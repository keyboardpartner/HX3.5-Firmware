/*
// #############################################################################
//       __ ________  _____  ____  ___   ___  ___
//      / //_/ __/\ \/ / _ )/ __ \/ _ | / _ \/ _ \
//     / ,< / _/   \  / _  / /_/ / __ |/ , _/ // /
//    /_/|_/___/_  /_/____/\____/_/_|_/_/|_/____/
//      / _ \/ _ | / _ \/_  __/ |/ / __/ _ \
//     / ___/ __ |/ , _/ / / /    / _// , _/
//    /_/  /_/ |_/_/|_| /_/ /_/|_/___/_/|_|
//
// #############################################################################
*/
// Test-Framework für HX3.5 Mainboard mit ATmega1284P
// Banner Logos from
// https://patorjk.com/software/taag/#p=display&f=Banner&t=MAIN&x=cppComment&v=4&h=2&w=80&we=false
// Diverse Bootloader:
// https://github.com/MCUdude/MiniCore/tree/master/avr/bootloaders/optiboot_flash/bootloaders

#include <Arduino.h>
#include <EEPROM.h>
#include <TimerOne.h>
#include "FPGA_SPI.h"

// Define used modules here, comment out unused modules to save program memory
#define LCD_I2C
#define ANLG_MPX
#define PANEL16

#define VERSION "HX3.5 v0.01"

// ATMEL ATMEGA644P / SANGUINO
//
//                     +---\/---+
// 0  INT0 (D 0) PB0  1|        |40  PA0 (AI 0 / D31)	31
// 1  INT1 (D 1) PB1  2|        |39  PA1 (AI 1 / D30)	30
// 2  INT2 (D 2) PB2  3|        |38  PA2 (AI 2 / D29)	39
// 3   PWM (D 3) PB3  4|        |37  PA3 (AI 3 / D28)	28
// 4   PWM (D 4) PB4  5|        |36  PA4 (AI 4 / D27)	27
// 5  MOSI (D 5) PB5  6|        |35  PA5 (AI 5 / D26)	26
// 6  MISO (D 6) PB6  7|        |34  PA6 (AI 6 / D25)	25
// 7   SCK (D 7) PB7  8|        |33  PA7 (AI 7 / D24)	24
//               RST  9|        |32  AREF
//               VCC 10|        |31  GND
//               GND 11|        |30  AVCC
//             XTAL2 12|        |29  PC7 (D 23)		23
//             XTAL1 13|        |28  PC6 (D 22)		22
// 8  RX0 (D 8)  PD0 14|        |27  PC5 (D 21) TDI	21
// 9  TX0 (D 9)  PD1 15|        |26  PC4 (D 20) TDO	20
//10  RX1 (D 10) PD2 16|        |25  PC3 (D 19) TMS	19
//11  TX1 (D 11) PD3 17|        |24  PC2 (D 18) TCK	18
//12  PWM (D 12) PD4 18|        |23  PC1 (D 17) SDA	17
//13  PWM (D 13) PD5 19|        |22  PC0 (D 16) SCL	16
//14  PWM (D 14) PD6 20|        |21  PD7 (D 15) PWM	15
//                     +--------+
//

#define LED_PIN 10 // Pin für LED
#define PWR_GOOD 15 // Pin für DSP-Reset


#define _NOP_DLY asm volatile ("nop")


volatile uint8_t Timer1Semaphore = 0;
volatile uint8_t Timer1RoundRobin = 0;


#ifdef LCD_I2C
  // Für LCD mit I2C-Interface
  #include "MenuPanel.h"
  #include "MenuItems.h"
#endif
bool lcdPresent = false;

#ifdef PANEL16
  // Für LCD mit I2C-Interface
  #include "Panel16.h"
  #define PANEL16_I2C_ADDR 0x62
  Panel16 panel16(PANEL16_I2C_ADDR);
#endif
bool panel16Present = false;

#ifdef ANLG_MPX
  // Für MPX-gestützte analoge Eingänge
  #define ANLG_INPUTS 4 // Analoge Eingänge für MIDI-CC-Potentiometer
  #include "MpxPots.h"
  MPXpots mpxPots(ANLG_INPUTS, MPX_ACTIVE_TIMEOUT, MPX_INTEGRATOR_FACTOR);
#endif

// #############################################################################

void configurePorts(uint8_t driverType) {
  DDRA  = B01111000; // Encoder-Eingänge PA0 und PA1, MPX-Reset PA3 als Ausgang
  PORTA = B00111111; // Pull-ups für Encoder-Eingänge PA0 und PA1, MPX-Reset PA3 auf HIGH

  DDRB  = DDRBINIT_FPGACONF; // PB0 = F_CSO_B, PB1 = F_RS, PB2 = F_INT, PB3 = F_DS, PB4 = F_AUX
  PORTB = B10011111; //

  DDRC  = B01100000; // MPX Data PC0 und MPX-Clk PC1 als Ausgänge
  PORTC = B11111111; //

  DDRD  = B11111110; //
  PORTD = B01111100; // Pull-ups für Eingänge aktivieren, LED PD2 off

  // Während der FPGA-Konfiguration müssen einige Pins als Inputs konfiguriert werden,
  // damit das FPGA nicht gestört wwird.
  // Nach der FPGA-Konfiguration können die Pins wieder als SPI-Pins konfiguriert werden
  DDRB  = DDRBINIT_FPGACONF; // PB0 = F_CSO_B, PB1 = F_RS, PB2 = F_INT, PB3 = F_DS, PB4 = F_AUX
  digitalWrite(LED_PIN, LOW); // sets the LED on
  _FPGA_PROG_ON;
  delayMicroseconds(5);
  _FPGA_PROG_OFF;
  uint8_t my_time = 0;
  do {  // Konfiguration abwarten, max 2,5 Sek
    delay(10);
    my_time++;
  } while (!_FPGA_DONE || (my_time > 250));

  if (_FPGA_DONE) {
    Serial.println("/ FPGA done");
  }
  digitalWrite(LED_PIN, HIGH);  // sets the LED off
  DDRB  = DDRBINIT; // PB0 = F_CSO_B, PB1 = F_RS, PB2 = F_INT, PB3 = F_DS, PB4 = F_AUX
  _FPGA_PROG_OFF;


  // SPI initialisieren, wie bei MMC
  SPCR  = B01011100;  // Enable SPI, Master, CPOL/CPHA=1,1 Mode 3
  SPSR  = B00000000;  // %00000001 = Double Rate, %00000000 = Normal Rate
}


// #############################################################################
//
//      #####     #    #       #       ######     #     #####  #    #  #####
//     #     #   # #   #       #       #     #   # #   #     # #   #  #     #
//     #        #   #  #       #       #     #  #   #  #       #  #   #
//     #       #     # #       #       ######  #     # #       ###     #####
//     #       ####### #       #       #     # ####### #       #  #         #
//     #     # #     # #       #       #     # #     # #     # #   #  #     #
//      #####  #     # ####### ####### ######  #     #  #####  #    #  #####
//
// #############################################################################

#ifdef ANLG_MPX
// #############################################################################
// Callback für MPX-Eingänge, hier können die MIDI-CC-Werte gesendet werden
// Muss in setup() mit "mpxPots.setChangeAction(onMPXChange)" registriert werden
// #############################################################################

void onMPXChange(uint8_t inputIndex, uint8_t value) {

}
#endif

#ifdef PANEL16
// #############################################################################
// Callback-Funktion für Panel16, liefert derzeit gedrückten Button
// Wird von der Panel16-Library aufgerufen, während ein Panel16-Button gedrückt
// und auf Loslassen gewartet wird. Dadurch können die Manuale weiter
// gescannt werden, ohne die Scan-Funktion zu blockieren
// #############################################################################

void onPanel16releaseWait(uint8_t button) {

}
#endif


// #############################################################################
//
//     #     # ####### #     # #     #
//     ##   ## #       ##    # #     #
//     # # # # #       # #   # #     #
//     #  #  # #####   #  #  # #     #
//     #     # #       #   # # #     #
//     #     # #       #    ## #     #
//     #     # ####### #     #  #####
//
// #############################################################################


void blinkLED(uint8_t times) {
  // Board-LED blinkt zur Bestätigung von Aktionen, z.B. Speichern von Werten im EEPROM
  for (uint8_t i=0; i<times; i++) {
    digitalWrite(LED_PIN, LOW); // sets the LED on
    delay(150);
    digitalWrite(LED_PIN, HIGH);  // sets the LED off
    delay(150);
  }
}

#ifdef LCD_I2C

void handleEncoder(int16_t encoderDelta, bool forceDisplay) {
  // Menü-Handling bei Encoder-Änderungen: Wert ändern,
  // bei Änderung des Treibertyps Ports neu konfigurieren, Dynamiktabelle neu erstellen
  if (MenuLink[MenuItemActive] != 0) return; // im Untermenü-Link, Encoder hat keine Funktion
  if ((encoderDelta != 0) || forceDisplay) {
    // Encoder hat sich bewegt
    int8_t oldValue = MenuValues[MenuItemActive];
    if (oldValue + encoderDelta < MenuValueMin[MenuItemActive]) {
      MenuValues[MenuItemActive] = MenuValueMin[MenuItemActive]; // Unterlauf verhindern
    } else if (oldValue + encoderDelta > MenuValueMax[MenuItemActive]) {
      MenuValues[MenuItemActive] = MenuValueMax[MenuItemActive]; // Maximalwert
    } else {
      MenuValues[MenuItemActive] = oldValue + encoderDelta;
    }
    displayMenuValue(MenuItemActive);
    if (MenuItemActive == m_driver_type) {
      // PortD neu konfigurieren
      configurePorts(MenuValues[m_driver_type]);
      if (MenuValues[m_driver_type] >= drv_fatar1) {
        Timer1.setPeriod(500);  // Timer1 auf 500 us einstellen
      } else {
        Timer1.setPeriod(1000); // Timer1 auf 1000 us einstellen
      }
    }
  }
}

void handleMenuButtons() {
  // Menü-Handling bei Button-Änderungen: Menupunkt wechseln oder Wert in EEPROM speichern
  uint8_t buttons = lcd.getButtons(); // benötigt etwa 130 µs (inkl. I2C Overhead) bei 400 kHz
  int8_t menu_link = MenuLink[MenuItemActive];

  if (buttons != 0) {
    if (buttons & LCD_BTNUP_MASK) {
      // Up-Taste mit Autorepeat
      uint16_t timeout = 750; // Startwert für getButtonsWaitReleased, wird nach erstem Durchlauf verkürzt für schnelleres Scrollen, wenn Taste gehalten wird
      do {
        if (MenuItemActive > MenuStart) {
          MenuItemActive--;
        } else {
          MenuItemActive = MenuEnd; // wrap around
        }
        displayMenuItem(MenuItemActive);
        buttons = lcd.getButtonsWaitReleased(timeout); // Warte bis losgelassen
        timeout = 250; // verkürze Wartezeit für schnelleres Scrollen, wenn Taste gehalten wird
      } while (buttons);
    }

    if (buttons & LCD_BTNDN_MASK) {
      // Down-Taste mit Autorepeat
      uint16_t timeout = 750; // Startwert für getButtonsWaitReleased, wird nach erstem Durchlauf verkürzt für schnelleres Scrollen, wenn Taste gehalten wird
      do {
       if (MenuItemActive < MenuEnd) {
          MenuItemActive++;
        } else {
          MenuItemActive = MenuStart; // wrap around
        }
        displayMenuItem(MenuItemActive);
        buttons = lcd.getButtonsWaitReleased(timeout); // Warte bis losgelassen
        timeout = 250; // verkürze Wartezeit für schnelleres Scrollen, wenn Taste gehalten wird
      } while (buttons);
    }

    if (buttons & LCD_BTNENTER_MASK) {
      // Enter-Taste, Wert in EEPROM speichern oder Submenu aufrufen
      if (menu_link < 0) {
        // Link zurück zum Hauptmenü, wechsle zurück
        MenuItemActive = MenuItemReturn; // Link ist negativ, also zurück zum Hauptmenü
        MenuStart = 0;
        MenuEnd = m_end - 1;
        displayMenuItem(MenuItemActive);
      } else if (menu_link > 0) {
        // Link zu Untermenü, wechsle zu diesem
        MenuItemReturn = MenuItemActive; // speichere Rücksprungposition
        MenuItemActive = menu_link;
        displayMenuItem(MenuItemActive);
        // Untermenü, finde Start- und Endindex der Menupunkte
        MenuStart = menu_link;
        for (MenuEnd = menu_link; MenuEnd < MENU_ITEMCOUNT; MenuEnd++) {
          if (MenuLink[MenuEnd] < 0) {
            break; // Ende des Untermenüs erreicht
          }
        }
      } else {
        // Kein Link, speichere Wert im EEPROM
        EEPROM.update(MenuItemActive + EEPROM_MENUDEFAULTS, MenuValues[MenuItemActive]);
        displayMenuItem(MenuItemActive);
        // Kurzes Blinken als Bestätigung
        blinkLED(1);
      }
      lcd.getButtonsWaitReleased(0); // Warte bis losgelassen
    }
  }
}

#endif

// ------------------------------------------------------------------------------

#ifdef PANEL16

void handlePanel16(uint8_t row) {
  // Panel16-Handling, hier werden Tasten einer Reihe abgefragt und LEDs gesetzt
  uint8_t bnt_number = panel16.getButtonRow(row); // benötigt etwa 550 µs für Button-Abfrage bei 400 kHz
  if (bnt_number != 0xFF) {
    uint8_t btn_onoff = panel16.getLEDonOff(bnt_number) ? 0 : 127;
    switch (MenuValues[m_btnmode1 + bnt_number]) {
      case btnmode_send_cc_val:
        // Button Mode 0 = Toggle, sendet MIDI-CC mit 127 bei ON und 0 bei OFF
        panel16.toggleLEDstate(bnt_number);
        break;
      case btnmode_send_cc_evt:
        // Button Mode 1 = Event, sendet immer MIDI-CC mit 127 bei ON und bei OFF
        break;
      case btnmode_send_prg_ch:
        // Button Mode 2 = Program Change, sendet ein MIDI Program Change mit der Nummer aus MenuValues[m_btn1 + bnt_number]
        break;
      case btnmode_send_note:
        // Button Mode 3 = Note On/Off, sendet MIDI Note On mit Velocity 64 bei ON und Note Off bei OFF, Note Nummer aus MenuValues[m_btn1 + bnt_number]
        //MidiSendNoteOnNoDyn(MenuValues[m_upper_channel], MenuValues[m_btn1 + bnt_number]);
        panel16.getButtonRowWaitReleased(0);
        break;
    }
    panel16.getButtonRowWaitReleased(0);
    #ifdef LCD_I2C
      if (lcdPresent) displayMenuItem(MenuItemActive);
    #endif
  };
}

#endif

// #############################################################################
//
//     #     #    #    ### #     #
//     ##   ##   # #    #  ##    #
//     # # # #  #   #   #  # #   #
//     #  #  # #     #  #  #  #  #
//     #     # #######  #  #   # #
//     #     # #     #  #  #    ##
//     #     # #     # ### #     #
//
// #############################################################################

void timer1SemaphoreISR() {
  // Timer1 Interrupt Service Routine, setzt Semaphore für Timer-basiertes Ausführen
  // der Scan- und MIDI-Merge-Funktionen im Hauptprogramm
  Timer1Semaphore++;
  Timer1RoundRobin++;
  Timer1RoundRobin &= 0x0F; // nur die unteren 4 Bits behalten
}

// ------------------------------------------------------------------------------

void setup() {
  Serial.begin(57600);
  Serial.println();
  Serial.println(F("/ HX3.5 C++ Framework Test"));

  // set led port as output
  pinMode(LED_PIN, OUTPUT);
  // Defaults aus EEPROM lesen
  for (uint8_t i = 0; i < MENU_ITEMCOUNT; i++) {
    uint8_t eep_val = EEPROM.read(i + EEPROM_MENUDEFAULTS);
    if ((eep_val < MenuValueMin[i]) || (eep_val > MenuValueMax[i])) {
      // ungültiger Wert, auf default zurücksetzen
      eep_val = MenuValues[i]; // sind noch Default-Werte aus Menü-Definition
      EEPROM.update(i + EEPROM_MENUDEFAULTS, eep_val);
    }
    MenuValues[i] = eep_val;
  }
  configurePorts(MenuValues[m_driver_type]); // Port Initialisierung je nach Treibertyp

  Timer1.attachInterrupt(timer1SemaphoreISR); // timer1SemaphoreISR to run every 0.5 milliseconds
  Timer1.initialize(2000); // Timer1 auf 2000 us einstellen

  Wire.begin();
  Wire.setClock(400000UL);  // 400kHz

  #ifdef LCD_I2C
    if (menuInit()) {
      lcdPresent = true;
      lcd.cursorXY(0,0);
      lcd.print(VERSION);
      blinkLED(5);
     }
  #else
    blinkLED(3);
  #endif

  #ifdef PANEL16
    Wire.beginTransmission(PANEL16_I2C_ADDR); // Panel I2C-Adresse
    if (Wire.endTransmission(true) == 0) {
      panel16Present = true;
      panel16.begin();
      // just a test for Panel16 library
      // Bit 7 = Active/On, Bit 6 = Blinking, Bit 4,5 = OffState, Bit 2,3 = BlinkState, Bit 0,1 = OnState
      // mit State =%00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
      panel16.setLEDstate(2, panel16.led_hilight | panel16.led_alt_dark | panel16.led_blink_ena); // einzelne LED in lower row
      panel16.setLEDstate(3, panel16.led_dark | panel16.led_alt_dark | panel16.led_btn_on); // einzelne LED in lower row
      panel16.setLEDstate(4, 0b10001001); // einzelne LED in lower row, direkte Bitmask, entspricht hilight, alt_bright, off_dark, blink_ena
      panel16.setLEDstate(8, panel16.led_hilight | panel16.led_alt_bright | panel16.led_off_dark | panel16.led_blink_ena); // einzelne LED in upper row
      panel16.setLEDstate(13, panel16.led_dark | panel16.led_btn_on); // einzelne LED in upper row
      panel16.setWaitCallback(onPanel16releaseWait); // Callback-Funktion für Button-Handling registrieren
    }
  #endif

  #ifdef ANLG_MPX
    mpxPots.setChangeAction(onMPXChange); // MPX-gestützte analoge Eingänge initialisieren, Callback-Funktion für Änderungen übergeben
    mpxPots.resetMPX(); // MPX-SR 74HC164 zurücksetzen
  #endif

  spi_write8(68, 0); // Tuning Byte
  spi_write8(246, 0); // DSP Bits

  digitalWrite(LED_PIN, LOW); // sets the LED on

  digitalWrite(PWR_GOOD, HIGH); // DSP-Reset deaktivieren
  delay(150); // DSP booten lassen

  uint32_t fpga_version= spi_read32(3); // SPI-Transfer, lese Version aus
  Serial.print(F("/ FPGA Version: "));
  Serial.println(fpga_version, HEX);

  spi_read8(240); // hier nur DNA-Auslese-Trigger
  uint32_t fpga_serial = spi_read32(242); // lese Seriennummer aus
  Serial.print(F("/ FPGA Serial: "));
  Serial.println(fpga_serial);

  // Serial Number: 2821432, Licence Organ: 9523781  Extended: 3316044
  spi_write32(240, 9523781);
  spi_write32(241, 3316044);

  uint32_t fpga_organ = spi_read32(240); // lese Lizenznummer aus
  Serial.print(F("/ FPGA Organ License: "));
  Serial.println(fpga_organ);

  uint32_t fpga_rotary = spi_read32(241); // lese Lizenznummer aus
  Serial.print(F("/ FPGA Rotary License: "));
  Serial.println(fpga_rotary);

  uint8_t fpga_valid = spi_read32(244); // muss in 32 Bit-Register gelesen werden
  Serial.println(fpga_valid);

  df_send_core(15, 2, 1);  // FIR Koeffizienten Horn (+15 auf Reg. 2), 1 Block
  df_send_core(0, 0, 2);   // Test: DF-Transfer, sende 8 KByte aus Blockbuffer an Core #0

  spi_clearfifo();
  spi_autoIncReset(0); // Scan core zurücksetzen
  delay(10);
  uint32_t scan_info = spi_read32(MIDI_FIFO_RDREG); // Test: SPI-Transfer, lese erstes Wort von Core #0, sollte 0x12345678 sein
  Serial.print(F("/ Scan Core response: "));
  Serial.println(scan_info, HEX);
  digitalWrite(LED_PIN, HIGH); // sets the LED off

  #ifdef LCD_I2C
    lcd.cursorXY(0,1);
    lcd.print(fpga_serial, HEX);
    lcd.clearEOL();
    delay(1500);
    displayMenuItem(MenuItemActive); // Hauptmenü anzeigen
  #endif

  spi_write8(177, 40); // Test: SPI-Transfer, schreibe LeslieHornSpeed
  spi_write8(178, 40); // Test: SPI-Transfer, schreibe LeslieRotorSpeed
}

// #############################################################################

void loop() {
  while (Timer1Semaphore) {
    // wird alle 500µs neu gesetzt durch Timer1 ISR, hier wird die eigentliche Arbeit erledigt
    Timer1Semaphore--;

    #ifdef LCD_I2C
      if (lcdPresent) {
        handleEncoder(lcd.getEncoderDelta(), false);
        if (Timer1RoundRobin == 0) {
          handleMenuButtons(); // benötigt etwa 130 µs für Button-Abfrage bei 400 kHz
        }
      }
    #endif

    #ifdef PANEL16
      // Test für Panel16 Button-Abfrage
      if (panel16Present) {
        if (Timer1RoundRobin == 4) {
          panel16.updateBlinkLEDs(); // muss regelmäßig für blinkende LEDs aufgerufen werden
        }
        if (Timer1RoundRobin == 8) {
          handlePanel16(0); // aus Zeitgründen in zwei Hälften aufteilen
        }
        if (Timer1RoundRobin == 12) {
          handlePanel16(1); // aus Zeitgründen in zwei Hälften aufteilen
        }
      }
    #endif

    #ifdef ANLG_MPX
      if (Timer1RoundRobin == 4) {
        mpxPots.handleMPX(); // muss regelmäßig aufgerufen werden, um Änderungen aller Potis zu erkennen
      }
    #endif

  }
}
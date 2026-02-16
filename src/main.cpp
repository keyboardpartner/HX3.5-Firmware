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
#include "global_vars.h"
#include "files.h"
#include "organ.h"
#include "speaker.h"
#include "board.h"

// Define used modules here, comment out unused modules to save program memory
#define LCD_I2C
#define ANLG_MPX
#define PANEL16

#ifdef LCD_I2C
  // Für LCD mit I2C-Interface
  #include "menu_system.h"
#endif
bool lcdPresent = false;

#include "FPGA_hilevel.h"

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

void onPanel16press(uint8_t button) {
  if (button != 0xFF) {
    uint8_t btn_onoff = panel16.getLEDonOff(button) ? 0 : 127;
    switch (buttonModes[button]) {
      case bm_toggle:
        // Button Mode 0 = Toggle, sendet MIDI-CC mit 127 bei ON und 0 bei OFF
        panel16.toggleLEDstate(button);
        midi_sendcontroller(0, button, btn_onoff); // MIDI-CC-Nummer = Button-Nummer, Testweise
        break;
      case bm_press:
        // Button Mode 3 = Note On/Off, sendet MIDI Note On mit Velocity 64 bei ON und Note Off bei OFF, Note Nummer aus EditValues[m_btn1 + button]
        //MidiSendNoteOnNoDyn(EditValues[m_upper_channel], EditValues[m_btn1 + button]);
        break;
    }
    #ifdef FILES_H
      switch (button) {
        case 12:
          sendSDcore(0, true);
          break;
        case 13:
          sendSDcore(2, true);
          break;
        case 14:
          sendSDcore(2, false);
          break;
        case 15:
          initSDcard();
          listCardDirectory();
          break;
      }
    #endif
    panel16.waitReleased();
  };
}

void onPanel16releaseWait() {
  // DPRINTLNF("/ ReleaseWait callback");
}

#endif

#ifdef LCD_I2C

void onMenuButton(uint8_t button) {
  // Callback-Funktion für MenuPanel-Button, liefert gedrückten Button
  handleMenuButtons(button);
}

void onMenuEncoder(int16_t delta) {
  // Callback-Funktion für MenuPanel-Encoder, liefert Bewegungsdelta
  handleMenuEncoderChange(delta, false);
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
  if (lcdPresent) {
    // Timer-Interrupt erledigt auch das Scannen des MenuPanel-Encoders
    lcd.encoderISR();
  }
}

// ------------------------------------------------------------------------------

void setup() {
  Serial.begin(57600);
  Serial.println();
  Serial.println(F("/ HX3.5 C++ Framework Test"));

  // set led port as output
  pinMode(LED_PIN, OUTPUT);
  // Defaults aus EEPROM lesen
  if (EEPROM.read(EEPROM_VERSION_IDX) != FIRMWARE_VERSION) {
    // EEPROM enthält ungültige Werte, z.B. nach erstem Flashen oder bei Firmware-Update, also mit Default-Werten initialisieren
    for (uint8_t i = 0; i < MENU_ITEMCOUNT; i++) {
      if (EditValuePtrs[i] != NULL) {
        EEPROM.update(i + EEPROM_MENUDEF_IDX, *EditValuePtrs[i]);
      }
    }
    EEPROM.update(EEPROM_VERSION_IDX, FIRMWARE_VERSION); // Schreibe Vergleichswert für zukünftige Gültigkeitsprüfung
  } else {
    for (uint8_t i = 0; i < MENU_ITEMCOUNT; i++) {
      if (EditValuePtrs[i] != NULL) {
        *EditValuePtrs[i] = EEPROM.read(i + EEPROM_MENUDEF_IDX);
      }
    }
  }
  configurePorts(); // Port Initialisierung je nach Treibertyp
  // initSDcard();  // SD-Karte initialisieren - nur bei Bedarf!

  // Der Timer-Interrupt erledigt auch das Scannen des MenuPanel-Encoders!
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
      // Callback-Funktion für MenuPanel-Button-Handling registrieren
      lcd.setButtonCallback(onMenuButton); 
      // Callback-Funktion für MenuPanel-Encoder-Handling registrieren
      lcd.setEncoderCallback(onMenuEncoder); 
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
      // Callback-Funktion für Panel16-Button-Handling registrieren
      panel16.setPressCallback(onPanel16press); 
      // Callback-Funktion für Panel16-Button-WaitRelease-Handling registrieren (optional)
      panel16.setWaitCallback(onPanel16releaseWait); 
    }
  #endif

  #ifdef ANLG_MPX
    mpxPots.setChangeAction(onMPXChange); // MPX-gestützte analoge Eingänge initialisieren, Callback-Funktion für Änderungen übergeben
    mpxPots.resetMPX(); // MPX-SR 74HC164 zurücksetzen
  #endif

  if (fpgaOK) {
    initBoard();
    initOrgan();
  }
  #ifdef LCD_I2C
    if (lcdPresent) displayMenuItem(0);
  #endif
}

// #############################################################################

void loop() {
  if (!_FIFO_EMPTY && fpgaOK) {
    // MIDI-Daten vom FPGA empfangen
    Serial.print (F("/ MIDI RX: "));
    Serial.println(spi_read32(MIDI_FIFO_RDREG), HEX);
  }

  while (Timer1Semaphore) {
    // wird alle 2000µs neu gesetzt durch Timer1 ISR, hier wird die eigentliche Arbeit erledigt
    Timer1Semaphore--;

    #ifdef LCD_I2C
      if (lcdPresent) {
        lcd.checkEncoder(); // ruft Callback für Encoder-Bewegung auf
        if (Timer1RoundRobin == 0) {
          lcd.getButtons(); // benötigt etwa 130 µs für Button-Abfrage bei 400 kHz, ruft callbacks für gedrückte Buttons auf
        }
      }
    #endif

    #ifdef PANEL16
      // Test für Panel16 Button-Abfrage
      if (panel16Present) {
        // bei unkritischen Aktionen könnten die beiden Panel16-Zeilen 
        // auch mit checkRow() gemeinsam upgedated werden
        if (Timer1RoundRobin == 8) {
          panel16.checkRow(0); // aus Zeitgründen in zwei Hälften aufteilen
        }
        if (Timer1RoundRobin == 12) {
          panel16.checkRow(1); // aus Zeitgründen in zwei Hälften aufteilen
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
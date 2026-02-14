#ifndef MENU_SYSTEM_H
#define MENU_SYSTEM_H

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

// Menu System für LCD mit I2C-Interface, basierend auf der Menu-Struktur aus Excel-Tabelle

#include <Wire.h>
#include <EEPROM.h>
#include "MenuPanel.h"
#include "global_vars.h"
#include "menu_items.h"
#include "FPGA_hilevel.h"

void menuActionDispatch(uint8_t itemIndex, uint8_t new_value) {
  // Hier wird entschieden, was bei einer Wertänderung eines Menüpunktes passieren soll
  switch (EditAction[itemIndex]) {
    case ac_upper_db:
      fpga_send_upper_db();
      break;
    case ac_lower_db:
      fpga_send_lower_db();
      break;
    case ac_pedal_db:
      fpga_send_pedal_db();
      break;
    case ac_volume:
      DPRINTF("/ Set Volume: ");
      DPRINTLN(new_value);
      midi_sendnrpn(0x3560, EditValues[m_master_volume]);
      midi_sendnrpn(0x3564, EditValues[m_amp_gain]);
      break;
    default:
      // Keine Aktion definiert
      break;
  }
}

bool menuInit() {
  // Initialisiere Menü, setze Start- und Endpunkt und zeige Version an
  if (lcd.begin(16, 2)) {
    MenuStart = 0;
    MenuEnd = m_end - 1;
    MenuItemActive = 0;
    MenuItemReturn = 0; // Initiale Rücksprungposition auf ersten Menüpunkt setzen
    // Display gefunden, zeige Startbild
    lcd.setCursor(0, 0);
    lcd.print(VERSION);
    lcd.setCursor(0, 1);
    lcd.print(F("C.Meyer 2026"));
    return true;
  } else {
    // Kein Display gefunden
    return false;
  }
}

// Menu-Handling für LCD mit I2C-Interface

void displayMenuValue(uint8_t itemIndex) {
  lcd.setCursor(0, 1);
  int8_t item_value = EditValues[itemIndex];
  switch (itemIndex) {
    case m_kbd_driver:
      // Kopiert Menu Text aus PROGMEM ins RAM, da lcd.print() nicht direkt aus PROGMEM lesen kann
      if (item_value < MENU_DRIVERCOUNT) {
        lcd.printProgmem(&DriverTypes[item_value]);
        lcd.clearEOL(); // Lösche evtl. alte Zeichen
        lcd.setCursor(13, 1);
      }
      break;
    default:
      lcd.print(item_value);
      lcd.clearEOL(); // Lösche evtl. alte Zeichen
      lcd.setCursor(3, 1);
      break;
  }
  lcd.write(LCD_ARW_LT);
  if (item_value != (int8_t)EEPROM.read(itemIndex + EEPROM_MENUDEF_IDX)) {
    lcd.setCursor(15, 1);
    lcd.write('*'); // geänderte Werte mit Stern markieren
  }
  if (item_value < 0) {
    lcd.setCursor(5, 1);
    lcd.print(F("(unused)")); // negative Werte sind unbenutzt, entsprechend kennzeichnen
  }
}

void displayMenuItem(uint8_t itemIndex) {
  lcd.setCursor(0, 0);
  // Kopiert MenuItem aus PROGMEM ins RAM, da lcd.print() nicht direkt aus PROGMEM lesen kann
  lcd.printProgmem(&MenuItems[itemIndex]);
  lcd.clearEOL(); // Lösche evtl. alte Zeichen

  lcd.setCursor(15, 0);
  lcd.write(LCD_ARW_UD);
  int8_t menu_link = MenuLink[MenuItemActive];
  if (menu_link < 0) {
    lcd.setCursor(0, 1);
    lcd.print(F("Exit "));
    lcd.write(LCD_ARW_LT); // Untermenü-Ende mit Pfeil nach links markieren
    lcd.clearEOL(); // Lösche evtl. alte Zeichen
  } else if (menu_link > 0) {
    lcd.setCursor(0, 1);
    lcd.print(F("Settings "));
    lcd.write(LCD_ARW_RT); // Untermenü mit Pfeil nach rechts markieren
    lcd.clearEOL(); // Lösche evtl. alte Zeichen
  } else {
    displayMenuValue(itemIndex);
  }
}

void handleEncoder(int16_t encoderDelta, bool forceDisplay) {
  // Menü-Handling bei Encoder-Änderungen: Wert ändern,
  // bei Änderung des Treibertyps Ports neu konfigurieren, Dynamiktabelle neu erstellen
  if (MenuLink[MenuItemActive] != 0) return; // im Untermenü-Link, Encoder hat keine Funktion
  if ((encoderDelta != 0) || forceDisplay) {
    // Encoder hat sich bewegt
    int16_t oldValue = EditValues[MenuItemActive];
    int16_t newValue = oldValue + encoderDelta; // Word, könnte sonst einen Überlauf geben
    int16_t minValue = (int16_t)MenuValueMin[MenuItemActive];
    int16_t maxValue = (int16_t)MenuValueMax[MenuItemActive];
    if (newValue < minValue) {
      newValue = minValue; // Unterlauf verhindern
    } else if (newValue > maxValue) {
      newValue = maxValue; // Maximalwert
    }
    EditValues[MenuItemActive] = (int8_t)newValue;
    displayMenuValue(MenuItemActive);
    menuActionDispatch(MenuItemActive, (int8_t)newValue);
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
        EEPROM.update(MenuItemActive + EEPROM_MENUDEF_IDX, EditValues[MenuItemActive]);
        displayMenuItem(MenuItemActive);
        // Kurzes Blinken als Bestätigung
        blinkLED(1);
      }
      lcd.getButtonsWaitReleased(0); // Warte bis losgelassen
    }
  }
}

#endif

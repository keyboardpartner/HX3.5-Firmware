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


#ifndef MenuItems_h
#define MenuItems_h

#include "global_vars.h"
#include "files.h"

// Menu System Variables

#define MENU_DRIVERCOUNT 4
enum {drv_sr61, drv_fatar1, drv_fatar2, drv_custom};
const lcdTextType DriverTypes[MENU_DRIVERCOUNT] PROGMEM = {
  { "Scan16/61" },
  { "FatarScan1-61" },
  { "FatarScan2" },
  { "Custom" },
};


// Wrapper für Routinen mit Parametern oder Text-Parametern, Prototypes
void menuOrganModel();
void menuSpeakerModel();

// ------------------------------------------------------------------------------
// Hier Daten aus Excel-Tabelle einfügen, die die Menüstruktur definiert.
// Es müssen 1 enum-Liste und 5 Arrays mit gleicher Länge angelegt werden.
// MenuLink[MENU_ITEMCOUNT] definiert die Menüstruktur:
// 0 normaler Edit-Menüpunkt, der mit Encoder geändert werden kann
// >0 ist die Nummer des Submenüpunktes, zu dem verlinkt wird
// -1 Rücksprungmöglichkeit (Exit) zum Hauptmenü
//
// EditValuePtrs[MENU_ITEMCOUNT] enthält Zeiger auf die Werte, die bei 
// Änderung eines Menüeintrags geändert werden sollen, 
// NULL wenn kein Wert geändert werden soll.
// ------------------------------------------------------------------------------

enum {
  m_upper_db,
  m_lower_db,
  m_pedal_db,
  m_swell,
  m_volume,
  m_gain,
  m_sd_card,
  m_kbd_driver,
  m_organ,
  m_speaker,
  m_pitchwheel,
  m_main_end,
}; // alle vorhandenen Menü-Links


// Action-Routine über Tabelle
typedef void (*action)();

// Bei mehr als 127 Menüpunkten müssen die Datentypen in menuEntryType angepasst werden
typedef struct {
  char menuHeader[16];
  int8_t submenuLink;
  uint8_t* editValuePtr;
  action editAction;
  int8_t menuValueMin;
  int8_t menuValueMax;
} menuEntryType;

#define MENU_ITEMCOUNT 52

// Diese Tabelle enthält die Menüstruktur, die in der Excel-Tabelle HX35_menuItems.xlsx definiert ist
// Menü-Text, Link zu Untermenüs, Zeiger auf Werte, die bei Änderung geändert werden sollen, 
// Action-Routine bei Änderung, Min- und Maximalwerte für die Editierung

const menuEntryType MenuItems[MENU_ITEMCOUNT] PROGMEM = { 
  {"Upper DBs", m_upper_db, NULL, NULL, -1, -1},
  {"Lower DBs", m_lower_db, NULL, NULL, -1, -1},
  {"Pedal DBs", m_pedal_db, NULL, NULL, -1, -1},
  {"Swell Pedal", m_swell, &preamp.swell127, &setMIDIswell, 0, 127},
  {"Master Volume", m_volume, &preamp.masterVolume, &sendOrganVolumes, 0, 127},
  {"Amp Gain", m_gain, &preamp.ampGain, &sendAmpVolume, 0, 127},
  {"SD Flash Tools", m_sd_card, NULL, NULL, -1, -1},
  {"Keyboard", m_kbd_driver, NULL, NULL, -1, -1},
  {"Organ Model", m_organ, &tabs.organModel, &menuOrganModel, 0, 15},
  {"Speaker Model", m_speaker, &tabs.speakerModel, &menuSpeakerModel, 0, 15},
  {"Pitchwheel Pot", m_pitchwheel, NULL, NULL, -1, 31},
  {"End", m_main_end, NULL, NULL, -1, -1},
  {"Upper DB 16", m_upper_db, &drawbars.upper[0], &fpga_send_upper_db, 0, 127},
  {"Upper DB 5 1/3", m_upper_db, &drawbars.upper[1], &fpga_send_upper_db, 0, 127},
  {"Upper DB 8", m_upper_db, &drawbars.upper[2], &fpga_send_upper_db, 0, 127},
  {"Upper DB 4", m_upper_db, &drawbars.upper[3], &fpga_send_upper_db, 0, 127},
  {"Upper DB 2 2/3", m_upper_db, &drawbars.upper[4], &fpga_send_upper_db, 0, 127},
  {"Upper DB 2", m_upper_db, &drawbars.upper[5], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1 3/5", m_upper_db, &drawbars.upper[6], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1 1/3", m_upper_db, &drawbars.upper[7], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1", m_upper_db, &drawbars.upper[8], &fpga_send_upper_db, 0, 127},
  {"Upper DB", m_upper_db, NULL, NULL, -1, -1},
  {"Lower DB 16", m_lower_db, &drawbars.lower[0], &fpga_send_lower_db, 0, 127},
  {"Lower DB 5 1/3", m_lower_db, &drawbars.lower[1], &fpga_send_lower_db, 0, 127},
  {"Lower DB 8", m_lower_db, &drawbars.lower[2], &fpga_send_lower_db, 0, 127},
  {"Lower DB 4", m_lower_db, &drawbars.lower[3], &fpga_send_lower_db, 0, 127},
  {"Lower DB 2 2/3", m_lower_db, &drawbars.lower[4], &fpga_send_lower_db, 0, 127},
  {"Lower DB 2", m_lower_db, &drawbars.lower[5], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1 3/5", m_lower_db, &drawbars.lower[6], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1 1/3", m_lower_db, &drawbars.lower[7], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1", m_lower_db, &drawbars.lower[8], &fpga_send_lower_db, 0, 127},
  {"Lower DB", m_lower_db, NULL, NULL, -1, -1},
  {"Pedal DB 16", m_pedal_db, &drawbars.pedal[0], NULL, 0, 127},
  {"Pedal DB 8", m_pedal_db, &drawbars.pedal[1], NULL, 0, 127},
  {"Pedal DB", m_pedal_db, NULL, NULL, -1, -1},
  {"SD Card Info", m_sd_card, NULL, &sdCardInfo, 0, 0},
  {"Load SD Scan", m_sd_card, NULL, &loadScanDriver, 0, 0},
  {"Flash SD Scan", m_sd_card, NULL, &flashScanDriver, 0, 0},
  {"Flash FPGA", m_sd_card, NULL, &flashFPGA, 0, 0},
  {"Flash Other", m_sd_card, NULL, &flashOther, 0, 0},
  {"Reload FPGA", m_sd_card, NULL, &organReset, 0, 0},
  {"Test", m_sd_card, NULL, NULL, 0, 0},
  {"SD Card Info", m_sd_card, NULL, NULL, -1, -1},
  {"Kbd Driver", m_kbd_driver, &boardInfo.scan_driverIdx, NULL, 0, drv_custom},
  {"Velocity Min", m_kbd_driver, NULL, NULL, 1, 40},
  {"Velocity MaxAdj", m_kbd_driver, NULL, NULL, 1, 40},
  {"Velocity Slope", m_kbd_driver, &organModel.fatarVelocityFac, NULL, 1, 30},
  {"MIDI Channel", m_kbd_driver, &midiSettings.channel, NULL, 1, 15},
  {"Upper Base", m_kbd_driver, NULL, NULL, 12, 60},
  {"Lower Base", m_kbd_driver, NULL, NULL, 12, 60},
  {"Pedal Base", m_kbd_driver, NULL, NULL, 12, 60},
  {"Kbd Driver", m_kbd_driver, NULL, NULL, -1, -1},
};

// ------------------------------------------------------------------------------

menuEntryType currentMenuEntry; // extrahierter Menüpunkt

void getMenuEntry(uint8_t index) {
  // einen Menüpunkt aus PROGMEM lesen und lokal in currentMenuEntry speichern, 
  // damit wir die Werte daraus verwenden können
  if (index >= MENU_ITEMCOUNT) return;
  memcpy_P(&currentMenuEntry, &MenuItems[index], sizeof(menuEntryType));
}

uint8_t findSubMenuStartIndex(int8_t submenuLink) {
  // Hilfsfunktion, um den Startindex eines Untermenüs zu finden
  for (uint8_t i = m_main_end; i < MENU_ITEMCOUNT; i++) {
    getMenuEntry(i);
    if (currentMenuEntry.submenuLink == submenuLink) {
      return i; // In currentMenuEntry ist jetzt der gefundene Menüpunkt, wir können den Index zurückgeben
    }
  }
  return 0; // nicht gefunden, Rückfall auf Hauptmenü
}

uint8_t findSubMenuEndIndex(int8_t submenuLink) {
  // Hilfsfunktion, um den Endindex eines Untermenüs zu finden
  for (int8_t i = MENU_ITEMCOUNT-1; i > m_main_end; i--) {
    getMenuEntry(i);
    if (currentMenuEntry.submenuLink == submenuLink) {
      return i; // In currentMenuEntry ist jetzt der gefundene Menüpunkt, wir können den Index zurückgeben 
    }
  }
  return 0; // nicht gefunden, Rückfall auf Hauptmenü
}

bool isSubMenu(int8_t menuIdx) {
  // Hilfsfunktion, um zu prüfen, ob es ein Untermenü mit diesem Link gibt
  if (menuIdx > m_main_end) return true;
  return false; // nicht gefunden
}

// ------------------------------------------------------------------------------

const String Msg[] = {"FCK TRMP", "FCK AFD"};
int8_t MenuItemActive;
int8_t MenuItemReturn;   // speichert bei Untermenüs die Rücksprungposition

#endif
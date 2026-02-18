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

const uint8_t m_upper_db_16 = 11;
const uint8_t m_lower_db_16 = 21;
const uint8_t m_pedal_db_16 = 31;
const uint8_t m_sd_card_info = 34;
const uint8_t m_kbd_driver = 42;
const uint8_t m_menu_end = 10;

// Action-Routine über Tabelle
typedef void (*action)();

typedef struct {
  char menuHeader[16];
  int16_t submenuLink;
  uint8_t* editValuePtr;
  action editAction;
  int16_t menuValueMin;
  int16_t menuValueMax;
} menuEntryType;

#define MENU_ITEMCOUNT 51

// Diese Tabelle enthält die Menüstruktur, die in der Excel-Tabelle HX35_menuItems.xlsxdefiniert ist
// Menü-Text, Link zu Untermenüs, Zeiger auf Werte, die bei Änderung geändert werden sollen, 
// Action-Routine bei Änderung, Min- und Maximalwerte für die Editierung
const menuEntryType MenuItems[MENU_ITEMCOUNT] PROGMEM = { 
  {"Upper DBs", m_upper_db_16, NULL, NULL, 1, 0},
  {"Lower DBs", m_lower_db_16, NULL, NULL, 1, 16},
  {"Pedal DBs", m_pedal_db_16, NULL, NULL, 1, 16},
  {"Swell Pedal", 0, NULL, NULL, 0, 127},
  {"Master Volume", 0, &preamp.masterVolume, &sendOrganVolumes, 0, 127},
  {"Amp Gain", 0, &preamp.ampGain, &sendAmpVolume, 0, 127},
  {"SD Flash Tools", m_sd_card_info, NULL, NULL, 0, 127},
  {"Keyboard", m_kbd_driver, NULL, NULL, 0, 0},
  {"Organ Model", 0, &tabs.organModel, &menuOrganModel, 0, 15},
  {"Speaker Model", 0, &tabs.speakerModel, &menuSpeakerModel, 0, 15},
  {"Pitchwheel Pot", 0, NULL, NULL, -1, 31},
  {"End", 0, NULL, NULL, 0, 0},
  {"Upper DB 16", 0, &drawbars.upper[0], &fpga_send_upper_db, 0, 127},
  {"Upper DB 5 1/3", 0, &drawbars.upper[1], &fpga_send_upper_db, 0, 127},
  {"Upper DB 8", 0, &drawbars.upper[2], &fpga_send_upper_db, 0, 127},
  {"Upper DB 4", 0, &drawbars.upper[3], &fpga_send_upper_db, 0, 127},
  {"Upper DB 2 2/3", 0, &drawbars.upper[4], &fpga_send_upper_db, 0, 127},
  {"Upper DB 2", 0, &drawbars.upper[5], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1 3/5", 0, &drawbars.upper[6], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1 1/3", 0, &drawbars.upper[7], &fpga_send_upper_db, 0, 127},
  {"Upper DB 1", 0, &drawbars.upper[8], &fpga_send_upper_db, 0, 127},
  {"Upper DB", -1, NULL, NULL, 0, 0},
  {"Lower DB 16", 0, &drawbars.lower[0], &fpga_send_lower_db, 0, 127},
  {"Lower DB 5 1/3", 0, &drawbars.lower[1], &fpga_send_lower_db, 0, 127},
  {"Lower DB 8", 0, &drawbars.lower[2], &fpga_send_lower_db, 0, 127},
  {"Lower DB 4", 0, &drawbars.lower[3], &fpga_send_lower_db, 0, 127},
  {"Lower DB 2 2/3", 0, &drawbars.lower[4], &fpga_send_lower_db, 0, 127},
  {"Lower DB 2", 0, &drawbars.lower[5], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1 3/5", 0, &drawbars.lower[6], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1 1/3", 0, &drawbars.lower[7], &fpga_send_lower_db, 0, 127},
  {"Lower DB 1", 0, &drawbars.lower[8], &fpga_send_lower_db, 0, 127},
  {"Lower DB", -1, NULL, NULL, 0, 0},
  {"Pedal DB 16", 0, &drawbars.pedal[0], NULL, 0, 127},
  {"Pedal DB 8", 0, &drawbars.pedal[1], NULL, 0, 127},
  {"Pedal DB", -1, NULL, NULL, 0, 0},
  {"SD Card Info", 0, NULL, &sdCardInfo, 0, 0},
  {"Load SD Scan", 0, NULL, &loadScanDriver, 0, 0},
  {"Flash SD Scan", 0, NULL, &flashScanDriver, 0, 0},
  {"Flash FPGA", 0, NULL, &flashFPGA, 0, 0},
  {"Flash Other", 0, NULL, &flashOther, 0, 0},
  {"Reload FPGA", 0, NULL, &organReset, 0, 0},
  {"Test", 0, NULL, NULL, 0, 0},
  {"SD Flash Tools", -1, NULL, NULL, 0, 0},
  {"Kbd Driver", 0, &boardInfo.scan_driverIdx, NULL, 0, drv_custom},
  {"Velocity Min", 0, NULL, NULL, 1, 40},
  {"Velocity MaxAdj", 0, NULL, NULL, 1, 40},
  {"Velocity Slope", 0, &organModel.fatarVelocityFac, NULL, 1, 30},
  {"Upper Base", 0, &midiSettings.channel, NULL, 12, 60},
  {"Lower Base", 0, &midiSettings.channelLower, NULL, 12, 60},
  {"Pedal Base", 0, &midiSettings.channelPedal, NULL, 12, 60},
  {"Kbd Driver", -1, NULL, NULL, 0, 0},
};

// ------------------------------------------------------------------------------

menuEntryType oneMenuEntry; // extrahierter Menüpunkt

void getOneMenuEntry(uint8_t index) {
  // einen Menüpunkt aus PROGMEM lesen und lokal in oneMenuEntry speichern, 
  // damit wir die Werte daraus verwenden können
  if (index >= MENU_ITEMCOUNT) return;
  memcpy_P(&oneMenuEntry, &MenuItems[index], sizeof(menuEntryType));
}

// ------------------------------------------------------------------------------

const String Msg[] = {"FCK TRMP", "FCK AFD"};
int8_t MenuStart;
int8_t MenuEnd;
int8_t MenuItemActive;
int8_t MenuItemReturn;   // speichert bei Untermenüs die Rücksprungposition

#endif
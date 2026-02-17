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

// Action-Routine über Tabelle
typedef void (*action)();

// Wrapper für Routinen mit Parametern oder Text-Parametern, Prototypes
void menuOrganModel();
void menuSpeakerModel();



#define MENU_ITEMCOUNT 50

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

const lcdTextType MenuItems[MENU_ITEMCOUNT] PROGMEM = { 
  { "Upper DBs" },  // #0 
  { "Lower DBs" },  // #1 
  { "Pedal DBs" },  // #2 
  { "Master Volume" },  // #3 
  { "Amp Gain" },  // #4 
  { "SD Flash Tools" },  // #5 
  { "Keyboard" },  // #6 
  { "Organ Model" },  // #7 
  { "Speaker Model" },  // #8 
  { "Pitchwheel Pot" },  // #9 
  { "End" },  // #10 
  { "Upper DB 16" },  // #11 
  { "Upper DB 5 1/3" },  // #12 
  { "Upper DB 8" },  // #13 
  { "Upper DB 4" },  // #14 
  { "Upper DB 2 2/3" },  // #15 
  { "Upper DB 2" },  // #16 
  { "Upper DB 1 3/5" },  // #17 
  { "Upper DB 1 1/3" },  // #18 
  { "Upper DB 1" },  // #19 
  { "Upper DB" },  // #20  EXIT SUBM
  { "Lower DB 16" },  // #21 
  { "Lower DB 5 1/3" },  // #22 
  { "Lower DB 8" },  // #23 
  { "Lower DB 4" },  // #24 
  { "Lower DB 2 2/3" },  // #25 
  { "Lower DB 2" },  // #26 
  { "Lower DB 1 3/5" },  // #27 
  { "Lower DB 1 1/3" },  // #28 
  { "Lower DB 1" },  // #29 
  { "Lower DB" },  // #30  EXIT SUBM
  { "Pedal DB 16" },  // #31 
  { "Pedal DB 8" },  // #32 
  { "Pedal DB" },  // #33  EXIT SUBM
  { "SD Card Info" },  // #34 
  { "Load SD Scan" },  // #35 
  { "Flash SD Scan" },  // #36 
  { "Flash FPGA" },  // #37 
  { "Flash Other" },  // #38 
  { "Reload FPGA" },  // #39 
  { "Test" },  // #40 
  { "Utilities" },  // #41  EXIT SUBM
  { "Kbd Driver" },  // #42 
  { "Velocity Min" },  // #43 
  { "Velocity MaxAdj" },  // #44 
  { "Velocity Slope" },  // #45 
  { "Upper Base" },  // #46 
  { "Lower Base" },  // #47 
  { "Pedal Base" },  // #48 
  { "(Keyboard)" },  // #49  EXIT SUBM
};



const int8_t MenuValueMin[MENU_ITEMCOUNT] = {
  1, // #0 = Upper DBs
  1, // #1 = Lower DBs
  1, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  0, // #5 = SD Flash Tools
  0, // #6 = Keyboard
  0, // #7 = Organ Model
  0, // #8 = Speaker Model
  -1, // #9 = Pitchwheel Pot
  0, // #10 = End
  0, // #11 = Upper DB 16
  0, // #12 = Upper DB 5 1/3
  0, // #13 = Upper DB 8
  0, // #14 = Upper DB 4
  0, // #15 = Upper DB 2 2/3
  0, // #16 = Upper DB 2
  0, // #17 = Upper DB 1 3/5
  0, // #18 = Upper DB 1 1/3
  0, // #19 = Upper DB 1
  0, // #20 = Upper DB EXIT 
  0, // #21 = Lower DB 16
  0, // #22 = Lower DB 5 1/3
  0, // #23 = Lower DB 8
  0, // #24 = Lower DB 4
  0, // #25 = Lower DB 2 2/3
  0, // #26 = Lower DB 2
  0, // #27 = Lower DB 1 3/5
  0, // #28 = Lower DB 1 1/3
  0, // #29 = Lower DB 1
  0, // #30 = Lower DB EXIT 
  0, // #31 = Pedal DB 16
  0, // #32 = Pedal DB 8
  0, // #33 = Pedal DB EXIT 
  0, // #34 = SD Card Info
  0, // #35 = Load SD Scan
  0, // #36 = Flash SD Scan
  0, // #37 = Flash FPGA
  0, // #38 = Flash Other
  0, // #39 = Reload FPGA
  0, // #40 = Test
  0, // #41 = Utilities EXIT 
  0, // #42 = Kbd Driver
  1, // #43 = Velocity Min
  1, // #44 = Velocity MaxAdj
  1, // #45 = Velocity Slope
  12, // #46 = Upper Base
  12, // #47 = Lower Base
  12, // #48 = Pedal Base
  0, // #49 = (Keyboard) EXIT 
};

const int8_t MenuValueMax[MENU_ITEMCOUNT] = {
  0, // #0 = Upper DBs
  16, // #1 = Lower DBs
  16, // #2 = Pedal DBs
  127, // #3 = Master Volume
  127, // #4 = Amp Gain
  127, // #5 = SD Flash Tools
  0, // #6 = Keyboard
  15, // #7 = Organ Model
  15, // #8 = Speaker Model
  31, // #9 = Pitchwheel Pot
  0, // #10 = End
  127, // #11 = Upper DB 16
  127, // #12 = Upper DB 5 1/3
  127, // #13 = Upper DB 8
  127, // #14 = Upper DB 4
  127, // #15 = Upper DB 2 2/3
  127, // #16 = Upper DB 2
  127, // #17 = Upper DB 1 3/5
  127, // #18 = Upper DB 1 1/3
  127, // #19 = Upper DB 1
  0, // #20 = Upper DB EXIT 
  127, // #21 = Lower DB 16
  127, // #22 = Lower DB 5 1/3
  127, // #23 = Lower DB 8
  127, // #24 = Lower DB 4
  127, // #25 = Lower DB 2 2/3
  127, // #26 = Lower DB 2
  127, // #27 = Lower DB 1 3/5
  127, // #28 = Lower DB 1 1/3
  127, // #29 = Lower DB 1
  0, // #30 = Lower DB EXIT 
  127, // #31 = Pedal DB 16
  127, // #32 = Pedal DB 8
  0, // #33 = Pedal DB EXIT 
  0, // #34 = SD Card Info
  0, // #35 = Load SD Scan
  0, // #36 = Flash SD Scan
  0, // #37 = Flash FPGA
  0, // #38 = Flash Other
  0, // #39 = Reload FPGA
  0, // #40 = Test
  0, // #41 = Utilities EXIT 
  drv_custom, // #42 = Kbd Driver
  40, // #43 = Velocity Min
  40, // #44 = Velocity MaxAdj
  30, // #45 = Velocity Slope
  60, // #46 = Upper Base
  60, // #47 = Lower Base
  60, // #48 = Pedal Base
  0, // #49 = (Keyboard) EXIT 
};

const int8_t MenuLink[MENU_ITEMCOUNT] = {
  m_upper_db_16, // #0 = Upper DBs
  m_lower_db_16, // #1 = Lower DBs
  m_pedal_db_16, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  m_sd_card_info, // #5 = SD Flash Tools
  m_kbd_driver, // #6 = Keyboard
  0, // #7 = Organ Model
  0, // #8 = Speaker Model
  0, // #9 = Pitchwheel Pot
  0, // #10 = End
  0, // #11 = Upper DB 16
  0, // #12 = Upper DB 5 1/3
  0, // #13 = Upper DB 8
  0, // #14 = Upper DB 4
  0, // #15 = Upper DB 2 2/3
  0, // #16 = Upper DB 2
  0, // #17 = Upper DB 1 3/5
  0, // #18 = Upper DB 1 1/3
  0, // #19 = Upper DB 1
  -1, // #20 = Upper DB EXIT 
  0, // #21 = Lower DB 16
  0, // #22 = Lower DB 5 1/3
  0, // #23 = Lower DB 8
  0, // #24 = Lower DB 4
  0, // #25 = Lower DB 2 2/3
  0, // #26 = Lower DB 2
  0, // #27 = Lower DB 1 3/5
  0, // #28 = Lower DB 1 1/3
  0, // #29 = Lower DB 1
  -1, // #30 = Lower DB EXIT 
  0, // #31 = Pedal DB 16
  0, // #32 = Pedal DB 8
  -1, // #33 = Pedal DB EXIT 
  0, // #34 = SD Card Info
  0, // #35 = Load SD Scan
  0, // #36 = Flash SD Scan
  0, // #37 = Flash FPGA
  0, // #38 = Flash Other
  0, // #39 = Reload FPGA
  0, // #40 = Test
  -1, // #41 = Utilities EXIT 
  0, // #42 = Kbd Driver
  0, // #43 = Velocity Min
  0, // #44 = Velocity MaxAdj
  0, // #45 = Velocity Slope
  0, // #46 = Upper Base
  0, // #47 = Lower Base
  0, // #48 = Pedal Base
  -1, // #49 = (Keyboard) EXIT 
};


const action EditActions[MENU_ITEMCOUNT] = {
  NULL, // Upper DBs
  NULL, // Lower DBs
  NULL, // Pedal DBs
  &setOrganVolumes, // Master Volume
  &setAmpVolume, // Amp Gain
  NULL, // SD Flash Tools
  NULL, // Keyboard
  &menuOrganModel, // Organ Model
  &menuSpeakerModel, // Speaker Model
  NULL, // Pitchwheel Pot
  NULL, // End
  &fpga_send_upper_db, // Upper DB 16
  &fpga_send_upper_db, // Upper DB 5 1/3
  &fpga_send_upper_db, // Upper DB 8
  &fpga_send_upper_db, // Upper DB 4
  &fpga_send_upper_db, // Upper DB 2 2/3
  &fpga_send_upper_db, // Upper DB 2
  &fpga_send_upper_db, // Upper DB 1 3/5
  &fpga_send_upper_db, // Upper DB 1 1/3
  &fpga_send_upper_db, // Upper DB 1
  NULL, // Upper DB
  &fpga_send_lower_db, // Lower DB 16
  &fpga_send_lower_db, // Lower DB 5 1/3
  &fpga_send_lower_db, // Lower DB 8
  &fpga_send_lower_db, // Lower DB 4
  &fpga_send_lower_db, // Lower DB 2 2/3
  &fpga_send_lower_db, // Lower DB 2
  &fpga_send_lower_db, // Lower DB 1 3/5
  &fpga_send_lower_db, // Lower DB 1 1/3
  &fpga_send_lower_db, // Lower DB 1
  NULL, // Lower DB
  NULL, // Pedal DB 16
  NULL, // Pedal DB 8
  NULL, // Pedal DB
  &sdCardInfo, // SD Card Info
  &loadScanDriver, // Load SD Scan
  &flashScanDriver, // Flash SD Scan
  &flashFPGA, // Flash FPGA
  &flashOther, // Flash Other
  &organReset, // Reload FPGA
  NULL, // Test
  NULL, // Utilities
  NULL, // Kbd Driver
  NULL, // Velocity Min
  NULL, // Velocity MaxAdj
  NULL, // Velocity Slope
  NULL, // Upper Base
  NULL, // Lower Base
  NULL, // Pedal Base
  NULL, // (Keyboard)
};





uint8_t * EditValuePtrs[MENU_ITEMCOUNT] = {
  NULL, // #0 = Upper DBs
  NULL, // #1 = Lower DBs
  NULL, // #2 = Pedal DBs
  &preamp.masterVolume, // #3 = Master Volume
  &preamp.ampVolume, // #4 = Amp Gain
  NULL, // #5 = SD Flash Tools
  NULL, // #6 = Keyboard
  &tabs.organModel, // #7 = Organ Model
  &tabs.speakerModel, // #8 = Speaker Model
  NULL, // #9 = Pitchwheel Pot
  NULL, // #10 = End
  &drawbars.upper[0], // #11 = Upper DB 16
  &drawbars.upper[1], // #12 = Upper DB 5 1/3
  &drawbars.upper[2], // #13 = Upper DB 8
  &drawbars.upper[3], // #14 = Upper DB 4
  &drawbars.upper[4], // #15 = Upper DB 2 2/3
  &drawbars.upper[5], // #16 = Upper DB 2
  &drawbars.upper[6], // #17 = Upper DB 1 3/5
  &drawbars.upper[7], // #18 = Upper DB 1 1/3
  &drawbars.upper[8], // #19 = Upper DB 1
  NULL, // #20 = Upper DB EXIT 
  &drawbars.lower[0], // #21 = Lower DB 16
  &drawbars.lower[1], // #22 = Lower DB 5 1/3
  &drawbars.lower[2], // #23 = Lower DB 8
  &drawbars.lower[3], // #24 = Lower DB 4
  &drawbars.lower[4], // #25 = Lower DB 2 2/3
  &drawbars.lower[5], // #26 = Lower DB 2
  &drawbars.lower[6], // #27 = Lower DB 1 3/5
  &drawbars.lower[7], // #28 = Lower DB 1 1/3
  &drawbars.lower[8], // #29 = Lower DB 1
  NULL, // #30 = Lower DB EXIT 
  &drawbars.pedal[0], // #31 = Pedal DB 16
  &drawbars.pedal[1], // #32 = Pedal DB 8
  NULL, // #33 = Pedal DB EXIT 
  NULL, // #34 = SD Card Info
  NULL, // #35 = Load SD Scan
  NULL, // #36 = Flash SD Scan
  NULL, // #37 = Flash FPGA
  NULL, // #38 = Flash Other
  NULL, // #39 = Reload FPGA
  NULL, // #40 = Test
  NULL, // #41 = Utilities EXIT 
  &boardInfo.scan_driverIdx, // #42 = Kbd Driver
  NULL, // #43 = Velocity Min
  NULL, // #44 = Velocity MaxAdj
  &organModel.fatarVelocityFac, // #45 = Velocity Slope
  &midiSettings.channel, // #46 = Upper Base
  &midiSettings.channelLower, // #47 = Lower Base
  &midiSettings.channelPedal, // #48 = Pedal Base
  NULL, // #49 = (Keyboard) EXIT 
};



// ------------------------------------------------------------------------------

const String Msg[] = {"FCK TRMP", "FCK AFD"};
int8_t MenuStart;
int8_t MenuEnd;
int8_t MenuItemActive;
int8_t MenuItemReturn;   // speichert bei Untermenüs die Rücksprungposition

#endif
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

// Menu System Variables

#define MENU_DRIVERCOUNT 4
enum {drv_sr61, drv_fatar1, drv_fatar2, drv_custom};
const lcdTextType DriverTypes[MENU_DRIVERCOUNT] PROGMEM = {
  { "Scan16/61" },
  { "FatarScan1-61" },
  { "FatarScan2" },
  { "Custom" },
};

// Menu Actions, die bei Änderung eines Menüpunktes ausgeführt werden sollen
enum {
  ac_none, // Upper DBs
  ac_upper_db, // Upper DB 16
  ac_lower_db, // Lower DB 16
  ac_pedal_db, // Pedal DB 16
  ac_volume, // Master Volume
  ac_kbd_driver,
  ac_pitchwheel_pot,
  ac_velocity_min,
  ac_velocity_maxadj,
  ac_velocity_slope,
  ac_upper_base,
  ac_lower_base,
  ac_pedal_base,
  ac_sd_card_init,
  ac_load_sd_scan,
  ac_flash_sd_scan,
  ac_flash_fpga,
  ac_flash_other,
  ac_reload_fpga,
  ac_test,
};

#define MENU_ITEMCOUNT 48

// ------------------------------------------------------------------------------
// Hier Daten aus Excel-Tabelle einfügen, die die Menüstruktur definiert.
// Es müssen 1 enum-Liste und 5 Arrays mit gleicher Länge angelegt werden.
// MenuLink[MENU_ITEMCOUNT] definiert die Menüstruktur:
// 0 normaler Edit-Menüpunkt, der mit Encoder geändert werden kann
// >0 ist die Nummer des Submenüpunktes, zu dem verlinkt wird
// -1 Rücksprungmöglichkeit (Exit) zum Hauptmenü
// ------------------------------------------------------------------------------

enum {
  m_upper_dbs, // #0 = Upper DBs
  m_lower_dbs, // #1 = Lower DBs
  m_pedal_dbs, // #2 = Pedal DBs
  m_master_volume, // #3 = Master Volume
  m_amp_gain, // #4 = Amp Gain
  m_sd_flash_tools, // #5 = Utilities
  m_keyboard, // #6 = Keyboard
  m_pitchwheel_pot, // #7 = Pitchwheel Pot
  m_end, // #8 = End
  m_upper_db_16, // #9 = Upper DB 16
  m_upper_db_5_13, // #10 = Upper DB 5 1/3
  m_upper_db_8, // #11 = Upper DB 8
  m_upper_db_4, // #12 = Upper DB 4
  m_upper_db_2_23, // #13 = Upper DB 2 2/3
  m_upper_db_2, // #14 = Upper DB 2
  m_upper_db_1_35, // #15 = Upper DB 1 3/5
  m_upper_db_1_13, // #16 = Upper DB 1 1/3
  m_upper_db_1, // #17 = Upper DB 1
  m_back_18, // #18 = Upper DB EXIT 
  m_lower_db_16, // #19 = Lower DB 16
  m_lower_db_5_13, // #20 = Lower DB 5 1/3
  m_lower_db_8, // #21 = Lower DB 8
  m_lower_db_4, // #22 = Lower DB 4
  m_lower_db_2_23, // #23 = Lower DB 2 2/3
  m_lower_db_2, // #24 = Lower DB 2
  m_lower_db_1_35, // #25 = Lower DB 1 3/5
  m_lower_db_1_13, // #26 = Lower DB 1 1/3
  m_lower_db_1, // #27 = Lower DB 1
  m_back_28, // #28 = Lower DB EXIT 
  m_pedal_db_16, // #29 = Pedal DB 16
  m_pedal_db_8, // #30 = Pedal DB 8
  m_back_31, // #31 = Pedal DB EXIT 
  m_sd_card_init, // #32 = SD Card Init
  m_load_sd_scan, // #33 = Load SD Scan
  m_flash_sd_scan, // #34 = Flash SD Scan
  m_flash_fpga, // #35 = Flash FPGA
  m_flash_other, // #36 = Flash Other
  m_reload_fpga, // #37 = Reload FPGA
  m_test, // #38 = Test
  m_back_39, // #39 = Utilities EXIT 
  m_kbd_driver, // #40 = Kbd Driver
  m_velocity_min, // #41 = Velocity Min
  m_velocity_maxadj, // #42 = Velocity MaxAdj
  m_velocity_slope, // #43 = Velocity Slope
  m_upper_base, // #44 = Upper Base
  m_lower_base, // #45 = Lower Base
  m_pedal_base, // #46 = Pedal Base
  m_back_47, // #47 = (Keyboard) EXIT 
};
const lcdTextType MenuItems[MENU_ITEMCOUNT] PROGMEM = { 
  { "Upper DBs" },  // #0 
  { "Lower DBs" },  // #1 
  { "Pedal DBs" },  // #2 
  { "Master Volume" },  // #3 
  { "Amp Gain" },  // #4 
  { "Utilities" },  // #5 
  { "Keyboard" },  // #6 
  { "Pitchwheel Pot" },  // #7 
  { "End" },  // #8 
  { "Upper DB 16" },  // #9 
  { "Upper DB 5 1/3" },  // #10 
  { "Upper DB 8" },  // #11 
  { "Upper DB 4" },  // #12 
  { "Upper DB 2 2/3" },  // #13 
  { "Upper DB 2" },  // #14 
  { "Upper DB 1 3/5" },  // #15 
  { "Upper DB 1 1/3" },  // #16 
  { "Upper DB 1" },  // #17 
  { "Upper DB" },  // #18  EXIT SUBM
  { "Lower DB 16" },  // #19 
  { "Lower DB 5 1/3" },  // #20 
  { "Lower DB 8" },  // #21 
  { "Lower DB 4" },  // #22 
  { "Lower DB 2 2/3" },  // #23 
  { "Lower DB 2" },  // #24 
  { "Lower DB 1 3/5" },  // #25 
  { "Lower DB 1 1/3" },  // #26 
  { "Lower DB 1" },  // #27 
  { "Lower DB" },  // #28  EXIT SUBM
  { "Pedal DB 16" },  // #29 
  { "Pedal DB 8" },  // #30 
  { "Pedal DB" },  // #31  EXIT SUBM
  { "SD Card Init" },  // #32 
  { "Load SD Scan" },  // #33 
  { "Flash SD Scan" },  // #34 
  { "Flash FPGA" },  // #35 
  { "Flash Other" },  // #36 
  { "Reload FPGA" },  // #37 
  { "Test" },  // #38 
  { "SD Flash Tools" },  // #39  EXIT SUBM
  { "Kbd Driver" },  // #40 
  { "Velocity Min" },  // #41 
  { "Velocity MaxAdj" },  // #42 
  { "Velocity Slope" },  // #43 
  { "Upper Base" },  // #44 
  { "Lower Base" },  // #45 
  { "Pedal Base" },  // #46 
  { "(Keyboard)" },  // #47  EXIT SUBM
};
const int8_t MenuValueMin[MENU_ITEMCOUNT] = {
  1, // #0 = Upper DBs
  1, // #1 = Lower DBs
  1, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  0, // #5 = Utilities
  0, // #6 = Keyboard
  -1, // #7 = Pitchwheel Pot
  0, // #8 = End
  0, // #9 = Upper DB 16
  0, // #10 = Upper DB 5 1/3
  0, // #11 = Upper DB 8
  0, // #12 = Upper DB 4
  0, // #13 = Upper DB 2 2/3
  0, // #14 = Upper DB 2
  0, // #15 = Upper DB 1 3/5
  0, // #16 = Upper DB 1 1/3
  0, // #17 = Upper DB 1
  0, // #18 = Upper DB EXIT 
  0, // #19 = Lower DB 16
  0, // #20 = Lower DB 5 1/3
  0, // #21 = Lower DB 8
  0, // #22 = Lower DB 4
  0, // #23 = Lower DB 2 2/3
  0, // #24 = Lower DB 2
  0, // #25 = Lower DB 1 3/5
  0, // #26 = Lower DB 1 1/3
  0, // #27 = Lower DB 1
  0, // #28 = Lower DB EXIT 
  0, // #29 = Pedal DB 16
  0, // #30 = Pedal DB 8
  0, // #31 = Pedal DB EXIT 
  0, // #32 = SD Card Init
  0, // #33 = Load SD Scan
  0, // #34 = Flash SD Scan
  0, // #35 = Flash FPGA
  0, // #36 = Flash All
  0, // #37 = Reload FPGA
  0, // #38 = Test
  0, // #39 = SD Flash Tools EXIT 
  0, // #40 = Kbd Driver
  1, // #41 = Velocity Min
  1, // #42 = Velocity MaxAdj
  1, // #43 = Velocity Slope
  12, // #44 = Upper Base
  12, // #45 = Lower Base
  12, // #46 = Pedal Base
  0, // #47 = (Keyboard) EXIT 
};
const int8_t MenuValueMax[MENU_ITEMCOUNT] = {
  0, // #0 = Upper DBs
  16, // #1 = Lower DBs
  16, // #2 = Pedal DBs
  127, // #3 = Master Volume
  127, // #4 = Amp Gain
  127, // #5 = Utilities
  0, // #6 = Keyboard
  31, // #7 = Pitchwheel Pot
  0, // #8 = End
  127, // #9 = Upper DB 16
  127, // #10 = Upper DB 5 1/3
  127, // #11 = Upper DB 8
  127, // #12 = Upper DB 4
  127, // #13 = Upper DB 2 2/3
  127, // #14 = Upper DB 2
  127, // #15 = Upper DB 1 3/5
  127, // #16 = Upper DB 1 1/3
  127, // #17 = Upper DB 1
  0, // #18 = Upper DB EXIT 
  127, // #19 = Lower DB 16
  127, // #20 = Lower DB 5 1/3
  127, // #21 = Lower DB 8
  127, // #22 = Lower DB 4
  127, // #23 = Lower DB 2 2/3
  127, // #24 = Lower DB 2
  127, // #25 = Lower DB 1 3/5
  127, // #26 = Lower DB 1 1/3
  127, // #27 = Lower DB 1
  0, // #28 = Lower DB EXIT 
  127, // #29 = Pedal DB 16
  127, // #30 = Pedal DB 8
  0, // #31 = Pedal DB EXIT 
  0, // #32 = SD Card Init
  0, // #33 = Load SD Scan
  0, // #34 = Flash SD Scan
  0, // #35 = Flash FPGA
  0, // #36 = Flash All
  0, // #37 = Reload FPGA
  0, // #38 = Test
  0, // #39 = Utilities EXIT 
  drv_custom, // #40 = Kbd Driver
  40, // #41 = Velocity Min
  40, // #42 = Velocity MaxAdj
  30, // #43 = Velocity Slope
  60, // #44 = Upper Base
  60, // #45 = Lower Base
  60, // #46 = Pedal Base
  0, // #47 = (Keyboard) EXIT 
};
const int8_t MenuLink[MENU_ITEMCOUNT] = {
  m_upper_db_16, // #0 = Upper DBs
  m_lower_db_16, // #1 = Lower DBs
  m_pedal_db_16, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  m_sd_card_init, // #5 = Utilities
  m_kbd_driver, // #6 = Keyboard
  0, // #7 = Pitchwheel Pot
  0, // #8 = End
  0, // #9 = Upper DB 16
  0, // #10 = Upper DB 5 1/3
  0, // #11 = Upper DB 8
  0, // #12 = Upper DB 4
  0, // #13 = Upper DB 2 2/3
  0, // #14 = Upper DB 2
  0, // #15 = Upper DB 1 3/5
  0, // #16 = Upper DB 1 1/3
  0, // #17 = Upper DB 1
  -1, // #18 = Upper DB EXIT 
  0, // #19 = Lower DB 16
  0, // #20 = Lower DB 5 1/3
  0, // #21 = Lower DB 8
  0, // #22 = Lower DB 4
  0, // #23 = Lower DB 2 2/3
  0, // #24 = Lower DB 2
  0, // #25 = Lower DB 1 3/5
  0, // #26 = Lower DB 1 1/3
  0, // #27 = Lower DB 1
  -1, // #28 = Lower DB EXIT 
  0, // #29 = Pedal DB 16
  0, // #30 = Pedal DB 8
  -1, // #31 = Pedal DB EXIT 
  0, // #32 = SD Card Init
  0, // #33 = Load SD Scan
  0, // #34 = Flash SD Scan
  0, // #35 = Flash FPGA
  0, // #36 = Flash All
  0, // #37 = Reload FPGA
  0, // #38 = Test
  -1, // #39 = Utilities EXIT 
  0, // #40 = Kbd Driver
  0, // #41 = Velocity Min
  0, // #42 = Velocity MaxAdj
  0, // #43 = Velocity Slope
  0, // #44 = Upper Base
  0, // #45 = Lower Base
  0, // #46 = Pedal Base
  -1, // #47 = (Keyboard) EXIT 
};

const int8_t EditAction[MENU_ITEMCOUNT] = {
  ac_none, // Upper DBs
  ac_none, // Lower DBs
  ac_none, // Pedal DBs
  ac_volume, // Master Volume
  ac_volume, // Amp Gain
  ac_none, // SD Flash Tools
  ac_none, // Keyboard
  ac_pitchwheel_pot, // Pitchwheel Pot
  ac_none, // End
  ac_upper_db, // Upper DB 16
  ac_upper_db, // Upper DB 5 1/3
  ac_upper_db, // Upper DB 8
  ac_upper_db, // Upper DB 4
  ac_upper_db, // Upper DB 2 2/3
  ac_upper_db, // Upper DB 2
  ac_upper_db, // Upper DB 1 3/5
  ac_upper_db, // Upper DB 1 1/3
  ac_upper_db, // Upper DB 1
  ac_none, // Upper DB
  ac_lower_db, // Lower DB 16
  ac_lower_db, // Lower DB 5 1/3
  ac_lower_db, // Lower DB 8
  ac_lower_db, // Lower DB 4
  ac_lower_db, // Lower DB 2 2/3
  ac_lower_db, // Lower DB 2
  ac_lower_db, // Lower DB 1 3/5
  ac_lower_db, // Lower DB 1 1/3
  ac_lower_db, // Lower DB 1
  ac_none, // Lower DB
  ac_pedal_db, // Pedal DB 16
  ac_pedal_db, // Pedal DB 8
  ac_none, // Pedal DB
  ac_sd_card_init, // SD Card Init
  ac_load_sd_scan, // Load SD Scan
  ac_flash_sd_scan, // Flash SD Scan
  ac_flash_fpga, // Flash FPGA
  ac_flash_other, // Flash Other
  ac_reload_fpga, // Reload FPGA
  ac_test, // Test
  ac_none, // SD Flash Tools
  ac_kbd_driver, // Kbd Driver
  ac_velocity_min, // Velocity Min
  ac_velocity_maxadj, // Velocity MaxAdj
  ac_velocity_slope, // Velocity Slope
  ac_upper_base, // Upper Base
  ac_lower_base, // Lower Base
  ac_pedal_base, // Pedal Base
  ac_none, // (Keyboard)
};

int8_t EditValues[MENU_ITEMCOUNT] = {
  0, // #0 = Upper DBs
  0, // #1 = Lower DBs
  0, // #2 = Pedal DBs
  127, // #3 = Master Volume
  40, // #4 = Amp Gain
  -47, // #5 = SD Flash Tools
  0, // #6 = Keyboard
  -1, // #7 = Pitchwheel Pot
  0, // #8 = End
  127, // #9 = Upper DB 16
  127, // #10 = Upper DB 5 1/3
  127, // #11 = Upper DB 8
  50, // #12 = Upper DB 4
  0, // #13 = Upper DB 2 2/3
  0, // #14 = Upper DB 2
  0, // #15 = Upper DB 1 3/5
  0, // #16 = Upper DB 1 1/3
  0, // #17 = Upper DB 1
  0, // #18 = Upper DB EXIT 
  0, // #19 = Lower DB 16
  0, // #20 = Lower DB 5 1/3
  127, // #21 = Lower DB 8
  127, // #22 = Lower DB 4
  40, // #23 = Lower DB 2 2/3
  0, // #24 = Lower DB 2
  0, // #25 = Lower DB 1 3/5
  0, // #26 = Lower DB 1 1/3
  0, // #27 = Lower DB 1
  0, // #28 = Lower DB EXIT 
  127, // #29 = Pedal DB 16
  60, // #30 = Pedal DB 8
  0, // #31 = Pedal DB EXIT 
  127, // #32 = SD Card Init
  127, // #33 = Load SD Scan
  127, // #34 = Flash SD Scan
  127, // #35 = Flash FPGA
  127, // #36 = Flash All
  127, // #37 = Reload FPGA
  127, // #38 = Test
  0, // #39 = Utilities EXIT 
  drv_fatar1, // #40 = Kbd Driver
  MIDI_MINDYN, // #41 = Velocity Min
  MIDI_MAXDYNADJ, // #42 = Velocity MaxAdj
  MIDI_DYNSLOPE, // #43 = Velocity Slope
  MIDI_BASE_UPR, // #44 = Upper Base
  MIDI_BASE_LWR, // #45 = Lower Base
  MIDI_BASE_PED, // #46 = Pedal Base
  0, // #47 = (Keyboard) EXIT 
};

// ------------------------------------------------------------------------------

const String Msg[] = {"FCK TRMP", "FCK AFD"};
int8_t MenuStart;
int8_t MenuEnd;
int8_t MenuItemActive;
int8_t MenuItemReturn;   // speichert bei Untermenüs die Rücksprungposition

#endif
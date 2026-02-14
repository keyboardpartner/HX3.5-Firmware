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
};

#define MENU_ITEMCOUNT 41

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
  m_keyboard, // #5 = Keyboard
  m_pitchwheel_pot, // #6 = Pitchwheel Pot
  m_end, // #7 = End
  m_upper_db_16, // #8 = Upper DB 16
  m_upper_db_5_13, // #9 = Upper DB 5 1/3
  m_upper_db_8, // #10 = Upper DB 8
  m_upper_db_4, // #11 = Upper DB 4
  m_upper_db_2_23, // #12 = Upper DB 2 2/3
  m_upper_db_2, // #13 = Upper DB 2
  m_upper_db_1_35, // #14 = Upper DB 1 3/5
  m_upper_db_1_13, // #15 = Upper DB 1 1/3
  m_upper_db_1, // #16 = Upper DB 1
  m_back_17, // #17 = Upper DB EXIT
  m_lower_db_16, // #18 = Lower DB 16
  m_lower_db_5_13, // #19 = Lower DB 5 1/3
  m_lower_db_8, // #20 = Lower DB 8
  m_lower_db_4, // #21 = Lower DB 4
  m_lower_db_2_23, // #22 = Lower DB 2 2/3
  m_lower_db_2, // #23 = Lower DB 2
  m_lower_db_1_35, // #24 = Lower DB 1 3/5
  m_lower_db_1_13, // #25 = Lower DB 1 1/3
  m_lower_db_1, // #26 = Lower DB 1
  m_back_27, // #27 = Lower DB EXIT
  m_pedal_db_16, // #28 = Pedal DB 16
  m_pedal_db_8, // #29 = Pedal DB 8
  m_back_30, // #30 = Pedal DB EXIT
  m_kbd_driver, // #31 = Kbd Driver
  m_velocity_min, // #32 = Velocity Min
  m_velocity_maxadj, // #33 = Velocity MaxAdj
  m_velocity_slope, // #34 = Velocity Slope
  m_upper_base, // #35 = Upper Base
  m_lower_base, // #36 = Lower Base
  m_pedal_base, // #37 = Pedal Base
  m_back_38, // #38 = (Keyboard) EXIT
};
const lcdTextType MenuItems[MENU_ITEMCOUNT] PROGMEM = {
  { "Upper DBs" },  // #0
  { "Lower DBs" },  // #1
  { "Pedal DBs" },  // #2
  { "Master Volume" },  // #3
  { "Amp Gain" },  // #4
  { "Keyboard" },  // #5
  { "Pitchwheel Pot" },  // #6
  { "End" },  // #7
  { "Upper DB 16" },  // #8
  { "Upper DB 5 1/3" },  // #9
  { "Upper DB 8" },  // #10
  { "Upper DB 4" },  // #11
  { "Upper DB 2 2/3" },  // #12
  { "Upper DB 2" },  // #13
  { "Upper DB 1 3/5" },  // #14
  { "Upper DB 1 1/3" },  // #15
  { "Upper DB 1" },  // #16
  { "Upper DB" },  // #17  EXIT SUBM
  { "Lower DB 16" },  // #18
  { "Lower DB 5 1/3" },  // #19
  { "Lower DB 8" },  // #20
  { "Lower DB 4" },  // #21
  { "Lower DB 2 2/3" },  // #22
  { "Lower DB 2" },  // #23
  { "Lower DB 1 3/5" },  // #24
  { "Lower DB 1 1/3" },  // #25
  { "Lower DB 1" },  // #26
  { "Lower DB" },  // #27  EXIT SUBM
  { "Pedal DB 16" },  // #28
  { "Pedal DB 8" },  // #29
  { "Pedal DB" },  // #30  EXIT SUBM
  { "Kbd Driver" },  // #31
  { "Velocity Min" },  // #32
  { "Velocity MaxAdj" },  // #33
  { "Velocity Slope" },  // #34
  { "Upper Base" },  // #35
  { "Lower Base" },  // #36
  { "Pedal Base" },  // #37
  { "(Keyboard)" },  // #38  EXIT SUBM
};
const int8_t MenuValueMin[MENU_ITEMCOUNT] = {
  1, // #0 = Upper DBs
  1, // #1 = Lower DBs
  1, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  0, // #5 = Keyboard
  -1, // #6 = Pitchwheel Pot
  0, // #7 = End
  0, // #8 = Upper DB 16
  0, // #9 = Upper DB 5 1/3
  0, // #10 = Upper DB 8
  0, // #11 = Upper DB 4
  0, // #12 = Upper DB 2 2/3
  0, // #13 = Upper DB 2
  0, // #14 = Upper DB 1 3/5
  0, // #15 = Upper DB 1 1/3
  0, // #16 = Upper DB 1
  0, // #17 = Upper DB EXIT
  0, // #18 = Lower DB 16
  0, // #19 = Lower DB 5 1/3
  0, // #20 = Lower DB 8
  0, // #21 = Lower DB 4
  0, // #22 = Lower DB 2 2/3
  0, // #23 = Lower DB 2
  0, // #24 = Lower DB 1 3/5
  0, // #25 = Lower DB 1 1/3
  0, // #26 = Lower DB 1
  0, // #27 = Lower DB EXIT
  0, // #28 = Pedal DB 16
  0, // #29 = Pedal DB 8
  0, // #30 = Pedal DB EXIT
  0, // #31 = Kbd Driver
  1, // #32 = Velocity Min
  1, // #33 = Velocity MaxAdj
  1, // #34 = Velocity Slope
  12, // #35 = Upper Base
  12, // #36 = Lower Base
  12, // #37 = Pedal Base
  0, // #38 = (Keyboard) EXIT
};
const int8_t MenuValueMax[MENU_ITEMCOUNT] = {
  0, // #0 = Upper DBs
  16, // #1 = Lower DBs
  16, // #2 = Pedal DBs
  127, // #3 = Master Volume
  127, // #4 = Amp Gain
  0, // #5 = Keyboard
  31, // #6 = Pitchwheel Pot
  0, // #7 = End
  127, // #8 = Upper DB 16
  127, // #9 = Upper DB 5 1/3
  127, // #10 = Upper DB 8
  127, // #11 = Upper DB 4
  127, // #12 = Upper DB 2 2/3
  127, // #13 = Upper DB 2
  127, // #14 = Upper DB 1 3/5
  127, // #15 = Upper DB 1 1/3
  127, // #16 = Upper DB 1
  0, // #17 = Upper DB EXIT
  127, // #18 = Lower DB 16
  127, // #19 = Lower DB 5 1/3
  127, // #20 = Lower DB 8
  127, // #21 = Lower DB 4
  127, // #22 = Lower DB 2 2/3
  127, // #23 = Lower DB 2
  127, // #24 = Lower DB 1 3/5
  127, // #25 = Lower DB 1 1/3
  127, // #26 = Lower DB 1
  0, // #27 = Lower DB EXIT
  127, // #28 = Pedal DB 16
  127, // #29 = Pedal DB 8
  0, // #30 = Pedal DB EXIT
  drv_custom, // #31 = Kbd Driver
  40, // #32 = Velocity Min
  40, // #33 = Velocity MaxAdj
  30, // #34 = Velocity Slope
  60, // #35 = Upper Base
  60, // #36 = Lower Base
  60, // #37 = Pedal Base
  0, // #38 = (Keyboard) EXIT
};
const int8_t MenuLink[MENU_ITEMCOUNT] = {
  m_upper_db_16, // #0 = Upper DBs
  m_lower_db_16, // #1 = Lower DBs
  m_pedal_db_16, // #2 = Pedal DBs
  0, // #3 = Master Volume
  0, // #4 = Amp Gain
  m_kbd_driver, // #5 = Keyboard
  0, // #6 = Pitchwheel Pot
  0, // #7 = End
  0, // #8 = Upper DB 16
  0, // #9 = Upper DB 5 1/3
  0, // #10 = Upper DB 8
  0, // #11 = Upper DB 4
  0, // #12 = Upper DB 2 2/3
  0, // #13 = Upper DB 2
  0, // #14 = Upper DB 1 3/5
  0, // #15 = Upper DB 1 1/3
  0, // #16 = Upper DB 1
  -1, // #17 = Upper DB EXIT
  0, // #18 = Lower DB 16
  0, // #19 = Lower DB 5 1/3
  0, // #20 = Lower DB 8
  0, // #21 = Lower DB 4
  0, // #22 = Lower DB 2 2/3
  0, // #23 = Lower DB 2
  0, // #24 = Lower DB 1 3/5
  0, // #25 = Lower DB 1 1/3
  0, // #26 = Lower DB 1
  -1, // #27 = Lower DB EXIT
  0, // #28 = Pedal DB 16
  0, // #29 = Pedal DB 8
  -1, // #30 = Pedal DB EXIT
  0, // #31 = Kbd Driver
  0, // #32 = Velocity Min
  0, // #33 = Velocity MaxAdj
  0, // #34 = Velocity Slope
  0, // #35 = Upper Base
  0, // #36 = Lower Base
  0, // #37 = Pedal Base
  -1, // #38 = (Keyboard) EXIT
};
const int8_t EditAction[MENU_ITEMCOUNT] = {
  ac_none, // Upper DBs
  ac_none, // Lower DBs
  ac_none, // Pedal DBs
  ac_volume, // Master Volume
  ac_volume, // Amp Gain
  ac_none, // Keyboard
  ac_none, // Pitchwheel Pot
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
  ac_none, // Kbd Driver
  ac_none, // Velocity Min
  ac_none, // Velocity MaxAdj
  ac_none, // Velocity Slope
  ac_none, // Upper Base
  ac_none, // Lower Base
  ac_none, // Pedal Base
  ac_none, // (Keyboard)
};
int8_t EditValues[MENU_ITEMCOUNT] = {
  0, // #0 = Upper DBs
  0, // #1 = Lower DBs
  0, // #2 = Pedal DBs
  127, // #3 = Master Volume
  40, // #4 = Amp Gain
  0, // #5 = Keyboard
  -1, // #6 = Pitchwheel Pot
  0, // #7 = End
  127, // #8 = Upper DB 16
  127, // #9 = Upper DB 5 1/3
  127, // #10 = Upper DB 8
  50, // #11 = Upper DB 4
  0, // #12 = Upper DB 2 2/3
  0, // #13 = Upper DB 2
  0, // #14 = Upper DB 1 3/5
  0, // #15 = Upper DB 1 1/3
  0, // #16 = Upper DB 1
  0, // #17 = Upper DB EXIT
  0, // #18 = Lower DB 16
  0, // #19 = Lower DB 5 1/3
  127, // #20 = Lower DB 8
  127, // #21 = Lower DB 4
  40, // #22 = Lower DB 2 2/3
  0, // #23 = Lower DB 2
  0, // #24 = Lower DB 1 3/5
  0, // #25 = Lower DB 1 1/3
  0, // #26 = Lower DB 1
  0, // #27 = Lower DB EXIT
  127, // #28 = Pedal DB 16
  60, // #29 = Pedal DB 8
  0, // #30 = Pedal DB EXIT
  drv_fatar1, // #31 = Kbd Driver
  MIDI_MINDYN, // #32 = Velocity Min
  MIDI_MAXDYNADJ, // #33 = Velocity MaxAdj
  MIDI_DYNSLOPE, // #34 = Velocity Slope
  MIDI_BASE_UPR, // #35 = Upper Base
  MIDI_BASE_LWR, // #36 = Lower Base
  MIDI_BASE_PED, // #37 = Pedal Base
  0, // #38 = (Keyboard) EXIT
};


// ------------------------------------------------------------------------------

const String Msg[] = {"FCK TRMP", "FCK AFD"};
int8_t MenuStart;
int8_t MenuEnd;
int8_t MenuItemActive;
int8_t MenuItemReturn;   // speichert bei Untermenüs die Rücksprungposition

#endif
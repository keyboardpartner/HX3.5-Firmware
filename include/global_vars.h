#ifndef global_vars_h
#define global_vars_h

// #############################################################################
//
//      #####  #       ####### ######     #    #        #####  
//     #     # #       #     # #     #   # #   #       #     # 
//     #       #       #     # #     #  #   #  #       #       
//     #  #### #       #     # ######  #     # #        #####  
//     #     # #       #     # #     # ####### #             # 
//     #     # #       #     # #     # #     # #       #     # 
//      #####  ####### ####### ######  #     # #######  #####  
//                                                             
// #############################################################################

#include <Arduino.h>
#include "MenuPanel.h"
#include <avr/io.h> // add "platformio/framework-arduino-avr-mightycore@^3.0.2" to platformio.ini!
#include <SdFat.h>

#define VERSION "HX3.5 v0.01"
#define CREATOR "C.Meyer 2/2026"

#define FIRMWARE_VERSION 0x02 // Vergleichswert für EEPROM, um veraltete Versionen zu erkennen
#define PRESET_VERSION 60 
#define EEPROM_VERSION_IDX 0x08 // Adresse des Vergleichwerts
#define EEPROM_MENUDEF_IDX 0x10 // Startadresse im EEPROM für gespeicherte Werte

#define LICENSE_ORGAN 9523781
#define LICENSE_EXTENDED 3316044

#define MIDI_MINDYN 10
#define MIDI_DYNSLOPE 12
#define MIDI_MAXDYNADJ 5

// ATMEL ATMEGA644P

#define LED_PIN PIN_PD2  // Pin für LED
#define PWR_GOOD PIN_PD7 // Pin für DSP-Reset

#define _NOP_DLY asm volatile ("nop")

#ifdef DEBUG
#define DPRINT(...)    Serial.print(__VA_ARGS__)
//OR, #define DPRINT(args...)    Serial.print(args)
#define DPRINTLN(...)  Serial.println(__VA_ARGS__)
#define DPRINTF(...)    Serial.print(F(__VA_ARGS__))
#define DPRINTLNF(...) Serial.println(F(__VA_ARGS__)) //printing text using the F macro
#else
#define DPRINT(...)     //blank line
#define DPRINTLN(...)   //blank line
#define DPRINTF(...)    //blank line
#define DPRINTLNF(...)  //blank line
#define DBEGIN(...)     //blank line
#endif

// #define VAL_DEBUG // define this to enable debug prints for variable values

#ifdef VAL_DEBUG
#define DVPRINT(...)    Serial.print(__VA_ARGS__)
//OR, #define DVPRINT(args...)    Serial.print(args)
#define DVPRINTLN(...)  Serial.println(__VA_ARGS__)
#define DVPRINTF(...)    Serial.print(F(__VA_ARGS__))
#define DVPRINTLNF(...) Serial.println(F(__VA_ARGS__)) //printing text using the F macro
#else
#define DVPRINT(...)     //blank line
#define DVPRINTLN(...)   //blank line
#define DVPRINTF(...)    //blank line
#define DVPRINTLNF(...)  //blank line
#define DVBEGIN(...)     //blank line
#endif

// Default MIDI Einstellungen
#define MIDI_BASE_UPR 36
#define MIDI_BASE_LWR 36
#define MIDI_BASE_PED 36

#define MIDI_CH_UPR 1
#define MIDI_CH_LWR 2
#define MIDI_CH_PED 3

MenuPanel lcd(LCD_I2C_ADDR, 16, 2);
File myFile;

// #############################################################################
//
//    ########   #######     ###    ########  ########  
//    ##     ## ##     ##   ## ##   ##     ## ##     ## 
//    ##     ## ##     ##  ##   ##  ##     ## ##     ## 
//    ########  ##     ## ##     ## ########  ##     ## 
//    ##     ## ##     ## ######### ##   ##   ##     ## 
//    ##     ## ##     ## ##     ## ##    ##  ##     ## 
//    ########   #######  ##     ## ##     ## ########  
//
// #############################################################################


enum { bm_toggle = 0,  bm_press = 1 };
const uint8_t buttonModes[16] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, bm_press, bm_press, bm_press, bm_press};

volatile uint8_t Timer1Semaphore = 0;
volatile uint8_t Timer1RoundRobin = 0;
bool fpgaOK = false;

 
struct {
  union {
    uint8_t channel = 0;
    uint8_t channelUpper;
  };
  uint8_t channelLower = 1; // noch nicht implementiert
  uint8_t channelPedal = 2; // noch nicht implementiert
} midiSettings;


struct {
  uint32_t fpga_version;
  uint32_t fpga_serial;
  uint32_t fpga_organ;
  uint32_t fpga_rotary;
  uint8_t fpga_valid;
  uint8_t scan_id;
  uint8_t scan_version;
  uint8_t scan_driverIdx;
  uint8_t scan_validflag;
} boardInfo;

// ------------------
// TABS/SWITCHES
// ------------------

struct {
  uint8_t dummy_0 = 0;
  uint8_t vibKnobMode = 0;
  uint8_t presetMask = 159;
  uint8_t dummy_1 = 0;
  uint8_t dummy_2 = 0;
  uint8_t config_1 = 0;
  uint8_t config_2 = 0;
  uint8_t adcConfig = 1;
  uint8_t voice1stDBset = 0;
  uint8_t voice2ndDBset = 40;
  uint8_t configPedal = 0;
  uint8_t adcScaling = 100;
  uint8_t adcHysteresis = 4;
  uint8_t deviceType = 0;
  uint8_t structureVersion = 60;
  uint8_t adcHmagicFlag = 0xAA; // Vergleichswert für EEPROM, um veraltete Versionen zu erkennen
  // Aliasses für config_1:
  bool swapPresetRowsUpper = false;
  bool swapPresetRowsLower = false;
  bool gainCompensation = true;
  bool extPedalonly = false;
  bool pedalOnLowerVib = false;
  bool audioTaperPots = false;
  bool disableSwellonExtPedal = false;
  bool displaySplashScreen = false;
  // Aliasses für config_2:
  bool latchingFootswiches = false;
  bool halfmoonConfig = false;
  bool wrapMenus = true;
  bool syncPHRtoRotary = false;
  bool delayedCancelSave = false;
  bool swapFootswitchInputs = false;
  bool separateMainPedalOnRotBypass = false;
 } config;

// #############################################################################
//
//     #######  ########   ######      ###    ##    ## 
//    ##     ## ##     ## ##    ##    ## ##   ###   ## 
//    ##     ## ##     ## ##         ##   ##  ####  ## 
//    ##     ## ########  ##   #### ##     ## ## ## ## 
//    ##     ## ##   ##   ##    ##  ######### ##  #### 
//    ##     ## ##    ##  ##    ##  ##     ## ##   ### 
//     #######  ##     ##  ######   ##     ## ##    ## 
//
// #############################################################################


// ------------------
// KEYBED/GENERATOR
// ------------------

struct {
  // Reihenfolge wg. memcpy nicht ändern!
  // 10 Werte #1356 ff.
  uint8_t earlyKeyCont = false; // 100
  uint8_t noDB1onPerc = false;
  uint8_t foldbModeDB16 = 0; 
  uint8_t hiFoldback = false;
  uint8_t contFlex = 4;
  uint8_t contDamping = 7;
  uint8_t PercOnLiveOnly = true;
  uint8_t fatarVelocityFac = 20; // 20 = Nominalwert, <100 = weichere Ansprache, >100 = härtere Ansprache
  uint8_t lubedContacts = false;  
  uint8_t enaSagLoadmap= true; // Ri-Simulation des Generator-Innenwiderstands (nur HX3.6/3.7)
  
  // 10 Werte #1385 ff.
  uint8_t tuning_set = 0; // 0: Hammond, 1: Hammond Spread, 2: Even, 3..n: detuned sets
  uint8_t generator_size = 91;
  uint8_t fixed_taper = 32; // 32 = Nominalwert
  uint8_t waveset = 0; // 0..n, Index für Waveset in DataFlash
  uint8_t flutter = 7; // 0..7, Stärke des Flutters
  uint8_t leakage = 3; // 0..7, Stärke der Leckage
  uint8_t tuning_val = 7; // CycleSteal-Tabelleneintrag, A 440 = 7 (433 .. 447 Hz)
  uint8_t taperset = 0; // 0..n, Index für Taper-Set in DataFlash
  uint8_t lc_filter_fac = 36; // LC Cutoff frequency calculation factor
  uint8_t bottom_oct_taper = 23; // Tapering value for first octave 16' Drawbar

  uint8_t genTranspose = 0;  // MIDI IN/Generator Transpose
  uint8_t keyTranspose = 0;  // nur MIDI OUT eigene Tastatur

  uint8_t percNormLvl = 100;
  uint8_t percSoftLvl = 75;
  uint8_t percLongTime = 55;
  uint8_t percShortTime = 36;
  uint8_t percMutedLvl = 64; // (all Drawbars muted by this value when PERC NORMAL)
  uint8_t percDummy0;
  uint8_t percPrechargeTime = 36; //Perc Precharge Time (sets time to fully charge decay capacitor when all keys released)
  uint8_t percDummy1;

  uint8_t busbarOffsets[16];
  uint8_t busbarLevels[16];
  uint8_t pedalFac16[16];
  uint8_t pedalFac8[16];
} organModel;

// ------------------
// VIBRATO
// ------------------

struct {
  uint8_t preEmphasis;
  uint8_t lineAge;
  uint8_t feedback;
  uint8_t reflection;
  uint8_t lineCutoff;
  uint8_t phaseShelvLvl;
  uint8_t gearing;
  uint8_t chorusDryLvl;
  uint8_t chorusWetLvl;
  uint8_t modV1C1;
  uint8_t modV2C2;
  uint8_t modV3C3;
  uint8_t chorusEnhance;
  uint8_t segmentFlutter; // HX3.6/3.7 only
  uint8_t hipassCutoff;
  uint8_t slopeNoiseBits;
} vibrato; 

// ------------------
// AO28 PREAMP
// ------------------

struct {
  uint8_t masterVolume = 127;
  uint8_t ampGain = 40;
  uint8_t upperVolumeWet = 105;
  uint8_t lowerVolume = 105 ;
  uint8_t pedalVolume = 105 ;
  uint8_t upperVolumeDry = 105 ;
  uint8_t overallReverb = 30 ;
  uint8_t tonePot = 60;
  uint8_t trimSwell = 60;
  uint8_t minimalSwell= 20;
  uint8_t triode_k2 = 30;
  uint8_t swellLoudnessBass = 90;
  uint8_t swellMidrangeResponse = 40;
  uint8_t swellMidrangeShelving = 25;
  uint8_t swellFinalResponse = 40 ;
  uint8_t swellLoudnessTreble = 35;
  // Integrierter Schwellerwert von ADC oder MIDI, 0..255
  uint8_t swell255 = 254; 
  uint8_t swell255_old = 0;
  uint8_t swell127 = 127; // von MIDI gesetzte Schwellerstellung, 0..127, wird in swell255 umgerechnet
  int16_t swellIntegrator = 254 * 16;
 } preamp;

// ------------------
// EQUALIZER
// ------------------

struct {
  uint8_t bass = 64;
  uint8_t bass_freq = 25;
  uint8_t bass_peak = 30;
  uint8_t mid = 64;
  uint8_t mid_freq = 40;
  uint8_t mid_peak = 30;
  uint8_t treble = 64;
  uint8_t treble_freq = 70;
  uint8_t treble_peak = 25;
} equalizer;

// ------------------
// DRAWBARS
// ------------------

struct {
  uint8_t upper[16];
  uint8_t lower[16];
  uint8_t pedal[16];
  uint8_t egPerc[16];
} drawbars;
    

// ------------------
// TABS/SWITCHES
// ------------------


struct {
  uint8_t vibKnob = 0;
  bool vibUpper = false;
  bool vibLower = false;
  
  bool phrUpper = false;
  bool phrLower = false;
  
  bool percOn = false;
  bool percSoft = false;
  bool percFast = false;
  bool perc3rd = false;
  
  bool tubeAmpBypass = true;
  bool speakerBypass = true;
  bool equ_bypass = false;

  uint8_t organModel = 0;
  uint8_t speakerModel = 0;
  uint8_t upperVoice = 0;
  uint8_t lowerVoice = 0;
  uint8_t pedalVoice = 0;
 } tabs;

 struct {
  bool vibToPedal = false;
  uint8_t inserts = 0;
 } organ;

// #############################################################################
//
//     ######  ########  ########    ###    ##    ## ######## ########  
//    ##    ## ##     ## ##         ## ##   ##   ##  ##       ##     ## 
//    ##       ##     ## ##        ##   ##  ##  ##   ##       ##     ## 
//     ######  ########  ######   ##     ## #####    ######   ########  
//          ## ##        ##       ######### ##  ##   ##       ##   ##   
//    ##    ## ##        ##       ##     ## ##   ##  ##       ##    ##  
//     ######  ##        ######## ##     ## ##    ## ######## ##     ## 
//
// #############################################################################

struct {
  uint8_t ctrl[16];
  uint8_t inits[32];
  uint8_t phases[16];
} speakerModel;

struct {
  uint8_t ampGain = 40;
  uint8_t ampInVol = 100;
  uint8_t ampOutVol = 100;
  uint8_t stereoSpread = 100;
  uint8_t hornSpeed = 15;
  uint8_t rotorSpeed = 14;
  uint8_t balance = 64;
  uint8_t throb = 0;
  uint8_t tubeSlopePos = 0;
  uint8_t tubeSlopeNeg = 0;
} speakerCtrl;

// #############################################################################
//
//    ########    ###    ########  ##       ########  ######  
//       ##      ## ##   ##     ## ##       ##       ##    ## 
//       ##     ##   ##  ##     ## ##       ##       ##       
//       ##    ##     ## ########  ##       ######    ######  
//       ##    ######### ##     ## ##       ##             ## 
//       ##    ##     ## ##     ## ##       ##       ##    ## 
//       ##    ##     ## ########  ######## ########  ######  
//
// #############################################################################


// aus DrawbarLogTable_std_neu.xls importiert
const uint8_t  c_DrawbarLogTable[128] = {
    0, 0, 0, 1, 1, 1, 1, 1,             // 0..63
    1, 2, 2, 2, 2, 2, 3, 3,
    3, 3, 4, 4, 4, 5, 5, 5,
    6, 6, 7, 7, 8, 8, 9, 9,
    10, 10, 11, 11, 12, 13, 13, 14,
    15, 15, 16, 17, 17, 18, 19, 20,
    20, 21, 22, 23, 24, 24, 25, 26,
    27, 28, 29, 30, 31, 32, 33, 34,
    35, 36, 37, 38, 39, 40, 41, 43,     // 64..127
    44, 45, 46, 47, 48, 50, 51, 52,
    54, 55, 56, 57, 59, 60, 62, 63,
    64, 66, 67, 69, 70, 72, 73, 75,
    76, 78, 79, 81, 82, 84, 86, 87,
    89, 91, 92, 94, 96, 97, 99, 101,
    103, 105, 106, 108, 110, 112, 114, 116,
    118, 119, 121, 123, 125, 127, 127, 127 };

const uint8_t c_AntiLogTable[128] = {
    0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18, 19, 21, 22, 24, 25, 27, 28,
    29, 31, 32, 33, 35, 36, 37, 39, 40, 41, 43, 44, 45, 47, 48, 49, 50, 52, 53,
    54, 55, 57, 58, 59, 60, 62, 63, 64, 65, 66, 68, 69, 70, 71, 72, 73, 74, 76,
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 102, 103, 104, 105, 106, 107, 108, 108, 109,
    110, 111, 111, 112, 113, 114, 114, 115, 116, 116, 117, 118, 118, 119, 120,
    120, 121, 121, 122, 122, 123, 123, 124, 124, 125, 125, 125, 126, 126, 127,
    127, 127, 127, 127 };


const uint16_t c_HighpassFilterArray[] = {
  // aus Digital_HP_LP.xls
  100, 100, 100, 100, 130, 150, 200, 210, 220, 240, 253, 253, 279, 295, 313, 331,
  351, 372, 394, 417, 442, 468, 496, 525, 556, 589, 624, 661, 700, 741, 785, 831,
  880, 932, 987, 1046, 1107, 1173, 1242, 1315, 1392, 1474, 1561, 1652, 1749, 1852,
  1960, 2075, 3288, 3478, 3679, 3891, 4115, 4352, 4601, 4864, 5142, 5434, 5743,
  6068, 6411, 6772, 7152, 7551, 7972, 8414, 8879, 9367, 9880, 10418, 10983, 11575,
  12195, 12844, 13523, 14232, 14871, 14871, 14871, 14871, 14871, 14871, 14871,
  14871, 14871, 14871, 18028, 18028, 18028, 18028, 18028, 18028, 20988, 20988,
  20988, 20988};

const uint16_t c_TuningArrayHammond[] = {
  // Hammond Generator, aus GeneratorNoten96.xls
  1428, 1513, 1604, 1699, 1800, 1907, 2021, 2141, 2267, 2403, 2545, 2696};

const uint16_t c_TuningArrayHammondSpread[] = {
  // Hammond Generator letzte Oktave 192er Wheels, aus GeneratorNoten96.xls
  1430, 1516, 1606, 1701, 1802, 1909, 2022, 2142, 2270, 2404, 2547, 2699};

const uint16_t c_TuningArrayEven[] = {
  // Exakt gleichschwebend (Even), aus GeneratorNoten96.xls
  1429, 1514, 1604, 1699, 1800, 1907, 2021, 2141, 2268, 2403, 2546, 2697};

const uint8_t c_TuningTable[] = {
  // CycleSteal-Werte, A 440 = 7 (433 .. 447 Hz)
  142,145,148,154,163,180,232,
  0,
  18,72,92,101,106,110,112,112};

const int16_t c_tubeampslopes[8][32] = {
    {1024,998,952,910,870,831,793,755,718,682,646,610,575,540,505,471,436,402,368,335,301,268,235,202,169,137,104,72,39,7,0,0},
    {1024,1019,1003,981,955,926,895,861,825,786,746,705,661,616,570,522,473,423,371,319,265,209,153,96,38,0,0,0,0,0,0,0},
    {1024,1023,1019,1011,999,983,963,939,911,879,843,803,759,711,659,603,543,479,411,339,263,183,99,11,0,0,0,0,0,0,0,0},
    {1024,1024,1023,1020,1014,1005,993,978,958,934,905,871,832,787,737,681,619,550,475,393,304,209,106,0,0,0,0,0,0,0,0,0},
    {1024,1024,1024,1024,1024,1023,1021,1017,1012,1003,991,974,953,926,894,854,806,750,685,610,525,428,318,196,60,0,0,0,0,0,0,0},
    {1024,1024,1024,1024,1024,1023,1022,1020,1016,1009,1000,986,967,942,908,864,808,737,651,545,417,264,82,0,0,0,0,0,0,0,0,0},
    {1024,1024,1024,1024,1024,1024,1024,1023,1022,1020,1016,1011,1002,988,969,941,902,850,781,691,574,426,240,8,0,0,0,0,0,0,0,0},
    {1024,1024,1024,1024,1024,1024,1024,1024,1024,1023,1022,1021,1018,1013,1005,993,975,948,910,856,781,679,543,362,127,0,0,0,0,0,0,0}
};

// #############################################################################
//
//    ######## ########   ######      ###       ######  ########  #### 
//    ##       ##     ## ##    ##    ## ##     ##    ## ##     ##  ##  
//    ##       ##     ## ##         ##   ##    ##       ##     ##  ##  
//    ######   ########  ##   #### ##     ##    ######  ########   ##  
//    ##       ##        ##    ##  #########         ## ##         ##  
//    ##       ##        ##    ##  ##     ##   ##    ## ##         ##  
//    ##       ##         ######   ##     ##    ######  ##        #### 
//
// #############################################################################


// Defines für SPI-Register, siehe FPGA-Hilevel.h und FPGA_SPI.h

#define SPI_RD_FIFO_TX_STATUS 0
#define SPI_RD_SAM_D1_STATUS 1
#define SPI_RD_MIDI_RX_DATA 2
#define SPI_RD_FPGA_VERSION 3
#define SPI_RD_THROB_POS 4
#define SPI_SCAN_MIDICH 4
#define SPI_SCAN_MIDIOPT 5
#define SPI_SCAN_SPLITMODE 6
#define SPI_SCAN_SPLIT_ON 7
#define SPI_SCAN_SPLITPOINT 8
#define SPI_SCAN_CLICK 9
#define SPI_SCAN_KEY_TRANSPOSE 10
#define SPI_SCAN_CONFIG_1 11
#define SPI_SCAN_GEN_TRANSPOSE 12
#define SPI_SCAN_MIDISEND_DISABLES 13
#define SPI_SCAN_PWM_LOCALDISABLES 14
#define SPI_SCAN_PWM_AUXPORT_LEDS 15

#define SPI_PERC_ENA 32
#define SPI_PERC_VOL 33
#define SPI_UPPER_WET_LVL 34
#define SPI_LOWER_LVL 35
#define SPI_PEDAL_LVL 36
#define SPI_UPPER_DRY_LVL 37
#define SPI_PERC_PRECHARGE_TIME 38
#define SPI_PERC_DECAY_TIME 39
#define SPI_UPPER_BB_MECH_CONT_ENA 40
#define SPI_UPPER_BB_ADSR_ENA 41
#define SPI_UPPER_BB_HARP_SUST_ENA 42
#define SPI_UPPER_BB_TO_DRY_ENA 43
#define SPI_LOWER_BB_ADSR_ENA 44
#define SPI_PED_TO_VIB_LVL 45
#define SPI_PED_TO_AO28_LVL 46
#define SPI_PED_TO_BYPASS_AMP 47

#define SPI_SWAP_DACS 64
#define SPI_TEST_SEL 65

// Bitmasken für SPI_INSERTS
#define INSERT_PHR_UPR 1
#define INSERT_PHR_LWR 2
#define INSERT_VIB_UPR 4
#define INSERT_VIB_LWR 8
#define INSERT_TUBEAMP 16
#define INSERT_SPEAKER 32
#define INSERT_PEDAL_POSTMIX 64
#define INSERT_PEDAL_BYPASS 128

#define SPI_INSERTS 66

#define SPI_LEAK_RNDMASK 67
#define SPI_DDS_TUNING 68
#define SPI_AMP_IN_LVL 69
#define SPI_AMP_OUT_LVL 70

#define SPI_MASTER_VOLUME 72

#define SPI_AO28_LOUDN_BASS 80
#define SPI_AO28_MIDRANGE 81
#define SPI_AO28_LOUDN_TREBLE 82
#define SPI_AO28_MIDRANGE_SHELF 83
#define SPI_AO28_FINAL_GAIN 84
#define SPI_AO28_TRIODE_K2 85
#define SPI_AO28_PEDAL_LVL 86
#define SPI_AO28_FREQU_RESPONSE_FINAL 87
#define SPI_AO28_FREQU_RESPONSE_MIDRANGE 88
#define SPI_AO28_BYPASS_SEL 89

#define SPI_PHR_SPEED_SLOW 112
#define SPI_PHR_SPEED_FAST 113
#define SPI_PHR_SPEED_SLOW_FIXED 114
#define SPI_PHR_FEEDBACK_ 115
#define SPI_PHR_LEVEL_PH1_ 116
#define SPI_PHR_LEVEL_PH2_ 117
#define SPI_PHR_LEVEL_PH3_ 118
#define SPI_PHR_LEVEL_DRY_ 119
#define SPI_PHR_FEEDBACK_SELECT_ 120
#define SPI_PHR_RAMP_DELAY_ 121
#define SPI_PHR_MOD_VARI_PH1_ 122
#define SPI_PHR_MOD_VARI_PH2_ 123
#define SPI_PHR_MOD_VARI_PH3_ 124
#define SPI_PHR_MOD_SLOW_PH1_ 125
#define SPI_PHR_MOD_SLOW_PH2_ 126
#define SPI_PHR_MOD_SLOW_PH3_ 127
#define SPI_INC_LOADCORE 128
#define SPI_RST_LOADCORE 129

#define SPI_VIB_PREEMPH 144
#define SPI_VIB_LC_LINE_AGE 145
#define SPI_VIB_LC_LINE_FB 146
#define SPI_VIB_LC_LINE_REFLE 147
#define SPI_VIB_LC_LINE_CUTOFF 148
#define SPI_VIB_PHASELK_SHELV 149
#define SPI_VIB_GEARING 150
#define SPI_VIB_DRY_LVL 151
#define SPI_VIB_WET_LVL 152
#define SPI_VIB_FLUTTER 153
#define SPI_VIB_PREMPH_FREQU 154
#define SPI_VIB_MODWAVE_PHASE 155

#define SPI_LC_LINE_DLY_0 160
#define SPI_LC_LINE_DLY_1 161
#define SPI_LC_LINE_DLY_2 162
#define SPI_LC_LINE_DLY_3 163
#define SPI_LC_LINE_DLY_4 164
#define SPI_LC_LINE_DLY_5 165
#define SPI_LC_LINE_DLY_6 166
#define SPI_LC_LINE_DLY_7 167
#define SPI_LC_LINE_DLY_8 168
#define SPI_LC_LINE_DLY_9 169
#define SPI_LC_LINE_DLY_10 170
#define SPI_LC_LINE_DLY_11 171
#define SPI_LC_LINE_DLY_12 172
#define SPI_LC_LINE_DLY_13 173
#define SPI_LC_LINE_DLY_14 174

#define SPI_SPEED_HORN 177
#define SPI_SPEED_ROTOR 178
#define SPI_NOT_USED 179
#define SPI_ROTRY_INP_LVL 180
#define SPI_ROTRY_HORN_LVL 181
#define SPI_ROTRY_ROTOR_LVL 182
#define SPI_ROTRY_HORN_NEAR_REFL_LVL 183
#define SPI_ROTRY_HORN_ROOM_REFL_LVL 184
#define SPI_ROTRY_XOVER_FREQU 185

#define SPI_ROTRY_PRE_DLY 187
#define SPI_ROTRY_DIFFUSE_1 188
#define SPI_ROTRY_DIFFUSE_2 189
#define SPI_ROTRY_DIFFUSE_3 190
#define SPI_ROTRY_DIFFUSE_4 191
#define SPI_LFO_MOD_HORN_MAIN_L 192
#define SPI_LFO_MOD_HORN_MAIN_R 193
#define SPI_LFO_MOD_HORN_REFL_1_L_NEAR 194
#define SPI_LFO_MOD_HORN_REFL_1_R_NEAR 195
#define SPI_LFO_MOD_HORN_REFL_2_L_FAR 196
#define SPI_LFO_MOD_HORN_REFL_2_R_FAR 197
#define SPI_LFO_MOD_HORN_THROB_L 198
#define SPI_LFO_MOD_HORN_THROB_R 199
#define SPI_LFO_MOD_HORN_CAB 200
#define SPI_LFO_MOD_ROTOR_MAIN 201
#define SPI_LFO_MOD_ROTOR_REFL 202
#define SPI_LFO_MOD_ROTOR_THROB 203
#define SPI_HORN_FIR_FILTER_ENABLE 204

#define SPI_LFO_PHASE_OFFSET_HORN_MAIN_L 224
#define SPI_LFO_PHASE_OFFSET_HORN_MAIN_R 225
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_1_L_NEAR_CAB 226
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_1_R_NEAR_CAB 227
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_2_L_FAR 228
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_2_R_FAR 229
#define SPI_LFO_PHASE_OFFSET_HORN_THROB_L_2_KHZ 230
#define SPI_LFO_PHASE_OFFSET_HORN_THROB_R_2_KHZ 231
#define SPI_LFO_PHASE_OFFSET_HORN_CAB_4X 232
#define SPI_LFO_PHASE_OFFSET_ROTOR_MAIN 233
#define SPI_LFO_PHASE_OFFSET_ROTOR_REFL 234
#define SPI_LFO_PHASE_OFFSET_ROTOR_THROB 235

#define SPI_DNA_COMPARE_0 240
#define SPI_DNA_COMPARE_1 241
#define SPI_RD_DNA_0 242
#define SPI_RD_DNA_1 243
#define SPI_RD_LIC_VALID 244

#define SPI_SAM_COMMAND 246

// #############################################################################
//
//    ######## ########   ######      ###        ##        ######  
//    ##       ##     ## ##    ##    ## ##       ##       ##    ## 
//    ##       ##     ## ##         ##   ##      ##       ##       
//    ######   ########  ##   #### ##     ##     ##       ##       
//    ##       ##        ##    ##  #########     ##       ##       
//    ##       ##        ##    ##  ##     ##     ##       ##    ## 
//    ##       ##         ######   ##     ##     ########  ######  
//
// #############################################################################

// Load Core (LC) Target-Nummern
// Größere Datenmengen werden nicht als SPI-Register egesetzt, sondern an
// einen "LoadCore"-Buffer mit Auto-Inkrement im FPGA übertragen,
// siehe FPGA_Hilevel.h
#define LCTARGET_SCAN_DRIVER 0  // aus DataFlash
#define LCTARGET_TAPERING 1  // aus DataFlash
#define LCTARGET_FIR_COEFF 2  // aus DataFlash
#define LCTARGET_KEYMAP 3  // berechnet
#define LCTARGET_WAVESET 4  // aus DataFlash
#define LCTARGET_TUNING_VALS 5  // berechnet
#define LCTARGET_HP_FILTER 6  // berechnet
#define LCTARGET_TUBE_AMP_SLOPE 7  // berechnet
#define LCTARGET_UPPER_DRAWBARS 8  // berechnet
#define LCTARGET_LOWER_DRAWBARS 9  // berechnet
#define LCTARGET_PEDAL_DRAWBARS 10  // berechnet
#define LCTARGET_ADSR_UPPER 11  // berechnet
#define LCTARGET_ADSR_LOWER 12  // berechnet
#define LCTARGET_ADSR_PEDAL 13  // berechnet



// Wortbreite Anzahl Bytes für Datenübertragung an LoadCore-Buffer, siehe FPGA_Hilevel.h
const uint8_t c_target_datawidth[] =  {4, 4, 4, 1, 2, 2, 2, 2,  1,  1,  1, 2, 2, 2, 2};
const uint16_t c_target_blockcount[]  = { 2,  1,  1,  0,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0};
// c_target_count in Anzahl Words, Longwords oder Bytes, je nach c_target_datawidth:
const uint16_t c_target_count_per_block[]  = {1024,  1024,  512,  0,  2048,
                                    0,  0,  0,  0,  0,  0,  0,  0,  0,  0};

// Das Dataflash enthält nicht nur dass FPGA-Binary, sondern
// auch diverse Daten wie Scan Driver, Taperings etc.,
// die über den "LoadCore"-Mechanismus an die FPGA-Cores übertragen werden
// Block-Nummern im DataFlash ab 0x3B0, siehe FPGA_Hilevel.h
#define BLOCK_FPGA 0  // XC6S25 Binary, 196 Blöcke
#define BLOCK_FAILSAFE_BASE 320  // Sicherungskopie
#define BLOCK_UPDATE_INFO 637  // Update List
#define BLOCK_boardInfo 639  // 
#define BLOCK_SPEAKER_MODEL_BASE 768  // 16 Blöcke
#define BLOCK_ORGAN_MODEL_BASE 784  // 16 Blöcke
#define BLOCK_PRESET_BASE 800  // 100 Blöcke
#define BLOCK_MIDI_CC_BASE 928  // 16 Blöcke
#define BLOCK_CORE_BASE 944  // 
#define BLOCK_SCAN 944  // 
#define BLOCK_VOICE 946  // 
#define BLOCK_DEFAULTS 947  // HX3 Edit Array
#define BLOCK_EEPROM 953  // 
#define BLOCK_TAPER_BASE 955  // 4 Taperings
#define BLOCK_TAPER_0 955  // 
#define BLOCK_TAPER_1 956  // 
#define BLOCK_TAPER_2 957  // 
#define BLOCK_TAPER_3 958  // 
#define BLOCK_FIR_COEFF 959  // Filterkoeffizienten
#define BLOCK_WAVESET_BASE 960  // 8 Wavesets
#define BLOCK_WAVESET_0 960  // 
#define BLOCK_WAVESET_1 964  // 
#define BLOCK_WAVESET_2 968  // 
#define BLOCK_WAVESET_3 972  // 
#define BLOCK_WAVESET_4 976  // 
#define BLOCK_WAVESET_5 980  // 
#define BLOCK_WAVESET_6 984  // 
#define BLOCK_WAVESET_7 988  // 
#define BLOCK_FIRMWARE 992  // Buffer für Update


void blinkLED(uint8_t times) {
  // Board-LED blinkt zur Bestätigung von Aktionen, z.B. Speichern von Werten im EEPROM
  for (uint8_t i=0; i<times; i++) {
    digitalWrite(LED_PIN, LOW); // sets the LED on
    delay(150);
    digitalWrite(LED_PIN, HIGH);  // sets the LED off
    delay(150);
  }
}

uint8_t mulDivByte(uint8_t value, uint8_t mul, uint8_t div) {
  // Für AVRco-Kompatibilität, oft genutzt
  uint16_t temp = (uint16_t)value;
  temp = (temp * mul) / div;
  return temp;
}

uint8_t mulDivInt(int16_t value, int16_t mul, int16_t div) {
  // Für AVRco-Kompatibilität, oft genutzt
  uint32_t temp = (uint32_t)value;
  temp = (temp * mul) / div;
  return temp;
}

#define OFS_SYSTEMINITS 496
#define OFS_VIBKNOBMODE 497
#define OFS_RESTORECOMMONPRESETMASK 498
#define OFS_BUTTONMASK0 499
#define OFS_BUTTONMASK1 500
#define OFS_CONFBITS1 501
#define OFS_CONFBITS2 502
#define OFS_ADCCONFIG 503
#define OFS_1STDBSELECT 504
#define OFS_2NDDBSELECT 505
#define OFS_PEDALDBSETUP 506
#define OFS_ADCSCALING 507

#define OFS_DEVICETYPE 509
#define OFS_PRESETSTRUCTURE 510
#define OFS_EDITMAGICFLAGIDX 511

#endif
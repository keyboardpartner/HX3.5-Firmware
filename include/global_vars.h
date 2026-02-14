#ifndef global_vars_h
#define global_vars_h

#include <Arduino.h>
#include "MenuPanel.h"
#include <avr/io.h> // add "platformio/framework-arduino-avr-mightycore@^3.0.2" to platformio.ini!

#define VERSION "HX3.5 v0.01"

#define FIRMWARE_VERSION 0x01 // Vergleichswert für EEPROM, um ungültige Werte zu erkennen
#define EEPROM_VERSION_IDX 01 // Vergleichwert
#define EEPROM_MENUDEF_IDX 16 // Startadresse im EEPROM für gespeicherte Werte

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

// Default MIDI Einstellungen
#define MIDI_BASE_UPR 36
#define MIDI_BASE_LWR 36
#define MIDI_BASE_PED 36

#define MIDI_CH_UPR 1
#define MIDI_CH_LWR 2
#define MIDI_CH_PED 3

struct {
  uint32_t fpga_version;
  uint32_t fpga_serial;
  uint32_t fpga_organ;
  uint32_t fpga_rotary;
  uint8_t fpga_valid;
  uint8_t scan_id;
  uint8_t scan_version;
  uint8_t scan_validflag;
} board_info;

struct {
  uint8_t generator_size = 91;
  uint8_t tuning_val = 7; // CycleSteal-Tabelleneintrag, A 440 = 7 (433 .. 447 Hz)
  uint8_t tuning_set = 0; // 0: Hammond, 1: Hammond Spread, 2: Even, 3..n: detuned sets
  bool has_foldback = false;
  uint8_t waveset = 0;
  uint8_t taperset = 0;
  uint8_t busbar_offsets[16] = {0, 19, 12, 24, 31, 36, 40, 43, 48, 46, 50, 51, 54, 55, 44, 0};
  uint8_t busbar_levels[16] = {110, 115, 115, 115, 115, 110, 110, 110, 115, 105, 100, 100, 100, 100, 100, 0};
  uint8_t pedal_fac16[16] = {110, 122, 127, 95, 35, 20, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  uint8_t pedal_fac8[16] = {0, 0, 120, 127, 75, 65, 55, 55, 20, 0, 0, 0, 0, 0, 0, 0};
} organ_model;

struct {
  uint8_t db_upper[16] = {127, 127, 127, 127, 115, 110, 110, 110, 115, 0, 0, 0, 0, 0, 0, 0};
  uint8_t db_lower[16] = {0, 0, 115, 115, 115, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  uint8_t db_pedal[16] = {127, 127, 115, 100, 100, 50, 20, 10, 0, 0, 0, 0, 0, 0, 0, 0};
  uint8_t masterVolume = 127;
  uint8_t ampVolume = 40;
  uint8_t upperVolumeWet = 105;
  uint8_t lowerVolume = 105 ;
  uint8_t pedalVolume = 105 ;
  uint8_t upperVolumeDry = 105 ;
  uint8_t overallReverb = 30 ;
} preset;

struct {
  uint8_t tonePot = 60;
  uint8_t trimSwell = 90;
  uint8_t minimalSwell= 20;
  uint8_t triode_k2 = 30;
  uint8_t swellLoudnessBass = 90;
  uint8_t swellMidrangeResponse = 40;
  uint8_t swellMidrangeShelving = 25;
  uint8_t swellFinalResponse = 40 ;
  uint8_t swellLoudnessTreble = 35;
 } ao28;

struct {
  uint8_t channel = 0;
  uint8_t channel_lower = 1;
  uint8_t channel_pedal = 2;
 } midi_settings;

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
    118, 119, 121, 123, 125, 127, 127, 127  };


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


enum { bm_toggle = 0,  bm_press = 1 };
const uint8_t buttonModes[16] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

volatile uint8_t Timer1Semaphore = 0;
volatile uint8_t Timer1RoundRobin = 0;

MenuPanel lcd(LCD_I2C_ADDR, 16, 2);



void blinkLED(uint8_t times) {
  // Board-LED blinkt zur Bestätigung von Aktionen, z.B. Speichern von Werten im EEPROM
  for (uint8_t i=0; i<times; i++) {
    digitalWrite(LED_PIN, LOW); // sets the LED on
    delay(150);
    digitalWrite(LED_PIN, HIGH);  // sets the LED off
    delay(150);
  }
}

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
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_2_L__FAR 228
#define SPI_LFO_PHASE_OFFSET_HORN_REFL_2_R_FAR 229
#define SPI_LFO_PHASE_OFFSET_HORN_THROB_L__2_KHZ 230
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

// Load Core (LC) Target-Nummern
// Größere Datenmengen werden nicht als SPI-Register egesetzt, sondern an
// einen "LoadCore"-Buffer mit Auto-Inkrement im FPGA übertragen,
// siehe FPGA_Hilevel.h
#define LCTARGET_SCAN_DRIVER 0
#define LCTARGET_TAPERING 1
#define LCTARGET_FIR_COEFF 2
#define LCTARGET_KEYMAP 3
#define LCTARGET_WAVESET 4
#define LCTARGET_TUNING_VALS 5
#define LCTARGET_HP_FILTER 6
#define LCTARGET_TUBE_AMP_SLOPE 7
#define LCTARGET_UPPER_DRAWBARS 8
#define LCTARGET_LOWER_DRAWBARS 9
#define LCTARGET_PEDAL_DRAWBARS 10
#define LCTARGET_ADSR_UPPER 11
#define LCTARGET_ADSR_LOWER 12
#define LCTARGET_ADSR_PEDAL 13

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
#define BLOCK_CORE_BASE 944
#define BLOCK_SCAN 944
#define BLOCK_VOICE 946
#define BLOCK_DEFAULTS 947
#define BLOCK_EEPROM 953
#define BLOCK_TAPER_BASE 955
#define BLOCK_TAPER_0 955
#define BLOCK_TAPER_1 956
#define BLOCK_TAPER_2 957
#define BLOCK_TAPER_3 958
#define BLOCK_FIR_COEFF 959
#define BLOCK_WAVESET_BASE 960
#define BLOCK_WAVESET_0 960
#define BLOCK_WAVESET_1 964
#define BLOCK_WAVESET_2 968
#define BLOCK_WAVESET_3 972
#define BLOCK_WAVESET_4 976
#define BLOCK_WAVESET_5 980
#define BLOCK_WAVESET_6 984
#define BLOCK_WAVESET_7 988


#endif
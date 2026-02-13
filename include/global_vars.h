#ifndef global_vars_h
#define global_vars_h

#include <Arduino.h>
#include "MenuPanel.h"

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

#define LED_PIN 10  // Pin für LED
#define PWR_GOOD 15 // Pin für DSP-Reset

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
  uint8_t tuning_val = 8; // CycleSteal-Tabelleneintrag, A 440 = 7 (433 .. 447 Hz)
  uint8_t tuning_set = 0; // 0: Hammond, 1: Hammond Spread, 2: Even, 3..n: detuned sets
  bool has_foldback = false;
  uint8_t waveset = 0;
  uint8_t taperset = 0;
  uint8_t busbar_offsets[16] = {0, 19, 12, 24, 31, 36, 40, 43, 48, 46, 50, 51, 54, 55, 44, 0};
  uint8_t busbar_levels[16] = {110, 115, 115, 115, 115, 110, 110, 110, 115, 105, 100, 100, 100, 100, 100, 0};
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
  uint8_t tonePot = 60;
  uint8_t trimSwell = 90;
  uint8_t minimalSwell= 20;
  uint8_t triode_k2 = 30;
  uint8_t swellLoudnessBass = 90;
  uint8_t swellMidrangeResponse = 40;
  uint8_t swellMidrangeShelving = 25;
  uint8_t swellFinalResponse = 40 ;
  uint8_t swellLoudnessTreble = 35;
} preset;

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


volatile uint8_t Timer1Semaphore = 0;
volatile uint8_t Timer1RoundRobin = 0;

MenuPanel lcd(LCD_I2C_ADDR, 16, 2);

#endif
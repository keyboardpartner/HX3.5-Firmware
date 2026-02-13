#ifndef global_vars_h
#define global_vars_h

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




#endif
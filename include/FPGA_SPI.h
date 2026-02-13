#ifndef FPGA_SPI_H
#define FPGA_SPI_H

// #############################################################################
//
//     ####### ######   #####     #       #####  ######  ###
//     #       #     # #     #   # #     #     # #     #  #
//     #       #     # #        #   #    #       #     #  #
//     #####   ######  #  #### #     #    #####  ######   #
//     #       #       #     # #######         # #        #
//     #       #       #     # #     #   #     # #        #
//     #       #        #####  #     #    #####  #       ###
//
// #############################################################################

#include <Arduino.h>
#include "global_vars.h"

// PB0 = F_CSO_B, PB1 = F_RS, PB2 = F_INT, PB3 = F_DS, PB4 = F_AUX
#define _DF_CS PORTB0
#define _DF_OFF asm volatile("sbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_DF_CS))
#define _DF_ON  asm volatile("cbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_DF_CS))

#define _RS_PIN PORTB1
#define _DS_PIN PORTB3
#define _RS_OFF asm volatile("sbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_RS_PIN))
#define _RS_ON  asm volatile("cbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_RS_PIN))
#define _DS_OFF asm volatile("sbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_DS_PIN))
#define _DS_ON  asm volatile("cbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTB)), "I" (_DS_PIN))

#define _FPGA_PROG PORTC6
#define _FPGA_PROG_OFF asm volatile("sbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTC)), "I" (_FPGA_PROG))
#define _FPGA_PROG_ON  asm volatile("cbi %0,%1 " : : "I" (_SFR_IO_ADDR(PORTC)), "I" (_FPGA_PROG))

#define _FIFO_EMPTY_PIN PINB2
#define _FPGA_DONE_PIN PINC7
#define _FPGA_DONE (PINC & (1 << _FPGA_DONE_PIN))
#define _FIFO_EMPTY (PINB & (1 << _FIFO_EMPTY_PIN))

#define DDRBINIT  B10111011
#define DDRBINIT_FPGACONF B00111010

#define MIDI_FIFO_RDREG 0x02

// define a union of the same array in byte and word representation for easier access to the 4KByte block buffer
union {
  uint8_t byte[4096];
  uint16_t word[2048];
  uint32_t dword[1024];
} spi_blockbuffer;

// #############################################################################

uint8_t spi_xfer8(uint8_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  SPDR = data;
  asm volatile("nop"); // See transfer(uint8_t) function
  while (!(SPSR & _BV(SPIF))) ;
  return SPDR;
}

uint16_t spi_xfer16(uint16_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  union { uint16_t val; struct { uint8_t lsb; uint8_t msb; }; } in, out;
  in.val = data;
  SPDR = in.msb;
  asm volatile("nop"); // See transfer(uint8_t) function
  while (!(SPSR & _BV(SPIF))) ;
  out.msb = SPDR;
  SPDR = in.lsb;
  asm volatile("nop");
  while (!(SPSR & _BV(SPIF))) ;
  out.lsb = SPDR;
  return out.val;
}

uint32_t spi_xfer32(uint32_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  uint16_t highWord = (data >> 16) & 0xFFFF;
  uint16_t lowWord = data & 0xFFFF;
  uint16_t recv_hw = spi_xfer16(highWord);
  uint16_t recv_lw = spi_xfer16(lowWord);
  return ((uint32_t)recv_hw << 16) | recv_lw;
}

void spi_sendreg(uint8_t spi_reg) {
  _RS_ON; // Register
  spi_xfer16((uint16_t)spi_reg);
  _RS_OFF;
}

void spi_sendreg_wr(uint8_t spi_reg) {
  _RS_ON; // Register
  spi_xfer16((uint16_t)spi_reg | 0x8000); // Write-Flag 1, Register senden
  _RS_OFF;
}

uint32_t spi_read32(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  _DS_ON; // Daten
  uint32_t result = spi_xfer32(0x00000000);
  _DS_OFF;
  return result;
}

void spi_write32(uint8_t spi_reg, uint32_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  _DS_ON; // Daten
  spi_xfer32(data);
  _DS_OFF;
}

void spi_write16(uint8_t spi_reg, uint16_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  _DS_ON; // Daten
  spi_xfer16(data);
  _DS_OFF;
}

uint32_t spi_read16(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  _DS_ON; // Daten
  uint16_t result = spi_xfer16(0x0000);
  _DS_OFF;
  return result;
}

void spi_write8(uint8_t spi_reg, uint8_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  _DS_ON; // Daten
  spi_xfer8(data);
  _DS_OFF;
}

uint8_t spi_read8(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  _DS_ON; // Daten
  uint8_t result = spi_xfer8(0x00);
  _DS_OFF;
  return result;
}

// #############################################################################

void spi_clearfifo() {
  for (uint16_t i=0; i<1024; i++) {
    spi_read32(MIDI_FIFO_RDREG);
    if (_FIFO_EMPTY) {
      Serial.println(F("/ MIDI FIFO empty"));
      break;
    }
  }
}


void spi_autoIncReset(uint8_t my_target) {
// AutoInc zurücksetzen, Core freigeben
  spi_write8(129, my_target); // Ziel an SPI übermitteln
}


void spi_autoIncSetup(uint8_t my_target) {
// AutoInc vorbereiten: Länge, Start an SPI übermitteln
  spi_autoIncReset(my_target);
  spi_sendreg_wr(128); // Write-Flag 1, Register senden
}


// #############################################################################
//
//     ######     #    #######    #    ####### #          #     #####  #     #
//     #     #   # #      #      # #   #       #         # #   #     # #     #
//     #     #  #   #     #     #   #  #       #        #   #  #       #     #
//     #     # #     #    #    #     # #####   #       #     #  #####  #######
//     #     # #######    #    ####### #       #       #######       # #     #
//     #     # #     #    #    #     # #       #       #     # #     # #     #
//     ######  #     #    #    #     # #       ####### #     #  #####  #     #
//
// #############################################################################

uint8_t df_busy() {
  _DF_ON;
  spi_xfer8(0x05);
  uint8_t status;
  do {
    status = spi_xfer8(0x00);
  } while (status & 0x01); // Warte bis vorherige Übertragung abgeschlossen ist
  _DF_OFF;
  return status;
}

void df_wen() {
  _DF_ON;
  spi_xfer8(0x06);
  _DF_OFF;
}

void df_unprotect() {
  _DF_ON;
  spi_xfer8(0x01);
  spi_xfer8(0x00); // Write 0, Global Unprotect
  _DF_OFF;
}

void df_protect() {
  _DF_ON;
  spi_xfer8(0x01);
  spi_xfer8(0x3F); // Write $3F, Global Protect
  _DF_OFF;
}

bool df_eraseblock_4k(uint16_t block_4k) {
// Lösche 4-KByte-Block bzw. 64-KByte-Sektor im DF
// liefert TRUE wenn erfolgreich
  df_wen();
  _DF_ON;
  uint32_t addr = (uint32_t)block_4k * 4096;
  spi_xfer8(0x20); // Erase 4 KByte Block
  spi_xfer8((addr >> 16) & 0xFF); // Adr Bits 23..16
  spi_xfer8((addr >> 8) & 0xFF); // Adr Bits 15..8
  spi_xfer8(addr & 0xFF); // Adr Bits 7..0
  _DF_OFF;
  uint8_t status = df_busy();
  return ((status & 0x20) == 0);
}

void df_readblock(uint16_t block_4k, uint16_t df_blocklen) {
  // Lese BlockBuffer8 aus DataFlash, max. 4096 bytes

  df_busy();
  uint32_t addr = (uint32_t)block_4k * 4096;
  _DF_ON;
  spi_xfer8(0x0B); // Read Page
  spi_xfer8((addr >> 16) & 0xFF); // Adr Bits 23..16
  spi_xfer8((addr >> 8) & 0xFF); // Adr Bits 15..8
  spi_xfer8(addr & 0xFF); // Adr Bits 7..0
  spi_xfer8(0x00); // dummy für $0B read mode
  for (uint16_t df_idxw = 0; df_idxw < df_blocklen; df_idxw++) {
    spi_blockbuffer.byte[df_idxw] = spi_xfer8(0x00);
  }
  _DF_OFF;
}

bool df_writeblock(uint16_t block_4k, uint16_t df_blocklen) {
  // Schreibe BlockBuffer8 in DataFlash, max. 4096 bytes
  // liefert TRUE wenn erfolgreich
  // df_blocklen sollte Vielfaches von 256 sein,
  // es können max. 256 Bytes auf einmal geschrieben werden
  df_wen();
  uint8_t status;
  uint32_t addr = (uint32_t)block_4k * 4096;
  for (uint16_t page = 0; page < (df_blocklen / 256); page++) {
    _DF_ON;
    spi_xfer8(0x84); // Write Page, Buffer 1
    spi_xfer8((addr >> 16) & 0xFF); // Adr Bits 23..16
    spi_xfer8((addr >> 8) & 0xFF); // Adr Bits 15..8
    spi_xfer8(addr & 0xFF); // Adr Bits 7..0
    for (uint16_t i = 0; i < 256; i++) {
      spi_xfer8(spi_blockbuffer.byte[page * 256 + i]);
    }
    _DF_OFF;
    status = df_busy();
    addr += 256;
  }
  return ((status & 0x20) == 0);
}

// #############################################################################


void df_send_blocks(uint16_t block_4k, uint8_t core_target, uint16_t block_count, uint8_t data_width) {
  // 4k-Blocks aus DF laden und an AutoInc-Reg senden
  // 4096 Bytes = 1 BlockRAM
  uint16_t block_idx, array_idx;
  block_idx = 0;
  spi_autoIncSetup(core_target); // for Write
  for (block_idx = 0; block_idx < block_count; block_idx++) {
    df_readblock(block_4k + block_idx, 4096);
#ifdef DEBUG
    Serial.print("/ DF block #");
    Serial.print(block_4k + block_idx);
    Serial.print(" to LC #");
    Serial.println(core_target);
#endif
    switch (data_width) {
      case 8:
        for (array_idx = 0; array_idx < 4096; array_idx++) {
          _DS_ON; // Daten
          spi_xfer8(spi_blockbuffer.byte[array_idx]);
          _DS_OFF;
        }
        break;
      case 16:
        for (array_idx = 0; array_idx < 2048; array_idx++) {
          _DS_ON; // Daten
          spi_xfer16(spi_blockbuffer.word[array_idx]);
          _DS_OFF;
        }
        break;
      case 32:
      default:
        for (array_idx = 0; array_idx < 1024; array_idx++) {
          _DS_ON; // Daten
          spi_xfer32(spi_blockbuffer.dword[array_idx]);
          _DS_OFF;
        }
        break;
    }
  }
  spi_autoIncReset(core_target);
}

// AutoInc-Register FPGA-SPI
// LC#    Breite   Länge Bytes  LC Core
// 0        32        8192      PicoBlaze       (Datei/DF-Blocks)
// 1        32        1024      Taper-RAM (Datei/DF in 32 Bit, nur unterste 8 übertragen)
// 2        16        2048      FIR-Coeff       (Datei/DF-Blocks)
// 3         8        1024      Keymap-RAM      (berechnet!)
// 4        16       16384      Wave-RAM        (Datei/DF-Blocks)
// berechnete Cores: 5..13, je nach LC
// 5        16          96      Frequenz/Tuning (berechnet)
// 6        16        1024      Highpass-Filter (berechnet)
// 7 NEU    16         512      TubeAmp Steps/Slopes,je 256 Werte (aus Tabelle)
// 8         8          16      Upper DBs       (berechnet)
// 9         8          16      Lower DB        (berechnet)
// 10        8          16      Pedal DB        (berechnet)
// 11       16          64      ADSR Upper      (berechnet)
// 12       16          64      ADSR Lower      (berechnet)
// 13       16          64      ADSR Pedal      (berechnet)

// Block-Offsets zu Block c_scan_base
// 0..1: Scan Core,
// 11..14: Tapering
// 15: FIR filter
// 16 ff.: Wavesets, je 4 Blocks!

const uint16_t c_core_base_DF = 0x3B0;    // 944, erster 4k-Block nach FPGA-Image(s)
const uint16_t c_scan_base_DF = 0x3B0;    // 944, erster 4k-Block nach FPGA-Image(s)
const uint16_t c_voice_base_DF = c_core_base_DF + 2;    // 946, Zugriegel-Arrays, Länge 1 Block
const uint16_t c_defaults_base_DF = c_core_base_DF + 3; // 947, EEPROM-simulation bei ARM
const uint16_t c_taper_base_DF = c_core_base_DF + 11;   // 955..958, Länge 4 x 1 Block
const uint16_t c_coeff_base_DF = c_core_base_DF + 15;   // 959, Länge 1 Block
const uint16_t c_waveset_base_DF = 0x3C0;   // 960, Länge 32 (8 x 4 Blocks)

const uint16_t c_target_datawidth[] = {32, 32, 16,  8, 16, 16, 16, 16,  8,  8,  8, 16, 16, 16, 16};
const uint16_t c_core_blockcount[]  = { 2,  1,  1,  0,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0};

void df_send_core(uint8_t lc_target, uint8_t block_offset) {
  // PicoBlaze- oder Tapering-Core #core aus DF laden und an AutoInc-Reg senden
  // 4096 Bytes = 1 BlockRAM
  // 0..1: Scan Core,
  // 11..14: Tapering
  // 15: FIR filter
  if (c_core_blockcount[lc_target] == 0) return; // nur LC #0..2 und #4 haben Daten in DF
  df_send_blocks(c_core_base_DF + (uint16_t)block_offset, lc_target, c_core_blockcount[lc_target],
                c_target_datawidth[lc_target]);
}


#endif // FPGA_SPI_H
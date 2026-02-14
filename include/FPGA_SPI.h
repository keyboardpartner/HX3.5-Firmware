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

// define a union of the same array in byte and word representation
// for easier access to the 4KByte block buffer
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

uint8_t spi_xfer8_ds(uint8_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  _DS_ON; // Daten
  SPDR = data;
  asm volatile("nop"); // See transfer(uint8_t) function
  while (!(SPSR & _BV(SPIF))) ;
  _DS_OFF;
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

uint16_t spi_xfer16_ds(uint16_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  _DS_ON; // Daten
  uint16_t result = spi_xfer16(data);
  _DS_OFF;
  return result;
}

uint32_t spi_xfer24(uint32_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  uint8_t highByte = (data >> 16) & 0xFF;
  uint16_t lowWord = data & 0xFFFF;
  uint8_t recv_hb = spi_xfer8(highByte);
  uint16_t recv_lw = spi_xfer16(lowWord);
  return ((uint32_t)recv_hb << 16) | recv_lw;
}

uint32_t spi_xfer24_ds(uint32_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  _DS_ON; // Daten
  uint32_t result = spi_xfer24(data);
  _DS_OFF;
  return result;
}

uint32_t spi_xfer32(uint32_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  uint16_t highWord = (data >> 16) & 0xFFFF;
  uint16_t lowWord = data & 0xFFFF;
  uint16_t recv_hw = spi_xfer16(highWord);
  uint16_t recv_lw = spi_xfer16(lowWord);
  return ((uint32_t)recv_hw << 16) | recv_lw;
}

uint32_t spi_xfer32_ds(uint32_t data) {
  // Slave Select muss vorher aktiviert und hinterher deaktiviert werden!
  _DS_ON; // Daten
  uint32_t result = spi_xfer32(data);
  _DS_OFF;
  return result;
}

// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------

void spi_write32(uint8_t spi_reg, uint32_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  spi_xfer32_ds(data);
}

void spi_write24(uint8_t spi_reg, uint32_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  _DS_ON; // Daten
  spi_xfer24(data);
  _DS_OFF;
}

void spi_write16(uint8_t spi_reg, uint16_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  spi_xfer16_ds(data);
}

void spi_write8(uint8_t spi_reg, uint8_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  spi_xfer8_ds(data);
}

// Kompatibiltätsfunktionen für 8 Bit Register

void spi_write8_scaled(uint8_t spi_reg, uint8_t data, uint8_t percent) {
  // Wert mit Prozentzahl skalieren
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  uint16_t scaled_data = (data * percent) / 100;
  spi_xfer8_ds(scaled_data);
}

void spi_write8_doubled(uint8_t spi_reg, uint8_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  spi_xfer8_ds(data << 1); // Daten verdoppeln
}

void spi_write16_volume(uint8_t spi_reg, uint8_t data) {
  // 0..127 auf 0..252 quadriert für Lautstärkeregelung
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  uint16_t scaled_data = (data * data) / 64;
  spi_xfer16_ds(scaled_data >> 8); // Daten quadriert
}

void spi_write16_log(uint8_t spi_reg, uint8_t data) {
  spi_sendreg_wr(spi_reg); // Write-Flag 1, Register senden
  uint16_t log_data = c_DrawbarLogTable[data] * 2;
  spi_xfer16_ds(log_data); // Daten aus Tabelle
}

// -----------------------------------------------------------------------------

// Bei HX3 müssen Register idR. mit 32 Bit Breite gelesen werden!

uint32_t spi_read32(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  return spi_xfer32_ds(0x00000000);
}

uint32_t spi_read16(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  return spi_xfer16_ds(0x0000);
}

uint8_t spi_read8(uint8_t spi_reg) {
  spi_sendreg(spi_reg); // Write-Flag 0, Register senden
  return spi_xfer8_ds(0x00);
}

// #############################################################################

void spi_clearfifo() {
  // Clears the MIDI IN FIFO of the Scan-Core by reading until empty
  // or until 1024 bytes have been read (to prevent infinite loop in case of error)
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
//     ######  #       #######  #####  #    # ######  #     # #######
//     #     # #       #     # #     # #   #  #     # #     # #
//     #     # #       #     # #       #  #   #     # #     # #
//     ######  #       #     # #       ###    ######  #     # #####
//     #     # #       #     # #       #  #   #     # #     # #
//     #     # #       #     # #     # #   #  #     # #     # #
//     ######  ####### #######  #####  #    # ######   #####  #
//
// #############################################################################

void spi_send_blockbuffer(uint16_t count, uint8_t data_width, bool debug_print = false) {
  // Sende BlockBuffer an AutoInc-Register, Länge length in Bytes,
  // data_width in Bits (8, 16, 24 oder 32) oder Bytes (1, 2, 3 oder 4)
  // Universell verwendbar für alle Cores, die Daten in 8, 16 oder 32 Bit Breite erwarten
  if (debug_print) {
    DPRINTF(", Data (hex): ");
  }
  uint16_t array_idx;
  switch (data_width) {
  case 1:
  case 8:
    for (array_idx = 0; array_idx < count; array_idx++) {
      spi_xfer8_ds(spi_blockbuffer.byte[array_idx]);
      if (debug_print && array_idx < 10) { // nur die ersten 10 Werte drucken
        DPRINT(spi_blockbuffer.byte[array_idx], HEX);
        DPRINTF(", ");
      }
    }
    break;
  case 2:
  case 16:
    // Länge in 16 Bit Wörtern
    for (array_idx = 0; array_idx < count; array_idx++) {
      spi_xfer16_ds(spi_blockbuffer.word[array_idx]);
      if (debug_print && array_idx < 10) { // nur die ersten 10 Werte drucken
        DPRINT(spi_blockbuffer.word[array_idx], HEX);
        DPRINTF(", ");
      }
    }
    break;
  case 3:
  case 24:
    // bei 24 Bit Breite werden die Daten in 32 Bit Blöcken gesendet, die oberen 8 Bit werden ignoriert
    // Länge in 32 Bit Blöcken
    for (array_idx = 0; array_idx < count; array_idx++) {
      spi_xfer24_ds(spi_blockbuffer.dword[array_idx]);
      if (debug_print && array_idx < 10) { // nur die ersten 10 Werte drucken
        DPRINT(spi_blockbuffer.dword[array_idx], HEX);
        DPRINTF(", ");
      }
    }
    break;
  case 4:
  case 32:
  default:
    // Länge in 32 Bit Blöcken
    for (array_idx = 0; array_idx < count; array_idx++) {
      spi_xfer32_ds(spi_blockbuffer.dword[array_idx]);
      if (debug_print && array_idx < 10) { // nur die ersten 10 Werte drucken
        DPRINT(spi_blockbuffer.dword[array_idx], HEX);
        DPRINTF(", ");
      }
    }
    break;
  }
  if (debug_print) {
    DPRINTF("...");
  }
  DPRINTF(", count: ");
  DPRINT(count);
  DPRINTF(", width: ");
  DPRINTLN(data_width);
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

void df_send_core(uint8_t lc_target, uint16_t block_number) {
  // PicoBlaze-, FIR- oder Tapering-Core #core aus DF laden und an AutoInc-Reg senden, 4096 Bytes = 1 BlockRAM
  if (c_target_blockcount[lc_target] == 0) return; // nur LC #0..2 und #4 haben Daten in DF
  spi_autoIncSetup(lc_target); // for Write
  uint16_t block_size = c_target_count_per_block[lc_target] * (c_target_datawidth[lc_target]);
  for (uint16_t block_idx = 0; block_idx < c_target_blockcount[lc_target]; block_idx++) {
    DPRINTF("/ Send Block #");
    DPRINT(block_number + block_idx);
    df_readblock(block_number + block_idx, block_size);
    spi_send_blockbuffer(c_target_count_per_block[lc_target], c_target_datawidth[lc_target]);
  }
  spi_autoIncReset(lc_target);
}

#endif // FPGA_SPI_H
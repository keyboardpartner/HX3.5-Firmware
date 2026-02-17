#ifndef BOARD_H
#define BOARD_H

// Organ-specific definitions and functions
#include "FPGA_SPI.h"
#include "global_vars.h"
#include "FPGA_MIDI.h"
#include "FPGA_hilevel.h"


void initBoard() {
  spi_write8(246, 0); // DSP Bits

  digitalWrite(LED_PIN, LOW); // sets the LED on
  digitalWrite(PWR_GOOD, HIGH); // DSP-Reset deaktivieren
  delay(150); // DSP booten lassen

  boardInfo.fpga_version= spi_read32(3); // SPI-Transfer, lese Version aus
  DPRINTF("/ FPGA Version: ");
  DPRINTLN(boardInfo.fpga_version, HEX);

  spi_read8(240); // hier nur DNA-Auslese-Trigger
  boardInfo.fpga_serial = spi_read32(242); // lese Seriennummer aus
  DPRINTF("/ FPGA Serial:  ");
  DPRINTLN(boardInfo.fpga_serial);

  // For Serial Number 2821432, Licence Organ: 9523781  Extended: 3316044
  // These will not work on other boards!
  spi_write32(240, 9523781);
  spi_write32(241, 3316044);

  boardInfo.fpga_organ = spi_read32(240); // lese Lizenznummer aus
  DPRINTF("/ FPGA Organ License:  ");
  DPRINTLN(boardInfo.fpga_organ);

  boardInfo.fpga_rotary = spi_read32(241); // lese Lizenznummer aus
  DPRINTF("/ FPGA Rotary License: ");
  DPRINTLN(boardInfo.fpga_rotary);

  boardInfo.fpga_valid = spi_read32(244); // muss in 32 Bit-Register gelesen werden
  DPRINTF("/ FPGA License valid flags: ");
  DPRINTLN(boardInfo.fpga_valid);

  DPRINTLNF("/ Send Scan Driver to LC #0");
  df_send_core(LCTARGET_SCAN_DRIVER, BLOCK_SCAN);     // PicoBlaze Core #0

  spi_clearfifo();
  spi_autoIncReset(LCTARGET_SCAN_DRIVER); // Scan core zurücksetzen
  delay(10);
  uint32_t scan_info = spi_read32(MIDI_FIFO_RDREG); // Test: SPI-Transfer, lese erstes Wort von Core #0, sollte 0x12345678 sein
  DPRINTF("/ PicoBlaze response: ");
  DPRINTLN(scan_info, HEX);
  digitalWrite(LED_PIN, HIGH); // sets the LED off

  boardInfo.scan_id = scan_info & 0xFF;
  boardInfo.scan_version = (scan_info >> 8) & 0xFF;
  boardInfo.scan_validflag = (scan_info >> 16) & 0xFF;
  //$60=SR4014, $61=Fatar, $62=Opto, $63=MIDI, $64=OrganScan61, $65=XB2-5, $66=Fatar61 (neu), $67=Fatar73 (neu, mit Presets)
  if (boardInfo.scan_validflag == 0xAA) {
    DPRINTF("/ Scan Core valid, version ");
    DPRINT(boardInfo.scan_version, HEX);
    switch(boardInfo.scan_id &0x0F) {
      case 0x00:
        DPRINTLNF(", Scan16/SR4014");
        break;
      case 0x01:
        DPRINTLNF(", FatarScan2");
        break;
      case 0x02:
        DPRINTLNF(", Opto");
        break;
      case 0x03:
        DPRINTLNF(", MIDI");
        break;
      case 0x04:
        DPRINTLNF(", OrganScan61");
        break;
      case 0x05:
        DPRINTLNF(", XB2-5");
        break;
      case 0x06:
        DPRINTLNF(", FatarScan1-61");
        break;
      default:
        DPRINTLNF(", unknown ID!");
    }
    delay(10);
  } else {
    DPRINTLNF("/ Scan Core invalid!");
  }
}

#endif // BOARD_H
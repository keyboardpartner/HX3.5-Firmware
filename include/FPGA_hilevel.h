#ifndef FPGA_HILEVEL_H
#define FPGA_HILEVEL_H

// #############################################################################
//
//     #     # ###   #       ####### #     # ####### #
//     #     #  #    #       #       #     # #       #
//     #     #  #    #       #       #     # #       #
//     #######  #    #       #####   #     # #####   #
//     #     #  #    #       #        #   #  #       #
//     #     #  #    #       #         # #   #       #
//     #     # ###   ####### #######    #    ####### #######
//
// #############################################################################

#include <Arduino.h>
#include "FPGA_SPI.h"
#include "global_vars.h"


void fpga_setup() {
  spi_write8(68, 0); // Tuning Byte
  spi_write8(246, 0); // DSP Bits

  digitalWrite(LED_PIN, LOW); // sets the LED on
  digitalWrite(PWR_GOOD, HIGH); // DSP-Reset deaktivieren
  delay(150); // DSP booten lassen

  uint32_t fpga_version= spi_read32(3); // SPI-Transfer, lese Version aus
  Serial.print(F("/ FPGA Version: "));
  Serial.println(fpga_version, HEX);

  spi_read8(240); // hier nur DNA-Auslese-Trigger
  uint32_t fpga_serial = spi_read32(242); // lese Seriennummer aus
  Serial.print(F("/ FPGA Serial:  "));
  Serial.println(fpga_serial);

  // For Serial Number 2821432, Licence Organ: 9523781  Extended: 3316044
  // These will not work on other boards!
  spi_write32(240, 9523781);
  spi_write32(241, 3316044);

  uint32_t fpga_organ = spi_read32(240); // lese Lizenznummer aus
  Serial.print(F("/ FPGA Organ License:  "));
  Serial.println(fpga_organ);

  uint32_t fpga_rotary = spi_read32(241); // lese Lizenznummer aus
  Serial.print(F("/ FPGA Rotary License: "));
  Serial.println(fpga_rotary);

  uint8_t fpga_valid = spi_read32(244); // muss in 32 Bit-Register gelesen werden
  Serial.print(F("/ FPGA License valid flags: "));
  Serial.println(fpga_valid);

  df_send_core(0, 0);  // PicoBlaze Core #0
  df_send_core(1, 11);  // 1. Taper-Set, Block Offset 11 (nur unterste 8 Bit übertragen)
  df_send_core(2, 15);  // FIR Koeffizienten Horn, Block Offset 15
  df_send_core(4, 16);  // 1. Waveset, Block Offset 16 (4 Blocks für 1 Waveset)

  spi_clearfifo();
  spi_autoIncReset(0); // Scan core zurücksetzen
  delay(10);
  uint32_t scan_info = spi_read32(MIDI_FIFO_RDREG); // Test: SPI-Transfer, lese erstes Wort von Core #0, sollte 0x12345678 sein
  Serial.print(F("/ Scan Core response: "));
  Serial.println(scan_info, HEX);
  digitalWrite(LED_PIN, HIGH); // sets the LED off

  uint8_t scan_id = scan_info & 0xFF;
  uint8_t scan_version = (scan_info >> 8) & 0xFF;
  uint8_t scan_validflag = (scan_info >> 16) & 0xFF;
  //$60=SR4014, $61=Fatar, $62=Opto, $63=MIDI, $64=OrganScan61, $65=XB2-5, $66=Fatar61 (neu), $67=Fatar73 (neu, mit Presets)
  if (scan_validflag == 0xAA) {
    Serial.print("/ Scan Core valid, version ");
    Serial.print(scan_version, HEX);
    switch(scan_id &0x0F) {
      case 0x00:
        Serial.println(F(", Scan16/SR4014"));
        break;
      case 0x01:
        Serial.println(F(", FatarScan2"));
        break;
      case 0x02:
        Serial.println(F(", Opto"));
        break;
      case 0x03:
        Serial.println(F(", MIDI"));
        break;
      case 0x04:
        Serial.println(F(", OrganScan61"));
        break;
      case 0x05:
        Serial.println(F(", XB2-5"));
        break;
      case 0x06:
        Serial.println(F(", FatarScan1-61"));
        break;
      default:
        Serial.println(F(", unknown ID!"));
    }
  } else {
    Serial.println(F("/ Scan Core invalid!"));
  }
}


#endif
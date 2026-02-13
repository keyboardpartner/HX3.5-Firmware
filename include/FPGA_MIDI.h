#ifndef FPGA_MIDI_H
#define FPGA_MIDI_H

// #############################################################################
// MIDI to FPGA Scancore communication functions
// Sends MIDI Bytes to FPGA MIDI OUT FIFO
// Scan Core will handle or forward them to MIDI-OUT, MIDI-USB and SAM5504 DSP
// Incoming data from Scan Core (e.g. MIDI IN) can be read by spi_read32(MIDI_FIFO_RDREG)
// 3 Bytes at a time. Sysex data will be specially formatted.
// #############################################################################

#include <Arduino.h>
#include "FPGA_SPI.h"

void midi_sendbyte(uint8_t midi_byte) {
  // warte auf leeren MIDI-OUT-FIFO, dann Byte senden
  if (board_info.scan_validflag) {
    while ((spi_read32(0) & 3) != 0) { delay(2);} // STATUS anfordern
    spi_write8(0x0C, midi_byte); // MIDI-Byte an Register 0 übermitteln, wird von Scan-Core gelesen
  }
}

uint16_t midi_14_to_word(uint8_t msb, uint8_t lsb) {
  // zwei 7-Bit-Fragmente zu einem Word zusammenbasteln
  return ((uint16_t)msb << 7) | (uint16_t)lsb;
}

void midi_sendword(uint16_t my_word) {
  // Integer in zwei MIDI-Bytes umrechnen und senden
  uint8_t lsb = my_word & 0x7F;
  uint8_t msb = (my_word >> 7) & 0x7F;
  midi_sendbyte(msb);
  midi_sendbyte(lsb);
}

void midi_sendnrpn(uint16_t my_nrpn, uint8_t my_val) {
  // benötigt für GM Piano-, Equalizer und Reverb-Fernsteuerung
  if ((my_nrpn & 0x8080) == 0) { // $0000..$7F7F
    midi_sendbyte(0xB0); // Control Change, Kanal 0
    midi_sendbyte(0x62); // NRPN LSB
    midi_sendbyte(my_nrpn & 0x7F);
    midi_sendbyte(0x63); // NRPN MSB
    midi_sendbyte((my_nrpn >> 7) & 0x7F);
    midi_sendbyte(6); // Data Entry MSB
    midi_sendbyte(my_val & 0x7F);
    delayMicroseconds(40); // MIDI-Übertragung abwarten
  }
}

void midi_sendboolean(uint8_t my_channel_offset, uint8_t my_ctrl, bool my_bool) {
  // MIDI-Controller mit Wert 0 oder 1 senden
  uint8_t send_ch; // default: Kanal 0
  if (my_channel_offset > 4) {
    send_ch = my_channel_offset;
  } else {
    send_ch = constrain(midi_settings.channel + my_channel_offset, 0, 15);
  }
  midi_sendbyte(0xB0 + send_ch); // Control Change
  midi_sendbyte(my_ctrl);
  midi_sendbyte((uint8_t)my_bool & 0x01);
}

void midi_sendcontroller(uint8_t my_channel_offset, uint8_t my_ctrl, uint8_t my_val) {
  // MIDI-Controller mit Wert 0..127 senden
  uint8_t send_ch; // default: Kanal 0
  if (my_channel_offset > 4) {
    send_ch = my_channel_offset;
  } else {
    send_ch = constrain(midi_settings.channel + my_channel_offset, 0, 15);
  }
  midi_sendbyte(0xB0 + send_ch); // Control Change
  midi_sendbyte(my_ctrl);
  midi_sendbyte(my_val & 0x7F);
}

#endif
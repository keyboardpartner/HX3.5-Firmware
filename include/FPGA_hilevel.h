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
#include "FPGA_MIDI.h"

// #############################################################################

void fpga_send_waveset(uint8_t waveset) {
  DPRINTF("/ Send Waveset #");
  DPRINT(waveset);
  DPRINTLNF(" to LC #4");
  df_send_core(LCTARGET_WAVESET, BLOCK_WAVESET_BASE + (waveset * 4));  // Waveset #waveset, Block Offset 16 ff. (4 Blocks für 1 Waveset)
}

void fpga_send_taperset(uint8_t taperset) {
  // benutzt nicht df_send_core(), da evt.
  // eine Skalierung der Daten nötig ist
  DPRINTF("/ Send Taper-Set #");
  DPRINT(taperset);
  DPRINTF(" to LC #1");
  df_readblock(BLOCK_TAPER_BASE + taperset, 4096);
  for (uint16_t array_idx = 0; array_idx < 1024; array_idx++) {
    spi_blockbuffer.dword[array_idx] &= 0x000000FF; // nur unterste 8 Bit übertragen
  }
  spi_autoIncSetup(LCTARGET_TAPERING); // for Write
  spi_send_blockbuffer(1024, 32, true);
  spi_autoIncReset(LCTARGET_TAPERING); // for Write Core 1, Taper-Set
}

// -----------------------------------------------------------------------------

void fpga_make_keymap64(uint16_t buffer_offset, uint8_t start_note, uint8_t generator_size, bool do_high_foldback) {
  for (uint8_t i = 0; i < 64; i++) {
    spi_blockbuffer.byte[buffer_offset + i] = start_note;
    start_note++;
    if (start_note >= generator_size) {
      if (do_high_foldback) {
        start_note -= 12;
      } else {
        start_note = 127;   // Rest abgeschaltet
      }
    }
  }
}

void fpga_send_keymap() {
  DPRINTF("/ Send Keymap to LC #3");
  for (uint8_t busbar = 0; busbar < 16; busbar++) {
    fpga_make_keymap64(busbar * 64, organModel.busbar_offsets[busbar], organModel.generator_size, organModel.has_foldback);
  }
  spi_autoIncSetup(LCTARGET_KEYMAP); // for Write Core 3, Keymap
  spi_send_blockbuffer(1024, 8, true); // 1024 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_KEYMAP);
}

// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------

void fpga_make_hpfilter64(uint16_t buffer_offset, uint8_t start_note) {
  for (uint8_t i = 0; i < 64; i++) {
    spi_blockbuffer.word[buffer_offset + i] = (c_HighpassFilterArray[start_note] * organModel.busbar_levels[i / 4]) / 64;
    start_note++;
    if (start_note >= organModel.generator_size) {
      start_note -= 12;
    }
  }
}

void fpga_send_hpfilter() {
  DPRINTF("/ Send Highpass Filters to LC #6");
  for (uint8_t busbar = 0; busbar < 16; busbar++) {
    fpga_make_hpfilter64(busbar * 64, organModel.busbar_offsets[busbar]);
  }
  spi_autoIncSetup(LCTARGET_HP_FILTER); // for Write Core 6, Highpass-Filter
  spi_send_blockbuffer(1024, 16, true); // 1024 Werte à 16 Bit
  spi_autoIncReset(LCTARGET_HP_FILTER);
}

// -----------------------------------------------------------------------------

void fpga_send_tuning(uint8_t tuning_set) {
// 95 Tuning-Werte 16 Bit breit an FPGA DDS96 übertragen
// Generator dds96 arbeitet mit Vorteilern 1..128 pro Oktave, deshalb gleiche Werte
// für jede Oktave. Lediglich oberste Hammond-Oktave ist etws gespreizt, deshalb extra.
  DPRINTF("/ Send Tuning #");
  DPRINT(tuning_set);
  DPRINTF(" to LC #5");
  uint16_t buf_idx = 0;
  if (tuning_set == 0) {
    // Hammond Spread
    for (uint8_t m = 0; m < 7; m++) {
      for (uint8_t i = 0; i < 12; i++) {
        spi_blockbuffer.word[buf_idx] = c_TuningArrayHammond[i];
        buf_idx++;
      }
    }
    for (uint8_t i = 0; i < 12; i++) {
      spi_blockbuffer.word[buf_idx] = c_TuningArrayHammondSpread[i];
      buf_idx++;
    }
  } else {
    for (uint8_t m = 0; m < 8; m++) {
      for (uint8_t i = 0; i < 12; i++) {
        spi_blockbuffer.word[buf_idx] = c_TuningArrayEven[i];
        if (tuning_set > 1) {
          uint8_t my_random_word = random(0, tuning_set > 2 ? 8 : 4);
          if ((my_random_word & 1) == 0) {
            spi_blockbuffer.word[buf_idx] += my_random_word;
          } else {
            spi_blockbuffer.word[buf_idx] -= my_random_word;
          }
        }
        buf_idx++;
      }
    }
  }
  spi_autoIncSetup(LCTARGET_TUNING_VALS); // for Write Core 5, Tuning Vals
  spi_send_blockbuffer(buf_idx, 16, true); // 96 Werte à 16 Bit
  spi_autoIncReset(LCTARGET_TUNING_VALS);
  spi_write8(68, c_TuningTable[organModel.tuning_val]);  // CycleSteal-Wert -125 .. +125
}


// -----------------------------------------------------------------------------

union {
  uint16_t word[8] = {0x0FFF, 0, 0, 0, 0, 0, 0, 0};
  struct {
    uint16_t ena_cont;
    uint16_t ena_env_db;
    uint16_t ena_env_full;
    uint16_t env_to_dry;
    // nur in FW benutzt, nicht an FPGA gesendet:
    uint16_t ena_cont_perc;
    uint16_t ena_env_percmode;
    uint16_t ena_env_adsrmode;
    uint16_t ena_env_timemode;
   } bits;
} bb_words;

void fpga_send_contact_enables() {
  DPRINTLNF("/ Send Contact Enables to SPI #40..#43");
  for (uint8_t i = 0; i < 4; i++) {
    spi_write16(40 + i, bb_words.word[i]);
  }
}

// -----------------------------------------------------------------------------

void fpga_send_upper_db() {
  DPRINTF("/ Send Upper DB to LC #8");
  for (uint8_t i = 0; i < 16; i++) {
    uint16_t my_val = (preset.db_upper[i] * organModel.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_UPPER_DRAWBARS); // for Write Core 8, Upper Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_UPPER_DRAWBARS);
}

void fpga_send_lower_db() {
  DPRINTF("/ Send Lower DB to LC #9");
  for (uint8_t i = 0; i < 16; i++) {
    uint16_t my_val = (preset.db_lower[i] * organModel.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_LOWER_DRAWBARS); // for Write Core 9, Lower Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_LOWER_DRAWBARS);
}

void fpga_send_pedal_db() {
  DPRINTF("/ Send Pedal DB to LC #10");
  for (uint8_t i = 0; i < 16; i++) {
    uint16_t my_val = (preset.db_pedal[i] * organModel.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_PEDAL_DRAWBARS); // for Write Core 10, Pedal Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_PEDAL_DRAWBARS);
}

// -----------------------------------------------------------------------------

// #############################################################################

#endif
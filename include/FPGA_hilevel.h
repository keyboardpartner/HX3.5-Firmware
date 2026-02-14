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
    fpga_make_keymap64(busbar * 64, organ_model.busbar_offsets[busbar], organ_model.generator_size, organ_model.has_foldback);
  }
  spi_autoIncSetup(LCTARGET_KEYMAP); // for Write Core 3, Keymap
  spi_send_blockbuffer(1024, 8, true); // 1024 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_KEYMAP);
}

// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------

void fpga_make_hpfilter64(uint16_t buffer_offset, uint8_t start_note) {
  for (uint8_t i = 0; i < 64; i++) {
    spi_blockbuffer.word[buffer_offset + i] = (c_HighpassFilterArray[start_note] * organ_model.busbar_levels[i / 4]) / 64;
    start_note++;
    if (start_note >= organ_model.generator_size) {
      start_note -= 12;
    }
  }
}

void fpga_send_hpfilter() {
  DPRINTF("/ Send Highpass Filters to LC #6");
  for (uint8_t busbar = 0; busbar < 16; busbar++) {
    fpga_make_hpfilter64(busbar * 64, organ_model.busbar_offsets[busbar]);
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
  spi_write8(68, c_TuningTable[organ_model.tuning_val]);  // CycleSteal-Wert -125 .. +125
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
    uint16_t my_val = (preset.db_upper[i] * organ_model.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_UPPER_DRAWBARS); // for Write Core 8, Upper Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_UPPER_DRAWBARS);
}

void fpga_send_lower_db() {
  DPRINTF("/ Send Lower DB to LC #9");
  for (uint8_t i = 0; i < 16; i++) {
    uint16_t my_val = (preset.db_lower[i] * organ_model.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_LOWER_DRAWBARS); // for Write Core 9, Lower Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_LOWER_DRAWBARS);
}

void fpga_send_pedal_db() {
  DPRINTF("/ Send Pedal DB to LC #10");
  for (uint8_t i = 0; i < 16; i++) {
    uint16_t my_val = (preset.db_pedal[i] * organ_model.busbar_levels[i]) / 127;
    spi_blockbuffer.byte[i] = (my_val > 127) ? 127 : (uint8_t)my_val;
  }
  spi_autoIncSetup(LCTARGET_PEDAL_DRAWBARS); // for Write Core 10, Pedal Drawbars
  spi_send_blockbuffer(16, 8, true); // 16 Werte à 8 Bit
  spi_autoIncReset(LCTARGET_PEDAL_DRAWBARS);
}

// -----------------------------------------------------------------------------

void fpga_initVolumes() {
  if (!board_info.scan_validflag) { return; }
  spi_write8_scaled(SPI_UPPER_WET_LVL, preset.upperVolumeWet, 150);
  spi_write8_scaled(SPI_LOWER_LVL, preset.lowerVolume, 150);
  spi_write8_scaled(SPI_UPPER_DRY_LVL, preset.upperVolumeDry, 150);

  spi_write16(SPI_PED_TO_VIB_LVL, preset.pedalVolume); // Pedal an Vibrato Lower, über AO28
  spi_write16(SPI_PED_TO_AO28_LVL, 0); // Pedal Dry über AO28
  spi_write16(SPI_PED_TO_BYPASS_AMP, preset.pedalVolume); // Pedal to Ext. Output & Postmix

  spi_write8(SPI_SWAP_DACS, 0);  // Swap Dacs 0=normal, 1=swap
  spi_write8(SPI_INSERTS, 0);  // Inserts

  spi_write16_volume(SPI_AMP_IN_LVL, preset.ampVolume);
  spi_write8(SPI_AMP_OUT_LVL, 100);     // Tube Amp Out Level
  spi_write16_volume(SPI_MASTER_VOLUME, preset.masterVolume);  // 72 = Master Vol I2S Multiplier

  spi_write8(SPI_AO28_LOUDN_BASS, ao28.swellLoudnessBass);
  spi_write8(SPI_AO28_MIDRANGE, 255); // AO28 midrange
  spi_write8(SPI_AO28_LOUDN_TREBLE, ao28.swellLoudnessTreble); // AO28 LoudnessTreble
  spi_write8(SPI_AO28_MIDRANGE_SHELF, ao28.swellMidrangeShelving * 2);
  spi_write8(SPI_AO28_FINAL_GAIN, 128 + ao28.trimSwell);
  spi_write8(SPI_AO28_TRIODE_K2, 255 - ao28.triode_k2);
  spi_write8(SPI_AO28_FREQU_RESPONSE_FINAL, ao28.swellFinalResponse);
  spi_write8(SPI_AO28_FREQU_RESPONSE_MIDRANGE, ao28.swellMidrangeResponse);
  spi_write8(SPI_AO28_BYPASS_SEL, 1); // AO28 Equalizing Bypass wenn 1

  spi_write8(SPI_INSERTS, 0); // Vorerst keine Effekte, Inserts auf 0

  spi_write8(SPI_VIB_DRY_LVL, 200); // Vibrato Dry Level auf 0..255
  spi_write8(SPI_VIB_MODWAVE_PHASE, 3); // Vibrato Modwave Phase und Noise Level

  spi_write8(SPI_SPEED_HORN, 30); // Speed Horn
  spi_write8(SPI_SPEED_ROTOR, 30); // Speed Rotor

  midi_sendnrpn(0x3509, 115); // SAM55004 GM2 Pre-Mix Gain
  midi_sendnrpn(0x3510, 127); // SAM55004 GM2 General Master Volume
  midi_sendnrpn(0x3512, 127); // SAM55004 GM2 Master Volume
  midi_sendnrpn(0x3514, equalizer.bass); // SAM55004 Equalizer Bass Level
  midi_sendnrpn(0x3515, equalizer.bass_freq); // SAM55004 Equalizer Bass Frequency
  midi_sendnrpn(0x3516, equalizer.bass_peak / 2); // SAM55004 Equalizer Bass Peak
  midi_sendnrpn(0x3517, equalizer.mid); // SAM55004 Equalizer Mid Level
  midi_sendnrpn(0x3518, equalizer.mid_freq); // SAM55004 Equalizer Mid Frequency
  midi_sendnrpn(0x3519, equalizer.mid_peak / 2); // SAM55004 Equalizer Mid Peak
  midi_sendnrpn(0x351A, equalizer.treble); // SAM55004 Equalizer Treble Level
  midi_sendnrpn(0x351B, equalizer.treble_freq); // SAM55004 Equalizer Treble Frequency
  midi_sendnrpn(0x351C, equalizer.treble_peak / 2); // SAM55004 Equalizer Treble Peak
  midi_sendnrpn(0x351D, 1); // SAM5504 EQU Bass/Treble Type full parametric = 1

  midi_sendnrpn(0x3530, 1);   // UpperGMharm
  midi_sendnrpn(0x3560, 127); // UpperGMlvl
  midi_sendnrpn(0x3564, 0);   // UpperGMlvl

  DPRINTLNF("/ Init Volumes done");
}

// #############################################################################

void fpga_setup() {
  spi_write8(68, 0); // Tuning Byte
  spi_write8(246, 0); // DSP Bits

  digitalWrite(LED_PIN, LOW); // sets the LED on
  digitalWrite(PWR_GOOD, HIGH); // DSP-Reset deaktivieren
  delay(150); // DSP booten lassen

  board_info.fpga_version= spi_read32(3); // SPI-Transfer, lese Version aus
  DPRINTF("/ FPGA Version: ");
  DPRINTLN(board_info.fpga_version, HEX);

  spi_read8(240); // hier nur DNA-Auslese-Trigger
  board_info.fpga_serial = spi_read32(242); // lese Seriennummer aus
  DPRINTF("/ FPGA Serial:  ");
  DPRINTLN(board_info.fpga_serial);

  // For Serial Number 2821432, Licence Organ: 9523781  Extended: 3316044
  // These will not work on other boards!
  spi_write32(240, 9523781);
  spi_write32(241, 3316044);

  board_info.fpga_organ = spi_read32(240); // lese Lizenznummer aus
  DPRINTF("/ FPGA Organ License:  ");
  DPRINTLN(board_info.fpga_organ);

  board_info.fpga_rotary = spi_read32(241); // lese Lizenznummer aus
  DPRINTF("/ FPGA Rotary License: ");
  DPRINTLN(board_info.fpga_rotary);

  board_info.fpga_valid = spi_read32(244); // muss in 32 Bit-Register gelesen werden
  DPRINTF("/ FPGA License valid flags: ");
  DPRINTLN(board_info.fpga_valid);

  DPRINTLNF("/ Send Scan Driver to LC #0");
  df_send_core(LCTARGET_SCAN_DRIVER, BLOCK_SCAN);   // PicoBlaze Core #0
  DPRINTLNF("/ Send FIR Coeff to LC #2");
  df_send_core(LCTARGET_FIR_COEFF, BLOCK_FIR_COEFF);  // FIR Koeffizienten Horn, Block Offset 15

  fpga_send_taperset(organ_model.taperset); // Taper-Set aus organ_model, Block Offset 11 (nur unterste 8 Bit übertragen)
  fpga_send_waveset(organ_model.waveset);  // Waveset aus organ_model, Block Offset 16 (4 Blocks für 1 Waveset)
  fpga_send_hpfilter();
  fpga_send_keymap();
  fpga_send_tuning(organ_model.tuning_set);

  fpga_send_contact_enables();
  bb_words.bits.ena_cont = 0x0FFF; // alle 12 "mechanischen" Kontakte aktiviert
  spi_write16(40, bb_words.bits.ena_cont);
  fpga_send_upper_db();
  fpga_send_lower_db();
  fpga_send_pedal_db();

  spi_clearfifo();
  spi_autoIncReset(LCTARGET_SCAN_DRIVER); // Scan core zurücksetzen
  delay(10);
  uint32_t scan_info = spi_read32(MIDI_FIFO_RDREG); // Test: SPI-Transfer, lese erstes Wort von Core #0, sollte 0x12345678 sein
  DPRINTF("/ PicoBlaze response: ");
  DPRINTLN(scan_info, HEX);
  digitalWrite(LED_PIN, HIGH); // sets the LED off

  board_info.scan_id = scan_info & 0xFF;
  board_info.scan_version = (scan_info >> 8) & 0xFF;
  board_info.scan_validflag = (scan_info >> 16) & 0xFF;
  //$60=SR4014, $61=Fatar, $62=Opto, $63=MIDI, $64=OrganScan61, $65=XB2-5, $66=Fatar61 (neu), $67=Fatar73 (neu, mit Presets)
  if (board_info.scan_validflag == 0xAA) {
    DPRINTF("/ Scan Core valid, version ");
    DPRINT(board_info.scan_version, HEX);
    switch(board_info.scan_id &0x0F) {
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
  fpga_initVolumes(); // Checkt, ob Scan Core valid ist
}

#endif
#ifndef ORGAN_H
#define ORGAN_H

// Organ-specific definitions and functions
#include "FPGA_SPI.h"
#include "global_vars.h"
#include "FPGA_MIDI.h"
#include "FPGA_hilevel.h"
#include "board.h"

void setOrganContacts() {
  spi_write8(SPI_SCAN_MIDICH, midiSettings.channel); 
  uint8_t temp = (organModel.contFlex << 4) | (organModel.contDamping & 15);
  spi_write8(SPI_SCAN_CLICK, temp); 
  spi_write8(SPI_SCAN_KEY_TRANSPOSE, organModel.keyTranspose); 
  spi_write8(SPI_SCAN_GEN_TRANSPOSE, organModel.genTranspose); 
  spi_write8(SPI_SCAN_SPLITPOINT, 24); 
  spi_write8(SPI_SCAN_SPLIT_ON, 0); 
  spi_write8(SPI_SCAN_PWM_LOCALDISABLES, 0); 

  temp = (organModel.earlyKeyCont & 1) | ((organModel.fatarVelocityFactor) << 2);
  spi_write8(SPI_SCAN_CONFIG_1, temp);
  spi_write8(SPI_SCAN_MIDISEND_DISABLES, 0); // alle MIDI-Ausgänge aktivieren
  spi_write8(SPI_SCAN_PWM_LOCALDISABLES, 0); // alle PWM 
  spi_write8(SPI_DDS_TUNING, c_TuningTable[organModel.tuning_val]); // alle PWM 
  temp = (organModel.flutter & 0x0F) | (organModel.leakage << 4);
  spi_write8(SPI_LEAK_RNDMASK, temp); // Flutter und Leckage
  fpga_send_contact_enables();
}

void setOrganGenerator() {
  fpga_send_tuning(organModel.tuning_set);
  fpga_send_keymap();
  fpga_send_hpfilter();
}

void setOrganInserts() {
  spi_write8(SPI_SWAP_DACS, 0); 
  spi_write8(SPI_INSERTS, 0); 
  if (!board_info.scan_validflag) { return; }
  midi_sendnrpn(0x350E, equalizer.equ_bypass);
}

void setOrganEqualizer() {
  if (!board_info.scan_validflag) { return; }
  midi_sendnrpn(0x350E, equalizer.equ_bypass);
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
}

void setOrganVolumes() {
  spi_write8_scaled(SPI_UPPER_WET_LVL, preset.upperVolumeWet, 150);
  spi_write8_scaled(SPI_LOWER_LVL, preset.lowerVolume, 150);
  spi_write8_scaled(SPI_UPPER_DRY_LVL, preset.upperVolumeDry, 150);
  spi_write16(SPI_PED_TO_VIB_LVL, preset.pedalVolume); // Pedal an Vibrato Lower, über AO28
  spi_write16(SPI_PED_TO_AO28_LVL, 0); // Pedal Dry über AO28
  spi_write16(SPI_PED_TO_BYPASS_AMP, preset.pedalVolume); // Pedal to Ext. Output & Postmix
  spi_write8_volume(SPI_AMP_IN_LVL, preset.ampVolume);
  spi_write8(SPI_AMP_OUT_LVL, 100);     // Tube Amp Out Level
  spi_write8_volume(SPI_MASTER_VOLUME, preset.masterVolume);  // 72 = Master Vol I2S Multiplier
}

void setOrganVibrato() {
  // TODO!
  spi_write8(SPI_VIB_DRY_LVL, 200); // Vibrato Dry Level auf 0..255
  spi_write8(SPI_VIB_MODWAVE_PHASE, 3); // Vibrato Modwave Phase und Noise Level
}

void setOrganPercussion() {
  // TODO!
}

void setOrganSwell() {
  // TODO! Werte müssen anhand Schwellerstellung berechnet werden, hier nur Beispielwerte
  spi_write8(SPI_AO28_LOUDN_BASS, ao28.swellLoudnessBass);
  spi_write8(SPI_AO28_MIDRANGE, 255); // AO28 midrange
  spi_write8(SPI_AO28_LOUDN_TREBLE, ao28.swellLoudnessTreble); // AO28 LoudnessTreble
  spi_write8(SPI_AO28_MIDRANGE_SHELF, ao28.swellMidrangeShelving * 2);
  spi_write8(SPI_AO28_FINAL_GAIN, 128 + ao28.trimSwell);
  spi_write8(SPI_AO28_TRIODE_K2, 255 - ao28.triode_k2);
  spi_write8(SPI_AO28_FREQU_RESPONSE_FINAL, ao28.swellFinalResponse);
  spi_write8(SPI_AO28_FREQU_RESPONSE_MIDRANGE, ao28.swellMidrangeResponse);
  spi_write8(SPI_AO28_BYPASS_SEL, 1); // AO28 Equalizing Bypass wenn 1
}

void initOrgan() {
  DPRINTLNF("/ Send FIR Coeff to LC #2");
  df_send_core(LCTARGET_FIR_COEFF, BLOCK_FIR_COEFF);  // FIR Koeffizienten Horn
  fpga_send_taperset(organModel.taperset); // Taper-Set aus organ_model, Block Offset 11 (nur unterste 8 Bit übertragen)
  fpga_send_waveset(organModel.waveset);  // Waveset aus organ_model, Block Offset 16 (4 Blocks für 1 Waveset)
  fpga_send_hpfilter();
 
  setOrganGenerator();
  setOrganContacts();
  setOrganVolumes();
  setOrganInserts();
  setOrganVibrato();
  setOrganEqualizer();
  setOrganSwell();

  fpga_send_upper_db();
  fpga_send_lower_db();
  fpga_send_pedal_db();

  if (!board_info.scan_validflag) { return; }
  midi_sendnrpn(0x3509, 115); // SAM55004 GM2 Pre-Mix Gain
  midi_sendnrpn(0x3510, 127); // SAM55004 GM2 General Master Volume
  midi_sendnrpn(0x3512, 127); // SAM55004 GM2 Master Volume

  midi_sendnrpn(0x3530, 1);   // UpperGMharm
  midi_sendnrpn(0x3560, 127); // UpperGMlvl
  midi_sendnrpn(0x3564, 0);   // UpperGMlvl

  DPRINTLNF("/ Init Organ done");
}

// -----------------------------------------------------------------------------
// Funktionen ohne Parameter für EditAction
// -----------------------------------------------------------------------------

void organReset() {
  DPRINTLN("/ Reload FPGA");
  configurePorts(); // Port Initialisierung je nach Treibertyp
  if (fpgaOK) {
    initBoard();
    initOrgan();
  }
}
#endif // ORGAN_H
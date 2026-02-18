#ifndef ORGAN_H
#define ORGAN_H

// #############################################################################
//
//     #######  ########   ######      ###    ##    ## 
//    ##     ## ##     ## ##    ##    ## ##   ###   ## 
//    ##     ## ##     ## ##         ##   ##  ####  ## 
//    ##     ## ########  ##   #### ##     ## ## ## ## 
//    ##     ## ##   ##   ##    ##  ######### ##  #### 
//    ##     ## ##    ##  ##    ##  ##     ## ##   ### 
//     #######  ##     ##  ######   ##     ## ##    ## 
//
// #############################################################################

// Organ-specific definitions and functions

#include "FPGA_SPI.h"
#include "global_vars.h"
#include "FPGA_MIDI.h"
#include "FPGA_hilevel.h"
#include "board.h"

// -----------------------------------------------------------------------------
// Prototypes
// -----------------------------------------------------------------------------

void sendSwellEqu(uint8_t swell_raw255, bool bypass_ao28);

void sendOrganKeybed();
void sendOrganGenerator();
void sendOrganInserts();
void sendOrganEqualizer();
void sendOrganVolumes();
void sendOrganVibrato();
// TODO!

void sendOrganPercussion();
// TODO!


// kopiert nur für Orgelmodell relevante Teile ins edit_array
// liefert TRUE wenn Orgelmodell gültig (> 0) und geladen
bool loadOrganModel(uint8_t organModelIdx);

// -----------------------------------------------------------------------------
// Wrapper-Funktionen ohne Parameter für EditAction
// -----------------------------------------------------------------------------

void sendOrganSwell();
void initOrgan();
void organReset();

// #############################################################################

void sendOrganSwell() {
  sendSwellEqu(preamp.swell127 * 2, false);
}

void sendSwellEqu(uint8_t swell_raw255, bool bypass_ao28){
  // Werte für FPGA müssen anhand Schwellerstellung berechnet werden
  if (bypass_ao28) {
    DPRINTLNF("/ Swell Bypass EQ ");
    spi_write8(SPI_AO28_BYPASS_SEL, 1); // AO28 Equalizing Bypass wenn 1
    spi_write8(SPI_AO28_LOUDN_BASS, preamp.swellLoudnessBass);
    spi_write8(SPI_AO28_MIDRANGE, swell_raw255); // AO28 midrange
    spi_write8(SPI_AO28_LOUDN_TREBLE, preamp.swellLoudnessTreble); // AO28 LoudnessTreble
    spi_write8(SPI_AO28_MIDRANGE_SHELF, preamp.swellMidrangeShelving * 2);
    spi_write8(SPI_AO28_FINAL_GAIN, 128 + preamp.trimSwell);
    spi_write8(SPI_AO28_TRIODE_K2, swell_raw255 - preamp.triode_k2);
    spi_write8(SPI_AO28_FREQU_RESPONSE_FINAL, preamp.swellFinalResponse);
    spi_write8(SPI_AO28_FREQU_RESPONSE_MIDRANGE, preamp.swellMidrangeResponse);
  } else {
    DPRINTF("/ Swell: ");
    uint8_t swell_raw128 = swell_raw255 / 2;
    uint8_t swell_bassboost = mulDivByte(preamp.swellLoudnessBass, preamp.minimalSwell, 20) + c_AntiLogTable[swell_raw128] / 3;   // #1091
    if( swell_bassboost > 200) {
      swell_bassboost = 200;
    }
    // halber Anstieg bis 32, danach steiler bis max. 255
    uint8_t swell_midrange;
    if (swell_raw255 < 32) {
      swell_midrange = swell_raw255 / 2; // 0..16
    } else {
      swell_midrange = mulDivByte(swell_raw255-16, 255, 255-16);
    }
    
    uint8_t swell_temp = preamp.minimalSwell / 10;
    if (swell_temp > 0) {
      swell_midrange = swell_temp + mulDivByte(swell_midrange, 255-swell_temp, 255);
    }
    uint8_t swell_midrange_response = preamp.swellMidrangeResponse; // #1092
    
    uint16_t swell_midrange_shelf = preamp.swellMidrangeShelving + mulDivByte(preamp.swellMidrangeShelving, preamp.tonePot, 64);      // #1093, 0..255
    if (swell_midrange_shelf > 255) {
      swell_midrange_shelf = 255;
    }
    
    swell_temp = preamp.tonePot / 4;
    uint8_t swell_final_response = preamp.swellFinalResponse + swell_temp;  // #1094
    if (swell_final_response > 63) {
      swell_final_response = 63; // nur 5 Bit
    }
    uint8_t swell_loudness_hi = mulDivByte(swell_temp + preamp.swellLoudnessTreble, preamp.minimalSwell, 20);  // #1095
    
    DPRINT (swell_raw255);
    DPRINTF (", Loudness Bass: ");
    DPRINT (swell_bassboost);
    DPRINTF (", Midrange: ");
    DPRINT (swell_midrange);
    DPRINTF (", Mid Resp: ");
    DPRINT (swell_midrange_response);
    DPRINTF (", Mid Shelf: ");
    DPRINT (swell_midrange_shelf);
    DPRINTF (", Final Resp: ");
    DPRINT (swell_final_response);
    DPRINTF (", Loudness Hi: ");
    DPRINT (swell_loudness_hi);
    DPRINTLN();

    spi_write8(SPI_AO28_BYPASS_SEL, 0); // AO28 Equalizing Bypass abgeschaltet
    spi_write8(SPI_AO28_LOUDN_BASS, swell_bassboost);
    spi_write8(SPI_AO28_MIDRANGE, swell_midrange); // AO28 midrange
    spi_write8(SPI_AO28_FREQU_RESPONSE_MIDRANGE, swell_midrange_response);
    spi_write8(SPI_AO28_MIDRANGE_SHELF, swell_midrange_shelf);
    spi_write8(SPI_AO28_FINAL_GAIN, 128 + preamp.trimSwell);
    spi_write8(SPI_AO28_LOUDN_TREBLE, swell_loudness_hi); // AO28 LoudnessTreble
    
    spi_write8(SPI_AO28_TRIODE_K2, 255 - preamp.triode_k2);
    spi_write8(SPI_AO28_FREQU_RESPONSE_FINAL, swell_final_response);
  }
}

// -----------------------------------------------------------------------------
// Keybed-Parameter senden, z.B. bei Orgelmodellwechsel oder MIDI-Kanalwechsel
// -----------------------------------------------------------------------------

void sendOrganKeybed() {
  DPRINTLNF("/ Send Keybed to FPGA");
  spi_write8(SPI_SCAN_MIDICH, midiSettings.channel); 
  uint8_t temp = (organModel.contFlex << 4) | (organModel.contDamping & 15);
  spi_write8(SPI_SCAN_CLICK, temp); 
  spi_write8(SPI_SCAN_KEY_TRANSPOSE, organModel.keyTranspose); 
  spi_write8(SPI_SCAN_GEN_TRANSPOSE, organModel.genTranspose); 
  spi_write8(SPI_SCAN_SPLITPOINT, 24); 
  spi_write8(SPI_SCAN_SPLIT_ON, 0); 
  spi_write8(SPI_SCAN_PWM_LOCALDISABLES, 0); 

  temp = (organModel.earlyKeyCont & 1) | ((organModel.fatarVelocityFac) << 2);
  spi_write8(SPI_SCAN_CONFIG_1, temp);
  spi_write8(SPI_SCAN_MIDISEND_DISABLES, 0); // alle MIDI-Ausgänge aktivieren
  spi_write8(SPI_SCAN_PWM_LOCALDISABLES, 0); // alle PWM 
  spi_write8(SPI_DDS_TUNING, c_TuningTable[organModel.tuning_val]); // alle PWM 
  temp = (organModel.flutter & 0x0F) | (organModel.leakage << 4);
  spi_write8(SPI_LEAK_RNDMASK, temp); // Flutter und Leckage
  fpga_send_contact_enables();
}

void sendOrganGenerator() {
  DPRINTLNF("/ Send Generator to FPGA");
  fpga_send_tuning(organModel.tuning_set);
  fpga_send_keymap();
  fpga_send_hpfilter();
}

void sendOrganInserts() {
  DPRINTLNF("/ Send Inserts to FPGA");
  spi_write8(SPI_SWAP_DACS, 0); 
  if (organ.vibToPedal) {
    organ.inserts |= INSERT_PEDAL_POSTMIX;
  } else {
    organ.inserts &= ~INSERT_PEDAL_POSTMIX;
  }
  if (tabs.tubeAmpBypass) {
    organ.inserts &= ~INSERT_TUBEAMP;
  } else {
    organ.inserts |= INSERT_TUBEAMP;
  }
  if (tabs.speakerBypass) {
    organ.inserts &= ~INSERT_SPEAKER;
  } else {
    organ.inserts |= INSERT_SPEAKER;
  }
  if (tabs.phrUpper) {
    organ.inserts |= INSERT_PHR_UPR;
  } else {
    organ.inserts &= ~INSERT_PHR_UPR;
  }
  if (tabs.phrLower) {
    organ.inserts |= INSERT_PHR_LWR;
  } else {
    organ.inserts &= ~INSERT_PHR_LWR;
  }
  spi_write8(SPI_INSERTS, organ.inserts); 

  if (!boardInfo.scan_validflag) { return; }
  midi_sendnrpn(0x350E, tabs.equ_bypass);
}

void sendOrganEqualizer() {
  if (!boardInfo.scan_validflag) { return; }
  DPRINTLNF("/ Send Equalizer to FPGA");
  midi_sendnrpn(0x350E, tabs.equ_bypass);
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

void sendOrganVolumes() {
  DPRINTLNF("/ Send Volumes to FPGA");
  spi_write8_scaled(SPI_UPPER_WET_LVL, preamp.upperVolumeWet, 150);
  spi_write8_scaled(SPI_LOWER_LVL, preamp.lowerVolume, 150);
  spi_write8_scaled(SPI_UPPER_DRY_LVL, preamp.upperVolumeDry, 150);
  spi_write16(SPI_PED_TO_VIB_LVL, preamp.pedalVolume); // Pedal an Vibrato Lower, über AO28
  spi_write16(SPI_PED_TO_AO28_LVL, 0); // Pedal Dry über AO28
  spi_write16(SPI_PED_TO_BYPASS_AMP, preamp.pedalVolume); // Pedal to Ext. Output & Postmix
  spi_write8_volume(SPI_MASTER_VOLUME, preamp.masterVolume);  // 72 = Master Vol I2S Multiplier
}

void sendOrganVibrato() {
  // TODO!
  spi_write8(SPI_VIB_DRY_LVL, 200); // Vibrato Dry Level auf 0..255
  spi_write8(SPI_VIB_MODWAVE_PHASE, 3); // Vibrato Modwave Phase und Noise Level
}

void sendOrganPercussion() {
  // TODO!
}

bool loadOrganModel(uint8_t organModelIdx) {
  // kopiert nur für Orgelmodell relevante Teile ins edit_array
  // liefert TRUE wenn Orgelmodell gültig (> 0) und geladen
  df_readblock(BLOCK_ORGAN_MODEL_BASE + organModelIdx, 512);  // 512 Bytes!
  if (spi_blockbuffer.byte[OFS_EDITMAGICFLAGIDX] == 0xA5
    && spi_blockbuffer.byte[OFS_PRESETSTRUCTURE] >= PRESET_VERSION) {
    DPRINTF("/ Load Organ Model #");
    DPRINTLN(organModelIdx);
    memcpy(&organModel.busbarLevels[0], spi_blockbuffer.byte + 272, 16);
    memcpy(&organModel.busbarOffsets[0], spi_blockbuffer.byte + 288, 16);
    memcpy(&organModel.earlyKeyCont, spi_blockbuffer.byte + 356, 10);
    memcpy(&organModel.tuning_set, spi_blockbuffer.byte + 385, 10);
    memcpy(&organModel.percNormLvl, spi_blockbuffer.byte + 480, 7);
    memcpy(&preamp.upperVolumeWet, spi_blockbuffer.byte + 82, 4);
    memcpy(&preamp.tonePot, spi_blockbuffer.byte + 87, 9);
    memcpy(&vibrato.preEmphasis, spi_blockbuffer.byte + 320, 16);
    sendOrganGenerator();
    uint8_t temp = (organModel.contFlex << 4) | (organModel.contDamping & 15);
    spi_write8(SPI_SCAN_CLICK, temp); 
    sendOrganVibrato();
    sendOrganVolumes();
    sendOrganEqualizer();
    return true;
  } else {
    DPRINTF("/ Invalid Organ Model #");
    DPRINTLN(organModelIdx);
    DPRINTF("/ Version byte found:");
    DPRINTLN(spi_blockbuffer.byte[OFS_PRESETSTRUCTURE], HEX);
    DPRINTF("/ Magic Flag byte found:");
    DPRINTLN(spi_blockbuffer.byte[OFS_EDITMAGICFLAGIDX], HEX);
  }
  return false;
}


void initOrgan() {
  loadOrganModel(0);
  DPRINTLNF("/ Send FIR Coeff to LC #2");
  df_send_core(LCTARGET_FIR_COEFF, BLOCK_FIR_COEFF);  // FIR Koeffizienten Horn
  fpga_send_taperset(organModel.taperset); // Taper-Set aus organ_model, Block Offset 11 (nur unterste 8 Bit übertragen)
  fpga_send_waveset(organModel.waveset);  // Waveset aus organ_model, Block Offset 16 (4 Blocks für 1 Waveset)
  fpga_send_hpfilter();
  fpga_sendLicense();
 
  sendOrganInserts();
  sendOrganSwell();
  sendOrganKeybed();

  fpga_send_upper_db();
  fpga_send_lower_db();
  fpga_send_pedal_db();

  if (!boardInfo.scan_validflag) { return; }
  midi_sendnrpn(0x3509, 115); // SAM55004 GM2 Pre-Mix Gain
  midi_sendnrpn(0x3510, 127); // SAM55004 GM2 General Master Volume
  midi_sendnrpn(0x3512, 127); // SAM55004 GM2 Master Volume

  midi_sendnrpn(0x3530, 1);   // UpperGMharm
  midi_sendnrpn(0x3560, 0);   // UpperGMlvl Layer 1
  midi_sendnrpn(0x3564, 0);   // UpperGMlvl Layer 2

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
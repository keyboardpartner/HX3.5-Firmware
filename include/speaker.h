#ifndef SPEAKER_H
#define SPEAKER_H

// #############################################################################
//
//     ######  ########  ########    ###    ##    ## ######## ########  
//    ##    ## ##     ## ##         ## ##   ##   ##  ##       ##     ## 
//    ##       ##     ## ##        ##   ##  ##  ##   ##       ##     ## 
//     ######  ########  ######   ##     ## #####    ######   ########  
//          ## ##        ##       ######### ##  ##   ##       ##   ##   
//    ##    ## ##        ##       ##     ## ##   ##  ##       ##    ##  
//     ######  ##        ######## ##     ## ##    ## ######## ##     ## 
//
// #############################################################################


// Speaker-specific definitions and functions
#include "FPGA_SPI.h"
#include "global_vars.h"
#include "FPGA_MIDI.h"

// -----------------------------------------------------------------------------
// Prototypes
// -----------------------------------------------------------------------------

void sendAmpVolume();
void sendAmpTubeCurve(uint8_t curve_pos, uint8_t curve_neg);
void sendSpeakerCtrls();

// kopiert nur für Speakermodell relevante Teile ins edit_array
// liefert TRUE wenn Speakermodell gültig (> 0) und geladen
bool loadSpeakerModel(uint8_t speakerModelIdx);

void sendSpeakerModel();

// #############################################################################

void sendAmpTubeCurve(uint8_t curve_pos, uint8_t curve_neg) {
  int16_t stepval = 0;
  int16_t slopeval = 0;
  // Positive Werte für Aufwärtssteilheit
  for (uint8_t i = 0; i < 32; i++) {
    slopeval = c_tubeampslopes[curve_pos][i]; // Auswahl der Steilheit aus Tabelle, abhängig von Kurvenstufe
    spi_blockbuffer.tubeSlope.slopevals[i] = slopeval;
    spi_blockbuffer.tubeSlope.stepvals[i] = stepval;
    stepval += slopeval; // Schrittweite für nächsten Punkt berechnen
  }
  stepval = spi_blockbuffer.tubeSlope.stepvals[31];
  for (uint8_t i = 32; i < 128; i++) {
    spi_blockbuffer.tubeSlope.slopevals[i] = 0; // letzter Wert immer 0
    spi_blockbuffer.tubeSlope.stepvals[i] = stepval;
  }
  // negative Werte für Abwärtssteilheit
  stepval = 0;
  for (uint8_t i = 255; i >= 224; i--) {
    slopeval = c_tubeampslopes[curve_neg][255-i]; // Auswahl der Steilheit aus Tabelle, abhängig von Kurvenstufe
    spi_blockbuffer.tubeSlope.slopevals[i] = slopeval;
    spi_blockbuffer.tubeSlope.stepvals[i] = stepval;
    stepval -= slopeval; // Schrittweite für nächsten Punkt berechnen
  }
  stepval = spi_blockbuffer.tubeSlope.stepvals[224];
  for (uint8_t i = 223; i >= 128; i--) {
    spi_blockbuffer.tubeSlope.slopevals[i] = 0; // letzter Wert immer 0
    spi_blockbuffer.tubeSlope.stepvals[i] = stepval;
  }
  spi_autoIncSetup(LCTARGET_TUBE_AMP_SLOPE); // for Write
  spi_send_blockbuffer(512, 16);
  spi_autoIncReset(LCTARGET_TUBE_AMP_SLOPE); // for Write Core 7, Tube Amp Slope
}


void sendAmpVolume() {
  speakerCtrl.ampGain = preamp.ampGain; // Amp Gain aus Alias holen, damit bei Gain Compensation die Korrektur in sendAmpVolume berücksichtigt wird
  spi_write8(SPI_ROTRY_INP_LVL, speakerModel.inits[4]); // Amp In Level an FPGA senden, proportional zur Amp In Volume, auf 0..127
  if (tabs.tubeAmpBypass) {
    spi_write8(SPI_AMP_OUT_LVL, 0); // Amp Out Level an FPGA senden
  } else {
    uint16_t my_word = (speakerCtrl.ampOutVol * 100) / 127 + 27; // Amp Out Level proportional zur Amp Out Volume, auf 0..127
    spi_write8_volume(SPI_AMP_IN_LVL, my_word); // Amp In Level an FPGA senden, proportional zur Amp In Volume, auf 0..127
    if(config.gainCompensation) {
        my_word = 240 - (constrain(speakerCtrl.ampGain, 0, 33) * 4 ) - (speakerCtrl.ampOutVol / 5); // Amp Out Level mit Korrektur, auf 0..127
    } else {
        my_word = 230 - (speakerCtrl.ampGain / 3); // Amp Out Level mit geringer Korrektur, auf 0..127
    }        
    spi_write8(SPI_AMP_OUT_LVL, my_word); // Amp Out Level an FPGA senden
  }
}

void adjustSpeakerSpread() {
  // Leslie Spread (für R) neu setzen, wenn sich nur die Speaker-Parameter geändert haben
  speakerModel.inits[17] = speakerModel.inits[16];
  speakerModel.inits[19] = speakerModel.inits[18];
  speakerModel.inits[21] = speakerModel.inits[20];
  speakerModel.inits[23] = speakerModel.inits[22];
  uint8_t spread_angle = (speakerCtrl.stereoSpread >> 1) + 40;
  speakerModel.phases[1] = speakerModel.phases[0] + spread_angle;  // +0..127  MAIN
  speakerModel.phases[3] = speakerModel.phases[2] + spread_angle;  // +0..127  NEAR
  speakerModel.phases[5] = speakerModel.phases[4] + spread_angle;  // +0..127  FAR
  speakerModel.phases[7] = speakerModel.phases[6] + spread_angle;  // +0..127  THROB
}

void sendSpeakerCtrls() {
  // Leslie Spread Offsets und Delays an FPGA
  // war AC_SendLeslieLiveParams in Pascal 
  uint16_t my_word;
  adjustSpeakerSpread();
  for (uint8_t i = 0; i < 8; i++) {
    spi_write8(SPI_LFO_PHASE_OFFSET_HORN_MAIN_L + i, speakerModel.phases[i]); // Leslie Spread Parameter inkl. Spread
    spi_write8(SPI_LFO_MOD_HORN_MAIN_L + i, speakerModel.inits[i + 16]);
  }
  if (speakerCtrl.balance >= 64) {
    // Rotor-Pegel reduzieren
    my_word = (speakerModel.inits[6] * (128 - speakerCtrl.balance)) / 64;
    spi_write8(SPI_ROTRY_ROTOR_LVL, my_word);   // skalierter Rotor-Anteil
    // Hornpegel konstant, unabhängig von Balance
    spi_write8(SPI_ROTRY_HORN_LVL, speakerModel.inits[5]);
  } else {
    // Horn-Pegel reduzieren
    my_word = (speakerModel.inits[5] * speakerCtrl.balance) / 64;
    spi_write8(SPI_ROTRY_HORN_LVL, my_word);
    // Rotorpegel konstant, unabhängig von Balance
    spi_write8(SPI_ROTRY_ROTOR_LVL, speakerModel.inits[6]);
  }  
  // Horn-Throb konstant, unabhängig von Balance
  my_word = (speakerModel.inits[22] * speakerCtrl.throb) / 128; // Throb Horn L
  spi_write8(SPI_LFO_MOD_HORN_THROB_L, my_word);  // Rotor-Throb konstant, unabhängig von Balance
  my_word = (speakerModel.inits[27] * speakerCtrl.throb) / 128; // Throb Rotor
  spi_write8(SPI_LFO_MOD_ROTOR_THROB, my_word);  // Rotor
  sendAmpTubeCurve(speakerCtrl.tubeSlopePos, speakerCtrl.tubeSlopeNeg);
  sendAmpVolume();
}

void sendSpeakerModel() {
  // Leslie Equalizer, Offsets und Delays an FPGA
  adjustSpeakerSpread();
  // edit_LeslieInpLvl wird in AC_SendVolumes korrigiert und gesendet
  uint8_t param_idx = 4;
  DVPRINTF("/ Speaker Inits to FPGA: ");
  for (uint8_t spi = SPI_ROTRY_INP_LVL; spi <= SPI_HORN_FIR_FILTER_ENABLE; spi++) {
    spi_write8(spi, speakerModel.inits[param_idx]);
    DVPRINT(speakerModel.inits[param_idx]);
    DVPRINTF(", ");
    param_idx++;
  }  
  param_idx = 0;
  DVPRINTLN();
  DVPRINTF("/ Speaker Phases to FPGA: ");
  for (uint8_t spi = SPI_LFO_PHASE_OFFSET_HORN_MAIN_L; spi <= SPI_LFO_PHASE_OFFSET_ROTOR_THROB; spi++) {
    spi_write8(spi, speakerModel.phases[param_idx]);
    DVPRINT(speakerModel.phases[param_idx]);
    DVPRINTF(", ");
    param_idx++;
  }  
  DVPRINTLN();
  sendSpeakerCtrls();
  spi_write8(SPI_SPEED_HORN, speakerCtrl.hornSpeed);  // Horn
  spi_write8(SPI_SPEED_ROTOR, speakerCtrl.rotorSpeed); // Rotor
}

bool loadSpeakerModel(uint8_t speakerModelIdx) {
  // kopiert nur für Rotary-Modell relevante Teile ins edit_array
  // liefert TRUE wenn Rotary-Modell gültig (> 0) und geladen
  df_readblock(BLOCK_SPEAKER_MODEL_BASE, 512);  // 512 Bytes bis Magic Flag
  if (spi_blockbuffer.byte[OFS_EDITMAGICFLAGIDX] == 0xAA
    && spi_blockbuffer.byte[OFS_PRESETSTRUCTURE] >= PRESET_VERSION) {
    DPRINTF("/ Load Speaker Model #");
    DPRINTLN(speakerModelIdx);
    memcpy(speakerModel.inits, spi_blockbuffer.byte, 32);
    memcpy(speakerModel.phases, spi_blockbuffer.byte + 0x30, 16);
    memcpy(speakerModel.ctrl, spi_blockbuffer.byte + 0x40, 16);
    sendSpeakerModel();
    return true;
  } else {
    DPRINTF("/ Invalid Speaker Model #");
    DPRINTLN(speakerModelIdx);
  }
  return false;
}

#endif
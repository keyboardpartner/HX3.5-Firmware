#ifndef SPEAKER_H
#define SPEAKER_H

// Speaker-specific definitions and functions
#include "FPGA_SPI.h"
#include "global_vars.h"
#include "FPGA_MIDI.h"


void setSpeaker() {

}

void setAmpVolume() {

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
        return true;
    } else {
        DPRINTF("/ Invalid Speaker Model #");
        DPRINTLN(speakerModelIdx);
    }
    return false;
}

void sendSpeakerModel() {
    // Leslie Equalizer, Offsets und Delays an FPGA
    speakerModel.inits[17] = speakerModel.inits[16];
    speakerModel.inits[19] = speakerModel.inits[18];
    speakerModel.inits[21] = speakerModel.inits[20];
    speakerModel.inits[23] = speakerModel.inits[22];
    // edit_LeslieInpLvl wird in AC_SendVolumes korrigiert und gesendet
    uint8_t param_idx = 5;
    DVPRINTF("/ Speaker Inits to FPGA: ");
    for (uint8_t i = SPI_ROTRY_HORN_LVL; i <= SPI_HORN_FIR_FILTER_ENABLE; i++) {
        spi_write8(i, speakerModel.inits[param_idx]);
        DVPRINT(speakerModel.inits[param_idx]);
        DVPRINTF(", ");
        param_idx++;
    }  
    param_idx = 0;
    DVPRINTLN();
    DVPRINTF("/ Speaker Phases to FPGA: ");
    for (uint8_t i = SPI_LFO_PHASE_OFFSET_HORN_MAIN_L; i <= SPI_LFO_PHASE_OFFSET_ROTOR_THROB; i++) {
        spi_write8(i, speakerModel.phases[param_idx]);
        DVPRINT(speakerModel.phases[param_idx]);
        DVPRINTF(", ");
        param_idx++;
    }  
    DVPRINTLN();
}

#endif
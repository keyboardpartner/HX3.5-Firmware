#ifndef FILES_H
#define FILES_H

#include "FPGA_hilevel.h"
#include "FPGA_SPI.h"
#include "global_vars.h"
#include <SdFat.h>

SdFat SD;
#define SD_CS_PIN PIN_PB4

// 1 for FAT16/FAT32, 2 for exFAT, 3 for FAT16/FAT32 and exFAT.
#define SD_FAT_TYPE 1

#if SD_FAT_TYPE == 0
  SdFat sd;
  File dir;
  File file;
#elif SD_FAT_TYPE == 1
  SdFat32 sd;
  File32 dir;
  File32 file;
#elif SD_FAT_TYPE == 2
  SdExFat sd;
  ExFile dir;
  ExFile file;
#elif SD_FAT_TYPE == 3
  SdFs sd;
  FsFile dir;
  FsFile file;
#endif  // SD_FAT_TYPE

// Try max SPI clock for an SD. Reduce SPI_CLOCK if errors occur.
#define SPI_CLOCK SD_SCK_MHZ(8)
#define SD_CONFIG SdSpiConfig(SD_CS_PIN, SHARED_SPI, SPI_CLOCK)

bool sdReady = false;

typedef struct {
  char filename[16];
  uint16_t block_number; // Block-Nummer im DataFlash
  uint8_t lctarget;     // 255 = none
} updateFileType;

const updateFileType filelist[32] PROGMEM = {
  {"hx3_main.bin", BLOCK_FPGA, 255},
  {"firmware.bin", BLOCK_FIRMWARE, 255},
  {"scan.dat", BLOCK_SCAN, LCTARGET_SCAN_DRIVER},
  {"taper1.dat", BLOCK_TAPER_0, LCTARGET_TAPERING},
  {"taper2.dat", BLOCK_TAPER_1, LCTARGET_TAPERING},
  {"taper3.dat", BLOCK_TAPER_2, LCTARGET_TAPERING},
  {"taper4.dat", BLOCK_TAPER_3, LCTARGET_TAPERING},
  {"waveset0.bin", BLOCK_WAVESET_0, LCTARGET_WAVESET},
  {"waveset1.bin", BLOCK_WAVESET_1, LCTARGET_WAVESET},
  {"waveset2.bin", BLOCK_WAVESET_2, LCTARGET_WAVESET},
  {"waveset3.bin", BLOCK_WAVESET_3, LCTARGET_WAVESET},
  {"waveset4.bin", BLOCK_WAVESET_4, LCTARGET_WAVESET},
  {"waveset5.bin", BLOCK_WAVESET_5, LCTARGET_WAVESET},
  {"waveset6.bin", BLOCK_WAVESET_6, LCTARGET_WAVESET},
  {"waveset7.bin", BLOCK_WAVESET_7, LCTARGET_WAVESET},
  {"fir.dat", BLOCK_FIR_COEFF, LCTARGET_FIR_COEFF},
  {"voices.dat", BLOCK_VOICE, 255}, // kein LC-Ziel, wird von Firmware verarbeitet
  {"organs.dat", BLOCK_ORGAN_MODEL_BASE, 255},
  {"speakers.dat", BLOCK_SPEAKER_MODEL_BASE, 255},
  {"presets.dat", BLOCK_PRESET_BASE, 255},
  {"file20.txt", 0, 255},
  {"file21.txt", 0, 255},
  {"file22.txt", 0, 255},
  {"file23.txt", 0, 255},
  {"file24.txt", 0, 255},
  {"file25.txt", 0, 255},
  {"file26.txt", 0, 255},
  {"file27.txt", 0, 255},
  {"file28.txt", 0, 255},
  {"file29.txt", 0, 255},
  {"file30.txt", 0, 255},
  {"file31.txt", 0, 255},
};

updateFileType getFileItem(uint8_t idx) {
  updateFileType item;
  memcpy_P (&item, &filelist[idx], sizeof item);
  return item;
}

void listCardDirectory() {
  DPRINTLNF("/ SD init directory:");
  if (!dir.open("/")) {
    DPRINTLNF("/ dir.open failed!");
    return;
  }
  // Open next file in root.
  // Warning, openNext starts at the current position of dir so a
  // rewind may be necessary in your application.
  while (file.openNext(&dir, O_RDONLY)) {
    Serial.write('/');
    file.printFileSize(&Serial);
    Serial.write(' ');
    file.printModifyDateTime(&Serial);
    Serial.write(' ');
    file.printName(&Serial);
    if (file.isDir()) {
      // Indicate a directory.
      Serial.write('/');
    }
    Serial.println();
    file.close();
  }
  if (dir.getError()) {
    Serial.println("/ openNext failed");
  } else {
    Serial.println("/ Done!");
  }
  dir.close();
}

void initSDcard() {
  // Initialize the SD.
  if (!sd.begin(SD_CONFIG)) {
    DPRINTLNF("/ SD init failed or no card");
    sdReady = false;
  } else {
    sdReady = true;
  }
}

void sendSDcore(uint8_t fileIdx, bool to_df) {
  // Sende einen Core oder andere Daten von der SD-Karte an ein LC-Ziel, 
  // basierend auf der Datei- und Zielzuordnung in filelist
  updateFileType fileItem = getFileItem(fileIdx); // Datensatz aus Flash-Array holen
  if (!sdReady) {
    DPRINTLNF("/ SD card not ready");
    return;
  }  
  if (!sd.exists(fileItem.filename)) {
    DPRINTF("/ File not found: ");
    DPRINTLN(fileItem.filename);
    return;
  }
  if (!file.open(fileItem.filename, O_RDONLY)) {
    DPRINTF("/ Error opening file: ");
    DPRINTLN(fileItem.filename);
    return;
  }  

  uint16_t block_size, block_count, target_count_per_block;
  uint8_t target_datawidth = 1; // 8 Bit pro Datenwort
  uint16_t block_number = fileItem.block_number;
  if ((fileItem.lctarget == 255) || to_df) {
    // Firmware oder FPGA-Bitstream, nur an DF
    block_size = 4096;
    block_count = 999; // max. Anzahl Blöcke, wird durch Dateigröße begrenzt
    target_count_per_block = 4096; // 4096 Bytes pro Block
  } else {
    if (c_target_blockcount[fileItem.lctarget] == 0) return; // nichts zu tun
    block_size = c_target_count_per_block[fileItem.lctarget] * (c_target_datawidth[fileItem.lctarget]);
    block_count = c_target_blockcount[fileItem.lctarget];
    target_count_per_block = c_target_count_per_block[fileItem.lctarget];
    target_datawidth = c_target_datawidth[fileItem.lctarget];
  }
 
  DPRINTF("/ Send file: ");
  DPRINT(fileItem.filename);
  DPRINTF(" to LC #");
  DPRINTLN(fileItem.lctarget);
         
  // PicoBlaze-, FIR- oder Tapering-Core #core von SD laden und an AutoInc-Reg senden, 4096 Bytes = 1 BlockRAM
  file.rewind(); // sicherstellen, dass wir am Anfang der Datei lesen

  if (!to_df) spi_autoIncSetup(fileItem.lctarget); // for Write
  else df_unprotect(); // for DataFlash write

  for (uint16_t block_idx = 0; block_idx < block_count; block_idx++) {
    int16_t bytesRead = file.read(spi_blockbuffer.byte, block_size); // Lese bis zu 4096 Bytes aus der Datei in den BlockBuffer
    DPRINTF("/ Bytes read: ");
    DPRINTLN(bytesRead);
    DPRINTF("/ Send Block #");
    DPRINT(block_number + block_idx);
    bytesRead = (bytesRead > 0) ? ((bytesRead + 255) & (uint16_t)~255) : 0; // auf nächstes Vielfaches von 256 aufrunden, wenn > 0
    if (to_df) {
      if (bytesRead > 0) {
        lcd.setCursor(13, 1);
        lcd.print(block_number + block_idx);
        DPRINTF(" to DataFlash");
        df_eraseblock_4k(block_number + block_idx);
        df_writeblock(block_number + block_idx, bytesRead);
        df_verifyblock_4k(block_number + block_idx, bytesRead);
        DPRINTLN();
      } else {
        DPRINTLNF(" - file ended");
      }
    } else {
      spi_send_blockbuffer(target_count_per_block, target_datawidth, true);
    }
    // stop at end of file, even if block was not full
    if (bytesRead == 0) {
      break;
    }
  }

  if (!to_df) spi_autoIncReset(fileItem.lctarget); 
  else df_protect();

  file.close();
}
#endif  // FILES_H
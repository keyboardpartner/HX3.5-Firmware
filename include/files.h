#ifndef FILES_H
#define FILES_H

#include <SdFat.h>
#include "FPGA_hilevel.h"
#include "FPGA_SPI.h"
#include "global_vars.h"
#include "organ.h"

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

#define LC_NONE 255

#define FILE_FPGA 0
#define FILE_FIRMWARE 1
#define FILE_SCAN_DRIVER 2
#define FILE_TAPER_0 3
#define FILE_TAPER_1 4
#define FILE_TAPER_2 5
#define FILE_TAPER_3 6
#define FILE_WAVESET_0 7
#define FILE_WAVESET_1 8
#define FILE_WAVESET_2 9
#define FILE_WAVESET_3 10
#define FILE_WAVESET_4 11
#define FILE_WAVESET_5 12
#define FILE_WAVESET_6 13
#define FILE_WAVESET_7 14
#define FILE_FIR_COEFF 15
#define FILE_VOICE 16
#define FILE_ORGAN_MODEL 17
#define FILE_SPEAKER_MODEL 18
#define FILE_PRESET 19
#define FILE_DEFAULTS 20


const updateFileType filelist[32] PROGMEM = {
  {"hx3_main.bin", BLOCK_FPGA, LC_NONE},  // 0: FPGA-Bitstream, wird direkt an FPGA gesendet
  {"firmware.bin", BLOCK_FIRMWARE, LC_NONE},  // 1: Firmware, wird direkt von der MCU verarbeitet
  {"scan.dat", BLOCK_SCAN, LCTARGET_SCAN_DRIVER},  // 2: Scantabellen
  {"taper1.dat", BLOCK_TAPER_0, LCTARGET_TAPERING}, //3
  {"taper2.dat", BLOCK_TAPER_1, LCTARGET_TAPERING}, //4
  {"taper3.dat", BLOCK_TAPER_2, LCTARGET_TAPERING}, //5
  {"taper4.dat", BLOCK_TAPER_3, LCTARGET_TAPERING}, //6
  {"waveset0.bin", BLOCK_WAVESET_0, LCTARGET_WAVESET}, // 7
  {"waveset1.bin", BLOCK_WAVESET_1, LCTARGET_WAVESET}, // 8
  {"waveset2.bin", BLOCK_WAVESET_2, LCTARGET_WAVESET}, // 9
  {"waveset3.bin", BLOCK_WAVESET_3, LCTARGET_WAVESET}, // 10
  {"waveset4.bin", BLOCK_WAVESET_4, LCTARGET_WAVESET}, // 11
  {"waveset5.bin", BLOCK_WAVESET_5, LCTARGET_WAVESET}, // 12
  {"waveset6.bin", BLOCK_WAVESET_6, LCTARGET_WAVESET}, // 13
  {"waveset7.bin", BLOCK_WAVESET_7, LCTARGET_WAVESET}, // 14
  {"fir.dat", BLOCK_FIR_COEFF, LCTARGET_FIR_COEFF}, // 15
  {"voices.dat", BLOCK_VOICE, LC_NONE}, // 16: kein LC-Ziel, wird von Firmware verarbeitet
  {"organs.dat", BLOCK_ORGAN_MODEL_BASE, LC_NONE}, // 17
  {"speakers.dat", BLOCK_SPEAKER_MODEL_BASE, LC_NONE}, // 18
  {"presets.dat", BLOCK_PRESET_BASE, LC_NONE}, // 19
  {"defaults.dat", BLOCK_DEFAULTS, LC_NONE}, // 20
  {"file21.txt", 0, LC_NONE}, // 21
  {"file22.txt", 0, LC_NONE}, // 22
  {"file23.txt", 0, LC_NONE}, // 23
  {"file24.txt", 0, LC_NONE}, // 24
  {"file25.txt", 0, LC_NONE}, // 25
  {"file26.txt", 0, LC_NONE}, // 26
  {"file27.txt", 0, LC_NONE}, // 27
  {"file28.txt", 0, LC_NONE}, // 28
  {"file29.txt", 0, LC_NONE}, // 29
  {"file30.txt", 0, LC_NONE}, // 30
  {"file31.txt", 0, LC_NONE}, // 31
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

bool sendSDcore(uint8_t fileIdx, bool to_df) {
  // Sende einen Core oder andere Daten von der SD-Karte an ein LC-Ziel oder speichert sie in der DataFlash,
  // basierend auf der Datei- und Zielzuordnung in filelist
  updateFileType fileItem = getFileItem(fileIdx); // Datensatz aus Flash-Array holen
  if (!sdReady) {
    DPRINTLNF("/ SD card not ready");
    return false;
  }  
  if (!sd.exists(fileItem.filename)) {
    DPRINTF("/ File not found: ");
    DPRINTLN(fileItem.filename);
    return false;
  }
  if (!file.open(fileItem.filename, O_RDONLY)) {
    DPRINTF("/ Error opening file: ");
    DPRINTLN(fileItem.filename);
    return false;
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
    if (c_target_blockcount[fileItem.lctarget] == 0) return true; // nichts zu tun
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
    // auf nächstes Vielfaches von 256 aufrunden, wenn > 0
    bytesRead = (bytesRead > 0) ? ((bytesRead + 255) & (uint16_t)~255) : 0; 
    if (to_df) {
      if (bytesRead > 0) {
        lcd.setCursor(13, 1);
        lcd.print(block_number + block_idx);
        DPRINTF(" to DataFlash");
        df_eraseblock_4k(block_number + block_idx);
        df_writeblock(block_number + block_idx, bytesRead);
        uint8_t retry = 3; // max. 3 Versuche, um Block korrekt zu schreiben
        while (!df_verifyblock_4k(block_number + block_idx, bytesRead) && (retry > 0)) {
          DPRINTF(" (retry)");
          df_unprotect();
          df_eraseblock_4k(block_number + block_idx);
          df_writeblock(block_number + block_idx, bytesRead);
          retry--;
        }
        DPRINTLN();
      } else {
        DPRINTLNF(" - file ended");
      }
    } else {
      spi_send_blockbuffer(target_count_per_block, target_datawidth);
    }
    // stop at end of file, even if block was not full
    if (bytesRead == 0) {
      break;
    }
  }

  if (!to_df) spi_autoIncReset(fileItem.lctarget); 
  else df_protect();

  file.close();
  return true;
}

// -----------------------------------------------------------------------------
// Funktionen ohne Parameter für EditAction
// -----------------------------------------------------------------------------

void sendCoreAndDisplay(uint8_t fileIdx, bool to_df) {
  updateFileType fileItem = getFileItem(fileIdx);
  DPRINTF("/ Flashing file: ");
  DPRINTLN(fileItem.filename);
  lcd.setCursor(0, 1);
  lcd.print(fileItem.filename);
  lcd.clearEOL();
  lcd.setCursor(0, 1);
  if (sendSDcore(fileIdx, true)) { // scan.dat flashen
    // Erfolgreich geflasht
    lcd.print(F("Done."));
    lcd.clearEOL();
  } else {
    // Fehler beim Flashen
    delay(500); // Kurze Pause, damit Filename lesbar bleibt
    lcd.print(F("Not found!"));
    lcd.clearEOL();
    delay(1000);
  }
}

void loadScanDriver() {
  if (!sdReady) initSDcard();
  sendCoreAndDisplay(FILE_SCAN_DRIVER, false); // scan.dat an Scan Driver senden
}

void flashScanDriver() {
  if (!sdReady) initSDcard();
  sendCoreAndDisplay(FILE_SCAN_DRIVER, true); // scan.dat flashen
}

void loadTapering() {
  if (!sdReady) initSDcard();
  for (uint8_t i = FILE_TAPER_0; i <= FILE_TAPER_3; i++) {
    sendCoreAndDisplay(i, true); // taperX.dat an Tapering senden
  }
}

void loadWavesets() {
  if (!sdReady) initSDcard();
  for (uint8_t i = FILE_WAVESET_0; i <= FILE_WAVESET_7; i++) {
    sendCoreAndDisplay(i, true); // wavesetX.dat an Waveset senden
  }
}

void flashFPGA() {
  if (!sdReady) initSDcard();
  sendCoreAndDisplay(FILE_FPGA, true); // hx3_main.bin flashen
  organReset(); // FPGA neu laden, damit neuer Bitstream aktiv wird
}

void flashOther() {
  if (!sdReady) initSDcard();
  for (uint8_t i = FILE_TAPER_0; i <= FILE_DEFAULTS; i++) {
    sendCoreAndDisplay(i, true); // taperX.dat an Tapering senden
  }
}

void sdCardInfo() {
  initSDcard();
  lcd.setCursor(0, 1);
  DPRINT("/ SD Card Type: ");
  switch (sd.card()->type()) {
    case SD_CARD_TYPE_SD1:
      DPRINTF("SD1, ");
      lcd.print("SD1, ");
      break;
    case SD_CARD_TYPE_SD2:
      DPRINTF("SD2, ");
      lcd.print("SD2, ");
      break;
    case SD_CARD_TYPE_SDHC:
      DPRINT("SDHC, ");
      lcd.print("SDHC, ");
      break;
    default:
      DPRINTF("Unknown, ");
      lcd.print("Unknown,");
  }
  uint32_t sizeMB = (sd.card()->sectorCount()) / 2048; // Total blocks, Size in MB
  DPRINT(sizeMB);
  DPRINTLNF(" MByte");
  lcd.print(sizeMB);
  lcd.print(" MByte");
  lcd.clearEOL();
  listCardDirectory();
}

#endif  // FILES_H
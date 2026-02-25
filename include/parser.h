#ifndef PARSER_H
#define PARSER_H

#include <Arduino.h>
#include <ctype.h>
#include "FPGA_SPI.h"
#include "global_vars.h"

typedef struct {
  const char* mnemonic;
  uint16_t index;
} MnemonicPair;

const MnemonicPair mnemonicPairs[]  = {
    {"STR", 255},  // Status Request 255
    {"IDN", 254},  // Identify Version number 254
    {"VAL", 0},  // 0..9999
    {"VER", 3},
    {"LCO", 240},
    {"LCE", 241}, 
    {"WEN", 250},  // 250 Write enable
    {"ERC", 251},  // 251 ErrCount seit letztem Reset
    {"VAL", 0},  // 0..9999
    {"EDT", 1000},  // 1000 ff.  alle Edit-Vars
    {"COR", 7000},  // 7000 Core Load, z.B. COR 192=firmware.bin
    {"CFG", 8000},  // 8000 FPGA Config from Flash
    {"UPD", 8200},  // 8200 Update from SD
    {"SCI", 8500},  // 8500 Scan Core Info, 0=ID, 1=Revision
    {"RCB", 8600},  // 8600 4K-Block überspezielles Protokoll empfangen
    {"WFB", 8601},  // 8601 4K-Block in DataFlash speichern, Param = Blocknummer abs.
    {"DFI", 8800},  // 8800 DF Init Presets
    {"RCS", 8900},  // 8900 Receive Binary Stream (+Core #)
    {"FIN", 9940},  // 9940 Finalisieren, DF Preset INIT
    {"KEY", 9950},  // 9950 DNA Key Eingabe 0 und 1
    {"DIR", 9960},  // 9960 List SD Card Directory
    {"EPS", 9970},  // 9970 EEPROM Save to DF
    {"EPR", 9980},  // 9980 EEPROM Restore from DF
    {"DMP", 9989},  // 9989
    {"USR", 9990},  // 9990 User Name
    {"RPE", 9997},  // 9997 Reset User Interface, DB/Peripherals and ADC/Btn Remap
    {"RLD", 9998},  // 9998 Reload All
    {"RST", 9999},  // 9999 System Reset
    {"NOP", 0},
};

// -----------------------------------------------------------------------------
// Parser: Wert holen
// -----------------------------------------------------------------------------

void parseGetValue(uint16_t index) {
  // Hier können die Werte für die GET-Kommandos zurückgegeben werden, z.B. über Serial.print()
  if (index <=255) {
    uint32_t spi_result = spi_read32(index);
    Serial.println(spi_result);
  } else if (index >= 1000 && index < 1256) {
    uint8_t idx8 = index - 1000;
    if (idx8 < 64) {
      Serial.println(drawbars.upper[idx8]);
    }

  } else {
    Serial.print("/ Invalid index: ");
    Serial.println(index);
  }
}

void parseGetValueMnemonic(const char* mnemonic, uint8_t offset) {
  // convert mnemonic to uppercase for case-insensitive comparison
  char upperMnemonic[16];
  size_t i;
  for (i = 0; i < sizeof(upperMnemonic) - 1 && mnemonic[i] != '\0'; i++) {
    upperMnemonic[i] = toupper(mnemonic[i]);
  }
  upperMnemonic[i] = '\0';
  // Search for the mnemonic in the mnemonicPairs array and call parseGetValue with the corresponding index
  for (size_t i = 0; i < sizeof(mnemonicPairs) / sizeof(MnemonicPair); i++) {
    if (strcmp(upperMnemonic, mnemonicPairs[i].mnemonic) == 0) {
      parseGetValue(mnemonicPairs[i].index + offset);
      return;
    }
  }
  Serial.println("/ Invalid mnemonic");
}

// -----------------------------------------------------------------------------
// Parser: Wert setzen
// -----------------------------------------------------------------------------

void parseSetValue(uint16_t index, uint16_t value) {
  // Hier können die Werte für die SET-Kommandos gesetzt werden
  if (index <=255) {
    spi_write32(index, value);
  } else if (index >= 1000 && index < 1256) {
    uint8_t idx8 = index - 1000;
    if (idx8 < 64) {
      drawbars.upper[idx8] = (uint8_t)value;
    }
  }
}

void parseSetValueMnemonic(const char* mnemonic, uint8_t offset, uint16_t value) {
  // convert mnemonic to uppercase for case-insensitive comparison
  char upperMnemonic[16];
  size_t i;
  for (i = 0; i < sizeof(upperMnemonic) - 1 && mnemonic[i] != '\0'; i++) {
    upperMnemonic[i] = toupper(mnemonic[i]);
  }
  upperMnemonic[i] = '\0';
  // Search for the mnemonic in the mnemonicPairs array and call parseSetValue with the corresponding index
  for (size_t i = 0; i < sizeof(mnemonicPairs) / sizeof(MnemonicPair); i++) {
    if (strcmp(upperMnemonic, mnemonicPairs[i].mnemonic) == 0) {
      parseSetValue(mnemonicPairs[i].index + offset, value);
      return;
    }
  }
  Serial.println("/ Invalid mnemonic");
}

typedef struct {
  char firstMnemonic[8]; // Optional: Ein kurzer String zur Identifikation des Kommandos
  char secondMnemonic[16]; // Optional: Ein kurzer String zur Identifikation des Wertes
  uint16_t first; // Erster Wert, z.B. Index oder Parameter
  uint8_t first_offset; // Optional: Offset für den ersten Wert wenn Mnemonic genutzt wird, z.B. "EDT 5 = 1234" könnte Index 1005 ansprechen
  uint16_t second; // Optional: Zweiter Wert, z.B. Wert zum Setzen
  bool firstIsMnemonic; // Gibt an, ob der erste Wert als Mnemonic interpretiert werden soll
  bool secondIsMnemonic; // Gibt an, ob der zweite Wert als Mnemonic interpretiert werden soll
  bool hasSecond;
} ParseResult;

ParseResult parseCommand(const char* input) {
  ParseResult result = {{0}, {0}, 0, 0, 0, false, false, false};
  if (input == NULL || input[0] == '\0') {
    return result;
  }
  int index = 0;
  // Skip leading whitespace
  while (input[index] == ' ' || input[index] == '\t') {
    index++;
  }
  // Parse first value (number or mnemonic)
  if (isdigit(input[index])) {
    // Parse as number
    uint16_t firstNum = 0;
    while (input[index] != '\0' && isdigit(input[index])) {
      firstNum = firstNum * 10 + (input[index] - '0');
      index++;
    }
    result.first = firstNum;
    result.firstIsMnemonic = false;
  } else if (isalpha(input[index]) || input[index] == '_') {
    // Parse as mnemonic
    int mnemonicIndex = 0;
    while (input[index] != '\0' && 
           (isalnum(input[index]) || input[index] == '_') &&
           mnemonicIndex < sizeof(result.firstMnemonic) - 1) {
      result.firstMnemonic[mnemonicIndex++] = input[index++];
    }
    result.firstMnemonic[mnemonicIndex] = '\0';
    result.firstIsMnemonic = true;
    
    // Skip whitespace after mnemonic
    while (input[index] == ' ' || input[index] == '\t') {
      index++;
    }
    
    // Check for optional offset (number after mnemonic, e.g., "EDT 5")
    if (isdigit(input[index])) {
      uint8_t offsetNum = 0;
      while (input[index] != '\0' && isdigit(input[index])) {
        offsetNum = offsetNum * 10 + (input[index] - '0');
        index++;
      }
      result.first_offset = offsetNum;
    }
  }
  
  // Skip whitespace before delimiter
  while (input[index] == ' ' || input[index] == '\t') {
    index++;
  }
  
  // Check for delimiter '='
  if (input[index] == '=') {
    index++;
    result.hasSecond = true;
    
    // Skip whitespace after delimiter
    while (input[index] == ' ' || input[index] == '\t') {
      index++;
    }
    
    // Parse second value (number or mnemonic)
    if (isdigit(input[index])) {
      // Parse as number
      uint16_t secondNum = 0;
      while (input[index] != '\0' && isdigit(input[index])) {
        secondNum = secondNum * 10 + (input[index] - '0');
        index++;
      }
      result.second = secondNum;
      result.secondIsMnemonic = false;
    } else if (isalpha(input[index]) || input[index] == '_') {
      // Parse as mnemonic
      int mnemonicIndex = 0;
      while (input[index] != '\0' && 
             (isalnum(input[index]) || input[index] == '_') &&
             mnemonicIndex < sizeof(result.secondMnemonic) - 1) {
        result.secondMnemonic[mnemonicIndex++] = input[index++];
      }
      result.secondMnemonic[mnemonicIndex] = '\0';
      result.secondIsMnemonic = true;
    }
  }
  return result;
}


void checkSerialCommand() {
  static char buffer[64] = {0};
  static int bufferIndex = 0;
  ParseResult result = {{0}, {0}, 0, 0, 0, false, false, false};
  
  while (Serial.available()) {
    char c = Serial.read();
    if (c == 0x1B) { // Binärmodus starten
      bufferIndex = 0;
      buffer[0] = '\0';
      Serial.println("/ Command input cancelled");
      Serial.write('>'); // Show prompt for next command
      return;
    }
    if (c == '\n' || c == '\r') {
      if (bufferIndex > 0) {
        buffer[bufferIndex] = '\0';
        result = parseCommand(buffer);
        bufferIndex = 0;
        if (result.hasSecond) {
          if (result.firstIsMnemonic) {
            // Handle first value as mnemonic with optional offset
            parseSetValueMnemonic(result.firstMnemonic, result.first_offset, result.second);
          } else {
            parseSetValue(result.first, result.second);
          }
        } else {
          if (result.firstIsMnemonic) {
            // Handle first value as mnemonic with optional offset
            parseGetValueMnemonic(result.firstMnemonic, result.first_offset);
          } else {
            parseGetValue(result.first);
          }
        }
        Serial.write('>'); // Show prompt for next command
      }
      return;
    }
    else if (c == 127 || c == '\b') {  // DEL or backspace
      if (bufferIndex > 0) {
        bufferIndex--;
        buffer[bufferIndex] = '\0';
      }
    }
    else if (bufferIndex < sizeof(buffer) - 1) {
      buffer[bufferIndex++] = c;
    }
  }
}
#endif // PARSER_H
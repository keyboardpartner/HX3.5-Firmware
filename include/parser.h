// filepath: e:\Dropbox\HOAX_35\HX3.5-Firmware\include\parser.h
#ifndef PARSER_H
#define PARSER_H

#include <Arduino.h>
#include <ctype.h>
#include "FPGA_SPI.h"
#include "global_vars.h"

void parseGetValue(uint16_t index) {
  // Hier können die Werte für die GET-Kommandos zurückgegeben werden, z.B. über Serial.print()
  // Beispiel: Serial.print(getUpperDbValue(index));
  if (index <=255) {
    uint32_t spi_result = spi_read32(index);
    Serial.println(spi_result);
    // Beispiel: Serial.print(getUpperDbValue(index));
  } else {
    Serial.println("Invalid index");
  }
}

void parseSetValue(uint16_t index, uint16_t value) {
  // Hier können die Werte für die SET-Kommandos gesetzt werden, z.B. setUpperDbValue(index, value);
  // Beispiel: setUpperDbValue(index, value);
}

typedef struct {
  uint16_t first;
  uint16_t second;
  bool hasSecond;
} ParseResult;

ParseResult parseCommand(const char* input) {
  ParseResult result = {0, 0, false};
  if (input == NULL || input[0] == '\0') {
    return result;
  }
  // Parse first number
  uint16_t firstNum = 0;
  int index = 0;
  while (input[index] != '\0' && isdigit(input[index])) {
    firstNum = firstNum * 10 + (input[index] - '0');
    index++;
  }
  result.first = firstNum;
  // Check for delimiter '='
  if (input[index] == '=') {
    index++;
    uint16_t secondNum = 0;
    // Parse second number
    while (input[index] != '\0' && isdigit(input[index])) {
      secondNum = secondNum * 10 + (input[index] - '0');
      index++;
    } 
    result.second = secondNum;
    result.hasSecond = true;
  }
  return result;
}

void checkSerialCommand() {
  static char buffer[64] = {0};
  static int bufferIndex = 0;
  ParseResult result = {0, 0, false};
  
  while (Serial.available()) {
    char c = Serial.read();
    
    if (c == '\n' || c == '\r') {
      if (bufferIndex > 0) {
        buffer[bufferIndex] = '\0';
        result = parseCommand(buffer);
        bufferIndex = 0;
        if (result.hasSecond) {
          parseSetValue(result.first, result.second);
        } else {
          parseGetValue(result.first);
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
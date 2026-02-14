// #############################################################################
//
//     ####### ######   #####     #
//     #       #     # #     #   # #
//     #       #     # #        #   #
//     #####   ######  #  #### #     #
//     #       #       #     # #######
//     #       #       #     # #     #
//     #       #        #####  #     #
//
// #############################################################################

// FPGA LOWLEVEL-FUNKTIONEN

unit fpga_if;

interface
uses var_def, const_def;
uses eeprom_def;

  procedure LED_timer50;
  procedure LED_timer150;
  procedure LED_timer250;
  procedure LED_timer1000;
  procedure LED_blink(my_blinks: Byte);

  procedure MemLED(my_memled: boolean);

  procedure SendFPGA8;
  procedure SendFPGA16;
  procedure SendFPGA32;

  function ReceiveFPGA(const myreg:byte): LongInt;
  procedure SendByteToFPGA(const myparam: byte; const myreg:byte);
  // procedure SPI_fpga_send_byte(const myreg:byte; const myparam: byte); // Kompatibiltät zu HX3.6

  procedure SendDoubledByteToFPGA(const myparam: byte; const myreg:byte);
  procedure SendScaledByteToFPGA(const myparam: byte; const myreg, myscale: byte);

  procedure SendVolumeByteToFPGA(const myparam: byte; const myreg:byte);
  procedure SendVolumeByteLogToFPGA(const myparam: byte; const myreg:byte);

  procedure SendWordToFPGA(const myparam: word; const myreg:byte);
  procedure SendLongToFPGA(const myparam: LongInt; const myreg:byte);

  procedure FI_AutoIncSetup(my_target: byte);
  procedure FI_AutoIncReset(my_target: byte);
  procedure FI_SendBlockBuffer(count: Word; width: byte);

  procedure FI_FPGAconfig(force_init: Boolean);
  procedure FI_GetScanCoreInfo;

const
  b_INT2:      byte = 2; // INT2 ausgel�st vom FPGA
  c_PROG:      byte = 6; // InOut Prog-Leitung FPGA Configuration
  c_DONE:      byte = 7; // Input Done-Leitung FPGA Configuration

var
{$PData}
  F_FIFO_empty[@PinB, b_INT2]: bit;    // F_INT, hier ein Flag
  FPGA_PROG[@PortC, c_PROG]: bit;   // Prog-Leitung FPGA Configuration
  FPGA_DONE[@PinC, c_DONE]: bit;    // Done-Leitung FPGA Configuration

{$IData}
  FPGAreg        : word;   // FPGA-Registerauswahl mit Write Enable Bit 15
  FPGA_OK, FPGA_UpToDate: boolean;
  FPGAsendLong, FPGAreceiveLong: LongInt;  // FPGA-Registerwert Langwort

  FPGAsendLong0[@FPGAsendLong+0]: byte;
  FPGAsendLong1[@FPGAsendLong+1]: byte;
  FPGAsendLong2[@FPGAsendLong+2]: byte;
  FPGAsendLong3[@FPGAsendLong+3]: byte;

  FPGAreceiveLong0[@FPGAreceiveLong+0]: byte;
  FPGAreceiveLong1[@FPGAreceiveLong+1]: byte;
  FPGAreceiveLong2[@FPGAreceiveLong+2]: byte;
  FPGAreceiveLong3[@FPGAreceiveLong+3]: byte;

  FPGAdate: LongInt;
  FPGAday[@FPGAdate+0]: byte;
  FPGAmonth[@FPGAdate+1]: byte;
  FPGAyear0[@FPGAdate+2]: byte;
  FPGAyear1[@FPGAdate+3]: byte;
  FPGAyear[@FPGAdate+2]: Integer;


{$VALIDATE_ON}
// F�r Assembler-Routinen in DF_ ben�tigt!
  FPGAsendword, FPGAreceiveword: word;
  FPGAsendWord0[@FPGAsendWord+0]: byte;
  FPGAsendWord1[@FPGAsendWord+1]: byte;
  FPGAsendByte, FPGAreceiveByte, FPGAbyte: byte;  // FPGA-Registerwert Byte
{$VALIDATE_OFF}

implementation
{ implementation-Abschnitte }
// #############################################################################
// ###             Tabs und gesetzte Parameter an FPGA senden                ###
// #############################################################################

const
  b_SCK:       byte = 7; // Takt f�r alle, SPI-Belegung!
  b_MISO:      byte = 6; // SPI Daten von allen
  b_MOSI:      byte = 5; // Daten an alle
  // b_SS:        byte = 4; // f�r MMC-Karte benutzt, HW-SPI!
  b_DATASEL:   byte = 3; // FPGA 32-Bit-Register
  // b_INT2:      byte = 2; // INT2 ausgel�st vom FPGA
  b_REGSEL:    byte = 1; // FPGA Registerauswahl
  // b_DFCS:      byte = 0; // DataFlash Chipselect

var
{$PData}
// #### AVR Port B ####
  FPGAport[@PortB]      : byte;   {FPGA-SPI-Port}

// #############################################################################

procedure LED_timer150;
// kurzes Aufblitzen der Board-LED2
begin
  LEDactivity:=low;
  if isSystimerzero(ActivityTimer) then
    setsystimer(ActivityTimer, 75);
  endif;
end;

procedure LED_timer50;
begin
// kurzes Aufblitzen der Board-LED2
  LEDactivity:=low;
  if isSystimerzero(ActivityTimer) then
    setsystimer(ActivityTimer, 25);
  endif;
end;

procedure LED_timer25;
begin
// kurzes Aufblitzen der Board-LED2
  LEDactivity:=low;
  if isSystimerzero(ActivityTimer) then
    setsystimer(ActivityTimer, 12);
  endif;
end;

procedure LED_timer250;
begin
// kurzes Aufblitzen der Board-LED2
  LEDactivity:=low;
  if isSystimerzero(ActivityTimer) then
    setsystimer(ActivityTimer, 125);
  endif;
end;

procedure LED_timer1000;
begin
  LEDactivity:=low;
  setsystimer(ActivityTimer, 500);
end;

procedure MemLED(my_memled: boolean);
begin
  LEDactivity:= not my_memled;
end;

procedure LED_blink(my_blinks: Byte);
begin
  for i:= 0 to my_blinks do
    LEDactivity:=low;
    mdelay(100);
    LEDactivity:=low;
    mdelay(100);
  endfor;
  MemLed(false);
end;

// #############################################################################
// FPGA Lowlevel functions
// #############################################################################

procedure SendFPGA8;
//Sende und empfange ein Daten-Byte an den FPGA-Chip �ber SPI
begin
  asm;
;    cli ; Disable interrupts
    lds  _ACCA, fpga_if.FPGAsendByte
    cbi  fpga_if.FPGAport, fpga_if.b_DATASEL
    out SPDR, _ACCA    ; SPI wurde von FAT16-Treiber eingeschaltet!
  SPIwait8_1:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait8_1
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveByte, _ACCA  ;Lesewert zur�ck ins Datenbyte
    sbi  fpga_if.FPGAport, fpga_if.b_DATASEL
;    sei ; Enable interrupts
  endasm;
end;

procedure SendFPGA16;
//Sende und empfange ein Daten-Wort (16 Bit-Register) an den FPGA-Chip �ber SPI
begin
  asm;
;    cli ; Disable interrupts
    lds  _ACCA, fpga_if.FPGAsendWord+1
    cbi  fpga_if.FPGAport, fpga_if.b_DATASEL
    out SPDR, _ACCA    ; SPI wurde von FAT16-Treiber eingeschaltet!
  SPIwait16_3:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait16_3
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveWord+1, _ACCA

    lds  _ACCA, fpga_if.FPGAsendWord+0
    out SPDR, _ACCA
  SPIwait16_4:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait16_4
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveWord+0, _ACCA

    sbi  fpga_if.FPGAport, fpga_if.b_DATASEL
;    sei ; Enable interrupts
  endasm;
end;

procedure SendFPGA32;
//Sende und empfange ein Daten-Langwort (32 Bit-Register) an den FPGA-Chip �ber SPI
begin
  asm;
;    cli ; Disable interrupts
    lds  _ACCA, fpga_if.FPGAsendLong+3
    cbi  fpga_if.FPGAport, fpga_if.b_DATASEL
    out SPDR, _ACCA    ; SPI wurde von FAT16-Treiber eingeschaltet!
  SPIwait32_1:
    in _ACCA, SPSR
    sbrs _ACCA,7       ; SPIF gesetzt?
    rjmp SPIwait32_1   ; auf Ende des SPI-Transfer warten
    in _ACCA, SPDR     ; und empfangenes Byte wieder in FPGAsendLong ablegen
    sts  fpga_if.FPGAreceiveLong+3, _ACCA

    lds  _ACCA, fpga_if.FPGAsendLong+2
    out SPDR, _ACCA     ; SPI von FAT16-Treiber eingeschaltet!
  SPIwait32_2:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait32_2
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveLong+2, _ACCA

    lds  _ACCA, fpga_if.FPGAsendLong+1
    out SPDR, _ACCA
  SPIwait32_3:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait32_3
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveLong+1, _ACCA

    lds  _ACCA, fpga_if.FPGAsendLong+0
    out SPDR, _ACCA
  SPIwait32_4:
    in _ACCA, SPSR
    sbrs _ACCA,7
    rjmp SPIwait32_4
    in _ACCA, SPDR
    sts  fpga_if.FPGAreceiveLong+0, _ACCA

    sbi  fpga_if.FPGAport, fpga_if.b_DATASEL
;    sei ; Enable interrupts
  endasm;
end;

procedure SendFPGAreg;
//Sende ein Byte (Registeradresse) an den FPGA-Chip
begin
  asm;
;    cli ; Disable interrupts
    lds  _ACCA, fpga_if.FPGAreg+1  ; Adresse Word MSB
    cbi  fpga_if.FPGAport, fpga_if.b_REGSEL
    out SPDR, _ACCA     ; SPI von FAT16-Treiber eingeschaltet!
  SPIwaitReg_1:
    in _ACCA, SPSR
    sbrs _ACCA,7 ; SPIF?
    rjmp SPIwaitReg_1     ;  auf Ende des SPI-Transfer warten

    lds  _ACCA, fpga_if.FPGAreg  ; Adresse Word LSB
    out SPDR, _ACCA     ; SPI von FAT16-Treiber eingeschaltet!
  SPIwaitReg_2:
    in _ACCA, SPSR
    sbrs _ACCA,7 ; SPIF?
    rjmp SPIwaitReg_2     ;  auf Ende des SPI-Transfer warten

    sbi  fpga_if.FPGAport, fpga_if.b_REGSEL
;    sei ; Enable interrupts
  endasm;
end;


// #############################################################################
// FPGA SPI communication functions
// #############################################################################

function ReceiveFPGA(const myreg:byte): LongInt;
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $00;       // ohne Write Enable
  SendFPGAreg;
  SendFPGA32;
  return(FPGAreceiveLong);
end;

procedure SendByteToFPGA(const myparam: byte; const myreg:byte);
// schreibe unskalierten Wert "myparam" nach SPI "myreg"
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  hi(FPGAsendWord):= 0;
  lo(FPGAsendWord):= myparam;
  SendFPGA16;
end;

{
procedure SPI_fpga_send_byte(const myreg:byte; const myparam: byte);
// schreibe unskalierten Wert "myparam" nach SPI "myreg"
// umgekehrte Reihenfolge, sonst wie vor
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  hi(FPGAsendWord):= 0;
  lo(FPGAsendWord):= myparam;
  SendFPGA16;
end;
}

procedure SendDoubledByteToFPGA(const myparam: byte; const myreg:byte);
// schreib verdoppelten Wert "myparam" nach SPI "myreg"
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  FPGAsendWord:= word(myparam) shl 1;
  SendFPGA16;
end;

procedure SendScaledByteToFPGA(const myparam: byte; const myreg, myscale: byte);
// schreibt Wert "myparam" * myscale div 100 nach SPI "myreg"
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  hi(FPGAsendWord):= 0;
  lo(FPGAsendWord):= muldivByte(myparam, myscale, 100);
  SendFPGA16;
end;

procedure SendVolumeByteToFPGA(const myparam: byte; const myreg:byte);
// schreibt quadrierten Wert div 64 "myparam" nach SPI "myreg"
// 0..127 auf 0..252
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  FPGAsendWord:= word(myparam);
  FPGAsendWord:= muldivInt(FPGAsendWord, FPGAsendWord, 64);
  SendFPGA16;
end;

procedure SendVolumeByteLogToFPGA(const myparam: byte; const myreg:byte);
// schreibt "myparam" �ber DrawbarLog-Tabelle nach SPI "myreg"
// 0..127 auf 0..252
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  FPGAsendWord:= word(c_DrawbarLogTable[myparam]) shl 1;
  SendFPGA16;
end;

procedure SendWordToFPGA(const myparam: word; const myreg:byte);
// schreib unskalierten Wert "myparam" nach SPI "myreg"
begin
  lo(FPGAreg):= myreg;     // Schreib-Register
  hi(FPGAreg):= $80;       // mit Write Enable
  SendFPGAreg;
  FPGAsendWord := myparam;
  SendFPGA16;
end;

procedure SendLongToFPGA(const myparam: LongInt; const myreg:byte);
// schreib unskalierten Wert "myparam" nach SPI "myreg"
begin
  lo(FPGAreg):=myreg;     // Schreib-Register
  hi(FPGAreg):=$80;       // mit Write Enable
  SendFPGAreg;
  FPGAsendLong:= myparam;
  SendFPGA32;
end;

// #############################################################################
// ###                      INITIALISIERUNG FPGA                             ###
// #############################################################################

procedure FI_FPGAconfig(force_init: Boolean);
// Pulse PROG, force FPGA configuration
var my_time: byte;
begin
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ (FI) Config FPGA from DF');
{$ENDIF}

  FPGA_OK:= false;
  FPGA_UpToDate:= false;

  if force_init then
    DDRB:=  DDRBinit_SelfConf;   {PortB dir}
    SPCR := %01011100;          // Enable SPI, Master, CPOL/CPHA=1,1 Mode 3
    SPSR := %00000000;          // %00000001 = Double Rate, %00000000 = Normal Rate
    PortB:= PortBinit;           {PortB}
    ConfErr:= false;
    FPGA_PROG:= low;
    udelay(5);
    FPGA_PROG:= high;
  endif;

  my_time:= 0;
  repeat  // Konfiguration abwarten, max 1 Sek
    mdelay(10);
    inc(my_time);
  until FPGA_DONE or (my_time > 250);

  if force_init then
    DDRB:= DDRBinit;   // PB0 DF Enable ist wieder Ausgang
    PortB:= PortBinit; // PortB wiederherstellen
  endif;
  FPGA_PROG:= FPGA_DONE;

  if FPGA_DONE then
    ReceiveFPGA(3);  // FPGA-Datum lesen
    // BCD-kodiertes Erstellungsdatum umsortieren
    FPGAyear0:= FPGAreceiveLong0; // in FPGAdate!
    FPGAyear1:= FPGAreceiveLong1;
    FPGAmonth:= FPGAreceiveLong2;
    FPGAday:=   FPGAreceiveLong3;
{$IFDEF DEBUG_MSG}
    write(serout, '/ (FI) FPGA: #');
    writeln(serout, LongToHex(FPGAreceiveLong));
{$ENDIF}
    FPGA_OK:= (FPGAreceiveLong <> 0) and (FPGAreceiveLong <> $FFFFFFFF);
    FPGA_UpToDate:= FPGA_OK and (FPGAdate >= c_min_date);
    if FPGA_OK then
      if not FPGA_UpToDate then
        writeln(serout, '/ WARNING: FPGA out of date');
      endif;
    else
      writeln(serout, '/ ERROR: FPGA corrupted');
      ConfErr:= true;
    endif;
  else
    writeln(serout, '/ ERROR: FPGA_DONE failed or CONFDIS JP set');
    ConfErr:= true;
  endif;

  if ConfErr then
{$IFNDEF MODULE}
    if LCDpresent then
      LCDxy_M(LCD_m1, 0, 1);
      write(LCDOut_M, 'FPGA FAULT');
      LCDclrEOL_M(LCD_m1);
    endif;
{$ENDIF} // ALLINONE
    //LED_blink(5);
  else
{$IFNDEF MODULE}
    if LCDpresent then
      ReceiveFPGA(3);
      ValueLong:= FPGAreceiveLong; // vom FPGA AUXPORT
  // in MIDI-DB2 steht nach dem Start die Core-Version
      LCDxy_M(LCD_m1, 0, 1);
      write(LCDOut_M, 'FPGA #');
      write(LCDOut_M, longtohex(ValueLong));
      LCDclrEOL_M(LCD_m1);
      mdelay(500);
    endif;
{$ENDIF} // ALLINONE
    LED_timer250;
    for i:= 0 to 255 do
      ReceiveFPGA(c_MIDIreceiveReg);     // FIFO-Register komplett auslesen
      ReceiveFPGA(c_MIDIreceiveReg);
      if F_FIFO_empty then
        break;
      endif;
    endfor;
  endif;
end;

procedure FI_GetScanCoreInfo;
var
  buf_count: Integer;
begin
// FPGAreceiveLong2 = Command, $AA
// FPGAreceiveLong1 = Controller-Nr, c_corerevi
// FPGAreceiveLong0 = Controller-Wert, c_corevers
  for buf_count:= 0 to 1023 do
    ReceiveFPGA(c_MIDIreceiveReg);     // FIFO-Register
    if F_FIFO_empty then
      break;
    endif;
  endfor;
  FI_AutoIncReset(0); // Reset Picoblaze
  mdelay(5);
  ReceiveFPGA(c_MIDIreceiveReg);     // FIFO-Register
  if FPGAreceiveLong2 = $AA then
    ScanCoreRevision:= FPGAreceiveLong1;
    ScanCoreID:= FPGAreceiveLong0;
  else
    ScanCoreRevision:= 0;
    ScanCoreID:= 0;
  endif;
end;

procedure FI_AutoIncReset(my_target: byte);
// AutoInc zur�cksetzen, Core freigeben
begin
  hi(FPGAreg):= $80;  // SPI Wite Enable
  lo(FPGAreg):= 129;  // Schreib-Register Adress-Reset
  SendFPGAreg;
  FPGAsendByte:= my_target; // resettet Core Select
  SendFPGA8;
end;

procedure FI_AutoIncSetup(my_target: byte);
// AutoInc vorbereiten: L�nge, Start an SPI �bermitteln
begin
  FI_AutoIncReset(my_target);
  lo(FPGAreg):= 128;  // Schreib-Register Daten f�r DAT-Files
  SendFPGAreg;
end;

procedure FI_SendBlockBuffer(count: Word; width: byte);
// Sende BlockBuffer an AutoInc-Register, Länge length in Bytes,
// data_width in Bits (8, 16, 24 oder 32) oder Bytes (1, 2, 3 oder 4)
// Universell verwendbar für alle Cores, die Daten in 8, 16 oder 32 Bit Breite erwarten
var buf_idx: Word;
begin
  case width of
    1, 8:
      for buf_idx:= 0 to count - 1 do
        FPGAsendByte:= BlockBuffer8[buf_idx];
        SendFPGA8;
      endfor;
    |
    2, 16:
      // Länge in LongWords - nicht in Bytes! - übergeben, da Blockarray_lw verwendet wird
      for buf_idx:= 0 to count - 1 do
        FPGAsendWord:= Blockarray_w[buf_idx];
        SendFPGA16;
      endfor;
    |
    4, 32:
      // Länge in LongWords - nicht in Bytes! - übergeben, da Blockarray_lw verwendet wird
      for buf_idx:= 0 to count - 1 do
        FPGAsendLong:= Blockarray_lw[buf_idx];
        SendFPGA32;
      endfor;
    |
  endcase;
end;


end fpga_if.


// #############################################################################
// ###                          DataFlash-Interface                          ###
// #############################################################################

unit dataflash;

interface
uses const_def, eeprom_def, fpga_if;

//function  DF_status: byte;
procedure DF_protect;
procedure DF_unprotect;
function  DF_erase: boolean;
function DF_writeblock(const block_4k: Word; const df_blocklen: word): boolean;
function  DF_eraseblock_4k(const block_4k: Word): boolean;
procedure DF_readblock(const block_4k: Word; const df_blocklen: word);
function DF_EraseWriteblock(const block_4k: Word; const df_blocklen: word): boolean;

// kopiert 4K-Blöcke von first_block bis einschl. last_block nach dest_block:
procedure DF_CopyBlocks(const first_block, last_block, dest_block: Word);

// PicoBlaze- oder Tapering-Core #x aus DF laden und an AutoInc-Reg senden
procedure DF_SendToAutoinc(const block_4k: Word; const my_target: byte; const my_len: word);

// Restore EEPROM content from Factory Default in DF block #my_block
procedure DFtoEEPROM(block, start_adr: Word);

procedure DF_FWupdateFromFlashAndReboot;

// 4K-Block seriell empangen und in BlockBuffer8 speichern, eigenes Protokoll.
// Liefert TRUE wenn Transfer erfolgreich (Prüfsumme OK)
// Format: $55 AA CC cc <4K data> mit CC cc = 16-Bit-Summe aller Datenbytes
function DF_SerReceive4kBlock(const num_bytes: Integer): boolean;

// vorhandenen 4K-Block aus BlockBuffer8 in DataFlash übertragen
// Liefert TRUE wenn Store erfolgreich (kein Speicherfehler)
function DF_Store4kBlock(const block_4k, block_len: Word): boolean;

// Prüfsumme Firmware direkt aus DF
// df_first_block: erster zu berücksichtigender 4K-Block
// df_last_block: letzter zu berücksichtigender 4K-Block
function DF_getChecksum(const df_first_block, df_last_block: Word):word;

function DF_GetPresetNameStr(const common_preset: Byte): Boolean;

implementation

const
  b_DFCS:      byte = 0; // DataFlash Chipselect

var
{$PData}
  F_DFCS[@PortB, b_DFCS]: bit;    // CS für AT25DF021

{$IData}
  DF_send, DF_receive  : byte;  // externer DataFlash-Speicher
  DF_long : LongInt;     // DF-Registerwert Langwort
  DF_long0[@DF_long+0]       : byte;
  DF_long1[@DF_long+1]       : byte;
  DF_long2[@DF_long+2]       : byte;
  DF_long3[@DF_long+3]       : byte;
  df_idxw, df_blockw: Word;

// #############################################################################
// DataFlash SPI Funktionen
// #############################################################################

procedure DF_sr;
// Sende/empfange ein Byte über SPI an DF (F_DFCS muss entspr. gesetzt sein)
begin
  asm;
;    cli ; Disable interrupts
    lds  _ACCA, dataflash.DF_send
    out SPDR, _ACCA     ; SPI von FAT16-Treiber eingeschaltet!
  DF_waitReg:
    in _ACCA, SPSR
    sbrs _ACCA,7 ; SPIF?
    rjmp DF_waitReg     ;  auf Ende des SPI-Transfer warten
    in _ACCA, SPDR
    sts  dataflash.DF_receive, _ACCA  ;Lesewert zurück ins Datenbyte
;    sei ; Enable interrupts
  endasm;
end;

{
function DF_status: byte;
// Lese DF Status; normal $1C = 28 dez. = %0001 1100
begin
  F_DFCS:= low;
  DF_send:=$05; // Read Status
  DF_sr;
  DF_sr;
  F_DFCS:= high;
  return(DF_receive);
end;

function DF_checkprotected: boolean;
begin
  return ((DF_status and %11101111) <> 0);
end;
}

procedure DF_busy;
// Warte, bis DF nicht mehr beschäftigt ist
begin
  F_DFCS:= low;
  DF_send:=$05; // Read Status
  DF_sr;
  repeat
    DF_sr;
  until (DF_receive AND $01) = 0;
  F_DFCS:= high;
end;

procedure DF_wen;
// Setze DF Write Enable
begin
  F_DFCS:= low;
  DF_send:=$06; // Write Enable
  DF_sr;
  F_DFCS:= high;
end;

procedure DF_unprotect;
// DataFlash freigeben, Global unprotect
begin
  DF_wen;
  F_DFCS:= low;
  DF_send:=$01; // Write Status
  DF_sr;
  DF_send:=$00; // Write 0, Global Unprotect
  DF_sr;
  F_DFCS:= high;
  DF_busy;
end;

procedure DF_protect;
// DataFlash sperren
begin
  DF_wen;
  F_DFCS:= low;
  DF_send:=$01; // Write Status
  DF_sr;
  DF_send:=$3F; // Write $3F, Global Protect
  DF_sr;
  F_DFCS:= high;
  DF_busy;
end;

// #############################################################################

function DF_eraseblock_4k(const block_4k: Word): boolean;
// Lösche 4-KByte-Block bzw. 64-KByte-Sektor im DF
// liefert TRUE wenn erfolgreich
begin
  DF_wen;
  F_DFCS:= low;
  DF_long := LongInt(block_4k) * 4096;
  DF_send:=$20; // Erase 4 KByte Block
  DF_sr;
  DF_send:=DF_long2; // Adr Bits 23..16
  DF_sr;
  DF_send:=DF_long1; // Adr Bits 15..8
  DF_sr;
  DF_send:=DF_long0; // Adr Bits 7..0
  DF_sr;
  F_DFCS:= high;
  DF_busy;
  return ((DF_receive AND $20) = 0);
end;

function DF_erase: boolean;
// DataFlash löschen, warten bis Ende
// liefert TRUE wenn erfolgreich
begin
  DF_wen;
  F_DFCS:= low;
  DF_send:= $C7; // Chip/Bulk Erase
  DF_sr;
  F_DFCS:= high;
  DF_busy;
  return ((DF_receive AND $20) = 0);
end;

function DF_writeblock(const block_4k: Word; const df_blocklen: word): boolean;
// Sende BlockBuffer8 mit (df_count) Bytes an DataFlash
// liefert TRUE wenn erfolgreich
// df_blocklen sollte Vielfaches von 256 sein,
// es können max. 256 Bytes auf einmal geschrieben werden
var my_idx: word;
  df_adr: LongInt;
begin
  my_idx:= 0;
  df_adr := LongInt(block_4k) * 4096;
  for df_idxw:= 0 to (df_blocklen div 256) - 1 do
    DF_wen;
    F_DFCS:= low;
    DF_long := df_adr;
    DF_send:=$02; // Write Page
    DF_sr;
    DF_send:=DF_long2; // Adr Bits 23..16
    DF_sr;
    DF_send:=DF_long1; // Adr Bits 15..8
    DF_sr;
    DF_send:=DF_long0; // Adr Bits 7..0
    DF_sr;
    for h := 0 to 255 do
      DF_send:= BlockBuffer8[my_idx]; // Data Byte h
      DF_sr;
      inc(my_idx);
    endfor;
    F_DFCS:= high;
    DF_busy;
    inc(df_adr, 256);
  endfor;
  return ((DF_receive AND $20) = 0);
end;

function DF_EraseWriteblock(const block_4k: Word; const df_blocklen: word): boolean;
var result_ok: Boolean;
begin
  DF_unprotect;
  result_ok:= false;
  if DF_eraseblock_4k(block_4k) then
    result_ok:= DF_writeblock(block_4k, df_blocklen);
  endif;
  DF_protect;
  return(result_ok);
end;


procedure DF_readblock(const block_4k: Word; const df_blocklen: word);
//Lese BlockBuffer8 aus DataFlash, max. 4096 bytes
begin
  DF_busy;
  DF_long := LongInt(block_4k) * 4096;
  F_DFCS:= low;
  DF_send:=$0B; // Read Page
  DF_sr;
  DF_send:=DF_long2; // Adr Bits 23..16
  DF_sr;
  DF_send:=DF_long1; // Adr Bits 15..8
  DF_sr;
  DF_send:=DF_long0; // Adr Bits 7..0
  DF_sr;
  DF_send:=0; // dummy für $0B read mode
  DF_sr;
  for df_idxw:= 0 to df_blocklen-1 do
    DF_sr;
    BlockBuffer8[df_idxw]:=DF_receive;
  endfor;
  F_DFCS:= high;
end;

function DF_getChecksum(const df_first_block, df_last_block: Word):word;
// df_first_block: erster zu berücksichtigender 4K-Block
// df_last_block: letzter zu berücksichtigender 4K-Block
// c_firmware_startblock_w: Word  = $3E0;       // 992 (944 + 48)
var
  block_idx, my_addr, my_checksum: Word;
begin
  LEDactivity:=low;
{$IFNDEF MODULE}
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, 'Get DF Checksum');
    MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
  endif;
{$ENDIF}
  my_checksum:= 0;
  for block_idx:= df_first_block to df_last_block do
    DF_readblock(block_idx, 4096);
    for my_addr:= 0 to 4095 do
      my_checksum:= my_checksum + word(BlockBuffer8[my_addr]);
    endfor;
    LEDactivity:= not LEDactivity; //  LED Toggle
  endfor;
  return(my_checksum);
end;

// #############################################################################

procedure DF_SendToAutoinc(const block_4k : Word; const my_target: byte; const my_len: word);
// PicoBlaze- oder Tapering-Core #x aus DF laden und an AutoInc-Reg senden
// Relative 4k-Blocknummer ab c_scan_base!
// 4096 Bytes = 1 BlockRAM
// 0..1: Scan Core,
// 11..14: Tapering
// 15: FIR filter

var block_count, block_idx, array_idx, loop_count, read_len: Word;
begin
//  AutoIncSel:= myDF_4K_block - c_scan_base; // Core-Nr. wird Blocknummer-Offset
{$IFDEF DEBUG_DF}
    writeln(serout,'/ (DF) Core block ' + bytetostr(block_offs)
                    + ' to FPGA (' + bytetostr(my_target) + ')');
{$ENDIF}
  block_count:= 0;
  block_idx:= 0;
  if my_len < 4096 then
    loop_count:= (my_len div 4) - 1;
    read_len:= my_len;
  else
    loop_count:= 1023;
    read_len:= 4096;
  endif;
  FI_AutoIncSetup(my_target); // for Write
  repeat
    DF_readblock(block_4k + block_count, read_len); // , false
    for array_idx:= 0 to loop_count do
      FPGAsendLong:= Blockarray_lw[array_idx];
      SendFPGA32;
    endfor;
    inc(block_idx, 4096);
    inc(block_count);
  until block_idx >= my_len;
  FI_AutoIncReset(my_target);
end;

// #############################################################################


function DF_GetPresetNameStr(const common_preset: Byte): Boolean;
var my_4K_block_num: Word;
begin
  if common_preset = 0 then
    CommentStr:= c_PresetNameStr0;
  else
    my_4K_block_num:= c_preset_base_DF + word(common_preset);
    DF_readblock(my_4K_block_num, 256);
    if valueInRange(block_PresetNameLen, 1, 15) then
      CommentStr:= block_PresetNameStr;
    else
      CommentStr:= '(unnamed)';
      return(false);
    endif;
  endif;
  return(true);
end;

// #############################################################################

procedure DFtoEEPROM(block, start_adr: word);
// Restore EEPROM content from Factory Default in DF block #myDF_4K_block_offs
// Relative 4k-Blocknummer!
// 4096 Bytes = 1 BlockRAM

var ee_adr: word;
begin
{$IFDEF DEBUG_DF}
  write(serout,'/ (DF) Restore EEPROM from core block #');
  writeln(serout, Inttostr(myDF_4K_block_offs));
{$ENDIF}
  DF_readblock(block, 4096);
  for ee_adr:= start_adr to 4095 do
    EE_dumpArr[ee_adr]:= BlockBuffer8[ee_adr];
  endfor;
end;


procedure DF_FWupdateFromFlashAndReboot;
//Firmware aus DataFlash holen, per Bootloader in AVR übertragen und Reboot
begin
  LEDactivity:=low;
{$IFNDEF MODULE}
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, 'Update Firmware');
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M, LongToHex(ValueLong));
    LED_timer250;
  endif;
{$ENDIF} // ALLINONE
  if SD_TextFile_open then
    F16_FileClose (SD_TextFile);
  endif;
  writeln(serout, '/ (DF) Invoke Bootloader, flash AVR Firmware ROM from DF...');
  mdelay(100);
  MCUCR:=0; EICRA:=0; EIMSK:=0; PCICR:=0;
  WDTCSR:=0; CLKPR:=0; MCUSR:=0;
  // Flash-Programmierung im Bootblock anspringen. Lädt ROM aus SPI-Flash
  // und startet anschließend neu. Da update.ini inzwischen umbenannt
  // ist, wird dieser Vorgang nur einmal ausgeführt. Bei
  // einem weiteren Start werden nur die Parameter gesetzt, da
  // EEPROM-Flag EE_skip_flashload noch TRUE ist.
  asm;
    JMP  $1F800;                   // c_BootSection;
  endasm;
end;

function DF_SerReceive4kBlock(const num_bytes: Integer): boolean;
// 4K-Block seriell empangen und in BlockBuffer8 speichern, eigenes Protokoll.
// Liefert TRUE wenn Transfer erfolgreich (Prüfsumme OK)
// Format: $55 AA CC cc <4K data> mit CC cc = 16-Bit-Summe aller Datenbytes
// Alle 128 Bytes empfangener Nutzdaten wird ein ACK (#6) gesendet
var is_ok: Boolean; byte_received: byte;
    idx_w, checksum_received, checksum_calculated: Word;
begin
  LEDactivity:=low;
  for i:= 0 to 3 do  // Restzeichen im Buffer, evt. LF
    SerInp_to(byte_received, 100);
    is_ok:= (byte_received = $55);
    if is_ok then
      break;
    endif;
  endfor;
  if is_ok then
    SerInp_to(byte_received, 10);
    is_ok:= (byte_received = $AA);
  endif;
  if is_ok then
    SerInpBlock_TO(checksum_received, 100);   // niederwertiges Byte zuerst
    checksum_calculated:= 0;

    for idx_w:= 0 to num_bytes - 1 do
      is_ok:= SerInp_to(byte_received, 50);
      BlockBuffer8[idx_w]:= byte_received;
      checksum_calculated:= checksum_calculated + word(byte_received);
      if idx_w mod 128 = 0 then
        serout(#6); // ACK senden
      endif;
    endfor;

    is_ok:= (checksum_calculated = checksum_received);
  endif;
  LED_timer1000;
  return(is_ok);
end;

function DF_Store4kBlock(const  block_4k, block_len: Word): boolean;
// vorhandenen 4K-Block aus BlockBuffer8 in DataFlash übertragen
// Liefert TRUE wenn Transfer erfolgreich (kein Speicherfehler)
var is_ok: Boolean;
begin
  LEDactivity:=low;
  is_ok:= true;
  DF_unprotect;
  if DF_eraseblock_4k(block_4k) then
    if not DF_writeblock(block_4k, block_len) then
      is_ok:= false;
    endif;
  else
    is_ok:= false;
  endif;
  DF_protect;
  return(is_ok);
  LED_timer250;
end;

procedure DF_CopyBlocks(const first_block, last_block, dest_block: Word);
// kopiert 4K-Blöcke von first_block bis einschl. last_block nach dest_block
var my_block_idx, my_block_count: Word;
begin
  LEDactivity:=low;
  my_block_count:= last_block - first_block;
{$IFNDEF MODULE}
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, 'Copy shadow DF');
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M, LongToHex(ValueLong));
    MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
  endif;
{$ENDIF}
  for my_block_idx:= 0 to my_block_count do
    LEDactivity:= low; //  LED ON
{$IFNDEF MODULE}
    if LCDpresent then
      LCDxy_M(LCD_m1, 0, 1);
      write(LCDOut_M, 'Count: ' + IntToHex(my_block_idx));
      LED_timer250;
    endif;
{$ENDIF}
    DF_readblock(first_block + my_block_idx, 4096);
    LEDactivity:=high; //  LED OFF
    if DF_Store4kBlock(dest_block + my_block_idx, 4096) then
{$IFNDEF MODULE}
      if LCDpresent then
        write(LCDOut_M, ' OK');
      endif;
{$ENDIF}
    else
{$IFNDEF MODULE}
      if LCDpresent then
        write(LCDOut_M, ' FAIL');
      endif;
{$ENDIF}
    endif;
  endfor;
  LED_timer1000;
end;

end dataflash.


// #############################################################################
// ###                       F Ü R   A L L E   B O A R D S                   ###
// #############################################################################
// ###                          SD CARD FUNCTIONS                           ####
// #############################################################################
unit sd_card;

interface
uses var_def, port_def, edit_changes, dataflash;
{$IFNDEF MODULE}
uses display_toolbox;
{$ENDIF} // ALLINONE

type t_flashErr = (df_noErr, df_skipped, df_fileNotFound, df_eraseErr, df_writeFailed, df_verifyFailed);

// Gibt Anzahl der vorhandenen Dateien zurück
function SD_GetDir(const file_mask: string[5]; const list_files: boolean): Byte;

function  SD_ForceCheck: Boolean; // mit Meldung, wenn Karte fehlt oder defekt
procedure SD_SilentInit; // ohne Meldung

// Datei von SD-Karte lesen und ab my_startAddr in DF abspeichern
// Absolute 4k-Blocknummer, iefert TRUE wenn erfolgreich
function SD_FlashBinFile(const startblock: Word; const my_BinFileName: String[15]): t_flashErr;

// Standard-Update: Alle Files von SD laden und im DF ablegen
procedure SD_LoadAndFlashAllBinCores(const upd_cores, upd_firmware: boolean);
function SD_LoadAndFlashStandardCCsets: t_flashErr;
function SD_LoadAndFlashCustomCCsets: t_flashErr;
function SD_LoadAndFlashWavesets: t_flashErr;
function SD_LoadAndFlashTaperings: t_flashErr;

implementation
{$IDATA}

{$TYPEDCONST OFF}
const
  sd_missing_str = 'SD not found!';
{$TYPEDCONST ON}

procedure sd_missing_msg;
begin
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, sd_missing_str);
    LED_blink(3);
  endif;
  WriteSerError;
  writeln(serout, sd_missing_str);
end;

function SD_ForceCheck: Boolean;
begin
  if F16_DiskInit then
    F16_DiskReset;
    SD_present:= F16_CheckDisk;
  endif;
  if SD_present then
    return(true);
  else
    incl(ErrFlags, c_err_sd);
  endif;
  sd_missing_msg;
  return(false);
end;

Procedure SD_SilentInit;
begin
  if not SD_present then
    if F16_DiskInit then
      F16_DiskReset;
      SD_present:= F16_CheckDisk;
      if not SD_present then
        incl(ErrFlags, c_err_sd);
      endif;
    endif;
  endif;
end;

function SD_GetDir(const file_mask: string[5]; const list_files: boolean): Byte;
// Gibt in "number_of_Files" Anzahl der passenden Dateien zurück
var my_searchRec: TsearchRec;
    number_of_Files: Byte;
begin
{$IFDEF DEBUG_SD}
  writeln(serout, '/ SD GetDir ');
{$ENDIF}
  number_of_Files:= 0;
  if SD_ForceCheck then
    if F16_FindFirst('\', file_mask, faAnyFile, my_searchRec) then
      repeat
        if list_files then
          writeln(serout, '/ ' + my_searchRec.name);
        else
          BlockArrayDirFileNames[number_of_Files]:= my_searchRec.name;
{$IFDEF DEBUG_SD}
          writeln(serout, '/ SD ' + my_searchRec.name);
{$ENDIF}
        endif;
        inc(number_of_Files);
      until not F16_FindNext(my_searchRec);
    endif;
  endif;
  return(number_of_Files);
end;


// Liefert TRUE wenn SDCard vorhanden und min. 1 File vorhanden
function SD_FlashBinFile(const startblock: Word; const my_BinFileName: String[15]): t_flashErr;
// Datei von SD-Karte lesen und ab my_startAddr in DF abspeichern
// Absolute 4k-Blocknummer in startblock, liefert t_flashErr wenn erfolgreich
// type t_flashErr = (df_noErr, df_skipped, df_fileNotFound, df_eraseErr, df_writeFailed, df_verifyFailed);
var
  sd_size        : LongWord;
  sd_file        : file of Byte;
  bytes_read, current_block, block_count: Word;
//  ver_idx: Word;
  my_err: t_flashErr;
begin
  ValueLong:= 0;
  block_count:= 0;
  if not SD_present then
    sd_missing_msg;
    return(df_fileNotFound);
  endif;
{$IFNDEF MODULE}
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, 'SD Load:');
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M, my_BinFileName);
  endif;
{$ENDIF} // ALLINONE
  my_err:= df_noErr;
  current_block:= startblock;
  if F16_FileExist ('\', my_BinFileName, faFilesOnly) then
    F16_FileSize('\', my_BinFileName, sd_size);
{$IFDEF DEBUG_SD}
    writeln(serout, '/ SD Flash file "' + my_BinFileName + '" Size ' + LongToStr(sd_size));
{$ENDIF}
    sd_size:= (sd_size div 4096) + 1;
    F16_FileAssign(sd_file, '', my_BinFileName);
    F16_FileReset(sd_file); // Datei zum Lesen öffnen
    DF_unprotect;
    ConfErr:= false;
    while not F16_EndOfFile(sd_file) do // read the entire file
{$IFNDEF MODULE}
      if LCDpresent then
        LCDxy_M(LCD_m1, 9, 0);
        LCDOut_M('#');
        write(LCDOut_M, IntToStr(current_block));
      endif;
{$ENDIF} // ALLINONE
      F16_BlockRead (sd_file, @BlockBuffer8, 4096, bytes_read);
{$IFDEF DEBUG_SD}
      writeln(serout, '/ SD Write DF Block #' + IntToStr(current_block));
{$ENDIF}
      if not DF_eraseblock_4k(current_block) then
{$IFDEF DEBUG_SD}
        WriteSerError;
        writeln(serout, 'SD Erase DF block failed ');
{$ENDIF}
        ConfErr:= true;
        my_err:= df_eraseErr;
{$IFNDEF MODULE}
        if LCDpresent then
          LCDxy_M(LCD_m1, 0, 0);
          write(LCDOut_M, 'Erase Failed! ');
          LED_blink(10);
        endif;
{$ENDIF} // ALLINONE
        break;
      endif;

      if not DF_writeblock(current_block, 4096) then
        ConfErr:= true;
{$IFDEF DEBUG_SD}
        WriteSerError;
        writeln(serout, 'SD Write DF block failed ');
{$ENDIF}
        my_err:= df_writeFailed;
{$IFNDEF MODULE}
        if LCDpresent then
          LCDxy_M(LCD_m1, 0, 0);
          write(LCDOut_M, 'Write Failed!  ');
        endif;
{$ENDIF} // ALLINONE
        LED_blink(10);
        break;
      endif;
      inc(current_block);
      if (block_count > (c_FPGA_lastblock + 1)) or (block_count > word(sd_size)) then
        // maximale Länge einer Datei überschritten (SD defekt)?
        ConfErr:= true;
        my_err:= df_writeFailed;
{$IFDEF DEBUG_SD}
        WriteSerError;
        writeln(serout, 'SD Block count exceeded');
{$ENDIF}
{$IFNDEF MODULE}
        if LCDpresent then
          LCDxy_M(LCD_m1, 0, 0);
          write(LCDOut_M, 'SD Card Error!');
        endif;
{$ENDIF}
        LED_blink(10);
        break;
      endif;
      inc(block_count);
    endwhile; // until end of file
    F16_FileClose(sd_file);
    DF_protect;

    if my_Err > df_noErr then
      incl(ErrFlags, c_err_sd);
    endif;
    if my_Err >= df_eraseErr then
      incl(ErrFlags, c_err_flash);
    endif;
    MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
{$IFDEF DEBUG_SD}
    writeln(serout, '/ SD FlashFile returns ' + ByteToStr(ord(my_Err)));
{$ENDIF}
    return(my_Err);
  else
    WriteSerWarning;
    writeln(serout, 'SD File "' + my_BinFileName + '" not found ');
{$IFNDEF MODULE}
    if LCDpresent then
      LCDxy_M(LCD_m1, 0, 0);
      write(LCDOut_M, 'File not found:');
      LED_blink(3);
    endif;
{$ENDIF}
    ConfErr:= true;
    MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
    return(df_fileNotFound);
  endif;
end;

// #############################################################################

function SD_LoadAndFlashStandardCCsets: t_flashErr;
// 1 Block pro File
var my_err: t_flashErr;
  file_idx: Byte;
begin
  my_err:= df_noErr;
  for file_idx:= 0 to 8 do   // cc_set0.dat bis cc_set8.dat
    TempStr:= 'ccset' + ByteToStr(file_idx) + '.dat';
    my_err:= my_err or SD_FlashBinFile(c_midicc_base_DF + word(file_idx), TempStr);
  endfor;
  return(my_err);
end;

function SD_LoadAndFlashCustomCCsets: t_flashErr;
// 1 Block pro File
var my_err: t_flashErr;
  file_idx: Byte;
begin
  my_err:= df_noErr;
  for file_idx:= 9 to 10 do   // cc_set9.dat bis cc_set10.dat
    TempStr:= 'ccset' + ByteToStr(file_idx) + '.dat';
    my_err:= my_err or SD_FlashBinFile(c_midicc_base_DF + word(file_idx), TempStr);
  endfor;
  return(my_err);
end;

function SD_LoadAndFlashWavesets: t_flashErr;
// 4 Blöcke pro File!
var my_err: t_flashErr;
  file_idx: Byte; block_offs: Word;
begin
  my_err:= df_noErr;
  block_offs:= 0;
  for file_idx:= 0 to 7 do
    TempStr:= 'waveset' + ByteToStr(file_idx) + '.bin';
    my_err:= my_err or SD_FlashBinFile(c_waveset_base_DF + block_offs, TempStr);
    inc(block_offs, 4);
  endfor;
  return(my_err);
end;

function SD_LoadAndFlashTaperings: t_flashErr;
// 1 Block pro File
var my_err: t_flashErr;
  file_idx: Byte;
begin
  my_err:= df_noErr;
  for file_idx:= 0 to 3 do
    TempStr:= 'taper' + ByteToStr(file_idx + 1) + '.dat';
    my_err:= my_err or SD_FlashBinFile(c_taper_base_DF + word(file_idx), TempStr);
  endfor;
  return(my_err);
end;

procedure SD_LoadAndFlashAllBinCores(const upd_cores, upd_firmware: boolean);
// Standard-Update: Alle Files von SD laden und im DF ablegen
// type t_flashErr = (df_noErr, df_skipped, df_fileNotFound, df_eraseErr, df_writeFailed, df_verifyFailed);
var
  is_ok, overwrite_eeprom: Boolean;
begin
  ConfErr:= false;
  is_ok:= true;
  if upd_cores then
    if SD_FlashBinFile(0, 'hx3_main.bin') > df_noErr then
      ConfErr:= true;
      incl(ErrFlags, c_err_flash);
      is_ok:= false;
    endif;

    if (SD_FlashBinFile(c_scan_base_DF, 'scan.dat') > df_noErr) then
      incl(ErrFlags, c_err_upd);  // ScanCore immer benötigt!
      is_ok:= false;
    endif;

    if (SD_LoadAndFlashStandardCCsets > df_noErr) then
      incl(ErrFlags, c_err_upd);  // Standard CC Sets immer benötigt!
      is_ok:= false;
    endif;

    if (SD_LoadAndFlashTaperings > df_noErr) then
      incl(ErrFlags, c_err_upd);  // Taperings immer benötigt!
      is_ok:= false;
    endif;


    if (SD_LoadAndFlashWavesets > df_noErr) then
      incl(ErrFlags, c_err_upd);  // Wavesets immer benötigt!
      is_ok:= false;
    endif;

    SD_FlashBinFile(c_coeff_base_DF, 'fir_coe.dat');
    SD_LoadAndFlashCustomCCsets;                            // optional
    SD_FlashBinFile(c_organModel_base_DF, 'organs.dat');    // optional
    SD_FlashBinFile(c_leslieModel_base_DF, 'speakers.dat'); // optional
    SD_FlashBinFile(c_preset_base_DF, 'presets.dat');       // optional
  endif;
// Restore Edit Array from DF block #myDF_4K_block_offs
// Relative 4k-Blocknummer, Offset hier auf Daten-Bereich!

  overwrite_eeprom:= false;
  if upd_firmware then
    // EEPROM auf DF Core 9
    if SD_FlashBinFile(c_eeprom_base35_DF, 'eeprom.bin') = df_noErr then   // optional
      overwrite_eeprom:= true;    // bei Modul EEPROM immer updaten
    endif;
    // 128 KByte Firmware für Bootloader
    if SD_FlashBinFile(c_firmware_base35_DF, 'firmware.bin') = df_noErr then  // 992, 128 KByte
      writeln(serout, '/ Firmware copied to DF');
      if overwrite_eeprom then // steht noch im Buffer, nur ins EEPROM übertragen, wenn TRUE
        writeln(serout, '/ Overwrite EEPROM from DF');
        EE_ForceUpdateEEPROM:= true; // DF-Init beim Reboot erzwingen
      else
        writeln(serout, '/ Retain EEPROM content');
      endif;
{$IFNDEF MODULE}
      DT_ResetMenuEnables;
{$ENDIF}
      // DFtoEEPROM(c_eeprom_base) wird beim Reboot ausgeführt!
      DF_FWupdateFromFlashAndReboot;  // mit Meldung!
    else
      is_ok:= false;
    endif;
  endif;

  if not is_ok then
{$IFDEF DEBUG_SD}
    WriteSerError;
    writeln(serout, 'SD Files missing!');
{$ENDIF}
    ConfErr:= true;
    incl(ErrFlags, c_err_upd);
  endif;
end;


end sd_card.



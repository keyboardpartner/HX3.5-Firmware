// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################
// ###                            UTILITIES                                  ###
// #############################################################################

Unit nuts_and_bolts;

interface
// global part
uses const_def, var_def, port_def, edit_changes, fpga_if, eeprom_def, dataflash;

  procedure NB_VibknobToVCbits;
  procedure NB_VCbitsToVibknob;
  procedure NB_PercKnobToTabs;
  procedure NB_TabsToPercKnob;
  procedure NB_TabsToReverbKnob;


  procedure NB_ResetSpecialFlags;
  procedure NB_CheckForLive;

  procedure NB_CreateInverseCCarrays;
  procedure NB_CCarrayFromDF(const cc_set: Byte);

  // sendet einen binär kodierten Header ohne Länge an serielle Schnittstelle:
  function NB_SendBinaryHeader(const cmd: byte; const param_num: Integer):byte;

  procedure NB_SendBinaryBlock(const param_num: Integer; const len: Byte);
  procedure NB_SendBinaryVal(const param_num: Integer; const new_val: byte);
  procedure NB_SendBinaryAllOSCvals;

  procedure NB_SerSendBlockArray(const len_w: Word);

  procedure NB_LoadLeslieInits;
//  procedure NB_pulse(const p_len: byte); // neg. 10µs/dig Impuls für Messungen mit LA

  procedure NB_LoadPhasingSet(const my_phr_preset: byte);

  procedure NB_CreateInverseMenuArr;


  procedure NB_CheckDFUmsg;

  procedure NB_SetLEDdimmer;
  procedure NB_BlockRcvMsg(const my_block: Integer);

  function NB_GetBytefromI2Cslave(const i2c_addr, idx: Byte; var data: Byte): Boolean;
  function NB_SendBytetoI2Cslave(const i2c_addr, idx, data: Byte): Boolean;
  function NB_ManualDefaultsToI2Cslave(const manual: Byte): Boolean;

  procedure NB_ValidateExtendedParams;
  procedure NB_init_edittable;

{$IFDEF DEBUG_SEMPRA}
 procedure NB_writeser_enabits(cont_word: word);
{$ENDIF}

{$IDATA}

implementation
const
// ErrFlags: Byte;
{
  c_err_cmd:       Byte = 0;    // Bit 0 = +1
  c_err_sd:        Byte = 1;    // Bit 1 = +2
  c_err_finalized: Byte = 2;    // Bit 2 = +4
  c_err_flash:     Byte = 3;    // Bit 3 = +8
  c_err_conf:      Byte = 4;    // Bit 4 = +16
  c_err_upd:       Byte = 5;    // Bit 5 = +32
  c_err_param:     Byte = 6;    // Bit 5 = +64

  c_ErrStrArr      : array[0..6] of String[10] = (
  '[CMD ERR]', '[SD ERR]', '[FIN ERR]', '[DF ERR]',
  '[CONF ERR]', '[UPD ERR]', '[PAR ERR]');
}
  ErrSubCh: Integer = 255;

  knob_to_vibtab3_lut: table[0..7] of byte =
    ( 1, 9, 2, 10, 3, 11, 10, 10);     // V1..C3

  knob_to_vibtab4_lut: table[0..7] of byte =
    ( 1, 9, 2, 10, 4, 12, 12, 12);     // V1..C3


{$IDATA}
structconst
//                                           OUT0 OUT1 XOR0 XOR1 DDR0       DDR1
  PCA9535iniTab: array[0..7] of byte =(0, 8, $FF, $FF, $00, $00, %11111111, %11110000);

var
  temp_I2Cbuffer24:   Array[0..23] of byte;
  temp_I2Cbuffer24_flag[@temp_I2Cbuffer24 + 23]: Boolean;

procedure NB_PercKnobToTabs;
begin
  if edit_PercKnob < 8 then
    FillBlock(@edit_LogicalTab_PercOn, 4, 0);
    edit_PercKnob:= 7;
  else
    edit_LogicalTab_PercOn:= Bit(edit_PercKnob, 3);
    edit_LogicalTab_PercSoft:= Bit(edit_PercKnob, 2);
    edit_LogicalTab_PercFast:= Bit(edit_PercKnob, 1);
    edit_LogicalTab_Perc3rd:= Bit(edit_PercKnob, 0);
  endif;
end;

procedure NB_TabsToPercKnob;
begin
  edit_PercKnob:= 0;
  Setbit(edit_PercKnob, 3, edit_LogicalTab_PercOn);
  Setbit(edit_PercKnob, 2, edit_LogicalTab_PercSoft);
  Setbit(edit_PercKnob, 1, edit_LogicalTab_PercFast);
  Setbit(edit_PercKnob, 0, edit_LogicalTab_Perc3rd);
  if edit_PercKnob < 8 then
    edit_PercKnob:= 7;
  endif;
end;

procedure NB_TabsToReverbKnob;
begin
  edit_ReverbKnob:= 0;
  Setbit(edit_ReverbKnob, 0, edit_LogicalTab_Reverb1);
  Setbit(edit_ReverbKnob, 1, edit_LogicalTab_Reverb2);
end;

procedure NB_VibknobToVCbits;
// setzt Vibrato-Knopfstellung in logische Tab-Stellung für LEDs um
begin
  if (edit_VibKnobMode = 3) then
    FillBlock(@edit_LogicalTab_VibBtns, 6, 0);
    edit_LogicalTab_VibBtns[edit_VibKnob]:= true;
  elsif (edit_VibKnobMode > 0) then
    if edit_VibKnobMode = 1 then
      m:= gettable(knob_to_vibtab3_lut, edit_VibKnob);
    else  // edit_VibKnobMode = 2
      m:= gettable(knob_to_vibtab4_lut, edit_VibKnob);
    endif;
    edit_LogicalTab_4V1:= Bit(m, 0);
    edit_LogicalTab_4V2:= Bit(m, 1);
    edit_LogicalTab_4V3:= Bit(m, 2);
    edit_LogicalTab_4VCh:= Bit(m, 3);
  endif;
  // nur Knob-Stellung berücksichtigen:
  FillBlock(@edit_LogicalTab_VibBtns_flag, 6, 0);
  MenuRefresh:= true;
end;

procedure NB_VCbitsToVibknob;
// setzt logische Tab-Stellung für LEDs in Vibrato-Knopfstellung um
begin
  // Sonderfall Button Vibrato mit gegenseitiger Auslösung, V/C einzeln
  // nur Vib-Tabs
  if (edit_VibKnobMode = 3) then
    edit_VibKnob:= 0;
    for i:= 1 to 5 do
      if edit_LogicalTab_VibBtns[i] then  // anderer Btn als V1 aktiv?
        edit_VibKnob:= i;
      endif;
    endfor;
  elsif (edit_VibKnobMode > 0) then
    if edit_VibKnobMode = 1 then
      edit_VibKnob:= 4;  // Default V3 in Stellung 00, 11
      if (edit_LogicalTab_4V1 and edit_LogicalTab_4V2) = false then
        if edit_LogicalTab_4V2 then
          edit_VibKnob:= edit_VibKnob - 2;
        elsif edit_LogicalTab_4V1 then
          edit_VibKnob:= edit_VibKnob - 4;
        endif;
      endif;
      edit_VibKnob:= valueTrimLimit(edit_VibKnob, 0, 4);
    elsif edit_VibKnobMode = 2 then
      edit_VibKnob:= 0;
      if edit_LogicalTab_4V2 then
        edit_VibKnob:= 2;
      elsif edit_LogicalTab_4V3 then
        edit_VibKnob:= 4;
      endif;
    endif;
    if edit_LogicalTab_4VCh then
      inc(edit_VibKnob);
    endif;
    edit_VibKnob_flag:= c_control_event_source;
  endif;
  MenuRefresh:= true;
end;

{$IFDEF DEBUG_SEMPRA}
procedure NB_writeser_enabits(cont_word: word);
begin
  serout(#9);
  for i:= 11 downto 8 do
    if Bit(cont_word, i) then
      write(serout, '1');
    else
      write(serout, '0');
    endif;
  endfor;
  write(serout, '.');
  for i:= 7 downto 4 do
    if Bit(cont_word, i) then
      write(serout, '1');
    else
      write(serout, '0');
    endif;
  endfor;
  write(serout, '.');
  for i:= 3 downto 0 do
    if Bit(cont_word, i) then
      write(serout, '1');
    else
      write(serout, '0');
    endif;
  endfor;
  writeln(serout);
end;
{$ENDIF}

// #############################################################################

procedure NB_CheckForLive;
begin
  UpperSecondaryActive:= edit_UpperVoice = edit_2ndDBselect;
  UpperIsLive:= UpperSecondaryActive or (edit_UpperVoice = 0);

  LowerSecondaryActive:= edit_LowerVoice = edit_2ndDBselect;
  LowerIsLive:= LowerSecondaryActive or (edit_LowerVoice = 0);

  UpperSecondaryActive_DB9_MPX:= UpperSecondaryActive and (edit_ADCconfig = 2);
  LowerSecondaryActive_DB9_MPX:= LowerSecondaryActive and (edit_ADCconfig = 2);
  if (edit_ADCconfig <> 2) then
    UpperSecondaryActive_DB9_MPX_old:= false;
    LowerSecondaryActive_DB9_MPX_old:= false;
  endif;
end;

procedure NB_ResetSpecialFlags;
begin
  FillBlock(@edit_voices_flag, 4, 0);
  FillBlock(@edit_LogicalTab_Specials, 16, 0);
  FillBlock(@edit_LogicalTab_IncDecBtns_flag, 16, 0);
end;


function NB_GetBytefromI2Cslave(const i2c_addr, idx: Byte; var data: Byte): Boolean;
begin
{$IFDEF MODULE}
  return(false);
{$ELSE}
  if TWIstat(i2c_addr) then
    udelay(10); // immer nach TWIstat
    TWIout(i2c_addr, idx); // Index im Buffer
    udelay(10); // für FatarScan76 nötig!
    TWIinp(i2c_addr, data);
    return(true);
  else
    return(false);
  endif;
{$ENDIF}
end;

function NB_SendBytetoI2Cslave(const i2c_addr, idx, data: Byte): Boolean;
begin
{$IFDEF MODULE}
  return(false);
{$ELSE}
  if TWIstat(i2c_addr) then
    udelay(10); // immer nach TWIstat
    TWIout(i2c_addr, idx, data); // Index im Buffer
    return(true);
  else
    return(false);
  endif;
{$ENDIF}
end;

function NB_ManualDefaultsToI2Cslave(const manual: Byte): Boolean;
var i2c_addr: Byte;
begin
{$IFDEF MODULE}
  return(false);
{$ELSE}
  i2c_addr:= $5A + manual;
  if TWIstat(i2c_addr) then
    udelay(5); // immer nach TWIstat
    for i:= 0 to 22 do
      temp_I2Cbuffer24[i]:= eep_fs76_arr[manual, i];
    endfor;
    temp_I2Cbuffer24_flag:= true;
    TWIout(i2c_addr, 0, temp_I2Cbuffer24); // Alles aus Buffer an I2C-Slave
    return(true);
  else
    return(false);
  endif;
{$ENDIF}
end;


procedure NB_CheckDFUmsg;
begin
{$IFDEF MODULE}
  DFUrunning:= false;
{$ELSE}
  if FPGA_OK then
    ReceiveFPGA(1);
    if FPGAreceiveLong0 <> 0 then
      if LCDpresent and (not DFUrunning) and IsSysTimerZero(ActivityTimer) then
        MenuIndex_Requested:= MenuIndex; // zurück
        LCDxy_M(LCD_m1, 0, 0);
        write(LCDOut_M, 'DSP Update (DFU)');
        LCDxy_M(LCD_m1, 0, 1);
        write(LCDOut_M, 'running...      ');
      endif;
      setSysTimer(ActivityTimer, 25); // Refresh verhindern
    endif;
    if DFUrunning and (FPGAreceiveLong0 = 0) then
      writeln(serout, '/ DFU Update ended');
    endif;
    DFUrunning:= FPGAreceiveLong0 <> 0;
  endif;
{$ENDIF}
end;


procedure NB_CreateInverseCCarrays;
// CC-Arrays für MIDI IN/OUT anlegen
// ch enthält auch Flags: Bit 4 = Inverted, Bit 5 = Scaled
var my_idx: Integer;
    cc, ch: Byte;
begin
  UseSustainSostMask:= $80;
  FillBlock(@CCarray, 1024, 255); // -1 = ungültiger Parameter
  // Index auf CCarray_i: ch*128 + cc
  // Index auf MIDIset_Array: Param-1000 wenn 1000..1751
  // MIDIset_Arrays enthalten zum Parameter (100)0..(1)751
  // den passenden Kanal (InverseCHarray) und CC-Nummer (InverseCCarray)
  for my_idx:= 0 to 767 do
    ch:= MIDIset_CHarray[my_idx] and $0F; // obere 4 Bits = Flags
    if valueInRange(ch, 0, 3) then
      cc:= MIDIset_CCarray[my_idx];
      if cc < 128 then
        CCarray_i[ch, cc]:= my_idx + 1000;
      endif;
      if (cc = 64) or (cc = 66) then
        UseSustainSostMask:= 0;  // belegt, Sustain und Sostenuto NICHT benutzen
      endif;
    endif;
  endfor;
{$IFDEF DEBUG_MIDI}
  writeln(serout, '/ (NB) CCarrInvert');
{$ENDIF}
end;

procedure NB_CCarrayFromDF(const cc_set: Byte);
// cc_set 0..11
begin
  // Custom-Array von DF laden
  // 4096 Bytes = 1 BlockRAM
  // 0..1: Scan Core,     Block: c_scan_base
  // 9: EEPROM Backup,
  // 10: DSP Core,
  // 11..14: Tapering
  // 15: FIR filter
  // 16 ff.: Wavesets
  DF_readblock(c_midicc_base_DF + word(cc_set), c_midiarr_dflen);
  // BlockBuffer8 enthält jetzt Block aus 4 x 768 Parametern
  // CH- und CC-Nummern sowie min und max
  // plus 4x128 min- und 4x128 max-Werte
  // NRPN-Array getrennt von CCs ab Index 3072
  // ValueLong0,1 = NRPN, Funktion = ValueLong2, Channel und Mode = ValueMode3
  CopyBlock(@BlockBuffer8, @MIDIset_Array, c_midiarr_len);
  if (MIDIset_CCdisplayedName[0] > 15) then
    MIDIset_CCdisplayedName:= 'CC invalid!';
  endif;
{$IFDEF DEBUG_MIDI}
  writeln(serout, '/ (NB) CCarrFromDF ' + ByteToStr(cc_set));
{$ENDIF}
  NB_CreateInverseCCarrays;
end;


// #############################################################################

procedure NB_init_edittable;
// Defaults aus Flash für Preset-Initialisierung
var idx_w: Word;
begin
  for idx_w:= 0 to 495 do
    edit_array[idx_w]:= eep_defaults[idx_w];
  endfor;
  edit_LocalEnable:= 7;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure NB_CreateInverseMenuArr;
// Das RestoreArray entscheidet, ob ein Wert aus CommonPresets übernommen wird
// anhand edit_RestoreCommonPresetMask und c_MenuSaveDestArr setzen
// Legt auch Param2MenuInverseArray an!
var
  my_param, my_idx: Integer;

begin
  FillBlock(@Param2MenuInverseArray, 512, 255);  // alle unbelegt
  // edit_RestoreCommonPresetMask Bits 1 bis 6 im Menü
  for i:= 0 to c_MenuLen - 1 do      // im Menü, falls save_dest < EEPROM
    my_param:= c_Index2ParamArr[i];
    if valueInRange(my_param, 1000, 1494) then
      my_idx:= my_param - 1000;
      Param2MenuInverseArray[my_idx]:= i;
    endif;
  endfor;

  FillBlock(@Param2MenuInverseArray + 128, 4, c_PercMenu);    // Percussion #10
  FillBlock(@Param2MenuInverseArray + 140, 2, c_ReverbMenu);  // Reverb
  FillBlock(@Param2MenuInverseArray + 160, 11, c_EnvEnaUpperMenu);  // H100 Perc/Ena Upper
  FillBlock(@Param2MenuInverseArray + 212, 6, c_VibKnobMenu);   // Vibrato Buttons
  // TODO!
//  FillBlock(@Param2MenuInverseArray + 144, 8, c_PhrMenu);     // PHR
//  FillBlock(@Param2MenuInverseArray + 152, 4, c_GatingMenu);  // Gating Mode
//  FillBlock(@Param2MenuInverseArray + 216, 2, c_KeybTransposeMenu);  // Transpose Up/Down
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


procedure NB_ValidateExtendedParams;
// Ungültige Werte anhand nicht freigegebener Bedienelemente setzen
var
   my_param: Integer;
   my_idx, my_mask: byte;
begin
  for my_idx:= 0 to c_MenuLen do
    my_mask:= c_MenuMaskArr[my_idx];
    if (not HasExtendedLicence) and (not Bit(my_mask, 6)) then
      // Eintrag ungültig, Default-Wert 0 in edit_table
      my_param:= c_Index2ParamArr[my_idx];
      if my_param >= 1000 then
        edit_array[my_param - 1000]:= 0;
      endif;
    endif;
  endfor;
end;


// #############################################################################
// Various functions
// #############################################################################

{
procedure NB_pulse(const p_len: byte); // neg. Impuls für Messungen mit LA
begin
  excl(PortD, 3);
  udelay(p_len);
  incl(PortD, 3);
end;
}

procedure NB_LoadLeslieInits;
begin
  for i:= 3 to 63 do
    edit_LeslieInits[i]:= eep_LeslieInits[i];
  endfor;
end;

procedure NB_LoadPhasingSet(const my_phr_preset: byte);
begin
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ (NB) Load PHR prg #'+ byteToSTr(my_phr_preset));
{$ENDIF}
  for i:= 0 to 15 do
    edit_PhasingGroup[i]:= eep_PhasingRotorSets[my_phr_preset, i];
  endfor;
  edit_CurrentPhasingSet:= my_phr_preset;
  edit_PhasingGroup_flag[0]:= c_board_event_source;
end;

// #############################################################################

procedure NB_SerSendBlockArray(const len_w: Word);
// Sendet Speicherauszug BlockBuffer8, Anzahl len_w Bytes
// Format: $55 $AA STX <4K data> CC cc ETX mit CC cc = 16-Bit-Summe aller Datenbytes
var  idx_w, checksum: Word; retry: byte;
begin
  Serout($55);
  Serout($AA);
  serout(#2); // STX senden
  checksum:= 0;
  for idx_w:= 0 to len_w - 1 do
    i:= BlockBuffer8[idx_w];
    Serout(i);
    checksum:= checksum + word(i);
    if idx_w mod 128 = 0 then
      retry:= 0;
      repeat
        serinp_to(m, 50);
        inc(retry);
      until (m = $06) or (retry > 7);
    endif;
  endfor;
  Serout(hi(checksum));
  Serout(lo(checksum));
  serout(#3); // ETX senden
end;


// #############################################################################
// ###                             EVENT-SENDER                              ###
// #############################################################################

// Routinen zum binär kodierten Senden (schneller als Parser in Klartext)

function NB_SendBinaryHeader(const cmd: byte; const param_num: Integer):byte;
// sendet einen binär kodierten Header ohne Länge an BLE bzw. serielle Schnittstelle
// ESC CMD ADRL ADRH
// liefert CRC zurück
var
  my_temp_crc : byte;
begin
  serout(27);   // ESC
  my_temp_crc:= 27;
  serout(cmd);     // CMD
  my_temp_crc:= my_temp_crc + cmd;
  serout(lo(param_num));    // ADRL, ADRH
  my_temp_crc:= my_temp_crc + lo(param_num);
  serout(hi(param_num));
  my_temp_crc:= my_temp_crc + hi(param_num);
  return(my_temp_crc);
end;

procedure NB_BlockRcvMsg(const my_block: Integer);
begin
{$IFNDEF MODULE}
  LCDclr_M(LCD_m1);
  LCDxy_M(LCD_m1, 0, 0);
  write(LCDOut_M, 'Data received');
  LCDxy_M(LCD_m1, 0, 1);
  write(LCDOut_M, 'Block #' + IntToSTr(my_block));
  LED_timer1000;
{$ENDIF}
  MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
end;

function NB_WaitACK(const add_timeout: Byte): Boolean;
begin
  for i:= 0 to 25 + add_timeout do   // Timeout
    mdelay(1);
    if serStat then
      if (serInp = #6) then
        return(true);  // ACK
      endif;
    endif;
  endfor;
  return(false);
end;

procedure NB_SendBinaryBlock(const param_num: Integer; const len: Byte);
// mit Event-CMD #5: Erwarte Bestätigung nach Bearbeitung
// ESC CMD ADRL ADRH LEN DATA0...DATAn CHK, hier also
// 27  4/5 ADRL ADRH  1  <vals...>     CHK
// len=1: nur 1 Byte senden
// param_num nur im Bereich 1000..1511!
var
  chksum, retry, idx, my_val, cmd: byte;
  edit_idx: Integer;
  done: Boolean;
begin
  if ConnectMode = t_connect_osc_wifi then // OSC connected By Serial
    cmd:= 5; // mit Bestätigung
  else
    cmd:= 4;
  endif;
  retry:= 0;
  done:= false;
  repeat
    if ConnectMode = t_connect_osc_wifi then
      FlushBuffer(RxBuffer);
    endif;
    chksum:= NB_SendBinaryHeader(cmd, param_num); // Event = 4 oder 5
    serout(len);
    inc(chksum, len);
    edit_idx:= param_num - 1000;
    for idx:= 0 to len-1 do
      my_val:= edit_array[edit_idx];
      inc(chksum, my_val);
      serout(my_val);        // Wert
      inc(edit_idx);
    endfor;
    serout(chksum);     // CHK
    if ConnectMode = t_connect_osc_wifi then
      done:= NB_WaitACK(len);   // Timeout
    else
      done:= true; // nur einmal ausführen wenn kein ACK erwartet
    endif;
    inc(retry);
  until done or (retry > 3);
end;

procedure NB_SendBinaryVal(const param_num: Integer; const value: byte);
var
  chksum, retry, cmd: byte;
  done: Boolean;
begin
  if ConnectMode = t_connect_osc_wifi then
    cmd:= 5;
  else
    cmd:= 4;
  endif;
  retry:= 0;
  done:= false;
  repeat
    chksum:= NB_SendBinaryHeader(cmd, param_num); // Event = 4 oder 5
    serout(1);     // LEN = 1
    inc(chksum);
    serout(value);        // Wert
    inc(chksum, value);
    serout(chksum);     // CHK
    if ConnectMode = t_connect_osc_wifi then
      done:= NB_WaitACK(0);   // Timeout 25ms
    else
      done:= true; // nur einmal ausführen wenn kein ACK erwartet
    endif;
    inc(retry);
  until done or (retry > 3);
end;

// #############################################################################


procedure NB_SendBinaryAllOSCvals;
var idx: Word;
begin
  for idx:= 0 to 2 do           // Drawbars, 12 Werte
    NB_SendBinaryBlock(1000 + (idx * 16), 12);
    mdelay(15);
  endfor;
  for idx:= 0 to 3 do           // ADSRs
    NB_SendBinaryBlock(1048 + (idx * 8), 5);
    mdelay(10);
  endfor;
  NB_SendBinaryBlock(1080, 11);  // Volumes, 11 Werte
  mdelay(15);
  NB_SendBinaryBlock(1096, 12);  // EG Env DBs
  mdelay(15);
  NB_SendBinaryBlock(1112, 10);  // Equalizer, 10 Werte
  mdelay(15);
  for idx:= 0 to 3 do           // TABs
    NB_SendBinaryBlock(1128 + (idx * 16), 16);
    mdelay(15);
  endfor;
  NB_SendBinaryBlock(1224, 24);   // GM Voices
  mdelay(20);
  NB_SendBinaryBlock(1264, 9);   // Presets/Knobs
  mdelay(10);
  NB_SendBinaryBlock(1320, 14);   // Vibrato Params
  mdelay(10);
  NB_SendBinaryBlock(1448, 12);   // Rotary Live Params
  mdelay(10);
  NB_SendBinaryBlock(1480, 12);   // Rotary Live Params
  mdelay(10);
  NB_SendBinaryVal(1610, 127);  // Connect Button ON, mit ACK
  FillBlock(@edit_array_flag, 496, 0);
end;

// #############################################################################

procedure NB_InitPCA9532_dim(const my_adr, my_dim: byte);
// initialisiert PCA9532, LEDs aus
// ACHTUNG: AutoInc funktioniert beim PCA9532 aus unbekannten Gründen
// NICHT bei PSC- und PWM-Registern, deshalb hier "zu Fuß":
// %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
var my_dim_2: Byte;
begin
{$IFNDEF MODULE}
  my_dim_2:= mulDivByte(my_dim, 15, 100) + 1;   // 15% Helligkeit von hell
  TWIout(my_adr, 2, 0);   // PWM_0-Frequ hoch
  TWIout(my_adr, 3, my_dim_2);   // PWM_0, darker
  TWIout(my_adr, 4, 0);   // PWM_1-Frequ hoch
  TWIout(my_adr, 5, my_dim); // PWM_1, brighter
{$ENDIF}
end;

procedure NB_SetLEDdimmer;
// %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
var my_dim: Byte;
begin
{$IFNDEF MODULE}
  my_dim:= (edit_LED_PWM + 1) * edit_LED_PWM + 15;
  for i:= 0 to 5 do
    if PanelsPresent[i] then
      NB_InitPCA9532_dim(PCA9532_0 + i, my_dim);
    endif;
  endfor;
  for i:= 6 to 7 do         // XB2 LEDs
    if PanelsPresent[i] then
      NB_InitPCA9532_dim(PCA9532_0 + i, 255);
    endif;
  endfor;
{$ENDIF}
end;

end nuts_and_bolts.


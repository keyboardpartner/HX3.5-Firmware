// #############################################################################
// ###                       MIDI LOWLEVEL-FUNKTIONEN                        ###
// #############################################################################

unit MIDI_com;

interface

uses var_def, const_def, fpga_if, nuts_and_bolts;


  // zwei 7-Bit-Fragmente zu einem Word zusammenbasteln
  function MIDI_14_to_int(const msb, lsb: byte): integer;
//  procedure int_to_MIDI_14(var msb, lsb: Byte; my_param: integer);
  // aus Konstanten, wenn from_custom TRUE aus EEPROM Custom

  procedure MIDI_send_7plus1_bytes(var my_buf_adr: Integer; var checksum: Byte);

  procedure MIDI_SendByte(const myparam: byte);
  procedure MIDI_SendInt(const my_int: Integer);
  procedure MIDI_SendChar(const myparam: char);

  procedure MIDI_SendNRPN(const my_nrpn: Integer; const my_val: byte);
  procedure MIDI_SendController(const my_channel_offset, my_ctrl, my_val: byte);
  procedure MIDI_SendPitchwheel(const my_channel_offset, my_val: byte);
  procedure MIDI_SendSustainSostEnable;

  Procedure MIDI_SendIndexedController(idx: Word; scaled_val: Byte);
  procedure MIDI_RequestAllGMnames;
  procedure MIDI_SendAllOSCvals;
  procedure MIDI_ResetGMprogs;
  procedure MIDI_SendProgramChange(const my_channel_offset, my_val: byte);
  procedure MIDI_SendChangedSwell(my_val: byte);
  procedure MIDI_SendBoolean(const my_channel_offset, my_ctrl: byte; const my_bool: boolean);
  procedure MIDI_SendVent;
  // werden schon hier und in apply_changes gebraucht
  procedure MIDI_SendSysExParamList(const start_param, count: Integer);
  procedure MIDI_SendSysExParam(const my_param, my_val: Integer);
  procedure MIDI_SendSysEx_header_ID(const my_cmd_id: Byte);
  procedure MIDI_SendSysEx_end;
  procedure MIDI_SendSysEx_header;

implementation

var
{$IData}
  midi_old_swell: byte;
  send_ch: Byte;

procedure MIDI_SendSustainSostEnable;
begin
  SendByteToFPGA(edit_MIDI_Option or UseSustainSostMask, 5);  // MIDI-Option
{$IFNDEF MODULE}
  MIDI_SendNRPN($3513, UseSustainSostMask shr 1); // an GM
{$ENDIF}
end;

procedure MIDI_ResetGMprogs;
begin
{$IFNDEF MODULE}
  MIDI_SendNRPN($3550, edit_UpperGMprg_0);
  MIDI_SendNRPN($3551, edit_LowerGMprg_0);
  MIDI_SendNRPN($3552, edit_PedalGMprg_0);
  mdelay(10);
  MIDI_SendNRPN($3554, edit_UpperGMprg_1);
  MIDI_SendNRPN($3555, edit_LowerGMprg_1);
  MIDI_SendNRPN($3556, edit_PedalGMprg_1);
{$ENDIF}
  mdelay(10);
end;

procedure MIDI_RequestAllGMnames;
begin
  for i:= 0 to 6 do
    if i = 3 then
      continue;
    endif;
    GM_VoiceNames[i]:='(unknown)';
    GM_VoiceNameToDisplaySema[i]:= false;
    GM_VoiceNameReceivedFlags[i]:= false;
{$IFNDEF MODULE}
    MIDI_SendNRPN($3570 + Integer(i), 127); // Namen anfordern
    mdelay(3);
{$ENDIF}
  endfor;
end;

Procedure MIDI_SendIndexedController(idx: Word; scaled_val: Byte);
// idx weist auf Eintrag in MIDIset-CC-Tabelle
// berechnet scaled_val anhand Flags neu, sendet Controller anhand Index
// liefert TRUE wenn in Tabelle gefunden und gesendet
// edit_array_flag-Bitpositionen
// c_sendfpga:Byte = 0;
// c_sendserial:Byte = 1;
// c_sendmidicc:Byte = 2;
// c_sendsysex:Byte = 3;
var
  mode, ch, cc, cc_min, cc_max, arr_idx: Byte;
// threshold: Byte;
begin
  ch:= MIDIset_CHarray[idx];
  if ch <> 255 then               // gültig?
    cc:= MIDIset_CCarray[idx]; // Params 1000..1511
    cc_min:= MIDIset_CCminArray[idx];
    cc_max:= MIDIset_CCmaxArray[idx];
    // threshold:= (cc_max + cc_min) div 2 ;  // Schaltschwelle für Tabs
    mode:= ch shr 4; // oberes Nibble nach unten, enthält Flags
    ch:= ch and $0F;
    case mode of     // Limit, SCale, Ignore, Invert, Toggle
      1: // Scale to min/max
        n:= cc_max - cc_min;      // Wertebereich
        if n > 0 then
          scaled_val:= mulDivByte(scaled_val, n, 127) + cc_min;
        endif;
        if scaled_val > cc_max then
          scaled_val:= cc_max;
        endif;
        |
      3: // Invert value
        scaled_val:= valueTrimLimit(scaled_val, cc_min, cc_max);
        scaled_val:= cc_max + cc_min - scaled_val;
        |
      4: // Toggle value
        scaled_val:= cc_max;
        |
(*
      5: // Threshold
        if scaled_val >= threshold then
          scaled_val:= cc_max;
        else
          scaled_val:= cc_min;
        endif;
        |
      6: // Inverted Threshold
        if scaled_val >= threshold then
          scaled_val:= cc_min;
        else
          scaled_val:= cc_max;
        endif;
        |
      7: // within Range
        if (scaled_val >= cc_min) and (scaled_val <= cc_max) then
          MIDI_SendController(ch, cc, scaled_val);
          return; // sonst NICHT senden
        endif;
        |
*)
      8: // Mult/Div value
        scaled_val:= mulDivByte(scaled_val, cc_min, cc_max);
        scaled_val:= valueTrimLimit(scaled_val, 0, 127);
        |
    else   // Limit to min/max,  Ignore out of range
      scaled_val:= valueTrimLimit(scaled_val, cc_min, cc_max);
    endcase;
    if cc = 6 then // NRPN mitsenden, so vorhanden
      for arr_idx:= 0 to 31 do
        if idx = Word(MIDIset_NRPNarray[arr_idx].EditIdx) then
          MIDI_SendNRPN(MIDIset_NRPNarray[arr_idx].NRPN, scaled_val);
          break;
        endif;
      endfor;
    else
      if valueInRange(idx, 0520, 0531) then
        // Fest eingestellter Kanal für Send-Only-Funktion
        MIDI_SendByte($B0 + ch);  // Control Change
        MIDI_SendByte(cc);
        MIDI_SendByte(scaled_val);
      else
        MIDI_SendController(ch, cc, scaled_val);
      endif;
    endif;
  endif;
end;

procedure MIDI_SendAllOSCvals;
var my_val: Byte; idx: Word;
begin
  for idx:= 0 to 511 do
    my_val:= edit_array[idx];
    MIDI_SendIndexedController(idx, my_val);
    edit_array_flag[idx]:= edit_array_flag[idx] and %11111011;  // Bit 2 löschen
  endfor;
end;

// #############################################################################
// MIDI-Basisfunktionen
// #############################################################################

procedure MIDI_SendNRPN(const my_nrpn: Integer; const my_val: byte);
// benötigt für Piano- und Reverb-Fernsteuerung
begin
  if (my_nrpn and $8080) = 0 then // $0000..$7F7F
    MIDI_SendController(0, $62, lo(my_nrpn));   // LSB
    MIDI_SendController(0, $63, hi(my_nrpn));   // MSB
    MIDI_SendController(0, 6, my_val);
    udelay(40);
  endif;
end;

procedure MIDI_SendSysExParam(const my_param, my_val: Integer);
// Parameter und Wert über MIDI-SysEx senden
// für Event-Messages an Editor, schneller als Klartext
// Format: F0 00 20 04 33 06 PP pp VV vv F7
// PP pp = 14Bit-Parameter-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// VV vv = 14Bit-Parameter-Wert (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
begin
  MIDI_SendSysEx_header_ID($06);
  MIDI_SendInt(my_param);
  MIDI_SendInt(my_val);
  MIDI_SendSysEx_end;
end;

procedure MIDI_SendSysExParamList(const start_param, count: Integer);
// Parameterliste (1000..1511) über MIDI-SysEx senden
// für Event-Messages an Editor, schneller als Klartext
// SysEx Cmd 0A, abgefragte Parameterliste, wir senden:
// F0 00 20 05 33 0A PP pp VV vv VV vv VV vv VV vv ... [00] F7
// VV vv = 14Bit-Parameter-Wert (0VVVVVV 0vvvvvvv wird zu 00VVVVVV Vvvvvvvv)
var param_idx: Integer;
begin
  MIDI_SendSysEx_header_ID($0A);
  MIDI_SendInt(start_param);
  for param_idx:= start_param to start_param + count - 1 do
    MIDI_SendInt(Integer(edit_array[param_idx - 1000]));
  endfor;
  MIDI_SendSysEx_end;
end;

procedure MIDI_SendSysEx_header;
begin
  SysExID_long:= $042000F0;  // umgekehrte Folge in LongInt!
  for i := 0 to 3 do
    MIDI_SendByte(SysExArray[i]);
  endfor;
end;


procedure MIDI_SendSysEx_header_ID(const my_cmd_id: Byte);
begin
  MIDI_SendSysEx_header;
  MIDI_SendByte($33);
  MIDI_SendByte(my_cmd_id);
end;

procedure MIDI_SendSysEx_end;
begin
  MIDI_SendByte($F7);
end;

// Achtung: FIFO nur 16 Bytes groß, deshalb Delays!
// Statusbyte auf SPI (0):
// Bit 7 = 1: hat Status, 0: alte Version
// Bit 5/4 = MIDI TO SAM Buffer full/almost_full
// Bit 3/2 = MIDI UART Buffer full/almost_full
// Bit 1/0 = AVR FIFO Buffer full/almost_full

procedure MIDI_SendByte(const my_byte: byte);
var buffer_full: boolean;
begin
  if FPGA_OK then
    if FPGA_UpToDate then  // aktuelles FPGA?
      // Warten bis gesendet oder Buffer wieder aufnahmebereit
      repeat
        ReceiveFPGA(0); // STATUS anfordern
        buffer_full:= (FPGAreceiveLong0 and 3) <> 0;
        if buffer_full then
          mdelay(2);   // kritischer Füllstand, Buffer leert sich um 6 Bytes
        endif;
      until not buffer_full;
    else
      udelay(40);
    endif;
    SendByteToFPGA(my_byte, $0C);
  endif;
end;

procedure MIDI_SendChar(const my_char: char);
begin
  MIDI_SendByte(byte(my_char) and $7F);
end;


procedure MIDI_SendController(const my_channel_offset, my_ctrl, my_val: byte);
// falls my_channel_offset 5..15, Kanal direkt und
// ohne Berücksichtigung von edit_MIDI_Channel senden
begin
  if my_channel_offset > 4 then
    send_ch:= my_channel_offset;
  else
    send_ch:= valuetrimlimit(edit_MIDI_Channel + my_channel_offset, 0, 15);
  endif;
  MIDI_SendByte($B0 + send_ch);  // Control Change
  MIDI_SendByte(my_ctrl);
  MIDI_SendByte(my_val and $7F);
end;

procedure MIDI_SendPitchwheel(const my_channel_offset, my_val: byte);
// falls my_channel_offset 5..15, Kanal direkt und
// ohne Berücksichtigung von edit_MIDI_Channel senden
begin
  if my_channel_offset > 4 then
    send_ch:= my_channel_offset;
  else
    send_ch:= valuetrimlimit(edit_MIDI_Channel + my_channel_offset, 0, 15);
  endif;
  MIDI_SendByte($E0 + send_ch);  // Pitchwheel
  MIDI_SendByte(0);
  MIDI_SendByte(my_val and $7F);
end;

procedure MIDI_SendBoolean(const my_channel_offset, my_ctrl: byte; const my_bool: boolean);
begin
  MIDI_SendController(my_channel_offset, my_ctrl, byte(my_bool) shr 1);
end;

procedure MIDI_SendProgramChange(const my_channel_offset, my_val: byte);
// falls my_channel_offset 5..15, Kanal direkt und
// ohne Berücksichtigung von edit_MIDI_Channel senden
begin
  if my_channel_offset > 4 then
    send_ch:= my_channel_offset;
  else
    send_ch:= valuetrimlimit(edit_MIDI_Channel + my_channel_offset, 0, 15);
  endif;
  MIDI_SendByte($C0 + send_ch);
  MIDI_SendByte(my_val);   // Program Change
end;

procedure MIDI_SendChangedSwell(my_val: byte);
begin
  if midi_old_swell <> my_val then
    MIDI_SendController(0, edit_SwellCC, my_val);
    midi_old_swell:=  my_val;
  endif;
end;

procedure MIDI_SendVent;
begin
  SendByteToFPGA($B0, 73);  // Control Change
  udelay(50);
  SendByteToFPGA(21, 73);   // Control Change #21
  udelay(50);
  if edit_LogicalTab_LeslieRun then
    if edit_LogicalTab_LeslieFast then
      SendByteToFPGA(2, 73);
    else
      SendByteToFPGA(1, 73);
    endif;
  else
    SendByteToFPGA(0, 73);  // Control Change
  endif;
  udelay(50);
end;

{
procedure FH_AllNotesOff;
begin
  MIDI_SendController(0, 123, 0); // All notes off Upper
  MIDI_SendController(1, 123, 0); // All notes off Lower
  MIDI_SendController(2, 123, 0); // All notes off Pedal
end;
}

// #############################################################################
// ########################### HX3.5 SysEx Send ################################
// #############################################################################

// Parameter setzen, wir haben empfangen:
// F0 00 20 04 33 07 PP pp VV vv ... F7
// mit
// PP pp = 14Bit-Parameter-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// VV vv = 14Bit-Parameter-Wert (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// dieser Block wird sooft wiederholt, bis F7 kommt.
// z.b. F0 0020043307 0400 017F F7  wird zu  Param 512 = 255
// Wir senden Status:
// F0 00 20 04 33 02 <er> F7

// Befehl in Klartext - wir haben empfangen:
// Befehlsformat:
// F0 00 20 04 33 03 <ASCII-TEXT> F7
// ASCII-Text kann ein beliebiger HX3-Parser-Befehl sein
// wir senden Status:
// F0 00 20 04 33 02 <er> F7

// Parameter abfragen - wir haben empfangen:
// F0 00 20 04 33 05 PP pp PP pp ... F7
// PP pp = 14Bit-Parameter-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// dieser Block wird sooft wiederholt, bis F7 kommt.
// wir senden:
// F0 00 20 04 33 06 PP pp VV vv F7
// mit
// PP pp = 14Bit-Parameter-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// VV vv = 14Bit-Parameter-Wert (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// dieser Block wird sooft wiederholt, bis F7 kommt.

// Parameter-Serie abfragen - wir haben empfangen:
// F0 00 20 04 33 09 PP pp NN nn F7
// PP pp = 14Bit-Startparameter-Nummer
// NN nn = 14Bit-Parameter-Anzahl (1 = 1 Wert, 0 unzulässig)
// wir senden:
// F0 00 20 04 33 0A PP pp VV vv VV vv ... F7
// Werte VV vv werden sooft wiederholt, bis F7 kommt.


// Status abfragen, wir haben empfangen:
// F0 00 20 04 33 01 F7
// wir senden Status:
// F0 00 20 04 33 02 <er> F7


// #############################################################################
// MIDI-SYSEX Tools
// #############################################################################

procedure MIDI_send_7plus1_bytes(var my_buf_adr: Integer; var checksum: Byte);
// 7 Bytes aus BlockBuffer8 und gesammelte MSBits dieser 7 Bytes senden
// Adresse und Checksum werden mitgeführt
var msbits: byte;
begin
  msbits:= 0;
  for i := 0 to 6 do
    n:= BlockBuffer8[my_buf_adr];
    if n >= 128 then
      msbits:= (msbits shl 1) or 1;
    else
      msbits:= msbits shl 1;
    endif;
    n:= n and $7F;
    MIDI_SendByte(n);  // 7 Bytes Data
    checksum:= checksum + n;
    inc(my_buf_adr);
  endfor;
  MIDI_SendByte(msbits);  // 1 Byte MSBits
  checksum:= checksum + msbits;
end;

function MIDI_14_to_int(const msb, lsb: byte): integer;
// zwei 7-Bit-Fragmente zu einem Word zusammenbasteln
begin
  return((integer(msb) shl 7) or integer(lsb));
end;

{
procedure int_to_MIDI_14(var msb, lsb: Byte; my_param: integer);
// ein Word in zwei 7-Bit-Fragmente zerlegen
begin
  lsb:= byte(my_param) and $7F;
  msb:= byte(my_param shr 7) and $7F;
end;
}

procedure MIDI_SendInt(const my_int: Integer);
// Integer in zwei MIDI-Bytes umrechnen und senden
var msb, lsb: Byte;
begin
  //int_to_MIDI_14(msb, lsb, my_int);
  lsb:= byte(my_int) and $7F;
  msb:= byte(my_int shr 7) and $7F;
  MIDI_SendByte(msb);
  MIDI_SendByte(lsb);
end;




end MIDI_com.


Unit midi_sysex;

interface
// global part

{ $W+}                  // enable/disable warnings for this unit
{$IFDEF MODULE}
uses var_def, port_def, parser, MIDI_com, nuts_and_bolts;
{$ELSE}
uses var_def, port_def, parser, MIDI_com, display_toolbox, nuts_and_bolts;
{$ENDIF}


  procedure MIDI_Dispatch;

  procedure MIDI_SendSysEx_status;
  procedure MIDI_SendSysExSernum; // Format: F0 00 20 04 33 26 <ASCII-TEXT> 00 F7

  function MIDI_GetSysEx_int(var my_idx: byte; var my_val: Integer): boolean;
  // Standard-Antwort auf Parameter-Änderungen und Fehlerabfrage:
  procedure MIDI_SendSysEx_cmderr;     // F0 00 20 04 33 02 <er> F7
  procedure MIDI_SendSysExParamStr(header_id: Byte); // ID und ParamStr senden


implementation
const
  vk_to_vibknob_arr:Array[0..7] of Byte = (0, 2, 4, 1, 3, 5, 5, 5);

{$IFNDEF MODULE}
procedure MIDIset_CCdisplayRequest;
// aktuell empfangene MIDI-Werte anzeigen:
//      mv:= FPGAreceiveLong0;     // Byte 2, Wert
//      mp:= FPGAreceiveLong1;     // Byte 1, Parameter oder CC
//      mcmd:= FPGAreceiveLong2 and $F0;
//      mch:= FPGAreceiveLong2 and $0F;
var my_idx: Integer;
begin
  if LCDpresent then
    m:= mch or mcmd;
    LCDxy_M(LCD_m1, 0, 1);  // untere Zeile
    write(LCDOut_M, 'MIDI: $');
    write(LCDOut_M, ByteToHex(m));
    LCDOut_M_space;
    write(LCDOut_M, ByteToHex(mp));
    if (mcmd = $C0) and (not edit_MIDI_DisableProgramChange) then  // Program Change
      MenuIndex_Requested:= c_MenuCommonPreset;
    else
      LCDOut_M_space;
      write(LCDOut_M, ByteToHex(mv));
    endif;
    LCDclreol_M(LCD_m1);
    LED_timer1000;
    if mcmd = $B0 then // alle CCs
      my_idx:= CCarray_i[mch, mp]; // liefert Parameter 1000..1751
      m:= 255;
      if valueInRange(my_idx, 1000, 1511) then
        m:= Param2MenuInverseArray[my_idx - 1000] ; // auf Menu wechseln
      endif;
      if m = 255 then
        MenuIndex_Requested:= MenuIndex;
        DisplayHeader('CC not assigned');
      else
        MenuIndex_Requested:= m;
        DisplayHeaderIndexed(MenuIndex_Requested);
      endif;
    endif;
  endif;
end;
{$ENDIF}

// local part

// MIDI interpreter, MIDI_ni muss immer vorhanden sein und ganz oben stehen
// MIDI-CC-Sets:
//  'NI B4 d3c  ' , // 0, interpretiert, teilw. über Custom 'ccset0.dat'
//  'Hammond XK ' , // 1, interpretiert, teilw. über Custom 'ccset1.dat'
//  'Hammond SK ' , // 2, interpretiert, teilw. über Custom 'ccset2.dat'
//  'Versatile  ' , // 3, interpretiert, teilw. über Custom 'ccset3.dat'
//  'Nord C1/C2 ' , // aus DF Core Block c_midicc_base +4, 'ccset4.dat'
//  'VoceDrawbar' , // aus DF Core Block c_midicc_base +5, 'ccset5.dat'
//  'KeyB/Duo   ' , // aus DF Core Block c_midicc_base +6, 'ccset6.dat'
//  'Hamichord  ' , // aus DF Core Block c_midicc_base +7, 'ccset7.dat'
//  'KBP/Touchp ' , // aus DF Core Block c_midicc_base +8, 'ccset8.dat'
//  'Custom 1   ' , // aus DF Core Block c_midicc_base +9, 'ccset9.dat'
//  'Custom 2   ' );// aus DF Core Block c_midicc_base +10,'ccset10.dat'

{$I MIDI_Custom.pas}   // für CC-Sets 4..10
{$I MIDI_ni.pas}
{$I MIDI_sempra.pas}


procedure MIDI_SendSysEx_blockbuf(var my_param, my_count: Integer);
// Daten aus BlockBuffer8 senden, ggf. my_count mod 7 Bytes zuviel!
var calc_cs: Byte;
    my_adr: Integer;
begin
   MIDI_SendInt(my_param);
   MIDI_SendInt(my_count);
   calc_cs:= 0;
   my_adr:= 0;
   repeat
     MIDI_send_7plus1_bytes(my_adr, calc_cs);
   until my_adr >= my_count; // Länge erreicht?
   MIDI_SendByte(calc_cs and $7F);
   MIDI_SendSysEx_end;
end;


procedure midi_set_sysex_mode;
begin
  CmdSentByMIDI:= true;
  CmdSentBySerial:= false;
  if edit_MIDI_Option <> 0 then    // ggf temporär auf Ausgang schalten
    edit_MIDI_Option:= 0;          // Senden hardwaremäßig freigeben
    FH_OrganParamsToFPGA;
  endif;
end;

// #############################################################################
// ######################### HX3.5 SysEx Receive ###############################
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
// Eigene SysEx behandeln. SysEx-ID von Keyswerk/Böhm oder Roland
// SysEx-Anfrage erhalten, steht jetzt in SysEx-Buffer.
// #############################################################################

procedure MIDI_DispatchSysEx;
var my_param, my_val, my_count, my_adr: Integer;
    my_idx, msb, lsb: Byte;
    from_eeprom, my_bool: Boolean;
    sysex_id: Byte;
    block_page, block_page_cs, calc_cs: Byte;
begin

// #############################################################################
// +++++++++++++++++++++++++++ R O L A N D +++++++++++++++++++++++++++++++++++++
// #############################################################################

{$IFNDEF MODULE}
  if (SysExID_short = $41F0) then  // // Reihenfolge F0 41 im Buffer

// #############################################################################
// Rudimentärer Interpreter für Roland VK77, MIDI Kanal 1,2,3
//
// IDX:    0  1  2  3  4  5  6  7  8  9 10 11 12
//        ST Mn Dv Model Co AdrHi AdrLo Da Ck End
// SYSX:  F0 41 10 00 1A 12 01 00 50 00 01 2E F7 - Vib Upper ON
// SYSX:  F0 41 10 00 1A 12 01 00 50 00 00 2F F7 - Vib Upper OFF
//
// SYSX:  F0 41 10 00 1A 12 01 00 50 01 01 2D F7 - Vib Lower ON
// SYSX:  F0 41 10 00 1A 12 01 00 50 01 00 2E F7 - Vib Lower OFF
//
// SYSX:  F0 41 10 00 1A 12 01 00 40 08 00 37 F7 - Second
// SYSX:  F0 41 10 00 1A 12 01 00 40 07 01 37 F7 - PERC ON
// SYSX:  F0 41 10 00 1A 12 01 00 40 07 00 38 F7 - PERC OFF
//
// SYSX:  F0 41 10 00 1A 12 01 00 40 08 01 36 F7 - Third
// SYSX:  F0 41 10 00 1A 12 01 00 40 07 01 37 F7 - PERC ON
// SYSX:  F0 41 10 00 1A 12 01 00 40 07 00 38 F7 - PERC OFF
//
// SYSX:  F0 41 10 00 1A 12 01 00 40 09 01 35 F7 - SOFT ON
// SYSX:  F0 41 10 00 1A 12 01 00 40 09 00 36 F7 - SOFT OFF
//
// SYSX:  F0 41 10 00 1A 12 01 00 40 0A 00 35 F7 - SLOW ON (FAST OFF)
// SYSX:  F0 41 10 00 1A 12 01 00 40 0A 01 34 F7 - SLOW OFF (FAST ON)
//
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 00 2D F7 - V1
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 01 2C F7 - V2
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 02 2B F7 - V3
//
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 03 2A F7 - C1
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 04 29 F7 - C2
// SYSX:  F0 41 10 00 1A 12 01 00 50 02 05 28 F7 - C3

// SYSX:  F0 41 10 00 1A 12 01 00 50 0B 01 23 F7 - Rotary Sound (Bypass) ON
// SYSX:  F0 41 10 00 1A 12 01 00 40 3B 01 03 F7 - Pedal Attack ON
// SYSX:  F0 41 10 00 1A 12 01 00 40 39 01 05 F7 - Pedal Sustain ON
// SYSX:  F0 41 10 00 1A 12 01 00 00 10 01 6E F7 - Pedal To Lower ON

// #############################################################################
    if edit_MIDI_EnaVK77sysex then
      if (SysExModel_0 = $1A) and (SysExCmd = $12)
      and (SysExAdrHiWord = $0001)  then
        my_bool:= SysExData <> 0;
        case SysExAdrLoWord of
          $0050:
            edit_LogicalTab_VibOnUpper:= my_bool;
            edit_LogicalTab_VibOnUpper_flag:= c_midi_sysex_source;
            |
          $0150:
            edit_LogicalTab_VibOnLower:= my_bool;
            edit_LogicalTab_VibOnLower_flag:= c_midi_sysex_source;
            |
          $0250:
            edit_VibKnob:= vk_to_vibknob_arr[SysExData]; // anders sortiert
            edit_VibKnob_flag:= c_midi_sysex_source;
            NB_VibknobToVCbits;
            |
          $0B50:  // Rotary Sound Button --> Spkr Bypass
            edit_LogicalTab_RotarySpkrBypass:= my_bool;
            edit_LogicalTab_RotarySpkrBypass_flag:= c_midi_sysex_source;
            |
          $3940: // Pedal Sustain ON
            if my_bool then
              edit_PedalRelease:= eep_PedalRelease;
            else
              edit_PedalRelease:= 0;
            endif;
            edit_PedalRelease_flag:= c_midi_sysex_source;
            |
          $3B40: // Pedal Attack Button --> Reverb 2
            edit_LogicalTab_Reverb1:= true;
            edit_LogicalTab_Reverb2:= my_bool;
            edit_LogicalTab_Reverb1_flag:= c_midi_sysex_source;
            edit_LogicalTab_Reverb2_flag:= c_midi_sysex_source;
            |
          $0740:
            edit_LogicalTab_PercOn:= my_bool;
            edit_LogicalTab_PercOn_flag:= c_midi_sysex_source;
            |
          $0840:
            edit_LogicalTab_Perc3rd:= my_bool;
            edit_LogicalTab_Perc3rd_flag:= c_midi_sysex_source;
            |
          $0940:
            edit_LogicalTab_PercSoft:= my_bool;
            edit_LogicalTab_PercSoft_flag:= c_midi_sysex_source;
            |
          $0A40:
            edit_LogicalTab_PercFast:= my_bool;
            edit_LogicalTab_PercFast_flag:= c_midi_sysex_source;
            |
        endcase;
      endif;

// #############################################################################
// Roland VK7:  F0 41 10 00 08 12
// VK7 MIDI Kanal 1,2,3
// Noch nicht verifiziert!
// #############################################################################

      if (SysExModel_0 = $08) and (SysExCmd = $12)
      and (SysExAdrHiWord = $0004)  then
        my_bool:= SysExData <> 0;
        case SysExAdr_0 of
          $11:
            edit_LogicalTab_PercOn:= my_bool;
            edit_LogicalTab_PercOn_flag:= c_midi_sysex_source;
            |
          $12:
            edit_LogicalTab_Perc3rd:= my_bool;
            edit_LogicalTab_Perc3rd_flag:= c_midi_sysex_source;
            |
          $13:
            edit_LogicalTab_PercSoft:= my_bool;
            edit_LogicalTab_PercSoft_flag:= c_midi_sysex_source;
            |
          $16:
            edit_LogicalTab_PercFast:= my_bool;
            edit_LogicalTab_PercFast_flag:= c_midi_sysex_source;
            |
          $39:
            edit_LogicalTab_VibOnUpper:= my_bool;        // kein UM!
            edit_LogicalTab_VibOnUpper_flag:= c_midi_sysex_source;
            |
          $3A:
            edit_VibKnob:= vk_to_vibknob_arr[SysExData]; // anders sortiert
            edit_VibKnob_flag:= c_midi_sysex_source;
            NB_VibknobToVCbits;
            |
        endcase;
      endif;
    endif; // edit_MIDI_EnaVK77sysex

// #############################################################################
// +++++++++++++++++++++++++++ S E M P R A +++++++++++++++++++++++++++++++++++++
// #############################################################################

  elsif (SysExID_long = $042000F0) then   // Reihenfolge F0 00 20 04 im Buffer
{$ELSE}
  if (SysExID_long = $042000F0) then   // Reihenfolge F0 00 20 04 im Buffer
{$ENDIF}
    my_idx:= 6;
    if (SysExCmd_sempra = $0000) then

// #############################################################################
// Es kam eine Anfrage an alle: ID senden
// Kennung (Name und Version) senden:
// SysEx: F0 00 20 04 00 01 <ID (33)>
// <16 Bytes ASCII Device-Name>
// <8 Bytes ASCII Version>
// <8 Byte ASCII Release> $F7
// #############################################################################

      midi_set_sysex_mode;
{$IFDEF DEBUG_SYSEX}
      writeln(serout, 'ID Request');
{$ENDIF}
      MIDI_SendSysEx_header;
      MIDI_SendByte(0);
      MIDI_SendByte(1);
      MIDI_SendByte($33);
      for i := 1 to 24 do
        MIDI_SendChar(SysExDeviceStr[i]);
      endfor;

      ReceiveFPGA(3);  // FPGA-Datum lesen, in 8 Zeichen umwandeln
      ParamStr:= LongToHex(FPGAreceiveLong);
      for i := 1 to 8 do
        MIDI_SendChar(ParamStr[i]);
      endfor;
      MIDI_SendSysEx_end;

    elsif (lo(SysExCmd_sempra) = $33) then  // Empfangen: ID für uns
      sysex_id:= hi(SysExCmd_sempra);

// #############################################################################
// Empfangen: Parameter setzen  ($07)
// SysEx: F0 00 20 04 33 07 <PP pp VV vv> F7
// PP pp = Parameter-Nummer (0PPPPPPP 0ppppppp wird zu 00PPPPPP Pppppppp)
// VV vv = Parameter-Wert (0VVVVVV 0vvvvvvv wird zu 00VVVVVV Vvvvvvvv)
// dieser Block wird sooft wiederholt, bis F7 kommt.
// z.b. F0 0020043307 0400 017F F7  wird zu  Param 512 = 255
// #############################################################################

      if (sysex_id = $07) then  // Empfangen: Parameter setzen
        midi_set_sysex_mode;
        repeat
          if not MIDI_GetSysEx_int(my_idx, my_param) then
            break;
          endif;
          if not MIDI_GetSysEx_int(my_idx, my_val) then
            break;
          endif;
          // Sysex kann nur über Editor kommen, kein Feedback
          if not PA_NewParamEvent(my_param, lo(my_val), EEunLocked, c_midi_sysex_source) then
            incl(ErrFlags, c_err_cmd);
          endif;

{$IFDEF DEBUG_SYSEX}
          writeln(serout, '/ ' + IntToSTr(my_param) + '=' + ByteToSTr(lo(my_val)));
{$ENDIF}
        until false;
        // ACK später senden, wenn Änderungen abgeschlossen
        MIDI_SendSysEx_status;

// #############################################################################
// Empfangen: Befehl in Klartext ($03)
// SysEx: F0 00 20 04 33 03 <ASCII-TEXT> [00] F7
// ASCII-Text kann ein beliebiger HX3-Parser-Befehl sein
// #############################################################################

      elsif (sysex_id = $03) then
        midi_set_sysex_mode;
        SerinpStr:='';
        repeat
          m:= SysExArray[my_idx];
          if m = $F7 then
            break;
          endif;
          if m >= 32 then
            SerinpStr:= SerinpStr + char(m);
          endif;
          inc(my_idx);
        until false;
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'CmdStr (03): ' + SerinpStr);
{$ENDIF}
        PA_HandleCmdString;  // wie Befehl über Com-Schnittstelle
        SerinpStr:='';
        // ACK später senden, wenn Änderungen abgeschlossen
        MIDI_SendSysEx_status;

// #############################################################################
// Empfangen: einzelnen Parameter abfragen, Antwort als Klartext ($17)
// SysEx: F0 00 20 04 33 17 PP pp F7
// mit PP pp = Parameter-Nummer
// wir senden:
// F0 00 20 06 33 18 <string> F7
// #############################################################################

      elsif (sysex_id = $17) then
        midi_set_sysex_mode;
        from_eeprom:= false;
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'GetParamText (17): ' + IntToSTr(my_param));
{$ENDIF}
        PA_GetParamString(my_param); // Antwort-String in ParamStr
        MIDI_SendSysExParamStr($18);

// #############################################################################
// Empfangen: einzelnen Parameter 1000...7999 abfragen, Antwort binär ($05)
// SysEx: F0 00 20 04 33 05 PP pp F7
// mit PP pp = Parameter-Nummer
// wir senden:
// F0 00 20 04 33 06 PP pp VV vv F7
// mit
// PP pp = 14Bit-Parameter-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// VV vv = 14Bit-Parameter-Wert (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// #############################################################################

      elsif (sysex_id = $05) then
        midi_set_sysex_mode;
        from_eeprom:= false;
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'GetParamBinary (05): ' + IntToSTr(my_param));
{$ENDIF}
        PA_GetParamByte(my_param, n, false);
        MIDI_SendSysExParam(my_param, Integer(n));

// #############################################################################
// Empfangen: Parameter-Serie abfragen ($09 oder $29 mit CS)
// SysEx: F0 00 20 04 33 09 PP pp NN nn F7
// bzw.
// SysEx: F0 00 20 04 33 29 PP pp NN nn F7 (CS verlangt)
// PP pp = 14Bit-Startparameter-Nummer
// NN nn = 14Bit-Parameter-Anzahl (1 = 1 Wert, 0 unzulässig)
// Wir senden:
// F0 00 20 04 33 0A PP pp VV vv ... F7
// bzw.
// F0 00 20 04 33 2A PP pp NN nn VV vv ... 00 CS F7
// CS = 7-Bit-Prüfsumme über alle Parameter- und DatenBytes PP pp VV vv VV vv...
// Werte VV vv werden N-mal wiederholt, jeweils eine Parameternummer höher
// #############################################################################

      elsif (sysex_id = $09) or (sysex_id = $29) then
        midi_set_sysex_mode;
        from_eeprom:= false;
        if MIDI_GetSysEx_int(my_idx, my_param) then
          if MIDI_GetSysEx_int(my_idx, my_count) then
            if (sysex_id = $29) then
              MIDI_SendSysEx_header_ID($2A);
            else
              MIDI_SendSysEx_header_ID($0A);
            endif;
            // mdelay(2);
{$IFDEF DEBUG_SYSEX}
            writeln(serout, 'GetParams (09): ' + IntToStr(my_param) + ', ' + IntToSTr(my_count) + ' vals');
{$ENDIF}
            MIDI_SendInt(my_param);
            calc_cs:= lo(my_param) + hi(my_param);
            if (sysex_id = $29) then // Anzahl senden, nur wenn Cmd $29
              MIDI_SendInt(my_count);
              calc_cs:= lo(my_count) + hi(my_count);
            endif;
            for my_idx:= 0 to lo(my_count) - 1 do
              if PA_GetParamByte(my_param, m, false) then
                my_val:= integer(m); // Wert holen
              else
                my_val:= 0; // Fehler
                incl(ErrFlags, c_err_cmd);
              endif;
              inc(my_param);
              MIDI_SendInt(my_val);
              calc_cs:= lo(my_val) + hi(my_val);
              //if my_idx mod 2 = 0 then
              //  mdelay(1);
              //endif;
            endfor;
            if (sysex_id = $29) then // Checksum senden, nur wenn Cmd $29
              MIDI_SendByte(0);
              MIDI_SendByte(calc_cs and $7F);
            endif;
            MIDI_SendSysEx_end;
          else
            MIDI_SendSysEx_cmderr;
          endif;
        else
          MIDI_SendSysEx_cmderr;
        endif;

// #############################################################################
// Empfangen: 32 Byte-Segment für Buffer ($20)
// SysEx: F0 00 20 04 33 20 BB <7data> MS <7data> MS <7data> MS ... CC F7
// BB = 7-Bit-Blockseiten-Nummer 0..128, 32 Bytes pro Seite
// CS = 7-Bit-Prüfsumme über alle 32 Daten- und MSBytes
// MS = MSBits der letzten 7 Bytes
// data = n * (7 Bytes Nutzdaten AND $7F, gefolgt von 1 Byte MSBits)
// Beispiel:
// #0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45
// SYSEX-HEADER-- CM BN  0  1  2  3  4  5  6 MS  7  8  9 10 11 12 13 MS 14 15 16 17 18 19 20 MS 21 22 23 24 25 26 27 MS 28 29 30 31 MS CS END
// F0 00 20 04 33 20 00 00 01 02 00 01 7F 7E 0F 44 00 01 02 00 01 7F 47 7E 44 00 01 02 00 01 63 7F 7E 44 00 01 02 00 71 01 7F 7E 44 0F 4D F7
// #############################################################################

      elsif (sysex_id = $20) then
        block_page:= SysExArray[6];
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'GetBlockPage (20): ' + ByteToStr(block_page));
{$ENDIF}
        LED_timer250;   // Timer refreshen
        my_idx:= 7;
        my_adr:= Integer(block_page) * 32;
        calc_cs:= 0;

        repeat
          if my_idx > 38 then
            n:= 3;
          else
            n:= 6;
          endif;
          for i:= 0 to n do
            m:= SysExArray[my_idx];
            calc_cs:= calc_cs + m;
            SysExArrayTemp[i]:= m;
            inc(my_idx);
          endfor;
          msb:= SysExArray[my_idx];  // nach 7 Bytes folgt ein Byte mit allen MSBits
          inc(my_idx);
          calc_cs:= calc_cs + msb;
          for i:= n downto 0 do
            m:= SysExArrayTemp[i];
            if Bit(msb, 0) then
              SysExArrayTemp[i]:= m or 128;
            endif;
            msb:= msb shr 1;
          endfor;
          for i:= 0 to n do
            BlockBuffer8[my_adr]:= SysExArrayTemp[i];
            inc(my_adr);
          endfor;
        until (my_idx > 43);
        block_page_cs:= SysExArray[my_idx];   // Prüfsumme über alle Datenbytes
        calc_cs:= calc_cs and $7F;

{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'CS calc: ' + ByteToStr(calc_cs) + ' CS transm: ' + ByteToStr(block_page_cs));
{$ENDIF}
        if block_page_cs <> calc_cs then
          incl(ErrFlags, c_err_flash);
        endif;
        MIDI_SendSysEx_status;

// #############################################################################
// Anforderung: fertigen Block in Flash speichern ($21)
// SysEx: F0 00 20 04 33 21 PP pp VV vv F7
// PP pp = 14-Bit-Flash-Seiten-Nummer, 4096 Bytes pro Seite
// VV vv = 14-Bit-Länge, max. 4096 Bytes pro Seite
// #############################################################################

      elsif (sysex_id = $21) then
        my_idx:= 6;
        if MIDI_GetSysEx_int(my_idx, my_param) then  // Blocknummer
          if MIDI_GetSysEx_int(my_idx, my_val) then  // Länge
{$IFNDEF MODULE}
            NB_BlockRcvMsg(my_param);
{$ENDIF}
{$IFDEF DEBUG_SYSEX}
            writeln(serout, 'SetFlashPage (21): ' + IntToStr(my_param) + ' Length: ' + IntToStr(my_val));
{$ENDIF}
            // aus im BlockBuffer8 zwischengespeicherten Block ins DF
            if not DF_Store4kBlock(word(my_param), word(my_val)) then
              incl(ErrFlags, c_err_flash);
            endif;
          endif;
        else
          incl(ErrFlags, c_err_cmd);
        endif;
        MIDI_SendSysEx_status;

// #############################################################################
// Anforderung GM2-Sound-Name Upper/Lower/Pedal ($10..$16)
// wurde von DSP gesendet, kein ACK!
// Befehlsformat:
// SysEx: F0 00 20 04 33 1X <string> 00 F7      mit X = Layer-Nummer 0..6
// #############################################################################

      elsif valueinRange(sysex_id, $10, $16) then
        my_idx:= 6;
        CommentStr:='';
        repeat
          m:= SysExArray[my_idx];
          if (m = $F7) or (m = $00) then
            break;
          endif;
          if m > 32 then  // Leerzeichen ignorieren
            CommentStr:= CommentStr + char(m);
          endif;
          inc(my_idx);
        until false or (my_idx > 20);
        // Index = 0=upper_0, 1=lower_0, 2=pedal_0, xxx, 4=upper_1, 5=lower_1, 6=pedal_1, xxx;
        i:= sysex_id - $10;
        GM_VoiceNames[i]:= CommentStr;
        GM_VoiceNameReceivedFlags[i]:= true;
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'VoiceName: ' + SerinpStr + ' Manual: ' + ByteToStr(m));
{$ENDIF}
        excl(ErrFlags, c_err_cmd);

// #############################################################################
// Anforderung Versionsnummer 2 Bytes HHLL ($0F)
// wurde von DSP gesendet, kein ACK!
// SysEx: F0 00 20 04 33 0F HH LL F7
// #############################################################################

      elsif (sysex_id = $0F) then
        DSPversion_H:= SysExArray[6];
        DSPversion_L:= SysExArray[7];
{$IFDEF DEBUG_SYSEX}
        writeln(serout, 'DSP version: '
          + ByteToHex(DSPversion_H) + '.' + ByteToHex(DSPversion_L));
{$ENDIF}
        excl(ErrFlags, c_err_cmd);

// #############################################################################
// Anforderung Flash-Block-Seite ($1A, Antwort $1B)
// SysEx: F0 00 20 04 33 1A PP pp LL ll F7
// PP pp = 14Bit-Page-Nummer (00PPPPPP Pppppppp wird zu 0PPPPPPP 0ppppppp)
// VV vv = 14Bit-Länge Bytes (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// wir senden:
// F0 00 20 04 33 1B PP pp VV vv <7+1 data> <7+1 data> ... CC F7
// mit
// CC = 7-Bit-Prüfsumme über alle Daten- und MSBytes
// #############################################################################

      elsif (sysex_id = $1A) then
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        if not MIDI_GetSysEx_int(my_idx, my_count) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        DF_readblock(word(my_param), word(my_count));  // Block aus Flash in Buffer
        MIDI_SendSysEx_header_ID($1B);
        MIDI_SendSysEx_blockbuf(my_param, my_count);

// #############################################################################
// Anforderung EEPROM-Seite ($1C, Antwort $1D)
// SysEx: F0 00 20 04 33 1C 00 00 LL ll F7
// VV vv = 14Bit-Page-Länge (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// wir senden:
// F0 00 20 04 33 1D 00 00 VV vv <7+1 data> <7+1 data> ... CC F7
// mit
// CC = 7-Bit-Prüfsumme über alle Daten- und MSBytes
// #############################################################################

// NICHT MEHR BENÖTIGT!!!
(*
      elsif (sysex_id = $1C) then
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        if not MIDI_GetSysEx_int(my_idx, my_count) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        // gesamtes EEPROM in Buffer kopieren:
        for my_adr:= 0 to 4095 do
          BlockBuffer8[my_adr]:= EE_dumpArr[my_adr];
        endfor;
        MIDI_SendSysEx_header_ID($1D);
        MIDI_SendSysEx_blockbuf(my_param, my_count);
*)

// #############################################################################
// Anforderung EditPages ($1E, Antwort $1F)
// SysEx: F0 00 20 04 33 1E 00 00 LL ll F7
// VV vv = 14Bit-Page-Länge (00VVVVVV Vvvvvvvv wird zu 0VVVVVV 0vvvvvvv)
// wir senden:
// F0 00 20 04 33 1F 00 00 VV vv <7+1 data> <7+1 data> ... CC F7
// mit
// CC = 7-Bit-Prüfsumme über alle Daten- und MSBytes
// #############################################################################

      elsif (sysex_id = $1E) then
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        if not MIDI_GetSysEx_int(my_idx, my_count) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        // gesamte EditPages in Buffer kopieren:
        edit_TempStr:= CurrentPresetName;
        CopyBlock(@edit_array, @BlockBuffer8, 512);
        MIDI_SendSysEx_header_ID($1F);
        MIDI_SendSysEx_blockbuf(my_param, my_count);
        FillBlock(@edit_TempStr, 16, 0);

// #############################################################################
// Anforderung aktuelle MIDI-Custom-Page, c_midiarr_len Bytes ($30, Antwort $31)
// #############################################################################

      elsif (sysex_id = $30) then
        if not MIDI_GetSysEx_int(my_idx, my_param) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        if not MIDI_GetSysEx_int(my_idx, my_count) then
          MIDI_SendSysEx_cmderr;
          return;
        endif;
        // gesamtes aktuelles MIDIset_Array in Buffer kopieren:
        CopyBlock(@MIDIset_Array, @BlockBuffer8, c_midiarr_len);

        MIDI_SendSysEx_header_ID($31);
        MIDI_SendSysEx_blockbuf(my_param, my_count);

// #############################################################################
// ErrFlags abfragen und löschen ($01)
// SysEx: F0 00 20 04 33 01 F7
// #############################################################################

      elsif (sysex_id = $01) then
        MIDI_SendSysEx_status;
        ErrFlags:= 0;
      endif;
    else
    endif;
{$IFDEF DEBUG_SYSEX}
  else
    write(serout, 'SysEx (other): ');
    my_idx:= 0;
    repeat
      m:= SysExArray[my_idx];
      write(serout, ByteToHex(m));
      serout(#32);
      if (m = $F7) then
        break;
      endif;
      inc(my_idx);
    until false or (my_idx = 255);
    writeln(serout);
{$ENDIF}
  endif;
end;

function MIDI_GetSysEx_int(var my_idx: byte; var my_val: Integer): boolean;
// 14-Bit-Wert aus SysExArray holen
var msb, lsb: Byte;
begin
  my_val:= 0;
  msb:= SysExArray[my_idx];
  if msb = $F7 then
    return(false);
  endif;
  inc(my_idx);
  lsb:= SysExArray[my_idx];
  if lsb = $F7 then
    return(false);
  endif;
  inc(my_idx);
  my_val:= MIDI_14_to_int(msb, lsb);
  return(true);
end;

procedure MIDI_SendSysEx_status;
// Standard-Antwort auf Parameter-Änderungen und Fehlerabfrage
// F0 00 20 04 33 02 <er> F7
begin
  MIDI_SendSysEx_header_ID($02); // Status-ID
  if midi_sysex_busyflag then
    ErrFlags:= ErrFlags or $40;
  else
    ErrFlags:= ErrFlags and $3F;
  endif;
  MIDI_SendByte(ErrFlags and $7F);
  MIDI_SendSysEx_end;
  ErrFlags:= 0;
end;

procedure MIDI_SendSysEx_cmderr;
begin
  incl(ErrFlags, c_err_cmd);
  MIDI_SendSysEx_status;
end;

procedure MIDI_SendSysExParamStr(header_id: Byte);
// Format: F0 00 20 04 33 27 <ParamStr> 00 F7
begin
  MIDI_SendSysEx_header_ID(header_id);
  for i:= 1 to length(ParamStr) do
    MIDI_SendChar(ParamStr[i]);
  endfor;
  MIDI_SendByte(0);
  MIDI_SendSysEx_end;
end;

procedure MIDI_SendSysExSernum;
// Format: F0 00 20 04 33 26 <ASCII-TEXT> 00 F7
begin
  ValueLong:= ReceiveFPGA(242);
  ParamStr:= LongToStr(ValueLong);   // FPGA-Seriennummer
  MIDI_SendSysExParamStr($26);
end;

procedure MIDI_SysExReceived(sysex_byte: Byte);
begin
  if mv = $F0 then  // SysEx-Beginn, 8 Bit zulässig wg. SPI
    SysExCount:= 0;
    SysExActive:= true;
    // innerhalb 50ms muss nächstes SyEx-Byte eintreffen
    SetSysTimer(SysExTimer, 25);
  endif;
  if SysExActive then
    SysExArray[SysExCount]:= sysex_byte;
    inctolim(SysExCount, 255);
    // innerhalb 50ms muss nächstes SyEx-Byte eintreffen
    SetSysTimer(SysExTimer, 25);
  endif;
  if (mv = $F7) then  // vollständig, korrektes Ende
    MIDI_DispatchSysEx;
    SysExCount:= 0;
    SysExActive:= false;
  endif;
end;

procedure MIDI_SetGenosActive(ch_idx: Byte);
var my_bool: Boolean;
begin
  if (ch_idx <= 2) and ExternalScanActive then
    my_bool:= BankSelectGenosValids[ch_idx];
    MidiInterpreterEnables[ch_idx]:= my_bool;
    edit_Audio_Enables[ch_idx]:= my_bool;
    edit_Audio_Enables_flag[ch_idx]:= c_to_fpga_event_source;
  endif;
end;

procedure MIDI_Dispatch;
var mch_is_valid: Boolean;
  mch_idx, midi_prog: Byte;
// MIDI IN überprüfen und ggf. an MIDI-Interpreter weiterleiten
begin
  if edit_MIDI_CC_Set <> 8 then
    ESP_RST:= high;
  endif;
  if FPGA_OK then
    while (not F_FIFO_empty) do
      ReceiveFPGA(c_MIDIreceiveReg);     // FIFO-Register
{$IFDEF DEBUG_MIDI_IN}
      writeln(serout, '/ Midi$ ' + ByteToHex(FPGAreceiveLong2) + ' '
             + ByteToHex(FPGAreceiveLong1) + ' ' + ByteToHex(FPGAreceiveLong0));
{$ENDIF}
      if not valueInRange(FPGAreceiveLong2, $80, $EF) then  // MIDI-Command
        continue;
      endif;
      mv:= FPGAreceiveLong0;     // Byte 2, Wert
      mp:= FPGAreceiveLong1;     // Byte 1, Parameter oder CC
      mcmd:= FPGAreceiveLong2 and $F0;
      mch:= FPGAreceiveLong2 and $0F;
      mbool:= mv > 63;
      mch_is_valid:= valueinrange(mch, edit_MIDI_Channel, edit_MIDI_Channel+3);


      // von Scan Driver, nur Kanal 1!
      if (FPGAreceiveLong2 = $B0) then
        case mp of
         $76:   // 118 = Split Mode
           // Splitmode setzen:
           // 0 = PedalToLower, 1 = LowerToUpper
           // 2 = PedalToUpper, 3 = LowerToUpper + 1 Oktave
           // 4 = LowerToUpper +2 Oktaven
           {$IFDEF DEBUG_MIDI_IN}
             writeln(serout,'/ (MT) New Split Mode from FPGA: ' + ByteToSTr(mv));
           {$ENDIF}
           if (not ExternalScanActive) then
             edit_SplitMode:= ValueTrimLimit(mv, 0, 5);
             edit_SplitMode_flag:= c_board_event_source;
             continue;
           endif;
           |
         $77: // 119
           {$IFDEF DEBUG_MIDI_IN}
             writeln(serout,'/ (MT) New Split Point from FPGA: ' + ByteToSTr(mv));
           {$ENDIF}
           if (not ExternalScanActive) then
             edit_SplitPoint:= ValueTrimLimit(mv, 11, 49);  // Split Point
             edit_SplitPoint_flag:= c_board_event_source;
             continue;
           endif;
           |
         $78: // 120
           // umgesetzte SysEx-Daten mit CC $78 vom FPGA Scan Driver
           // können nur auf Kanal 0 kommen!
           MIDI_SysExReceived(mv);
           continue;
           |
        endcase;
      endif;

      if not mch_is_valid then // Channel für uns?
        continue;
      endif;

      mch_idx:= mch - edit_MIDI_Channel;

      // auf Bank Selects reagieren, auch für Eder TopShop
      if (mcmd = $B0) and (mch_idx <= 3) then
        case mp of
           0: // Bank Select MSB von Genos für Eder TopShop
            BankSelectGenosValids[mch_idx]:= (mv = 63) and (BankSelectLSBs[mch_idx] = 120);
            BankSelectMSBs[mch_idx]:= mv;
            MIDI_SetGenosActive(mch_idx);
            |
          32: // Bank Select LSB von Genos für Eder TopShop
            BankSelectGenosValids[mch_idx]:= (mv = 120) and (BankSelectMSBs[mch_idx] = 63);
            BankSelectLSBs[mch_idx]:= mv;
            MIDI_SetGenosActive(mch_idx);
            |
        endcase;
      endif;

      if not MidiInterpreterEnables[mch_idx] then // sind default auf TRUE
        continue;  // wenn von MIDI_SetGenosActive() abgeschaltet
      endif;

      // Program Changes allgemein, kann ggf. in CC-Sets noch geändert werden
      if (mcmd = $C0) and (not edit_MIDI_DisableProgramChange) then
        // für Eder TopShop
        if BankSelectGenosValids[mch_idx] then
          edit_CommonPreset:= ValueTrimLimit(mv, 0, 99);
          edit_CommonPreset_flag:= c_midi_event_source;
          continue;
        elsif (edit_MIDI_CC_Set <> 0) then
          // nicht für NI B4
          midi_received:= FPGAreceiveLong and $00FFFFFF;  // 00, cmd, cc, val
{$IFNDEF MODULE}
          if edit_ShowCC then
            MIDIset_CCdisplayRequest;
          endif;
          if (edit_MIDI_CC_Set = 1) and (mch <= edit_MIDI_Channel + 1) then
            // für Hammond XK/XB
            if mp = 0 then
              midi_prog:= 0; // Cancel-Taste bei XB2, Cancel-C bei XB3/XK3
            else
              // umgekehrte Reihenfolge, B-Preset = 11, A#-Preset = 10
              midi_prog:= valueTrimLimit(11 - mp, 0, 15);
            endif;
          else
            midi_prog:= valueTrimLimit(mp, 0, 15);
          endif;
          if mch = edit_MIDI_Channel then
            edit_UpperVoice:= midi_prog;
            if edit_MIDI_CC_Set = 7 then // Hamichord sendet eigene Preset-Daten!
              edit_UpperVoice_old:= edit_UpperVoice;  // Laden verhindern
              edit_UpperVoice_flag:= 0;
            else
              edit_UpperVoice_flag:= c_midi_event_source;
            endif;
          endif;
          if mch = edit_MIDI_Channel + 1 then
            edit_LowerVoice:= midi_prog;
            if edit_MIDI_CC_Set = 7 then // Hamichord sendet eigene Preset-Daten!
              edit_LowerVoice_old:= edit_LowerVoice;  // Laden verhindern
              edit_LowerVoice_flag:= 0;
            else
              edit_LowerVoice_flag:= c_midi_event_source;
            endif;
          endif;
          if mch = edit_MIDI_Channel + 2 then
            edit_PedalVoice:= midi_prog;
            edit_PedalVoice_flag:= c_midi_event_source;
          endif;
{$ENDIF}
        endif;
      endif;

      // Spezielle Controller außerhalb MIDI-CC-Set Interpreter
      if mcmd = $B0 then
        midi_received:= FPGAreceiveLong and $00FFFFFF;  // 00, cmd, cc, val
{$IFNDEF MODULE}
        if edit_ShowCC then
          MIDIset_CCdisplayRequest;
        endif;
        if MIDI_setswell then
          continue;
        endif;

        case mp of
           6:
            midi_data_entry:= mv;
            incl(midi_rpn_flags, 2); // wird von auswertender Routine wieder auf 0 gesetzt
            incl(midi_nrpn_flags, 2);
            |
          98:
            midi_nrpn_lsb:= mv;
            midi_rpn_flags:= 0;
            incl(midi_nrpn_flags, 0);
            |
          99:
            midi_nrpn_msb:= mv;
            midi_rpn_flags:= 0;
            incl(midi_nrpn_flags, 1);
            if mv = 127 then
              midi_nrpn_flags:= 0;
            endif;
            |
         100:
            midi_rpn_lsb:= mv;
            midi_nrpn_flags:= 0;
            incl(midi_rpn_flags, 0);
            |
         101:
            midi_rpn_msb:= mv;
            midi_nrpn_flags:= 0;
            incl(midi_rpn_flags, 1);
            if mv = 127 then
              midi_rpn_flags:= 0;
            endif;
            |
        endcase;


        if midi_rpn_flags = 7 then
          // Adressen (Bit 0, 1) und Daten (Bit 2) eingetroffen
          if midi_rpn = $0002 then  // Coarse Tuning = Transpose
            // Generator Transpose, +1 = 1 Halbton nach oben
            edit_GenTranspose:= midi_data_entry - 64;
            edit_GenTranspose_flag:= c_midi_event_source;
          endif;
          midi_rpn_flags:= 0;
        endif;
        // Default: Bank Select LSB als Common Preset, nicht bei Hamichord!
        if (mp = edit_PresetCC) and (mv < 100) and (edit_MIDI_CC_Set <> 7) then
          edit_CommonPreset:= mv;
          edit_CommonPreset_flag:= c_midi_event_source;
          return;
        endif;
        // Für Touchpad und Custom CC, abschalten mit val >
        if (mp = 124) then
          ConnectMode:= t_connect_osc_midi;
          midi_DisablePercussion:= false;
          if valueInRange(mv, 0, 10) then
            edit_MIDI_CC_Set:= mv;  // CC Set
            NB_CCarrayFromDF(edit_MIDI_CC_Set);        // Set laden
            MIDI_SendSustainSostEnable;
            if edit_MIDI_CC_Set = 8 then     // MIDI-CCs immer zurücksenden
              ESP_RST:= low;                 // ESP8266 Reset aktiv
              edit_MIDI_Option:= 0;          // Senden hardwaremäßig freigeben
              FH_OrganParamsToFPGA;
              edit_PedalDBsetup:= 1;
              MIDI_SendController(0, 124, 127);  // highlight Button "Connect"
              MIDI_SendController(3, 99, 127);   // Connect LED
              edit_LogicalTab_PHRlowerOn:= false;
              edit_GatingKnob:= 0;
              edit_GatingKnob_flag:= c_midi_event_source;
              edit_OrganModel:= 0;
              edit_OrganModel_flag:= c_midi_event_source;
              for i:= 0 to 3 do
                edit_LogicalTabs_KeyingModes[i]:= false;
              endfor;
              MIDI_SendAllOSCvals;  // alle Werte!
              mdelay(100);
              MIDI_SendController(3, 103, 127);   // Page "B3"
            endif;
          endif;
          edit_MIDI_CC_Set_flag:= 0;
        endif;
{$ENDIF}
      endif;


{$IFNDEF MODULE}
      // MIDI-CC-Sets:
      //  'NI B4 d3c  ' , // 0, interpretiert, teilw. über Custom 'ccset0.dat'
      //  'Hammond XK ' , // 1, interpretiert, teilw. über Custom 'ccset1.dat'
      //  'Hammond SK ' , // 2, interpretiert, teilw. über Custom 'ccset2.dat'
      //  'Versatile  ' , // 3, interpretiert, teilw. über Custom 'ccset3.dat'
      //  'Nord C1/C2 ' , // 4, aus DF Core Block c_midicc_base +4, 'ccset4.dat'
      //  'VoceDrawbar' , // 5, aus DF Core Block c_midicc_base +5, 'ccset5.dat'
      //  'KeyB/Duo   ' , // 6, aus DF Core Block c_midicc_base +6, 'ccset6.dat'
      //  'Hamichord  ' , // 7, aus DF Core Block c_midicc_base +7, 'ccset7.dat'
      //  'KBP/Touchp ' , // 8, aus DF Core Block c_midicc_base +8, 'ccset8.dat'
      //  'Custom 1   ' , // 9, aus DF Core Block c_midicc_base +9, 'ccset9.dat'
      //  'Custom 2   ' );// 10, aus DF Core Block c_midicc_base +10,'ccset10.dat'
      case edit_MIDI_CC_Set of
        0:
          midi_DisablePercussion:= false;
          MIDI_Dispatch_ni;
          |
        1, 2: // XK/XB
          midi_DisablePercussion:= false;
          MIDI_Dispatch_custom;   // SK/XB/XK series
          |
        3:
          midi_DisablePercussion:= false;
          MIDI_Dispatch_sempra;
          |
        4..10:
          MIDI_Dispatch_custom;    // Touchpad und alle CC-only
          |
      else
      // Adressen (Bit 0, 1) und Daten (Bit 2) eingetroffen
        MIDI_Dispatch_none;
      endcase;
{$ELSE}
      midi_DisablePercussion:= false;
      MIDI_Dispatch_sempra;
{$ENDIF}
    endwhile;
  endif;
  // Bei Sysex-Empfang wurde 50ms-Timer gestartert, wird mit jedem Byte
  // wieder gesetzt. Wenn zu lange nichts kommt, ist SysEx abgestürzt.
  if SysExActive and IsSystimerzero(SysExTimer) then
{$IFDEF DEBUG_SYSEX}
    writeln(serout, '/ (MT) SysEx: ### TimeOut Error ###');
{$ENDIF}
    incl(ErrFlags, c_err_timeout);
    MIDI_SendSysEx_status;
    excl(ErrFlags, c_err_timeout);
    SysExActive:= false;
    SysExCount:= 0;        // Timeout, verwerfen
  endif;
end;

end midi_sysex.


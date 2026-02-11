// #############################################################################
// ###                      MIDI-DISPATCHER CUSTOM                           ###
// #############################################################################

// CC-Tabelle in MIDIset_Array aus DF geladen

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

// #############################################################################
// gemeinsame MIDI-Routinen für alle MIDI-CC-Interpreter
// und MIDI-Parser für NI und Doepfer d3c Drawbars
// #############################################################################

{$IFDEF DEBUG_MIDI}
procedure writeser_midibytes;
begin
  write(serout, '/ MidiCC $' +  ByteToHex(mcmd or mch) + '.'
                  + ByteToHex(mp) + '.' + ByteToHex(mv) + #9);
end;

procedure writeser_valstr(my_param: Integer; my_val: Byte);
var my_idx: Byte;
begin
  writeser_midibytes;
  write(serout, IntToStr(my_param) + '=' + ByteToStr(my_val)  + '  ' + #9);
  if valueInRange(my_param, 1000, 1511) then
    write(serout, s_MidiDebugStrArr[my_param - 1000]);
  endif;
end;
{$ENDIF}

procedure MIDIset_CheckTransposeTuning(const my_param: Integer);
begin
  if (my_param = 1355) or (my_param = 1395) then // Transpose
    mv:= mv - 64;
  endif;
{$IFNDEF MODULE}
  if (my_param = 1391)  then // Generator Tuning
    mv:= mv - 64 + 7;
  endif;
{$ENDIF}
end;

procedure MIDI_Setval(const my_param: Integer);
// Parameter auf Wert mv setzen, ggf. in echte Booleans für Buttons wandeln
// CH in MIDIset_CHarray enthält auch Mode im oberen Nibble:
// 0  (Limit to min/max)
// 1  (Scale to min/max)
// 2  (Ignore out of range)
// 3  (Invert value)
// 4  (Toggle value)
// Hammond-Drawbar-Matrix muss vor apply_changes abgefangen werden,
// sonst gehen Zwischenwerte verloren!

var ch, cc, cc_min, cc_max, threshold, flags: Byte; idx: Integer;
  mode: byte;
  do_search: Boolean;
  my_db, my_val, my_pos: byte;
begin
  if valueInRange(my_param, 1000, 1751) then
    LED_timer50;
    idx:= my_param - 1000;
    ch:= MIDIset_CHarray[idx];
    cc:= MIDIset_CCarray[idx];
    case my_param of
    1208..1210:  // Hammond Specials
      my_pos:= (mv mod 9); // 0..8
      my_db:= mv div 9;
      my_val:= muldivbyte(my_pos, 158, 10);  //0..127
      case my_param of  //
      1208:  // Upper
        if valueinrange(my_db, 0, 8) then
          edit_UpperDBs[my_db]:=my_val;
          edit_UpperDBs_flag[my_db]:= c_midi_event_source;
        endif;
        edit_HammondUprDecode:= mv;
        |
      1209:  // Lower
        if valueinrange(my_db, 0, 8) then
          edit_LowerDBs[my_db]:=my_val;
          edit_LowerDBs_flag[my_db]:= c_midi_event_source;
        endif;
        edit_HammondLwrDecode:= mv;
        |
      1210:  // Bass
        edit_PedalDBsetup:= 0; // nur 2 Drawbars, Umrechnung erzwingen
        if my_db = 0 then
          edit_PedalDB_B3_16:= my_val;
          edit_PedalDB_B3_16_flag:= c_midi_event_source;
        elsif my_db = 1 then
          edit_PedalDB_B3_8:= my_val;
          edit_PedalDB_B3_8_flag:= c_midi_event_source;
        endif;
        edit_HammondPedDecode:= mv;
        |
      endcase;
      return; // nicht über apply_changes und PA_NewParamEvent!
      |
    1211:  // Hammond Specials
      n:= edit_VibKnob and 1;
      case mv of
        0: // XB2 und XK
          edit_VibKnob:= 0;
          |
        1: // XB2 und XK
          edit_VibKnob:= 2;
          |
        2: // XB2 und XK
          edit_VibKnob:= 4;
          |
        3: // XB2 und XK
          edit_VibKnob:= 1;
         |
        4: // XB2 und XK
          edit_VibKnob:= 3;
          |
        5: // XB2 und XK
          edit_VibKnob:= 5;
          |
        $20: // XB3
          edit_VibKnob:= 0 + n;
          |
        $40: // XB3
          edit_VibKnob:= 2 + n;
          |
        $60: // XB3
          edit_VibKnob:= 4 + n;
          |
        $7F: // XB3
          edit_VibKnob:= edit_VibKnob or 1;
          |
      endcase;
      NB_VibknobToVCbits;
      edit_HammondVibKnobDecode:= mv;
      edit_VibKnob_flag:= c_midi_event_source;
      return; // nicht über apply_changes und PA_NewParamEvent!
      |
    endcase;

    do_search:= false;
    // ggf. mit absteigenen Parameternummern wiederholen,
    // bis andere CH/CC-Kombination erreicht
    repeat
      mode:= ch shr 4; // oberes Nibble nach unten
      cc_min:= MIDIset_CCminArray[idx];
      cc_max:= MIDIset_CCmaxArray[idx];
      threshold:= (cc_max + cc_min) div 2 ;  // Schaltschwelle für Tabs

      case mode of // Limit, Scale, Ignore, Invert, Toggle
        0:// Limit to min/max
          mv:= valueTrimLimit(mv, cc_min, cc_max);
          // writeln(serout,'/ (MI) SetLimit: ' + IntToStr(my_param) + ', ' + ByteToStr(mv));
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          MIDIset_CheckTransposeTuning(my_param);
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
        1: // Scale to min/max
          n:= cc_max - cc_min;      // Wertebereich
          mv:= mulDivByte(mv, n, 127) + cc_min;
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
        2: //  Send value when in range
          // 1670, 1671 Disable Percussion, setzt midi_DisablePercussion
          // 1680..1685 Vibrato-Knob, mv auf Parameter-Index umsetzen
          // 1686..1689 FAST/STOP/SLOW/RUN, mv auf Parameter-Index umsetzen
          if valueInRange(mv, cc_min, cc_max) then
{$IFDEF DEBUG_MIDI}
            writeser_valstr(my_param, mv);
{$ENDIF}
            PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          endif;
          do_search:= true;
          |
       3: // Invert value
          mv:= valueTrimLimit(mv, cc_min, cc_max);
          mv:= cc_max + cc_min - mv;
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
        4: // Toggle value
          if (mv >= 64) then
            n:= edit_array[idx];
            if n > cc_min then
              mv:= cc_min;
            endif;
            if n < cc_max then
              mv:= cc_max;
            endif;
{$IFDEF DEBUG_MIDI}
            writeser_valstr(my_param, mv);
{$ENDIF}
            PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          endif;
          |
       5: // Switch mit Schwelle, Mitte zwischen min und max
          if mv > threshold then
            mv:= 127;
          else
            mv:= 0;
          endif;
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
       6: // Inverted Switch mit Schwelle, Mitte zwischen min und max
          if mv > threshold then
            mv:= 0;
          else
            mv:= 127;
          endif;
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
       7: // Send ON only when in range
          if valueInRange(mv, cc_min, cc_max) then
            mv:= 127;
            PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          endif;
          do_search:= true;
          |
       8: // Multiply by max div min
          if cc_min = 0 then
            cc_min:= 1;
          endif;
          mv:= muldivByte(mv, cc_max, cc_min);
{$IFDEF DEBUG_MIDI}
          writeser_valstr(my_param, mv);
{$ENDIF}
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          |
       9: //  Send ON when in range, Send OFF when not in range
          if valueInRange(mv, cc_min, cc_max) then
            mv:= 127;
          else
            mv:= 0;
          endif;
          PA_NewParamEvent(my_param, mv, false, c_midi_event_source);
          do_search:= true;
          |
      endcase;
{$IFDEF DEBUG_MIDI}
      writeln(serout);
{$ENDIF}
      // mehrfach belegte CCs müssen aufeinander folgende Parameter haben
      // abbrechen, wenn andere CH/CC-Kombination oder Idx-Ende erreicht
      if do_search then
        // Anlegen der inversen Tabelle hat zuletzt gefunden Eintrag gespeichert,
        // deshalb zurück!
        dec(my_param);
        dec(idx);
        m:= ch; // vorherige Werte
        n:= cc;
        ch:= MIDIset_CHarray[idx];  // wird oben wieder gebraucht
        cc:= MIDIset_CCarray[idx];
        mode:= ch shr 4; // oberes Nibble nach unten
        // neue Werte unterschiedlich? Dann Abbruch
        do_search:= (ch = m) and (cc = n); // weitersuchen?
      endif;
    until not do_search;
  else
{$IFDEF DEBUG_MIDI}
    writeser_midibytes;
    writeln(serout, 'INVALID PARAM! ');
{$ENDIF}
  endif;
end;

function MIDI_setswell: Boolean;
// Volume/Expression setzen, wird überall gebraucht
// liefert TRUE wenn tatsächlich Schweller oder MasterVolume gemeint war
begin
  if mp = edit_VolumeCC then     // norm. 7, Overall Volume
{$IFDEF DEBUG_MIDI}
    writeln(serout,'/ MidiVol ' + ByteToStr(mv));
{$ENDIF}
    edit_MasterVolume:= mv;
    edit_MasterVolume_flag:= c_midi_event_source;
    return(true);
  elsif mp = edit_SwellCC then  // 11, Expression Pedal
{$IFDEF DEBUG_MIDI}
    writeln(serout,'/ MidiSwell ' + ByteToStr(mv));
{$ENDIF}
    midi_swell128:= mv;
    SwellPedalControlledByMIDI:= true;
    return(true);
  endif;
  return(false);
end;

// #############################################################################

procedure PresetStoreRequest_off;
begin
{$IFNDEF MODULE}
  if PresetStoreRequest then
    MIDI_SendBoolean(3, 90, false);  // Store Request LED
    PresetStoreRequest:= false;
  endif;
{$ENDIF}
end;

procedure MIDI_Dispatch_custom;
// wird angesprungen, sobald ein vollständiger MIDI-Datensatz
// (zwei oder drei Bytes, ja nach Command-Byte) im FIFO ist.
// MIDI-Daten können von beiden MIDI-Schnittstellen stammen,
// aber auch von der PicoBlaze-CPU im FPGA (Keyboard/MIDI-ScanCore) selbst.
var
  cc_min, cc_max: Byte; idx, my_param: Integer;
  arr_idx: Byte;
begin
  if (mcmd = $B0) and valueinRange(mch, edit_MIDI_Channel, edit_MIDI_Channel + 3) then
    if (mp = 6) and (midi_nrpn_flags = 7) then
      // NRPNs behandeln
      for arr_idx:= 0 to 31 do
        if midi_nrpn = MIDIset_NRPNarray[arr_idx].NRPN then
          my_param:= MIDIset_NRPNarray[arr_idx].EditIdx + 1000;
          if valueInRange(my_param, 1000, 1751) then // gültiger Index?
            MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
            LED_timer250;
          endif;
          break;
        endif;
      endfor;
    else
      // Upper bis Pedal Channel
      my_param:= CCarray_i[mch - edit_MIDI_Channel, mp];
      MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      // Sonderkanal Spezialfunktionen und Statusmeldungen über Parser
      if mch < edit_MIDI_Channel + 3 then
        PresetStoreRequest_off;
      endif;
    endif;
  endif;
end;


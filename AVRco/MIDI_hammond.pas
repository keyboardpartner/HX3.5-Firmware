{###########################################################################}
// MIDI-Parser für Hammond (XK-3 und andere)
{###########################################################################}

// NICHT MEHR BENUTZT!!! - jetzt über Custom CC

// Preset speichern mit MIDI-CC $5F (95) auf Upper oder
// mit MIDI-CC $5E (94) auf Lower

procedure translate_vibknob_hammond(const hammond_vib_byte: Byte);
begin
  case hammond_vib_byte of
    0: // XB2 und XK
      edit_VibKnob:= 0;
      MIDI_Chorus_on:= 0;
      |
    1: // XB2 und XK
      edit_VibKnob:= 2;
      MIDI_Chorus_on:= 1;
      |
    2: // XB2 und XK
      edit_VibKnob:= 4;
      MIDI_Chorus_on:= 0;
      |
    3: // XB2 und XK
      edit_VibKnob:= 1;
      MIDI_Chorus_on:= 1;
      |
    4: // XB2 und XK
      edit_VibKnob:= 3;
      MIDI_Chorus_on:= 0;
      |
    5: // XB2 und XK
      edit_VibKnob:= 5;
      MIDI_Chorus_on:= 1;
      |
    $20: // XB3
      edit_VibKnob:= 0 + MIDI_Chorus_on;
      |
    $40: // XB3
      edit_VibKnob:= 2 + MIDI_Chorus_on;
      |
    $60: // XB3
      edit_VibKnob:= 4 + MIDI_Chorus_on;
      |
  endcase;
  edit_VibKnob_flag:= c_midi_event_source;
end;

procedure DispatchNRP_hammond_xk(my_ch: byte);
var my_bool: boolean;
begin
  LED_timer150;
  my_bool:= midi_data_entry <> 0;
  if my_ch = edit_MIDI_Channel then // upper
    case midi_nrpn of
    $000A:  // XK EQ Bass Gain
      edit_EqualizerBass:= midi_data_entry * 7;
      edit_EqualizerBass_flag:= c_midi_event_source;
      |
    $020A:  // XK EQ Treble Gain
      edit_EqualizerTreble := muldivbyte(midi_data_entry * 7, 100, 127);
      edit_EqualizerTreble_flag:= c_midi_event_source;
      |
    $4600,  // XB2
    $1700,  // XB3
    $0209:  // XK Vibrato Upper On/Off
      edit_LogicalTab_VibOnUpper:= my_bool;
      edit_LogicalTab_VibOnUpper_flag:= c_midi_event_source;
      |
    $0409,  // SK
    $1800,  // XB2
    $1709:  // XK Vibrato Lower On/Off (nur XK3c)
      edit_LogicalTab_VibOnLower:= my_bool;
      edit_LogicalTab_VibOnLower_flag:= c_midi_event_source;
      |
    $0030,  // SK Overdrive ON
    $6D00,  // XB2/3 Overdrive ON
    $0909:  // XK Tube ON
      edit_LogicalTab_TubeAmpBypass:= not my_bool;
      edit_LogicalTab_TubeAmpBypass_flag:= c_midi_event_source;
      |
    $040A:  // XK Reverb ON
      edit_LogicalTab_Reverb2:= my_bool;
      edit_LogicalTab_Reverb2_flag:= c_midi_event_source;
      |
    $0900:  // XK/XB3 Leslie Run
      edit_LogicalTab_LeslieRun:= my_bool;
      edit_LogicalTab_LeslieRun_flag:= c_midi_event_source;
      |
    $0000,  // XB2/3
    $0109:  // XK/SK Leslie Fast/Slow
      edit_LogicalTab_LeslieFast:= my_bool;
      edit_LogicalTab_LeslieFast_flag:= c_midi_event_source;
      |
    $0509:  // XK Overdrive (hier Leslie Volume)
      edit_LeslieVolume:= midi_data_entry shl 1; // 0..$3F!!!
      edit_LeslieVolume_flag:= c_midi_event_source;
      |
    $1200,  // XB2/3
    $0008:  // Perc 2nd (hier ON) wie SK
      edit_LogicalTab_percOn:= my_bool;
      edit_LogicalTab_percOn_flag:= c_midi_event_source;
      //edit_LogicalTab_perc3rd:= false;
      //edit_LogicalTab_perc3rd_flag:= c_midi_event_source;
      |
    $1300,  // XB2/3
    $0108:  // Perc 3rd wie SK
      //edit_LogicalTab_percOn:= my_bool;
      edit_LogicalTab_perc3rd:= my_bool;
      //edit_LogicalTab_percOn_flag:= c_midi_event_source;
      edit_LogicalTab_perc3rd_flag:= c_midi_event_source;
      |
    $1600,  // XB3
    $0208:  // Perc FAST wie SK
      edit_LogicalTab_PercFast:= my_bool;
      edit_LogicalTab_PercFast_flag:= c_midi_event_source;
      |
    $1500,  // XB3
    $0308:  // Perc SOFT wie SK
      edit_LogicalTab_PercSoft:= my_bool;
      edit_LogicalTab_PercSoft_flag:= c_midi_event_source;
      |
    $0702:  // User Sw
      edit_LogicalTab_VibOnLower:= my_bool;
      edit_LogicalTab_VibOnLower_flag:= c_midi_event_source;
      |
    $2C00,  // XB3
    $0007, $0107:  // XK Manual Bass, hier Split
      edit_LogicalTab_SplitOn:= my_bool;
      edit_LogicalTab_SplitOn_flag:= c_midi_event_source;
      |
    $0322,  // SK
    $0800:  // XB3 Pedal Sustain ON
      if my_bool then
        edit_PedalRelease:= 30;
      else
        edit_PedalRelease:= 0;
      endif;
      edit_PedalRelease_flag:= c_midi_event_source;
      |
    $0B00:  // XB3 Chorus ON
      MIDI_Chorus_on:= byte(my_bool) and 1;
      translate_vibknob_hammond(midi_vibknob_hammond);
      |
    $0309:  // XK Vibrato knob
      translate_vibknob_hammond(midi_data_entry);
      |
    $4500:  // XB2, XB3 Vibrato knob
      translate_vibknob_hammond(midi_data_entry);
      midi_vibknob_hammond:= midi_data_entry;
      |
    endcase;
  endif;
  if my_ch = (edit_MIDI_Channel+1) then // lower
    if midi_nrpn = $0209 then  // Vibrato On/Off
      edit_LogicalTab_VibOnLower:= (midi_data_entry <> 0);
      edit_LogicalTab_VibOnLower_flag:= c_midi_event_source;
    endif;
  endif;
end;

procedure DispatchNRP_hammond_sk(my_ch: byte);
// Spezialfälle für SK abfangen, sonst wie oben
var my_bool: boolean;
begin
  LED_timer150;
  my_bool:= midi_data_entry > 0;
  if my_ch = edit_MIDI_Channel then // upper
    case midi_nrpn of
    $0309:  // Vibrato lower On/Off ### GREAT
      edit_LogicalTab_VibOnLower:= my_bool;
      edit_LogicalTab_VibOnLower_flag:= c_midi_event_source;
      |
    $0709:  // Leslie Run = not STOP ###
      edit_LogicalTab_LeslieRun:= not my_bool;
      edit_LogicalTab_LeslieRun_flag:= c_midi_event_source;
      |
    $0230:  // SK Overdrive (hier Leslie Volume)
      edit_LeslieVolume:= midi_data_entry; // 0..$7F
      edit_LeslieVolume_flag:= c_midi_event_source;
      |
    $0409:  // SK Vibrato knob
      translate_vibknob_hammond(midi_data_entry);
      |
    $040A:  // Reverb Depth
      edit_OverallReverb:= midi_data_entry;
      edit_OverallReverb_flag:= c_midi_event_source;
      |
    else
      DispatchNRP_hammond_xk(my_ch);
    endcase;
  endif;
end;

procedure DispatchDB_hammond;
var my_db, my_val, my_pos: byte;
begin
  LED_timer150;
// merkwürdige CC-Zuordnung bei Hammond: Je Zugriegel 9 Werte
// Kanal unberücksichtigt
  my_pos:= (mv mod 9); // 0..8
  my_db:= mv div 9;
  my_val:= my_pos * 15;  //0..120, war DrawbarLevelArr[my_pos];

//  TESTAUSGABE
//  WriteByteSer(my_val);

  case FPGAreceiveLong1 of  //
  $50:  // Upper
    if valueinrange(my_db, 0, 8) then
      edit_UpperDBs[my_db]:=my_val;
      edit_UpperDBs_flag[my_db]:= c_midi_event_source;
    endif;
    |
  $51:  // Lower
    if valueinrange(my_db, 0, 8) then
      edit_LowerDBs[my_db]:=my_val;
      edit_LowerDBs_flag[my_db]:= c_midi_event_source;
    endif;
    |
  $52:  // Bass
    edit_PedalDBsetup:= 0; // nur 2 Drawbars, Umrechnung erzwingen
    if my_db = 0 then
      edit_PedalDB_B3_16:= my_val;
      edit_PedalDB_B3_16_flag:= c_midi_event_source;
    elsif my_db = 1 then
      edit_PedalDB_B3_8:= my_val;
      edit_PedalDB_B3_8_flag:= c_midi_event_source;
    endif;
    |
  endcase;
end;

procedure MIDI_Dispatch_hammond_xk_xb;
// Anpassung für Hammond XK-3 und andere

var my_bool: boolean; my_param: Integer;
begin
// mcmd = Command isoliert,
// mch = Channel isoliert,
// mp = Controller-Nr,
// mv = Controller-Wert
  my_bool:= mv > 63;

  if valueinrange(mch, edit_MIDI_Channel, edit_MIDI_Channel+2) then
// für Upper/Lower/Bass gemeinsam behandeln
    if midi_nrpn_flags = 7 then // Adressen (Bit 0, 1) und Daten (Bit 2) eingetroffen
      DispatchNRP_hammond_xk(mch);
      midi_nrpn_flags:= 0;
    endif;
  endif;
  if mcmd = $B0 then   // Control Change
    case (mch - edit_MIDI_Channel) of
    0: // Upper
      if valueInRange(mp, $50, $52) then
        DispatchDB_hammond;
      else
        my_param:= CCarray_i[0, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endif;
      |

    1: // Lower
      if valueInRange(mp, $50, $52) then
        DispatchDB_hammond;
      else
        my_param:= CCarray_i[1, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endif;
      |

    2: // Pedal
      if valueInRange(mp, $50, $52) then
        DispatchDB_hammond;
      else
        edit_PedalDBsetup:= 0; // nur 2 Drawbars, Umrechnung erzwingen
        my_param:= CCarray_i[2, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endif;
      |
    endcase;
  endif;
end;

// MIDI-Parser für Hammond SK2 und neuere
// Achtung: Drawbar und Vibrato ggü. XK3 geändert!
// SK hat Drawbars wieder als CC, Tabs etwas anders als XK. Bescheuert!

procedure MIDI_Dispatch_hammond_sk;
// Anpassung für Hammond SK und neuere
var my_index: byte; my_param: Integer;
begin
// mcmd = Command isoliert,
// mch = Channel isoliert,
// mp = Controller-Nr,
// mv = Controller-Wert
  if valueinrange(mch, edit_MIDI_Channel, edit_MIDI_Channel+2) then
// für Upper/Lower gemeinsam behandeln
    if midi_nrpn_flags = 7 then // Adressen (Bit 0, 1) und Daten (Bit 2) eingetroffen
      DispatchNRP_hammond_sk(mch);
      midi_nrpn_flags:= 0;
    elsif mcmd = $B0 then          // Control Change
      LED_timer50;
      if mch=(edit_MIDI_Channel+2) then // Pedal
        edit_PedalDBsetup:= 0; // nur 2 Drawbars, Umrechnung erzwingen
      endif;
      my_param:= CCarray_i[mch - edit_MIDI_Channel, mp];
      MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
    endif;
  endif;
end;



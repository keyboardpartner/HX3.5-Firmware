// #############################################################################
//       __ ________  _____  ____  ___   ___  ___
//      / //_/ __/\ \/ / _ )/ __ \/ _ | / _ \/ _ \
//     / ,< / _/   \  / _  / /_/ / __ |/ , _/ // /
//    /_/|_/___/_  /_/____/\____/_/_|_/_/|_/____/
//      / _ \/ _ | / _ \/_  __/ |/ / __/ _ \
//     / ___/ __ |/ , _/ / / /    / _// , _/
//    /_/  /_/ |_/_/|_| /_/ /_/|_/___/_/|_|
//
// #############################################################################

unit menu_system;

interface
uses var_def, const_def, port_def, edit_changes, nuts_and_bolts,
     apply_changes, display_toolbox, parser, dataflash, main_tasks;

procedure MenuPanelHandling;

// #############################################################################
//
//     #     # ####### #     # #     #    #####  #     #  #####
//     ##   ## #       ##    # #     #   #     #  #   #  #     #
//     # # # # #       # #   # #     #   #         # #   #
//     #  #  # #####   #  #  # #     #    #####     #     #####
//     #     # #       #   # # #     #         #    #          #
//     #     # #       #    ## #     #   #     #    #    #     #
//     #     # ####### #     #  #####     #####     #     #####
//
// #############################################################################


implementation

type t_ovr = (t_inrange, t_overrange, t_underrange);

{$IDATA}

// #############################################################################
// ###                         private Fuktionen                             ###
// #############################################################################

procedure lcd_number2(const my_number: byte);
begin
  write(LCDOut_M, byteToStr(my_number:2:'0'));
end;

// #############################################################################

procedure menu_WaitPanelButtonsReleased;
// Warten auf Loslassen einer Panel-Taste.
// Ruft in der Schleife MainTasks auf
begin
  while DT_PanelButtonPressed(10)  do
    MainTasks;
    mDelay(10);
  endwhile; // Timeout oder losgelassen
end;

function menu_PanelButtonTimeout(timeout: byte): Boolean;
// Warten auf Loslassen einer Panel-Taste.
// Liefert TRUE, wenn l�nger als "timeout" * 10 ms gedr�ckt
// Ruft in der Schleife MainTasks auf
var
  loopcount: byte;
  my_result: Boolean;
begin
  loopcount:= 0;
  my_result:= false;
  while DT_PanelButtonPressed(10) and (not my_result) do
    MainTasks;
    my_result:= not inctolim(loopcount, timeout); // my_result wird nach my_limit true
  endwhile; // Timeout oder losgelassen
  ButtonPressed:= (PanelButtonTemp <> 0);
  return(my_result); // true wenn Timeout
end;

function menu_GetSaveDestination(const my_menu_idx: Byte): char;
// ermittelt aus Menu-Eintrag und Maske das Preset-Ziel.
// Wenn Masken-Bit nicht freigegeben, wird ggf. ts_eepdefs als Ziel genommen
(* Save Destination:
  0 = None/Unsaved
  1 = Upper Drawbars
  2 = Lower Drawbars
  3 = Pedal Drawbars
  4 = Common Preset
  5 = Common Preset, valid only if PresetGM-Mask = 1
  6 = Common Preset, valid only if PresetPercDB-Mask = 1
  7 = Organ Model
  8 = Speaker Model
  9 = Defaults
  10 = Extended Params >= #2000
  11 = System Inits
*)
var
  save_mask: Word;
  save_dest: Byte;
  idx: Integer;
begin
  idx:= c_Index2ParamArr[my_menu_idx];
  save_dest:= 0; // keine Destination
  if ValueInRange(idx, 1000, 1511) then
    save_mask:= c_SaveRestoreMasks[idx - 1000];
    save_dest:= hi(save_mask) and $0F;  // Bits 8..11
    if save_dest < 7 then
      // Mask-Bits isolieren
      if (save_mask and Word(edit_SaveRestoreMask) and $00FF) = 0 then
        save_dest:= 9; // Recall-Bit nicht gesetzt, dann in Defaults
      endif;
    endif;
  endif;
  return(c_destchar_arr[save_dest]);
end;

// #############################################################################
// ###                           Memorize-Anzeige                            ###
// #############################################################################

procedure disp_arrow_clreol;
begin
  LCDOut_M(#7);
  LCDclrEOL_M(LCD_m1);  // Rest der unteren Zeile l�schen
end;


procedure MenuOnOffArrow(const my_bool: boolean);
begin
  DisplayOnOff(my_bool);
  disp_arrow_clreol;
end;

procedure MenuDispValueArrow(const my_val: byte);
begin
  write(LCDOut_M, byteToStr(my_val:3));
  disp_arrow_clreol;
end;

procedure MenuDispValZeroOffArrow(const my_val: byte);
begin
  if my_val = 0 then
    MenuOnOffArrow(false);
  else
    MenuDispValueArrow(my_val);
  endif;
end;

procedure MenuDispPercussion(const my_percmode: Byte);
// var adsr_mask: Word;
begin
  if my_percmode < 8 then
    MenuOnOffArrow(false);
  else
    DisplayOnOff(true);
    // adsr_mask:= EC_LogicalTabs2Word(32) and $0FFF;
    if Bit(my_percmode, 2) then
      write(LCDOut_M, 'SFT ');
    else
      write(LCDOut_M, 'NRM ');
    endif;
    if Bit(my_percmode, 1) then
      write(LCDOut_M, 'FST ');
    else
      write(LCDOut_M, 'SLW ');
    endif;
    if (edit_GatingKnob >= 1) and (CurrentADSRmask <> 0) then  // H100-Modus, Fu�lagen �ber Enable-Bits
        LCDOut_M('H');
    else
      if Bit(my_percmode, 0) then
        LCDOut_M('3');
      else
        LCDOut_M('2');
      endif;
    endif;
    disp_arrow_clreol;
  endif;
end;

procedure MenuDispVibrato(const vibon_upr, vibon_lwr: Boolean; const knob_pos: Byte);
begin
// Short Message-Display
  DisplayOnOff(vibon_upr);
  LCDOut_M_space;
  DisplayOnOff(vibon_lwr);
  LCDOut_M_space;
  if (knob_pos and 1) = 1 then
    LCDOut_M('C');
  else
    LCDOut_M('V');
  endif;
  LCDOut_M(char(49 + (knob_pos shr 1)));
  LCDclrEOL_M(LCD_m1);  // Rest der unteren Zeile l�schen
end;

function DrawbarNumberScale(const my_dbval: byte): byte;
// 0..127 => 0..63, dann Wert aus Antilog-Tabelle entnehmen -> 0..8
begin
  return(muldivbyte(my_dbval + 4, 10, 149)); // 0..127 => 0..8
end;

procedure MenuDispValueBarArrow(my_val: byte);
// 0..127 in Balkenl�nge umrechnen
var my_temp: byte;
begin
  LCDsetBar;
  my_val:= my_val shr 3;
  my_temp:= my_val shr 1;
  if (my_val and 1) = 1 then
    for i:= 0 to my_temp do
      LCDOut_M(#0);
    endfor;
  else
    for i:= 1 to my_temp do
      LCDOut_M(#0);
    endfor;
    LCDOut_M(#1);
  endif;
  for i := my_temp to 6 do
    LCDOut_M(#3);
  endfor;
  LCDOut_M(#2);
  disp_arrow_clreol;
end;

procedure MenuDispListItemArrow(my_ptr: pointer; const my_idx: byte);
// Display-Text zweite Zeile �ber Pointer zum Array
var my_bool: boolean; my_len: byte;
begin
  my_len:= FlashPtr(my_ptr)^;
  my_ptr:= my_ptr + (word(my_idx) * word(my_len + 1));
  for i:= 0 to my_len - 1 do
    inc(my_ptr);
    LCDOut_M(char(FlashPtr(my_ptr)^));
  endfor;
  disp_arrow_clreol;
end;

procedure display_frequ(edit_val, shifts: Byte; offset: Word);
var
  frequ: Word;
begin
  // Wert wird in DSP-FW quadriert, durch divide geteilt und mit Offset versehen
  frequ:= Word(edit_val);
  frequ:= ((frequ * frequ) shr shifts) + offset;
  write(LCDOut_M, IntToStr(frequ:4));
  write(LCDOut_M, ' Hz');
  disp_arrow_clreol;
end;

// #############################################################################

procedure MainPresetDisplay(const my_menutype: t_menuType);
var my_dbval: byte;
begin
  LCDxy_M(LCD_m1, 0, 0);
  if PresetPreview then
    LCDxy_M(LCD_m1, 0, 0);
    write(LCDOut_M, 'Preset Preview');
    LCDclrEOL_M(LCD_m1);
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M, CurrentPresetName);
    LCDclrEOL_M(LCD_m1);
  else
    case my_menutype of
      tm_preset_upper:
        write(LCDOut_M, 'Drb');
        for i:= 0 to 11 do
          my_dbval:= DrawbarNumberScale(edit_UpperDBs[i]); // 0..127 => 0..8
          if (edit_GatingKnob = 0) and (i > 8) then
            LCDOut_M('-');
          else
            LCDOut_M(char(my_dbval +48));
           endif;
        endfor;
        |
      tm_preset_lower:
        write(LCDOut_M, 'Drb');
        for i:= 0 to 11 do
          my_dbval:= DrawbarNumberScale(edit_LowerDBs[i]); // 0..127 => 0..8
          if (edit_GatingKnob = 0) and (i > 8) then
            LCDOut_M('-');
          else
            LCDOut_M(char(my_dbval +48));
           endif;
        endfor;
        |
      tm_preset_pedal:
        write(LCDOut_M, 'Drb');
        for i:= 0 to 11 do
          my_dbval:= DrawbarNumberScale(edit_PedalDBs[i]); // 0..127 => 0..8
          if (edit_GatingKnob = 0) and (i > 8) then
            LCDOut_M('-');
          else
            LCDOut_M(char(my_dbval +48));
           endif;
        endfor;
        |
    else
      write(LCDOut_M, s_MenuHeaderArr[c_MenuCommonPreset]);
      LCDxy_M(LCD_m1, 11, 0);
      lcd_number2(edit_CommonPreset);
      if MenuIndex = c_MenuCommonPreset then
        LCDOut_M(#7); // left Arrow
      else
        LCDOut_M_space;
      endif;
      // Name eingetragen?
    endcase;
    LCDclrEOL_M(LCD_m1);
    LCDxy_M(LCD_m1, 0, 1);
    if (my_menutype = tm_preset_common) and (edit_CommonPreset > 0) then
      // DF_GetPresetNameStr(edit_CommonPreset);
      // write(LCDOut_M, CommentStr);
      write(LCDOut_M, CurrentPresetName);
      LCDclrEOL_M(LCD_m1);
    else
      LCDOut_M('U');
      lcd_number2(edit_UpperVoice);
      if my_menutype = tm_preset_upper then
        LCDOut_M(#7); // left Arrow
      else
        LCDOut_M_space;
      endif;
      LCDOut_M_space;
      LCDOut_M('L');
      lcd_number2(edit_LowerVoice);
      if my_menutype = tm_preset_lower then
        LCDOut_M(#7); // left Arrow
      else
        LCDOut_M_space;
      endif;
      LCDOut_M_space;
      LCDOut_M('P');
      lcd_number2(edit_PedalVoice);
      if my_menutype = tm_preset_pedal then
        LCDOut_M(#7); // left Arrow
      else
        LCDOut_M_space;
      endif;
      LCDOut_M_space;
      LCDOut_M_space;
    endif;
  endif;
end;

// #############################################################################

procedure MenuDispChangedStar(my_bool: boolean);
begin
  LCDxy_M(LCD_m1, 14, 1);
  if my_bool then
    LCDOut_M('*'); // noch nicht gesichert
  else
    LCDOut_M_space; // gleich oder gesichert
  endif;
end;

function ApplyDelta(var my_val: Byte; const my_min, my_max: byte; const delta: Int8): t_ovr;
// Encoder-�nderung auf einzelne Variable anwenden
// Liefert TRUE wenn innerhalb Bereich
// type t_ovr = (t_inrange, t_overrange, t_underrange);
var
  my_encoder_val: integer;
  ovr_dir: t_ovr;

begin
  my_encoder_val:= Integer(my_val) + Integer(delta);
  ovr_dir:= t_inrange;
  if my_encoder_val < integer(my_min) then
    ovr_dir:= t_underrange;
  elsif my_encoder_val > integer(my_max) then
    ovr_dir:= t_overrange;
  endif;
  my_encoder_val:= ValueTrimLimit(my_encoder_val, integer(my_min), integer(my_max));
  my_val:= byte(my_encoder_val);
  return(ovr_dir);
end;

// #############################################################################

function EditPresetName(char_idx: Byte; delta: Int8): Byte;
// liefert neue L�nge des Strings
var my_val: Byte;
  temp_arr: Array[0..15] of Byte;
  len: Word;
begin
  inc(char_idx); // wg. Pascal-L�ngenbyte
  len:= Word(CurrentPresetNameLen) + 1;
  FillBlock(@temp_arr, 16, 32); // mit Leerzeichen #32 f�llen
  CopyBlock(@CurrentPresetName, @temp_arr, len);
  temp_arr[0]:= 14;
  if delta <> 0 then
    my_val:= temp_arr[char_idx];
    ApplyDelta(my_val, 32, 127, delta);
    temp_arr[char_idx]:= my_val;
  endif;
  CopyBlock(@temp_arr, @CurrentPresetName, 16);
  CurrentPresetName:= TrimRight(CurrentPresetName);
  LCDxy_M(LCD_m1, 0, 1);
  write(LCDOut_M, CurrentPresetName);
  LCDclrEOL_M(LCD_m1);  // Rest der unteren Zeile l�schen
  return(CurrentPresetNameLen);
end;

procedure EditBitfield(var bitfield: word; const my_len, my_idx: byte;
          const invert: Boolean; const all_white_btns: Boolean);
var my_bool: Boolean;
begin
  LCDsetBitfield;
  if invert then
    my_bool:= Bit(bitfield, my_idx) xor invert;
    Setbit(bitfield, my_idx, my_bool);
  endif;
  LCDxy_M(LCD_m1, 0, 1);
  for i:= 0 to my_len do
    if all_white_btns or (i in [2,3,5,8]) then
      if Bit(bitfield, i) then
        LCDOut_M(#1);
      else
        LCDOut_M(#0);
      endif;
    else         // "graue" Buttons f�r DBs?
      if Bit(bitfield, i) then
        LCDOut_M(#3);
      else
        LCDOut_M(#2);
      endif;
    endif;
  endfor;
end;

// #############################################################################
// ###       Spezielle Anzeigefunktionen bei Vibrato und Percussion etc.     ###
// ###           Zus�tzliche Anzeigefunktionen f�r EDIT-MODUS                ###
// #############################################################################

procedure DoMenuChange(delta: Int8; change_menu_only, invert: Boolean);
// wenn change_menu_only TRUE, wird nur Menu ge�ndert, aber nicht der Wert.
var my_menutype: t_menuType;
    my_pointer: pointer;
    my_bool, value_changed: Boolean;
    my_param_idx, my_int: Integer;
    my_max, my_val, my_idx: byte;
    my_bitfield, my_bitfield_temp: Word;
    my_save_dest_char: char;

begin
  value_changed:= (delta <> 0);
  if invert then
    value_changed:= false;
    delta:= 0;
  endif;

  my_menutype:= c_MenuTypeArr[MenuIndex];
  my_max:= DT_GetMenuMax(MenuIndex);

  my_save_dest_char:= menu_GetSaveDestination(MenuIndex);
  my_param_idx:= c_Index2ParamArr[MenuIndex];

  if my_menutype in [tm_preset_common..tm_preset_pedal] then
    if value_changed then
      my_idx:= ord(my_menutype) - ord(tm_preset_common);
      ApplyDelta(edit_voices[my_idx], 0, my_max, delta);
      edit_voices_flag[my_idx]:= c_menu_event_source;
    endif;
    MainPresetDisplay(my_menutype);
    IsInBitField:= false;
    DT_SetUpDownArrows;
    return;
  endif;

  if change_menu_only then
    DisplayHeaderIndexed(MenuIndex);
  endif;

  if DT_MenuEntryValid(MenuIndex) <= t_menu_invalid then
    DisplayBottom('(invalid)');
    LCDclrEOL_M(LCD_m1);  // Rest der unteren Zeile l�schen
    return;
  endif;

  if my_menutype = tm_perc then
    // Men�-Anfangswert korrigieren (min)
    NB_TabsToPercKnob;
  endif;

  if my_menutype = tm_button then
    my_val:= 0;
  else
    PA_GetParamByte(my_param_idx, my_val, false);
  endif;

  my_bool:= (my_val <> 0);

  if value_changed then // �nderungen
    if delta > 0 then
      my_bool:= true;
    elsif delta < 0 then
      my_bool:= false;
    endif;
    if my_menutype = tm_boolean then
      my_val:= byte(my_bool);
    else
      ApplyDelta(my_val, 0, my_max, delta);
    endif;
  endif;
{
  if my_bool then
    writeln(serout, '/ ON');
  else
    writeln(serout, '/ OFF');
  endif;
}
  LCDxy_M(LCD_m1, 14, 0);
  LCDOut_M(my_save_dest_char); // Zus�tzlicher Buchstabe U/L/D

  LCDxy_M(LCD_m1, 0, 1);
  my_pointer:= nil;

  case my_menutype of
    tm_drawbar:
      MenuDispValueBarArrow(my_val);
      |
    tm_gm_prg0..tm_gm_prg6:    // alle GM-Layer
      // Reihenfolge von my_menutype wie
      // NRPN-Reihenfolge $3570+x und in GM-VoiceName-Array:
      // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
      // xxx taucht als my_menutype nicht auf!
      n:= ord(my_menutype) - ord(tm_gm_prg0);   // 0..6!
      // Platz f�r Namen freilassen, wird von MT_HandleGMnameRequests gef�llt
      LCDxy_M(LCD_m1, 0, 1);
      if (delta = 0) then
        write(LCDOut_M, GM_VoiceNames[n]); // vorbelegter Name
        LCDclrEOL_M(LCD_m1);  // Rest der unteren Zeile l�schen
      endif;
      GM_VoiceNameToDisplaySema[n]:= true;
      LCDxy_M(LCD_m1, 13, 1);
      disp_arrow_clreol;
      |
    // Spezieller Editor n�tig
    tm_adsrena_upr:
      if edit_GatingKnob = 1 then
        LCDxy_M(LCD_m1, 0, 0);
        write(LCDOut_M, 'H-Perc ');
      endif;
      LCDxy_M(LCD_m1, 7, 0);
      write(LCDOut_M, s_EGbitfieldArr[11-EditFieldIndex]);
      LCDOut_M(#32);
      lo(my_bitfield):= EC_LogicalTabsToByte(32);
      hi(my_bitfield):= EC_LogicalTabsToByte(40);
      my_bitfield_temp:= my_bitfield;
      EditBitfield(my_bitfield, EditFieldSize, EditFieldIndex, invert, false); // DB-Mode
      EC_ByteToLogicalTabs(lo(my_bitfield), 32);
      EC_ByteToLogicalTabs(hi(my_bitfield), 40);
      // Percussion automatisch einschalten
      if (edit_GatingKnob = 1) then
        if (BitCountOf(my_bitfield) > BitCountOf(my_bitfield_temp)) then
          PA_NewEditEvent(0128, 255, false, c_menu_event_source);
        endif;
        if (my_bitfield = 0) then
          PA_NewEditEvent(0128, 0, false, c_menu_event_source);
        endif;
      endif;
      disp_arrow_clreol;
      |
    tm_adsrena_lwr:
      LCDxy_M(LCD_m1, 0, 0);
      write(LCDOut_M, 'EnvEna ');
      write(LCDOut_M, s_EGbitfieldArr[11-EditFieldIndex]);
      LCDOut_M(#32);
      lo(my_bitfield):= EC_LogicalTabsToByte(48);
      hi(my_bitfield):= EC_LogicalTabsToByte(56);
      EditBitfield(my_bitfield, EditFieldSize, EditFieldIndex, invert, false); // DB-Mode
      EC_ByteToLogicalTabs(lo(my_bitfield), 48);
      EC_ByteToLogicalTabs(hi(my_bitfield), 56);
      disp_arrow_clreol;
      |
    tm_items_phrmode:
      LCDxy_M(LCD_m1, 4, 0);
      write(LCDOut_M, s_PHRbitfieldArr[EditFieldIndex]);
      LCDOut_M(#32);
      lo(my_bitfield):= EC_LogicalTabsToByte(16);
      EditBitfield(my_bitfield, 7, EditFieldIndex, invert, true);
      EC_ByteToLogicalTabs(lo(my_bitfield), 16);
      disp_arrow_clreol;
      |
    tm_editname: //
      EditPresetName(EditFieldIndex, delta); // liefert neue L�nge
      my_val:= 0;
      value_changed:= false;
      |
    tm_reverb:
      MenuDispValZeroOffArrow(edit_ReverbKnob);
      |
    tm_perc:
//      if (edit_GatingKnob = 1) then    // GEHT NICHT!
        // ungerade Eintr�ge (2nd/3rd wechselt) �berspringen
//        ApplyDelta(edit_MenuPercMode, 7, my_max, delta);
//      endif;
      MenuDispPercussion(edit_PercKnob);
      |
    tm_vibknob:
      // ge�nderten edit_VibKnob-Wert anzeigen
      MenuDispVibrato(edit_LogicalTab_VibOnUpper, edit_LogicalTab_VibOnLower, my_val);
      LCDxy_M(LCD_m1, 15, 0);
      LCDOut_M_space;
      LCDxy_M(LCD_m1, 10, 1);
      disp_arrow_clreol;
      |
    tm_vib_on_upr:
      // bisherigen edit_VibKnob-Wert anzeigen
      MenuDispVibrato(my_bool, edit_LogicalTab_VibOnLower, edit_VibKnob);
      my_val:= byte(my_bool);
      LCDxy_M(LCD_m1, 3, 1);
      LCDOut_M(#7); // Rest muss stehenbleiben!
      |
    tm_vib_on_lwr:
      MenuDispVibrato(edit_LogicalTab_VibOnUpper, my_bool, edit_VibKnob);
      my_val:= byte(my_bool);
      LCDxy_M(LCD_m1, 7, 1);
      LCDOut_M(#7); // Rest muss stehenbleiben!
      |
    tm_transpose:
      PA_GetParamByte(my_param_idx, my_val, false);  // neu holen ohne Delta
      m:= my_val + 24;
      ApplyDelta(m, 0, my_max, delta);
      my_val:= m - 24;
      LCDOut_M_space;
      if my_val >= 128 then
        LCDOut_M('-');
        write(LCDOut_M, ByteToStr(0-my_val));
      else
        LCDOut_M('+');
        write(LCDOut_M, ByteToStr(my_val));
      endif;
      disp_arrow_clreol;
      |
    tm_button:
      DisplayBottom('Press Btn 2sec');
      LCDOut_M_space;
      DT_LeftArrowClrEol;
      |
    tm_boolean:
      MenuOnOffArrow(my_bool);
      |
    tm_midichannel: // MIDI-Channel +1!
      MenuDispValueArrow(my_val + 1);
      ConnectMode:= t_connect_midi;
      |
    tm_bassfreq: // Equalizer Bass Frequ
      display_frequ(my_val, 3, 32);
      |
    tm_midfreq: // Equalizer Mid Frequ
      display_frequ(my_val, 2, 128);
      |
    tm_treblefreq: // Equalizer Treble Frequ
      display_frequ(my_val, 1, 512);
      |
    tm_tuning:
      if my_val >= 7 then
        write(LCDOut_M,'+');
        write(LCDOut_M, ByteToStr(my_val - 7));
        write(LCDOut_M,' Hz');
      else
        write(LCDOut_M,'-');
        write(LCDOut_M, ByteToStr(7 - my_val));
        write(LCDOut_M,' Hz');
      endif;
      disp_arrow_clreol;
      |
    tm_items_gatingmode:
      my_Pointer:= @s_GatingModeArr;
      |
    tm_items_splitm:
      my_Pointer:= @s_MenuSplitmodeArr;
      |
    tm_items_localena:
      my_Pointer:= @s_LocalEnableArr;
      |
    tm_items_midiopt:
      my_Pointer:= @s_MenuMidiOptArr;
      |
    tm_items_ccset:
      edit_MIDI_CC_Set:= my_val;
      NB_CCarrayFromDF(edit_MIDI_CC_Set);
      MIDI_SendSustainSostEnable;
      edit_MIDI_CC_Set_flag:= 0;
      DisplayBottom(MIDIset_CCdisplayedName);
      disp_arrow_clreol;
      |
    tm_items_waveset:
      my_Pointer:= @s_MenuWaveArr;
      |
    tm_items_capset:
      my_Pointer:= @s_MenuTaperingArr;
      |
{

    tm_modphasebits:
      LCDxy_M(LCD_m1, 0, 0);
      write(LCDOut_M, s_VibBitfieldArr[EditFieldIndex]);
      LCDOut_M(#32);
      lo(my_bitfield):= edit_PreemphPhase;
      EditBitfield(my_bitfield, 7, EditFieldIndex, delta, true);
      edit_PreemphPhase:= lo(my_bitfield);
      disp_arrow_clreol;
      |
    tm_items_swelltype:
      my_Pointer:= @s_MenuSwellTypeArr;
      |
    tm_items_spread:
      my_Pointer:= @s_MenuSpreadArr;
      |
    tm_items_fb16:
      my_Pointer:= @s_MenuFoldbackArr;
      |
    tm_genvibmode:
      my_Pointer:= @s_GenVibArr;
      my_val:= ValueTrimLimit(my_val, 0, edit_GeneratorModelLimit);
      |
}
    tm_items_organmodel:     //
      if not HasExtendedLicence then
        my_val:= ValueTrimLimit(my_val, 0, 3);
      endif;
      my_Pointer:= @s_organModelArr;
      |
    tm_items_speakermodel:     //
      if not HasExtendedLicence then
        my_val:= ValueTrimLimit(my_val, 0, 5);
      endif;
      my_Pointer:= @s_speakerModelArr;
      |
    tm_setupfile:
      if change_menu_only then
        DisplayBottom('Wait...');
        NumberOfIniFiles:= SD_GetDir('*.INI', false);  // erstmalig lesen
        edit_CardSetup:= 0;
      endif;
      if NumberOfIniFiles > 0 then
        ApplyDelta(edit_CardSetup, 0, NumberOfIniFiles - 1, delta);
        DisplayBottom(BlockArrayDirFileNames[edit_CardSetup]);
      else
        DisplayBottom('<Empty>');
      endif;
      LCDOut_M_space;
      DT_LeftArrowClrEol;
      return;
      |
    tm_savedefault, tm_bootloader,      //
    tm_initwifi, tm_initpreset:     //
      LCDxy_M(LCD_m1, 14, 0);
      LCDOut_M_space;
      DisplayBottom('Press Btn 2sec');
      ValueChangeMode:= false;
      DT_LeftArrowClrEol;
      return;
      |
  else
    MenuDispValueArrow(my_val);
  endcase;

  if my_Pointer <> nil then
    // Textanzeige mit Offset zur Text-Tabelle
    MenuDispListItemArrow(my_pointer, my_val);
  endif;

  PA_GetParamByte(my_param_idx, m, true); // m aus Vergleichstabelle holen
  if value_changed then
    PA_NewParamEvent(my_param_idx, my_val, false, c_menu_event_source);
    if my_val <> m then
      CommonPresetInvalid:= true;
    endif;
  endif;
  if my_menutype in [tm_items_phrmode..tm_adsrena_lwr] then
    MenuDispChangedStar(value_changed);
  else
    MenuDispChangedStar(my_val <> m);
  endif;
end;

// #############################################################################

function menu_RequestNewPresetNumber(const old_preset, max_preset: byte; const my_dest: char): byte;
var new_preset: byte;
begin
  new_preset:= old_preset;
  DT_MsgToPreset(my_dest);
  menu_WaitPanelButtonsReleased;   // warten auf Loslassen
  repeat
    //LCDxy_M(LCD_m1, 13, 1);
    LCDxy_M(LCD_m1, 4, 1);
    lcd_number2(new_preset);
    LCDOut_M(#7);
    MainTasks; // muss wg. diverser Updates immer aufgerufen werden
    DT_GetEncoderKnobDelta;
    ApplyDelta(new_preset, 0, max_preset, EncoderDelta);
  until DT_PanelButtonPressed(10);
  return(new_preset);
end;

function menu_RequestNewModel(const old_preset: byte; const my_dest: char): byte;
var new_preset, limit: byte;
begin
  new_preset:= old_preset;
  DT_MsgToPreset(my_dest);
  menu_WaitPanelButtonsReleased;   // warten auf Loslassen
  repeat
    //LCDxy_M(LCD_m1, 13, 1);
    LCDxy_M(LCD_m1, 0, 1);
    limit:= 15;
    if my_dest = 'O' then
      if not HasExtendedLicence then
        limit:= ValueTrimLimit(limit, 0, 3);
      endif;
      DisplayBottom(s_OrganModelArr[new_preset]);
    elsif my_dest = 'R' then
      if not HasExtendedLicence then
        limit:= ValueTrimLimit(limit, 0, 5);
      endif;
      DisplayBottom(s_speakerModelArr[new_preset]);
    endif;
    LCDOut_M(#7);
    MainTasks; // muss wg. diverser Updates immer aufgerufen werden
    DT_GetEncoderKnobDelta;
    ApplyDelta(new_preset, 0, limit, EncoderDelta);
  until DT_PanelButtonPressed(10);
  return(new_preset);
end;

// #############################################################################
// ###                 Behandlung ENTER-Button (Drehknopf)                   ###
// #############################################################################

procedure MenuEnterButton;
// Enter-Button gedr�ckt: Entweder zur�ck zur DB-Anzeige
// oder gerade aufgerufenen Eintrag speichern
var
  old_val: Byte;
  my_save_dest_char: char;
  my_idx: Integer;
  menu_type: t_menuType;
begin
  if menu_PanelButtonTimeout(100) then // Timeout 2 Sek. erreicht, User will abspeichern
    menu_type:= c_MenuTypeArr[MenuIndex];
    my_save_dest_char:= menu_GetSaveDestination(MenuIndex);

    case menu_type of
    tm_preset_common:
      my_save_dest_char:= 'C';
      |
    tm_preset_upper:
      my_save_dest_char:= 'U';
      |
    tm_preset_lower:
      my_save_dest_char:= 'L';
      |
    tm_preset_pedal:
      my_save_dest_char:= 'P';
      |

    tm_setupfile:
      // Sondefall: INI-File-Men� ist kein Default, Skript ausf�hren
      if NumberOfIniFiles > 0  then
        SerInpStr:= BlockArrayDirFileNames[edit_CardSetup];
        PA_RunSDscript(SerInpStr);
        menu_WaitPanelButtonsReleased;
        MenuIndex_Requested:= MenuIndex;       // zur�ck
      endif;
      return;
      |
    tm_initwifi:
      // Sondefall: WIFI-Init
      NB_SendBinaryVal(1698,127);
      mdelay(50);
      NB_SendBinaryVal(1699,127);
      DisplayHeader('WiFi Init done');
      DisplayBottom('Re-config WiFi!');
      LED_blink(5);
      LCDclr_M(LCD_m1);
      MenuIndex_Requested:= MenuIndex;  // zur�ck
      return;
      |
    tm_bootloader:
      // DFU starten
      ValueByte:= 1;
      PA_SetParam(8209, false);
      LCDclr_M(LCD_m1);
      DisplayHeader('DFU Start');
      menu_WaitPanelButtonsReleased; // warten bis Drehknopf losgelassen
      // MenuIndex_Requested nicht setzen, Meldung bleibt bis Ende oder Abbruch
      return;
      |
    tm_initpreset: // Init Preset Defaults
      NB_init_edittable;
      LCDclr_M(LCD_m1);
      DisplayHeader('Preset 0 Init');
      DisplayBottom('to Std B3');
      for i:= 0 to 255 do
        edit_array_flag_0[i]:= c_to_fpga_event_source;
      endfor;
      for i:= 0 to 255 do
        edit_array_flag_1[i]:= c_to_fpga_event_source;
      endfor;
      LED_blink(5);
      LCDclr_M(LCD_m1);
      MenuIndex_Requested:= MenuIndex;  // zur�ck
      return;
      |
    endcase;
    if my_save_dest_char = #32 then
      return;
    endif;
    case my_save_dest_char of
      'C': // bei 0 ins EEPROM, Startup Defaults
        PresetStoreRequest:= true;   // nicht neu laden
        edit_CommonPreset:= menu_RequestNewPresetNumber(edit_CommonPreset_old, 99, my_save_dest_char);
        SaveCommonPreset(edit_CommonPreset);
        edit_CommonPreset_flag:= 0;
        |
      'U': // edit_UpperVoice zum Kopieren auf andere Position
        edit_UpperVoice:= menu_RequestNewPresetNumber(edit_UpperVoice, 15, my_save_dest_char);
        SaveUpperVoice;
        |
      'L': // edit_LowerVoice zum Kopieren auf andere Position
        edit_LowerVoice:= menu_RequestNewPresetNumber(edit_LowerVoice, 15, my_save_dest_char);
        SaveLowerVoice;
        |
      'P': // edit_PedalVoice zum Kopieren auf andere Position
        edit_PedalVoice:= menu_RequestNewPresetNumber(edit_PedalVoice, 15, my_save_dest_char);
        SavePedalVoice;
        |
      'O': // Organ Model
        edit_OrganModel:= menu_RequestNewModel(edit_OrganModel, 'O');
        SR_StoreOrganModel(edit_OrganModel);
        |
      'R': // Speaker/Rotary Model
        edit_SpeakerModel:= menu_RequestNewModel(edit_SpeakerModel, 'R');
        SR_StoreSpeakerModel(edit_SpeakerModel);
        |
      'D': // Defaults abspeichern
        // sind nie 0-Parameter-Indexe, immer ins EEPROM
        my_idx:= c_Index2ParamArr[MenuIndex];
        PA_GetParamByte(my_idx, old_val, false); // aus edit_table
        PA_NewParamEvent(my_idx, old_val, true, 0);  // in EEPROM f�r edit_CommonPreset 0 Startup
        |
    endcase;
    DT_MsgSaveDoneBlink(my_save_dest_char);
  else
    if isSysTimerZero(ActivityTimer) then
      ValueChangeMode:= not ValueChangeMode;
      setsystimer(ActivityTimer, 200);
    else
      PresetPreview:= false;
      // DT_InitLCD;
      ValueChangeMode:= false;
      // kein Save-Timeout, Wechsel zur�ck auf Common Preset
      MenuIndex:= c_MenuCommonPreset;    // wieder zur�ck
      IsInMainMenu:= true;
    endif;
    if DFUrunning then
      ValueByte:= 0;
      PA_SetParam(8209, false);  // DFU Modus beenden
      MenuIndex_Requested:= MenuIndex;  // zur�ck
    endif;
  endif;
end;

// #############################################################################


procedure MenuPanelHandling;
// Men�-Bedienung und Einstellungen �ber Display, Buttons und Drehgeber
// wertet DisplayDisplayRequest aus und setzt dieses zur�ck, sobald angezeigt
// type t_ovr = (t_inrange, t_overrange, t_underrange);
// type t_menuvalid = (t_menu_hidden, t_menu_invalid, t_menu_valid);
var
  my_ovr_dir: t_ovr;
//  my_menutype: t_menuType;
//  my_menuvalid: t_menuvalid;
begin
  if not LCDpresent then
    return;
  endif;

  if MenuPanelLEDsPresent then  // gro�es MenuPanel mit 7 LEDs
    m:= EC_LogicalTabsToByte(0) xor $FF;
    if edit_LogicalTab_LeslieRun then
      if SpeedBlinkToggle then
        m:= m xor %01000000;
      endif;
    else
      m:= m or %01000000; // RUN-LED aus
    endif;
    if DisablePercussion or (not edit_LogicalTab_PercOn) then
      m:= m or %00001111;
    endif;
    MenuPanelLEDsOut:= m;
  endif;

  DT_GetEncoderKnobDelta;  // bei Drawbar beschleunigen
  DT_GetButtonDelta;

  if PanelButtonEnter then
    if IsInBitfield then
      DoMenuChange(0, false, true);
    else
      MenuEnterButton;
      menu_WaitPanelButtonsReleased;
      DT_ResetEncoderKnob;
      EncoderDelta:= 0;
      DT_GetMenuStatus;       // Menu k�nnte sich komplett ge�ndert haben
      DoMenuChange(0, true, false);  // Men�punkt ge�ndert
    endif;
    DT_SetUpDownArrows;
  endif;

  // Men� oder Bitfield-Index �ndern
  if ButtonPressed then
    MIDI_SendController(0, 123, 127);
    MIDI_SendController(1, 123, 127);
    MIDI_SendController(2, 123, 127);
    PresetNameEdit:= false;
    if (ButtonDelta > 0) and (IsInMainMenu) then
      // nach oben, Hauptmen�-Anfang
      MenuIndex:= c_MenuCommonPreset;    // wieder zur�ck
    elsif (ButtonDelta > 0) and (not IsInMainMenu) then
      // nach oben, zur�ck zum Hauptmen�
      MenuIndex:= LastMainMenuIndex;
    elsif (ButtonDelta < 0) and (IsInMainMenu) then
      // nach unten: Aus Haupmen� in Submen�-Anfang
      LastMainMenuIndex:= MenuIndex;
      MenuIndex:= c_MenuGotoArr[MenuIndex];  // nur 0..c_MainMenuEnd
      DT_GetNextValidMenuIndex(0);
      EditFieldIndex:= 0;
    elsif (ButtonDelta < 0) and (not IsInMainMenu) then
      // nochmal nach unten, Submen�-Anfang
      MenuIndex:= c_MenuGotoArr[LastMainMenuIndex];  // nur 0..c_MainMenuEnd
      DT_GetNextValidMenuIndex(0);
      EditFieldIndex:= 0;
    endif;
    ValueChangeMode:= false;  // immer mit Scroll-Modus beginnen
    DT_GetMenuStatus;         // Menu k�nnte sich komplett ge�ndert haben
    DoMenuChange(0, true, false);    // Men�punkt ge�ndert
    DT_SetUpDownArrows;
    menu_WaitPanelButtonsReleased;
    EncoderDelta:= 0;
  endif;

  // Wert-�nderungen, auch f�r Bitfields
  if EncoderChanged then
    if ValueChangeMode then
      DoMenuChange(EncoderDelta, false, false);  // Wert ge�ndert
    else
      if (IsInEditName or IsInBitField) then
        // in Bitfield, Buttons scrollen immer
        my_ovr_dir:= ApplyDelta(EditFieldIndex, 0, EditFieldSize, EncoderDelta);
        if my_ovr_dir = t_overrange then
          DT_GetNextValidMenuIndex(1);
        elsif my_ovr_dir = t_underrange then
          DT_GetNextValidMenuIndex(-1);
        endif;
      else
        // nicht in Bitfield
        DT_GetNextValidMenuIndex(EncoderDelta);
        DT_GetMenuStatus;         // Menu k�nnte sich komplett ge�ndert haben
        if EncoderDelta > 0 then  // nach oben gescrollt
          EditFieldIndex:= 0;
          // writeln(serout,'/ Menu up, 0');
        elsif EncoderDelta < 0 then
          EditFieldIndex:= EditFieldSize;
          // writeln(serout,'/ Menu dwn, 11');
        endif;
      endif;
      DT_GetMenuStatus;       // Menu k�nnte sich komplett ge�ndert haben
      DoMenuChange(0, true, false);  // Men�punkt ge�ndert
    endif;
    DT_SetUpDownArrows;
    ResetSysTimer(ActivityTimer);
  endif;

  if Bit(edit_ConfBits, 7) and (MenuIndex_SplashIfEnabled <> 255) then
    // kurz auf MenuIndex_SplashIfEnabled wechseln, danach wieder zur�ck
    // nur wenn ConfBit 7 gesetzt ist
    MenuIndex_Splash:= MenuIndex_SplashIfEnabled;
    MenuIndex_SplashIfEnabled:= 255;
  endif;

  if (MenuIndex_Splash <> 255) then
    // kurz auf #MenuIndex_Splash wechseln, danach wieder zur�ck
    MenuIndex_Requested:= MenuIndex;
    MenuIndex:= MenuIndex_Splash;
    DT_GetMenuStatus;       // Menu k�nnte sich komplett ge�ndert haben
    DoMenuChange(0, true, false);  // Men�punkt ge�ndert
    setSysTimer(ActivityTimer, 500); // zur�ck nach 1 Sekunde
    MenuIndex:= MenuIndex_Requested;
    MenuIndex_Splash:= 255;
  endif;

  if isSystimerzero(ActivityTimer) then
    // Neues Men� angefordert: Wenn ActivityTimer abgelaufen ist,
    // Anzeige auf #MenuIndex setzen und Wert neu anzeigen
    if (MenuIndex_Requested <> 255) then
      MenuIndex:= MenuIndex_Requested;
      DT_GetMenuStatus;       // Menu k�nnte sich komplett ge�ndert haben
      DoMenuChange(0, true, false);  // Men�punkt ge�ndert
      // auf aktuelle Anzeige #MenuIndex wechseln und aktualisieren
      MenuIndex_Requested:= 255;
      MenuRefresh:= true;  // ggf. angezeigten Wert aktualisieren
    endif;
    // Wenn ActivityTimer abgelaufen ist,
    // nur Wert aktualisieren (z.B. wenn extern ge�ndert)
    if MenuRefresh then
      //aktuelle Anzeige #MenuIndex aktualisieren
      DoMenuChange(0, False, false);  // nur Wert ge�ndert
      DT_SetUpDownArrows;
      setSysTimer(ActivityTimer, 50); // Update alle 50 ms reicht
      MenuRefresh:= false;
    endif;
  endif;
end;

end menu_system.


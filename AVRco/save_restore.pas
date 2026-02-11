// #############################################################################
// ###                 LOAD/SAVE PRESETS FROM EEPROM                         ###
// #############################################################################
Unit save_restore;

interface
{$IFDEF MODULE}
uses const_def, var_def, port_def, nuts_and_bolts;
{$ELSE}
uses const_def, var_def, port_def, nuts_and_bolts, adc_touch_interface;
{$ENDIF}

procedure LoadDrawbarDefaults;

{$IFNDEF MODULE}

procedure LoadUpperVoice(const new_index:byte);
procedure LoadLowerVoice(const new_index:byte);
procedure LoadPedalVoice(const new_index:byte);

procedure SaveUpperVoice;
procedure SaveLowerVoice;
procedure SavePedalVoice;

procedure SR_StoreOrganModel(organ: byte);
function  SR_LoadOrganModel(organ: byte): Boolean;
procedure SR_StoreSpeakerModel(leslie: byte);
function  SR_LoadSpeakerModel(leslie: byte): Boolean;

procedure SaveCommonPreset(var new_index:byte);
procedure InitCommonPresets;

function LoadPresetFromBlockBuffer: Boolean;

procedure SR_UpperLiveToTemp;
procedure SR_UpperTempToLive;
procedure SR_LowerLiveToTemp;
procedure SR_LowerTempToLive;
procedure SR_PedalLiveToTemp;
procedure SR_PedalTempToLive;

procedure SR_PresetLiveToTemp;
procedure SR_PresetTempToLive;


{$ENDIF}


implementation

// #############################################################################
// ###                       ORGAN/SPEAKER MODELS                            ###
// #############################################################################

function SR_LoadSpeakerModel(leslie: Byte): Boolean;
// kopiert nur für Rotary-Modell relevante Teile ins edit_array
// liefert TRUE wenn Rotary-Modell gültig (> 0) und geladen
var result: Boolean;
begin
  result:= false;
  LED_timer150;
  DF_ReadBlock(c_leslieModel_base_DF + word(leslie), c_edit_array_len);  // 512 Bytes!
  if (BlockBuffer8[c_EditMagicFlagIdx] = $AA)
  and (BlockBuffer8[c_PresetStructure] >= c_MinimalRotaryStructureVersion) then
{$IFDEF DEBUG_SR}
  writeln(serout, '/ SR LoadSpeakerModel #' + ByteToStr(leslie));
{$ENDIF}
    result:= true;
    CopyBlock(@BlockBuffer8, @edit_LeslieInits, c_leslie_array_len);
    CopyBlock(@BlockBuffer8 + c_leslie_array_len, @edit_RotaryGroup, 16);
    FillEventSource(c_RotaryGroup, 16, c_preset_event_source);
  endif;
  return(result);
end;

procedure SR_StoreSpeakerModel(leslie: Byte);
// Speichert kompletten edit_array-Abzug in c_organModel_base_DF + organ
begin
{$IFDEF DEBUG_SR}
  writeln(serout, '/ SR StoreSpeakerModel #' + ByteToStr(leslie));
{$ENDIF}
   LED_timer250;
  FillBlock(@BlockBuffer8, c_edit_array_len, 255); // 512 Bytes, nur 64 Bytes benutzt
  CopyBlock(@edit_LeslieInits, @BlockBuffer8, c_leslie_array_len);
  CopyBlock(@edit_RotaryGroup, @BlockBuffer8 + c_leslie_array_len, 16);
  BlockBuffer8[c_PresetStructure]:= c_CurrentRotaryStructureVersion;
  BlockBuffer8[c_EditMagicFlagIdx]:= $AA;   // valid Rotary setzen
  DF_EraseWriteBlock(c_leslieModel_base_DF + word(leslie), c_edit_array_len); // 512 Bytes
  MenuRefresh:= true;
end;

// -----------------------------------------------------------------------------

function SR_LoadOrganModel(organ: Byte): Boolean;
// Ähnlich wie Preset Load,
// kopiert nur für Orgelmodell relevante Teile ins edit_array
// liefert TRUE wenn Orgelmodell gültig (> 0) und geladen
var temp_tuning, temp_transpose: Byte;
  result: Boolean;
  idx_w, temp_w: Word;
  blockarr_val, save_dest, control_type: Byte;
begin
  result:= false;
  LED_timer150;
  // komplett lesen wg. MagicFlag
  DF_ReadBlock(c_organModel_base_DF + Word(organ), c_edit_array_len);
  if (BlockBuffer8[c_EditMagicFlagIdx] = $A5)
  and (BlockBuffer8[c_PresetStructure] >= c_MinimalOrganStructureVersion) then
{$IFDEF DEBUG_SR}
    writeln(serout, '/ SR LoadOrganModel #' + ByteToStr(organ));
{$ENDIF}
    result:= true;
    for idx_w:= c_PreampGroup to c_SystemInits - 1 do
      // unnötige Werte und Tabs überspringen
      if valueInRange(idx_w, c_UpperEnvelopeDBs, c_SaveEventPedal) then
        continue;
      endif;
      blockarr_val:= BlockBuffer8[idx_w];
      if edit_array[idx_w] = blockarr_val then
        continue;
      endif;
      temp_w:= c_SaveRestoreMasks[idx_w];
      save_dest:= hi(temp_w) and $0F; // unteres Nibble
      if (save_dest = c_savedestNone) then
        continue;
      endif;
      control_type:= hi(temp_w) shr 4;   // oberes Nibble
      if (control_type = c_controlTypeSaveEnter) then
        continue;
      endif;
      // Bits 8..11 benötigt
      if (save_dest = c_savedestOrganModel) then  // freigegeben und Werte abweichend?
        NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
      endif;
    endfor;
  endif;
  return(result);
end;

procedure SR_StoreOrganModel(organ: Byte);
// Speichert kompletten edit_array-Abzug in c_organModel_base_DF + organ
begin
{$IFDEF DEBUG_SR}
  writeln(serout, '/ SR StoreOrganModel #' + ByteToStr(organ));
{$ENDIF}
  LED_timer250;
  CopyBlock(@edit_array, @BlockBuffer8, c_edit_array_len);
  BlockBuffer8[c_PresetStructure]:= c_CurrentOrganStructureVersion;
  BlockBuffer8[c_EditMagicFlagIdx]:= $A5;   // valid setzen
  DF_EraseWriteBlock(c_organModel_base_DF + Word(organ), c_edit_array_len);
  MenuRefresh:= true;
end;

// #############################################################################
// ###                         COMMON PRESET                                 ###
// #############################################################################

function LoadPresetFromBlockBuffer: Boolean;
// Value Type Bits 12..15
// 0 = None
// 1 = Button
// 2 = Knob
// 3 = Analog
// 4 = Convert Button to Knob
// 5 = Convert Knob to Button
// 6 = Momentary/Pulse/RadioBtn
// 7 = Number
// 8 = String

// Save Dest (MenuPanel-Destination-Anzeige) Bits 8..11
// 0 = None/Unsaved
// 1 = Common Preset
// 2 = Defaults
// 3 = System Inits
// 4 = Upper Drawbars
// 5 = Lower Drawbars
// 6 = Pedal Drawbars
// 7 = (unused)
// 8 = Organ Model
// 9 = Speaker Model
// 10 = Common Preset, valid only if PresetGM-Mask = 1
// 11 = Common Preset, valid only if PresetPercDB-Mask = 1

// Bit=1: Wert wird aus Preset geholt
// Bit 7    Bit 6       Bit 5       Bit 4       Bit 3           Bit 2           Bit 1           Bit 0
// PresetGM	PresetVolEq	PresetRoty	PresetTabs	PresetPercDBs	PresetPedalDBs	PresetLowerDBs	PresetUpperDBs

var struct_version: Byte;
  my_result, restore_flag: Boolean;
  idx_w, temp_w: Word;
  save_dest, control_type, restore_mask: Byte;
  blockarr_val: Byte;
begin
  CurrentPresetName:= s_none;
  my_result:= false;
  // if (BlockArrayMagicByte = $A5)
  // and (BlockArrayPresetVersion >= c_MinimalPresetStructureVersion) then
  if (BlockBuffer8[c_EditMagicFlagIdx] = $A5) then
    // Block ist ein Preset
    struct_version:= BlockBuffer8[c_PresetStructure];
    if struct_version >= c_MinimalPresetStructureVersion then
      // kompatibel mit alter Firmware, nur Drawbars und Tabs, GM
      for idx_w:= 0 to c_VibKnob do         // freigegeben und Werte abweichend?
        blockarr_val:= BlockBuffer8[idx_w];
        if edit_array[idx_w] = blockarr_val then
          continue;
        endif;
        temp_w:= c_SaveRestoreMasks[idx_w];
        save_dest:= hi(temp_w) and $0F; // unteres Nibble
        if (save_dest = c_savedestNone) then
          continue;
        endif;
        control_type:= hi(temp_w) shr 4;   // oberes Nibble
        if (control_type = c_controlTypeSaveEnter) then
          continue;
        endif;
        restore_mask:= lo(temp_w);
        case save_dest of
        c_savedestPreset, c_savedestUpperDBs, c_savedestLowerDBs, c_savedestPedalDBs:
          if ((restore_mask and edit_SaveRestoreMask) <> 0) then
            NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
          endif;
          |
        c_savedestPresetifGM:  // mit spezieller Bedingung
          if Bit(edit_SaveRestoreMask, c_presetGMRecallMaskBit)
          and ((restore_mask and edit_SaveRestoreMask) <> 0)  then
            NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
          endif;
          |
        c_savedestPresetifPercEG:  // mit spezieller Bedingung
          if Bit(edit_SaveRestoreMask, c_presetPercDBsRecallMaskBit)
          and ((restore_mask and edit_SaveRestoreMask) <> 0) then
            NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
          endif;
          |
        endcase;
      endfor;

      if struct_version >= c_CurrentPresetStructureVersion then
        for idx_w:= c_OrganModel to c_SpeakerModel do
          // kompatibel mit aktueller Firmware, auch Organ und Rotary Model
          blockarr_val:= BlockBuffer8[idx_w];
          if edit_array[idx_w] = blockarr_val then
            continue;
          endif;
          temp_w:= c_SaveRestoreMasks[idx_w];
          save_dest:= hi(temp_w) and $0F; // unteres Nibble
          // control_type:= hi(temp_w) shr 4;   // oberes Nibble
          restore_mask:= lo(temp_w);
          if valueInRange(save_dest, c_savedestPreset, c_savedestPresetifPercEG)
          and ((restore_mask and edit_SaveRestoreMask) <> 0) then
          // and (control_type <> c_controlTypeSaveEnter) then
            NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
          endif;
        endfor;
        for idx_w:= c_EnableUpperAudio to c_ReverbLevel_3 do
          // kompatibel mit aktueller Firmware, Manual Enables, Reverb Levels
          blockarr_val:= BlockBuffer8[idx_w];
          if edit_array[idx_w] = blockarr_val then
            continue;
          endif;
          temp_w:= c_SaveRestoreMasks[idx_w];
          save_dest:= hi(temp_w) and $0F; // unteres Nibble
          if (save_dest = c_savedestNone) then
            continue;
          endif;
          control_type:= hi(temp_w) shr 4;   // oberes Nibble
          if (control_type = c_controlTypeSaveEnter) then
            continue;
          endif;
          restore_mask:= lo(temp_w);
          if valueInRange(save_dest, c_savedestPreset, c_savedestPresetifPercEG)
          and ((restore_mask and edit_SaveRestoreMask) <> 0) then
            NewEditIdxEvent(idx_w, blockarr_val, c_preset_event_source);
          endif;
        endfor;
      else
        // nur kompatibel mit alter Firmware, B3 Std Leslie laden
        if edit_GatingKnob <> 0 then  // vorherige Einstellung!
          NewEditIdxEvent(c_GatingKnob, 0, c_preset_event_source);
        endif;
        if edit_OrganModel <> 0 then  // vorherige Einstellung!
          NewEditIdxEvent(c_OrganModel, 0, c_preset_event_source);
        endif;
        if edit_SpeakerModel <> 0 then  // vorherige Einstellung!
          NewEditIdxEvent(c_SpeakerModel, 0, c_preset_event_source);
        endif;
      endif;
      // Namen auf jeden Fall holen, wenn gültig
      if valueInRange(block_PresetNameLen, 1, 15) then
        CurrentPresetName:= block_PresetNameStr;
      else
        CurrentPresetName:= s_none;
      endif;
      my_result:= true;
    endif;
  else
    CurrentPresetName:= s_none;
    DisplayBottom('INVALID PRESET');
{$IFDEF DEBUG_SR}
    Serial1_sendstringCRLF('/ SR Preset invalid!');
{$ENDIF}
  endif;

  edit_ShowCC:= false;
  if Bit(edit_ConfBits2, 3) then
    edit_LogicalTab_PHR_Fast:= edit_LogicalTab_LeslieFast;              // PHR FAST
    edit_LogicalTab_PHR_Fast_flag:= c_preset_event_source;
  endif;

  NB_ValidateExtendedParams;
  NB_ResetSpecialFlags;
  CopyBlock(@edit_array, @edit_CompareArray_0, 496);

  ForceSplitRequest:= false;
  MenuRefresh:= true; // Namen anzeigen
  // CopyBlock(@edit_array, @edit_compare_array, c_common_preset_len);
  return(my_result);
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SR_PresetTempToLive;
// Holt Preset aus temp_Common, Umweg über LoadPresetFromBlockBuffer
var
  my_idx: Integer;
begin
  NB_ValidateExtendedParams;
  // Änderungen in edit_array_flag eintragen
  if valueInRange(temp_PresetNameLen, 1, 15) then
    CurrentPresetName:= temp_PresetNameStr;
  else
    CurrentPresetName:= s_none;
  endif;
  CopyBlock(@temp_Common, @BlockBuffer8, 512);
  LoadPresetFromBlockBuffer;  // Setzt Flags
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Common TempToLive');
{$ENDIF}
end;

procedure SR_PresetLiveToTemp;
begin
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Common LiveToTemp');
{$ENDIF}
  CopyBlock(@edit_array, @temp_Common, 512);
  temp_EditMagicFlagIdx:= $A5;      // stammt ja aus gültigen Daten
  temp_PresetStructure:= c_CurrentPresetStructureVersion;
  temp_PresetNameStr:= CurrentPresetName;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SaveEditDefaultsToEEPROM;
var my_idx: Integer;
begin
  edit_SingleDBtoLower:= false;
  edit_SingleDBtoPedal:= false;
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ SR Save defaults to EEPROM');
{$ENDIF}
  for my_idx:= 48 to c_SpeakerModel do    // DBs, Tabs, GM
    eep_defaults[my_idx]:= edit_array[my_idx];
  endfor;

  FillBlock(@edit_voices + 1, 3, 0);
  SaveUpperVoice;
  SaveLowerVoice;
  SavePedalVoice;
end;

procedure InitCommonPresets;
// initialisiert 99 Common Presets
var my_idx: Word;
begin
  edit_SingleDBtoLower:= false;
  edit_SingleDBtoPedal:= false;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Init Overall Presets 1..99');
{$ENDIF}
  FillBlock(@BlockBuffer8, 512, 255);  // löschen
  block_PresetNameStr:= s_none;
  BlockArrayPresetVersion:= 0;
  for my_idx:= 0 to 99 do
    DF_EraseWriteblock(c_preset_base_DF + my_idx, 512);
  endfor;
  FillBlock(@edit_LogicalTab_Specials, 16, 0);
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SaveCommonPreset(var new_index:byte);
// Für bis zu 99 Common Presets
begin
  FillBlock(@edit_LogicalTab_Specials, 16, 0);
  edit_SingleDBtoLower:= false;
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Save Overall Preset ' + bytetostr(new_index));
{$ENDIF}
  if (not valueInRange(CurrentPresetNameLen, 1, 15)) then
    CurrentPresetName:= s_none;
  endif;
  new_index:= valueTrimLimit(new_index, 0, 99);
  if new_index > 0 then // nicht Live-Preset 0
    FillBlock(@edit_voices + 1, 3, 0);
    FillBlock(@edit_voices_flag + 1, 3, 0);
    edit_PresetStructure:= c_CurrentPresetStructureVersion;
    edit_MagicFlag:= $A5;
    CopyBlock(@edit_array, @BlockBuffer8, 512);
    block_PresetNameStr:= CurrentPresetName;
    DF_EraseWriteblock(c_preset_base_DF + Word(new_index), 512);
  else
    SaveEditDefaultsToEEPROM;
  endif;
  CopyBlock(@edit_array, @edit_CompareArray_0, 496);
  CommonPresetInvalid:= false;
end;

// #############################################################################
// ###                            VOICES                                     ###
// #############################################################################

procedure SR_UpperTempToLive;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Upper TempToLive');
  {$ENDIF}
  // Kopieren und Änderungen in edit_array_flag eintragen
  for i:= 0 to 11 do
    n:= temp_VoiceUpperDrawbars[i];
    if n <> edit_UpperDBs[i]then
      edit_UpperDBs[i]:= n;
      edit_UpperDBs_flag[i]:= c_control_event_source;
    endif;
  endfor;
end;

procedure SR_UpperLiveToTemp;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Upper LiveToTemp');
  {$ENDIF}
  CopyBlock(@edit_UpperDBs, @temp_VoiceUpperDrawbars, SizeOf(temp_VoiceUpperDrawbars));
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SR_LowerTempToLive;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Lower TempToLive');
  {$ENDIF}
  // Kopieren und Änderungen in edit_array_flag eintragen
  for i:= 0 to 11 do
    n:= temp_VoiceLowerDrawbars[i];
    if n <> edit_array[i]then
      edit_LowerDBs[i]:= n;
      edit_LowerDBs_flag[i]:= c_control_event_source;
    endif;
  endfor;
end;

procedure SR_LowerLiveToTemp;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Lower LiveToTemp');
  {$ENDIF}
  CopyBlock(@edit_LowerDBs, @temp_VoiceLowerDrawbars, SizeOf(temp_VoiceLowerDrawbars));
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SR_PedalTempToLive;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Pedal TempToLive');
  {$ENDIF}
  // Kopieren und Änderungen in edit_array_flag eintragen
  for i:= 0 to 11 do
    n:= temp_VoicePedalDrawbars[i];
    if n <> edit_PedalDBs[i]then
      edit_PedalDBs[i]:= n;
      edit_PedalDBs_flag[i]:= c_control_event_source;
    endif;
  endfor;
  for i:= 0 to 3 do
    n:= temp_VoicePedalDrawbars4[i];
    if n <> edit_PedalDB4s[i]then
      edit_PedalDB4s[i]:= n;
      edit_PedalDB4s_flag[i]:= c_control_event_source;
    endif;
  endfor;
end;

procedure SR_PedalLiveToTemp;
begin
  {$IFDEF DEBUG_SR}
  writeln(serout,'/ (NB) Pedal LiveToTemp');
  {$ENDIF}
  CopyBlock(@edit_PedalDBs, @temp_VoicePedalDrawbars, SizeOf(temp_VoicePedalDrawbars));
  CopyBlock(@edit_PedalDB4s, @temp_VoicePedalDrawbars4, 4);
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure LoadUpperVoice(const new_index:byte);
// Voice aus EEPROM laden
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Load Upper Voice ' + bytetostr(new_index));
{$ENDIF}
  for i:= 0 to 11 do
    // 12 Zugriegel-Analogwerte
    edit_UpperDBs[i]:= eep_upperDBpresets[new_index, i];
  endfor;
  FillBlock(@edit_UpperDBs_flag, 12, c_preset_event_source);
  CopyBlock(@edit_array, @edit_CompareArray, 12);
  if edit_ActiveUpperIndirect = 0 then
    CopyBlock(@edit_array, @edit_UpperIndirectA_DBs, 12);
  else
    CopyBlock(@edit_array, @edit_UpperIndirectB_DBs, 12);
  endif;
  VoiceUpperInvalid:= false;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure LoadLowerVoice(const new_index:byte);
// Voice aus EEPROM laden
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Load Lower Voice ' + bytetostr(new_index));
{$ENDIF}
  for i:= 0 to 11 do
    // 12 Zugriegel-Analogwerte
    edit_lowerDBs[i]:= eep_lowerDBpresets[new_index, i];
  endfor;
  FillBlock(@edit_lowerDBs_flag, 12, c_preset_event_source);
  CopyBlock(@edit_array + 16, @edit_CompareArray + 16, 12);
  if edit_ActiveLowerIndirect = 0 then
    CopyBlock(@edit_array + 16, @edit_LowerIndirectA_DBs, 12);
  else
    CopyBlock(@edit_array + 16, @edit_LowerIndirectB_DBs, 12);
  endif;
  VoiceLowerInvalid:= false;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure LoadPedalVoice(const new_index:byte);
// Voice aus EEPROM laden
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Load Pedal Voice ' + bytetostr(new_index));
{$ENDIF}
  for i:= 0 to 11 do
    // 12 Zugriegel-Analogwerte
    edit_PedalDBs[i]:= eep_PedalDBpresets[new_index, i];
  endfor;
  FillBlock(@edit_PedalDBs_flag, 12, c_preset_event_source);
  for i:= 0 to 3 do
    // 4 Zugriegel-Analogwerte für 4 Pedal-Drawbars
    edit_PedalDB4s[i]:= eep_PedalDB4presets[new_index, i];
  endfor;
  FillBlock(@edit_PedalDB4s_flag, 4, c_preset_event_source);
  CopyBlock(@edit_array + 32, @edit_CompareArray + 32, 16);
  CopyBlock(@edit_array + 72, @edit_CompareArray + 72, 4);
  VoicePedalInvalid:= false;
end;

// #############################################################################

procedure LoadDrawbarDefaults;
// Einschalt-Defaults aus Voice 0
begin
  LoadUpperVoice(0);
  LoadLowerVoice(0);
  LoadPedalVoice(0);
end;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************


procedure SaveUpperVoice;
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Save Upper Voice ' + bytetostr(edit_UpperVoice));
{$ENDIF}
  for i:= 0 to 11 do
    eep_upperDBpresets[edit_UpperVoice, i]:= edit_UpperDBs[i];
  endfor;
//  SR_store_voice_to_current_preset(0, 48, 240);
  CopyBlock(@edit_array, @edit_CompareArray, 12);
  VoiceUpperInvalid:= false;
  edit_UpperVoice_old:= edit_UpperVoice;
  edit_UpperVoice_flag:= 0;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SaveLowerVoice;
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Save Lower Voice ' + bytetostr(edit_LowerVoice));
{$ENDIF}
  for i:= 0 to 11 do
    eep_LowerDBpresets[edit_LowerVoice, i] := edit_LowerDBs[i];
  endfor;
  CopyBlock(@edit_array + 16, @edit_CompareArray + 16, 12);
  VoiceLowerInvalid:= false;
  edit_LowerVoice_old:= edit_LowerVoice;
  edit_LowerVoice_flag:= 0;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SavePedalVoice;
begin
  LED_timer50;
{$IFDEF DEBUG_SR}
  writeln(serout,'/ SR Save Pedal Voice ' + bytetostr(edit_PedalVoice));
{$ENDIF}
  for i:= 0 to 11 do
    eep_PedalDBpresets[edit_PedalVoice, i] := edit_PedalDBs[i];
  endfor;
  for i:= 0 to 3 do
    // 4 Zugriegel-Analogwerte, wenn nur 4 Pedal-Drawbars benutzt werden
    eep_PedalDB4presets[edit_PedalVoice, i]:= edit_PedalDB4s[i];
  endfor;
  CopyBlock(@edit_array + 32, @edit_CompareArray + 32, 12);
  CopyBlock(@edit_array + 72, @edit_CompareArray + 72, 4);
  VoicePedalInvalid:= false;
  edit_PedalVoice_old:= edit_PedalVoice;
  edit_PedalVoice_flag:= 0;
end;
// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************

end save_restore.


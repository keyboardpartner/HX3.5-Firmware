// #############################################################################
// ###                       PRESET-Routinen HILEVEL                         ###
// #############################################################################
unit preset_interface;

interface
uses var_def, port_def, eeprom_def, nuts_and_bolts,
     save_restore, apply_changes;

{$IFDEF ALLINONE}
procedure PRE_Init;
procedure PRE_GetPresets;
{$ENDIF}

{ interface-Abschnitt }
implementation

var
{$IDATA}
  MemorizeTimer: Byte;
  PCA9532LED: LongInt;

// #############################################################################
// Standard Preset16-Version, Buttons, 1 oder 2 Panels
// #############################################################################
{$IFDEF ALLINONE}

procedure UpdatePresetLEDs(const my_i2cadr, my_preset: byte; const led_blink: Boolean);
// %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
var my_led: Byte;
begin
  my_led:= my_preset and 15;
  my_led:= my_led shl 1; // zurechtrücken
  if led_blink and BlinkToggle then
    PCA9532LED:= 2 shl my_led;
  else
    PCA9532LED:= 3 shl my_led;
  endif;
  TWIout(my_i2cadr, $16, PCA9532LED); // LEDs updaten
end;

procedure UpdatePresetLEDsplit(const my_i2cadr: Byte;
          const upper_row: Byte; const upperled_blink: Boolean;
          const Lower_row: byte; const lowerled_blink: Boolean);
var temp: byte;
begin
  temp:= Lower_row shl 1; // zurechtrücken
  if lowerled_blink and BlinkToggle then
    PCA9532LED:= 2 shl temp;
  else
    PCA9532LED:= 3 shl temp;
  endif;

  temp:= (upper_row shl 1) + 16; // zurechtrücken
  if upperled_blink and BlinkToggle then
    PCA9532LED:= PCA9532LED or (2 shl temp);
  else
    PCA9532LED:= PCA9532LED or (3 shl temp);
  endif;
  TWIout(my_i2cadr, $16, PCA9532LED); // LEDs updaten
end;

procedure PresetCopyBlink(my_i2cadr, my_old, my_new: byte);
begin
  for i:= 0 to 3 do
    MEMled(true);
    UpdatePresetLEDs(my_i2cadr, my_old, true); // Kopiert-von-Anzeige,
    mdelay(200);
    MEMled(false);
    UpdatePresetLEDs(my_i2cadr, my_new, true); // Wechelblinken mit der vorherigen LED
    mdelay(200);
  endfor;
end;

procedure PresetSaveFlash(const my_i2cadr: Byte);
begin
  // %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
  PCA9532LED:= $55555555;  // kurzer Bestätigungs-Flash aller LEDs
  TWIout(my_i2cadr, $16, PCA9532LED);
  mdelay(100);
  PCA9532LED:= 0;
  TWIout(my_i2cadr, $16, PCA9532LED);
end;

procedure get_first_bit_zero_in_i(const my_word: Word);
// gibt in i Bitposition von erster Null in my_word zurück
// oder 255, wenn nicht gefunden
begin
  if (my_word <> $FFFF) then   // negative Logik!
    for i:= 0 to 15 do
      if not Bit(my_word, i) then // invertiert, schalten nach Masse!
        return;
      endif;
    endfor;
  endif;
  i:= 255;
end;

function GetPresetButtonsLatched(my_panel:byte): byte;
// liefert aktuelle Tastennummer der externen Preset-Buttons
// my_panel = 0 für Upper, = 1 für Lower
var my_word: word;
// Temporär-Werte für Bedienfeld-Taster intern und extern auf HOAXPANEL 1.2 Platine:
  my_result, my_timeout: byte;
  my_save: boolean;
  my_i2cadr: byte;
begin
  my_timeout:= 100; // 1 Sekunde bis zum Speichern
  my_i2cadr:= $60 + my_panel;
  PCA9532LED:= 0;
  TWIout(my_i2cadr, $16, PCA9532LED); // immer alle LEDs abschalten
  repeat
// Button-Zustand lesen
    TWIout(my_i2cadr, $00);   // untere Reihe
    TWIinp(my_i2cadr, i);
    lo(my_word):= i;
    TWIout(my_i2cadr, $01);   // obere Reihe
    TWIinp(my_i2cadr, i);
    hi(my_word):= i;

    // mask CANCEL, Preset 12
    my_save := (i and %00001000) = 0; // überprüfen ob CANCEL (C=12) gedrückt
    get_first_bit_zero_in_i(my_word);   // erste gedrückte Taste feststellen
    my_result:= i;   // Ergebnis in i
    if my_save then  // zusätzlich CANCEL gedrückt?
      mdelay(10);
      dec(my_timeout);
    endif;
  until (not my_save) or (my_timeout=0);
  if my_timeout = 0 then
    if my_panel = 0 then
      MemorizeTimeOutUpper:=true;
    elsif my_panel = 1 then
      MemorizeTimeOutLower:=true;
    endif;
    PresetSaveFlash(my_i2cadr); // kurzer Bestätigungs-Flash aller LEDs
  endif;
  return(my_result);
end;

function GetPresetButtons(my_panel: byte): byte;
// liefert aktuelle Tastennummer der externen Preset-Buttons
// my_panel = 0 für Upper, = 1 für Lower
var my_word: word;
// Temporär-Werte für Bedienfeld-Taster intern und extern auf HOAXPANEL 1.2 Platine:
  my_result, my_timeout: byte;
  my_i2cadr: byte;

begin
  my_result:= 255; // wenn keine Taste gedrückt, default
  my_timeout:=100; // 2 Sekunde bis zum Speichern
  my_i2cadr:=PCA9532_0 + my_panel;
  repeat
    PCA9532LED:= 0;
    TWIout(my_i2cadr, $16, PCA9532LED); // abschalten
    TWIout(my_i2cadr, $00);   // untere Reihe
    TWIinp(my_i2cadr, i);
    lo(my_word):= i;
    TWIout(my_i2cadr, $01);   // obere Reihe
    TWIinp(my_i2cadr, i);
    hi(my_word):= i;
// Button-Zustand lesen
    get_first_bit_zero_in_i(my_word);   // erste gedrückte Taste feststellen
    if i < 255 then  // Ergebnis in i
      mdelay(10);
      dec(my_timeout);
      my_result:= i;
    endif;
// alten Zustand wiederherstellen
  until (i = 255) or (my_timeout=0);
  if my_timeout=0 then
    if my_panel = 0 then
      MemorizeTimeOutUpper:=true;
    elsif my_panel = 1 then
      MemorizeTimeOutLower:=true;
    endif;
    PresetSaveFlash(my_i2cadr); // kurzer Bestätigungs-Flash aller LEDs
  endif;
  return(my_result);
end;


// #############################################################################
// ###                       PRESET-Routinen HILEVEL                         ###
// #############################################################################

procedure PRE_GetPresets;
// Preset-Nummer aus Button-LED-Stellung ermitteln
var
  my_preset_temp: byte;
begin
  if UpperVoiceButtonsPresent then
    // Upper Preset Buttons, Preset-Panel #0
    if Bit(edit_ConfBits, 6) then
      my_preset_temp:= GetPresetButtonsLatched(0);
    else
      my_preset_temp:= GetPresetButtons(0);
    endif;
    if edit_PresetConfig = 2 then
      // Split Upper/Common
      if my_preset_temp <> 255 then // Tastennummer oder $FF wenn keine gedrückt
        if my_preset_temp < 8 then
          // 8 Buttons untere Reihe, Upper Voice
          if MemorizeTimeOutUpper then
            DT_MsgSaveDone(ts_voice_upr);
            PresetCopyBlink(PCA9532_0, edit_UpperVoice, my_preset_temp);
            SaveUpperVoice(my_preset_temp);
            MemorizeTimeOutUpper:= false;
          endif;
          edit_UpperVoice:= my_preset_temp;
          edit_UpperVoice_flag:= CurrentSendFlags; // erneut laden, falls gleich
          VoiceUpperInvalid:= false;
        else  // my_preset_temp >= 8
          edit_CommonPreset:= my_preset_temp - 8;
          // 8 Buttons obere Reihe, jetzt Common Presets
          if MemorizeTimeOutUpper then
            DT_MsgSaveDone(ts_preset_0);
            PresetCopyBlink(PCA9532_0, edit_CommonPreset + 8, my_preset_temp);
            SaveCommonPreset(edit_CommonPreset);
            MemorizeTimeOutUpper:= false;
          endif;
        endif;
        MenuIndex_ValChanged:= MenuIndex; // angezeigten Wert aktualisieren
      endif;
      UpdatePresetLEDsplit(PCA9532_0, edit_CommonPreset, false,
                                      edit_UpperVoice, VoiceUpperInvalid);

    elsif (edit_PresetConfig = 0) or (edit_PresetConfig = 3) then

      // Upper Preset Buttons normal
      if my_preset_temp <> 255 then // Tastennummer oder $FF wenn keine gedrückt
        if MemorizeTimeOutUpper then
          DT_MsgSaveDone(ts_voice_upr);
          PresetCopyBlink(PCA9532_0, edit_UpperVoice, my_preset_temp);
          SaveUpperVoice(my_preset_temp);
          MemorizeTimeOutUpper:= false;
        endif;
        MenuIndex_ValChanged:= MenuIndex; // angezeigten Wert aktualisieren
        edit_UpperVoice:= my_preset_temp;
        edit_UpperVoice_flag:= CurrentSendFlags; // erneut laden, falls gleich
        VoiceUpperInvalid:= false;
      endif;
      UpdatePresetLEDs(PCA9532_0, edit_UpperVoice, VoiceUpperInvalid);

    elsif edit_PresetConfig = 1 then
      // Split Upper/Lower
      if my_preset_temp <> 255 then // Tastennummer oder $FF wenn keine gedrückt
        if my_preset_temp >= 8 then
          // Upper
          if MemorizeTimeOutUpper then
            DT_MsgSaveDone(ts_voice_upr);
            PresetCopyBlink(PCA9532_0, edit_UpperVoice + 8, my_preset_temp);
            // Offset 8 für obere Reihe
            SaveUpperVoice(my_preset_temp - 8);
            MemorizeTimeOutUpper:= false;
          endif;
          edit_UpperVoice:= my_preset_temp - 8;  // obere Reihe
          edit_UpperVoice_flag:= CurrentSendFlags; // erneut laden, falls gleich
          VoiceUpperInvalid:= false;
        else
          // untere Reihe Lower
           if MemorizeTimeOutUpper then
            DT_MsgSaveDone(ts_voice_lwr);
            PresetCopyBlink(PCA9532_0, edit_LowerVoice, my_preset_temp);
            SaveLowerVoice(my_preset_temp);
            MemorizeTimeOutUpper:= false;
          endif;
          edit_LowerVoice:= my_preset_temp; // untere Reihe
          edit_LowerVoice_flag:= CurrentSendFlags; // erneut laden, falls gleich
          VoiceLowerInvalid:= false;
        endif;
        MenuIndex_ValChanged:= MenuIndex; // angezeigten Wert aktualisieren
      endif;

      // nur Upper Preset Button Panel
      UpdatePresetLEDsplit(PCA9532_0, edit_UpperVoice, VoiceUpperInvalid,
                                      edit_LowerVoice, VoiceLowerInvalid);
      
    endif;
  endif;

  if LowerVoiceButtonsPresent then
    // Lower Preset Buttons, Preset-Panel #1
    if Bit(edit_ConfBits, 6) then
      my_preset_temp:= GetPresetButtonsLatched(1);
    else
      my_preset_temp:= GetPresetButtons(1);
    endif;
    if edit_PresetConfig = 3 then
      // Split Common/Lower
      if my_preset_temp <> 255 then // Tastennummer oder $FF wenn keine gedrückt
        if my_preset_temp < 8 then
        // Lower Voice
          if MemorizeTimeOutLower then
            DT_MsgSaveDone(ts_voice_lwr);
            PresetCopyBlink(PCA9532_1, edit_LowerVoice, my_preset_temp);
            SaveLowerVoice(my_preset_temp);
            MemorizeTimeOutLower:= false;
          endif;
          edit_LowerVoice:= my_preset_temp;
          edit_LowerVoice_flag:= CurrentSendFlags;
          VoiceLowerInvalid:= false;
        else  // my_preset_temp >= 8
          // obere Reihe, jetzt Common Presets
          edit_CommonPreset:= my_preset_temp - 8;
          if MemorizeTimeOutLower then
            DT_MsgSaveDone(ts_preset_0);
            PresetCopyBlink(PCA9532_1, edit_CommonPreset + 8, my_preset_temp);
            SaveCommonPreset(edit_CommonPreset);
            MemorizeTimeOutLower:= false;
          endif;
        endif; // edit_PresetConfig = 3
        MenuIndex_ValChanged:= MenuIndex; // angezeigten Wert aktualisieren
      endif;
      UpdatePresetLEDsplit(PCA9532_1, edit_CommonPreset, false,
                                      edit_LowerVoice, VoiceLowerInvalid);
    else
      // normal Lower
      if my_preset_temp <> 255 then // Tastennummer oder $FF wenn keine gedrückt
        if MemorizeTimeOutLower then
          DT_MsgSaveDone(ts_voice_lwr);
          PresetCopyBlink(PCA9532_1, edit_LowerVoice, my_preset_temp);
          SaveLowerVoice(my_preset_temp);
          MemorizeTimeOutLower:= false;
        endif;
        edit_LowerVoice:= my_preset_temp;
        edit_LowerVoice_flag:= CurrentSendFlags; // erneut laden, falls gleich
        VoiceLowerInvalid:= false;
        MenuIndex_ValChanged:= MenuIndex; // angezeigten Wert aktualisieren
      endif;
      UpdatePresetLEDs(PCA9532_1, edit_LowerVoice, VoiceLowerInvalid);
    endif; // edit_PresetConfig = 3

  endif;     // LowerVoiceButtonsPresent

end;


// #############################################################################

procedure PRE_Init;
begin
  UpperVoiceButtonsPresent:= TWIStat(PCA9532_0); // externe Platine mit PCA9532
  LowerVoiceButtonsPresent:= TWIStat(PCA9532_1);
  if UpperVoiceButtonsPresent then
    writeln(serout,'/ Preset16 (upper) found');
  endif;
  if LowerVoiceButtonsPresent then
    writeln(serout,'/ Preset16 (lower) found');
  endif;
  NB_SetLEDdimmer;
  VoiceUpperInvalid:= false;
  VoiceLowerInvalid:= false;
end;
{$ENDIF}  // ALLLINONE

end preset_interface.


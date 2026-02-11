unit display_toolbox;

interface
uses var_def, port_def, edit_changes, nuts_and_bolts;

{$IDATA}

type t_menuvalid = (t_menu_hidden, t_menu_invalid, t_menu_valid);

{$IFNDEF MODULE}
procedure DT_Init;

procedure DT_SetUpDownArrows;

procedure DT_LeftArrowClrEol;
// procedure DispRightArrow;

// liefert t_menu_hidden, t_menu_invalid oder t_menu_valid
function DT_MenuEntryValid(const menu_idx: byte): t_menuvalid;
procedure DT_ResetMenuEnables;


procedure DisplayHeaderIndexed(const my_idx: byte);
procedure DisplayHeader(const my_str: String[15]);
procedure DisplayBottom(const my_str: String[15]);
procedure DisplayOnOff(const my_bool: boolean);

procedure LCDsetBitfield;
procedure LCDsetBar;
procedure DT_InitLCD;
// MenuIndex um menu_delta erhöhen/erniedrigen, Wrap around ausführen
procedure DT_GetNextValidMenuIndex(const delta: Int8);

procedure DT_MsgToPreset(const my_dest: char);
procedure DT_MsgSaveDone(const my_dest: char);  // Meldung "Save OK!"
procedure DT_MsgSaveDoneBlink(const my_dest: char);  // Meldung "Save OK!"

procedure DT_ResetEncoderKnob;
procedure DT_GetEncoderKnobDelta;
procedure DT_GetButtonDelta;
procedure DT_GetMenuStatus;  // setzt IsInBitField, IsInMainMenu
function DT_GetMenuMax(const my_menu_index: byte): byte;

// Holt Menupanel-Button-Status und liefert TRUE wenn Up/Down/Enter gedrückt
function DT_PanelButtonPressed(my_delay: word):Boolean;

procedure LCDOut_M_space;
procedure LCDout_Error;
{$ENDIF}

implementation
{$IDATA}
{$IFNDEF MODULE}
type t_charset03 = (t_charset03_none, t_charset03_bitfield, t_charset03_bar);
type t_charsetLR = (t_charsetLR_none, t_charsetLR_filled, t_charsetLR_gray);


const
  EncRast: Byte = 4;

var
  EncoderIntegratorTimer: Systimer8;
  LCDcharset_LRarrows: t_charsetLR;
  LCDcharset_chars: t_charset03;

procedure LCDOut_M_space;
begin
  LCDOut_M(#32);
end;

procedure LCDout_Error;
begin
  write(LCDOut_M, 'ERROR:');
end;


// #############################################################################
// ###                     LCD-Sonderzeichen setzen                          ###
// #############################################################################

procedure LCDsetBitfield;
begin
  if (LCDcharset_chars <> t_charset03_bitfield) then
    //LCDsetup_M(LCD_m1);
    LCDCharSet_M(LCD_m1, #0, $00, $0E, $11, $11, $11, $0E, $00, $00);  // 0
    LCDCharSet_M(LCD_m1, #1, $00, $0E, $1F, $1F, $1F, $0E, $00, $00);  // 1
    LCDCharSet_M(LCD_m1, #2, $00, $0A, $11, $00, $11, $0A, $00, $00);  // 0 gerasterte Darstellung
    LCDCharSet_M(LCD_m1, #3, $00, $0E, $1B, $15, $1B, $0E, $00, $00);  // 1 gerasterte Darstellung
    LCDcharset_chars:= t_charset03_bitfield;
    mdelay(5);
    LCDxy_M(LCD_m1, 0, 1);
    LCDcursor_M(LCD_m1, true, false);
  endif;
end;


procedure LCDsetBar;
begin
  if (LCDcharset_chars <> t_charset03_bar) then
    //LCDsetup_M(LCD_m1);
    LCDCharSet_M(LCD_m1, #0, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $00); // full bar
    LCDCharSet_M(LCD_m1, #1, $1F, $18, $18, $18, $18, $18, $1F, $00); // half bar
    LCDCharSet_M(LCD_m1, #2, $10, $10, $10, $10, $10, $10, $10, $00); // end bar
    LCDCharSet_M(LCD_m1, #3, $1F, $00, $00, $00, $00, $00, $1F, $00); // empty bar
    LCDcharset_chars:= t_charset03_bar;
    mdelay(5);
    LCDxy_M(LCD_m1, 0, 1);
    LCDcursor_M(LCD_m1, false, false);
  endif;
end;

procedure LCDset_LR_Arrows(filled_arrows: Boolean);
begin
  if filled_arrows then
    if (LCDcharset_LRarrows <> t_charsetLR_filled) then
      LCDCharSet_M(LCD_m1, #6, $04, $0A, $15, $00, $15, $0A, $04, $00); // Updown (grey)
      LCDCharSet_M(LCD_m1, #7, $02, $06, $0E, $1E, $0E, $06, $02, $00); // "<" Cursor filled (white)
      LCDcharset_LRarrows:= t_charsetLR_filled;
      mdelay(5);
    endif;
  else
    if (LCDcharset_LRarrows <> t_charsetLR_gray) then
      LCDCharSet_M(LCD_m1, #6, $04, $0E, $1F, $00, $1F, $0E, $04, $00); // Updown (white)
      LCDCharSet_M(LCD_m1, #7, $02, $04, $0A, $14, $0A, $04, $02, $00);  // "<" Cursor grey
      LCDcharset_LRarrows:= t_charsetLR_gray;
      mdelay(5);
    endif;
  endif;
end;

procedure DT_InitLCD;
begin
  if LCDsetup_M(LCD_m1) then
    mdelay(5);
    LCDCharSet_M(LCD_m1, #5, $1F, $19, $17, $1B, $1D, $13, $1F, $00); // "s" inv.
    mdelay(5);
    LCDsetBar;
    LCDpresent:= true;
    LCDhome_M(LCD_m1);
    mdelay(5);
    write(LCDOut_M, LCD1Str);
  {$IFDEF DEBUG_MSG}
    writeln(serout,'/ (RST) MenuPanel LCD I2C OK');
  {$ENDIF}
  endif;
end;

// #############################################################################
// ###                Display Buttons und Drehgeber                          ###
// #############################################################################

procedure DT_ResetEncoderKnob;
begin
  asm;
    CLI;
  endasm;
{
// für Encoder-BETA in Main
  IRQ_Incr0:= (PinA and 3);  // Ruheposition angenommen
  IRQ_Incr1:= IRQ_Incr0;
  IRQ_Incr_zero:= IRQ_Incr0;          // eingerastet
  IRQ_Incr_detent:= IRQ_Incr0 xor 3;  // OT "Zahn"
  IRQ_Incr_forward:= IRQ_Incr_detent xor 1; // Pin A invertiert
  IRQ_Incr_reverse:= IRQ_Incr_detent xor 2; // Pin B invertiert
  IRQ_Incr_delta_temp:= 0;
}
  IRQ_Incr0:= 3;  // Ruheposition
  IRQ_Incr1:= 3;
  IRQ_Incr_delta:= 0;
  asm;
    SEI;
  endasm;
  EncoderDiff:= 0;
end;

function DT_GetMenuMax(const my_menu_index: byte): byte;
// liefert Maximalwert des Menüeintrags über c_edit_max-Tabelle
var
  arr_idx: Integer;
  max_val: byte;
begin
  arr_idx:= c_Index2ParamArr[my_menu_index] - 1000;
  if valueInRange(arr_idx, 0, 511) then
    max_val:= c_edit_max[arr_idx];
  else
    max_val:= 255;
  endif;
  return(max_val);
end;


procedure DT_GetEncoderKnobDelta;
var
  encoder_delta_temp: Integer;
  max_val: byte;
begin
  // mit Beschleuningung für Drawbar/Poti-Werte
  asm;
    CLI;
  endasm;
  EncoderDelta:= IRQ_Incr_delta;
  IRQ_Incr_delta:= 0;
  asm;
    SEI;
  endasm;
  EncoderChanged:= (EncoderDelta <> 0);

  // Integrierer für Encoder-Absolutwert
  if isSystimerZero(EncoderIntegratorTimer) then
    setSysTimer(EncoderIntegratorTimer, 33); // 66 ms
    asm;
      CLI;
    endasm;
      EncoderDiff:= IRQ_Incr_acc;
      IRQ_Incr_acc:= 0;
    asm;
      SEI;
    endasm;
  endif;
  if abs(EncoderDiff) > 1 then
    max_val:= DT_GetMenuMax(MenuIndex);
    encoder_delta_temp:= muldivInt(Integer(max_val), Integer(EncoderDiff), 64);
    EncoderDelta := EncoderDelta + Int8(encoder_delta_temp);
  endif;
{$IFDEF DEBUG_SWI}
  if EncoderChanged then
    writeln(serout,'/ (DT) EncoderDelta: ' + IntToSTr(encoder_delta_temp));
    writeln(serout,'/ (DT) EncoderDiff: ' + IntToSTr(EncoderDiff));
  endif;
{$ENDIF}
end;

// #############################################################################

function DT_PanelButtonPressed(const my_delay: word):Boolean;
begin
  PanelButtonTemp := not (LCDportInp_M(LCD_m1) or %11000111);
  if my_delay > 0 then
    mDelay(my_delay);
  endif;
  if PanelButtonTemp = 0 then
    return(false);
  endif;
  return(true);
end;

// #############################################################################


function DT_MenuEntryValid(const menu_idx: byte): t_menuvalid;
// Menü-Eintrag vorhanden? Ist nur gültig, wenn KEIN phys.
// Bedienelement vorhanden ist und Lizenz den Eintrag zulässt.
// wird bei jedem Menüwechsel aufgerufen (Up/Down/Enter)
// type t_menuvalid = (t_menu_hidden, t_menu_invalid, t_menu_valid);
var
   menu_valid: t_menuvalid;
   my_mask, my_organ_type_bit: byte;
begin
  my_mask:= c_MenuMaskArr[menu_idx];
  menu_valid:= t_menu_valid;
  my_organ_type_bit:= valueTrimLimit(edit_GatingKnob, 0, 2); // Default EG

  if valueInRange(menu_idx, c_EquMenuStart, c_EquMenuEnd) then
    if ((not edit_EqualizerFullParametric) and (not Bit(my_mask, 7))) then
      menu_valid:= t_menu_invalid;
    endif;
  elsif not Bit(my_mask, my_organ_type_bit) then
    menu_valid:= t_menu_hidden;
  endif;

  if (not HasExtendedLicence) and (not Bit(my_mask, 6)) then
    // Eintrag ungültig
    menu_valid:= t_menu_hidden;
  endif;

  if not eep_MenuValidArr[menu_idx] then  // nicht anzeigen
    menu_valid:= t_menu_hidden;
  endif;

  if (menu_idx = c_KeybEarlySubmenu) and (ScanCoreID <> $51) then
    return(t_menu_hidden);
  endif;
{
  if (ScanCoreID = $53) then   // wenn MIDI Input
    MenuMaskArray[c_KeybTransposeMenu]:= 0;
    MenuMaskArray[c_LocalOnOffMenu]:= 0;
    MenuMaskArray[c_SplitOnMenu]:= 0;
    MenuMaskArray[c_SplitPointMenu]:= 0;
    MenuMaskArray[c_SplitModeMenu]:= 0;
  endif;
}

  return(menu_valid);
end;

procedure DT_ResetMenuEnables;
begin
// Alle Menüs wieder auf ON
  for i:= 0 to c_MenuLen do
     eep_MenuValidArr[i]:= true;
  endfor;
  NB_ValidateExtendedParams;
end;

// -----------------------------------------------------------------------------

procedure DT_GetMenuGroupLimits(const menu_idx: Byte; var first_menu, last_menu: Byte);
// Start und Ende des aktuellen Menü-Bereichs ermitteln
begin
  for i:= 0 to c_MenuGroups do
    first_menu:= c_MenuStartArr[i];
    last_menu:= c_MenuEndArr[i];
    if valueinRange(menu_idx, first_menu, last_menu) then
      break;
    endif;
  endfor;
end;

procedure DT_GetMenuStatus;
// Menü-Bedienung und Einstellungen über Display, Buttons und Drehgeber
// wertet DisplayDisplayRequest aus und setzt dieses zurück, sobald angezeigt
// type t_ovr = (t_inrange, t_overrange, t_underrange);
var
  my_menutype: t_menuType;
begin
  my_menutype:= c_MenuTypeArr[MenuIndex];
  IsInBitField:= my_menutype in [tm_adsrena_upr, tm_adsrena_lwr, tm_items_phrmode, tm_modphasebits];
  IsInEditName:= (my_menutype = tm_editname);
  if (my_menutype = tm_items_phrmode) or (my_menutype = tm_modphasebits) then
    EditFieldSize:= 7;
  elsif (my_menutype = tm_editname) then
    EditFieldSize:= 13;
  else
    EditFieldSize:= 11;
  endif;
  if DT_MenuEntryValid(MenuIndex) <= t_menu_invalid then
    IsInBitField:= false;
    ValueChangeMode:= false;
  endif;
  IsInMainMenu:= valueInRange(MenuIndex, c_MainMenuStart, c_MainMenuEnd);
end;

// -----------------------------------------------------------------------------

procedure DT_GetNextValidMenuIndex(delta: Int8);
// MenuIndex um menu_delta erhöhen/erniedrigen, ggf. Wrap around ausführen
// t_scroll_both, t_scroll_up, t_scroll_down, t_scroll_none
// type t_menuvalid = (t_menu_hidden, t_menu_invalid, t_menu_valid);
var
  search_index: Byte;
  first_menu, last_menu: Byte;
  valid: t_menuvalid;
  is_on_limit: Boolean;
begin
  DT_GetMenuGroupLimits(MenuIndex, first_menu, last_menu);
  is_on_limit:= false;
  search_index:= MenuIndex;
  repeat
    // wiederholen, bis gültiges Menü gefunden
    search_index:= search_index + byte(delta);
    // if Bit(edit_ConfBits, 5) then  // Wrap Menus?
      if (search_index > 200) or (search_index < first_menu) then // Überlauf Byte
        search_index:= last_menu;
      endif;
      if (search_index > last_menu) then
        search_index:= first_menu;
      endif;
    {
    else
      if (search_index > 200) or (search_index <= first_menu) then
        search_index:= first_menu;
        is_on_limit:= true;
      endif;
      if search_index >= last_menu then
        search_index:= last_menu;
        is_on_limit:= true;
      endif;
    endif;
    }
    // writeln(serout,'/ Menu: ' + bytetostr(search_index));
    valid:= DT_MenuEntryValid(search_index);

    // Ausgehend vom letzen Menü ein gültiges in Richtung Delta suchen;
    // Abbrechen wenn gefunden oder Ende erreicht
    // nur noch Einzelschritte, Richtung beibehalten
    if delta >= 0 then
      delta:= 1;
    else
      delta:= -1;
    endif;
  until (valid > t_menu_hidden) or is_on_limit;
  if (valid > t_menu_hidden) then
    MenuIndex:= search_index;
  endif;
end;

procedure DT_SetUpDownArrows;
// Up/Down-Arrows für derzeitige Richtung anhand des
// nächsten und vorherigen Eintrags setzen
// Weiße Up/Down-Arrows, wenn Submenu vorhanden
begin
  LCDset_LR_Arrows(ValueChangeMode); // filled wenn ValueChangeMode

  LCDxy_M(LCD_m1, 15, 0);
  LCDOut_M(#6);   // Updown, Farbe abhängig von ValueChangeMode
  LCDxy_M(LCD_m1, 15, 1);
  if IsInMainMenu then
    LCDOut_M(#32);
  else
    LCDOut_M(#5); // inv. "s" wenn im Submenü
  endif;

  if (IsInEditName or IsInBitField) then
    LCDxy_M(LCD_m1, EditFieldIndex, 1);
    if ValueChangeMode then
      LCDcursor_M(LCD_m1, true, true);
      LCDctrl_M(LCD_m1, $0F);  // Block Cursor
    else
      LCDcursor_M(LCD_m1, true, false);
      LCDctrl_M(LCD_m1, $0E);  // Underline Cursor
    endif;
  else
    LCDcursor_M(LCD_m1, false, false);
  endif;
end;

procedure DT_LeftArrowClrEol;
begin
  LCDOut_M(#7);
  LCDclreol_M(LCD_m1);
end;

// #############################################################################

procedure DT_GetButtonDelta;
begin
  ButtonDelta:= 0;
  ButtonPressed:= DT_PanelButtonPressed(0);
  if ButtonPressed then     // DT_PanelButtonPressed ist eine function!
    if PanelButtonDown then
      ButtonDelta:= -1;
    elsif PanelButtonUp then
      ButtonDelta:= 1;
    endif;
    mDelay(5);
  endif;
end;

// #############################################################################

procedure DisplayHeader(const my_str: String[15]);
// Display-Überschrift aus Array, Rest löschen und in zweite Zeile wechseln
begin
  LCDxy_M(LCD_m1, 0, 0);
  write(LCDOut_M, my_str);
  LCDclrEOL_M(LCD_m1);
  LCDxy_M(LCD_m1, 0, 1);
end;

procedure DisplayHeaderIndexed(const my_idx: byte);
// Display-Überschrift aus Array, Rest löschen und in zweite Zeile wechseln
begin
  if (my_idx = c_EnvEnaUpperMenu) and (edit_GatingKnob >= 2)then
    DisplayHeader('EG Dry  ');
  else
    DisplayHeader(s_MenuHeaderArr[my_idx]);
  endif;
end;

procedure DisplayBottom(const my_str: String[15]);
// Display-Überschrift aus Array, Rest löschen und in zweite Zeile wechseln
begin
  LCDxy_M(LCD_m1, 0, 1);
  write(LCDOut_M, my_str);
end;

procedure DisplayOnOff(const my_bool: boolean);
begin
  if my_bool then
    write(LCDOut_M, 'ON ');
  else
    write(LCDOut_M, 'OFF');
  endif;
end;

// #############################################################################
// ###                           Memorize-Anzeige                            ###
// #############################################################################

procedure msg_savedest(const my_dest: char);
begin
  case my_dest of
    'C':
      write(LCDOut_M, 'Preset');
      |
    'U':
      write(LCDOut_M, 'Upper');
      |
    'L':
      write(LCDOut_M, 'Lower');
      |
    'P':
      write(LCDOut_M, 'Pedal');
      |
    'D':
      write(LCDOut_M, 'Defaults');
      |
    'O':
      write(LCDOut_M, 'Organ');
      |
    'R':
      write(LCDOut_M, 'Rotary');
      |
  endcase;
end;

procedure DT_MsgToPreset(const my_dest: char);
begin
  if LCDpresent then
    LCDclr_M(LCD_m1);
    // Voices und edit_CommonPreset zum Kopieren auf andere Position
    write(LCDOut_M, 'Save ');
    msg_savedest(my_dest);
    if (my_dest <> 'D') then
      write(LCDOut_M, ' to');
    endif;
  endif;
end;

procedure DT_MsgSaveDone(const my_dest: char);  // Meldung "Save OK!"
begin
  if LCDpresent then
    LCDclr_M(LCD_m1);
    write(LCDOut_M, 'Saved to');
    LCDxy_M(LCD_m1, 0, 1);
    msg_savedest(my_dest);
    write(LCDOut_M, ' OK!');
    MenuIndex_Requested:= MenuIndex; // zurück zum letzen Menü
  endif;
end;

procedure DT_MsgSaveDoneBlink(const my_dest: char);  // Meldung "Save OK!"
begin
  DT_MsgSaveDone(my_dest);
  LED_blink(5);
  if LCDpresent then
    LCDclr_M(LCD_m1);
  endif;
end;

procedure DT_Init;
begin
  MenuIndex_Requested:= c_MenuCommonPreset;    // Index auf Common Presets
  LastMainMenuIndex:= c_MenuCommonPreset;
  if LCDpresent then
    LCDcharset_LRarrows:= t_charsetLR_none;
    LCDset_LR_Arrows(false); // Arrows gray
  endif;
  DT_GetMenuStatus;
  DT_ResetEncoderKnob;
end;
{$ENDIF}
end display_toolbox.


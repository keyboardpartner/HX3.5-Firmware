// #############################################################################
// ###                    HARDWARE-USER-INTERFACE                            ###
// ### von Hardware und Zielgerät abhängige Funktionen für User Interface    ###
// #############################################################################

// Buttons an PCA9532 bzw. Panel16 abfragen, bei Änderungen in edit-Table eintragen

unit switch_interface;

interface
uses var_def, port_def, eeprom_def, edit_changes,
     display_toolbox, adc_touch_interface, save_restore;

  procedure SWI_Init;      // Initialisiert Panel16, Remaps
  procedure SWI_InitButtons;
  procedure SWI_GetPanel16(const panel_nr: Byte);
  procedure SWI_HandleXB2panel;
  procedure SWI_ForceSwitchReload;
  procedure SWI_PresetLoadOrDisplayToggle(const preset_nr: Byte);
  function SWI_GetSwitchVibrato: Byte;   // aktuelle Stellung Drehschalter
  procedure SWI_GetSwitchVibratoChange;

// Physikalische Button-Nummer (fortlaufend 0..63 über alle Panel16) wird
// umgesetzt in einen Zeiger auf edit_LogicalTabs.

// PL7, obere Button-Reihe:
// Button/Bit  0        1         2         3        4      5       6      7
// Tabs0:   PERCON   PERCSOFT  PERCFAST  PERC_3RD  VIBUP  VIBLO   LRUN   LFAST

// PL11, untere Button-Reihe:
// Button      8        9        10       11         12     13      14      15
// Tabs2:   AMP_INS  SKR_INS PHR_UprON  PHR_LwrON   EFX1   EFX2   CONFIG  SPLIT

// Vibrato-Drehschalter (alle offen = V1, dh. Pin 1 des Drehschalters OFFEN!)
// PCA9554A   C1      V2        C2       V3       C3   (MEMUP  MEMLO  MEMLED)
//            \----------- Drehschalter -----------/    \- Taster -/

var
  SWI_InputBytes: Array[0..15] of Byte; // Letzter Port-Zustand für Parser
  MemorizeTimerPanel, MemorizeTimerXB2: Byte;
  PresetWasSaved: Boolean;

  // wird Cancel Key Voice Nummer wenn Cancel gedrückt, sonst 255:

  SWI_CancelActive_upr: Boolean;
  SWI_CancelActive_lwr: Boolean;

implementation
{$IDATA}

const
  c_hw_btntable_size: Byte = 96;
  c_hw_btntable_size_w: Word = 96;
  c_hw_btntable_max: Byte = c_hw_btntable_size - 1;

  // %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
  led_off: Byte = 0;
  led_on: Byte =     %01000000;
  led_dark: Byte =   %10000000;
  led_bright: Byte = %11000000;

  led_off_xb2: Byte = 0;
  led_on_xb2: Byte =  1;
  led_dark_xb2: Byte =    2;
  led_bright_xb2: Byte =  3;

  // %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
  c_XB2selects9532: Table[0..3] of word = (
                         // INPUT LOW    P0.2   P0.3   P0.4   P0.5
    %0100000000000000,   // ROW A P0.7   VIB    3RD    2ND    SOLO
    %0001000000000000,   // ROW B P0.6   S/F    EDIT   REC    CANCEL
    %0000000000000001,   // ROW C P0.0   PR4    PR3    PR2    PR1
    %0000000000000100);  // ROW D P0.1   PR8    PR7    PR6    PR5

var

  blinktoggle_old,
  swi_has_cancel_upr, swi_has_cancel_lwr: Boolean;
  swi_cancel_idx_upr: Byte;
  swi_cancel_idx_lwr: Byte;

{$IFNDEF MODULE}
  xb2_drawbar_mode: Byte; // 0 = Upper, 1 = Lower, 2 = Pedal
  xb2_hw_btnstates_old: Array[0..15]  of boolean;

  xb2_hw_tabs: Array[0..15]  of boolean;
  xb2_hw_tab_solo[@xb2_hw_tabs + 0]: boolean;
  xb2_hw_tab_2nd[@xb2_hw_tabs + 1]: boolean;
  xb2_hw_tab_3rd[@xb2_hw_tabs + 2]: boolean;
  xb2_hw_tab_vib[@xb2_hw_tabs + 3]: boolean;

  xb2_hw_tab_cancel[@xb2_hw_tabs + 4]: boolean;
  xb2_hw_tab_rec[@xb2_hw_tabs + 5]: boolean;
  xb2_hw_tab_edit[@xb2_hw_tabs + 6]: boolean;
  xb2_hw_tab_sf[@xb2_hw_tabs + 7]: boolean;

  xb2_hw_tab_pr1[@xb2_hw_tabs + 8]: boolean;
  xb2_hw_tab_pr2[@xb2_hw_tabs + 9]: boolean;
  xb2_hw_tab_pr3[@xb2_hw_tabs + 10]: boolean;
  xb2_hw_tab_pr4[@xb2_hw_tabs + 11]: boolean;

  xb2_hw_tab_pr5[@xb2_hw_tabs + 12]: boolean;
  xb2_hw_tab_pr6[@xb2_hw_tabs + 13]: boolean;
  xb2_hw_tab_pr7[@xb2_hw_tabs + 14]: boolean;
  xb2_hw_tab_pr8[@xb2_hw_tabs + 15]: boolean;

  xb2_hw_tabs_editmode: Array[0..15]  of boolean;
  xb2_hw_tab_edit_editmode[@xb2_hw_tabs_editmode + 6]: boolean;
{$ENDIF}

// %00 = OFF, %01 = ON, %10 = PWM_0 (darker), %11= PWM_1 (brighter)
  // Letzter Port-Zustand, direkt gelesen
  swi_hw_OldInputWords[@SWI_InputBytes]: Array[0..7] of Word;

  swi_hw_btnstates: Array[0..c_hw_btntable_max] of Byte; // aktueller LED-Zustand
  swi_hw_btnstates_old: Array[0..c_hw_btntable_max]  of boolean;
  swi_hw_btnstates_collected: Array[0..c_hw_btntable_max] of Boolean;

  // weitere Auswertung erforderlich bei Panels mit Preset-Buttons
  // Map-Index c_mapidx_preset..c_mapidx_speakermodel (0..13)
  swi_firstbtns: Array[0..c_mapidx_lasttype] of Byte;
  swi_lastbtns: Array[0..c_mapidx_lasttype] of Byte;

  swi_inverse_organmodels: Array[0..15] of Byte;
  swi_inverse_speakermodels: Array[0..15] of Byte;

// #############################################################################
// ############################# XB2-Panel #####################################
// #############################################################################
// ###       Spezielle Button- und Anzeigefunktionen für XB2-Panel           ###
// #############################################################################

// LED-Zuordnung XB2:
// P1.0 = EDIT
// P1.1 =
// P1.2 =
// P1.3 = Solo
// P1.4 = Perc 2nd
// P1.5 = Perc 3rd
// P1.6 = Vibrato ON
// P1.7 = Slow/Fast

// LEDs 9532 MSB: FF VV 33 22, F = Fast, V = Vibrato, 2/3 =Perc 2nd/3rd
// LED-Belegung:
// XB2:    SOLO (0)    2nd (1)     3rd (2)     VIBRATO (3)    FAST  (7)
// --------------------------------------------------------------------------
// Upper   OFF         ON/OFF      ON/OFF      ON/OFF (U)     SpeedBlink/OFF
// Lower   ON          DARK/OFF    DARK/OFF    ON/OFF (L)     SpeedBlink/OFF
// Pedal   BLINK       DARK/OFF    DARK/OFF    ON/OFF (L)     SpeedBlink/OFF

// Button-Belegung:
// XB2:    SOLO (0)    2nd (1)     3rd (2)     VIBRATO (3)    FAST  (7)
// --------------------------------------------------------------------------
// Upper   U->L        ON/OFF      ON/OFF      ON/OFF Upper   SpeedBlink/OFF
// Lower   L->P        ------      ------      ON/OFF Lower   SpeedBlink/OFF
// Pedal   P->U        ------      ------      ON/OFF Lower   SpeedBlink/OFF
function swi_get_TabLED_bits(const btn_idx: Byte;
         const xb2_mode: Boolean): Byte; forward;

procedure xb2_UpdateLEDs;
// LEDs 9532 MSB: FF VV 33 22, F = Fast, V = Vibrato, 2/3 =Perc 2nd/3rd
// LEDs 9532 LSB: SS 00 00 EE, S = Solo, E = Edit
var temp_word: Word;
  temp_word_0[@temp_word]: Byte;
  temp_word_1[@temp_word + 1]: Byte;
  btn_idx: Byte;
  temp_solo, temp_perc, temp_vib, temp_speed: Byte;
  blink_bits_dark_on: Byte;
  blink_bits_off_dark: Byte;
begin
  // Remap-Tabs wieder in xb2_hw_tabs übertragen
  temp_word:= 0;
  if xb2_hw_tab_edit then
    // Nur bei Zweitfunktion, Edit ON, zugewiesene Buttons
    // in editmode-Tabelle übertragen
    for btn_idx:= 0 to 15 do
      n:= BtnRemaps_XB[btn_idx];
      if n < c_hw_btntable_size then         // Zuweisung Zweitfunktion
        xb2_hw_tabs_editmode[btn_idx]:=  edit_LogicalTabs[n]; // beginnt bei xb2_hw_tab_pr1
      endif;
    endfor;
    temp_word_0:= byte(xb2_hw_tab_edit) and (led_on shr 6); // EDIT !!!
    temp_word_0:= temp_word_0 or swi_get_TabLED_bits(0, true); // SOLO

    temp_word_1:= (swi_get_TabLED_bits(1, true) shr 6)     // 2ND
                  or (swi_get_TabLED_bits(2, true) shr 4)  // 3RD LED
                  or (swi_get_TabLED_bits(3, true) shr 2)  // VIBRATO LED
                  or swi_get_TabLED_bits(7, true); // FAST LED
  else
    if BlinkToggle then
      blink_bits_dark_on:= led_dark_xb2;
      // blink_bits_off_dark:= 0;            // falls benötigt
    else
      blink_bits_dark_on:= led_on_xb2;
      // blink_bits_off_dark:= led_dark_xb2;
    endif;

    // Feste Tabs in xb2_hw_tabs übertragen
    xb2_hw_tab_2nd:= edit_LogicalTab_PercOn and (not edit_LogicalTab_Perc3rd);
    xb2_hw_tab_3rd:= edit_LogicalTab_PercOn and edit_LogicalTab_Perc3rd;
    xb2_hw_tab_sf:= edit_LogicalTab_LeslieFast;
    if xb2_drawbar_mode = 0 then
      xb2_hw_tab_vib:= edit_LogicalTab_VibOnUpper;
    else
      xb2_hw_tab_vib:= edit_LogicalTab_VibOnLower;
    endif;

    xb2_hw_tab_solo:= false;
    xb2_hw_tab_rec:= edit_LogicalTab_LeslieRun; // Zweitfunktion aus

    temp_perc:= (Byte(xb2_hw_tab_3rd) and (led_on_xb2 shl 2))
                or (Byte(xb2_hw_tab_2nd) and (led_on_xb2));
    if xb2_drawbar_mode > 0 then
      temp_perc:= (temp_perc shl 1);     // PERC-LED bei Lower, Pedal dunkel
    endif;

    // DBSEL PEDAL blinkt hell/dunkel
    temp_solo:= (byte(edit_SingleDBtoPedal) and (blink_bits_dark_on shl 6))
                or (byte(edit_SingleDBtoLower) and (led_on_xb2 shl 6));

    temp_vib:= Byte(xb2_hw_tab_vib) and (led_on_xb2 shl 4);

    if not edit_LogicalTab_RotarySpkrBypass then  // S/F aus wenn Bypass
      // S/F blinkt hell/dunkel mit Leslie-Geschwindigkeit
      if SpeedBlinkToggle and edit_LogicalTab_LeslieRun then
        temp_speed:= led_on_xb2 shl 6;
      else
        temp_speed:= led_dark_xb2 shl 6;
      endif;
    endif;

    // LEDs 9532 MSB: FF VV 33 22, F = Fast, V = Vibrato, 2/3 =Perc 2nd/3rd
    temp_word_1:= temp_vib or temp_perc or temp_speed;
    // LEDs 9532 LSB: SS 00 00 EE, S = Solo, E = Edit
    temp_word_0:= temp_solo or (led_on_xb2 and Byte(xb2_hw_tab_edit));  // EDIT
  endif;
  TWIout(PCA9532_7, $18, temp_word);   // 8 LEDs auf neuen Zustand

end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure xb2_RemapSetBtn(const xb2_remap_idx: Byte; const new_state: boolean);
var tab_remap: Byte;
begin
  tab_remap:= BtnRemaps_XB[xb2_remap_idx];
  if tab_remap < c_hw_btntable_size then
    edit_LogicalTabs[tab_remap]:= new_state;
    edit_LogicalTabs_flag[tab_remap]:= c_control_event_source;
    // Versuche, ein passendes Menü anzuzeigen
    MenuIndex_SplashIfEnabled:= Param2MenuInverseArray[tab_remap + 128];
  endif;
end;

// LED-Belegung:
// XB2:    SOLO (0)    2nd (1)     3rd (2)     VIBRATO (3)    FAST  (7)
// --------------------------------------------------------------------------
// Upper   OFF         ON/OFF      ON/OFF      ON/OFF (U)     SpeedBlink/OFF
// Lower   ON          DARK/OFF    DARK/OFF    ON/OFF (L)     SpeedBlink/OFF
// Pedal   BLINK       DARK/OFF    DARK/OFF    ON/OFF (L)     SpeedBlink/OFF

// Button-Belegung:
// XB2:    SOLO (0)    2nd (1)     3rd (2)     VIBRATO (3)    FAST  (7)
// --------------------------------------------------------------------------
// Upper   U->L        ON/OFF      ON/OFF      ON/OFF Upper   SpeedBlink/OFF
// Lower   L->P        ------      ------      ON/OFF Lower   SpeedBlink/OFF
// Pedal   P->U        ------      ------      ON/OFF Lower   SpeedBlink/OFF

procedure xb2_BtnPressedEvent(const btn: Byte; const new_state: Boolean);
// tab_state enthält NEUEN Tab/LED-Zustand nach Invertierung
// Btn Idx  0      1      2      3
// +0       SOLO   2ND    3RD    VIB    - xb2_hw_tabs[0..3]
// +4       CANCEL REC    EDIT   S/F    - xb2_hw_tabs[4..7]
// +8       PR1    PR2    PR3    PR4    - xb2_hw_tabs[8..11]
// +12      PR5    PR6    PR7    PR5    - xb2_hw_tabs[12..15]

var
  tab_remap: Byte;
  old_split_on: Boolean;
begin
{$IFDEF DEBUG_SWI}
  write(serout,'/ XB2 BtnEvt #' + ByteToStr(btn) + '   ');
  for i:= 0 to 15 do
    write(serout, ByteToStr(byte(xb2_hw_tabs[i]) and 1));
    if i mod 4 = 3 then
      serout(#32);
    endif;
  endfor;
  writeln(serout);
{$ENDIF}
  if xb2_hw_tab_edit then
    old_split_on:= edit_LogicalTab_SplitOn;
    xb2_RemapSetBtn(btn, new_state);
    if (not old_split_on) and edit_LogicalTab_SplitOn then
      ForceSplitRequest:= true;
    endif;
  else
    case btn of
    0:  // SOLO Btn
      inctolimwrap(xb2_drawbar_mode, 2, 0);
      edit_SingleDBtoLower:= Bit(xb2_drawbar_mode, 0);
      edit_SingleDBtoPedal:= Bit(xb2_drawbar_mode, 1);
      MenuIndex_Requested:= xb2_drawbar_mode + 1; // auf DB-Menü
      |
    1:  // PERC 2nd
      if xb2_drawbar_mode = 0 then
        edit_LogicalTab_PercOn:= new_state;
        edit_LogicalTab_Perc3rd:= false;
        FillBlock(@edit_LogicalTab_PercOn_flag, 4, c_control_event_source);
        MenuIndex_SplashIfEnabled:= c_PercMenu;
      endif;
      |
    2:  // PERC 3rd
      if xb2_drawbar_mode = 0 then
        edit_LogicalTab_PercOn:= new_state;
        edit_LogicalTab_Perc3rd:= true;
        FillBlock(@edit_LogicalTab_PercOn_flag, 4, c_control_event_source);
        MenuIndex_SplashIfEnabled:= c_PercMenu;
      endif;
      |
    3:  // VIBRATO
      if xb2_drawbar_mode = 0 then
        edit_LogicalTab_VibOnUpper:= new_state;
        edit_LogicalTab_VibOnUpper_flag:= c_control_event_source;
        MenuIndex_SplashIfEnabled:= c_VibUprMenu;
      else
        edit_LogicalTab_VibOnLower:= new_state;
        edit_LogicalTab_VibOnLower_flag:= c_control_event_source;
        MenuIndex_SplashIfEnabled:= c_VibUprMenu;
      endif;
      |
    // 4:  // CANCEL
    5:  // RECORD Btn
      edit_LogicalTab_LeslieRun:= new_state;
      edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
      MenuIndex_SplashIfEnabled:= c_RotaryRunMenu;
      |
    // 6:  // EDIT
    7:  // S/F Button
      edit_LogicalTab_LeslieFast:= new_state;
      edit_LogicalTab_LeslieFast_flag:= c_control_event_source;
      MenuIndex_SplashIfEnabled:= c_RotaryFastMenu;
      |
    endcase;
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure xb2_BtnReleasedEvent(const btn: Byte);
// Cancel- und Preset-Buttons werden mit LOSLASSEN aktiv
begin
  MemorizeTimerXB2:= 0;
  if not xb2_hw_tab_edit then  // keine Zweitfunktion?
    case btn of
      4:  // Cancel
        SWI_PresetLoadOrDisplayToggle(0);
        |
      8..15: // Preset Buttons
        SWI_PresetLoadOrDisplayToggle(btn - 7);
        |
    endcase;
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure xb2_CheckPresetTimeout(btn: Byte);
// Prüft, ob Button min. 2 Sekunden gedrückt wurde
// Wenn ja, Abspeichern des Presets
var
  temp_word: Word;
begin
  if (not xb2_hw_tab_edit) then   // Cancel und Preset Buttons
{$IFDEF DEBUG_SWI}
    if MemorizeTimerXB2 mod 10 = 0 then
      writeln(serout,'/ XB2 Timeout Counter: ' + ByteToStr(MemorizeTimerXB2));
    endif;
{$ENDIF}

    if not inctolim(MemorizeTimerXB2, 100) then
      // Timer abgelaufen, Preset speichern
      edit_CommonPreset:= 0;           // Default Btn 4, Cancel
      if (btn >= 8) then         // Preset-Buttons
        edit_CommonPreset:= btn - 7;   // beginnen mit 1!
      endif;
      PresetStoreRequest:= true;
      SaveCommonPreset(edit_CommonPreset);
      DT_MsgSaveDone('C');
{$IFDEF DEBUG_SWI}
      writeln(serout,'/ XB2 Saved to: ' + ByteToStr(edit_CommonPreset));
{$ENDIF}
      for n:= 0 to 3 do
        temp_word:= $5555;
        TWIout(PCA9532_7, $18, temp_word);   // 8 LEDs auf neuen Zustand
        mdelay(100);
        temp_word:= 0;
        TWIout(PCA9532_7, $18, temp_word);   // 8 LEDs auf neuen Zustand
        mdelay(100);
      endfor;
      MemorizeTimerXB2:= 0;
    endif;
    xb2_hw_tabs[btn]:= false;
  else
    MemorizeTimerXB2:= 0;
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SWI_HandleXB2panel;
// Übersetzt Tastermatrix...
// INPUT        P0.2   P0.3   P0.4   P0.5
// ROW A P0.7   VIB    3RD    2ND    SOLO
// ROW B P0.6   S/F    EDIT   REC    CANCEL
// ROW C P0.0   PR4    PR3    PR2    PR1
// ROW D P0.1   PR8    PR7    PR6    PR5
// ...in diese Tabellen-Reihenfolge:
// mapidx  0      1      2      3
// +0      SOLO   2ND    3RD    VIB    - xb2_hw_tabs[0..3]
// +4      CANCEL REC    EDIT   S/F    - xb2_hw_tabs[4..7]
// +8      PR1    PR2    PR3    PR4    - xb2_hw_tabs[8..11]
// +12     PR5    PR6    PR7    PR5    - xb2_hw_tabs[12..15]
var i2c_data, btn, btn_row, btn_col: Byte;
  btn_state, tab_state: Boolean;
  old_split_on: Boolean;
  temp_word: Word;
begin
  if edit_ADCconfig = 5 then // Single Drawbar mode, Auto Switch
    ReceiveFPGA(0); // STATUS anfordern
    n:= FPGAreceiveLong0 and %11000000;
    if n = %11000000 then
      xb2_drawbar_mode:= 2;  // Pedal gespielt
      edit_SingleDBtoLower:= false;
      edit_SingleDBtoPedal:= true;
      if valueInRange(MenuIndex, 1, 3) then
        MenuIndex_Requested:= 3; // auf DB-Menü Pedal
      endif;
    elsif n = %01000000 then
      xb2_drawbar_mode:= 0;  // Upper gespielt, KEYS_ON_UPR-Bit 6
      edit_SingleDBtoLower:= false;
      edit_SingleDBtoPedal:= false;
      if valueInRange(MenuIndex, 1, 3) then
        MenuIndex_Requested:= 1; // auf DB-Menü Upper
      endif;
    elsif n = %10000000 then
      xb2_drawbar_mode:= 1;  // Lower gespielt, KEYS_ON_LWR-Bit 7
      edit_SingleDBtoLower:= true;
      edit_SingleDBtoPedal:= false;
      if valueInRange(MenuIndex, 1, 3) then
        MenuIndex_Requested:= 2; // auf DB-Menü Lower
      endif;
    endif;
  elsif edit_ADCconfig < 4 then
    edit_SingleDBtoLower:= false;
    edit_SingleDBtoPedal:= false;
  endif;

  if XB2_present then
    old_split_on:= edit_LogicalTab_SplitOn;
    xb2_UpdateLEDs;
    for btn_row:= 0 to 3 do
      temp_word:= c_XB2selects9532[btn_row];
      TWIout(PCA9532_7, $16, temp_word);   // Select-Ausgänge setzen
      // Einer der Select-Ausgänge ist jetzt auf 0 (ON), der Rest 1
      udelay(5);
      TWIout(PCA9532_7, 0);    // Lesen des Ports 0
      TWIinp(PCA9532_7, i2c_data);
      i2c_data:= (not i2c_data) and %00111100;  // invertiert, 0 = Taster gedrückt
      for btn_col:= 0 to 3 do
        btn:= btn_col + (btn_row * 4);
        btn_state:= Bit(i2c_data, 5 - btn_col); // Umgekehrte Bit-Reihenfolge!
        if btn_state then
          if ((btn = 4) or (btn >= 8)) and (not xb2_hw_tab_edit) then
            // Preset-Buttons Timeout nur wenn nicht Edit ON
            xb2_CheckPresetTimeout(btn);
          elsif (not xb2_hw_btnstates_old[btn]) then
            // Erstmals "gedrückt" festgestellt?
            if xb2_hw_tab_edit then
              tab_state:= not xb2_hw_tabs_editmode[btn];  // einmalig invertieren
              xb2_hw_tabs_editmode[btn]:= tab_state;
              xb2_hw_tab_edit:= xb2_hw_tab_edit_editmode;    // beide mitführen
            else
              tab_state:= not xb2_hw_tabs[btn];      // einmalig invertieren
              xb2_hw_tabs[btn]:= tab_state;
              xb2_hw_tab_edit_editmode:= xb2_hw_tab_edit;
            endif;
            xb2_BtnPressedEvent(btn, tab_state);
          endif;
        else
          if (xb2_hw_btnstates_old[btn]) then
            // Taster erstmals "losgelassen" festgestellt? - Hier nur für Presets
            xb2_BtnReleasedEvent(btn);
          endif;
        endif;
        xb2_hw_btnstates_old[btn]:= btn_state;
      endfor;
    endfor;
    temp_word:= 0;
    TWIout(PCA9532_7, $16, temp_word);   // Select-Ausgänge abschalten
  endif;
end;

// #############################################################################
// ############################ HX3.5 PANEL16 ##################################
// #############################################################################
// ####                  Standard-Panels und Extend16                       ####
// #############################################################################

// Neue Routinen, Einzeltasten-Events


function swi_search_group(const btn_type; var start_btn, end_btn: Byte): boolean;
// Sucht in Remaps ersten und letzten Button vom Remap-Typ btn_type
// innerhalb von start_btn bis end_btn
// liefert Ergebnis in start_btn, end_btn zurück, falls gefunden
var found_btn: boolean;
begin
  found_btn:= false;
  for i:= start_btn to end_btn do
    if (PanelsPresent[i div 16]) and (btn_type = BtnRemaps[i]) then
      found_btn:= true;
      break;
    endif;
  endfor;
  if found_btn then
    start_btn:= i;
    for i:= end_btn downto start_btn do
      if (PanelsPresent[i div 16]) and (btn_type = BtnRemaps[i]) then
        break;
      endif;
    endfor;
    end_btn:= i;
  endif;
  return(found_btn);
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function swi_CollectBinaryPresetButtons(const map_idx: Byte): Byte;
// addiert gedrückte Binary-Preset-Buttons binär, +1 +2 +4 +8 usw.
// swi_hw_btnstates und swi_hw_btnstates_collected sind bereits gesetzt
var preset_nr, first_preset_btn, last_preset_btn, adder: Byte;
  btn_state_collected: Boolean;
begin
  first_preset_btn:= swi_firstbtns[map_idx];
  last_preset_btn:= swi_lastbtns[map_idx];
  preset_nr:= 0;
  adder:= 1;  //Wertigkeit erster Button der Reihe
  for i:= first_preset_btn to last_preset_btn do
    btn_state_collected:= swi_hw_btnstates_collected[i];
    if btn_state_collected then
      inc(preset_nr, adder);
    endif;
    adder:= adder * 2;
  endfor;
  return(preset_nr);
end;

// #############################################################################
// ###                          LED-Routinen                                 ###
// #############################################################################

procedure swi_set_simple_PresetLEDs(first_btn, btn_count, led_number: Byte; invalid: Boolean);
var led_state: Byte;
begin
  if invalid then
    led_state:= led_dark and Byte(BlinkToggle);
  else
    led_state:= led_bright;
  endif;
  for i:= 0 to btn_count do
    swi_hw_btnstates[first_btn + i]:= led_off; // = 0
  endfor;
  swi_hw_btnstates[first_btn + led_number]:= led_state;
end;

procedure swi_set_organ_PresetLEDs(first_btn, btn_count, led_number: Byte);
// zu Model passendes Button-Assgnment suchen
var model_idx: Byte;
begin
  model_idx:= swi_inverse_organmodels[led_number];
  for i:= first_btn to first_btn + btn_count do
    swi_hw_btnstates[i]:= led_off;
  endfor;
  if model_idx <= btn_count then
    swi_hw_btnstates[first_btn + model_idx]:= led_bright;
  endif;
end;

procedure swi_set_speaker_PresetLEDs(first_btn, btn_count, led_number: Byte);
// zu Model passendes Button-Assgnment suchen
var model_idx: Byte;
begin
  model_idx:= swi_inverse_speakermodels[led_number];
  for i:= first_btn to first_btn + btn_count do
    swi_hw_btnstates[i]:= led_off;
  endfor;
  if model_idx <= btn_count then
    swi_hw_btnstates[first_btn + model_idx]:= led_bright;
  endif;
end;

procedure swi_set_binary_PresetLEDs(first_btn, btn_count, bin_value: Byte; invalid: Boolean);
var led_state: Byte;
begin
  if invalid then
    led_state:= led_dark and Byte(BlinkToggle);
  else
    led_state:= led_bright;
  endif;
  for i:= 0 to btn_count do
    if Bit(bin_value, i) then
      swi_hw_btnstates[first_btn + i]:= led_state;
    else
      swi_hw_btnstates[first_btn + i]:= led_off; // = 0
    endif;
  endfor;
end;

// -----------------------------------------------------------------------------

procedure swi_set_PresetLEDs;
// setzt LED-Zustand in swi_tabs anhand Preset-Nummern, sofern zugewiesen
// ca. 15µs
var
  first_btn, btn_count, led_bits, btn_type_idx: Byte;
begin
  for btn_type_idx:= c_mapidx_firsttype to c_mapidx_lasttype do
    // Index 0..10
    first_btn:= swi_firstbtns[btn_type_idx];
    if first_btn < c_hw_btntable_size then // vorhanden?
      btn_count:= swi_lastbtns[btn_type_idx] - first_btn;
      case btn_type_idx of
      // normale (einzelne) Voice-LEDs einstellen, so vorhanden
      c_mapidx_preset: //
        swi_set_simple_PresetLEDs(first_btn, btn_count, edit_CommonPreset, PresetInvalids[0]);
        |
      c_mapidx_voice_upr: //
        swi_set_simple_PresetLEDs(first_btn, btn_count, edit_UpperVoice, PresetInvalids[1] or SWI_CancelActive_upr);
        |
      c_mapidx_voice_lwr: //
        swi_set_simple_PresetLEDs(first_btn, btn_count, edit_LowerVoice, PresetInvalids[2] or SWI_CancelActive_lwr);
        |
      c_mapidx_voice_ped: //
        swi_set_simple_PresetLEDs(first_btn, btn_count, edit_PedalVoice, PresetInvalids[3]);
        |
      c_mapidx_organmodel: //
        swi_set_organ_PresetLEDs(first_btn, btn_count, edit_OrganModel);
        |
      c_mapidx_speakermodel: //
        swi_set_speaker_PresetLEDs(first_btn, btn_count, edit_SpeakerModel);
        |
      // Binary-LEDs einstellen, so vorhanden
      c_mapidx_binary_preset: //
        swi_set_binary_PresetLEDs(first_btn, btn_count, edit_CommonPreset, PresetInvalids[0]);
        |
      c_mapidx_binary_voice_upr, c_mapidx_binary_voice_ul,
      c_mapidx_binary_voice_ulp: //
        swi_set_binary_PresetLEDs(first_btn, btn_count, edit_UpperVoice, PresetInvalids[1]);
        |
      c_mapidx_binary_voice_lwr, c_mapidx_binary_voice_lp: //
        swi_set_binary_PresetLEDs(first_btn, btn_count, edit_LowerVoice, PresetInvalids[2]);
        |
      c_mapidx_binary_voice_ped: //
        swi_set_binary_PresetLEDs(first_btn, btn_count, edit_PedalVoice, PresetInvalids[3]);
        |
      endcase;
    endif;
  endfor;
  // Cancel-Buttons unabhängig vom Panel setzen
  if swi_has_cancel_upr then
    // Upper Cancel, Cancel-LED zusätzlich zu Voice anzeigen
    swi_hw_btnstates[swi_cancel_idx_upr]:= led_bright and byte(SWI_CancelActive_upr);
  endif;
  if swi_has_cancel_lwr then
    // Lower Cancel, Cancel-LED zusätzlich zu  Voice anzeigen
    swi_hw_btnstates[swi_cancel_idx_lwr]:= led_bright and byte(SWI_CancelActive_lwr);
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function swi_get_TabLED_bits(btn_idx: Byte; xb2_mode: Boolean): Byte;
// holt einzelnen LED-Zustand aus Logical Tabs,
// sofern als Remap zugewiesen,
// sonst aus swi_hw_btnstates (z.B. vorbereitete  Preset-Leds)
// Sonderbehandlung spezielle Taster: Percussion, Leslie RUN-Blink
var dim_bits, btn_remap: Byte;
begin
  if xb2_mode then
    btn_remap:= BtnRemaps_XB[btn_idx];
  else
    btn_remap:= BtnRemaps[btn_idx];
  endif;
// setze zur LED gehörigen Tab-Wert, falls zugeordnet
  if btn_remap < c_hw_btntable_size then
    // aktueller Tab-Zustand in LED-Bit bei zugewiesenen Buttons
    dim_bits:= byte(edit_LogicalTabs[btn_remap]) and led_bright;
    if not xb2_mode then
      swi_hw_btnstates[btn_idx]:= dim_bits;
    endif;
  else
    // bei nicht zugewiesenen Buttons, z.B. Presets
    if xb2_mode then
      dim_bits:= 0;
    else
      dim_bits:= swi_hw_btnstates[btn_idx];
    endif;
  endif;
  if (dim_bits <> led_off)
  or (btn_remap >= c_map_incdec_firstbtn) then
    // Sonderbehandlung LEDs spezielle Taster anhand aktuellem Remap:
    // Percussion, Leslie RUN-Blink
    // Default: led_bright wenn ON
    case btn_remap of
    c_map_percon:
      if DisablePercussion then
        if BlinkToggle then
          dim_bits:= led_dark;
        else
          dim_bits:= led_off;
        endif;
      endif;
      |
    c_map_percsoft..c_map_perc3rd:  // Percussion
      if DisablePercussion or (not edit_LogicalTab_PercOn) then
        dim_bits:= led_dark;
      endif;
      |
    c_map_leslierun:  // Leslie RUN
      if SpeedBlinkToggle then
        dim_bits:= led_dark;
      endif;
      |
    c_map_dectranspose: // Transpose DOWN
      if edit_GenTranspose > 128 then
        if BlinkToggle then
          dim_bits:= led_dark;
        else
          dim_bits:= led_on;
        endif;
      else
        dim_bits:= led_off;
      endif;
      |
    c_map_inctranspose: // Transpose UP
      if valueInRange(edit_GenTranspose, 1, 127) then
        if BlinkToggle then
          dim_bits:= led_dark;
        else
          dim_bits:= led_on;
        endif;
      else
        dim_bits:= led_off;
      endif;
      |
    c_map_singledb_toggle: // SingleDBsetSelect Toggle
      case SingleDBsetSelect of
      0:
        dim_bits:= led_off;
        |
      1:
        dim_bits:= led_on;
        |
      2:
        if BlinkToggle then
          dim_bits:= led_dark;
        else
          dim_bits:= led_on;
        endif;
        |
      endcase;
      |
    endcase;
  endif;
  return(dim_bits);
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function swi_setLEDs_getInPort(const panel_nr: Byte): Word;
// setzt LED-Zustand anhand Presets/Voices, Logical Tabs
// Liefert aktuellen Port-Wert vom PCA9532 zurück (16 Bit)
// benötigt etwa 700µs
var
  btn, btn_idx, i2c_addr, dim_bits: Byte;
  temp_leds: LongWord;
  temp_leds_msbyte[@temp_leds + 3]: Byte;
  temp_leds_lo[@temp_leds]: Word;
  temp_leds_hi[@temp_leds + 2]: Word;
  temp_word: Word;
  temp_word_0[@temp_word]: Byte;
  temp_word_1[@temp_word + 1]: Byte;
  swap_rows: Boolean;
begin
  // bereitet LED-Bits in swi_hw_btnstates vor, falls dort Voices oder Presets liegen
  swi_set_PresetLEDs;
  i2c_addr:= PCA9532_0 + panel_nr;
  temp_leds:= 0;
  TWIout(i2c_addr, $16, temp_leds); // 16 LEDs abschalten, 4 Bytes - 72µs!

  // LED-Zustand ermitteln und in temp_leds einschieben
  btn_idx:= panel_nr * 16;          // btn_idx wird über inc() mitgeführt
  for btn:= 0 to 15 do
    // 16 Buttons pro Panel
    dim_bits:= swi_get_TabLED_bits(btn_idx, false);
    // LED-Longword vorbereiten, 32 Bits
    temp_leds:= temp_leds shr 2; // 2 Nullen einschieben = led_off
    temp_leds_msbyte:= temp_leds_msbyte or dim_bits;
    inc(btn_idx);
  endfor;
  swap_rows:= (panel_nr = 0) and Bit(edit_ConfBits, 0)
              or (panel_nr = 1) and Bit(edit_ConfBits, 1);
  if swap_rows then
    // alte Reihenfolge der Preset-Buttons, unten links = 0/Live
    // LED-Word berechnet, Ports lesen und neuen LED-Wert senden
    // In-Ports müssen bein 9532 einzeln gelesen werden!
    TWIout(i2c_addr, 0);    // Lesen Port 0
    TWIinp(i2c_addr, temp_word_0);
    TWIout(i2c_addr, 1);    // Lesen Port 1
    TWIinp(i2c_addr, temp_word_1);
  else
    // neue Reihenfolge der Buttons
    // Words vertauschen wg. Port-Reihenfolge der Register
    temp_word:= temp_leds_hi;
    temp_leds_hi:= temp_leds_lo;
    temp_leds_lo:= temp_word;
    // LED-Word berechnet, Ports lesen und neuen LED-Wert senden
    // In-Ports müssen bein 9532 einzeln gelesen werden!
    TWIout(i2c_addr, 0);    // Lesen Port 0
    TWIinp(i2c_addr, temp_word_1);
    TWIout(i2c_addr, 1);    // Lesen Port 1
    TWIinp(i2c_addr, temp_word_0);
  endif;

  TWIout(i2c_addr, $16, temp_leds);   // neuer LED-Wert, 4 Bytes
  // LED_DOWN:= true;
  return(not temp_word);  // invertiert!
end;

// #############################################################################
// ###                          Button-Events                                ###
// #############################################################################

procedure swi_BtnPressedEvent(panel_nr, btn_idx: Byte);
// Physikalischer Panel-Button in btn (0..63) wurde erstmals als
// "betätigt" registriert
var
  btn_remap, preset_btn: Byte;
  tab_state, old_split_on: Boolean;
begin
  btn_remap:= BtnRemaps[btn_idx];
  // normale Buttons invertieren, ON/OFF
  if btn_remap < c_map_binary_preset then
    // keine Presets und Voices!
    old_split_on:= edit_LogicalTab_SplitOn;
    tab_state:= swi_hw_btnstates[btn_idx] = led_off;  // invertieren wenn Button
    swi_hw_btnstates[btn_idx]:= byte(tab_state) and led_bright;
    edit_LogicalTabs[btn_remap]:= tab_state;
    edit_LogicalTabs_flag[btn_remap]:= c_control_event_source;
    MenuIndex_SplashIfEnabled:= Param2MenuInverseArray[btn_remap + 128];
    // Split Request, geändert?
    if edit_LogicalTab_SplitOn and (not old_split_on) then
      ForceSplitRequest:= true;
    endif;
  endif;

{$IFDEF DEBUG_SWI}
  write(serout,'/ Panel Btn: ' + ByteToStr(btn_idx));
  write(serout,', Remap to: ' + ByteToStr(btn_remap));
  writeln(serout,', Menu Idx: ' + ByteToStr(MenuIndex_SplashIfEnabled));
{$ENDIF}
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure swi_BtnReleasedEvent(panel_nr, btn: Byte; save_preset: Boolean);
// Physikalischer Panel-Button in btn (0..63) wurde erstmals als
// "losgelassen" registriert, liefert ggf. preset_nr zurück
var
  btn_remap, first_preset_btn, preset_nr: Byte;
begin
  btn_remap:= BtnRemaps[btn];
  preset_nr:= 0;

  // Cancel-Buttons gehören zwar zu einer Voice-Gruppe, bewirken aber
  // nur das Abschalten der Drawbars, wenn kürzer als 2sec. gedrückt
  case btn_remap of
  c_map_cancel_upr:
    ADC_ResetTimersUpper;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
    ADC_ChangeStateAll(false);
    FillBlock(@edit_UpperDBs, 16, 0);
    edit_UpperDBs_flag[0]:= c_control_event_source;
    SWI_CancelActive_upr:= true;
    return;
    |
  c_map_cancel_lwr:
    ADC_ResetTimersLower;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
    ADC_ChangeStateAll(false);
    FillBlock(@edit_LowerDBs, 16, 0);
    edit_LowerDBs_flag[0]:= c_control_event_source;
    SWI_CancelActive_lwr:= true;
    return;
    |
  endcase;

  if valueInRange(btn_remap, c_map_preset, c_map_voice_ped)
  or valueInRange(btn_remap, c_map_organmodel, c_map_speakermodel) then
    // NICHT bei AddMode, c_map_binary_preset bis c_map_binary_voice_xxx!
    first_preset_btn:= swi_firstbtns[btn_remap - c_map_preset];
    if first_preset_btn <= btn then
      preset_nr:= valueTrimLimit(btn - first_preset_btn, 0, 15);
{$IFDEF ALLINONE}
      case btn_remap of
      c_map_preset:
        edit_CommonPreset:= preset_nr;
        if save_preset then
          PresetStoreRequest:= true;
          SaveCommonPreset(edit_CommonPreset);
          DT_MsgSaveDone('C');
        else
          edit_CommonPreset_flag:= c_control_event_source;
        endif;
        |
      c_map_voice_upr:
        edit_UpperVoice:= preset_nr;
        if save_preset then
          SaveUpperVoice;
          DT_MsgSaveDone('U');
        else
          edit_UpperVoice_flag:= c_control_event_source;  // neu laden!
        endif;
        SWI_CancelActive_upr:= false; // kein Cancel mehr
        |
      c_map_voice_lwr:
        edit_LowerVoice:= preset_nr;
        if save_preset then
          SaveLowerVoice;
          DT_MsgSaveDone('L');
        else
          edit_LowerVoice_flag:= c_control_event_source; // neu laden!
        endif;
        SWI_CancelActive_lwr:= false; // kein Cancel mehr
        |
      c_map_voice_ped:
        edit_PedalVoice:= preset_nr;
        if save_preset then
          SavePedalVoice;
          DT_MsgSaveDone('P');
        else
          edit_PedalVoice_flag:= c_control_event_source; // neu laden!
        endif;
        |
      c_map_organmodel:
        edit_OrganModel:= eep_OrganModelAssignments[preset_nr];
        if save_preset then
          SR_StoreOrganModel(edit_OrganModel);
          DT_MsgSaveDone('O');
        else
          edit_OrganModel_flag:= c_control_event_source; // neu laden!
        endif;
        |
      c_map_speakermodel:
        edit_SpeakerModel:= eep_SpeakerModelAssignments[preset_nr];
        if save_preset then
          SR_StoreSpeakerModel(edit_SpeakerModel);
          DT_MsgSaveDone('R');
        else
          edit_SpeakerModel_flag:= c_control_event_source; // neu laden!
        endif;
        |
      endcase;
{$ENDIF}
{$IFDEF DEBUG_SWI}
      write(serout,'/ Released Btn: ' + ByteToStr(btn));
      writeln(serout,', is Preset: ' + ByteToStr(preset_nr));
{$ENDIF}
      swi_set_PresetLEDs;
    endif;
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure swi_voice_released(btn_remap, voice_idx, panel_nr: Byte);
var preset_temp: Byte;
begin
  // 100..109
  preset_temp:= swi_CollectBinaryPresetButtons(btn_remap - c_map_firsttype);
  // wenn kein Save-Timeout und gleiche Tasten nochmal gedrückt
  if (not PresetWasSaved) and (edit_voices[voice_idx] = preset_temp) then
    edit_voices[voice_idx]:= 0; // Gleiche Buttons nochmal gedrückt? Dann auf 0
  else
    edit_voices[voice_idx]:= preset_temp;
  endif;
  edit_voices_flag[voice_idx]:= c_control_event_source;
  swi_set_PresetLEDs;
end;


procedure swi_PanelAllBtnsReleasedEvent(panel_nr, last_btn_released: Byte);
// Alle Tasten von panel_nr wurden erstmalig losgelassen,
// für Binary Presets
var btn_remap, preset_temp: Byte;
begin
  btn_remap:= BtnRemaps[last_btn_released];
  // War es ein Binary AddMode Button?
  case btn_remap of
  c_map_binary_preset..c_map_binary_voice_ped:
    swi_voice_released(btn_remap, btn_remap - c_map_binary_preset, panel_nr);
    |
  c_map_binary_voice_ul:
    swi_voice_released(btn_remap, 1, panel_nr);
    edit_LowerVoice:= edit_UpperVoice;
    edit_LowerVoice_flag:= c_control_event_source;
    |
  c_map_binary_voice_ulp:
    swi_voice_released(btn_remap, 1, panel_nr);
    edit_LowerVoice:= edit_UpperVoice;
    edit_LowerVoice_flag:= c_control_event_source;
    edit_PedalVoice:= edit_UpperVoice;
    edit_PedalVoice_flag:= c_control_event_source;
    |
  c_map_binary_voice_lp:
    swi_voice_released(btn_remap, 2, panel_nr);
    edit_PedalVoice:= edit_LowerVoice;
    edit_PedalVoice_flag:= c_control_event_source;
    |
  c_map_cancel_upr:
    // erneut laden, wenn per Timeout oder Cancel Key gespeichert
    if PresetWasSaved then
      edit_UpperVoice_flag:= c_control_event_source;
      SWI_CancelActive_upr:= false; // kein Cancel mehr
    endif;
    |
  c_map_cancel_lwr:
    // erneut laden, wenn per Timeout oder Cancel Key gespeichert
    if PresetWasSaved then
      edit_LowerVoice_flag:= c_control_event_source;
      SWI_CancelActive_lwr:= false; // kein Cancel mehr
    endif;
    |
  endcase;
  MemorizeTimerPanel:= 0;
  PresetWasSaved:= false;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure swi_SwitchChangedEvent(panel_nr, btn_idx: Byte; const switch_state: Boolean);
// Physikalischer Panel-Button in btn (0..63) wurde erstmals als
// "eingeschaltet" oder "ausgeschaltet" registriert
// wird niemals für Cancel-Buttons aufgerufen, da immer auf Button gesetzt
var
  btn_remap: Byte;
  old_split_on: Boolean;
begin
  btn_remap:= BtnRemaps[btn_idx];
  // Schalter direkt übernehmen
  if btn_remap < c_hw_btntable_size then
    old_split_on:= edit_LogicalTab_SplitOn;
    swi_hw_btnstates[btn_idx]:= byte(switch_state) and led_bright;
    edit_LogicalTabs[btn_remap]:= switch_state;
    edit_LogicalTabs_flag[btn_remap]:= c_control_event_source;
    if Bit(edit_ConfBits, 7) then
      MenuIndex_SplashIfEnabled:= Param2MenuInverseArray[btn_remap + 128];
    endif;
    // Split Request, geändert?
    if edit_LogicalTab_SplitOn and (not old_split_on) then
      ForceSplitRequest:= true;
    endif;
  elsif switch_state
  and valueInRange(btn_remap, c_map_preset, c_map_voice_ped) then
    // Latched Preset Keys, Preset sofort nach Drücken aufrufen
    swi_BtnReleasedEvent(panel_nr, btn_idx, false);
  endif;
{$IFDEF DEBUG_SWI}
  write(serout,'/ Switch Input: ' + ByteToStr(btn_idx));
  write(serout,', Remap to: ' + ByteToStr(btn_remap));
  writeln(serout,', Menu Idx: ' + ByteToStr(MenuIndex_SplashIfEnabled));
{$ENDIF}
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure swi_CheckPresetTimeout(const panel_nr, btn_idx: Byte);
// Physikalischer Panel-Button in btn (0..63)
var
  btn_remap, preset_nr, first_preset_btn, start_btn, i2c_addr: Byte;
  temp_leds: LongWord;
begin
{$IFDEF ALLINONE}
  btn_remap:= BtnRemaps[btn_idx];
  if not inctolim(MemorizeTimerPanel, 100) then
    // Timer abgelaufen, Preset neu setzen und speichern
    case btn_remap of
    c_map_binary_preset:
      PresetStoreRequest:= true;   // nicht neu laden
      edit_CommonPreset:= swi_CollectBinaryPresetButtons(c_mapidx_binary_preset);
      SaveCommonPreset(edit_CommonPreset);
      DT_MsgSaveDone('C');
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_upr:
      edit_UpperVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_upr);
      SaveUpperVoice;
      DT_MsgSaveDone('U');
      edit_UpperVoice_old:= edit_UpperVoice;   // nicht neu laden
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_lwr:
      edit_LowerVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_lwr);
      SaveLowerVoice;
      DT_MsgSaveDone('L');
      edit_LowerVoice_old:= edit_LowerVoice;   // nicht neu laden
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_ped:
      edit_PedalVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_ped);
      SavePedalVoice;
      DT_MsgSaveDone('P');
      edit_PedalVoice_old:= edit_PedalVoice;   // nicht neu laden
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_cancel_upr:
      SaveUpperVoice;
      DT_MsgSaveDone('U');
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_ul:
      edit_UpperVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_ul);
      edit_LowerVoice:= edit_UpperVoice;
      SaveUpperVoice;
      SaveLowerVoice;
      DT_MsgSaveDone('U');
      edit_LowerVoice_old:= edit_LowerVoice;   // nicht neu laden
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_ulp:
      edit_UpperVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_ulp);
      edit_LowerVoice:= edit_UpperVoice;
      edit_PedalVoice:= edit_UpperVoice;
      SaveUpperVoice;
      SaveLowerVoice;
      SavePedalVoice;
      DT_MsgSaveDone('U');
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_binary_voice_lp:
      edit_LowerVoice:= swi_CollectBinaryPresetButtons(c_mapidx_binary_voice_lp);
      edit_PedalVoice:= edit_LowerVoice;
      SaveLowerVoice;
      SavePedalVoice;
      DT_MsgSaveDone('L');
      edit_LowerVoice_old:= edit_LowerVoice;   // nicht neu laden
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_cancel_lwr:
      SaveLowerVoice;
      DT_MsgSaveDone('L');
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    c_map_voice_upr, c_map_voice_lwr, c_map_voice_ped,
    c_map_preset, c_map_organmodel, c_map_speakermodel:
      swi_BtnReleasedEvent(panel_nr, btn_idx, true);
      PresetWasSaved:= true;    // für swi_PanelAllBtnsReleasedEvent
      |
    endcase;
  endif;

  if PresetWasSaved then
    i2c_addr:= PCA9532_0 + panel_nr;
    for n:= 0 to 2 do
      temp_leds:= $55555555;
      TWIout(i2c_addr, $16, temp_leds);   // 8 LEDs auf neuen Zustand
      mdelay(100);
      temp_leds:= 0;
      TWIout(i2c_addr, $16, temp_leds);   // 8 LEDs auf neuen Zustand
      mdelay(100);
    endfor;
    mdelay(400);
    MemorizeTimerPanel:= 0;
  endif;
{$ENDIF}
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure swi_HandlePanel(panel_nr: Byte; force_sw_reload: Boolean);
// Fragt Panel mit PCA9532 ab, je nach BtnSwitchSelects Button oder Switch
// Wenn force_sw_reload TRUE ist, werden alle SCHALTER neu eingelesen
var
  inp_word, old_input_word: Word;
  tab_state, btn_state, btn_state_old: Boolean;
  btn, btn_idx, last_btn_released: Byte;
  any_btn_on, any_btn_on_old: Boolean;
begin
  // LEDs setzen und 16-Bit-Port holen
  inp_word:= swi_setLEDs_getInPort(panel_nr);
  old_input_word:= swi_hw_OldInputWords[panel_nr];
  // hat sich überhaupt etwas geändert?
  any_btn_on:= false;
  any_btn_on_old:= false;
  if (inp_word <> 0) or (inp_word <> old_input_word) or force_sw_reload then
    btn_idx:= panel_nr * 16;   // wird in Schleife inkrementiert!
    // btn_idx zeigt auf swi_hw_btnstates- und swi_hw_btnstates_old-Array
    for btn:= 0 to 15 do
      btn_state:= Bit(inp_word, btn);
      btn_state_old:= swi_hw_btnstates_old[btn_idx];
      if BtnSwitchSelects[btn_idx] then
        // Switch-Eingang
        if (btn_state <> btn_state_old) or force_sw_reload then
          swi_SwitchChangedEvent(panel_nr, btn_idx, btn_state);
        endif;
      else
        // Button-Eingang oder CANCEL key
        if btn_state then
          any_btn_on:= true;
          swi_hw_btnstates_collected[btn_idx]:= true;
          if not btn_state_old then
           // Erstmals "gedrückt" festgestellt?
            swi_BtnPressedEvent(panel_nr, btn_idx);   // neu ON oder OFF
          endif;
          swi_CheckPresetTimeout(panel_nr, btn_idx);
        else
          if btn_state_old then
            // Taster erstmals "losgelassen" festgestellt?
            swi_BtnReleasedEvent(panel_nr, btn_idx, false);
            last_btn_released:= btn_idx;
            any_btn_on_old:= true;
          endif;
        endif;
      endif;
      swi_hw_btnstates_old[btn_idx]:= btn_state;
      inc(btn_idx);
    endfor;
    swi_hw_OldInputWords[panel_nr]:= inp_word;
  endif;
  if (not any_btn_on) and any_btn_on_old then
    // berücksichtigt keine SCHALTER!
    swi_PanelAllBtnsReleasedEvent(panel_nr, last_btn_released);
    FillBlock(@swi_hw_btnstates_collected, c_hw_btntable_size_w, 0);
  endif;
end;

// #############################################################################
// ###                       UNIT Interface                                  ###
// #############################################################################

procedure SWI_ForceSwitchReload;
var panel_nr: Byte;
begin
  for panel_nr:= 0 to 5 do
    if PanelsPresent[panel_nr] then
{$IFDEF DEBUG_SWI}
      writeln(serout,'/ Switch Reload on Panel: ' + char(panel_nr + 48));
{$ENDIF}
      swi_HandlePanel(panel_nr, true); // mit force_sw_reload = TRUE
    endif;
  endfor;
end;

procedure SWI_GetPanel16(const panel_nr: Byte);
// ButtonsTemp und Tabs an PL7, PL8, PL11, PL12 abfragen, sofern Hardware vorhanden
// Zeitbedarf ca. 400µs pro Port, Tabs 0..15
begin
  if PanelsPresent[panel_nr] then
    swi_HandlePanel(panel_nr, false);
  endif;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SWI_PresetLoadOrDisplayToggle(const preset_nr: Byte);
// Wenn zweimal gedrückt, Anzeige nur toggeln DB/Preset
begin
  if edit_CommonPreset = preset_nr then
    if MenuIndex = 0 then
      MenuIndex_Requested:= 1; // auf DB-Menü
    endif;
    if MenuIndex >= 1 then
      MenuIndex_Requested:= 0; // auf Preset-Menü
    endif;
  else
    edit_CommonPreset:= preset_nr;
    edit_CommonPreset_flag:= c_control_event_source;
  endif;
  xb2_drawbar_mode:= 0;
  edit_SingleDBtoLower:= false;
  edit_SingleDBtoPedal:= false;
end;

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

procedure SWI_MessagePanel(panel_nr: Byte);
begin
  if panel_nr = 2 then
    write(serout,'/ Onboard Panel16 #2');
  else
    write(serout,'/ Preset16/Extend16 #' + char(panel_nr + 48));
  endif;
  writeln(serout,' found');
end;

procedure SWI_InitButtons;
var start_btn, end_btn, btn_type_idx, btn_cancel: Byte;
begin
  SWI_CancelActive_upr:= false;
  SWI_CancelActive_lwr:= false;

  swi_cancel_idx_upr:= 255; // Default "keiner"
  swi_cancel_idx_lwr:= 255;
  swi_has_cancel_upr:= false;
  swi_has_cancel_lwr:= false;

  // Anzahl der verwendeten Organ-Model-Buttons feststellen und ggf.
  // inverse Liste für Rückübersetzung edit_OrganModel -> Button-Offset anlegen
  FillBlock(@swi_inverse_organmodels, sizeof(swi_inverse_organmodels), 255);
  start_btn:= 0;
  end_btn:= c_hw_btntable_max;
  if swi_search_group(c_map_organmodel, start_btn, end_btn) then
    for i:= 0 to end_btn-start_btn do
      n:= eep_OrganModelAssignments[i];
      if n <= 15 then
        swi_inverse_organmodels[n]:= i;
      endif;
    endfor;
  endif;

  // Anzahl der verwendeten Speaker-Model-Buttons feststellen und ggf.
  // inverse Liste für Rückübersetzung edit_SpeakerModel -> Button-Offset anlegen
  FillBlock(@swi_inverse_speakermodels, sizeof(swi_inverse_speakermodels), 255);
  start_btn:= 0;
  end_btn:= c_hw_btntable_max;
  if swi_search_group(c_map_speakermodel, start_btn, end_btn) then
    for i:= 0 to end_btn-start_btn do
      n:= eep_SpeakerModelAssignments[i];
      if n <= 15 then
        swi_inverse_speakermodels[n]:= i;
      endif;
    endfor;
  endif;

  // Preset-Buttons in Tabellen eintragen für schnelleren Zugriff
  // Preset- und Voice-Gruppen suchen
  // (c_map_binary_preset - 100) to (c_map_binary_voice_lp - 100)
  FillBlock(@swi_firstbtns, sizeof(swi_firstbtns), 255); // Default "keiner"
  FillBlock(@swi_lastbtns, sizeof(swi_lastbtns), 255);
  for btn_type_idx:= c_mapidx_firsttype to c_mapidx_lasttype do
    start_btn:= 0;
    end_btn:= c_hw_btntable_max;
    if swi_search_group(btn_type_idx + c_map_firsttype, start_btn, end_btn) then
      swi_firstbtns[btn_type_idx]:= start_btn;
      swi_lastbtns[btn_type_idx]:= end_btn;
    endif;
  endfor;

  // Cancel-Buttons Upper suchen
  swi_cancel_idx_upr:= 0;
  end_btn:= c_hw_btntable_max;
  swi_has_cancel_upr:= swi_search_group(c_map_cancel_upr, swi_cancel_idx_upr, end_btn);
  if swi_has_cancel_upr then
    BtnSwitchSelects[swi_cancel_idx_upr]:= false;
  endif;
  // Cancel-Button Lower suchen
  swi_cancel_idx_lwr:= 0;
  end_btn:= c_hw_btntable_max;
  swi_has_cancel_lwr:= swi_search_group(c_map_cancel_lwr, swi_cancel_idx_lwr, end_btn);
  if swi_has_cancel_lwr then
    BtnSwitchSelects[swi_cancel_idx_lwr]:= false;
  endif;

  SWI_ForceSwitchReload;
  MemorizeTimerPanel:= 0;
  PresetWasSaved:= false;
end;

// #############################################################################

function SWI_GetSwitchVibrato: Byte;
var vib_port, result: Byte;
begin
  if VibKnobPortPresent then
    vib_port:= not VibKnobPortIn;
    result:= vib_port and 3;  // 0 = V1, 1 = C1, 2 = V2
    if Bit(vib_port, 2) then  // C2
      result:= 3;
    elsif Bit(vib_port, 3) then // V3
      result:= 4;
    elsif Bit(vib_port, 4) then // C3
      result:= 5;
    endif;
  else
    result:= edit_VibKnob;
  endif;
  return(result);
end;

procedure SWI_GetSwitchVibratoChange;
// Vibrato-Knopf-Port holen und bei Änderung edit_VibKnob neu setzen
// liefert TRUE wenn geändert
var vibknob: Byte;
begin
  if VibKnobPortPresent then
    vibknob:= SWI_GetSwitchVibrato;
    if vibknob <> Switch_vibrato_old then
      Switch_vibrato_old:= vibknob;
      edit_VibKnob:= vibknob;  // Änderung wird in apply_changes behandelt
      edit_VibKnob_flag:= c_control_event_source;
      edit_VibKnobMode:= 0;    // wurde betätigt, ist vorhanden
      NB_VibknobToVCbits;
      MenuIndex_SplashIfEnabled:= c_VibKnobMenu;
    endif;
  endif;
end;

// #############################################################################

procedure SWI_Init;
// Spezielle Initialisierung für jeweiliges User-Interface
// Es sind noch keine Presets geladen!
begin
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ (SW) Init Switches/Buttons');
{$ENDIF}
  XB2_present:= TWIStat(PCA9532_7);
  for i:= 0 to c_hw_btntable_max do
    n:= eep_BtnRemaps[i];  // Liste 0..63 enthält Remaps
    BtnRemaps[i]:= n;      // Inhalt wie EEPROM 5100.5163
    BtnSwitchSelects[i]:= eep_SwitchInputArr[i]; // wie EEPROM 5200.5263
  endfor;
  for i:= 0 to 31 do
    BtnRemaps_XB[i]:= eep_BtnRemaps_XB[i];      // wie EEPROM 5300.5331
  endfor;

  for i:= 0 to 5 do
    if TWIStat(PCA9532_0 + i) then
      PanelsPresent[i]:= true;
      SWI_MessagePanel(i);
    endif;
  endfor;
  // PCA9532_6 evt. für XB5
  if XB2_present then
    writeln(serout,'/ XB2 panel found');
  endif;
  NB_SetLEDdimmer;

  FillBlock(@xb2_hw_tabs, 16, 0);
  FillBlock(@xb2_hw_btnstates_old, 16, 0);

  FillBlock(@swi_hw_btnstates, c_hw_btntable_size_w, 0);
  FillBlock(@swi_hw_btnstates_old, c_hw_btntable_size_w, 0);

  SWI_InitButtons;

  if VibKnobPortPresent then
    if edit_VibKnobMode = 0 then
      Switch_vibrato_old:= 255;  // Switch_vibrato_old ungültig, neu lesen
    else
      Switch_vibrato_old:= SWI_GetSwitchVibrato;  // Switch_vibrato_old vorbelegen
    endif;
  endif;

  // Wenn Schaltereingänge, neu einlesen
  SWI_ForceSwitchReload;
end;

end switch_interface.


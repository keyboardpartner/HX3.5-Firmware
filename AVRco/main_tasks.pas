// #############################################################################
// ###           Wird in Haupschleife und allen Timeouts aufgerufen          ###
// #############################################################################

unit main_tasks;

interface
uses var_def, const_def, edit_changes, port_def, eeprom_def, edit_changes,
     apply_changes, parser, MIDI_com, midi_sysex;
uses switch_interface, eeprom_def;

procedure MainTasks;
procedure MainTasks_Init;

{$IDATA}

implementation


procedure MT_HandleGMnameRequests;
// angeforderte Namen anzeigen oder an TouchOSC senden
var
  gm_idx, temp_idx: Byte;
begin
  // Reihenfolge von NRPN $3570+x und in GM-VoiceName-Array:
  // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
  for gm_idx:= 0 to 6 do
    if gm_idx = 3 then
      continue;
    endif;
    if GM_VoiceNameReceivedFlags[gm_idx] then
      // Flag ist gesetzt wenn vom DSP SysEx eingetroffen ist
      GM_VoiceNameReceivedFlags[gm_idx]:= false;
      CommentStr:= GM_VoiceNames[gm_idx];
      if ConnectMode = t_connect_osc_wifi then //  OSCconnectedBySerial
        writeln(serout);  // Sync TEXT
        write(serout, '/label_gm/');  // Voice Names schicken
        write(serout, ByteToStr(gm_idx));
        write(serout, '="');
        write(serout, CommentStr);
        writeln(serout, '"');
        mdelay(10);
      endif;
      if GM_VoiceNameToDisplaySema[gm_idx] then
        if LCDpresent then
          LCDxy_M(LCD_m1, 0, 1);
          CommentStr:= PadRight(CommentStr, 15, #32);
          SetLength(CommentStr, 13);
          write(LCDOut_M, CommentStr); // mit Leerzeichen aufgefüllt
        endif;
        GM_VoiceNameToDisplaySema[gm_idx]:= false;
        //MenuIndex_Splash:= c_gmidx_to_menu[gm_idx];  // neues Menu anfordern
      endif;
    endif;
  endfor;
end;

// #############################################################################
// ###          ScheduledTasks: Zeitscheibe, regelmäßig aufgerufen           ###
// #############################################################################


{$IFDEF TIMING_PIN}
procedure MT_Refpulse;
begin
  TEST_LA:= high;
  udelay(10);
  TEST_LA:= low;
  udelay(10);
end;
{$ENDIF}

procedure MT_ScheduledTasks;
// Zeitscheibe, Verteilung der Rechenleistung bei nicht zeitkritischen Aufgaben
// Wird regelmäßig alle 2ms aus #MainTasks# heraus aufgerufen:
// fragt Panels, Presets und Schalter ab und speichert Werte
// in edit-Parameter-Tabelle. Auswertung erfolgt in #AC_HandleTabEditChanges#
// und #AC_HandleKnobChanges#, sofern nicht durch Parser oder MenuPanel gesperrt
// Jeder TimeSlot wird alle 16 ms ausgeführt, keiner sollte länger als 2ms dauern.
const
  c_pitchwheel_hyst: Byte = 12;

var my_bool: Boolean;
    my_idx, my_val: Byte;
begin
  if not inctolim(TimeSlot, 7) then  // 8 Timeslots, 0 bis 7
    TimeSlot:= 0;
  endif;
  case TimeSlot of
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    0:
      // Änderungs-Flags löschen, wurden noch in menu_system gebraucht
      // 24..88 ADCs lesen und bei Änderung verteilen
      if edit_ADCconfig > 0 then
        SWI_GetPanel16(0); // ca. 700µs pro Panel16
      endif;

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

      ADC_ReadAll_24;      // ca. 450 µs bei 24 DBs
      FH_UpdatePHRspeed;
      NB_CheckDFUmsg;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    1:
      ADC_ReadAll_64;  // ca. 1150 µs bei 64 DBs
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    2:
      // Panel16 abfragen
      if edit_ADCconfig > 0 then
        SWI_GetPanel16(1);  // ca. 700µs pro Panel16 wenn vorhanden
        SWI_GetPanel16(2);  // ca. 700µs pro Panel16 wenn vorhanden
      endif;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    3:
      // Panel16 abfragen
      if edit_ADCconfig > 0 then
        SWI_GetPanel16(3);  // ca. 700µs pro Panel16 wenn vorhanden
        SWI_GetPanel16(4);  // ca. 700µs pro Panel16 wenn vorhanden
        SWI_HandleXB2panel;
      endif;
      MIDI_SendChangedSwell(MIDI_NewSwellVal);
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    4:
      if edit_ADCconfig > 0 then
        SWI_GetPanel16(5);  // ca. 400µs pro Panel16 wenn vorhanden
        SWI_GetSwitchVibratoChange;  // VibKnobPort Drehschalter ca. 150 µs
        ADC_ChangesToEdit;      // ca. 300µs

        if edit_Wheel_PitchToMIDI_flag > 0 then
          if edit_Wheel_PitchToMIDI >= (64 + c_pitchwheel_hyst) then
            n:= edit_Wheel_PitchToMIDI
                -  muldivByte(127 - edit_Wheel_PitchToMIDI, c_pitchwheel_hyst, 64);
          elsif edit_Wheel_PitchToMIDI <= (64 - c_pitchwheel_hyst) then
            n:= edit_Wheel_PitchToMIDI
                + muldivByte(edit_Wheel_PitchToMIDI, c_pitchwheel_hyst, 64);
          else
            n:= 64; // Mittelstellung
          endif;
          MIDI_SendPitchwheel(0, n);
          edit_Wheel_PitchToMIDI_flag:= 0;
        endif;

        if edit_Wheel_PitchRotary_flag > 0 then
          if edit_Wheel_PitchRotary > 96 then
            if not edit_LogicalTab_LeslieFast then  // nur einmal senden
              edit_LogicalTab_LeslieFast_flag:= c_board_event_source;
              edit_LogicalTab_LeslieFast:= true;
            endif;
          endif;
          if edit_Wheel_PitchRotary < 32 then
            if edit_LogicalTab_LeslieFast then  // nur einmal senden
              edit_LogicalTab_LeslieFast_flag:= c_board_event_source;
              edit_LogicalTab_LeslieFast:= false;
            endif;
          endif;
          edit_Wheel_PitchRotary_flag:= 0;
        endif;

        if edit_Wheel_ModToMIDI_flag > 0 then
          MIDI_SendController(0, 1, edit_Wheel_ModToMIDI); // MIDI Modulation
          edit_Wheel_ModToMIDI_flag:= 0;
        endif;

        if edit_Wheel_ModRotary_flag > 0 then
          my_bool:= edit_Wheel_ModRotary >= 64;
          if edit_LogicalTab_LeslieRun <> my_bool then // nur einmal senden
            edit_LogicalTab_LeslieRun:= my_bool;
            edit_LogicalTab_LeslieRun_flag:= c_board_event_source;
          endif;
          edit_Wheel_ModRotary_flag:= 0;
        endif;

      endif;
      MT_HandleGMnameRequests;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    5:
{$IFDEF TIMING_PIN}
      MT_Refpulse;
      TEST_LA:= high;
{$ENDIF}
{$IFDEF TIMING_PIN}
      TEST_LA:= low;
{$ENDIF}
      AC_IncDecControls;  // Momentary Buttons
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    6:
{$IFDEF TIMING_PIN}
      TEST_LA:= high;
{$ENDIF}
      // gesammelte Aktionen ausführen
      AC_ExecEditChanges;
      FH_UpdatePHRspeed;
{$IFDEF TIMING_PIN}
      TEST_LA:= low;
{$ENDIF}
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    7:
      // TimeSlot 7 auch für MenuPanelHandling in MainLoop(benötigt dort 250..350µs)
      // MenuPanelHandling darf wg. möglicher Rekursion nicht hier stehen!
      // Behandlung der geänderten Buttons, Presets, Switches
      MIDI_SendChangedSwell(MIDI_NewSwellVal);
      if edit_ADCconfig > 0 then
        if Bit(edit_ConfBits2, 0) then  // Klinkenbuchsen sind Schalter-Eingänge
          if Bit(edit_ConfBits2, 5) then
              // Vertauschte Eingänge für Hammond-Halfmoon
            FootSwFast:= not FOOTSW_LESLRUN;
            FootSwRun:= not FOOTSW_LESLFAST;
          else
            FootSwFast:= not FOOTSW_LESLFAST;
            FootSwRun:= not FOOTSW_LESLRUN;
          endif;
          // FootSwSlow:= FootSwRun and (not FootSwFast);
          if footsw_lesliefast_old <> FootSwFast then
            edit_LogicalTab_LeslieFast:= FootSwFast;
            edit_LogicalTab_LeslieFast_flag:= c_control_event_source;
            footsw_lesliefast_old:= FootSwFast;
            if Bit(edit_ConfBits2, 1) then  // Slow/Stop/Fast-Schalter
              if FootSwFast then
                edit_LogicalTab_LeslieRun:= True;
                edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
              elsif (not FootSwRun) then
                edit_LogicalTab_LeslieRun:= false;
                edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
              endif;
            endif;
            AC_SendRotarySpeed;
          endif;

          if footsw_leslierun_old <> FootSwRun then
            edit_LogicalTab_LeslieRun:= FootSwRun;
            edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
            footsw_leslierun_old:= FootSwRun;
            if Bit(edit_ConfBits2, 1) then  // Slow/Stop/Fast-Schalter
              if (not FootSwFast) and (not FootSwRun) then
                edit_LogicalTab_LeslieRun:= false;
                edit_LogicalTab_LeslieFast:= false;
                edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
              endif;
            endif;
            AC_SendRotarySpeed;
          endif;
        else                       // Klinkenbuchsen sind Taster-Eingänge
          if FootSwFast then       // Taster OFF?
            inctolim(footsw_lesliefast_debounce, 5);
          else
            dectolim(footsw_lesliefast_debounce, 0);
          endif;
          FootSwFast:= footsw_lesliefast_debounce >= 5;
          if FootSwFast and (not footsw_lesliefast_old) then
            edit_LogicalTab_LeslieFast:= not edit_LogicalTab_LeslieFast;
            edit_LogicalTab_LeslieFast_flag:= c_control_event_source;
          endif;
          footsw_lesliefast_old:= FootSwFast;

          if FootSwRun then        // Taster OFF?
            inctolim(footsw_leslierun_debounce, 5);
          else
            dectolim(footsw_leslierun_debounce, 0);
          endif;
          FootSwRun:= footsw_leslierun_debounce >= 5;
          if FootSwRun and (not footsw_leslierun_old) then
            edit_LogicalTab_LeslieRun:= not edit_LogicalTab_LeslieRun;
            edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
          endif;
          footsw_leslierun_old:= FootSwRun;

        endif;
      endif;

      inc(ToggleLEDcount);
      if ToggleLEDcount > 15 then
        ToggleLEDcount:= 0;
        ToggleLEDstate:= not ToggleLEDstate;
        if ConnectMode = t_connect_osc_midi then // OSCconnectedByMIDI
          MIDI_SendBoolean(3, 91, ToggleLEDstate);
        endif;
        if PresetStoreRequest then
          if ConnectMode = t_connect_osc_wifi then  // OSCconnectedBySerial
            NB_SendBinaryVal(1640, 64);
          elsif ConnectMode = t_connect_osc_midi then // OSCconnectedByMIDI
            MIDI_SendBoolean(3, 90, ToggleLEDstate);
          endif;
        endif;
      endif;

      if issystimerzero(TimeoutTimer) then
        AC_IncDecControlsTimerElapsed;
      endif;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  endcase;
end;

// #############################################################################

procedure MainTasks;
begin
  // Festes Zeitraster für Task-Switcher: 2 ms (SysTick)
  // Warten auf SysTick, währenddessen eilige Aufgaben erledigen
  while SysTickSema = 0 do
    PA_CheckSer;            // Serinp immer parsen
    MIDI_Dispatch;           // MIDI-Input immer auswerten
  endwhile;

  inc(BlinkTimerByte);
  BlinkToggle:= Bit(BlinkTimerByte, 7);
  dectolim(SysTickSema, 0);
  FH_UpdateLeslieSpeed;
  MT_ScheduledTasks;         // weniger zeitkritische Aufgaben
  ADC_ReadSwell;
  AC_SendSwell; // spontate Reaktion auf Schweller erforderlich, alle 2ms

  if issystimerzero(ActivityTimer) then
    LEDactivity:= high;
    LED_DOWN:= high;
    // Momentary Button Auto Release
  endif;
end;

procedure MainTasks_Init;
begin
  FillBlock(@edit_Wheels_flag, 4, 0);
  edit_Wheel_PitchToMIDI:= 64;
  edit_Wheel_PitchRotary:= 64;
  if (edit_ADCconfig > 0) and Bit(edit_ConfBits2, 0) then  // Schalter-Eingänge
    FootSwFast:= not FOOTSW_LESLFAST;
    FootSwRun:= not FOOTSW_LESLRUN;

    if FootSwRun then
      edit_LogicalTab_LeslieRun:= true;
      edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
      footsw_leslierun_old:= true;
    endif;

    if FootSwFast then
      edit_LogicalTab_LeslieFast:= true;
      edit_LogicalTab_LeslieFast_flag:= c_control_event_source;
      footsw_lesliefast_old:= true;
      if Bit(edit_ConfBits2, 1) then  // Slow/Stop/Fast-Schalter
        edit_LogicalTab_LeslieRun:= True;
        edit_LogicalTab_LeslieRun_flag:= c_control_event_source;
      endif;
    endif;

  endif;
end;

end.


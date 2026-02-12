// #############################################################################
// ###                    NUR  K E Y S W E R K - M O D U L                   ###
// ###           Wird in Haupschleife und allen Timeouts aufgerufen          ###
// #############################################################################

unit main_tasks_module;

interface
uses var_def, const_def, edit_changes, edit_changes,
     apply_changes, parser, MIDI_com, midi_sysex;

procedure MainTasks;
procedure MainTasks_Init;

{$IDATA}

implementation

// #############################################################################
// ###          ScheduledTasks: Zeitscheibe, regelmäßig aufgerufen           ###
// #############################################################################

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
      UpperSecondaryActive:= edit_UpperVoice = edit_2ndDBselect;
      UpperIsLive:= UpperSecondaryActive or (edit_UpperVoice = 0);

      LowerSecondaryActive:= edit_LowerVoice = edit_2ndDBselect;
      LowerIsLive:= LowerSecondaryActive or (edit_LowerVoice = 0);

      FH_UpdatePHRspeed;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    1:
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    2:
      // Panel16 abfragen
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    3:
      // Panel16 abfragen
       AC_MomentaryControls;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    4:
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    5:
      // später ggf. AC_CollectedActionsToFPGA ausführen:
      // Aktionen sammeln, ans FPGA im nächsten Slot
      AC_MutualControls; // gegenseitig beeinflussende Bedienelemente behandeln
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    6:
      // gesammelte Aktionen ausführen
      AC_ExecEditChanges;
      FH_UpdatePHRspeed;
      |
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    7:
      if issystimerzero(TimeoutTimer) then
        AC_MomentaryControlsTimerElapsed;
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
  FH_updateLeslieSpeed;
  MT_ScheduledTasks;         // weniger zeitkritische Aufgaben
  AC_SendSwell; // spontate Reaktion auf Schweller erforderlich, alle 2ms

  if issystimerzero(ActivityTimer) then
    LEDactivity:= high;
    // Momentary Button Auto Release
  endif;
end;

procedure MainTasks_Init;
begin

end;

end.


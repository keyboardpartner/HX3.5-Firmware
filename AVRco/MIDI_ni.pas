// #############################################################################
// ###                       MIDI-SYSEX-DISPATCHER                           ###
// #############################################################################

// Standard-CC-Set und eigene SysEx, sollte immer vorhanden sein.



// #############################################################################
// ###  MIDI-DISPATCHER NONE, CCs ignorieren (auﬂer Expression/Schweller)    ###
// #############################################################################

procedure MIDI_Dispatch_none;
// falls MIDI-CC disabled, nur Volume/Expression
begin
  if (mch = edit_MIDI_Channel) and (mcmd = $B0) then   // Control Change
    LED_timer50;
    MIDI_setswell;
  endif;
end;

// #############################################################################
// ###         MIDI-DISPATCHER NI und Doepfer d3c Drawbars                   ###
// #############################################################################

procedure MIDI_Dispatch_ni;
var my_index: byte;
    my_param: Integer;
begin
// mcmd = Command isoliert,
// mch = Channel isoliert,
// mp = Controller-Nr,
// mv = Controller-Wert
  if (mch=edit_MIDI_Channel) then
    // d3c sendet immer auf Basiskanal 0
    if (mcmd = $C0) and (not edit_MIDI_DisableProgramChange) then   // Program Change
      if valueinrange(mp,0,11) then
        edit_UpperVoice:= mp;
        edit_UpperVoice_flag:= c_midi_event_source;
      elsif valueinrange(mp,12,23) then
        edit_LowerVoice:= (mp-12);
        edit_LowerVoice_flag:= c_midi_event_source;
      endif;
    else
      // Upper bis Pedal Channel
      MIDI_Dispatch_custom;
    endif;
  endif;

  if mch = edit_MIDI_Channel+1 then
    MIDI_Dispatch_custom;
  endif;

  if mch = edit_MIDI_Channel+2 then
    MIDI_Dispatch_custom;
  endif;

end;


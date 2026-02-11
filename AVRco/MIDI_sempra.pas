// #############################################################################
// ###                 MIDI-DISPATCHER KEYSWERK SEMPRA                       ###
// #############################################################################

// Umfangreichster Dispatcher, mit sehr vielen Einstellungen

// NRPN-Handling für SEMPRA:

// NRPN senden: Parameter-Nummer senden, Reihenfolge MSB/LSB egal.
// Falls erforderlich, erst Data MSB (CC #6) auf Kanal 2 senden, macht noch nichts
// Dann Data LSB (CC #6) auf Kanal 1 senden, setzt dann den gewünschten Wert
// Data MSB wird danach automatisch wieder auf 0 gesetzt (sicherheitshalber)


procedure DispatchNRP_sempra;
var my_param, my_int: Integer; my_idx: Byte;
begin
//  if midi_nrpn_msb = 0 then  // Falls MSB noch nicht gesetzt
//    midi_nrpn_msb:= $0B; // wahrscheinlich 1468 ff. gewünscht
//  endif;
  my_param:= MIDI_14_to_int(midi_nrpn_msb, midi_nrpn_lsb);
  my_int:= MIDI_14_to_int(midi_data_entry_msb, midi_data_entry_lsb);
{$IFDEF DEBUG_SEMPRA}
  write(serout, '/ SemNRPN $' + ByteToHex(midi_nrpn_msb) + '.' + ByteToHex(midi_nrpn_lsb) + #9
  + IntToStr(my_param) + '=' + IntToStr(my_int) + '  ' + #9);  // mit Tab-Ausgleich
  if valueInRange(my_param, 1000, 1511) then
    write(serout, s_MidiDebugStrArr[my_param - 1000]);
  else
    write(serout,' INVALID!');
  endif;
  writeln(serout);
{$ENDIF}
  if valueInRange(my_param, 1000, 1511) then
    PA_NewEditEvent(Word(my_param) - 1000, Lo(my_int), false, c_midi_event_source);
  endif;
  midi_data_entry_msb:= 0;  // sicherheitshalber
  midi_nrpn_flags:= 0;
end;



procedure MIDI_Dispatch_sempra;
// wird angesprungen, sobald ein vollständiger MIDI-Datensatz
// (zwei oder drei Bytes, ja nach Command-Byte) im FIFO ist.
// MIDI-Daten können von beiden MIDI-Schnittstellen stammen,
// aber auch von der PicoBlaze-CPU im FPGA (Keyboard/MIDI-ScanCore) selbst.
// mcmd = Command isoliert,
// mch = Channel isoliert,
// mp = Controller-Nr,
// mv = Controller-Wert

var
  my_fac, my_index, my_byte: byte;
  my_param: Integer;
begin

  if valueinrange(mch, edit_MIDI_Channel, edit_MIDI_Channel+1) then // UPPER und LOWER
    if mcmd = $B0 then   // Control Change
      // für beide Kanäle 1..2 gültig
      case mp of
        $0B: // 11, Expression Pedal, Hammond AO28
          midi_swell128:= mv;
          SwellPedalControlledByMIDI:= true;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemExpr  ' + ByteToStr(mv));
{$ENDIF}
          return;
          |
        $1E: // Schweller-Lautstärke für Böhm
          midi_swell128:= mv;
          SwellPedalControlledByMIDI:= true;
          edit_ModuleSwellVolume:= mv;
          edit_ModuleSwellVolume_flag:= c_midi_event_source;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemSwell  ' + ByteToStr(mv));
{$ENDIF}
          return;
          |

        $62:
          midi_nrpn_lsb:= mv;
          return;
          |
        $63:
          midi_nrpn_msb:= mv;
          return;
          |
      endcase;
    endif;
  endif;

  if mch = edit_MIDI_Channel then // nur UPPER betreffend
    if mcmd = $B0 then   // Control Change
      LED_timer50;  // Setzt ActivityTimer
      case mp of
        $06:
          midi_data_entry_lsb:= mv;    // LSB auf UPPER!
          DispatchNRP_sempra;
          // NRPN senden: Parameter-Nummer senden, Reihenfolge MSB/LSB egal.
          // Falls erforderlich, erst Data MSB (CC #6) auf Kanal 2 senden, macht noch nichts
          // Dann Data LSB (CC #6) auf Kanal 1 senden, setzt dann den gewünschten Wert
          // Data MSB wird danach automatisch wieder auf 0 gesetzt (sicherheitshalber)
          |
        $07: // Kanal-Lautstärke
          edit_UpperVolumeWet:= mv;
          edit_UpperVolumeWet_flag:= c_midi_event_source;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemUprVol ' + ByteToStr(mv));
{$ENDIF}
           |
        $09: // Kanal-Lautstärke Perc/Dry-Kanal
          edit_UpperVolumeDry:= mv;
          edit_UpperVolumeDry_flag:= c_midi_event_source;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemUprVol ' + ByteToStr(mv));
{$ENDIF}
           |
        $4E:  // Upper ADSR Group 1 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_UpperDBtoADSR[i]:= Bit(mv, i);
            edit_LogicalTab_UpperDBtoADSR_flag[i]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemUprMask1 $' + ByteToHex(mv));
{$ENDIF}
          |
        $4F:  // Upper ADSR Group 2 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_UpperDBtoADSR[i + 4]:= Bit(mv, i);
            edit_LogicalTab_UpperDBtoADSR_flag[i+4]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemUprMask2 $' + ByteToHex(mv));
{$ENDIF}
          |
        $50:  // Upper ADSR Group 3 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_UpperDBtoADSR[i + 8]:= Bit(mv, i);
            edit_LogicalTab_UpperDBtoADSR_flag[i+8]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemUprMask3 $' + ByteToHex(mv));
{$ENDIF}
          |
      else
        my_param:= CCarray_i[mch - edit_MIDI_Channel, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endcase;
    endif;

  elsif mch = edit_MIDI_Channel+1 then // nur LOWER betreffend
    if mcmd = $B0 then   // Control Change
      LED_timer50;  // Setzt ActivityTimer
      case mp of
        $06:
          midi_data_entry_msb:= mv;  // MSB auf LOWER!
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemDataMSB ' + ByteToStr(mv));
{$ENDIF}
          |
        $07: // Kanal-Lautstärke, geht von 0..255!
          edit_LowerVolume:= mv;
          edit_LowerVolume_flag:= c_midi_event_source;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemLwrVol ' + ByteToStr(mv));
{$ENDIF}
          |
        $4E:  // Lower ADSR Group 1 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_LowerDBtoADSR[i]:= Bit(mv, i);
            edit_LogicalTab_LowerDBtoADSR_flag[i]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemLwrMask1 $' + ByteToHex(mv));
{$ENDIF}
          |
        $4F:  // Lower ADSR Group 2 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_LowerDBtoADSR[i + 4]:= Bit(mv, i);
            edit_LogicalTab_LowerDBtoADSR_flag[i+4]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemLwrMask2 $' + ByteToHex(mv));
{$ENDIF}
          |
        $50:  // Lower ADSR Group 3 Mask
          for i:= 0 to 3 do
            edit_LogicalTab_LowerDBtoADSR[i + 8]:= Bit(mv, i);
            edit_LogicalTab_LowerDBtoADSR_flag[i+8]:= c_midi_event_source;
          endfor;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemLwrMask3 $' + ByteToHex(mv));
{$ENDIF}
          |
      else
        my_param:= CCarray_i[mch - edit_MIDI_Channel, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endcase;
    endif;

  elsif mch = edit_MIDI_Channel+2 then // nur PEDAL betreffend
    if mcmd = $B0 then   // Control Change
      LED_timer50;  // Setzt ActivityTimer
      if valueInRange(mp, $2D, $3E) then
        edit_ena_cont_bits_flag:= word(c_midi_event_source);
        edit_ena_cont_perc_bits_flag:= word(c_midi_event_source);
        edit_ena_env_adsrmode_bits_flag:= word(c_midi_event_source);
      endif;
      m:= mv and 15;
      n:= mv shl 4;
      case mp of
        $07: // Kanal-Lautstärke
          edit_PedalVolume:= mv;
          edit_PedalVolume_flag:= c_midi_event_source;
{$IFDEF DEBUG_SEMPRA}
          writeln(serout, '/ SemPedVol ' + ByteToStr(mv));
{$ENDIF}
          |

        $2D: // ENA_CONT_BITS
          lo(edit_ena_cont_bits):= (lo(edit_ena_cont_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENA_CONT_BITS     ');
          NB_writeser_enabits(edit_ena_cont_bits);
{$ENDIF}
          |
        $2E: // ENA_CONT_BITS
          lo(edit_ena_cont_bits):= (lo(edit_ena_cont_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENA_CONT_BITS     ');
          NB_writeser_enabits(edit_ena_cont_bits);
{$ENDIF}
          |
        $2F: // ENA_CONT_BITS
          hi(edit_ena_cont_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENA_CONT_BITS     ');
          NB_writeser_enabits(edit_ena_cont_bits);
{$ENDIF}
          |

        $30: // ENA_CONT_PERC_BITS
          lo(edit_ena_cont_perc_bits):= (lo(edit_ena_cont_perc_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_CONT_PERC_BITS    ');
          NB_writeser_enabits(edit_ena_cont_perc_bits);
{$ENDIF}
          |
        $31: // ENA_CONT_PERC_BITS
          lo(edit_ena_cont_perc_bits):= (lo(edit_ena_cont_perc_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_CONT_PERC_BITS    ');
          NB_writeser_enabits(edit_ena_cont_perc_bits);
{$ENDIF}
          |
        $32: // ENA_CONT_PERC_BITS
          hi(edit_ena_cont_perc_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_CONT_PERC_BITS    ');
          NB_writeser_enabits(edit_ena_cont_perc_bits);
{$ENDIF}
          |

        $33: // ENA_ENV_DB_BITS
          lo(edit_ena_env_db_bits):= (lo(edit_ena_env_db_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_DB_BITS       ');
          NB_writeser_enabits(edit_ena_env_db_bits);
{$ENDIF}
          |
        $34: // ENA_ENV_DB_BITS
          lo(edit_ena_env_db_bits):= (lo(edit_ena_env_db_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_DB_BITS       ');
          NB_writeser_enabits(edit_ena_env_db_bits);
{$ENDIF}
          |
        $35: // ENA_ENV_DB_BITS
          hi(edit_ena_env_db_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_DB_BITS       ');
          NB_writeser_enabits(edit_ena_env_db_bits);
{$ENDIF}
          |

        $36: // ENA_ENV_ADSRMODE_BITS
          lo(edit_ena_env_adsrmode_bits):= (lo(edit_ena_env_adsrmode_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_ADSRMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_adsrmode_bits);
{$ENDIF}
          |
        $37: // ENA_ENV_ADSRMODE_BITS
          lo(edit_ena_env_adsrmode_bits):= (lo(edit_ena_env_adsrmode_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_ADSRMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_adsrmode_bits);
{$ENDIF}
          |
        $38: // ENA_ENV_ADSRMODE_BITS
          hi(edit_ena_env_adsrmode_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_ADSRMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_adsrmode_bits);
{$ENDIF}
          |

        $39: // ENA_ENV_PERCMODE_BITS
          lo(edit_ena_env_percmode_bits):= (lo(edit_ena_env_percmode_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_PERCMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_percmode_bits);
{$ENDIF}
          |
        $3A: // ENA_ENV_PERCMODE_BITS
          lo(edit_ena_env_percmode_bits):= (lo(edit_ena_env_percmode_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_PERCMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_percmode_bits);
{$ENDIF}
          |
        $3B: // ENA_ENV_PERCMODE_BITS
          hi(edit_ena_env_percmode_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_PERCMODE_BITS ');
          NB_writeser_enabits(edit_ena_env_percmode_bits);
{$ENDIF}
          |

        $3C: // ENV_TO_DRY_BITS
          lo(edit_env_to_dry_bits):= (lo(edit_env_to_dry_bits) and $F0) or m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_TO_DRY_BITS   ');
          NB_writeser_enabits(edit_env_to_dry_bits);
{$ENDIF}
          |
        $3D: // ENV_TO_DRY_BITS
          lo(edit_env_to_dry_bits):= (lo(edit_env_to_dry_bits) and $0F) or n;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_TO_DRY_BITS   ');
          NB_writeser_enabits(edit_env_to_dry_bits);
{$ENDIF}
          |
        $3E: // ENV_TO_DRY_BITS
          hi(edit_env_to_dry_bits):= m;
{$IFDEF DEBUG_SEMPRA}
          write(serout, '/ Sem_ENV_TO_DRY_BITS   ');
          NB_writeser_enabits(edit_env_to_dry_bits);
{$ENDIF}
          |
      else
        my_param:= CCarray_i[mch - edit_MIDI_Channel, mp];
        MIDI_Setval(my_param); // Limit/Scale/Toggle etc.
      endcase;
    endif;
  endif;
end;


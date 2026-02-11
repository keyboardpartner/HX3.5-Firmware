// #############################################################################
// ###                   FPGA HIGH-LEVEL-FUNKTIONEN                          ###
// ###             Tabs und gesetzte Parameter an FPGA senden                ###
// #############################################################################

// AutoInc-Register FPGA-SPI
// LC#    Breite   Länge Bytes  LC Core
// 0        24        8192      PicoBlaze       (Datei/DF-Blocks)
// 1         8        1024      Taper-RAM (Datei/DF in 32 Bit, nur unterste 8 übertragen)
// 2        16        2048      FIR-Coeff       (Datei/DF-Blocks)
// 3         8        1024      Keymap-RAM      (berechnet)
// 4        16       16384      Wave-RAM        (Datei/DF-Blocks)
// 5        16          96      Frequenz/Tuning (berechnet)
// 6        16        1024      Highpass-Filter (berechnet)
// 7 NEU    16         512      TubeAmp Steps/Slopes,je 256 Werte (aus Tabelle)
// 8         8          16      Upper DBs       (berechnet)
// 9         8          16      Lower DB        (berechnet)
// 10        8          16      Pedal DB        (berechnet)
// 11       16          64      ADSR Upper      (berechnet)
// 12       16          64      ADSR Lower      (berechnet)
// 13       16          64      ADSR Pedal      (berechnet)

// Block-Offsets zu Block c_scan_base
// 0..1: Scan Core,
// 9: EEPROM Backup,
// 10: DSP Core,
// 11..14: Tapering
// 15: FIR filter
// 16 ff.: Wavesets, je 4 Blocks!


unit fpga_hilevel;

interface
uses var_def, const_def, fpga_if, dataflash, MIDI_com, nuts_and_bolts;

  procedure FH_InsertsToFPGA;
  procedure FH_SplitConfigToFPGA;

  procedure FH_UpperDrawbarsToFPGA;
  procedure FH_LowerDrawbarsToFPGA;
  procedure FH_PedalDrawbarsToFPGA;

  procedure FH_PercussionParamsToFPGA;
  procedure FH_VibratoToFPGA;

  procedure FH_OrganParamsToFPGA;
  procedure FH_LicenceToFPGA;

  procedure FH_SendLeslieInitsToFPGA;
  procedure FH_SendFIRToFPGA(rotary_model: Byte);

// vorgefertigte Blocks (8 pro Set) mit Nummer wave_set
// aus DF laden und an AutoInc-Reg senden, 16 Bit breit
  procedure FH_WaveBlocksToFPGA;

// 1024 Keymap-Werte 8 Bit breit an FPGA DDS48 übertragen
  procedure FH_KeymapToFPGA;

// 1024 HighpassFilter 16 Bit breit an FPGA DDS48 übertragen
  procedure FH_NoteHighpassFilterToFPGA;

// 95 Tuning-Werte 16 Bit breit an FPGA DDS96 übertragen
  procedure FH_TuningValsToFPGA;

// 8 Bit breit an FPGA TAPER übertragen
  procedure FH_TaperingToFPGA(const taper_set: byte);

  procedure FH_TubeCurveToFPGA(const tube_set_a, tube_set_b: byte);

  procedure FH_PhasingRotorToFPGA;
  procedure FH_UpdatePHRspeed;

  procedure FH_UpdateLeslieSpeed;

  procedure FH_UpperRoutingToFPGA;
  procedure FH_RouteOrgan;
  procedure FH_PercOnOff;

  procedure FH_TestExtLicence;

{$IFNDEF MODULE}
  procedure FH_SendReverbTabs;
{$ELSE}
  procedure FH_SendModuleExtRotary;
{$ENDIF}

implementation
{$IDATA}
var
  // Für TubeAmp Kennlinien
  StepSlopeArray[@BlockBuffer8]: array[0..511] of Integer;  // Gesamttabelle
  StepArray[@BlockBuffer8]: array[0..255] of Integer;
  SlopeArray[@BlockBuffer8 + 512]: array[0..255] of Integer;

  temp_db_levels: array[0..15] of byte;// Mixturen umgerechnet zum Senden an FPGA
  temp_dbe_levels: array[0..15] of byte;// Mixturen umgerechnet zum Senden an FPGA

  PhasingTimer : Systimer8;
  HornTimer, RotorTimer: Systimer8;
  MixturesEnaByte: byte;

  // erhalten übersetzte Werte aus edit_UpperRoutingWords
  bb_UpperRoutingWords: array[0..7] of word;
    // an FPGA:
  bb_ena_cont_bits[@bb_UpperRoutingWords + 0]: word;         // FPGA SPI #40
  bb_ena_env_db_bits[@bb_UpperRoutingWords + 2]: word;       // FPGA SPI #41
  bb_ena_env_full_bits[@bb_UpperRoutingWords + 4]: word;     // FPGA SPI #42
  bb_env_to_dry_bits[@bb_UpperRoutingWords + 6]: word;       // FPGA SPI #43
    // nur in FW benutzt:
  bb_ena_cont_perc_bits[@bb_UpperRoutingWords + 8]: word;         // FPGA SPI #32
  bb_ena_env_percmode_bits[@bb_UpperRoutingWords + 10]: word;     // FW use, enable Perc DB
  bb_ena_env_adsrmode_bits[@bb_UpperRoutingWords + 12]: word;     // FW use, enable ADSR
  bb_ena_env_timemode_bits[@bb_UpperRoutingWords + 14]: word;     // FW use, full ADSR

  bb_attack_arr: array[0..15] of byte;   // Zeitkorrekturen für EG Decay Mode
  bb_decay_arr : array[0..15] of byte;  // Zeitkorrekturen für EG Decay Mode
  bb_sustain_arr: array[0..15] of byte;   // Zeitkorrekturen für EG Decay Mode
  bb_release_arr: array[0..15] of byte;   // Zeitkorrekturen für EG Decay Mode

  fpga_PhasingGroup: array[0..15] of byte;
  fpga_PHR_SpeedVariSlow[@fpga_PhasingGroup + 0]: byte;       // FPGA SPI #112
  fpga_PHR_SpeedVariFast[@fpga_PhasingGroup + 1]: byte;
  fpga_PHR_SpeedSlow[@fpga_PhasingGroup + 2]: byte;
  fpga_PHR_Feedback[@fpga_PhasingGroup + 3]: byte;
  fpga_PHR_LevelPh1[@fpga_PhasingGroup + 4]: byte;
  fpga_PHR_LevelPh2[@fpga_PhasingGroup + 5]: byte;
  fpga_PHR_LevelPh3[@fpga_PhasingGroup + 6]: byte;
  fpga_PHR_LevelDry[@fpga_PhasingGroup + 7]: byte;
  fpga_PHR_FeedBackInvert[@fpga_PhasingGroup + 8]: byte;
  fpga_PHR_RampDelay[@fpga_PhasingGroup + 9]: byte;
  fpga_PHR_ModVariPh1[@fpga_PhasingGroup + 10]: byte;
  fpga_PHR_ModVariPh2[@fpga_PhasingGroup + 11]: byte;
  fpga_PHR_ModVariPh3[@fpga_PhasingGroup + 12]: byte;
  fpga_PHR_ModSlowPh1[@fpga_PhasingGroup + 13]: byte;
  fpga_PHR_ModSlowPh2[@fpga_PhasingGroup + 14]: byte;
  fpga_PHR_ModSlowPh3[@fpga_PhasingGroup + 15]: byte;

{
  temp_DBEs: Array[0..15] of byte; // alternate DBE ADSR drawbar set
    temp_DBE_16[@temp_DBEs+0]:     byte;
    temp_DBE_5_13[@temp_DBEs+1]:   byte;
    temp_DBE_8[@temp_DBEs+2]:      byte;
    temp_DBE_4[@temp_DBEs+3]:      byte;
    temp_DBE_2_23[@temp_DBEs+4]:   byte;
    temp_DBE_2[@temp_DBEs+5]:      byte;
    temp_DBE_1_35[@temp_DBEs+6]:   byte;
    temp_DBE_1_23[@temp_DBEs+7]:   byte;
    temp_DBE_1[@temp_DBEs+8]:      byte;
    temp_DBE_mixt1[@temp_DBEs+9]:  byte;
    temp_DBE_mixt2[@temp_DBEs+10]: byte;
    temp_DBE_mixt3[@temp_DBEs+11]: byte;
}

const
  // Impulsantwort (fast) linear
  c_fir_linear_arr: Array[0..7] of Word = (
    10000, 20000, 28000, 32767, 28000, 20000, 10000, 0);   // muss mit 0 enden

// #############################################################################

procedure FH_SendFIRToFPGA(rotary_model: Byte);
var idx: Word;
begin
  if rotary_model < 8 then
    DF_SendToAutoinc(c_coeff_base_DF, 2, 512);  // FIR Koeffizienten Horn (Reg. 2)
  else
    FI_AutoIncSetup(2);
    for idx:= 0 to 511 do
      if idx < 8 then
        FPGAsendLong:= LongInt(c_fir_linear_arr[idx]);
      endif;
      SendFPGA32;
    endfor;
    FI_AutoIncReset(2);
  endif;
end;

procedure FH_SendLeslieInitsToFPGA;
begin
// Leslie Equalizer, Offsets und Delays an FPGA
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Rotary params to FPGA');
{$ENDIF}
  edit_LeslieInits[17]:= edit_LeslieInits[16];
  edit_LeslieInits[19]:= edit_LeslieInits[18];
  edit_LeslieInits[21]:= edit_LeslieInits[20];
  edit_LeslieInits[23]:= edit_LeslieInits[22];
  // edit_LeslieInpLvl wird in AC_SendVolumes korrigiert und gesendet!
  for i:= 5 to 63 do
    m:= edit_LeslieInits[i]; // Grundeinstellungen direkt an FPGA
    SendByteToFPGA(m, i + 176);
  endfor;
  SendByteToFPGA(edit_LeslieInits[28], 179); // Invert Horn
  edit_MasterVolume_flag:= c_to_fpga_event_source;
  FH_InsertsToFPGA;
end;

// #############################################################################
// ###                       FPGA MIDI-FUNKTIONEN                            ###
// #############################################################################

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************

procedure FH_SendReverbTabs;
// Vorbereitete Parameter-Tabelle UPPER für HX3-Engine an FPGA
{
  SAM _LiveMic Reverb programs:
  0: Off		1: Short Room		2: Room A		3: Room B
  4: Small Hall A	5: Small Hall B		6: Large Hall A		7: Large Hall B
  8: Short Plate	9: Vocal Plate
  10: Mono Echo		11: Stereo Echo
  12: MonoEcho+Reverb	13: StereoEcho+Reverb
}
begin
  NB_TabsToReverbKnob;
  if ReverbKnob_old <> edit_ReverbKnob then
    // eigener Event für Reverb Level wäre sicher eleganter...
    MIDI_SendNRPN($3500, edit_SAMreverbPrgms[edit_ReverbKnob]); // SAM55004 _LiveMic_Effect_LoadProgram
  endif;
{$IFDEF DEBUG_DSP}
  Writeln(Serout, '/ FH Reverb Prg: ' + ByteToStr(edit_ReverbKnob));
{$ENDIF}
  if edit_ReverbKnob > 0 then
    i:= muldivByte(edit_ReverbLevels[edit_ReverbKnob - 1], edit_OverallReverb, 127);
    MIDI_SendNRPN($3502, i);   // SAM55004 RevInputLevel
    MIDI_SendNRPN($3505, edit_SAMreverbTimes[edit_ReverbKnob] + (i shr 2)); // SAM55004 RevTime
    if ReverbKnob_old <> edit_ReverbKnob then
      // eigener Event für Reverb Level wäre sicher eleganter...
      MIDI_SendNRPN($3503, edit_SAMreverbPreHP[edit_ReverbKnob]); // SAM55004 RevPreHP, $40 = 600 Hz, $7F =1,2kHz
      MIDI_SendNRPN($3504, edit_SAMreverbHdamp[edit_ReverbKnob]); // SAM55004 RevHDamp, $7F = max.
      MIDI_SendNRPN($3506, edit_SAMreverbToneGain[edit_ReverbKnob]); // SAM55004 RevToneGain, $40 = 0dB, $7F= +6dB
      MIDI_SendNRPN($3507, edit_SAMreverbToneFreq[edit_ReverbKnob]); // SAM55004 RevToneFreq, $00 = 800 Hz, $7F = 3kHz
    endif;
  endif;
  PREAMP_REV1:= edit_LogicalTab_Reverb1;
  PREAMP_REV2:= edit_LogicalTab_Reverb2;
  ReverbKnob_old:= edit_ReverbKnob;
end;

// ALLINONE
{$ELSE}
// NOT ALLINONE
procedure FH_SendModuleExtRotary;
begin
  m:= 0;
  if edit_LogicalTab_Reverb1 then
    Inc(m);
  endif;
  if edit_LogicalTab_Reverb2 then
    Inc(m, 2);
  endif;
  SendByteToFPGA(m, 69);  // External Rotary DABD3

end;
// *****************************************************************************
{$ENDIF}
// *****************************************************************************


// #############################################################################
// ###                           UPPER DRAWBARS                              ###
// #############################################################################

// ######################## Drawbar- und ADSR-Tools ############################

procedure drawbars_to_lc(var db_array: array[0..15] of byte;
                         const manual: byte);
// AutoInc-Register muss gesetzt sein
// In "bb_ena_env_adsrmode_bits" sind jene Bits auf '1',
// bei denen ein BUSBAR auf ADSR geschaltet ist.
// In "bb_ena_env_percmode_bits" sind jene Bits auf '1',
// bei denen zusätzlich der Sustain-Pegel vom normalen
// Fußlagen-Drawbar statt von ADSR-Sustain-Poti übernommen werden soll.
var
  my_fac_10, my_fac_11, my_fac_12, my_dbe_val  : byte;
  my_word                                      : word;
  is_eg_adsr, mute_db                          : boolean;
begin

{$IFNDEF MODULE}
  is_eg_adsr:= (manual = 0) and (bb_ena_env_adsrmode_bits <> 0)
               and (bb_ena_env_db_bits <> 0)
               and (edit_GatingKnob >= 2);
  if (manual = 0) and edit_LogicalTab_PercOn and (edit_GatingKnob = 0) then
    mute_db:= not (edit_LogicalTab_PercSoft or DisablePercussion);
  else
    mute_db:= false;
  endif;
{$ELSE}
  is_eg_adsr:= (manual = 0) and (bb_ena_env_adsrmode_bits <> 0)
               and (bb_ena_env_db_bits <> 0);
  if (manual = 0) and edit_LogicalTab_PercOn then
    mute_db:= not edit_LogicalTab_PercSoft;
  else
    mute_db:= false;
  endif;
{$ENDIF}

  FillBlock(@temp_db_levels, 16, 0);
  FillBlock(@temp_dbe_levels, 16, 0);

  // normale Zugriegel in Temp-Tabelle
  if manual = 2 then // Pedal?
    for i:= 0 to 8 do
      m:= db_array[i];
      temp_db_levels[i]:= muldivByte(m, edit_BusbarLevels[i], 127); // mal Busbar-Pegel
    endfor;
    temp_db_levels[15]:= temp_db_levels[0];
    temp_db_levels[0]:= 0;
  else
    for i:= 0 to 8 do
      m:= db_array[i];
      temp_db_levels[i]:= muldivByte(m, edit_BusbarLevels[i], 135); // mal Busbar-Pegel
      if is_eg_adsr then
        temp_dbe_levels[i]:= edit_UpperEnvelopeDBs[i];
      endif;
    endfor;
  endif;

  // 3 Pegelwerte in temp_db_levels zusammenstellen
  // Zugehörige Fußlagen ermitteln
  // Es kann ein Busbar jeweils nur EINEM Zugriegel zugeordnet werden,
  // ein Zugriegel kann aber Signale von mehreren Busbars erhalten
{$IFNDEF MODULE}
  if HasExtendedLicence and (edit_GatingKnob >= 1) then
{$ELSE}
  if HasExtendedLicence then
{$ENDIF}
    for i:= 0 to 5 do
      my_fac_10:= edit_DB10_MixtureSet[i];
      my_fac_11:= edit_DB11_MixtureSet[i];
      my_fac_12:= edit_DB12_MixtureSet[i];
      m:= 0;
      my_dbe_val:= 0;
      if my_fac_12 > 0 then
        m:= muldivByte(my_fac_12, db_array[11], 127);
        m:= muldivByte(m, edit_BusbarLevels[i + 9], 140);// mal Busbar-Pegel
        if is_eg_adsr then
          my_dbe_val:= muldivByte(my_fac_12, edit_UpperEnvelopeDBs[11], 128);
        endif;
      endif;

      if my_fac_11 > 0 then
        m:= muldivByte(my_fac_11, db_array[10], 127);
        m:= muldivByte(m, edit_BusbarLevels[i + 9], 140);// mal Busbar-Pegel
        if is_eg_adsr then
          my_dbe_val:= muldivByte(my_fac_11, edit_UpperEnvelopeDBs[10], 128);
        endif;

      endif;
      if my_fac_10 > 0 then
        m:= muldivByte(my_fac_10, db_array[9], 127);
        m:= muldivByte(m, edit_BusbarLevels[i + 9], 140);// mal Busbar-Pegel
        if is_eg_adsr then
          my_dbe_val:= muldivByte(my_fac_10, edit_UpperEnvelopeDBs[9], 128);
        endif;
      endif;
      temp_db_levels[i + 9]:= m;
      temp_dbe_levels[i + 9]:= my_dbe_val;
    endfor;
  endif;


  for i:= 0 to 15 do       // 16 Werte log. an LC senden
    m:= temp_db_levels[i];
    if is_eg_adsr and bit(bb_ena_env_percmode_bits, i) then  // soll auf Drawbar-Level?
      // nach Formel Sustain = DB / (P + 1) und V = DB * fac + P
      m:= c_DrawbarLogTable[m];
      // halbieren, weil doppelter Pegel durch gesetztes FULL_BIT
      FPGAsendByte:= m shr 1;

      m:= temp_dbe_levels[i];
      m:= c_DrawbarLogTable[m];
      FPGAsendByte:= FPGAsendByte + m;
    else
      FPGAsendByte:= c_DrawbarLogTable[m];
      if mute_db then
        // Drawbar-Pegelabsenkung bei Percussion gewünscht, nur Hammond
        FPGAsendByte:= muldivByte(FPGAsendByte, edit_PercMutedLvl, 127);
      endif;
    endif;
    SendFPGA8;
  endfor;
end;

// #############################################################################

procedure bb_adsr_to_fpga;
// ADSR-Arrays an FPGA senden
// sendet nacheinander 16 Attack-, 16 Decay-, 16 Sustain- und 16 Release-Werte
begin
  // Attack- und Decay-Values senden
  FI_AutoIncSetup(11);    // for Write Core 11, Upper ADSR
  for i:= 0 to 15 do
    FPGAsendWord:= c_TimeLogTable[bb_attack_arr[i]];
    SendFPGA16;
  endfor;
  for i:= 0 to 15 do
    FPGAsendWord:= c_TimeLogTable[bb_decay_arr[i]];
    SendFPGA16;
  endfor;
  // Sustain-Values senden
  Hi(FPGAsendWord):= 0;
  for i:= 0 to 15 do
    Lo(FPGAsendWord):= bb_sustain_arr[i] shl 1;
    SendFPGA16;
  endfor;
  // Release-Wert senden
  for i:= 0 to 15 do
    FPGAsendWord:= c_TimeLogTable[bb_release_arr[i]];
    SendFPGA16;
  endfor;
  FI_AutoIncReset(11);
end;

procedure adsr_to_bb_adsr;
// produziert 15 abfallende/ansteigende ADSR-Werte für Saiten-Simulation
// In "bb_ena_env_adsrmode_bits" sind jene Bits auf '1',
// bei denen ein BUSBAR auf ADSR geschaltet ist.
// In "bb_ena_env_percmode_bits" sind jene Bits auf '1',
// bei denen zusätzlich der Sustain-Pegel vom normalen
// Fußlagen-Drawbar statt von ADSR-Sustain-Poti übernommen werden soll.
// drawbars_to_lc muss ausgeführt sein!
var
  my_timefac, decay_harm, release_harm, sustain_harm,
  my_db_val, my_dbe_val, this_env_db: byte;
  attack, decay, sustain, release   : byte;
  env_db_int, attack_int, decay_int, release_int: integer;
begin
  // EG Mode, einige EG-Enables gesetzt
  my_timefac:= (edit_UpperADSRharmonics div 4) + 112; // Mitte 128

  decay_harm:= edit_UpperDecay;  // 0..127
  sustain_harm:= edit_UpperSustain;  // 0..127
  release_harm:= edit_UpperRelease;

  for i:= 0 to 15 do
    attack:= 0; // Default: sehr kurz
    decay:= 0;
    sustain:= 127;
    release:= 0;


    // EG ADSR aktiviert?
    if bit(bb_ena_env_adsrmode_bits, i) then
      attack:= edit_UpperAttack; // kein HARMONIC DECAY!
      decay:= decay_harm;
      sustain:= edit_UpperSustain;
      release:= release_harm;
    endif;

    // EG Percussion Mode aktiviert? Sustain-Wert ändern
    if bit(bb_ena_env_percmode_bits, i) then  // soll auf Drawbar-Level?
      attack:= 0;
      decay:= decay_harm;
      release:= release_harm;

      my_db_val:= temp_db_levels[i]; // umsortierte lineare Werte
      my_dbe_val:= temp_dbe_levels[i];
{$IFDEF DEBUG_FH}
      Writeln(Serout, '/ FH Sustain DB val:' + ByteToStr(my_db_val) + ' DBE val:' + ByteToStr(my_dbe_val));
{$ENDIF}

      // nach Formel S = DB / (P + 1) und V = DB + P
      sustain:= muldivByte(my_db_val, 127, my_dbe_val + 127);  // S = DB / (P + 1)
    endif;

    // EG TimeMod aktiviert?
    if bit(bb_ena_env_timemode_bits, i) then
      env_db_int:= integer(muldivByte(edit_UpperEnvelopeDBs[i], 75, 100));

      attack_int:= integer(edit_UpperAttack) + env_db_int; // kein HARMONIC DECAY!
      attack:= byte(valuetrimlimit(attack_int, 0, 127));

      decay_int:= integer(decay_harm) + env_db_int;
      decay:= byte(valuetrimlimit(decay_int, 0, 127));

      sustain:= edit_UpperSustain;

      release_int:= integer(release_harm) + env_db_int;
      release:= byte(valuetrimlimit(release_int, 0, 127));
    endif;

    // aktuell ermittelte Werte in Tabelle
    bb_attack_arr[i]:= attack;
    bb_decay_arr[i]:= decay;
    bb_sustain_arr[i]:= sustain;
    bb_release_arr[i]:= release;

    // HARMONIC DECAY, modifizierte Zeiten für obere Teiltöne
    decay_harm:= muldivByte(decay_harm, my_timefac, 128);
    decay_harm:= valuetrimlimit(decay_harm, 0, 127);
    release_harm:= muldivByte(release_harm, my_timefac, 128);
    release_harm:= valuetrimlimit(release_harm, 0, 127);
  endfor;
end;


procedure harp_sustain_to_bb_adsr;
begin
  // Decay-Value für Harp-Sustain-Fußlage 4' = BB 2
  bb_attack_arr[3]:= 0;
  bb_decay_arr[3]:= edit_H100harpSust;
  bb_sustain_arr[3]:= 40;  // Sustain-Value
  bb_release_arr[3]:= edit_H100harpSust;
end;

// #############################################################################

procedure FH_UpperDrawbarsToFPGA;
// Vorbereitete Parameter-Tabelle UPPER und Tabs an FPGA
// ADSR-Drawbars und bb_ena_words an FPGA
// In "bb_ena_env_adsrmode_bits" sind jene Bits auf '1',
// bei denen ein BUSBAR auf ADSR geschaltet ist.
// In "bb_ena_env_percmode_bits" sind jene Bits auf '1',
// bei denen zusätzlich der Sustain-Pegel vom normalen
// Fußlagen-Drawbar statt von ADSR-Sustain-Poti übernommen werden soll.
// benutzte LCs
// (6)=HP-Filter, (8)=DB Upper, (10)=DB Pedal, (11)= ADSR Upper, (12)=ADSR Lower, (13)=ADSR Pedal
begin
// Percussion ans FPGA, sofern nicht zweiter Zugriegelsatz
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Send Upper DB');
{$ENDIF}
  FI_AutoIncSetup(8);          // for Write Core 8, Upper DBs
  drawbars_to_lc(edit_UpperDBs, 0);
  FI_AutoIncReset(8);
  // Sustainpegel neu senden, ggf. H100 Harp Sustain
{$IFNDEF MODULE}
  if (edit_GatingKnob = 1) and edit_LogicalTab_H100_HarpSustain then
    harp_sustain_to_bb_adsr;  // nur BB 3 freigeschaltet
    bb_adsr_to_fpga;
  endif;
  if edit_GatingKnob > 1 then // alle EG Modes
    adsr_to_bb_adsr;
    bb_adsr_to_fpga;
  endif;
{$ELSE}
  if edit_LogicalTab_H100_HarpSustain then
    harp_sustain_to_bb_adsr;  // nur BB 3 freigeschaltet
  else
    adsr_to_bb_adsr;
  endif;
  bb_adsr_to_fpga;
{$ENDIF}
end;

// #############################################################################
// ###                 UPPER ADSR/PERCUSSION ROUTING                         ###
// #############################################################################

function mixtures_to_ena_byte(to_adsr_bits: byte): byte;
// liefert zugehörige Fußlagen-Bits nach Drawbar-Zählweise, oberes Byte
var
  my_fac_10, my_fac_11, my_fac_12, temp  : byte;
begin
  temp:= 0;
  for i:= 0 to 5 do       // 6 Werte ermitteln und Bits setzen
    if HasExtendedLicence then
      my_fac_10:= edit_DB10_MixtureSet[i];
      my_fac_11:= edit_DB11_MixtureSet[i];
      my_fac_12:= edit_DB12_MixtureSet[i];
    else
      my_fac_10:= 0;
      my_fac_11:= 0;
      my_fac_12:= 0;
    endif;
    // Es kann ein Busbar nur EINEM Zugriegel zugeordnet werden!
    if (my_fac_12 > 0) and bit(to_adsr_bits, 3) then
      Incl(temp, i + 1);
    endif;
    if (my_fac_11 > 0) and bit(to_adsr_bits, 2) then
      Incl(temp, i + 1);
    endif;
    if (my_fac_10 > 0) and bit(to_adsr_bits, 1) then
      Incl(temp, i + 1);
    endif;
  endfor;
  return(temp);
end;

function drawbar_ena_to_busbar_ena(const drawbar_ena: word): word;
var
  temp_word  : word;
begin
  Lo(temp_word):= Lo(drawbar_ena);
  m:= Hi(drawbar_ena);
  Hi(temp_word):= (m and 1) or mixtures_to_ena_byte(m);
  return(temp_word);
end;

// #############################################################################

procedure FH_RouteOrgan;
// Routing-Grundeinstellung anhand Tabs setzen

begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Route Organ');
{$ENDIF}

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

  edit_ena_env_full_bits:= 0;
  edit_ena_env_percmode_bits:= 0;
  edit_ena_env_adsrmode_bits:= 0;
  edit_ena_env_timemode_bits:= 0;
  edit_ena_env_db_bits:= 0;
  edit_env_to_dry_bits:= 0;

  // Default B3/H100-Percussion, EG-Bits OFF
  if edit_LogicalTab_PercOn and (not DisablePercussion) then
    // Standard-B3-Percussion
    if edit_LogicalTab_Perc3rd then
      edit_ena_cont_perc_bits:= $010; // Perc Select 3rd-Bit
    else
      edit_ena_cont_perc_bits:= $008; // Perc Select 2nd-Bit
    endif;
  else
    edit_ena_cont_perc_bits:= 0;
  endif;

  if (edit_GatingKnob = 0) then
    // B3/M100 Mode
    edit_ena_cont_bits:= $01FF;    // nur 9 Drawbars
    CurrentADSRmask:= 0;
  else
    CurrentADSRmask:= EC_LogicalTabs2Word(32) and $0FFF; // 12 ADSR Mask Bits
  endif;
  if HasExtendedLicence then
    if (edit_GatingKnob = 1) then
      // H100 Mode
      // ADSR Enables als Hammond-Percussion-Freigabe-Bits
      // keine Auswertung der 12 Perkussion-DBs
      edit_ena_cont_bits:= $0FFF;
      if edit_LogicalTab_H100_HarpSustain then
        // H100 HarpSustain: 4' zusätzlich auf ADSR, voller Pegel, Dry Channel
        edit_ena_env_full_bits:= $008;
        edit_env_to_dry_bits:= $008;
      endif;
    endif;

    if edit_LogicalTab_PercOn and (edit_GatingKnob <> 3) and (CurrentADSRmask <> 0) then
      // H100-Percussion bei H100 und EG mode
      edit_ena_cont_perc_bits:= CurrentADSRmask;
    endif;

    if (edit_GatingKnob >= 2) then
      // EG Mode:
      // ADSR Enables als EG-Freigabe-Bits
      // mit Auswertung der 12 Perkussion-DBs, Umrechnung auf Sustain
      edit_ena_cont_bits:= $000;    // mechanische Kontakte alle OFF
      edit_ena_env_db_bits:= $0FFF; // alle auf EG
      edit_ena_env_adsrmode_bits:= $0FFF;      // alle auf ADSR
      if edit_GatingKnob = 3 then
        edit_ena_env_percmode_bits:= $0FFF;
        edit_ena_env_full_bits:= $0FFF;
      endif;
      if edit_GatingKnob = 4 then
        edit_ena_env_timemode_bits:= $0FFF;
      endif;
      if edit_LogicalTab_EG_mask2dry then
        edit_env_to_dry_bits:= CurrentADSRmask;
      endif;
    endif;
  else
    // B3/M100 Mode
    edit_ena_cont_bits:= $01FF;    // nur 9 Drawbars
  endif;

// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************

  FH_UpperRoutingToFPGA; // auf BB umsetzen, ans FPGA schicken
  FH_InsertsToFPGA;
end;

procedure FH_PercOnOff;
begin
  // Default B3/H100-Percussion, EG-Bits OFF
{$IFNDEF MODULE}
  if edit_LogicalTab_PercOn and (not DisablePercussion) then
{$ELSE}
 if edit_LogicalTab_PercOn  then
{$ENDIF}
    // Standard-B3-Percussion
    if edit_LogicalTab_Perc3rd then
{$IFDEF DEBUG_FH}
      Writeln(Serout, '/ FH B3 Perc 3rd');
{$ENDIF}
      edit_ena_cont_perc_bits:= $010; // Perc Select 3rd-Bit
    else
{$IFDEF DEBUG_FH}
      Writeln(Serout, '/ FH B3 Perc 2ndd');
{$ENDIF}
      edit_ena_cont_perc_bits:= $008; // Perc Select 2nd-Bit
    endif;
  else
{$IFDEF DEBUG_FH}
    Writeln(Serout, '/ FH B3 Perc Off');
{$ENDIF}
    edit_ena_cont_perc_bits:= 0;
  endif;
  FH_RouteOrgan;
end;

procedure FH_UpperRoutingToFPGA;
// edit-Routing-Bits in beteiligte Fußlagen umrechnen und an FPGA senden
// bei Sempra direkte Änderungen über MIDI
// ena_cont_perc_bits     = 32, mit Bit 15 = PERC_BYPASS
// ENA_CONT_BITS     = 40, mechanische Kontakte für jede Fußlage
// ENA_ENV_DB_BITS   = 41, elektronische Kontakte für jede Fußlage
// ENA_ENV_FULL_BITS = 42, elektronische Kontakte für jede Fußlage
// ENV_TO_DRY_BITS   = 43, ADSR-Fußlagen auf Dry-Kanal
// bb_ena_env_percmode_bits (FW) = Sustain-Pegel Umrechnung in FW
// bb_ena_env_adsrmode_bits (FW) = ADSR statt AR-Envelope
// bb_ena_env_timemode_bits (FW) = Envelope-DBs sind A/D/R Time Modifier

// In "bb_ena_env_adsrmode_bits" sind jene Bits auf '1',
// bei denen ein BUSBAR auf ADSR geschaltet ist.
// In "fpge_ena_env_percmode_mode" sind jene Bits auf '1',
// bei denen zusätzlich der Sustain-Pegel vom normalen
// Fußlagen-Drawbar statt von ADSR-Sustain-Poti übernommen werden soll.

var
  idx: byte;
  cancel_1: boolean;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Send Routing');
{$ENDIF}
  // 1' abschalten wenn B3-Mode und Percussion ON
  cancel_1:= DisableDB1 and edit_LogicalTab_PercOn;

  // nur in FW benutzt:
  bb_ena_env_percmode_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_percmode_bits);
  bb_ena_env_adsrmode_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_adsrmode_bits);
  bb_ena_env_timemode_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_timemode_bits);
  bb_ena_cont_perc_bits:= drawbar_ena_to_busbar_ena(edit_ena_cont_perc_bits);


  bb_ena_cont_bits:= drawbar_ena_to_busbar_ena(edit_ena_cont_bits);      // FPGA SPI #40
  bb_ena_env_db_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_db_bits)   // FPGA SPI #41
                       and (not bb_ena_cont_bits);

 // 1" ausmaskieren wenn DisableDB1 gesetzt
{$IFNDEF MODULE}
  if cancel_1 then
    bb_ena_cont_bits:= bb_ena_cont_bits and $FEFF;
    // bb_ena_env_db_bits:= bb_ena_env_db_bits and $FEFF;
  endif;
{$ELSE}
  // für Böhm auch EG mode!
  if cancel_1 then
    bb_ena_cont_bits:= bb_ena_cont_bits and $FEFF;
    // bb_ena_env_adsrmode_bits:= bb_ena_env_adsrmode_bits and $FEFF;
    bb_ena_env_db_bits:= bb_ena_env_db_bits and $FEFF;  // FPGA SPI #41
  endif;
{$ENDIF}
  bb_ena_env_full_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_full_bits);
  bb_env_to_dry_bits:= drawbar_ena_to_busbar_ena(edit_env_to_dry_bits);  // FPGA SPI #43

  for idx:= 0 to 3 do
    SendWordToFPGA(bb_UpperRoutingWords[idx], idx + 40);  // Ena-Word-Reihenfolge wie im FPGA
  endfor;

  SendWordToFPGA(bb_ena_cont_perc_bits, 32);
{$IFDEF DEBUG_FH}
  Write(Serout, '/ FH contact_bits      =');
  NB_writeser_enabits(bb_ena_cont_bits);
  Write(Serout, '/ FH cont_perc_bits    =');
  NB_writeser_enabits(bb_ena_cont_perc_bits);
  Write(Serout, '/ FH env_percmode_bits =' );
  NB_writeser_enabits(bb_ena_env_percmode_bits);
  Write(Serout, '/ FH env_adsrmode_bits =' );
  NB_writeser_enabits(bb_ena_env_adsrmode_bits);
  Write(Serout, '/ FH ena_env_full_bits =' );
  NB_writeser_enabits(bb_ena_env_full_bits);
{$ENDIF}
end;


// #############################################################################
// ###                            B3 PERCUSSION                              ###
// #############################################################################

procedure FH_PercussionParamsToFPGA;
// für Advanced Routing und Hammond-Percussion
// Hammond-Percussion: Timing-Werte und Pegel an FPGA
var
  my_lvl, my_timerval, my_med_lvl  : word;
  ena_h100_perc                    : boolean;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Send Percussion Params');
{$ENDIF}

  my_lvl:= 0;
  if edit_LogicalTab_PercSoft then
    Lo(my_lvl):= edit_PercSoftLvl;
  else
    Lo(my_lvl):= edit_PercNormLvl;
  endif;
  my_timerval:= word(edit_PercPrecharge) shl 6;
  SendWordToFPGA(my_timerval, 38); // perc_precharge (Time)

  if edit_LogicalTab_PercFast then
    my_timerval:= c_TimeLogTable[edit_PercShortTm];
    my_timerval:= my_timerval div 8;
  else
    my_timerval:= c_TimeLogTable[edit_PercLongTm];
    my_timerval:= my_timerval div 8;
  endif;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

  // Bei H100 und EG Mode ist zusätzliche trockene Percussion möglich
  ena_h100_perc:= HasExtendedLicence and (edit_GatingKnob >= 1);

  if ena_h100_perc then  // H100, Perc-Level verringern
    if edit_LogicalTab_H100_2ndVoice then
      my_timerval:= 0; // Perc-Bypass durch extrem lange Decay-Zeit
      if edit_LogicalTab_PercSoft then
        Lo(my_lvl):= muldivByte(edit_H100_2ndVlvl, 60, 100);
      else
        Lo(my_lvl):= edit_H100_2ndVlvl;
      endif;
      //writeln(serout,'/ Send H100 2ndV Vol ' + IntToSTr(my_lvl));
    else
      // Gesetzte Bits in bb_ena_cont_perc_bits zählen und
      // Percussion Volume um so mehr verringern, sonst Übersteuerung
      m:= 0;
      my_med_lvl:= 0;
      for i:= 0 to 15 do
        if bit(bb_ena_cont_perc_bits, i) then
          Inc(m);
          my_med_lvl:= my_med_lvl + word(c_perc_bbfacs[i]);  // max. 1120
        endif;
      endfor;
      if m > 0 then
        my_med_lvl:= my_med_lvl div word(m);
        Lo(my_lvl):= muldivByte(Lo(my_lvl), c_perc_mute[m], 100);
        Lo(my_lvl):= muldivByte(Lo(my_lvl), Lo(my_med_lvl), 70);
      endif;
    endif;
  else
    Lo(my_lvl):= muldivByte(Lo(my_lvl), 160, 100);
  endif;

// **************************** ALLINONE****************************************
{$ELSE}
// ******************************MODULE*****************************************

  // Simple Version für Böhm, kein H100-Mode
  m:= 0;
  my_med_lvl:= 0;
  for i:= 0 to 15 do
    if bit(bb_ena_cont_perc_bits, i) then
      Inc(m);
      my_med_lvl:= my_med_lvl + word(c_perc_bbfacs[i]);  // max. 1120
    endif;
  endfor;
  if m > 0 then
    my_med_lvl:= my_med_lvl div word(m);  // Mittelwert eingeschalteter Pegel
    Lo(my_lvl):= muldivByte(Lo(my_lvl), c_perc_mute[m], 100);
    Lo(my_lvl):= muldivByte(Lo(my_lvl), Lo(my_med_lvl), 70);
  endif;

// ******************************MODULE*****************************************
{$ENDIF}
// *****************************************************************************

  if Lo(my_lvl) > 200 then
    Lo(my_lvl):= 200; // begrenzen, sonst Verzerrungen bei mehreren Noten
  endif;
  SendWordToFPGA(my_timerval, 39); // perc_decay
  SendWordToFPGA(my_lvl, 33); // perc_level
  // Routing-Bits werden durch erfolgte Änderungen an FPGA gesendet
end;


// #############################################################################
// ###                     LOWER ADSR und DRAWBARS                           ###
// #############################################################################

// benutzte LCs (6)=HP-Filter, (8)=DB Upper, (9)=DB Lower, (10)=DB Pedal,
//              (11)= ADSR Upper, (12)=ADSR Lower, (13)=ADSR Pedal

procedure scaled_lwrped_adsr_to_lc(var adsr_arr: array[0..7] of byte; const full_adsr: word);
// produziert 15 abfallende/ansteigende ADSR-Werte für Saiten-Simulation
// sendet nacheinander 16 Attack-, 16 Decay-, 16 Sustain- und 16 Release-Werte
var
  my_timefac, attack_val, decay_val, sustain_val, release_val  : byte;
begin

  my_timefac:= (adsr_arr[4] div 4) + 112; // Mitte 128
  // Attack-Values errechnen und senden
  attack_val:= adsr_arr[0];   // 0..127
  for i:= 0 to 15 do
    if bit(full_adsr, i) then
      m:= attack_val;
    else
      m:= 0;
    endif;
    FPGAsendWord:= c_TimeLogTable[m];
    SendFPGA16;
  endfor;
  // Decay-Values errechnen und senden
  decay_val:= adsr_arr[1];  // 0..127
  for i:= 0 to 15 do
    if i = 15 then
      decay_val:= adsr_arr[1];  // Pedal-BB
    endif;
    if bit(full_adsr, i) then
      m:= decay_val;
    else
      m:= 0;
    endif;
    FPGAsendWord:= c_TimeLogTable[m];
    // modifizierte Zeiten für obere Teiltöne
    decay_val:= muldivByte(decay_val, my_timefac, 128);
    decay_val:= valuetrimlimit(decay_val, 0, 127);
    // Decay-Wert in FPGAsendWord senden
    SendFPGA16;
  endfor;
  // Sustain-Values senden
  Hi(FPGAsendWord):= 0;
  sustain_val:= adsr_arr[2] shl 1;
  for i:= 0 to 15 do
    // Sustain-Wert in FPGAsendWord senden
    if bit(full_adsr, i) then
      m:= sustain_val;
    else
      m:= 255;
    endif;
    Lo(FPGAsendWord):= m;
    SendFPGA16;
  endfor;
  // Release-Values errechnen und senden
  release_val:= adsr_arr[3];  // 0..127
  for i:= 0 to 15 do
    if i = 15 then
      release_val:= adsr_arr[3];  // Pedal-BB
    endif;
    if bit(full_adsr, i) then
      m:= release_val;
    else
      m:= 0;
    endif;
    FPGAsendWord:= c_TimeLogTable[m];
    // modifizierte Zeiten für obere Teiltöne
    release_val:= muldivByte(release_val, my_timefac, 128);
    release_val:= valuetrimlimit(release_val, 0, 127);
    // Decay-Wert in FPGAsendWord senden
    SendFPGA16;
  endfor;
end;


procedure FH_LowerDrawbarsToFPGA;
// 9 + 6 skalierte Drawbar-Werte Lower an FPGA
var
  my_word  : word;
begin
  FI_AutoIncSetup(9);         // for Write Core 9, Lower DB
  drawbars_to_lc(edit_LowerDBs, 1);
  FI_AutoIncReset(9);
  if HasExtendedLicence then
    if edit_GatingKnob > 1 then // alle EG Modes
      my_word:= drawbar_ena_to_busbar_ena(EC_LogicalTabs2Word(48));
      SendWordToFPGA($0FFF, 44); // ADSR enables, all ON
      FI_AutoIncSetup(12);    // for Write Core 12, Lower ADSR
      scaled_lwrped_adsr_to_lc(edit_LowerADSR, my_word); // Busbars auf ADSR statt A--D
      FI_AutoIncReset(12);
    else
      SendWordToFPGA(0, 44); // ADSR enables, all OFF
    endif;
  else
    SendWordToFPGA(0, 44); // ADSR enables, all OFF
  endif;
end;

// #############################################################################
// ###                     PEDAL ADSR und DRAWBARS                           ###
// #############################################################################

// benutzte LCs (6)=HP-Filter, (8)=DB Upper, (9)=DB Lower, (10)=DB Pedal,
//              (11)= ADSR Upper, (12)=ADSR Lower, (13)=ADSR Pedal

procedure convert_pedal2;
// 2 Hammond B3-Drawbars auf 12 umsetzen
var
  my_dbval  : byte;
begin
  for i:= 0 to 11 do
    edit_PedalDBs[i]:= muldivByte(edit_PedalDB_B3_16, eep_Pedal4DBfacs16[i], 127);
  endfor;

  for i:= 2 to 11 do
    m:= edit_PedalDBs[i] + muldivByte(edit_PedalDB_B3_8, eep_Pedal4DBfacs8[i], 127);
    if m > 127 then
      m:= 127;
    endif;
    edit_PedalDBs[i]:= m;
  endfor;
end;

procedure convert_pedal4;
// 4 Hammond H100-Drawbars auf 12 umsetzen
begin
  for i:= 0 to 11 do
    m:= muldivByte(edit_PedalDB_B3_16, eep_Pedal4DBfacs16[i], 127)
        + muldivByte(edit_PedalDB_B3_16H, eep_Pedal4DBfacs16H[i], 127);
    if m > 127 then
      m:= 127;
    endif;
    edit_PedalDBs[i]:= m;
  endfor;

  for i:= 2 to 11 do
    m:= muldivByte(edit_PedalDB_B3_8, eep_Pedal4DBfacs8[i], 127)
        + muldivByte(edit_PedalDB_B3_8H, eep_Pedal4DBfacs8H[i], 127);
    if m > 127 then
      m:= 127;
    endif;
    m:= edit_PedalDBs[i] + m;
    if m > 127 then
      m:= 127;
    endif;
    edit_PedalDBs[i]:= m;
  endfor;
end;

// #############################################################################

procedure FH_PedalDrawbarsToFPGA;
// Vorbereitete Parameter-Tabelle BASS für HX3-Engine an FPGA
// benutzte LCs (6)=HP-Filter, (8)=DB Upper, (10)=DB Pedal, (11)= ADSR Upper, (12)=ADSR Lower, (13)=ADSR Pedal
begin
// Pedal-Bass-Drawbar ans FPGA
  if edit_PedalDBsetup = 0 then
    convert_pedal2;
  elsif edit_PedalDBsetup = 1 then
    convert_pedal4;
  endif;
  FI_AutoIncSetup(10);       // for Write Core 10, Pedal DB
  drawbars_to_lc(edit_PedalDBs, 2);
  FI_AutoIncReset(10);
  // ADSR-Params bei Pedal immer
  FI_AutoIncSetup(13);       // for Write Core 13, Pedal ADRS
  scaled_lwrped_adsr_to_lc(edit_PedalADSR, $FFFF);
  FI_AutoIncReset(13);
end;

// #############################################################################
// ###                   FPGA HIGH-LEVEL-FUNKTIONEN                          ###
// #############################################################################

procedure FH_InsertsToFPGA;
var ena_dac_swap: Boolean;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Inserts to FPGA');
{$ENDIF}
  InsertVibratoUpper:= edit_LogicalTab_VibOnUpper;
  InsertVibratoLower:= edit_LogicalTab_VibOnLower;
  if HasExtendedLicence then
    InsertPhasingUpper:= edit_LogicalTab_PHRupperOn;
    InsertPhasingLower:= edit_LogicalTab_PHRlowerOn;
  endif;
  InsertTubeAmp:= not edit_LogicalTab_TubeAmpBypass;
  InsertRotarySpkr:= not edit_LogicalTab_RotarySpkrBypass;
  // InsertADSRtoPerc:= edit_LogicalTab_H100_2ndVoice;
  ena_dac_swap:= Bit(edit_ConfBits2, 6) and edit_LogicalTab_RotarySpkrBypass;
  InsertPedalPostMix:= (edit_LogicalTab_PedalPostMix and (not Bit(edit_ConfBits, 3))) or ena_dac_swap;
  // entspricht jetzt Bit-Folge im FPGA Register 66
  SendByteToFPGA(Inserts, 66);  // Insert Change
  SendByteToFPGA(byte(ena_dac_swap), 64);  // Swap DACs, Bit 0

{$IFNDEF MODULE}
  MIDI_SendNRPN($350E, byte(edit_LogicalTab_EqualizerBypass)); // Equalizer freischalten
{$ENDIF}
end;

// #############################################################################

procedure FH_SplitConfigToFPGA;
// Splitmode setzen:
// 0 = PedalToLower, 1 = LowerToUpper
// 2 = PedalToUpper, 3 = LowerToUpper + 1 Oktave
// 4 = LowerToUpper +2 Oktaven
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Split mode to FPGA: ' + ByteToStr(edit_SplitMode));
  Writeln(Serout, '/ FH Split Point to FPGA: ' + ByteToStr(edit_SplitPoint));
{$ENDIF}
  // Werte an Scan Driver
  SendByteToFPGA(edit_GenTranspose, 10);  // Generator Transpose, +1 = 1 Halbton nach oben
  SendByteToFPGA(edit_KeyTranspose, 13);  // positive Werte verschieben Töne nach UNTEN!
  SendByteToFPGA(edit_LocalEnable xor 7, 14);   // ScanCore SPI Local Disables
  SendByteToFPGA(edit_SplitMode, 6);   // Splitmode
  SendByteToFPGA(edit_SplitPoint, 8);  // Splitpunkt

  if ForceSplitRequest and edit_LogicalTab_SplitOn then
    // Scan/Split erstmal OFF, damit Änderungen beim Wiedereinschalten übernommen werden
{$IFDEF DEBUG_FH}
    Writeln(Serout, '/ FH New Split Request');
{$ENDIF}
    SendByteToFPGA(0, 7);
    mdelay(3);
    SendByteToFPGA(2, 7);    // Tastatur-Split-Request-Flag, Tastatur auswerten
    mdelay(3);
    ForceSplitRequest:= false;
  endif;
  m:= (byte(edit_LogicalTab_SplitOn) and 1)          // Bit 0
      or (byte(edit_LogicalTab_Shift_upper) and 16)   // Bit 4
      or (byte(edit_LogicalTab_Shift_lower) and 32);  // Bit 5
  SendByteToFPGA(m, 7); // Split ON Register
end;

// #############################################################################

procedure FH_OrganParamsToFPGA;
// Edit-Tabelle Orgel an FPGA, Kanal und Freigabe an SAM5504
// nur übertragen, wenn im Menü geändert
begin
// Achtung: Throb Position wird auf 4 gelesen, edit_MIDI_Channel auf SPI 4 muss
// deshalb in AC_SendSwell ebenfalls gesendet werden!
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Organ params to FPGA');
{$ENDIF}
  m:= edit_MIDI_Channel;
  SendByteToFPGA(m, 4); // MIDI-Channel
// MIDI_OUT_SEL: 0 = MIDI_TX_1, 1 = MIDI_IN_1, 2 = MIDI_IN_2, 3 = MIDI_FROM_SAM (USB)
{$IFNDEF MODULE}
  MIDI_SendSustainSostEnable;
  SendByteToFPGA(m, 9);
{$ENDIF}

  m:= (edit_ContSpringFlx shl 4) or (edit_ContSpringDmp and 15);
  SendByteToFPGA(m, 9);          // Klick-Länge und Noise-Frequenz
  // Transpose, positive Werte verschieben Töne nach UNTEN!
  SendByteToFPGA(edit_GenTranspose, 10);  // MIDI IN/Generator Transpose
  SendByteToFPGA(edit_KeyTranspose, 13);  // nur MIDI OUT eigene Tastatur
{$IFNDEF MODULE}
  // Fatar Key Velocity Faktor (1/t-Steilheit)
  m:= byte(edit_EarlyKeyCont) and 1; // für FATAR Scancore
  m:= m or (edit_FatarVelocityFac shl 2);
  SendByteToFPGA(m, 11);         // TWG Config1  EARLY_KEY
{$ENDIF}
  m:= c_TuningTable[edit_TG_tuning];
  SendByteToFPGA(m, 68);  // CycleSteal-Wert -125 .. +125

{$IFNDEF MODULE}
  if edit_GatingKnob <= 1 then
    m:= (edit_TG_Flutter and %00001111) or (edit_TG_Leakage shl 4);
  else
    // Leakage abschalten bei EG-Modes - keine Plopp-Filter!
    m:= (edit_TG_Flutter and %00001111);
  endif;
{$ELSE}
  m:= (edit_TG_Flutter and %00001111) or (edit_TG_Leakage shl 4);
{$ENDIF}
  SendByteToFPGA(m, 67);  //
  SendByteToFPGA(0, 64);  // kein Swap DAC
end;

// #############################################################################

procedure FH_LicenceToFPGA;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Licences to FPGA');
{$ENDIF}
  ValueLong:= ReceiveFPGA(240); // hier nur DNA-Auslese-Trigger
  ValueLong:= EE_DNA_0 and $FFFFFF;  // Freischaltcode Organ, sofern gesetzt
  SendLongToFPGA(ValueLong, 240);
  ValueLong:= EE_DNA_1 and $FFFFFF;  // Freischaltcode Extended, sofern gesetzt
  SendLongToFPGA(ValueLong, 241);
end;

// #############################################################################
// ###                    SETUP  SINUS-GENERATOR                             ###
// #############################################################################

// Für jede Oktave des Generators muss eine eigene, 1024 Worte lange Wellenform
// geladen werden. Höhere Oktaven dürfen wg. Nyquist-Grenze keine Oberwellen
// jenseits 20 kHz enthalten.
// Wg. Nicht-Hörbarkeit der Oberwellen werden Oktaven 6 bis 8 (9) grundsätzlich
// nur als Sinus abgelegt.


procedure FH_WaveBlocksToFPGA;
// vorgefertigte Blocks (8 pro Set) mit Nummer edit_TG_WaveSet
// aus DF laden und an AutoInc-Reg senden
// 8 WaveSets im DF fortlaufend gespeichert: 1 KWorte pro Oktave,
// 8 KWorte pro Set = 16 KByte
// 32 KWorte insgesamt

var
  idx_b  : byte;
  idx_w, waveset_block: word;
begin
  waveset_block:= word((edit_TG_WaveSet) * 4) + c_waveset_base_DF;
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH TG WaveSet #' + ByteToStr((edit_TG_WaveSet))
          + ' from DF block #' + IntToStr(waveset_block) + ' to FPGA (4)');
{$ENDIF}

  FI_AutoIncSetup(4); // for Write Core 4 = Wave ROM in dds48
  for idx_b:= 0 to 3 do       // 4 * 4096 Bytes = 16 KBytes = 8 KWorte
    DF_readblock(waveset_block, 4096); // 4 KByte lesen, 2 KWorte!
    for idx_w:= 0 to 2047 do
      // je Block 2048 Integer-Werte 12 Bit breit, 2 Oktaven
      FPGAsendWord:= Blockarray_w[idx_w];
      SendFPGA16;
    endfor;
    Inc(waveset_block);
  endfor;
  FI_AutoIncReset(4);
end;


// #############################################################################
// ###                     SETUP  KEYMAPPING-TABELLE                         ###
// #############################################################################

procedure FH_KeymapToFPGA64(my_startnote: byte; var my_generator_size: byte;
                            var do_high_foldback: boolean);
// 1024 Keymap-Werte 8 Bit breit an FPGA DDS48 übertragen
begin
  for i:= 0 to 63 do
    FPGAsendByte:= my_startnote;
    SendFPGA8;
    Inc(my_startnote);
    if my_startnote >= my_generator_size then
      if do_high_foldback then
        my_startnote:= my_startnote - 12;
      else
        my_startnote:= 127;   // Rest abgeschaltet
      endif;
    endif;
  endfor;
end;

procedure FH_KeymapToFPGA;
// 1024 Keymap-Werte 8 Bit breit an FPGA DDS48 übertragen
var
  busbar  : byte;
begin
{$IFDEF DEBUG_FH}
  Write(Serout, '/ FH TG Keymap to FPGA (3), TG size '
        + ByteToStr(edit_TG_Size) + ', HiFbk ');
  if edit_HighFoldbackOn then
    Writeln(Serout, 'ON');
  else
    Writeln(Serout, 'OFF');
  endif;
{$ENDIF}

  FI_AutoIncSetup(3); // for Write Core 3, Keymap
  for busbar:= 0 to 15 do
    FH_KeymapToFPGA64(edit_BusBarNoteOffsets[busbar], edit_TG_Size,
                      edit_HighFoldbackOn);
  endfor;
  FI_AutoIncReset(3);
end;

procedure highpassfilter_to_fpga64(my_startnote: byte;
                                   var my_generator_size: byte);
// 64 Highpass-Filter-Werte 16 Bit breit an FPGA übertragen
begin
  for i:= 0 to 63 do
    FPGAsendWord:= muldivInt(c_HighpassFilterArray[my_startnote], word(edit_TG_FilterFac), 64);
    SendFPGA16;
    Inc(my_startnote);
    if my_startnote >= my_generator_size then
      my_startnote:= my_startnote - 12;
    endif;
  endfor;
end;

procedure FH_NoteHighpassFilterToFPGA;
// 1024 Highpass-Filter-Werte an FPGA übertragen
var
  busbar   : byte;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH LC Filters to FPGA (6), TG size '
          + ByteToStr(edit_TG_Size));
{$ENDIF}
  FI_AutoIncSetup(6); // for Write Core 6 = RC Filter Facs in FPGA, tg_manuals_ng
  for busbar:= 0 to 15 do
    highpassfilter_to_fpga64(edit_BusBarNoteOffsets[busbar], edit_TG_Size);
  endfor;
  FI_AutoIncReset(6);
end;

procedure FH_TubeCurveToFPGA(const tube_set_a, tube_set_b: byte);
// 256 Step- und 256 Slope-Werte für interpolierenden TubeAmp HX4.0
var
  stepval, slopeval: Integer;
begin
  // Werte für LC vorbereiten aus Slope-Tabelle
  stepval:= 0;
  for i:= 0 to 31 do
    slopeval:= c_tubeampslopes[tube_set_a, i];
    SlopeArray[i]:= slopeval;
    StepArray[i]:= stepval;
    stepval:= stepval + slopeval;  // nächste Stufe um slope höher
  endfor;
  stepval:= StepArray[31];
  for i:= 32 to 127 do
    SlopeArray[i]:= 0; // letzter Wert immer 0
    StepArray[i]:= stepval;
  endfor;

  // negative Werte, rückwärts
  stepval:= 0;
  for i:= 255 downto 224 do
    slopeval:= c_tubeampslopes[tube_set_b, 255-i];
    SlopeArray[i]:= slopeval;
    StepArray[i]:= stepval;
    stepval:= stepval - slopeval;  // nächste Stufe um slope kleiner
  endfor;
  stepval:= StepArray[224];
  for i:= 223 downto 128 do
    SlopeArray[i]:= 0; // letzter Wert immer 0
    StepArray[i]:= stepval;
  endfor;

  FI_AutoIncSetup(7); // for Write Core 7 = Tube Amp StepVals/Slopes, 512 Werte
  for stepval:= 0 to 511 do
    FPGASendWord:= Word(StepSlopeArray[stepval]);
    SendFPGA16;
  endfor;
  FI_AutoIncReset(7);
end;

procedure FH_TuningValsToFPGA;
// 95 Tuning-Werte 16 Bit breit an FPGA DDS96 übertragen
// Generator dds96 arbeitet mit Vorteilern 1..128 pro Oktave, deshalb gleiche Werte
// für jede Oktave. Lediglich oberste Hammond-Oktave ist etws gespreizt, deshalb extra.
var
  my_random_limit, my_random_word  : word;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH TG tuning set #' + ByteToStr(edit_TG_TuningSet) + ' to FPGA (5)');
{$ENDIF}
  FI_AutoIncSetup(5); // for Write Core 5, Tuning Vals
  if edit_TG_TuningSet = 0 then
    for m:= 0 to 6 do
      for i:= 0 to 11 do
        FPGAsendWord:= c_TuningArrayHammond[i];
        SendFPGA16;
      endfor;
    endfor;
    for i:= 0 to 11 do
      FPGAsendWord:= c_TuningArrayHammondSpread[i];
      SendFPGA16;
    endfor;
  else
    my_random_limit:= 1;
    if edit_TG_TuningSet = 2 then
      my_random_limit:= 4;
    endif;
    if edit_TG_TuningSet = 3 then
      my_random_limit:= 8;
    endif;
    for m:= 0 to 7 do
      for i:= 0 to 11 do
        FPGAsendWord:= c_TuningArrayEven[i];
        if edit_TG_TuningSet > 1 then
          my_random_word:= RandomRange(0, my_random_limit);
          if even(my_random_word) then
            FPGAsendWord:= FPGAsendWord + my_random_word;
          else
            FPGAsendWord:= FPGAsendWord - my_random_word;
          endif;
        endif;
        SendFPGA16;
      endfor;
    endfor;
  endif;
  FI_AutoIncReset(5);
  m:= c_TuningTable[edit_TG_tuning];
  SendByteToFPGA(m, 68);  // CycleSteal-Wert -125 .. +125
end;

procedure FH_TaperingToFPGA(const taper_set: byte);
var fixed_taperval: Byte;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Tapering set #' + ByteToStr(taper_set) + ' to FPGA (1)');
{$ENDIF}
  if taper_set <= 3 then
    // Taper-Sets aus DF
    DF_SendToAutoinc(c_taper_base_DF + Word(taper_set), 1, 4096);  // Target Tapering (+11)
  else
    // Errechnete oder konstante Taper-Werte für Nicht-Hammonds
    FI_AutoIncSetup(1); // for Write Core 1 = Tapering
    FPGAsendLong:= 0;
    for i:= 0 to 15 do
      case taper_set of
// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************
        4: // linear
           for m:= 0 to 63 do
             FPGAsendLong0:= edit_TG_FixedTaperVal;
             SendFPGA32;  // 3 Bytes unbenutzt, aber für Tapering Editor gebraucht!
           endfor;
         |
        5: // higher DB enhanced
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 85, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + (i * 3);
             SendFPGA32;
           endfor;
         |
        6: // Brilliant
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 80, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + (m shr 2) + (i * 4);
             SendFPGA32;
           endfor;
         |
        7: // Sharp
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 75, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + muldivByte(i + 1, m + 1, 16) + (i * 4);
             SendFPGA32;
           endfor;
         |
// **************************** ALLINONE****************************************
{$ELSE}
// ******************************MODULE*****************************************
        4: // linear
           FPGAsendLong0:= mulDivByte(edit_TG_FixedTaperVal, 125, 100);
           for m:= 0 to 63 do
             SendFPGA32;  // 3 Bytes unbenutzt, aber für Tapering Editor gebraucht!
           endfor;
         |
         5: // higher DB enhanced
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 125, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + (i * 3);
             SendFPGA32;
           endfor;
         |
        6: // Brilliant
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 125, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + (m shr 1) + (i * 3);
             SendFPGA32;
           endfor;
         |
        7: // Sharp
           fixed_taperval:= mulDivByte(edit_TG_FixedTaperVal, 125, 100);
           for m:= 0 to 63 do
             FPGAsendLong0:= fixed_taperval + muldivByte(i + 1, m + 1, 20) + (i * 3);
             SendFPGA32;
           endfor;
         |
// ******************************MODULE*****************************************
{$ENDIF}
// *****************************************************************************
      endcase;
    endfor;
    FI_AutoIncReset(1);
  endif;

// erste 12 Tapering- und Keymap-Werte 8 Bit breit nochmal an FPGA übertragen
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH DB16 Foldb/Keymap to FPGA');
{$ENDIF}
  m:= edit_TG_First16TaperVal;  // fester Pegel
  if (edit_DB16_FoldbMode and 2) = 2 then  // muted, früher TWG Config0
    // Full muted oder Foldback muted, früher TWG Config0
    m:= muldivByte(m, 50, 100);
  endif;
  FI_AutoIncSetup(1); // for Write Core 1 = Tapering BRAM, 12 Werte neu
  for i:= 0 to 11 do
    FPGAsendByte:= m;
    SendFPGA8;
  endfor;
  FI_AutoIncReset(1);

  m:= edit_BusBarNoteOffsets[0];
  if (edit_DB16_FoldbMode and 1) = 0 then
    // Foldback oder Foldback muted, früher TWG Config0
    Inc(m, 12);
  endif;
  FI_AutoIncSetup(3); // for Write Core 3 = Keymap BRAM
  for i:= 0 to 11 do
    FPGAsendByte:= m;
    SendFPGA8;
    Inc(m);
  endfor;
  FI_AutoIncReset(3);
end;

// #############################################################################

procedure FH_PhasingRotorToFPGA;
var
  temp_level_w  : word;
  temp_level    : byte;
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ FH Phasing Rotor params to FPGA');
{$ENDIF}
  // Register 0 und 9 nicht nenutzt
  // Register 1 wird mit FH_UpdatePHRspeed aktualisiert

  CopyBlock(@edit_PhasingGroup, @fpga_PhasingGroup, 16);
  // Gesamtpegel berechnen
  temp_level_w:= 0;
  for i:= 4 to 7 do
    temp_level_w:= temp_level_w + word(edit_PhasingGroup[i]);
  endfor;
  temp_level_w:= temp_level_w div 4;
  temp_level:= Lo(temp_level_w);

  // Defaultwerte für FPGA ggf modifizieren

  // Nur DEEP
  if edit_LogicalTab_PHR_Deep and (not edit_LogicalTab_PHR_Weak) then
    fpga_PHR_Feedback:= muldivByte(edit_PHR_Feedback, 130, 100);
    // je zwei Modulationsfaktoren anheben
    fpga_PHR_ModVariPh1:= muldivByte(edit_PHR_ModVariPh1, 125, 100);
    fpga_PHR_ModVariPh2:= muldivByte(edit_PHR_ModVariPh2, 120, 100);
    fpga_PHR_ModSlowPh1:= muldivByte(edit_PHR_ModSlowPh1, 120, 100);
    fpga_PHR_ModSlowPh2:= muldivByte(edit_PHR_ModSlowPh2, 120, 100);
    fpga_PHR_FeedBackInvert:= edit_PHR_FeedBackInvert or $00000010; // Filter
    // Wet-Level vergrößern
    for i:= 4 to 6 do
      fpga_PhasingGroup[i]:= muldivByte(edit_PhasingGroup[i], 105, 100);
    endfor;
    // Dry-Level verkleinern
    fpga_PHR_LevelDry:= muldivByte(edit_PHR_LevelDry, 40, 100);

  // Nur WEAK
  elsif (not edit_LogicalTab_PHR_Deep) and edit_LogicalTab_PHR_Weak then
    fpga_PHR_Feedback:= muldivByte(edit_PHR_Feedback, 75, 100);
    // je zwei Modulationsfaktoren verkleinern
    fpga_PHR_ModVariPh1:= muldivByte(edit_PHR_ModVariPh1, 80, 100);
    fpga_PHR_ModVariPh2:= muldivByte(edit_PHR_ModVariPh2, 75, 100);
    fpga_PHR_ModSlowPh1:= muldivByte(edit_PHR_ModSlowPh1, 75, 100);
    fpga_PHR_ModSlowPh2:= muldivByte(edit_PHR_ModSlowPh2, 75, 100);
    // fpga_PHR_FeedBackInvert:= edit_PHR_FeedBackInvert or $00000010; // Filter
    // Wet- und DryLevel neu berechnen
    for i:= 4 to 6 do
      fpga_PhasingGroup[i]:= muldivByte(edit_PhasingGroup[i], temp_level, 120);
    endfor;
    fpga_PHR_LevelDry:= muldivByte(temp_level, 160, 100);

  // DEEP und WEAK
  elsif edit_LogicalTab_PHR_Deep and edit_LogicalTab_PHR_Weak then
    fpga_PHR_Feedback:= muldivByte(edit_PHR_Feedback, 130, 100);
    // je zwei Modulationsfaktoren anheben
    fpga_PHR_ModVariPh1:= muldivByte(edit_PHR_ModVariPh1, 125, 100);
    fpga_PHR_ModVariPh2:= muldivByte(edit_PHR_ModVariPh2, 120, 100);
    fpga_PHR_ModSlowPh1:= muldivByte(edit_PHR_ModSlowPh1, 120, 100);
    fpga_PHR_ModSlowPh2:= muldivByte(edit_PHR_ModSlowPh2, 120, 100);
    // fpga_PHR_FeedBackInvert:= edit_PHR_FeedBackInvert or $00000010; // Filter
    // Wet- und DryLevel neu berechnen
    for i:= 4 to 6 do
      fpga_PhasingGroup[i]:= muldivByte(edit_PhasingGroup[i], 80, 100);
    endfor;
    // Dry-Level verkleinern
    fpga_PHR_LevelDry:= 130;

  endif;

  // Wenn kein FB Invert, FB Level zurücknehmen
{$IFNDEF MODULE}
  if not bit(fpga_PHR_FeedBackInvert, 3) then
    fpga_PHR_Feedback:= fpga_PHR_Feedback shr 1;
  endif;
{$ENDIF}
  for i:= 2 to 15 do
    SendByteToFPGA(fpga_PhasingGroup[i], 112 + i);
  endfor;
end;

procedure FH_UpdatePHRspeed;
begin
  if edit_LogicalTab_PHR_Fast then
    PhasingDestSpeed:= edit_PHR_SpeedVariFast;
  else
    PhasingDestSpeed:= edit_PHR_SpeedVariSlow;
  endif;
  if isSystimerzero(PhasingTimer) then
    m:= 1;
    if PhasingSpeed < PhasingDestSpeed then
      Inc(PhasingSpeed);
      if edit_LogicalTab_PHR_Delay then
        m:= edit_PHR_RampDelay;
      endif;
    endif;
    if PhasingSpeed > PhasingDestSpeed then
      Dec(PhasingSpeed);
      if edit_LogicalTab_PHR_Delay then
        m:= edit_PHR_RampDelay shr 1;
      endif;
    endif;
    setSysTimer(PhasingTimer, m);
    SendByteToFPGA(PhasingSpeed, 113);
  endif;
end;

// #############################################################################


procedure FH_VibratoToFPGA;
var
  my_fm, my_am: byte;
begin
  // Interpolierte Vibrato-Linebox, andere FPGA-Register
  // 160 bis 174: Delay-Taps
  m:= edit_VibKnob shr 1;
  my_fm:= edit_VibMods[m];
  my_am:= muldivByte(edit_VibChLineAgeAM, m + 3, 5); // 3/5, 4/5 und 5/5

  if (bit(edit_VibKnob, 0)) then  // Chorus-Stellungen
{$IFNDEF MODULE}
    my_fm:= muldivByte(my_fm, (edit_ChorusEnhance shr 2) + 50, 50);  // Allinone
{$ELSE}
    my_fm:= muldivByte(my_fm, (edit_ChorusEnhance shr 3) + 40, 50);  // Modul
{$ENDIF}
    m:= muldivByte(edit_VibChPreEmphasis, 65, 100) + 15;
  else
    m:= muldivByte(edit_VibChPreEmphasis, 97, 127) + 30;
  endif;
  SendDoubledByteToFPGA(m, 144);   // #1320

  my_fm:= valueTrimLimit(my_fm, 0, 115);
  my_am:= valueTrimLimit(my_am, 0, 127);

  SendDoubledByteToFPGA(my_am, 145);                 // #1321 Level AM

  for i:= 0 to 14 do   // 15 ansteigende Verzögerungszeiten berechnen
    m:= muldivByte(my_fm, i, 28) + 1;   //  49 = 1 ms = V3
    SendByteToFPGA(m, 160 + i);
  endfor;


  m:= muldivByte(edit_SegmentFlutter, m, 127);
  SendDoubledByteToFPGA(m, 153);   // #1333 Vib Segment Flutter, Anteil Emphasis
  SendDoubledByteToFPGA(edit_PreemphCutoff, 154);

  m:= edit_PreemphPhase;
  if Bit(edit_PreemphPhase, 5) then
    Excl(m, 4);
  endif;
  SendByteToFPGA(m, 155);

  SendDoubledByteToFPGA(edit_VibChFeedback, 146);    // #1322 Feedback
  SendDoubledByteToFPGA(edit_VibChReflection, 147);  // #1323
{$IFNDEF MODULE}
  SendDoubledByteToFPGA(edit_VibChRespCutoff, 148);  // #1324 Filter Offset
{$ELSE}
  // LC Cutoff Frequ begrenzen
  my_am:= (edit_VibChLineAgeAM div 2) + 5;
  m:= ValueTrimLimit(edit_VibChRespCutoff, my_am, 127);
  SendDoubledByteToFPGA(m, 148);  // #1324 Filter Offset
{$ENDIF}

  SendDoubledByteToFPGA(edit_PhaseLk_Shelving, 149); // #1325 Phase Lk
  SendByteToFPGA(150 - edit_ScannerGearing, 150);    // #1326 Vibrato-Frequenz umdrehen

  if (bit(edit_VibKnob, 0)) then
    // Chorus-Werte, param * scale div 100
{$IFNDEF MODULE}
    SendDoubledByteToFPGA(edit_ChorusBypassLevel, 151);  // #1327 Dry
{$ELSE}
    SendDoubledByteToFPGA(edit_ChorusBypassLevel + 25, 151);  // #1327 Dry anheben
{$ENDIF}
    SendDoubledByteToFPGA(edit_ChorusScannerLevel, 152); // #1328 Wet
  else
    // Vibrato-Werte
    SendByteToFPGA(0, 151);    // Dry auf 0
    SendDoubledByteToFPGA(125, 152);             // Wet auf Max
  endif;
  FH_InsertsToFPGA;
end;

procedure FH_UpdateLeslieSpeed;
begin
// Achtung: Throb Position wird auf SPI 4 gelesen, edit_MIDI_Channel auf SPI 4 muss
// deshalb in AC_SendSwell gleichzeitig gesendet werden!
  FPGAsendLong0:= edit_MIDI_Channel;
  ReceiveFPGA(4); // Throb Position Register 4
// LLLL RRRR BBBB, je obere vier Bits Throb-Signale Horn L/R und Bass
// aufgeteilt auf drei einzelne Bytes
  SpeedBlinkToggle:= (FPGAreceiveLong2 and %00001100) = 0;

  if edit_LogicalTab_LeslieRun then
    // Motoren laufen, gewünschte Geschwindigkeiten annähern
    if edit_LogicalTab_LeslieFast then
      LeslieDestHornSpeed:= edit_HornFastTm + 50;
      LeslieDestRotorSpeed:= edit_RotorFastTm + 50;
    else
      LeslieDestHornSpeed:= edit_HornSlowTm;
      LeslieDestRotorSpeed:= edit_RotorSlowTm;
    endif;
    // Rampen für Anlauf/Bremsen
    if isSystimerzero(HornTimer) then
      if LeslieHornSpeed < LeslieDestHornSpeed then
        Inc(LeslieHornSpeed);
        setSysTimer(HornTimer, edit_HornRampUp); // Anlauf
      endif;
      if LeslieHornSpeed > LeslieDestHornSpeed then
        Dec(LeslieHornSpeed);
        setSysTimer(HornTimer, edit_HornRampDown); // Auslauf
      endif;
    endif;
    if isSystimerzero(RotorTimer) then
      if LeslieRotorSpeed < LeslieDestRotorSpeed then
        Inc(LeslieRotorSpeed);
        setSysTimer(RotorTimer, edit_RotorRampUp); // Anlauf
      endif;
      if LeslieRotorSpeed > LeslieDestRotorSpeed then
        Dec(LeslieRotorSpeed);
        setSysTimer(RotorTimer, edit_RotorRampDown); // Auslauf
      endif;
    endif;
  else
    // Rampe für Auslauf, stoppt auf bestimmter Position
    // Horn maximalen mittleren Throb-Wert von L/R anfahren
    if LeslieHornSpeed > 5 then
      if isSystimerzero(HornTimer) then
        setSysTimer(HornTimer, 15); // langsamer Auslauf
        dectolim(LeslieHornSpeed, 5);
      endif;
    else
      if (FPGAreceiveLong2 + FPGAreceiveLong1 > 15) then
        FPGAreceiveLong2:= FPGAreceiveLong2 and %00001110;
        FPGAreceiveLong1:= FPGAreceiveLong1 and %00001110;
        if (FPGAreceiveLong2 = FPGAreceiveLong1) then
          LeslieHornSpeed:= 0;      // Stopp
        endif;
      endif;
    endif;
    // Rotor maximalen Throb-Wert anfahren
    if LeslieRotorSpeed > 5 then
      if isSystimerzero(RotorTimer) then
        setSysTimer(RotorTimer, 8); // langsamer Auslauf
        dectolim(LeslieRotorSpeed, 5);
      endif;
    else
      if ((FPGAreceiveLong0 and %00001110) > 10) then
        LeslieRotorSpeed:= 0;      // Stopp
      endif;
    endif;
  endif;
  SendByteToFPGA(LeslieHornSpeed, 177);
  SendByteToFPGA(LeslieRotorSpeed, 178);
end;

// #############################################################################

procedure FH_TestExtLicence;
begin
  ValueLong:= ReceiveFPGA(244);   // FPGA-Freischaltungen
  HasExtendedLicence:= bit(ValueLong0, 1);
end;

end fpga_hilevel.


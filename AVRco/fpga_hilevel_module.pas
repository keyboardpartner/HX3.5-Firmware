// ############################################################################# 
// ###                   FPGA HIGH-LEVEL-FUNKTIONEN                          ### 
// ###             Tabs und gesetzte Parameter an FPGA senden                ### 
// ############################################################################# 

unit fpga_hilevel_module;

interface
uses var_def, const_def, fpga_if, dataflash, MIDI_com;

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
  
// vorgefertigte Blocks (8 pro Set) mit Nummer wave_set 
// aus DF laden und an AutoInc-Reg senden 
  procedure FH_WaveBlocksToFPGA;
  
// 1024 Keymap-Werte 8 Bit breit an FPGA DDS48 übertragen 
  procedure FH_KeymapToFPGA; 
  
// 1024 Keymap-Werte 8 Bit breit an FPGA DDS48 übertragen 
  procedure FH_NoteHighpassFilterToFPGA; 
  
// 95 Tuning-Werte 16 Bit breit an FPGA DDS96 übertragen 
  procedure FH_TuningValsToFPGA; 
  
  procedure FH_TaperingToFPGA(const taper_set: byte); 
  
  procedure FH_PhasingRotorToFPGA; 
  procedure FH_UpdatePHRspeed; 
  
  procedure FH_updateLeslieSpeed; 
  
  procedure FH_CoresToFPGA; 
  
  procedure FH_UpperRoutingToFPGA; 
  procedure FH_RouteOrgan; 
  
  procedure FH_TestExtLicence; 
  
  procedure FH_SendModuleExtRotary;

implementation
{$IDATA}
var
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
// ############################################################################# 
// ###                       FPGA MIDI-FUNKTIONEN                            ### 
// ############################################################################# 
  
// ############################################################################# 
  
  
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
  is_eg_adsr:= (manual = 0) and (bb_ena_env_adsrmode_bits <> 0)
               and (bb_ena_env_db_bits <> 0)
               and (edit_GatingMode >= 2); 
  
  if (manual = 0) and edit_LogicalTab_PercOn then
    mute_db:= not edit_LogicalTab_PercSoft; 
  else 
    mute_db:= false; 
  endif; 

  // normale Zugriegel in Temp-Tabelle 
  if manual = 2 then // Pedal? 
    for i:= 0 to 8 do 
      m:= db_array[i]; 
      temp_db_levels[i]:= muldivByte(m, edit_BusbarLevels[i], 127); // mal Busbar-Pegel 
    endfor; 
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
  for i:= 0 to 5 do 
    if HasExtendedLicence then 
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
    else 
      m:= 0; 
      my_dbe_val:= 0; 
    endif; 
    
    temp_db_levels[i + 9]:= m; 
    temp_dbe_levels[i + 9]:= my_dbe_val; 
  endfor; 
  
  for i:= 0 to 15 do       // 16 Werte log. an LC senden 
    m:= temp_db_levels[i]; 
    if is_eg_adsr and bit(bb_ena_env_percmode_bits, i) then  // soll auf Drawbar-Level? 
      // nach Formel Sustain = DB / (P + 1) und V = DB * fac + P 
      m:= gettable(c_DrawbarLogTable, m); 
      // halbieren, weil doppelter Pegel durch gesetztes FULL_BIT 
      FPGAsendByte:= m shr 1; 
      
      m:= temp_dbe_levels[i]; 
      m:= gettable(c_DrawbarLogTable, m); 
      FPGAsendByte:= FPGAsendByte + m; 
    else 
      FPGAsendByte:= gettable(c_DrawbarLogTable, m); 
      if mute_db then 
        // Drawbar-Pegelabsenkung bei Percussion gewünscht, nur Hammond 
        FPGAsendByte:= muldivByte(FPGAsendByte, edit_PercMutedLvl, 127); 
      endif; 
    endif; 
    if ((not HasExtendedLicence) or (edit_GatingMode = 0)) and (i > 8) then 
      FPGAsendByte:= 0; 
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
  FI_AutoIncSetup(11); 
  for i:= 0 to 15 do 
    FPGAsendWord:= gettable(c_TimeLogTable, bb_attack_arr[i]); 
    SendFPGA16; 
  endfor; 
  for i:= 0 to 15 do 
    FPGAsendWord:= gettable(c_TimeLogTable, bb_decay_arr[i]); 
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
    FPGAsendWord:= gettable(c_TimeLogTable, bb_release_arr[i]); 
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
      Writeln(Serout, '/ (FH) Sustain DB val:' + ByteToStr(my_db_val) + ' DBE val:' + ByteToStr(my_dbe_val)); 
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
  Writeln(Serout, '/ (FH) Send Upper DB'); 
{$ENDIF}
  FI_AutoIncSetup(8);          // for Write Core 8 = Upper DBs 
  drawbars_to_lc(edit_UpperDBs, 0); 
  FI_AutoIncReset(8); 
  // Sustainpegel neu senden, ggf. H100 Harp Sustain 
  if (edit_GatingMode = 1) and edit_LogicalTab_H100_HarpSustain then 
    harp_sustain_to_bb_adsr;  // nur BB 3 freigeschaltet 
    bb_adsr_to_fpga; 
  endif; 
  if edit_GatingMode > 1 then // alle EG Modes 
    adsr_to_bb_adsr; 
    bb_adsr_to_fpga; 
  endif; 
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
  Writeln(Serout, '/ (FH) Route Organ'); 
{$ENDIF}

  // Routing-Bits werden durch erfolgte Änderungen an FPGA gesendet
  if edit_LogicalTab_PercOn then
    if edit_LogicalTab_Perc3rd then
      edit_ena_cont_perc_bits:= (edit_ena_cont_perc_bits and $FF7) or $010; // Perc Select 3rd-Bit
    else
      edit_ena_cont_perc_bits:= (edit_ena_cont_perc_bits and $FEF) or $008;
    endif;
  else
    edit_ena_cont_perc_bits:= (edit_ena_cont_perc_bits and $FE7);
  endif;

  FH_UpperRoutingToFPGA; // auf BB umsetzen, ans FPGA schicken
  FH_InsertsToFPGA; 
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
  Writeln(Serout, '/ (FH) Send Routing'); 
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
  // für Böhm auch EG mode!
  if cancel_1 then 
    bb_ena_cont_bits:= bb_ena_cont_bits and $FEFF; 
    // bb_ena_env_adsrmode_bits:= bb_ena_env_adsrmode_bits and $FEFF; 
    bb_ena_env_db_bits:= bb_ena_env_db_bits and $FEFF;  // FPGA SPI #41 
  endif; 

  bb_ena_env_full_bits:= drawbar_ena_to_busbar_ena(edit_ena_env_full_bits);
  bb_env_to_dry_bits:= drawbar_ena_to_busbar_ena(edit_env_to_dry_bits);  // FPGA SPI #43 
  
  for idx:= 0 to 3 do 
    SendWordToFPGA(bb_UpperRoutingWords[idx], idx + 40);  // Ena-Word-Reihenfolge wie im FPGA 
  endfor; 
  
  SendWordToFPGA(bb_ena_cont_perc_bits, 32); 
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) FPGA #32 (Perc) = $' + IntToHex(bb_ena_cont_perc_bits)); 
  Writeln(Serout, '/ (FH) Sust on DB = $' + IntToHex(bb_ena_env_percmode_bits)); 
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
  Writeln(Serout, '/ (FH) Send Percussion Params'); 
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
    my_timerval:= gettable(c_TimeLogTable, edit_PercShortTm); 
    my_timerval:= my_timerval div 8; 
  else 
    my_timerval:= gettable(c_TimeLogTable, edit_PercLongTm); 
    my_timerval:= my_timerval div 8; 
  endif; 
  
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

  if Lo(my_lvl) > 200 then
    Lo(my_lvl):= 200; // begrenzen, sonst Verzerrungen bei mehreren Noten 
  endif; 
  SendWordToFPGA(my_timerval, 39); // perc_decay 
  SendWordToFPGA(my_lvl, 33); // perc_level 
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
    FPGAsendWord:= gettable(c_TimeLogTable, m); 
    SendFPGA16; 
  endfor; 
  // Decay-Values errechnen und senden 
  decay_val:= adsr_arr[1];  // 0..127 
  for i:= 0 to 15 do 
    if bit(full_adsr, i) then 
      m:= decay_val; 
    else 
      m:= 0; 
    endif; 
    FPGAsendWord:= gettable(c_TimeLogTable, m); 
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
    if bit(full_adsr, i) then 
      m:= release_val; 
    else 
      m:= 0; 
    endif; 
    FPGAsendWord:= gettable(c_TimeLogTable, m); 
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
  FI_AutoIncSetup(9);         // for Write Core 9 
  drawbars_to_lc(edit_LowerDBs, 1); 
  FI_AutoIncReset(9); 
  if HasExtendedLicence then 
    if edit_GatingMode > 1 then // alle EG Modes 
      my_word:= drawbar_ena_to_busbar_ena(EC_LogicalTabs2Word(48)); 
      SendWordToFPGA($0FFF, 44); // ADSR enables, all ON 
      FI_AutoIncSetup(12);    // for Write Core 12 
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
  FI_AutoIncSetup(10);       // for Write Core 10 
  drawbars_to_lc(edit_PedalDBs, 2); 
  FI_AutoIncReset(10); 
  // ADSR-Params bei Pedal immer 
  FI_AutoIncSetup(13);       // for Write Core 13 
  scaled_lwrped_adsr_to_lc(edit_PedalADSR, $FFF); 
  FI_AutoIncReset(13); 
end; 

// ############################################################################# 
// ###                   FPGA HIGH-LEVEL-FUNKTIONEN                          ### 
// ############################################################################# 

procedure FH_InsertsToFPGA; 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Inserts to FPGA'); 
{$ENDIF}
  Inserts:= 0; 
  InsertVibratoUpper:= edit_LogicalTab_VibOnUpper; 
  InsertVibratoLower:= edit_LogicalTab_VibOnLower; 
  if HasExtendedLicence then 
    InsertPhasingUpper:= edit_LogicalTab_PHRupperOn; 
    InsertPhasingLower:= edit_LogicalTab_PHRlowerOn; 
  else 
    InsertPhasingUpper:= false; 
    InsertPhasingLower:= false; 
  endif; 
  InsertTubeAmp:= not edit_LogicalTab_TubeAmpBypass; 
  InsertRotarySpkr:= not edit_LogicalTab_RotarySpkrBypass; 
  // InsertADSRtoPerc:= edit_LogicalTab_H100_2ndVoice; 
  InsertAddPedal:= not edit_LogicalTab_SeparatePedalOut; 
  // entspricht jetzt Bit-Folge im FPGA Register 66 
  SendByteToFPGA(Inserts, 66);  // Insert Change 
end;

// ############################################################################# 

procedure FH_SplitConfigToFPGA; 
// Splitmode setzen: 
// 0 = PedalToLower, 1 = LowerToUpper 
// 2 = PedalToUpper, 3 = LowerToUpper + 1 Oktave 
// 4 = LowerToUpper +2 Oktaven 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Split mode to FPGA: ' + ByteToStr(edit_SplitMode)); 
  Writeln(Serout, '/ (FH) Split Point to FPGA: ' + ByteToStr(edit_SplitPoint)); 
{$ENDIF}
  // Werte an Scan Driver 
  SendByteToFPGA(edit_GenTranspose, 10);  // Generator Transpose, +1 = 1 Halbton nach oben 
  SendByteToFPGA(edit_KeyTranspose, 13);  // positive Werte verschieben Töne nach UNTEN! 
  SendByteToFPGA(edit_LocalEnable xor 7, 14);   // ScanCore SPI Local Disables 
  SendByteToFPGA(edit_SplitMode, 6);   // Splitmode 
  SendByteToFPGA(edit_SplitPoint, 8);  // Splitpunkt 
  if NewSplitRequest and edit_LogicalTab_SplitOn then 
{$IFDEF DEBUG_MSG}
    Writeln(Serout, '/ (FH) New Split Request'); 
{$ENDIF}
    // Scan/Split erstmal OFF, damit Änderungen beim Wiedereinschalten übernommen werden 
    SendByteToFPGA(0, 7); 
    mdelay(3); 
    SendByteToFPGA(2, 7); 
    mdelay(3); 
    NewSplitRequest:= false; 
  endif; 
  SendByteToFPGA(byte(edit_LogicalTab_SplitOn) and 1, 7); // Split ON Register 
end; 

// ############################################################################# 

procedure FH_OrganParamsToFPGA; 
// Edit-Tabelle Orgel an FPGA, Kanal und Freigabe an SAM5504 
// nur übertragen, wenn im Menü geändert 
begin
// Achtung: Throb Position wird auf 4 gelesen, edit_MIDI_Channel auf SPI 4 muss
// deshalb in AC_SendSwell ebenfalls gesendet werden! 
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Organ params to FPGA'); 
{$ENDIF}
  m:= edit_MIDI_Channel;
  SendByteToFPGA(m, 4); // MIDI-Channel 
// MIDI_OUT_SEL: 0 = MIDI_TX_1, 1 = MIDI_IN_1, 2 = MIDI_IN_2, 3 = MIDI_FROM_SAM (USB) 
  m:= (edit_ContSpringFlx shl 4) or (edit_ContSpringDmp and 15);
  SendByteToFPGA(m, 9);          // Klick-Länge und Noise-Frequenz 
  SendByteToFPGA(edit_GenTranspose, 10);  // Generator Transpose 
  SendByteToFPGA(edit_KeyTranspose, 13);  // positive Werte verschieben Töne nach UNTEN! 
  m:= gettable(c_TuningTable, edit_TG_tuning);
  SendByteToFPGA(m, 68);  // CycleSteal-Wert -125 .. +125 
  
  m:= (edit_TG_Flutter and %00001111) or (edit_TG_Leakage shl 4);
  SendByteToFPGA(m, 67);  //
  SendByteToFPGA(0, 64);  // kein Swap DAC 
end; 

// ############################################################################# 

procedure FH_LicenceToFPGA; 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Licences to FPGA'); 
{$ENDIF}
  ValueLong:= ReceiveFPGA(240); // hier nur DNA-Auslese-Trigger
  ValueLong:= EE_DNA_0 and $FFFFFF;  // Freischaltcode Organ, sofern gesetzt
  SendLongToFPGA(ValueLong, 240);
  ValueLong:= EE_DNA_1 and $FFFFFF;  // Freischaltcode Extended, sofern gesetzt
  SendLongToFPGA(ValueLong, 241);
end; 

// ############################################################################# 

procedure FH_SendLeslieInitsToFPGA; 
begin
// Leslie Equalizer, Offsets und Delays an FPGA 
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Rotary params to FPGA'); 
{$ENDIF}
  edit_LeslieInits[17]:= edit_LeslieInits[16]; 
  edit_LeslieInits[19]:= edit_LeslieInits[18]; 
  edit_LeslieInits[21]:= edit_LeslieInits[20]; 
  edit_LeslieInits[23]:= edit_LeslieInits[22]; 
  for i:= 4 to 63 do 
    m:= edit_LeslieInits[i]; // Grundeinstellungen direkt an FPGA 
    SendByteToFPGA(m, i + 176); 
  endfor; 
  SendByteToFPGA(edit_LeslieInits[28], 179); // Invert Horn 
  
  FH_InsertsToFPGA; 
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
  waveset_block:= word((edit_TG_WaveSet) * 4) + c_wavesets_base;
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) TG WaveSet #' + ByteToStr((edit_TG_WaveSet))
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
  Write(Serout, '/ (FH) TG Keymap to FPGA (3), TG size '
        + ByteToStr(edit_TG_Size) + ', HiFbk '); 
  if edit_HighFoldbackOn then 
    Writeln(Serout, 'ON'); 
  else 
    Writeln(Serout, 'OFF'); 
  endif; 
{$ENDIF}
  
  FI_AutoIncSetup(3); // for Write Core 3 
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
  Writeln(Serout, '/ (FH) LC Filters to FPGA (6), TG size '
          + ByteToStr(edit_TG_Size)); 
{$ENDIF}
  FI_AutoIncSetup(6); // for Write Core 6 = RC Filter Facs in FPGA, tg_manuals_ng 
  for busbar:= 0 to 15 do 
    highpassfilter_to_fpga64(edit_BusBarNoteOffsets[busbar], edit_TG_Size); 
  endfor; 
  FI_AutoIncReset(6); 
end; 

procedure FH_TuningValsToFPGA; 
// 95 Tuning-Werte 16 Bit breit an FPGA DDS96 übertragen 
// Generator dds96 arbeitet mit Vorteilern 1..128 pro Oktave, deshalb gleiche Werte 
// für jede Oktave. Lediglich oberste Hammond-Oktave ist etws gespreizt, deshalb extra. 
var
  my_random_limit, my_random_word  : word; 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) TG tuning set #' + ByteToStr(edit_TG_TuningSet) + ' to FPGA (5)'); 
{$ENDIF}
  FI_AutoIncSetup(5); // for Write Core 5 
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
  m:= gettable(c_TuningTable, edit_TG_tuning); 
  SendByteToFPGA(m, 68);  // CycleSteal-Wert -125 .. +125 
end; 

procedure FH_TaperingToFPGA(const taper_set: byte); 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Tapering set #' + ByteToStr(taper_set) + ' to FPGA (1)'); 
{$ENDIF}
  if taper_set <= 3 then 
    // Taper-Sets aus DF 
    DF_SendToAutoinc(taper_set + 11, 1, 4096);  // Target Tapering (+11) 
  else 
    // Errechnete oder konstante Taper-Werte für Nicht-Hammonds 
    FI_AutoIncSetup(1); // for Write Core 1 = Tapering 
    for i:= 0 to 15 do 
      case taper_set of 
        4: // linear 
           for m:= 0 to 63 do 
             FPGAsendByte:= edit_TG_FixedTaperVal; 
             SendFPGA8; 
           endfor; 
         |
         5: // higher DB enhanced
           for m:= 0 to 63 do
             FPGAsendByte:= edit_TG_FixedTaperVal + (i * 3);
             SendFPGA8;
           endfor;
         |
        6: // Brilliant
           for m:= 0 to 63 do
             FPGAsendByte:= edit_TG_FixedTaperVal + (m shr 1) + (i * 3);
             SendFPGA8;
           endfor;
         |
        7: // Sharp
           for m:= 0 to 63 do
             FPGAsendByte:= edit_TG_FixedTaperVal + muldivByte(i + 1, m + 1, 20) + (i * 3);
             SendFPGA8;
           endfor;
         |
      endcase;
    endfor; 
    FI_AutoIncReset(1); 
  endif; 
  
// erste 12 Tapering- und Keymap-Werte 8 Bit breit nochmal an FPGA übertragen 
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) DB16 Foldb/Keymap to FPGA'); 
{$ENDIF}
  if taper_set <= 3 then 
    m:= edit_TG_First16TaperVal;  // fester Pegel 
  else 
    m:= edit_TG_FixedTaperVal; 
  endif; 
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
  Writeln(Serout, '/ (FH) Phasing Rotor params to FPGA'); 
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

procedure FH_CoresToFPGA; 
// 0: Scan Core, 
// 8: Keymap, 
// 10: DSP Core (zusätzlich im EEPROM des SPIN-1) 
// 11: Tapering 
// 15: FIR Horn 
begin
{$IFDEF DEBUG_FH}
  Writeln(Serout, '/ (FH) Config ScanCore and FIR BlockRAMs from DF'); 
{$ENDIF}
//  if IsFinalized then 
  MemLED(true); 
  DF_SendToAutoinc(0, 0, 8192);    // Target ScanCore (+0 auf Reg. 0) 
  DF_SendToAutoinc(15, 2, 2048);    // FIR Koeffizienten Horn (+15 auf Reg. 2) 
  MemLED(false); 
  FI_GetScanCoreInfo; 
//  else 
//    WriteSerWarning; 
//    writeln(serout,'Cores not loaded'); 
//  endif; 
end; 

// ############################################################################# 

procedure FH_VibratoToFPGA; 
var
  my_am, my_fm   : byte; 
begin
  // Interpolierte Vibrato-Linebox, andere FPGA-Register
  // 160 bis 174: Delay-Taps 
  my_fm:= edit_VibMods[edit_VibKnob]; 
  my_am:= (edit_VibChLineAgeAM div 4) + muldivByte(edit_VibChLineAgeAM, my_fm, 168); 
  if (bit(edit_VibKnob, 0)) then 
    my_fm:= muldivByte(my_fm, 80, 100); 
  endif; 
  for i:= 0 to 14 do   // 15 ansteigende Verzögerungszeiten berechnen 
    m:= muldivByte(my_fm, i, 28) + 1;   //  49 = 1 ms = V3 
    SendByteToFPGA(m, 160 + i); 
  endfor; 
  
  SendDoubledByteToFPGA(muldivByte(edit_VibChPreEmphasis, 97, 127) + 30, 144);   // #1320 
  SendDoubledByteToFPGA(my_am, 145);                 // #1321 Level AM 
  SendDoubledByteToFPGA(edit_VibChFeedback, 146);    // #1322 Feedback 
  SendDoubledByteToFPGA(edit_VibChReflection, 147);  // #1323 
  SendDoubledByteToFPGA(muldivByte(edit_VibChRespCutoff, 97, 127) + 30, 148);   // #1324 Filter Offset 
  SendDoubledByteToFPGA(edit_PhaseLk_Shelving, 149); // #1325 Phase Lk 
  SendByteToFPGA(150 - edit_ScannerGearing, 150);    // #1326 Vibrato-Frequenz umdrehen 
  if (bit(edit_VibKnob, 0)) then 
    // Chorus-Werte 
    SendScaledByteToFPGA(edit_ChorusBypassLevel, 151, 165);  // #1327 Dry 
    SendScaledByteToFPGA(edit_ChorusScannerLevel, 152, 165); // #1328 Wet 
  else 
    // Vibrato-Werte 
    my_am:= my_am div 2; 
    SendByteToFPGA(0, 151);    // Dry auf 0 
    SendScaledByteToFPGA(255 - my_am, 152, 185);             // Wet auf Max 
  endif; 
  FH_InsertsToFPGA;
end; 

procedure FH_updateLeslieSpeed; 
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

end fpga_hilevel_module.


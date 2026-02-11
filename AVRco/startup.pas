// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################

Unit startup;

interface
uses const_def, var_def, port_def, nuts_and_bolts, fpga_if, sd_card,
     apply_changes;
{$IFNDEF MODULE}
uses save_restore, display_toolbox, adc_touch_interface, switch_interface;
{$ENDIF}

var  // Send to FatarScan76
  i2c_buf24: Array[0..23] of byte;
  i2c_buf24_flag[@i2c_buf24 + 0]: Boolean;

  // Received from FatarScan76
  i2c_buf4: Array[0..3] of byte;
  i2c_buf4_version[@i2c_buf4 + 0]: Byte;
  i2c_buf4_lastkey[@i2c_buf4 + 1]: Byte;
  i2c_buf4_keyspressed[@i2c_buf4 + 2]: Byte;


procedure START_LoadFromEEPROM;
procedure START_ColdBoot;
procedure START_InitAll;
{$IFNDEF MODULE}
procedure START_InitFatarScan76;
{$ENDIF} // ALLINONE

implementation
{$IDATA}


// #############################################################################

{$IFNDEF MODULE}
{
procedure DoFactoryReset;
begin
  LCDclr_M(LCD_m1);
  DisplayHeader('Factory Reset?'); // FactoryReset-Meldung
  LCDxy_M(LCD_m1, 0, 1);
  write(LCDOut_M,'Btn Up=Y Dwn=N');
  repeat
  until not DT_PanelButtonPressed(20);   // warten bis Drehknopf losgelassen
  mdelay(100);
  repeat
  until DT_PanelButtonPressed(20);
  if PanelButtonUp then
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M,'Restoring Memory');
    DFtoEEPROM(c_eeprom_base, 0); // aus Block 9 lesen
    START_LoadFromEEPROM;
    DF_InitAllPresets;
    System_Reset;
  endif;
  LCDclr_M(LCD_m1);
  LED_timer250;
  MenuIndexChanged:= true;
end;
}
{$ENDIF}

procedure START_LoadFromEEPROM;
var idx: Integer;
begin
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ (SR) Load defaults from EEPROM');
{$ENDIF}
  // EEPROM in edit_array kopieren
  for idx:= 48 to 495 do
    m:= eep_defaults[idx];
    if m > c_edit_max[idx] then
      m:= c_edit_max[idx];
      eep_defaults[idx]:= m;
    endif;
    edit_array[idx]:= m; // Param-Array updaten
  endfor;
  // Werte aus Erstprogrammierung, persistent bei Updates
  for i:= 0 to 15 do
    edit_DefaultsGroup[i]:= EE_InitsGroup[i];
  endfor;
  for i:= 0 to 23 do
    edit_SAM_RevDSP_Init[i]:= eep_SAM_RevDSP_Init[i];
  endfor;
  LoadDrawbarDefaults;
  CurrentPresetName:= c_PresetNameStr0;
  edit_ShowCC:= false;
  midi_edit_perc_levelsoft:= edit_PercSoftLvl;
  midi_edit_perc_levelnorm:= edit_PercNormLvl;

  midi_swell128:= 125;
  // nur VibKnob-Stellung berücksichtigen:
  VoiceUpperInvalid:= false;
  VoiceLowerInvalid:= false;
  VoicePedalInvalid:= false;
  CommonPresetInvalid:= false;

  FillBlock(@edit_voices, 4, 0);
  NB_ResetSpecialFlags;
{$IFNDEF MODULE}
  NB_VibknobToVCbits;
{$ENDIF}

  CopyBlock(@edit_array, @edit_CompareArray, 496);
  CopyBlock(@edit_array, @temp_common, 496);
  FillBlock(@edit_array_flag, 496, 0);
end;


// #############################################################################
// ###                 Initialisierung FPGA und SAM5504                      ###
// #############################################################################

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

procedure START_InitFatarScan76;
// Initialisierung externer MIDI-Keyboards an I2C
var my_result: Byte;
begin
  ExternalScanActive:= false;
  if NB_ManualDefaultsToI2Cslave(0) then
    NB_GetBytefromI2Cslave($5A, 0, my_result);
    writeln(serout,'/ FatarMIDI UPR v#' + ByteToHex(my_result));
    ExternalScanActive:= true;
  endif;
  if NB_ManualDefaultsToI2Cslave(1) then
    NB_GetBytefromI2Cslave($5B, 0, my_result);
    writeln(serout,'/ FatarMIDI LWR v#' + ByteToHex(my_result));
    ExternalScanActive:= true;
  endif;
  if NB_ManualDefaultsToI2Cslave(2) then
    NB_GetBytefromI2Cslave($5C, 0, my_result);
    writeln(serout,'/ FatarMIDI PED v#' + ByteToHex(my_result));
  endif;
  if NB_ManualDefaultsToI2Cslave(3) then
    NB_GetBytefromI2Cslave($5D, 0, my_result);
    writeln(serout,'/ FatarMIDI AUX v#' + ByteToHex(my_result));
  endif;
end;
// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************



procedure START_InitAll;
begin
  // Alte initialisierungen korrigieren
  if eep_EquBassDetentShift = 255 then
    for i:= 0 to 3 do
      eep_PotDetentShiftGroup[i]:= 64;  // Mittelstellung
    endfor;
  endif;

  if (eep_Pedal4DBfacs16[0] > 127) or (eep_Pedal4DBfacs8[0] > 127) then // nicht initialisiert?
    for i:= 0 to 11 do
      eep_Pedal4DBfacs8[i]:= c_Pedal4DBfacs8[i];
      eep_Pedal4DBfacs8H[i]:= c_Pedal4DBfacs8H[i];
      eep_Pedal4DBfacs16[i]:= c_Pedal4DBfacs16[i];
      eep_Pedal4DBfacs16H[i]:= c_Pedal4DBfacs16H[i];
    endfor;
  endif;

  if (eep_OrganModelAssignments[0] > 15) then // nicht initialisiert?
    for i:= 0 to 15 do
      eep_OrganModelAssignments[i]:= i;
    endfor;
  endif;

  if (eep_SpeakerModelAssignments[0] > 15) then // nicht initialisiert?
    for i:= 0 to 15 do
      eep_SpeakerModelAssignments[i]:= i;
    endfor;
  endif;

  if (EE_RestoreCommonPresetMask2 > 63) then // nicht initialisiert?
    EE_RestoreCommonPresetMask2:= 7;
  endif;

  LED_timer150;

  START_LoadFromEEPROM; // auch für DF-Init!

{$IFNDEF MODULE}
  NB_CreateInverseMenuArr;
  DT_Init;
  edit_CommonPreset:= 0;
  edit_CommonPreset_flag:= 0;
  footsw_lesliefast_old:= false;
  footsw_leslierun_old:= false;
{$ENDIF} // ALLINONE
  DF_SendToAutoinc(c_scan_base_DF, 0, 8192);  // Target ScanCore (+0 auf Reg. 0)
  FH_LicenceToFPGA;
  SendByteToFPGA(0, 246); // Set DSP ROW bits auf 0

{$IFNDEF MODULE}
  SWI_init;
{$ENDIF}

  FH_TestExtLicence;   // FPGA-Freischaltungen
  FH_LicenceToFPGA;

  NB_LoadPhasingSet(0);

  NB_ValidateExtendedParams;  // Legt gültige Menüs und Restore-Freigaben an
  ReverbKnob_old:= 255;

{$IFNDEF MODULE}
  incl(PortA, 3); // Reset HC164 aufheben
  if FPGA_OK then
    MIDI_SendVent;
    LoadDrawbarDefaults;
    AC_MutualControls;

    FH_SendReverbTabs;
    mdelay(3);
  endif;
{$ENDIF}
  AC_LoadOrganModel;
  AC_LoadSpeakerModel;

  FH_WaveBlocksToFPGA;
  FH_KeymapToFPGA;
  FH_NoteHighpassFilterToFPGA;

  FH_SplitConfigToFPGA;
  FH_VibratoToFPGA;

  FH_TuningValsToFPGA;
  FH_TaperingToFPGA(edit_TG_TaperCaps);
  FH_PhasingRotorToFPGA;
  FH_UpdatePHRspeed;
  AC_SendLeslieLiveParams;

  NB_CCarrayFromDF(edit_MIDI_CC_Set); // setzt UseSustainSostMask
{$IFNDEF MODULE}
  ADC_Init;
  ADC_ReadAll_24;
  ADC_ReadAll_64;
  ADC_ChangeStateAll(true);
  ADC_ChangesToEdit;
{$ENDIF}
  FH_OrganParamsToFPGA;   // sendet UseSustainSostMask
  FH_InsertsToFPGA;
  AC_SendTrimPots;
  AC_SendVolumes;
  AC_SendSwell;
  AC_HandlePercButtons;    // auch DBs, wg. EG und Percussion
  AC_SendPercValues;   // auch DBs, wg. EG und Percussion
  FH_LowerDrawbarsToFPGA;
  FH_PedalDrawbarsToFPGA;


// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

  SR_UpperLiveToTemp;
  SR_LowerLiveToTemp;
  SR_PedalLiveToTemp;
  SR_PresetLiveToTemp;

  CurrentPresetName:= c_PresetNameStr0;
  ToneChanged:= true;

  MIDI_ResetGMprogs;
  MIDI_SendNRPN($3530, edit_UpperGMharm_0);
  MIDI_SendNRPN($3560, edit_UpperGMlvl_0);
  // layer 2:
  if HasExtendedLicence then
    MIDI_SendNRPN($3524, edit_UpperGMdetune_1 + 57);
    MIDI_SendNRPN($3534, edit_UpperGMharm_1);
    MIDI_SendNRPN($3564, edit_UpperGMlvl_1);
  else
    MIDI_SendNRPN($3564, 0);  //  edit_UpperGMlvl_1
  endif;
  mdelay(5);
  MIDI_SendNRPN($3531, edit_LowerGMharm_0);
  MIDI_SendNRPN($3561, edit_LowerGMlvl_0);
  if HasExtendedLicence then
    MIDI_SendNRPN($3525, edit_LowerGMdetune_1 + 57);
    MIDI_SendNRPN($3535, edit_LowerGMharm_1);
    MIDI_SendNRPN($3565, edit_LowerGMlvl_1);
  else
    MIDI_SendNRPN($3565, 0);  //  edit_LowerGMlvl_1
  endif;
  mdelay(5);
  MIDI_SendNRPN($3532, edit_PedalGMharm_0);
  MIDI_SendNRPN($3562, edit_PedalGMlvl_0);
  if HasExtendedLicence then
    MIDI_SendNRPN($3526, edit_PedalGMdetune_1 + 57);
    MIDI_SendNRPN($3536, edit_PedalGMharm_1);
    MIDI_SendNRPN($3566, edit_PedalGMlvl_1);
  else
    MIDI_SendNRPN($3566, 0);  //  edit_PedalGMlvl_1
  endif;
  mdelay(5);
  MIDI_RequestAllGMnames;
  MIDI_SendNRPN($357E, 127); // Request DSP Version Info, get ID $0F SysExResponse

// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************

  setSysTimer(ActivityTimer, 25);
  MenuIndex_Requested:= 0; // angezeigten Wert aktualisieren
  MenuIndex_Splash:= 255;
  MenuIndex_SplashIfEnabled:= 255;
  IsInMainMenu:= true;
{$IFDEF DEBUG_MSG}
  writeln(serout,'/ (RST) InitAll done');
{$ENDIF}
  for i:= 0 to 3 do
    MidiInterpreterEnables[i]:= true;
  endfor;
end;


procedure START_ColdBoot;
//nach Reset aufgerufen
var my_word: Word;
begin

  DDRA:=  DDRAinit;            {PortA dir}
  PortA:= PortAinit;           // mit Reset HC164
  DDRB:=  DDRBinit;            {PortB dir}
  PortB:= PortBinit;           {PortB}
  DDRC:=  DDRCinit;            {PortC dir}
  PortC:= PortCinit;           {PortC}
  DDRD:=  DDRDinit;            {PortD dir}
  PortD:= PortDinit;           {PortD}


// SPI initialisieren, wie bei MMC
  SPCR := %01011100;          // Enable SPI, Master, CPOL/CPHA=1,1 Mode 3
  SPSR := %00000000;          // %00000001 = Double Rate, %00000000 = Normal Rate

//  EIMSK := EIMSK or %00000100;  // external IRQ F_INT auf INT2
//  EICRA := EICRA or %00100000;  // Bit 4 und 5 = INT2 falling Edge
  PWR_GOOD:= false;

  MemLED(true);
  serBaud(57600);       // nur ab mega644!
  EnableInts;

  writeln(serout);
  write(serout,'/ Version ' + Vers1Str);
  write(serout,' - ');
  write(serout,Vers2Str);
  writeln(serout,Vers3Str);

  while serStat do
    i:= serInp;
  endwhile;

  udelay(1);
  ValueLong:= EE_DNA_0 xor EE_DNA_1;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************

  ESP_RST:= low;
  DT_InitLCD;
  mdelay(10);
  ESP_RST:= high;

  VibKnobPortPresent:=  I2CexpStat(Port0);
  if VibKnobPortPresent then
  {$IFDEF DEBUG_MSG}
    writeln(serout,'/ (RST) VibKnob I2C OK');
  {$ENDIF}
    VibKnobPortDDR:= %11000000;
    VibKnobPortOut:= %00111111;
  endif;
  PreampPortPresent:=  I2CexpStat(Port1);
  if PreampPortPresent then
  {$IFDEF DEBUG_MSG}
    writeln(serout,'/ (RST) PreampC I2C OK');
  {$ENDIF}
    PreampPortDDR:= $FF;
    PreampPortOut:= $00;
  endif;

  MenuPanelLEDsPresent:=  I2CexpStat(Port2);

  if MenuPanelLEDsPresent then
    MenuPanelLEDsDDR:= $00; // auf Eingang
    MenuPanelLEDsOut:= $FF;
    mdelay(10);
    my_word:= $0000;  // alle PL25 LEDs OFF
    TWIout(PCA9532_2, $18, my_word);
    mdelay(10);
    my_word:= $0444;  // jede zweite LED ohne PWM auf ON
    TWIout(PCA9532_2, $18, my_word);   // PL25 Einschalten auf %00101010 = $AA
    mdelay(10);
    m:= (not MenuPanelLEDsIn) and $3F;  // nicht alle LEDs verbunden!
    {$IFDEF DEBUG_MSG}
      writeln(serout,'/ (RST) MenuPanel LEDs IN: ' + ByteToStr(m));
    {$ENDIF}
    if (m = $2A) then
      // MenuPanel ist mit Kabel an PL25 verbunden
      {$IFDEF DEBUG_MSG}
        writeln(serout,'/ (RST) MenuPanel LED ctrl by PL25');
      {$ENDIF}
      MenuPanelLEDsPresent:= false;
      MenuPanelLEDsDDR:= $00; // auf Eingang
    else
      {$IFDEF DEBUG_MSG}
        writeln(serout,'/ (RST) MenuPanel LED I2C OK');
      {$ENDIF}
      MenuPanelLEDsDDR:= $FF; // auf Ausgang
      MenuPanelLEDsOut:= $FF;
    endif;
    my_word:= 0;
    TWIout(PCA9532_2, $18, my_word);   // PL25 OFF
  endif;

  START_InitFatarScan76;

// *****************************************************************************
{$ENDIF}
// *****************************************************************************


// Warten bis FPGA-Konfiguration geladen ist
  FI_FPGAconfig(true);

// Lizenzen kontrollieren
  if (EE_DNA_0 <> EE_DNA_0_bak) or (EE_DNA_1 <> EE_DNA_1_bak) then // korrumpiert?
    WriteSerWarning;
    writeln(serout, 'Licence corrupted');
{$IFNDEF MODULE}
    if LCDpresent then
      LCDclr_M(LCD_m1);
      LCDxy_M(LCD_m1, 0, 0);
      LCDout_Error;
      LCDxy_M(LCD_m1, 0, 1);
      write(LCDOut_M, 'LICENCE CORRUPTD');
      LED_blink(10);
    endif;
{$ENDIF} // ALLINONE
    mdelay(2000);
  endif;
{$IFDEF DEBUG_MSG}
  writeln(serout, '/ (RST) Owner: '+ EE_owner);
{$ENDIF}
  SerInpPtr:= 1;

// *****************************************************************************

// erster Bootvorgang nach Flashen des AVR über SPI?
  if EE_FirstRunAfterFactoryPrg then
    EE_FirstRunAfterFactoryPrg:= false;
    EE_ForceUpdateEEPROM:= false;
    EE_EEPROMstructureVersion:= c_FirmwareStructureVersion; // erledigt
  endif;

  if EE_ForceUpdateEEPROM then // wurde ggf. von SD-Loader gesetzt
{$IFNDEF MODULE}
    // Firmware-PresetStructureVersion anders als alte EEPROM-Version?
    // Ab c_FirmwareStructureVersion = $19 nicht den Drawbar-Bereich updaten
    DFtoEEPROM(c_eeprom_base35_DF, 1024); // neuer EEPROM-Inhalt ohne User-Info und DBs
    writeln(Serout, '/ EEPROM update forced');
{$ELSE}
    DFtoEEPROM(c_eeprom_base35_DF, 80); // neuer EEPROM-Inhalt ohne User-Info
{$ENDIF}
    EE_EEPROMstructureVersion:= c_FirmwareStructureVersion; // erledigt
    EE_ForceUpdateEEPROM:= false;
  endif;

// *****************************************************************************

  PWR_GOOD:= true;

  if EE_Vers1Hex < Vers1Hex then
    EE_Vers1Hex:= Vers1Hex;
    eep_LogicalTab_SwapDACs:= false;
    eep_LogicalTab_Shift_upper:= false;
    eep_LogicalTab_Shift_lower:= false;
    if eep_TubeAmpCurveB > 7 then
      eep_TubeAmpCurveA:= 3;
      eep_TubeAmpCurveB:= 3;
    endif;
    writeln(Serout, '/ EEPROM changes done');
  endif;


  START_InitAll;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************
  if LCDpresent then
    LCDxy_M(LCD_m1, 0, 1);
    write(LCDOut_M, Vers3Str);
    LCDclrEOL_M(LCD_m1);
    mdelay(1000);

    if DT_PanelButtonPressed(0) then
      if PanelButtonUp then
        SendByteToFPGA(1, 246); // Set DSP ROW bits = 1
        mdelay(100);
        SendByteToFPGA(0, 246); // Set DSP ROW bits = 0
        repeat
          mdelay(100);
          NB_CheckDFUmsg;
        until not DFUrunning;
      endif;
    endif;
    DT_ResetEncoderKnob;
    CommentStr:= EE_owner;
    LCDclr_M(LCD_m1);
    write(LCDOut_M, CommentStr);
    LCDxy_M(LCD_m1, 0, 1);
    ValueLong:= ReceiveFPGA(242);   // FPGA-Seriennummer
    write(LCDOut_M, 'SerN #');
    write(LCDOut_M, LongToStr(ValueLong));
    LCDOut_M(#32);
    LED_blink(4);
  endif;
  SwellPedalADC := 230;  // wenn disabled, fester Wert

// *****************************************************************************
{$ENDIF}
// *****************************************************************************
  MemLED(false);
  FH_TestExtLicence;   // FPGA-Freischaltungen
end;



end startup.


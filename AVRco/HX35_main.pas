// #############################################################################
//       __ ________  _____  ____  ___   ___  ___
//      / //_/ __/\ \/ / _ )/ __ \/ _ | / _ \/ _ \
//     / ,< / _/   \  / _  / /_/ / __ |/ , _/ // /
//    /_/|_/___/_  /_/____/\____/_/_|_/_/|_/____/
//      / _ \/ _ | / _ \/_  __/ |/ / __/ _ \
//     / ___/ __ |/ , _/ / / /    / _// , _/
//    /_/  /_/ |_/_/|_| /_/ /_/|_/___/_/|_|
//
// #############################################################################

program hx35_main_allinone;

{$W+}

// #############################################################################
// ###      Schalter für bedingte Kompilierung verschiedener Versionen       ###
// #############################################################################

{$DEFINE ALLINONE}
{ $DEFINE MODULE}
{ $DEFINE SPARTAN7}

{ $DEFINE AUTO_FINALIZE}  // TO DO!   - nicht benutzen

{ $DEFINE DEBUG_MSG}      // Ausführliche Meldungen bei vielen Aktionen


{ $DEFINE DEBUG_MIDI_IN}
{ $DEFINE DEBUG_FH}       // Ausführliche Meldungen bei
{ $DEFINE DEBUG_SWI}
{ $DEFINE DEBUG_AC}       // Apply Changes

{$IFDEF DEBUG_MSG}
  {$DEFINE DEBUG_DF}       // Ausführliche Meldungen bei Dataflash-Aktionen
  {$DEFINE DEBUG_FH}       // Ausführliche Meldungen bei FPGA-Aktionen
  {$DEFINE DEBUG_SD}       // Ausführliche Meldungen bei SDCARD-Aktionen
  {$DEFINE DEBUG_DSP}      // Ausführliche Meldungen bei DSP
  {$DEFINE DEBUG_MIDI}
  { $DEFINE DEBUG_SEMPRA}   // Ausführliche Meldungen bei SEMPRA-MIDI
  {$DEFINE DEBUG_SR}       // Ausführliche Meldungen bei Save/Restore
  {$DEFINE DEBUG_SWI}      // Button/Switch/Encoder-Aktionen
  {$DEFINE DEBUG_DF}       // Ausführliche Meldungen bei Dataflash-Aktionen
  { $DEFINE DEBUG_SD}       // Ausführliche Meldungen bei SDCARD-Aktionen
  {$DEFINE DEBUG_SYSEX}    // Ausführliche Meldungen bei SysEx-Empfang
  { $DEFINE DEBUG_DSP}      // Ausführliche Meldungen bei DSP
{$ENDIF}
{ $DEFINE TIMING_PIN}       // LA-Zeitanalyse


// #############################################################################

{ $OPTI SMARTLINK_ONLY}
{ $OPTI NO_REDUNDANT_FRAME_USAGE_OPT}
{ $OPTI NO_OPT_OFFSET_LOADS}
{ $OPTI NO_CHECK_REDUNDANT_LOAD}
{ $OPTI NO_CHECK_REDUNDANT_FRAME_LOAD}
{ $OPTI NO_CHECK_REDUNDANT_SAVE}
{ $OPTI NO_CHECK_MOV}
{ $OPTI NO_CHECK_RETURN_REGS}

{  $OPTI NO_LOOP_OPT}
{ $OPTI NO_OPT_LOOP_LOADS}
{  $OPTI NO_BRANCH_OPT}
{ $OPTI NO_CSE_OPT}
{ $OPTI No_Remove_Code_Islands}
{ $OPTI No_Opt_Final_MOV}

{ $OPTI NO_COM_OPT}
{ $OPTI NO_OPT_TST}
{ $OPTI NO_BITTEST_OPT}
{ $OPTI NO_OPT_CPI}
{ $OPTI NO_CALL_FRAME_OPT}
{ $OPTI NO_CALL_FRAME_OPT_LOCAL}

{ $OPTI NO_OPT_LOCAL_VARS}
{ $OPTI NO_OPT_LOCAL_VARS2}
{ $OPTI NO_OPT_LOCAL_VARS3}

// Falls Assemblerfehler auftreten, ggf. diese Optimierung an- oder abschalten:
{ $OPTI NO_ALLOW_INLINE}

{ $OPTI No_Phase_4}
{ $OPTI No_Phase_3}
{ $OPTI No_Phase_2_OR_3}
{ $OPTI No_Phase_1_2_OR_3}

{ $OPTI QUICK}
{ $OPTI SPECIAL_DEBUG}

// #################################################################################
// Button Bit     0        1         2        3         4       5       6      7
// edit_LogicalTabs1:     PERCON    PERCSOFT  PERCFAST  PERC_3RD  VIBUP  VIBLO   LSRUN   LFAST
// edit_LogicalTabs2:     PRESET1   PRESET2   PRESET3   PRESET4   EFX1   EFX2   LESLBASS BSPLIT
// PL07/PL08 in edit_LogicalTabs1, PL11/PL12 in edit_LogicalTabs2
//
// Vibrato-Drehschalter (alle offen = V1, dh. Pin 1 des Drehschalters OFFEN!)
// edit_VibKnob: 0=V1...5=C3
// KnobBits      C1       V2        C2       V3       C3    (MEMUP   MEMLO    MEMLED)
//               \----------- Drehschalter -----------/      \- Taster -/
// #################################################################################

//Defines aktivieren durch Entfernen des 1. Leerzeichens!
{$NOSHADOW}
{ $DEBDELAY}

// #############################################################################
// ###                ab hier keine DEFINEs mehr �ndern!                     ###
// #############################################################################

Device = mega1284p, VCC = 5;

Define_Fuses
Override_Fuses;    // optional, always replaces fuses in ISPE
COMport = USB;     // COM2..COM7, USB
LockBits0 = [BOOTLOCK11];
FuseBits0 = [CKSEL3];
FuseBits1 = [SPIEN,EESAVE,BOOTSZ1];
FuseBits2 = [BODLEVEL0,BODLEVEL1];
ProgMode = SPI;    // SPI, JTAG or OWD
ProgFuses = true;
ProgLock = true;
ProgFlash = true;
ProgEEprom= true;

AddApp= 'HX35_bootloader';

Import SysTick, FAT16_32, FlashWrite, TWImaster, SerPort, LCDmultiPort, I2CExpand;

From System Import LongWord, LongInt, Random;

Define
  ProcClock      = 16000000;        {Hertz}
  TWIpresc       = TWI_BR400;

  LCDmultiPort   = I2C_TWI;
  LCDTYPE_M      = 44780; // 44780 oder 66712;
  LCDrows_M      = 2;     // rows
  LCDcolumns_M   = 16;     // chars per line

  SysTick        = 2;              //msec
  SerPort        = 57600, Stop1, timeout;    {Baud, StopBits|Parity}
  RxBuffer       = 160, iData;
  TxBuffer       = 32, iData;

  StackSize      = $0100, iData;
  FrameSize      = $0140, iData; // nicht heruntersetzen, sonst MIDI-Update-Bug!

  I2Cexpand = I2C_TWI, $38; {use TWIport, 9554A}
  I2CexpPorts = Port0, Port1, Port2;

  FAT16 = MMC_SPI, iData;
  F16_MMCspeed = standard; // standard, slow, fast, superfast -> XMega + FAT16_32 only
  F16_FileHandles = 3;
  F16_DirLevels = 1;

Uses UFAT16_32, eeprom_def, var_def, const_def, nuts_and_bolts, startup, main_tasks,
     menu_system, adc_touch_interface;

Implementation

const

// #############################################################################
// ###                Encoder und Zeitgeber für MainTask                     ###
// #############################################################################

procedure onSysTick;
begin
{$IFDEF ALLINONE}
// Selbstgemachter Inkrementalgeber
  IRQ_Incr0:= (PinA and 3);
  if IRQ_Incr0 <> IRQ_Incr1 then
    if IRQ_Incr0 = 0 then // Rastpunkt �berschritten
      if (IRQ_Incr2 = 3)then       // kommt aus Ruheposition
        if(IRQ_Incr1 = 1) then     // Rechtsdrehung
          inc(IRQ_Incr_delta);     // Encoder-�nderung
          inc(IRQ_Incr_acc);       // für Beschleunigung
          IRQ_EncoderTouched:= true;
        elsif(IRQ_Incr1 = 2) then  // Linksdrehung
          dec(IRQ_Incr_delta);     // Encoder-�nderung
          dec(IRQ_Incr_acc);       // für Beschleunigung
          IRQ_EncoderTouched:= true;
        endif;
      endif;
    endif;
    IRQ_Incr2:= IRQ_Incr1;  // vorvorheriger Wert
    IRQ_Incr1:= IRQ_Incr0;  // vorheriger Wert
  endif;
{$ENDIF} // ALLINONE
  inc(SysTickSema);
end;

// #############################################################################
// #############################################################################
// ###                           Hauptschleife                               ###
// #############################################################################
// #############################################################################

begin
  START_ColdBoot;
  MainTasks_Init;
  SWI_ForceSwitchReload;
  ConnectMode:= t_disable;
  AC_ExecEditChanges;   // Ohne MIDI-Ausgabe ausführen

{$IFDEF DEBUG_MSG}
  write(serout,'/ Check SD Card');
{$ENDIF}
  SD_SilentInit;
  if SD_Present then
{$IFDEF DEBUG_MSG}
    writeln(serout,' - OK');
{$ENDIF}
    if F16_FileExist('\', s_autorun_ini, faFilesOnly) then
      // altes _autorun.ini vorhanden? Dann l�schen, muss neu angelegt werden
      if F16_FileExist('\', s_autorun_ini_old, faFilesOnly) then
        F16_FileDelete('\', s_autorun_ini_old);
      endif;
      // Datei umbenennen, um erneuten Start zu vermeiden
      F16_FileRename('\', s_autorun_ini, s_autorun_ini_old);
      PA_RunSDscript( s_autorun_ini_old); // ggf. Reboot, kommt dann nicht zur�ck!
    endif;
    if F16_FileExist('\',s_config_ini, faFilesOnly) then
      if PA_RunSDscript(s_config_ini) then  // darf kein UPD enthalten!
        // Datei umbenennen, um erneuten Start zu vermeiden
        if F16_FileExist('\', s_config_ini_old, faFilesOnly) then
          F16_FileDelete('\', s_config_ini_old);
        endif;
        F16_FileRename('\', s_config_ini, s_config_ini_old);
      endif;
    endif;
{$IFDEF DEBUG_MSG}
  else
    writeln(serout,' - not found');
{$ENDIF}
  endif;
  ErrFlags:= 0;

  ConnectMode:= t_connect_midi;

  FlushBuffer(RxBuffer);
  serout('>');  // NEU: Prompt nach jedem Befehl
  // Hauptschleife
  loop
    MainTasks;
    if Timeslot = 7 then
      if LCDpresent then
        MenuPanelHandling; // 250..370 �s ohne Bedienung
      else
        mdelay(1);
      endif;
    endif;
  endloop;

end hx35_main_allinone.




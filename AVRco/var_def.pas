// #############################################################################
// ###                       F Ü R   A L L E   B O A R D S                   ###
// #############################################################################
// ###                       allg. VARIABLEN-Definitionen                    ###
// #############################################################################

unit var_def;

interface
// enable/disable warnings for this unit

uses const_def;
type
  t_nrpn_entry = record
     EditIdx: Integer;  // verweist auf edit_array 0..511, -1 wenn nicht zugewiesen
     NRPN: Integer;     // NRPN MSB/LSB, -1 wenn nicht zugewiesen
  end;

var
{$DATA}
// schnelle temporäre Variablen
  h, i              : byte;  // h in HW-ADCProzess benutzt
  m, n              : byte;

{$IDATA}

// ------------------------------- SysTimer ------------------------------------

  ActivityTimer: Systimer;  // 16 Bit
  TimeoutTimer, SysExTimer: Systimer8; // 8 Bit

// --------------------------- IRQ und Encoder ---------------------------------

  SysTickSema: Byte;

  IRQ_Incr0, IRQ_Incr1, IRQ_Incr2: byte; // Für Dreh-Encoder, in Systick-IRQ benutzt
  IRQ_Incr_delta, IRQ_Incr_acc: Int8;
  IRQ_EncoderTouched: boolean;
{
  IRQ_Incr_detent, IRQ_Incr_zero: byte;
  IRQ_Incr_forward, IRQ_Incr_reverse: Byte; // bei Init vorbelegt
  IRQ_Incr_delta_temp, IRQ_Incr_delta: Int8;
}


// ---------------------------- MenuPanel --------------------------------------

  EncoderChanged, ButtonPressed: Boolean;
  PanelButtonTemp: Byte;   // Buttons auf Display-Panel
  PanelButtonDown[@PanelButtonTemp, 5]  : bit;
  PanelButtonUp[@PanelButtonTemp, 4]  : bit;
  PanelButtonEnter[@PanelButtonTemp, 3]  : bit;
  IsInBitField, IsInEditName, IsInMainMenu: Boolean;
  EditFieldIndex, EditFieldSize: Byte;

  MenuRefresh: Boolean;       // Wert neu anzeigen
  MenuIndex_Requested: Byte;  // anzuzeigendes Menü wenn <> 255
  MenuIndex_Splash,
  MenuIndex_SplashIfEnabled: Byte;  // kurz anzuzeigendes Menü wenn <> 255
  MenuIndex, LastMainMenuIndex: Byte;
  ValueChangeMode,    // Menü-Modus: Wechseln wenn FLASE oder Wert wenn TRUE
  AnyParamChanged: Boolean;

  ButtonDelta: Int8;
  EncoderDelta: Int8;
  EncoderDiff: Int8;  // für Drehgeber in SysTick-IRQ
  NumberOfIniFiles: byte; // Anzahl INI-Dateien auf SD-Karte

  BlinkToggle, SpeedBlinkToggle: boolean;
  BlinkTimerByte: Byte; // für Preset-Blink
  SingleDBsetSelect: Byte; // Enthält Manual 0..2

  ForceSplitRequest: boolean;

  PresetInvalids: Array[0..3] of Boolean;  // Reihenfolge wie edit_voices
    CommonPresetInvalid[@PresetInvalids + 0]: Boolean;
    VoiceUpperInvalid[@PresetInvalids + 1]: Boolean;
    VoiceLowerInvalid[@PresetInvalids + 2]: Boolean;
    VoicePedalInvalid[@PresetInvalids + 3]: Boolean;

  PresetStoreRequest,
  ToggleLEDstate: Boolean;
  ToggleLEDcount: byte;

  PresetPreview, PresetNameEdit: boolean;
  ExternalScanActive,
  UpperSecondaryActive, LowerSecondaryActive,
  UpperIsLive, LowerIsLive,
  UpperSecondaryActive_DB9_MPX, LowerSecondaryActive_DB9_MPX,
  UpperSecondaryActive_DB9_MPX_old, LowerSecondaryActive_DB9_MPX_old: Boolean;

  BankSelectMSBs: Array[0..3] of Byte;
  BankSelectMSB1[@BankSelectMSBs]: Byte;
  BankSelectMSB2[@BankSelectMSBs + 1]: Byte;
  BankSelectMSB3[@BankSelectMSBs + 2]: Byte;

  BankSelectLSBs: Array[0..3] of Byte;
  BankSelectLSB1[@BankSelectLSBs]: Byte;
  BankSelectLSB2[@BankSelectLSBs + 1]: Byte;
  BankSelectLSB3[@BankSelectLSBs + 2]: Byte;

  BankSelectGenosValids: Array[0..3] of Boolean;
  BankSelectGenosValid1[@BankSelectGenosValids]: Boolean;
  BankSelectGenosValid2[@BankSelectGenosValids + 1]: Boolean;
  BankSelectGenosValid3[@BankSelectGenosValids + 2]: Boolean;

  MidiInterpreterEnables: Array[0..3] of Boolean;

// ------------------------------- MIDI ----------------------------------------

  mp, mv, mcmd, mch: Byte;
  mbool: boolean;
  MIDI_received: LongInt;
  MIDI_swell128, MIDI_swell255_old: Byte;
  MIDI_swell_w, MIDI_swell_final_w: Word;
  MIDI_DisablePercussion: Boolean;  // temp. Percussion-Abschaltung per MIDI
  MIDI_data_entry: byte;
  MIDI_data_entry_msb, MIDI_data_entry_lsb: Byte; // für Sempra
  MIDI_nrpn: Integer;
  MIDI_nrpn_lsb[@MIDI_nrpn+0]: byte;
  MIDI_nrpn_msb[@MIDI_nrpn+1]: byte;
  MIDI_rpn_flags, MIDI_nrpn_flags: Byte;
  MIDI_rpn: Integer;
  MIDI_rpn_lsb[@MIDI_rpn+0]: byte;
  MIDI_rpn_msb[@MIDI_rpn+1]: byte;
  MIDI_edit_perc_levelsoft, MIDI_edit_perc_levelnorm: byte;
  MIDI_sysex_busyflag: Boolean;
  MIDI_OverrideCancelDB1: Boolean;
  MIDI_NewSwellVal: Byte;  // Wird bei Änderung alle 8ms gesendet
 // MIDI_RealOrganSwellAdjust: Byte;

  SysExArray: array[0..255] of byte;

  SysExID_long[@SysExArray]: LongInt;     // Sempra ID, $042000F0
  SysExID_short[@SysExArray]: Integer;    // Roland, 2 Bytes $41F0

  SysExCmd_sempra[@SysExArray + 4]: Integer;       // Sempra, 2 Bytes

// Roland SysEx Defines
// IDX:    0  1  2  3  4  5  6  7  8  9 10 11 12
//        ST Mn Dv Model Co AdrHi AdrLo Da Ck End
// SYSX:  F0 41 10 00 1A 12 01 00 50 00 01 2E F7 - Vib Upper ON
  SysExDeviceID[@SysExArray + 2]: Byte;    // Roland
  SysExModel_1[@SysExArray + 3]: Byte;     // Roland
  SysExModel_0[@SysExArray + 4]: Byte;     // Roland
  SysExCmd[@SysExArray + 5]: byte;         // Roland
  SysExAdrHiWord[@SysExArray + 6]: Word;
  SysExAdrLoWord[@SysExArray + 8]: Word;
  SysExAdr_3[@SysExArray + 6]: Byte;       // Roland
  SysExAdr_2[@SysExArray + 7]: Byte;       // Roland
  SysExAdr_1[@SysExArray + 8]: Byte;       // Roland
  SysExAdr_0[@SysExArray + 9]: Byte;       // Roland
  SysExData[@SysExArray + 10]: Byte;       // Roland

  SysExArrayTemp: array[0..7] of byte;

  ConnectMode: t_connect;
  UseSustainSostMask: Byte; // $80 wenn Sostenuto und Sustain benutzbar

  // Reihenfolge von NRPN $3570+x und in Tabelle:
  // Index = 0=upper_0, 1=lower_0, 2=pedal_0, xxx, 4=upper_1, 5=lower_1, 6=pedal_1, xxx;
  GM_VoiceNameToDisplaySema, GM_VoiceNameReceivedFlags: Array[0..7] of boolean;
  GM_VoiceNames: Array[0..7] of String[15];


// ----------------------------- Hardware --------------------------------------

  ADCtestMode: Boolean;
  SwellPedalADC : byte;
  ToneChanged: boolean;
  SwellPedalControlledByMIDI: boolean;

  CurrentADSRmask: Word;
  CmdSentBySerial, CmdSentByMIDI: Boolean; // Quelle des Parser-Kommandos
  DisablePercussion, DisableDB1: boolean;
  DFUrunning: boolean;
  LeslieHornSpeed, LeslieRotorSpeed: byte;
  LeslieDestHornSpeed, LeslieDestRotorSpeed: byte;

  PhasingSpeed, PhasingDestSpeed: byte;

  ReverbKnob_old: Byte;  // Reverb-Program senden falls geändert, sonst nur Level

// Verteiler für zeitintensive Routinen:
// 0..3 ADCs
// 4 Leslie
// 5 Display
// 6 Tabs & Buttons
// 7 Presets
  TimeSlot: byte;

  HasExtendedLicence: boolean;
  Inserts: Byte; // Bit-Folge in FPGA-SPI
  InsertPhasingUpper[@Inserts,0]: bit;
  InsertPhasingLower[@Inserts,1]: bit;
  InsertVibratoUpper[@Inserts,2]: bit; // wird ständig mit edit_LogicalTab_VibOnUpper überschrieben
  InsertVibratoLower[@Inserts,3]: bit; // wird ständig mit VibOnLower überschrieben
  InsertTubeAmp[@Inserts, 4]:     bit;
  InsertRotarySpkr[@Inserts, 5]:  bit;
  InsertPedalPostMix[@Inserts, 6]: bit;
  InsertPedalBypass[@Inserts, 7]:  bit;

  SD_present     : boolean;
  SD_TextFile_open : boolean;
  SD_TextFile    : file of Byte;

  DSPversion: LongInt;
  DSPversion_L[@DSPversion+0]: Byte;
  DSPversion_H[@DSPversion+1]: Byte;
  DSPversion_Flags_L[@DSPversion+2]: Byte;   // noch nicht benutzt!
  DSPversion_Flags_H[@DSPversion+3]: Byte;

// ------------------------------ Parser ---------------------------------------

  ParamStr       : String[31]; // auch für Display
  SerInpStr      : String[31];
  CommentStr     : String[31];
  TempStr: String[15];

  SerInpPtr, ParsePtr  : byte;
  CmdWhich       : byte; // tcmdwhich nicht mehr benutzt
  ValueInt       : integer;
  ParamAlpha     : boolean; // Flag für Zeichenfolge hinter "="
  ValueLong      : LongInt;
  ValueLong0[@ValueLong+0]: byte;
  ValueLong1[@ValueLong+1]: byte;
  ValueLong2[@ValueLong+2]: byte;
  ValueLong3[@ValueLong+3]: byte;
  ValueByte      : byte;

  // Buffer für Binärformat
  // ESC CMD ADRL ADRH LEN DATA0...DATAn, CRC
  //  BinaryData: array[0..255] of byte;  // jetzt in BlockBuffer8
  BinaryStart: byte;     // ESC char
  BinaryCmd: byte;   // Command (1 = Set, 2 = Read)
  BinaryAdr: Integer;// Adresse (Parameter-Nummer, SubCh)
  BinaryAdrL[@BinaryAdr + 0]: byte;    // Adresse Low
  BinaryAdrH[@BinaryAdr + 1]: byte;    // Adresse High
  BinaryLen: byte;   // Anzahl Datenbytes
  BinaryCRC:  Byte;     // kann irgendwo stehen
  BinaryValid: boolean;

// ------------------------------ Status-Flags ---------------------------------

  EEUnlocked: Boolean; // EEPROM-unlocked-Flag
  ConfErr:  Boolean;
  SysExCount: Byte;
  SysExActive: Boolean;
  ScanCoreRevision, ScanCoreID: Byte;

// Fehlerkonstanten für SysEx <er>, die falls >0 aufgetretene Fehler
// in einem 8-Bit-Feld anzeigen. Fehler können kombiniert auftreten.
// Bit 0 = SysEx-Befehl unbekannt (nur wenn auf 0 oder 0x33 addressiert, der Rest interessiert nicht)
//         Dieses Bit wird nach Ausgeben des Status wieder gelöscht.
//         Alle anderen sind persistent, bleiben also bis zum Reboot gesetzt.
// Bit 1 = SD-Karte nicht erkannt/fehlerhaft (darf 1 sein, weil nicht immer eine SD-Karte steckt),
//         Datei auf SD nicht gefunden
// Bit 2 = Nicht finalisiert
// Bit 3 = Flash Write/Erase-Fehler, Hardware defekt!
// Bit 4 = Booten der FPGA-Konfiguration oder des ScanCore (MIDI-Interpreter) fehlgeschlagen
// Bit 5 = Update von SD fehlgeschlagen
  ErrFlags: Byte;
// c_err_cmd:       Byte = 0;    // Bit 0 = +1
// c_err_sd:        Byte = 1;    // Bit 1 = +2
// c_err_finalized: Byte = 2;    // Bit 2 = +4
// c_err_flash:     Byte = 3;    // Bit 3 = +8
// c_err_conf:      Byte = 4;    // Bit 4 = +16
// c_err_upd:       Byte = 5;    // Bit 5 = +32
// c_err_busy:      Byte = 6;    // Bit 6 = +64

// -------------------------- zusätzliche Arrays -------------------------------

  // von Parameter-1000 auf Menu-Index für 1000..1511,
  // wird in NB_CreateRestoreArr_InverseArr angelegt

  Param2MenuInverseArray: array[0..511] of byte;

  // Inverse MIDI CC/CH Arrays zum Senden von Parameteränderungen
  CCarray: array[0..1023] of byte; // Dummy für Pointer
  // CCarray_i mit Index [ch, cc]  liefert zugehörige Parameter-Nummer
  CCarray_i[@CCarray + 0]: array[0..3, 0..127] of Integer; // 4 x 128 x 2 = 1024

  MIDIset_Array: array[0..3199] of Byte;  // Dummy für Adresspointer
  MIDIset_CCarray[@MIDIset_Array + 0]: array[0..767] of byte; // Index Param-1000, liefert CC-Nummer
  MIDIset_CHarray[@MIDIset_Array + 768]: array[0..767] of byte; // Index Param-1000, liefert Channel
  MIDIset_CCminArray[@MIDIset_Array + 1536]: array[0..767] of byte; // Index Param-1000, liefert CC-Maximalwert
  MIDIset_CCmaxArray[@MIDIset_Array + 2304]: array[0..751] of byte; // Index Param-1000, liefert CC-Minimalwert
  MIDIset_CCdisplayedName[@MIDIset_Array + 3056]: String[15]; // Angezeigter Name, letzte 15 Bytes!

  // NRPN-Array getrennt von CCs ab Index 3072
  // ValueLong0,1 = NRPN, Funktion = ValueLong2, Channel und Mode = ValueMode3

  // 32 NRPN-Entries aus Edit-Index 0..511 und NRPN-Wert 0..$7F7F
  // t_nrpn_entry = record
  //   EditIdx: Integer;  // verweist auf edit_array 0..511, -1 wenn nicht zugewiesen
  //   NRPN: Integer;     // NRPN MSB/LSB, -1 wenn nicht zugewiesen
  // end;
  MIDIset_NRPNarray[@MIDIset_Array + 3072]: array[0..31] of t_nrpn_entry;
  MIDIset_NRPNarrayLongInt[@MIDIset_Array + 3072]: array[0..31] of LongInt;

  edit_CompareArray: array[0..511] of byte;
  edit_CompareArray_0[@edit_CompareArray]   : array[0..255] of byte;
  edit_CompareArray_1[@edit_CompareArray + 256]   : array[0..255] of byte;

  BlockBuffer8: array[0..4095] of byte;

  // Hilfsarray für Binärbefehle, hier Zweitnutzung:
  BlockArrayBinaryBuf[@BlockBuffer8 + 3328]: array[0..255] of byte;
  // Hilfsarray für Directory, sonst nie benutzt, deshalb hier Zweitnutzung:
  BlockArrayDirFileNames[@BlockBuffer8 + 3584]: array[0..31] of String[15];

  BlockArray256_0[@BlockBuffer8]: array[0..255] of byte;
  BlockArray256_1[@BlockBuffer8 + 256]: array[0..255] of byte;

  Blockarray_w[@BlockBuffer8] : array[0..2047] of word;
  Blockarray_lw[@BlockBuffer8]: array[0..1023] of LongInt;

  // letzte 2 Bytes vor Bootloader ($1F000) = $1EFFE
  BlockArrayFwVersion[@BlockBuffer8 + $FFE]: Word; // Version als HEX

  // Aus Preset direkt gelesene Werte, zur Erstellung des PresetLoadEnableArray
  block_PresetNameStr[@BlockBuffer8 + 192]: String[15];
  block_PresetNameLen[@BlockBuffer8 + 192]: Byte;
  block_CommonPreset[@BlockBuffer8 + 268]:  byte;  // #268, wird nicht bei edit_CommonPreset überschrieben
  block_LogicalTab_H100mode[@BlockBuffer8 + 104]: boolean;
  block_LogicalTab_EGmode[@BlockBuffer8 + 107]: boolean;
// Wird nach Lesen der EEPROM-Datei verglichen mit aktuell
// im EEPROM gespeicherter Versionsnummer:
  BlockArrayEEPROMVersion[@BlockBuffer8 + 36] : Byte;
// Wird nach Lesen eines Presets verglichen mit aktuell
// im EEPROM gespeicherter Versionsnummer:
  BlockArrayPresetVersion[@BlockBuffer8 + 510] : Byte;
  BlockArrayMagicByte[@BlockBuffer8+ 511] : Byte;
  BlockArray_start[@BlockBuffer8]: byte;   // für CopyBlock


implementation

end var_def.


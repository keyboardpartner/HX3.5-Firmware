// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################
// ###          Tabellen für Parameter, Einstellungen und Defaults           ###
// #############################################################################

// Virtuelle Bedienelemente. Jeder Wert hat eine Vergleichskopie _old,
// um Änderungen ermitteln zu können und entsprechende Routinen aufzurufen.

unit edit_changes;

interface
uses var_def;

procedure NewEditIdxEvent(edit_idx: Word; pvalue, event_source: Byte);
procedure FillEventSource(start_idx, count: Word; event_source: Byte);
//procedure FillEditArray(start_idx, count: Word; data: Byte);

// löscht Flags, die in delete_bitmask '1' sind
// procedure MaskEventSource(start_idx, count: Word; delete_bitmask: Byte);

// Index zeigt auf Eintrag in edit_LogicalTabs, 64 Schalterstellungen
function EC_LogicalTabsToByte(const idx: Byte): byte;

// Setzt LogicalTabs ab Index aus Byte (repäsentiert Bit-Array)
procedure EC_ByteToLogicalTabs(const my_tab_byte, idx: Byte);

function EC_LogicalTabs2Word(const idx: Byte): word;


procedure SerPromptErrFlags(const my_subch, my_paramint: Integer);
procedure SerPrompt(const my_Err: byte; const my_subch, my_paramint: Integer);

procedure WriteByteSer(const my_param: byte);
procedure WriteBoolSer(const my_bool: Boolean);
procedure WriteLongSer(const my_param: LongInt);
procedure WriteLongSerHex(const my_param: LongInt);
procedure WriteCommentSer;
procedure WriteSerError;
procedure WriteSerWarning;


var
{$IDATA}

// #############################################################################
// ###                           Edit-Tabelle 1                              ###
// ###                                                                       ###
// ###                               #####                                   ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                               #####                                   ###
// ###                                                                       ###
// ###              Gleiche Reihenfolge wie eep_defaults_0                   ###
// #############################################################################

// "Virtuelle" Bedienelemente (Schalter und Analogwerte)
// Alle Änderungen seitens Bedienelemente werden hier eingetragen und das
// gleichnamige Flags-Byte auf aktuellen Sender gesetzt.

  edit_array: Array[0..511] of byte; // Gesamt-Array änderbarer Parameter 1000..1511

  edit_table_0[@edit_array + 0]: Table[0..255] of byte;

// #############################################################################
// Drawbar-Voices, nur für Live und EEPROM
// #############################################################################

// @0, #1000 Upper Drawbars
  edit_UpperDBs[@edit_table_0 + 0]: Array [0..15] of byte;
    edit_UpperDB_1[@edit_UpperDBs + 8]:byte;       // für Percussion gebraucht

// @16, #1016 Lower Drawbars
  edit_LowerDBs[@edit_table_0 + 16]: Array [0..15] of byte;

// @32, #1032 Pedal Drawbars
  edit_PedalDBs[@edit_table_0 + 32]: Array[0..15] of byte;
    edit_PedalDB_16[@edit_PedalDBs + 0]:     byte;  // #1032
    edit_PedalDB_5_13[@edit_PedalDBs + 1]:   byte;
    edit_PedalDB_8[@edit_PedalDBs + 2]:      byte;
    edit_PedalDB_4[@edit_PedalDBs + 3]:      byte;
    edit_PedalDB_2_23[@edit_PedalDBs + 4]:   byte;
    edit_PedalDB_2[@edit_PedalDBs + 5]:      byte;
    edit_PedalDB_1_35[@edit_PedalDBs + 6]:   byte;
    edit_PedalDB_1_23[@edit_PedalDBs + 7]:   byte;
    edit_PedalDB_1[@edit_PedalDBs + 8]:      byte;
    edit_PedalDB_mixt1[@edit_PedalDBs + 9]:  byte;
    edit_PedalDB_mixt2[@edit_PedalDBs + 10]: byte;
    edit_PedalDB_mixt3[@edit_PedalDBs + 11]: byte;

// Parameter ADSR in Reihenfolge der FPGA-LC-Werte!
// @48, #1048
  edit_ADSR[@edit_table_0 + 48]: Array[0..23] of Byte;
    edit_UpperADSR[@edit_ADSR + 0]: Array[0..7] of Byte;
      edit_UpperAttack[@edit_UpperADSR + 0]:        Byte; // #420
      edit_UpperDecay[@edit_UpperADSR + 1]:         Byte; // #421
      edit_UpperSustain[@edit_UpperADSR + 2]:       Byte; // #422
      edit_UpperRelease[@edit_UpperADSR + 3]:       Byte; // #423
      edit_UpperADSRharmonics[@edit_ADSR + 4]:      Byte; // #426 Oberton-Zerfall

// @56, #1056
    edit_LowerADSR[@edit_ADSR + 8]: Array[0..7] of Byte;
      edit_LowerAttack[@edit_LowerADSR + 0]:        Byte; // #520
      edit_LowerDecay[@edit_LowerADSR + 1]:         Byte; // #521
      edit_LowerSustain[@edit_LowerADSR + 2]:       Byte; // #522
      edit_LowerRelease[@edit_LowerADSR + 3]:       Byte; // #523
      edit_LowerADSRharmonics[@edit_LowerADSR + 4]: byte; // #526 Oberton-Zerfall

// @64, #1064
    edit_PedalADSR[@edit_ADSR + 16]: Array[0..7] of byte;
      edit_PedalAttack[@edit_PedalADSR + 0]:        byte; // #620
      edit_PedalDecay[@edit_PedalADSR + 1]:         byte; // #621
      edit_PedalSustain[@edit_PedalADSR + 2]:       byte; // #622
      edit_PedalRelease[@edit_PedalADSR + 3]:       byte; // #623
      edit_PedalADSRharmonics[@edit_PedalADSR + 4]: byte; // #626 Oberton-Zerfall

// @72, #1072
  edit_PedalDB4s[@edit_table_0 + 72]: Array[0..3] of byte;
    edit_PedalDB_B3_16[@edit_PedalDB4s + 0]: byte;  // für MIDI und Hammond,
    edit_PedalDB_B3_16H[@edit_PedalDB4s + 1]:byte;  // werden später umgerechnet
    edit_PedalDB_B3_8[@edit_PedalDB4s + 2]:  byte;  // und auf 11 Drawbars verteilt
    edit_PedalDB_B3_8H[@edit_PedalDB4s + 3]: byte;  //

// @76, #1076
  edit_Wheels[@edit_table_0 + 76]: Array[0..3] of byte;
    edit_Wheel_PitchToMIDI[@edit_Wheels + 0]: byte; // Pitchwheel MIDI Send
    edit_Wheel_PitchRotary[@edit_Wheels + 1]: byte; // Pitchwheel Rotary Control
    edit_Wheel_ModToMIDI[@edit_Wheels + 2]: byte;   // Modwheel MIDI Send
    edit_Wheel_ModRotary[@edit_Wheels + 3]: byte;   // Modwheel Rotary Control

// @80 #1080 ff. AO28/Preamp/Audio/Routing Group
  edit_PreampGroup[@edit_table_0 + 80]: Array[0..15] of byte;
    edit_MasterVolume[@edit_PreampGroup + 0]:   byte;       //  + 00
    edit_LeslieVolume[@edit_PreampGroup + 1]:   byte;       //  + 01
    edit_UpperVolumeWet[@edit_PreampGroup + 2]: byte;       //  + 02
    edit_LowerVolume[@edit_PreampGroup + 3]:    byte;       //  + 03
    edit_PedalVolume[@edit_PreampGroup + 4]:    byte;       //  + 04
    edit_UpperVolumeDry[@edit_PreampGroup + 5]: byte;       //  + 05
    edit_OverallReverb[@edit_PreampGroup + 6]: byte;      //  + 06
    edit_TonePot[@edit_PreampGroup + 7]:      byte;         //  + 07
    edit_TrimSwell[@edit_PreampGroup + 8]:      byte;       //  + 08
    edit_MinimalSwell[@edit_PreampGroup + 9]:   byte;       //  + 09
    edit_Triode_k2[@edit_PreampGroup + 10]:     byte;       //  + 10

    edit_ModuleRevVolume[@edit_PreampGroup + 11]:byte;    //  + 91
    edit_ModuleEfxVolume[@edit_PreampGroup + 12]:byte;    //  + 92
    edit_ModuleSwellVolume[@edit_PreampGroup + 13]:   byte;       //  + 93
    edit_ModuleFrontVolume[@edit_PreampGroup + 14]:   byte;       //  + 94
    edit_ModuleRearVolume[@edit_PreampGroup + 15]:   byte;        //  + 95

// @96, #1096 ff. getrennte DBs für elektronische Tastenkontakte mit ADSR, Upper
  edit_UpperEnvelopeDBs[@edit_table_0 + 96]:Array[0..15] of byte;
    edit_UpperEnvelopeDB_16[@edit_UpperEnvelopeDBs + 0]:     byte;
    edit_UpperEnvelopeDB_5_13[@edit_UpperEnvelopeDBs + 1]:   byte;
    edit_UpperEnvelopeDB_8[@edit_UpperEnvelopeDBs + 2]:      byte;
    edit_UpperEnvelopeDB_4[@edit_UpperEnvelopeDBs + 3]:      byte;
    edit_UpperEnvelopeDB_2_23[@edit_UpperEnvelopeDBs + 4]:   byte;
    edit_UpperEnvelopeDB_2[@edit_UpperEnvelopeDBs + 5]:      byte;
    edit_UpperEnvelopeDB_1_35[@edit_UpperEnvelopeDBs + 6]:   byte;
    edit_UpperEnvelopeDB_1_23[@edit_UpperEnvelopeDBs + 7]:   byte;
    edit_UpperEnvelopeDB_1[@edit_UpperEnvelopeDBs + 8]:      byte;
    edit_UpperEnvelopeDB_mixt1[@edit_UpperEnvelopeDBs + 9]:  byte;
    edit_UpperEnvelopeDB_mixt2[@edit_UpperEnvelopeDBs + 10]: byte;
    edit_UpperEnvelopeDB_mixt3[@edit_UpperEnvelopeDBs + 11]: byte;

// @112, #1112 Parametrischer 3-Band-EQ
  edit_EqualizerGroup[@edit_table_0 + 112]:Array[0..15] of byte;
    edit_EqualizerBass    [@edit_EqualizerGroup  + 0]: byte;
    edit_EqualizerBassFreq[@edit_EqualizerGroup  + 1]: byte;
    edit_EqualizerBassPeak[@edit_EqualizerGroup  + 2]: byte;

    edit_EqualizerMid     [@edit_EqualizerGroup  + 3]: byte;
    edit_EqualizerMidFreq [@edit_EqualizerGroup  + 4]: byte;
    edit_EqualizerMidPeak [@edit_EqualizerGroup  + 5]: byte;

    edit_EqualizerTreble    [@edit_EqualizerGroup  + 6]: byte;
    edit_EqualizerTrebleFreq[@edit_EqualizerGroup  + 7]: byte;
    edit_EqualizerTreblePeak[@edit_EqualizerGroup  + 8]: byte;

    edit_EqualizerFullParametric[@edit_EqualizerGroup  + 9]: boolean;
    edit_ModuleExtRotaryLeft[@edit_EqualizerGroup  + 10]: Byte;
    edit_ModuleExtRotaryRight[@edit_EqualizerGroup  + 11]: Byte;

  edit_PotDetentShiftGroup[@edit_table_0 + 124]: Array[0..3] of byte;
    edit_EquBassDetentShift[@edit_PotDetentShiftGroup + 0]:     byte;
    edit_EquMidDetentShift[@edit_PotDetentShiftGroup + 1]: byte;
    edit_EquTrebleDetentShift[@edit_PotDetentShiftGroup + 2]: byte;
    edit_PercVolDetentShift[@edit_PotDetentShiftGroup + 3]:  byte;

// @128..191, #1128..1191 im Parser reserviert für Boolean Tabs
// Tabs 0-7, #1128 ff.
  edit_LogicalTabs[@edit_table_0 + 128]: Array[0..63] of boolean;
    edit_LogicalTab_PercOn    [@edit_LogicalTabs + 0] : Boolean; // Perc ON, Reihenfolge wie B3
    edit_LogicalTab_PercSoft  [@edit_LogicalTabs + 1] : Boolean; // Perc SOFT (NORMAL)
    edit_LogicalTab_PercFast  [@edit_LogicalTabs + 2] : Boolean; // Perc FAST (SLOW)
    edit_LogicalTab_Perc3rd   [@edit_LogicalTabs + 3] : Boolean; // Perc THIRD (SECOND)
    edit_LogicalTab_VibOnUpper[@edit_LogicalTabs + 4] : Boolean; // Vib ON upper
    edit_LogicalTab_VibOnLower[@edit_LogicalTabs + 5] : Boolean; // Vib ON lower
    edit_LogicalTab_LeslieRun [@edit_LogicalTabs + 6] : Boolean; // Leslie Slow
    edit_LogicalTab_LeslieFast[@edit_LogicalTabs + 7] : Boolean; // Leslie Fast

// Tabs 8-15, #1136 ff.
    edit_LogicalTab_TubeAmpBypass[@edit_LogicalTabs + 8]  : Boolean;  // Insert Tube Amp
    edit_LogicalTab_RotarySpkrBypass[@edit_LogicalTabs + 9] : Boolean; // Insert Seaker Sim
    edit_LogicalTab_PHRupperOn[@edit_LogicalTabs + 10] : Boolean; // Insert PHR upper
    edit_LogicalTab_PHRlowerOn[@edit_LogicalTabs + 11] : Boolean; // Insert PHR lower

    edit_LogicalTab_Reverb1   [@edit_LogicalTabs + 12] : Boolean; // Effekt 1
    edit_LogicalTab_Reverb2   [@edit_LogicalTabs + 13] : Boolean; // Effekt 2
    edit_LogicalTab_PedalPostMix  [@edit_LogicalTabs + 14] : Boolean; // Bass on Amp enable
    edit_LogicalTab_SplitOn   [@edit_LogicalTabs + 15] : Boolean; // Split Lower

// Tabs 16-23, #1144 ff.
    edit_LogicalTab_PHR_WersiBoehm[@edit_LogicalTabs + 16]   : Boolean;  // Böhm Phasing Rotor
    edit_LogicalTab_PHR_Ensemble[@edit_LogicalTabs + 17]: Boolean;
    edit_LogicalTab_PHR_Celeste[@edit_LogicalTabs + 18] : Boolean;
    edit_LogicalTab_PHR_Fading[@edit_LogicalTabs + 19]  : Boolean;
    edit_LogicalTab_PHR_Weak[@edit_LogicalTabs + 20]    : Boolean;
    edit_LogicalTab_PHR_Deep[@edit_LogicalTabs + 21]    : Boolean;
    edit_LogicalTab_PHR_Fast[@edit_LogicalTabs + 22]    : Boolean;
    edit_LogicalTab_PHR_Delay[@edit_LogicalTabs + 23]   : Boolean;

// Tabs 24-31, #1152 ff.
  edit_LogicalTabs_KeyingModes[@edit_LogicalTabs + 24]: Array[0..7] of Boolean;
    edit_LogicalTab_H100_Mode[@edit_LogicalTabs + 24]: boolean;       // H100 Percussion statt B3
    edit_LogicalTab_EG_Mode[@edit_LogicalTabs + 25]: boolean;         // Electronic Gating Mode, Attack-Release, Enables => Percussion, ADSR
    edit_LogicalTab_EG_PercMode[@edit_LogicalTabs + 26]: boolean;     // Electronic Gating Mode, EG Drawbars sind Percussion
    edit_LogicalTab_EG_TimeBendMode[@edit_LogicalTabs + 27]: boolean; // Electronic Gating Mode, EG Drawbars sind TimeBend DBs
    edit_LogicalTab_H100_2ndVoice[@edit_LogicalTabs + 28]: boolean;   // H100 Perc Bypass (2nd Voice)
    edit_LogicalTab_H100_HarpSustain[@edit_LogicalTabs + 29]: boolean;// H100 HarpSustain voice on DB 8'
    edit_LogicalTab_EG_mask2dry[@edit_LogicalTabs + 30]: boolean;     // Electronic Gating Option, Enables => Fußlagen auf Dry
    edit_LogicalTab_EqualizerBypass[@edit_LogicalTabs + 31]: boolean;

// Tabs 32-43, #1160 ff.
  edit_LogicalTab_UpperDBtoADSR[@edit_LogicalTabs + 32]: Array[0..15] of Boolean;   // Upper BBs to ADSRs
    edit_LogicalTab_UpperDB0toADSR[@edit_LogicalTab_UpperDBtoADSR + 0]  : Boolean;  // Upper BBs to ADSRs
    edit_LogicalTab_UpperDB1toADSR[@edit_LogicalTab_UpperDBtoADSR + 1]  : Boolean;  //
    edit_LogicalTab_UpperDB2toADSR[@edit_LogicalTab_UpperDBtoADSR + 2]  : Boolean;  //
    edit_LogicalTab_UpperDB3toADSR[@edit_LogicalTab_UpperDBtoADSR + 3]  : Boolean;  //
    edit_LogicalTab_UpperDB4toADSR[@edit_LogicalTab_UpperDBtoADSR + 4]  : Boolean;  //
    edit_LogicalTab_UpperDB5toADSR[@edit_LogicalTab_UpperDBtoADSR + 5]  : Boolean;  //
    edit_LogicalTab_UpperDB6toADSR[@edit_LogicalTab_UpperDBtoADSR + 6]  : Boolean;  //
    edit_LogicalTab_UpperDB7toADSR[@edit_LogicalTab_UpperDBtoADSR + 7]  : Boolean;  //
    edit_LogicalTab_UpperDB8toADSR[@edit_LogicalTab_UpperDBtoADSR + 8]  : Boolean;  //
    edit_LogicalTab_UpperDB9toADSR[@edit_LogicalTab_UpperDBtoADSR + 9]  : Boolean;  //
    edit_LogicalTab_UpperDB10toADSR[@edit_LogicalTab_UpperDBtoADSR + 10] : Boolean;  //
    edit_LogicalTab_UpperDB11toADSR[@edit_LogicalTab_UpperDBtoADSR + 11] : Boolean;  // #1171

// Tabs 44-47, #1172 ff. Swap DACs und 2 Tabs Transpose Up/Down, OctaveShift Upper/Lower
  edit_LogicalTab_ShiftBtns[@edit_LogicalTabs + 44]: Array[0..3] of Boolean;
    edit_LogicalTab_SwapDACs[@edit_LogicalTab_ShiftBtns + 0] :  Boolean; // #1172
    edit_LogicalTab_Shift_upper[@edit_LogicalTab_ShiftBtns + 2] :  Boolean; // #1174
    edit_LogicalTab_Shift_lower[@edit_LogicalTab_ShiftBtns + 3] : Boolean;  // #1175

// Tabs 48-63, #1176 ff.
  edit_LogicalTab_LowerDBtoADSR[@edit_LogicalTabs + 48]: Array[0..11] of Boolean;  // Lower BBs to ADSRs
    edit_LogicalTab_LowerDB0toADSR[@edit_LogicalTab_LowerDBtoADSR + 0]  : Boolean;  // Lower BBs to ADSRs
    edit_LogicalTab_LowerDB1toADSR[@edit_LogicalTab_LowerDBtoADSR + 1]  : Boolean;  //
    edit_LogicalTab_LowerDB2toADSR[@edit_LogicalTab_LowerDBtoADSR + 2]  : Boolean;  //
    edit_LogicalTab_LowerDB3toADSR[@edit_LogicalTab_LowerDBtoADSR + 3]  : Boolean;  //
    edit_LogicalTab_LowerDB4toADSR[@edit_LogicalTab_LowerDBtoADSR + 4]  : Boolean;  //
    edit_LogicalTab_LowerDB5toADSR[@edit_LogicalTab_LowerDBtoADSR + 5]  : Boolean;  //
    edit_LogicalTab_LowerDB6toADSR[@edit_LogicalTab_LowerDBtoADSR + 6]  : Boolean;  //
    edit_LogicalTab_LowerDB7toADSR[@edit_LogicalTab_LowerDBtoADSR + 7]  : Boolean;  //
    edit_LogicalTab_LowerDB8toADSR[@edit_LogicalTab_LowerDBtoADSR + 8]  : Boolean;  //
    edit_LogicalTab_LowerDB9toADSR[@edit_LogicalTab_LowerDBtoADSR + 9]  : Boolean;  //
    edit_LogicalTab_LowerDB10toADSR[@edit_LogicalTab_LowerDBtoADSR + 10] : Boolean;  //
    edit_LogicalTab_LowerDB11toADSR[@edit_LogicalTab_LowerDBtoADSR + 11] : Boolean;  //


// ab #1192 Momentary Buttons, nicht gespeichert
// Dieser Bereich ist im Preset mit seinem Namen belegt!
  edit_TempStr[@edit_table_0 + 192]: String[15];
  edit_LogicalTab_IncDecBtns[@edit_table_0 + 192]: Array[0..15] of Boolean;
    edit_LogicalTab_DecPreset[@edit_LogicalTab_IncDecBtns + 0] :  Boolean;  // #1192
    edit_LogicalTab_IncPreset[@edit_LogicalTab_IncDecBtns + 1] :  Boolean;  // #1193
    edit_LogicalTab_DecUpperVoice[@edit_LogicalTab_IncDecBtns + 2]:  Boolean;  // #1194
    edit_LogicalTab_IncUpperVoice[@edit_LogicalTab_IncDecBtns + 3]:  Boolean;  // #1195
    edit_LogicalTab_DecLowerVoice[@edit_LogicalTab_IncDecBtns + 4]:  Boolean;  // #1196
    edit_LogicalTab_IncLowerVoice[@edit_LogicalTab_IncDecBtns + 5]:  Boolean;  // #1197
    edit_LogicalTab_DecPedalVoice[@edit_LogicalTab_IncDecBtns + 6]:  Boolean;  // #1198
    edit_LogicalTab_IncPedalVoice[@edit_LogicalTab_IncDecBtns + 7]:  Boolean;  // #1199
    edit_LogicalTab_DecOrganModel[@edit_LogicalTab_IncDecBtns + 8]:  Boolean;  // #1200
    edit_LogicalTab_IncOrganModel[@edit_LogicalTab_IncDecBtns + 9]:  Boolean;  // #1201
    edit_LogicalTab_DecSpeakerModel[@edit_LogicalTab_IncDecBtns + 10]: Boolean; // #1202
    edit_LogicalTab_IncSpeakerModel[@edit_LogicalTab_IncDecBtns + 11]: Boolean; // #1203
    edit_LogicalTab_DecTranspose[@edit_LogicalTab_IncDecBtns + 12]:  Boolean;  // #1204
    edit_LogicalTab_IncTranspose[@edit_LogicalTab_IncDecBtns + 13]:  Boolean;  // #1205

  edit_LogicalTab_Specials[@edit_table_0 + 208]: Array[0..3] of Boolean;
    edit_HammondUprDecode[@edit_LogicalTab_Specials + 0] :  Byte; // #1208
    edit_HammondLwrDecode[@edit_LogicalTab_Specials + 1] :  Byte; // #1208
    edit_HammondPedDecode[@edit_LogicalTab_Specials + 2] :  Byte; // #1208
    edit_HammondVibKnobDecode[@edit_LogicalTab_Specials + 3] :  Byte; // #1208

  edit_LogicalTab_VibBtns[@edit_table_0 + 212]: Array[0..3] of Boolean;
    edit_LogicalTab_4V1[@edit_LogicalTab_VibBtns + 0] :  Boolean;  // #1212
    edit_LogicalTab_4V2[@edit_LogicalTab_VibBtns + 1] :  Boolean;  // #1213
    edit_LogicalTab_4V3[@edit_LogicalTab_VibBtns + 2] :  Boolean;  // #1214
    edit_LogicalTab_4VCh[@edit_LogicalTab_VibBtns + 3] : Boolean;  // #1215
    // doppelt belegt!
    edit_LogicalTab_6V1[@edit_LogicalTab_VibBtns + 0] :  Boolean;  // #1212
    edit_LogicalTab_6C1[@edit_LogicalTab_VibBtns + 1] :  Boolean;  // #1213
    edit_LogicalTab_6V2[@edit_LogicalTab_VibBtns + 2] :  Boolean;  // #1214
    edit_LogicalTab_6C2[@edit_LogicalTab_VibBtns + 3] : Boolean;  // #1215
    edit_LogicalTab_6V3[@edit_LogicalTab_VibBtns + 4] : Boolean;   // #1216
    edit_LogicalTab_6C3[@edit_LogicalTab_VibBtns + 5] : Boolean;   // #1217

  edit_LogicalTab_SingleDBdestBtns[@edit_table_0 + 218]: Array[0..3] of Byte;
    edit_SingleDBtoggle[@edit_table_0 + 218]:  Boolean;    // #1218
    edit_SingleDBtoUpper[@edit_table_0 + 219]: Boolean;    // #1219
    edit_SingleDBtoLower[@edit_table_0 + 220]: Boolean;    // #1220
    edit_SingleDBtoPedal[@edit_table_0 + 221]: Boolean;    // #1221

// 224 ff.
  edit_GMprogs[@edit_table_0 + 224]: Array[0..23] of byte;
    edit_UpperGMprg_0[@edit_GMprogs + 0]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_UpperGMlvl_0[@edit_GMprogs + 1]: byte; // GM Layer 1 Level
    edit_UpperGMharm_0[@edit_GMprogs + 2]: Byte; // Harmonic Transpose Layer 1
    edit_UpperGMprg_1[@edit_GMprogs + 3]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_UpperGMlvl_1[@edit_GMprogs + 4]: byte; // GM Layer 2 Level
    edit_UpperGMharm_1[@edit_GMprogs + 5]: Byte; // Harmonic Transpose Layer 2
    edit_UpperGMdetune_1[@edit_GMprogs + 6]: Byte; // Detune Layer 2
// 232 ff.
    edit_LowerGMprg_0[@edit_GMprogs + 8]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_LowerGMlvl_0[@edit_GMprogs + 9]: byte; // GM Layer 1 Level
    edit_LowerGMharm_0[@edit_GMprogs + 10]: Byte; // Harmonic Transpose Layer 1
    edit_LowerGMprg_1[@edit_GMprogs + 11]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_LowerGMlvl_1[@edit_GMprogs + 12]: byte; // GM Layer 2 Level
    edit_LowerGMharm_1[@edit_GMprogs + 13]: Byte; // Harmonic Transpose Layer 2
    edit_LowerGMdetune_1[@edit_GMprogs + 14]: Byte; // Detune Layer 2
// 240 ff.
    edit_PedalGMprg_0[@edit_GMprogs + 16]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_PedalGMlvl_0[@edit_GMprogs + 17]: byte; // GM Layer 1 Level
    edit_PedalGMharm_0[@edit_GMprogs + 18]: Byte; // Harmonic Transpose Layer 1
    edit_PedalGMprg_1[@edit_GMprogs + 19]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_PedalGMlvl_1[@edit_GMprogs + 20]: byte; // GM Layer 2 Level
    edit_PedalGMharm_1[@edit_GMprogs + 21]: Byte; // Harmonic Transpose Layer 2
    edit_PedalGMdetune_1[@edit_GMprogs + 22]: Byte; // Detune Layer 2


// #############################################################################
// ###                           Edit-Tabelle 1                              ###
// ###                                                                       ###
// ###                                 ##                                    ###
// ###                               ####                                    ###
// ###                                 ##                                    ###
// ###                                 ##                                    ###
// ###                                 ##                                    ###
// ###                               #####                                   ###
// ###                                                                       ###
// ###              Gleiche Reihenfolge wie eep_defaults_1                   ###
// #############################################################################

// ab hier in/aus EEPROM oder DF kopiert, Param  + 1256

  edit_table_1[@edit_array + 256]: Table[0..255] of byte;
  edit_table_1_start[@edit_table_1]: byte;

// @0..7, #1256 frei

  edit_knobs[@edit_table_1 + 4]: Array[0..7] of byte; // #1260
    edit_GatingKnob[@edit_knobs + 1]: Byte;    // #1261
    edit_PercKnob[@edit_knobs + 2]:   Byte;    // #1262
    edit_ReverbKnob[@edit_knobs + 3]: Byte;    // #1263
    edit_VibKnob[@edit_knobs + 4]:    Byte;    // #1264
    edit_OrganModel[@edit_knobs + 5]: byte;    // #1265
    edit_SpeakerModel[@edit_knobs + 6]:byte;    // #1266

// @12, #1268 ff. Voices und Presets
  edit_voices[@edit_table_1 + 12]: Array[0..3] of byte;
    edit_CommonPreset[@edit_voices + 0]: byte;
    edit_UpperVoice[@edit_voices + 1]: byte;
    edit_LowerVoice[@edit_voices + 2]: byte;
    edit_PedalVoice[@edit_voices + 3]: byte;

// #############################################################################

// @16, #1272 Busbar Levels
  edit_BusbarLevels[@edit_table_1 + 16]: Array[0..15] of byte;

// Zur Erzeugung der Keymap-Tabelle, Offsets aus Orgel-Tabellen
// @32, #1288
  edit_BusBarNoteOffsets[@edit_table_1 + 32]: Array [0..15] of byte;

// @64, #1320 Hammond-Vibrato
  edit_VibratoGroup[@edit_table_1 + 64]: Array[0..15] of byte;
    edit_VibChPreEmphasis[@edit_VibratoGroup + 0]:   byte;   // #1320
    edit_VibChLineAgeAM[@edit_VibratoGroup + 1]:     byte;   // #1321
    edit_VibChFeedback[@edit_VibratoGroup + 2]:      byte;   // #1322
    edit_VibChReflection[@edit_VibratoGroup + 3]:    byte;   // #1323
    edit_VibChRespCutoff[@edit_VibratoGroup + 4]:    byte;   // #1324
    edit_PhaseLk_Shelving[@edit_VibratoGroup + 5]:   byte;   // #1325
    edit_ScannerGearing[@edit_VibratoGroup + 6]:     byte;   // #1326
    edit_ChorusBypassLevel[@edit_VibratoGroup + 7]:  byte;   // #1327
    edit_ChorusScannerLevel[@edit_VibratoGroup + 8]: byte;   // #1328
    edit_VibMods[@edit_VibratoGroup + 9]: Array[0..2] of  byte;
      edit_CV1mod[@edit_VibratoGroup + 9]:           byte;   // #1329
      edit_CV2mod[@edit_VibratoGroup + 10]:          byte;   // #1330
      edit_CV3mod[@edit_VibratoGroup + 11]:          byte;   // #1331
    edit_ChorusEnhance[@edit_VibratoGroup + 12]:     byte;   // #1332
    edit_SegmentFlutter[@edit_VibratoGroup + 13]:    byte;   // #1333
    edit_PreemphCutoff[@edit_VibratoGroup + 14]:     byte;   // #1334
    edit_PreemphPhase[@edit_VibratoGroup + 15]:      byte;   // #1335

// @80, #1336..#1351 TEMP!
// Phasing Rotor, Reihenfolge wie FPGA, temporär aus PHR-Preset geladen
// im Edit-Bereich für PHR-Programmerstellung über Editor
  edit_PhasingGroup[@edit_table_1 + 80]:Array[0..15] of byte;
    edit_PHR_SpeedVariSlow[@edit_PhasingGroup + 0]:     byte;   // #1336
    edit_PHR_SpeedVariFast[@edit_PhasingGroup + 1]:     byte;   // #1337
    edit_PHR_SpeedSlow[@edit_PhasingGroup + 2]:         byte;
    edit_PHR_Feedback[@edit_PhasingGroup + 3]:          byte;
    edit_PHR_LevelPh1[@edit_PhasingGroup + 4]:          byte;
    edit_PHR_LevelPh2[@edit_PhasingGroup + 5]:          byte;
    edit_PHR_LevelPh3[@edit_PhasingGroup + 6]:          byte;
    edit_PHR_LevelDry[@edit_PhasingGroup + 7]:          byte;
    edit_PHR_FeedBackInvert[@edit_PhasingGroup + 8]:    byte;
    edit_PHR_RampDelay[@edit_PhasingGroup + 9]:         byte;
    edit_PHR_ModVariPh1[@edit_PhasingGroup + 10]:       byte;
    edit_PHR_ModVariPh2[@edit_PhasingGroup + 11]:       byte;
    edit_PHR_ModVariPh3[@edit_PhasingGroup + 12]:       byte;
    edit_PHR_ModSlowPh1[@edit_PhasingGroup + 13]:       byte;
    edit_PHR_ModSlowPh2[@edit_PhasingGroup + 14]:       byte;
    edit_PHR_ModSlowPh3[@edit_PhasingGroup + 15]:       byte;


// @96, #1352 ff. Keyboard control
  edit_KeyboardGroup[@edit_table_1 + 96]: Array[0..15] of byte;
    edit_PedalCoupler[@edit_KeyboardGroup + 0]:   byte;     //  + 96  #1352
    edit_SplitPoint[@edit_KeyboardGroup + 1]:    byte;      //  + 97  #1353
    edit_SplitMode[@edit_KeyboardGroup + 2]:     byte;      //  + 98  #1354
    edit_KeyTranspose[@edit_KeyboardGroup + 3]:  byte;      //  + 99  #1355
    edit_EarlyKeyCont[@edit_KeyboardGroup + 4]:  boolean;   //  + 100 #1356
    edit_NoDB1_atPerc[@edit_KeyboardGroup + 5]:  boolean;   //  + 101 #1357
    edit_DB16_FoldbMode[@edit_KeyboardGroup + 6]:byte;      //  + 102 #1358
    edit_HighFoldbackOn[@edit_KeyboardGroup + 7]: boolean;  //  + 103 #1359
    edit_ContSpringFlx[@edit_KeyboardGroup + 8]: byte;      //  + 104 #1360
    edit_ContSpringDmp[@edit_KeyboardGroup + 9]: byte;      //  + 105 #1361
    edit_PercEnaOnLiveDBonly[@edit_KeyboardGroup + 10]:    boolean; // keine B3-Perc auf Presets
    edit_FatarVelocityFac[@edit_KeyboardGroup + 11]: byte;  //  + 107 #1363


// @112, #1368 MIDI
  edit_MidiGroup[@edit_table_1 + 112]: Array[0..15] of byte;
    edit_MIDI_Channel[@edit_MidiGroup + 0]:      byte;      // #1368
    edit_MIDI_Option[@edit_MidiGroup + 1]:       byte;
    edit_MIDI_CC_Set[@edit_MidiGroup + 2]:       byte;
    edit_SwellCC[@edit_MidiGroup + 3]:           byte;
    edit_VolumeCC[@edit_MidiGroup + 4]:          byte;
    edit_LocalEnable[@edit_MidiGroup + 5]:       byte;      // #1373
    edit_PresetCC[@edit_MidiGroup + 6]:          byte;      // #1374
    edit_ShowCC[@edit_MidiGroup + 7]:            boolean;   // #1375
    edit_MIDI_DisableProgramChange[@edit_MidiGroup + 8]: Boolean; // #1376
    edit_MIDI_EnaVK77sysex[@edit_MidiGroup + 9]: Boolean; // #1377

// @128, #1384 Generator
  edit_GeneratorGroup[@edit_table_1 + 128]: Array[0..15] of byte;
    edit_PreampSwellType[@edit_GeneratorGroup + 0]:     byte;  // #1384
    edit_TG_TuningSet[@edit_GeneratorGroup + 1]:        byte;  // #1385
    edit_TG_Size[@edit_GeneratorGroup + 2]:             byte;  // #1386
    edit_TG_FixedTaperVal[@edit_GeneratorGroup + 3]:    byte;  // #1387
    edit_TG_WaveSet[@edit_GeneratorGroup + 4]:          byte;  // #1388
    edit_TG_Flutter[@edit_GeneratorGroup + 5]:          byte;  // #1389
    edit_TG_Leakage[@edit_GeneratorGroup + 6]:          byte;  // #1390
    edit_TG_Tuning[@edit_GeneratorGroup + 7]:           byte;  // #1391 A 440 = 7 (433 .. 447 Hz)
    edit_TG_TaperCaps[@edit_GeneratorGroup + 8]:        byte;  // #1392 CapSet
    edit_TG_FilterFac[@edit_GeneratorGroup + 9]:        byte;  // #1393 LC Filters cutoff
    edit_TG_First16TaperVal[@edit_GeneratorGroup + 10]: byte;  // #1394
    edit_GenTranspose[@edit_GeneratorGroup + 11]:       byte;  // #1395
    edit_GeneratorModelLimit[@edit_GeneratorGroup + 12]: byte; // #1396
  edit_Audio_Enables[@edit_GeneratorGroup + 13]: Array[0..2] of Boolean;
    edit_EnableUpperAudio[@edit_GeneratorGroup + 13]: Boolean; // #1397
    edit_EnableLowerAudio[@edit_GeneratorGroup + 14]: Boolean; // #1398
    edit_EnablePedalAudio[@edit_GeneratorGroup + 15]: Boolean; // #1399

// @144, #1400 Effects & Reverb control
  edit_EffectsGroup[@edit_table_1 + 144]:Array[0..7] of byte;
    edit_ReverbLevels[@edit_EffectsGroup + 0]:Array[0..2] of byte;
      edit_ReverbLevel_1[@edit_ReverbLevels + 0]:       byte;
      edit_ReverbLevel_2[@edit_ReverbLevels + 1]:       byte;
      edit_ReverbLevel_3[@edit_ReverbLevels + 2]:       byte;

// @152, #1408 ff. ReadOnly/MenuList Items
  edit_MenuListItems[@edit_table_1 + 152]: Array[0..7] of Byte;
// @154, #1410 PhasingProgram
    edit_CurrentMixtureSet[@edit_MenuListItems + 0]:     byte; // #1408
    edit_CurrentVibratoSet[@edit_MenuListItems + 1]:     byte; // #1409
    edit_CurrentPhasingSet[@edit_MenuListItems + 2]:    byte;  // #1410
    // edit_MenuPercMode[@edit_MenuListItems + 3]: Byte;        // #1411 Perc Select
    // edit_MenuReverbMode[@edit_MenuListItems + 4]: Byte;      // #1412 Reverb Select

// Drawbar-zu-Busbar-Mapping
// Es kann ein Busbar-Pegel nur EINEM Zugriegel zugeordnet werden!
// Wert > 0 ist gleichzeitig Flag, dass dieser Busbar schon einem DB zugeordnet ist.
// Er wird dann keinem anderem mehr zugewiesen.
// DB10 ist vorrangig vor DB11, DB11 ist vorrangig vor DB12
// Drawbar-zu-Busbar-Mapping, 10. Zugriegel (erster nach 1')
// Folge 9, 10, 11, 12, 13, 14 -- -- Anteile Drawbar an Busbar-#
// @160, #1416
  edit_MixtureSets[@edit_table_1 + 160]:Array[0..23] of byte;
  edit_DB10_MixtureSet[@edit_MixtureSets + 0]:Array[0..7] of byte;
  edit_DB11_MixtureSet[@edit_MixtureSets + 8]:Array[0..7] of byte;
  edit_DB12_MixtureSet[@edit_MixtureSets + 16]:Array[0..7] of byte;

// @192, #1448 ff. Rotary live control
  edit_RotaryGroup[@edit_table_1 + 192]:Array[0..15] of byte;
    edit_HornSlowTm[@edit_RotaryGroup + 0]:             byte;
    edit_RotorSlowTm[@edit_RotaryGroup + 1]:            byte;
    edit_HornFastTm[@edit_RotaryGroup + 2]:             byte;
    edit_RotorFastTm[@edit_RotaryGroup + 3]:            byte;
    edit_HornRampUp[@edit_RotaryGroup + 4]:             byte;
    edit_RotorRampUp[@edit_RotaryGroup + 5]:            byte;
    edit_HornRampDown[@edit_RotaryGroup + 6]:           byte;
    edit_RotorRampDown[@edit_RotaryGroup + 7]:          byte;
  edit_RotaryGroup_DB[@edit_RotaryGroup + 8]:Array[0..2] of byte;
    edit_LeslieThrob[@edit_RotaryGroup + 8]:            byte;
    edit_LeslieSpread[@edit_RotaryGroup + 9]:           byte;
    edit_LeslieBalance[@edit_RotaryGroup + 10]:         byte;
    // edit_SyncPHRtoLeslie[@edit_RotaryGroup + 11]:       boolean;

    edit_TubeAmpCurveA[@edit_RotaryGroup + 12]:         Byte;
    edit_TubeAmpCurveB[@edit_RotaryGroup + 13]:         Byte;

// @208, #1464 ff. Advanced Routing Bits for RealOrgan. WORDs!
  edit_UpperRoutingWords[@edit_table_1 + 208]: Array[0..7] of word;
    edit_ena_cont_bits[@edit_UpperRoutingWords + 0]:  word;      // FPGA SPI #40
    edit_ena_env_db_bits[@edit_UpperRoutingWords + 2]:   word;   // FPGA SPI #41
    edit_ena_env_full_bits[@edit_UpperRoutingWords + 4]:   word; // FPGA SPI #42
    edit_env_to_dry_bits[@edit_UpperRoutingWords + 6]:   word;   // FPGA SPI #43

    edit_ena_cont_perc_bits[@edit_UpperRoutingWords + 8]:  word;      // FPGA SPI #32
    edit_ena_env_percmode_bits[@edit_UpperRoutingWords + 10]:  word;  // FW use
    edit_ena_env_adsrmode_bits[@edit_UpperRoutingWords + 12]:  word;  // ADSR ena
    edit_ena_env_timemode_bits[@edit_UpperRoutingWords + 14]:  word;  // TimeMod ADSRena

// @224, #1480 ff. Percussion Hammond
  edit_PercussionGroup[@edit_table_1 + 224]: Array[0..7] of byte;
    edit_PercNormLvl[@edit_PercussionGroup + 0]:        byte; // #1480
    edit_PercSoftLvl[@edit_PercussionGroup + 1]:        byte; // #1481
    edit_PercLongTm[@edit_PercussionGroup + 2]:         byte; // #1482
    edit_PercShortTm[@edit_PercussionGroup + 3]:        byte; // #1483
    edit_PercMutedLvl[@edit_PercussionGroup + 4]:       byte; // #1484
    //edit_H100harpSust[@edit_PercussionGroup + 5]:       byte;  // H100 Harp Sustain length
    edit_PercPrecharge[@edit_PercussionGroup + 6]:      byte;  // #1486

// @232, #1488 GM2 Synth control (SAM5504)
  edit_GM2group[@edit_table_1 + 232]: Array [0..7] of byte;
    // edit_GM2frqShiftAmount[@edit_GM2group + 0] : byte;  // #1488
    // edit_GM2frqShiftInGain[@edit_GM2group + 1] : byte;  // #1489
    edit_GM2synthVolume[@edit_GM2group + 2] : byte;        // #1490 final gain
    edit_GM2organVolume[@edit_GM2group + 3] : byte;        // #1491 final gain

    edit_H100harpSust[@edit_GM2group + 4]: byte;           // #1492 H100 Harp Sustain length
    edit_H100_2ndVlvl[@edit_GM2group + 5]: byte;           // #1493 H100 2nd Voice Level

    edit_LED_PWM[@edit_GM2group + 7]: byte;                // #1495 LED Dimmer

// bis hier wird aus DF-edit_CommonPreset kopiert

// #############################################################################
// ###                                                                       ###
// ###             - +  +  S Y S T E M   I N I T S  +  + -                   ###
// ###                                                                       ###
// #############################################################################

// ab hier nur EEPROM mit persistenter Kopie

// @240, #1496 ff. Defaults, alles mögliche, nur zum Start und Reset gelesen
  edit_DefaultsGroup[@edit_table_1 + 240]: Array[0..15] of byte;

    edit_VibKnobMode[@edit_DefaultsGroup + 1]   :       byte;      // #1497
    edit_SaveRestoreMask[@edit_DefaultsGroup + 2]:      byte;     // #1498
    // edit_SaveRestoreMask2[@edit_DefaultsGroup + 3]:      byte;     // #1499

    edit_ConfBits[@edit_DefaultsGroup + 5] :            byte;      // #1501
    edit_ConfBits2[@edit_DefaultsGroup + 6] :           byte;      // #1501
    edit_ADCconfig[@edit_DefaultsGroup + 7]:            byte;      // #1503
    edit_1stDBselect[@edit_DefaultsGroup + 8]:          byte;      // #1504
    edit_2ndDBselect[@edit_DefaultsGroup + 9]:          byte;      // #1505
    edit_PedalDBsetup[@edit_DefaultsGroup + 10]:        byte;      // #1506
    edit_ADCscaling[@edit_DefaultsGroup + 11]:          byte;      // #1507

    edit_DeviceType[@edit_DefaultsGroup + 13]:          byte;      // #1509
    edit_PresetStructure[@edit_DefaultsGroup + 14]:     byte;      // #1510
    edit_MagicFlag[@edit_DefaultsGroup + 15]:           byte;      // #1511


// #############################################################################
// außerhalb Tabelle, da nur temporär benutzt
// #############################################################################

  CurrentPresetName: String[15];
  CurrentPresetNameLen[@CurrentPresetName]: byte;

  edit_CardSetup:  byte;                //

  edit_LeslieInits: Array[0..63] of byte;
  edit_LeslieInpLvl[@edit_LeslieInits + 4]: byte;

  edit_SAM_RevDSP_Init: array[0..23] of byte;
  edit_SAMreverbPrgms[@edit_SAM_RevDSP_Init]: Array[0..3] of byte;   // 0
  edit_SAMreverbTimes[@edit_SAM_RevDSP_Init + 4]: Array[0..3] of byte; // 1
  // SAM55004 _LiveMic_Effect_RevPreHP, $40 = 600 Hz, $7F =1,2kHz
  edit_SAMreverbPreHP[@edit_SAM_RevDSP_Init + 8]: Array[0..3] of byte; // 2
  // SAM55004 _LiveMic_Effect_RevHDamp, $7F = max.
  edit_SAMreverbHdamp[@edit_SAM_RevDSP_Init + 12]: Array[0..3] of byte; // 3
  // SAM55004 _LiveMic_Effect_RevToneGain, $40 = 0dB, $7F=  + 6dB
  edit_SAMreverbToneGain[@edit_SAM_RevDSP_Init + 16]: Array[0..3] of byte; // 4
  // SAM55004 _LiveMic_Effect_RevToneFreq, $00 = 800 Hz, $7F = 3kHz
  edit_SAMreverbToneFreq[@edit_SAM_RevDSP_Init + 20]: Array[0..3] of byte; // 5


// #############################################################################
// ###          Sender-Flags bei Parser-, OSC- und MIDI-Empfang              ###
// #############################################################################

  //edit_array_sent: Array[0..511] of byte; // Gesamt-Array änderbarer Parameter 1000..1511

// #############################################################################
// ###                        Sendflags-Tabelle 0                            ###
// ###              Gleiche Reihenfolge wie eep_defaults_0                   ###
// #############################################################################

// "Virtuelle" Bedienelemente (Schalter und Analogwerte)
// Alle Änderungen seitens Bedienelemente werden hier zuerst eingetragen.
// Dann wird der neue Wert mit dem alten in_old verglichen, die entsprechende
// Aktion ausgeführt bzw. Routine aufgerufen
// und anschließend_old auf den neuen Wert gesetzt.
  edit_voices_old: Array[0..3] of byte;
    edit_CommonPreset_old[@edit_voices_old + 0]: byte;  // würde bei CommonPresets überschrieben
    edit_UpperVoice_old[@edit_voices_old + 1]: byte;
    edit_LowerVoice_old[@edit_voices_old + 2]: byte;
    edit_PedalVoice_old[@edit_voices_old + 3]: byte;

  edit_array_flag: Array[0..511] of byte; // Gesamt-Array änderbarer Parameter 1000..1511
  edit_array_flag_0[@edit_array_flag + 0]: table[0..255] of byte;

// #############################################################################
// Drawbar-Voices, nur für Live und EEPROM
// #############################################################################

// @0, #1000 Upper Drawbars
  edit_UpperDBs_flag[@edit_array_flag + 0]: Array[0..15] of byte;

// @16, #1016 Lower Drawbars
  edit_LowerDBs_flag[@edit_array_flag + 16]: Array[0..15] of byte;

// @32, #1032 Pedal Drawbars
  edit_PedalDBs_flag[@edit_array_flag + 32]: Array[0..15] of byte;

// Parameter ADSR in Reihenfolge der FPGA-LC-Werte!
// @48, #1048
  edit_ADSR_flag[@edit_array_flag + 48]: Array[0..23] of Byte;
    edit_UpperADSR_flag[@edit_ADSR_flag + 0]: Array[0..7] of Byte;
      edit_UpperAttack_flag[@edit_ADSR_flag + 0]:        Byte; // #420
      edit_UpperDecay_flag[@edit_ADSR_flag + 1]:         Byte; // #421
      edit_UpperSustain_flag[@edit_ADSR_flag + 2]:       Byte; // #422
      edit_UpperRelease_flag[@edit_ADSR_flag + 3]:       Byte; // #423
      edit_UpperADSRharmonics_flag[@edit_ADSR_flag + 4]:      Byte; // #426 Oberton-Zerfall

// @56, #1056
    edit_LowerADSR_flag[@edit_ADSR_flag + 8]: Array[0..7] of Byte;
      edit_LowerAttack_flag[@edit_LowerADSR_flag + 0]:        Byte; // #520
      edit_LowerDecay_flag[@edit_LowerADSR_flag + 1]:         Byte; // #521
      edit_LowerSustain_flag[@edit_LowerADSR_flag + 2]:       Byte; // #522
      edit_LowerRelease_flag[@edit_LowerADSR_flag + 3]:       Byte; // #523
      edit_LowerADSRharmonics_flag[@edit_LowerADSR_flag + 4]: byte; // #526 Oberton-Zerfall

// @64, #1064
    edit_PedalADSR_flag[@edit_ADSR_flag + 16]: Array[0..7] of byte;
      edit_PedalAttack_flag[@edit_PedalADSR_flag + 0]:        byte; // #620
      edit_PedalDecay_flag[@edit_PedalADSR_flag + 1]:         byte; // #621
      edit_PedalSustain_flag[@edit_PedalADSR_flag + 2]:       byte; // #622
      edit_PedalRelease_flag[@edit_PedalADSR_flag + 3]:       byte; // #623
      edit_PedalADSRharmonics_flag[@edit_PedalADSR_flag + 4]: byte; // #626 Oberton-Zerfall

// @72, #1072
  edit_PedalDB4s_flag[@edit_array_flag + 72]: Array[0..3] of byte;
    edit_PedalDB_B3_16_flag[@edit_PedalDB4s_flag + 0]: byte;  // für MIDI und Hammond,
    edit_PedalDB_B3_16H_flag[@edit_PedalDB4s_flag + 1]:byte;  // werden später umgerechnet
    edit_PedalDB_B3_8_flag[@edit_PedalDB4s_flag + 2]:  byte;  // und auf 11 Drawbars verteilt
    edit_PedalDB_B3_8H_flag[@edit_PedalDB4s_flag + 3]: byte;  //

// @76, #1076
  edit_Wheels_flag[@edit_array_flag + 76]: Array[0..3] of byte;
    edit_Wheel_PitchToMIDI_flag[@edit_Wheels_flag + 0]: byte; // Pitchwheel MIDI Send
    edit_Wheel_PitchRotary_flag[@edit_Wheels_flag + 1]: byte; // Pitchwheel Rotary Control
    edit_Wheel_ModToMIDI_flag[@edit_Wheels_flag + 2]: byte;   // Modwheel MIDI Send
    edit_Wheel_ModRotary_flag[@edit_Wheels_flag + 3]: byte;   // Modwheel Rotary Control

// @80 #1080 ff. AO28/Preamp/Audio/Routing Group
  edit_PreampGroup_flag[@edit_array_flag + 80]: Array[0..15] of byte;
    edit_MasterVolume_flag[@edit_PreampGroup_flag + 0]:   byte;       //  + 00
    edit_LeslieVolume_flag[@edit_PreampGroup_flag + 1]:   byte;       //  + 01
    edit_UpperVolumeWet_flag[@edit_PreampGroup_flag + 2]: byte;       //  + 02
    edit_LowerVolume_flag[@edit_PreampGroup_flag + 3]:    byte;       //  + 03
    edit_PedalVolume_flag[@edit_PreampGroup_flag + 4]:    byte;       //  + 04
    edit_UpperVolumeDry_flag[@edit_PreampGroup_flag + 5]: byte;       //  + 05
    edit_OverallReverb_flag[@edit_PreampGroup_flag + 6]: byte;      //  + 06
    edit_TonePot_flag[@edit_PreampGroup_flag + 7]:      byte;         //  + 07
    edit_TrimSwell_flag[@edit_PreampGroup_flag + 8]:      byte;       //  + 08
    edit_MinimalSwell_flag[@edit_PreampGroup_flag + 9]:   byte;       //  + 09
    edit_Triode_k2_flag[@edit_PreampGroup_flag + 10]:     byte;       //  + 10

    edit_ModuleRevVolume_flag[@edit_PreampGroup_flag + 11]:byte;    //  + 91
    edit_ModuleEfxVolume_flag[@edit_PreampGroup_flag + 12]:byte;    //  + 92
    edit_ModuleSwellVolume_flag[@edit_PreampGroup_flag + 13]:   byte;       //  + 93
    edit_ModuleFrontVolume_flag[@edit_PreampGroup_flag + 14]:   byte;       //  + 94
    edit_ModuleRearVolume_flag[@edit_PreampGroup_flag + 15]:   byte;        //  + 95

// @96, #1096 ff. getrennte DBs für elektronische Tastenkontakte mit ADSR, Upper
  edit_UpperEnvelopeDBs_flag[@edit_array_flag + 96]: Array[0..15] of byte;
    edit_UpperEnvelopeDB_16_flag[@edit_UpperEnvelopeDBs_flag + 0]:     byte;
    edit_UpperEnvelopeDB_5_13_flag[@edit_UpperEnvelopeDBs_flag + 1]:   byte;
    edit_UpperEnvelopeDB_8_flag[@edit_UpperEnvelopeDBs_flag + 2]:      byte;
    edit_UpperEnvelopeDB_4_flag[@edit_UpperEnvelopeDBs_flag + 3]:      byte;
    edit_UpperEnvelopeDB_2_23_flag[@edit_UpperEnvelopeDBs_flag + 4]:   byte;
    edit_UpperEnvelopeDB_2_flag[@edit_UpperEnvelopeDBs_flag + 5]:      byte;
    edit_UpperEnvelopeDB_1_35_flag[@edit_UpperEnvelopeDBs_flag + 6]:   byte;
    edit_UpperEnvelopeDB_1_23_flag[@edit_UpperEnvelopeDBs_flag + 7]:   byte;
    edit_UpperEnvelopeDB_1_flag[@edit_UpperEnvelopeDBs_flag + 8]:      byte;
    edit_UpperEnvelopeDB_mixt1_flag[@edit_UpperEnvelopeDBs_flag + 9]:  byte;
    edit_UpperEnvelopeDB_mixt2_flag[@edit_UpperEnvelopeDBs_flag + 10]: byte;
    edit_UpperEnvelopeDB_mixt3_flag[@edit_UpperEnvelopeDBs_flag + 11]: byte;

// @112, #1112 Parametrischer 3-Band-EQ
  edit_EqualizerGroup_flag[@edit_array_flag + 112]: Array[0..15] of byte;
    edit_EqualizerBass_flag[@edit_EqualizerGroup_flag  + 0]: byte;
    edit_EqualizerBassFreq_flag[@edit_EqualizerGroup_flag  + 1]: byte;
    edit_EqualizerBassPeak_flag[@edit_EqualizerGroup_flag  + 2]: byte;

    edit_EqualizerMid_flag[@edit_EqualizerGroup_flag  + 3]: byte;
    edit_EqualizerMidFreq_flag[@edit_EqualizerGroup_flag  + 4]: byte;
    edit_EqualizerMidPeak_flag[@edit_EqualizerGroup_flag  + 5]: byte;

    edit_EqualizerTreble_flag[@edit_EqualizerGroup_flag  + 6]: byte;
    edit_EqualizerTrebleFreq_flag[@edit_EqualizerGroup_flag  + 7]: byte;
    edit_EqualizerTreblePeak_flag[@edit_EqualizerGroup_flag  + 8]: byte;

    edit_EqualizerFullParametric_flag[@edit_EqualizerGroup_flag  + 9]: Byte;
    edit_ModuleExtRotaryEna_flag[@edit_EqualizerGroup_flag  + 10]: boolean;

  edit_PotDetentShiftGroup_flag[@edit_array_flag + 124]: Array[0..3] of byte;
    edit_EquBassDetentShift_flag[@edit_PotDetentShiftGroup_flag + 0]:     byte;
    edit_EquMidDetentShift_flag[@edit_PotDetentShiftGroup_flag + 1]: byte;
    edit_EquTrebleDetentShift_flag[@edit_PotDetentShiftGroup_flag + 2]: byte;
    edit_PercVolDetentShift_flag[@edit_PotDetentShiftGroup_flag + 3]:  byte;

// @128..191, #1128..1191 im Parser reserviert für Byte Tabs
// Tabs 0-7, #1128 ff.
  edit_LogicalTabs_flag[@edit_array_flag + 128]: Array[0..63] of Byte;
    edit_LogicalTab_PercOn_flag[@edit_LogicalTabs_flag + 0] : Byte; // Perc ON, Reihenfolge wie B3
    edit_LogicalTab_PercSoft_flag[@edit_LogicalTabs_flag + 1] : Byte; // Perc SOFT (NORMAL)
    edit_LogicalTab_PercFast_flag[@edit_LogicalTabs_flag + 2] : Byte; // Perc FAST (SLOW)
    edit_LogicalTab_Perc3rd_flag[@edit_LogicalTabs_flag + 3] : Byte; // Perc THIRD (SECOND)
    edit_LogicalTab_VibOnUpper_flag[@edit_LogicalTabs_flag + 4] : Byte; // Vib ON upper
    edit_LogicalTab_VibOnLower_flag[@edit_LogicalTabs_flag + 5] : Byte; // Vib ON lower
    edit_LogicalTab_LeslieRun_flag[@edit_LogicalTabs_flag + 6] : Byte; // Leslie Slow
    edit_LogicalTab_LeslieFast_flag[@edit_LogicalTabs_flag + 7] : Byte; // Leslie Fast

// Tabs 8-15, #1136 ff.
    edit_LogicalTab_TubeAmpBypass_flag[@edit_LogicalTabs_flag + 8]  : Byte;  // Insert Tube Amp
    edit_LogicalTab_RotarySpkrBypass_flag[@edit_LogicalTabs_flag + 9] : Byte; // Insert Seaker Sim
    edit_LogicalTab_PHRupperOn_flag[@edit_LogicalTabs_flag + 10] : Byte; // Insert PHR upper
    edit_LogicalTab_PHRlowerOn_flag[@edit_LogicalTabs_flag + 11] : Byte; // Insert PHR lower

    edit_LogicalTab_Reverb1_flag[@edit_LogicalTabs_flag + 12] : Byte; // Effekt 1
    edit_LogicalTab_Reverb2_flag[@edit_LogicalTabs_flag + 13] : Byte; // Effekt 2
    edit_LogicalTab_PedalPostMix_flag[@edit_LogicalTabs_flag + 14] : Byte; // Bass on Amp enable
    edit_LogicalTab_SplitOn_flag[@edit_LogicalTabs_flag + 15] : Byte; // Split Lower

// Tabs 16-23, #1144 ff.
    edit_LogicalTab_PHR_WersiBoehm_flag[@edit_LogicalTabs_flag + 16]   : Byte;  // Böhm Phasing Rotor
    edit_LogicalTab_PHR_Ensemble_flag[@edit_LogicalTabs_flag + 17]: Byte;
    edit_LogicalTab_PHR_Celeste_flag[@edit_LogicalTabs_flag + 18] : Byte;
    edit_LogicalTab_PHR_Fading_flag[@edit_LogicalTabs_flag + 19]  : Byte;
    edit_LogicalTab_PHR_Weak_flag[@edit_LogicalTabs_flag + 20]    : Byte;
    edit_LogicalTab_PHR_Deep_flag[@edit_LogicalTabs_flag + 21]    : Byte;
    edit_LogicalTab_PHR_Fast_flag[@edit_LogicalTabs_flag + 22]    : Byte;
    edit_LogicalTab_PHR_Delay_flag[@edit_LogicalTabs_flag + 23]   : Byte;

// Tabs 24-31, #1152 ff.
  edit_LogicalTabs_KeyingModes_flag[@edit_LogicalTabs_flag + 24]: Array[0..7] of Byte;
    edit_LogicalTab_H100_Mode_flag[@edit_LogicalTabs_flag + 24]: Byte;       // H100 Percussion statt B3
    edit_LogicalTab_EG_Mode_flag[@edit_LogicalTabs_flag + 25]: Byte;         // Electronic Gating Mode, Attack-Release, Enables => Percussion, ADSR
    edit_LogicalTab_EG_PercMode_flag[@edit_LogicalTabs_flag + 26]: Byte;     // Electronic Gating Mode, EG Drawbars sind Percussion
    edit_LogicalTab_EG_TimeBendMode_flag[@edit_LogicalTabs_flag + 27]: Byte; // Electronic Gating Mode, EG Drawbars sind TimeBend DBs
    edit_LogicalTab_H100_2ndVoice_flag[@edit_LogicalTabs_flag + 28]: Byte;   // H100 Perc Bypass (2nd Voice)
    edit_LogicalTab_H100_HarpSustain_flag[@edit_LogicalTabs_flag + 29]: Byte;// H100 HarpSustain voice on DB 8'
    edit_LogicalTab_EG_mask2dry_flag[@edit_LogicalTabs_flag + 30]: Byte;     // Electronic Gating Option, Enables => Fußlagen auf Dry
    edit_LogicalTab_EqualizerBypass_flag[@edit_LogicalTabs_flag + 31]: Byte;

// Tabs 32-47, #1160 ff.
  edit_LogicalTab_UpperDBtoADSR_flag[@edit_LogicalTabs_flag + 32]: Array[0..15] of Byte;   // Upper BBs to ADSRs
    edit_LogicalTab_UpperDB0toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 0]  : Byte;  // Upper BBs to ADSRs
    edit_LogicalTab_UpperDB1toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 1]  : Byte;  //
    edit_LogicalTab_UpperDB2toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 2]  : Byte;  //
    edit_LogicalTab_UpperDB3toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 3]  : Byte;  //
    edit_LogicalTab_UpperDB4toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 4]  : Byte;  //
    edit_LogicalTab_UpperDB5toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 5]  : Byte;  //
    edit_LogicalTab_UpperDB6toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 6]  : Byte;  //
    edit_LogicalTab_UpperDB7toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 7]  : Byte;  //
    edit_LogicalTab_UpperDB8toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 8]  : Byte;  //
    edit_LogicalTab_UpperDB9toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 9]  : Byte;  //
    edit_LogicalTab_UpperDB10toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 10] : Byte;  //
    edit_LogicalTab_UpperDB11toADSR_flag[@edit_LogicalTab_UpperDBtoADSR_flag + 11] : Byte;  //
    // 2 Tabs OctaveShift Upper/Lower
  edit_LogicalTab_ShiftBtns_flag[@edit_LogicalTabs_flag + 44]: Array[0..3] of Byte;
    // 2 noch frei
    edit_LogicalTab_Shift_upper_flag[@edit_LogicalTab_ShiftBtns_flag + 2] :  Byte; // #1174
    edit_LogicalTab_Shift_lower_flag[@edit_LogicalTab_ShiftBtns_flag + 3] : Byte;  // #1175

// Tabs 48-63, #1176 ff.
  edit_LogicalTab_LowerDBtoADSR_flag[@edit_LogicalTabs_flag + 48]: Array[0..11] of Byte;  // Lower BBs to ADSRs
    edit_LogicalTab_LowerDB0toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 0]  : Byte;  // Lower BBs to ADSRs
    edit_LogicalTab_LowerDB1toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 1]  : Byte;  //
    edit_LogicalTab_LowerDB2toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 2]  : Byte;  //
    edit_LogicalTab_LowerDB3toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 3]  : Byte;  //
    edit_LogicalTab_LowerDB4toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 4]  : Byte;  //
    edit_LogicalTab_LowerDB5toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 5]  : Byte;  //
    edit_LogicalTab_LowerDB6toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 6]  : Byte;  //
    edit_LogicalTab_LowerDB7toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 7]  : Byte;  //
    edit_LogicalTab_LowerDB8toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 8]  : Byte;  //
    edit_LogicalTab_LowerDB9toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 9]  : Byte;  //
    edit_LogicalTab_LowerDB10toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 10] : Byte;  //
    edit_LogicalTab_LowerDB11toADSR_flag[@edit_LogicalTab_LowerDBtoADSR_flag + 11] : Byte;  //

// ab #1192 Momentary Buttons, nicht gespeichert
// Dieser Bereich ist im Preset mit seinem Namen belegt!
  edit_LogicalTab_IncDecBtns_flag[@edit_array_flag + 192]: Array[0..15] of Byte;
    edit_LogicalTab_DecPreset_flag[@edit_LogicalTab_IncDecBtns_flag + 0] :  Byte;  // #1192
    edit_LogicalTab_IncPreset_flag[@edit_LogicalTab_IncDecBtns_flag + 1] :  Byte;  // #1193
    edit_LogicalTab_DecUpperVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 2]:  Byte;  // #1194
    edit_LogicalTab_IncUpperVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 3]:  Byte;  // #1195
    edit_LogicalTab_DecLowerVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 4]:  Byte;  // #1196
    edit_LogicalTab_IncLowerVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 5]:  Byte;  // #1197
    edit_LogicalTab_DecPedalVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 6]:  Byte;  // #1198
    edit_LogicalTab_IncPedalVoice_flag[@edit_LogicalTab_IncDecBtns_flag + 7]:  Byte;  // #1199
    edit_LogicalTab_DecOrganModel_flag[@edit_LogicalTab_IncDecBtns_flag + 8]:  Byte;  // #1200
    edit_LogicalTab_IncOrganModel_flag[@edit_LogicalTab_IncDecBtns_flag + 9]:  Byte;  // #1201
    edit_LogicalTab_DecSpeakerModel_flag[@edit_LogicalTab_IncDecBtns_flag + 10]: Byte; // #1202
    edit_LogicalTab_IncSpeakerModel_flag[@edit_LogicalTab_IncDecBtns_flag + 11]: Byte; // #1203
    edit_LogicalTab_DecTranspose_flag[@edit_LogicalTab_IncDecBtns_flag + 12]:  Byte;  // #1204
    edit_LogicalTab_IncTranspose_flag[@edit_LogicalTab_IncDecBtns_flag + 13]:  Byte;  // #1205

  edit_LogicalTab_VibBtns_flag[@edit_array_flag + 212]: Array[0..5] of Byte;
    edit_LogicalTab_4V1_flag[@edit_LogicalTab_VibBtns_flag + 0] :  Byte;  // #1212
    edit_LogicalTab_4V2_flag[@edit_LogicalTab_VibBtns_flag + 1] :  Byte;  // #1213
    edit_LogicalTab_4V3_flag[@edit_LogicalTab_VibBtns_flag + 2] :  Byte;  // #1214
    edit_LogicalTab_4VCh_flag[@edit_LogicalTab_VibBtns_flag + 3] : Byte;  // #1215
    // doppelt belegt!
    edit_LogicalTab_6V1_flag[@edit_LogicalTab_VibBtns_flag + 0] :  Boolean;  // #1212
    edit_LogicalTab_6C1_flag[@edit_LogicalTab_VibBtns_flag + 1] :  Boolean;  // #1213
    edit_LogicalTab_6V2_flag[@edit_LogicalTab_VibBtns_flag + 2] :  Boolean;  // #1214
    edit_LogicalTab_6C2_flag[@edit_LogicalTab_VibBtns_flag + 3] : Boolean;  // #1215
    edit_LogicalTab_6V3_flag[@edit_LogicalTab_VibBtns_flag + 4] : Byte;   // #1216
    edit_LogicalTab_6C3_flag[@edit_LogicalTab_VibBtns_flag + 5] : Byte;   // #1217

  edit_SingleDBtoggle_flag[@edit_array_flag + 218]:  Byte;    // #1218
  edit_SingleDBtoUpper_flag[@edit_array_flag + 219]: Byte;    // #1219
  edit_SingleDBtoLower_flag[@edit_array_flag + 220]: Byte;    // #1220
  edit_SingleDBtoPedal_flag[@edit_array_flag + 221]: Byte;    // #1221

// @224..223, #1128..1223 im Parser reserviert für Byte Tabs
// Tabs 0-7, #1128 ff.
  edit_GMprogs_flag[@edit_array_flag + 224]: Array[0..23] of byte;
    edit_UpperGMprg_0_flag[@edit_GMprogs_flag + 0]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_UpperGMlvl_0_flag[@edit_GMprogs_flag + 1]: byte; // GM Layer 1 Level
    edit_UpperGMharm_0_flag[@edit_GMprogs_flag + 2]: Byte; // Harmonic Transpose Layer 1
    edit_UpperGMprg_1_flag[@edit_GMprogs_flag + 3]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_UpperGMlvl_1_flag[@edit_GMprogs_flag + 4]: byte; // GM Layer 2 Level
    edit_UpperGMharm_1_flag[@edit_GMprogs_flag + 5]: Byte; // Harmonic Transpose Layer 2
    edit_UpperGMdetune_1_flag[@edit_GMprogs_flag + 6]: Byte; // Detune Layer 2
// 232 ff.
    edit_LowerGMprg_0_flag[@edit_GMprogs_flag + 8]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_LowerGMlvl_0_flag[@edit_GMprogs_flag + 9]: byte; // GM Layer 1 Level
    edit_LowerGMharm_0_flag[@edit_GMprogs_flag + 10]: Byte; // Harmonic Transpose Layer 1
    edit_LowerGMprg_1_flag[@edit_GMprogs_flag + 11]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_LowerGMlvl_1_flag[@edit_GMprogs_flag + 12]: byte; // GM Layer 2 Level
    edit_LowerGMharm_1_flag[@edit_GMprogs_flag + 13]: Byte; // Harmonic Transpose Layer 2
    edit_LowerGMdetune_1_flag[@edit_GMprogs_flag + 14]: Byte; // Detune Layer 2
// 240 ff.
    edit_PedalGMprg_0_flag[@edit_GMprogs_flag + 16]: byte; // GM Layer 1 Voice #, 0 = OFF
    edit_PedalGMlvl_0_flag[@edit_GMprogs_flag + 17]: byte; // GM Layer 1 Level
    edit_PedalGMharm_0_flag[@edit_GMprogs_flag + 18]: Byte; // Harmonic Transpose Layer 1
    edit_PedalGMprg_1_flag[@edit_GMprogs_flag + 19]: byte; // GM Layer 2 Voice #, 0 = OFF
    edit_PedalGMlvl_1_flag[@edit_GMprogs_flag + 20]: byte; // GM Layer 2 Level
    edit_PedalGMharm_1_flag[@edit_GMprogs_flag + 21]: Byte; // Harmonic Transpose Layer 2
    edit_PedalGMdetune_1_flag[@edit_GMprogs_flag + 22]: Byte; // Detune Layer 2


// #############################################################################
// ###                        Sendflags-Tabelle 1                            ###
// ###              Gleiche Reihenfolge wie eep_defaults_1                   ###
// #############################################################################

// @0..7, #1256 frei
  edit_array_flag_1[@edit_array_flag + 256]: Array[0..255] of byte;

// #1260 ff. "Drehknöpfe", exklusive Stellungen, werden auf edit- oder Tab-Werte umgesetzt
  edit_knobs_flag[@edit_array_flag_1 + 4]: Array[0..7] of byte;
    edit_GatingKnob_flag[@edit_knobs_flag + 1]: Byte;    // #1261
    edit_PercKnob_flag[@edit_knobs_flag + 2]: Byte;      // #1262
    edit_ReverbKnob_flag[@edit_knobs_flag + 3]: Byte;    // #1263
    edit_VibKnob_flag[@edit_knobs_flag + 4]: Byte;       // #1264
    edit_OrganModel_flag[@edit_knobs_flag + 5]:   byte;  // #1265
    edit_SpeakerModel_flag[@edit_knobs_flag + 6]:   byte; // #1266

// @12, #1268 ff. Voices und Presets
  edit_voices_flag[@edit_array_flag_1 + 12]: Array[0..3] of byte;
    edit_CommonPreset_flag[@edit_voices_flag + 0]: byte;
    edit_UpperVoice_flag[@edit_voices_flag + 1]: byte;
    edit_LowerVoice_flag[@edit_voices_flag + 2]: byte;
    edit_PedalVoice_flag[@edit_voices_flag + 3]: byte;

// #############################################################################

// @16, #1272 Busbar Levels
  edit_BusbarLevels_flag[@edit_array_flag_1 + 16]: Array[0..15] of byte;

// Zur Erzeugung der Keymap-Tabelle, Offsets aus Orgel-Tabellen
// @32, #1288
  edit_BusBarNoteOffsets_flag[@edit_array_flag_1 + 32]: Array[0..15] of byte;

// @64, #1320 Hammond-Vibrato
  edit_VibratoGroup_flag[@edit_array_flag_1 + 64]: Array[0..15] of byte;
    edit_VibChPreEmphasis_flag[@edit_VibratoGroup_flag + 0]:   byte;   // #1320
    edit_VibChLineAgeAM_flag[@edit_VibratoGroup_flag + 1]:     byte;   // #1321
    edit_VibChFeedback_flag[@edit_VibratoGroup_flag + 2]:      byte;   // #1322
    edit_VibChReflection_flag[@edit_VibratoGroup_flag + 3]:    byte;   // #1323
    edit_VibChRespCutoff_flag[@edit_VibratoGroup_flag + 4]:    byte;   // #1324
    edit_PhaseLk_Shelving_flag[@edit_VibratoGroup_flag + 5]:   byte;   // #1325
    edit_ScannerGearing_flag[@edit_VibratoGroup_flag + 6]:     byte;   // #1326
    edit_ChorusBypassLevel_flag[@edit_VibratoGroup_flag + 7]:  byte;   // #1327
    edit_ChorusScannerLevel_flag[@edit_VibratoGroup_flag + 8]: byte;   // #1328
    edit_VibMods_flag[@edit_VibratoGroup_flag + 9]: Array[0..2] of byte;
      edit_CV1mod_flag[@edit_VibratoGroup_flag + 9]:           byte;   // #1329
      edit_CV2mod_flag[@edit_VibratoGroup_flag + 10]:          byte;   // #1330
      edit_CV3mod_flag[@edit_VibratoGroup_flag + 11]:          byte;   // #1331
    edit_ChorusEnhance_flag[@edit_VibratoGroup_flag + 12]:     byte;   // #1332
    edit_SegmentFlutter_flag[@edit_VibratoGroup_flag + 13]:    byte;   // #1333
    edit_PreemphCutoff_flag[@edit_VibratoGroup_flag + 14]:     byte;   // #1334
    edit_PreemphPhase_flag[@edit_VibratoGroup_flag + 15]:      byte;   // #1335

// @80, #1336..#1351 TEMP!
// Phasing Rotor, Reihenfolge wie FPGA, temporär aus PHR-Preset geladen
// im Edit-Bereich für PHR-Programmerstellung über Editor
  edit_PhasingGroup_flag[@edit_array_flag_1 + 80]: Array[0..15] of byte;
    edit_PHR_SpeedVariSlow_flag[@edit_PhasingGroup_flag + 0]:     byte;   // #1336
    edit_PHR_SpeedVariFast_flag[@edit_PhasingGroup_flag + 1]:     byte;   // #1337
    edit_PHR_SpeedSlow_flag[@edit_PhasingGroup_flag + 2]:         byte;
    edit_PHR_Feedback_flag[@edit_PhasingGroup_flag + 3]:          byte;
    edit_PHR_LevelPh1_flag[@edit_PhasingGroup_flag + 4]:          byte;
    edit_PHR_LevelPh2_flag[@edit_PhasingGroup_flag + 5]:          byte;
    edit_PHR_LevelPh3_flag[@edit_PhasingGroup_flag + 6]:          byte;
    edit_PHR_LevelDry_flag[@edit_PhasingGroup_flag + 7]:          byte;
    edit_PHR_FeedBackInvert_flag[@edit_PhasingGroup_flag + 8]:    byte;
    edit_PHR_RampDelay_flag[@edit_PhasingGroup_flag + 9]:         byte;
    edit_PHR_ModVariPh1_flag[@edit_PhasingGroup_flag + 10]:       byte;
    edit_PHR_ModVariPh2_flag[@edit_PhasingGroup_flag + 11]:       byte;
    edit_PHR_ModVariPh3_flag[@edit_PhasingGroup_flag + 12]:       byte;
    edit_PHR_ModSlowPh1_flag[@edit_PhasingGroup_flag + 13]:       byte;
    edit_PHR_ModSlowPh2_flag[@edit_PhasingGroup_flag + 14]:       byte;
    edit_PHR_ModSlowPh3_flag[@edit_PhasingGroup_flag + 15]:       byte;


// @96, #1352 ff. Keyboard control
  edit_KeyboardGroup_flag[@edit_array_flag_1 + 96]: Array[0..15] of byte;
    edit_PedalCoupler_flag[@edit_KeyboardGroup_flag + 0]:   byte;      //  + 96  #1352
    edit_SplitPoint_flag[@edit_KeyboardGroup_flag + 1]:    byte;      //  + 97  #1353
    edit_SplitMode_flag[@edit_KeyboardGroup_flag + 2]:     byte;      //  + 98  #1354
    edit_KeyTranspose_flag[@edit_KeyboardGroup_flag + 3]:  byte;      //  + 99  #1355
    edit_EarlyKeyCont_flag[@edit_KeyboardGroup_flag + 4]:  Byte;   //  + 100 #1356
    edit_NoDB1_atPerc_flag[@edit_KeyboardGroup_flag + 5]:  Byte;   //  + 101 #1357
    edit_DB16_FoldbMode_flag[@edit_KeyboardGroup_flag + 6]:byte;      //  + 102 #1358
    edit_HighFoldbackOn_flag[@edit_KeyboardGroup_flag + 7]: Byte;  //  + 103 #1359
    edit_ContSpringFlx_flag[@edit_KeyboardGroup_flag + 8]: byte;      //  + 104 #1360
    edit_ContSpringDmp_flag[@edit_KeyboardGroup_flag + 9]: byte;      //  + 105 #1361
    edit_PercEnaOnLiveDBonly_flag[@edit_KeyboardGroup_flag + 10]:    Byte; // #1362 keine B3-Perc auf Presets
    edit_FatarVelocityFac_flag[@edit_KeyboardGroup_flag + 11]: byte;  //  + 107 #1363
    edit_VibKnobMode_flag[@edit_KeyboardGroup_flag + 12]   : byte;    // #1364

// @112, #1368 MIDI
  edit_MidiGroup_flag[@edit_array_flag_1 + 112]: Array[0..15] of byte;
    edit_MIDI_Channel_flag[@edit_MidiGroup_flag + 0]:      byte;      //  + 112  #1368
    edit_MIDI_Option_flag[@edit_MidiGroup_flag + 1]:       byte;
    edit_MIDI_CC_Set_flag[@edit_MidiGroup_flag + 2]:       byte;
    edit_SwellCC_flag[@edit_MidiGroup_flag + 3]:           byte;
    edit_VolumeCC_flag[@edit_MidiGroup_flag + 4]:          byte;
    edit_LocalEnable_flag[@edit_MidiGroup_flag + 5]:       byte;      //  + 96  #1373
    edit_PresetCC_flag[@edit_MidiGroup_flag + 6]:        byte;      // #1374
    edit_ShowCC_flag[@edit_MidiGroup_flag + 7]:        byte;      // #1375
    // edit_UseSwellAsDamper_flag[@edit_MidiGroup_flag + 7]: Byte;     // not used

// @128, #1384 Generator
  edit_GeneratorGroup_flag[@edit_array_flag_1 + 128]: Array[0..15] of byte;
    edit_PreampSwellType_flag[@edit_GeneratorGroup_flag + 0]:     byte;  // #1384
    edit_TG_TuningSet_flag[@edit_GeneratorGroup_flag + 1]:        byte;  // #1385
    edit_TG_Size_flag[@edit_GeneratorGroup_flag + 2]:             byte;  // #1386
    edit_TG_FixedTaperVal_flag[@edit_GeneratorGroup_flag + 3]:    byte;  // #1387
    edit_TG_WaveSet_flag[@edit_GeneratorGroup_flag + 4]:          byte;  // #1388
    edit_TG_Flutter_flag[@edit_GeneratorGroup_flag + 5]:          byte;  // #1389
    edit_TG_Leakage_flag[@edit_GeneratorGroup_flag + 6]:          byte;  // #1390
    edit_TG_Tuning_flag[@edit_GeneratorGroup_flag + 7]:           byte;  // #1391 A 440 = 7 (433 .. 447 Hz)
    edit_TG_TaperCaps_flag[@edit_GeneratorGroup_flag + 8]:        byte;  // #1392 CapSet
    edit_TG_FilterFac_flag[@edit_GeneratorGroup_flag + 9]:        byte;  // #1393 LC Filters cutoff
    edit_TG_First16TaperVal_flag[@edit_GeneratorGroup_flag + 10]: byte;  // #1394
    edit_GenTranspose_flag[@edit_GeneratorGroup_flag + 11]:       byte;  // #1395
    edit_GeneratorModelLimit_flag[@edit_GeneratorGroup_flag + 12]: byte; // #1396
    edit_Audio_Enables_flag[@edit_GeneratorGroup_flag + 13]: Array[0..2] of byte;
      edit_EnableUpperAudio_flag[@edit_GeneratorGroup_flag + 13]:   byte;  // #1397
      edit_EnableLowerAudio_flag[@edit_GeneratorGroup_flag + 14]:   byte;  // #1398
      edit_EnablePedalAudio_flag[@edit_GeneratorGroup_flag + 15]:   byte;  // #1399

// @144, #1400 Effects & Reverb control
  edit_EffectsGroup_flag[@edit_array_flag_1 + 144]: Array[0..7] of byte;
    edit_ReverbLevels_flag[@edit_EffectsGroup + 0]: Array[0..2] of byte;
      edit_ReverbLevel_1_flag[@edit_ReverbLevels_flag + 0]:       byte;
      edit_ReverbLevel_2_flag[@edit_ReverbLevels_flag + 1]:       byte;
      edit_ReverbLevel_3_flag[@edit_ReverbLevels_flag + 2]:       byte;

// @152, #1408 ff. ReadOnly/MenuList Items
  edit_MenuListItems_flag[@edit_array_flag_1 + 152]: Array[0..7] of Byte;
// @154, #1410 PhasingProgram
    edit_CurrentMixtureSet_flag[@edit_MenuListItems_flag + 0]:     byte; // #1408
    edit_CurrentVibratoSet_flag[@edit_MenuListItems_flag + 1]:     byte; // #1409
    edit_CurrentPhasingSet_flag[@edit_MenuListItems_flag + 2]:    byte;  // #1410
    // edit_MenuPercMode_flag[@edit_MenuListItems_flag + 3]: Byte;        // #1411 Perc Select
    // edit_MenuReverbMode_flag[@edit_MenuListItems_flag + 4]: Byte;      // #1412 Reverb Select

// Drawbar-zu-Busbar-Mapping
// Es kann ein Busbar-Pegel nur EINEM Zugriegel zugeordnet werden!
// Wert > 0 ist gleichzeitig Flag, dass dieser Busbar schon einem DB zugeordnet ist.
// Er wird dann keinem anderem mehr zugewiesen.
// DB10 ist vorrangig vor DB11, DB11 ist vorrangig vor DB12
// Drawbar-zu-Busbar-Mapping, 10. Zugriegel (erster nach 1')
// Folge 9, 10, 11, 12, 13, 14 -- -- Anteile Drawbar an Busbar-#
// @160, #1416
  edit_MixtureSets_flag[@edit_array_flag_1 + 160]: Array[0..23] of byte;
  edit_DB10_MixtureSet_flag[@edit_MixtureSets_flag + 0]: Array[0..7] of byte;
  edit_DB11_MixtureSet_flag[@edit_MixtureSets_flag + 8]: Array[0..7] of byte;
  edit_DB12_MixtureSet_flag[@edit_MixtureSets_flag + 16]: Array[0..7] of byte;

// @192, #1448 ff. Rotary live control
  edit_RotaryGroup_flag[@edit_array_flag_1 + 192]: Array[0..15] of byte;
    edit_HornSlowTm_flag[@edit_RotaryGroup_flag + 0]:             byte;
    edit_RotorSlowTm_flag[@edit_RotaryGroup_flag + 1]:            byte;
    edit_HornFastTm_flag[@edit_RotaryGroup_flag + 2]:             byte;
    edit_RotorFastTm_flag[@edit_RotaryGroup_flag + 3]:            byte;
    edit_HornRampUp_flag[@edit_RotaryGroup_flag + 4]:             byte;
    edit_RotorRampUp_flag[@edit_RotaryGroup_flag + 5]:            byte;
    edit_HornRampDown_flag[@edit_RotaryGroup_flag + 6]:           byte;
    edit_RotorRampDown_flag[@edit_RotaryGroup_flag + 7]:          byte;
  edit_RotaryGroup_DB_flag[@edit_RotaryGroup_flag + 8]: Array[0..2] of byte;
    edit_LeslieThrob_flag[@edit_RotaryGroup_flag + 8]:            byte;
    edit_LeslieSpread_flag[@edit_RotaryGroup_flag + 9]:           byte;
    edit_LeslieBalance_flag[@edit_RotaryGroup_flag + 10]:         byte;
    edit_SyncPHRtoLeslie_flag[@edit_RotaryGroup_flag + 11]:       Byte;

// @208, #1464 ff. Advanced Routing Bits for RealOrgan. WORDs!
  edit_UpperRoutingWords_flag[@edit_array_flag_1 + 208]: Array[0..7] of word;
    edit_ena_cont_bits_flag[@edit_UpperRoutingWords_flag + 0]:  word;      // FPGA SPI #40
    edit_ena_env_db_bits_flag[@edit_UpperRoutingWords_flag + 2]:   word;   // FPGA SPI #41
    edit_ena_env_full_bits_flag[@edit_UpperRoutingWords_flag + 4]:   word; // FPGA SPI #42
    edit_env_to_dry_bits_flag[@edit_UpperRoutingWords_flag + 6]:   word;   // FPGA SPI #43

    edit_ena_cont_perc_bits_flag[@edit_UpperRoutingWords_flag + 8]:  word;      // FPGA SPI #32
    edit_ena_env_percmode_bits_flag[@edit_UpperRoutingWords_flag + 10]:  word;  // FW use
    edit_ena_env_adsrmode_bits_flag[@edit_UpperRoutingWords_flag + 12]:  word;  // ADSR ena
    edit_ena_env_timemode_bits_flag[@edit_UpperRoutingWords_flag + 14]:  word;  // TimeMod ADSRena

// @224, #1480 ff. Percussion Hammond
  edit_PercussionGroup_flag[@edit_array_flag_1 + 224]: Array[0..7] of byte;
    edit_PercNormLvl_flag[@edit_PercussionGroup_flag + 0]:        byte; // #1480
    edit_PercSoftLvl_flag[@edit_PercussionGroup_flag + 1]:        byte; // #1481
    edit_PercLongTm_flag[@edit_PercussionGroup_flag + 2]:         byte; // #1482
    edit_PercShortTm_flag[@edit_PercussionGroup_flag + 3]:        byte; // #1483
    edit_PercMutedLvl_flag[@edit_PercussionGroup_flag + 4]:       byte; // #1484
    //edit_H100harpSust_flag[@edit_PercussionGroup_flag + 5]:     byte;  // H100 Harp Sustain length
    edit_PercPrecharge_flag[@edit_PercussionGroup_flag + 6]:      byte;  // #1486

// @232, #1488 GM2 Synth control (SAM5504)
  edit_GM2group_flag[@edit_array_flag_1 + 232]: Array[0..7] of byte;
    // edit_GM2frqShiftAmount_flag[@edit_GM2group_flag + 0] : byte;  // #1488
    // edit_GM2frqShiftInGain_flag[@edit_GM2group_flag + 1] : byte;  // #1489
    edit_GM2synthVolume_flag[@edit_GM2group_flag + 2] : byte;        // #1490 final gain
    edit_GM2organVolume_flag[@edit_GM2group_flag + 3] : byte;        // #1491 final gain

    edit_H100harpSust_flag[@edit_GM2group_flag + 4]: byte;           // #1492 H100 Harp Sustain length
    edit_H100_2ndVlvl_flag[@edit_GM2group_flag + 5]: byte;           // #1493 H100 2nd Voice Level

    edit_LED_PWM_flag[@edit_GM2group_flag + 7]: byte;                // #1495 LED Dimmer

// #############################################################################
// ###          Indirekte Drawbar-Sets für MIDI (Nord C2D etc)               ###
// #############################################################################

// Daten werden an "richtige" Drawbars weitergereicht, wenn
// edit_ActiveUpperIndirect und edit_ActiveLowerIndirect der übertragenen
// Drawbar-Parameternummer entspricht.


  edit_Indirect_DBs: Array[0..63] of Byte;

  edit_UpperIndirect_DBs[@edit_Indirect_DBs]: Array [0..1, 0..11] of Byte;
  edit_UpperIndirectA_DBs[@edit_Indirect_DBs]: Array [0..11] of byte;
  edit_UpperIndirectB_DBs[@edit_Indirect_DBs + 12]: Array [0..11] of byte;

  edit_LowerIndirect_DBs[@edit_Indirect_DBs + 24]: Array [0..1, 0..11] of Byte;
  edit_LowerIndirectA_DBs[@edit_Indirect_DBs + 24]: Array [0..11] of byte;
  edit_LowerIndirectB_DBs[@edit_Indirect_DBs + 36]: Array [0..11] of byte;

  edit_ActiveUpperIndirect, edit_ActiveLowerIndirect: Byte;

// #############################################################################
// ###                 Erweiterte Funktionen und Buttons                     ###
// #############################################################################

// Parameter 1192..1207 auf PresetName[] werden im Parser hierhin umgeleitet

  edit_MomentaryButtons: Array[0..15] of Byte;

// #############################################################################
// ###         Tabellen zum Zwischenspeichern der Live-Einstellungen         ###
// #############################################################################

  // für Common Presets
  temp_common:      Array[0..511] of byte;
  temp_VoiceUpperDrawbars[@Temp_Common + c_UpperDBs]:  Array[0..11] of byte; // wie EEPROM-Tabellen
  temp_VoiceLowerDrawbars[@Temp_Common + c_LowerDBs]:  Array[0..11] of byte;
  temp_VoicePedalDrawbars[@Temp_Common + c_PedalDBs]:  Array[0..11] of byte;
  temp_VoicePedalDrawbars4[@Temp_Common + c_PedalDB4s]:   Array[0..3] of byte;

  temp_PresetNameStr[@temp_Common + c_PresetNameStrArr]: String[15];
  temp_PresetNameLen[@temp_Common + c_PresetNameStrArr]: Byte;
  temp_voices[@temp_Common + c_voices]: Array[0..3] of byte;
  temp_EditMagicFlagIdx[@temp_Common + c_EditMagicFlagIdx]: byte;
  temp_PresetStructure[@temp_Common + c_PresetStructure]: byte;

implementation

procedure NewEditIdxEvent(edit_idx: Word; pvalue, event_source: Byte);
// allgemeiner Event im Bereich 0 bis 511
begin
  if ValueInRange(edit_idx, 0, 511) then
    if ValueInRange(edit_idx, 0128, 0191) or ValueInRange(edit_idx, 0208, 0223) then
      pvalue:= Byte(pvalue <> 0);  // Logical Tabs
    endif;
    edit_array[edit_idx]:= pvalue;
    edit_array_flag[edit_idx]:= event_source;
  endif;
end;

procedure FillEventSource(start_idx, count: Word; event_source: Byte);
// start_idx zeigt auf Edit-/Event-Tabelle 0..511
var my_idx: Word;
begin
  for my_idx:= start_idx to (start_idx + count - 1) do
    edit_array_flag[my_idx]:= event_source;
  endfor;
end;

{
procedure FillEditArray(start_idx, count: Word; data: Byte);
var my_idx: Word;
begin
  for my_idx:= start_idx to (start_idx + count - 1) do
    edit_array[my_idx]:= data;
  endfor;
end;


procedure MaskEventSource(start_idx, count: Word; delete_bitmask: Byte);
// start_idx zeigt auf Edit-/Event-Tabelle 0..511
// löscht Flags, die in delete_bitmask '1' sind
var my_idx: Word;
begin
  delete_bitmask:= not delete_bitmask;
  for my_idx:= start_idx to (start_idx + count - 1) do
    edit_array_flag[my_idx]:= edit_array_flag[my_idx] and (delete_bitmask);
  endfor;
end;
}


// #############################################################################


function EC_LogicalTabsToByte(const idx: Byte): byte;
// Index zeigt auf Eintrag in edit_LogicalTabs, 64 Schalterstellungen
var
  my_result, my_count: Byte;
begin
  my_result:= 0;
  for i:= 7 downto 0 do // alle Bits durchlaufen
    my_result:= (my_result shl 1) or (byte(edit_LogicalTabs[idx + i]) and 1);
  endfor;
  return(my_result);
end;

procedure EC_ByteToLogicalTabs(my_tab_byte, idx: Byte);
// Setzt LogicalTabs ab Index aus Byte (repäsentiert Bit-Array)
begin
  for i:= 0 to 7 do // alle Bits durchlaufen
    edit_LogicalTabs[i + idx]:= Bit(my_tab_byte, i); // neues edit_LogicalTabs-Byte
  endfor;
end;

function EC_LogicalTabs2Word(const idx: Byte): word;
var temp_word: word;
begin
  m:= EC_LogicalTabsToByte(idx);  // ADSR Enables als Percussion-Freigabe-Bits
  lo(temp_word):= m;
  m:= EC_LogicalTabsToByte(idx + 8);
  hi(temp_word):= m;
  return(temp_word);
end;



// #############################################################################
// ###                        SERIELLE TEXT-AUSGABE                          ###
// #############################################################################

procedure SerPromptErrFlags(const my_subch, my_paramint: Integer);
// Error-Meldung und Status-Request-Antwort,
// Status Bit 7=Busy, 6=UserSRQ, 5=OverLoad, 4=WriteEnable, 3..0=Fault/Error
begin
  if ErrFlags = 0 then
    ParamStr:= '0 [OK ';
  else
    ParamStr:= '-' + ByteToStr(ErrFlags) + #32 + '[ERR:';
    for i:= 0 to 6 do
      if Bit(ErrFlags, i) then
        ParamStr:= ParamStr + c_ErrStrArr[i] + #32;
      endif;
    endfor;
    ParamStr:= ParamStr +  ' ' + IntToStr(my_subch) + ' ' + IntToStr(my_paramint);
  endif;
  ParamStr:= ParamStr + ']';
  writeln(serout, ParamStr);
  ErrFlags:= 0;
end;

procedure SerPrompt(const my_Err: byte; const my_subch, my_paramint: Integer);
// Error-Meldung und Status-Request-Antwort,
// Status Bit 7=Busy, 6=UserSRQ, 5=OverLoad, 4=WriteEnable, 3..0=Fault/Error
begin
  incl(ErrFlags, my_Err);
  SerPromptErrFlags(my_subch, my_paramint);
end;

// #############################################################################

// Ausgabe-Prozeduren.
// ACHTUNG: fertiger ParamStr wird für SysEx-Ausgabe gebraucht!

procedure WriteLongSer(const my_param: LongInt);
begin
  ParamStr:= LongToStr(my_param);
  writeln(serout, ParamStr);
end;

procedure WriteByteSer(const my_param: byte);
begin
  ParamStr:= ByteToStr(my_param);
  writeln(serout, ParamStr);
end;

procedure WriteBoolSer(const my_bool: Boolean);
begin
  WriteByteSer(byte(my_bool));
end;

procedure WriteLongSerHex(const my_param: LongInt);
begin
  ParamStr:= LongToStr(my_param) + ' [$' + LongToHex(my_param) + ']';
  writeln(serout, ParamStr);
end;

procedure WriteCommentSer;
begin
  ParamStr:= '0 [' + CommentStr + ']';
  writeln(serout, ParamStr);
end;

procedure WriteSerError;
begin
  write(serout, '/ ERROR: ');
end;

procedure WriteSerWarning;
begin
  write(serout, '/ WARNING: ');
end;

{
procedure WriteParamByteCommentSer;
begin
  WriteChPrefix;
  ParamStr:= ByteToStr(ValueByte);
  write(serout, ParamStr);
  write(serout, ' [');
  write(serout, CommentStr);
  serout(']');
  writeln(serout);
end;
}


end edit_changes.


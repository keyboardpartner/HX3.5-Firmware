// #############################################################################
// ###                           E E P R O M                                 ###
// #############################################################################

// ACHTUNG: EEPROM-VARs werden nicht programmiert (und nicht auf $FF gelöscht),
// nur STRUCTCONST!

unit eeprom_def;

interface
uses const_def;

// #############################################################################
// ###                     Dauerhafte Init-Werte                             ###
// #############################################################################
// die ersten 80 Bytes werden vom Flash-Update grundsätzlich nicht überschrieben!
{$VALIDATE_ON}
{$EEPROM}
structconst
  EE_OverwriteFlag: Boolean   = true; // +0 Flag: Overwrite EEPROM 80+ on Update
  EE_dummy1       : byte   = 0;       // +1 Dummy
  EE_dummy2       : byte   = 0;       // +1 Dummy
  EE_dummy3       : byte   = 0;       // +2 Dummy
  EE_dummy4       : LongInt   = 0;    // +4 Dummy
  EE_dummy8       : LongInt   = 0;    // +8 Dummy
  EE_dummy12      : boolean = false;  // +12, Flag FPGA-Update beim Reboot
  EE_dummy13      : boolean = false;  // +13, Flag Scan-Update beim Reboot
  // wird nach Initialisierung der DF-Seiten auf FALSE gesetzt:
  EE_FirstRunAfterFactoryPrg : boolean = true;  // +14
  EE_ForceUpdateEEPROM  : boolean = true;       // +15
  // +16
  EE_DNA_0         : LongInt   = 0;             // +16
  EE_DNA_1         : LongInt   = 0;             // +20
  EE_DNA_0_bak     : LongInt   = 0; // Backup      +24
  EE_DNA_1_bak     : LongInt   = 0; // Backup      +28
  // +32
  EE_CS_0          : byte = 0;      // +32
  EE_CS_1          : byte = 0;      // +33
  EE_CS_0_bak      : byte = 0;      // +34
  EE_CS_1_bak      : byte = 0;      // +35
  // +36
  // Dieser Wert wird beim Update mit Wert in geladener Datei verglichen.
  // Wenn kleiner, werden ggf. nötige Änderungen im EEPROM vorgenommen.
  EE_Vers1Hex: Word = Vers1Hex;
  EE_dummy38  : boolean = false;    // +38
  EE_dummy39  : boolean = false;    // +39
  // +40
{$IFNDEF MODULE}
  EE_owner         : string[23] = 'KeyboardPartner';
{$ELSE}
  EE_owner         : string[23] = 'Keyswerk/Boehm';  // Module
{$ENDIF}

// +64
var
// #############################################################################
// #1240 ff., Defaults, alles mögliche, nur nach Erstprogrammierung gelesen
// persistent auch bei SD-Card-Update
// NICHT Bestandteil der DF-CommonPresets!
var
{$NOOVRCHECK}
  EE_InitsGroup: array[0..15] of byte;

structconst
{$IFDEF MODULE}
  //EE_unused1[@EE_InitsGroup + 0]: byte = 255;               // #1496
  EE_VibknobMode[@EE_InitsGroup + 1]: byte   = 0;             // #1497
  EE_RestoreCommonPresetMask1[@EE_InitsGroup + 2]: byte = 0;   // #1498
  EE_RestoreCommonPresetMask2[@EE_InitsGroup + 3]: byte = 0;   // #1498
  //EE_unused3[@EE_InitsGroup + 4]: byte = 255;               // #1496
  EE_ConfigurationBits[@EE_InitsGroup+5]: byte  =  4;         // #1501
  EE_ConfigurationBits2[@EE_InitsGroup+6]: byte = 0;          // #1502
  EE_ADCconfig[@EE_InitsGroup + 7]: byte    = 0;              // #1503 no Drawbars
  EE_1stDBselect[@EE_InitsGroup + 8] : byte  = 0;             // #1504
  EE_2ndDBselect[@EE_InitsGroup + 9] : byte  = 40;            // #1505
  EE_PedalDBsetup[@EE_InitsGroup+10] : Byte = 2;              // #1506
  EE_ADCscaling[@EE_InitsGroup + 11]: byte = 100;             // #1507
  EE_ADChysteresis[@EE_InitsGroup + 12]: byte = 4;            // #1508
  EE_DeviceType[@EE_InitsGroup + 13]: byte = 7;               // #1509
 {$ELSE}
  // Für AllinOne, neuer Editor 6.0
  //EE_unused1[@EE_InitsGroup + 0]: byte = 255;               // #1496
  EE_VibknobMode[@EE_InitsGroup + 1]: byte = 2;               // #1497
  EE_RestoreCommonPresetMask1[@EE_InitsGroup + 2]: byte = 31; // #1498
  EE_RestoreCommonPresetMask2[@EE_InitsGroup + 3]: byte = 7;  // #1498
  //EE_unused3[@EE_InitsGroup + 4]: byte = 255;               // #1496
  EE_ConfigurationBits[@EE_InitsGroup+5] : byte = 23;         // #1501
  EE_ConfigurationBits2[@EE_InitsGroup+6] : byte = 1;         // #1502
  EE_ADCconfig[@EE_InitsGroup + 7]   : byte =  1;             // #1503 no Drawbars
  EE_1stDBselect[@EE_InitsGroup + 8] : byte  = 0;             // #1504
  EE_2ndDBselect[@EE_InitsGroup + 9] : byte  = 40;            // #1505
  EE_PedalDBsetup[@EE_InitsGroup+10] : Byte = 1;              // #1506 Plexi 4 DB
  EE_ADCscaling[@EE_InitsGroup + 11]: byte = 100;             // #1507
  EE_ADChysteresis[@EE_InitsGroup + 12]: byte = 4;            // #1508
  EE_DeviceType[@EE_InitsGroup + 13]: byte = 0;               // #1509
{$ENDIF}
  EE_EEPROMstructureVersion[@EE_InitsGroup + 14]: byte = c_FirmwareStructureVersion;
// MagicNumber-Flag: als Kennung für belegte DF-Preset-Arrays
  EE_init[@EE_InitsGroup + 15]    : byte     = $A5;            // #1511

// ab hier können Werte vom Firmware-Update überschrieben werden

// +80

// #############################################################################
// ###                           Drawbar-Presets                             ###
// #############################################################################
// werden ab FW 5.520 nicht mehr bei EEEPROM-Update überschrieben
var
  eep_UpperDBdump: Array[0..255] of byte;
structconst
  eep_UpperDBpresets[@eep_UpperDBdump]: array[0..15, 0..15] of byte = (
    // 0   1   2   3   4   5   6   7   8   9  10  11  GM0 GM1 GM2 GM3  // GMx Overlay Voice #, 0 = OFF
    (127,127,127,127,127,127,127,127,127,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Live
    (127,127,127,127,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 1
    (127,127,127,127,  0,  0,  0,  0,100,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 2
    (127,100,127,100, 20,100, 50, 50,100,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 3
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 4
    (127,100,127,100, 20,  8,  0, 50, 90,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 5
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 6
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 7
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 8
    (127,100,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 9
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 10
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 11
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 12
    (127,100,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 13
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Upper DBs Preset 14
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0)  // #0..11 Upper DBs Preset 15
    );

// 12 Werte werden in den unteren Teil der Edit-Tabelle geladen  // #2200..#2391
var
  eep_LowerDBdump: Array[0..255] of byte;
structconst
  eep_LowerDBpresets[@eep_LowerDBdump]: array[0..15, 0..15] of byte = (
    // 0   1   2   3   4   5   6   7   8   9  10  11  GM0 GM1 GM2 GM3  // GMx Voice #, 0 = OFF
    (  0,  0,127,100, 20,  8,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Live
    (  0,  0,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 1
    (  0,  0,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 2
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 3
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 4
    (127,100,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 5
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 6
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 7
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 8
    (127,100,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 9
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 10
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 11
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 12
    (127,100,127,100, 20,  8,  0,  0, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 13
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0), // #0..11 Lower DBs Preset 14
    ( 70,100,127,100, 20,100, 80, 80, 50,  0,  0,  0,  0,  0,  0,  0)  // #0..11 Lower DBs Preset 15
    );

// 15 Werte werden in den unteren Teil der Edit-Tabelle geladen  // #2200..#2391
var
  eep_PedalDBdump: Array[0..255] of byte;
structconst
  eep_PedalDBpresets[@eep_PedalDBdump]: array[0..15, 0..15] of byte = (
    // 0   1   2   3   4   5   6   7   8   9  10  11  GM0 GM1 GM2 GM3  // GMx Voice #, 0 = OFF
    (127, 95, 76, 45, 27, 16,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Live
    (127, 80, 70, 40, 20, 16,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 1
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 2
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 3
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 4
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 5
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 6
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 7
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 8
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 9
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 10
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 11
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 12
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 13
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0), // #0..11 Pedal DBs Preset 14
    (127, 80, 70, 40, 20, 16,  9,  5,  3,  1,  1,  0,  0,  0,  0,  0)  // #0..11 Pedal DBs Preset 15
    );

structconst
  eep_PedalDB4presets: array[0..15, 0..3] of byte = (
    // 0   1   2   3
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25), // #BD16, DB16H, DB8, DB8H
    (120, 20,100, 25)  // #BD16, DB16H, DB8, DB8H
    );

var
  eep_DrawbarFillDummy: array[0..191] of byte;  // reserviert für weitere EInstellungen

{$NOOVRCHECK}
var
  eep_DrawbarPresetDump[@eep_UpperDBdump]: Array[0..1023] of byte;     // Overlay für Parser

// Adresse $400 = 1024 dez.
//
// #############################################################################
// ###                 Init-Werte für Edit-Tabelle 0                         ###
// ###                (auch Vergleichswerte für Save-*)                      ###
// ###                                                                       ###
// ###                               #####                                   ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                              ##   ##                                  ###
// ###                               #####                                   ###
// ###                                                                       ###
// ###                Gleiche Reihenfolge wie edit_table_0                   ###
// #############################################################################

var
  eep_defaults: array[0..511] of byte;
  eep_defaults_0[@eep_defaults]: array[0..255] of byte;

// "Virtuelle" Bedienelemente (Schalter und Analogwerte)
// #############################################################################
// Drawbar-Voices, nur für Live und EEPROM
// #############################################################################

// @0, #1000 Upper Drawbars
  eep_UpperDBsDummy[@eep_defaults_0 + 0]: Array [0..15] of byte; // #0..11 Upper DBs Live

// @16, #1016 Lower Drawbars
  eep_LowerDBsDummy[@eep_defaults_0 + 16]: Array [0..15] of byte; // #0..11 Lower DBs Live

// @32, #1032 Pedal Drawbars
  eep_PedalDBsDummy[@eep_defaults_0 + 32]: Array[0..15] of byte; // #0..11 Pedal DBs Live

// Parameter ADSR in Reihenfolge der FPGA-LC-Werte!
// @48, #1048
var
  eep_ADSR[@eep_defaults_0+48]: Array[0..23] of byte;
    eep_UpperADSR[@eep_ADSR+0]: Array[0..7] of byte;
structconst
      eep_UpperAttack[@eep_UpperADSR+0]:        byte = 0;   // #1048
      eep_UpperDecay[@eep_UpperADSR+1]:         byte = 70;
      eep_UpperSustain[@eep_UpperADSR+2]:       byte = 125;
      eep_UpperRelease[@eep_UpperADSR+3]:       byte = 0;
      eep_UpperADSRharmonics[@eep_ADSR+4]:      byte = 64;  // #1052 Oberton-Zerfall

// @56, #1056
var
    eep_LowerADSR[@eep_ADSR+8]: Array[0..7] of byte;
structconst
      eep_LowerAttack[@eep_LowerADSR+0]:        byte = 0;  // #1056
      eep_LowerDecay[@eep_LowerADSR+1]:         byte = 70;
      eep_LowerSustain[@eep_LowerADSR+2]:       byte = 125;
      eep_LowerRelease[@eep_LowerADSR+3]:       byte = 0;
      eep_LowerADSRharmonics[@eep_LowerADSR+4]: byte = 64; // # 1060 Oberton-Zerfall

// @64, #1064
var
    eep_PedalADSR[@eep_ADSR+16]: Array[0..7] of byte;
structconst
      eep_PedalAttack[@eep_PedalADSR+0]:        byte = 0;   // #1064
      eep_PedalDecay[@eep_PedalADSR+1]:         byte = 70;
      eep_PedalSustain[@eep_PedalADSR+2]:       byte = 125;
      eep_PedalRelease[@eep_PedalADSR+3]:       byte = 30;
      eep_PedalADSRharmonics[@eep_PedalADSR+4]: byte = 64;  // #1068 Oberton-Zerfall

// @72, #1072
var
  eep_PedalDB4s[@eep_defaults_0+72]: Array[0..3] of byte;
structconst
    eep_PedalDB_B3_16[@eep_PedalDB4s + 0]: byte = 125;  // für MIDI, Menu und Hammond,
    eep_PedalDB_B3_16H[@eep_PedalDB4s + 1]:byte = 0;    // werden später umgerechnet
    eep_PedalDB_B3_8[@eep_PedalDB4s + 2]:  byte = 100;  // und auf 11 Drawbars verteilt
    eep_PedalDB_B3_8H[@eep_PedalDB4s + 3]: byte = 0;    //

// @80 #1080 ff. AO28/Preamp/Audio/Routing Group
var
  eep_PreampGroup[@eep_defaults_0 + 80] : array[0..15] of byte; // #1080 ff.
structconst
    eep_MasterVolume[@eep_PreampGroup + 0] : byte  = 100;       // #1080
    eep_LeslieVolume[@eep_PreampGroup + 1] : byte  = 30;        // #1081

    eep_UpperVolume[@eep_PreampGroup + 2]  : byte  = 105;       // #1082
    eep_LowerVolume[@eep_PreampGroup + 3]  : byte  = 105;       // #1083
    eep_PedalVolume[@eep_PreampGroup + 4]  : byte  = 110;       // #1084
    eep_UpperVolumeDry[@eep_PreampGroup + 5]: byte = 105;       // #1085

    eep_OverallReverb[@eep_PreampGroup + 6]  : byte  = 80;      // #1086

    eep_TonePot[@eep_PreampGroup + 7]      : byte  = 60;        // #1087
    eep_TrimSwell[@eep_PreampGroup + 8]    : byte  = 100;       // #1088
    eep_MinimalSwell[@eep_PreampGroup + 9] : byte  = 20;        // #1089
    eep_Triode_k2[@eep_PreampGroup + 10]   : byte  = 20;        // #1090

    eep_ModuleRevVolume[@eep_PreampGroup + 11]  : byte  = 40;   // #1091
    eep_ModuleEfxVolume[@eep_PreampGroup + 12]  : byte  = 0;    // #1092
    eep_ModuleSwellVolume[@eep_PreampGroup + 13]: byte  = 127;  // #1093
    eep_ModuleFrontVolume[@eep_PreampGroup + 14]: byte  = 127;  // #1094
    eep_ModuleRearVolume[@eep_PreampGroup + 15] : byte  = 40;   // #1095

// @96, #1096 getrennte DBs für elektronische Tastenkontakte mit ADSR, Upper
// Benutzt, wenn SEL_DBE_BITS gesetzt
  eep_UpperEnvelopeDBs[@eep_defaults_0 + 96]:Array[0..15] of byte =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);  // nicht vorbelegt

// @112, #1112 Parametrischer 3-Band-EQ

var
  eep_EqualizerGroup[@eep_defaults_0 + 112]:Array[0..15] of byte;
structconst
    eep_EqualizerBass[@eep_EqualizerGroup + 0]:     byte = 64;
    eep_EqualizerBassFreq[@eep_EqualizerGroup + 1]: byte = 25;
    eep_EqualizerBassPeak[@eep_EqualizerGroup + 2]: byte = 30;

    eep_EqualizerMid[@eep_EqualizerGroup + 3]:      byte = 64;
    eep_EqualizerMidFreq[@eep_EqualizerGroup + 4]:  byte = 40;
    eep_EqualizerMidPeak[@eep_EqualizerGroup + 5]:  byte = 50;

    eep_EqualizerTreble[@eep_EqualizerGroup + 6]:     byte = 64;
    eep_EqualizerTrebleFreq[@eep_EqualizerGroup + 7]: byte = 80;
    eep_EqualizerTreblePeak[@eep_EqualizerGroup + 8]: byte = 64;

    eep_EqualizerFullParametric[@eep_EqualizerGroup +9]: boolean = true;
    eep_ModuleExtRotaryLeft[@eep_EqualizerGroup  + 10]: Byte = 0;
    eep_ModuleExtRotaryRight[@eep_EqualizerGroup  + 11]: Byte = 0;

// @124, #1124 Shift-Wert für Potentiometer mit Mittelstellung
var
  eep_PotDetentShiftGroup[@eep_defaults_0 + 124]:Array[0..3] of byte;
structconst
    eep_EquBassDetentShift[@eep_PotDetentShiftGroup + 0]:     byte = 64;
    eep_EquMidDetentShift[@eep_PotDetentShiftGroup + 1]: byte = 64;
    eep_EquTrebleDetentShift[@eep_PotDetentShiftGroup + 2]: byte = 64;
    eep_PercVolDetentShift[@eep_PotDetentShiftGroup + 3]:  byte = 64;

// #############################################################################
// @128 ff. Boolean Tabs
// #############################################################################

// Tabs 0-7, #1128 ff.
var
  eep_LogicalTabs[@eep_defaults_0+128]: Array[0..63] of boolean;
structconst
      eep_LogicalTab_PercOn    [@eep_LogicalTabs + 0] : boolean = false; // Perc ON, Reihenfolge wie B3
      eep_LogicalTab_PercSoft  [@eep_LogicalTabs + 1] : boolean = false; // Perc SOFT (NORMAL)
      eep_LogicalTab_PercFast  [@eep_LogicalTabs + 2] : boolean = false; // Perc FAST (SLOW)
      eep_LogicalTab_Perc3rd   [@eep_LogicalTabs + 3] : boolean = false; // Perc THIRD (SECOND)
      eep_LogicalTab_VibOnUpper[@eep_LogicalTabs + 4] : boolean = false; // Vib ON upper
      eep_LogicalTab_VibOnLower[@eep_LogicalTabs + 5] : boolean = false; // Vib ON lower
{$IFNDEF MODULE}
      eep_LogicalTab_LeslieRun [@eep_LogicalTabs + 6] : boolean = true;  // Leslie Slow, direkt aus LED-Zustand
{$ELSE}
      eep_LogicalTab_LeslieRun [@eep_LogicalTabs + 6] : boolean = false;  // Leslie Slow, direkt aus LED-Zustand
{$ENDIF}
      eep_LogicalTab_LeslieFast[@eep_LogicalTabs + 7] : boolean = false; // Leslie Fast, direkt aus LED-Zustand

// Tabs 8-15,
      eep_LogicalTab_TubeAmpBypass[@eep_LogicalTabs + 8]  : boolean = false;  // Insert Tube Amp
{$IFNDEF MODULE}
      eep_LogicalTab_RotarySpkrBypass[@eep_LogicalTabs + 9] : boolean = false; // Insert Seaker Sim
{$ELSE}
      eep_LogicalTab_RotarySpkrBypass[@eep_LogicalTabs + 9] : boolean = true; // Insert Seaker Sim
{$ENDIF}
      eep_LogicalTab_PHRupperOn[@eep_LogicalTabs + 10] : boolean = false; // Insert PHR upper
      eep_LogicalTab_PHRlowerOn[@eep_LogicalTabs + 11] : boolean = false; // Insert PHR lower

      eep_LogicalTab_Reverb1   [@eep_LogicalTabs + 12] : boolean = false; // Effekt 1
      eep_LogicalTab_Reverb2   [@eep_LogicalTabs + 13] : boolean = false; // Effekt 2
      eep_LogicalTab_SeparatePedalOut  [@eep_LogicalTabs + 14] : boolean = false; // Bass on Amp enable
      eep_LogicalTab_SplitOn   [@eep_LogicalTabs + 15] : boolean = false; // Split Lower

// Tabs 16-23
{$IFNDEF MODULE}
      eep_LogicalTab_PHR_WersiBoehm[@eep_LogicalTabs + 16]   : boolean = false;  // Böhm Phasing Rotor
{$ELSE}
      eep_LogicalTab_PHR_WersiBoehm[@eep_LogicalTabs + 16]   : boolean = true;   // Böhm Phasing Rotor
{$ENDIF}
      eep_LogicalTab_PHR_Ensemble[@eep_LogicalTabs + 17]: boolean = false;
      eep_LogicalTab_PHR_Celeste[@eep_LogicalTabs + 18] : boolean = false;
      eep_LogicalTab_PHR_Fading[@eep_LogicalTabs + 19]  : boolean = false;
      eep_LogicalTab_PHR_Weak[@eep_LogicalTabs + 20]    : boolean = false;
      eep_LogicalTab_PHR_Deep[@eep_LogicalTabs + 21]    : boolean = false;
      eep_LogicalTab_PHR_Fast[@eep_LogicalTabs + 22]    : boolean = false;
      eep_LogicalTab_PHR_Delay[@eep_LogicalTabs + 23]   : boolean = false;

// Tabs 24-31
      eep_LogicalTab_H100_Mode[@eep_LogicalTabs + 24]: boolean = false;        // H100 Percussion statt B3
      eep_LogicalTab_EG_Mode[@eep_LogicalTabs + 25]: boolean = false;          // Electronic Gating Mode, Attack-Release, Enables => Percussion, ADSR
      eep_LogicalTab_EG_PercMode[@eep_LogicalTabs + 26]: boolean = false;      // Electronic Gating, alle Fußlagen auf Percussion-DB
      eep_LogicalTab_EG_TimeBendMode[@eep_LogicalTabs + 27]: boolean = false;
      eep_LogicalTab_H100_2ndVoice[@eep_LogicalTabs + 28]: boolean = false;    // H100 Perc Bypass (2nd Voice)
      eep_LogicalTab_H100_HarpSustain[@eep_LogicalTabs + 29]: boolean = false; // H100 HarpSustain voice on DB 8'
{$IFNDEF MODULE}
      eep_LogicalTab_EG_mask2dry[@eep_LogicalTabs + 30]: boolean = true;       // Electronic Gating, Enables => Fußlagen auf Dry
{$ELSE}
      eep_LogicalTab_EG_mask2dry[@eep_LogicalTabs + 30]: boolean = false;       // Electronic Gating, Enables => Fußlagen auf Dry
{$ENDIF}
      eep_LogicalTab_EqualizerBypass[@eep_LogicalTabs + 31]: boolean = false;

// Tabs 32-43
var
    eep_LogicalTab_UpperDBtoADSR[@eep_LogicalTabs + 32]: Array[0..15] of boolean;   // Upper BBs to ADSRs
structconst
      eep_LogicalTab_UpperDB0toADSR[@eep_LogicalTab_UpperDBtoADSR + 0]  : boolean = false;  // Upper BBs to ADSRs
      eep_LogicalTab_UpperDB1toADSR[@eep_LogicalTab_UpperDBtoADSR + 1]  : boolean = false;  //
      eep_LogicalTab_UpperDB2toADSR[@eep_LogicalTab_UpperDBtoADSR + 2]  : boolean = false;  //
      eep_LogicalTab_UpperDB3toADSR[@eep_LogicalTab_UpperDBtoADSR + 3]  : boolean = false;  //
      eep_LogicalTab_UpperDB4toADSR[@eep_LogicalTab_UpperDBtoADSR + 4]  : boolean = false;  //
      eep_LogicalTab_UpperDB5toADSR[@eep_LogicalTab_UpperDBtoADSR + 5]  : boolean = false;  //
      eep_LogicalTab_UpperDB6toADSR[@eep_LogicalTab_UpperDBtoADSR + 6]  : boolean = false;  //
      eep_LogicalTab_UpperDB7toADSR[@eep_LogicalTab_UpperDBtoADSR + 7]  : boolean = false;  //
      eep_LogicalTab_UpperDB8toADSR[@eep_LogicalTab_UpperDBtoADSR + 8]  : boolean = false;  //
      eep_LogicalTab_UpperDB9toADSR[@eep_LogicalTab_UpperDBtoADSR + 9]  : boolean = false;  //
      eep_LogicalTab_UpperDB10toADSR[@eep_LogicalTab_UpperDBtoADSR + 10] : boolean = false;  //
      eep_LogicalTab_UpperDB11toADSR[@eep_LogicalTab_UpperDBtoADSR + 11] : boolean = false;  //

// Tabs 44-47
var
  eep_LogicalTab_ShiftBtns[@eep_LogicalTabs + 44]: Array[0..3] of Boolean;
structconst
    eep_LogicalTab_SwapDACs[@eep_LogicalTab_ShiftBtns + 0] :  Boolean = false;  // #1172 Swap DACs
    eep_LogicalTab_Shift_upper[@eep_LogicalTab_ShiftBtns + 2] :  Boolean = false;  //
    eep_LogicalTab_Shift_lower[@eep_LogicalTab_ShiftBtns + 3] : Boolean = false;   //

// Tabs 48-59
var
    eep_LogicalTab_LowerDBtoADSR[@eep_LogicalTabs + 48]: Array[0..11] of boolean;  // Lower BBs to ADSRs
structconst
      eep_LogicalTab_LowerDB0toADSR[@eep_LogicalTab_LowerDBtoADSR + 0]  : boolean = false;  // Lower BBs to ADSRs
      eep_LogicalTab_LowerDB1toADSR[@eep_LogicalTab_LowerDBtoADSR + 1]  : boolean = false;  //
      eep_LogicalTab_LowerDB2toADSR[@eep_LogicalTab_LowerDBtoADSR + 2]  : boolean = false;  //
      eep_LogicalTab_LowerDB3toADSR[@eep_LogicalTab_LowerDBtoADSR + 3]  : boolean = false;  //
      eep_LogicalTab_LowerDB4toADSR[@eep_LogicalTab_LowerDBtoADSR + 4]  : boolean = false;  //
      eep_LogicalTab_LowerDB5toADSR[@eep_LogicalTab_LowerDBtoADSR + 5]  : boolean = false;  //
      eep_LogicalTab_LowerDB6toADSR[@eep_LogicalTab_LowerDBtoADSR + 6]  : boolean = false;  //
      eep_LogicalTab_LowerDB7toADSR[@eep_LogicalTab_LowerDBtoADSR + 7]  : boolean = false;  //
      eep_LogicalTab_LowerDB8toADSR[@eep_LogicalTab_LowerDBtoADSR + 8]  : boolean = false;  //
      eep_LogicalTab_LowerDB9toADSR[@eep_LogicalTab_LowerDBtoADSR + 9]  : boolean = false;  //
      eep_LogicalTab_LowerDB10toADSR[@eep_LogicalTab_LowerDBtoADSR + 10] : boolean = false; //
      eep_LogicalTab_LowerDB11toADSR[@eep_LogicalTab_LowerDBtoADSR + 11] : boolean = false; //



  eep_LogicalTab_MomentaryButtons[@eep_defaults_0 + 192]: Array[0..15] of Byte =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

// Tabs 60..63
var
  eep_SpecialBtns[@eep_defaults_0 + 208]: Array[0..15] of Boolean; //  #1208 ff.
structconst
    eep_LogicalTab_V1[@eep_SpecialBtns + 4] :  Boolean = false;   // #1212
    eep_LogicalTab_V2[@eep_SpecialBtns + 5] :  Boolean = false;   //
    eep_LogicalTab_V3[@eep_SpecialBtns + 6] :  Boolean = false;   //
    eep_LogicalTab_VCh[@eep_SpecialBtns + 7] : Boolean = false;   //
    eep_LogicalTab_TP_up[@eep_SpecialBtns + 8] :  Boolean = false;    //
    eep_LogicalTab_TP_down[@eep_SpecialBtns + 9] :  Boolean = false;  //

// @224..247, GM Programme
var
  eep_GMprogs[@eep_defaults_0 + 224]: Array[0..23] of byte;
structconst
    eep_UpperGMprg_0[@eep_GMprogs + 0]: byte = 0; // GM Layer 1 Voice #, 0 = OFF
    eep_UpperGMlvl_0[@eep_GMprogs + 1]: byte = 0; // GM Layer 1 Level
    eep_UpperGMharm_0[@eep_GMprogs + 2]: byte = 1; // Harmonic Transpose Layer 1
    eep_UpperGMprg_1[@eep_GMprogs + 3]: byte = 0; // GM Layer 2 Voice #, 0 = OFF
    eep_UpperGMlvl_1[@eep_GMprogs + 4]: byte = 0; // GM Layer 2 Level
    eep_UpperGMharm_1[@eep_GMprogs + 5]: byte = 1; // Harmonic Transpose Layer 2
    eep_UpperGMdetune_1[@eep_GMprogs + 6]: byte = 7; // Detune Layer 2

    eep_LowerGMprg_0[@eep_GMprogs + 8]: byte = 0; // GM Layer 1 Voice #, 0 = OFF
    eep_LowerGMlvl_0[@eep_GMprogs + 9]: byte = 0; // GM Layer 1 Level
    eep_LowerGMharm_0[@eep_GMprogs + 10]: byte = 1; // Harmonic Transpose Layer 1
    eep_LowerGMprg_1[@eep_GMprogs + 11]: byte = 0; // GM Layer 2 Voice #, 0 = OFF
    eep_LowerGMlvl_1[@eep_GMprogs + 12]: byte = 0; // GM Layer 2 Level
    eep_LowerGMharm_1[@eep_GMprogs + 13]: byte = 1; // Harmonic Transpose Layer 2
    eep_LowerGMdetune_1[@eep_GMprogs + 14]: byte = 7; // Detune Layer 2

    eep_PedalGMprg_0[@eep_GMprogs + 16]: byte = 0; // GM Layer 1 Voice #, 0 = OFF
    eep_PedalGMlvl_0[@eep_GMprogs + 17]: byte = 0; // GM Layer 1 Level
    eep_PedalGMharm_0[@eep_GMprogs + 18]: byte = 1; // Harmonic Transpose Layer 1
    eep_PedalGMprg_1[@eep_GMprogs + 19]: byte = 0; // GM Layer 2 Voice #, 0 = OFF
    eep_PedalGMlvl_1[@eep_GMprogs + 20]: byte = 0; // GM Layer 2 Level
    eep_PedalGMharm_1[@eep_GMprogs + 21]: byte = 1; // Harmonic Transpose Layer 2
    eep_PedalGMdetune_1[@eep_GMprogs + 22]: byte = 7; // Detune Layer 2

// 248..255 frei

// #############################################################################
// ###                    Init-Werte für Edit-Tabelle 1                      ###
// ###                                                                       ###
// ###                                 ##                                    ###
// ###                               ####                                    ###
// ###                                 ##                                    ###
// ###                                 ##                                    ###
// ###                                 ##                                    ###
// ###                               #####                                   ###
// ###                                                                       ###
// ###                Gleiche Reihenfolge wie edit_table_1                   ###
// #############################################################################

var
  eep_defaults_1[@eep_defaults+256]: array[0..255] of byte;

// Alle Tab-Bits für erstes Common Presets, zur DF-Initialisierung
// @0..7,  #1000..#1007

  eep_knobs[@eep_defaults_1 + 4]: Array[0..7] of byte;
  eep_voices[@eep_defaults_1 + 12]: Array[0..3] of byte;

structconst

// @8, "Drehknöpfe", exklusive Stellungen, werden auf edit- oder Tab-Werte umgesetzt
    eep_GatingKnob[@eep_knobs + 1]: Byte = 0;    // #1261
    eep_PercKnob[@eep_knobs + 2]: Byte = 0;      // #1262
    eep_ReverbKnob[@eep_knobs + 3]: Byte = 0;    // #1263
    eep_VibKnob[@eep_knobs + 4]: Byte = 5;       // #1264
    eep_OrganModel[@eep_knobs + 5]:   byte = 0;  // #1265
    eep_RotaryModel[@eep_knobs + 6]:   byte = 0; // #1266

// #############################################################################
// @12, Voices und Presets
// #############################################################################

  eep_CommonPresetDummy[@eep_voices + 0]: byte = 0;   // #1268
  eep_UpperVoice[@eep_voices + 1]: byte = 0;          // #1269
  eep_LowerVoice[@eep_voices + 2]: byte = 0;          // #1270

  eep_PedalVoice[@eep_voices + 3]: byte = 0;          // #1271

// #############################################################################
// @16, #1272
// #############################################################################

  eep_BusbarLevels[@eep_defaults_1 + 16] : array[0..15] of byte =
    // 0   1   2   3   4   5   6   7   8 # 9  10  11  12  13  14 (15)   // BUSBAR
    (115,110,115,115,115,110,110,110,115,105,100,100,100,100,100,100);

var
  // #1320 ff. AO28 Vibrato Group
  // nicht mehr benutzt, nur temporär!
  // jetzt aus 2200ff. entnommen, je nach Generator-Modell

  // #1336 ff. PHR Group

  // #1352 ff. Keyboard control
  eep_KeyboardGroup[@eep_defaults_1 + 96] : array[0..15] of byte;     // #1352
structconst
  eep_PedalCoupler[@eep_KeyboardGroup + 0]  : boolean = false;      // #1352 Pedal Coupler
  eep_SplitPoint[@eep_KeyboardGroup + 1]    : byte    = 24;         // #1353
  eep_SplitMode[@eep_KeyboardGroup + 2]     : byte    = 0;          // #1354
  eep_KeyTranspose[@eep_KeyboardGroup + 3]  : byte    = 0;          // #1355
  eep_EarlyKeyCont[@eep_KeyboardGroup + 4]  : boolean = false;      // #1356
  eep_NoDB1_atPerc[@eep_KeyboardGroup + 5]  : boolean = true;       // #1357
  eep_DB16_FoldbMode[@eep_KeyboardGroup + 6] : byte   = 2;          // #1358
  eep_HighFoldbackOn[@eep_KeyboardGroup + 7] : boolean = true;      // #1359 B3=ON, M100=OFF
  eep_ContSpringFlx[@eep_KeyboardGroup + 8] : byte    = 4;          // #1360
  eep_ContSpringDmp[@eep_KeyboardGroup + 9] : byte    = 5;          // #1361
  eep_PercEnaOnLiveDBonly[@eep_KeyboardGroup + 10]: boolean = true; // #1362
  eep_FatarVelocityFac[@eep_KeyboardGroup + 11] : byte = 20;        // #1363

var
  // #1368 ff. MIDI
  eep_MidiGroup[@eep_defaults_1 + 112] : array[0..15] of byte;        // #1368
structconst
  eep_MIDIset_Channel[@eep_MidiGroup + 0] : byte     = 0;              // #1369
  eep_MIDI_Option[@eep_MidiGroup + 1]  : byte     = 0;              // #1370
{$IFNDEF MODULE}                                                     // #1371
  eep_MIDIset_CC_Set[@eep_MidiGroup + 2]  : byte     = 0;              // NI B4
{$ELSE}
  eep_MIDIset_CC_Set[@eep_MidiGroup + 2]  : byte     = 3;              // Böhm Sempra
{$ENDIF}
  eep_SwellCC[@eep_MidiGroup + 3]      : byte     = 11;             // #1371
  eep_VolumeCC[@eep_MidiGroup + 4]     : byte     = 7;              // #1372
  eep_LocalEnable[@eep_MidiGroup + 5]   : byte = 7;                 // #1373 Mask ON/OFF
  eep_PresetCC[@eep_MidiGroup + 6]: Boolean  = 32;                  // #1374
  eep_ShowCC[@eep_MidiGroup + 7]: Boolean  = 0;                     // #1375
  eep_MIDI_DisableProgramChange[@eep_MidiGroup + 8]: Boolean  = 0;  // #1376
  eep_MIDI_EnaVK77sysex[@eep_MidiGroup + 9]: Boolean = 0;           // #1377

var
  // #1384 ff. Generator
  eep_GeneratorGroup[@eep_defaults_1 + 128] : array[0..15] of byte;   // #1384
structconst
  eep_PreampSwellType[@eep_GeneratorGroup + 0] : byte    = 0;       // #1384
  eep_TG_TuningSet[@eep_GeneratorGroup + 1] : byte       = 0;       // #1385 0 = Hammond Spread
  eep_TG_Size[@eep_GeneratorGroup + 2]   : byte          = 91;      // #1386
  eep_TG_FixedTaperVal[@eep_GeneratorGroup + 3] : byte   = 32;      // #1387
  eep_TG_WaveSet[@eep_GeneratorGroup + 4] : byte         = 1;       // #1388
  eep_TG_Flutter[@eep_GeneratorGroup + 5] : byte         = 7;       // #1389
  eep_TG_Leakage[@eep_GeneratorGroup + 6] : byte         = 3;       // #1390
  eep_TG_tuning[@eep_GeneratorGroup + 7] : byte          = 7;       // #1391 A440=7 (433..447Hz)
  eep_TG_CapSet[@eep_GeneratorGroup + 8]    : byte       = 1;       // #1392 Tapering
  eep_TG_FilterFac[@eep_GeneratorGroup + 9]    : byte    = 35;      // #1393
  eep_TG_First16TaperVal[@eep_GeneratorGroup + 10]: byte = 23;      // #1394
  eep_GenTranspose[@eep_GeneratorGroup + 11]: byte = 0;             // #1395
  eep_GeneratoModelLimit[@eep_GeneratorGroup + 12]: byte = 7;       // #1396
  eep_EnableUpperAudio[@eep_GeneratorGroup + 13]: Boolean = true;   // #1397
  eep_EnableLowerAudio[@eep_GeneratorGroup + 14]: Boolean = true;   // #1398
  eep_EnablePedalAudio[@eep_GeneratorGroup + 15]: Boolean = true;   // #1399

var
  // #1400 ff. Effects & Reverb control
  eep_EffectsGroup[@eep_defaults_1 + 144] : array[0..15] of byte;   // #1400
  eep_ReverbLevels[@eep_EffectsGroup + 0] : array[0..2] of byte;    // #1400
structconst
  eep_ReverbLevel_1[@eep_ReverbLevels + 0]  : byte       = 63;      // #1400
  eep_ReverbLevel_2[@eep_ReverbLevels + 1]  : byte       = 89;      // #1401
  eep_ReverbLevel_3[@eep_ReverbLevels + 2]  : byte       = 115;     // #1402

  eep_ReverbPrg[@eep_EffectsGroup + 3]      : byte       = 0;       // #1403

//  edit_MenuListItems[@edit_table_1 + 152]: Array[0..7] of Byte;
var
  eep_MenuListItems[@eep_defaults_1 + 152]: Array[0..15] of Boolean;
structconst
    eep_MixtureSetup[@eep_MenuListItems + 0]: Byte = 0;
    eep_VibratoSetup[@eep_MenuListItems + 1]: Byte = 0;
    eep_PhasingSetup[@eep_MenuListItems + 2]: Byte = 0;
    eep_MenuPercMode[@eep_MenuListItems + 3]: Byte = 0;
    eep_MenuReverbMode[@eep_MenuListItems + 4]: Byte = 0;


var
  // #1448 ff. Rotary Live/Menu control
  eep_RotaryGroup[@eep_defaults_1 + 192] : array[0..15] of byte;
structconst
  eep_HornSlowTm[@eep_RotaryGroup + 0] : byte            = 15;      // #1448
  eep_RotorSlowTm[@eep_RotaryGroup + 1] : byte           = 14;      // #1449
  eep_HornFastTm[@eep_RotaryGroup + 2] : byte            = 91;      // #1450 +50!
  eep_RotorFastTm[@eep_RotaryGroup + 3] : byte           = 87;      // #1451 +50!
  eep_HornRampUp[@eep_RotaryGroup + 4] : byte            = 2;       // #1452
  eep_RotorRampUp[@eep_RotaryGroup + 5] : byte           = 12;      // #1453
  eep_HornRampDown[@eep_RotaryGroup + 6] : byte          = 3;       // #1454
  eep_RotorRampDown[@eep_RotaryGroup + 7] : byte         = 20;      // #1455
  eep_LeslieThrob[@eep_RotaryGroup + 8] : byte           = 59;      // #1456 x2!
  eep_LeslieSpread[@eep_RotaryGroup + 9] : byte          = 80;      // #1457
  eep_LeslieBalance[@eep_RotaryGroup + 10] : byte        = 60;      // #1458
{$IFNDEF MODULE}
  // jetzt in Various Configurations 2, Bit 3
  eep_SyncPHRtoLeslie[@eep_RotaryGroup + 11]: boolean    = true;    // #1459
{$ELSE}
  eep_SyncPHRtoLeslie[@eep_RotaryGroup + 11]: boolean    = false;   // #1459
{$ENDIF}
  eep_TubeAmpCurveA[@eep_RotaryGroup + 12]:   Byte        = 2;
  eep_TubeAmpCurveB[@eep_RotaryGroup + 13]:   Byte        = 3;

var
  // #1464 ff. Advanced Routing Bits for RealOrgan, WORDs!
  eep_UpperRoutingWords[@eep_defaults_1 + 208]: Array[0..7] of word;
structconst
    eep_ena_cont_bits[@eep_UpperRoutingWords + 0]: word = $FFF;    // FPGA SPI #40
    eep_ena_env_db_bits[@eep_UpperRoutingWords + 2]: word = 0;     // FPGA SPI #41
    eep_ena_env_full_bits[@eep_UpperRoutingWords + 4]: word = 0;   // FPGA SPI #42
    eep_env_to_dry_bits[@eep_UpperRoutingWords + 6]: word = 0;     // FPGA SPI #43

    eep_ena_cont_perc_bits[@eep_UpperRoutingWords + 8]:  word = 0;     // FPGA SPI #32
    eep_ena_env_percmode_bits[@eep_UpperRoutingWords + 10]:  word = 0;  // FW use
    eep_ena_env_adsrmode_bits[@eep_UpperRoutingWords + 12]:  word = 0;  // FW use
    eep_ena_env_timemode_bits[@eep_UpperRoutingWords + 14]:  word = 0;  // FW use

var
  // #1480 ff. Percussion Hammond
  eep_PercussionGroup[@eep_defaults_1 + 224] : array[0..7] of byte;   // #1480
structconst
  eep_PercNormLvl[@eep_PercussionGroup + 0] : byte = 100;           // #1480
  eep_PercSoftLvl[@eep_PercussionGroup + 1] : byte = 75;            // #1481
  eep_PercLongTm[@eep_PercussionGroup + 2]  : byte = 55;            // #1482
  eep_PercShortTm[@eep_PercussionGroup + 3] : byte = 36;            // #1483
  eep_PercMutedLvl[@eep_PercussionGroup + 4] : byte = 64;           // #1484
  //eep_H100harpSust[@eep_PercussionGroup + 5]: byte = 68;          // #1485
  eep_PercPrecharge[@eep_PercussionGroup + 6] : byte = 63;          // #1486

var
  // 1488 ff. SAM5504 Parameter, nicht für Modul!
  eep_GM2group[@eep_defaults_1 + 232] : array[0..7] of byte;
structconst
  eep_GM2_dummy1[@eep_GM2group + 0] : byte =  0;            // #1488
  eep_GM2_dummy2[@eep_GM2group + 1] : byte =  0;            // #1489
  eep_GM2synthVolume[@eep_GM2group + 2] :    byte = 105;            // #1490
  {$IFNDEF MODULE}
    eep_GM2organVolume[@eep_GM2group + 3] :    byte = 100;           // #1491
  {$ELSE}
    eep_GM2organVolume[@eep_GM2group + 3] :    byte = 115;          // #1491
  {$ENDIF}
  eep_H100harpSust[@eep_GM2group + 4]: byte = 75;                   // #1492 Release Time
  eep_H100_2ndVlvl[@eep_GM2group + 5]: byte = 60;                   // #1493 Level when 2nd Voice ON

  eep_LED_PWM[@eep_GM2group + 7]: byte = 15;                       // #1495 LED Dimmer

var
  eep_dummyGroup[@eep_defaults_1 + 240] : array[0..15] of byte;
structconst
  eep_PresetValid[@eep_dummyGroup + 15]: byte =  $A5;

// #############################################################################
// ###               Parameter #1144 ff. SAM5504 REVERB                      ###
// #############################################################################
{
  SAM _LiveMic Reverb programs:
  0: Off		1: Short Room		2: Room A		3: Room B
  4: Small Hall A	5: Small Hall B		6: Large Hall A		7: Large Hall B
  8: Short Plate	9: Vocal Plate
  10: Mono Echo		11: Stereo Echo
  12: MonoEcho+Reverb	13: StereoEcho+Reverb
  Mit Piano/GM2Synth nur 0-3 und 8 möglich!
}
var
  eep_SAM_RevDSP_Init: array[0..31] of byte;
structconst
  eep_SAMreverbPrgms[@eep_SAM_RevDSP_Init]: Array[0..3] of byte = (0, 2, 3, 3);

  eep_SAMreverbTimes[@eep_SAM_RevDSP_Init + 4]: Array[0..3] of byte = (0, $40, $30, $40);

  // SAM55004 _LiveMic_Effect_RevPreHP, $40 = 600 Hz, $7F =1,2kHz
  eep_SAMreverbPreHP[@eep_SAM_RevDSP_Init + 8]: Array[0..3] of byte = (0, $40, $30, $10);

  // SAM55004 _LiveMic_Effect_RevHDamp, $7F = max.
  eep_SAMreverbHdamp[@eep_SAM_RevDSP_Init + 12]: Array[0..3] of byte = (0, $60, $40, $20);

  // SAM55004 _LiveMic_Effect_RevToneGain, $40 = 0dB, $7F= +6dB
  eep_SAMreverbToneGain[@eep_SAM_RevDSP_Init + 16]: Array[0..3] of byte = (0, $50, $50, $40);

  // SAM55004 _LiveMic_Effect_RevToneFreq, $00 = 800 Hz, $7F = 3kHz
  eep_SAMreverbToneFreq[@eep_SAM_RevDSP_Init + 20]: Array[0..3] of byte = (0, $40, $30, $30);

// #############################################################################
// Parameter ff. ROTARY INIT, nur für EEPROM
// #############################################################################

structconst
  eep_LeslieInits: Array[0..63] of byte = (
    30,	  // +0 Amp Volume   ### keine Konstanten! ###  SPI 176  ###
    15,	  // +1 Speed Horn   ### keine Konstanten! ###  SPI 177  ###
    14,	  // +2 Speed Rotor  ### keine Konstanten! ###  SPI 178  ###
    0,	  // +3 Config Sw    ### keine Konstanten! ###  SPI 179  ###
    170,  // +4 Lvl Input
    180,  // +5 Lvl Horn
    235,  // +6 Lvl Rotor
    216,  // +7 Near Refl level
    200,  // +8 Room Refl level
    50,	  // +9  Crossover Frequ (51 = 800 Hz)
    20,	  // +10 Throb Highpass Frequency Rotor
    110,  // +11 Room Initial Delay
    35,  // +12 Diffuse Allpass Delay Near
    100,  // +13 Diffuse Allpass Delay Room
    49,  // +14 Diffuse Rotor Near
    133,  // +15 Diffuse Rotor Room
    180,  // +16 LFO Mod Horn Main Left       ###  SPI 192  ###
    180,  // +17 LFO Mod Horn Main Right
    158,  // +18 LFO Mod Horn Refl 1 Left  Near + Cab 4x
    158,  // +19 LFO Mod Horn Refl 1 Right Near - Cab 4x
    219,  // +20 LFO Mod Horn Refl 2 Left  Far
    219,  // +21 LFO Mod Horn Refl 2 Right Far
    255,  // +22 LFO Mod Horn Throb Left  2 kHz
    255,  // +23 LFO Mod Horn Throb Right 2 kHz
    90,  // +24 LFO Mod Horn Cab 4x
    152,  // +25 LFO Mod Rotor Main
    191,  // +26 LFO Mod Rotor Refl
    230,  // +27 LFO Mod Rotor Throb 200 Hz
    0,    // +28 Invert Horn Phase
    0,    // n.v.
    0,    // n.v.
    0,    // n.v.
    // nächste 12 Werte nicht mehr benutzt ab FPGA 10112015
    0,    // LFO Add' Delay Offset Horn Main Left ###  SPI 208 $D0 ###
    0,	  // LFO Add' Delay Offset Horn Main Right
    0,	  // LFO Add' Delay Offset Horn Cab 4x
    0,	  // LFO Add' Delay Offset Horn Refl 1 Left  Near  + Cab 4x
    0,	  // LFO Add' Delay Offset Horn Refl 1 Right Near - Cab 4x
    0,	  // LFO Add' Delay Offset Horn Refl 2 Left  Far
    0,	  // LFO Add' Delay Offset Horn Refl 2 Right Far
    0,	  // LFO Add' Value Offset Horn Throb Left  2 kHz ###
    0,	  // LFO Add' Value Offset Horn Throb Right 2 kHz ###
    0,    // LFO Add' Delay Offset Rotor Main
    0,    // LFO Add' Delay Offset Rotor Refl
    0,    // LFO Add' Value Offset Rotor Throb 200 Hz  ###
    0,    // n.v.
    0,    // n.v.
    0,    // n.v.
    0,    // n.v.
    0,	  // +48 LFO Phase Offset Horn Main Left (+ Spread)
    80,	  // +49 LFO Phase Offset Horn Main Right
    51,   // +50 LFO Phase Offset Horn Refl 1 Left  Near + Cab 4x (+ Spread)
    131,  // +51 LFO Phase Offset Horn Refl 1 Right Near - Cab 4x
    158,  // +52 LFO Phase Offset Horn Refl 2 Left  Far (+ Spread)
    238,  // +53 LFO Phase Offset Horn Refl 2 Right Far
    54,   // +54 LFO Level Offset Horn Throb Left  2 kHz (+ Spread)
    134,  // +55 LFO Level Offset Horn Throb Right 2 kHz ###
    85,   // +56 LFO Phase Offset Horn Cab 4x
    0,    // +57 LFO Phase Offset Rotor Main
    75,   // +58 LFO Phase Offset Rotor Refl
    146,  // +59 LFO Level Offset Rotor Throb 200 Hz
    0,    // +60 unused
    0,    // n.v.
    0,    // n.v.
    0     // n.v.
  );

// #############################################################################
// ###                         PHASING ROTOR PROGRAMME                       ###
// #############################################################################

// Level-/Mod-Werte max. 127!
var
  eep_PhasingRotorDump: Array[0..127] of byte;
// alte Böhm-Parameter aus 5.202, Delays verdoppelt
structconst
  eep_PhasingRotorSets[@eep_PhasingRotorDump]:Array[0..7, 0..15] of byte = (
    (                                    // Preset 0, WersiVoice
    14,                                  // Speed Vari TDA1022, Slow
    136,                                 // Speed Vari TDA1022, Fast
    10,                                  // Speed Slow TDA1022
    100,                                 // Feedback
    118, 144, 90,                        // Level Phase 1..3
    50,                                  // Level Dry
    %00001011,                           // Feedback Invert (3), Filter (1..0)
    10,                                  // Ramp Delay
    33, 70, 44,                          // Mod Vari Phase 1..3
    0, 0, 0),                            // Mod Slow Phase 1..3

    (                                    // Preset nicht benutzt!     // #2516 ff.
    14,                                  // Speed Vari TDA1022, Slow
    144,                                 // Speed Vari TDA1022, Fast
    10,                                  // Speed Slow TDA1022
    164,                                 // Feedback
    118, 144, 117,                       // Level Phase 1..3
    50,                                  // Level Dry
    %00001000,                           // Feedback Invert (3), Filter (1..0)
    10,                                  // Ramp Delay
    35, 40, 24,                          // Mod Vari Phase 1..3
    0, 0, 0),                            // Mod Slow Phase 1..3

    (                                    // Preset 2 Böhm Rotor Slow/Fast     // #2532 ff.
    14,                                  // Speed Vari TDA1022, Slow
    144,                                 // Speed Vari TDA1022, Fast
    10,                                  // Speed Slow TDA1022
    63,                                  // Feedback
    118, 144, 90,                        // Level Phase 1..3
    50,                                  // Level Dry
    %00001011,                           // Feedback Invert (3), Filter (1..0)
    10,                                  // Ramp Delay
    18, 64, 44,                          // Mod Vari Phase 1..3
    0, 0, 0),                            // Mod Slow Phase 1..3

    (                                    // Preset 3 Ensemble       // #2548 ff.
    136,                                 // Speed Vari TDA1022, Slow
    136,                                 // Speed Vari TDA1022, Fast
    5,                                   // Speed Slow TDA1022
    51,                                  // Feedback
    122, 122, 122,                       // Level Phase 1..3
    30,                                  // Level Dry
    %00001000,                           // Feedback Invert (3), Filter (1..0)
    15,                                  // Ramp Delay
    33, 33, 33,                          // Mod Vari Phase 1..3
    100, 100, 100),                      // Mod Slow Phase 1..3

    (                                    // Preset 4 Celeste       // #2564 ff.
    136,                                 // Speed Vari TDA1022, Slow
    136,                                 // Speed Vari TDA1022, Fast
    5,                                   // Speed Slow TDA1022
    130,                                 // Feedback
    122, 122, 122,                       // Level Phase 1..3
    30,                                  // Level Dry
    %00001011,                           // Feedback Invert (3), Filter (1..0)
    15,                                  // Ramp Delay
    53, 53, 51,                          // Mod Vari Phase 1..3
    121, 119, 122),                      // Mod Slow Phase 1..3

    (                                    // Preset 5 Fading       // #2580 ff.
    9,                                   // Speed Vari TDA1022, Fast
    14,                                  // Speed Vari TDA1022, Slow
    3,                                   // Speed Slow TDA1022
    130,                                 // Feedback
    122, 122, 122,                       // Level Phase 1..3
    80,                                  // Level Dry
    %00000011,                           // Feedback Invert (3), Filter (1..0)
    15,                                  // Ramp Delay
    85, 85, 85,                          // Mod Vari Phase 1..3
    97, 0, 0),                           // Mod Slow Phase 1..3

    (                                    // Preset 6 Vibrato 1, dünn// #2596 ff.
    128,                                 // Speed Vari TDA1022, Slow
    135,                                 // Speed Vari TDA1022, Fast
    10,                                  // Speed Slow TDA1022
    90,                                  // Feedback
    160, 70,  0,                         // Level Phase 1..3
    63,                                  // Level Dry
    %00000000,                           // Feedback Invert (3), Filter (1..0)
    15,                                  // Ramp Delay
    40, 25,  0,                          // Mod Vari Phase 1..3
    0, 0, 0),                            // Mod Slow Phase 1..3

    (                                    // Preset 7 Vibrato 2, X-66// #2612
    133,                                 // Speed Vari TDA1022, Slow
    142,                                 // Speed Vari TDA1022, Fast
    10,                                  // Speed Slow TDA1022
    20,                                  // Feedback
    170, 30, 0,                          // Level Phase 1..3
    60,                                  // Level Dry
    %00001000,                           // Feedback Invert (3), Filter (1..0)
    15,                                  // Ramp Delay
    35, 20,  0,                          // Mod Vari Phase 1..3
    0, 0, 0)                             // Mod Slow Phase 1..3
    );


// #############################################################################

var
  // Reihenfolge wie in I2C-Buffer FatarScan76-Slave
  eep_fs76_arr_dump:Array[0..95] of byte;
  eep_fs76_arr[@eep_fs76_arr_dump]:Array[0..3, 0..23] of byte;

  eep_fs76_arr_upper[@eep_fs76_arr_dump + 0]:Array[0..23] of byte;
  eep_fs76_arr_lower[@eep_fs76_arr_dump + 24]:Array[0..23] of byte;
  eep_fs76_arr_pedal[@eep_fs76_arr_dump + 48]:Array[0..23] of byte;
  eep_fs76_arr_aux[@eep_fs76_arr_dump + 72]:Array[0..23] of byte;

structconst
  // FatarScan76-Defaults
  // Reihenfolge wie in I2C-Buffer FatarScan76-Slave

  // UPPER
  eep_upper_Test[@eep_fs76_arr_upper + 0]: Byte = 0;
  eep_upper_Transpose[@eep_fs76_arr_upper + 1]: Byte = 0;

  eep_upper_Channel_A[@eep_fs76_arr_upper + 2]: Byte = 0;  // Channel Main
  eep_upper_Channel_B[@eep_fs76_arr_upper + 3]: Byte = 0;  // Channel unterhalb Split

  eep_upper_OctaveShift_A[@eep_fs76_arr_upper + 4]: Byte = 0;   // Oktave Main
  eep_upper_OctaveShift_B[@eep_fs76_arr_upper + 5]: Byte = 0;   // Oktave unterhalb Split

  eep_upper_DynOn_A[@eep_fs76_arr_upper + 6]: Boolean = true;   // Modus Main
  eep_upper_DynOn_B[@eep_fs76_arr_upper + 7]: Boolean = true;   // Modus unterhalb Split

  eep_upper_UsePitchBnd[@eep_fs76_arr_upper + 8]: Boolean = false;
  eep_upper_UseAftTouch[@eep_fs76_arr_upper + 9]: Boolean = true;
  eep_upper_UseModwheel[@eep_fs76_arr_upper + 10]: Boolean = false;
  // DynMode: Late OFF  Dyn, EarlyOFF  Dyn, Late ON NoDyn, EarlyON NoDyn
  eep_upper_DynMode[@eep_fs76_arr_upper + 11]: Byte = 0;
  eep_upper_DynSlope[@eep_fs76_arr_upper + 12]: Byte = 32;
  eep_upper_ActiveSensing[@eep_fs76_arr_upper + 13]: Boolean = false;
  eep_upper_SplitOn[@eep_fs76_arr_upper + 14]: Boolean = false;
  eep_upper_SplitPoint[@eep_fs76_arr_upper + 15]: Byte = 24;

  eep_upper_KbdType[@eep_fs76_arr_upper + 16]: Byte = 0;
  eep_upper_InvertedKbdPolarity[@eep_fs76_arr_upper + 18]: Boolean = false;

  eep_upper_Loopdelay[@eep_fs76_arr_upper + 19]: Byte = 10;
  eep_upper_DynResetVal[@eep_fs76_arr_upper + 20]: Byte = 19;
  eep_upper_FilterCC[@eep_fs76_arr_upper + 21]: Boolean = false;
  eep_upper_FilterPrgChnge[@eep_fs76_arr_upper + 22]: Boolean = false;
  eep_upper_I2Cflag[@eep_fs76_arr_upper + 23]: Boolean = true;

  // LOWER
  eep_lower_Test[@eep_fs76_arr_lower + 0]: Boolean = false;
  eep_lower_Transpose[@eep_fs76_arr_lower + 1]: Byte = 0;

  eep_lower_Channel_A[@eep_fs76_arr_lower + 2]: Byte = 1;  // Channel Main
  eep_lower_Channel_B[@eep_fs76_arr_lower + 3]: Byte = 1;  // Channel unterhalb Split

  eep_lower_OctaveShift_A[@eep_fs76_arr_lower + 4]: Byte = 0;   // Oktave Main
  eep_lower_OctaveShift_B[@eep_fs76_arr_lower + 5]: Byte = 0;   // Oktave unterhalb Split

  eep_lower_DynOn_A[@eep_fs76_arr_lower + 6]: Boolean = true;   // Modus Main
  eep_lower_DynOn_B[@eep_fs76_arr_lower + 7]: Boolean = true;   // Modus unterhalb Split

  eep_lower_UsePitchBnd[@eep_fs76_arr_lower + 8]: Boolean = false;
  eep_lower_UseAftTouch[@eep_fs76_arr_lower + 9]: Boolean = false;
  eep_lower_UseModwheel[@eep_fs76_arr_upper + 10]: Boolean = false;
  // DynMode: Late OFF  Dyn, EarlyOFF  Dyn, Late ON NoDyn, EarlyON NoDyn
  eep_lower_DynMode[@eep_fs76_arr_lower + 11]: Byte = 0;
  eep_lower_DynSlope[@eep_fs76_arr_lower + 12]: Byte = 32;
  eep_lower_ActiveSensing[@eep_fs76_arr_lower + 13]: Boolean = false;
  eep_lower_SplitOn[@eep_fs76_arr_lower + 14]: Boolean = false;
  eep_lower_SplitPoint[@eep_fs76_arr_lower + 15]: Byte = 24;

  eep_lower_KbdType[@eep_fs76_arr_lower + 16]: Byte = 0;
  eep_lower_InvertedKbdPolarity[@eep_fs76_arr_lower + 18]: Boolean = false;

  eep_lower_Loopdelay[@eep_fs76_arr_lower + 19]: Byte = 10;
  eep_lower_DynResetVal[@eep_fs76_arr_lower + 20]: Byte = 19;
  eep_lower_FilterCC[@eep_fs76_arr_lower + 21]: Boolean = false;
  eep_lower_FilterPrgChnge[@eep_fs76_arr_lower + 22]: Boolean = false;
  eep_lower_I2Cflag[@eep_fs76_arr_lower + 23]: Boolean = true;

  // PEDAL
  eep_pedal_Test[@eep_fs76_arr_pedal + 0]: Byte = 0;
  eep_pedal_Transpose[@eep_fs76_arr_pedal + 1]: Byte = 0;

  eep_pedal_Channel_A[@eep_fs76_arr_pedal + 2]: Byte = 2;  // Channel Main
  eep_pedal_Channel_B[@eep_fs76_arr_pedal + 3]: Byte = 2;  // Channel unterhalb Split

  eep_pedal_OctaveShift_A[@eep_fs76_arr_pedal + 4]: Byte = 0;   // Oktave Main
  eep_pedal_OctaveShift_B[@eep_fs76_arr_pedal + 5]: Byte = 0;   // Oktave unterhalb Split

  eep_pedal_DynOn_A[@eep_fs76_arr_pedal + 6]: Boolean = false;  // Modus Main
  eep_pedal_DynOn_B[@eep_fs76_arr_pedal + 7]: Boolean = false;  // Modus unterhalb Split

  eep_pedal_UsePitchBnd[@eep_fs76_arr_pedal + 8]: Boolean = false;
  eep_pedal_UseAftTouch[@eep_fs76_arr_pedal + 9]: Boolean = false;
  eep_pedal_UseModwheel[@eep_fs76_arr_upper + 10]: Boolean = false;
  // DynMode: Late OFF  Dyn, EarlyOFF  Dyn, Late ON NoDyn, EarlyON NoDyn
  eep_pedal_DynMode[@eep_fs76_arr_pedal + 11]: Byte = 0;
  eep_pedal_DynSlope[@eep_fs76_arr_pedal + 12]: Byte = 32;
  eep_pedal_ActiveSensing[@eep_fs76_arr_pedal + 13]: Boolean = false;
  eep_pedal_SplitOn[@eep_fs76_arr_pedal + 14]: Boolean = false;
  eep_pedal_SplitPoint[@eep_fs76_arr_pedal + 15]: Byte = 24;

  eep_pedal_KbdType[@eep_fs76_arr_pedal + 16]: Byte = 0;
  eep_pedal_InvertedKbdPolarity[@eep_fs76_arr_pedal + 18]: Boolean = false;

  eep_pedal_Loopdelay[@eep_fs76_arr_pedal + 19]: Byte = 10;
  eep_pedal_DynResetVal[@eep_fs76_arr_pedal + 20]: Byte = 19;
  eep_pedal_FilterCC[@eep_fs76_arr_pedal + 21]: Boolean = false;
  eep_pedal_FilterPrgChnge[@eep_fs76_arr_pedal + 22]: Boolean = false;
  eep_pedal_I2Cflag[@eep_fs76_arr_pedal + 23]: Boolean = true;

  // AUX
  eep_aux_Test[@eep_fs76_arr_aux + 0]: Byte = 0;
  eep_aux_Transpose[@eep_fs76_arr_aux + 1]: Byte = 0;

  eep_aux_Channel_A[@eep_fs76_arr_aux + 2]: Byte = 3;  // Channel Main
  eep_aux_Channel_B[@eep_fs76_arr_aux + 3]: Byte = 3;  // Channel unterhalb Split

  eep_aux_OctaveShift_A[@eep_fs76_arr_aux + 4]: Byte = 0;   // Oktave Main
  eep_aux_OctaveShift_B[@eep_fs76_arr_aux + 5]: Byte = 0;   // Oktave unterhalb Split

  eep_aux_DynOn_A[@eep_fs76_arr_aux + 6]: Boolean = true;   // Modus Main
  eep_aux_DynOn_B[@eep_fs76_arr_aux + 7]: Boolean = true;   // Modus unterhalb Split

  eep_aux_UsePitchBnd[@eep_fs76_arr_aux + 8]: Boolean = false;
  eep_aux_UseAftTouch[@eep_fs76_arr_aux + 9]: Boolean = false;
  //  DynMode: Late OFF  Dyn, EarlyOFF  Dyn, Late ON NoDyn, EarlyON NoDyn
  eep_aux_DynMode[@eep_fs76_arr_aux + 10]: Byte = 0;

  eep_aux_DynSlope[@eep_fs76_arr_aux + 11]: Byte = 32;
  eep_aux_KeyTimerStart[@eep_fs76_arr_aux + 12]: Byte = 25;
  eep_aux_ActiveSensing[@eep_fs76_arr_aux + 13]: Boolean = false;
  eep_aux_SplitOn[@eep_fs76_arr_aux + 14]: Boolean = false;
  eep_aux_SplitPoint[@eep_fs76_arr_aux + 15]: Byte = 24;

  eep_aux_KbdType[@eep_fs76_arr_aux + 16]: Byte = 1;

  eep_aux_InvertedKbdPolarity[@eep_fs76_arr_aux + 18]: Boolean = true;
  eep_aux_Loopdelay[@eep_fs76_arr_aux + 19]: Byte = 10;
  eep_aux_DynResetVal[@eep_fs76_arr_aux + 20]: Byte = 19;
  eep_aux_FilterCC[@eep_fs76_arr_aux + 21]: Boolean = false;
  eep_aux_FilterPrgChnge[@eep_fs76_arr_aux + 22]: Boolean = false;
  eep_aux_I2Cflag[@eep_fs76_arr_aux + 23]: Boolean = true;

// #############################################################################

var
  eep_dummy_filler: Array[0..26] of byte;

// #############################################################################
// #1064 ff. H100 Vibrato Group für Keyswerk von Wurzenrainer
// NICHT MEHR BENUTZT!

// #############################################################################
  eep_ScannerVibSets:Array[0..7, 0..15] of byte;
  eep_ScannerVibSetDump[@eep_ScannerVibSets]:Array[0..127] of byte;

structconst
  eep_VibratoGroup_B3_new[@eep_ScannerVibSets + 0] : array[0..15] of byte = (
    100, // Pre-Emphasis (Treble Gain), ScannerVib Program 0 Setup (B3 default)
    33,  // LC Line Age/AM Amplitude Modulation
    45,  // LC Line Feedback
    67,  // LC Line Reflection
    71,  // LC Line Response Cutoff Frequency
    71,  // LC PhaseLk/Line Cutoff Shelving Level
    66,  // Scanner Gearing (Vib Frequ)
    94,  // Chorus Dry (Bypass) Level
    65,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    77,  // Modulation V3/C3
    15,  // Modulation Chorus Enhance
    109, // Scanner Segment Flutter
    40,  // Preemphasis Highpass Cutoff Frequ
    113); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_B3_old[@eep_ScannerVibSets + 16] : array[0..15] of byte = (
    100,  // Pre-Emphasis (Treble Gain), ScannerVib Program 1 Setup (B3 old)
    48,  // LC Line Age/AM Amplitude Modulation
    54,  // LC Line Feedback
    67,  // LC Line Reflection
    64,  // LC Line Response Cutoff Frequency
    14,  // LC PhaseLk/Line Cutoff Shelving Level
    78,  // Scanner Gearing (Vib Frequ)
    94,  // Chorus Dry (Bypass) Level
    67,  // Chorus Wet (Scanner) Level
    34,  // Modulation V1/C1
    58,  // Modulation V2/C2
    90,  // Modulation V3/C3
    15,  // Modulation Chorus Enhance
    120, // Scanner Segment Flutter
    31,  // Preemphasis Highpass Cutoff Frequ
    97); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_M100[@eep_ScannerVibSets + 32] : array[0..15] of byte = (
    90,  // Pre-Emphasis (Treble Gain), ScannerVib Program 2 Setup (M3/M100)
    91,  // LC Line Age/AM Amplitude Modulation
    40,  // LC Line Feedback
    35,  // LC Line Reflection
    82,  // LC Line Response Cutoff Frequency
    40,  // LC PhaseLk/Line Cutoff Shelving Level
    78,  // Scanner Gearing (Vib Frequ)
    84,  // Chorus Dry (Bypass) Level
    71,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    80,  // Modulation V3/C3
    30,  // Modulation Chorus Enhance
    52,  // Preemphasis Highpass Cutoff Frequ
    71,  // Scanner Segment Flutter
    103); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_H100[@eep_ScannerVibSets + 48] : array[0..15] of byte = (
    95,  // Pre-Emphasis (Treble Gain), ScannerVib Program 3 Setup (H100)
    73,  // LC Line Age/AM Amplitude Modulation
    25,  // LC Line Feedback
    30,  // LC Line Reflection
    100,  // LC Line Response Cutoff Frequency
    55,  // LC PhaseLk/Line Cutoff Shelving Level
    74,  // Scanner Gearing (Vib Frequ)
    85,  // Chorus Dry (Bypass) Level
    70,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    80,  // Modulation V3/C3
    30,  // Modulation Chorus Enhance
    52,  // Preemphasis Highpass Cutoff Frequ
    31,  // Scanner Segment Flutter
    80); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_Boehm[@eep_ScannerVibSets + 64] : array[0..15] of byte = (
    66,  // Pre-Emphasis (Treble Gain), ScannerVib Program 4 Setup (LSI Sine)
    33,  // LC Line Age/AM Amplitude Modulation
    0,  // LC Line Feedback
    28,  // LC Line Reflection
    82,  // LC Line Response Cutoff Frequency
    0,  // LC PhaseLk/Line Cutoff Shelving Level
    70,  // Scanner Gearing (Vib Frequ)
    85,  // Chorus Dry (Bypass) Level
    70,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    80,  // Modulation V3/C3
    24,  // Modulation Chorus Enhance
    52,  // Preemphasis Highpass Cutoff Frequ
    71,  // Scanner Segment Flutter
    66); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_Square[@eep_ScannerVibSets + 80] : array[0..15] of byte = (
    88,  // Pre-Emphasis (Treble Gain), ScannerVib Program 5 Setup (LSI Square)
    20,  // LC Line Age/AM Amplitude Modulation
    40,  // LC Line Feedback
    30,  // LC Line Reflection
    109,  // LC Line Response Cutoff Frequency
    55,  // LC PhaseLk/Line Cutoff Shelving Level
    74,  // Scanner Gearing (Vib Frequ)
    74,  // Chorus Dry (Bypass) Level
    70,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    80,  // Modulation V3/C3
    18,  // Modulation Chorus Enhance
    0,  // Preemphasis Highpass Cutoff Frequ
    47,  // Scanner Segment Flutter
    33); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_Conn[@eep_ScannerVibSets + 96] : array[0..15] of byte = (
    105,  // Pre-Emphasis (Treble Gain), ScannerVib Program 6 Setup (Conn SNG)
    96,  // LC Line Age/AM Amplitude Modulation
    25,  // LC Line Feedback
    30,  // LC Line Reflection
    82,  // LC Line Response Cutoff Frequency
    40,  // LC PhaseLk/Line Cutoff Shelving Level
    78,  // Scanner Gearing (Vib Frequ)
    74,  // Chorus Dry (Bypass) Level
    68,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    80,  // Modulation V3/C3
    71,  // Modulation Chorus Enhance
    52,  // Preemphasis Highpass Cutoff Frequ
    71,  // Scanner Segment Flutter
    103); //  Modulation Slope, Preemph HP Phase/Peak
  eep_VibratoGroup_Combo[@eep_ScannerVibSets + 112] : array[0..15] of byte = (
    37,  // Pre-Emphasis (Treble Gain), ScannerVib Program 7 Setup (Combo)
    33,  // LC Line Age/AM Amplitude Modulation
    0,  // LC Line Feedback
    0,  // LC Line Reflection
    127,  // LC Line Response Cutoff Frequency
    0,  // LC PhaseLk/Line Cutoff Shelving Level
    70,  // Scanner Gearing (Vib Frequ)
    85,  // Chorus Dry (Bypass) Level
    70,  // Chorus Wet (Scanner) Level
    30,  // Modulation V1/C1
    55,  // Modulation V2/C2
    84,  // Modulation V3/C3
    24,  // Modulation Chorus Enhance
    0,  // Preemphasis Highpass Cutoff Frequ
    78,  // Scanner Segment Flutter
    0); //  Modulation Slope, Preemph HP Phase/Peak



// #############################################################################
// Button-Remap über Tabelle: Index ist phys. Button-Nummer,
// #############################################################################

// Eintrag ist edit_LogicalTabs-Index (oberes Nibble) und Bit-Nummer (unteres Nibble)
// Index: Button-Nummer 0..63, übersetzt Button-Nummer in Tab-Nummer
// Panel16_0 obere Reihe, sollte wg. Percussion so bleiben, sonst
{
    0, 1, 2, 3, 4, 5, 6, 7,                   // Panel16_0 obere Reihe
    8, 9, 10, 11, 12, 13, 14, 15,             // Panel16_1 untere Reihe
    16, 17, 18, 19, 20, 21, 22, 23,           // Panel16_2 obere Reihe
    24, 25, 26, 27, 28, 29, 30, 31,           // Panel16_2 untere Reihe
    32, 33, 34, 35, 36, 37, 38, 39,           // Panel16_3 obere Reihe
    40, 41, 42, 43, 44, 45, 46, 47,           // Panel16_3 untere Reihe
    48, 49, 50, 51, 52, 53, 54, 55,           // Panel16_4 obere Reihe
    56, 57, 58, 59, 60, 61, 62, 63            // Panel16_4 untere Reihe
}
structconst
  eep_BtnRemaps: Array[0..95] of byte = (
    // Panel 0, Input 0..15
    c_map_voice_upr, c_map_voice_upr, c_map_voice_upr, c_map_voice_upr,
    c_map_voice_upr, c_map_voice_upr, c_map_voice_upr, c_map_voice_upr,
    c_map_voice_upr, c_map_voice_upr, c_map_voice_upr, c_map_voice_upr,
    c_map_voice_upr, c_map_voice_upr, c_map_voice_upr, c_map_voice_upr,
    // Panel 1, Input 16..31
    c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr,
    c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr,
    c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr,
    c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr, c_map_voice_lwr,
    // Panel 2 (onboard), Input 32..47
    0, 1, 2, 3, 4, 5, 6, 7,                          // Panel 2 obere Reihe
    84, 85, 86, 87,                                  // Vib/Preset Btns
    12, 13, 14, 15,                                  // Panel 2 untere Reihe
    // Panel 3, Input 48..63
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    // Panel 4, Input 64..79
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    // Panel 5, Input 80..96
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end
  );


// #############################################################################
// MIXTURE SETS, Drawbar-zu-Busbar-Mapping
// #############################################################################

// Es kann ein Busbar-Pegel nur EINEM Zugriegel zugeordnet werden!
// Wert > 0 ist gleichzeitig Flag, dass dieser Busbar schon einem DB zugeordnet ist.
// Er wird dann keinem anderem mehr zugewiesen.
// DB10 ist vorrangig vor DB11, DB11 ist vorrangig vor DB12
// Drawbar-zu-Busbar-Mapping, 10. Zugriegel (erster nach 1')
var
  eep_MixtureTables: Array[0..131] of byte;

structconst
  eep_DB10_StdMixtureSet[@eep_MixtureTables + 0]:Array[0..5] of byte =
    // 9, 10, 11, 12, 13, 14 BUSBAR 9..14
    (127,127,  0,  0,  0,  0);    // Set 0, B3/H100 7th and 9th

  eep_DB10_MixtureSets[@eep_MixtureTables + 6]:Array[0..3, 0..5] of byte = (
    // 9, 10, 11, 12, 13, 14  BUSBAR 9..14
    (127,127,  0,  0,  0,  0),    // Set 4, LSI SINE (Böhm)
    (  0,  0,127,  0,  0,  0),    // Set 5, LSI SQUARE (Wersi)
    (127,127,  0,  0,  0,  0),    // Set 6, CONN SINGLE NOTE
    (  0,  0,  0,  0,  0,  0)     // Set 7, CHEESY COMBO
    );

  eep_DB11_StdMixtureSet[@eep_MixtureTables + 30]:Array[0..5] of byte =
    // 9, 10, 11, 12, 13, 14 BUSBAR 9..14
    (  0,  0,127,127,  0,  0);    // Set 0, B3/H100 10th and 12th

  eep_DB11_MixtureSets[@eep_MixtureTables + 36]:Array[0..3, 0..5] of byte = (
    // 9, 10, 11, 12, 13, 14 BUSBAR 9..14
    (  0,  0,127,  0,127,  0),    // Set 4, LSI SINE (Böhm)
    (  0,  0,  0,  0,127,  0),    // Set 5, LSI SQUARE (Wersi)
    (  0,  0,127,127,  0,  0),    // Set 6, CONN SINGLE NOTE
    (  0,  0,  0,  0,  0,  0)     // Set 7, CHEESY COMBO
    );

  eep_DB12_StdMixtureSet[@eep_MixtureTables + 60]:Array[0..5] of byte =
    // 9, 10, 11, 12, 13, 14 BUSBAR 9..14
    (  0,  0,  0,  0,  0,127);    // Set 0, B3/H100 Chime 1 1/4

  eep_DB12_MixtureSets[@eep_MixtureTables + 66]:Array[0..3, 0..5] of byte = (
    // 9, 10, 11, 12, 13, 14 BUSBAR 9..14
    (  0,  0,  0,  0,  0,127),    // Set 4, LSI SINE (Böhm)
    (127,100,  0,  0,  0,  0),    // Set 5, LSI SQUARE (Wersi)
    (  0,  0,  0,  0,127,  0),    // Set 6, CONN SINGLE NOTE
    (  0,  0,  0,  0,  0,  0)     // Set 7, CHEESY COMBO
    );

var
  eep_BusBarNoteOffsetTables: array[0..39] of byte;

structconst

  eep_StdBusBarNoteOffsets[@eep_BusBarNoteOffsetTables + 0]: Array [0..15] of byte =
    // 0   1   2   3   4   5   6   7   8 # 9  10  11  12  13  14 (15)   // BUSBAR
    (  0, 19, 12, 24, 31, 36, 40, 43, 48, 46, 50, 51, 54, 55, 44,  0);  // B3/H100 +Chime 1 1/4 (14) #1600 ff.

  eep_MixtureBusBarNoteOffsets[@eep_BusBarNoteOffsetTables + 16]: Array [0..3, 0..5] of byte = (
    // 9  10  11  12  13  14    // BUSBAR
    ( 46, 50, 51, 54, 55, 60),  // LSI SINE (Böhm)
    ( 46, 50, 52, 54, 55, 60),  // LSI SQUARE (Wersi)
    ( 46, 50, 51, 54, 55, 44),  // CONN SINGLE NOTE
    ( 46, 50, 51, 52, 55, 44)   // CHEESY COMBO
    );

// #############################################################################
// Remap-Tabelle für Analogeingänge, Index: ADC-Kanal
// #############################################################################

{$IFNDEF MODULE}
    // Remap-Tabelle für Analogeingänge, Index: ADC-Kanal
  eep_ADCremaps : Array[0..87] of byte = (
    0,1,2,3,4,5,6,7,8,                   // #0..#8 Upper DBs
    80,                                  // #9 Master Volume
    81,                                  // #10 Leslie Volume
    c_map_none,                          // #11 nicht belegt (war mk4 Schweller)
    16,17,18,19,20,21,22,23,24,          // #12..#20 Lower DBs
    72,74,                               // #21, #22 Pedal DBs
    64+3,                                // #23 Pedal ADSR Release
    // Eintrag #24, ab hier SR-MPX-Eingang
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end
  );
{$ENDIF}

// Menü-Enabled-Tabelle
// sollte als Letztes stehen, da sich Länge ändern kann
  eep_MenuValidArr: array[0..255] of Boolean = (
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true
  );

  eep_Owner        : string[23] = 'KeyboardPartner';

  // Faktoren für Drawbar-Mix bei 4 Drawbars, Initialwerte
  eep_Pedal4DBfacs8: Array [0..11] of byte =
    // 0  1   2   3    4   5   6   7   8  9  10 11   // Drawbar
    (  0, 0, 120, 127, 75, 65, 55, 55, 0, 0, 0, 0
    );
  eep_Pedal4DBfacs8H: Array [0..11] of byte =
    // 0  1   2   3    4    5   6   7   8   9 10 11   // Drawbar
    (  0, 0, 127, 100, 60, 30, 20, 20, 0, 0, 0, 0
    );
  eep_Pedal4DBfacs16: Array [0..11] of byte =
    //  0   1   2   3   4   5  6  7  8  9  10  11   // Drawbar
    (  105, 122, 127, 95, 35, 20, 20, 0, 0, 0, 0, 0
    );
  eep_Pedal4DBfacs16H: Array [0..11] of byte =
    //  0   1   2   3   4   5   6   7  8  9  10  11   // Drawbar
    (  127, 60, 80, 45, 25, 15, 10, 0, 0, 0,  0,  0
    );

  eep_SwitchInputArr: array[0..95] of Boolean = (
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false
  );

  // Btn Idx  0      1      2      3
  // +0       SOLO   2ND    3RD    VIB    - xb2_hw_tabs[0..3]
  // +4       CANCEL REC    EDIT   S/F    - xb2_hw_tabs[4..7]
  // +8       PR1    PR2    PR3    PR4    - xb2_hw_tabs[8..11]
  // +12      PR5    PR6    PR7    PR5    - xb2_hw_tabs[12..15]
  eep_BtnRemaps_XB: Array[0..31] of byte= (
    15, 89, 88, 14,  // Split auf SOLO
    31, 9, c_map_none, c_map_none,           // Equ Bypass, Rotary Spkr Bypass
    84, 85, 86, 87,                          // Vib Btns
    12, 13, 1, 2,                            // Reverb 1/2, Perc Soft/Fast
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end,
    c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end, c_map_end
    );

  // ggf. andere als vorgegebene Voreinstellungs-Reihenfolge
  eep_OrganModelAssignments: Array[0..15] of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);

  eep_SpeakerModelAssignments: Array[0..15] of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);

var
  eep_XB5_BtnRemaps_dummy: Array[0..15] of byte;

{$NOOVRCHECK}
  EE_DB_dumpArr[@eep_upperDBpresets]: Array[0..511] of byte;

{$NOOVRCHECK}
  EE_dumpArr[@EE_OverwriteFlag]: array[0..4095] of byte;

{$VALIDATE_OFF}
{$IDATA}

implementation

end eeprom_def.


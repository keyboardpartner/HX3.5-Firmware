// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################

unit const_def;

interface

type
  // Quelle einer Parameter-Änderung
  t_connect = (t_connect_midi, t_connect_osc_midi, t_connect_editor_midi,
              t_connect_osc_wifi, t_connect_editor_serial, t_disable);

  t_menuType = (
    tm_none, tm_limitm_goto,
    tm_drawbar,
    // Reihenfolge wie NRPN/GM_VoiceName-Array!
    // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
    tm_gm_prg0, tm_gm_prg1, tm_gm_prg2, tm_gm_prg3_dummy,
    tm_gm_prg4, tm_gm_prg5, tm_gm_prg6,
    tm_preset_common, tm_preset_upper, tm_preset_lower, tm_preset_pedal,
    tm_perc, tm_reverb,
    tm_vibknob, tm_vib_on_upr, tm_vib_on_lwr, ta_vibbtn,
    tm_numeric, tm_boolean,
    tm_midichannel,  tm_tuning, tm_transpose,
    tm_modphasebits, tm_editname,
    tm_items_splitm,  tm_items_midiopt,
    tm_items_localena, tm_items_waveset,
    tm_items_ccset, tm_items_capset, tm_items_spread,
    tm_items_fb16, tm_items_swelltype, tm_items_gatingmode,
    tm_items_organmodel, tm_items_SpeakerModel,
    tm_items_phrmode, tm_adsrena_upr, tm_adsrena_lwr, tm_button,
    tm_bassfreq, tm_midfreq, tm_treblefreq,
    tm_setupfile, tm_initwifi, tm_initpreset,
    tm_savedefault, tm_bootloader
  );

const

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  c_min_date: LongInt = $20221012; // FPGA YYYY MM DD (!)
  // letzte 4 Bytes vor Bootloader ($1F000) = $1EFFC
  c_CurrentFirmwareVersion[$1EFFE]: Word   = $0580;
  // Erhöhen, wenn sich eep_defaults-Array-Struktur ändert:
  c_FirmwareStructureVersion: Byte   = 80;  // Dezimalstellen FW-Version
  // Wenn bestehende EEPROM-Version kleiner, wird DB-Bereich überschrieben
  c_SkipEEPROM_DBs: Word   = $400;
  // Self-FlashWrite from DF, BOOTSZ0-Fuse = $FC000 (*2 = $1F800):
  c_BootSection: LongInt = $1F800;    // Einsprungadresse in geschützten Bereich

  c_MinimalPresetStructureVersion: Byte = 31;
  c_MinimalOrganStructureVersion: Byte = 60;
  c_MinimalRotaryStructureVersion: Byte = 60;
  c_CurrentPresetStructureVersion: Byte = 60;
  c_CurrentOrganStructureVersion: Byte = 60;
  c_CurrentRotaryStructureVersion: Byte = 60;

{$TYPEDCONST OFF}

  Vers1Str  = '5.836';    // müssen 5 Zeichen sein!
  Vers1Hex: Word = $5836;

  {$IFNDEF MODULE}
  // Dieses müssen die ersten Strings mit "HX3." im Firmware-File sein,
  // da der HX3 Manager beim Start nach dieser Signatur sucht.
    SysExDeviceStr  = 'HX3.5 TrueOrgan ' // 16 Bytes
                    + '#' + Vers1Str;    // +8 Bytes
    Vers2Str  = 'HX3 mk5, ';
    Vers3Str        = 'TrueOrgan';
  {$ELSE}
    SysExDeviceStr  = 'HX3.5 RealOrgan '   // 16 Bytes
                    + 'V. ' + Vers1Str;    // +8 Bytes
    Vers2Str  = 'HX3 mk7, ';
    Vers3Str        = 'RealOrgan';
  {$ENDIF}

  LCD1Str   = 'HX3.5 #' + Vers1Str;    // Kurzform von Vers1 für LCD

  c_PresetNameStr0        = 'Startup/Live';
  s_none = '(none)';
  s_autorun_ini = 'autorun.ini';
  s_config_ini = 'config.ini';
  s_autorun_ini_old = '_autorun.ini';
  s_config_ini_old = '_config.ini';

{$TYPEDCONST ON}

  high:  boolean = true;
  low:   boolean = false;

// #############################################################################
// ###                     Dataflash Block-Belegung                          ###
// #############################################################################

  // Länge $C439F je XC6S25 Image, Rest frei bis einschl. Block $31F
  // Zwischen FPGA und PB Core sind 144 Blöcke frei für Daten, 100 für Presets benutzt
{$IFDEF SPARTAN7}
  c_FPGA_lastblock: Word = $130;  // Shadow nicht nutzbar!
{$ELSE}
  c_FPGA_lastblock: Word = $0C4;
{$ENDIF}
  // Diese Werte müssen auch dem Editor bekannt sein:
  c_FPGA_base_DF: Word = 0;  // bis Block $012F = 303 dez.
  // Failsafe-Images für FPGA und Scan Driver falls normale korrumpiert
  // Falls es Bootloader nicht gelingt, FPGA und Scan Driver zu starten,
  // wird Image aus diesen Bereichen umkopiert und FPGA-Start erneut versucht.
  // Nötig, um ggf. Zugriff auf SAM-Flash über FPGA und DFU zu ermöglichen
  // Failsafe-Binaries können/dürfen nur von SD-Karte aufgespielt werden!
  c_FPGA_failsafe_base_DF: Word = $140;  // 320, bis Block $0270 = 624 dez.
  c_scan_failsafe_base_DF: Word = $278;  // 632, zwei Blocks
  c_dfudl_failsafe_DF: Word     = $27C;  // 636, letzte geladene DFUDL-Table mit Failsafe

  c_update_info_DF: Word        = $27D;  // 637, DFUDL-Info-Block, für Firmware
  c_param_update_list_DF: Word  = $27E;  // 638, PUL-Block, für Firmware
  c_boardinfo_DF: Word          = $27F;  // 639, Block mit Seriennummern, Username etc.

  // 16 Rotary-Modelle (Einstellungen für Rotary Setup)
  c_leslieModel_base_DF: Word   = $300;  // 768, nach Firmware-Image
  // 16 Orgelmodelle (Einstellungen für Vibrato, Generator, Gating, Mixturen etc.
  c_organModel_base_DF: Word    = $310;  // 784, nach Rotary Models

  // Freie Blöcke für Daten, 100 für Presets benutzt
  c_preset_base_DF: Word  = $320;  // 800..899
  // Platz für 16 MIDI-CC-Sets je 4K:
  c_midicc_base_DF: Word  = $3A0;  // 928, erster 4k-Block nach Presets

  c_core_base_DF: Word     = $3B0;    // 944, erster 4k-Block nach FPGA-Image(s)
  c_scan_base_DF: Word     = $3B0;    // 944, erster 4k-Block nach FPGA-Image(s)
  c_voice_base_DF: Word    = c_core_base_DF + 2;    // 946, Zugriegel-Arrays, Länge 1 Block
  c_defaults_base_DF: Word = c_core_base_DF + 3;    // 947, EEPROM-simulation bei ARM
  c_taper_base_DF: Word    = c_core_base_DF + 11;   // 955..958, Länge 4 x 1 Block
  c_coeff_base_DF: Word    = c_core_base_DF + 15;   // 959, Länge 1 Block
  c_waveset_base_DF: Word  = $3C0;   // 960, Länge 32 (8 x 4 Blocks)

  c_eeprom_base35_DF: Word   = c_core_base_DF + 9;    // 953, EEPROM AVR
  c_firmware_base35_DF: Word = $3E0;  // 32 Blöcke, 128 KByte

// #############################################################################
// ###                       BLOCKBUFFER   OFFSETS                           ###
// #############################################################################

  c_edit_array_offs: Word   = 0;     // Offset zu c_edit_addr
  c_edit_array_len: Word    = 512;
  c_leslie_array_len: Word  = 64;
  c_common_preset_len: Word = 496;  // Ohne System Inits
  c_edit_ext_len: Word      = 1536;      // 1,5 KByte am Ende des RAM-Bereichs
  c_edit_ext_offs: Word     = c_edit_array_offs + 512;
  c_edit_all_len: Word = c_edit_ext_offs + c_edit_ext_len;  // 2048 Bytes

  c_midiarr_dflen: Word = 3328; // ganze 256-Byte-Seiten für Dataflash-Routinen
  c_midiarr_len: Word = 3200;   // inkl. NRPN-Array 3200
  c_midicc_len:  Word = 3072;   // nur CC-Array

  c_voiceblock_len: Word = 832 + 2;   // plus Word für Init-Flag

  c_table_0: Word = 0;
  c_UpperDBs: Word = c_table_0 + 0;
  c_LowerDBs: Word = c_table_0 + 16;
  c_PedalDBs: Word = c_table_0 + 32;
  c_ADSR: Word = c_table_0 + 48;
  c_PedalDB4s: Word = c_table_0 + 72;
  c_PreampGroup: Word = c_table_0 + 80;
  c_UpperEnvelopeDBs: Word = c_table_0 + 96;
  c_EqualizerGroup: Word = c_table_0 + 112;
  c_LogicalTabs: Word = c_table_0 + 128;
  c_LogicalTab_Specials: Word = c_table_0 + 208;
  c_GMprogs: Word = c_table_0 + 224;
  c_SaveEventDefaults: Word = 247;
  c_SaveEventOrganModel: Word = 248;
  c_SaveEventSpeakerModel: Word = 249;

  c_LogicalTab_PercBtns: Word  = c_table_0 + 128;
  c_LogicalTab_VibBtns: Word = 212;

  c_SaveEventPreset: Word = 252;
  c_SaveEventUpper: Word = 253;
  c_SaveEventLower: Word = 254;
  c_SaveEventPedal: Word = 255;

  c_table_1: Word = c_table_0 + 256;

  c_knobs: Word = 260;   // 8 Bytes bis 267
  c_GatingKnob: Word = 261;
  c_PercKnob: Word = 262;
  c_ReverbKnob: Word = 263;
// @8, #1264 ff. "Drehknöpfe", exklusive Stellungen, werden auf edit- oder Tab-Werte umgesetzt
  c_VibKnob: Word = 264; // #1264 Bedienfeld-Stellung

  c_OrganModel: Word = 265; // #1265
  c_SpeakerModel: Word = 266; // #1266

// @12, #1268 ff. Voices und Presets
  c_voices: Word = c_table_1 + 12;
  c_CommonPreset: Word = c_voices + 0;
  c_UpperVoice: Word = c_voices + 1;
  c_LowerVoice: Word = c_voices + 2;
  c_PedalVoice: Word = c_voices + 3;

  c_PresetNameStrArr: Word = 192;  // Preset-Name im Preset-Block

  c_VibratoGroup: Word = c_table_1 + 64;
  c_PhasingGroup: Word = c_table_1 + 80;
  c_KeyboardGroup: Word = c_table_1 + 96;
  c_MidiGroup: Word = c_table_1 + 112;
  c_GeneratorGroup: Word = c_table_1 + 128;
  c_EffectsGroup: Word = c_table_1 + 144;
  c_MixtureLevels: Word = c_table_1 + 160;
  c_RotaryGroup: Word = c_table_1 + 192;

  c_pidx_transpose: Word = 395;

  c_Audio_Enables: Word = 397;
  c_EnableUpperAudio: Word = c_Audio_Enables + 0; // #1397
  c_EnableLowerAudio: Word = c_Audio_Enables + 1; // #1398
  c_EnablePedalAudio: Word = c_Audio_Enables + 2; // #1399


  c_ReverbLevels: Word = c_EffectsGroup + 0;
  c_ReverbLevel_1: Word = c_ReverbLevels + 0;
  c_ReverbLevel_2: Word = c_ReverbLevels + 1;
  c_ReverbLevel_3: Word = c_ReverbLevels + 2;

// @240, #1496 ff. Defaults, alles mögliche, nur zum Start und Reset gelesen
  c_SystemInits: Word = 496;
  c_VibKnobMode: Word = c_SystemInits + 1; // #1497
  c_RestoreCommonPresetMask: Word = c_SystemInits + 2; // #1498
  c_ButtonMask0: Word = c_SystemInits + 3; // #1499 ALT
  c_ButtonMask1: Word = c_SystemInits + 4; // #1500 ALT
  c_ConfBits1: Word = c_SystemInits + 5; // #1501
  c_ConfBits2: Word = c_SystemInits + 6; // #1502
  c_ADCconfig: Word = c_SystemInits + 7; // #1503
  c_1stDBselect: Word = c_SystemInits + 8; // #1504
  c_2ndDBselect: Word = c_SystemInits + 9; // #1505
  c_PedalDBsetup: Word = c_SystemInits + 10; // #1506
  c_ADCscaling: Word = c_SystemInits + 11; // #1507
  // c_LatchingPresets = c_SystemInits + 12; // #1508
  c_DeviceType: Word = c_SystemInits + 13; // #1509
  c_PresetStructure: Word = c_SystemInits + 14; // #1510
  c_EditMagicFlagIdx: Word = c_SystemInits + 15; // #1511


// Fehlerkonstanten für SysEx <er>, die falls >0 aufgetretene Fehler
// in einem 8-Bit-Feld anzeigen. Fehler können kombiniert auftreten.
// Bit 0 = SysEx-Befehl unbekannt (nur wenn auf 0 oder 0x33 addressiert, der Rest interessiert nicht)
//         oder es wurde versucht, einen unbekannten Parameter zu setzen oder zu lesen.
//         Dieses Bit wird nach Ausgeben des Status-SysEx wieder gelöscht.
//         Alle anderen sind persistent, bleiben also bis zum Reboot gesetzt.
// Bit 1 = SD-Karte nicht erkannt/fehlerhaft (darf 1 sein, weil nicht immer eine SD-Karte steckt),
//         Datei auf SD nicht gefunden
// Bit 2 = Nicht finalisiert
// Bit 3 = Flash Write/Erase-Fehler, Hardware defekt!
// Bit 4 = Booten der FPGA-Konfiguration oder des ScanCore (MIDI-Interpreter) fehlgeschlagen
// Bit 5 = Update von SD fehlgeschlagen
// ErrFlags: Byte;
  c_err_cmd:       Byte = 0;    // Bit 0 = +1
  c_err_sd:        Byte = 1;    // Bit 1 = +2
  c_err_finalized: Byte = 2;    // Bit 2 = +4
  c_err_flash:     Byte = 3;    // Bit 3 = +8
  c_err_conf:      Byte = 4;    // Bit 4 = +16
  c_err_upd:       Byte = 5;    // Bit 5 = +32
  c_err_timeout:   Byte = 6;   // Bit 6 = +64
  c_err_locked:    Byte = 6;

  c_ErrStrArr      : Array[0..6] of String[4] = (
  'CMD', 'SD ', 'FIN', 'DF', 'CONF', 'UPD', 'PAR');

// #############################################################################
// ###                        Analog Input Mapping                           ###
// #############################################################################

  c_map_volumepot:  Byte = 80;
  c_map_first_logpot:    Byte = 80;
  c_map_last_logpot:     Byte = 95;
  c_map_midi_sendpot_0:  Byte = 200;
  c_map_midi_sendpot_11: Byte = 211;

// #############################################################################
// ###                       Digital Input Mapping                           ###
// #############################################################################

// Button Assigns für spezielle Behandlung in swi_get_TabLED_bits
  c_map_percon:  Byte = 0;
  c_map_percsoft:  Byte = 1;
  c_map_percfast:  Byte = 2;
  c_map_perc3rd:   Byte = 3;
  c_map_leslierun:    Byte = 6;
  c_map_dectranspose: Byte = 76;
  c_map_inctranspose: Byte = 77;
  c_map_incdec_firstbtn: Byte = 64;
  c_map_incdec_lastbtn:  Byte = 79;


  c_map_singledb_toggle: Byte = 90;
  c_map_singledb_upr:    Byte = 91;
  c_map_singledb_lwr:    Byte = 92;
  c_map_singledb_ped:    Byte = 93;

// Button Assigns für Preset/Voice Groups
  c_map_preset: Byte = 100;         // btn_type_idx: Byte = 0
  c_map_voice_upr: Byte = 101;      // btn_type_idx: Byte = 1
  c_map_voice_lwr: Byte = 102;      // btn_type_idx: Byte = 2
  c_map_voice_ped: Byte = 103;      // btn_type_idx: Byte = 3

  c_map_binary_preset: Byte = 104;         // btn_type_idx: Byte = 4
  c_map_binary_voice_upr: Byte = 105;      // btn_type_idx: Byte = 6
  c_map_binary_voice_lwr: Byte = 106;      // btn_type_idx: Byte = 7
  c_map_binary_voice_ped: Byte = 107;      // btn_type_idx: Byte = 8
  c_map_binary_voice_ul: Byte = 108;       // btn_type_idx: Byte = 9
  c_map_binary_voice_ulp: Byte = 109;      // btn_type_idx: Byte = 10
  c_map_binary_voice_lp: Byte = 110;       // btn_type_idx: Byte = 11

  c_map_organmodel: Byte = 112;           // btn_type_idx: Byte = 12
  c_map_speakermodel: Byte = 113;         // btn_type_idx: Byte = 13

  c_map_firsttype: Byte = c_map_preset;     // Erster Typ-Index (0)
  c_map_lasttype: Byte = c_map_speakermodel;       // Letzter Typ-Index (13)

  c_map_cancel_upr: Byte = 120;
  c_map_cancel_lwr: Byte = 121;

  c_map_none: Byte = 254;
  c_map_end: Byte = 255;

  c_mapidx_preset: byte = 0;                // btn_type_idx = 0
  c_mapidx_voice_upr: byte = c_map_voice_upr - c_map_firsttype;          // btn_type_idx = 1
  c_mapidx_voice_lwr: byte = c_map_voice_lwr - c_map_firsttype;          // btn_type_idx = 2
  c_mapidx_voice_ped: byte = c_map_voice_ped - c_map_firsttype;          // btn_type_idx = 3

  c_mapidx_binary_preset: byte = c_map_binary_preset - c_map_firsttype ;  // btn_type_idx = 4
  c_mapidx_binary_voice_upr: byte = c_map_binary_voice_upr - c_map_firsttype;   // btn_type_idx = 5
  c_mapidx_binary_voice_lwr: byte = c_map_binary_voice_lwr - c_map_firsttype;   // btn_type_idx = 6
  c_mapidx_binary_voice_ped: byte = c_map_binary_voice_ped - c_map_firsttype;   // btn_type_idx = 7
  c_mapidx_binary_voice_ul: byte = c_map_binary_voice_ul - c_map_firsttype;     // btn_type_idx = 8
  c_mapidx_binary_voice_ulp: byte = c_map_binary_voice_ulp - c_map_firsttype;   // btn_type_idx = 9
  c_mapidx_binary_voice_lp: byte = c_map_binary_voice_lp - c_map_firsttype;     // btn_type_idx = 10

  c_mapidx_organmodel: byte = c_map_organmodel - c_map_firsttype;      // btn_type_idx = 12
  c_mapidx_speakermodel: byte = c_map_speakermodel - c_map_firsttype;  // btn_type_idx = 13

  c_mapidx_firsttype: byte = c_mapidx_preset;     // Erster Typ-Index (0)
  c_mapidx_lasttype: byte = c_mapidx_speakermodel ;        // Letzter Typ-Index (13)

  c_mapidx_max: Byte = c_map_lasttype - c_map_firsttype;
  c_mapidx_count_w: Word = Word(c_mapidx_lasttype) + 1;    // Anzahl (14)

// #############################################################################
// ###                   Save/Restore Mask (Matrix)                          ###
// #############################################################################

// Control Type (aus SaveRestoreMask Table)
// Event Control Types
// Bit 12..15 in Save/Restore Mask
  c_controlTypeNone: Byte = 0;
  c_controlTypeButton: Byte = 1;
  c_controlTypeKnob: Byte = 2;
  c_controlTypeAnalog: Byte = 3;
  c_controlTypeButtonToKnob: Byte = 4;
  c_controlTypeKnobToButton: Byte = 5;
  c_controlTypeMomentary: Byte = 6;
  c_controlTypeNumber: Byte = 7;
  c_controlTypeString: Byte = 8;
  c_controlTypeSaveEnter: Byte = 15;

// Bit 8..11 in Save/Restore Mask
  c_savedestNone: Byte = 0;        // None/Unsaved
  c_savedestUpperDBs: Byte = 1;    // Upper Drawbars
  c_savedestLowerDBs: Byte = 2;    // Lower Drawbars
  c_savedestPedalDBs: Byte = 3;    // Pedal Drawbars
  c_savedestPreset: Byte = 4;      // Common Preset
  c_savedestPresetifGM: Byte = 5;      // Common Preset, valid only if PresetGM-Mask = 1
  c_savedestPresetifPercEG: Byte = 6;  // Common Preset, valid only if PresetPercDB-Mask = 1
  c_savedestOrganModel: Byte = 7;      // Organ Model
  c_savedestSpeakerModel: Byte = 8;    // Speaker Model
  c_savedestDefaults: Byte = 9;        // Defaults
  c_savedestExtendedParams: Byte = 10; // Extended Params >= #2000
  c_savedestSystemInits: Byte = 11;    // System Inits

  c_presetGMRecallMaskBit: Byte = 7;     // in edit_SaveRestoreMask1
  c_presetVolEqRecallMaskBit: Byte = 6;
  c_presetRotaryRecallMaskBit: Byte = 5;
  c_presetTabsRecallMaskBit: Byte = 4;
  c_presetPercDBsRecallMaskBit: Byte = 3;
  c_pedalRecallMaskBit: Byte = 2;
  c_lowerRecallMaskBit: Byte = 1;
  c_upperRecallMaskBit: Byte = 0;

  c_destchar_arr: Array[0..15] of Char =
    (' ', 'U', 'L', 'P', 'C', 'C', 'C', 'O',
     'R', 'D', 'E', 'I', ' ', ' ', ' ', ' ');


// #############################################################################
// ###                          Event Sources                                ###
// #############################################################################

  c_to_fpga_event_source: Byte  = 1;   // nur an FPGA, ohne Quelle
  c_board_event_source: Byte    = 2;   // eigene Events durch verknüpfte Einstellungen
  c_preset_event_source: Byte   = 4;   // durch Preset-Load ausgelöstes Event
  c_editor_event_source: Byte   = 8;   // über Serial gekommen
  c_midi_event_source: Byte     = 16;  // über MIDI als CC gekommen
  c_midi_sysex_source: Byte     = 32;  // über MIDI vom Editor gekommen
  c_control_event_source: Byte  = 64;  // eigene Events durch Bedienelemente/Tabs
  c_menu_event_source: Byte     = 128; // eigene Events durch MenuPanel

// #############################################################################

  // CycleSteal-Werte, A 440 = 7 (433 .. 447 Hz)
  c_TuningTable: Array[0..15] of byte = (
    142,145,148,154,163,180,232,
    0,
    18,72,92,101,106,110,112,112);

  // aus DrawbarLogTable_std_neu.xls importiert
  c_DrawbarLogTable : Array[0..127] of byte = (
    0, 0, 0, 1, 1, 1, 1, 1,             // 0..63
    1, 2, 2, 2, 2, 2, 3, 3,
    3, 3, 4, 4, 4, 5, 5, 5,
    6, 6, 7, 7, 8, 8, 9, 9,
    10, 10, 11, 11, 12, 13, 13, 14,
    15, 15, 16, 17, 17, 18, 19, 20,
    20, 21, 22, 23, 24, 24, 25, 26,
    27, 28, 29, 30, 31, 32, 33, 34,

    35, 36, 37, 38, 39, 40, 41, 43,     // 64..127
    44, 45, 46, 47, 48, 50, 51, 52,
    54, 55, 56, 57, 59, 60, 62, 63,
    64, 66, 67, 69, 70, 72, 73, 75,
    76, 78, 79, 81, 82, 84, 86, 87,
    89, 91, 92, 94, 96, 97, 99, 101,
    103, 105, 106, 108, 110, 112, 114, 116,
    118, 119, 121, 123, 125, 127, 127, 127  );

{
  c_TimeLogTable: Table[0..127] of word = (
    13998, 13149, 12353, 11604, 10901, 10240, 9619, 9036, 8488, 7974, 7491, 7037,
    6610, 6209, 5833, 5479, 5147, 4835, 4542, 4266, 4008, 3765, 3536, 3322, 3120,
    2931, 2753, 2586, 2429, 2282, 2143, 2013, 1891, 1776, 1668, 1567, 1472, 1382,
    1298, 1219, 1145, 1076, 1010, 949, 891, 837, 786, 738, 693, 651, 611, 574,
    539, 506, 475, 446, 419, 393, 369, 347, 325, 305, 287, 269, 252, 237, 222,  // 53..67
    209, 196, 184, 172, 162, 152, 142, 133, 125, 117, 110, 103, 96, 90, 85,     // 68..83
    79, 74, 69, 65, 61, 57, 53, 50, 46, 43, 41, 38, 35, 33, 31, 29, 27, 25, 23, // 84..101
    21, 20, 18, 17, 16, 15, 13, 12, 11, 10, 10, 9, 8, 7, 7, 6, 5, 5, 4, 4, 3,   // 100..121
    3, 2, 2, 2, 1, 1);                                                          // 122..127
}

c_TimeLogTable: Array[0..127] of word = (
  15000, // 0
  15000, // 1
  4305, // 2
  4097, // 3
  3899, // 4
  3710, // 5
  3531, // 6
  3361, // 7
  3199, // 8
  3044, // 9
  2897, // 10
  2758, // 11
  2625, // 12
  2499, // 13
  2379, // 14
  2264, // 15
  2156, // 16
  2052, // 17
  1954, // 18
  1860, // 19
  1771, // 20
  1686, // 21
  1606, // 22
  1529, // 23
  1456, // 24
  1387, // 25
  1321, // 26
  1258, // 27
  1199, // 28
  1142, // 29
  1088, // 30
  1037, // 31
  988, // 32
  941, // 33
  897, // 34
  855, // 35
  815, // 36
  777, // 37
  741, // 38
  706, // 39
  674, // 40
  643, // 41
  613, // 42
  585, // 43
  558, // 44
  532, // 45
  508, // 46
  485, // 47
  463, // 48
  442, // 49
  422, // 50
  403, // 51
  386, // 52
  368, // 53
  352, // 54
  337, // 55
  322, // 56
  308, // 57
  295, // 58
  282, // 59
  270, // 60
  259, // 61
  248, // 62
  237, // 63
  227, // 64
  218, // 65
  209, // 66
  201, // 67
  193, // 68
  185, // 69
  178, // 70
  171, // 71
  164, // 72
  158, // 73
  152, // 74
  146, // 75
  141, // 76
  135, // 77
  131, // 78
  126, // 79
  121, // 80
  117, // 81
  113, // 82
  109, // 83
  106, // 84
  102, // 85
  99, // 86
  96, // 87
  93, // 88
  90, // 89
  87, // 90
  85, // 91
  82, // 92
  80, // 93
  78, // 94
  76, // 95
  74, // 96
  72, // 97
  70, // 98
  68, // 99
  67, // 100
  65, // 101
  64, // 102
  62, // 103
  61, // 104
  60, // 105
  59, // 106
  57, // 107
  56, // 108
  55, // 109
  54, // 110
  53, // 111
  52, // 112
  52, // 113
  51, // 114
  50, // 115
  49, // 116
  49, // 117
  48, // 118
  47, // 119
  47, // 120
  46, // 121
  46, // 122
  45, // 123
  45, // 124
  44, // 125
  44, // 126
  43); // 127

  c_AntiLogTable : Table[0..127] of byte = (
    0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18, 19, 21, 22, 24, 25, 27, 28,
    29, 31, 32, 33, 35, 36, 37, 39, 40, 41, 43, 44, 45, 47, 48, 49, 50, 52, 53,
    54, 55, 57, 58, 59, 60, 62, 63, 64, 65, 66, 68, 69, 70, 71, 72, 73, 74, 76,
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 102, 103, 104, 105, 106, 107, 108, 108, 109,
    110, 111, 111, 112, 113, 114, 114, 115, 116, 116, 117, 118, 118, 119, 120,
    120, 121, 121, 122, 122, 123, 123, 124, 124, 125, 125, 125, 126, 126, 127,
    127, 127, 127, 127
    );


// #############################################################################

  c_TuningArrayHammond: Array[0..11] of word = (
    // Hammond Generator, aus GeneratorNoten96.xls
    1428, 1513, 1604, 1699, 1800, 1907, 2021, 2141, 2267, 2403, 2545, 2696
    );

  c_TuningArrayHammondSpread: Array[0..11] of word = (
    // Hammond Generator letzte Oktave 192er Wheels, aus GeneratorNoten96.xls
    1430, 1516, 1606, 1701, 1802, 1909, 2022, 2142, 2270, 2404, 2547, 2699
    );

  c_TuningArrayEven: Array[0..11] of word = (
    // Exakt gleichschwebend (Even), aus GeneratorNoten96.xls
    1429, 1514, 1604, 1699, 1800, 1907, 2021, 2141, 2268, 2403, 2546, 2697
    );

  c_HighpassFilterArray: Array[0..95] of word = (
    // aus Digital_HP_LP.xls
    100, 100, 100, 100, 130, 150, 200, 210, 220, 240, 253, 253, 279, 295, 313, 331,
    351, 372, 394, 417, 442, 468, 496, 525, 556, 589, 624, 661, 700, 741, 785, 831,
    880, 932, 987, 1046, 1107, 1173, 1242, 1315, 1392, 1474, 1561, 1652, 1749, 1852,
    1960, 2075, 3288, 3478, 3679, 3891, 4115, 4352, 4601, 4864, 5142, 5434, 5743,
    6068, 6411, 6772, 7152, 7551, 7972, 8414, 8879, 9367, 9880, 10418, 10983, 11575,
    12195, 12844, 13523, 14232, 14871, 14871, 14871, 14871, 14871, 14871, 14871,
    14871, 14871, 14871, 18028, 18028, 18028, 18028, 18028, 18028, 20988, 20988,
    20988, 20988
    );

  // Faktoren für Drawbar-Mix bei 4 Drawbars, Initialwerte
  c_Pedal4DBfacs8: Array [0..11] of byte =
    // 0  1   2   3   4   5   6   7  8  9  10 11   // Drawbar
    (  0, 0, 127, 50, 35, 20, 10, 0, 0, 0, 0, 0
    );
  c_Pedal4DBfacs8H: Array [0..11] of byte =
    // 0  1   2   3   4   5   6   7   8   9  10 11   // Drawbar
    (  0, 0, 127, 70, 65, 40, 30, 25, 10, 0, 0, 0
    );
  c_Pedal4DBfacs16: Array [0..11] of byte =
    //  0   1   2   3   4   5  6  7  8  9  10  11   // Drawbar
    (  124, 80, 50, 30, 15, 8, 3, 0, 0, 0,  0,  0
    );
  c_Pedal4DBfacs16H: Array [0..11] of byte =
    //  0   1   2   3   4   5   6   7  8  9  10  11   // Drawbar
    (  124, 80, 70, 40, 25, 15, 10, 8, 0, 0,  0,  0
    );

  c_MIDIreceiveReg: Byte = 2;  // MIDI-Daten vom FPGA FIFO


// Tabelle IncDec-Button-Offset (div 2) auf Parameter
  c_incdec2edit_idx: Array[0..7] of Word = (
    // alle IncDec-Buttons #1192..#1207 (Index div 2)
    // Presets, 3x Voices, 2x Models, Transpose, RFU
    268, 269, 270, 271, 265, 266, 395, 0
    );
  c_incdec_lastbtn: byte = 13;   // Anzahl der Inc/Dec-Buttons #1192..#1207 -1

// Reihenfolge von NRPN $3570+x und in Tabelle:
// upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
// Reihenfolge MIDI/OSC-Befehle:
// Dec/Inc upper_0   0,0 (Index auf GM_VoiceNames)
// Dec/Inc upper_1   4,4
// Dec/Inc lower_0   1,1
// Dec/Inc lower_1   5,5
// Dec/Inc pedal_0   2,2
// Dec/Inc pedal_1   6,6

// Index in MIDI/OSC-Reihenfolge auf GM_VoiceNames (NRPN-Reihenfolge)
// idx = Inc_dec div 2
//  c_midi_osc_order_to_gmidx: Array[0..5] of byte = (0, 4, 1, 5, 2, 6);

// Index in MIDI/OSC-Reihenfolge auf Einträge in edit_GMprogs:
// idx = Inc_dec div 2
  c_midi_osc_order_to_edit_gmvoice: Array[0..5] of byte =
      (0, 3, 8, 11, 16, 19);

// Index in NRPN-Reihenfolge auf Einträge in edit_GMprogs div 2:
// idx = upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
  c_gmidx_order_to_edit_gmvoice: Array[0..7] of byte =
      (0, 8, 16, 0, 3, 11, 19, 0);

//  c_gmidx_to_menu: Array[0..7] of byte =
//      (57, 82, 98, 0, 60, 85, 101, 0);

// Reduziert Percussion-Pegel bei H100 und Modul,
// wenn mehrere Perc-Fußlagen aktiviert sind
  c_perc_mute: Array [0..15] of byte =
    //  0    1    2   3   4   5   6   7   8   9  10  11  12  13  14  15 // BBs
    (  100, 100, 80, 68, 60, 55, 50, 47, 45, 42, 40, 38, 36, 35, 33, 33
    );
// Relative Percussion-Level (Prozent) nach Fußlage zur Mittelwertbildung
  c_perc_bbfacs: Array [0..15] of byte =
    //  0    1    2   2nd  3rd  5   6   7   8   9  10  11  12  13  14  15 // BB#
    (  100, 100, 100, 100, 95, 85, 75, 65, 60, 55, 50, 50, 50, 50, 50, 50
    );

// #############################################################################
// ###   Tabellen aus "Controllerliste HX35_custom_xxx.xls" übernommen       ###
// #############################################################################

// ab hier in Pascal-Konstanten kopieren
  c_MenuGroups: Byte = 12;

  c_MenuStartArr: array[0..  c_MenuGroups] of Byte = (
    0, //  #0 Main Menu
    22, //  #1 SubMenu EditName
    29, //  #2 Upper Menu
    52, //  #3 Lower Menu
    72, //  #4 Pedal Menu
    84, //  #5 Reverb Menu
    87, //  #6 PHR Mode Menu
    88, //  #7 Audio Menu
    108, //  #8 Percussion Menu
    112, //  #9 Rotary Menu
    125, //  #10 MIDI/Split Menu
    137, //  #11 Vib/Chorus Menu
    143  //  #12 Organ Setup Menu
  );

  c_MenuEndArr: array[0..  c_MenuGroups] of Byte = (
    21, //  #0 Ende Main Menu
    28, //  #1 Ende SubMenu EditName
    51, //  #2 Ende Upper Menu
    71, //  #3 Ende Lower Menu
    83, //  #4 Ende Pedal Menu
    86, //  #5 Ende Reverb Menu
    87, //  #6 Ende PHR Mode Menu
    107, //  #7 Ende Audio Menu
    111, //  #8 Ende Percussion Menu
    124, //  #9 Ende Rotary Menu
    136, //  #10 Ende MIDI/Split Menu
    142, //  #11 Ende Vib/Chorus Menu
    151  //  #12 Ende Organ Setup Menu
  );

  // Spezielle Menüs
  c_MenuLen: byte = 151;
  // Startmenu
  c_MenuCommonPreset: Byte = 0;
  c_MainMenuStart: Byte = 0;
  c_MainMenuEnd: Byte = 21;
  c_VibKnobMenu: Byte = 13;
  // für Freigabe mit Scanboard
  c_KeybEarlySubmenu: Byte = 150;
  c_EquMenuStart: Byte = 89;
  c_EquMenuEnd: Byte = 97;
  c_TransposeMenu: Byte = 21;
  c_EnvEnaUpperMenu: Byte = 44;
  c_ReverbMenu: Byte = 7;
  c_PercMenu: Byte = 12;
  c_VibUprMenu: Byte = 13;
  c_VibLwrMenu: Byte = 14;
  c_ViKnobMenu: Byte = 15;
  c_RotaryRunMenu: Byte = 8;
  c_RotaryFastMenu: Byte = 9;

  c_MenuGotoArr: array[0..  c_MainMenuEnd] of byte = (
    22, // #0 HX3 Preset
    29, // #1 Voice Upper
    52, // #2 Voice Lower
    72, // #3 Voice Pedal
    88, // #4 Master Volume
    88, // #5 TubeAmp Gain
    88, // #6 TubeAmpBypass
    84, // #7 Reverb Prgm
    112, // #8 Rotary Motor
    112, // #9 Rotary Fast
    112, // #10 Rotary Bypass
    112, // #11 Rotary Model
    108, // #12 Percussion
    137, // #13 UPR LWR Vibr
    137, // #14 UPR LWR Vibr
    137, // #15 UPR LWR Vibr
    87, // #16 Phasing Fast
    87, // #17 Phasing Upper
    87, // #18 Phasing Lower
    143, // #19 Organ Model
    143, // #20 TG Tuning
    125  // #21 MIDI Transpos
  );

// #############################################################################

  c_MenuTypeArr: array[0..  c_MenuLen] of t_menuType = (
  tm_preset_common, // #1268 HX3 Preset
  tm_preset_upper, // #1269 Voice Upper
  tm_preset_lower, // #1270 Voice Lower
  tm_preset_pedal, // #1271 Voice Pedal
  tm_drawbar, // #1080 Master Volume
  tm_drawbar, // #1081 TubeAmp Gain
  tm_boolean, // #1136 TubeAmpBypass
  tm_reverb, // #1263 Reverb Prgm
  tm_boolean, // #1134 Rotary Motor
  tm_boolean, // #1135 Rotary Fast
  tm_boolean, // #1137 Rotary Bypass
  tm_items_SpeakerModel, // #1266 Rotary Model
  tm_perc, // #1262 Percussion
  tm_vib_on_upr, // #1132 UPR LWR Vibr
  tm_vib_on_lwr, // #1133 UPR LWR Vibr
  tm_vibknob, // #1264 UPR LWR Vibr
  tm_boolean, // #1150 Phasing Fast
  tm_boolean, // #1138 Phasing Upper
  tm_boolean, // #1139 Phasing Lower
  tm_items_organmodel, // #1265 Organ Model
  tm_tuning, // #1391 TG Tuning
  tm_transpose, // #1395 MIDI Transpos
  tm_editname, // #1192 Edit Name
  tm_numeric, // #1495 LED Dimmer
  tm_savedefault, // #1247 Save Defaults
  tm_setupfile, // #1509 SD File Exec
  tm_bootloader, // #1697 Bootld Update
  tm_initwifi, // #1698 WiFi Init Def
  tm_initpreset, // #1699 Preset Init
  tm_drawbar, // #1000 UpperDB 16
  tm_drawbar, // #1001 UpperDB 5 1/3
  tm_drawbar, // #1002 UpperDB 8
  tm_drawbar, // #1003 UpperDB 4
  tm_drawbar, // #1004 UpperDB 2 2/3
  tm_drawbar, // #1005 UpperDB 2
  tm_drawbar, // #1006 UpperDB 1 3/5
  tm_drawbar, // #1007 UpperDB 1 1/3
  tm_drawbar, // #1008 UpperDB 1
  tm_drawbar, // #1009 UpperDB Mix 1
  tm_drawbar, // #1010 UpperDB Mix 2
  tm_drawbar, // #1011 UpperDB Mix 3
  tm_boolean, // #1157 H100 HarpSust
  tm_boolean, // #1156 H100 2ndVoice
  tm_boolean, // #1158 EG DB To Dry
  tm_adsrena_upr, // #1160 H100 Perc
  tm_gm_prg0, // #1224 UpperGM Prg 1
  tm_drawbar, // #1225 UpperGM Lvl 1
  tm_numeric, // #1226 UpperGM Hrm 1
  tm_gm_prg4, // #1227 UpperGM Prg 2
  tm_drawbar, // #1228 UpperGM Lvl 2
  tm_numeric, // #1229 UpperGM Harm2
  tm_tuning, // #1230 UpperGM Detn2
  tm_drawbar, // #1016 LowerDB 16
  tm_drawbar, // #1017 LowerDB 5 1/3
  tm_drawbar, // #1018 LowerDB 8
  tm_drawbar, // #1019 LowerDB 4
  tm_drawbar, // #1020 LowerDB 2 2/3
  tm_drawbar, // #1021 LowerDB 2
  tm_drawbar, // #1022 LowerDB 1 3/5
  tm_drawbar, // #1023 LowerDB 1 1/3
  tm_drawbar, // #1024 LowerDB 1
  tm_drawbar, // #1025 LowerDB Mix 1
  tm_drawbar, // #1026 LowerDB Mix 2
  tm_drawbar, // #1027 LowerDB Mix 3
  tm_adsrena_lwr, // #1176 ADSR Ena Lwr
  tm_gm_prg1, // #1232 LowerGM Prg 1
  tm_drawbar, // #1233 LowerGM Lvl 1
  tm_numeric, // #1234 LowerGM Harm1
  tm_gm_prg5, // #1235 LowerGM Prg 2
  tm_drawbar, // #1236 LowerGM Lvl 2
  tm_numeric, // #1237 LowerGM Harm2
  tm_tuning, // #1238 LowerGM Detn2
  tm_drawbar, // #1072 PedalDB 16
  tm_drawbar, // #1073 PedalDB 16H
  tm_drawbar, // #1074 PedalDB 8
  tm_drawbar, // #1075 PedalDB 8H
  tm_drawbar, // #1067 Pedal Release
  tm_gm_prg2, // #1240 PedalGM Prg 1
  tm_drawbar, // #1241 PedalGM Lvl 1
  tm_numeric, // #1242 PedalGM Harm1
  tm_gm_prg6, // #1243 PedalGM Prg 2
  tm_drawbar, // #1244 PedalGM Lvl 2
  tm_numeric, // #1245 PedalGM Harm2
  tm_tuning, // #1246 PedalGM Detn2
  tm_drawbar, // #1400 Reverb 1 Lvl
  tm_drawbar, // #1401 Reverb 2 Lvl
  tm_drawbar, // #1402 Reverb 3 Lvl
  tm_items_phrmode, // #1144 PHR <Mode>
  tm_boolean, // #1159 Equ Bypass
  tm_drawbar, // #1112 Bass Equal
  tm_bassfreq, // #1113 Bass Equ Frq
  tm_drawbar, // #1114 Bass Equ Q
  tm_drawbar, // #1115 Mid Equal
  tm_midfreq, // #1116 Mid Equ Frq
  tm_drawbar, // #1117 Mid Equ Q
  tm_drawbar, // #1118 Treble Equal
  tm_treblefreq, // #1119 Treb Equ Frq
  tm_drawbar, // #1120 Treb Equ Q
  tm_boolean, // #1121 Parametr B/T
  tm_drawbar, // #1082 Upper Lvl Adj
  tm_drawbar, // #1083 Lower Lvl Adj
  tm_drawbar, // #1084 Pedal Lvl Adj
  tm_drawbar, // #1085 Perc Lvl Adj
  tm_boolean, // #1142 PedalRotBypas
  tm_drawbar, // #1087 AO28 Tone Pot
  tm_drawbar, // #1088 AO28 Gain Cap
  tm_drawbar, // #1089 AO28 MinSwell
  tm_numeric, // #1090 AO28 Tube Age
  tm_numeric, // #1480 PercNormLvl
  tm_numeric, // #1481 PercSoftLvl
  tm_numeric, // #1482 PercLongTm
  tm_numeric, // #1483 PercShortTm
  tm_numeric, // #1448 HornSlowSpeed
  tm_numeric, // #1449 RotrSlowSpeed
  tm_numeric, // #1450 HornFastSpeed
  tm_numeric, // #1451 RotrFastSpeed
  tm_numeric, // #1452 HornRampUp
  tm_numeric, // #1453 RotorRampUp
  tm_numeric, // #1454 HornRampDown
  tm_numeric, // #1455 RotorRampDown
  tm_numeric, // #1456 Rotary Throb
  tm_numeric, // #1457 Rotary Spread
  tm_numeric, // #1458 Rotary Balnce
  tm_numeric, // #1460 Tube Select A
  tm_numeric, // #1461 Tube Select B
  tm_midichannel, // #1368 MIDI Channel
  tm_items_midiopt, // #1369 MIDI Option
  tm_items_ccset, // #1370 MIDI CC Set
  tm_numeric, // #1371 MIDI Swell CC
  tm_numeric, // #1372 MIDI VolumeCC
  tm_numeric, // #1374 MIDI PresetCC
  tm_transpose, // #1355 TransposeOffs
  tm_items_localena, // #1373 Local On/Off
  tm_boolean, // #1143 Split Keyb
  tm_numeric, // #1353 Split Point
  tm_items_splitm, // #1354 Split Mode
  tm_boolean, // #1376 MIDI Disable Program Change
  tm_numeric, // #1326 Scanner Gear
  tm_numeric, // #1328 Ch ScannerLvl
  tm_numeric, // #1327 Ch Bypass Lvl
  tm_numeric, // #1329 V1/C1 FM Mod
  tm_numeric, // #1330 V2/C2 FM Mod
  tm_numeric, // #1331 V3/C3 FM Mod
  tm_items_gatingmode, // #1261 Gating Mode
  tm_items_waveset, // #1388 TG WaveSet
  tm_items_capset, // #1392 TG Tapering
  tm_numeric, // #1389 TG Flutter
  tm_numeric, // #1390 TG Leakage
  tm_numeric, // #1360 ContSpringFlx
  tm_numeric, // #1361 ContSpringDmp
  tm_boolean, // #1356 ContEarlyActn
  tm_boolean  // #1357 No DB1 @Perc
);

  c_Index2ParamArr: array[0..  c_MenuLen] of Integer = (
  1268, // #1268 HX3 Preset
  1269, // #1269 Voice Upper
  1270, // #1270 Voice Lower
  1271, // #1271 Voice Pedal
  1080, // #1080 Master Volume
  1081, // #1081 TubeAmp Gain
  1136, // #1136 TubeAmpBypass
  1263, // #1263 Reverb Prgm
  1134, // #1134 Rotary Motor
  1135, // #1135 Rotary Fast
  1137, // #1137 Rotary Bypass
  1266, // #1266 Rotary Model
  1262, // #1262 Percussion
  1132, // #1132 UPR LWR Vibr
  1133, // #1133 UPR LWR Vibr
  1264, // #1264 UPR LWR Vibr
  1150, // #1150 Phasing Fast
  1138, // #1138 Phasing Upper
  1139, // #1139 Phasing Lower
  1265, // #1265 Organ Model
  1391, // #1391 TG Tuning
  1395, // #1395 MIDI Transpos
  1192, // #1192 Edit Name
  1495, // #1495 LED Dimmer
  1247, // #1247 Save Defaults
  1509, // #1509 SD File Exec
  1697, // #1697 Bootld Update
  1698, // #1698 WiFi Init Def
  1699, // #1699 Preset Init
  1000, // #1000 UpperDB 16
  1001, // #1001 UpperDB 5 1/3
  1002, // #1002 UpperDB 8
  1003, // #1003 UpperDB 4
  1004, // #1004 UpperDB 2 2/3
  1005, // #1005 UpperDB 2
  1006, // #1006 UpperDB 1 3/5
  1007, // #1007 UpperDB 1 1/3
  1008, // #1008 UpperDB 1
  1009, // #1009 UpperDB Mix 1
  1010, // #1010 UpperDB Mix 2
  1011, // #1011 UpperDB Mix 3
  1157, // #1157 H100 HarpSust
  1156, // #1156 H100 2ndVoice
  1158, // #1158 EG DB To Dry
  1160, // #1160 H100 Perc
  1224, // #1224 UpperGM Prg 1
  1225, // #1225 UpperGM Lvl 1
  1226, // #1226 UpperGM Hrm 1
  1227, // #1227 UpperGM Prg 2
  1228, // #1228 UpperGM Lvl 2
  1229, // #1229 UpperGM Harm2
  1230, // #1230 UpperGM Detn2
  1016, // #1016 LowerDB 16
  1017, // #1017 LowerDB 5 1/3
  1018, // #1018 LowerDB 8
  1019, // #1019 LowerDB 4
  1020, // #1020 LowerDB 2 2/3
  1021, // #1021 LowerDB 2
  1022, // #1022 LowerDB 1 3/5
  1023, // #1023 LowerDB 1 1/3
  1024, // #1024 LowerDB 1
  1025, // #1025 LowerDB Mix 1
  1026, // #1026 LowerDB Mix 2
  1027, // #1027 LowerDB Mix 3
  1176, // #1176 ADSR Ena Lwr
  1232, // #1232 LowerGM Prg 1
  1233, // #1233 LowerGM Lvl 1
  1234, // #1234 LowerGM Harm1
  1235, // #1235 LowerGM Prg 2
  1236, // #1236 LowerGM Lvl 2
  1237, // #1237 LowerGM Harm2
  1238, // #1238 LowerGM Detn2
  1072, // #1072 PedalDB 16
  1073, // #1073 PedalDB 16H
  1074, // #1074 PedalDB 8
  1075, // #1075 PedalDB 8H
  1067, // #1067 Pedal Release
  1240, // #1240 PedalGM Prg 1
  1241, // #1241 PedalGM Lvl 1
  1242, // #1242 PedalGM Harm1
  1243, // #1243 PedalGM Prg 2
  1244, // #1244 PedalGM Lvl 2
  1245, // #1245 PedalGM Harm2
  1246, // #1246 PedalGM Detn2
  1400, // #1400 Reverb 1 Lvl
  1401, // #1401 Reverb 2 Lvl
  1402, // #1402 Reverb 3 Lvl
  1144, // #1144 PHR <Mode>
  1159, // #1159 Equ Bypass
  1112, // #1112 Bass Equal
  1113, // #1113 Bass Equ Frq
  1114, // #1114 Bass Equ Q
  1115, // #1115 Mid Equal
  1116, // #1116 Mid Equ Frq
  1117, // #1117 Mid Equ Q
  1118, // #1118 Treble Equal
  1119, // #1119 Treb Equ Frq
  1120, // #1120 Treb Equ Q
  1121, // #1121 Parametr B/T
  1082, // #1082 Upper Lvl Adj
  1083, // #1083 Lower Lvl Adj
  1084, // #1084 Pedal Lvl Adj
  1085, // #1085 Perc Lvl Adj
  1142, // #1142 PedalRotBypas
  1087, // #1087 AO28 Tone Pot
  1088, // #1088 AO28 Gain Cap
  1089, // #1089 AO28 MinSwell
  1090, // #1090 AO28 Tube Age
  1480, // #1480 PercNormLvl
  1481, // #1481 PercSoftLvl
  1482, // #1482 PercLongTm
  1483, // #1483 PercShortTm
  1448, // #1448 HornSlowSpeed
  1449, // #1449 RotrSlowSpeed
  1450, // #1450 HornFastSpeed
  1451, // #1451 RotrFastSpeed
  1452, // #1452 HornRampUp
  1453, // #1453 RotorRampUp
  1454, // #1454 HornRampDown
  1455, // #1455 RotorRampDown
  1456, // #1456 Rotary Throb
  1457, // #1457 Rotary Spread
  1458, // #1458 Rotary Balnce
  1460, // #1460 Tube Select A
  1461, // #1461 Tube Select B
  1368, // #1368 MIDI Channel
  1369, // #1369 MIDI Option
  1370, // #1370 MIDI CC Set
  1371, // #1371 MIDI Swell CC
  1372, // #1372 MIDI VolumeCC
  1374, // #1374 MIDI PresetCC
  1355, // #1355 TransposeOffs
  1373, // #1373 Local On/Off
  1143, // #1143 Split Keyb
  1353, // #1353 Split Point
  1354, // #1354 Split Mode
  1376, // #1376 MIDI Disable Program Change
  1326, // #1326 Scanner Gear
  1328, // #1328 Ch ScannerLvl
  1327, // #1327 Ch Bypass Lvl
  1329, // #1329 V1/C1 FM Mod
  1330, // #1330 V2/C2 FM Mod
  1331, // #1331 V3/C3 FM Mod
  1261, // #1261 Gating Mode
  1388, // #1388 TG WaveSet
  1392, // #1392 TG Tapering
  1389, // #1389 TG Flutter
  1390, // #1390 TG Leakage
  1360, // #1360 ContSpringFlx
  1361, // #1361 ContSpringDmp
  1356, // #1356 ContEarlyActn
  1357  // #1357 No DB1 @Perc
);

s_MenuHeaderArr: array[0..  c_MenuLen] of String[13] = (
  'HX3 Preset   ',  // #1268
  'Voice Upper  ',  // #1269
  'Voice Lower  ',  // #1270
  'Voice Pedal  ',  // #1271
  'Master Volume',  // #1080
  'TubeAmp Gain ',  // #1081
  'TubeAmpBypass',  // #1136
  'Reverb Prgm  ',  // #1263
  'Rotary Motor ',  // #1134
  'Rotary Fast  ',  // #1135
  'Rotary Bypass',  // #1137
  'Rotary Model ',  // #1266
  'Percussion   ',  // #1262
  'UPR LWR Vibr ',  // #1132
  'UPR LWR Vibr ',  // #1133
  'UPR LWR Vibr ',  // #1264
  'Phasing Fast ',  // #1150
  'Phasing Upper',  // #1138
  'Phasing Lower',  // #1139
  'Organ Model  ',  // #1265
  'TG Tuning    ',  // #1391
  'MIDI Transpos',  // #1395
  'Edit Name    ',  // #1192
  'LED Dimmer   ',  // #1495
  'Save Defaults',  // #1247
  'SD File Exec ',  // #1509
  'Bootld Update',  // #1697
  'WiFi Init Def',  // #1698
  'Preset Init  ',  // #1699
  'UpperDB 16   ',  // #1000
  'UpperDB 5 1/3',  // #1001
  'UpperDB 8    ',  // #1002
  'UpperDB 4    ',  // #1003
  'UpperDB 2 2/3',  // #1004
  'UpperDB 2    ',  // #1005
  'UpperDB 1 3/5',  // #1006
  'UpperDB 1 1/3',  // #1007
  'UpperDB 1    ',  // #1008
  'UpperDB Mix 1',  // #1009
  'UpperDB Mix 2',  // #1010
  'UpperDB Mix 3',  // #1011
  'H100 HarpSust',  // #1157
  'H100 2ndVoice',  // #1156
  'EG DB To Dry ',  // #1158
  'H100 Perc    ',  // #1160
  'UpperGM Prg 1',  // #1224
  'UpperGM Lvl 1',  // #1225
  'UpperGM Hrm 1',  // #1226
  'UpperGM Prg 2',  // #1227
  'UpperGM Lvl 2',  // #1228
  'UpperGM Harm2',  // #1229
  'UpperGM Detn2',  // #1230
  'LowerDB 16   ',  // #1016
  'LowerDB 5 1/3',  // #1017
  'LowerDB 8    ',  // #1018
  'LowerDB 4    ',  // #1019
  'LowerDB 2 2/3',  // #1020
  'LowerDB 2    ',  // #1021
  'LowerDB 1 3/5',  // #1022
  'LowerDB 1 1/3',  // #1023
  'LowerDB 1    ',  // #1024
  'LowerDB Mix 1',  // #1025
  'LowerDB Mix 2',  // #1026
  'LowerDB Mix 3',  // #1027
  'ADSR Ena Lwr ',  // #1176
  'LowerGM Prg 1',  // #1232
  'LowerGM Lvl 1',  // #1233
  'LowerGM Harm1',  // #1234
  'LowerGM Prg 2',  // #1235
  'LowerGM Lvl 2',  // #1236
  'LowerGM Harm2',  // #1237
  'LowerGM Detn2',  // #1238
  'PedalDB 16   ',  // #1072
  'PedalDB 16H  ',  // #1073
  'PedalDB 8    ',  // #1074
  'PedalDB 8H   ',  // #1075
  'Pedal Release',  // #1067
  'PedalGM Prg 1',  // #1240
  'PedalGM Lvl 1',  // #1241
  'PedalGM Harm1',  // #1242
  'PedalGM Prg 2',  // #1243
  'PedalGM Lvl 2',  // #1244
  'PedalGM Harm2',  // #1245
  'PedalGM Detn2',  // #1246
  'Reverb 1 Lvl ',  // #1400
  'Reverb 2 Lvl ',  // #1401
  'Reverb 3 Lvl ',  // #1402
  'PHR <Mode>   ',  // #1144
  'Equ Bypass   ',  // #1159
  'Bass Equal   ',  // #1112
  'Bass Equ Frq ',  // #1113
  'Bass Equ Q   ',  // #1114
  'Mid Equal    ',  // #1115
  'Mid Equ Frq  ',  // #1116
  'Mid Equ Q    ',  // #1117
  'Treble Equal ',  // #1118
  'Treb Equ Frq ',  // #1119
  'Treb Equ Q   ',  // #1120
  'Parametr B/T ',  // #1121
  'Upper Lvl Adj',  // #1082
  'Lower Lvl Adj',  // #1083
  'Pedal Lvl Adj',  // #1084
  'Perc Lvl Adj ',  // #1085
  'PedalRotBypas',  // #1142
  'AO28 Tone Pot',  // #1087
  'AO28 Gain Cap',  // #1088
  'AO28 MinSwell',  // #1089
  'AO28 Tube Age',  // #1090
  'PercNormLvl  ',  // #1480
  'PercSoftLvl  ',  // #1481
  'PercLongTm   ',  // #1482
  'PercShortTm  ',  // #1483
  'HornSlowSpeed',  // #1448
  'RotrSlowSpeed',  // #1449
  'HornFastSpeed',  // #1450
  'RotrFastSpeed',  // #1451
  'HornRampUp   ',  // #1452
  'RotorRampUp  ',  // #1453
  'HornRampDown ',  // #1454
  'RotorRampDown',  // #1455
  'Rotary Throb ',  // #1456
  'Rotary Spread',  // #1457
  'Rotary Balnce',  // #1458
  'Tube Select A',  // #1460
  'Tube Select B',  // #1461
  'MIDI Channel ',  // #1368
  'MIDI Option  ',  // #1369
  'MIDI CC Set  ',  // #1370
  'MIDI Swell CC',  // #1371
  'MIDI VolumeCC',  // #1372
  'MIDI PresetCC',  // #1374
  'TransposeOffs',  // #1355
  'Local On/Off ',  // #1373
  'Split Keyb   ',  // #1143
  'Split Point  ',  // #1353
  'Split Mode   ',  // #1354
  'No ProgChgRcv',  // #1376
  'Scanner Gear ',  // #1326
  'Ch ScannerLvl',  // #1328
  'Ch Bypass Lvl',  // #1327
  'V1/C1 FM Mod ',  // #1329
  'V2/C2 FM Mod ',  // #1330
  'V3/C3 FM Mod ',  // #1331
  'Gating Mode  ',  // #1261
  'TG WaveSet   ',  // #1388
  'TG Tapering  ',  // #1392
  'TG Flutter   ',  // #1389
  'TG Leakage   ',  // #1390
  'ContSpringFlx',  // #1360
  'ContSpringDmp',  // #1361
  'ContEarlyActn',  // #1356
  'No DB1 @Perc '   // #1357
);

// Bit 0 = B3, Bit 1 = H100, Bit 2 = Versatile,
// Bit 3 = Expander, Bit 4 = mk4, Bit 5 = mk5,
// Bit 6 = Extended Licence, Bit 7 = Parametric EQU
c_MenuMaskArr: array[0..  c_MenuLen] of Byte = (
  199, // #1268 HX3 Preset
  199, // #1269 Voice Upper
  199, // #1270 Voice Lower
  199, // #1271 Voice Pedal
  199, // #1080 Master Volume
  199, // #1081 TubeAmp Gain
  199, // #1136 TubeAmpBypass
  199, // #1263 Reverb Prgm
  199, // #1134 Rotary Motor
  199, // #1135 Rotary Fast
  199, // #1137 Rotary Bypass
  199, // #1266 Rotary Model
  199, // #1262 Percussion
  199, // #1132 UPR LWR Vibr
  199, // #1133 UPR LWR Vibr
  199, // #1264 UPR LWR Vibr
  134, // #1150 Phasing Fast
  134, // #1138 Phasing Upper
  134, // #1139 Phasing Lower
  199, // #1265 Organ Model
  199, // #1391 TG Tuning
  199, // #1395 MIDI Transpos
  199, // #1192 Edit Name
  199, // #1495 LED Dimmer
  199, // #1247 Save Defaults
  199, // #1509 SD File Exec
  199, // #1697 Bootld Update
  199, // #1698 WiFi Init Def
  199, // #1699 Preset Init
  199, // #1000 UpperDB 16
  199, // #1001 UpperDB 5 1/3
  199, // #1002 UpperDB 8
  199, // #1003 UpperDB 4
  199, // #1004 UpperDB 2 2/3
  199, // #1005 UpperDB 2
  199, // #1006 UpperDB 1 3/5
  199, // #1007 UpperDB 1 1/3
  199, // #1008 UpperDB 1
  134, // #1009 UpperDB Mix 1
  134, // #1010 UpperDB Mix 2
  134, // #1011 UpperDB Mix 3
  130, // #1157 H100 HarpSust
  130, // #1156 H100 2ndVoice
  132, // #1158 EG DB To Dry
  134, // #1160 H100 Perc
  199, // #1224 UpperGM Prg 1
  199, // #1225 UpperGM Lvl 1
  199, // #1226 UpperGM Hrm 1
  135, // #1227 UpperGM Prg 2
  135, // #1228 UpperGM Lvl 2
  135, // #1229 UpperGM Harm2
  135, // #1230 UpperGM Detn2
  199, // #1016 LowerDB 16
  199, // #1017 LowerDB 5 1/3
  199, // #1018 LowerDB 8
  199, // #1019 LowerDB 4
  199, // #1020 LowerDB 2 2/3
  199, // #1021 LowerDB 2
  199, // #1022 LowerDB 1 3/5
  199, // #1023 LowerDB 1 1/3
  199, // #1024 LowerDB 1
  134, // #1025 LowerDB Mix 1
  134, // #1026 LowerDB Mix 2
  134, // #1027 LowerDB Mix 3
  132, // #1176 ADSR Ena Lwr
  199, // #1232 LowerGM Prg 1
  199, // #1233 LowerGM Lvl 1
  199, // #1234 LowerGM Harm1
  135, // #1235 LowerGM Prg 2
  135, // #1236 LowerGM Lvl 2
  135, // #1237 LowerGM Harm2
  135, // #1238 LowerGM Detn2
  199, // #1072 PedalDB 16
  199, // #1073 PedalDB 16H
  199, // #1074 PedalDB 8
  199, // #1075 PedalDB 8H
  199, // #1067 Pedal Release
  199, // #1240 PedalGM Prg 1
  199, // #1241 PedalGM Lvl 1
  199, // #1242 PedalGM Harm1
  135, // #1243 PedalGM Prg 2
  135, // #1244 PedalGM Lvl 2
  135, // #1245 PedalGM Harm2
  135, // #1246 PedalGM Detn2
  199, // #1400 Reverb 1 Lvl
  199, // #1401 Reverb 2 Lvl
  199, // #1402 Reverb 3 Lvl
  134, // #1144 PHR <Mode>
  199, // #1159 Equ Bypass
  199, // #1112 Bass Equal
  71, // #1113 Bass Equ Frq
  71, // #1114 Bass Equ Q
  199, // #1115 Mid Equal
  199, // #1116 Mid Equ Frq
  199, // #1117 Mid Equ Q
  199, // #1118 Treble Equal
  71, // #1119 Treb Equ Frq
  71, // #1120 Treb Equ Q
  71, // #1121 Parametr B/T
  199, // #1082 Upper Lvl Adj
  199, // #1083 Lower Lvl Adj
  199, // #1084 Pedal Lvl Adj
  199, // #1085 Perc Lvl Adj
  199, // #1142 PedalRotBypas
  199, // #1087 AO28 Tone Pot
  199, // #1088 AO28 Gain Cap
  199, // #1089 AO28 MinSwell
  199, // #1090 AO28 Tube Age
  199, // #1480 PercNormLvl
  199, // #1481 PercSoftLvl
  199, // #1482 PercLongTm
  199, // #1483 PercShortTm
  199, // #1448 HornSlowSpeed
  199, // #1449 RotrSlowSpeed
  199, // #1450 HornFastSpeed
  199, // #1451 RotrFastSpeed
  199, // #1452 HornRampUp
  199, // #1453 RotorRampUp
  199, // #1454 HornRampDown
  199, // #1455 RotorRampDown
  199, // #1456 Rotary Throb
  199, // #1457 Rotary Spread
  199, // #1458 Rotary Balnce
  199, // #1460 Tube Select A
  199, // #1461 Tube Select B
  199, // #1368 MIDI Channel
  199, // #1369 MIDI Option
  199, // #1370 MIDI CC Set
  199, // #1371 MIDI Swell CC
  199, // #1372 MIDI VolumeCC
  199, // #1374 MIDI PresetCC
  199, // #1355 TransposeOffs
  199, // #1373 Local On/Off
  199, // #1143 Split Keyb
  199, // #1353 Split Point
  199, // #1354 Split Mode
  199, // #1376 MIDI Disable Program Change
  199, // #1326 Scanner Gear
  199, // #1328 Ch ScannerLvl
  199, // #1327 Ch Bypass Lvl
  199, // #1329 V1/C1 FM Mod
  199, // #1330 V2/C2 FM Mod
  199, // #1331 V3/C3 FM Mod
  199, // #1261 Gating Mode
  199, // #1388 TG WaveSet
  199, // #1392 TG Tapering
  199, // #1389 TG Flutter
  199, // #1390 TG Leakage
  195, // #1360 ContSpringFlx
  195, // #1361 ContSpringDmp
  199, // #1356 ContEarlyActn
  199  // #1357 No DB1 @Perc
);

// #############################################################################
// ###                       Display untere Zeile                            ###
// #############################################################################

s_MenuSplitmodeArr: array[0..5] of String[11] = (
  'PedalToLwr '	,
  'LowerToUpr '	,
  'PedalToUpr ' ,
  'Lower+1 ToU'	,
  'Lower+2 ToU' ,
  'LwrAddPedal' );

// MIDI_OUT_SEL: 0 = MIDI_TX_1, 1 = MIDI_IN_1, 2 = MIDI_IN_2, 3 = MIDI_FROM_SAM (USB)
s_MenuMidiOptArr: array[0..3] of String[10] = (
  'Local Tx  '	,	// 23 Opt 0
  'Inp 1 Thru'	,	// 24 Opt 1
  'Inp 2 Thru'	,	// 25 Opt 2
  'USB InThru'	);	// 26 Opt 3

{
s_MenuSwellTypeArr: array[0..2] of String[7] = (
  'Hammond'	,	//
  'Audio  '	,	//
  'Linear ' );	//

s_MenuFoldbackArr: array[0..3] of String[11] = (
  'Foldback   '	,	//
  'Full       '	,	//
  'Foldb muted'	,	//
  'Full  muted'	);	//

s_GenVibArr: array[0..7] of String[11] = (
  'B3 Std  91#',  // 0, alle Param aus EEPROM
  'B3 Old  91#',  // 1
  'M3/M100 79#',  // 2
  'H100    96#',  // 3
  'Tr Sin  96#',  // 4
  'Tr Squ  96#',  // 5
  'LC Gen  91#',  // 6
  'Cheesy  84#'); // 7

s_MenuSpreadArr: array[0..3] of String[11] = (
  'B3/M/H100  ',    // Hammond Spread
  'TOS/Div2   ',    // TOS/ Div2
  'SingleNote ',    // SingleNote Conn
  'SingleNtDet' );  // SingleNote Detuned

}

s_OrganModelArr: array[0..15] of String[11] = (
  'B3 Standard',  // 0
  'B3 Old     ',  // 1
  'B3 Recapped',  // 2
  'M100/M3    ',  // 3
  'H100/12 Drb',  // 4
  'Boehm 2000 ',  // 5
  'Boehm CnT/L',  // 6
  'Wersi Space',  // 7
  'Wersi Sacrl',  // 8
  'FarfisCombo',  // 9
  'Vox Conti  ',  // 10
  'Conn/Church',  // 11
  'Custom 1   ',  // 12
  'Custom 2   ',  // 13
  'Custom 3   ',  // 14
  'Custom 4   '   // 15
  );

s_SpeakerModelArr: array[0..15] of String[11] = (
  '122 Std SmR',  // 0
  '122 Std LgR',  // 1
  '122 Old SmR',  // 2
  '122 Old LgR',  // 3
  '147 New SmR',  // 4
  '147 New LgR',  // 5
  '760 Std SmR',  // 6
  '760 Std LgR',  // 7
  'SpaceSound ',  // 8
  'Sharma2001 ',  // 9
  'Vibratone  ',  // 10
  'Dynacord100',  // 11
  'CLS-222    ',  // 12
  'PR40       ',  // 13
  'Custom 1   ',  // 14
  'Custom 2   '   // 15
  );

s_GatingModeArr: array[0..4] of String[11] = (
  'B3/9 DrB   ',  // 0
  'H100/12 Drb',  // 1
  'EnvelopeGen',  // 2
  'EG +PercDrb',  // 3
  'EG +TimeDrb'); // 4

s_PHRbitfieldArr: array[0..7] of String[8] = (
  'We/Boe  ',  // 0, Bitfield Descr
  'Ensemble',  // 1
  'Celeste ',  // 2
  'Fading  ',  // 3
  'Weak    ',  // 4
  'Deep    ',  // 5
  'RotFast ',  // 6
  'Ramp up '); // 7

(*
s_VibBitfieldArr: array[0..7] of String[11] = (
  'PreEmphLoPk',  // 0, Bitfield Descr
  'PreEmphHiPk',  // 1
  'PrePhaseInv',  // 2
  '(not used) ',  // 3
  'ModSlope 1 ',  // 4
  'ModSlope 2 ',  // 5
  'ModSlopeInv',  // 6
  '(not used) '); // 7
*)

s_EGbitfieldArr: array[0..11] of String[6] = (
  'Mix 3 ',
  'Mix 2 ',
  'Mix 1 ',
  '1''    ',
  '1 1/3''',
  '1 3/5''',
  '2''    ',
  '2 2/3''',
  '4''    ',
  '8''    ',
  '5 1/3''',
  '16''   ');

s_LocalEnableArr: array[0..7] of String[11] = (
  'All Kbd OFF',  // 0
  'Upper ON   ',  // 1
  'Lower ON   ',  // 2
  'Upr+Lwr ON ',  // 3
  'Pedal ON   ',  // 4
  'Upr+Ped ON ',  // 5
  'Lwr+Ped ON ',  // 6
  'All Kbd ON '); // 7


// wird auch über SysEx gesendet
// s_MenuMidiCCArr: array[0..3] of String[11] = (
//  'NI B4 d3c  ',  // 0
//  'Hammond XK ',  // 1
//  'Hammond SK ',  // 2
//  'Versatile  ');  // 3
//  'Nord C1/C2 ',  // aus DF Core Block c_midicc_base +4, 'nordc_cc.dat'
//  'VoceDrawbar' , // aus DF Core Block c_midicc_base +5, 'voced_cc.dat'
//  'KeyB/Duo   ' , // aus DF Core Block c_midicc_base +6, 'keybd_cc.dat'
//  'Hamichord  ' , // aus DF Core Block c_midicc_base +7, 'hamic_cc.dat'
//  'KBP/Touchp ' , // aus DF Core Block c_midicc_base +8, 'hx35k_cc.dat'
//  'Custom 1   ' , // aus DF Core Block c_midicc_base +9, 'cust1_cc.dat'
//  'Custom 2   ' );// aus DF Core Block c_midicc_base +10,'cust2_cc.dat'

s_MenuTaperingArr: array[0..5] of String[11] = (
  'Year 1955  ',    // 0 Cap Sets, Tapering B3
  'Year 1961  ',    // 1
  'Year 1972  ',    // 2
  'Recapped   ',    // 3 B3 aggressiv
  'StraightLin',    // 4 linear, kein Tapering
  'Twangy     ' );  // 5 hohe Noten betont

{
Waveset: 0..3 Hammond 25-38% k2,
4: Sinus 2% THD
5: Sägezahn gefiltert für Strings oder Cheesy
6: Sinus 12% k3 für Conn
7: Sinus Square 8% k3, 5% k5
}
s_MenuWaveArr: array[0..7] of String[11] = (
  'B3  25% k2 ',  // 0 neue B3
  'B3  28% k2 ',  // 1
  'B3  32% k2 ',  // 2
  'B3  38% k2 ',  // 3 alte B3
  'Sine 2% k2 ',  // 4 Reiner Sinus, Böhm mit Sinus-Zusatz
  'Sawt Fltrd ',  // 5 Sägezahn gefiltert
  'Sine LC Gen',  // 6 Sinus LC-Generator
  'Sine TOSGen'); // 7 Sinus aus Rechteck-Filterung


const

c_edit_max: Array[0..511] of byte = (
  127, // #1000 Upper Drawbar 16
  127, // #1001 Upper Drawbar 5 1/3
  127, // #1002 Upper Drawbar 8
  127, // #1003 Upper Drawbar 4
  127, // #1004 Upper Drawbar 2 2/3
  127, // #1005 Upper Drawbar 2
  127, // #1006 Upper Drawbar 1 3/5
  127, // #1007 Upper Drawbar 1 1/3
  127, // #1008 Upper Drawbar 1
  127, // #1009 Upper Mixture Drawbar 10
  127, // #1010 Upper Mixture Drawbar 11
  127, // #1011 Upper Mixture Drawbar 12
  0, // #1012
  0, // #1013
  0, // #1014
  127, // #1015
  127, // #1016 Lower Drawbar 16
  127, // #1017 Lower Drawbar 5 1/3
  127, // #1018 Lower Drawbar 8
  127, // #1019 Lower Drawbar 4
  127, // #1020 Lower Drawbar 2 2/3
  127, // #1021 Lower Drawbar 2
  127, // #1022 Lower Drawbar 1 3/5
  127, // #1023 Lower Drawbar 1 1/3
  127, // #1024 Lower Drawbar 1
  127, // #1025 Lower Mixture Drawbar 10
  127, // #1026 Lower Mixture Drawbar 11
  127, // #1027 Lower Mixture Drawbar 12
  0, // #1028
  0, // #1029
  0, // #1030
  127, // #1031 Pedal Drawbar 16
  127, // #1032 Pedal Drawbar 16
  127, // #1033 Pedal Drawbar 5 1/3
  127, // #1034 Pedal Drawbar 8
  127, // #1035 Pedal Drawbar 4
  127, // #1036 Pedal Drawbar 2 2/3
  127, // #1037 Pedal Drawbar 2
  127, // #1038 Pedal Drawbar 1 3/5
  127, // #1039 Pedal Drawbar 1 1/3
  127, // #1040 Pedal Drawbar 1
  127, // #1041 Pedal Mixture Drawbar 10
  127, // #1042 Pedal Mixture Drawbar 11
  127, // #1043 Pedal Mixture Drawbar 12
  0, // #1044
  0, // #1045
  0, // #1046
  127, // #1047
  127, // #1048 Upper Attack
  127, // #1049 Upper Decay
  127, // #1050 Upper Sustain
  127, // #1051 Upper Release
  127, // #1052 Upper ADSR Harmonic Decay
  0, // #1053
  0, // #1054
  0, // #1055
  127, // #1056 Lower Attack
  127, // #1057 Lower Decay
  127, // #1058 Lower Sustain
  127, // #1059 Lower Release
  127, // #1060 Lower ADSR Harmonic Decay
  0, // #1061
  0, // #1062
  0, // #1063
  127, // #1064 Pedal Attack
  127, // #1065 Pedal Decay
  127, // #1066 Pedal Sustain
  127, // #1067 Pedal Release
  127, // #1068 Pedal ADSR Harmonic Decay
  0, // #1069
  0, // #1070
  0, // #1071
  127, // #1072 Pedal Drawbar 16 AutoMix
  127, // #1073 Pedal Drawbar 16H AutoMix
  127, // #1074 Pedal Drawbar 8 AutoMix
  127, // #1075 Pedal Drawbar 8H AutoMix
  127, // #1076 Pitchwheel MIDI Send
  127, // #1077 Pitchwheel Rotary Control
  127, // #1078 Modwheel MIDI Send
  127, // #1079 Modwheel Rotary Control
  127, // #1080 General Master Volume
  127, // #1081 Rotary Simulation Tube Amp Gain
  127, // #1082 Upper Manual Level
  127, // #1083 Lower Manual Level
  127, // #1084 Pedal Level
  127, // #1085 Upper Dry/2ndVoice Level
  127, // #1086 Overall Reverb Level
  127, // #1087 Tone Pot Equ
  127, // #1088 Trim Cap Swell
  127, // #1089 Minimal Swell Level
  127, // #1090 AO 28 Triode Distortion
  127, // #1091 Böhm Module Reverb Volume
  127, // #1092 Böhm Module Efx Volume
  127, // #1093 Böhm Module Swell Volume
  127, // #1094 Böhm Module Front Volume
  127, // #1095 Böhm Module Rear Volume
  127, // #1096 Upper Envelope Drawbar 16
  127, // #1097 Upper Envelope Drawbar 5 1/3
  127, // #1098 Upper Envelope Drawbar 8
  127, // #1099 Upper Envelope Drawbar 4
  127, // #1100 Upper Envelope Drawbar 2 2/3
  127, // #1101 Upper Envelope Drawbar 2
  127, // #1102 Upper Envelope Drawbar 1 3/5
  127, // #1103 Upper Envelope Drawbar 1 1/3
  127, // #1104 Upper Envelope Drawbar 1
  127, // #1105 Upper Envelope Mixture Drawbar 10
  127, // #1106 Upper Envelope Mixture Drawbar 11
  127, // #1107 Upper Envelope Mixture Drawbar 12
  0, // #1108
  0, // #1109
  0, // #1110
  0, // #1111
  127, // #1112 Equ Bass Control
  127, // #1113 Equ Bass Frequency if FullParametric
  127, // #1114 Equ Bass Peak/Q if FullParametric
  127, // #1115 Equ Mid Control
  127, // #1116 Equ Mid Frequency
  127, // #1117 Equ Mid Peak/Q
  127, // #1118 Equ Treble Control
  127, // #1119 Equ Treble Frequency if FullParametric
  127, // #1120 Equ Treble Peak/Q if FullParametric
  255, // #1121 Equ FullParametric Enable
  127, // #1122 Böhm Module Ext Rotary Volume Left
  127, // #1123 Böhm Module Ext Rotary Volume Right
  127, // #1124 Equ Bass Gain Pot Mid Position
  127, // #1125 Equ Mid Gain Pot Mid Position
  127, // #1126 Equ Treble Gain Pot Mid Position
  127, // #1127 Perc/Dry Volume Mid Position
  255, // #1128 Percussion ON
  255, // #1129 Percussion SOFT
  255, // #1130 Percussion FAST
  255, // #1131 Percussion THIRD
  255, // #1132 Vibrato Upper ON
  255, // #1133 Vibrato Lower ON
  255, // #1134 Leslie RUN
  255, // #1135 Leslie FAST
  255, // #1136 Tube Amp Bypass
  255, // #1137 Rotary Speaker Bypass
  255, // #1138 Phasing Rotor upper ON
  255, // #1139 Phasing Rotor lower ON
  255, // #1140 Reverb 1
  255, // #1141 Reverb 2
  255, // #1142 Add Pedal
  255, // #1143 Keyboard Split ON
  255, // #1144 Phasing Rotor
  255, // #1145 Phasing Rotor Ensemble
  255, // #1146 Phasing Rotor Celeste
  255, // #1147 Phasing Rotor Fading
  255, // #1148 Phasing Rotor Weak
  255, // #1149 Phasing Rotor Deep
  255, // #1150 Phasing Rotor Fast
  255, // #1151 Phasing Rotor Delay
  255, // #1152 TAB #24, H100 Mode
  255, // #1153 TAB #25, Envelope Generator (EG) Mode
  255, // #1154 TAB #26, EG Percussion Drawbar Mode
  255, // #1155 TAB #27, EG TimeBend Drawbar Mode
  255, // #1156 TAB #28, H100 2ndVoice (Perc Decay Bypass)
  255, // #1157 TAB #29, H100 Harp Sustain
  255, // #1158 TAB #30, EG Enables to Dry Channel
  255, // #1159 TAB #31, Equalizer Bypass
  255, // #1160 Upper Drawbar 16 to ADSR
  255, // #1161 Upper Drawbar 5 1/3 to ADSR
  255, // #1162 Upper Drawbar 8 to ADSR
  255, // #1163 Upper Drawbar 4 to ADSR
  255, // #1164 Upper Drawbar 2 2/3 to ADSR
  255, // #1165 Upper Drawbar 2 to ADSR
  255, // #1166 Upper Drawbar1 3/5 to ADSR
  255, // #1167 Upper Drawbar 1 1/3 to ADSR
  255, // #1168 Upper Drawbar 1 to ADSR
  255, // #1169 Upper Mixture Drawbar 10 to ADSR
  255, // #1170 Upper Mixture Drawbar 11 to ADSR
  255, // #1171 Upper Mixture Drawbar 12 to ADSR
  255, // #1172 Swap DACs
  0, // #1173
  255, // #1174 Octave Downshift Upper
  255, // #1175 Octave Downshift Lower
  255, // #1176 Lower Drawbar 16 to ADSR
  255, // #1177 Lower Drawbar 5 1/3 to ADSR
  255, // #1178 Lower Drawbar 8 to ADSR
  255, // #1179 Lower Drawbar 4 to ADSR
  255, // #1180 Lower Drawbar 2 2/3 to ADSR
  255, // #1181 Lower Drawbar 2 to ADSR
  255, // #1182 Lower Drawbar1 3/5 to ADSR
  255, // #1183 Lower Drawbar 1 1/3 to ADSR
  255, // #1184 Lower Drawbar 1 to ADSR
  255, // #1185 Lower Mixture Drawbar 10 to ADSR
  255, // #1186 Lower Mixture Drawbar 11 to ADSR
  255, // #1187 Lower Mixture Drawbar 12 to ADSR
  255, // #1188
  255, // #1189 MIDI Upper Enable
  255, // #1190 MIDI Lower Enable
  255, // #1191 MIDI Pedal Enable
  15, // #1192 Preset Name String [0] (Length Byte)
  127, // #1193 Preset Name String [1]
  127, // #1194 Preset Name String [2]
  127, // #1195 Preset Name String [3]
  127, // #1196 Preset Name String [4]
  127, // #1197 Preset Name String [5]
  127, // #1198 Preset Name String [6]
  127, // #1199 Preset Name String [7]
  127, // #1200 Preset Name String [8]
  127, // #1201 Preset Name String [9]
  127, // #1202 Preset Name String [10]
  127, // #1203 Preset Name String [11]
  127, // #1204 Preset Name String [12]
  127, // #1205 Preset Name String [13]
  127, // #1206 Preset Name String [14]
  127, // #1207 Preset Name String [15]
  127, // #1208 Hammond DB Upper Decode
  127, // #1209 Hammond DB Lower Decode
  127, // #1210 Hammond DB Pedal Decode
  127, // #1211 Hammond VibKnob Decode
  255, // #1212 4 Btn V1
  255, // #1213 4 Btn V2
  255, // #1214 4 Btn V3
  255, // #1215 4 Btn V/C
  255, // #1216 Transpose +1 UP
  255, // #1217 Transpose -1 DOWN
  255, // #1218 Single DB Destination U/L/P Toggle
  255, // #1219 Single DB set to Upper
  255, // #1220 Single DB set to Lower
  255, // #1221 Single DB set to Pedal
  0, // #1222 nicht abgespeicherte Buttons
  0, // #1223 nicht abgespeicherte Buttons
  126, // #1224 Upper GM Layer 1 Voice
  127, // #1225 Upper GM Layer 1 Level
  5, // #1226 Upper GM Layer 1 Harmonic
  126, // #1227 Upper GM Layer 2 Voice
  127, // #1228 Upper GM Layer 2 Level
  5, // #1229 Upper GM Layer 2 Harmonic
  15, // #1230 Upper GM Layer 2 Detune
  0, // #1231
  126, // #1232 Lower GM Layer 1 Voice
  127, // #1233 Lower GM Layer 1 Level
  5, // #1234 Lower GM Layer 1 Harmonic
  126, // #1235 Lower GM Layer 2 Voice
  127, // #1236 Lower GM Layer 2 Level
  5, // #1237 Lower GM Layer 2 Harmonic
  15, // #1238 Lower GM Layer 2 Detune
  0, // #1239
  126, // #1240 Pedal GM Layer 1 Voice
  127, // #1241 Pedal GM Layer 1 Level
  5, // #1242 Pedal GM Layer 1 Harmonic
  126, // #1243 Pedal GM Layer 2 Voice
  127, // #1244 Pedal GM Layer 2 Level
  5, // #1245 Pedal GM Layer 2 Harmonic
  15, // #1246 Pedal GM Layer 2 Detune
  0, // #1247 Save Event Defaults
  0, // #1248 Save Event Organ
  0, // #1249 Save Event Rotary
  0, // #1250
  0, // #1251
  0, // #1252 Save Event Common
  0, // #1253 Save Event Upper
  0, // #1254 Save Event Lower
  0, // #1255 Save Event Pedal
  0, // #1256
  0, // #1257
  0, // #1258
  0, // #1259
  0, // #1260
  4, // #1261 Gating Mode Knob (MenuPanel)
  15, // #1262 Percussion Knob (MenuPanel)
  3, // #1263 Reverb Knob (MenuPanel)
  5, // #1264 Vibrato Knob
  15, // #1265 Organ Model
  15, // #1266 Rotary Model
  0, // #1267 Upper Prerset Limit
  99, // #1268 Overall Preset (Temp)
  15, // #1269 Upper Voice
  15, // #1270 Lower Voice
  15, // #1271 Pedal Voice
  127, // #1272 Level Busbar 16
  127, // #1273 Level Busbar 5 1/3
  127, // #1274 Level Busbar 8
  127, // #1275 Level Busbar 4
  127, // #1276 Level Busbar 2 2/3
  127, // #1277 Level Busbar 2
  127, // #1278 Level Busbar 1 3/5
  127, // #1279 Level Busbar 1 1/3
  127, // #1280 Level Busbar 1
  127, // #1281 Level Busbar 10
  127, // #1282 Level Busbar 11
  127, // #1283 Level Busbar 12
  127, // #1284 Level Busbar 13
  127, // #1285 Level Busbar 14
  127, // #1286 Level Busbar 15
  127, // #1287
  72, // #1288 Note Offset Busbar 16
  72, // #1289 Note Offset Busbar 5 1/3
  72, // #1290 Note Offset Busbar 8
  72, // #1291 Note Offset Busbar 4
  72, // #1292 Note Offset Busbar 2 2/3
  72, // #1293 Note Offset Busbar 2
  72, // #1294 Note Offset Busbar 1 3/5
  72, // #1295 Note Offset Busbar 1 1/3
  72, // #1296 Note Offset Busbar 1
  72, // #1297 Note Offset Busbar 10
  72, // #1298 Note Offset Busbar 11
  72, // #1299 Note Offset Busbar 12
  72, // #1300 Note Offset Busbar 13
  72, // #1301 Note Offset Busbar 14
  72, // #1302 Note Offset Busbar 15
  0, // #1303
  0, // #1304
  0, // #1305
  0, // #1306
  0, // #1307
  0, // #1308
  0, // #1309
  0, // #1310
  0, // #1311
  0, // #1312
  0, // #1313
  0, // #1314
  0, // #1315
  0, // #1316
  0, // #1317
  0, // #1318
  0, // #1319
  127, // #1320 Pre-Emphasis (Treble Gain)
  127, // #1321 LC Line Age/AM Amplitude Modulation
  127, // #1322 LC Line Feedback
  127, // #1323 LC Line Reflection
  127, // #1324 LC Line Response Cutoff Frequency
  127, // #1325 LC PhaseLk/Line Cutoff Shelving Level
  127, // #1326 Scanner Gearing (Vib Frequ)
  127, // #1327 Chorus Dry (Bypass) Level
  127, // #1328 Chorus Wet (Scanner) Level
  127, // #1329 Modulation V1/C1
  127, // #1330 Modulation V2/C2
  127, // #1331 Modulation V3/C3
  127, // #1332 Modulation Chorus Enhance
  127, // #1333 Scanner Segment Flutter
  127, // #1334 Preemphasis Highpass Cutoff Frequ
  255, // #1335 Modulation Slope, Preemph HP Phase/Peak
  255, // #1336 PHR Speed Vari Slow (Temp)
  255, // #1337 PHR Speed Vari Fast (Temp)
  255, // #1338 PHR Speed Slow (Temp)
  255, // #1339 PHR Feedback (Temp)
  255, // #1340 PHR Level Ph1 (Temp)
  255, // #1341 PHR Level Ph2 (Temp)
  255, // #1342 PHR Level Ph3 (Temp)
  255, // #1343 PHR Level Dry (Temp)
  255, // #1344 PHR Feedback Invert (Temp)
  255, // #1345 PHR Ramp Delay (Temp)
  255, // #1346 PHR Mod Vari Ph1 (Temp)
  255, // #1347 PHR Mod Vari Ph2 (Temp)
  255, // #1348 PHR Mod Vari Ph3 (Temp)
  255, // #1349 PHR Mod Slow Ph1 (Temp)
  255, // #1350 PHR Mod Slow Ph2 (Temp)
  255, // #1351 PHR Mod Slow Ph3 (Temp)
  0, // #1352 (RFU)
  63, // #1353 Keyboard Split Point if ON
  5, // #1354 Keyboard Split Mode
  255, // #1355 Keyboard Transpose
  255, // #1356 Contact Early Action (Fatar Keybed only)
  255, // #1357 No 1' Drawbar when Perc ON
  3, // #1358 Drawbar 16' Foldback Mode
  255, // #1359 Higher Foldback
  15, // #1360 Contact Spring Flex
  15, // #1361 Contact Spring Damping
  255, // #1362 Percussion Enable On Live DB only
  50, // #1363 Fatar Velocity Factor
  7, // #1364
  0, // #1365
  0, // #1366
  0, // #1367
  12, // #1368 MIDI Channel
  3, // #1369 MIDI Option
  10, // #1370 MIDI CC Set
  127, // #1371 MIDI Swell CC
  127, // #1372 MIDI Volume CC
  7, // #1373 MIDI Local Enable
  127, // #1374 MIDI Preset CC
  255, // #1375 MIDI Show CC
  255, // #1376 MIDI Disable Program Change
  0, // #1377
  0, // #1378
  0, // #1379
  0, // #1380
  0, // #1381
  0, // #1382
  0, // #1383
  2, // #1384 Preamp Swell Type
  3, // #1385 TG Tuning Set
  96, // #1386 TG Size
  127, // #1387 TG Fixed Taper Value
  7, // #1388 TG WaveSet
  15, // #1389 TG Flutter
  7, // #1390 TG Leakage
  15, // #1391 TG Tuning
  5, // #1392 TG Cap Set/Tapering
  127, // #1393 TG LC Filter Fac
  127, // #1394 TG Bottom 16' Octave Taper Val
  255, // #1395 Generator/MIDI IN Transpose
  15, // #1396 Generator Model Limit
  255, // #1397 Organ Upper Manual Enable
  255, // #1398 Organ Lower Manual Enable
  255, // #1399 Organ Pedal Enable
  127, // #1400 Reverb Level 1
  127, // #1401 Reverb Level 2
  127, // #1402 Reverb Level 3
  0, // #1403
  0, // #1404
  0, // #1405
  0, // #1406
  0, // #1407
  7, // #1408
  7, // #1409
  7, // #1410
  15, // #1411
  3, // #1412
  0, // #1413
  0, // #1414
  0, // #1415
  127, // #1416 Mixt DB 10, Level from Busbar 9
  127, // #1417 Mixt DB 10, Level from Busbar 10
  127, // #1418 Mixt DB 10, Level from Busbar 11
  127, // #1419 Mixt DB 10, Level from Busbar 12
  127, // #1420 Mixt DB 10, Level from Busbar 13
  127, // #1421 Mixt DB 10, Level from Busbar 14
  0, // #1422
  0, // #1423
  127, // #1424 Mixt DB 11, Level from Busbar 9
  127, // #1425 Mixt DB 11, Level from Busbar 10
  127, // #1426 Mixt DB 11, Level from Busbar 11
  127, // #1427 Mixt DB 11, Level from Busbar 12
  127, // #1428 Mixt DB 11, Level from Busbar 13
  127, // #1429 Mixt DB 11, Level from Busbar 14
  0, // #1430
  0, // #1431
  127, // #1432 Mixt DB 12, Level from Busbar 9
  127, // #1433 Mixt DB 12, Level from Busbar 10
  127, // #1434 Mixt DB 12, Level from Busbar 11
  127, // #1435 Mixt DB 12, Level from Busbar 12
  127, // #1436 Mixt DB 12, Level from Busbar 13
  127, // #1437 Mixt DB 12, Level from Busbar 14
  0, // #1438
  0, // #1439
  0, // #1440
  0, // #1441
  0, // #1442
  0, // #1443
  0, // #1444
  0, // #1445
  0, // #1446
  0, // #1447
  127, // #1448 Rotary Live Control, Horn Slow Time
  127, // #1449 Rotary Live Control, Rotor Slow Time
  127, // #1450 Rotary Live Control, Horn Fast Time
  127, // #1451 Rotary Live Control, Rotor Fast Time
  127, // #1452 Rotary Live Control, Horn Ramp Up Time
  127, // #1453 Rotary Live Control, Rotor Ramp Up Time
  127, // #1454 Rotary Live Control, Horn Ramp Down Time
  127, // #1455 Rotary Live Control, Rotor Ramp Down Time
  127, // #1456 Rotary Live Control, Speaker Throb Amount
  127, // #1457 Rotary Live Control, Speaker Spread
  127, // #1458 Rotary Live Control, Speaker Balance
  255, // #1459 Sync PHR
  7, // #1460 Rotary Amp: Tube A, old 6550 .. new EL34
  7, // #1461 Rotary Amp: Tube B, old 6550 .. new EL34
  0, // #1462
  0, // #1463
  255, // #1464 ENA_CONT_BITS (LSB), Drawbar 7..0
  255, // #1465 ENA_CONT_BITS (MSB), Drawbar 11..8
  255, // #1466 ENA_ENV_DB_BITS (LSB), Drawbar 7..0
  255, // #1467 ENA_ENV_DB_BITS (MSB), Drawbar 11..8
  255, // #1468 ENA_ENV_FULL_BITS (LSB), Drawbar 7..0
  255, // #1469 ENA_ENV_FULL_BITS (MSB), Drawbar 11..8
  255, // #1470 ENV_TO_DRY_BITS (LSB), Drawbar 7..0
  255, // #1471 ENV_TO_DRY_BITS (MSB), Drawbar 11..8
  255, // #1472 ENA_CONT_PERC_BITS (LSB), Drawbar 7..0
  255, // #1473 ENA_CONT_PERC_BITS (MSB), Drawbar 11..8
  255, // #1474 ENA_ENV_PERCMODE_BITS (LSB), Drawbar 7..0
  255, // #1475 ENA_ENV_PERCMODE_BITS (MSB), Drawbar 11..8
  255, // #1476 ENA_ENV_ADSRMODE_BITS (LSB), Drawbar 7..0
  255, // #1477 ENA_ENV_ADSRMODE_BITS (MSB), Drawbar 11..8
  0, // #1478
  0, // #1479
  127, // #1480 Perc Norm Level
  127, // #1481 Perc Soft Level
  127, // #1482 Perc Long Time
  127, // #1483 Perc Short Time
  127, // #1484 Perc Muted Level
  0, // #1485
  127, // #1486 Perc Precharge Time
  255, // #1487 Perc Ena on Live DB only
  0, // #1488 (RFU)
  0, // #1489 (RFU)
  127, // #1490 GM2 Synth Volume
  127, // #1491 Relative Organ Volume
  127, // #1492 H100 Harp Sustain Time
  127, // #1493 H100 2nd Voice Level
  0, // #1494 (RFU)
  15, // #1495 LED Dimmer
  40, // #1496 (not used)
  3, // #1497 Vibrato Knob Mode
  255, // #1498 CommonPreset Save/Restore Mask
  255, // #1499 (not used)
  255, // #1500 (not used)
  255, // #1501 Various Configurations 1
  255, // #1502 Various Configurations 2
  4, // #1503 ADC Configuration
  40, // #1504 1st DB Set Voice Number (enabled when 0..15)
  40, // #1505 2nd DB Set Voice Number (enabled when 1..15)
  2, // #1506 Pedal Drawbar Configuration
  127, // #1507 ADC Scaling
  255, // #1508 (not used)
  255, // #1509 HX3.5 Device Type
  255, // #1510 Preset/EEPROM Structure Version
  255  // #1511 Magic Flag
);


{$IFDEF DEBUG_SEMPRA}
{$I debug_sempra_inc.pas}
{$ENDIF}

c_tubeampslopes: Array[0..7, 0..31] of Integer = (
  (
  1024,
  998,
  952,
  910,
  870,
  831,
  793,
  755,
  718,
  682,
  646,
  610,
  575,
  540,
  505,
  471,
  436,
  402,
  368,
  335,
  301,
  268,
  235,
  202,
  169,
  137,
  104,
  72,
  39,
  7,
  0,
  0
  ),  (    // Slope pow(2)
  1024,
  1019,
  1003,
  981,
  955,
  926,
  895,
  861,
  825,
  786,
  746,
  705,
  661,
  616,
  570,
  522,
  473,
  423,
  371,
  319,
  265,
  209,
  153,
  96,
  38,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(3)
  1024,
  1023,
  1019,
  1011,
  999,
  983,
  963,
  939,
  911,
  879,
  843,
  803,
  759,
  711,
  659,
  603,
  543,
  479,
  411,
  339,
  263,
  183,
  99,
  11,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(4)
  1024,
  1024,
  1023,
  1020,
  1014,
  1005,
  993,
  978,
  958,
  934,
  905,
  871,
  832,
  787,
  737,
  681,
  619,
  550,
  475,
  393,
  304,
  209,
  106,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(5  1024,
  1024,
  1024,
  1024,
  1023,
  1021,
  1017,
  1012,
  1003,
  991,
  974,
  953,
  926,
  894,
  854,
  806,
  750,
  685,
  610,
  525,
  428,
  318,
  196,
  60,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(6)
  1024,
  1024,
  1024,
  1024,
  1024,
  1023,
  1022,
  1020,
  1016,
  1009,
  1000,
  986,
  967,
  942,
  908,
  864,
  808,
  737,
  651,
  545,
  417,
  264,
  82,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(7)
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1023,
  1022,
  1020,
  1016,
  1011,
  1002,
  988,
  969,
  941,
  902,
  850,
  781,
  691,
  574,
  426,
  240,
  8,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ), (    // Slope pow(8)
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1024,
  1023,
  1022,
  1021,
  1018,
  1013,
  1005,
  993,
  975,
  948,
  910,
  856,
  781,
  679,
  543,
  362,
  127,
  0,
  0,
  0,
  0,
  0,
  0,
  0
  ));


// #############################################################################
// ###                   Save/Restore Mask (Matrix)                          ###
// #############################################################################

// MSN Value Type Bits 12..15
// 0 = None
// 1 = Button
// 2 = Knob
// 3 = Analog
// 4 = Convert Button to Knob
// 5 = Convert Knob to Button
// 6 = Momentary/Pulse/RadioBtn
// 7 = Number
// 8 = String
// 15 = Save Button/Enter, ignored in Preset/Model

// LSN Save Dest (MenuPanel-Destination-Anzeige) Bits 8..11
// 0 = None/Unsaved
// 1 = Upper Drawbars
// 2 = Lower Drawbars
// 3 = Pedal Drawbars
// 4 = Common Preset
// 5 = Common Preset, valid only if PresetGM-Mask = 1
// 6 = Common Preset, valid only if PresetPercDB-Mask = 1
// 7 = Organ Model
// 8 = Speaker Model
// 9 = Defaults
// 10 = Extended Params >= #2000
// 11 = System Inits


// Bits 0..7, RestoreMask, Bit=1: Wert wird aus Preset geholt wenn
// gleiches Bit in edit_SaveRestoreMask auch gesetzt ist
// Bit 7    Bit 6   Bit 5    Bit 4      Bit 3      Bit 2     Bit 1     Bit 0
// GMsynth  VolEq  RotyS/F   KnobsTabs  EGPercDBs  PedalDBs  LowerDBs  UpperDBs



  c_SaveRestoreMasks: array[0..c_edit_array_len-1] of Word = (
  12545, // #1000 Upper Drawbar 16
  12545, // #1001 Upper Drawbar 5 1/3
  12545, // #1002 Upper Drawbar 8
  12545, // #1003 Upper Drawbar 4
  12545, // #1004 Upper Drawbar 2 2/3
  12545, // #1005 Upper Drawbar 2
  12545, // #1006 Upper Drawbar 1 3/5
  12545, // #1007 Upper Drawbar 1 1/3
  12545, // #1008 Upper Drawbar 1
  12545, // #1009 Upper Mixture Drawbar 10
  12545, // #1010 Upper Mixture Drawbar 11
  12545, // #1011 Upper Mixture Drawbar 12
  0, // #1012 (RFU)
  0, // #1013 (RFU)
  0, // #1014 (RFU)
  0, // #1015 (RFU)
  12802, // #1016 Lower Drawbar 16
  12802, // #1017 Lower Drawbar 5 1/3
  12802, // #1018 Lower Drawbar 8
  12802, // #1019 Lower Drawbar 4
  12802, // #1020 Lower Drawbar 2 2/3
  12802, // #1021 Lower Drawbar 2
  12802, // #1022 Lower Drawbar 1 3/5
  12802, // #1023 Lower Drawbar 1 1/3
  12802, // #1024 Lower Drawbar 1
  12802, // #1025 Lower Mixture Drawbar 10
  12802, // #1026 Lower Mixture Drawbar 11
  12802, // #1027 Lower Mixture Drawbar 12
  0, // #1028 (RFU)
  0, // #1029 (RFU)
  0, // #1030 (RFU)
  0, // #1031 (RFU)
  13060, // #1032 Pedal Drawbar 16
  13060, // #1033 Pedal Drawbar 5 1/3
  13060, // #1034 Pedal Drawbar 8
  13060, // #1035 Pedal Drawbar 4
  13060, // #1036 Pedal Drawbar 2 2/3
  13060, // #1037 Pedal Drawbar 2
  13060, // #1038 Pedal Drawbar 1 3/5
  13060, // #1039 Pedal Drawbar 1 1/3
  13060, // #1040 Pedal Drawbar 1
  13060, // #1041 Pedal Mixture Drawbar 10
  13060, // #1042 Pedal Mixture Drawbar 11
  13060, // #1043 Pedal Mixture Drawbar 12
  0, // #1044 (RFU)
  0, // #1045 (RFU)
  0, // #1046 (RFU)
  0, // #1047 (RFU)
  13833, // #1048 Upper Attack
  13833, // #1049 Upper Decay
  13833, // #1050 Upper Sustain
  13833, // #1051 Upper Release
  13833, // #1052 Upper ADSR Harmonic Decay
  0, // #1053 (RFU)
  0, // #1054 (RFU)
  0, // #1055 (RFU)
  13834, // #1056 Lower Attack
  13834, // #1057 Lower Decay
  13834, // #1058 Lower Sustain
  13834, // #1059 Lower Release
  13834, // #1060 Lower ADSR Harmonic Decay
  0, // #1061 (RFU)
  0, // #1062 (RFU)
  0, // #1063 (RFU)
  13836, // #1064 Pedal Attack
  13836, // #1065 Pedal Decay
  13836, // #1066 Pedal Sustain
  13836, // #1067 Pedal Release
  13836, // #1068 Pedal ADSR Harmonic Decay
  0, // #1069 (RFU)
  0, // #1070 (RFU)
  0, // #1071 (RFU)
  13060, // #1072 Pedal Drawbar 16 AutoMix
  13060, // #1073 Pedal Drawbar 16H AutoMix
  13060, // #1074 Pedal Drawbar 8 AutoMix
  13060, // #1075 Pedal Drawbar 8H AutoMix
  12288, // #1076 Pitchwheel MIDI Send
  12288, // #1077 Pitchwheel Rotary Control
  12288, // #1078 Modwheel MIDI Send
  12288, // #1079 Modwheel Rotary Control
  13376, // #1080 General Master Volume
  13344, // #1081 Rotary Simulation Tube Amp Gain
  14080, // #1082 Upper Manual Level
  14080, // #1083 Lower Manual Level
  14080, // #1084 Pedal Level
  14080, // #1085 Upper Dry/2ndVoice Level
  13376, // #1086 Overall Reverb Level
  14080, // #1087 Tone Pot Equ
  14080, // #1088 Trim Cap Swell
  14080, // #1089 Minimal Swell Level
  14080, // #1090 AO 28 Triode Distortion
  0, // #1091 Böhm Module Reverb Volume
  0, // #1092 Böhm Module Efx Volume
  0, // #1093 Böhm Module Swell Volume
  0, // #1094 Böhm Module Front Volume
  0, // #1095 Böhm Module Rear Volume
  13833, // #1096 Upper Envelope Drawbar 16
  13833, // #1097 Upper Envelope Drawbar 5 1/3
  13833, // #1098 Upper Envelope Drawbar 8
  13833, // #1099 Upper Envelope Drawbar 4
  13833, // #1100 Upper Envelope Drawbar 2 2/3
  13833, // #1101 Upper Envelope Drawbar 2
  13833, // #1102 Upper Envelope Drawbar 1 3/5
  13833, // #1103 Upper Envelope Drawbar 1 1/3
  13833, // #1104 Upper Envelope Drawbar 1
  13833, // #1105 Upper Envelope Mixture Drawbar 10
  13833, // #1106 Upper Envelope Mixture Drawbar 11
  13833, // #1107 Upper Envelope Mixture Drawbar 12
  0, // #1108 (RFU)
  0, // #1109 (RFU)
  0, // #1110 (RFU)
  0, // #1111 (RFU)
  13376, // #1112 Equ Bass Control
  13376, // #1113 Equ Bass Frequency if FullParametric
  13376, // #1114 Equ Bass Peak/Q if FullParametric
  13376, // #1115 Equ Mid Control
  13376, // #1116 Equ Mid Frequency
  13376, // #1117 Equ Mid Peak/Q
  13376, // #1118 Equ Treble Control
  13376, // #1119 Equ Treble Frequency if FullParametric
  13376, // #1120 Equ Treble Peak/Q if FullParametric
  6400, // #1121 Equ FullParametric Enable
  0, // #1122 Böhm Module Ext Rotary Volume Left
  0, // #1123 Böhm Module Ext Rotary Volume Right
  14592, // #1124 Equ Bass Gain Pot Mid Position
  14592, // #1125 Equ Mid Gain Pot Mid Position
  14592, // #1126 Equ Treble Gain Pot Mid Position
  14592, // #1127 Perc/Dry Volume Mid Position
  17425, // #1128 Percussion ON
  17425, // #1129 Percussion SOFT
  17425, // #1130 Percussion FAST
  17425, // #1131 Percussion THIRD
  5137, // #1132 Vibrato Upper ON
  5138, // #1133 Vibrato Lower ON
  5152, // #1134 Leslie RUN
  5152, // #1135 Leslie FAST
  5136, // #1136 Tube Amp Bypass
  5136, // #1137 Rotary Speaker Bypass
  5137, // #1138 Phasing Rotor upper ON
  5138, // #1139 Phasing Rotor lower ON
  17424, // #1140 Reverb 1
  17424, // #1141 Reverb 2
  5136, // #1142 Add Pedal
  4112, // #1143 Keyboard Split ON
  5136, // #1144 Phasing Rotor
  5136, // #1145 Phasing Rotor Ensemble
  5136, // #1146 Phasing Rotor Celeste
  5136, // #1147 Phasing Rotor Fading
  5136, // #1148 Phasing Rotor Weak
  5136, // #1149 Phasing Rotor Deep
  5136, // #1150 Phasing Rotor Fast
  5136, // #1151 Phasing Rotor Delay
  16384, // #1152 TAB #24, H100 Mode
  16384, // #1153 TAB #25, Envelope Generator (EG) Mode
  16384, // #1154 TAB #26, EG Percussion Drawbar Mode
  16384, // #1155 TAB #27, EG TimeBend Drawbar Mode
  5136, // #1156 TAB #28, H100 2ndVoice (Perc Decay Bypass)
  5136, // #1157 TAB #29, H100 Harp Sustain
  5136, // #1158 TAB #30, EG Enables to Dry Channel
  5136, // #1159 TAB #31, Equalizer Bypass
  5641, // #1160 Upper Drawbar 16 to ADSR
  5641, // #1161 Upper Drawbar 5 1/3 to ADSR
  5641, // #1162 Upper Drawbar 8 to ADSR
  5641, // #1163 Upper Drawbar 4 to ADSR
  5641, // #1164 Upper Drawbar 2 2/3 to ADSR
  5641, // #1165 Upper Drawbar 2 to ADSR
  5641, // #1166 Upper Drawbar1 3/5 to ADSR
  5641, // #1167 Upper Drawbar 1 1/3 to ADSR
  5641, // #1168 Upper Drawbar 1 to ADSR
  5641, // #1169 Upper Mixture Drawbar 10 to ADSR
  5641, // #1170 Upper Mixture Drawbar 11 to ADSR
  5641, // #1171 Upper Mixture Drawbar 12 to ADSR
  5136, // #1172 Swap DACs
  0, // #1173 (RFU)
  6400, // #1174 Octave Downshift Upper
  6400, // #1175 Octave Downshift Lower
  5138, // #1176 Lower Drawbar 16 to ADSR
  5138, // #1177 Lower Drawbar 5 1/3 to ADSR
  5138, // #1178 Lower Drawbar 8 to ADSR
  5138, // #1179 Lower Drawbar 4 to ADSR
  5138, // #1180 Lower Drawbar 2 2/3 to ADSR
  5138, // #1181 Lower Drawbar 2 to ADSR
  5138, // #1182 Lower Drawbar1 3/5 to ADSR
  5138, // #1183 Lower Drawbar 1 1/3 to ADSR
  5138, // #1184 Lower Drawbar 1 to ADSR
  5138, // #1185 Lower Mixture Drawbar 10 to ADSR
  5138, // #1186 Lower Mixture Drawbar 11 to ADSR
  5138, // #1187 Lower Mixture Drawbar 12 to ADSR
  0, // #1188 (RFU)
  6416, // #1189 MIDI Upper Enable
  6416, // #1190 MIDI Lower Enable
  6416, // #1191 MIDI Pedal Enable
  25600, // #1192 Dec Overall/Common Preset
  25600, // #1193 Inc Overall/Common Preset
  25600, // #1194 Dec Upper Voice
  25600, // #1195 Inc Upper Voice
  25600, // #1196 Dec Lower Voice
  25600, // #1197 Inc Lower Voice
  25600, // #1198 Dec Pedal Voice
  25600, // #1199 Inc Pedal Voice
  25600, // #1200 Dec OrganModel
  25600, // #1201 Inc OrganModel
  25600, // #1202 Dec SpeakerModel
  25600, // #1203 Inc SpeakerModel
  25600, // #1204 Dec Transpose
  25600, // #1205 Inc Transpose
  25600, // #1206 (RFU)
  25600, // #1207 (RFU)
  24576, // #1208 Hammond DB Upper Decode
  24576, // #1209 Hammond DB Lower Decode
  24576, // #1210 Hammond DB Pedal Decode
  24576, // #1211 Hammond VibKnob Decode
  24576, // #1212 4 Btn V1
  24576, // #1213 4 Btn V2
  24576, // #1214 4 Btn V3
  24576, // #1215 4 Btn V/C, 6 Btn C1
  24576, // #1216 6 Btn C2
  24576, // #1217 6 Btn C3
  24576, // #1218 Single DB Destination U/L/P Toggle
  24576, // #1219 Single DB set to Upper
  24576, // #1220 Single DB set to Lower
  24576, // #1221 Single DB set to Pedal
  0, // #1222 (RFU)
  0, // #1223 (RFU)
  30081, // #1224 Upper GM Layer 1 Voice
  13697, // #1225 Upper GM Layer 1 Level
  13697, // #1226 Upper GM Layer 1 Harmonic
  30081, // #1227 Upper GM Layer 2 Voice
  13697, // #1228 Upper GM Layer 2 Level
  13697, // #1229 Upper GM Layer 2 Harmonic
  13697, // #1230 Upper GM Layer 2 Detune
  0, // #1231 (RFU)
  30082, // #1232 Lower GM Layer 1 Voice
  13698, // #1233 Lower GM Layer 1 Level
  13698, // #1234 Lower GM Layer 1 Harmonic
  30082, // #1235 Lower GM Layer 2 Voice
  13698, // #1236 Lower GM Layer 2 Level
  13698, // #1237 Lower GM Layer 2 Harmonic
  13698, // #1238 Lower GM Layer 2 Detune
  0, // #1239 (RFU)
  30084, // #1240 Pedal GM Layer 1 Voice
  13700, // #1241 Pedal GM Layer 1 Level
  13700, // #1242 Pedal GM Layer 1 Harmonic
  30084, // #1243 Pedal GM Layer 2 Voice
  13700, // #1244 Pedal GM Layer 2 Level
  13700, // #1245 Pedal GM Layer 2 Harmonic
  13700, // #1246 Pedal GM Layer 2 Detune
  63744, // #1247 Save Event Defaults
  63232, // #1248 Save Event Organ
  63488, // #1249 Save Event Speaker/Rotary
  0, // #1250 (RFU)
  0, // #1251 (RFU)
  62464, // #1252 Save Event Common
  61696, // #1253 Save Event Upper
  61952, // #1254 Save Event Lower
  62208, // #1255 Save Event Pedal
  0, // #1256
  0, // #1257 (RFU)
  0, // #1258 (RFU)
  0, // #1259 (RFU)
  0, // #1260 (RFU)
  22272, // #1261 Gating Mode Knob (MenuPanel)
  21521, // #1262 Percussion Knob (MenuPanel)
  21520, // #1263 Reverb Knob (MenuPanel)
  21521, // #1264 Vibrato Knob
  29712, // #1265 Organ Model
  29712, // #1266 Rotary Speaker Model
  30976, // #1267 Upper Preset Limit
  29696, // #1268 Overall Preset (Temp)
  28928, // #1269 Upper Voice
  29184, // #1270 Lower Voice
  29440, // #1271 Pedal Voice
  30464, // #1272 Level Busbar 16
  30464, // #1273 Level Busbar 5 1/3
  30464, // #1274 Level Busbar 8
  30464, // #1275 Level Busbar 4
  30464, // #1276 Level Busbar 2 2/3
  30464, // #1277 Level Busbar 2
  30464, // #1278 Level Busbar 1 3/5
  30464, // #1279 Level Busbar 1 1/3
  30464, // #1280 Level Busbar 1
  30464, // #1281 Level Busbar 10
  30464, // #1282 Level Busbar 11
  30464, // #1283 Level Busbar 12
  30464, // #1284 Level Busbar 13
  30464, // #1285 Level Busbar 14
  30464, // #1286 Level Busbar 15
  0, // #1287 (RFU)
  30464, // #1288 Note Offset Busbar 16
  30464, // #1289 Note Offset Busbar 5 1/3
  30464, // #1290 Note Offset Busbar 8
  30464, // #1291 Note Offset Busbar 4
  30464, // #1292 Note Offset Busbar 2 2/3
  30464, // #1293 Note Offset Busbar 2
  30464, // #1294 Note Offset Busbar 1 3/5
  30464, // #1295 Note Offset Busbar 1 1/3
  30464, // #1296 Note Offset Busbar 1
  30464, // #1297 Note Offset Busbar 10
  30464, // #1298 Note Offset Busbar 11
  30464, // #1299 Note Offset Busbar 12
  30464, // #1300 Note Offset Busbar 13
  30464, // #1301 Note Offset Busbar 14
  30464, // #1302 Note Offset Busbar 15
  0, // #1303 (RFU)
  0, // #1304 (RFU)
  0, // #1305 (RFU)
  0, // #1306 (RFU)
  0, // #1307 (RFU)
  0, // #1308 (RFU)
  0, // #1309 (RFU)
  0, // #1310 (RFU)
  0, // #1311 (RFU)
  0, // #1312 (RFU)
  0, // #1313 (RFU)
  0, // #1314 (RFU)
  0, // #1315 (RFU)
  0, // #1316 (RFU)
  0, // #1317 (RFU)
  0, // #1318 (RFU)
  0, // #1319 (RFU)
  30464, // #1320 Pre-Emphasis (Treble Gain)
  30464, // #1321 LC Line Age/AM Amplitude Modulation
  30464, // #1322 LC Line Feedback
  30464, // #1323 LC Line Reflection
  30464, // #1324 LC Line Response Cutoff Frequency
  30464, // #1325 LC PhaseLk/Line Cutoff Shelving Level
  30464, // #1326 Scanner Gearing (Vib Frequ)
  30464, // #1327 Chorus Dry (Bypass) Level
  30464, // #1328 Chorus Wet (Scanner) Level
  30464, // #1329 Modulation V1/C1
  30464, // #1330 Modulation V2/C2
  30464, // #1331 Modulation V3/C3
  30464, // #1332 Modulation Chorus Enhance
  30464, // #1333 Scanner Segment Flutter
  30464, // #1334 Preemphasis Highpass Cutoff Frequ
  30464, // #1335 Modulation Slope, Preemph HP Phase/Peak
  16, // #1336 PHR Speed Vari Slow (Temp)
  16, // #1337 PHR Speed Vari Fast (Temp)
  30976, // #1338 PHR Speed Slow (Temp)
  30976, // #1339 PHR Feedback (Temp)
  30976, // #1340 PHR Level Ph1 (Temp)
  30976, // #1341 PHR Level Ph2 (Temp)
  30976, // #1342 PHR Level Ph3 (Temp)
  30976, // #1343 PHR Level Dry (Temp)
  30976, // #1344 PHR Feedback Invert (Temp)
  30976, // #1345 PHR Ramp Delay (Temp)
  30976, // #1346 PHR Mod Vari Ph1 (Temp)
  30976, // #1347 PHR Mod Vari Ph2 (Temp)
  30976, // #1348 PHR Mod Vari Ph3 (Temp)
  30976, // #1349 PHR Mod Slow Ph1 (Temp)
  30976, // #1350 PHR Mod Slow Ph2 (Temp)
  30976, // #1351 PHR Mod Slow Ph3 (Temp)
  0, // #1352 (RFU)
  30976, // #1353 Keyboard Split Point if ON
  30976, // #1354 Keyboard Split Mode
  30976, // #1355 Keyboard Transpose
  30976, // #1356 Contact Early Action (Fatar Keybed only)
  5888, // #1357 No 1' Drawbar when Perc ON
  30464, // #1358 Drawbar 16' Foldback Mode
  5888, // #1359 Higher Foldback
  30464, // #1360 Contact Spring Flex
  30464, // #1361 Contact Spring Damping
  30464, // #1362 Percussion Enable On Live DB only
  30976, // #1363 Fatar Velocity Factor
  0, // #1364 (RFU)
  0, // #1365 (RFU)
  0, // #1366 (RFU)
  0, // #1367 (RFU)
  30976, // #1368 MIDI Channel
  30976, // #1369 MIDI Option
  30976, // #1370 MIDI CC Set
  30976, // #1371 MIDI Swell CC
  30976, // #1372 MIDI Volume CC
  30976, // #1373 MIDI Local Enable
  30976, // #1374 MIDI Preset CC
  6400, // #1375 MIDI Show CC
  30976, // #1376 MIDI Disable Program Change
  30976, // #1377 MIDI Enable VK77 Sysex Rcv
  0, // #1378 (RFU)
  0, // #1379 (RFU)
  0, // #1380 (RFU)
  0, // #1381 (RFU)
  0, // #1382 (RFU)
  0, // #1383 (RFU)
  30464, // #1384 Preamp Swell Type
  30464, // #1385 TG Tuning Set
  30464, // #1386 TG Size
  30464, // #1387 TG Fixed Taper Value
  30464, // #1388 TG WaveSet
  30464, // #1389 TG Flutter
  30464, // #1390 TG Leakage
  28672, // #1391 TG Tuning
  30464, // #1392 TG Cap Set/Tapering
  30464, // #1393 TG LC Filter Fac
  30464, // #1394 TG Bottom 16' Octave Taper Val
  0, // #1395 Generator/MIDI IN Transpose
  0, // #1396 Generator Model Limit
  4096, // #1397 Organ Upper Manual Enable
  4096, // #1398 Organ Lower Manual Enable
  4096, // #1399 Organ Pedal Enable
  5120, // #1400 Reverb Level 1
  5120, // #1401 Reverb Level 2
  5120, // #1402 Reverb Level 3
  0, // #1403 (RFU)
  0, // #1404 (RFU)
  0, // #1405 (RFU)
  0, // #1406 (RFU)
  0, // #1407 (RFU)
  0, // #1408 (RFU)
  0, // #1409 (RFU)
  0, // #1410 (RFU)
  0, // #1411 (RFU)
  0, // #1412 (RFU)
  0, // #1413 (RFU)
  0, // #1414 (RFU)
  0, // #1415 (RFU)
  14080, // #1416 Mixt DB 10, Level from Busbar 9
  14080, // #1417 Mixt DB 10, Level from Busbar 10
  14080, // #1418 Mixt DB 10, Level from Busbar 11
  14080, // #1419 Mixt DB 10, Level from Busbar 12
  14080, // #1420 Mixt DB 10, Level from Busbar 13
  14080, // #1421 Mixt DB 10, Level from Busbar 14
  0, // #1422 (RFU)
  0, // #1423 (RFU)
  14080, // #1424 Mixt DB 11, Level from Busbar 9
  14080, // #1425 Mixt DB 11, Level from Busbar 10
  14080, // #1426 Mixt DB 11, Level from Busbar 11
  14080, // #1427 Mixt DB 11, Level from Busbar 12
  14080, // #1428 Mixt DB 11, Level from Busbar 13
  14080, // #1429 Mixt DB 11, Level from Busbar 14
  0, // #1430 (RFU)
  0, // #1431 (RFU)
  14080, // #1432 Mixt DB 12, Level from Busbar 9
  14080, // #1433 Mixt DB 12, Level from Busbar 10
  14080, // #1434 Mixt DB 12, Level from Busbar 11
  14080, // #1435 Mixt DB 12, Level from Busbar 12
  14080, // #1436 Mixt DB 12, Level from Busbar 13
  14080, // #1437 Mixt DB 12, Level from Busbar 14
  0, // #1438 (RFU)
  0, // #1439 (RFU)
  0, // #1440 (RFU)
  0, // #1441 (RFU)
  0, // #1442 (RFU)
  0, // #1443 (RFU)
  0, // #1444 (RFU)
  0, // #1445 (RFU)
  0, // #1446 (RFU)
  0, // #1447 (RFU)
  14336, // #1448 Rotary Live Control, Horn Slow Time
  14336, // #1449 Rotary Live Control, Rotor Slow Time
  14336, // #1450 Rotary Live Control, Horn Fast Time
  14336, // #1451 Rotary Live Control, Rotor Fast Time
  14336, // #1452 Rotary Live Control, Horn Ramp Up Time
  14336, // #1453 Rotary Live Control, Rotor Ramp Up Time
  14336, // #1454 Rotary Live Control, Horn Ramp Down Time
  14336, // #1455 Rotary Live Control, Rotor Ramp Down Time
  14336, // #1456 Rotary Live Control, Speaker Throb Amount
  14336, // #1457 Rotary Live Control, Speaker Spread
  14336, // #1458 Rotary Live Control, Speaker Balance
  0, // #1459 (RFU)
  30720, // #1460 Rotary Amp: Tube A, old 6550 .. new EL34
  30720, // #1461 Rotary Amp: Tube B, old 6550 .. new EL34
  0, // #1462 (RFU)
  0, // #1463 (RFU)
  0, // #1464 ENA_CONT_BITS (LSB), Drawbar 7..0
  0, // #1465 ENA_CONT_BITS (MSB), Drawbar 11..8
  0, // #1466 ENA_ENV_DB_BITS (LSB), Drawbar 7..0
  0, // #1467 ENA_ENV_DB_BITS (MSB), Drawbar 11..8
  0, // #1468 ENA_ENV_FULL_BITS (LSB), Drawbar 7..0
  0, // #1469 ENA_ENV_FULL_BITS (MSB), Drawbar 11..8
  0, // #1470 ENV_TO_DRY_BITS (LSB), Drawbar 7..0
  0, // #1471 ENV_TO_DRY_BITS (MSB), Drawbar 11..8
  0, // #1472 ENA_CONT_PERC_BITS (LSB), Drawbar 7..0
  0, // #1473 ENA_CONT_PERC_BITS (MSB), Drawbar 11..8
  0, // #1474 ENA_ENV_PERCMODE_BITS (LSB), Drawbar 7..0
  0, // #1475 ENA_ENV_PERCMODE_BITS (MSB), Drawbar 11..8
  0, // #1476 ENA_ENV_ADSRMODE_BITS (LSB), Drawbar 7..0
  0, // #1477 ENA_ENV_ADSRMODE_BITS (MSB), Drawbar 11..8
  0, // #1478 (RFU)
  0, // #1479 (RFU)
  14080, // #1480 Perc Norm Level
  14080, // #1481 Perc Soft Level
  14080, // #1482 Perc Long Time
  14080, // #1483 Perc Short Time
  14080, // #1484 Perc Muted Level
  0, // #1485 (RFU)
  14080, // #1486 Perc Precharge Time
  0, // #1487 Perc Ena on Live DB only
  0, // #1488 (RFU)
  0, // #1489 (RFU)
  14592, // #1490 GM Synth Output Mix Level
  14592, // #1491 Organ Output Mix Level
  1792, // #1492 H100 Harp Sustain Time
  1792, // #1493 H100 2nd Voice Level
  0, // #1494 (RFU)
  29184, // #1495 LED Dimmer
  0, // #1496 (RFU)
  31488, // #1497 Vibrato Knob Mode
  31488, // #1498 CommonPreset Save/Restore Mask
  0, // #1499 (RFU)
  0, // #1500 (RFU)
  31488, // #1501 Various Configurations 1
  31488, // #1502 Various Configurations 2
  31488, // #1503 ADC Configuration
  31488, // #1504 1st DB Set Voice Number (enabled when 0..15)
  31488, // #1505 2nd DB Set Voice Number (enabled when 1..15)
  31488, // #1506 Pedal Drawbar Configuration
  31488, // #1507 ADC Scaling
  31488, // #1508 ADC Hysteresis
  31488, // #1509 HX3 Device Type
  28672, // #1510 Preset/EEPROM Structure Version
  28672  // #1511 Magic Flag
  );

implementation
end const_def.


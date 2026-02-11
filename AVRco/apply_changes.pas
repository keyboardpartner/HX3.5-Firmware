// #############################################################################
// ###                   Tabs auswerten und Änderungen an FPGA               ###
// #############################################################################
Unit apply_changes;

interface

{$IFNDEF MODULE}
uses var_def, edit_changes, nuts_and_bolts, MIDI_com, fpga_hilevel,
     adc_touch_interface, save_restore, switch_interface;
{$ELSE}
uses var_def, edit_changes, nuts_and_bolts, MIDI_Com, fpga_hilevel;
{$ENDIF}

  procedure AC_SendPresetName;

// enable/disable warnings for this unit
  procedure AC_LoadOrganModel;
  procedure AC_LoadSpeakerModel;

  procedure AC_IncDecControls; // Radio Buttons etc.
  procedure AC_IncDecControlsTimerElapsed;
  procedure AC_MutualControls;
  procedure AC_ExecEditChanges;   // Geänderte Bedienelemente als Message senden und für FPGA sammeln

  procedure AC_SendSwell;
  procedure AC_SendVolumes;
  procedure AC_SendTrimPots;
  procedure AC_SendLeslieLiveParams;

  procedure AC_SendPHRprgm;
  procedure AC_IncDecParam(edit_idx: Word; do_inc, do_limit: boolean; event_source: byte);
  procedure AC_IncDecGMprogs(gm_btn_offset: byte; event_source: byte);


  // Wrapper-Forwards für Proc-Tabelle:
  procedure AC_HandleGatingknob;
  procedure AC_HandleGatingButtons;
  procedure AC_HandleVibknob;
  procedure AC_HandleVibButtons;
  procedure AC_HandleReverbKnob;
  procedure AC_HandleReverbButtons;
  procedure AC_HandlePercKnob;
  procedure AC_HandlePercButtons;

  procedure AC_HandleVoiceChangeUpper;
  procedure AC_HandleVoiceChangeLower;
  procedure AC_HandleVoiceChangePedal;

  procedure AC_OrganParamsToFPGA;
  procedure AC_WaveBlocksToFPGA;
  procedure AC_PhasingRotorToFPGA;
  procedure AC_SendUpperDBs;
  procedure AC_SendLowerDBs;
  procedure AC_SendPedalDBs;
  procedure AC_SendConvertedPedalDBs;
  procedure AC_SendTaper;
  procedure AC_RouteDirect;
  procedure AC_SendGating;
  procedure AC_SendInserts;
  procedure AC_SendGM2ena;
  procedure AC_SendRotarySpeed;
  procedure AC_SendMIDIccSet;
  procedure AC_SetDetent;
  procedure AC_SendPercValues;
  procedure AC_SendReverb;
  procedure AC_SendMasterVolume;
  procedure AC_SendGMvoiceUpper0;
  procedure AC_SendGMvoiceUpper1;
  procedure AC_SendGMupperLvl;
  procedure AC_SendGMvoiceLower0;
  procedure AC_SendGMvoiceLower1;
  procedure AC_SendGMlowerLvl;
  procedure AC_SendGMvoicePedal0;
  procedure AC_SendGMvoicePedal1;
  procedure AC_SendGMpedalLvl;
  procedure AC_VibratoToFPGA;
  procedure AC_SendTuningVals;
  procedure AC_SetLEDdimmer;
  procedure AC_SplitConfigToFPGA;

// *****************************************************************************


implementation
{$IDATA}

const

// #############################################################################
// ####                        ACTION-TABELLE                               ####
// #############################################################################

// Diese Tabelle enthält alle Indexe auf Routinen-Adressen in ac_proclist,
// die bei Änderung eines edit-Wertes aufgerufen werden müssen.

c_last_edit_param: Word = c_edit_array_len - 17;

ac_proc_idx: Array[0..c_last_edit_param] of byte = (
    39,  // #1000, Upper Drawbar 16
    39,  // #1001, Upper Drawbar 5 1/3
    39,  // #1002, Upper Drawbar 8
    39,  // #1003, Upper Drawbar 4
    39,  // #1004, Upper Drawbar 2 2/3
    39,  // #1005, Upper Drawbar 2
    39,  // #1006, Upper Drawbar 1 3/5
    39,  // #1007, Upper Drawbar 1 1/3
    39,  // #1008, Upper Drawbar 1
    39,  // #1009, Upper Mixture Drawbar 10
    39,  // #1010, Upper Mixture Drawbar 11
    39,  // #1011, Upper Mixture Drawbar 12
    46,  // #1012, (RFU)
    46,  // #1013, (RFU)
    46,  // #1014, (RFU)
    46,  // #1015, (RFU)
    40,  // #1016, Lower Drawbar 16
    40,  // #1017, Lower Drawbar 5 1/3
    40,  // #1018, Lower Drawbar 8
    40,  // #1019, Lower Drawbar 4
    40,  // #1020, Lower Drawbar 2 2/3
    40,  // #1021, Lower Drawbar 2
    40,  // #1022, Lower Drawbar 1 3/5
    40,  // #1023, Lower Drawbar 1 1/3
    40,  // #1024, Lower Drawbar 1
    40,  // #1025, Lower Mixture Drawbar 10
    40,  // #1026, Lower Mixture Drawbar 11
    40,  // #1027, Lower Mixture Drawbar 12
    46,  // #1028, (RFU)
    46,  // #1029, (RFU)
    46,  // #1030, (RFU)
    46,  // #1031, (RFU)
    42,  // #1032, Pedal Drawbar 16
    42,  // #1033, Pedal Drawbar 5 1/3
    42,  // #1034, Pedal Drawbar 8
    42,  // #1035, Pedal Drawbar 4
    42,  // #1036, Pedal Drawbar 2 2/3
    42,  // #1037, Pedal Drawbar 2
    42,  // #1038, Pedal Drawbar 1 3/5
    42,  // #1039, Pedal Drawbar 1 1/3
    42,  // #1040, Pedal Drawbar 1
    42,  // #1041, Pedal Mixture Drawbar 10
    42,  // #1042, Pedal Mixture Drawbar 11
    42,  // #1043, Pedal Mixture Drawbar 12
    46,  // #1044, (RFU)
    46,  // #1045, (RFU)
    46,  // #1046, (RFU)
    46,  // #1047, (RFU)
    39,  // #1048, Upper Attack
    39,  // #1049, Upper Decay
    39,  // #1050, Upper Sustain
    39,  // #1051, Upper Release
    39,  // #1052, Upper ADSR Harmonic Decay
    46,  // #1053, (RFU)
    46,  // #1054, (RFU)
    46,  // #1055, (RFU)
    40,  // #1056, Lower Attack
    40,  // #1057, Lower Decay
    40,  // #1058, Lower Sustain
    40,  // #1059, Lower Release
    40,  // #1060, Lower ADSR Harmonic Decay
    46,  // #1061, (RFU)
    46,  // #1062, (RFU)
    46,  // #1063, (RFU)
    42,  // #1064, Pedal Attack
    42,  // #1065, Pedal Decay
    42,  // #1066, Pedal Sustain
    42,  // #1067, Pedal Release
    42,  // #1068, Pedal ADSR Harmonic Decay
    46,  // #1069, (RFU)
    46,  // #1070, (RFU)
    46,  // #1071, (RFU)
    41,  // #1072, Pedal Drawbar 16 AutoMix
    41,  // #1073, Pedal Drawbar 16H AutoMix
    41,  // #1074, Pedal Drawbar 8 AutoMix
    41,  // #1075, Pedal Drawbar 8H AutoMix
    46,  // #1076, Pitchwheel MIDI Send
    46,  // #1077, Pitchwheel Rotary Control
    46,  // #1078, Modwheel MIDI Send
    46,  // #1079, Modwheel Rotary Control
    43,  // #1080, General Master Volume
    38,  // #1081, Rotary Simulation Tube Amp Gain
    38,  // #1082, Upper Manual Level
    38,  // #1083, Lower Manual Level
    38,  // #1084, Pedal Level
    38,  // #1085, Upper Dry/2ndVoice Level
    35,  // #1086, Overall Reverb Level
    38,  // #1087, Tone Pot Equ
    38,  // #1088, Trim Cap Swell
    38,  // #1089, Minimal Swell Level
    38,  // #1090, AO 28 Triode Distortion
    38,  // #1091, Böhm Module Reverb Volume
    38,  // #1092, Böhm Module Efx Volume
    38,  // #1093, Böhm Module Swell Volume
    38,  // #1094, Böhm Module Front Volume
    38,  // #1095, Böhm Module Rear Volume
    39,  // #1096, Upper Envelope Drawbar 16
    39,  // #1097, Upper Envelope Drawbar 5 1/3
    39,  // #1098, Upper Envelope Drawbar 8
    39,  // #1099, Upper Envelope Drawbar 4
    39,  // #1100, Upper Envelope Drawbar 2 2/3
    39,  // #1101, Upper Envelope Drawbar 2
    39,  // #1102, Upper Envelope Drawbar 1 3/5
    39,  // #1103, Upper Envelope Drawbar 1 1/3
    39,  // #1104, Upper Envelope Drawbar 1
    39,  // #1105, Upper Envelope Mixture Drawbar 10
    39,  // #1106, Upper Envelope Mixture Drawbar 11
    39,  // #1107, Upper Envelope Mixture Drawbar 12
    46,  // #1108, (RFU)
    46,  // #1109, (RFU)
    46,  // #1110, (RFU)
    46,  // #1111, (RFU)
    37,  // #1112, Equ Bass Control
    37,  // #1113, Equ Bass Frequency if FullParametric
    37,  // #1114, Equ Bass Peak/Q if FullParametric
    37,  // #1115, Equ Mid Control
    37,  // #1116, Equ Mid Frequency
    37,  // #1117, Equ Mid Peak/Q
    37,  // #1118, Equ Treble Control
    37,  // #1119, Equ Treble Frequency if FullParametric
    37,  // #1120, Equ Treble Peak/Q if FullParametric
    37,  // #1121, Equ FullParametric Enable
    38,  // #1122, Böhm Module Ext Rotary Volume Left
    38,  // #1123, Böhm Module Ext Rotary Volume Right
    36,  // #1124, Equ Bass Gain Pot Mid Position
    36,  // #1125, Equ Mid Gain Pot Mid Position
    36,  // #1126, Equ Treble Gain Pot Mid Position
    36,  // #1127, Perc/Dry Volume Mid Position
    7,  // #1128, Percussion ON
    7,  // #1129, Percussion SOFT
    7,  // #1130, Percussion FAST
    7,  // #1131, Percussion THIRD
    17,  // #1132, Vibrato Upper ON
    17,  // #1133, Vibrato Lower ON
    21,  // #1134, Leslie RUN
    21,  // #1135, Leslie FAST
    17,  // #1136, Tube Amp Bypass
    17,  // #1137, Rotary Speaker Bypass
    17,  // #1138, Phasing Rotor upper ON
    17,  // #1139, Phasing Rotor lower ON
    5,  // #1140, Reverb 1
    5,  // #1141, Reverb 2
    17,  // #1142, Add Pedal
    33,  // #1143, Keyboard Split ON
    18,  // #1144, Phasing Rotor
    18,  // #1145, Phasing Rotor Ensemble
    18,  // #1146, Phasing Rotor Celeste
    18,  // #1147, Phasing Rotor Fading
    18,  // #1148, Phasing Rotor Weak
    18,  // #1149, Phasing Rotor Deep
    18,  // #1150, Phasing Rotor Fast
    18,  // #1151, Phasing Rotor Delay
    1,  // #1152, TAB #24, H100 Mode
    1,  // #1153, TAB #25, Envelope Generator (EG) Mode
    1,  // #1154, TAB #26, EG Percussion Drawbar Mode
    1,  // #1155, TAB #27, EG TimeBend Drawbar Mode
    14,  // #1156, TAB #28, H100 2ndVoice (Perc Decay Bypass)
    14,  // #1157, TAB #29, H100 Harp Sustain
    14,  // #1158, TAB #30, EG Enables to Dry Channel
    17,  // #1159, TAB #31, Equalizer Bypass
    14,  // #1160, Upper Drawbar 16 to ADSR
    14,  // #1161, Upper Drawbar 5 1/3 to ADSR
    14,  // #1162, Upper Drawbar 8 to ADSR
    14,  // #1163, Upper Drawbar 4 to ADSR
    14,  // #1164, Upper Drawbar 2 2/3 to ADSR
    14,  // #1165, Upper Drawbar 2 to ADSR
    14,  // #1166, Upper Drawbar1 3/5 to ADSR
    14,  // #1167, Upper Drawbar 1 1/3 to ADSR
    14,  // #1168, Upper Drawbar 1 to ADSR
    14,  // #1169, Upper Mixture Drawbar 10 to ADSR
    14,  // #1170, Upper Mixture Drawbar 11 to ADSR
    14,  // #1171, Upper Mixture Drawbar 12 to ADSR
    17,  // #1172, Swap DACs
    46,  // #1173, (RFU)
    33,  // #1174, Octave Downshift Upper
    33,  // #1175, Octave Downshift Lower
    40,  // #1176, Lower Drawbar 16 to ADSR
    40,  // #1177, Lower Drawbar 5 1/3 to ADSR
    40,  // #1178, Lower Drawbar 8 to ADSR
    40,  // #1179, Lower Drawbar 4 to ADSR
    40,  // #1180, Lower Drawbar 2 2/3 to ADSR
    40,  // #1181, Lower Drawbar 2 to ADSR
    40,  // #1182, Lower Drawbar1 3/5 to ADSR
    40,  // #1183, Lower Drawbar 1 1/3 to ADSR
    40,  // #1184, Lower Drawbar 1 to ADSR
    40,  // #1185, Lower Mixture Drawbar 10 to ADSR
    40,  // #1186, Lower Mixture Drawbar 11 to ADSR
    40,  // #1187, Lower Mixture Drawbar 12 to ADSR
    46,  // #1188, (RFU)
    15,  // #1189, MIDI Upper Enable
    15,  // #1190, MIDI Lower Enable
    15,  // #1191, MIDI Pedal Enable
    46,  // #1192, Dec Overall/Common Preset
    46,  // #1193, Inc Overall/Common Preset
    46,  // #1194, Dec Upper Voice
    46,  // #1195, Inc Upper Voice
    46,  // #1196, Dec Lower Voice
    46,  // #1197, Inc Lower Voice
    46,  // #1198, Dec Pedal Voice
    46,  // #1199, Inc Pedal Voice
    46,  // #1200, Dec OrganModel
    46,  // #1201, Inc OrganModel
    46,  // #1202, Dec SpeakerModel
    46,  // #1203, Inc SpeakerModel
    46,  // #1204, Dec Transpose
    46,  // #1205, Inc Transpose
    46,  // #1206, (RFU)
    46,  // #1207, (RFU)
    46,  // #1208, Hammond DB Upper Decode
    46,  // #1209, Hammond DB Lower Decode
    46,  // #1210, Hammond DB Pedal Decode
    46,  // #1211, Hammond VibKnob Decode
    3,  // #1212, 4 Btn V1
    3,  // #1213, 4 Btn V2
    3,  // #1214, 4 Btn V3
    3,  // #1215, 4 Btn V/C, 6 Btn C1
    3,  // #1216, 6 Btn C2
    3,  // #1217, 6 Btn C3
    46,  // #1218, Single DB Destination U/L/P Toggle
    46,  // #1219, Single DB set to Upper
    46,  // #1220, Single DB set to Lower
    46,  // #1221, Single DB set to Pedal
    46,  // #1222, (RFU)
    46,  // #1223, (RFU)
    30,  // #1224, Upper GM Layer 1 Voice
    25,  // #1225, Upper GM Layer 1 Level
    25,  // #1226, Upper GM Layer 1 Harmonic
    31,  // #1227, Upper GM Layer 2 Voice
    25,  // #1228, Upper GM Layer 2 Level
    25,  // #1229, Upper GM Layer 2 Harmonic
    25,  // #1230, Upper GM Layer 2 Detune
    46,  // #1231, (RFU)
    26,  // #1232, Lower GM Layer 1 Voice
    23,  // #1233, Lower GM Layer 1 Level
    23,  // #1234, Lower GM Layer 1 Harmonic
    27,  // #1235, Lower GM Layer 2 Voice
    23,  // #1236, Lower GM Layer 2 Level
    23,  // #1237, Lower GM Layer 2 Harmonic
    23,  // #1238, Lower GM Layer 2 Detune
    46,  // #1239, (RFU)
    28,  // #1240, Pedal GM Layer 1 Voice
    24,  // #1241, Pedal GM Layer 1 Level
    24,  // #1242, Pedal GM Layer 1 Harmonic
    29,  // #1243, Pedal GM Layer 2 Voice
    24,  // #1244, Pedal GM Layer 2 Level
    24,  // #1245, Pedal GM Layer 2 Harmonic
    24,  // #1246, Pedal GM Layer 2 Detune
    46,  // #1247, Save Event Defaults
    46,  // #1248, Save Event Organ
    46,  // #1249, Save Event Speaker/Rotary
    46,  // #1250, (RFU)
    46,  // #1251, (RFU)
    46,  // #1252, Save Event Common
    46,  // #1253, Save Event Upper
    46,  // #1254, Save Event Lower
    46,  // #1255, Save Event Pedal
    46,  // #1256,
    46,  // #1257, (RFU)
    46,  // #1258, (RFU)
    46,  // #1259, (RFU)
    46,  // #1260, (RFU)
    0,  // #1261, Gating Mode Knob (MenuPanel)
    6,  // #1262, Percussion Knob (MenuPanel)
    4,  // #1263, Reverb Knob (MenuPanel)
    2,  // #1264, Vibrato Knob
    46,  // #1265, Organ Model
    46,  // #1266, Rotary Speaker Model
    46,  // #1267, Upper Preset Limit
    46,  // #1268, Overall Preset (Temp)
    8,  // #1269, Upper Voice
    9,  // #1270, Lower Voice
    10,  // #1271, Pedal Voice
    14,  // #1272, Level Busbar 16
    14,  // #1273, Level Busbar 5 1/3
    14,  // #1274, Level Busbar 8
    14,  // #1275, Level Busbar 4
    14,  // #1276, Level Busbar 2 2/3
    14,  // #1277, Level Busbar 2
    14,  // #1278, Level Busbar 1 3/5
    14,  // #1279, Level Busbar 1 1/3
    14,  // #1280, Level Busbar 1
    14,  // #1281, Level Busbar 10
    14,  // #1282, Level Busbar 11
    14,  // #1283, Level Busbar 12
    14,  // #1284, Level Busbar 13
    14,  // #1285, Level Busbar 14
    14,  // #1286, Level Busbar 15
    46,  // #1287, (RFU)
    11,  // #1288, Note Offset Busbar 16
    11,  // #1289, Note Offset Busbar 5 1/3
    11,  // #1290, Note Offset Busbar 8
    11,  // #1291, Note Offset Busbar 4
    11,  // #1292, Note Offset Busbar 2 2/3
    11,  // #1293, Note Offset Busbar 2
    11,  // #1294, Note Offset Busbar 1 3/5
    11,  // #1295, Note Offset Busbar 1 1/3
    11,  // #1296, Note Offset Busbar 1
    11,  // #1297, Note Offset Busbar 10
    11,  // #1298, Note Offset Busbar 11
    11,  // #1299, Note Offset Busbar 12
    11,  // #1300, Note Offset Busbar 13
    11,  // #1301, Note Offset Busbar 14
    11,  // #1302, Note Offset Busbar 15
    46,  // #1303, (RFU)
    46,  // #1304, (RFU)
    46,  // #1305, (RFU)
    46,  // #1306, (RFU)
    46,  // #1307, (RFU)
    46,  // #1308, (RFU)
    46,  // #1309, (RFU)
    46,  // #1310, (RFU)
    46,  // #1311, (RFU)
    46,  // #1312, (RFU)
    46,  // #1313, (RFU)
    46,  // #1314, (RFU)
    46,  // #1315, (RFU)
    46,  // #1316, (RFU)
    46,  // #1317, (RFU)
    46,  // #1318, (RFU)
    46,  // #1319, (RFU)
    34,  // #1320, Pre-Emphasis (Treble Gain)
    34,  // #1321, LC Line Age/AM Amplitude Modulation
    34,  // #1322, LC Line Feedback
    34,  // #1323, LC Line Reflection
    34,  // #1324, LC Line Response Cutoff Frequency
    34,  // #1325, LC PhaseLk/Line Cutoff Shelving Level
    34,  // #1326, Scanner Gearing (Vib Frequ)
    34,  // #1327, Chorus Dry (Bypass) Level
    34,  // #1328, Chorus Wet (Scanner) Level
    34,  // #1329, Modulation V1/C1
    34,  // #1330, Modulation V2/C2
    34,  // #1331, Modulation V3/C3
    34,  // #1332, Modulation Chorus Enhance
    34,  // #1333, Scanner Segment Flutter
    34,  // #1334, Preemphasis Highpass Cutoff Frequ
    34,  // #1335, Modulation Slope, Preemph HP Phase/Peak
    46,  // #1336, PHR Speed Vari Slow (Temp)
    46,  // #1337, PHR Speed Vari Fast (Temp)
    19,  // #1338, PHR Speed Slow (Temp)
    19,  // #1339, PHR Feedback (Temp)
    19,  // #1340, PHR Level Ph1 (Temp)
    19,  // #1341, PHR Level Ph2 (Temp)
    19,  // #1342, PHR Level Ph3 (Temp)
    19,  // #1343, PHR Level Dry (Temp)
    19,  // #1344, PHR Feedback Invert (Temp)
    19,  // #1345, PHR Ramp Delay (Temp)
    19,  // #1346, PHR Mod Vari Ph1 (Temp)
    19,  // #1347, PHR Mod Vari Ph2 (Temp)
    19,  // #1348, PHR Mod Vari Ph3 (Temp)
    19,  // #1349, PHR Mod Slow Ph1 (Temp)
    19,  // #1350, PHR Mod Slow Ph2 (Temp)
    19,  // #1351, PHR Mod Slow Ph3 (Temp)
    46,  // #1352, (RFU)
    33,  // #1353, Keyboard Split Point if ON
    33,  // #1354, Keyboard Split Mode
    15,  // #1355, Keyboard Transpose
    15,  // #1356, Contact Early Action (Fatar Keybed only)
    15,  // #1357, No 1' Drawbar when Perc ON
    11,  // #1358, Drawbar 16' Foldback Mode
    11,  // #1359, Higher Foldback
    15,  // #1360, Contact Spring Flex
    15,  // #1361, Contact Spring Damping
    15,  // #1362, Percussion Enable On Live DB only
    15,  // #1363, Fatar Velocity Factor
    15,  // #1364, (RFU)
    15,  // #1365, (RFU)
    15,  // #1366, (RFU)
    15,  // #1367, (RFU)
    15,  // #1368, MIDI Channel
    15,  // #1369, MIDI Option
    32,  // #1370, MIDI CC Set
    15,  // #1371, MIDI Swell CC
    15,  // #1372, MIDI Volume CC
    22,  // #1373, MIDI Local Enable
    46,  // #1374, MIDI Preset CC
    46,  // #1375, MIDI Show CC
    46,  // #1376, (RFU)
    46,  // #1377, (RFU)
    46,  // #1378, (RFU)
    46,  // #1379, (RFU)
    46,  // #1380, (RFU)
    46,  // #1381, (RFU)
    46,  // #1382, (RFU)
    46,  // #1383, (RFU)
    38,  // #1384, Preamp Swell Type
    13,  // #1385, TG Tuning Set
    11,  // #1386, TG Size
    11,  // #1387, TG Fixed Taper Value
    12,  // #1388, TG WaveSet
    15,  // #1389, TG Flutter
    15,  // #1390, TG Leakage
    15,  // #1391, TG Tuning
    11,  // #1392, TG Cap Set/Tapering
    11,  // #1393, TG LC Filter Fac
    11,  // #1394, TG Bottom 16' Octave Taper Val
    15,  // #1395, Generator/MIDI IN Transpose
    46,  // #1396, Generator Model Limit
    38,  // #1397, Organ Upper Manual Enable
    38,  // #1398, Organ Lower Manual Enable
    38,  // #1399, Organ Pedal Enable
    5,  // #1400, Reverb Level 1
    5,  // #1401, Reverb Level 2
    5,  // #1402, Reverb Level 3
    46,  // #1403, (RFU)
    46,  // #1404, (RFU)
    46,  // #1405, (RFU)
    46,  // #1406, (RFU)
    46,  // #1407, (RFU)
    46,  // #1408, (RFU)
    46,  // #1409, (RFU)
    46,  // #1410, (RFU)
    46,  // #1411, (RFU)
    46,  // #1412, (RFU)
    46,  // #1413, (RFU)
    46,  // #1414, (RFU)
    46,  // #1415, (RFU)
    14,  // #1416, Mixt DB 10, Level from Busbar 9
    14,  // #1417, Mixt DB 10, Level from Busbar 10
    14,  // #1418, Mixt DB 10, Level from Busbar 11
    14,  // #1419, Mixt DB 10, Level from Busbar 12
    14,  // #1420, Mixt DB 10, Level from Busbar 13
    14,  // #1421, Mixt DB 10, Level from Busbar 14
    14,  // #1422, (RFU)
    14,  // #1423, (RFU)
    14,  // #1424, Mixt DB 11, Level from Busbar 9
    14,  // #1425, Mixt DB 11, Level from Busbar 10
    14,  // #1426, Mixt DB 11, Level from Busbar 11
    14,  // #1427, Mixt DB 11, Level from Busbar 12
    14,  // #1428, Mixt DB 11, Level from Busbar 13
    14,  // #1429, Mixt DB 11, Level from Busbar 14
    14,  // #1430, (RFU)
    14,  // #1431, (RFU)
    14,  // #1432, Mixt DB 12, Level from Busbar 9
    14,  // #1433, Mixt DB 12, Level from Busbar 10
    14,  // #1434, Mixt DB 12, Level from Busbar 11
    14,  // #1435, Mixt DB 12, Level from Busbar 12
    14,  // #1436, Mixt DB 12, Level from Busbar 13
    14,  // #1437, Mixt DB 12, Level from Busbar 14
    46,  // #1438, (RFU)
    46,  // #1439, (RFU)
    46,  // #1440, (RFU)
    46,  // #1441, (RFU)
    46,  // #1442, (RFU)
    46,  // #1443, (RFU)
    46,  // #1444, (RFU)
    46,  // #1445, (RFU)
    46,  // #1446, (RFU)
    46,  // #1447, (RFU)
    20,  // #1448, Rotary Live Control, Horn Slow Time
    20,  // #1449, Rotary Live Control, Rotor Slow Time
    20,  // #1450, Rotary Live Control, Horn Fast Time
    20,  // #1451, Rotary Live Control, Rotor Fast Time
    20,  // #1452, Rotary Live Control, Horn Ramp Up Time
    20,  // #1453, Rotary Live Control, Rotor Ramp Up Time
    20,  // #1454, Rotary Live Control, Horn Ramp Down Time
    20,  // #1455, Rotary Live Control, Rotor Ramp Down Time
    20,  // #1456, Rotary Live Control, Speaker Throb Amount
    20,  // #1457, Rotary Live Control, Speaker Spread
    20,  // #1458, Rotary Live Control, Speaker Balance
    46,  // #1459, (RFU)
    37,  // #1460, Rotary Amp: Tube A, old 6550 .. new EL34
    37,  // #1461, Rotary Amp: Tube B, old 6550 .. new EL34
    46,  // #1462, (RFU)
    46,  // #1463, (RFU)
    45,  // #1464, ENA_CONT_BITS (LSB), Drawbar 7..0
    45,  // #1465, ENA_CONT_BITS (MSB), Drawbar 11..8
    45,  // #1466, ENA_ENV_DB_BITS (LSB), Drawbar 7..0
    45,  // #1467, ENA_ENV_DB_BITS (MSB), Drawbar 11..8
    45,  // #1468, ENA_ENV_FULL_BITS (LSB), Drawbar 7..0
    45,  // #1469, ENA_ENV_FULL_BITS (MSB), Drawbar 11..8
    45,  // #1470, ENV_TO_DRY_BITS (LSB), Drawbar 7..0
    45,  // #1471, ENV_TO_DRY_BITS (MSB), Drawbar 11..8
    45,  // #1472, ENA_CONT_PERC_BITS (LSB), Drawbar 7..0
    45,  // #1473, ENA_CONT_PERC_BITS (MSB), Drawbar 11..8
    45,  // #1474, ENA_ENV_PERCMODE_BITS (LSB), Drawbar 7..0
    45,  // #1475, ENA_ENV_PERCMODE_BITS (MSB), Drawbar 11..8
    45,  // #1476, ENA_ENV_ADSRMODE_BITS (LSB), Drawbar 7..0
    45,  // #1477, ENA_ENV_ADSRMODE_BITS (MSB), Drawbar 11..8
    46,  // #1478, (RFU)
    46,  // #1479, (RFU)
    16,  // #1480, Perc Norm Level
    16,  // #1481, Perc Soft Level
    16,  // #1482, Perc Long Time
    16,  // #1483, Perc Short Time
    16,  // #1484, Perc Muted Level
    46,  // #1485, (RFU)
    16,  // #1486, Perc Precharge Time
    46,  // #1487, Perc Ena on Live DB only
    46,  // #1488, (RFU)
    46,  // #1489, (RFU)
    22,  // #1490, GM Synth Output Mix Level
    22,  // #1491, Organ Output Mix Level
    16,  // #1492, H100 Harp Sustain Time
    16,  // #1493, H100 2nd Voice Level
    46,  // #1494, (RFU)
    44   // #1495  LED Dimmer
  );


// Neue Prozedur-Tabelle statt CASE, Adressen der benutzten Routinen
  c_proc_max: Byte = 46;

  ac_proclist: Array[0..c_proc_max] of procedure = (
    @AC_HandleGatingknob,  // Index [0]
    @AC_HandleGatingButtons,  // Index [1]
    @AC_HandleVibknob,  // Index [2]
    @AC_HandleVibButtons,  // Index [3]
    @AC_HandleReverbKnob,  // Index [4]
    @AC_HandleReverbButtons,  // Index [5]
    @AC_HandlePercKnob,  // Index [6]
    @AC_HandlePercButtons,  // Index [7]
    @AC_HandleVoiceChangeUpper,  // Index [8]
    @AC_HandleVoiceChangeLower,  // Index [9]
    @AC_HandleVoiceChangePedal,  // Index [10]
    @AC_SendTaper,  // Index [11]
    @AC_WaveBlocksToFPGA,  // Index [12]
    @AC_SendTuningVals,  // Index [13]
    @AC_SendGating,  // Index [14]
    @AC_OrganParamsToFPGA,  // Index [15]
    @AC_SendPercValues,  // Index [16]
    @AC_SendInserts,  // Index [17]
    @AC_SendPHRprgm,  // Index [18]
    @AC_PhasingRotorToFPGA,  // Index [19]
    @AC_SendLeslieLiveParams,  // Index [20]
    @AC_SendRotarySpeed,  // Index [21]
    @AC_SendGM2ena,  // Index [22]
    @AC_SendGMlowerLvl,  // Index [23]
    @AC_SendGMpedalLvl,  // Index [24]
    @AC_SendGMupperLvl,  // Index [25]
    @AC_SendGMvoiceLower0,  // Index [26]
    @AC_SendGMvoiceLower1,  // Index [27]
    @AC_SendGMvoicePedal0,  // Index [28]
    @AC_SendGMvoicePedal1,  // Index [29]
    @AC_SendGMvoiceUpper0,  // Index [30]
    @AC_SendGMvoiceUpper1,  // Index [31]
    @AC_SendMIDIccSet,  // Index [32]
    @AC_SplitConfigToFPGA,  // Index [33]
    @AC_VibratoToFPGA,  // Index [34]
    @AC_SendReverb,  // Index [35]
    @AC_SetDetent,  // Index [36]
    @AC_SendTrimPots,  // Index [37]
    @AC_SendVolumes,  // Index [38]
    @AC_SendUpperDBs,  // Index [39]
    @AC_SendLowerDBs,  // Index [40]
    @AC_SendConvertedPedalDBs,  // Index [41]
    @AC_SendPedalDBs,  // Index [42]
    @AC_SendMasterVolume,  // Index [43]
    @AC_SetLEDdimmer,  // Index [44]
    @AC_RouteDirect,  // Index [45]
    @nil   // Index [46]
  );

// Konstanten für ac_proclist_flags-Index
const
  c_AC_HandleGatingknob: Byte = 0;
  c_AC_HandleGatingButtons: Byte = 1;
  c_AC_HandleVibknob: Byte = 2;
  c_AC_HandleVibButtons: Byte = 3;
  c_AC_HandleReverbKnob: Byte = 4;
  c_AC_HandleReverbButtons: Byte = 5;
  c_AC_HandlePercKnob: Byte = 6;
  c_AC_HandlePercButtons: Byte = 7;
  c_AC_HandleVoiceChangeUpper: Byte = 8;
  c_AC_HandleVoiceChangeLower: Byte = 9;
  c_AC_HandleVoiceChangePedal: Byte = 10;
  c_AC_SendTaper: Byte = 11;
  c_AC_WaveBlocksToFPGA: Byte = 12;
  c_AC_SendTuningVals: Byte = 13;
  c_AC_SendGating: Byte = 14;
  c_AC_OrganParamsToFPGA: Byte = 15;
  c_AC_SendPercValues: Byte = 16;
  c_AC_SendInserts: Byte = 17;
  c_AC_SendPHRprgm: Byte = 18;
  c_AC_PhasingRotorToFPGA: Byte = 19;
  c_AC_SendLeslieLiveParams: Byte = 20;
  c_AC_SendRotarySpeed: Byte = 21;
  c_AC_SendGM2ena: Byte = 22;
  c_AC_SendGMlowerLvl: Byte = 23;
  c_AC_SendGMpedalLvl: Byte = 24;
  c_AC_SendGMupperLvl: Byte = 25;
  c_AC_SendGMvoiceLower0: Byte = 26;
  c_AC_SendGMvoiceLower1: Byte = 27;
  c_AC_SendGMvoicePedal0: Byte = 28;
  c_AC_SendGMvoicePedal1: Byte = 29;
  c_AC_SendGMvoiceUpper0: Byte = 30;
  c_AC_SendGMvoiceUpper1: Byte = 31;
  c_AC_SendMIDIccSet: Byte = 32;
  c_AC_SplitConfigToFPGA: Byte = 33;
  c_AC_VibratoToFPGA: Byte = 34;
  c_AC_SendReverb: Byte = 35;
  c_AC_SetDetent: Byte = 36;
  c_AC_SendTrimPots: Byte = 37;
  c_AC_SendVolumes: Byte = 38;
  c_AC_SendUpperDBs: Byte = 39;
  c_AC_SendLowerDBs: Byte = 40;
  c_AC_SendConvertedPedalDBs: Byte = 41;
  c_AC_SendPedalDBs: Byte = 42;
  c_AC_SendMasterVolume: Byte = 43;
  c_AC_SetLEDdimmer: Byte = 44;
  c_AC_RouteDirect: Byte = 45;
  c_nil: Byte = 46;

  c_nil_proc: Byte = c_nil;

var
  ac_temp_GeneratorGroup: Array[0..15] of byte;
  ac_temp_KeyboardGroup: Array[0..15] of byte;
  ac_temp_VibratoGroup: Array[0..15] of byte;
  //ac_collect_action_array:Array[0..ord(ta_last_entry)] of boolean;

  ac_preset_changed: Boolean;
  idx_w, temp_w: Word;

  ac_mb_inc, ac_mb_dec,
  ac_mb_v1, ac_mb_v2: Boolean; // temp values for Inc/Dec Buttons
  ac_proc_eventsource: Byte; // für jeweils aufgerufene Proc gültig
  ac_proclist_flags: Array[0..c_proc_max] of Boolean;
  ac_swell_integrator_w, ac_volume_integrator_w: Word;
  ac_swell_w, ac_volume_w: Word;
  ac_swell_w_old, ac_volume_w_old: Word;

// #############################################################################
// #####                      Hilfsroutinen                               ######
// #############################################################################

procedure AC_SendPresetName;
begin
  edit_TempStr:= CurrentPresetName;
  case ConnectMode of
    t_connect_editor_midi:
      MIDI_SendSysExParamList(1000 + c_PresetNameStrArr, 16); // Namen senden
      |
    t_connect_editor_serial, t_connect_osc_wifi:
      NB_SendBinaryBlock(1000 + c_PresetNameStrArr, 16);
      |
  else
  endcase;
  FillBlock(@edit_TempStr, 16, 0);
end;


procedure AC_sendmsg(idx: Word; const event_source: byte);
// Event-Sender: Sorgt dafür, dass Änderungen nicht an den Absender zurückgehen
// idx muss zwischen 0 und 511 liegen!
var param: Integer;
  my_menu_requ, hammond_db_val: Byte; new_val: Byte;
begin
  if idx > 495 then
    return;
  endif;
  param:= Integer(idx) + 1000;
  new_val:= edit_array[idx];
  my_menu_requ:= Param2MenuInverseArray[idx];
  case event_source of
    // c_to_fpga_event_source: nur ans FPGA, interne Änderung
    // c_midi_sysex_source: SysEx-Events kommen immer vom Editor
    c_editor_event_source:
      // Durch Editor oder TouchOSC verursachte Events
      case ConnectMode of
        t_connect_osc_wifi:
          NB_SendBinaryVal(param, new_val); // OSC braucht das Event zurück
          mdelay(5);
          |
      endcase;
      |
    c_preset_event_source, c_control_event_source,
    c_menu_event_source:
      // Durch Bedienung verursachte Events
      case ConnectMode of
        t_connect_midi:
          // speziell für XB3-Einbau:
          if edit_MIDI_CC_Set = 1 then
            case idx of
            0..8:
              n:= lo(idx);
              hammond_db_val:= (n * 9) + (new_val div 15);
              idx:= 208;
              MIDI_SendIndexedController(idx, hammond_db_val);
              |
            16..24:
              n:= lo(idx) - 16;
              hammond_db_val:= (n * 9) + (new_val div 15);
              idx:= 209;
              MIDI_SendIndexedController(idx, hammond_db_val);
              |
            264:
              n:= (edit_VibKnob div 2) * $20 + $20;
              idx:= 211;
              MIDI_SendIndexedController(idx, n);
              if Bit(edit_VibKnob, 0) then
                n:= 127;
              else
                n:= 0;
              endif;
              idx:= 215;
              MIDI_SendIndexedController(idx, n);
              |
            else
              MIDI_SendIndexedController(idx, new_val);
            endcase;
          else
            MIDI_SendIndexedController(idx, new_val);
          endif;
          |
        t_connect_editor_serial:
          NB_SendBinaryVal(param, new_val);
          MIDI_SendIndexedController(idx, new_val);
          |
{$IFNDEF MODULE}
        t_connect_osc_midi:
          MIDI_SendIndexedController(idx, new_val);
          |
        t_connect_editor_midi:
          MIDI_SendSysExParam(param, Integer(new_val));
          mdelay(5);
          |
        t_connect_osc_wifi:
          NB_SendBinaryVal(param, new_val);
          mdelay(5);
          |
{$ENDIF}
      endcase;
      |
    c_midi_event_source:
      // über MIDI-CCs verursachte Events
      case ConnectMode of
        t_connect_editor_midi:
          MIDI_SendSysExParam(param, Integer(new_val));
          |
{$IFNDEF MODULE}
        t_connect_editor_serial, t_connect_osc_wifi:
          NB_SendBinaryVal(param, new_val);
          |
{$ENDIF}
      else
        MenuIndex_SplashIfEnabled:= my_menu_requ;
      endcase;
      |
  endcase;
  if event_source > c_board_event_source then
    MenuRefresh:= true;
  endif;
end;

// -----------------------------------------------------------------------------

function ac_detent_shift(my_val, detent_shift: Byte): Byte;
var diff_i, val_i: Integer;
begin
{$IFNDEF MODULE}
  // bei Equalizer und Percussion Volume von Mittelwert ausgehen
  // Detent-Shift-Wert aus EEPROM bzw. edit_table
  val_i:= Integer(my_val);
  diff_i:= Integer(detent_shift);
  diff_i:= diff_i - 64;
  if my_val < 64 then
    // unterhalb Mittelstellung, n < 64
    val_i:= val_i + (val_i * diff_i div 64);
  else
    // oberhalb Mittelstellung, n >= 64, läuft von 64 bis 127
    val_i:= val_i + ((127 - val_i) * diff_i div 64);
  endif;
  {$IFDEF DEBUG_AC}
    Write(Serout, ' DetentShift: ' + byteToStr(my_val));
    Writeln(Serout, ', Shift to: ' + byteToStr(lo(val_i)));
  {$ENDIF}
  return(lo(val_i));
{$ELSE}
  return(my_val);
{$ENDIF}
end;

// #############################################################################
// #############################################################################
// #####         Interface für Prozeduraufruf über Tabelle                ######
// #############################################################################
// #############################################################################

procedure AC_SetLEDdimmer;
begin
  NB_SetLEDdimmer;
end;

// Parameteränderungen in edit_table rufen eine zugehörige Routine
// in der Tabelle ac_edit_procs auf


procedure AC_SendGating;
begin
  FH_OrganParamsToFPGA;
  AC_SendPercValues;   // auch DBs, wg. EG und Percussion
  FH_LowerDrawbarsToFPGA;
  AC_SendVolumes;  // wg. Pedal to Lower Vib
end;

procedure AC_OrganParamsToFPGA;  // Index [37]
begin
  FH_OrganParamsToFPGA;
end;

procedure AC_PhasingRotorToFPGA;  // Index [38]
begin
  FH_PhasingRotorToFPGA;
end;

procedure AC_SplitConfigToFPGA;  // Index [40]
begin
  FH_SplitConfigToFPGA;
end;

procedure AC_WaveBlocksToFPGA;  // Index [42]
begin
  FH_WaveBlocksToFPGA;
end;

procedure AC_SendUpperDBs;
begin
  ac_proclist_flags[c_AC_SendUpperDBs]:= false;
  FH_UpperDrawbarsToFPGA;
  if (MenuIndex = 1) then
    MenuRefresh:= true;
  endif;
end;

procedure AC_SendLowerDBs;
begin
  ac_proclist_flags[c_AC_SendLowerDBs]:= false;
  FH_LowerDrawbarsToFPGA;
  if (MenuIndex = 2) then
    MenuRefresh:= true;
  endif;
end;

procedure AC_SendPedalDBs;
begin
  ac_proclist_flags[c_AC_SendPedalDBs]:= false;
  FH_PedalDrawbarsToFPGA;
  if (MenuIndex = 3) then
    MenuRefresh:= true;
  endif;
end;

procedure AC_SendConvertedPedalDBs;
begin
  ac_proclist_flags[c_AC_SendConvertedPedalDBs]:= false;
  AC_SendPedalDBs;
end;

// -----------------------------------------------------------------------------

procedure AC_RouteDirect; // nur für Modul benötigt
begin
  ac_proclist_flags[c_AC_RouteDirect]:= false;
  FH_UpperRoutingToFPGA;
  FH_UpperDrawbarsToFPGA;
  FH_PercussionParamsToFPGA; // Perc-Bits könnten sich geändert haben
  FH_LowerDrawbarsToFPGA;
end;

procedure AC_RouteOrgan;
begin
  {$IFDEF DEBUG_AC}
    writeln(serout, '/ AC Organ Params');
  {$ENDIF}
  ac_proclist_flags[c_AC_OrganParamsToFPGA]:= false;
  FH_OrganParamsToFPGA;
  FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
end;

procedure AC_SendTaper;  // Zeitaufwendig!
begin
  ac_proclist_flags[c_AC_SendTaper]:= false;
  FH_KeymapToFPGA;
  FH_TaperingToFPGA(edit_TG_TaperCaps);
  FH_NoteHighpassFilterToFPGA;
end;

procedure AC_SendTuningVals;
begin
  FH_TuningValsToFPGA;
end;

procedure AC_VibratoToFPGA;
begin
  FH_VibratoToFPGA;
end;

procedure AC_HandleVibknob;
var edit_idx: Integer;
begin
  NB_VibknobToVCbits;
  FH_VibratoToFPGA;
end;

procedure AC_HandleVibButtons;  // Index [3]
// bereits in AC_MomentaryControls erledigt
begin
end;

// -----------------------------------------------------------------------------

procedure AC_HandleReverbKnob;
// Übersetzung in Buttons bereits in AC_MomentaryControls erledigt
begin
  ac_proclist_flags[c_AC_HandleReverbKnob]:= false;
  FH_SendReverbTabs;
end;


procedure AC_HandleReverbButtons;
begin
  FH_SendReverbTabs;
end;

procedure AC_SendReverb;
begin
  FH_SendReverbTabs;
end;

// -----------------------------------------------------------------------------

procedure AC_HandlePercKnob;
var edit_idx: Word;
begin
  for edit_idx:= 128 to 131 do
    AC_sendmsg(edit_idx, c_control_event_source);     // zusätzlich senden
  endfor;
  AC_SendPercValues;
end;

procedure AC_HandlePercButtons;  // Index [7]
begin
  AC_SendPercValues;
  FH_PercOnOff;
end;

procedure AC_SendPercOnOff;
begin
  // Percussion, EG/H100 Modus, Tastenkontakt-Umschaltung
  FH_PercOnOff;
end;

procedure AC_SendPercValues;
begin
  {$IFDEF DEBUG_AC}
    writeln(serout, '/ AC PercLvlTime');
  {$ENDIF}
  // Percussion, EG/H100 Modus, Tastenkontakt-Umschaltung
  FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
  FH_PercussionParamsToFPGA;
  FH_UpperDrawbarsToFPGA;   // wg. EG und Percussion
end;

procedure AC_HandleGatingknob;
begin
  {$IFDEF DEBUG_AC}
    writeln(serout, '/ AC Gating/Upr/Lwr');
  {$ENDIF}
  ac_proclist_flags[c_AC_SendGating]:= false;
  // Percussion, EG/H100 Modus, Tastenkontakt-Umschaltung
  FH_OrganParamsToFPGA;
  AC_SendPercValues;   // auch DBs, wg. EG und Percussion
  FH_LowerDrawbarsToFPGA;
  AC_SendVolumes;  // wg. Pedal to Lower Vib
end;

procedure AC_HandleGatingButtons;  // Index [1]
begin
end;

procedure AC_SendInserts;
begin
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Inserts');
{$ENDIF}
  ac_proclist_flags[c_AC_SendInserts]:= false;
  FH_InsertsToFPGA;
  AC_SendVolumes;
end;

procedure AC_SendRotarySpeed;
var my_bool: Boolean;
begin
{$IFNDEF MODULE}
  // ac_proclist_flags[c_AC_SendRotarySpeed]:= false;
  my_bool:= edit_LogicalTab_LeslieFast and edit_LogicalTab_LeslieRun;
  VKPORT_LESFAST:= my_bool; // Leslie 11pin, vom I2C Vibrato-Knob-Port
  PREAMP_LESFAST:= my_bool; // an PL29 PREAMP CTRL
  my_bool:= edit_LogicalTab_LeslieRun and (not edit_LogicalTab_LeslieFast);
  VKPORT_LESRUN:= my_bool; // Leslie 11pin, vom I2C Vibrato-Knob-Port
  PREAMP_LESRUN:= my_bool; // an PL29 PREAMP CTRL;
  MIDI_SendVent;
{$ENDIF}
end;

// -----------------------------------------------------------------------------

procedure AC_SendMIDIccSet;

begin
  ac_proclist_flags[c_AC_SendMIDIccSet]:= false;
  NB_CCarrayFromDF(edit_MIDI_CC_Set);   // setzt UseSustainSostMask
  MIDI_SendSustainSostEnable;
end;

// -----------------------------------------------------------------------------

procedure AC_SetDetent;
begin
// Mittelpositions-Default geändert, nach zugehörigem ADC suchen
  ac_proclist_flags[c_AC_SetDetent]:= false;
{$IFNDEF MODULE}
  for i:= 0 to 87 do
    n:= ADC_remaps[i];
    if n in [85, 112, 115, 118] then
      ADC_changed[i]:= true;
    endif;
  endfor;
{$ENDIF}
  AC_SendTrimPots;
  AC_SendVolumes;
end;

// -----------------------------------------------------------------------------

procedure AC_SendGM2ena;
begin
  {$IFDEF DEBUG_AC}
  writeln(serout, '/ AC GM Volume');
  {$ENDIF}
  ac_proclist_flags[c_AC_SendGM2ena]:= false;
  m:= (edit_LocalEnable shl 4) or edit_MIDI_Channel;
  MIDI_SendNRPN($357F, m); // Kanal und Freigabe für SAM5504
  AC_SendVolumes;
  ToneChanged:=true;
end;

procedure AC_SendGMprgRequestDisplay(idx: Integer; const gm_prg: Byte);
// GM-Programm senden und Namen anfordern, kommt später über SysEx vom DSP
begin
  // Programm setzen
  MIDI_SendNRPN($3550 + idx, gm_prg);
  // Namen anfordern, wird über SysEx in GM_VoiceNames[] gesetzt
  MIDI_SendNRPN($3570 + idx, 127);
  if not ac_preset_changed then
    GM_VoiceNameToDisplaySema[idx]:= GM_VoiceNameToDisplaySema[idx]
       or (ConnectMode in[t_connect_osc_midi, t_connect_osc_wifi]);
  endif;
end;

procedure AC_SendGMvoiceUpper0;
begin
  AC_SendGMprgRequestDisplay(0, edit_UpperGMprg_0);
end;

procedure AC_SendGMvoiceUpper1;
begin
  AC_SendGMprgRequestDisplay(4, edit_UpperGMprg_1);
end;

procedure AC_SendGMupperLvl;
begin
  ac_proclist_flags[c_AC_SendGMupperLvl]:= false;
  // layer 1:
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
end;

// -----------------------------------------------------------------------------

procedure AC_SendGMvoiceLower0;
begin
  AC_SendGMprgRequestDisplay(1, edit_LowerGMprg_0);
end;

procedure AC_SendGMvoiceLower1;
begin
  AC_SendGMprgRequestDisplay(5, edit_LowerGMprg_1);
end;

procedure AC_SendGMlowerLvl;
begin
  ac_proclist_flags[c_AC_SendGMlowerLvl]:= false;
  // layer 1:
  MIDI_SendNRPN($3531, edit_LowerGMharm_0);
  MIDI_SendNRPN($3561, edit_LowerGMlvl_0);
  // layer 2:
  if HasExtendedLicence then
    MIDI_SendNRPN($3525, edit_LowerGMdetune_1 + 57);
    MIDI_SendNRPN($3535, edit_LowerGMharm_1);
    MIDI_SendNRPN($3565, edit_LowerGMlvl_1);
  else
    MIDI_SendNRPN($3565, 0);  //  edit_LowerGMlvl_1
  endif;
end;

// -----------------------------------------------------------------------------

procedure AC_SendGMvoicePedal0;
begin
  AC_SendGMprgRequestDisplay(2, edit_PedalGMprg_0);
end;

procedure AC_SendGMvoicePedal1;
begin
  AC_SendGMprgRequestDisplay(6, edit_PedalGMprg_1);
end;

procedure AC_SendGMpedalLvl;
begin
  ac_proclist_flags[c_AC_SendGMpedalLvl]:= false;
  // layer 1:
  MIDI_SendNRPN($3532, edit_PedalGMharm_0);
  MIDI_SendNRPN($3562, edit_PedalGMlvl_0);
  // layer 2:
  if HasExtendedLicence then
    MIDI_SendNRPN($3526, edit_PedalGMdetune_1 + 57);
    MIDI_SendNRPN($3536, edit_PedalGMharm_1);
    MIDI_SendNRPN($3566, edit_PedalGMlvl_1);
  else
    MIDI_SendNRPN($3566, 0);  //  edit_PedalGMlvl_1
  endif;
end;


// #############################################################################
// ####                         POTENTIOMETERS                              ####
// #############################################################################

procedure AC_SendVolumes;
// UPPER/LOWER/PEDAL Volumes
// wird bei Änderungen aufgerufen
// Rechnet Byte "volume" in EQ-Paramater um
begin
{$IFDEF DEBUG_AC}
  Writeln(Serout, '/ AC SendVolumes');
{$ENDIF}
  ac_proclist_flags[c_AC_SendVolumes]:= false;
  SendByteToFPGA(edit_LeslieInpLvl, 180); // Leslie Input Level

  if edit_LogicalTab_TubeAmpBypass then
    SendByteToFPGA(0, 70);    // Amp Out Level
  else
    // Amp122 auf 35..127 begrenzen
    // SendVolumeByteToFPGA(amp_gain, 176);     // ALT, auf 0..255
    m:= muldivbyte(edit_LeslieVolume, 100, 127) + 27; // 32..127
    // NEU ab FPGA 01032022
    SendVolumeByteToFPGA(m, 69);  // Amp In Gain in Volume-Gruppe, auf 0..255
    if Bit(edit_ConfBits, 2) then // Volume Correction bit gesetzt?
      // für Amp Out Lvl
      m:= 240 - (ValueTrimLimit(edit_LeslieVolume, 0, 33) * 4)
              - (edit_LeslieVolume div 5);
    else
      // nur geringe Korrektur für Leslie-Sim
      m:= 230 - (edit_LeslieVolume div 3);
    endif;
    SendByteToFPGA(m, 70);    // Amp Out Level, in Volume-Gruppe, auf 0..255
  endif;
  AC_SendMasterVolume;

  m:= (edit_GM2synthVolume shr 2) + 96;
  MIDI_SendNRPN($3509, m); // SAM55004 GM2 Pre-Mix Gain
  MIDI_SendNRPN($3512, 127);                 // SAM55004 GM2 Master Volume

  m:= ac_detent_shift(edit_UpperVolumeDry, edit_PercVolDetentShift);
  if edit_EnableUpperAudio then
    SendScaledByteToFPGA(edit_UpperVolumeWet, 34, 150);   // 34 = Upper Manual Vol auf 0..200
    SendScaledByteToFPGA(m, 37, 150);   // 37 = Perc/lvl_2nd_voice Vol auf 0..200
  else
    SendByteToFPGA(0, 34);   // 34 = Upper Manual Vol auf 0
    SendByteToFPGA(0, 37);   // 37 = Perc/lvl_2nd_voice Vol auf 0
  endif;
  if edit_EnableLowerAudio then
    SendScaledByteToFPGA(edit_LowerVolume, 35, 150);  // 35 = Lower Manual Vol auf 0..200
  else
    SendByteToFPGA(0, 35);   // 35 = Lower Manual Vol auf 0
  endif;

  // Pedal Enable in AC_SendSwell!

  SendByteToFPGA(edit_LocalEnable xor 7, 14);   // ScanCore SPI Local Disables

  if edit_PreampSwellType = 0 then // Hammond, mit TRIODE K2 AGE-Pot
    SendByteToFPGA(255-edit_Triode_k2, 85);  // 85 = TRIODE_K2  255..155
  else
    SendByteToFPGA(255, 85);  // kein k2
  endif;
  ToneChanged:= true;  // sende SWELL
end;

// -----------------------------------------------------------------------------

procedure AC_SendTrimPots;
// UPPER/LOWER/PEDAL Volumes
// wird bei Änderungen aufgerufen
// Rechnet Byte "volume" in EQ-Paramater um
var temp_vol: Byte;
begin
  ac_proclist_flags[c_AC_SendTrimPots]:= false;
// *****************************************************************************
{$IFNDEF MODULE}
// **************************** ALLINONE****************************************
  // DREAM FX5000 Biquads
  // Mid ist immer Typ 1 = parametrisch Peak
  // bei Änderungen wird EQ in SAM-FW neu initialisiert
  MIDI_SendNRPN($351D, byte(edit_EqualizerFullParametric)); // SAM5504 EQU Bass/Treble Type

{$IFDEF DEBUG_AC}
  Write(Serout, '/ AC Bass EQ');
{$ENDIF}
  temp_vol:= ac_detent_shift(edit_EqualizerBass, edit_EquBassDetentShift);
  MIDI_SendNRPN($3514, temp_vol);      // SAM5504 EQU 1
  // Bass EQ 0 = 32 Hz, 64 = 544 Hz, 127 = 2048 Hz
  MIDI_SendNRPN($3515, edit_EqualizerBassFreq);  // SAM5504 Bass EQU Mittenfrequenz

{$IFDEF DEBUG_AC}
  Write(Serout, '/ AC Mid EQ');
{$ENDIF}
  temp_vol:= ac_detent_shift(edit_EqualizerMid, edit_EquMidDetentShift);
  MIDI_SendNRPN($3517, temp_vol);       // SAM5504 EQU 2
  // Mid EQ 0= 127 Hz, 64=1150 Hz, 127=4200 Hz
  MIDI_SendNRPN($3518, edit_EqualizerMidFreq);   // SAM5504 Mid EQU Mittenfrequenz
  MIDI_SendNRPN($3519, edit_EqualizerMidPeak shr 1);   // SAM5504 Mid EQU Damp/Q

{$IFDEF DEBUG_AC}
  Write(Serout, '/ AC Treble EQ');
{$ENDIF}
  temp_vol:= ac_detent_shift(edit_EqualizerTreble, edit_EquTrebleDetentShift);
  MIDI_SendNRPN($351A, temp_vol);      // SAM5504 EQU 3
  // Treble EQ 0 = 500 Hz, 64 = 2550 Hz, 127 = 8500 Hz
  MIDI_SendNRPN($351B, edit_EqualizerTrebleFreq);  // SAM5504 Treble EQU Mittenfrequenz

  if edit_EqualizerFullParametric then
    MIDI_SendNRPN($3516, edit_EqualizerBassPeak shr 1);    // SAM5504 Bass EQU Damp/Q
    MIDI_SendNRPN($351C, edit_EqualizerTreblePeak shr 1);  // SAM5504 Treble EQU Damp/Q
  endif;
// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************

  FH_TubeCurveToFPGA(edit_TubeAmpCurveA, edit_TubeAmpCurveB);
end;

// #############################################################################
// ###                    Master Volume setzen und an DSP                    ###
// #############################################################################

procedure AC_SendMasterVolume;
begin
  // Integrator nach Logarithmierung!
  MIDI_SendNRPN($3510, edit_MasterVolume);   // SAM55004 GM2 General Master Volume
  m:= muldivbyte(edit_MasterVolume, edit_GM2organVolume, 127);
  ac_volume_w:= word(c_DrawbarLogTable[m]) * 2; // neuer Wert, 0..254
end;

// #############################################################################
// ###                  Schweller und Volume an FPGA senden                  ###
// #############################################################################


procedure AC_SendSwell;
// SCHWELLPEDAL- und MASTER-VOLUME-Steuerung
// Wird alle 2ms aus main_tasks aufgerufen wg. Integratoren
const
  // Scale * int_fac < 256, sonst Word-Überlauf!
  int_fac_swell: Word = 7;
  int_div_swell: Word = int_fac_swell + 1;
  int_shift_swell: Byte = 4;  // Scale = 16 bei 4 shifts
  int_fac_volume: Word = 15;
  int_div_volume: Word = int_fac_volume + 1;
  int_shift_volume: Byte = 3;  // Scale = 8 bei 3 shifts

var swell_raw255,
    swell_ranged,
    swell_63hz,
    swell_midrange,
    swell_bypass,   // nur halber Audio-Pegel in AO28 NEU!
    swell_fullrange,   // nur halber Audio-Pegel in AO28 NEU!
    swell_pedal,
    swell_final: Byte;
    swell_changed: Boolean;
begin
  // Volume Integrator, t = 2ms
  ac_volume_integrator_w:= ((ac_volume_integrator_w * int_fac_volume)
                          + (ac_volume_w shl int_shift_volume)) div int_div_volume;
  temp_w:= ac_volume_integrator_w shr int_shift_volume;
  if temp_w <> ac_volume_w_old then
    ac_volume_w_old:= temp_w;
    // 72 = Master Vol, 0..1016 div 4 = 0..255
    SendWordToFPGA(temp_w, 72);
  endif;

  if SwellPedalControlledByMIDI then
    // result:= ((oldVal * fact) + newVal) div (fact + 1);
    ac_swell_w:= word(MIDI_swell128 shl 1);  // *2, 0..254
  else
    ac_swell_w:= Word(SwellPedalADC); // ist schon im Bereich 0..255
  endif;

  // Swell Integrator, t = 2ms
  ac_swell_integrator_w:= ((ac_swell_integrator_w * int_fac_swell)
                         + (ac_swell_w shl int_shift_swell)) div int_div_swell;
  temp_w:= ac_swell_integrator_w shr int_shift_swell;
  swell_changed:= temp_w <> ac_swell_w_old;
  if swell_changed then
    ac_swell_w_old:= temp_w;
    if not SwellPedalControlledByMIDI then
      MIDI_NewSwellVal:= lo(ac_swell_w_old) shr 1;
    endif;
  endif;
  swell_raw255:= lo(ac_swell_w_old);

  swell_final:= 128 + edit_TrimSwell;
  if swell_changed or ToneChanged then
    case edit_PreampSwellType of
    0:
      // Hammond Mode, ausgeprägtes, aber flaches Maximum bei 200 Hz,
      // ab 250 Hz mit 3-4 db/Okt fallend, über 4 kHz stärker
      // TONE-Pot, Minimal Swell und Swell Trim Cap werden berücksichtigt
      // Maximalwert auf Trim Cap Swell anpassen
      // Range auf Minimal Swell anpassen
      // n:= MulDivByte(64 + edit_TrimSwell, swell_raw255, 195);  // zu laut
      n:= MulDivByte(48 + edit_TrimSwell, swell_raw255, 230);
      swell_ranged:= edit_MinimalSwell + MulDivByte(n, 255-edit_MinimalSwell, 255);

      n:= MulDivByte(edit_TonePot, swell_ranged, 190);
      swell_fullrange:= (swell_ranged div 3) + n; // 0..63
      swell_63hz:= 80 + (swell_ranged div 2); //

      swell_midrange:= swell_ranged;

      // Finales Lowpass-Filter 6db/Okt.
      // Frequenzen ermittelt mit IIR_Filter_Coef_Generator.xls
      // Bit 7 = 0, Hammond Mode, 4khz-Bereich um 12 dB abgesenkt
      // Frequenz 120,3 Hz * (Wert + 1) nom. 40 für 4800 Hz
      n:= (edit_TonePot div 4) + 6;   // (edit_TonePot div 3) + 10;
      SendByteToFPGA(n, 87);  // 10..42, ca. 4,5 kHz Grenzfrequenz

      // Filter Bypass, full range ohne Tone-Lowpass
      swell_bypass:= 0;

      swell_pedal:= 35 + MulDivByte(swell_ranged, 220, 255);
      // writeln(serout,'/ 1k:' + bytetostr(swell_bypass) + ' 4k: ' + bytetostr(swell_fullrange));
      |

    1:  // Conn, Böhm etc. Sinus
      swell_63hz:= MulDivByte(swell_raw255, 150, 255);
      swell_midrange:= MulDivByte(swell_raw255, 165, 255);
      swell_bypass:= MulDivByte(swell_raw255, 120, 255); // - 12 dB in Preamp
      // in AO28-Sim ist dieser Pegel nur um -6 dB abgesenkt, wenn Linear Mode ON
      swell_fullrange:= MulDivByte(swell_raw255, 140, 255); // - 6 dB in Preamp

      // Finales Lowpass-Filter 6db/Okt.
      // Frequenzen ermittelt mit IIR_Filter_Coef_Generator.xls
      // Bit 7 = 1, 4khz-Bereich nur um 6 dB abgesenkt
      // Frequenz 120,3 Hz * (Wert + 1) + 128 für 4k Enhanced
      SendByteToFPGA(45, 87);  // ca. 5,5 kHz Grenzfrequenz

      swell_pedal:=  swell_raw255;
      |
    else  // andere, fast linear, etwas Mid-Bass-Anhebung
      swell_63hz:= 20;
      swell_midrange:= MulDivByte(swell_raw255, 95, 255);
      swell_bypass:= MulDivByte(swell_raw255, 145, 255); // - 12 dB in Preamp
      // in AO28-Sim ist dieser Pegel nur um -6 dB abgesenkt, wenn Linear Mode ON
      swell_fullrange:= MulDivByte(swell_raw255, 190, 255); // - 6 dB in Preamp

      // Finales Lowpass-Filter 6db/Okt.
      // Frequenzen ermittelt mit IIFilter_Coef_Generator.xls
      // Bit 7 = 1, 4khz-Bereich nur um 6 dB abgesenkt
      // Frequenz 120,3 Hz * (Wert + 1) + 128 für 4k Enhanced
      SendByteToFPGA(128 + 47, 87);  // ca. 6 kHz Grenzfrequenz

      swell_pedal:= swell_raw255;
    endcase;

    if edit_EnablePedalAudio then
      if edit_LogicalTab_PedalPostMix then  // Pedal Bypass Tab
        // bei Pedal Bypass wird direkt auf Ausgang gemischt
        SendByteToFPGA(0, 45);  // Pedal to Lower Vib
        SendByteToFPGA(0, 46);  // Pedal to AO28
      else
        // normales Pedal Routing mit oder ohne Lower Vibrato
        if Bit(edit_ConfBits, 4) and (edit_GatingKnob = 0) then
          // Pedal an Vibrato Lower
          SendScaledByteToFPGA(edit_PedalVolume, 45, 190);  // Pedal an Lower Vib
          SendByteToFPGA(0, 46); // nichts an AO28
        else
          // Pedal Dry an AO28
          SendByteToFPGA(0, 45); // nichts an Lower Vib
          SendDoubledByteToFPGA(edit_PedalVolume, 46);  // Pedal an AO28
        endif;
      endif;
      // Pedal-Signal für separaten Ausgang auf Extension Board und Postmix:
      swell_pedal:= mulDivByte(swell_pedal, edit_PedalVolume, 128);
      if Bit(edit_ConfBits, 6) then
        // Swell disable für separaten Ausgang auf Extension Board und Postmix
        swell_pedal:=   mulDivByte(edit_PedalVolume, 150, 100) // 0..191
                         + (swell_pedal div 4); // geringer Anteil Swell
      endif;
      SendByteToFPGA(swell_pedal, 47); // Pedal to Ext. Output & Postmix
    else
      SendByteToFPGA(0, 45);   // Pedal Vol auf 0
      SendByteToFPGA(0, 46);   // Pedal Vol auf 0
      SendByteToFPGA(0, 47);   // Pedal Vol auf 0
    endif;

    SendByteToFPGA(swell_63hz, 80);
    SendByteToFPGA(swell_midrange, 81);
    SendByteToFPGA(swell_bypass,  82);
    SendByteToFPGA(swell_fullrange,  83);
    SendByteToFPGA(swell_final,  84);      // final AO28 gain
    ToneChanged:= false;
  endif;
end;

// -----------------------------------------------------------------------------

procedure AC_SendLeslieLiveParams;
var my_val, my_spread_angle: Byte;
// wird bei Änderungen aufgerufen
begin
  SendByteToFPGA(edit_LeslieInpLvl, 180); // Leslie Input Level
  ac_proclist_flags[c_AC_SendLeslieLiveParams]:= false;
  my_val:= edit_LeslieInits[11];
  SendByteToFPGA(my_val, 187); // Crossmix 40..157
  my_spread_angle:= (edit_LeslieSpread shr 1) + 40;
  my_val:= edit_LeslieInits[48] + my_spread_angle;  // +0..127  MAIN
  edit_LeslieInits[49]:= my_val;
  SendByteToFPGA(my_val, 225);
  my_val:= edit_LeslieInits[50] + my_spread_angle;  // +0..127  NEAR
  edit_LeslieInits[51]:= my_val;
  SendByteToFPGA(my_val, 227);
  my_val:= edit_LeslieInits[52] + my_spread_angle;  // +0..127  FAR
  edit_LeslieInits[53]:= my_val;
  SendByteToFPGA(my_val, 229);
  my_val:= edit_LeslieInits[54] + my_spread_angle;  // +0..127  THROB
  edit_LeslieInits[55]:= my_val;
  SendByteToFPGA(my_val, 231);

  // Rotor/Horn Balance einstellen - entgegengesetzten Wert absenken
  if edit_LeslieBalance >= 64 then
    // Rotor-Pegel reduzieren
    my_val:= MulDivByte(edit_LeslieInits[6], (128-edit_LeslieBalance), 64);
    SendByteToFPGA(my_val, 182);   // skalierter Rotor-Anteil

    // Hornpegel konstant, unabhängig von Balance
    SendByteToFPGA(edit_LeslieInits[5], 181);
  else
    // Horn-Pegel reduzieren
    my_val:= MulDivByte(edit_LeslieInits[5], edit_LeslieBalance, 64);
    SendByteToFPGA(my_val, 181);

    // Rotorpegel konstant, unabhängig von Balance
    SendByteToFPGA(edit_LeslieInits[6], 182);
  endif;

  // Horn-Throb konstant, unabhängig von Balance
  my_val:= MulDivByte(edit_LeslieInits[22], edit_LeslieThrob, 128); // Throb Horn L
  SendByteToFPGA(my_val, 198);  // 0..254 auf Horn L
  SendByteToFPGA(my_val, 199);  // 0..254 auf Horn R
  // Rotor-Throb konstant, unabhängig von Balance
  my_val:= MulDivByte(edit_LeslieInits[27], edit_LeslieThrob, 128); // Throb Rotor
  SendByteToFPGA(my_val, 203);  // Rotor
end;

// #############################################################################
// ####                        DRAWBAR VOICES                               ####
// #############################################################################

procedure AC_HandleVoiceChangeUpper;
var was_live: Boolean;
begin
  // Voice Change Upper Manual
  SWI_CancelActive_upr:= false; // kein Cancel mehr
  NB_CheckForLive;
  if (edit_ADCconfig >= 2) then
    // neue Umschalt-Logik in ADC_ChangesToEdit
    if UpperIsLive then
      ADC_ReadAll_24;
      ADC_ReadAll_64;
      ADC_SetChangedUpper;  // Force ADC Update
    else
      if (edit_ADCconfig = 2) then
        // wg. Umschaltung alte Preset12-MPX-Platine
        mdelay(5);
        ADC_ReadAll_24;
      endif;
      ADC_ResetTimersUpper;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
      ADC_ChangeStateAll(false);
      LoadUpperVoice(edit_UpperVoice);
    endif;
  else // Expander, keine Analogeingänge
    was_live:= (edit_UpperVoice_old = 0)
    or (edit_UpperVoice_old = edit_2ndDBselect);
    if (not UpperIsLive) then
      if was_live then
        SR_UpperLiveToTemp;  // war Live, ist jetzt Preset
      endif;
      LoadUpperVoice(edit_UpperVoice);
    elsif (not was_live) then
      SR_UpperTempToLive;    // war Preset, ist jetzt Live
    endif;
  endif;
  FH_RouteOrgan;  // wg. Percussion-Freigabe
  MIDI_SendProgramChange(0, edit_UpperVoice);
  AC_sendmsg(c_UpperVoice, c_preset_event_source);
  case ConnectMode of
  t_connect_editor_midi:
    MIDI_SendSysExParamList(1000, 12);
    |
  t_connect_editor_serial, t_connect_osc_wifi:
    NB_SendBinaryBlock(1000, 12);
    |
  endcase;
  if (not ac_preset_changed) then
    MenuIndex_Splash:= c_MenuCommonPreset + 1; // neues Menü anfordern
  endif;
  edit_UpperVoice_flag:= 0;
  edit_UpperVoice_old:= edit_UpperVoice;
  VoiceUpperInvalid:= false;
  CommonPresetInvalid:= true;
  midi_DisablePercussion:= false;
  FH_UpperDrawbarsToFPGA;

end;

// -----------------------------------------------------------------------------

procedure AC_HandleVoiceChangeLower;
var was_live: Boolean;
begin
  // Voice Change Lower Manual
  SWI_CancelActive_lwr:= false; // kein Cancel mehr
  NB_CheckForLive;
  if (edit_ADCconfig >= 2) then
    // neue Umschalt-Logik in ADC_ChangesToEdit
    if LowerIsLive then
      ADC_ReadAll_24;
      ADC_ReadAll_64;
      ADC_SetChangedLower;  // Force ADC Update
    else
      if (edit_ADCconfig = 2) then
        // wg. Umschaltung alte Preset12-MPX-Platine
        mdelay(5);
        ADC_ReadAll_24;
      endif;
      ADC_ResetTimersLower;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
      ADC_ChangeStateAll(false);
      LoadLowerVoice(edit_LowerVoice);
    endif;
  else // Expander, keine Analogeingänge
    was_live:= (edit_LowerVoice_old = 0)
    or (edit_LowerVoice_old = edit_2ndDBselect);
    if (not LowerIsLive) then
      if was_live then
        SR_LowerLiveToTemp;  // war Live, ist jetzt Preset
      endif;
      LoadLowerVoice(edit_LowerVoice);
    elsif (not was_live) then
      SR_LowerTempToLive;    // war Preset, ist jetzt Live
    endif;
  endif;
  MIDI_SendProgramChange(1, edit_LowerVoice);
  AC_sendmsg(c_LowerVoice, c_preset_event_source);
  case ConnectMode of
  t_connect_editor_midi:
    MIDI_SendSysExParamList(1016, 12);
    |
  t_connect_editor_serial, t_connect_osc_wifi:
    NB_SendBinaryBlock(1016, 12);
    |
  endcase;
  if (not ac_preset_changed) then
    MenuIndex_Splash:= c_MenuCommonPreset + 2; // neues Menü anfordern
  endif;
  edit_LowerVoice_flag:= 0;
  edit_LowerVoice_old:= edit_LowerVoice;
  VoiceLowerInvalid:= false;
  CommonPresetInvalid:= true;
  FH_LowerDrawbarsToFPGA;
end;

// -----------------------------------------------------------------------------

procedure AC_HandleVoiceChangePedal;
var was_live, is_live: Boolean;
begin
  // Voice Change Pedal
  is_live:= (edit_PedalVoice = 0);

  if (edit_ADCconfig >= 2) then // hat Analogeingänge
    if is_live then
      ADC_SetChangedPedal; // ADC-Kanäle invalidieren
    else
      LoadPedalVoice(edit_PedalVoice);
      ADC_ResetTimersPedal;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
      ADC_ChangeStateAll(false);
    endif;
  else
    was_live:= (edit_PedalVoice_old = 0);
    if (not is_live) then
      if was_live then
        SR_PedalLiveToTemp;  // war Live, ist jetzt Preset
      endif;
      LoadPedalVoice(edit_PedalVoice);
    elsif (not was_live) then
      SR_PedalTempToLive;    // war Preset, ist jetzt Live
    endif;
  endif;
  MIDI_SendProgramChange(2, edit_PedalVoice);
  AC_sendmsg(c_PedalVoice, c_preset_event_source);
  case ConnectMode of
  t_connect_editor_midi:
    MIDI_SendSysExParamList(1032, 12);
    MIDI_SendSysExParamList(1072, 4);
    |
  t_connect_editor_serial, t_connect_osc_wifi:
    // DB-Änderungen sofort als Block senden
    NB_SendBinaryBlock(1032, 12);
    NB_SendBinaryBlock(1072, 4);
    |
  endcase;
  if (not ac_preset_changed) then
    MenuIndex_Splash:= c_MenuCommonPreset + 3; // neues Menü anfordern
  endif;
  edit_PedalVoice_flag:= 0;
  edit_PedalVoice_old:= edit_PedalVoice;
  VoicePedalInvalid:= false;
  CommonPresetInvalid:= true;
  FH_PedalDrawbarsToFPGA;
end;

// #############################################################################

procedure AC_SendPHRprgm;
var my_phrset: byte;
begin
{$IFNDEF MODULE}
  if edit_LogicalTab_PHR_Celeste and edit_LogicalTab_PHR_Ensemble then
{$ELSE}
  // Modul, Vibrato 1
  if edit_LogicalTab_PHR_WersiBoehm and edit_LogicalTab_PHR_Ensemble then
{$ENDIF}
    my_phrset:= 6; // Vibrato 1, dünn
  elsif edit_LogicalTab_PHR_Celeste and edit_LogicalTab_PHR_Fading then
    my_phrset:= 7; // Vibrato 2, X66 etwas langsamer
  elsif edit_LogicalTab_PHR_WersiBoehm then
    my_phrset:= 2;
  elsif edit_LogicalTab_PHR_Ensemble then
    my_phrset:= 3;
  elsif edit_LogicalTab_PHR_Celeste then
    my_phrset:= 4;
  elsif edit_LogicalTab_PHR_Fading then
    my_phrset:= 5;
  else
    my_phrset:= 0;  // Keine Funktion an, WersiVoice!
  endif;
  NB_LoadPhasingSet(my_phrset); // aus EEPROM
  FH_PhasingRotorToFPGA;
end;

// #############################################################################

procedure AC_LoadOrganModel;
// Organ Model Preconfig
// TODO!
begin
{$IFNDEF MODULE}
  if not HasExtendedLicence then
    edit_OrganModel:= ValueTrimLimit(edit_OrganModel, 0, 3);
  endif;
  if (ConnectMode = t_connect_osc_midi) and (edit_OrganModel <= 2) then
    // initialisieren, weil ADS(R) nicht auf Page
    edit_PreampSwellType:= 0;
    edit_PreampSwellType_flag:= c_preset_event_source;
    edit_PedalAttack:= 0;
    edit_PedalAttack_flag:= c_preset_event_source;
    edit_PedalDecay:= 0;
    edit_PedalDecay_flag:= c_preset_event_source;
    edit_PedalSustain:= 127;
    edit_PedalSustain_flag:= c_preset_event_source;
    edit_PedalADSRharmonics:= 64;
    edit_PedalADSRharmonics_flag:= c_preset_event_source;
  endif;

  AC_sendmsg(c_OrganModel, c_preset_event_source);  //  für TouchOSC
  AC_sendmsg(c_GatingKnob, c_preset_event_source);  //  für TouchOSC
  SR_LoadOrganModel(edit_OrganModel);
{$ENDIF}
end;

procedure AC_LoadSpeakerModel;
// Speaker Model Preconfig
// TODO!
begin
{$IFNDEF MODULE}
  if not HasExtendedLicence then
    edit_SpeakerModel:= ValueTrimLimit(edit_SpeakerModel, 0, 5);
  endif;
  AC_sendmsg(c_SpeakerModel, c_preset_event_source);  //  für TouchOSC
  SR_LoadSpeakerModel(edit_SpeakerModel);
  FH_SendFIRToFPGA(edit_SpeakerModel);
  FH_SendLeslieInitsToFPGA;
  AC_SendLeslieLiveParams;
{$ENDIF}
end;

// #############################################################################

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************
procedure send_osc_colors;
// Red 0, Green 1, Blue 2, Yellow 3, Purple 4, Gray 5, Orange 6, Brown 7, Pink 8
var idx: Integer;
begin
  // für TouchOSC: Farben setzen
  if (ConnectMode = t_connect_osc_midi) then
    case edit_GatingKnob of
      2: // EG Mode
      MIDI_SendController(3, 114, 5); // Perc Drawbars gray
      MIDI_SendController(3, 113, 0); // [A]DSR rot
      |
      3: // EG Percussion Mode
      MIDI_SendController(3, 114, 2); // Perc Drawbars blau
      MIDI_SendController(3, 113, 2); // [A]DSR blau
      |
      4: // EG TimeBend Mode
      MIDI_SendController(3, 114, 3); // Perc Drawbars gelb
      MIDI_SendController(3, 113, 3); // [A]DSR gelb
      |
    else
      // Red 0, Green 1, Blue 2, Yellow 3, Purple 4, Gray 5, Orange 6, Brown 7, Pink 8
      MIDI_SendController(3, 114, 5); // Perc Drawbars gray
      MIDI_SendController(3, 113, 5); // [A]DSR gray
    endcase;
    if edit_LogicalTab_PercOn or edit_LogicalTab_EG_mask2dry then
      MIDI_SendController(3, 112, 2); // Perc Bits blau
    else
      MIDI_SendController(3, 112, 5); // Perc Bits gray
    endif;
  elsif (ConnectMode = t_connect_osc_wifi) then
    writeln(serOut); // resync
    mdelay(5);
    // Red 0, Green 1, Blue 2, Yellow 3, Purple 4, Gray 5, Orange 6, Brown 7, Pink 8
    if edit_GatingKnob >= 2 then
      for idx := 1048 to 1051 do
        write(serout, '/param/' + IntToStr(idx) + '/color=');  // ADSR Drawbars
        case edit_GatingKnob of
          2: // EG ADSR Mode
          writeln(serout, '"red"');  // ADSR Drawbars blau
          |
          3: // EG Percussion Mode
          if odd(idx) then
            writeln(serout, '"blue"');  // ADSR Drawbars blau
          else
            writeln(serout, '"gray"');  // ADSR Drawbars blau
          endif;
          |
          4: // EG TimeBend Mode
          writeln(serout, '"yellow"');  // ADSR Drawbars rot
          |
        endcase;
      endfor;
      mdelay(5);
      write(serout, '/param_mf/1096/color=');  // Perc Drawbars gray
      case edit_GatingKnob of
        3: // EG Percussion Mode
        writeln(serout, '"blue"');  // Perc Drawbars blau
        |
        4: // EG TimeBend Mode
        writeln(serout, '"yellow"');  // Perc Drawbars gelb
        |
      else
        writeln(serout, '"gray"');  // Perc Drawbars gray
      endcase;
      mdelay(5);
    endif;

    write(serout, '/param_mbh/1060/color='); // Perc Bits blau
    if edit_LogicalTab_PercOn or edit_LogicalTab_EG_mask2dry then
      writeln(serout, '"blue"'); // Perc Bits blau
    else
      writeln(serout, '"gray"'); // Perc Bits gray
    endif;
    mdelay(5);
  endif;
end;

// *****************************************************************************
{$ENDIF}
// *****************************************************************************


// #############################################################################
// #############################################################################
// ######               CHORES - regelmäßig aufgerufen                    ######
// #############################################################################
// #############################################################################

procedure ac_incDecParam(edit_idx: Word; do_inc, do_limit: boolean; event_source: byte);
// Inc Wert in edit_array wenn do_inc TRUE, sonst Dec Wert in edit_array
begin
  n:= edit_array[edit_idx];
  if do_inc then
    // Increment Buttons
    if do_limit then // Transpose ohne Limit
      inctolim(n, c_edit_max[edit_idx]);
    else
      inc(n);
    endif;
    if ac_mb_dec then  // Inc und Dec gleichzeitig
      n:= 0;
    endif;
    ac_mb_inc:= true;
  else
    // Decrement Buttons
    if do_limit then // Transpose ohne Limit
      dectolim(n, 0);
    else
      dec(n);
    endif;
    if ac_mb_inc then  // Inc und Dec gleichzeitig
      n:= 0;
    endif;
    ac_mb_dec:= true;
  endif;
  edit_array[edit_idx]:= n;
  edit_array_flag[edit_idx]:= event_source;
  MenuRefresh:= true;
end;

procedure AC_IncDecGMprogs(gm_btn_offset: byte; event_source: byte);
// Reihenfolge von NRPN $3570+x und in Tabelle:
// upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
// Reihenfolge MIDI/OSC-Befehle:
// Dec/Inc upper_0   0,0 (Index auf GM_VoiceNames)
// Dec/Inc upper_1   4,4
// Dec/Inc lower_0   1,1
// Dec/Inc lower_1   5,5
// Dec/Inc pedal_0   2,2
// Dec/Inc pedal_1   6,6
begin
  // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
  m:= c_midi_osc_order_to_edit_gmvoice[gm_btn_offset div 2];
  n:= edit_GMprogs[m];
  if odd(gm_btn_offset) then
    // Increment Buttons
    inctolim(n, 126);
    if ac_mb_dec then  // Inc und Dec gleichzeitig
      n:= 0;
    endif;
    ac_mb_inc:= true;
  else
    dectolim(n, 0);
    if ac_mb_inc then  // Inc und Dec gleichzeitig
      n:= 0;
    endif;
    ac_mb_dec:= true;
  endif;
  edit_GMprogs[m]:= n;
  edit_GMprogs_flag[m]:= event_source;
  setsystimer(TimeoutTimer, 75);
  MenuRefresh:= true;
end;

// #############################################################################

procedure AC_IncDecControls;
// wird aus MainTasks aufgerufen
// Up/Down-Buttons (Momentary) behandeln
// Button-LEDs werden erst nach Ablauf von ActivityTimer zurückgesetzt.
// Dadurch ist es möglich, gleichzeitige Betätigung mehrerer Buttons
// zu erkennen.
// Hier: Beide Transpose-Buttons zugleich setzen Transponierwert auf 0 zurück.
var
  event_source, my_idx: Byte;
  edit_idx: Word;
begin
  // Inc/Dec Presets, Models, Transpose
  for my_idx:= 0 to c_incdec_lastbtn do  // alle IncDec-Buttons #1192..#1207
    event_source:= edit_LogicalTab_IncDecBtns_flag[my_idx];
    if event_source <> 0 then
      // Zielparameter aus Tabelle c_incdec2edit_idx
      edit_idx:= c_incdec2edit_idx[my_idx div 2];
      // Inkrementieren wenn event_idx ungerade ist
      AC_IncDecParam(edit_idx, odd(my_idx), edit_idx <> c_pidx_transpose, event_source);
      SetSystimer(TimeoutTimer, 75);
    endif;
  endfor;
  FillBlock(@edit_LogicalTab_IncDecBtns, 16, 0);  // alle IncDec-Buttons löschen
  FillBlock(@edit_LogicalTab_IncDecBtns_flag, 16, 0);
end;

// -----------------------------------------------------------------------------

procedure AC_IncDecControlsTimerElapsed;
// wird aus MainTasks nach Abschluss aller Aufgaben
// aufgerufen, wenn TimeoutTimer abgelaufen ist
// Aktivierte IncDec-Momentary-Buttons wieder zurücksetzen
begin
  ac_mb_inc:= false;
  ac_mb_dec:= false;
  ac_mb_v1:= false;
  ac_mb_v2:= false;
end;

// #############################################################################

procedure ac_send_converted_vibbtns(event_source: Byte);
begin
  NB_VCbitsToVibknob;
  FH_VibratoToFPGA;
  AC_sendmsg(c_VibKnob, event_source);
  edit_VibKnob_flag:= 0;
end;

procedure ac_reset_vibtabs_flags;
var a_bool: Boolean;
begin
  a_bool:= edit_LogicalTab_4VCh;
  FillBlock(@edit_LogicalTab_VibBtns, 6, 0);
  FillBlock(@edit_LogicalTab_VibBtns_flag, 6, 0);
  if (edit_VibKnobMode <> 3) then
    edit_LogicalTab_4VCh:= a_bool;
  endif;
end;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

procedure AC_HandlePresetChange;
begin

{$IFDEF DEBUG_AC}
  writeln(serout,'/ AC Preset ' + bytetostr(edit_CommonPreset));
{$ENDIF}
  PresetPreview:= false;
  AC_sendmsg(c_CommonPreset, edit_CommonPreset_flag);

  if (edit_CommonPreset = 0) then
    // wieder Live-Einstellung. Vorherige Werte Laden
    if (edit_CommonPreset_old > 0) then
      SR_PresetTempToLive; // vorherige Werte nehmen
    endif;
    if edit_ADCconfig >= 2 then
      AC_HandleVoiceChangeUpper;  // ggf. auch zum Einlesen der Live-Drawbars
      AC_HandleVoiceChangeLower;
      AC_HandleVoiceChangePedal;
      ADC_ChangeStateAll(true);
    endif;
    if (edit_ADCconfig > 1) then
      ADC_ResetTimersAll;
    endif;
    SWI_ForceSwitchReload;       // Schalter-Eingänge neu einlesen
    VoiceUpperInvalid:= false;   // kein Blinken der Preset-LEDs
    VoiceLowerInvalid:= false;
    VoicePedalInvalid:= false;
    CurrentPresetName:= c_PresetNameStr0;
  else
    // Common Preset laden
    if (edit_CommonPreset_old = 0) then
      SR_PresetLiveToTemp;  // Live-Einstellung merken
    endif;
    // hole edit_CommonPreset, Voice-Nummern bleiben
    DF_readblock(c_preset_base_DF + Word(edit_CommonPreset), 512);
    if (BlockArrayMagicByte = $A5)
    and (BlockArrayPresetVersion >= c_MinimalPresetStructureVersion) then
      CurrentPresetName:= block_PresetNameStr;
    else
{$IFDEF DEBUG_AC}
      writeln(serout, '/ AC Preset not initalized!');
{$ENDIF}
      CurrentPresetName:= s_none;
    endif;
    LoadPresetFromBlockBuffer;
    VoiceUpperInvalid:= true;  // Blinken der Preset-LEDs, invalid
    VoiceLowerInvalid:= true;
    VoicePedalInvalid:= true;
    if (edit_ADCconfig > 1) then
      // Drawbars neu einlesen und annulieren
      ADC_ReadAll_24;
      ADC_ReadAll_64;
      ADC_ChangeStateAll(false);
      ADC_ResetTimersAll;
    endif;
  endif;

  if ConnectMode = t_connect_osc_wifi then
    writeln(serOut);
    writeln(serOut, '/label_preset="' + CurrentPresetName + '"');
  endif;
  AC_SendPresetName;

  if edit_LogicalTab_EG_mask2dry_flag > 0 then
    send_osc_colors;
  endif;

  MIDI_SendController(0, edit_PresetCC, edit_CommonPreset); // Default: Bank Select LSB
  if ConnectMode = t_connect_osc_wifi then
    MIDI_RequestAllGMnames; // werden für Anzeige gebraucht
  endif;

  CommonPresetInvalid:= false;
  midi_DisablePercussion:= false;

  edit_CommonPreset_old:= edit_CommonPreset;
  edit_CommonPreset_flag:= 0;
  edit_PercKnob_flag:= 0; // wird sonst evt. zurückübersetzt!
  edit_ReverbKnob_flag:= 0;
  NB_VibknobToVCbits;
  NB_ResetSpecialFlags; // Voice-Flags und Momentary Buttons
  MenuIndex_Requested:= c_MenuCommonPreset;  // Menu dauerhaft wechseln
end;

// ******************************ALLINONE***************************************
{$ENDIF}
// *****************************************************************************



procedure AC_MutualControls;
// Wird regelmäßig aus main_tasks-Zeitscheibe aufgerufen
// Behandlung sich gegenseitig beeinflussender Bedienelemente
// und Presets (würden nach AC_CollectChanges nicht mehr ausgeführt)
var
  any_change, resend_osc_colors: boolean;
  any_gating_tab, is_b3, is_primary_upperdb, is_not_primary_upperdb: Boolean;
  temp_flag, idx_b: Byte;
begin

  // Preset-Change vorab behandeln
  if (not PresetStoreRequest) and (edit_CommonPreset_flag > c_to_fpga_event_source) then
    ac_preset_changed:= true;  // wird für GM-Voicenamen-Unterdrückung gebraucht
    AC_HandlePresetChange;
  endif;

  // ---------------------------------------------------------------------------
  any_change:= false;
  if edit_SingleDBtoggle_flag <> 0 then
    Inc(SingleDBsetSelect);
    if SingleDBsetSelect > 2 then
      SingleDBsetSelect:= 0;
    endif;
    any_change:= true;
  endif;
  if edit_SingleDBtoUpper_flag <> 0 then
    SingleDBsetSelect:= 0;
  endif;
  if edit_SingleDBtoLower_flag <> 0 then
    if SingleDBsetSelect = 1 then
      SingleDBsetSelect:= 0;  // wieder ausgeschaltet
    else
      SingleDBsetSelect:= 1;
    endif;
    any_change:= true;
  endif;
  if edit_SingleDBtoPedal_flag <> 0 then
    if SingleDBsetSelect = 2 then
      SingleDBsetSelect:= 0;  // wieder ausgeschaltet
    else
      SingleDBsetSelect:= 2;
    endif;
    any_change:= true;
  endif;
  // alle SingleDBset-Buttons löschen, nur aktiven setzen
  // edit_LogicalTab_SingleDBtoggle wird in swi_get_TabLED_bits behandelt
  if any_change then
    FillBlock(@edit_SingleDBtoggle, 4, 0);   // alle SingleDBset-Buttons löschen
    edit_LogicalTab_SingleDBdestBtns[SingleDBsetSelect + 1]:= 255;
  endif;

  resend_osc_colors:= false;

  // Organ-/Rotary-Setup, Änderungen nur über Menu oder OSC/MIDI,
  // NICHT über Preset. Belegt einige Parameter für jeweiliges Modell.
  if edit_OrganModel_flag > 0 then
    AC_LoadOrganModel; // setzt Gating Mode etc anhand edit_OrganSetup
    AC_sendmsg(c_OrganModel, edit_OrganModel_flag);
    edit_OrganModel_flag:= 0;
    edit_GatingKnob_flag:= c_preset_event_source;
    FillBlock(@edit_LogicalTabs_KeyingModes_flag, 4, 0);
  endif;
  if edit_SpeakerModel_flag > 0 then
    AC_LoadSpeakerModel;
    AC_sendmsg(c_SpeakerModel, edit_SpeakerModel_flag);
    edit_SpeakerModel_flag:= 0;
  endif;

  // ---------------------------------------------------------------------------

  // Gating-Mode, 4 Radio Buttons mit gegenseitiger Auslösung und OFF
  // Menü-Item oder Knob (RFU) - falls Änderungen über Menü
  if (edit_LogicalTab_H100_Mode_flag > 0) then
    edit_GatingKnob_flag:= edit_LogicalTab_H100_Mode_flag;
    if edit_LogicalTab_H100_Mode then
      edit_GatingKnob:= 1;
    else
      edit_GatingKnob:= 0;
    endif;
  endif;
  if (edit_LogicalTab_EG_mode_flag > 0) then
    edit_GatingKnob_flag:= edit_LogicalTab_EG_mode_flag;
    if edit_LogicalTab_EG_mode then
      edit_GatingKnob:= 2;
    else
      edit_GatingKnob:= 0;
    endif;
  endif;
  if (edit_LogicalTab_EG_PercMode_flag > 0) then
    edit_GatingKnob_flag:= edit_LogicalTab_EG_PercMode_flag;
    if edit_LogicalTab_EG_PercMode then
      edit_GatingKnob:= 3;
    else
      edit_GatingKnob:= 0;
    endif;
  endif;
  if (edit_LogicalTab_EG_TimeBendMode_flag > 0) then
    edit_GatingKnob_flag:= edit_LogicalTab_EG_TimeBendMode_flag;
    if edit_LogicalTab_EG_TimeBendMode then
      edit_GatingKnob:= 4;
    else
      edit_GatingKnob:= 0;
    endif;
  endif;

  if edit_GatingKnob_flag > 0 then
    // Knob geändert. Zugehörige Tabs neu setzen und senden
    // alle Tabs löschen = B3, Flags setzen auf c_board_event_source:
    // edit_LogicalTab_H100_Mode etc. löschen, Sende-Flags setzen
    // #1152 bis #1155
    FillBlock(@edit_LogicalTabs_KeyingModes, 4, 0);
    if edit_GatingKnob >= 1 then
      edit_LogicalTabs_KeyingModes[edit_GatingKnob - 1]:= true; // Tab setzen
    endif;
    for idx_w:= 152 to 155 do  // #1152 bis #1155
      AC_sendmsg(idx_w, edit_GatingKnob_flag);
    endfor;
    FillBlock(@edit_LogicalTabs_KeyingModes_flag, 4, 0);

{$IFNDEF MODULE}
    AC_sendmsg(c_GatingKnob, edit_GatingKnob_flag);  //  für TouchOSC
{$ENDIF}

    resend_osc_colors:= true;
    NB_ValidateExtendedParams;  // Legt gültige Menüs und Restore-Freigaben an
    MenuRefresh:= true;
  endif;

  // ---------------------------------------------------------------------------

  // Percussion-Abschaltung
  any_change:= DisablePercussion;
  is_b3:= (edit_GatingKnob = 0) and edit_PercEnaOnLiveDBonly;
  is_primary_upperdb:= (edit_UpperVoice = 0) or (edit_CommonPreset > 0);
  is_not_primary_upperdb:= not is_primary_upperdb;
  DisablePercussion:= (is_b3 and is_not_primary_upperdb)
             or MIDI_DisablePercussion or SWI_CancelActive_upr;

  if DisablePercussion <> any_change then
    // erzwingt Senden von Upper und Perc über ta_perc_param
    edit_PercEnaOnLiveDBonly_flag:= c_to_fpga_event_source;
    edit_LogicalTab_PercOn_flag:= c_to_fpga_event_source;
  endif;

  any_change:= DisableDB1;  // DisableDB1 nur bei Perc ON wirksam!
  DisableDB1:= edit_NoDB1_atPerc and is_primary_upperdb and is_b3;
  if MIDI_OverrideCancelDB1 then
    DisableDB1:= false;
  endif;
  if DisableDB1 <> any_change then
    // erzwingt Senden von Upper und Perc über ta_perc_param
    edit_PercEnaOnLiveDBonly_flag:= c_to_fpga_event_source;
    edit_LogicalTab_PercOn_flag:= c_to_fpga_event_source;
  endif;

  // ---------------------------------------------------------------------------

  // Percussion Modes über Menü oder #1262 eingestellt?
  if edit_PercKnob_flag > 0 then // über Menü geändert
    NB_PercKnobToTabs;
    FillEventSource(c_LogicalTab_PercBtns, 4, edit_PercKnob_flag);
    edit_PercKnob_flag:= 0;
    resend_osc_colors:= true;
    MenuRefresh:= true;
  else
    // zurückübersetzen, falls Änderung über Tabs
    if (edit_LogicalTab_PercOn_flag  or edit_LogicalTab_PercSoft_flag
    or edit_LogicalTab_PercFast_flag or edit_LogicalTab_Perc3rd_flag) > 0 then
      NB_TabsToPercKnob;
      edit_PercKnob_flag:= c_control_event_source;
      resend_osc_colors:= true;
      MenuRefresh:= true;
    endif;
  endif;

  // Reverb über Menü oder #1263 eingestellt?
  if edit_ReverbKnob_flag > 0 then // über Menü geändert
    edit_LogicalTab_Reverb1:= Bit(edit_ReverbKnob, 0);
    edit_LogicalTab_Reverb2:= Bit(edit_ReverbKnob, 1);
    edit_LogicalTab_Reverb1_flag:= edit_ReverbKnob_flag;
    edit_LogicalTab_Reverb2_flag:= edit_ReverbKnob_flag;
    MenuRefresh:= true;
  else
    if (edit_LogicalTab_Reverb1_flag or edit_LogicalTab_Reverb2_flag) > 0 then
      NB_TabsToReverbKnob;
      AC_sendmsg(c_ReverbKnob, c_control_event_source);
      edit_ReverbKnob_flag:= c_control_event_source;
      MenuRefresh:= true;
    endif;
  endif;

  // ----------------------- VIBRATO BUTTONS -----------------------------------

  if (edit_LogicalTab_4VCh_flag > 0) and (edit_VibKnobMode <> 3) then
    ac_send_converted_vibbtns(edit_LogicalTab_4VCh_flag);
  endif;


  case edit_VibKnobMode of
  1:
    if edit_LogicalTab_4V1_flag > 0 then
      // 2 Binary Toggle Buttons + C/V
      // Logik: Wechselseitige Auslösung oder beide gedrückt
      edit_LogicalTab_4V1:= true;
      edit_LogicalTab_4V2:= ac_mb_v2; // nach 75 Ticks gelöscht
      ac_mb_v1:= true;
      ac_send_converted_vibbtns(edit_LogicalTab_4V1_flag);
      SetSystimer(TimeoutTimer, 75);
    endif;
    if edit_LogicalTab_4V2_flag > 0 then
      // 2 Binary Toggle Buttons + C/V
      // Logik: Wechselseitige Auslösung oder beide gedrückt
      edit_LogicalTab_4V2:= true;
      edit_LogicalTab_4V1:= ac_mb_v1; // nach 75 Ticks gelöscht
      ac_mb_v2:= true;
      ac_send_converted_vibbtns(edit_LogicalTab_4V2_flag);
      SetSystimer(TimeoutTimer, 75);
    endif;
    |
  2:
    for idx_b:= 0 to 2 do
      temp_flag:= edit_LogicalTab_VibBtns_flag[idx_b];
      if temp_flag > 0 then
        ac_reset_vibtabs_flags;
        edit_LogicalTab_VibBtns[idx_b]:= true;
        ac_send_converted_vibbtns(temp_flag);
        break;
      endif;
    endfor;
    |
  3:
    for idx_b:= 0 to 5 do
      temp_flag:= edit_LogicalTab_VibBtns_flag[idx_b];
      if temp_flag > 0 then
        ac_reset_vibtabs_flags;
        edit_LogicalTab_VibBtns[idx_b]:= true;
        ac_send_converted_vibbtns(temp_flag);
        break;
      endif;
    endfor;
    |
  endcase;


  // ---------------------------------------------------------------------------

{$IFNDEF MODULE}
  if Bit(edit_ConfBits2, 3) then
    if (edit_LogicalTab_LeslieFast_flag > 0) then
      edit_LogicalTab_PHR_Fast:= edit_LogicalTab_LeslieFast;
      edit_LogicalTab_PHR_Fast_flag:= edit_LogicalTab_LeslieFast_flag;
    elsif  (edit_LogicalTab_PHR_Fast_flag > 0) then
      edit_LogicalTab_LeslieFast:= edit_LogicalTab_PHR_Fast;
      edit_LogicalTab_LeslieFast_flag:= edit_LogicalTab_PHR_Fast_flag;
    endif;
  endif;

  // ---------------------------------------------------------------------------

  if resend_osc_colors or (edit_LogicalTab_EG_mask2dry_flag > 0) then
    send_osc_colors;
  endif;
{$ENDIF}

end;

// #############################################################################

procedure AC_ExecEditChanges;
// Wird regelmäßig aus main_tasks-Zeitscheibe aufgerufen
// Geänderte Bedienelemente (*_flag > 0) als Message senden und über
// Proc-Tabelle ans FPGA bzw. entsprechende Routinen schicken
var
  event_flags, proc_idx: Byte;
  run_proc: procedure;
begin
  AC_MutualControls; // gegenseitig beeinflussende Bedienelemente behandeln

  // alle Proc-Flags auf "nicht ausführen"
  FillBlock(@ac_proclist_flags, word(c_proc_max + 1), 0);

  for idx_w:= 0 to c_last_edit_param do
    event_flags:= edit_array_flag[idx_w];
    if event_flags = 0 then
      continue;
    endif;

    if event_flags > c_to_fpga_event_source then  // mehr tun als nur an FPGA
      // Voice-Changes wurden bereits gesendet!
      AC_sendmsg(idx_w, event_flags);
    endif;

    // Änderungen für FPGA und DSP, Prozeduraufruf über Tabelle
    proc_idx:= ac_proc_idx[idx_w];
    if proc_idx < c_nil_proc then
      ac_proclist_flags[proc_idx]:= true;
    endif;

    edit_array_flag[idx_w]:= 0;
  endfor;

  for proc_idx:= 0 to c_proc_max - 1 do // ohne "nil"
    if ac_proclist_flags[proc_idx] then
      run_proc:= ac_proclist[proc_idx];
      run_proc; // aus Tabelle entnommene Routine ausführen
    endif;
  endfor;
  ac_preset_changed:= false;
  PresetStoreRequest:= false;
end;



end apply_changes.


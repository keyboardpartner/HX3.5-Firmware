  t_action = (
    ta_none,
    ta_dbu, ta_dbl, ta_dbp,
    ta_perc_param,
    ta_organ,
    ta_gating,  // Percussion, EG/H100 Mode, SaveDest- und Menüumfang
    ta_vib, ta_phr_prog,
    ta_trimpots, ta_rota_live,
    ta_split,
    ta_pots, ta_reverb,
    ta_tuning, ta_midi,
    ta_gmu, ta_gml, ta_gmp,
    // Reihenfolge von NRPN $3570+x und in Tabelle:
    // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
    ta_gmu_v0, ta_gml_v0, ta_gmp_v0, ta_dummy, ta_gmu_v1, ta_gml_v1, ta_gmp_v1,
    ta_rotary_run, ta_rotary_fast, ta_phr,
    ta_dimmer, ta_detent,
    ta_gm2,
    ta_inserts,
    ta_wave,
    ta_swell, ta_taper_tg,
    ta_cpn, ta_vn_l, ta_vn_p, ta_vn_u,   // Preset-Nummern
    ta_direct_uprout,
    ta_presetname,
    ta_last_entry
  );

c_edit_actions: Array[0..511] of t_action = (
  ta_dbu, // #1000 Upper Drawbar 16
  ta_dbu, // #1001 Upper Drawbar 5 1/3
  ta_dbu, // #1002 Upper Drawbar 8
  ta_dbu, // #1003 Upper Drawbar 4
  ta_dbu, // #1004 Upper Drawbar 2 2/3
  ta_dbu, // #1005 Upper Drawbar 2
  ta_dbu, // #1006 Upper Drawbar 1 3/5
  ta_dbu, // #1007 Upper Drawbar 1 1/3
  ta_dbu, // #1008 Upper Drawbar 1
  ta_dbu, // #1009 Upper Mixture Drawbar 10
  ta_dbu, // #1010 Upper Mixture Drawbar 11
  ta_dbu, // #1011 Upper Mixture Drawbar 12
  ta_none, // #1012
  ta_none, // #1013
  ta_none, // #1014
  ta_none, // #1015
  ta_dbl, // #1016 Lower Drawbar 16
  ta_dbl, // #1017 Lower Drawbar 5 1/3
  ta_dbl, // #1018 Lower Drawbar 8
  ta_dbl, // #1019 Lower Drawbar 4
  ta_dbl, // #1020 Lower Drawbar 2 2/3
  ta_dbl, // #1021 Lower Drawbar 2
  ta_dbl, // #1022 Lower Drawbar 1 3/5
  ta_dbl, // #1023 Lower Drawbar 1 1/3
  ta_dbl, // #1024 Lower Drawbar 1
  ta_dbl, // #1025 Lower Mixture Drawbar 10
  ta_dbl, // #1026 Lower Mixture Drawbar 11
  ta_dbl, // #1027 Lower Mixture Drawbar 12
  ta_none, // #1028
  ta_none, // #1029
  ta_none, // #1030
  ta_none, // #1031
  ta_dbp, // #1032 Pedal Drawbar 16
  ta_dbp, // #1033 Pedal Drawbar 5 1/3
  ta_dbp, // #1034 Pedal Drawbar 8
  ta_dbp, // #1035 Pedal Drawbar 4
  ta_dbp, // #1036 Pedal Drawbar 2 2/3
  ta_dbp, // #1037 Pedal Drawbar 2
  ta_dbp, // #1038 Pedal Drawbar 1 3/5
  ta_dbp, // #1039 Pedal Drawbar 1 1/3
  ta_dbp, // #1040 Pedal Drawbar 1
  ta_dbp, // #1041 Pedal Mixture Drawbar 10
  ta_dbp, // #1042 Pedal Mixture Drawbar 11
  ta_dbp, // #1043 Pedal Mixture Drawbar 12
  ta_none, // #1044
  ta_none, // #1045
  ta_none, // #1046
  ta_none, // #1047
  ta_dbu, // #1048 Upper Attack
  ta_dbu, // #1049 Upper Decay
  ta_dbu, // #1050 Upper Sustain
  ta_dbu, // #1051 Upper Release
  ta_dbu, // #1052 Upper ADSR Harmonic Decay
  ta_none, // #1053
  ta_none, // #1054
  ta_none, // #1055
  ta_dbl, // #1056 Lower Attack
  ta_dbl, // #1057 Lower Decay
  ta_dbl, // #1058 Lower Sustain
  ta_dbl, // #1059 Lower Release
  ta_dbl, // #1060 Lower ADSR Harmonic Decay
  ta_none, // #1061
  ta_none, // #1062
  ta_none, // #1063
  ta_dbp, // #1064 Pedal Attack
  ta_dbp, // #1065 Pedal Decay
  ta_dbp, // #1066 Pedal Sustain
  ta_dbp, // #1067 Pedal Release
  ta_dbp, // #1068 Pedal ADSR Harmonic Decay
  ta_none, // #1069
  ta_none, // #1070
  ta_none, // #1071
  ta_dbp, // #1072 Pedal Drawbar 16 AutoMix
  ta_dbp, // #1073 Pedal Drawbar 16H AutoMix
  ta_dbp, // #1074 Pedal Drawbar 8 AutoMix
  ta_dbp, // #1075 Pedal Drawbar 8H AutoMix
  ta_none, // #1076
  ta_rotary_fast, // #1077
  ta_none, // #1078
  ta_rotary_run, // #1079
  ta_pots, // #1080 General Master Volume
  ta_pots, // #1081 Rotary Simulation Tube Amp Gain
  ta_pots, // #1082 Upper Manual Level
  ta_pots, // #1083 Lower Manual Level
  ta_pots, // #1084 Pedal Level
  ta_pots, // #1085 Upper Dry/2ndVoice Level
  ta_reverb, // #1086 Overall Reverb Level
  ta_swell, // #1087 Tone Pot Equ
  ta_swell, // #1088 Trim Cap Swell
  ta_swell, // #1089 Minimal Swell Level
  ta_pots, // #1090 AO 28 Triode Distortion
  ta_pots, // #1091 Böhm Module Reverb Volume
  ta_pots, // #1092 Böhm Module Efx Volume
  ta_swell, // #1093 Böhm Module Swell Volume
  ta_pots, // #1094 Böhm Module Front Volume
  ta_pots, // #1095 Böhm Module Rear Volume
  ta_dbu, // #1096 Upper Envelope Drawbar 16
  ta_dbu, // #1097 Upper Envelope Drawbar 5 1/3
  ta_dbu, // #1098 Upper Envelope Drawbar 8
  ta_dbu, // #1099 Upper Envelope Drawbar 4
  ta_dbu, // #1100 Upper Envelope Drawbar 2 2/3
  ta_dbu, // #1101 Upper Envelope Drawbar 2
  ta_dbu, // #1102 Upper Envelope Drawbar 1 3/5
  ta_dbu, // #1103 Upper Envelope Drawbar 1 1/3
  ta_dbu, // #1104 Upper Envelope Drawbar 1
  ta_dbu, // #1105 Upper Envelope Mixture Drawbar 10
  ta_dbu, // #1106 Upper Envelope Mixture Drawbar 11
  ta_dbu, // #1107 Upper Envelope Mixture Drawbar 12
  ta_none, // #1108
  ta_none, // #1109
  ta_none, // #1110
  ta_none, // #1111
  ta_trimpots, // #1112 Equ Bass Control
  ta_trimpots, // #1113 Equ Bass Frequency if FullParametric
  ta_trimpots, // #1114 Equ Bass Peak/Q if FullParametric
  ta_trimpots, // #1115 Equ Mid Control
  ta_trimpots, // #1116 Equ Mid Frequency
  ta_trimpots, // #1117 Equ Mid Peak/Q
  ta_trimpots, // #1118 Equ Treble Control
  ta_trimpots, // #1119 Equ Treble Frequency if FullParametric
  ta_trimpots, // #1120 Equ Treble Peak/Q if FullParametric
  ta_trimpots, // #1121 Equ FullParametric Enable
  ta_pots, // #1122 Böhm Module Ext Rotary Volume Left
  ta_pots, // #1123 Böhm Module Ext Rotary Volume Right
  ta_detent, // #1124 Equ Bass Gain Pot Mid Position
  ta_detent, // #1125 Equ Mid Gain Pot Mid Position
  ta_detent, // #1126 Equ Treble Gain Pot Mid Position
  ta_detent, // #1127 Perc/Dry Volume Mid Position
  ta_gating, // #1128 Percussion ON
  ta_gating, // #1129 Percussion SOFT
  ta_gating, // #1130 Percussion FAST
  ta_gating, // #1131 Percussion THIRD
  ta_inserts, // #1132 Vibrato Upper ON
  ta_inserts, // #1133 Vibrato Lower ON
  ta_rotary_run, // #1134 Leslie RUN
  ta_rotary_fast, // #1135 Leslie FAST
  ta_inserts, // #1136 Tube Amp Bypass
  ta_inserts, // #1137 Rotary Speaker Bypass
  ta_inserts, // #1138 Phasing Rotor upper ON
  ta_inserts, // #1139 Phasing Rotor lower ON
  ta_none, // #1140 Reverb 1
  ta_none, // #1141 Reverb 2
  ta_inserts, // #1142 Add Pedal
  ta_split, // #1143 Keyboard Split ON
  ta_phr_prog, // #1144 Phasing Rotor
  ta_phr_prog, // #1145 Phasing Rotor Ensemble
  ta_phr_prog, // #1146 Phasing Rotor Celeste
  ta_phr_prog, // #1147 Phasing Rotor Fading
  ta_phr_prog, // #1148 Phasing Rotor Weak
  ta_phr_prog, // #1149 Phasing Rotor Deep
  ta_phr_prog, // #1150 Phasing Rotor Fast
  ta_phr_prog, // #1151 Phasing Rotor Delay
  ta_none, // #1152 TAB #24, H100 Mode
  ta_none, // #1153 TAB #25, Envelope Generator (EG) Mode
  ta_none, // #1154 TAB #26, EG Percussion Drawbar Mode
  ta_none, // #1155 TAB #27, EG TimeBend Drawbar Mode
  ta_gating, // #1156 TAB #28, H100 2ndVoice (Perc Decay Bypass)
  ta_gating, // #1157 TAB #29, H100 Harp Sustain
  ta_gating, // #1158 TAB #30, EG Enables to Dry Channel
  ta_inserts, // #1159 TAB #31, Equalizer Bypass
  ta_gating, // #1160 Upper Drawbar 16 to ADSR
  ta_gating, // #1161 Upper Drawbar 5 1/3 to ADSR
  ta_gating, // #1162 Upper Drawbar 8 to ADSR
  ta_gating, // #1163 Upper Drawbar 4 to ADSR
  ta_gating, // #1164 Upper Drawbar 2 2/3 to ADSR
  ta_gating, // #1165 Upper Drawbar 2 to ADSR
  ta_gating, // #1166 Upper Drawbar1 3/5 to ADSR
  ta_gating, // #1167 Upper Drawbar 1 1/3 to ADSR
  ta_gating, // #1168 Upper Drawbar 1 to ADSR
  ta_gating, // #1169 Upper Mixture Drawbar 10 to ADSR
  ta_gating, // #1170 Upper Mixture Drawbar 11 to ADSR
  ta_gating, // #1171 Upper Mixture Drawbar 12 to ADSR
  ta_none, // #1172
  ta_none, // #1173
  ta_split, // #1174 Octave Downshift Upper
  ta_split, // #1175 Octave Downshift Lower
  ta_dbl, // #1176 Lower Drawbar 16 to ADSR
  ta_dbl, // #1177 Lower Drawbar 5 1/3 to ADSR
  ta_dbl, // #1178 Lower Drawbar 8 to ADSR
  ta_dbl, // #1179 Lower Drawbar 4 to ADSR
  ta_dbl, // #1180 Lower Drawbar 2 2/3 to ADSR
  ta_dbl, // #1181 Lower Drawbar 2 to ADSR
  ta_dbl, // #1182 Lower Drawbar1 3/5 to ADSR
  ta_dbl, // #1183 Lower Drawbar 1 1/3 to ADSR
  ta_dbl, // #1184 Lower Drawbar 1 to ADSR
  ta_dbl, // #1185 Lower Mixture Drawbar 10 to ADSR
  ta_dbl, // #1186 Lower Mixture Drawbar 11 to ADSR
  ta_dbl, // #1187 Lower Mixture Drawbar 12 to ADSR
  ta_none, // #1188
  ta_none, // #1189
  ta_none, // #1190
  ta_none, // #1191
  ta_presetname, // #1192 Preset Name String [0] (Length Byte)
  ta_presetname, // #1193 Preset Name String [1]
  ta_presetname, // #1194 Preset Name String [2]
  ta_presetname, // #1195 Preset Name String [3]
  ta_presetname, // #1196 Preset Name String [4]
  ta_presetname, // #1197 Preset Name String [5]
  ta_presetname, // #1198 Preset Name String [6]
  ta_presetname, // #1199 Preset Name String [7]
  ta_presetname, // #1200 Preset Name String [8]
  ta_presetname, // #1201 Preset Name String [9]
  ta_presetname, // #1202 Preset Name String [10]
  ta_presetname, // #1203 Preset Name String [11]
  ta_presetname, // #1204 Preset Name String [12]
  ta_presetname, // #1205 Preset Name String [13]
  ta_presetname, // #1206 Preset Name String [14]
  ta_presetname, // #1207 Preset Name String [15]
  ta_none, // #1208 nicht abgespeicherte Buttons
  ta_none, // #1209 nicht abgespeicherte Buttons
  ta_none, // #1210 nicht abgespeicherte Buttons
  ta_none, // #1211 nicht abgespeicherte Buttons
  ta_none, // #1212 4 Btn V1
  ta_none, // #1213 4 Btn V2
  ta_none, // #1214 4 Btn V3
  ta_none, // #1215 4 Btn V/C
  ta_none, // #1216 Transpose +1 UP
  ta_none, // #1217 Transpose -1 DOWN
  ta_none, // #1218 nicht abgespeicherte Buttons
  ta_none, // #1219 nicht abgespeicherte Buttons
  ta_none, // #1220 Single DB set on Lower
  ta_none, // #1221 nicht abgespeicherte Buttons
  ta_none, // #1222 nicht abgespeicherte Buttons
  ta_none, // #1223 nicht abgespeicherte Buttons
  ta_gmu_v0, // #1224 Upper GM Layer 1 Voice
  ta_gmu, // #1225 Upper GM Layer 1 Level
  ta_gmu, // #1226 Upper GM Layer 1 Harmonic
  ta_gmu_v1, // #1227 Upper GM Layer 2 Voice
  ta_gmu, // #1228 Upper GM Layer 2 Level
  ta_gmu, // #1229 Upper GM Layer 2 Harmonic
  ta_gmu, // #1230 Upper GM Layer 2 Detune
  ta_none, // #1231
  ta_gml_v0, // #1232 Lower GM Layer 1 Voice
  ta_gml, // #1233 Lower GM Layer 1 Level
  ta_gml, // #1234 Lower GM Layer 1 Harmonic
  ta_gml_v1, // #1235 Lower GM Layer 2 Voice
  ta_gml, // #1236 Lower GM Layer 2 Level
  ta_gml, // #1237 Lower GM Layer 2 Harmonic
  ta_gml, // #1238 Lower GM Layer 2 Detune
  ta_none, // #1239
  ta_gmp_v0, // #1240 Pedal GM Layer 1 Voice
  ta_gmp, // #1241 Pedal GM Layer 1 Level
  ta_gmp, // #1242 Pedal GM Layer 1 Harmonic
  ta_gmp_v1, // #1243 Pedal GM Layer 2 Voice
  ta_gmp, // #1244 Pedal GM Layer 2 Level
  ta_gmp, // #1245 Pedal GM Layer 2 Harmonic
  ta_gmp, // #1246 Pedal GM Layer 2 Detune
  ta_none, // #1247
  ta_none, // #1248
  ta_none, // #1249
  ta_none, // #1250
  ta_none, // #1251
  ta_none, // #1252
  ta_none, // #1253
  ta_none, // #1254
  ta_none, // #1255
  ta_none, // #1256
  ta_none, // #1257
  ta_none, // #1258
  ta_none, // #1259
  ta_none, // #1260
  ta_none, // #1261
  ta_none, // #1262
  ta_none, // #1263
  ta_vib, // #1264 Vibrato Knob
  ta_none, // #1265 Organ Model (OSC)
  ta_none, // #1266 Generator Model Knob
  ta_gating, // #1267 Gating (Keying) Knob
  ta_cpn, // #1268 Overall Preset (Temp)
  ta_vn_u, // #1269 Upper Voice
  ta_vn_l, // #1270 Lower Voice
  ta_vn_p, // #1271 Pedal Voice
  ta_gating, // #1272 Level Busbar 16
  ta_gating, // #1273 Level Busbar 5 1/3
  ta_gating, // #1274 Level Busbar 8
  ta_gating, // #1275 Level Busbar 4
  ta_gating, // #1276 Level Busbar 2 2/3
  ta_gating, // #1277 Level Busbar 2
  ta_gating, // #1278 Level Busbar 1 3/5
  ta_gating, // #1279 Level Busbar 1 1/3
  ta_gating, // #1280 Level Busbar 1
  ta_gating, // #1281 Level Busbar 10
  ta_gating, // #1282 Level Busbar 11
  ta_gating, // #1283 Level Busbar 12
  ta_gating, // #1284 Level Busbar 13
  ta_gating, // #1285 Level Busbar 14
  ta_gating, // #1286 Level Busbar 15
  ta_none, // #1287
  ta_taper_tg, // #1288 Note Offset Busbar 16
  ta_taper_tg, // #1289 Note Offset Busbar 5 1/3
  ta_taper_tg, // #1290 Note Offset Busbar 8
  ta_taper_tg, // #1291 Note Offset Busbar 4
  ta_taper_tg, // #1292 Note Offset Busbar 2 2/3
  ta_taper_tg, // #1293 Note Offset Busbar 2
  ta_taper_tg, // #1294 Note Offset Busbar 1 3/5
  ta_taper_tg, // #1295 Note Offset Busbar 1 1/3
  ta_taper_tg, // #1296 Note Offset Busbar 1
  ta_taper_tg, // #1297 Note Offset Busbar 10
  ta_taper_tg, // #1298 Note Offset Busbar 11
  ta_taper_tg, // #1299 Note Offset Busbar 12
  ta_taper_tg, // #1300 Note Offset Busbar 13
  ta_taper_tg, // #1301 Note Offset Busbar 14
  ta_taper_tg, // #1302 Note Offset Busbar 15
  ta_none, // #1303
  ta_none, // #1304
  ta_none, // #1305
  ta_none, // #1306
  ta_none, // #1307
  ta_none, // #1308
  ta_none, // #1309
  ta_none, // #1310
  ta_none, // #1311
  ta_none, // #1312
  ta_none, // #1313
  ta_none, // #1314
  ta_none, // #1315
  ta_none, // #1316
  ta_none, // #1317
  ta_none, // #1318
  ta_none, // #1319
  ta_vib, // #1320 Pre-Emphasis (Treble Gain)
  ta_vib, // #1321 LC Line Age/AM Amplitude Modulation
  ta_vib, // #1322 LC Line Feedback
  ta_vib, // #1323 LC Line Reflection
  ta_vib, // #1324 LC Line Response Cutoff Frequency
  ta_vib, // #1325 LC PhaseLk/Line Cutoff Shelving Level
  ta_vib, // #1326 Scanner Gearing (Vib Frequ)
  ta_vib, // #1327 Chorus Dry (Bypass) Level
  ta_vib, // #1328 Chorus Wet (Scanner) Level
  ta_vib, // #1329 Modulation V1/C1
  ta_vib, // #1330 Modulation V2/C2
  ta_vib, // #1331 Modulation V3/C3
  ta_vib, // #1332 Modulation Chorus Enhance
  ta_vib, // #1333 Scanner Segment Flutter
  ta_vib, // #1334 Preemphasis Highpass Cutoff Frequ
  ta_vib, // #1335 Modulation Slope, Preemph HP Phase/Peak
  ta_none, // #1336 PHR Speed Vari Slow (Temp)
  ta_none, // #1337 PHR Speed Vari Fast (Temp)
  ta_phr, // #1338 PHR Speed Slow (Temp)
  ta_phr, // #1339 PHR Feedback (Temp)
  ta_phr, // #1340 PHR Level Ph1 (Temp)
  ta_phr, // #1341 PHR Level Ph2 (Temp)
  ta_phr, // #1342 PHR Level Ph3 (Temp)
  ta_phr, // #1343 PHR Level Dry (Temp)
  ta_phr, // #1344 PHR Feedback Invert (Temp)
  ta_none, // #1345 PHR Ramp Delay (Temp)
  ta_phr, // #1346 PHR Mod Vari Ph1 (Temp)
  ta_phr, // #1347 PHR Mod Vari Ph2 (Temp)
  ta_phr, // #1348 PHR Mod Vari Ph3 (Temp)
  ta_phr, // #1349 PHR Mod Slow Ph1 (Temp)
  ta_phr, // #1350 PHR Mod Slow Ph2 (Temp)
  ta_phr, // #1351 PHR Mod Slow Ph3 (Temp)
  ta_none, // #1352 (RFU)
  ta_split, // #1353 Keyboard Split Point if ON
  ta_split, // #1354 Keyboard Split Mode
  ta_organ, // #1355 Keyboard Transpose
  ta_organ, // #1356 Contact Early Action (Fatar Keybed only)
  ta_organ, // #1357 No 1' Drawbar when Perc ON
  ta_taper_tg, // #1358 Drawbar 16' Foldback Mode
  ta_taper_tg, // #1359 Higher Foldback
  ta_organ, // #1360 Contact Spring Flex
  ta_organ, // #1361 Contact Spring Damping
  ta_organ, // #1362 Percussion Enable On Live DB only
  ta_organ, // #1363 Fatar Velocity Factor
  ta_none, // #1364
  ta_none, // #1365
  ta_none, // #1366
  ta_none, // #1367
  ta_midi, // #1368 MIDI Channel
  ta_midi, // #1369 MIDI Option
  ta_midi, // #1370 MIDI CC Set
  ta_midi, // #1371 MIDI Swell CC
  ta_midi, // #1372 MIDI Volume CC
  ta_gm2, // #1373 MIDI Local Enable
  ta_none, // #1374 MIDI Preset CC
  ta_none, // #1375 MIDI Show CC
  ta_none, // #1376
  ta_none, // #1377
  ta_none, // #1378
  ta_none, // #1379
  ta_none, // #1380
  ta_none, // #1381
  ta_none, // #1382
  ta_none, // #1383
  ta_pots, // #1384 Preamp Swell Type
  ta_tuning, // #1385 TG Tuning Set
  ta_taper_tg, // #1386 TG Size
  ta_taper_tg, // #1387 TG Fixed Taper Value
  ta_wave, // #1388 TG WaveSet
  ta_organ, // #1389 TG Flutter
  ta_organ, // #1390 TG Leakage
  ta_organ, // #1391 TG Tuning
  ta_taper_tg, // #1392 TG Cap Set/Tapering
  ta_taper_tg, // #1393 TG LC Filter Fac
  ta_taper_tg, // #1394 TG Bottom 16' Octave Taper Val
  ta_organ, // #1395 Generator Transpose
  ta_none, // #1396 Generator Model Limit
  ta_pots, // #1397 Organ Upper Manual Enable
  ta_pots, // #1398 Organ Lower Manual Enable
  ta_pots, // #1399 Organ Pedal Enable
  ta_reverb, // #1400 Reverb Level 1
  ta_reverb, // #1401 Reverb Level 2
  ta_reverb, // #1402 Reverb Level 3
  ta_none, // #1403
  ta_none, // #1404
  ta_none, // #1405
  ta_none, // #1406
  ta_none, // #1407
  ta_none, // #1408 Current Mixture Setup Number
  ta_none, // #1409 Current Vibrato Setup Number
  ta_none, // #1410 Current Phasing Setup Number
  ta_gating, // #1411 Current Percussion Menu Number
  ta_reverb, // #1412 Current Reverb Menu Number
  ta_none, // #1413
  ta_none, // #1414
  ta_none, // #1415
  ta_gating, // #1416 Mixt DB 10, Level from Busbar 9
  ta_gating, // #1417 Mixt DB 10, Level from Busbar 10
  ta_gating, // #1418 Mixt DB 10, Level from Busbar 11
  ta_gating, // #1419 Mixt DB 10, Level from Busbar 12
  ta_gating, // #1420 Mixt DB 10, Level from Busbar 13
  ta_gating, // #1421 Mixt DB 10, Level from Busbar 14
  ta_none, // #1422
  ta_none, // #1423
  ta_gating, // #1424 Mixt DB 11, Level from Busbar 9
  ta_gating, // #1425 Mixt DB 11, Level from Busbar 10
  ta_gating, // #1426 Mixt DB 11, Level from Busbar 11
  ta_gating, // #1427 Mixt DB 11, Level from Busbar 12
  ta_gating, // #1428 Mixt DB 11, Level from Busbar 13
  ta_gating, // #1429 Mixt DB 11, Level from Busbar 14
  ta_none, // #1430
  ta_none, // #1431
  ta_gating, // #1432 Mixt DB 12, Level from Busbar 9
  ta_gating, // #1433 Mixt DB 12, Level from Busbar 10
  ta_gating, // #1434 Mixt DB 12, Level from Busbar 11
  ta_gating, // #1435 Mixt DB 12, Level from Busbar 12
  ta_gating, // #1436 Mixt DB 12, Level from Busbar 13
  ta_gating, // #1437 Mixt DB 12, Level from Busbar 14
  ta_none, // #1438
  ta_none, // #1439
  ta_none, // #1440
  ta_none, // #1441
  ta_none, // #1442
  ta_none, // #1443
  ta_none, // #1444
  ta_none, // #1445
  ta_none, // #1446
  ta_none, // #1447
  ta_rota_live, // #1448 Rotary Live Control, Horn Slow Time
  ta_rota_live, // #1449 Rotary Live Control, Rotor Slow Time
  ta_rota_live, // #1450 Rotary Live Control, Horn Fast Time
  ta_rota_live, // #1451 Rotary Live Control, Rotor Fast Time
  ta_rota_live, // #1452 Rotary Live Control, Horn Ramp Up Time
  ta_rota_live, // #1453 Rotary Live Control, Rotor Ramp Up Time
  ta_rota_live, // #1454 Rotary Live Control, Horn Ramp Down Time
  ta_rota_live, // #1455 Rotary Live Control, Rotor Ramp Down Time
  ta_rota_live, // #1456 Rotary Live Control, Speaker Throb Amount
  ta_rota_live, // #1457 Rotary Live Control, Speaker Spread
  ta_rota_live, // #1458 Rotary Live Control, Speaker Balance
  ta_rotary_fast, // #1459 Sync PHR
  ta_none, // #1460
  ta_none, // #1461
  ta_none, // #1462
  ta_none, // #1463
  ta_direct_uprout, // #1464 ENA_CONT_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1465 ENA_CONT_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1466 ENA_ENV_DB_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1467 ENA_ENV_DB_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1468 ENA_ENV_FULL_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1469 ENA_ENV_FULL_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1470 ENV_TO_DRY_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1471 ENV_TO_DRY_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1472 ENA_CONT_PERC_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1473 ENA_CONT_PERC_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1474 ENA_ENV_PERCMODE_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1475 ENA_ENV_PERCMODE_BITS (MSB), Drawbar 11..8
  ta_direct_uprout, // #1476 ENA_ENV_ADSRMODE_BITS (LSB), Drawbar 7..0
  ta_direct_uprout, // #1477 ENA_ENV_ADSRMODE_BITS (MSB), Drawbar 11..8
  ta_none, // #1478
  ta_none, // #1479
  ta_perc_param, // #1480 Perc Norm Level
  ta_perc_param, // #1481 Perc Soft Level
  ta_perc_param, // #1482 Perc Long Time
  ta_perc_param, // #1483 Perc Short Time
  ta_perc_param, // #1484 Perc Muted Level
  ta_none, // #1485
  ta_perc_param, // #1486 Perc Precharge Time
  ta_none, // #1487 Perc Ena on Live DB only
  ta_none, // #1488 (RFU)
  ta_none, // #1489 (RFU)
  ta_gm2, // #1490 GM2 Synth Volume
  ta_gm2, // #1491 Relative Organ Volume
  ta_perc_param, // #1492 H100 Harp Sustain Time
  ta_perc_param, // #1493 H100 2nd Voice Level
  ta_none, // #1494 (RFU)
  ta_dimmer, // #1495 LED Dimmer
  ta_none, // #1496 2ndDB Select Voice Number
  ta_none, // #1497 Vibrato Knob Mode
  ta_none, // #1498 CommonPreset Save/Restore Mask
  ta_none, // #1499 (not used)
  ta_none, // #1500 (not used)
  ta_none, // #1501 Various Configurations
  ta_none, // #1502 Additional Tab Panels are Switch Inputs (obsolete)
  ta_none, // #1503 ADC Configuration
  ta_none, // #1504 (not used)
  ta_none, // #1505 (not used)
  ta_none, // #1506 Pedal Drawbar Configuration
  ta_none, // #1507 ADC Scaling
  ta_none, // #1508 (not used)
  ta_none, // #1509 HX3.5 Device Type
  ta_none, // #1510 Preset/EEPROM Structure Version
  ta_none  // #1511 Magic Flag
);
// #############################################################################
// ###                   Tabs auswerten und Änderungen an FPGA               ###
// #############################################################################
Unit apply_changes;

interface
uses var_def, edit_changes, nuts_and_bolts, MIDI_com, fpga_hilevel;
{$IFDEF ALLINONE}
uses adc_touch_interface, save_restore, switch_interface;
{$ENDIF}

// enable/disable warnings for this unit

procedure AC_MutualControls; // Radio Buttons etc.
function AC_CollectAndSendEventMessages: Boolean;  // Geänderte Bedienelemente als Message senden und für FPGA sammeln
procedure AC_CollectedActionsToFPGA; // gesammelte änderungen anwenden

procedure AC_SendSwell;
procedure AC_SendVolumes;
procedure AC_SendTrimPots;
procedure AC_SendLeslieLiveParams;
procedure AC_SetGenVibMode;
procedure AC_SendPHRprgm;
procedure AC_MomentaryControls;
procedure AC_MomentaryControlsTimerElapsed;

// nur für Proc-Tabelle:
procedure AC_SendTaper;
procedure AC_RouteDirect;
procedure AC_RouteOrgan;
procedure AC_SendGating;
procedure AC_SendInserts;
procedure AC_SendPercParams;
procedure AC_SendGM2ena;
procedure AC_SendRotarySpeed;
procedure AC_SendMIDIccSet;
procedure AC_SetDetent;
procedure AC_SendGMvoiceUpper0;
procedure AC_SendGMvoiceUpper1;
procedure AC_SendGMupper;
procedure AC_SendGMvoiceLower0;
procedure AC_SendGMvoiceLower1;
procedure AC_SendGMlower;
procedure AC_SendGMvoicePedal0;
procedure AC_SendGMvoicePedal1;
procedure AC_SendGMpedal;

implementation
{$IDATA}

const

c_edit_procs: Array[0..511] of procedure = (
  @FH_UpperDrawbarsToFPGA, // #1000 Upper Drawbar 16
  @FH_UpperDrawbarsToFPGA, // #1001 Upper Drawbar 5 1/3
  @FH_UpperDrawbarsToFPGA, // #1002 Upper Drawbar 8
  @FH_UpperDrawbarsToFPGA, // #1003 Upper Drawbar 4
  @FH_UpperDrawbarsToFPGA, // #1004 Upper Drawbar 2 2/3
  @FH_UpperDrawbarsToFPGA, // #1005 Upper Drawbar 2
  @FH_UpperDrawbarsToFPGA, // #1006 Upper Drawbar 1 3/5
  @FH_UpperDrawbarsToFPGA, // #1007 Upper Drawbar 1 1/3
  @FH_UpperDrawbarsToFPGA, // #1008 Upper Drawbar 1
  @FH_UpperDrawbarsToFPGA, // #1009 Upper Mixture Drawbar 10
  @FH_UpperDrawbarsToFPGA, // #1010 Upper Mixture Drawbar 11
  @FH_UpperDrawbarsToFPGA, // #1011 Upper Mixture Drawbar 12
  nil, // #1012
  nil, // #1013
  nil, // #1014
  nil, // #1015
  @FH_LowerDrawbarsToFPGA, // #1016 Lower Drawbar 16
  @FH_LowerDrawbarsToFPGA, // #1017 Lower Drawbar 5 1/3
  @FH_LowerDrawbarsToFPGA, // #1018 Lower Drawbar 8
  @FH_LowerDrawbarsToFPGA, // #1019 Lower Drawbar 4
  @FH_LowerDrawbarsToFPGA, // #1020 Lower Drawbar 2 2/3
  @FH_LowerDrawbarsToFPGA, // #1021 Lower Drawbar 2
  @FH_LowerDrawbarsToFPGA, // #1022 Lower Drawbar 1 3/5
  @FH_LowerDrawbarsToFPGA, // #1023 Lower Drawbar 1 1/3
  @FH_LowerDrawbarsToFPGA, // #1024 Lower Drawbar 1
  @FH_LowerDrawbarsToFPGA, // #1025 Lower Mixture Drawbar 10
  @FH_LowerDrawbarsToFPGA, // #1026 Lower Mixture Drawbar 11
  @FH_LowerDrawbarsToFPGA, // #1027 Lower Mixture Drawbar 12
  nil, // #1028
  nil, // #1029
  nil, // #1030
  nil, // #1031
  @FH_PedalDrawbarsToFPGA, // #1032 Pedal Drawbar 16
  @FH_PedalDrawbarsToFPGA, // #1033 Pedal Drawbar 5 1/3
  @FH_PedalDrawbarsToFPGA, // #1034 Pedal Drawbar 8
  @FH_PedalDrawbarsToFPGA, // #1035 Pedal Drawbar 4
  @FH_PedalDrawbarsToFPGA, // #1036 Pedal Drawbar 2 2/3
  @FH_PedalDrawbarsToFPGA, // #1037 Pedal Drawbar 2
  @FH_PedalDrawbarsToFPGA, // #1038 Pedal Drawbar 1 3/5
  @FH_PedalDrawbarsToFPGA, // #1039 Pedal Drawbar 1 1/3
  @FH_PedalDrawbarsToFPGA, // #1040 Pedal Drawbar 1
  @FH_PedalDrawbarsToFPGA, // #1041 Pedal Mixture Drawbar 10
  @FH_PedalDrawbarsToFPGA, // #1042 Pedal Mixture Drawbar 11
  @FH_PedalDrawbarsToFPGA, // #1043 Pedal Mixture Drawbar 12
  nil, // #1044
  nil, // #1045
  nil, // #1046
  nil, // #1047
  @FH_UpperDrawbarsToFPGA, // #1048 Upper Attack
  @FH_UpperDrawbarsToFPGA, // #1049 Upper Decay
  @FH_UpperDrawbarsToFPGA, // #1050 Upper Sustain
  @FH_UpperDrawbarsToFPGA, // #1051 Upper Release
  @FH_UpperDrawbarsToFPGA, // #1052 Upper ADSR Harmonic Decay
  nil, // #1053
  nil, // #1054
  nil, // #1055
  @FH_LowerDrawbarsToFPGA, // #1056 Lower Attack
  @FH_LowerDrawbarsToFPGA, // #1057 Lower Decay
  @FH_LowerDrawbarsToFPGA, // #1058 Lower Sustain
  @FH_LowerDrawbarsToFPGA, // #1059 Lower Release
  @FH_LowerDrawbarsToFPGA, // #1060 Lower ADSR Harmonic Decay
  nil, // #1061
  nil, // #1062
  nil, // #1063
  @FH_PedalDrawbarsToFPGA, // #1064 Pedal Attack
  @FH_PedalDrawbarsToFPGA, // #1065 Pedal Decay
  @FH_PedalDrawbarsToFPGA, // #1066 Pedal Sustain
  @FH_PedalDrawbarsToFPGA, // #1067 Pedal Release
  @FH_PedalDrawbarsToFPGA, // #1068 Pedal ADSR Harmonic Decay
  nil, // #1069
  nil, // #1070
  nil, // #1071
  @FH_PedalDrawbarsToFPGA, // #1072 Pedal Drawbar 16 AutoMix
  @FH_PedalDrawbarsToFPGA, // #1073 Pedal Drawbar 16H AutoMix
  @FH_PedalDrawbarsToFPGA, // #1074 Pedal Drawbar 8 AutoMix
  @FH_PedalDrawbarsToFPGA, // #1075 Pedal Drawbar 8H AutoMix
  nil, // #1076 Pitchwheel MIDI Send
  @AC_SendRotarySpeed, // #1077 Pitchwheel Rotary Control
  nil, // #1078 Modwheel MIDI Send
  @AC_SendRotarySpeed, // #1079 Modwheel Rotary Control
  @AC_SendVolumes, // #1080 General Master Volume
  @AC_SendVolumes, // #1081 Rotary Simulation Tube Amp Gain
  @AC_SendVolumes, // #1082 Upper Manual Level
  @AC_SendVolumes, // #1083 Lower Manual Level
  @AC_SendVolumes, // #1084 Pedal Level
  @AC_SendVolumes, // #1085 Upper Dry/2ndVoice Level
  @FH_SendReverb, // #1086 Overall Reverb Level
  nil, // #1087 Tone Pot Equ
  nil, // #1088 Trim Cap Swell
  nil, // #1089 Minimal Swell Level
  @AC_SendVolumes, // #1090 AO 28 Triode Distortion
  @AC_SendVolumes, // #1091 Böhm Module Reverb Volume
  @AC_SendVolumes, // #1092 Böhm Module Efx Volume
  nil, // #1093 Böhm Module Swell Volume
  @AC_SendVolumes, // #1094 Böhm Module Front Volume
  @AC_SendVolumes, // #1095 Böhm Module Rear Volume
  @FH_UpperDrawbarsToFPGA, // #1096 Upper Envelope Drawbar 16
  @FH_UpperDrawbarsToFPGA, // #1097 Upper Envelope Drawbar 5 1/3
  @FH_UpperDrawbarsToFPGA, // #1098 Upper Envelope Drawbar 8
  @FH_UpperDrawbarsToFPGA, // #1099 Upper Envelope Drawbar 4
  @FH_UpperDrawbarsToFPGA, // #1100 Upper Envelope Drawbar 2 2/3
  @FH_UpperDrawbarsToFPGA, // #1101 Upper Envelope Drawbar 2
  @FH_UpperDrawbarsToFPGA, // #1102 Upper Envelope Drawbar 1 3/5
  @FH_UpperDrawbarsToFPGA, // #1103 Upper Envelope Drawbar 1 1/3
  @FH_UpperDrawbarsToFPGA, // #1104 Upper Envelope Drawbar 1
  @FH_UpperDrawbarsToFPGA, // #1105 Upper Envelope Mixture Drawbar 10
  @FH_UpperDrawbarsToFPGA, // #1106 Upper Envelope Mixture Drawbar 11
  @FH_UpperDrawbarsToFPGA, // #1107 Upper Envelope Mixture Drawbar 12
  nil, // #1108
  nil, // #1109
  nil, // #1110
  nil, // #1111
  @AC_SendTrimPots, // #1112 Equ Bass Control
  @AC_SendTrimPots, // #1113 Equ Bass Frequency if FullParametric
  @AC_SendTrimPots, // #1114 Equ Bass Peak/Q if FullParametric
  @AC_SendTrimPots, // #1115 Equ Mid Control
  @AC_SendTrimPots, // #1116 Equ Mid Frequency
  @AC_SendTrimPots, // #1117 Equ Mid Peak/Q
  @AC_SendTrimPots, // #1118 Equ Treble Control
  @AC_SendTrimPots, // #1119 Equ Treble Frequency if FullParametric
  @AC_SendTrimPots, // #1120 Equ Treble Peak/Q if FullParametric
  @AC_SendTrimPots, // #1121 Equ FullParametric Enable
  @AC_SendVolumes, // #1122 Böhm Module Ext Rotary Volume Left
  @AC_SendVolumes, // #1123 Böhm Module Ext Rotary Volume Right
  @AC_SetDetent, // #1124 Equ Bass Gain Pot Mid Position
  @AC_SetDetent, // #1125 Equ Mid Gain Pot Mid Position
  @AC_SetDetent, // #1126 Equ Treble Gain Pot Mid Position
  @AC_SetDetent, // #1127 Perc/Dry Volume Mid Position
  @AC_SendGating, // #1128 Percussion ON
  @AC_SendGating, // #1129 Percussion SOFT
  @AC_SendGating, // #1130 Percussion FAST
  @AC_SendGating, // #1131 Percussion THIRD
  @AC_SendInserts, // #1132 Vibrato Upper ON
  @AC_SendInserts, // #1133 Vibrato Lower ON
  @AC_SendRotarySpeed, // #1134 Leslie RUN
  @AC_SendRotarySpeed, // #1135 Leslie FAST
  @AC_SendInserts, // #1136 Tube Amp Bypass
  @AC_SendInserts, // #1137 Rotary Speaker Bypass
  @AC_SendInserts, // #1138 Phasing Rotor upper ON
  @AC_SendInserts, // #1139 Phasing Rotor lower ON
  nil, // #1140 Reverb 1
  nil, // #1141 Reverb 2
  @AC_SendInserts, // #1142 Add Pedal
  @FH_SplitConfigToFPGA, // #1143 Keyboard Split ON
  @AC_SendPHRprgm, // #1144 Phasing Rotor
  @AC_SendPHRprgm, // #1145 Phasing Rotor Ensemble
  @AC_SendPHRprgm, // #1146 Phasing Rotor Celeste
  @AC_SendPHRprgm, // #1147 Phasing Rotor Fading
  @AC_SendPHRprgm, // #1148 Phasing Rotor Weak
  @AC_SendPHRprgm, // #1149 Phasing Rotor Deep
  @AC_SendPHRprgm, // #1150 Phasing Rotor Fast
  @AC_SendPHRprgm, // #1151 Phasing Rotor Delay
  nil, // #1152 TAB #24, H100 Mode
  nil, // #1153 TAB #25, Envelope Generator (EG) Mode
  nil, // #1154 TAB #26, EG Percussion Drawbar Mode
  nil, // #1155 TAB #27, EG TimeBend Drawbar Mode
  @AC_SendGating, // #1156 TAB #28, H100 2ndVoice (Perc Decay Bypass)
  @AC_SendGating, // #1157 TAB #29, H100 Harp Sustain
  @AC_SendGating, // #1158 TAB #30, EG Enables to Dry Channel
  @AC_SendInserts, // #1159 TAB #31, Equalizer Bypass
  @AC_SendGating, // #1160 Upper Drawbar 16 to ADSR
  @AC_SendGating, // #1161 Upper Drawbar 5 1/3 to ADSR
  @AC_SendGating, // #1162 Upper Drawbar 8 to ADSR
  @AC_SendGating, // #1163 Upper Drawbar 4 to ADSR
  @AC_SendGating, // #1164 Upper Drawbar 2 2/3 to ADSR
  @AC_SendGating, // #1165 Upper Drawbar 2 to ADSR
  @AC_SendGating, // #1166 Upper Drawbar1 3/5 to ADSR
  @AC_SendGating, // #1167 Upper Drawbar 1 1/3 to ADSR
  @AC_SendGating, // #1168 Upper Drawbar 1 to ADSR
  @AC_SendGating, // #1169 Upper Mixture Drawbar 10 to ADSR
  @AC_SendGating, // #1170 Upper Mixture Drawbar 11 to ADSR
  @AC_SendGating, // #1171 Upper Mixture Drawbar 12 to ADSR
  nil, // #1172
  nil, // #1173
  @FH_SplitConfigToFPGA, // #1174 Octave Downshift Upper
  @FH_SplitConfigToFPGA, // #1175 Octave Downshift Lower
  @FH_LowerDrawbarsToFPGA, // #1176 Lower Drawbar 16 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1177 Lower Drawbar 5 1/3 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1178 Lower Drawbar 8 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1179 Lower Drawbar 4 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1180 Lower Drawbar 2 2/3 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1181 Lower Drawbar 2 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1182 Lower Drawbar1 3/5 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1183 Lower Drawbar 1 1/3 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1184 Lower Drawbar 1 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1185 Lower Mixture Drawbar 10 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1186 Lower Mixture Drawbar 11 to ADSR
  @FH_LowerDrawbarsToFPGA, // #1187 Lower Mixture Drawbar 12 to ADSR
  nil, // #1188
  nil, // #1189
  nil, // #1190
  nil, // #1191
  nil, // #1192 Preset Name String [0] (Length Byte)
  nil, // #1193 Preset Name String [1]
  nil, // #1194 Preset Name String [2]
  nil, // #1195 Preset Name String [3]
  nil, // #1196 Preset Name String [4]
  nil, // #1197 Preset Name String [5]
  nil, // #1198 Preset Name String [6]
  nil, // #1199 Preset Name String [7]
  nil, // #1200 Preset Name String [8]
  nil, // #1201 Preset Name String [9]
  nil, // #1202 Preset Name String [10]
  nil, // #1203 Preset Name String [11]
  nil, // #1204 Preset Name String [12]
  nil, // #1205 Preset Name String [13]
  nil, // #1206 Preset Name String [14]
  nil, // #1207 Preset Name String [15]
  nil, // #1208 nicht abgespeicherte Buttons
  nil, // #1209 nicht abgespeicherte Buttons
  nil, // #1210 nicht abgespeicherte Buttons
  nil, // #1211 nicht abgespeicherte Buttons
  nil, // #1212 4 Btn V1
  nil, // #1213 4 Btn V2
  nil, // #1214 4 Btn V3
  nil, // #1215 4 Btn V/C
  nil, // #1216 Transpose +1 UP
  nil, // #1217 Transpose -1 DOWN
  nil, // #1218 nicht abgespeicherte Buttons
  nil, // #1219 nicht abgespeicherte Buttons
  nil, // #1220 Single DB set to Lower
  nil, // #1221 nicht abgespeicherte Buttons
  nil, // #1222 nicht abgespeicherte Buttons
  nil, // #1223 nicht abgespeicherte Buttons
  @AC_SendGMvoiceUpper0, // #1224 Upper GM Layer 1 Voice
  @AC_SendGMupper, // #1225 Upper GM Layer 1 Level
  @AC_SendGMupper, // #1226 Upper GM Layer 1 Harmonic
  @AC_SendGMvoiceUpper1, // #1227 Upper GM Layer 2 Voice
  @AC_SendGMupper, // #1228 Upper GM Layer 2 Level
  @AC_SendGMupper, // #1229 Upper GM Layer 2 Harmonic
  @AC_SendGMupper, // #1230 Upper GM Layer 2 Detune
  nil, // #1231
  @AC_SendGMvoiceLower0, // #1232 Lower GM Layer 1 Voice
  @AC_SendGMlower, // #1233 Lower GM Layer 1 Level
  @AC_SendGMlower, // #1234 Lower GM Layer 1 Harmonic
  @AC_SendGMvoiceLower1, // #1235 Lower GM Layer 2 Voice
  @AC_SendGMlower, // #1236 Lower GM Layer 2 Level
  @AC_SendGMlower, // #1237 Lower GM Layer 2 Harmonic
  @AC_SendGMlower, // #1238 Lower GM Layer 2 Detune
  nil, // #1239
  @AC_SendGMvoicePedal0, // #1240 Pedal GM Layer 1 Voice
  @AC_SendGMpedal, // #1241 Pedal GM Layer 1 Level
  @AC_SendGMpedal, // #1242 Pedal GM Layer 1 Harmonic
  @AC_SendGMvoicePedal1, // #1243 Pedal GM Layer 2 Voice
  @AC_SendGMpedal, // #1244 Pedal GM Layer 2 Level
  @AC_SendGMpedal, // #1245 Pedal GM Layer 2 Harmonic
  @AC_SendGMpedal, // #1246 Pedal GM Layer 2 Detune
  nil, // #1247
  nil, // #1248
  nil, // #1249
  nil, // #1250
  nil, // #1251
  nil, // #1252
  nil, // #1253
  nil, // #1254
  nil, // #1255
  nil, // #1256
  nil, // #1257
  nil, // #1258
  nil, // #1259
  nil, // #1260
  nil, // #1261
  nil, // #1262
  nil, // #1263
  @FH_VibratoToFPGA, // #1264 Vibrato Knob
  nil, // #1265 Organ Model (OSC)
  nil, // #1266 Generator Model Knob
  @AC_SendGating, // #1267 Gating (Keying) Knob
  nil, // #1268 Overall Preset (Temp)
  nil, // #1269 Upper Voice
  nil, // #1270 Lower Voice
  nil, // #1271 Pedal Voice
  @AC_SendGating, // #1272 Level Busbar 16
  @AC_SendGating, // #1273 Level Busbar 5 1/3
  @AC_SendGating, // #1274 Level Busbar 8
  @AC_SendGating, // #1275 Level Busbar 4
  @AC_SendGating, // #1276 Level Busbar 2 2/3
  @AC_SendGating, // #1277 Level Busbar 2
  @AC_SendGating, // #1278 Level Busbar 1 3/5
  @AC_SendGating, // #1279 Level Busbar 1 1/3
  @AC_SendGating, // #1280 Level Busbar 1
  @AC_SendGating, // #1281 Level Busbar 10
  @AC_SendGating, // #1282 Level Busbar 11
  @AC_SendGating, // #1283 Level Busbar 12
  @AC_SendGating, // #1284 Level Busbar 13
  @AC_SendGating, // #1285 Level Busbar 14
  @AC_SendGating, // #1286 Level Busbar 15
  nil, // #1287
  @AC_SendTaper, // #1288 Note Offset Busbar 16
  @AC_SendTaper, // #1289 Note Offset Busbar 5 1/3
  @AC_SendTaper, // #1290 Note Offset Busbar 8
  @AC_SendTaper, // #1291 Note Offset Busbar 4
  @AC_SendTaper, // #1292 Note Offset Busbar 2 2/3
  @AC_SendTaper, // #1293 Note Offset Busbar 2
  @AC_SendTaper, // #1294 Note Offset Busbar 1 3/5
  @AC_SendTaper, // #1295 Note Offset Busbar 1 1/3
  @AC_SendTaper, // #1296 Note Offset Busbar 1
  @AC_SendTaper, // #1297 Note Offset Busbar 10
  @AC_SendTaper, // #1298 Note Offset Busbar 11
  @AC_SendTaper, // #1299 Note Offset Busbar 12
  @AC_SendTaper, // #1300 Note Offset Busbar 13
  @AC_SendTaper, // #1301 Note Offset Busbar 14
  @AC_SendTaper, // #1302 Note Offset Busbar 15
  nil, // #1303
  nil, // #1304
  nil, // #1305
  nil, // #1306
  nil, // #1307
  nil, // #1308
  nil, // #1309
  nil, // #1310
  nil, // #1311
  nil, // #1312
  nil, // #1313
  nil, // #1314
  nil, // #1315
  nil, // #1316
  nil, // #1317
  nil, // #1318
  nil, // #1319
  @FH_VibratoToFPGA, // #1320 Pre-Emphasis (Treble Gain)
  @FH_VibratoToFPGA, // #1321 LC Line Age/AM Amplitude Modulation
  @FH_VibratoToFPGA, // #1322 LC Line Feedback
  @FH_VibratoToFPGA, // #1323 LC Line Reflection
  @FH_VibratoToFPGA, // #1324 LC Line Response Cutoff Frequency
  @FH_VibratoToFPGA, // #1325 LC PhaseLk/Line Cutoff Shelving Level
  @FH_VibratoToFPGA, // #1326 Scanner Gearing (Vib Frequ)
  @FH_VibratoToFPGA, // #1327 Chorus Dry (Bypass) Level
  @FH_VibratoToFPGA, // #1328 Chorus Wet (Scanner) Level
  @FH_VibratoToFPGA, // #1329 Modulation V1/C1
  @FH_VibratoToFPGA, // #1330 Modulation V2/C2
  @FH_VibratoToFPGA, // #1331 Modulation V3/C3
  @FH_VibratoToFPGA, // #1332 Modulation Chorus Enhance
  @FH_VibratoToFPGA, // #1333 Scanner Segment Flutter
  @FH_VibratoToFPGA, // #1334 Preemphasis Highpass Cutoff Frequ
  @FH_VibratoToFPGA, // #1335 Modulation Slope, Preemph HP Phase/Peak
  nil, // #1336 PHR Speed Vari Slow (Temp)
  nil, // #1337 PHR Speed Vari Fast (Temp)
  @FH_PhasingRotorToFPGA, // #1338 PHR Speed Slow (Temp)
  @FH_PhasingRotorToFPGA, // #1339 PHR Feedback (Temp)
  @FH_PhasingRotorToFPGA, // #1340 PHR Level Ph1 (Temp)
  @FH_PhasingRotorToFPGA, // #1341 PHR Level Ph2 (Temp)
  @FH_PhasingRotorToFPGA, // #1342 PHR Level Ph3 (Temp)
  @FH_PhasingRotorToFPGA, // #1343 PHR Level Dry (Temp)
  @FH_PhasingRotorToFPGA, // #1344 PHR Feedback Invert (Temp)
  nil, // #1345 PHR Ramp Delay (Temp)
  @FH_PhasingRotorToFPGA, // #1346 PHR Mod Vari Ph1 (Temp)
  @FH_PhasingRotorToFPGA, // #1347 PHR Mod Vari Ph2 (Temp)
  @FH_PhasingRotorToFPGA, // #1348 PHR Mod Vari Ph3 (Temp)
  @FH_PhasingRotorToFPGA, // #1349 PHR Mod Slow Ph1 (Temp)
  @FH_PhasingRotorToFPGA, // #1350 PHR Mod Slow Ph2 (Temp)
  @FH_PhasingRotorToFPGA, // #1351 PHR Mod Slow Ph3 (Temp)
  nil, // #1352 (RFU)
  @FH_SplitConfigToFPGA, // #1353 Keyboard Split Point if ON
  @FH_SplitConfigToFPGA, // #1354 Keyboard Split Mode
  @FH_OrganParamsToFPGA, // #1355 Keyboard Transpose
  @FH_OrganParamsToFPGA, // #1356 Contact Early Action (Fatar Keybed only)
  @FH_OrganParamsToFPGA, // #1357 No 1' Drawbar when Perc ON
  @AC_SendTaper, // #1358 Drawbar 16' Foldback Mode
  @AC_SendTaper, // #1359 Higher Foldback
  @FH_OrganParamsToFPGA, // #1360 Contact Spring Flex
  @FH_OrganParamsToFPGA, // #1361 Contact Spring Damping
  @FH_OrganParamsToFPGA, // #1362 Percussion Enable On Live DB only
  @FH_OrganParamsToFPGA, // #1363 Fatar Velocity Factor
  nil, // #1364
  nil, // #1365
  nil, // #1366
  nil, // #1367
  @FH_OrganParamsToFPGA, // #1368 MIDI Channel
  @FH_OrganParamsToFPGA, // #1369 MIDI Option
  @AC_SendMIDIccSet, // #1370 MIDI CC Set
  @FH_OrganParamsToFPGA, // #1371 MIDI Swell CC
  @FH_OrganParamsToFPGA, // #1372 MIDI Volume CC
  @AC_SendGM2ena, // #1373 MIDI Local Enable
  nil, // #1374 MIDI Preset CC
  nil, // #1375 MIDI Show CC
  nil, // #1376
  nil, // #1377
  nil, // #1378
  nil, // #1379
  nil, // #1380
  nil, // #1381
  nil, // #1382
  nil, // #1383
  @AC_SendVolumes, // #1384 Preamp Swell Type
  @FH_TuningValsToFPGA, // #1385 TG Tuning Set
  @AC_SendTaper, // #1386 TG Size
  @AC_SendTaper, // #1387 TG Fixed Taper Value
  @FH_WaveBlocksToFPGA, // #1388 TG WaveSet
  @FH_OrganParamsToFPGA, // #1389 TG Flutter
  @FH_OrganParamsToFPGA, // #1390 TG Leakage
  @FH_OrganParamsToFPGA, // #1391 TG Tuning
  @AC_SendTaper, // #1392 TG Cap Set/Tapering
  @AC_SendTaper, // #1393 TG LC Filter Fac
  @AC_SendTaper, // #1394 TG Bottom 16' Octave Taper Val
  @FH_OrganParamsToFPGA, // #1395 Generator Transpose
  nil, // #1396 Generator Model Limit
  @AC_SendVolumes, // #1397 Organ Upper Manual Enable
  @AC_SendVolumes, // #1398 Organ Lower Manual Enable
  @AC_SendVolumes, // #1399 Organ Pedal Enable
  @FH_SendReverb, // #1400 Reverb Level 1
  @FH_SendReverb, // #1401 Reverb Level 2
  @FH_SendReverb, // #1402 Reverb Level 3
  nil, // #1403
  nil, // #1404
  nil, // #1405
  nil, // #1406
  nil, // #1407
  nil, // #1408 Current Mixture Setup Number
  nil, // #1409 Current Vibrato Setup Number
  nil, // #1410 Current Phasing Setup Number
  nil, // #1411 Current Percussion Menu Number
  nil, // #1412 Current Reverb Menu Number
  nil, // #1413
  nil, // #1414
  nil, // #1415
  @AC_SendGating, // #1416 Mixt DB 10, Level from Busbar 9
  @AC_SendGating, // #1417 Mixt DB 10, Level from Busbar 10
  @AC_SendGating, // #1418 Mixt DB 10, Level from Busbar 11
  @AC_SendGating, // #1419 Mixt DB 10, Level from Busbar 12
  @AC_SendGating, // #1420 Mixt DB 10, Level from Busbar 13
  @AC_SendGating, // #1421 Mixt DB 10, Level from Busbar 14
  nil, // #1422
  nil, // #1423
  @AC_SendGating, // #1424 Mixt DB 11, Level from Busbar 9
  @AC_SendGating, // #1425 Mixt DB 11, Level from Busbar 10
  @AC_SendGating, // #1426 Mixt DB 11, Level from Busbar 11
  @AC_SendGating, // #1427 Mixt DB 11, Level from Busbar 12
  @AC_SendGating, // #1428 Mixt DB 11, Level from Busbar 13
  @AC_SendGating, // #1429 Mixt DB 11, Level from Busbar 14
  nil, // #1430
  nil, // #1431
  @AC_SendGating, // #1432 Mixt DB 12, Level from Busbar 9
  @AC_SendGating, // #1433 Mixt DB 12, Level from Busbar 10
  @AC_SendGating, // #1434 Mixt DB 12, Level from Busbar 11
  @AC_SendGating, // #1435 Mixt DB 12, Level from Busbar 12
  @AC_SendGating, // #1436 Mixt DB 12, Level from Busbar 13
  @AC_SendGating, // #1437 Mixt DB 12, Level from Busbar 14
  nil, // #1438
  nil, // #1439
  nil, // #1440
  nil, // #1441
  nil, // #1442
  nil, // #1443
  nil, // #1444
  nil, // #1445
  nil, // #1446
  nil, // #1447
  @AC_SendLeslieLiveParams, // #1448 Rotary Live Control, Horn Slow Time
  @AC_SendLeslieLiveParams, // #1449 Rotary Live Control, Rotor Slow Time
  @AC_SendLeslieLiveParams, // #1450 Rotary Live Control, Horn Fast Time
  @AC_SendLeslieLiveParams, // #1451 Rotary Live Control, Rotor Fast Time
  @AC_SendLeslieLiveParams, // #1452 Rotary Live Control, Horn Ramp Up Time
  @AC_SendLeslieLiveParams, // #1453 Rotary Live Control, Rotor Ramp Up Time
  @AC_SendLeslieLiveParams, // #1454 Rotary Live Control, Horn Ramp Down Time
  @AC_SendLeslieLiveParams, // #1455 Rotary Live Control, Rotor Ramp Down Time
  @AC_SendLeslieLiveParams, // #1456 Rotary Live Control, Speaker Throb Amount
  @AC_SendLeslieLiveParams, // #1457 Rotary Live Control, Speaker Spread
  @AC_SendLeslieLiveParams, // #1458 Rotary Live Control, Speaker Balance
  @AC_SendRotarySpeed, // #1459 Sync PHR
  nil, // #1460
  nil, // #1461
  nil, // #1462
  nil, // #1463
  @AC_RouteDirect, // #1464 ENA_CONT_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1465 ENA_CONT_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1466 ENA_ENV_DB_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1467 ENA_ENV_DB_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1468 ENA_ENV_FULL_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1469 ENA_ENV_FULL_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1470 ENV_TO_DRY_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1471 ENV_TO_DRY_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1472 ENA_CONT_PERC_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1473 ENA_CONT_PERC_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1474 ENA_ENV_PERCMODE_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1475 ENA_ENV_PERCMODE_BITS (MSB), Drawbar 11..8
  @AC_RouteDirect, // #1476 ENA_ENV_ADSRMODE_BITS (LSB), Drawbar 7..0
  @AC_RouteDirect, // #1477 ENA_ENV_ADSRMODE_BITS (MSB), Drawbar 11..8
  nil, // #1478
  nil, // #1479
  @AC_SendPercParams, // #1480 Perc Norm Level
  @AC_SendPercParams, // #1481 Perc Soft Level
  @AC_SendPercParams, // #1482 Perc Long Time
  @AC_SendPercParams, // #1483 Perc Short Time
  @AC_SendPercParams, // #1484 Perc Muted Level
  nil, // #1485
  @AC_SendPercParams, // #1486 Perc Precharge Time
  nil, // #1487 Perc Ena on Live DB only
  nil, // #1488 (RFU)
  nil, // #1489 (RFU)
  @AC_SendGM2ena, // #1490 GM2 Synth Volume
  @AC_SendGM2ena, // #1491 Relative Organ Volume
  @AC_SendPercParams, // #1492 H100 Harp Sustain Time
  @AC_SendPercParams, // #1493 H100 2nd Voice Level
  nil, // #1494 (RFU)
  @NB_SetLEDdimmer, // #1495 LED Dimmer
  nil, // #1496 2ndDB Select Voice Number
  nil, // #1497 Vibrato Knob Mode
  nil, // #1498 CommonPreset Save/Restore Mask
  nil, // #1499 (not used)
  nil, // #1500 (not used)
  nil, // #1501 Various Configurations
  nil, // #1502 Additional Tab Panels are Switch Inputs (obsolete)
  nil, // #1503 ADC Configuration
  nil, // #1504 (not used)
  nil, // #1505 (not used)
  nil, // #1506 Pedal Drawbar Configuration
  nil, // #1507 ADC Scaling
  nil, // #1508 (not used)
  nil, // #1509 HX3.5 Device Type
  nil, // #1510 Preset/EEPROM Structure Version
  nil  // #1511 Magic Flag
);

var
  ac_temp_GeneratorGroup: Array[0..15] of byte;
  ac_temp_KeyboardGroup: Array[0..15] of byte;
  ac_temp_VibratoGroup: Array[0..15] of byte;
  ac_collect_action_array:Array[0..ord(ta_last_entry)] of boolean;
  
  ac_LiveUpperVoice,
  ac_LiveLowerVoice, ac_LivePedalVoice: Byte;
  
  ac_LiveUpperVoice_old,
  ac_LiveLowerVoice_old, ac_LivePedalVoice_old: Byte;

  ac_CommonPreset_old: Byte;

  ac_preset_changed: Boolean;
  ac_edit_idx: Integer;
  
  ac_mb_transpose_up, ac_mb_transpose_down: Boolean;
  ac_proc: procedure;
  ac_proc_array: Array[0..15] of procedure;

// #############################################################################
// #############################################################################
// #############################################################################

procedure AC_SendTaper;
begin
  FH_KeymapToFPGA;
  FH_TaperingToFPGA(edit_TG_TaperCaps);
  FH_NoteHighpassFilterToFPGA;
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Tapering');
{$ENDIF}
end;

procedure AC_RouteDirect;
begin
  FH_UpperRoutingToFPGA;
  FH_UpperDrawbarsToFPGA;
  FH_PercussionParamsToFPGA; // Perc-Bits könnten sich geändert haben
end;

procedure AC_RouteOrgan;
begin
  FH_OrganParamsToFPGA;
  FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Organ Params');
{$ENDIF}
end;

procedure AC_SendGating;
begin
  // B3/H100/EG Mode Tabs
  // Percussion, EG/H100 Modus, Tastenkontakt-Umschaltung
  FH_OrganParamsToFPGA;
  FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
  FH_UpperDrawbarsToFPGA;   // wg. EG Percussion
  FH_LowerDrawbarsToFPGA;
  FH_PercussionParamsToFPGA;
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Gating/Upr/Lwr/Perc');
{$ENDIF}
end;

procedure AC_SendInserts;
begin
  FH_InsertsToFPGA;
  AC_SendVolumes;
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Inserts');
{$ENDIF}
end;


procedure AC_SendPercParams;
begin
{$IFDEF ALLINONE}
  FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
  FH_UpperDrawbarsToFPGA;   // wg. Percussion Muted Level
  FH_PercussionParamsToFPGA;
{$ELSE}
  FH_UpperDrawbarsToFPGA;   // wg. Percussion Muted Level
  FH_PercussionParamsToFPGA;
{$ENDIF}
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC Perc');
{$ENDIF}
end;

procedure AC_SendGM2ena;
begin
  m:= (edit_LocalEnable shl 4) or edit_MIDI_Channel;
  MIDI_SendNRPN($357F, m); // Kanal und Freigabe für SAM5504
  AC_SendVolumes;
  ToneChanged:=true;
{$IFDEF DEBUG_AC}
  writeln(serout, '/ AC GM Volume');
{$ENDIF}
end;

procedure AC_SendRotarySpeed;
begin
  // zum Extension Board, an I2C Vibrato-Knob-Port angeschlossen
  VKPORT_LESFAST:= edit_LogicalTab_LeslieFast and edit_LogicalTab_LeslieRun;
  VKPORT_LESRUN:= edit_LogicalTab_LeslieRun and (not edit_LogicalTab_LeslieFast);
  // an PL29 PREAMP CTRL
  PREAMP_LESFAST:= VKPORT_LESFAST;
  PREAMP_LESRUN:= VKPORT_LESRUN;
  MIDI_SendVent;
end;

procedure AC_SendMIDIccSet;
begin
  NB_CCarrayFromDF(edit_MIDI_CC_Set);   // setzt UseSustainSostMask
  MIDI_SendSustainSostEnable;
  edit_MIDI_CC_Set_flag:= c_sendfpga_mask;
end;

procedure AC_SetDetent;
begin
// Mittelpositions-Default geändert, nach zugehörigem ADC suchen
  for i:= 0 to 87 do
    n:= ADC_remaps[i];
    if n in [85, 112, 115, 118] then
      ADC_changed[i]:= true;
    endif;
  endfor;
  AC_SendTrimPots;
  AC_SendVolumes;
end;

procedure AC_SendGMvoiceUpper0;
begin
end;

procedure AC_SendGMvoiceUpper1;
begin
end;

procedure AC_SendGMupper;
begin
end;

procedure AC_SendGMvoiceLower0;
begin
end;

procedure AC_SendGMvoiceLower1;
begin
end;

procedure AC_SendGMlower;
begin
end;

procedure AC_SendGMvoicePedal0;
begin
end;

procedure AC_SendGMvoicePedal1;
begin
end;

procedure AC_SendGMpedal;
begin
end;

// #############################################################################
// #############################################################################
// #############################################################################

procedure AC_sendmsg(const idx: Integer; new_val: Byte; var flags: byte);
// my_param muss zwischen 1000 und 1511 liegen!
// my_mask gibt Ziel der Message an:
// c_sendfpga:Byte = 0;
// c_sendserial:Byte = 1;
// c_sendmidicc:Byte = 2;
// c_sendsysex:Byte = 3;
var
  param: Integer;
begin
  param:= idx + 1000;
  if Bit(flags, c_sendserial) then  // als Binary-Message senden
    NB_SendBinaryVal(param, new_val);
    Excl(flags, c_sendserial);
  endif;
  
{$IFDEF ALLINONE}
  if Bit(flags, c_sendmidicc) then  // als MIDI-CC senden, über Tabelle
    MIDI_SendIndexedController(idx, new_val);
    Excl(flags, c_sendmidicc);
  endif;
  
  if Bit(flags, c_sendsysex) then  // als SysEx senden
    MIDI_SendSysExParam(param, Integer(new_val));
    Excl(flags, c_sendsysex);
  endif;
{$ENDIF}
end;

procedure AC_sendmsg_OR_flag(const idx: Integer; const new_val, or_flags: byte);
// wie oben, holt jedoch vorher Flags aus edit_array_flag und
// setzt dieses neu
var
  flags: Byte;
begin
  flags:= edit_array_flag[idx] or or_flags;
  AC_sendmsg(idx, new_val, flags);
  edit_array_flag[idx]:= flags;
end;

procedure AC_sendmsg_arrval_OR_flag(const idx: Integer; const or_flags: byte);
// wie oben, holt jedoch vorher Wert aus edit_array
begin
  AC_sendmsg_OR_flag(idx, edit_array[idx], or_flags);
end;


{$IFDEF ALLINONE}
procedure AC_HandleVoiceChangeUpper;
var was_live: Boolean;
begin
  // Voice Change Upper Manual
  if (edit_ADCconfig >= 2) then
    // neue Umschalt-Logik in ADC_ChangesToEdit
    if UpperIsLive then
      ADC_ReadAll_24;
      ADC_ReadAll_64;
      ADC_SetChangedUpper;  // Force ADC Update
    else
      ADC_ResetTimersUpper;    // ADC-Kanäle unempfindlich machen (abgelaufen!)
      ADC_ChangeStateAll(false);
      LoadUpperVoice(edit_UpperVoice);
    endif;
  else // Expander, keine Analogeingänge
    was_live:= (edit_UpperVoice_old = 0)
    or (edit_UpperVoice_old = edit_2ndDBselect);
    if (not UpperIsLive) then
      if was_live then
        NB_copy_Upper_live_to_temp;  // war Live, ist jetzt Preset
      endif;
      LoadUpperVoice(edit_UpperVoice);
    elsif (not was_live) then
      NB_copy_Upper_temp_to_live;    // war Preset, ist jetzt Live
    endif;
  endif;
  FH_RouteOrgan;  // wg. Percussion-Freigabe
  CommonPresetInvalid:= true;
  VoiceUpperInvalid:= false;
end;

// -----------------------------------------------------------------------------

procedure AC_HandleVoiceChangeLower;
var was_live: Boolean;
begin
  // Voice Change Lower Manual
  if (edit_ADCconfig >= 2) then
    // neue Umschalt-Logik in ADC_ChangesToEdit
    if LowerIsLive then
      ADC_ReadAll_24;
      ADC_ReadAll_64;
      ADC_SetChangedLower;  // Force ADC Handling
    else
      ADC_ResetTimersLower; // ADC-Kanäle unempfindlich machen (abgelaufen!)
      ADC_ChangeStateAll(false);
      LoadLowerVoice(edit_LowerVoice);
    endif;
  else // Expander, keine Analogeingänge
    was_live:= (edit_LowerVoice_old = 0)
    or (edit_LowerVoice_old = edit_2ndDBselect);
    if (not LowerIsLive) then
      if was_live then
        NB_copy_Lower_live_to_temp;  // war Live, ist jetzt Preset
      endif;
      LoadLowerVoice(edit_LowerVoice);
    elsif (not was_live) then
      NB_copy_Lower_temp_to_live;    // war Preset, ist jetzt Live
    endif;
  endif;
  CommonPresetInvalid:= true;
  VoiceLowerInvalid:= false;
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
        NB_copy_pedal_live_to_temp;  // war Live, ist jetzt Preset
      endif;
      LoadPedalVoice(edit_PedalVoice);
    elsif (not was_live) then
      NB_copy_pedal_temp_to_live;    // war Preset, ist jetzt Live
    endif;
  endif;
  VoicePedalInvalid:= false;
  CommonPresetInvalid:= true;
end;

{$ENDIF}


// #############################################################################
// Action-Dispatcher
// Action-Tabellen entscheiden, was bei Parameter-Änderungen tu tun ist
// #############################################################################

procedure AC_SendPHRprgm;
var my_phrset: byte;
begin
{$IFDEF ALLINONE}
  if edit_LogicalTab_PHR_Celeste and edit_LogicalTab_PHR_Ensemble then
    my_phrset:= 6; // Vibrato 1, dünn
{$ELSE}
  if edit_LogicalTab_PHR_WersiBoehm and edit_LogicalTab_PHR_Ensemble then
    my_phrset:= 6; // Vibrato 1, dünn
{$ENDIF}
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

const
  c_OrganDefaultSets: Array[0..7, 0..9] of byte = (
  // 0  1   2   3   4  5  6  7  8  9
    (0, 0, 91, 35,  0, 3, 1, 7, 1, 70),     // 0 Hammond B3 default (aus EEPROM)
    (0, 0, 91, 35,  3, 3, 5, 7, 0, 60),     // 1 Hammond B3 old
    (0, 0, 91, 35,  2, 3, 3, 7, 4, 70),     // 2 Hammond M3/M100
    (0, 0, 96, 35,  1, 2, 3, 7, 3, 70),     // 3 Hammond H100
    (1, 1, 96, 35,  4, 0, 0, 7, 4, 60),     // 4 TOS/LSI Sine
    (1, 1, 96, 35,  7, 0, 0, 7, 4, 60),     // 5 TOS/LSI Square
    (1, 2, 96, 35,  6, 0, 0, 7, 4, 60),     // 6 Single Note Gen
    (2, 1, 84, 35,  7, 0, 0, 7, 5, 100)     // 7 CheesyCombo
    );
{
0  edit_PreampSwellType,
1  edit_TG_TuningSet,
2  edit_TG_Size,
3  edit_TG_FixedTaperVal,
4  edit_TG_WaveSet,
5  edit_TG_Flutter,
6  edit_TG_Leakage,
7  edit_TG_tuning,
8  edit_TG_CapSet,
9  edit_TG_FilterFac

Waveset: 0..3 Hammond 25-38% k2,
4: Sinus 2% THD
5: Sägezahn gefiltert für Strings oder Cheesy
6: Sinus 12% k3 für Conn
7: Sinus Square 8% k3, 5% k5
}

procedure AC_SetGenVibMode;
// anhand edit_GenVibMode
// Grundeinstellung Tapering, Wave, Vibrato, Mixturen anhand my_generator setzen
begin
  // B3 Defaults laden
  for i:= 0 to 10 do
    if i <> 7 then  // ohne Tuning
      edit_GeneratorGroup[i]:= eep_GeneratorGroup[i];
    endif;
  endfor;
  FillBlock(@edit_GeneratorGroup_flag, 11, CurrentSendFlags);

  // Generator-Grundeinstellung
  // 0..2 = B3, 3 = H100, 4 = TOS/LSI Sine,
  // 5 = TOS/LSI Square, 6 = SNG Conn, 7 = Cheesy
  if edit_GenVibMode > 0 then
    for i:= 0 to 9 do
      if (i <> 3) and (i <> 7) then // ohne Fixed Taper, ohne Tuning
        edit_GeneratorGroup[i]:= c_OrganDefaultSets[edit_GenVibMode, i];
      endif;
    endfor;
  endif;
  // Generator-Grundeinstellung
  // 0..2 = B3, 3 = H100, 4 = TOS/LSI Sine,
  // 5 = TOS/LSI Square, 6 = SNG Conn, 7 = Cheesy
  for i:= 5 to 15 do  // Für Kontakt-Einstellung
    edit_KeyboardGroup[i]:= eep_KeyboardGroup[i];
    edit_KeyboardGroup_flag[i]:= CurrentSendFlags;
  endfor;
  case edit_GenVibMode of
    1:  // B3 old
      edit_ContSpringDmp:= valueTrimLimit(eep_ContSpringDmp + 2, 0, 15);
      edit_ContSpringFlx:= valueTrimLimit(eep_ContSpringFlx + 3, 0, 15);
      |
    2:  // M3/M100
      edit_HighFoldbackOn:= false;
      edit_PercEnaOnLiveDBonly:= false;
      |
    3:  // H100
      edit_ContSpringDmp:= valueTrimLimit(eep_ContSpringDmp - 2, 0, 15);
      edit_ContSpringFlx:= valueTrimLimit(eep_ContSpringFlx - 3, 0, 15);
      edit_HighFoldbackOn:= true;
      edit_DB16_FoldbMode:= 1;
      edit_PercEnaOnLiveDBonly:= false;
      |
    4, 5, 6:  // LSI/SNG
      edit_ContSpringFlx:= 2;
      edit_ContSpringDmp:= 1;
      edit_HighFoldbackOn:= true;
      edit_DB16_FoldbMode:= 1;
      edit_PercEnaOnLiveDBonly:= false;
      |
    7: // CheesyCombo
      edit_ContSpringFlx:= 0;
      edit_ContSpringDmp:= 0;
      edit_HighFoldbackOn:= false;
      edit_DB16_FoldbMode:= 3;
      edit_PercEnaOnLiveDBonly:= false;
      |
  endcase;
  // Vibrato-Presets jetzt nach Generatormodell
  NB_LoadVibatoSet(edit_GenVibMode);
  NB_LoadMixtureSet(edit_GenVibMode);
  AC_sendmsg_OR_flag(0266, edit_GenVibMode, CurrentSendFlags);  //  für TouchOSC
  edit_GenVibMode_flag:= c_sendfpga_mask;
end;

procedure AC_PreconfigModel;
// Organ Model Preconfig anhand edit_OrganSetup 0..2
// Generator-Grundeinstellung
// Tapering, Wave, Vibrato, Mixturen, Fußlagen-Offsets
// 0..2 = B3, 3 = H100, 4 = TOS/LSI Sine,
// 5 = TOS/LSI Square, 6 = SNG Conn, 7 = Cheesy
// OrganSetup = Keying-Grundeinstellung
// 0 'B3/9 DrB   ',  // edit_GatingMode=0, edit_GenVibMode=0
// 1 'H100/12 Drb',  // edit_GatingMode=1, edit_GenVibMode=3
// 2 'ElectronGat',  // edit_GatingMode=2, edit_GenVibMode=4
// 3 'EG PercDrwb',  // edit_GatingMode=3, edit_GenVibMode=5
// 4 'EG TimeDrwb'); // edit_GatingMode=4, edit_GenVibMode=6
begin
  if edit_OrganSetup < 5 then
    edit_GatingMode:= edit_OrganSetup;
    if edit_OrganSetup = 0 then
      if edit_GenVibMode > 2 then
        edit_GenVibMode:= 0; // Falls H100 oder höher
      endif;
    else
      edit_GenVibMode:= edit_OrganSetup + 2;
    endif;
    if edit_OrganSetup < 2 then // initialisieren, weil ADS(R) nicht auf Page
      edit_PreampSwellType:= 0;
      edit_PedalAttack:= 0;
      edit_PedalAttack_flag:= CurrentSendFlags;
      edit_PedalDecay:= 0;
      edit_PedalDecay_flag:= CurrentSendFlags;
      edit_PedalSustain:= 127;
      edit_PedalSustain_flag:= CurrentSendFlags;
      edit_PedalADSRharmonics:= 64;
      edit_PedalADSRharmonics_flag:= CurrentSendFlags;
    else
      edit_PreampSwellType:= 1;
    endif;
    edit_PreampSwellType_flag:= CurrentSendFlags;
  endif;
  AC_SetGenVibMode;
  AC_sendmsg_OR_flag(0267, edit_GatingMode, CurrentSendFlags);  //  für TouchOSC
  edit_GatingMode_flag:= c_sendfpga_mask;
  edit_GenVibMode_flag:= c_sendfpga_mask;
end;

// #############################################################################

procedure send_osc_colors;
// Red 0, Green 1, Blue 2, Yellow 3, Purple 4, Gray 5, Orange 6, Brown 7, Pink 8
var idx: Integer;
begin
  // für TouchOSC: Farben setzen
  if (ConnectMode = t_connect_osc_midi) then
    case edit_GatingMode of
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
  elsif (ConnectMode = t_connect_osc_serial) then
    writeln(serOut); // resync
    mdelay(5);
    // Red 0, Green 1, Blue 2, Yellow 3, Purple 4, Gray 5, Orange 6, Brown 7, Pink 8
    if edit_GatingMode >= 2 then
      for idx := 1048 to 1051 do
        write(serout, '/param/' + IntToStr(idx) + '/color=');  // ADSR Drawbars
        case edit_GatingMode of
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
      case edit_GatingMode of
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

procedure send_block_upper;
// für Preset-Änderungen
begin
  if Bit(CurrentSendFlags, c_sendserial) then
    // DB-Änderungen sofort als Block senden
    NB_SendBinaryBlock(1000, 12);
  else
    for ac_edit_idx:= 0 to 11 do
      AC_sendmsg_arrval_OR_flag(ac_edit_idx, c_sendmidicc_mask);
    endfor;
  endif;
end;

procedure send_block_lower;
// für Preset-Änderungen
begin
  if Bit(CurrentSendFlags, c_sendserial) then
    // DB-Änderungen sofort als Block senden
    NB_SendBinaryBlock(1016, 12);
  else
    for ac_edit_idx:= 16 to 23 do
      AC_sendmsg_arrval_OR_flag(ac_edit_idx, c_sendmidicc_mask);
    endfor;
  endif;
end;

procedure send_block_pedal;
// für Preset-Änderungen
begin
  if Bit(CurrentSendFlags, c_sendserial) then
    // DB-Änderungen sofort als Block senden
    NB_SendBinaryBlock(1032, 12);
    NB_SendBinaryBlock(1072, 4);
  else
    for ac_edit_idx:= 32 to 43 do
      AC_sendmsg_arrval_OR_flag(ac_edit_idx, c_sendmidicc_mask);
    endfor;
    for ac_edit_idx:= 72 to 75 do
      AC_sendmsg_arrval_OR_flag(ac_edit_idx, c_sendmidicc_mask);
    endfor;
  endif;
end;

procedure reset_gatingmode_tabs;
begin
  // edit_LogicalTab_H100_Mode etc. löschen
  for i:= 0 to 3 do  // #1152 bis #1155
     edit_LogicalTabs_KeyingModes[i]:= false;
     edit_LogicalTabs_KeyingModes_flag[i]:= 0;
  endfor;
end;

procedure send_gatingmode_tabs;
begin
  // edit_LogicalTab_H100_Mode etc. senden
  for ac_edit_idx:= 152 to 155 do  // #1152 bis #1155
    AC_sendmsg_arrval_OR_flag(ac_edit_idx, CurrentSendFlags); // komplett neu senden!
  endfor;
  AC_sendmsg_OR_flag(0265, edit_OrganSetup, CurrentSendFlags);  //  für TouchOSC
  AC_sendmsg_OR_flag(0267, edit_GatingMode, CurrentSendFlags);  //  für TouchOSC umleiten
  for i:= 0 to 3 do  // #1152 bis #1155
     edit_LogicalTabs_KeyingModes_flag[i]:= 0;
  endfor;
  edit_GatingMode_flag:= CurrentSendFlags;
  edit_OrganSetup_flag:= c_sendfpga_mask;
end;

// #############################################################################

procedure AC_MomentaryControls;
// Up/Down-Buttons (Momentary) behandeln
// Button-LEDs werden erst nach Ablauf von ActivityTimer zurückgesetzt.
// Dadurch ist es möglich, gleichzeitige Betätigung mehrerer Buttons
// zu erkennen.
// Hier: Beide Transpose-Buttons zugleich setzen Transponierwert auf 0 zurück.
begin
  if edit_LogicalTab_TP_up_flag > 0 then   // ON oder OFF!
    edit_LogicalTab_TP_up_flag:= 0;
    ac_mb_transpose_up:= true;             // ON bis Timer zuschlägt
    inc(edit_KeyTranspose);
    edit_KeyTranspose_flag:= CurrentSendFlags;
    setsystimer(ActivityTimer, 75);
    if ac_mb_transpose_down then           // beide gedrückt?
      edit_KeyTranspose:= 0;
    endif;
  endif;

  if edit_LogicalTab_TP_down_flag > 0 then  // ON oder OFF!
    edit_LogicalTab_TP_down_flag:= 0;
    ac_mb_transpose_down:= true;            // ON bis Timer zuschlägt
    dec(edit_KeyTranspose);
    edit_KeyTranspose_flag:= CurrentSendFlags;
    setsystimer(ActivityTimer, 75);
    if ac_mb_transpose_up then              // beide gedrückt?
      edit_KeyTranspose:= 0;
    endif;
  endif;
  if edit_KeyTranspose = 0 then
    edit_LogicalTab_TP_up:= false;
    edit_LogicalTab_TP_down:= false;
  elsif edit_KeyTranspose > 127 then          // negativer Wert
    edit_LogicalTab_TP_up:= false;
    edit_LogicalTab_TP_down:= true;    // Blinkt solange < 0
  else
    edit_LogicalTab_TP_up:= true;      // Blinkt solange > 0
    edit_LogicalTab_TP_down:= false;
  endif;
end;

procedure AC_MomentaryControlsTimerElapsed;
// wird aus Main Tasks aufgerufen, wenn AcivityTimer abgelaufen ist
// Aktivierte Momentary-Buttons wieder zurücksetzen
begin
  ac_mb_transpose_up:= false;
  ac_mb_transpose_down:= false;
end;

// #############################################################################

procedure AC_MutualControls;
// Behandlung sich gegenseitig beeinflussender Bedienelemente
// und Presets (würden nach AC_CollectChanges nicht mehr ausgeführt)
// Später AC_CollectChanges zum Zurücksetzen der alten Werte aufrufen!
var
  any_change, resend_osc_colors: boolean;
  any_gating_tab, is_b3, is_primary_upperdb: Boolean;
  any_gating_tab_flag: Byte;
begin
  resend_osc_colors:= false;
  ac_preset_changed:= false;  // wird für GM-Voicenamen-Unterdrückung gebraucht

{$IFDEF ALLINONE}

  if (edit_CommonPreset <> edit_CommonPreset_old)
  or (edit_CommonPreset_flag <> 0) then

    edit_CommonPreset_flag:= 0;
    ac_CommonPreset_old:= edit_CommonPreset_old;
    edit_CommonPreset_old:= edit_CommonPreset;

    // Preset geändert, PRE-LOAD in BlockArray
{$IFDEF DEBUG_AC}
    writeln(serout,'/ AC Requested Preset ' + bytetostr(edit_CommonPreset));
{$ENDIF}
    PresetPreview:= false;
    AC_sendmsg_OR_flag(0268, edit_CommonPreset, CurrentSendFlags);
    if edit_CommonPreset = 0 then
      setsystimer(PresetLoadTimer, 5); // 10 ms bis zum Laden
      edit_PresetNameStr:= c_PresetNameStr0;
    else
      if DF_presetToBlockArray(edit_CommonPreset) then
        edit_PresetNameStr:= block_PresetNameStr;
        setsystimer(PresetLoadTimer, 50); // 100 ms bis zum Laden
      else
{$IFDEF DEBUG_AC}
        writeln(serout, '/ AC Preset not initalized!');
{$ENDIF}
        edit_PresetNameStr:= '(empty)';
        PresetLoadRequest:= false;
        setsystimer(PresetLoadTimer, 5);
      endif;
    endif;
    if ConnectMode = t_connect_osc_serial then
      writeln(serOut);
      writeln(serOut, '/label_preset="' + edit_PresetNameStr + '"');
    endif;
    MenuIndex_Requested:= c_MenuCommonPreset;  // Menu dauerhaft wechseln
    // nicht laden wenn zum Speichern vorgesehen
    PresetLoadRequest:= not PresetStoreRequest;
  endif;
  
  if PresetLoadRequest and IsSysTimerZero(PresetLoadTimer) then
    PresetLoadRequest:= false;
    ac_preset_changed:= true;  // wird für GM-Voicenamen-Unterdrückung gebraucht
    if (edit_CommonPreset = 0) then
      // Live-Einstellung. Vorherige Werte Laden
      NB_copy_common_BlockArrayOrTemp_to_live(true); // vorherige Werte nehmen
      if edit_ADCconfig >= 2 then
        AC_HandleVoiceChangeUpper;
        AC_HandleVoiceChangeLower;
        AC_HandleVoiceChangePedal;
      endif;
      if (edit_ADCconfig > 1) then
        ADC_ResetTimersAll;
      endif;
      SWI_ForceSwitchReload;     // Schalter-Eingänge neu einlesen
      VoiceUpperInvalid:= false;   // kein Blinken der Preset-LEDs
      VoiceLowerInvalid:= false;
      VoicePedalInvalid:= false;
    else
      // Common Preset laden
      if (ac_CommonPreset_old = 0) then
        NB_copy_common_live_to_temp;  // Live-Einstellung merken
      endif;
      // hole edit_CommonPreset, Voice-Nummern bleiben
      NB_copy_common_BlockArrayOrTemp_to_live(false);
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
      FillBlock(@edit_LogicalTab_SpecialBtns, 16, 0);
      FillBlock(@edit_LogicalTab_SpecialBtns_flag, 16, 0);
    endif;

    MenuIndex_Requested:= c_MenuCommonPreset; // zurück zum Hauptmenü

    edit_OrganSetup_flag:= 0;
    edit_GenVibMode_flag:= 0; // Neueinstellung verhindern, Einzelparameter
    AC_sendmsg_OR_flag(0266, edit_GenVibMode, c_sendmidicc_mask);
    MIDI_SendController(0, edit_PresetCC, edit_CommonPreset); // Default: Bank Select LSB
    if ConnectMode = t_connect_osc_serial then
      MIDI_RequestAllGMnames; // werden für Anzeige gebraucht
    endif;
    resend_osc_colors:= true;
    CommonPresetInvalid:= false;
    NB_VibknobToVCbits;
    midi_DisablePercussion:= false;
  endif;
  
  if (edit_UpperVoice <> edit_UpperVoice_old) or (edit_UpperVoice_flag <> 0) then
    edit_UpperVoice_flag:= 0;
    AC_HandleVoiceChangeUpper;
    MIDI_SendProgramChange(0, edit_UpperVoice);
    AC_sendmsg_OR_flag(0269, edit_UpperVoice, CurrentSendFlags);
    send_block_upper; // DB-Änderungen sofort als Block senden
    if (not ac_preset_changed) then
      MenuIndex_Splash:= c_MenuCommonPreset + 1; // neues Menü anfordern
    endif;
    edit_UpperVoice_old:= edit_UpperVoice;
    midi_DisablePercussion:= false;
  endif;
  
  if (edit_LowerVoice <> edit_LowerVoice_old) or (edit_LowerVoice_flag <> 0) then
    edit_LowerVoice_flag:= 0;
    AC_HandleVoiceChangeLower;
    MIDI_SendProgramChange(1, edit_LowerVoice);
    AC_sendmsg_OR_flag(0270, edit_LowerVoice, CurrentSendFlags);
    send_block_lower; // DB-Änderungen sofort als Block senden
    if (not ac_preset_changed) then
      MenuIndex_Splash:= c_MenuCommonPreset + 2; // neues Menü anfordern
    endif;
    edit_LowerVoice_old:= edit_LowerVoice;
    VoiceLowerInvalid:= false;
  endif;
  
  if (edit_PedalVoice <> edit_PedalVoice_old) or (edit_PedalVoice_flag <> 0) then
    edit_PedalVoice_flag:= 0;
    AC_HandleVoiceChangePedal;
    MIDI_SendProgramChange(2, edit_PedalVoice);
    AC_sendmsg_OR_flag(0271, edit_PedalVoice, CurrentSendFlags);
    send_block_pedal; // DB-Änderungen sofort als Block senden
    if (not ac_preset_changed) then
      MenuIndex_Splash:= c_MenuCommonPreset + 3; // neues Menü anfordern
    endif;
    edit_PedalVoice_old:= edit_PedalVoice;
    VoicePedalInvalid:= false;
  endif;

  // ---------------------------------------------------------------------------

  // OrganSetup, Änderungen nur über Menu oder OSC/MIDI,
  // NICHT über Preset. Belegt einige Parameter für jeweiliges Modell.
  if edit_OrganSetup_flag > 0 then
    reset_gatingmode_tabs; // alle löschen = edit_GatingMode 0 (B3)
    AC_sendmsg_OR_flag(0265, edit_OrganSetup, CurrentSendFlags);  //  für TouchOSC
    AC_PreconfigModel; // setzt Gating Mode etc anhand edit_OrganSetup
    edit_OrganSetup_flag:= c_sendfpga_mask;
    resend_osc_colors:= true;
  endif;


  // ---------------------------------------------------------------------------

  // Gating-Mode, 4 Radio Buttons mit gegenseitiger Auslösung und OFF
  // Menü-Item oder Knob (RFU) - falls Änderungen über Menü
  
  if edit_GatingMode_flag > 0 then
    // Knob geändert. Zugehörige Tabs neu setzen und senden
    reset_gatingmode_tabs; // alle löschen = edit_GatingMode 0 (B3)
    case edit_GatingMode of
      1:
      edit_LogicalTab_H100_Mode:= true;
      |
      2:
      edit_LogicalTab_EG_mode:= true;
      |
      3:
      edit_LogicalTab_EG_PercMode:= true;
      |
      4:
      edit_LogicalTab_EG_TimeBendMode:= true;
      |
    endcase;
    edit_OrganSetup:= valueTrimLimit(edit_GatingMode, 0, 2);
    edit_OrganSetup_flag:= 0;
    send_gatingmode_tabs;
    resend_osc_colors:= true;
    NB_ValidateExtendedParams;  // Legt gültige Menüs und Restore-Freigaben an
  endif;

  any_gating_tab:= edit_LogicalTab_H100_Mode or edit_LogicalTab_EG_mode
    or edit_LogicalTab_EG_PercMode or edit_LogicalTab_EG_TimeBendMode;
    
  any_gating_tab_flag:= edit_LogicalTab_H100_Mode_flag or edit_LogicalTab_EG_mode_flag
    or edit_LogicalTab_EG_PercMode_flag or edit_LogicalTab_EG_TimeBendMode_flag;

  if (not any_gating_tab) and (any_gating_tab_flag > 0) then
    // irgendeine ON-Stellung auf ALL OFF geändert
    reset_gatingmode_tabs; // alle löschen
    edit_GatingMode:= 0;
    edit_OrganSetup:= 0;
    send_gatingmode_tabs;  // löscht auch Tab-Flags
    resend_osc_colors:= true;
  endif;
  
  if edit_LogicalTab_H100_Mode and (edit_LogicalTab_H100_Mode_flag > 0) then
    reset_gatingmode_tabs; // alle löschen
    edit_LogicalTab_H100_Mode:= true;
    edit_GatingMode:= 1;
    edit_OrganSetup:= 1;
    send_gatingmode_tabs;  // löscht auch Tab-Flags
    resend_osc_colors:= true;
  endif;

  if edit_LogicalTab_EG_mode and (edit_LogicalTab_EG_mode_flag > 0)  then
    reset_gatingmode_tabs; // alle löschen
    edit_LogicalTab_EG_mode:= true;
    edit_GatingMode:= 2;
    edit_OrganSetup:= 2;
    send_gatingmode_tabs;  // löscht auch Tab-Flags
    resend_osc_colors:= true;
  endif;

  if edit_LogicalTab_EG_PercMode and (edit_LogicalTab_EG_PercMode_flag > 0)  then
    reset_gatingmode_tabs; // alle löschen
    edit_LogicalTab_EG_PercMode:= true;
    edit_GatingMode:= 3;
    edit_OrganSetup:= 2;
    send_gatingmode_tabs;  // löscht auch Tab-Flags
    resend_osc_colors:= true;
  endif;
  
  if edit_LogicalTab_EG_TimeBendMode and (edit_LogicalTab_EG_TimeBendMode_flag > 0)  then
    reset_gatingmode_tabs; // alle löschen
    edit_LogicalTab_EG_TimeBendMode:= true;
    edit_GatingMode:= 4;
    edit_OrganSetup:= 2;
    send_gatingmode_tabs;  // löscht auch Tab-Flags
    resend_osc_colors:= true;
  endif;

  // ---------------------------------------------------------------------------
  
  // Percussion-Abschaltung
  is_b3:= (edit_GatingMode = 0); // and (edit_CommonPreset = 0);
  is_primary_upperdb:= (edit_UpperVoice = 0) or (edit_CommonPreset > 0);
  any_change:= DisablePercussion;

  DisablePercussion:= (edit_PercEnaOnLiveDBonly and is_b3 and (not is_primary_upperdb))
                      or midi_DisablePercussion;

  if DisablePercussion <> any_change then
    // erzwingt Senden von Upper und Perc über ta_perc_param
    edit_PercEnaOnLiveDBonly_flag:= c_sendfpga_mask;
  endif;
  any_change:= DisableDB1;
  DisableDB1:= edit_NoDB1_atPerc and is_primary_upperdb and is_b3;
  if DisableDB1 <> any_change then
    // erzwingt Senden von Upper und Perc über ta_perc_param
    edit_PercEnaOnLiveDBonly_flag:= c_sendfpga_mask;
  endif;

  // Generator Mode, ta_generator_knob
  // muss vorab erfolgen, damit Parameter-Änderungen in Schleife erfolgen
  if (edit_GenVibMode_flag > 0) then
    AC_SetGenVibMode;
    edit_GenVibMode_flag:= c_sendfpga_mask;
  endif;


  if edit_MIDI_CC_Set_flag > 0 then
    NB_CCarrayFromDF(edit_MIDI_CC_Set);   // setzt UseSustainSostMask
    MIDI_SendSustainSostEnable;
    edit_MIDI_CC_Set_flag:= c_sendfpga_mask;
  endif;

  // ---------------------------------------------------------------------------

  // Percussion Modes über Menü eingestellt?
  if (MenuIndex = c_PercMenu) and (edit_MenuPercMode < 7) then
    // Menü-Anfangswert korrigieren (min)
    edit_MenuPercMode:= 7; // Perc OFF, alle anderen ON
  endif;
  if edit_MenuPercMode_flag > 0 then // über Menü geändert
    edit_LogicalTab_PercOn:= Bit(edit_MenuPercMode, 3);
    edit_LogicalTab_PercOn_flag:= CurrentSendFlags;
    
    edit_LogicalTab_PercSoft:= Bit(edit_MenuPercMode, 2);
    edit_LogicalTab_PercSoft_flag:= CurrentSendFlags;
    
    edit_LogicalTab_PercFast:= Bit(edit_MenuPercMode, 1);
    edit_LogicalTab_PercFast_flag:= CurrentSendFlags;
    
    edit_LogicalTab_Perc3rd:= Bit(edit_MenuPercMode, 0);
    edit_LogicalTab_Perc3rd_flag:= CurrentSendFlags;
    
    resend_osc_colors:= true;
    edit_MenuPercMode_flag:= c_sendfpga_mask;
  endif;
  
  // zurückübersetzen, falls Änderung über Tabs
  if edit_LogicalTab_PercOn_flag > 0 then
    Setbit(edit_MenuPercMode, 3, edit_LogicalTab_PercOn);
    edit_MenuPercMode_flag:= c_sendfpga_mask;
    resend_osc_colors:= true;
  endif;
  if edit_LogicalTab_PercSoft_flag > 0 then
    Setbit(edit_MenuPercMode, 2, edit_LogicalTab_PercSoft);
    edit_MenuPercMode_flag:= c_sendfpga_mask;
  endif;
  if edit_LogicalTab_PercFast_flag > 0 then
    Setbit(edit_MenuPercMode, 1, edit_LogicalTab_PercFast);
    edit_MenuPercMode_flag:= c_sendfpga_mask;
  endif;
  if edit_LogicalTab_Perc3rd_flag > 0 then
    Setbit(edit_MenuPercMode, 0, edit_LogicalTab_Perc3rd);
    edit_MenuPercMode_flag:= c_sendfpga_mask;
  endif;

  // ---------------------------------------------------------------------------

{$IFDEF ALLINONE}
  if edit_VibKnobMode = 1 then
    // 2 Binary Toggle Buttons + C/V
    // Logik: Wechselseitige Auslösung, nochmaliger Druck schaltet beide ein
    if (edit_LogicalTab_V1_flag > 0) then
      if not edit_LogicalTab_V1 then
        // war vorher ON, nochmals gedrückt
        edit_LogicalTab_V2:= not edit_LogicalTab_V2;
      else
        edit_LogicalTab_V2:= false;
      endif;
      edit_LogicalTab_V1:= true;
      edit_LogicalTab_V3:= false;
      NB_VCbitsToVibknob;
    endif;
    if (edit_LogicalTab_V2_flag > 0) then
      if not edit_LogicalTab_V2 then
        // war vorher ON, nochmals gedrückt
        edit_LogicalTab_V1:= not edit_LogicalTab_V1;
      else
        edit_LogicalTab_V1:= false;
      endif;
      edit_LogicalTab_V2:= true;
      edit_LogicalTab_V3:= false;
      NB_VCbitsToVibknob;
    endif;
    if edit_LogicalTab_VCh_flag > 0 then
      NB_VCbitsToVibknob;
    endif;
  elsif edit_VibKnobMode = 2 then
    // 3 Radio Buttons V1..V3 + C/V
    if (edit_LogicalTab_V1_flag > 0) then
      edit_LogicalTab_V1:= true;
      edit_LogicalTab_V2:= false;
      edit_LogicalTab_V3:= false;
      NB_VCbitsToVibknob;
    endif;
    if (edit_LogicalTab_V2_flag > 0) then
      edit_LogicalTab_V1:= false;
      edit_LogicalTab_V2:= true;
      edit_LogicalTab_V3:= false;
      NB_VCbitsToVibknob;
    endif;
    if (edit_LogicalTab_V3_flag > 0) then
      edit_LogicalTab_V1:= false;
      edit_LogicalTab_V2:= false;
      edit_LogicalTab_V3:= true;
      NB_VCbitsToVibknob;
    endif;
    if edit_LogicalTab_VCh_flag > 0 then
      NB_VCbitsToVibknob;
    endif;
  endif;
  if edit_VibKnob_flag > 0 then
    NB_VibknobToVCbits;  // Falls Änderung über Panel
  endif;
  edit_VibKnobMode_flag:= 0;
{$ENDIF}


  // ---------------------------------------------------------------------------

  // Reverb über Menü eingestellt?
  if edit_MenuReverbMode_flag > 0 then
    edit_LogicalTab_Reverb1:= Bit(edit_MenuReverbMode, 0);
    edit_LogicalTab_Reverb1_flag:= CurrentSendFlags;

    edit_LogicalTab_Reverb2:= Bit(edit_MenuReverbMode, 1);
    edit_LogicalTab_Reverb2_flag:= CurrentSendFlags;
  endif;
  // zurückübersetzen, falls Änderung über Tabs
  if edit_LogicalTab_Reverb1_flag > 0 then
    Setbit(edit_MenuReverbMode, 0, edit_LogicalTab_Reverb1);
    edit_MenuReverbMode_flag:= CurrentSendFlags;
  endif;
  if edit_LogicalTab_Reverb2_flag > 0 then
    Setbit(edit_MenuReverbMode, 1, edit_LogicalTab_Reverb2);
    edit_MenuReverbMode_flag:= CurrentSendFlags;
  endif;

  // ---------------------------------------------------------------------------
  
  if edit_SyncPHRtoLeslie and (edit_LogicalTab_LeslieFast_flag > 0) then
    edit_LogicalTab_PHR_Fast:= edit_LogicalTab_LeslieFast;
    edit_LogicalTab_PHR_Fast_flag:= edit_LogicalTab_LeslieFast_flag;
    AC_sendmsg_OR_flag(0150, byte(edit_LogicalTab_PHR_Fast), CurrentSendFlags);  //  für TouchOSC
  endif;

  // ---------------------------------------------------------------------------

  if resend_osc_colors or (edit_LogicalTab_EG_mask2dry_flag > 0) then
    send_osc_colors;
  endif;

{$ELSE}

  // ---------------------------------------------------------------------------

  // Keyswerk-Modul
  DisablePercussion:= false; // es gibt keine Voices > 0
  if DisableDB1 <> edit_NoDB1_atPerc then
    DisableDB1:= edit_NoDB1_atPerc;
    FH_UpperRoutingToFPGA;
  endif;
  edit_GatingMode:= 1;
  if (edit_ena_env_adsrmode_bits <> 0) or (edit_ena_env_db_bits <> 0) then
    edit_GatingMode:= 2;
    if edit_ena_env_percmode_bits <> 0 then
      edit_GatingMode:= 3;
    endif;
  endif;
  
//  if (edit_TG_TaperCaps > 5) and (edit_TG_WaveSet >= 6) and (edit_TG_WaveSet_flag > 0) then
//    edit_TG_WaveSet_flag:= 0;   // unnötige Änderung vermeiden
//  endif;
  
  if edit_TG_FilterFac > 50  then
    edit_TG_FilterFac:= 50;
    edit_TG_FilterFac_flag:= CurrentSendFlags;
  endif;

{$ENDIF}

end;

// #############################################################################

function AC_CollectAndSendEventMessages: Boolean;
// Gegenüber Parser-Input geänderte Bedienelemente als Message senden
// Über Parser gesetzte Werte sollten nicht unnötig wieder ausgesendet werden.
// Parser setzt in die Tabelle parsed_table_X die gleichen Werte wie in edit_table_X.
// Vergleich mit diesen Tabellen verhindert, das Änderungen über Parser gleich
// wieder als Event-Message gesendet werden.
// Ausnahme: Im Touchpad-CC-Set immer senden (über inverse CC-Tabelle)
var
  send_flags: Byte;
  changed_edit_idx: Integer;
  any_change: Boolean;
  action, last_action: t_action;
begin
  // alle Änderungen senden (neuer Wert <> alter Wert)
  // Änderungen nur im Touchpad-Set senden oder wenn mit Editor verbunden
  any_change:= false;
  action:= ta_last_entry; // wird einmal last_action zugewiesen!
  
  for ac_edit_idx:= 0 to 511 do
    send_flags:= edit_array_flag[ac_edit_idx];
    if send_flags = 0 then
      continue;
    endif;

    if send_flags > c_sendfpga_mask then  // mehr tun als nur an FPGA
      // Voice-Changes wurden bereits gesendet!
      AC_sendmsg(ac_edit_idx, edit_array[ac_edit_idx], send_flags);
    endif;

    if Bit(send_flags, c_sendfpga) then
      // Änderungen für FPGA sammeln
      last_action:= action;
      action:= c_edit_actions[ac_edit_idx];
      if last_action = action then
        // Rest überspringen, Event wurde bereits gesammelt
        continue;
      endif;
      ac_collect_action_array[ord(action)]:= true;
      any_change:= true;
      changed_edit_idx:= ac_edit_idx;
    endif;
  endfor;
{$IFDEF ALLINONE}
  // wenn sich im Upper/Lower/Pedal-Menü Drawbars geändert haben
  if any_change then
    MenuIndex_ValChanged:= Param2MenuInverseArray[changed_edit_idx]; // aus inverser Tabelle
    if valueInRange(MenuIndex, 1, 3) and c_MenuTypeArr[MenuIndex_ValChanged] = t_drawbar then
      MenuIndex_ValChanged:= MenuIndex;
    endif;
  endif;
{$ENDIF}

  FillBlock(@edit_array_flag, 512, 0); // alle erledigt
  return(any_change);
end;


// #############################################################################

procedure AC_CollectedActionsToFPGA;
// Routinen für Switch-Auswertung und
// Änderungen in der edit-Tabelle anhand bereits gesetzter Flags auswerten
// wird nur angesprungen, wenn sich in
// AC_CollectAndSendEventMessages etwas geändert hat!
var
  idx, temp_idx: Byte;
{$IFDEF ALLINONE}
  in_main_menu, preset_changed,
{$ENDIF}
  gating_changed, perc_changed: Boolean;
begin

  // Abbruchbedingung, falls sich CommonPreset zwischendurch geändert hat
{$IFDEF ALLINONE}
  IRQ_EncoderTouched:= false; // wird im IRQ gesetzt!
  in_main_menu:= MenuIndex = c_MenuCommonPreset;
  preset_changed:= (edit_CommonPreset <> edit_CommonPreset_old)
                   or (IRQ_EncoderTouched and in_main_menu);
{$ENDIF}

  gating_changed:= ac_collect_action_array[ord(ta_gating)];
  perc_changed:= gating_changed or ac_collect_action_array[ord(ta_perc_param)];
  // mögliche Aktionen durchsehen
  for idx:= 0 to ord(ta_last_entry)-1 do

    if ac_collect_action_array[idx] then
      ac_collect_action_array[idx]:= false;
{$IFDEF ALLINONE}
      if preset_changed then
        continue; // nur Flags löschen
      endif;
{$ENDIF}
      case t_action(idx) of
        ta_dbu:
          if not perc_changed then
            FH_UpperDrawbarsToFPGA;
{$IFDEF DEBUG_AC}
            writeln(serout, '/ AC UprDB');
{$ENDIF}
          endif;
          |
        ta_dbl:
          if not gating_changed then
            FH_LowerDrawbarsToFPGA; // stellt auch ADSR und Bits ein
{$IFDEF DEBUG_AC}
            writeln(serout, '/ AC LwrDB');
{$ENDIF}
          endif;
          |
        ta_dbp:
          FH_PedalDrawbarsToFPGA;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC PedDB');
{$ENDIF}
          |
        ta_perc_param:
{$IFDEF ALLINONE}
          if not gating_changed then
            FH_RouteOrgan;    // macht auch FH_UpperRoutingToFPGA
            FH_UpperDrawbarsToFPGA;   // wg. Percussion Muted Level
            FH_PercussionParamsToFPGA;
          endif;
{$ELSE}
          FH_UpperDrawbarsToFPGA;   // wg. Percussion Muted Level
          FH_PercussionParamsToFPGA;
{$ENDIF}
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Perc');
{$ENDIF}
          |
        ta_organ, ta_midi:
          AC_RouteOrgan;
          |
        ta_gating:
          AC_SendGating;
          |
        // ta_generator_knob siehe oben bei AC_MutualControls
        ta_direct_uprout:
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC DirectRouting');
{$ENDIF}
          FH_UpperRoutingToFPGA;
          FH_UpperDrawbarsToFPGA;
          FH_PercussionParamsToFPGA; // Perc-Bits könnten sich geändert haben
          |

{$IFDEF ALLINONE}
        ta_rotary_run, ta_rotary_fast:
          AC_SendRotarySpeed;
          |
        // NRPN-Reihenfolge upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx;
        ta_gmu:
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
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC GM Upr');
{$ENDIF}
          |
        ta_gml:
          MIDI_SendNRPN($3531, edit_LowerGMharm_0);
          MIDI_SendNRPN($3561, edit_LowerGMlvl_0);
          if HasExtendedLicence then
            MIDI_SendNRPN($3525, edit_LowerGMdetune_1 + 57);
            MIDI_SendNRPN($3535, edit_LowerGMharm_1);
            MIDI_SendNRPN($3565, edit_LowerGMlvl_1);
          else
            MIDI_SendNRPN($3565, 0);  //  edit_LowerGMlvl_1
          endif;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC GM Lwr');
{$ENDIF}
          |
        ta_gmp:
          MIDI_SendNRPN($3532, edit_PedalGMharm_0);
          MIDI_SendNRPN($3562, edit_PedalGMlvl_0);
          if HasExtendedLicence then
            MIDI_SendNRPN($3526, edit_PedalGMdetune_1 + 57);
            MIDI_SendNRPN($3536, edit_PedalGMharm_1);
            MIDI_SendNRPN($3566, edit_PedalGMlvl_1);
          else
            MIDI_SendNRPN($3566, 0);  //  edit_PedalGMlvl_1
          endif;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC GM Ped');
{$ENDIF}
          |
        // GM Programmnummer senden und Namen anfordern
        // Reihenfolge von NRPN $3570+x und in Tabelle:
        // upper_0, lower_0, pedal_0, xxx, upper_1, lower_1, pedal_1, xxx
        // ta_gmu_v0, ta_gml_v0, ta_gmp_v0, ta_dummy, ta_gmu_v1, ta_gml_v1, ta_gmp_v1
        ta_gmu_v0..ta_gmp_v1:
          temp_idx:= idx - ord(ta_gmu_v0);
          n:= c_gmidx_order_to_edit_gmvoice[temp_idx];
          i:= edit_GMprogs[n];  // aktuelle GM-Programmnummer
          MIDI_SendNRPN($3550 + Integer(temp_idx), i);    // Programm setzen
          // Namen anfordern, wird über SysEx in GM_VoiceNames[] gesetzt
          MIDI_SendNRPN($3570 + Integer(temp_idx), 127);
          if not ac_preset_changed then
            GM_VoiceNameToDisplaySema[temp_idx]:= GM_VoiceNameToDisplaySema[temp_idx]
            or (ConnectMode in[t_connect_osc_midi, t_connect_osc_serial]);
          endif;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC GM ProgName');
{$ENDIF}
          |
        // Reverb etc.
        ta_gm2:
          m:= (edit_LocalEnable shl 4) or edit_MIDI_Channel;
          MIDI_SendNRPN($357F, m); // Kanal und Freigabe für SAM5504
          AC_SendVolumes;
          ToneChanged:=true;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC GM Volume');
{$ENDIF}
          |
        ta_reverb:
          FH_SendReverb;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Reverb');
{$ENDIF}
          |
{$ELSE}
        ta_reverb:
          FH_SendModuleExtRotary;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC ModuleExtVol');
{$ENDIF}
          |
          
{$ENDIF}

        ta_inserts:
          AC_SendInserts;
          |
        ta_phr:
          FH_PhasingRotorToFPGA;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC PHR Params');
{$ENDIF}
          |
        ta_phr_prog:
          AC_SendPHRprgm;
          |
        ta_rota_live:
          AC_SendLeslieLiveParams;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC RotaryLive');
{$ENDIF}
          |
        ta_split:
          FH_SplitConfigToFPGA;
          |
        ta_vib:
          FH_VibratoToFPGA;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Vibrato');
{$ENDIF}
          |
        ta_swell:
          ToneChanged:= true;
          |
        ta_pots:
          AC_SendVolumes;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Volumes');
{$ENDIF}
          |
        ta_trimpots:
          AC_SendTrimPots;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Trimpots');
{$ENDIF}
          |
        ta_taper_tg:
          if IRQ_EncoderTouched and in_main_menu then  // kann länger dauern
            continue;                                  // ggf. Abbruch
          endif;
          FH_KeymapToFPGA;
          if IRQ_EncoderTouched and in_main_menu then
            continue;
          endif;
          FH_TaperingToFPGA(edit_TG_TaperCaps);
          if IRQ_EncoderTouched and in_main_menu then
            continue;
          endif;
          FH_NoteHighpassFilterToFPGA;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Tapering');
{$ENDIF}
          |
        ta_tuning:
          FH_TuningValsToFPGA;
          |
        ta_wave:
          FH_WaveBlocksToFPGA;
{$IFDEF DEBUG_AC}
          writeln(serout, '/ AC Wave');
{$ENDIF}
          |
{$IFDEF ALLINONE}
        ta_dimmer:
          NB_SetLEDdimmer;
          |
        ta_detent:
          // Mittelpositions-Default geändert, nach zugehörigem ADC suchen
          AC_SetDetent;
          |
{$ENDIF}
      endcase;
    endif;
  endfor;
  ac_preset_changed:= false;
end;

// #############################################################################
// ###                       Volume an FPGA senden                           ###
// #############################################################################

procedure AC_SendSwell;
// SCHWELLPEDAL-Steuerung, MASTER-Volume wg. MasterSwell für Böhm
// wird in MainTasks ständig aufgerufen
// Rechnet Byte "volume" in EQ-Paramater um
var my_swell,
    my_swell_ranged,
    my_swell_125hz,
    my_swell_250hz,
    my_swell_1khz,   // nur halber Audio-Pegel in AO28 NEU!
    my_swell_4khz,   // nur halber Audio-Pegel in AO28 NEU!
    my_swell_tone, my_swell_pedal: Byte;
{$IFNDEF ALLINONE}
    my_master_vol, my_front_vol, my_rear_vol, my_efx_vol, my_rev_vol: Byte;  // nur für Realorgan
{$ENDIF}
begin
{$IFDEF ALLINONE}
  if SwellPedalControlledByMIDI then
{$ENDIF}
    // result:= ((oldVal * fact) + newVal) div (fact + 1);
    midi_swell_w:= (midi_swell_w * 3 + word(midi_swell128 shl 1)) div 4;
    my_swell:= lo(midi_swell_w);

    if my_swell <> MIDI_swell255_old then
      //writeln(serout,'/ Swell midi: ' + bytetostr(midi_swell128) + ' int: ' + bytetostr(my_swell));
      SwellPedalChanged:= true;
      MIDI_swell255_old:= my_swell;
    endif;
{$IFDEF ALLINONE}
  else
    my_swell:= SwellPedalADC;                   // Swell-Bereich 0..255
    MIDI_SendChangedSwell(my_swell shr 1);
  endif;
{$ENDIF}

  if SwellPedalChanged or ToneChanged then
  
    case edit_PreampSwellType of
      0:
        // Hammond Mode, ausgeprägtes, aber flaches Maximum bei 200 Hz,
        // ab 250 Hz mit 3-4 db/Okt fallend, über 4 kHz stärker
        // TONE-Pot, Minimal Swell und Swell Trim Cap werden berücksichtigt
        // Range auf Minimal Swell anpassen
        my_swell_ranged:= edit_MinimalSwell + MulDivByte(my_swell, 255 - edit_MinimalSwell, 255);
        // Maximalwert auf Trim Cap Swell anpassen
        n:= MulDivByte(edit_TrimSwell, 65, 100) + 35;
        my_swell_ranged:= MulDivByte(my_swell_ranged, n, 127);
        // my_swell_ranged geht jetzt von edit_MinimalSwell..(255*edit_TrimSwell/100),
        // d.h. 15..255 wenn edit_MinimalSwell = 15 und edit_TrimSwell = 100
        my_swell_125hz:= 65 + MulDivByte(my_swell_ranged, 190, 255);
        my_swell_250hz:= MulDivByte(my_swell_ranged, 165, 255);
        // in AO28-Sim ist dieser Pegel um -12 dB abgesenkt
        my_swell_1khz:= MulDivByte(my_swell_ranged, 140, 255);
        // in AO28-Sim ist dieser Pegel um -12 dB abgesenkt
        my_swell_4khz:= 30 + MulDivByte(my_swell_ranged, 215, 255);

        // edit_TonePot im Bereich 0..127, Mitte 64
        my_swell_tone:= edit_TonePot;   // 0..127
        //my_swell_tone_inv:= 127 - my_swell_tone;

        // 1kHz-Anteil wird mit steigendem TONE-Wert kleiner
        // in AO28-Sim ist dieser Pegel um -12 dB abgesenkt
       // my_swell_1khz:= MulDivByte(my_swell_1khz, my_swell_tone_inv, 127);

        // 4kHz-Anteil wird mit steigendem TONE-Wert größer
        // in AO28-Sim ist dieser Pegel um -12 dB abgesenkt
        my_swell_4khz:= MulDivByte(my_swell_4khz, my_swell_tone, 127);
        
        // Finales Lowpass-Filter 6db/Okt.
        // Frequenzen ermittelt mit IIR_Filter_Coef_Generator.xls
        // Bit 7 = 0, Hammond Mode, 4khz-Bereich um 12 dB abgesenkt
        // Frequenz 120,3 Hz * (Wert + 1)
        SendByteToFPGA(40, 87);  // ca. 4,5 kHz Grenzfrequenz
        
        my_swell_pedal:= my_swell_125hz;
        // writeln(serout,'/ 1k:' + bytetostr(my_swell_1khz) + ' 4k: ' + bytetostr(my_swell_4khz));
        |
      1:  // Conn, Böhm etc. Sinus
        my_swell_125hz:= MulDivByte(my_swell, 150, 255);
        my_swell_250hz:= MulDivByte(my_swell, 135, 255);
        my_swell_1khz:= MulDivByte(my_swell, 120, 255); // - 12 dB in Preamp
        // in AO28-Sim ist dieser Pegel nur um -6 dB abgesenkt, wenn Linear Mode ON
        my_swell_4khz:= MulDivByte(my_swell, 140, 255); // - 6 dB in Preamp

        // Finales Lowpass-Filter 6db/Okt.
        // Frequenzen ermittelt mit IIR_Filter_Coef_Generator.xls
        // Bit 7 = 1, 4khz-Bereich nur um 6 dB abgesenkt
        // Frequenz 120,3 Hz * (Wert + 1) + 128 für 4k Enhanced
        SendByteToFPGA(45, 87);  // ca. 5,5 kHz Grenzfrequenz
        
        my_swell_pedal:=  my_swell;
        |
    else  // andere, fast linear, etwas Bass-Anhebung
        my_swell_125hz:= 0;
        my_swell_250hz:= MulDivByte(my_swell, 95, 255);
        my_swell_1khz:= MulDivByte(my_swell, 145, 255); // - 12 dB in Preamp
        // in AO28-Sim ist dieser Pegel nur um -6 dB abgesenkt, wenn Linear Mode ON
        my_swell_4khz:= MulDivByte(my_swell, 190, 255); // - 6 dB in Preamp
        
        // Finales Lowpass-Filter 6db/Okt.
        // Frequenzen ermittelt mit IIR_Filter_Coef_Generator.xls
        // Bit 7 = 1, 4khz-Bereich nur um 6 dB abgesenkt
        // Frequenz 120,3 Hz * (Wert + 1) + 128 für 4k Enhanced
        SendByteToFPGA(128 + 47, 87);  // ca. 6 kHz Grenzfrequenz
        
        my_swell_pedal:= my_swell;
    endcase;

    // InsertPedalPostMix:= edit_LogicalTab_PedalPostMix and (not Bit(edit_ConfBits, 3));
    if edit_EnablePedalAudio then
      if edit_LogicalTab_PedalPostMix then  // Pedal Bypass Tab
        // bei Pedal Bypass wird direkt auf Ausgang gemischt
        SendByteToFPGA(0, 45);  // Pedal to Lower Vib
        SendByteToFPGA(0, 46);  // Pedal to AO28
      else
        // normales Pedal Routing mit oder ohne Lower Vibrato
        if Bit(edit_ConfBits, 4) and (edit_GatingMode = 0) then
          SendScaledByteToFPGA(edit_PedalVolume, 45, 90);  // Pedal to Lower Vib
          SendByteToFPGA(0, 46);  // Pedal to AO28
        else
          SendByteToFPGA(0, 45);  // Pedal to Lower Vib
          SendScaledByteToFPGA(edit_PedalVolume, 46, 90);  // Pedal to AO28
        endif;
      endif;
      // immer an Pedal-Ausgang und an Postmix, falls eingeschaltet
      if (not edit_LogicalTab_TubeAmpBypass) and Bit(edit_ConfBits, 2) then
        // Volume Correction Bit gesetzt, Pedal-Volume anheben (!),
        // sonst wird Pedal mit zunehmendem Tube Amp Gain leiser
        m:= (ValueTrimLimit(edit_LeslieVolume, 0, 31) shl 1) + 65; // 65..127
        m:= muldivbyte(my_swell_pedal, m, 162);  // 162 = 127/100 * 127

        SendScaledByteToFPGA(m, 47, edit_PedalVolume); // Pedal to Output & Postmix
      else
        // Swell Pedal an Pedal-Postmix und Pedal-Ausgang
        m:= muldivbyte(my_swell_pedal, edit_PedalVolume, 150);
        SendByteToFPGA(m, 47); // Pedal to Output & Postmix
      endif;
    else
      SendByteToFPGA(0, 45);   // Pedal Vol auf 0
      SendByteToFPGA(0, 46);   // Pedal Vol auf 0
      SendByteToFPGA(0, 47);   // Pedal Vol auf 0
    endif;

    SendByteToFPGA(my_swell_125hz, 80);
    SendByteToFPGA(my_swell_250hz, 81);
    SendByteToFPGA(my_swell_1khz,  82);
    SendByteToFPGA(my_swell_4khz,  83);

    ToneChanged:= false;
    SwellPedalChanged:= false;
  endif;
  
{$IFNDEF ALLINONE}
// Nur RealOrgan!
  if midi_RealOrganSwellAdjust < midi_RealOrganSwellAdjust_integrated then
    dec(midi_RealOrganSwellAdjust_integrated);
  endif;
  if midi_RealOrganSwellAdjust > midi_RealOrganSwellAdjust_integrated then
    inc(midi_RealOrganSwellAdjust_integrated);
  endif;

  // m wird overall Volume, regelt alle Ausgänge
  m:= muldivbyte(edit_MasterVolume, midi_RealOrganSwellAdjust_integrated, 127);
  
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleFrontVolume, m, 127), 72);    // 72 = Front Vol DABD0
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleRevVolume, m, 127), 73);      // 73 = Ext Rev Vol DABD1_L
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleEfxVolume, m, 127), 74);      // 74 = Ext Efx Vol DABD1_R
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleRearVolume, m, 127), 75);     // 75 = Rear Vol DABD2
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleExtRotaryLeft, m, 127), 76);  // RealOrgan External Rotary DABD3_L
  SendVolumeByteToFPGA(muldivbyte(edit_ModuleExtRotaryRight, m, 127), 77); // RealOrgan External Rotary DABD3_R
// NOT ALLINONE
{$ENDIF}
end;

function ac_detent_shift(const my_val, detent_shift: Byte): Byte;
var diff_i, val_i: Integer;
begin
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
end;

procedure AC_SendVolumes;
// UPPER/LOWER/PEDAL Volumes
// wird bei Änderungen aufgerufen
// Rechnet Byte "volume" in EQ-Paramater um
var rot_vol, temp_vol: Byte;
begin

{$IFDEF ALLINONE}
  // Amp122 nicht auf 0
  m:= muldivbyte(edit_LeslieVolume, 97, 127) + 30; // 30..127
  SendVolumeByteToFPGA(m, 176);     // in Volume-Gruppe, auf 0..255

  temp_vol:= muldivbyte(edit_MasterVolume, edit_GM2organVolume, 127);

  if edit_LogicalTab_TubeAmpBypass then
    SendByteToFPGA(edit_LeslieInpLvl, 180); // Leslie Input Level
  else
    // edit_LeslieInpLvl korrigieren, um Übersteuerungen zu vermeiden
    rot_vol:= edit_LeslieInpLvl - (edit_LeslieVolume div 2);
    SendByteToFPGA(rot_vol, 180); // Leslie Input Level
    if Bit(edit_ConfBits, 2) then // Volume Correction bit
      // m = 30..127
      m:= 80 - ValueTrimLimit(m, 0, 49);
      temp_vol:= muldivbyte(temp_vol, m, 50);
    endif;
  endif;

  // SendVolumeByteLogToFPGA(m, 45);  // 45 = Master Vol ALT auf 0..255, über Log-Table
  SendVolumeByteLogToFPGA(temp_vol, 72);     // 72 = Master Vol NEU ab FPGA 17112020

  m:= (edit_GM2synthVolume shr 2) + 96;
  MIDI_SendNRPN($3509, m); // SAM55004 GM2 Pre-Mix Gain
  MIDI_SendNRPN($3510, edit_MasterVolume);   // SAM55004 GM2 General Master Volume
  MIDI_SendNRPN($3512, 127);                 // SAM55004 GM2 Master Volume
{$IFDEF DEBUG_AC}
  Write(Serout, '/ AC PercVol');
{$ENDIF}
  temp_vol:= ac_detent_shift(edit_UpperVolumeDry, edit_PercVolDetentShift);
  if edit_EnableUpperAudio then
    SendScaledByteToFPGA(edit_UpperVolumeWet, 34, 150);   // 34 = Upper Manual Vol auf 0..200
    SendScaledByteToFPGA(temp_vol, 37, 150);   // 37 = Perc/lvl_2nd_voice Vol auf 0..200
  else
    SendByteToFPGA(0, 34);   // 34 = Upper Manual Vol auf 0
    SendByteToFPGA(0, 37);   // 37 = Perc/lvl_2nd_voice Vol auf 0
  endif;
  if edit_EnableLowerAudio then
    SendScaledByteToFPGA(edit_LowerVolume, 35, 150);  // 35 = Lower Manual Vol auf 0..200
  else
    SendByteToFPGA(0, 35);   // 35 = Lower Manual Vol auf 0
  endif;

{$ELSE}
// NOT ALLINONE!
  SendVolumeByteToFPGA(edit_LeslieVolume, 176);     // in Volume-Gruppe, auf 0..255
  AC_SendSwell;

  SendScaledByteToFPGA(edit_UpperVolumeWet, 34, 140);    // 34 = Upper Manual Vol auf 0..200
  temp_vol:= ac_detent_shift(edit_UpperVolumeDry, edit_PercVolDetentShift);
  SendScaledByteToFPGA(temp_vol,  37, 140);   // 37 = Perc/lvl_2nd_voice Vol auf 0..200
  SendScaledByteToFPGA(edit_LowerVolume, 35, 140);       // 35 = Lower Manual Vol auf 0..200
  SendScaledByteToFPGA(edit_PedalVolume, 36, 160);       // 36 = Pedal Vol auf 0..200
// NOT ALLINONE
{$ENDIF}

  SendByteToFPGA(edit_LocalEnable xor 7, 14);   // ScanCore SPI Local Disables

  if edit_PreampSwellType = 0 then // Hammond, mit TRIODE K2 AGE-Pot
    SendByteToFPGA(255-edit_Triode_k2, 85);  // 85 = TRIODE_K2  255..155
  else
    SendByteToFPGA(255, 85);  // kein k2
  endif;
  ToneChanged:= true;  // sende SWELL
end;



procedure AC_SendTrimPots;
// UPPER/LOWER/PEDAL Volumes
// wird bei Änderungen aufgerufen
// Rechnet Byte "volume" in EQ-Paramater um
var temp_vol: Byte;
begin
{$IFDEF ALLINONE}
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
  MIDI_SendNRPN($3519, edit_EqualizerMidPeak);   // SAM5504 Mid EQU Damp/Q

{$IFDEF DEBUG_AC}
  Write(Serout, '/ AC Treble EQ');
{$ENDIF}
  temp_vol:= ac_detent_shift(edit_EqualizerTreble, edit_EquTrebleDetentShift);
  MIDI_SendNRPN($351A, temp_vol);      // SAM5504 EQU 3
  // Treble EQ 0 = 500 Hz, 64 = 2550 Hz, 127 = 8500 Hz
  MIDI_SendNRPN($351B, edit_EqualizerTrebleFreq);  // SAM5504 Treble EQU Mittenfrequenz

  if edit_EqualizerFullParametric then
    MIDI_SendNRPN($3516, edit_EqualizerBassPeak);  // SAM5504 Bass EQU Damp/Q
    MIDI_SendNRPN($351C, edit_EqualizerTreblePeak);  // SAM5504 Treble EQU Damp/Q
  endif;
{$ENDIF}
end;


procedure AC_SendLeslieLiveParams;
var my_val, my_spread_angle: Byte;
// wird bei Änderungen aufgerufen
begin
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

end apply_changes.

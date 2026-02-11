// DEBUG_SEMPRA includes

s_MidiDebugStrArr: array[0..511] of String[23] = (
  'Upr DB 16',  // 1000
  'Upr DB 5 1/3',  // 1001
  'Upr DB 8',  // 1002
  'Upr DB 4',  // 1003
  'Upr DB 2 2/3',  // 1004
  'Upr DB 2',  // 1005
  'Upr DB 1 3/5',  // 1006
  'Upr DB 1 1/3',  // 1007
  'Upr DB 1',  // 1008
  'Upr Mixt DB 10',  // 1009
  'Upr Mixt DB 11',  // 1010
  'Upr Mixt DB 12',  // 1011
  '(none)',  // 1012
  '(none)',  // 1013
  '(none)',  // 1014
  '(none)',  // 1015
  'Lwr DB 16',  // 1016
  'Lwr DB 5 1/3',  // 1017
  'Lwr DB 8',  // 1018
  'Lwr DB 4',  // 1019
  'Lwr DB 2 2/3',  // 1020
  'Lwr DB 2',  // 1021
  'Lwr DB 1 3/5',  // 1022
  'Lwr DB 1 1/3',  // 1023
  'Lwr DB 1',  // 1024
  'Lwr Mixt DB 10',  // 1025
  'Lwr Mixt DB 11',  // 1026
  'Lwr Mixt DB 12',  // 1027
  '(none)',  // 1028
  '(none)',  // 1029
  '(none)',  // 1030
  '(none)',  // 1031
  'Ped DB 16',  // 1032
  'Ped DB 5 1/3',  // 1033
  'Ped DB 8',  // 1034
  'Ped DB 4',  // 1035
  'Ped DB 2 2/3',  // 1036
  'Ped DB 2',  // 1037
  'Ped DB 1 3/5',  // 1038
  'Ped DB 1 1/3',  // 1039
  'Ped DB 1',  // 1040
  'Ped Mixt DB 10',  // 1041
  'Ped Mixt DB 11',  // 1042
  'Ped Mixt DB 12',  // 1043
  '(none)',  // 1044
  '(none)',  // 1045
  '(none)',  // 1046
  '(none)',  // 1047
  'Upr Attack',  // 1048
  'Upr Decay',  // 1049
  'Upr Sustain',  // 1050
  'Upr Release',  // 1051
  'Upr ADSR Harm Decay',  // 1052
  '(none)',  // 1053
  '(none)',  // 1054
  '(none)',  // 1055
  'Lwr Attack',  // 1056
  'Lwr Decay',  // 1057
  'Lwr Sustain',  // 1058
  'Lwr Release',  // 1059
  'Lwr ADSR Harm Decay',  // 1060
  '(none)',  // 1061
  '(none)',  // 1062
  '(none)',  // 1063
  'Ped Attack',  // 1064
  'Ped Decay',  // 1065
  'Ped Sustain',  // 1066
  'Ped Release',  // 1067
  'Ped ADSR Harm Decay',  // 1068
  '(none)',  // 1069
  '(none)',  // 1070
  '(none)',  // 1071
  'Ped DB 16 AutoMix',  // 1072
  'Ped DB 16H AutoMix',  // 1073
  'Ped DB 8 AutoMix',  // 1074
  'Ped DB 8H AutoMix',  // 1075
  'Pitchwheel MIDI Send',  // 1076
  'Pitchwheel Rotary Ctrl',  // 1077
  'Modwheel MIDI Send',  // 1078
  'Modwheel Rotary Ctrl',  // 1079
  'General Master Vol',  // 1080
  'Rotary Simulation Tube Amp Gain',  // 1081
  'Upr Manual Lvl',  // 1082
  'Lwr Manual Lvl',  // 1083
  'Ped Lvl',  // 1084
  'Upr Dry/2ndVoice Lvl',  // 1085
  'Overall Reverb Lvl',  // 1086
  'Tone Pot Equ',  // 1087
  'Trim Cap Swell',  // 1088
  'Minimal Swell Lvl',  // 1089
  'AO 28 Triode Dist',  // 1090
  'Böhm Module Rev Vol',  // 1091
  'Böhm Module Efx Vol',  // 1092
  'Böhm Module Swell Vol',  // 1093
  'Böhm Module Front Vol',  // 1094
  'Böhm Module Rear Vol',  // 1095
  'Upr Env DB 16',  // 1096
  'Upr Env DB 5 1/3',  // 1097
  'Upr Env DB 8',  // 1098
  'Upr Env DB 4',  // 1099
  'Upr Env DB 2 2/3',  // 1100
  'Upr Env DB 2',  // 1101
  'Upr Env DB 1 3/5',  // 1102
  'Upr Env DB 1 1/3',  // 1103
  'Upr Env DB 1',  // 1104
  'Upr Env Mixt DB 10',  // 1105
  'Upr Env Mixt DB 11',  // 1106
  'Upr Env Mixt DB 12',  // 1107
  '(none)',  // 1108
  '(none)',  // 1109
  '(none)',  // 1110
  '(none)',  // 1111
  'Equ Bass Ctrl',  // 1112
  'Equ Bass Freq',  // 1113
  'Equ Bass Peak/Q',  // 1114
  'Equ Mid Ctrl',  // 1115
  'Equ Mid Freq',  // 1116
  'Equ Mid Peak/Q',  // 1117
  'Equ Treble Ctrl',  // 1118
  'Equ Treble Freq',  // 1119
  'Equ Treble Peak/Q',  // 1120
  'Equ FullPara Ena',  // 1121
  'Böhm Ext Rotary Vol Left',  // 1122
  'Böhm Ext Rotary Vol Right',  // 1123
  'Equ Bass Pot Mid Pos',  // 1124
  'Equ Mid Pot Mid Pos',  // 1125
  'Equ Treble Pot Mid Pos',  // 1126
  'Perc/Dry Vol Mid Pos',  // 1127
  'Perc ON',  // 1128
  'Perc SOFT',  // 1129
  'Perc FAST',  // 1130
  'Perc THIRD',  // 1131
  'Vibrato Upr ON',  // 1132
  'Vibrato Lwr ON',  // 1133
  'Leslie RUN',  // 1134
  'Leslie FAST',  // 1135
  'Tube Amp Bypass',  // 1136
  'Rotary Speaker Bypass',  // 1137
  'Phasing Rotor Upr ON',  // 1138
  'Phasing Rotor Lwr ON',  // 1139
  'Reverb 1 ',  // 1140
  'Reverb 2 ',  // 1141
  'Add Ped',  // 1142
  'Keyboard Split ON ',  // 1143
  'Phasing Rotor',  // 1144
  'Phasing Rotor Ensemble',  // 1145
  'Phasing Rotor Celeste',  // 1146
  'Phasing Rotor Fading',  // 1147
  'Phasing Rotor Weak',  // 1148
  'Phasing Rotor Deep',  // 1149
  'Phasing Rotor Fast',  // 1150
  'Phasing Rotor Delay',  // 1151
  'TAB #24, H100 Mode',  // 1152
  'TAB #25, Env Gen Mode',  // 1153
  'TAB #26, EG Perc DB Mode',  // 1154
  'TAB #27, EG TimeBend Mode ',  // 1155
  'TAB #28, H100 2ndVoice',  // 1156
  'TAB #29, H100 Harp Sust',  // 1157
  'TAB #30, EG Ena to Dry',  // 1158
  'TAB #31, Equ Bypass',  // 1159
  'Upr DB 16 to ADSR',  // 1160
  'Upr DB 5 1/3 to ADSR',  // 1161
  'Upr DB 8 to ADSR',  // 1162
  'Upr DB 4 to ADSR',  // 1163
  'Upr DB 2 2/3 to ADSR',  // 1164
  'Upr DB 2 to ADSR',  // 1165
  'Upr DB1 3/5 to ADSR',  // 1166
  'Upr DB 1 1/3 to ADSR',  // 1167
  'Upr DB 1 to ADSR',  // 1168
  'Upr Mixt DB 10 to ADSR',  // 1169
  'Upr Mixt DB 11 to ADSR',  // 1170
  'Upr Mixt DB 12 to ADSR',  // 1171
  '(none)',  // 1172
  '(none)',  // 1173
  'Octave Downshift Upr',  // 1174
  'Octave Downshift Lwr',  // 1175
  'Lwr DB 16 to ADSR',  // 1176
  'Lwr DB 5 1/3 to ADSR',  // 1177
  'Lwr DB 8 to ADSR',  // 1178
  'Lwr DB 4 to ADSR',  // 1179
  'Lwr DB 2 2/3 to ADSR',  // 1180
  'Lwr DB 2 to ADSR',  // 1181
  'Lwr DB1 3/5 to ADSR',  // 1182
  'Lwr DB 1 1/3 to ADSR',  // 1183
  'Lwr DB 1 to ADSR',  // 1184
  'Lwr Mixt DB 10 to ADSR',  // 1185
  'Lwr Mixt DB 11 to ADSR',  // 1186
  'Lwr Mixt DB 12 to ADSR',  // 1187
  '(none)',  // 1188
  '(none)',  // 1189
  '(none)',  // 1190
  '(none)',  // 1191
  'Preset Name [0] (Length)',  // 1192
  'Preset Name [1]',  // 1193
  'Preset Name [2]',  // 1194
  'Preset Name [3]',  // 1195
  'Preset Name [4]',  // 1196
  'Preset Name [5]',  // 1197
  'Preset Name [6]',  // 1198
  'Preset Name [7]',  // 1199
  'Preset Name [8]',  // 1200
  'Preset Name [9]',  // 1201
  'Preset Name [10]',  // 1202
  'Preset Name [11]',  // 1203
  'Preset Name [12]',  // 1204
  'Preset Name [13]',  // 1205
  'Preset Name [14]',  // 1206
  'Preset Name [15]',  // 1207
  'Hammond DB Upr Decode',  // 1208
  'Hammond DB Lwr Decode',  // 1209
  'Hammond DB Ped Decode',  // 1210
  'Hammond VibKnob Decode',  // 1211
  '4 Btn V1',  // 1212
  '4 Btn V2',  // 1213
  '4 Btn V3',  // 1214
  '4 Btn V/C',  // 1215
  'Transpose +1 UP',  // 1216
  'Transpose -1 DOWN',  // 1217
  '(Btns not saved)',  // 1218
  '(Btns not saved)',  // 1219
  'Single DB set to Lwr',  // 1220
  'Single DB set to Ped',  // 1221
  '(Btns not saved)',  // 1222
  '(Btns not saved)',  // 1223
  'Upr GM Layer 1 Voice',  // 1224
  'Upr GM Layer 1 Lvl',  // 1225
  'Upr GM Layer 1 Harmonic',  // 1226
  'Upr GM Layer 2 Voice',  // 1227
  'Upr GM Layer 2 Lvl',  // 1228
  'Upr GM Layer 2 Harmonic',  // 1229
  'Upr GM Layer 2 Detune',  // 1230
  '(none)',  // 1231
  'Lwr GM Layer 1 Voice',  // 1232
  'Lwr GM Layer 1 Lvl',  // 1233
  'Lwr GM Layer 1 Harmonic',  // 1234
  'Lwr GM Layer 2 Voice',  // 1235
  'Lwr GM Layer 2 Lvl',  // 1236
  'Lwr GM Layer 2 Harmonic',  // 1237
  'Lwr GM Layer 2 Detune',  // 1238
  '(none)',  // 1239
  'Ped GM Layer 1 Voice',  // 1240
  'Ped GM Layer 1 Lvl',  // 1241
  'Ped GM Layer 1 Harmonic',  // 1242
  'Ped GM Layer 2 Voice',  // 1243
  'Ped GM Layer 2 Lvl',  // 1244
  'Ped GM Layer 2 Harmonic',  // 1245
  'Ped GM Layer 2 Detune',  // 1246
  '(none)',  // 1247
  'LoadEventCommon',  // 1248
  'LoadEventUpper',  // 1249
  'LoadEventLower',  // 1250
  'LoadEventPedal',  // 1251
  'SaveEventCommon',  // 1252
  'SaveEventUpper',  // 1253
  'SaveEventLower',  // 1254
  'SaveEventPedal',  // 1255
  '(none)',  // 1256
  '(none)',  // 1257
  '(none)',  // 1258
  '(none)',  // 1259
  '(none)',  // 1260
  '(none)',  // 1261
  '(none)',  // 1262
  '(none)',  // 1263
  'Vibrato Knob',  // 1264
  'Organ Model (OSC)',  // 1265
  'Generator Model Knob',  // 1266
  'Gating (Keying) Knob',  // 1267
  'Overall Preset (Temp)',  // 1268
  'Upr Voice',  // 1269
  'Lwr Voice',  // 1270
  'Ped Voice',  // 1271
  'Lvl BB 16',  // 1272
  'Lvl BB 5 1/3',  // 1273
  'Lvl BB 8',  // 1274
  'Lvl BB 4',  // 1275
  'Lvl BB 2 2/3',  // 1276
  'Lvl BB 2',  // 1277
  'Lvl BB 1 3/5',  // 1278
  'Lvl BB 1 1/3',  // 1279
  'Lvl BB 1',  // 1280
  'Lvl BB 10',  // 1281
  'Lvl BB 11',  // 1282
  'Lvl BB 12',  // 1283
  'Lvl BB 13',  // 1284
  'Lvl BB 14',  // 1285
  'Lvl BB 15',  // 1286
  '(none)',  // 1287
  'Note Offset BB 16',  // 1288
  'Note Offset BB 5 1/3',  // 1289
  'Note Offset BB 8',  // 1290
  'Note Offset BB 4',  // 1291
  'Note Offset BB 2 2/3',  // 1292
  'Note Offset BB 2',  // 1293
  'Note Offset BB 1 3/5',  // 1294
  'Note Offset BB 1 1/3',  // 1295
  'Note Offset BB 1',  // 1296
  'Note Offset BB 10',  // 1297
  'Note Offset BB 11',  // 1298
  'Note Offset BB 12',  // 1299
  'Note Offset BB 13',  // 1300
  'Note Offset BB 14',  // 1301
  'Note Offset BB 15',  // 1302
  '(none)',  // 1303
  '(none)',  // 1304
  '(none)',  // 1305
  '(none)',  // 1306
  '(none)',  // 1307
  '(none)',  // 1308
  '(none)',  // 1309
  '(none)',  // 1310
  '(none)',  // 1311
  '(none)',  // 1312
  '(none)',  // 1313
  '(none)',  // 1314
  '(none)',  // 1315
  '(none)',  // 1316
  '(none)',  // 1317
  '(none)',  // 1318
  '(none)',  // 1319
  'Pre-Emphasis',  // 1320
  'LC Line Age/AM',  // 1321
  'LC Line Feedback',  // 1322
  'LC Line Reflection',  // 1323
  'LC Line Response Cutoff Freq',  // 1324
  'LC PhaseLk/LineCutoff Lvl',  // 1325
  'Scanner Gearing (Vib Frequ)',  // 1326
  'Chorus Dry (Bypass) Lvl',  // 1327
  'Chorus Wet (Scanner) Lvl',  // 1328
  'Modulation V1/C1',  // 1329
  'Modulation V2/C2',  // 1330
  'Modulation V3/C3',  // 1331
  'Modulation Chorus Enhance',  // 1332
  'Scanner Segment Flutter',  // 1333
  'Preemph HP Cutoff Frequ',  // 1334
  'Mod Slope, Preemph HP Phase',  // 1335
  'PHR Speed Vari Slow (Temp)',  // 1336
  'PHR Speed Vari Fast (Temp)',  // 1337
  'PHR Speed Slow (Temp)',  // 1338
  'PHR Feedback (Temp)',  // 1339
  'PHR Lvl Ph1 (Temp)',  // 1340
  'PHR Lvl Ph2 (Temp)',  // 1341
  'PHR Lvl Ph3 (Temp)',  // 1342
  'PHR Lvl Dry (Temp)',  // 1343
  'PHR Feedback Invert (Temp)',  // 1344
  'PHR Ramp Delay (Temp)',  // 1345
  'PHR Mod Vari Ph1 (Temp)',  // 1346
  'PHR Mod Vari Ph2 (Temp)',  // 1347
  'PHR Mod Vari Ph3 (Temp)',  // 1348
  'PHR Mod Slow Ph1 (Temp)',  // 1349
  'PHR Mod Slow Ph2 (Temp)',  // 1350
  'PHR Mod Slow Ph3 (Temp)',  // 1351
  '(RFU)',  // 1352
  'Keyboard Split Point if ON',  // 1353
  'Keyboard Split Mode',  // 1354
  'Keyboard Transp (MIDI OUT)',  // 1355
  'Contact Early Action',  // 1356
  'No 1 Drawbar when Perc ON',  // 1357
  'Drawbar 16 Foldback Mode',  // 1358
  'Higher Foldback',  // 1359
  'Contact Spring Flex',  // 1360
  'Contact Spring Damping',  // 1361
  'Perc Ena On Live DB only',  // 1362
  'Fatar Velocity Factor',  // 1363
  '(none)',  // 1364
  '(none)',  // 1365
  '(none)',  // 1366
  '(none)',  // 1367
  'MIDI Channel',  // 1368
  'MIDI Option',  // 1369
  'MIDI CC Set',  // 1370
  'MIDI Swell CC',  // 1371
  'MIDI Vol CC',  // 1372
  'MIDI Local Ena',  // 1373
  'MIDI Preset CC',  // 1374
  'MIDI Show CC',  // 1375
  '(none)',  // 1376
  '(none)',  // 1377
  '(none)',  // 1378
  '(none)',  // 1379
  '(none)',  // 1380
  '(none)',  // 1381
  '(none)',  // 1382
  '(none)',  // 1383
  'Preamp Swell Type',  // 1384
  'TG Tuning Set',  // 1385
  'TG Size',  // 1386
  'TG Fixed Taper Value',  // 1387
  'TG WaveSet',  // 1388
  'TG Flutter',  // 1389
  'TG Leakage',  // 1390
  'TG Tuning',  // 1391
  'TG Cap Set/Tapering',  // 1392
  'TG LC Filter Fac',  // 1393
  'TG Btm 16 Oct Taper Val',  // 1394
  'Transpose',  // 1395
  'Generator Model Limit',  // 1396
  'Organ Upr Manual Ena',  // 1397
  'Organ Lwr Manual Ena',  // 1398
  'Organ Ped Ena',  // 1399
  'Reverb Lvl 1',  // 1400
  'Reverb Lvl 2',  // 1401
  'Reverb Lvl 3',  // 1402
  '(none)',  // 1403
  '(none)',  // 1404
  '(none)',  // 1405
  '(none)',  // 1406
  '(none)',  // 1407
  'Current Mixt Setup Num',  // 1408
  'Current Vibrato Setup Num',  // 1409
  'Current Phasing Setup Num',  // 1410
  'Current Perc Menu Num',  // 1411
  'Current Reverb Menu Num',  // 1412
  '(none)',  // 1413
  '(none)',  // 1414
  '(none)',  // 1415
  'Mixt DB 10, Lvl from BB 9',  // 1416
  'Mixt DB 10, Lvl from BB 10',  // 1417
  'Mixt DB 10, Lvl from BB 11',  // 1418
  'Mixt DB 10, Lvl from BB 12',  // 1419
  'Mixt DB 10, Lvl from BB 13',  // 1420
  'Mixt DB 10, Lvl from BB 14',  // 1421
  '(none)',  // 1422
  '(none)',  // 1423
  'Mixt DB 11, Lvl from BB 9',  // 1424
  'Mixt DB 11, Lvl from BB 10',  // 1425
  'Mixt DB 11, Lvl from BB 11',  // 1426
  'Mixt DB 11, Lvl from BB 12',  // 1427
  'Mixt DB 11, Lvl from BB 13',  // 1428
  'Mixt DB 11, Lvl from BB 14',  // 1429
  '(none)',  // 1430
  '(none)',  // 1431
  'Mixt DB 12, Lvl from BB 9',  // 1432
  'Mixt DB 12, Lvl from BB 10',  // 1433
  'Mixt DB 12, Lvl from BB 11',  // 1434
  'Mixt DB 12, Lvl from BB 12',  // 1435
  'Mixt DB 12, Lvl from BB 13',  // 1436
  'Mixt DB 12, Lvl from BB 14',  // 1437
  '(none)',  // 1438
  '(none)',  // 1439
  '(none)',  // 1440
  '(none)',  // 1441
  '(none)',  // 1442
  '(none)',  // 1443
  '(none)',  // 1444
  '(none)',  // 1445
  '(none)',  // 1446
  '(none)',  // 1447
  'Rotary Ctrl, Horn Slow Time',  // 1448
  'Rotary Ctrl, Rotor Slow Time',  // 1449
  'Rotary Ctrl, Horn Fast Time',  // 1450
  'Rotary Ctrl, Rotor Fast Time',  // 1451
  'Rotary Ctrl, Horn Ramp Up Time',  // 1452
  'Rotary Ctrl, Rotor Ramp Up Time',  // 1453
  'Rotary Ctrl, Horn Ramp Down Time',  // 1454
  'Rotary Ctrl, Rotor Ramp Down Time',  // 1455
  'Rotary Ctrl, Speaker Throb Amount',  // 1456
  'Rotary Ctrl, Speaker Spread',  // 1457
  'Rotary Ctrl, Speaker Balance',  // 1458
  'Sync PHR',  // 1459
  'Tube Amp Curve 6550 A',  // 1460
  'Tube Amp Curve 6550 B',  // 1461
  '(none)',  // 1462
  '(none)',  // 1463
  'ENA_CONT_BITS, DB 7..0',  // 1464
  'ENA_CONT_BITS, DB 11..8',  // 1465
  'ENA_ENV_DB_BITS, DB 7..0',  // 1466
  'ENA_ENV_DB_BITS, DB 11..8',  // 1467
  'ENA_ENV_FULL_BITS, DB 7..0',  // 1468
  'ENA_ENV_FULL_BITS, DB 11..8',  // 1469
  'ENV_TO_DRY_BITS, DB 7..0',  // 1470
  'ENV_TO_DRY_BITS, DB 11..8',  // 1471
  'ENA_CONT_PERC_BITS, DB 7..0',  // 1472
  'ENA_CONT_PERC_BITS, DB 11..8',  // 1473
  'ENA_ENV_PERCMODE_BITS, DB 7..0',  // 1474
  'ENA_ENV_PERCMODE_BITS, DB 11..8',  // 1475
  'ENA_ENV_ADSRMODE_BITS, DB 7..0',  // 1476
  'ENA_ENV_ADSRMODE_BITS, DB 11..8',  // 1477
  '(none)',  // 1478
  '(none)',  // 1479
  'Perc Norm Lvl',  // 1480
  'Perc Soft Lvl',  // 1481
  'Perc Long Time',  // 1482
  'Perc Short Time',  // 1483
  'Perc Muted Lvl',  // 1484
  '(none)',  // 1485
  'Perc Precharge Time',  // 1486
  'Perc Ena on Live DB only',  // 1487
  '(RFU)',  // 1488
  '(RFU)',  // 1489
  'GM2 Synth Vol',  // 1490
  'Relative Organ Vol',  // 1491
  'H100 Harp Sustain Time',  // 1492
  'H100 2nd Voice Lvl',  // 1493
  '(RFU)',  // 1494
  'LED Dimmer',  // 1495
  '2ndDB Select Voice Num (enabled when 1..15)',  // 1496
  'Vibrato Knob Mode',  // 1497
  'CommonPreset Save/Restore Mask',  // 1498
  '(not used)',  // 1499
  '(not used)',  // 1500
  'Various Configurations 1',  // 1501
  'Various Configurations 2',  // 1502
  'ADC Configuration',  // 1503
  '(not used)',  // 1504
  '(not used)',  // 1505
  'Ped Drawbar Configuration',  // 1506
  'ADC Scaling',  // 1507
  '(not used)',  // 1508
  'HX3.5 Device Type',  // 1509
  'Preset/EEPROM Struct Vers',  // 1510
  'Magic Flag'  // 1511
);

// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################
// ###             Parser für Befehle von serieller Schnittstelle            ###
// #############################################################################
unit parser;

interface
{$IFDEF MODULE}
uses var_def, port_def, sd_card, dataflash, apply_changes, fpga_hilevel,
     nuts_and_bolts, startup, MIDI_com;
{$ELSE}
uses var_def, port_def, sd_card, dataflash, apply_changes, fpga_hilevel,
     nuts_and_bolts, startup, switch_interface, MIDI_com,
     save_restore, switch_interface;
{$ENDIF}

// enable/disable warnings for this unit
{$W+}
{$IDATA}

procedure PA_CheckSer;
procedure PA_HandleCmdString;// SerInpStr parsen

// Parameter-Byte anhand Parameter-Nummer holen
// auch für Menüsystem benutzt. Liefert TRUE wenn Parameter bekannt ist
function PA_GetParamByte(my_param: integer; var my_result: byte;
         from_eeprom: boolean): boolean;

// Wert anhand Parameter-Nummer setzen
// auch für Menüsystem benutzt. Liefert TRUE wenn Parameter bekannt ist
function PA_NewParamEvent(my_param : integer; value : byte;
         to_eeprom: boolean; event_source: Byte): boolean;

// nur innerhalb edit_array, idx_i von 0..511
procedure PA_NewEditEvent(idx_i: integer; value: byte;
         to_eeprom: boolean; event_source: Byte);


procedure PA_SetParam(my_param : integer; verbose : boolean);
procedure PA_GetParamString(my_param: integer);

// INI-File von SD-Karte parsen, liefert TRUE wenn Script gefunden wurde
function PA_RunSDscript(my_ini_filename: string[12]): Boolean;

implementation


{$IDATA}

const
// nur noch allgemeine und Konfigurations-Parameter über Mnemonics!
  cmdAnzahl      : byte = 27; // letzter Eintrag, statt tCmdwhich
  cmdErr         : byte = cmdAnzahl + 1;// Error, Statt tCmdwhich
  CmdStrArr      : array[0..cmdAnzahl] of string[3] = (
    'STR',// Status Request 255
    'IDN',// Identify Version number 254
    'VAL',// 0..9999
    'EDT',// 1000 ff.  alle Edit-Vars
    'PHR',// 2500 ff.  Phasing Rotor Params
    'MXS',// 2800 ff.  Mixture Sets

    'COR',// 7000 Core Load, z.B. COR 192=firmware.bin

    'CFG',// 8000 FPGA Config from Flash
    'UPD',// 8200 Update from SD
    'INI',// 8300 INI-Datei ausführen
    'SCI',// 8500 Scan Core Info, 0=ID, 1=Revision
    'RCB',// 8600 4K-Block überspezielles Protokoll empfangen
    'WFB',// 8601 4K-Block in DataFlash speichern, Param = Blocknummer abs.
    'DFI',// 8800 DF Init Presets
    'RCS',// 8900 Receive Binary Stream (+Core #)

    'FIN',// 9940 Finalisieren, DF Preset INIT
    'KEY',// 9950 DNA Key Eingabe 0 und 1
    'DIR',// 9960 List SD Card Directory
    'EPS',// 9970 EEPROM Save to DF
    'EPR',// 9980 EEPROM Restore from DF
    'DMP',// 9989
    'USR',// 9990 User Name

    'RPE',// 9997 Reset User Interface, DB/Peripherals and ADC/Btn Remap
    'RLD',// 9998 Reload All
    'RST',// 9999 System Reset

    'WEN',// 250 Write enable
    'ERC',// 251 ErrCount seit letztem Reset
    'NOP');

 Cmd2SubChArr   : array[0..cmdAnzahl] of integer   = (
  255, 254,
  0,
  1000, 2500, 2800,
  7000, 8000, 8200, 8300, 8500, 8600, 8601, 8800, 8900,
  9940, 9950, 9960, 9970, 9980, 9989, 9990,
  9997, 9998, 9999,
  250, 251, 253
  );

// #############################################################################


procedure ValueStrToValues;
begin
  ValueLong:= StrToInt(ParamStr);
  ValueInt:= integer(ValueLong);
  ValueByte:= byte(ValueInt);
end;

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************

procedure send_osc_store_led;
begin
  if ConnectMode = t_connect_osc_midi then
    MIDI_SendBoolean(3, 90, PresetStoreRequest);  // Store Request LED MIDI
  endif;
  if ConnectMode = t_connect_osc_wifi then
    NB_SendBinaryVal(1640, byte(PresetStoreRequest) and $40); // Store Request LED OSC
  endif;
end;

// *****************************************************************************
{$ENDIF}
// *****************************************************************************


// #############################################################################
// GET BYTE
// #############################################################################

function PA_GetParamByte(my_param : integer; var my_result : byte;
                      from_eeprom : boolean) : boolean;
// liefert TRUE wenn Parameter bekannt ist
var
  my_index_1000, my_index_100, my_index_10  : byte;
  my_int: integer;

begin
  my_index_1000:= byte(my_param mod 1000);
  my_index_100:= byte(my_param mod 100);
  my_index_10:= my_index_100 mod 10; // angespr. Register 0..9 errechnen aus SubCh-Rest
  my_result:= 0;
  case my_param of
{$IFDEF MODULE}
    900..905:  // Dummy für neuen Editor mit Spartan-7 auf Böhm Modul
               my_result:= 0;
               |
{$ELSE}
    900..903: // Preset-Nummer holen: Common, Upper, Lower, Pedal
               my_result:= edit_voices[my_index_10];
               edit_voices_old[my_index_10]:= 255;  // Neuladen erzwingen
               |
{$ENDIF}
    1000..1511:// edit_array
               my_int:= my_param - 1000; // auf 0..511 bringen
               if from_eeprom then
                 my_result:= edit_CompareArray[my_int];
               else
                 my_result:= edit_array[my_int];
               endif;
               |
    1600:
               my_result:= midi_swell128;
               |
{$IFNDEF MODULE}
    2000..2023 : // Reverb DSP Init
               my_result:= eep_SAM_RevDSP_Init[my_index_100];
               |
{$ENDIF}
    2100..2163 : // Leslie Inits
               my_result:= edit_LeslieInits[my_index_100];
               |
    2200..2327 : // 8 Vibrato Parameter-Tabellen für OEM Modul
               my_int:= my_param - 2200;
               my_result:= eep_ScannerVibSetDump[my_int];
               |
    2500..2627 :
               // Phasing-Rotor Parameter-Tabelle Byte Delays etc.
               my_int:= my_param - 2500;
               my_result:= eep_PhasingRotorDump[my_int];
               |
    2700..2739 : // Busbar-Tabellen
               my_result:= eep_BusBarNoteOffsetTables[my_index_100];
               |
    2800..2929 : // Mixtur-Tabellen
               my_int:= my_param - 2800;
               my_index_1000 := byte(my_int); // auf 0..255 bringen
               my_result:= eep_MixtureTables[my_index_1000];
               |
    3000..3311:
               case my_param of
                 3000..3011:
                   my_result:= eep_Pedal4DBfacs16[my_index_100];
                   |
                 3100..3111:
                   my_result:= eep_Pedal4DBfacs16H[my_index_100];
                   |
                 3200..3211:
                   my_result:= eep_Pedal4DBfacs8[my_index_100];
                   |
                 3300..3311:
                   my_result:= eep_Pedal4DBfacs8H[my_index_100];
                   |
               endcase;
               |

{$IFNDEF MODULE}
    3500..3595 : // FatarScan76-Tabellen
               my_result:= eep_fs76_arr_dump[my_index_100];
               |
    3600..3615 : // je 4 FatarScan76-Werte vom I2C-Slave
               my_result:= 0;
               NB_GetBytefromI2Cslave((my_index_100 div 4) + $5A, my_index_100 mod 4, my_result);
               |

    5000..5087 :// ADC input Remaps
               my_result:= eep_ADCremaps[my_index_100];
               |
    5100..5195 :// Button Remaps Panel16
               my_result:= eep_BtnRemaps[my_index_100];
               |
    5200..5295 :// Button Remaps Panel16
               my_result:= byte(eep_SwitchInputArr[my_index_100]);
               |
    5300..5331 : // Button Remaps XB2
               my_result:= eep_BtnRemaps_XB[my_index_100];
               |
    5400..5415 : // Organ Model Assignments
               my_result:= eep_OrganModelAssignments[my_index_100];
               |
    5500..5515 : // Speaker Model Assignments
               my_result:= eep_SpeakerModelAssignments[my_index_100];
               |
    6000..6199 : // MenuValidArray Booleans
               my_result:= byte(eep_MenuValidArr[my_param - 6000]);
               |

    6200..6215: // Button Test
               my_result:= SWI_InputBytes[my_index_100];
               |
    6300..6387: // Analog Test
               my_result:= byte(ADC_Values[my_index_100]);
               |
{$ENDIF}
  else
    Incl(ErrFlags, c_err_cmd);
    return(false);
  endcase;
  return(true);
end;

// #############################################################################
// GET allgemein
// #############################################################################

procedure PA_GetParamString(my_param : integer);
var
  my_index_100: byte;
  my_word: Word;
begin
  my_index_100:= byte(my_param mod 100); // angespr. Register 0..9 errechnen aus SubCh-Rest

  case my_param of
    0..249    :// FPGA-Lese-Register
              ValueLong:= ReceiveFPGA(byte(my_param));
              WriteLongSerHex(ValueLong);
              |
    250       :// Schreibschutz auslesen
              WriteBoolSer(EEunlocked);
              |
    253       :// SerTest, gibt Input-String komplett und unverändert wieder aus
              Writeln(Serout, SerInpStr);
              return;
              |
    254:      // Version
              ParamStr:= Vers1Str + ' [' + Vers2Str + Vers3Str + ']';
              Writeln(Serout, ParamStr);
              |
    255:      // Status
              SerPromptErrFlags(255, -1);
              |

    300..3999, 5000..6387:  // Parameter mit Byte-Ergebnis
              if PA_GetParamByte(my_param, ValueByte, EEunlocked) then
                WriteByteSer(ValueByte);
              else
                Serprompt(c_err_cmd, my_param, -1);
              endif;
              |

    4000..4767: // Custom-CC-Tabellen,
              // 4 Bytes gepackt als 32-Bit-Werte: (msb) MIN MAX CH CC (lsb)
              my_param:= my_param - 4000;
              ValueLong0:= MIDIset_CCarray[my_param];
              ValueLong1:= MIDIset_CHarray[my_param];
              ValueLong2:= MIDIset_CCmaxArray[my_param];
              ValueLong3:= MIDIset_CCminArray[my_param];
              WriteLongSer(ValueLong);
              |
    4768..4799: // Custom-NRPN-Tabelle,
              my_param:= my_param - 4768;
              ValueLong:= MIDIset_NRPNarrayLongInt[my_param];
              WriteLongSer(ValueLong);
              |
    8202      :// Boot-Flash-Signatur in AVR
              WriteLongSerHex(longint(c_CurrentFirmwareVersion));
              |
    8203      :// FPGA-Signatur, aktuell geladen
              ValueLong:= ReceiveFPGA(3);
              WriteLongSerHex(ValueLong);
              |
    8204      :// DSP-Signatur/Version, aktuell geladen
              ValueLong:= LongInt(DSPversion);
              WriteLongSerHex(ValueLong);
              |
    8500:     // ScanCore Info
              FI_GetScanCoreInfo;  // Meldung über Scancore ausgeben
              WriteByteSer(ScanCoreID);
              |
    8501:     // SCI? FI_GetScanCoreInfo Info
              FI_GetScanCoreInfo;  // Meldung über Scancore ausgeben
              WriteByteSer(ScanCoreRevision);
              |

    8510:     // Checksum FW Update
              my_word:= DF_getChecksum(c_firmware_base35_DF, c_firmware_base35_DF + $1F);
              WriteLongSer(LongInt(my_word));
              |

    8511:     // Checksum EEPROM Update
              my_word:= DF_getChecksum(c_defaults_base_DF, c_defaults_base_DF);
              WriteLongSer(LongInt(my_word));
              |

    8529:      // HashadowMem für FPGA und ScanCore; liefert bei alten Versionen Fehler -1
              WriteByteSer(0);
              |

    9000:     // Zuletzt empfangene MIDI-Daten: 00, cmd, cc, val als LongInt
              WriteLongSer(midi_received);
              |
    9001:     // Zuletzt empfangener MIDI-NRPN-Code
              WriteLongSer(LongInt(midi_nrpn));
              |
    9800..9899: // Get Preset Names
              DF_GetPresetNameStr(my_index_100);
              WriteCommentSer;
              |

    9902:
              WriteByteSer(byte(ConnectMode));
              |
    9940      :// FIN? Finalize mit aktueller EEPROM-/Preset-Struktur anzeigen
              WriteByteSer(c_FirmwareStructureVersion);
              |
    9950:     // Freischaltcodes anzeigen
              ValueLong:= EE_DNA_0; // Organ Licence
              WriteLongSer(EE_DNA_0);
              |
    9951:
              ValueLong:= EE_DNA_1; // Extended/Leslie Licence
              WriteLongSer(EE_DNA_1);
              |
    9952:
{$IFNDEF MODULE}
              MIDI_SendNRPN($357E, 127); // Request DSP Version Info
{$ENDIF}
              ValueLong:= ReceiveFPGA(242);
              WriteLongSer(ValueLong);
              |

    9960:// Card dir
              WriteByteSer(SD_GetDir('*.*', true));
              |
    9990:// Owner info
              CommentStr:= 'OWNER: ' + EE_owner;
              WriteCommentSer;
              |

  else
    serprompt(c_err_cmd, my_param, -1);
  endcase;
end;


// #############################################################################
// #####           STANDARD-EVENT: Parameter-Wert geändert                 #####
// #############################################################################

procedure PA_NewEditEvent(idx_i: Word; value: byte;
         to_eeprom: boolean; event_source: Byte);
var
  my_bool: boolean;
  val_ltd: Byte;
begin
  if not valueInRange(idx_i, 0, 511) then
    return;
  endif;
  my_bool:= value <> 0;
  val_ltd:= valueTrimLimit(value, 0, c_edit_max[idx_i]);

  // in edit_array, nicht in EEPROM, möglichst schnell erledigen
  case idx_i of
{$IFNDEF MODULE}
    0000..0011:
      edit_UpperIndirect_DBs[edit_ActiveUpperIndirect, lo(idx_i)]:= val_ltd;
      if UpperIsLive then
        Temp_VoiceUpperDrawbars[lo(idx_i)]:= val_ltd;
      endif;
      |
    0016..0027:
      edit_LowerIndirect_DBs[edit_ActiveLowerIndirect, lo(idx_i) - 16]:= val_ltd;
      if LowerIsLive then
        Temp_VoiceLowerDrawbars[lo(idx_i) - 16]:= val_ltd;
      endif;
      |
{$ENDIF}
    0121, 0128..0191:      // Tabs?
      // wichtig, sonst wird "not XXX" bei Werten <> 255 falsch ausgeführt!
      val_ltd:= byte(my_bool);
      if idx_i = 0143 then   // Split ON/OFF
        ForceSplitRequest:= true;
      endif;
      |
  endcase;
  NewEditIdxEvent(idx_i, val_ltd,  event_source);
{$IFNDEF MODULE}
  if edit_CommonPreset = 0 then
    Temp_Common[idx_i]:= val_ltd;
  endif;
{$ENDIF}

  if to_eeprom then // and (my_param <> 1268)   // nicht edit_CommonPreset!
    edit_CompareArray[idx_i]:= val_ltd;
    case idx_i of
    0320..0335: // in Vibrato Group?
      eep_ScannerVibSets[edit_CurrentVibratoSet, idx_i - 320]:= val_ltd;
      eep_defaults[idx_i]:= val_ltd;
      |
    0336..0351: // 1336..1351 PHR Temp
      eep_PhasingRotorSets[edit_CurrentPhasingSet, idx_i - 336]:= val_ltd;
      eep_defaults[idx_i]:= val_ltd;
      |
    0496..0511: // System Inits nur in Permanent-EEPROM
      EE_InitsGroup[idx_i - 496]:= val_ltd;
      |
    else
      eep_defaults[idx_i]:= val_ltd;
    endcase;
  endif;

{$IFNDEF MODULE}
  case idx_i of
  0501:
    SWI_InitButtons;
    |
  0503:
    ADC_Init;
    |
  endcase;
{$ENDIF}
end;

procedure pa_send_osc_store_led;
begin
  if ConnectMode = t_connect_osc_midi then // OSCconnectedByMIDI
    MIDI_SendBoolean(3, 90, PresetStoreRequest);  // Store Request LED MIDI
  elsif ConnectMode = t_connect_osc_wifi then
    NB_SendBinaryVal(1640, byte(PresetStoreRequest) and $40); // Store Request LED OSC
  endif;
end;

procedure pa_send_osc_store_led_off;
begin
  PresetStoreRequest:= false;
  pa_send_osc_store_led;
end;


function PA_NewParamEvent(my_param : integer; value : byte;
         to_eeprom: boolean; event_source: Byte): boolean;
// liefert TRUE wenn Parameter bekannt ist
var
  my_index_1000, my_index_100, my_index_10: byte;
  my_bool: boolean;
  my_word, my_index_1000_i: Word;

begin
  my_index_1000_i:= word(my_param) mod 1000;
  // wg. Geschwindigkeit Edit-Parameter vorab behandeln
  if valueinRange(my_param, 1000, 1511) then
    PA_NewEditEvent(my_index_1000_i, value, to_eeprom, event_source);
    return(true);
  endif;

  my_index_1000:= lo(my_index_1000_i);
  my_index_100:= byte(my_param mod 100);
  my_index_10:= my_index_100 mod 10;
  my_bool:= value <> 0;

  case my_param of
    250:
      EEunlocked:= my_bool;  // für Binary-Parser
      |
{$IFDEF MODULE}
    900..909:  // Dummy für neuen Editor mit Spartan-7 auf Böhm Modul
      |
{$ELSE}
    900..903: // Preset-Nummer setzen: Common, Upper, Lower, Pedal
      // und aktuelle Werte dort als Preset abspeichern
      edit_voices[my_index_10]:= value;
      case my_index_10 of
        0: SaveCommonPreset(value);
          |
        1: SaveUpperVoice;
          |
        2: SaveLowerVoice;
          |
        3: SavePedalVoice;
          |
      endcase;
      |
    905, 907: // Store Defaults/Extended, durch WEN EEPROM erledigt
      |
    906: // Store System Inits, durch WEN EEPROM erledigt
      for my_word:= 0 to 4095 do
        BlockBuffer8[my_word]:= EE_dumpArr[my_word];
      endfor;
      DF_EraseWriteblock(c_eeprom_base35_DF, 4096);
      |
    908: // Store Organ Model
      edit_OrganModel:= value and 15;
      SR_StoreOrganModel(edit_OrganModel);
      |
    909: // Store Speaker/Rotary Model
      edit_SpeakerModel:= value and 15;
      SR_StoreSpeakerModel(edit_SpeakerModel);
      |
{$ENDIF}
    1600:
      midi_swell128:= value;
      SwellPedalControlledByMIDI:= true;
      |
// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************
//    1520..1531: // Send MIDI CCs, in ADC_ChangeToRemap erledigt
//      |
    1605..1608:// Preset Store
      case my_index_10 of
        5:
          if PresetStoreRequest then
            send_osc_store_led;
              DT_MsgSaveDoneBlink('C');
            SaveCommonPreset(edit_CommonPreset);
            pa_send_osc_store_led_off;
            if ConnectMode = t_connect_osc_wifi then
              writeln(serOut);
              writeln(serOut, '/label_preset="' + CurrentPresetName + '"');
            endif;
          else
            edit_CommonPreset_flag:= c_to_fpga_event_source;
          endif;
          |
        6:
          if PresetStoreRequest then
            send_osc_store_led;
            SR_UpperTempToLive;
            DT_MsgSaveDoneBlink('U');
            SaveUpperVoice;
            pa_send_osc_store_led_off;
          else
            LoadUpperVoice(edit_UpperVoice);
          endif;
          |
        7:
          if PresetStoreRequest then
            send_osc_store_led;
            SR_LowerTempToLive;
            DT_MsgSaveDoneBlink('L');
            SaveLowerVoice;
            pa_send_osc_store_led_off;
          else
            LoadLowerVoice(edit_LowerVoice);
          endif;
          |
        8:
          if PresetStoreRequest then
            send_osc_store_led;
            SR_PedalTempToLive;
            DT_MsgSaveDoneBlink('P');
            SavePedalVoice;
            pa_send_osc_store_led_off;
          else
            LoadPedalVoice(edit_PedalVoice);
          endif;
          |
      endcase;
      |
    1609:
      if my_bool then
        PresetStoreRequest:= not PresetStoreRequest;
        send_osc_store_led;
        ToggleLEDcount:= 0;
        if PresetStoreRequest then
          SR_UpperLiveToTemp;
          SR_LowerLiveToTemp;
          SR_PedalLiveToTemp;
          SR_PresetLiveToTemp;
        endif;
      endif;
      |
    1610:// Start OSCconnectedBySerial Mode, HX3 sendet Parameter-Änderungen, binär
      MIDI_RequestAllGMnames;
      FlushBuffer(RxBuffer);
      ConnectMode:= t_connect_osc_wifi;  // Abschalten mit 9902=0
      DisplayHeader('OSC Connect...');
      mdelay(100);
      NB_SendBinaryVal(1610, 127); // Connect Button ON (dummy für Re-Connect)
      mdelay(1000);    // Zeit für IP-Meldung von WiFi-Interface
      NB_SendBinaryVal(1610, 127); // Connect Button ON
      NB_SendBinaryVal(1649, 64); // LED Blink
      writeln(serout, '/page/1=0'); // für alte Versionen
      NB_SendBinaryVal(1650, 0); // Page
      mdelay(100);
      writeln(serout); // sync Text
      write(serout, '/label_fw_version="HX3.5 Version '); // Versionsnummer HX3
      write(serout, Vers1Str);
      writeln(serout, '"');
      writeln(serout); // sync Text
      writeln(serout, '/label_wait="Please wait..."');
      NB_SendBinaryVal(1610, 0); // Connect Button OFF (dummy)
      mdelay(100);    // Zeit für IP-Meldung von WiFi-Interface
      NB_SendBinaryAllOSCvals;     // einschl. Preset-Nummern
      mdelay(500);
      writeln(serout, '/label_preset="' + c_PresetNameStr0 + '"'); // Preset-Namen
      writeln(serout, '/label_wait=""');
      writeln(serout, '/page/1=127'); // für alte Versionen
      mdelay(100);    // Zeit für IP-Meldung von WiFi-Interface
      MenuIndex_Requested:= 0;
      NB_SendBinaryVal(1697, 127); // Param Invalidate Extended
      mdelay(500);
      NB_SendBinaryVal(1650, 1); // Page
      |
    1620..1627:
      // Alias INCs/DECs Presets, Voices, Organ & Speaker Models
      if my_bool then       // Alias auf 8 IncDec-Buttons #1192 ff.
        NewEditIdxEvent(Word(my_param) - 1428, 255, event_source); // -1620 +192
      endif;
      |
    1628..1639:  // INCs/DECs für Custom MIDI, wurde bereits in WIFI-IF erledigt!
      if my_bool then
        AC_IncDecGMprogs(my_index_100 - 28, event_source);    // TODO!
      endif;
      |
    1642..1645:
      // Alias INCs/DECs Presets, Voices, Organ & Speaker Models
      if my_bool then       // Alias auf 8 IncDec-Buttons #1192 ff.
        NewEditIdxEvent(Word(my_param) - 1442, 255, event_source); // -1642 +200
      endif;
      |
    1650: // #1650 TouchOSC Page Select, Einstellung vorbelegen
      // Organ Model Preconfig (sets Gating & GenVib)
      // 0 'B3/9 DrB   ',  // edit_GatingMode=0, edit_GenVibMode=0
      // 1 'H100/12 Drb',  // edit_GatingMode=1, edit_GenVibMode=3
      // 2 'ElectronGat',  // edit_GatingMode=2, edit_GenVibMode=4
      // 3 'EG PercDrwb',  // edit_GatingMode=3, edit_GenVibMode=5
      // 4 'EG TimeDrwb'); // edit_GatingMode=4, edit_GenVibMode=6
      NB_SendBinaryVal(1610, 0); // Connect Button OFF
      case value of
        0: // Start page
        // NB_SendBinaryVal(1680, 0);  // Progress Bar
        writeln(serout); // sync Text
        writeln(serout, '/label_wait=" "'); // "Please Wait..." löschen
        |
        1,2: // B3/Basic Pages
        edit_OrganModel:= 0;
        edit_OrganModel_flag:= event_source;
        |
        3,4: // H100 Pages
        edit_OrganModel:= 1;
        edit_OrganModel_flag:= event_source;
        |
        5,6: // EG Mode Pages, keine Änderung wenn bereits EG Mode
        if edit_OrganModel < 2 then // vorheriger Wert
          edit_OrganModel:= 2; // Basiseinstellung EG-Mode
          edit_OrganModel_flag:= event_source;
        endif;
        |
      endcase;
      MenuRefresh:= true;
      |

    1651:  // Page B3
      // OrganSetup => Keying-Grundeinstellung
      // 0 'B3/9 DrB   ',  // edit_GatingMode=0, edit_GenVibMode=0
      // 1 'H100/12 Drb',  // edit_GatingMode=1, edit_GenVibMode=3
      // 2 'ElectronGat',  // edit_GatingMode=2, edit_GenVibMode=4
      // 3 'EG PercDrwb',  // edit_GatingMode=3, edit_GenVibMode=5
      // 4 'EG TimeDrwb'); // edit_GatingMode=4, edit_GenVibMode=6
      edit_OrganModel:= 0;
      edit_OrganModel_flag:= event_source;
      MenuRefresh:= true;
      |
    1653,1654:  // Page H100
      // OrganSetup => Keying-Grundeinstellung
      // 0 'B3/9 DrB   ',  // edit_GatingMode=0, edit_GenVibMode=0
      // 1 'H100/12 Drb',  // edit_GatingMode=1, edit_GenVibMode=3
      // 2 'ElectronGat',  // edit_GatingMode=2, edit_GenVibMode=4
      // 3 'EG PercDrwb',  // edit_GatingMode=3, edit_GenVibMode=5
      // 4 'EG TimeDrwb'); // edit_GatingMode=4, edit_GenVibMode=6
      edit_OrganModel:= 1;
      edit_OrganModel_flag:= event_source;
      MenuRefresh:= true;
      |
    1655,1656:  // Pages EG Mode
      if edit_OrganModel < 2 then // vorheriger Wert
        edit_OrganModel:= 2; // Basiseinstellung EG-Mode
        edit_OrganModel_flag:= event_source;
        MenuRefresh:= true;
      endif;
      |
    1670:  // Temp Perc Enable
      MIDI_DisablePercussion:= false;
      MIDI_OverrideCancelDB1:= false;
      edit_LogicalTab_PercON_flag:= event_source;
      |
    1671:  // Temp Perc Disable
      MIDI_DisablePercussion:= true;
      MIDI_OverrideCancelDB1:= true;
      edit_LogicalTab_PercON_flag:= event_source;
      |
    // 1672 nicht benutzen, war vorher Audio Enable
    1674:  // Temp Perc Enable
      MIDI_DisablePercussion:= not my_bool;
      MIDI_OverrideCancelDB1:= not my_bool;
      edit_LogicalTab_PercON_flag:= event_source;
      |
    1677:  // Upper/Lower/Pedal Audio Enable
      edit_EnableUpperAudio:= Bit(value, 0);
      edit_EnableLowerAudio:= Bit(value, 1);
      edit_EnablePedalAudio:= Bit(value, 2);
      edit_EnableUpperAudio_flag:= event_source;
      edit_EnableLowerAudio_flag:= event_source;
      edit_EnablePedalAudio_flag:= event_source;
      |
    1680..1685:  // Set Vibrato on Range match
      edit_VibKnob:= my_index_100 - 80;
      edit_VibKnob_flag:= event_source;
      |
    1686:  // Set rotary RUN SLOW
      edit_LogicalTab_LeslieRun:= true;
      edit_LogicalTab_LeslieFast:= false;
      edit_LogicalTab_LeslieRun_flag:= event_source;
      edit_LogicalTab_LeslieFast_flag:= event_source;
      |
    1687:  // Set rotary RUN FAST
      edit_LogicalTab_LeslieRun:= true;
      edit_LogicalTab_LeslieFast:= true;
      edit_LogicalTab_LeslieRun_flag:= event_source;
      edit_LogicalTab_LeslieFast_flag:= event_source;
      |
    1688:  // Set rotary STOP
      edit_LogicalTab_LeslieRun:= false;
      edit_LogicalTab_LeslieRun_flag:= event_source;
      |
    1689:  // Set rotary RUN
      edit_LogicalTab_LeslieRun:= true;
      edit_LogicalTab_LeslieRun_flag:= event_source;
      |
    // 1697 an ESP: Alle Parameter neu an OSC senden
    // 1698 an ESP:  // Wifi EEPROM Init to Defaults
    // 1699 an ESP:  // Wifi Reset

    1690..1695: // Indirekte Drawbar-Sets Upper A/B und Lower A/B
      if my_index_10 < 3 then
        edit_UpperDBs_flag[0]:= event_source;
      else
        edit_LowerDBs_flag[0]:= event_source;
      endif;
      case my_index_10 of
      0:  // Activate A Upper
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveUpperIndirect:= 0;
        CopyBlock(@edit_UpperIndirectA_DBs, @edit_UpperDBs, 12);
        MIDI_DisablePercussion:= false;
        edit_LogicalTab_PercON_flag:= event_source;
        |
      1:  // Activate to B Upper
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveUpperIndirect:= 1;
        CopyBlock(@edit_UpperIndirectB_DBs, @edit_UpperDBs, 12);
        MIDI_DisablePercussion:= true;
        edit_LogicalTab_PercON_flag:= event_source;
        |
      2:  // switch A/B Upper
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveUpperIndirect:= ValueTrimLimit(value, 0, 1);
        if edit_ActiveUpperIndirect = 0 then
          CopyBlock(@edit_UpperIndirectA_DBs, @edit_UpperDBs, 12);
          MIDI_DisablePercussion:= false;
        else
          CopyBlock(@edit_UpperIndirectB_DBs, @edit_UpperDBs, 12);
          MIDI_DisablePercussion:= true;
        endif;
        edit_LogicalTab_PercON_flag:= event_source;
        |
      3:  // Activate to A Lower
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveLowerIndirect:= 0;
        CopyBlock(@edit_LowerIndirectA_DBs, @edit_LowerDBs, 12);
        |
      4:  // Activate to B Lower
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveLowerIndirect:= 1;
        CopyBlock(@edit_LowerIndirectB_DBs, @edit_LowerDBs, 12);
        |
      5:  // switch A/B Lower
        MIDI_OverrideCancelDB1:= false;
        edit_ActiveLowerIndirect:= ValueTrimLimit(value, 0, 1);
        if edit_ActiveLowerIndirect = 0 then
          CopyBlock(@edit_LowerIndirectA_DBs, @edit_LowerDBs, 12);
        else
          CopyBlock(@edit_LowerIndirectB_DBs, @edit_LowerDBs, 12);
        endif;
        |
      endcase;
      |
    1700..1747: // Indirekte Drawbar-Sets Upper A/B und Lower A/B
      MIDI_OverrideCancelDB1:= false;
      edit_Indirect_DBs[my_index_100]:= value;
      // Wenn aktiv, gleich an "richtige" Drawbars durchreichen
      case my_index_100 of
      0..11:
        if edit_ActiveUpperIndirect = 0 then
          edit_UpperDBs[my_index_100]:= value;
          edit_UpperDBs_flag[0]:= event_source;
        endif;
        |
      12..23:
        if edit_ActiveUpperIndirect >= 1 then
          dec(my_index_100, 12);
          edit_UpperDBs[my_index_100]:= value;
          edit_UpperDBs_flag[0]:= event_source;
        endif;
        |
      24..35:
        if edit_ActiveLowerIndirect = 0 then
          dec(my_index_100, 24);
          edit_LowerDBs[my_index_100]:= value;
          edit_LowerDBs_flag[0]:= event_source;
        endif;
        |
      36..47:
        if edit_ActiveLowerIndirect >= 1 then
          dec(my_index_100, 36);
          edit_LowerDBs[my_index_100]:= value;
          edit_LowerDBs_flag[0]:= event_source;
        endif;
        |
      endcase;
      |
    2000..2023 : // Reverb DSP Init
      edit_SAM_RevDSP_Init[my_index_1000]:= value;
      if to_eeprom then
        eep_SAM_RevDSP_Init[my_index_1000]:= value;
      endif;
      FH_SendReverbTabs;
      |
// *****************************************************************************
{$ENDIF}
// *****************************************************************************

    2100..2163 : // Leslie Inits
      edit_LeslieInits[my_index_100]:= value;
      FH_SendLeslieInitsToFPGA;
      AC_SendLeslieLiveParams;
      |

    2500..2627 : // 8 Phasing-Rotor Parameter-Tabellen
      my_word:= Word(my_param) - 2500;
      my_index_1000 := byte(my_word); // auf 0..255 bringen
      edit_PhasingGroup[my_index_1000 mod 16]:= value;
      if to_eeprom then
        eep_PhasingRotorDump[my_index_1000]:= value;
      endif;
      edit_PhasingGroup_flag[0]:= event_source;
      |

    3000..3311:
      if to_eeprom then
        case my_param of
          3000..3011:
            eep_Pedal4DBfacs16[my_index_100]:= value;
            |
          3100..3111:
            eep_Pedal4DBfacs16H[my_index_100]:= value;
            |
          3200..3211:
            eep_Pedal4DBfacs8[my_index_100]:= value;
            |
          3300..3311:
            eep_Pedal4DBfacs8H[my_index_100]:= value;
            |
        endcase;
        FH_PedalDrawbarsToFPGA;
      endif;
      |
// *****************************************************************************
{$IFNDEF MODULE}
// *****************************************************************************
    3500..3595 : // FatarScan76-Tabellen
      if to_eeprom then
        eep_fs76_arr_dump[my_index_100]:= value;
      endif;
      NB_SendBytetoI2Cslave((my_index_100 div 24) + $5A, my_index_100 mod 24, value);
      |

    5000..5087 : // ADC input Remaps, internal mk4 inputs
      // Index: Analogeingang fortlaufend,
      // Wert: Parameter-Index in edit_table_0 (<80) oder edit_table_1
      ADC_SetRemapTable(my_index_100, value);
      if to_eeprom then
        eep_ADCremaps[my_index_100]:= value;
      endif;
      |
    5100..5195 : // Button Remaps Panel16
      // Index: Button/Switch-Nummer fortlaufend,
      // Wert:  Bit-Index in edit_LogicalTabs (fortlaufende Bit-Nummer)
      BtnRemaps[my_index_100]:= value; // Inhalt wie EEPROM 5100.5163
      if to_eeprom then
        eep_BtnRemaps[my_index_100]:= value;
      endif;
      SWI_InitButtons;
      |
    5200..5295 : // Button/Switch Selects
      BtnSwitchSelects[my_index_100]:= my_bool; // Inhalt wie EEPROM 5100.5163
      if to_eeprom then
        eep_SwitchInputArr[my_index_100]:= my_bool;
      endif;
      SWI_InitButtons;
      |
    5300..5331 : // Button Remaps XB2
      // Index: Button/Switch-Nummer fortlaufend,
      // Wert:  Bit-Index in edit_LogicalTabs (fortlaufende Bit-Nummer)
      BtnRemaps_XB[my_index_100]:= value;
      if to_eeprom then
        eep_BtnRemaps_XB[my_index_100]:= value;
      endif;
      |
    5400..5415 : // Organ Model Assignments
      if to_eeprom then
        eep_OrganModelAssignments[my_index_100]:= value;
      endif;
      |
    5500..5515 : // Speaker Model Assignments
      if to_eeprom then
        eep_SpeakerModelAssignments[my_index_100]:= value;
      endif;
      |
    6000..6199 : // MenuValidArray
      if to_eeprom then
        eep_MenuValidArr[my_param - 6000]:= my_bool;
      endif;
      |
// *****************************************************************************
{$ENDIF}
// *****************************************************************************
  else
    Incl(ErrFlags, c_err_cmd);
    return(false);
  endcase;
  return(true);
end;

// #############################################################################
// SET ALLGEMEIN
// #############################################################################

procedure PA_SetParam(my_param : integer; verbose : boolean);
var
  my_Index_100, my_index_10  : byte;
  my_word                : word;
  my_bool                : boolean;
  my_int                 : integer;

begin
  my_Index_100:= byte(my_param mod 100); // angespr. Register 0..9 errechnen aus SubCh-Rest
  my_index_10:= my_Index_100 mod 10;
  my_bool:= ValueByte <> 0;
  Excl(ErrFlags, c_err_cmd);
  case my_param of
    0..239     :// FPGA-Schreibregister Wort, auch Default-Auto-Increment
               TimeSlot:= 15;// zählt wieder rauf bis 0, SPI-Updates über AVR verhindern
               SendWordToFPGA(word(ValueInt), byte(my_param));
               |
    240..249   :// FPGA-Schreibregister Langwort
               SendLongToFPGA(ValueLong, byte(my_param));
               |
    250        :// WEN
               EEunlocked:= my_bool;
               |
    300..3999, 5000..6199: // Parameter mit Byte-Ergebnis, kann nur vom Editor kommen
               if not PA_NewParamEvent(my_param, ValueByte, EEunlocked, c_editor_event_source) then
                 Serprompt(c_err_cmd, my_param, -1);
                 return;
               endif;
               |

    4000..4767:// Custom-CC-Tabellen beschreiben, temporär
               // 4 Bytes gepackt als 32-Bit-Werte: MIN MAX CH CC
               my_param:= my_param - 4000;
               MIDIset_CCarray[my_param]:= ValueLong0;
               MIDIset_CHarray[my_param]:= ValueLong1; // mit Mode-Nibble!
               if my_param <= 0751 then
                 // hier kein Index > 751, da von Namen belegt
                 MIDIset_CCmaxArray[my_param]:= ValueLong2; // MAX
                 MIDIset_CCminArray[my_param]:= ValueLong3; // MIN
               endif;
               NB_CreateInverseCCarrays;
{$IFNDEF MODULE}
               MIDI_SendSustainSostEnable;
{$ENDIF}
               |
    4768..4799:// Custom-NRPN-Tabellen beschreiben, temporär
               my_param:= my_param - 4768;
               MIDIset_NRPNarrayLongInt[my_param]:= ValueLong;
               |
    4800..4815:// CC-Set 0..15 aus DF holen
               if my_bool then
                 NB_CCarrayFromDF(my_Index_100);
{$IFNDEF MODULE}
                 MIDI_SendSustainSostEnable;
{$ENDIF}
               endif;
               |
    4900..4915:// Speichern des gerade mit 8600=3200 oder SysEx geladenen
               // oder mit 4921=1 umkopierten BlockArrays als
               // CC-Set 0..15 in DF (4 bis 10 belegt)
               if my_bool then
                 if not DF_Store4kBlock(c_midicc_base_DF + word(my_Index_100), c_midiarr_dflen) then
                   serprompt(c_err_conf, my_param, -1);
                   return;
                 endif;
                 CopyBlock(@BlockBuffer8, @MIDIset_Array, c_midiarr_len);
                 edit_MIDI_CC_Set:= my_Index_100;  // CC Set
                 NB_CreateInverseCCarrays;
{$IFNDEF MODULE}
                 MIDI_SendSustainSostEnable;
{$ENDIF}
               endif;
               |
    4920:      // Umkopieren des gerade mit 8600=3200 oder SysEx geladenen BlockArrays
               // in MIDIset_Array zum Test als Custom 1 CC
               if my_bool then
                 CopyBlock(@BlockBuffer8, @MIDIset_Array, c_midiarr_len);
                 edit_MIDI_CC_Set:= 9;  // CC Set
                 NB_CreateInverseCCarrays;
{$IFNDEF MODULE}
                 MIDI_SendSustainSostEnable;
{$ENDIF}
               endif;
               |
    4921:      // Umkopieren des aktuellen MIDIset_Array in BlockBuffer8
               // zum erneuten Speichern mit 4900..4915
               if my_bool then
                 CopyBlock(@MIDIset_Array, @BlockBuffer8, c_midiarr_len);
               endif;
               |
    8000:      // FPGA Load from SD to SPI Flash
               // StartAdresse 0 für FPGA-Image
               if ParamAlpha then
                 SD_ForceCheck;
                 if SD_present then
                   if SD_FlashBinFile(0, ParamStr) <> df_noErr then
                     Serprompt(c_err_conf, my_param, -1);
                     return;
                   endif;
                 else
                   serprompt(c_err_sd, my_param, -1);
                   return;
                 endif;
               else
                 serprompt(c_err_cmd, my_param, -1);
                 return;
               endif;
               |

    8200:      // UPD, FileLoad from SD to SPI Flash, alle Standard-Dateien versuchen
               if my_bool and SD_ForceCheck then
                 SD_LoadAndFlashAllBinCores(true, true);// anschließend FW-Flash und Reset!
                 if ConfErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |
    8201:      // UPD 1, nur Firmware updaten
               if my_bool and SD_ForceCheck then
                 SD_LoadAndFlashAllBinCores(false, true); // anschließend FW-Flash und Reset!
                 if ConfErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |

    8202:      // UPD 2, FPGA and Cores config Flash from SD, nicht AVR FW-flash
               if my_bool and SD_ForceCheck then
                 SD_LoadAndFlashAllBinCores(true, false);
                 if ConfErr then
                   Incl(ErrFlags, c_err_flash);
                 endif;
                 FI_FPGAconfig(true);
                 if FPGA_OK then
                   START_InitAll;
                 else
                   serprompt(c_err_conf, my_param, -1);
                   return;
                 endif;
               endif;
               |

    8203:      // UPD 3, Scan Driver only
               if my_bool and SD_ForceCheck then
                 if SD_FlashBinFile(c_scan_base_DF, 'scan.dat') > df_noErr then
                   serprompt(c_err_conf, my_param, -1);      // ScanCore immer benötigt!
                   return;
                 endif;
                 START_InitAll;
               endif;
               |

    8204:      // UPD 4, nur EEPROM von SD-Karte updaten,
               // immer, auch wenn Overwrite Flag nicht gesetzt
               if my_bool and SD_ForceCheck then
                 if SD_FlashBinFile(c_defaults_base_DF, 'eeprom.bin') = df_noErr then   // optional
                   // EEPROM updaten, wenn Flag gesetzt und Version ungleich
{$IFNDEF MODULE}

                   if EE_EEPROMStructureVersion >= c_MinimalPresetStructureVersion then    // min.  c_FirmwareStructureVersion
                     DFtoEEPROM(9,1024); // neuer EEPROM-Inhalt ohne User-Info und DBs
                   else
                     DFtoEEPROM(9, 80); // neuer EEPROM-Inhalt ohne User-Info
                   endif;
{$ELSE}
                   DFtoEEPROM(9, 80); // neuer EEPROM-Inhalt ohne User-Info
{$ENDIF} // ALLINONE
                   EE_EEPROMStructureVersion:= c_FirmwareStructureVersion; // erledigt
                   System_Reset;
                 else
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |

{$IFNDEF MODULE}
    8205:      // UPD 5, Preset-Blocks von SD-Karte updaten
              if my_bool and SD_ForceCheck then
                SD_FlashBinFile(c_defaults_base_DF, 'defaults.dat'); // noch Dummy
                SD_FlashBinFile(c_organModel_base_DF, 'organs.dat');
                SD_FlashBinFile(c_leslieModel_base_DF, 'speakers.dat');
                SD_FlashBinFile(c_preset_base_DF, 'presets.dat');
              endif;
              |
{$ENDIF}
    8206:      // UPD 6, Standard- und Touchpad-CC-Block von SD-Karte updaten
               if my_bool and SD_ForceCheck then
                 if SD_LoadAndFlashStandardCCsets > df_noErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |
    8207:      // UPD 7, nur Custom- und Touchpad-CC-Block von SD-Karte updaten
               if my_bool and SD_ForceCheck then
                 if SD_LoadAndFlashCustomCCsets > df_noErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |

{$IFNDEF MODULE}
    8208:      // UPD 8, Reset Menu Enables
               if my_bool then
                 DT_ResetMenuEnables;
               endif;
               |

    8209:      // UPD 9, request DFU update for DSP
               if my_bool then
                 SendByteToFPGA(1, 246); // Set DSP ROW bits = 1
                 mdelay(100);
                 SendByteToFPGA(0, 246); // Set DSP ROW bits = 0
                 writeln(serout, '/ Start DFU Update on host!');
               else  // DFU Mode (Bootloader) abbrechen
                 SendByteToFPGA(2, 246); // Set DSP ROW bits = 2
                 mdelay(100);
                 SendByteToFPGA(0, 246); // Set DSP ROW bits = 0
                 writeln(serout, '/ DFU Update cancelled');
               endif;
               |
{$ENDIF}
    8210:      // UPD 10, Taperings
               if my_bool and SD_ForceCheck then
                 if SD_LoadAndFlashTaperings > df_noErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |
    8211:      // UPD 11, Wavesets
               if my_bool and SD_ForceCheck then
                 if SD_LoadAndFlashWavesets > df_noErr then
                   serprompt(c_err_upd, my_param, -1);
                   return;
                 endif;
               endif;
               |
    8299:      // UPD 99, DF Erase, Chip ganz löschen
               if my_bool then
                 DF_unprotect;
                 if not DF_erase then
                   DF_protect;
                   ConfErr:= true;
                   incl(ErrFlags, c_err_flash);
                   serprompt(c_err_flash, my_param, -1);
                   return;
                 endif;
                 DF_protect;
               endif;
               |
    8300:      // INI=, Load from SD
               if ParamAlpha then
                 if SD_ForceCheck then
                   PA_RunSDscript(ParamStr + '.ini');
                 else
                   return;
                 endif;
               else
                 serprompt(c_err_cmd, my_param, -1);
                 return;
               endif;
               |

    8500:      // Firmware Update from DF auf Controller, falls über SysEx oder seriell geladen
               // c_firmware_base: Word  = $3E0;       // 992 (944 + 48)
               my_word:= DF_getChecksum(c_firmware_base35_DF, c_firmware_base35_DF + $1F);
               if word(ValueLong) = my_word then
                 writeln(serout, '/ FW Checksum OK');
{$IFNDEF MODULE}
                 DT_ResetMenuEnables;
{$ENDIF}
                 DF_FWupdateFromFlashAndReboot;
               else
                 WriteSerError;
                 writeln(serout, 'Checksum failed, DF:' + IntToStr(my_word));
                 serprompt(c_err_conf, my_param, -1);
                 return;
               endif;
               |
    8501:      // EEPROM Update von DF auf Controller
               my_word:= DF_getChecksum(c_eeprom_base35_DF, c_eeprom_base35_DF);
               if word(ValueLong) = my_word then
                 writeln(serout, '/ EEPROM Checksum OK');
                 DFtoEEPROM(c_eeprom_base35_DF, 1024);
{$IFNDEF MODULE}
                 DT_ResetMenuEnables;
{$ENDIF}
               else
                 WriteSerError;
                 writeln(serout, 'Checksum failed, EEPROM:' + IntToStr(my_word));
                 serprompt(c_err_conf, my_param, -1);
                 return;
               endif;
               |

    8510:      // Firmware Update von DF auf Controller, falls über SysEx oder seriell geladen
               // Wie 8500, aber OHNE Überprüfung der Checksumme!
{$IFNDEF MODULE}
               DT_ResetMenuEnables;
{$ENDIF}
               DF_FWupdateFromFlashAndReboot;
               |
    8511:      // EEPROM Update von DF auf Controller
               // Wie 8501, aber OHNE Überprüfung der Checksumme!
               EE_ForceUpdateEEPROM:= true;
{$IFNDEF MODULE}
               DT_ResetMenuEnables;
{$ENDIF}
               |

    8600:      // Empfange 4KByte-Block
               if ValueInt < 32 then
                 ValueInt:= 4096;     // Kompatibilität mit alten HX3.5-Editor
               endif;
               serOut(#6); // ACK
               if not DF_SerReceive4kBlock(ValueInt) then  // in BlockBuffer8 zwischenspeichern
                 serprompt(c_err_conf, my_param, -1);
                 return;
               endif;
               // Liefert OK wenn Transfer erfolgreich
               |

    8601:      // Soeben empfangenen 4KByte-Block in DF speichern, absolute Blocknummer
               // Liefert OK wenn Löschen/Speichern erfolgreich
{$IFNDEF MODULE}
               NB_BlockRcvMsg(ValueInt);
{$ENDIF}
               if not DF_Store4kBlock(word(ValueInt), 4096) then
                 serprompt(c_err_conf, my_param, -1);
                 return;
               endif;
               |
{$IFNDEF MODULE}
    8605:      // 4KByte-Block als temporäres Preset laden
               if my_bool then
                 LoadPresetFromBlockBuffer; // geladene Werte nehmen
                 NB_VibknobToVCbits;
                 MenuRefresh:= true;  // ggf. angezeigten Wert aktualisieren
                 PresetPreview:= true;
                 MenuIndex:= 0;
                 MenuIndex_Splash:= 0;
               endif;
               |
    8606:      // Soeben empfangenen 512-Byte-Block in DF speichern, Preset-Nummer
               // Liefert OK wenn Löschen/Speichern erfolgreich
               if not DF_Store4kBlock(word(ValueInt) + c_preset_base_DF, 512) then
                 serprompt(c_err_conf, my_param, -1);
                 return;
               endif;
               |
{$ENDIF}

    8700:      // 4KByte-Block DF senden, ValueInt = absolute Blocknummer aus DF
               DF_readblock(word(ValueInt), 4096);
               NB_SerSendBlockArray(4096);
               |
    8701:      // 4KByte-Block EEPROM senden, ValueInt ignoriert
               for my_word:= 0 to 4095 do
                 BlockBuffer8[my_word]:= EE_dumpArr[my_word];
               endfor;
               NB_SerSendBlockArray(4096);
               |
    8702:      // 512-Byte-Block senden, ValueInt = absolute Blocknummer aus DF
               // für Presets
               DF_readblock(word(ValueInt), 512);
               NB_SerSendBlockArray(512);
               |
    8703:      // 512-Byte-EditPages 0 und 1 senden, ValueInt ignoriert
               // z.B. für Preset-Speicherauszug
               edit_TempStr:= CurrentPresetName;
               CopyBlock(@edit_array, @BlockBuffer8, 512);
               NB_SerSendBlockArray(512);
               |
    8704:      // 3200-Byte-Block CC-Sets senden, ValueInt ignoriert
               CopyBlock(@MIDIset_Array, @BlockBuffer8, c_midiarr_len);
               NB_SerSendBlockArray(c_midiarr_len);
               |

    8800:      // DFI=1, Init Preset Memory to EEPROM defaults
{$IFNDEF MODULE}
               if my_bool then
                 InitCommonPresets;
               endif;
{$ELSE}
               WriteSerWarning;
               writeln(Serout, 'Preset DF not used, ignored');
{$ENDIF}
               |

    8900..8915:
               case my_index_100 of // Binary Core Stream, LongWords, Scan Core und FIR
               0, 2: // Scan Core und FIR, LongWords
                 FI_AutoIncSetup(my_index_100); // for Write
                 for my_word:= 0 to word(ValueInt) - 1 do // Länge in LongWords!
                   FPGAsendLong0:= serInp;
                   FPGAsendLong1:= serInp;
                   FPGAsendLong2:= serInp;
                   FPGAsendLong3:= serInp;
                   SendFPGA32;
                 endfor;
                 FI_AutoIncReset(my_index_100);
                 FI_GetScanCoreInfo;
                 |
               1, 3: // Tapering und Keymap, Bytes
                 FI_AutoIncSetup(my_index_100); // for Write
                 for my_word:= 0 to word(ValueInt) - 1 do // Länge in Bytes!
                   FPGAsendByte:= serInp;
                   SendFPGA8;
                 endfor;
                 FI_AutoIncReset(my_index_100);
                 |
               else // WaveSet, TuningSet und FilterFacs, Words
                 FI_AutoIncSetup(my_index_100); // for Write
                 for my_word:= 0 to word(ValueInt) - 1 do // Länge in Words!
                   FPGAsendWord0:= serInp;
                   FPGAsendWord1:= serInp;
                   SendFPGA16;
                 endfor;
                 FI_AutoIncReset(my_index_100);
               endcase;
               |
{$IFNDEF MODULE}
    9100, 9101:// Display Message Line n
               if ParamAlpha then
                 LCDxy_M(LCD_m1, 0, my_index_100);
                 write(LCDOut_M, ParamStr);
                 LCDclreol_M(LCD_m1);
                 setSysTimer(ActivityTimer, 1000); // zurück nach 2 Sekunden
                 MenuIndex_Requested:= MenuIndex;
               endif;
               |
    9800..9899:// Set Preset Names
               if ParamAlpha then
                 CurrentPresetName:= ParamStr;
                 if my_index_100 > 0 then
                   DF_readblock(c_preset_base_DF + Word(my_index_100), 512);
                   block_PresetNameStr:= ParamStr;
                   DF_EraseWriteblock(c_preset_base_DF + Word(my_index_100), 512);
                 endif;
                 MenuRefresh:= true;
               else
                 serprompt(c_err_cmd, my_param, -1);
                 return;
               endif;
               |
{$ENDIF}
    9900, 9901: // ConnectMode nach benutzter Schnittstelle einstellen:
               if CmdSentBySerial then  // HX3 sendet Parameter-Änderungen, binär
                 ConnectMode:= t_connect_editor_serial;
               endif;
               if CmdSentByMIDI then // HX3 sendet Parameter-Änderungen, Sysex
                 ConnectMode:= t_connect_editor_midi;
               endif;
               |
    9902:
               ConnectMode:= t_connect(ValueByte);
               |
    9940:      // Finalize
               if my_bool then
                 ErrFlags:= 0;
                 FH_TestExtLicence;
{$IFNDEF MODULE}
                 MIDI_SendNRPN($357E, 127); // Request DSP Version Info, get ID $0F SysExResponse
{$ENDIF}
               endif;
{$IFNDEF MODULE}
               NB_ValidateExtendedParams;
{$ENDIF}
               |
    9950, 9951:
               if my_param = 9950 then
                 EE_DNA_0:= ValueLong;
                 EE_DNA_0_bak:= ValueLong;
                 FH_LicenceToFPGA;
               else
                 EE_DNA_1:= ValueLong;
                 EE_DNA_1_bak:= ValueLong;
                 FH_LicenceToFPGA;
               endif;
               mdelay(500);
               FH_TestExtLicence;
               |
    9980, 9981:// Restore EEPROM from DF # (9) content
             if my_Index_100 = 80 then
{$IFNDEF MODULE}
               if EE_EEPROMStructureVersion >= c_MinimalPresetStructureVersion then
                 DFtoEEPROM(9,1024); // neuer EEPROM-Inhalt ohne User-Info und DBs
               else
                 DFtoEEPROM(9, 80); // neuer EEPROM-Inhalt ohne User-Info
               endif;
{$ELSE}
               DFtoEEPROM(9, 80); // neuer EEPROM-Inhalt ohne User-Info
{$ENDIF} // ALLINONE
             else
               DFtoEEPROM(9, 0);
             endif;
             START_InitAll;
             |

{$IFDEF DEBUG_SYSEX}
    9989:      // Dump Flash Block for Test of DF
               Write(Serout, ByteToStr(ValueByte) + ' [HEXDUMP OF DF BLOCK $');
               Write(Serout, LongToHex(longword(ValueLong) * 4096));
               Writeln(Serout, ' - FIRST 1024 BYTES]');
               DF_readblock(word(ValueInt), 1024);// 1024 Bytes aus DF lesen
               for my_word:= 0 to 1023 do
                 ValueByte:= BlockBuffer8[my_word];
                 Write(Serout, ByteToHex(ValueByte));
                 Serout(#32);
                 if (my_word and 7) = 7 then
                   Serout(#32);
                 endif;
                 if (my_word and 15) = 15 then
                   writeln(serout);
                 endif;
                 if (my_word and 255) = 255 then
                   writeln(serout);
                 endif;
               endfor;
               |
{$ENDIF}

    9990:      // Owner info
               if ParamAlpha then
                 EE_owner:= ParamStr;
               else
                 serprompt(c_err_cmd, my_param, -1);
                 return;
               endif;
               |
    9994:      // ADC Test Mode
               ADCtestMode:= my_bool;
               |
    9995:
               ESP_RST:= not my_bool;  // ESP8266 Reset Pin
               if not my_bool then
                 mdelay(250);
               endif;
               |

    9997:      // Set/Reset Defaults.ini  Flag
               // Drawbars to 0, all Buttons OFF, Init ADC & Button Remap
               if my_bool then
                 FillBlock(@edit_array, 48, 0);
                 FPGA_PROG:= high;// force FPGA release when programmed by IMPACT
                 FPGA_OK:= true;
                 START_InitAll;
                 SD_present:= false;
                 SD_ForceCheck;
                 FH_TestExtLicence;
{$IFNDEF MODULE}
                 MIDI_SendNRPN($357E, 127); // Request DSP Version Info, get ID $0F SysExResponse
{$ENDIF}
               endif;
               |
    9998:      // Generator-Keymap/Waves neu an FPGA senden
               if my_bool then
                 SD_present:= false;
                 FI_FPGAconfig(true);
                 SD_SilentInit;
                 START_InitAll;
{$IFNDEF MODULE}
                 MIDI_SendNRPN($357E, 127); // Request DSP Version Info, get ID $0F SysExResponse
{$ENDIF}
               endif;
               |
    9999      :// SysReset
               if my_bool then
                 System_Reset;
               endif;
               |
  else
    serprompt(c_err_cmd, my_param, ValueInt);
  endcase;
end;


// #############################################################################
// Neuer Alpha-Parser, nimmt in ParamStr auch Strings nach "=" entgegen
// #############################################################################

// allgemeiner Parser-Teil

function Cmd2Index : byte;
// Umsetzen eines Text-Befehls in Index-Eintrag der Befehlstabelle
var
  myCmdIndex  : byte;
begin
  ParamStr:= uppercase(ParamStr);
  for myCmdIndex:= 0 to cmdAnzahl do
    if ParamStr = CmdStrArr[Ord(myCmdIndex)] then
      return(myCmdIndex);
    endif;
  endfor;
  return(cmdErr);
end;

function ParseExtract(nachGleich : boolean) : boolean;
//extrahiert ParamStr oder CmdStr aus SerInpStr,
//liefert true, wenn Parameter, sonst false, wenn Command
//akzeptiert auch alphanumerische Parameter als String nach "="
var
  my_char  : char;
  myBool  : boolean;
begin
  ParamStr:= '';
  ParamAlpha:= false;
  myBool:= false;
  while SerInpStr[ParsePtr] = ' ' do // Leerzeichen überspringen
    Inc(ParsePtr);
  endwhile;
  if SerInpStr[ParsePtr] in ['*'..'9'] then // Zahlen oder Wildcard, es wird ein Parameter
    myBool:= true;
    for i:= ParsePtr to length(SerInpStr) do
      my_char:= SerInpStr[i];
      if my_char in ['*'..'9'] then
        append(my_char, ParamStr);
      else // Buchstabe oder sonstirgendwas, abbrechen
        ParsePtr:= i;
        return(myBool);
      endif;
    endfor;
  else
    for i:= ParsePtr to length(SerInpStr) do
      my_char:= SerInpStr[i];
      if my_char = '"' then
        ParamAlpha:= true;
      else
        if (my_char >= 'A') or ParamAlpha then
          if (my_char in ['!', '?', '$']) then
            ParsePtr:= i;
            return(myBool);
          else
            append(my_char, ParamStr);
          endif;
          if nachGleich then
            ParamAlpha:= true;
          endif;
        else // Ziffer oder sonstirgendwas, abbrechen
          ParsePtr:= i;
          return(myBool);
        endif;
      endif;
    endfor;
  endif;
  return(myBool);
end;

// #############################################################################

procedure PA_HandleCmdString;
// SerInpStr parsen
var
  GleichPos : byte;
  my_param, my_SubChOffset : integer;
  isRequest, verbose : boolean;

begin
  if SerInpStr = '' then
    return;
  endif;
  verbose:= (pos('!', SerInpStr) > 0);// OK erwünscht?
  GleichPos:= pos('=', SerInpStr);// Set-'='
  isRequest:= (GleichPos = 0);// Abfrage
  ParsePtr:= 1;

//Parse einzelnen Befehl
  if ParseExtract(false) then
    my_SubChOffset:= 0; // direkter SubCh-Aufruf
  else
    CmdWhich:= Cmd2Index;// Klartext übersetzen
    if CmdWhich = cmdErr then
      serprompt(c_err_cmd, my_param, -1);
      return;
    endif;
    my_SubChOffset:= Cmd2SubChArr[Ord(CmdWhich)];
    ParseExtract(false); // SubCh-Parameter holen
  endif;
  my_param:= StrToInt(ParamStr) + my_SubChOffset; //auf neuen SubCh umrechnen

  if isRequest then
    PA_GetParamString(my_param);
  else
    ParsePtr:= GleichPos + 1;// Set-'='
    if ParseExtract(true) then
      ValueStrToValues;
    else
      ValueLong:= 0;
      ValueInt:= 0;
      ValueByte:= 0;
    endif;
    PA_SetParam(my_param, verbose);
  endif;
end;

// #############################################################################
// ###                         BINARY MODE PARSER                            ###
// #############################################################################

// BinaryMode-Funktionen, Protokoll:
// CMD=1: SetParam
// Parameter setzen:
// ESC CMD ADRL ADRH LEN DATA0...DATAn CRC then wait for <--ACK
// mit
// LEN = Anzahl der folgenden Datenbytes, 0 => 256
// CRC = einfache Modulo-Prüfsumme über alle Bytes von ESC bis DATAn
// als Antwort wird gesendet:
// ACK oder NAK wenn CRC falsch oder TimeOut

// CMD=2: GetParam
// Parameter holen:
// ESC CMD ADRL ADRH LEN CRC then wait for <--ACK
// mit
// LEN = Anzahl der gewünschten Datenbytes, 0 => 256
// CRC = einfache Modulo-Prüfsumme über alle empfangenen Bytes von ESC bis LEN

// CMD=3: SetParam mit Response (setzt kein parsed_table!)
// Parameter setzen:
// ESC CMD ADRL ADRH LEN DATA0...DATAn CRC then wait for <--ACK
// mit
// LEN = Anzahl der folgenden Datenbytes, 0 => 256
// CRC = einfache Modulo-Prüfsumme über alle Bytes von ESC bis DATAn
// als Antwort wird gesendet:
// ACK oder NAK wenn CRC falsch oder TimeOut

// Antwort sofort ACK, oder NAK wenn CRC falsch oder TimeOut, bei NAK Abbruch
// als Ergebnis wird gesendet:
// ACK ESC CMD ADRL ADRH LEN DATA0...DATAn CRC
// CMD=1: SetParam, CMD=2: GetParam
// mit
// LEN = Anzahl der folgenden oder gewünschten Datenbytes, 0 => 256
// CRC = einfache Modulo-Prüfsumme über alle Bytes von ESC bis DATAn

procedure PA_HandleBinary;
var
  my_count, my_temp_crc, my_val : byte;
  my_param, my_idx: Integer;
  sender: t_connect;
begin
  BinaryStart:= 27;   // ESC bereits empfangen
  serInp_to(BinaryCmd, 10);   // CMD
  if BinaryCmd = 4 then
    serOut(#6); // ACK
    SerInpStr:= '';
    return;
  endif;
  serInp_to(BinaryAdrL, 10);  // ADRL, ADRH
  serInp_to(BinaryAdrH, 10);
  BinaryValid:= serInp_to(BinaryLen, 10);

  my_temp_crc:= BinaryStart + BinaryCmd + BinaryAdrL + BinaryAdrH + BinaryLen;

  if BinaryValid then
    if (BinaryCmd = 1) then //    or (BinaryCmd = 3)
      // Command: fortlaufende Parameter setzen
      // auf Datensatz warten, Länge steht fest. Buffer füllen
      // Mit Cmd=1 Änderungen nicht erneut senden
      // Mit Cmd=3 wird der geänderte Parameter später als
      // geändert erkannt und zurückgesendet
      for i:= 0 to BinaryLen-1 do
        if not serinp_to(n, 10) then
          BinaryValid:= false;
          break;
        else
          BlockArrayBinaryBuf[i]:= n;
          my_temp_crc:= my_temp_crc + n;
        endif;
      endfor;
      serInp_to(BinaryCRC, 10);
      BinaryValid:= BinaryValid and (BinaryCRC = my_temp_crc);
      if BinaryValid then
        // Datensatz vollständig, CRC stimmt. Befehl bestätigen.
        // Nur an FPGA, nicht zurücksenden, kommt von Editor oder OSC Wifi
        for i:= 0 to BinaryLen-1 do
          my_param:= BinaryAdr + Integer(i);
          my_val:= BlockArrayBinaryBuf[i];
          PA_NewParamEvent(my_param, my_val, EEunlocked, c_editor_event_source);
        endfor;
        serOut(#6); // ACK
      else
        serOut(#21); // NAK
      endif;

    elsif (BinaryCmd = 2) then
      // Command: fortlaufende Parameter holen
      serInp_to(BinaryCRC, 10);
      BinaryValid:= BinaryValid and (BinaryCRC = my_temp_crc);
      if BinaryValid then
        serOut(#6); // ACK
        // Datensatz vollständig, CRC stimmt. Befehl bestätigen
        my_temp_crc:= NB_SendBinaryHeader(2, BinaryAdr);
        serout(BinaryLen);     // LEN
        my_temp_crc:= my_temp_crc + BinaryLen;
        my_param:= BinaryAdr;
        for i:= 0 to BinaryLen-1 do  // DATA0..DATAn
          PA_GetParamByte(my_param, my_val, false);
          serout(my_val);
          my_temp_crc:= my_temp_crc + my_val;
          inc(my_param);
        endfor;
        serout(my_temp_crc);   // CRC
      else
        serOut(#21); // NAK
      endif;
    endif;
  endif;

  if not BinaryValid then
    while serStat do // ungültigen Rest lesen
      serInp;
    endwhile;
  endif;
  SerInpStr:= '';
end;

// #############################################################################
// ###                     PA_CheckSer: Befehlszeile parsen                  ###
// #############################################################################

procedure PA_CheckSer;
var
  my_char : char;
begin
  if serStat then //
    my_char:= serInp;
    case my_char of
      #8:   // BS
        if (length(SerInpStr) > 0) then
          setlength(SerInpStr, length(SerInpStr) - 1);
        endif;
        |
      #13:  // CR
        if (length(SerInpStr) > 0) and SerInpStr[1] <> '/' then
          LED_timer50;
          CmdSentByMidi:= false;
          CmdSentBySerial:= true;
          PA_HandleCmdString;  // Befehl vollständig, also interpretieren
          while serstat do // evt. noch ein LF
            serInp;
          endwhile;
          CmdSentBySerial:= false;
        endif;
        serout('>');  // NEU: Prompt nach jedem Befehl
        SerInpStr:= '';
        |
      #27:  // ESC --> Binärmodus starten, niemals auf EEPROM loslassen!
        EEunlocked:= false;
        CmdSentByMidi:= false;
        CmdSentBySerial:= true;
        PA_HandleBinary;
        CmdSentBySerial:= false;
        |
    else
      if my_char in [#32..#122] then // nur 7-Bit-ASCII ohne Controls
        append(my_char, SerInpStr);
      endif;
    endcase;

  else
    udelay(10);
  endif;
  if issystimerzero(ActivityTimer) then
    LEDactivity:= high;
  endif;
end;

// #############################################################################

function PA_RunSDscript(my_ini_filename: string[12]): Boolean;
// liefert TRUE wenn Script gefunden wurde
var script_found: Boolean; my_byte: Byte;
  bytes_read: word;
begin
  MenuIndex_Requested:= MenuIndex; // Anzeige zurücksetzen wenn beendet
  if not SD_ForceCheck then
    return(false);
  endif;
  script_found:= false;
  ConfErr:= false;
  SD_TextFile_open:= false;
  if F16_FileExist('\', my_ini_filename, faFilesOnly) then
    Writeln(Serout, '/ (PA) Executing "' + my_ini_filename + '"');
{$IFNDEF MODULE}
    if LCDpresent then
      LCDclr_M(LCD_m1);
      Write(LCDOut_M, 'Run INI file');
      LCDxy_M(LCD_m1, 0, 1);
      Write(LCDOut_M, my_ini_filename);
      mdelay(500);
    endif;
{$ENDIF} // ALLINONE

    if F16_FileAssign(SD_TextFile, '', my_ini_filename) then
      if F16_FileReset(SD_TextFile) then  // Datei zum Lesen öffnen
        SD_TextFile_open:= true;
        script_found:= true;
        while not F16_EndOfFile(SD_TextFile) do  // read the entire file
          SerInpStr:= '';
          while not F16_EndOfFile(SD_TextFile) do
            // Read(Ln) hat Fehler im Optimizer- deshalb hier über F16_BlockRead
            // Read(SD_TextFile, my_byte);
            F16_BlockRead(SD_TextFile, @my_byte, 1, bytes_read);
            // write(serout, BytetoHex(my_byte) + '-');
            if  my_byte >= 32 then
              SerInpStr:= SerInpStr + char(my_byte);
            endif;
            if (my_byte = 10) or (my_byte = 13) then
              break;
            endif;
          endwhile;
          writeln(serout, SerInpStr);
          if Length(SerInpStr) > 0 then
            if SerInpStr[1] <> '/' then
{$IFNDEF MODULE}
              if LCDpresent then
                LCDxy_M(LCD_m1, 0, 1);
                Write(LCDOut_M, SerInpStr);
                LCDclreol_M(LCD_m1);
                mdelay(25);
              endif;
{$ENDIF} // ALLINONE
              PA_HandleCmdString;               // Befehlszeile interpretieren
            endif;
          endif;
        endwhile;
      endif;
      mdelay(25);
    endif;

    // Falls Firmware-Update erwünscht, wird nach Flashen des AVR jetzt
    // ein Reset ausgeführt.
    // Die Datei wird also noch nicht wie folgt umbenannt
    // und EE_skip_flashload nicht auf FALSE gesetzt.
    SerInpStr:= '';
    F16_FileClose(SD_TextFile);
    SD_TextFile_open:= false;
  else
    edit_CardSetup:= 0;
    WriteSerError;
    Writeln(Serout, '(PA) File "' + my_ini_filename + '" not found');
  endif;
  return(script_found);
end;

end parser.


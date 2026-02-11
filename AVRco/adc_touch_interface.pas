// #############################################################################
// ADC and TOUCH button functions
// #############################################################################

unit adc_touch_interface;

interface

uses var_def, eeprom_def, MIDI_com, edit_changes;

{$IDATA}
{
  procedure ADC_Read_Upper_DBX9;
  procedure ADC_Read_Lower_DBX9;
}
  procedure ADC_ReadAll_24;    // 24 interne Inputs holen und auf edit-Tabelle verteilen
  procedure ADC_ReadAll_64;    // 64 externe Inputs holen und auf edit-Tabelle verteilen
  procedure ADC_ChangesToEdit;

  procedure ADC_ChangeStateAll(const my_state: Boolean); // ADCs freigeben, erzwingt spätere Aktualisierung
  procedure ADC_ResetTimersAll;
  procedure ADC_ResetTimersUpper;
  procedure ADC_SetChangedUpper;
  procedure ADC_ResetTimersLower;
  procedure ADC_SetChangedLower;
  procedure ADC_ResetTimersPedal;
  procedure ADC_SetChangedPedal;
  procedure ADC_SetRemapTable(const my_idx, my_val: Byte);
  procedure ADC_Init;       // Remap-Table anlegen, ADC-Werte annulieren
  procedure ADC_ReadSwell;  // Nur Schweller lesen, getrennter AVR-Eingang

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ADC-Remap über Tabelle: Index ist ADC-Kanal, Eintrag ist edit_LogicalTabsTable-Index
// Werte aus Index-Tabelle:
// 0..79 in edit_table_0
// 80..239 in edit_table_1
// 240..254 Sonderbehandlung
// 255 nicht belegt
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

{$IDATA}
const
  c_coarse_ADChyst:   Integer = 8;
  c_fine_ADChyst:     Integer = 3;

var
  ADC_changed : Array[0..127] of boolean; // Flags: Analog-Wert hat sich geändert
  // 100..108: Secondary DB Set 1
  // 112..120: Secondary DB Set 2

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ADC-Remap über Tabelle: Index ADC-Kanal, Ausgang edit_Table-Index
// Werte aus Index-Tabelle:
// 0..79 in edit_table_0
// 80..239 in edit_table_1
// 240..254 Sonderbehandlung
// 255 nicht belegt
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ADC_remaps: Array[0..127] of byte;
  // 100..108: Secondary DB Set 1, gleiche Werte wie 0..9    (für DBX9)
  // 112..120: Secondary DB Set 2, gleiche Werte wie 12..21  (für DBX9)

implementation


{$IDATA}
var
  adc_changetimers : Array[0..127] of byte;  // Hysterese-Timer
  // 100..108: Secondary DB Set 1
  // 112..120: Secondary DB Set 2
  swell_adc_old : integer;

// #############################################################################
// ###                         ADC MPX Routinen                              ###
// #############################################################################

procedure adc_to_table(adc_chan, adc_remap: byte; sr_pulse: Boolean);
// Schreibt in Tabelle ADC_Values, wenn Eingang sich stärker als
// Hysterese ändert. Dieser Eingang wird dann über Timer auf "aktiv" gesetzt
// und laufend in ADC_Values aktualisiert.
// Wert in ADC_Values speichern und ADC_changed-Flag setzen, sofern geändert
// liefert Remap-Wert zurück, der ohnehin gebraucht wird
// 18 µs für je jeden freigeschalteten Eingang im Leerlauf (nicht bedient)
// 20 µs, wenn Wert sich gerade ändert
// benutzt n
var
  my_ADChyst, adc_val_b : byte;
  adc_val_old_i, adc_raw_i: Integer;
  my_active : boolean;
begin
  // Einschwingzeit nutzen, Zeit bis zur Wandlung liegt insgesamt bei ca. 8 µs
  if (not ADCtestMode) and (adc_remap >= 254) then
    if sr_pulse then
      incl(PortD, 5); // HC164 CLK
      nop; nop;
      excl(PortD, 5); // HC164 CLK
    endif;
    return;  // wenn Kanal nicht zugewiesen ist, nichts machen
  endif;
  n:= adc_changetimers[adc_chan];      // aktueller Aktiv-Timerwert in n
  if dectolim(n, 0) then
    my_active:= true;                  // nicht abgelaufen, also aktiv
    adc_changetimers[adc_chan]:= n;    // Decrement speichern
  else
    my_active:= false;                 // abgelaufen, also nicht aktiv
    nop; nop; nop; nop;
  endif;

  if sr_pulse then
    ADCSR:= $93;  // Clear ADIF
    ADCSR:= $C3;  // Start, ca. 8 µs nach SR-Takt bzw. MPX-Umschaltung
    // Konvertierzeit nutzen
    adc_val_old_i:= ADC_Values[adc_chan]; // vorheriger ADC-Wert
    repeat
    until Bit(ADCSR, 4);         // bis ADIF-Bit gesetzt
    ADCSR:= $83;  // Stopp
    // nächster HC164-Ausgang, Einschwingzeit nutzen
    incl(PortD, 5); // HC164 CLK
    nop; nop;
    excl(PortD, 5); // HC164 CLK
  else
    // Einschwingzeit verlängern für Poti in DB-Expander, evt. 50k
    if valueInRange(adc_remap, 80, 87) then
      udelay(1);
    endif;
    ADCSR:= $93;  // Clear ADIF
    ADCSR:= $C3;  // Start, ca. 8 µs nach SR-Takt bzw. MPX-Umschaltung
    // Konvertierzeit nutzen
    adc_val_old_i:= ADC_Values[adc_chan]; // vorheriger ADC-Wert
    repeat
    until Bit(ADCSR, 4);         // bis ADIF-Bit gesetzt
    ADCSR:= $83;  // Stopp
  endif;

  adc_raw_i:= integer(ADCH);

  // neuer Wert um grobe Hysterese größer oder kleiner als alter Wert?
  if not valueinTolerance(adc_raw_i, adc_val_old_i, c_coarse_ADChyst) then
    // Aktiv-Timer laden, 100=1,6 sek. bei 16ms Cycle (2ms Systick, 8 Timeslots)
    adc_changetimers[adc_chan]:= 50;
    my_active:= true;
  endif;

  // falls geändert, neuen Wert und Flag in ADC-Array setzen
  if my_active and (adc_raw_i <> adc_val_old_i) then
    ADC_Values[adc_chan]:= adc_raw_i; // letzter Wert für nächsten Vergleich
    ADC_changed[adc_chan]:= true;
  endif;
end;

procedure adc_disable;
begin
  PortA:= PortA or %01110000; // 4051 disable
  Excl(PortA, 3);             // Reset HC164
end;

// #############################################################################

procedure ADC_ReadAll_24;
// 24 ADCs, kompatibel zu HX3.4, mit 3x 74HC4051 MPX on board
// Werte in edit_table speichern und Änderungs-Flags setzen
// 740 µs mit 24 Eingängen im Leerlauf
// PA4: INHIBIT MPX 0
// PA5: INHIBIT MPX 1
// PA6: INHIBIT MPX 2
// PA7: ANALOG BUS
// PD4: SEL A MPX
// PD5: SEL B MPX
// PD6: SEL C MPX
// Je nach Einstellung verschiedene ADC-Konfigurationen lesen und verteilen
// 0: No ADC
// 1: SwellPedal only
// 2: Onboard MPX mk4, 2x 9+3 DBs (24 total)
// 3: External SR-MPX mk5 (64 total)
// NEU: Wenn UpperSecondaryActive_DB9_MPX oder LowerSecondaryActive_DB9_MPX,
// werden Werte auf +100 ff. abgelegt
var
  adc_chan, adc_remap, adc_chan_shl4, table_offset_upper, table_offset_lower: byte;
begin
{$IFNDEF MODULE}
  if ADCtestMode or (edit_ADCconfig >= 2) then

    // vor der Wandlung ggf. einmalig DB9-MPX-Satz auswählen
    // I2C-Ports sind sehr langsam!
    if UpperSecondaryActive_DB9_MPX_old <> UpperSecondaryActive_DB9_MPX then
      PREAMP_DBSELECT_UPPER:= UpperSecondaryActive_DB9_MPX;
      UpperSecondaryActive_DB9_MPX_old:= UpperSecondaryActive_DB9_MPX;
{$IFDEF DEBUG_ADC}
      Writeln(Serout, '/ ADC Upper DB9-MPX: ' + byteToStr(byte(UpperSecondaryActive_DB9_MPX)));
{$ENDIF}
    endif;
    if LowerSecondaryActive_DB9_MPX_old <> LowerSecondaryActive_DB9_MPX then
      PREAMP_DBSELECT_LOWER:= LowerSecondaryActive_DB9_MPX;
      LowerSecondaryActive_DB9_MPX_old:= LowerSecondaryActive_DB9_MPX;
{$IFDEF DEBUG_ADC}
      Writeln(Serout, '/ ADC Lower DB9-MPX: ' + byteToStr(byte(LowerSecondaryActive_DB9_MPX)));
{$ENDIF}
    endif;

    adc_disable; // Reset HC164, 4051 disable
    ADMUX:= $27;  // immer Kanal 7, ADLAR =1 (left adjusted, 8-Bit-Result on ADCH)

    if ADCtestMode then
      table_offset_upper:= 0;
      table_offset_lower:= 0;
    else
      if UpperSecondaryActive_DB9_MPX then
        table_offset_upper:= 100;
      else
        table_offset_upper:= 0;
      endif;

      if LowerSecondaryActive_DB9_MPX then
        table_offset_lower:= 100;
      else
        table_offset_lower:= 0;
      endif;
    endif;

    // INH 1 auf low = aktiviert, Kanal 0..7
    Excl(PortA, 4);
    h:= (PortD and $8F);
    adc_chan_shl4:= 0;  // 3 Bits oberes Nibble = Kanal
    adc_chan:= table_offset_upper;   // erste 8 sind alle Upper DBs
    for i:= 0 to 7 do
      PortD:= h or adc_chan_shl4;    // Kanal vorbereiten
      inc(adc_chan_shl4, 16);        // oberes Nibble inkrementieren
      adc_remap:= ADC_remaps[adc_chan];
      if (adc_remap = c_map_end) and (not ADCtestMode) then
        adc_disable; // Reset HC164, 4051 disable
        return;
      endif;
      adc_to_table(adc_chan, adc_remap, false); // erzeuge KEINEN SR-Impuls
      inc(adc_chan);
    endfor;

    // INH 2 auf low = aktiviert, Kanal 8 bis 15
    Incl(PortA, 4);
    Excl(PortA, 5);
    adc_chan_shl4:= 0;  // 3 Bits oberes Nibble = Kanal
    for i:= 8 to 15 do
      PortD:= h or adc_chan_shl4; // Kanal vorbereiten
      inc(adc_chan_shl4, 16);     // oberes Nibble inkrementieren
      if i = 8 then                         // DB-MPX 1' Upper?
        adc_chan:= table_offset_upper + i;  // mit DBX9-Offset
      elsif i >= 12 then                    // Erste 4 Lower DBs
        adc_chan:= table_offset_lower + i;  // mit DBX9-Offset
      else
        adc_chan:= i;                       // keine Umleitung
      endif;
      adc_remap:= ADC_remaps[adc_chan];
      if (adc_remap = c_map_end) and (not ADCtestMode) then
        adc_disable; // Reset HC164, 4051 disable
        return;
      endif;
      adc_to_table(adc_chan, adc_remap, false);        // erzeuge KEINEN SR-Impuls
      inc(adc_chan);
    endfor;

    // INH 3 auf low = aktiviert, Kanal 16 bis 23
    Incl(PortA, 5);
    Excl(PortA, 6);
    adc_chan_shl4:= 0;  // 3 Bits oberes Nibble = Kanal
    for i:= 16 to 23 do
      PortD:= h or adc_chan_shl4; // Kanal vorbereiten
      inc(adc_chan_shl4, 16);     // oberes Nibble inkrementieren
      if i <= 20 then                       // innerhalb DBX9-DBs?
        adc_chan:= table_offset_lower + i;  // mit DBX9-Offset
      else
        adc_chan:= i;                       // keine Umleitung
      endif;
      adc_remap:= ADC_remaps[adc_chan];
      if (adc_remap = c_map_end) and (not ADCtestMode) then
        adc_disable; // Reset HC164, 4051 disable
        return;
      endif;
      adc_to_table(adc_chan, adc_remap, false);        // erzeuge KEINEN SR-Impuls
      inc(adc_chan);
    endfor;
  endif;
  adc_disable; // Reset HC164, 4051 disable
{$ENDIF}
end;

// -----------------------------------------------------------------------------

procedure ADC_ReadAll_64;
// 64 ADCs bei HX3.5, neue DB-Platinen mit HC164 und 4066 MPX
// Werte in edit_table speichern und Änderungs-Flags setzen
// 19 µs für je jeden freigeschalteten Eingang im Leerlauf (nicht bedient)
// PA3: Reset HC164                  (PL20 DRAWB_MPX Pin 2)
// PA7: ANALOG BUS                   (PL20 DRAWB_MPX Pin 6)
// PD4: SROUT_DATA to HC164 chain    (PL20 DRAWB_MPX Pin 7)
// PD5: SR_CLK to HC164 and 4014 chain  (PL20 DRAWB_MPX Pin 8)
// Je nach Einstellung verschiedene ADC-Konfigurationen lesen und verteilen
// 0: No ADC
// 1: SwellPedal only
// 2: Onboard MPX mk4, 2x 9+3 DBs (24 total)
// 3: External SR-MPX mk5 (64 total)
var
  adc_chan, adc_remap: Byte;
begin
{$IFNDEF MODULE}
  if ADCtestMode or (edit_ADCconfig >= 2) then
    PortA:= PortA or %01111000; // Reset HC164 aufheben, 4051 disable
    Excl(PortD, 5); // HC164 CLK
    // Startbit einschieben
    incl(PortD, 4); // HC164 SER IN
    nop;
    incl(PortD, 5); // HC164 CLK
    ADMUX := $27;   // immer Kanal 7, ADLAR =1 (left adjusted, 8-Bit-Result on ADCH
    nop;
    excl(PortD, 5); // HC164 CLK
    excl(PortD, 4); // HC164 SER IN
    // Jetzt erster HC164-Ausgang high
    udelay(1);      // erste Settle Time
    for adc_chan:= 24 to 87 do
      adc_remap:= ADC_remaps[adc_chan];
      if (adc_remap = c_map_end) and (not ADCtestMode) then
        break;
      endif;
      adc_to_table(adc_chan, adc_remap, true);  // erzeuge SR-Impuls, Verarbeitung = Settle Time
    endfor;
  endif;
  adc_disable; // Reset HC164, 4051 disable
{$ENDIF}
end;

// #############################################################################

procedure ADC_ChangeToRemap(const adc_chan, adc_remap: Byte;
          const log_pots: Boolean);
var
  adc_val, my_idx: Integer;
  my_remap: Byte;
  is_2nd_dbset_remap: Boolean;
begin
{$IFNDEF MODULE}
  adc_val:= ADC_Values[adc_chan];
  n:= lo(adc_val) shr 1; // auf 0..127 bringen
  if edit_ADCscaling <> 100 then
    n:= ValueTrimLimit(muldivByte(n, edit_ADCscaling, 100), 0, 127);
  endif;

  is_2nd_dbset_remap:= valueInRange(adc_remap, 128, 155); // Flag, >=128
  my_remap:= adc_remap;

  // Drawbars Upper, Lower
  if (is_2nd_dbset_remap or valueInRange(adc_remap, 0, 27)) then
    my_remap:= adc_remap and $7F;
    if (edit_ADCconfig = 3) then
      // Upper/Lower DBX-Drawbars mit neuer 2nd-Set-Logik behandeln
      // DB-Levels ggf. sperren, wenn inaktiver DB-Satz
      if valueInRange(my_remap, 0, 11) then          // Upper DBs?
        if is_2nd_dbset_remap <> UpperSecondaryActive then
          return;                                   // nicht aktiv, überspringen
        endif;
      elsif valueInRange(my_remap, 16, 27) then      // Lower DBs?
        if is_2nd_dbset_remap <> LowerSecondaryActive then
          return;                                   // nicht aktiv, überspringen
        endif;
      endif;
    endif;
  // Logarithmische Volume-Potentiometer?
  elsif log_pots
  and valueInRange(adc_remap, c_map_first_logpot, c_map_last_logpot) then
    n:= c_AntiLogTable[n];
    // Analogwert eintragen
    edit_table_0[my_remap]:= n;
    edit_array_flag_0[my_remap]:= c_control_event_source;
    return;
  // Rotary-DB-Remap?
  elsif valueInRange(adc_remap, c_map_midi_sendpot_0, c_map_midi_sendpot_11) then  // MIDI CC Remap?
    my_idx:= Integer(adc_remap) - c_map_midi_sendpot_0 + 520;  // + 520 -200, CCs # 1520 ff.
    MIDI_SendIndexedController(Word(my_idx), n);      // nur MIDI CC senden
    return;
  elsif valueInRange(adc_remap, 248, 250) then  // Rotary-DB-Remap?
    my_remap:= adc_remap - 248;
    edit_RotaryGroup_DB[my_remap]:= n;
    edit_RotaryGroup_DB_flag[my_remap]:= c_control_event_source;
    return;
  endif;

  // normale Zuordnung über Remap, kein Rotary-DB
  if edit_ADCconfig = 2 then       // alte DB9-MPX mit 4053-Umschaltern
    if UpperSecondaryActive_DB9_MPX and valueInRange(adc_remap, 0, 8) then
      return; // nicht eintragen, wird später erledigt
    endif;
    if LowerSecondaryActive_DB9_MPX and valueInRange(adc_remap, 16, 24) then
      return; // nicht eintragen, wird später erledigt
    endif;
  // Orgel mit nur einem DB-Satz
  elsif edit_ADCconfig >= 4 then
    if SingleDBsetSelect = 1 then
      // Single DB9 umleiten wenn edit_ADCconfig = 4 und ToLower-Tab
      if valueInRange(adc_remap, 0, 8) then   // Upper DBs?
        // Änderungen auf Lower umleiten
        my_remap:= adc_remap + 16;
      endif;
    elsif SingleDBsetSelect = 2 then
      // Single DB9 umleiten wenn edit_ADCconfig = 4 und ToPedal-Tab
      case adc_remap of
        0: my_remap:= 72;
        |
        1: my_remap:= 74;
        |
        2: my_remap:= 67;
        |
        3..8: return;
        |
      endcase;
    else
      if valueInRange(adc_remap, 16, 24) then   // Lower DBs?
        // Änderungen auf Lower-Eingängen verwerfen
        return;
      endif;
    endif;
  endif;
  // Analogwert endlich eintragen
  edit_table_0[my_remap]:= n;
  edit_array_flag_0[my_remap]:= c_control_event_source;
{$ENDIF}
end;

// -----------------------------------------------------------------------------

procedure ADC_ChangesToEdit;
// Änderungen von ADC-Werten in edit_table setzen
var
  adc_chan, adc_remap, upper_keycount, lower_keycount: byte;
  log_pots: Boolean;
  adc_val: Integer;
begin
{$IFNDEF MODULE}
  if ADCtestMode or (edit_ADCconfig < 2) then
    return;
  endif;

  log_pots:= Bit(edit_ConfBits, 5);

  if ExternalScanActive and (edit_ADCconfig = 5) then
    // Nur für Orgeln mit FatarScan76
    // Anzahl gedrückter Tasten vom Scan-Interface holen.
    // Evt. Umbau auf FPGA-Register?
    NB_GetBytefromI2Cslave($5A, 2, upper_keycount);
    NB_GetBytefromI2Cslave($5B, 2, lower_keycount);
    edit_SingleDBtoLower:= lower_keycount > upper_keycount;
  endif;

  for adc_chan:= 0 to 23 do
    adc_remap:= ADC_remaps[adc_chan];
    if adc_remap = c_map_none then
      continue;
    endif;
    if adc_remap = c_map_end then
      break;
    endif;
    if ADC_changed[adc_chan] then
      ADC_changed[adc_chan]:= false;
      ADC_ChangeToRemap(adc_chan, adc_remap, log_pots);
    endif;
  endfor;

  for adc_chan:= 24 to 87 do
    adc_remap:= ADC_remaps[adc_chan];
    if adc_remap = c_map_none then
      continue;
    endif;
    if adc_remap = c_map_end then
      break;
    endif;
    if ADC_changed[adc_chan] then
      ADC_changed[adc_chan]:= false;
      ADC_ChangeToRemap(adc_chan, adc_remap, log_pots);
    endif;
  endfor;
  if edit_ADCconfig <> 2 then
    return;
  endif;

  // Wenn bei altem DB9-MPX zweiter Drawbar-Satz gewählt ist,
  // wurden die Drawbar-ADC-Werte auf 100..108 und 112..120 abgelegt
  if UpperSecondaryActive_DB9_MPX then
    for adc_chan:= 100 to 108 do
      // Verteilt ADC-Werte von zweitem DB9-MPX, wenn geändert.
      adc_remap:= ADC_remaps[adc_chan];
      if adc_remap = c_map_none then
        continue;
      endif;
      if adc_remap = c_map_end  then
        break;
      endif;
      if ADC_changed[adc_chan] then
        ADC_changed[adc_chan]:= false;
        adc_val:= ADC_Values[adc_chan];
        n:= lo(adc_val) shr 1; // auf 0..127 bringen
        edit_table_0[adc_remap]:= n;
        // edit_UpperIndirectB_DBs[adc_chan - 100]:= n;
        edit_array_flag[adc_remap]:= c_control_event_source;
{$IFDEF DEBUG_ADC}
        Write(Serout, '/ ADC UpperSecondary: ' + byteToStr(adc_chan));
        Writeln(Serout, ', Remap to: ' + byteToStr(adc_remap));
{$ENDIF}
      endif;
    endfor;
  endif; // UpperSecondaryActive_DB9_MPX

  if LowerSecondaryActive_DB9_MPX then
    for adc_chan:= 112 to 120 do
      // Verteilt ADC-Werte von zweitem DB9-MPX, wenn geändert.
      adc_remap:= ADC_remaps[adc_chan];
      if adc_remap = c_map_none then
        continue;
      endif;
      if adc_remap = c_map_end  then
        break;
      endif;
      if ADC_changed[adc_chan] then
        ADC_changed[adc_chan]:= false;
        adc_val:= ADC_Values[adc_chan];
        n:= lo(adc_val) shr 1; // auf 0..127 bringen
        edit_table_0[adc_remap]:= n;
        // edit_LowerIndirectB_DBs[adc_chan - 100]:= n;
        edit_array_flag[adc_remap]:= c_board_event_source;
{$IFDEF DEBUG_ADC}
        Write(Serout, '/ ADC LowerSecondary: ' + byteToStr(adc_chan));
        Writeln(Serout, ', Remap to: ' + byteToStr(adc_remap));
{$ENDIF}
      endif;
    endfor;
  endif; // LowerSecondaryActive_DB9_MPX
{$ENDIF}
end;

// #############################################################################

procedure ADC_ReadSwell;
// Schweller-Eingang PA2 wird immer gewandelt und bei Änderung Change-Flag gesetzt
var
  my_adc_new : integer;
begin
  if edit_ADCconfig = 0 then
    SwellPedalControlledByMIDI:= true;
    return;
  endif;
  ADMUX:= $22;  // immer Kanal 2, ADLAR =1 (left adjusted, 8-Bit-Result on ADCH), 3,3 VRef
  udelay(1);    // 10µs Einschwingen
  ADCSR:= $93;  // clear ADIF
  ADCSR:= $C3;
  repeat
  until Bit(ADCSR, 4);         // bis ADIF-Bit gesetzt
  ADCSR:= $83;
  SwellPedalADC:= ADCH;  // ADC-Wert neu
  my_adc_new:= integer(SwellPedalADC);
  if not valueinTolerance(my_adc_new, swell_adc_old, 5) then
    SwellPedalControlledByMIDI:= false;
    swell_adc_old:= my_adc_new; // alter Wert
{$IFDEF DEBUG_AC}
    Writeln(Serout, '/ ADC SwellVal: ' + byteToStr(SwellPedalADC));
{$ENDIF}
  endif;
end;

// #############################################################################

procedure adc_set_timer_range(const remapped_start, remapped_end: Byte; const changed: Boolean);
// Analoge Eingänge und Timer auf "changed" setzen
// Wird bei Voice-Umschaltung
// von Preset auf Live aufgerufen.
// Durchsucht ADC_remaps nach Werten zwischen db_start und db_end
var my_remap: Byte;
begin
  if edit_ADCconfig >= 2 then // ADC eingeschaltet?
    for i:= 0 to 120 do
      my_remap:=  ADC_remaps[i] and $7F;
      if valueInRange(my_remap, remapped_start, remapped_end) then
        // Timer abgelaufen, grobe Hysterese
        adc_changetimers[i]:= byte(changed) and 50;
        adc_changed[i]:= changed;
      endif;
    endfor;
  endif;
end;

procedure ADC_ResetTimersAll;
begin
  for i:= 0 to 120 do
    adc_changetimers[i]:= 0; // Timer abgelaufen, grobe Hysterese
  endfor;
end;

procedure ADC_ResetTimersUpper;
begin
  adc_set_timer_range(0, 11, false);    // DBs
end;

procedure ADC_ResetTimersLower;
begin
  adc_set_timer_range(16, 27, false);   // DBs
end;

procedure ADC_ResetTimersPedal;
begin
  adc_set_timer_range(32, 43, false);  // DBs
  adc_set_timer_range(72, 75, false);  // DB4s
end;

procedure ADC_ChangeStateAll(const my_state: Boolean);
begin
  if edit_ADCconfig >= 2 then     // ADC eingeschaltet?
    for i:= 0 to 127 do
      ADC_changed[i]:= my_state;  // Force or disable ADC handling
    endfor;
  endif;
end;

procedure ADC_SetChangedUpper;
begin
  adc_set_timer_range(0, 11, true);     // DBs
end;

procedure ADC_SetChangedLower;
begin
  adc_set_timer_range(16, 27, true);   // DBs
end;

procedure ADC_SetChangedPedal;
begin
  adc_set_timer_range(32, 43, true);   // DBs
  adc_set_timer_range(72, 75, true);   // DB4s
end;

// #############################################################################

procedure ADC_SetRemapTable(my_idx, my_val: Byte);
begin
  ADC_remaps[my_idx]:= my_val;
  if (my_idx < 9) then
    ADC_remaps[my_idx + 100]:= my_val; // Upper secondary DB9-MPX
  endif;
  if valueInRange(my_idx, 12, 20) then
    ADC_remaps[my_idx + 100]:= my_val; // Upper secondary DB9-MPX
  endif;
end;

procedure ADC_Init;
// Tabellen ungültig machen
begin
  SingleDBsetSelect:= 0;
  edit_SingleDBtoUpper:= true;
  PREAMP_DBSELECT_UPPER:= false;
  PREAMP_DBSELECT_LOWER:= false;
  for i:= 0 to 87 do
    ADC_remaps[i]:= eep_ADCremaps[i];
  endfor;
  // 100..108: Secondary DB Set 1, gleiche Werte wie 0..9   (für DB9-MPX, alt)
  for i:= 0 to 8 do
    ADC_remaps[i + 100]:= ADC_remaps[i];
  endfor;
  for i:= 109 to 111 do
    ADC_remaps[i]:= c_map_none;
  endfor;
  // 112..118: Secondary DB Set 2, gleiche Werte wie 12..21 (für DB9-MPX, alt)
  for i:= 12 to 20 do
    ADC_remaps[i + 100]:= ADC_remaps[i];
  endfor;
  ADC_remaps[121]:= c_map_end;
  ADC_ChangeStateAll(true); // Force ADC handling
end;

end adc_touch_interface.



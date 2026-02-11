// #############################################################################
// ###                     F Ü R   A L L E   B O A R D S                     ###
// #############################################################################

// #############################################################################
// Hardware-Ports AVR
// #############################################################################
unit port_def;

interface
const
  PCA9532_0      : Byte      = $60; // Upper Voice
  PCA9532_1      : Byte      = $61; // Lower Voice
  PCA9532_2      : Byte      = $62; // Panel16 onboard
  PCA9532_3      : Byte      = $63; // ext. Panels
  PCA9532_4      : Byte      = $64;
  PCA9532_5      : Byte      = $65;
  PCA9532_6      : Byte      = $66;
  PCA9532_7      : Byte      = $67; // auch XB2!

  PCA9554A_0     : Byte      = $38;
  PCA9554A_1     : Byte      = $39;
  PCA9554A_2     : Byte      = $3A;
  PCA9554A_3     : Byte      = $3B;
  PCA9554A_4     : Byte      = $3C;
  PCA9554A_5     : Byte      = $3D;
  PCA9554A_6     : Byte      = $3E;
  PCA9554A_7     : Byte      = $3F;

  PCA9555_0      : Byte      = $20;
  PCA9555_1      : Byte      = $21;
  PCA9555_2      : Byte      = $22;
  PCA9555_3      : Byte      = $23;
  PCA9555_4      : Byte      = $24;
  PCA9555_5      : Byte      = $25;
  PCA9555_6      : Byte      = $26;
  PCA9555_7      : Byte      = $27; // XB2 Alternativbestückung

  PCA9555_IN0    : Byte      = 0;
  PCA9555_IN1    : Byte      = 1;
  PCA9555_OUT0   : Byte      = 2;
  PCA9555_OUT1   : Byte      = 3;
  PCA9555_INV0   : Byte      = 4;
  PCA9555_INV1   : Byte      = 5;
  PCA9555_DDR0   : Byte      = 6;
  PCA9555_DDR1   : Byte      = 7;

// A321-SEE    Analogeingang, MPX 3 bis 1, -, Swell, Encoder
  DDRAinit:    byte = %01111000;            {PortA dir }
  PortAinit:   byte = %00110011;            {PortA }

// CIOS-Q-F    Clk, MISO, MOSI, SS, -, IRQ, -,DF
  DDRBinit:          byte = %10111011;            {PortB dir }
  DDRBinit_SelfConf: byte = %00111010;            {PortB dir }
  PortBinit:         byte = %10011111;            {PortB }

  DDRCinit:          byte = %01100000;            {PortC dir}
  PortCinit:         byte = %11111111;            {PortC - PROG high}

  c_LSPEED:    byte = 2; // Input Footswitch Leslie Slow/Fast
  c_CDSW:      byte = 3; // Input SD Card Switch
  c_LRUN:      byte = 4; // Input Footswitch Leslie Run
  c_ESPRST:     byte = 5; // Output ESP8266 RST (active low)


{ Jumper und LEDs PortBits }
  DDRDinit:          byte = %11111100;            {PortD dir, 0..1=Serial }
  PortDinit:         byte = %01111100;            {PortD }


var

{$IDATA}

// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

  // Ausstattungs-Flags
  PanelsPresent: Array[0..7] of Boolean;
    Panel16_0_present[@PanelsPresent + 0]: Boolean; // Preset16_0
    Panel16_1_present[@PanelsPresent + 1]: Boolean; // Preset16_1
    Panel16_2_present[@PanelsPresent + 2]: Boolean; // PCA9532_2 onboard
    Panel16_3_present[@PanelsPresent + 3]: Boolean; // PCA9532_3 externes Panel 1
    Panel16_4_present[@PanelsPresent + 4]: Boolean; // PCA9532_4 externes Panel 2
    Panel16_5_present[@PanelsPresent + 5]: Boolean; // PCA9532_5 externes Panel 3
    XB2_present[@PanelsPresent + 7]: Boolean;       // PCA9532_7 externes Panel

// Index: Button-Nummer 0..63, übersetzt Button/LED-Nummer in Tab-Nummer
  BtnRemaps : Array[0..95] of byte;            // wie in EEPROM 5100..5195
  BtnSwitchSelects : Array[0..95] of Boolean;  // wie in EEPROM 5200..5295
  BtnRemaps_XB: Array[0..31] of byte;          // wie in EEPROM 5300..5331

  // 100..108: Secondary DB Set 1
  // 112..120: Secondary DB Set 2
  ADC_Values   : Array[0..127] of Integer;   // Werte 0..255

  FootSwFast, FootSwRun, FootSwSlow: Boolean;  // aktueller Schalter-Zustand
  footsw_lesliefast_old, footsw_leslierun_old: Boolean;
  footsw_lesliefast_debounce, footsw_leslierun_debounce: Byte;
  Switch_vibrato_old: Byte;

// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************

  LCDpresent, MenuPanelLEDsPresent,         // PM8-Panel oder 2x16 Display an XB2
  PreampPortPresent, VibKnobPortPresent: Boolean;

  // MenuPanelLEDs_temp, MenuPanelLEDs_timer, MenuPanelLEDs_pwm: byte;
  // MenuPanelLEDsCablePresent: Boolean; // MenuPanel LEDs driven by PL25 cable


{$PDATA}

  LEDactivity[@PortD, 2] : bit; // Bit 2 LED Remote-Activity, auch LED_UP
  LED_DOWN[@PortD, 3] : bit;    // Bit 3 LED Display-Panel
  PWR_GOOD[@PortD, 7] : bit;

  TEST_LA[@PortD, 6] : bit;

  SD_CDSW[@PinC, c_CDSW]: bit;      // SD Card Switch
  ESP_RST[@PortC, c_ESPRST]: bit;    // ESP8266-Adapter, Reset LOW aktiv

  // #### AVR Port D ####
  // Port D Bits 4, 5, 6 sind MPX-Adresse 0..2

  SD_SS[@PortB, 4] : bit;


// *****************************************************************************
{$IFNDEF MODULE}
// *****************************ALLINONE****************************************

  FOOTSW_LESLFAST[@PinC, c_LSPEED]: bit;  // Fußschalter Leslie
  FOOTSW_LESLRUN[@PinC, c_LRUN]: bit;     // Fußschalter Leslie

  // #### I2C-Ports PCA9554A ####
  // Vibrato-Knob
  VibKnobPortIn[@Pin0]   : TI2Cport;     // In-Port 9554A auf I/O-Platine
  VibKnobPortOut[@Port0] : TI2Cport;     // Out-Port 9554A auf I/O-Platine
  VibKnobPortDDR[@DDR0]  : TI2Cport;     // Datenrichtung 9554A auf I/O-Platine

  VKPORT_LESRUN[@Port0, 6] : bit; // Ausgang zum Extension Board CTRL_0
  VKPORT_LESFAST[@Port0, 7] : bit; // Ausgang zum Extension Board CTRL_1

  PreampPortOut[@Port1] : TI2Cport;     // Out-Port 9554A auf mk3
  PreampPortDDR[@DDR1]  : TI2Cport;  // Datenrichtung 9554A auf I/O-Platine

  PREAMP_DBSELECT_UPPER[@Port1, 0] : bit; // Ausgang!
  PREAMP_DBSELECT_LOWER[@Port1, 1] : bit; // Ausgang!
  PREAMP_LESRUN[@Port1, 2] : bit; // Ausgang!
  PREAMP_LESFAST[@Port1, 3] : bit; // Ausgang!
  PREAMP_REV1[@Port1, 4] : bit; // Ausgang!
  PREAMP_REV2[@Port1, 5] : bit; // Ausgang!
  PREAMP_AUX[@Port1, 6] : bit; // Ausgang!
  PREAMP_POWER[@Port1, 7] : bit; // Ausgang!

  MenuPanelLEDsOut[@Port2] : TI2Cport;       // Out-Port 9554A auf I/O-Platine
  MenuPanelLEDsIn[@Pin2] : TI2Cport;       // Out-Port 9554A auf I/O-Platine
  MenuPanelLEDsDDR[@DDR2]  : TI2Cport;    // Datenrichtung 9554A auf I/O-Platine

// **************************** ALLINONE****************************************
{$ENDIF}
// *****************************************************************************


// #############################################################################

implementation

end port_def.


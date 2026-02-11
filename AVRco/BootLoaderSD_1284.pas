program HX35_BL;
// Bootloader, lädt Firmware aus externem Flash-Speicher

Device = mega1284p, VCC = 5;    // mega644, ggf. mega644p !!!

{$BootApplication $0FC00}

Define_Fuses
  Override_Fuses;    // optional, always replaces fuses in ISPE
  COMport = USB;     // COM2..COM7, USB
  LockBits0 = [BOOTLOCK11];
  FuseBits0 = [CKSEL3];
  FuseBits1 = [SPIEN,EESAVE,BOOTSZ0];
  FuseBits2 = [BODLEVEL0,BODLEVEL1];
  ProgMode = SPI;    // SPI, JTAG or OWD
  ProgFuses = true;
  ProgLock = true;
  ProgFlash = true;

Import FlashWrite, SysTick;  //   ADCport,

From System Import LongWord, LongInt;

Define
  ProcClock      = 16000000;        {Hertz}
  SysTick        = 2;              //msec
  StackSize      = $0080, iData;
  FrameSize      = $0080, iData;

Implementation


const
  DDRBinit:          byte = %10111011;            {PortB dir }
  bPortBinit:         byte = %10011111;            {PortB }
  DDRCinit:          byte = %01010000;            {PortC dir, 0..1=Incr4 }
  bPortCinit:         byte = %10001111;            {PortC, hold PROG low! }
  DDRDinit:          byte = %11111100;            {PortD dir, 0..1=Serial }
  bPortDinit:         byte = %00001100;            {PortD }

  FlashSizeDiv256: Word    = $1F8;     // $01 F800 div 256
  FW_start_addr: LongInt     = 4063232;  // $3E 0000

  high:  boolean = true;
  low:   boolean = false;


var
{$PData}
  F_DFCS[@PortB, 0]: bit;    // CS für AT25DF021
  LEDactivity[@PortD, 2] : bit; {Bit 2 LED Remote-Activity}

{$IDATA}
  DF_send, DF_receive         : byte;  // externer DataFlash-Speicher
  DF_long                     : LongInt;     // DF-Registerwert Langwort
  DF_long0[@DF_long+0]        : byte;
  DF_long1[@DF_long+1]        : byte;
  DF_long2[@DF_long+2]        : byte;
  DF_long3[@DF_long+3]        : byte;
  BlockArray[$3000]           : Array[0..255] of byte;
  BlockArrayWords[@BlockArray]: Array[0..127] of word; // This is the very same buffer, just addressed as WORDs

  FlashAdr          : WORD;
  FlashPage         : BYTE;
  WordsWritten      : LONGWORD;
  F_addr: LongInt;
  Count: Word;
  Idx : byte;


procedure DF_sr;
// Sende/empfange ein Byte über SPI an DF (F_DFCS muss entspr. gesetzt sein)
begin
  asm;
    lds  _ACCA, HX35_BL.DF_send
    out SPDR, _ACCA     ; SPI von FAT16-Treiber eingeschaltet!
    
    DF_waitReg:
    in _ACCA, SPSR
    sbrs _ACCA,7 ; SPIF?
    rjmp DF_waitReg     ;  auf Ende des SPI-Transfer warten
    in _ACCA, SPDR
    sts  HX35_BL.DF_receive, _ACCA  ;Lesewert zurück ins Datenbyte
  endasm;
end;

procedure DF_busy;
// Warte, bis DF nicht mehr beschäftigt ist
begin
  F_DFCS:= low;
  DF_send:=$05; // Read Status
  DF_sr;
  repeat
    DF_sr;
  until (DF_receive AND $01) = 0;
  F_DFCS:= high;
end;

procedure DFreadblock(df_adr: LongInt; df_count: word);
var my_count, my_idx: byte;
//Lese BlockArray aus DataFlash
begin
  DF_busy;
  my_count:=byte(df_count-1);
  DF_long := df_adr;
  F_DFCS:= low;
  DF_send:=$0B; // Read Page
  DF_sr;
  DF_send:=DF_long2; // Adr Bits 23..16
  DF_sr;
  DF_send:=DF_long1; // Adr Bits 15..8
  DF_sr;
  DF_send:=DF_long0; // Adr Bits 7..0
  DF_sr;
  DF_send:=0; // dummy für $0B read mode
  DF_sr;
  for my_idx := 0 to my_count do
    DF_sr;
    BlockArray[my_idx] := DF_receive; // store Data Byte
  endfor;
  F_DFCS:= high;
end;


begin
  DDRC:=  DDRCinit;            {PortC dir}
  PortC:= bPortCinit;           {PortC, keep PROG low!}

  DDRB:=  DDRBinit;            {PortB dir}
  PortB:= bPortBinit;           {PortB}

  DDRD:=  DDRDinit;            {PortD dir}
  PortD:= bPortDinit;           {PortD}

  SPCR := %01011100;          // Enable SPI, Master, CPOL/CPHA=1,1 Mode 3
  SPSR := %00000000;          // %00000001 = Double Rate, %00000000 = Normal Rate
  
  FlashAdr:= 0;
  FlashPage:= 0;
  F_Addr:= FW_start_addr;
  FlashInitPage(nil);
  for Count:= 0 to  (FlashSizeDiv256-1) do
    DFreadblock(F_Addr, 256);
    //mdelay(25);
    
    FLASH_ADDR  := FlashAdr;
    FLASH_PAGE  := FlashPage;
    FlashErasePage;
    FLASH_ADDR  := FlashAdr;
    for Idx := 0 to 127 do
      FlashWritePage(BlockArrayWords[Idx]);
      inc(WordsWritten);
    endfor;
    FLASH_ADDR  := FlashAdr;
    FlashProgPage;

    inc(FlashAdr, 256);
    if FlashAdr = 0 then
      inc(FlashPage);
    endif;
    inc(F_Addr, 256);
    // mdelay(25);
    if (Count and 7) = 0 then
      LEDactivity:= not LEDactivity;
    endif;
  endfor;
  Application_Startup;
end.


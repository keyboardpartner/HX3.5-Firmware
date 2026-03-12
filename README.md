# HX3.5 Firmware

![HX3.7 Pic](https://github.com/keyboardpartner/HX3-Scan-Drivers/blob/main/docs/mainboard37_kl.JPG)

### Firmware for HX3.5 Mainboard with ATmega1284P MCU

**Customer info:** Do not open! No user servicable parts inside. For HX3 updates, see our **[HX3 Update page](http://updates.keyboardpartner.de/Files/index.php)**.

HX3.5 firmware was compiled with older **AVRCo** Pascal IDE from [**e-lab**](https://www.e-lab.de/) which is free of charge now. It runs on a ATmega1284P MCU (see **AVRco** directory).

In AVRco IDE project manager, import project **HX35_allinone.ppro** and compile with optimizer (brick wall icon). AVRco will create *HX35_main.hex* (flash content file) and *HX35_main.eep* (EEPROM file). To modify HX3.5 bootloader (reads firmware from SD Card) open AVRco project **HX35_bootloader.ppro**. Using the AVRco compiler, ignore the *src, lib* and *include* directory for now. 

### Version History

* Update to version 5.840 for new FPGA 12032026
* Update to version 5.836

### Future repository for HX3.5 Firmware C++ conversion

We plan to port the firmware to PlatformIO IDE with Arduino C++ framework for easier compilation and portability. The *src, lib* and *include* directories contain a PlatformIO framework (in progress) that displays some basic menus on HX3 MenuPanel, scans Panel16 tab board, inits the FPGA and loads a (present) scancore. At least it plays notes via MIDI (or Fatar Scan driver) with the current HX3.5 sound engine (FPGA). Controlling the rotary sim, vibrato or advanced features are not implemented yet. 

There is some debug output on serial COM (57600 8n1), but there is no provision for connection with the HX3 Manager; MIDI interpreters and SysEx handling are far away from completion. Updates of FPGA, Scan Driver etc. must be done by SD card.

Feel free to help us converting the old sources to a PlatformIO or Arduino project! 3000 lines of code done, 25.000 pending...

C. Meyer 10/2010 - 11/2025

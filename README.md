# HX3.5 Firmware

### Firmware for HX3.5 Mainboard with ATmega1284P MCU

HX3.5 firmware was compiled with older **AVRCo** Pascal IDE from [**e-lab**](https://www.e-lab.de/) which is free of charge now. It runs on a ATmega1284P MCU (see **AVRco** directory).

In AVRco IDE project manager, import project **HX35_allinone.ppro** and compile with optimizer (brick wall icon). AVRco will create *HX35_main.hex* (flash content file) and *HX35_main.eep* (EEPROM file). To modify HX3.5 bootloader (reads firmware from SD Card) open AVRco project **HX35_bootloader.ppro**.

### Version History

* Update to version 5.9 for new FPGA 13022026
* Update to version 5.836

### Future repository for HX3.5 Firmware C++ conversion

We plan to port it to PlatformIO IDE with Arduino C++ framework for easier compilation and portability. Using the AVRco compiler, ignore the *src, lib* and *include* directory for now. These just contain a PlatformIO framework that displays some menus, inits the FPGA and loads a (present) scancore, but has no other functionality.

Feel free to help us converting it to a PlatformIO or Arduino project!

C.Meyer 10/2010 - 11/2025

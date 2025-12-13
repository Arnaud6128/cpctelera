- Run compile.bat in the tester folder.
- It will compile a tester, creating an obx (executable) file.
- Load it with any loader or DOS, e.g. on SIO2SD select the file and press RESET + OPTION: the program will start itself.
- The player is compatible with any Atari 8bit with 48K RAM (800 / 800XL / 1200XL / 600XL / 65XE / 130XE / XEGS), fitted with the SONari extension.

- To generate any another song, use the source profile "6502 MADS" when exporting the AKY song (either in the editor, or via the SongToAky command line tool).
- Don't forget to set the PSG frequency to 1773400 Hz in the Properties of the song before, else it will not sound the same on the hardware.
- Also set the PSG type to an AY or YM, according to your setup.
- As an optimisation, the player ignores the AKY header and directly points on the Subsong data. You might want to adapt the tester according to the name of the label. In the example song it is "Main_Subsong0_Linker", but when you export your song, you can change it to anything you want, so it may just be "Subsong0_Linker" or "MySuperSong_Subsong0_Linker".
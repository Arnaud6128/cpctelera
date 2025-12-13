        ;Tests the AKY player with digidrums, for MSX.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example). Tested with WebMSX emulator.
        
        org #8100
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
TesterStart:
        
        ;Initializes the music.
        ld hl,MusicStart
        call PLY_AKY_Init

        ;Initializes the digidrums.
        ld hl,MusicEvents               ;Address of the events (digidrums).
        ld de,MusicSamples              ;Address of the sample table.
        ld a,DIGICHANNEL_INDEX          ;Channel (0, 1 (=middle), 2)
        call PLY_AKY_InitDigidrums
        
MainLoop:
        xor a
        call #00d8      ;Checks the space bar. If pressed, exits.
        or a
        ret nz
        
        ei
        nop
        halt
        di
        
	;Plays one frame of the music.
        call PLY_AKY_Play
        
        jr MainLoop
        

Player:
        ;Selects the hardware. Mandatory, as Amstrad CPC is default.
        PLY_AKY_HARDWARE_MSX = 1
                
        ;Include digidrums replay? This must be declared BEFORE the player.
        PLY_AKY_USE_DIGIDRUMS = 1
        ;PLY_AKY_DIGIDRUM_PSG_NUMBER = 1      ;Optional, default value is 1.
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the address of the buffer must be declared *before* including the player, but PLY_AKY_ROM_BufferSize is only known *after*.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = #e000                  ;Can be set anywhere.
        ENDIF
        
        ;Uncomment to use this song...
;MusicStart:
;DIGICHANNEL_INDEX = 1
;        include "../resources/DigitestMusic_MSX_SPECTRUM_playerconfig.asm"       ;Includes the music.
;        include "../resources/DigitestMusic_MSX_SPECTRUM.asm"
;MusicEvents:
;        include "../resources/DigitestEvents.asm"                       ;Includes the events and samples.
;MusicSamples:
;        include "../resources/DigitestSamples.asm"
;MusicEnd:

        ;... or this one.
MusicStart:
DIGICHANNEL_INDEX = 0   ;Use channel 0 (left).
        include "../resources/Aganamemnon_MSX_SPECTRUM_playerconfig.asm"       ;Includes the music.
        include "../resources/Aganamemnon_MSX_SPECTRUM.asm"
MusicEvents:
        include "../resources/AganamemnonEvents.asm"                  ;Includes the events and samples.
MusicSamples:
        include "../resources/AganamemnonSamples.asm"
MusicEnd:

        ;... or this one.
;MusicStart:
;DIGICHANNEL_INDEX = 1
;        include "../resources/MusicSarkboteur_MSX_SPECTRUM_playerconfig.asm"    ;Includes the music.
;        include "../resources/MusicSarkboteur_MSX_SPECTRUM.asm"
;MusicEvents:
;        include "../resources/DigidrumSarkboteurEvents.asm"            ;Includes the events and samples.
;MusicSamples:
;        include "../resources/DigidrumSarkboteurSamples.asm"
;MusicEnd:

        ;The player itself. No need to insert the digidrum player, it is inserted by the AKY player.
        ;It must be included AFTER the "_playerconfig" files, else the player will not be optimized according to the song.
        include "../PlayerAkyMultiPsg.asm"

        print "Total size (player and music): ", {hex}($ - TesterStart)
        
TesterEnd:

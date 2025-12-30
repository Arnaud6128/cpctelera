        ;Tests the AKY player with sample player
        ;(one sample note at the same time, but on any channel).
        
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;This player is EXPERIMENTAL. It fully works, but the sound quality is not quite as I wanted it to be,
        ;because the PSG player should be "stopped" at regular interval to play more samples. This not-very-fun job is not done yet.
        ;On WebMSX, the demo music has a bass sample that sounds like crap and out-of-tune, due to parasitic frequencies.
        ;It may sound better on the real machine, I don't know.

        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example).
        ;Or directly loaded on the web via WebMSX emulator (handy!).
        
        org #8100
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
TesterStart:
        ;Initializes the music.
        ld hl,Music_Start
        call PLY_AKY_Init

        ;Initializes the samples.
        ld hl,SamplePatterns            ;Address of the sample patterns.
        ld de,Samples                   ;Address of the sample table.
        call PLY_AKY_InitSamples

TesterMainLoop:
        ei
        nop
        halt
        di

        ;xor a
        ;call #00d8      ;Checks the space bar. If pressed, exits.
        ;or a
        ;ret nz

        ;Plays a frame of the music. Samples are also triggered when necessary.
        call PLY_AKY_Play

        jr TesterMainLoop

Music_Start:
        ;Includes the music.
        include "../resources/LoPanAttackAky_MSX_SPECTRUM_playerconfig.asm"
        include "../resources/LoPanAttackAky_MSX_SPECTRUM.asm"

        ;Includes the sample patterns and samples.
SamplePatterns
        include "../resources/LoPanAttackRawLinear.asm"
Samples
        include "../resources/LoPanAttackSamples.asm"
Music_End:

Main_Player_Start:
        PLY_AKY_HARDWARE_MSX = 1
        
        ;Include sample replay? This must be declared BEFORE the player.
        PLY_AKY_USE_SAMPLE = 1
        ;PLY_AKY_SAMPLE_PSG_NUMBER = 1           ;>=1. Not mandatory, as it is the default value.

        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_ROM = 1     ;Must be set BEFORE the player is included.

        ;Declares the buffer for the ROM player, if you're using it.
        ;LIMITATION: the address of the buffer must be declared *before* including the player, but PLY_AKY_ROM_BufferSize is only known *after*.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        IFDEF PLY_AKY_ROM
                PLY_AKY_ROM_Buffer = #c000                  ;Can be set anywhere. 
        ENDIF

        ;The player itself. No need to insert the digidrum player, it is inserted by the AKY player.
        include "../PlayerAkyMultiPsg.asm"      ;Only this AKY player version supports sample replay.

Main_Player_End:
        print "Size of player: ", {hex}(Main_Player_End - Main_Player_Start)
        print "Size of music: ", {hex}(Music_End - Music_Start)
                IFDEF PLY_AKY_ROM
        print "Size of buffer in ROM: ", {hex}(PLY_AKY_ROM_BufferSize)
                ENDIF
        print "Total size (player and music): ", {hex}($ - Music_Start)

        ASSERT $ < #d800
TesterEnd:
        ;Tests the AKY player with sample player
        ;(one sample note at the same time, but on any channel).

        ;This player is EXPERIMENTAL. It fully works, but the sound quality is not quite as I wanted it to be,
        ;because the PSG player should be "stopped" at regular interval to play more samples. This not-very-fun job is not done yet.
        ;The demo music has a bass sample that sounds pretty bad and out-of-tune, due to parasitic frequencies.
        ;It sounds better on the hardware though.

        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        buildsna
        bankset 0

        org #100
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl

        ld hl,#c000
        ld de,#c001
        ld bc,#4000
        ld (hl),l
        ldir

        ;Initializes the music.
        ld hl,Music_Start
        call PLY_AKY_Init

        ;Initializes the samples.
        ld hl,SamplePatterns            ;Address of the sample patterns.
        ld de,Samples                   ;Address of the sample table.
        call PLY_AKY_InitSamples

Sync:
        ld b,#f5
        in a,(c)
        rra
        jr nc,Sync + 2
Sync2:  in a,(c)
        rra
        jr c,Sync2

        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a

        ;Plays a frame of the music. Samples are also triggered when necessary.
        call PLY_AKY_Play

        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        jr Sync

Music_Start:
        ;Includes the music.
        include "../resources/LoPanAttackAky_playerconfig.asm"
        include "../resources/LoPanAttackAky.asm"

        ;Includes the sample patterns and samples.
SamplePatterns
        include "../resources/LoPanAttackRawLinear.asm"
Samples
        include "../resources/LoPanAttackSamples.asm"
Music_End:

Main_Player_Start:
        PLY_AKY_HARDWARE_CPC = 1
        
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

        ;Generates a binary.
        SAVE "generated/playsamp.bin", Start, $ - Start, AMSDOS
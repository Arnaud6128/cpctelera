        ;Tests the AKY player with samples, for SPECTRUM.
        ;(one sample note at the same time, but on any channel).

        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;This player is EXPERIMENTAL. It fully works, but the sound quality is not quite as I wanted it to be,
        ;because the PSG player should be "stopped" at regular interval to play more samples. This not-very-fun job is not done yet.
        ;The demo music has a bass sample that sounds pretty bad and out-of-tune, due to parasitic frequencies.
        ;It may sound better on the real machine, I don't know.

        ;Tested with JSSpeccy 3.

        org #8000
Start:
        di
        ld sp,$
        
        ;Initializes the music.
        ld hl,MusicStart
        call PLY_AKY_Init

        ;Initializes the samples.
        ld hl,SamplePatterns            ;Address of the sample patterns.
        ld de,Samples                   ;Address of the sample table.
        call PLY_AKY_InitSamples

        ;Waits for the ~50Hz interrupt.
Sync:
        ei
        nop
        halt
        di

        ;Changes the border color to white.
        ld bc,#fe
        ld a,7
        out (c),a

	;Plays one frame of the music.
        call PLY_AKY_Play
        
        ;Changes the border color to black.
        ld bc,#fe
        xor a
        out (c),a
        
        jr Sync


Player:
        ;Selects the hardware. Mandatory, as Amstrad CPC is default.
        PLY_AKY_HARDWARE_SPECTRUM = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Include sample replay? This must be declared BEFORE the player.
        PLY_AKY_USE_SAMPLE = 1
        ;PLY_AKY_SAMPLE_PSG_NUMBER = 1           ;>=1. Not mandatory, as it is the default value.

        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        ;include "Mysong1_playerconfig.asm"
        ;include "Mysong2_playerconfig.asm"

        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the address of the buffer must be declared *before* including the player, but PLY_AKY_ROM_BufferSize is only known *after*.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = #c000                  ;Can be set anywhere.
        ENDIF
        
MusicStart:
        ;Includes the music.
        include "../resources/LoPanAttackAky_MSX_SPECTRUM_playerconfig.asm"
        include "../resources/LoPanAttackAky_MSX_SPECTRUM.asm"

        ;Includes the sample patterns and samples.
SamplePatterns
        include "../resources/LoPanAttackRawLinear.asm"
Samples
        include "../resources/LoPanAttackSamples.asm"
Music_End:

        ;The player itself. No need to insert the digidrum player, it is inserted by the AKY player.
        ;It must be included AFTER the "_playerconfig" files, else the player will not be optimized according to the song.
        include "../PlayerAkyMultiPsg.asm"

        print "Total size (player and music): ", {hex}($ - Start)
        ;Tests the AKY player with digidrums, for SPECTRUM.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        org #8000
Start:
        di
        ld sp,$
        
        ;Initializes the music.
        ld hl,MusicStart
        call PLY_AKY_Init
        
        ;Initializes the digidrums.
        ld hl,MusicEvents               ;Address of the events (digidrums).
        ld de,MusicSamples              ;Address of the sample table.
        ld a,DIGICHANNEL_INDEX          ;Channel (0, 1 (=middle), 2)
        call PLY_AKY_InitDigidrums

        ;Waits for the ~50Hz interrupt.
MainLoop:
        ei
        nop
        halt
        di

        ;Waits for the electron beam to be in the upper border.
        ;djnz $
        ;djnz $

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
        
        jr MainLoop


Player:
        ;Selects the hardware. Mandatory, as Amstrad CPC is default.
        PLY_AKY_HARDWARE_SPECTRUM = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Include digidrums replay? This must be declared BEFORE the player.
        PLY_AKY_USE_DIGIDRUMS = 1
        ;PLY_AKY_DIGIDRUM_PSG_NUMBER = 1      ;Optional, default value is 1. Only the first one is managed on this hardware. Contact me if needed.

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

        print "Total size (player and music): ", {hex}($ - Start)
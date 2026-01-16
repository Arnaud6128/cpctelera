        ;Tests the AKY player, for SPECTRUM.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;PLY_AKY_ADD_STOP_SOUNDS = 1             ;To add the "stop sounds" method.
        ;PLY_AKY_REMOVE_HOOKS = 1               ;To remove the +0/+3/+6 "hook" jumps.

        org #8000
        
Start:
        di
        ld sp,$
        
        ;Initializes the music.
        ld hl,Music
        call PLY_AKY_Init
        
        ;Waits for the ~50Hz interrupt.
MainLoop:
        ei
        nop
        halt
        di

        ;Waits for the electron beam to be in the upper border.
        djnz $
        djnz $

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
        
        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        ;include "Mysong1_playerconfig.asm"
        ;include "Mysong2_playerconfig.asm"

        include "../PlayerAky.asm"

        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = $                  ;Can be set anywhere.
                ds PLY_AKY_ROM_BufferSize, 0            ;Reserves the buffer for the ROM player (not mandatory, but cleaner).
        ENDIF
Music:
        ;What music to play?
        include "../resources/MusicAHarmlessGrenade_MSX_SPECTRUM.asm"

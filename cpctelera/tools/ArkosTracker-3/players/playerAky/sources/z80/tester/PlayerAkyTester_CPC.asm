        ;Tests the AKY player, for AMSTRAD CPC.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

	;Uncomment this to build a SNApshot, handy for testing (RASM feature).
        buildsna
        bankset 0

        PLY_AKY_ADD_STOP_SOUNDS = 1             ;To add the "stop sounds" method.
        ;PLY_AKY_REMOVE_HOOKS = 1               ;To remove the +0/+3/+6 "hook" jumps.
		
        org #f00
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl

	;Initializes the music.
        ld hl,Music_Start
        call Main_Player_Start + 0              ;Or use PLY_AKY_Init.

        ;Some dots on the screen to judge how much CPU takes the player.
        ld a,255
        ld hl,#c000 + 5 * #50
        ld (hl),a
        ld hl,#c000 + 6 * #50
        ld (hl),a
        ld hl,#c000 + 7 * #50
        ld (hl),a
		
        ld bc,#7f03
        out (c),c
        ld a,#4c
        out (c),a
        
Sync:   ld b,#f5
        in a,(c)
        rra
        jr nc,Sync + 2

        ei
        nop
        halt
        halt
        di

        ld b,90
        djnz $

        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a
        
        call PLY_AKY_Play                ;Play. Or the Main_Player_Start + 3 if the hooks are present (PLY_AKY_REMOVE_HOOKS not set).
        
        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        ;If space is pressed, stops the music.
        ld a,5 + 64
        call Keyboard
        cp #7f
        jr nz,Sync

        ;Stops the music. PLY_AKY_ADD_STOP_SOUNDS must be set (not default on AKY).
        IFDEF PLY_AKY_ADD_STOP_SOUNDS
                call PLY_AKY_Stop               ;Or the Main_Player_Start + 6 if the hooks are present (PLY_AKY_REMOVE_HOOKS not set). 
        ENDIF
        ;Endless loop!
        jr $

;Checks a line of the keyboard.
;IN:    A = line + 64.
;OUT:   A = key mask.
Keyboard:
        ld bc,#f782
        out (c),c
        ld bc,#f40e
        out (c),c
        ld bc,#f6c0
        out (c),c
        out (c),0
        ld bc,#f792
        out (c),c
        dec b
        out (c),a
        ld b,#f4
        in a,(c)
        ld bc,#f782
        out (c),c
        dec b
        out (c),0
        ret

Main_Player_Start:
        ;Selects the hardware. Not mandatory, as Amstrad CPC is default.
        PLY_AKY_HARDWARE_CPC = 1

        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.

        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        ;include "../resources/MusicCarpet_playerconfig.asm"
        ;include "../resources/MusicBoulesEtBits_playerconfig.asm"
        ;include "Mysong1_playerconfig.asm"
        ;include "Mysong2_playerconfig.asm"

        ;What player to use?
        include "../PlayerAky.asm"                       ;Only this player has the ROM feature.
        ;include "../PlayerAkyStabilized_CPC.asm"        ;For now, this player does not take the Player Configuration in account.
        
        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = $                  ;Can be set anywhere.
                ds PLY_AKY_ROM_BufferSize, 0            ;Reserves the buffer for the ROM player (not mandatory, but cleaner).
        ENDIF
Main_Player_End:

Music_Start:
        ;What music to play?
        ;include "../resources/MusicCarpet.asm"
        include "../resources/MusicBoulesEtBits.asm"

Music_End:

        print "Total size (player and music): ", {hex}($ - Main_Player_Start)
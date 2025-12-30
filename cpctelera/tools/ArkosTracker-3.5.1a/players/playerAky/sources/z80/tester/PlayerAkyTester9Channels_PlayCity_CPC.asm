        ;Tests the AKY player, targeting the PlayCity hardware (9 channels) for AMSTRAD CPC.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

	;Uncomment this to build a SNApshot, handy for testing (RASM feature).
        ;buildsna
        ;bankset 0
		
        org #f00
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl

	;Initializes the music.
        ld hl,Music_Start
        call Main_Player_Start + 0

        ;Some dots on the screen to judge how much CPU takes the player.
        ;ld a,255
        ;ld hl,#c000 + 5 * #50
        ;ld (hl),a
        ;ld hl,#c000 + 6 * #50
        ;ld (hl),a
        ;ld hl,#c000 + 7 * #50
        ;ld (hl),a
		
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
        
        call Main_Player_Start + 3                ;Play.
        
        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        jr Sync

Main_Player_Start:
        ;Selects the hardware. Mandatory.
        PLY_AKY_HARDWARE_PLAYCITY = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.

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
        
        ;What player to use?
        include "../PlayerAkyMultiPsg.asm"        

Main_Player_End:

Music_Start:
        ;What music to play?
        include "../resources/MusicTheLastV8_9Channels.asm"
        

Music_End:
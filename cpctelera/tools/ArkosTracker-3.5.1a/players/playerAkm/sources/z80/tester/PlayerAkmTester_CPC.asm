        ;Tests the AKM player, for AMSTRAD CPC.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;This builds a SNApshot, handy for testing (RASM feature).
        ;buildsna
        ;bankset 0

        org #1000

FLAG_25Hz equ 0                                ;Watch out for this in your test! Should be 0 most of the time.

        di
        ld hl,#c9fb
        ld (#38),hl
        ld sp,#38

        ;Initializes the music.
        ld hl,Music
        xor a                                   ;Subsong 0.
        call PLY_AKM_Init

        ;Puts some markers to see the CPU.
        ld a,255
        ld hl,#c000 + 5 * #50
        ld (hl),a
        ld hl,#c000 + 6 * #50
        ld (hl),a
        ld hl,#c000 + 7 * #50
        ld (hl),a
        ld hl,#c000 + 8 * #50
        ld (hl),a
        ld hl,#c000 + 9 * #50
        ld (hl),a
        ld hl,#c000 + 10 * #50
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

        ;If 25 hz.
        if FLAG_25Hz
                halt
                halt
                halt
                halt
                halt
                halt
        endif
        
        di

        ld b,90
        djnz $

        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a

	;Plays the music.
        call PLY_AKM_Play

        ld bc,#7f10
        out (c),c
        ld a,#55
        out (c),a
        ei
        nop
        halt
        di
        ld a,#54
        out (c),a

;If space is pressed, stops the music.
        ld a,5 + 64
        call Keyboard
        cp #7f
        jr nz,Sync

        ;Stops the music.
        call PLY_AKM_Stop
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


Music:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/Dead On Time - Main Menu_playerconfig.asm"

        include "../resources/Dead On Time - Main Menu.asm"
        
Player:
        ;Selects the hardware. Not mandatory on CPC, as it is default.
        ;PLY_AKM_HARDWARE_CPC = 1

        ;Want a ROM player (a player without automodification)?
        ;PLY_AKM_Rom = 1                         ;Must be set BEFORE the player is included.
       
        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the address MUST be compiled BEFORE the player, but the size (PLY_AKM_ROM_BufferSize) of the buffer is only known *after* ther player is compiled.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        ;Note that the size of the buffer shrinks when using the Player Configuration feature. Use the largest size and you'll be safe.
        IFDEF PLY_AKM_Rom
                PLY_AKM_ROM_Buffer = #f000                  ;Can be set anywhere.
        ENDIF
        
        include "../PlayerAkm.asm"


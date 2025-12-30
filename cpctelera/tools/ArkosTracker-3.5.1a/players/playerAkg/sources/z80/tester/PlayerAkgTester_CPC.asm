        ;Tests the AKG player, for the AMSTRAD CPC.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;Uncomment this to build a SNApshot, handy for testing (RASM feature).
        buildsna
        bankset 0

        org #1000
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl

        ld hl,Music_Start
        xor a                   ;Subsong 0.
        call PLY_AKG_Init

        ;Some dots on the screen to judge how much CPU takes the player.
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

        ld sp,#38

        ld b,90
        djnz $

        ;Calls the player, shows some colors to see the consumed CPU.
        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a
        call PLY_AKG_Play
        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        ;If space is pressed, stops the music.
        ld a,5 + 64
        call Keyboard
        cp #7f
        jr nz,Sync

        ;Stops the music.
        call PLY_AKG_Stop
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


Music_Start:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/Music_AHarmlessGrenade_playerconfig.asm"
        
        include "../resources/Music_AHarmlessGrenade.asm"
Music_End:

Main_Player_Start:
        ;Selects the hardware. Not mandatory on CPC, as it is default.
        ;PLY_AKG_HARDWARE_CPC = 1

        ;Want a ROM player (a player without automodification)?
        ;PLY_AKG_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the SIZE of the buffer (PLY_AKG_ROM_BufferSize) is only known *after* ther player is compiled.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        ;Note that the size of the buffer shrinks when using the Player Configuration feature. Use the largest size and you'll be safe.
        IFDEF PLY_AKG_Rom
                PLY_AKG_ROM_Buffer = #f000                  ;Can be set anywhere.
        ENDIF

        include "../PlayerAkg.asm"
Main_Player_End:

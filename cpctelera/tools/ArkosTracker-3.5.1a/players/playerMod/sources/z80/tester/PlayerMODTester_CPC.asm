        ;Tests the MOD player, for AMSTRAD CPC.
        ;Compiles with RASM.

        ;This builds a SNApshot, handy for testing (RASM feature).
        buildsna
        bankset 0

        org #100

        di
        ld hl,#c9fb
        ld (#38),hl
        ld sp,#38

        ;Initializes the music.
        ld hl,Music
        call PLY_MOD_Init

MainLoop:
        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a

        call PLY_MOD_Play
 
        ;Uncomment this if you need a space bar key test.
        ;call CheckKeyboardAndExitIfPressed
        
        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        jr MainLoop

CheckKeyboardAndExitIfPressed:
        ;Checks a line of the keyboard.
        ld a,5 + 64             ;Tests SPACE.
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
        
        cp #7f
        jr z,Exit
        
        ;IMPORTANT! On CPC, the keyboard test above changes the selected PSG register, so
        ;we have to select it back, else, no sound!
        ld bc,#f409
        out (c),c
        ld bc,#f6c0
        out (c),c
        out (c),0
        ret

Exit:
        ld bc,#7f10
        out (c),c
        ld a,#4c
        out (c),a
        jr $
        
Player:
        include "../PlayerMod_CPC.asm"
        
Music:
        ;What music to play?
        include "../resources/SmallMod.asm"
        ;include "../resources/ShowThem.asm"

        print "End: ", {hex}$
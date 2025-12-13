        ;Tests the FAP player, for the AMSTRAD CPC.
        ;Compressor/player by Hicks/Vanity and Gozeur/Contrast: https://github.com/grim1z/FastAyPlayer
        ;This tester is also based on their code.

        ;This compiles with RASM.
        ;FAP player currently does NOT support Disark to convert the player on any other assembler. Plague Hicks for support!

        ;Uncomment this to build a SNApshot, handy for testing (RASM feature).
        buildsna
        bankset 0

        org #1000
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl
        ld sp,$

        ;Initialize the player.
        ;Once the player is initialized, you can overwrite the init code if you need some extra memory.
        ld a,hi(FapBuff)   ;High byte of the decrunch buffer address.
        ld bc,FapPlay      ;Address of the player binary.
        ld de,ReturnAddr   ;Address to jump after playing a song frame.
        ld hl,FapMusic     ;Address of song data.
        call FapInit


        ;Some dots on the screen to judge how much CPU takes the player.
        ld a,255
        ld hl,#c000 + 5 * #50
        ld (hl),a
        ld hl,#c000 + 6 * #50
        ld (hl),a
        ld hl,#c000 + 7 * #50
        ld (hl),a
        ld hl,#c000 + 8 * #50

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

        ld b,92
        djnz $

        ;Calls the player, shows some colors to see the consumed CPU.
        ld bc,#7f00
        out (c),c
        ld a,#4b
        out (c),a

        ld (RestoreSp),sp	    ;Save our precious stack-pointer.
        jp FapPlay		    ;Jump into the replay-routine.
ReturnAddr: ld sp,0		    ;Return address the replay-routine will jump back to.
RestoreSp = ReturnAddr + 1

        ld bc,#7f00
        out (c),c
        ld a,#54
        out (c),a

        ;If space is pressed, stops the music.
        ld a,5 + 64
        call Keyboard
        cp #7f
        jr nz,Sync

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

FapPlay:
        include	"../FapMacro.asm"       ;Must be loaded BEFORE the player.
        assert $ == FapPlay             ;Make sure there is no data in this "FapMacro" file.
        include "../FapPlay.asm"
FapMusic:
        ;What song to load?
        incbin "../resources/Targhan - A Harmless Grenade.fap"
        include "../resources/Targhan - A Harmless Grenade_fap_constants.asm"

        ;incbin "../resources/Targhan - Hocus Pocus.fap"
        ;include "../resources/Targhan - Hocus Pocus_fap_constants.asm"

        ;incbin "../resources/Tom&Jerry - Boules Et Bits (Extended).fap"
        ;include "../resources/Tom&Jerry - Boules Et Bits (Extended)_fap_constants.asm"

        ;incbin "../resources/UltraSyd - Fractal.fap"
        ;include "../resources/UltraSyd - Fractal_fap_constants.asm"

        ;incbin "../resources/FenyxKell - Bobline.fap"
        ;include "../resources/FenyxKell - Bobline_fap_constants.asm"

        assert $ < #7fff, "Error: fap music shall not cross #8000 boundary!"

;The init code can be put anywhere and can be dismissed once used.
FapInit: include "../FapInit.asm"

End:

        align #100
FapBuff:
        assert lo(FapBuff) == 0, "Error: The buffer must be 256-aligned".
        ;Buffer, usually #B42 bytes up to #C48 bytes on rare occasions. It MUST be 256-aligned.
        ;Given by the output of the encoder, but AT3 FAP exporter generates a convenient constant file!
        ds FapBufferSize, 0


        ;Saves into a DSK.
        ;SAVE 'fap.bin', Start, End - Start, DSK, "generated/FapTest.dsk"
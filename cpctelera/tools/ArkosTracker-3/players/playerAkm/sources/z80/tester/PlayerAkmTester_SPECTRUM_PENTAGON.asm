        ;Tests the AKM player, for SPECTRUM or PENTAGON (choose the target at the bottom).
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;You can generate a SNA, with the execution point at "Start" (#8183).
        ;Example with "makesna" from the "zxspectrum-utils":
        ;makesna snaToGenerate.sna 33155 assembledPlayerAndMusic.bin 33153
        ;(33153 = 0x8181, 33155 = 0x8183).

        ;Tester code based on the one Grim/Arkos did for Arkos Tracker 1.

        org #8181
        
        ;Dummy interrupt service routine.
        ei
        ret
      
        ;The Program Counter must set here when generating the SNA (#8183).
Start:

        ;Here comes the test program.
        ;Initializes IM2, gets rid of the system interrupt.
        di
        ld hl,#8000	;HL points to the IM2 Lookup table.
        ld a,h
        ld i,a		;Set I=#80.
        im 2		;Switch to vectorized interrupts.
        inc a
Im2FillLut: ld (hl),a	;Fills the IM2 LUT with #81.
        inc l		;All INT will jump to #8181.
        jr nz,Im2FillLut
        inc h
        ld (hl),a
	
        ld sp,$
        
        ;Initializes the music.
        ld hl,Music
        xor a                                   ;Subsong 0.
        call PLY_AKM_Init
        
        ei

        ;Waits for the ~50Hz interrupt.
MainLoop: halt

        ;Waits for the electron beam to be in the upper border.
        djnz $
        djnz $

        ;Changes the border color to white.
        ld bc,#fe
        ld a,7
        out (c),a

	;Plays one frame of the music.
        call PLY_AKM_Play
        
        ;Changes the border color to black.
        ld bc,#fe
        xor a
        out (c),a
        
        jr MainLoop


Music:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/Dead On Time - Main Menu_playerconfig.asm"

        include "../resources/Dead On Time - Main Menu.asm"
        
Player:
        ;Selects the hardware. Mandatory, as CPC is default.
        PLY_AKM_HARDWARE_SPECTRUM = 1
        ;PLY_AKM_HARDWARE_PENTAGON = 1

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
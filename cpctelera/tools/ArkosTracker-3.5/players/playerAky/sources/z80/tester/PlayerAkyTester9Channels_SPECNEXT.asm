        ;Tests the AKY player, 9 channels, for the SPECNEXT.
        ;This compiles with RASM. Please check the compatibility page to learn how to convert your sources to ANY assembler!
        
        ;Tester code based on the one Grim/Arkos did for Arkos Tracker 1.

        org #8181
        
        ;Dummy interrupt service routine.
        ei
        ret
      
        ;The Program Counter MUST be set here when generating the SNA (#8183).
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
        call PLY_AKY_Init
        
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
        call PLY_AKY_Play
        
        ;Changes the border color to black.
        ld bc,#fe
        xor a
        out (c),a
        
        jr MainLoop

        ;Selects the target hardware. Mandatory!
        PLY_AKY_HARDWARE_SPECNEXT = 1

        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.

        ;Declares the buffer for the ROM player, if you're using it.
        ;LIMITATION: the address of the buffer must be declared *before* including the player, but PLY_AKY_ROM_BufferSize is only known *after*.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        ;IFDEF PLY_AKY_ROM
        ;        PLY_AKY_ROM_Buffer = #c000                  ;Can be set anywhere.
        ;ENDIF
Music:
        ;What music to play?
        
        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled, else it is not effective.
        include "../resources/MusicTheLastV8_9Channels_playerconfig.asm"
        ;Now includes the music itself.
        include "../resources/MusicTheLastV8_9Channels.asm"
        
Player:
        include "../PlayerAkyMultiPsg.asm"


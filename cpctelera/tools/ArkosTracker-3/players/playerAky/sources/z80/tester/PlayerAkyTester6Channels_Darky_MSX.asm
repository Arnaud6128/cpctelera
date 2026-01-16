        ;Tests the AKY player, for MSX, targeting the 6-channel DARKY hardware.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example). Tested with the BlueMSX emulator.
        
        org #8100
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
TesterStart:
        
        ;Initializes the music.
        ld hl,Music
        xor a                                   ;Subsong 0.
        call PLY_AKY_Init
        
MainLoop:
        xor a
        call #00d8      ;Checks the space bar. If pressed, exits.
        or a
        ret nz
        
        ei
        nop
        halt
        
	;Plays one frame of the music.
        call PLY_AKY_Play
        
        jr MainLoop
        

Player_Start:
        ;Selects the hardware. Mandatory.
        PLY_AKY_HARDWARE_DARKY = 1
        
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
        ;IFDEF PLY_AKY_Rom
        ;        PLY_AKY_ROM_Buffer = #c000                  ;Can be set anywhere.
        ;ENDIF
        
        ;What player to use?
        include "../PlayerAkyMultiPsg.asm"        

Player_End:

Music:
        ;What music to play?
        include "../resources/MusicTheLastV8_6Channels.asm"

Music_End:

TesterEnd:

        ;Tests the AKM player, for MSX.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example). Tested with the BlueMSX emulator.
        
        org #b000
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
        
TesterStart:
        
        ;Initializes the music.
        ld hl,Music
        xor a                                   ;Subsong 0.
        call PLY_AKM_Init
        
MainLoop:
        xor a
        call #00d8      ;Checks the space bar. If pressed, stops the music.
        or a
        jp nz,PLY_AKM_Stop
        
        ei
        halt
        
        ;Plays one frame of the music.
        call PLY_AKM_Play
        
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
        PLY_AKM_HARDWARE_MSX = 1

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

        
TesterEnd:

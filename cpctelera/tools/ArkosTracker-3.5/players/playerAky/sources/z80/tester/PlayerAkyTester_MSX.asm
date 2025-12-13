        ;Tests the AKY player, for MSX.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example). Tested with the BlueMSX emulator.
        
        PLY_AKY_ADD_STOP_SOUNDS = 1             ;To add the "stop sounds" method.
        ;PLY_AKY_REMOVE_HOOKS = 1               ;To remove the +0/+3/+6 "hook" jumps.

        org #8100
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
TesterStart:
        
        ;Initializes the music.
        ld hl,Music
        call PLY_AKY_Init
        
MainLoop:
        xor a
        call #00d8      ;Checks the space bar. If pressed, exits.
        or a
        jr nz,StopSounds
        
        ei
        nop
        halt
        
	;Plays one frame of the music.
        call PLY_AKY_Play
        
        jr MainLoop
        
StopSounds
        ;Stops the music. PLY_AKY_ADD_STOP_SOUNDS must be set (not default on AKY).
        IFDEF PLY_AKY_ADD_STOP_SOUNDS
                call PLY_AKY_Stop               ;Or the Main_Player_Start + 6 if the hooks are present (PLY_AKY_REMOVE_HOOKS not set). 
        ENDIF
        jr $    ;Endless loop.

Player:
        ;Selects the hardware. Mandatory, as Amstrad CPC is default.
        PLY_AKY_HARDWARE_MSX = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        ;include "Mysong1_playerconfig.asm"
        ;include "Mysong2_playerconfig.asm"
        include "../resources/MusicAHarmlessGrenade_MSX_SPECTRUM_playerconfig.asm"

        include "../PlayerAky.asm"

        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = $                  ;Can be set anywhere.
                ds PLY_AKY_ROM_BufferSize, 0            ;Reserves the buffer for the ROM player (not mandatory, but cleaner).
        ENDIF
Music:
        ;What music to play?
        include "../resources/MusicAHarmlessGrenade_MSX_SPECTRUM.asm"
        
TesterEnd:

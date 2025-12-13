        ;Tests the AKG player, for MSX.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;This tester is by NYYRIKKI (thanks!).

        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example),
        ;or simpler, the binary can be injected directly into WebMSX.
        
HOOK    equ #FD9F               ; H.TIMI VDP interrupt hook that is called 50 or 60 times/s to play the song
CHSNS   equ #9C                 ; Routine to check if characters available in keyboard buffer

        org #8100
        
        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.


TesterStart:
        
        ;Initializes the music.
        ld hl,Music_Start
        xor a                                   ;Subsong 0.
        call PLY_AKG_Init
        
        di
        ld hl,HOOK              ; Store original VDP hook content
        ld de,OldHook
        ld bc,5
        ldir

        ld a,#C3                ; JP instruction
        ld hl,NewHook           ; our new interrupt handler
        ld (HOOK),a
        ld (HOOK+1),hl          ; Place the jump to hook handler
        ei

IdleLoop:
        call CHSNS              ; Checks keyboard buffer
        jr z,IdleLoop           ; Loops playing the music until any key is pressed.

ExitProg:
        di
        ld hl,OldHook
        ld de,HOOK              ; Restore original code to VDP interrupt hook
        ld bc,5
        ldir

        call PLY_AKG_Stop
        ret

NewHook:
        push af
        call PLY_AKG_Play
        pop af
OldHook:
        ds 5                    ; Space to store old interrupt hook handler (this is executed after the play routine)



Music_Start:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/Music_AHarmlessGrenade_playerconfig.asm"
        
        include "../resources/Music_AHarmlessGrenade.asm"
Music_End:

Main_Player_Start:
        ;Selects the hardware. Mandatory, as CPC is default.
        PLY_AKG_HARDWARE_MSX = 1
        
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

TesterEnd:
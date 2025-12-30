        ;Tests the AKG player, for SVI 318 and 328.
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;This tester is by NYYRIKKI (thanks!).

        ;To test:
        ;RASM.exe PlayerAkgTester_SVI.asm -ob test\SVITST.BIN
        ;Create a cassette image:
        ;svitools.exe -b test\SVITST.BIN -o test\SVITST.CAS
        ;On openMSX, load the program with:
        ;BLOAD "CAS:",R

HOOK    equ #FE79               ; H.KEYI interrupt hook that is used to play the song
CHSNS   equ #3B                 ; Routine to check if characters available in keyboard buffer

        org #c200 - 6           ; Routine start address (-6 is for the BASIC header length)
                                ; Use lower start address (ie. #a000 if you use disk drive.

        ;This is the binary file header for SVI-BASIC (disk or cassette)
        dw TesterStart          ; Begin address
        dw TesterEnd            ; End address
        dw TesterStart          ; Execution address.

TesterStart:
        
        ;Initializes the music.
        ld hl,Music_Start
        xor a                                   ;Subsong 0.
        call PLY_AKG_Init
        
        di
        ld hl,HOOK              ; Store original interrupt hook data
        ld de,OldHook
        ld bc,3
        ldir
        ld a,#C3                ; JP-instruction
        ld hl,NewHook           ; our new interrupt handler
        ld (HOOK),a
        ld (HOOK+1),hl          ; Place the jump to interrupt handler
        ei

IdleLoop:
        call CHSNS              ; Checks keyboard buffer
        jr z,IdleLoop           ; Loops playing the music until any key is pressed.

ExitProg:
        di
        ld hl,OldHook
        ld de,HOOK              ; Restore original hook to interrupt hook handler
        ld bc,3
        ldir
        call PLY_AKG_Stop
        ret

NewHook:
        exx
        ex af,af'
        push af
        push de
        push bc
        push hl
        push ix
        push iy
        call PLY_AKG_Play
        pop iy
        pop ix
        pop hl
        pop bc
        pop de
        pop af
        ex af,af'
        exx
OldHook:
        ds 3                    ; Space to store old interrupt hook (this is executed after the play routine)

Music_Start:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        ;include "../resources/Music_AHarmlessGrenade_playerconfig.asm"
        
        include "../resources/Music_AHarmlessGrenade.asm"
Music_End:

Main_Player_Start:
        ;Selects the hardware. Mandatory, as CPC is default.
        PLY_AKG_HARDWARE_SVI = 1
        
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

TesterEnd: nop         ;extra nop for cassette compatibility
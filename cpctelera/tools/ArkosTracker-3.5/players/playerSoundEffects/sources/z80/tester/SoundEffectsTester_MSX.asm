        ;Tests the stand-alone sound effects player, for MSX.
        ;If you want to play sound effects along with music, do not use this player, check the related sound effects player that goes along the music player!

        ;The sound effects are played one after the other automatically.

        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!
        
        ;A binary file (to load with the BLOAD MSX command) is generated.
        ;It can then be included inside a DSK file (using the DiskMgr software for example). Tested with the BlueMSX emulator.
        
LAST_SOUND_EFFECT_INDEX equ 5                 ;Index of the last sound effect.
        
        org #b000

        ;This is the header for a BINary file for MSX. See https://www.faq.msxnet.org/suffix.html
        db #fe
        dw TesterStart
        dw TesterEnd
        dw TesterStart          ;Execution address.
        
        
TesterStart:
        
        ;Initializes the sound effects.
        ld hl,SoundEffects
        call PLY_SE_InitSoundEffects
        
        ei
        
MainLoop:
        xor a
        call #00d8      ;Checks the space bar. If pressed, exits.
        or a
        ret nz
        
        ei
        halt
        
        call PLY_SE_PlaySoundEffectsStream
        
        ;How long to wait to trigger another sound effect?
Wait:   ld a,1
        dec a
        jr nz,WaitMore

        ;Chooses a "random" channel (0, 1, 2) to play the sound on.
        ld a,r
        and %11
        cp %11
        jr nz,WaitChannelOk
        ld a,1
WaitChannelOk:
        ld c,a
        
        ;Triggers the next sound effect.
SelectedSoundEffect: ld a,0
        inc a
        cp LAST_SOUND_EFFECT_INDEX + 1
        jr nz,SoundEffectNoOverflow
        ld a,1
SoundEffectNoOverflow:
        ld (SelectedSoundEffect + 1),a
        
        ;Selects the sound effect (A = sound effect number (>0)).
        ld b,0          ;Full volume.
        call PLY_SE_PlaySoundEffect
        
        ;How long to wait for the next sound effect.
        ld a,50
WaitMore: ld (Wait + 1),a
        
        jr MainLoop
        

SoundEffects:
        ;Include here the Player Configuration source of the sound effects (you can generate them with AT2 while exporting the SFXs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/SoundEffects_playerconfig.asm"

        include "../resources/SoundEffects.asm"

Player:
        ;Selects the hardware. Mandatory, as CPC is default.
        PLY_SE_HARDWARE_MSX = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_SE_Rom = 1                         ;Must be set BEFORE the player is included.
       
        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the address MUST be compiled BEFORE the player, but the size (PLY_SE_ROM_BufferSize) of the buffer is only known *after* ther player is compiled.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        ;Note that the size of the buffer shrinks when using the Player Configuration feature. Use the largest size and you'll be safe.
        IFDEF PLY_SE_Rom
                PLY_SE_ROM_Buffer = #f000                  ;Can be set anywhere.
        ENDIF

        include "../PlayerSoundEffects.asm"

        
TesterEnd:

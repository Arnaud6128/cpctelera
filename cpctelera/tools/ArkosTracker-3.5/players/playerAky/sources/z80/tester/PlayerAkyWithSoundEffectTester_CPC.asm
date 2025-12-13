        ;Tests the AKY player, as well as the sound effects, for CPC.
        ;The player itself works for all the platforms, of course!
        
        ;Important note: the sound effects feature is ONLY available for the "multi-PSG" player and it can not be done otherwise.
        ;So the "multi-PSG" player is used, but only one PSG is declared.
        ;This makes the player less efficient than the raw AKY player. But this is the price to pay if you want SFXs with this player.
        
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;This plays a sound effect on one channel every second.

	;Uncomment this to build a SNApshot, handy for testing (RASM feature).
        ;buildsna
        ;bankset 0
        
        org #f00
Start   equ $
        di
        ld hl,#c9fb
        ld (#38),hl
        
	;Initializes the music.
        ld hl,Music_Start
        call PLY_AKY_Init
        
        ;Initializes the sound effects.
        ld hl,Untitled_SoundEffects
        call PLY_AKY_InitSoundEffects

        ;Some dots on the screen to judge how much CPU takes the player.
        ld a,255
        ld hl,#c000 + 5 * #50
        ld (hl),a
        ld hl,#c000 + 6 * #50
        ld (hl),a
        ld hl,#c000 + 7 * #50
        ld (hl),a
                
        ld bc,#7f03
        out (c),c
        ld a,#4c
        out (c),a
        
Sync:
        ld b,#f5
        in a,(c)
        rra
        jr nc,Sync + 2

        ei
        nop
        halt
        halt
        di

        ld b,90
        djnz $

        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a
        
        ;Uses a small counter to play a sound effect at regular interval.
SfxCounter: ld a,0
        inc a
        cp 50
        jr nz,SfxCounterNotEnded

        ld a,11          ;A = Sound effect number (>0!).
        ld c,0          ;C = The channel where to play the sound effect (0, 1, 2).
        ld b,0          ;B = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
        call PLY_AKY_PlaySoundEffect
        
        xor a
SfxCounterNotEnded:
        ld (SfxCounter + 1),a
        
        call PLY_AKY_Play                ;Play one frame of the music, with the possible SFXs.
        
        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        jr Sync

Main_Player_Start:
        ;Selects the hardware. Mandatory with this player, there is no default hardware.
        PLY_AKY_HARDWARE_CPC = 1
        ;PLY_AKY_HARDWARE_PLAYCITY = 1

        ;Sound effects?
        PLY_AKY_MANAGE_SOUND_EFFECTS = 1
        ;If sound effects, the PSG number where to play SFX must be declared (>=1). This is mandatory.
        PLY_AKY_SFX_PSG_NUMBER = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.

        ;Includes here the Player Configuration source of the songs (you can generate them with AT3 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning: this must be included BEFORE the player is compiled.
        ;include "../resources/MusicCarpet_playerconfig.asm"
        ;include "../resources/SoundEffectsDeadOnTime_playerconfig.asm"

        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = #f000              ;Can be set anywhere.
        ENDIF
        
        include "../PlayerAkyMultiPsg.asm"              ;Only the Multi-PSG player allows sound effects.
Main_Player_End:

Music_Start:
        ;What music to play?
        include "../resources/MusicCarpet.asm"
        ;include "../resources/MusicBoulesEtBits.asm"
        
        ;include "../resources/MusicLastV89Channels.asm"         ;9 channels, for Playcity.

Music_End:

SoundEffects_Start:
        include "../resources/SoundEffectsDeadOnTime.asm"
SoundEffects_End:

        print "Size of player: ", {hex}(Main_Player_End - Main_Player_Start)
        print "Size of music: ", {hex}(Music_End - Music_Start)
        print "Size of sfx: ", {hex}(SoundEffects_End - SoundEffects_Start)
                IFDEF PLY_AKY_ROM
        print "Size of buffer in ROM: ", {hex}(PLY_AKY_ROM_BufferSize)
                ENDIF
        print "Total size (player and music): ", {hex}($ - Music_Start)
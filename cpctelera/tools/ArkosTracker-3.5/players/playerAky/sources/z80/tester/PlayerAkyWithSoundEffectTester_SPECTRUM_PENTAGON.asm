        ;Tests the AKY player, as well as the sound effects, for SPECTRUM or PENTAGON.
        ;The player itself works for all the platforms, of course!
        
        ;Important note: the sound effects feature is ONLY available for the "multi-PSG" player and it can not be done otherwise.
        ;So the "multi-PSG" player is used, but only one PSG is declared.
        ;This makes the player less efficient than the raw AKY player. But this is the price to pay if you want SFXs with this player.
        
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;This plays a sound effect on one channel every second.
        
        org #8000
Start   equ $

        di
        
	;Initializes the music.
        ld hl,Music_Start
        call PLY_AKY_Init
        
        ;Initializes the sound effects.
        ld hl,Untitled_SoundEffects
        call PLY_AKY_InitSoundEffects

MainLoop:
        ei
        nop
        halt
        
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
        
        jr MainLoop

Main_Player_Start:
        ;Selects the hardware.
        PLY_AKY_HARDWARE_SPECTRUM = 1
        ;PLY_AKY_HARDWARE_PENTAGON = 1

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
        
        
TesterEnd:
        ;Tests the AKY player with sound effects, for PCW TurboSound (6 channels).
        ;This compiles with RASM. Please check the compatibility page on the website, you can convert these sources to ANY assembler!

        ;Thanks to Kachorro on his help about PCW and how to create this tester!
        ;Thanks to Prodatron for the help about the VSync loop.

        ;To test, compile in #0, launch CP/M Box emulator with:
        ;PCW.exe @ 0000 80 81 82 83 Y 0000 <exe file.bin>
        ;Warning, this simple setup doesn't work for larger than 16kb binary.

        org #0

        di
        ld sp,#fff0     ;Before keyboard!

        ;Initializes the music.
        ld hl,Music_Start
        call PLY_AKY_Init
        
        ;Initializes the sound effects.
        ld hl,Untitled_SoundEffects
        call PLY_AKY_InitSoundEffects

MainLoop:
VSync1  in a,(#f8)   ;Bit 6 is set while screen is not being drawn. Wait for this state.
        bit 6,a
        jr z,VSync1
VSync2  in a,(#f8)   ;Wait for the screen to be drawn.
        bit 6,a
        jr nz,VSync2

        ;Uses a small counter to play a sound effect at regular interval.
SfxCounter: ld a,0
        inc a
        cp 50
        jr nz,SfxCounterNotEnded

        ld a,11         ;A = Sound effect number (>0!).
        ld c,1          ;C = The channel where to play the sound effect (0, 1, 2).
        ld b,0          ;B = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
        call PLY_AKY_PlaySoundEffect
        
        xor a
SfxCounterNotEnded:
        ld (SfxCounter + 1),a

	;Plays one frame of the music.
        call PLY_AKY_Play
        
        jr MainLoop


Music_Start:
        ;Include here the Player Configuration source of the songs (you can generate them with AT2 while exporting the songs).
        ;If you don't have any, the player will use a default Configuration (full code used), which may not be optimal.
        ;If you have several songs, include all their configuration here, their flags will stack up!
        ;Warning, this must be included BEFORE the player is compiled.
        include "../resources/MusicTheLastV8_6Channels_playerconfig.asm"
        include "../resources/MusicTheLastV8_6Channels.asm"
Music_End:

SoundEffects_Start:
        include "../resources/SoundEffectsDeadOnTime.asm"
SoundEffects_End:

Main_Player_Start:
        ;Selects the hardware. Mandatory, as CPC is default.
        PLY_AKY_HARDWARE_PCW_TURBOSOUND = 1
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_Rom = 1                         ;Must be set BEFORE the player is included.
        
        ;Sound effects?
        PLY_AKY_MANAGE_SOUND_EFFECTS = 1
        ;If sound effects, the PSG number where to play SFX must be declared (>=1). This is mandatory.
        PLY_AKY_SFX_PSG_NUMBER = 1

        ;Declares the buffer for the ROM player, if you're using it. You can declare it anywhere of course.
        ;LIMITATION: the SIZE of the buffer (PLY_AKY_ROM_BufferSize) is only known *after* ther player is compiled.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        ;Note that the size of the buffer shrinks when using the Player Configuration feature. Use the largest size and you'll be safe.
        IFDEF PLY_AKY_Rom
                PLY_AKY_ROM_Buffer = #3f00                  ;Can be set anywhere.
        ENDIF

        include "../PlayerAkyMultiPsg.asm"
Main_Player_End:

        assert $ < #4000, "This tester only manages a 16k page. Split the binary into 2 pages."
        ;This creates a program to be loaded in BASIC, on CPC, so that you can use a song in BASIC,
        ;using interruption, as well as sound effects. Very handy to add music and sound to a game!
        
        ;This tester focuses on the AKG player, but you can actually use the one you want.
        
        ;Assembles this with RASM, loads the binary in Basic (load"player.bin",&9500 for example).
        ;Then type:
        ;10 memory &6fff
        ;20 load"music.bin",&7000       ;Or where you have compiled it, beware not to overwrite the player!!
        ;30 load"sfxs.bin",&9000        ;The same. Remove this line if you're not using sound effects.
        ;40 player = &9500
        ;50 load"player.bin",player     ;Loads the player.
        ;
        ;60 call player+0,&7000,0       ;Plays the subsong 0, from the music previously loaded in &7000. Change the 0 to play another subsong.
        ;
        ;That's all! The music is playing in the background.
        ;To stop it:
        ;call player+3
        ;
        ;BEFORE playing a sound effect, we must initialize them. This must be done only ONCE.
        ;If you don't want any sfx, don't do anything.
        ;call player+6, <sfx address>   (#9000 in this example).
        ;
        ;To play a sound effect:
        ;call player+9, <sfx number>, <channel>, <inverted volume>
        ;The sfx number must be >0.
        ;The channel is 0 (left), 1 (center) or 2 (right).
        ;The inverted volume must be from 0 (full volume) to 16 (mute).
        
        ;To stop a sound effect:
        ;call player+15, <channel>
        ;The channel is 0 to 2.
        ;This stops ANY sound effect on the selected channel. It does NOT stop a SPECIFIC sound effect.
        
        
        ;TESTING = 1     ;Only for developer testing. Comment this!


        IFNDEF TESTING
;The normal case.
                org #9500
                limit #a400
        ELSE
;For testing only.
Music = #7000
Sfx = #9000
Player = #9500
                org Music
                limit Sfx
                include "../../resources/Music_AHarmlessGrenade.asm"
                print "Music end: ", {hex}$
                
                org Sfx
                limit Player
                include "../../resources/SoundEffects.asm"
                print "Sfx end: ", {hex}$

                org Player      ;Should not be too low in Basic (between #2000 and #9500, for example).
                limit #a400     ;Makes sure we don't mess with the system!
        ENDIF                   
        
        
        ;Indirections, called from Basic.
        jp PLY_PlaySong                 ;+0
        jp PLY_StopSong                 ;+3
        jp PLY_InitializeSfxs           ;+6
        jp PLY_PlaySfx                  ;+9
        jp PLY_StopSfx                  ;+12
        
;Plays a song.
;BASIC IN: <music address (IX+2)>, <subsong index (IX+0), also in DE>
PLY_PlaySong:
        ;Gets the music address.
        ld l,(ix + 2)
        ld h,(ix + 3)
        ld (PLY_MusicAddressPtr + 1),hl
        ;Finds the replay frequency. We must reach the subsong for that.
        ;Skips the header.
        ld bc,12
        add hl,bc
        ;What subsong to read? It is in DE.
        ld a,e
        ld (PLY_SubsongIndex + 1),a
        add hl,de
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a                  ;HL = Subsong address.
        ld a,(hl)               ;0=12.5hz, 1=25, 2=50, 3=100, 4=150, 5=300
        ld b,24                 ;12.5hz: play every 4 frames.
        or a
        jr z,.FoundFreq
        ld b,12                 ;25hz: play every 2 frames.
        dec a
        jr z,.FoundFreq
        ld b,6                  ;50hz: play every frame.
        dec a
        jr z,.FoundFreq
        ld b,3                  ;100hz: play twice a frame.
        dec a
        jr z,.FoundFreq
        ld b,2                  ;150hz: play three time a frame.
        dec a
        jr z,.FoundFreq
        ld b,1                  ;300hz: play 6 times a frame.
.FoundFreq
        ld a,b
        ld (PLY_TickCounterOriginal + 1),a
        xor a
        ld (PLY_IsInitialized + 1),a
        inc a
        ld (PLY_TickCounter + 1),a
        
        ;Starts the interruption block.
        ld hl,PLY_InterruptionEventBlock
        ld de,PLY_InterruptionPlay
        ld bc,%10000001 * 256 + 0       ;In RAM (b0), start immediatly (b7).
        jp #bce0
PLY_InterruptionEventBlock: defs 10,0	;Buffer used by the OS.
        
;Called by the OS.
PLY_InterruptionPlay:
        ;Should play something on this tick? 0 if yes.
PLY_TickCounter: ld a,1
        dec a
        jr nz,PLY_PlayFinished
        
        ;Can play the music.
        di              ;Security, the player diverts the stack. The system will put it back.
        ;Some registers must be stored, else the system isn't happy.
        ex af,af'
	exx
	push af
	push bc
	push ix
	push iy
        
        ;Has the music been initialized? If no, do it in now.
PLY_IsInitialized: ld a,0
        or a
        jr nz,PLY_MusicIsInitialized
        inc a
        ld (PLY_IsInitialized + 1),a
        ;Initializes the song.
        ;IN:    HL = music address.
        ;       A = subsong index (>=0).
PLY_MusicAddressPtr: ld hl,0
PLY_SubsongIndex: ld a,0
        call PLY_AKG_Init
        jr PLY_Restore
        
        ;The music is initialized, plays it.
PLY_MusicIsInitialized:        
        call PLY_AKG_Play
   
PLY_Restore:
        pop iy
        pop ix
        pop bc
        pop af
        exx
        ex af,af'
        
PLY_TickCounterOriginal: ld a,0
PLY_PlayFinished:
        ld (PLY_TickCounter + 1),a
        ret



;Stops the song. No need of parameters.        
PLY_StopSong:
        ;Stops the interruption event.
        ld hl,PLY_InterruptionEventBlock
        call #bce6
        
        ld a,255                ;A ruse to prevent the song to be played just after this method. I saw that happening. The timer is killed too late.
        ld (PLY_TickCounter + 1),a

        di                      ;DI/EI mandatory, the players diverts the stack.
        
        ;Stops the sound.
        ex af,af'
	exx
	push af
	push bc
	push ix
	push iy 
        call PLY_AKG_Stop
        pop iy
        pop ix
        pop bc
        pop af
        exx
        ex af,af'
        
        ei
        
        ret
        
         
;Initializes the sound effects. Must be done once, any time, BEFORE using them.
;BASIC IN: DE = sound effects address.
PLY_InitializeSfxs:
        ex de,hl
        jp PLY_AKG_InitSoundEffects     ;No need to saves registers, nothing critical is modified.

;Plays a sound effect.
;BASIC IN: <sfx number (ix + 4)>, <channel (ix + 2)>, <inverted volume (ix + 0, also in DE)>
PLY_PlaySfx:
        ld a,(ix + 4)   ;A = Sound effect number (>0!).
        ld c,(ix + 2)   ;C = The channel where to play the sound effect (0, 1, 2).
        ld b,e          ;B = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
        jp PLY_AKG_PlaySoundEffect     ;No need to saves registers, nothing critical is modified.
        
;Stops a sfx on the selected channel.
;BASIC IN: DE = the channel where to stop the sfx (0-2).
PLY_StopSfx:
        ld a,e          ;A = The channel where to stop the sound effect (0, 1, 2).
        jp PLY_AKG_StopSoundEffectFromChannel     ;No need to saves registers, nothing critical is modified.
      
      
        ;The player, and sfx player.
        PLY_AKG_MANAGE_SOUND_EFFECTS = 1
        include "../../PlayerAkg.asm"
   
   
        print "End: ", {hex}$

;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2025 Targhan/Arkos 
;;  Copyright (C) 2025 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------

.module cpct_audio

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;       Arkos Tracker AKM (Minimalist) player (format V0).
;;       By Targhan/Arkos.
;;       Adapted by Arnaud Bouche for cpctelera
;;
;;       Thanks to Hicks/Vanity for two small (but relevant!) optimizations.
;;       v1.0b:  - Removed the ":" before EQU, for RASM 2.3.9.
;;               - Changed the MSX period table to 1789773 Hz (was 1773400 Hz like Spectrum before).
;;               - Cleaned conditionals when the SFX has hardware sounds, but not the main song, using player configuration (thanks Arnaud!).
;;       v1.0a: 
;;               - To remove hooks, define PLY_AKM_REMOVE_HOOKS (PLY_AKM_REMOVE_HOOKS = 1).
;;               - PLY_AKM_REMOVE_STOP_SOUNDS added (instead of the previously used PLY_AKM_STOP_SOUNDS constant) to remove the snippet to stop the sounds.
;;
;;       This compiles with RASM. Check the compatibility page on the Arkos Tracker 3 website, it contains a source converter to any Z80 assembler!
;;
;;       This is a Minimalist player. Only a subset of the generic player is used. Use this player for 4k demo or other productions
;;       with a tight memory limitation. However, this remains a versatile and powerful player, so it may fit any production!
;;
;;       Though the player is optimized in speed, it is much slower than the generic one or the AKY player.
;;       With effects used at the same time, it can reach 45 scanlines on a CPC, plus some few more if you are using sound effects.
;;       So it's slightly faster than the Soundtrakker 128 player, but smaller and more powerful (so what are you complaining about?).
;;
;;       The player uses the stack for optimizations. Make sure the interruptions are disabled before it is called.
;;       The stack pointer is saved at the beginning and restored at the end.
;;
;;       Target hardware:
;;       ---------------
;;       This code can target Amstrad CPC, MSX, Spectrum and Pentagon. By default, it targets Amstrad CPC.
;;       Simply use one of the follow line (BEFORE this player):
;;       PLY_AKM_HARDWARE_CPC = 1
;;       PLY_AKM_HARDWARE_MSX = 1
;;       PLY_AKM_HARDWARE_SPECTRUM = 1
;;       PLY_AKM_HARDWARE_PENTAGON = 1
;;       Note that the PRESENCE of this variable is tested, NOT its value.

;;       Optimizations
;;       -------------
;;       - Use the Player Configuration of Arkos Tracker to generate a configuration file to be included at the beginning of this player.
;;         It will disable useless features according to your songs! Check the manual for more details, or more simply the testers.
;;       - SIZE: Hooks for external calls (play/init) are present by default. Define PLY_AKM_REMOVE_HOOKS to remove them (PLY_AKM_REMOVE_HOOKS = 1).
;;       - SIZE: Define PLY_AKM_REMOVE_STOP_SOUNDS to remove the Stop sound method (PLY_AKM_Stop) if you don't intend on stopping the music.

;;       Sound effects:
;;       --------------
;;       Sound effects are disabled by default. Declare PLY_AKM_MANAGE_SOUND_EFFECTS to enable it:
;;       PLY_AKM_MANAGE_SOUND_EFFECTS = 1
;;       Check the sound effect tester to see how it enables it.
;;       Note that the PRESENCE of this variable is tested, NOT its value.
;;
;;       ROM
;;       ----------------------
;;       To use a ROM player (no automodification, use of a small buffer to put in RAM):
;;       PLY_AKM_Rom = 1
;;       PLY_AKM_ROM_Buffer = #4000 (or wherever).
;;       This makes the player a bit slower and slightly bigger.
;;       The buffer is PLY_AKM_ROM_BufferSize bytes long (199 bytes max, 273 if using sound effects).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLY_AKM_OFFSET1B = .+1
PLY_AKM_DATA_OFFSETTRANSPOSITION = .+1
PLY_AKM_REGISTERS_OFFSETVOLUME = .+1
RASM_VERSION = .+2
PLY_AKM_SOUNDEFFECTDATA_OFFSETINVERTEDVOLUME = .+2
PLY_AKM_OFFSET2B = .+2
PLY_AKM_DATA_OFFSETPTSTARTTRACK = .+2
PLY_AKM_START:
PLY_AKM_DATA_OFFSETWAITEMPTYCELL: jp cpct_PLY_AKM_Init
PLY_AKM_SOUNDEFFECTDATA_OFFSETSPEED = .+1
PLY_AKM_DATA_OFFSETPTTRACK = .+1
PLY_AKM_REGISTERS_OFFSETSOFTWAREPERIODLSB = .+2
PLY_AKM_SOUNDEFFECTDATA_OFFSETCURRENTSTEP: jp cpct_PLY_AKM_Play
PLY_AKM_DATA_OFFSETESCAPENOTE = .+1
PLY_AKM_CHANNEL_SOUNDEFFECTDATASIZE = .+2
PLY_AKM_DATA_OFFSETESCAPEINSTRUMENT = .+2
PLY_AKM_DATA_OFFSETBASENOTE: jp PLY_AKM_INITVARS_END
PLY_AKM_DATA_OFFSETPTINSTRUMENT = .+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKM_InitSoundEffects
;;
;; Initializes the sound effects. It MUST be called at any times before a first sound effect is triggered.
;; It doesn't matter whether the song is playing or not, or if it has been initialized or not.
;;
;; C Definition:
;;    void cpct_PLY_AKM_InitSoundEffects(void* sfx_song_data) __z88dk_fastcall
;;
;; Input Parameters (2 bytes):
;;    (2B  HL) sfx_song_data  - Address to the sound effects data.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKM_InitSoundEffects_asm
;;
;; Destroyed Register values: 
;;      -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_PLY_AKM_InitSoundEffects::
;; CPCtelera according __z88dk_fastcall convention
;; HL = sfx_song_data 
cpct_PLY_AKM_InitSoundEffects:
cpct_PLY_AKM_InitSoundEffects_asm:
PLY_AKM_DATA_OFFSETESCAPEWAIT:
PLY_AKM_DATA_OFFSETSECONDARYINSTRUMENT:
PLY_AKM_REGISTERS_OFFSETSOFTWAREPERIODMSB: ld (PLY_AKM_DATA_OFFSETTRACKPITCHSPEED),hl
PLY_AKM_DATA_OFFSETINSTRUMENTCURRENTSTEP: ret 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKM_PlaySoundEffect
;;
;; Plays a sound effect. If a previous one was already playing on the same channel, it is replaced.
;; This does not actually plays the sound effect, but programs its playing.
;; The music player, when called, will call the PLY_AKG_PlaySoundEffectsStream method below.
;;
;; C Definition:
;;    void cpct_PLY_AKM_PlaySoundEffect(u8 sfx_num, u8 channel, u16 volume) __z88dk_callee;
;;
;; Input Parameters (3 bytes):
;;    (1B A) = Sound effect number (>0!).
;;    (1B C) = The channel where to play the sound effect (0, 1, 2) 
;;    (1B B) = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKM_PlaySoundEffect_asm
;;
;; Destroyed Register values: 
;;      AF', AF, BC, DE, HL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_cpct_PLY_AKM_PlaySoundEffect::
cpct_PLY_AKM_PlaySoundEffect:
;; According __sdcccall(1) and __z88dk_callee convention
;; A = Sound effect number (>0!)
;; L = The channel where to play the sound effect (0, 1, 2).
        ld c,l
        pop hl
        ex (sp),hl ;; HL <-> SP Inverted volume
        ld b,l     ;; B = L Inverted volume
cpct_PLY_AKM_PlaySoundEffect_asm: 
        ;Gets the address to the sound effect.
        dec a
PLY_AKM_DATA_OFFSETTRACKPITCHSPEED = .+1
PLY_AKM_PTSOUNDEFFECTTABLE:
PLY_AKM_DATA_OFFSETTRACKPITCHDECIMAL: ld hl,#0
PLY_AKM_DATA_OFFSETISARPEGGIOTABLEUSED: ld e,a
PLY_AKM_DATA_OFFSETPTARPEGGIOTABLE: ld d,#0
PLY_AKM_DATA_OFFSETPTARPEGGIOOFFSET: add hl,de
PLY_AKM_DATA_OFFSETARPEGGIOCURRENTSTEP: add hl,de
PLY_AKM_DATA_OFFSETARPEGGIOCURRENTSPEED: ld e,(hl)
PLY_AKM_DATA_OFFSETARPEGGIOORIGINALSPEED: inc hl
PLY_AKM_DATA_OFFSETCURRENTARPEGGIOVALUE: ld d,(hl)
PLY_AKM_DATA_OFFSETISPITCHTABLEUSED: ld a,(de)
PLY_AKM_DATA_OFFSETPTPITCHTABLE: inc de
    ex af,af'
PLY_AKM_DATA_OFFSETPTPITCHOFFSET: ld a,b
PLY_AKM_DATA_OFFSETPITCHCURRENTSPEED = .+1
PLY_AKM_DATA_OFFSETPITCHORIGINALSPEED = .+2
PLY_AKM_DATA_OFFSETPITCHCURRENTSTEP: ld hl,#PLY_AKM_CHANNEL1_SOUNDEFFECTDATA
PLY_AKM_DATA_OFFSETCURRENTPITCHTABLEVALUE: ld b,#0
PLY_AKM_TRACK1_DATA_SIZE: sla c
    sla c
    sla c
    add hl,bc
    ld (hl),e
    inc hl
    ld (hl),d
    inc hl
    ld (hl),a
    inc hl
    ld (hl),#0
    inc hl
    ex af,af'
    ld (hl),a
    ret 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKM_StopSoundEffectFromChannel
;;
;; Stops a sound effect. Nothing happens if there was no sound effect.
;;
;; C Definition:
;;    void cpct_PLY_AKM_StopSoundEffectFromChannel(u8 channel) __z88dk_fastcall;
;;
;; Input Parameters (1 bytes):
;;    (1B A) = Channel number.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKM_StopSoundEffectFromChannel_asm
;;
;; Destroyed Register values: 
;;      AF, DE, HL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
_PLY_AKM_StopSoundEffectFromChannel::
;; CPCtelera according __z88dk_fastcall convention
;; A = Channel
PLY_AKM_StopSoundEffectFromChannel:
PLY_AKM_StopSoundEffectFromChannel_asm: 
    add a,a
    add a,a
    add a,a
    ld e,a
    ld d,#0
    ld hl,#PLY_AKM_CHANNEL1_SOUNDEFFECTDATA
    add hl,de
    ld (hl),d
    inc hl
    ld (hl),d
    ret 
;Plays the sound effects, if any has been triggered by the user.
;This does not actually send registers to the PSG, it only overwrite the required values of the registers of the player.
;The sound effects initialization method must have been called before!
;As R7 is required, this must be called after the music has been played, but BEFORE the registers are sent to the PSG.
;IN:    A = R7.	
PLY_AKM_PLAYSOUNDEFFECTSSTREAM: rla 
    rla 
    ld ix,#PLY_AKM_CHANNEL1_SOUNDEFFECTDATA
    ld iy,#PLY_AKM_TRACK3_DATA_END
    ld c,a
    call PLY_AKM_PSES_PLAY
    ld ix,#PLY_AKM_CHANNEL2_SOUNDEFFECTDATA
    ld iy,#PLY_AKM_TRACK2_REGISTERS
    srl c
    call PLY_AKM_PSES_PLAY
    ld ix,#PLY_AKM_CHANNEL3_SOUNDEFFECTDATA
    ld iy,#PLY_AKM_TRACK3_REGISTERS
    rr c
    call PLY_AKM_PSES_PLAY
    ld a,c
    ld (PLY_AKM_MIXERREGISTER),a
    ret 
PLY_AKM_PSES_PLAY: ld l,+0(ix)
    ld h,+1(ix)
    ld a,l
    or h
    ret z
PLY_AKM_PSES_READFIRSTBYTE: ld a,(hl)
    inc hl
    ld b,a
    rra 
    jr c,PLY_AKM_PSES_SOFTWAREORSOFTWAREANDHARDWARE
    rra 
    jr c,PLY_AKM_PSES_HARDWAREONLY
    rra 
    jr c,PLY_AKM_PSES_S_ENDORLOOP
    call PLY_AKM_PSES_MANAGEVOLUMEFROMA_FILTER4BITS
    rl b
    call PLY_AKM_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    set 2,c
    jr PLY_AKM_PSES_SAVEPOINTERANDEXIT
PLY_AKM_PSES_S_ENDORLOOP: rra 
    jr c,PLY_AKM_PSES_S_LOOP
    xor a
    ld +0(ix),a
    ld +1(ix),a
    ret 
PLY_AKM_PSES_S_LOOP: ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    jr PLY_AKM_PSES_READFIRSTBYTE
PLY_AKM_PSES_SAVEPOINTERANDEXIT: ld a,+3(ix)
    cp +4(ix)
    jr c,PLY_AKM_PSES_NOTREACHED
    ld +3(ix),#0
    .db 221
    .db 117
    .db 0
    .db 221
    .db 116
    .db 1
    ret 
PLY_AKM_PSES_NOTREACHED: inc +3(ix)
    ret 
PLY_AKM_PSES_HARDWAREONLY: call PLY_AKM_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE
    set 2,c
    jr PLY_AKM_PSES_SAVEPOINTERANDEXIT
PLY_AKM_PSES_SOFTWAREORSOFTWAREANDHARDWARE: rra 
    jr c,PLY_AKM_PSES_SOFTWAREANDHARDWARE
    call PLY_AKM_PSES_MANAGEVOLUMEFROMA_FILTER4BITS
    rl b
    call PLY_AKM_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    res 2,c
    call PLY_AKM_PSES_READSOFTWAREPERIOD
    jr PLY_AKM_PSES_SAVEPOINTERANDEXIT
PLY_AKM_PSES_SOFTWAREANDHARDWARE: call PLY_AKM_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE
    call PLY_AKM_PSES_READSOFTWAREPERIOD
    res 2,c
    jr PLY_AKM_PSES_SAVEPOINTERANDEXIT
PLY_AKM_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE: rra 
    jr nc,PLY_AKM_PSES_H_AFTERRETRIG
    ld d,a
    ld a,#255
    ld (PLY_AKM_SETREG13OLD+1),a
    ld a,d
PLY_AKM_PSES_H_AFTERRETRIG: and #7
    add a,#8
    ld (PLY_AKM_SENDPSGREGISTERR13+1),a
    rl b
    call PLY_AKM_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    call PLY_AKM_PSES_READHARDWAREPERIOD
    ld a,#16
    jp PLY_AKM_PSES_MANAGEVOLUMEFROMA_HARD
PLY_AKM_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL: jr c,PLY_AKM_PSES_READNOISEANDOPENNOISECHANNEL_OPENNOISE
SYNCHRO: set 5,c
    ret 
PLY_AKM_PSES_READNOISEANDOPENNOISECHANNEL_OPENNOISE: ld a,(hl)
    ld (PLY_AKM_NOISEREGISTER),a
    inc hl
    res 5,c
    ret 
PLY_AKM_PSES_READHARDWAREPERIOD: ld a,(hl)
    ld (PLY_AKM_REG11),a
    inc hl
    ld a,(hl)
    ld (PLY_AKM_REG12),a
    inc hl
    ret 
PLY_AKM_PSES_READSOFTWAREPERIOD: ld a,(hl)
    ld +5(iy),a
    inc hl
    ld a,(hl)
    ld +9(iy),a
    inc hl
    ret 
PLY_AKM_PSES_MANAGEVOLUMEFROMA_FILTER4BITS: and #15
PLY_AKM_PSES_MANAGEVOLUMEFROMA_HARD: sub +2(ix)
    jr nc,PLY_AKM_PSES_MVFA_NOOVERFLOW
    xor a
PLY_AKM_PSES_MVFA_NOOVERFLOW: ld +1(iy),a
    ret 
PLY_AKM_CHANNEL1_SOUNDEFFECTDATA: .dw 0
PLY_AKM_CHANNEL1_SOUNDEFFECTINVERTEDVOLUME: .db 0
PLY_AKM_CHANNEL1_SOUNDEFFECTCURRENTSTEP: .db 0
PLY_AKM_CHANNEL1_SOUNDEFFECTSPEED: .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_CHANNEL2_SOUNDEFFECTDATA: .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_CHANNEL3_SOUNDEFFECTDATA: .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_Init
;;
;; Initializes the player.
;;
;; C Definition:
;;    void cpct_PLY_AKM_Init(void* songdata, u16 subSong) __z88dk_callee;
;;
;; Input Parameters (3 bytes):
;;    (2B HL) = Song data
;;    (1B A)  = Subsong index
;;    
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_Init_asm
;;
;; Destroyed Register values: 
;;     -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

_cpct_PLY_AKM_Init::
;; CPCTelera according __sdcccall(1) and __z88dk_callee convention
;; HL = Address of the song
;; DE = D useless  / E  = Subsong index (>=0)
cpct_PLY_AKM_Init: 
    ld   a, e        ;; A = Subsong index
cpct_PLY_AKM_Init_asm: 
    ld de,#PLY_AKM_READLINE+1
    ldi
    ldi
    ld de,#PLY_AKM_PTARPEGGIOS+1
    ldi
    ldi
    ld de,#PLY_AKM_PTPITCHES+1
    ldi
    ldi
    add a,a
    ld e,a
    ld d,#0
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld ix,#PLY_AKM_INITVARS_START
    ld a,#13
PLY_AKM_INITVARS_LOOP: ld e,+0(ix)
    ld d,+1(ix)
    inc ix
    inc ix
    ldi
    dec a
    jr nz,PLY_AKM_INITVARS_LOOP
    ld (PLY_AKM_PATTERNREMAININGHEIGHT+1),a
    ex de,hl
    ld hl,#PLY_AKM_PTLINKER+1
    ld (hl),e
    inc hl
    ld (hl),d
    ld hl,#PLY_AKM_TRACK1_DATA
    ld de,#PLY_AKM_TRACK1_TRANSPOSITION
    ld bc,#113
    ld (hl),a
    ldir
    ld (PLY_AKM_RT_READEFFECTSFLAG+1),a
    ld a,(PLY_AKM_SPEED+1)
    dec a
    ld (PLY_AKM_TICKCOUNTER+1),a
    ld hl,(PLY_AKM_READLINE+1)
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc de
    ld (PLY_AKM_TRACK1_PTINSTRUMENT),de
    ld (PLY_AKM_TRACK2_PTINSTRUMENT),de
    ld (PLY_AKM_TRACK3_PTINSTRUMENT),de
    ld hl,#0
    ld (PLY_AKM_CHANNEL1_SOUNDEFFECTDATA),hl
    ld (PLY_AKM_CHANNEL2_SOUNDEFFECTDATA),hl
    ld (PLY_AKM_CHANNEL3_SOUNDEFFECTDATA),hl
    ret 
PLY_AKM_INITVARS_START: .dw PLY_AKM_NOTEINDEXTABLE+1
    .dw PLY_AKM_NOTEINDEXTABLE+2
    .dw PLY_AKM_LINKER+1
    .dw PLY_AKM_LINKER+2
    .dw PLY_AKM_SPEED+1
    .dw PLY_AKM_RT_PRIMARYINSTRUMENT+1
    .dw PLY_AKM_RT_SECONDARYINSTRUMENT+1
    .dw PLY_AKM_RT_PRIMARYWAIT+1
    .dw PLY_AKM_RT_SECONDARYWAIT+1
    .dw PLY_AKM_DEFAULTSTARTNOTEINTRACKS+1
    .dw PLY_AKM_DEFAULTSTARTINSTRUMENTINTRACKS+1
    .dw PLY_AKM_DEFAULTSTARTWAITINTRACKS+1
    .dw PLY_AKM_FLAGNOTEANDEFFECTINCELL+1
PLY_AKM_INITVARS_END:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_Stop
;;
;; Stops the music. This code can be removed if you don't intend to stop it!
;;
;; C Definition:
;;    void cpct_PLY_AKG_Stop(void);
;;
;; Input Parameters (0 bytes):
;;    
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_Stop_asm
;;
;; Destroyed Register values: 
;;     -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_PLY_AKM_Stop::
cpct_PLY_AKM_Stop:
cpct_PLY_AKM_Stop_asm: 
    ld (PLY_AKM_SENDPSGREGISTEREND+1),sp
    xor a
    ld (PLY_AKM_TRACK1_VOLUME),a
    ld (PLY_AKM_TRACK2_VOLUME),a
    ld (PLY_AKM_TRACK3_VOLUME),a
    ld a,#63
    ld (PLY_AKM_MIXERREGISTER),a
    jp PLY_AKM_SENDPSG

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKM_Play
;;
;; Plays one frame of the song. It MUST have been initialized before.
;; The stack is saved and restored, but is diverted, so watch out for the interruptions.	
;;
;; C Definition:
;;    void cpct_PLY_AKM_Play(void);
;;
;; Input Parameters (0 bytes):
;;    
;; Assembly call (Input parameters on registers):
;;    > call Pcpct_PLY_AKM_Play_asm
;;
;; Destroyed Register values: 
;;     -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
_cpct_PLY_AKM_Play::
cpct_PLY_AKM_Play:
cpct_PLY_AKM_Play_asm: 
    ld (PLY_AKM_SENDPSGREGISTEREND+1),sp
PLY_AKM_TICKCOUNTER: ld a,#0
    inc a
PLY_AKM_SPEED: cp #1
    jp nz,PLY_AKM_TICKCOUNTERMANAGED
PLY_AKM_PATTERNREMAININGHEIGHT: ld a,#0
    sub #1
    jr c,PLY_AKM_LINKER
    ld (PLY_AKM_PATTERNREMAININGHEIGHT+1),a
    jr PLY_AKM_READLINE
PLY_AKM_LINKER:
PLY_AKM_TRACKINDEX: ld de,#0
    exx
PLY_AKM_PTLINKER: ld hl,#0
PLY_AKM_LINKERPOSTPT: xor a
    ld (PLY_AKM_TRACK1_DATA),a
    ld (PLY_AKM_TRACK1_DATA_END),a
    ld (PLY_AKM_TRACK2_DATA_END),a
PLY_AKM_DEFAULTSTARTNOTEINTRACKS: ld a,#0
    ld (PLY_AKM_TRACK1_ESCAPENOTE),a
    ld (PLY_AKM_TRACK2_ESCAPENOTE),a
    ld (PLY_AKM_TRACK3_ESCAPENOTE),a
PLY_AKM_DEFAULTSTARTINSTRUMENTINTRACKS: ld a,#0
    ld (PLY_AKM_TRACK1_ESCAPEINSTRUMENT),a
    ld (PLY_AKM_TRACK2_ESCAPEINSTRUMENT),a
    ld (PLY_AKM_TRACK3_ESCAPEINSTRUMENT),a
PLY_AKM_DEFAULTSTARTWAITINTRACKS: ld a,#0
    ld (PLY_AKM_TRACK1_ESCAPEWAIT),a
    ld (PLY_AKM_TRACK2_ESCAPEWAIT),a
    ld (PLY_AKM_TRACK3_ESCAPEWAIT),a
    ld b,(hl)
    inc hl
    rr b
    jr nc,PLY_AKM_LINKERAFTERSPEEDCHANGE
    ld a,(hl)
    inc hl
    or a
    jr nz,PLY_AKM_LINKERSPEEDCHANGE
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    jr PLY_AKM_LINKERPOSTPT
PLY_AKM_LINKERSPEEDCHANGE: ld (PLY_AKM_SPEED+1),a
PLY_AKM_LINKERAFTERSPEEDCHANGE: rr b
    jr nc,PLY_AKM_LINKERUSEPREVIOUSHEIGHT
    ld a,(hl)
    inc hl
    ld (PLY_AKM_LINKERUSEPREVIOUSHEIGHT+1),a
    jr PLY_AKM_LINKERSETREMAININGHEIGHT
PLY_AKM_LINKERUSEPREVIOUSHEIGHT:
PLY_AKM_LINKERPREVIOUSREMAININGHEIGHT: ld a,#0
PLY_AKM_LINKERSETREMAININGHEIGHT: ld (PLY_AKM_PATTERNREMAININGHEIGHT+1),a
    ld ix,#PLY_AKM_TRACK1_DATA
    call PLY_AKM_CHECKTRANSPOSITIONANDTRACK
    ld ix,#PLY_AKM_TRACK1_DATA_END
    call PLY_AKM_CHECKTRANSPOSITIONANDTRACK
    ld ix,#PLY_AKM_TRACK2_DATA_END
    call PLY_AKM_CHECKTRANSPOSITIONANDTRACK
    ld (PLY_AKM_PTLINKER+1),hl
PLY_AKM_READLINE:
PLY_AKM_PTINSTRUMENTS: ld de,#0
PLY_AKM_NOTEINDEXTABLE: ld bc,#0
    exx
    ld ix,#PLY_AKM_TRACK1_DATA
    call PLY_AKM_READTRACK
    ld ix,#PLY_AKM_TRACK1_DATA_END
    call PLY_AKM_READTRACK
    ld ix,#PLY_AKM_TRACK2_DATA_END
    call PLY_AKM_READTRACK
    xor a
PLY_AKM_TICKCOUNTERMANAGED: ld (PLY_AKM_TICKCOUNTER+1),a
    ld de,#PLY_AKM_PERIODTABLE
    exx
    ld c,#224
    ld ix,#PLY_AKM_TRACK1_DATA
    call PLY_AKM_MANAGEEFFECTS
    ld iy,#PLY_AKM_TRACK3_DATA_END
    call PLY_AKM_PLAYSOUNDSTREAM
    srl c
    ld ix,#PLY_AKM_TRACK1_DATA_END
    call PLY_AKM_MANAGEEFFECTS
    ld iy,#PLY_AKM_TRACK2_REGISTERS
    call PLY_AKM_PLAYSOUNDSTREAM
    rr c
    ld ix,#PLY_AKM_TRACK2_DATA_END
    call PLY_AKM_MANAGEEFFECTS
    ld iy,#PLY_AKM_TRACK3_REGISTERS
    call PLY_AKM_PLAYSOUNDSTREAM
    ld a,c
    call PLY_AKM_PLAYSOUNDEFFECTSSTREAM
PLY_AKM_SENDPSG: ld sp,#PLY_AKM_TRACK3_DATA_END
    ld bc,#63104
    ld a,#192
    ld de,#62710
    out (c),a
PLY_AKM_SENDPSGREGISTER: pop hl
PLY_AKM_SENDPSGREGISTERAFTERPOP: ld b,d
    out (c),l
    ld b,e
    .db 237
    .db 113
    ld b,d
    out (c),h
    ld b,e
    out (c),c
    out (c),a
    ret 
PLY_AKM_SENDPSGREGISTERR13:
PLY_AKM_SETREG13: ld a,#0
PLY_AKM_SETREG13OLD: cp #0
    jr z,PLY_AKM_SENDPSGREGISTEREND
    ld (PLY_AKM_SETREG13OLD+1),a
    ld h,a
    ld l,#13
    ld a,#192
    ret 
PLY_AKM_SENDPSGREGISTEREND:
PLY_AKM_SAVESP: ld sp,#0
    ret 
PLY_AKM_CHECKTRANSPOSITIONANDTRACK: rr b
    jr nc,PLY_AKM_CHECKTRANSPOSITIONANDTRACK_AFTERTRANSPOSITION
    ld a,(hl)
    ld +1(ix),a
    inc hl
PLY_AKM_CHECKTRANSPOSITIONANDTRACK_AFTERTRANSPOSITION: rr b
    jr nc,PLY_AKM_CHECKTRANSPOSITIONANDTRACK_NONEWTRACK
    ld a,(hl)
    inc hl
    sla a
    jr nc,PLY_AKM_CHECKTRANSPOSITIONANDTRACK_TRACKOFFSET
    exx
    ld l,a
    ld h,#0
    add hl,de
    ld a,(hl)
    ld +2(ix),a
    ld +4(ix),a
    inc hl
    ld a,(hl)
    ld +3(ix),a
    ld +5(ix),a
    exx
    ret 
PLY_AKM_CHECKTRANSPOSITIONANDTRACK_TRACKOFFSET: rra 
    ld d,a
    ld e,(hl)
    inc hl
    ld c,l
    ld a,h
    add hl,de
    .db 221
    .db 117
    .db 2
    .db 221
    .db 116
    .db 3
    .db 221
    .db 117
    .db 4
    .db 221
    .db 116
    .db 5
    ld l,c
    ld h,a
    ret 
PLY_AKM_CHECKTRANSPOSITIONANDTRACK_NONEWTRACK: ld a,+2(ix)
    ld +4(ix),a
    ld a,+3(ix)
    ld +5(ix),a
    ret 
PLY_AKM_READTRACK: ld a,+0(ix)
    sub #1
    jr c,PLY_AKM_RT_NOEMPTYCELL
    ld +0(ix),a
    ret 
PLY_AKM_RT_NOEMPTYCELL: ld l,+4(ix)
    ld h,+5(ix)
PLY_AKM_RT_GETDATABYTE: ld b,(hl)
    inc hl
    ld a,b
    and #15
PLY_AKM_FLAGNOTEANDEFFECTINCELL: cp #12
    jr c,PLY_AKM_RT_NOTEREFERENCE
    sub #12
    jr z,PLY_AKM_RT_NOTEANDEFFECTS
    dec a
    jr z,PLY_AKM_RT_NONOTEMAYBEEFFECTS
    dec a
    jr z,PLY_AKM_RT_NEWESCAPENOTE
    ld a,+7(ix)
    jr PLY_AKM_RT_AFTERNOTEREAD
PLY_AKM_RT_NEWESCAPENOTE: ld a,(hl)
    ld +7(ix),a
    inc hl
    jr PLY_AKM_RT_AFTERNOTEREAD
PLY_AKM_RT_NOTEANDEFFECTS: dec a
    ld (PLY_AKM_RT_READEFFECTSFLAG+1),a
    jr PLY_AKM_RT_GETDATABYTE
PLY_AKM_RT_NONOTEMAYBEEFFECTS: bit 4,b
    jr z,PLY_AKM_RT_READWAITFLAGS
    ld a,b
    ld (PLY_AKM_RT_READEFFECTSFLAG+1),a
    jr PLY_AKM_RT_READWAITFLAGS
PLY_AKM_RT_NOTEREFERENCE: exx
    ld l,a
    ld h,#0
    add hl,bc
    ld a,(hl)
    exx
PLY_AKM_RT_AFTERNOTEREAD: add a,+1(ix)
    ld +6(ix),a
    ld a,b
    and #48
    jr z,PLY_AKM_RT_SAMEESCAPEINSTRUMENT
    cp #16
    jr z,PLY_AKM_RT_PRIMARYINSTRUMENT
    cp #32
    jr z,PLY_AKM_RT_SECONDARYINSTRUMENT
    ld a,(hl)
    inc hl
    ld +8(ix),a
    jr PLY_AKM_RT_STORECURRENTINSTRUMENT
PLY_AKM_RT_SAMEESCAPEINSTRUMENT: ld a,+8(ix)
    jr PLY_AKM_RT_STORECURRENTINSTRUMENT
PLY_AKM_RT_SECONDARYINSTRUMENT:
PLY_AKM_SECONDARYINSTRUMENT: ld a,#0
    jr PLY_AKM_RT_STORECURRENTINSTRUMENT
PLY_AKM_RT_PRIMARYINSTRUMENT:
PLY_AKM_PRIMARYINSTRUMENT: ld a,#0
PLY_AKM_RT_STORECURRENTINSTRUMENT: exx
    add a,a
    ld l,a
    ld h,#0
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
    inc hl
    ld +13(ix),a
    .db 221
    .db 117
    .db 10
    .db 221
    .db 116
    .db 11
    exx
    xor a
    ld +12(ix),a
    ld +15(ix),a
    ld +16(ix),a
    ld +17(ix),a
    ld +24(ix),a
    ld +25(ix),a
    ld a,+27(ix)
    ld +26(ix),a
    ld +32(ix),a
    ld +33(ix),a
    ld a,+35(ix)
    ld +34(ix),a
PLY_AKM_RT_READWAITFLAGS: ld a,b
    and #192
    jr z,PLY_AKM_RT_SAMEESCAPEWAIT
    cp #64
    jr z,PLY_AKM_RT_PRIMARYWAIT
    cp #128
    jr z,PLY_AKM_RT_SECONDARYWAIT
    ld a,(hl)
    inc hl
    ld +9(ix),a
    jr PLY_AKM_RT_STORECURRENTWAIT
PLY_AKM_RT_SAMEESCAPEWAIT: ld a,+9(ix)
    jr PLY_AKM_RT_STORECURRENTWAIT
PLY_AKM_RT_PRIMARYWAIT:
PLY_AKM_PRIMARYWAIT: ld a,#0
    jr PLY_AKM_RT_STORECURRENTWAIT
PLY_AKM_RT_SECONDARYWAIT:
PLY_AKM_SECONDARYWAIT: ld a,#0
PLY_AKM_RT_STORECURRENTWAIT: ld +0(ix),a
PLY_AKM_RT_READEFFECTSFLAG: ld a,#0
    or a
    jr nz,PLY_AKM_RT_READEFFECTS
PLY_AKM_RT_AFTEREFFECTS: .db 221
    .db 117
    .db 4
    .db 221
    .db 116
    .db 5
    ret 
PLY_AKM_RT_READEFFECTS: xor a
    ld (PLY_AKM_RT_READEFFECTSFLAG+1),a
PLY_AKM_RT_READEFFECT: ld iy,#PLY_AKM_EFFECTTABLE
    ld b,(hl)
    ld a,b
    inc hl
    and #14
    ld e,a
    ld d,#0
    add iy,de
    ld a,b
    rra 
    rra 
    rra 
    rra 
    and #15
    jp (iy)
PLY_AKM_RT_READEFFECT_RETURN: bit 0,b
    jr nz,PLY_AKM_RT_READEFFECT
    jr PLY_AKM_RT_AFTEREFFECTS
PLY_AKM_RT_WAITLONG: ld a,(hl)
    inc hl
    ld +0(ix),a
    jr PLY_AKM_RT_CELLREAD
PLY_AKM_RT_WAITSHORT: ld a,b
    rlca 
    rlca 
    and #3
    ld +0(ix),a
PLY_AKM_RT_CELLREAD: .db 221
    .db 117
    .db 4
    .db 221
    .db 116
    .db 5
    ret 
PLY_AKM_MANAGEEFFECTS: ld a,+15(ix)
    or a
    jr z,PLY_AKM_ME_PITCHUPDOWNFINISHED
    ld l,+18(ix)
    ld h,+16(ix)
    ld e,+19(ix)
    ld d,+20(ix)
    ld a,+17(ix)
    bit 7,d
    jr nz,PLY_AKM_ME_PITCHUPDOWN_NEGATIVESPEED
PLY_AKM_ME_PITCHUPDOWN_POSITIVESPEED: add hl,de
    adc a,#0
    jr PLY_AKM_ME_PITCHUPDOWN_SAVE
PLY_AKM_ME_PITCHUPDOWN_NEGATIVESPEED: res 7,d
    or a
    sbc hl,de
    sbc a,#0
PLY_AKM_ME_PITCHUPDOWN_SAVE: ld +17(ix),a
    .db 221
    .db 117
    .db 18
    .db 221
    .db 116
    .db 16
PLY_AKM_ME_PITCHUPDOWNFINISHED: ld a,+21(ix)
    or a
    jr z,PLY_AKM_ME_ARPEGGIOTABLEFINISHED
    ld e,+22(ix)
    ld d,+23(ix)
    ld l,+24(ix)
    ld h,#0
    add hl,de
    ld a,(hl)
    sra a
    ld +28(ix),a
    ld a,+25(ix)
    cp +26(ix)
    jr c,PLY_AKM_ME_ARPEGGIOTABLE_SPEEDNOTREACHED
    ld +25(ix),#0
    inc +24(ix)
    inc hl
    ld a,(hl)
    rra 
    jr nc,PLY_AKM_ME_ARPEGGIOTABLEFINISHED
    ld l,a
    ld +24(ix),a
    jr PLY_AKM_ME_ARPEGGIOTABLEFINISHED
PLY_AKM_ME_ARPEGGIOTABLE_SPEEDNOTREACHED: inc a
    ld +25(ix),a
PLY_AKM_ME_ARPEGGIOTABLEFINISHED: ld a,+29(ix)
    or a
    ret z
    ld l,+30(ix)
    ld h,+31(ix)
    ld e,+32(ix)
    ld d,#0
    add hl,de
    ld a,(hl)
    sra a
    jp p,PLY_AKM_ME_PITCHTABLEENDNOTREACHED_POSITIVE
    dec d
PLY_AKM_ME_PITCHTABLEENDNOTREACHED_POSITIVE: ld +36(ix),a
    .db 221
    .db 114
    .db 37
    ld a,+33(ix)
    cp +34(ix)
    jr c,PLY_AKM_ME_PITCHTABLE_SPEEDNOTREACHED
    ld +33(ix),#0
    inc +32(ix)
    inc hl
    ld a,(hl)
    rra 
    ret nc
    ld l,a
    ld +32(ix),a
    ret 
PLY_AKM_ME_PITCHTABLE_SPEEDNOTREACHED: inc a
    ld +33(ix),a
    ret 
PLY_AKM_PLAYSOUNDSTREAM: ld l,+10(ix)
    ld h,+11(ix)
PLY_AKM_PSS_READFIRSTBYTE: ld a,(hl)
    ld b,a
    inc hl
    rra 
    jr c,PLY_AKM_PSS_SOFTORSOFTANDHARD
    rra 
    jr c,PLY_AKM_PSS_SOFTWARETOHARDWARE
    rra 
    jr nc,PLY_AKM_PSS_NSNH_NOTENDOFSOUND
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    .db 221
    .db 117
    .db 10
    .db 221
    .db 116
    .db 11
    jr PLY_AKM_PSS_READFIRSTBYTE
PLY_AKM_PSS_NSNH_NOTENDOFSOUND: set 2,c
    call PLY_AKM_PSS_SHARED_ADJUSTVOLUME
    ld +1(iy),a
    rl b
    call c,PLY_AKM_PSS_READNOISE
    jr PLY_AKM_PSS_SHARED_STOREINSTRUMENTPOINTER
PLY_AKM_PSS_SOFTORSOFTANDHARD: rra 
    jr c,PLY_AKM_PSS_SOFTANDHARD
    call PLY_AKM_PSS_SHARED_ADJUSTVOLUME
    ld +1(iy),a
    ld d,#0
    rl b
    jr nc,PLY_AKM_PSS_S_AFTERARPANDORNOISE
    ld a,(hl)
    inc hl
    sra a
    ld d,a
    call c,PLY_AKM_PSS_READNOISE
PLY_AKM_PSS_S_AFTERARPANDORNOISE: ld a,d
    call PLY_AKM_CALCULATEPERIODFORBASENOTE
    rl b
    call c,PLY_AKM_READPITCHANDADDTOPERIOD
    exx
    ld +5(iy),l
    ld +9(iy),h
    exx
PLY_AKM_PSS_SHARED_STOREINSTRUMENTPOINTER: ld a,+12(ix)
    cp +13(ix)
    jr nc,PLY_AKM_PSS_S_SPEEDREACHED
    inc +12(ix)
    ret 
PLY_AKM_PSS_S_SPEEDREACHED: .db 221
    .db 117
    .db 10
    .db 221
    .db 116
    .db 11
    ld +12(ix),#0
    ret 
PLY_AKM_PSS_SOFTANDHARD: call PLY_AKM_PSS_SHARED_READENVBITPITCHARP_SOFTPERIOD_HARDVOL_HARDENV
    ld a,(hl)
    ld (PLY_AKM_REG11),a
    inc hl
    ld a,(hl)
    ld (PLY_AKM_REG12),a
    inc hl
    jr PLY_AKM_PSS_SHARED_STOREINSTRUMENTPOINTER
PLY_AKM_PSS_SOFTWARETOHARDWARE: call PLY_AKM_PSS_SHARED_READENVBITPITCHARP_SOFTPERIOD_HARDVOL_HARDENV
    ld a,b
    rlca 
    rlca 
    rlca 
    rlca 
    and #7
    exx
    jr z,PLY_AKM_PSS_STH_RATIOEND
PLY_AKM_PSS_STH_RATIOLOOP: srl h
    rr l
    dec a
    jr nz,PLY_AKM_PSS_STH_RATIOLOOP
    jr nc,PLY_AKM_PSS_STH_RATIOEND
    inc hl
PLY_AKM_PSS_STH_RATIOEND: ld a,l
    ld (PLY_AKM_REG11),a
    ld a,h
    ld (PLY_AKM_REG12),a
    exx
    jr PLY_AKM_PSS_SHARED_STOREINSTRUMENTPOINTER
PLY_AKM_PSS_SHARED_READENVBITPITCHARP_SOFTPERIOD_HARDVOL_HARDENV: and #2
    add a,#8
    ld (PLY_AKM_SENDPSGREGISTERR13+1),a
    ld +1(iy),#16
    xor a
    bit 7,b
    jr z,PLY_AKM_PSS_SHARED_RENVBAP_AFTERARPEGGIO
    ld a,(hl)
    inc hl
PLY_AKM_PSS_SHARED_RENVBAP_AFTERARPEGGIO: call PLY_AKM_CALCULATEPERIODFORBASENOTE
    bit 2,b
    call nz,PLY_AKM_READPITCHANDADDTOPERIOD
    exx
    ld +5(iy),l
    ld +9(iy),h
    exx
    ret 
PLY_AKM_PSS_SHARED_ADJUSTVOLUME: and #15
    sub +14(ix)
    ret nc
    xor a
    ret 
PLY_AKM_PSS_READNOISE: ld a,(hl)
    inc hl
    ld (PLY_AKM_NOISEREGISTER),a
    res 5,c
    ret 
PLY_AKM_CALCULATEPERIODFORBASENOTE: exx
    ld h,#0
    add a,+6(ix)
    add a,+28(ix)
    ld bc,#65292
PLY_AKM_FINDOCTAVE_LOOP: inc b
    sub c
    jr nc,PLY_AKM_FINDOCTAVE_LOOP
    add a,c
    add a,a
    ld l,a
    ld h,#0
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,b
    or a
    jr z,PLY_AKM_FINDOCTAVE_OCTAVESHIFTLOOP_FINISHED
PLY_AKM_FINDOCTAVE_OCTAVESHIFTLOOP: srl h
    rr l
    djnz PLY_AKM_FINDOCTAVE_OCTAVESHIFTLOOP
PLY_AKM_FINDOCTAVE_OCTAVESHIFTLOOP_FINISHED: jr nc,PLY_AKM_FINDOCTAVE_FINISHED
    inc hl
PLY_AKM_FINDOCTAVE_FINISHED: ld a,+29(ix)
    or a
    jr z,PLY_AKM_CALCULATEPERIODFORBASENOTE_NOPITCHTABLE
    ld c,+36(ix)
    ld b,+37(ix)
    add hl,bc
PLY_AKM_CALCULATEPERIODFORBASENOTE_NOPITCHTABLE: ld c,+16(ix)
    ld b,+17(ix)
    add hl,bc
    exx
    ret 
PLY_AKM_READPITCHANDADDTOPERIOD: ld a,(hl)
    inc hl
    exx
    ld c,a
    exx
    ld a,(hl)
    inc hl
    exx
    ld b,a
    add hl,bc
    exx
    ret 
PLY_AKM_EFFECTRESETWITHVOLUME: ld +14(ix),a
    xor a
    ld +15(ix),a
    ld +21(ix),a
    ld +28(ix),a
    ld +29(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTVOLUME: ld +14(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTFORCEINSTRUMENTSPEED: call PLY_AKM_EFFECTREADIFESCAPE
    ld +13(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTFORCEPITCHSPEED: call PLY_AKM_EFFECTREADIFESCAPE
    ld +34(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTFORCEARPEGGIOSPEED: call PLY_AKM_EFFECTREADIFESCAPE
    ld +26(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTTABLE: jr PLY_AKM_EFFECTRESETWITHVOLUME
    jr PLY_AKM_EFFECTVOLUME
    jr PLY_AKM_EFFECTPITCHUPDOWN
    jr PLY_AKM_EFFECTARPEGGIOTABLE
    jr PLY_AKM_EFFECTPITCHTABLE
    jr PLY_AKM_EFFECTFORCEINSTRUMENTSPEED
    jr PLY_AKM_EFFECTFORCEARPEGGIOSPEED
    jr PLY_AKM_EFFECTFORCEPITCHSPEED
PLY_AKM_EFFECTPITCHUPDOWN: rra 
    jr nc,PLY_AKM_EFFECTPITCHUPDOWN_DEACTIVATED
    ld +15(ix),#255
    ld a,(hl)
    inc hl
    ld +19(ix),a
    ld a,(hl)
    inc hl
    ld +20(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTPITCHUPDOWN_DEACTIVATED: ld +15(ix),#0
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTARPEGGIOTABLE: call PLY_AKM_EFFECTREADIFESCAPE
    ld +21(ix),a
    or a
    jr z,PLY_AKM_EFFECTARPEGGIOTABLE_STOP
    add a,a
    exx
    ld l,a
    ld h,#0
PLY_AKM_PTARPEGGIOS: ld bc,#0
    add hl,bc
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
    inc hl
    ld +27(ix),a
    ld +26(ix),a
    .db 221
    .db 117
    .db 22
    .db 221
    .db 116
    .db 23
    ld bc,(PLY_AKM_NOTEINDEXTABLE+1)
    exx
    xor a
    ld +24(ix),a
    ld +25(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTARPEGGIOTABLE_STOP: ld +28(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTPITCHTABLE: call PLY_AKM_EFFECTREADIFESCAPE
    ld +29(ix),a
    or a
    jp z,PLY_AKM_RT_READEFFECT_RETURN
    add a,a
    exx
    ld l,a
    ld h,#0
PLY_AKM_PTPITCHES: ld bc,#0
    add hl,bc
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
    inc hl
    ld +35(ix),a
    ld +34(ix),a
    .db 221
    .db 117
    .db 30
    .db 221
    .db 116
    .db 31
    ld bc,(PLY_AKM_NOTEINDEXTABLE+1)
    exx
    xor a
    ld +32(ix),a
    ld +33(ix),a
    jp PLY_AKM_RT_READEFFECT_RETURN
PLY_AKM_EFFECTREADIFESCAPE: cp #15
    ret c
    ld a,(hl)
    inc hl
    ret 
PLY_AKM_TRACK1_DATA:
PLY_AKM_TRACK1_WAITEMPTYCELL: .db 0
PLY_AKM_TRACK1_TRANSPOSITION: .db 0
PLY_AKM_TRACK1_PTSTARTTRACK: .dw 0
PLY_AKM_TRACK1_PTTRACK: .dw 0
PLY_AKM_TRACK1_BASENOTE: .db 0
PLY_AKM_TRACK1_ESCAPENOTE: .db 0
PLY_AKM_TRACK1_ESCAPEINSTRUMENT: .db 0
PLY_AKM_TRACK1_ESCAPEWAIT: .db 0
PLY_AKM_TRACK1_PTINSTRUMENT: .dw 0
PLY_AKM_TRACK1_INSTRUMENTCURRENTSTEP: .db 0
PLY_AKM_TRACK1_INSTRUMENTSPEED: .db 0
PLY_AKM_TRACK1_TRACKINVERTEDVOLUME: .db 0
PLY_AKM_TRACK1_ISPITCHUPDOWNUSED: .db 0
PLY_AKM_TRACK1_TRACKPITCHINTEGER: .dw 0
PLY_AKM_TRACK1_TRACKPITCHDECIMAL: .db 0
PLY_AKM_TRACK1_TRACKPITCHSPEED: .dw 0
PLY_AKM_TRACK1_ISARPEGGIOTABLEUSED: .db 0
PLY_AKM_TRACK1_PTARPEGGIOTABLE: .dw 0
PLY_AKM_TRACK1_PTARPEGGIOOFFSET: .db 0
PLY_AKM_TRACK1_ARPEGGIOCURRENTSTEP: .db 0
PLY_AKM_TRACK1_ARPEGGIOCURRENTSPEED: .db 0
PLY_AKM_TRACK1_ARPEGGIOORIGINALSPEED: .db 0
PLY_AKM_TRACK1_CURRENTARPEGGIOVALUE: .db 0
PLY_AKM_TRACK1_ISPITCHTABLEUSED: .db 0
PLY_AKM_TRACK1_PTPITCHTABLE: .dw 0
PLY_AKM_TRACK1_PTPITCHOFFSET: .db 0
PLY_AKM_TRACK1_PITCHCURRENTSTEP: .db 0
PLY_AKM_TRACK1_PITCHCURRENTSPEED: .db 0
PLY_AKM_TRACK1_PITCHORIGINALSPEED: .db 0
PLY_AKM_TRACK1_CURRENTPITCHTABLEVALUE: .dw 0
PLY_AKM_TRACK1_DATA_END:
PLY_AKM_TRACK2_DATA:
PLY_AKM_TRACK2_WAITEMPTYCELL: .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_TRACK2_PTTRACK: .db 0
    .db 0
    .db 0
PLY_AKM_TRACK2_ESCAPENOTE: .db 0
PLY_AKM_TRACK2_ESCAPEINSTRUMENT: .db 0
PLY_AKM_TRACK2_ESCAPEWAIT: .db 0
PLY_AKM_TRACK2_PTINSTRUMENT: .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_TRACK2_DATA_END:
PLY_AKM_TRACK3_DATA:
PLY_AKM_TRACK3_WAITEMPTYCELL: .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_TRACK3_PTTRACK: .db 0
    .db 0
    .db 0
PLY_AKM_TRACK3_ESCAPENOTE: .db 0
PLY_AKM_TRACK3_ESCAPEINSTRUMENT: .db 0
PLY_AKM_TRACK3_ESCAPEWAIT: .db 0
PLY_AKM_TRACK3_PTINSTRUMENT: .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
PLY_AKM_TRACK3_DATA_END:
PLY_AKM_REGISTERS_RETTABLE:
PLY_AKM_TRACK1_REGISTERS: .db 8
PLY_AKM_TRACK1_VOLUME: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 0
PLY_AKM_TRACK1_SOFTWAREPERIODLSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 1
PLY_AKM_TRACK1_SOFTWAREPERIODMSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
PLY_AKM_TRACK2_REGISTERS: .db 9
PLY_AKM_TRACK2_VOLUME: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 2
PLY_AKM_TRACK2_SOFTWAREPERIODLSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 3
PLY_AKM_TRACK2_SOFTWAREPERIODMSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
PLY_AKM_TRACK3_REGISTERS: .db 10
PLY_AKM_TRACK3_VOLUME: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 4
PLY_AKM_TRACK3_SOFTWAREPERIODLSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 5
PLY_AKM_TRACK3_SOFTWAREPERIODMSB: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 6
PLY_AKM_NOISEREGISTER: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 7
PLY_AKM_MIXERREGISTER: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 11
PLY_AKM_REG11: .db 0
    .dw PLY_AKM_SENDPSGREGISTER
    .db 12
PLY_AKM_REG12: .db 0
    .dw PLY_AKM_SENDPSGREGISTERR13
    .dw PLY_AKM_SENDPSGREGISTERAFTERPOP
    .dw PLY_AKM_SENDPSGREGISTEREND
PLY_AKM_PERIODTABLE: .dw 3822
    .dw 3608
    .dw 3405
    .dw 3214
    .dw 3034
    .dw 2863
    .dw 2703
    .dw 2551
    .dw 2408
    .dw 2273
    .dw 2145
    .dw 2025

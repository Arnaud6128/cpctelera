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
;;       Arkos Tracker 3 player "generic" player.
;;       By Targhan/Arkos.
;;       Adapted by Arnaud Bouche for cpctelera
;;
;;       Psg optimization trick on CPC by Madram/Overlanders.
;;
;;       v1.2:  
;;               - Added support for PCW and SVI. No change at all in the code, it uses the same access as MSX. Small label/constants refactor, but no Z80 change.
;;               - Removed ":" before EQUs (to be compatible with RASM 2.3.9).
;;               - Changed the MSX period table to 1789773 Hz (was 1773400 Hz like Spectrum before).
;;               - Corrected a small conditional bug when the SFX has hardware sounds, but not the main song, using player configuration (thanks Arnaud!).
;;       V1.1a: Added external variables instead of hardcoded constants inside the player:
;;               - Declare PLY_AKG_REMOVE_HOOKS (PLY_AKG_REMOVE_HOOKS = 1) to remove hooks (previously was PLY_AKG_USE_HOOKS).
;;               - Declare PLY_AKG_REMOVE_STOP_SOUNDS added to remove the snippet to stop the sounds (previously was PLY_AKG_STOP_SOUNDS) .
;;               - Declare PLY_AKG_REMOVE_FULL_INIT_CODE added to remove full init code (see below) (previously was PLY_AKG_FULL_INIT_CODE).
;;       V1.1
;;               - Corrected a SoftwareAndHardware bug if using Player Configuration and forced hardware sound (without using forced software sound).
;;               - Corrected a crash when using more than 128 effect blocks (thanks E-dredon and Roudoudou).
;;
;;       This compiles with RASM. Check the compatibility page on the Arkos Tracker website, it contains a source converter to any Z80 assembler!
;;
;;       The player uses the stack for optimizations. Make sure the interruptions are disabled before it is called.
;;       The stack pointer is saved at the beginning and restored at the end.
;;
;;       Target hardware:
;;       ---------------
;;       This code can target Amstrad CPC, MSX, Spectrum, Pentagon, PCW and SVI (SpectraVideo). By default, it targets Amstrad CPC.
;;       Simply use one of the follow line (BEFORE this player):
;;       PLY_AKG_HARDWARE_CPC = 1
;;       PLY_AKG_HARDWARE_MSX = 1
;;       PLY_AKG_HARDWARE_SPECTRUM = 1
;;       PLY_AKG_HARDWARE_PENTAGON = 1
;;       PLY_AKG_HARDWARE_PCW = 1
;;       PLY_AKG_HARDWARE_SVI = 1
;;       Note that the PRESENCE of this variable is tested, NOT its value.
;;
;;       ROM
;;       ----------------------
;;       To use a ROM player (no automodification, use of a small buffer to put in RAM):
;;       PLY_AKG_ROM = 1
;;       PLY_AKG_ROM_Buffer = #4000 (or wherever).
;;       This makes the player a bit slower and slightly bigger.
;;       The buffer is PLY_AKG_ROM_BufferSize long (=250 bytes max, 273 with sound effects).
;;       You can hardcode this value, because it is calculated, so it won't be accessible before this player is assembled.
;;       This value decreases when you use player configuration, but increases if you use sound effects.
;;
;;       Optimizations:
;;       --------------
;;       - Use the Player Configuration of Arkos Tracker 3 to generate a configuration file to be included at the beginning of this player.
;;         It will disable useless features according to your songs, saving for memory and CPU! Check the manual for more details, or more simply the testers.
;;       - SIZE: Hooks for external calls (play/init) are present by default. Define PLY_AKG_REMOVE_HOOKS to remove them (PLY_AKG_REMOVE_HOOKS = 1).
;;       - SIZE: Define PLY_AKG_REMOVE_STOP_SOUNDS to remove the Stop sound method (PLY_AKG_Stop) if you don't intend on stopping the music.
;;       - SIZE: If you play your song "one shot" (i.e. without looping it), you can define PLY_AKG_REMOVE_FULL_INIT_CODE, some
;;         initialization code will not be assembled.

;;       Sound effects:
;;       --------------
;;       Sound effects are disabled by default. Declare PLY_AKG_MANAGE_SOUND_EFFECTS to enable it:
;;       PLY_AKG_MANAGE_SOUND_EFFECTS = 1
;;       Check the sound effect tester to see how it enables it.
;;       Note that the PRESENCE of this variable is tested, NOT its value.

;;       Additional note:
;;       - There can be a slightly difference when using volume in/out effects compared to the PC side, because the volume management is
;;         different. This means there can be a difference of 1 at certain frames. As it shouldn't be a bother, I let it this way.
;;         This allows the Z80 code to be faster and simpler.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PLY_AKG_OFFSET1B = .+1
RASM_VERSION = .+2
PLY_AKG_OFFSET2B = .+2
PLY_AKG_SOUNDEFFECTDATA_OFFSETINVERTEDVOLUME = .+2
PLY_AKG_BITFORSOUND = .+2
PLY_AKG_START:
PLY_AKG_OPCODE_ADD_HL_BC_MSB: jp cpct_PLY_AKG_Init
PLY_AKG_SOUNDEFFECTDATA_OFFSETSPEED = .+1
PLY_AKG_BITFORNOISE = .+2
PLY_AKG_SOUNDEFFECTDATA_OFFSETCURRENTSTEP: jp cpct_PLY_AKG_Play
PLY_AKG_CHANNEL_SOUNDEFFECTDATASIZE = .+2
    jp PLY_AKG_INITTABLEORA_END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_InitSoundEffects
;;
;; Initializes the sound effects. It MUST be called at any times before a first sound effect is triggered.
;; It doesn't matter whether the song is playing or not, or if it has been initialized or not.
;;
;; C Definition:
;;    void cpct_PLY_AKG_InitSoundEffects(void* sfx_song_data) __z88dk_fastcall
;;
;; Input Parameters (2 bytes):
;;    (2B  HL) sfx_song_data  - Address to the sound effects data.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_InitSoundEffects_asm
;;
;; Destroyed Register values: 
;;      -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
_cpct_PLY_AKG_InitSoundEffects::
;; CPCtelera according __z88dk_fastcall convention
;; HL = sfx_song_data 
cpct_PLY_AKG_InitSoundEffects:
cpct_PLY_AKG_InitSoundEffects_asm:
PLY_AKG_OPCODE_ADD_HL_BC_LSB: 
	ld (PLY_AKG_PTSOUNDEFFECTTABLE+1),hl
    ret 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_PlaySoundEffect
;;
;; Plays a sound effect. If a previous one was already playing on the same channel, it is replaced.
;; This does not actually plays the sound effect, but programs its playing.
;; The music player, when called, will call the PLY_AKG_PlaySoundEffectsStream method below.
;;
;; C Definition:
;;    void cpct_PLY_AKG_PlaySoundEffect(u8 sfx_num, u8 channel, u16 volume) __z88dk_callee;
;;
;; Input Parameters (3 bytes):
;;    (1B A) = Sound effect number (>0!).
;;    (1B C) = The channel where to play the sound effect (0, 1, 2) 
;;    (1B B) = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_PlaySoundEffect_asm
;;
;; Destroyed Register values: 
;;      AF', AF, BC, DE, HL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_PLY_AKG_PlaySoundEffect::
cpct_PLY_AKG_PlaySoundEffect: 
;; CPCtelera according __sdcccall(1) and __z88dk_callee convention
;; A = Sound effect number (>0!)
;; L = The channel where to play the sound effect (0, 1, 2).
    ld c,l
    pop hl
    ex (sp),hl ;; HL <-> SP Inverted volume
    ld b,l     ;; B = L Inverted volume
cpct_PLY_AKG_PlaySoundEffect_asm: 
	dec a
PLY_AKG_PTSOUNDEFFECTTABLE: ld hl,#0
    ld e,a
    ld d,#0
    add hl,de
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld a,(de)
    inc de
    ex af,af'
    ld a,b
PLY_AKG_OPCODE_INC_HL = .+2
    ld hl,#PLY_AKG_CHANNEL1_SOUNDEFFECTDATA
    ld b,#0
    sla c
    sla c
PLY_AKG_OPCODE_DEC_HL = .+1
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
PLY_AKG_OPCODE_SCF: ld (hl),a
    ret 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_StopSoundEffectFromChannel
;;
;; Stops a sound effect. Nothing happens if there was no sound effect.
;;
;; C Definition:
;;    void cpct_PLY_AKG_StopSoundEffectFromChannel(u8 channel) __z88dk_fastcall;
;;
;; Input Parameters (1 bytes):
;;    (1B A) = Channel number.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_StopSoundEffectFromChannel_asm
;;
;; Destroyed Register values: 
;;      AF, DE, HL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_PLY_AKG_StopSoundEffectFromChannel::
;; CPCtelera according __z88dk_fastcall convention
;; A = Channel
cpct_PLY_AKG_StopSoundEffectFromChannel:
cpct_PLY_AKG_StopSoundEffectFromChannel_asm:
    add a,a
    add a,a
    add a,a
    ld e,a
    ld d,#0
    ld hl,#PLY_AKG_CHANNEL1_SOUNDEFFECTDATA
PLY_AKG_OPCODE_SBC_HL_BC_LSB: add hl,de
    ld (hl),d
    inc hl
    ld (hl),d
    ret 
		
;Plays the sound effects, if any has been triggered by the user.
;This does not actually send registers to the PSG, it only overwrite the required values of the registers of the player.
;The sound effects initialization method must have been called before!
;As R7 is required, this must be called after the music has been played, but BEFORE the registers are sent to the PSG.
;IN:    A = R7.
;OUT:   A = new R7.	
PLY_AKG_PLAYSOUNDEFFECTSSTREAM: 
	rla 
    rla 
    ld ix,#PLY_AKG_CHANNEL1_SOUNDEFFECTDATA
    ld iy,#PLY_AKG_PSGREG8
    ld hl,#PLY_AKG_PSGREG01_INSTR+1
    exx
    ld c,a
    call PLY_AKG_PSES_PLAY
    ld ix,#PLY_AKG_CHANNEL2_SOUNDEFFECTDATA
    ld iy,#PLY_AKG_PSGREG9
    exx
    ld hl,#PLY_AKG_PSGREG23_INSTR+1
    exx
    srl c
    call PLY_AKG_PSES_PLAY
    ld ix,#PLY_AKG_CHANNEL3_SOUNDEFFECTDATA
    ld iy,#PLY_AKG_PSGREG10
    exx
    ld hl,#PLY_AKG_PSGREG45_INSTR+1
    exx
    rr c
    call PLY_AKG_PSES_PLAY
    ld a,c
    ret 
	
;Plays the sound stream from the given pointer to the sound effect. If 0, no sound is played.
;The given R7 is given shift twice to the left, so that this code MUST set/reset the bit 2 (sound), and set/reset bit 5 (noise).
;This code MUST overwrite these bits because sound effects have priority over the music.
;IN:    IX = Points on the sound effect pointer. If the sound effect pointer is 0, nothing must be played.
;       IY = Points on the address where to store the volume for this channel.
;       HL'= Points on the address where to store the software period for this channel.
;       C = R7, shifted twice to the left.
;OUT:   The pointed pointer by IX may be modified as the sound advances.
;       C = R7, MUST be modified if there is a sound effect.	
PLY_AKG_PSES_PLAY: ld l,+0(ix)
    ld h,+1(ix)
    ld a,l
    or h
    ret z
PLY_AKG_PSES_READFIRSTBYTE: ld a,(hl)
    inc hl
    ld b,a
    rra 
    jr c,PLY_AKG_PSES_SOFTWAREORSOFTWAREANDHARDWARE
    rra 
    jr c,PLY_AKG_PSES_HARDWAREONLY
    rra 
    jr c,PLY_AKG_PSES_S_ENDORLOOP
    call PLY_AKG_PSES_MANAGEVOLUMEFROMA_FILTER4BITS
    rl b
    call PLY_AKG_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    set 2,c
    jr PLY_AKG_PSES_SAVEPOINTERANDEXIT
PLY_AKG_PSES_S_ENDORLOOP: rra 
    jr c,PLY_AKG_PSES_S_LOOP
    xor a
    ld +0(ix),a
    ld +1(ix),a
    ret 
PLY_AKG_PSES_S_LOOP: ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    jr PLY_AKG_PSES_READFIRSTBYTE
PLY_AKG_PSES_SAVEPOINTERANDEXIT: ld a,+3(ix)
    cp +4(ix)
PLY_AKG_OPCODE_OR_A: jr c,PLY_AKG_PSES_NOTREACHED
    ld +3(ix),#0
    .db 221
    .db 117
    .db 0
    .db 221
    .db 116
    .db 1
    ret 
PLY_AKG_OPCODE_ADD_A_IMMEDIATE = .+2
PLY_AKG_PSES_NOTREACHED: inc +3(ix)
    ret 
PLY_AKG_PSES_HARDWAREONLY: call PLY_AKG_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE
    set 2,c
    jr PLY_AKG_PSES_SAVEPOINTERANDEXIT
PLY_AKG_PSES_SOFTWAREORSOFTWAREANDHARDWARE: rra 
    jr c,PLY_AKG_PSES_SOFTWAREANDHARDWARE
    call PLY_AKG_PSES_MANAGEVOLUMEFROMA_FILTER4BITS
PLY_AKG_OPCODE_SUB_IMMEDIATE = .+1
    rl b
    call PLY_AKG_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    res 2,c
    call PLY_AKG_PSES_READSOFTWAREPERIOD
    jr PLY_AKG_PSES_SAVEPOINTERANDEXIT
PLY_AKG_PSES_SOFTWAREANDHARDWARE: call PLY_AKG_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE
    call PLY_AKG_PSES_READSOFTWAREPERIOD
    res 2,c
    jr PLY_AKG_PSES_SAVEPOINTERANDEXIT
PLY_AKG_PSES_SHARED_READRETRIGHARDWAREENVPERIODNOISE: rra 
PLY_AKG_OPCODE_SBC_HL_BC_MSB = .+1
    jr nc,PLY_AKG_PSES_H_AFTERRETRIG
    ld d,a
    ld a,#255
    ld (PLY_AKG_PSGREG13_OLDVALUE+1),a
    ld a,d
PLY_AKG_PSES_H_AFTERRETRIG: and #7
    add a,#8
    ld (PLY_AKG_PSGREG13_INSTR+1),a
    rl b
SYNCHRO = .+2
    call PLY_AKG_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL
    call PLY_AKG_PSES_READHARDWAREPERIOD
    ld a,#16
    jp PLY_AKG_PSES_MANAGEVOLUMEFROMA_HARD
PLY_AKG_PSES_READNOISEIFNEEDEDANDOPENORCLOSENOISECHANNEL: jr c,PLY_AKG_PSES_READNOISEANDOPENNOISECHANNEL_OPENNOISE
    set 5,c
    ret 
PLY_AKG_PSES_READNOISEANDOPENNOISECHANNEL_OPENNOISE: ld a,(hl)
    ld (PLY_AKG_PSGREG6),a
    inc hl
    res 5,c
    ret 
PLY_AKG_PSES_READHARDWAREPERIOD: ld a,(hl)
    ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+1),a
    inc hl
    ld a,(hl)
    ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+2),a
    inc hl
    ret 
PLY_AKG_PSES_READSOFTWAREPERIOD: ld a,(hl)
    inc hl
    exx
    ld (hl),a
    inc hl
    exx
    ld a,(hl)
    inc hl
    exx
    ld (hl),a
    exx
    ret 
PLY_AKG_PSES_MANAGEVOLUMEFROMA_FILTER4BITS: and #15
PLY_AKG_PSES_MANAGEVOLUMEFROMA_HARD: sub +2(ix)
    jr nc,PLY_AKG_PSES_MVFA_NOOVERFLOW
    xor a
PLY_AKG_PSES_MVFA_NOOVERFLOW: ld +0(iy),a
    ret 
PLY_AKG_CHANNEL1_SOUNDEFFECTDATA: .dw 0
PLY_AKG_CHANNEL1_SOUNDEFFECTINVERTEDVOLUME: .db 0
PLY_AKG_CHANNEL1_SOUNDEFFECTCURRENTSTEP: .db 0
PLY_AKG_CHANNEL1_SOUNDEFFECTSPEED: .db 0
    .db 0
    .db 0
    .db 0
PLY_AKG_CHANNEL2_SOUNDEFFECTDATA: .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
    .db 0
PLY_AKG_CHANNEL3_SOUNDEFFECTDATA: .db 0
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
	
_cpct_PLY_AKG_Init::
;; CPCTelera according __sdcccall(1) and __z88dk_callee convention
;; HL = Address of the song
;; DE = D useless  / E  = Subsong index (>=0)
cpct_PLY_AKG_Init:
    ld a,e  ;; A = E (Subsong index (>=0))
cpct_PLY_AKG_Init_asm: 
    ld de,#4
    add hl,de
    ld de,#PLY_AKG_ARPEGGIOSTABLE+1
    ldi
    ldi
    ld de,#PLY_AKG_PITCHESTABLE+1
    ldi
    ldi
    ld de,#PLY_AKG_INSTRUMENTSTABLE+1
    ldi
    ldi
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    ld (PLY_AKG_CHANNEL_READEFFECTS_EFFECTBLOCKS1+1),bc
    ld (PLY_AKG_CHANNEL_READEFFECTS_EFFECTBLOCKS2+1),bc
    add a,a
    ld e,a
    ld d,#0
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld de,#5
    add hl,de
    ld de,#PLY_AKG_CHANNEL3_READCELLEND+1
    ldi
    ld de,#PLY_AKG_CHANNEL1_NOTE+1
    ldi
    ld (PLY_AKG_READLINKER+1),hl
    ld hl,#PLY_AKG_INITTABLE0
    ld bc,#3584
    call PLY_AKG_INIT_READWORDSANDFILL
    inc c
    ld hl,#PLY_AKG_INITTABLE0_END
    ld b,#3
    call PLY_AKG_INIT_READWORDSANDFILL
    ld hl,#PLY_AKG_INITTABLE1_END
    ld bc,#3511
    call PLY_AKG_INIT_READWORDSANDFILL
    ld a,#255
    ld (PLY_AKG_PSGREG13_OLDVALUE+1),a
    ld hl,(PLY_AKG_INSTRUMENTSTABLE+1)
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    inc hl
    ld (PLY_AKG_ENDWITHOUTLOOP+1),hl
    ld (PLY_AKG_CHANNEL1_PTINSTRUMENT+1),hl
    ld (PLY_AKG_CHANNEL2_PTINSTRUMENT+1),hl
    ld (PLY_AKG_CHANNEL3_PTINSTRUMENT+1),hl
    ld hl,#0
    ld (PLY_AKG_CHANNEL1_SOUNDEFFECTDATA),hl
    ld (PLY_AKG_CHANNEL2_SOUNDEFFECTDATA),hl
    ld (PLY_AKG_CHANNEL3_SOUNDEFFECTDATA),hl
    ret 
PLY_AKG_INIT_READWORDSANDFILL_LOOP: ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld a,c
    ld (de),a
PLY_AKG_INIT_READWORDSANDFILL: djnz PLY_AKG_INIT_READWORDSANDFILL_LOOP
    ret 
PLY_AKG_INITTABLE0: .dw PLY_AKG_CHANNEL1_INVERTEDVOLUMEINTEGERANDDECIMAL+1
    .dw PLY_AKG_CHANNEL1_INVERTEDVOLUMEINTEGER
    .dw PLY_AKG_CHANNEL2_INVERTEDVOLUMEINTEGERANDDECIMAL+1
    .dw PLY_AKG_CHANNEL2_INVERTEDVOLUMEINTEGER
    .dw PLY_AKG_CHANNEL3_INVERTEDVOLUMEINTEGERANDDECIMAL+1
    .dw PLY_AKG_CHANNEL3_INVERTEDVOLUMEINTEGER
    .dw PLY_AKG_CHANNEL1_PITCHTABLE_END+1
    .dw PLY_AKG_CHANNEL1_PITCHTABLE_END+2
    .dw PLY_AKG_CHANNEL2_PITCHTABLE_END+1
    .dw PLY_AKG_CHANNEL2_PITCHTABLE_END+2
    .dw PLY_AKG_CHANNEL3_PITCHTABLE_END+1
    .dw PLY_AKG_CHANNEL3_PITCHTABLE_END+2
    .dw PLY_AKG_RETRIG+1
PLY_AKG_INITTABLE0_END:
PLY_AKG_INITTABLE1: .dw PLY_AKG_PATTERNDECREASINGHEIGHT+1
    .dw PLY_AKG_TICKDECREASINGCOUNTER+1
PLY_AKG_INITTABLE1_END:
PLY_AKG_INITTABLEORA: .dw PLY_AKG_CHANNEL1_ISVOLUMESLIDE
    .dw PLY_AKG_CHANNEL2_ISVOLUMESLIDE
    .dw PLY_AKG_CHANNEL3_ISVOLUMESLIDE
    .dw PLY_AKG_CHANNEL1_ISARPEGGIOTABLE
    .dw PLY_AKG_CHANNEL2_ISARPEGGIOTABLE
    .dw PLY_AKG_CHANNEL3_ISARPEGGIOTABLE
    .dw PLY_AKG_CHANNEL1_ISPITCHTABLE
    .dw PLY_AKG_CHANNEL2_ISPITCHTABLE
    .dw PLY_AKG_CHANNEL3_ISPITCHTABLE
    .dw PLY_AKG_CHANNEL1_ISPITCH
    .dw PLY_AKG_CHANNEL2_ISPITCH
    .dw PLY_AKG_CHANNEL3_ISPITCH
PLY_AKG_INITTABLEORA_END:

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

_cpct_PLY_AKG_Stop::
cpct_PLY_AKG_Stop:
cpct_PLY_AKG_Stop_asm: 
    ld (PLY_AKG_PSGREG13_END+1),sp
    xor a
    ld l,a
    ld h,a
    ld (PLY_AKG_PSGREG8),a
    ld (PLY_AKG_PSGREG9),hl
    ld a,#63
    jp PLY_AKG_SENDPSGREGISTERS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_PLY_AKG_Play
;;
;; Plays one frame of the subsong
;;
;; C Definition:
;;    void cpct_PLY_AKG_Play(void);
;;
;; Input Parameters (0 bytes):
;;    
;; Assembly call (Input parameters on registers):
;;    > call cpct_PLY_AKG_Play_asm
;;
;; Destroyed Register values: 
;;     -
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

_cpct_PLY_AKG_Play::
cpct_PLY_AKG_Play:
cpct_PLY_AKG_Play_asm: 
    ld (PLY_AKG_PSGREG13_END+1),sp
    xor a
    ld (PLY_AKG_EVENT),a
PLY_AKG_TICKDECREASINGCOUNTER: ld a,#1
    dec a
    jp nz,PLY_AKG_SETSPEEDBEFOREPLAYSTREAMS
PLY_AKG_PATTERNDECREASINGHEIGHT: ld a,#1
    dec a
    jr nz,PLY_AKG_SETCURRENTLINEBEFOREREADLINE
PLY_AKG_READLINKER:
PLY_AKG_READLINKER_PTLINKER: ld sp,#0
    pop hl
    ld a,l
    or h
    jr nz,PLY_AKG_READLINKER_NOLOOP
    pop hl
    ld sp,hl
    pop hl
PLY_AKG_READLINKER_NOLOOP: ld (PLY_AKG_CHANNEL1_READTRACK+1),hl
    pop hl
    ld (PLY_AKG_CHANNEL2_READTRACK+1),hl
    pop hl
    ld (PLY_AKG_CHANNEL3_READTRACK+1),hl
    pop hl
    ld (PLY_AKG_READLINKER+1),sp
    ld sp,hl
    pop hl
    ld c,l
    ld a,h
    ld (PLY_AKG_CHANNEL1_AFTERNOTEKNOWN+1),a
    pop hl
    ld a,l
    ld (PLY_AKG_CHANNEL2_AFTERNOTEKNOWN+1),a
    ld a,h
    ld (PLY_AKG_CHANNEL3_AFTERNOTEKNOWN+1),a
    pop hl
    ld (PLY_AKG_SPEEDTRACK_PTTRACK+1),hl
    pop hl
    ld (PLY_AKG_EVENTTRACK_PTTRACK+1),hl
    xor a
    ld (PLY_AKG_READLINE+1),a
    ld (PLY_AKG_SPEEDTRACK_END+1),a
    ld (PLY_AKG_EVENTTRACK_END+1),a
    ld (PLY_AKG_CHANNEL1_READCELLEND+1),a
    ld (PLY_AKG_CHANNEL2_READCELLEND+1),a
    ld a,c
PLY_AKG_SETCURRENTLINEBEFOREREADLINE: ld (PLY_AKG_PATTERNDECREASINGHEIGHT+1),a
PLY_AKG_READLINE:
PLY_AKG_SPEEDTRACK_WAITCOUNTER: ld a,#0
    sub #1
    jr nc,PLY_AKG_SPEEDTRACK_MUSTWAIT
PLY_AKG_SPEEDTRACK_PTTRACK: ld hl,#0
    ld a,(hl)
    inc hl
    srl a
    jr c,PLY_AKG_SPEEDTRACK_STOREPOINTERANDWAITCOUNTER
    jr nz,PLY_AKG_SPEEDTRACK_NORMALVALUE
    ld a,(hl)
    inc hl
PLY_AKG_SPEEDTRACK_NORMALVALUE: ld (PLY_AKG_CHANNEL3_READCELLEND+1),a
    xor a
PLY_AKG_SPEEDTRACK_STOREPOINTERANDWAITCOUNTER: ld (PLY_AKG_SPEEDTRACK_PTTRACK+1),hl
PLY_AKG_SPEEDTRACK_MUSTWAIT: ld (PLY_AKG_READLINE+1),a
PLY_AKG_SPEEDTRACK_END:
PLY_AKG_EVENTTRACK_WAITCOUNTER: ld a,#0
    sub #1
    jr nc,PLY_AKG_EVENTTRACK_MUSTWAIT
PLY_AKG_EVENTTRACK_PTTRACK: ld hl,#0
    ld a,(hl)
    inc hl
    srl a
    jr c,PLY_AKG_EVENTTRACK_STOREPOINTERANDWAITCOUNTER
    jr nz,PLY_AKG_EVENTTRACK_NORMALVALUE
    ld a,(hl)
    inc hl
PLY_AKG_EVENTTRACK_NORMALVALUE: ld (PLY_AKG_EVENT),a
    xor a
PLY_AKG_EVENTTRACK_STOREPOINTERANDWAITCOUNTER: ld (PLY_AKG_EVENTTRACK_PTTRACK+1),hl
PLY_AKG_EVENTTRACK_MUSTWAIT: ld (PLY_AKG_SPEEDTRACK_END+1),a
PLY_AKG_EVENTTRACK_END:
PLY_AKG_CHANNEL1_WAITCOUNTER: ld a,#0
    sub #1
    jr c,PLY_AKG_CHANNEL1_READTRACK
    ld (PLY_AKG_EVENTTRACK_END+1),a
    jp PLY_AKG_CHANNEL1_READCELLEND
PLY_AKG_CHANNEL1_READTRACK:
PLY_AKG_CHANNEL1_PTTRACK: ld hl,#0
    ld c,(hl)
    inc hl
    ld a,c
    and #63
    cp #60
    jr c,PLY_AKG_CHANNEL1_NOTE
    sub #60
    jp z,PLY_AKG_CHANNEL1_MAYBEEFFECTS
    dec a
    jr z,PLY_AKG_CHANNEL1_WAIT
    dec a
    jr z,PLY_AKG_CHANNEL1_SMALLWAIT
    ld a,(hl)
    inc hl
    jr PLY_AKG_CHANNEL1_AFTERNOTEKNOWN
PLY_AKG_CHANNEL1_SMALLWAIT: ld a,c
    rlca 
    rlca 
    and #3
    inc a
    ld (PLY_AKG_EVENTTRACK_END+1),a
    jr PLY_AKG_CHANNEL1_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL1_WAIT: ld a,(hl)
    ld (PLY_AKG_EVENTTRACK_END+1),a
    inc hl
    jr PLY_AKG_CHANNEL1_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL1_SAMEINSTRUMENT:
PLY_AKG_CHANNEL1_PTBASEINSTRUMENT: ld de,#0
    ld (PLY_AKG_CHANNEL1_PTINSTRUMENT+1),de
    jr PLY_AKG_CHANNEL1_AFTERINSTRUMENT
PLY_AKG_CHANNEL1_NOTE:
PLY_AKG_BASENOTEINDEX: add a,#0
PLY_AKG_CHANNEL1_AFTERNOTEKNOWN:
PLY_AKG_CHANNEL1_TRANSPOSITION: add a,#0
    ld (PLY_AKG_CHANNEL1_TRACKNOTE+1),a
    rl c
    jr nc,PLY_AKG_CHANNEL1_SAMEINSTRUMENT
    ld a,(hl)
    inc hl
    exx
    ld l,a
    ld h,#0
    add hl,hl
PLY_AKG_INSTRUMENTSTABLE: ld de,#0
    add hl,de
    ld sp,hl
    pop hl
    ld a,(hl)
    inc hl
    ld (PLY_AKG_CHANNEL1_INSTRUMENTORIGINALSPEED+1),a
    ld (PLY_AKG_CHANNEL1_PTINSTRUMENT+1),hl
    ld (PLY_AKG_CHANNEL1_SAMEINSTRUMENT+1),hl
    exx
PLY_AKG_CHANNEL1_AFTERINSTRUMENT: ex de,hl
    xor a
    ld l,a
    ld h,a
    ld (PLY_AKG_CHANNEL1_PITCHTABLE_END+1),hl
    ld (PLY_AKG_CHANNEL1_ARPEGGIOTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL1_PITCHTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL1_INSTRUMENTSTEP+2),a
PLY_AKG_CHANNEL1_INSTRUMENTORIGINALSPEED: ld a,#0
    ld (PLY_AKG_CHANNEL1_INSTRUMENTSPEED+1),a
    ld a,#183
    ld (PLY_AKG_CHANNEL1_ISPITCH),a
    ld a,(PLY_AKG_CHANNEL1_ARPEGGIOBASESPEED)
    ld (PLY_AKG_CHANNEL1_ARPEGGIOTABLESPEED),a
    ld a,(PLY_AKG_CHANNEL1_PITCHBASESPEED)
    ld (PLY_AKG_CHANNEL1_PITCHTABLESPEED),a
    ld hl,(PLY_AKG_CHANNEL1_ARPEGGIOTABLEBASE)
    ld (PLY_AKG_CHANNEL1_ARPEGGIOTABLE+1),hl
    ld hl,(PLY_AKG_CHANNEL1_PITCHTABLEBASE)
    ld (PLY_AKG_CHANNEL1_PITCHTABLE+1),hl
    ex de,hl
    rl c
    jp c,PLY_AKG_CHANNEL1_READEFFECTS
PLY_AKG_CHANNEL1_BEFOREEND_STORECELLPOINTER: ld (PLY_AKG_CHANNEL1_READTRACK+1),hl
PLY_AKG_CHANNEL1_READCELLEND:
PLY_AKG_CHANNEL2_WAITCOUNTER: ld a,#0
    sub #1
    jr c,PLY_AKG_CHANNEL2_READTRACK
    ld (PLY_AKG_CHANNEL1_READCELLEND+1),a
    jp PLY_AKG_CHANNEL2_READCELLEND
PLY_AKG_CHANNEL2_READTRACK:
PLY_AKG_CHANNEL2_PTTRACK: ld hl,#0
    ld c,(hl)
    inc hl
    ld a,c
    and #63
    cp #60
    jr c,PLY_AKG_CHANNEL2_NOTE
    sub #60
    jp z,PLY_AKG_CHANNEL1_READEFFECTSEND
    dec a
    jr z,PLY_AKG_CHANNEL2_WAIT
    dec a
    jr z,PLY_AKG_CHANNEL2_SMALLWAIT
    ld a,(hl)
    inc hl
    jr PLY_AKG_CHANNEL2_AFTERNOTEKNOWN
PLY_AKG_CHANNEL2_SMALLWAIT: ld a,c
    rlca 
    rlca 
    and #3
    inc a
    ld (PLY_AKG_CHANNEL1_READCELLEND+1),a
    jr PLY_AKG_CHANNEL2_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL2_WAIT: ld a,(hl)
    ld (PLY_AKG_CHANNEL1_READCELLEND+1),a
    inc hl
    jr PLY_AKG_CHANNEL2_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL2_SAMEINSTRUMENT:
PLY_AKG_CHANNEL2_PTBASEINSTRUMENT: ld de,#0
    ld (PLY_AKG_CHANNEL2_PTINSTRUMENT+1),de
    jr PLY_AKG_CHANNEL2_AFTERINSTRUMENT
PLY_AKG_CHANNEL2_NOTE: ld b,a
    ld a,(PLY_AKG_CHANNEL1_NOTE+1)
    add a,b
PLY_AKG_CHANNEL2_AFTERNOTEKNOWN:
PLY_AKG_CHANNEL2_TRANSPOSITION: add a,#0
    ld (PLY_AKG_CHANNEL2_TRACKNOTE+1),a
    rl c
    jr nc,PLY_AKG_CHANNEL2_SAMEINSTRUMENT
    ld a,(hl)
    inc hl
    exx
    ld e,a
    ld d,#0
    ld hl,(PLY_AKG_INSTRUMENTSTABLE+1)
    add hl,de
    add hl,de
    ld sp,hl
    pop hl
    ld a,(hl)
    inc hl
    ld (PLY_AKG_CHANNEL2_INSTRUMENTORIGINALSPEED+1),a
    ld (PLY_AKG_CHANNEL2_PTINSTRUMENT+1),hl
    ld (PLY_AKG_CHANNEL2_SAMEINSTRUMENT+1),hl
    exx
PLY_AKG_CHANNEL2_AFTERINSTRUMENT: ex de,hl
    xor a
    ld l,a
    ld h,a
    ld (PLY_AKG_CHANNEL2_PITCHTABLE_END+1),hl
    ld (PLY_AKG_CHANNEL2_ARPEGGIOTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL2_PITCHTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL2_INSTRUMENTSTEP+2),a
PLY_AKG_CHANNEL2_INSTRUMENTORIGINALSPEED: ld a,#0
    ld (PLY_AKG_CHANNEL2_INSTRUMENTSPEED+1),a
    ld a,#183
    ld (PLY_AKG_CHANNEL2_ISPITCH),a
    ld a,(PLY_AKG_CHANNEL2_ARPEGGIOBASESPEED)
    ld (PLY_AKG_CHANNEL2_ARPEGGIOTABLESPEED),a
    ld a,(PLY_AKG_CHANNEL2_PITCHBASESPEED)
    ld (PLY_AKG_CHANNEL2_PITCHTABLESPEED),a
    ld hl,(PLY_AKG_CHANNEL2_ARPEGGIOTABLEBASE)
    ld (PLY_AKG_CHANNEL2_ARPEGGIOTABLE+1),hl
    ld hl,(PLY_AKG_CHANNEL2_PITCHTABLEBASE)
    ld (PLY_AKG_CHANNEL2_PITCHTABLE+1),hl
    ex de,hl
    rl c
    jp c,PLY_AKG_CHANNEL2_READEFFECTS
PLY_AKG_CHANNEL2_BEFOREEND_STORECELLPOINTER: ld (PLY_AKG_CHANNEL2_READTRACK+1),hl
PLY_AKG_CHANNEL2_READCELLEND:
PLY_AKG_CHANNEL3_WAITCOUNTER: ld a,#0
    sub #1
    jr c,PLY_AKG_CHANNEL3_READTRACK
    ld (PLY_AKG_CHANNEL2_READCELLEND+1),a
    jp PLY_AKG_CHANNEL3_READCELLEND
PLY_AKG_CHANNEL3_READTRACK:
PLY_AKG_CHANNEL3_PTTRACK: ld hl,#0
    ld c,(hl)
    inc hl
    ld a,c
    and #63
    cp #60
    jr c,PLY_AKG_CHANNEL3_NOTE
    sub #60
    jp z,PLY_AKG_CHANNEL2_READEFFECTSEND
    dec a
    jr z,PLY_AKG_CHANNEL3_WAIT
    dec a
    jr z,PLY_AKG_CHANNEL3_SMALLWAIT
    ld a,(hl)
    inc hl
    jr PLY_AKG_CHANNEL3_AFTERNOTEKNOWN
PLY_AKG_CHANNEL3_SMALLWAIT: ld a,c
    rlca 
    rlca 
    and #3
    inc a
    ld (PLY_AKG_CHANNEL2_READCELLEND+1),a
    jr PLY_AKG_CHANNEL3_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL3_WAIT: ld a,(hl)
    ld (PLY_AKG_CHANNEL2_READCELLEND+1),a
    inc hl
    jr PLY_AKG_CHANNEL3_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL3_SAMEINSTRUMENT:
PLY_AKG_CHANNEL3_PTBASEINSTRUMENT: ld de,#0
    ld (PLY_AKG_CHANNEL3_PTINSTRUMENT+1),de
    jr PLY_AKG_CHANNEL3_AFTERINSTRUMENT
PLY_AKG_CHANNEL3_NOTE: ld b,a
    ld a,(PLY_AKG_CHANNEL1_NOTE+1)
    add a,b
PLY_AKG_CHANNEL3_AFTERNOTEKNOWN:
PLY_AKG_CHANNEL3_TRANSPOSITION: add a,#0
    ld (PLY_AKG_CHANNEL3_TRACKNOTE+1),a
    rl c
    jr nc,PLY_AKG_CHANNEL3_SAMEINSTRUMENT
    ld a,(hl)
    inc hl
    exx
    ld e,a
    ld d,#0
    ld hl,(PLY_AKG_INSTRUMENTSTABLE+1)
    add hl,de
    add hl,de
    ld sp,hl
    pop hl
    ld a,(hl)
    inc hl
    ld (PLY_AKG_CHANNEL3_INSTRUMENTORIGINALSPEED+1),a
    ld (PLY_AKG_CHANNEL3_PTINSTRUMENT+1),hl
    ld (PLY_AKG_CHANNEL3_SAMEINSTRUMENT+1),hl
    exx
PLY_AKG_CHANNEL3_AFTERINSTRUMENT: ex de,hl
    xor a
    ld l,a
    ld h,a
    ld (PLY_AKG_CHANNEL3_PITCHTABLE_END+1),hl
    ld (PLY_AKG_CHANNEL3_ARPEGGIOTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL3_PITCHTABLECURRENTSTEP+1),a
    ld (PLY_AKG_CHANNEL3_INSTRUMENTSTEP+2),a
PLY_AKG_CHANNEL3_INSTRUMENTORIGINALSPEED: ld a,#0
    ld (PLY_AKG_CHANNEL3_INSTRUMENTSPEED+1),a
    ld a,#183
    ld (PLY_AKG_CHANNEL3_ISPITCH),a
    ld a,(PLY_AKG_CHANNEL3_ARPEGGIOBASESPEED)
    ld (PLY_AKG_CHANNEL3_ARPEGGIOTABLESPEED),a
    ld a,(PLY_AKG_CHANNEL3_PITCHBASESPEED)
    ld (PLY_AKG_CHANNEL3_PITCHTABLESPEED),a
    ld hl,(PLY_AKG_CHANNEL3_ARPEGGIOTABLEBASE)
    ld (PLY_AKG_CHANNEL3_ARPEGGIOTABLE+1),hl
    ld hl,(PLY_AKG_CHANNEL3_PITCHTABLEBASE)
    ld (PLY_AKG_CHANNEL3_PITCHTABLE+1),hl
    ex de,hl
    rl c
    jp c,PLY_AKG_CHANNEL3_READEFFECTS
PLY_AKG_CHANNEL3_BEFOREEND_STORECELLPOINTER: ld (PLY_AKG_CHANNEL3_READTRACK+1),hl
PLY_AKG_CHANNEL3_READCELLEND:
PLY_AKG_CURRENTSPEED: ld a,#0
PLY_AKG_SETSPEEDBEFOREPLAYSTREAMS: ld (PLY_AKG_TICKDECREASINGCOUNTER+1),a
PLY_AKG_CHANNEL1_INVERTEDVOLUMEINTEGER = .+2
PLY_AKG_CHANNEL1_INVERTEDVOLUMEINTEGERANDDECIMAL: ld hl,#0
PLY_AKG_CHANNEL1_ISVOLUMESLIDE: or a
    jr nc,PLY_AKG_CHANNEL1_VOLUMESLIDE_END
PLY_AKG_CHANNEL1_VOLUMESLIDEVALUE: ld de,#0
    add hl,de
    bit 7,h
    jr z,PLY_AKG_CHANNEL1_VOLUMENOTOVERFLOW
    ld h,#0
    jr PLY_AKG_CHANNEL1_VOLUMESETAGAIN
PLY_AKG_CHANNEL1_VOLUMENOTOVERFLOW: ld a,h
    cp #16
    jr c,PLY_AKG_CHANNEL1_VOLUMESETAGAIN
    ld h,#15
PLY_AKG_CHANNEL1_VOLUMESETAGAIN: ld (PLY_AKG_CHANNEL1_INVERTEDVOLUMEINTEGERANDDECIMAL+1),hl
PLY_AKG_CHANNEL1_VOLUMESLIDE_END: ld a,h
    ld (PLY_AKG_CHANNEL1_GENERATEDCURRENTINVERTEDVOLUME+1),a
    ld c,#0
PLY_AKG_CHANNEL1_ISARPEGGIOTABLE: or a
    jr nc,PLY_AKG_CHANNEL1_ARPEGGIOTABLE_END
PLY_AKG_CHANNEL1_ARPEGGIOTABLE: ld hl,#0
    ld a,(hl)
    cp #128
    jr nz,PLY_AKG_CHANNEL1_ARPEGGIOTABLE_AFTERLOOPTEST
    inc hl
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
PLY_AKG_CHANNEL1_ARPEGGIOTABLE_AFTERLOOPTEST: ld c,a
    ld a,(PLY_AKG_CHANNEL1_ARPEGGIOTABLESPEED)
    ld d,a
PLY_AKG_CHANNEL1_ARPEGGIOTABLECURRENTSTEP: ld a,#0
    inc a
    cp d
    jr c,PLY_AKG_CHANNEL1_ARPEGGIOTABLE_BEFOREEND_SAVESTEP
    inc hl
    ld (PLY_AKG_CHANNEL1_ARPEGGIOTABLE+1),hl
    xor a
PLY_AKG_CHANNEL1_ARPEGGIOTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL1_ARPEGGIOTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL1_ARPEGGIOTABLE_END: ld de,#0
PLY_AKG_CHANNEL1_ISPITCHTABLE: or a
    jr nc,PLY_AKG_CHANNEL1_PITCHTABLE_END
PLY_AKG_CHANNEL1_PITCHTABLE: ld sp,#0
    pop de
    pop hl
    ld a,(PLY_AKG_CHANNEL1_PITCHTABLESPEED)
    ld b,a
PLY_AKG_CHANNEL1_PITCHTABLECURRENTSTEP: ld a,#0
    inc a
    cp b
    jr c,PLY_AKG_CHANNEL1_PITCHTABLE_BEFOREEND_SAVESTEP
    ld (PLY_AKG_CHANNEL1_PITCHTABLE+1),hl
    xor a
PLY_AKG_CHANNEL1_PITCHTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL1_PITCHTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL1_PITCHTABLE_END:
PLY_AKG_CHANNEL1_PITCH: ld hl,#0
PLY_AKG_CHANNEL1_ISPITCH: or a
    jr nc,PLY_AKG_CHANNEL1_PITCH_END
    .db 221
    .db 105
PLY_AKG_CHANNEL1_PITCHTRACK: ld bc,#0
    or a
PLY_AKG_CHANNEL1_PITCHTRACKADDORSBC_16BITS: nop
    add hl,bc
PLY_AKG_CHANNEL1_PITCHTRACKDECIMALCOUNTER: ld a,#0
PLY_AKG_CHANNEL1_PITCHTRACKDECIMALVALUE = .+1
PLY_AKG_CHANNEL1_PITCHTRACKDECIMALINSTR: add a,#0
    ld (PLY_AKG_CHANNEL1_PITCHTRACKDECIMALCOUNTER+1),a
    jr nc,PLY_AKG_CHANNEL1_PITCHNOCARRY
PLY_AKG_CHANNEL1_PITCHTRACKINTEGERADDORSUB: inc hl
PLY_AKG_CHANNEL1_PITCHNOCARRY: ld (PLY_AKG_CHANNEL1_PITCHTABLE_END+1),hl
PLY_AKG_CHANNEL1_SOUNDSTREAM_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL1_GLIDEDIRECTION: ld a,#0
    or a
    jr z,PLY_AKG_CHANNEL1_GLIDE_END
    ld (PLY_AKG_CHANNEL1_AFTERARPEGGIOPITCHVARIABLES+1),hl
    ld c,l
    ld b,h
    ex af,af'
    ld a,(PLY_AKG_CHANNEL1_TRACKNOTE+1)
    add a,a
    ld l,a
    ex af,af'
    ld h,#0
    ld sp,#PLY_AKG_PERIODTABLE
    add hl,sp
    ld sp,hl
    pop hl
    dec sp
    dec sp
    add hl,bc
PLY_AKG_CHANNEL1_GLIDETOREACH: ld bc,#0
    rra 
    jr nc,PLY_AKG_CHANNEL1_GLIDEDOWNCHECK
    or a
    sbc hl,bc
    jr nc,PLY_AKG_CHANNEL1_AFTERARPEGGIOPITCHVARIABLES
    jr PLY_AKG_CHANNEL1_GLIDEOVER
PLY_AKG_CHANNEL1_GLIDEDOWNCHECK: sbc hl,bc
    jr c,PLY_AKG_CHANNEL1_AFTERARPEGGIOPITCHVARIABLES
PLY_AKG_CHANNEL1_GLIDEOVER: ld l,c
    ld h,b
    pop bc
    or a
    sbc hl,bc
    ld (PLY_AKG_CHANNEL1_PITCHTABLE_END+1),hl
    ld a,#183
    ld (PLY_AKG_CHANNEL1_ISPITCH),a
    jr PLY_AKG_CHANNEL1_GLIDE_END
PLY_AKG_CHANNEL1_ARPEGGIOTABLESPEED: .db 0
PLY_AKG_CHANNEL1_ARPEGGIOBASESPEED: .db 0
PLY_AKG_CHANNEL1_ARPEGGIOTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL1_PITCHTABLESPEED: .db 0
PLY_AKG_CHANNEL1_PITCHBASESPEED: .db 0
PLY_AKG_CHANNEL1_PITCHTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL1_AFTERARPEGGIOPITCHVARIABLES:
PLY_AKG_CHANNEL1_GLIDE_BEFOREEND:
PLY_AKG_CHANNEL1_GLIDE_SAVEHL: ld hl,#0
PLY_AKG_CHANNEL1_GLIDE_END: .db 221
    .db 77
PLY_AKG_CHANNEL1_PITCH_END: add hl,de
    ld (PLY_AKG_CHANNEL1_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS+1),hl
    ld a,c
    ld (PLY_AKG_CHANNEL1_GENERATEDCURRENTARPNOTE+1),a
PLY_AKG_CHANNEL2_INVERTEDVOLUMEINTEGER = .+2
PLY_AKG_CHANNEL2_INVERTEDVOLUMEINTEGERANDDECIMAL: ld hl,#0
PLY_AKG_CHANNEL2_ISVOLUMESLIDE: or a
    jr nc,PLY_AKG_CHANNEL2_VOLUMESLIDE_END
PLY_AKG_CHANNEL2_VOLUMESLIDEVALUE: ld de,#0
    add hl,de
    bit 7,h
    jr z,PLY_AKG_CHANNEL2_VOLUMENOTOVERFLOW
    ld h,#0
    jr PLY_AKG_CHANNEL2_VOLUMESETAGAIN
PLY_AKG_CHANNEL2_VOLUMENOTOVERFLOW: ld a,h
    cp #16
    jr c,PLY_AKG_CHANNEL2_VOLUMESETAGAIN
    ld h,#15
PLY_AKG_CHANNEL2_VOLUMESETAGAIN: ld (PLY_AKG_CHANNEL2_INVERTEDVOLUMEINTEGERANDDECIMAL+1),hl
PLY_AKG_CHANNEL2_VOLUMESLIDE_END: ld a,h
    ld (PLY_AKG_CHANNEL2_GENERATEDCURRENTINVERTEDVOLUME+1),a
    ld c,#0
PLY_AKG_CHANNEL2_ISARPEGGIOTABLE: or a
    jr nc,PLY_AKG_CHANNEL2_ARPEGGIOTABLE_END
PLY_AKG_CHANNEL2_ARPEGGIOTABLE: ld hl,#0
    ld a,(hl)
    cp #128
    jr nz,PLY_AKG_CHANNEL2_ARPEGGIOTABLE_AFTERLOOPTEST
    inc hl
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
PLY_AKG_CHANNEL2_ARPEGGIOTABLE_AFTERLOOPTEST: ld c,a
    ld a,(PLY_AKG_CHANNEL2_ARPEGGIOTABLESPEED)
    ld d,a
PLY_AKG_CHANNEL2_ARPEGGIOTABLECURRENTSTEP: ld a,#0
    inc a
    cp d
    jr c,PLY_AKG_CHANNEL2_ARPEGGIOTABLE_BEFOREEND_SAVESTEP
    inc hl
    ld (PLY_AKG_CHANNEL2_ARPEGGIOTABLE+1),hl
    xor a
PLY_AKG_CHANNEL2_ARPEGGIOTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL2_ARPEGGIOTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL2_ARPEGGIOTABLE_END: ld de,#0
PLY_AKG_CHANNEL2_ISPITCHTABLE: or a
    jr nc,PLY_AKG_CHANNEL2_PITCHTABLE_END
PLY_AKG_CHANNEL2_PITCHTABLE: ld sp,#0
    pop de
    pop hl
    ld a,(PLY_AKG_CHANNEL2_PITCHTABLESPEED)
    ld b,a
PLY_AKG_CHANNEL2_PITCHTABLECURRENTSTEP: ld a,#0
    inc a
    cp b
    jr c,PLY_AKG_CHANNEL2_PITCHTABLE_BEFOREEND_SAVESTEP
    ld (PLY_AKG_CHANNEL2_PITCHTABLE+1),hl
    xor a
PLY_AKG_CHANNEL2_PITCHTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL2_PITCHTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL2_PITCHTABLE_END:
PLY_AKG_CHANNEL2_PITCH: ld hl,#0
PLY_AKG_CHANNEL2_ISPITCH: or a
    jr nc,PLY_AKG_CHANNEL2_PITCH_END
    .db 221
    .db 105
PLY_AKG_CHANNEL2_PITCHTRACK: ld bc,#0
    or a
PLY_AKG_CHANNEL2_PITCHTRACKADDORSBC_16BITS: nop
    add hl,bc
PLY_AKG_CHANNEL2_PITCHTRACKDECIMALCOUNTER: ld a,#0
PLY_AKG_CHANNEL2_PITCHTRACKDECIMALVALUE = .+1
PLY_AKG_CHANNEL2_PITCHTRACKDECIMALINSTR: add a,#0
    ld (PLY_AKG_CHANNEL2_PITCHTRACKDECIMALCOUNTER+1),a
    jr nc,PLY_AKG_CHANNEL2_PITCHNOCARRY
PLY_AKG_CHANNEL2_PITCHTRACKINTEGERADDORSUB: inc hl
PLY_AKG_CHANNEL2_PITCHNOCARRY: ld (PLY_AKG_CHANNEL2_PITCHTABLE_END+1),hl
PLY_AKG_CHANNEL2_SOUNDSTREAM_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL2_GLIDEDIRECTION: ld a,#0
    or a
    jr z,PLY_AKG_CHANNEL2_GLIDE_END
    ld (PLY_AKG_CHANNEL2_AFTERARPEGGIOPITCHVARIABLES+1),hl
    ld c,l
    ld b,h
    ex af,af'
    ld a,(PLY_AKG_CHANNEL2_TRACKNOTE+1)
    add a,a
    ld l,a
    ex af,af'
    ld h,#0
    ld sp,#PLY_AKG_PERIODTABLE
    add hl,sp
    ld sp,hl
    pop hl
    dec sp
    dec sp
    add hl,bc
PLY_AKG_CHANNEL2_GLIDETOREACH: ld bc,#0
    rra 
    jr nc,PLY_AKG_CHANNEL2_GLIDEDOWNCHECK
    or a
    sbc hl,bc
    jr nc,PLY_AKG_CHANNEL2_AFTERARPEGGIOPITCHVARIABLES
    jr PLY_AKG_CHANNEL2_GLIDEOVER
PLY_AKG_CHANNEL2_GLIDEDOWNCHECK: sbc hl,bc
    jr c,PLY_AKG_CHANNEL2_AFTERARPEGGIOPITCHVARIABLES
PLY_AKG_CHANNEL2_GLIDEOVER: ld l,c
    ld h,b
    pop bc
    or a
    sbc hl,bc
    ld (PLY_AKG_CHANNEL2_PITCHTABLE_END+1),hl
    ld a,#183
    ld (PLY_AKG_CHANNEL2_ISPITCH),a
    jr PLY_AKG_CHANNEL2_GLIDE_END
PLY_AKG_CHANNEL2_ARPEGGIOTABLESPEED: .db 0
PLY_AKG_CHANNEL2_ARPEGGIOBASESPEED: .db 0
PLY_AKG_CHANNEL2_ARPEGGIOTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL2_PITCHTABLESPEED: .db 0
PLY_AKG_CHANNEL2_PITCHBASESPEED: .db 0
PLY_AKG_CHANNEL2_PITCHTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL2_AFTERARPEGGIOPITCHVARIABLES:
PLY_AKG_CHANNEL2_GLIDE_BEFOREEND:
PLY_AKG_CHANNEL2_GLIDE_SAVEHL: ld hl,#0
PLY_AKG_CHANNEL2_GLIDE_END: .db 221
    .db 77
PLY_AKG_CHANNEL2_PITCH_END: add hl,de
    ld (PLY_AKG_CHANNEL2_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS+1),hl
    ld a,c
    ld (PLY_AKG_CHANNEL2_GENERATEDCURRENTARPNOTE+1),a
PLY_AKG_CHANNEL3_INVERTEDVOLUMEINTEGER = .+2
PLY_AKG_CHANNEL3_INVERTEDVOLUMEINTEGERANDDECIMAL: ld hl,#0
PLY_AKG_CHANNEL3_ISVOLUMESLIDE: or a
    jr nc,PLY_AKG_CHANNEL3_VOLUMESLIDE_END
PLY_AKG_CHANNEL3_VOLUMESLIDEVALUE: ld de,#0
    add hl,de
    bit 7,h
    jr z,PLY_AKG_CHANNEL3_VOLUMENOTOVERFLOW
    ld h,#0
    jr PLY_AKG_CHANNEL3_VOLUMESETAGAIN
PLY_AKG_CHANNEL3_VOLUMENOTOVERFLOW: ld a,h
    cp #16
    jr c,PLY_AKG_CHANNEL3_VOLUMESETAGAIN
    ld h,#15
PLY_AKG_CHANNEL3_VOLUMESETAGAIN: ld (PLY_AKG_CHANNEL3_INVERTEDVOLUMEINTEGERANDDECIMAL+1),hl
PLY_AKG_CHANNEL3_VOLUMESLIDE_END: ld a,h
    ld (PLY_AKG_CHANNEL3_GENERATEDCURRENTINVERTEDVOLUME+1),a
    ld c,#0
PLY_AKG_CHANNEL3_ISARPEGGIOTABLE: or a
    jr nc,PLY_AKG_CHANNEL3_ARPEGGIOTABLE_END
PLY_AKG_CHANNEL3_ARPEGGIOTABLE: ld hl,#0
    ld a,(hl)
    cp #128
    jr nz,PLY_AKG_CHANNEL3_ARPEGGIOTABLE_AFTERLOOPTEST
    inc hl
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ld a,(hl)
PLY_AKG_CHANNEL3_ARPEGGIOTABLE_AFTERLOOPTEST: ld c,a
    ld a,(PLY_AKG_CHANNEL3_ARPEGGIOTABLESPEED)
    ld d,a
PLY_AKG_CHANNEL3_ARPEGGIOTABLECURRENTSTEP: ld a,#0
    inc a
    cp d
    jr c,PLY_AKG_CHANNEL3_ARPEGGIOTABLE_BEFOREEND_SAVESTEP
    inc hl
    ld (PLY_AKG_CHANNEL3_ARPEGGIOTABLE+1),hl
    xor a
PLY_AKG_CHANNEL3_ARPEGGIOTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL3_ARPEGGIOTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL3_ARPEGGIOTABLE_END: ld de,#0
PLY_AKG_CHANNEL3_ISPITCHTABLE: or a
    jr nc,PLY_AKG_CHANNEL3_PITCHTABLE_END
PLY_AKG_CHANNEL3_PITCHTABLE: ld sp,#0
    pop de
    pop hl
    ld a,(PLY_AKG_CHANNEL3_PITCHTABLESPEED)
    ld b,a
PLY_AKG_CHANNEL3_PITCHTABLECURRENTSTEP: ld a,#0
    inc a
    cp b
    jr c,PLY_AKG_CHANNEL3_PITCHTABLE_BEFOREEND_SAVESTEP
    ld (PLY_AKG_CHANNEL3_PITCHTABLE+1),hl
    xor a
PLY_AKG_CHANNEL3_PITCHTABLE_BEFOREEND_SAVESTEP: ld (PLY_AKG_CHANNEL3_PITCHTABLECURRENTSTEP+1),a
PLY_AKG_CHANNEL3_PITCHTABLE_END:
PLY_AKG_CHANNEL3_PITCH: ld hl,#0
PLY_AKG_CHANNEL3_ISPITCH: or a
    jr nc,PLY_AKG_CHANNEL3_PITCH_END
    .db 221
    .db 105
PLY_AKG_CHANNEL3_PITCHTRACK: ld bc,#0
    or a
PLY_AKG_CHANNEL3_PITCHTRACKADDORSBC_16BITS: nop
    add hl,bc
PLY_AKG_CHANNEL3_PITCHTRACKDECIMALCOUNTER: ld a,#0
PLY_AKG_CHANNEL3_PITCHTRACKDECIMALVALUE = .+1
PLY_AKG_CHANNEL3_PITCHTRACKDECIMALINSTR: add a,#0
    ld (PLY_AKG_CHANNEL3_PITCHTRACKDECIMALCOUNTER+1),a
    jr nc,PLY_AKG_CHANNEL3_PITCHNOCARRY
PLY_AKG_CHANNEL3_PITCHTRACKINTEGERADDORSUB: inc hl
PLY_AKG_CHANNEL3_PITCHNOCARRY: ld (PLY_AKG_CHANNEL3_PITCHTABLE_END+1),hl
PLY_AKG_CHANNEL3_SOUNDSTREAM_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL3_GLIDEDIRECTION: ld a,#0
    or a
    jr z,PLY_AKG_CHANNEL3_GLIDE_END
    ld (PLY_AKG_CHANNEL3_AFTERARPEGGIOPITCHVARIABLES+1),hl
    ld c,l
    ld b,h
    ex af,af'
    ld a,(PLY_AKG_CHANNEL3_TRACKNOTE+1)
    add a,a
    ld l,a
    ex af,af'
    ld h,#0
    ld sp,#PLY_AKG_PERIODTABLE
    add hl,sp
    ld sp,hl
    pop hl
    dec sp
    dec sp
    add hl,bc
PLY_AKG_CHANNEL3_GLIDETOREACH: ld bc,#0
    rra 
    jr nc,PLY_AKG_CHANNEL3_GLIDEDOWNCHECK
    or a
    sbc hl,bc
    jr nc,PLY_AKG_CHANNEL3_AFTERARPEGGIOPITCHVARIABLES
    jr PLY_AKG_CHANNEL3_GLIDEOVER
PLY_AKG_CHANNEL3_GLIDEDOWNCHECK: sbc hl,bc
    jr c,PLY_AKG_CHANNEL3_AFTERARPEGGIOPITCHVARIABLES
PLY_AKG_CHANNEL3_GLIDEOVER: ld l,c
    ld h,b
    pop bc
    or a
    sbc hl,bc
    ld (PLY_AKG_CHANNEL3_PITCHTABLE_END+1),hl
    ld a,#183
    ld (PLY_AKG_CHANNEL3_ISPITCH),a
    jr PLY_AKG_CHANNEL3_GLIDE_END
PLY_AKG_CHANNEL3_ARPEGGIOTABLESPEED: .db 0
PLY_AKG_CHANNEL3_ARPEGGIOBASESPEED: .db 0
PLY_AKG_CHANNEL3_ARPEGGIOTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL3_PITCHTABLESPEED: .db 0
PLY_AKG_CHANNEL3_PITCHBASESPEED: .db 0
PLY_AKG_CHANNEL3_PITCHTABLEBASE: .db 0
    .db 0
PLY_AKG_CHANNEL3_AFTERARPEGGIOPITCHVARIABLES:
PLY_AKG_CHANNEL3_GLIDE_BEFOREEND:
PLY_AKG_CHANNEL3_GLIDE_SAVEHL: ld hl,#0
PLY_AKG_CHANNEL3_GLIDE_END: .db 221
    .db 77
PLY_AKG_CHANNEL3_PITCH_END: add hl,de
    ld (PLY_AKG_CHANNEL3_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS+1),hl
    ld a,c
    ld (PLY_AKG_CHANNEL3_GENERATEDCURRENTARPNOTE+1),a
    ld sp,(PLY_AKG_PSGREG13_END+1)
PLY_AKG_CHANNEL1_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL1_GENERATEDCURRENTPITCH: ld hl,#0
PLY_AKG_CHANNEL1_TRACKNOTE: ld a,#0
PLY_AKG_CHANNEL1_GENERATEDCURRENTARPNOTE: add a,#0
    ld e,a
    ld d,#0
    exx
PLY_AKG_CHANNEL1_INSTRUMENTSTEP: .db 253
    .db 46
    .db 0
PLY_AKG_CHANNEL1_PTINSTRUMENT: ld hl,#0
PLY_AKG_CHANNEL1_GENERATEDCURRENTINVERTEDVOLUME: ld de,#57359
    call PLY_AKG_READINSTRUMENTCELL
    .db 253
    .db 125
    inc a
PLY_AKG_CHANNEL1_INSTRUMENTSPEED: cp #0
    jr c,PLY_AKG_CHANNEL1_SETINSTRUMENTSTEP
    ld (PLY_AKG_CHANNEL1_PTINSTRUMENT+1),hl
    xor a
PLY_AKG_CHANNEL1_SETINSTRUMENTSTEP: ld (PLY_AKG_CHANNEL1_INSTRUMENTSTEP+2),a
    ld a,e
    ld (PLY_AKG_PSGREG8),a
    srl d
    exx
    ld (PLY_AKG_PSGREG01_INSTR+1),hl
PLY_AKG_CHANNEL2_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL2_GENERATEDCURRENTPITCH: ld hl,#0
PLY_AKG_CHANNEL2_TRACKNOTE: ld a,#0
PLY_AKG_CHANNEL2_GENERATEDCURRENTARPNOTE: add a,#0
    ld e,a
    ld d,#0
    exx
PLY_AKG_CHANNEL2_INSTRUMENTSTEP: .db 253
    .db 46
    .db 0
PLY_AKG_CHANNEL2_PTINSTRUMENT: ld hl,#0
PLY_AKG_CHANNEL2_GENERATEDCURRENTINVERTEDVOLUME: ld e,#15
    nop
    call PLY_AKG_READINSTRUMENTCELL
    .db 253
    .db 125
    inc a
PLY_AKG_CHANNEL2_INSTRUMENTSPEED: cp #0
    jr c,PLY_AKG_CHANNEL2_SETINSTRUMENTSTEP
    ld (PLY_AKG_CHANNEL2_PTINSTRUMENT+1),hl
    xor a
PLY_AKG_CHANNEL2_SETINSTRUMENTSTEP: ld (PLY_AKG_CHANNEL2_INSTRUMENTSTEP+2),a
    ld a,e
    ld (PLY_AKG_PSGREG9),a
    srl d
    exx
    ld (PLY_AKG_PSGREG23_INSTR+1),hl
PLY_AKG_CHANNEL3_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS:
PLY_AKG_CHANNEL3_GENERATEDCURRENTPITCH: ld hl,#0
PLY_AKG_CHANNEL3_TRACKNOTE: ld a,#0
PLY_AKG_CHANNEL3_GENERATEDCURRENTARPNOTE: add a,#0
    ld e,a
    ld d,#0
    exx
PLY_AKG_CHANNEL3_INSTRUMENTSTEP: .db 253
    .db 46
    .db 0
PLY_AKG_CHANNEL3_PTINSTRUMENT: ld hl,#0
PLY_AKG_CHANNEL3_GENERATEDCURRENTINVERTEDVOLUME: ld e,#15
    nop
    call PLY_AKG_READINSTRUMENTCELL
    .db 253
    .db 125
    inc a
PLY_AKG_CHANNEL3_INSTRUMENTSPEED: cp #0
    jr c,PLY_AKG_CHANNEL3_SETINSTRUMENTSTEP
    ld (PLY_AKG_CHANNEL3_PTINSTRUMENT+1),hl
    xor a
PLY_AKG_CHANNEL3_SETINSTRUMENTSTEP: ld (PLY_AKG_CHANNEL3_INSTRUMENTSTEP+2),a
    ld a,e
    ld (PLY_AKG_PSGREG10),a
    ld a,d
    exx
    ld (PLY_AKG_PSGREG45_INSTR+1),hl
    call PLY_AKG_PLAYSOUNDEFFECTSSTREAM
PLY_AKG_SENDPSGREGISTERS: ld bc,#63104
    ld e,#192
    out (c),e
    exx
    ld bc,#62465
PLY_AKG_PSGREG01_INSTR: ld hl,#0
    .db 237
    .db 113
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGREG23_INSTR: ld hl,#0
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGREG45_INSTR: ld hl,#0
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGREG6 = .+1
PLY_AKG_PSGREG8 = .+2
PLY_AKG_PSGREG6_8_INSTR: ld hl,#0
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),a
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGREG9 = .+1
PLY_AKG_PSGREG10 = .+2
PLY_AKG_PSGREG9_10_INSTR: ld hl,#0
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGHARDWAREPERIOD_INSTR: ld hl,#0
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),l
    exx
    out (c),c
    out (c),e
    exx
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),h
    exx
    out (c),c
    out (c),e
    exx
PLY_AKG_PSGREG13_OLDVALUE: ld a,#255
PLY_AKG_RETRIG: or #0
PLY_AKG_PSGREG13_INSTR: ld l,#0
    cp l
    jr z,PLY_AKG_PSGREG13_END
    ld a,l
    ld (PLY_AKG_PSGREG13_OLDVALUE+1),a
    inc c
    out (c),c
    exx
    .db 237
    .db 113
    exx
    out (c),a
    exx
    out (c),c
    out (c),e
    xor a
    ld (PLY_AKG_RETRIG+1),a
PLY_AKG_PSGREG13_END:
PLY_AKG_SAVESP: ld sp,#0
    ret 
PLY_AKG_CHANNEL1_MAYBEEFFECTS: ld (PLY_AKG_EVENTTRACK_END+1),a
    bit 6,c
    jp z,PLY_AKG_CHANNEL1_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL1_READEFFECTS: ld iy,#PLY_AKG_CHANNEL1_SOUNDSTREAM_RELATIVEMODIFIERADDRESS
    ld ix,#PLY_AKG_CHANNEL1_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS
    ld de,#PLY_AKG_CHANNEL1_BEFOREEND_STORECELLPOINTER
    jr PLY_AKG_CHANNEL3_READEFFECTSEND
PLY_AKG_CHANNEL1_READEFFECTSEND:
PLY_AKG_CHANNEL2_MAYBEEFFECTS: ld (PLY_AKG_CHANNEL1_READCELLEND+1),a
    bit 6,c
    jp z,PLY_AKG_CHANNEL2_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL2_READEFFECTS: ld iy,#PLY_AKG_CHANNEL2_SOUNDSTREAM_RELATIVEMODIFIERADDRESS
    ld ix,#PLY_AKG_CHANNEL2_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS
    ld de,#PLY_AKG_CHANNEL2_BEFOREEND_STORECELLPOINTER
    jr PLY_AKG_CHANNEL3_READEFFECTSEND
PLY_AKG_CHANNEL2_READEFFECTSEND:
PLY_AKG_CHANNEL3_MAYBEEFFECTS: ld (PLY_AKG_CHANNEL2_READCELLEND+1),a
    bit 6,c
    jp z,PLY_AKG_CHANNEL3_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL3_READEFFECTS: ld iy,#PLY_AKG_CHANNEL3_SOUNDSTREAM_RELATIVEMODIFIERADDRESS
    ld ix,#PLY_AKG_CHANNEL3_PLAYINSTRUMENT_RELATIVEMODIFIERADDRESS
    ld de,#PLY_AKG_CHANNEL3_BEFOREEND_STORECELLPOINTER
PLY_AKG_CHANNEL3_READEFFECTSEND:
PLY_AKG_CHANNEL_READEFFECTS: ld (PLY_AKG_CHANNEL_READEFFECTS_ENDJUMP+1),de
    ex de,hl
    ld a,(de)
    inc de
    sla a
    jr c,PLY_AKG_CHANNEL_READEFFECTS_RELATIVEADDRESS
    exx
    ld l,a
    ld h,#0
PLY_AKG_CHANNEL_READEFFECTS_EFFECTBLOCKS1: ld de,#0
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
PLY_AKG_CHANNEL_RE_EFFECTADDRESSKNOWN: ld a,(de)
    inc de
    ld (PLY_AKG_CHANNEL_RE_EFFECTRETURN+1),a
    and #254
    ld l,a
    ld h,#0
    ld sp,#PLY_AKG_EFFECTTABLE
    add hl,sp
    ld sp,hl
    ret 
PLY_AKG_CHANNEL_RE_EFFECTRETURN:
PLY_AKG_CHANNEL_RE_READNEXTEFFECTINBLOCK: ld a,#0
    rra 
    jr c,PLY_AKG_CHANNEL_RE_EFFECTADDRESSKNOWN
    exx
    ex de,hl
PLY_AKG_CHANNEL_READEFFECTS_ENDJUMP: jp 0
PLY_AKG_CHANNEL_READEFFECTS_RELATIVEADDRESS: srl a
    exx
    ld h,a
    exx
    ld a,(de)
    inc de
    exx
    ld l,a
PLY_AKG_CHANNEL_READEFFECTS_EFFECTBLOCKS2: ld de,#0
    add hl,de
    ex de,hl
    jr PLY_AKG_CHANNEL_RE_EFFECTADDRESSKNOWN
PLY_AKG_READINSTRUMENTCELL: ld a,(hl)
    inc hl
    ld b,a
    rra 
    jp c,PLY_AKG_S_OR_H_OR_SAH_OR_ENDWITHLOOP
    rra 
    jr c,PLY_AKG_STH_OR_ENDWITHOUTLOOP
    rra 
    jr c,PLY_AKG_HARDTOSOFT
PLY_AKG_NOSOFTNOHARD: and #15
    sub e
    jr nc,PLY_AKG_NOSOFTNOHARD+6
    xor a
    ld e,a
    rl b
    jr nc,PLY_AKG_NSNH_NONOISE
    ld a,(hl)
    inc hl
    ld (PLY_AKG_PSGREG6),a
    set 2,d
    res 5,d
    ret 
PLY_AKG_NSNH_NONOISE: set 2,d
    ret 
PLY_AKG_SOFT: and #15
    sub e
    jr nc,PLY_AKG_SOFTONLY_HARDONLY_TESTSIMPLE_COMMON-1
    xor a
    ld e,a
PLY_AKG_SOFTONLY_HARDONLY_TESTSIMPLE_COMMON: rl b
    jr nc,PLY_AKG_S_NOTSIMPLE
    ld c,#0
    jr PLY_AKG_S_AFTERSIMPLETEST
PLY_AKG_S_NOTSIMPLE: ld b,(hl)
    ld c,b
    inc hl
PLY_AKG_S_AFTERSIMPLETEST: call PLY_AKG_S_OR_H_CHECKIFSIMPLEFIRST_CALCULATEPERIOD
    ld a,c
    and #31
    ret z
    ld (PLY_AKG_PSGREG6),a
    res 5,d
    ret 
PLY_AKG_HARDTOSOFT: call PLY_AKG_STOH_HTOS_SANDH_COMMON
    ld (PLY_AKG_HS_JUMPRATIO+1),a
    ld a,b
    exx
    ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+1),hl
PLY_AKG_HS_JUMPRATIO: jr PLY_AKG_HS_JUMPRATIO+2
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    rla 
    jr nc,PLY_AKG_SH_NOSOFTWAREPITCHSHIFT
    exx
    ld a,(hl)
    inc hl
    exx
    add a,l
    ld l,a
    exx
    ld a,(hl)
    inc hl
    exx
    adc a,h
    ld h,a
PLY_AKG_SH_NOSOFTWAREPITCHSHIFT: exx
    ret 
PLY_AKG_ENDWITHOUTLOOP:
PLY_AKG_EMPTYINSTRUMENTDATAPT: ld hl,#0
    inc hl
    xor a
    ld b,a
    jr PLY_AKG_NOSOFTNOHARD
PLY_AKG_STH_OR_ENDWITHOUTLOOP: rra 
    jr c,PLY_AKG_ENDWITHOUTLOOP
    call PLY_AKG_STOH_HTOS_SANDH_COMMON
    ld (PLY_AKG_SH_JUMPRATIO+1),a
    ld a,b
    exx
    ld e,l
    ld d,h
PLY_AKG_SH_JUMPRATIO: jr PLY_AKG_SH_JUMPRATIO+2
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    jr nc,PLY_AKG_SH_JUMPRATIOEND
    inc hl
PLY_AKG_SH_JUMPRATIOEND: rla 
    jr nc,PLY_AKG_SH_NOHARDWAREPITCHSHIFT
    exx
    ld a,(hl)
    inc hl
    exx
    add a,l
    ld l,a
    exx
    ld a,(hl)
    inc hl
    exx
    adc a,h
    ld h,a
PLY_AKG_SH_NOHARDWAREPITCHSHIFT: ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+1),hl
    ex de,hl
    exx
    ret 
PLY_AKG_S_OR_H_OR_SAH_OR_ENDWITHLOOP: rra 
    jr c,PLY_AKG_H_OR_ENDWITHLOOP
    rra 
    jp nc,PLY_AKG_SOFT
    exx
    push hl
    push de
    exx
    call PLY_AKG_STOH_HTOS_SANDH_COMMON
    exx
    ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+1),hl
    pop de
    pop hl
    exx
    rl b
    jp PLY_AKG_S_OR_H_CHECKIFSIMPLEFIRST_CALCULATEPERIOD
PLY_AKG_H_OR_ENDWITHLOOP: rra 
    jr c,PLY_AKG_ENDWITHLOOP
    ld e,#16
    rra 
    jr nc,PLY_AKG_H_AFTERRETRIG
    ld c,a
    .db 253
    .db 125
    or a
    jr nz,PLY_AKG_H_RETRIGEND
    ld a,e
    ld (PLY_AKG_RETRIG+1),a
PLY_AKG_H_RETRIGEND: ld a,c
PLY_AKG_H_AFTERRETRIG: and #7
    add a,#8
    ld (PLY_AKG_PSGREG13_INSTR+1),a
    call PLY_AKG_SOFTONLY_HARDONLY_TESTSIMPLE_COMMON
    exx
    ld (PLY_AKG_PSGHARDWAREPERIOD_INSTR+1),hl
    exx
    set 2,d
    ret 
PLY_AKG_ENDWITHLOOP: ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    jp PLY_AKG_READINSTRUMENTCELL
PLY_AKG_S_OR_H_CHECKIFSIMPLEFIRST_CALCULATEPERIOD: jr nc,PLY_AKG_S_OR_H_NEXTBYTE
    exx
    ex de,hl
    add hl,hl
    ld bc,#PLY_AKG_PERIODTABLE
    add hl,bc
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    add hl,de
    exx
    rl b
    rl b
    rl b
    ret 
PLY_AKG_S_OR_H_NEXTBYTE: rl b
    jr c,PLY_AKG_S_OR_H_FORCEDPERIOD
    rl b
    jr nc,PLY_AKG_S_OR_H_AFTERARPEGGIO
    ld a,(hl)
    inc hl
    exx
    add a,e
    ld e,a
    exx
PLY_AKG_S_OR_H_AFTERARPEGGIO: rl b
    jr nc,PLY_AKG_S_OR_H_AFTERPITCH
    ld a,(hl)
    inc hl
    exx
    add a,l
    ld l,a
    exx
    ld a,(hl)
    inc hl
    exx
    adc a,h
    ld h,a
    exx
PLY_AKG_S_OR_H_AFTERPITCH: exx
    ex de,hl
    add hl,hl
    ld bc,#PLY_AKG_PERIODTABLE
    add hl,bc
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    add hl,de
    exx
    ret 
PLY_AKG_S_OR_H_FORCEDPERIOD: ld a,(hl)
    inc hl
    exx
    ld l,a
    exx
    ld a,(hl)
    inc hl
    exx
    ld h,a
    exx
    rl b
    rl b
    ret 
PLY_AKG_STOH_HTOS_SANDH_COMMON: ld e,#16
    rra 
    jr nc,PLY_AKG_SHOHS_AFTERRETRIG
    ld c,a
    .db 253
    .db 125
    or a
    jr nz,PLY_AKG_SHOHS_RETRIGEND
    dec a
    ld (PLY_AKG_RETRIG+1),a
PLY_AKG_SHOHS_RETRIGEND: ld a,c
PLY_AKG_SHOHS_AFTERRETRIG: and #7
    add a,#8
    ld (PLY_AKG_PSGREG13_INSTR+1),a
    rl b
    jr nc,PLY_AKG_SHOHS_AFTERNOISE
    ld a,(hl)
    inc hl
    ld (PLY_AKG_PSGREG6),a
    res 5,d
PLY_AKG_SHOHS_AFTERNOISE: ld c,(hl)
    ld b,c
    inc hl
    rl b
    call PLY_AKG_S_OR_H_CHECKIFSIMPLEFIRST_CALCULATEPERIOD
    ld a,c
    rla 
    rla 
    and #28
    ret 
PLY_AKG_EFFECTTABLE: .dw PLY_AKG_EFFECT_RESETFULLVOLUME
    .dw PLY_AKG_EFFECT_RESET
    .dw PLY_AKG_EFFECT_VOLUME
    .dw PLY_AKG_EFFECT_ARPEGGIOTABLE
    .dw PLY_AKG_EFFECT_ARPEGGIOTABLESTOP
    .dw PLY_AKG_EFFECT_PITCHTABLE
    .dw PLY_AKG_EFFECT_PITCHTABLESTOP
    .dw PLY_AKG_EFFECT_VOLUMESLIDE
    .dw PLY_AKG_EFFECT_VOLUMESLIDESTOP
    .dw PLY_AKG_EFFECT_PITCHUP
    .dw PLY_AKG_EFFECT_PITCHDOWN
    .dw PLY_AKG_EFFECT_PITCHSTOP
    .dw PLY_AKG_EFFECT_GLIDEWITHNOTE
    .dw PLY_AKG_EFFECT_GLIDE_READSPEED
    .dw PLY_AKG_EFFECT_LEGATO
    .dw PLY_AKG_EFFECT_FORCEINSTRUMENTSPEED
    .dw PLY_AKG_EFFECT_FORCEARPEGGIOSPEED
    .dw PLY_AKG_EFFECT_FORCEPITCHSPEED
PLY_AKG_EFFECT_RESETFULLVOLUME: xor a
    jr PLY_AKG_EFFECT_RESETVOLUME_AFTERREADING
PLY_AKG_EFFECT_RESET: ld a,(de)
    inc de
PLY_AKG_EFFECT_RESETVOLUME_AFTERREADING: ld -123(iy),a
    xor a
    ld -26(iy),a
    ld -25(iy),a
    ld a,#183
    ld -24(iy),a
    ld -52(iy),a
    ld -91(iy),a
    ld -122(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_VOLUME: ld a,(de)
    inc de
    ld -123(iy),a
    ld -122(iy),#183
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_ARPEGGIOTABLE: ld a,(de)
    inc de
    ld l,a
    ld h,#0
    add hl,hl
PLY_AKG_ARPEGGIOSTABLE: ld bc,#0
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    ld a,(bc)
    inc bc
    ld +61(iy),a
    ld +62(iy),a
    ld -87(iy),c
    ld -86(iy),b
    ld +63(iy),c
    ld +64(iy),b
    ld -91(iy),#55
    xor a
    ld -68(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_ARPEGGIOTABLESTOP: ld -91(iy),#183
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_PITCHTABLE: ld a,(de)
    inc de
    ld l,a
    ld h,#0
    add hl,hl
PLY_AKG_PITCHESTABLE: ld bc,#0
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    ld a,(bc)
    inc bc
    ld +65(iy),a
    ld +66(iy),a
    ld -48(iy),c
    ld -47(iy),b
    ld +67(iy),c
    ld +68(iy),b
    ld -52(iy),#55
    xor a
    ld -39(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_PITCHTABLESTOP: ld -52(iy),#183
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_VOLUMESLIDE: ld a,(de)
    inc de
    ld -118(iy),a
    ld a,(de)
    inc de
    ld -117(iy),a
    ld -122(iy),#55
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_VOLUMESLIDESTOP: ld -122(iy),#183
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_PITCHDOWN: ld -15(iy),#0
    ld -14(iy),#9
    ld -11(iy),#198
    ld -4(iy),#35
PLY_AKG_EFFECT_PITCHUPDOWN_COMMON: ld -24(iy),#55
    ld +1(iy),#0
    ld a,(de)
    inc de
    ld -10(iy),a
    ld a,(de)
    inc de
    ld -18(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_PITCHUP: ld -15(iy),#237
    ld -14(iy),#66
    ld -11(iy),#214
    ld -4(iy),#43
    jr PLY_AKG_EFFECT_PITCHUPDOWN_COMMON
PLY_AKG_EFFECT_PITCHSTOP: ld -24(iy),#183
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_GLIDEWITHNOTE: ld a,(de)
    inc de
    ld (PLY_AKG_EFFECT_GLIDEWITHNOTESAVEDE+1),de
    add a,a
    ld l,a
    ld h,#0
    ld bc,#PLY_AKG_PERIODTABLE
    add hl,bc
    ld sp,hl
    pop de
    ld +29(iy),e
    ld +30(iy),d
    ld a,+4(ix)
    add a,a
    ld l,a
    ld h,#0
    add hl,bc
    ld sp,hl
    pop hl
    ld c,-26(iy)
    ld b,-25(iy)
    add hl,bc
    or a
    sbc hl,de
PLY_AKG_EFFECT_GLIDEWITHNOTESAVEDE: ld de,#0
    jr c,PLY_AKG_EFFECT_GLIDE_PITCHDOWN
    ld +1(iy),#1
    ld -15(iy),#237
    ld -14(iy),#66
    ld -11(iy),#214
    ld -4(iy),#43
PLY_AKG_EFFECT_GLIDE_READSPEED:
PLY_AKG_EFFECT_GLIDESPEED: ld a,(de)
    inc de
    ld -10(iy),a
    ld a,(de)
    inc de
    ld -18(iy),a
    ld a,#55
    ld -24(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_GLIDE_PITCHDOWN: ld +1(iy),#2
    ld -15(iy),#0
    ld -14(iy),#9
    ld -11(iy),#198
    ld -4(iy),#35
    jr PLY_AKG_EFFECT_GLIDE_READSPEED
PLY_AKG_EFFECT_LEGATO: ld a,(de)
    inc de
    ld +4(ix),a
    ld a,#183
    ld -24(iy),a
    xor a
    ld -26(iy),a
    ld -25(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_FORCEINSTRUMENTSPEED: ld a,(de)
    inc de
    ld +27(ix),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_FORCEARPEGGIOSPEED: ld a,(de)
    inc de
    ld +61(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EFFECT_FORCEPITCHSPEED: ld a,(de)
    inc de
    ld +65(iy),a
    jp PLY_AKG_CHANNEL_RE_EFFECTRETURN
PLY_AKG_EVENT: .db 0
PLY_AKG_PERIODTABLE: .dw 3822
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
    .dw 1911
    .dw 1804
    .dw 1703
    .dw 1607
    .dw 1517
    .dw 1432
    .dw 1351
    .dw 1276
    .dw 1204
    .dw 1136
    .dw 1073
    .dw 1012
    .dw 956
    .dw 902
    .dw 851
    .dw 804
    .dw 758
    .dw 716
    .dw 676
    .dw 638
    .dw 602
    .dw 568
    .dw 536
    .dw 506
    .dw 478
    .dw 451
    .dw 426
    .dw 402
    .dw 379
    .dw 358
    .dw 338
    .dw 319
    .dw 301
    .dw 284
    .dw 268
    .dw 253
    .dw 239
    .dw 225
    .dw 213
    .dw 201
    .dw 190
    .dw 179
    .dw 169
    .dw 159
    .dw 150
    .dw 142
    .dw 134
    .dw 127
    .dw 119
    .dw 113
    .dw 106
    .dw 100
    .dw 95
    .dw 89
    .dw 84
    .dw 80
    .dw 75
    .dw 71
    .dw 67
    .dw 63
    .dw 60
    .dw 56
    .dw 53
    .dw 50
    .dw 47
    .dw 45
    .dw 42
    .dw 40
    .dw 38
    .dw 36
    .dw 34
    .dw 32
    .dw 30
    .dw 28
    .dw 27
    .dw 25
    .dw 24
    .dw 22
    .dw 21
    .dw 20
    .dw 19
    .dw 18
    .dw 17
    .dw 16
    .dw 15
    .dw 14
    .dw 13
    .dw 13
    .dw 12
    .dw 11
    .dw 11
    .dw 10
    .dw 9
    .dw 9
    .dw 8
    .dw 8
    .dw 7
    .dw 7
    .dw 7
    .dw 6
    .dw 6
    .dw 6
    .dw 5
    .dw 5
    .dw 5
    .dw 4
    .dw 4
    .dw 4
    .dw 4
    .dw 4
    .dw 3
    .dw 3
    .dw 3
    .dw 3
    .dw 3
    .dw 2

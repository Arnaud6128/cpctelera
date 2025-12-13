;       Stand-alone player of sound effects player.
;       By Targhan/Arkos, January 2017.
;       Psg optimization trick on CPC by Madram/Overlanders.
;
;       If you want to play sound effects along with music, check the related sound effects player besides the player!

;       This compiles with RASM. Check the compatibility page on the Arkos Tracker 2 website, it contains a source converter to any Z80 assembler!
;
;       Target hardware:
;       ---------------
;       This code can target Amstrad CPC, MSX, Spectrum and Pentagon. By default, it targets Amstrad CPC.
;       Simply use one of the follow line (BEFORE this player):
;       PLY_SE_HARDWARE_CPC = 1
;       PLY_SE_HARDWARE_MSX = 1
;       PLY_SE_HARDWARE_SPECTRUM = 1
;       PLY_SE_HARDWARE_PENTAGON = 1
;       Note that the PRESENCE of this variable is tested, NOT its value.
;
;       ROM
;       ----------------------
;       To use a ROM player (no automodification, use of a small buffer to put in RAM):
;       PLY_SE_Rom = 1
;       PLY_SE_ROM_Buffer = #4000 (or wherever).
;       This makes the player a bit slower and slightly bigger.
;       The buffer is PLY_SE_ROM_BufferSize bytes long (41 bytes max).

;       Some severe optimizations of CPU/memory can be performed:
;       ---------------------------------------------------------
;       - Use the Player Configuration of Arkos Tracker 2 to generate a configuration file to be included at the beginning of this player.
;         It will disable useless features according to your songs! Check the online manual for more details.
;       - If you don't stop sound effects (via code), you can reset the flag PLY_SE_UseStopSounds just below to remove the code that makes it possible.

PLY_SE_UseStopSounds equ 1                             ;If 0, the code to stop the sounds (by code) is not compiled.


        ;Checks the hardware. Only one must be selected.
PLY_SE_HardwareCounter = 0
        IFDEF PLY_SE_HARDWARE_CPC
                PLY_SE_HardwareCounter = PLY_SE_HardwareCounter + 1
        ENDIF
        IFDEF PLY_SE_HARDWARE_MSX
                PLY_SE_HardwareCounter = PLY_SE_HardwareCounter + 1
                PLY_SE_HARDWARE_SPECTRUM_OR_MSX = 1
        ENDIF
        IFDEF PLY_SE_HARDWARE_SPECTRUM
                PLY_SE_HardwareCounter = PLY_SE_HardwareCounter + 1
                PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON = 1
                PLY_SE_HARDWARE_SPECTRUM_OR_MSX = 1
        ENDIF
        IFDEF PLY_SE_HARDWARE_PENTAGON
                PLY_SE_HardwareCounter = PLY_SE_HardwareCounter + 1
                PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON = 1
        ENDIF
        IFDEF PLY_SE_HARDWARECounter > 1
                FAIL 'Only one hardware must be selected!'
        ENDIF
        ;By default, selects the Amstrad CPC.
        IF PLY_SE_HARDWARECounter == 0
                PLY_SE_HARDWARE_CPC = 1
        ENDIF

        ;Is there a loaded Player Configuration source? If no, use a default configuration.
        IFNDEF PLY_CFG_SFX_ConfigurationIsPresent
                PLY_CFG_UseHardwareSounds = 1
                PLY_CFG_SFX_LoopTo = 1
                PLY_CFG_SFX_NoSoftNoHard = 1
                PLY_CFG_SFX_NoSoftNoHard_Noise = 1
                PLY_CFG_SFX_SoftOnly = 1
                PLY_CFG_SFX_SoftOnly_Noise = 1
                PLY_CFG_SFX_HardOnly = 1
                PLY_CFG_SFX_HardOnly_Noise = 1
                PLY_CFG_SFX_HardOnly_Retrig = 1
                PLY_CFG_SFX_SoftAndHard = 1
                PLY_CFG_SFX_SoftAndHard_Noise = 1
                PLY_CFG_SFX_SoftAndHard_Retrig = 1
        ENDIF

;       Agglomerates some Player Configuration flags.
;       --------------------------------------------
;       Mixes the Hardware flags into one.
        IFDEF PLY_CFG_SFX_HardOnly
                PLY_SE_HardwareSounds = 1
        ENDIF
        IFDEF PLY_CFG_SFX_SoftAndHard
                PLY_SE_HardwareSounds = 1
        ENDIF
;       Mixes the Hardware Noise flags into one.
        IFDEF PLY_CFG_SFX_HardOnly_Noise
                PLY_SE_HardwareNoise = 1
        ENDIF
        IFDEF PLY_CFG_SFX_SoftAndHard_Noise
                PLY_SE_HardwareNoise = 1
        ENDIF
;       Mixes the Noise flags into one.
        IFDEF PLY_SE_HardwareNoise
                PLY_SE_Noise = 1
        ENDIF
        IFDEF PLY_CFG_SFX_NoSoftNoHard_Noise
                PLY_SE_Noise = 1
        ENDIF
        IFDEF PLY_CFG_SFX_SoftOnly
                PLY_SE_Noise = 1
        ENDIF
;       Mixes the Software Volume flags into one.
        IFDEF PLY_CFG_SFX_NoSoftNoHard
                PLY_SE_VolumeSoft = 1
                PLY_SE_VolumeSoftOrHard = 1
        ENDIF
        IFDEF PLY_CFG_SFX_SoftOnly
                PLY_SE_VolumeSoft = 1
                PLY_SE_VolumeSoftOrHard = 1
        ENDIF
;       Mixes the volume (soft/hard) into one.
        IFDEF PLY_CFG_UseHardwareSounds
                PLY_SE_VolumeSoftOrHard = 1
        ENDIF
;       Mixes the retrig flags into one.
        IFDEF PLY_CFG_SFX_HardOnly_Retrig
                PLY_SE_UseRetrig = 1
        ENDIF
        IFDEF PLY_CFG_SFX_SoftAndHard_Retrig
                PLY_SE_UseRetrig = 1
        ENDIF


        ;Disark macro: Word region Start.
        disarkCounter = 0
        IFNDEF dkws
        MACRO dkws
PLY_SE_DisarkWordRegionStart_{disarkCounter}
        ENDM
        ENDIF
        ;Disark macro: Word region End.
        IFNDEF dkwe
        MACRO dkwe
PLY_SE_DisarkWordRegionEnd_{disarkCounter}:
        disarkCounter = disarkCounter + 1
        ENDM
        ENDIF
        
        ;Disark macro: Pointer region Start.
        disarkCounter = 0
        IFNDEF dkps
        MACRO dkps
PLY_SE_DisarkPointerRegionStart_{disarkCounter}
        ENDM
        ENDIF
        ;Disark macro: Pointer region End.
        IFNDEF dkpe
        MACRO dkpe
PLY_SE_DisarkPointerRegionEnd_{disarkCounter}:
        disarkCounter = disarkCounter + 1
        ENDM
        ENDIF
        
        ;Disark macro: Byte region Start.
        disarkCounter = 0
        IFNDEF dkbs
        MACRO dkbs
PLY_SE_DisarkByteRegionStart_{disarkCounter}
        ENDM
        ENDIF
        ;Disark macro: Byte region End.
        IFNDEF dkbe
        MACRO dkbe
PLY_SE_DisarkByteRegionEnd_{disarkCounter}:
        disarkCounter = disarkCounter + 1
        ENDM
        ENDIF

        ;Disark macro: Force "No Reference Area" for 3 bytes (ld hl,xxxx).
        IFNDEF dknr3
        MACRO dknr3
PLY_SE_DisarkForceNonReferenceDuring3_{disarkCounter}:
        disarkCounter = disarkCounter + 1
        ENDM
        ENDIF
        
;A nice trick to manage the offset using the same instructions, according to the player (ROM or not).
        IFDEF PLY_SE_Rom
PLY_SE_Offset1b equ 0
PLY_SE_Offset2b equ 0         ;Used for instructions such as ld iyh,xx
        ELSE
PLY_SE_Offset1b equ 1
PLY_SE_Offset2b equ 2
        ENDIF
        
        
;Initializes the sound effects. It MUST be called at any times before a first sound effect is triggered.
;It doesn't matter whether the song is playing or not, or if it has been initialized or not.
;IN:    HL = Address to the sound effects data.
PLY_SE_InitSoundEffectsDisarkGenerateExternalLabel:
PLY_SE_InitSoundEffects:
        ld (PLY_SE_PtSoundEffectTable + PLY_SE_Offset1b),hl
        
        ;No need to set up the ROM buffer, except for R13 old value, as a security.
        IFDEF PLY_SE_Rom
                ld a,255
                ld (PLY_SE_PSGReg13_OldValue),a
        ENDIF
        
        ;Stops all the sounds. Especially useful for the ROM buffer!
dknr3 (void): ld hl,0
        ld (PLY_SE_Channel1_SoundEffectData),hl
        ld (PLY_SE_Channel2_SoundEffectData),hl
        ld (PLY_SE_Channel3_SoundEffectData),hl
        ret


;Programs the playing of a sound effect. If a previous one was already playing on the same channel, it is replaced.
;This does not actually plays the sound effect, but programs its playing.
;Once done, call PLY_SE_Play, every frame.
;IN:    A = Sound effect number (>0!).
;       C = The channel where to play the sound effect (0, 1, 2).
;       B = Inverted volume (0 = full volume, 16 = no sound). Hardware sounds are also lowered.
PLY_SE_PlaySoundEffectDisarkGenerateExternalLabel:
PLY_SE_PlaySoundEffect:
        ;Gets the address to the sound effect.
        dec a                   ;The 0th is not encoded.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PtSoundEffectTable: ld hl,0
        ELSE
        ld hl,(PLY_SE_PtSoundEffectTable)
        ENDIF
        ld e,a
        ld d,0
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ;Reads the header of the sound effect to get the speed.
        ld a,(de)
        inc de
        ex af,af'

        ld a,b

        ;Finds the pointer to the sound effect of the desired channel.
        ld hl,PLY_SE_Channel1_SoundEffectData
        ld b,0
        sla c
        sla c
        sla c
        add hl,bc
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl        
        
        ;Now stores the inverted volume.
        ld (hl),a
        inc hl
        
        ;Resets the current speed, stores the instrument speed.
        ld (hl),0
        inc hl
        ex af,af'
        ld (hl),a
        
        ret

        if PLY_SE_UseStopSounds
;Stops a sound effect. Nothing happens if there was no sound effect.
;Only when the PLY_SE_Play is called are the results heard.
;IN:    A = The channel where to stop the sound effect (0, 1, 2).
PLY_SE_StopSoundEffectFromChannelDisarkGenerateExternalLabel:
PLY_SE_StopSoundEffectFromChannel:
        ld c,a
        
        ;Puts 0 to the pointer of the sound effect.
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,PLY_SE_Channel1_SoundEffectData
        add hl,de
        ld (hl),d               ;0 means "no sound".
        inc hl
        ld (hl),d
        
        ;Makes sure the volume of the channel is 0, else hardware sounds will continue.
        ;Note: this *could* be done in two instructions when no sound is detected. But most of the time
        ;this is useless, so I decided to save some CPU and lose some memory here (plus, the current method can be removed if not used).
        ld hl,PLY_SE_PSGReg8
        ld a,c
        or a
        jr z,PLY_SE_StopSoundEffectFromChannel_FoundChannel
        ld hl,PLY_SE_PSGReg9
        dec a
        jr z,PLY_SE_StopSoundEffectFromChannel_FoundChannel
        ld hl,PLY_SE_PSGReg10
        dec a
PLY_SE_StopSoundEffectFromChannel_FoundChannel:
        ld (hl),a       ;Volume to 0.        
        ret
        endif ;PLY_SE_UseStopSounds

;Plays the sound effects, if any has been triggered by the user.
;This must be played every frame.
;This sends new data to the PSG. Of course, nothing will be heard unless some sound effects are programmed (via PLY_SE_ProgramSoundEffect).
;The sound effects initialization method must have been called once before!
PLY_SE_PlaySoundEffectsStreamDisarkGenerateExternalLabel:
PLY_SE_PlaySoundEffectsStream:
        ;Plays the sound effects on every track.
        ld ix,PLY_SE_Channel1_SoundEffectData
        ld iy,PLY_SE_PSGReg8
        ld hl,PLY_SE_PSGReg01_Instr + PLY_SE_Offset1b
        exx
        ld c,%11111100                  ;Shifts the R7 to the left twice, so that bit 2 and 5 only can be set for each track, below.
        call PLY_SE_PSES_Play
        ld ix,PLY_SE_Channel2_SoundEffectData
        ld iy,PLY_SE_PSGReg9
        exx
                ld hl,PLY_SE_PSGReg23_Instr + PLY_SE_Offset1b
        exx
        srl c                           ;Not RR, to make sure bit 6 is 0 (else, no more keyboard on CPC!).
                                        ;Also, on MSX, bit 6 must be 0.
        call PLY_SE_PSES_Play
        ld ix,PLY_SE_Channel3_SoundEffectData
        ld iy,PLY_SE_PSGReg10
        exx
                ld hl,PLY_SE_PSGReg45_Instr + PLY_SE_Offset1b
        exx
        IFDEF PLY_SE_HARDWARE_MSX
                scf             ;On MSX, bit 7 must be 1.
                rr c
        ELSE
                rr c            ;On other platforms, we don't care about b7.
        ENDIF
        call PLY_SE_PSES_Play

        ld a,c


; -----------------------------------------------------------------------------------
; PSG access.
; -----------------------------------------------------------------------------------

;Sends the registers to the PSG. Only general registers are sent, the specific ones have already been sent.
;IN:    A = R7.
PLY_SE_SendPSGRegisters:

        IFDEF PLY_SE_HARDWARE_CPC
                ld e,#c0
dknr3 (void):   ld bc,#f680
        	out (c),e	;#f6c0          ;Madram's trick requires to start with this.
        exx
dknr3 (void): ld bc,#f401                     ;C is the PSG register.
        
        ;Register 0 and 1.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg01_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg01_Instr)
        ENDIF
        out (c),0                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        ;Register 2 and 3.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg23_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg23_Instr)
        ENDIF
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        ;Register 4 and 5.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg45_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg45_Instr)
        ENDIF
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        ;Register 6.
                        IFDEF PLY_SE_Noise              ;CONFIG SPECIFIC
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg6_8_Instr: ld hl,0          ;L is R6, H is R8. Faster to set a 16 bits register than 2 8-bit.
        ELSE
        ld hl,(PLY_SE_PSGReg6_8_Instr)
        ENDIF
PLY_SE_PSGReg6 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg8 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b + 1
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
                        ELSE ;No Register 6 (noise), but R8 must still loaded.
        IFNDEF PLY_SE_Rom
PLY_SE_PSGReg8_Instr: ld h,0
        ELSE
        ld l,a  ;Saves A first.
        ld a,(PLY_SE_PSGReg8_Instr)
        ld h,a
        ld a,l
        ENDIF
PLY_SE_PSGReg8 equ PLY_SE_PSGReg8_Instr + PLY_SE_Offset1b
                inc c   ;Important to still increase C (register).
                        ENDIF ;PLY_SE_Noise
        
        ;Register 7. The value is A.
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),a                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        ;Register 8. The value is loaded above via HL.
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx

        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg9_10_Instr: ld hl,0          ;L is R9, H is R10. Faster to set a 16 bits register than 2 8-bit.
        ELSE
        ld hl,(PLY_SE_PSGReg9_10_Instr)
        ENDIF
PLY_SE_PSGReg9 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg10 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b + 1
        ;Register 9.
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
        ;Register 10.
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
        
                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
        ;Register 11 and 12.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGHardwarePeriod_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGHardwarePeriod_Instr)
        ENDIF
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),l                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx  

        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),h                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        exx
                        ENDIF ;PLY_CFG_UseHardwareSounds
        ENDIF ;PLY_SE_HARDWARE_CPC
        
        IFDEF PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON
        ex af,af'       ;Saves R7.
dknr3 (void):  ld de,#bfff
dknr3 (void):  ld bc,#fffd
        
        ld a,1          ;Register.
        
        ;Register 0 and 1.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg01_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg01_Instr)
        ENDIF
        out (c),0       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
        
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
      
        ;Register 2 and 3.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg23_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg23_Instr)
        ENDIF
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
        
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
        
        ;Register 4 and 5.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg45_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg45_Instr)
        ENDIF
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
        
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
        
        ;Register 6.
                        IFDEF PLY_SE_Noise              ;CONFIG SPECIFIC
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg6_8_Instr: ld hl,0          ;L is R6, H is R8. Faster to set a 16 bits register than 2 8-bit.
        ELSE
        ld hl,(PLY_SE_PSGReg6_8_Instr)
        ENDIF
PLY_SE_PSGReg6 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg8 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b + 1
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
                        ELSE ;No Register 6 (noise), but R8 must still loaded.
        IFNDEF PLY_SE_Rom
PLY_SE_PSGReg8_Instr: ld h,0
        ELSE
        ld l,a          ;Saves A first.
        ld a,(PLY_SE_PSGReg8_Instr)
        ld h,a
        ld a,l
        ENDIF
PLY_SE_PSGReg8 equ PLY_SE_PSGReg8_Instr + PLY_SE_Offset1b
                inc a   ;Important to still increase A (register).
                        ENDIF ;PLY_SE_Noise
     
        ;Register 7. The value is A.
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        ex af,af'       ;Retrieves R7.
        out (c),a       ;#bffd + value
        ex af,af'
        ld b,e
        
        ;Register 8. The value is loaded above via HL.
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
        
        ;Register 9 and 10.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg9_10_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg9_10_Instr)
        ENDIF
PLY_SE_PSGReg9 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg10 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b + 1
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
        
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
        
                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
        ;Register 11 and 12.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGHardwarePeriod_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGHardwarePeriod_Instr)
        ENDIF
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),l       ;#bffd + value
        ld b,e
        
        inc a
        out (c),a       ;#fffd + register.
        ld b,d
        out (c),h       ;#bffd + value
        ld b,e
                        ENDIF ;PLY_CFG_UseHardwareSounds
        ENDIF ;PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON

        IFDEF PLY_SE_HARDWARE_MSX
        ld b,a          ;Preserves R7.
        ld a,7
        out (#a0),a     ;Register.
        ld a,b
        out (#a1),a     ;Value.
        
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg01_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg01_Instr)
        ENDIF
        xor a
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.

        ld a,1
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.

        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg23_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg23_Instr)
        ENDIF
        ld a,2
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.

        ld a,3
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.
        
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg45_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg45_Instr)
        ENDIF
        ld a,4
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.

        ld a,5
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.
        
        ;Register 6 and 8.
                        IFDEF PLY_SE_Noise              ;CONFIG SPECIFIC
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg6_8_Instr: ld hl,0          ;L is R6, H is R8. Faster to set a 16 bits register than 2 8-bit.
        ELSE
        ld hl,(PLY_SE_PSGReg6_8_Instr)
        ENDIF
PLY_SE_PSGReg6 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg8 equ PLY_SE_PSGReg6_8_Instr + PLY_SE_Offset1b + 1
        ld a,6
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.
        
        ld a,8
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.
                        ELSE ;No Register 6 (noise), only register 8.
                ld a,8
                out (#a0),a     ;Register.
        IFNDEF PLY_SE_Rom
PLY_SE_PSGReg8_Instr: ld a,0
        ELSE
        ld a,(PLY_SE_PSGReg8_Instr)
        ENDIF
PLY_SE_PSGReg8 equ PLY_SE_PSGReg8_Instr + PLY_SE_Offset1b
                out (#a1),a     ;Value.
                        ENDIF ;PLY_SE_Noise

        
        ;Register 9 and 10.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGReg9_10_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGReg9_10_Instr)
        ENDIF
PLY_SE_PSGReg9 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b
PLY_SE_PSGReg10 equ PLY_SE_PSGReg9_10_Instr + PLY_SE_Offset1b + 1
        ld a,9
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.
        
        ld a,10
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.
        
                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
        ;Register 11 and 12.
        IFNDEF PLY_SE_Rom
dknr3 (void):
PLY_SE_PSGHardwarePeriod_Instr: ld hl,0
        ELSE
        ld hl,(PLY_SE_PSGHardwarePeriod_Instr)
        ENDIF
        ld a,11
        out (#a0),a     ;Register.
        ld a,l
        out (#a1),a     ;Value.
        
        ld a,12
        out (#a0),a     ;Register.
        ld a,h
        out (#a1),a     ;Value.
                        ENDIF ;PLY_CFG_UseHardwareSounds
        ENDIF ;PLY_SE_HARDWARE_MSX

        ;R13.
                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
        IFDEF PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON
        inc a           ;Selects R13 now, even if not changed, because A will be modified.
        out (c),a       ;#fffd + register.
        ENDIF
        IFDEF PLY_SE_HARDWARE_MSX
        ld a,13         ;Selects R13 now, even if not changed, because A will be modified.
        out (#a0),a     ;Register.
        ENDIF
        
                        IFDEF PLY_SE_UseRetrig          ;CONFIG SPECIFIC
        IFNDEF PLY_SE_Rom
PLY_SE_PSGReg13_OldValue: ld a,255
PLY_SE_Retrig: or 0                    ;0 = no retrig. Else, should be >0xf to be sure the old value becomes a sentinel (i.e. unreachable) value.
PLY_SE_PSGReg13_Instr: ld l,0          ;Register 13.
        ELSE
        ld a,(PLY_SE_PSGReg13_Instr)
        ld l,a
        ld a,(PLY_SE_Retrig)
        ld h,a
        ld a,(PLY_SE_PSGReg13_OldValue)
        or h
        ENDIF
        cp l                           ;Is the new value still the same? If yes, the new value must not be set again.
        ret z
        ;Different R13.
        ld a,l
                        ELSE ;PLY_SE_UseRetrig
        IFNDEF PLY_SE_Rom
PLY_SE_PSGReg13_Instr: ld a,0          ;Register 13.
PLY_SE_PSGReg13_OldValue: cp 255
        ELSE
        ld a,(PLY_SE_PSGReg13_OldValue)
        ld l,a
        ld a,(PLY_SE_PSGReg13_Instr)
        ENDIF
        cp l                           ;Is the new value still the same? If yes, the new value must not be set again.
        ret z
                        ENDIF ;PLY_SE_UseRetrig
                        
        ld (PLY_SE_PSGReg13_OldValue + PLY_SE_Offset1b),a
        
        IFDEF PLY_SE_HARDWARE_CPC
        inc c
        out (c),c                       ;#f400 + register.
        exx
                out (c),0               ;#f600.
        exx
        out (c),a                       ;#f400 + value.
        exx
                out (c),c               ;#f680.
                out (c),e               ;#f6c0.
        ;exx
        ENDIF
        
        IFDEF PLY_SE_HARDWARE_SPECTRUM_OR_PENTAGON
        ld b,d
        out (c),a       ;#bffd + value
        ENDIF
        
        IFDEF PLY_SE_HARDWARE_MSX
        out (#a1),a     ;Value.
        ENDIF

                        IFDEF PLY_SE_UseRetrig          ;CONFIG SPECIFIC
        xor a
        ld (PLY_SE_Retrig + PLY_SE_Offset1b),a
                        ENDIF ;PLY_SE_UseRetrig
                        
                        ENDIF ;PLY_CFG_UseHardwareSounds
        ret
        





;Plays the sound stream from the given pointer to the sound effect. If 0, no sound is played.
;The given R7 is given shift twice to the left, so that this code MUST set/reset the bit 2 (sound), and maybe reset bit 5 (noise).
;This code MUST overwrite these bits.
;IN:    IX = Points on the sound effect pointer. If the sound effect pointer is 0, nothing must be played.
;       IY = Points on the address where to store the volume for this channel.
;       HL'= Points on the address where to store the software period for this channel.
;       C = R7, shifted twice to the left.
;OUT:   The pointed pointer by IX may be modified as the sound advances.
;       C = R7, MUST be modified if there is a sound effect.
PLY_SE_PSES_Play:

        ;Reads the pointer pointed by IX.
        ld l,(ix + 0)
        ld h,(ix + 1)
        ld a,l
        or h
        ret z

        ;Reads the first byte. What type of sound is it?
PLY_SE_PSES_ReadFirstByte:
        ld a,(hl)
        inc hl
        ld b,a
        rra
        jr c,PLY_SE_PSES_SoftwareOrSoftwareAndHardware
        rra
                        IFDEF PLY_CFG_SFX_HardOnly              ;CONFIG SPECIFIC
        jr c,PLY_SE_PSES_HardwareOnly
                        ENDIF ;PLY_CFG_SFX_HardOnly
                        
        ;No software, no hardware, or end/loop.
        ;-------------------------------------------
        ;End or loop?
        rra
                        IFDEF PLY_CFG_SFX_NoSoftNoHard         ;CONFIG SPECIFIC. If not present, the jump is not needed, the method is just below.
        jr c,PLY_SE_PSES_S_EndOrLoop

        ;Real sound.
        ;Gets the volume.
        call PLY_SE_PSES_ManageVolumeFromA_Filter4Bits

        ;Noise?
                        IFDEF PLY_CFG_SFX_NoSoftNoHard_Noise                ;CONFIG SPECIFIC
        rl b
        call PLY_SE_PSES_ReadNoiseIfNeededAndOpenOrCloseNoiseChannel
                        ELSE
        set 5,c                                                 ;No noise in compilation, so stops the noise.
                        ENDIF ;PLY_CFG_SFX_NoSoftNoHard_Noise

        ;Cuts the sound.
        set 2,c
        
        jr PLY_SE_PSES_SavePointerAndExit
                        ENDIF ;PLY_CFG_SFX_NoSoftNoHard

PLY_SE_PSES_S_EndOrLoop:
                        IFDEF PLY_CFG_SFX_LoopTo                ;CONFIG SPECIFIC. If no "loop to", the sounds always end, no need to test.
        ;Is it an end?
        rra
        jr c,PLY_SE_PSES_S_Loop
                        ENDIF ;PLY_CFG_SFX_LoopTo
        ;End of the sound. Marks the sound pointer with 0, meaning "no sound".
        xor a
        ld (ix + 0),a
        ld (ix + 1),a
        ;Sets the volume to 0 (else, nothing will stop the sound from continuing, contrary to the non-standalone players).
        ld (iy + 0),a
        ret
                        IFDEF PLY_CFG_SFX_LoopTo                ;CONFIG SPECIFIC.
PLY_SE_PSES_S_Loop:
        ;Loops. Reads the pointer and directly uses it.
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jr PLY_SE_PSES_ReadFirstByte
                        ENDIF ;PLY_CFG_SFX_LoopTo

;Saves HL into IX, and exits. This must be called at the end of each Cell.
;If the speed has not been reached, it is not saved.
PLY_SE_PSES_SavePointerAndExit:
        ;Speed reached?
        ld a,(ix + PLY_SE_SoundEffectData_OffsetCurrentStep)
        cp (ix + PLY_SE_SoundEffectData_OffsetSpeed)
        jr c,PLY_SE_PSES_NotReached
        ;The speed has been reached, so resets it and saves the pointer to the next cell to read.
        ld (ix + PLY_SE_SoundEffectData_OffsetCurrentStep),0
        ld (ix + 0),l
        ld (ix + 1),h
        ret
PLY_SE_PSES_NotReached:
        ;Speed not reached. Increases it, that's all. The same cell will be read next time.
        inc (ix + PLY_SE_SoundEffectData_OffsetCurrentStep)
        ret

                        IFDEF PLY_CFG_SFX_HardOnly         ;CONFIG SPECIFIC
        ;Hardware only.
        ;-------------------------------------------
PLY_SE_PSES_HardwareOnly:
        ;Calls the shared code that manages everything.
        call PLY_SE_PSES_Shared_ReadRetrigHardwareEnvPeriodNoise
        ;Cuts the sound.
        set 2,c

        jr PLY_SE_PSES_SavePointerAndExit
                        ENDIF ;PLY_CFG_SFX_HardOnly



PLY_SE_PSES_SoftwareOrSoftwareAndHardware:
        ;Software only?
        rra
                        IFDEF PLY_CFG_SFX_SoftAndHard         ;CONFIG SPECIFIC
        jr c,PLY_SE_PSES_SoftwareAndHardware
                        ENDIF ;PLY_CFG_SFX_SoftAndHard

        ;Software.
        ;-------------------------------------------
                        IFDEF PLY_CFG_SFX_SoftOnly          ;CONFIG SPECIFIC
        ;Volume.
        call PLY_SE_PSES_ManageVolumeFromA_Filter4Bits

        ;Noise?
                        IFDEF PLY_CFG_SFX_SoftOnly_Noise                ;CONFIG SPECIFIC
        rl b
        call PLY_SE_PSES_ReadNoiseIfNeededAndOpenOrCloseNoiseChannel
                        ELSE
        set 5,c                                                         ;No noise in compilation, so stops the noise.
                        ENDIF ;PLY_CFG_SFX_SoftOnly_Noise
                        
        ;Opens the "sound" channel.
        res 2,c

        ;Reads the software period.
        call PLY_SE_PSES_ReadSoftwarePeriod

        jr PLY_SE_PSES_SavePointerAndExit
                        ENDIF ;PLY_CFG_SFX_SoftOnly

        ;Software and Hardware.
        ;-------------------------------------------
                        IFDEF PLY_SE_HardwareSounds         ;CONFIG SPECIFIC
PLY_SE_PSES_SoftwareAndHardware:
        ;Calls the shared code that manages everything.
        call PLY_SE_PSES_Shared_ReadRetrigHardwareEnvPeriodNoise

        ;Reads the software period.
        call PLY_SE_PSES_ReadSoftwarePeriod

        ;Opens the sound.
        res 2,c

        jr PLY_SE_PSES_SavePointerAndExit
                        ENDIF ;PLY_SE_HardwareSounds


                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
        ;Shared code used by the "hardware only" and "software and hardware" part.
        ;Reads the Retrig flag, the Hardware Envelope, the possible noise, the hardware period,
        ;and sets the volume to 16. The R7 sound channel is NOT modified.
PLY_SE_PSES_Shared_ReadRetrigHardwareEnvPeriodNoise:
        ;Retrig?
        rra
                        IFDEF PLY_SE_UseRetrig                  ;CONFIG SPECIFIC
        jr nc,PLY_SE_PSES_H_AfterRetrig
        ld d,a
        ld a,255
        ld (PLY_SE_PSGReg13_OldValue + PLY_SE_Offset1b),a
        ld a,d
PLY_SE_PSES_H_AfterRetrig:
                        ENDIF ;PLY_SE_UseRetrig
                        
        ;Can't use A anymore, it may have been destroyed by the retrig.

        ;The hardware envelope can be set (8-15).
        and %111
        add a,8
        ld (PLY_SE_PSGReg13_Instr + PLY_SE_Offset1b),a

        ;Noise?
                        IFDEF PLY_SE_HardwareNoise           ;CONFIG SPECIFIC. B not needed after, we can put it in the condition too.
        rl b
        call PLY_SE_PSES_ReadNoiseIfNeededAndOpenOrCloseNoiseChannel
                        ELSE
        set 5,c                                                         ;No noise in compilation, so stops the noise.
                        ENDIF ;PLY_SE_HardwareNoise

        ;Reads the hardware period.
        call PLY_SE_PSES_ReadHardwarePeriod

        ;Sets the volume to "hardware". It still may be decreased.
        ld a,16
        jp PLY_SE_PSES_ManageVolumeFromA_Hard
                        ENDIF ;PLY_CFG_UseHardwareSounds

                        
                        IFDEF PLY_SE_Noise
;If asked to, reads the noise pointed by HL, increases HL, and opens the noise channel. If no noise, closes the noise channel.
;IN:    Carry = true if noise to read. False if no noise, thus the noise channel must be closed.
;       HL = the data.
PLY_SE_PSES_ReadNoiseIfNeededAndOpenOrCloseNoiseChannel:
        jr c,PLY_SE_PSES_ReadNoiseAndOpenNoiseChannel_OpenNoise
        ;No noise, so closes the noise channel.
        set 5,c
        ret
PLY_SE_PSES_ReadNoiseAndOpenNoiseChannel_OpenNoise:
        ;Reads the noise.
        ld a,(hl)
        ld (PLY_SE_PSGReg6),a
        inc hl

        ;Opens noise channel.
        res 5,c
        ret
                        ENDIF ;PLY_SE_Noise

                        IFDEF PLY_CFG_UseHardwareSounds         ;CONFIG SPECIFIC
;Reads the hardware period from HL and sets the R11/R12 registers. HL is incremented of 2.
PLY_SE_PSES_ReadHardwarePeriod:
        ld a,(hl)
        ld (PLY_SE_PSGHardwarePeriod_Instr + PLY_SE_Offset1b),a
        inc hl
        ld a,(hl)
        ld (PLY_SE_PSGHardwarePeriod_Instr + PLY_SE_Offset1b + 1),a
        inc hl
        ret
                        ENDIF ;PLY_CFG_UseHardwareSounds

;Reads the software period from HL and sets the period registers thanks to IY. HL is incremented of 2.
PLY_SE_PSES_ReadSoftwarePeriod:
        ld a,(hl)
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

                        IFDEF PLY_SE_VolumeSoft      ;CONFIG SPECIFIC
;Reads the volume in A, decreases it from the inverted volume of the channel, and sets the volume via IY.
;IN:    A = volume, from 0 to 15 (no hardware envelope).
PLY_SE_PSES_ManageVolumeFromA_Filter4Bits:
        and %1111
                        ENDIF ;PLY_SE_VolumeSoft
                        IFDEF PLY_SE_VolumeSoftOrHard        ;CONFIG SPECIFIC
;After the filtering. Useful for hardware sound (volume has been forced to 16).
PLY_SE_PSES_ManageVolumeFromA_Hard:
        ;Decreases the volume, checks the limit.
        sub (ix + PLY_SE_SoundEffectData_OffsetInvertedVolume)
        jr nc,PLY_SE_PSES_MVFA_NoOverflow
        xor a
PLY_SE_PSES_MVFA_NoOverflow:
        ld (iy + 0),a
        ret
                        ENDIF ;PLY_SE_VolumeSoftOrHard
                        
        IFNDEF PLY_SE_Rom
;The data of the Channels MUST be consecutive.
dkws (void):
PLY_SE_Channel1_SoundEffectData:
        dw 0                                            ;Points to the sound effect for the track 1, or 0 if not playing.
dkwe (void):
dkbs (void):
PLY_SE_Channel1_SoundEffectInvertedVolume:
        db 0                                            ;Inverted volume.
PLY_SE_Channel1_SoundEffectCurrentStep:
        db 0                                            ;Current step (>=0).
PLY_SE_Channel1_SoundEffectSpeed:
        db 0                                            ;Speed (>=0).
        ds 3,0                                          ;Padding.

PLY_SE_Channel_SoundEffectDataSize equ $ - PLY_SE_Channel1_SoundEffectData
        
PLY_SE_Channel2_SoundEffectData:
        ds PLY_SE_Channel_SoundEffectDataSize, 0
PLY_SE_Channel3_SoundEffectData:
        ds PLY_SE_Channel_SoundEffectDataSize, 0
dkbe (void):
        ELSE
        
        ;Data for ROM. Generic data first.
        counter = 0
        ;Words.
PLY_SE_PtSoundEffectTable                               equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
PLY_SE_PSGReg01_Instr                                   equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
PLY_SE_PSGReg23_Instr                                   equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
PLY_SE_PSGReg45_Instr                                   equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
        IFDEF PLY_SE_Noise              ;CONFIG SPECIFIC
PLY_SE_PSGReg6_8_Instr                                  equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
        ELSE
PLY_SE_PSGReg8_Instr                                    equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
        ENDIF
PLY_SE_PSGReg9_10_Instr                                 equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
PLY_SE_PSGHardwarePeriod_Instr                          equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
        ;Bytes.
PLY_SE_PSGReg13_Instr                                   equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
PLY_SE_PSGReg13_OldValue                                equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
PLY_SE_Retrig                                           equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
        
        ;Channel 1 data.
        ;Words.
        channelCounterStart = counter
PLY_SE_Channel1_SoundEffectData                         equ PLY_SE_ROM_Buffer + counter : counter = counter + 2
        ;Bytes.
PLY_SE_Channel1_SoundEffectInvertedVolume               equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
PLY_SE_Channel1_SoundEffectCurrentStep                  equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
PLY_SE_Channel1_SoundEffectSpeed                        equ PLY_SE_ROM_Buffer + counter : counter = counter + 1
        counter = counter + 3   ;Padding.
PLY_SE_Channel_SoundEffectDataSize = counter - channelCounterStart
        assert PLY_SE_Channel_SoundEffectDataSize == 8
PLY_SE_Channel2_SoundEffectData                         equ PLY_SE_Channel1_SoundEffectData + PLY_SE_Channel_SoundEffectDataSize
PLY_SE_Channel3_SoundEffectData                         equ PLY_SE_Channel2_SoundEffectData + PLY_SE_Channel_SoundEffectDataSize

PLY_SE_ROM_BufferSize = PLY_SE_Channel3_SoundEffectData + PLY_SE_Channel_SoundEffectDataSize - PLY_SE_ROM_Buffer
        ENDIF

;Offset from the beginning of the data, to reach the inverted volume.
PLY_SE_SoundEffectData_OffsetInvertedVolume equ PLY_SE_Channel1_SoundEffectInvertedVolume - PLY_SE_Channel1_SoundEffectData
PLY_SE_SoundEffectData_OffsetCurrentStep equ PLY_SE_Channel1_SoundEffectCurrentStep - PLY_SE_Channel1_SoundEffectData
PLY_SE_SoundEffectData_OffsetSpeed equ PLY_SE_Channel1_SoundEffectSpeed - PLY_SE_Channel1_SoundEffectData

        ;Checks that the pointers are consecutive.
        assert (PLY_SE_Channel1_SoundEffectData + PLY_SE_Channel_SoundEffectDataSize) == PLY_SE_Channel2_SoundEffectData
        assert (PLY_SE_Channel2_SoundEffectData + PLY_SE_Channel_SoundEffectDataSize) == PLY_SE_Channel3_SoundEffectData

    ;Sample player, included to the PlayerAkyMultiPsg.
    ;This player can play one sampled note at a time, but on any channel, alongside standard PSG music.
    ;Do not include this player directly to your code, it is included by the aforementioned player directly.
    ;See the testers for a fully working example.

    ;Effects are not supported for now (ignored).

    ;This player requires your PSG in AT3 to have a "sample replay frequency" set to 8000 Hz.
    ;Please check the documentation about how to export the samples in the right format.

;The following constants indicates how many bytes are played every frame. This should be as high as possible to "fill" the VBL.
;It is also possible to skip the wait for the frame flyback to maximize the quality,
;but then synchronizing anything on the frame will be impossible.
;The samples should have a padding of at least this value (should be more to handle higher pitches), else glitches
;are going to be heard at the end of each sample (AT can generate that).
;320/31 = ideal values. CANNOT BE DONE!

;Default values for CPC. Compromise so that it sounds OK without being out of key.
PLY_AKY_SAMPLE_BYTE_PER_FRAME = 308     ;Must be even.
PLY_AKY_NOPS_TO_WAIT = 28
PLY_AKY_SPL_TRANSPOSE = 0

IFDEF PLY_AKY_HARDWARE_MSX
    ;Tested on emulator (WebMSX) for MSX2+ (PAL).
    PLY_AKY_SAMPLE_BYTE_PER_FRAME = 274
    PLY_AKY_NOPS_TO_WAIT = 27
    PLY_AKY_SPL_TRANSPOSE = 0
    ;Another possibility...
    ;PLY_AKY_SAMPLE_BYTE_PER_FRAME = 308
    ;PLY_AKY_NOPS_TO_WAIT = 22
    ;PLY_AKY_SPL_TRANSPOSE = -2
ENDIF

IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
    ;Tested on emulator (JSSpeccy3).
    ;PLY_AKY_SAMPLE_BYTE_PER_FRAME = 302
    ;PLY_AKY_NOPS_TO_WAIT = 34
    ;PLY_AKY_SPL_TRANSPOSE = 0
    ;Another possibility...
    PLY_AKY_SAMPLE_BYTE_PER_FRAME = 256
    PLY_AKY_NOPS_TO_WAIT = 44
    PLY_AKY_SPL_TRANSPOSE = 3
ENDIF

    ;If using ROM, the player is slightly more demanding, so the sample count must be decreased.
    IFDEF PLY_AKY_ROM
        PLY_AKY_SAMPLE_BYTE_PER_FRAME = PLY_AKY_SAMPLE_BYTE_PER_FRAME - 2
    ENDIF

    ASSERT (PLY_AKY_SAMPLE_BYTE_PER_FRAME %2 == 0)  ;Must be even.
    ASSERT (PLY_AKY_SAMPLE_BYTE_PER_FRAME /2 < 256) ;The half-counter must remain 8 bits.

;Initializes the samples. It must be called before playing the song.
;HL = address of the sample patterns (exported from AT).
;DE = address of the sample table (exported from AT).
PLY_AKY_InitSamples
    ld (PLY_AKY_SPL_PT_Pattern + PLY_AKY_Offset1b),hl
    dec de      ;The indexes start at 1, so need to shift the table.
    dec de
    ld (PLY_AKY_SPL_PT_SampleTable + PLY_AKY_Offset1b),de

    xor a
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a
    ld (PLY_AKY_SPL_SampleVolumeRegister + PLY_AKY_Offset1b),a
    ld l,a
    ld h,a
    ld (PLY_AKY_SPL_Sample + PLY_AKY_Offset1b),hl
    inc l
    ld (PLY_AKY_SPL_ManageSampleWait + PLY_AKY_Offset1b),hl
    ret

;Manages the presence or not of the samples by reading the sample pattern (RAW Linear file).
;Called from the player every frame BEFORE the PSG values are sent.
;The stack must NOT be used. Then goes to PLY_AKY_ManageSample_Return.
;IN:    B = R7.
;OUT:   B = R7, modified or not.
PLY_AKY_ManageSample
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_ManageSampleWait ld hl,0             ;Frames to wait?
    ELSE
            ld hl,(PLY_AKY_SPL_ManageSampleWait)
    ENDIF
    dec hl
    ld a,l
    or h
    jr z,.endWait
    ;Wait not finished.
    ld (PLY_AKY_SPL_ManageSampleWait + PLY_AKY_Offset1b),hl
    jp PLY_AKY_ManageSample_Return
.endWait
    ;Wait finished. Reads the next value.
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_PT_Pattern ld hl,0
    ELSE
        ld hl,(PLY_AKY_SPL_PT_Pattern)
    ENDIF
PLY_AKY_SPL_ReadCommand ld a,(hl)       ;What command?
    inc hl
    cp 254
    jr z,PLY_AKY_SPL_Wait
    cp 255
    jr z,PLY_AKY_SPL_Wait_1
    cp 253
    jr nz,PLY_AKY_SPL_FoundNote
    
    ;End of song. Reads the loop and continues.
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    jr PLY_AKY_SPL_ReadCommand

PLY_AKY_SPL_Wait
    ;Wait. Reads how many frames to wait.
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
PLY_AKY_SPL_WaitSet
    ld (PLY_AKY_SPL_ManageSampleWait + PLY_AKY_Offset1b),de
    ld (PLY_AKY_SPL_PT_Pattern + PLY_AKY_Offset1b),hl
    jp PLY_AKY_ManageSample_Return
PLY_AKY_SPL_Wait_1
    ld hl,1
    jr PLY_AKY_SPL_WaitSet
   
;A = channel index.
PLY_AKY_SPL_FoundNote
    ld c,a

    ;Special case: if the instrument is RST, we must stop the sample IF there is a sample on this channel.
    inc hl          ;Skips the note.
    ld a,(hl)       ;Gets the instrument.
    or a
    jr nz,PLY_AKY_SPL_FoundNote_AfterRstTest
    ;Instrument 0 (RST) must stop the possible sample, if present (else, ignore it).
    ;Is there a sample on this channel?
    ld a,(PLY_AKY_RegisterToSkip + 1)
    inc hl          ;Goes beyond the instrument.
    sub 8
    cp c
    jr nz,PLY_AKY_SPL_ReadEffect    ;RST found, but no sample being played. Simply skips this note.
    ;There is a sample on this channel. Stops it.

    xor a
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a
    ld e,a
    ld d,a
    ld (PLY_AKY_SPL_Sample + PLY_AKY_Offset1b),de
    ;Let's be clean and read the possible following data. B is not modified, we don't play sample.
    jr PLY_AKY_SPL_ReadEffect

PLY_AKY_SPL_FoundNote_AfterRstTest
    dec hl  ;Goes back to the note.

    ;set 0,b = 0xcb 0xc0.
    ;set 1,b = 0xcb 0xc8.
    ;set 2,b = 0xcb 0xd0.
    ;Encoding the second byte of the set instruction.
    ld a,c
    add a,a
    add a,a
    add a,a
    add a,#c0
    ld (PLY_AKY_SPL_R7CloseChannelOpcode + 1),a     ;The second byte is modified (even for ROM).
    ld a,c
    add a,8
    ld (PLY_AKY_SPL_SampleVolumeRegister + PLY_AKY_Offset1b),a

    ;If a sample is being played, the R7 channel must be closed NOW, before the player is going to
    ;sends this value to the PSG
    ld de,(PLY_AKY_SPL_Sample + PLY_AKY_Offset1b)
    ld a,e
    or d
    jr z,PLY_AKY_SPL_AfterChannel
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_R7CloseChannelOpcode set 1,b     ;The second byte is modified (set 0/1/2 on init).
    ELSE
        jp PLY_AKY_SPL_R7CloseChannelOpcode
PLY_AKY_SPL_R7CloseChannelOpcode_Return
    ENDIF
PLY_AKY_SPL_AfterChannel

    ld a,(hl)       ;Gets the note, if any.
    inc hl
    cp 255
    jr z,PLY_AKY_SPL_AfterNote
    ;Finds the step of the current note.
    add a,a         ;Only 7 bits, so all right.
    exx
        ld l,a
        ld h,0
        ld de,PLY_AKY_SPL_StepsTable + (PLY_AKY_SPL_TRANSPOSE * 2)
        add hl,de
        ld de,PLY_AKY_SPL_StepIntegerAndDecimal + PLY_AKY_Offset1b
        ldi
        ldi
    exx
PLY_AKY_SPL_AfterNote

    ld a,(hl)       ;Gets the instrument, if any. We know it is not a RST, which has been tested earlier.
    inc hl
    cp 255
    jr z,PLY_AKY_SPL_AfterInstrument
    exx
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_PT_SampleTable ld de,0
    ELSE
        ld de,(PLY_AKY_SPL_PT_SampleTable)
    ENDIF
        ld l,a
        ld h,0
        add hl,hl
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld de,PLY_AKY_SPL_Sample + PLY_AKY_Offset1b
        ldi
        ldi
        ld de,PLY_AKY_SPL_SampleEnd + PLY_AKY_Offset1b
        ldi
        ldi
        ld de,PLY_AKY_SPL_SampleLoop + PLY_AKY_Offset1b
        ldi
        ldi
    exx
PLY_AKY_SPL_AfterInstrument

    ;Any effect?
PLY_AKY_SPL_ReadEffect
    ld a,(hl)
    inc hl
    or a
    jr z,PLY_AKY_SPL_AfterEffect
    inc hl                  ;For now, they are ignored!
    inc hl
    jr PLY_AKY_SPL_ReadEffect
PLY_AKY_SPL_AfterEffect

    ;Next command.
    jp PLY_AKY_SPL_ReadCommand
    






;Plays a frame of the sample, or any is programmed.
;Do NOT use the stack. Use JP to call this. PLY_AKY_ManageSample_Return is called on return.
PLY_AKY_PlaySample
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_Sample ld hl,0   ;0 means no sample frame to play.
    ELSE
        ld hl,(PLY_AKY_SPL_Sample)
    ENDIF
    ld a,l
    or h
    jr nz,.samplePresent
    ;No sample. Allows the player to uses its own volume value.
    xor a
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a
    jp PLY_AKY_PlaySample_Return
.samplePresent

    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_SampleVolumeRegister ld a,0     ;8/9/10.
    ELSE
        ld a,(PLY_AKY_SPL_SampleVolumeRegister)
    ENDIF
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a ;The player code must not play its own volume.
    ;Selects the sample channel.
    IFDEF PLY_AKY_HARDWARE_PLAYCITY_OR_CPC
        ld b,#f4
        out (c),a
        ld bc,#f6c0
        out (c),c
        out (c),0
    ENDIF
    IFDEF PLY_AKY_HARDWARE_MSX
        out (PLY_AKY_FAST_PSG_SELECT_REGISTER),a        ;Register.
    ENDIF
    IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
        ld bc,#fffd
        out (c),a               ;Register.
    ENDIF

    ;Main sample loop at 16khz.

    IFDEF PLY_AKY_HARDWARE_PLAYCITY_OR_CPC
    exx
        ld hl,#f4f6
    exx
    ENDIF
    IFDEF PLY_AKY_HARDWARE_MSX
        ;Nothing to do!
    ENDIF
    IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
    exx
        ld bc,#bffd
    exx
    ENDIF
    
    ld de,0 * 256 + PLY_AKY_SAMPLE_BYTE_PER_FRAME / 2 ;D = Increasing decimal step.
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_StepIntegerAndDecimal ld bc,0   ;B = Integer speed part, C = decimal speed part.
    ELSE
        ld bc,(PLY_AKY_SPL_StepIntegerAndDecimal)
    ENDIF

    ;Macro to play the samples, used just after.
    MACRO PLY_PLAY_SAMPLE
@playSampleLoop
        ld a,(hl)           ;Reads from the sample.
        IFDEF PLY_AKY_HARDWARE_PLAYCITY_OR_CPC
        exx
            ld b,h
            out (c),a       ;Sends the byte from HL.
            ld b,l
            out (c),a       ;#f680 (a trick, our sample value has its 7th bit to 1).
            out (c),0       ;#f600
        exx
        ENDIF
        IFDEF PLY_AKY_HARDWARE_MSX
        out (PLY_AKY_FAST_PSG_SELECT_VALUE),a
        ENDIF
        IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
        exx
            out (c),a
        exx
        ENDIF

        ;Moves forward in the sample.
        ld a,d
        add a,c
        ld d,a
        ld a,l
        adc a,b
        ld l,a
        jr nc,@forwardNoCarry
        inc h
@forwardNoCarry

        dec e
        jr z,@iterationEnd              ;Could have used a RET table to optimize, but no need, we keep on waiting...

        ;Wastes time to reach 16 khz. The loop should ideally last 1 scanline, but tweaking is done to adjust for the player non-playing time
        ;(see constants at the top).
        ds PLY_AKY_NOPS_TO_WAIT
        jr @playSampleLoop
@iterationEnd

    ENDM

    ;Plays the loop twice so that the counter remains in 8 bits.
    PLY_PLAY_SAMPLE
    ld e,PLY_AKY_SAMPLE_BYTE_PER_FRAME / 2
    PLY_PLAY_SAMPLE

PLY_AKY_SPL_PlaySampleEnd
    ex de,hl        ;DE = advanced pointer on the sample.
    ;Are we beyond the sample range?
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_SampleEnd ld hl,0
    ELSE
        ld hl,(PLY_AKY_SPL_SampleEnd)
    ENDIF
    or a
    sbc hl,de
    jr nc,PLY_AKY_SPL_SetNewSamplePt
    ;End sample ended. Loop? If not 0, loops.
    IFNDEF PLY_AKY_ROM
PLY_AKY_SPL_SampleLoop ld de,0
    ELSE
        ld de,(PLY_AKY_SPL_SampleLoop)
    ENDIF
PLY_AKY_SPL_SetNewSamplePt
    ld (PLY_AKY_SPL_Sample + PLY_AKY_Offset1b),de

    jp PLY_AKY_PlaySample_Return









;Steps for each note, nominal octave.
;Calculated thanks to https://fr.wikipedia.org/wiki/Gamme_temp%C3%A9r%C3%A9e, and ratioed into 256.
;Same table as for the MOD player.
PLY_AKY_SPL_Step_Oct4_0 equ #0100
PLY_AKY_SPL_Step_Oct4_1 equ #0100 + 15     ;15.22
PLY_AKY_SPL_Step_Oct4_2 equ #0100 + 31     ;31.35
PLY_AKY_SPL_Step_Oct4_3 equ #0100 + 48     ;48.43
PLY_AKY_SPL_Step_Oct4_4 equ #0100 + 66     ;66.54
PLY_AKY_SPL_Step_Oct4_5 equ #0100 + 86     ;85.72
PLY_AKY_SPL_Step_Oct4_6 equ #0100 + 106    ;106.23
PLY_AKY_SPL_Step_Oct4_7 equ #0100 + 127    ;127.56
PLY_AKY_SPL_Step_Oct4_8 equ #0100 + 150    ;150.37
PLY_AKY_SPL_Step_Oct4_9 equ #0100 + 174    ;174.53
PLY_AKY_SPL_Step_Oct4_10 equ #0100 + 201   ;200.71
PLY_AKY_SPL_Step_Oct4_11 equ #0100 + 227   ;226.90

;Steps for every note.
PLY_AKY_SPL_StepsTable:
        dw PLY_AKY_SPL_Step_Oct4_0 / 128                            ;Octave 0
        dw PLY_AKY_SPL_Step_Oct4_1 / 128
        dw PLY_AKY_SPL_Step_Oct4_2 / 128
        dw PLY_AKY_SPL_Step_Oct4_3 / 128
        dw PLY_AKY_SPL_Step_Oct4_4 / 128
        dw PLY_AKY_SPL_Step_Oct4_5 / 128
        dw PLY_AKY_SPL_Step_Oct4_6 / 128
        dw PLY_AKY_SPL_Step_Oct4_7 / 128
        dw PLY_AKY_SPL_Step_Oct4_8 / 128
        dw PLY_AKY_SPL_Step_Oct4_9 / 128
        dw PLY_AKY_SPL_Step_Oct4_10 / 128
        dw PLY_AKY_SPL_Step_Oct4_11 / 128

        dw PLY_AKY_SPL_Step_Oct4_0 / 64                            ;Octave 1
        dw PLY_AKY_SPL_Step_Oct4_1 / 64
        dw PLY_AKY_SPL_Step_Oct4_2 / 64
        dw PLY_AKY_SPL_Step_Oct4_3 / 64
        dw PLY_AKY_SPL_Step_Oct4_4 / 64
        dw PLY_AKY_SPL_Step_Oct4_5 / 64
        dw PLY_AKY_SPL_Step_Oct4_6 / 64
        dw PLY_AKY_SPL_Step_Oct4_7 / 64
        dw PLY_AKY_SPL_Step_Oct4_8 / 64
        dw PLY_AKY_SPL_Step_Oct4_9 / 64
        dw PLY_AKY_SPL_Step_Oct4_10 / 64
        dw PLY_AKY_SPL_Step_Oct4_11 / 64

        dw PLY_AKY_SPL_Step_Oct4_0 / 32                            ;Octave 2
        dw PLY_AKY_SPL_Step_Oct4_1 / 32
        dw PLY_AKY_SPL_Step_Oct4_2 / 32
        dw PLY_AKY_SPL_Step_Oct4_3 / 32
        dw PLY_AKY_SPL_Step_Oct4_4 / 32
        dw PLY_AKY_SPL_Step_Oct4_5 / 32
        dw PLY_AKY_SPL_Step_Oct4_6 / 32
        dw PLY_AKY_SPL_Step_Oct4_7 / 32
        dw PLY_AKY_SPL_Step_Oct4_8 / 32
        dw PLY_AKY_SPL_Step_Oct4_9 / 32
        dw PLY_AKY_SPL_Step_Oct4_10 / 32
        dw PLY_AKY_SPL_Step_Oct4_11 / 32

        dw PLY_AKY_SPL_Step_Oct4_0 / 16                            ;Octave 3
        dw PLY_AKY_SPL_Step_Oct4_1 / 16
        dw PLY_AKY_SPL_Step_Oct4_2 / 16
        dw PLY_AKY_SPL_Step_Oct4_3 / 16
        dw PLY_AKY_SPL_Step_Oct4_4 / 16
        dw PLY_AKY_SPL_Step_Oct4_5 / 16
        dw PLY_AKY_SPL_Step_Oct4_6 / 16
        dw PLY_AKY_SPL_Step_Oct4_7 / 16
        dw PLY_AKY_SPL_Step_Oct4_8 / 16
        dw PLY_AKY_SPL_Step_Oct4_9 / 16
        dw PLY_AKY_SPL_Step_Oct4_10 / 16
        dw PLY_AKY_SPL_Step_Oct4_11 / 16

        dw PLY_AKY_SPL_Step_Oct4_0 / 8                            ;Octave 4
        dw PLY_AKY_SPL_Step_Oct4_1 / 8
        dw PLY_AKY_SPL_Step_Oct4_2 / 8
        dw PLY_AKY_SPL_Step_Oct4_3 / 8
        dw PLY_AKY_SPL_Step_Oct4_4 / 8
        dw PLY_AKY_SPL_Step_Oct4_5 / 8
        dw PLY_AKY_SPL_Step_Oct4_6 / 8
        dw PLY_AKY_SPL_Step_Oct4_7 / 8
        dw PLY_AKY_SPL_Step_Oct4_8 / 8
        dw PLY_AKY_SPL_Step_Oct4_9 / 8
        dw PLY_AKY_SPL_Step_Oct4_10 / 8
        dw PLY_AKY_SPL_Step_Oct4_11 / 8

        dw PLY_AKY_SPL_Step_Oct4_0 / 4                            ;Octave 5
        dw PLY_AKY_SPL_Step_Oct4_1 / 4
        dw PLY_AKY_SPL_Step_Oct4_2 / 4
        dw PLY_AKY_SPL_Step_Oct4_3 / 4
        dw PLY_AKY_SPL_Step_Oct4_4 / 4
        dw PLY_AKY_SPL_Step_Oct4_5 / 4
        dw PLY_AKY_SPL_Step_Oct4_6 / 4
        dw PLY_AKY_SPL_Step_Oct4_7 / 4
        dw PLY_AKY_SPL_Step_Oct4_8 / 4
        dw PLY_AKY_SPL_Step_Oct4_9 / 4
        dw PLY_AKY_SPL_Step_Oct4_10 / 4
        dw PLY_AKY_SPL_Step_Oct4_11 / 4

        dw PLY_AKY_SPL_Step_Oct4_0 / 2                            ;Octave 6
        dw PLY_AKY_SPL_Step_Oct4_1 / 2
        dw PLY_AKY_SPL_Step_Oct4_2 / 2
        dw PLY_AKY_SPL_Step_Oct4_3 / 2
        dw PLY_AKY_SPL_Step_Oct4_4 / 2
        dw PLY_AKY_SPL_Step_Oct4_5 / 2
        dw PLY_AKY_SPL_Step_Oct4_6 / 2
        dw PLY_AKY_SPL_Step_Oct4_7 / 2
        dw PLY_AKY_SPL_Step_Oct4_8 / 2
        dw PLY_AKY_SPL_Step_Oct4_9 / 2
        dw PLY_AKY_SPL_Step_Oct4_10 / 2
        dw PLY_AKY_SPL_Step_Oct4_11 / 2

        dw PLY_AKY_SPL_Step_Oct4_0                                ;Octave 7
        dw PLY_AKY_SPL_Step_Oct4_1
        dw PLY_AKY_SPL_Step_Oct4_2
        dw PLY_AKY_SPL_Step_Oct4_3
        dw PLY_AKY_SPL_Step_Oct4_4
        dw PLY_AKY_SPL_Step_Oct4_5
        dw PLY_AKY_SPL_Step_Oct4_6
        dw PLY_AKY_SPL_Step_Oct4_7
        dw PLY_AKY_SPL_Step_Oct4_8
        dw PLY_AKY_SPL_Step_Oct4_9
        dw PLY_AKY_SPL_Step_Oct4_10
        dw PLY_AKY_SPL_Step_Oct4_11

        dw PLY_AKY_SPL_Step_Oct4_0 * 2                            ;Octave 8
        dw PLY_AKY_SPL_Step_Oct4_1 * 2
        dw PLY_AKY_SPL_Step_Oct4_2 * 2
        dw PLY_AKY_SPL_Step_Oct4_3 * 2
        dw PLY_AKY_SPL_Step_Oct4_4 * 2
        dw PLY_AKY_SPL_Step_Oct4_5 * 2
        dw PLY_AKY_SPL_Step_Oct4_6 * 2
        dw PLY_AKY_SPL_Step_Oct4_7 * 2
        dw PLY_AKY_SPL_Step_Oct4_8 * 2
        dw PLY_AKY_SPL_Step_Oct4_9 * 2
        dw PLY_AKY_SPL_Step_Oct4_10 * 2
        dw PLY_AKY_SPL_Step_Oct4_11 * 2

        dw PLY_AKY_SPL_Step_Oct4_0 * 4                            ;Octave 9
        dw PLY_AKY_SPL_Step_Oct4_1 * 4
        dw PLY_AKY_SPL_Step_Oct4_2 * 4
        dw PLY_AKY_SPL_Step_Oct4_3 * 4
        dw PLY_AKY_SPL_Step_Oct4_4 * 4
        dw PLY_AKY_SPL_Step_Oct4_5 * 4
        dw PLY_AKY_SPL_Step_Oct4_6 * 4
        dw PLY_AKY_SPL_Step_Oct4_7 * 4
        dw PLY_AKY_SPL_Step_Oct4_8 * 4
        dw PLY_AKY_SPL_Step_Oct4_9 * 4
        dw PLY_AKY_SPL_Step_Oct4_10 * 4
        dw PLY_AKY_SPL_Step_Oct4_11 * 4

        dw PLY_AKY_SPL_Step_Oct4_0 * 8                            ;Octave 10
        dw PLY_AKY_SPL_Step_Oct4_1 * 8
        dw PLY_AKY_SPL_Step_Oct4_2 * 8
        dw PLY_AKY_SPL_Step_Oct4_3 * 8
        dw PLY_AKY_SPL_Step_Oct4_4 * 8
        dw PLY_AKY_SPL_Step_Oct4_5 * 8
        dw PLY_AKY_SPL_Step_Oct4_6 * 8
        dw PLY_AKY_SPL_Step_Oct4_7 * 8
        ;dw PLY_AKY_SPL_Step_Oct4_8 * 8
        ;dw PLY_AKY_SPL_Step_Oct4_9 * 8
        ;dw PLY_AKY_SPL_Step_Oct4_10 * 8
        ;dw PLY_AKY_SPL_Step_Oct4_11 * 8

        assert ($ - PLY_AKY_SPL_StepsTable) == 256
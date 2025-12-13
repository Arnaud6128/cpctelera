    ;Digidrum player, included to the PlayerAkyMultiPsg.
    ;Do not include this player directly to your code, it is included by the aforementioned player directly.
    ;See the testers for a fully working example.

    ;This player requires your PSG in AT3 to have a "sample replay frequency" set to 8000 Hz.
    ;Please check the documentation about how to export the samples in the right format.


;PLY_AKY_SAMPLE_BYTE_PER_FRAME is how many bytes are played every frame. This should be as high as possible to "fill" the VBL.
;It basically indicates the sample replay frequency (trying to reach 8Khz).
;The samples should have a padding of at least this value, else glitches
;are going to be heard at the end of each digidrum.
;Also, PLY_AKG_WASTE_TIME_ITERATION indicates how long to "waste time" between each sample is to the PSG.
;Basically, the aim is to "spread" the sample bytes playing evenly in the frame.

;If these values are too high for your hardware (provoking slower playback when digidrums are played),
;reduce the PLY_AKG_WASTE_TIME_ITERATION, but keep it as high as possible.

PLY_AKY_SAMPLE_BYTE_PER_FRAME = 148         ;Default values.
PLY_AKG_WASTE_TIME_ITERATION = 25

IFDEF PLY_AKY_HARDWARE_MSX
    PLY_AKY_SAMPLE_BYTE_PER_FRAME = 130     ;Tested on emulator (WebMSX) for MSX2+ (PAL).
    PLY_AKG_WASTE_TIME_ITERATION = 22
ENDIF

IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
    PLY_AKY_SAMPLE_BYTE_PER_FRAME = 148     ;Tested on emulator (JSSpeccy3).
    PLY_AKG_WASTE_TIME_ITERATION = 24
ENDIF

;Initializes the digidrums. It must be called before playing the song.
;HL = address of the events (exported from AT).
;DE = address of the sample table (exported from AT).
;A = channel index where the digidrums are (0, 1, 2).
PLY_AKY_InitDigidrums
    dec de      ;The indexes start at 1, so need to shift the table.
    dec de
    ld (PLY_AKY_PT_SampleTable + PLY_AKY_Offset1b),de
    ld b,a
    add a,8         ;To reach registers 8, 9, 10.
    ld (PLY_AKY_SampleVolumeRegister + PLY_AKY_Offset1b),a
    ld a,b
    ;set 0,b = 0xcb 0xc0.
    ;set 1,b = 0xcb 0xc8.
    ;set 2,b = 0xcb 0xd0.
    ;Encoding the second byte of the set instruction.
    add a,a
    add a,a
    add a,a
    add a,#c0
    ld (PLY_AKY_R7CloseChannelOpcode + 1),a ;The second byte is modified (even for ROM).

    ;Sets the first "wait".
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    ld (PLY_AKY_ReadEventsWait + PLY_AKY_Offset1b),bc
    ld (PLY_AKY_PT_Events + PLY_AKY_Offset1b),hl               ;Now points on the sample index to play.

    ld hl,0
    ld (PLY_AKY_PT_Sample + PLY_AKY_Offset1b),hl
    ld a,l
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a
    ret

;Manages the presence or not of the digidrums by reading the event table.
;Called from the player every frame BEFORE the PSG values are sent.
;The stack must NOT be used. Then goes to PLY_AKY_ManageDigidrums_Return.
;IN:    B = R7.
;OUT:   B = R7, modified or not.
PLY_AKY_ManageDigidrums
    IFNDEF PLY_AKY_ROM
PLY_AKY_ReadEventsWait ld hl,1       ;Waiting for the next event. Decreased first.
    ELSE
            ld hl,(PLY_AKY_ReadEventsWait)
    ENDIF
PLY_AKY_PastReadEventsWait
    dec hl
    ld a,l
    or h
    jr z,.waitOver
    ;Wait not over.
    ld (PLY_AKY_ReadEventsWait + PLY_AKY_Offset1b),hl
    jp PLY_AKY_ManageDigidrums_End
.waitOver

    IFNDEF PLY_AKY_ROM
PLY_AKY_PT_Events ld hl,0           ;Reads a new event.
    ELSE
        ld hl,(PLY_AKY_PT_Events)
    ENDIF
    ;A new digidrum is going to be played.
    ld c,(hl)       ;C = sample index (>0 for a digidrum, 0 to do nothing).
    inc hl
    ;Reads the next wait.
.readWait
    ld e,(hl)       ;DE = how many frames (+1) to wait for? 0 = end. 1 = immediately.
    inc hl
    ld d,(hl)
    inc hl
    ld a,e
    or d
    jr nz,.sequenceNotEnded
    ;End of the sequence. Reads the loop to restart to.
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a
    ;Reads the wait.
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld (PLY_AKY_PT_Events + PLY_AKY_Offset1b),hl
    ex de,hl
    jr PLY_AKY_PastReadEventsWait

.sequenceNotEnded
    ld (PLY_AKY_ReadEventsWait + PLY_AKY_Offset1b),de  ;Stores how many frames to wait for next time.
    ld (PLY_AKY_PT_Events + PLY_AKY_Offset1b),hl       ;Stores the address for next iteration (sample index).

;A new digidrum is going to be played.
    ld a,c      ;Unless it is 0, in which case nothing must be played.
    or a
    jp z,PLY_AKY_ManageDigidrums_Return

    IFNDEF PLY_AKY_ROM
PLY_AKY_PT_SampleTable ld de,0
    ELSE
        ld de,(PLY_AKY_PT_SampleTable)
    ENDIF
    ld l,c
    ld h,0
    add hl,hl       ;Sample index * 2.
    add hl,de
    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a          ;HL points on the sample metadata.
    ;Copies the sample start address.
    ld a,b
    ld de,PLY_AKY_PT_Sample + PLY_AKY_Offset1b
    ldi
    ldi
    ;Then the end address.
    ld de,PLY_AKY_PT_SampleEnd + PLY_AKY_Offset1b
    ldi
    ldi
    ld b,a
    ;The follow loop-to address is ignored (digidrums don't loop).

PLY_AKY_ManageDigidrums_End
    ;If a sample is being played, the R7 channel must be closed NOW, before the player is going to
    ;sends this value to the PSG.
    ld hl,(PLY_AKY_PT_Sample + PLY_AKY_Offset1b)
    ld a,l
    or h
    jp z,PLY_AKY_ManageDigidrums_Return
    IFNDEF PLY_AKY_ROM
PLY_AKY_R7CloseChannelOpcode set 1,b     ;The second byte is modified (set 0/1/2 on init).
    ELSE
        jp PLY_AKY_R7CloseChannelOpcode
PLY_AKY_R7CloseChannelOpcode_Return
    ENDIF

    jp PLY_AKY_ManageDigidrums_Return





;Plays a frame of the digidrums, or any if programmed.
;Do NOT use the stack. Use JP to call this. PLY_AKY_PlayDigidrums_Return is called on return.
PLY_AKY_PlayDigidrums
    IFNDEF PLY_AKY_ROM
PLY_AKY_PT_Sample ld hl,0   ;0 means no sample frame to play.
    ELSE
        ld hl,(PLY_AKY_PT_Sample)
    ENDIF
    ld a,l
    or h
    jr nz,.samplePresent
    ;No sample. Allows the player to uses its own volume value.
    xor a
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a
    jp PLY_AKY_PlayDigidrums_Return
.samplePresent

    IFNDEF PLY_AKY_ROM
PLY_AKY_SampleVolumeRegister ld a,0
    ELSE
        ld a,(PLY_AKY_SampleVolumeRegister)
    ENDIF
    ld (PLY_AKY_RegisterToSkip + PLY_AKY_Offset1b),a       ;The player code must not play its own volume.
    ;Selects the digi-channel.
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

    ;Main digidrum loop at 8khz.
    assert PLY_AKY_SAMPLE_BYTE_PER_FRAME < 256      ;A 8-bit counter is used.
    IFDEF PLY_AKY_HARDWARE_PLAYCITY_OR_CPC
        ld de,#f4 * 256 + PLY_AKY_SAMPLE_BYTE_PER_FRAME
        ld c,#f6
    ENDIF
    IFDEF PLY_AKY_HARDWARE_MSX
        ld e,PLY_AKY_SAMPLE_BYTE_PER_FRAME
    ENDIF
    IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
        ld b,#bf    ;C remains #fd.
        ld e,PLY_AKY_SAMPLE_BYTE_PER_FRAME
    ENDIF

.sampleLoop
    IFDEF PLY_AKY_HARDWARE_PLAYCITY_OR_CPC
        ld b,d
        ld a,(hl)
        out (c),a       ;Sends the byte from HL.
        ld b,c
        out (c),a       ;#f680 (a trick, our sample value has its 7th bit to 1).
        out (c),0       ;#f600
        inc hl
    ENDIF
    IFDEF PLY_AKY_HARDWARE_MSX
        ld a,(hl)
        out (PLY_AKY_FAST_PSG_SELECT_VALUE),a
        inc hl
    ENDIF
    IFDEF PLY_AKY_HARDWARE_SPECTRUM_RELATED
        ld a,(hl)
        out (c),a
        inc hl
    ENDIF

    dec e
    jr z,.sampleLoopEnd

    ;Wastes time to reach 8 khz somehow. The loop should last 128 nops on CPC.
    ld a,PLY_AKG_WASTE_TIME_ITERATION
.wasteTime  dec a
    jr nz,.wasteTime
    ds 3,0
    jr .sampleLoop

.sampleLoopEnd

    ex de,hl        ;DE = advanced pointer on the sample.
    ;Are we beyond the sample range?
    IFNDEF PLY_AKY_ROM
PLY_AKY_PT_SampleEnd ld hl,0
    ELSE
        ld hl,(PLY_AKY_PT_SampleEnd)
    ENDIF
    or a
    sbc hl,de
    jr nc,.notEnded
    ;End sample ended.
    ld de,0
.notEnded
    ld (PLY_AKY_PT_Sample + PLY_AKY_Offset1b),de

    jp PLY_AKY_PlayDigidrums_Return

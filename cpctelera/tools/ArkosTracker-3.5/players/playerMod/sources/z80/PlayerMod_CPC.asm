;       Arkos Tracker 3 MOD Player.
;       By Targhan/Arkos, 2018-2025.

;       This plays 3-channel sample music. The name of this file is a misnomer, the input format is not "MOD",
;       but the "RAW" format from AT3, with ONLY these parameters to ON (set the others to OFF):
;       Also explained further here: https://www.julien-nevo.com/arkostracker/index.php/the-mod-player/
;       ------------------------------
;       Encode Song/Subsong metadatas.
;       Encode Reference tables.
;       Encode Speed Tracks.
;       Encode instruments.
;       Encode effects (even if you don’t need them).
;       Encode arpeggios: only if you use them.
;       Encode heights in linker.
;       Pitch Track ratio: 0.25 (but this is an approximation).
;
;       Samples
;       -----------------------------
;       Some very specific tricks are used to make the replay fast. The sample export of AT2 must be configured this way:
;       - The sample MUST be encoded with an "offset" of 128.
;       - The "amplitude" should be between 8 and 10, it's up to you to choose what is best for the song.
;       - It is strongly advised to add a "padding length" of at least "PLY_MOD_IterationCountPerFrame" + 1, else strange things will happen.
;         However, this number must be increased according to the highest note you can use. So 320 may be enough, but raise it to 450/500 if
;         the sound cuts abruptly.

;       "Only" 128 instruments possible (small optimization).
;
;       Only the following effects are supported:
;       - Pitch up/down (not Fast).
;       - Arpeggio table.
;       - Arpeggio 3 notes.
;       - Arpeggio 4 notes.
;       - Reset.
;
;       The stack is diverted: the interruptions must be disabled.

;       Even though the replay code itself is very very fast, the song management is rather slow.
;       The export format is generic and I didn't want to make another converter specific to this player.
;       However, I don't think this is a problem, the music sounds good enough on a CPC.
;       On request, I could make this code convert the Patterns into another format to gain some speed.

PLY_MOD_IterationCountPerFrame equ 312                 ;How many samples to play per frame.
;Very important value. Should be fine, but try fiddle with it according to the song (from #83-85, else it will sound like crap).
PLY_MOD_FillerByte equ #84

PLY_MOD_InstrumentHeaderSize equ 10                    ;How large is the Sample Instrument header.


;Initializes the music.
;IN:    HL = music.
PLY_MOD_Init:
        ;Skips the flags.
        inc hl
        inc hl
        ;Skips the song name, author, composer, comments, subsong title.
        ld b,5
PLY_MOD_Init_SkipLoop:
        call PLY_MOD_Skip0TerminatedString
        djnz PLY_MOD_Init_SkipLoop

        ;Sets the speed.
        ld a,(hl)
        ld (PLY_MOD_Speed + 1),a
        dec a           ;Current speed is speed-1 to force the new line at first iteration.
        ld (PLY_MOD_CurrentSpeed + 1),a

        ;Skips many information, we don't need them.
        ld de,15
        add hl,de
        ld de,PLY_MOD_PtLinker + 1
        ldi
        ldi
        ;Skips the address of the tables for the tracks, speed/event tracks.
        ld de,6
        add hl,de
        ld de,PLY_MOD_PtInstrumentTable + 1
        ldi
        ldi
        ld de,PLY_MOD_PtArpeggioTable + 1
        ldi
        ldi

        ;Cuts all the channels.
        ld hl,#0700 + %00111111
        call PLY_MOD_SetPsg
        ;Nice trick (c) me, to handle overflow of volume.
        ld hl,#0b01
        call PLY_MOD_SetPsg
        ld hl,#0c00
        call PLY_MOD_SetPsg
        ld hl,#0d0d     ;Ramp up and stays up.
        call PLY_MOD_SetPsg
        ;Selects the PSG volume register of the second channel.
        ;Is it important that this is the last PSG selected.
        ld hl,#0900
        call PLY_MOD_SetPsg

        ;Fills the RET table. One iteration is already encoded, so we can directly "LDIR" it.
        ld hl,PLY_MOD_CodeRetTable
        ld de,PLY_MOD_CodeRetTable + 2
        ld bc,(PLY_MOD_IterationCountPerFrame - 1) * 2
        ldir

        ;Replaces the zero-instrument with a sample instrument.
        ld hl,(PLY_MOD_PtInstrumentTable + 1)
        ld (hl),PLY_MOD_Instrument0_Header MOD 256
        inc hl
        ld (hl),(PLY_MOD_Instrument0_Header AND #ff00) / 256

        ;Simulates reading notes of Instrument 0 to set-up everything quickly.
                ld de,PLY_MOD_Channel1Data
        exx
        ld hl,PLY_MOD_InitEmptyInstrumentCell
        call PLY_MOD_ReadTrack

                ld de,PLY_MOD_Channel2Data
        exx
        ld hl,PLY_MOD_InitEmptyInstrumentCell
        call PLY_MOD_ReadTrack

                ld de,PLY_MOD_Channel3Data
        exx
        ld hl,PLY_MOD_InitEmptyInstrumentCell
        jp PLY_MOD_ReadTrack

PLY_MOD_InitEmptyInstrumentCell:
        db 12 * 4
        db 0            ;Instrument 0.
        db 0            ;No effect.


;Finds the next 0, skips it too.
;IN:    HL = Points on 0 zero-terminated string.
;OUT:   HL = Points after the first 0 found.
;MOD:   HL, A.
PLY_MOD_Skip0TerminatedString:
        ld a,(hl)
        inc hl
        or a
        ret z
        jr PLY_MOD_Skip0TerminatedString





;Plays one frame of the music. It must have been initialized before!
PLY_MOD_Play:
        ld (PLY_MOD_SaveSP + 1),sp

        ;Are we at the beginning of a new line?
PLY_MOD_CurrentSpeed: ld a,0
        inc a
PLY_MOD_Speed: cp 1             ;The speed to reach (>0).
        jr nz,PLY_MOD_LineEnd

        ;We must read a new line. But maybe the pattern is over!
PLY_MOD_NewLine:
        ;Is the current Pattern over?
PLY_MOD_PatternHeight: ld a,1
        dec a
        jr nz,PLY_MOD_PatternReadEnd

        ;Reads a new Pattern.
PLY_MOD_PtLinker: ld hl,0
PLY_MOD_LinkerReadTracks:
        ld c,(hl)          ;Track 1, or end if 0.
        inc hl
        ld b,(hl)
        ld a,b
        or c
        jr nz,PLY_MOD_LinkerNotEnd
        ;End of the Song. Where to go to?
        inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld c,(hl)
        inc hl
        ld b,(hl)
PLY_MOD_LinkerNotEnd:
        inc hl
        ld (PLY_MOD_PtTrack1 + 1),bc
        ld de,PLY_MOD_PtTrack2 + 1
        ldi
        ldi
        ld de,PLY_MOD_PtTrack3 + 1
        ldi
        ldi
        ld de,PLY_MOD_PtSpeedTrack + 1
        ldi
        ldi
        ;Gets the Track height.
        ld a,(hl)
        inc hl
        ld (PLY_MOD_PtLinker + 1),hl
PLY_MOD_PatternReadEnd:
        ld (PLY_MOD_PatternHeight + 1),a

        ;Reads the Speed Track.
PLY_MOD_PtSpeedTrack: ld hl,0
        ld a,(hl)
        inc hl
        ld (PLY_MOD_PtSpeedTrack + 1),hl
        or a
        jr z,PLY_MOD_ReadSpeedTrackEnd
        ld (PLY_MOD_Speed + 1),a
PLY_MOD_ReadSpeedTrackEnd:

        ;Reads the Track 1.
                ld de,PLY_MOD_Channel1Data
        exx
PLY_MOD_PtTrack1: ld hl,0
        call PLY_MOD_ReadTrack
        ld (PLY_MOD_PtTrack1 + 1),hl

        ;Reads the Track 2.
                ld de,PLY_MOD_Channel2Data
        exx
PLY_MOD_PtTrack2: ld hl,0
        call PLY_MOD_ReadTrack
        ld (PLY_MOD_PtTrack2 + 1),hl

        ;Reads the Track 3.
                ld de,PLY_MOD_Channel3Data
        exx
PLY_MOD_PtTrack3: ld hl,0
        call PLY_MOD_ReadTrack
        ld (PLY_MOD_PtTrack3 + 1),hl

        xor a
PLY_MOD_LineEnd:
        ld (PLY_MOD_CurrentSpeed + 1),a


        ;Gets the Step of each channel and puts it in the replay code.
        ;Also manages the effects for each, such as Pitch and Arpeggio.
        ld ix,PLY_MOD_Channel1Data
        call PLY_MOD_ManageArpeggio
        call PLY_MOD_ManagePitch
        ld a,l
        ld (PLY_MOD_PS_Step1Decimal + 1),a
        ld a,h
        ld (PLY_MOD_PS_Step1Integer + 1),a

        ld ix,PLY_MOD_Channel2Data
        call PLY_MOD_ManageArpeggio
        call PLY_MOD_ManagePitch
        ld a,l
        ld (PLY_MOD_PS_Step2Decimal + 1),a
        ld a,h
        ld (PLY_MOD_PS_Step2Integer + 1),a

        ld ix,PLY_MOD_Channel3Data
        call PLY_MOD_ManageArpeggio
        call PLY_MOD_ManagePitch
        ld a,l
        ld (PLY_MOD_PS_Step3Decimal + 1),a
        ld a,h
        ld (PLY_MOD_PS_Step3Integer + 1),a



        ;Plays the samples, via the RET table.
                ld hl,(PLY_MOD_Channel3Data_Sample)
PLY_MOD_BaseStep3: ld de,#00f4       ;D' = decimal steps for sample 3.
        exx
        ld hl,(PLY_MOD_Channel1Data_Sample)
        ld de,(PLY_MOD_Channel2Data_Sample)
PLY_MOD_BaseStep12: ld bc,0         ;B/C = decimal steps for sample 1/2.
        ld sp,PLY_MOD_CodeRetTable
        ret
PLY_MOD_CodeRetReturn:
        ;Saves the Steps and sample pointers.
        ld (PLY_MOD_Channel1Data_Sample),hl
        ld (PLY_MOD_Channel2Data_Sample),de
        ld (PLY_MOD_BaseStep12 + 1),bc
        exx
                ld (PLY_MOD_Channel3Data_Sample),hl
                ld a,d
                ld (PLY_MOD_BaseStep3 + 2),a

        ;Manages the sample pointers advance (has a sample reached its end?), for each channel.
        ld sp,PLY_MOD_Channel1Data
        ld iy,PLY_MOD_ManageSampleTracker1_Return
        jp PLY_MOD_ManageSamplePointers
PLY_MOD_ManageSampleTracker1_Return:

        ld sp,PLY_MOD_Channel2Data
        ld iy,PLY_MOD_ManageSampleTracker2_Return
        jp PLY_MOD_ManageSamplePointers
PLY_MOD_ManageSampleTracker2_Return:

        ld sp,PLY_MOD_Channel3Data
        ld iy,PLY_MOD_ManageSampleTracker3_Return
        jp PLY_MOD_ManageSamplePointers
PLY_MOD_ManageSampleTracker3_Return:

PLY_MOD_Exit:
PLY_MOD_SaveSP: ld sp,0
        ret

;Code that plays the samples. Called via a RET table.
;Takes 61 cycles. Try to beat diz!
;IN:    HL = sample 1.
;       DE = sample 2.
;       HL'= sample 3.
;       B = decimal step sample1.
;       C = decimal step sample2.
;       D'= decimal step sample3.
;       E'= #f4
;MOD:
;       B'= PSG.
;       C'= temp for mix.
PLY_MOD_PlaySamples:
        ;Increases the step for sample 1.
        ld a,b
PLY_MOD_PS_Step1Decimal: add a,0
        ld b,a
        ld a,l
PLY_MOD_PS_Step1Integer: adc a,0
        ld l,a
        jr nc,$ + 3
        inc h

        ;Increases the step for sample 2.
        ld a,c
PLY_MOD_PS_Step2Decimal: add a,0
        ld c,a
        ld a,e
PLY_MOD_PS_Step2Integer: adc a,0
        ld e,a
        jr nc,$ + 3
        inc d

        ;Mixes sample 1 and 2.
        ld a,(de)
        add a,(hl)
        exx
                ld c,a

                ;Increases the step for sample 3.
                ld a,d
PLY_MOD_PS_Step3Decimal: add a,0
                ld d,a
                ld a,l
PLY_MOD_PS_Step3Integer: adc a,0
                ld l,a
                jr nc,$ + 3
                inc h

                ;Mixes the whole.
                ld a,(hl)
                add a,c

                ld b,e
                out (c),a       ;#f400 + value.
                ld b,#f6
                out (c),a       ;#f680
                out (c),0
        exx
        ret

;Manages the advance of each sample, makes it loop if it has reached its end.
;IN:    IY = Return address.
;       SP = Channel data block.
PLY_MOD_ManageSamplePointers:
        inc sp          ;Skips the base note.
        ld (PLY_MOD_ManageSamplePointers_SaveSpAfterSteps + 1),sp
        pop hl          ;HL = current sample data pointer.
        pop de          ;DE = end sample.

        ;Have we reached the end? If no, we can quit.
        or a
        sbc hl,de
        jr c,PLY_MOD_ManageSamplePointers_End
        ;Loop (or end of sample).
        pop hl          ;HL = where to loop (0 = no loop).
        ld a,l
        or h
        jr z,PLY_MOD_ManageSamplePointers_NoLoop:
        ;Loop. Encodes HL into the current sample data pointer.
PLY_MOD_ManageSamplePointers_SaveSpAfterSteps: ld sp,0
        pop bc          ;Goes after the value to set.
        push hl
PLY_MOD_ManageSamplePointers_End:
        jp (iy)
PLY_MOD_ManageSamplePointers_NoLoop:
        ;No loop: this means this sample must refer to the empty instrument.
        ;Simply replaces the datablock.
        ld hl,PLY_MOD_EmptyInstrument_DataBlock
        ld de,(PLY_MOD_ManageSamplePointers_SaveSpAfterSteps + 1)
        dec de          ;Goes back to the base note, one byte before.
        ld bc,PLY_MOD_EmptyInstrument_DataBlockEnd - PLY_MOD_EmptyInstrument_DataBlock
        ldir
        jp (iy)




;Reads the given Track.
;IN:    HL = Points on the Track to read.
;       DE'= The channel data block.
;OUT:   HL = Channel data, after the read cell.
PLY_MOD_ReadTrack:
        ;IX now also points on the channel data block, useful for the effects.
        exx
                ld ixl,e
                ld ixh,d
        exx

        ld a,(hl)
        inc hl
        cp 120
        jr z,PLY_MOD_RT_SkipInstrumentAndReadEffect
        jr c,PLY_MOD_RT_NotePresentMaybeEffect
        ;Other value? Then, nothing for this cell.
        ret
PLY_MOD_RT_SkipInstrumentAndReadEffect:
        inc hl          ;Skips the instrument, not needed.
        jr PLY_MOD_RT_ReadEffect
PLY_MOD_RT_NotePresentMaybeEffect:
        ;add 0                  ;Transposes all the notes, if wanted. If doing this, make sure the padding of the empty sound is large enough (see at the end of the source).

        exx
                ;Stores the note.
                ld (de),a
                inc de
        exx
        ;Reads the instrument number.
        ld a,(hl)
        inc hl
        exx
                ;Gets the instrument address.
                add a,a
                ld l,a
                ld h,0
PLY_MOD_PtInstrumentTable: ld bc,0
                add hl,bc
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a
                inc hl          ;Skips the sample type.
                ;Copies the sample pointer.
                ldi
                ldi
                ;Copies the end sample pointer.
                ldi
                ldi
                ;Copies the sample loop address pointer.
                ldi
                ldi
                ;Resets the current pitch
                xor a
                ld (de),a
                inc de
                ld (de),a
                ;Resets the pitch to add.
                inc de
                ld (de),a
                inc de
                ld (de),a
                ;Resets the Arpeggio index.
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex),a
        exx
PLY_MOD_RT_ReadEffect:
        ;Reads the possible effects.
        ld a,(hl)
        inc hl
        or a
        ret z           ;No effect? Exits.

        ;Finds the code of the effect to jump to.
        ;Warning! Effect code will be in auxiliary registers, and must put HL back on exit (or return to "normal" registers).
        ;The effect code must jump to PLY_MOD_RT_ReadEffect, on "normal" registers.
        exx
                add a,a
                add a,a
                ld l,a
                ld h,0
                ld bc,PLY_MOD_RT_EffectJumpTable
                add hl,bc
                jp (hl)
PLY_MOD_RT_ReadEffect_Skip:
        ;Skips the effect data.
        exx
        inc hl
        inc hl
        jr PLY_MOD_RT_ReadEffect

PLY_MOD_RT_EffectJumpTable:
        jp PLY_MOD_RT_ReadEffect_Skip           ;0: No effect.
        nop
        jp PLY_MOD_RT_ReadEffect_PitchUp        ;1: Pitch up.
        nop
        jp PLY_MOD_RT_ReadEffect_PitchDown      ;2: Pitch down.
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;3
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;4
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;5: Volume.
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;6
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;7
        nop
        jp PLY_MOD_RT_ReadEffect_ArpeggioTable  ;8: Arpeggio table.
        nop
        jp PLY_MOD_RT_ReadEffect_Arpeggio3Notes ;9: Arpeggio 3 notes.
        nop
        jp PLY_MOD_RT_ReadEffect_Arpeggio4Notes ;10: Arpeggio 4 notes.
        nop
        jp PLY_MOD_RT_ReadEffect_Reset          ;11: Reset
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;12
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;13
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;14
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;15: Fast pitch up.
        nop
        jp PLY_MOD_RT_ReadEffect_Skip           ;16: Fast pitch down.

;Pitch up.
PLY_MOD_RT_ReadEffect_PitchUp:
        ;Copies the pitch to add to the data for the channel.
        exx
        ld a,(hl)
        inc hl
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 0),a
        ld a,(hl)
        inc hl
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 1),a
        jr PLY_MOD_RT_ReadEffect

;Pitch down.
PLY_MOD_RT_ReadEffect_PitchDown:
        ;Copies the pitch to add to the data for the channel.
        exx

        ld a,(hl)
        inc hl
        cpl
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 0),a

        ld a,(hl)
        inc hl
        cpl
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 1),a
        jp PLY_MOD_RT_ReadEffect

;Reset.
PLY_MOD_RT_ReadEffect_Reset:
        exx
        ;Skips the value, useless.
        inc hl
        inc hl

        ;No more pitch to add.
        xor a
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 0),a
        ld (ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 1),a
        ;No more Arpeggio.
        ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 0),a
        ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 1),a
        jp PLY_MOD_RT_ReadEffect

;Arpeggio Table effect.
PLY_MOD_RT_ReadEffect_ArpeggioTable:
        ;Reads the Arpeggio table index.
        exx
        ld a,(hl)
        inc hl
        exx
                ld e,a
        exx
        ld a,(hl)
        inc hl
        exx
                ld d,a
                ;It is *16 by default
                srl d
                rr e
                srl d
                rr e
                srl d
                rr e
PLY_MOD_PtArpeggioTable: ld hl,0
                add hl,de
                ld a,(hl)       ;Gets the Arpeggio header.
                inc hl
                ld h,(hl)
                ld l,a

                inc hl          ;Skips the length.
                ld a,(hl)       ;Gets the end index.
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataEndIndex),a
                inc hl
                ld a,(hl)       ;Gets the loop index.
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataLoopIndex),a
                inc hl
                inc hl          ;Skips the speed, not used.
                ;HL points now on the the arpeggio data.
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 0),l
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 1),h
                ;The index inside the Arpeggio is 0, of course.
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex),0
        exx

        jp PLY_MOD_RT_ReadEffect

;Arpeggio 3 Notes effect.
PLY_MOD_RT_ReadEffect_Arpeggio3Notes:
        ;Reads the Arpeggio data (-ab-).
        exx

        ld a,(hl)               ;Reads "b-". "b" is on the most significant nibble.
        inc hl
        rra
        rra
        rra
        rra
        and %1111
        ld (ix + PLY_MOD_ChannelDataOffset_InlineArpeggioValue2),a

        ld a,(hl)               ;Reads "-a". The most significant nibble is 0.
        inc hl
        ld (ix + PLY_MOD_ChannelDataOffset_InlineArpeggioValue1),a

        ;Makes the arpeggio pointer points on the the arpeggio data.
        exx
                ld hl,PLY_MOD_ChannelDataOffset_InlineArpeggioValue0
                ld e,ixl
                ld d,ixh
                add hl,de
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 0),l
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 1),h

                ;The index inside the Arpeggio is 0, of course, as well as the loop index.
                xor a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex),a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataLoopIndex),a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataEndIndex),2      ;This Arpeggio has only 3 values.
        exx

        jp PLY_MOD_RT_ReadEffect

;Arpeggio 4 Notes effect.
PLY_MOD_RT_ReadEffect_Arpeggio4Notes:
        ;Reads the Arpeggio data (-abc).
        exx

        ld b,(hl)               ;Reads "bc".
        inc hl
        ld a,b
        and %1111
        ld (ix + PLY_MOD_ChannelDataOffset_InlineArpeggioValue3),a
        ld a,b
        rra
        rra
        rra
        rra
        and %1111
        ld (ix + PLY_MOD_ChannelDataOffset_InlineArpeggioValue2),a

        ld a,(hl)               ;Reads "-a". The most significant nibble is 0.
        inc hl
        ld (ix + PLY_MOD_ChannelDataOffset_InlineArpeggioValue1),a

        ;Makes the arpeggio pointer points on the the arpeggio data.
        exx
                ld hl,PLY_MOD_ChannelDataOffset_InlineArpeggioValue0
                ld e,ixl
                ld d,ixh
                add hl,de
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 0),l
                ld (ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 1),h

                ;The index inside the Arpeggio is 0, of course, as well as the loop index.
                xor a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex),a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataLoopIndex),a
                ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataEndIndex),3      ;This Arpeggio has 4 values.
        exx

        jp PLY_MOD_RT_ReadEffect

;Manages the Pitch effect for the channel the data block is given from.
;This updates the Current Pitch value. In return is the current step to use.
;IN:    IX = Data block of the channel.
;       A = Note to play (= should be base note + arpeggio).
;OUT:   HL = Step.
PLY_MOD_ManagePitch:
        ;Gets the Pitch to Add.
        ld e,(ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 0)
        ld d,(ix + PLY_MOD_ChannelDataOffset_PitchToAdd + 1)

        ;Add it to the "current pitch" (2 bytes).
        ld l,(ix + PLY_MOD_ChannelDataOffset_CurrentPitch + 0)
        ld h,(ix + PLY_MOD_ChannelDataOffset_CurrentPitch + 1)
        add hl,de
        ld (ix + PLY_MOD_ChannelDataOffset_CurrentPitch + 0),l
        ld (ix + PLY_MOD_ChannelDataOffset_CurrentPitch + 1),h

        ;Adds the MSB of the current pitch to the Current Step. Note that it is not modified!
        ld e,h
        ld d,0
        ;Is the pitch negative? If yes, D is #ff.
        bit 7,h
        jr z,$ + 3
        dec d

        ;Finds the step of the current note.
        add a,a         ;Only 7 bits, so all right.
        ld l,a
        ld h,0
        ld bc,PLY_MOD_StepsTable
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a

        add hl,de
        ret


;Manages the Arpeggio effect for the channel the data block is given from.
;If there is no Arpeggio, nothing happens.
;IN:    IX = Data block of the channel.
;OUT:   A = Note + Arpeggio.
PLY_MOD_ManageArpeggio:
        ;Gets the Arpeggio base. If 0, it means there is no Arpeggio.
        ld l,(ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 0)
        ld h,(ix + PLY_MOD_ChannelDataOffset_BaseArpeggioData + 1)
        ld a,l
        or h
        jr z,PLY_MOD_ManageArpeggio_Present        ;No arp. Exits, returning the base note only. Works because A = 0 if no arp!

        ;Gets the current index on the Arp. Has the end index been passed?
        ld a,(ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex)
        ld c,(ix + PLY_MOD_ChannelDataOffset_ArpeggioDataEndIndex)
        cp c
        jr c,PLY_MOD_ManageArpeggio_IndexOk
        ;End index passed. Gets the loop index.
        ld a,(ix + PLY_MOD_ChannelDataOffset_ArpeggioDataLoopIndex)
PLY_MOD_ManageArpeggio_IndexOk:
        ld c,a
        ld b,0

        ;Increases and stores the index for next time.
        inc a
        ld (ix + PLY_MOD_ChannelDataOffset_ArpeggioDataIndex),a

        add hl,bc
        ld a,(hl)               ;A is the Arpeggio value.

        ;Note to play = current note + Arpeggio note.
PLY_MOD_ManageArpeggio_Present:
        add a,(ix + PLY_MOD_ChannelDataOffset_BaseNote)
        ret


;Sends a value to a PSG register.
;IN:    H = Register.
;       L = Value.
PLY_MOD_SetPsg:
        ld b,#f4
        out (c),h
        ld bc,#f6c0
        out (c),c
        out (c),0
        ld b,#f4
        out (c),l
        ld bc,#f680
        out (c),c
        out (c),0
        ret






;Steps for each note, nominal octave.
;Calculated thanks to https://fr.wikipedia.org/wiki/Gamme_temp%C3%A9r%C3%A9e, and ratioed into 256.
PLY_MOD_Step_Oct4_0 equ #0100
PLY_MOD_Step_Oct4_1 equ #0100 + 15     ;15.22
PLY_MOD_Step_Oct4_2 equ #0100 + 31     ;31.35
PLY_MOD_Step_Oct4_3 equ #0100 + 48     ;48.43
PLY_MOD_Step_Oct4_4 equ #0100 + 66     ;66.54
PLY_MOD_Step_Oct4_5 equ #0100 + 86     ;85.72
PLY_MOD_Step_Oct4_6 equ #0100 + 106    ;106.23
PLY_MOD_Step_Oct4_7 equ #0100 + 127    ;127.56
PLY_MOD_Step_Oct4_8 equ #0100 + 150    ;150.37
PLY_MOD_Step_Oct4_9 equ #0100 + 174    ;174.53
PLY_MOD_Step_Oct4_10 equ #0100 + 201   ;200.71
PLY_MOD_Step_Oct4_11 equ #0100 + 227   ;226.90

;Steps for every note.
PLY_MOD_StepsTable:
        dw PLY_MOD_Step_Oct4_0 / 128                            ;Octave 0
        dw PLY_MOD_Step_Oct4_1 / 128
        dw PLY_MOD_Step_Oct4_2 / 128
        dw PLY_MOD_Step_Oct4_3 / 128
        dw PLY_MOD_Step_Oct4_4 / 128
        dw PLY_MOD_Step_Oct4_5 / 128
        dw PLY_MOD_Step_Oct4_6 / 128
        dw PLY_MOD_Step_Oct4_7 / 128
        dw PLY_MOD_Step_Oct4_8 / 128
        dw PLY_MOD_Step_Oct4_9 / 128
        dw PLY_MOD_Step_Oct4_10 / 128
        dw PLY_MOD_Step_Oct4_11 / 128

        dw PLY_MOD_Step_Oct4_0 / 64                            ;Octave 1
        dw PLY_MOD_Step_Oct4_1 / 64
        dw PLY_MOD_Step_Oct4_2 / 64
        dw PLY_MOD_Step_Oct4_3 / 64
        dw PLY_MOD_Step_Oct4_4 / 64
        dw PLY_MOD_Step_Oct4_5 / 64
        dw PLY_MOD_Step_Oct4_6 / 64
        dw PLY_MOD_Step_Oct4_7 / 64
        dw PLY_MOD_Step_Oct4_8 / 64
        dw PLY_MOD_Step_Oct4_9 / 64
        dw PLY_MOD_Step_Oct4_10 / 64
        dw PLY_MOD_Step_Oct4_11 / 64

        dw PLY_MOD_Step_Oct4_0 / 32                            ;Octave 2
        dw PLY_MOD_Step_Oct4_1 / 32
        dw PLY_MOD_Step_Oct4_2 / 32
        dw PLY_MOD_Step_Oct4_3 / 32
        dw PLY_MOD_Step_Oct4_4 / 32
        dw PLY_MOD_Step_Oct4_5 / 32
        dw PLY_MOD_Step_Oct4_6 / 32
        dw PLY_MOD_Step_Oct4_7 / 32
        dw PLY_MOD_Step_Oct4_8 / 32
        dw PLY_MOD_Step_Oct4_9 / 32
        dw PLY_MOD_Step_Oct4_10 / 32
        dw PLY_MOD_Step_Oct4_11 / 32

        dw PLY_MOD_Step_Oct4_0 / 16                            ;Octave 3
        dw PLY_MOD_Step_Oct4_1 / 16
        dw PLY_MOD_Step_Oct4_2 / 16
        dw PLY_MOD_Step_Oct4_3 / 16
        dw PLY_MOD_Step_Oct4_4 / 16
        dw PLY_MOD_Step_Oct4_5 / 16
        dw PLY_MOD_Step_Oct4_6 / 16
        dw PLY_MOD_Step_Oct4_7 / 16
        dw PLY_MOD_Step_Oct4_8 / 16
        dw PLY_MOD_Step_Oct4_9 / 16
        dw PLY_MOD_Step_Oct4_10 / 16
        dw PLY_MOD_Step_Oct4_11 / 16

        dw PLY_MOD_Step_Oct4_0 / 8                            ;Octave 4
        dw PLY_MOD_Step_Oct4_1 / 8
        dw PLY_MOD_Step_Oct4_2 / 8
        dw PLY_MOD_Step_Oct4_3 / 8
        dw PLY_MOD_Step_Oct4_4 / 8
        dw PLY_MOD_Step_Oct4_5 / 8
        dw PLY_MOD_Step_Oct4_6 / 8
        dw PLY_MOD_Step_Oct4_7 / 8
        dw PLY_MOD_Step_Oct4_8 / 8
        dw PLY_MOD_Step_Oct4_9 / 8
        dw PLY_MOD_Step_Oct4_10 / 8
        dw PLY_MOD_Step_Oct4_11 / 8

        dw PLY_MOD_Step_Oct4_0 / 4                            ;Octave 5
        dw PLY_MOD_Step_Oct4_1 / 4
        dw PLY_MOD_Step_Oct4_2 / 4
        dw PLY_MOD_Step_Oct4_3 / 4
        dw PLY_MOD_Step_Oct4_4 / 4
        dw PLY_MOD_Step_Oct4_5 / 4
        dw PLY_MOD_Step_Oct4_6 / 4
        dw PLY_MOD_Step_Oct4_7 / 4
        dw PLY_MOD_Step_Oct4_8 / 4
        dw PLY_MOD_Step_Oct4_9 / 4
        dw PLY_MOD_Step_Oct4_10 / 4
        dw PLY_MOD_Step_Oct4_11 / 4

        dw PLY_MOD_Step_Oct4_0 / 2                            ;Octave 6
        dw PLY_MOD_Step_Oct4_1 / 2
        dw PLY_MOD_Step_Oct4_2 / 2
        dw PLY_MOD_Step_Oct4_3 / 2
        dw PLY_MOD_Step_Oct4_4 / 2
        dw PLY_MOD_Step_Oct4_5 / 2
        dw PLY_MOD_Step_Oct4_6 / 2
        dw PLY_MOD_Step_Oct4_7 / 2
        dw PLY_MOD_Step_Oct4_8 / 2
        dw PLY_MOD_Step_Oct4_9 / 2
        dw PLY_MOD_Step_Oct4_10 / 2
        dw PLY_MOD_Step_Oct4_11 / 2

        dw PLY_MOD_Step_Oct4_0                                ;Octave 7
        dw PLY_MOD_Step_Oct4_1
        dw PLY_MOD_Step_Oct4_2
        dw PLY_MOD_Step_Oct4_3
        dw PLY_MOD_Step_Oct4_4
        dw PLY_MOD_Step_Oct4_5
        dw PLY_MOD_Step_Oct4_6
        dw PLY_MOD_Step_Oct4_7
        dw PLY_MOD_Step_Oct4_8
        dw PLY_MOD_Step_Oct4_9
        dw PLY_MOD_Step_Oct4_10
        dw PLY_MOD_Step_Oct4_11

        dw PLY_MOD_Step_Oct4_0 * 2                            ;Octave 8
        dw PLY_MOD_Step_Oct4_1 * 2
        dw PLY_MOD_Step_Oct4_2 * 2
        dw PLY_MOD_Step_Oct4_3 * 2
        dw PLY_MOD_Step_Oct4_4 * 2
        dw PLY_MOD_Step_Oct4_5 * 2
        dw PLY_MOD_Step_Oct4_6 * 2
        dw PLY_MOD_Step_Oct4_7 * 2
        dw PLY_MOD_Step_Oct4_8 * 2
        dw PLY_MOD_Step_Oct4_9 * 2
        dw PLY_MOD_Step_Oct4_10 * 2
        dw PLY_MOD_Step_Oct4_11 * 2

        dw PLY_MOD_Step_Oct4_0 * 4                            ;Octave 9
        dw PLY_MOD_Step_Oct4_1 * 4
        dw PLY_MOD_Step_Oct4_2 * 4
        dw PLY_MOD_Step_Oct4_3 * 4
        dw PLY_MOD_Step_Oct4_4 * 4
        dw PLY_MOD_Step_Oct4_5 * 4
        dw PLY_MOD_Step_Oct4_6 * 4
        dw PLY_MOD_Step_Oct4_7 * 4
        dw PLY_MOD_Step_Oct4_8 * 4
        dw PLY_MOD_Step_Oct4_9 * 4
        dw PLY_MOD_Step_Oct4_10 * 4
        dw PLY_MOD_Step_Oct4_11 * 4

        dw PLY_MOD_Step_Oct4_0 * 8                            ;Octave 10
        dw PLY_MOD_Step_Oct4_1 * 8
        dw PLY_MOD_Step_Oct4_2 * 8
        dw PLY_MOD_Step_Oct4_3 * 8
        dw PLY_MOD_Step_Oct4_4 * 8
        dw PLY_MOD_Step_Oct4_5 * 8
        dw PLY_MOD_Step_Oct4_6 * 8
        dw PLY_MOD_Step_Oct4_7 * 8
        ;dw PLY_MOD_Step_Oct4_8 * 8
        ;dw PLY_MOD_Step_Oct4_9 * 8
        ;dw PLY_MOD_Step_Oct4_10 * 8
        ;dw PLY_MOD_Step_Oct4_11 * 8

        assert ($ - PLY_MOD_StepsTable) == 256


;The data block for the Channel 1.
PLY_MOD_Channel1Data:
PLY_MOD_Channel1Data_BaseNote: db 0     ;The base note (without arpeggio).
;This MUST match the header of an Instrument!
PLY_MOD_Channel1Data_Sample: dw 0
PLY_MOD_Channel1Data_SampleEnd: dw 0
PLY_MOD_Channel1Data_SampleLoop: dw 0   ;Or 0 if not looping.
PLY_MOD_Channel1Data_PitchToAdd: dw 0   ;Pitch to add to the current pitch (as read in the Track). Does not change (unless new effect/effect stops).
PLY_MOD_Channel1Data_CurrentPitch: dw 0   ;Pitch to add to the step (integer/decimal).

PLY_MOD_Channel1Data_BaseArpeggioData: dw 0   ;0 = No arp, or points on the base of the current Arpeggio data (does not evolve, unless a new Arpeggio is used).
PLY_MOD_Channel1Data_ArpeggioDataIndex: db 0   ;The current index within the arpeggio data. Evolves.
PLY_MOD_Channel1Data_ArpeggioDataLoopIndex: db 0
PLY_MOD_Channel1Data_ArpeggioDataEndIndex: db 0
PLY_MOD_Channel1Data_InlineArpeggioValue0: db 0                 ;Value 0 for effect B/C. Always 0!
PLY_MOD_Channel1Data_InlineArpeggioValue1: db 0                 ;Value 1 for effect B/C.
PLY_MOD_Channel1Data_InlineArpeggioValue2: db 0                 ;Value 2 for effect B/C.
PLY_MOD_Channel1Data_InlineArpeggioValue3: db 0                 ;Value 3 for effect C.
PLY_MOD_Channel1DataEnd:

        ;The inline arpeggio must be in a row!
        assert (PLY_MOD_Channel1Data_InlineArpeggioValue1 - PLY_MOD_Channel1Data_InlineArpeggioValue0) == 1
        assert (PLY_MOD_Channel1Data_InlineArpeggioValue2 - PLY_MOD_Channel1Data_InlineArpeggioValue1) == 1
        assert (PLY_MOD_Channel1Data_InlineArpeggioValue3 - PLY_MOD_Channel1Data_InlineArpeggioValue2) == 1

PLY_MOD_ChannelDataSize equ PLY_MOD_Channel1DataEnd - PLY_MOD_Channel1Data

;The data block for the Channel 2 and 3.
PLY_MOD_Channel2Data: ds PLY_MOD_ChannelDataSize, 0
PLY_MOD_Channel3Data: ds PLY_MOD_ChannelDataSize, 0

PLY_MOD_ChannelDataOffset_BaseNote equ PLY_MOD_Channel1Data_BaseNote - PLY_MOD_Channel1Data
;PLY_MOD_ChannelDataOffset_Step equ PLY_MOD_Channel1Data_Step - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_Sample equ PLY_MOD_Channel1Data_Sample - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_PitchToAdd equ PLY_MOD_Channel1Data_PitchToAdd - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_CurrentPitch equ PLY_MOD_Channel1Data_CurrentPitch - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_BaseArpeggioData equ PLY_MOD_Channel1Data_BaseArpeggioData - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_ArpeggioDataIndex equ PLY_MOD_Channel1Data_ArpeggioDataIndex - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_ArpeggioDataLoopIndex equ PLY_MOD_Channel1Data_ArpeggioDataLoopIndex - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_ArpeggioDataEndIndex equ PLY_MOD_Channel1Data_ArpeggioDataEndIndex - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_InlineArpeggioValue0 equ PLY_MOD_Channel1Data_InlineArpeggioValue0 - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_InlineArpeggioValue1 equ PLY_MOD_Channel1Data_InlineArpeggioValue1 - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_InlineArpeggioValue2 equ PLY_MOD_Channel1Data_InlineArpeggioValue2 - PLY_MOD_Channel1Data
PLY_MOD_ChannelDataOffset_InlineArpeggioValue3 equ PLY_MOD_Channel1Data_InlineArpeggioValue3 - PLY_MOD_Channel1Data

PLY_MOD_Channel2Data_Sample equ PLY_MOD_Channel2Data + PLY_MOD_ChannelDataOffset_Sample
PLY_MOD_Channel3Data_Sample equ PLY_MOD_Channel3Data + PLY_MOD_ChannelDataOffset_Sample
PLY_MOD_Channel2Data_PitchToAdd equ PLY_MOD_Channel2Data + PLY_MOD_ChannelDataOffset_PitchToAdd
PLY_MOD_Channel3Data_PitchToAdd equ PLY_MOD_Channel3Data + PLY_MOD_ChannelDataOffset_PitchToAdd
PLY_MOD_Channel2Data_CurrentPitch equ PLY_MOD_Channel2Data + PLY_MOD_ChannelDataOffset_CurrentPitch
PLY_MOD_Channel3Data_CurrentPitch equ PLY_MOD_Channel3Data + PLY_MOD_ChannelDataOffset_CurrentPitch

;RET table of all the sample call.
PLY_MOD_CodeRetTable:
        dw PLY_MOD_PlaySamples
        ds (PLY_MOD_IterationCountPerFrame - 1) * 2, 0            ;-1 because we have added one already.
        dw PLY_MOD_CodeRetReturn

;The datablock to use when a sample is empty.
PLY_MOD_EmptyInstrument_DataBlock:
        db 0            ;Note = 0.
        dw PLY_MOD_SampleEmpty
        dw PLY_MOD_SampleEmpty_End - 1
        dw PLY_MOD_SampleEmpty
        ds PLY_MOD_Channel1DataEnd - PLY_MOD_Channel1Data_SampleLoop - 2, 0
PLY_MOD_EmptyInstrument_DataBlockEnd:
        assert $ - PLY_MOD_EmptyInstrument_DataBlock == PLY_MOD_ChannelDataSize

;The "empty" instrument.
PLY_MOD_Instrument0_Header:
        db 1            ;Instrument type (sample).
        dw PLY_MOD_SampleEmpty
        dw PLY_MOD_SampleEmpty_End - 1
        dw PLY_MOD_SampleEmpty
PLY_MOD_Instrument0_HeaderEnd:
        dw 0              ;Pitch to add.
        dw 0              ;Current pitch.

;"Empty" sample data.
PLY_MOD_SampleEmpty: ds PLY_MOD_IterationCountPerFrame, PLY_MOD_FillerByte
PLY_MOD_SampleEmpty_End
;Some padding is necessary after the "empty" sound, especially if transpositing the notes, as the "empty" note will also be transposed.
        ds PLY_MOD_IterationCountPerFrame / 2, PLY_MOD_FillerByte

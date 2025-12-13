        ;Base code for the serial. It requires some methods to be defined, which
        ;the specialized sources provide.

COMMAND_INIT equ #ff           ;Sets the PSG frequencies.
COMMAND_FRAME equ #fe          ;A frame of PSG registers.
COMMAND_STOP_SOUNDS equ #fd    ;Stops all the sounds.

;Buffer where all the data is put, one PSG data after the other. Before each, a PSG index (>=0) or 255 to mark the end.
PsgBufferOffsetR13 equ 13
PsgBufferOffsetIsRetrig equ PsgBufferOffsetR13 + 1
PsgBufferOffsetPreviousR13 equ PsgBufferOffsetIsRetrig + 1

PsgBufferSize equ PsgBufferOffsetPreviousR13 + 1           ;How many registers are stored per PSG, in a frame. 0-13 + 1 for Retrig? + 1 for old R13.

Start:        
        ;Iniializes the input hardware.
        call Initialize
        jr nc,OnInitializeFailed
        
        ;Initializes the sound card.
        call InitializeSoundHardware
        
MainLoop:       
        ;Reads the serial.
        call GetNextByteAndStopSoundIfTimeout
        
        ;What command?
        cp COMMAND_FRAME
        jp z,OnFrameCommandReceived
        cp COMMAND_STOP_SOUNDS
        jr z,OnStopSoundsCommandReceived
        cp COMMAND_INIT
        jr z,OnInitCommandReceived
        ;Command unknown!
        jr OnError
        
;Error! Stops.
OnError:
        call ShowError
        jr $

OnWrongPsgError:
        ld bc,#7f10
        out (c),c
OnWrongPsgError_Loop:
        ld a,#4b
        out (c),a
        ld a,#54
        out (c),a
        jr OnWrongPsgError_Loop

;Waits indefinitely for a byte in the buffer, and returns it.
;However, if too much certain time is spent, the sound is stopped. This is useful if
;the server stops the connection, we don't want the CPC sound to hang.
;OUT:   A = value.
;MOD:   BC.
GetNextByteAndStopSoundIfTimeout:
        call ShowWaitStart
        call WaitForByteWithTimeout
        call ShowWaitOver

        call ReadPresentByte
        ret

;Stops all the sounds of the PSG.
;This is useful for a "normal" PSG. Specific hardware may need something different.
;IN:    D = PSG number (may be useful for specific implementation of SendPsgRegister).
;MOD:   HL, DE, BC preserved.
StopSoundsGeneric:
        push hl
        push de
        push bc
        IFDEF MACHINE_MSX
                ld hl,#0700 + %10111111         ;On MSX, bit 7 must be 1 and bit 6 must be 0.
        ELSE
                ld hl,#0700 + %00111111         ;On CPC, bit 6 must be 0.
        ENDIF
        call SendPsgRegister
        ld hl,#0800
        call SendPsgRegister
        inc h
        call SendPsgRegister
        inc h
        call SendPsgRegister
        pop bc
        pop de
        pop hl
        ret
 
ShowWaitStart:
        ld bc,#7f10
        out (c),c
        ld c,#55
        out (c),c
        ret

ShowWaitOver:
        ld bc,#7f10
        out (c),c
        ld c,#54
        out (c),c
        ret
        
ShowError:
        ld bc,#7f10
        out (c),c
        ld c,#4c
        out (c),c
        ret
        
OnInitializeFailed:
        ld bc,#7f10
        out (c),c
        ld c,#4b
        out (c),c
        jr $
        

;A Stop sound command is received.
OnStopSoundsCommandReceived:
        call StopSounds
        jp MainLoop
        
;An Init command is received.
OnInitCommandReceived:
        ;Get the replay frequency in Hz. We actually don't need it, skip.
        call GetNextByteAndStopSoundIfTimeout
        call GetNextByteAndStopSoundIfTimeout
        
        ;Get PSG count.
        call GetNextByteAndStopSoundIfTimeout
        ld h,a
        
        ;Writes everything in a buffer.
        ld l,0  ;Current PSG.
OnInitCommandReceived_ReadLoop:
        ld ix,Buffer
        ;Writes the PSG frequency (4 bytes).
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a
        inc ix
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a
        inc ix
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a
        inc ix
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a

        ;Applies this frequency for this PSG.
        ld ix,Buffer
        ld a,l          ;Current PSG.
        call InitializePsgWithFrequency
        
        ;More PSG frequency to encode?
        inc l
        ld a,l
        cp h
        jr nz,OnInitCommandReceived_ReadLoop
        
        jp MainLoop

;A Frame is received. Read all the registers!
OnFrameCommandReceived:
        ld ix,Buffer
        
OnFrameCommandReceived_Loop:
        ;What PSG?
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a                   ;Marks the end, or the PSG index.
        inc ix
        
        cp 255                          ;End of the command. We can play what has been read.
        jp z,PlayFrame
        
        call ReadAndDepackFrameRegistersOfOnePsg

        ;Reads the other PSGs.          ;FIXME Simplistic, we should note, in the buffer, which are the PSGs to read.        
        jr OnFrameCommandReceived_Loop
        
;Reads and depacks a frame registers, for one PSG only. The PSG number must already have been read.
;IN:    IX = where to store the data. The PSG index is NOT written by this method, only the registers.
;OUT:   IX = after the written data.
ReadAndDepackFrameRegistersOfOnePsg:
        ;LSB of the software periods.
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 0),a
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 2),a
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 4),a
        
        ;Hardware period.
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 11),a
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 12),a
        
        ;Software period MSB 1 & 2, mixed.
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 1),a           ;No need to discard the most significant quartet.
        rra
        rra
        rra
        rra
        ld (ix + 3),a
        
        ;Software period MSB 3 + volume 1 (4bits only).
        call GetNextByteAndStopSoundIfTimeout
        ld h,a
        and %1111
        ld (ix + 8),a           ;Volume, incomplete for now, bit 5 missing.
        ld a,h
        rra                     ;Transfer bits 7-4 to 3-0.
        rra
        rra
        rra
        ld (ix + 5),a           ;No need to discard the most significant quartet.        
        
        ;Volume 2 & 3 (4bits only).
        call GetNextByteAndStopSoundIfTimeout
        ld h,a
        and %1111
        ld (ix + 9),a           ;Incomplete for now, bit 5 missing.
        ld a,h
        rra                     ;Transfer bits 7-4 to 3-0.
        rra
        rra
        rra
        and %1111
        ld (ix + 10),a          ;Incomplete for now, bit 5 missing.
        
        ;Noise + hardware volume bits.
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 6),a           ;Noise, no need to discard the useless bits.
        ;If hardware bits are present, report them on the related volume bit 4.
        bit 5,a
        jr z,ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel1
        set 4,(ix + 8)
ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel1:

        bit 6,a
        jr z,ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel2
        set 4,(ix + 9)
ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel2:

        bit 7,a
        jr z,ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel3
        set 4,(ix + 10)
ReadAndDepackFrameRegistersOfOnePsg_NoHardwareOnChannel3:

        ;Mixer (6b) + retrig?
        call GetNextByteAndStopSoundIfTimeout
        ld h,a
        and %00111111
        ld (ix + 7),a
        ld a,h
        and %01000000
        ld (ix + PsgBufferOffsetIsRetrig),a
        
        ;R13.
        call GetNextByteAndStopSoundIfTimeout
        ld (ix + 13),a
        
        ;Goes after the buffer.
        ld de,PsgBufferSize
        add ix,de
        ret
        
;Plays the frame of the read registers. It does not have any form of sync, we rely on the accuracy of the received frames! Seems to work fine.
PlayFrame:
        ld ix,Buffer
        
PlayFrame_Loop:
        ;What PSG number? Or no PSG to read anymore?
        ld a,(ix + 0)
        cp #ff
        jp z,MainLoop
        inc ix
        
        ;Selects the PSG, if the implementation allows it.
        call SelectPsg
        call PlayRegisters

        jp PlayFrame_Loop

;Plays the registers.
;IN:    IX = the buffer of the registers.
;       A = PSG index (>=0).
;OUT:   IX = after the buffer.
PlayRegisters:
        ld d,a
        ld e,13

        ;Plays the registers from 0 to 12, included.
        ld h,0
PlayRegisters_Loop:
        ld l,(ix + 0)
        call SendPsgRegister
        
        inc ix
        
        inc h
        ld a,h
        cp 13
        jr nz,PlayRegisters_Loop
        
        ;R13 must be sent, but only if different.
        ld a,(ix + 0)
        ld l,a
        cp (ix + PsgBufferOffsetPreviousR13 - PsgBufferOffsetR13)
        jr nz,PlayRegisters_PlayR13
        ;R13 is the same. Is there a Retrig?
        ld a,(ix + PsgBufferOffsetIsRetrig - PsgBufferOffsetR13)
        or a
        jr z,PlayRegisters_End
        ;There is a retrig, so plays the R13 anyway.
        
PlayRegisters_PlayR13:
        call SendPsgRegister
        ld (ix + PsgBufferOffsetPreviousR13 - PsgBufferOffsetR13),l        ;Stores the new R13.
   
PlayRegisters_End:
        ;Skips R13, isRetrig, previousR13.
        inc ix
        inc ix
        inc ix
        ret
;       AKY music player - V1.0
;       Atari XL/XE; Card: SONari
;       By Krzysztof Dudek (xxl)
;       March 2021

AYR EQU $D560
AYD EQU $D561

ZP  EQU $80

AKY_RegisterBlock EQU ZP+0 ; word
AKY_TOKEN         EQU ZP+2 ; byte   / doesn't have to be on ZP
AKY_PtLinker      EQU ZP+3 ; word
AKY_PatternFrameCounter EQU ZP+5 ; word  / doesn't have to be on ZP

AKY_ChannelC1_WaitBeforeNextRegisterBlock   EQU ZP+7 ; byte  / keep order. / doesn't have to be on ZP
AKY_ChannelC1_PtRegisterBlock               EQU ZP+8 ; word                / doesn't have to be on ZP
AKY_ChannelC2_WaitBeforeNextRegisterBlock   EQU ZP+10 ; byte               / doesn't have to be on ZP
AKY_ChannelC2_PtRegisterBlock               EQU ZP+11 ; word               / doesn't have to be on ZP
AKY_ChannelC3_WaitBeforeNextRegisterBlock   EQU ZP+13 ; byte               / doesn't have to be on ZP
AKY_ChannelC3_PtRegisterBlock               EQU ZP+14 ; word               / doesn't have to be on ZP

AKY_ChannelC1_PtTrack     EQU ZP+16 ; word        ; keep order.
AKY_ChannelC2_PtTrack     EQU ZP+18 ; word
AKY_ChannelC3_PtTrack     EQU ZP+20 ; word

AKY_ChannelC1_RegisterBlockLineState     EQU ZP+22 ; byte  / doesn't have to be on ZP        .
AKY_ChannelC2_RegisterBlockLineState     EQU ZP+23 ; byte  / doesn't have to be on ZP
AKY_ChannelC3_RegisterBlockLineState     EQU ZP+24 ; byte  / doesn't have to be on ZP


            ; +0     - PLAY
            ; +3     - INIT

            JMP AKY_Play

AKY_Init    STY AKY_PtLinker
            STX AKY_PtLinker+1
            LDX #$01
            STX AKY_ChannelC1_RegisterBlockLineState
            STX AKY_ChannelC2_RegisterBlockLineState
            STX AKY_ChannelC3_RegisterBlockLineState
            STX AKY_PatternFrameCounter
            DEX
            STX AKY_PatternFrameCounter+1
            RTS
; =====================================
AKY_Play    LDA AKY_PatternFrameCounter
            BNE @+
            DEC AKY_PatternFrameCounter+1
@           DEC AKY_PatternFrameCounter
            BNE @+
            LDY AKY_PatternFrameCounter+1
            BEQ AKY_PatternFrameCounter_Over
@           JMP AKY_Channel1_WaitBeforeNextRegisterBlock

AKY_PatternFrameCounter_Over
            LDA (AKY_PtLinker),Y
            STA AKY_PatternFrameCounter
            INY
            LDA (AKY_PtLinker),Y
            STA AKY_PatternFrameCounter+1
            ORA AKY_PatternFrameCounter
            BNE AKY_LinkerNotEndSong
            INY                        ; 0000 - JMP
            LDA (AKY_PtLinker),Y
            TAX
            INY
            LDA (AKY_PtLinker),Y
            STA AKY_PtLinker+1
            STX AKY_PtLinker
            LDY #$00
            BEQ AKY_PatternFrameCounter_Over       ; RELOADED

AKY_LinkerNotEndSong
@           INY
            LDA (AKY_PtLinker),Y
            STA AKY_ChannelC1_PtTrack-2,Y                 ; -2
            CPY #$07
            BCC @-
            TYA           ; 7+c=1 +8  for 1xPSG
            ADC AKY_PtLinker
            STA AKY_PtLinker
            BCC @+
            INC AKY_PtLinker+1

@           LDA #01
            STA AKY_ChannelC1_WaitBeforeNextRegisterBlock
            STA AKY_ChannelC2_WaitBeforeNextRegisterBlock
            STA AKY_ChannelC3_WaitBeforeNextRegisterBlock

; =====================================
AKY_Channel1_WaitBeforeNextRegisterBlock

            DEC AKY_ChannelC1_WaitBeforeNextRegisterBlock
            BNE AKY_Channel1_RegisterBlock_Process
            LDA #$01 ;c=1 initial state
            STA AKY_ChannelC1_RegisterBlockLineState
            LDY #00
@           LDA (AKY_ChannelC1_PtTrack),Y
            STA AKY_ChannelC1_WaitBeforeNextRegisterBlock,Y
            INY
            CPY #$03
            BCC @-
            LDA #$02                       ; C=1
            ADC AKY_ChannelC1_PtTrack      ; +3
            STA AKY_ChannelC1_PtTrack
            BCC AKY_Channel1_RegisterBlock_Process
            INC AKY_ChannelC1_PtTrack+1
AKY_Channel1_RegisterBlock_Process

            DEC AKY_ChannelC2_WaitBeforeNextRegisterBlock
            BNE AKY_Channel2_RegisterBlock_Process
            LDA #$01 ;c=1 initial state
            STA AKY_ChannelC2_RegisterBlockLineState
            LDY #00
@           LDA (AKY_ChannelC2_PtTrack),Y
            STA AKY_ChannelC2_WaitBeforeNextRegisterBlock,Y
            INY
            CPY #$03
            BCC @-
            LDA #$02                       ; C=1
            ADC AKY_ChannelC2_PtTrack      ; +3
            STA AKY_ChannelC2_PtTrack
            BCC AKY_Channel2_RegisterBlock_Process
            INC AKY_ChannelC2_PtTrack+1
AKY_Channel2_RegisterBlock_Process

            DEC AKY_ChannelC3_WaitBeforeNextRegisterBlock
            BNE AKY_Channel3_RegisterBlock_Process
            LDA #$01 ;c=1 initial state
            STA AKY_ChannelC3_RegisterBlockLineState
            LDY #00
@           LDA (AKY_ChannelC3_PtTrack),Y
            STA AKY_ChannelC3_WaitBeforeNextRegisterBlock,Y
            INY
            CPY #$03
            BCC @-
            LDA #$02                       ; C=1
            ADC AKY_ChannelC3_PtTrack      ; +3
            STA AKY_ChannelC3_PtTrack
            BCC AKY_Channel3_RegisterBlock_Process
            INC AKY_ChannelC3_PtTrack+1
AKY_Channel3_RegisterBlock_Process

; =====================================
            LDA #$38       ; 0011 1000
            STA AKY_MixerControlEnable

            LDX #$00
            ;Channel 1
            LDY #$00
            LSR AKY_ChannelC1_RegisterBlockLineState
            JSR AKY_ReadRegisterBlock
            TYA
            CLC
            ADC AKY_RegisterBlock
            STA AKY_ChannelC1_PtRegisterBlock
            LDA AKY_RegisterBlock+1
            ADC #$00
            STA AKY_ChannelC1_PtRegisterBlock+1

            INX
            ;Channel 2
            LDY #$03
            LSR AKY_ChannelC2_RegisterBlockLineState
            JSR AKY_ReadRegisterBlock
            TYA
            CLC
            ADC AKY_RegisterBlock
            STA AKY_ChannelC2_PtRegisterBlock
            LDA AKY_RegisterBlock+1
            ADC #$00
            STA AKY_ChannelC2_PtRegisterBlock+1

            INX
            ;Channel 3
            LDY #$06
            LSR AKY_ChannelC3_RegisterBlockLineState
            JSR AKY_ReadRegisterBlock
            TYA
            CLC
            ADC AKY_RegisterBlock
            STA AKY_ChannelC3_PtRegisterBlock
            LDA AKY_RegisterBlock+1
            ADC #$00
            STA AKY_ChannelC3_PtRegisterBlock+1

            LDA #$07
            STA AYR
            LDA AKY_MixerControlEnable
            STA AYD

            LDA #$06
            STA AYR
            LDA AKY_NoiseGeneratorControl
            STA AYD

            LDA #11
            STA AYR
            LDA AKY_EnvelopePeriodControl
            STA AYD

            LDA #12
            STA AYR
            LDA AKY_EnvelopePeriodControl+1
            STA AYD

            LDA AKY_EnvelopeShapeControl
            CMP AKY_EnvelopeShapeControlOld
            BEQ @+
            STA AKY_EnvelopeShapeControlOld
            LDX #13
            STX AYR
            STA AYD

@           RTS                 ; end

; =====================================
AKY_ReadRegisterBlock
            LDA AKY_ChannelC1_PtRegisterBlock,Y
            STA AKY_RegisterBlock
            LDA AKY_ChannelC1_PtRegisterBlock+1,Y
            STA AKY_RegisterBlock+1
            LDY #$00
            LDA (AKY_RegisterBlock),Y
; type
; 00 = no software no hardware.
; 01 = software only.
; 10 = hardware only.
; 11 = software and hardware.
            INY

            BCS @+               ; INITIAL STATE
            JMP AKY_RRB_NonInitialState
@
            LSR @
            BCS AKY_RRB_IS_SoftwareOnlyOrSoftwareAndHardware
            LSR @
            BCS AKY_RRB_IS_HardwareOnly

; =====================================
AKY_RRB_IS_NoSoftwareNoHardware
; 7  6  5  4  3  2  1  0
; 0  v  v  v  v  n  t  t
; n = noise?
; v = volume

            LSR @
            PHA
            BCC AKY_RRB_NIS_NoSoftwareNoHardware_ReadVolume
            LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable

AKY_RRB_NIS_NoSoftwareNoHardware_ReadVolume
            LDA AKY_AmplitudeControl,X
            STA AYR
            PLA
            STA AYD
            LDA AKY_MixerControlEnableTone,X
            ORA AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            RTS

; =====================================
AKY_RRB_IS_HardwareOnly
; 7  6  5  4  3  2  1  0
; e  e  e  e  n  r  t  t
; r = retrig?
; n = noise?
; e = envelope

            LSR @
            BCC AKY_RRB_IS_HO_NoRetrig
            ROR AKY_EnvelopeShapeControlOld    ; C=1
AKY_RRB_IS_HO_NoRetrig
            LSR @
            PHA
            BCC AKY_RRB_IS_HO_NoNoise
            LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable
AKY_RRB_IS_HO_NoNoise
            PLA
            STA AKY_EnvelopeShapeControl
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl
            INY
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl+1
            INY
            LDA AKY_MixerControlEnableTone,X
            ORA AKY_MixerControlEnable
            STA AKY_MixerControlEnable

            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA #$10
            STA AYD
            RTS

; =====================================
AKY_RRB_IS_SoftwareOnlyOrSoftwareAndHardware
            LSR @
            BCS AKY_RRB_IS_SoftwareAndHardware

AKY_RRB_IS_SoftwareOnly
; 7  6  5  4  3  2  1  0
; 0  v  v  v  v  n  t  t
; n = noise?
; v = volume.

            LSR @
            PHA
            BCC AKY_RRB_IS_SoftwareOnly_NoNoise
            LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable

AKY_RRB_IS_SoftwareOnly_NoNoise
            LDA AKY_AmplitudeControl,X
            STA AYR
            PLA
            STA AYD

            LDA AKY_ToneGeneratorControlL,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
            LDA AKY_ToneGeneratorControlH,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
            RTS

; =====================================
AKY_RRB_IS_SoftwareAndHardware
; 7  6  5  4  3  2  1  0
; e  e  e  e  n  r  t  t
; r = retrig?
; n = noise?
; e = envelope

            LSR @
            BCC AKY_RRB_IS_SAH_NoRetrig
            ROR AKY_EnvelopeShapeControlOld   ; C=1
AKY_RRB_IS_SAH_NoRetrig
            LSR @
            PHA
            BCC AKY_RRB_IS_SAH_NoNoise
            LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable

AKY_RRB_IS_SAH_NoNoise
            PLA
            STA AKY_EnvelopeShapeControl
            LDA AKY_ToneGeneratorControlL,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
            LDA AKY_ToneGeneratorControlH,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA #$10
            STA AYD
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl
            INY
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl+1
            INY
            RTS

; =====================================
AKY_RRB_NIS_NoSoftwareNoHardware_Loop
            LDA (AKY_RegisterBlock),Y
            PHA
            INY
            LDA (AKY_RegisterBlock),Y
            STA AKY_RegisterBlock+1
            PLA
            STA AKY_RegisterBlock
            LDY #$00
            LDA (AKY_RegisterBlock),Y
            INY

; =====================================
AKY_RRB_NonInitialState
; t = type.
;	00 = no software no hardware.
;	01 = software only.
;	10 = hardware only.
;	11 = software and hardware.

            LSR @
            BCS AKY_RRB_NIS_SoftwareOnlyOrSoftwareAndHardware
            LSR @
            BCC @+
            JMP AKY_RRB_NIS_HardwareOnly
@

AKY_RRB_NIS_NoSoftwareNoHardwareOrLoop
;    7  6  5  4  3  2  1  0
;    n  vv vv vv vv v  0  0
;                l
;    v = new volume? If 1, vv is the volume. If 0, the vv flags are used for the possible loop.
;    l = loop? Only relevant if v = 0.
;    n = noise? Always 0 in case of loop.

            STA AKY_TOKEN
            AND #$03
            CMP #$02                                             ;%10 loop
            BEQ AKY_RRB_NIS_NoSoftwareNoHardware_Loop

            LDA AKY_MixerControlEnableTone,X
            ORA AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_NoVolume
            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA AKY_TOKEN
            AND #$0F
            STA AYD

AKY_RRB_NIS_NoVolume
            LDA AKY_TOKEN
            AND #%00010000
            BNE @+
            RTS
@
            LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            RTS

; =====================================
AKY_RRB_NIS_SoftwareOnlyOrSoftwareAndHardware

            LSR @
            BCC @+
            JMP AKY_RRB_NIS_SoftwareAndHardware
@
AKY_RRB_NIS_SoftwareOnly
; 7        6   5  4  3  2  1  0
; mspnoise lsp v  v  v  v  0  1
; v = volume.
; mspnoise = new Most Significant byte of Period AND/OR noise.
; lsp = new Most Significant byte of Period?

            STA AKY_TOKEN
            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA AKY_TOKEN
            AND #$0F
            STA AYD

            LDA AKY_TOKEN
            AND #%00010000
            BEQ AKY_RRB_NIS_SoftwareOnly_NoLSP

            LDA AKY_ToneGeneratorControlL,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY

AKY_RRB_NIS_SoftwareOnly_NoLSP
            LDA AKY_TOKEN
            AND #%00100000
            BNE @+
            RTS
@
; 76543210
; in  pppp
; i = isNoise? If yes, open the noise channel.
; n = new Noise? If !isNoise, 0.
; p = MSB of period (encoded regardless its usefulness)
            LDA AKY_ToneGeneratorControlH,X
            STA AYR

            LDA (AKY_RegisterBlock),Y
            INY
            STA AYD                        ; AND #$0F

            ASL @
            BCS @+
            RTS
@           ASL @                          ; C
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            BCS @+
            RTS
@           LDA (AKY_RegisterBlock),Y
            STA AKY_NoiseGeneratorControl
            INY
            RTS

; =====================================
AKY_RRB_NIS_HardwareOnly
; 7   6   5  4  3  2  1  0
; lsp msp nr e  e  e  1  0
; e = envelope.
; msp = new Most Significant byte of Period?
; lsp = new Most Significant byte of Period?
; nr = new noise or retrig?

            ASL @
            STA AKY_EnvelopeShapeControl             ; AND #$0F    b0=0?
            PHA
            LDA AKY_MixerControlEnableTone,X
            ORA AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA #$10
            STA AYD

            PLA
            ASL @
            ASL @
            STA AKY_TOKEN
            BCC AKY_RRB_NIS_HardwareOnly_NoLSB
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl
            INY

AKY_RRB_NIS_HardwareOnly_NoLSB
            ASL AKY_TOKEN
            BCC AKY_RRB_NIS_HardwareOnly_NoMSB

            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl+1
            INY
AKY_RRB_NIS_HardwareOnly_NoMSB

            ASL AKY_TOKEN
            BCS AKY_RRB_NIS_Hardware_Shared_NoiseOrRetrig_AndStop
            RTS

; =====================================
AKY_RRB_NIS_SoftwareAndHardware
; 7  6  5    4    3    2    1  0
; rn ne mssp lssp mshp lshp 1  1
; lshp = new Less Significant byte of Hardware Period?
; mshp = new Most Significant byte of Hardware Period?
; lssp = new Less Significant byte of Software Period?
; mssp = new Most Significant byte of Software Period?
; ne = new envelope?
; rn = retrig or noise/new noise?

            STA AKY_TOKEN
            LDA AKY_AmplitudeControl,X
            STA AYR
            LDA #$10
            STA AYD
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_SAHH_AfterLSBH
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl
            INY
AKY_RRB_NIS_SAHH_AfterLSBH
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_SAHH_AfterMSBH
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopePeriodControl+1
            INY
AKY_RRB_NIS_SAHH_AfterMSBH
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_SAHH_AfterLSBS
            LDA AKY_ToneGeneratorControlL,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
AKY_RRB_NIS_SAHH_AfterLSBS
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_SAHH_AfterMSBS
            LDA AKY_ToneGeneratorControlH,X
            STA AYR
            LDA (AKY_RegisterBlock),Y
            STA AYD
            INY
AKY_RRB_NIS_SAHH_AfterMSBS
            LSR AKY_TOKEN
            BCC AKY_RRB_NIS_SAHH_AfterEnvelope
            LDA (AKY_RegisterBlock),Y
            STA AKY_EnvelopeShapeControl
            INY
AKY_RRB_NIS_SAHH_AfterEnvelope
            LSR AKY_TOKEN
            BCS @+
            RTS
@

AKY_RRB_NIS_Hardware_Shared_NoiseOrRetrig_AndStop
;76543210
;ooooonir
;r = retrig?
;i = isNoise? If yes, open the noise channel.
;n = new Noise? If !isNoise, 0.
;o = noise (>0).
            LDA (AKY_RegisterBlock),Y
            INY
            LSR @
            BCC AKY_RRB_NIS_S_NOR_NoRetrig
            ROR AKY_EnvelopeShapeControlOld        ; C=1
AKY_RRB_NIS_S_NOR_NoRetrig
            LSR @
            BCS @+
            RTS
@           PHA
            LDA AKY_MixerControlEnableNoise,X
            AND AKY_MixerControlEnable
            STA AKY_MixerControlEnable
            PLA
            LSR @
            BCS @+
            RTS
@           STA AKY_NoiseGeneratorControl
            RTS

; =====================================
AKY_NoiseGeneratorControl   .byte $00
AKY_EnvelopePeriodControl   .byte $00,$00
AKY_EnvelopeShapeControl    .byte $00
AKY_EnvelopeShapeControlOld .byte $00
AKY_MixerControlEnable      .byte $00
AKY_ToneGeneratorControlL   .byte 0,2,4
AKY_ToneGeneratorControlH   .byte 1,3,5
AKY_AmplitudeControl        .byte 8,9,10
AKY_MixerControlEnableTone  .byte $01,$02,$04
AKY_MixerControlEnableNoise .byte %11110111,%11101111,%11011111

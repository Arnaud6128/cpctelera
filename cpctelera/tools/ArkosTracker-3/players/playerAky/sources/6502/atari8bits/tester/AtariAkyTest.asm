;       AKY music player - V1.0
;       Atari XL/XE; Card: SONari
;       By Krzysztof Dudek (xxl)
;       March 2021


AUDCTL   EQU   $D208
AUDC1    EQU   $D201
AUDF1    EQU   $D200
AUDC2    EQU   $D203
AUDF2    EQU   $D202
IRQEN    EQU   $D20E
IRQENS   EQU   $0010
VTIMR2   EQU   $0212
STIMER   EQU   $D209
COLBAK   EQU   $D01A


            RUN $2000

            ORG $2000

            LDY #.lo(Main_Subsong0_Linker)
            LDX #.hi(Main_Subsong0_Linker)
            JSR AKY_Init

            SEI
            LDA #.lo(MyIRQ)
            STA VTIMR2
            LDA #.hi(MyIRQ)
            STA VTIMR2+1
            LDA #%00010001
            STA AUDCTL
            LDA #.lo($137) ; $137 = 50Hz; $09b = 100Hz
            STA AUDF1
            LDA #.hi($137)
            STA AUDF2
            LDA #$00
            STA AUDC1
            STA AUDC2
            STA STIMER
            LDA IRQENS
            ORA #$02
            STA IRQENS
            STA IRQEN
            CLI
            JMP *

MyIRQ
            TXA
            PHA
            TYA
            PHA
            LDA #$0F
            STA COLBAK
            JSR AKY_Play
            LDA #$00
            STA COLBAK
            PLA
            TAY
            PLA
            TAX
            PLA
            RTI

            ICL '../PlayerAky.asm'
            ICL '../resources/KellyOn.asm'


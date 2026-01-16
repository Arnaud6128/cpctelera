        ;Launcher code using a CPC and the USIfAC serial hardware.

        ;What hardware?
        MACHINE_CPC = 1
        MACHINE_MSX = 0
        
        ;What kind of PSG?
        PSG_CPC = 1
        ;PSG_CPC_PLAYCITY = 1

        ;What interface for serial?
        INTERFACE_ALBIREO = 1
        ;INTERFACE_USIFAC = 1
        
        include "../Serial.asm"
        ;Includes all the necessary files, but the configuration must be set before.
        ;Check the testers!

        MACHINE_COUNT = 0
        INTERFACE_COUNT = 0
        PSG_KIND_COUNT = 0
        
        ;----- Amstrad CPC specific
        IFDEF MACHINE_CPC
        MACHINE_COUNT = MACHINE_COUNT + 1
Buffer  equ #c000               ;About 15 bytes per PSG.
        org #1000
                
        di
        ld hl,#c9fb
        ld (#38),hl
        ld sp,$
        ENDIF
        ;-----------------------------------
        
        
        include "SerialBase.asm"
                
        ;What Serial interface to use?
        IFDEF INTERFACE_ALBIREO
                include "SerialAlbireo.asm"
        ENDIF
        IFDEF INTERFACE_USIFAC
                include "SerialUsifac.asm"
        ENDIF
        IFDEF INTERFACE_BOOSTER
                include "SerialBooster.asm"
        ENDIF
        
        ;What hardware for the PSG?
        IFDEF PSG_CPC
                include "PsgCpc.asm"
        ENDIF
        IFDEF PSG_CPC_PLAYCITY
                include "PsgCpc_PlayCity.asm"
        ENDIF
        
        ;One instance of interface/psg kind/machine should have been set.
        if MACHINE_COUNT != 1
                fail "One (and only one) machine kind must be declared!"
        ENDIF
        if INTERFACE_COUNT != 1
                fail "One (and only one) interface must be declared!"
        ENDIF
        if PSG_KIND_COUNT != 1
                fail "One (and only one) PSG kind must be declared!"
        ENDIF

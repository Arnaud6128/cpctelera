        ;Access to the PSG for the Amstrad CPC.
        
        PSG_KIND_COUNT = PSG_KIND_COUNT + 1
        
;Selects a PSG. Nothing is done in this implementation, except checking the PSG index.
;IN:    A = PSG index (should be 0).
;MOD:   A is not modified.
SelectPsg:
        ;Only PSG 0 is allowed with this implementation!
        or a
        jp nz,OnWrongPsgError
        ret

;Sends a PSG register.
;IN:    H = register
;       L = value
;       D = PSG number (not useful for this implementation).
;MOD:   BC.        
SendPsgRegister:
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
        
InitializeSoundHardware:
        ;Nothing to do.
        ret
        
;Stops all the sounds.
;MOD:   HL, DE, BC preserved.
StopSounds:
        ;The normal code can be used.
        jp StopSoundsGeneric
        
;Sets the frequency of a PSG. May not be used according to the hardware.
;IN:    IX = buffer of 4 bytes with the period, little-endian (1000000 for a CPC for example).
;       A = PSG index (>=0).
;MOD:   Must preserve HL.
InitializePsgWithFrequency:
        ;Nothing to do on a bare CPC.
        ret
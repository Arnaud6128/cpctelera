        ;Access to the PSG for the Amstrad CPC, using the PlayCity hardware.

        PSG_KIND_COUNT = PSG_KIND_COUNT + 1

PLAYCITY_SELECTWRITE_PORT_LSB_RIGHT equ #84        ;The LSB of the PlayCity SELECT/WRITE port, for the right PSG.
PLAYCITY_SELECTWRITE_PORT_LSB_LEFT equ #88         ;The LSB of the PlayCity SELECT/WRITE port, for the left PSG.
PLAYCITY_WRITE_PORT_MSB equ #f8                    ;The MSB of the PlayCity WRITE port.
PLAYCITY_SELECT_PORT_MSB equ #f9                   ;The MSB of the PlayCity SELECT port.


InitializeSoundHardware:
        ld de,FreqAtariLittleEndian
        call FindFrequencyAndSetYMZ
        ret

FreqAtariLittleEndian: db #80, #84, #1e, #0
        
;Sets the YMZ frequency according to the one given. If not found, nothing is done (Atari ST is set by default, which is good, as it is the only way to select it).
;In all cases, the PlayCity is reset.
;IN:    DE = Points on the 32 bits little-endian PSG frequency that we want to set to the PlayCity.
;MOD:   DE is preserved.
FindFrequencyAndSetYMZ:
        ;Resets the PlayCity (= sets the frequencies to 2Mhz (Atari ST)).
        ld bc,PLAYCITY_WRITE_PORT_MSB * 256 + #ff
        out (c),c

        ld a,PSGFrequenciesToYMZFlag_Count
        ex af,af'

        ;IX points on the frequency of the song.
        ld ixl,e
        ld ixh,d

        ;IY points on the frequency look-up table.
        ld iy,PSGFrequenciesToYMZFlag
FindFrequencyAndSetYMZ_Loop:
        ld a,(ix + 0)
        cp (iy + 0)
        jr nz,FindFrequencyAndSetYMZ_Next
        ld a,(ix + 1)
        cp (iy + 1)
        jr nz,FindFrequencyAndSetYMZ_Next
        ld a,(ix + 2)
        cp (iy + 2)
        jr nz,FindFrequencyAndSetYMZ_Next
        ld a,(ix + 3)
        cp (iy + 3)
        jr nz,FindFrequencyAndSetYMZ_Next
        ;Match!
        ld a,(iy + 4)           ;Gets the frequency index.
        ld bc,PLAYCITY_WRITE_PORT_MSB * 256 + #80   ;#f880
        ld h,#7f
        out (c),h                                       ;Clock generator.
        out (c),a                                       ;Sends frequency index.

        ret

FindFrequencyAndSetYMZ_Next
        ex af,af'
        dec a
        ret z                                           ;No match! Returns (default to Atari ST).

        ex af,af'

        ;Next frequency!
        dknr3:  ld bc,5
        add iy,bc
        jr FindFrequencyAndSetYMZ_Loop


;The frequencies (hz) to YMZ flag (index).
PSGFrequenciesToYMZFlag:
        db #40, #42, #f, 0,             1               ;1000000        CPC
        db #60, #e3, #16, #0,           2               ;1500000
        db #70, #7b, #19, #0,           3               ;1670000
        db #f0, #b3, #1a, #0,           4               ;1750000        ZX
        db #40, #77, #1b, #0,           5               ;1800000        ~MSX
        db #70, #ec, #1b, #0,           6               ;1830000
        db #a0, #61, #1c, #0,           7               ;1860000
        db #c0, #af, #1c, #0,           8               ;1880000
        db #d0, #d6, #1c, #0,           9               ;1890000
        db #e0, #fd, #1c, #0,           10              ;1900000
        db #f0, #24, #1d, #0,           11              ;1910000
        db #00, #4c, #1d, #0,           12              ;1920000
        db #00, #4c, #1d, #0,           13              ;1920000        ;No change
        db #10, #73, #1d, #0,           14              ;1930000
        db #10, #73, #1d, #0,           15              ;1930000        ;No change
        db #70, #5d, #1e, #0,           0               ;1990000        ;~ST
PSGFrequenciesToYMZFlag_End:

PSGFrequenciesToYMZFlag_Count equ (PSGFrequenciesToYMZFlag_End - PSGFrequenciesToYMZFlag) / 5

;Selects a PSG. Nothing is done in this implementation, except checking the PSG index.
;IN:    A = PSG index (>=0, <=2).
;MOD:   A is not modified.
SelectPsg:
        ;Only PSG 0, 1, 2 are allowed with this implementation!
        cp 3
        jp nc,OnWrongPsgError
        ret

;Sends a PSG register.      
;IN:    H = register
;       L = value
;       D = PSG number (0-2).
;MOD:   BC.
SendPsgRegister:
        push af
        ;On which PSG to send the data?
        ld a,d
        or a
        jr z,SendPsgRegister_PlayCityLeft
        dec a            ;We consider the PSG 1 as the CPC PSG.
        jr z,SendPsgRegister_PlayCityOldPsg
        dec a
        jr z,SendPsgRegister_PlayCityRight
        jp OnWrongPsgError    
        
        ;PSG sending to the PlayCity Left.
SendPsgRegister_PlayCityLeft:
        ld bc,PLAYCITY_SELECT_PORT_MSB * 256 + PLAYCITY_SELECTWRITE_PORT_LSB_LEFT
SendPsgRegister_PlayCity:
        out (c),h               ;#f984/88 to select a register.
        dec b                   ;#f884/88 to select a value
        out (c),l
SendPsgRegister_End:  
        pop af
        ret

SendPsgRegister_PlayCityRight:
        ld bc,PLAYCITY_SELECT_PORT_MSB * 256 + PLAYCITY_SELECTWRITE_PORT_LSB_RIGHT
        jr SendPsgRegister_PlayCity
        
        ;Normal sending to the PlayCity PSG.
SendPsgRegister_PlayCityOldPsg:
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
        jr SendPsgRegister_End

;Stops all the sounds.
;MOD:   HL, DE, BC preserved.
StopSounds:
        ld d,0
        call StopSoundsGeneric
        ld d,1
        call StopSoundsGeneric
        ld d,2
        call StopSoundsGeneric
        ret

;Sets the frequency of a PSG. May not be used according to the hardware.
;IN:    IX = buffer of 4 bytes with the period, little-endian (1000000 for a CPC for example).
;       A = PSG index (>=0).
;MOD:   Must preserve HL.
InitializePsgWithFrequency:
        ;On a PlayCity, PSG 2 is the "cpc" normal one, we can't set its frequency.
        ;PSG 1 and 3 have the same frequency. We consider only reading the PSG 1.
        or a    ;Only PSG 1 (=index 0) is used.
        ret nz

        push hl
        
        ;Sets the frequency for the PlayCity.
        ld e,ixl
        ld d,ixh
        call FindFrequencyAndSetYMZ

        pop hl
        ret
;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2022 Einar Saukas (https://www.ime.usp.br/~einar/)
;;  Copyright (C) 2025 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_compression

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_zx1_decrunch
;;
;; ZX1 decoder by Einar Saukas & introspec "Turbo" version (128 bytes, 20% faster).
;; ZX1 is a simpler but faster version of ZX0 that sacrifices about 1.5% compression to run about 15% faster and
;; successor of widely popular compressor ZX7.
;;
;; C Definition:
;;    void <cpct_zx1_decrunch> (const u8* *source*, u8* *destination*) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;    (2B  HL) source      - Pointer of the source (compressed) array
;;    (2B  DE) destination - Pointer of the destination (decompressed) array
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_ZX1_decrunch_asm
;;
;; Parameter Restrictions:
;;    * *source* should be a 16-bit pointer to the latest byte of the array where compressed
;; data is held. ZX1 algorithm will read the array from this byte backwards till its start.
;; No runtime checks are performed: if this value is incorrect, undefined behaviour will follow.
;; Typically, garbage data of undefined size will be produced, potentially overwriting undesired
;; memory parts.
;;    * *destination* should be a 16-bit pointer to the latest byte of the array where decompressed
;; data will be written. It could point anywhere in memory. Data will be written from that
;; byte backwards until all compressed data has been decompressed. No runtime checks
;; are performed. By specially careful to ensure that this pointer is correct; otherwise
;; undesired parts of memory could be overwritten, causing undefined behaviour. 
;;
;; Known limitations:
;;     * This function does not do any kind of checking over pointers or data passed. If any of the
;; pointers is badly calculated or incorrect, or compressed data is corrupted, undefined behaviour 
;; will follow.
;;
;; Details:
;;      This function decompresses an array of data previously compressed using ZX1 algorithm
;; by Einar Saukas. In order to perform this decompression, two in-memory arrays are required:
;; a *source* array containing compressed data and a *destination* array
;; where decompressed data will be written. *source* array is only read and never changed, so
;; it might be placed either on RAM or on ROM memory. *destination* array is required to be 
;; in RAM, as decompressed data will be written there.
;;
;; Destroyed Register values: 
;;      AF,  BC,  DE,  HL
;;
;; Required memory:
;;      C-bindings - 0 bytes 
;;    ASM-bindings - 0 bytes 
;;
;; Credits:
;;    * <Original code at https://github.com/einar-saukas/ZX1> 
;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dzx1_turbo:
        ld      bc, #0xffff               ; preserve default offset 1
        ld      (dzx1t_last_offset+1), bc
        inc     bc
        ld      a, #0x80
        jr      dzx1t_literals
dzx1t_new_offset:
        dec     b
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      c                       ; single byte offset?
        jr      nc, dzx1t_msb_skip
        ld      b, (hl)                 ; obtain offset MSB
        inc     hl
        rr      b                       ; replace last LSB bit with last MSB bit
        inc     b
        ret     z                       ; check end marker
        rl      c
dzx1t_msb_skip:
        ld      (dzx1t_last_offset+1), bc ; preserve new offset
        ld      bc, #1                  ; obtain length
        add     a, a
        call    c, dzx1t_elias
        inc     bc
dzx1t_copy:
        push    hl                      ; preserve source
dzx1t_last_offset:
        ld      hl, #0                  ; restore offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx1t_new_offset
dzx1t_literals:
        inc     c                       ; obtain length
        add     a, a
        call    c, dzx1t_elias
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx1t_new_offset
        inc     c                       ; obtain length
        add     a, a
        call    c, dzx1t_elias
        jp      dzx1t_copy
dzx1t_elias_loop:
        add     a, a
        rl      c
        add     a, a
        ret     nc
dzx1t_elias:
        jp      nz, dzx1t_elias_loop    ; inverted interlaced Elias gamma coding
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
        add     a, a
        rl      c
        add     a, a
        ret     nc
dzx1t_elias_reload:
        add     a, a
        rl      c
        rl      b
        add     a, a
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        ret     nc
        add     a, a
        rl      c
        rl      b
        add     a, a
        jr      c, dzx1t_elias_reload
        ret

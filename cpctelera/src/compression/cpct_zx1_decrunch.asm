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
;;    void <cpct_zx1_decrunch> (u8* *destination*, const u8* *source*) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;    (2B  DE) destination - Pointer of the destination (decompressed) array
;;    (2B  HL) source      - Pointer of the source (compressed) array
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_ZX1_decrunch_asm
;;
;; Parameter Restrictions:
;;    * *source* should be a 16-bit pointer to the latest byte of the array where compressed
;; data is held. ZX1 algorithm will read the array from this byte.
;; No runtime checks are performed: if this value is incorrect, undefined behaviour will follow.
;; Typically, garbage data of undefined size will be produced, potentially overwriting undesired
;; memory parts.
;;    * *destination* should be a 16-bit pointer to the latest byte of the array where decompressed
;; data will be written. It could point anywhere in memory. Data will be written from that
;; byte until all compressed data has been decompressed. No runtime checks
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
;;      C-bindings - 121 bytes 
;;    ASM-bindings - 120 bytes 
;;
;; Credits:
;;    * <Original code at https://github.com/einar-saukas/ZX1> 
;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dzx1_turbo:
        ld      bc, #0xffff               ;; [3]  Initialize default offset (-1)
        ld      (dzx1t_last_offset+1), bc ;; [5]  Store as last offset
        inc     bc                        ;; [2]  BC = 0
        ld      a, #0x80                  ;; [2]  Initialize bit mask
        jr      dzx1t_literals            ;; [3]  Start with literal copy

dzx1t_new_offset:
        dec     b                         ;; [1]  Prepare for 1-byte offset
        ld      c, (hl)                   ;; [2]  Load LSB of offset
        inc     hl                        ;; [2]  Advance source pointer
        rr      c                         ;; [2]  Check if 1-byte offset (bit 7)
        jr      nc, dzx1t_msb_skip        ;; [3]  Skip MSB if not needed
        ld      b, (hl)                   ;; [2]  Load MSB of offset
        inc     hl                        ;; [2]  Advance source pointer
        rr      b                         ;; [2]  Rotate MSB into place
        inc     b                         ;; [1]  Adjust offset (avoid zero)
        ret     z                         ;; [3]  End marker found → return
        rl      c                         ;; [2]  Restore LSB bit from carry
dzx1t_msb_skip:
        ld      (dzx1t_last_offset+1), bc ;; [5]  Save new offset
        ld      bc, #1                    ;; [3]  Initialize length = 1
        add     a, a                      ;; [1]  Shift bit mask left
        call    c, dzx1t_elias            ;; [5]  Decode Elias gamma length if carry
        inc     bc                        ;; [2]  Final length = decoded + 1
        ;; Fall through to copy from offset

dzx1t_copy:
        push    hl                        ;; [3]  Save source pointer
dzx1t_last_offset:
        ld      hl, #0                    ;; [3]  Load last offset (self-modified at runtime)
        add     hl, de                    ;; [3]  Compute source = dest - offset
        ldir                              ;; [6*N] Copy BC bytes from (HL) to (DE)
        pop     hl                        ;; [3]  Restore source pointer
        add     a, a                      ;; [1]  Shift bit mask left
        jr      c, dzx1t_new_offset       ;; [3]  If carry, read new offset

dzx1t_literals:
        inc     c                         ;; [1]  Initialize length = 1
        add     a, a                      ;; [1]  Shift bit mask left
        call    c, dzx1t_elias            ;; [5]  Decode Elias gamma length if carry
        ldir                              ;; [6*N] Copy literals
        add     a, a                      ;; [1]  Shift bit mask left
        jr      c, dzx1t_new_offset       ;; [3]  If carry, read new offset
        inc     c                         ;; [1]  Initialize length = 1
        add     a, a                      ;; [1]  Shift bit mask left
        call    c, dzx1t_elias            ;; [5]  Decode Elias gamma length if carry
        jp      dzx1t_copy                ;; [3]  Jump to copy from last offset

;;----------------------------------------------------------------
;; dzx1t_elias: Decodes inverted interlaced Elias gamma code
;;----------------------------------------------------------------
dzx1t_elias_loop:
        add     a, a                      ;; [1]  Shift bit mask left
        rl      c                         ;; [2]  Insert bit into length (C)
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry (end of code)
dzx1t_elias:
        jp      nz, dzx1t_elias_loop      ;; [3]  Jump if not end of byte
        ld      a, (hl)                   ;; [2]  Load next byte from source
        inc     hl                        ;; [2]  Advance source pointer
        rla                               ;; [1]  Rotate first bit into carry
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry
dzx1t_elias_reload:
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        rl      b                         ;; [2]  Insert bit into B (for multi-byte)
        add     a, a                      ;; [1]  Shift again
        ld      a, (hl)                   ;; [2]  Load next byte from source
        inc     hl                        ;; [2]  Advance source pointer
        rla                               ;; [1]  Rotate first bit into carry
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        rl      b                         ;; [2]  Insert bit into B
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        rl      b                         ;; [2]  Insert bit into B
        add     a, a                      ;; [1]  Shift again
        ret     nc                        ;; [3]  Return if no carry
        add     a, a                      ;; [1]  Shift bit mask
        rl      c                         ;; [2]  Insert bit into C
        rl      b                         ;; [2]  Insert bit into B
        add     a, a                      ;; [1]  Shift again
        jr      c, dzx1t_elias_reload     ;; [3]  Continue if carry set
        ret                               ;; [3]  Return
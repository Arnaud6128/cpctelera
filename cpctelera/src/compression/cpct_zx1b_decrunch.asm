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
;; Function: cpct_zx1b_decrunch
;;
;; ZX1 decoder by Einar Saukas & introspec "Turbo" version backwards (128 bytes, 20% faster).
;; ZX1 is a simpler but faster version of ZX0 that sacrifices about 1.5% compression to run about 15% faster and
;; successor of widely popular compressor ZX7.
;;
;; C Definition:
;;    void <cpct_zx1b_decrunch> (u8* *dest_end*, const u8* *source_end*) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;    (2B  DE) dest_end   - Ending (latest) byte of the destination (decompressed) array
;;    (2B  HL) source_end - Ending (latest) byte of the source (compressed) array
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_zx1b_decrunch
;;
;; Parameter Restrictions:
;;    * *dest_end* should be a 16-bit pointer to the latest byte of the array where decompressed
;; data will be written. It could point anywhere in memory. Data will be written from that
;; byte backwards until all compressed data has been decompressed. No runtime checks
;; are performed. By specially careful to ensure that this pointer is correct; otherwise
;; undesired parts of memory could be overwritten, causing undefined behaviour. 
;;    * *source_end* should be a 16-bit pointer to the latest byte of the array where compressed
;; data is held. ZX1B algorithm will read the array from this byte backwards till its start.
;; No runtime checks are performed: if this value is incorrect, undefined behaviour will follow.
;; Typically, garbage data of undefined size will be produced, potentially overwriting undesired
;; memory parts.
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

dzx1_turbo_back:
        ld      bc, #1                  ; [3] Load BC with default offset value 1
        ld      (dzx1tb_last_offset+1), bc ; [5] Store as initial last offset (self-modified later)
        dec     c                       ; [1] Decrement C so BC becomes 0 (will be incremented before use)
        ld      a, #0x80                ; [2] Initialize bit mask to 10000000b (MSB set)
        jr      dzx1tb_literals         ; [3] Jump to handle literal bytes first

dzx1tb_new_offset:
        ld      c, (hl)                 ; [2] Load LSB of back-reference offset from source
        dec     hl                      ; [2] Move source pointer backward by 1
        srl     c                       ; [2] Shift right C; carry = original bit 0 (1-byte flag)
        jr      nc, dzx1tb_msb_skip     ; [3] If carry clear, offset is 1 byte → skip MSB
        ld      b, (hl)                 ; [2] Load MSB of offset from source
        dec     hl                      ; [2] Move source pointer backward by 1
        srl     b                       ; [2] Shift right B; carry = bit 7 of MSB
        ret     z                       ; [3] If both bytes zero, end marker → return
        dec     b                       ; [1] Decrement B to adjust offset (avoid zero)
        rl      c                       ; [2] Rotate carry into bit 7 of C to restore LSB

dzx1tb_msb_skip:
        inc     c                       ; [1] Ensure offset is at least 1
        ld      (dzx1tb_last_offset+1), bc ; [5] Save new offset for future use
        ld      bc, #1                  ; [3] Initialize length counter to 1
        add     a, a                    ; [1] Shift bit mask left to get next control bit
        call    c, dzx1tb_elias         ; [5] If carry set, decode Elias gamma length
        inc     bc                      ; [2] Increment length (final length = decoded + 1)

dzx1tb_copy:
        push    hl                      ; [3] Save current source pointer on stack
dzx1tb_last_offset:
        ld      hl, #0                  ; [3] Load last offset (will be patched at runtime)
        add     hl, de                  ; [3] Compute source address = dest - offset
        lddr                            ; [6*N] Copy BC bytes backward from (HL) to (DE)
        pop     hl                      ; [3] Restore source pointer from stack
        add     a, a                    ; [1] Shift bit mask left to get next control bit
        jr      c, dzx1tb_new_offset    ; [3] If carry set, next is a new offset

dzx1tb_literals:
        inc     c                       ; [1] Initialize literal length to 1
        add     a, a                    ; [1] Shift bit mask left
        call    c, dzx1tb_elias         ; [5] If carry set, decode Elias gamma length
        lddr                            ; [6*N] Copy literals backward from (HL) to (DE)
        add     a, a                    ; [1] Shift bit mask left
        jr      c, dzx1tb_new_offset    ; [3] If carry set, next is a new offset
        inc     c                       ; [1] Initialize literal length to 1
        add     a, a                    ; [1] Shift bit mask left
        call    c, dzx1tb_elias         ; [5] If carry set, decode Elias gamma length
        jp      dzx1tb_copy             ; [3] Jump to copy from last offset

;----------------------------------------------------------------
; dzx1tb_elias: Decodes inverted interlaced Elias gamma code
;----------------------------------------------------------------
dzx1tb_elias_loop:
        add     a, a                    ; [1] Shift bit mask left to get next bit
        rl      c                       ; [2] Rotate bit into length register C
        add     a, a                    ; [1] Shift again to get next control bit
        ret     nc                      ; [3] If no carry, end of Elias code → return

dzx1tb_elias:
        jp      nz, dzx1tb_elias_loop   ; [3] If not end of current byte, continue decoding loop
        ld      a, (hl)                 ; [2] Load next byte from compressed data
        dec     hl                      ; [2] Move source pointer backward by 1
        rla                             ; [1] Rotate left A; carry = bit 7 of the new byte
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into length register C
        add     a, a                    ; [1] Shift again
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into C
        add     a, a                    ; [1] Shift again
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into C
        add     a, a                    ; [1] Shift again
        ret     nc                      ; [3] If no carry, end of code → return

dzx1tb_elias_reload:
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into length register C
        rl      b                       ; [2] Insert bit into high byte B (for multi-byte lengths)
        add     a, a                    ; [1] Shift again
        ld      a, (hl)                 ; [2] Load next byte from compressed data
        dec     hl                      ; [2] Move source pointer backward by 1
        rla                             ; [1] Rotate left A; carry = bit 7 of the new byte
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into C
        rl      b                       ; [2] Insert bit into B
        add     a, a                    ; [1] Shift again
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into C
        rl      b                       ; [2] Insert bit into B
        add     a, a                    ; [1] Shift again
        ret     nc                      ; [3] If no carry, end of code → return
        add     a, a                    ; [1] Shift bit mask left
        rl      c                       ; [2] Insert bit into C
        rl      b                       ; [2] Insert bit into B
        add     a, a                    ; [1] Shift again
        jr      c, dzx1tb_elias_reload  ; [3] If carry set, reload another byte and continue
        ret                             ; [3] Done return
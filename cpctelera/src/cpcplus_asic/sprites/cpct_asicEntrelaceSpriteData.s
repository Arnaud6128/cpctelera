;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_asic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_asicEntrelaceSpriteData
;;
;;   Interlaces two 16x16 hardware sprites into one 256-byte buffer
;;
;; C Definition:
;;    void cpct_asicEntrelaceSpriteData(<u8>* *sprite_array_dst*, <u8>* *sprite_array_src*);
;;
;; Assembly call:
;;   > call cpct_asicEntrelaceSpriteData_asm
;;
;; Input Parameters:
;;   (2B HL) sprite_array_dst - Pointer to destination 256-byte sprite array
;;   (2B DE) sprite_array_src - Pointer to source 256-byte sprite array
;;
;; Parameter Restrictions:
;;   * *sprite_array_dst* must point to an array of at least 256 bytes (RAM or ASIC area 0x4000..0x4FFF).
;;   * *sprite_array_src* must point to an array of at least 256 bytes containing the second sprite frame.
;;
;; Requirements and limitations:
;;  * If pointers target the ASIC sprite RAM (0x4000..0x4FFF), *cpct_asicUnlock* and 
;;    *cpct_asicPageConnect* must be called beforehand.
;;  * The ASIC registers / RAM are paged from 0x4000 to 0x7FFF *beware* the code located 
;;    in this area will be hidden.
;;  * ASIC page can be disconnected with *cpct_asicPageDisconnect* function to recover code.
;;
;; Details:
;;   The CPC+ ASIC only renders the lower nibble (bits 0..3) of each byte in sprite
;;   memory and ignores the upper nibble (bits 4..7).
;;
;;   This function merges two 16x16 sprites: pixels from *sprite_array_dst* are
;;   preserved in the lower nibble (bits 0..3), while pixels from *sprite_array_src*
;;   are shifted into the upper nibble (bits 4..7) of each byte in *sprite_array_dst*.
;;
;;   Once interlaced, the two frames can be toggled instantaneously in-place using
;;   *cpct_asicEntrelaceSpriteData*.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;     C-bindings - 20 bytes
;;   ASM-bindings - 20 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        | 6148          | 24592
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_asicEntrelaceSpriteData::
cpct_asicEntrelaceSpriteData_asm::
    ld   b, #0         ;; [ 2]  B = 256 iterations counter

entrelace_loop:
    ld   a, (de)       ;; [ 2]  A = source pixel byte
    rrca               ;; [ 1]  Rotate right 4 times to place lower nibble into upper nibble
    rrca               ;; [ 1]
    rrca               ;; [ 1]
    rrca               ;; [ 1]
    and  #0xF0         ;; [ 2]  Mask out lower nibble: A = (src & 0x0F) << 4
    ld   c, a          ;; [ 1]  C = source upper nibble

    ld   a, (hl)       ;; [ 2]  A = destination pixel byte
    and  #0x0F         ;; [ 2]  Mask out upper nibble: A = dst & 0x0F
    or   c             ;; [ 1]  Combine [Source : Destination]
    ld   (hl), a       ;; [ 2]  Write merged pixel back to destination

    inc  de            ;; [ 2]  Advance source pointer
    inc  hl            ;; [ 2]  Advance destination pointer
    djnz entrelace_loop ;; [4/3] 4 if branch taken (255x), 3 on final exit (1x)

    ret                ;; [ 3]  Return to caller
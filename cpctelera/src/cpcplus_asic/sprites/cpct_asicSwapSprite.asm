;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it intelligence or modify
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
;; Function: cpct_asicSwapSprite
;;
;;   Swaps low and high nibbles (4-bit pixels) of a 16x16 hardware sprite in ASIC memory
;;
;; C Definition:
;;    void cpct_asicSwapSprite(<u8> *hardware_sprite_id*) __z88dk_fastcall;
;;
;; Assembly call:
;;   > call cpct_asicSwapSprite_asm
;;
;; Input Parameters (1 Byte):
;;   (1B L) hardware_sprite_id - Hardware sprite identifier (0..15)
;;
;; Parameter Restrictions:
;;   * *hardware_sprite_id* hardware sprite identifier from 0 to 15
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Details:
;;   The CPC+ ASIC only renders the lower nibble (bits 0..3) of each byte in sprite
;;   memory, completely ignoring the upper nibble (bits 4..7). By rotating each byte
;;   by 4 bits directly in ASIC RAM (0x4000..0x4FFF), this function swaps the active
;;   and standby frames in-place without requiring any CPU RAM buffer or data copy.
;;
;; Destroyed Register values: 
;;    AF, HL
;;
;; Required memory:
;;     C-bindings - 18 bytes
;;   ASM-bindings - 18 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        | 3082          | 12328
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_asicSwapSprite::
cpct_asicSwapSprite_asm::

    ;; 1. Calculate base address in ASIC sprite RAM: 0x4000 + (hardware_sprite_id * 256)
    ld   a, l          ;; [1] A = sprite ID (0..15)
    and  #0x0F         ;; [2] Mask ID to ensure it is in range 0..15
    add  a, #0x40      ;; [2] A = 0x40 + id -> High byte of sprite address
    ld   h, a          ;; [1] H = 0x40..0x4F
    ld   l, #0x00      ;; [2] L = 0x00 -> HL points to sprite origin (0x4X00)

    ;; 2. In-place nibble swap loop over all 256 sprite bytes
swap_loop:
    ld   a, (hl)       ;; [2] Read current byte: A = [Sprite_B : Sprite_A]
    rrca               ;; [1] Rotate right 4 times to swap low and high nibbles
    rrca               ;; [1] |
    rrca               ;; [1] |
    rrca               ;; [1] A = [Sprite_A : Sprite_B]
    ld   (hl), a       ;; [2] Write back directly into ASIC RAM
    inc  l             ;; [1] Increment low byte of address pointer
    jr   nz, swap_loop ;; [3/2] Loop 256 times until L overflows to 0 (3 taken, 2 fall-through)

    ret                ;; [3] Return to caller
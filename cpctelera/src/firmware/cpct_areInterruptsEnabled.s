;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
.module cpct_firmware

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_areInterruptsEnabled
;;
;;    Returns whether the maskable interrupts of the CPU are enabled (EI) or
;; disabled (DI).
;;
;; C Definition:
;;    u8 <cpct_areInterruptsEnabled> (void)
;;
;; Assembly call:
;;    > call cpct_areInterruptsEnabled_asm
;;
;; Return value:
;;    A - 1 if the interrupts are enabled, 0 if they are disabled
;;
;; Details:
;;    Reads the interrupt flip-flop IFF2 of the Z80 with "ld a, i" (bit P/V of
;; the flags). It does not depend on the interrupt handler nor on the interrupt
;; mode: it only tells if the CPU accepts maskable interrupts (the state that
;; EI and DI set). Useful to save it before a code that disables the interrupts,
;; and to enable them again only if they were enabled before:
;; (start code)
;;    u8 ints = cpct_areInterruptsEnabled();
;;    ...                    // code that disables the interrupts
;;    if (ints)
;;       cpctm_enableInterrupts();
;; (end code)
;;
;; Destroyed Register values:
;;    AF
;;
;; Required memory:
;;    7 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs (us) | CPU Cycles
;; -------------------------------------
;; Any  |      15        |     60
;; -------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_areInterruptsEnabled::
cpct_areInterruptsEnabled_asm::
   ld    a, i                     ;; [3] P/V = IFF2 (1 = interrupts enabled)
   ld    a, #0                    ;; [2] A = 0 (does not change the flags)
   ret   po                       ;; [2/4] IFF2 = 0 (P/V = 0, parity odd): return 0
   inc   a                        ;; [1] A = 1
   ret                            ;; [3] Return

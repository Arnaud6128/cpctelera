;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Use of Claude.ai - Opus 5.5
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
;; Function: cpct_cartSetUpperRomBank
;;
;;   Selects the bank of the cartridge seen by the upper ROM (0xC000-0xFFFF)
;;
;; C Definition:
;;    void <cpct_cartSetUpperRomBank> (<u8> *bank*);
;;
;; Assembly call:
;;    > call cpct_cartSetUpperRomBank_asm
;;
;; Input Parameters (1 Byte):
;;  (1B A)  bank - Bank of the cartridge (0-31)
;;
;; Details:
;;  The upper ROM is selected with the port 0xDF00 (128 + bank). It only chooses the bank: the CPU reads
;; it when the upper ROM is enabled, with <cpct_enableUpperROM> (and the RAM is seen again after
;; <cpct_disableUpperROM>).
;;
;;  The same addresses are two different memories, one for reading and one for writing:
;; (start code)
;;                   | CPU reads             | CPU writes
;;    ---------------+-----------------------+---------------------------
;;    0xC000-0xFFFF  | the bank (ROM)        | the RAM under it (screen)
;; (end code)
;; With the upper ROM enabled, reading 0xC000-0xFFFF gives the bank and writing goes to the RAM, that is
;; the video memory: a bank of 16 KB (a picture of the screen, for example) can be copied on itself to the
;; screen, without any buffer:
;; (start code)
;;    cpct_cartSetUpperRomBank(bank);                    // choose the bank
;;    cpct_enableUpperROM();                             // reading 0xC000-0xFFFF gives the bank
;;    cpct_memcpy((void*)0xC000, (void*)0xC000, 0x4000); // reads the ROM, writes the RAM (the screen)
;;    cpct_disableUpperROM();                            // reading gives the RAM again
;; (end code)
;; The ROM must be enabled before the copy: without it the same call copies the RAM on itself and does nothing.
;; After <cpct_disableUpperROM> the RAM is seen again, with the data that was written.
;;
;; Known limitations:
;;  * The code that reads the bank (the copy) must not be in 0xC000-0xFFFF: the CPU would read the bank instead
;; of the instructions. The stack must not be there either while the ROM is enabled (it is below 0xC000 by default).
;;  * If an interrupt handler uses 0xC000-0xFFFF, disable the interrupts while the upper ROM is enabled.
;;
;; Destroyed Register values:
;;    AF, BC
;;
;; Required memory:
;;    10 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs(us) | CPU Cycles
;; -----------------------------------
;; Any  |      14       |     56
;; -----------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "../asic.s"

_cpct_cartSetUpperRomBank::
cpct_cartSetUpperRomBank_asm::
   and  #0x1F                    ;; [2] | A = 128 + bank
   or   #0x80                    ;; [2] |
   ld   b, #CART_ROM_PORT_HI     ;; [2] | Select the bank of the upper ROM
   ld   c, a                     ;; [1] |
   out  (c), c                   ;; [4] |
   ret                           ;; [3] Return
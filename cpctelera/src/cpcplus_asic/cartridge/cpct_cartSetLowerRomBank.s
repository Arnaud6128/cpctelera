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
.module cpct_asic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_cartSetLowerRomBank
;;
;;   Selects the bank of the cartridge seen by the lower ROM (0x0000-0x3FFF)
;;
;; C Definition:
;;    void <cpct_cartSetLowerRomBank> (<u8> *bank*);
;;
;; Assembly call:
;;    > call cpct_cartSetLowerRomBank_asm
;;
;; Input Parameters (1 Byte):
;;  (1B A)  bank - Bank of the cartridge (0-7: the lower ROM sees the first 8)
;;
;; Details:
;;  * The function DISABLES THE INTERRUPTS (di) and does not enable them again: the lower ROM is going to be read
;; and the interrupt vector (0x0038) is the one of the bank while the lower ROM is enabled, and a handler that
;; connects the ASIC page writes RMR2 too (the lower bank would change). The interrupts must stay disabled until
;; <cpct_disableLowerROM> is called: enable them again then (ei) if they were enabled, and if the vector is in the RAM.
;;  * <cpct_asicPageConnect> and <cpct_asicPageDisconnect> write RMR2 too, they set the lower bank to 0,
;; select the bank again after them.
;;  * Reading 0x0000-0x3FFF gives the bank only when the lower ROM is enabled with <cpct_enableLowerROM>, and
;; <cpct_disableLowerROM> gives the RAM back. The same addresses are two different memories: the CPU reads the
;; bank (ROM) and writes the RAM under it, so a file of a bank is read in a buffer of the RAM:
;; (start code)
;;    cpct_cartSetLowerRomBank(bank);                    // choose the bank (and disable the interrupts)
;;    cpct_enableLowerROM();                             // reading 0x0000-0x3FFF gives the bank
;;    cpct_memcpy(buffer, (void*)offset, size);          // reads the ROM, writes the buffer (in the RAM)
;;    cpct_disableLowerROM();                            // reading gives the RAM again
;;    cpctm_enableInterrupts();                          // if they were enabled
;; (end code)
;; Without <cpct_enableLowerROM> the same call reads the RAM, not the bank.
;;
;; Known limitations:
;;  * The ASIC must be unlocked (<cpct_asicUnlock>): RMR2 is a register of the CPC Plus.
;;  * The code that reads the bank must not be in 0x0000-0x3FFF (hidden by the ROM), neither in 0x4000-0x7FFF
;; if the ASIC page is connected.
;;
;; Destroyed Register values:
;;    AF, BC (and the interrupts are disabled)
;;
;; Required memory:
;;    11 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs(us) | CPU Cycles
;; -----------------------------------
;; Any  |      15       |     60
;; -----------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "../asic.s"

_cpct_cartSetLowerRomBank::
cpct_cartSetLowerRomBank_asm::
   di                            ;; [1] No interrupt while the bank is chosen and read (see Details)
   and  #0x07                    ;; [2] | A = 0xA0 + bank (RMR2)
   or   #CART_RMR2_LOWER         ;; [2] |
   ld   b, #CART_GA_PORT_HI      ;; [2] | Select the bank of the lower ROM
   ld   c, a                     ;; [1] |
   out  (c), c                   ;; [4] |
   ret                           ;; [3] Return
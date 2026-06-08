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

.module cpct_dsk

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_sectorRead
;;
;;    Reads an array of consecutive sectors from a given track and drive into memory
;;
;; C Definition:
;;    void cpct_sectorRead (void* dest, u8 track, u8 sector, u8 nbSectorsToRead, u8 driveNumber) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL) dest - Memory destination buffer pointer
;;   (1B D)  sector - Physical starting sector ID
;;   (1B E)  track - Target disk track index
;;   (1B C)  nbSectorsToRead - Total number of sectors to read
;;   (1B B)  driveNumber - Drive index selection (0 for Drive A, 1 for Drive B)
;;
;; Assembly call:
;;    > call cpct_sectorRead_asm
;;
;; Requirements and limitations:
;;   * The floppy drive motor state is automatically handled.
;;   * CPU Interrupts are disabled (DI) during execution to protect hardware timings.
;;
;; Details:
;;    Communicates directly with the uPD765A FDC ports (#0xfa7e and #0xfb7e).
;;    Extracts parameters from stack according to __z88dk_callee convention.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    C-binding wrapper: 8 bytes
;;    Complete routine & buffers: 467 bytes (Shared with write implementation)
;;
;; Time Measures: 
;; (start code)
;;    Case                            | microSecs (us)  | CPU Cycles 
;; ------------------------------------------------------------------
;;    C Binding Wrapper Setup         | 17              | 68         
;;    ASM Core Interface Setup        | 28              | 111        
;;    Fixed Internal Setup Overhead   | 34              | 136        
;;    FDC Protocol Software Overhead  | 200             | 800        
;;    CPU Data Transfer (per Sector)  | 9730            | 38920      
;;    Hardware Execution & Mechanical | Variable        | Variable   
;; ------------------------------------------------------------------
;;    Total Time (WITHOUT C Binding)  | 9992 + Variable | 39967 + Variable
;;    Total Time (WITH C Binding)     | 10009 + Variable| 40035 + Variable
;; ------------------------------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; External function
;;
.globl cpct_sector_read_asm

;;
;; C bindings for <cpct_sectorRead>
;;
;;   21 us, 6 bytes
;;
_cpct_sectorRead::
    pop  af          ;; [3] Pop return address from stack into AF
    pop  de          ;; [3] Pop sector (E) and track (D) parameters from stack
    pop  bc          ;; [3] Pop number of sectors (C) and drive number (B)
    push af          ;; [4] Push return address back onto stack (callee convention cleanup)
    
    call cpct_sector_read_asm      ;; [5] Call the internal reading routine
    ret                            ;; [3] Return to C caller
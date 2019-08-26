;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 Arnaud Bouche (@Arnaud)
;;  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; Function: 
;;   Connect Asic Page to get access to Asic registers and memory
;;    
;; C Definition:
;;    <void> cpct_asicPageConnect();
;;
;; Assembly call:
;;   > call cpct_asicPageConnect_asm
;;
;; Details:
;;  Get access to Asic page memory configuration from 0x4000 to 0x7FFF. All code in this area will be hidden and will no be readable. 
;;  To restore the memory page, use *cpct_asicPageDisconnect* function.
;;
;; (start code)
;; | Sprite | Address | Position X | Position Y | Zoom  |
;; +--------+---------+------------+------------+-------+
;; | 0      | &4000   | &6000-01   | &6002-03   | &6004 |
;; | 1      | &4100   | &6008-09   | &600A-0B   | &600C |
;; | 2      | &4200   | &6010-11   | &6012-13   | &6014 |
;; | 3      | &4300   | &6018-19   | &601A-1B   | &601C |
;; | 4      | &4400   | &6020-21   | &6022-23   | &6024 |
;; | 5      | &4500   | &6028-29   | &602A-2B   | &602C |
;; | 6      | &4600   | &6030-31   | &6032-33   | &6034 |
;; | 7      | &4700   | &6038-38   | &603A-3B   | &603C |
;; | 8      | &4800   | &6040-41   | &6042-43   | &6044 |
;; | 9      | &4900   | &6048-49   | &604A-4B   | &604C |
;; | 10     | &4A00   | &6050-51   | &6052-53   | &6054 |
;; | 11     | &4B00   | &6058-59   | &605A-5B   | &605C |
;; | 12     | &4C00   | &6060-61   | &6062-63   | &6064 |
;; | 13     | &4D00   | &6068-69   | &606A-6B   | &606C |
;; | 14     | &4E00   | &6070-71   | &6072-73   | &6074 |
;; | 15     | &4F00   | &6078-79   | &607A-7B   | &607C |
;; +----------------------------------------------------+
;;    Table 1 - Hardware Sprite Configuration address
;; (end)
;;
;; Destroyed Register values: 
;;    BC
;;
;; Required memory:
;;    6 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs(us) | CPU Cycles
;; -----------------------------------
;; Any  |      10       |     40
;; -----------------------------------
;; (end code)
;;
;; Credits :
;;  Memory mapping from http://quasar.cpcscene.net/doku.php?id=assem:asic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_asicPageConnect::
cpct_asicPageConnect_asm::
   ld  bc, #0x7FB8   ;; [3] Connect I/O ASIC
   out (c), c        ;; [4] | 
   ret               ;; [3] Return
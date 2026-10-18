;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

;; Define some constants for geometry functions (screen limits, etc...)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode 0 - Horizontal pixel values
XMinM0        =    0                 ;; X min value in pixels for M1 Screen
XMaxM0        =  159                 ;; X max value in pixels for M1 Screen
XMaxM0LSB     =  159                 ;; LSB value of XMax (319 - 256)
XMaxM0MSB     =    0                 ;; MSB value of XMax (319 = 1 * 256 + 63)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode 1 - Horizontal pixel values
XMinM1        =    0                 ;; X min value in pixels for M1 Screen
XMaxM1        =  319                 ;; X max value in pixels for M1 Screen
XMaxM1LSB     =   63                 ;; LSB value of XMax (319 - 256)
XMaxM1MSB     =    1                 ;; MSB value of XMax (319 = 1 * 256 + 63)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode 2 - Horizontal pixel values
XMinM2        =    0                 ;; X min value in pixels for M1 Screen
XMaxM2        =  639                 ;; X max value in pixels for M1 Screen
XMaxM2LSB     =  127                 ;; LSB value of XMax (639 - 2*256)
XMaxM2MSB     =    2                 ;; MSB value of XMax (639 = 2 * 256 + 127)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vertical pixel values
YMin          =     0                 ;; Y min value for all modes
YMax          =   199                 ;; Y max value for all modes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Shared values
screenNbOctet =    79                 ;; Number of octets in a screen line (defautl CRTC mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

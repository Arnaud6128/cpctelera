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

.equ ASIC_OFFS_CONFIG_ZOOM, 0x04

.equ ASIC_HW_SPRITE_DATA,   0x40
.equ ASIC_HW_SPRITE_CONFIG, 0x60
.equ ASIC_PALETTE_COLOUR,   0x6400
.equ ASIC_BORDER_COLOUR,    0x6420 ;; Border color is index 0 of Sprite hardware palette
.equ ASIC_PALETTE_SPRITE,   0x6420

.equ ASIC_RASTER_INT,       0x6800

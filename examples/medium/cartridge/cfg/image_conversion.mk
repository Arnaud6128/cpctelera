##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine
##  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU Lesser General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU Lesser General Public License for more details.
##
##  You should have received a copy of the GNU Lesser General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##------------------------------------------------------------------------------############################################################################
##                        CPCTELERA ENGINE                                ##
##                 Automatic image conversion file                        ##
##------------------------------------------------------------------------##
## The images of the example are converted here, with the IMG2SP macro.   ##
## The creation of the cartridge is somewhere else (cfg/cartridge.mk): it ##
## only puts the files generated here in the banks.                       ##
############################################################################

## Firmware inks of the 16 pens of the title: the hardware colours of resources/TITLE.PAL, converted to
## firmware numbers (0 black, 1 blue, 10 cyan, 15 orange, 4 magenta, 26 bright white, ...)
PALETTE_TITLE=0 1 10 15 4 26 20 25 6 23 7 16 24 3 5 11

## Colours of the ASIC (RGB) of the pens of the hardware sprite (pen 0: transparent)
RGB_SPRITE=0x000000 0xFFFF00 0xFF0000 0xFFFFFF

## Title of mode 0 in binary format: assets/title.bin (16 KB: a whole bank)
$(eval $(call IMG2SP, SET_MODE        , 0                  ))
$(eval $(call IMG2SP, SET_FOLDER      , assets/            ))
$(eval $(call IMG2SP, SET_OUTPUT      , bin                ))
$(eval $(call IMG2SP, SET_IMG_FORMAT  , screen             ))
$(eval $(call IMG2SP, SET_PALETTE_FW  , $(PALETTE_TITLE)   ))
$(eval $(call IMG2SP, CONVERT         , resources/title.png , 0, 0, title ))

## Hardware sprite 16x16 in binary format: assets/hwsprite.bin (256 bytes, 1 byte per pixel)
$(eval $(call IMG2SP, SET_IMG_FORMAT  , spritehardware     ))
$(eval $(call IMG2SP, SET_PALETTE_PLUS, $(RGB_SPRITE)      ))
$(eval $(call IMG2SP, CONVERT         , resources/hwsprite.png , 16, 16, hwsprite ))

## Palettes linked to the program: src/g_palette_*.c and src/g_palette_*.h
##   g_palette_title: hardware colours of the gate array (u8), g_palette_sprite: colours of the ASIC (u16, 12 bits)
$(eval $(call IMG2SP, SET_FOLDER      , src/               ))
$(eval $(call IMG2SP, CONVERT_PALETTE , $(PALETTE_TITLE), g_palette_title ))
$(eval $(call IMG2SP, CONVERT_PALETTE_PLUS, $(RGB_SPRITE), g_palette_sprite ))
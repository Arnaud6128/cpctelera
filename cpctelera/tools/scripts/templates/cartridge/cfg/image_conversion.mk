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
##------------------------------------------------------------------------------
############################################################################
##                        CPCTELERA ENGINE                                ##
##                 Automatic image conversion file                        ##
##------------------------------------------------------------------------##
## The images of the project are converted here, with the IMG2SP macro.   ##
## The creation of the cartridge is somewhere else (cfg/cartridge.mk): it ##
## only puts the files generated here in the banks.                       ##
############################################################################

## Firmware inks of the pens 0 to 3 of the picture: black, bright yellow, bright cyan, bright white
PALETTE=0 24 20 26

## Sprite of mode 1 (16x16 pixels) in binary format: assets/sprite.bin (64 bytes)
$(eval $(call IMG2SP, SET_MODE        , 1                  ))
$(eval $(call IMG2SP, SET_FOLDER      , assets/            ))
$(eval $(call IMG2SP, SET_OUTPUT      , bin                ))
$(eval $(call IMG2SP, SET_IMG_FORMAT  , sprites            ))
$(eval $(call IMG2SP, SET_PALETTE_FW  , $(PALETTE)         ))
$(eval $(call IMG2SP, CONVERT         , resources/gfx/sprite.png , 16, 16, sprite ))

## Palette as hardware colours: src/g_palette.c and src/g_palette.h, linked to the program
$(eval $(call IMG2SP, SET_FOLDER      , src/               ))
$(eval $(call IMG2SP, CONVERT_PALETTE , $(PALETTE), g_palette ))
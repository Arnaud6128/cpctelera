##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
## This file is intended for users to automate image conversion from JPG, ##
## PNG, GIF, etc. into C-arrays.                                          ##
############################################################################

PALETTE_SPRITE_HW=0x000000 0xAA2805 0xFF0000 0xFFFFFF \
0x808080 0x1E64A0 0x2896DC 0x501414 \
0xFF6419 0xFFE141 0x28232C 0x413741 \
0x5A4B4B 0x5A505F 0xC8E6F5 0xFFFFC8

PALETTE_PLANET=0 11 23 26
PALETTE_FIRE=0 7 8 17

$(eval $(call IMG2SP, SET_MODE        , 1 )) 
$(eval $(call IMG2SP, SET_FOLDER      , src/ ))
$(eval $(call IMG2SP, SET_OUTPUT      , c ))  # { bin, c }
$(eval $(call IMG2SP, SET_IMG_FORMAT  , sprites ))  #{ sprites, zgtiles, screen, spritehardware }
$(eval $(call IMG2SP, SET_PALETTE_FW  , $(PALETTE_PLANET) ))
$(eval $(call IMG2SP, CONVERT         , assets/planet.png , 0, 0, pre_planet , , ))
$(eval $(call IMG2SP, SET_PALETTE_FW  , $(PALETTE_FIRE)   ))
$(eval $(call IMG2SP, CONVERT         , assets/stars.png , 8, 5, pre_stars , , pre_tileset ))
$(eval $(call IMG2SP, SET_IMG_FORMAT  , spritehardware ))
$(eval $(call IMG2SP, CONVERT_PALETTE_PLUS, $(PALETTE_SPRITE_HW), g_palette_hw ))
$(eval $(call IMG2SP, CONVERT         , assets/ship.png , 16, 16, sprite_ship , , ))
$(eval $(call IMG2SP, CONVERT         , assets/explosions.png , 16, 16, sprite_explosion , , ))

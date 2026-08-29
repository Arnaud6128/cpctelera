##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

## Firmware palettes definition
PALETTE=0 4 16 26

## Default values
$(eval $(call IMG2SP, SET_MODE        , 1                  ))  
$(eval $(call IMG2SP, SET_MASK        , none               )) 
$(eval $(call IMG2SP, SET_FOLDER      , src                ))
$(eval $(call IMG2SP, SET_IMG_FORMAT  , sprites            ))	
$(eval $(call IMG2SP, SET_PALETTE_FW  , $(PALETTE)         ))
$(eval $(call IMG2SP, CONVERT_PALETTE , $(PALETTE), g_palette ))
$(eval $(call IMG2SP, SET_OUTPUT      , c                ))  
$(eval $(call IMG2SP, CONVERT         , img/winner.png , 0, 0, winner, , ))
$(eval $(call IMG2SP, SET_FOLDER      , img                ))
$(eval $(call IMG2SP, SET_OUTPUT      , bin                ))  
$(eval $(call IMG2SP, CONVERT         , img/winner_rle.png , 0, 0, winner_rle, , ))

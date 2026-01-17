##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2025 Arnaud BOUCHE (@Arnaud 6128)
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
## This file is intended for users to automate music conversion from      ##
## original files (like Arkos Tracker .aks) into data arrays or assembly. ##
############################################################################

# Default values
#$(eval $(call AKS2DATA, SET_FOLDER   , src/ ))
#$(eval $(call AKS2DATA, SET_OUTPUTS  , s    )) # { bin, s }
#$(eval $(call AKS2DATA, SET_PLAYER   , akg  )) # { akg, akm, fx }
#$(eval $(call AKS2DATA, SET_EXTRAPAR ,      )) 
# Conversion
#$(eval $(call AKS2DATA, CONVERT      , music.aks , name , mem_address )) #  mem_adress mandatory for bin output

$(eval $(call AKS2DATA, SET_OUTPUTS  , bin  )) 
$(eval $(call AKS2DATA, SET_PLAYER , akg )) 
$(eval $(call AKS2DATA, CONVERT , music/molusk.aks , music , 0x300))
$(eval $(call AKS2DATA, SET_OUTPUTS  , s  )) 
$(eval $(call AKS2DATA, SET_PLAYER , fx )) 
$(eval $(call AKS2DATA, CONVERT , music/sfx.aks , effects , ))

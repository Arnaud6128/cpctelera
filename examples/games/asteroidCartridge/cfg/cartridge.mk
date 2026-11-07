##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine
##  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
##  Use of Claude.ai - Opus 5.5
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
##              Cartridge (CPR) of the CPC Plus / GX4000                  ##
##------------------------------------------------------------------------##
## The bank 0 is the crt0 (cart/cpct_cart_crt0.s: reset and boot) and the ##
## game, copied to the RAM at Z80CODELOC. The other banks are filled with ##
## ADD_BANK_FILE (see cfg/modules/cartridge.mk): the files of a bank      ##
## follow each other, an error stops the build if they do not fit in 16KB ##
############################################################################

# Loading screen (assets/title.png converted by cfg/image_conversion.mk), copied to the screen at start
$(eval $(call CARTRIDGE, SET_HEADER    , src/banks.h ))
$(eval $(call CARTRIDGE, ADD_BANK_FILE , assets/title.bin , 1 ))$(eval $(call CARTRIDGE, ADD_BANK_FILE , assets/molusk.bin , 2 ))

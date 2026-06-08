##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2026 Arnaud BOUCHE (@Arnaud 6128)
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
##                 Automatic copy file data to disk sectors               ##
##------------------------------------------------------------------------##
## This file is intended for users to automate file import in raw format  ##
## into disk specific tracks / sectors                                    ##
############################################################################
##              DETAILED INSTRUCTIONS AND PARAMETERS                      ##
##------------------------------------------------------------------------##
##                                                                        ##
## Macros used are :                                                      ##
##  SET_DSK_FILE  : Set destination disk file                             ##
##  ADD_DATA_FILE : Add file (arg1) content to specific tracks / sectors  ##
##                  location (arg2) see examples next.                    ##
##   Examples (from RASM docs) :                                          ##
##    5             => track 5                                            ##
##    5:#C2         => sector #C2 track 5                                 ##
##    0-5           => tracks 0 to 5 and sectors in PHYSICAL order!       ##
##    0-5:$C2-0xC9  => sectors #C2 to #C9 on tracks 0 to 5                ##
##    0:#C1 0:#C3   => sectors #C1 and #C3 on track 0                     ##
##    5+            => from track 5 to the end of the disk allowed,       ##
##                     in PHYSICAL sector order                           ##
##    5+:0xC1-0xC9  => from track 5 to the end of the disk allowed,       ##
##                     in logical sector order DATA                       ##
##                                                                        ##
############################################################################

$(eval $(call FILE2SECTOR, SET_DSK_FILE , diskSectors.dsk ))
$(eval $(call FILE2SECTOR, ADD_DATA_FILE , dat/wolf.dat, 5+:0xC1-0xC9 ))
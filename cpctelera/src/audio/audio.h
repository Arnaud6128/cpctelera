//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
//  Copyright (C) 2026 Targhan/Arkos 
//  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//-------------------------------------------------------------------------------
//######################################################################
//### MODULE: Audio                                                  ###
//######################################################################
//### This module contains code for music and SFX players and other  ###
//### audio routines for ArkosTracker 3                              ###
//######################################################################
//
#ifndef CPCT_AUDIO_H
#define CPCT_AUDIO_H

enum
{
	AT3_CHANNEL_A,
	AT3_CHANNEL_B,
	AT3_CHANNEL_C
};

// Arkos AKG player functions
extern void cpct_PLY_AKG_Init(void* songdata, u16 subSong) __z88dk_callee;
extern void cpct_PLY_AKG_Play(void);
extern void cpct_PLY_AKG_Stop(void);
extern void cpct_PLY_AKG_InitSoundEffects(void* sfx_song_data) __z88dk_fastcall;
extern void cpct_PLY_AKG_PlaySoundEffect(u8 sfx_num, u8 channel, u16 volume) __z88dk_callee;
extern void cpct_PLY_AKG_StopSoundEffectFromChannel(u8 channel) __z88dk_fastcall;

// Arkos AKM player functions
extern void cpct_PLY_AKM_Init(void* songdata, u16 subSong) __z88dk_callee;
extern void cpct_PLY_AKM_Play(void);
extern void cpct_PLY_AKM_Stop(void);
extern void cpct_PLY_AKM_InitSoundEffects(void* sfx_song_data) __z88dk_fastcall;
extern void cpct_PLY_AKM_PlaySoundEffect(u8 sfx_num, u8 channel, u16 volume) __z88dk_callee;
extern void cpct_PLY_AKM_StopSoundEffectFromChannel(u8 channel) __z88dk_fastcall;

#endif
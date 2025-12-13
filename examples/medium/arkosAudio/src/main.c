//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2025 CPCteleraNext (@Arnaud6128)
//  Copyright (C) 2025 CPCtelera - ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
//------------------------------------------------------------------------------

#include <cpctelera.h>
#include <stdio.h>

// This file is generated on compilation from music/molusk.aks
// In this example the AKG Player is used but it can be changed to AKM
// See arkosTracker3 documentation about different players.
#include "arkosPlayer3.h"

// Defined type to know the status of a Key 
//    Key is either Pressed / Released, and K_NOEVENT is used to
//    report that a key is in the same status as in previous checks
//    (Continues pressed or continues released)
//
typedef enum { K_NOEVENT, K_RELEASED, K_PRESSED } TKeyStatus;

// Playing sound
u8 gPlaying;

////////////////////////////////////////////////////////////////////////
// Play Music on interruption 
//
void MusicInterruptHandler(void)
{
    static u8 sInterrupt = 0;
    
    // Play next music 1/50 step.
    if (sInterrupt == 1)
    {
        if (gPlaying)
            cpct_PLY_AKG_Play();  
    }
    else if (sInterrupt == 6)
    {        
        cpct_scanKeyboard_if();
        sInterrupt = 0;
    }

    sInterrupt++;
}

////////////////////////////////////////////////////////////////////////
// Checks if a Key has changed from pressed to released or viceversa
// If it has changed, that is considered and event, the status of 
// the key is changed and the concrete event is returned. If it is
// in its previous status, nothing is done and K_NOEVENT is returned
//
TKeyStatus checkKeyEvent(cpct_keyID key, TKeyStatus *keystatus) {
   TKeyStatus newstatus;   // Hold the new status of the key (pressed / released)

   // Check the new status of the key and save it into newstatus
   if ( cpct_isKeyPressed(key) )
      newstatus = K_PRESSED;   // Key is now pressed
   else
      newstatus = K_RELEASED;  // Key is now released

   // Check if newstatus is same or different than previous one
   // If it is different, change key status and report the event
   if (newstatus == *keystatus)
      return K_NOEVENT;       // Same key status, report NO EVENT
   else {
      *keystatus = newstatus; // Status has changed, save it...
      return newstatus;       // And return the new status
   }
}

////////////////////////////////////////////////////////////////////////
// MAIN: Arkos Tracker Music Example
//    Keys:
//       * SPACE - Start / Stop Music
//       *   1   - Play a sound effect on Channel A
//       *   2   - Play a sound effect on Channel C
//
void main(void) 
{
   TKeyStatus k_space, k_1, k_2;    // Status of the 3 Keys for this example (Space, 1, 2)
   u8* pvideomem = CPCT_VMEM_START; // Pointer to video memory where next character will be drawn

   // All 3 keys are considered to be released at the start of the program
   k_space = k_1 = k_2 = K_RELEASED;
   gPlaying = 1;

   // Initialize CPC
   cpct_disableFirmware();    // Disable firmware to prevent interaction
   cpct_setVideoMode(2);      // Set Mode 2 (640x200, 2 colours)
   cpct_setDrawCharM2(1, 0);  // Set Initial colours for drawCharM2 (Foreground/Background)

   printf("ArkosTracker 3 demo.\r\n\r\nPress 'Space bar' to stop/play sound.\r\nPress '1' or '2' to play sound effect.");
   
   // Initialize the song to be played
   cpct_PLY_AKG_Init(MUSICSTART, 0);    // Initialize the music
   cpct_PLY_AKG_InitSoundEffects(EFFECTSSOUNDEFFECTS); // Initialize the sound effects

    // Music is played on interrupt.
   cpct_setInterruptHandler(MusicInterruptHandler);

   while (1) 
   {
       // When Space is released, stop / continue music
       if ( checkKeyEvent(Key_Space, &k_space) == K_RELEASED ) 
       {                       
           // Change it from playing to not playing and viceversa (0 to 1, 1 to 0)
           gPlaying ^= 1;
           
           // Stop sound
           if (!gPlaying){
               cpct_PLY_AKG_Stop(); // Cut down sound output
           }
           else{
               cpct_PLY_AKG_PlaySoundEffect(1, CHANNEL_B, 0); // Play sound
           }
       } 

       // Play sound effect when press key 1, or 2
       // !! Warning sound effect start at index 1 !!
       if ( checkKeyEvent(Key_1, &k_1) == K_RELEASED ) 
       {
           cpct_PLY_AKG_PlaySoundEffect(2, CHANNEL_A, 0);
       } 

       if ( checkKeyEvent(Key_2, &k_2) == K_RELEASED ) 
       {
           cpct_PLY_AKG_PlaySoundEffect(3, CHANNEL_C, 0);
       } 
   }
}

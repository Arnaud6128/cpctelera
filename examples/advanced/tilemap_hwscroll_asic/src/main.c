//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
#include "tilemap.h"
#include "tiles.h"

/////////////////////////////////////////////////////////////////////////////////
// USEFUL MACROS AND CONSTANTS
#define MAXSCROLL      80
#define SCR_TILE_WIDTH 40
#define MAP_WIDTH     120
#define MAP_HEIGHT     46

/////////////////////////////////////////////////////////////////////////////////
// STRUCTURES 

// Structure defining a tilemap located on the screen
typedef struct {
   u8* pVideo;   // Pointer to the upper-left corner of the tilemap in video memory
   u8* pTilemap; // Pointer to the start of the drawable window of the tilemap
   u8  scroll;   // Scrolling offset from the original video memory location
} TScreenTilemap;

/////////////////////////////////////////////////////////////////////////////////
// Read User Keyboard Input and do associated actions
//
i16 wait4KeyboardInput(void){
   // Read keyboard continuously until the user perfoms an action
   while(1) {
      // Scan Keyboard
      cpct_scanKeyboard_f(); 

      // Check user keys for controlling scroll. If one of them is pressed
      // return the associated scroll offset.
      if      (cpct_isKeyPressed(Key_CursorRight)) return  1;
      else if (cpct_isKeyPressed(Key_CursorLeft))  return -1;
   }
}

/////////////////////////////////////////////////////////////////////////////////
// Scrolls the tilemap, relocates pointers and draws left and right columns 
// with their new content after scrolling
//
void scrollScreenTilemap(TScreenTilemap *scr, i16 scroll) { 
   // Select leftmost or rightmost column of the tilemap to be redrawn 
   // depending on the direction of the scrolling movement made
   u8 column = (scroll > 0) ? (SCR_TILE_WIDTH-1) : (0);

   // Update pointers to tilemap drawable window, tilemap upper-left corner in video memory
   // and scroll offset
   scr->pVideo   += 2*scroll; // Video memory starts now 2 bytes to the left or to the right
   scr->pTilemap += scroll;   // Move the start pointer to the tilemap 1 tile (1 byte) to point to the drawable zone (viewport)
   scr->scroll   += scroll;   // Update scroll offset to produce scrolling

   // Wait for VSYNC before redrawing,
   cpct_waitVSYNC();
     
   // Do hardware scrolling to the present offset
   cpct_setVideoMemoryOffset(scr->scroll);    
   
   // Redraw newly appearing column (either it is left or right)
   cpct_etm_drawTileBox2x4(column, 0,         // (X, Y) Upper-left Location of the Box (column in this case) to be redrawn
                           1, MAP_HEIGHT,     // (Width, Height) of the Box (column) to be redrawn
                           MAP_WIDTH,         // Width of the full tilemap (which is wider than the screen in this case)
                           scr->pVideo,       // Pointer to the upper-left corner of the tilemap in video memory
                           scr->pTilemap);    // Pointer to the first tile of the tilemap to be drawn (upper-left corner
                                              // ... of the tilemap viewport window)
   // When scrolling to the left, erase the character that appears on the left, just
   // below the visible tilemap
   if (scroll <= 0) 
   {
      u8* br_char = cpct_getScreenPtr(scr->pVideo, 0, 4*MAP_HEIGHT);
      cpct_drawSolidBox(br_char, 0, 2, 8);  // bottom-right scrolled-out char
   }
}

////////////////////////////////////////////////////
//    Initialize for CPC Plus features
//        
void InitCpcPlus(void)
{
    cpct_disableFirmware(); // Disable firmware
    cpct_asicUnlock();         // Unlock asic
    cpct_asicPageConnect();    // Connect Asic memory page configuration (0x4000)    

    // When scrolling to the right auto hide top-left corner of the screen. 
    //u8* sscr = ASIC_SSCR_ADRESS;
    //*sscr = cpctm_asicSSCRBorder(*sscr, ASIC_SCROLL_HIDE_BORDER);
    cpct_asicSetScrollBorder(1);    
}

/////////////////////////////////////////////////////////////////////////////////
// Machine initialization code
//
void initialize_CPC(void) {
    // Initialize the application
   cpct_disableFirmware();         // Firmware must be disabled for this application to work
   cpct_setVideoMode(0);           // Set Mode 0 (160x200, 16 Colours)
   cpct_setPalette(g_palette, 13); // Set Palette 
   cpct_setBorder(HW_BLACK);       // Set the border and background colours to black
   
   InitCpcPlus();                  // Initialize for CPC Plus features

   // VERY IMPORTANT: Before using EasyTileMap functions (etm), the internal
   // pointer to the tileset must be set. 
   cpct_etm_setTileset2x4(g_tileset);   

   // Clean up the screen 
   cpct_memset(CPCT_VMEM_START, 0x00, 0x4000);

   // Draw the full tilemap for the first time
   cpct_etm_drawTileBox2x4(0, 0,                       // (X, Y) upper-left corner of the tilemap
                           SCR_TILE_WIDTH, MAP_HEIGHT, // (Width, Height) of the Box to be drawn (all the screen)
                           MAP_WIDTH,                  // Width of the full tilemap (which is wider than the screen)
                           CPCT_VMEM_START,                   // Pointer to the start of video memory (upper-left corner of the
                                                       // ...tilemap in the screen)
                           g_tilemap);                 // Pointer to the first tile of the tilemap to be drawn (upper-left
                                                       // ... corner of the tilemap viewport window)
}

/////////////////////////////////////////////////////////////////////////////////
// Main application's code
//
void main(void) 
{
    u8* tile_unconst;
    tile_unconst = (u8*)g_tilemap;
    TScreenTilemap scr = { CPCT_VMEM_START, tile_unconst, 0 }; // Screen tilemap properties
    i8 pixelScroll = 0; // Pixel scroll offset -4 to 4 in mode 0
    i16 scroll_offset;  // Requested scroll offset

    initialize_CPC(); // Initialize the machine and set up all necessary things

    // Indefinitely draw the tilemap, listen to user input, 
    // do changes and draw it again
    while(1) 
    {
        // Waits for a user input and return requested scroll offset
        scroll_offset = wait4KeyboardInput();

        // Ensure requested scroll_offset is possible before doing it
        if ( scroll_offset > 0 ) 
        {
            if ( scr.scroll == MAXSCROLL ) 
                continue;  // Do not scroll passed the right limit
        } 
        else 
        {
            if ( scr.scroll == 0 ) 
                continue;  // Do not scroll passed the left limit
        }

        pixelScroll += scroll_offset;

        // Pixel scroll right
        if (pixelScroll >= 0)
        {        
            // Go Right
            if (scroll_offset > 0)
            {
                if (pixelScroll == 1)
                {
                    scrollScreenTilemap(&scr, scroll_offset);
                }

                if (pixelScroll == 4)
                {
                    pixelScroll = 0;
                    cpct_asicSetScrollHoriz(0);
                }
                else
                {
                    cpct_asicSetScrollHoriz(ASIC_SCROLL_MODE0 * (4 - pixelScroll));
                }
            }
            // Go Left
            else
            {
                if (pixelScroll == 0)
                {
                    scrollScreenTilemap(&scr, scroll_offset);
                    cpct_asicSetScrollHoriz(0);
                }
                else
                {
                    cpct_asicSetScrollHoriz(ASIC_SCROLL_MODE0 * (4 - pixelScroll));
                }
            }
        }
        // Pixel scroll left
        else
        {
            // Go Left
            if (scroll_offset < 0)
            {
                if (pixelScroll == -4)
                {
                    scrollScreenTilemap(&scr, scroll_offset);
                    pixelScroll = 0;
                }
            }

            cpct_asicSetScrollHoriz(ASIC_SCROLL_MODE0 * -pixelScroll);
        }
    }
}
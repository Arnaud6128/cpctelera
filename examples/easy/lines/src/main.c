//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
//------------------------------------------------------------------------------

#include <cpctelera.h>

//------------------------------------------------------------------------------
// The goal of this example is to demonstrate the line and point drawing functions,
// it is not a 3D tutorial. The mathematic 3D part will not be detailed.
//------------------------------------------------------------------------------

#define VRAM_PAGE_C0 (u8*)CPCT_VMEM_START
#define VRAM_PAGE_40 (u8*)0x4000

typedef struct 
{
    i16 x, y, z;
} SPoint3D;

typedef struct 
{
    u16 x;
    u8  y;
} SPoint2D;

typedef struct 
{
    u8 v0;
    u8 v1;
    u8 color;
} SEdge;

// -----------------------------------------------------------------------------
// Ship model geometry
// -----------------------------------------------------------------------------
#define SHIP_VERTICES 16
#define SHIP_EDGES    24

const SPoint3D ship_nodes[SHIP_VERTICES] = 
{
    // Main Body Hull (0 to 6)
    {   0,   0,  35 },  // 0: Nose tip
    { -42,  -6, -15 },  // 1: Left outer wingtip
    {  42,  -6, -15 },  // 2: Right outer wingtip
    { -18,  12, -15 },  // 3: Top plate left
    {  18,  12, -15 },  // 4: Top plate right
    { -18, -12, -15 },  // 5: Bottom plate left
    {  18, -12, -15 },  // 6: Bottom plate right
    
    // Top Fin / Antenna (7)
    {   0,  18, -15 },  // 7: Antenna tip

    // Left Central Thruster (8 to 11)
    {  -8,  -2, -15 },  // 8: Top-left
    {  -2,  -2, -15 },  // 9: Top-right
    {  -8,  -8, -15 },  // 10: Bot-left
    {  -2,  -8, -15 },  // 11: Bot-right

    // Right Central Thruster (12 to 15)
    {   2,  -2, -15 },  // 12: Top-left
    {   8,  -2, -15 },  // 13: Top-right
    {   2,  -8, -15 },  // 14: Bot-left
    {   8,  -8, -15 }   // 15: Bot-right
};

// SEdge table with color attribute
const SEdge ship_edges[SHIP_EDGES] = 
{
    // Hull (Color 1 and 3)
    { 0,  1, 1 }, { 0,  2, 1 }, { 0,  3, 1 }, { 0,  4, 1 }, { 0,  5, 1 }, { 0,  6, 1 },
    { 1,  3, 1 }, { 2,  4, 1 }, { 3,  4, 1 },
    { 1,  5, 1 }, { 2,  6, 1 }, { 5,  6, 1 },
    { 3,  5, 3 }, { 4,  6, 3 },
    { 3,  7, 3 }, { 4,  7, 3 },

    // Engines (Color 2)
    { 8,  9, 2 }, { 9, 11, 2 }, {11, 10, 2 }, {10,  8, 2 },
    {12, 13, 2 }, {13, 15, 2 }, {15, 14, 2 }, {14, 12, 2 }
};

// Precalculated sine lookup table (64 angles x 64 scale)
const i8 sintable[64] =
{
      0,   6,  12,  18,  24,  30,  35,  40,  45,  49,  53,  56,  59,  61,  63,  63,
     64,  63,  63,  61,  59,  56,  53,  49,  45,  40,  35,  30,  24,  18,  12,   6,
      0,  -6, -12, -18, -24, -30, -35, -40, -45, -49, -53, -56, -59, -61, -63, -63,
    -64, -63, -63, -61, -59, -56, -53, -49, -45, -40, -35, -30, -24, -18, -12,  -6
};

// Macro functions
#define FAST_COS(X) sintable[(X + 16)  % 64]
#define FAST_SIN(X) sintable[X % 64]

///////////////////////////////////////////////
// 3D Transformation, Scaling and 2D Projection
void TransformAndProject(const SPoint3D* in, SPoint2D* out, u8 angleX, u8 angleY, u8 scale) 
{
    // 0. Apply dynamic scale (scale is base 32 = 1.0x)
    i16 x = (in->x * scale) >> 5; // divide by 32
    i16 y = (in->y * scale) >> 5;
    i16 z = (in->z * scale) >> 5;

    // 1. Y-axis Rotation
    i16 cosY = FAST_COS(angleY);
    i16 sinY = FAST_SIN(angleY);
    i16 x1 = (x * cosY - z * sinY) >> 6; // divide by 64
    i16 z1 = (x * sinY + z * cosY) >> 6;

    // 2. X-axis Rotation
    i16 cosX = FAST_COS(angleX);
    i16 sinX = FAST_SIN(angleX);
    i16 y2 = (y * cosX - z1 * sinX) >> 6;

    // 3. 2D Projection (Center: 160, 100) - Mode 1 320x200)
    out->x = (u16)(160 + x1);
    out->y = (u8)(100 + y2);
}

/////////////////////////////////////////
// Clear screens and display text in both
void InitScreen(void)
{
	cpct_memset_f64(VRAM_PAGE_40, 0x00, 0x4000);
	cpct_drawStringM1("Press any key to flip vertice and point", VRAM_PAGE_40);

	cpct_memset_f64(VRAM_PAGE_C0, 0x00, 0x4000);			
	cpct_drawStringM1("Press any key to flip vertice and point", VRAM_PAGE_C0);
}

///////////////////////
// Init mode and colors
void InitDisplay(void)
{
	cpct_disableFirmware();
	cpct_setDrawCharM1(1, 0);
    cpct_setVideoMode(1);
	
	cpct_setBorder(0x54); // Black
	cpct_setPALColour(0, 0x54); // Black
	cpct_setPALColour(1, 0x43); // Pastel Yellow
	cpct_setPALColour(2, 0x57); // Sky Blue 
}

////////////////////////////////////////
// Main demo
// Use line and plot to display 3d ship
void main(void) 
{
	// Transformation variables
    u8 angleX = 32;
    u8 angleY = 0;
    u8 scale = 48;
	
	// Flip vertices or points to draw
	u8 drawVertice = 1;
    
    // Current frame projected coordinates
    SPoint2D proj[SHIP_VERTICES];

	// Double buffer to avoid tearing
    u8* draw_buffer = VRAM_PAGE_40;
	
	// 0 = page 40, 1 = page C0
    u8 buffer_index = 0; 
    
	// Initialisations
	InitDisplay();
	InitScreen();

    // Render loop
    while (1) 
	{
        // ---------------------------------------------------------------------
        // 1. SCREEN ERASING
        // ---------------------------------------------------------------------	
		u8* cleanBox = cpct_getScreenPtr(draw_buffer, 18, 25);
		cpct_drawSolidBox(cleanBox, 0, 50, 150);
	
        // ---------------------------------------------------------------------
        // 2. COMPUTE NEW POSITION
        // ---------------------------------------------------------------------	
        angleY = (angleY + 1) % 64;

        for (u8 i = 0; i < SHIP_VERTICES; i++) {
            TransformAndProject(&ship_nodes[i], &proj[i], angleX, angleY, scale);
        }

        // ---------------------------------------------------------------------
        // 4. RENDER SHIP
        // ---------------------------------------------------------------------
		if (drawVertice)
		{
			// Draw wireframe edges using their color attribute
			for (u8 i = 0; i < SHIP_EDGES; i++) 
			{
				u8 v0 = ship_edges[i].v0;
				u8 v1 = ship_edges[i].v1;
				
				cpct_geometryLineM1(draw_buffer, 
							        proj[v0].x, proj[v0].y,
							        proj[v1].x, proj[v1].y, 
							        ship_edges[i].color);			  
			}
        }
		else        
		{
			// Draw plots with Color 1
			for (u8 i = 0; i < SHIP_VERTICES; i++) 	{
				cpct_geometryPlotM1(draw_buffer, proj[i].x, proj[i].y, 1);
			}
		}

        // ---------------------------------------------------------------------
        // 5. HARDWARE PAGE FLIP TO AVOID TEARING
        // ---------------------------------------------------------------------
        if (buffer_index == 0) 
		{
            cpct_setVideoMemoryPage(cpct_page40);
            draw_buffer = VRAM_PAGE_C0;
            buffer_index = 1;
        } 
		else 
		{
            cpct_setVideoMemoryPage(cpct_pageC0);
            draw_buffer = VRAM_PAGE_40;
            buffer_index = 0;
        }
		
		// ---------------------------------------------------------------------
        // 5. CHANGE DISPLAY MODE IF KEY PRESSED
        // ---------------------------------------------------------------------
		cpct_scanKeyboard_f();
		if (cpct_isAnyKeyPressed_f())
		{
			drawVertice = !drawVertice;
			cpct_waitVSYNC();
		}
    }
}
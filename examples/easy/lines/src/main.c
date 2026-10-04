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
	cpct_drawStringM1("Press any key to flip vertices / points", VRAM_PAGE_40);

	cpct_memset_f64(VRAM_PAGE_C0, 0x00, 0x4000);			
	cpct_drawStringM1("Press any key to flip vertices / points", VRAM_PAGE_C0);
}

/////////////////////////////////////
// Init mode 1 and colors for speed test and 3D demo
void InitDisplayM1(void)
{
	cpct_setDrawCharM1(1, 0);
    cpct_setVideoMode(1);

	cpct_setBorder(0x54);       // Black
	cpct_setPALColour(0, 0x54); // Black
	cpct_setPALColour(1, 0x57); // Sky Blue
	cpct_setPALColour(2, 0x43); // Pastel Yellow
	cpct_setPALColour(3, 0x4C); // Bright Red
}

//////////////////////////////////////////
// Init mode 0 and colors for speed test
void InitDisplayM0(void)
{
	// 16 colors palette (hardware values)
	static const u8 paletteM0[16] =
	{
		0x54, 0x44, 0x55, 0x5C, 0x58, 0x5D, 0x4C, 0x45,
		0x4D, 0x56, 0x46, 0x57, 0x5E, 0x40, 0x5F, 0x4E
	};

	cpct_setDrawCharM0(13, 0);
    cpct_setVideoMode(0);

	cpct_setBorder(0x54);       // Black
	cpct_setPalette(paletteM0, 16);
}

////////////////////////////////////////
// Line clipping test in Mode 1
// Clears a window, frames it and draws long lines crossing it, starting and
// ending far outside of the screen, clipped to the window by cpct_clipLine
// (xmin must be a multiple of 4 for the window clearing because m1 has 4 pixels by byte)
void ClipTestM1(i16 xmin, i16 ymin, i16 xmax, i16 ymax, u8 color, u8 fast)
{
	i16 cx = (xmin + xmax) / 2;
	i16 cy = (ymin + ymax) / 2;

	// Clear window area (frame included) and draw the frame just outside of the clipping rectangle
	cpct_drawSolidBox(cpct_getScreenPtr(CPCT_VMEM_START, (xmin - 4) / 4, ymin - 1), 0, (xmax - xmin + 9) / 4, ymax - ymin + 3);
	cpct_drawLineM1_f(CPCT_VMEM_START, xmin - 1, ymin - 1, xmax + 1, ymin - 1, 2);
	cpct_drawLineM1_f(CPCT_VMEM_START, xmin - 1, ymax + 1, xmax + 1, ymax + 1, 2);
	cpct_drawLineM1_f(CPCT_VMEM_START, xmin - 1, ymin - 1, xmin - 1, ymax + 1, 2);
	cpct_drawLineM1_f(CPCT_VMEM_START, xmax + 1, ymin - 1, xmax + 1, ymax + 1, 2);

	cpct_setClipRect(xmin, ymin, xmax, ymax);

	// 16 lines through the window center, both endpoints ~1000 pixels away
	for (u8 a = 0; a < 32; a += 2)
	{
		i16 x0 = cx - FAST_COS(a) * 16;
		i16 y0 = cy - FAST_SIN(a) * 16;
		i16 x1 = cx + FAST_COS(a) * 16;
		i16 y1 = cy + FAST_SIN(a) * 16;

		if (cpct_clipLine(&x0, &y0, &x1, &y1))
		{
			if (fast) cpct_drawLineM1_f(CPCT_VMEM_START, x0, y0, x1, y1, color);
			else      cpct_drawLineM1  (CPCT_VMEM_START, x0, y0, x1, y1, color);
		}
	}

	// Restore default clipping rectangle (whole Mode 1 screen)
	cpct_setClipRect(0, 0, 319, 199);
}

////////////////////////////////////////
// Speed test in Mode 1 (320x200, 4 colors)
void SpeedTestM1(void)
{
	// Circle
	cpct_drawCircleM1(CPCT_VMEM_START, 160, 100, 20, 1);
	cpct_drawCircleM1(CPCT_VMEM_START, 160, 100, 21, 2);
	cpct_drawCircleM1(CPCT_VMEM_START, 160, 100, 22, 3);

	// Constants dx/N = 320/40 = 8 | dy/N = 200/40 = 5
	i16 x,y;

	y = 0;
	for (x = 0; x < 320; x += 8)
	{
		cpct_drawLineM1_f(CPCT_VMEM_START, x, 0, 319, y, 1);
		y += 5;
	}

	x = 319;
	for (y = 0; y < 200; y += 5)
	{
		cpct_drawLineM1(CPCT_VMEM_START, 319, y, x, 199, 3);
		x -= 8;
	}

	y = 199;
	for (x = 319; x > 0; x -= 8)
	{
		cpct_drawLineM1_f(CPCT_VMEM_START, x, 199, 0, y, 1);
		y -= 5;
	}

	x = 0;
	for (y = 199; y > 0; y -= 5)
	{
		cpct_drawLineM1(CPCT_VMEM_START, 0, y, x, 0, 3);
		x += 8;
	}

	// Frame
    cpct_drawLineM1_f(CPCT_VMEM_START,   0,   0, 319,   0, 2);
    cpct_drawLineM1_f(CPCT_VMEM_START, 319,   0, 319, 199, 2);
    cpct_drawLineM1_f(CPCT_VMEM_START, 319, 199,   0, 199, 2);
    cpct_drawLineM1_f(CPCT_VMEM_START,   0, 199,   0,   0, 2);

	// Line clipping in 2 windows on both sides of the circles
	ClipTestM1( 72, 70, 127, 129, 1, 1);  // Fast line version
	ClipTestM1(192, 70, 247, 129, 3, 0);  // Compact line version
}

////////////////////////////////////////
// Speed test in Mode 0 (160x200, 16 colors)
void SpeedTestM0(void)
{

	// Circles (radius in lines, Mode 0 circles are corrected to look round)
	cpct_drawCircleM0(CPCT_VMEM_START, 80, 100, 20, 12);
	cpct_drawCircleM0(CPCT_VMEM_START, 80, 100, 21, 13);
	cpct_drawCircleM0(CPCT_VMEM_START, 80, 100, 22, 14);

	// Constants dx/N = 160/40 = 4 | dy/N = 200/40 = 5
	i16 x,y;
	u8  pen;

	y = 0;
	for (x = 0; x < 160; x += 4)
	{
		pen = 1 + (x >> 2) % 11;
		cpct_drawLineM0_f(CPCT_VMEM_START, x, 0, 159, y, pen);
		y += 5;
	}

	x = 159;
	for (y = 0; y < 200; y += 5)
	{
		pen = 1 + (y / 5) % 11;
		cpct_drawLineM0(CPCT_VMEM_START, 159, y, x, 199, pen);
		x -= 4;
	}

	y = 199;
	for (x = 159; x > 0; x -= 4)
	{
		pen = 1 + (x >> 2) % 11;
		cpct_drawLineM0_f(CPCT_VMEM_START, x, 199, 0, y, pen);
		y -= 5;
	}

	x = 0;
	for (y = 199; y > 0; y -= 5)
	{
		pen = 1 + (y / 5) % 11;
		cpct_drawLineM0(CPCT_VMEM_START, 0, y, x, 0, pen);
		x += 4;
	}

	// Frame
    cpct_drawLineM0_f(CPCT_VMEM_START,   0,   0, 159,   0, 15);
    cpct_drawLineM0_f(CPCT_VMEM_START, 159,   0, 159, 199, 15);
    cpct_drawLineM0_f(CPCT_VMEM_START, 159, 199,   0, 199, 15);
    cpct_drawLineM0_f(CPCT_VMEM_START,   0, 199,   0,   0, 15);

	// Plots in the center, one per pen
	for (pen = 0; pen < 16; pen++)
		cpct_drawPlotM0(CPCT_VMEM_START, 72 + pen, 100, pen);
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
	cpct_disableFirmware();

	// Speed testing in Mode 1 then Mode 0
	InitDisplayM1();
	SpeedTestM1();
	cpct_memset_f64(CPCT_VMEM_START, 0x00, 0x4000);  // Clear Mode 1 pattern before switching mode

    // Speed testing in Mode 0
	InitDisplayM0();
	SpeedTestM0();

	// Init screen for 3d in Mode 1
	InitDisplayM1();
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
				
				cpct_drawLineM1_f(draw_buffer,
							        proj[v0].x, proj[v0].y,
							        proj[v1].x, proj[v1].y, 
							        ship_edges[i].color);			  
			}
        }
		else        
		{
			// Draw plots with Color 1
			for (u8 i = 0; i < SHIP_VERTICES; i++) 	{
				cpct_drawPlotM1(draw_buffer, proj[i].x, proj[i].y, 1);
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
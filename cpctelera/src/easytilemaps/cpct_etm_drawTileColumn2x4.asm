;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Function: cpct_etm_drawTileColumn2x4
;;
;;    Draws a column of 2x4-byte tiles from a tilemap: 2 tiles for each of the
;; *nrows* character rows (the 2 tiles of a character row are drawn on its pixel
;; lines 0-3 and 4-7).
;;
;; C Definition:
;;    void <cpct_etm_drawTileColumn2x4> (const void* *ptilemap*, void* *pvideomem*,
;;                                       <u16> *map_width*, <u16> *nrows*) __z88dk_callee;
;;
;; Input Parameters (8 bytes):
;;    (2B HL) ptilemap  - Pointer to the first tile of the column, in the tilemap
;;    (2B DE) pvideomem - Pointer to the video memory byte where the first tile is drawn
;;    (2B BC) map_width - Width in tiles of the tilemap: distance, in tiles, between two
;; tile rows of the tilemap (it is a 16-bit value, so there is no limit of 255 tiles)
;;    (1B  A) nrows     - Number of character rows to draw (2 tiles each, *nrows* x 2 tiles)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_etm_drawTileColumn2x4_asm
;;
;; Parameter Restrictions:
;;    * *ptilemap* must point to a tile index inside a tilemap (a 2D matrix of 1-byte
;; tile indexes), and the next tiles of the column, *map_width* bytes apart, must also
;; be valid tile indexes.
;;    * *pvideomem* must point to the Pixel Line 0 of a character line, from video
;; memory or from a backbuffer, in the first 2K of its 16K block (bits 11-13 of the
;; address are 0), and it must be an EVEN address. To know which bytes are Pixel Line 0
;; you may have a look at <cpct_drawSprite> documentation.
;;    * *map_width* is the width of the tilemap in tiles. It is only used to move
;; from a tile to the one below it, so any value from 1 to 65535 may be used.
;;    * *nrows* must be 1 to 255. 0 is not valid (the loop would repeat 256 times).
;;    * The tileset must have been set with <cpct_etm_setTileset2x4> (the pointer
;; to the tileset is the one that function stores).
;;
;; Known limitations:
;;     * This function does not do any kind of check on the parameters. It is up to the
;; programmer to provide correct values for them.
;;     * This function *will not work from ROM*, as it uses self-modifying code.
;;     * It only draws tiles of 2x4 bytes (8 bytes each).
;;     * The 2 tiles of every character row are drawn at the same video memory column.
;; The address of the next character row is the previous one + 80 bytes, wrapped inside
;; the 2K block where the first one is. This is exactly what hardware scrolling needs
;; (the video memory wraps there when the CRTC start address is changed, see
;; <cpct_setVideoMemoryOffset>), and it never happens without scrolling: 25 character
;; rows of 80 bytes are less than 2K.
;;
;; Destroyed Register values: 
;;    C-bindings   - AF, BC, DE, HL (IX and IY are saved and restored)
;;    ASM-bindings - AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    C-bindings   - 175 bytes
;;    ASM-bindings - 155 bytes
;;
;; Time Measures:
;; (start code)
;;    Case    |      microSecs (us)     |      CPU Cycles       |
;; ------------------------------------------------------------------
;;    Any     |     82 + 192 N          |     328 + 768 N       |
;; ------------------------------------------------------------------
;;  ASM-Saving|        - 35             |        - 140          |
;; ------------------------------------------------------------------
;;    N = 1   |        274              |       1096            |
;; ------------------------------------------------------------------
;;    N = 10  |       2002              |       8008            |
;; ------------------------------------------------------------------
;;    N = 23  |       4498              |      17992            |
;; ------------------------------------------------------------------
;; (end code)
;;    N - Number of character rows (*nrows*), that is, 2 N tiles. 192 us per
;;        character row (96 us per tile).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globl dtr_restore_ptileset      ;; Tileset pointer: the operand of an instruction in cpct_etm_drawTileRow2x4,
                                 ;; set by cpct_etm_setTileset2x4 (it must have been called)

ROW_BYTES = 80                   ;; Bytes of a character row in video memory (40 units x 2 bytes)


;; Draws the tile whose id is at 0(IX) at DE (pixel line 0 or 4) and moves IX to the
;; next tile row. On exit, D = D + 0x18 and E = E + 1. 
.macro DRAW_TILE smc_ts, smc_mw
   ld    a, 0(ix)                ;; [5] A = tile id
   ld    l, a                    ;; [1] |
   ld    h, #0                   ;; [2] | HL = id
   add  hl, hl                   ;; [3] HL = 2 x id (offset in the array of pointers)
smc_ts = .+1
   ld   bc, #0000                ;; [3] BC = tileset (self-modified at the start)
   add  hl, bc                   ;; [3] HL = &tileset[id]
   ld    a, (hl)                 ;; [2] |
   inc  hl                       ;; [2] |
   ld    h, (hl)                 ;; [2] |
   ld    l, a                    ;; [1] HL = address of the 2x4 tile data
smc_mw = .+1
   ld   bc, #0000                ;; [3] BC = width of the tilemap (self-modified at the start)
   add  ix, bc                   ;; [4] IX = tile id of the next tile row

   ld    a, d                    ;; [1] Save D in A, to do the +800h increments
   ld    b, e                    ;; [1] Save E in B, to restore it on each line
   ld    c, #10                  ;; [2] C = 10: after the 2 LDIs of line 1 it is 8, the increment of D. The 7 LDIs leave it >= 3: B is not changed
   ldi                           ;; [5] Pixel line 1: copy 2 bytes
   ldi                           ;; [5] |
   add   a, c                    ;; [1] D += 8 (DE += 800h): C = 10 - 2 LDIs = 8
   ld    d, a                    ;; [1] |
   ld    e, b                    ;; [1] Restore E
   ldi                           ;; [5] Pixel line 2
   ldi                           ;; [5] |
   add   a, #8                   ;; [2] |
   ld    d, a                    ;; [1] |
   ld    e, b                    ;; [1] |
   ldi                           ;; [5] Pixel line 3
   ldi                           ;; [5] |
   add   a, #8                   ;; [2] |
   ld    d, a                    ;; [1] |
   ld    e, b                    ;; [1] |
   ldi                           ;; [5] Pixel line 4: 2 bytes (the last one without LDI)
   ld    a, (hl)                 ;; [2] |
   ld  (de), a                   ;; [2] |
.endm                            ;; [24 + 7 + 54 = 85]

   ;; Here: BC (map_width) is SMC, and IYL = nrows
   ld   bc, (dtr_restore_ptileset + 1) ;; [6] BC = tileset (operand of an instruction of cpct_etm_drawTileRow2x4)
   ld  (smc_ts1), bc             ;; [6] Patch it in the 2 expansions of DRAW_TILE
   ld  (smc_ts2), bc             ;; [6] |

   push hl                       ;; [4] |
   pop  ix                       ;; [3] IX = ptilemap

   ld    a, d                    ;; [1] |
   and   a, #0xF8                ;; [2] | Bits 14-15 and 11-13 of the video address:
   ld__iyh_a                     ;; [2] | the 2K block where the rows wrap, kept in IYH
rowLoop:
   DRAW_TILE smc_ts1, smc_mw1    ;; [85] Top tile of the character row (pixel lines 0-3)
   ld    a, d                    ;; [1] |
   add   a, #8                   ;; [2] | DE = pixel line 4 of the same character
   ld    d, a                    ;; [1] | (D = D + 0x18 + 8 = first D + 0x20)
   dec   e                       ;; [1] |
   DRAW_TILE smc_ts2, smc_mw2    ;; [85] Bottom tile (pixel lines 4-7)

   ;; DE = (first D + 0x38, first E + 1). Next character row: first address + 80, wrapped in its 2K block
   ld    a, e                    ;; [1] |
   add   a, #(ROW_BYTES - 1)     ;; [2] | E = first E + 80 (C = carry)
   ld    e, a                    ;; [1] |
   ld    a, d                    ;; [1] |
   adc   a, #0xC8                ;; [2] | A = D - 0x38 + carry (0xC8 = -0x38)
   and   a, #0x07                ;; [2] | Wrap: only bits 8-10 of the address change
   or__iyh                       ;; [2] Bits 11-15 of the block (IYH)
   ld    d, a                    ;; [1] |

   dec__iyl                      ;; [2] One character row less
   jp   nz, rowLoop              ;; [3] Next row until done

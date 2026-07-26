;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

.globl cpct_plotColorTable_M1
.globl cpct_plotMasksTable_M1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_geometryLineM1
;;
;;    Draws an arbitrary straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using Bresenham's line algorithm.
;;
;; C Definition:
;;    void cpct_geometryLineM1(void* screen_base, u16 x0, u8 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address (typically 0xC000)
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) y0          - Starting Y coordinate (0-199)
;;    (Stack) x1          - Ending X coordinate (0-319)
;;    (Stack) color / y1  - Color index (B: 0-3) and Ending Y coordinate (C: 0-199)
;;
;; Assembly call:
;;    > call cpct_geometryLineM1
;;
;; Bresenham's Line Algorithm Description:
;;    Bresenham's algorithm determines which discrete pixels on a 2D raster 
;;    grid should be selected to form a close approximation of a straight 
;;    line between two given points (X0, Y0) and (X1, Y1).
;;
;;    1. Deltas and Directions:
;;       Calculates delta distances DX = |X1 - X0| and DY = |Y1 - Y0|, as well
;;       as directional steps SX = sgn(X1 - X0) and SY = sgn(Y1 - Y0).
;;
;;    2. Decision Error Variable:
;;       Initializes an accumulated decision error term: err = DX - DY.
;;
;;    3. At each pixel step:
;;       - Evaluates e2 = 2 * err.
;;       - If e2 >= -DY: subtracts DY from err and steps X in direction SX.
;;       - If e2 <= DX: adds DX to err and steps Y in direction SY.
;;
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    336 bytes (310 bytes core routine + 26 bytes binding wrapper)
;;
;; Time Measures (Includes +34 us / +136 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Setup Overhead (routine + binding)       | -      | 63             | 252
;;    Single Point  (50,50) to (50,50)         | 1      | 115            | 460
;;    Horizontal    (0,0)   to (100,0)         | 101    | 3598           | 14392
;;    Shallow Slope (0,0)   to (100,25)        | 101    | 4216           | 16862
;;    Vertical      (0,0)   to (0,100)         | 101    | 5366           | 21462
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | 5997           | 23986
;;   ---------------------------------------------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ld   (screen_start), hl  ;; [5] Save screen start address

    ;; Parameter retrieval and stack adjustment
    ex    de, hl          ;; [1] HL = X0 coordinate, DE = Screen base
    ld   (x0), hl         ;; [5] Save X0
    
    pop   de              ;; [3] DE = Y0
    ld    a, e            ;; [2] A = E = Y0
    
    ex    de, hl          ;; [1] DE = X0 / HL = Y0   
    pop   hl              ;; [3] HL = X1
    
    sbc   hl, de          ;; [3] HL = DX = X1 - X0 
    ld    e, a            ;; [1] E = A = Y0
    
    pop   bc              ;; [3] B = Color / C = Y1
    ld    a, b            ;; [1] Save Color
    ld   (color_pen), a   ;; [4] |

compute_dx:
    ld    iy, #1          ;; [4] SX = 1
    bit   7, h            ;; [2] If DX > 0 then
    jr    z, compute_dy   ;; [2/3] | Jump compute_dy
    
    ld    iy, #-1         ;; [4] SX = -1
    xor   a               ;; [1] HL = -DX
    sub   l               ;; [1] |
    ld    l, a            ;; [1] |
    sbc   a, a            ;; [1] |
    sub   h               ;; [1] |
    ld    h, a            ;; [1] |
    
compute_dy:
    ld   (dx), hl         ;; [4] Save DX
    ld   (sx), iy         ;; [5] Save SX
    
    ld    a, c            ;; [1] A = C = Y1
    sub   e               ;; [1] A (DY) = A (Y1) - E (Y0) 
    
compute_sy:    
    ld    bc, #1          ;; [3] B = SY = 1
    bit   7, a            ;; [2] If DY > 0 then    
    jr    z, compute_err  ;; [2/3] | Jump compute_err
    neg                   ;; [1] A = -DY    
    ld    bc, #-1         ;; [3] B = SY = -1

compute_err:
    ld   (sy), bc         ;; [4] Save SY
    ld    b, #00          ;; [2] BC = A = DY
    ld    c, a            ;; [1] |

;; Nb pixels = max(DX, DY) + 1

compute_pixels:    
    push hl               ;; [4] Save HL (DX) in stack
    or    a               ;; [1] Clear carry flag
    sbc   hl, bc          ;; [3] Compare DX and DY (HL = DX - DY)
	add   hl, bc          ;; [3] Restore HL = DX
    jr    nc, dx_is_max   ;; [2/3] IF (DX >= DY) THEN DX is max

dy_is_max:
    ld    h, b            ;; [1] HL = BC = DY
    ld    l, c            ;; [1] |

dx_is_max:
    inc   hl              ;; [2] HL = max(DX, DY) + 1 (Total pixels)
    ld   (pixel_num), hl  ;; [5] Store initial pixel counter
	pop   hl              ;; [4] Restore HL (DX) from stack
	
	;; DY = -DY
    xor   a               ;; [1] BC = -DY
    sub   c               ;; [1] |
    ld    c, a            ;; [1] |
    sbc   a, a            ;; [1] |
    sub   b               ;; [1] |
    ld    b, a            ;; [1] |    
    ld   (dy), bc         ;; [4] Save -DY

    ;; err = DX - DY
    or    a              ;; [1] Clear carry
    add   hl, bc         ;; [3] HL (ERR) = HL (DX) - DE (DY)    
    ld    b, h           ;; [1] ERR = BC = HL
    ld    c, l           ;; [1] |
    
    ld__ixh_b            ;; [2] IX = BC = ERR
    ld__ixl_c            ;; [2] |

x0=.+1
    ld   hl, #0000       ;; [3] HL = X0

compute_start_vmem:
     push hl              ;; [4] Save HL = X0

    ;; Convert X-pixels to X-bytes (HL = X / 4)
    srl   h               ;; [2] Shift X coordinate right
    rr    l               ;; [2] Rotate right through carry
    srl   h               ;; [2] Shift X coordinate right second time
    rr    l               ;; [2] L now contains X_byte coordinate (0-79)

    ld    c, l           ;; [1] C = L = X_byte
    ld    a, c           ;; [1] Save first X_byte position 
    ld   (prev_x), a     ;; [4] |
	
    ld    a, e           ;; [1] Save first Y position
    ld   (prev_y), a     ;; [4] |

    ;; Calculate VRAM pointer (DE=Base, B=Y, C=X_byte)
    ;: Copy of cpct_getScreenPtr_asm see cpct_getScreenPtr for more informations
    ld    a, e           ;; [1] rA = Y-Coordinate
    and   #0x07          ;; [2] /
    ld    h, a           ;; [1] \ rH = Y % 8      
              
    ;; Now extract Screen Character Row (R) from Y-Coordinate
    ld    a, e           ;; [1] rA = Y-Coordinate
    and   #0xF8          ;; [2] /
    ld    l, a           ;; [1] \ rL = 8*int(Y/8)                                           
    rrca                 ;; [1] / rA' = rA / 4 = 2*int(Y/8)
    rrca                 ;; [1] \ 
    add   a, l           ;; [1] / rL = rL + rA' = 8*int(Y/8) + 2*int(Y/8) = 10*int(Y/8)
    ld    l, a           ;; [1] \ 

    ;; Now rHL = 256*L + 10*R
    add   hl, hl         ;; [3] / rHL' = 8*rHL
    add   hl, hl         ;; [3] | rHL' = 2048*L + 80*R
    add   hl, hl         ;; [3] \ 

    ;; Add up X coordinate
    ld    b, #00         ;; [2] / As rC = X-Coordinate, having rB=0 makes rBC = X-Coordinate
    add   hl, bc         ;; [3] \ rHL' = rHL + X 
    
     ;; Add up screen start address
screen_start=.+1
    ld    bc, #0000      ;; [3] Load video memory start    
    add   hl, bc         ;; [3] rHL' = rHL + screen_start
    
    ld  (screen_ptr), hl ;; [5] Save start video address
    pop hl               ;; [4] Restore HL = X0

loop_line_pixel::
    push  de             ;; [4] Save DE = Y0
    push  hl             ;; [4] Save HL = X0

color_pen=.+1    
    ld    d, #00         ;; [2] D = COLOR    

    ;; 1. Extract pixel index (x & 3)
    ld    a, l           ;; [1] A = X coordinate low byte 
    and   #3             ;; [2] Isolate lower 2 bits
    
    ;; 2. Convert X-pixels to X-bytes (HL = X / 4)
    srl   h              ;; [2]  Shift X coordinate right
    rr    l              ;; [2]  Rotate right through carry
    srl   h              ;; [2]  Shift X coordinate right second time
    rr    l              ;; [2]  L now contains X_byte coordinate (0-79)

    ld    c, l           ;; [1] C = L = X_byte coordinate
    ld    b, e           ;; [1] B = E = Y coordinate
    ld    e, a           ;; [1] E = A = Pixel offset (0-3)
    
screen_ptr=.+1
    ld    hl, #0000           ;; [3]  HL = current screen pointer

test_x_coord::
prev_x=.+1    
    ld    a, #0x00            ;; [2]   Test if x coordinates changed
    cp    c                   ;; [1]   |
    jr    z, test_y_coord     ;: [2/3] | IF no change THEN jump to test Y
    
    ld    a, c                ;; [1] Update previous x value
    ld   (prev_x), a          ;; [4] |
    
    jr    nc,  move_left      ;; [2/3] IF value inferior THEN jump move left
move_right:      
    inc   hl                  ;; [2] Increment video memory
    jp    test_y_coord        ;; [3] Jump to test Y
    
move_left:    
    dec   hl                  ;; [2]   Decrement video memory

test_y_coord::
prev_y=.+1
    ld    a, #0x00            ;; [2]   Test if y coordinates changed
    cp    b                   ;; [1]   |
    jr    z, save_screen_ptr  ;; [2/3] | If no change save
    
    ld    a, b                ;; [1]   Save y coordinates
    ld   (prev_y), a          ;; [4]   |
    jr    nc,  move_up        ;; [2/3] IF y inferior THEN go move up

move_down:
   ld     bc, #0x0800         ;; [3] Compute next scanline 
   add    hl, bc              ;; [3] | HL += 0x0800
   ld     a, h                ;; [1] Check 8-line boundary crossing          
   and    #0x38               ;; [2] |
   jr     nz, save_screen_ptr ;; [2/3] Jump if not inside 8-line block
   ld     bc, #0xC050         ;; [3] Next character row boundary correction
   add    hl, bc              ;; [3] | HL += 0xC050
   jp     save_screen_ptr     ;; [3] Continue

move_up:
   ld     a, h                ;; [1] Read current high byte of address           
   and    #0x38               ;; [2] Check if currently on line 0 of 8-line block
   jr     z, move_up_row      ;; [2/3] If line 0, cross boundary to previous character row
   ld     bc, #0xF800         ;; [3] Move to previous scanline 
   add    hl, bc              ;; [3] | HL += (-0x0800 / 0xF800)
   jp     save_screen_ptr     ;; [3] Continue

move_up_row: 
   ld     bc, #0x37B0         ;; [3] Jump to line 7 of previous character row
   add    hl, bc              ;; [3] | HL += (-0xC050 / #0x37B0)
    
save_screen_ptr:
    ld   (screen_ptr), hl     ;; [5]  Save current screen pointer

plot_pixel:    
    ;; Restore pixel context
    ld   b, d                 ;; [1] B = D = Color
    ld   c, e                 ;; [1] C = E = Pixel index (0-3)

    ld    a, (hl)            ;; [2]  A = Current screen byte from VRAM
    push  hl                 ;; [4]  Save screen byte pointer
    
    ld    hl, #cpct_plotMasksTable_M1 ;; [3]  HL = Base address of mask table
    ld    e, c               ;; [1] HL = &mask_table[offset]
    ld    d, #00             ;; [2] |
    add   hl, de             ;; [3] |
    and   (hl)               ;; [2] Combine AND mask directly from table!
    ld    e, a               ;; [1] E = Preserved background pixels
    
    ;; 8. Inject the new color bits
    ld    a, b               ;; [1]  A = B = Color value (0-3)
    ld    b, e               ;; [1]  B = Cleaned background pixels preserved
    add   a, a               ;; [1]  Color * 2
    add   a, a               ;; [1]  Color * 4
    or    c                  ;; [1]  A = (Color * 4) + Pixel index
    ld    e, a               ;; [1]  E = Final color table offset
    ld    hl, #cpct_plotColorTable_M1 ;; [3]  HL = Base address of color table
    add   hl, de             ;; [3]  HL = &color_table[offset]
    ld    a, (hl)            ;; [2]  A = Mode 1 interlaced color bit

    or    b                  ;; [1]  Merge new color bits into background
    pop   hl                 ;; [3]  Restore screen byte pointer
    ld    (hl), a            ;; [2]  Write finalized byte back into VRAM

err_2_compute:
    ld__b_ixh               ;; [2] BC = IX = err
    ld__c_ixl               ;; [2] |
    ld    h, b              ;; [1] DE = e2 = 2 * err
    ld    l, c              ;; [1] |
    add   hl, hl            ;; [3] |
    ex    de, hl            ;; [1] | DE = E2

x_move:
dy=.+1
    ld    hl, #0000         ;; [3] HL = -DY        
    ex    de, hl            ;; [1] HL (E2) / DE (-DY)

    ld    a, h              ;; [1] Flip sign bit of H to shift range to unsigned
    xor   #0x80             ;; [2] |
    ld    h, a              ;; [1] |
    
    ld    b, d              ;; [1] B = D to keep
    ld    a, d              ;; [1] Flip sign bit of D to shift range to unsigned        
    xor   #0x80             ;; [2] |    
    ld    d, a              ;; [1] |

    or    a                 ;; [1] Clear Carry flag
    sbc   hl, de            ;; [3] Subtract DE from HL for comparison
    add   hl, de            ;; [3] Add DE to HL for restore value
    
    pop   iy                ;; [4] Restore IY = X0
    jr    c, y_move         ;; [2/3] IF (e2  < -dy) THEN y_move
    jr    z, y_move         ;; [2/3] IF (e2 == -dy) THEN y_move
        
    ld    d, b              ;; [1] D = B to get
    add   ix, de            ;; [4] IX (ERR) = IX (ERR) - DE (DY)

;; IY = X0 += SX
add_sx:
sx=.+1
    ld    bc, #0000         ;; [3] BC = SX
    add   iy, bc            ;; [4] IY (X0) = IY (X0) + BC (SX)

y_move::
dx=.+1
    ld    de, #0000         ;; [3] BC = DE = DX
    ld    b, d              ;; [1] |
    ld    c, e              ;; [1] |
    
    ld    a, d              ;; [1] Flip sign bit of H to shift range to unsigned        
    xor   #0x80             ;; [2] |
    ld    d, a              ;; [1] |

    or    a                 ;; [1] Clear carry flag
    sbc   hl, de            ;; [3] IF (E2 (HL) >= DX (DE))
    pop   hl                ;; [3] Restore HL = Y0   
    jp    p, last_pixel     ;; [2/3] IF (e2 >= dx) then test last pixel
        
    ;; ERR += DX
    add  ix, bc             ;; [4] IX (ERR) = IX (ERR) + BC (DX)

;; HL = Y0 += SY
add_sy:    
sy=.+1
    ld   de, #0000          ;; [2] DE = SY
    add  hl, de             ;; [3] HL (Y0) = HL (Y0) + DE (SX)
    
;; Test if last pixel
last_pixel:
     ex   de, hl            ;; [1] DE = Y0
pixel_num = .+1
    ld    hl, #0000         ;; [3] HL = remaining pixels count
    dec   hl                ;; [2] Decrement pixel counter
    ld   (pixel_num), hl    ;; [5] Update pixel counter
    ld    a, h              ;; [1] Check if HL == 0
    or    l                 ;; [1] |
    
    ;; Restore HL = X0
    ld__b_iyh               ;; [2] BC = IY = X0
    ld__c_iyl               ;; [2] |
    ld   h, b               ;; [1] HL = BC = X0
    ld   l, c               ;; [1] |

    jp    nz, loop_line_pixel ;; [3] IF (pixels left > 0) THEN loop_line_pixel

end_draw_line:
    ;; Return in binding
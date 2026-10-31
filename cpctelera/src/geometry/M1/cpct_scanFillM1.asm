;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;;
;; Function: cpct_scanFillM1
;;
;;    Fills an area defined by a point and its actual color with a new color in Mode 1 (320x200, 4 colors)
;;
;; C Definition:
;;    void cpct_scanFillM1 (u8* vmem, u16 x, u8 y, u8 newColor) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B HL)  vmem       - Base VRAM memory address (typically 0xC000)
;;    (2B DE)  x          -  X coordinate (0-319 no checks)
;;    (1B  C)  y          -  Y coordinate (0-199 no checks)
;;    (1B  B)  newColor   -  New color to use (0-3)
;;
;; Assembly call:
;;    > call cpct_scanFillM1_asm
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Algorithm & Details:
;;    Scanline Fill, starting from a point, it fills the area with the color specified.
;;    It will stop when it finds a pixel with a different color than the one found initialy
;;
;;    Init algo: 
;;       get screen adress from X,Y, compute X Offset and subpixel, get old color on X,Y
;;       Compute new and old_color subpixels and full octet, exit if new color == old color
;;       Push X Offset, subpixel and Y in point stack 
;;    Main loop:
;;        pop a point from stack - Exit is stack was empty (no more things to do)
;;        drawOnLeft to find left most pixel which is still old_color, try to use full_octet if possible. Stop at begining of screen if needed.
;;        drawOnRight to find right most pixel which is still old_color, try to use full_octet if possible. Stop at end of screen if needed.
;;        get left side of line on above line (decreasing Y)   (do it again after with below line (increase y)
;;        initSubLoop
;;             set a search flag to 'search old_color'
;;        subLoop
;;             if searchFlag is 'search Old Color'
;;                check if pixel is old color
;;                if yes
;;                   pushcurrent  point into stack and set search flag to 'search not old color'
;;             else  (search for 'not old color')
;;                check if pixel is old color
;;                if not
;;                   set search flag to 'search old color'
;;             endif
;;             move to next pixel on the right, check if right end of previous drawnn line reached to exit subLoop
;;             try to jump over full octets
;;                old color if 'not old color' (will slow back to pixel checks if not found)
;;                new_color if 'old_color'  (only case we have values ready, else switch back to pixel check)
;;                fall back to pixel checking in doubt, exit subLoop if right end of drawn line is reached or passed
;;
;;    Comment on stack size:
;;       A memory buffer is set to store next points to check above and below vurrent line.
;;       By default this is a 30 points storage using 3 Bytes each, 90 Bytes.
;;       If area to fill has a lot of different vertical area to fill
;;       the algorithm will need all this area. The algorithm stops adding points if 
;;       buffer is filled. So some area will not be checked and some area may miss in result.
;;       A simple rectangular area just need 2 points.
;;       If you know how many elements in stacks you need, you can adjust 
;;       the STACK_SIZE value to your need and recompile cpctelera to decrease memory need.
;;
;; (start code)
;; Required memory:
;;    602 bytes core routine (including 3 bytes of c binding) + 115 bytes data
;;
;; Test measure: 
;;    Screen set to color 0
;;    4 points:
;;       pt1 (100,100) pt2 (125,75) pt3 (150,100) pt4 (125,125)
;;    4 lines of color 2 between:
;;       pt1,pt2  pt2,pt3 pt3,pt4 pt4,pt1
;;    Time to fill from pt (125,100) with color 3
;;
;;  Totals and assumptions
;;    Pixels drawn: 1,201
;;    Estimated drawing work: about 28,300 NOPs
;;    Estimated above/below checks and point-queue costs: about 51,400 NOPs
;;  Estimated overall: 
;;    about 80,000 NOPs, including roughly 30 NOPs for the initial screen-pointer helper and the documented 10-NOP C-binding overhead; allow a few hundred more for setup.
;;
;; (end code)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globl cpct_plotColorTable_M1
.globl cpct_plotMasksTable_M1
.globl cpct_getScreenPtr_asm

;; Special values 
STACK_SIZE = 30                  ;; Max number of elements in points stack

;;-------------------------------------------------------------------------------
;; DATA SECTION
;;-------------------------------------------------------------------------------
.area _DATA
screen_start:     .dw 0          ;; (2) Screen start from input

;; Keep cur values ordered like this for easy incremental access
;; Byte and subpixel maybe stored as a 16bit register so do not swap order
cur_byte_offset:  .db 0          ;; (1) Current byte offset
cur_subpixel:     .db 0          ;; (1) Current subpixel
cur_y_val:        .db 0          ;; (1) Current y coordinate
cur_adress:       .dw 0          ;; (2) Current screen adress

left_byte_offset: .db 0          ;; (1) Left byte offset
left_subpixel:    .db 0          ;; (1) Left subpixel
left_adress:      .dw 0          ;; (2) Left screen adress

; Flags
searchFlag:       .db 0          ;; (1) Flag to check if looking for old color or not
; Color buffers
new_color:        .ds 4          ;; (4) new color values for sub pixel 0..3
new_color_full:   .db 0          ;; (1) new color full octet for quick checks of octet
old_color:        .ds 4          ;; (4) old color values for sub pixel 0..3
old_color_full:   .db 0          ;; (1) old color full octet for quick fill of octet
; Stack
stack_idx:        .db 0          ;; (1) Stack index
stack_adress:     .dw pt_stack   ;; (2) Current Stack Adress to use
pt_stack:                        ;; Stack of points to fill horizontaly
   .rept STACK_SIZE              ;; Allocate a fixed size stack of points 
      .db 0                      ;; (30) X Octet from left (0..79)
      .db 0                      ;; (30) Sub pixel offset  (0..3)
      .db 0                      ;; (30) Y coordinates from top (0..199)
   .endm

;;-------------------------------------------------------------------------------
;; CODE SECTION
;;-------------------------------------------------------------------------------
.area _CODE

   ;  HL = VMEM start ptr
   ;  DE = X
   ;  C  = Y
   ;  B  = New Color 

   ld    (screen_start),hl       ;; [5] Store VMem start
   ld    a,c                     ;; [1] A = Y coord
   ld    (cur_y_val),a           ;; [4] Store Y value

   ;; Compute new color values for sub pixel 0..3
   ;; compute sub pixel 0
   xor   a                       ;; [1] A = 0
   rr    b                       ;; [2] B = New Color >> 1 , Carry = low bit of New Color
   rra                           ;; [1] Bit 7 of A = Low bit of New_color
   sla   b                       ;; [2] B = High bit of new color in bit 1
   sla   b                       ;; [2] B = High bit of new color in bit 2
   sla   b                       ;; [2] B = High bit of new color in bit 3
   or    b                       ;; [1] A = New Color for sub pixel 0
   ld    hl,#new_color           ;; [3] HL = new_color table / A = new color for sub pixel 0
   call  storeColor              ;; [5] Store old color values for sub pixel 0..3 and a = full octet

   ;; Compute Screen adress and sub pixel offset from X,Y
   ld    a,e                     ;; [1] A = low byte X
   and   #3                      ;; [2] A = Sub Pixel offset
   ld    (cur_subpixel),a        ;; [4] Store current subpixel
   srl   d                       ;; [2] d can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
   rr    e                       ;; [2] rotate e once with carry from d
   srl   e                       ;; [2] Now e is the byte offset in the line (0-79)
   ld    a,e                     ;; [1] A = current byte offset
   ld    (cur_byte_offset),a     ;; [4] Store current byte offset
   ld    b, c                    ;; [1] b = Y
   ld    c, e                    ;; [1] c = X in bytes
   ld    de,(screen_start)       ;; [6] de = VMEM_START_ADRESS
   call  cpct_getScreenPtr_asm   ;; [5] HL = Current adress

   ;; Get old color from adress HL and sub pixel offset
   ld    a,(cur_subpixel)        ;; [4] A = Subpixel
   ld    d,a                     ;; [1] put back subpixel in d
   ld    (l_tableOffset),a       ;; [4] SMC: Change jmp indexation with sub pixel offset
   ld    e,(hl)                  ;; [2] Get current screen octet
   ld    hl,#cpct_plotColorTable_M1+15 ;; [3] Points to individual pixel table from right subpixel
l_tableOffset=.+1
   jr    l_maxjr                 ;; [3] jumps over necessary dec to points correct hl
   dec   hl                      ;; [2] get adress of subpixel 0
   dec   hl                      ;; [2] get adress of subpixel 1
   dec   hl                      ;; [2] get adress of subpixel 2
l_maxjr:
   ld    a,(hl)                  ;; [2] get mask for the pixel
   and   e                       ;; [1] masked pixel of screen octet
   ld    b,d                     ;; [1] b = sub pixel offset
   inc   b                       ;; [1] b = subPixel offset + 1 (1..4)
   rrca                          ;; [1] Rotate right for first djnz
loop_getOldColor:
   rlca                          ;; [1] Rotate until a = subpixel 0 of old color
   djnz  loop_getOldColor        ;; [3/4] Loop on B

   ld    hl,#old_color           ;; [3] HL = old_color table  / A = old color for sub pixel 0
   call  storeColor              ;; [5] Store old color values and a = full octet old color
   ld    hl,#new_color_full      ;; [3]
   cp    (hl)                    ;; [2] Check if old_color == new_color
   ret   z                       ;; [2/4] If equal old_color==new_color, end : nothing to replace
initALgo:
   ;; Init Stack
   xor   a                       ;; [1] A = 0
   ld    (stack_idx),a           ;; [4] Stack index = 0
   ld    a,<#pt_stack            ;; [2] A = low byte of Stack Adress
   ld    (stack_adress),a        ;; [4] Init low Stack Adress
   ld    a,>#pt_stack            ;; [2] A = high byte of Stack Adress
   ld    (stack_adress+1),a      ;; [4] Init high Stack Adress

   ld    de,(cur_byte_offset)    ;; [6] Retrieve current values for init
   ld    a,(cur_y_val)           ;; [4] Retrieve Y value
   ld    c,a                     ;; [1] c = y val

   call  pushPoint               ;; [5] Push current point DE, C into stack

   ;; During loop, D = subpixel, E = X-octet, C = Y, HL = compute adress based on E/C
mainLoop:
   call  popPoint                ;; [5] Pop next point from stack into DE, C
   ret    z                      ;; [2/4] If stack is empty, algo is finished

   call  computeAdress           ;; [5] Retrieve HL adress based on E,C (untouched)
   ld    a,c                     ;; [1] a = y value
   ld    (cur_adress),hl         ;; [5] Save cur adress
   ld    (cur_byte_offset),de    ;; [6] and byte offset / subpixel
   ld    (cur_y_val),a           ;; [4] and Y value

   call  checkOldColor           ;; [5] If point is no more old color, we have already turned around this point and fill it
   jr    nz,mainLoop             ;; [2/3] Skip it

	ld    a,(new_color_full)  	   ;; [4] A = new_color full
   ld    b,a                     ;; [1] b = full octet new color

   call  searchAndDrawLeft       ;; [5] Find first left pixel which is not an old color

   ld    (left_adress),hl        ;; [5] Store last old color left adress
   ld    (left_byte_offset),de   ;; [6] Store last old color Left byte and subpixel

   ld    hl, (cur_adress)        ;; [5] Retrieve starting values
   ld    de, (cur_byte_offset)   ;; [6] "       "      "
   call  searchAndDrawRight      ;; [5] Find first right pixel which is not an old color

   ld    (cur_adress),hl         ;; [5] Store last right adress for above and below boundaries checks
   ld    (cur_byte_offset),de    ;; [6] Store last right byte and subpixel
ml_searchNewPoints:              ;; Check lines above and below for new points

   ld    hl, (left_adress)       ;; [5] Retrieve left values
   ld    de, (left_byte_offset)  ;; [6]

   ;; Move along upper line to check if new points should be stacked
   call  changeYUp               ;; [5] Compute a new HL and C, z if top of screen reached
   jr    z,checkBelow            ;; [2/3] Cannot move up, check other line
   call  searchNewPoints         ;; [5] Push new points inside stack if old_color found above drawn line
checkBelow:
   ld    hl, (left_adress)       ;; [5] Retrieve left values
   ld    de, (left_byte_offset)  ;; [6]
   call  changeYDown             ;; [5] Compute a new HL and C
   call  changeYDown             ;; [5] Compute a new HL and C, z if top of screen reached
   jr    z,continue              ;; [2/3] Cannot move up, check other line
   call  searchNewPoints         ;; [5] Push new points inside stack if old_color found above drawn line
continue:
   jr    mainLoop                ;; [3] Check new point in stack

searchAndDrawLeft:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Move HL / DE / B until a pixel which is not old_color or left of screen
;; First pixel is set here
sdl_loopSubpixel:
   call  plotPixel               ;; [5] set new color of d subpixel at HL, first pixel is drawn here
   call  decreaseSubpixel        ;; [5] move cur pixel to the left
   ret   z                       ;; [2/4] if ZFLag, we have reach left screen boundary

   ld    a,d                     ;; [1] a = subpixel
   cp    #0x03                   ;; [2] check if right subpixel (so we reached a new octet)
   jr    nz, sdl_checkSubpixel   ;; [2/3] No ?  Let's check individual subpixel

   ld    a,(new_color_full)      ;; [4] a = new color full octet
   ld    b,a                     ;; [1] c = new color full octet
   ld    a,(old_color_full)      ;; [4] a = old color full octet
sdl_loopFullOctet:
   cp    (hl)                    ;; [2] check with screen octet
   jr    nz,sdl_checkSubpixel    ;; [2/3] if not full octet let's do it one subpixel by one subpixel
   ld    (hl),b                  ;; [2] Set full octet to new color
   dec   hl                      ;; [2] decrease adress
   dec   e                       ;; [1] decrease X OCtet
   jp    p, sdl_loopFullOctet    ;; [3] if positif or 0 loop
   ld    d,#0                    ;; [2] d = left subpixel
   inc   hl                      ;; [2] move back to last adress
   inc   e                       ;; [1] set e = 0, so ZFlag is set
   ret                           ;; [3] ret with ZFlag set
sdl_checkSubpixel:
   call  checkOldColor           ;; [5] is subpixel of old color
   jr    z,sdl_loopSubpixel      ;; [2/3] if old color draw it and continue

   call  increaseSubpixel        ;; [5] if not, last subpixel was the last one
   ret                           ;; [3] return

searchAndDrawRight:              ;; Move HL / DE until a pixel which is not old_color or Right of screen - b = full octet new_color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Move and draw HL / DE  until a pixel which is not old_color or right of screen
;; First pixel is skipped here (because leftDraw has already done it)
sdr_loopSubpixel:
   call  increaseSubpixel        ;; [5] Move to subpixel on right
   ret   z                       ;; [2/4] if ZFLag, we have reach right screen boundary

   ld    a,d                     ;; [1] a = subpixel
   or    a                       ;; [1] check if left subpixel (so we reached a new octet)
   jr    nz, sdr_checkSubpixel   ;; [2/3] No ?  Let's print it and move to another one

   ld    a,(new_color_full)      ;; [4] a = new color full octet
   ld    b,a                     ;; [1] c = new color full octet
sdr_loopFullOctet:
   ld    a,(old_color_full)      ;; [4] a = old color full octet
   cp    (hl)                    ;; [2] check with screen octet
   jr    nz,sdr_checkSubpixel    ;; [2/3] if not full octet let's do it one subpixel by one subpixel
   ld    (hl),b                  ;; [2] Set full octet to new color
   ld    a,e                     ;; [1] a = X OCtet
   cp    #screenNbOctet          ;; [2] Compare with screen size (79)
   jr    z,sdr_lastOctet         ;; [2/3] we reached end of line
   inc   hl                      ;; [2] if not move to next adress
   inc   e                       ;; [1] e = X + 1
   jp    sdr_loopFullOctet       ;; [3] loop
sdr_lastOctet:
   ld    d,#0x03                 ;; [2] set subpixel to right one
   ret                           ;; [3] ZFlag is still set here
sdr_checkSubpixel:
   call  checkOldColor           ;; [5] is subpixel of old color
   jr    nz,sdr_lastSubpixel     ;; [2/3] if old color draw it and continue
   call  plotPixel               ;; [5] chenge color of subpixel
   jr    sdr_loopSubpixel        ;; [3] continue
sdr_lastSubpixel:
   call  decreaseSubpixel        ;; [5] if not, last subpixel was the last one
	ret                           ;; [3] return
searchNewPoints:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; check and push points which are old_color (wait for end of old_color to add another one found)
;; and move to the right until end of previously draw Line 
   ;; Init
   xor   a                       ;; [1] a = 0
   ld    (searchFlag),a          ;; [4] reset search flag insertion - looking For old_color (jump over full new color)

   ;; Alternate between searching old_color and jumping above old_color on current line
   ;; Stops when end of right drawn line reached
snp_mainLoop:
   ld    a,(searchFlag)          ;; [4] get current searchFlag
   or    a                       ;; [1] check == 0
   jr    nz,snp_searchEndOC      ;; [2/3] if !=0 we are looking for end of old_color

;; searching for old_color pixels
   call  checkOldColor           ;; [5] Do we have an old_color here?
   jr    nz,snp_nextSearchSP     ;; [2/3] no, move to next subpixel
   
   call  pushPoint               ;; [5] We have a hit, push it on stack and switch flag
   or    a,#0x01                 ;; [2] a != 0
   ld    (searchFlag),a          ;; [4] flag != 0 means, search for first pixel which is not old_color (jump over old_color)
   jr    snp_nextSearchSP        ;; [3] move to next subpixel
snp_searchEndOC:
   call  checkOldColor           ;; [5] search for another color in pixel
   jr    z,snp_nextSearchSP      ;; [2/3] Still old color, wait for another color
   xor   a                       ;; [1] set a = 0
   ld    (searchFlag),a          ;; [4] Reset flag : search for old color again
                                 ;; continue to next subpixel
snp_nextSearchSP:
   call  increaseSubpixel        ;; [5] move to right one subpixel
   ret   z                       ;; [2/4] stop if already at end of screen
   call  checkEndOfDrawnLine     ;; [5] Check if end of draw line
   ret   z                       ;; [2/4] stop if increase has gone after drawn line
   ld    a,d                     ;; [1] a = subpixel
   or    a                       ;; [1] check a == 0
   jr    nz, snp_mainLoop        ;; [2/3] Not starting a new octet, let's loop on sub pixels

   ld    a,(searchFlag)          ;; [4] check the searchFlag to set correct full_octet to test
   or    a                       ;; [1] 
   jr    z,snp_useNewColor       ;; [2/3] if searching for old_color , we can skip new_color_full octets

   ld    a,(old_color_full)      ;; [4] a = old color full octet
   jr snp_setColorToJump         ;; [3] continue with this color
snp_useNewColor:
   ld    a,(new_color_full)      ;; [4] a = new color full octet
snp_setColorToJump:
   ld    b,a                     ;; [1] b = color full octet to skip
snp_loopFullOctet:
   ld    a,(cur_byte_offset)     ;; [4] a = right X Offset
   cp    e                       ;; [1] compare with current X Offset
   ret   c                       ;; [2/4] We move above last pixel (e > a), ret from there

   ld    a,b                     ;; [1] a = color full octet to skip
   cp    (hl)                    ;; [2] compare with screen octet
   jr    nz,snp_mainLoop         ;; [2/3] not equal so we need to check pixels
   inc   e                       ;; [1] increase X ofsset  (keep d = 0 left subpixel)
   inc   hl                      ;; [2] inc screen adress
   jr    snp_loopFullOctet       ;; [3] loop on full octets

checkEndOfDrawnLine:             ;; Return ZFlag when last pixel is passed (still no ZFlag on last subpixel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,(cur_byte_offset)     ;; [4] A = right X Offset
   cp    e                       ;; [1] compare actual X Offset with right X Offset
   ret   c                       ;; [2/4] if e > cur X, not on last octet
   jr    nz,cel_resetZFlag       ;; [2/3] if e < cur X, line is overpassed
   ld    a,(cur_subpixel)        ;; [4] here e == cur X so check subpixel, A = righ subpixel
   cp    d                       ;; [1] compare with actual subpixel, d must be > a to fire ZFlag
   jr    nc,cel_resetZFlag       ;; [2/3] d <= a , no flag
   xor   a                       ;; [1] force ZFLag ON
   ret   nc                      ;; [2/4] if d <= cur subPixel, ZFlag is set appropiately with comparison
                                 ;; if d> cur subpixel need to set ZFlag
cel_resetZFlag:   
   or   #0x01                    ;; [2] force ZFlag to OFF
   ret                           ;; [3]

plotPixel:                       ;; Plot pixel D at (hl) in new_color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   push  de                      ;; [4] Preserve DE
   push  hl                      ;; [4] Preserve HL = screen adress
   ld    e,d                     ;; [1] e = subpixel
   ld    d,#0                    ;; [2] de = subpixel offset 16 bits
   ld    hl,#cpct_plotMasksTable_M1 ;; [3] hl = masktable
   add   hl,de                   ;; [3] hl = masktable + subpixel offset
   ld    a,(hl)                  ;; [2] a = subpixel mask
   ld    hl,#new_color           ;; [3] de = new color table
   add   hl,de                   ;; [3] hl = new color table + subpixel offset
   ld    e,(hl)                  ;; [2] e = new_color subpixel
   pop   hl                      ;; [3] retrieve screen adress
   and   (hl)                    ;; [2] a = subpixel reset of screen octet
   or    e                       ;; [1] a = merge reset screen octet with new_color subpixel
   ld    (hl),a                  ;; [2] Set screen octet
   pop   de                      ;; [3] Retrieve DE
   ret                           ;; [3] return
computeAdress:                   ;; Compute HL = VMemStart + c mod 7 * &800 + 80 * (c % 7) + E  - From cpct_getScreenPtr_asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   push  bc                      ;; [4] Preserve BC
   ld    a, c                    ;; [1] rA = Y-Coordinate
   and   #0x07                   ;; [2] /
   ld    h, a                    ;; [1] \ rH = Y % 8      ;; << rH contains Line number [0-7] inside character Row
   xor   c                       ;; [1] / rA = ( rB and #0x07 ) xor rB  =  rB and #0xF8
   ld    l, a                    ;; [1] \ rL = 8*int(Y/8) ;; << L contains Screen Character Row multiplied by 8
   rrca                          ;; [1] /
   rrca                          ;; [1] \ rA' = rA / 4 = 2*int(Y/8)
   add   a, l                    ;; [1] /
   ld    l, a                    ;; [1] \ rL = rL + rA' = 8*int(Y/8) + 2*int(Y/8) = 10*int(Y/8)
   add   hl, hl                  ;; [3] /
   add   hl, hl                  ;; [3] |
   add   hl, hl                  ;; [3] \ rHL' = 8*rHL = 2048*L + 80*R
   ld    b,#0                    ;; [2] Reset b
   ld    c,e                     ;; [1] c = byte offset
   add   hl, bc                  ;; [3] rHL' = rHL + x octet
   ld    bc,(screen_start)       ;; [6] BC = VMEM start
   add   hl, bc                  ;; [3] rHL' = rHL + screen_start
   pop   bc                      ;; [3] retrieve BC
   ret                           ;; [3] return

checkOldColor:                   ;; Returns ZFlag ON if color of the pixel at (HL),D is an old_color
   ld    b,(hl)                  ;; [2] b = screen octet
   ld    a,(old_color_full)      ;; [4] A = full octet old color
   xor   b                       ;; [1] check if A == B
   ret   z                       ;; [2/4] If full octet is old_color ret ZFlag
   push  hl                      ;; [4] save screen adress
   push  de                      ;; [4] save de
   ld    e,d                     ;; [1] e = subpixel
   ld    d,#0                    ;; [2] de = subpixel 16 bit
   ld    hl,#cpct_plotColorTable_M1+12 ;; [3] Point to pixel table
   add   hl,de                   ;; [3] hl = subpixel mask adress in pixel table
   ld    a,(hl)                  ;; [2] get mask for the subpixel
   and   b                       ;; [1] a = get the subpixel value of screen octet
   ld    hl,#old_color           ;; [3] hl = old color table
   add   hl,de                   ;; [3] hl = old color subpixel adress
   xor   (hl)                    ;; [2] a = actual subpixel xor oldcolor pixel- ZFlag is set if A == (HL)
   pop   de                      ;; [3] retrieve de
   pop   hl                      ;; [3] retrieve screen adress
   ret                           ;; [3] Z Flag is true if color found in pixel

pushPoint:                       ;; Push point DE and C into stack - FZ not set : OK - FZ set : no more room
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,(stack_idx)           ;; [4] Get current stack index
   cp    #STACK_SIZE             ;; [2] Check if stack is full
   ret   z                       ;; [2/4] Return if full

   inc   a                       ;; [1] a = stack_idx + 1
   ld    (stack_idx),a           ;; [4] store stack_idx

   push  hl                      ;; [4] preserve hl
   ld    hl,(stack_adress)       ;; [5] HL = Stack Adress

   ld    (hl),e                  ;; [2] Save X byte offset
   inc   hl                      ;; [2] Move down
   ld    (hl),d                  ;; [2] Save subpixel
   inc   hl                      ;; [2] Move down
   ld    (hl),c                  ;; [2] Save Y Coordinates
   inc   hl                      ;; [2] Move down
   ld    (stack_adress),hl       ;; [5] Save new stack address
   pop   hl                      ;; [3] retrieve hl
   ret                           ;; [3] Going back

popPoint:                        ;; Pop point into DE and C from stack - No need to preserve HL (recomputed) - FZ not set : OK - FZ set : empty stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,(stack_idx)           ;; [4] Get current stack index
   or    a                       ;; [1] Check if stack is empty
   ret   z                       ;; [2/4] If not empty, continue

   dec   a                       ;; [1] a = stck_idx - 1
   ld    (stack_idx),a           ;; [4] store stack_idx

   ld    hl,(stack_adress)       ;; [5] Points to last stack adress - no need to preserve, will be recomputed
   dec   hl                      ;; [2] Move up
   ld    c,(hl)                  ;; [2] Get Y coordinates
   dec   hl                      ;; [2] Move up
   ld    d,(hl)                  ;; [2] Get subpixel
   dec   hl                      ;; [2] Move up
   ld    e,(hl)                  ;; [2] Get X byte offset
   ld    (stack_adress),hl       ;; [5] Save new stack address
   or    #0x01                   ;; [2] reset Z flag
   ret                           ;; [3] return

storeColor:                      ;; Store color subpixels into HL - a = color of subpixel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    b,a                     ;; [1] b = color for sub pixel 0
   ld   (hl),b                   ;; [2] Save color for sub pixel 0
   inc   hl                      ;; [2] next octet
   rrc   b                       ;; [2] Rotate B right to get color for sub pixel 1
   or    b                       ;; [1] A = A + color for sub pixel 1
   ld   (hl),b                   ;; [2] Save color for sub pixel 1
   inc   hl                      ;; [2] next octet
   rrc   b                       ;; [2] Rotate B right to get color for sub pixel 2
   or    b                       ;; [1] A = A + color for sub pixel 2
   ld   (hl),b                   ;; [2] Save color for sub pixel 2
   inc   hl                      ;; [2] next octet
   rrc   b                       ;; [2] Rotate B right to get color for sub pixel 3
   or    b                       ;; [1] A = A + color for sub pixel 3
   ld   (hl),b                   ;; [2] Save color for sub pixel 3
   inc   hl                      ;; [2] next octet (Full_octet)
   ld   (hl),a                   ;; [2] Save color full octet
   ret                           ;; [3] return and A contains full octet color

changeYUp:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,c                     ;; [1] a = c = Y value
   or    a                       ;; [1] Check if 0
   ret   z                       ;; [2/4] Top of screen reached, return ZFlag ON
   dec   c                       ;; [1] c = Y - 1
   call  computeAdress           ;; [5] Compute new adress
   or    #0x01                   ;; [2] make sure ZFlag is OFF because of previous call
   ret                           ;; [3] return

changeYDown:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,c                     ;; [1] a = c = Y value
   cp    #YMax                   ;; [2] Compare with max screen height
   ret   z                       ;; [2/4] Top of screen reached, return ZFlag ON
   inc   c                       ;; [1] c = Y + 1
   call  computeAdress           ;; [5] Compute new adress
   or    #0x01                   ;; [2] make sure ZFlag is OFF because of previous call
   ret                           ;; [3] return

decreaseSubpixel:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,d                     ;; [1] a = subpixel
   or    a                       ;; [1] check a == 0
   jr    z,dsp_changeXOffset     ;; [2/3] Subpixel == 0, move to previous octet
   dec   d                       ;; [1] decrease subpixel
   or    a                       ;; [1] To reset Z Flag if d == 0
   ret                           ;; [3] return
dsp_changeXOffset:
   ld    a,e                     ;; [1] a = X octet in line
   or    a                       ;; [1] Check a == 0
   ret   z                       ;; [2/4] Z flag is set : cannot move before sub pixel 0 of X-Offset 0
   ld    d,#0x03                 ;; [2] d = last subpixel
   dec   hl                      ;; [2] decrease screen adress
   dec   e                       ;; [1] decrease X Octet
   or    a                       ;; [1] to reset ZFlag if e = 0
   ret                           ;; [3] return

increaseSubpixel:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ld    a,#0x03                 ;; [2] a = 3
   cp    d                       ;; [1] Compare subpixel with 3
   jr    z,isp_changeXOffset     ;; [2/3] subpixel == 3, move to next octet
   inc   d                       ;; [1] increase subpixel (ZFlag cannot be set)
   ret                           ;; [3] return
isp_changeXOffset:
   ld    a,e                     ;; [1] a = X Octet in line
   cp    #screenNbOctet          ;; [2] compare with end of line
   ret   z                       ;; [2/4] Z flag is set : cannot move after sub pixel 3 of last X-Offset
   ld    d,#0x00                 ;; [2] d = left subpixel
   inc   hl                      ;; [2] increase screen adress
   inc   e                       ;; [1] increase X (ZFlag cannot be set)
   ret                           ;; [3] return
    ;; Ok let's start drawing the line now, we have all the information we need
    ; Here HL = Left pixel adress
    ;      B  = left subpixel
    ;      C  = right subpixel
    ;      E  = Nb OCtet difference between right and left (positif) so from 0 to 79
    ;      A  = INK Color

    ;; Memory needed
    ;;     264 bytes
    ;;
    ;; Timing of draw
    ;;
    ;;     X0 and X1 on same octet
    ;;     X1-X0 = 1 
    ;;     X0=0 X1=319 
    ;;     Left subpixel != 0 and full o34 Microseonds   79 Bytes

    ;  Computing full 4 pixels with INK inside d
    ld  d,#0                    ;; d will contain the full octet color to use
    rra                         ;; Put bit0 of INK in Carry
    jr  nc,testHightBitColor
    ld  d,#0xF0                 ;; d = full pixel of INK 1
testHightBitColor:    
    rra                         ;; put bit 1 of INK in carry
    jr  nc,noHightBitColor
    ld  a,#0x0F                 ;; a = full pixel of INK 2  
    or  d                       ;; merge on d
    ld  d,a                      
noHightBitColor:
                                ;; d = full pixel octet color of ink

    ld  a,e                     ;; a = nbOctet
    or  a                       ;; check if nbOct == 0 ==> B and C on same octet
    jr  nz,notSameOctet         ;; Ok, let's do the full process

    ; Specific case : Draw from B to C subPixels inside same octet
    push hl                     ;; Keep adress

    ld  a,b                     ;; a = left subpixel
    rlca                        ;; multiply by 4
    rlca                        ;;  "
    add c                       ;; a = b*4+c : index in mask table
 
    ld  hl, #cpct_subPixelHorizontalMask_M1  ;; mask table
    ld  b,#0     
    ld  c,a                     ;; bc = index in table
    add hl,bc                   ;; hl = adress of mask to use
    ld  a,(hl)                  ;; a = mask to use for reset pixels with new color

    pop hl                      ;; Restore adress

    ld  e,a                     ;; save mask
    and (hl)                    ;; a = current screen pixels with clear pixels from mask 

    ld  b,a                     ;; b = current screen octet (cleared)
    ld  a,e                     ;; retrieve mask
    cpl                         ;; invert mask
    and d                       ;; set requested color to inverted pixels

    or  b                       ;; merge result with current screen octet
    ld  d,a                     ;; use d as new color for next instruction to run

    jp  drawLastOctet           ;; Move to last draw

notSameOctet:
    ; deal with starting subpixel
    ld  a,b                 ;; a = left subpixel
    or  a                   ;; if 0 we can do full pixels, if not we need to mask and move forward 1
    jr  z,drawFullOctets    ;; We can draw octets from there, but we will need to check last octet

    ; Deal from b subpixel to 3 on actual adress, a = left subpixel
    rlca                    ;; multiply by 4
    rlca                    ;;  "

    push hl                 ;; Save Adress
    push de                 ;; Save d = color and e = nbOctet

    ld  hl, #cpct_subPixelHorizontalMask_M1 + 3  ;; mask table with right subPixel = 3
    ld  d,#0                ;;     
    ld  e,a                 ;; de = index in table
    add hl,de               ;; hl = adress of mask to use
    ld  a,(hl)              ;; a = mask to use for reset pixels with new color

    ld  d,a                 ;; save mask
    and (hl)                ;; a = current screen pixels with clear pixels from mask 

    ld  b,a                 ;; b = current screen octet (cleared)
    ld  a,d                 ;; retrieve mask
    cpl                     ;; invert mask

    pop de                  ;; Restore color and nbOctet
    pop hl                  ;; Restore adress

    and d                   ;; set requested color to inverted pixels
    or  b                   ;; merge result with current screen octet

    ld  (hl),a              ;; Set screen octet with preserved pixels around b and c

    inc hl                  ;; We have finished this first octet, increase adress
    dec e                   ;; and decrease nbOctet

drawFullOctets:
    ;; We will now draw needed octets with full octets 
    ;; based on e = nbOctet using a jump table
    ;; e can be 0 so in this case we will jump over everything
    ld  a,#79               ;; a = max jump
    sub e                   ;; a = 79 - nbOctect (so from 0 max lines to 79)
                            ;; jr 0 will use full table
    rla                     ;; a = a * 2 because ld (hl),d inc hl
    ld  (#drawJrOffset),a   ;; SMC to use the correct amount of ld (hl),d inc hl
drawJrOffset=. + 1
    jr  #0          ;; SMC to jump over necessary code - Max code is 79 * 2 so JR works
.rept 79
    ld  (hl),d      ;; Set screen octet with full color
    inc hl          ;; Increase adress
.endm


onLeftSubpixel:
    ; We are on the last octet, deal with C subPixels from left on last adress
    ld  a,c             ;; a = right subpixel    
    cp  #3              ;; if 3 we can do full byte, if not we need to mask
    jr  z,drawLastOctet ;; go for it

    push hl             ;; Save Adress
    ld  hl, #cpct_subPixelHorizontalMask_M1 + 3  ;; mask table with right subPixel = 3
    ld  b,#0     
    ld  c,a             ;; bc = index in table
    add hl,bc           ;; hl = adress of mask to use
    ld  a,(hl)          ;; a = mask to use for reset pixels with new color

    pop hl              ;; Restore adress

    ld  e,a             ;; save mask
    and (hl)            ;; a = current screen pixels with clear pixels from mask 

    ld  b,a             ;; b = current screen octet (cleared)
    ld  a,e             ;; retrieve mask
    cpl                 ;; invert mask
    and d               ;; set requested color to inverted pixels

    or  b               ;; merge result with current screen octet
    ld  d,a             ;; use d as new color for next instruction to run 

drawLastOctet:      
    ld  (hl),d          ;; Computed color in last byte

endDraw:
    ret

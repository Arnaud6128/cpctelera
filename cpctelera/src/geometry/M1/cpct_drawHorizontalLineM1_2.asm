    ;; Ok let's start drawing the line now, we have all the information we need
    ; Here HL = Left pixel adress (leftAdress)
    ;      B  = left subpixel
    ;      C  = right subpixel
    ;      E  = Nb OCtet difference between X1 (right) and X0 (positif) so from 0 to 79
    ;      A  = INK Color

    ;  Computing full 4 pixels with INK inside d
    ld d,#0
    rra     ; Put bit0 of INK in Carry
    jr nc,testHightBitColor
    ld d,#0xF0
testHightBitColor:    
    rra     ; put bit 1 of INK in carry
    jr nc,noHightBitColor
    ld a,#0x0F
    or d
    ld d,a
noHightBitColor:
    ; d contains full pixel color to use

    ld a,e              ; a = nbOctet
    or a                ; check if nbOct == 0 ==> B and C on same octet
    jr nz,notSameOctet  ; Ok, let's do the full process

    ; Specific case : Draw from B to C subPixels inside same octet
    ; d still needed, e nomore
    push hl     ; Keep adress

    ld a,b      ; a = left subpixel
    rlca        ; multiply by 4
    rlca        ;  "
    add c       ; a = b*4+c : index in mask table
 
    ld hl, #cpct_subPixelHorizontalMask_M1  ; mask table
    ld b,#0     
    ld c,a      ; bc = index in table
    add hl,bc   ; hl = adress of mask to use
    ld a,(hl)   ; a = mask to use for reset pixels with new color

    pop hl      ; Restore adress

    ld e,a      ; save mask
    and (hl)    ; a = current screen pixels with clear pixels from mask 

    ld b,a      ; b = current screen octet (cleared)
    ld a,e      ; retrieve mask
    cpl         ; invert mask
    and d       ; set requested color to inverted pixels

    or b        ; merge result with current screen octet

    ld (hl),a   ; Set screen octet with preserved pixels around b and c

    jp endDraw  ; we have finished
notSameOctet:
    ; deal with starting subpixel : if 0 we can do full pixels, if not we need to mask and move forward 1
    ld a,b
    or a
    jr z,drawFullOctets     ;   We can draw octets from there, but we will need to check last octet

    ; Deal from b subpixel to 3 on actual adress
    ld a,b      ; a = left subpixel
    rlca        ; multiply by 4
    rlca        ;  "
 
    push hl     ; Save Adress
    push de     ; Save color

    ld hl, #cpct_subPixelHorizontalMask_M1 + 3  ; mask table with right subPixel = 3
    ld d,#0     
    ld e,a      ; de = index in table
    add hl,de   ; hl = adress of mask to use
    ld a,(hl)   ; a = mask to use for reset pixels with new color

    ld d,a      ; save mask
    and (hl)    ; a = current screen pixels with clear pixels from mask 

    ld b,a      ; b = current screen octet (cleared)
    ld a,d      ; retrieve mask
    cpl         ; invert mask

    pop de      ; Restore color and nbOctet
    and d       ; set requested color to inverted pixels

    or b        ; merge result with current screen octet

    pop hl      ; Restore adress

    ld (hl),a   ; Set screen octet with preserved pixels around b and c


    inc hl      ; We have finished this first octet, increase adress
    dec e       ; and decrease nbOctet

drawFullOctets:
    ; We will now draw needed octets with full octets - d can be 0 so it will need to jump over everything
    ld a,#79                ; a = max jump
    sub e                   ; a = 79 - nbOctect (so from 0 max lines to 79)
    ; inc a                  ;  to avoid jr 0
    rla                     ; a = a * 2 because ld (hl),e inc hl
    ld (#drawJrOffset),a    ; SMC to use the correct amount of ld (hl),e inc hl
drawJrOffset=. + 1
    jr #0    ;   SMC to jump over necessary code - Max code is 79 * 2 so JR is enough
.rept 79
    ld (hl),d
    inc hl
.endm


onLeftSubpixel:
    ; We are on the last octet, deal with C subPixels from left on last adress
    ld a,c
    cp #3
    jr z,drawLastOctet ; Even if we are on last octet we can print it, so go for it

    push hl
    ld hl, #cpct_subPixelHorizontalMask_M1 + 3  ; mask table with right subPixel = 3
    ld b,#0     
    ld c,a      ; de = index in table
    add hl,bc   ; hl = adress of mask to use
    ld a,(hl)   ; a = mask to use for reset pixels with new color

    pop hl      ; Restore adress

    ld e,a      ; save mask
    and (hl)    ; a = current screen pixels with clear pixels from mask 

    ld b,a      ; b = current screen octet (cleared)
    ld a,e      ; retrieve mask
    cpl         ; invert mask
    and d       ; set requested color to inverted pixels

    or b        ; merge result with current screen octet

    ld d,a      ; use e as new color for next instruction to run 
drawLastOctet:
    ld (hl),d
endDraw:

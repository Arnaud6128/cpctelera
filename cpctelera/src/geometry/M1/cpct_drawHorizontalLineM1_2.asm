    ;; Ok let's start drawing the line now, we have all the information we need
    ; Here HL = current adress (leftAdress)
    ;      DE = Target  adress (rightAdress)
    ;      B  = current sub pixel (leftSubPixel)
    ;      C  = target  sub pixel (rightSubPixel)
    ;      A  = INK Color

    ; 
    ld (#colorIndex),a      ; SMC to chnge indexed access

    ; set ix to point to the color table
    ld ix,#cpct_plotFullColor_M1
colorIndex=.+2
    ld a,(ix+2)     ; Full pixels chosen color SMC
    ld__iyl_a       ; Store full pixels in iyl
draw_loop:

; have we reached target adress ?
    ld a,l                  ; Optim: start with most different checks
    cp e
    jr nz,notSameAdress
    ld a,h                  ; Liekly to be egal often
    cp d
    jr nz,notSameAdress
sameAdress: ; Ok, almost there, deal with remaining sub pixel at end of line - We do not need de anymore
    push hl

    ld a,b      ; a = left subpixel
    rlca        ; multiply by 4
    rlca        ;  "
    add c       ; a = b*4+c : index in mask table
 
    ld hl, #cpct_subPixelHorizontalMask_M1  ; mask table
    ld d,#0     
    ld e,a      ; de = index in table
    add hl,de   ; hl = adress of mask to use
    ld a,(hl)   ; a = mask to use for reset pixels with new color

    pop hl      ; restore current adress

    ld d,a      ; save mask
    and (hl)    ; a = current screen pixels with clear pixels from mask 

    ld e,a      ; current screen octet (cleared)
    ld a,d      ; retrieve mask
    cpl         ; invert mask
    and__iyl    ; set requested color to inverted pixels

    or e        ; merge result with current screen octet

    ld (hl),a   ; Set screen octet with preserved pixels around b and c
    
    jr endDrawing
notSameAdress:  ; Still not on last octet, We don't care of c
    ; Are we on a full octet (b == 0) or on a partial octet?
    ld a,b
    or a
    jr z,drawFullPixel  ; best case, let's accelerate full speed

    ; get full mask from b sub pixel to 3rd subpixel on right
    push de     ; preserve target adress
    push hl     ; preserve current adress

    ld hl, #cpct_subPixelHorizontalMask_M1 + 3  ; Hardcoding C=3 here for third sub pixel on right
    ld a,b    ; a = left subpixel
    rlca      ; multiply by 4
    rlca      ;  "
    ld e,a    
    ld d,#0    

    add hl,de   ; Get adress of mask for b to 3 subpixel

    ld a,(hl)   ; get mask

    pop hl      ; restore current adress

    ld d,a      ; save mask
    and (hl)    ; Get current screen octet and reset needed pixels

    ld e,a      ; store current octet
    ld a,d      ; restore mask
    cpl         ; invert mask
    and__iyl    ; set requested color to pixels

    or e        ; merge current screen octet with new colored pixels

    pop de      ; restore target adress

    ld b,#0     ; we performed sub pixel b, so now it is reset to 0

    jr setOctet ; set value to screen and continue
drawFullPixel:
    ld__a_iyl   ; get Full Color value
setOctet:
    ld (hl),a       ; Set new screen octet
    inc hl          ; increase adress
    jr draw_loop    ; let's loop
endDrawing:

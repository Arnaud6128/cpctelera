;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawDoubleSpriteM0
;;
;;    Draw a Mode 0 sprite scale x2 horizontally and vertically, transforming each 
;; source pixel into a 2x2 block of identical pixels. The function processes 
;; sprites stored in CPC Mode 0 format (2bpp, 4 pixels per byte) and outputs 
;; the enlarged sprite to a destination memory buffer.
;;
;; C Definition:
;;    void <cpct_drawDoubleSpriteM0> (const <u8>* spr, <u8>* dst, 
;;                                          <u8> width, <u8> height) __z88dk_callee;
;;
;; Input Parameters (5 bytes):
;;  (2B  HL) spr       - Pointer to source sprite data in Mode 0 format
;;  (2B  DE) dst       - Pointer to destination video memory for enlarged sprite
;;  (1B   C) width     - Sprite width in bytes (>0) (Beware, not in pixels!)
;;  (1B   B) height    - Sprite height in bytes (>0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawDoubleSpriteM0_asm
;;
;; Return value:
;;  (2B  DE) Pointer to the byte following the last written byte in destination buffer
;;
;; Parameter Restrictions:
;;  * sprite must be an array containing sprite's pixels in CPC Mode 0 format 
;; (4 bits per pixel, 2 pixels per byte). Pixels must be stored consecutively 
;; starting from top-left corner, going left-to-right and top-to-bottom. Total 
;; amount of bytes in the array must be w × h.
;;  * memory may point to any RAM location (video memory, backbuffer or 
;; temporary buffer). The function writes 2×w bytes per scanline and produces 
;; 2×h scanlines of output (total size = 4×w×h bytes).
;;  * w must be the sprite width in bytes (not pixels) and must be ≥1. 
;; In Mode 0: 1 byte = 2 pixels, therefore a 16-pixel wide sprite has w=8.
;; Using w=0 will cause undefined behaviour (IXL underflow).
;;  * h must be the sprite height in bytes (equal to pixel height) and ≥1. 
;; Using h=0 will cause undefined behaviour (IXH underflow).
;;  * Source and destination buffers must not overlap. Overlapping regions 
;; will cause corruption of source data during processing.
;;
;; Known limitations:
;;    * w or h values of 0 will cause infinite loops (IXL/IXH underflow to 255).
;;    * This function is Mode 0 specific (4bpp). Using it with Mode 0 or Mode 2 
;; sprites will produce corrupted output.
;;    * This function cannot be run from ROM as it uses self-modifying code 
;; (patching of LD BC,#0000 instruction at runtime).
;;    * No boundary checks are performed on destination buffer. Writing beyond 
;; allocated memory may corrupt adjacent data or crash the program.
;;    * Performance degrades linearly with sprite dimensions. Very large sprites 
;; (>64×64 bytes) may cause visible slowdown in real-time applications.
;;
;; Details:
;;    The function processes each source byte (containing 2 Mode 0 pixels) and 
;; expands it into 4 output bytes (representing a 2×2 pixel block per source pixel):
;;      Source byte format: [P3 P2 P1 P0 | P3 P2 P1 P0]  (two identical nybbles)
;;      Output for 1 byte:  4 bytes forming a 2 scanlines × 8 pixels block
;;
;;    Processing steps per source byte:
;;      1. Extract each of the 4 pixels using bitmasks
;;      2. Duplicate each pixel horizontally (bit replication within byte)
;;      3. Write 2 bytes for current scanline (pixels doubled horizontally)
;;      4. After finishing a scanline, duplicate it vertically using LDIR
;;
;; Register usage:
;;    Destroyed   : AF, BC, DE, HL
;;
;; Required memory:
;;     C-bindings   - 123 bytes 
;;     ASM-bindings - 120 bytes
;;
;; Time Measures :
;; (start code)
;;  Case          |    microSecs (us)       |    CPU Cycles
;; ----------------------------------------------------------------
;;  Formula       |    14 + 33H + 16WH      |    56 + 132H + 64WH
;; ----------------------------------------------------------------
;;  W=4 / H=8     |           790           |          3160
;;  W=8 / H=16    |          2586           |         10344
;;  W=16 / H=32   |          9262           |         37048
;; ----------------------------------------------------------------
;; (end code)
;;    W = width in bytes (source), H = height in lines (source)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   push ix                      ;; [5] Save IX

   ld   a, c                   ;; [1] Save sprite width
   ld  (sprite_width), a       ;; [4] |
   
   add  a                      ;; [1] Sprite width double
   ld__ixl_a                   ;; [2] IXL = A (Width double)
   ld__ixh_b                   ;; [2] IXH = B (Height)

;; Sprite Height Loop
Loop_height:
    push de                    ;; [3] Store DE (Video memory destination)
	
sprite_width = .+1
    ld   b, #00                ;; [2] B = Sprite width

;; Sprite Width Loop
Loop_width:
	ld   a, (hl)               ;; [2] A = Current Byte
	and  #0b10101010           ;; [2] Get first pixel [AXCXBXDX]
	ld   c, a                  ;; [1] Double first pixel on first Byte
	srl	 a                     ;; [1] | A |= (C >> 1)
	or	 a, c                  ;; [1] | [AABBCCDD]

	ld  (de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 

	ld   a, (hl)               ;; [2] A = Current Byte
	and  #0b01010101           ;; [2] Get second pixel [X1X2X3X4]
	ld	 c, a                  ;; [1] Double second pixel on second Byte
	add	 a, a                  ;; [1] | A |= (C << 1)
	or	 a, c                  ;; [1] | [11223344]

	ld	(de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 

	inc	 hl                    ;; [2] Next Byte Sprite 
	djnz Loop_width            ;; [3/4] Decrement width continue if (B != 0)

;; Double line by copy current line	
    pop  de                     ;; [3] Restore DE to compute next line
    push hl                     ;; [3] Store HL (Sprite array)
	
    ld   h, d                   ;; [1] HL = DE (Destination memory)
    ld   l, e                   ;; [1] |
    
    ld   a, d                   ;; [1] Start of next pixel line normally is 0x0800 bytes away.
    add  #0x08                  ;; [2]    so we add it to DE (just by adding 0x08 to D)
    ld   d, a                   ;; [1] We check if we have crossed memory boundary (every 8 pixel lines)
    and  #0x38                  ;; [2] |
    jr   nz, Copy_line          ;; [2/3]  by checking the 4 bits that identify present memory line. 

;; Check boundary crossed:
    ld   a, e                   ;; [1] DE = DE + 0xC050h
    add  #0x50                  ;; [2] -- Relocate DE pointer to the start of the next pixel line:
    ld   e, a                   ;; [1] -- DE is moved forward 3 memory banks plus 50 bytes (4000h * 3) 
    ld   a, d                   ;; [1] -- which effectively is the same as moving it 1 bank backwards and then
    adc  #0xC0                  ;; [2] -- 50 bytes forwards (which is what we want to move it to the next pixel line)
    ld   d, a                   ;; [1] -- Calculations are made with 8 bit maths as it is faster than other alternatives here

Copy_line:
	ld__c_ixl                   ;; [2] C = IXL (Width * 2)
	ldir                        ;; [4/5] Copy data
	
	pop  hl                     ;; [3] Restore Sprite pointer
	dec__ixh                    ;; [2] IXH-- (Height)
    jr   z, End_draw            ;; [2/3] Loop Height if (IXH != 0)
	
    ex   de, hl                 ;; [1] DE has destination, but we have to exchange it with HL to be able to do 16bit maths
	ld__c_ixl                   ;; [2] C = IXL (Width * 2)
    sbc  hl, bc                 ;; [3] HL -= Width (return to start)
    ex   de, hl                 ;; [1] DE = Destination

    ld   a, d                   ;; [1] Start of next pixel line normally is 0x0800 bytes away.
    add  #0x08                  ;; [2]    so we add it to DE (just by adding 0x08 to D)
    ld   d, a                   ;; [1] We check if we have crossed memory boundary (every 8 pixel lines)
    and  #0x38                  ;; [2] |
    jr   nz, Loop_height        ;; [2/3]  by checking the 4 bits that identify present memory line. 

;; Check boundary crossed
   ld    a, e                   ;; [1] DE = DE + 0xC050h
   add   #0x50                  ;; [2] -- Relocate DE pointer to the start of the next pixel line:
   ld    e, a                   ;; [1] -- DE is moved forward 3 memory banks plus 50 bytes (4000h * 3) 
   ld    a, d                   ;; [1] -- which effectively is the same as moving it 1 bank backwards and then
   adc   #0xC0                  ;; [2] -- 50 bytes forwards (which is what we want to move it to the next pixel line)
   ld    d, a                   ;; [1] -- Calculations are made with 8 bit maths as it is faster than other alternatives here
   jp    Loop_height            ;; [3] Next line

End_draw:   	
	pop  ix                    ;; [4] Restore IX
	ret                        ;; [3] Return to caller
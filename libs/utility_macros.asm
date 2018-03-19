;====SNES Utility Macros====

; Notes on parameter usage:
; The stack is used to get inputs/outputs between subroutines
; and calling code. The list and ORDER of parameters will be
; given which must be abided by when using these subroutines.

; The address range $00:F000 to $00:F01F is commonly used for storing state.

; Unless otherwise noted, a subroutine assumes 16-bit A/X/Y registers.

; I : pColorB1 : The first byte of the colour to write. 	0bbbbbgg
; I : pColorB2 : The second byte of the colour to write.	gggrrrrr
; I : pAddress : The palette address to write to.			--------
; Push order: pColorB1 => pColorB2 => pAddress

; Note: Colour looks like 0bbbbbgg gggrrrrr == pColorB1 pColorB2
WritePalette:
	sep #$20
	php
	pla
	sta $00F000 ; store P
	
	rep #$30 ; 16-bit AXY
	
	pla
	sta $2121 ; set palette address
	pla
	sta $2122 ; write B2
	pla
	sta $2122 ; write B1
EndWP:
	sep #$20
	lda $00F000
	pha
	plp ; restore P
	
	rts ; end WritePalette
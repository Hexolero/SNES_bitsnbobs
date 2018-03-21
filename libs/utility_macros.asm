;====SNES Utility Library====
; This is a file full of utility subroutines and .DEFINEs and all
; sorts of stuff designed to make SNES development much easier.
; A game would typically be built AROUND this file, rather than
; simply including it and using it. (That's the intent, at least.)
;
; This file was made by Bomberdude / JWK, and I hope it's of some
; use to you in your mad quest to make SNES homebrews/romhacks.

; Notes on parameter usage:
; The stack is used to get inputs/outputs between subroutines
; and calling code. The list and ORDER of parameters will be
; given which must be abided by when using these subroutines.
;
; The address range $00:F000 to $00:F01F is commonly used by subroutines:
; $00:F000 - commonly overwritten/used as storage/transfer memory.
; $00:F001 - same as above
; $00:F002 - same as above
; $00:F003 - same as above
; $00:F004 - same as above
; $00:F005 - same as above
; $00:F006 - same as above
; $00:F007 - same as above

;=================================================
; Define statements used for general management:

.DEFINE JOYPAD_STATE	$00E000 ; Where to store joypad data. 2 bytes of the form: ABLR0000 BYSSUDLR (a, b, lt, rt || b, y, sel, st, up, down, left, right)
.DEFINE JOYPAD_STATE_2	$00E001	; This takes up bytes $00E000 and $00E001. Read from here if you want to quickly run bit checks (i.e. JOYPAD_STATE_2 & 11------)

; These addresses contain a byte which holds the number of frames the button has been pressed for.
; If you want to use these to do simple press checks, do a CMP #0 to see if they're pressed at all.
; (Note: CMP #x and AND #x both take 3-m cycles, so either of them is equally fast for press checks.)
; If you want to see if they've been held for x frames, do a CMP #x and check for > than / < than.
; The value maxes out at $FF, i.e. 255 frames = 4.25sec.
; When the button is not currently pressed, it is immediately reset to $00.
.DEFINE BTN_A 		$00E002
.DEFINE BTN_B 		$00E003
.DEFINE BTN_X 		$00E004
.DEFINE BTN_Y 		$00E005
.DEFINE BTN_UP 		$00E006
.DEFINE BTN_LEFT	$00E007
.DEFINE BTN_DOWN	$00E008
.DEFINE BTN_RIGHT	$00E009
.DEFINE BTN_LT		$00E00A
.DEFINE BTN_RT		$00E00B
.DEFINE BTN_SEL		$00E00C
.DEFINE BTN_START	$00E00D

;=================================================

; I : pColorB1 : The first byte of the colour to write. 	0bbbbbgg
; I : pColorB2 : The second byte of the colour to write.	gggrrrrr
; I : pAddress : The palette address to write to.			--------
; Push order: pColorB1 => pColorB2 => pAddress
; Note: Colour looks like 0bbbbbgg gggrrrrr == pColorB1 pColorB2
WritePalette:
	pha ; save working registers
	
	lda 7,S
	sta $2121 ; set palette address
	lda 9,S
	sta $2122 ; write B2
	lda 11,S
	sta $2122 ; write B1
	
	pla ; restore working registers
	
	sta $00F000 ; temporarily store A
	pla
	pla
	pla ; remove parameters from stack
	lda $00F000 ; restore A
	
	rts ; end WritePalette


ReadPalette:
	rts ; end ReadPalette


; No inputs/outputs. Call this once every frame to store the current
; joypad state in JOYPAD_STATE and all BTN_[] addresses.
ReadJoypad:
	pha
	phx
	phy ; store working registers
	
	rep #$20 ; use 16-bit registers for a single read/write
	lda $4218
	sta JOYPAD_STATE ; read joypad data into the two bytes at JOYPAD_STATE
	
	sep #$30 ; use 8-bit accumulator/x/y
	ldx #0 ; index which button we're checking
	ldy #%10000000 ; store bit check in Y
LoopOneRJP:
	tya
	and JOYPAD_STATE
	bne MatchABLR ; check against bit pattern
NoMatchABLR:
	lda #$00
	sta BTN_A,X
	bra ContinueLoopOneRJP
MatchABLR:
	lda BTN_A,X
	ina
	bcs OverflowBtnABLR ; branch if overflow occured
NoOverflowBtnABLR:
	sta BTN_A,X ; store the result back in BTN_[]
	bra ContinueLoopOneRJP
OverflowBtnABLR:
	clc ; clear carry bit
	lda #$FF
	sta BTN_A,X ; hold BTN_[] at $FF
ContinueLoopOneRJP:
	inx ; increment our button counter by 1
	tya
	lsr
	tay ; shift the bit pattern to the right by 1
	and %00001000
	beq LoopOneRJP ; until we shift to %00001000, loop
EndLoopOneRJP:
	
	ldx #0 ; index which button we're checking
	ldy #%10000000 ; store bit check in Y
LoopTwoRJP:
	tya
	and JOYPAD_STATE_2
	bne MatchBYSSUDLR ; check against bit pattern
NoMatchBYSSUDLR:
	lda $00
	sta BTN_UP,X
	bra ContinueLoopTwoRJP
MatchBYSSUDLR:
	lda BTN_UP,X
	ina
	bcs OverflowBtnBYSSUDLR ; branch if overflow occured
NoOverflowBtnBYSSUDLR:
	sta BTN_UP,X ; store the result back in BTN_[]
	bra ContinueLoopTwoRJP
OverflowBtnBYSSUDLR:
	clc ; clear carry bit
	lda $FF
	sta BTN_UP,X ; hold BTN_[] at $FF
ContinueLoopTwoRJP:
	inx ; increment our button counter by 1
	tya
	lsr
	tay ; shift the bit pattern to the right by 1
	bcc LoopTwoRJP ; lsr shifts the low bit into c - if this is 1, we are done
EndLoopTwoRJP:
	ply
	plx
	pla ; restore working registers
	
	rts ; end ReadJoypad


; Util subroutine which ASLs the accumulator X times.
ASLRepeated:
	phx ; store working registers
	
	cpx #0
	beq EndASLR ; if X==0, do no ASLs
LoopASLR:
	asl A
	dex ; z flag will be set if X==0
	beq EndASLR ; check z flag is set
EndASLR:
	plx ; restore working registers
	
	rts ; end ASLRepeated


; Util to use A to add X to Y
AddXY:
	pha ; store A on stack
	
	tya
	stx $00F000
	adc $00F000
	tay
	
	pla ; restore A
	rts ; end AddXY


; Util to use A to add Y to X
AddYX:
	pha ; store A on stack
	
	txa
	sty $00F000
	adc $00F000
	tax
	
	pla ; restore A
	rts ; end AddYX



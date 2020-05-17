; zero page addresses
	util1	= $22
	util2	= $24
	txttab	= $2b	; start of basic text
	fretop	= $33	; string storage ptr
	limit 	= $37	; limit of memory ptr
	chrget	= $73
	chrgot	= $79
	chrptr	= $7a	; text ptr in chrget routine
	status	= $90
	tmp	= $9b
	int	= $b0	; 2 bytes	
	fnlen	= $b7

; basic tokens
	tokprint	= $99
	toktab		= $a3
	toksys		= $9e
	tokpeek		= $c2
	tokmul		= $ac
	tokplus		= $aa
	toknew		= $a2

; petscii
	eol	= $0d
	down	= $11
	reverse = $12
	quote	= $22
	clear	= $93

; kernal
	lstnsa	= $ff93
	talksa	= $ff96
	iecin	= $ffa5
	iecout	= $ffa8
	untalk	= $ffab
	unlstn	= $ffae
	listen	= $ffb1
	talk	= $ffb4
	setlfs	= $ffba
	setnam	= $ffbd
	open	= $ffc0
	close	= $ffc3
	clrchn	= $ffcc
	chrout	= $ffd2
	load	= $ffd5
	stop	= $ffe1
	getin	= $ffe4

; other rom routines
	printxa		= $ddcd	; print word
	doready		= $e195	; do ready return to basic ?
	warmstart	= $e467	; basic warm start
	output		= $e742 ; output character to screen

	.org	$401-2
	.word	basic

; 10 PRINT"<clear>"TAB(6)"<reverse>VIC WEDGE
; 20 PRINT"<down>   BY DAVID A. HOOK
; 30 PRINT"<down>>         DISK STATUS
; 40 PRINT"@         OR COMMANDS
; 50 PRINT"<down>>$0         DIRECTORY
; 60 PRINT"@$0
; 70 PRINT"<down>/FILENAME        LOAD
; 80 SYS(PEEK(43)+256*PEEK(44)+215)
; 90 NEW
basic:
	.word	line20, 10
	.byte	tokprint, quote, clear, quote, toktab, "6)", quote, reverse, "VIC WEDGE", 0
line20:	.word	line30, 20
	.byte	tokprint, quote, down, "   BY DAVID A. HOOK", 0
line30:	.word	line40, 30
	.byte	tokprint, quote, down, ">         DISK STATUS", 0
line40:	.word	line50, 40
	.byte	tokprint, quote, "@         OR COMMANDS", 0
line50:	.word	line60, 50
	.byte	tokprint, quote, down, ">$0         DIRECTORY", 0
line60:	.word	line70, 60
	.byte	tokprint, quote, "@$0", 0
line70:	.word	line80, 70
	.byte	tokprint, quote, down, "/FILENAME        LOAD", 0
line80:	.word	line90, 80
	.byte	toksys, "(", tokpeek, "(43)", tokplus, "256", tokmul, tokpeek, "(44)", tokplus, "215)", 0
line90:	.word	line99, 90
	.byte	toknew, 0
line99:	.word	0

	.res	5,$aa

install:
	; alloc memory for dos wedge
	lda	limit
	sec
	sbc	#$33
	sta	limit
	sta	fretop
	lda	limit+1
	sbc	#1
	sta	limit+1
	sta	fretop+1
	; copy code
	ldy	#$33
	lda	txttab
	ldx	txttab+1
	inx
	inx
	inx
	sta	util1
	stx	util1+1
	lda	limit
	ldx	limit+1
	inx
	sta	util2
	stx	util2+1
	ldx	#1
@copy1:	lda	(util1),y
	sta	(util2),y
	dey
	bne	@copy1
	dex
	beq	@copy2
	bmi	@copy3
@copy2:	lda	(util1),y
	sta	(util2),y
	dec	util2+1
	dec	util1+1
	ldy	#0
	beq	@copy1
	; modify chrget
@copy3:
	lda	#$4c	; jmp
	sta	chrget
	ldy	limit
	ldx	limit+1
	iny
	bne	@skip
	inx
@skip:	sty	chrget+1
	stx	chrget+2
	rts

	.res	215, $aa

main:
	nop
	inc	chrptr
	bne	@main1
	inc	chrptr+1
	; check immediate vs program mode ?
@main1:	stx	tmp
	tsx
	lda	$101,x
	cmp	#$8c
	bne	@main3
	lda	$102,x
	cmp	#$c4
	bne	@main3
	lda	chrptr
	bne	@main2
	lda	chrptr+1
	cmp	#$02
	bne	@main2
	; check command
	ldy	#0
	sty	tmp
	lda	(chrptr),y
	cmp	#'>'
	beq	@command
	cmp	#'@'
	beq	@command
	iny
	sta	tmp
	cmp	#'/'
	beq	loadfile
	bne	@main2
@command:
	iny
	lda	(chrptr),y
	beq	getstatus
	cmp	#'$'
	beq	getdirectory
	bne	sendcommand
@main2:	jmp	chrgot
@main3:	ldx	tmp
	jmp	chrgot

; send disk command
sendcommand:
	lda	#$8
	jsr	listen
	lda	#$6f
	jsr	lstnsa
@send1:	inc	chrptr
	ldy	#0
	lda	(chrptr),y
	beq	@send2
	jsr	iecout
	clv
	bvc	@send1
@send2:	jsr	unlstn
	clv
	bvc	exit
	
getstatus:
	sty	chrptr
	lda	#8
	jsr	talk
	lda	#$6f
	jsr	talksa
@status1:
	jsr	iecin
	cmp	#eol
	beq	@status2
	jsr	output
	clv
	bvc	@status1
@status2:
	jsr	output
	jsr	untalk
exit:	jmp	chrgot

loadfile:
getdirectory:
	iny			; calculate file name length
	lda	(chrptr),y
	bne	loadfile
	dey
	tya
	ldx	#1		; name at $201
	ldy	#2
	jsr	setnam
	ldx	#8
	lda	tmp
	bne	@load0
	lda	#$0e
	ldy	#$60
	jsr	setlfs
	jsr	open
	lda	#8
	jsr	talk
	lda	#$60
	jsr	talksa
	lda	#0
	sta	status
	ldy	#3		; a number of words to be read (address, next line, line number)
@readword:
	sty	fnlen
	jsr	iecin		; read word
	sta	int
	ldy	status
	bne	@error0
	jsr	iecin
	sta	int+1
	ldy	status
	bne	@error0
	ldy	fnlen
	dey
	bne	@readword
	ldx	int
	lda	int+1
	jsr	printxa		; print a number of blocks
	lda	#' '
@l14dd:	bne	@skip
@load0:
	bne	@load1
@error0:
	bne	@error
@readword0:
	bne	@readword
@skip:	jsr	chrout
@getchar:			; print file name
	jsr	iecin
	ldx	status
	bne	@error
	cmp	#0
	beq	@printcr
	jsr	chrout
	jsr	stop		; check if stop key was pressed
	beq	@error
	jsr	getin		; check if a user requested pause
	beq	@getchar
	cmp	#' '
	bne	@getchar
@pause:	jsr	getin
	beq	@pause
	bne	@getchar
@printcr:
	lda	#eol
	jsr	chrout
	ldy	#2		; read two words (next line ptr and line number)
	bne	@readword0
@error:	jsr	clrchn
	lda	#$0e
	jsr	close
	pla
	pla
	jmp	warmstart
@load1:	lda	#$0e
	ldy	#0
	jsr	setlfs
	lda	#0
	ldx	txttab
	ldy	txttab+1
	jsr	load
	jmp	doready


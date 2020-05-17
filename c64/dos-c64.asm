; Commodore 64 DOS Wedge
;
; /filename	Load a BASIC program into RAM
; %filename	Load a machine language program into RAM
; ↑filename	Load a BASIC program into RAM and then automatically run it
; ←filename	Save a BASIC program to disk
; @	Display (and clear) the disk drive status
; @$	Display the disk directory without overwriting the BASIC program in memory
; @command	Execute a disk drive command (e.g. S0:filename, V0:, I0:)
; @Q	Deactivate the DOS Wedge

; petscii
	cmdz	= $ad
	uparrow	= $5e
	cmds	= $ae
	leftarrow = $5f
	cmde	= $b1
	eol	= $0d
; zero page addresses
	txttab	= $2b	; start of basic text (2 bytes)
	vartab	= $2d	; start of basic variables (2 bytes)
	chrget	= $73
	chrgot	= $79
	chrptr	= $7a	; text ptr in chrget routine (2 bytes)
	chrmod	= $7c
	status	= $90
	index	= $a5
	savea	= $a6
	savex	= $a7
	endaddr = $ae
	fnlen	= $b7	; file name lenght
	second	= $b9	; secondary address
	devnum	= $ba	; device number
	fnaddr	= $bb	; ptr to file name (2 bytes)
	int	= $c3	; (2 bytes)

; kernal routines
	setmsg	= $ff90
	lstnsa	= $ff93
	talksa	= $ff96
	iecin	= $ffa5
	iecout	= $ffa8
	untalk	= $ffab
	unlstn	= $ffae
	listen	= $ffb1
	talk	= $ffb4
	load	= $ffd5
	stop	= $ffe1
	getin	= $ffe4

; other routines in rom
	linechaining = $a533	; rebuild basic line chaining
	clear = $a659		; clear command
	basicexeptr = $a68e	; set basic execute ptr
	basicloop = $a7ae	; basic interpreter inner loop
	syntax = $af08		; syntax error
	printxa	= $bdcd		; print unsigned integer
	save = $e159		; save routine
	warmstart = $e386	; basic warm start
	chrorg = $e3ab		; chrget original version
	output = $e716		; output character to screen 
	sendsa = $f3d5		; send secondary address and file name
	closeserial = $f642	; close serial device
	
	.org	$cc00-2
	.word	start
start:
	jmp	install
; address tables for commands
tablehi:
	.byte >(loadfile-1), >(loadfile-1), >(loadfile-1), >(loadfile-1), >(loadfile-1)
	.byte >(savefile-1), >(command-1), >(command-1), >(command-1), >(changedevice-1)
	.byte >(quit-1)
tablelow:
	.byte <(loadfile-1), <(loadfile-1), <(loadfile-1), <(loadfile-1), <(loadfile-1)
	.byte <(savefile-1), <(command-1), <(command-1), <(command-1), <(changedevice-1)
	.byte <(quit-1)
tablecmd:
	.byte "%/", cmdz, uparrow, cmds, leftarrow, ">", cmde, "@#Q", 0

	.res	2, $aa
; file name
filename:
	.res	80, $aa
; device number
device:
	.byte	$aa
tmp1:
	.byte	$aa ; CC78
tmp2:
	.byte	$aa ; CC79
; current command
current:
	.byte	$aa ; CC7A

title:
	.byte eol, eol, "      DOS MANAGER V5.1/071382"
	.byte eol, eol, "         BY  BOB FAIRBAIRN"
	.byte eol, eol, "(C) 1982 COMMODORE BUSINESS MACHINES"
	.byte eol, 0

; 3 bytes which will be copied to chrget routine
modification:
	jmp	main

; install wedge
install:
	ldx	#$02
@install1:
	lda	modification,x
	sta	chrmod,x
	dex
	bpl	@install1
; copy current device number
	lda	devnum
	sta	device
	jmp	printtitle

; start of dos wedge
main:
	sta	savea
	stx	savex
; check basic direct mode vs program mode?
	tsx
	lda	$101,x
	cmp	#$e6
	beq	@main1
	cmp	#$8c
	bne	@exit
@main1:	lda	$102,x
	cmp	#$a7
	beq	@main2
	cmp	#$a4
	bne	@exit

; search command
@main2:	lda	savea
	ldx	#$8
@main3:	cmp	tablecmd,x
	beq	commandfound
	dex
	bpl	@main3

; exit to chrget routine
; command was not found or in wrong mode
@exit:	lda	savea
	ldx	savex
; rest of original chrget routine
	cmp	#$3a
	bcs	@exit1
	jmp	$0080
@exit1:	jmp	$008a

; command was found
commandfound:
	stx	index	; save command index
	sta	current	; save command char
	jsr	parse	; parse parameters
	ldx	index
; set pointer to the file name
	lda	#<filename
	sta	fnaddr
	lda	#>filename
	sta	fnaddr+1
; set device number
	lda	device
	sta	devnum
; execute command
execute:
	lda	tablehi,x
	pha
	lda	tablelow,x
	pha
	rts

; execute @ command
command:
	tya
	beq	getstatus	; branch if only @
; check if @# or @Q
	ldx	#$9
@command1:
	lda	tablecmd,x
	beq	@notfound
	cmp	filename
	beq	@found
	inx
	bpl	@command1
@notfound:
	lda	filename
	cmp	#'$'
	beq	getdirectory
	jmp	drivecommand
; perform @# or @Q
@found:
	dec	fnlen
	lda	#<(filename+1)
	sta	fnaddr
	lda	#>(filename+1)
	sta	fnaddr+1
	jmp	execute

; send a drive command
drivecommand:
	lda	devnum
	jsr	listen
	lda	#$6f
	sta	second	; secondary address
	jsr	lstnsa
	ldy	#0
@drive1:
	lda	filename,y
	jsr	iecout
	iny
	cpy	fnlen
	bcc	@drive1
	jsr	unlstn
	jmp	getstatusend

; get device status
getstatus:
	lda	devnum
	jsr	talk
	lda	#$6f
	sta	second
	jsr	talksa
@status1:
	jsr	iecin
	cmp	#eol
	beq	@status2
	jsr	output
	jmp	@status1
@status2:
	jsr	output
	jsr	untalk
getstatusend:
	jmp	chrgot

; get directory
getdirectory:
	lda	#$60
	sta	second
	jsr	sendsa	; send secondary address and file name
	lda	devnum
	jsr	talk
	lda	second
	jsr	talksa
	lda	#0
	sta	status
	ldy	#$3	; number of words to be read (address, link to basic line and line number)
@get1:	sty	fnlen	; read y integers
	jsr	iecin
	sta	int
	jsr	iecin
	sta	int+1
	ldy	status
	bne	@end
	ldy	fnlen
	dey
	bne	@get1
	ldx	int
	lda	int+1
	jsr	printxa ; print unsigned integer (blocks)
	lda	#' '
	jsr	output
@get2:	jsr	iecin	; print file name
	ldx	status
	bne	@end
	cmp	#0
	beq	@endofline
	jsr	output
	jsr	stop	; check if stop pressed
	beq	@end
	jsr	getin	; check if a user pressed a key for pause
	beq	@get2
	cmp	#' '
	bne	@get2
@pause:	jsr	getin
	beq	@pause
	bne	@get2
@endofline:
	lda	#eol	; print cr
	jsr	output
	ldy	#2	; words to be read (link to basic line and line number)
	jmp	@get1	; read next line of directory
@end:	jsr	closeserial
	lda	#eol
	jsr	output
	jmp	chrgot

; load routine
loadfile:
	ldx	txttab		; beginning of basic text
	ldy	txttab+1
	lda	current		; current command
	cmp	#'%'
	bne	@basic
	lda	#1		; secondary address
	.byte	$2c
@basic:	lda	#0
	sta	second
	lda	#0		; load
	jsr	load
	bcs	@error
	lda	current
	cmp	#'%'
	beq	@warm
	lda	endaddr+1
	sta	vartab+1
	lda	endaddr
	sta	vartab
	jsr	clear		; perform clear
	jsr	linechaining	; rebuild basic line chaining
	lda	current
	cmp	#cmdz
	beq	@warm
	cmp	#'/'
	bne	@run
@warm:	jmp	warmstart
@run:
	lda	#0
	jsr	setmsg
	jsr	basicexeptr	; set basic execute pointer
	jmp	basicloop	; basic interpreter inner loop
@error:	jmp	warmstart

; quit command
quit:
	ldx	#2
@quit1:	lda	chrorg,x
	sta	chrmod,x
	dex
	bpl	@quit1
	jmp	warmstart

; save basic program
savefile:
	jsr	save
	jmp	getstatus

; change device number
changedevice:
	ldy	fnlen
	lda	filename,y
	and	#$0f
	sta	device
	dey
	beq	@end
	lda	filename,y
	and	#$0f
	tay
	beq	@end
	lda	device
	clc
@change1:
	adc	#$a
	dey
	bne	@change1
	sta	device
@end:	jmp	chrgot


; parse parameters
parse:
	ldy	#0
	jsr	chrget
	tax
	bne	@parse1
	jmp	return
@parse1:
	lda	#$60	; save rts to chrget routine
	sta	chrmod
	lda	chrptr	; save text ptr in chrget routine
	pha
	lda	chrptr+1
	pha
	txa
@parse2:		; check if there is a "string"
	cmp	#'"'
	beq	@string
	jsr	chrget
	bne	@parse2
	pla		; string was not found
	sta	chrptr+1
	pla
	sta	chrptr
	jsr	chrgot
	ldx	#0
	cmp	#'"'
	beq	@string1
	ldx	#2
	cpx	chrptr+1
	bne	error
	ldx	#0
	beq	@parse3
@string:
	pla	; discard saved text ptr
	pla
	ldx	#0
@string1:
	jsr	chrget
;@parse2b:
	beq	return
@parse3:
	cmp	#'"'
	beq	return
	cmp	#'='
	beq	@parse4
	cmp	#':'
	bne	@parse5
@parse4:
	ldx	#$ff
@parse5:
	cmp	#'['
	beq	@parse6
@string2:
	sta	filename,y
	sta	tmp2
	inx
	iny
	bpl	@string1
@parse6:
	jsr	chrget
	beq	error
	sta	tmp1
	jsr	chrget
	beq	error
	cmp	#']'
	bne	error
	cpx	#$10
	bcs	error	; file name too long
	lda	tmp2
	cmp	#'*'
	bne	@parse7
	dey
	dex
	lda	#'?'
	.byte	$2c
@parse7:
	lda	#' '
@parse8:
	cpx	#$f
	bcs	@parse9
	sta	filename,y
	iny
	inx
	bpl	@parse8
@parse9:
	lda	tmp1
	bne	@string2

; return via syntax error
error:
	ldx	#$4c	; store jmp to chrget routine
	stx	chrmod
	jmp	syntax

; return from parse parameters
return:
	sty	fnlen
	ldx	#$4c	; store jmp to chrget routine
	stx	chrmod
	jsr	chrgot
	beq	@return2
@return1:
	jsr	chrget	; ignore rest of line
	bne	@return1
@return2:
	rts

; print title
printtitle:
	ldx	#$00
@title1:
	lda	title,x
	beq	@title2
	jsr	output
	inx
	bne	@title1
@title2:
	rts
	brk



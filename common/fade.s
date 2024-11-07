InitFade:
        move.w  #0,FCnt
        rts

;******************************************************************************
; ** Fade colors
; a0 = From palette
; a1 = To palette
; a2 = Copcols
; d0 = Number of steps
; d1 = Number of colors
Fade:	movem.l	d0-d7/a0-a2,-(sp)
	cmp.w	FCnt,d0
	bmi.s	.end
       
	move.w	d0,d6
	move.w	d1,d7
.loop:	move.w	(a0)+,d0
	move.w	d0,d1
	and.w	#$0f0,d1
	eor.w	d1,d0
	move.w	d0,d2
	ext.w	d2     ; r
	lsr.w	#8,d0  ; g
	lsr.w	#4,d1  ; b

	move.w	(a1)+,d3
	move.w	d3,d4
	and.w	#$0f0,d4
	eor.w	d4,d3
	move.w	d3,d5
	ext.w	d5
	lsr.w	#8,d3
	lsr.w	#4,d4

	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5

	muls.w	FCnt,d3
	muls.w	FCnt,d4
	muls.w	FCnt,d5

	divs.w	d6,d3
	divs.w	d6,d4
	divs.w	d6,d5

	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5

	lsl.w	#8,d3
	lsl.w	#4,d4
	or.b	d4,d5
	or.w	d3,d5

	move.w	d5,2(a2)
	add.l	#4,a2
	dbf	d7,.loop

	add.w	#1,FCnt
.end: 	movem.l	(sp)+,d0-d7/a0-a2
	move.w	FCnt,d0
	rts
FCnt: 	dc.w	0

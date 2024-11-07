*******************************************************************************
*									      *
* 'DrawLine V1.01' By TIP/SPREADPOINT					      *
* ­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­					      *
* Adapted by Prospect / Insane ^ C-Lous (2013-10-23)			      *
*									      *
*******************************************************************************

DL_MInternsNonFilled	=	$CA
DL_MInternsFilled	=	$4A

;­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­
;	A0 = PlanePtr, A6 = $DFF002, D0/D1 = X0/Y0, D2/D3 = X1/Y1
;	D4 = PlaneWidth > Kills: D0-D4/A0-A1 (+D5 in Fill Mode)

DrawLine:	cmp.w	d1,d3		; Drawing only from Top to Bottom is
		bge.s	.y1ly2		; necessary for:
		exg	d0,d2		; 1) Up-down Differences (same coords)
		exg	d1,d3		; 2) Blitter Invert Bit (only at top of
					;    line)
.y1ly2:		sub.w	d1,d3		; D3 = yd

; Here we could do an Optimization with Special Shifts
; depending on the DL_Width value... I know it, but please, let it be.

		mulu	d4,d1		; Use muls for neg Y-Vals
		add.l	d1,a0		; Please don't use add.w here !!!
		moveq	#0,d1		; D1 = Quant-Counter
		sub.w	d0,d2		; D2 = xd
		bge.s	.xdpos
		addq.w	#2,d1		; Set Bit 1 of Quant-Counter (here it
					; could be a moveq)
		neg.w	d2
.xdpos:		moveq	#$f,d4		; D4 full cleaned (for later oktants
					; move.b)
		and.w	d0,d4
		lsr.w	#3,d0		; Yeah, on byte (necessary for bchg)...
		add.w	d0,a0		; ...Blitter ands automagically
		ror.w	#4,d4		; D4 = Shift
		or.w	#$B00+DL_MInternsNonFilled,d4	; BLTCON0-codes
		swap	d4
		cmp.w	d2,d3		; Which Delta is the Biggest ?
		bge.s	.dygdx
		addq.w	#1,d1		; Set Bit 0 of Quant-Counter
		exg	d2,d3		; Exchange xd with yd
.dygdx:		add.w	d2,d2		; D2 = xd*2
		move.w	d2,d0		; D0 = Save for $52(a6)
		sub.w	d3,d0		; D0 = xd*2-yd
		addx.w	d1,d1		; Bit0 = Sign-Bit
		move.b	OktantsNonFilled(PC,d1.w),d4	; In Low Byte of d4
						; (upper byte cleaned above)
		swap	d2
		move.w	d0,d2
		sub.w	d3,d2		; D2 = 2*(xd-yd)
		moveq	#6,d1		; D1 = ShiftVal (not necessary) 
					; + TestVal for the Blitter
		lsl.w	d1,d3		; D3 = BLTSIZE
		add.w	#$42,d3
		lea	$52(a6),a1	; A1 = CUSTOM+$52

; WARNING : If you use FastMem and an extreme DMA-Access (e.g. 6
; Planes and Copper), you should Insert a tst.b (a6) here (for the
; shitty AGNUS-BUG)

;		tst.b	(a6)
;.wb:		btst	#6,(a6)		; Waiting for the Blitter...
;		bne.s	.wb
		bsr     WaitBlitter
		move.l	d4,$40(a6)	; Writing to the Blitter Regs as fast
		move.l	d2,$62(a6)	; as possible
		move.l	a0,$48(a6)
		move.w	d0,(a1)+
		move.l	a0,(a1)+	; Shit-Word Buffer Ptr...
		move.w	d3,(a1)
		rts

SML			=	0
OktantsNonFilled:	dc.b	SML+1,SML+1+$40
			dc.b	SML+17,SML+17+$40
			dc.b	SML+9,SML+9+$40
			dc.b	SML+21,SML+21+$40
;­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­
;	A0 = PlanePtr, A6 = $DFF002, D0/D1 = X0/Y0, D2/D3 = X1/Y1
;	D4 = PlaneWidth > Kills: D0-D4/A0-A1 (+D5 in Fill Mode)

DrawLineFilledPoly:	
		cmp.w	d1,d3		; Drawing only from Top to Bottom is
		bge.s	.y1ly2		; necessary for:
		exg	d0,d2		; 1) Up-down Differences (same coords)
		exg	d1,d3		; 2) Blitter Invert Bit (only at top of
					;    line)
.y1ly2:		sub.w	d1,d3		; D3 = yd

; Here we could do an Optimization with Special Shifts
; depending on the DL_Width value... I know it, but please, let it be.

		mulu	d4,d1		; Use muls for neg Y-Vals
		add.l	d1,a0		; Please don't use add.w here !!!
		moveq	#0,d1		; D1 = Quant-Counter
		sub.w	d0,d2		; D2 = xd
		bge.s	.xdpos
		addq.w	#2,d1		; Set Bit 1 of Quant-Counter (here it
					; could be a moveq)
		neg.w	d2
.xdpos:		moveq	#$f,d4		; D4 full cleaned (for later oktants
					; move.b)
		and.w	d0,d4
		move.b	d4,d5		; D5 = Special Fill Bit
		not.b	d5
		lsr.w	#3,d0		; Yeah, on byte (necessary for bchg)...
		add.w	d0,a0		; ...Blitter ands automagically
		ror.w	#4,d4		; D4 = Shift
		or.w	#$B00+DL_MInternsFilled,d4	; BLTCON0-codes
		swap	d4
		cmp.w	d2,d3		; Which Delta is the Biggest ?
		bge.s	.dygdx
		addq.w	#1,d1		; Set Bit 0 of Quant-Counter
		exg	d2,d3		; Exchange xd with yd
.dygdx:		add.w	d2,d2		; D2 = xd*2
		move.w	d2,d0		; D0 = Save for $52(a6)
		sub.w	d3,d0		; D0 = xd*2-yd
		addx.w	d1,d1		; Bit0 = Sign-Bit
		move.b	OktantsFilled(PC,d1.w),d4	; In Low Byte of d4
						; (upper byte cleaned above)
		swap	d2
		move.w	d0,d2
		sub.w	d3,d2		; D2 = 2*(xd-yd)
		moveq	#6,d1		; D1 = ShiftVal (not necessary) 
					; + TestVal for the Blitter
		lsl.w	d1,d3		; D3 = BLTSIZE
		add.w	#$42,d3
		lea	$52(a6),a1	; A1 = CUSTOM+$52

; WARNING : If you use FastMem and an extreme DMA-Access (e.g. 6
; Planes and Copper), you should Insert a tst.b (a6) here (for the
; shitty AGNUS-BUG)
;		tst.b	(a6)
;.wb:		btst	#6,(a6)		; Waiting for the Blitter...
;		bne.s	.wb
		bsr     WaitBlitter
		bchg	d5,(a0)		; Inverting the First Bit of Line
		move.l	d4,$40(a6)	; Writing to the Blitter Regs as fast
		move.l	d2,$62(a6)	; as possible
		move.l	a0,$48(a6)
		move.w	d0,(a1)+
		move.l	a0,(a1)+	; Shit-Word Buffer Ptr...
		move.w	d3,(a1)
		rts

SMLFilled	= 	2
OktantsFilled:	dc.b	SMLFilled+1,SMLFilled+1+$40
		dc.b	SMLFilled+17,SMLFilled+17+$40
		dc.b	SMLFilled+9,SMLFilled+9+$40
		dc.b	SMLFilled+21,SMLFilled+21+$40

;­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­
;	Optimized Init Part... 
;	A6 = $DFF000, D0 = PlaneWidth > Kills : D0-D2

DL_Init:	;addq.w	#2,a6		; A6 = $DFF002 for DrawLine !
		; moveq	#-1,d1
		; moveq	#6,d2
;		tst.b	(a6)
;.wb:		btst	d2,(a6)
;		bne.s	.wb
		bsr     WaitBlitter
		move.w	#-1,$dff044
		move.w	#-1,$dff072
		move.w	#$8000,$dff074
		move.w	#40,$dff060
		move.w	#40,$dff066
		rts

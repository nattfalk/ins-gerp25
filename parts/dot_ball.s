************************************************************
* Main routines
************************************************************
        SECTION DotBall, CODE_P

		include	"include/macros.i"

DB_InitialDots		= 20

DotBall_Init:
		lea.l	$dff000,a6

		move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr		BltClr
		jsr		WaitBlitter

        move.l  DrawBuffer,a0
		lea		DB_BplPtrs+2,a1
        moveq   #0,d0
		moveq	#1-1,d1
		jsr		SetBpls

    	move.l	#DB_Copper,$80(a6)

		; Set initial positions
		lea.l	DB_InitialPositions(pc),a0
		move.w	#-160,d0	; xpos
		moveq	#DB_InitialDots-1,d7
.create:
		move.w	d0,(a0)+
		move.w	#0,(a0)+
		add.w	#320/20,d0
		dbf		d7,.create
		
		; Create target circle positions
		lea.l	DB_TargetPositions(pc),a0
		lea.l	Sintab,a1
		lea.l	512(a1),a2
		moveq	#0,d6
		moveq	#20-1,d7
.createCircle:
		move.w	(a1,d6.w),d0
		asr.w	#8,d0
		asr.w	#1,d0
		move.w	d0,(a0)+

		move.w	(a2,d6.w),d0
		asr.w	#8,d0
		asr.w	#1,d0
		move.w	d0,(a0)+

.next:	add.w	#(1024/20)*2,d6
		dbf		d7,.createCircle

		; Create ball coords
		lea.l	DB_Coords+(3*DB_InitialDots)*2,a0
		lea.l	Sintab,a4
		lea.l	512(a4),a5
		move.w	#340,d4			; x/z angle

		moveq	#2-1,d6
.outerLoop:
		move.l	a0,a1
		moveq	#0,d5			; y angle
		moveq	#20-1,d7
.createCoords:
		cmp.w	#19,d7
		beq.s	.next2
		cmp.w	#9,d7
		beq.s	.next2

		and.w	#$7fe,d4
		and.w	#$7fe,d5

		move.w	(a4,d5.w),d1
		asr.w	#7,d1

		move.w	(a5,d4.w),d0
		asr.w	#7,d0
		ext.l	d0
		muls	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+

		move.w	(a5,d5.w),d0
		asr.w	#7,d0
		move.w	d0,(a1)+

		move.w	(a4,d4.w),d0
		asr.w	#7,d0
		ext.l	d0
		muls	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
.next2:	
		add.w	#(1024/20)*2,d5
		dbf		d7,.createCoords

		lea.l	(DB_InitialDots-2)*3*2(a0),a0
		add.w	#340,d4

		dbf		d6,.outerLoop

		; Create preshifted dotmask
		lea.l	DB_DotMask,a1
		moveq	#0,d0
		moveq	#16-1,d7
.outerDMLoop:
		lea.l	DotMask,a0
		move.w	#160-1,d6
.innerDMLoop:
		move.l	(a0)+,d1
		lsr.l	d0,d1
		move.l	d1,(a1)+
		dbf		d6,.innerDMLoop
		addq.w	#1,d0
		dbf		d7,.outerDMLoop

		rts

DotBall_Run:
		movem.l	DrawBuffer,a2-a3
		exg		a2,a3
		movem.l	a2-a3,DrawBuffer

		move.l	a3,a0
		lea		DB_BplPtrs+2,a1
		moveq   #0,d0
		moveq	#1-1,d1
		jsr		SetBpls

		move.l	a2,a0
		move.l  #(256<<6)+(320>>4),d0
		jsr		BltClr

		cmp.l	#50,DB_LocalFrameCounter
		ble.s	.doMorph
		cmp.l	#51,DB_LocalFrameCounter
		beq		.scaleUpCoords
		cmp.l	#200,DB_LocalFrameCounter
		beq.s	.addDots1
		cmp.l	#300,DB_LocalFrameCounter
		beq.s	.addDots2
		cmp.l	#1000,DB_LocalFrameCounter
		blo.s	.doRotate

.render:
		jsr		WaitBlitter
		bsr		DB_RenderDots

.done:	
		addq.l	#1,DB_LocalFrameCounter
		rts

.doMorph:
		cmp.w	#32,DB_CurrentMorphStep
		beq.s	.morphDone
		addq.w	#1,DB_CurrentMorphStep
		bsr		DB_MorphDots
.morphDone:
		bra.s	.render

.scaleUpCoords:
		lea.l	DB_Coords(pc),a0
		moveq	#(DB_InitialDots*3)-1,d7
.scale:	move.w	(a0),d0
		asl.w	#2,d0
		move.w	d0,(a0)+
		dbf		d7,.scale
		bra.s	.doRotate

.addDots1:
		add.w	#DB_InitialDots-2,DB_DotCount
		bra.s	.doRotate

.addDots2:
		add.w	#DB_InitialDots-2,DB_DotCount
		; bra.s	.doRotate

.doRotate:
		; Rotate
		bsr		DB_RotateDots
		addq.w	#4,DB_Angles
		addq.w	#6,DB_Angles+2
		add.w	#2,DB_Angles+4
		bra.s	.render

DotBall_Interrupt:
		rts

************************************************************
* Effect routines
************************************************************
DB_RotateDots:
        lea.l   DB_Angles(pc),a0
        movem.w (a0)+,d0-d2
        jsr     InitRotate

        lea.l   DB_Coords(pc),a0
        lea.l   DB_RotatedCoords(pc),a1

        move.w	DB_DotCount,d7
		subq.w	#1,d7
.rotate:movem.w (a0)+,d0-d2
        jsr     RotatePoint

		add.w	#256,d2

        ; Project x
        ext.l   d0
        asl.l   #7,d0
        divs    d2,d0

        ; Project y
        ext.l   d1
        asl.l   #7,d1
        divs    d2,d1

		movem.w	d0-d2,(a1)
		addq.l	#6,a1

		dbf		d7,.rotate

		rts

DB_MorphDots:
		lea.l	DB_InitialPositions(pc),a0
		lea.l	DB_TargetPositions(pc),a1
		lea.l	DB_Coords(pc),a2
		lea.l	DB_RotatedCoords(pc),a3

		move.w	DB_CurrentMorphStep(pc),d6

		moveq	#DB_InitialDots-1,d7
.morph:
		; Morph x
		move.w	(a1)+,d0
		move.w	(a0)+,d1
		sub.w	d1,d0

		muls	d6,d0
		asr.w	#5,d0
		add.w	d1,d0

		move.w	d0,(a2)+
		move.w	d0,(a3)+

		; Morph y
		move.w	(a1)+,d0
		move.w	(a0)+,d1
		sub.w	d1,d0

		muls	d6,d0
		asr.w	#5,d0
		add.w	d1,d0

		move.w	d0,(a2)+
		move.w	d0,(a3)+

		clr.w	(a2)+
		move.w	#256,(a3)+

		dbf		d7,.morph

		rts

DB_RenderDots:
        move.l  DrawBuffer,a0
        lea.l   DB_RotatedCoords(pc),a1
        lea.l   DB_DotMask,a4
        lea.l   Mulu40,a2

        move	DB_DotCount(pc),d7
		subq.w	#1,d7
.renderBlock:
        move.w  (a1)+,d2
        add.w   #160-8,d2
        move.w  d2,d4
        move.w  (a1)+,d3

		move.w	(a1)+,d1
		and.w	#7<<6,d1

        add.w   #128-8,d3
        lsr.w   #3,d2
        and.w   #$fffe,d2
        and.w   #15,d4
		mulu	#640,d4
		
		add.w	d1,d4
		lea.l	(a4,d4.w),a3

        add.w   d3,d3
        move.w  (a2,d3.w),d3

        add.w   d2,d3

        lea.l   (a0,d3.w),a5

I       SET     0
        REPT    16
        move.l  (a3)+,d5
        or.l    d5,I(a5)
I       SET     I+40
        ENDR

        dbf     d7,.renderBlock

		rts

************************************************************
* Variables and data
************************************************************
		even
DB_LocalFrameCounter:		dc.l	0

DB_DotCount:				dc.w	DB_InitialDots
DB_CurrentMorphStep:		dc.w	0

DB_Angles:					dc.w	0,0,0

DB_InitialPositions:		ds.w	2*20
DB_TargetPositions:			ds.w	2*20

DB_Coords:					ds.w	3*(DB_InitialDots+(3*(DB_InitialDots-2)))
DB_RotatedCoords:			ds.w	3*(DB_InitialDots+(3*(DB_InitialDots-2)))

DB_DotMask:					ds.l	160*16
************************************************************
* Copper
************************************************************
        SECTION DB_Copper, CODE_C

DB_Copper:
		dc.w	$01fc,$0000
		dc.w	$008e,$2c81
		dc.w	$0090,$2cc1
		dc.w	$0092,$0038
		dc.w	$0094,$00d0
		dc.w	$0106,$0c00
		dc.w	$0102,$0000
		dc.w	$0104,$0000
		dc.w	$0108,$0000
		dc.w	$010a,$0000
		dc.w	$0100,$0000

		dc.w	$0180,$0123
		dc.w	$0182,$0fff

        dc.w    $0100,$1200
DB_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

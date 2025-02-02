************************************************************
*
* Main routines
*
************************************************************
        SECTION DotBall, CODE_P

		include	"include/macros.i"

DB_InitialDots		= 20

************************************************************
* Initialize
************************************************************
DotBall_InitHeart:
		; Use for debugging purposes only
		; bsr		DotBall_Init

		move.l	#160,DB_LocalFrameCounter
		move.l	#DB_BallCenterXTable,DB_BallCenterXTablePtr

		move.w	#38,DB_DotCount
		lea.l	DB_HeartCoords,a0
		lea.l	DB_Coords(pc),a1
		move.w	DB_DotCount(pc),d7
		subq.w	#1,d7
.copyCoords:
		move.w	(a0)+,d0
		asl.w	#2,d0
		move.w	d0,(a1)+
		move.w	(a0)+,d0
		asl.w	#2,d0
		move.w	d0,(a1)+
		move.w	(a0)+,d0
		asl.w	#2,d0
		move.w	d0,(a1)+
		dbf		d7,.copyCoords

		move.w	#14,DB_DotCount
		move.w	#12,DB_AddDots

		lea.l	DB_HeartPalette(pc),a0
		move.l	a0,DB_PalettePtr
		lea.l	DB_CopCols,a1
		moveq	#8-1,d7
.setCols:
		move.w	(a0)+,2(a1)
		addq.l	#4,a1
		dbf		d7,.setCols

		lea.l	$dff000,a6
    	move.l	#DB_Copper,$80(a6)
		rts

DotBall_InitReturn:
		lea.l	$dff000,a6
    	move.l	#DB_Copper,$80(a6)
		rts

DotBall_Init:
		lea.l	$dff000,a6

		move.l	DrawBuffer,a0
        ; move.l  #(768<<6)+(320>>4),d0
        move.l  #((192*3)<<6)+(320>>4),d0
        jsr		BltClr
		jsr		WaitBlitter

        move.l  DrawBuffer,a0
		lea		DB_BplPtrs+2,a1
        ; move.l	#320*256>>3,d0
        move.l	#320*192>>3,d0
		moveq	#3-1,d1
		jsr		SetBpls

    	move.l	#DB_Copper,$80(a6)

		; Set initial positions
		lea.l	DB_InitialPositions(pc),a0
		move.w	#-160+8,d0	; xpos
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
		moveq	#DB_InitialDots-1,d7
.createCircle:
		move.w	(a1,d6.w),d0
		asr.w	#8,d0
		asr.w	#1,d0
		move.w	d0,(a0)+

		move.w	(a2,d6.w),d0
		asr.w	#8,d0
		asr.w	#1,d0
		move.w	d0,(a0)+

.next:	add.w	#(1024/DB_InitialDots)*2,d6
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
		moveq	#DB_InitialDots-1,d7
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

		; Create scale tables
		lea.l	DB_ScaleTableNeg(pc),a0
		moveq	#127,d0
		moveq	#64-1,d7
.scaleLoopNeg:
		moveq	#0,d1
		move.l	a0,a1
		moveq	#80-1,d6
.scaleLoopInnerNeg:
		move.l	d1,d2
		muls	d0,d2
		asr.w	#6,d2
		move.w	d2,(a1)+
		subq.w	#1,d1
		dbf		d6,.scaleLoopInnerNeg
		lea.l	128*2(a0),a0
		subq.w	#1,d0
		dbf		d7,.scaleLoopNeg

		lea.l	DB_ScaleTablePos(pc),a0
		moveq	#64,d0
		moveq	#64-1,d7
.scaleLoopPos:
		moveq	#0,d1
		move.l	a0,a1
		moveq	#80-1,d6
.scaleLoopInnerPos:
		move.w	d1,d2
		mulu	d0,d2
		lsr.w	#6,d2
		move.w	d2,(a1)+
		addq.w	#1,d1
		dbf		d6,.scaleLoopInnerPos
		lea.l	128*2(a0),a0
		addq.w	#1,d0
		dbf		d7,.scaleLoopPos

		rts

************************************************************
* Run
************************************************************
DotBall_RunHeart:
		movem.l	DrawBuffer,a2-a3
		exg		a2,a3
		movem.l	a2-a3,DrawBuffer

		move.l	a3,a0
		lea		DB_BplPtrs+2,a1
		move.l	#320*192>>3,d0
		moveq	#3-1,d1
		jsr		SetBpls

		move.l	a2,a0
		move.l  #((192*3)<<6)+(320>>4),d0
		jsr		BltClr

		move.l	DB_BallCenterXTablePtr(pc),a0
		moveq	#0,d0
		move.w	(a0),d0
		cmp.w	#-1,d0
		beq.s	.moveDone
		cmp.l	DB_LocalFrameCounter(pc),d0
		bne.s	.moveDone
		move.w	2(a0),DB_BallCenterX
		addq.l	#4,DB_BallCenterXTablePtr

.moveDone:
		; Rotate
		bsr		DB_RotateDots

		add.w	#12,DB_Angles
		add.w	#8,DB_Angles+2
		addq.w	#4,DB_Angles+4

		jsr		WaitBlitter
		bsr		DB_RenderDots

.done:	
		addq.l	#1,DB_LocalFrameCounter
		rts

DotBall_Run:
		movem.l	DrawBuffer,a2-a3
		exg		a2,a3
		movem.l	a2-a3,DrawBuffer

		move.l	a3,a0
		lea		DB_BplPtrs+2,a1
		move.l	#320*192>>3,d0
		moveq	#3-1,d1
		jsr		SetBpls

		move.l	a2,a0
		move.l  #((192*3)<<6)+(320>>4),d0
		jsr		BltClr

		cmp.l	#150,DB_LocalFrameCounter
		ble.s	.doMorph
		cmp.l	#151,DB_LocalFrameCounter
		beq		.scaleUpCoords
		cmp.l	#200,DB_LocalFrameCounter
		beq.s	.addDots1
		cmp.l	#250,DB_LocalFrameCounter
		beq.s	.addDots2
		bra.s	.doRotate
		
.render:
		cmp.l	#300+(DB_BEAT*13),DB_LocalFrameCounter
		beq		.invertPalette

		cmp.l	#300+(DB_BEAT*17),DB_LocalFrameCounter
		beq		.originalPalette
.render2:
		jsr		WaitBlitter
		bsr		DB_RenderDots

.done:	
		addq.l	#1,DB_LocalFrameCounter
		rts

.doMorph:
		cmp.w	#128,DB_CurrentMorphStep
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
		move.w	DB_AddDots,d0
		add.w	d0,DB_DotCount
		bra.s	.doRotate

.addDots2:
		move.w	DB_AddDots,d0
		add.w	d0,DB_DotCount

.doRotate:
		move.l	DB_BallCenterXTablePtr(pc),a0
		moveq	#0,d0
		move.w	(a0),d0
		cmp.w	#-1,d0
		beq.s	.moveDone
		cmp.l	DB_LocalFrameCounter(pc),d0
		bne.s	.moveDone
		move.w	2(a0),DB_BallCenterX
		addq.l	#4,DB_BallCenterXTablePtr

.moveDone:
		; Rotate
		bsr		DB_RotateDots

		addq.w	#8,DB_Angles
		add.w	#12,DB_Angles+2
		addq.w	#4,DB_Angles+4
		bra		.render

.sideScale:
		lea.l	Sintab,a0
		add.w	#24,DB_ScaleSinIndex
		move.w	DB_ScaleSinIndex,d0
		and.w	#$7fe,d0
		move.w	(a0,d0.w),d0
		asr.w	#8,d0
		asr.w	#1,d0
		move.w	d0,DB_ScaleValue

		bra		.render

.invertPalette:
		lea.l	DB_InvertedPalette(pc),a0
		lea.l	DB_CopCols,a1
		moveq	#8-1,d7
.setCols:
		move.w	(a0)+,2(a1)
		addq.l	#4,a1
		dbf		d7,.setCols
		bra		.render2

.originalPalette:
		move.l	DB_PalettePtr(pc),a0
		lea.l	DB_CopCols,a1
		moveq	#8-1,d7
.setCols2:
		move.w	(a0)+,2(a1)
		addq.l	#4,a1
		dbf		d7,.setCols2
		bra		.render2

************************************************************
* Interrupt
************************************************************
DotBall_Interrupt:
		rts

************************************************************
*
* Effect routines
*
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

		move.w	d2,d3
		add.w	#256,d3

        ; Project x
        ext.l   d0
        asl.l   #7,d0
        divs    d3,d0

        ; Project y
        ext.l   d1
		asr.l	#1,d1

		movem.w	d0-d2,(a1)
		addq.l	#6,a1

		dbf		d7,.rotate

		rts

DB_MorphDots:
		lea.l	DB_InitialPositions(pc),a0
		lea.l	DB_TargetPositions(pc),a1
		lea.l	DB_Coords(pc),a2
		lea.l	DB_RotatedCoords(pc),a3

		lea.l	DB_MorphTable(pc),a4
		move.w	DB_CurrentMorphStep(pc),d6
		add.w	d6,d6
		move.w	(a4,d6.w),d6

		moveq	#DB_InitialDots-1,d7
.morph:
		; Morph x
		move.w	(a1)+,d0
		move.w	(a0)+,d1
		sub.w	d1,d0

		muls	d6,d0
		asr.w	#6,d0
		add.w	d1,d0

		move.w	d0,(a2)+
		move.w	d0,(a3)+

		; Morph y
		move.w	(a1)+,d0
		move.w	(a0)+,d1
		sub.w	d1,d0

		muls	d6,d0
		asr.w	#6,d0
		add.w	d1,d0

		move.w	d0,(a2)+
		move.w	d0,(a3)+

		clr.w	(a2)+
		clr.w	(a3)+

		dbf		d7,.morph

		rts

DB_RenderDots:
		PUSH	a6

        move.l  DrawBuffer,a0
		lea.l	(192*2)*40(a0),a0
        lea.l   DB_RotatedCoords(pc),a1
        lea.l   DB_DotMask,a4
        lea.l   Mulu40,a2

		lea.l	DB_ScaleTablePos(pc),a6
		move.w	DB_ScaleValue(pc),d6
		move.w	d6,d0
		asl.w	#8,d0
		lea.l	(a6,d0.w),a6

		move.w	DB_BallCenterX(pc),d0
		subq.w	#8,d0

        move	DB_DotCount(pc),d7
		subq.w	#1,d7
.render:
        move.w  (a1)+,d2

		cmp.w	#0,d6
		beq.s	.scaleDone
		bge.s	.testScaleRight
		cmp.w	#0,d2
		bge.s	.scaleDone
		neg.w	d2
		add.w	d2,d2
		move.w	(a6,d2.w),d2
		bra.s	.scaleDone

.testScaleRight
		cmp.w	#0,d6
		bmi.s	.scaleDone
		cmp.w	#0,d2
		bmi.s	.scaleDone
		add.w	d2,d2
		move.w	(a6,d2.w),d2

.scaleDone:
		add.w	d0,d2
        move.w  d2,d4
        move.w  (a1)+,d3

		move.w	(a1)+,d1 
		asr.w	#5,d1
		add.w	#6,d1
		
		cmp.w	#0,d1
		bge.s	.ok1
		moveq	#0,d1
.ok1:	cmp.w	#9,d1
		ble.s	.ok2
		moveq	#9,d1
.ok2:	
		lsl.w	#6,d1

        add.w   #(192/2)-8,d3
        lsr.w   #3,d2
        and.w   #$fffe,d2
        and.w   #15,d4

		add.w	d4,d4
		add.w	#512,d4
		move.w	(a2,d4.w),d4

		add.w	d1,d4
		lea.l	(a4,d4.w),a3

        add.w   d3,d3
        move.w  (a2,d3.w),d3

        add.w   d2,d3

        lea.l   (a0,d3.w),a5

		; Add shading
		lsr.w	#6,d1
		cmp.w	#2,d1
		ble.b	.renderDot
		lea.l	-192*40(a5),a5
		cmp.w	#4,d1
		ble.b	.renderDot
		lea.l	-192*40(a5),a5

.renderDot:
I       SET     0
        REPT    16
        move.l  (a3)+,d5
        or.l    d5,I(a5)
I       SET     I+40
        ENDR

        dbf     d7,.render

		POP		a6
		rts

************************************************************
*
* Variables and data
*
************************************************************
		even
DB_LocalFrameCounter:		dc.l	0

DB_AddDots:					dc.w	DB_InitialDots-2
DB_DotCount:				dc.w	DB_InitialDots
DB_CurrentMorphStep:		dc.w	0
DB_MorphTable:				dc.w    0, 0, 0, 0, 0, 0, 0, 0
							dc.w    0, 0, 0, 0, 1, 1, 1, 1
							dc.w    2, 2, 2, 2, 3, 3, 3, 4
							dc.w    4, 4, 5, 5, 6, 6, 7, 7
							dc.w    8, 8, 9, 9, 10, 10, 11, 11
							dc.w    12, 13, 13, 14, 15, 15, 16, 17
							dc.w    18, 18, 19, 20, 21, 21, 22, 23
							dc.w    24, 25, 26, 27, 28, 29, 30, 31
							dc.w    32, 33, 34, 35, 35, 36, 37, 38
							dc.w    39, 40, 41, 42, 43, 44, 44, 45
							dc.w    46, 47, 47, 48, 49, 50, 50, 51
							dc.w    52, 52, 53, 53, 54, 55, 55, 56
							dc.w    56, 57, 57, 58, 58, 59, 59, 59
							dc.w    60, 60, 61, 61, 61, 62, 62, 62
							dc.w    62, 63, 63, 63, 63, 64, 64, 64
							dc.w    64, 64, 64, 64, 64, 64, 64, 64
							dc.w	64

DB_Angles:					dc.w	0,0,0
DB_ScaleValue:				dc.w	0
DB_ScaleSinIndex:			dc.w	0

DB_PalettePtr:				dc.l	DB_OriginalPalette
DB_InvertedPalette:			dc.w	$0fed,$0ba9,$0876,$0654
							dc.w	$0432,$0321,$0210,$0000
DB_OriginalPalette:			dc.w	$0012,$0456,$0789,$09ab
							dc.w	$0bcd,$0cde,$0def,$0fff
DB_HeartPalette:			dc.w	$0201,$0645,$0978,$0b9a
							dc.w	$0dbc,$0ecd,$0fde,$0fff

DB_BallCenterX:				dc.w	160
DB_BallCenterXTablePtr:		dc.l	DB_BallCenterXTable

DB_BEAT = 24
DB_BallCenterXTable:		dc.w	300,160-64
							dc.w	300+(DB_BEAT*1),160
							dc.w	300+(DB_BEAT*2),160+64
							dc.w	300+(DB_BEAT*3),160-64
							dc.w	300+(DB_BEAT*4),160+64
							dc.w	300+(DB_BEAT*5),160
							dc.w	300+(DB_BEAT*10),160-64
							dc.w	300+(DB_BEAT*11),160-32
							dc.w	300+(DB_BEAT*12),160
							dc.w	300+(DB_BEAT*13),160+32
							dc.w	300+(DB_BEAT*14),160+64
							dc.w	300+(DB_BEAT*15),160+32
							dc.w	300+(DB_BEAT*16),160
							dc.w	300+(DB_BEAT*18),160-64
							dc.w	300+(DB_BEAT*19),160+64
							dc.w	300+(DB_BEAT*20),160-32
							dc.w	300+(DB_BEAT*21),160+32
							dc.w	300+(DB_BEAT*22),160
							dc.w	-1

DB_InitialPositions:		ds.w	2*20
DB_TargetPositions:			ds.w	2*20

DB_Coords:					ds.w	3*(DB_InitialDots+(2*(DB_InitialDots-2)))
DB_RotatedCoords:			ds.w	3*(DB_InitialDots+(2*(DB_InitialDots-2)))
DB_ScaleTableNeg:			ds.w	128*64
DB_ScaleTablePos:			ds.w	128*64

; Scale macros
SCALEUP:	MACRO
			dc.w	(\1*70)>>6,(\2*70)>>6,\3
			ENDM
SCALEDOWN:	MACRO
			dc.w	(\1*50)>>6,(\2*50)>>6,\3
			ENDM
DB_HeartCoords:				SCALEUP		0,-40,0
							SCALEUP		20,-60,0
							SCALEUP		36,-56,0
							SCALEUP		52,-28,0
							SCALEUP		48,4,0
							SCALEUP		24,20,0
							SCALEUP		12,32,0
							SCALEUP		0,52,0
							SCALEUP		-12,32,0
							SCALEUP		-24,20,0
							SCALEUP		-48,4,0
							SCALEUP		-52,-28,0
							SCALEUP		-36,-56,0
							SCALEUP		-20,-60,0

HEART_Z	SET	-26
							SCALEDOWN	20,-60,HEART_Z
							SCALEDOWN	36,-56,HEART_Z
							SCALEDOWN	52,-28,HEART_Z
							SCALEDOWN	48,4,HEART_Z
							SCALEDOWN	24,20,HEART_Z
							SCALEDOWN	12,32,HEART_Z
							SCALEDOWN	-12,32,HEART_Z
							SCALEDOWN	-24,20,HEART_Z
							SCALEDOWN	-48,4,HEART_Z
							SCALEDOWN	-52,-28,HEART_Z
							SCALEDOWN	-36,-56,HEART_Z
							SCALEDOWN	-20,-60,HEART_Z

HEART_Z	SET	26
							SCALEDOWN	20,-60,HEART_Z
							SCALEDOWN	36,-56,HEART_Z
							SCALEDOWN	52,-28,HEART_Z
							SCALEDOWN	48,4,HEART_Z
							SCALEDOWN	24,20,HEART_Z
							SCALEDOWN	12,32,HEART_Z
							SCALEDOWN	-12,32,HEART_Z
							SCALEDOWN	-24,20,HEART_Z
							SCALEDOWN	-48,4,HEART_Z
							SCALEDOWN	-52,-28,HEART_Z
							SCALEDOWN	-36,-56,HEART_Z
							SCALEDOWN	-20,-60,HEART_Z

************************************************************
*
* Copper
*
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

DB_CopCols:
		dc.w	$0180,$0012
		dc.w	$0182,$0456
		dc.w	$0184,$0789
		dc.w	$0186,$09ab
		dc.w	$0188,$0bcd
		dc.w	$018a,$0cde
		dc.w	$018c,$0def
		dc.w	$018e,$0fff

DB_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000
		dc.w	$00e4,$0000,$00e6,$0000
		dc.w	$00e8,$0000,$00ea,$0000

		dc.b	$2c+32,$01
		dc.w	$fffe
        dc.w    $0100,$3200

		dc.l	$ffdffffe
		dc.b	$2c+32+192-256,$01
		dc.w	$fffe
        dc.w    $0100,$0200

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

DB_DotMask:					ds.l	160*16

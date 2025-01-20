************************************************************
*
* Main routines
*
************************************************************
        SECTION WordWriter, CODE_P

		include	"include/macros.i"

WW_DOTS		= 32

************************************************************
* Initialize
************************************************************
WordWriter_Init:
		lea.l	$dff000,a6

		move.l	ViewBuffer,a0
        move.l  #(768<<6)+(320>>4),d0
        jsr		BltClr
		jsr		WaitBlitter

        move.l  ViewBuffer,a0
		lea		WW_BplPtrs+2,a1
        move.l	#320*256>>3,d0
		moveq	#3-1,d1
		jsr		SetBpls

		move.l	ViewBuffer,WW_TextBuffer

    	move.l	#WW_Copper,$80(a6)

		rts

************************************************************
* Run
************************************************************
WordWriter_Run:
		movem.l	DrawBuffer,a2-a3
		exg		a2,a3
		movem.l	a2-a3,DrawBuffer

		move.l	a3,a0
		lea.l	256*40*2(a0),a0
		lea.l	WW_BplPtrs+2+16,a1
		move.l	#320*256>>3,d0
		moveq	#1-1,d1
		jsr		SetBpls

		move.l	a2,a0
		lea.l	256*40*2(a0),a0
		move.l  #(256<<6)+(320>>4),d0
		jsr		BltClr

		cmp.l	#600,WW_LocalFrameCounter
		bmi.s	.textWriter
		cmp.l	#1500,WW_LocalFrameCounter
		bmi.s	.clearText

.done:
		WAITBLIT
		bsr		RenderDotLineEffect

		rts

.textWriter:
		lea.l	WW_Text(pc),a0
		lea.l	Font,a1
		move.l	WW_TextBuffer,a2
		jsr		TextWriter_Word
		bra.s	.done

.clearText:
		addq.w	#1,WW_ColumnCounter

		bsr		WW_ClearText
		bra.s	.done

************************************************************
* Interrupt
************************************************************
WordWriter_Interrupt:
		addq.l	#1,WW_LocalFrameCounter
		rts

************************************************************
*
* Effect routines
*
************************************************************
WW_ClearText:
		move.l	WW_TextBuffer,a0
		lea.l	70*40(a0),a0

		lea.l	WW_ClearPattern(pc),a1
		lea.l	WW_ClearCounter(pc),a2

		move.w	WW_ColumnCounter,d7
		lsr.w	#2,d7
		cmp.w	#19,d7
		ble.s	.columnLoop
		move.w	#19,d7
.columnLoop:
		move.w	(a2),d0
		cmp.w	#16,d0
		bgt.s	.nextColumn
		and.w	#$f,d0
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		not.w	d0

		move.l	a0,a3
		move.w	#54-1,d6
.clearLoop:
		and.w	d0,(a3)
		and.w	d0,256*40(a3)
		lea.l	40(a3),a3
		dbf		d6,.clearLoop

.nextColumn:
		addq.w	#1,(a2)+
		adda.l	#2,a0
		dbf		d7,.columnLoop
		rts

RenderDotLineEffect:
		move.l	DrawBuffer,a0
		lea.l	256*40*2(a0),a0
		lea.l	WW_Dots(pc),a1
		lea.l	Mulu40,a2

		; Render dots
		moveq	#WW_DOTS-1,d7
.loop:	move.w	(a1),d0
		lsr.w	#4,d0
		move.w	d0,8(a1)
		move.w	2(a1),d1
		lsr.w	#4,d1
		move.w	d1,10(a1)

		add.w	d1,d1
		move.w	(a2,d1.w),d1

		move.w	d0,d2
		lsr.w	#3,d0
		add.w	d0,d1
		
		and.b	#$7,d2
		not.b	d2
		bset.b	d2,(a0,d1.w)

		move.w	(a1),d0
		add.w	4(a1),d0
		tst.w	d0
		bge.s	.xOk
		add.w	#320*16,d0
.xOk:	cmp.w	#320*16,d0
		bmi.s	.xOk2
		sub.w	#320*16,d0
.xOk2:	move.w	d0,(a1)

		move.w	2(a1),d0
		add.w	6(a1),d0
		tst.w	d0
		bge.s	.yOk
		add.w	#256*16,d0
.yOk:	cmp.w	#256*16,d0
		bmi.s	.yOk2
		sub.w	#256*16,d0
.yOk2:	move.w	d0,2(a1)

		adda.l	#12,a1

		dbf		d7,.loop

		; Render lines
		jsr		DL_Init
		
		lea.l	WW_Dots(pc),a2
		adda.l	#8,a2

		moveq	#WW_DOTS-1,d7
.outer:
		tst.w	d7
		beq		.done

		lea.l	12(a2),a3
		move.w	d7,d6
		subq.w	#1,d6
.inner:

		; Calculate Chebyshev Distance
		move.w	(a2),d0
		sub.w	(a3),d0
		bpl.s	.lxOk
		neg.w	d0
.lxOk: 
		move.w	2(a2),d1
		sub.w	2(a3),d1
		bpl.s	.lyOk
		neg.w	d1
.lyOk:
		cmp.w	d0,d1
		ble.s	.ok
		exg		d0,d1
.ok:
		; If distance between 2 points is less than 40 px, render line
		cmp.w	#40,d0
		bgt		.skip

		; Drawline
		move.l	DrawBuffer,a0
		lea.l	256*40*2(a0),a0
		move.w	(a2),d0
		move.w	2(a2),d1
		move.w	(a3),d2
		move.w	2(a3),d3
		moveq	#40,d4
		jsr		DrawLine

.skip:	lea.l	12(a3),a3
		dbf		d6,.inner
		lea.l	12(a2),a2
		dbf		d7,.outer
.done:
		rts

************************************************************
*
* Variables and data
*
************************************************************
		even
WW_TextBuffer:				dc.l	0
WW_LocalFrameCounter:		dc.l	0
WW_ClearCounter:			dc.w	0,0,0,0,0,0,0,0,0,0
							dc.w	0,0,0,0,0,0,0,0,0,0
WW_ColumnCounter:			dc.w	0
WW_ClearPattern:			dc.w	$8000,$c000,$e000,$f000
							dc.w	$f800,$fc00,$fe00,$ff00
							dc.w	$ff80,$ffc0,$ffe0,$fff0
							dc.w	$fff8,$fffc,$fffe,$ffff

WW_Dots:					dc.w 3984,480,-15,-14,0,0
							dc.w 3840,1104,-4,-11,0,0
							dc.w 3328,3680,7,-11,0,0
							dc.w 1856,224,-7,9,0,0
							dc.w 4848,2944,-13,-12,0,0
							dc.w 3904,832,5,-11,0,0
							dc.w 3120,2192,3,7,0,0
							dc.w 3280,1248,-11,-1,0,0
							dc.w 16,2560,-1,-10,0,0
							dc.w 336,1488,13,2,0,0
							dc.w 224,3584,-14,-6,0,0
							dc.w 4400,3296,10,5,0,0
							dc.w 3792,608,-9,-1,0,0
							dc.w 3984,2032,2,-2,0,0
							dc.w 3232,2432,6,-1,0,0
							dc.w 3216,2016,-5,0,0,0
							dc.w 768,2160,-3,14,0,0
							dc.w 4880,3696,9,-6,0,0
							dc.w 1808,3488,-8,-8,0,0
							dc.w 4576,336,-14,1,0,0
							dc.w 4992,1456,6,4,0,0
							dc.w 1440,1680,15,1,0,0
							dc.w 1584,1376,1,2,0,0
							dc.w 2848,1392,-13,-4,0,0
							dc.w 1808,816,-10,10,0,0
							dc.w 1344,1136,1,-9,0,0
							dc.w 2960,16,5,-12,0,0
							dc.w 928,3792,10,15,0,0
							dc.w 4320,1600,-9,-11,0,0
							dc.w 800,3872,9,-11,0,0
							dc.w 1680,2496,13,2,0,0
							dc.w 2992,464,9,-8,0,0

					;0123456789012345678901234567890123456789
WW_Text:	dc.b	10,10,10,10,10 ;,10,10,10,10,10
			dc.b	'MY',5,10,' GENERATION ',5,10,'WROTE ',5,10,'A ',5,10,'NEW ',5,30,'TYPE ',5,10,'OF ',5,10,'DIARY.',10
			dc.b	'WITH',5,10,2,' PIXELS',5,10,',',5,10,2,' CODE',5,30,', ',5,10,2,'CHIP ',5,10,'SOUNDS ',5,10,1,'AND ',5,10,'FLAT',10
			dc.b	' OUT ',5,30,'SHARED ',5,10,'AMAZEMENT ',5,10,'ON ',5,10,'WHAT ',5,10,'COULD ',5,30,'BE',10
			dc.b	'    ',5,10,'DONE ',5,10,'ON ',5,10,'A ',5,10,'HOME ',5,30,'COMPUTER. ',5,10,'WE ',5,10,'WERE ',10
			dc.b	10,5,100,3
			dc.b	'        ... THE',5,50,' LOWRES',5,50,' KIDS ...',0
************************************************************
*
* Copper
*
************************************************************
        SECTION WW_Copper, CODE_C

WW_Copper:
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
		dc.w	$0182,$0678
		dc.w	$0184,$0966
		dc.w	$0186,$0cde

		dc.w	$0188,$0234
		dc.w	$018a,$0678
		dc.w	$018c,$0966
		dc.w	$018e,$0cde

        dc.w    $0100,$3200
WW_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000
		dc.w	$00e4,$0000,$00e6,$0000
		dc.w	$00e8,$0000,$00ea,$0000

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe



 
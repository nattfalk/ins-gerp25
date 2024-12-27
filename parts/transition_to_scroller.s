************************************************************
* Main routines
************************************************************
        SECTION TransitionToScroller, CODE_P

		include	"include/macros.i"
		include	"parts/sine_scroller.i"

FADE_STEPS_UP	=	2
FADE_STEPS_DOWN	=	16
FADE_STEPS		=	FADE_STEPS_UP+FADE_STEPS_DOWN

TransitionToScroller_Init:
		lea.l	$dff000,a6

    	move.l	#TTS_Copper,$80(a6)

		lea.l	TTS_ShadeTable(pc),a0
		lea.l	TTS_ToColors(pc),a1
		moveq	#8-1,d7
.createShades:
		PUSH	d7

		move.w	(a1)+,d0
		move.w	TTS_HighLightColor(pc),d1
		moveq	#FADE_STEPS_UP,d2
		jsr		CreateShadeTable

		move.w	TTS_HighLightColor(pc),d0
		move.w	(a1),d1
		moveq	#FADE_STEPS_DOWN,d2
		jsr		CreateShadeTable

		POP		d7
		dbf		d7,.createShades

		rts

TransitionToScroller_Run:
		lea.l	TTS_FadeTablePtr(pc),a0
		move.l	(a0),a0

		move.l	(a0),d0
		cmp.l	#-1,d0
		beq.s	.done
		cmp.l	#FADE_STEPS,d0
		bne.s	.doFade
		add.l	#18*4,TTS_FadeTablePtr
		bra.s	TransitionToScroller_Run

.doFade:
		move.l	d0,d1
		add.w	d1,d1
		addq.l	#1,d0
		move.l	d0,(a0)+
		move.l	(a0)+,a1
		move.w	(a1,d1.w),d0

		moveq	#16-1,d7
.fadeLoop:
		move.l	(a0)+,a2
		cmp.l	#-1,a2
		beq.s	.skip

		move.w	d0,(a2)

.skip:	dbf		d7,.fadeLoop

.done:
		rts

TransitionToScroller_Interrupt:
		addq.l	#1,TTS_LocalFrameCounter

		rts

************************************************************
* Effect routines
************************************************************

************************************************************
* Variables and data
************************************************************
		even
TTS_LocalFrameCounter:
					dc.l	0

TTS_HighLightColor:	dc.w	$0fff
TTS_ToColors:		dc.w	$0000
					dc.w	$0fed,$0fda,$0fb6,$0d86,$0978,$0556,$0245,$0134

TTS_FadeTablePtr:	dc.l	TTS_FadeTable
TTS_FadeTable:		dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*0)
					dc.l	TTS_COL_00,TTS_COL_01,TTS_COL_10,TTS_COL_11,TTS_COL_20,TTS_COL_21
					dc.l	TTS_COL_30,TTS_COL_31,TTS_COL_40,TTS_COL_41,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1
					
					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*1)
					dc.l	-1,-1,TTS_COL_10,TTS_COL_11,TTS_COL_20,TTS_COL_21
					dc.l	TTS_COL_30,TTS_COL_31,TTS_COL_40,TTS_COL_41,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*2)
					dc.l	-1,-1,-1,-1,TTS_COL_20,TTS_COL_21
					dc.l	TTS_COL_30,TTS_COL_31,TTS_COL_40,TTS_COL_41,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*3)
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	TTS_COL_30,TTS_COL_31,TTS_COL_40,TTS_COL_41,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*4)
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	-1,-1,TTS_COL_40,TTS_COL_41,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*5)
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	-1,-1,-1,-1,TTS_COL_50,TTS_COL_51
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*6)
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	TTS_COL_60,TTS_COL_61,TTS_COL_70,-1

					dc.l	0,TTS_ShadeTable+(FADE_STEPS*2*7)
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	-1,-1,-1,-1,-1,-1
					dc.l	-1,-1,TTS_COL_70,-1

					dc.l	-1

TTS_ShadeTable:		dcb.w	FADE_STEPS*8

************************************************************
* Copper
************************************************************
        SECTION TTS_Copper, CODE_C

TTS_Copper:
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

		dc.w	$0180
TTS_COL_00:
		dc.w	$0fed

		SS_CALCY	-1,-6
		dc.w	$fffe,$0180
TTS_COL_10:
		dc.w	$0fda

		SS_CALCY	-1,-5
		dc.w	$fffe,$0180
TTS_COL_20:
		dc.w	$0fb6

		SS_CALCY	-1,-4
		dc.w	$fffe,$0180
TTS_COL_30:
		dc.w	$0d86

		SS_CALCY	-1,-3
		dc.w	$fffe,$0180
TTS_COL_40:
		dc.w	$0978

		SS_CALCY	-1,-2
		dc.w	$fffe,$0180
TTS_COL_50:
		dc.w	$0556

		SS_CALCY	-1,-1
		dc.w	$fffe,$0180
TTS_COL_60:
		dc.w	$0245

		SS_CALCY	-1,0
		dc.w	$fffe
		dc.w	$0180
TTS_COL_70:
		dc.w	$0134

		SS_CALCY	1,0
		dc.w	$fffe,$0180
TTS_COL_61:
		dc.w	$0245
		
		SS_CALCY	1,1
		dc.w	$fffe,$0180
TTS_COL_51:
		dc.w	$0556
		
		SS_CALCY	1,2
		dc.w	$fffe,$0180
TTS_COL_41:
		dc.w	$0978
		
		dc.w	$ffdf,$fffe

		SS_CALCY	1,3
		dc.w	$fffe,$0180
TTS_COL_31:
		dc.w	$0d86
		
		SS_CALCY	1,4
		dc.w	$fffe,$0180
TTS_COL_21:
		dc.w	$0fb6

		SS_CALCY	1,5
		dc.w	$fffe,$0180
TTS_COL_11:
		dc.w	$0fda

		SS_CALCY	1,6
		dc.w	$fffe,$0180
TTS_COL_01:
		dc.w	$0fed

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

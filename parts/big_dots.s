************************************************************
* Main routines
************************************************************
        SECTION BigDots, CODE_P

		include	"include/macros.i"

BigDots_Init:
		lea.l	$dff000,a6

    	move.l	#BD_Copper,$80(a6)

		rts

BigDots_Run:
.done:	rts

BigDots_Interrupt:
		addq.l	#1,BD_LocalFrameCounter
		rts

************************************************************
* Effect routines
************************************************************

************************************************************
* Variables and data
************************************************************
		even
BD_LocalFrameCounter:
					dc.l	0

************************************************************
* Copper
************************************************************
        SECTION BD_Copper, CODE_C

BD_Copper:
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

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

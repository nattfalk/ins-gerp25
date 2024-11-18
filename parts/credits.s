************************************************************
        SECTION Credits, CODE_P

        include	"include/blitter.i"

Credits_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr	BltClr
	jsr	WaitBlitter

        move.l  DrawBuffer,a0
        lea.l   C_BplPtrs,a1
        moveq   #2-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #320*256>>3,a0
        adda.l  #8,a1
        dbf     d7,.setBpls

    	move.l	#C_Copper,$80(a6)
        rts

************************************************************
Credits_Run:

        jsr	WaitBlitter

        move.w	#SRCA|DEST|A_TO_D|((16-2)<<ASHIFTSHIFT),bltcon0(a6)
        move.w	#0,bltcon1(a6)
        move.l	ViewBuffer,bltapt(a6)
        move.w	#0,bltamod(a6)
        move.l	DrawBuffer,bltdpt(a6)
        move.w	#0,bltdmod(a6)
        move.l	#-1,bltafwm(a6)
        move.w	#(256<<HSIZEBITS)|20,bltsize(a6)

        jsr	WaitBlitter

        move.w	#SRCA|DEST|A_TO_D|((16-2)<<ASHIFTSHIFT),bltcon0(a6)
        move.w	#0,bltcon1(a6)
        move.l	ViewBuffer,bltapt(a6)
        move.w	#0,bltamod(a6)
        move.l	DrawBuffer,bltdpt(a6)
        move.w	#0,bltdmod(a6)
        move.l	#-1,bltafwm(a6)
        move.w	#(256<<HSIZEBITS)|20,bltsize(a6)

        rts

************************************************************
Credits_Interrupt:
        addq.l  #1,C_LocalFrameCounter

        rts

************************************************************
        even
C_LocalFrameCounter:   dc.l    0

************************************************************
        SECTION C_Copper, CODE_C
C_Copper:
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
        dc.w    $0100,$0200

	dc.w	$0180,$0222
	dc.w	$0182,$0fff

        dc.w    $0100,$2200
C_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

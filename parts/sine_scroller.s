************************************************************
* Main routines
************************************************************
        SECTION SineScroller, CODE_P

SS_FontHeight		= 24

		include	"include/blitter.i"

SineScroller_Init:
		lea.l	$dff000,a6

		move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr		BltClr
		jsr		WaitBlitter

        move.l  DrawBuffer,a0
        move.l  ViewBuffer,a1
        move.w  #320*256>>5,d7
.fill:  move.l  #0,(a0)+
        move.l  #0,(a1)+
        dbf     d7,.fill

        move.l  ViewBuffer,a0
		lea		SS_BplPtrs+2,a1
        move.l  #6*40,d0
		moveq	#2-1,d1
		jsr		SetBpls

    	move.l	#SS_Copper,$80(a6)

		lea.l	Sintab,a0
		lea.l	SS_CustomSinTab(pc),a1
		move.w	#1024-1,d7
.calc:	move.w	(a0)+,d0
		asr.w	#8,d0
		asr.w	#3,d0
		muls	#40,d0
		move.w	d0,(a1)+
		dbf		d7,.calc

		lea.l	Font,a0
		lea.l	SS_CustomFont,a1
		move.w	#520-1,d7
.scaleFont:
		move.b	(a0)+,d0
		REPT	SS_FontHeight/8
		move.b	d0,(a1)+
		ENDR

		; REPT	4
		; move.b	(a0),(a1)+
		; move.b	(a0),(a1)+
		; move.b	(a0)+,(a1)+
		; move.b	(a0),(a1)+
		; move.b	(a0)+,(a1)+
		; ENDR

		dbf		d7,.scaleFont

		lea.l	SS_TextBuf,a0
		move.l	#42*SS_FontHeight-1,d7
.fillLoop:
		move.b	#0,(a0)+
		dbf		d7,.fillLoop

		rts

SineScroller_Run:
		movem.l	DrawBuffer,a2-a3
		exg		a2,a3
		movem.l	a2-a3,DrawBuffer

		move.l	a3,a0
		lea		SS_BplPtrs+2,a1
		; moveq   #0,d0
        move.l  #6*40,d0
		moveq	#2-1,d1
		jsr		SetBpls

		move.l	a2,a0
		; move.l  #(256<<6)+(320>>4),d0
		; lea.l	(128-30)*40(a0),a0
		jsr		WaitBlitter
		move.l  #(90<<6)+(320>>4),d0
		jsr		BltClr

		move.l	SS_LocalFrameCounter,d0
		and.w	#3,d0
		bne.s	.skipPrint
		bsr		SS_PrintChar
.skipPrint:
		bsr		SS_Scroll

		lea.l	SS_TextBuf,a0
		move.l	DrawBuffer,a1
		lea.l	35*40(a1),a1
		lea.l	SS_CustomSinTab,a2
		move.l	SS_SinIndex(pc),d0
		move.l	#12<<16|22,d4
		bsr		SS_BlitSineScroller
		
		rts

SineScroller_Interrupt:
		addq.l	#1,SS_LocalFrameCounter
		add.l	#12<<16|4,SS_SinIndex
		rts

************************************************************
* Effect routines
************************************************************
SS_PrintChar:
		move.l	SS_TextPtr(pc),a0
.testReset:
		move.b	(a0),d0
		bne.s	.print
		move.l	#SS_Text,SS_TextPtr
		move.l	SS_TextPtr(pc),a0
		bra		.testReset
.print:	addq.l	#1,SS_TextPtr
		sub.b	#' ',d0
        and.w   #$ff,d0
		mulu	#SS_FontHeight,d0

		lea.l	SS_CustomFont,a1
		lea.l	(a1,d0.w),a1
		move.l	#SS_TextBuf+40,a2

I       SET     0
        REPT    SS_FontHeight
        move.b  I(a1),I*42(a2)
I       SET     I+1
        ENDR

		rts

SS_Scroll:
		jsr		WaitBlitter

		move.w	#SRCA|DEST|A_TO_D|((16-2)<<ASHIFTSHIFT),bltcon0(a6)
		move.w	#0,bltcon1(a6)
		move.l	#SS_TextBuf+2,bltapt(a6)
		move.w	#0,bltamod(a6)
		move.l	#SS_TextBuf,bltdpt(a6)
		move.w	#0,bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(SS_FontHeight<<HSIZEBITS)|21,bltsize(a6)

		rts

; A0 = PlanePtr (src)
; A1 = PlanePtr (dest)
; A2 = Sinetable
; D0 = Framecounter
; D4 = Speed
		even
SS_BlitSineScroller:
		jsr		WaitBlitter
		move.w	#SRCA|SRCB|DEST|A_OR_B,bltcon0(a6)
		move.w	#0,bltcon1(a6) 		;BC1F_DESC,bltcon1(a6)
		move.w	#40,bltamod(a6)
		move.w	#38,bltbmod(a6)
		move.w	#38,bltdmod(a6)

		moveq	#0,d1
		moveq	#0,d2

		move.l	#(320/16)-1,d7
.outerLoop:
		move.l	#$80008000,d5		; Mask

		moveq	#16-1,d6
.innerLoop:
		swap	d0
		andi.w	#$7fe,d0
		move.w	(a2,d0.w),d1
		swap	d0
		andi.w	#$7fe,d0
		add.w	(a2,d0.w),d1
		ext.l	d1

		move.l	d2,d3
		lsr.w	#3,d3
		and.l	#$fe,d3

		; jsr		WaitBlitter

		move.l	a0,a3
		add.l	d3,a3
		move.l	a3,bltapth(a6)

		move.l 	a1,a3				; Store destination in a3
		add.l	d1,a3				; Add y-position to destination
		add.l	d3,a3
		move.l 	a3,bltbpth(a6)

		move.l	a3,bltdpth(a6)
		move.l	d5,bltafwm(a6)
		move.w	#(SS_FontHeight<<6)+1,bltsize(a6)

		addq.w	#1,d2
		lsr.l	#1,d5

		add.w	d4,d0
		swap	d0
		swap	d4
		add.w	d4,d0
		swap	d0
		swap	d4
		
		dbf		d6,.innerLoop
		dbf		d7,.outerLoop

		rts

************************************************************
* Variables and data
************************************************************
		even
SS_LocalFrameCounter:
					dc.l	0
SS_SinIndex:		dc.w	0,0

SS_CustomSinTab:	ds.w	1024
							;0123456789012345678901234567890123456789
SS_Text:			dc.b	'... PRESENTED AT - GERP 2025 - ... INSANE '
					dc.b	'HERE AGAIN WITH ANOTHER AMIGA OCS PRODUCTION.'
					dc.b	' ...',0
					even
SS_TextPtr:			dc.l	SS_Text
************************************************************
* Copper
************************************************************
        SECTION SS_Copper, CODE_C
SS_Copper:
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

		dc.w	$0180,$0000
		dc.w	$0182,$0242
		dc.w	$0184,$0beb
		dc.w	$0186,$0beb

		dc.w	$8e01,$fffe
		dc.w	$0180,$0473
		dc.w    $0100,$2200
SS_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000
		dc.w	$00e4,$0000,$00e6,$0000

		dc.w	$e801,$fffe
		dc.w	$0100,$0200
		dc.w	$0180,$0000

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

		even
SS_TextBuf:		
		ds.w	42*SS_FontHeight
SS_CustomFont:
		ds.b	520*3
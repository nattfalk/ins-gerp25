************************************************************
* Main routines
************************************************************
        SECTION SineScroller, CODE_P

SS_FONT_HEIGHT		= 16

		include	"include/blitter.i"

SineScroller_Init:
		lea.l	$dff000,a6

		move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr		BltClr
		WAITBLIT

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
		IFNE	SS_FONT_HEIGHT-20
		move.b	(a0)+,d0
		REPT	SS_FONT_HEIGHT/8
		move.b	d0,(a1)+
		ENDR
		ENDC

		IFEQ	SS_FONT_HEIGHT-20
		; Use for FontHeight = 20
		REPT	4
		move.b	(a0),(a1)+
		move.b	(a0),(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0),(a1)+
		move.b	(a0)+,(a1)+
		ENDR
		ENDC

		dbf		d7,.scaleFont

		lea.l	SS_TextBuf,a0
		move.l	#42*SS_FONT_HEIGHT-1,d7
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
        move.l  #6*40,d0
		moveq	#2-1,d1
		jsr		SetBpls

		move.l	a2,a0
		jsr		WaitBlitter
		move.l  #(90<<6)+(320>>4),d0
		jsr		BltClr

		move.l	SS_LocalFrameCounter,d0
		and.w	#7,d0
		bne.s	.skipPrint
		bsr		SS_PrintChar
.skipPrint:
		bsr		SS_Scroll

		lea.l	SS_TextBuf,a0
		move.l	DrawBuffer,a1
		lea.l	35*40(a1),a1
		lea.l	SS_CustomSinTab,a2
		move.l	SS_SinIndex(pc),d0
		move.l	#16<<16|32,d4
		bsr		SS_BlitSineScroller
		WAITBLIT

		bsr		SS_CopperWave

		rts

SineScroller_Interrupt:
		addq.l	#1,SS_LocalFrameCounter
		add.l	#12<<16|4,SS_SinIndex

		rts

************************************************************
* Effect routines
************************************************************
SS_CopperWave:
		lea.l	SS_WaveTable(pc),a0
		move.w	SS_WaveTableIndex(pc),d0
		cmp.w	#512,d0
		beq.s	.done
		addq.w	#2,SS_WaveTableIndex

		lea.l	SS_YStartTable(pc),a1

		move.w	(a0,d0.w),d0
		add.w	#70,d0

		move.w	#$2c<<3,d1

		moveq	#7-1,d7
.loop:	
		add.w	d0,d1
		move.w	d1,d2
		lsr.w	#3,d2
		move.l	(a1)+,a2
		move.b	d2,(a2)
		dbf		d7,.loop

		add.w	#90,d2
		move.b	d2,SS_YStop1

		and.w	#$ff,d2
		move.w	d2,d3
		
		sub.w	#$2c,d3
		move.w	#$ff,d4
		sub.w	d3,d4
		lsl.w	#3,d2

		lea.l	SS_YStopTable(pc),a1
		moveq	#6-1,d7
.loop2:	move.l	(a1)+,a2
		add.w	d4,d2
		move.w	d2,d0
		lsr.w	#3,d0

		move.w	d0,d1
		and.w	#$f00,d1
		beq.s	.noExtra
		move.w	#$ffdf,(a2)+
		move.w	#$fffe,(a2)+
		sub.w	#$ff,d0
		sub.w	#$ff<<3,d2
		bra.s	.setY
.noExtra:
		move.w	#$0182,(a2)+
		move.w	#$0000,(a2)+
.setY:	move.b	d0,(a2)
		dbf		d7,.loop2

.done:	rts

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
		mulu	#SS_FONT_HEIGHT,d0

		lea.l	SS_CustomFont,a1
		lea.l	(a1,d0.w),a1
		move.l	#SS_TextBuf+40,a2

I       SET     0
        REPT    SS_FONT_HEIGHT
        move.b  I(a1),I*42(a2)
I       SET     I+1
        ENDR

		rts

SS_Scroll:
		WAITBLIT

		move.w	#SRCA|DEST|A_TO_D|((16-1)<<ASHIFTSHIFT),bltcon0(a6)
		move.w	#0,bltcon1(a6)
		move.l	#SS_TextBuf+2,bltapt(a6)
		move.w	#0,bltamod(a6)
		move.l	#SS_TextBuf,bltdpt(a6)
		move.w	#0,bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(SS_FONT_HEIGHT<<HSIZEBITS)|21,bltsize(a6)

		rts

; A0 = PlanePtr (src)
; A1 = PlanePtr (dest)
; A2 = Sinetable
; D0 = Framecounter
; D4 = Speed
		even
SS_BlitSineScroller:
		WAITBLIT

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

		WAITBLIT
		
		move.l	a0,a3
		add.l	d3,a3
		move.l	a3,bltapth(a6)

		move.l 	a1,a3				; Store destination in a3
		add.l	d1,a3				; Add y-position to destination
		add.l	d3,a3
		move.l 	a3,bltbpth(a6)

		move.l	a3,bltdpth(a6)
		move.l	d5,bltafwm(a6)
		move.w	#(SS_FONT_HEIGHT<<6)+1,bltsize(a6)

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
SS_Text:			dc.b	' -INSANE- ... AT GERP 2025 ...'
					dc.b	' WITH LOVE AND INSANITY ... ANOTHER YEAR, '
					dc.b	'ANOTHER PROD ... PEACE OUT!    ',0
					even
SS_TextPtr:			dc.l	SS_Text

SS_YStartTable:		dc.l	SS_YStart1,SS_YStart2,SS_YStart3,SS_YStart4
					dc.l	SS_YStart5,SS_YStart6,SS_YStart7
SS_YStopTable:		dc.l	SS_YStop2,SS_YStop3,SS_YStop4,SS_YStop5
					dc.l	SS_YStop6,SS_YStop7

SS_WaveTableIndex:	dc.w	0
SS_WaveTable:
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(70*sin((8*PI/256)*x-PI/2)*exp(-x/64))
;variable:
;   name:x
;   startValue:0
;   endValue:255
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 8
;--------------------------------
;- DO NOT MODIFY following lines -
 ; -> SIGNED values <-
 dc.w $ffba, $ffbb, $ffbd, $ffc0, $ffc3, $ffc7, $ffcb, $ffcf
 dc.w $ffd4, $ffd9, $ffdf, $ffe4, $ffea, $ffef, $fff5, $fffb
 dc.w $0000, $0005, $000a, $000f, $0014, $0018, $001c, $001f
 dc.w $0022, $0025, $0027, $0028, $002a, $002b, $002b, $002b
 dc.w $002a, $002a, $0028, $0027, $0025, $0023, $0020, $001d
 dc.w $001a, $0017, $0014, $0011, $000d, $000a, $0007, $0003
 dc.w $0000, $fffd, $fffa, $fff7, $fff4, $fff2, $ffef, $ffed
 dc.w $ffeb, $ffea, $ffe8, $ffe7, $ffe7, $ffe6, $ffe6, $ffe6
 dc.w $ffe6, $ffe7, $ffe8, $ffe8, $ffea, $ffeb, $ffed, $ffee
 dc.w $fff0, $fff2, $fff4, $fff6, $fff8, $fffa, $fffc, $fffe
 dc.w $0000, $0002, $0004, $0006, $0007, $0009, $000a, $000b
 dc.w $000d, $000d, $000e, $000f, $000f, $0010, $0010, $0010
 dc.w $0010, $000f, $000f, $000e, $000e, $000d, $000c, $000b
 dc.w $000a, $0009, $0007, $0006, $0005, $0004, $0002, $0001
 dc.w $0000, $ffff, $fffe, $fffd, $fffc, $fffb, $fffa, $fff9
 dc.w $fff8, $fff8, $fff7, $fff7, $fff7, $fff6, $fff6, $fff6
 dc.w $fff7, $fff7, $fff7, $fff7, $fff8, $fff8, $fff9, $fff9
 dc.w $fffa, $fffb, $fffb, $fffc, $fffd, $fffe, $ffff, $ffff
 dc.w $0000, $0001, $0001, $0002, $0003, $0003, $0004, $0004
 dc.w $0005, $0005, $0005, $0005, $0006, $0006, $0006, $0006
 dc.w $0006, $0006, $0005, $0005, $0005, $0005, $0004, $0004
 dc.w $0004, $0003, $0003, $0002, $0002, $0001, $0001, $0000
 dc.w $0000, $0000, $ffff, $ffff, $fffe, $fffe, $fffe, $fffd
 dc.w $fffd, $fffd, $fffd, $fffd, $fffd, $fffd, $fffc, $fffc
 dc.w $fffd, $fffd, $fffd, $fffd, $fffd, $fffd, $fffd, $fffe
 dc.w $fffe, $fffe, $fffe, $ffff, $ffff, $ffff, $ffff, $0000
 dc.w $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0002
 dc.w $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002
 dc.w $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0001
 dc.w $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000
 dc.w $0000, $0000, $0000, $0000, $ffff, $ffff, $ffff, $ffff
 dc.w $ffff, $ffff, $ffff, $ffff, $ffff, $ffff, $ffff, $ffff
;@generated-datagen-end----------------

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
		dc.w	$0102,$0003		; 3 pixels offset for text shadow
		dc.w	$0104,$0000
		dc.w	$0108,$0000
		dc.w	$010a,$0000

* 0134
* 0245
* 0556
* 0978
* 0d86
* 0fb6
* 0fda
* 0fed

		dc.w	$0180,$0fed
		dc.w	$0182,$0556
		dc.w	$0184,$0ddd
		dc.w	$0186,$0ddd

SS_YStart1:
		dc.b	$2c+$d,$01
		dc.w	$fffe,$0180,$0fda

SS_YStart2:
		dc.b	$2c+($d*2),$01
		dc.w	$fffe,$0180,$0fb6

SS_YStart3:
		dc.b	$2c+($d*3),$01
		dc.w	$fffe,$0180,$0d86

SS_YStart4:
		dc.b	$2c+($d*4),$01
		dc.w	$fffe,$0180,$0978

SS_YStart5:
		dc.b	$2c+($d*5),$01
		dc.w	$fffe,$0180,$0556

SS_YStart6:
		dc.b	$2c+($d*6),$01
		dc.w	$fffe,$0180,$0245

SS_YStart7:
		dc.w	$8e01,$fffe
		dc.w	$0180,$0134
		dc.w    $0100,$2200
SS_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000
		dc.w	$00e4,$0000,$00e6,$0000

SS_YStop1:
		dc.w	$e801,$fffe
		dc.w	$0100,$0200
		dc.w	$0180,$0245
SS_YStop2:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0556
SS_YStop3:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0978
SS_YStop4:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0d86
SS_YStop5:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0fb6
SS_YStop6:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0fda
SS_YStop7:
		dc.w	$0190,$0000
		dc.w	$e801,$fffe
		dc.w	$0180,$0fed

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

		even
SS_TextBuf:		
		ds.w	42*SS_FONT_HEIGHT
SS_CustomFont:
		ds.b	520*3
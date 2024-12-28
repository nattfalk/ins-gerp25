************************************************************
* Main routines
************************************************************
        SECTION SineScroller, CODE_P

SS_FONT_HEIGHT		= 	16

SS_FADE_STEPS_UP	=	16
SS_FADE_STEPS_DOWN	=	2
SS_FADE_STEPS		=	SS_FADE_STEPS_UP+SS_FADE_STEPS_DOWN

SS_NO_COLORS		=	13

		include	"include/macros.i"
		include	"include/blitter.i"
		include	"parts/sine_scroller.i"

SineScroller_Init:
		lea.l	$dff000,a6

		; Clear buffers
		move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr		BltClr
		WAITBLIT
		move.l	ViewBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr		BltClr
		WAITBLIT

		; Display viewbuffer
        move.l  ViewBuffer,a0
		lea		SS_BplPtrs+2,a1
        move.l  #6*40,d0
		moveq	#2-1,d1
		jsr		SetBpls

    	move.l	#SS_Copper,$80(a6)

		; Create custom scaled sin table
		lea.l	Sintab,a0
		lea.l	SS_CustomSinTab(pc),a1
		move.w	#1024-1,d7
.calc:	move.w	(a0)+,d0
		asr.w	#8,d0
		asr.w	#3,d0
		muls	#40,d0
		move.w	d0,(a1)+
		dbf		d7,.calc

		; Scale up font
		lea.l	Font,a0
		lea.l	SS_CustomFont,a1
		moveq	#0,d0
		move.w	#520-1,d7
.scaleFont:
		IFNE	SS_FONT_HEIGHT-20
		move.b	(a0)+,d0
		lsl.w	#8,d0
		REPT	SS_FONT_HEIGHT/8
		move.w	d0,(a1)+
		ENDR
		ENDC

		IFEQ	SS_FONT_HEIGHT-20
		; Use for FontHeight = 20
		REPT	4
		move.b	(a0),d0
		lsl.w	#8,d0
		move.w	d0,(a1)+
		move.w	d0,(a1)+
		move.w	d0,(a1)+
		addq.l	#1,a0
		move.b	(a0),d0
		lsl.w	#8,d0
		move.w	d0,(a1)+
		move.w	d0,(a1)+
		addq.l	#1,a0
		ENDR
		ENDC

		dbf		d7,.scaleFont

		; Clear text buffer
		lea.l	SS_TextBuf,a0
		move.l	#42*SS_FONT_HEIGHT-1,d7
.fillLoop:
		move.b	#0,(a0)+
		dbf		d7,.fillLoop

		; Create shade tables
		lea.l	SS_ShadeTable(pc),a0
		lea.l	SS_FromColors(pc),a1
		moveq	#SS_NO_COLORS-1,d7
.createShades:
		PUSH	d7

		move.w	(a1)+,d0
		move.w	SS_HighLightColor(pc),d1
		moveq	#SS_FADE_STEPS_UP,d2
		jsr		CreateShadeTable

		move.w	SS_HighLightColor(pc),d0
		move.w	SS_ToColor(pc),d1
		moveq	#SS_FADE_STEPS_DOWN,d2
		jsr		CreateShadeTable

		POP		d7
		dbf		d7,.createShades

		rts

SineScroller_Run:
		addq.l	#1,SS_LocalRunFrameCounter

		tst.b	SS_ScrollTextDone
		bne.s	.doFadeOut

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

		move.l	SS_LocalRunFrameCounter,d0
		and.w	#7,d0
		bne.s	.skipPrint
		bsr		SS_PrintChar
.skipPrint:
		bsr		SS_Scroll

		bsr		SS_BlitSineScroller
		WAITBLIT

.doCopperWave:
		bsr		SS_CopperWave
		rts

.doFadeOut:
		move.l	SS_ColPtr(pc),a0
		move.l	(a0),a0
		cmpa.l	#-1,a0
		beq.s	.fadeDone

		move.w	SS_FadeStepCounter(pc),d0
		
		cmp.w	#SS_FADE_STEPS,d0
		blo.s	.doFade
		clr.w	SS_FadeStepCounter
		addq.l	#4,SS_ColPtr
		bra.s	.doFadeOut

.doFade:
		move.l	SS_ShadeTablePtr(pc),a1
		addq.l	#2,SS_ShadeTablePtr
		move.w	(a1),(a0)
		addq.w	#1,SS_FadeStepCounter

.fadeDone:
		bra.s	.doCopperWave


SineScroller_Interrupt:
		addq.l	#1,SS_LocalFrameCounter
		add.l	#12<<16|4,SS_SinIndex

		cmp.l	#200,SS_LocalFrameCounter
		blo.s	.noWave
		addq.w	#2,SS_WaveTableIndex
.noWave:

		rts

************************************************************
* Effect routines
************************************************************
SS_CopperWave:
		lea.l	SS_WaveTable(pc),a0
		move.w	SS_WaveTableIndex(pc),d0
		and.w	#$1ff,d0

		lea.l	SS_YStartTable(pc),a1

		move.w	(a0,d0.w),d0
		add.w	#SS_STEP_SIZE<<3,d0

		move.w	#(($2c+(256/2))-(SS_HEIGHT/2)-(6*SS_STEP_SIZE))<<3,d1
 
		moveq	#7-1,d7
.loop:	
		move.w	d1,d2
		lsr.w	#3,d2
		move.l	(a1)+,a2
		move.b	d2,(a2)
		add.w	d0,d1
		dbf		d7,.loop

		add.w	#SS_HEIGHT,d2
		lea.l	SS_YStopTable(pc),a1
		move.l	(a1)+,a2

		cmp.w	#$100,d2
		blo.s	.yStop1Ok
		move.l	#$ffdffffe,(a2)+
		sub.w	#$ff,d2
		move.w	#$2c<<3,d0
		bra.s	.setYStop1
.yStop1Ok:
		move.l	#$01900000,(a2)+
		move.w	#$12c<<3,d0
.setYStop1:		
		move.b	d2,(a2)	
		lsl.w	#3,d2
		
		sub.w	d2,d0
		ext.l	d0
		divu.w	#7,d0
		
		moveq	#6-1,d7
.loop2:
		move.l	(a1)+,a2
		add.w	d0,d2
		move.w	d2,d1
		lsr.w	#3,d1

		cmp.w	#$100,d1
		blo.s	.noExtra
		move.l	#$ffdffffe,(a2)+
		sub.w	#$ff,d1
		sub.w	#$ff<<3,d2
		bra.s	.setY
.noExtra:
		move.l	#$01900000,(a2)+
.setY:	move.b	d1,(a2)

		dbf		d7,.loop2

.done:	rts

SS_PrintChar:
		move.l	SS_TextPtr(pc),a0
.testReset:
		move.b	(a0),d0
		bne.s	.print
		move.b	#1,SS_ScrollTextDone
		bra		.printDone
		; move.l	#SS_Text,SS_TextPtr
		; move.l	SS_TextPtr(pc),a0
		; bra		.testReset
.print:	addq.l	#1,SS_TextPtr
		sub.b	#' ',d0
        and.w   #$ff,d0
		mulu	#SS_FONT_HEIGHT*2,d0

		lea.l	SS_CustomFont,a1
		lea.l	(a1,d0.w),a1
		move.l	#SS_TextBuf+40,a2

I       SET     0
        REPT    SS_FONT_HEIGHT
        move.w  I*2(a1),I*42(a2)
        ; move.b  #0,I*42+1(a2)
I       SET     I+1
        ENDR
.printDone:
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

		even
SS_BlitSineScroller:
		lea.l	SS_TextBuf,a0
		move.l	DrawBuffer,a1
		lea.l	40*40(a1),a1
		lea.l	SS_CustomSinTab,a2
		move.l	SS_SinIndex(pc),d0
		move.l	#16<<16|32,d4

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
		
		move.l	a0,a3
		add.l	d3,a3
		add.l	d1,d3				; Add y-position to destination
		
		WAITBLIT
		move.l	a3,bltapth(a6)

		move.l 	a1,a3				; Store destination in a3
		add.l	d3,a3
		move.l 	a3,bltbpth(a6)
		move.l	a3,bltdpth(a6)
		move.l	d5,bltafwm(a6)
		move.w	#(SS_FONT_HEIGHT<<6)+1,bltsize(a6)

		addq.w	#1,d2
		lsr.l	#1,d5

		add.l	d4,d0

		dbf		d6,.innerLoop
		dbf		d7,.outerLoop

		rts

************************************************************
* Variables and data
************************************************************
		even
SS_LocalFrameCounter:
					dc.l	0
SS_LocalRunFrameCounter:
					dc.l	0
SS_SinIndex:		dc.w	0,0

SS_CustomSinTab:	ds.w	1024
							;0123456789012345678901234567890123456789
SS_Text:			
					dc.b	'****************************************'
					dc.b	'        -INSANE-        AT GERP 2025    '
					dc.b	'    WITH LOVE AND INSANITY'
					dc.b	'                                         ',0
					even
SS_TextPtr:			dc.l	SS_Text
SS_ScrollTextDone:	dc.w	0

SS_YStartTable:		dc.l	SS_YStart1,SS_YStart2,SS_YStart3,SS_YStart4
					dc.l	SS_YStart5,SS_YStart6,SS_YStart7
SS_YStopTable:		dc.l	SS_YStop1,SS_YStop2,SS_YStop3,SS_YStop4,SS_YStop5
					dc.l	SS_YStop6,SS_YStop7

; 13 colors
SS_ColTable:		dc.l	SS_COL_01,SS_COL_02,SS_COL_03,SS_COL_04,SS_COL_05,SS_COL_06
					dc.l	SS_COL_07,SS_COL_08,SS_COL_09,SS_COL_10,SS_COL_11,SS_COL_12
					dc.l	SS_COL_13,-1
SS_ColPtr:			dc.l	SS_ColTable

SS_HighLightColor:	dc.w	$0fff
SS_ToColor:			dc.w	$0fed
SS_FromColors:		dc.w    $0fda,$0fb6,$0d86,$0978,$0556,$0245,$0134
					dc.w    $0245,$0556,$0978,$0d86,$0fb6,$0fda
SS_ShadeTable:		dcb.w	SS_FADE_STEPS*SS_NO_COLORS
SS_ShadeTablePtr:	dc.l	SS_ShadeTable
SS_FadeStepCounter:	dc.w	0

SS_WaveTableIndex:	dc.w	0
SS_WaveTable:

;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(sin(x*PI/64)*sin((x/2)*(PI/128))*cos(x*2*PI/128)*64)
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
 dc.w $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0002
 dc.w $0002, $0003, $0003, $0004, $0004, $0005, $0005, $0006
 dc.w $0006, $0007, $0007, $0007, $0007, $0007, $0007, $0007
 dc.w $0007, $0006, $0006, $0005, $0004, $0003, $0002, $0001
 dc.w $0000, $ffff, $fffd, $fffc, $fffb, $fff9, $fff8, $fff7
 dc.w $fff5, $fff4, $fff3, $fff2, $fff1, $fff0, $ffef, $ffef
 dc.w $ffee, $ffee, $ffee, $ffee, $ffee, $ffef, $fff0, $fff1
 dc.w $fff2, $fff3, $fff4, $fff6, $fff8, $fffa, $fffc, $fffe
 dc.w $0000, $0002, $0005, $0007, $0009, $000b, $000d, $0010
 dc.w $0011, $0013, $0015, $0016, $0018, $0019, $001a, $001a
 dc.w $001b, $001b, $001b, $001a, $0019, $0018, $0017, $0016
 dc.w $0014, $0012, $0010, $000e, $000b, $0008, $0006, $0003
 dc.w $0000, $fffd, $fffa, $fff7, $fff4, $fff2, $ffef, $ffed
 dc.w $ffea, $ffe8, $ffe6, $ffe5, $ffe3, $ffe2, $ffe1, $ffe1
 dc.w $ffe1, $ffe1, $ffe1, $ffe2, $ffe3, $ffe4, $ffe6, $ffe7
 dc.w $ffe9, $ffec, $ffee, $fff1, $fff4, $fff7, $fffa, $fffd
 dc.w $0000, $0003, $0006, $0009, $000c, $000f, $0012, $0014
 dc.w $0017, $0019, $001a, $001c, $001d, $001e, $001f, $001f
 dc.w $001f, $001f, $001f, $001e, $001d, $001b, $001a, $0018
 dc.w $0016, $0013, $0011, $000e, $000c, $0009, $0006, $0003
 dc.w $0000, $fffd, $fffa, $fff8, $fff5, $fff2, $fff0, $ffee
 dc.w $ffec, $ffea, $ffe9, $ffe8, $ffe7, $ffe6, $ffe5, $ffe5
 dc.w $ffe5, $ffe6, $ffe6, $ffe7, $ffe8, $ffea, $ffeb, $ffed
 dc.w $ffef, $fff0, $fff3, $fff5, $fff7, $fff9, $fffb, $fffe
 dc.w $0000, $0002, $0004, $0006, $0008, $000a, $000c, $000d
 dc.w $000e, $000f, $0010, $0011, $0012, $0012, $0012, $0012
 dc.w $0012, $0011, $0011, $0010, $000f, $000e, $000d, $000c
 dc.w $000b, $0009, $0008, $0007, $0005, $0004, $0003, $0001
 dc.w $0000, $ffff, $fffe, $fffd, $fffc, $fffb, $fffa, $fffa
 dc.w $fff9, $fff9, $fff9, $fff9, $fff9, $fff9, $fff9, $fff9
 dc.w $fffa, $fffa, $fffb, $fffb, $fffc, $fffc, $fffd, $fffd
 dc.w $fffe, $fffe, $ffff, $ffff, $ffff, $0000, $0000, $0000
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

		dc.w	$0180
SS_COL_00:dc.w	$0fed
		dc.w	$0182,$0556
		dc.w	$0184,$0ddd
		dc.w	$0186,$0ddd

SS_YStart1:
		SS_CALCY	-1,-6
		dc.w	$fffe,$0180
SS_COL_01:
		dc.w	$0fda
SS_YStart2:
		SS_CALCY	-1,-5
		dc.w	$fffe,$0180
SS_COL_02:
		dc.w	$0fb6
SS_YStart3:
		SS_CALCY	-1,-4
		dc.w	$fffe,$0180
SS_COL_03:
		dc.w	$0d86
SS_YStart4:
		SS_CALCY	-1,-3
		dc.w	$fffe,$0180
SS_COL_04:
		dc.w	$0978
SS_YStart5:
		SS_CALCY	-1,-2
		dc.w	$fffe,$0180
SS_COL_05:
		dc.w	$0556
SS_YStart6:
		SS_CALCY	-1,-1
		dc.w	$fffe,$0180
SS_COL_06:
		dc.w	$0245
SS_YStart7:
		SS_CALCY	-1,0
		dc.w	$fffe
		dc.w	$0180
SS_COL_07:
		dc.w	$0134
		dc.w    $0100,$2200

SS_BplPtrs:
		dc.w	$00e0,$0000,$00e2,$0000
		dc.w	$00e4,$0000,$00e6,$0000

SS_YStop1:
		dc.w	$0190,$0000
		SS_CALCY	1,0
		dc.w	$fffe
		dc.w	$0100,$0200
		dc.w	$0180
SS_COL_08:
		dc.w	$0245
SS_YStop2:
		dc.w	$0190,$0000
		SS_CALCY	1,1
		dc.w	$fffe
		dc.w	$0180
SS_COL_09:
		dc.w	$0556
SS_YStop3:
		dc.w	$0190,$0000
		SS_CALCY	1,2
		dc.w	$fffe
		dc.w	$0180
SS_COL_10:
		dc.w	$0978
SS_YStop4:
		dc.w	$ffdf,$fffe
		SS_CALCY	1,3
		dc.w	$fffe
		dc.w	$0180
SS_COL_11:
		dc.w	$0d86
SS_YStop5:
		dc.w	$0190,$0000
		SS_CALCY	1,4
		dc.w	$fffe
		dc.w	$0180
SS_COL_12:
		dc.w	$0fb6
SS_YStop6:
		dc.w	$0190,$0000
		SS_CALCY	1,5
		dc.w	$fffe
		dc.w	$0180
SS_COL_13:
		dc.w	$0fda
SS_YStop7:
		dc.w	$0190,$0000
		SS_CALCY	1,6
		dc.w	$fffe
		dc.w	$0180
SS_COL_14:
		dc.w	$0fed

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

		even
SS_TextBuf:		
		ds.w	42*SS_FONT_HEIGHT
SS_CustomFont:
		ds.b	520*3*2
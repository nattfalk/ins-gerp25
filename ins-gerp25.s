	include "include/hardware/custom.i"
	include "include/blitter.i"
	include "include/bits.i"
	include	"include/macros.i"
	INCLUDE "common/startup.s"
	
********** Flags **************
PLAY_MUSIC = 1
SHOW_RASTER = 1

********** Constants **********
w		= 320
h		= 256
bpls	= 1
bpl		= w/16*2
bwid	= bpls*bpl

********** Demo **********
Demo:
	move.l	#VBint,$6c(a4)
	; $c020
	IFEQ	PLAY_MUSIC-1
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_EXTER|INTF_VERTB,$9a(a6)
	ELSE
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,$9a(a6)
	ENDIF
	; $87c0
	move.w	#DMAF_SETCLR|DMAF_BLTPRI|DMAF_DMAEN|DMAF_BPLEN|DMAF_COPEN|DMAF_BLTEN,$96(a6)
	; move.w	#DMAF_SETCLR|DMAF_DMAEN|DMAF_BPLEN|DMAF_COPEN|DMAF_BLTEN,$96(a6)
    
	; Call precalc routines

	IFEQ	PLAY_MUSIC-1
	lea		LSPMusic,a0
	lea		LSPBank,a1
	suba.l	a2,a2			; suppose VBR=0 ( A500 )
	moveq	#0,d0			; suppose PAL machine
	bsr		LSP_MusicDriver_CIA_Start
	ENDIF

********** Main loop **********
MainLoop:
	move.w	#$12c,d0
	bsr.w	WaitRaster

.initEffect:
	move.l	EffectsInitPointer,a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	move.l	(a0),a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	jsr		(a0)
	move.l	#-1,EffectsInitPointer
	bra		.mouse

.runEffect:
	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.end
	move.l	8(a0),a0
	jsr		(a0)

.mouse:
	IFEQ	SHOW_RASTER-1
	move.w	#$39c,$180(a6)
	ENDIF
	btst	#6,$bfe001
	bne.w	MainLoop

.end:	
	IFEQ	PLAY_MUSIC-1
	bsr		LSP_MusicDriver_CIA_Stop
	ENDIF
	rts

********** Common **********

; Set bitplane pointers
; a0 = Screen buffer
; a1 = Bitplane pointers in copper
; d0 = Bitplane size
; d1 = Number of bitplanes
SetBpls:
.bpll:	
	move.l	a0,d2
	swap 	d2
	move.w	d2,(a1)
	move.w	a0,4(a1)
	addq.w	#8,a1
	add.l	d0,a0
	dbf		d1,.bpll
	rts

; Clear buffer with blitter
; a0 = Buffer to clear
; d0 = Size to clear in words
BltClr:	
	bsr		WaitBlitter
	clr.w	$66(a6)
	move.l	#$01000000,$40(a6)	
	move.l	a0,$54(a6)
	move.w	d0,$58(a6)
	rts

; Vertical blank interrupt
VBint:	
	movem.l	d0/a0/a6,-(sp)
	lea		$dff000,a6
	btst	#5,$1f(a6)
	beq.s	.notvb

.do:
	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.done

	move.l	(a0),d0
	cmp.l	FrameCounter,d0
	bne.s	.run
	add.l	#16,EffectsPointer
	move.l	EffectsPointer,EffectsInitPointer
	add.l	#4,EffectsInitPointer
	bra		.do

.run:	
	move.l	12(a0),a0
	jsr		(a0)
	add.l	#1,FrameCounter

.done:
	moveq	#$20,d0
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	
	movem.l	(sp)+,d0/a0/a6
	rte

	; include	"common/textwriter.s"
	include	"common/fade.s"
	include "common/clippoly.s"
	include "common/drawline.s"
	include "common/rotate.s"
	include	"common/shadetable.s"
	include	"common/math.s"
	include	"common/textwriter_line.s"
	include "common/textwriter_word.s"

	include "common/LightSpeedPlayer_cia.asm"
	include "common/LightSpeedPlayer.asm"

	even
********** Fastmem Data **********
DrawBuffer:		dc.l	Screen2
ViewBuffer:		dc.l	Screen

EffectsTable:		
			; dc.l	15*50, WordWriter_Init, WordWriter_Run, WordWriter_Interrupt
			; dc.l	(2+15)*50, HorizontalStrips_Init, HorizontalStrips_Run, HorizontalStrips_Interrupt
			; dc.l	(2+17)*50, Logo_Init, Logo_Run, Logo_Interrupt
			; dc.l	(3+20)*50, LowresKidsImage_Init, LowresKidsImage_Run, LowresKidsImage_Interrupt
			; dc.l	(12+23)*50, DotRemove_Init, DotRemove_Run, DotRemove_Interrupt
			; dc.l	(11+35)*50, DotBall_Init, DotBall_Run, DotBall_Interrupt
			; dc.l	(8+46)*50, ErrolImage_Init, ErrolImage_Run, ErrolImage_Interrupt
			; dc.l	(7+54)*50, DotBall_InitReturn, DotBall_Run, DotBall_Interrupt
			dc.l	(30+61)*50, WordChanger_Init_Credits, WordChanger_Run_Credits, WordChanger_Interrupt
			dc.l	(4+91)*50, TransitionToScroller_Init, TransitionToScroller_Run, TransitionToScroller_Interrupt
			dc.l	(30+95)*50, SineScroller_Init, SineScroller_Run, SineScroller_Interrupt
			dc.l	(65+125)*50, WordChanger_Init_Greetings, WordChanger_Run_Greetings, WordChanger_Interrupt
  			dc.l	-1,-1
EffectsPointer:		dc.l	EffectsTable
EffectsInitPointer:	dc.l	EffectsTable+4
FrameCounter:		dc.l	0

			dcb.w	100,0
Mulu40:
I			SET		0
			REPT	256
			dc.w	I
I			SET		I+40
			ENDR

I			SET		0
			REPT	16
			dc.w	I
I			SET		I+640
			ENDR
			dcb.w	100,0

	include	"include/sintab.i"

	include "parts/horizontal_strips.s"
	include	"parts/dot_remove.s"
	include	"parts/sine_scroller.s"
	include	"parts/credits.s"
	include	"parts/logo.s"
	include	"parts/transition_to_scroller.s"
	include "parts/word_writer.s"
	include "parts/dot_ball.s"
	include "parts/word_changer.s"
	include "parts/lowreskids_image.s"
	include "parts/errol_image.s"

*******************************************************************************
	SECTION ChipData,DATA_C
*******************************************************************************

MainCopper:
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

MainPalette:
	dc.w	$0180,$0222
	dc.w	$0182,$0fff
	dc.w	$0184,$0088
	dc.w	$0186,$00ff

MainBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
MainBplCon:
	dc.w	$0100,$2200

	dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

******************************************************

BlankLine:      dcb.b   40,0
				dcb.b	65*2*4*3,0
BigFont:        incbin	"data/graphics/font_32x65_1751x3.raw"
				dcb.b	65*2*4*3,0
LSPBank:		incbin	"data/music/prospectives(final).lsbank"

	SECTION	VariousData,DATA_P

Font:			incbin	"data/graphics/vedderfont5.8x520.1.raw"
DotMask:		incbin	"data/graphics/circle_mask_2_32x160x1.raw"
LSPMusic:		incbin	"data/music/prospectives(final).lsmusic"

*******************************************************************************
	SECTION ChipBuffers,BSS_C
*******************************************************************************
			even
Screen:		ds.b	h*bwid*5
Screen2:	ds.b	h*bwid*5
ChipBuf:	ds.b	h*bwid*5

QuadsMask:	ds.b	h*bwid

TLFont:		ds.w	520*8

; Triangle:	ds.b	320*160/8
	END
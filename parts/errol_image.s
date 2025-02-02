************************************************************
*
* Main routines
*
************************************************************
        SECTION ErrolImage, CODE_P

************************************************************
* Initialize
************************************************************
ErrolImage_FinalInit:
        bsr     ErrolImage_Init

        lea.l   EI_CopCols,a0
        moveq   #16-1,d7
.clearPal:
        move.w  #$0012,2(a0)
        addq.l  #4,a0
        dbf     d7,.clearPal

        lea.l   EI_ImageRip,a0
        lea.l   ChipBuf,a1
        adda.l  #(320*195)>>3,a1
        moveq   #4-1,d7
.copy:  moveq   #32-1,d6
.copyY: moveq   #(128>>3)-1,d5
.copyX: move.b  (a0)+,(a1)+
        dbf     d5,.copyX
        adda.l  #(320-128)>>3,a1
        dbf     d6,.copyY
        adda.l  #(320*(256-32))>>3,a1
        dbf     d7,.copy

        lea.l   ChipBuf,a1
        adda.l  #(320*54)>>3,a1
        moveq   #4-1,d7
.copy2: moveq   #23-1,d6
.copyY2:moveq   #(176>>3)-1,d5
.copyX2:clr.b   (a1)+
        dbf     d5,.copyX2
        adda.l  #(320-176)>>3,a1
        dbf     d6,.copyY2
        adda.l  #(320*(256-23))>>3,a1
        dbf     d7,.copy2

        clr.l   EI_LocalFrameCounter
        clr.w   EI_DoGlitch
        bsr     EI_ResetGlitch

        move.l  #EI_ImagePalOrange,EI_FadePalettePtr

        move.l  #22*50,EI_FadeOutTriggerFrame
        rts

ErrolImage_Init:
	lea.l	$dff000,a6

        lea.l   EI_Image,a0
        lea.l   ChipBuf,a1
        move.l  #(320*256*4)>>5-1,d7
.copyImage:
        move.l  (a0)+,(a1)+
        dbf     d7,.copyImage

        lea.l   ChipBuf,a0
        lea.l   EI_BplPtrs,a1
        moveq   #4-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #320*256>>3,a0
        adda.l  #8,a1
        dbf     d7,.setBpls

    	move.l	#EI_Copper,$80(a6)
        
        jsr     InitFade
        rts

************************************************************
* Run
************************************************************
ErrolImage_RunFinal:
        cmp.l   #15*50,EI_LocalFrameCounter
        bmi.s   .done
        cmp.l   #16*50,EI_LocalFrameCounter
        bmi.s   .fadeIn
        cmp.l   #16*50,EI_LocalFrameCounter
        beq.s   .resetFade
        move.l  EI_FadeOutTriggerFrame(pc),d0
        cmp.l   EI_LocalFrameCounter,d0
        bmi.s   .fadeOut
.done:  
        addq.l  #1,EI_LocalFrameCounter
        rts

.fadeIn:
        lea.l   EI_ImageFadePal(pc),a0
        move.l  EI_FadePalettePtr(pc),a1
        lea.l   EI_CopCols,a2
        moveq   #24,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.fadeOut:
        move.l  EI_FadePalettePtr(pc),a0
        lea.l   EI_ImageFadePal(pc),a1
        lea.l   EI_CopCols,a2
        moveq   #24,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.resetFade:
        jsr     InitFade
        bra.s   .done

ErrolImage_Run:
        tst.w   EI_DoGlitch
        beq.s   .skipGlitch

        cmp.l   #100,EI_LocalFrameCounter
        bgt.s   .resetGlitch
        bsr     EI_Glitch
        bra.s   .skipGlitch
.resetGlitch:
        cmp.l   #101,EI_LocalFrameCounter
        bne.s   .skipGlitch
        bsr     EI_ResetGlitch
.skipGlitch:
        cmp.l   #32,EI_LocalFrameCounter
        bmi.s   .fadeIn
        cmp.l   #50,EI_LocalFrameCounter
        beq.s   .resetFade
        move.l  EI_FadeOutTriggerFrame(pc),d0
        cmp.l   EI_LocalFrameCounter,d0
        bmi.s   .fadeOut
.done:  
        addq.l  #1,EI_LocalFrameCounter
        rts

.fadeIn:
        lea.l   EI_ImageFadePal(pc),a0
        move.l  EI_FadePalettePtr(pc),a1
        lea.l   EI_CopCols,a2
        moveq   #24,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.fadeOut:
        move.l  EI_FadePalettePtr(pc),a0
        lea.l   EI_ImageFadePal(pc),a1
        lea.l   EI_CopCols,a2
        moveq   #24,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.resetFade:
        jsr     InitFade
        bra.s   .done

************************************************************
* Interrupt
************************************************************
ErrolImage_Interrupt:
        rts

************************************************************
*
* Effect routines
*
************************************************************
EI_Glitch:
        lea.l   EI_GlitchIndexValues(pc),a0
        lea.l   EI_GlitchValues(pc),a1
        lea.l   EI_GlitchPointers(pc),a2

        moveq   #6-1,d7
.doGlitch:
        move.w  (a0),d0
        and.w   #63,d0
        move.w  (a1,d0.w),d0
        move.l  (a2)+,a3
        move.w  d0,(a3)

        addq.w  #2,(a0)+

        dbf     d7,.doGlitch

        rts

EI_ResetGlitch:
        lea.l   EI_GlitchPointers(pc),a0
        moveq   #6-1,d7
.reset: move.l  (a0)+,a1
        clr.w   (a1)
        dbf     d7,.reset
        rts

************************************************************
*
* Variables and data
*
************************************************************
        even
EI_LocalFrameCounter:   dc.l    0
EI_FadeStage:           dc.w    0

EI_FadeOutTriggerFrame: dc.l    375
EI_FadePalettePtr:      dc.l    EI_ImagePal
EI_ImageFadePal:        dcb.w   32,$0012
EI_ImagePal:            incbin  "data/graphics/errol_320x256x4.pal"
EI_ImagePalOrange:      incbin  "data/graphics/errol_plain_320x256x4.pal"

EI_DoGlitch:            dc.w    1
EI_GlitchPointers:      dc.l    EI_GlitchRow1
                        dc.l    EI_GlitchRow2
                        dc.l    EI_GlitchRow3
                        dc.l    EI_GlitchRow4
                        dc.l    EI_GlitchRow5
                        dc.l    EI_GlitchRow6
EI_GlitchIndexValues:   dc.w    4,14,8,18,26,22
EI_GlitchValues:        dc.w    $0C,$B4,$0D,$4F,$AF,$0D,$D2,$08
                        dc.w    $19,$4D,$6E,$64,$E2,$CA,$88,$F9
                        dc.w    $DD,$B8,$C5,$66,$93,$43,$5A,$1C
                        dc.w    $96,$D9,$94,$D3,$37,$6F,$FB,$A8

************************************************************
*
* Copper and data
*
************************************************************
        SECTION EI_Copper, DATA_C
EI_Copper:
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
        dc.w    $0100,$4200

EI_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
EI_CopCols:
	dc.w	$0180,$0012,$0182,$0012,$0184,$0012,$0186,$0012
	dc.w	$0188,$0012,$018a,$0012,$018c,$0012,$018e,$0012
	dc.w	$0190,$0012,$0192,$0012,$0194,$0012,$0196,$0012
	dc.w	$0198,$0012,$019a,$0012,$019c,$0012,$019e,$0012

        dc.w    $5001,$fffe
	dc.w	bplcon1
EI_GlitchRow1:
        dc.w    $00ff
        dc.w    $5501,$fffe
	dc.w	bplcon1,$0000

        dc.w    $7501,$fffe
	dc.w	bplcon1
EI_GlitchRow2:
        dc.w    $00ff
        dc.w    $7601,$fffe
	dc.w	bplcon1,$0000

        dc.w    $8001,$fffe
	dc.w	bplcon1
EI_GlitchRow3:
        dc.w    $00ff
        dc.w    $8301,$fffe
	dc.w	bplcon1,$0000

        dc.w    $b001,$fffe
	dc.w	bplcon1
EI_GlitchRow4:
        dc.w    $00ff
        dc.w    $b601,$fffe
	dc.w	bplcon1,$0000

        dc.w    $d001,$fffe
	dc.w	bplcon1
EI_GlitchRow5:
        dc.w    $00ff
        dc.w    $d201,$fffe
	dc.w	bplcon1,$0000

        dc.w    $ffdf,$fffe

        dc.w    $0501,$fffe
	dc.w	bplcon1
EI_GlitchRow6:
        dc.w    $00ff
        dc.w    $0901,$fffe
	dc.w	bplcon1,$0000

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

        section EI_ChipData, DATA_P

EI_Image:	incbin	"data/graphics/errol_320x256x4.raw"
EI_ImageRip:	incbin	"data/graphics/errol_rip_128x32x4.raw"

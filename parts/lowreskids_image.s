************************************************************
*
* Main routines
*
************************************************************
        SECTION LowresKidsImage, CODE_P

************************************************************
* Initialize
************************************************************
LowresKidsImage_Init:
	lea.l	$dff000,a6

        lea.l   LKI_Image,a0
        lea.l   ChipBuf,a1
        move.l  #(320*256*4)>>5-1,d7
.copyImage:
        move.l  (a0)+,(a1)+
        dbf     d7,.copyImage

        lea.l   ChipBuf,a0
        lea.l   LKI_BplPtrs,a1
        moveq   #4-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #320*200>>3,a0
        adda.l  #8,a1
        dbf     d7,.setBpls

    	move.l	#LKI_Copper,$80(a6)
        
        jsr     InitFade
        rts

************************************************************
* Run
************************************************************
LowresKidsImage_Run:
        cmp.l   #32,LKI_LocalFrameCounter
        bmi.s   .fadeIn
        cmp.l   #50,LKI_LocalFrameCounter
        beq.s   .resetFade
        cmp.l   #175,LKI_LocalFrameCounter
        bge.s   .fadeOut
.done:  
        addq.l  #1,LKI_LocalFrameCounter
        rts

.fadeIn:
        lea.l   LKI_ImageFadePalFrom(pc),a0
        lea.l   LKI_ImagePal(pc),a1
        lea.l   LKI_CopCols,a2
        moveq   #25,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.fadeOut:
        lea.l   LKI_ImagePal(pc),a0
        lea.l   LKI_ImageFadePalTo(pc),a1
        lea.l   LKI_CopCols,a2
        moveq   #50,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.resetFade:
        jsr     InitFade
        bra.s   .done

************************************************************
* Interrupt
************************************************************
LowresKidsImage_Interrupt:
        rts

************************************************************
*
* Variables and data
*
************************************************************
        even
LKI_LocalFrameCounter:  dc.l    0
LKI_FadeStage:          dc.w    0

LKI_ImageFadePalFrom:   dcb.w   32,$0012
LKI_ImageFadePalTo:     dcb.w   32,$0fff
LKI_ImagePal:           incbin  "data/graphics/lowres_kids_320x256x4.pal"

************************************************************
*
* Copper and data
*
************************************************************
        SECTION LKI_Copper, DATA_C
LKI_Copper:
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

LKI_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
LKI_CopCols:
	dc.w	$0180,$0012,$0182,$0012,$0184,$0012,$0186,$0012
	dc.w	$0188,$0012,$018a,$0012,$018c,$0012,$018e,$0012
	dc.w	$0190,$0012,$0192,$0012,$0194,$0012,$0196,$0012
	dc.w	$0198,$0012,$019a,$0012,$019c,$0012,$019e,$0012

        dc.b    $2c+28,$01
        dc.w    $fffe
        dc.w    $0100,$4200

        dc.w    $ffdf,$fffe
        dc.w    $1001,$fffe,$0100,$0200        

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

        SECTION LKI_ChipData, DATA_P

                even
LKI_Image:	incbin	"data/graphics/lowres_kids_320x256x4.raw"

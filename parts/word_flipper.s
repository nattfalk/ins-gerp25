************************************************************
*
* Main routines
*
************************************************************
        SECTION WordFlipper, CODE_P

	include	"include/macros.i"

WF_NumPoints = 20+9+9 ; +18 ; +18 ;32

************************************************************
WordFlipper_Init:
	lea	Screen,a0
        move.l  #(256<<6)+(320>>4)*3,d0
	jsr	BltClr
	lea	Screen2,a0
        move.l  #(256<<6)+(320>>4)*3,d0
	jsr	BltClr
	WAITBLIT

        lea.l   Screen,a0
        adda.l  #(320>>3)*256,a0
        move.l  a0,WF_TextScr

	; Balls - bpl 0
        lea	Screen,a0
	lea	WF_BplPtrs+2,a1
	moveq	#1-1,d1
	jsr	SetBpls

        ; Text shadow - bpl 1
	move.l  WF_TextScr,a0
	lea	WF_BplPtrs+2+8,a1
	moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

        ; Text - bpl 2
	move.l  WF_TextScr,a0
	lea	WF_BplPtrs+2+16,a1
	moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

        move.w  #$0789,WF_Palette+2
        move.w  #$0789,WF_Palette+6
        move.w  #$0789,WF_Palette+10
        move.w  #$0789,WF_Palette+14
        move.w  #$3200,WF_BplCon+2

        jsr     InitFade

	move.l	#WF_Copper,$80(a6)
        rts

************************************************************
WordFlipper_Run:
	movem.l	DrawBuffer,a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
        moveq   #0,d0
	lea	WF_BplPtrs+2,a1
	moveq	#1-1,d1
	jsr	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	jsr	BltClr

        bsr     WF_MoveBackgroundLines

        tst.b   WF_DoExplode
        beq     .noExplode
	
        WAITBLIT

        lea.l   WF_CubeRotatedCoords,a0
        lea.l   WF_Balls,a1
        move.l  DrawBuffer,a3
        lea.l   WF_ExplodeVelocities,a4
        moveq   #WF_NumPoints-1,d7
.drawExplode:
        movem.w (a0),d0-d1/d5

        move.w  (a4)+,d2
        add.w   d2,(a0)
        move.w  (a4)+,d2
        add.w   d2,2(a0)
        addq.l  #6,a0

        cmp.w   #0,d0
        bmi.s   .nextBall
        cmp.w   #0,d1
        bmi.s   .nextBall
        cmp.w   #320-8,d0
        bge     .nextBall
        cmp.w   #256-8,d1
        bge     .nextBall

        ; Calculate screen offset
        move.w  d0,d2
        lsr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        ; Get current ball index
        asr.w   #5,d5
        add.w   #4,d5
        bge     .ok11
        moveq   #0,d5
.ok11:  cmp.w   #7,d5
        ble     .ok22
        move    #7,d5
.ok22:  lsl.w   #4,d5
        lea.l   (a1,d5.w),a2

        ; Render ball
        moveq   #8-1,d6
.drawBall1:
        move.w  (a2)+,d3
        and.w   #7,d2
        addq.w  #8,d2
        ror.w   d2,d3
        or.b    d3,(a3,d1.l)
        ror.w   #8,d3
        or.b    d3,1(a3,d1.l)
        add.l   #40,d1
        dbf     d6,.drawBall1
.nextBall:
        dbf     d7,.drawExplode

        bra     .done

.noExplode:
        tst.b   WF_FadeIn
        bne.s   .fadeDone
        lea.l   WF_FromPalette,a0
        lea.l   WF_ToPalette,a1
        lea.l   WF_Palette,a2
        moveq   #32,d0
        moveq   #8-1,d1
        jsr     Fade
        move.w  WF_Palette+2,d1
        move.w  d1,WF_PaletteBg2+2
        move.w  d1,WF_PaletteBg3+2
        cmp.w   #33,d0
        bmi.s   .fadeDone
        move.w  #$0456,WF_PaletteBg2+2
        move.w  #$0678,WF_PaletteBg3+2
        st.b    WF_FadeIn
        clr.w   FCnt
.fadeDone:
        tst.b   WF_FlashText
        beq.s   .noFlash
        lea.l   WF_FlashPaletteFrom,a0
        lea.l   WF_FlashPaletteTo,a1
        move.l  WF_FlashPalettePtr,a2
        moveq   #8,d0
        moveq   #6-1,d1
        jsr     Fade

.noFlash:
        WAITBLIT
 
        lea.l   WF_CubeAngles,a0
        movem.w (a0)+,d0-d2
        jsr     InitRotate

        lea.l   WF_CubeCoords,a0
        lea.l   WF_CubePosition,a1
        lea.l   WF_Balls,a2
        movea.l WF_MorphTargetPtr,a3
        move.l  DrawBuffer,a4
        lea.l   WF_CubeRotatedCoords,a5

        moveq   #0,d4
        moveq   #WF_NumPoints-1,d7
.rotate:movem.w (a0)+,d0-d2
        jsr     RotatePoint
        move.w  d2,d5
        
        ; Add object offset
        add.w   (a1),d0
        add.w   2(a1),d1
        add.w   4(a1),d2

        ; Project x
        ext.l   d0
        asl.l   #7,d0
        divs    d2,d0
        add.w   WF_CubeXCenter,d0
        bmi     .next

        ; Project y
        ext.l   d1
        asl.l   #7,d1
        divs    d2,d1
        add.w   WF_CubeYCenter,d1
        
        movem.w d0-d1/d5,(a5)
        addq.l  #6,a5

        move.w  WF_MorphStep,d6
        beq.s   .calcScreenOffset
        move.w  (a3),d3
        add.w   d4,d3
        addq.w  #2,d4
        sub.w   d0,d3
        muls    d6,d3
        asr.w   #5,d3
        add.w   d3,d0
        move.w  2(a3),d3
        sub.w   d1,d3
        muls    d6,d3
        asr.w   #5,d3
        add.w   d3,d1

.calcScreenOffset:
        move.l  a5,-(sp)
        ; Calculate screen offset
        move.w  d0,d2
        lsr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        ; Get current ball index
        asr.w   #5,d5
        add.w   #4,d5
        bge     .ok1
        moveq   #0,d5
.ok1:   cmp.w   #7,d5
        ble     .ok2
        move    #7,d5
.ok2:   lsl.w   #4,d5
        lea.l   (a2,d5.w),a5

        ; Render ball
        moveq   #8-1,d6
.drawBall:
        move.w  (a5)+,d3
        and.w   #7,d2
        addq.w  #8,d2
        ror.w   d2,d3
        or.b    d3,(a4,d1.l)
        ror.w   #8,d3
        or.b    d3,1(a4,d1.l)
        add.l   #40,d1
        dbf     d6,.drawBall

        move.l  (sp)+,a5

.next:  dbf     d7,.rotate

        move.w  WF_PrintText,d7
        beq.s   .done
        lsr.w   #1,d7
        cmp.w   #10,d7
        bhi.s   .done
        subq.w  #1,d7
        bmi     .done

        movea.l WF_TextPtr,a0
        lea.l   Font,a1
        movea.l WF_PositionPtr,a2
        move.l  WF_TextScr,a3
        moveq   #0,d3
.print:
        move.w  (a2),d0
        add.w   d3,d0
        addq.w  #8,d3
        move.w  2(a2),d1
        asr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        move.b  (a0)+,d2
        sub.b   #' ',d2
        and.w   #255,d2
        asl.w   #3,d2
        lea.l   (a1,d2.w),a4
        lea.l   (a3,d1.l),a5

        REPT    8
        move.b  (a4)+,(a5)
        lea.l   40(a5),a5
        ENDR

        dbf     d7,.print
.done:
        rts
 
************************************************************
WordFlipper_Interrupt:
        movem.l d0-d1/a0-a2,-(sp)

        add.w   #1,WF_LocalFrameCounter
        move.w  WF_LocalFrameCounter,d0

        add.w   #32,WF_ShadowMoveX
        add.w   #24,WF_ShadowMoveY

.runFx:
        movea.l WF_TimingPointer,a0
        move.w  (a0)+,d1
        cmp.w   d1,d0
        blo.s   .run
        add.l   #4,WF_TimingPointer
        bra     .runFx
.run:   move.w  (a0)+,d1
        cmp.w   #0,d1
        beq     .rotate

.morphIn:
        cmp.w   #1,d1
        bne.s   .printText

        cmp.w   #40,WF_MorphStep
        beq     .rotate
        add.w   #2,WF_MorphStep
        bra     .rotate

.printText:
        cmp.w   #2,d1
        bne.s   .morphOut
        cmp.w   #128,WF_PrintText
        beq     .rotate
        add.w   #1,WF_PrintText
        bra    .rotate

.morphOut:
        cmp.w   #3,d1
        bne.s   .initFlash
        cmp.w   #0,WF_PrintText
        beq.s   .mo2
        add.l   #10,WF_TextPtr
.mo2:   move.w  #0,WF_PrintText
        cmp.w   #0,WF_MorphStep
        beq.s   .rotate
        sub.w   #2,WF_MorphStep
        tst.w   WF_MorphStep
        bne.s   .rotate
        addq.l  #4,WF_MorphTargetPtr
        addq.l  #4,WF_PositionPtr
        bra.s   .rotate

.initFlash: 
        cmp.w   #4,d1
        bne.s   .flash
        clr.b   WF_FlashText
        clr.w   FCnt
        add.l   #16*2,WF_FlashPalettePtr

        cmp.l   #WF_PaletteLine1,WF_FlashPalettePtr
        beq     .rotate

        lea.l   WF_FlashPaletteTo,a0
        add.w   #$111,(a0)
        add.w   #$111,4(a0)
        add.w   #$111,8(a0)
        bra.s   .rotate

.flash: cmp.w   #5,d1
        bne.s   .explode
        move.b  #1,WF_FlashText
        bra.s   .rotate

.explode:
        cmp.w   #6,d1
        bne.s   .rotate
        move.b  #1,WF_DoExplode
        bra.s   .exit

.rotate:
        lea.l   WF_CubeAngles,a0
        cmp.w   #950,WF_LocalFrameCounter
        bmi.s   .slowSpeed
        add.w   #6,(a0)
        add.w   #14,2(a0)
        sub.w   #-6,4(a0)
        bra.s   .rotate2
.slowSpeed:
        add.w   #2,(a0)
        add.w   #6,2(a0)
        sub.w   #-2,4(a0)
.rotate2:
        lea.l   Sintab,a0
        lea.l   Costab,a1
        lea.l   WF_CubePosition,a2
        move.w  WF_PosMove,d0
        cmp.w   #512,d0
        bgt.s   .skipMove
        move.w  (a1,d0.w),d1
        lsr.w   #6,d1
        add.w   #200,d1
        move.w  d1,4(a2)

        move.w  (a0,d0.w),d1
        lsr.w   #7,d1
        sub.w   #256-160,d1
        move.w  d1,WF_CubeXCenter

        add.w   #4,WF_PosMove
.skipMove:

.exit:
        movem.l (sp)+,d0-d1/a0-a2
        rts

************************************************************

WF_MoveShadowLayer:
        lea.l   Sintab,a0

        move.w  WF_ShadowMoveX,d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0

        move.w  WF_ShadowMoveY,d1
        and.w   #$7fe,d1
        move.w  (a0,d1.w),d1
        asr.w   #8,d1
        asr.w   #2,d1

        add.w   d0,d1
        asr.w   #1,d1
        muls    #40,d1

        add.l   WF_TextScr,d1

        lea.l   WF_BplPtrs+10,a0

        cmp.w   #0,d0
        bge.s   .pos
        addq.l  #2,d1
        add.w   #16,d0
.pos:
        lsl.b   #4,d0
        and.b   #$f0,d0
        move.b  d0,WF_BplCon1+1
        move.w  d1,4(a0)
        swap    d1
        move.w  d1,(a0)

        rts

WF_MoveBackgroundLines:
        lea.l   Sintab,a0
        move.w  WF_ShadowMoveX,d0
        neg.w   d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0
        add.w   #$80,d0
        move.b  d0,WF_Palette2Y

        move.w  WF_ShadowMoveX,d0
        neg.w   d0
        sub.w   WF_ShadowMoveY,d0
        asr.w   #1,d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0
        add.w   #$d0,d0
        move.b  d0,WF_Palette3Y
        rts

************************************************************
                        even
                        ; Effect types
                        ; 0 = Rotate
                        ; 1 = Morph in
                        ; 2 = Print text
                        ; 3 = Morph out
                        ; 4 = Flash text
T_OFFS                  = 180
BEAT                    = 24
WF_TimingTable:         dc.w    T_OFFS+(BEAT*0),0
                        dc.w    T_OFFS+(BEAT*1),1
                        dc.w    T_OFFS+(BEAT*2),2
                        dc.w    T_OFFS+(BEAT*3),3

                        dc.w    T_OFFS+(BEAT*4),0
                        dc.w    T_OFFS+(BEAT*5),1
                        dc.w    T_OFFS+(BEAT*6),2
                        dc.w    T_OFFS+(BEAT*7),3
                        dc.w    T_OFFS+(BEAT*8),0
                        dc.w    T_OFFS+(BEAT*9),1
                        dc.w    T_OFFS+(BEAT*10),2
                        dc.w    T_OFFS+(BEAT*11),3
                        dc.w    T_OFFS+(BEAT*12),0
                        dc.w    T_OFFS+(BEAT*13),1
                        dc.w    T_OFFS+(BEAT*14),2
                        dc.w    T_OFFS+(BEAT*15),3
                        dc.w    T_OFFS+(BEAT*16),0
                        dc.w    T_OFFS+(BEAT*17),1
                        dc.w    T_OFFS+(BEAT*18),2
                        dc.w    T_OFFS+(BEAT*19),3
                        dc.w    T_OFFS+(BEAT*20),0
                        dc.w    T_OFFS+(BEAT*21),1
                        dc.w    T_OFFS+(BEAT*22),2
                        dc.w    T_OFFS+(BEAT*23),3
                        dc.w    T_OFFS+(BEAT*24),0
                        dc.w    T_OFFS+(BEAT*25),1
                        dc.w    T_OFFS+(BEAT*26),2
                        dc.w    T_OFFS+(BEAT*27),3
                        dc.w    T_OFFS+(BEAT*28),0
                        dc.w    T_OFFS+(BEAT*29),1
                        dc.w    T_OFFS+(BEAT*30),2
                        dc.w    T_OFFS+(BEAT*31),3

                        dc.w    1699,0
                        dc.w    1700,4
                        dc.w    1724,5
                        dc.w    1725,4
                        dc.w    1749,5
                        dc.w    1750,4
                        dc.w    1774,5

                        dc.w    1800,6


WF_TimingPointer:  dc.l    WF_TimingTable
WF_LocalFrameCounter:
                        dc.w    0
WF_PrintText:      dc.w    0
WF_Text:
                        dc.b    'AN        '
                        dc.b    'ANAGRAM   '
                        dc.b    'FOR       '
                        dc.b    'LOWRES    '
                        dc.b    'KIDS      '
                        dc.b    'IS        '
                        dc.b    'LIKES     '
                        dc.b    'WORDS     '
                        even
WF_TextPtr:        dc.l    WF_Text

WF_FadeIn:         dc.b    0,0

CRED_LINE_1             = 128-25-50
CRED_LINE_2             = 128-25
CRED_LINE_3             = 128+25
CRED_LINE_4             = 128+25+50
WF_Positions:
                        dc.w    4*8,CRED_LINE_1
                        dc.w    7*8,CRED_LINE_1
                        dc.w    15*8,CRED_LINE_1
                        dc.w    11*8,CRED_LINE_2
                        dc.w    18*8,CRED_LINE_2
                        dc.w    20*8,CRED_LINE_3
                        dc.w    21*8,CRED_LINE_4
                        dc.w    27*8,CRED_LINE_4
WF_PositionPtr:    dc.l    WF_Positions

WF_TextScr:        dc.l    0
WF_CubeCoords:
        ; First ring
        dc.w $0000, $00fc, $0000
        dc.w $004c, $00f0, $0000
        dc.w $0094, $00cc, $0000
        dc.w $00cc, $0094, $0000
        dc.w $00f0, $0050, $0000
        dc.w $00fc, $0000, $0000
        dc.w $00f4, $ffb0, $0000
        dc.w $00d0, $ff68, $0000
        dc.w $0098, $ff30, $0000
        dc.w $0050, $ff0c, $0000
        dc.w $0000, $ff00, $0000
        dc.w $ffb4, $ff08, $0000
        dc.w $ff6c, $ff2c, $0000
        dc.w $ff30, $ff64, $0000
        dc.w $ff0c, $ffac, $0000
        dc.w $ff00, $fff8, $0000
        dc.w $ff08, $0048, $0000
        dc.w $ff2c, $0090, $0000
        dc.w $ff64, $00c8, $0000
        dc.w $ffa8, $00f0, $0000

        ; Second ring
        dc.w $0027, $00f3, $0043
        dc.w $0067, $0097, $00b1
        dc.w $007f, $0001, $00dc
        dc.w $0068, $ff6b, $00b3
        dc.w $0028, $ff0d, $0045
        dc.w $ffb6, $ff2e, $ff80
        dc.w $ff86, $ffac, $ff2e
        dc.w $ff85, $004a, $ff2c
        dc.w $ffb2, $00cb, $ff7a

        ; Third ring
        dc.w $ffb6, $00cf, $0081
        dc.w $ff87, $0050, $00d2
        dc.w $ff86, $ffb2, $00d3
        dc.w $ffb4, $ff32, $0083
        dc.w $0025, $ff0b, $ffbe
        dc.w $0065, $ff66, $ff4e
        dc.w $007f, $fffb, $ff22
        dc.w $0068, $0092, $ff49
        dc.w $002a, $00f1, $ffb6
        
WF_CubeRotatedCoords:
                        ds.w    3*WF_NumPoints
WF_CubeAngles:     dc.w    0,0,0
WF_CubePosition:   dc.w    0,0,600
WF_PosMove:        dc.w    0
WF_CubeXCenter:    dc.w    320/2
WF_CubeYCenter:    dc.w    256/2
WF_MorphStep:      dc.w    0
WF_MorphTarget:         dc.w    5*8+12,CRED_LINE_1+4+12
                        dc.w    10*8-20,CRED_LINE_1+4+12
                        dc.w    16*8-30,CRED_LINE_1+4+12
                        dc.w    14*8-25,CRED_LINE_2+4
                        dc.w    20*8-30,CRED_LINE_2+4
                        dc.w    21*8-35,CRED_LINE_3+4-4
                        dc.w    23*8-40,CRED_LINE_4+4-20
                        dc.w    29*8-48,CRED_LINE_4+4-20
WF_MorphTargetPtr:      dc.l    WF_MorphTarget

WF_ExplodeVelocities:
                        dc.w    -5,-6, -3,-1, -3,2, 0,-4, -4,-3, -3,3, 1,3, -2,0
                        dc.w    3,5, -2,-4, 0,-2, 2,4, -5,4, 2,-4, -1,-2, -2,-3
                        dc.w    -2,-2, -6,3, 1,-4, -3,4, 2,5, 2,1, 5,-6, -1,1
                        dc.w    3,1, -1,3, -3,-6, -4,-1, -3,2, -2,-1, 4,5, -2,-2
WF_DoExplode:      dc.b    0,0

WF_FromPalette:    dc.w    $048b,$048b,$048b,$048b,$048b,$048b,$048b,$048b
WF_ToPalette:      dc.w    $0345,$0abc,$0555,$0555,$0cde,$0cde,$0cde,$0cde
WF_FlashPaletteFrom:
                   dc.w    $0555,$0555,$0fff,$0fff,$0fff,$0fff
WF_FlashPaletteTo: dc.w    $0345,$078f,$0345,$078f,$0345,$078f
WF_FlashPalettePtr:dc.l    WF_PaletteLine1-(16*2)

WF_FlashText:      dc.w    0

WF_ShadowMoveX:    dc.w    0
WF_ShadowMoveY:    dc.w    0

WF_Balls:          dc.b    %00111100,0
                        dc.b    %01111110,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %01111110,0
                        dc.b    %00111100,0

                        dc.b    %00111000,0
                        dc.b    %01111100,0
                        dc.b    %11111110,0
                        dc.b    %11111110,0
                        dc.b    %11111110,0
                        dc.b    %01111100,0
                        dc.b    %00111000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00111100,0
                        dc.b    %01111110,0
                        dc.b    %01111110,0
                        dc.b    %00111100,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00111000,0
                        dc.b    %01111100,0
                        dc.b    %01111100,0
                        dc.b    %00111000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00111100,0
                        dc.b    %00111100,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00111000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

************************************************************
*
* Copper
*
************************************************************
        SECTION WF_Copper, CODE_C

WF_Copper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0104,$0000
	dc.w	$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0102
WF_BplCon1:
	dc.w	$0000   ;$00f0

WF_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
WF_BplCon:
	dc.w	$0100,$1200

WF_Palette:
	dc.w	$0180,$0222
	dc.w	$0182,$0222
WF_PaletteLine1:
	dc.w	$0184,$00f0
	dc.w	$0186,$00f0
	dc.w	$0188,$0222
	dc.w	$018a,$0222
	dc.w	$018c,$0222
	dc.w	$018e,$0222

WF_Palette2Y:
	dc.w	$8001,$fffe
WF_PaletteBg2:
	dc.w	$0180,$0222
WF_PaletteLine2:
	dc.w	$0184,$0555
	dc.w	$0186,$0555
	dc.w	$0188,$0cde
	dc.w	$018a,$0cde
	dc.w	$018c,$0cde
	dc.w	$018e,$0cde

WF_Palette3Y:
	dc.w	$d001,$fffe
WF_PaletteBg3:
	dc.w	$0180,$0222
WF_PaletteLine3:
	dc.w	$0184,$0555
	dc.w	$0186,$0555
	dc.w	$0188,$0cde
	dc.w	$018a,$0cde
	dc.w	$018c,$0cde
	dc.w	$018e,$0cde

	dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

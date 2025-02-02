************************************************************
*
* Main routines
*
************************************************************
        SECTION WordChanger, CODE_P

        include	"include/blitter.i"
        include	"include/macros.i"

MOVEMENT_TABLE_SIZE     = 32+32+(27*5)+1
WC_SCR_HEIGHT           = 256-(48*2)
WC_DOTS		        = 12

WC_COL1 =       $0234
WC_COL2 =       $0234
WC_COL3 =       $0234
WC_COL4 =       $0567
WC_COL5 =       $0678
WC_COL6 =       $0345
WC_COL7 =       $0345

************************************************************
* Initialize
************************************************************
WordChanger_Init_Credits:
        move.l  #WC_Words_Credits,WC_WordsPtr
        bra.s   WordChanger_Init

WordChanger_Init_Greetings:
        clr.w   WC_IsCredits
        move.w  #5,WC_FadeStep
        clr.l   WC_LocalFrameCounter
        move.l  #WC_Words_Greetings,WC_WordsPtr

WordChanger_Init:
	lea.l	$dff000,a6

        lea.l   WC_MovementTablePtr,a0
        moveq   #10-1,d7
.reset: move.l  (a0),a1
        move.w  #-(128-32),(a1)+
        move.w  #-1000,(a1)
        add.l   #4,a0
        dbf     d7,.reset

	move.l	DrawBuffer,a0
        move.l  #((WC_SCR_HEIGHT*5)<<6)+(320>>4),d0
        jsr	BltClr
	WAITBLIT

        move.l  ViewBuffer,a0
        adda.l  #(320*256*4)>>3,a0
        move.l  #((48*2)<<6)+(320>>4),d0
        jsr     BltClr
        WAITBLIT

        move.l  DrawBuffer,a0
        lea.l   WC_BplPtrs,a1
        moveq   #4-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #40,a0
        adda.l  #8,a1
        dbf     d7,.setBpls

        move.l  DrawBuffer,a0
        adda.l  #((WC_SCR_HEIGHT*3)*40)+((128-33)*40),a0
        move.l  #65*10-1,d7
.fill:  move.l  #$ffffffff,(a0)+
        dbf     d7,.fill

        move.l  DrawBuffer,d0
        add.l   #(320*256*4)>>3,d0
        move.l  d0,WC_Dots_DrawBuffer
        move.l  ViewBuffer,d0
        add.l   #(320*256*4)>>3,d0
        move.l  d0,WC_Dots_ViewBuffer

        move.l  WC_Dots_ViewBuffer,d0
        lea.l   WC_DotLines_BplPtrs,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        swap    d0
        add.l   #48*40,d0
        lea.l   WC_DotLines_BplPtrs2,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)

    	move.l	#WC_Copper,$80(a6)

        rts

************************************************************
* Run
************************************************************
WordChanger_Run_Credits:
        cmp.w   #0,WC_FadeStep
        bne.s   .fadeIn
        jsr     InitFade
        move.w  #1,WC_FadeStep
.fadeIn:
        cmp.w   #1,WC_FadeStep
        bne.s   .fadeWait
        lea.l   WC_FromPal(pc),a0
        lea.l   WC_FontPal+2(pc),a1
        lea.l   WC_CopCols,a2
        moveq   #8,d0
        moveq   #7-1,d1
        jsr     Fade
        cmp.w   #9,d0
        bne.s   .doWords
        move.l  WC_LocalFrameCounter,WC_FadeWait
        move.w  #2,WC_FadeStep
        bra.s   .doWords

.fadeWait:
        cmp.w   #2,WC_FadeStep
        bne.s   .initFadeOut
        move.l  WC_FadeWait(pc),d0
        add.l   #10,D0
        cmp.l   WC_LocalFrameCounter,d0
        bne.s   .doWords
        move.w  #3,WC_FadeStep
        bra.s   .doWords

.initFadeOut:
        cmp.w   #3,WC_FadeStep
        bne.s   .fadeOut
        jsr     InitFade
        move.w  #4,WC_FadeStep
.fadeOut:
        cmp.w   #4,WC_FadeStep
        bne.s   .doWords
        lea.l   WC_FontPal+2(pc),a0
        lea.l   WC_FromPal(pc),a1
        lea.l   WC_CopCols,a2
        moveq   #8,d0
        moveq   #7-1,d1
        jsr     Fade
        cmp.w   #9,d0
        bne.s   .doWords
        move.w  #5,WC_FadeStep

.doWords:
        move.l  WC_Credits_TimingTablePtr(pc),a0
        move.l  (a0),d0
        cmp.l   #-1,d0
        beq.s   .done
        cmp.l   WC_LocalFrameCounter,d0
        bne.s   .render
        bsr     WC_CreateWordsMovementTable
        add.l   #4,WC_Credits_TimingTablePtr
        bra     .render
.render:
        movem.l	WC_Dots_DrawBuffer,a2-a3
        exg	a2,a3
        movem.l	a2-a3,WC_Dots_DrawBuffer

        move.l	a3,d0
        lea.l   WC_DotLines_BplPtrs,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        swap    d0
        add.l   #48*40,d0
        lea.l   WC_DotLines_BplPtrs2,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)

        move.l	a2,a0
        move.l  #(96<<6)+(320>>4),d0
        jsr	BltClr
        WAITBLIT

        bsr     WC_RenderLetters
        bsr     WC_RenderDotLineEffect
.done:
        addq.l  #1,WC_LocalFrameCounter
        rts

GREETINGS_ROWS = 46
TIME_PER_GREET = 70
WordChanger_Run_Greetings:
        cmp.w   #0,WC_FadeStep
        bne.s   .fadeIn
        jsr     InitFade
        move.w  #1,WC_FadeStep
.fadeIn:
        cmp.w   #1,WC_FadeStep
        bne.s   .fadeWait
        lea.l   WC_FromPal(pc),a0
        lea.l   WC_FontPal+2(pc),a1
        lea.l   WC_CopCols,a2
        moveq   #8,d0
        moveq   #7-1,d1
        jsr     Fade
        cmp.w   #9,d0
        bne.s   .doWords
        move.l  WC_LocalFrameCounter,WC_FadeWait
        move.w  #2,WC_FadeStep
        bra.s   .doWords

.fadeWait:
        cmp.w   #2,WC_FadeStep
        bne.s   .initFadeOut
        move.l  WC_FadeWait(pc),d0
        add.l   #10,D0
        cmp.l   WC_LocalFrameCounter,d0
        bne.s   .doWords
        move.w  #3,WC_FadeStep
        bra.s   .doWords

.initFadeOut:
        cmp.w   #3,WC_FadeStep
        bne.s   .fadeOut
        jsr     InitFade
        move.w  #4,WC_FadeStep
.fadeOut:
        cmp.w   #4,WC_FadeStep
        bne.s   .doWords
        lea.l   WC_FontPal+2(pc),a0
        lea.l   WC_FromPal(pc),a1
        lea.l   WC_CopCols,a2
        moveq   #8,d0
        moveq   #7-1,d1
        jsr     Fade
        cmp.w   #9,d0
        bne.s   .doWords
        move.w  #5,WC_FadeStep

.doWords:
        move.l  WC_TriggerFrame(pc),d0
        cmp.l   #25+(GREETINGS_ROWS*TIME_PER_GREET),d0
        beq.s   .done
        cmp.l   WC_LocalFrameCounter,d0
        bne.s   .render
        bsr     WC_CreateWordsSameMovementTable
        add.l   #TIME_PER_GREET,WC_TriggerFrame
        bra     .render
.render:
        movem.l	WC_Dots_DrawBuffer,a2-a3
        exg	a2,a3
        movem.l	a2-a3,WC_Dots_DrawBuffer

        move.l	a3,d0
        lea.l   WC_DotLines_BplPtrs,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        swap    d0
        add.l   #48*40,d0
        lea.l   WC_DotLines_BplPtrs2,a1
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)

        move.l	a2,a0
        move.l  #(96<<6)+(320>>4),d0
        jsr	BltClr
        WAITBLIT

        bsr     WC_RenderLetters
        bsr     WC_RenderDotLineEffect
.done:  addq.l  #1,WC_LocalFrameCounter
        rts

************************************************************
* Interrupt
************************************************************
WordChanger_Interrupt:

        rts

************************************************************
*
* Effect routines
*
************************************************************
LETTERS = 10

; Individual movment speeds
WC_CreateWordsMovementTable:
        move.l  WC_WordsPtr(pc),a5
        lea.l   WC_MovementTable,a4
        lea.l   WC_MovementTablePtr(pc),a3

        moveq   #LETTERS-1,d6
.createMovement:
        move.l  a4,(a3)+
        move.l  a4,a0
        move.b  (a5),d0
        move.b  LETTERS(a5),d1
        bsr     WC_CreateMovementTable

        add.l   #(MOVEMENT_TABLE_SIZE*2),a4
        addq.l  #1,a5
        dbf     d6,.createMovement

        add.l  #LETTERS,WC_WordsPtr
        rts

STEPSIZE        = 13    ; 65 / 5
EASE_VALUES     = 8
; WC_CreateMovementTable
; Input:
;   a0 = Destination table
;   d0 = Source char
;   d1 = Target char
WC_CreateMovementTable:
        lea.l   WC_LetterPositions(pc),a1

        sub.b   #'@',d0
        sub.b   #'@',d1
        cmp.b   d0,d1
        beq     .noMovement

        and.w   #$ff,d0
        and.w   #$ff,d1

        move.w  d1,d5
        add.w   d5,d5
        move.w  (a1,d5.w),d5

        sub.w   d0,d1
        bmi.s   .moveUp

        subq.w  #1,d1
        mulu    #5,d1
        subq.w  #1,d1

        add.w   d0,d0
        move.w  (a1,d0.w),d0

        ; Add ease-out movement
        lea.l   WC_EaseOut(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeOut:
        move.w  (a2)+,d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeOut
        move.w  d2,d0

        ; Add middle movement
        cmp.w   #-1,d1
        beq.s   .doEaseIn
.middle:
        add.w   #STEPSIZE,d0
        move.w  d0,(a0)+
        dbf     d1,.middle
.doEaseIn:

        ; Add ease-out movement
        lea.l   WC_EaseIn(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeIn:
        move.w  (a2)+,d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeIn

        move.w  d5,(a0)+
        move.w  #-1000,(a0)+
        rts

.moveUp:
        neg.w   d1
        subq.w  #1,d1
        mulu    #5,d1
        subq.w  #1,d1

        add.w   d0,d0
        move.w  (a1,d0.w),d0

        ; Add ease-out movement
        lea.l   WC_EaseOut(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeOutUp:
        move.w  (a2)+,d2
        neg.w   d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeOutUp
        move.w  d2,d0

        ; Add middle movement
        cmp.w   #-1,d1
        beq.s   .doEaseInUp
.middleUp:
        sub.w   #STEPSIZE,d0
        move.w  d0,(a0)+
        dbf     d1,.middleUp
.doEaseInUp:

        ; Add ease-out movement
        lea.l   WC_EaseIn(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeInUp:
        move.w  (a2)+,d2
        neg.w   d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeInUp

        move.w  d5,(a0)+
        move.w  #-1000,(a0)+
        rts

.noMovement:
        move.w  #-1000,(a0)
        rts

; Same movement speeds
WC_CreateWordsSameMovementTable:
        move.l  WC_WordsPtr(pc),a5
        lea.l   WC_MovementTable,a4
        lea.l   WC_MovementTablePtr(pc),a3

        moveq   #LETTERS-1,d6
.createMovement:
        move.l  a4,(a3)+
        move.l  a4,a0
        move.b  (a5),d0
        move.b  LETTERS(a5),d1
        bsr     WC_CreateSameMovementTable

        add.l   #(MOVEMENT_TABLE_SIZE*2),a4
        addq.l  #1,a5
        dbf     d6,.createMovement

        add.l  #LETTERS,WC_WordsPtr
        rts

; WC_CreateSameMovementTable
; Input:
;   a0 = Destination table
;   d0 = Source char
;   d1 = Target char
WC_CreateSameMovementTable:
        lea.l   WC_LetterPositions(pc),a1

        sub.b   #'@',d0
        sub.b   #'@',d1
        cmp.b   d0,d1
        beq     .noMovement

        and.w   #$ff,d0
        and.w   #$ff,d1

        move.w  d1,d5
        add.w   d5,d5
        move.w  (a1,d5.w),d5

        sub.w   d0,d1
        bmi.s   .moveDown

        subq.w  #1,d1
        mulu    #65,d1
        lsl.w   #3,d1
        lsr.w   #5,d1

        add.w   d0,d0
        move.w  (a1,d0.w),d0

        ; Add ease-out movement
        lea.l   WC_EaseOut(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeOut:
        move.w  (a2)+,d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeOut
        move.w  d2,d0

        ; Add middle movement
        cmp.w   #-1,d1
        beq.s   .doEaseIn
        moveq   #32-1,d7
        move.w  d1,d2
.middle:
        ; add.w   #STEPSIZE,d0
        move.w  d2,d3
        lsr.w   #3,d3
        add.w   d0,d3
        move.w  d3,(a0)+
        add.w   d1,d2
        dbf     d7,.middle
.doEaseIn:
        move.w  d3,d0

        ; Add ease-out movement
        lea.l   WC_EaseIn(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeIn:
        move.w  (a2)+,d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeIn

        move.w  d5,(a0)+
        move.w  #-1000,(a0)+
        rts

.moveDown:
        neg.w   d1
        subq.w  #1,d1
        mulu    #65,d1
        lsl.w   #3,d1
        lsr.w   #5,d1

        add.w   d0,d0
        move.w  (a1,d0.w),d0

        ; Add ease-out movement
        lea.l   WC_EaseOut(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeOutDown:
        move.w  (a2)+,d2
        neg.w   d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeOutDown
        move.w  d2,d0

        ; Add middle movement
        cmp.w   #-1,d1
        beq.s   .doEaseInDown
        moveq   #32-1,d7
        move.w  d1,d2
.middleDown:
        move.w  d2,d3
        lsr.w   #3,d3
        move.w  d0,d4
        sub.w   d3,d4
        move.w  d4,(a0)+
        add.w   d1,d2
        dbf     d7,.middleDown
        move.w  d4,d0
.doEaseInDown:

        ; Add ease-out movement
        lea.l   WC_EaseIn(pc),a2
        moveq   #EASE_VALUES-1,d7
.easeInDown:
        move.w  (a2)+,d2
        neg.w   d2
        add.w   d0,d2
        move.w  d2,(a0)+
        dbf     d7,.easeInDown

        move.w  d5,(a0)+
        move.w  #-1000,(a0)+
        rts

.noMovement:
        move.w  #-1000,(a0)
        rts

WC_RenderLetters:
        move.w	#SRCA|DEST|A_TO_D,bltcon0(a6)
        clr.w   bltcon1(a6)
        move.l	#-1,bltafwm(a6)
        move.w	#0,bltamod(a6)
        move.w	#36,bltdmod(a6)

        lea.l   WC_MovementTablePtr(pc),a0
        moveq   #0,d0
        moveq   #0,d2
        moveq   #LETTERS-1,d7
.print:
        move.l  (a0),a1
        move.w  (a1),d1
        cmp.w   #-1000,d1
        beq.s   .onTarget
        addq.l  #2,(a0)

        muls    #12,d1

        lea.l   BigFont,a2
        add.l   d1,a2
        move.l	a2,bltapt(a6)
        
        move.l	DrawBuffer,a2
        add.l   d0,a2
        move.l  a2,bltdpt(a6)
        
        move.w	#((WC_SCR_HEIGHT*3)<<HSIZEBITS)|2,bltsize(a6)
        WAITBLIT

        addq.w  #4,d0
        addq.l  #4,a0
        bra.s   .next
.onTarget:
        addq.w  #4,d0
        addq.l  #4,a0
        addq.w  #1,d2
.next:
        dbf     d7,.print

        cmp.w   #LETTERS,d2
        bne.s   .done
        cmp.w   #5,WC_FadeStep
        bne.s   .done

.clearFade:
        clr.w   WC_FadeStep

.done:  rts

WC_RenderDotLineEffect:
        move.l	WC_Dots_DrawBuffer,a0
        lea.l	WC_Dots,a1
        lea.l	Mulu40,a2

        ; Render dots
        moveq	#WC_DOTS-1,d7
.loop:	move.w	(a1),d0
        lsr.w	#4,d0
        move.w	d0,8(a1)
        move.w	2(a1),d1
        lsr.w	#4,d1
        move.w	d1,10(a1)

        add.w	d1,d1
        move.w	(a2,d1.w),d1

        move.w	d0,d3
        move.w	d1,d4

        move.w	d0,d2
        lsr.w	#3,d0
        add.w	d0,d1
        
        and.b	#$7,d2
        not.b	d2
        bset.b	d2,(a0,d1.w)
        bset.b	d2,40(a0,d1.w)

        move.w	d3,d0
        addq.w	#1,d0
        move.w	d0,d2
        lsr.w	#3,d0
        move.w	d4,d1
        add.w	d0,d1
        
        and.b	#$7,d2
        not.b	d2
        bset.b	d2,(a0,d1.w)
        bset.b	d2,40(a0,d1.w)

        move.w	(a1),d0
        add.w	4(a1),d0
        tst.w	d0
        bge.s	.xOk
        add.w	#320*16,d0
.xOk:	cmp.w	#320*16,d0
        bmi.s	.xOk2
        sub.w	#320*16,d0
.xOk2:	move.w	d0,(a1)

        move.w	2(a1),d0
        add.w	6(a1),d0
        tst.w	d0
        bge.s	.yOk
        add.w	#96*16,d0
.yOk:	cmp.w	#96*16,d0
        bmi.s	.yOk2
        sub.w	#96*16,d0
.yOk2:	move.w	d0,2(a1)

        adda.l	#12,a1

        dbf	d7,.loop

        ; Render lines
        WAITBLIT
        jsr	DL_Init
        
        lea.l	WC_Dots,a2
        adda.l	#8,a2

        moveq	#WC_DOTS-1,d7
.outer:
        tst.w	d7
        beq	.done

        lea.l	12(a2),a3
        move.w	d7,d6
        subq.w	#1,d6
.inner:

        ; Calculate Chebyshev Distance
        move.w	(a2),d0
        sub.w	(a3),d0
        bpl.s	.lxOk
        neg.w	d0
.lxOk: 
        move.w	2(a2),d1
        sub.w	2(a3),d1
        bpl.s	.lyOk
        neg.w	d1
.lyOk:
        cmp.w	d0,d1
        ble.s	.ok
        exg	d0,d1
.ok:
        ; If distance between 2 points is less than 40 px, render line
        cmp.w	#40,d0
        bgt	.skip

        ; Drawline
        move.l	WC_Dots_DrawBuffer,a0
        move.w	(a2),d0
        move.w	2(a2),d1
        move.w	(a3),d2
        move.w	2(a3),d3
        moveq	#40,d4
        jsr	DrawLine
        WAITBLIT

.skip:	lea.l	12(a3),a3
        dbf	d6,.inner
        lea.l	12(a2),a2
        dbf	d7,.outer
.done:  
        rts

************************************************************
*
* Variables and data
*
************************************************************
        even
WC_LocalFrameCounter:   dc.l    0
WC_TriggerFrame:        dc.l    25

WC_FromPal:             dc.w	WC_COL1,WC_COL2,WC_COL3,WC_COL4,WC_COL5,WC_COL6,WC_COL7
WC_FontPal:             incbin  "data/graphics/font_32x65_1751x3.PAL"

WC_FadeStep:            dc.w    5
WC_FadeWait:            dc.l    0
WC_IsCredits:           dc.w    1
WC_Credits_TimingTablePtr:
                        dc.l    WC_Credits_TimingTable
WC_Credits_TimingTable: dc.l    25
                        dc.l    25+110  ; Code
                        dc.l    25+250  ; Prospect
                        dc.l    25+390  ; Music
                        dc.l    25+530  ; Alpa
                        dc.l    25+690  ; Gfx
                        dc.l    25+850  ; Corel
                        dc.l    25+1000  ; TmX Vedder
                        dc.l    -1

WC_Words_Credits:       dc.b    '@@@@@@@@@@'
                        dc.b    'CODE@@@@@@'
                        dc.b    '@PROSPECT@'
                        dc.b    '@@MUSIC@@@'
                        dc.b    '@@@ALPA@@@'
                        dc.b    '@@@@@@@GFX'
                        dc.b    '@COREL@@@@'
                        dc.b    'TMX@VEDDER'

WC_Words_Greetings:     dc.b    '@@@@@@@@@@'
                        dc.b    'GREETINGS@'
                        dc.b    '@@@@@@@@@@'
                        dc.b    'SPACEBALLS'
                        dc.b    'PHENOMENA@'
                        dc.b    '@LOONIES@@'
                        dc.b    'NECTARINE@'
                        dc.b    '@@DESIRE@@'
                        dc.b    '@SCOOPEX@@'
                        dc.b    '@@RAZOR@@@'
                        dc.b    'ANDROMEDA@'
                        dc.b    'BITBENDAZ@'
                        dc.b    '@EPHIDRENA'
                        dc.b    '@@@@HMF@@@'
                        dc.b    'E@R@R@O@L@'
                        dc.b    '@@@SMFX@@@'
                        dc.b    '@PACIFIC@@'
                        dc.b    '@SCENESAT@'
                        dc.b    '@@OFFENCE@'
                        dc.b    '@@UPROUGH@'
                        dc.b    'NICEPIXEL@'
                        dc.b    '@@TOLOU@@@'
                        dc.b    'PLANETJAZZ'
                        dc.b    '@@@@DHS@@@'
                        dc.b    '@@@@GP@@@@'
                        dc.b    'SLAYRADIO@'
                        dc.b    '@THEGANG@@'
                        dc.b    '@@@TBL@@@@'
                        dc.b    '@LOGICOMA@'
                        dc.b    'FAIRLIGHT@'
                        dc.b    '@@@LEMON@@'
                        dc.b    '@NAHKOLOR@'
                        dc.b    '@@@@TEK@@@'
                        dc.b    '@@STRUTS@@'
                        dc.b    'FOCUS@DSGN'
                        dc.b    '@@@FFP@@@@'
                        dc.b    '@@REBELS@@'
                        dc.b    '@REALITY@@'
                        dc.b    '@@NUKLEUS@'
                        dc.b    '@TRAKTOR@@'
                        dc.b    '@@NEWBEAT@'
                        dc.b    '@@NATURE@@'
                        dc.b    '@@ISTARI@@'
                        dc.b    '@OUTBREAK@'
                        dc.b    '@@@KESO@@@'
                        dc.b    'FJALLDATA@'

WC_WordsPtr:            dc.l    0
                        dcb.w   2,0
WC_LetterPositions:      
LETTER                  SET     0
                        REPT    27
                        dc.w    (LETTER*65)-((WC_SCR_HEIGHT/2)-32)
LETTER                  SET     LETTER+1
                        ENDR
                        dcb.w   2,0

WC_EaseOut:             dc.w    0, 0, 2, 4, 8, 16, 23, 32
WC_EaseIn:              dc.w    0, 7, 14, 20, 25, 29, 31, 33
WC_MovementTablePtr:    dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*0
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*1
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*2
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*3
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*4
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*5
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*6
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*7
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*8
                        dc.l    WC_MovementTable+(MOVEMENT_TABLE_SIZE*2)*9

WC_Dots_DrawBuffer:     dc.l    0
WC_Dots_ViewBuffer:     dc.l    0
WC_Dots:                dc.w 3888,1120,-5,-4,0,0
                        dc.w 4848,1248,10,10,0,0
                        dc.w 2160,0,-5,9,0,0
                        dc.w 416,240,-13,8,0,0
                        dc.w 3792,48,-5,13,0,0
                        dc.w 1136,1312,12,8,0,0
                        dc.w 4032,240,13,-14,0,0
                        dc.w 4208,368,-6,-11,0,0
                        dc.w 4864,1488,-10,-15,0,0
                        dc.w 1584,80,-2,2,0,0
                        dc.w 3920,528,-6,12,0,0
                        dc.w 3680,384,4,12,0,0
                        dc.w 4256,1472,-14,-4,0,0
                        dc.w 3968,112,10,-8,0,0
                        dc.w 3168,416,6,10,0,0
                        dc.w 944,1088,-12,7,0,0
                        dc.w 2672,1184,0,12,0,0
                        dc.w 1904,1472,12,-3,0,0
                        dc.w 4144,1072,-11,-7,0,0
                        dc.w 4528,1008,1,4,0,0
                        dc.w 3536,1120,0,-5,0,0
                        dc.w 4352,512,5,-1,0,0
                        dc.w 5056,896,4,3,0,0
                        dc.w 3408,1120,10,13,0,0
                        dc.w 2720,112,12,10,0,0
                        dc.w 3872,528,14,-15,0,0
                        dc.w 4320,1152,-12,1,0,0
                        dc.w 720,816,12,3,0,0
                        dc.w 4448,112,2,3,0,0
                        dc.w 4144,480,-15,11,0,0
                        dc.w 1184,464,-13,15,0,0
                        dc.w 3472,1328,-1,-6,0,0
                        dc.w 2848,1008,-15,-1,0,0
                        dc.w 112,1072,-3,9,0,0
                        dc.w 1824,592,-5,10,0,0
                        dc.w 1568,304,0,7,0,0
                        dc.w 4448,688,-12,2,0,0
                        dc.w 832,144,13,9,0,0
                        dc.w 4752,48,-9,5,0,0
                        dc.w 2096,48,5,-9,0,0
                        dc.w 4160,944,12,9,0,0
                        dc.w 4704,1296,5,14,0,0
                        dc.w 2528,1040,-2,4,0,0
                        dc.w 1040,656,-5,-2,0,0
                        dc.w 4032,496,-15,-5,0,0
                        dc.w 2000,896,14,1,0,0
                        dc.w 1424,1408,15,4,0,0
                        dc.w 1520,1200,-1,-15,0,0

************************************************************
*
* Copper
*
************************************************************
        SECTION WC_Copper, CODE_C
WC_Copper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,0
	dc.w	$010a,0
        dc.w    $0100,$0200

	dc.w	$0180,$0012,$0182,$0234
WC_DotLines_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
        dc.w    $0100,$1200

        dc.b    $2c+47,$01
        dc.w    $fffe
        dc.w    $0180,$0456,$0100,$0200
        dc.b    $2c+48,$01
        dc.w    $fffe
        dc.w    $0100,$3200,$0180,$0012
	dc.w	$0108,80
	dc.w	$010a,80

WC_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

	dc.w	$0182,WC_COL1,$0184,WC_COL2,$0186,WC_COL3
	dc.w	$0188,WC_COL4,$018a,WC_COL5,$018c,WC_COL6,$018e,WC_COL7
	dc.w	$0190,$0012
        dc.w    $0192,WC_COL1,$0194,WC_COL2,$0196,WC_COL3
	dc.w	$0198,WC_COL4,$019a,WC_COL5,$019c,WC_COL6,$019e,WC_COL7

        dc.b    $2c+128-33,$01
        dc.w    $fffe
WC_CopCols:
	dc.w	$0182,WC_COL1,$0184,WC_COL2,$0186,WC_COL3
	dc.w	$0188,WC_COL4,$018a,WC_COL5,$018c,WC_COL6,$018e,WC_COL7
WC_FadeCols:
        dc.w    $0192,WC_COL1,$0194,WC_COL2,$0196,WC_COL3
	dc.w	$0198,WC_COL4,$019a,WC_COL5,$019c,WC_COL6,$019e,WC_COL7

        dc.b    $2c+128+32,$01
        dc.w    $fffe
	dc.w	$0182,WC_COL1,$0184,WC_COL2,$0186,WC_COL3
	dc.w	$0188,WC_COL4,$018a,WC_COL5,$018c,WC_COL6,$018e,WC_COL7
        dc.w    $0192,WC_COL1,$0194,WC_COL2,$0196,WC_COL3
	dc.w	$0198,WC_COL4,$019a,WC_COL5,$019c,WC_COL6,$019e,WC_COL7

        dc.w    $fb01,$fffe,$0100,$0200,$0180,$0456
        dc.w    $fc01,$fffe,$0180,$0012
	dc.w	$0108,0
	dc.w	$010a,0

	dc.w	$0180,$0012,$0182,$0234
WC_DotLines_BplPtrs2:
	dc.w	$00e0,$0000,$00e2,$0000
        dc.w    $0100,$1200

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

************************************************************
*
* Copper
*
************************************************************
        SECTION WC_Extra, BSS_P

WC_MovementTable:       ds.w    MOVEMENT_TABLE_SIZE*10

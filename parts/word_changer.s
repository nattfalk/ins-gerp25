************************************************************
*
* Main routines
*
************************************************************
        SECTION WordChanger, CODE_P

        include	"include/blitter.i"
        include	"include/macros.i"

MOVEMENT_TABLE_SIZE     = 32+32+(27*5)+1
************************************************************
* Initialize
************************************************************
WordChanger_Init_Credits:
        move.l  #WC_Words_Credits,WC_WordsPtr
        bra.s   WordChanger_Init

WordChanger_Init_Greetings:
        move.w  #5,WC_FadeStep
        clr.l   WC_LocalFrameCounter
        move.l  #WC_Words_Greetings,WC_WordsPtr

WordChanger_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #((256*4)<<6)+(320>>4),d0
        jsr	BltClr
	jsr	WaitBlitter

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
        adda.l  #(768*40)+((128-33)*40),a0
        move.l  #65*10-1,d7
.fill:  move.l  #$ffffffff,(a0)+
        dbf     d7,.fill

;         lea.l   WC_FontPal+2(pc),a0
;         lea.l   WC_CopCols,a1
;         moveq   #7-1,d7
; .setColor:
;         move.w  (a0)+,2(a1)
;         adda.l  #4,a1
;         dbf     d7,.setColor

    	move.l	#WC_Copper,$80(a6)

        lea.l   WC_MovementTablePtr,a0
        moveq   #10-1,d7
.reset: move.l  (a0),a1
        move.w  #-(128-32),(a1)+
        move.w  #-1000,(a1)
        add.l   #4,a0
        dbf     d7,.reset

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
.render:bsr     WC_RenderLetters
.done:  addq.l  #1,WC_LocalFrameCounter
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
.render:bsr     WC_RenderLetters
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
        
        move.w	#(768<<HSIZEBITS)|2,bltsize(a6)
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

        clr.w   WC_FadeStep

.done:  rts

************************************************************
*
* Variables and data
*
************************************************************
        even
WC_LocalFrameCounter:   dc.l    0
WC_TriggerFrame:        dc.l    25

WC_FromPal:             dc.w	$0222,$0222,$0222
                        dc.w	$0555,$0666,$0333,$0333
WC_FontPal:             incbin  "data/graphics/font_32x65_1751x3.PAL"

WC_FadeStep:            dc.w    5
WC_FadeWait:            dc.l    0
WC_Credits_TimingTablePtr:
                        dc.l    WC_Credits_TimingTable
WC_Credits_TimingTable: dc.l    25
                        dc.l    25+110  ; Code
                        dc.l    25+250  ; Prospect
                        dc.l    25+390  ; Music
                        dc.l    25+530  ; Alpa
                        dc.l    25+690  ; Gfx
                        dc.l    25+850  ; Corel
                        dc.l    25+960  ; TmX
                        dc.l    25+1100 ; Vedder
                        dc.l    25+1240 ; 
                        dc.l    25+1500 ; Insane
                        dc.l    -1

WC_Words_Credits:       dc.b    '@@@@@@@@@@'
                        dc.b    'CODE@@@@@@'
                        dc.b    '@PROSPECT@'
                        dc.b    '@@MUSIC@@@'
                        dc.b    '@@@ALPA@@@'
                        dc.b    '@@@@@@@GFX'
                        dc.b    '@COREL@@@@'
                        dc.b    '@@@TMX@@@@'
                        dc.b    '@@@VEDDER@'
                        dc.b    '@@@@@@@@@@'
                        dc.b    '@@INSANE@@'

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
                        dc.w    (LETTER*65)-(128-32)
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
	dc.w	$0108,80
	dc.w	$010a,80
        dc.w    $0100,$0200

	dc.w	$0180,$0012
        ; dc.w    $0182,$0222,$0184,$0222,$0186,$0222
	; dc.w	$0188,$0222,$018a,$0222,$018c,$0222,$018e,$0222
	dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333
	dc.w	$0190,$0012
        dc.w    $0192,$0222,$0194,$0222,$0196,$0222
	dc.w	$0198,$0555,$019a,$0666,$019c,$0333,$019e,$0333

        dc.w    $0100,$3200
WC_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

        ; dc.b    $2c+128-35-90,$01
        ; dc.w    $fffe
	; ; dc.w	$0180,$0222,$0182,$0222,$0184,$0222,$0186,$0222
	; ; dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333
	; dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	; dc.w	$0188,$0333,$018a,$0444,$018c,$0333,$018e,$0333

        ; ; dc.b    $2c+128-35-60,$01
        ; ; dc.w    $fffe
	; ; ; dc.w	$0180,$0222,$0182,$0333,$0184,$0222,$0186,$0444
	; ; ; dc.w	$0188,$0888,$018a,$0999,$018c,$0555,$018e,$0666
	; ; dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	; ; dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333

        ; dc.b    $2c+128-35-8,$01
        ; dc.w    $fffe
	; dc.w	$0180,$0222,$0182,$0444,$0184,$0333,$0186,$0666
	; dc.w	$0188,$0ccc,$018a,$0ccc,$018c,$0999,$018e,$0999
	; dc.w	$0182,$0444,$0184,$0333,$0186,$0666
	; dc.w	$0188,$0ccc,$018a,$0ccc,$018c,$0999,$018e,$0999
	; dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	; dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333


        dc.b    $2c+128-33,$01
        dc.w    $fffe
WC_CopCols:
	dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333
	; dc.w	$0182,$0555,$0184,$0444,$0186,$0888
	; dc.w	$0188,$0eee,$018a,$0fff,$018c,$0bbb,$018e,$0ccc
WC_FadeCols:
        dc.w    $0192,$0222,$0194,$0222,$0196,$0222
	dc.w	$0198,$0555,$019a,$0666,$019c,$0333,$019e,$0333

        dc.b    $2c+128+32,$01
        dc.w    $fffe
	; dc.w	$0182,$0444,$0184,$0333,$0186,$0666
	; dc.w	$0188,$0ccc,$018a,$0ccc,$018c,$0999,$018e,$0999
	dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333
        dc.w    $0192,$0222,$0194,$0222,$0196,$0222
	dc.w	$0198,$0555,$019a,$0666,$019c,$0333,$019e,$0333

        ; dc.b    $2c+128+35+8,$01
        ; dc.w    $fffe
	; ; dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	; ; dc.w	$0188,$0555,$018a,$0666,$018c,$0333,$018e,$0333

        ; ; dc.w    $ffdf,$fffe
        ; ; dc.b    $2c+128+35+60-256,$01
        ; ; dc.w    $fffe
	; dc.w	$0182,$0222,$0184,$0222,$0186,$0222
	; dc.w	$0188,$0333,$018a,$0444,$018c,$0333,$018e,$0333

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

************************************************************
*
* Copper
*
************************************************************
        SECTION WC_Extra, BSS_P

WC_MovementTable:       ds.w    MOVEMENT_TABLE_SIZE*10

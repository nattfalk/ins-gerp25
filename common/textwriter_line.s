; a0 = Text
;      0   - End
;      1-3 - Color0-2
;      5,X - Wait X frames
;      10  - Newline
;      11  - New page (Not implemented!)
; a1 = Font
; a2 = Screen buffer
TextWriter_Line:
        ; tst.b   .waitCnt
        ; beq.s   .write
        ; sub.b   #1,.waitCnt
        ; bra     .done

.write: move.b  .col,d3
        move.w  .charIndex(pc),d0
        move.b  (a0,d0.w),d0
        tst.b   d0
        beq     .done

        cmp.b   #10,d0  ; Newline
        bne.s   .noNewLine
        clr.w   .x
        ; add.w   #9,.y
        add.w   #1,.charIndex
        bra    .done
.noNewLine:
        cmp.b   #1,d0
        bmi.s   .noColorChange
        cmp.b   #3,d0
        bgt.s   .noColorChange
        subq.b  #1,d0
        move.b  d0,.col
        add.w   #1,.charIndex
        bra.s   .write
.noColorChange:
        ; cmp.b   #5,d0
        ; bne.s   .noWait
        ; move.w  .charIndex(pc),d0
        ; move.b  1(a0,d0.w),d0
        ; move.b  d0,.waitCnt
        ; add.w   #2,.charIndex
        ; bra     TextWriter

.noWait:
        sub.b   #' ',d0
        and.w   #$ff,d0
        lsl.w   #3,d0
        ext.l   d0

        ; move.w  .y(pc),d1
        ; move.w  d1,d2
        ; lsl.w   #6,d1
        ; lsl.w   #4,d2
        ; add.w   d2,d1
        move.w   .x(pc),d1
        ext.l   d1

        move.l  a1,a3
        add.l   d0,a3

        move.l  a2,a4
        add.l   d1,a4
        
        tst.b   d3
        bne.s   .col2
I       SET     0
        REPT    8
        move.b  I(a3),I*80(a4)
I       SET     I+1
        ENDR
        bra   .next

.col2:
        cmp.b   #1,d3
        bne.w   .col3
I       SET     0
        REPT    8
        move.b  I(a3),I*80+40(a4)
I       SET     I+1
        ENDR
        bra.s   .next

.col3:
I       SET     0
        REPT    8
        move.b  I(a3),I*80(a4)
I       SET     I+1
        ENDR
I       SET     0
        REPT    8
        move.b  I(a3),I*80+40(a4)
I       SET     I+1
        ENDR

.next:  add.w   #1,.charIndex
        add.w   #1,.x
        bra     .write
.done:  rts

                even
.x:             dc.w    0
.y:             dc.w    0
.charIndex:     dc.w    0
.col:           dc.b    0
.waitCnt:       dc.b    0

************************************
* Calculate LERP for 128 steps
*
* a0 = Source values (word-sized)
* a1 = Target values
* a2 = Calculated values
* d0 = Current step (max 127)
* d7 = Number of values to process
Lerp128:
        cmp.w   #128,d0
        bge.s   .done
        subq.w  #1,d7
.lerp:  move.w  (a0)+,d1
        move.w  (a1)+,d2
        sub.w   d1,d2
        muls.w  d0,d2
        asr.w   #7,d2
        add.w   d1,d2
        move.w  d2,(a2)+
        dbf     d7,.lerp
.done:  rts

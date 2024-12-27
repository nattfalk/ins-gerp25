    ifnd    SINE_SCROLLER_I
SINE_SCROLLER_I = 1

SS_STEP_SIZE	= 12
SS_HEIGHT		= $60

SS_CALCY:		MACRO
                ifge	$ac+(\1*(SS_HEIGHT/2))+(SS_STEP_SIZE*\2)-$ff
                dc.b	$ac+(\1*(SS_HEIGHT/2))+(SS_STEP_SIZE*\2)-$ff,$01
                else
                dc.b	$ac+(\1*(SS_HEIGHT/2))+(SS_STEP_SIZE*\2),$01
                endif
                ENDM

    endc




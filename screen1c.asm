; PET/CBM Editor ROM Project - CODEBASE 0 - Screen line LO address table - Screen 1 @ $8800 Video (characters)
; ==========================   SCREEN1V.ASM
;
; These tables are used to calculate the starting address of each line on the screen

CLine_Addr_Lo:
!for i, 0, 24 {
	!byte <(COLOUR_RAM + (i * COLUMNS))
}

CLine_Addr_Hi:
!for i, 0, 24 {
	!byte >(COLOUR_RAM + (i * COLUMNS))
}

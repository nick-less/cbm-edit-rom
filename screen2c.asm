; PET/CBM Editor ROM Project - Screen line address table - Screen 2 @ $8800 Attributes (colour)
; ==========================   SCREEN2C.ASM
;
; These tables are used to calculate the starting address of each line on the screen


CLine_Addr_Lo2:
!for i, 0, ROWS-1 {
	!byte <(COLOUR_RAM + (i * COLUMNS))
}

CLine_Addr_Hi2:
!for i, 0, ROWS-1 {
	!byte >(COLOUR_RAM + (i * COLUMNS))
}


; PET/CBM Editor ROM Project - Screen line address table - Screen 2 @ $8000 Video (characters)
; ==========================   SCREEN2V.ASM
;
; Variables: ROWS, COLUMNS
; These tables are used to calculate the starting address of each line on the screen.
; The standard screens are 40x25 and 80x25. Experimental screens can be up to 90x35.
; 32 and 64 are included for future support of non-cbm type screens.
; When ROWS>25 it assumes maximum 35 rows although less are supported as well.


Line_Addr_Lo2:
!for i, 0, ROWS-1 {
	!byte <(COLOUR_RAM + (i * COLUMNS))
}

Line_Addr_Hi2:
!for i, 0, ROWS-1 {
	!byte >(COLOUR_RAM + (i * COLUMNS))
}


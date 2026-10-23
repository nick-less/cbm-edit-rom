;
; table for a 105 german ps2 keyboard, driven by a x16-smc based keyboard controller
;

; PET/CBM Editor ROM Project - Keyboard Matrix
keymap_matrix:
; 0x00 
!byte   0, '`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', $5C, $27, 0,   $14
; 0x10 
!byte   9, 'Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', '[', '+', '#',   0,   'A'
; 0x20 
!byte 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 0,   0,   '#', 13,  0,   '<','Y', 'X' 
; 0x30 
!byte 'C', 'V', 'B', 'N', 'M', $2C, '.', '-', 0,   0,   0, 0, 0, ' ', 0  , " "
; 0x40 
!byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 157
; 0x50 
!byte 19, 0, 0, 145, 17, 0, 0, 0, 0, 29, 0, 127, 0, 0, 0, 0
; 0x60 
!byte 0, 0, 0, 0, "/", "8", "5", "2", "0", "*", "9", "6", "3", '.', 27, "+"
; 0x70 
!byte 0, 13, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



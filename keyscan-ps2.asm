
;----------------------------------------------------------------------
; PET KERNAL PS/2 keyboard driver, 6502 
;----------------------------------------------------------------------

; The original routine mainly used these symbols/variables:

; - State and flag variables
;   - Key_Image
;     - Stores the currently determined keycode.
;   - KEYFLAGS
;     - Various keyboard flags, e.g. Shift status.
;   - RPTFLG
;     - Repeat flag; controls auto-repeat and repeat-disable.
;   - KEYPRESSED
;     - The last registered or currently held keycode.
;   - DELAY
;     - Repeat delay counter.
;   - KOUNT
;     - Repeat speed counter.
;   - CharsInBuffer
;     - Number of characters in the keyboard buffer.
;   - STKEY
;     - Used for the STOP-Key-Fix.

; - Keyboard/buffer variables
;   - KEYBOARD_NORMAL
;     - Matrix/Table data for the keyboard layout.
;   - KEYD
;     - The actual Keyboard buffer array.
;   - XMAX
;     - Maximum buffer size.

; In short: The kernel variables are:
; Key_Image, KEYFLAGS, RPTFLG, KEYPRESSED, DELAY, KOUNT, CharsInBuffer, KEYD, STKEY


I2C_ADDRESS      = $42
I2C_GET_KEYCODE  = $07

MOD_SHIFT = $01
MOD_CTRL  = $02
MOD_ALT   = $04
MOD_GUI   = $08
MOD_CAPS   = $10

modifier_scancodes:
!byte $2c, $39, $3a, $40, $3c, $3e, 63, 59, 30
;     RSh LSh RCt LCt RAl LAl RGu LGu
modifier_bit_indices:
!byte MOD_SHIFT,  MOD_SHIFT,  MOD_CTRL,  MOD_CTRL,  MOD_ALT,  MOD_ALT, MOD_GUI,  MOD_GUI, MOD_CAPS
MODIFIER_COUNT = 9




SCAN_KEYBOARD:
    ; read one keycode from SMC
    lda #I2C_ADDRESS
    ldx #I2C_GET_KEYCODE
    ldy #0
    jsr i2c_read_byte

    ; A = 0 means no key available
    beq no_key


check_modifier:
    pha                 ; Save the original scan code (with bit 7) on the stack
    and #$7F            ; Clear bit 7 for the clean scan code
     
    ldx #MODIFIER_COUNT-1
loop_mod:
    cmp modifier_scancodes,x
    beq found_modifier  ; Scan code found in the table!
    dex
    bpl loop_mod


    ; If not found: It's a normal key
    pla                 ; pull scancode
    jmp normal_key      

found_modifier:
    pla ; <- scan code from stack

    bmi clear_flag    
    ; X now holds the table index (0 to 8)
    lda modifier_bit_indices,x

set_flag:
    ; Key was pressed (bit 7 was 0)
    cmp #MOD_CAPS            ; Is it CapsLock 
    beq toggle_caps


    ora KEYFLAGS        ; press: set bit
    sta KEYFLAGS

    jmp done

clear_flag:
    lda modifier_bit_indices,x
    eor #$FF            ; Invert the mask (e.g., from %00000010 to %11111101)
    and KEYFLAGS        ; Clear the bit
    sta KEYFLAGS
    rts
toggle_caps:
    eor KEYFLAGS        ; CapsLock: toggle the bit
    sta KEYFLAGS
    rts
normal_key:
    ; key release: high bit set
    cmp #$80
    bcs key_release

    ; key press
    JMP process_key_press
no_key:
    rts

key_release:
    rts

process_key_press:
    tax
    lda keymap_matrix,x
    pha

   ; 1. Check CTRL
    lda KEYFLAGS
    and #MOD_CTRL
    beq check_alt        ; If CTRL not active (0), jump further
    pla
    and #$1F               ; Make 'A' ($41) a CTRL+A ($01). Filters bits 5-7.
    brk
    jmp SCAN_NORM2

check_alt:
   ; 1. Check ALT
    lda KEYFLAGS
    and #MOD_ALT
    beq check_shift        ; If CTRL not active (0), jump further
    pla

    cmp #'A'
    bcc out    ; If smaller than 'A', no letter
    cmp #'Z'+1
    bcs out    ; If greater than 'Z', no letter
    clc
    adc #96
out:    
    jmp SCAN_NORM2



pull_a_done:
    pla 
    jmp SCAN_NORM2


check_shift:
    ; 2. Check SHIFT
    lda KEYFLAGS
    and #MOD_SHIFT
    beq pull_a_done           ; If no Shift, we're done
    pla

    cmp #'A'
    bcc not_letter    ; If smaller than 'a', no letter
    cmp #'Z'+1
    bcs not_letter    ; If greater than 'z', no letter
    ora #$80
    jmp SCAN_NORM2
not_letter:

apply_shift_table:
    ldx #$00
loop_pairs:
    ldy shift_pairs,x
    beq SCAN_NORM2       ; End marker reached -> no change for this key
    cmp shift_pairs,x  ; Does the current character match the normal key?
    beq found_shift    ; Yes? Then replace!
    inx
    inx                ; Jump to the next pair
    bne loop_pairs     
found_shift:
    lda shift_pairs+1,x ; Load the following shifted character

; key in A
SCAN_NORM2
    ldx CharsInBuffer		; No. of Chars. in Keyboard Buffer (Queue)
    cpx XMAX                ; 4.80: Size of Keyboard Buffer
    bcs done
    sta KEYD,x
    inx 
    stx CharsInBuffer       ; No. of Chars. in Keyboard Buffer (Queue)

done:
    rts



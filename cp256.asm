
CF_READ_SECTOR_COMMAND = $20
CF_WRITE_SECTOR_COMMAND = $30
CF_ADDRESS = $E870
kernel_putc = $FFD2
buffer = $9000

CP256_Init
    LDA #255
;    STA $FFF1   ; new color reg
    STA $E850   ; old color reg

	JSR INIT_EDITOR					; Do Normal Initialization
    RTS
    RTS

cf_startup:
    jsr cf_init
    jsr cf_identify
    jsr cf_read_data
    jsr cf_print_model
    rts

cf_identify:
    lda #$EC            ; IDENTIFY DEVICE
    sta CF_ADDRESS+7
    jsr cf_wait_drq     ; auf DRQ warten
    bcs cf_err   ; Carry=1 → Fehler
    rts

cf_init:
    ; phy
    lda #$4
    ; ldy #7
    ; sta (CF_ADDRESS),y
    sta CF_ADDRESS + 7
    jsr cf_wait
    lda #$E0
    sta CF_ADDRESS + 6
    jsr cf_wait
    lda #$1
    sta CF_ADDRESS + 1
    jsr cf_wait
    lda #$EF
    sta CF_ADDRESS + 7
    jsr cf_wait
    jsr cf_err
    ; ply
    rts


cf_wait: 
    ; phy
    ; ldy #7
@wait_loop:
    ; lda (CF_ADDRESS), y
    lda CF_ADDRESS + 7
    and #$80
    bne @wait_loop
    ; ply
    rts

cf_err:
    ; phy
    jsr cf_wait
    ; ldy #7
    ; lda (CF_ADDRESS), y
    lda CF_ADDRESS + 7
    and #$01
    beq @exit
@exit_fail:
    lda #'!'
    jsr kernel_putc
@exit:
    ; ply
    rts

cf_wait_drq:
@loop:
    lda CF_ADDRESS+7
    and #$80            ; BSY?
    bne @loop           ; solange busy

    lda CF_ADDRESS+7
    and #$08            ; DRQ?
    beq @loop           ; warten bis DRQ=1

    clc                 ; Erfolg
    rts

cf_read_data:
    ldx #0
    ldy #2        ; 2 × 256 = 512 bytes

read_loop:
    lda CF_ADDRESS

    jsr kernel_putc
    sta buffer,x
    inx
    lda CF_ADDRESS
    sta buffer,x
    inx
    bne read_loop   ; solange X != 0

    dey
    bne read_loop
    rts

cf_print_model:
    ldx #54             ; Startoffset
@loop:
    lda buffer+1,x      ; high byte zuerst
    jsr kernel_putc
    lda buffer,x        ; dann low byte
    jsr kernel_putc
    inx
    inx
    cpx #94
    bne @loop
    rts



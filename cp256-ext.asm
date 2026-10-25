
I2C_DDR = VIA_DDR_B
I2C_PORT = VIA_Port_B


; fixme
i2c_addr = $8FFF
i2c_val  = $8FFE
I2C_TEMP = $8FFD
i2c_opt  = $8FFC

shift_pairs:
!byte '1', '!'
!byte '2', 34
!byte '3', 92
!byte '4', '$'
!byte '5', '%'
!byte '6', '&'
!byte '7', '/'
!byte '8', '('
!byte '9', ')'
!byte '0', '='
!byte '\\', '?'
!byte '+', '*'
!byte '#','\''
!byte ',', ';'
!byte '.', ':'
!byte '<', '>'
!byte '-', $ba
!byte $00          ; end of table


I2C_CMD_GET_VER1  = 0x30
I2C_CMD_GET_VER2  = 0x31
I2C_CMD_GET_VER3  = 0x32



kbd_init:
    lda #0
    sta KEYFLAGS
    sta i2c_addr 
    sta i2c_val  
    sta I2C_TEMP 
    sta CharsInBuffer 
    jsr I2C_INIT

    rts



!macro TSB .adr {
    pha
    ora .adr  ; OR memory with A
    sta .adr ; Store back
    pla
}

!macro TRB .adr {
    pha
    eor #$FF   ; Complement A (invert bits)
    and .adr  ; AND with memory
    sta .adr  ; Store back
    pla
}



!macro I2C_DATA_UP {
       LDA I2C_DDR         ; to make I2C_PORT7 an input and let it float up.
       AND #$7F
       STA I2C_DDR
}

!macro I2C_DATA_DN {
       LDA I2C_DDR         ; make I2C_PORT7 an output and pull it down since
       ORA #$80
       STA I2C_DDR
}

!macro I2C_CLK_UP {
       LDA I2C_DDR         ; to make I2C_PORT7 an input and let it float up.
       AND #$FE
       STA I2C_DDR
}

!macro I2C_CLK_DN {
       LDA I2C_DDR         ; make I2C_PORT0 an output and pull it down since
       ORA #$01
       STA I2C_DDR
}



i2c_read_byte 
       sta i2c_addr
       stx i2c_val
       jsr I2C_INIT

       jsr I2C_START
       
       lda i2c_addr
       asl        
       jsr I2C_SEND_BYTE
       
       lda i2c_val
       jsr I2C_SEND_BYTE

       jsr I2C_START        

       lda i2c_addr
       asl                  
       ora #$01             
       jsr I2C_SEND_BYTE

       jsr I2C_RCV_BYTE     
       pha                  

       jsr I2C_NAK
       jsr I2C_STOP

       pla               
       rts

I2C_INIT:
       ; Set up the port bit directions and values.  Leaves power off, clk & data low.
       LDA I2C_DDR
       AND #$7E            ; Bit 7 und Bit 0 im DDR auf 0 setzen
       STA I2C_DDR

       LDA I2C_PORT
       AND     #$7E
       STA I2C_PORT
       RTS       ; You might want to leave a delay to let the power die out so devices are really
 

I2C_START
          +I2C_DATA_UP
          +I2C_CLK_UP
          +I2C_DATA_DN
          INC   I2C_DDR         ; Clk down.  We now know the bit val, so just INC.
          +I2C_DATA_UP
          RTS
 ;-----------------------

I2C_STOP
        +I2C_DATA_DN
        +I2C_CLK_UP
        +I2C_DATA_UP
        INC   I2C_DDR         ; Clk down.  We now know the bit val, so just INC.
        +I2C_DATA_UP
        RTS

 ;-----------------------

I2C_ACK
       +I2C_DATA_DN        ; Acknowledge.  The ACK bit in I2C is the 9th bit of a "byte".
ia1:
       +I2C_CLK_UP         ;               and acknowledging consists of pulling it down.
       INC I2C_DDR         ; Clk down.  We know the bit val, so just INC.
       +I2C_DATA_UP
       RTS

 ;-----------------------

I2C_NAK  
       +I2C_DATA_UP        ; Not acknowledge.
       jmp ia1

 ;-----------------------

I2C_IS_ACK ; At end, N=0 means ACK.  N=1 means NAK.
       +I2C_DATA_UP        
       +I2C_CLK_UP
       BIT   I2C_PORT           ; Bit 7 (the data line) gets put in the N flag.
       bmi plus ; N=1
       lda #0
plus:
       sta I2C_TEMP
      
       LDA I2C_DDR
       ORA #1
       STA I2C_DDR

       LDA  I2C_TEMP
       RTS
 ;-----------------------


; send byte 
I2C_SEND_BYTE               ; Start with byte in A, and clock low.  Ends with I2C_ACK?.
       STA     I2C_TEMP        ; Store the byte in a variable so we can use A with TSB & TRB for data line.
       LDA     #$80      ; Init A for mask for TRB & TSB below.  A does not get disturbed below.
       LDX     #8              ; We will do 8 bits.
sIb2:  
       +TRB  I2C_DDR            ; Release data line.  This is like I2C_DATA_UP but saves 1 instruction.
       ASL  I2C_TEMP        ; Get next bit to send and put it in the C flag.
       BCS  sIb1
       +TSB I2C_DDR          ; If the bit was 0, pull data line down by making it an output.
sIb1:  DEC  I2C_DDR            ; Do a high pulse on the clock line.  Remember there's a 0 in the output
       INC  I2C_DDR            ; register bit, and DEC'ing I2C_DDR makes that bit an input, so it can float up.
       DEX                  ;    IOW, it's backwards from what it seems.
       BNE     sIb2
       JMP     I2C_IS_ACK        ; (JSR, RTS)


I2C_RCV_BYTE                ; Start with clock low.  Ends with byte in I2C_TEMP.  Do ACK bit seI2C_PORTrately.
       +I2C_DATA_UP             ; Make sure we're not holding the data line down.  Be ready to input data.
       LDX     #8              ; We will do 8 bits.  There's no need to init I2C_TEMP.
rIb1:  
       DEC  I2C_DDR            ; Set clock line high.
       ASL  I2C_TEMP        ; Get the forming byte's next bit position ready to accept the bit.
       BIT  I2C_PORT              ; Read the data line value into N flag.
       BPL  rIb2            ; If the data line was high,
       INC  I2C_TEMP     ; increment the 1's place to a 1 in the forming byte.  (ASL made bit 0 = 0.)
rIb2:  
       INC  I2C_DDR            ; Put clock line back low.
       DEX
       BNE     rIb1            ; Go back for next bit if there is one.
       LDA I2C_TEMP
       RTS



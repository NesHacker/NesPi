.segment "CODE"

.macro IncrementBcdDigits addr, bytes
  .repeat bytes, K
    lda addr + K
    and #$F0
    cmp #$50
    bcc :+
    clc
    lda #$30
    adc addr + K
    sta addr + K
  :
    lda addr + K
    and #$0F
    cmp #$05
    bcc :+
    clc
    lda #$03
    adc addr + K
    sta addr + K
  :
  .endrepeat
.endmacro

.proc binary_to_bcd
  address = $25
  output = $27
  ldy #0
  .repeat 5, K
    sty output + K
  .endrepeat
  lda (address), y
  sta output+4
  iny
  lda (address), y
  sta output+3
  ldy #$10
loop:
  IncrementBcdDigits output, 3
  asl output+4
  rol output+3
  rol output+2
  rol output+1
  rol output
  dey
  bne loop
  rts
.endproc

.macro BinaryToBcd valueAddress
  lda #.LOBYTE(valueAddress)
  sta binary_to_bcd::address
  lda #.HIBYTE(valueAddress)
  sta binary_to_bcd::address + 1
  jsr binary_to_bcd
.endmacro

.proc print_bcd
  address = $2A  ; 16-bit
  bytes = $2C
  tileOffset = $2D
  blankTile = $2E

  ldy #0
stripLeadingZeros:
  lda (address), y
  beq @next
  tax
  and #$F0
  bne printLoop
  lda blankTile
  sta $2007
  txa
  clc
  adc tileOffset
  sta $2007
  iny
  jmp printLoop
@next:
  iny
  cpy bytes
  beq printZero
  lda blankTile
  sta $2007
  sta $2007
  jmp stripLeadingZeros

printZero:
  lda blankTile
  sta $2007
  lda tileOffset
  sta $2007
  rts

printLoop:
  cpy bytes
  beq return
  lda (address), y
  tax
  and #$F0
  lsr
  lsr
  lsr
  lsr
  clc
  adc tileOffset
  sta $2007
  txa
  and #$0F
  clc
  adc tileOffset
  sta $2007
  iny
  jmp printLoop
return:
  rts
.endproc

.macro PrintBcd valueAddress, b, to, bt
  lda #.LOBYTE(valueAddress)
  sta print_bcd::address
  lda #.HIBYTE(valueAddress)
  sta print_bcd::address + 1
  lda b
  sta print_bcd::bytes
  lda to
  sta print_bcd::tileOffset
  lda bt
  sta print_bcd::blankTile
  jsr print_bcd
.endmacro

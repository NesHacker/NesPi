.segment "CODE"

; Helper macro to perform the double dabble "increment by 3" step.
;
; Note: this produces unrolled code, with the number of bytes used
; equal to 30 * bytes (assuming `addr` is in the zeropage). E.g.
; a 4 byte output will require 120 bytes of PRG-ROM code to perform
; the unrolled loop.
;
; @param addr Lowest byte of the double dabble scratch space.
; @param bytes Number of bytes in the output for the algorithm.
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

; Converts the given 8-bit binary value to BCD.
; @param addressLow $00 The low byte of the data address.
; @param addressHigh $01 The high byte of the data address.
; @return $10-$11 The nibble packed BCD result.
.proc proc_BinaryToBcd8
  addressLow = $00
  output = $10

  ; Setup the scratch space
  lda #0
  sta output
  sta output+1
  ldy #0
  lda (addressLow), y
  sta output+2

  ldy #8
loop:
  IncrementBcdDigits output, 2
  asl output+2
  rol output+1
  rol output
  dey
  bne loop

  rts
.endproc

; Helper macro for the 8-bit BCD conversion routine.
; @param address 16-bit address to the byte of data to convert.
.macro BinaryToBcd8 address
  lda #.LOBYTE(address)
  sta $00
  lda #.HIBYTE(address)
  sta $01
  jsr proc_BinaryToBcd8
.endmacro

; Converts the given 16-bit binary value to BCD.
; @param addressLow $00 The low byte of the data address.
; @param addressHigh $01 The high byte of the data address.
; @return $10-$12 The nibble packed BCD result.
.proc proc_BinaryToBcd16
  addressLow = $00
  output = $10

  ; Clear the scratch space
  ldy #0
  .repeat 5, K
    sty output + K
  .endrepeat

  ; Copy the value to convert
  lda ($00), y
  sta output+4
  iny
  lda ($00), y
  sta output+3

  ; Convert the value
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

; Helper macro for the 8-bit BCD conversion routine.
; @param address 16-bit address to the byte of data to convert.
.macro BinaryToBcd16 address
  lda #.LOBYTE(address)
  sta $00
  lda #.HIBYTE(address)
  sta $01
  jsr proc_BinaryToBcd16
.endmacro

; Prints BCD Digits in memory to the nametable. You must set the starting
; address in VRAM prior to calling this routine.
;
; @param $00 Low byte of binary data address.
; @param $01 High byte of binary data address.
; @param $02 The number of bytes of data to print.
; @param $03 Tile offset for the zero character in pattern tables.
.proc proc_PrintBCD
  addressLow = $00
  addressHigh = $01
  bytes = $02
  tileOffset = $03
  blankTile = $04

  ldy #0
stripLeadingZeros:
  lda (addressLow), y
  beq @next
  tax
  and #$F0
  bne printLoop
  lda $04
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
  lda $04
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
  lda (addressLow), y
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

; Helper macro for the BCD nametable printing routine.
; @param address The starting address for the BCD data to print.
; @param bytes The number of BCD bytes to print.
; @param tileOffset Pattern table tile offset for the "zero character" tile.
; @param blankTile The tile to use for zero padding.
.macro PrintBcd address, bytes, tileOffset, blankTile
  lda #.LOBYTE(address)
  sta $00
  lda #.HIBYTE(address)
  sta $01
  lda bytes
  sta $02
  lda tileOffset
  sta $03
  lda blankTile
  sta $04
  jsr proc_PrintBCD
.endmacro

.include "../ppu.s"

.segment "CODE"

arrowLabel: .byte "  ", $0C, "  ", 0

.proc printHex
  tya
  pha
  txa
  pha
  ldy $F2
@loop:
  dey
  lda ($F0), y
  tax
  lsr
  lsr
  lsr
  lsr
  clc
  adc #$10
  sta PPU_DATA
  txa
  and #$0F
  clc
  adc #$10
  sta PPU_DATA
  txa
  cpy #0
  bne @loop
  pla
  tax
  pla
  tay
  rts
.endproc

.proc printString
  tya
  pha
  ldy #0
@loop:
  lda ($F0), y
  beq @break
  sta PPU_DATA
  iny
  beq @break
  jmp @loop
@break:
  pla
  tay
  rts
.endproc

.proc resetPrintLine
  bit PPU_STATUS
  lda #$20
  sta $FF
  sta PPU_ADDR
  lda #$41
  sta $FE
  sta PPU_ADDR
  rts
.endproc

.proc nextPrintLine
  lda $FE
  clc
  adc #$20
  sta $FE
  lda $FF
  adc #0
  sta $FF
  bit PPU_STATUS
  sta PPU_ADDR
  lda $FE
  sta PPU_ADDR
  rts
.endproc

.macro LoadData input, output, numBytes
  ldx #0
: lda input, x
  sta output, x
  inx
  cpx #numBytes
  bne :-
.endmacro

.macro PrintString address
  lda #.LOBYTE(address)
  sta $F0
  lda #.HIBYTE(address)
  sta $F1
  jsr printString
.endmacro

.macro PrintLine address
  PrintString address
  jsr nextPrintLine
.endmacro

.macro PrintTitle title
  jsr resetPrintLine
  PrintString @title
  jsr nextPrintLine
  jsr nextPrintLine
.endmacro

.macro PrintTest label, value, expected
  pha

  lda #.LOBYTE(label)
  sta $F0
  lda #.HIBYTE(label)
  sta $F1
  jsr printString

  lda #.LOBYTE(value)
  sta $F0
  lda #.HIBYTE(value)
  sta $F1
  lda #4
  sta $F2
  jsr printHex

  lda #.LOBYTE(arrowLabel)
  sta $F0
  lda #.HIBYTE(arrowLabel)
  sta $F1
  jsr printString

  lda #.LOBYTE(expected)
  sta $F0
  lda #.HIBYTE(expected)
  sta $F1
  jsr printHex

  jsr nextPrintLine
  pla
.endmacro

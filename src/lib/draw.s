.segment "CODE"

.proc draw_image
  imagePtr    = $30
  vramPtr     = $32
  width       = $34
  height      = $35
  tileOffset  = $36
  ldx height
@outer:
  bit PPU_STATUS
  lda $33
  sta PPU_ADDR
  lda $32
  sta PPU_ADDR
  ldy #0
@inner:
  lda ($30), y
  clc
  adc tileOffset
  sta PPU_DATA
  iny
  cpy width
  bne @inner
  lda imagePtr
  clc
  adc width
  sta imagePtr
  lda imagePtr + 1
  adc #0
  sta imagePtr + 1
  lda vramPtr
  clc
  adc #$20
  sta vramPtr
  lda vramPtr + 1
  adc #0
  sta vramPtr + 1
  dex
  bne @outer
  rts
.endproc

.macro DrawImage imageTable, col, row, offset
.scope
  lda #.LOBYTE(imageTable + 2)
  sta draw_image::imagePtr
  lda #.HIBYTE(imageTable + 2)
  sta draw_image::imagePtr + 1
  vramStart = $2000 + (row * $20) + col
  lda #.LOBYTE(vramStart)
  sta draw_image::vramPtr
  lda #.HIBYTE(vramStart)
  sta draw_image::vramPtr + 1
  lda imageTable
  sta draw_image::width
  lda imageTable + 1
  sta draw_image::height
  lda #offset
  sta draw_image::tileOffset
  jsr draw_image
.endscope
.endmacro

.proc draw_text
  textPtr = $30
  vramPtr = $32
  bit PPU_STATUS
  lda vramPtr + 1
  sta PPU_ADDR
  lda vramPtr
  sta PPU_ADDR
  ldy #0
@loop:
  lda (textPtr), y
  beq @break
  cmp #$0A
  beq @new_line
  sta PPU_DATA
  jmp @next
@new_line:
  lda vramPtr
  clc
  adc #$20
  sta vramPtr
  tax
  lda vramPtr + 1
  adc #0
  sta vramPtr + 1
  bit PPU_STATUS
  sta PPU_ADDR
  txa
  sta PPU_ADDR
@next:
  iny
  bne @loop
@break:
  rts
.endproc

.macro DrawText col, row, textLabel, nametable
.scope
  vramStart = nametable + (row * $20) + col
  lda #.LOBYTE(vramStart)
  sta draw_text::vramPtr
  lda #.HIBYTE(vramStart)
  sta draw_text::vramPtr + 1

  lda #.LOBYTE(textLabel)
  sta draw_text::textPtr
  lda #.HIBYTE(textLabel)
  sta draw_text::textPtr + 1

  jsr draw_text
.endscope
.endmacro

.proc vram_rle_fill
  pointer = $30
  ldy #0
@loop:
  lda (pointer), y
  beq @break
  tax
  iny
  lda (pointer), y
@writeLoop:
  sta PPU_DATA
  dex
  bne @writeLoop
  iny
  bne @loop
@break:
  rts
.endproc

.macro FillAttributes attrLabel
  lda #.LOBYTE(attrLabel)
  sta vram_rle_fill::pointer
  lda #.HIBYTE(attrLabel)
  sta vram_rle_fill::pointer + 1
  Vram ATTR_A
  jsr vram_rle_fill
.endmacro

.proc clear_nametable_and_attr
  ldy #4
  lda #0
: ldx #0
: sta PPU_DATA
  inx
  bne :-
  dey
  bne :--
  rts
.endproc

.proc clear_screen
  Vram NAMETABLE_A
  jsr clear_nametable_and_attr
  Vram NAMETABLE_C
  jsr clear_nametable_and_attr
  rts
.endproc

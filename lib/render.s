.include "ppu.s"

.segment "CODE"

.proc loadPalettes
  bit PPU_STATUS
  lda #$3f
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #0
: lda @palettes, x
  sta PPU_DATA
  inx
  cpx #$20
  bne :-
  rts
@palettes:
  .byte $0F, $0F, $03, $32
  .byte $0F, $16, $06, $05
  .byte $0F, $10, $2D, $00
  .byte $0F, $11, $03, $20

  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
.endproc

.proc renderDigit
  vramAddr    = $60   ; 16-bit
  hasRendered = $62   ; 8-bit
  lda hasRendered
  bne renderNextDigit
  bit PPU_STATUS
  lda #$20
  sta vramAddr + 1
  sta PPU_ADDR
  lda #$00
  sta vramAddr
  sta PPU_ADDR
  lda #$33
  sta PPU_DATA
  lda #$2E
  sta PPU_DATA
  inc hasRendered
  inc renderPtr
  inc renderPtr
  inc vramAddr
  inc vramAddr
  rts
renderNextDigit:
  lda digitPtr
  sec
  sbc renderPtr
  sta $40
  lda digitPtr + 1
  sbc renderPtr + 1
  sta $41
  lda #0
  cmp $41
  beq :+
  rts
: cmp $40
  bne :+
  rts
: bit PPU_STATUS
  lda vramAddr + 1
  sta PPU_ADDR
  lda vramAddr
  sta PPU_ADDR
  ldy #0
  lda (renderPtr), y
  sta PPU_DATA
  inc renderPtr
  bne :+
  inc renderPtr + 1
: inc vramAddr
  bne :+
  inc vramAddr + 1
: rts
.endproc

.proc render_image
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

.macro RenderImage imageTable, col, row, offset
.scope
  lda #.LOBYTE(imageTable + 2)
  sta render_image::imagePtr
  lda #.HIBYTE(imageTable + 2)
  sta render_image::imagePtr + 1
  vramStart = $2000 + (row * $20) + col
  lda #.LOBYTE(vramStart)
  sta render_image::vramPtr
  lda #.HIBYTE(vramStart)
  sta render_image::vramPtr + 1
  lda imageTable
  sta render_image::width
  lda imageTable + 1
  sta render_image::height
  lda #offset
  sta render_image::tileOffset
  jsr render_image
.endscope
.endmacro

.proc fill_attributes
  rlePtr = $30
  Vram ATTR_A
  ldy #0
@loop:
  lda (rlePtr), y
  beq @break
  tax
  iny
  lda (rlePtr), y
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
  sta fill_attributes::rlePtr
  lda #.HIBYTE(attrLabel)
  sta fill_attributes::rlePtr + 1
  jsr fill_attributes
.endmacro

.proc render_text
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

.macro RenderText col, row, textLabel
.scope
  lda #.LOBYTE(textLabel)
  sta render_text::textPtr
  lda #.HIBYTE(textLabel)
  sta render_text::textPtr + 1
  vramStart = $2000 + (row * $20) + col
  lda #.LOBYTE(vramStart)
  sta render_text::vramPtr
  lda #.HIBYTE(vramStart)
  sta render_text::vramPtr + 1
  jsr render_text
.endscope
.endmacro

.proc renderPi
  RenderImage image_pi, 8, 7, $60
  FillAttributes attr_pi
  rts
.endproc

.proc renderNesHackerLogo
  RenderImage image_neshacker, 4, 12, $B0
  RenderText 12, 16, str_presents
  FillAttributes attr_neshacker
  rts
.endproc

.proc initializePPU
  ; jsr renderPi
  jsr renderNesHackerLogo

  ; Initalize Pi Palette Cycle
  ; lda #$21
  ; sta $60
  ; lda #1
  ; sta $61

  VramReset
  EnableRendering
  EnableNMI
  rts
.endproc

.proc title_palette_cycle
  sequenceLength = 12 * 12
  dec $61
  beq :+
  rts
: lda #6
  sta $61
  Vram (PALETTE + 3)
  ldx $60
  lda pi_colors, x
  sta PPU_DATA
  inx
  cpx #sequenceLength
  bne :+
  ldx #0
: stx $60
  rts
pi_colors:
  .byte $01, $11, $21, $21, $21, $21, $21, $21, $11, $01, $0F, $0F
  .byte $02, $12, $22, $22, $22, $22, $22, $22, $12, $02, $0F, $0F
  .byte $03, $13, $23, $23, $23, $23, $23, $23, $13, $03, $0F, $0F
  .byte $04, $14, $24, $24, $24, $24, $24, $24, $14, $04, $0F, $0F
  .byte $05, $15, $25, $25, $25, $25, $25, $25, $15, $05, $0F, $0F
  .byte $06, $16, $26, $26, $26, $26, $26, $26, $16, $06, $0F, $0F
  .byte $07, $17, $27, $27, $27, $27, $27, $27, $17, $07, $0F, $0F
  .byte $08, $18, $28, $28, $28, $28, $28, $28, $18, $08, $0F, $0F
  .byte $09, $19, $29, $29, $29, $29, $29, $29, $19, $09, $0F, $0F
  .byte $0A, $1A, $2A, $2A, $2A, $2A, $2A, $2A, $1A, $0A, $0F, $0F
  .byte $0B, $1B, $2B, $2B, $2B, $2B, $2B, $2B, $1B, $0B, $0F, $0F
  .byte $0C, $1C, $2C, $2C, $2C, $2C, $2C, $2C, $1C, $0C, $0F, $0F
.endproc

.proc render
  ; jsr renderDigit
  ; jsr title_palette_cycle
  VramReset
  rts
.endproc

image_pi:         .incbin "./bin/image/pi.bin"
attr_pi:          .byte 64, %00000000, 0

image_neshacker:  .incbin "./bin/image/neshacker.bin"
attr_neshacker:   .byte 24, 0, 3, %01010101, 5, %10101010, 8, %00000000, 0

str_presents:     .byte "PRESENTS", 0

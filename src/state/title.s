.segment "CODE"

.scope title
  .scope PiColor
    color = $60
    timer = $61
    DURATION = 6

    .proc init
      lda #0
      sta color
      lda #DURATION
      sta timer
      rts
    .endproc

    .proc cycle_color
      sequenceLength = 12 * 12
      dec timer
      beq :+
      rts
    : lda #DURATION
      sta timer
      Vram (PALETTE + 3)
      ldx color
      lda color_table, x
      sta PPU_DATA
      inx
      cpx #sequenceLength
      bne :+
      ldx #0
    : stx color
      rts
    color_table:
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
  .endscope

  .proc draw_pi
    DrawImage image_pi, 8, 7, $60
    FillAttributes attr_pi
    rts
  .endproc

  .proc init
    jsr clear_screen
    jsr draw_pi
    jsr PiColor::init
    VramReset
    rts
  .endproc

  .proc draw
    jsr PiColor::cycle_color
    rts
  .endproc

  .proc game_loop
    rts
  .endproc

  image_pi:         .incbin "./bin/image/pi.bin"
  attr_pi:          .byte 64, %00000000, 0
.endscope

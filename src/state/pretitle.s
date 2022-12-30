.segment "CODE"

.scope pretitle
  .scope PaletteFade
    .enum State
      fadeIn
      hold
      fadeOut
      transition
    .endenum

    animationState = $60
    paletteIndex = $61
    timer = $62

    .proc update_palettes
      Vram PALETTE
      lda paletteIndex
      asl
      asl
      tax
      lda presents_palettes, x
      sta PPU_DATA
      lda presents_palettes + 1, x
      sta PPU_DATA
      lda presents_palettes + 2, x
      sta PPU_DATA
      lda presents_palettes + 3, x
      sta PPU_DATA
      lda hacker_palettes, x
      sta PPU_DATA
      lda hacker_palettes + 1, x
      sta PPU_DATA
      lda hacker_palettes + 2, x
      sta PPU_DATA
      lda hacker_palettes + 3, x
      sta PPU_DATA
      lda nes_palettes, x
      sta PPU_DATA
      lda nes_palettes + 1, x
      sta PPU_DATA
      lda nes_palettes + 2, x
      sta PPU_DATA
      lda nes_palettes + 3, x
      sta PPU_DATA
      rts
    .endproc

    .proc set_animation_state
      sta animationState
      tax
      lda state_timers, x
      sta timer
      rts
    .endproc

    .proc set_title_state
      SetGameState #GameState::title
      rts
    .endproc

    .proc init
      lda #State::fadeIn
      jsr set_animation_state
      lda #0
      sta paletteIndex
      jsr update_palettes
      rts
    .endproc

    .proc update
      dec timer
      beq @animate
      rts
    @animate:
      lda animationState
      cmp #State::fadeIn
      beq @fadeIn
      cmp #State::hold
      beq @hold
      cmp #State::fadeOut
      beq @fadeOut
      cmp #State::transition
      beq @transition
    @fadeIn:
      inc paletteIndex
      lda paletteIndex
      cmp #3
      bne @reset_timer
      lda #State::hold
      jsr set_animation_state
      rts
    @hold:
      lda #State::fadeOut
      jsr set_animation_state
      rts
    @fadeOut:
      dec paletteIndex
      bne @reset_timer
      lda #State::transition
      jsr set_animation_state
      rts
    @transition:
      jsr set_title_state
      rts
    @reset_timer:
      ldx animationState
      lda state_timers, x
      sta timer
      rts
    .endproc

  state_timers:
    .byte 4, 120, 4, 22
  nes_palettes:
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $06, $0F, $0F
    .byte $0F, $06, $0F, $0F
    .byte $0F, $16, $06, $05
  hacker_palettes:
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $10, $0D, $0F
    .byte $0F, $10, $1D, $0F
    .byte $0F, $10, $2D, $00
  presents_palettes:
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $02
    .byte $0F, $0F, $0F, $12
    .byte $0F, $0F, $03, $32
  .endscope

  .proc drawNesHackerLogo
    DrawImage image_neshacker, 4, 12, $B0
    DrawText 12, 16, str_presents
    FillAttributes attr_neshacker
    rts
  .endproc

  .proc init
    jsr clear_screen
    jsr PaletteFade::init
    jsr drawNesHackerLogo
    rts
  .endproc

  .proc draw
    jsr PaletteFade::update_palettes
    rts
  .endproc

  .proc game_loop
    jsr PaletteFade::update
    rts
  .endproc

  image_neshacker:  .incbin "./src/bin/neshacker.bin"
  attr_neshacker:   .byte 24, 0, 3, %01010101, 5, %10101010, 8, %00000000, 0
  str_presents:     .byte "PRESENTS", 0
.endscope

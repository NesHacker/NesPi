.segment "CODE"

.scope title
  lightnessIndex  = $60
  timer           = $61
  hue             = $62
  textIndex       = $63
  textTimer       = $64
  enabled         = $65
  flag            = $66
  transitionTimer = $67
  colorIndex      = $68

  .scope Transition
    FRAME_DURATION = 4

    .proc init
      lda #FRAME_DURATION
      sta transitionTimer
      lda #0
      sta colorIndex
      rts
    .endproc

    .proc transition_game_state
      lda #0
      sta lightnessIndex
      sta timer
      sta hue
      sta textIndex
      sta textTimer
      sta enabled
      sta flag
      sta transitionTimer
      sta colorIndex
      SetGameState #GameState::digit_select
      rts
    .endproc

    .proc update
      lda flag
      bne @animate
      rts
    @animate:
      dec transitionTimer
      beq @next
      rts
    @next:
      lda #FRAME_DURATION
      sta transitionTimer
      Vram PALETTE + 2
      lda #$0F
      sta PPU_DATA
      ldx colorIndex
      lda text_colors, x
      sta PPU_DATA
      Vram PALETTE + 3*4 + 3
      lda pi_colors, x
      sta PPU_DATA
      dex
      bmi @transition
      stx colorIndex
      rts
    @transition:
      jsr transition_game_state
      rts
    .endproc

    text_colors: .byte $22, $12, $02, $0F
    pi_colors:   .byte $20, $10, $00, $0F
  .endscope

  .scope PiColor
    DURATION = 6

    .proc init
      lda #0
      sta lightnessIndex
      lda #DURATION
      sta timer
      lda #1
      sta hue
      rts
    .endproc

    .proc update
      lda flag
      bne @skip
      jsr cycle_color
    @skip:
      rts
    .endproc

    .proc cycle_color
      dec timer
      beq :+
      rts
    : lda #DURATION
      sta timer
      Vram (PALETTE + 12)

      ldx lightnessIndex
      ldy hue

      lda lightness_cycle, x
      beq @black
      cmp #3
      beq @bright
      cmp #2
      beq @medium
    @dark:
      lda #$0F
      sta PPU_DATA
      lda hue
      sta PPU_DATA
      lda #$0F
      sta PPU_DATA
      sta PPU_DATA
      jmp @next
    @medium:
      lda #$0F
      sta PPU_DATA
      lda hue
      clc
      adc #$10
      sta PPU_DATA
      lda hue
      sta PPU_DATA
      lda #$0F
      sta PPU_DATA
      jmp @next
    @bright:
      lda #$0F
      sta PPU_DATA
      lda hue
      clc
      adc #$20
      sta PPU_DATA
      lda hue
      clc
      adc #$10
      sta PPU_DATA
      lda hue
      sta PPU_DATA
      jmp @next
    @black:
      lda #$0F
      sta PPU_DATA
      sta PPU_DATA
      sta PPU_DATA
      sta PPU_DATA
    @next:
      inx
      cpx #12
      bne @done
      ldx #0
      iny
      cpy #$0D
      bne @done
      ldy #1
    @done:
      stx lightnessIndex
      sty hue
      rts
    lightness_cycle:
      .byte 0, 1, 2, 3, 3, 3, 3, 3, 3, 2, 1, 0
    .endproc
  .endscope

  .scope PressStart
    INITAL_DURATION = 80
    TYPE_DURATION = 6
    TEXT_ROW = 25
    TEXT_COL = 10
    TEXT_VRAM_START = $2000 + ($20 * TEXT_ROW) + TEXT_COL

    .proc init
      lda #0
      sta textIndex
      lda #1
      sta enabled
      lda #INITAL_DURATION
      sta textTimer
      rts
    .endproc

    .proc update
      lda flag
      bne @skip
      jsr update_text
    @skip:
      rts
    .endproc

    .proc update_text
      lda enabled
      bne @animate
      rts
    @animate:
      dec textTimer
      beq @next
      rts
    @next:
      lda #TYPE_DURATION
      sta textTimer
      bit PPU_STATUS
      lda #.LOBYTE(TEXT_VRAM_START)
      clc
      adc textIndex
      tax
      lda #.HIBYTE(TEXT_VRAM_START)
      adc #0
      sta PPU_ADDR
      stx PPU_ADDR
      ldx textIndex
      lda str_press_start, x
      beq @end_animation
      sta PPU_DATA
      inc textIndex
      rts
    @end_animation:
      lda #0
      sta enabled
      rts
    .endproc

    str_press_start:
      .byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, 0
    text_palette: .byte $0F, $0F, $03, $32
  .endscope

  .proc init
    lda #%10010000
    sta PPU_CTRL

    jsr clear_screen

    ldx #0
    Vram PALETTE
  : lda title_palette, x
    sta PPU_DATA
    inx
    cpx #$10
    bne :-

    DrawImage image_logo, 0, 0, $80
    FillAttributes attr_logo

    jsr PiColor::init
    jsr PressStart::init
    jsr Transition::init
    jsr set_scroll

    rts
  title_palette:
    .byte $0F, $0F, $11, $20
    .byte $0F, $16, $05, $06
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
  .endproc

  .proc set_scroll
    lda #0
    sta PPU_SCROLL
    lda #5
    sta PPU_SCROLL
    lda #%10010001
    sta PPU_CTRL
    rts
  .endproc

  .proc draw
    jsr PiColor::update
    jsr PressStart::update
    jsr Transition::update
    jsr set_scroll
    rts
  .endproc

  .proc game_loop
    lda flag
    beq @check_controller
    rts
  @check_controller:
    lda JOYPAD1_BITMASK
    and #BUTTON_START
    beq @skip
    lda #1
    sta flag
  @skip:
    rts
  .endproc

  image_logo:     .incbin "./src/bin/logo.bin"
  attr_logo:      .byte 16, %01010101, 32, %11111111, 16, %00000000, 0
.endscope

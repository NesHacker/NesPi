.segment "CODE"

.scope digit_select
  MIN_N         = 1
  MAX_N         = 960
  DEFAULT_N     = 31
  REPEAT_DELAY  = 20
  REPEAT_FRAMES = 2

  bcd           = $10 ; 16-bit
  digits        = $60 ; 16-bit
  repeat_timer  = $62

  .proc init
    jsr clear_screen
    jsr load_palettes

    FillAttributes screen_attr

    VramColRow 2, 2, $2000
    lda #.LOBYTE(top_menu)
    sta vram_rle_fill::pointer
    lda #.HIBYTE(top_menu)
    sta vram_rle_fill::pointer + 1
    jsr vram_rle_fill

    DrawText 3, 3, str_select_digits

    VramColRow 12, 12, $2000
    lda #.LOBYTE(digit_menu)
    sta vram_rle_fill::pointer
    lda #.HIBYTE(digit_menu)
    sta vram_rle_fill::pointer + 1
    jsr vram_rle_fill

    DrawText 1, 20, str_time_cost_note

    lda #.LOBYTE(DEFAULT_N)
    sta digits
    lda #.HIBYTE(DEFAULT_N)
    sta digits + 1

    BinaryToBcd16 digits

    rts
  .endproc

  .proc draw
    VramColRow 15, 13, $2000
    PrintBcd $0011, #2, #$10, #$01
    rts
  .endproc

  .proc clamp_digits
    lda digits + 1
    bmi @too_small
    lda #.LOBYTE(MAX_N)
    sec
    sbc digits
    lda #.HIBYTE(MAX_N)
    sbc digits + 1
    bcc @too_big
    lda digits
    bne @return
    lda digits + 1
    beq @too_small
  @return:
    rts
  @too_small:
    lda #1
    sta digits
    lda #0
    sta digits + 1
    rts
  @too_big:
    lda #.LOBYTE(MAX_N)
    sta digits
    lda #.HIBYTE(MAX_N)
    sta digits + 1
    rts
  .endproc

  .proc increment_digits
    increment = $21
    direction = $22
    made_change = $23

    lda direction
    bne @subtract
  @add:
    lda digits
    clc
    adc increment
    sta digits
    lda digits + 1
    adc #0
    sta digits + 1
    jsr clamp_digits
    jmp @done
  @subtract:
    lda digits
    sec
    sbc increment
    sta digits
    lda digits + 1
    sbc #0
    sta digits + 1
    jsr clamp_digits
  @done:
    BinaryToBcd16 digits
    lda #1
    sta made_change
    rts
  .endproc

  .proc handle_button
    button = $20
    increment = $21
    direction = $22
    made_change = $23
    lda JOYPAD1_BITMASK
    and button
    tay
    lda JOYPAD1_BITMASK_LAST
    and button
    bne @check_stop
  @check_start:
    tya
    beq @done
    lda #REPEAT_DELAY
    sta repeat_timer
    jsr increment_digits
    jmp @done
  @check_stop:
    tya
    bne @continue
  @continue:
    dec repeat_timer
    bne @done
    jsr increment_digits
    lda #REPEAT_FRAMES
    sta repeat_timer
  @done:
    rts
  .endproc

  .proc transition
    DisableRendering
    DisableNMI

    lda #GameState::calculate
    sta Game::state

    lda digits
    sta pi_spigot::n
    lda digits + 1
    sta pi_spigot::n + 1

    jsr pi_spigot::init

    VramReset
    EnableNMI
    EnableRendering
    rts
  .endproc

  .proc game_loop
    lda JOYPAD1_BITMASK
    and #BUTTON_START
    beq @dpad
    jsr transition
    rts
  @dpad:
    lda #BUTTON_UP
    sta handle_button::button
    lda #1
    sta handle_button::increment
    lda #0
    sta handle_button::direction
    jsr handle_button
    lda handle_button::made_change
    bne @done
    lda #BUTTON_RIGHT
    sta handle_button::button
    lda #10
    sta handle_button::increment
    lda #0
    sta handle_button::direction
    jsr handle_button
    lda handle_button::made_change
    bne @done
    lda #BUTTON_DOWN
    sta handle_button::button
    lda #1
    sta handle_button::increment
    lda #1
    sta handle_button::direction
    jsr handle_button
    lda handle_button::made_change
    bne @done
    lda #BUTTON_LEFT
    sta handle_button::button
    lda #10
    sta handle_button::increment
    lda #1
    sta handle_button::direction
    jsr handle_button
    lda handle_button::made_change
    bne @done
  @done:
    lda #0
    sta handle_button::made_change
    rts
  .endproc

  str_select_digits:
    .byte "SELECT NUMBER OF ", $0F, " DIGITS", $0A
    .byte "TO CALCULATE", $0E, " THEN PRESS", $0A
    .byte "THE START BUTTON."
    .byte 0

  str_time_cost_note:
    .byte "NOTE: ", $0F, "-SPIGOT IS A QUADRATIC", $0A
    .byte "ALGORITHM. IT WILL SLOW DOWN", $0A
    .byte "SIGNIFICANTLY FOR VERY LARGE", $0A
    .byte "NUMBERS", $0E, $0A, $0A
    .byte "CERTAIN DIGIT COUNTS (E.G. 5)", $0A
    .byte "WILL NOT PRODUCE ALL DIGITS ", $0A
    .byte "DUE TO AN OPTIMIZATION THAT", $0A
    .byte "HANDLES PREDIGIT CORRECTION.", $0A
    .byte 0

  top_menu:
    .byte 1, $04, 26, $08,  1, $05, 2, $00
    .byte 2, $00,  1, $0A, 26, $01, 1, $0B, 2, $00
    .byte 2, $00,  1, $0A, 26, $01, 1, $0B, 2, $00
    .byte 2, $00,  1, $0A, 26, $01, 1, $0B, 2, $00
    .byte 2, $00,  1, $06, 26, $09,  1, $07
    .byte 0

  digit_menu:
    .byte 1, $04, 6, $08, 1, $05, 12, $00
    .byte 12, $00, 1, $0A, 1, $0D, 5, $01, 1, $0B, 12, $00
    .byte 12, $00, 1, $06, 6, $09, 1, $07
    .byte 0

  screen_attr:
    .byt 32, %11111111, 32, %00000000, 0
.endscope
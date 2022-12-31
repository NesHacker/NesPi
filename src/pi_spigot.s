.segment "CODE"

.scope pi_spigot
  MAX_DIGITS = 960

  vramAddr    = $60   ; 16-bit
  hasRendered = $62   ; 8-bit
  drawEnabled = $63   ; 8-bit

  checksum    = $80   ; 8-bit
  nines       = $81   ; 8-bit
  predigit    = $82   ; 8-bit
  q           = $83   ; 8-bit
  calcOn      = $84   ; 8-bit

  i           = $90   ; 16-bit
  j           = $92   ; 16-bit
  n           = $94   ; 16-bit
  len         = $96   ; 16-bit
  len_bytes   = $98   ; 16-bit
  digitsFound = $9A   ; 16-bit

  arrayPtr    = $A0   ; 16-bit
  digitPtr    = $A2   ; 16-bit
  renderPtr   = $A4   ; 16-bit

  digits      = $300  ; Array[8-bit]
  array       = $6000 ; Array[16-bit]

  .scope LeadDigitAnimation
    FRAME_DURATION = 3
    NUM_FRAMES = 4

    frame = $6A
    timer = $6B

    .proc init
      lda #0
      sta frame
      lda #FRAME_DURATION
      sta timer
      rts
    .endproc

    .proc draw
      lda #.LOBYTE(MAX_DIGITS)
      sec
      sbc digitsFound
      lda #.HIBYTE(MAX_DIGITS)
      sbc digitsFound + 1
      bcs @check_active
      rts
    @check_active:
      bit PPU_STATUS
      lda vramAddr + 1
      sta PPU_ADDR
      lda vramAddr
      sta PPU_ADDR
      lda calcOn
      bne @animate
      lda #0
      sta PPU_DATA
      rts
    @animate:
      dec timer
      bne @draw
      lda #FRAME_DURATION
      sta timer
      inc frame
      lda #NUM_FRAMES
      cmp frame
      bne @draw
      lda #0
      sta frame
    @draw:
      ldx frame
      lda frames, x
      sta PPU_DATA
      rts
    .endproc

    frames:
      .byte $AC, $AD, $AE, $AF
  .endscope

  .scope StartMenu
    OPEN_Y = 175
    CLOSED_Y = 239

    .enum State
      closed = 0
      opening = 1
      open = 2
      closing = 3
    .endenum

    state = $6C
    scrollY = $6D
    timer = $6E

    .proc init
      lda #State::closed
      sta state
      lda #CLOSED_Y
      sta scrollY
      Vram NAMETABLE_C + 32 * 15
      lda #.LOBYTE(menu_border)
      sta vram_rle_fill::pointer
      lda #.HIBYTE(menu_border)
      sta vram_rle_fill::pointer + 1
      jsr vram_rle_fill
      rts
    .endproc

    .proc draw
      lda state
      cmp #State::opening
      beq @opening
      cmp #State::closing
      beq @closing
    @check_start_press:
      lda JOYPAD1_BITMASK_LAST
      and #BUTTON_START
      bne @return
      lda JOYPAD1_BITMASK
      and #BUTTON_START
      beq @return
      lda state
      beq @closed
    @open:
      lda #State::closing
      sta state
      rts
    @closed:
      lda #State::opening
      sta state
      rts
    @opening:
      ldx scrollY
      dex
      dex
      dex
      dex
      cpx #OPEN_Y
      bne @save_scroll
      lda #State::open
      sta state
      jmp @save_scroll
    @closing:
      ldx scrollY
      inx
      inx
      inx
      inx
      cpx #CLOSED_Y
      bne @save_scroll
      lda #State::closed
      sta state
    @save_scroll:
      stx scrollY
    @return:
      rts
    .endproc

    menu_border:
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $0A, 30, $01, 1, $0B
      .byte 1, $06, 30, $09, 1, $07
      .byte 0
  .endscope

  .proc init
    jsr clear_data
    jsr init_data
    jsr init_vram
    jsr LeadDigitAnimation::init
    jsr StartMenu::init
    rts
  .endproc

  .proc init_vram
    Vram $2000
    ldy #4
    lda #0
  : ldx #0
  : sta PPU_DATA
    inx
    bne :-
    dey
    bne :--
    Vram ATTR_C
    ldx #64
    lda #%01010101
  : sta PPU_DATA
    dex
    bne :-
    Vram PALETTE
    ldx #0
  : lda @palette, x
    sta PPU_DATA
    inx
    cpx #8
    bne :-
    rts
  @palette:
    .byte $0F, $0F, $03, $3A
    .byte $0F, $11, $03, $20
  .endproc

  .proc clear_data
    ; Save the given value of n
    lda n
    pha
    lda n+1
    pha
    ; Clear (zero out) all related algorithm memory
    lda #0
    ldx #0
  @loop:
    sta $60, x
    sta $70, x
    sta $80, x
    sta $90, x
    sta $A0, x
    inx
    cpx #$10
    bne @loop
    ; Reset the value of n
    pla
    sta n + 1
    pla
    sta n
    rts
  .endproc

  .proc init_data
    ; Increment n by one to account for the "tens place" digit
    inc n
    bne :+
    inc n+1
  :

    ; Calculate length and length in bytes for the table
    lda #10
    sta $00
    lda #0
    sta $01
    lda n
    sta $02
    lda n + 1
    sta $03
    jsr mul16
    lda $10
    sta $00
    lda $11
    sta $01
    lda #3
    sta $02
    lda #0
    sta $03
    jsr div16
    lda $00
    sta len
    sta len_bytes
    lda $01
    sta len + 1
    sta len_bytes + 1
    asl len_bytes
    rol len_bytes + 1

    ; Initialize the digit and render pointers
    lda #.LOBYTE(digits)
    sta digitPtr
    sta renderPtr
    lda #.HIBYTE(digits)
    sta digitPtr + 1
    sta renderPtr + 1

    ; for (let x = len; x > 0; x--) A[i] = 2;
    .scope
      lda #.LOBYTE(array)
      sta $00
      lda #.HIBYTE(array)
      sta $01

      lda len
      clc
      adc #2
      sta $02
      lda len+1
      adc #0
      sta $03

    loop:
      lda #2
      ldy #0
      sta ($00), y
      lda #0
      ldy #1
      sta ($00), y
      lda $00
      clc
      adc #2
      sta $00
      lda $01
      adc #0
      sta $01
      dec $02
      lda #$FF
      cmp $02
      bne :+
      dec $03
    : lda $02
      bne loop
      lda $03
      bne loop
    .endscope

    ; Enable caclulation
    lda #1
    sta calcOn
    rts
  .endproc

  .proc draw_digit
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
    sta $30
    lda digitPtr + 1
    sbc renderPtr + 1
    sta $31
    lda #0
    cmp $31
    beq :+
    rts
  : cmp $30
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

  .proc draw
    ReadJoypad1

    jsr draw_digit
    jsr LeadDigitAnimation::draw
    jsr StartMenu::draw

    lda #0
    sta PPU_SCROLL
    lda StartMenu::scrollY
    sta PPU_SCROLL
    lda #%10000010
    sta PPU_CTRL

    rts
  .endproc

  .proc write_digit
    inc digitsFound
    bne :+
    inc digitsFound + 1
  : tay
    lda #.LOBYTE(MAX_DIGITS)
    sec
    sbc digitsFound
    lda #.HIBYTE(MAX_DIGITS)
    sbc digitsFound + 1
    bcs @perform_write
    dec digitsFound
    rts
  @perform_write:
    tya
    clc
    adc checksum
    sta checksum
    tya
    clc
    adc #$30
    ldy #0
    sta (digitPtr), y
    inc digitPtr
    bne :+
    inc digitPtr+1
  : rts
  .endproc

  .proc calculate
    ; for (let j = n; j >= 1; j--) {
    .scope
      lda n
      sta j
      lda n + 1
      sta j + 1

    loop:
      ; let q = 0
      lda #0
      sta q

      ; for (let i = len; i >= 1; i--) {
      .scope
        ; Save a pointer to the current array position
        lda len_bytes
        sec
        sbc #2
        sta $00
        lda len_bytes + 1
        sbc #0
        sta $01
        lda #.LOBYTE(array)
        clc
        adc $00
        sta arrayPtr
        lda #.HIBYTE(array)
        adc $01
        sta arrayPtr + 1

        ; i = len
        lda len
        sta i
        lda len + 1
        sta i + 1

      loop:
        ; z = 10 * A[i] + q * i

        ; 10 * A[i] -> $14
        lda #10
        sta $00
        lda #0
        sta $01
        ldy #0
        lda (arrayPtr), y
        sta $02
        ldy #1
        lda (arrayPtr), y
        sta $03
        jsr mul16

        lda $10
        sta $14
        lda $10 + 1
        sta $14 + 1
        lda $10 + 2
        sta $14 + 2
        lda $10 + 3
        sta $14 + 3

        ; q * i -> $10
        lda q
        sta $00
        lda #0
        sta $01
        lda i
        sta $02
        lda i+1
        sta $03
        jsr mul16

        ; z = $14 + $10 = 10*A[i] + q*i -> [$00-$02]
        ; Note: we only need the first 3 bytes since z will always be < 0x1FFFF
        lda $10
        clc
        adc $14
        sta $00
        lda $10 + 1
        adc $14 + 1
        sta $00 + 1
        lda $10 + 2
        adc $14 + 2
        sta $00 + 2

        ; A[i] = z % (2*i - 1)
        ; q = (z / (2*i - 1)) | 0

        ; (2*i - 1) = ((i << 1) - 1) -> [$03-$05]
        lda i
        sta $03
        lda i+1
        sta $04
        lda #0
        sta $05

        asl $03
        rol $04
        rol $05

        lda $03
        sec
        sbc #1
        sta $03
        lda $04
        sbc #0
        sta $04
        lda $05
        sbc #0
        sta $05

        ; z / (2*i - 1)
        ; Note: Since z is never larger than $1FFFF we technically could do a
        ;       17-bit division here to save a lot of time. Play with it after
        ;       the program is complete.
        jsr div24

        ; A[i] = z % (2*i - 1)
        lda $09
        ldy #0
        sta (arrayPtr), y
        lda $09 + 1
        ldy #1
        sta (arrayPtr), y

        ; q = z / (2*i - 1)
        lda $00
        sta q

        lda calcOn
        bne @skip_return
        rts
      @skip_return:

        ; if (--i == 0) break
        lda i
        sec
        sbc #1
        sta i
        lda i + 1
        sbc #0
        sta i + 1
        lda i
        bne next
        lda i + 1
        bne next
        jmp break

        ; arrayPtr -= 2
      next:
        lda arrayPtr
        sec
        sbc #2
        sta arrayPtr
        lda arrayPtr + 1
        sbc #0
        sta arrayPtr + 1
        jmp loop
      break:
      .endscope
      ; }

      ; A[1] = q % 10
      ; q = (q / 10) | 0
      lda q
      sta $00
      lda #10
      sta $01
      jsr div8
      lda $00
      sta q
      lda $03
      sta array
      lda #0
      sta array+1

      .scope
        lda q
        cmp #9
        beq qIsNine

        cmp #10
        beq qIsTen
        jmp otherwise

      ; if (q == 9)
      qIsNine:
        ; nines++
        inc nines
        jmp next

      ; else if (q == 10)
      qIsTen:
        ;  digits.push(predigit + 1)
        inc predigit
        lda predigit
        jsr write_digit

        ; for (let k = 1; k <= nines; k++) digits.push(0)
        .scope
          ldx nines
          beq skipZerosLoop
        zerosLoop:
          lda #0
          jsr write_digit
          dex
          bne zerosLoop
        skipZerosLoop:
        .endscope

        ;  predigit = nines = 0
        lda #0
        sta predigit
        sta nines
        jmp next

      ; else
      otherwise:
        ; digits.push(predigit)
        lda predigit
        jsr write_digit

        ; predigit = q
        lda q
        sta predigit

        ; if (nines != 0)
        ldx nines
        beq next

        ; for (let k = 1; k <= nines; k++) digits.push(9)
        .scope
        ninesLoop:
          lda #9
          jsr write_digit
          dex
          bne ninesLoop
        .endscope

        ; nines = 0
        stx nines
      next:
      .endscope

      lda calcOn
      beq break

      ; j--
      lda j
      sec
      sbc #1
      sta j
      lda j + 1
      sbc #0
      sta j + 1

      ; if (j == 0) break;
      lda j
      bne nextIteration
      lda j+1
      bne nextIteration
      jmp break
    nextIteration:
      jmp loop
    break:
    .endscope
    ; }

    lda #0
    sta calcOn
    rts
  .endproc
.endscope


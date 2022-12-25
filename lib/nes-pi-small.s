.include "common.s"
.include "ppu.s"
.include "math32.s"

.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte $01, $00            ; mapper 0, vertical mirroring

.segment "VECTORS"
  .addr nmi
  .addr main
  .addr 0

.segment "STARTUP"

.segment "CHARS"
.incbin "./bin/CHR-ROM.bin"

.segment "CODE"

ten32Bit: .byte 10, 0, 0, 0

.proc piSpigot
  N = 21
  LEN = 10 * N / 3
  LEN_BYTES = 2 * LEN
  ARRAY = $0400

  ARRAY_PTR = $E0

  nines     = $0200
  predigit  = $0204
  j         = $0208
  i         = $020C
  k         = $0210
  q         = $0214
  z         = $0218

  ; for (let x = len; x > 0; x--) {
  .scope
    lda #.LOBYTE(ARRAY)
    sta ARRAY_PTR
    lda #.HIBYTE(ARRAY)
    sta ARRAY_PTR + 1
    lda #.LOBYTE(LEN)
    sta $20
    lda #.HIBYTE(LEN)
    sta $21
    ldy #0
  loop:
    ; A[i] = 2
    lda #2
    sta (ARRAY_PTR), y
    lda #0
    sta (ARRAY_PTR + 1), y
    ; x--
    lda $20
    sec
    sbc #1
    sta $20
    lda $21
    sbc #0
    sta $21
    ; x > 0
    lda $20
    bne next
    lda $21
    beq break
  next:
    lda ARRAY_PTR
    clc
    adc #2
    sta ARRAY_PTR
    lda ARRAY_PTR + 1
    adc #0
    sta ARRAY_PTR + 1
    jmp loop
  break:
  ; }
  .endscope

  ; let nines = 0, predigit = 0, i = j = k = 0;
  ; This is redundant since memory was zeroed out during reset

  ; for (let j = 1; j <= n; j++) {
  .scope
    lda #.LOBYTE(N)
    sta j
    lda #.HIBYTE(N)
    sta j+1
  loop:

    ; let q = z = 0
    lda #0
    sta q
    sta z
    sta z + 1
    sta z + 2
    sta z + 3

    ; for (let i = len; i >= 1; i--) {
    .scope
      ; Save a pointer to the current array position
      lda #.LOBYTE(ARRAY)
      clc
      adc #.LOBYTE(LEN_BYTES - 2)
      sta ARRAY_PTR
      lda #.HIBYTE(ARRAY)
      adc #.HIBYTE(LEN_BYTES - 2)
      sta ARRAY_PTR + 1

      ; i = len
      lda #.LOBYTE(LEN)
      sta i
      lda #.HIBYTE(LEN)
      sta i + 1

    loop:
      ; z = 10 * A[i] + q * i

      ; 10 * A[i] -> $20
      lda #10
      sta $00
      lda #0
      sta $01
      ldy #0
      lda (ARRAY_PTR), y
      sta $02
      lda (ARRAY_PTR + 1), y
      sta $03
      jsr mul16
      ldx #3
    : lda $10, x
      sta $20, x
      dex
      bpl :-

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

      ; z = $20 + $10 = 10*A[i] + q*i
      lda $10
      clc
      adc $20
      sta z
      lda $11
      adc $21
      sta z + 1
      lda $12
      adc $22
      sta z + 2
      lda $13
      adc $23
      sta z + 3

      ; A[i] = z % (2*i - 1)
      ; q = (z / (2*i - 1)) | 0

      ; (2*i - 1) = ((i << 1) - 1) -> $04
      lda i
      sta $04
      lda i+1
      sta $05
      lda #0
      sta $06
      sta $07
      asl $04
      rol $05
      lda $04
      sec
      sbc #1
      sta $04
      lda $05
      sbc #0
      sta $06

      ; z -> $00
      lda z
      sta $00
      lda z + 1
      sta $01
      lda z + 2
      sta $02
      lda #0
      sta $03

      ; z / (2*i - 1)
      jsr div32     ; z will never exceed 3 bytes, div24 is faster

      ; A[i] = z % (2*i - 1)
      ldy #0
      lda $0C + 1
      sta (ARRAY_PTR + 1), y
      lda $0C
      sta (ARRAY_PTR), y

      ; q = (z / (2*i - 1)) | 0
      lda $00
      sta q

      ; if (--i == 0) break
      dec i
      bpl :+
      dec i + 1
    : lda i
      bne :+
      lda i + 1
      bne :+
      jmp break

      ; ARRAY_PTR -= 2
    : lda ARRAY_PTR
      sec
      sbc #2
      sta ARRAY_PTR
      lda ARRAY_PTR + 1
      sbc #0
      sta ARRAY_PTR + 1
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
    sta ARRAY
    lda #0
    sta ARRAY+1

    .scope
    isQNine:
      ; if (q == 9) {
      .scope
        lda #9
        cmp q
        bne isQTen
        ; nines++
        inc nines
        jmp next
      ; }
      .endscope

    isQTen:
      ; else if (q == 10) {
      .scope
        lda #10
        cmp q
        bne otherwise

        ;  digits.push(predigit + 1)
        inc predigit
        lda predigit
        clc
        adc #$10
        sta PPU_DATA

        ;  for (let k = 1; k <= nines; k++) digits.push(0)
        ldx nines
        lda #$10
      : sta PPU_DATA
        dex
        bpl :-

        ;  predigit = nines = 0
        lda #0
        sta predigit
        sta nines

        jmp next
      ; }
      .endscope

    otherwise:
      ; else {
      .scope
        ; digits.push(predigit)
        lda predigit
        clc
        adc #$10
        sta PPU_DATA

        ; predigit = q
        lda q
        sta predigit

        ; if (nines != 0) {
        .scope
          lda nines
          beq skip

          ; for (let k = 1; k <= nines; k++) digits.push(9)
          lda #$19
          ldx nines
        : sta PPU_DATA
          dex
          bne :-

          ; nines = 0
          lda #0
          sta nines
        ; }
        skip:
        .endscope
      .endscope
      ; }
    next:
    .endscope

    dec j
    bpl :+
    dec j+1
  : lda j
    bne nextIteration
    lda j+1
    bne nextIteration
    jmp break
  nextIteration:
    jmp loop
  break:
  .endscope
  ; }

  rts
.endproc

.proc main
  NesReset

  VramColRow 0, 1, NAMETABLE_A
  jsr piSpigot

  jsr printNesHackerLogo
  jsr loadPalettes
  VramReset
  EnableRendering
: jmp :-
.endproc

.proc nmi
  VramReset
  rti
.endproc


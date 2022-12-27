.include "common.s"
.include "ppu.s"
.include "math32.s"

.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte $01, $01            ; mapper 1 (MMC1), vertical mirroring

.segment "VECTORS"
  .addr nmi
  .addr main
  .addr 0

.segment "STARTUP"

.segment "CHARS"
.incbin "./bin/CHR-ROM.bin"

.segment "CODE"


ARRAY       = $6000
digits      = $300

nines       = $80 ; 8-bit
predigit    = $81 ; 8-bit
q           = $82 ; 8-bit

i           = $90 ; 16-bit
j           = $92 ; 16-bit
z           = $94 ; 32-bit

arrayPtr    = $A0 ; 16-bit
digitPtr    = $A2 ; 16-bit
renderPtr   = $A4 ; 16-bit

.proc piSpigot
  N = 120
  LEN = 10 * N / 3
  LEN_BYTES = 2 * LEN

  lda #.LOBYTE(digits)
  sta digitPtr
  sta renderPtr
  lda #.HIBYTE(digits)
  sta digitPtr + 1
  sta renderPtr + 1

  .macro WriteDigit addr
    lda addr
    clc
    adc #$30
    ldy #0
    sta (digitPtr), y
    inc digitPtr
    bne :+
    inc digitPtr+1
  :
  .endmacro

  ; for (let x = len; x > 0; x--) A[i] = 2;
  .scope
    ldx #0
    lda #2
  arrayInitLoop:
    sta ARRAY, x
    sta ARRAY + $100, x
    sta ARRAY + $200, x
    sta ARRAY + $300, x
    sta ARRAY + $400, x
    sta ARRAY + $500, x
    sta ARRAY + $600, x
    sta ARRAY + $700, x
    sta ARRAY + $800, x
    sta ARRAY + $900, x
    sta ARRAY + $1000, x
    sta ARRAY + $1100, x
    sta ARRAY + $1200, x
    sta ARRAY + $1300, x
    sta ARRAY + $1400, x
    sta ARRAY + $1500, x
    sta ARRAY + $1600, x
    sta ARRAY + $1700, x
    sta ARRAY + $1800, x
    sta ARRAY + $1900, x
    inx
    inx
    bne arrayInitLoop
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
      sta arrayPtr
      lda #.HIBYTE(ARRAY)
      adc #.HIBYTE(LEN_BYTES - 2)
      sta arrayPtr + 1

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
      lda (arrayPtr), y
      sta $02
      iny
      lda (arrayPtr), y
      sta $03
      jsr mul16
      lda $10
      sta $20
      lda $11
      sta $21
      lda $12
      sta $22
      lda $13
      sta $23

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
      rol $06
      rol $07
      lda $04
      sec
      sbc #1
      sta $04
      lda $05
      sbc #0
      sta $05
      lda $06
      sbc #0
      sta $06
      lda $07
      sbc #0
      sta $07

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
      jsr div32     ; note: z will never exceed 3 bytes, div24 is faster

      ; A[i] = z % (2*i - 1)
      ldy #0
      lda $0C
      sta (arrayPtr), y
      iny
      lda $0C + 1
      sta (arrayPtr), y

      ; q = (z / (2*i - 1)) | 0
      lda $00
      sta q

      ; if (--i == 0) break
      lda i
      sec
      sbc #1
      sta i
      lda i + 1
      sbc #0
      sta i + 1
      lda i
      bne :+
      lda i + 1
      bne :+
      jmp break

      ; arrayPtr -= 2
    : lda arrayPtr
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
    sta ARRAY
    lda #0
    sta ARRAY+1

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
      WriteDigit predigit

      ; for (let k = 1; k <= nines; k++) digits.push(0)
      .scope
        ldx nines
        beq skipZerosLoop
      zerosLoop:
        WriteDigit #0
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
      WriteDigit predigit

      ; predigit = q
      lda q
      sta predigit

      ; if (nines != 0)
      ldx nines
      beq next

      ; for (let k = 1; k <= nines; k++) digits.push(9)
      .scope
      ninesLoop:
        WriteDigit #9
        dex
        bne ninesLoop
      .endscope

      ; nines = 0
      stx nines
    next:
    .endscope

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

  rts
.endproc

.proc main
  NesReset
  VramReset
  jsr printNesHackerLogo
  jsr loadPalettes
  VramReset
  EnableRendering
  ; EnableNMI

  jsr piSpigot

: jmp :-
.endproc

.proc nmi
exit:
  VramReset
  rti
.endproc

; math32.s - 32-bit Integer Mathematics Library
; Adapted from: https://llx.com/Neil/a2/mult.html

.segment "CODE"

; Increments the given 32-bit value in place.
; @param [$00-$03] 32-bit value to increment.
.proc inc32
  inc $00
  bne @done
  inc $01
  bne @done
  inc $02
  bne @done
  inc $03
@done:
  rts
.endproc

; Decrements the given 32-bit value in place.
; @param [$00-$03] 32-bit value to decrement.
.proc dec32
  pha
  lda #$FF
  dec $00
  cmp $00
  bne @done
  dec $01
  cmp $01
  bne @done
  dec $02
  cmp $02
  bne @done
  dec $03
@done:
  pla
  rts
.endproc

; Adds two 32-bit values and stores the result in a 32-bit return value.
; @param [$00-$03] First 32-bit operand.
; @param [$04-$07] Second 32-bit operand.
; @return [$10-$03] 32-bit result.
.proc add32
  pha
  lda $00
  clc
  adc $04
  sta $10
  lda $01
  adc $05
  sta $11
  lda $02
  adc $06
  sta $12
  lda $03
  adc $07
  sta $13
  pla
  rts
.endproc

; Subtracts two 32-bit numbers.
; @param [$00-$03] First 32-bit operand.
; @param [$04-$07] Second 32-bit operand.
; @return [$10-$03] 32-bit result.
.proc sub32
  pha
  lda $00
  sec
  sbc $04
  sta $10
  lda $01
  sbc $05
  sta $11
  lda $02
  sbc $06
  sta $12
  lda $03
  sbc $07
  sta $13
  pla
  rts
.endproc

; Multiplies two 32-bit numbers and returns a 64-bit result.
; @param [$00-$03] The first 32-bit number.
; @param [$04-$07] The second 32-bit number.
; @return [$10-$17] The 64-bit result.
.proc mul32
  NUM1 = $00
  NUM2 = $04
  RESULT = $10
  pha
  txa
  pha
  lda #0
  sta RESULT+7
  sta RESULT+6
  sta RESULT+5
  sta RESULT+4
  ldx #32
@loop:
  lsr NUM2+3
  ror NUM2+2
  ror NUM2+1
  ror NUM2
  bcc :+
  tay
  clc
  lda NUM1
  adc RESULT+4
  sta RESULT+4
  lda NUM1+1
  adc RESULT+5
  sta RESULT+5
  lda NUM1+2
  adc RESULT+6
  sta RESULT+6
  tya
  adc NUM1+3
: ror A
  ror RESULT+6
  ror RESULT+5
  ror RESULT+4
  ror RESULT+3
  ror RESULT+2
  ror RESULT+1
  ror RESULT
  dex
  bne @loop
  sta RESULT+7
  pla
  tax
  pla
  rts
.endproc



.proc div32
  DIVIDEND = $00  ; The 4-byte Dividend for the division (numerator)
  DIVISOR = $04   ; The 4-byte Divisor for the division (denominator)
  SUB = $08       ; 4-bytes to store the result of the test subtraction.
  REM = $12       ; 4-bytes to store the running remainder.

  ; Push the current values of A and X to the stack
  pha
  txa
  pha

  ; Zero-out the Remainder memory
  lda #0
  sta REM
  sta REM+1
  sta REM+2
  sta REM+3

  ; for (int x = 32; x > 0; x--)
  ldx #32
@loop:
  ; Shift the next bit off the front of the dividend
  asl DIVIDEND
  rol DIVIDEND+1
  rol DIVIDEND+2
  rol DIVIDEND+3
  rol REM
  rol REM+1
  rol REM+2
  rol REM+3

  ; Perform the test subtraction
  lda REM
  sec
  sbc DIVISOR
  sta SUB
  lda REM+1
  sbc DIVISOR+1
  sta SUB+1
  lda REM+2
  sbc DIVISOR+2
  sta SUB+2
  lda REM+3
  sbc DIVISOR+3
  sta SUB+3
  bcc @skip_increment

  ; Record a "1" and store the resulting remainder
  sta REM+3
  lda SUB+2
  sta REM+2
  lda SUB+1
  sta REM+1
  lda SUB
  sta REM
  inc DIVIDEND

@skip_increment:
  dex
  bne @loop

  ; Restore the values of A and X from the stack
  pla
  tax
  pla

  rts
.endproc

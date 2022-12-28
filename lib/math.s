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

; Multiplies two 16 bit numbers and returns a 32-bit result.
; @param [$00-$01] First 16-bit operand.
; @param [$02-$03] Second 16-bit operand.
; @return [$10-$13] 32-bit result.
.proc mul16
  NUM1 = $00
  NUM2 = $02
  RESULT = $10
  lda #0
  sta RESULT+2
  ldx #16
@loop:
  lsr NUM2+1      ; Shift a bit
  ror NUM2
  bcc :+          ; 0 or 1 ?
  tay
  clc
  lda NUM1
  adc RESULT+2
  sta RESULT+2
  tya
  adc NUM1+1
: ror A
  ror RESULT+2
  ror RESULT+1
  ror RESULT
  dex
  bne @loop
  sta RESULT+3
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

.proc div8
  DIVIDEND  = $00
  DIVISOR   = $01
  SUB       = $02
  REM       = $03
  ; Zero-out the Remainder memory
  lda #0
  sta REM
  ; for (int x = 8; x > 0; x--)
  ldx #8
@loop:
  ; Shift the next bit off the front of the dividend
  asl DIVIDEND
  rol REM
  ; Perform the test subtraction
  lda REM
  sec
  sbc DIVISOR
  sta SUB
  bcc @skip_increment
  ; Record a "1" and store the resulting remainder
  sta REM
  inc DIVIDEND
@skip_increment:
  dex
  bne @loop
  rts
.endproc

.proc div16
  NUM1 = $00
  NUM2 = $02
  REM = $04
  lda #0
  sta REM
  sta REM+1
  ldx #16
@loop:
  asl NUM1    ;Shift hi bit of NUM1 into REM
  rol NUM1+1  ;(vacating the lo bit, which will be used for the quotient)
  rol REM
  rol REM+1
  lda REM
  sec         ;Trial subtraction
  sbc NUM2
  tay
  lda REM+1
  sbc NUM2+1
  bcc :+      ;Did subtraction succeed?
  sta REM+1   ;If yes, save it
  sty REM
  inc NUM1    ;and record a 1 in the quotient
: dex
  bne @loop
  rts
.endproc


.proc div24
  DIVIDEND = $00
  DIVISOR  = $03
  SUB      = $06
  REM      = $09
  ; Zero-out the Remainder memory
  lda #0
  sta REM
  sta REM+1
  sta REM+2
  ; for (int x = 24; x > 0; x--)
  ldx #24
@loop:
  ; Shift the next bit off the front of the dividend
  asl DIVIDEND
  rol DIVIDEND+1
  rol DIVIDEND+2
  rol REM
  rol REM+1
  rol REM+2

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

  bcc @skip_increment

  ; Record a "1" and store the resulting remainder
  ; lda SUB+2
  sta REM+2
  lda SUB+1
  sta REM+1
  lda SUB
  sta REM
  inc DIVIDEND

@skip_increment:
  dex
  bne @loop
  rts
.endproc

; Divides two 32-bit integers producing a result and a remainder.
; @param [$00-$03] The dividend (numerator) for the division.
; @param [$04-$07] The divisor (denominator) for the division.
; @return [$00-$03] Result of the division.
; @return [$0C-$0F] Remainder after division.
.proc div32
  DIVIDEND = $00  ; The 4-byte Dividend for the division (numerator)
  DIVISOR = $04   ; The 4-byte Divisor for the division (denominator)
  SUB = $08       ; 4-bytes to store the result of the test subtraction.
  REM = $0C       ; 4-bytes to store the running remainder.

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

  rts
.endproc

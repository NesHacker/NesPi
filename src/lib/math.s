.segment "CODE"

.proc mul16
  num1 = $00
  num2 = $02
  result = $10
  lda #0
  sta result+2
  ldx #16
@loop:
  lsr num2+1      ; Shift a bit
  ror num2
  bcc :+          ; 0 or 1 ?
  tay
  clc
  lda num1
  adc result+2
  sta result+2
  tya
  adc num1+1
: ror
  ror result+2
  ror result+1
  ror result
  dex
  bne @loop
  sta result+3
  rts
.endproc

.proc div8
  dividend  = $00
  divisor   = $01
  sub       = $02
  remainder = $03
  ; Zero-out the Remainder memory
  lda #0
  sta remainder
  ; for (int x = 8; x > 0; x--)
  ldx #8
@loop:
  ; Shift the next bit off the front of the dividend
  asl dividend
  rol remainder
  ; Perform the test subtraction
  lda remainder
  sec
  sbc divisor
  sta sub
  bcc @skip_increment
  ; Record a "1" and store the resulting remainder
  sta remainder
  inc dividend
@skip_increment:
  dex
  bne @loop
  rts
.endproc

.proc div16
  dividend  = $00
  divisor   = $02
  sub       = $04
  remainder = $06
  ; Zero-out the Remainder memory
  lda #0
  sta remainder
  sta remainder+1
  ; for (int x = 16; x > 0; x--)
  ldx #16
@loop:
  ; Shift the next bit off the front of the dividend
  asl dividend
  rol dividend+1
  rol remainder
  rol remainder+1

  ; Perform the test subtraction
  lda remainder
  sec
  sbc divisor
  sta sub

  lda remainder+1
  sbc divisor+1
  sta sub+1

  bcc @skip_increment

  ; Record a "1" and store the resulting remainder
  ; lda sub+2
  sta remainder+1
  lda sub
  sta remainder
  inc dividend

@skip_increment:
  dex
  bne @loop
  rts
.endproc

.proc div24
  dividend  = $00
  divisor   = $03
  sub       = $06
  remainder = $09
  ; Zero-out the Remainder memory
  lda #0
  sta remainder
  sta remainder+1
  sta remainder+2
  ; for (int x = 24; x > 0; x--)
  ldx #24
@loop:
  ; Shift the next bit off the front of the dividend
  asl dividend
  rol dividend+1
  rol dividend+2
  rol remainder
  rol remainder+1
  rol remainder+2

  ; Perform the test subtraction
  lda remainder
  sec
  sbc divisor
  sta sub

  lda remainder+1
  sbc divisor+1
  sta sub+1

  lda remainder+2
  sbc divisor+2
  sta sub+2

  bcc @skip_increment

  ; Record a "1" and store the resulting remainder
  ; lda sub+2
  sta remainder+2
  lda sub+1
  sta remainder+1
  lda sub
  sta remainder
  inc dividend

@skip_increment:
  dex
  bne @loop
  rts
.endproc
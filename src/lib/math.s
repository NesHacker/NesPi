.segment "CODE"

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
  DIVIDEND = $00
  DIVISOR  = $02
  SUB      = $04
  REM      = $06
  ; Zero-out the Remainder memory
  lda #0
  sta REM
  sta REM+1
  ; for (int x = 16; x > 0; x--)
  ldx #16
@loop:
  ; Shift the next bit off the front of the dividend
  asl DIVIDEND
  rol DIVIDEND+1
  rol REM
  rol REM+1

  ; Perform the test subtraction
  lda REM
  sec
  sbc DIVISOR
  sta SUB

  lda REM+1
  sbc DIVISOR+1
  sta SUB+1

  bcc @skip_increment

  ; Record a "1" and store the resulting remainder
  ; lda SUB+2
  sta REM+1
  lda SUB
  sta REM
  inc DIVIDEND

@skip_increment:
  dex
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
.macro VblankWait
: bit $2002
  bpl :-
.endmacro

.macro NesReset
  sei
  cld
  ldx #%01000000
  stx $4017
  ldx #$ff
  txs
  ldx #0
  stx $2000
  stx $2001
  stx $4010
  bit $2002
  VblankWait
  ldx #0
@loop:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne @loop
  VblankWait
  bit $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  lda #$0F
  ldx #$20
@paletteLoadLoop:
  sta $2007
  dex
  bne @paletteLoadLoop
.endmacro

.segment "CODE"

.proc loadPalettes
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #0
: lda @palettes, x
  sta $2007
  inx
  cpx #$20
  bne :-
  rts
@palettes:
  .byte $0F, $0F, $03, $32
  .byte $0F, $2D, $16, $0F
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
  .byte $0F, $03, $15, $32
.endproc

.proc printNesHackerLogo

  lineOneStart = ($2000 + 26*$20 + 15)
  bit $2002
  lda #.HIBYTE(lineOneStart)
  sta $2006
  lda #.LOBYTE(lineOneStart)
  sta $2006

  ldx #$60
: stx PPU_DATA
  inx
  cpx #$70
  bne :-

  lineTwoStart = ($2000 + 27*$20 + 15)
  bit $2002
  lda #.HIBYTE(lineTwoStart)
  sta $2006
  lda #.LOBYTE(lineTwoStart)
  sta $2006

: stx PPU_DATA
  inx
  cpx #$80
  bne :-

  bit $2002
  lda #$23
  sta $2006
  lda #$F0
  sta $2006

  lda #%01010101
  ldx #16
: sta PPU_DATA
  dex
  bne :-
  rts
.endproc

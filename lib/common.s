; Common NES Programming Routines

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

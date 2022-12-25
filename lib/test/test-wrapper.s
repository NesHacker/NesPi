.include "../common.s"
.include "../ppu.s"

.import test

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
.incbin "../bin/CHR-ROM.bin"

.segment "CODE"

.proc loadPalettes
  VramPalette
  ldx #0
: lda @palettes, x
  sta PPU_DATA
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
  VramColRow 15, 26, NAMETABLE_A
  ldx #$60
: stx PPU_DATA
  inx
  cpx #$70
  bne :-
  VramColRow 15, 27, NAMETABLE_A
: stx PPU_DATA
  inx
  cpx #$80
  bne :-
  Vram $23F0
  lda #%01010101
  ldx #16
: sta PPU_DATA
  dex
  bne :-
  rts
.endproc

.proc main
  NesReset
  jsr loadPalettes
  jsr printNesHackerLogo
  jsr test
  VramReset
  EnableRendering
: jmp :-
.endproc

.proc nmi
  VramReset
  rti
.endproc


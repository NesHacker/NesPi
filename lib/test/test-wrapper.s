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


.include "../math32.s"
.include "test-common.s"

.export test
.segment "CODE"

.proc testInc32
  LoadData @data, $00, 8
  jsr inc32
  jsr inc32
  jsr inc32
  jsr inc32
  PrintTest @label, $00, $04
  rts
@label:
  .byte "INC32: ", 0
@data:
  .byte $ff, $ff, $ff, $ff
  .byte $03, $00, $00, $00
.endproc

.proc testDec32
  LoadData @data, $00, 8
  jsr dec32
  jsr dec32
  jsr dec32
  jsr dec32
  PrintTest @label, $00, $04
  rts
@label:
  .byte "DEC32: ", 0
@data:
  .byte $00, $00, $00, $00
  .byte $FC, $FF, $FF, $FF
.endproc

.proc testAdd32
  ; 0x8805F23A + 0x5ABE201F = 0xE2C41259
  LoadData @data, $00, 12
  jsr add32
  PrintTest @label, $0010, $0008
  rts
@label:
  .byte "ADD32: ", 0
@data:
  .byte $3A, $F2, $05, $88
  .byte $1F, $20, $BE, $5A
  .byte $59, $12, $C4, $E2
.endproc

.proc testSub32
  ; 0xA8B9C0D1 - 0x21008CFF = 0x87B933D2
  LoadData @data, $00, 12
  jsr sub32
  PrintTest @label, $0010, $0008
  rts
@label:
  .byte "SUB32: ", 0
@data:
  .byte $D1, $C0, $B9, $A8
  .byte $FF, $8C, $00, $21
  .byte $D2, $33, $B9, $87
.endproc

.proc testMul32
  ; 0x189B67A3 * 0x7E921BC2 = 0x(C2A884E)5EA8BA86
  LoadData @data, $00, 12
  jsr mul32
  PrintTest @label, $0010, $0008
  rts
@label:
  .byte "MUL32: ", 0
@data:
  .byte $A3, $67, $9B, $18
  .byte $C2, $1B, $92, $7E
  .byte $86, $BA, $A8, $5E
.endproc

.proc testDiv32
  ; 0xFC96EB85 / 0x001A42DF = 0x0000099E
  LoadData @data, $00, 8
  LoadData @expected, $20, 4
  jsr div32
  PrintTest @label, $0000, $0020
  rts
@label:
  .byte "DIV32: ", 0
@data:
  .byte $85, $EB, $96, $FC
  .byte $DF, $42, $1A, $00
@expected:
  .byte $9E, $09, $00, $00
.endproc

.proc testMod32
  ; 0xDEADBEEF % 0xC0FFEE = 0x0046D3AD
  ; 3735928559 % 12648430 =    4641709
  LoadData @data, $00, 8
  LoadData @expected, $20, 4
  jsr div32
  PrintTest @label, $0C, $20
  rts
@label:
  .byte "MOD32: ", 0
@data:
  .byte $EF, $BE, $AD, $DE
  .byte $EE, $FF, $C0, $00
@expected:
  .byte $AD, $D3, $46, $00
.endproc

.proc test
  PrintTitle @title
  jsr testInc32
  jsr testDec32
  jsr testAdd32
  jsr testSub32
  jsr testMul32
  jsr testDiv32
  jsr testMod32
  rts
@title:
  .byte "### MATH32 LIBRARY TESTS ###", 0
.endproc

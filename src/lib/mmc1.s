.segment "CODE"

.proc mmc1_reset
  inc mmc1_reset
  rts
.endproc

.proc mmc1_write_control
  sta $8000
  lsr
  sta $8000
  lsr
  sta $8000
  lsr
  sta $8000
  lsr
  sta $8000
  rts
.endproc

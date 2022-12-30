; nes-pi.s - An NES game that computes the digits of pi.
; By NesHacker

;-------------------------------------------------------------------------------
;                                 Memory Map
;-------------------------------------------------------------------------------
; $00-$1F:      Pi-Spigot Compute / Scratch
;               Memory in this range is used by the Pi-Spigot routine as a
;               scratch pad when computing digits. As such, it should be left
;               alone when the routine is running.
;-------------------------------------------------------------------------------
; $20-$2F       General CPU Scratch
;               Scratch pad for general CPU tasks, e.g. game states, controller
;               input, etc.
;-------------------------------------------------------------------------------
; $30-$3F       NMI/Rendering Scratch
;               Scratch pad for PPU and rendering related tasks. Keeping this
;               Separate ensures that CPU memory isn't corrupted mid-computer
;               when the NMI fires.
;-------------------------------------------------------------------------------
; $40-$5F       Game State
;               Long term variables used for handling the overall game logic.
;-------------------------------------------------------------------------------
; $60-$7F       Rendering
;               Long term variables used for handling rendering routines.
;-------------------------------------------------------------------------------
; $80-$AF       Pi-Spigot State
;               Pi-spigot algorithm variables. For ease of debugging I chose to
;               group like sized variables together. $80-$8F holds all 8-bit
;               values, $90-$9F all 16-bit values, and $A0-$AF all pointers.
;-------------------------------------------------------------------------------
; $B0-$FF       Unassigned
;-------------------------------------------------------------------------------
; $100-$1FF     Stack
;-------------------------------------------------------------------------------
; $200-$2FF     OAM Sprite Memory
;               Holds the OAM sprite entires that are copied to VRAM each frame.
;-------------------------------------------------------------------------------
; $300-$700     Pi Digits
;               Each byte in this memory region stores a single digit of pi, as
;               computed by the Pi-Spigot routine.
;-------------------------------------------------------------------------------
; $700-$7FF     Unassigned
;-------------------------------------------------------------------------------
; $6000-$78FF   Pi-Spigot Compute Table
;               Holds a table of 16-bit entries used by the Pi-Spigot algorithm
;               to compute the digits of pi. This table is the main ledger used
;               by the algorithm and, as such, should be considered completely
;               off-limits to the rest of the program.
;-------------------------------------------------------------------------------

.scope Game
  FRAME_FLAG = %10000000
  state = $40
  flags = $41
.endscope

.macro SetGameFlag mask
  lda #mask
  ora Game::flags
  sta Game::flags
.endmacro

.macro ClearGameFlag mask
  lda #mask
  eor Game::flags
  sta Game::flags
.endmacro

.enum GameState
  pretitle
  title
  digit_select
  spigot_calculation
.endenum

.macro SetGameState value
.scope
  lda value
  sta Game::state
  DisableRendering
  jsr executeInitHandler
@vblank_wait:
  bit PPU_STATUS
  bpl @vblank_wait
  EnableRendering
.endscope
.endmacro

digitPtr    = $A2   ; 16-bit
renderPtr   = $A4   ; 16-bit

.include "ppu.s"
.include "draw.s"
.include "joypad.s"
.include "state/pretitle.s"
.include "state/title.s"
.include "pi_spigot.s"

.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte %00010000           ; mapper 1 (MMC1), vertical mirroring
  .byte $00                 ; System: NES

.segment "VECTORS"
  .addr nmi
  .addr reset
  .addr 0

.segment "STARTUP"

.segment "CHARS"
.incbin "./src/bin/CHR-ROM.bin"

.segment "CODE"

.proc reset
  sei
  cld
  ldx #%01000000
  stx $4017
  ldx #$ff
  txs
  ldx #0
  stx PPU_CTRL
  stx PPU_MASK
  stx $4010
  bit PPU_STATUS
: bit PPU_STATUS
  bpl :-
  ldx #0
: lda #0
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne :-
: bit PPU_STATUS
  bpl :-
  bit PPU_STATUS
  lda #$3F
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  lda #$0F
  ldx #$20
: sta PPU_DATA
  dex
  bne :-
  jmp main
.endproc

.proc main
  SetGameState GameState::pretitle
  EnableNMI
@loop:
  bit Game::flags
  bpl @loop
  ClearGameFlag Game::FRAME_FLAG
  ReadJoypad1
  jsr executeGameLoopHandler
  jmp @loop
.endproc

.macro PushState
  php
  pha
  txa
  pha
  tya
  pha
.endmacro

.macro PullState
  pla
  tay
  pla
  tax
  pla
  plp
.endmacro

.proc nmi
  PushState
  bit Game::state
  bmi @return
  jsr executeDrawHandler
  VramReset
  SetGameFlag Game::FRAME_FLAG
@return:
  PullState
  rti
.endproc

.macro JumpTable index, low, high
  ldx index
  lda low, x
  sta $20
  lda high, x
  sta $21
  jmp ($0020)
.endmacro

.proc executeInitHandler
  JumpTable Game::state, low, high
.define InitHandler pretitle::init, title::init
low: .lobytes InitHandler
high: .hibytes InitHandler
.endproc

.proc executeDrawHandler
  JumpTable Game::state, low, high
.define DrawHandler pretitle::draw, title::draw
low: .lobytes DrawHandler
high: .hibytes DrawHandler
.endproc

.proc executeGameLoopHandler
  JumpTable Game::state, low, high
.define GameLoopHandler pretitle::game_loop, title::game_loop
low:  .lobytes GameLoopHandler
high: .hibytes GameLoopHandler
.endproc

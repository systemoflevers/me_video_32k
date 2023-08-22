INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
        di ; Disable interrupts. That way we can avoid dealing with them, especially since we didn't talk about them yet :p
        jp Start

REPT $150 - $104
    db 0
ENDR

SECTION "Game code", ROM0

Start:
.waitVBlank
  ld a, [rLY]
  cp 144 ; Check if the LCD is past VBlank
  jr c, .waitVBlank
  xor a ; ld a, 0 ; We only need to reset a value with bit 7 reset, but 0 does the job
  ld [rLCDC], a ; We will have to write to LCDC again later, so it's not a bother, really.

  ;; Load the tile data from ROM to VRAM at address $8000
  ld bc, TileSet.end - TileSet
  ld hl, _VRAM8000
  ld de, TileSet
  call memcpy_big

  ld bc, TileMap

  ;; Disable interupts but set the Stat IE flag so that I 
  ;; can use halt to wait for HBlank.
  di
  ld a, %00000010
  ld [rIE], a

  ld a, %00001000
  ld [rSTAT], a

  ld a, %11100100
  ld [rBGP], a

  ld hl, _SCRN0
  ld de, 12
  ;; 7    LCD and PPU enable      0=Off, 1=On
  ;; 6    Window tile map area    0=9800-9BFF, 1=9C00-9FFF
  ;; 5    Window enable   0=Off, 1=On
  ;; 4    BG and Window tile data area    0=8800-97FF, 1=8000-8FFF
  ;; 3    BG tile map area        0=9800-9BFF, 1=9C00-9FFF
  ;; 2    OBJ size        0=8×8, 1=8×16
  ;; 1    OBJ enable      0=Off, 1=On
  ;; 0    BG and Window enable/priority   0=Off, 1=On

  ld a, %11010001
  ld [rLCDC], a

  ld a, [bc]
  inc bc
mainLoop:
  halt
REPT 10
  ld [hli], a
  ld a, [bc]
  inc bc
ENDR
  ld d, a
  xor a
  ldh [rIF], a
  ld a, d
  ld d, 0
  halt
REPT 10
  ld [hli], a
  ld a, [bc]
  inc bc
ENDR
  add hl, de
  ld d, a
  xor a
  ld [rIF], a
  ld a, h
  cp a, $9A
  jr nz, fixThenLoop
  ld a, l
  cp a, $40
  jr nz, fixThenLoop
  
  ld HL, _SCRN0
  
  ld a, %00000001
  ld [rIE], a

  xor a
  ld [rIF], a
  halt 
  ;; The first vblank should be right on the same frame, so need to wait for
  ;; the next.
  xor a
  ld [rIF], a
  halt 

  ld [rIF], a
  ld a, %00000010
  ld [rIE], a

  ;; Check if we're at the end of the tile map data
  ld a, b
  cp high(TileMap.end + 1)
  jr nz, fixThenLoop
  ld a, c
  cp low(TileMap.end + 1)
  jr nz, fixThenLoop
  ;; At the end of tile map data, need to loop.
  ld bc, TileMap
  ld a, [bc]
  ld d, a    ;; d will be assumed to have the backed up copy of a, so make that correct.
  inc bc
fixThenLoop:
  ld a, d
  ld d, 0
  jp mainLoop

SECTION "Tile Set", ROM0
TileSet:
  incbin "video.gbgfx"
.end

SECTION "Tile Map", rom0
TileMap:
  incbin "video.tilemap", (1079 - 78) * 360, 360 * 78
.end

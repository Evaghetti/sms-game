.include "constants.asm"
.include "tileset.asm"

.text
;==============================================================
; Main program
;==============================================================
.global main
main:
    ld sp, $dff0

    ld hl, VdpData
    ld b, VdpDataEnd - VdpData
    ld c, VDP_CTRL
    otir

    ld a, $00
    out (VDP_CTRL), a
    ld a, $40
    out (VDP_CTRL), a

    ld bc, $4000
    ClearVRAM:
        ld a, $00
        out (VDP_DATA), a
        dec bc
        ld a, b
        or c
        jp nz, ClearVRAM
    
    ld a, $00
    out (VDP_CTRL), a
    ld a, $C0
    out (VDP_CTRL), a

    ld hl, PaletteData
    ld b, PaletteDataEnd - PaletteData
    ld c, VDP_DATA
    otir

    ld a, $00
    out (VDP_CTRL), a
    ld a, $40
    out (VDP_CTRL), a

    ld hl, TileData
    ld bc, TileDataEnd - TileData
    LoadFontTile:
        ld a, (hl)
        out (VDP_DATA), a
        inc hl
        dec bc
        ld a, b
        or c
        jp nz, LoadFontTile

    ld hl, Message
    call PrintText

    ; Turn screen on
    ld a,%11000000
;          |||| |`- Zoomed sprites -> 16x16 pixels
;          |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
;          |||`---- 30 row/240 line mode
;          ||`----- 28 row/224 line mode
;          |`------ VBlank interrupts
;          `------- Enable display
    out (VDP_CTRL), a
    ld a, $81
    out (VDP_CTRL), a
Loop:
    jp Loop


;
; Printa texto em tela no background
; INPUT : hl -> Endereço da mensagem na ROM.
; OUTPUT: Nenhum
; AFETA : hl
PrintText:
    ; Seta para colocar tiles no inicio do tilemap ($4000 | VRAM_WRITE)
    ; TOOD: Setar posição por parâmetro.
    ld a, $00
    out (VDP_CTRL), a
    ld a, $78
    out (VDP_CTRL), a

    LoopPrint:
        ; Carrega o caractere atual, se for 0, é o fim da string e termina o looping
        ld a, (hl)
        cp $00
        jp z, EndPrintText

        ; Subtrai do ASCII carregado o ASCII do primeiro caractere permitido
        ; Assim consigo indexar o caractere.
        sub $20
        out (VDP_DATA), a

        ; O VDP Espera 2 bytes.
        ld a, $00
        out (VDP_DATA), a

        ; Incrementa e volta o looping.
        inc hl
        jp LoopPrint
    EndPrintText:
    ret

;==============================================================
; Data
;==============================================================

.data
Message:
.ascii "ENZO VAGHETTI"
.db 0
MessageEnd:

; VDP initialisation data
VdpData:
.db $04,$80,$00,$81,$ff,$82,$ff,$85,$ff,$86,$ff,$87,$00,$88,$00,$89,$ff,$8a
VdpDataEnd:

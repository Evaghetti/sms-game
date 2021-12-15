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

    ; Turn screen on
    ld a,%11100000
;         |||||||`- b0 Sempre 0
;         ||||||`-- b1 Tamanho dos sprites, 0 8x8, 1 8x16
;         |||||`--- b2 Sempre 0
;         ||||`---- b3 Sempre 0
;         |||`----- b4 Sempre 0
;         ||`------ b5 VBlank interrupts
;         |`------- b6 Enable display
;         `-------- b7 Sempre 1

    out (VDP_CTRL), a
    ld a, $81
    out (VDP_CTRL), a

    ei ; Reabilita interrupts para responder ao VBlank
    MainLoop:
        halt ; Master System só tem um interrupt, aguarda ele ocorrer
        
        ld hl, Message
        ld b, 6
        ld c, 10
        call PrintText
        
        ; TODO: Game Logic
        jp MainLoop


; Printa texto em tela no background
; INPUT : hl -> Endereço da mensagem na ROM.
;   =   : b  -> Posição X do testo dentro do tilemap.
;   =   : c  -> Posição Y do testo dentro do tilemap.
; OUTPUT: Nenhum
; AFETA : hl
PrintText:
    ; Primeiramente seta a posição dentro do tilemap
    push hl ; Salva o endereço da mensagem que vai ser printada.

    ; Tilemap começa 3800, endereço base é esse
    ld hl, VRAM_WRITE | $3800

    ; Se a posição Y passada for 0, não precisa multiplicar por 64
    ld a, c
    cp $00
    jp z, FixPositionX ; Pula pra ajeitar a posição X

    ; Cada linha do tilemap tem 32 tiles, como cada tile são 2 bytes...
    ; Multplica por 64 o numero em c
    LoopMultiplyY:
        ld a, l
        add a, $40
        ld l, a
        adc a, h
        sub l
        ld h, a

        dec c
        jp nz, LoopMultiplyY

    ; Verifica se posição X for 0, se for não precisa ajeitar nada
    FixPositionX:
    ld a, b
    cp $00
    jp z, SetPosition

    ; Multiplica o número em b por 2 (cada tyle é 2 bytes).
    rla
    or l
    ld l, a

    ; Seta a posição do tilemap a ser escrita.
    SetPosition:
    ld a, l
    out (VDP_CTRL), a
    ld a, h
    out (VDP_CTRL), a

    pop hl ; Recupera o endereço da mensagem.
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
.asciz "MENSAGEM POSICIONADA"

; VDP initialisation data
VdpData:
.db %00010110,$80,$00,$81,$ff,$82,$ff,$85,$ff,$86,$ff,$87,$00,$88,$00,$89,$ff,$8a
VdpDataEnd:

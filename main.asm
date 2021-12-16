.include "constants.asm"
.include "player.asm"
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

    ; Seta pro ínicio da paleta de sprites
    ld a, $10
    out (VDP_CTRL), a
    ld a, $C0
    out (VDP_CTRL), a

    ld hl, PlayerPaletteData
    ld b, PlayerPaletteDataEnd - PlayerPaletteData
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

    ld hl, PlayerTileData
    ld b, PlayerTileDataEnd - PlayerTileData
    ld c, VDP_DATA
    otir

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

    ld a, 128
    ld (posX), a
    ld a, 16
    ld (posY), a

    ei ; Reabilita interrupts para responder ao VBlank
    MainLoop:
        halt ; Master System só tem um interrupt, aguarda ele ocorrer
        
        call ReadControllers

        ld hl, Message
        ld b, 6
        ld c, 10
        call PrintText

        ld ix, posX
        ld iy, posY

        ; Seta a posição dos 4 sprites dos player, e seus index
        ld b, (ix)
        ld c, (iy)
        
        ld l, $00
        ld d, $3b
        call SetSpritePosition

        ld a, b
        add a, $08
        ld b, a

        ld l, $01
        ld d, $3c
        call SetSpritePosition

        ld a, b
        sub $08
        ld b, a
        ld a, c
        add a, $08
        ld c, a
        
        ld l, $02
        ld d, $3d
        call SetSpritePosition

        ld a, b
        add a, $08
        ld b, a

        ld l, $03
        ld d, $3e
        call SetSpritePosition

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

; Lê os botões sendo apertados pelo controle 1 e 2
; Salvando em (controller1) e (controller2) respectivamente
; INPUT : Nenhum
; OUTPUT: (controller1) com os botões apertados (bits ligados) do controle 1
;    =  : (controller2) com os botões apertados (bits ligados) do controle 2
; AFFECT: a
; TODO  : Leitura controle 2
ReadControllers:
    in a, (IN_JOY_1)
    and $3f ; Remove os bits que possuem os botoes do controle 2
    xor $3f ; Inverte eles também
    ld (controller1), a
    ret

; Seta a posição de um sprite em tela.
; INPUT : l -> Index do sprite a ser setada a posição
;   =   : b -> Posição X (00-FF)
;   =   : c -> Posição Y (00-FF)
;   =   : d -> Index do tile a qual esse sprite mostra
; OUTPUT: None
; AFFECT: hl, a
; TODO  : Talvez separar atualizar posição e index do tile?
SetSpritePosition:
    ; High byte de onde estão os prites na VDP
    ; (VRAM_WRITE | $3f00) -> $7f00 -> $7f
    ld h, $7f 

    ; Seta VDP pra posição Y do tile que vai ser atualizado.
    ld a, l
    out (VDP_CTRL), a
    ld a, h
    out (VDP_CTRL), a

    ; Passa a posição Y pra VDP
    ld a, c
    out (VDP_DATA), a

    ; d é usado numa soma 16-bit, salva pra n alterar os valores desse registrador
    ; TODO: Necessário?
    push de
        ; Posição X e qual o tile desse sprite tá mais pra frente na memória
        ; Sempre em par, então multiplica o indice por 2
        ld a, l
        rla
        ld l, a
        ; 64 bytes pra frente tá os dados que vão ser atualizados.
        ld de, $0080
        add hl, de
    pop de

    ; Seta VDP pro endereço da posição X
    ld a, l
    out (VDP_CTRL), a
    ld a, h
    out (VDP_CTRL), a

    ; Escreve a posição X na VDP
    ld a, b
    out (VDP_DATA), a

    ; Em seguida, o tile
    ld a, d
    out (VDP_DATA), a
    ret
;==============================================================
; Data
;==============================================================

.data
Message:
.asciz "MENSAGEM POSICIONADA"

; VDP initialisation data
VdpData:
.db %00010110 ; r0
.db %10000000 ; r1
.db %11111111 ; r2
.db %11111111 ; r3
.db %11111111 ; r4
.db %11111111 ; r5
.db %11111111 ; r6
.db %10000101 ; r7
.db %00000000 ; r8
.db %00000000 ; r9
.db %11111111 ; r10
VdpDataEnd:

.bss
controller1: .ds 1
controller2: .ds 1
posX       : .ds 1
posY       : .ds 1

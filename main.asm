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

    ld a, $74
    ld (posX), a
    ld a, $4c
    ld (posY), a

    ei ; Reabilita interrupts para responder ao VBlank
    MainLoop:
        halt ; Master System só tem um interrupt, aguarda ele ocorrer
        
        call ReadControllers

        ld a, (controller1)
        and JOY1_BUT_LEFT
        jp z, VerificaDireita
            ld a, (posX)
            sub $02
            ld (posX), a
        VerificaDireita:
        ld a, (controller1)
        and JOY1_BUT_RIGHT
        jp z, VerificaCima
            ld a, (posX)
            add a, $02
            ld (posX), a
        VerificaCima:
        ld a, (controller1)
        and JOY1_BUT_UP
        jp z, VerificaBaixo
            ld a, (posY)
            sub $02
            ld (posY), a
        VerificaBaixo:
        ld a, (controller1)
        and JOY1_BUT_DOWN
        jp z, FimControle
            ld a, (posY)
            add a, $02
            ld (posY), a
        FimControle:

        ld hl, Message
        ld b, $0c
        ld c, $0a
        call PrintText

        ; Seta a posição dos 4 sprites dos player, e seus index
        ld a, (posX)
        ld b, a
        ld a, (posY)
        ld c, a
        
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
;   =   : b  -> Posição Y do testo dentro do tilemap.
;   =   : c  -> Posição X do testo dentro do tilemap.
; OUTPUT: Nenhum
; AFETA : hl, b, c
PrintText:
    ; Transforma bc no offset necessário dentro do tilemap
    
    ; Cada tile são 2 bytes, como uma linha no tilemap são 32 tiles
    ; É necessário pular 64 bytes para ir para próxima linha
    ; Shifta os bits em b para direita duas vezes, 
    ; e coloca o carry em a (seta os bits o bit 7 pra frente)
    xor a
    rr b
    rra
    rr b
    rra

    ; Multiplica a posição X em 2, e junta isso aos bits que foram
    ; retirados no carry, efetivamente fica b:--YYYYYY c:YYXXXXXX
    rl c
    or c
    ld c, a

    push hl
        ld hl, VRAM_WRITE | $3800 ; Endereço base do tilemap
        add hl, bc ; Acrescenda no endereço base o offset calculado acima

        ; Seta o local que VDP vai escrever os tiles a seguir.
        ld a, l
        out (VDP_CTRL), a
        ld a, h
        out (VDP_CTRL), a
    pop hl

LoopPrint:
    ; Carrega o caractere atual, se for 0, é o fim da string e termina o looping
    ld a, (hl)
    cp $00
    ret z

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

; Lê os botões sendo apertados pelo controle 1 e 2
; Salvando em (controller1) e (controller2) respectivamente
; INPUT : Nenhum
; OUTPUT: (controller1) com os botões apertados (bits ligados) do controle 1
;    =  : (controller2) com os botões apertados (bits ligados) do controle 2
; AFFECT: a
ReadControllers:
    push bc
        in a, (IN_JOY_1) ; Lê os botões do controle 1 e cima/baixo do controle 2
        ld c, a ; Salva o estado dos controles
        and %00111111 ; Mantém apenas os botões do controle 1
        xor %00111111 ; Inverte eles também
        ld (controller1), a
        
        ; 0 o registrador b
        xor a
        ld b, a
        ld a, c ; Restaura os botoes como estavam ao ser lidos

        ; Mantém apenas os botoes do controle 2
        ; E coloca eles nos primeiros bits de b
        and %11000000
        rla
        rl b
        rla
        rl b

        ; Lê o restante do controle 2 e shifta pra esquerda para caber os
        ; botoes de IN_JOY_1
        in a, (IN_JOY_2)
        rla
        rla
        
        ; Une b com a, formando assim todo os botoes do controle
        or b
        ; Inverte e salva
        xor $ff
        ld (controller2), a
    pop bc
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
        and a
        rl l
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
.asciz "HELLO WORLD"

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

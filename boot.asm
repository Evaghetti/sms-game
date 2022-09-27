.text
;============================================================
; Boot section
;==============================================================
.global _start
_start:
    di              ; disable interrupts
    im 1            ; Interrupt mode 1
    jp main         ; jump to main program

.data
.db "TMR SEGA"                  ; Trademark Sega
.db $00, $00                    ; Unused
.db $00, $00                    ; Checksum (Soma dos bytes de $0000 até $7FF0)
.db %00000000, %00000000        ; Código do produto 
.db %00000000                   ; Código do produto (Nibble de cima) e versão da ROM (Nibble inferior)
.db %01001100                   ; Qual video game (nibble de cima) e e tamanho da ROM (nibble debaixo)


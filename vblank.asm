.include "constants.asm"

.text
VBlankInterrupt:
    ; Troca os registradores pras versões reservas deles (shadow)
    ; Com exceção de a, ele fica pra eu poder usar os dados da VDP
    ; no main loop
    ex af, af'
    exx

    ; Satisfaz o interrupt, assim o master system pode gerar
    ; outro VBlank
    in a, (VDP_CTRL)
    
    ; Recupera os registradores.
    exx
    ex af, af'

    ; Quando entra num interrupt outros interrupts são desabilitados
    ; Reabilita eles e retorna pro fluxo
    ei
    reti

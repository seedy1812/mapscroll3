wait_vbl:
	border 3
    ld hl,irq_counter 
	ld a,(hl)
.loop:
	halt
    cp (hl)
    jr z,.loop
	ld (hl),0
	border 6
	ret


vbl:
	di
	push af

 	ld a,(irq_counter)
	inc a
 	ld (irq_counter),a

	pop af

if VBL_ON_LINE_INTERRUPT
    NextReg $c8,1
else
    NextReg $c8,2
endif
    ei
    reti

irq_counter: db 0

    align 32


IM_2_Table:
if VBL_ON_LINE_INTERRUPT
        dw      vbl             ; 11 - ula
else
        dw      linehandler     ; 0 - line interrupt
endif

        dw      inthandler      ; 1 - uart0 rx
        dw      inthandler      ; 2 - uart1 rx
        dw      inthandler     ; 3 - ctc 0
        dw      inthandler      ; 4 - ctc 1
        dw      inthandler      ; 5 - ctc 2
        dw      inthandler      ; 6 - ctc 3
        dw      inthandler      ; 7 - ctc 4
        dw      inthandler      ; 8 - ctc 5
        dw      inthandler      ; 9 - ctc 6
        dw      inthandler      ; 10 - ctc 7
if VBL_ON_LINE_INTERRUPT
        dw      inthandler      ; 10 - ctc 7
else
        dw      vbl             ; 11 - ula
endif
        dw      inthandler      ; 12 - uart0 tx
        dw      inthandler      ; 13 - uart1 tx
        dw      inthandler      ; 14
        dw      inthandler      ; 15


init_vbl:
    di

    nextreg $22,%010
    nextreg $23,100

    ld a,HI(IM_2_Table)
    ld i,a

    nextreg $c0, 1+(IM_2_Table & %11100000) ;low byte IRQ table  | base vector = 0xa0, im2 hardware mode
   	
if VBL_ON_LINE_INTERRUPT
	nextreg $c4,2				; no ULA but Line interrupt 
    nextreg $22,%110            ; disable ula , enable line , MSB line = 0
    nextreg $23,180             ; so line interrupt on 180
else
	nextreg $c4,1				; ULA interrupt no Line
endif
	nextreg $c5,0               ; disable CTC channels
	nextreg $c6,0               ; disable UART

    ; not dma
    nextreg $cc,%10000001    ; NMI will interrupt dma
    nextreg $cd,0            ; ct 0 no interrupt dma
    nextreg $ce,0            ; ct 0 no interrupt dma

    im 2

    ei
    ret

linehandler:
	my_break
    NextReg $c8,2
    ei
    reti

ctc0handler:
	my_break
    NextReg $c9,1
    ei
    reti

inthandler:
	my_break
    ei
    reti
    

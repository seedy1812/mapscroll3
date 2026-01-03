WINDOW_START_Y:		equ 10			; where on screen map is displayed
WINDOW_START_X:		equ 14

WINDOW_WIDTH:		equ +(13*2)		; width in tiles ( 16 pixels wide so times 2)
WINDOW_HEIGHT:     	equ +(10*2+1)	; 10 tiles high (16 pixels so times 2) + 1 extra

MAP_WIDTH:			equ +(13*2*2)	; how may bytes wide
MAP_HEIGHT 			equ 4608		; height in pixels
HW_WIDTH:      		equ 40*2		; hw ism 40 tiles *2

HW_MAP 				equ $e000		; location in memory for hw map
WINDOW_PIXEL_HEIGHT equ (WINDOW_HEIGHT*8)-8	; this is height what is seen on screen
WINDOW_PIXEL_WIDTH	equ WINDOW_WIDTH*8


VBL_ON_LINE_INTERRUPT equ 1

; next regs
LAYER_2_Y_OFFSET 	 	equ $17
LAYER2_CLIP_WINDOW   	equ $18
LINE_INT_LSB		 	equ $23
LAYER3_SCROLL_X_MSB	 	equ $2f
LAYER3_SCROLL_X_LSB	 	equ $30
LAYER3_SCROLL_Y		 	equ $31
SPRITE_NUMBER		 	equ $34
PAL_INDEX            	equ $40
PAL_VALUE_8BIT       	equ $41
PAL_CTRL			 	equ $43
PAL_VALUE_9BIT       	equ $44
TILE_TRANS_INDEX: 	 	equ $4c
MMU_0					equ $50
MMU_1					equ $51
MMU_2					equ $52
MMU_3					equ $53
MMU_4					equ $54
MMU_5					equ $55
MMU_6					equ $56
MMU_7					equ $57
COPPER_DATA				equ $60
COPPER_ADDR_LSB			equ $61
COPPER_CTRL				equ $62
LAYER_3_CTRL		 	equ $6b
TILE_DEF_ATTR		 	equ $6c
LAYER3_MAP_HI		 	equ $6e
LAYER3_TILE_HI		 	equ $6f

LAYER3_BANK7			equ $80

NEXTREG_OUT			 			equ $243b


border macro
           ld a,\0
           out ($fe),a
        endm

MY_BREAK	macro
        db $fd,00
		endm


	OPT Z80
	OPT ZXNEXTREG    

CODE_PAGE equ 2*2

MAP_PAGE equ 9*2
MAP_PAGE_ADDR equ $a000

TILES_PAGE equ 5*2

    seg     CODE_SEG, 			 	CODE_PAGE:$0000,$8000
	seg 	MAP_SEG,				MAP_PAGE:$0000,MAP_PAGE_ADDR
	seg 	TILES_SEG,				TILES_PAGE:$0000,$4000

    seg     CODE_SEG
start:
	ld sp , StackStart

	call backdrop_start

	call video_setup

	call init_vbl

	ld a, 6
	call ReadNextReg
	and %01011111 
	Nextreg 6,a

	nextreg 7,%11 ; 28mhz

frame_loop:

	call backdrop_update

	call wait_vbl

	jr frame_loop

video_setup:
;      nextreg $68,%10000000   ;ula disable
       nextreg $15,%00000100 ; no low rez , LSU ,  sprites lo priority , no sprites
       ret

 ReadNextReg:
       push bc
       ld bc,NEXTREG_OUT
       out (c),a
       inc b
       in a,(c)
       pop bc
       ret


StackEnd:
	ds	128*3
StackStart:
	ds  2

include "irq.s"

include "backdrop.s"

THE_END:

 	savenex "mapscroll3.nex",start


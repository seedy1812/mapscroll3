

set_pal:
        nextreg PAL_INDEX ,a
.loop:
        ld a,(hl)
        inc hl
        Nextreg PAL_VALUE_8BIT,a
        djnz .loop
        ret


MAP_X: dw 0
MAP_Y: dw 0
MAP_PREV_Y: dw 0

backdrop_start:

	nextreg $1c,%00001000	; reset tilemapclipping

;       layer 3 clipping
	nextreg $1b,WINDOW_START_X/2
	nextreg $1b,+(WINDOW_START_X+WINDOW_PIXEL_WIDTH-1)/2
	nextreg $1b,WINDOW_START_Y
	nextreg $1b,WINDOW_START_Y+WINDOW_PIXEL_HEIGHT-1

; set where the map should be

        ld de,0
        ld (MAP_X),de
        ld de,0
        ld (MAP_Y),de
        ld (MAP_PREV_Y),de

	nextreg TILE_TRANS_INDEX,15 ; set transparent colour for tilemap


        nextreg PAL_CTRL,%00110000  ; layer 3 pal 1 to edit
        ld a,0  ; start at index 0
        ld b,16 ; 16 colours
        ld hl,bg_pal    ; the palette
        call set_pal

        ;On , 40x32, 16 bit values , pal0 , no text,0 , 512 tile ,on top of ula
        nextreg LAYER_3_CTRL,%10000011
        ; using inline attributes , clear default just for fun of it
        ;nextreg TILE_DEF_ATTR,%000000000


        ; point to the where map will be store
        ld a,LAYER3_BANK7|(HI(HW_MAP)& $3f)
        nextreg LAYER3_MAP_HI,a

        ; now the tiles offset
        ld a, HI(bg_tiles)& $3f
        nextreg LAYER3_TILE_HI,a

        call backdrop_display

        ret

backdrop_flags: db 0

;de = y
calc_layer3_offset:
        ld b,3
        ld d,0
        bsra de,b       ; y /8

        ld d, HW_WIDTH
        mul
        ret


; de = y
; can be speeded up with a look up table
calc_map_offset:
        ld b,3
        bsra de,b       ; y /8

        ld a, MAP_WIDTH    ; how many bytes wide is the map
        push de         ;d*a
        ld e,a
        mul
        ex de,hl
        pop de
        ld d,a          ; e*a
        mul

        ld a,d
        add a,l
        ld d,a
        ld a,0
        adc a,h
        ld h,a

; hl  = bits 23->16 $00ff0000
; de = 0ffset into 8 k bank

        ex de,hl

; can go over multiple banks
; 8k-1 is $1fff
        ld  a,h
        call backdrop_set_mmu
 
        ld a,$1f
        and h
        ld h,a
        ret

backdrop_copy:
        ld b,3
        ld de,(MAP_Y)
        bsra de,b
        ex de,hl

        ld de,(MAP_PREV_Y)
        bsra de,b

        or a
        sbc hl,de

        ret z

        ld de,(MAP_Y)
        jp  nc,.scrolling_up

.scrolling_down:
        jr .copy

.scrolling_up:
        add de,WINDOW_PIXEL_HEIGHT
.copy:
        call backdrop_store_MMU
        call backdrop_copy_line       

.return:
        ld de,(MAP_Y)
        ld (MAP_PREV_Y),de

        call backdrop_restore_MMU
        ret

backdrop_store_MMU:

        ld a,MMU_5
        call ReadNextReg
        ld a,(backdrop_MMU5)

        ld a,MMU_6
        call ReadNextReg
        ld a,(backdrop_MMU6)

        ld a,MMU_7
        call ReadNextReg
        ld a,(backdrop_MMU7)
        nextreg MMU_7,14
        ret

backdrop_set_mmu:
        swapnib
        srl a
        and 7
        add a, MAP_PAGE
        nextreg MMU_5,a
        inc a
        nextreg MMU_6,a
        ret


backdrop_restore_MMU:
        ld a,(backdrop_MMU7)
        nextreg MMU_7,a
        ld a,(backdrop_MMU6)
        nextreg MMU_6,a
        ld a,(backdrop_MMU5)
        nextreg MMU_5,a
        ret

backdrop_MMU5: db 0
backdrop_MMU6: db 0
backdrop_MMU7: db 0


backdrop_move
        ld hl,backdrop_flags

        bit 0,(hl)
        jr z,.otherway
        
        ld bc,(MAP_Y)
        ld a,b
        or c
        jr z, .go_down
        dec bc
        ld (MAP_Y),bc
        ret
.go_down:
        res 0,(hl)
        ret
.otherway:
        push hl
        ld bc,(MAP_Y)
        ld hl,MAP_HEIGHT-WINDOW_PIXEL_HEIGHT
        or a
        sbc hl,bc
        ld a,h
        or l
        pop hl
        jr z,.go_up
        inc bc
        ld (MAP_Y),bc
        ret
.go_up:
        set 0,(hl)
        ret


backdrop_update:
        or a 
        ld hl,(MAP_X)
        ld bc,WINDOW_START_X
        sbc hl,bc
        jp p, .no
        add hl, 320
.no:
        ld a,h
        and 1
        nextreg LAYER3_SCROLL_X_MSB,a

        ld a, l
        nextreg LAYER3_SCROLL_X_LSB,a
        // set at top of the map - rember 8 pixel border at top
        ld a, (MAP_Y)
        sub WINDOW_START_Y
        nextreg LAYER3_SCROLL_Y,a
    ; point to the where map will be store
    ; top 2 bits are special
        ld a,LAYER3_BANK7|(HI(bg_map)&$3f)
        nextreg LAYER3_MAP_HI,a

        ld a, HI(bg_tiles)&$3f
        nextreg LAYER3_TILE_HI,a

        call backdrop_copy

        call backdrop_move

        ret

backdrop_display:
        call backdrop_store_MMU

        ld de,(MAP_Y)

        ld b, WINDOW_HEIGHT

.loop:
        push bc
        push de

        call backdrop_copy_line

        pop de
        add de,8
        pop bc

        djnz .loop

        call backdrop_restore_MMU
        ret

backdrop_copy_line:
        push de
        call calc_map_offset

        pop de
        call calc_layer3_offset

        add de, HW_MAP
        add hl,MAP_PAGE_ADDR    ; someplace in the 8k map window to copy from

        ld bc,WINDOW_WIDTH*2    ; 2 byts attr * 13 tiles * 2 (each tile 16 pixels)
        ldir
        ret

        SEG MAP_SEG

bg_map: incbin "gfx/bg.nxm"
bg_map_length: equ *-bg_map

        SEG TILES_SEG

bg_tiles: incbin "gfx/bg.nxt"
bg_tiles_length: equ *-bg_tiles


        SEG CODE_SEG

bg_pal: incbin "gfx/bg.nxp"
bg_pal_length: equ *-bg_pal

                

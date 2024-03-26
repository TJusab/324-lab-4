.global _start

.equ PIXEL_ADDR, 0xC8000000
.equ CHAR_ADDR, 0xC9000000
.equ PS2_REG, 0xFF200100
.equ WIDTH, 300				// don't forget to add 19
.equ HEIGHT, 239
.equ CHAR_X_MAX, 79
.equ CHAR_Y_MAX, 59

_start:
        bl      draw_test_screen
end:
        b       end
		
// draws a point on the screen at the specified (x, y) in color c
// pre-- R0: x coordinate
// pre-- R1: y coordinate
// pre-- R2: color c
// post-- R0: store the color in pixel buffer

VGA_draw_point_ASM:
	PUSH {R4, LR}
	LDR R3, =PIXEL_ADDR
	
	// Check x coordinate
	CMP R0, #0			// if x < 0, exit
	POP {R4, LR}
	BLT quit
	
	// TODO: How to check for larger ImmValues
	PUSH {R4, LR}
	MOV R4, #WIDTH
	ADD R4, R4, #19
	CMP R0, R4		// if x > 319, exit
	POP {R4, LR}
	BGT quit
	
	// Check y coordinate
	CMP R1, #0
	BLT quit
	CMP R1, #HEIGHT
	BGT quit
	
	LSL R1, R1, #10
	LSL R0, R0, #1
	ADD R0, R0, R1
	
	// Calculate the memory location
	ADD R3, R3, R0
	
	STRH R2, [R3]
	BX LR

// sets to 0 all valid memory locations --> calls VGA_draw_point_ASM with c = 0
VGA_clear_pixelbuff_ASM:
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
	
	PUSH {LR}
	BL outer_loop
	POP {LR}

outer_loop:
	PUSH {R4, LR}
	
	MOV R4, #WIDTH
	ADD R4, R4, #19
	CMP R0, R4
	BGE quit
	POP {R4, LR}
	BX LR
	
inner_loop:
	CMP R1, #HEIGHT
	BGE inner_loop_exit
	BL VGA_draw_point_ASM
	ADD R1, R1, #1
	B inner_loop
	
inner_loop_exit:
	ADD R0, R0, #1
	B outer_loop

// writes the ASCII code c to the screen at (x, y)
VGA_write_char_ASM:
	LDR R3, =CHAR_ADDR
	
	PUSH {LR}
	// check x coordinate
	CMP R0, #0
	BLT quit
	CMP R0, #CHAR_X_MAX
	BGT quit
	
	// check y coordinate
	CMP R1, #0
	BLT quit
	CMP R1, #CHAR_Y_MAX
	BGT quit
	
	LSL R1, R1, #7
	ADD R0, R0, R1
	
	// Calculate the memory location
	ADD R3, R3, R0
	STRB R2, [R3]
	POP {LR}
	BX LR
	
// sets to 0 --> call VGA_write_char_ASM with c = 0 for every valid location
VGA_clear_charbuff_ASM:
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
	
	PUSH {LR}
	BL outer_loop_charbuff
	POP {LR}

outer_loop_charbuff:
	PUSH {LR}
	CMP R0, #CHAR_X_MAX
	BGE quit
	POP {LR}
	BX LR
	
inner_loop_charbuff:
	CMP R1, #CHAR_Y_MAX
	BGE inner_loop_charbuff_exit
	BL VGA_write_char_ASM
	ADD R1, R1, #1
	B inner_loop_charbuff
	
inner_loop_charbuff_exit:
	ADD R0, R0, #1
	B outer_loop_charbuff

quit:
	BX LR

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
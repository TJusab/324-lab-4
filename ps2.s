/* This part 2 was made by Tayba Jusab */
.global _start

.equ PIXEL_ADDR, 0xC8000000
.equ CHAR_ADDR, 0xC9000000
.equ PS2_REG, 0xFF200100
.equ WIDTH, 300				// don't forget to add 19
.equ HEIGHT, 239
.equ CHAR_X_MAX, 79
.equ CHAR_Y_MAX, 59 

_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
// draws a point on the screen at the specified (x, y) in color c
// pre-- R0: x coordinate
// pre-- R1: y coordinate
// pre-- R2: color c
// post-- R0: store the color in pixel buffer
VGA_draw_point_ASM:
	PUSH {R4-R7, LR}
	// Check x coordinate
	CMP R0, #0			// if x < 0, exit
	BLT quit
	
	// TODO: How to check for larger ImmValues
	MOV R4, #WIDTH
	ADD R4, R4, #19
	CMP R0, R4		// if x > 319, exit
	BGT quit
	
	// Check y coordinate
	CMP R1, #0
	BLT quit
	CMP R1, #HEIGHT
	BGT quit
	
	LSL R4, R0, #1
	LSL R5, R1, #10
	LDR R6, =PIXEL_ADDR
	ORR R7, R4, R5
	ORR R7, R7, R6
	STRH R2, [R7]
	POP {R4-R7, LR}
	BX LR
	
VGA_clear_pixelbuff_ASM:
	PUSH {R4, R6, LR}
	LDR R6, =PIXEL_ADDR
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0

	outer_loop:
		MOV R1, #0
		inner_loop:
			BL VGA_draw_point_ASM
			ADD R1, R1, #1
			CMP R1, #HEIGHT
			BLE inner_loop
		ADD R0, R0, #1
		MOV R4, #WIDTH
		ADD R4, R4, #19
		CMP R0, R4
		BLE outer_loop
		
	POP {R4, R6, LR}
	BX LR

// writes the ASCII code c to the screen at (x, y)
VGA_write_char_ASM:
	PUSH {R4-R7, LR}
	LDR R6, =CHAR_ADDR
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
	
	LSL R4, R0, #0
	LSL R5, R1, #7
	ORR R7, R4, R5
	ORR R7, R7, R6
	STRB R2, [R7]
	
	POP {R4-R7, LR}
	BX LR
	
// sets to 0 --> call VGA_write_char_ASM with c = 0 for every valid location
VGA_clear_charbuff_ASM:
	PUSH {R4, R6, LR}
	LDR R6, =CHAR_ADDR
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0

	outer_loop_charbuff:
		MOV R1, #0
		inner_loop_charbuff:
			BL VGA_draw_point_ASM
			ADD R1, R1, #1
			CMP R1, #CHAR_Y_MAX
			BLE inner_loop_charbuff
		ADD R0, R0, #1
		CMP R0, #CHAR_X_MAX
		BLE outer_loop_charbuff
		
	POP {R4, R6, LR}
	BX LR

quit:
	BX LR


@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	PUSH {R4-R6, LR}
	LDR R6, =PS2_REG
	LDR R5, [R6]
	LSR R4, R5, #15
	AND R4, R4, #0x1
	CMP R4, #0			// Let R4 = RVALID
	BEQ RINVALID
	STRB R5, [R0]
	MOV R0, #1
	POP {R4-R6, LR}
	BX LR
	
	RINVALID:
		MOV R0, #0
		POP {R4-R6, LR}
		BX LR
	
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
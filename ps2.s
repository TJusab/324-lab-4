.global _start

.equ PIXEL_ADDR, 0xC8000000
.equ CHAR_ADDR, 0xC9000000
.equ PS2_REG, 0xFF200100
.equ WIDTH, 300				// don't forget to add 19
.equ HEIGHT, 219
.equ CHAR_X_MAX, 79
.equ CHAR_Y_MAX, 59 

_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
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
	
	STRB R2, [R3]
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
	CMP R0, #WIDTH
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

@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	LDR R1, =PS2_REG
	LSR R0, R0, #15
	AND R1, R0, #1

quit:
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

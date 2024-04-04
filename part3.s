.global _start

GoLBoard:
//     x 0 1 2 3 4 5 6 7 8 9 a b c d e f y
.word 0b0000000000000000 // 0
.word 0b0000000000000000 // 1
.word 0b0000000100000000 // 2
.word 0b0000000100000000 // 3
.word 0b0000000100000000 // 4
.word 0b0000000111110000 // 5
.word 0b0000111110000000 // 6
.word 0b0000000010000000 // 7
.word 0b0000000010000000 // 8
.word 0b0000000010000000 // 9
.word 0b0000000000000000 // a
.word 0b0000000000000000 // b

// Holds the current location of the cursor, by default (0,0)
cursor_x: .word 1
cursor_y: .word 1

key_pressed: .word 0

_start:
    MOV A1, #0
    LDR A3, =#1366
    BL GoL_draw_board_ASM
main:
    BL GoL_poll_pressed_key

    b main


end:
    b end



//------------------------// Part3 - Game of Life subroutines (GoL) //------------------------//

// draws a line on the screen from (x1, y1) to (x2, y2) in the color c
// where where either x1 = x2 (a vertical line) or y1 = y2 (a horizontal line)
// pre-- A1: x1
// pre-- A2: y1
// pre-- A3: x2
// pre-- A4: y2
// pre-- V1: color c
VGA_draw_line_ASM:
    PUSH {A1-V1, LR}
    // Check vertical or horizontal:
    CMP A1, A3 // same x's ?
    BNE not_vertical_line
        BL VGA_draw_vertical_line
        B succesfully_drew_line
    not_vertical_line:

    // if its not vertical check if its horizontal (same y's)
    CMP A2, A4
    BNE error_line
        BL VGA_draw_horizontal_line
        B succesfully_drew_line

    // Catch if subroutine called with wrong arguments
    error_line:
        B error_line // infinite loop so stop here

    succesfully_drew_line:
    POP {A1-V1, LR}
    BX LR

// pre-- A1: x1
// pre-- A2: y1
// pre-- A4: y2
// pre-- V1: color c
VGA_draw_vertical_line:
    PUSH {A1-V1, LR}
    // make sure y1(A2) is the smallest number (A2<=A4: y1<=y2)
    CMP A2, A4
    BLE do_not_switch_y
        // if GT: y1>y2, switch the values
        ADD A3, A2, #0 // Save temp=A2
        ADD A2, A4, #0 // A2=A4
        ADD A4, A3, #0 // A4=temp
    do_not_switch_y:

    ADD A3, V1, #0 // Move color(V1) into R2
    
    // loop which draw every points from y1 to y2
    loop_draw_each_points_on_the_vertical_line:
        BL VGA_draw_point_ASM // draw
        ADD A2, A2, #1 // increment A2 (y1++)
        CMP A2, A4  // check if y1<=y2, if yes continue drawing points
        BLE loop_draw_each_points_on_the_vertical_line

    POP {A1-V1, LR}
    BX LR


// pre-- A1: x1
// pre-- A2: y1
// pre-- A3: x2
// pre-- V1: color c
VGA_draw_horizontal_line:
    PUSH {A1-V1, LR}
    // make sure x1(A1) is the smallest number (A1<=A3: x1<=x2)
    CMP A1, A3
    BLE do_not_switch_x
        // if GT: x1>x2, switch the values
        ADD A4, A1, #0 // Save temp(A4)=A1
        ADD A1, A3, #0 // A1=A3
        ADD A3, A4, #0 // A3=temp(A4)
    do_not_switch_x:
    
    // loop which draw every points from y1 to y2
    loop_draw_each_points_on_the_horizontal_line:
        // pre-- R0: x coordinate
        // pre-- R1: y coordinate
        // pre-- R2: color c
        PUSH {A3} // we need to put into A3/R2 the color
        ADD A3, V1, #0 // Move color(V1) into R2
        BL VGA_draw_point_ASM // draw
        POP {A3} // we need to remember x2

        ADD A1, A1, #1 // increment A1 (x1++)
        CMP A1, A3  // check if x1<=x2, if yes continue drawing points
        BLE loop_draw_each_points_on_the_horizontal_line

    POP {A1-V1, LR}
    BX LR

// pre-R2/A3: Color c
VGA_set_background:
    PUSH {R4, R6, LR}
	LDR R6, =PIXEL_ADDR
	MOV R0, #0
	MOV R1, #0

	outer_loop_background:
		MOV R1, #0
		inner_loop_background:
			BL VGA_draw_point_ASM
			ADD R1, R1, #1
			CMP R1, #HEIGHT
			BLE inner_loop_background
		ADD R0, R0, #1
		MOV R4, #WIDTH
		ADD R4, R4, #19
		CMP R0, R4
		BLE outer_loop_background
		
	POP {R4, R6, LR}
	BX LR

// Draw  a 16x12 grid on the VGA display in a specified background color and grid color
// Pre-- A1: color of the grid
// Pre-- A3: color of the background
GoL_draw_grid_ASM:
    PUSH {A1-V1, LR}

    // A3: color of the background
    BL VGA_set_background

    // pre-- V1: color c
    ADD V1, A1, #0 // set V1 to hold the color

    // draw horizontal lines
    // pre-- A1: x1
    MOV A1, #0 // x1 = 0
    // pre-- A2: y1
    MOV A2, #0 // starts drawing a line at y=0
    // pre-- A3: x2
    LDR A3, =#319 // x2 = 319

    LDR A4, =#239 // need to load the max since value too big
    loop_draw_every_horizontal_lines:
        BL VGA_draw_horizontal_line

        ADD A2, #20
        CMP A2, A4 // if y1<=239, keep drawing horizontal lines
        BLE loop_draw_every_horizontal_lines

    // draw vertical lines
    // pre-- A1: x1
    MOV A1, #0
    // pre-- A2: y1
    MOV A2, #0
    // pre-- A4: y2
    LDR A4, =#239

    LDR A3, =#319 // need to load the max since value too big
    loop_draw_every_vertical_lines:
        BL VGA_draw_vertical_line

        ADD A1, #20
        CMP A1, A3 // if x1<=239, keep drawing vertical lines
        BLE loop_draw_every_vertical_lines


    POP {A1-V1, LR}

    BX LR

// Draw rectangles from pixel (x1, y1) to (x2, y2)
// pre-- A1: x1
// pre-- A2: y1
// pre-- A3: x2
// pre-- A4: y2
// pre-- V1: color c
VGA_draw_rect_ASM:
    PUSH {A1-V1, LR}
    // pre-- A1: x1
    // pre-- A2: y1
    // pre-- A3: x2
    // pre-- V1: color c
    loop_draw_rectangle:
        BL VGA_draw_horizontal_line

        ADD A2, #1
        CMP A2, A4 // if x1<=239, keep drawing vertical lines
        BLE loop_draw_rectangle

    POP {A1-V1, LR}
    BX LR

// Fills the rectangle of grid location (x, y) with color c
// Grid: 0 ≤ x < 16, 0 ≤ y < 12
// Pre-- A1: x
// Pre-- A2: y
// Pre-- V1: color
// during V2: temp holds 20
GoL_fill_gridxy_ASM:
    PUSH {A1-V2, LR}
    MOV V2, #20
    // pre-- A1: x1
    MUL A1, A1, V2 // x * 20
    ADD A1, A1, #1
    // pre-- A2: y1
    MUL A2, A2, V2 // y * 20
    ADD A2, A2, #1

    SUB V2, V2, #2
    // pre-- A3: x2
    ADD A3, A1, V2 // x * 20 + 19 = x2
    // pre-- A4: y2
    ADD A4, A2, V2 // y * 20 + 19 = y2
    // pre-- V1: color c
    BL VGA_draw_rect_ASM

    POP {A1-V2, LR}
    BX LR

// Read GoLBoard and fills grid locations (x, y), 0 ≤ x < 16, 0 ≤ y < 12 with color c if GoLBoard[y][x] == 1.
// Pre-- A1: color of the grid(and fill)
// Pre-- A3: color of the background
GoL_draw_board_ASM:
    PUSH {A1-V1, LR}
    // First: Draw the grid
    BL GoL_draw_grid_ASM
    ADD V1, A1, #0 // V1 = A1 for GoL_fill_gridxy_ASM (Pre-- V1: color)

    // Second: Draw rectangles for every 1 in GoLBoard
    LDR A2, =GoLBoard // Start by loading the address of the board (every word is a row, so 12 rows)

    MOV A4, #0 // row index
    loop_fill_all_ones_in_GoLBoard:
        LDR A1, [A2], #4 // Start by reading a row (a word) and post-increment the address
        // Every last 16 bits in A1 represents the value of the cells in the row, so read last bit and right-shift:
        MOV A3, #15 // Column index

        check_each_cell_in_row:
            TST A1, #1 // Is the least significant bit 1 ?
            BEQ skip_filling_cell // if its not 1, skip the hex
                // if it is one color the cell

                PUSH {A1, A2} // save current values an prep the parameters
                // Pre-- A1: x
                ADD A1, A3, #0 // A1 = row_index(A4)
                // Pre-- A2: y
                ADD A2, A4, #0 // A1 = column_index(A3)
                // Pre-- V1: color => done earlier
                BL GoL_fill_gridxy_ASM
                POP {A1, A2}

            skip_filling_cell:
            LSR A1, #1 // shift value to check next bit
            SUB A3, A3, #1 // decrease column index
            CMP A3, #0
        BGE check_each_cell_in_row // keep looping as long as column_index>=0

        ADD A4, A4, #1 // increase row index
        CMP A4, #12
    BLT loop_fill_all_ones_in_GoLBoard // keep looping as long as row_index<12

    // Finally draw cursor on top
    BL Cursor_draw_cursor

    POP {A1-V1, LR}
    BX LR


// Check for a pressed key
GoL_poll_pressed_key:
    PUSH {A1, A2, LR}
    read_key_pressed:
    LDR A1, =key_pressed
    BL read_PS2_data_ASM // Returns value in R0

    // If A1 is 1 after reading then read the key pressed
    CMP A1, #1
    BNE done_polling_pressed_key
        // Read code after the release:
        // f0 000180f0
        LDR A1, key_pressed
        LDR A2, =#0xf0
        CMP A1, A2 // when its a released key, skip next key
        BNE done_polling_pressed_key
            read_key_released: // reread the next key
            LDR A1, =key_pressed
            BL read_PS2_data_ASM
            CMP A1, #1
            BNE read_key_released
            LDR A1, key_pressed

            PUSH {A1, A2, V1}
            // erase current position of the star before changing position

            // Pre-- A1: x
            LDR A1, cursor_x
            // Pre-- A2: y
            LDR A2, cursor_y
            
            // First get the current value to know which color to use 
            BL GoL_state_of_tile
            CMP A1, #0
            LDREQ V1, =#1366
            LDRNE V1, =#0

            // Fills the rectangle of grid location (x, y) with color c
            // Grid: 0 ≤ x < 16, 0 ≤ y < 12
            // Pre-- A1: x
            LDR A1, cursor_x
            // Pre-- A2: y
            LDR A2, cursor_y
            // Pre-- V1: color
            // during V2: temp holds 20
            BL GoL_fill_gridxy_ASM
            POP {A1, A2, V1}
        
            LDR A2, =#0x1d
            CMP A1, A2 // check if it is W
            BNE not_w_pressed
                LDR A3, =cursor_y
                LDR A4, cursor_y
                CMP A4, #0
                BLE done_polling_pressed_key // do not move up if y<=0
                    SUB A4, A4, #1 // Move up
                    STR A4, [A3] // Store new value of cursor
                    BL Cursor_draw_cursor
                    B done_polling_pressed_key
            not_w_pressed:

            LDR A2, =#0x1B
            CMP A1, A2
            BNE not_s_pressed
                LDR A3, =cursor_y
                LDR A4, cursor_y
                CMP A4, #11
                BGE done_polling_pressed_key // do not move up if y>=12
                    ADD A4, A4, #1 // Move down
                    STR A4, [A3] // Store new value of cursor
                    BL Cursor_draw_cursor
                    B done_polling_pressed_key
            not_s_pressed:

            LDR A2, =#0x1C
            CMP A1, A2
            BNE not_a_pressed
                LDR A3, =cursor_x
                LDR A4, cursor_x
                CMP A4, #0
                BLE done_polling_pressed_key // do not move up if x<=0
                    SUB A4, A4, #1 // Move left
                    STR A4, [A3] // Store new value of cursor
                    BL Cursor_draw_cursor
                    B done_polling_pressed_key
            not_a_pressed:

            LDR A2, =#0x23
            CMP A1, A2
            BNE not_d_pressed
                LDR A3, =cursor_x
                LDR A4, cursor_x
                CMP A4, #15
                BGE done_polling_pressed_key // do not move up if x>=15
                    ADD A4, A4, #1 // Move right
                    STR A4, [A3] // Store new value of cursor
                    BL Cursor_draw_cursor
                    B done_polling_pressed_key
            not_d_pressed:

    done_polling_pressed_key:
    POP {A1, A2, LR}
    BX LR

// Draws cursor at cursor_x and at cursor_y
// During A4: cursor_x
// During V2: cursor_y
Cursor_draw_cursor:
    PUSH {A1-V3, LR}
    LDR A4, cursor_x
    LDR V2, cursor_y
    MOV V3, #20
    MUL A4, A4, V3
    MUL V2, V2, V3

    // center star:
    ADD A4, A4, #1
    ADD V2, V2, #1

    // pre-- V1: color c
    LDR V1, =#0b1111111000000000

    // pre-- A1: x1
    ADD A1, A4, #8
    // pre-- A2: y1
    ADD A2, V2, #0
    // pre-- A3: x2
    ADD A3, A4, #10
    BL VGA_draw_horizontal_line
    
    // pre-- A1: x1
    ADD A1, A4, #7
    // pre-- A2: y1
    ADD A2, V2, #1
    // pre-- A3: x2
    ADD A3, A4, #11
    BL VGA_draw_horizontal_line
    ADD A2, V2, #2
    BL VGA_draw_horizontal_line
    
    // pre-- A1: x1
    ADD A1, A4, #6
    // pre-- A2: y1
    ADD A2, V2, #3
    // pre-- A3: x2
    ADD A3, A4, #12
    BL VGA_draw_horizontal_line
    ADD A2, V2, #4
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #1
    // pre-- A2: y1
    ADD A2, V2, #5
    // pre-- A3: x2
    ADD A3, A4, #17
    BL VGA_draw_horizontal_line
    ADD A2, V2, #8
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #0
    // pre-- A2: y1
    ADD A2, V2, #6
    // pre-- A3: x2
    ADD A3, A4, #18
    BL VGA_draw_horizontal_line
    ADD A2, V2, #7
    BL VGA_draw_horizontal_line
    
    // pre-- A1: x1
    ADD A1, A4, #2
    // pre-- A2: y1
    ADD A2, V2, #9
    // pre-- A3: x2
    ADD A3, A4, #16
    BL VGA_draw_horizontal_line
    ADD A2, V2, #15
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #3
    // pre-- A2: y1
    ADD A2, V2, #10
    // pre-- A3: x2
    ADD A3, A4, #15
    BL VGA_draw_horizontal_line
    ADD A2, V2, #13
    BL VGA_draw_horizontal_line
    ADD A2, V2, #14
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #4
    // pre-- A2: y1
    ADD A2, V2, #11
    // pre-- A3: x2
    ADD A3, A4, #14
    BL VGA_draw_horizontal_line
    ADD A2, V2, #12
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #2
    // pre-- A2: y1
    ADD A2, V2, #16
    // pre-- A3: x2
    ADD A3, A4, #8
    BL VGA_draw_horizontal_line
    // pre-- A1: x1
    ADD A1, A4, #10
    // pre-- A3: x2
    ADD A3, A4, #16
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #2
    // pre-- A2: y1
    ADD A2, V2, #17
    // pre-- A3: x2
    ADD A3, A4, #7
    BL VGA_draw_horizontal_line
    // pre-- A1: x1
    ADD A1, A4, #11
    // pre-- A3: x2
    ADD A3, A4, #16
    BL VGA_draw_horizontal_line

    // pre-- A1: x1
    ADD A1, A4, #2
    // pre-- A2: y1
    ADD A2, V2, #17
    // pre-- A3: x2
    ADD A3, A4, #6
    BL VGA_draw_horizontal_line
    // pre-- A1: x1
    ADD A1, A4, #12
    // pre-- A3: x2
    ADD A3, A4, #16
    BL VGA_draw_horizontal_line

    POP {A1-V3, LR}
    BX LR

// Get the value(0 or 1) of the tile
// Pre--A1: column index (x) 
// Pre--A2: row index (y)
// Post-A1: return the state of tile
GoL_state_of_tile:
    PUSH {A2-V2, LR}

    LDR A3, =GoLBoard

    // Get the offset of the address to access specific row (row_index * 4)
    MOV A4, #4
    MUL A2, A2, A4

    // Load the row
    LDR V1, [A3, A2]

    // Get the cell with the column index
    // Shift = total number of column - column index
    MOV V2, #15
    SUB A1, V2, A1

    LSR V1, A1

    TST V1, #1 // Is the least significant bit 1 ?
    MOVEQ A1, #0 // if its not 1, return 0
    MOVNE A1, #1 // if it is 1, return 1

    POP {A2-V2, LR}
    BX LR


//------------------------// VGA & PS2 drivers //------------------------//

.equ PIXEL_ADDR, 0xC8000000
.equ CHAR_ADDR, 0xC9000000
.equ PS2_REG, 0xFF200100
.equ WIDTH, 300				// don't forget to add 19
.equ HEIGHT, 239
.equ CHAR_X_MAX, 79
.equ CHAR_Y_MAX, 59 

@ TODO: copy VGA driver here.
// draws a point on the screen at the specified (x, y) in color c
// pre-- R0: x coordinate
// pre-- R1: y coordinate
// pre-- R2: color c
// post-- R0: store the color in pixel buffer
VGA_draw_point_ASM:
	PUSH {R0-R7, LR}
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
	POP {R0-R7, LR}
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
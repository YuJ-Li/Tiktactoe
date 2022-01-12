.text
.global _start
 .equ c_buffer,0xc9000000
 .equ p_buffer,0xc8000000
 .equ ps2_data,0xff200100
 .equ ps2_control,0xff200104
white: .word 0xffff
black: .word 0x0000
read: .space 4,0
board: .word 0,0,0,0,0,0,0,0,0
win: .word 0
_start:
        b       main_loop
end:
        b       end

@ TODO: copy VGA driver here.
VGA_draw_point_ASM:
//r0 : 1st argument int x
//r1 : 2nd argument int y
//r2 : 3rd arguemnt short c
		push {r0,r1,r2,r3}
		lsl r0,r0,#1 //shift x
		lsl r1,r1,#10 //shift y
		ldr r3,=p_buffer // pixel buffer addr
		add r3,r3,r0
		add r3,r3,r1 //pixel address
		strh r2,[r3] //str to the 
		pop {r0,r1,r2,r3}
		bx lr
VGA_clear_pixelbuff_ASM:
		push {r0,r1,r2}
		mov r2,#0x0 //reset to 0
		mov r0,#0 // i
		mov r1,#0 // j
		
		iloop:
		cmp r0,#320
		blt jloop
		bge exit
		
		jloop:
		cmp r1,#240
		blt execute
		addge r0,r0,#1
		movge r1,#0
		bge iloop
	
		execute:
		push {lr}
		bl VGA_draw_point_ASM
		pop {lr}
		add r1,r1,#1
		b jloop
		
		exit:
		pop {r0,r1,r2}
		bx lr
//----------pseudo code---------		
//for (int i=0,i<320,i++){
//	for (int j =0,j<240,j++){
		//VGA_draw_point_ASM with r0=0x0
//	}
//}
//------------------------------


VGA_write_char_ASM:
//r0 : 1st argument int x
//r1 : 2nd argument int y
//r2 : 3rd arguemnt char c
		push {r0,r1,r2,r3}
		
		//x in [0,79], if not, do nothing and return
		cmp r0,#0 
		bxlt lr
		cmp r0,#79
		bxgt lr
		
		//y in [0,59], if not, do nothing and return
		cmp r1,#0
		bxlt lr
		cmp r1,#59
		bxgt lr
		
		//operation
		lsl r1,r1,#7 //shift y
		ldr r3,=c_buffer // character buffer addr
		add r3,r3,r0
		add r3,r3,r1 //pixel address
		strb r2,[r3] //str to the c addr
		pop {r0,r1,r2,r3}
		bx lr
VGA_clear_charbuff_ASM:
		push {r0,r1,r2}
		mov r2,#0x0 //reset to 0
		mov r0,#0 // i
		mov r1,#0 // j
		
		icloop:
		cmp r0,#80
		blt jcloop
		bge c_exit
		
		jcloop:
		cmp r1,#60
		blt c_execute
		addge r0,r0,#1
		movge r1,#0
		bge icloop
	
		c_execute:

		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		add r1,r1,#1
		b jcloop
		
		c_exit:
		pop {r0,r1,r2}
		bx lr
				

read_PS2_data_ASM:
//input:r0  ----memory addr
//output:r0 ----boolean if the data is valid
		push {r1,r2}
		//get data
		ldr r1,=ps2_data
	
		ldr r1,[r1]  // ps2_data

		//shift & and
		lsr r1,r1,#15
		and r1,r1,#0x1
		//evaluate the rvalid bit
		cmp r1,#1
		movne r0,#0		
		bne ps2_exit
		ldr r1,=ps2_data
		ldrb r2,[r1]
		strb r2, [r0]
		mov r0,#1
		
		ps2_exit:
		pop {r1,r2}
		bx lr

draw_rectangle:
//provided method to draw a rectangle
//r0: int x -- the x coordinate of the top left corner
//r1: int y -- the y corrdinate of the top left corener
//r2: int width
//r3: int height
//r4: int c -- color #move this to sp
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        ldr     r7, [sp, #32]
        add     r9, r1, r3
        cmp     r1, r9
        popge   {r4, r5, r6, r7, r8, r9, r10, pc}
        mov     r8, r0
        mov     r5, r1
        add     r6, r0, r2
        b       .line_L2
.line_L5:
        add     r5, r5, #1
        cmp     r5, r9
        popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.line_L2:
        cmp     r8, r6
        movlt   r4, r8
        bge     .line_L5
.line_L4:
        mov     r2, r7
        mov     r1, r5
        mov     r0, r4
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        cmp     r4, r6
        bne     .line_L4
        b       .line_L5

VGA_fill_ASM:
//set background color to black
		push {lr}
		bl VGA_clear_pixelbuff_ASM
		pop {lr}
		bx lr
draw_grid_ASM:
//big rec: wdith = height = 207
//small rec: width = height = 65
//thickness = 3
		push {r0,r1,r2,r3,r4,lr}
		//big rec
		mov r0,#56
		mov r1,#32
		mov r2,#207
		mov r3,#207
		ldr r4,white
		str r4,[sp]
		bl draw_rectangle
		//small rec
		//#1
		mov r0,#59
		mov r1,#35
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#2
		mov r0,#127
		mov r1,#35
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#3
		mov r0,#195
		mov r1,#35
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#4
		mov r0,#59
		mov r1,#103
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#5
		mov r0,#127
		mov r1,#103
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#6
		mov r0,#195
		mov r1,#103
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#7
		mov r0,#59
		mov r1,#171
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#8
		mov r0,#127
		mov r1,#171
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		//#9
		mov r0,#195
		mov r1,#171
		mov r2,#65
		mov r3,#65
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		
		pop {r0,r1,r2,r3,r4,lr}
		bx lr
draw_plus_ASM:
//r0: int x ---center coordiante x
//r1: int y ---center coordiante y
		push {r0,r1,r2,r3,r4,r5,r6,lr}
		mov r5,r0 // temp for r0
		mov r6,r1 // temp for r1
		sub r0,r0,#21
		sub r1,r1,#2
		mov r2,#43
		mov r3,#4
		ldr r4,white
		str r4,[sp]
		bl draw_rectangle
		mov r0,r5
		mov r1,r6
		sub r0,r0,#2
		sub r1,r1,#21
		mov r2,#4
		mov r3,#43
		bl draw_rectangle

		pop {r0,r1,r2,r3,r4,r5,r6,lr}
		bx lr
draw_square_ASM:
//r0: int x ---center coordiante x
//r1: int y ---center coordiante y
		push {r0,r1,r2,r3,r4,r5,r6,lr}
		mov r5,r0 // temp for r0
		mov r6,r1 // temp for r1
		sub r0,r0,#14
		sub r1,r1,#14
		mov r2,#30
		mov r3,#30
		ldr r4,white
		str r4,[sp]
		bl draw_rectangle
		
		mov r0,r5
		mov r1,r6
		sub r0,r0,#11
		sub r1,r1,#11
		mov r2,#24
		mov r3,#24
		ldr r4,black
		str r4,[sp]
		bl draw_rectangle
		
		pop {r0,r1,r2,r3,r4,r5,r6,lr}
		bx lr
Player_turn_ASM:
//r0 : 0 for player 1; 1 for player 2


		//T
		push {r0,r1,r2,r3}
		mov r3,r0 //temp for r0
		
		mov r0,#37
		mov r1,#3
		mov r2,#84
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//u
		mov r0,#38
		mov r1,#3
		mov r2,#117
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//r
		mov r0,#39
		mov r1,#3
		mov r2,#114
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//n
		mov r0,#40
		mov r1,#3
		mov r2,#110
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//:
		mov r0,#41
		mov r1,#3
		mov r2,#58
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//space
		mov r0,#42
		mov r1,#3
		mov r2,#32
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//P
		mov r0,#43
		mov r1,#3
		mov r2,#80
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//1 or 2
		cmp r3,#0
		mov r0,#44
		mov r1,#3
		moveq r2,#49
		movne r2,#50
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		
		pop {r0,r1,r2,r3}
		bx lr
		
result_ASM:
//r0: result of the game
// 0 for p1_win, 1 for p2_win, 2 for draw
		push {r0,r1,r2}
		cmp r0,#0
		beq p1_win
		cmp r0,#1
		beq p2_win
		cmp r0,#2
		beq draw
		p1_win:
		//P
		mov r0,#38
		mov r1,#5
		mov r2,#80
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//1
		mov r0,#39
		mov r1,#5
		mov r2,#49
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//space
		mov r0,#40
		mov r1,#5
		mov r2,#32
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//W
		mov r0,#41
		mov r1,#5
		mov r2,#87
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//i
		mov r0,#42
		mov r1,#5
		mov r2,#105
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//n
		mov r0,#43
		mov r1,#5
		mov r2,#110
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		b win_end
		
		p2_win:
		
				//P
		mov r0,#38
		mov r1,#5
		mov r2,#80
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//2
		mov r0,#39
		mov r1,#5
		mov r2,#50
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//space
		mov r0,#40
		mov r1,#5
		mov r2,#32
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//W
		mov r0,#41
		mov r1,#5
		mov r2,#87
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//i
		mov r0,#42
		mov r1,#5
		mov r2,#105
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//n
		mov r0,#43
		mov r1,#5
		mov r2,#110
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		b win_end
		draw:
		//D
		mov r0,#39
		mov r1,#5
		mov r2,#68
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//R
		mov r0,#40
		mov r1,#5
		mov r2,#82
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//A
		mov r0,#41
		mov r1,#5
		mov r2,#65
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		//W
		mov r0,#42
		mov r1,#5
		mov r2,#87
		push {lr}
		bl VGA_write_char_ASM
		pop {lr}
		win_end:	
		pop {r0,r1,r2}
		bx lr
main_loop:
//read_PS2_data_ASM:
//input:r0  ----memory addr
//output:r0 ----boolean if the data is valid

//initialization
		push {lr}
		bl VGA_fill_ASM
		pop {lr}
		push {lr}
		bl draw_grid_ASM
		pop {lr}
		push {lr}
		bl VGA_clear_charbuff_ASM
		pop {lr}
		
//check if input is valid
check:
		push {r0}
		ldr r0,=read
		push {lr}
		bl read_PS2_data_ASM
		pop {lr}
		cmp r0,#0
		popeq {r0}
		beq check
		pop {r0}
		
//read input
		push {r0,r1}
		ldr r0,=read
		ldr r1,[r0] // input data
		cmp r1,#0x45
		popne {r0,r1}
		bne check
		pop {r0,r1}
		b start_game
reinit:
		push {r2,r3}
		ldr r2,=board
		mov r3,#0
		str r3,[r2] //index 0
		add r2,r2,#4
		str r3,[r2] // index 1
		add r2,r2,#4
		str r3,[r2] // index 2
		add r2,r2,#4
		str r3,[r2] // index 3
		add r2,r2,#4
		str r3,[r2] // index 4
		add r2,r2,#4
		str r3,[r2] // index 5
		add r2,r2,#4
		str r3,[r2] // index 6
		add r2,r2,#4
		str r3,[r2] // index 7
		add r2,r2,#4
		str r3,[r2] // index 8
		//clear win record
		ldr r2,=win
		mov r3,#0
		str r3,[r2]
		pop {r2,r3}
		push {lr}
		bl VGA_fill_ASM
		pop {lr}
		push {lr}
		bl draw_grid_ASM
		pop {lr}
		push {lr}
		bl VGA_clear_charbuff_ASM
		pop {lr}
start_game:	
		mov r11,#0 //player bit, 0 for player 1, 1 for player 2
		mov r10,#0 //step counter
read_steps:
		push {r0,lr}
		mov r0,r11
		bl Player_turn_ASM
		pop {r0,lr}
		
		
		push {r0}
		ldr r0,=read
		push {lr}
		bl read_PS2_data_ASM
		pop {lr}
		cmp r0,#0
		popeq {r0}
		beq read_steps
		pop {r0}
		
		ldr r1,=read
		ldr r0,[r1] // input data
		cmp r0,#0x16 //1
		beq s1
		cmp r0,#0x1e //2
		beq s2
		cmp r0,#0x26 //3
		beq s3
		cmp r0,#0x25 //4
		beq s4
		cmp r0,#0x2e //5
		beq s5
		cmp r0,#0x36 //6
		beq s6
		cmp r0,#0x3d //7
		beq s7
		cmp r0,#0x3e //8
		beq s8
		cmp r0,#0x46 //9
		beq s9
		cmp r0,#0x45 //0
		
		beq reinit
		b read_steps // if invalid (input not [0-9])
		s1:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#92
		mov r1,#68
		
		cmp r11,#0
		bleq draw_square_ASM
		blne draw_plus_ASM
		
		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		//counter ++
		add r10,r10,#1
		
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip:
		pop {r1}
		
		
		b read_steps
		s2:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#4 // index[1] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#160
		mov r1,#68
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM
		
		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#4
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip2
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip2:
		pop {r1}
		
		
		b read_steps
		s3:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#8 // index[2] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#228
		mov r1,#68
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM
		
		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#8
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip3
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip3:
		pop {r1}
		
		
		b read_steps
		s4:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#12 // index[3] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#92
		mov r1,#136
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#12
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip4
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip4:
		pop {r1}
		
		
		b read_steps
		s5:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#16 // index[4] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#160
		mov r1,#136
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#16
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip5
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip5:
		pop {r1}
		
		
		b read_steps
		s6:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#20 // index[5] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#228
		mov r1,#136
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#20
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip6
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip6:
		pop {r1}
		
		
		b read_steps
		s7:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#24 // index[6] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#92
		mov r1,#204
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#24
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip7
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip7:
		pop {r1}
		
		
		b read_steps
		s8:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#28 // index[3] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#160
		mov r1,#204
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#28
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip8
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip8:
		pop {r1}
		
		
		b read_steps
		s9:
		//vefrify if the slot is already used
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#32 // index[3] for the second slot 
		ldr r3,[r2]
		cmp r3,#0
		popne {r2,r3}
		bne read_steps
		pop {r2,r3}
		
		//write in the slot
		push {lr,r0,r1}
		mov r0,#228
		mov r1,#204
		
		cmp r11,#0	
		bleq draw_square_ASM
		blne draw_plus_ASM

		pop {lr,r0,r1}
		
		//modify the board array
		push {r2,r3}
		ldr r2,=board
		add r2,r2,#32
		cmp r11,#0
		moveq r3,#1
		movne r3,#2
		str r3,[r2]
		pop {r2,r3}
		
		//toogle
		cmp r11,#0
		moveq r11,#1
		movne r11,#0
		
		//counter ++
		add r10,r10,#1
		//check win
		push {lr}
		bl check_win
		pop {lr}
		push {r1}
		ldr r1,=win
		ldr r1,[r1]
		cmp r1,#0
		beq skip9
		push {lr,r0}
		cmp r1,#1
		moveq r0,#0
		cmp r1,#2
		moveq r0,#1
		cmp r1,#3
		moveq r0,#2
		bl result_ASM
		pop {lr,r0}
		pop {r1}
		b game_end
		skip9:
		pop {r1}
		
		
		b read_steps

check_win:
//check winner
//str the winner to win label, 1 for player 1, 2 for player 2 and 3 for draw
		push {r1-r9}
		ldr r9,=board
		// first number in the board array
		ldr r1,[r9] 
		// second
		add r9,r9,#4
		ldr r2,[r9]
		//third
		add r9,r9,#4
		ldr r3,[r9]
		//fourth
		add r9,r9,#4
		ldr r4,[r9]
		//fifth
		add r9,r9,#4
		ldr r5,[r9]
		//sixth
		add r9,r9,#4
		ldr r6,[r9]
		//seventh
		add r9,r9,#4
		ldr r7,[r9]
		//eighth
		add r9,r9,#4
		ldr r8,[r9]
		//ninth
		add r9,r9,#4
		ldr r9,[r9]		
		//r1,r2,r3
		//r4,r5,r6
		//r7,r8,r9
	//P1	
		//wining condition if slot 1 is filled
		check_p1_1:
		cmp r1,#1
		beq check_p1_12
		bne check_p1_5		
		check_p1_12:
		cmp r2,#1
		beq check_p1_13
		bne check_p1_14		
		check_p1_13:
		cmp r3,#1
		beq winner
		bne check_p1_14		
		check_p1_14:
		cmp r4,#1
		beq check_p1_17
		bne check_p1_15		
		check_p1_15:
		cmp r5,#1
		beq check_p1_19
		bne check_p1_5	
		check_p1_17:
		cmp r7,#1
		beq winner
		bne check_p1_15	
		check_p1_19:
		cmp r9,#1
		beq winner
		bne check_p1_5
		//wining condition if slot 5 is filled
		check_p1_5:
		cmp r5,#1
		beq check_p1_52
		bne check_p1_9
		check_p1_52:
		cmp r2,#1
		beq check_p1_58
		bne check_p1_54
		check_p1_53:
		cmp r3,#1
		beq check_p1_57
		bne check_p1_9
		check_p1_54:
		cmp r4,#1
		beq check_p1_56
		bne check_p1_53
		check_p1_56:
		cmp r6,#1
		beq winner
		bne check_p1_53
		check_p1_57:
		cmp r7,#1
		beq winner
		bne check_p1_9
		check_p1_58:
		cmp r8,#1
		beq winner
		bne check_p1_54
		//wining condition if slot 9 is filled
		check_p1_9:
		cmp r9,#1
		beq check_p1_96
		bne check_p2_1
		check_p1_93:
		cmp r3,#1
		beq winner
		bne check_p1_98
		check_p1_96:
		cmp r6,#1
		beq check_p1_93
		bne check_p1_98
		check_p1_97:
		cmp r7,#1
		beq winner
		bne check_p2_1
		check_p1_98:
		cmp r8,#1
		beq check_p1_97
		bne check_p2_1
	//P2
		check_p2_1:
		cmp r1,#2
		beq check_p2_12
		bne check_p2_5		
		check_p2_12:
		cmp r2,#2
		beq check_p2_13
		bne check_p2_14		
		check_p2_13:
		cmp r3,#2
		beq winner2
		bne check_p2_14		
		check_p2_14:
		cmp r4,#2
		beq check_p2_17
		bne check_p2_15		
		check_p2_15:
		cmp r5,#2
		beq check_p2_19
		bne check_p2_5	
		check_p2_17:
		cmp r7,#2
		beq winner2
		bne check_p2_15	
		check_p2_19:
		cmp r9,#2
		beq winner2
		bne check_p2_5
		//wining condition if slot 5 is filled
		check_p2_5:
		cmp r5,#2
		beq check_p2_52
		bne check_p2_9
		check_p2_52:
		cmp r2,#2
		beq check_p2_58
		bne check_p2_54
		check_p2_53:
		cmp r3,#2
		beq check_p2_57
		bne check_p2_9
		check_p2_54:
		cmp r4,#2
		beq check_p2_56
		bne check_p2_53
		check_p2_56:
		cmp r6,#2
		beq winner2
		bne check_p2_53
		check_p2_57:
		cmp r7,#2
		beq winner2
		bne check_p2_9
		check_p2_58:
		cmp r8,#2
		beq winner2
		bne check_p2_54
		//wining condition if slot 9 is filled
		check_p2_9:
		cmp r9,#2
		beq check_p2_96
		bne nowinner
		check_p2_93:
		cmp r3,#2
		beq winner2
		bne check_p2_98
		check_p2_96:
		cmp r6,#2
		beq check_p2_93
		bne check_p2_98
		check_p2_97:
		cmp r7,#2
		beq nowinner
		bne draw
		check_p2_98:
		cmp r8,#2
		beq check_p2_97
		bne nowinner
		
		winner:
		push {r8,r9}
		ldr r9,=win
		mov r8,#1
		str r8,[r9]
		pop {r8,r9}
		pop {r1-r9}
		bx lr
		winner2:
		push {r8,r9}
		ldr r9,=win
		mov r8,#2
		str r8,[r9]
		pop {r8,r9}
		pop {r1-r9}
		bx lr
		nowinner:
		push {r8,r9}
		ldr r9,=win
		cmp r10,#9
		moveq r8,#3
		movne r8,#0
		str r8,[r9]
		pop {r8,r9}
		pop {r1-r9}
		bx lr
		
game_end:
		b check

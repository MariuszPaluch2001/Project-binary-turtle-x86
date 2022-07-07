.global exec_turtle_cmd

.data
color_arr:  .byte 0, 0, 0, 255, 0, 0, 0, 128, 0, 0, 0, 255, 255, 255, 0, 0, 255, 255, 128, 0, 128, 255, 255, 255

.text

#----------------------------------------------------------exec_turtle_cmd
# rdi - bitmap pointer
# rsi - command pointer
# rdx - struct pointer
# return politic:
# 0 - o.k
# 1 - set_position beside bitmap border	
exec_turtle_cmd:

	mov  rax, [rsi]
	and  rax, 3
	cmp  rax, 0
	je   set_pen_state_and_color
	cmp  rax, 1
	je   prepare_for_move
	cmp  rax, 2
	je   set_direction
	cmp  rax, 3
	je   set_position
	
	mov  eax, 1
	ret
#----------------------------------------------------------set_position
set_position:
	mov rcx, [rsi]
	shr rcx, 6
	and rcx, 0x3FF
	mov eax, [rdi + 18]	# rdi + 18 bitmap width
	cmp rcx, rax
	jg  set_position_error
	mov [rdx], ecx
	mov rcx, [rsi]
	shr rcx, 26
	and rcx, 0x3F
	mov eax, [rdi + 22]	# rdi + 22 bitmap height
	cmp rcx, rax
	jg  set_position_error
	mov [rdx + 4], ecx
	mov rax, 0
	ret
set_position_error:
	mov rax, 1
	ret
#----------------------------------------------------------get_pen_state
set_pen_state_and_color:
	mov rcx, [rsi]
	shr rcx, 3
	and rcx, 1
	je  down
	mov [rdx + 8], cl
	jmp set_color
down:
	mov [rdx + 8], cl
set_color:
	mov rax, [rsi]
	shr rax, 13
	and rax, 7
	imul rax, 3
	mov cl, [color_arr + rax]
	mov [rdx + 12], cl
	add rax, 1
	mov cl, [color_arr + rax]
	mov [rdx + 13], cl
	add rax, 1
	mov cl, [color_arr + rax]
	mov [rdx + 14], cl
	mov rax, 0
	ret
	
	
#----------------------------------------------------------get_direction
set_direction:
	mov rax, [rsi]
	shr rax, 2
	and rax, 3
	mov [rdx + 10], ax
	mov rax, 0
	ret

#----------------------------------------------------------turtle_move
prepare_for_move:
	mov  eax, [rsi]	#rax length of move
	shr  eax, 2
	and  eax, 0x3FF
	mov  cl, [rdx + 10]
	cmp  cl, 0
	je   test_right
	cmp  cl, 1
	je   test_up
	cmp  cl, 2
	je   test_left
	cmp  cl, 3
	je   test_down
	jmp  turtle_move
test_right:
	mov  ecx, [rdx]      # rcx x positon
	mov  ebx, [rdi + 18] # width of bitmap
	add  ecx, eax        # ecx store future position
	sub  ebx, ecx        # check how future position is wider than max
	cmp  ebx, 0	      
	jg   turtle_move
	add  eax, ebx
	dec  eax
	mov  rsi, 2
	jmp  turtle_move
test_up:
	mov  ecx, [rdx + 4]  # rcx y positon
	mov  ebx, [rdi + 22] # height of bitmap
	add  ecx, eax
	sub  ebx, ecx
	cmp  ebx, 1
	jg   turtle_move
	add  eax, ebx
	dec  eax
	mov  rsi, 2
	jmp  turtle_move
test_left:
	mov  ecx, [rdx]      # rcx x positon
	sub  ecx, eax
	
	cmp  ecx, 0
	jg   turtle_move
	add  eax, ecx

	mov  rsi, 2
	jmp  turtle_move
test_down:
	mov  ecx, [rdx + 4]  # rcx y positon
	sub  ecx, eax
	cmp  ecx, 0
	jg   turtle_move
	add  eax, ecx
	mov  rsi, 2
turtle_move:
	mov  ebx, eax
test4:
	mov  eax, [rdx]      #get x position
	mov  r8d, 3          #get x pixels per line
	mov  r10, rdx
	mul  r8d
	mov  r8d, eax
	mov  rdx, r10
	mov  eax, [rdx + 4]  #get y position
	mov  r9d, [rdi + 38] #get y pixels per line
	mov  r10, rdx
	mul  r9d
	mov  r9d, eax
	mov  rdx, r10
	
	mov  rcx, 62
	add  rcx, rdi
	add  rcx, r8
	add  rcx, r9
	
	xor  r8, r8
	
	mov  ax, [rdx + 10]
	cmp  ax, 0
	je   move_right
	cmp  ax, 1
	je   move_up
	cmp  ax, 2
	je   move_left
	cmp  ax, 3
	je   move_down
back_from_move:
	cmp  rsi, 2
	je   move_too_long_err
	mov  rax, 0
	ret
move_too_long_err:
	mov  rax, rsi
	ret
	
	
move_right:
	mov eax, [rdx]
	add eax, ebx
	mov [rdx], eax
	
	mov r8, 3
	mov ax,  [rdx + 8]
	cmp ax,  1
	je  move_loop
	jmp back_from_move
move_up:
	mov eax, [rdx + 4]
	add eax, ebx
	mov [rdx + 4], eax
	
	xor r8, r8
	mov r8d, [rdi + 38]
	
	mov ax,  [rdx + 8]
	cmp ax,  1
	je  move_loop
	jmp back_from_move
move_left:
	mov eax, [rdx]
	sub eax, ebx
	mov [rdx], eax
	
	mov r8, -3
	
	mov ax,  [rdx + 8]
	cmp ax,  1
	je  move_loop
	jmp back_from_move
move_down:
	mov eax, [rdx + 4]
	sub eax, ebx
	mov [rdx + 4], eax
	
	xor r8, r8
	mov r8d, [rdi + 38]
	neg r8
	
	mov ax,  [rdx + 8]
	cmp ax,  1
	je  move_loop
	jmp back_from_move
move_loop:
	mov al, [rdx + 14] 
	mov [rcx], al
	mov al,  [rdx + 13] 
	mov [rcx + 1], al
	mov al,  [rdx + 12]
	mov [rcx + 2], al
	add rcx, r8 
	dec rbx
	cmp rbx, 0
	jg  move_loop
	jmp back_from_move

#---------------------------------------------------

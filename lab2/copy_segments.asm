img_pImg		EQU	12

section	.text
global  _assembler_copy_segments

_assembler_copy_segments:
	push ebp
	mov	ebp, esp
	push ebx
	push edi
	push esi
	
	sub esp, 24				; make space for 2 variables for the order_array and 4 loop variables
	
	; create a double nested loop, outer loop is for row number, inner for column number
	mov eax, 1
	mov [esp + 8], eax		; [esp + 8] - outerMainLoop variable

outerMainLoop:

	mov eax, 4
    cmp [esp + 8], eax
    je done
	mov eax, 1
    mov [esp + 12], eax		; [esp + 12] - innerMainLoop variable

innerMainLoop:

	; ------------------- INPUT BMP FILE POINTER ----------------------
	; make esi point to source.bmp coordinate (0, 0), that is the lower left corner 
	mov	eax, [ebp + 8]		; eax - address of the first imgInfo struct
	mov esi, [eax + img_pImg]

	; calculate necessary offset to get correct data from order_array
	mov ecx, [esp + 8]		; offset by 32 in the order_array for each row
	dec ecx
	shl ecx, 5				; multiply by 32

	mov edx, [esp + 12]		; offset by 8 in the order_array for each column
	dec edx
	shl edx, 3				; multiply by 8

	add ecx, edx
	mov ebx, ecx			; now ebx is equal to the total offset needed

	mov eax, [ebp + 16]		; eax - address of order_array
	add eax, ebx			; offset eax by abx
	mov ebx, [eax + 0]
	mov [esp + 0], ebx		; [esp + 0] - the row number from the array
	mov ebx, [eax + 4]
	mov [esp + 4], ebx		; [esp + 4] - the column number from the array

	; move the input file pointer
	; move by (3-[esp + 0])*76800 bytes - by 76800 for each row segment
	mov eax, 3
	mov ebx, [esp + 0]
	sub eax, ebx			; now eax = 3-[esp + 0], let's multiply it by 76800
	mov ebx, 76800
	imul eax, ebx
	add esi, eax			; move the source.bmp pointer

	; move by ([esp + 4]-1)*240 bytes - by 240 for each column segment
	mov eax, [esp + 4]
	mov ebx, 1
	sub eax, ebx			; now eax = [esp + 4]-1, let's multiply it by 240
	mov ebx, 240
	imul eax, ebx
	add esi, eax			; move the source.bmp pointer again

	; ------------------- OUTPUT BMP FILE POINTER ---------------------
	; make edi point to dest.bmp coordinate (0, 0)
	mov	eax, [ebp + 12]		; eax - address of the second imgInfo struct
	mov edi, [eax + img_pImg]

	; move the output file pointer
	; move by (3-[esp + 8])*76800 bytes - by 76800 for each row segment
	mov eax, 3
	mov ebx, [esp + 8]
	sub eax, ebx			; now eax = 3-[esp + 8], let's multiply it by 76800
	mov ebx, 76800
	imul eax, ebx
	add edi, eax			; move the dest.bmp pointer

	; move by ([esp + 12]-1)*240 bytes - by 240 for each column segment
	mov eax, [esp + 12]
	mov ebx, 1
	sub eax, ebx			; now eax = [esp + 12]-1, let's multiply it by 240
	mov ebx, 240
	imul eax, ebx
	add edi, eax			; move the dest.bmp pointer again

	; create another double nested loop, outer loop for the 80 pixels height of the segments, inner loop for the 60 words width of the segments
	; ----------------------- INNER LOOP -----------------------

	mov eax, 0
	mov [esp + 16], eax		; [esp + 16] - outerLoop variable

outerLoop:

	mov eax, 80
    cmp [esp + 16], eax
    je innerdone
	mov eax, 0
    mov [esp + 20], eax		; [esp + 20] - innerLoop variable

innerLoop:

	mov eax, [esi]			
	mov [edi], eax			; copy word from source.bmp to dest.bmp

	mov eax, 4
	add esi, eax
	add edi, eax			; increment pointers so that they point to the next word

	mov eax, 59				
    cmp [esp + 20], eax
    je innerLoopDone	
	mov eax, 1
    add [esp + 20], eax
    jmp innerLoop

innerLoopDone:

	mov eax, 720			
	add esi, eax
	add edi, eax			; rows are 960 bytes in width total, so to move to the next one after moving 240 bytes we need to jump by the 720 bytes left

	mov eax, 1
    add [esp + 16], eax
    jmp outerLoop

innerdone:

	mov eax, 4
    cmp [esp + 12], eax
    je innerMainLoopDone
	mov eax, 1
    add [esp + 12], eax
    jmp innerMainLoop

innerMainLoopDone:

	mov eax, 1
    add [esp + 8], eax
    jmp outerMainLoop

done:

	pop esi
	pop edi
	pop ebx
	mov esp, ebp			; restore stack pointer
	pop	ebp					; restore ebp
	ret						; return
# Kamil Borkowski
# Student number: 300166
# ECOAR 2021 Summer Semester
# Laboratory 1
# Task: Puzzle 2

# Patch 1.1
# Changelog:
# - readBmp and writeBmp now slightly more universal
# - optimized multiplication by a power of 2 (now using sll)

.eqv	bmpFileSize 230454
.eqv	bytesPerRow 960
.eqv	bytesPerColumnSegment 240
.eqv 	bytesPerRowSegment 76800
.eqv	bytesJumpNextRow 720

.data	
		
	array:		.space	96	# reserve space for array of numbers by which to order the segments in dest.bmp
	checkArray:	.word 	1,1,1,2,1,3,1,4,2,1,2,2,2,3,2,4,3,1,3,2,3,3,3,4	# reserve space for array used in checking the input string
	userInput: 	.space 	25	# reserve space for initial user input
	.align 	4
	res1: 	.space 	2
	inputImage:	.space 	bmpFileSize	# reserve space for input file data
	.align 	4
	res2: 	.space 	2
	outputImage:	.space 	bmpFileSize  	# reserve space for output file data
	inputImageName: .asciiz "source.bmp"
	outputImageName:.asciiz "dest.bmp"
	inputMessage: 	.asciiz "Please input the desired order in the format 'number1number2number3...'. NO SPACES!!!\nFor instance 111213142122232431323334.\nAll numbers need to be used\n"
	inputTab:	.asciiz "\n"
	inputFileErrorMessage:	.asciiz "Encountered a problem while trying to open the input file. Exiting the program"
	outputFileErrorMessage:	.asciiz "Encountered a problem while trying to open the output file. Exiting the program"
	checkErrorMessage:	.asciiz "checkString error: Incorrect input string"
	
.text

######## Initial file handling ###############
	
	# handle source.bmp and dest.bmp reading into memory
	la $a0, inputImageName
	la $a1, outputImageName
	move $t8, $a1
	jal readBmp

######## User input section ##################

	# print 'give input' message
	li $v0, 4
	la $a0, inputMessage
	syscall
	
	# get user input
	li $v0, 8
	la $a0, userInput
	li $a1, 25
	syscall
	
	# print newline
	li $v0, 4
	la $a0, inputTab
	syscall
	
	# loop over string and put data into array
	li $s4, 24
	li $s5, 0
	addi $t0, $zero, 0		# array index
	addi $t1, $zero, 0		# string index
	
arrayLoop:
	
	lb $t2, userInput($t1)		# load character bit
	subi $t2, $t2, 48		# subtract 0
	sb $t2, array($t0)		# put into array
	addi $t0, $t0, 4		# move array index
	addi $t1, $t1, 1		# move string index
	addi $s5, $s5, 1		
	blt $s5, $s4, arrayLoop
	
	# check for errors in the array
	jal checkString
	
######## Copying the segment data from inputImage into outputImage with accordance to the user input ########
	
	# set up a nested loop (upper loop 3 (row), lower 4 (column))
	li $s4, 2
	li $s5, 4
	li $s6, 0			# set first loop changing variable to 0
	li $s7, 1			# set second loop changing variable to 1
	
segmentLoop1:

	blt $s4, $s6, segmentLoopFin
	addi $s6, $s6, 1
	li $s7, 1
	j segmentLoop2

segmentLoop2:

	blt $s5, $s7, segmentLoop1
	
	# load to $a0 and $a1 from array. row first, column second
	addi $t0, $zero, 0	
	subi $t1, $s6, 1
	sll $t1, $t1, 5			# calculate offset due to row number		
	add $t0, $t0, $t1		# offset $t0
	subi $t1, $s7, 1
	sll $t1, $t1, 3			# calculate offset due to column number
	add $t0, $t0, $t1		# offset $t0
	
	lw $t2, array($t0)		# get row number
	move $a0, $t2
	addi $t0, $t0, 4
	lw $t2, array($t0)		# now column number
	move $a1, $t2
	
	# load to $a2 and $a3 from loop
	move $a2, $s6
	move $a3, $s7

	jal copySegment
	addi $s7, $s7, 1
	j segmentLoop2

segmentLoopFin:

######## Output file handling ##############
		
	# handle dest.bmp
	move $a0, $t8
	jal writeBmp

exit:

	# exit
	li $v0, 10
	syscall
	
readBmp:

	# $a0 - name of source file
	# $a1 - name of destination file
	move $t1, $a1		# save destintation file name for second half of function

	sub $sp, $sp, 4
	sw $s1, 0($sp)
	
	# input file
	# open file
	li $v0, 13
	# file name already in $a0
	li $a1, 0		# flags: read file
	li $a2, 0		# mode: ignored
	syscall
	
	# save file descriptor
	move $s1, $v0	
	
	# check if the file was opened correctly
	bltz $v0, inputFileError
	
	# read file
	li $v0, 14
	move $a0, $s1
	la $a1, inputImage
	li $a2, bmpFileSize
	syscall
	
	# close file
	li $v0, 16
	move $a0, $s1
	syscall
	
	# output file
	# open file
	li $v0, 13
	move $a0, $t1		# file name
	li $a1, 0		# flags: read file
	li $a2, 0		# mode: ignored
	syscall
	
	# save file descriptor
	move $s1, $v0
	
	# check if the file was opened correctly
	bltz $v0, outputFileError
	
	# read file
	li $v0, 14
	move $a0, $s1
	la $a1, outputImage
	li $a2, bmpFileSize
	syscall
	
	# close file
	li $v0, 16
	move $a0, $s1
	syscall
	
	lw $s1, 0($sp)
	add $sp, $sp, 4
	
	jr $ra
	
writeBmp:

	# $a0 - name of destination file
	sub $sp, $sp, 4		# push $s1
	sw $s1, 0($sp)
	
	# open file
	li $v0, 13
	# file name already in $a0
	li $a1, 1		# flags: write file
	li $a2, 0		# mode: ignored
	syscall
	
	# save file descriptor
	move $s1, $v0
	
	# check if the file was opened correctly
	bltz $v0, outputFileError
	
	# save file
	li $v0, 15
	move $a0, $s1
	la $a1, outputImage
	li $a2, bmpFileSize
	syscall
	
	# close file
	li $v0, 16
	move $a0, $s1
	syscall
	
	lw $s1, 0($sp)
	add $sp, $sp, 4
	
	jr $ra

inputFileError:

	# print error message
	li $v0, 4
	la $a0, inputFileErrorMessage
	syscall
	j exit

outputFileError:

	# print error message
	li $v0, 4
	la $a0, outputFileErrorMessage
	syscall
	j exit

checkString:

	# This part (from here till if2True included) is a bit convoluted, but it works.
	# Firstly there is a check if any data in the array derived from user input is zero. This doesn't do much
	# by itself, but it compliments the next part.
	# Then we iterate over checkArray in search of a pair of numbers that are the same as those in the array from user input.
	# If we don't find it it means that the number pair was not a valid one (as checkArray contains all valid number pairs).
	# If we find it we change that pair in checkArray into 00 and go to the next pair from user input. That way we won't count duplicates
	# as once a number is used, it cannot be found again. That is also why at the beggining we check for the occurence of zeroes, because if we didn't
	# an input string of 110000000000000000000000 would be accepted, which is of course wrong.
			
	# set up nested loop
	li $s4, 12
	addi $s4, $s4, -1
	li $s5, 12
	addi $s5, $s5, -1
	li $s6, 0
	li $s7, 0
	
	addi $t0, $zero, 0	# input array row index
	addi $t1, $zero, 4	# input array column index
	
checkLoop1:
	
	blt $s4, $s6, checkLoopFin
	addi $s6, $s6, 1
	li $s7, 0
	
	# check if either row number or column number are equal to 0
	lw $t4, array($t0)
	beqz $t4, checkError
	lw $t4, array($t1)
	beqz $t4, checkError	
	
	addi $t2, $zero, 0	# check array row index
	addi $t3, $zero, 4	# check array column index

checkLoop2:

	blt $s5, $s7, checkError
	
	lw $t4, array($t0)	
	lw $t5, array($t1)	
	lw $t6, checkArray($t2)	
	lw $t7, checkArray($t3)	
	
	beq $t4, $t6, if1True

checkCont:
	
	addi $t2, $t2, 8
	addi $t3, $t3, 8
	addi $s7, $s7, 1
	j checkLoop2

checkLoopFin:
		
	jr $ra

if1True:

	beq $t5, $t7, if2True
	j checkCont
	
if2True:

	li $t6, 0
	li $t7, 0
	sw $t6, checkArray($t2)
	sw $t7, checkArray($t3)
	addi $t0, $t0, 8
	addi $t1, $t1, 8
	j checkLoop1
	
checkError:

	# print error message
	li $v0, 4
	la $a0, checkErrorMessage
	syscall
	j exit

copySegment:

	# $a0 - row number input
	# $a1 - column number input
	# $a2 - row number output
	# $a3 - column number output

# one register - get address of segment start point in input file
	la $t1, inputImage + 10 # address of file offset to pixel array
	lw $t2, ($t1)		# file offset to pixel array in $t2
	la $t1, inputImage	# address of bitmab
	add $t2, $t1, $t2	# address of pixel array in $t2
	# pixel address calculation
	# calculate 3 - $a0
	li $t0, 3
	sub $t1, $t0, $a0
	# move $t2 by $t0*bytesPerRowSegment
	mul $t0, $t1, bytesPerRowSegment
	add $t2, $t2, $t0
	# calculate $a1 - 1
	li $t0, 1
	sub $t1, $a1, $t0
	# move $t2 by $t0*bytesPerColumnSegment
	mul $t0, $t1, bytesPerColumnSegment
	add $t2, $t2, $t0	
	
# second register - get address of segment start point in output file
	la $t1, outputImage + 10 # address of file offset to pixel array
	lw $t3, ($t1)		# file offset to pixel array in $t2
	la $t1, outputImage	# address of bitmab
	add $t3, $t1, $t3	# address of pixel array in $t2
	# pixel address calculation
	# calculate 3 - $a2
	li $t0, 3
	sub $t1, $t0, $a2
	# move $t3 by $t0*bytesPerRowSegment
	mul $t0, $t1, bytesPerRowSegment
	add $t3, $t3, $t0
	# calculate $a3 - 1
	li $t0, 1
	sub $t1, $a3, $t0
	# move $t3 by $t0*bytesPerColumnSegment
	mul $t0, $t1, bytesPerColumnSegment
	add $t3, $t3, $t0
	
	# set up nested foor loop (upper one loops 80 times (rows per segment), lower one 60 (words per row in segment))
	li $s0, 80
	addi $s0, $s0, -1
	li $s1, 60
	addi $s1, $s1, -1
	li $s2, 0			# set first loop changing variable to 0
	li $s3, 0			# set second loop changing variable to 0
	
copyLoop1:

	blt $s0, $s2, copyLoopFin
	addi $s2, $s2, 1
	li $s3, 0
	j copyLoop2

copyLoop2:

	blt $s1, $s3, copyLoop2after
	lw $t0, 0($t2)			# load word value from input file
	sw $t0, 0($t3)			# save word value to output file
	addiu $t2, $t2, 4		# jump $t2 into next word
	addiu $t3, $t3, 4		# jump $t3 into next word
	addi $s3, $s3, 1
	j copyLoop2

copyLoop2after:

	add $t2, $t2, bytesJumpNextRow	# jump $t2 into next row
	add $t3, $t3, bytesJumpNextRow	# jump $t3 into next row
	j copyLoop1

copyLoopFin:

	jr $ra

CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o copy_segments.o -f elf -g -l copy_segments.lst copy_segments.asm
cc :
	$(CC) -m32 -c -g -O0 puzzle2.c
link :
	$(CC) -m32 -g -o puzzle2_test puzzle2.o copy_segments.o
clean :
	del *.o
	del puzzle2_test.exe
	del copy_segments.lst

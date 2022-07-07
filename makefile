CC=g++
ASMBIN=as
all : asm cc link
asm : 
	$(ASMBIN) -msyntax=intel -mnaked-reg -o binary_turtle.o -g binary_turtle.asm
cc :
	$(CC) -no-pie -c -g -O0 main.c
link :
	$(CC) -no-pie -o exe binary_turtle.o  main.o 
clean :
	rm *.o
	rm exe

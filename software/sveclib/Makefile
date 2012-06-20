OBJS=sveclib.o libvmebus.o 

CFLAGS=-I. -Wall
CC=gcc

all:	cl fwloader vuart

cl:	svec-cl.o $(OBJS)
	gcc -o svec-cl $(OBJS) svec-cl.o

fwloader:	svec-fwloader.o $(OBJS)
	gcc -o svec-fwloader $(OBJS) svec-fwloader.o		

vuart:	svec-vuart.o $(OBJS)
	gcc -o svec-vuart $(OBJS) svec-vuart.o		
	
clean:
	rm -f *.o svec-cl svec-test svec-fwloader svec-vuart
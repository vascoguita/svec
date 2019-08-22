CC = gcc
CFLAGS = -I.
OBJS = libvmebus.o svec-flasher.o

all:	$(OBJS)
	${CC} -o svec-flasher $(OBJS)

clean:
	rm -f $(OBJS) svec-flasher
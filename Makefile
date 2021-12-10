CC=z80-elf-as
LD=z80-elf-ld

SRCS=hello.asm pause.asm boot.asm
OBJS=$(subst .asm,.o,$(SRCS))

%.o : %.asm
	$(CC)  $< -o $@

hello.sms : $(OBJS)
	$(LD) -T master-system.linker $(OBJS) -o $@

all: hello.sms

clean:
	rm -rf $(OBJS)

distclean: clean
	rm -rf *.sms
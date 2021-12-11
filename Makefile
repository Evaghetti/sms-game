CC=z80-elf-as
LD=z80-elf-ld
OC=z80-elf-objcopy

SRCS=hello.asm pause.asm boot.asm
OBJS=$(subst .asm,.o,$(SRCS))

%.o : %.asm
	$(CC)  $< -o $@

hello.sms : $(OBJS)
	$(LD) $(OBJS) -T master-system.linker -o $(subst .sms,.elf,$@)
	$(OC) -O binary $(subst .sms,.elf,$@) $@

all: hello.sms

clean:
	rm -rf $(OBJS)

distclean: clean
	rm -rf *.sms
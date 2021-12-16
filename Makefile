CC=z80-elf-as
LD=z80-elf-ld
OC=z80-elf-objcopy
NM=z80-elf-nm
AWK=awk

CCFLAGS=-g

SRCS=main.asm pause.asm boot.asm vblank.asm player.asm
OBJS=$(subst .asm,.o,$(SRCS))

%.o : %.asm
	$(CC) $(CCFLAGS) $< -o $@

main.sms : $(OBJS)
	$(LD) $(OBJS) -T master-system.linker -o $(subst .sms,.elf,$@)
	$(OC) -O binary $(subst .sms,.elf,$@) $@
	$(NM) $(subst .sms,.elf,$@) > temp.sym
	$(AWK) -F' ' '{ print $$1,$$3 }' temp.sym > $@.sym
	rm temp.sym

all: main.sms

clean:
	rm -rf $(OBJS) *.sym *.elf

distclean: clean
	rm -rf *.sms
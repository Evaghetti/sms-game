CC=z80-elf-as
LD=z80-elf-ld
OC=z80-elf-objcopy
NM=z80-elf-nm
PY=python3

CCFLAGS=-g

SRCS=main.asm pause.asm boot.asm vblank.asm player.asm
OBJS=$(subst .asm,.o,$(SRCS))

%.o : %.asm
	$(CC) $(CCFLAGS) $< -o $@

main.sms : $(OBJS)
	$(LD) main.o -T master-system.linker -o $(subst .sms,.elf,$@)
	$(OC) -O binary $(subst .sms,.elf,$@) $@
	$(NM) $(subst .sms,.elf,$@) > $(subst .sms,.sym,$@)
	$(PY) fix-checksum.py $@

all: main.sms

clean:
	rm -rf $(OBJS) *.sym *.elf

distclean: clean
	rm -rf *.sms

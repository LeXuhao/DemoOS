# Common part for the Makefile.
# This file will be included by the Makefile of each project.

# Custom Macro Definition (Common part)



DEFS +=

CROSS_COMPILE = riscv64-unknown-elf-
CFLAGS += -nostdlib -fno-builtin -g -Wall
CFLAGS += -march=rv32g -mabi=ilp32
LDFLAGS ?= -T os.ld

QEMU = qemu-system-riscv32
QFLAGS = -nographic -smp 1 -machine virt -bios none

GDB = gdb-multiarch
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump
MKDIR = mkdir -p
RM = rm -rf

OUTPUT_PATH = out

# 指定链接器（ld）将代码段（text section）放置在内存中的特定地址
# 0x80000000为riscv内存的起始地址
# LDFLAGS = -Ttext=0x80000000

SRCS_ASM = \
	start.S \
	mem.S \

SRCS_C = \
	kernel.c \
	uart.c \
	page.c \
	printf.c \

# SRCS_ASM & SRCS_C are defined in the Makefile of each project.
OBJS_ASM := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.S, %.o, ${SRCS_ASM}))
OBJS_C   := $(addprefix $(OUTPUT_PATH)/, $(patsubst %.c, %.o, ${SRCS_C}))
OBJS = ${OBJS_ASM} ${OBJS_C}

ELF = ${OUTPUT_PATH}/os.elf
BIN = ${OUTPUT_PATH}/os.bin

.DEFAULT_GOAL := all
all: ${OUTPUT_PATH} ${ELF}

${OUTPUT_PATH}:
	@${MKDIR} $@

# start.o must be the first in dependency!
${ELF}: ${OBJS}
#gcc编译成os.elf文件
	${CC} ${CFLAGS} ${LDFLAGS} -o ${ELF} $^
# 将ELF(os.elf)文件转换为二进制文件BIN（os.bin）
	${OBJCOPY} -O binary ${ELF} ${BIN} 


${OUTPUT_PATH}/%.o : %.c
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

${OUTPUT_PATH}/%.o : %.S
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

run: all
	@${QEMU} -M ? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
# -kernel指定要加载和执行的内核镜像文件，即指定ELF跳到0x80000000运行
	@${QEMU} ${QFLAGS} -kernel ${ELF}

.PHONY : debug
debug: all
	@echo "Press Ctrl-C and then input 'quit' to exit GDB and QEMU"
	@echo "-------------------------------------------------------"
# -s启动GDB服务器，默认端口1234. 
# -S在QEMU启动时暂停虚拟机的执行，直到接收到GDB连接并收到继续执行的命令
# &让QEMU在后台运行（shell 命令）
	@${QEMU} ${QFLAGS} -kernel ${ELF} -s -S &
	@${GDB} ${ELF} -q -x gdbinit

.PHONY : code
code: all
	@${OBJDUMP} -S ${ELF} | less

.PHONY : clean
clean:
	@${RM} ${OUTPUT_PATH}


# riscv64-unknown-elf-gcc  -nostdlib -fno-builtin -g -Wall -march=rv32g -mabi=ilp32 -c -o out/start.o start.S
# riscv64-unknown-elf-gcc  -nostdlib -fno-builtin -g -Wall -march=rv32g -mabi=ilp32 -c -o out/kernel.o kernel.c
# riscv64-unknown-elf-gcc  -nostdlib -fno-builtin -g -Wall -march=rv32g -mabi=ilp32 -c -o out/uart.o uart.c
# riscv64-unknown-elf-gcc -nostdlib -fno-builtin -g -Wall -march=rv32g -mabi=ilp32 -Ttext=0x80000000 -o out/os.elf out/start.o out/kernel.o out/uart.o
# riscv64-unknown-elf-objcopy -O binary out/os.elf out/os.bin

all: run
kernel: kernel.bin
kernel.bin: main.asm
	nasm -f bin -o kernel.bin main.asm
run: kernel
	kvm-spice kernel.bin
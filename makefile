.PHONY: all clean size

all: crackme

crackme: src/midnight.asm build
	nasm -f bin -o build/midnight src/midnight.asm
	chmod +x build/midnight

build:
	mkdir build

size: build/midnight
	@stat -c%s build/midnight

help:
	@echo "Commandes disponibles:"
	@echo "  make          - Compiler le crackme"
	@echo "  make size     - Afficher la taille"
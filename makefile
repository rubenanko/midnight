.PHONY: all clean size

all: crackme

crackme: midnight.asm build
	nasm -f bin -o build/midnight midnight.asm
	chmod +x build/midnight

build:
	mkdir build

size: midnight
	@stat -c%s midnight

help:
	@echo "Commandes disponibles:"
	@echo "  make          - Compiler le crackme"
	@echo "  make size     - Afficher la taille"
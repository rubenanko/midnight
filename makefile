# Makefile pour Crackme Midnight
# Usage: make, make clean, make size, make test

# Chemins
SRC_PATH := src
BUILD_PATH := build
OBJ_PATH := obj
TARGET_NAME := midnight
TARGET := $(BUILD_PATH)/$(TARGET_NAME)
CIPHER_ELF := $(BUILD_PATH)/cipher

# Couleurs pour l'affichage
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Cibles phony (ne correspondent pas à des fichiers)
.PHONY: all clean size test help bonus docker cipher

# Cible par défaut
all: $(TARGET)
	@echo "$(GREEN)✓ Build réussi$(NC)"
	@$(MAKE) size

# Créer les dossiers build et obj s'ils n'existent pas
$(BUILD_PATH) $(OBJ_PATH):
	@mkdir -p $@
	@echo "$(YELLOW)→ Création du dossier $@$(NC)"

# Compiler le crackme
$(TARGET): $(SRC_PATH)/midnight.asm | $(BUILD_PATH)
	@echo "$(YELLOW)→ Compilation de $(TARGET_NAME)...$(NC)"
	nasm -f bin -o $(TARGET) $(SRC_PATH)/midnight.asm
	chmod +x $(TARGET)
	@echo "$(GREEN)✓ Compilation terminée$(NC)"

# Compiler cipher.nasm en standalone (pour debug avec gdb)
cipher: $(CIPHER_ELF)
	@echo "$(GREEN)✓ cipher.elf compilé avec succès$(NC)"
	@echo "$(YELLOW)→ Debug avec: gdb $(CIPHER_ELF)$(NC)"

$(CIPHER_ELF): $(SRC_PATH)/cipher.nasm | $(BUILD_PATH) $(OBJ_PATH)
	@echo "$(YELLOW)→ Compilation de cipher.nasm en ELF...$(NC)"
	nasm -felf64 -g -F dwarf $(SRC_PATH)/cipher.nasm -o $(OBJ_PATH)/cipher.o
	ld -o $(CIPHER_ELF) $(OBJ_PATH)/cipher.o
	@echo "$(GREEN)✓ ELF créé: $(CIPHER_ELF)$(NC)"

# Afficher la taille avec calcul de bonus
size: $(TARGET)
	@echo ""
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@SIZE=$$(stat -c%s $(TARGET) 2>/dev/null || stat -f%z $(TARGET)); \
	echo "$(GREEN)📦 Taille du binaire: $$SIZE octets$(NC)"; \
	echo "$(YELLOW)───────────────────────────────────────$(NC)"; \
	if [ $$SIZE -gt 8192 ]; then \
		echo "$(RED)❌ DISQUALIFIÉ: Taille > 8 KiB$(NC)"; \
	elif [ $$SIZE -le 1024 ]; then \
		echo "$(GREEN)🏆 BONUS: +2.0000 pts (≤ 1 KiB) - Max 8 args$(NC)"; \
	elif [ $$SIZE -le 2048 ]; then \
		echo "$(GREEN)🏆 BONUS: +1.3333 pts (≤ 2 KiB) - Max 4 args$(NC)"; \
	elif [ $$SIZE -le 4096 ]; then \
		echo "$(GREEN)🏆 BONUS: +0.6666 pts (≤ 4 KiB) - Max 2 args$(NC)"; \
	elif [ $$SIZE -le 8192 ]; then \
		echo "$(GREEN)✓ Conforme: ≤ 8 KiB - Max 1 arg$(NC)"; \
	fi; \
	echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Tests automatiques
test: $(TARGET)
	@echo ""
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo "$(YELLOW)🧪 Tests du crackme$(NC)"
	@echo "$(YELLOW)───────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Test 1: Sans argument$(NC)"
	@if ./$(TARGET) 2>/dev/null; then \
		echo "$(RED)❌ FAIL: Ne devrait pas accepter sans arg$(NC)"; \
	else \
		echo "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Test 2: Argument trop long (17+ octets)$(NC)"
	@if ./$(TARGET) "12345678901234567" 2>/dev/null | grep -q "OK"; then \
		echo "$(RED)❌ FAIL: Ne devrait pas accepter > 16 octets$(NC)"; \
	else \
		echo "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Test 3: Mauvais mot de passe (16 octets)$(NC)"
	@if ./$(TARGET) "WrongPassword!!!" 2>/dev/null | grep -q "OK"; then \
		echo "$(RED)❌ FAIL: Accepte un mauvais mdp$(NC)"; \
	else \
		echo "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Test 4: BON mot de passe$(NC)"
	@echo "$(RED)⚠ À TESTER MANUELLEMENT avec votre mot de passe$(NC)"
	@echo "  Exemple: ./$(TARGET) \"VotreMotDePasse!\""
	@echo "  Devrait afficher: OK"
	@echo ""
	@echo "$(YELLOW)Test 5: Vérification du retour$(NC)"
	@if ./$(TARGET) "WrongPassword!!!" >/dev/null 2>&1; then \
		echo "$(RED)❌ FAIL: Code retour devrait être non-zéro$(NC)"; \
	else \
		echo "$(GREEN)✓ PASS: Code retour correct$(NC)"; \
	fi
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Calcul du bonus potentiel
bonus: $(TARGET)
	@echo ""
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo "$(YELLOW)💰 Calcul des bonus potentiels$(NC)"
	@echo "$(YELLOW)───────────────────────────────────────$(NC)"
	@SIZE=$$(stat -c%s $(TARGET) 2>/dev/null || stat -f%z $(TARGET)); \
	echo "Taille actuelle: $$SIZE octets"; \
	echo ""; \
	echo "Objectifs pour bonus:"; \
	REDUCTION=$$(($$SIZE - 4096)); \
	if [ $$REDUCTION -gt 0 ]; then \
		echo "  → Réduire de $$REDUCTION octets pour +0.6666 pts (4 KiB)"; \
	fi; \
	REDUCTION=$$(($$SIZE - 2048)); \
	if [ $$REDUCTION -gt 0 ]; then \
		echo "  → Réduire de $$REDUCTION octets pour +1.3333 pts (2 KiB)"; \
	fi; \
	REDUCTION=$$(($$SIZE - 1024)); \
	if [ $$REDUCTION -gt 0 ]; then \
		echo "  → Réduire de $$REDUCTION octets pour +2.0000 pts (1 KiB)"; \
	fi
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Nettoyage
clean:
	@echo "$(YELLOW)→ Nettoyage...$(NC)"
	rm -rf $(BUILD_PATH) $(OBJ_PATH)
	rm -f $(SRC_PATH)/*.o $(SRC_PATH)/*.elf
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

# Analyse avec objdump (si pas ELF pur)
dump: $(TARGET)
	@echo "$(YELLOW)→ Désassemblage (si possible)...$(NC)"
	@if file $(TARGET) | grep -q "ELF"; then \
		objdump -D -b binary -m i386:x86-64 $(TARGET) | less; \
	else \
		ndisasm -b64 $(TARGET) | less; \
	fi

# Analyse avec hexdump
hex: $(TARGET)
	@echo "$(YELLOW)→ Dump hexadécimal...$(NC)"
	hexdump -C $(TARGET) | less

# Vérifier les dépendances
check-deps:
	@echo "$(YELLOW)→ Vérification des dépendances...$(NC)"
	@command -v nasm >/dev/null 2>&1 || { echo "$(RED)❌ nasm non installé$(NC)"; exit 1; }
	@command -v stat >/dev/null 2>&1 || { echo "$(RED)❌ stat non installé$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Toutes les dépendances sont présentes$(NC)"

# Préparer le rendu
package: clean all test
	@echo ""
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo "$(YELLOW)📦 Préparation du package de rendu$(NC)"
	@echo "$(YELLOW)───────────────────────────────────────$(NC)"
	@mkdir -p rendu/src
	@cp $(TARGET) rendu/midnight
	@cp $(SRC_PATH)/midnight.asm rendu/src/
	@echo '#!/bin/bash' > rendu/BUILD.sh
	@echo 'nasm -f bin -o midnight src/midnight.asm' >> rendu/BUILD.sh
	@echo 'chmod +x midnight' >> rendu/BUILD.sh
	@echo 'echo "Build réussi: $$(ls -lh midnight | awk '"'"'{print $$5}'"'"')"' >> rendu/BUILD.sh
	@chmod +x rendu/BUILD.sh
	@echo "$(GREEN)✓ Fichiers copiés dans ./rendu/$(NC)"
	@echo ""
	@echo "Contenu du package:"
	@ls -lh rendu/
	@echo ""
	@echo "$(YELLOW)N'oubliez pas d'ajouter DOCUMENTATION.pdf !$(NC)"
	@echo "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Créer le ZIP final
zip: package
	@echo "$(YELLOW)→ Création de l'archive...$(NC)"
	@cd rendu && zip -r ../groupe_midnight.zip *
	@echo "$(GREEN)✓ Archive créée: groupe_midnight.zip$(NC)"
	@ls -lh groupe_midnight.zip

# Test dans Docker (environnement propre)
docker:
	@echo "$(YELLOW)→ Test dans un environnement Docker propre...$(NC)"
	docker run --rm -v $(PWD):/work -w /work debian:latest bash -c "\
		apt-get update -qq && \
		apt-get install -y -qq nasm && \
		nasm -f bin -o /tmp/midnight src/midnight.asm && \
		chmod +x /tmp/midnight && \
		echo 'Build réussi' && \
		ls -lh /tmp/midnight"

# Aide
help:
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo "$(GREEN)🔧 Makefile Crackme Midnight$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Commandes principales:$(NC)"
	@echo "  make           - Compiler le crackme"
	@echo "  make cipher    - Compiler cipher.nasm en standalone (debug avec gdb)"
	@echo "  make clean     - Nettoyer les fichiers générés"
	@echo "  make size      - Afficher la taille et bonus"
	@echo "  make test      - Lancer les tests du crackme"
	@echo ""
	@echo "$(YELLOW)Commandes d'analyse:$(NC)"
	@echo "  make dump      - Désassembler le binaire"
	@echo "  make hex       - Afficher en hexadécimal"
	@echo "  make bonus     - Calculer les réductions nécessaires"
	@echo ""
	@echo "$(YELLOW)Commandes de rendu:$(NC)"
	@echo "  make package   - Préparer le dossier de rendu"
	@echo "  make zip       - Créer l'archive ZIP finale"
	@echo ""
	@echo "$(YELLOW)Autres:$(NC)"
	@echo "  make check-deps - Vérifier les dépendances"
	@echo "  make docker    - Tester dans Docker"
	@echo "  make help      - Afficher cette aide"
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""

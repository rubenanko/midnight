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
	@echo -e "$(GREEN)✓ Build réussi$(NC)"
	@$(MAKE) size

# Créer les dossiers build et obj s'ils n'existent pas
$(BUILD_PATH) $(OBJ_PATH):
	@mkdir -p $@
	@echo -e "$(YELLOW)→ Création du dossier $@$(NC)"

# Compiler le crackme
$(TARGET): $(SRC_PATH)/midnight.asm | $(BUILD_PATH)
	@echo -e "$(YELLOW)→ Compilation de $(TARGET_NAME)...$(NC)"
	nasm -f bin -o $(TARGET) $(SRC_PATH)/midnight.asm
	chmod +x $(TARGET)
	@echo -e "$(GREEN)✓ Compilation terminée$(NC)"

# Compiler cipher.nasm en standalone (pour debug avec gdb)
cipher: $(CIPHER_ELF)
	@echo -e "$(GREEN)✓ cipher.elf compilé avec succès$(NC)"
	@echo -e "$(YELLOW)→ Debug avec: gdb $(CIPHER_ELF)$(NC)"

$(CIPHER_ELF): $(SRC_PATH)/cipher.nasm | $(BUILD_PATH) $(OBJ_PATH)
	@echo -e "$(YELLOW)→ Compilation de cipher.nasm en ELF...$(NC)"
	nasm -felf64 -g -F dwarf $(SRC_PATH)/cipher.nasm -o $(OBJ_PATH)/cipher.o
	ld -o $(CIPHER_ELF) $(OBJ_PATH)/cipher.o
	@echo -e "$(GREEN)✓ ELF créé: $(CIPHER_ELF)$(NC)"

# Afficher la taille avec calcul de bonus
size: $(TARGET)
	@echo ""
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@SIZE=$$(stat -c%s $(TARGET) 2>/dev/null || stat -f%z $(TARGET)); \
	echo -e "$(GREEN)📦 Taille du binaire: $$SIZE octets$(NC)"; \
	echo -e "$(YELLOW)───────────────────────────────────────$(NC)"; \
	if [ $$SIZE -gt 8192 ]; then \
		echo -e "$(RED)❌ DISQUALIFIÉ: Taille > 8 KiB$(NC)"; \
	elif [ $$SIZE -le 1024 ]; then \
		echo -e "$(GREEN)🏆 BONUS: +2.0000 pts (≤ 1 KiB) - Max 8 args$(NC)"; \
	elif [ $$SIZE -le 2048 ]; then \
		echo -e "$(GREEN)🏆 BONUS: +1.3333 pts (≤ 2 KiB) - Max 4 args$(NC)"; \
	elif [ $$SIZE -le 4096 ]; then \
		echo -e "$(GREEN)🏆 BONUS: +0.6666 pts (≤ 4 KiB) - Max 2 args$(NC)"; \
	elif [ $$SIZE -le 8192 ]; then \
		echo -e "$(GREEN)✓ Conforme: ≤ 8 KiB - Max 1 arg$(NC)"; \
	fi; \
	echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Tests automatiques
test: $(TARGET)
	@echo ""
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo -e "$(YELLOW)🧪 Tests du crackme$(NC)"
	@echo -e "$(YELLOW)───────────────────────────────────────$(NC)"
	@echo -e "$(YELLOW)Test 1: Sans argument$(NC)"
	@if ./$(TARGET) 2>/dev/null; then \
		echo -e "$(RED)❌ FAIL: Ne devrait pas accepter sans arg$(NC)"; \
	else \
		echo -e "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Test 2: Argument trop long (17+ octets)$(NC)"
	@if ./$(TARGET) "12345678901234567" 2>/dev/null | grep -q "OK"; then \
		echo -e "$(RED)❌ FAIL: Ne devrait pas accepter > 16 octets$(NC)"; \
	else \
		echo -e "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Test 3: Mauvais mot de passe (16 octets)$(NC)"
	@if ./$(TARGET) "WrongPassword!!!" 2>/dev/null | grep -q "OK"; then \
		echo -e "$(RED)❌ FAIL: Accepte un mauvais mdp$(NC)"; \
	else \
		echo -e "$(GREEN)✓ PASS: Rejette correctement$(NC)"; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Test 4: BON mot de passe$(NC)"
	@echo -e "$(RED)⚠ À TESTER MANUELLEMENT avec votre mot de passe$(NC)"
	@echo "  Exemple: ./$(TARGET) \"VotreMotDePasse!\""
	@echo "  Devrait afficher: OK"
	@echo ""
	@echo -e "$(YELLOW)Test 5: Vérification du retour$(NC)"
	@if ./$(TARGET) "WrongPassword!!!" >/dev/null 2>&1; then \
		echo -e "$(RED)❌ FAIL: Code retour devrait être non-zéro$(NC)"; \
	else \
		echo -e "$(GREEN)✓ PASS: Code retour correct$(NC)"; \
	fi
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Calcul du bonus potentiel
bonus: $(TARGET)
	@echo ""
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo -e "$(YELLOW)💰 Calcul des bonus potentiels$(NC)"
	@echo -e "$(YELLOW)───────────────────────────────────────$(NC)"
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
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Nettoyage
clean:
	@echo -e "$(YELLOW)→ Nettoyage...$(NC)"
	rm -rf $(BUILD_PATH) $(OBJ_PATH)
	rm -f $(SRC_PATH)/*.o $(SRC_PATH)/*.elf
	@echo -e "$(GREEN)✓ Nettoyage terminé$(NC)"

# Analyse avec objdump (si pas ELF pur)
dump: $(TARGET)
	@echo -e "$(YELLOW)→ Désassemblage (si possible)...$(NC)"
	@if file $(TARGET) | grep -q "ELF"; then \
		objdump -D -b binary -m i386:x86-64 $(TARGET) | less; \
	else \
		ndisasm -b64 $(TARGET) | less; \
	fi

# Analyse avec hexdump
hex: $(TARGET)
	@echo -e "$(YELLOW)→ Dump hexadécimal...$(NC)"
	hexdump -C $(TARGET) | less

# Vérifier les dépendances
check-deps:
	@echo -e "$(YELLOW)→ Vérification des dépendances...$(NC)"
	@command -v nasm >/dev/null 2>&1 || { echo -e "$(RED)❌ nasm non installé$(NC)"; exit 1; }
	@command -v stat >/dev/null 2>&1 || { echo -e "$(RED)❌ stat non installé$(NC)"; exit 1; }
	@echo -e "$(GREEN)✓ Toutes les dépendances sont présentes$(NC)"

# Préparer le rendu
package: clean all test
	@echo ""
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo -e "$(YELLOW)📦 Préparation du package de rendu$(NC)"
	@echo -e "$(YELLOW)───────────────────────────────────────$(NC)"
	@mkdir -p rendu/src
	@cp $(TARGET) rendu/midnight
	@cp $(SRC_PATH)/midnight.asm rendu/src/
	@echo '#!/bin/bash' > rendu/BUILD.sh
	@echo 'nasm -f bin -o midnight src/midnight.asm' >> rendu/BUILD.sh
	@echo 'chmod +x midnight' >> rendu/BUILD.sh
	@echo 'echo "Build réussi: $$(ls -lh midnight | awk '"'"'{print $$5}'"'"')"' >> rendu/BUILD.sh
	@chmod +x rendu/BUILD.sh
	@echo -e "$(GREEN)✓ Fichiers copiés dans ./rendu/$(NC)"
	@echo ""
	@echo "Contenu du package:"
	@ls -lh rendu/
	@echo ""
	@echo -e "$(YELLOW)N'oubliez pas d'ajouter DOCUMENTATION.pdf !$(NC)"
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""

# Créer le ZIP final
zip: package
	@echo -e "$(YELLOW)→ Création de l'archive...$(NC)"
	@cd rendu && zip -r ../groupe_midnight.zip *
	@echo -e "$(GREEN)✓ Archive créée: groupe_midnight.zip$(NC)"
	@ls -lh groupe_midnight.zip

# Test dans Docker (environnement propre)
docker:
	@echo -e "$(YELLOW)→ Test dans un environnement Docker propre...$(NC)"
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
	@echo -e "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)🔧 Makefile Crackme Midnight$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Commandes principales:$(NC)"
	@echo "  make           - Compiler le crackme"
	@echo "  make cipher    - Compiler cipher.nasm en standalone (debug avec gdb)"
	@echo "  make clean     - Nettoyer les fichiers générés"
	@echo "  make size      - Afficher la taille et bonus"
	@echo "  make test      - Lancer les tests du crackme"
	@echo ""
	@echo -e "$(YELLOW)Commandes d'analyse:$(NC)"
	@echo "  make dump      - Désassembler le binaire"
	@echo "  make hex       - Afficher en hexadécimal"
	@echo "  make bonus     - Calculer les réductions nécessaires"
	@echo ""
	@echo -e "$(YELLOW)Commandes de rendu:$(NC)"
	@echo "  make package   - Préparer le dossier de rendu"
	@echo "  make zip       - Créer l'archive ZIP finale"
	@echo ""
	@echo -e "$(YELLOW)Autres:$(NC)"
	@echo "  make check-deps - Vérifier les dépendances"
	@echo "  make docker    - Tester dans Docker"
	@echo "  make help      - Afficher cette aide"
	@echo ""
	@echo -e "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""

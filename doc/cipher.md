# Documentation technique : cipher.nasm

## Vue d'ensemble

Le fichier cipher.nasm implémente une fonction de chiffrement simplifiée opérant sur des blocs de 16 octets. L'objectif est de créer un mécanisme de vérification de mot de passe analytiquement réversible tout en intégrant plusieurs techniques d'obfuscation pour compliquer l'analyse statique et dynamique.

## Architecture du chiffrement

### Principe de base

La fonction cipher prend en entrée 16 octets répartis en deux registres de 64 bits (rdi et rsi) et produit deux valeurs chiffrées (rdx et rbx). Le chiffrement s'effectue octet par octet selon la transformation suivante :

```
c = (b XOR 4) + b
```

où b est l'octet en clair et c l'octet chiffré. Cette transformation préserve la structure positionnelle : chaque octet chiffré dépend uniquement de son octet source, ce qui garantit la réversibilité analytique.

### Implémentation de la boucle

Le traitement se déroule en deux phases de 8 octets chacune. Pour chaque octet, on extrait le byte de poids faible avec `movzx rax, dil`, on applique la transformation, puis on construit progressivement le résultat en shiftant rbx de 8 bits à gauche avant d'insérer le nouvel octet chiffré.

Le registre r8 sert de compteur décrémental pour parcourir les 8 octets, tandis que r9 indique la phase courante (0 pour la première moitié, 1 pour la seconde). À la fin de la première phase, le résultat rbx est sauvegardé dans rdx, rbx est réinitialisé, et on charge les 8 octets suivants depuis rsi dans rdi.

### Vérification intégrée

Au lieu de retourner simplement les valeurs chiffrées, la fonction intègre directement une comparaison avec des valeurs cibles hardcodées. Les hashs attendus sont poussés sur la pile puis comparés octet par octet avec les résultats calculés via une implémentation de strcmp.

Si la comparaison échoue, le programme exit avec un code d'erreur. Si elle réussit, le programme affiche "OK\n" et termine proprement. Cette approche fusionne chiffrement et validation dans un même bloc de code.

## Techniques d'obfuscation

### Prédicats opaques

Deux prédicats opaques sont insérés stratégiquement dans le code pour créer des branches mortes qui ne seront jamais prises mais compliquent l'analyse.

Le premier prédicat exploite une propriété mathématique : le carré d'un nombre modulo 2 est toujours pair. On calcule `rdx * rdx` puis on teste le bit de parité avec `test al, 1`. Le jump conditionnel pointe vers un faux exit qui ne sera jamais exécuté.

Le second prédicat repose sur la congruence `7x mod 2 = x mod 2`. On calcule 7x via `lea r10, [rax + rax*8]` suivi de deux soustractions, puis on XOR avec la valeur originale.

Ces prédicats introduisent du bruit dans le control flow graph sans altérer le comportement réel du programme.

### Dispatcher basique

Un dispatcher simple est ajouté pour briser la linéarité du flux d'exécution. Il route l'exécution selon la valeur de r8 :

- Si r8 = 8, on entre dans l'état 0 qui initialise r15 puis saute vers la boucle principale
- Si r8 = 0, on entre dans l'état 1 qui gère la transition entre les deux moitiés
- Sinon, on continue directement dans la boucle

Ce dispatcher fragmente le code en états discrets et oblige l'analyste à suivre les transitions d'état plutôt qu'un flux séquentiel simple.

### Position-independent code

L'ensemble du code est position-independent pour permettre une exécution depuis la pile : les accès mémoire utilisent systématiquement un adressage relatif à RIP. De plus, tous les jumps sont naturellement PC-relatifs en x86-64.

Cette propriété permet de copier dynamiquement le code sur la pile exécutable et de l'invoquer depuis cette position, rendant l'analyse statique plus difficile puisque le code n'est plus à son emplacement nominal.

## Réversibilité analytique

Le chiffrement reste facilement inversible malgré l'obfuscation. Pour chaque octet chiffré c, on peut tester les 256 valeurs possibles de b jusqu'à trouver celle qui satisfait `((b XOR 4) + b) & 0xFF = c`.

Cette recherche exhaustive nécessite au maximum 256 \* 16 = 4096 tests, exécutables en quelques millisecondes. Un script Python trivial peut donc récupérer le mot de passe à partir des valeurs TARGET_HASH hardcodées dans le binaire.

L'obfuscation vise à compliquer l'identification de l'algorithme et la localisation des constantes de comparaison, pas à rendre le problème cryptographiquement dur.

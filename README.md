# Midnight, *où le crackme d'une nuit* [^1]
> Midnight est binaire ELF (x86-64) obfusqué mais analytiquement réversible, pensé pour entraîner à la rétroconception.
---
## Ambitions
Ce projet noue l'ambition d'emmener le reverse engineer à travers les méandres de notre finasserie, déployée par des mécanismes dilatoires demeurant simples malgré-tout.

## Contraintes d'élaboration
Le binaire s'astreint à :
- une taille inférieure à 4 Ko,
- une portabilité sur une architecture Linux classique,
- une résistance aux agents LLMs analogues à Codex ou Claude Code (à dâte du 20 novembre 2025),
- demeurer exécutable, et retourner `OK\n` sur stdout en cas de succès.

[^1]: La dénomination du programme tient au contexte de développement de ce dernier, initié et clôturé en l'espace d'une demi-journée, rendu fonctionnel à minuit pile.

---
# Midnight, *where the crackme of a night* [^2]
> Midnight is an obfuscated but analytically reversible ELF (x86-64) binary, designed to train reverse engineering.
---
## Ambitions
This project aims to take reverse engineers through the twists and turns of our craftiness, deployed through delaying mechanisms that remain simple nonetheless.

## Development constraints
The binary must comply with the following requirements:
- size less than 4 KB,
- portability on a standard Linux architecture,
- resistance to LLMs similar to Codex or Claude Code (as of November 20, 2025),
- remain executable, and return `OK\n` on stdout if successful.

[^2]: The name of the program is due to the context of its development, which was initiated and completed in half a day, and made functional at midnight sharp.

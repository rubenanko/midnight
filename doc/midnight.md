# Midnight : un crackme inconcevable

## Point d'entrée

On récupère les argumentsd et on injecte de la donnée afin de rendre le code illisible car désaligné.
On calcule la taille, non sans obfusactionj là ecnore.

### Un faux jeu de piste...

On vérifie les huits premiers caractères. Si ces derniers valent `cosmogol`, on valide.
ENsuite, on comapre avec 9, ET SI >= on apellle check cesar1... Si on échoue, on jump à continue ; sinon à pre_fake_check_cesar_2.
Hash stocké dans r9, construit au fur et à mesure qu'on compare les caractères. Ce dernier est arbitraire, déterministe.
Si la chaîne n'est pas égal, on jump à continue et on accède au vrai crack me ; toutefois, on échoue par la force des choses, puisqu'on a pas la première lettre.
Si on valide `cosmogol`, on va dans cesar2

### En deux parties.

On somme le lsb de r8 avec r9, et on compare au caractrère courant.
Choix spécifique de r8 pour que lors de la somme, la solution imposée soit `shadok`.
Si on échoue la comparaison, on va aussi dans continue -> on se ditr qu'on est en échec.
SI réussi, ie `cosmogolshadok` on jump à `exit_with_error`.

### Overview

On perd en visibilité globale par le biais d'instructions overlapping.

```
   _._
 o|- -|o This file is licensed under CC BY-NC-SA 4.0 international license.
  ( l )  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
    =    Author: jean-marc "jihem" quere 2026
```

[![rag](ressources/carnet.png)](https://lipunila.sonaliwan.fr)
# Carnet Lexis+ - architecture

## Vue d'ensemble

```
┌──────────────── application (principal.prg …) ────────────────┐      ┌──────── noyau ────────┐
│ carnet (modèle)  ──►  cellules à l'écran (panneau défilant)   │      │ noyau.prg             │
│      ▲                       │ Maj+Entrée / ▶                 │      │  boucle : saisir()    │
│      │ sorties               ▼                                │      │  lexis.charger(...)   │
│ moteur.prg : file d'attente ─► c_<id>.prg + procedures.prg ───┼─────►│  appeler(NB_CELLULE_n)│
│      ▲                       x:envoyer("X|…")                 │      │  afficher… → JSON     │
│      └──── sursortie / surdemande / surfin ◄──────────────────┼──────│  ? texte              │
└───────────────────────────────────────────────────────────────┘      └───────────────────────┘
```

L'application et le noyau sont deux interpréteurs Lexis+ distincts : le code des cellules ne
peut ni bloquer l'interface ni toucher à ses variables, et **■ Interrompre** arrête le noyau sans
fermer le carnet.

## Le noyau

`ressources/noyau.lxk` est copié en `<tmp>/…-carnet/noyau/noyau.prg` et lancé par
`lexis.executer(chemin, {sursortie, surdemande, surfin})`. Il boucle :

1. affiche `car(30) + "NB:pret"` puis attend une commande par `saisir("")` ;
2. `X|procedures.prg|c_<id>.prg|NB_CELLULE_<id>|<ident>` : charge les deux fichiers par
   `lexis.charger` (recharger un fichier remplace ses procédures) et appelle la procédure de la
   cellule ; `§dossier|chemin` change le dossier courant ; `§quitter` termine.

Le code d'une cellule est le corps de `procedure NB_CELLULE_<id>` : les affectations de
variables non déclarées y sont **globales**, donc partagées par toutes les cellules — c'est ce
qui donne la persistance des variables, sans mécanisme supplémentaire.

Les procédures et fonctions écrites dans les cellules ne peuvent pas être imbriquées dans
`NB_CELLULE_<id>` : `PREPARER_CELLULE` les extrait (du mot-clé au `retourner` de même retrait) et
les écrit toutes dans `procedures.prg`, dans l'ordre de leur première définition. Un seul
fichier pour toutes les définitions permet de déplacer une procédure d'une cellule à l'autre
(`lexis.charger` refuse un nom défini dans un autre fichier).

Les cellules et `procedures.prg` sont dans `<tmp>/…/cellules/`, **hors** du dossier du noyau :
un programme charge tous les `.prg` de son dossier.

### Protocole

Toute ligne de sortie commençant par `car(30) NB:` est un message ; les autres sont la sortie
texte de la cellule (`?`).

| Message | Sens |
| --- | --- |
| `NB:pret` | prêt ; la demande de saisie qui suit vient du noyau |
| `NB:debut:<ident>` | début d'exécution |
| `NB:sortie:<json>` | sortie enrichie : `valeur`, `table`, `graphe`, `markdown` |
| `NB:fin:<ident>:ok:<secondes>` | fin normale |
| `NB:fin:<ident>:erreur:<json>` | fin en erreur : `pileerreur()` (message et pile d'appels) |

Les événements du noyau (sortie, demande, fin) arrivent **dans l'ordre** : une demande de saisie
qui ne suit pas `NB:pret` vient d'un `saisir()` de la cellule ; le carnet ouvre alors
`ui.demander` et répond par `x:envoyer`.

`json()` met les clefs en majuscules : les noms de colonnes voyagent donc comme **valeurs**
(`colonnes = {"mois", "nord"}`), jamais comme clefs.

### File d'attente

`NOYAU_SOUMETTRE` ajoute une cellule à `file_attente` (en-tête `[*]`) ; `NOYAU_POMPER` envoie la
suivante quand le noyau est prêt et qu'aucune cellule ne tourne. Une erreur vide la file (comme
« tout exécuter » dans Jupyter). Une commande `§…` peut aussi être mise en file.

### Interruption et redémarrage

`x:arreter()` arrête l'interpréteur du noyau ; `surfin` arrive (dernier événement de cet
interpréteur) et le carnet en démarre un nouveau. `arret_voulu` distingue une interruption (la
file est vidée), un redémarrage (la file est gardée : *Redémarrer et tout exécuter*) et un arrêt
imprévu (message d'erreur, au plus cinq relances de suite).

## Erreurs et lignes

Chaque fichier généré a sa **carte** : ligne du fichier → ligne de la cellule (`cartes[id]`,
`carte_procs` pour `procedures.prg`, qui renvoie aussi à la cellule d'origine).

- **Avant l'exécution** : `lexis.verifier` sur `c_<id>.prg` et `procedures.prg` ; les erreurs
  bloquent l'envoi, les avertissements sont soulignés ; les numéros « (ligne n) » des messages
  sont traduits.
- **À l'exécution** : la pile de `pileerreur()` (« …/c_12.prg:4 dans RATIO ») est traduite ligne
  par ligne (`TRADUIRE_PILE`) : « ligne 4 » dans la cellule exécutée, « cellule [3], ligne 2 »
  ailleurs ; les lignes internes du noyau sont retirées ; la ligne fautive est soulignée par
  `ed:diagnostics`.

## Affichage

- Le panneau central est un `ui.panneau{defilement = "vertical"}` ; une cellule est une
  `ui.colonne` : en-tête (`rangee` avec `fond`), éditeur, rendu Markdown, colonne des sorties.
- Éditeur : `ui.editeur{onglets = faux, ajuster = vrai, lignesmin = 2}` — sans barre d'onglets,
  hauteur = nombre de lignes, molette transmise au panneau, Maj+Entrée → `cmd:shiftenter`,
  Ctrl+Entrée → `cmd:ctrlenter`.
- Texte rendu et sorties : `ui.markdown{ajuster = vrai[, hauteurmax = n]}` — hauteur = contenu
  (ascenseur au-delà de `hauteurmax`).
- Grilles et graphes : `ui.grille`, `ui.graphe` ; une grille sans rien à faire défiler laisse la
  molette au panneau.
- La sortie texte est mise en tampon et affichée par paquets (minuterie de 120 ms) : mille
  lignes de `?` ne provoquent pas mille mises en page.
- Une insertion en fin de carnet ajoute un bloc ; une insertion au milieu ou un déplacement
  reconstruit les blocs (`CONSTRUIRE_TOUT`).

## Exports

- HTML : `publication.html` pour le Markdown, `<pre>` pour le code et le texte, `<table>`, SVG
  produit par `SVG_GRAPHE` (colonnes groupées, lignes, aires, secteurs ; graduations rondes).
- Markdown et PDF : même source Markdown (`MARKDOWN_CARNET`) ; graphes écrits en SVG ; le PDF est
  produit par `publication.pdf` avec le dossier des figures.
- `.prg` : corps des cellules dans l'ordre, procédures à la fin (règle de Lexis+ : le code de
  premier niveau précède les procédures), aides `afficher…` en version console.

## Pièges de Lexis+ évités

- Pas de variable nommée comme une fonction appelée (`texte`, `valeur`, `position`, `type`…).
- Clefs des tables en majuscules : le format `.lxnb` est écrit par `ENCODER_JSON` (clefs en
  minuscules) et relu par `dejson` (accès insensible à la casse).
- `souschaine` convertit toute la chaîne à chaque appel : les textes longs sont traités par
  lignes (`decouper`).
- Seul `principal.prg` a du code de premier niveau ; les constantes y sont déclarées.

Voir `README.md` pour une mise en œuvre rapide.

## Licence

CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026

### Encore une chose !
Un p'tit geste qui peut - grandement - nous aider... \[La caféïne c'est important pour une équipe de neuro-atypiques : TSA, TDAH, TAG, HPI et/ou THPI (membres de **mensa.fr** et de **triplenine.org**).\]

[![Buy Me a Coffee](ressources/buymeacoffe-fre.png)](https://buymeacoffee.com/sonaliwan.fr)

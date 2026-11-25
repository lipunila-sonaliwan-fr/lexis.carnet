```
   _._
 o|- -|o This file is licensed under CC BY-NC-SA 4.0 international license.
  ( l )  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
    =    Author: jean-marc "jihem" quere 2026
```

[![rag](ressources/carnet.png)](https://lipunila.sonaliwan.fr)
# Carnet Lexis+

Carnets interactifs pour Lexis+, à la manière de Jupyter. Un carnet (`.lxnb`) mélange :

- des **cellules de code Lexis+**, exécutées dans un noyau qui garde ses variables d'une cellule à l'autre ;
- des **cellules SQL**, exécutées dans la base DuckDB (en mémoire) du noyau ;
- des **cellules de texte** en Markdown : titres, listes, tableaux, citations, code.

Les résultats s'affichent sous chaque cellule : texte, valeurs, tableaux (grilles), graphes
(colonnes, lignes, aires, secteurs), Markdown et erreurs. Ils sont **enregistrés avec le carnet** :
un carnet se consulte sans être réexécuté.

## Lancer

```
wdlexisrt principal.prg                      nouveau carnet
wdlexisrt principal.prg mon-carnet.lxnb      ouvre un carnet
```

Le menu **Fichier › Ouvrir le carnet de découverte** présente toutes les possibilités ; le menu
**Aide › Aide-mémoire** résume les appels et les raccourcis.

> Le runtime doit être recompilé avec les modifications livrées à part (éditeur sans onglets
> ajusté à son texte, Maj/Ctrl+Entrée, `pileerreur()`, Markdown ajusté à son contenu…).

## Utiliser

| Action | Comment |
| --- | --- |
| Exécuter la cellule et passer à la suivante | **Maj+Entrée** (une cellule est créée à la fin) |
| Exécuter la cellule | **Ctrl+Entrée**, ou ▶ dans son en-tête |
| Tout exécuter | **▶▶ Tout** ; l'exécution s'arrête à la première erreur |
| Modifier un texte | **double-clic** sur le rendu ; **Maj+Entrée** affiche à nouveau le rendu |
| Ajouter (après la cellule choisie) | **+ Code**, **+ SQL**, **+ Texte**, **+** dans l'en-tête, ou *Cellule › Ajouter du Code Lexis+ (après)*, *du SQL DuckDB*, *du Texte Markdown* |
| Insérer (avant la cellule choisie) | *Cellule › Insérer du Code Lexis+ (avant)*, *du SQL DuckDB*, *du Texte Markdown* |
| Changer le genre d'une cellule | *Cellule › Changer en Code Lexis+*, *en SQL DuckDB*, *en Texte Markdown* |
| Déplacer, dupliquer, supprimer | ▲ ▼ ⧉ ✕ (en-tête ou barre d'outils) |
| Arrêter une boucle sans fin | **■ Interrompre** : le noyau redémarre, ses variables sont effacées |
| Repartir de zéro | **↻ Redémarrer** (ou *Exécution › Redémarrer et tout exécuter*) |
| Enregistrer / ouvrir / nouveau | **Ctrl+S**, **Ctrl+O**, **Ctrl+N** |
| Masquer / afficher une cellule | **▾ / ▸** au début de l'en-tête (ou *Cellule › Masquer / afficher la cellule*) |
| Inclure ou exclure une cellule des exports | case **Export** de l'en-tête (ou *Cellule › Inclure / exclure des exports*) |

L'en-tête de chaque cellule montre son numéro `[n]` : sa position dans le carnet, le même que
sur la vignette de la minimap. Il ne change pas quand on exécute ou réexécute la cellule, seulement
quand on ajoute, supprime ou déplace des cellules ; les messages d'erreur et l'export HTML
désignent les cellules par ce numéro. L'en-tête d'une cellule de code montre aussi son état
(en attente, en cours…) ou la durée de sa dernière exécution.

Une cellule **masquée** (▸) ne montre plus que son en-tête, avec sa première ligne en aperçu ;
elle s'exécute normalement et ses sorties sont conservées. Pour une cellule de code (Lexis+ ou
SQL) masquée dont la case **Export** est cochée, seul le code est caché : son résultat reste
affiché sous l'en-tête. Masquer ou afficher une cellule ne change que ce qui est sous elle (qui
remonte ou descend) ; ce qui est au-dessus ne bouge pas, et l'ascenseur suit la nouvelle hauteur.
Tout en bas, l'ascenseur s'arrête sur le bas de la dernière cellule, jamais sur un vide. *Affichage › Code Lexis+
masquer / révéler* masque toutes les cellules Lexis+ si l'une d'elles est affichée, sinon les
révèle toutes ; *Affichage › SQL DuckDB masquer / révéler* fait de même pour les cellules SQL.
Les autres cellules ne changent pas. L'état masqué est enregistré avec le carnet.

### Minimap

À droite du carnet, juste avant l'ascenseur, une colonne de vignettes numérotées (une par
cellule, dans l'ordre ; hauteur proportionnelle à celle de la cellule, couleur selon le genre :
Lexis+, SQL, Texte, écrit en clair sur la vignette ; à droite, alignées d'une vignette à
l'autre, ◉ : cellule masquée et ✓ : cellule exportée) donne le plan du carnet :

- les vignettes des cellules visibles à l'écran sont éclairées, celle de la cellule choisie est
  numérotée en bleu ;
- un **clic** sur une vignette amène sa cellule en haut de l'écran et la choisit ;
- **glisser** une vignette vers le haut ou le bas déplace la cellule : la vignette d'arrivée est
  marquée ▸ (en orange) et la barre d'état dit où la cellule ira ; relâcher la place avant elle
  (en dessous de la dernière : à la fin).

*Affichage › Minimap masquer / afficher* ; le choix est gardé dans les réglages.
Avec un runtime qui n'a pas `panneau:volet` (voir les modifications du runtime livrées avec cette
version), la minimap se place à droite de l'ascenseur et le glisser n'est montré qu'au relâchement.

## Écrire du code

Les variables **non déclarées** sont globales : elles restent d'une cellule à l'autre jusqu'au
redémarrage du noyau ; `locale x` limite une variable à sa cellule. Les `procedure` et `fonction`
écrites dans une cellule (du mot-clé jusqu'au `retourner` de même retrait) sont connues de toutes
les cellules.

| Appel | Résultat sous la cellule |
| --- | --- |
| `? a, b` | texte (les longues sorties défilent) |
| `afficher(x)` | une valeur ; une liste de fiches devient un tableau |
| `afficher_table(lignes, [colonnes])` | grille : liste de fiches ou de listes |
| `afficher_graphe(genre, categories, series, [titre])` | graphe ; `series` : liste de nombres, ou `{{nom = "…", valeurs = {…}}, …}` |
| `afficher_graphe_table(lignes, categorie, valeurs, [genre], [titre])` | graphe d'un résultat de requête |
| `afficher_md(texte)` | Markdown |
| `afficher_sql(requete, [paramètres…])` | grille du résultat d'une requête DuckDB |
| `saisir("Question ?")` | boîte de saisie |

Une **cellule SQL** exécute ses instructions (séparées par `;` en fin de ligne) et affiche le
résultat de la dernière. Les tables créées sont visibles du code (`requete(...)`) et inversement.

Le dossier courant du noyau est celui du carnet : un fichier de données posé à côté du carnet
s'ouvre par son nom.

**Erreurs** : avant l'exécution, la syntaxe de la cellule est vérifiée ; à l'exécution, l'erreur
s'affiche avec la ligne de la cellule et la pile d'appels traduite (« ligne 2 dans RATIO »,
« cellule [3], ligne 5 ») ; la ligne fautive est soulignée dans l'éditeur.

## Exporter

*Fichier › Exporter* :

- **HTML** : page autonome (styles intégrés, graphes en SVG), lisible dans tout navigateur ;
- **Markdown** : texte, code et résultats ; les graphes sont écrits en `.svg` à côté du `.md` ;
- **PDF** : le Markdown mis en page par le paquet `publication` (A4, pied de page numéroté) ;
- **programme `.prg`** : le code des cellules dans l'ordre, les textes en commentaires, les
  procédures à la fin et des versions console de `afficher…` : le carnet devient un programme.

Seules les cellules dont la case **Export** est cochée sont exportées (dans le `.prg`, une
cellule exclue est remplacée par un commentaire). Une cellule de code masquée n'exporte que son
résultat en HTML, Markdown et PDF (rien si elle n'a pas de sortie) ; le `.prg` garde son code,
nécessaire à l'exécution. Une cellule de texte masquée est repliée dans la page HTML : un clic sur
son aperçu l'ouvre.

## En ligne de commande (traitement par lots)

```
wdlexisrt principal.prg rapport.lxnb --executer --enregistrer --exporter rapport.html --exporter rapport.pdf --quitter
```

- `--executer` : exécute toutes les cellules à l'ouverture ;
- `--enregistrer` : enregistre le carnet (avec ses résultats) à la fin ;
- `--exporter fichier` : exporte d'après l'extension (`.html`, `.md`, `.pdf`, `.prg`), plusieurs fois possible ;
- `--quitter` : ferme l'application à la fin.

## Format `.lxnb`

JSON UTF-8, lisible et versionnable :

```json
{
  "format": "lexis-carnet",
  "version": 1,
  "metadonnees": {"titre": "…", "cree": "…", "modifie": "…"},
  "cellules": [
    {"genre": "markdown", "source": "# Titre"},
    {"genre": "code", "source": "? 1 + 1", "compteur": 1, "duree": 0.001,
     "sorties": [{"genre": "texte", "texte": "2"}]},
    {"genre": "code", "source": "x = 1", "masquee": true, "export": false}
  ]
}
```

Sorties : `texte`, `valeur`, `markdown` (`texte`), `table` (`colonnes`, `lignes`, `total`),
`graphe` (`forme`, `titre`, `categories`, `series` : `{nom, valeurs}`), `erreur` (`texte`, `ligne`).
Une `source` peut aussi être une liste de lignes. `masquee` (cellule repliée) et `export`
(`false` : exclue des exports) sont facultatifs et ne sont écrits que s'ils diffèrent du défaut.

## Réglages

`~/.carnet_lexis.json` : thème (*Affichage › Thème sombre / clair*), taille du texte du code
(*Affichage › Agrandir / Réduire*), dernier dossier.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `principal.prg` | fenêtre, barre d'outils, menus, clavier, ligne de commande, réglages |
| `document.prg` | modèle du carnet, lecture et écriture du format `.lxnb` |
| `cellules.prg` | cellules à l'écran : en-têtes, éditeurs, rendu Markdown, édition du carnet |
| `sorties.prg` | résultats : texte, valeur, tableau, graphe, Markdown, erreur |
| `moteur.prg` | noyau : interpréteur séparé, file d'attente, protocole, erreurs |
| `export.prg` | exports HTML, Markdown, PDF, `.prg` ; graphes en SVG |
| `minicarte.prg` | minimap : vignettes des cellules, aller à une cellule, réordonner par glisser |
| `ressources/noyau.lxk` | programme du noyau et aides `afficher…` |
| `exemples/*.lxnb` | carnet de découverte et aide-mémoire (déjà exécutés) |

Voir `ARCHITECTURE.md` pour le fonctionnement interne.

## Licence

CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026

### Encore une chose !
Un p'tit geste qui peut - grandement - nous aider... \[La caféïne c'est important pour une équipe de neuro-atypiques : TSA, TDAH, TAG, HPI et/ou THPI (membres de **mensa.fr** et de **triplenine.org**).\]

[![Buy Me a Coffee](ressources/buymeacoffe-fre.png)](https://buymeacoffee.com/sonaliwan.fr)

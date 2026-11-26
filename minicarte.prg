&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : minimap.
&& Une colonne de vignettes numérotées (genre Lexis+ / SQL / Texte, ◉ masquée, ✓ exportée),
&& une par cellule, à droite du carnet, juste avant son
&& ascenseur vertical (volet du panneau : elle ne défile pas avec les cellules).
&&   - hauteur de chaque vignette proportionnelle à celle de la cellule ;
&&   - vignettes des cellules visibles à l'écran éclairées, cellule choisie en bleu ;
&&   - clic : amène la cellule en haut de l'écran et la choisit ;
&&   - glisser une vignette vers le haut ou le bas : déplace la cellule à cet endroit.
&& Affichage › Minimap masquer / afficher ; le choix est gardé dans les réglages.
&& Une minuterie suit le défilement et les changements du carnet (ajout, masquage, sorties...).

&& variables globales : voir principal.prg (minimap)

procedure MINI_CREER
  minicarte = pc:ajouter(ui.panneau{disposition = "vertical", defilement = "masque"})
  minicarte.marge = 4
  minicarte.espacement = 3
  minicarte.largeurfixe = MINI_LARGEUR
  mini_volet = faux
  essayer
    pc:volet(minicarte, MINI_LARGEUR)
    mini_volet = vrai
  capturer e
  finessayer
  si non mini_volet
    && runtime sans « panneau:volet » : la minimap se place à droite du carnet (après l'ascenseur)
    essayer
      minicarte:detruire()
    capturer e
    finessayer
    minicarte = fen:ajouter(ui.panneau{disposition = "vertical", defilement = "masque"})
    minicarte.marge = 4
    minicarte.espacement = 3
    minicarte.largeurfixe = MINI_LARGEUR
    minicarte.ancrage = "droite"
  finsi
  MINI_COULEURS()
  minicarte.visible = reglages.minicarte <> faux
  mini_minuterie = ui.minuterie(150, @MINI_TIC)
retourner

procedure MINI_COULEURS
  essayer
    minicarte.fond = sisinon(reglages.sombre, "#161B22", "#F3F4F6")
  capturer e
  finessayer
retourner

procedure MINI_AFFICHER(oui)
  reglages.minicarte = oui
  ECRIRE_REGLAGES()
  si minicarte = nul
    retourner
  finsi
  minicarte.visible = oui
  mini_structure = ""
  mini_cle = ""
  MINI_RAFRAICHIR()
  STATUT(sisinon(oui, "Minimap affichée", "Minimap masquée"))
retourner

&& couleur d'une vignette : genre de la cellule, plus clair si la cellule est à l'écran
fonction MINI_FOND(c, visible)
  locale g = c.genre
  si reglages.sombre
    faire cas
    cas g = "planif"
      retourner sisinon(visible, "#4C3D7A", "#2E2650")
    cas g = "markdown"
      retourner sisinon(visible, "#5B5330", "#36321F")
    cas g = "sql"
      retourner sisinon(visible, "#2F5E4A", "#1E3A2F")
    fincas
    retourner sisinon(visible, "#33507A", "#1F2F47")
  finsi
  faire cas
  cas g = "planif"
    retourner sisinon(visible, "#DDD6FE", "#EDE9FE")
  cas g = "markdown"
    retourner sisinon(visible, "#F5E6B0", "#FBF4DC")
  cas g = "sql"
    retourner sisinon(visible, "#BFE5D2", "#E3F4EB")
  fincas
retourner sisinon(visible, "#C7D7F2", "#E6EDF9")

&& libellé d'une vignette : numéro et genre (Lexis+, SQL, Texte) ; les marques ◉ (masquée) et
&& ✓ (exportée) sont dans deux colonnes de largeur fixe à droite, vides si la marque est absente,
&& pour rester alignées d'une vignette à l'autre
fonction MINI_TEXTE(c, n)
  locale g = "Lexis+"
  faire cas
  cas c.genre = "planif"
    retourner "* ⏱ Planif."
  cas c.genre = "markdown"
    g = "Texte"
  cas c.genre = "sql"
    g = "SQL"
  fincas
retourner chaine(NUMERO(c.id)) + " " + g

&& signature de la structure (thème, ordre et genre des cellules) : si elle change, les
&& vignettes sont reconstruites et les bandeaux renumérotés ; masquer une cellule ou changer
&& son export ne touche qu'au libellé de sa vignette
fonction MINI_SIGNATURE()
  locale s = sisinon(reglages.sombre, "s", "c")
  si carnet <> nul
    pour chaque c dans carnet.cellules
      s = s + "|" + c.id + c.genre
    suivant
  finsi
retourner s

&& état affiché par les libellés et les couleurs (masquage, export, cellule choisie)
fonction MINI_ETAT()
  locale s = chaine(cellule_choisie)
  pour chaque c dans carnet.cellules
    s = s + sisinon(c.masquee, "m", "-") + sisinon(c.exporter = faux, "x", "-")
  suivant
retourner s

procedure MINI_RECONSTRUIRE
  pour chaque v dans VIGNETTES
    essayer
      v.cadre:detruire()
    capturer e
    finessayer
  suivant
  VIGNETTES = {}
  mini_geometrie = ""
  mini_cle = ""
  si carnet = nul
    retourner
  finsi
  pour i = 1 a taille(carnet.cellules)
    locale c = carnet.cellules[i]
    locale v = {id = c.id}
    v.cadre = minicarte:ajouter(ui.colonne())
    v.cadre.marge = 2
    v.cadre.espacement = 0
    v.cadre.hauteurfixe = MINI_HMIN
    v.cadre.fond = MINI_FOND(c, faux)
    v.ligne = v.cadre:ajouter(ui.rangee())
    v.ligne.marge = 0
    v.ligne.espacement = 0
    v.lbl = v.ligne:ajouter(ui.etiquette(MINI_TEXTE(c, i)))
    v.lbl.poids = 1
    v.lbl.couleur = "#9CA3AF"
    v.lm = v.ligne:ajouter(ui.etiquette(""))
    v.lm.largeurfixe = 20
    v.lm.couleur = "#9CA3AF"
    v.lx = v.ligne:ajouter(ui.etiquette(""))
    v.lx.largeurfixe = 20
    v.lx.couleur = "#9CA3AF"
    v.lbl.infobulle = "[" + NUMERO(c.id) + "] · " + LIBELLE_GENRE(c.genre) + " : " + APERCU_CELLULE(c, 60) + ;
                      "  —  clic : y aller ; glisser : la déplacer"
    v.cadre.surboutonbas = @MINI_BAS
    v.cadre.surdeplacement = @MINI_DEPLACE
    v.cadre.surboutonhaut = @MINI_HAUT
    inserer v dans VIGNETTES
  suivant
retourner

&& met à jour les vignettes (structure, hauteurs, zone visible, cellule choisie)
procedure MINI_RAFRAICHIR
  si carnet = nul
    retourner
  finsi
  locale sig = MINI_SIGNATURE()
  && numéros des bandeaux : suivent l'ordre des cellules, minimap affichée ou non
  si sig <> num_ordre
    num_ordre = sig
    NUMEROTER()
  finsi
  si minicarte = nul
    retourner
  finsi
  si non minicarte.visible
    retourner
  finsi
  si sig <> mini_structure ou taille(VIGNETTES) <> taille(carnet.cellules)
    mini_structure = sig
    MINI_RECONSTRUIRE()
  finsi
  && réactivité : une seule lecture (défilement, hauteur du contenu, zone visible) suffit à
  && savoir si quelque chose a bougé ; sinon rien n'est relu, sauf une vérification complète
  && toutes les 2 secondes environ (une cellule qui grandit pendant qu'une autre rétrécit)
  si mini_glisse = nul
    locale cle = MINI_ETAT()
    locale pos = nul
    essayer
      pos = pc:position()
    capturer e
    finessayer
    si pos <> nul
      cle = cle + "|" + arrondi(pos.y) + "|" + arrondi(pos.hauteur) + "|" + arrondi(pos.vuehauteur)
      mini_tics += 1
      si cle = mini_cle et mini_tics < 14
        retourner
      finsi
      mini_cle = cle
      mini_tics = 0
    finsi
  finsi
  && géométrie des cellules (dimensions de la dernière mise en page)
  locale haut = 0, vue = 0
  essayer
    haut = pc.y
    vue = pc.hauteur
  capturer e
    retourner
  finessayer
  locale hs = {}
  locale total = 0
  locale geo = chaine(vue) + ":" + cellule_choisie
  pour chaque v dans VIGNETTES
    locale u = UIC[v.id]
    locale y = 0, h = 0
    si u <> nul
      essayer
        y = u.bloc.y
        h = u.bloc.hauteur
      capturer e
      finessayer
    finsi
    inserer {y = y, h = h} dans hs
    total += h
    geo = geo + "|" + arrondi(y) + "," + arrondi(h)
  suivant
  si geo = mini_geometrie et mini_glisse = nul
    retourner
  finsi
  mini_geometrie = geo
  && échelle : tout le carnet dans la hauteur de la minimap si possible
  locale n = taille(VIGNETTES)
  locale dispo = max(60, vue - 8 - 3 * max(0, n - 1))
  locale echelle = 0.1
  si total > 0
    echelle = min(0.12, dispo / total)
  finsi
  pour i = 1 a n
    locale v = VIGNETTES[i]
    locale c = CELLULE(v.id)
    si c <> nul
      locale g = hs[i]
      locale visible = g.h > 0 et g.y + g.h > haut + 1 et g.y < haut + vue - 1
      locale hv = arrondi(max(MINI_HMIN, min(MINI_HMAX, g.h * echelle)))
      si v.cadre.hauteurfixe <> hv
        v.cadre.hauteurfixe = hv
      finsi
      locale fond = MINI_FOND(c, visible)
      locale couleur = "#9CA3AF"
      si v.id = cellule_choisie
        couleur = "#60A5FA"
      finsi
      si mini_glisse <> nul et mini_glisse.deplace
        si v.id = mini_glisse.id
          fond = sisinon(reglages.sombre, "#4B5563", "#D1D5DB")
        finsi
        si i = mini_glisse.cible
          couleur = "#F59E0B"
        finsi
      finsi
      si v.fond_vu <> fond
        v.cadre.fond = fond
        v.fond_vu = fond
      finsi
      si v.couleur_vue <> couleur
        v.lbl.couleur = couleur
        v.lm.couleur = couleur
        v.lx.couleur = couleur
        v.couleur_vue = couleur
      finsi
      locale marque = sisinon(c.masquee, "◉", "")
      si v.masque_vue <> marque
        v.lm.libelle = marque
        v.masque_vue = marque
      finsi
      marque = sisinon(c.exporter <> faux, "✓", "")
      si v.export_vu <> marque
        v.lx.libelle = marque
        v.export_vu = marque
      finsi
      locale texte = MINI_TEXTE(c, i)
      si mini_glisse <> nul et mini_glisse.deplace et i = mini_glisse.cible
        texte = "▸ " + texte
      finsi
      si v.texte_vu <> texte
        v.lbl.libelle = texte
        v.texte_vu = texte
      finsi
    finsi
  suivant
retourner

procedure MINI_TIC(ev)
  si mini_a_montrer <> 0
    locale id = mini_a_montrer
    mini_a_montrer = 0
    MINI_ALLER(id)
  finsi
  MINI_RAFRAICHIR()
retourner

&& amène la cellule en haut de la zone visible
procedure MINI_ALLER(id)
  locale u = UIC[id]
  si u = nul
    retourner
  finsi
  essayer
    pc:defilerde(0, u.bloc.y - pc.y - 6)
  capturer e
  finessayer
  CHOISIR(id)
retourner

fonction MINI_VIGNETTE(ctl)
  pour i = 1 a taille(VIGNETTES)
    locale v = VIGNETTES[i]
    si v.cadre = ctl ou v.ligne = ctl ou v.lbl = ctl ou v.lm = ctl ou v.lx = ctl
      retourner i
    finsi
  suivant
retourner 0

&& position d'insertion (1 .. n+1) pour une ordonnée de la souris
fonction MINI_POSITION(y)
  locale premiere = sisinon(PLANIF_CELLULE() <> nul, 2, 1)       && rien avant le planificateur
  pour i = premiere a taille(VIGNETTES)
    locale cadre = VIGNETTES[i].cadre
    essayer
      si y < cadre.y + cadre.hauteur / 2
        retourner i
      finsi
    capturer e
    finessayer
  suivant
retourner taille(VIGNETTES) + 1

procedure MINI_BAS(ev)
  locale i = MINI_VIGNETTE(ev.courant)
  si i = 0 ou ev.bouton <> "gauche"
    retourner
  finsi
  locale c = CELLULE(VIGNETTES[i].id)
  && le planificateur ne se déplace pas : sa vignette sert seulement à y aller
  mini_glisse = {id = VIGNETTES[i].id, y0 = ev.y, deplace = faux, cible = 0, ;
                 fixe = (c <> nul et c.genre = "planif")}
  essayer
    fen.suivisouris = vrai
  capturer e
  finessayer
retourner

procedure MINI_DEPLACE(ev)
  si mini_glisse = nul
    retourner
  finsi
  si mini_glisse.fixe
    retourner
  finsi
  si non mini_glisse.deplace et abs(ev.y - mini_glisse.y0) < 6
    retourner
  finsi
  mini_glisse.deplace = vrai
  locale p = MINI_POSITION(ev.y)
  si p <> mini_glisse.cible
    mini_glisse.cible = p
    locale i = INDEX_CELLULE(mini_glisse.id)
    locale nom = "la cellule [" + NUMERO(mini_glisse.id) + "]"
    si p = i ou p = i + 1
      STATUT("Relâcher ici : " + nom + " ne bouge pas")
    sinonsi p > taille(VIGNETTES)
      STATUT("Relâcher ici : " + nom + " passe à la fin")
    sinon
      STATUT("Relâcher ici : " + nom + " passe avant la cellule [" + NUMERO(VIGNETTES[p].id) + "]")
    finsi
    MINI_RAFRAICHIR()
  finsi
retourner

procedure MINI_HAUT(ev)
  essayer
    fen.suivisouris = faux
  capturer e
  finessayer
  si mini_glisse = nul
    retourner
  finsi
  locale g = mini_glisse
  mini_glisse = nul
  && sans suivi de la souris (ancien runtime), le glisser se décide au relâchement
  si non g.deplace et abs(ev.y - g.y0) >= 6 et non g.fixe
    g.deplace = vrai
  finsi
  si non g.deplace
    MINI_ALLER(g.id)
    MINI_RAFRAICHIR()
    retourner
  finsi
  MINI_DEPLACER(g.id, MINI_POSITION(ev.y))
retourner

&& déplace une cellule avant la position p (1 .. n+1) ; les contrôles des cellules sont
&& seulement remis dans le nouvel ordre (éditeurs et sorties gardés)
procedure MINI_DEPLACER(id, p)
  locale i = INDEX_CELLULE(id)
  si i = 0 ou p = i ou p = i + 1
    mini_geometrie = ""
    mini_cle = ""
    MINI_RAFRAICHIR()
    STATUT("")
    retourner
  finsi
  SYNC_SOURCES()
  locale c = carnet.cellules[i]
  retirer(carnet.cellules, i)
  si p > i
    p -= 1
  finsi
  si p > taille(carnet.cellules)
    inserer c dans carnet.cellules
  sinon
    inserer c dans carnet.cellules position p
  finsi
  REORDONNER_CELLULES(min(i, p))
  MARQUER_MODIFIE()
  STATUT("Cellule déplacée : c'est maintenant la cellule [" + NUMERO(id) + "]")
  mini_a_montrer = id
  MINI_RAFRAICHIR()
retourner

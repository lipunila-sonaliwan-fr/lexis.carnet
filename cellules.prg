&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : cellules à l'écran.
&& Chaque cellule est une colonne du panneau défilant :
&&   en-tête   [n] · genre · durée · boutons (▶ ▲ ▼ ⧉ + ✕)
&&   éditeur   ui.editeur sans onglets, hauteur ajustée au texte (code, SQL, Markdown en édition)
&&   rendu     ui.markdown ajusté (cellule de texte hors édition ; double-clic : modifier)
&&   sorties   colonne des résultats (voir sorties.prg)

fonction LIBELLE_GENRE(g)
  faire cas
  cas g = "markdown"
    retourner "Texte"
  cas g = "sql"
    retourner "SQL"
  fincas
retourner "Lexis+"

fonction LANGAGE_GENRE(g)
  faire cas
  cas g = "markdown"
    retourner "markdown"
  cas g = "sql"
    retourner "sql"
  fincas
retourner "lexis"

fonction COULEUR_ENTETE(choisie)
  si reglages.sombre
    retourner sisinon(choisie, "#1E3A5F", "#1F2937")
  finsi
retourner sisinon(choisie, "#DBEAFE", "#EEF0F3")

&& ---------------------------------------------------------------- construction

procedure CONSTRUIRE_TOUT
  maj_ui = vrai
  pour chaque k, u dans UIC
    essayer
      u.bloc:detruire()
    capturer e
    finessayer
  suivant
  UIC = {}
  BOUTONS = {}
  pour chaque c dans carnet.cellules
    CONSTRUIRE_CELLULE(c)
  suivant
  maj_ui = faux
retourner

procedure CONSTRUIRE_CELLULE(c)
  locale u = {id = c.id, ctrls = {}, texte_ctl = nul, edition = faux}
  locale etait = maj_ui
  maj_ui = vrai
  u.bloc = pc:ajouter(ui.colonne())
  u.bloc.marge = 0
  u.bloc.espacement = 3
  u.entete = u.bloc:ajouter(ui.rangee())
  u.entete.hauteurfixe = 26
  u.entete.marge = 2
  u.entete.espacement = 2
  u.entete.fond = COULEUR_ENTETE(faux)
  u.num = u.entete:ajouter(ui.etiquette(""))
  u.num.largeurfixe = 54
  u.num.couleur = "#60A5FA"
  u.genre_lbl = u.entete:ajouter(ui.etiquette(LIBELLE_GENRE(c.genre)))
  u.genre_lbl.largeurfixe = 64
  u.genre_lbl.couleur = "#9CA3AF"
  u.info = u.entete:ajouter(ui.etiquette(""))
  u.info.poids = 1
  u.info.couleur = "#9CA3AF"
  BOUTON_CELLULE(u, "▶", "executer", "Exécuter la cellule (Ctrl+Entrée)")
  BOUTON_CELLULE(u, "▲", "monter", "Monter")
  BOUTON_CELLULE(u, "▼", "descendre", "Descendre")
  BOUTON_CELLULE(u, "⧉", "dupliquer", "Dupliquer")
  BOUTON_CELLULE(u, "+", "ajouter", "Insérer une cellule de code dessous")
  BOUTON_CELLULE(u, "✕", "supprimer", "Supprimer la cellule")
  u.ed = u.bloc:ajouter(ui.editeur{onglets = faux, minicarte = faux, numeros = "simples", ;
                                   ajuster = vrai, lignesmin = 2, taille = reglages.police})
  u.ed:nouveau("cellule")
  u.ed:langage(LANGAGE_GENRE(c.genre))
  u.ed:fixertexte(c.source)
  u.ed.surchangement = @CELLULE_CHANGEE
  u.ed.surselection = @CELLULE_SIGNAL
  u.ed.surfocus = @CELLULE_FOCUS
  u.md = u.bloc:ajouter(ui.markdown{texte = "", ajuster = vrai})
  u.md.surdoubleclic = @MD_DOUBLECLIC
  u.md.surselection = @MD_LIEN
  u.edition = c.genre <> "markdown" ou rogner(c.source) = ""
  u.sorties = u.bloc:ajouter(ui.colonne())
  u.sorties.marge = 0
  u.sorties.espacement = 4
  UIC[c.id] = u
  APPLIQUER_MODE(c)
  MAJ_ENTETE(c)
  pour chaque s dans c.sorties
    SORTIE_CONTROLE(u, s)
  suivant
  maj_ui = etait
retourner

procedure BOUTON_CELLULE(u, libelle, action, aide)
  locale b = u.entete:ajouter(ui.bouton(libelle, {plat = vrai}))
  b.largeurfixe = 26
  b.infobulle = aide
  b.surclic = @CLIC_BOUTON_CELLULE
  inserer {ctl = b, id = u.id, action = action} dans BOUTONS
retourner

&& cellule de texte : rendu Markdown, ou éditeur pendant la modification
procedure APPLIQUER_MODE(c)
  locale u = UIC[c.id]
  si u = nul
    retourner
  finsi
  si c.genre = "markdown" et non u.edition
    u.md.valeur = MD_RENDU(c)
    u.md.visible = vrai
    u.ed.visible = faux
  sinon
    u.ed.visible = vrai
    u.md.visible = faux
  finsi
retourner

fonction MD_RENDU(c)
  si rogner(c.source) = ""
    retourner "*Cellule de texte vide : double-cliquez pour écrire.*"
  finsi
retourner c.source

procedure MAJ_ENTETE(c)
  locale u = UIC[c.id]
  si u = nul
    retourner
  finsi
  locale n = ""
  locale info = ""
  si c.genre <> "markdown"
    faire cas
    cas c.etat = "attente"
      n = "[*]"
      info = "en attente"
    cas c.etat = "cours"
      n = "[*]"
      info = "en cours…"
    cas c.compteur <> nul et c.compteur > 0
      n = "[" + c.compteur + "]"
      si c.duree <> nul
        info = DUREE_TEXTE(c.duree)
      finsi
    autrement
      n = "[ ]"
    fincas
  sinonsi u.edition
    info = "Maj+Entrée : afficher le rendu"
  finsi
  u.num.libelle = n
  u.info.libelle = info
retourner

fonction DUREE_TEXTE(s)
  si s < 1
    retourner chaine(arrondi(s * 1000)) + " ms"
  finsi
retourner remplacertexte(chaine(arrondi(s, 2)), ".", ",") + " s"

&& ---------------------------------------------------------------- sélection

procedure CHOISIR(id)
  si cellule_choisie = id
    retourner
  finsi
  locale ancienne = UIC[cellule_choisie]
  si ancienne <> nul
    ancienne.entete.fond = COULEUR_ENTETE(faux)
  finsi
  cellule_choisie = id
  locale u = UIC[id]
  si u <> nul
    u.entete.fond = COULEUR_ENTETE(vrai)
  finsi
retourner

procedure FOCUS_CELLULE(id)
  locale u = UIC[id]
  si u = nul
    retourner
  finsi
  essayer
    si u.ed.visible
      u.ed:focus()
    sinon
      u.md:focus()
    finsi
  capturer e
  finessayer
retourner

fonction ID_DU_CONTROLE(ctl)
  pour chaque k, u dans UIC
    si u.ed = ctl ou u.md = ctl
      retourner u.id
    finsi
  suivant
retourner 0

&& ---------------------------------------------------------------- événements

procedure CELLULE_CHANGEE(ev)
  si maj_ui
    retourner
  finsi
  locale id = ID_DU_CONTROLE(ev.id)
  locale c = CELLULE(id)
  si c = nul
    retourner
  finsi
  locale t = UIC[id].ed.valeur
  si t = c.source
    retourner
  finsi
  c.source = t
  MARQUER_MODIFIE()
retourner

procedure CELLULE_SIGNAL(ev)
  si maj_ui
    retourner
  finsi
  locale id = ID_DU_CONTROLE(ev.id)
  si id = 0
    retourner
  finsi
  locale t = chaine(ev.texte)
  faire cas
  cas t = "cmd:shiftenter"
    EXECUTER_ET_PASSER(id)
  cas t = "cmd:ctrlenter" ou t = "cmd:run"
    CHOISIR(id)
    EXECUTER_CELLULE(id)
  cas t = "cmd:save"
    ENREGISTRER(nul)
  cas commencepar(t, "pos:")
    CHOISIR(id)
  fincas
retourner

procedure CELLULE_FOCUS(ev)
  locale id = ID_DU_CONTROLE(ev.id)
  si id <> 0
    CHOISIR(id)
  finsi
retourner

procedure MD_DOUBLECLIC(ev)
  locale id = ID_DU_CONTROLE(ev.id)
  si id <> 0
    CHOISIR(id)
    EDITER_MARKDOWN(id)
  finsi
retourner

procedure MD_LIEN(ev)
  STATUT("Lien : " + chaine(ev.texte))
retourner

procedure CLIC_BOUTON_CELLULE(ev)
  pour chaque b dans BOUTONS
    si b.ctl = ev.id
      CHOISIR(b.id)
      faire cas
      cas b.action = "executer"
        EXECUTER_CELLULE(b.id)
      cas b.action = "monter"
        DEPLACER(b.id, -1)
      cas b.action = "descendre"
        DEPLACER(b.id, 1)
      cas b.action = "dupliquer"
        DUPLIQUER(b.id)
      cas b.action = "ajouter"
        INSERER_CELLULE("code", "", 1)
      cas b.action = "supprimer"
        SUPPRIMER_CELLULE(b.id)
      fincas
      retourner
    finsi
  suivant
retourner

&& ---------------------------------------------------------------- édition du carnet

procedure SYNC_SOURCES
  si carnet = nul
    retourner
  finsi
  pour chaque c dans carnet.cellules
    locale u = UIC[c.id]
    si u <> nul
      c.source = u.ed.valeur
    finsi
  suivant
retourner

procedure AJOUTER_CODE(ev)
  INSERER_CELLULE("code", "", 1)
retourner

procedure AJOUTER_TEXTE(ev)
  INSERER_CELLULE("markdown", "", 1)
retourner

procedure AJOUTER_SQL(ev)
  INSERER_CELLULE("sql", "", 1)
retourner

&& insère une cellule sous (decalage = 1) ou au-dessus (0) de la cellule choisie
procedure INSERER_CELLULE(genre, src, decalage)
  SYNC_SOURCES()
  locale nc = NOUVELLE_CELLULE(genre, src)
  locale i = INDEX_CELLULE(cellule_choisie)
  locale n = taille(carnet.cellules)
  locale pos = n + 1
  si i > 0
    pos = i + decalage
  finsi
  si pos > n
    inserer nc dans carnet.cellules
    CONSTRUIRE_CELLULE(nc)
    essayer
      pc:defilera(0, 1000000)
    capturer e
    finessayer
  sinon
    inserer nc dans carnet.cellules position pos
    CONSTRUIRE_TOUT()
  finsi
  CHOISIR(nc.id)
  FOCUS_CELLULE(nc.id)
  MARQUER_MODIFIE()
  MAJ_TITRE()
retourner

procedure MONTER(ev)
  DEPLACER(cellule_choisie, -1)
retourner

procedure DESCENDRE(ev)
  DEPLACER(cellule_choisie, 1)
retourner

procedure DEPLACER(id, sens)
  locale i = INDEX_CELLULE(id)
  locale j = i + sens
  si i = 0 ou j < 1 ou j > taille(carnet.cellules)
    retourner
  finsi
  SYNC_SOURCES()
  locale a = carnet.cellules[i]
  carnet.cellules[i] = carnet.cellules[j]
  carnet.cellules[j] = a
  CONSTRUIRE_TOUT()
  locale garde = cellule_choisie
  cellule_choisie = 0
  CHOISIR(garde)
  FOCUS_CELLULE(garde)
  MARQUER_MODIFIE()
retourner

procedure DUPLIQUER(id)
  locale c = CELLULE(id)
  si c = nul
    retourner
  finsi
  SYNC_SOURCES()
  CHOISIR(id)
  INSERER_CELLULE(c.genre, c.source, 1)
retourner

procedure SUPPRIMER(ev)
  SUPPRIMER_CELLULE(cellule_choisie)
retourner

procedure SUPPRIMER_CELLULE(id)
  locale i = INDEX_CELLULE(id)
  si i = 0
    retourner
  finsi
  si id = cellule_en_cours
    STATUT("Cellule en cours d'exécution : interrompez-la d'abord.")
    retourner
  finsi
  SYNC_SOURCES()
  RETIRER_DE_FILE(id)
  retirer(carnet.cellules, i)
  locale u = UIC[id]
  si u <> nul
    essayer
      u.bloc:detruire()
    capturer e
    finessayer
    UIC[id] = nul
  finsi
  locale reste = {}
  pour chaque b dans BOUTONS
    si b.id <> id
      inserer b dans reste
    finsi
  suivant
  BOUTONS = reste
  cellule_choisie = 0
  si taille(carnet.cellules) = 0
    locale nc = NOUVELLE_CELLULE("code", "")
    inserer nc dans carnet.cellules
    CONSTRUIRE_CELLULE(nc)
  finsi
  CHOISIR(carnet.cellules[min(i, taille(carnet.cellules))].id)
  MARQUER_MODIFIE()
  MAJ_TITRE()
retourner

procedure CHANGER_GENRE(id, genre)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul ou u = nul ou c.genre = genre
    retourner
  finsi
  SYNC_SOURCES()
  c.genre = genre
  c.sorties = {}
  c.compteur = 0
  c.duree = nul
  SORTIES_VIDER(u)
  u.ed:langage(LANGAGE_GENRE(genre))
  u.genre_lbl.libelle = LIBELLE_GENRE(genre)
  u.edition = genre <> "markdown" ou rogner(c.source) = ""
  APPLIQUER_MODE(c)
  MAJ_ENTETE(c)
  MARQUER_MODIFIE()
  MAJ_TITRE()
retourner

procedure EDITER_MARKDOWN(id)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul ou u = nul ou c.genre <> "markdown"
    retourner
  finsi
  u.edition = vrai
  APPLIQUER_MODE(c)
  MAJ_ENTETE(c)
  FOCUS_CELLULE(id)
retourner

procedure RENDRE_MARKDOWN(id)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul ou u = nul
    retourner
  finsi
  c.source = u.ed.valeur
  u.edition = faux
  APPLIQUER_MODE(c)
  MAJ_ENTETE(c)
retourner

procedure EFFACER_SORTIES_CELLULE(id)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul ou u = nul ou id = cellule_en_cours
    retourner
  finsi
  c.sorties = {}
  c.compteur = 0
  c.duree = nul
  SORTIES_VIDER(u)
  MAJ_ENTETE(c)
  MARQUER_MODIFIE()
retourner

procedure EFFACER_SORTIES(ev)
  pour chaque c dans carnet.cellules
    EFFACER_SORTIES_CELLULE(c.id)
  suivant
  STATUT("Sorties effacées")
retourner

&& ---------------------------------------------------------------- exécution (côté écran)

procedure EXECUTER_CHOISIE(ev)
  si cellule_choisie <> 0
    EXECUTER_CELLULE(cellule_choisie)
  finsi
retourner

procedure EXECUTER_CELLULE(id)
  locale c = CELLULE(id)
  si c = nul
    retourner
  finsi
  si c.genre = "markdown"
    RENDRE_MARKDOWN(id)
    retourner
  finsi
  c.source = UIC[id].ed.valeur
  NOYAU_SOUMETTRE(id)
retourner

procedure EXECUTER_ET_PASSER(id)
  EXECUTER_CELLULE(id)
  locale i = INDEX_CELLULE(id)
  si i = 0
    retourner
  finsi
  si i = taille(carnet.cellules)
    CHOISIR(id)
    INSERER_CELLULE("code", "", 1)
    retourner
  finsi
  locale suivante = carnet.cellules[i + 1]
  CHOISIR(suivante.id)
  FOCUS_CELLULE(suivante.id)
retourner

procedure TOUT_EXECUTER(ev)
  EXECUTER_PLAGE(1, taille(carnet.cellules))
retourner

procedure EXECUTER_PLAGE(debut, fin)
  SYNC_SOURCES()
  pour i = max(1, debut) a min(fin, taille(carnet.cellules))
    locale c = carnet.cellules[i]
    si c.genre = "markdown"
      si UIC[c.id] <> nul et UIC[c.id].edition et rogner(c.source) <> ""
        RENDRE_MARKDOWN(c.id)
      finsi
    sinon
      NOYAU_SOUMETTRE(c.id)
    finsi
  suivant
retourner

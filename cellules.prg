&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : cellules à l'écran.
&& Chaque cellule est une colonne du panneau défilant :
&&   en-tête   ▾/▸ (masquer) · [n] · genre · durée / aperçu · ☑ Export · boutons (▶ ▲ ▼ ⧉ + ✕)
&&   éditeur   ui.editeur sans onglets, hauteur ajustée au texte (code, SQL, Markdown en édition)
&&   rendu     ui.markdown ajusté (cellule de texte hors édition ; double-clic : modifier)
&&   sorties   colonne des résultats (voir sorties.prg)

fonction LIBELLE_GENRE(g)
  faire cas
  cas g = "planif"
    retourner "⏱ Planif."
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

&&
&& construction
&&

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
  MINI_RAFRAICHIR()
  planif_info_vu = ""
  PLANIF_VERIFIER()
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
  u.repli = BOUTON_CELLULE(u, "◎", "masquer", "Masquer / afficher la cellule")
  u.num = u.entete:ajouter(ui.etiquette(""))
  u.num.largeurfixe = 54
  u.num.couleur = "#60A5FA"
  u.genre_lbl = u.entete:ajouter(ui.etiquette(LIBELLE_GENRE(c.genre)))
  u.genre_lbl.largeurfixe = sisinon(c.genre = "planif", 76, 64)
  u.genre_lbl.couleur = sisinon(c.genre = "planif", "#C4B5FD", "#9CA3AF")
  si c.genre = "planif"
    && planificateur : période (liste déroulante) ; la case active le planificateur
    u.periode = u.entete:ajouter(ui.combo(PLANIF_PERIODES))
    u.periode.largeurfixe = 104
    u.periode.infobulle = "Période : durée ajoutée à l'heure de fin d'exécution pour le lancement suivant"
    essayer
      u.periode:selectionner(PLANIF_INDEX_PERIODE(c.intervalle))
    capturer e
    finessayer
    u.periode.surselection = @PLANIF_PERIODE
  finsi
  u.info = u.entete:ajouter(ui.etiquette(""))
  u.info.poids = 1
  u.info.couleur = "#9CA3AF"
  u.exp = u.entete:ajouter(ui.cases("§"))
  u.exp.largeurfixe = 40
  u.exp.infobulle = sisinon(c.genre = "planif", ;
    "Activer le planificateur (il ne tourne que si sa cellule est aussi masquée)", ;
    "Inclure la cellule dans les exports (HTML, Markdown, PDF, .prg)")
  u.exp:cocher(1, c.exporter <> faux)
  u.exp.surchangement = @EXPORT_CHANGE
  si c.genre = "planif"
    && non déplaçable, non dupliqué, non supprimé
    BOUTON_CELLULE(u, "▶", "executer", "Lancer le planificateur maintenant (s'il est actif)")
    BOUTON_CELLULE(u, "+", "ajouter", "Insérer une cellule de code dessous")
  sinon
    BOUTON_CELLULE(u, "▶", "executer", "Exécuter la cellule (Ctrl+Entrée)")
    BOUTON_CELLULE(u, "▲", "monter", "Monter")
    BOUTON_CELLULE(u, "▼", "descendre", "Descendre")
    BOUTON_CELLULE(u, "⧉", "dupliquer", "Dupliquer")
    BOUTON_CELLULE(u, "+", "ajouter", "Insérer une cellule de code dessous")
    BOUTON_CELLULE(u, "✕", "supprimer", "Supprimer la cellule")
  finsi
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

fonction BOUTON_CELLULE(u, libelle, action, aide)
  locale b = u.entete:ajouter(ui.bouton(libelle, {plat = vrai}))
  b.largeurfixe = 26
  b.infobulle = aide
  b.surclic = @CLIC_BOUTON_CELLULE
  inserer {ctl = b, id = u.id, action = action} dans BOUTONS
retourner b

&& cellule de texte : rendu Markdown, ou éditeur pendant la modification
procedure APPLIQUER_MODE(c)
  locale u = UIC[c.id]
  si u = nul
    retourner
  finsi
  && cellule masquée : seul le bandeau reste visible ; pour une cellule de code (Lexis+, SQL)
  && incluse dans les exports, le résultat reste affiché (c'est lui seul qui est exporté)
  u.sorties.visible = non c.masquee ou (c.genre <> "markdown" et c.exporter <> faux)
  si c.masquee
    u.ed.visible = faux
    u.md.visible = faux
  sinonsi c.genre = "markdown" et non u.edition
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
  && numéro = position de la cellule dans le carnet (le même que sur la minimap) ; il ne
  && change pas quand on exécute, seulement si l'on ajoute, supprime ou déplace des cellules
  locale n = NUMERO_CELLULE(c.id)
  locale info = ""
  si c.genre = "planif"
    info = PLANIF_INFO(c)
    planif_info_vu = info
  sinonsi c.genre <> "markdown"
    faire cas
    cas c.etat = "attente"
      info = "en attente"
    cas c.etat = "cours"
      info = "en cours…"
    cas c.compteur <> nul et c.compteur > 0
      si c.duree <> nul
        info = DUREE_TEXTE(c.duree)
      finsi
    fincas
  sinonsi u.edition
    info = "Maj+Entrée : afficher le rendu"
  finsi
  si c.masquee et c.genre <> "planif"
    info = sisinon(info = "", "", info + " · ") + APERCU_CELLULE(c, 70)
  finsi
  u.num.libelle = n
  u.info.libelle = info
  u.repli.libelle = sisinon(c.masquee, "◉", "◎")
  u.repli.infobulle = sisinon(c.masquee, "Afficher la cellule", "Masquer la cellule")
retourner

fonction NUMERO_CELLULE(id)
retourner "[" + NUMERO(id) + "]"

&& renumérote les bandeaux (après un ajout, une suppression ou un déplacement)
procedure NUMEROTER
  si carnet = nul
    retourner
  finsi
  locale k = 0
  pour i = 1 a taille(carnet.cellules)
    locale cc = carnet.cellules[i]
    si cc.genre <> "planif"
      k += 1
    finsi
    locale u = UIC[cc.id]
    si u <> nul
      locale n = sisinon(cc.genre = "planif", "[*]", "[" + k + "]")
      si u.num.libelle <> n
        u.num.libelle = n
      finsi
    finsi
  suivant
retourner

fonction DUREE_TEXTE(s)
  si s < 1
    retourner chaine(arrondi(s * 1000)) + " ms"
  finsi
retourner remplacertexte(chaine(arrondi(s, 2)), ".", ",") + " s"

&&
&& sélection
&&

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
  MINI_RAFRAICHIR()
retourner

procedure FOCUS_CELLULE(id)
  locale u = UIC[id]
  si u = nul
    retourner
  finsi
  && cellule masquée : ni éditeur ni texte à l'écran, rien à qui donner le focus (un contrôle
  && caché ferait défiler le carnet vers une position sans objet)
  essayer
    si u.ed.visible
      u.ed:focus()
    sinonsi u.md.visible
      u.md:focus()
    finsi
  capturer e
  finessayer
retourner

&& focus donné après la prochaine mise en page : une cellule tout juste créée ou déplacée a
&& encore l'ancienne position (ou aucune) ; le panneau défilerait vers un endroit périmé
procedure FOCUS_DIFFERE(id)
  focus_differe = id
  ui.minuterie(40, @FOCUS_DIFFERE_TIC, faux)
retourner

procedure FOCUS_DIFFERE_TIC(ev)
  locale id = focus_differe
  focus_differe = 0
  si id <> 0 et id = cellule_choisie
    FOCUS_CELLULE(id)
  finsi
retourner

fonction ID_DU_CONTROLE(ctl)
  pour chaque k, u dans UIC
    si u.ed = ctl ou u.md = ctl
      retourner u.id
    finsi
  suivant
retourner 0

&&
&& événements
&&

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
      cas b.action = "masquer"
        BASCULER_MASQUE(b.id)
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

&&
&& masquer, exporter
&&

procedure BASCULER_MASQUE(id)
  locale c = CELLULE(id)
  si c = nul
    retourner
  finsi
  SYNC_SOURCES()
  CHOISIR(id)
  c.masquee = non c.masquee
  CHANGER_AFFICHAGE(c)
  MAJ_ENTETE(c)
  MARQUER_MODIFIE()
  si c.genre = "planif"
    PLANIF_VERIFIER()
  finsi
  && pas de focus sur l'éditeur déplié : le panneau défilerait pour le montrer en entier
  && et le bandeau cliqué quitterait la position du pointeur
retourner

&& masque (masquer = vrai) ou révèle les cellules d'un genre ("code" : Lexis+, "sql", "markdown")
&& ou de tous les genres (genre = nul)
procedure MASQUER_TOUT(masquer, genre)
  SYNC_SOURCES()
  pour chaque c dans carnet.cellules
    si genre = nul ou c.genre = genre
      si c.masquee <> masquer
        c.masquee = masquer
        CHANGER_AFFICHAGE(c)
        MAJ_ENTETE(c)
      finsi
    finsi
  suivant
  MARQUER_MODIFIE()
retourner

&& Affichage › Code Lexis+ masquer / révéler (genre "code") et SQL DuckDB masquer / révéler
&& (genre "sql") : masque toutes les cellules de ce genre si l'une d'elles est affichée, sinon
&& les révèle toutes ; les cellules des autres genres ne changent pas
procedure BASCULER_GENRE(genre)
  locale masquer = faux
  pour chaque c dans carnet.cellules
    si c.genre = genre et non c.masquee
      masquer = vrai
    finsi
  suivant
  MASQUER_TOUT(masquer, genre)
  locale quoi = sisinon(genre = "sql", "Cellules SQL DuckDB", "Cellules de code Lexis+")
  STATUT(quoi + sisinon(masquer, " masquées", " révélées"))
retourner

&& Masquer ou démasquer ne change que la hauteur de la cellule, SOUS son bandeau : le
&& défilement du carnet est gardé, donc ce qui est au-dessus ne bouge pas et seul ce qui est
&& dessous monte ou descend. L'ascenseur suit la nouvelle hauteur du contenu ; tout en bas,
&& il s'arrête sur le bas de la dernière cellule (le carnet redescend si le contenu
&& raccourcit au point de laisser un vide).
procedure CHANGER_AFFICHAGE(c)
  APPLIQUER_MODE(c)
  MINI_RAFRAICHIR()
retourner

procedure EXPORT_CHANGE(ev)
  si maj_ui
    retourner
  finsi
  pour chaque k, u dans UIC
    si u.exp = ev.id
      locale c = CELLULE(u.id)
      si c <> nul
        c.exporter = u.exp:coche(1)
        CHOISIR(u.id)
        si c.masquee et c.genre <> "markdown"
          CHANGER_AFFICHAGE(c)
        finsi
        MARQUER_MODIFIE()
        si c.genre = "planif"
          PLANIF_VERIFIER()
        sinon
          STATUT(sisinon(c.exporter, "Cellule incluse dans les exports", "Cellule exclue des exports"))
        finsi
      finsi
      retourner
    finsi
  suivant
retourner

procedure BASCULER_EXPORT(id)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul ou u = nul
    retourner
  finsi
  c.exporter = non (c.exporter <> faux)
  locale etait = maj_ui
  maj_ui = vrai
  u.exp:cocher(1, c.exporter)
  maj_ui = etait
  si c.masquee et c.genre <> "markdown"
    CHANGER_AFFICHAGE(c)
  finsi
  MARQUER_MODIFIE()
  si c.genre = "planif"
    PLANIF_VERIFIER()
  sinon
    STATUT(sisinon(c.exporter, "Cellule incluse dans les exports", "Cellule exclue des exports"))
  finsi
retourner

&&
&& édition du carnet
&&

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
  si PLANIF_CELLULE() <> nul et pos < 2
    pos = 2                     && rien avant le planificateur
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
    && la nouvelle cellule est construite à la fin, puis les suivantes repassent derrière elle
    CONSTRUIRE_CELLULE(nc)
    REORDONNER_CELLULES(pos + 1)
  finsi
  CHOISIR(nc.id)
  si pos > n
    FOCUS_CELLULE(nc.id)
  sinon
    FOCUS_DIFFERE(nc.id)
  finsi
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
  locale premiere = sisinon(PLANIF_CELLULE() <> nul, 2, 1)     && le planificateur reste en tête
  si i < premiere ou j < premiere ou j > taille(carnet.cellules)
    retourner
  finsi
  SYNC_SOURCES()
  locale a = carnet.cellules[i]
  carnet.cellules[i] = carnet.cellules[j]
  carnet.cellules[j] = a
  REORDONNER_CELLULES(min(i, j))
  FOCUS_DIFFERE(id)
  MARQUER_MODIFIE()
retourner

&& remet les contrôles des cellules dans l'ordre du carnet, sans les reconstruire (éditeurs et
&& sorties gardés) : celles à partir de la position `depuis` repassent, dans l'ordre, en fin de
&& panneau (« ajouter » un contrôle déjà placé le déplace)
procedure REORDONNER_CELLULES(depuis)
  si depuis = nul ou depuis < 1
    depuis = 1
  finsi
  pour k = depuis a taille(carnet.cellules)
    locale u = UIC[carnet.cellules[k].id]
    si u <> nul
      pc:ajouter(u.bloc)
    finsi
  suivant
  NUMEROTER()
retourner

procedure DUPLIQUER(id)
  locale c = CELLULE(id)
  si c = nul ou c.genre = "planif"
    retourner
  finsi
  SYNC_SOURCES()
  CHOISIR(id)
  INSERER_CELLULE(c.genre, c.source, 1)
  && la copie garde le choix d'export de l'original
  si c.exporter = faux et cellule_choisie <> id
    BASCULER_EXPORT(cellule_choisie)
  finsi
retourner

procedure SUPPRIMER(ev)
  SUPPRIMER_CELLULE(cellule_choisie)
retourner

procedure SUPPRIMER_CELLULE(id)
  locale i = INDEX_CELLULE(id)
  si i = 0
    retourner
  finsi
  si id = cellule_en_cours ou PLANIF_TIENT(id)
    STATUT("Cellule en cours d'exécution : interrompez-la d'abord.")
    retourner
  finsi
  si carnet.cellules[i].genre = "planif"
    STATUT("Le planificateur ne se supprime pas (décochez sa case pour l'arrêter)")
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
  si taille(carnet.cellules) = 0 ou (taille(carnet.cellules) = 1 et carnet.cellules[1].genre = "planif")
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
  si c = nul ou u = nul ou c.genre = genre ou c.genre = "planif" ou genre = "planif"
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
  c.masquee = faux
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
  si c = nul ou u = nul ou id = cellule_en_cours ou PLANIF_TIENT(id)
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

&&
&& exécution (côté écran)
&&

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
  si c.genre = "planif"
    PLANIF_MAINTENANT()
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
    sinonsi c.genre <> "planif"
      && (le planificateur ne s'exécute qu'en tâche de fond)
      NOYAU_SOUMETTRE(c.id)
    finsi
  suivant
retourner

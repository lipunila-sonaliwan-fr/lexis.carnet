&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : résultats affichés sous les cellules.
&&   texte    sortie de ? (bloc à chasse fixe, regroupée au fil de l'exécution)
&&   valeur   afficher(x) d'une valeur
&&   markdown afficher_md(texte)
&&   table    afficher_table / afficher_sql / afficher(liste de fiches) : grille
&&   graphe   afficher_graphe : colonnes, lignes, aires, secteurs
&&   erreur   message, ligne de la cellule et pile d'appels

procedure SORTIES_VIDER(u)
  pour chaque x dans u.ctrls
    essayer
      x:detruire()
    capturer e
    finessayer
  suivant
  u.ctrls = {}
  u.texte_ctl = nul
retourner

fonction BLOC_CODE(t)
  locale lignes = decouper(t, car(10))
  locale n = taille(lignes)
  locale tete = ""
  si n > MAX_LIGNES_AFFICHEES
    locale garde = {}
    pour i = n - MAX_LIGNES_AFFICHEES + 1 a n
      inserer lignes[i] dans garde
    suivant
    tete = "*… " + (n - MAX_LIGNES_AFFICHEES) + " lignes plus haut (complètes dans l'export)*" + car(10) + car(10)
    t = joindre(garde, car(10))
  finsi
  si rogner(t) = ""
    t = " "
  finsi
retourner tete + "```" + car(10) + remplacertexte(t, "```", "ʼʼʼ") + car(10) + "```"

&& affiche une sortie (enregistrée ou reçue du noyau) sous la cellule
procedure SORTIE_CONTROLE(u, s)
  locale g = minuscule(chaine(s.genre))
  faire cas
  cas g = "texte" ou g = "valeur"
    locale md = u.sorties:ajouter(ui.markdown{texte = BLOC_CODE(chaine(s.texte)), ajuster = vrai, hauteurmax = 420})
    inserer md dans u.ctrls
    si g = "texte"
      u.texte_ctl = md
    sinon
      u.texte_ctl = nul
    finsi
  cas g = "markdown"
    locale mdx = u.sorties:ajouter(ui.markdown{texte = chaine(s.texte), ajuster = vrai})
    inserer mdx dans u.ctrls
    u.texte_ctl = nul
  cas g = "table"
    SORTIE_TABLE(u, s)
    u.texte_ctl = nul
  cas g = "graphe"
    SORTIE_GRAPHE(u, s)
    u.texte_ctl = nul
  cas g = "erreur"
    locale titre = "⚠ Erreur"
    si s.ligne <> nul et s.ligne > 0
      titre = titre + " — ligne " + s.ligne + " de la cellule"
    finsi
    locale l = u.sorties:ajouter(ui.etiquette(titre))
    l.couleur = "#F87171"
    inserer l dans u.ctrls
    locale mde = u.sorties:ajouter(ui.markdown{texte = BLOC_CODE(chaine(s.texte)), ajuster = vrai, hauteurmax = 420})
    inserer mde dans u.ctrls
    u.texte_ctl = nul
  fincas
retourner

procedure SORTIE_TABLE(u, s)
  locale cols = s.colonnes
  si cols = nul
    cols = {}
  finsi
  locale lignes = s.lignes
  si lignes = nul
    lignes = {}
  finsi
  locale total = sisinon(s.total = nul, taille(lignes), s.total)
  locale resume = chaine(total) + " ligne" + sisinon(total > 1, "s", "") + " · " + taille(cols) + " colonne" + ;
                  sisinon(taille(cols) > 1, "s", "")
  si total > taille(lignes)
    resume = resume + " (les " + taille(lignes) + " premières sont affichées)"
  finsi
  locale l = u.sorties:ajouter(ui.etiquette(resume))
  l.couleur = "#9CA3AF"
  inserer l dans u.ctrls
  si taille(cols) = 0
    retourner
  finsi
  locale gr = u.sorties:ajouter(ui.grille())
  inserer gr dans u.ctrls
  locale largeur_totale = 0
  pour i = 1 a taille(cols)
    locale lg = longueur(chaine(cols[i]))
    pour j = 1 a min(taille(lignes), 60)
      locale r = lignes[j]
      si i <= taille(r)
        lg = max(lg, longueur(chaine(r[i])))
      finsi
    suivant
    locale px = max(70, min(340, lg * 9 + 40))
    largeur_totale += px
    gr:ajoutercolonne{nom = "c" + i, titre = chaine(cols[i]), largeur = px}
  suivant
  pour chaque r dans lignes
    locale ligne = {}
    pour i = 1 a taille(cols)
      locale v = ""
      si i <= taille(r) et r[i] <> nul
        v = chaine(r[i])
      finsi
      inserer v dans ligne
    suivant
    gr:ajouterligne(ligne)
  suivant
  essayer
    gr:fixermodifiable(faux)
  capturer e
  finessayer
  gr.hauteurfixe = 34 + 26 * max(1, min(taille(lignes), 12))
retourner

fonction FORME_GRAPHE(f)
  f = minuscule(chaine(f))
  faire cas
  cas f = "lignes" ou f = "ligne" ou f = "courbe" ou f = "courbes"
    retourner "lignes"
  cas f = "aires" ou f = "aire"
    retourner "aires"
  cas f = "secteurs" ou f = "camembert" ou f = "secteur"
    retourner "secteurs"
  fincas
retourner "colonnes"

procedure SORTIE_GRAPHE(u, s)
  locale gr = u.sorties:ajouter(ui.graphe(FORME_GRAPHE(s.forme), chaine(sisinon(s.titre = nul, "", s.titre))))
  inserer gr dans u.ctrls
  gr.hauteurfixe = 320
  locale si_ = 0
  pour chaque serie dans s.series
    si_ += 1
    locale nom = chaine(sisinon(serie.nom = nul, "", serie.nom))
    si nom = ""
      nom = "Série " + si_
    finsi
    gr:libelleserie(si_, nom)
    locale ci = 0
    pour chaque v dans serie.valeurs
      ci += 1
      gr:ajouterdonnee(si_, ci, valeur(chaine(v)))
    suivant
  suivant
  locale ci2 = 0
  pour chaque cat dans s.categories
    ci2 += 1
    gr:libellecategorie(ci2, chaine(cat))
  suivant
retourner

&& ---------------------------------------------------------------- réception (noyau)

procedure SORTIE_RECUE(id, s)
  locale c = CELLULE(id)
  locale u = UIC[id]
  si c = nul
    retourner
  finsi
  inserer s dans c.sorties
  si u <> nul
    SORTIE_CONTROLE(u, s)
  finsi
retourner

procedure SORTIE_TEXTE(id, ligne)
  locale c = CELLULE(id)
  si c = nul
    retourner
  finsi
  locale n = taille(c.sorties)
  si n > 0 et c.sorties[n].genre = "texte"
    locale s = c.sorties[n]
    si longueur(s.texte) < MAX_TEXTE
      s.texte = s.texte + car(10) + ligne
    finsi
    locale u = UIC[id]
    si u <> nul et u.texte_ctl <> nul
      u.texte_ctl.valeur = BLOC_CODE(s.texte)
      essayer
        u.texte_ctl:defilera("fin")
      capturer e
      finessayer
      retourner
    finsi
    si u <> nul
      SORTIE_CONTROLE(u, s)
    finsi
    retourner
  finsi
  SORTIE_RECUE(id, {genre = "texte", texte = ligne})
retourner

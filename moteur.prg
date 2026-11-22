&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : noyau d'exécution.
&&
&& Le noyau est un interpréteur Lexis+ séparé (lexis.executer) qui exécute
&& ressources/noyau.lxk, copié dans un dossier temporaire :
&&   <tmp>/noyau/noyau.prg        le programme du noyau
&&   <tmp>/cellules/c_<id>.prg    une procédure NB_CELLULE_<id> par cellule
&&   <tmp>/cellules/procedures.prg  procédures et fonctions définies dans les cellules
&& Les variables non déclarées d'une cellule sont globales : elles restent d'une
&& cellule à l'autre, jusqu'au redémarrage du noyau.
&&
&& Protocole (lignes de sortie commençant par car(30)) :
&&   NB:pret                 le noyau attend une commande (suivi d'une demande de saisie)
&&   NB:debut:<ident>        début d'exécution
&&   NB:sortie:<json>        sortie enrichie (valeur, table, graphe, markdown)
&&   NB:fin:<ident>:ok:<s>   fin normale, durée en secondes
&&   NB:fin:<ident>:erreur:<json>  fin en erreur : message et pile d'appels
&& Les autres lignes sont la sortie texte de la cellule ; une demande de saisie
&& qui ne suit pas NB:pret vient d'un saisir() de la cellule.

fonction CHEMIN_NOYAU()
retourner fichier.joindre(noyau_dossier, "noyau", "noyau.prg")

fonction DOSSIER_CELLULES()
retourner fichier.joindre(noyau_dossier, "cellules")

procedure NOYAU_ETAT(m)
  noyau_etat = m
  essayer
    lbl_noyau.libelle = "Noyau : " + m
    lbl_noyau.couleur = sisinon(commencepar(m, "occupé"), "#FBBF24", sisinon(m = "prêt", "#34D399", "#9CA3AF"))
  capturer e
  finessayer
retourner

procedure NOYAU_DEMARRER
  si noyau_dossier = ""
    noyau_dossier = systeme.nomtemporaire() + "-carnet"
  finsi
  noyau_pret = faux
  pret_annonce = faux
  noyau_tampon = ""
  arret_voulu = faux
  defs_procs = {}
  ordre_procs = {}
  cartes = {}
  carte_procs = {}
  essayer
    fichier.creerdossier(fichier.joindre(noyau_dossier, "noyau"))
    fichier.creerdossier(DOSSIER_CELLULES())
    fichier.ecrire(CHEMIN_NOYAU(), fichier.lire(fichier.joindre(systeme.dossierprogramme(), "ressources", "noyau.lxk")))
    fichier.ecrire(fichier.joindre(DOSSIER_CELLULES(), "procedures.prg"), "")
    noyau_x = lexis.executer(CHEMIN_NOYAU(), {sursortie = @NOYAU_SORTIE, surdemande = @NOYAU_DEMANDE, surfin = @NOYAU_FIN})
    NOYAU_ETAT("démarrage…")
  capturer e
    noyau_x = nul
    NOYAU_ETAT("indisponible")
    STATUT("Noyau indisponible : " + chaine(e))
  finessayer
  NOYAU_DOSSIER_COURANT()
retourner

&& le dossier courant du noyau est celui du carnet (fichiers de données relatifs)
procedure NOYAU_DOSSIER_COURANT
  si chemin_carnet = "" ou noyau_x = nul
    retourner
  finsi
  inserer "§dossier|" + fichier.dossier(chemin_carnet) dans file_attente position 1
  NOYAU_POMPER()
retourner

procedure NOYAU_TERMINER
  quitter_demande = vrai
  essayer
    si noyau_x <> nul et noyau_x:actif()
      noyau_x:arreter()
    finsi
  capturer e
  finessayer
  essayer
    si noyau_dossier <> "" et fichier.existe(noyau_dossier)
      fichier.supprimer(noyau_dossier)
    finsi
  capturer e
  finessayer
retourner

procedure INTERROMPRE(ev)
  si noyau_x = nul ou (cellule_en_cours = 0 et taille(file_attente) = 0)
    STATUT("Rien à interrompre.")
    retourner
  finsi
  ANNULER_FILE()
  arret_voulu = vrai
  relances = 0
  NOYAU_ETAT("interruption…")
  STATUT("Exécution interrompue : le noyau redémarre.")
  essayer
    noyau_x:arreter()
  capturer e
  finessayer
retourner

procedure REDEMARRER(ev)
  relances = 0
  si noyau_x <> nul et noyau_x:actif()
    arret_voulu = vrai
    NOYAU_ETAT("redémarrage…")
    noyau_x:arreter()
  sinon
    NOYAU_DEMARRER()
  finsi
  STATUT("Noyau redémarré : les variables et procédures des cellules sont effacées.")
retourner

&& ---------------------------------------------------------------- file d'attente

procedure NOYAU_SOUMETTRE(id)
  locale c = CELLULE(id)
  si c = nul ou id = cellule_en_cours ou contient(file_attente, id)
    retourner
  finsi
  si noyau_x = nul
    NOYAU_DEMARRER()
  finsi
  c.etat = "attente"
  MAJ_ENTETE(c)
  inserer id dans file_attente
  NOYAU_POMPER()
retourner

procedure ANNULER_FILE
  pour chaque x dans file_attente
    si type(x) = "nombre"
      locale c = CELLULE(x)
      si c <> nul
        c.etat = ""
        MAJ_ENTETE(c)
      finsi
    finsi
  suivant
  file_attente = {}
retourner

procedure RETIRER_DE_FILE(id)
  locale reste = {}
  pour chaque x dans file_attente
    si x <> id
      inserer x dans reste
    finsi
  suivant
  file_attente = reste
retourner

procedure NOYAU_POMPER
  tantque noyau_pret et cellule_en_cours = 0 et taille(file_attente) > 0
    locale x = retirer(file_attente, 1)
    si type(x) = "chaine"
      noyau_pret = faux
      noyau_x:envoyer(x)
      retourner
    finsi
    locale c = CELLULE(x)
    si c <> nul
      LANCER_CELLULE(c)
    finsi
  fintantque
retourner

procedure LANCER_CELLULE(c)
  locale u = UIC[c.id]
  c.sorties = {}
  si u <> nul
    SORTIES_VIDER(u)
    essayer
      u.ed:diagnostics({})
    capturer e
    finessayer
  finsi
  locale prep = PREPARER_CELLULE(c)
  si prep.erreur <> nul
    && erreur de syntaxe : la cellule n'est pas envoyée au noyau
    c.etat = ""
    SORTIE_RECUE(c.id, {genre = "erreur", texte = prep.erreur, ligne = prep.ligne})
    MAJ_ENTETE(c)
    ANNULER_FILE()
    MARQUER_MODIFIE()
    retourner
  finsi
  c.etat = "cours"
  MAJ_ENTETE(c)
  exec_seq += 1
  cellule_en_cours = c.id
  exec_en_cours = chaine(c.id) + "." + chaine(exec_seq)
  noyau_pret = faux
  NOYAU_ETAT("occupé (cellule " + INDEX_CELLULE(c.id) + ")")
  noyau_x:envoyer("X|" + prep.procs + "|" + prep.fichier + "|NB_CELLULE_" + c.id + "|" + exec_en_cours)
retourner

&& ---------------------------------------------------------------- préparation d'une cellule

fonction NOM_DEFINITION(lt)
  locale p = position(" ", lt)
  locale reste = rogner(souschaine(lt, p + 1))
  locale q = position("(", reste)
  si q > 0
    reste = gauche(reste, q - 1)
  finsi
  q = position(" ", reste)
  si q > 0
    reste = gauche(reste, q - 1)
  finsi
retourner majuscule(rogner(reste))

fonction EST_DEFINITION(lt)
retourner commencepar(lt, "procedure ") ou commencepar(lt, "fonction ") ou ;
          commencepar(lt, "procédure ")

fonction RETRAIT(l)
retourner longueur(l) - longueur(rognerg(l))

fonction LITTERAL(t)
  si position("]]", t) = 0 et non finitpar(t, "]")
    retourner "[[" + t + "]]"
  finsi
retourner json(t)

&& découpe un script SQL en instructions (fin : « ; » en fin de ligne)
fonction DECOUPER_SQL(src)
  locale res = {}
  locale cour = {}
  locale debut = 0
  locale i = 0
  pour chaque l dans decouper(src, car(10))
    i += 1
    locale lr = rogner(l)
    si lr = "" ou commencepar(lr, "--")
      si taille(cour) = 0
        boucler
      finsi
    finsi
    si taille(cour) = 0
      debut = i
    finsi
    si finitpar(lr, ";")
      inserer gauche(rognerd(l), longueur(rognerd(l)) - 1) dans cour
      inserer {texte = joindre(cour, car(10)), ligne = debut, nb = taille(cour)} dans res
      cour = {}
    sinon
      inserer l dans cour
    finsi
  suivant
  si taille(cour) > 0
    locale t = rogner(joindre(cour, car(10)))
    si t <> ""
      inserer {texte = joindre(cour, car(10)), ligne = debut, nb = taille(cour)} dans res
    finsi
  finsi
retourner res

&& écrit c_<id>.prg et procedures.prg ; vérifie la syntaxe.
&& renvoie {fichier, procs, erreur, ligne}
fonction PREPARER_CELLULE(c)
  locale lignes = decouper(remplacertexte(c.source, car(13), ""), car(10))
  && les procédures déjà définies par cette cellule sont remplacées
  pour chaque nom dans ordre_procs
    locale d = defs_procs[nom]
    si d <> nul et d.id = c.id
      defs_procs[nom] = nul
    finsi
  suivant
  locale corps = {"procedure NB_CELLULE_" + c.id}
  locale carte = {0}
  si c.genre = "sql"
    locale instr = DECOUPER_SQL(c.source)
    pour k = 1 a taille(instr)
      locale st = instr[k]
      locale appel = sisinon(k = taille(instr), "AFFICHER_SQL(", "requete(") + LITTERAL(st.texte) + ")"
      inserer appel dans corps
      pour j = 1 a taille(decouper(appel, car(10)))
        inserer st.ligne dans carte
      suivant
    suivant
  sinon
    locale i = 1
    locale n = taille(lignes)
    tantque i <= n
      locale l = lignes[i]
      locale lt = minuscule(rognerg(l))
      si EST_DEFINITION(lt)
        locale retrait0 = RETRAIT(l)
        locale nom = NOM_DEFINITION(lt)
        locale bloc_def = {}
        tantque i <= n
          locale li = lignes[i]
          inserer {li, i} dans bloc_def
          i += 1
          si taille(bloc_def) > 1 et commencepar(minuscule(rognerg(li)), "retourner") et RETRAIT(li) = retrait0
            sortir
          finsi
        fintantque
        si non contient(ordre_procs, nom)
          inserer nom dans ordre_procs
        finsi
        defs_procs[nom] = {id = c.id, lignes = bloc_def}
      sinon
        inserer l dans corps
        inserer i dans carte
        i += 1
      finsi
    fintantque
  finsi
  inserer "retourner" dans corps
  inserer 0 dans carte
  cartes[c.id] = carte
  locale chemin_c = fichier.joindre(DOSSIER_CELLULES(), "c_" + c.id + ".prg")
  locale texte_c = joindre(corps, car(10)) + car(10)
  fichier.ecrire(chemin_c, texte_c)
  && procédures de toutes les cellules, dans l'ordre de leur première définition
  locale plignes = {}
  carte_procs = {}
  pour chaque nom dans ordre_procs
    locale d = defs_procs[nom]
    si d <> nul
      pour chaque x dans d.lignes
        inserer x[1] dans plignes
        inserer {id = d.id, ligne = x[2]} dans carte_procs
      suivant
      inserer "" dans plignes
      inserer {id = d.id, ligne = 0} dans carte_procs
    finsi
  suivant
  locale chemin_p = fichier.joindre(DOSSIER_CELLULES(), "procedures.prg")
  locale texte_p = joindre(plignes, car(10)) + car(10)
  fichier.ecrire(chemin_p, texte_p)
  && vérification (syntaxe) : les erreurs empêchent l'exécution
  locale res = {fichier = chemin_c, procs = sisinon(taille(plignes) > 0, chemin_p, ""), erreur = nul, ligne = 0}
  locale diags = {}
  locale messages = {}
  essayer
    pour chaque dg dans lexis.verifier(texte_c, {appelsinconnus = faux})
      locale ln = LIGNE_CARTE(carte, dg.ligne)
      dg.message = MESSAGE_CARTE(chaine(dg.message), carte)
      DIAG_CELLULE(dg, ln, c.id, c.id, diags, messages, res)
    suivant
    si taille(plignes) > 0
      pour chaque dg dans lexis.verifier(texte_p, {appelsinconnus = faux})
        si dg.ligne >= 1 et dg.ligne <= taille(carte_procs)
          locale cp = carte_procs[dg.ligne]
          DIAG_CELLULE(dg, cp.ligne, cp.id, c.id, diags, messages, res)
        finsi
      suivant
    finsi
  capturer e
  finessayer
  locale u = UIC[c.id]
  si u <> nul
    essayer
      u.ed:diagnostics(diags)
    capturer e
    finessayer
  finsi
  si taille(messages) > 0
    res.erreur = joindre(messages, car(10))
  finsi
retourner res

&& ligne de la cellule pour une ligne du fichier généré (l'en-tête et le « retourner »
&& ajoutés renvoient à la première et à la dernière ligne de la cellule)
fonction LIGNE_CARTE(carte, n)
  si n = nul ou n < 1
    retourner 1
  finsi
  si n <= taille(carte) et carte[n] > 0
    retourner carte[n]
  finsi
  locale dernier = 1
  pour chaque x dans carte
    dernier = max(dernier, x)
  suivant
  si n <= 1
    retourner 1
  finsi
retourner dernier

&& « (ligne n) » dans un message de vérification -> ligne de la cellule
fonction MESSAGE_CARTE(msg, carte)
  locale p = position("(ligne ", msg)
  si p = 0
    retourner msg
  finsi
  locale f = p + 7
  tantque f <= longueur(msg) et position(souschaine(msg, f, 1), "0123456789") > 0
    f += 1
  fintantque
  si f = p + 7
    retourner msg
  finsi
  locale n = valeur(souschaine(msg, p + 7, f - p - 7))
retourner gauche(msg, p - 1) + "(ligne " + LIGNE_CARTE(carte, n) + souschaine(msg, f)

procedure DIAG_CELLULE(dg, ln, idcell, idcourant, diags, messages, res)
  locale g = chaine(dg.genre)
  si g = "info"
    retourner
  finsi
  si idcell = idcourant et ln > 0
    inserer {ligne = ln, colonne = sisinon(dg.colonne = nul, 1, dg.colonne), longueur = sisinon(dg.longueur = nul, 1, dg.longueur), ;
             genre = g, message = dg.message} dans diags
  finsi
  si g = "erreur"
    locale ou_ = LIBELLE_LIEU(idcell, ln, idcourant)
    inserer ou_ + " : " + chaine(dg.message) dans messages
    si res.ligne = 0 et idcell = idcourant
      res.ligne = ln
    finsi
  finsi
retourner

&& ---------------------------------------------------------------- réception

procedure NOYAU_SORTIE(t)
  noyau_tampon = noyau_tampon + t
  si position(car(10), noyau_tampon) = 0
    retourner
  finsi
  locale morceaux = decouper(noyau_tampon, car(10))
  locale n = taille(morceaux)
  noyau_tampon = morceaux[n]
  pour i = 1 a n - 1
    NOYAU_LIGNE(remplacertexte(morceaux[i], car(13), ""))
  suivant
retourner

procedure NOYAU_LIGNE(l)
  si commencepar(l, car(30) + "NB:")
    VIDER_TEXTE()
    locale m = souschaine(l, 5)
    faire cas
    cas m = "pret"
      pret_annonce = vrai
    cas commencepar(m, "sortie:")
      si cellule_en_cours <> 0
        essayer
          SORTIE_RECUE(cellule_en_cours, dejson(souschaine(m, 8)))
        capturer e
          SORTIE_TEXTE(cellule_en_cours, "(sortie illisible : " + chaine(e) + ")")
        finessayer
      finsi
    cas commencepar(m, "fin:")
      NOYAU_FIN_CELLULE(souschaine(m, 5))
    fincas
    retourner
  finsi
  si cellule_en_cours <> 0
    si texte_attente_id <> cellule_en_cours
      VIDER_TEXTE()
      texte_attente_id = cellule_en_cours
    finsi
    inserer l dans texte_attente
  finsi
retourner

&& la sortie texte est affichée par paquets (minuterie), pas ligne à ligne
procedure VIDER_TEXTE
  si taille(texte_attente) = 0
    retourner
  finsi
  locale lignes = texte_attente
  texte_attente = {}
  SORTIE_TEXTE(texte_attente_id, joindre(lignes, car(10)))
retourner

procedure VIDER_TEXTE_TIC(ev)
  essayer
    VIDER_TEXTE()
  capturer e
  finessayer
retourner

procedure NOYAU_FIN_CELLULE(r)
  locale p = position(":", r)
  locale ident = gauche(r, p - 1)
  locale reste = souschaine(r, p + 1)
  si ident <> exec_en_cours
    retourner
  finsi
  locale c = CELLULE(cellule_en_cours)
  cellule_en_cours = 0
  exec_en_cours = ""
  si c = nul
    retourner
  finsi
  exec_compteur += 1
  c.compteur = exec_compteur
  c.etat = ""
  si commencepar(reste, "ok:")
    c.duree = valeur(souschaine(reste, 4))
  sinon
    c.duree = nul
    locale trace = souschaine(reste, 8)
    essayer
      trace = dejson(trace)
    capturer e
    finessayer
    ERREUR_CELLULE(c, chaine(trace))
    ANNULER_FILE()
  finsi
  MAJ_ENTETE(c)
  MARQUER_MODIFIE()
  NOYAU_ETAT("prêt")
retourner

procedure NOYAU_DEMANDE(invite)
  si pret_annonce
    pret_annonce = faux
    noyau_pret = vrai
    relances = 0
    si cellule_en_cours = 0 et taille(file_attente) = 0
      NOYAU_ETAT("prêt")
    finsi
    NOYAU_POMPER()
    si lot_actif et cellule_en_cours = 0 et taille(file_attente) = 0
      LOT_TERMINER()
    finsi
    retourner
  finsi
  && saisir() appelé par le code d'une cellule
  VIDER_TEXTE()
  locale id = cellule_en_cours
  locale invite_txt = chaine(sisinon(invite = nul, "", invite))
  locale deja = noyau_tampon
  noyau_tampon = ""
  locale rep = ui.demander(sisinon(rogner(invite_txt) = "", "Saisie demandée par la cellule :", invite_txt), "")
  si rep = nul
    rep = ""
  finsi
  si id <> 0
    si deja <> ""
      SORTIE_TEXTE(id, deja + rep)
    sinon
      SORTIE_TEXTE(id, "» " + rep)
    finsi
  finsi
  essayer
    noyau_x:envoyer(rep)
  capturer e
  finessayer
retourner

procedure NOYAU_FIN(ev)
  VIDER_TEXTE()
  noyau_pret = faux
  pret_annonce = faux
  noyau_tampon = ""
  si quitter_demande
    retourner
  finsi
  si cellule_en_cours <> 0
    locale c = CELLULE(cellule_en_cours)
    si c <> nul
      locale msg = "Exécution interrompue : le noyau a redémarré, les variables sont effacées."
      si non arret_voulu
        msg = "Le noyau s'est arrêté : " + chaine(ev.message)
      finsi
      SORTIE_RECUE(c.id, {genre = "erreur", texte = msg, ligne = 0})
      c.etat = ""
      MAJ_ENTETE(c)
    finsi
    cellule_en_cours = 0
    exec_en_cours = ""
  finsi
  si non arret_voulu
    ANNULER_FILE()
    relances += 1
  finsi
  si relances > 5
    NOYAU_ETAT("arrêté (trop de redémarrages)")
    noyau_x = nul
    retourner
  finsi
  NOYAU_DEMARRER()
retourner

&& ---------------------------------------------------------------- erreurs d'exécution

&& {fichier, n, debut, fin} de la première référence « nom.prg:n » à partir de depart
fonction REF_SUIVANTE(l, depart)
  locale p = position(".prg:", souschaine(l, depart))
  si p = 0
    retourner nul
  finsi
  p = p + depart - 1
  locale d = p
  tantque d > 1
    locale ch = souschaine(l, d - 1, 1)
    si ch = "/" ou ch = "\\" ou ch = " " ou ch = "("
      sortir
    finsi
    d -= 1
  fintantque
  locale f = p + 5
  tantque f <= longueur(l) et position(souschaine(l, f, 1), "0123456789") > 0
    f += 1
  fintantque
  si f = p + 5
    retourner {fichier = "", n = 0, debut = d, fin = f - 1, suite = f}
  finsi
retourner {fichier = souschaine(l, d, p - d), n = valeur(souschaine(l, p + 5, f - p - 5)), debut = d, fin = f - 1, suite = f}

&& {id, ligne} d'une référence c_<id>.prg:n ou procedures.prg:n, nul sinon
fonction LIEU_CELLULE(ref)
  si ref = nul
    retourner nul
  finsi
  si ref.fichier = "procedures"
    si ref.n >= 1 et ref.n <= taille(carte_procs)
      retourner carte_procs[ref.n]
    finsi
    retourner nul
  finsi
  si commencepar(ref.fichier, "c_")
    locale id = valeur(souschaine(ref.fichier, 3))
    locale carte = cartes[id]
    si carte <> nul et ref.n >= 1 et ref.n <= taille(carte)
      retourner {id = id, ligne = carte[ref.n]}
    finsi
  finsi
retourner nul

&& désignation d'une cellule dans un message : « ligne n » pour la cellule exécutée,
&& « cellule [compteur] » (ou « cellule n° position ») pour une autre
fonction LIBELLE_LIEU(id, ligne, idcourant)
  si id = idcourant
    retourner "ligne " + ligne
  finsi
  locale c = CELLULE(id)
  si c <> nul et c.compteur <> nul et c.compteur > 0
    retourner "cellule [" + c.compteur + "], ligne " + ligne
  finsi
retourner "cellule n° " + INDEX_CELLULE(id) + ", ligne " + ligne

&& pile d'appels du noyau -> références aux cellules du carnet
fonction TRADUIRE_PILE(trace, idcourant)
  locale res = {}
  locale dc = DOSSIER_CELLULES()
  locale premiere = vrai
  pour chaque l dans decouper(trace, car(10))
    si contient(l, "noyau.prg") et premiere
      && erreur levée dans une aide du noyau (afficher_sql…) : le message seul
      locale p = position("noyau.prg:", l)
      locale reste = souschaine(l, p + 10)
      locale q = position(": ", reste)
      l = sisinon(q > 0, souschaine(reste, q + 2), reste)
    sinonsi contient(l, "noyau.prg") ou contient(l, "[intégrée] appeler")
      boucler
    finsi
    premiere = faux
    l = remplacertexte(remplacertexte(l, dc + "/", ""), dc + "\\", "")
    locale q = position(" dans NB_CELLULE_", l)
    si q > 0
      l = gauche(l, q - 1)
    finsi
    locale sortie = ""
    locale depart = 1
    tantque vrai
      locale ref = REF_SUIVANTE(l, depart)
      si ref = nul
        sortir
      finsi
      locale lieu = LIEU_CELLULE(ref)
      sortie = sortie + souschaine(l, depart, ref.debut - depart)
      si lieu <> nul
        sortie = sortie + LIBELLE_LIEU(lieu.id, lieu.ligne, idcourant)
      sinon
        sortie = sortie + souschaine(l, ref.debut, ref.fin - ref.debut + 1)
      finsi
      depart = ref.suite
    fintantque
    sortie = sortie + souschaine(l, depart)
    inserer sortie dans res
  suivant
retourner rogner(joindre(res, car(10)))

procedure ERREUR_CELLULE(c, trace)
  locale lieu = nul
  locale premiere = decouper(trace, car(10))[1]
  locale depart = 1
  tantque lieu = nul
    locale ref = REF_SUIVANTE(trace, depart)
    si ref = nul
      sortir
    finsi
    lieu = LIEU_CELLULE(ref)
    depart = ref.suite
  fintantque
  locale ligne = 0
  si lieu <> nul et lieu.id = c.id
    ligne = lieu.ligne
  finsi
  SORTIE_RECUE(c.id, {genre = "erreur", texte = TRADUIRE_PILE(trace, c.id), ligne = ligne})
  && soulignement dans l'éditeur de la cellule fautive
  si lieu <> nul et lieu.ligne > 0
    locale u = UIC[lieu.id]
    si u <> nul
      locale msg = premiere
      locale p = position(": ", msg)
      si p > 0
        msg = souschaine(msg, p + 2)
      finsi
      essayer
        u.ed:diagnostics({{ligne = lieu.ligne, colonne = 1, longueur = 200, genre = "erreur", message = msg}})
      capturer e
      finessayer
    finsi
  finsi
retourner

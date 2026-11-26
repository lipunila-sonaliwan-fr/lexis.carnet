&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : planificateur.
&& La première cellule du carnet, notée [*] (icône ⏱, non déplaçable), contient du code Lexis+
&& lancé en tâche de fond sur un noyau dédié (un second interpréteur, comme le noyau principal),
&& à la période choisie dans la liste de son bandeau (+10s … +1h).
&&   - actif seulement si la cellule est masquée ET sa case cochée ; sinon le planificateur
&&     s'arrête : la tâche en cours est interrompue (son noyau est arrêté) et les cellules
&&     qu'elle exécutait retrouvent le résultat qu'elles avaient avant son lancement ;
&&   - au passage à l'état actif, le code est lancé tout de suite ; à la fin de chaque
&&     exécution, la période est ajoutée à l'heure courante : c'est le prochain lancement,
&&     affiché dans le bandeau ;
&&   - dans ce code, executer_cellule(n) exécute la cellule [n] et executer_depuis(n) les
&&     cellules de [n] à la fin (code Lexis+ et SQL seulement) ; une cellule affichée (non
&&     masquée), de texte ou déjà en cours n'est pas exécutée : l'appel est sans effet.
&& Protocole (voir ressources/noyau.lxk) : le noyau du planificateur écrit
&& « NB:demande:cellule:<n> » ou « NB:demande:liste:<n> » puis attend une saisie ; la réponse
&& est une commande X|… (code de la cellule préparé comme pour le noyau principal), la liste
&& des numéros à exécuter, ou « §refus ». Les sorties vont à la cellule en haut de la pile
&& (le planificateur, puis la cellule qu'il exécute).

fonction PLANIF_SECONDES_DE(t)
  pour i = 1 a taille(PLANIF_PERIODES)
    si PLANIF_PERIODES[i] = t
      retourner PLANIF_SECONDES[i]
    finsi
  suivant
retourner 60

fonction PLANIF_INDEX_PERIODE(t)
  pour i = 1 a taille(PLANIF_PERIODES)
    si PLANIF_PERIODES[i] = t
      retourner i
    finsi
  suivant
retourner 3

procedure PLANIF_CREER
  planif_minuterie = ui.minuterie(500, @PLANIF_TIC)
retourner

&& pas de planificateur en exécution en lot (--executer, --exporter, --quitter)
fonction PLANIF_PERMIS()
retourner non (lot_executer ou lot_quitter ou taille(lot_exports) > 0)

fonction PLANIF_VOULU(c)
  si c = nul
    retourner faux
  finsi
  si non c.masquee ou c.exporter = faux
    retourner faux
  finsi
retourner PLANIF_PERMIS()

&& vrai si la cellule est en cours dans le planificateur
fonction PLANIF_TIENT(id)
  pour chaque e dans planif_pile
    si e.id = id
      retourner vrai
    finsi
  suivant
retourner faux

&& cellule qui reçoit les sorties du noyau du planificateur
fonction PLANIF_SOMMET()
  locale n = taille(planif_pile)
  si n = 0
    retourner 0
  finsi
retourner planif_pile[n].id

&& active ou arrête le planificateur selon l'état de sa cellule (masquée, case cochée)
procedure PLANIF_VERIFIER
  locale c = PLANIF_CELLULE()
  locale id = 0
  si c <> nul
    id = c.id
  finsi
  si planif_id <> id
    && autre carnet : l'ancien planificateur s'arrête (ses cellules n'existent plus)
    si planif_actif ou planif_x <> nul
      PLANIF_ARRETER(faux)
    finsi
    planif_actif = faux
    planif_id = id
    planif_derniere_fin = 0
    planif_prochaine_txt = ""
  finsi
  locale voulu = PLANIF_VOULU(c)
  si voulu et non planif_actif
    planif_actif = vrai
    planif_prochaine = horodatage()        && premier lancement : tout de suite
    planif_prochaine_txt = ""
    PLANIF_DEMARRER()
    STATUT("Planificateur actif : lancement toutes les " + PERIODE_TEXTE(c.intervalle))
  sinonsi non voulu et planif_actif
    planif_actif = faux
    locale coupe = taille(planif_pile) > 0
    PLANIF_ARRETER(vrai)
    si coupe
      STATUT("Planificateur arrêté : tâche interrompue, résultats d'avant son lancement restitués")
    sinon
      STATUT("Planificateur arrêté")
    finsi
  finsi
  PLANIF_ENTETE()
retourner

fonction PERIODE_TEXTE(t)
  locale s = PLANIF_SECONDES_DE(t)
  faire cas
  cas s < 60
    retourner s + " s"
  cas s < 3600
    retourner (s / 60) + " min"
  fincas
retourner (s / 3600) + " h"

procedure PLANIF_DEMARRER
  si planif_x <> nul
    retourner
  finsi
  planif_pret = faux
  planif_annonce = faux
  planif_requete = ""
  planif_tampon = ""
  planif_texte = {}
  planif_dossier_envoye = faux
  essayer
    si noyau_dossier = "" ou non fichier.existe(CHEMIN_NOYAU())
      erreur "noyau indisponible"
    finsi
    planif_x = lexis.executer(CHEMIN_NOYAU(), {sursortie = @PLANIF_SORTIE, surdemande = @PLANIF_DEMANDE, surfin = @PLANIF_FIN})
  capturer e
    planif_x = nul
    STATUT("Planificateur : impossible de lancer son noyau (" + chaine(e) + ")")
  finessayer
retourner

&& arrête le noyau du planificateur ; restituer = vrai : les cellules en cours retrouvent le
&& résultat qu'elles avaient avant leur lancement
procedure PLANIF_ARRETER(restituer)
  si restituer
    PLANIF_RESTITUER()
  sinon
    planif_pile = {}
  finsi
  planif_texte = {}
  planif_pret = faux
  planif_requete = ""
  si planif_x <> nul
    locale x = planif_x
    planif_x = nul
    essayer
      si x:actif()
        x:arreter()
      finsi
    capturer e
    finessayer
  finsi
retourner

procedure PLANIF_RESTITUER
  tantque taille(planif_pile) > 0
    locale e = retirer(planif_pile)
    locale c = CELLULE(e.id)
    si c <> nul
      c.sorties = e.avant
      c.duree = e.duree
      c.compteur = e.compteur
      c.etat = ""
      locale u = UIC[c.id]
      si u <> nul
        SORTIES_VIDER(u)
        pour chaque s dans c.sorties
          SORTIE_CONTROLE(u, s)
        suivant
      finsi
      MAJ_ENTETE(c)
    finsi
  fintantque
retourner

&& toutes les 500 ms : état de la cellule, puis lancement si l'heure est venue
procedure PLANIF_TIC(ev)
  essayer
    PLANIF_VERIFIER()
    si planif_actif et planif_x = nul
      PLANIF_DEMARRER()
    finsi
    si planif_actif et planif_pret et taille(planif_pile) = 0 et horodatage() >= planif_prochaine
      PLANIF_LANCER()
    finsi
  capturer e
  finessayer
retourner

&& ▶ du planificateur (ou Ctrl+Entrée) : lancement immédiat s'il est actif
procedure PLANIF_MAINTENANT
  locale c = PLANIF_CELLULE()
  PLANIF_VERIFIER()
  si non planif_actif
    STATUT("Planificateur inactif : masquez sa cellule et cochez sa case pour l'activer")
    retourner
  finsi
  si taille(planif_pile) > 0
    STATUT("Planificateur déjà en cours")
    retourner
  finsi
  planif_prochaine = 0
  PLANIF_TIC(nul)
retourner

procedure PLANIF_LANCER
  locale c = PLANIF_CELLULE()
  si c = nul
    retourner
  finsi
  locale u = UIC[c.id]
  si u <> nul
    c.source = u.ed.valeur
  finsi
  locale prep = PREPARER_CELLULE(c)
  si prep.erreur <> nul
    c.sorties = {}
    si u <> nul
      SORTIES_VIDER(u)
    finsi
    SORTIE_RECUE(c.id, {genre = "erreur", texte = prep.erreur, ligne = prep.ligne})
    PLANIF_REPROGRAMMER(c)
    PLANIF_ENTETE()
    retourner
  finsi
  locale ident = PLANIF_EMPILER(c)
  planif_pret = faux
  essayer
    planif_x:envoyer("X|" + prep.procs + "|" + prep.fichier + "|NB_CELLULE_" + c.id + "|" + ident)
  capturer e
    PLANIF_RESTITUER()
  finessayer
  PLANIF_ENTETE()
retourner

&& une cellule commence dans le planificateur : son résultat d'avant est gardé (restitution)
fonction PLANIF_EMPILER(c)
  planif_seq += 1
  locale ident = "P" + c.id + "." + planif_seq
  inserer {id = c.id, ident = ident, avant = c.sorties, duree = c.duree, compteur = c.compteur} dans planif_pile
  c.sorties = {}
  locale u = UIC[c.id]
  si u <> nul
    SORTIES_VIDER(u)
  finsi
  c.etat = "cours"
  MAJ_ENTETE(c)
retourner ident

&& fin d'exécution du planificateur : prochain lancement = heure courante + période
procedure PLANIF_REPROGRAMMER(c)
  locale s = PLANIF_SECONDES_DE(c.intervalle)
  planif_derniere_fin = horodatage()
  planif_prochaine = planif_derniere_fin + s
  planif_prochaine_txt = HEURE_PLUS(s)
retourner

&& heure (HH:MM:SS) dans s secondes, « demain » si elle passe minuit
fonction HEURE_PLUS(s)
  locale h = decouper(heure(), ":")
  locale t = valeur(h[1]) * 3600 + valeur(h[2]) * 60 + valeur(h[3]) + arrondi(max(0, s))
  locale jour = ""
  si t >= 86400
    t = t - 86400
    jour = "demain "
  finsi
  locale hh = entier(t / 3600)
  locale mm = entier((t - hh * 3600) / 60)
  locale ss = t - hh * 3600 - mm * 60
retourner jour + DEUX_CHIFFRES(hh) + ":" + DEUX_CHIFFRES(mm) + ":" + DEUX_CHIFFRES(ss)

fonction DEUX_CHIFFRES(n)
retourner sisinon(n < 10, "0" + n, chaine(n))

&& liste déroulante de la période
procedure PLANIF_PERIODE(ev)
  si maj_ui
    retourner
  finsi
  locale c = PLANIF_CELLULE()
  si c = nul
    retourner
  finsi
  locale t = nul
  si ev.index <> nul et ev.index >= 1 et ev.index <= taille(PLANIF_PERIODES)
    t = PLANIF_PERIODES[ev.index]
  sinonsi ev.texte <> nul
    t = chaine(ev.texte)
  finsi
  si t = nul ou t = c.intervalle
    retourner
  finsi
  c.intervalle = t
  MARQUER_MODIFIE()
  && en attente : le prochain lancement suit la nouvelle période (depuis la dernière fin)
  si planif_actif et taille(planif_pile) = 0 et planif_derniere_fin > 0
    planif_prochaine = planif_derniere_fin + PLANIF_SECONDES_DE(t)
    planif_prochaine_txt = HEURE_PLUS(planif_prochaine - horodatage())
  finsi
  STATUT("Planificateur : lancement toutes les " + PERIODE_TEXTE(t))
  PLANIF_ENTETE()
retourner

&& texte d'état du bandeau du planificateur
fonction PLANIF_INFO(c)
  si planif_actif
    locale haut = PLANIF_SOMMET()
    si haut <> 0
      si haut = c.id
        retourner "actif · en cours…"
      finsi
      retourner "actif · en cours… · cellule [" + NUMERO(haut) + "]"
    finsi
    locale t = "actif · prochain lancement : " + sisinon(planif_prochaine_txt = "", "imminent", planif_prochaine_txt)
    si c.duree <> nul
      t = t + " · dernière durée " + DUREE_TEXTE(c.duree)
    finsi
    retourner t
  finsi
  si non PLANIF_PERMIS()
    retourner "inactif (exécution en lot)"
  finsi
  si c.masquee
    retourner "inactif : cochez la case pour l'activer"
  finsi
  si c.exporter <> faux
    retourner "inactif : masquez la cellule pour l'activer"
  finsi
retourner "inactif : masquez la cellule et cochez sa case pour l'activer"

procedure PLANIF_ENTETE
  locale c = PLANIF_CELLULE()
  si c = nul
    retourner
  finsi
  locale t = PLANIF_INFO(c)
  si t <> planif_info_vu
    planif_info_vu = t
    MAJ_ENTETE(c)
  finsi
retourner

&&
&& noyau du planificateur
&&

procedure PLANIF_SORTIE(t)
  si planif_x = nul
    retourner
  finsi
  planif_tampon = planif_tampon + t
  si position(car(10), planif_tampon) = 0
    retourner
  finsi
  locale morceaux = decouper(planif_tampon, car(10))
  locale n = taille(morceaux)
  planif_tampon = morceaux[n]
  pour i = 1 a n - 1
    PLANIF_LIGNE(remplacertexte(morceaux[i], car(13), ""))
  suivant
  PLANIF_VIDER_TEXTE()
retourner

procedure PLANIF_LIGNE(l)
  si commencepar(l, car(30) + "NB:")
    PLANIF_VIDER_TEXTE()
    locale m = souschaine(l, 5)
    faire cas
    cas m = "pret"
      planif_annonce = vrai
    cas commencepar(m, "sortie:")
      locale id = PLANIF_SOMMET()
      si id <> 0
        essayer
          SORTIE_RECUE(id, dejson(souschaine(m, 8)))
        capturer e
          SORTIE_TEXTE(id, "(sortie illisible : " + chaine(e) + ")")
        finessayer
      finsi
    cas commencepar(m, "fin:")
      PLANIF_FIN_CELLULE(souschaine(m, 5))
    cas commencepar(m, "demande:")
      planif_requete = souschaine(m, 9)
    fincas
    retourner
  finsi
  locale id = PLANIF_SOMMET()
  si id <> 0
    si planif_texte_id <> id
      PLANIF_VIDER_TEXTE()
      planif_texte_id = id
    finsi
    inserer l dans planif_texte
  finsi
retourner

procedure PLANIF_VIDER_TEXTE
  si taille(planif_texte) = 0
    retourner
  finsi
  locale lignes = planif_texte
  planif_texte = {}
  SORTIE_TEXTE(planif_texte_id, joindre(lignes, car(10)))
retourner

procedure PLANIF_FIN_CELLULE(r)
  locale p = position(":", r)
  locale ident = gauche(r, p - 1)
  locale reste = souschaine(r, p + 1)
  locale n = taille(planif_pile)
  si n = 0 ou planif_pile[n].ident <> ident
    retourner
  finsi
  locale e = retirer(planif_pile)
  locale c = CELLULE(e.id)
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
    capturer e2
    finessayer
    ERREUR_CELLULE(c, chaine(trace))
  finsi
  si c.genre = "planif"
    PLANIF_REPROGRAMMER(c)
  finsi
  MAJ_ENTETE(c)
  PLANIF_ENTETE()
retourner

procedure PLANIF_DEMANDE(invite)
  si planif_x = nul
    retourner
  finsi
  si planif_requete <> ""
    locale q = planif_requete
    planif_requete = ""
    locale rep = PLANIF_REPONSE(q)
    PLANIF_ENTETE()
    essayer
      planif_x:envoyer(rep)
    capturer e
    finessayer
    retourner
  finsi
  si planif_annonce
    planif_annonce = faux
    si non planif_dossier_envoye et chemin_carnet <> ""
      && dossier courant = celui du carnet (le noyau répond « pret » à nouveau)
      planif_dossier_envoye = vrai
      essayer
        planif_x:envoyer("§dossier|" + fichier.dossier(chemin_carnet))
      capturer e
      finessayer
      retourner
    finsi
    planif_pret = vrai
    PLANIF_TIC(nul)
    retourner
  finsi
  && saisir() dans le code planifié : pas de fenêtre de saisie en tâche de fond
  locale id = PLANIF_SOMMET()
  si id <> 0
    SORTIE_TEXTE(id, "(saisir() est sans effet dans le planificateur : réponse vide)")
  finsi
  essayer
    planif_x:envoyer("")
  capturer e
  finessayer
retourner

&& pourquoi une cellule ne peut pas être exécutée par le planificateur ("" : elle peut)
fonction PLANIF_REFUS(c)
  si c = nul
    retourner "cellule inexistante"
  finsi
  si c.genre = "planif"
    retourner "c'est le planificateur"
  finsi
  si c.genre = "markdown"
    retourner "cellule de texte"
  finsi
  si non c.masquee
    retourner "cellule affichée (seules les cellules masquées s'exécutent)"
  finsi
  si c.id = cellule_en_cours ou contient(file_attente, c.id)
    retourner "cellule en cours dans le noyau principal"
  finsi
  si PLANIF_TIENT(c.id)
    retourner "cellule déjà en cours"
  finsi
retourner ""

procedure PLANIF_NOTE(t)
  locale c = PLANIF_CELLULE()
  si c <> nul
    SORTIE_TEXTE(c.id, t)
  finsi
retourner

fonction PLANIF_REPONSE(q)
  si commencepar(q, "cellule:")
    locale n = valeur(souschaine(q, 9))
    locale c = CELLULE_NUMERO(n)
    locale refus = PLANIF_REFUS(c)
    si refus <> ""
      PLANIF_NOTE("executer_cellule(" + chaine(n) + ") sans effet : " + refus)
      retourner "§refus"
    finsi
    locale u = UIC[c.id]
    si u <> nul
      c.source = u.ed.valeur
    finsi
    locale prep = PREPARER_CELLULE(c)
    si prep.erreur <> nul
      c.sorties = {}
      si u <> nul
        SORTIES_VIDER(u)
      finsi
      SORTIE_RECUE(c.id, {genre = "erreur", texte = prep.erreur, ligne = prep.ligne})
      PLANIF_NOTE("executer_cellule(" + chaine(n) + ") : erreur de syntaxe dans la cellule [" + chaine(n) + "]")
      retourner "§refus"
    finsi
    locale ident = PLANIF_EMPILER(c)
    retourner "X|" + prep.procs + "|" + prep.fichier + "|NB_CELLULE_" + c.id + "|" + ident
  finsi
  si commencepar(q, "liste:")
    locale depuis = valeur(souschaine(q, 7))
    locale l = {}
    pour chaque c dans carnet.cellules
      si c.genre <> "planif"
        locale k = NUMERO(c.id)
        si k >= depuis et PLANIF_REFUS(c) = ""
          inserer chaine(k) dans l
        finsi
      finsi
    suivant
    retourner joindre(l, ",")
  finsi
retourner "§refus"

procedure PLANIF_FIN(ev)
  && fin d'un noyau du planificateur : arrêt voulu (planif_x déjà remis à nul) ou incident
  si planif_x = nul
    retourner
  finsi
  essayer
    si planif_x:actif()
      retourner                   && fin d'un ancien noyau : le noyau courant tourne
    finsi
  capturer e
  finessayer
  planif_x = nul
  planif_pret = faux
  si taille(planif_pile) > 0
    PLANIF_RESTITUER()
    PLANIF_NOTE("Le noyau du planificateur s'est arrêté : " + chaine(ev.message))
  finsi
  si planif_actif
    && il repart au prochain tic ; prochain lancement dans une période
    locale c = PLANIF_CELLULE()
    si c <> nul
      PLANIF_REPROGRAMMER(c)
    finsi
  finsi
  PLANIF_ENTETE()
retourner

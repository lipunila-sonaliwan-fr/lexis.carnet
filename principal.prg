&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : carnets interactifs (à la manière de Jupyter) écrits en Lexis+.
&& Un carnet mélange des cellules de code Lexis+, des cellules SQL (DuckDB) et des
&& cellules de texte Markdown ; les résultats (texte, valeurs, tableaux, graphes,
&& Markdown) s'affichent sous chaque cellule et sont enregistrés avec le carnet.
&&
&&   wdlexisrt principal.prg [carnet.lxnb]
&&
&& Fichiers (le runtime les charge tous) :
&&   principal.prg   fenêtre, barre d'outils, menus, clavier, état
&&   document.prg    modèle du carnet : cellules, lecture et écriture du format .lxnb
&&   cellules.prg    affichage et édition des cellules (éditeurs, Markdown, en-têtes)
&&   sorties.prg     affichage des résultats : texte, valeur, tableau, graphe, erreur
&&   moteur.prg      noyau d'exécution : interpréteur séparé, file d'attente, protocole
&&   export.prg      exports HTML, Markdown, PDF et programme .prg ; graphes en SVG
&&   minicarte.prg   minimap : vignettes numérotées des cellules (aller, réordonner)
&&   planificateur.prg  cellule [*] : code lancé en tâche de fond, à intervalle, sur un noyau dédié
&&   ressources/noyau.lxk  programme du noyau (copié dans un dossier temporaire)
ui = paquet("interface")

APP_NOM = "Carnet Lexis+ 1.0.5"
reglages = LIRE_REGLAGES()
carnet = nul                && document courant {titre, cellules, ...}
chemin_carnet = ""          && fichier .lxnb ("" : jamais enregistré)
modifie = faux
prochain_id = 1             && identifiant interne des cellules
UIC = {}                    && id de cellule -> contrôles de la cellule
BOUTONS = {}                && boutons d'en-tête : {ctl, id, action}
cellule_choisie = 0         && id de la cellule sélectionnée
maj_ui = faux               && vrai pendant la construction (événements ignorés)
derniere_sauvegarde = 0
&& minimap (minicarte.prg)
MINI_LARGEUR = 128
MINI_HMIN = 24              && hauteur minimale d'une vignette
MINI_HMAX = 140             && ... et maximale
minicarte = nul             && panneau des vignettes
mini_volet = faux           && vrai : volet du panneau des cellules (avant l'ascenseur)
VIGNETTES = {}              && vignettes, dans l'ordre des cellules : {id, cadre, lbl}
mini_structure = ""         && signature des cellules représentées (ordre, genres, état)
mini_geometrie = ""         && signature des hauteurs et de la zone visible
mini_glisse = nul           && glisser en cours : {id, y0, deplace, cible}
mini_a_montrer = 0              && cellule à amener en haut de l'écran au prochain tic
mini_minuterie = nul
mini_cle = ""               && dernier état vu par la minuterie (défilement, contenu, état)
mini_tics = 0
focus_differe = 0           && cellule à qui donner le focus après la mise en page
num_ordre = ""              && ordre des cellules au dernier numérotage des bandeaux
&& planificateur (planificateur.prg)
PLANIF_PERIODES = {"+10s", "+30s", "+1min", "+5min", "+10min", "+30min", "+1h"}
PLANIF_SECONDES = {10, 30, 60, 300, 600, 1800, 3600}
planif_x = nul              && noyau dédié du planificateur
planif_id = 0               && id de la cellule du planificateur suivie
planif_actif = faux
planif_pret = faux
planif_annonce = faux
planif_requete = ""         && demande du noyau en attente de réponse (cellule:n, liste:n)
planif_tampon = ""
planif_texte = {}
planif_texte_id = 0
planif_dossier_envoye = faux
planif_pile = {}            && cellules en cours : {id, ident, avant (sorties), duree, compteur}
planif_seq = 0
planif_prochaine = 0        && horodatage du prochain lancement
planif_prochaine_txt = ""
planif_derniere_fin = 0
planif_info_vu = ""
planif_minuterie = nul
&& noyau
noyau_x = nul
noyau_dossier = ""
noyau_pret = faux
pret_annonce = faux
noyau_requete = faux        && le noyau attend la réponse à une demande (executer_cellule…)
noyau_tampon = ""
noyau_etat = "arrêté"
file_attente = {}
cellule_en_cours = 0
exec_en_cours = ""
exec_compteur = 0
exec_seq = 0
arret_voulu = faux
quitter_demande = faux
relances = 0
cartes = {}                 && id -> lignes du fichier de cellule -> lignes de la cellule
carte_procs = {}            && lignes de procedures.prg -> {id, ligne}
defs_procs = {}             && nom de procédure -> {id, lignes}
ordre_procs = {}            && noms des procédures, dans l'ordre de définition
texte_attente = {}          && lignes de texte reçues, pas encore affichées
texte_attente_id = 0
lot_actif = faux            && exécution en lot (--executer) en cours
lot_enregistrer = faux
lot_quitter = faux
lot_exports = {}            && --exporter fichier.(html|md|pdf|prg)
MAX_TEXTE = 200000          && caractères de texte gardés par cellule
MAX_LIGNES_AFFICHEES = 2000 && lignes de texte montrées à l'écran (les dernières)

essayer
  ui.icone(fichier.joindre(systeme.dossierprogramme(), "ressources", "carnet.png"))
capturer e
finessayer
fen = ui.fenetre{titre = APP_NOM, largeur = 1280, hauteur = 900, disposition = "bordure", ;
                 sombre = reglages.sombre, densite = "compacte"}
fen.marge = 0
fen.espacement = 0
fen.surfermeture = @FERMETURE
fen.surtouchebas = @TOUCHE

barre_menus = fen:ajouter(ui.barremenu())
CONSTRUIRE_MENUS(barre_menus)
barre_menus.surselection = @MENU

barre = fen:ajouter(ui.rangee())
barre.ancrage = "haut"
barre.marge = 3
barre.espacement = 2
OUTIL(barre, "Nouveau", @NOUVEAU, "Nouveau carnet (Ctrl+N)")
OUTIL(barre, "Ouvrir…", @OUVRIR, "Ouvrir un carnet .lxnb (Ctrl+O)")
OUTIL(barre, "Enregistrer", @ENREGISTRER, "Enregistrer le carnet (Ctrl+S)")
ESPACE_BARRE(barre)
OUTIL(barre, "+ Code", @AJOUTER_CODE, "Insérer une cellule de code Lexis+ sous la cellule choisie")
OUTIL(barre, "+ SQL", @AJOUTER_SQL, "Insérer une cellule SQL (DuckDB) sous la cellule choisie")
OUTIL(barre, "+ Texte", @AJOUTER_TEXTE, "Insérer une cellule de texte Markdown sous la cellule choisie")
ESPACE_BARRE(barre)
b = OUTIL(barre, "▲", @MONTER, "Monter la cellule choisie")
b.largeurfixe = 28
b = OUTIL(barre, "▼", @DESCENDRE, "Descendre la cellule choisie")
b.largeurfixe = 28
b = OUTIL(barre, "✕", @SUPPRIMER, "Supprimer la cellule choisie")
b.largeurfixe = 28
ESPACE_BARRE(barre)
OUTIL(barre, "▶ Exécuter", @EXECUTER_CHOISIE, "Exécuter la cellule choisie (Ctrl+Entrée ; Maj+Entrée : et passer à la suivante)")
OUTIL(barre, "▶▶ Tout", @TOUT_EXECUTER, "Exécuter toutes les cellules, dans l'ordre")
OUTIL(barre, "■ Interrompre", @INTERROMPRE, "Interrompre l'exécution (le noyau redémarre : les variables sont perdues)")
OUTIL(barre, "↻ Redémarrer", @REDEMARRER, "Redémarrer le noyau (efface les variables)")
OUTIL(barre, "⌫ Sorties", @EFFACER_SORTIES, "Effacer toutes les sorties")
ESPACE_BARRE(barre)
OUTIL(barre, "Exporter HTML…", @EXPORTER_HTML, "Page HTML autonome : texte, code, tableaux et graphes (SVG)")

pied = fen:ajouter(ui.rangee())
pied.ancrage = "bas"
pied.marge = 2
pied.espacement = 14
pied.hauteurfixe = 22
pied.fond = sisinon(reglages.sombre, "#111827", "#E5E7EB")
lbl_etat = pied:ajouter(ui.etiquette("Prêt"))
lbl_etat.poids = 1
lbl_etat.couleur = "#9CA3AF"
lbl_titre = pied:ajouter(ui.etiquette(""))
lbl_titre.couleur = sisinon(reglages.sombre, "#FBBF24", "#B45309")
lbl_cellules = pied:ajouter(ui.etiquette(""))
lbl_cellules.couleur = "#9CA3AF"
lbl_noyau = pied:ajouter(ui.etiquette("Noyau : arrêté"))
lbl_noyau.couleur = "#9CA3AF"

pc = fen:ajouter(ui.panneau{disposition = "vertical", defilement = "vertical"})
pc.ancrage = "centre"
pc.marge = 12
pc.espacement = 10
MINI_CREER()
PLANIF_CREER()

&& ligne de commande : [carnet.lxnb] [--executer] [--enregistrer] [--exporter f.html|.md|.pdf|.prg] [--quitter]
depart = ""
lot_executer = faux
attend_export = faux
pour i = 1 a taille(systeme.args)
  arg = chaine(systeme.args[i])
  faire cas
  cas attend_export
    inserer fichier.absolu(arg) dans lot_exports
    attend_export = faux
  cas arg = "--exporter"
    attend_export = vrai
  cas arg = "--executer"
    lot_executer = vrai
  cas arg = "--enregistrer"
    lot_enregistrer = vrai
  cas arg = "--quitter"
    lot_quitter = vrai
  cas arg <> "" et depart = ""
    depart = arg
  fincas
suivant
minuterie_texte = ui.minuterie(120, @VIDER_TEXTE_TIC)
NOYAU_DEMARRER()
si depart <> "" et fichier.existe(depart)
  OUVRIR_CHEMIN(fichier.absolu(depart))
sinon
  NOUVEAU_CARNET()
finsi
si lot_executer
  TOUT_EXECUTER(nul)
  lot_actif = vrai
  STATUT("Exécution de toutes les cellules…")
sinonsi taille(lot_exports) > 0 ou lot_quitter
  lot_actif = vrai
  ui.minuterie(200, @LOT_DIFFERE, faux)     && une fois la fenêtre en service
finsi
ui.executer()

fonction OUTIL(conteneur, libelle, proc, infobulle)
  locale b = conteneur:ajouter(ui.bouton(libelle, {plat = vrai}))
  b.surclic = proc
  si infobulle <> nul
    b.infobulle = infobulle
  finsi
retourner b

procedure ESPACE_BARRE(barre_)
  locale e = barre_:ajouter(ui.etiquette(""))
  e.largeurfixe = 10
retourner

procedure STATUT(m)
  essayer
    lbl_etat.libelle = m
  capturer e
  finessayer
retourner

procedure MAJ_TITRE
  locale nom = "sans titre"
  si chemin_carnet <> ""
    nom = fichier.nom(chemin_carnet)
  finsi
  fen.titre = nom + sisinon(modifie, " •", "") + " - " + APP_NOM
  lbl_titre.libelle = TITRE_CARNET() + sisinon(modifie, "  (modifié)", "")
  locale nc = 0, nt = 0, ns = 0
  si carnet <> nul
    pour chaque c dans carnet.cellules
      faire cas
      cas c.genre = "markdown"
        nt += 1
      cas c.genre = "sql"
        ns += 1
      cas c.genre = "planif"
        nc += 0                 && le planificateur n'est pas compté
      autrement
        nc += 1
      fincas
    suivant
  finsi
  lbl_cellules.libelle = chaine(nc) + " code · " + chaine(ns) + " SQL · " + chaine(nt) + " texte"
retourner

procedure MARQUER_MODIFIE
  si non modifie
    modifie = vrai
    MAJ_TITRE()
  finsi
retourner

&&
&& menus
&&

fonction MENUS()
retourner { ;
  {"Fichier", {"Nouveau carnet (Ctrl+N)", "Ouvrir… (Ctrl+O)", "Enregistrer (Ctrl+S)", "Enregistrer sous…", "-", ;
               "Renommer le carnet…", "-", ;
               "Exporter en HTML…", "Exporter en Markdown…", "Exporter en PDF…", "Exporter en programme .prg…", "-", ;
               "Ouvrir le carnet de découverte", "-", "Quitter"}}, ;
  {"Cellule", {"Ajouter du Code Lexis+ (après)", "Ajouter du SQL DuckDB", "Ajouter du Texte Markdown", "-", ;
               "Insérer du Code Lexis+ (avant)", "Insérer du SQL DuckDB", "Insérer du Texte Markdown", "-", ;
               "Monter", "Descendre", "Dupliquer", "Supprimer", "-", ;
               "Changer en Code Lexis+", "Changer en SQL DuckDB", "Changer en Texte Markdown", "-", ;
               "Modifier le texte (cellule Markdown)", "Effacer les sorties de la cellule", "-", ;
               "Masquer / afficher la cellule", "Inclure / exclure des exports"}}, ;
  {"Exécution", {"Exécuter la cellule (Ctrl+Entrée)", "Exécuter et passer à la suivante (Maj+Entrée)", ;
                 "Tout exécuter", "Exécuter les cellules au-dessus", "Exécuter à partir de la cellule", "-", ;
                 "Interrompre", "Redémarrer le noyau", "Redémarrer et tout exécuter", "-", ;
                 "Effacer toutes les sorties"}}, ;
  {"Affichage", {"Thème sombre / clair", "Agrandir le texte du code", "Réduire le texte du code", "-", ;
                 "Minimap masquer / afficher", "Code Lexis+ masquer / révéler", "SQL DuckDB masquer / révéler"}}, ;
  {"Aide", {"Aide-mémoire", "Raccourcis clavier", "À propos"}}}

procedure CONSTRUIRE_MENUS(m)
  pour chaque groupe dans MENUS()
    pour chaque e dans groupe[2]
      m:ajouter(groupe[1], e)
    suivant
  suivant
retourner

procedure MENU(ev)
  locale choix = ev.texte
  si ev.chemin <> nul
    choix = ev.chemin[#ev.chemin]
  finsi
  faire cas
  cas commencepar(choix, "Nouveau carnet")
    NOUVEAU(nul)
  cas commencepar(choix, "Ouvrir…")
    OUVRIR(nul)
  cas commencepar(choix, "Enregistrer (")
    ENREGISTRER(nul)
  cas choix = "Enregistrer sous…"
    ENREGISTRER_SOUS()
  cas choix = "Renommer le carnet…"
    RENOMMER_CARNET()
  cas choix = "Exporter en HTML…"
    EXPORTER_HTML(nul)
  cas choix = "Exporter en Markdown…"
    EXPORTER_MARKDOWN()
  cas choix = "Exporter en PDF…"
    EXPORTER_PDF()
  cas choix = "Exporter en programme .prg…"
    EXPORTER_PRG()
  cas choix = "Ouvrir le carnet de découverte"
    OUVRIR_EXEMPLE("decouverte.lxnb")
  cas choix = "Quitter"
    FERMETURE(nul)
    ui.quitter()
  cas choix = "Ajouter du Code Lexis+ (après)"
    INSERER_CELLULE("code", "", 1)
  cas choix = "Ajouter du SQL DuckDB"
    INSERER_CELLULE("sql", "", 1)
  cas choix = "Ajouter du Texte Markdown"
    INSERER_CELLULE("markdown", "", 1)
  cas choix = "Insérer du Code Lexis+ (avant)"
    INSERER_CELLULE("code", "", 0)
  cas choix = "Insérer du SQL DuckDB"
    INSERER_CELLULE("sql", "", 0)
  cas choix = "Insérer du Texte Markdown"
    INSERER_CELLULE("markdown", "", 0)
  cas choix = "Monter"
    MONTER(nul)
  cas choix = "Descendre"
    DESCENDRE(nul)
  cas choix = "Dupliquer"
    DUPLIQUER(cellule_choisie)
  cas choix = "Supprimer"
    SUPPRIMER(nul)
  cas choix = "Changer en Code Lexis+"
    CHANGER_GENRE(cellule_choisie, "code")
  cas choix = "Changer en Texte Markdown"
    CHANGER_GENRE(cellule_choisie, "markdown")
  cas choix = "Changer en SQL DuckDB"
    CHANGER_GENRE(cellule_choisie, "sql")
  cas choix = "Modifier le texte (cellule Markdown)"
    EDITER_MARKDOWN(cellule_choisie)
  cas choix = "Effacer les sorties de la cellule"
    EFFACER_SORTIES_CELLULE(cellule_choisie)
  cas choix = "Masquer / afficher la cellule"
    BASCULER_MASQUE(cellule_choisie)
  cas choix = "Inclure / exclure des exports"
    BASCULER_EXPORT(cellule_choisie)
  cas choix = "Code Lexis+ masquer / révéler"
    BASCULER_GENRE("code")
  cas choix = "SQL DuckDB masquer / révéler"
    BASCULER_GENRE("sql")
  cas commencepar(choix, "Exécuter la cellule")
    EXECUTER_CHOISIE(nul)
  cas commencepar(choix, "Exécuter et passer")
    EXECUTER_ET_PASSER(cellule_choisie)
  cas choix = "Tout exécuter"
    TOUT_EXECUTER(nul)
  cas choix = "Exécuter les cellules au-dessus"
    EXECUTER_PLAGE(1, INDEX_CELLULE(cellule_choisie) - 1)
  cas choix = "Exécuter à partir de la cellule"
    EXECUTER_PLAGE(INDEX_CELLULE(cellule_choisie), taille(carnet.cellules))
  cas choix = "Interrompre"
    INTERROMPRE(nul)
  cas choix = "Redémarrer le noyau"
    REDEMARRER(nul)
  cas choix = "Redémarrer et tout exécuter"
    REDEMARRER(nul)
    TOUT_EXECUTER(nul)
  cas choix = "Effacer toutes les sorties"
    EFFACER_SORTIES(nul)
  cas choix = "Thème sombre / clair"
    reglages.sombre = non reglages.sombre
    APPLIQUER_THEME()
    ECRIRE_REGLAGES()
  cas choix = "Minimap masquer / afficher"
    MINI_AFFICHER(non (reglages.minicarte <> faux))
  cas choix = "Agrandir le texte du code"
    reglages.police = min(24, reglages.police + 1)
    TAILLE_POLICE()
  cas choix = "Réduire le texte du code"
    reglages.police = max(9, reglages.police - 1)
    TAILLE_POLICE()
  cas choix = "Aide-mémoire"
    OUVRIR_EXEMPLE("aide-memoire.lxnb")
  cas choix = "Raccourcis clavier"
    ui.alerte(
      "\nCtrl.\n+Espace : complétion dans le code\n" +
      "+Entrée : exécuter/afficher la cellule\n" +
      "+N : nouveau\n+O : ouvrir\n+S : enregistrer\n" +
      "\nMàj.\n+Entrée : exécuter/afficher et passer à la cellule nsuivante\n" +
      "\nDouble-clic\nsur un texte mis en forme : modifier son markdown"
    )
  cas choix = "À propos"
    ui.alerte(
      "\n" + APP_NOM + " interactifs avec :\n" + ;
      "→ Code Lexis+\n→ SQL DuckDB\n→ Texte Markdown\n\n" + ;
      "Résultats immédiats, enregistrés avec le carnet, sous forme de :\n→ Graphes\n→ Tableaux\n→ Textes\n\n" + ;
      "Tous droits réservés 2026 - Jean-Marc QUÉRÉ\n" +
      "⛶ https://sonaliwan.fr  ✉ metalab (at) sonaliwan.fr\n" +
      "SIRET 13033319800013", "information", "À propos"
    )              
  fincas
retourner

procedure TOUCHE(ev)
  locale ctrl = ev.modificateurs <> nul et (ev.modificateurs % 256) >= 64
  si non ctrl
    retourner
  finsi
  faire cas
  cas ev.touche = 115 ou ev.touche = 83
    ENREGISTRER(nul)
  cas ev.touche = 111 ou ev.touche = 79
    OUVRIR(nul)
  cas ev.touche = 110 ou ev.touche = 78
    NOUVEAU(nul)
  fincas
retourner

&&
&& fichier
&&

procedure NOUVEAU(ev)
  si non CONFIRMER_ABANDON()
    retourner
  finsi
  NOUVEAU_CARNET()
retourner

procedure NOUVEAU_CARNET
  carnet = CARNET_VIDE("Nouveau carnet")
  inserer NOUVELLE_CELLULE("markdown", "# Nouveau carnet" + car(10) + car(10) + ;
          "Double-cliquez sur ce texte pour le modifier ; **Maj+Entrée** exécute une cellule.") dans carnet.cellules
  inserer NOUVELLE_CELLULE("code", "") dans carnet.cellules
  ASSURER_PLANIF(carnet)
  chemin_carnet = ""
  modifie = faux
  CONSTRUIRE_TOUT()
  locale derniere = carnet.cellules[taille(carnet.cellules)].id
  CHOISIR(derniere)
  FOCUS_CELLULE(derniere)
  MAJ_TITRE()
  STATUT("Nouveau carnet")
retourner

fonction CONFIRMER_ABANDON()
  si modifie et carnet <> nul
    si ui.confirmer("Le carnet « " + TITRE_CARNET() + " » a été modifié. L'enregistrer d'abord ?", "question")
      retourner ENREGISTRER(nul)
    finsi
  finsi
retourner vrai

procedure OUVRIR(ev)
  si non CONFIRMER_ABANDON()
    retourner
  finsi
  locale p = ui.ouvrirfichier{titre = "Ouvrir un carnet", filtre = "*.lxnb", dossier = reglages.dossier}
  si p = nul ou p = ""
    retourner
  finsi
  OUVRIR_CHEMIN(p)
retourner

procedure OUVRIR_EXEMPLE(nom)
  si non CONFIRMER_ABANDON()
    retourner
  finsi
  OUVRIR_CHEMIN(fichier.joindre(systeme.dossierprogramme(), "exemples", nom))
  chemin_carnet = ""          && un exemple s'enregistre ailleurs (Enregistrer sous)
  MAJ_TITRE()
retourner

procedure OUVRIR_CHEMIN(p)
  locale c = nul
  essayer
    c = LIRE_CARNET(p)
  capturer e
    ui.alerte("Impossible d'ouvrir « " + p + " » :" + car(10) + chaine(e), "stop")
    retourner
  finessayer
  carnet = c
  chemin_carnet = p
  modifie = faux
  reglages.dossier = fichier.dossier(p)
  ECRIRE_REGLAGES()
  NOYAU_DOSSIER_COURANT()
  CONSTRUIRE_TOUT()
  si taille(carnet.cellules) > 1
    CHOISIR(carnet.cellules[2].id)        && la première cellule après le planificateur
  sinonsi taille(carnet.cellules) > 0
    CHOISIR(carnet.cellules[1].id)
  finsi
  MAJ_TITRE()
  STATUT("Ouvert : " + p + " (" + taille(carnet.cellules) + " cellules)")
retourner

fonction ENREGISTRER(ev)
  si horodatage() - derniere_sauvegarde < 0.4
    retourner vrai
  finsi
  si chemin_carnet = ""
    retourner ENREGISTRER_SOUS()
  finsi
  essayer
    ECRIRE_CARNET(chemin_carnet)
  capturer e
    ui.alerte("Enregistrement impossible :" + car(10) + chaine(e), "stop")
    retourner faux
  finessayer
  derniere_sauvegarde = horodatage()
  modifie = faux
  MAJ_TITRE()
  STATUT("Enregistré : " + chemin_carnet)
retourner vrai

fonction ENREGISTRER_SOUS()
  locale nom = NOM_FICHIER_SUR(TITRE_CARNET()) + ".lxnb"
  locale p = ui.enregistrerfichier{nom = fichier.joindre(reglages.dossier, nom), filtre = "*.lxnb"}
  si p = nul ou p = ""
    retourner faux
  finsi
  si non finitpar(minuscule(p), ".lxnb")
    p = p + ".lxnb"
  finsi
  chemin_carnet = p
  reglages.dossier = fichier.dossier(p)
  ECRIRE_REGLAGES()
  NOYAU_DOSSIER_COURANT()
  derniere_sauvegarde = 0
retourner ENREGISTRER(nul)

procedure RENOMMER_CARNET
  locale t = ui.demander("Titre du carnet :", TITRE_CARNET())
  si t = nul ou rogner(t) = ""
    retourner
  finsi
  carnet.metadonnees.titre = rogner(t)
  MARQUER_MODIFIE()
  MAJ_TITRE()
retourner

procedure FERMETURE(ev)
  si quitter_demande
    retourner
  finsi
  SYNC_SOURCES()
  si modifie et carnet <> nul
    si ui.confirmer("Le carnet « " + TITRE_CARNET() + " » a été modifié. L'enregistrer avant de quitter ?", "question")
      ENREGISTRER(nul)
    finsi
  finsi
  quitter_demande = vrai
  ECRIRE_REGLAGES()
  NOYAU_TERMINER()
retourner

procedure LOT_DIFFERE(ev)
  LOT_TERMINER()
retourner

&& fin d'une exécution en lot : enregistrement et sortie éventuels
procedure LOT_TERMINER
  lot_actif = faux
  STATUT("Exécution terminée")
  si lot_enregistrer et chemin_carnet <> ""
    essayer
      ECRIRE_CARNET(chemin_carnet)
      modifie = faux
      MAJ_TITRE()
      STATUT("Exécuté et enregistré : " + chemin_carnet)
    capturer e
      STATUT("Enregistrement impossible : " + chaine(e))
    finessayer
  finsi
  pour chaque x dans lot_exports
    EXPORTER_VERS(x)
  suivant
  si lot_quitter
    quitter_demande = vrai
    NOYAU_TERMINER()
    ui.quitter()
  finsi
retourner

procedure APPLIQUER_THEME
  essayer
    fen:fixertheme("natif", reglages.sombre, "compacte")
  capturer e
  finessayer
  pied.fond = sisinon(reglages.sombre, "#111827", "#E5E7EB")
  lbl_titre.couleur = sisinon(reglages.sombre, "#FBBF24", "#B45309")
  MINI_COULEURS()
  locale garde = cellule_choisie
  SYNC_SOURCES()
  CONSTRUIRE_TOUT()
  cellule_choisie = 0
  CHOISIR(garde)
retourner

procedure TAILLE_POLICE
  pour chaque k, u dans UIC
    essayer
      u.ed:taillepolice(reglages.police)
    capturer e
    finessayer
  suivant
  ECRIRE_REGLAGES()
retourner

&&
&& réglages
&&

fonction FICHIER_REGLAGES()
retourner fichier.joindre(fichier.dossierperso(), ".carnet_lexis.json")

fonction LIRE_REGLAGES()
  locale r = {sombre = vrai, dossier = fichier.dossierperso(), police = 14, minicarte = vrai}
  essayer
    locale p = FICHIER_REGLAGES()
    si fichier.existe(p)
      locale lu = dejson(fichier.lire(p))
      pour chaque k, v dans lu
        r[k] = v
      suivant
    finsi
  capturer e
  finessayer
  si r.dossier = nul ou non fichier.existe(r.dossier)
    r.dossier = fichier.dossierperso()
  finsi
retourner r

procedure ECRIRE_REGLAGES
  essayer
    fichier.ecrire(FICHIER_REGLAGES(), ENCODER_JSON(reglages, ""))
  capturer e
  finessayer
retourner

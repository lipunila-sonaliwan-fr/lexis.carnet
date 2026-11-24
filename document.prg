&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : modèle du document et format .lxnb.
&&
&& Format .lxnb (JSON, UTF-8) :
&&   {"format": "lexis-carnet", "version": 1,
&&    "metadonnees": {"titre": "...", "cree": "AAAA-MM-JJ HH:MM:SS", "modifie": "..."},
&&    "cellules": [{"genre": "code" | "markdown" | "sql", "source": "...",
&&                  "compteur": n, "duree": s, "sorties": [...],
&&                  "masquee": true,      (facultatif : cellule repliée à l'écran)
&&                  "export": false}]}    (facultatif : cellule exclue des exports)
&& Sorties : {"genre": "texte" | "valeur" | "markdown", "texte": "..."}
&&           {"genre": "table", "colonnes": [...], "lignes": [[...]], "total": n}
&&           {"genre": "graphe", "forme": "colonnes|lignes|aires|secteurs", "titre": "...",
&&            "categories": [...], "series": [{"nom": "...", "valeurs": [...]}]}
&&           {"genre": "erreur", "texte": "...", "ligne": n}

fonction CARNET_VIDE(titre)
  locale m = maintenant()
retourner {format = "lexis-carnet", version = 1, ;
           metadonnees = {titre = titre, cree = m, modifie = m}, cellules = {}}

fonction NOUVELLE_CELLULE(genre, src)
  locale c = {id = prochain_id, genre = genre, source = sisinon(src = nul, "", src), ;
              compteur = 0, duree = nul, sorties = {}, masquee = faux, exporter = vrai}
  prochain_id += 1
retourner c

fonction TITRE_CARNET()
  si carnet = nul ou carnet.metadonnees = nul ou carnet.metadonnees.titre = nul
    retourner "Carnet"
  finsi
retourner chaine(carnet.metadonnees.titre)

fonction INDEX_CELLULE(id)
  si carnet = nul
    retourner 0
  finsi
  pour i = 1 a taille(carnet.cellules)
    si carnet.cellules[i].id = id
      retourner i
    finsi
  suivant
retourner 0

fonction CELLULE(id)
  locale i = INDEX_CELLULE(id)
  si i = 0
    retourner nul
  finsi
retourner carnet.cellules[i]

fonction NOM_FICHIER_SUR(t)
  locale r = ""
  pour chaque morceau dans decouper(t, " ")
    si morceau <> ""
      r = r + sisinon(r = "", "", "-") + morceau
    finsi
  suivant
  pour chaque x dans {"/", "\\", ":", "*", "?", car(34), "<", ">", "|"}
    r = remplacertexte(r, x, "-")
  suivant
  si r = ""
    r = "carnet"
  finsi
retourner minuscule(r)

&& ---------------------------------------------------------------- lecture

fonction LIRE_CARNET(p)
  locale brut = dejson(fichier.lire(p))
  si type(brut) <> "table" ou brut.cellules = nul
    erreur "ce fichier n'est pas un carnet Lexis+ (.lxnb)"
  finsi
  si brut.format <> nul et brut.format <> "lexis-carnet"
    erreur "format inconnu : " + chaine(brut.format)
  finsi
  locale titre = fichier.nom(p)
  si brut.metadonnees <> nul et brut.metadonnees.titre <> nul
    titre = chaine(brut.metadonnees.titre)
  finsi
  locale c = CARNET_VIDE(titre)
  si brut.metadonnees <> nul
    pour chaque k, v dans brut.metadonnees
      c.metadonnees[k] = v
    suivant
  finsi
  pour chaque bc dans brut.cellules
    locale genre = minuscule(chaine(sisinon(bc.genre = nul, "code", bc.genre)))
    si non contient({"code", "markdown", "sql"}, genre)
      genre = "code"
    finsi
    locale cel = NOUVELLE_CELLULE(genre, SOURCE_TEXTE(bc.source))
    cel.compteur = sisinon(bc.compteur = nul, 0, bc.compteur)
    cel.duree = bc.duree
    cel.masquee = (bc.masquee = vrai)
    cel.exporter = (bc.export <> faux)
    si type(bc.sorties) = "table"
      pour chaque s dans bc.sorties
        inserer s dans cel.sorties
      suivant
    finsi
    inserer cel dans c.cellules
  suivant
retourner c

&& une source peut être un texte ou une liste de lignes (comme dans Jupyter)
fonction SOURCE_TEXTE(s)
  si s = nul
    retourner ""
  finsi
  si type(s) = "table"
    retourner joindre(s, "")
  finsi
retourner remplacertexte(chaine(s), car(13), "")

&& ---------------------------------------------------------------- écriture

procedure ECRIRE_CARNET(p)
  SYNC_SOURCES()
  carnet.metadonnees.modifie = maintenant()
  locale cs = {}
  pour chaque c dans carnet.cellules
    locale x = {genre = c.genre, source = c.source}
    si c.masquee
      x.masquee = vrai
    finsi
    si non c.exporter
      x.export = faux
    finsi
    si c.genre <> "markdown"
      x.compteur = sisinon(c.compteur = nul, 0, c.compteur)
      si c.duree <> nul
        x.duree = c.duree
      finsi
      x.sorties = c.sorties
    finsi
    inserer x dans cs
  suivant
  locale doc = {format = "lexis-carnet", version = 1, metadonnees = carnet.metadonnees, cellules = cs}
  locale tmp = p + ".tmp"
  fichier.ecrire(tmp, ENCODER_JSON(doc, "") + car(10))
  fichier.deplacer(tmp, p)
retourner

&& JSON lisible, clefs en minuscules (les clefs des tables Lexis+ sont en majuscules).
&& Une table dont toutes les clefs sont 1..n (ou vide) devient un tableau.
fonction ENCODER_JSON(v, retrait)
  faire cas
  cas v = nul
    retourner "null"
  cas type(v) = "logique"
    retourner sisinon(v, "true", "false")
  cas type(v) = "nombre"
    retourner json(v)
  cas type(v) = "chaine"
    retourner json(v)
  cas type(v) <> "table"
    retourner json(chaine(v))
  fincas
  locale n = taille(v)
  locale suite = retrait + "  "
  si n = nbelements(v)
    si n = 0
      retourner "[]"
    finsi
    locale simple = vrai
    pour i = 1 a n
      si type(v[i]) = "table"
        simple = faux
        sortir
      finsi
    suivant
    locale morceaux = {}
    pour i = 1 a n
      inserer ENCODER_JSON(v[i], suite) dans morceaux
    suivant
    si simple
      retourner "[" + joindre(morceaux, ", ") + "]"
    finsi
    retourner "[" + car(10) + suite + joindre(morceaux, "," + car(10) + suite) + car(10) + retrait + "]"
  finsi
  locale champs = {}
  pour chaque k, x dans v
    inserer json(minuscule(chaine(k))) + ": " + ENCODER_JSON(x, suite) dans champs
  suivant
retourner "{" + car(10) + suite + joindre(champs, "," + car(10) + suite) + car(10) + retrait + "}"

&& cellules incluses dans les exports (case « Export » du bandeau)
fonction CELLULES_EXPORT()
  locale l = {}
  pour chaque c dans carnet.cellules
    si c.exporter <> faux
      inserer c dans l
    finsi
  suivant
retourner l

&& première ligne non vide d'une cellule (aperçu d'une cellule masquée)
fonction APERCU_CELLULE(c, n)
  pour chaque l dans decouper(chaine(c.source), car(10))
    locale t = rogner(l)
    si t <> ""
      si longueur(t) > n
        t = gauche(t, n - 1) + "…"
      finsi
      retourner t
    finsi
  suivant
retourner "(vide)"

&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Carnet Lexis+ : exports.
&&   HTML      page autonome (styles intégrés, graphes en SVG) : se lit dans tout navigateur
&&   Markdown  texte + code + résultats ; graphes en fichiers SVG à côté du .md
&&   PDF       le Markdown mis en page par le paquet publication
&&   .prg      programme Lexis+ autonome : code des cellules, textes en commentaires

fonction PALETTE()
retourner {"#4F7CAC", "#E07A5F", "#3D9970", "#E9B44C", "#9B5DE5", "#2EC4B6", "#C2185B", "#7A8B99"}

fonction NB_SVG(x)
retourner chaine(arrondi(x, 1))

fonction BASE_EXPORT(ext)
  locale nom = NOM_FICHIER_SUR(TITRE_CARNET())
  si chemin_carnet <> ""
    nom = fichier.nom(chemin_carnet)
    si finitpar(minuscule(nom), ".lxnb")
      nom = gauche(nom, longueur(nom) - 5)
    finsi
  finsi
retourner fichier.joindre(reglages.dossier, nom + ext)

fonction CHOISIR_EXPORT(ext, filtre)
  locale p = ui.enregistrerfichier{nom = BASE_EXPORT(ext), filtre = filtre}
  si p = nul ou p = ""
    retourner nul
  finsi
  si non finitpar(minuscule(p), ext)
    p = p + ext
  finsi
retourner p

&& ---------------------------------------------------------------- graphes SVG

fonction SVG_GRAPHE(s, larg, haut)
  locale forme = FORME_GRAPHE(s.forme)
  locale pal = PALETTE()
  locale cats = {}
  pour chaque c dans s.categories
    inserer chaine(c) dans cats
  suivant
  locale series = {}
  locale k = 0
  pour chaque se dans s.series
    k += 1
    locale vs = {}
    pour chaque v dans se.valeurs
      inserer valeur(chaine(v)) dans vs
    suivant
    locale nom = chaine(sisinon(se.nom = nul, "", se.nom))
    inserer {nom = sisinon(nom = "", "Série " + k, nom), valeurs = vs} dans series
  suivant
  locale titre = chaine(sisinon(s.titre = nul, "", s.titre))
  locale o = {}
  inserer "<svg xmlns=" + car(34) + "http://www.w3.org/2000/svg" + car(34) + " viewBox=" + car(34) + "0 0 " + larg + " " + haut + car(34) + ;
          " width=" + car(34) + larg + car(34) + " height=" + car(34) + haut + car(34) + ;
          " font-family=" + car(34) + "Helvetica, Arial, sans-serif" + car(34) + " font-size=" + car(34) + "12" + car(34) + ">" dans o
  inserer "<rect width=" + car(34) + "100%" + car(34) + " height=" + car(34) + "100%" + car(34) + " fill=" + car(34) + "#ffffff" + car(34) + "/>" dans o
  locale haut_titre = 0
  si titre <> ""
    inserer ATTR_TEXTE(larg / 2, 20, titre, "middle", "#1f2937", "15", "bold") dans o
    haut_titre = 26
  finsi
  && légende (à droite)
  locale noms_leg = {}
  si forme = "secteurs"
    noms_leg = cats
  sinon
    pour chaque se dans series
      inserer se.nom dans noms_leg
    suivant
  finsi
  locale larg_leg = 0
  pour chaque nl dans noms_leg
    larg_leg = max(larg_leg, min(160, longueur(nl) * 7 + 26))
  suivant
  locale ly = haut_titre + 16
  locale li = 0
  pour chaque nl dans noms_leg
    li += 1
    si ly > haut - 10
      sortir
    finsi
    locale col = pal[((li - 1) % taille(pal)) + 1]
    inserer "<rect x=" + car(34) + (larg - larg_leg) + car(34) + " y=" + car(34) + (ly - 9) + car(34) + ;
            " width=" + car(34) + "10" + car(34) + " height=" + car(34) + "10" + car(34) + " fill=" + car(34) + col + car(34) + "/>" dans o
    inserer ATTR_TEXTE(larg - larg_leg + 15, ly, gauche(nl, 20), "start", "#374151", "12", "normal") dans o
    ly += 17
  suivant
  locale x0 = 54
  locale y0 = haut_titre + 12
  locale lz = larg - larg_leg - x0 - 16
  locale hz = haut - y0 - 34
  si forme = "secteurs"
    SVG_SECTEURS(o, series, cats, (larg - larg_leg) / 2, y0 + hz / 2 + 10, min(lz, hz) / 2, pal)
  sinon
    SVG_AXES(o, forme, series, cats, x0, y0, lz, hz, pal)
  finsi
  inserer "</svg>" dans o
retourner joindre(o, car(10))

fonction ATTR_TEXTE(x, y, t, ancre, coul, taille_, graisse)
retourner "<text x=" + car(34) + NB_SVG(x) + car(34) + " y=" + car(34) + NB_SVG(y) + car(34) + " text-anchor=" + car(34) + ancre + car(34) + ;
          " fill=" + car(34) + coul + car(34) + " font-size=" + car(34) + taille_ + car(34) + " font-weight=" + car(34) + graisse + car(34) + ">" + ;
          html(t) + "</text>"

&& graduation « ronde » au-dessus de m
fonction MAX_ROND(m)
  si m <= 0
    retourner 1
  finsi
  locale p = 1
  tantque p * 10 <= m
    p = p * 10
  fintantque
  tantque p > m
    p = p / 10
  fintantque
  pour chaque f dans {1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10}
    si f * p >= m
      retourner f * p
    finsi
  suivant
retourner 10 * p

procedure SVG_AXES(o, forme, series, cats, x0, y0, lz, hz, pal)
  locale vmax = 0
  locale vmin = 0
  locale nb = taille(cats)
  pour chaque se dans series
    nb = max(nb, taille(se.valeurs))
    pour chaque v dans se.valeurs
      vmax = max(vmax, v)
      vmin = min(vmin, v)
    suivant
  suivant
  si nb = 0
    retourner
  finsi
  vmax = MAX_ROND(vmax)
  si vmin < 0
    vmin = -MAX_ROND(-vmin)
  finsi
  locale etendue = vmax - vmin
  locale yb = y0 + hz
  && grille et graduations
  pour g = 0 a 5
    locale gv = vmin + etendue * g / 5
    locale gy = yb - hz * g / 5
    inserer "<line x1=" + car(34) + x0 + car(34) + " x2=" + car(34) + (x0 + lz) + car(34) + " y1=" + car(34) + NB_SVG(gy) + car(34) + ;
            " y2=" + car(34) + NB_SVG(gy) + car(34) + " stroke=" + car(34) + "#e5e7eb" + car(34) + "/>" dans o
    inserer ATTR_TEXTE(x0 - 6, gy + 4, chaine(arrondi(gv, 2)), "end", "#6b7280", "11", "normal") dans o
  suivant
  locale zero_y = yb - hz * (0 - vmin) / etendue
  inserer "<line x1=" + car(34) + x0 + car(34) + " x2=" + car(34) + (x0 + lz) + car(34) + " y1=" + car(34) + NB_SVG(zero_y) + car(34) + ;
          " y2=" + car(34) + NB_SVG(zero_y) + car(34) + " stroke=" + car(34) + "#9ca3af" + car(34) + "/>" dans o
  locale pasx = lz / nb
  && libellés des catégories (un sur deux si la place manque)
  locale saut = max(1, plafond(nb * 60 / max(1, lz)))
  pour i = 1 a nb
    si (i - 1) % saut = 0
      locale lib = ""
      si i <= taille(cats)
        lib = cats[i]
      finsi
      inserer ATTR_TEXTE(x0 + pasx * (i - 0.5), yb + 16, gauche(lib, 14), "middle", "#374151", "11", "normal") dans o
    finsi
  suivant
  locale ns = taille(series)
  si forme = "colonnes"
    locale lb = pasx * 0.8 / max(1, ns)
    locale si_ = 0
    pour chaque se dans series
      si_ += 1
      locale col = pal[((si_ - 1) % taille(pal)) + 1]
      pour i = 1 a taille(se.valeurs)
        locale v = se.valeurs[i]
        locale yv = yb - hz * (v - vmin) / etendue
        locale xb = x0 + pasx * (i - 1) + pasx * 0.1 + lb * (si_ - 1)
        inserer "<rect x=" + car(34) + NB_SVG(xb) + car(34) + " y=" + car(34) + NB_SVG(min(yv, zero_y)) + car(34) + ;
                " width=" + car(34) + NB_SVG(max(1, lb - 2)) + car(34) + " height=" + car(34) + NB_SVG(abs(zero_y - yv)) + car(34) + ;
                " fill=" + car(34) + col + car(34) + " rx=" + car(34) + "2" + car(34) + "/>" dans o
      suivant
    suivant
  sinon
    locale si2 = 0
    pour chaque se dans series
      si2 += 1
      locale col2 = pal[((si2 - 1) % taille(pal)) + 1]
      locale pts = {}
      pour i = 1 a taille(se.valeurs)
        inserer NB_SVG(x0 + pasx * (i - 0.5)) + "," + NB_SVG(yb - hz * (se.valeurs[i] - vmin) / etendue) dans pts
      suivant
      si taille(pts) > 0
        si forme = "aires"
          locale aire = NB_SVG(x0 + pasx * 0.5) + "," + NB_SVG(zero_y) + " " + joindre(pts, " ") + " " + ;
                        NB_SVG(x0 + pasx * (taille(pts) - 0.5)) + "," + NB_SVG(zero_y)
          inserer "<polygon points=" + car(34) + aire + car(34) + " fill=" + car(34) + col2 + car(34) + " fill-opacity=" + car(34) + "0.25" + car(34) + "/>" dans o
        finsi
        inserer "<polyline points=" + car(34) + joindre(pts, " ") + car(34) + " fill=" + car(34) + "none" + car(34) + ;
                " stroke=" + car(34) + col2 + car(34) + " stroke-width=" + car(34) + "2.2" + car(34) + "/>" dans o
        pour chaque pt dans pts
          locale xy = decouper(pt, ",")
          inserer "<circle cx=" + car(34) + xy[1] + car(34) + " cy=" + car(34) + xy[2] + car(34) + " r=" + car(34) + "3" + car(34) + ;
                  " fill=" + car(34) + col2 + car(34) + "/>" dans o
        suivant
      finsi
    suivant
  finsi
retourner

procedure SVG_SECTEURS(o, series, cats, cx, cy, r, pal)
  si taille(series) = 0
    retourner
  finsi
  locale vs = series[1].valeurs
  locale total = 0
  pour chaque v dans vs
    total += max(0, v)
  suivant
  si total <= 0
    retourner
  finsi
  locale a = -pi() / 2
  pour i = 1 a taille(vs)
    locale v = max(0, vs[i])
    locale da = 2 * pi() * v / total
    locale col = pal[((i - 1) % taille(pal)) + 1]
    si da >= 2 * pi() - 0.0001
      inserer "<circle cx=" + car(34) + NB_SVG(cx) + car(34) + " cy=" + car(34) + NB_SVG(cy) + car(34) + " r=" + car(34) + NB_SVG(r) + car(34) + ;
              " fill=" + car(34) + col + car(34) + "/>" dans o
    sinonsi da > 0
      locale x1 = cx + r * cos(a)
      locale y1 = cy + r * sin(a)
      locale x2 = cx + r * cos(a + da)
      locale y2 = cy + r * sin(a + da)
      locale grand = sisinon(da > pi(), "1", "0")
      inserer "<path d=" + car(34) + "M" + NB_SVG(cx) + "," + NB_SVG(cy) + " L" + NB_SVG(x1) + "," + NB_SVG(y1) + ;
              " A" + NB_SVG(r) + "," + NB_SVG(r) + " 0 " + grand + ",1 " + NB_SVG(x2) + "," + NB_SVG(y2) + " Z" + car(34) + ;
              " fill=" + car(34) + col + car(34) + " stroke=" + car(34) + "#ffffff" + car(34) + " stroke-width=" + car(34) + "1.5" + car(34) + "/>" dans o
      si da > 0.25
        locale am = a + da / 2
        inserer ATTR_TEXTE(cx + r * 0.65 * cos(am), cy + r * 0.65 * sin(am) + 4, chaine(arrondi(100 * v / total)) + " %", ;
                           "middle", "#ffffff", "12", "bold") dans o
      finsi
    finsi
    a += da
  suivant
retourner

&& ---------------------------------------------------------------- HTML

fonction CSS_EXPORT()
retourner [[
:root { --fond: #f7f7f5; --carte: #ffffff; --texte: #1f2937; --doux: #6b7280; --accent: #2563eb; --code: #f3f4f6; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--fond); color: var(--texte); font: 16px/1.6 -apple-system, "Segoe UI", Helvetica, Arial, sans-serif; }
main { max-width: 980px; margin: 0 auto; padding: 32px 20px 64px; }
header.carnet { border-bottom: 1px solid #e5e7eb; margin-bottom: 24px; padding-bottom: 8px; }
header.carnet h1 { margin: 0; font-size: 1.9em; }
header.carnet p { margin: 4px 0 0; color: var(--doux); font-size: .9em; }
section.md { margin: 18px 0; }
section.md h1, section.md h2, section.md h3 { line-height: 1.25; }
section.cellule { margin: 18px 0; background: var(--carte); border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; }
.entree { display: flex; border-bottom: 1px solid #eef0f3; }
.num { flex: 0 0 64px; padding: 10px 8px; color: var(--accent); font: 13px/1.5 ui-monospace, Menlo, Consolas, monospace; text-align: right; }
pre { margin: 0; white-space: pre-wrap; word-break: break-word; font: 13.5px/1.5 ui-monospace, Menlo, Consolas, monospace; }
pre.code { flex: 1; padding: 10px 12px; background: var(--code); }
.sorties { padding: 6px 12px 10px 76px; }
.sorties > * { margin: 8px 0; }
pre.texte { color: #111827; }
pre.erreur { color: #b91c1c; background: #fef2f2; padding: 8px 10px; border-radius: 6px; }
.resume { color: var(--doux); font-size: .85em; }
.tableau { overflow-x: auto; max-height: 460px; overflow-y: auto; border: 1px solid #e5e7eb; border-radius: 6px; }
table { border-collapse: collapse; font-size: .9em; width: max-content; min-width: 100%; }
th, td { padding: 4px 10px; border-bottom: 1px solid #eef0f3; text-align: left; white-space: nowrap; }
th { background: #f9fafb; position: sticky; top: 0; }
td.n { text-align: right; font-variant-numeric: tabular-nums; }
figure { margin: 8px 0; }
figure svg { max-width: 100%; height: auto; border: 1px solid #eef0f3; border-radius: 6px; }
code { background: var(--code); padding: 1px 4px; border-radius: 4px; font-size: .92em; }
section.md pre { background: var(--code); padding: 10px 12px; border-radius: 6px; }
blockquote { margin: 0; padding: 4px 14px; border-left: 3px solid var(--accent); color: #374151; background: #f8fafc; }
a.anchor { margin-left: .3em; color: #9ca3af; text-decoration: none; font-weight: normal; opacity: 0; }
h1:hover a.anchor, h2:hover a.anchor, h3:hover a.anchor, h4:hover a.anchor { opacity: 1; }
footer { margin-top: 40px; color: var(--doux); font-size: .8em; text-align: center; }
details.masquee { margin: 18px 0; border: 1px dashed #d1d5db; border-radius: 8px; padding: 6px 12px; background: var(--carte); }
details.masquee > summary { cursor: pointer; color: var(--doux); font-size: .9em; }
details.masquee[open] > summary { margin-bottom: 6px; }
]]

fonction EST_NOMBRE_TEXTE(v)
  si type(v) = "nombre"
    retourner vrai
  finsi
retourner type(v) = "chaine" et v <> "" et nombre(v) <> nul

fonction HTML_SORTIE(s)
  locale g = minuscule(chaine(s.genre))
  faire cas
  cas g = "texte" ou g = "valeur"
    retourner "<pre class=" + car(34) + "texte" + car(34) + ">" + html(chaine(s.texte)) + "</pre>"
  cas g = "markdown"
    retourner "<div class=" + car(34) + "mdsortie" + car(34) + ">" + publication.html(chaine(s.texte)) + "</div>"
  cas g = "erreur"
    retourner "<pre class=" + car(34) + "erreur" + car(34) + ">" + html(chaine(s.texte)) + "</pre>"
  cas g = "graphe"
    retourner "<figure>" + SVG_GRAPHE(s, 760, 340) + "</figure>"
  cas g = "table"
    locale o = {}
    locale total = sisinon(s.total = nul, taille(s.lignes), s.total)
    inserer "<div class=" + car(34) + "resume" + car(34) + ">" + total + " ligne(s) · " + taille(s.colonnes) + " colonne(s)</div>" dans o
    inserer "<div class=" + car(34) + "tableau" + car(34) + "><table><thead><tr>" dans o
    pour chaque c dans s.colonnes
      inserer "<th>" + html(chaine(c)) + "</th>" dans o
    suivant
    inserer "</tr></thead><tbody>" dans o
    pour chaque r dans s.lignes
      inserer "<tr>" dans o
      pour chaque v dans r
        si EST_NOMBRE_TEXTE(v)
          inserer "<td class=" + car(34) + "n" + car(34) + ">" + html(chaine(v)) + "</td>" dans o
        sinon
          inserer "<td>" + html(chaine(sisinon(v = nul, "", v))) + "</td>" dans o
        finsi
      suivant
      inserer "</tr>" dans o
    suivant
    inserer "</tbody></table></div>" dans o
    retourner joindre(o, "")
  fincas
retourner ""

fonction HTML_CARNET()
  SYNC_SOURCES()
  locale o = {}
  inserer "<!DOCTYPE html>" dans o
  inserer "<html lang=" + car(34) + "fr" + car(34) + "><head><meta charset=" + car(34) + "utf-8" + car(34) + ">" dans o
  inserer "<meta name=" + car(34) + "viewport" + car(34) + " content=" + car(34) + "width=device-width, initial-scale=1" + car(34) + ">" dans o
  inserer "<title>" + html(TITRE_CARNET()) + "</title><style>" + CSS_EXPORT() + "</style></head><body><main>" dans o
  && le titre du carnet n'est répété que si la première cellule n'en a pas
  locale cellules = CELLULES_EXPORT()
  locale entete_h1 = "<h1>" + html(TITRE_CARNET()) + "</h1>"
  si taille(cellules) > 0 et cellules[1].genre = "markdown" et commencepar(rognerg(cellules[1].source), "# ")
    entete_h1 = ""
  finsi
  inserer "<header class=" + car(34) + "carnet" + car(34) + ">" + entete_h1 + "<p>Carnet Lexis+ · " + ;
          html(date()) + "</p></header>" dans o
  pour chaque c dans cellules
    && cellule masquée à l'écran : repliée dans la page (un clic l'ouvre)
    si c.masquee
      inserer "<details class=" + car(34) + "masquee" + car(34) + "><summary>" + ;
              html(sisinon(c.genre = "markdown", "Texte", sisinon(c.genre = "sql", "SQL", "Code"))) + " masqué : " + ;
              html(APERCU_CELLULE(c, 90)) + "</summary>" dans o
    finsi
    si c.genre = "markdown"
      inserer "<section class=" + car(34) + "md" + car(34) + ">" + publication.html(c.source) + "</section>" dans o
    sinon
      locale n = sisinon(c.compteur <> nul et c.compteur > 0, "[" + c.compteur + "]", "[ ]")
      si c.genre = "sql"
        n = "SQL " + n
      finsi
      inserer "<section class=" + car(34) + "cellule" + car(34) + "><div class=" + car(34) + "entree" + car(34) + "><div class=" + car(34) + "num" + car(34) + ">" + ;
              n + "</div><pre class=" + car(34) + "code" + car(34) + ">" + html(c.source) + "</pre></div>" dans o
      si taille(c.sorties) > 0
        inserer "<div class=" + car(34) + "sorties" + car(34) + ">" dans o
        pour chaque s dans c.sorties
          inserer HTML_SORTIE(s) dans o
        suivant
        inserer "</div>" dans o
      finsi
      inserer "</section>" dans o
    finsi
    si c.masquee
      inserer "</details>" dans o
    finsi
  suivant
  inserer "<footer>Exporté de Carnet Lexis+ le " + html(maintenant()) + "</footer>" dans o
  inserer "</main></body></html>" dans o
retourner joindre(o, car(10))

procedure EXPORTER_HTML(ev)
  EXPORTER_VERS(CHOISIR_EXPORT(".html", "*.html"))
retourner

&& export d'après l'extension : .html, .md, .pdf, .prg ; renvoie vrai si réussi
fonction EXPORTER_VERS(p)
  si p = nul ou p = ""
    retourner faux
  finsi
  locale ext = minuscule(fichier.extension(p))
  si commencepar(ext, ".")
    ext = souschaine(ext, 2)
  finsi
  essayer
    faire cas
    cas ext = "html" ou ext = "htm"
      fichier.ecrire(p, HTML_CARNET())
    cas ext = "md"
      locale base = fichier.nom(p)
      base = gauche(base, longueur(base) - 3)
      fichier.ecrire(p, MARKDOWN_CARNET(fichier.dossier(p), base))
    cas ext = "pdf"
      EXPORT_PDF(p)
    cas ext = "prg"
      fichier.ecrire(p, PROGRAMME_CARNET())
    autrement
      erreur "extension inconnue (html, md, pdf, prg) : " + p
    fincas
    STATUT("Exporté : " + p)
  capturer e
    STATUT("Export impossible : " + chaine(e))
    si non lot_quitter
      ui.alerte("Export impossible :" + car(10) + chaine(e), "stop")
    finsi
    retourner faux
  finessayer
retourner vrai

&& ---------------------------------------------------------------- Markdown et PDF

fonction CELLULE_MD(t)
retourner remplacertexte(remplacertexte(chaine(sisinon(t = nul, "", t)), "|", "\\|"), car(10), " ")

fonction BLOC_MD(langage, t)
  locale clotures = "```"
  tantque contient(t, clotures)
    clotures = clotures + "`"
  fintantque
retourner clotures + langage + car(10) + t + car(10) + clotures

&& Markdown du carnet ; les graphes sont écrits en SVG dans dossier_fig (nom : prefixe_figN.svg)
fonction MARKDOWN_CARNET(dossier_fig, prefixe)
  SYNC_SOURCES()
  locale o = {}
  locale fig = 0
  locale cellules = CELLULES_EXPORT()
  si non (taille(cellules) > 0 et cellules[1].genre = "markdown" et ;
          commencepar(rognerg(cellules[1].source), "# "))
    inserer "# " + TITRE_CARNET() + car(10) dans o
  finsi
  pour chaque c dans cellules
    si c.genre = "markdown"
      inserer c.source + car(10) dans o
    sinon
      inserer BLOC_MD(sisinon(c.genre = "sql", "sql", "lexis"), c.source) + car(10) dans o
      pour chaque s dans c.sorties
        locale g = minuscule(chaine(s.genre))
        faire cas
        cas g = "texte" ou g = "valeur"
          inserer BLOC_MD("text", chaine(s.texte)) + car(10) dans o
        cas g = "markdown"
          inserer chaine(s.texte) + car(10) dans o
        cas g = "erreur"
          inserer "**Erreur**" + car(10) + car(10) + BLOC_MD("text", chaine(s.texte)) + car(10) dans o
        cas g = "graphe"
          fig += 1
          locale nomf = prefixe + "_fig" + fig + ".svg"
          fichier.ecrire(fichier.joindre(dossier_fig, nomf), SVG_GRAPHE(s, 760, 340))
          inserer "![" + chaine(sisinon(s.titre = nul, "Graphe " + fig, s.titre)) + "](" + nomf + ")" + car(10) dans o
        cas g = "table"
          locale t = {}
          inserer "| " + joindre(LISTE_MD(s.colonnes), " | ") + " |" dans t
          locale sep = {}
          pour chaque x dans s.colonnes
            inserer "---" dans sep
          suivant
          inserer "| " + joindre(sep, " | ") + " |" dans t
          locale n = 0
          pour chaque r dans s.lignes
            n += 1
            si n > 100
              sortir
            finsi
            inserer "| " + joindre(LISTE_MD(r), " | ") + " |" dans t
          suivant
          locale total = sisinon(s.total = nul, taille(s.lignes), s.total)
          si total > min(100, taille(s.lignes))
            inserer car(10) + "*" + min(100, taille(s.lignes)) + " lignes sur " + total + "*" dans t
          finsi
          inserer joindre(t, car(10)) + car(10) dans o
        fincas
      suivant
    finsi
  suivant
retourner joindre(o, car(10))

fonction LISTE_MD(l)
  locale r = {}
  pour chaque v dans l
    inserer CELLULE_MD(v) dans r
  suivant
retourner r

procedure EXPORTER_MARKDOWN
  EXPORTER_VERS(CHOISIR_EXPORT(".md", "*.md"))
retourner

procedure EXPORTER_PDF
  EXPORTER_VERS(CHOISIR_EXPORT(".pdf", "*.pdf"))
retourner

procedure EXPORT_PDF(p)
  locale tmp = systeme.nomtemporaire() + "-pdf"
  fichier.creerdossier(tmp)
  essayer
    locale md = MARKDOWN_CARNET(tmp, "carnet")
    publication.pdf(p, md, {format = "a4", titre = TITRE_CARNET(), dossier = tmp, ;
                            pied = "|{titre}|{page} / {pages}"})
  capturer e
    fichier.supprimer(tmp)
    erreur chaine(e)
  finessayer
  fichier.supprimer(tmp)
retourner

&& ---------------------------------------------------------------- programme .prg

&& sépare le code d'une cellule : {corps = lignes, defs = lignes des procédures}
fonction SEPARER_CODE(src)
  locale lignes = decouper(remplacertexte(src, car(13), ""), car(10))
  locale corps = {}
  locale defs = {}
  locale i = 1
  locale n = taille(lignes)
  tantque i <= n
    locale l = lignes[i]
    si EST_DEFINITION(minuscule(rognerg(l)))
      locale r0 = RETRAIT(l)
      locale nb = 0
      tantque i <= n
        locale li = lignes[i]
        inserer li dans defs
        nb += 1
        i += 1
        si nb > 1 et commencepar(minuscule(rognerg(li)), "retourner") et RETRAIT(li) = r0
          sortir
        finsi
      fintantque
      inserer "" dans defs
    sinon
      inserer l dans corps
      i += 1
    finsi
  fintantque
retourner {corps = corps, defs = defs}

fonction AIDES_CONSOLE()
retourner [[
&& ---- affichage en console (le carnet affiche ces résultats en tableaux et graphes)
procedure AFFICHER(x)
  si type(x) = "table" et taille(x) > 0 et type(x[1]) = "table"
    AFFICHER_TABLE(x)
    retourner
  finsi
  si type(x) = "table"
    ? json(x)
  sinon
    ? x
  finsi
retourner

procedure AFFICHER_TABLE(lignes, colonnes)
  pour chaque r dans lignes
    si type(r) <> "table"
      ? r
    sinon
      locale morceaux = {}
      pour chaque k, v dans r
        inserer chaine(v) dans morceaux
      suivant
      ? joindre(morceaux, " | ")
    finsi
  suivant
retourner

procedure AFFICHER_GRAPHE(genre, categories, series, titre)
  ? "[graphe " + chaine(genre) + "] " + sisinon(titre = nul, "", titre)
retourner

procedure AFFICHER_GRAPHE_TABLE(lignes, categorie, valeurs, genre, titre)
  ? "[graphe " + chaine(genre) + "] " + sisinon(titre = nul, "", titre)
retourner

procedure AFFICHER_MD(t)
  ? t
retourner

procedure AFFICHER_SQL(s)
  AFFICHER_TABLE(requete(s))
retourner
]]

procedure EXPORTER_PRG
  EXPORTER_VERS(CHOISIR_EXPORT(".prg", "*.prg"))
retourner

fonction PROGRAMME_CARNET()
  SYNC_SOURCES()
  locale corps = {}
  locale defs = {}
  inserer "&& " + TITRE_CARNET() + " — programme exporté de Carnet Lexis+ le " + maintenant() dans corps
  inserer "&& Les textes du carnet sont en commentaires ; les procédures des cellules sont à la fin." dans corps
  inserer "ouvrirbase(" + car(34) + ":memoire:" + car(34) + ")" dans corps
  inserer "" dans corps
  locale k = 0
  pour chaque c dans carnet.cellules
    k += 1
    si c.exporter = faux
      inserer "&& ---- cellule " + k + " : exclue de l'export" dans corps
    sinonsi c.genre = "markdown"
      pour chaque l dans decouper(c.source, car(10))
        inserer rognerd("&& " + l) dans corps
      suivant
    sinonsi c.genre = "sql"
      inserer "&& ---- cellule " + k + " (SQL)" dans corps
      locale instr = DECOUPER_SQL(c.source)
      pour j = 1 a taille(instr)
        inserer sisinon(j = taille(instr), "AFFICHER_SQL(", "requete(") + LITTERAL(instr[j].texte) + ")" dans corps
      suivant
    sinon
      inserer "&& ---- cellule " + k dans corps
      locale sc = SEPARER_CODE(c.source)
      pour chaque l dans sc.corps
        inserer l dans corps
      suivant
      pour chaque l dans sc.defs
        inserer l dans defs
      suivant
    finsi
    inserer "" dans corps
  suivant
  pour chaque l dans defs
    inserer l dans corps
  suivant
  inserer AIDES_CONSOLE() dans corps
retourner joindre(corps, car(10))

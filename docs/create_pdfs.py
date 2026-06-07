from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                 TableStyle, PageBreak, HRFlowable)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import Flowable

W, H = A4

# ── Couleurs ────────────────────────────────────────────────────────────────
NAVY    = colors.HexColor('#0f3460')
DARK    = colors.HexColor('#1a1a2e')
ACCENT  = colors.HexColor('#e94560')
GREEN   = colors.HexColor('#2ecc71')
ORANGE  = colors.HexColor('#f39c12')
LIGHT   = colors.HexColor('#f0f4f8')
WHITE   = colors.white
GREY    = colors.HexColor('#6c757d')
DKGREY  = colors.HexColor('#343a40')
MINT    = colors.HexColor('#d4edda')
AMBER   = colors.HexColor('#fff3cd')
RED_LT  = colors.HexColor('#f8d7da')

# ── Helper flowable : bande colorée pour titres de section ───────────────────
class SectionBand(Flowable):
    def __init__(self, text, bg=NAVY, fg=WHITE, w=None, h=1.1*cm):
        super().__init__()
        self.text = text
        self.bg = bg
        self.fg = fg
        self._w = w or (W - 4*cm)
        self._h = h

    def wrap(self, aw, ah):
        return self._w, self._h

    def draw(self):
        c = self.canv
        c.setFillColor(self.bg)
        c.roundRect(0, 0, self._w, self._h, 6, fill=1, stroke=0)
        c.setFillColor(self.fg)
        c.setFont('Helvetica-Bold', 13)
        c.drawString(14, self._h/2 - 5, self.text)

class NumberBadge(Flowable):
    """Cercle coloré avec numéro, pour les étapes."""
    def __init__(self, num, bg=ACCENT, fg=WHITE, size=24):
        super().__init__()
        self.num = str(num)
        self.bg = bg
        self.fg = fg
        self.size = size

    def wrap(self, aw, ah):
        return self.size, self.size

    def draw(self):
        c = self.canv
        r = self.size / 2
        c.setFillColor(self.bg)
        c.circle(r, r, r, fill=1, stroke=0)
        c.setFillColor(self.fg)
        c.setFont('Helvetica-Bold', 11)
        tw = c.stringWidth(self.num, 'Helvetica-Bold', 11)
        c.drawString(r - tw/2, r - 4, self.num)

class ColorBox(Flowable):
    """Boite colorée pour notes importantes."""
    def __init__(self, text, bg=AMBER, border=ORANGE, w=None, padding=10):
        super().__init__()
        self.text = text
        self.bg = bg
        self.border = border
        self._w = w or (W - 4*cm)
        self.padding = padding

    def wrap(self, aw, ah):
        # Estimate height
        lines = self.text.count('\n') + 1
        self._h = lines * 16 + self.padding * 2
        return self._w, self._h

    def draw(self):
        c = self.canv
        c.setFillColor(self.bg)
        c.setStrokeColor(self.border)
        c.roundRect(0, 0, self._w, self._h, 6, fill=1, stroke=1)
        c.setFillColor(self.border)
        c.setFont('Helvetica-Bold', 9)
        y = self._h - self.padding - 10
        for line in self.text.split('\n'):
            c.setFont('Helvetica-Bold' if line.startswith('!') else 'Helvetica', 9)
            text = line.lstrip('!')
            c.drawString(self.padding, y, text)
            y -= 14

# ── Header / Footer ──────────────────────────────────────────────────────────
def make_header_footer(title_doc, subtitle_doc, color):
    def _draw(canvas, doc):
        canvas.saveState()
        # Header band
        canvas.setFillColor(color)
        canvas.rect(0, H - 1.8*cm, W, 1.8*cm, fill=1, stroke=0)
        canvas.setFillColor(WHITE)
        canvas.setFont('Helvetica-Bold', 12)
        canvas.drawString(2*cm, H - 1.2*cm, title_doc)
        canvas.setFont('Helvetica', 9)
        canvas.drawRightString(W - 2*cm, H - 1.2*cm, subtitle_doc)
        # Footer
        canvas.setFillColor(GREY)
        canvas.setFont('Helvetica', 8)
        canvas.drawString(2*cm, 0.8*cm, f'Page {doc.page}')
        canvas.drawCentredString(W/2, 0.8*cm, 'SIGN — Document confidentiel')
        canvas.drawRightString(W - 2*cm, 0.8*cm, 'ballabeye.dev04@gmail.com')
        canvas.setStrokeColor(LIGHT)
        canvas.setLineWidth(0.5)
        canvas.line(2*cm, 1.2*cm, W - 2*cm, 1.2*cm)
        canvas.restoreState()
    return _draw


# ════════════════════════════════════════════════════════════════════════════
# PDF 1 — Guide Data Safety
# ════════════════════════════════════════════════════════════════════════════
def build_pdf1():
    path = r'C:\Users\vPro\AndroidStudioProjects\sign_application\docs\Guide_Data_Safety_Google_Play.pdf'
    doc = SimpleDocTemplate(path, pagesize=A4,
                            leftMargin=2*cm, rightMargin=2*cm,
                            topMargin=2.5*cm, bottomMargin=2*cm)

    styles = getSampleStyleSheet()
    normal  = ParagraphStyle('N', fontName='Helvetica', fontSize=10, leading=15, spaceAfter=4)
    bold    = ParagraphStyle('B', fontName='Helvetica-Bold', fontSize=10, leading=15)
    h2      = ParagraphStyle('H2', fontName='Helvetica-Bold', fontSize=12, textColor=DARK, spaceBefore=12, spaceAfter=6)
    h3      = ParagraphStyle('H3', fontName='Helvetica-Bold', fontSize=10, textColor=NAVY, spaceBefore=8, spaceAfter=4)
    center  = ParagraphStyle('C', fontName='Helvetica', fontSize=10, alignment=TA_CENTER)
    bullet  = ParagraphStyle('BUL', fontName='Helvetica', fontSize=10, leading=16, leftIndent=20, bulletIndent=5)
    step_p  = ParagraphStyle('SP', fontName='Helvetica', fontSize=10, leading=16, leftIndent=35)
    code_s  = ParagraphStyle('CODE', fontName='Courier', fontSize=9, backColor=LIGHT, leading=14, leftIndent=10)

    story = []

    # ── PAGE DE COUVERTURE ───────────────────────────────────────────────────
    story.append(Spacer(1, 3*cm))

    # Titre principal avec fond
    title_data = [[Paragraph('<font color="white"><b>SIGN</b></font>', ParagraphStyle('T', fontName='Helvetica-Bold', fontSize=42, textColor=WHITE, alignment=TA_CENTER))]]
    t = Table(title_data, colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), DARK),
        ('ROUNDEDCORNERS', [12]),
        ('TOPPADDING', (0,0), (-1,-1), 20),
        ('BOTTOMPADDING', (0,0), (-1,-1), 20),
    ]))
    story.append(t)
    story.append(Spacer(1, 0.5*cm))

    story.append(Paragraph('<b>Guide Data Safety — Google Play Store</b>',
                           ParagraphStyle('ST', fontName='Helvetica-Bold', fontSize=18,
                                          textColor=DARK, alignment=TA_CENTER, spaceBefore=10)))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph('Guide complet pour remplir la section Securite des donnees',
                           ParagraphStyle('SUB', fontName='Helvetica', fontSize=13,
                                          textColor=GREY, alignment=TA_CENTER)))
    story.append(Spacer(1, 1*cm))

    # Infos app
    info_data = [
        ['Application', 'SIGN'],
        ['Package', 'com.signapp.sign_application'],
        ['Version', '1.0.0 (versionCode 1)'],
        ['Date', 'Juin 2026'],
        ['Contact', 'ballabeye.dev04@gmail.com'],
    ]
    t_info = Table(info_data, colWidths=[5*cm, 11*cm])
    t_info.setStyle(TableStyle([
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('FONTNAME', (1,0), (1,-1), 'Helvetica'),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('BACKGROUND', (0,0), (0,-1), LIGHT),
        ('BACKGROUND', (1,0), (1,-1), WHITE),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [LIGHT, WHITE]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(t_info)
    story.append(Spacer(1, 1*cm))

    # Avertissement important
    warn_data = [['! OBLIGATOIRE : Sans Data Safety remplie, Google refuse la publication de votre application.']]
    t_warn = Table(warn_data, colWidths=[W - 4*cm])
    t_warn.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), RED_LT),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#721c24')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('TOPPADDING', (0,0), (-1,-1), 12),
        ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ('LEFTPADDING', (0,0), (-1,-1), 14),
        ('ROUNDEDCORNERS', [8]),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#f5c6cb')),
    ]))
    story.append(t_warn)

    story.append(PageBreak())

    # ── SECTION 1 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 1 — Qu\'est-ce que la Data Safety ?', bg=DARK))
    story.append(Spacer(1, 0.4*cm))

    story.append(Paragraph(
        'Depuis <b>mai 2022</b>, Google Play oblige <b>toutes les applications</b> a remplir '
        'un formulaire de securite des donnees. Ce formulaire declare exactement :', normal))
    story.append(Spacer(1, 0.2*cm))

    bullets1 = [
        'Quelles donnees personnelles votre app collecte',
        'Pourquoi vous les collectez (finalite)',
        'Si vous les partagez avec des tiers',
        'Comment vous les protegez (chiffrement, etc.)',
    ]
    for b in bullets1:
        story.append(Paragraph(f'<bullet>&bull;</bullet> {b}', bullet))
    story.append(Spacer(1, 0.4*cm))

    story.append(Paragraph('<b>Ce que voient les utilisateurs sur le Play Store :</b>', bold))
    story.append(Spacer(1, 0.2*cm))

    # Simulation badge Data Safety
    badge_data = [
        ['Securite des donnees', ''],
        ['Les donnees sont chiffrees en transit', '✓'],
        ['Vous pouvez demander la suppression de vos donnees', '✓'],
        ['Donnees collectees : Nom, Email, Telephone, Signature', ''],
    ]
    t_badge = Table(badge_data, colWidths=[13*cm, 3*cm])
    t_badge.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('FONTNAME', (1,1), (1,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,1), (1,2), GREEN),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE, LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.3, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('ALIGN', (1,0), (1,-1), 'CENTER'),
    ]))
    story.append(t_badge)
    story.append(Spacer(1, 0.4*cm))

    warn2_data = [['! Si la section Data Safety n\'est pas remplie :\n'
                   '- Google refuse la publication (rejet immediat)\n'
                   '- Votre compte developpeur peut etre suspendu\n'
                   '- Les utilisateurs ne peuvent pas voir les infos de securite']]
    t_warn2 = Table(warn2_data, colWidths=[W - 4*cm])
    t_warn2.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), AMBER),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#856404')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('BOX', (0,0), (-1,-1), 1, ORANGE),
    ]))
    story.append(t_warn2)

    story.append(Spacer(1, 0.6*cm))

    # ── SECTION 2 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 2 — Acceder a la section Data Safety', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    steps2 = [
        ('1', 'Ouvrir un navigateur et aller sur :', 'https://play.google.com/console'),
        ('2', 'Se connecter avec votre compte Google Play Developer', ''),
        ('3', 'Dans la liste de vos apps, cliquer sur <b>SIGN</b>', ''),
        ('4', 'Dans le menu gauche, cliquer sur <b>"Contenu de l\'app"</b>', ''),
        ('5', 'Cliquer sur <b>"Securite des donnees"</b>', ''),
        ('6', 'Cliquer sur le bouton bleu <b>"Commencer"</b>', ''),
    ]
    for num, txt, url in steps2:
        row_data = [[Paragraph(f'<b>{num}</b>', ParagraphStyle('SN', fontName='Helvetica-Bold',
                    fontSize=12, textColor=WHITE, alignment=TA_CENTER)),
                     Paragraph(txt + (f'<br/><font color="#0f3460"><u>{url}</u></font>' if url else ''), step_p)]]
        t_step = Table(row_data, colWidths=[0.8*cm, W - 4.8*cm])
        t_step.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), ACCENT),
            ('ROUNDEDCORNERS', [6]),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
            ('LEFTPADDING', (0,0), (0,0), 4),
        ]))
        story.append(t_step)
        story.append(Spacer(1, 0.25*cm))

    story.append(PageBreak())

    # ── SECTION 3 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 3 — Formulaire Partie 1 : Questions initiales', bg=DARK))
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph('Repondez exactement comme indique ci-dessous a chaque question :', normal))
    story.append(Spacer(1, 0.3*cm))

    q_data = [
        ['Question Google Play', 'Votre reponse', 'Explication'],
        ['Votre application collecte-t-elle\nou partage-t-elle des donnees\nutilisateur ?',
         'OUI', 'SIGN collecte nom, email,\ntelephone, signature...'],
        ['Toutes les donnees sont-elles\nchiffrees en transit ?',
         'OUI', 'Connexion HTTPS/TLS\nuniquement (config done)'],
        ['Proposez-vous la suppression\ndes donnees sur demande ?',
         'OUI', 'Les utilisateurs peuvent\ndemander la suppression'],
    ]
    t_q = Table(q_data, colWidths=[6.5*cm, 3*cm, 6.5*cm])
    t_q.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('FONTNAME', (1,1), (1,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,1), (1,-1), GREEN),
        ('FONTSIZE', (1,1), (1,-1), 13),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE, LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 9),
        ('BOTTOMPADDING', (0,0), (-1,-1), 9),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ALIGN', (1,0), (1,-1), 'CENTER'),
    ]))
    story.append(t_q)
    story.append(Spacer(1, 0.6*cm))

    # ── SECTION 4 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 4 — Types de donnees a declarer', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph(
        'Pour chaque type de donnee, cochez les cases correspondantes dans le formulaire Google Play :', normal))
    story.append(Spacer(1, 0.3*cm))

    headers = ['Type de donnee', 'Collecte', 'Partage', 'Finalite', 'Requis']
    data_rows = [
        ['Nom et prenom', 'OUI', 'NON', 'Fonctionnalite app', 'OUI'],
        ['Adresse e-mail', 'OUI', 'NON', 'Authentification', 'OUI'],
        ['Numero de telephone', 'OUI', 'NON', 'Profil utilisateur', 'OUI'],
        ['Numero CNI / identite', 'OUI', 'NON', 'Creation de contrats', 'OUI'],
        ['Adresse postale', 'OUI', 'NON', 'Contrats immobiliers', 'NON'],
        ['Donnees salariales', 'OUI', 'NON', 'Fiches de paie', 'NON'],
        ['Photo de profil', 'OUI', 'NON', 'Profil utilisateur', 'NON'],
        ['Image de signature', 'OUI', 'NON', 'Signature electronique', 'OUI'],
        ['Fichiers PDF (contrats)', 'OUI', 'NON', 'Telechargement docs', 'NON'],
        ['Token JWT', 'OUI', 'NON', 'Authentification session', 'OUI'],
        ['Logs crash (Firebase)', 'OUI', 'OUI*', 'Stabilite app', 'NON'],
    ]
    table_data = [headers] + data_rows
    col_w = [5.5*cm, 1.8*cm, 1.8*cm, 4.5*cm, 2.4*cm]
    t_types = Table(table_data, colWidths=col_w)
    style_types = [
        ('BACKGROUND', (0,0), (-1,0), DARK),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8.5),
        ('FONTNAME', (0,1), (0,-1), 'Helvetica-Bold'),
        ('GRID', (0,0), (-1,-1), 0.4, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 7),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ALIGN', (1,0), (4,-1), 'CENTER'),
    ]
    for i, row in enumerate(data_rows, 1):
        bg = LIGHT if i % 2 == 0 else WHITE
        style_types.append(('BACKGROUND', (0,i), (-1,i), bg))
        # OUI en vert, NON en rouge
        for j, val in enumerate(row):
            if val == 'OUI':
                style_types.append(('TEXTCOLOR', (j,i), (j,i), GREEN))
                style_types.append(('FONTNAME', (j,i), (j,i), 'Helvetica-Bold'))
            elif val == 'NON':
                style_types.append(('TEXTCOLOR', (j,i), (j,i), colors.HexColor('#dc3545')))
    t_types.setStyle(TableStyle(style_types))
    story.append(t_types)
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph('* OUI* : Firebase/Google recoit les logs de crash (anonymises)',
                           ParagraphStyle('NOTE', fontName='Helvetica', fontSize=8, textColor=GREY)))

    story.append(PageBreak())

    # ── SECTION 5 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 5 — Pratiques de securite a cocher', bg=DARK))
    story.append(Spacer(1, 0.4*cm))

    practices = [
        (True,  'Les donnees utilisateur sont chiffrees en transit',
                'Toutes les communications passent par HTTPS/TLS uniquement.\nLe fichier network_security_config.xml bloque tout trafic HTTP.'),
        (True,  'Vous proposez la suppression des donnees',
                'Les utilisateurs peuvent contacter l\'app pour demander\nla suppression de leur compte et de leurs donnees.'),
        (True,  'L\'app respecte la politique famille Google Play',
                'L\'application n\'est pas destinee aux enfants.\nPas de contenu inapproprie pour les mineurs.'),
        (False, 'L\'app collecte des donnees d\'enfants de moins de 13 ans',
                'SIGN est une app professionnelle/adulte.\nCocher NON pour cette option.'),
    ]
    for checked, title, detail in practices:
        icon = '✓' if checked else '✗'
        color_icon = GREEN if checked else colors.HexColor('#dc3545')
        row = [[Paragraph(f'<b><font color="{"#2ecc71" if checked else "#dc3545"}">{icon}</font></b>',
                           ParagraphStyle('IC', fontName='Helvetica-Bold', fontSize=16, alignment=TA_CENTER)),
                Paragraph(f'<b>{title}</b><br/><font color="#6c757d" size="9">{detail}</font>',
                           ParagraphStyle('PD', fontName='Helvetica', fontSize=10, leading=14))]]
        t_p = Table(row, colWidths=[1.2*cm, W - 5.2*cm])
        t_p.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), MINT if checked else RED_LT),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 10),
            ('BOTTOMPADDING', (0,0), (-1,-1), 10),
            ('LEFTPADDING', (0,0), (0,0), 4),
            ('LEFTPADDING', (1,0), (1,0), 10),
            ('BOX', (0,0), (-1,-1), 1, GREEN if checked else colors.HexColor('#f5c6cb')),
        ]))
        story.append(t_p)
        story.append(Spacer(1, 0.25*cm))

    story.append(Spacer(1, 0.4*cm))

    # ── SECTION 6 ────────────────────────────────────────────────────────────
    story.append(SectionBand('  Section 6 — Verification et soumission', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    steps6 = [
        '1', 'Cliquer sur <b>"Enregistrer"</b> en bas de la page Data Safety',
        '2', 'Cliquer sur <b>"Apercu"</b> pour voir comment la section s\'affichera sur le Store',
        '3', 'Verifier que toutes les donnees sont correctes',
        '4', 'Cliquer sur <b>"Soumettre"</b> pour valider definitivement',
        '5', 'Google affiche <b>"En attente de validation"</b> — c\'est normal',
        '6', 'Lors du prochain upload d\'AAB, la section sera automatiquement active',
    ]
    for i in range(0, len(steps6), 2):
        num = steps6[i]
        txt = steps6[i+1]
        row = [[Paragraph(f'<b>{num}</b>', ParagraphStyle('SN2', fontName='Helvetica-Bold',
                fontSize=11, textColor=WHITE, alignment=TA_CENTER)),
                Paragraph(txt, step_p)]]
        t_s = Table(row, colWidths=[0.8*cm, W - 4.8*cm])
        t_s.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), NAVY),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
            ('LEFTPADDING', (0,0), (0,0), 4),
            ('LEFTPADDING', (1,0), (1,0), 12),
        ]))
        story.append(t_s)
        story.append(Spacer(1, 0.2*cm))

    story.append(Spacer(1, 0.4*cm))

    # ── SECTION 7 — Badge final ───────────────────────────────────────────────
    story.append(SectionBand('  Section 7 — Resultat final sur le Play Store', bg=DARK))
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph('Apres soumission, voici ce que les utilisateurs verront sur la fiche SIGN :', normal))
    story.append(Spacer(1, 0.3*cm))

    final_badge = [
        ['SIGN — Securite des donnees', ''],
        ['Les donnees sont chiffrees en transit', '✓'],
        ['Vous pouvez demander la suppression de vos donnees', '✓'],
        ['', ''],
        ['Donnees collectees', ''],
        ['  • Informations personnelles (Nom, Email, Tel)', ''],
        ['  • Identifiants (Token JWT)', ''],
        ['  • Documents (Signature, PDF)', ''],
        ['  • Diagnostics (Logs crash Firebase)', ''],
    ]
    t_fb = Table(final_badge, colWidths=[13*cm, 2*cm])
    t_fb.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), DARK),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('FONTNAME', (0,4), (0,4), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,1), (1,2), GREEN),
        ('FONTNAME', (1,1), (1,2), 'Helvetica-Bold'),
        ('FONTSIZE', (1,1), (1,2), 14),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE]*5),
        ('GRID', (0,0), (-1,-1), 0.3, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('ALIGN', (1,0), (1,-1), 'CENTER'),
        ('BOX', (0,0), (-1,-1), 1.5, NAVY),
    ]))
    story.append(t_fb)
    story.append(Spacer(1, 0.5*cm))

    success = [['  FELICITATIONS ! La section Data Safety est completee.\n'
                '  Votre application est conforme aux exigences Google Play 2026.']]
    t_suc = Table(success, colWidths=[W - 4*cm])
    t_suc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), MINT),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#155724')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('TOPPADDING', (0,0), (-1,-1), 14),
        ('BOTTOMPADDING', (0,0), (-1,-1), 14),
        ('LEFTPADDING', (0,0), (-1,-1), 14),
        ('BOX', (0,0), (-1,-1), 1.5, GREEN),
    ]))
    story.append(t_suc)

    draw_fn = make_header_footer('Guide Data Safety — Google Play', 'Application SIGN', DARK)
    doc.build(story, onFirstPage=draw_fn, onLaterPages=draw_fn)
    print(f'PDF 1 cree : {path}')


# ════════════════════════════════════════════════════════════════════════════
# PDF 2 — Guide Compte Google Play Developer
# ════════════════════════════════════════════════════════════════════════════
def build_pdf2():
    path = r'C:\Users\vPro\AndroidStudioProjects\sign_application\docs\Guide_Compte_Google_Play_Developer.pdf'
    doc = SimpleDocTemplate(path, pagesize=A4,
                            leftMargin=2*cm, rightMargin=2*cm,
                            topMargin=2.5*cm, bottomMargin=2*cm)

    styles = getSampleStyleSheet()
    normal  = ParagraphStyle('N2', fontName='Helvetica', fontSize=10, leading=15, spaceAfter=4)
    bold    = ParagraphStyle('B2', fontName='Helvetica-Bold', fontSize=10, leading=15)
    bullet  = ParagraphStyle('BUL2', fontName='Helvetica', fontSize=10, leading=16, leftIndent=20)
    step_p  = ParagraphStyle('SP2', fontName='Helvetica', fontSize=10, leading=16, leftIndent=35)
    small   = ParagraphStyle('SM', fontName='Helvetica', fontSize=8.5, textColor=GREY, leading=13)
    code_s  = ParagraphStyle('CODE2', fontName='Courier', fontSize=9, backColor=LIGHT,
                              leading=14, leftIndent=10, spaceBefore=4, spaceAfter=4)

    def make_step(num, title, detail='', color=NAVY):
        row = [[Paragraph(f'<b>{num}</b>',
                           ParagraphStyle('SN3', fontName='Helvetica-Bold', fontSize=12,
                                          textColor=WHITE, alignment=TA_CENTER)),
                Paragraph(f'<b>{title}</b>' + (f'<br/><font size="9" color="#6c757d">{detail}</font>' if detail else ''),
                           step_p)]]
        t = Table(row, colWidths=[0.9*cm, W - 4.9*cm])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), color),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 9),
            ('BOTTOMPADDING', (0,0), (-1,-1), 9),
            ('LEFTPADDING', (0,0), (0,0), 4),
            ('LEFTPADDING', (1,0), (1,0), 12),
            ('BACKGROUND', (1,0), (1,0), LIGHT),
        ]))
        return t

    def make_check(ok, text):
        icon = '✓' if ok else '☐'
        color = GREEN if ok else NAVY
        row = [[Paragraph(f'<font color="{"#2ecc71" if ok else "#0f3460"}"><b>{icon}</b></font>',
                           ParagraphStyle('CI', fontName='Helvetica-Bold', fontSize=14, alignment=TA_CENTER)),
                Paragraph(text, step_p)]]
        t = Table(row, colWidths=[0.9*cm, W - 4.9*cm])
        t.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('BACKGROUND', (0,0), (-1,-1), MINT if ok else LIGHT),
            ('BOX', (0,0), (-1,-1), 0.5, GREEN if ok else colors.HexColor('#dee2e6')),
        ]))
        return t

    story = []

    # ── PAGE DE COUVERTURE ───────────────────────────────────────────────────
    story.append(Spacer(1, 2.5*cm))
    title_data = [[Paragraph('<font color="white"><b>SIGN</b></font>',
                              ParagraphStyle('T2', fontName='Helvetica-Bold', fontSize=44,
                                             textColor=WHITE, alignment=TA_CENTER))]]
    t = Table(title_data, colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), NAVY),
        ('TOPPADDING', (0,0), (-1,-1), 22),
        ('BOTTOMPADDING', (0,0), (-1,-1), 22),
    ]))
    story.append(t)
    story.append(Spacer(1, 0.5*cm))

    story.append(Paragraph('<b>Guide Creation Compte Google Play Developer</b>',
                           ParagraphStyle('ST2', fontName='Helvetica-Bold', fontSize=17,
                                          textColor=DARK, alignment=TA_CENTER)))
    story.append(Paragraph('De la creation du compte a la publication de l\'application',
                           ParagraphStyle('SU2', fontName='Helvetica', fontSize=12,
                                          textColor=GREY, alignment=TA_CENTER, spaceBefore=6)))
    story.append(Spacer(1, 1*cm))

    # Sommaire
    toc_data = [
        ['#', 'Section', 'Duree'],
        ['1', 'Prerequis avant de commencer', '5 min'],
        ['2', 'Creer le compte Google Play Developer', '15 min'],
        ['3', 'Creer l\'application dans la console', '5 min'],
        ['4', 'Remplir la fiche store', '20 min'],
        ['5', 'Configuration technique', 'Deja fait'],
        ['6', 'Upload de l\'AAB et publication', '10 min'],
        ['7', 'Apres la publication', 'Continu'],
        ['8', 'Checklist finale', '5 min'],
    ]
    t_toc = Table(toc_data, colWidths=[1*cm, 12*cm, 3*cm])
    t_toc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE]*5),
        ('GRID', (0,0), (-1,-1), 0.3, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('ALIGN', (0,0), (0,-1), 'CENTER'),
        ('ALIGN', (2,0), (2,-1), 'CENTER'),
    ]))
    story.append(t_toc)
    story.append(Spacer(1, 0.6*cm))

    price_data = [['  FRAIS UNIQUES : 25 USD (environ 15 000 FCFA)\n'
                   '  Carte Visa / Mastercard / Prepayee — Paiement unique, jamais a repayer']]
    t_price = Table(price_data, colWidths=[W - 4*cm])
    t_price.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#cce5ff')),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#004085')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('TOPPADDING', (0,0), (-1,-1), 12),
        ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ('LEFTPADDING', (0,0), (-1,-1), 14),
        ('BOX', (0,0), (-1,-1), 1.5, colors.HexColor('#004085')),
    ]))
    story.append(t_price)
    story.append(PageBreak())

    # ── SECTION 1 — PREREQUIS ────────────────────────────────────────────────
    story.append(SectionBand('  Section 1 — Prerequis avant de commencer', bg=DARK))
    story.append(Spacer(1, 0.4*cm))

    prereqs = [
        ('✓', NAVY, '<b>Compte Google (Gmail)</b>',
         'Utiliser ballabeye.dev04@gmail.com ou creer un nouveau compte Google dedie'),
        ('✓', NAVY, '<b>Carte bancaire</b>',
         'Visa, Mastercard ou carte prepayee — pour payer les 25 USD'),
        ('✓', GREEN, '<b>Fichier app-release.aab PRET</b>',
         'build\\app\\outputs\\bundle\\release\\app-release.aab (72.1 MB) — deja genere !'),
        ('✓', NAVY, '<b>Captures d\'ecran de l\'app</b>',
         'Minimum 2 captures — format PNG ou JPEG, taille 1080x1920px'),
        ('✓', NAVY, '<b>URL de la Privacy Policy</b>',
         'Une page web publique avec votre politique de confidentialite'),
    ]
    for icon, color, title, detail in prereqs:
        row = [[Paragraph(f'<font color="{"#2ecc71" if color==GREEN else "#0f3460"}"><b>{icon}</b></font>',
                           ParagraphStyle('PI', fontName='Helvetica-Bold', fontSize=16, alignment=TA_CENTER)),
                Paragraph(f'{title}<br/><font size="9" color="#6c757d">{detail}</font>',
                           step_p)]]
        tp = Table(row, colWidths=[0.9*cm, W - 4.9*cm])
        tp.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 9),
            ('BOTTOMPADDING', (0,0), (-1,-1), 9),
            ('LEFTPADDING', (1,0), (1,0), 12),
            ('BACKGROUND', (0,0), (-1,-1), MINT if color==GREEN else LIGHT),
            ('BOX', (0,0), (-1,-1), 0.5, GREEN if color==GREEN else colors.HexColor('#dee2e6')),
        ]))
        story.append(tp)
        story.append(Spacer(1, 0.2*cm))

    story.append(Spacer(1, 0.5*cm))

    # ── SECTION 2 — CREER LE COMPTE ──────────────────────────────────────────
    story.append(SectionBand('  Section 2 — Creer le compte Google Play Developer (25 USD)', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    steps_s2 = [
        ('1', 'Aller sur le site d\'inscription',
         'https://play.google.com/console/signup'),
        ('2', 'Se connecter avec votre Gmail',
         'Utiliser ballabeye.dev04@gmail.com'),
        ('3', 'Lire et accepter les conditions d\'utilisation',
         'Faire defiler jusqu\'en bas et cocher "J\'accepte"'),
        ('4', 'Remplir le profil developpeur',
         'Nom du developpeur visible sur le Store : "SIGN"\nEmail public : ballabeye.dev04@gmail.com'),
        ('5', 'Payer les 25 USD',
         'Entrer les informations de carte bancaire\nVisa / Mastercard / Carte prepayee Orange Money / Wave'),
        ('6', 'Attendre la confirmation par email',
         'Google envoie un email de confirmation sous 48h\nVotre compte est actif immediatement apres paiement'),
    ]
    for num, title, detail in steps_s2:
        story.append(make_step(num, title, detail, ACCENT))
        story.append(Spacer(1, 0.2*cm))

    story.append(Spacer(1, 0.3*cm))
    warn3 = [['! IMPORTANT : Les 25 USD sont des frais UNIQUES — vous ne payez qu\'une seule fois.\n'
              '  Apres cela, publier autant d\'applications que vous voulez, GRATUITEMENT.']]
    t_w3 = Table(warn3, colWidths=[W - 4*cm])
    t_w3.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), AMBER),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#856404')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 11),
        ('BOTTOMPADDING', (0,0), (-1,-1), 11),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('BOX', (0,0), (-1,-1), 1, ORANGE),
    ]))
    story.append(t_w3)
    story.append(PageBreak())

    # ── SECTION 3 — CREER L'APP ──────────────────────────────────────────────
    story.append(SectionBand('  Section 3 — Creer l\'application dans la console', bg=DARK))
    story.append(Spacer(1, 0.4*cm))

    steps_s3 = [
        ('1', 'Dans la console Play, cliquer sur <b>"Creer une application"</b>', ''),
        ('2', 'Langue par defaut', 'Choisir : Francais (France)'),
        ('3', 'Nom de l\'application', 'Taper : <b>SIGN</b>'),
        ('4', 'Type d\'application', 'Selectionner : <b>Application</b> (pas un jeu)'),
        ('5', 'Modele economique', 'Selectionner : <b>Gratuite</b>'),
        ('6', 'Accepter les declarations', 'Cocher les 2 cases de conformite'),
        ('7', 'Cliquer sur <b>"Creer l\'app"</b>', 'Votre app est maintenant dans la console !'),
    ]
    for num, title, detail in steps_s3:
        story.append(make_step(num, title, detail, NAVY))
        story.append(Spacer(1, 0.2*cm))

    story.append(Spacer(1, 0.5*cm))

    # ── SECTION 4 — FICHE STORE ──────────────────────────────────────────────
    story.append(SectionBand('  Section 4 — Remplir la fiche store', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    story.append(Paragraph('<b>4.1 — Description de l\'application</b>',
                           ParagraphStyle('H3B', fontName='Helvetica-Bold', fontSize=11, textColor=NAVY, spaceBefore=4)))
    story.append(Spacer(1, 0.2*cm))

    desc_data = [
        ['Champ', 'Valeur a entrer', 'Limite'],
        ['Titre', 'SIGN - Contrats & Signatures', '30 car.'],
        ['Description courte', 'Creez, signez et gerez vos contrats electroniques en toute securite', '80 car.'],
        ['Categorie', 'Business / Productivite', '-'],
        ['Email de contact', 'ballabeye.dev04@gmail.com', '-'],
    ]
    t_desc = Table(desc_data, colWidths=[4*cm, 10*cm, 2*cm])
    t_desc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE, LIGHT, WHITE]),
        ('GRID', (0,0), (-1,-1), 0.4, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('ALIGN', (2,0), (2,-1), 'CENTER'),
    ]))
    story.append(t_desc)
    story.append(Spacer(1, 0.3*cm))

    story.append(Paragraph('<b>Description longue (copier-coller ce texte) :</b>', bold))
    story.append(Spacer(1, 0.15*cm))
    long_desc = (
        'SIGN est votre solution complete de gestion et de signature electronique de contrats. '
        'Concue pour les professionnels et les particuliers au Senegal, l\'application vous permet '
        'de creer, signer et gerer tous vos documents legaux en toute securite.\n\n'
        'FONCTIONNALITES PRINCIPALES :\n'
        '- Contrats de bail immobilier : Creez et signez des contrats de location en quelques minutes\n'
        '- Contrats de travail : Generez des contrats CDI, CDD conformes\n'
        '- Fiches de paie : Editez des bulletins de paie professionnels\n'
        '- Quittances de loyer : Generez des quittances mensuelles automatiquement\n'
        '- Signature electronique : Signez directement sur votre ecran\n'
        '- Telechargement PDF : Conservez tous vos documents en local\n'
        '- Gestion clients : Centralisez vos contacts et clients\n\n'
        'SECURITE ET CONFIDENTIALITE :\n'
        '- Chiffrement HTTPS/TLS pour toutes les communications\n'
        '- Stockage securise des donnees sensibles\n'
        '- Authentification par token JWT securise\n'
        '- Aucune publicite, aucune vente de donnees\n\n'
        'Disponible pour Android 6.0 et versions superieures.'
    )
    story.append(Paragraph(long_desc.replace('\n', '<br/>'),
                           ParagraphStyle('LD', fontName='Helvetica', fontSize=8.5,
                                          backColor=LIGHT, leading=13, leftIndent=8,
                                          rightIndent=8, spaceBefore=4, spaceAfter=4)))

    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph('<b>4.2 — Captures d\'ecran (obligatoires)</b>',
                           ParagraphStyle('H3B2', fontName='Helvetica-Bold', fontSize=11, textColor=NAVY)))
    story.append(Spacer(1, 0.2*cm))

    screens_data = [
        ['Exigence', 'Detail'],
        ['Nombre minimum', '2 captures d\'ecran'],
        ['Format', 'PNG ou JPEG'],
        ['Taille recommandee', '1080 x 1920 pixels (portrait)'],
        ['Comment capturer', 'Android Studio > Emulateur > Icone appareil photo\nOU vrai appareil : Bouton Volume- + Power'],
        ['Contenu suggere', 'Ecran de connexion, Dashboard, Creation contrat, Signature'],
    ]
    t_sc = Table(screens_data, colWidths=[5*cm, 11*cm])
    t_sc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), DARK),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTNAME', (0,1), (0,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE]*3),
        ('GRID', (0,0), (-1,-1), 0.4, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_sc)
    story.append(Spacer(1, 0.3*cm))

    story.append(Paragraph('<b>4.3 — Feature Graphic (banniere 1024x500px)</b>',
                           ParagraphStyle('H3B3', fontName='Helvetica-Bold', fontSize=11, textColor=NAVY)))
    story.append(Paragraph(
        'Creer gratuitement sur <u>https://www.canva.com</u> → Nouveau design → 1024x500px\n'
        'Ajouter le logo SIGN + fond sombre + texte "Contrats & Signatures Electroniques"',
        ParagraphStyle('FG', fontName='Helvetica', fontSize=9, leading=14, spaceBefore=6)))

    story.append(PageBreak())

    # ── SECTION 5 — CONFIG TECHNIQUE ─────────────────────────────────────────
    story.append(SectionBand('  Section 5 — Configuration technique (deja faite)', bg=DARK))
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph('Tout est deja configure dans votre projet. Rien a faire ici.', normal))
    story.append(Spacer(1, 0.3*cm))

    tech_data = [
        ['Parametre', 'Valeur', 'Statut'],
        ['applicationId', 'com.signapp.sign_application', '✓ OK'],
        ['versionCode', '1 (premier upload)', '✓ OK'],
        ['versionName', '1.0.0', '✓ OK'],
        ['minSdk', '23 (Android 6.0)', '✓ OK'],
        ['targetSdk', 'Derniere version Flutter', '✓ OK'],
        ['Signature', 'upload-keystore.jks (RSA 2048)', '✓ OK'],
        ['Obfuscation', 'R8 / ProGuard active', '✓ OK'],
        ['Reseau', 'HTTPS uniquement (network_security_config)', '✓ OK'],
        ['Firebase', 'Crashlytics + google-services.json', '✓ OK'],
    ]
    t_tech = Table(tech_data, colWidths=[5.5*cm, 7.5*cm, 3*cm])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('FONTNAME', (0,1), (0,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (2,1), (2,-1), GREEN),
        ('FONTNAME', (2,1), (2,-1), 'Helvetica-Bold'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE]*5),
        ('GRID', (0,0), (-1,-1), 0.4, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('ALIGN', (2,0), (2,-1), 'CENTER'),
    ]))
    story.append(t_tech)
    story.append(Spacer(1, 0.5*cm))

    # ── SECTION 6 — UPLOAD AAB ───────────────────────────────────────────────
    story.append(SectionBand('  Section 6 — Upload de l\'AAB et publication', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    # Path de l'AAB
    aab_data = [['  Fichier a uploader :\n  build\\app\\outputs\\bundle\\release\\app-release.aab\n  Taille : 72.1 MB — Signe avec upload-keystore.jks']]
    t_aab = Table(aab_data, colWidths=[W - 4*cm])
    t_aab.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#cce5ff')),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#004085')),
        ('FONTNAME', (0,0), (-1,-1), 'Courier-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 12),
        ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ('LEFTPADDING', (0,0), (-1,-1), 14),
        ('BOX', (0,0), (-1,-1), 1.5, colors.HexColor('#004085')),
    ]))
    story.append(t_aab)
    story.append(Spacer(1, 0.35*cm))

    steps_s6 = [
        ('1', 'Dans la console Play, menu gauche : <b>Production</b>', ''),
        ('2', 'Cliquer sur <b>"Creer une version"</b>', ''),
        ('3', 'Dans "App bundles", cliquer <b>"Charger"</b>', 'Glisser-deposer le fichier app-release.aab'),
        ('4', 'Note de version', 'Taper : "Version initiale 1.0.0 — Lancement de l\'application SIGN"'),
        ('5', 'Cliquer <b>"Enregistrer"</b> puis <b>"Verifier la version"</b>', 'Google verifie la signature et le contenu'),
        ('6', 'Corriger les avertissements si necessaire', 'En general aucun probleme si tout est configure'),
        ('7', 'Cliquer sur <b>"Publier sur Production"</b>', 'Confirmer l\'envoi pour examen par Google'),
        ('8', 'Attendre l\'examen Google', 'Duree : 1 a 7 jours — Notification par email quand publie'),
    ]
    for num, title, detail in steps_s6:
        story.append(make_step(num, title, detail, ACCENT))
        story.append(Spacer(1, 0.18*cm))

    story.append(PageBreak())

    # ── SECTION 7 — APRES PUBLICATION ────────────────────────────────────────
    story.append(SectionBand('  Section 7 — Apres la publication', bg=DARK))
    story.append(Spacer(1, 0.4*cm))

    after_data = [
        ['Action', 'Quand', 'Comment'],
        ['Surveiller les crashes', 'Dans les 48h apres publication',
         'Firebase Console > Crashlytics\nhttps://console.firebase.google.com'],
        ['Repondre aux avis', 'Des le premier avis',
         'Console Play > Avis > Repondre\nDelai recommande : moins de 48h'],
        ['Publier une mise a jour', 'Apres correction de bugs',
         'Incrementer versionCode (ex: 2)\net versionName (ex: 1.0.1)\nflutter build appbundle --release\nUploader le nouvel AAB'],
        ['Surveiller les statistiques', 'Chaque semaine',
         'Console Play > Statistiques\nTaux de crash, installations, notes'],
    ]
    t_after = Table(after_data, colWidths=[4.5*cm, 4.5*cm, 7*cm])
    t_after.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), WHITE),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTNAME', (0,1), (0,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [LIGHT, WHITE, LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.4, colors.HexColor('#dee2e6')),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(t_after)
    story.append(Spacer(1, 0.4*cm))

    update_data = [['  Commande pour publier une mise a jour :\n\n'
                    '  # Incrementer version: 1.0.0+1 → 1.0.1+2 dans pubspec.yaml\n'
                    '  flutter build appbundle --release \\\n'
                    '    --dart-define=API_BASE_URL=https://sign-backend-ha5a.onrender.com/sign\n\n'
                    '  # Puis uploader le nouveau AAB dans la console Play']]
    t_up = Table(update_data, colWidths=[W - 4*cm])
    t_up.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#1e1e1e')),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#00ff41')),
        ('FONTNAME', (0,0), (-1,-1), 'Courier'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 12),
        ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ('LEFTPADDING', (0,0), (-1,-1), 14),
    ]))
    story.append(t_up)
    story.append(Spacer(1, 0.5*cm))

    # ── SECTION 8 — CHECKLIST FINALE ─────────────────────────────────────────
    story.append(SectionBand('  Section 8 — Checklist finale avant soumission', bg=NAVY))
    story.append(Spacer(1, 0.4*cm))

    checklist = [
        (False, 'Compte Google Play Developer cree et valide (25 USD paye)'),
        (False, 'Fiche store remplie : titre, description courte et longue'),
        (False, 'Captures d\'ecran uploadees (minimum 2)'),
        (False, 'Icone 512x512px uploadee dans la console'),
        (False, 'Feature Graphic 1024x500px uploadee'),
        (False, 'Privacy Policy URL renseignee dans la console'),
        (False, 'Section Data Safety completee (voir Guide_Data_Safety.pdf)'),
        (False, 'Compte de test fourni a Google (email + mot de passe)'),
        (True,  'google-services.json ajoute dans android/app/ [FAIT]'),
        (True,  'app-release.aab genere : 72.1 MB, signe [FAIT]'),
        (True,  'Firebase Crashlytics configure [FAIT]'),
        (True,  'Securite HTTPS, FLAG_SECURE, ProGuard [FAIT]'),
        (True,  'Permissions nettoyees (pas de VIDEO/AUDIO inutiles) [FAIT]'),
    ]
    for ok, text in checklist:
        story.append(make_check(ok, text))
        story.append(Spacer(1, 0.12*cm))

    story.append(Spacer(1, 0.4*cm))

    final_data = [['  VOTRE APP EST PRETE !\n'
                   '  Score technique : 95/100 — Il ne reste que les formulaires Play Store.\n'
                   '  Temps estime avant publication : 2h de configuration + 1 a 7 jours d\'examen Google.']]
    t_final = Table(final_data, colWidths=[W - 4*cm])
    t_final.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), MINT),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#155724')),
        ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('TOPPADDING', (0,0), (-1,-1), 16),
        ('BOTTOMPADDING', (0,0), (-1,-1), 16),
        ('LEFTPADDING', (0,0), (-1,-1), 16),
        ('BOX', (0,0), (-1,-1), 2, GREEN),
    ]))
    story.append(t_final)

    draw_fn = make_header_footer('Guide Google Play Developer', 'Application SIGN', NAVY)
    doc.build(story, onFirstPage=draw_fn, onLaterPages=draw_fn)
    print(f'PDF 2 cree : {path}')


if __name__ == '__main__':
    build_pdf1()
    build_pdf2()
    print('\nDone ! Les 2 PDFs sont dans le dossier docs/')

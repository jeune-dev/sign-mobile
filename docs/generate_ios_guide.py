#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère le PDF : Guide iOS Complet - BLK-05 + AS-03
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether, PageBreak
)
from reportlab.platypus.flowables import Flowable
from reportlab.lib.colors import HexColor
import datetime

# ── Couleurs ──────────────────────────────────────────────────────────────────
C_BLACK      = HexColor('#0A0A0A')
C_WHITE      = HexColor('#FFFFFF')
C_PRIMARY    = HexColor('#1A1A2E')      # Bleu très foncé
C_ACCENT     = HexColor('#4F46E5')      # Indigo
C_SUCCESS    = HexColor('#10B981')      # Vert
C_WARNING    = HexColor('#F59E0B')      # Orange
C_DANGER     = HexColor('#EF4444')      # Rouge
C_LIGHT_BG   = HexColor('#F8FAFC')
C_BORDER     = HexColor('#E2E8F0')
C_CODE_BG    = HexColor('#1E293B')
C_CODE_TEXT  = HexColor('#E2E8F0')
C_STEP_BG    = HexColor('#EEF2FF')
C_STEP_NUM   = HexColor('#4F46E5')
C_ORANGE_BG  = HexColor('#FFF7ED')
C_ORANGE_BD  = HexColor('#FB923C')
C_GRAY       = HexColor('#64748B')
C_LIGHT_GRAY = HexColor('#94A3B8')
C_HEADER_BG  = HexColor('#0F172A')

W, H = A4

# ── Styles ────────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

def make_style(name, **kw):
    return ParagraphStyle(name=name, **kw)

ST = {
    'cover_title': make_style('cover_title',
        fontName='Helvetica-Bold', fontSize=32, textColor=C_WHITE,
        leading=38, alignment=TA_CENTER, spaceAfter=8),

    'cover_sub': make_style('cover_sub',
        fontName='Helvetica', fontSize=14, textColor=HexColor('#CBD5E1'),
        leading=20, alignment=TA_CENTER),

    'cover_badge': make_style('cover_badge',
        fontName='Helvetica-Bold', fontSize=11, textColor=C_WHITE,
        alignment=TA_CENTER),

    'h1': make_style('h1',
        fontName='Helvetica-Bold', fontSize=22, textColor=C_PRIMARY,
        leading=28, spaceBefore=20, spaceAfter=10),

    'h2': make_style('h2',
        fontName='Helvetica-Bold', fontSize=15, textColor=C_ACCENT,
        leading=20, spaceBefore=16, spaceAfter=6),

    'h3': make_style('h3',
        fontName='Helvetica-Bold', fontSize=12, textColor=C_PRIMARY,
        leading=16, spaceBefore=10, spaceAfter=4),

    'body': make_style('body',
        fontName='Helvetica', fontSize=10.5, textColor=C_BLACK,
        leading=16, spaceAfter=6, alignment=TA_JUSTIFY),

    'body_center': make_style('body_center',
        fontName='Helvetica', fontSize=10.5, textColor=C_BLACK,
        leading=16, spaceAfter=6, alignment=TA_CENTER),

    'bullet': make_style('bullet',
        fontName='Helvetica', fontSize=10.5, textColor=C_BLACK,
        leading=16, spaceAfter=4, leftIndent=16, bulletIndent=0),

    'code': make_style('code',
        fontName='Courier-Bold', fontSize=9, textColor=C_CODE_TEXT,
        leading=14, spaceAfter=2, leftIndent=8),

    'caption': make_style('caption',
        fontName='Helvetica-Oblique', fontSize=9, textColor=C_GRAY,
        leading=13, alignment=TA_CENTER, spaceAfter=4),

    'warning_text': make_style('warning_text',
        fontName='Helvetica', fontSize=10, textColor=HexColor('#92400E'),
        leading=15),

    'warning_title': make_style('warning_title',
        fontName='Helvetica-Bold', fontSize=11, textColor=HexColor('#92400E'),
        leading=16, spaceAfter=3),

    'success_text': make_style('success_text',
        fontName='Helvetica', fontSize=10, textColor=HexColor('#065F46'),
        leading=15),

    'success_title': make_style('success_title',
        fontName='Helvetica-Bold', fontSize=11, textColor=HexColor('#065F46'),
        leading=16, spaceAfter=3),

    'step_num': make_style('step_num',
        fontName='Helvetica-Bold', fontSize=14, textColor=C_WHITE,
        alignment=TA_CENTER, leading=18),

    'step_title': make_style('step_title',
        fontName='Helvetica-Bold', fontSize=12, textColor=C_PRIMARY,
        leading=16, spaceAfter=2),

    'step_body': make_style('step_body',
        fontName='Helvetica', fontSize=10, textColor=HexColor('#334155'),
        leading=15, spaceAfter=2),

    'label': make_style('label',
        fontName='Helvetica-Bold', fontSize=9, textColor=C_ACCENT,
        leading=12),

    'toc': make_style('toc',
        fontName='Helvetica', fontSize=11, textColor=C_PRIMARY,
        leading=20, leftIndent=12),

    'footer': make_style('footer',
        fontName='Helvetica', fontSize=8, textColor=C_LIGHT_GRAY,
        leading=12, alignment=TA_CENTER),
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def hr(color=C_BORDER, thickness=1, space=8):
    return HRFlowable(width='100%', thickness=thickness,
                      color=color, spaceAfter=space, spaceBefore=space)

def sp(h=6):
    return Spacer(1, h)

def section_header(text):
    """Bandeau de section pleine largeur."""
    data = [[Paragraph(text, make_style('sh',
        fontName='Helvetica-Bold', fontSize=13, textColor=C_WHITE,
        leading=16))]]
    t = Table(data, colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0,0), (-1,-1), C_PRIMARY),
        ('PADDING',     (0,0), (-1,-1), 10),
        ('ROUNDEDCORNERS', [6]),
    ]))
    return [sp(12), t, sp(8)]

def warning_box(title, lines):
    content = [Paragraph(f'⚠️  {title}', ST['warning_title'])]
    for l in lines:
        content.append(Paragraph(l, ST['warning_text']))
    t = Table([[content]], colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0,0), (-1,-1), C_ORANGE_BG),
        ('BOX',         (0,0), (-1,-1), 1.5, C_ORANGE_BD),
        ('PADDING',     (0,0), (-1,-1), 12),
        ('ROUNDEDCORNERS', [8]),
    ]))
    return [sp(6), t, sp(8)]

def success_box(title, lines):
    content = [Paragraph(f'✅  {title}', ST['success_title'])]
    for l in lines:
        content.append(Paragraph(l, ST['success_text']))
    t = Table([[content]], colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0,0), (-1,-1), HexColor('#ECFDF5')),
        ('BOX',         (0,0), (-1,-1), 1.5, C_SUCCESS),
        ('PADDING',     (0,0), (-1,-1), 12),
        ('ROUNDEDCORNERS', [8]),
    ]))
    return [sp(6), t, sp(8)]

def code_block(lines, label=''):
    content = []
    if label:
        content.append(Paragraph(label, make_style('cl',
            fontName='Helvetica-Bold', fontSize=8, textColor=C_ACCENT,
            leading=12, spaceAfter=4)))
    for l in lines:
        content.append(Paragraph(l, ST['code']))
    t = Table([[content]], colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0,0), (-1,-1), C_CODE_BG),
        ('PADDING',     (0,0), (-1,-1), 14),
        ('ROUNDEDCORNERS', [6]),
    ]))
    return [sp(4), t, sp(8)]

def step_row(num, title, body_lines, icon=''):
    num_cell = Paragraph(str(num), ST['step_num'])
    num_tbl = Table([[num_cell]], colWidths=[1.0*cm], rowHeights=[1.0*cm])
    num_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_STEP_NUM),
        ('ROUNDEDCORNERS', [14]),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    content = [Paragraph(f'{icon}  {title}' if icon else title, ST['step_title'])]
    for l in body_lines:
        content.append(Paragraph(l, ST['step_body']))
    main = Table([[num_tbl, content]], colWidths=[1.4*cm, W - 4*cm - 1.4*cm])
    main.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_STEP_BG),
        ('PADDING',    (0,0), (-1,-1), 10),
        ('VALIGN',     (0,0), (-1,-1), 'TOP'),
        ('ROUNDEDCORNERS', [8]),
        ('LEFTPADDING', (1,0), (1,-1), 14),
    ]))
    return [sp(4), main, sp(4)]

def info_table(rows, widths=None):
    w = widths or [5*cm, W - 4*cm - 5*cm]
    data = []
    for k, v in rows:
        data.append([
            Paragraph(k, make_style('ik',
                fontName='Helvetica-Bold', fontSize=9.5, textColor=C_GRAY, leading=14)),
            Paragraph(v, make_style('iv',
                fontName='Helvetica', fontSize=9.5, textColor=C_BLACK, leading=14)),
        ])
    t = Table(data, colWidths=w)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (0,-1), C_LIGHT_BG),
        ('BACKGROUND', (1,0), (1,-1), C_WHITE),
        ('BOX',        (0,0), (-1,-1), 1, C_BORDER),
        ('INNERGRID',  (0,0), (-1,-1), 0.5, C_BORDER),
        ('PADDING',    (0,0), (-1,-1), 8),
        ('VALIGN',     (0,0), (-1,-1), 'TOP'),
    ]))
    return [sp(4), t, sp(8)]

# ── Header / Footer ───────────────────────────────────────────────────────────
def on_page(canvas, doc):
    canvas.saveState()
    # Pied de page
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(C_LIGHT_GRAY)
    date_str = datetime.date.today().strftime('%d/%m/%Y')
    canvas.drawCentredString(W/2, 1.8*cm,
        f'SIGN — Guide de configuration iOS  •  {date_str}  •  Page {doc.page}')
    canvas.setStrokeColor(C_BORDER)
    canvas.setLineWidth(0.5)
    canvas.line(2*cm, 2.2*cm, W - 2*cm, 2.2*cm)
    # En-tête (sauf page 1)
    if doc.page > 1:
        canvas.setFont('Helvetica-Bold', 8)
        canvas.setFillColor(C_GRAY)
        canvas.drawString(2*cm, H - 1.5*cm, 'SIGN  ·  Guide iOS Production')
        canvas.drawRightString(W - 2*cm, H - 1.5*cm, 'Confidentiel')
        canvas.line(2*cm, H - 1.8*cm, W - 2*cm, H - 1.8*cm)
    canvas.restoreState()

# ── Cover Page ────────────────────────────────────────────────────────────────
def cover_page():
    story = []

    # Fond sombre pleine page simulé avec table
    header_data = [[
        Paragraph('📱', make_style('emoji',
            fontName='Helvetica', fontSize=48, textColor=C_WHITE,
            alignment=TA_CENTER)),
    ]]
    header = Table(header_data, colWidths=[W - 4*cm], rowHeights=[3*cm])
    header.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_HEADER_BG),
        ('ALIGN',      (0,0), (-1,-1), 'CENTER'),
        ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING',    (0,0), (-1,-1), 20),
    ]))
    story.append(sp(20))
    story.append(header)
    story.append(sp(14))

    # Titre
    story.append(Paragraph('Guide de Configuration iOS', ST['h1']))
    story.append(Paragraph('Application SIGN — Préparation Production', make_style('sub',
        fontName='Helvetica', fontSize=14, textColor=C_ACCENT, leading=18, spaceAfter=20)))

    story.append(hr(C_ACCENT, 2, 16))

    # Badges
    badges = [
        ('BLK-05', C_DANGER, 'DEVELOPMENT_TEAM — Signing Xcode'),
        ('AS-03',  C_WARNING, 'GoogleService-Info.plist — Firebase iOS'),
    ]
    for code, col, label in badges:
        row = [
            [Paragraph(code, make_style('bc',
                fontName='Helvetica-Bold', fontSize=10, textColor=C_WHITE,
                alignment=TA_CENTER))],
            [Paragraph(label, make_style('bl',
                fontName='Helvetica', fontSize=11, textColor=C_BLACK, leading=16))],
        ]
        t = Table([[
            Table([[Paragraph(code, make_style('bc',
                fontName='Helvetica-Bold', fontSize=10, textColor=C_WHITE,
                alignment=TA_CENTER))]],
                colWidths=[2.5*cm], rowHeights=[0.7*cm]),
            Paragraph(label, make_style('bl',
                fontName='Helvetica', fontSize=11, textColor=C_BLACK, leading=16))
        ]], colWidths=[2.8*cm, W - 4*cm - 2.8*cm])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), col),
            ('BACKGROUND', (1,0), (1,0), C_LIGHT_BG),
            ('BOX',        (0,0), (-1,-1), 1, C_BORDER),
            ('PADDING',    (0,0), (-1,-1), 10),
            ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
            ('ROUNDEDCORNERS', [6]),
        ]))
        story.append(sp(4))
        story.append(t)

    story.append(sp(24))

    # Métadonnées
    meta = [
        ('Application',  'SIGN — Gestion & Signature Électronique'),
        ('Bundle ID',    'com.signapp.sign'),
        ('Plateforme',   'iOS 13.0+'),
        ('Flutter',      '3.35.6 stable'),
        ('Date',         datetime.date.today().strftime('%d %B %Y')),
        ('Confidentiel', 'Usage interne uniquement'),
    ]
    story += info_table(meta)

    story.append(PageBreak())
    return story

# ── Table des matières ────────────────────────────────────────────────────────
def toc_page():
    story = []
    story.append(Paragraph('Table des matières', ST['h1']))
    story.append(hr(C_ACCENT, 2, 10))

    toc_items = [
        ('01', 'Prérequis obligatoires',           '3'),
        ('02', 'BLK-05 — Configurer le Signing Xcode', '4'),
        ('   2.1', 'Créer un compte Apple Developer',   '4'),
        ('   2.2', 'Ouvrir le projet dans Xcode',       '4'),
        ('   2.3', 'Configurer Signing & Capabilities', '5'),
        ('   2.4', 'Vérifier le certificat',            '6'),
        ('   2.5', 'Résolution des erreurs courantes',  '7'),
        ('03', 'AS-03 — Configurer Firebase iOS',   '8'),
        ('   3.1', 'Créer l\'app iOS dans Firebase', '8'),
        ('   3.2', 'Télécharger GoogleService-Info.plist', '9'),
        ('   3.3', 'Ajouter le fichier dans Xcode',    '10'),
        ('   3.4', 'Vérifier l\'intégration Firebase', '11'),
        ('04', 'Build Release iOS',                 '12'),
        ('05', 'Checklist finale avant App Store',  '13'),
    ]

    data = []
    for num, title, page in toc_items:
        bold = not num.startswith(' ')
        font = 'Helvetica-Bold' if bold else 'Helvetica'
        indent = 0 if bold else 16
        data.append([
            Paragraph(f'<font name="{font}">{num}</font>', make_style('tn',
                fontName=font, fontSize=10.5, textColor=C_ACCENT if bold else C_GRAY,
                leading=18, leftIndent=indent)),
            Paragraph(f'<font name="{font}">{title}</font>', make_style('tt',
                fontName=font, fontSize=10.5, textColor=C_PRIMARY if bold else C_BLACK,
                leading=18, leftIndent=indent)),
            Paragraph(page, make_style('tp',
                fontName='Helvetica', fontSize=10.5, textColor=C_GRAY,
                leading=18, alignment=TA_CENTER)),
        ])

    t = Table(data, colWidths=[1.5*cm, W - 4*cm - 2.5*cm, 1*cm])
    t.setStyle(TableStyle([
        ('VALIGN',   (0,0), (-1,-1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [C_WHITE, C_LIGHT_BG]),
        ('PADDING',  (0,0), (-1,-1), 6),
        ('BOX',      (0,0), (-1,-1), 0.5, C_BORDER),
        ('INNERGRID',(0,0), (-1,-1), 0.3, C_BORDER),
    ]))
    story.append(t)
    story.append(PageBreak())
    return story

# ── Section 1 : Prérequis ─────────────────────────────────────────────────────
def section_prerequisites():
    story = []
    story.append(Paragraph('01 — Prérequis obligatoires', ST['h1']))
    story.append(hr(C_ACCENT, 2, 8))
    story.append(Paragraph(
        'Avant de commencer la configuration iOS, assurez-vous d\'avoir tous les éléments '
        'suivants. L\'absence de l\'un d\'eux bloquera le déploiement.',
        ST['body']))
    story.append(sp(8))

    prereqs = [
        ('Matériel', [
            '✅  Un Mac (macOS 13 Ventura minimum recommandé)',
            '✅  iPhone physique pour les tests (recommandé)',
        ]),
        ('Logiciels', [
            '✅  Xcode 15+ installé depuis le Mac App Store',
            '✅  Flutter SDK 3.35.6 configuré',
            '✅  Compte Apple Developer actif (99 $/an)',
            '✅  Compte Firebase avec projet existant',
        ]),
        ('Informations', [
            '✅  Bundle ID : <b>com.signapp.sign</b>',
            '✅  Nom de l\'app : <b>SIGN</b>',
            '✅  Dépôt git cloné sur le Mac',
        ]),
    ]

    for cat, items in prereqs:
        story.append(Paragraph(cat, ST['h3']))
        for item in items:
            story.append(Paragraph(item, ST['bullet']))
        story.append(sp(4))

    story += warning_box(
        'Important — Système requis',
        [
            'La configuration Xcode et la soumission App Store nécessitent <b>impérativement un Mac</b>. '
            'Ces étapes ne peuvent pas être effectuées sous Windows.',
            'Si vous développez sous Windows, transférez le dossier du projet sur un Mac ou utilisez '
            'un service de build cloud (Codemagic, Bitrise).',
        ]
    )

    story.append(PageBreak())
    return story

# ── Section 2 : BLK-05 Signing ────────────────────────────────────────────────
def section_blk05():
    story = []

    # Titre section
    title_data = [[Paragraph(
        '02 — BLK-05 : Configurer le Signing Xcode\n(DEVELOPMENT_TEAM)',
        make_style('st', fontName='Helvetica-Bold', fontSize=16,
                   textColor=C_WHITE, leading=22))]]
    t = Table(title_data, colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_DANGER),
        ('PADDING',    (0,0), (-1,-1), 16),
        ('ROUNDEDCORNERS', [8]),
    ]))
    story.append(t)
    story.append(sp(12))

    story.append(Paragraph(
        'Sans <b>DEVELOPMENT_TEAM</b> configuré, Xcode ne peut pas signer l\'IPA. '
        'Il est impossible de faire un build release ou de soumettre à l\'App Store. '
        'C\'est la correction la plus critique pour le déploiement iOS.',
        ST['body']))

    # 2.1 Compte Apple Developer
    story.append(Paragraph('2.1 — Créer / Vérifier le compte Apple Developer', ST['h2']))
    story.append(Paragraph(
        'Un abonnement Apple Developer Program est requis pour signer et distribuer l\'app.',
        ST['body']))

    story += step_row(1, 'Aller sur developer.apple.com',
        ['Ouvrir https://developer.apple.com/programs/enroll/',
         'Se connecter avec votre Apple ID existant.'], '🌐')
    story += step_row(2, 'S\'inscrire comme individuel ou organisation',
        ['Individual (vous seul) : 99 USD/an — approuvé immédiatement.',
         'Organization : nécessite un numéro DUNS — délai 3-5 jours ouvrés.'], '📝')
    story += step_row(3, 'Confirmer le paiement',
        ['Le compte est actif immédiatement après paiement (individuel).',
         'Vous recevez un email de confirmation avec votre Team ID (10 caractères alphanumériques).'], '💳')

    story += info_table([
        ('URL',       'https://developer.apple.com'),
        ('Prix',      '99 USD/an (renouvellement annuel)'),
        ('Team ID',   'Format : ABC1234567 (10 caractères — visible dans Membership)'),
        ('Délai',     'Individuel : immédiat | Organisation : 3-5 jours ouvrés'),
    ])

    # 2.2 Ouvrir dans Xcode
    story.append(Paragraph('2.2 — Ouvrir le projet dans Xcode', ST['h2']))
    story += warning_box('Toujours ouvrir .xcworkspace, jamais .xcodeproj',
        ['Utilisez <b>ios/Runner.xcworkspace</b> (et non Runner.xcodeproj). '
         'Le fichier .xcworkspace intègre CocoaPods (dépendances Firebase, etc.). '
         'Ouvrir .xcodeproj seul provoque des erreurs de compilation.'])

    story += step_row(1, 'Ouvrir le terminal sur Mac', [
        'Naviguer vers le répertoire du projet :',
        'cd ~/path/to/sign_application',
    ], '💻')

    story += code_block([
        '# Ouvrir directement depuis le terminal :',
        'open ios/Runner.xcworkspace',
        '',
        '# Ou double-cliquer depuis le Finder sur :',
        'ios/Runner.xcworkspace',
    ], 'Terminal Mac')

    story += step_row(2, 'Vérifier que le projet se charge correctement', [
        'Dans le panneau gauche de Xcode, vérifier la structure :',
        '  Runner (projet principal)',
        '  Pods (dépendances CocoaPods)',
        '  RunnerTests (tests)',
    ], '🔍')

    story.append(PageBreak())

    # 2.3 Signing & Capabilities
    story.append(Paragraph('2.3 — Configurer Signing & Capabilities', ST['h2']))
    story.append(Paragraph(
        'C\'est l\'étape centrale. Xcode va automatiquement créer les certificats '
        'et profils de provisioning nécessaires.',
        ST['body']))

    steps_signing = [
        (1, 'Sélectionner la cible Runner',
         ['Dans Xcode, cliquer sur "Runner" dans le panneau gauche (arbre de projet).',
          'Sélectionner la cible "Runner" (icône bleue) dans la liste centrale.'], '🎯'),
        (2, 'Aller dans Signing & Capabilities',
         ['Cliquer sur l\'onglet "Signing & Capabilities" dans la barre principale.'], '⚙️'),
        (3, 'Activer Automatically manage signing',
         ['Cocher la case "Automatically manage signing".',
          'Xcode s\'occupera des certificats et profils automatiquement.'], '✅'),
        (4, 'Sélectionner votre Team',
         ['Cliquer sur le menu déroulant "Team".',
          'Sélectionner votre compte Apple Developer (format: Prénom Nom ou Organisation).',
          'Si votre compte n\'apparaît pas : Xcode → Preferences → Accounts → + → Apple ID.'], '👤'),
        (5, 'Vérifier le Bundle Identifier',
         ['S\'assurer que "Bundle Identifier" affiche : com.signapp.sign',
          '(Déjà configuré dans project.pbxproj par le code de l\'audit)'], '🔑'),
    ]

    for num, title, body, icon in steps_signing:
        story += step_row(num, title, body, icon)

    story += success_box('Configuration automatique', [
        'Après avoir sélectionné votre Team et activé "Automatically manage signing", '
        'Xcode crée automatiquement :',
        '  • Un certificat de développement et de distribution (dans votre trousseau)',
        '  • Un profil de provisioning (lié au Bundle ID)',
        '  • Enregistre le device connecté (pour tests)',
    ])

    story.append(PageBreak())

    # 2.4 Vérifier le certificat
    story.append(Paragraph('2.4 — Vérifier et gérer les certificats', ST['h2']))

    story += step_row(1, 'Ouvrir le Keychain Access (Trousseau d\'accès)',
        ['Sur Mac : Spotlight → "Trousseau d\'accès" (Keychain Access)',
         'Aller dans : Mes certificats',
         'Vérifier la présence de "Apple Distribution: [votre nom]"'], '🔐')

    story += step_row(2, 'Dans Xcode — gérer les certificats',
        ['Xcode → menu Xcode → Settings → Accounts',
         'Sélectionner votre Apple ID',
         'Cliquer "Manage Certificates..."',
         'Cliquer "+" → "Apple Distribution" si absent'], '🏷️')

    story += step_row(3, 'Vérifier dans le portail Apple Developer',
        ['Aller sur https://developer.apple.com/account',
         'Certificates, IDs & Profiles → Certificates',
         'Vérifier qu\'un certificat "Apple Distribution" est actif (vert)'], '🌐')

    story += code_block([
        '# Vérifier les certificats disponibles depuis le terminal :',
        'security find-identity -v -p codesigning',
        '',
        '# Résultat attendu (exemple) :',
        '  1) ABCD1234... "Apple Distribution: Votre Nom (TEAM1234)"',
        '     1 valid identities found',
    ], 'Terminal Mac — Vérification certificat')

    # 2.5 Résolution erreurs
    story.append(Paragraph('2.5 — Résolution des erreurs courantes', ST['h2']))

    errors = [
        (
            '"No accounts with iTunes Connect access"',
            'Votre Apple ID n\'est pas inscrit au Developer Program.',
            'S\'inscrire sur developer.apple.com/programs',
        ),
        (
            '"Failed to create provisioning profile"',
            'Le Bundle ID com.signapp.sign n\'est pas encore enregistré.',
            'Apple Developer → Identifiers → "+" → App ID → com.signapp.sign',
        ),
        (
            '"Certificate has been revoked"',
            'Le certificat existant a été révoqué.',
            'Xcode → Settings → Accounts → Manage Certificates → créer nouveau',
        ),
        (
            '"Xcode couldn\'t find a profile matching"',
            'Le profil de provisioning est manquant ou périmé.',
            'Xcode → Product → Clean Build Folder, puis re-build',
        ),
    ]

    data = [
        [Paragraph('Erreur', make_style('eh', fontName='Helvetica-Bold', fontSize=10,
                   textColor=C_WHITE, leading=14)),
         Paragraph('Cause', make_style('eh', fontName='Helvetica-Bold', fontSize=10,
                   textColor=C_WHITE, leading=14)),
         Paragraph('Solution', make_style('eh', fontName='Helvetica-Bold', fontSize=10,
                   textColor=C_WHITE, leading=14))],
    ]
    for err, cause, sol in errors:
        data.append([
            Paragraph(f'<i>{err}</i>', make_style('ec', fontName='Courier',
                fontSize=8.5, textColor=C_DANGER, leading=13)),
            Paragraph(cause, make_style('ec2', fontName='Helvetica', fontSize=9,
                textColor=C_BLACK, leading=13)),
            Paragraph(sol, make_style('ec3', fontName='Helvetica', fontSize=9,
                textColor=HexColor('#065F46'), leading=13)),
        ])

    t = Table(data, colWidths=[5.5*cm, 4.5*cm, W - 4*cm - 10*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,0), C_PRIMARY),
        ('ROWBACKGROUNDS',(0,1), (-1,-1), [C_WHITE, C_LIGHT_BG]),
        ('BOX',           (0,0), (-1,-1), 1, C_BORDER),
        ('INNERGRID',     (0,0), (-1,-1), 0.5, C_BORDER),
        ('PADDING',       (0,0), (-1,-1), 8),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(sp(4))
    story.append(t)
    story.append(PageBreak())
    return story

# ── Section 3 : AS-03 Firebase ────────────────────────────────────────────────
def section_as03():
    story = []

    title_data = [[Paragraph(
        '03 — AS-03 : Configurer Firebase iOS\n(GoogleService-Info.plist)',
        make_style('st', fontName='Helvetica-Bold', fontSize=16,
                   textColor=C_WHITE, leading=22))]]
    t = Table(title_data, colWidths=[W - 4*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_WARNING),
        ('PADDING',    (0,0), (-1,-1), 16),
        ('ROUNDEDCORNERS', [8]),
    ]))
    story.append(t)
    story.append(sp(12))

    story.append(Paragraph(
        'Sans <b>GoogleService-Info.plist</b>, l\'appel <code>Firebase.initializeApp()</code> '
        'provoque un crash fatal au démarrage de l\'app iOS. Ce fichier contient la '
        'configuration unique de votre projet Firebase pour la plateforme iOS.',
        ST['body']))

    story += warning_box('Crash garanti sans ce fichier',
        ['L\'app iOS crashe immédiatement au lancement (avant même d\'afficher le splash screen) '
         'si GoogleService-Info.plist est absent de ios/Runner/.',
         'Le code a été protégé par un try/catch dans main.dart pour éviter le crash complet, '
         'mais Firebase et Crashlytics ne seront PAS actifs sans ce fichier.'])

    # 3.1 Créer l'app iOS dans Firebase
    story.append(Paragraph('3.1 — Créer l\'app iOS dans le projet Firebase', ST['h2']))
    story.append(Paragraph(
        'Si votre projet Firebase existe déjà (pour Android), vous devez y ajouter '
        'une application iOS avec le bon Bundle ID.',
        ST['body']))

    story += step_row(1, 'Ouvrir la Firebase Console',
        ['Aller sur https://console.firebase.google.com',
         'Cliquer sur votre projet existant "sign-app" (ou similaire).'], '🌐')

    story += step_row(2, 'Ajouter une application iOS',
        ['Dans la vue d\'ensemble du projet, cliquer "+ Add app".',
         'Sélectionner l\'icône iOS (pomme).'], '➕')

    story += step_row(3, 'Renseigner le Bundle ID iOS',
        ['iOS bundle ID : com.signapp.sign  (EXACTEMENT — respecter la casse)',
         'App nickname : SIGN iOS  (facultatif, pour vous repérer)',
         'App Store ID : laisser vide pour l\'instant',
         'Cliquer "Register app".'], '📝')

    story += info_table([
        ('Bundle ID iOS',  'com.signapp.sign  ← OBLIGATOIRE, exact'),
        ('Bundle ID Android', 'com.signapp.sign_application  ← différent'),
        ('Nickname',       'SIGN iOS  (optionnel)'),
        ('App Store ID',   'Laisser vide (remplir après publication)'),
    ])

    story.append(PageBreak())

    # 3.2 Télécharger le fichier
    story.append(Paragraph('3.2 — Télécharger GoogleService-Info.plist', ST['h2']))

    story += step_row(1, 'Télécharger le fichier de configuration',
        ['Après "Register app", Firebase affiche automatiquement le bouton de téléchargement.',
         'Cliquer "Download GoogleService-Info.plist".',
         'Le fichier se télécharge dans votre dossier Téléchargements.'], '⬇️')

    story += step_row(2, 'Vérifier le contenu du fichier',
        ['Ouvrir le fichier téléchargé (double-clic → TextEdit ou éditeur).',
         'Vérifier que BUNDLE_ID = com.signapp.sign'], '🔍')

    story += code_block([
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<!DOCTYPE plist ...>',
        '<plist version="1.0">',
        '<dict>',
        '  <key>CLIENT_ID</key>',
        '  <string>12345-abcdef.apps.googleusercontent.com</string>',
        '  <key>BUNDLE_ID</key>',
        '  <string>com.signapp.sign</string>   ← Vérifier cette ligne',
        '  <key>PROJECT_ID</key>',
        '  <string>sign-app-xxxxx</string>',
        '  ...',
        '</dict>',
        '</plist>',
    ], 'Contenu attendu de GoogleService-Info.plist')

    story += warning_box('Vérification critique',
        ['Le champ <b>BUNDLE_ID</b> dans le fichier doit être <b>exactement</b> '
         '"com.signapp.sign" — identique au Bundle ID configuré dans Xcode.',
         'Une divergence empêche Firebase de s\'initialiser correctement.'])

    # 3.3 Ajouter dans Xcode
    story.append(Paragraph('3.3 — Ajouter le fichier dans Xcode', ST['h2']))
    story.append(Paragraph(
        'Cette étape est cruciale : le fichier doit être ajouté via Xcode (pas juste copié '
        'dans le dossier) pour être inclus dans le bundle de l\'app lors de la compilation.',
        ST['body']))

    story += step_row(1, 'Ouvrir ios/Runner.xcworkspace dans Xcode',
        ['Si Xcode n\'est pas ouvert : open ios/Runner.xcworkspace'], '💻')

    story += step_row(2, 'Localiser le dossier Runner dans l\'arbre Xcode',
        ['Dans le panneau gauche de Xcode (Navigator), repérer le groupe "Runner".',
         'C\'est le dossier bleu principal (pas le projet racine, pas les Pods).'], '📂')

    story += step_row(3, 'Ajouter le fichier via clic droit',
        ['Clic droit sur le groupe "Runner" → "Add Files to Runner..."',
         'Dans le sélecteur de fichier, naviguer vers votre dossier Téléchargements.',
         'Sélectionner GoogleService-Info.plist.',
         'OPTIONS IMPORTANTES à vérifier :',
         '  ☑  Copy items if needed  (OBLIGATOIRE)',
         '  ☑  Add to targets: Runner  (OBLIGATOIRE)',
         'Cliquer "Add".'], '➕')

    story += step_row(4, 'Vérifier que le fichier est visible dans Xcode',
        ['Dans l\'arbre du projet, GoogleService-Info.plist doit apparaître',
         'sous le groupe Runner (avec une icône de fichier plist blanche).'], '✅')

    story += warning_box('Ne pas utiliser le Finder seul',
        ['Copier le fichier dans ios/Runner/ via le Finder sans passer par Xcode '
         'ne suffit pas : Xcode ne saura pas l\'inclure dans le bundle de compilation. '
         'Utilisez TOUJOURS "Add Files to Runner..." depuis Xcode.'])

    story.append(PageBreak())

    # 3.4 Vérifier l'intégration
    story.append(Paragraph('3.4 — Vérifier l\'intégration Firebase iOS', ST['h2']))

    story += step_row(1, 'Builder le projet en mode Debug',
        ['Dans Xcode : Product → Run (⌘R)',
         'Ou depuis Flutter : flutter run --debug',
         'L\'app doit démarrer sans crash.'], '▶️')

    story += code_block([
        '# Depuis le terminal Mac (projet sign_application) :',
        'flutter run --debug',
        '',
        '# Résultat attendu dans les logs :',
        'I/flutter (XXXX): Firebase initialisé avec succès',
        '# Ou absence du message d\'erreur Firebase',
        '',
        '# Si Firebase n\'est PAS configuré (mode fallback actif) :',
        '⚠️ Firebase non initialisé : [NSBundle mainBundle]...',
        '# → Le fichier est absent ou mal ajouté dans Xcode',
    ], 'Commande Flutter — Test Debug')

    story += step_row(2, 'Vérifier dans la Firebase Console',
        ['Aller sur console.firebase.google.com → votre projet.',
         'Project Overview → cliquer sur l\'app iOS.',
         'Si un device iOS s\'est connecté → section "Latest activity" mise à jour.'], '📊')

    story += step_row(3, 'Vérifier Crashlytics',
        ['Firebase Console → Crashlytics → sélectionner l\'app iOS.',
         'Forcer un crash de test (optionnel) :'], '🔥')

    story += code_block([
        '// Dans main.dart (temporaire — retirer après test) :',
        'FirebaseCrashlytics.instance.crash();',
        '',
        '// Résultat attendu : crash visible dans Firebase Console',
        '// sous Crashlytics → app iOS → dans les 5 minutes.',
    ], 'Test Crashlytics iOS')

    story += success_box('Intégration Firebase iOS réussie', [
        'Quand tout est correctement configuré :',
        '  • L\'app démarre sans crash sur iOS',
        '  • firebase_core est initialisé',
        '  • Crashlytics collecte les erreurs en production',
        '  • Firebase Analytics enregistre les sessions',
    ])

    story.append(PageBreak())
    return story

# ── Section 4 : Build Release ─────────────────────────────────────────────────
def section_build():
    story = []
    story.append(Paragraph('04 — Build Release iOS (Archive + Upload)', ST['h1']))
    story.append(hr(C_ACCENT, 2, 8))
    story.append(Paragraph(
        'Une fois BLK-05 et AS-03 résolus, voici la procédure complète pour '
        'créer un build release et le soumettre à l\'App Store.',
        ST['body']))

    story += step_row(1, 'Build depuis Flutter',
        ['Depuis le terminal Mac, à la racine du projet :'], '💻')

    story += code_block([
        '# Build IPA release :',
        'flutter build ipa --release \\',
        '  --dart-define=API_BASE_URL=https://sign-backend-ha5a.onrender.com/sign',
        '',
        '# Si succès :',
        'Built build/ios/archive/Runner.xcarchive',
        'Built build/ios/ipa/sign_application.ipa',
    ], 'Terminal Mac — flutter build ipa')

    story += step_row(2, 'Ouvrir l\'archive dans Xcode Organizer',
        ['Depuis Xcode : Window → Organizer',
         'Sélectionner l\'archive la plus récente.',
         'Cliquer "Distribute App".'], '📦')

    story += step_row(3, 'Upload vers App Store Connect',
        ['Sélectionner "App Store Connect".',
         'Cliquer "Next" → "Upload".',
         'Attendre la fin de l\'upload (~2-5 minutes).'], '⬆️')

    story += step_row(4, 'Valider sur App Store Connect',
        ['Aller sur https://appstoreconnect.apple.com',
         'Sélectionner votre app SIGN.',
         'Dans "TestFlight" ou "iOS App", vérifier que le build est visible.'], '✅')

    story.append(PageBreak())
    return story

# ── Section 5 : Checklist ─────────────────────────────────────────────────────
def section_checklist():
    story = []
    story.append(Paragraph('05 — Checklist finale avant App Store', ST['h1']))
    story.append(hr(C_ACCENT, 2, 8))

    items_blk05 = [
        ('✅', 'Compte Apple Developer actif (99$/an)', 'BLK-05'),
        ('✅', 'Xcode ouvert sur ios/Runner.xcworkspace', 'BLK-05'),
        ('✅', 'Automatically manage signing activé', 'BLK-05'),
        ('✅', 'Team sélectionné dans Signing & Capabilities', 'BLK-05'),
        ('✅', 'Bundle ID = com.signapp.sign', 'BLK-05'),
        ('✅', 'Certificat "Apple Distribution" dans le trousseau', 'BLK-05'),
    ]

    items_as03 = [
        ('✅', 'App iOS créée dans Firebase Console (com.signapp.sign)', 'AS-03'),
        ('✅', 'GoogleService-Info.plist téléchargé', 'AS-03'),
        ('✅', 'Fichier ajouté via "Add Files to Runner..." dans Xcode', 'AS-03'),
        ('✅', '"Copy items if needed" coché', 'AS-03'),
        ('✅', '"Add to targets: Runner" coché', 'AS-03'),
        ('✅', 'Build Debug sans crash Firebase', 'AS-03'),
    ]

    items_final = [
        ('✅', 'flutter build ipa --release réussi', 'BUILD'),
        ('✅', 'CFBundleName = "SIGN" (corrigé dans l\'audit)', 'AS-04'),
        ('✅', 'NSPhotoLibraryUsageDescription présent (corrigé)', 'BLK-03'),
        ('✅', 'Portrait uniquement configuré (corrigé)', 'AS-05'),
        ('✅', 'UIUserInterfaceStyle = Light (corrigé)', 'AS-06'),
        ('✅', 'Tests sur device physique iPhone', 'QA'),
        ('✅', 'TestFlight distribué à l\'équipe', 'QA'),
        ('✅', 'Politique de confidentialité hébergée publiquement', 'APP STORE'),
        ('✅', 'Screenshots App Store (6.5" + 12.9" iPad)', 'APP STORE'),
        ('✅', 'Description app en français (≤4000 car)', 'APP STORE'),
    ]

    for title, items in [
        ('Configuration Signing (BLK-05)', items_blk05),
        ('Configuration Firebase iOS (AS-03)', items_as03),
        ('Déploiement final', items_final),
    ]:
        story.append(Paragraph(title, ST['h3']))
        data = []
        for check, label, ref in items:
            ref_col = HexColor('#EEF2FF') if 'BLK' in ref else \
                      HexColor('#FFF7ED') if 'AS' in ref else \
                      HexColor('#F0FDF4')
            data.append([
                Paragraph(check, make_style('chk',
                    fontName='Helvetica', fontSize=12, textColor=C_SUCCESS,
                    alignment=TA_CENTER, leading=16)),
                Paragraph(label, make_style('lbl',
                    fontName='Helvetica', fontSize=10, textColor=C_BLACK, leading=15)),
                Paragraph(ref, make_style('ref',
                    fontName='Helvetica-Bold', fontSize=8.5, textColor=C_ACCENT,
                    alignment=TA_CENTER, leading=13)),
            ])
        t = Table(data, colWidths=[0.8*cm, W - 4*cm - 2.5*cm, 1.7*cm])
        t.setStyle(TableStyle([
            ('ROWBACKGROUNDS', (0,0), (-1,-1), [C_WHITE, C_LIGHT_BG]),
            ('BOX',           (0,0), (-1,-1), 0.5, C_BORDER),
            ('INNERGRID',     (0,0), (-1,-1), 0.3, C_BORDER),
            ('PADDING',       (0,0), (-1,-1), 7),
            ('VALIGN',        (0,0), (-1,-1), 'MIDDLE'),
        ]))
        story.append(sp(4))
        story.append(t)
        story.append(sp(10))

    # Score final
    score_data = [[
        Paragraph('Score App Store\naprès ces 2 corrections', make_style('sc',
            fontName='Helvetica-Bold', fontSize=13, textColor=C_WHITE,
            alignment=TA_CENTER, leading=18)),
        Paragraph('93 / 100', make_style('sn',
            fontName='Helvetica-Bold', fontSize=36, textColor=C_SUCCESS,
            alignment=TA_CENTER, leading=42)),
        Paragraph('Score Play Store\ndéjà atteint', make_style('sc',
            fontName='Helvetica-Bold', fontSize=13, textColor=C_WHITE,
            alignment=TA_CENTER, leading=18)),
        Paragraph('88 / 100', make_style('sn2',
            fontName='Helvetica-Bold', fontSize=36, textColor=HexColor('#60A5FA'),
            alignment=TA_CENTER, leading=42)),
    ]]
    t = Table(score_data, colWidths=[5*cm, 3.5*cm, 5*cm, 3.5*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_HEADER_BG),
        ('PADDING',    (0,0), (-1,-1), 16),
        ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
        ('ROUNDEDCORNERS', [10]),
    ]))
    story.append(sp(16))
    story.append(t)

    return story

# ── Assemblage final ──────────────────────────────────────────────────────────
def build_pdf():
    output_path = 'docs/GUIDE_IOS_CONFIGURATION.pdf'

    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=2*cm,
        rightMargin=2*cm,
        topMargin=2.5*cm,
        bottomMargin=2.8*cm,
        title='Guide iOS — BLK-05 + AS-03 — SIGN Application',
        author='SIGN Team',
        subject='Configuration iOS Production',
    )

    story = []
    story += cover_page()
    story += toc_page()
    story += section_prerequisites()
    story += section_blk05()
    story += section_as03()
    story += section_build()
    story += section_checklist()

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    print(f'[OK] PDF genere : {output_path}')
    return output_path

if __name__ == '__main__':
    build_pdf()

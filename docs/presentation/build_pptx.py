#!/usr/bin/env python3
"""Generate LSA Evaluate overview PPTX for Google Slides import."""

from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt

OUTPUT = Path(__file__).resolve().parent / 'LSA_Evaluate_Overview.pptx'

# Maize & Blue–inspired palette (simple solids that import cleanly)
NAVY = RGBColor(0x00, 0x2B, 0x5C)
MAIZE = RGBColor(0xFF, 0xCB, 0x05)
DARK = RGBColor(0x1A, 0x1A, 0x1A)
GRAY = RGBColor(0x4A, 0x4A, 0x4A)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
LIGHT_BLUE = RGBColor(0xE8, 0xF0, 0xF8)


def set_run(run, text, size=20, bold=False, color=DARK, font_name='Calibri'):
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    run.font.name = font_name


def add_notes(slide, text):
    notes = slide.notes_slide.notes_text_frame
    notes.clear()
    notes.text = text.strip()


def style_title(shape, size=32, color=NAVY):
    for p in shape.text_frame.paragraphs:
        for run in p.runs:
            run.font.size = Pt(size)
            run.font.bold = True
            run.font.color.rgb = color
            run.font.name = 'Calibri'


def add_bullets(tf, items, size=20, color=DARK, level_sizes=None):
    """items: list of str or (level, str)."""
    tf.clear()
    first = True
    for item in items:
        if isinstance(item, tuple):
            level, text = item
        else:
            level, text = 0, item
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.level = level
        p.space_after = Pt(8)
        font_size = size
        if level_sizes and level in level_sizes:
            font_size = level_sizes[level]
        elif level > 0:
            font_size = max(14, size - 2)
        run = p.add_run()
        set_run(run, text, size=font_size, color=color)


def blank_slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])  # blank


def add_title_box(slide, text, left=0.5, top=0.35, width=9.0, height=1.0, size=32):
    box = slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    run = p.add_run()
    set_run(run, text, size=size, bold=True, color=NAVY)
    return box


def add_body_box(slide, left=0.5, top=1.5, width=9.0, height=5.0):
    box = slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    box.text_frame.word_wrap = True
    return box


def add_accent_bar(slide):
    shape = slide.shapes.add_shape(
        1,  # rectangle
        Inches(0), Inches(0), Inches(0.15), Inches(7.5)
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = MAIZE
    shape.line.fill.background()


def add_footer(slide, page, total=15):
    box = slide.shapes.add_textbox(Inches(0.5), Inches(7.05), Inches(9.0), Inches(0.35))
    tf = box.text_frame
    p = tf.paragraphs[0]
    run = p.add_run()
    set_run(run, f'LSA Evaluate  ·  {page}/{total}', size=11, color=GRAY)
    p2_run = None
    # right-aligned page feel via second box
    right = slide.shapes.add_textbox(Inches(7.5), Inches(7.05), Inches(2.0), Inches(0.35))
    rp = right.text_frame.paragraphs[0]
    rp.alignment = PP_ALIGN.RIGHT
    rr = rp.add_run()
    set_run(rr, 'University of Michigan · LSA', size=11, color=GRAY)


def content_slide(prs, title, bullets, notes, page):
    slide = blank_slide(prs)
    add_accent_bar(slide)
    add_title_box(slide, title)
    body = add_body_box(slide)
    add_bullets(body.text_frame, bullets)
    add_footer(slide, page)
    add_notes(slide, notes)
    return slide


def title_slide(prs):
    slide = blank_slide(prs)
    # full-bleed navy band
    band = slide.shapes.add_shape(1, Inches(0), Inches(0), Inches(10), Inches(7.5))
    band.fill.solid()
    band.fill.fore_color.rgb = NAVY
    band.line.fill.background()

    maize = slide.shapes.add_shape(1, Inches(0), Inches(5.9), Inches(10), Inches(0.18))
    maize.fill.solid()
    maize.fill.fore_color.rgb = MAIZE
    maize.line.fill.background()

    title = slide.shapes.add_textbox(Inches(0.7), Inches(2.2), Inches(8.5), Inches(1.2))
    p = title.text_frame.paragraphs[0]
    run = p.add_run()
    set_run(run, 'LSA Evaluate', size=48, bold=True, color=WHITE)

    sub = slide.shapes.add_textbox(Inches(0.7), Inches(3.4), Inches(8.5), Inches(1.0))
    sp = sub.text_frame.paragraphs[0]
    sr = sp.add_run()
    set_run(sr, 'Submission and evaluation for contests and awards', size=22, color=MAIZE)

    meta = slide.shapes.add_textbox(Inches(0.7), Inches(6.3), Inches(8.5), Inches(0.8))
    mp = meta.text_frame.paragraphs[0]
    mr = mp.add_run()
    set_run(mr, 'University of Michigan  ·  LSA Technology Services\n30-minute overview for mixed audiences', size=14, color=WHITE)

    add_notes(
        slide,
        '''TIMING: 0:30

Welcome everyone. Introduce yourself and the session.
One sentence: LSA Evaluate is the shared platform that runs a contest season end to end —
from opening a call for work, to collecting submissions, to judging, to awards.

Promise: by the end, everyone in the room — technical or not — will be able to explain
what it does and how the pieces fit together.

Mention: we will leave time for a short live demo and questions.'''
    )
    return slide


def hierarchy_slide(prs, page):
    """Labeled nested boxes instead of SmartArt."""
    slide = blank_slide(prs)
    add_accent_bar(slide)
    add_title_box(slide, 'How a program is organized')

    levels = [
        ('Container', 'The program home — e.g. Hopwood Awards', LIGHT_BLUE, 1.4),
        ('Contest description', 'The contest type — e.g. Undergraduate Fiction', RGBColor(0xD0, 0xE4, 0xF5), 2.35),
        ('Contest instance', "This year's open window — dates, rules, categories", RGBColor(0xB8, 0xD4, 0xEC), 3.3),
        ('Entries → Judging rounds → Awards', 'Submissions, review stages, and prizes', RGBColor(0x9F, 0xC4, 0xE3), 4.25),
    ]

    for label, desc, fill, top in levels:
        shape = slide.shapes.add_shape(1, Inches(0.6), Inches(top), Inches(8.8), Inches(0.85))
        shape.fill.solid()
        shape.fill.fore_color.rgb = fill
        shape.line.color.rgb = NAVY
        tf = shape.text_frame
        tf.word_wrap = True
        tf.paragraphs[0].alignment = PP_ALIGN.LEFT
        r1 = tf.paragraphs[0].add_run()
        set_run(r1, label, size=18, bold=True, color=NAVY)
        p2 = tf.add_paragraph()
        r2 = p2.add_run()
        set_run(r2, desc, size=14, color=DARK)

    tip = slide.shapes.add_textbox(Inches(0.6), Inches(5.3), Inches(8.8), Inches(1.2))
    add_bullets(
        tip.text_frame,
        [
            'Analogy: filing cabinet → drawer → this year’s folder → papers, committees, prize ribbons',
            'Staff work mostly at the container and instance level; applicants and judges meet the instance',
        ],
        size=16,
    )
    add_footer(slide, page)
    add_notes(
        slide,
        '''TIMING: 3:00 — most important conceptual slide

Spend time here. This hierarchy is the mental model for everything else.

1. Container = the program office’s home in the system (Hopwood, MFA, a future unit).
2. Contest description = the named contest that repeats year after year.
3. Contest instance = this season’s offering: open/close dates, eligibility, categories, entry limits.
4. Inside an instance: entries (submissions), judging rounds (stages of review), awards (prizes).

Analogy (use once, then stick to it): cabinet → drawer → this year’s folder → papers / review committees / ribbons.

If someone only remembers one thing from this talk, it should be this nesting.'''
    )
    return slide


def season_slide(prs, page):
    slide = blank_slide(prs)
    add_accent_bar(slide)
    add_title_box(slide, 'Life of a contest season')

    steps = [
        'Prepare',
        'Open',
        'Close',
        'Judge',
        'Advance',
        'Award',
        'Notify',
    ]
    left = 0.45
    width = 1.2
    gap = 0.12
    for i, label in enumerate(steps):
        x = left + i * (width + gap)
        shape = slide.shapes.add_shape(1, Inches(x), Inches(1.8), Inches(width), Inches(1.1))
        shape.fill.solid()
        shape.fill.fore_color.rgb = NAVY if i % 2 == 0 else RGBColor(0x00, 0x3D, 0x7A)
        shape.line.fill.background()
        tf = shape.text_frame
        tf.paragraphs[0].alignment = PP_ALIGN.CENTER
        r = tf.paragraphs[0].add_run()
        set_run(r, label, size=14, bold=True, color=WHITE)
        if i < len(steps) - 1:
            arrow = slide.shapes.add_textbox(Inches(x + width - 0.05), Inches(2.1), Inches(0.25), Inches(0.4))
            ap = arrow.text_frame.paragraphs[0]
            ar = ap.add_run()
            set_run(ar, '→', size=16, bold=True, color=MAIZE)

    body = add_body_box(slide, top=3.3, height=3.5)
    add_bullets(
        body.text_frame,
        [
            'Prepare: questions, categories, awards, eligibility, judge pool',
            'Open / Close: applicants submit within the window (public or invite-only)',
            'Judge: one or more rounds; rank, comment, finalize',
            'Advance: staff select entries for the next round',
            'Award & Notify: attach prizes, send notices, export for disbursement',
            'Everything in today’s talk hangs off this timeline',
        ],
        size=18,
    )
    add_footer(slide, page)
    add_notes(
        slide,
        '''TIMING: 2:00

Walk left to right slowly. This is the “season” story.
Do not dig into screens yet — the live demo will show the clicks.
Emphasize that the platform supports the whole arc, not just intake or not just judging.'''
    )
    return slide


def demo_slide(prs, page):
    slide = blank_slide(prs)
    add_accent_bar(slide)
    add_title_box(slide, 'Live demo')

    body = add_body_box(slide, top=1.4)
    add_bullets(
        body.text_frame,
        [
            'What you will see (~7 minutes)',
            (1, 'Applicant path — profile and a submission'),
            (1, 'Program home — container overview'),
            (1, 'This year’s contest — instance setup highlights'),
            (1, 'Judging — rank entries in a round'),
            (1, 'Awards — attach a prize and note exports'),
            '',
            'Follow along conceptually: login → submit → manage → judge → award',
            'Detailed click path: see DEMO_SCRIPT.md in the presentation folder',
        ],
        size=18,
    )
    add_footer(slide, page)
    add_notes(
        slide,
        '''TIMING: switch to browser for ~7 minutes

Leave this slide up (or go full-screen on the app).
Use docs/presentation/DEMO_SCRIPT.md as your click path.
If a step fails (login, missing data), narrate with the fallback notes in the script —
do not debug live for more than 30 seconds.

After the demo, return to the next slide (What this unlocks for LSA).'''
    )
    return slide


def build():
    prs = Presentation()
    prs.slide_width = Inches(10)
    prs.slide_height = Inches(7.5)

    title_slide(prs)

    content_slide(
        prs,
        'Goals for today',
        [
            'By the end of this session you will be able to explain:',
            (1, 'What problem LSA Evaluate solves'),
            (1, 'Who it serves — applicants, staff, and judges'),
            (1, 'How a contest season is organized in the system'),
            (1, 'How work moves from submission → review → award'),
            '',
            'Audience note: plain language first; light technical detail near the end',
        ],
        '''TIMING: 1:00

Set expectations. Mixed room — we will not assume Rails knowledge.
Ask people to hold detailed “how do I configure X” questions for the end or office hours.
Point to the live demo as the proof of the story.''',
        2,
    )

    content_slide(
        prs,
        'The problem before',
        [
            'Contests often ran on email, forms, and spreadsheets',
            'Eligibility, deadlines, and judge assignments lived in people’s heads',
            'Hard to see at a glance:',
            (1, 'What is open right now?'),
            (1, 'What has been submitted?'),
            (1, 'What has been reviewed?'),
            (1, 'Who won — and what was awarded?'),
            'Hard for LSA Technology Services to support many units the same way',
            '',
            'Analogy: every office inventing its own filing system for the same kind of work',
        ],
        '''TIMING: 2:00

Paint the “before” picture without blaming anyone — this is normal for growing programs.
Hopwood and MFA needed a supported, shared approach.
The pain is operational (visibility, consistency, supportability), not just “we needed a website.”''',
        3,
    )

    content_slide(
        prs,
        'What LSA Evaluate is',
        [
            'A shared web application for contest seasons',
            'Applicants create a profile and submit work electronically',
            'Program staff open contests, set rules, and manage the season',
            'Judges review and rank entries across one or more rounds',
            'Staff assign awards and notify people',
            '',
            'Built first for Hopwood and MFA',
            'Designed so other LSA units can run similar workflows on the same platform',
        ],
        '''TIMING: 2:00

One sentence definition: contest season manager — open call → collect work → judge → award.
Emphasize “shared” and “enterprise for LSA,” not a one-off Hopwood site.
U-M community for applicants; staff can involve non-U-M judges when needed.''',
        4,
    )

    content_slide(
        prs,
        'Who uses it',
        [
            'Applicant — U-M student submitting work (U-M login)',
            'Collection Administrator / Manager — program staff who own the contest “home”',
            'Judge — internal or external reviewers assigned to contests and rounds',
            'Axis mundi — platform administrators (LSA Technology Services)',
            '',
            'Login uses University of Michigan SAML (single sign-on)',
            'Roles are assigned per program (container) so units control their own space',
        ],
        '''TIMING: 2:00

Keep faces, not job codes. “Axis mundi” is our platform-admin role name — smile and move on.
Key point: applicants are U-M; judges can be invited from outside when the program needs them.
Permissions are scoped to a container so Hopwood staff do not administer another unit’s contests by accident.''',
        5,
    )

    hierarchy_slide(prs, 6)
    season_slide(prs, 7)

    content_slide(
        prs,
        'For applicants',
        [
            'Sign in with U-M credentials',
            'Complete a profile (identity, class level, campus/school as needed)',
            'Browse open contests they are eligible for',
            'Submit a title, upload a file, and answer application questions',
            'See status cues so they know where their submission stands',
            '',
            'Private contests can use an invite link or invite list instead of a public listing',
        ],
        '''TIMING: 2:00

Applicant journey is intentionally simple: login → profile → eligible contests → submit → status.
Mention application questions as flexible fields programs can require.
Invite / capability URL covers MFA or other closed processes without making everything public.''',
        8,
    )

    content_slide(
        prs,
        'For program staff',
        [
            'Inside a container (program home), staff can manage:',
            (1, 'Contest descriptions and yearly instances'),
            (1, 'Categories (genres / tracks)'),
            (1, 'Eligibility — class levels, dates, entry limits'),
            (1, 'Application questions — shared or contest-specific'),
            (1, 'Access — open link vs invite-only'),
            (1, 'Bulk tools for opening seasons and judging windows'),
            'Assign colleagues with Collection Administrator or Manager roles',
            'Contact email and visibility settings keep the program discoverable and supportable',
        ],
        '''TIMING: 2:00

This is the “operations cockpit.” Staff spend most of their time here before and during a season.
Bulk tools matter for Hopwood-scale: many contests opening on similar calendars.
Do not list every screen — demo will show the container and an instance.''',
        9,
    )

    content_slide(
        prs,
        'For judges',
        [
            'Assigned to a contest and to specific judging rounds',
            'Review entries and rank them',
            'Add comments (programs can set minimum word counts)',
            'Finalize rankings when their review is complete',
            'Staff select which entries advance to the next round',
            '',
            'Email tools for instructions and “your round is done” notices',
            'Judge dashboard keeps assigned work in one place',
        ],
        '''TIMING: 2:00

Judging is round-based so programs can do screening then final panels, etc.
Ranking + comments + finalize is the judge’s job; advancing is a staff decision.
External judges get access without needing to be Collection Admins.''',
        10,
    )

    content_slide(
        prs,
        'Awards and reporting',
        [
            'Define primary and add-on prizes in the container',
            'Mark winners / finalists and attach awards (amounts, shortcodes)',
            'Send award notices to recipients',
            'Export what finance and program offices need:',
            (1, 'Entries and round results'),
            (1, 'Awards roster'),
            (1, 'Disbursement lists'),
            'Container-level reports — e.g. active applicants, winners overview',
        ],
        '''TIMING: 1:30

Close the season story: decisions become recorded awards and exportable data.
Primary vs add-on prizes covers main awards plus extras without a spreadsheet side channel.
Exports are the bridge to existing university processes (disbursement, archives).''',
        11,
    )

    demo_slide(prs, 12)

    content_slide(
        prs,
        'What this unlocks for LSA',
        [
            'One supported platform instead of many one-off processes',
            'Clear ownership per unit — containers and staff assignments',
            'Repeatable yearly seasons without rebuilding the process each time',
            'Room for more units beyond Hopwood and MFA',
            'LSA Technology Services can enterprise and maintain the application for broader use',
        ],
        '''TIMING: 1:30

Return from demo to the “why this matters for LSA” message.
This is the leadership slide: supportability, reuse, ownership, growth.''',
        13,
    )

    content_slide(
        prs,
        'Light technical snapshot',
        [
            'Modern web application (Ruby on Rails) with University of Michigan login',
            'MySQL database; file uploads for entry manuscripts',
            'Background jobs for email and notifications',
            'Roles and permissions scoped by program (container)',
            'Built to be reused across units — not a single-contest tool',
            '',
            'Non-technical takeaway: secure, supported, and ready for LSA-wide use',
        ],
        '''TIMING: 1:00 — optional depth

Skip or skim if the room is mostly non-technical.
For tech peers: Rails 8, Solid Queue/Cache/Cable, SendGrid mail, SAML OmniAuth.
Keep it to one minute; invite deeper conversation afterward.''',
        14,
    )

    content_slide(
        prs,
        'Takeaways and questions',
        [
            'LSA Evaluate runs the full contest season in one place',
            'Structure: program → contest → this year → entries → rounds → awards',
            'Applicants, staff, and judges each have a clear path',
            'Designed for Hopwood and MFA first — reusable across LSA',
            '',
            'Questions?',
            'Happy to walk through a specific screen or workflow after',
        ],
        '''TIMING: remainder of the 30 minutes

Restate the four takeaways slowly.
Open the floor. Offer a focused follow-up for Hopwood/MFA operators if useful.
Thank LSA Technology Services and the program partners who shaped the workflows.''',
        15,
    )

    prs.save(OUTPUT)
    print(f'Wrote {OUTPUT}')


if __name__ == '__main__':
    build()

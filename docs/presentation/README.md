# LSA Evaluate presentation materials

30-minute overview for mixed (technical and non-technical) audiences, with a ~7-minute live demo.

## Files

| File | Purpose |
|------|---------|
| [LSA_Evaluate_Overview.pptx](LSA_Evaluate_Overview.pptx) | Slide deck with speaker notes (Google Slides–ready) |
| [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | Timed click path for the live demo |
| [build_pptx.py](build_pptx.py) | Regenerates the PPTX if you need to edit content in code |

## Open as Google Slides

Native Google Slides API creation is not used here. Upload the PowerPoint and open it in Google Slides:

1. Go to [Google Drive](https://drive.google.com) and sign in with your U-M or preferred Google account.
2. Upload `LSA_Evaluate_Overview.pptx` (New → File upload, or drag and drop).
3. Right-click the uploaded file → **Open with** → **Google Slides**.
4. Google creates an editable Slides copy. Prefer working from that copy going forward.
5. Spot-check:
   - All 15 slides
   - **View** → **Show speaker notes** (notes include timing cues)
   - Hierarchy boxes (slide 6) and season timeline (slide 7)
6. Optional: apply U-M fonts/colors under **Slide** → **Edit theme**, or replace the title slide with a branded template while keeping the text.

### Alternative: import into an existing deck

1. Create or open a blank Google Slides presentation.
2. **File** → **Import slides**.
3. Upload the PPTX and select all slides → **Import slides**.

### Tips for a clean import

- The deck uses simple title/body layouts and shapes (no SmartArt) so Google Slides preserves content reliably.
- After import, if a bullet looks tight on a laptop projector, widen margins slightly or reduce font one step on that slide only.
- Keep `DEMO_SCRIPT.md` open on a second device during the talk; do not put the full click path on the slides.

## Regenerate the PPTX

If you change copy in `build_pptx.py`:

```bash
python3 -m pip install --user python-pptx
python3 docs/presentation/build_pptx.py
```

Then re-upload or re-import into Google Slides.

## Suggested timing (30 minutes)

| Block | Minutes |
|-------|--------:|
| Slides 1–11 (talk) | ~20 |
| Live demo (slide 12 + app) | ~7 |
| Slides 13–15 + Q&A | ~3+ |

Speaker notes on each slide include a timing cue.

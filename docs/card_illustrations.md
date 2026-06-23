# Card Illustrations — Gemini prompt sheet

Per-card watercolor + line-art illustrations for every tip in `tips.json`.

## How it works (app side — already wired)

- Drop each finished PNG at `assets/images/cards/<tip.id>.png`.
- `TipCard` shows it automatically as the card hero. Missing files fall back to
  the time-arc + emoji, so you can roll the set out one card at a time.
- Square-ish art works best: hero is rendered at **aspect ratio 1.15** with
  `BoxFit.cover`. Target export **~1024×900 px**, transparent or cream background.
- Keep file size reasonable (the ginger-tea sample is ~300 KB). 88 cards ≈ a few
  MB in the bundle; fine for offline-first.

## Locked style (paste this BEFORE every subject line)

> Soft editorial watercolor illustration with fine sepia/brown ink line-art on
> top. Muted "golden hour" palette: sage green, warm peach, cream, soft saffron.
> Gentle loose watercolor wash background with soft bleeding edges. Centered
> composition, a few botanical leaves framing the subject, calm and premium,
> hand-drawn storybook feel. No text, no letters, no border. Square composition,
> cream/transparent background.

Then append: **"Subject: <the line below>."**

## Cards

`w_ginger_tea` — ✅ DONE (the sample you generated; already in the app)

### First batch (lock the style on these 4, then continue)

| tip.id | Subject line to append |
|---|---|
| `w_kefir` | a tall glass of kefir / fermented milk drink, a few scattered kefir grains and a sprig of fresh mint beside it, on a calm surface |
| `w_walk_after_meal` | a pair of comfortable walking shoes mid-step on a garden path, a few leaves and a soft sun arc in the background, suggesting a gentle 15-minute walk |
| `w_fennel_tea` | a clear cup of pale fennel tea with whole fennel seeds and a feathery fennel frond resting beside the saucer, light steam rising |
| `w_yogurt` | a rustic ceramic bowl of plain white yogurt with a wooden spoon, a sprig of mint on top, simple and homely |
| `w_chew_slowly` | a single fork lifting a small bite, a calm plate of food, a soft clock-arc motif in the background hinting "slow down and chew" |

## Workflow

1. In Gemini, paste **Locked style** + `Subject: ...` for one card.
2. Export the result as PNG, name it exactly `<tip.id>.png`.
3. Drop into `assets/images/cards/`.
4. Hot restart the app (assets need a full restart, not hot reload).

Once the style on the first batch looks right, I'll generate the remaining 83
subject lines (all categories: digestion, immunity, sleep, energy, skin,
hydration, boundaries, emotions, cooperation, confidence, earlyYears) in the
same table format.

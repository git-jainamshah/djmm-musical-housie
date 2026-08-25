# DJMM Musical Housie — Project Context

> **Purpose of this file:** Give any AI agent (or developer) full context to understand, run, modify, and deploy this project without prior conversation history.

---

## Why This Project Exists

This is an internal event tool built for **ડભોઈ જૈન મિત્ર મંડળ - વડોદરા**.

During the gathering, participants play **Musical Housie** (also called Musical Tambola / Kukuba). Instead of calling numbers 1–90, the host plays Bollywood songs — each song maps to two housie numbers on the players' tickets.

**The problem:** The hosts are not very tech-savvy. They need a dead-simple way to:
1. Pick a random housie number during the game
2. Play the correct song instantly through speakers
3. See which song is playing and navigate forward/backward
4. Browse the full list of 45 songs if needed

**The solution:** A single-page, mobile-first web app that works on a phone connected to speakers. No app install, no login, no build step — just open a URL and tap big buttons.

**Deployment:** Hosted from GitHub on Vercel as a static site. Audio files are bundled in the repository so playback does not stream from YouTube at runtime.

---

## Event Details (Accurate Gujarati Copy)

These strings live in `data/songs.json → event` and are rendered in `index.html`:

| Field | Gujarati Text |
|-------|---------------|
| Blessing | `\|\| શ્રી લોઢણ પાર્શ્વનાથાય નમઃ \|\|` |
| Evening tagline | `સંગીતમય સાંજ` |
| Group name | `ડભોઈ જૈન મિત્ર મંડળ - વડોદરા` |
| Game type | `મ્યુઝિકલ હાઉઝી` |
| Date | `તારીખ: ૨૭ સપ્ટેમ્બર, ૨૦૨૬` |

**Printable document:** `output/pdf/DJMM - Musical Housie A4.pdf` — generated from `templates/djmm-musical-housie-a4.html`. The paste guide provides a verified **110 × 45 mm** ticket area, slightly larger than the approximately 100 × 40 mm ticket in the supplied reference sheet.

---

## How Musical Housie Works (Game Rules)

Standard 90-number housie, but numbers are replaced by **45 songs**. Each song appears on **two numbers**:

```
Song 1  → numbers  1, 46
Song 2  → numbers  2, 47
...
Song 45 → numbers 45, 90
```

Formula: `songId = ((housieNumber - 1) % 45) + 1`

**Prize categories** (from PDF, for reference — not implemented in the app):
- પહેલાં ૫ (First 5) × 2
- પહેલાં ૯ (First 9) × 2
- ચાર ખૂણા (Four corners) × 2
- ઉપરની / વચ્ચેની / નીચેની લાઈન (Lines) × 2 each
- એકફાસ્ટ / લંચ / ડિનર × 2 each
- ફુલ હાઉઝી (Full house) × 4

The app only handles **song playback and number calling** — prize tracking is done manually on paper tickets.

---

## What Was Built (Technical Summary)

### Architecture

```
Static site — no framework, no build step, no backend
├── HTML shell (index.html)
├── CSS (css/style.css) — mobile-first Spotify-inspired dark theme
├── Vanilla JS player (js/app.js) — IIFE, no dependencies
├── JSON data (data/songs.json) — event metadata + 45 songs
├── Audio assets (audio/*.mp3) — pre-downloaded from YouTube
├── Album artwork (musical_housie_ablum_pictures/*.jpg)
├── Service worker (sw.js) — cache-first audio and cache cleanup
├── Vercel config (vercel.json) — static serving and cache headers
└── Download script (scripts/download-songs.py) — yt-dlp pipeline
```

### Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **Vanilla JS, no React/Vue** | Zero build step; easy Vercel deploy; minimal complexity for a one-page tool |
| **Pre-downloaded audio (not YouTube embed)** | Reliable offline playback; no ads; works without internet after first load; hosts don't need YouTube open |
| **Pre-bundled `.mp3` files** | Direct browser playback without relying on YouTube during the event |
| **`data/songs.json` as single source of truth** | Event text, song names (GU/HI/EN), movie, YouTube URL, and audio path all in one file |
| **Mobile-first UI** | Primary use case is a phone connected to speakers at the function |
| **Gujarati numeral display** | Housie numbers shown as ૧૨૩ not 123 — matches the physical tickets |

The original 30 songs have playable `.mp3` files. Songs 31–45 are fully mapped but intentionally have `audioPending: true` and blank audio paths until their media is selected. The repository also retains 30 legacy `.m4a` files that are not loaded by the app.

### UI Design (Current)

- **Theme:** Spotify dark — `#121212` body, `#181818` surfaces, `#1DB954` green accent
- **Gujarati font:** Locally bundled Noto Serif Gujarati in Regular, Medium, SemiBold, and Bold weights; Noto Sans Devanagari remains available for Hindi metadata
- **PDF table type:** Prize entries, song numbers, and song titles use the same Noto Serif Gujarati 10pt size—longer titles are never individually reduced
- **Easy rollback:** Before this change, the web body used Noto Sans Gujarati and the top title used Anek Gujarati; that web/PDF version is preserved in Git commit `5550766`
- **Layout:** Flex shell with a fixed top bar, scrollable main area, and persistent mini-player — max-width 480px
- **Touch targets:** Play button 64–72px circle, Random button 56px full-width, skip buttons 56px
- **Safe areas:** `env(safe-area-inset-*)` for iPhone notch/home bar
- **Progress bar:** Custom 4px green track; 1000-step range input; pointer + touch events for mobile scrubbing
- **Album art:** Local artwork first, YouTube thumbnail fallback, then a cycling gradient placeholder
- **Housie number:** Large Gujarati song ID plus its two ticket-number aliases
- **Song list:** Spotify-style track rows with artwork, Gujarati name, singers/movie, and housie aliases

### Player Logic (`js/app.js`)

State object:
```javascript
{
  songs: [],              // loaded from songs.json
  currentHousieNumber: 1, // current song ID, 1–45
  playedNumbers: Set(),   // tracks played song IDs for random picker
  isPlaying: false,
  isSeeking: false        // true while user drags progress bar
}
```

Key functions:
- `playSongByHousie(n)` — selects a song ID, marks it played, loads audio, and plays
- `pickRandom()` — picks from unplayed song IDs 1–45; reuses the full pool after all 45 have been selected
- `houseNums(songId)` — maps each song ID to `[songId, songId + 45]`
- `toGu(n)` — converts ASCII digits to Gujarati numerals
- Progress seeking uses `PROGRESS_MAX = 1000` for fine-grained scrubbing; `isSeeking` flag prevents `timeupdate` from fighting the slider during drag

### Audio Download Pipeline (`scripts/download-songs.py`)

1. Reads `data/songs.json`
2. For each song, tries YouTube URL → ytsearch fallback by English name → ytsearch by Hindi name
3. Downloads via **yt-dlp**; uses **certifi** for SSL cert fix on macOS Python
4. Output: `audio/NN-slug.mp3` when ffmpeg is installed, otherwise `.m4a`
5. Updates `songs.json` with final audio paths

Run with:
```bash
pip install -r requirements.txt   # yt-dlp, certifi
python3 scripts/download-songs.py
# or: npm run download
```

**Note:** ffmpeg optional. Without it, files are `.m4a`. With ffmpeg, converts to `.mp3`.

---

## File Structure

```
DJMM Musical Housie/
├── index.html                  # App shell — header, player, and song list
├── css/style.css               # All styles (CSS custom properties, no preprocessor)
├── js/app.js                   # Player logic (IIFE, ~320 lines)
├── data/
│   └── songs.json              # Event metadata + 45 songs (source of truth)
├── audio/                      # Pre-downloaded MP3 files used by the app
│   ├── 01-lag-jaa-gale.mp3
│   ├── 02-roop-tera-mastana.mp3
│   └── ... (through 30)
├── scripts/
│   └── download-songs.py       # yt-dlp download script
├── templates/
│   └── djmm-musical-housie-a4.html # Printable A4 PDF source with 110 × 45 mm ticket guide
├── output/pdf/
│   └── DJMM - Musical Housie A4.pdf # Gujarati housie PDF
├── sw.js                       # Audio-focused service worker
├── context.md                  # This file
├── README.md                   # User-facing quick start
├── package.json                # npm scripts: download, serve
├── requirements.txt            # Python deps for download script
├── vercel.json                 # Cache headers for /audio/*
└── .gitignore
```

---

## Data Schema (`data/songs.json`)

```json
{
  "event": {
    "blessingGu": "|| શ્રી લોઢણ પાર્શ્વનાથાય નમઃ ||",
    "eveningGu": "સંગીતમય સાંજ",
    "titleGu": "ડભોઈ જૈન મિત્ર મંડળ - વડોદરા",
    "subtitleGu": "મ્યુઝિકલ હાઉઝી",
    "dateGu": "તારીખ: ૨૭ સપ્ટેમ્બર, ૨૦૨૬"
  },
  "songs": [
    {
      "id": 1,
      "nameGu": "લગ જા ગલે",
      "nameHi": "लग जा गले",
      "nameEn": "Lag Jaa Gale",
      "movie": "Woh Kaun Thi",
      "youtube": "https://www.youtube.com/watch?v=...",
      "audio": "audio/01-lag-jaa-gale.mp3"
    }
  ]
}
```

### Full Song List (PDF Order)

| ID | Gujarati | Housie Numbers | Audio |
|----|----------|----------------|-------|
| 1 | લગ જા ગલે | 1, 46 | Ready |
| 2 | રૂપ તેરા મસ્તાના | 2, 47 | Ready |
| 3 | પલ પલ દિલ કે પાસ | 3, 48 | Ready |
| 4 | ચુરા લિયા હૈ તુમને | 4, 49 | Ready |
| 5 | દમ મારો દમ | 5, 50 | Ready |
| 6 | મેરે સપનોં કી રાની | 6, 51 | Ready |
| 7 | યે દોસ્તી હમ નહીં તોડેંગે | 7, 52 | Ready |
| 8 | એક દો તીન | 8, 53 | Ready |
| 9 | તુઝે દેખા તો | 9, 54 | Ready |
| 10 | પહેલા નશા | 10, 55 | Ready |
| 11 | આજ કલ તેરે મેરે પ્યાર | 11, 56 | Ready |
| 12 | ગુલાબી આંખેં | 12, 57 | Ready |
| 13 | ઓ મેરે દિલ કે ચૈન | 13, 58 | Ready |
| 14 | એક લડકી કો દેખા | 14, 59 | Ready |
| 15 | દિલ દીવાના | 15, 60 | Ready |
| 16 | કભી કભી મેરે દિલ | 16, 61 | Ready |
| 17 | મેહંદી લગા કે રખના | 17, 62 | Ready |
| 18 | છૈયા છૈયા | 18, 63 | Ready |
| 19 | યાર બિના ચૈન | 19, 64 | Ready |
| 20 | ડિસ્કો દીવાને | 20, 65 | Ready |
| 21 | ખાઈ કે પાન બનારસ | 21, 66 | Ready |
| 22 | આપ કી નજરોં ને | 22, 67 | Ready |
| 23 | હવા હવાઈ | 23, 68 | Ready |
| 24 | જુમ્મા ચુમ્મા દે દે | 24, 69 | Ready |
| 25 | યે કાલી કાલી આંખેં | 25, 70 | Ready |
| 26 | ઐંવઈ ઐંવઈ | 26, 71 | Metadata added; artwork and audio pending |
| 27 | દીદી તેરા દેવર | 27, 72 | Ready |
| 28 | જો હાલ દિલ કા | 28, 73 | Ready |
| 29 | મેરે ખ્વાબોં મેં જો | 29, 74 | Ready |
| 30 | લૈલા મૈં લૈલા | 30, 75 | Ready |
| 31 | જવાની જાનેમન | 31, 76 | Pending |
| 32 | હરિ ઓમ હરિ | 32, 77 | Pending |
| 33 | કોઈ યહાં નાચે નાચે | 33, 78 | Pending |
| 34 | મહેબૂબા મહેબૂબા | 34, 79 | Pending |
| 35 | જબ છાયે મેરા જાદુ | 35, 80 | Pending |
| 36 | કાલા ચશ્મા | 36, 81 | Pending |
| 37 | બોલો તારા રા રા | 37, 82 | Metadata and artwork added; audio pending |
| 38 | તુને મારી એન્ટ્રી | 38, 83 | Pending |
| 39 | હેલો યેલો | 39, 84 | Pending |
| 40 | કોઈ કહે કહેતા રહે | 40, 85 | Pending |
| 41 | મલ્હારી | 41, 86 | Pending |
| 42 | મે સે મીના શાના સાકી લે | 42, 87 | Pending |
| 43 | છોગાળા તારા | 43, 88 | Pending |
| 44 | આંખ મારે | 44, 89 | Metadata and artwork added; audio pending |
| 45 | હોવે હોવે | 45, 90 | Pending |

---

## Known Ambiguities & Decisions

1. **Song #20 (`ડિલ દો દવાને`)** — PDF transliteration is unclear. Mapped to **"Dil Do Na"** from Heyy Babyy. User should confirm this is correct; easy to swap in `songs.json` + re-download audio.

2. **Gujarati song names** — Extracted from PDF via `pypdf`; some transliterations may differ slightly from spoken Gujarati. User provided corrected event-level text; individual song names come from the PDF.

3. **Audio source** — Songs downloaded from YouTube via yt-dlp (official channel uploads where possible). Not all may be the exact "official" version — acceptable for a family function.

4. **Audio format** — Currently `.m4a` (~148 MB total). Vercel free tier supports this size but it's close to repo limits. If deploying fails, consider Git LFS or converting to lower-bitrate mp3 with ffmpeg.

5. **No prize tracking** — App does not track who won which dividend. That's handled on paper tickets.

---

## How to Run Locally

```bash
# Serve (no install needed)
python3 -m http.server 8765
# Open http://localhost:8765

# Or via npm
npm run serve   # port 3000
```

**Important:** Must serve via HTTP (not `file://`) — `fetch('data/songs.json')` requires a server.

---

## How to Deploy (Vercel)

1. Ensure the referenced `audio/*.mp3` files are committed
2. Push to GitHub
3. Import on vercel.com — **no build command**, output dir `.`
4. `vercel.json` sets long cache headers on `/audio/*`

---

## How to Modify (Common Tasks)

### Change a song
Edit `data/songs.json` → update name/YouTube URL → delete old audio file → run `python3 scripts/download-songs.py`

### Change event text
Edit `data/songs.json → event` — app loads dynamically on page load

### Change UI colors
Edit CSS custom properties in `:root` at top of `css/style.css`:
```css
--bg-deep: #1a0a12;
--gold: #d4a853;
--rose: #c9788a;
```

### Add a feature (e.g. prize tracker, called-numbers log)
- All logic is in `js/app.js` (single IIFE)
- No module bundler — just edit the file directly
- State is in-memory only (resets on page refresh) — use `localStorage` if persistence needed

---

## Development History

| Phase | What happened |
|-------|---------------|
| **Initial build** | Parsed PDF for 30 songs; built vanilla HTML/CSS/JS player; downloaded all audio via yt-dlp; orange/simple theme |
| **UI redesign v1** | User requested classy mobile-friendly design → wine/gold dark theme, SVG icons, glass cards, larger touch targets, iPhone safe areas |
| **Audio fix** | Progress slider wasn't working on mobile → added pointer/touch events, 1000-step range, visual fill track, `isSeeking` flag |
| **Gujarati text correction** | User provided accurate event copy → updated `songs.json` event block and HTML fallbacks |
| **Context doc** | This file created for AI/developer handoff |
| **Spotify redesign + album details** | Full UI rebuild: Spotify dark theme (`#121212`, `#1DB954` green), sticky top bar + scrollable content + sticky Random button at bottom. Added `singers`, `musicBy`, `year` fields to all 30 songs in `songs.json`. Song list uses Spotify-style track rows with per-song gradient art placeholders. Big housie number badge overlays album art. Now-playing shows singers + music director. |
| **45-song architecture** | Remapped 1–90 into 45 two-number pairs (`n`, `n + 45`), added songs 31–44 plus placeholder song 45, introduced audio-pending UI states, and removed the hosts section. |

---

## Constraints for Future AI Agents

- **Do not over-engineer** — this is a one-day family event tool, not a product
- **Keep it static** — no backend, no database, no auth unless explicitly requested
- **Mobile-first always** — primary users are non-technical Gujarati-speaking mothers on phones
- **Gujarati text is sacred** — verify with user before changing any Gujarati copy
- **Audio must be pre-bundled** — do not switch to YouTube iframe/embed at runtime
- **No commits unless user asks** — per user preference

---

## Quick Reference Commands

```bash
# Local dev
python3 -m http.server 8765

# Download/re-download songs
pip install -r requirements.txt
python3 scripts/download-songs.py

# Deploy
git push origin main   # Vercel auto-deploys
```

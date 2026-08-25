# DJMM Musical Housie — Live Song Player

A simple, one-page web app to play songs live for **ડભોઈ જૈન મિત્ર મંડળ - વડોદરા**.

Built for easy use — large buttons, Gujarati labels, and a scrollable song list.

## Features

- **90 housie numbers** mapped to **45 songs** (each song appears at two numbers: 1/46, 2/47, etc.)
- Large play/pause, previous, and next controls
- **Random song** picker that avoids repeats until all 45 songs have been selected
- Full song list — tap any song to play
- Gujarati number display
- Works on phone, tablet, and laptop

## Quick Start (Local)

### 1. Download song audio

You need **yt-dlp** and **ffmpeg**:

```bash
pip install yt-dlp
brew install ffmpeg   # macOS
```

The original 30 songs already have audio. Songs 31–45 are mapped in the UI and currently marked as audio pending.

To download or refresh mapped audio later:

```bash
npm run download
# or: python3 scripts/download-songs.py
```

Audio files are saved to `audio/` as MP3.

### 2. Run locally

```bash
npm run serve
# Open http://localhost:3000
```

## Deploy to Vercel

1. Push this repo to GitHub
2. Import the project on [vercel.com](https://vercel.com)
3. No build command needed — it's a static site
4. **Important:** Run `npm run download` before pushing so `audio/*.mp3` files are included in the repo (Vercel serves them as static assets)

### Vercel settings

| Setting       | Value        |
|---------------|--------------|
| Framework     | Other        |
| Build Command | *(leave empty)* |
| Output Dir    | `.`          |

## Song List (45 songs, PDF order)

| # | Song (Gujarati) | Numbers |
|---|-----------------|---------|
| 1 | લગ જા ગલે | 1, 46 |
| 2 | રૂપ તેરા મસ્તાના | 2, 47 |
| ... | *(see data/songs.json)* | ... |
| 30 | લૈલા મૈં લૈલા | 30, 75 |
| 45 | હોવે હોવે | 45, 90 |

## Project Structure

```
├── index.html          # Main app
├── css/style.css       # Styles (large, mom-friendly UI)
├── js/app.js           # Player logic
├── data/songs.json     # Song metadata + YouTube sources
├── audio/              # MP3 files (after download)
├── templates/djmm-musical-housie-a4.html # Printable PDF source
├── output/pdf/         # Generated A4 participant sheet
├── scripts/download-songs.py
└── vercel.json
```

## For the Hosts

1. Open the website on a phone or laptop connected to speakers
2. Use **🎲 રેન્ડમ નંબર** to pick the next housie number
3. The song plays automatically — announce the number shown on screen
4. Use **પાછળ / આગળ** to go to previous/next number
5. Tap any song in the list to jump directly

---

Made with ❤️ for **ડભોઈ જૈન મિત્ર મંડળ - વડોદરા**.

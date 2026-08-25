#!/bin/bash
# DJMM Musical Housie — Audio Download
# Double-click this file in Finder to run.
# Uses your Chrome cookies to bypass YouTube bot detection.

cd "$(dirname "$0")"
AUDIO_DIR="$(pwd)/audio"
mkdir -p "$AUDIO_DIR"

# Find yt-dlp
YTDLP=""
for p in /opt/homebrew/bin/yt-dlp /usr/local/bin/yt-dlp "$HOME/.local/bin/yt-dlp" "$HOME/Library/Python/3.11/bin/yt-dlp" "$HOME/Library/Python/3.12/bin/yt-dlp"; do
  [ -x "$p" ] && YTDLP="$p" && break
done
command -v yt-dlp &>/dev/null && YTDLP="yt-dlp"

if [ -z "$YTDLP" ]; then
  echo "yt-dlp not found. Install with: brew install yt-dlp"
  read -p "Press Enter to close..."; exit 1
fi

echo "Using yt-dlp: $YTDLP"
echo "Downloading 30 songs into: $AUDIO_DIR"
echo "(Using Chrome cookies to bypass YouTube auth)"
echo "--------------------------------------------"

dl() {
  local num="$1" file="$2" url="$3" title="$4"
  printf "[%02d/30] %s ... " "$num" "$title"
  # Format 140 = YouTube native m4a audio (no ffmpeg needed)
  # --cookies-from-browser chrome bypasses bot detection
  "$YTDLP" \
    -f "140/bestaudio[ext=m4a]/bestaudio" \
    --cookies-from-browser chrome \
    -o "$AUDIO_DIR/${file}.m4a" \
    "$url" \
    --no-playlist --quiet --no-warnings --force-overwrites \
    && echo "✓" || {
      # Fallback: try Safari cookies
      "$YTDLP" \
        -f "140/bestaudio[ext=m4a]/bestaudio" \
        --cookies-from-browser safari \
        -o "$AUDIO_DIR/${file}.m4a" \
        "$url" \
        --no-playlist --quiet --no-warnings --force-overwrites \
        && echo "✓ (safari)" || echo "✗ FAILED"
    }
}

dl  1  "01-lag-jaa-gale"            "https://youtu.be/DFbbpMD3taw"  "Lag Ja Gale"
dl  2  "02-roop-tera-mastana"        "https://youtu.be/dyEdcOhxJNQ"  "Roop Tera Mastana"
dl  3  "03-pal-pal-dil-ke-paas"     "https://youtu.be/AMuRRXCuy-4"  "Pal Pal Dil Ke Paas"
dl  4  "04-chura-liya-hai-tumne"    "https://youtu.be/seFeZOgyFsc"   "Chura Liya Hai Tumne"
dl  5  "05-dum-maaro-dum"           "https://youtu.be/kOrRYDJ4AuY"   "Dum Maaro Dum"
dl  6  "06-mere-sapnon-ki-rani"     "https://youtu.be/UlWAjd9bcKw"   "Mere Sapnon Ki Rani"
dl  7  "07-ye-dosti-hum-nahin"      "https://youtu.be/wFAU_duK0Jc"   "Ye Dosti Hum Nahin"
dl  8  "08-ek-do-teen"              "https://youtu.be/MS5BLS2sIDM"   "Ek Do Teen"
dl  9  "09-tujhe-dekha-to"          "https://youtu.be/cNV5hLSa9H8"   "Tujhe Dekha To"
dl 10  "10-pehla-nasha"             "https://youtu.be/SBfPs-PMGTA"   "Pehla Nasha"
dl 11  "11-aaj-kal-tere-mere-pyar"  "https://youtu.be/ulEiyaxHx4s"   "Aaj Kal Tere Mere Pyar"
dl 12  "12-gulabi-aankhen"          "https://youtu.be/Xsn0QjMN3fM"   "Gulabi Aankhen"
dl 13  "13-o-mere-dil-ke-chain"     "https://youtu.be/_w14bUcxl1c"   "O Mere Dil Ke Chain"
dl 14  "14-ek-ladki-ko-dekha"       "https://youtu.be/htMvfOfixuM"   "Ek Ladki Ko Dekha"
dl 15  "15-dil-deewana"             "https://youtu.be/5s68NXiaWgk"   "Dil Deewana"
dl 16  "16-kabhi-kabhi-mere-dil"    "https://youtu.be/-W2dagktUp0"   "Kabhi Kabhi Mere Dil"
dl 17  "17-mehndi-laga-ke-rakhna"   "https://youtu.be/-bNwqXvMuB8"   "Mehndi Laga Ke Rakhna"
dl 18  "18-chaiyya-chaiyya"         "https://youtu.be/9yT4F8hzykY"   "Chaiyya Chaiyya"
dl 19  "19-yaar-bina-chain"         "https://youtu.be/rHVB-w1Dt2g"   "Yaar Bina Chain"
dl 20  "20-disco-deewane"           "https://youtu.be/_b2smR_tINE"   "Disco Deewane"
dl 21  "21-khaike-paan-banaras"     "https://youtu.be/VyqhPYe0vew"   "Khaike Paan Banaras"
dl 22  "22-aap-ki-nazron-ne"        "https://youtu.be/Wv-VlQMD0VY"   "Aap Ki Nazron Ne"
dl 23  "23-hawa-hawai"              "https://youtu.be/IgKdXLfxgQQ"   "Hawa Hawai"
dl 24  "24-jumma-chumma-de-de"      "https://youtu.be/5gTToFIZp-g"   "Jumma Chumma De De"
dl 25  "25-ye-kaali-kaali-aankhen"  "https://youtu.be/KC-DuX51NY0"   "Ye Kaali Kaali Aankhen"
dl 26  "26-ainvayi-ainvayi"         "https://youtu.be/pElk1ShPrcE"   "Ainvayi Ainvayi"
dl 27  "27-didi-tera-devar"         "https://youtu.be/ZqcDGvCM_w0"   "Didi Tera Devar"
dl 28  "28-jo-haal-dil-ka"          "https://youtu.be/Y9OnEE7FAcc"   "Jo Haal Dil Ka"
dl 29  "29-mere-khwabon-mein-jo"    "https://youtu.be/s1LozokQjIg"   "Mere Khwabon Mein Jo"
dl 30  "30-laila-main-laila"        "https://youtu.be/1i_MwtbXezY"   "Laila Main Laila"

echo ""
echo "--------------------------------------------"
echo "All done! Check above for any ✗ FAILED."
echo ""
echo "Now push to GitHub:"
echo "  cd \"$(pwd)\""
echo "  git add audio/"
echo "  git commit -m 'chore: refresh all audio from CSV youtube links'"
echo "  git push"
echo ""
read -p "Press Enter to close..."

#!/usr/bin/env python3
"""Download housie song audio from YouTube using yt-dlp."""

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

try:
    import certifi

    os.environ.setdefault("SSL_CERT_FILE", certifi.where())
except ImportError:
    pass

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "songs.json"
AUDIO_EXT = ".mp3" if shutil.which("ffmpeg") else ".m4a"
NODE_RUNTIME = shutil.which("node")


def slugify(value: str) -> str:
    """Return a stable, filesystem-safe ASCII slug."""
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", normalized.lower()).strip("-")


def apply_csv_links(csv_path: Path, songs: list[dict]) -> int:
    """Validate CSV song mappings and apply their source/audio paths in memory."""
    songs_by_id = {song["id"]: song for song in songs}
    seen: set[int] = set()

    with csv_path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        required = {"Song Number", "Song Name", "Song Link"}
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise ValueError(f"CSV must contain columns: {', '.join(sorted(required))}")

        for row_number, row in enumerate(reader, start=2):
            try:
                song_id = int(row["Song Number"].strip())
            except (TypeError, ValueError) as exc:
                raise ValueError(f"Invalid Song Number on CSV row {row_number}") from exc

            if song_id in seen:
                raise ValueError(f"Duplicate Song Number in CSV: {song_id}")
            if song_id not in songs_by_id:
                raise ValueError(f"Unknown Song Number in CSV: {song_id}")

            source = row["Song Link"].strip()
            if not source.startswith(("https://www.youtube.com/", "https://youtu.be/")):
                raise ValueError(f"Invalid YouTube link for song {song_id}")

            song = songs_by_id[song_id]
            csv_name = row["Song Name"].strip().casefold()
            if csv_name != song["nameEn"].strip().casefold():
                raise ValueError(
                    f"Song name mismatch for {song_id}: CSV has {row['Song Name']!r}, "
                    f"project has {song['nameEn']!r}"
                )

            song["youtube"] = source
            if not song.get("audio"):
                song["audio"] = f"audio/{song_id:02d}-{slugify(song['nameEn'])}.mp3"
            seen.add(song_id)

    return len(seen)


def download_one(song: dict, outfile: Path) -> bool:
    stem = outfile.with_suffix("")
    source = song.get("youtube", "")
    if not source:
        print(f"  No YouTube URL for: {song['nameEn']}", file=sys.stderr)
        return False

    cmd = ["yt-dlp", "--force-ipv4"]
    if NODE_RUNTIME:
        cmd.extend(
            [
                "--js-runtimes",
                f"node:{NODE_RUNTIME}",
                "--remote-components",
                "ejs:github",
            ]
        )

    if AUDIO_EXT == ".mp3":
        cmd.extend([
            "--extract-audio",
            "--audio-format",
            "mp3",
            "--audio-quality",
            "5",
            "--no-playlist",
            "--force-overwrites",
            "-o",
            f"{stem}.%(ext)s",
            source,
        ])
    else:
        cmd.extend([
            "-f",
            "bestaudio[ext=m4a]/bestaudio/best",
            "--no-playlist",
            "--force-overwrites",
            "-o",
            f"{stem}.%(ext)s",
            source,
        ])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and outfile.exists():
        return True

    for f in stem.parent.glob(stem.name + ".*"):
        if f.suffix in {".m4a", ".mp3", ".webm", ".opus"}:
            if f != outfile:
                f.rename(outfile)
            return True

    if result.stderr:
        print(result.stderr[-500:], file=sys.stderr)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Download housie song audio from YouTube")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-download even if audio file already exists",
    )
    parser.add_argument(
        "--csv",
        type=Path,
        help="Import Song Number, Song Name, and Song Link mappings from a CSV file",
    )
    args = parser.parse_args()

    if not shutil.which("yt-dlp"):
        print("Install yt-dlp: pip install yt-dlp")
        return 1

    if not shutil.which("ffmpeg"):
        print("Note: ffmpeg not found — saving as .m4a (plays fine in browsers).")
        print("For mp3: brew install ffmpeg, then re-run.\n")

    payload = json.loads(DATA.read_text(encoding="utf-8"))
    songs = payload["songs"]
    total = len(songs)

    if args.csv:
        imported = apply_csv_links(args.csv.expanduser().resolve(), songs)
        print(f"Validated {imported} CSV song mappings.\n")

    for i, song in enumerate(songs, 1):
        if not song.get("audio"):
            song["audio"] = f"audio/{song['id']:02d}-{slugify(song['nameEn'])}{AUDIO_EXT}"

        rel = Path(song["audio"])
        stem = rel.stem
        outfile = ROOT / "audio" / f"{stem}{AUDIO_EXT}"
        song["audio"] = f"audio/{outfile.name}"

        if outfile.exists() and not args.force:
            print(f"[{i}/{total}] Skip (exists): {outfile.name}")
            song.pop("audioPending", None)
            continue

        print(f"[{i}/{total}] Downloading: {song['nameEn']} -> {outfile.name}")
        outfile.parent.mkdir(parents=True, exist_ok=True)
        if not download_one(song, outfile):
            print(f"  Failed: {song['youtube']}", file=sys.stderr)
            return 1
        song.pop("audioPending", None)

    DATA.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\nUpdated {DATA.name} with audio paths ({AUDIO_EXT})")
    print(f"Done! {total} songs in {ROOT / 'audio'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

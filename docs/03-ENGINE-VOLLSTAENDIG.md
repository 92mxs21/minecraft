# 03 – Dream Displays: Der komplette Code-Walkthrough 🧬

> Frisch-geklonter Source, Zeile für Zeile durchsucht (Stand 28.09.2026, Commit `b649261`).
> Repo: <https://github.com/arsmotorin/dreamdisplays> · Lizenz: **LGPL-3.0**

---

## 📊 Sprachen & Größe

| Sprache | Zeilen | Dateien | Anteil |
|---------|-------:|--------:|-------:|
| **Kotlin** | 61.701 | 592 | ~85 % |
| **Rust** 🦀 | 6.258 | 12 | ~9 % |
| JSON (Ressourcen/Config) | 3.972 | 30 | ~5 % |
| Gradle Kotlin DSL | 1.408 | 26 | ~1 % |
| **Java** | **0** 🤯 | 0 | 0 % |

**Keine einzige Zeile Java** – das komplette Projekt ist modernes **Kotlin** (JVM-Seite)
plus **Rust** (nativer Decoder). Hauptentwickler: **Arsenii** (arsmotorin),
Credits in `fabric.mod.json`: INotSleep, Kolyakot33, Toffikk.

---

## 🗺️ Die 18 Gradle-Module (`settings.gradle.kts`)

```
dreamdisplays ─┬─ :api              → Öffentliche Schnittstellen (Packet-Typen, Modelle, Services)
               ├─ :core             → Protokoll-Registry, gemeinsame Logik Client↔Server
               ├─ :util             → Helferlein
               ├─ :native           → 🦀 Rust-Decoder, wird als .dll/.so/.dylib gebaut
               ├─ :media
               │  ├─ :runtime       → Externe Prozesse (yt-dlp, ffmpeg) managen
               │  ├─ :source        → 🔍 Resolver je Plattform (Link → Roh-Stream-URL)
               │  ├─ :player        → Der eigentliche MediaPlayer (Steuerung, Zustand)
               │  └─ :audio         → Eigene 3D-Audio-DSP-Engine
               └─ :platform
                  ├─ :resources     → Assets, Sprachdateien (13 Sprachen!)
                  ├─ :client:common → Rendering, Input, UI (Plattform-neutral)
                  ├─ :client:fabric / :client:neoforge → Loader-Anbindung
                  ├─ :server        → Commands, Display-Manager, Netzwerk
                  └─ :proxy         → Velocity + BungeeCord (!) → funktioniert sogar hinter Proxys
```

**Multi-Version-Trick:** Das Buildsystem **Stonecutter** kompiliert denselben Code parallel
für `1.21.1`, `1.21.11`, `26.1.2`, `26.2` und `26.3` – pro Version eigene
Java-Toolchain (21 → **25** ab 26.x), Loader- und API-Versionen in `versions.json`.
Deshalb erscheinen Updates für neue MC-Versionen hier immer so schnell. ⚡

---

## 🚦 Lebenszyklus – vom Tastendruck bis zum Pixel

### A) Start
`fabric.mod.json` definiert zwei Einstiegspunkte:
```json
"entrypoints": {
  "client": ["com.dreamdisplays.platform.client.Client"],   // nur im Spiel-Client
  "main":   ["com.dreamdisplays.platform.server.Server"]    // nur auf dem Server
}
```
→ **Eine einzige .jar für beide Seiten.** Fabric lädt je nach Umgebung die passende Hälfte.
Dazu zwei Mixin-Sets (`dreamdisplays.mixins.json` + Server-Mixins) und ein AccessWidener.

### B) Screen bauen & Display anlegen (Server)
- 14 Admin-Commands: `Create, Delete, Video, On, Off, Name, List, Info, Fullscreen,
  Schedule, Stats, Reload, Help` (jeweils eigene Datei in `commands/subcommands/`).
- `DisplayManager` führt persistente Registry: **ID → Position, Größe, Ausrichtung,
  Helligkeit, Quell-URL, Modus** → überlebt Restart & Chunk-Unload.
- `PlayerManager` + LuckPerms-Anbindung: Wer darf Displays erstellen/steuern?

### C) Das Sync-Protokoll (v2) – „ein Umschlag, getypte Pakete" 💌
Kerndatei: `platform/server/.../net/V2Fabric.kt`
- **Ein einziger Envelope-Payload** `V2Payload(bytes)` in beide Richtungen.
- `PacketRegistry` (Modul `:core`) serialisiert/deserialisiert **getypte Paket-Klassen**
  (`core/protocol/common/packets/`):
  | Paket-Gruppe | Pakete (Auswahl) | Zweck |
  |---|---|---|
  | Handshake | `ClientHello` | Client meldet Mod-Version → Server weiß, wer Displays sehen kann |
  | Session | `RequestSync`, `ReportDuration` | Späteinsteiger holen Display-Zustand nach |
  | Display | `ReportDisplay`, `DisplayDelete` | Lebenszyklus |
  | Playback | `SetVideo`, `SetMode`, `PlaybackCommand` (play/pause/seek + Position in ms), `SetLocked` | Steuerung |
  | **WatchParty** 🎉 | `WatchPartyStart`, `WatchPartyControl` | Gemeinsames Abspielen mit geteilter Uhr |
  | Fullscreen | `FullscreenAck` | Broadcast-Modus für Events |
  | Token | Token-Pakete | Zugriffsschutz |
- Paketgrößen: nur **URLs, IDs, Zeitstempel** – nie Videodaten. Das gesamte Sync-Protokoll
  einer Filmnacht passt in ein paar KB. → Darum ist playit kein Problem.

### D) Link → Video: Die Resolver-Kette (`:media:source`) 🔗
Jede Plattform hat einen eigenen Resolver mit Cache:
```
youtube/   → NewPipeResolver (parst YouTube intern)
          → YtDlpResolver   (externer yt-dlp-Prozess als Leiter/Fallback)
          → NewPipeLadderTracker (steigt bei Blockaden automatisch um!)
twitch/    → eigene HLS-Auflösung (+ Qualitätswahl)
kick/  vimeo/  bilibili/  → eigene APIs + MetadataCaches
direct/    → DirectMediaProbe (ffprobe-artiger Check von .mp4/.m3u8)
YtDlpSearchService → die eingebaute YouTube-Suche im GUI
```
`RetryPolicy` cached Stream-URLs (laufen nach Stunden ab!) und wiederholt mit
exponentiellem Backoff, inkl. Cache-Purge. *Der bekannte „Waiting on video"-Freeze
entsteht, wenn YouTube die Signatur ändert und NewPipe/yt-dlp hinterherhinkt –
deshalb kommen Updates der Mod immer so schnell nach YouTube-Änderungen.*

### E) Dekodieren: Rust „LAV" (`:native`) 🦀
= **L**ib**AV** – handgeschriebenes C-ABI rund um FFmpeg-Bibliotheken, Panic-sicher,
`rayon`-Multithreading. JVM ↔ Rust verheiratet über genau diese Funktionen:

| Rust-Export (`extern "C"`) | Aufgabe |
|---|---|
| `dd_lav_abi_version()` | Handshake: JVM prüft ABI-Version 5 → kein Versions-Mischmasch |
| `dd_lav_seek(handle, µs)` | Frame-genaues Spulen |
| `dd_lav_bind_surface_plane_gl(...)` | **Dekodierte Frame-Plane direkt an OpenGL-Textur binden** (Zero-Copy-Gedanke) |
| `dd_lav_enable_cache(...)` | Ring-Cache für Frames (schnelles Zurückspringen) |
| `dd_lav_close/kill/release_surface` | Sauberes Aufräumen |

Fallback, falls natives Decoding scheitert: zwei klassische **ffmpeg-Subprozesse**
(Audio + Video getrennt – deshalb gibt's den `AUDIO_EOS_NEAR_END_GUARD`, damit das
Video nicht 3 s zu früh „Ende" meldet).

### F) Rendern (`:platform:client:common/render/`) 🖥️
- `RenderHook` = kleine SAM-Bridge, die im **World-Render-Pass** feuert.
- `DisplayGeometry` berechnet aus Blockauswahl eine exakte **Quad-Geometrie**.
- `AsyncTextureUploader`/`GpuFrameUploader` schieben neue Frames außerhalb des
  Render-Threads auf die GPU (kein FPS-Ruckeln).
- `DisplayYuvRenderTypes`: Video liegt als **YUV** an → Shader wandelt auf der GPU
  in RGB um. CPU rechnet null Farben.
- Ergebnis: **1 Quad + 1 Textur pro Screen** – keine Entities, keine Maps → 4K-ready.

### G) Audio: eine Mini-Akustik-Engine 🔊
`AudioRenderChain.kt` ist pro Display ein echter DSP-Graph:
- **Lautheits-Normalisierung auf −16 LUFS** (Boost max +12 dB, Cut max −3 dB,
  Änderungsrate 0,5 dB/s – wie ein Radio-Mastering-Limiter!)
- **Binauraler 3D-Sound** (`ParametricBinaural`, HRTF-artig) + Stereo-Panner
- **Okklusion**: Wände zwischen dir und Leinwand → Tiefpass 550–18.000 Hz + Dämpfung
- **Luftabsorption** über Distanz, Hall (`Reverb`), alles weich geglättet
  (`*_SMOOTH_SECONDS`-Konstanten gegen Gain-Zipper)

---

## 🧩 Warum diese Architektur so gut zu euch passt

1. **Server schickt keine Videos** → playit-Datenlimit chillt. ✅
2. **State lebt auf dem Server** → wer joint, sieht denselben Frame (RequestSync). ✅
3. **Jeder Client dekodiert selbst** → schwächerer Host-PC kein Problem. ✅
4. **Native Rust-Pipeline + GPU-Shader** → flüssig trotz Vanilla-Client-FPS. ✅
5. **Multi-Loader/-Version aus einem Code** → Updates für 26.x kommen schnell. ✅

Und das Schönste: **LGPL-3.0** – ihr dürft forken, patchen, eigene Resolver bauen
(z. B. für euren Weg-B-HLS-Stream aus Doku 02 reicht schon die eingebaute
`direct/`-Pipeline mit `DirectMediaProbe` – keine Code-Änderung nötig! 🎉)

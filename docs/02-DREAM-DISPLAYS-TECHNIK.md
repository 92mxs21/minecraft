# 02 – Dream Displays: Engine-Deep-Dive 🔧

> Quelle: komplettes Repo analysiert (frisch geklont am 28.09.2026).
> **Reverse Engineering war gar nicht nötig** – die Mod ist **Open Source (LGPL-3.0)**:
> <https://github.com/arsmotorin/dreamdisplays>

---

## 🧱 Projektstruktur (Multi-Modul-Gradle, Kotlin + Rust)

```
dreamdisplays/
├─ api/        → öffentliche API: MediaSource, Plattformen, Such-Modelle
├─ core/       → gemeinsame Logik (Client & Server)
├─ platform/
│  ├─ client/  → Rendering, Input, UI (32 Dateien allein fürs Rendern!)
│  └─ server/  → Display-Verwaltung, Commands, Netzwerk-Protokoll
├─ media/
│  ├─ player/  → Player-Steuerung, Extractor-Kette, Prozess-Verwaltung
│  └─ audio/   → eigene Audio-DSP-Engine (3D-Sound!)
├─ native/     → 🦀 RUST: nativer Video-Decoder („lav")
└─ util/
```

---

## 🔄 So funktioniert ein Filmabend – Schritt für Schritt

### 1. Screen erstellen (Server-Seite)
Du markierst eine schwarze Fläche → der Server speichert **nur Metadaten**:
Position, Größe, Ausrichtung, Helligkeit, Quell-URL, Abspielstatus.
Das bleibt **persistent** (überlebt Neustarts & Chunk-Unloading).

### 2. Sync-Protokoll – der clevere Teil 🧠
Dateien: `platform/server/.../utils/net/` → `V2Fabric.kt`, `V2Paper.kt`, `V2NeoForge.kt`,
`DisplayActions.kt`, `V2PlayerTracker.kt`

**Der Server schickt NIEMALS Videodaten.** Er broadcastet nur winzige Steuerpakete:
- *„Display X spielt jetzt URL Y"*
- *„Play / Pause / Seek zu Zeitstempel Z"*

**Jeder Client lädt und dekodiert das Video selbst** (direkt von YouTube & Co.).
→ Deshalb „ultra-low network impact" und deshalb funktioniert das sogar über einen
playit-Tunnel mit fetter 4K-Leinwand – durch den Tunnel gehen nur Steuerbefehle!
Der Server ist nur **Dirigent**, nicht Beamer. 🎻

### 3. YouTube & Co. abrufen – der Werbefrei-Trick 🚫📢
Dateien: `api/.../media/source/model/MediaSource.kt`, `CustomMediaKind.kt`,
`media/player/MediaPlayer.kt`, `media/runtime/.../Processes.kt`

Eine **Extractor-Kette** löst den Link in die rohe Video-Stream-URL auf:
1. **NewPipeExtractor** – speziell für YouTube (parst YouTube intern)
2. **yt-dlp** (externer Prozess!) – „long tail" für Twitch, Kick, Vimeo, Bilibili & fast jede andere Seite
3. Direkte Videolinks (`.mp4`, `.m3u8`/HLS) → gar keine Extraktion nötig

**Warum ist das werbefrei ganz ohne uBlock?**
Werbung wird von YouTube **nicht in die Videodatei** gerendert – sie wird im Webplayer
über separate Ad-Server **drübergelegt**. NewPipe/yt-dlp holen die **Roh-Streams**
direkt von Googles Servern – da ist schlicht keine Werbung drin. uBlock blockiert auf
Webebene; die Mod umgeht die Webebene komplett. Eleganter gelöst. 😎

### 4. Dekodieren – Rust & FFmpeg 🦀
Dateien: `native/lav/src/*.rs`, `media/player/.../nativebridge/LavFfmpeg.kt`,
`process/FFmpegBinary.kt`

- `native/lav/` = **„In-process libav decode backend"** (steht so in `lib.rs`):
  ein handgeschriebener Rust-Decoder, der via FFmpeg-Bibliotheken (libav) Frames
  direkt im Prozess dekodiert – C-ABI mit Versionscheck (`LAV_ABI_VERSION = 5`),
  Panic-sicher (Panics dürfen nie über die C-Grenze fliegen), Multithreading via `rayon`,
  Frame-Cache & Skalierung in `cache.rs` / `chunked.rs` / `scale.rs`.
- Fallback: externer **ffmpeg-Prozess**, der Frames durch eine Pipe schiebt
  (`pipeline/NativeVideoFramePipe.kt`).
- `RetryPolicy.kt`: yt-dlp-Stream-URLs **laufen nach wenigen Stunden ab** → die Mod
  cached sie, erneuert sie bei Fehlern und wartet mit exponentiellem Backoff.
  *Das ist übrigens der Grund für den bekannten „Waiting on video"-Bug:
  abgelaufene/geblockte Stream-URL → Cache-Bug → Retry-Schleife.*

### 5. Rendern – keine Entities, pure GPU 🎮
Dateien: `platform/client/common/.../render/` (32 Dateien)

- `GpuFrameUploader` / `AsyncTextureUploader` laden dekodierte Frames
  **asynchron als Textur auf die Grafikkarte**.
- `DisplayYuvRenderTypes.kt` – das Video liegt als **YUV** vor (Videonorm); die
  Umwandlung nach RGB macht ein **Shader direkt auf der GPU** → massiv schneller als CPU.
- `DisplayGeometry.kt` + `RenderHook.kt`: im World-Render-Pass wird **eine einzige
  flache Quad** exakt vor der markierten Blockfläche gezeichnet.
- `LavGlSurfaceTextures.kt`: Rust-Decoder schreibt fast direkt in OpenGL-Texturen.
- **Kein** Armor-Stand-Spam, keine Maps, keine Block-Entities → darum skaliert das
  bis 4K, ohne die Welt auszubremsen.

### 6. Audio – eigene DSP-Engine 🔊
Dateien: `media/audio/`
Kompplett eigener Audio-Stack: **binauraler 3D-Sound** (`ParametricBinaural.kt`),
Hall (`Reverb.kt`), Limiter, Loudness-Meter, Stereo-Panning.
→ Der Sound kommt wirklich „aus der Leinwand", mit Dämpfung über Distanz. Lautstärke bis 200 %.

---

## 🌐 Browser mit uBlock? – Die ehrliche Analyse

**Warum gibt es keinen Ingame-Browser mit Extensions?**
Alle Ingame-Browser (WebDisplays, Client Web Displays, Echo Browser) bauen auf
**MCEF → JCEF → CEF** (Chromium Embedded Framework). CEF im klassischen
„Alloy-Runtime"-Modus **unterstützt keine Chrome-Extensions** – uBlock & Co. laufen
schlicht nicht. (CEF hat seit Neuestem im experimentellen „Chrome-Runtime"-Modus
*teilweisen* Extension-Support, aber kein Minecraft-Mod nutzt den bisher.)

Die drei realistischen Wege, sortiert nach Aufwand:

### Weg A – Extractor statt Browser (empfohlen, habt ihr schon ✅)
Dream Displays' yt-dlp-Kette deckt **viel mehr als YouTube** ab: Twitch, Kick, Vimeo,
Bilibili, direkte MP4/HLS-Links von fast jeder Seite. Werbefrei wie oben erklärt.
**Für 95 % aller Filmabende ist das die Lösung.**

### Weg B – „Echter Browser mit uBlock auf der Leinwand" (Host-Streaming) 🖥️➡️📺
Der Trick: der Browser läuft **auf deinem PC** (Firefox/Chrome **mit** uBlock),
sein Bild wird lokal als Video-Stream ins Spiel gespeist – Dream Displays zeigt ihn an.

```
Firefox (mit uBlock)  →  OBS/ffmpeg (Screen-Capture)  →  lokaler HLS-Stream
→  Dream Displays: "Direkter Video-Link"  →  alle sehen's synchron
```

Konzept-Beispiel mit ffmpeg (Windows, Bildschirmaufnahme in Echtzeit):
```powershell
ffmpeg -f gdigrab -framerate 30 -i desktop -f hls -hls_time 2 -hls_list_size 5 .\stream\index.m3u8
# Stream lokal per Mini-Webserver anbieten, z. B.:  python -m http.server 8090
# In Dream Displays dann:  http://127.0.0.1:8090/stream/index.m3u8
```
⚠️ Bedenken: **Du** steuerst den Browser (alle sehen dein Bild), jeder Client braucht
Zugriff auf deinen lokalen Stream (über LAN oder zusätzlichen playit-TCP-Tunnel für Port 8090),
und der Server-PC encode/decode doppelt. Für „wir schauen zusammen eine Doku von Seite X"
ist das aber **die** Lösung – mit vollem uBlock im echten Browser.

### Weg C – Bastler-Pfad: Browser-Mod selbst patchen 🛠️
Wenn du richtig reingrätschen willst (alles Open Source!):
1. **WebDisplays Revived** (Fabric, aktuell 26.2) + **MCEF** forken.
2. CEF bietet **Request-Interception** (`CefResourceRequestHandler`): Man kann
   HTTP-Anfragen gegen eine Blockliste (z. B. EasyList-Domains, genau die Listen,
   die uBlock nutzt) prüfen und Ads/Tracker **auf Netzwerkebene aborten**.
   → Ergibt „uBlock-Light": Domain-Blocking ja, kosmetisches Filtern (Element-Hiding) nein.
3. Oder MCEF auf CEFs „Chrome Runtime" umstellen und Extensions laden – Pionierarbeit.

Repo-Links zum Selbstbauen: [Dream Displays](https://github.com/arsmotorin/dreamdisplays) ·
[MCEF (CinemaMod-Gruppe)](https://github.com/CinemaMod/mcef) ·
WebDisplays Revived: Suche auf CurseForge.

---

## 🗺️ Einstiegspunkte im Code (wenn du selbst lesen willst)

| Interessiert dich… | Datei(en) |
|---|---|
| Nativer Decoder (Rust) | `native/lav/src/lib.rs`, `session.rs`, `surface.rs` |
| Player-Orchestrierung | `media/player/MediaPlayer.kt` |
| YouTube/yt-dlp-Auflösung | `api/.../media/source/model/MediaSource.kt` |
| Sync-Pakete | `platform/server/.../utils/net/V2Fabric.kt` |
| GPU-Rendering | `platform/client/common/.../render/GpuFrameUploader.kt` |
| 3D-Sound | `media/audio/spatial/ParametricBinaural.kt` |

```bash
git clone https://github.com/arsmotorin/dreamdisplays
# Bauen (braucht JDK + Rust-Toolchain):
./gradlew build
```

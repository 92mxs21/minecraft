# 🍿 Kino-Server (Minecraft 26.3 / Fabric)

Unser Fabric-Server mit kranker Weltgenerierung (Stardust Labs) + Ingame-Kino (Dream Displays),
gehostet lokal über **playit.gg** (kein Port-Forwarding nötig).

## 📚 Doku

| Datei | Inhalt |
|---|---|
| [docs/01-SERVER-MODS-UND-SETUP.md](docs/01-SERVER-MODS-UND-SETUP.md) | **Der Plan:** Welche Mods (Server & Client), Lizenzen/Open-Source, Setup Schritt für Schritt |
| [docs/02-DREAM-DISPLAYS-TECHNIK.md](docs/02-DREAM-DISPLAYS-TECHNIK.md) | **Technik-Deep-Dive:** Wie die Display-Mod innen funktioniert (Rust-Decoder, Sync-Protokoll, YouTube-Trick) + die Wahrheit über Ingame-Browser & uBlock |

## ⚡ Schnellstart

```powershell
# 1. Mods automatisch herunterladen (Windows PowerShell):
.\server\download-mods.ps1            # Server-Mods → .\server\mods\
.\server\download-mods.ps1 -Client    # Client-Mods für die Freunde → .\client-mods\
```

Danach Schritte 2–6 aus [docs/01-SERVER-MODS-UND-SETUP.md](docs/01-SERVER-MODS-UND-SETUP.md) abarbeiten.

## 🧩 Mod-Übersicht (Kurzfassung)

**Server:** Fabric API, Tectonic, Terralith, Incendium, Nullscape, Lithostitched, Lithium, Chunky, Dream Displays
**Client (jeder Spieler):** Fabric API, Dream Displays (+ optional Sodium, Iris, Mod Menu)

> ✅ Alle Welt-Mods sind **rein serverseitig** – Freunde brauchen nur Dream Displays!

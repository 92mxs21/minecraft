# 01 – Server-Modliste & Setup

> Ziel: Minecraft **26.3** (Fabric), lokal gehostet, erreichbar über **playit.gg**.
> Alle Angaben geprüft am 28.09.2026 gegen die Modrinth/CurseForge-Daten.

---

## 1️⃣ Mods für den SERVER (`mods/` im Server-Ordner)

| # | Mod | Zweck | 26.3? | Lizenz | Open Source? |
|---|-----|-------|:-----:|--------|--------------|
| 1 | **Fabric API** | Grundgerüst, braucht fast alles | ✅ | Apache-2.0 | ✅ ja ([GitHub](https://github.com/FabricMC/fabric)) |
| 2 | **Tectonic** | Riesige Berge, tiefe Ozeane, epische Täler | ✅ v3.0.31 | **MIT** | ✅ ja ([GitHub](https://github.com/Apollounknowndev/tectonic)) |
| 3 | **Terralith** | 95+ neue Biome (Skylands, Vulkankrater, Moonlight-Täler …) | ✅ v2.6.5+26.3 | ⚠️ Stardust Labs License | ⚠️ Quellcode offen, eigene Lizenz ([GitHub](https://github.com/Stardust-Labs-MC/Terralith)) |
| 4 | **Incendium** | Nether-Komplettumbau: Biome, Strukturen, Bosse, Items | ✅ v5.5.3+26.3 (Alpha) | ⚠️ Stardust Labs License | ⚠️ Quellcode offen, eigene Lizenz ([GitHub](https://github.com/Stardust-Labs-MC/Incendium)) |
| 5 | **Nullscape** | End-Komplettumbau: surreale Alien-Landschaften, 384 Blöcke hoch | ✅ v2.0.0+26.3 | ⚠️ Stardust Labs License | ⚠️ Quellcode offen, eigene Lizenz ([GitHub](https://github.com/Stardust-Labs-MC/Nullscape)) |
| 6 | **Lithostitched** | Worldgen-Bibliothek – **Pflicht-Dependency von Terralith!** | ✅ | **MIT** | ✅ ja ([GitHub](https://github.com/Apollounknowndev/lithostitched)) |
| 7 | **Lithium** | Server-Performance (Logik-Optimierungen) | ✅ | LGPL-3.0 | ✅ ja ([GitHub](https://github.com/CaffeineMC/lithium)) |
| 8 | **Chunky** | Welt vorab generieren (Anti-Lag beim Erkunden) | ✅ | GPL-3.0 | ✅ ja ([GitHub](https://github.com/pop4959/Chunky)) |
| 9 | **Dream Displays** | Ingame-Kino / Video-Screens (Server-Teil) | ✅ 1.10.0 | LGPL-3.0 | ✅ ja ([GitHub](https://github.com/arsmotorin/dreamdisplays)) |

### 🔑 Zur Lizenz-Frage („Ist das Open Source?")

- **Echtes Open Source (OSI):** Tectonic, Lithostitched (MIT), Fabric API (Apache-2.0), Lithium & Dream Displays (LGPL-3.0), Chunky (GPL-3.0).
- **„Source-Available" (Code einsehbar, aber eingeschränkte Lizenz):** Terralith, Incendium, Nullscape laufen unter der **Stardust Labs License**:
  - ✅ Erlaubt: auf eigenem Server benutzen (auch öffentlich & modifiziert), Code **ansehen und daraus lernen**, unverändert in Modpacks mit Credit + Link.
  - ❌ Verboten: Reupload/Weiterverbreitung (auch modifiziert), Code-Teile in eigene Projekte kopieren, **Verwendung für KI-Training** (explizit ausgeschlossen).
  - Also: für euren Server komplett unbedenklich – nur nicht weiterverbreiten.
- **Sodium** (optional, Client) ist „PolyForm Shield": Quellcode offen & veränderbar, aber kein OSI-Open-Source (Wettbewerbsklausel). Für normale Nutzung egal.

---

## 2️⃣ Mods für die CLIENTS (jeder Spieler)

| Mod | Pflicht? | Warum |
|-----|:--------:|-------|
| **Fabric Loader 26.3** | ✅ | statt Vanilla-Launcher-Profil |
| **Fabric API** | ✅ | Dependency |
| **Dream Displays** | ✅ | sonst sieht man die Screens nicht! |
| **Sodium** | empfohlen | deutlich mehr FPS bei der fetteren Welt |
| **Iris + Shader** | optional | erst richtig hübsch (z. B. *Complementary*, *Bliss*) |
| **Mod Menu** | optional | komfortable Mod-Liste/Configs |

> 💡 **Wichtig:** Tectonic/Terralith/Incendium/Nullscape sind **rein serverseitig**
> (`server_only` – nur Vanilla-Blöcke). Die Freunde müssen davon **nichts** installieren!

---

## 3️⃣ Setup Schritt für Schritt

### Schritt 1 – Java 25 installieren
Minecraft 26.3 braucht **Java 25 oder neuer** → z. B. [Adoptium Temurin 25](https://adoptium.net/).

### Schritt 2 – Fabric-Server bauen
1. Fabric Installer laden: <https://fabricmc.net/use/server/>
2. **Minecraft 26.3** + aktuellen Installer auswählen → „Server" installieren in einen leeren Ordner, z. B. `C:\minecraft-server\`
3. Ersten Start: `fabric-server-launch.jar` → erzeugt `eula.txt` → dort `eula=true` setzen.

### Schritt 3 – Mods herunterladen
```powershell
cd C:\minecraft-server
powershell -ExecutionPolicy Bypass -File <repo>\server\download-mods.ps1
```
→ lädt automatisch die **neueste 26.3-Fabric-Build** jeder Server-Mod nach `.\mods\`.

### Schritt 4 – `server.properties` (empfohlene Werte)
```properties
motd=§6Kino-Server §7| §bWilderness Bound
view-distance=10
simulation-distance=8
online-mode=true
network-compression-threshold=256
```
> `online-mode=true` lassen – playit braucht keinen Offline-Mode! Damit können sich nur
> Accounts mit gekauftem Minecraft einloggen (Sicherheit).

### Schritt 5 – 🌍 NEUE WELT generieren lassen & Vorgenerieren
⚠️ **Unbedingt eine frische Welt mit den Mods erstellen!**
Terralith kann **nicht** nachträglich hinzugefügt und **niemals wieder entfernt** werden.
Server starten → Welt entsteht mit allen Biomen → dann in der Konsole:
```
chunky center 0 0
chunky radius 2000
chunky start
```
→ generiert 2000 Blöcke Umkreis vorab (dauert mit Terralith+Tectonic gern 1–2 Stunden,
danach kein Generierungs-Lag mehr beim Erkunden – wichtig auf einem Heim-PC!).

### Schritt 6 – playit.gg-Tunnel
1. playit-Programm auf dem Server-PC starten (Agent läuft dauerhaft).
2. Tunnel anlegen: **Minecraft Java (TCP)** → lokaler Port `25565`.
3. playit zeigt dir die öffentliche Adresse (z. B. `xyz.at.ply.gg:12345`) → **das** schickst du deinen Freunden.
4. Mods sind dem Tunnel völlig egal – es läuft normales Minecraft-Protokoll durch. Keine Extra-Config.

### Schritt 7 – Freunde einladen
Jeder Freund:
1. Minecraft 26.3 + **Fabric Loader** installieren (fabricmc.net → „Install Fabric").
2. `download-mods.ps1 -Client` ausführen (oder manuell: Fabric API + Dream Displays in `.minecraft/mods`).
3. Multiplayer → playit-Adresse rein → fertig. 🍿

---

## ⚠️ Bekannte Fallen

| Falle | Lösung |
|------|--------|
| **Terralith + Tectonic als „Mod"-Versionen nutzen** | Stimmt so (offiziell kompatibel). Das Datapack **Terratonic** braucht man nur bei *Datapack*-Installation! |
| **Lithostitched vergessen** | Terralith startet nicht → immer mit in `mods/`! |
| **Incendium = noch Alpha f. 26.3** | Bei Crashes: v5.5.2 probieren oder im Stardust-Discord melden. |
| **Welt nach Wochen Mod reingeworfen** | Chunk-Kanten/Weltbruch → immer neue Welt! |
| **„Waiting on video" am Screen** | Betrifft Dream Displays nach YouTube-Änderungen → Mod-Update abwarten oder Link neu setzen (Details in Doku 02). |
| **Dream Displays Client vergessen** | Spieler sieht schwarze Wand statt Video. |

## 📌 Update-Strategie
- `download-mods.ps1` einfach erneut ausführen → holt jeweils die neueste 26.3-Build.
- Client-Mods (Dream Displays!) beim Update **mit den Freunden synchron halten**.

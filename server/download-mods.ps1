#Requires -Version 5.1
<#
.SYNOPSIS
  Lädt automatisch die neuesten Fabric-Mod-Builds für Minecraft 26.3 von Modrinth.

.DESCRIPTION
  Standard: Server-Mods nach .\server\mods\
  Mit -Client: Client-Mods nach .\client-mods\ (für deine Freunde)

.EXAMPLE
  .\download-mods.ps1            # Server-Mods
  .\download-mods.ps1 -Client    # Client-Mods
  .\download-mods.ps1 -GameVersion "26.2"   # andere MC-Version
#>
param(
    [switch]$Client,
    [string]$GameVersion = "26.3"
)

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── Mod-Listen ──────────────────────────────────────────────────────────────
$ServerMods = @(
    "fabric-api"      # Grundgerüst
    "tectonic"        # Mega-Berge & Terrainformen
    "lithostitched"   # Pflicht-Dependency für Terralith
    "terralith"       # 95+ Biome
    "incendium"       # Nether-Overhaul
    "nullscape"       # End-Overhaul
    "lithium"         # Server-Performance
    "chunky"          # Welt-Vorgenerierung
    "dreamdisplays"   # Kino-Screens (Server-Teil)
)
$ClientMods = @(
    "fabric-api"
    "dreamdisplays"   # Muss bei JEDEM Spieler installiert sein!
    "sodium"          # FPS-Boost (optional)
    "iris"            # Shader-Support (optional)
    "modmenu"         # Mod-Übersicht im Spiel (optional)
)

$mods  = if ($Client) { $ClientMods } else { $ServerMods }
$OutDir = if ($Client) { "client-mods" } else { Join-Path "server" "mods" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host ""
Write-Host "=== Kino-Server Mod-Downloader ===" -ForegroundColor Cyan
Write-Host "Minecraft $GameVersion / Fabric  →  $OutDir" -ForegroundColor Cyan
if ($Client) { Write-Host "(Client-Paket für deine Freunde)" -ForegroundColor Yellow }
Write-Host ""

$headers = @{ "User-Agent" = "kino-server-setup/1.0 (lokaler Privatserver)" }
$ok = 0; $failed = @()

foreach ($slug in $mods) {
    try {
        $apiUrl = "https://api.modrinth.com/v2/project/$slug/version" +
                  "?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$GameVersion%22%5D"
        $versions = Invoke-RestMethod -Uri $apiUrl -Headers $headers

        if (-not $versions -or $versions.Count -eq 0) {
            Write-Warning "$slug – keine Fabric-Version für $GameVersion gefunden (übersprungen)"
            $failed += "$slug (nicht verfügbar)"
            continue
        }

        $latest = $versions | Sort-Object { [datetime]$_.date_published } -Descending | Select-Object -First 1
        $file = $latest.files | Where-Object { $_.primary } | Select-Object -First 1
        if (-not $file) { $file = $latest.files[0] }

        $target = Join-Path $OutDir $file.filename
        if (Test-Path $target) {
            Write-Host "✔ $slug – schon aktuell ($($file.filename))" -ForegroundColor DarkGray
        } else {
            Invoke-WebRequest -Uri $file.url -OutFile $target -Headers $headers
            $size = "{0:N1} MB" -f ((Get-Item $target).Length / 1MB)
            Write-Host "✔ $slug $($latest.version_number) – $size" -ForegroundColor Green
        }
        $ok++
    }
    catch {
        Write-Warning "$slug – Download fehlgeschlagen: $($_.Exception.Message)"
        $failed += "$slug (Fehler)"
    }
}

Write-Host ""
Write-Host "Fertig: $ok/$($mods.Count) Mods in '$OutDir'" -ForegroundColor Cyan
if ($failed.Count -gt 0) {
    Write-Host "Übersprungen/Fehler:" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "→ Prüfe manuell auf https://modrinth.com, ob es schon eine $GameVersion-Version gibt." -ForegroundColor Yellow
}

if ($Client) {
    Write-Host ""
    Write-Host "So installieren deine Freunde:" -ForegroundColor Green
    Write-Host "  1. Fabric Loader für $GameVersion installieren (https://fabricmc.net/use/installer/)"
    Write-Host "  2. Inhalt von 'client-mods' nach %APPDATA%\.minecraft\mods kopieren"
    Write-Host "  3. Spiel starten, Multiplayer, playit-Adresse eintragen. Viel Spaß!"
}

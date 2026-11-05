# WoW Forever Kit installer. Windows PowerShell 5.1, run by Install.bat.
#
# Downloads the newest Forever build of each addon in addons.tsv from its
# author's release, and replaces only those addon folders. It never touches
# WTF, where settings live. A pinned file in addons.tsv covers a failed lookup.
#
# WOW_KIT_ADDONS overrides the target AddOns folder.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms

$Raw = 'https://raw.githubusercontent.com/jackisgolden/wow-forever-kit/main'
$Agent = 'wow-forever-kit'
$Flavor = '1.60.1'

function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }

function Find-Forever {
    $bases = New-Object System.Collections.ArrayList
    $key = 'HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft'
    $reg = (Get-ItemProperty $key -ErrorAction SilentlyContinue).InstallPath
    if ($reg) {
        $reg = $reg.TrimEnd('\')
        if ((Split-Path $reg -Leaf) -like '_*_') { $reg = Split-Path $reg -Parent }
        [void]$bases.Add($reg)
    }
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem).Root) {
        foreach ($sub in 'Program Files (x86)', 'Program Files', 'Games', '') {
            [void]$bases.Add((Join-Path (Join-Path $drive $sub) 'World of Warcraft'))
        }
    }
    foreach ($base in $bases) {
        $dir = Join-Path $base '_forever_'
        if (Test-Path $dir) { return $dir }
    }
    Say 'Could not find WoW Forever. Pick your "World of Warcraft" folder in the window that opened.' Yellow
    $picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description = 'Pick your World of Warcraft folder'
    if ($picker.ShowDialog() -eq 'OK') {
        $dir = Join-Path $picker.SelectedPath '_forever_'
        if (Test-Path $dir) { return $dir }
    }
    return $null
}

function Get-CurseFile($row) {
    try {
        $project = Invoke-RestMethod -UseBasicParsing -UserAgent $Agent -TimeoutSec 60 "https://api.cfwidget.com/$($row.id)"
        $file = $project.files |
            Where-Object { $_.type -eq 'release' -and $_.versions -contains $Flavor } |
            Sort-Object uploaded_at -Descending |
            Select-Object -First 1
        if ($file) { return @{ id = [string]$file.id; name = $file.name } }
    } catch { }
    return @{ id = $row.pin; name = $row.file }
}

function Get-Url($row) {
    if ($row.source -eq 'github') {
        try {
            $rel = Invoke-RestMethod -UseBasicParsing -UserAgent $Agent -TimeoutSec 60 "https://api.github.com/repos/$($row.id)/releases/latest"
            $asset = $rel.assets | Where-Object { $_.name -eq $row.file } | Select-Object -First 1
            if ($asset) { return $asset.browser_download_url }
        } catch { }
        return "https://github.com/$($row.id)/releases/download/$($row.pin)/$($row.file)"
    }
    $file = Get-CurseFile $row
    $head = $file.id.Substring(0, 4)
    $tail = [int]$file.id.Substring(4)
    return "https://mediafilez.forgecdn.net/files/$head/$tail/$([uri]::EscapeDataString($file.name))"
}

Say ''
Say 'WoW Forever Kit' Cyan
Say ''

$addons = $env:WOW_KIT_ADDONS
if (-not $addons) {
    $game = Find-Forever
    if (-not $game) {
        Say 'WoW Forever was not found, so nothing changed. Install it from Battle.net and run this again.' Red
        return
    }
    $addons = Join-Path $game 'Interface\AddOns'
    while (Get-Process -Name Wow -ErrorAction SilentlyContinue) {
        Say 'WoW is open. Close it completely, then press Enter here.' Yellow
        [void](Read-Host)
    }
}
Say "Installing to $addons"
Say ''

try {
    New-Item -ItemType Directory -Force -Path $addons | Out-Null
    $probe = Join-Path $addons '.kit-write-test'
    Set-Content -Path $probe -Value 'ok'
    Remove-Item $probe
} catch {
    Say 'Windows would not let me write to that folder. Right-click Install.bat and pick "Run as administrator".' Red
    return
}

$list = (Invoke-WebRequest -UseBasicParsing -UserAgent $Agent "$Raw/addons.tsv").Content
$rows = $list | ConvertFrom-Csv -Delimiter "`t"

$work = Join-Path $env:TEMP ("wow-forever-kit-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
$retired = 'AtlasBIStooltips', 'AtlasLootClassic', 'AtlasLootClassic_Collections', 'AtlasLootClassic_Crafting',
    'AtlasLootClassic_Data', 'AtlasLootClassic_DungeonsAndRaids', 'AtlasLootClassic_Factions', 'AtlasLootClassic_Options',
    'AtlasLootClassic_PvP', 'Details', 'Details_Compare2', 'Details_DataStorage', 'Details_EncounterDetails',
    'Details_RaidCheck', 'Details_Streamer', 'Details_TinyThreat', 'Details_Vanguard', 'GatherMate2', 'GatherMate2_Data',
    'GatherMate2Storage_Dragonflight', 'GatherMate2Storage_Midnight', 'GatherMate2Storage_TheWarWithin',
    'GuideLime_TUGs_Forever', 'Guidelime', 'Leatrix_Maps', 'Prat-3.0', 'Safeguard', 'WeaponSwingTimer',
    'unitscan', 'unitscanAON', 'unitscanData', 'unitscanIntegrity'
foreach ($name in $retired) {
    $old = Join-Path $addons $name
    if (Test-Path $old) { Remove-Item -Recurse -Force $old }
}
$failed = New-Object System.Collections.ArrayList
$n = 0
try {
    foreach ($row in $rows) {
        $n++
        Write-Host ("[{0}/{1}] {2} ... " -f $n, $rows.Count, $row.name) -NoNewline
        try {
            $zip = Join-Path $work "$n.zip"
            $out = Join-Path $work "$n"
            Invoke-WebRequest -UseBasicParsing -UserAgent $Agent -TimeoutSec 300 -Uri (Get-Url $row) -OutFile $zip
            [IO.Compression.ZipFile]::ExtractToDirectory($zip, $out)
            foreach ($dir in Get-ChildItem -Path $out -Directory) {
                $dest = Join-Path $addons $dir.Name
                if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
                Copy-Item -Recurse -Path $dir.FullName -Destination $dest
            }
            Say 'done' Green
        } catch {
            Say 'FAILED' Red
            [void]$failed.Add($row.name)
        }
    }
    $kit = Join-Path $addons '!ForeverKit'
    New-Item -ItemType Directory -Force -Path $kit | Out-Null
    foreach ($name in '!ForeverKit.toc', 'Layout.lua', 'Config.lua', 'ForeverKit.lua') {
        Invoke-WebRequest -UseBasicParsing -UserAgent $Agent -Uri "$Raw/!ForeverKit/$name" -OutFile (Join-Path $kit $name)
    }
    $personal = Join-Path $kit 'Personal.lua'
    if (-not (Test-Path $personal)) { Set-Content -Path $personal -Value '-- Your own overrides.' }
} finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}

Say ''
if ($failed.Count) {
    Say ("{0} of {1} installed. These failed: {2}" -f ($rows.Count - $failed.Count), $rows.Count, ($failed -join ', ')) Yellow
    Say 'Run this again. A second try usually gets them.' Yellow
} else {
    Say "All $($rows.Count) installed. Start WoW." Green
}

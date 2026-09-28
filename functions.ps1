# ============================================
# WINDOWS SETUP MANAGER - FUNKTIOT
# ============================================

$Script:ProjectRoot = $PSScriptRoot

$configPath = Join-Path $Script:ProjectRoot "config.json"

try {
    $globalConfig = Get-Content $configPath -Raw -ErrorAction Stop |
        ConvertFrom-Json
}
catch {
    Write-Host "config.json lukeminen epaonnistui." -ForegroundColor Red
    exit 1
}

$Script:ProfilesDir = Join-Path `
    $Script:ProjectRoot `
    $globalConfig.profiles_folder

$Script:LogFile = Join-Path `
    $Script:ProjectRoot `
    $globalConfig.log_file

$Script:LogDir = Split-Path $Script:LogFile


# ============================================
# LOKITUS
# ============================================

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    try {
        if (-not (Test-Path $Script:LogDir)) {
            New-Item `
                -ItemType Directory `
                -Path $Script:LogDir `
                -Force |
                Out-Null
        }

        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        "$time [$Level] $Message" |
            Add-Content -Path $Script:LogFile
    }
    catch {
        Write-Host "Lokikirjoitus epaonnistui." -ForegroundColor Red
    }
}


# ============================================
# PROFIILIN LUKEMINEN
# ============================================

function Get-ProfileConfig {
    param (
        [string]$ProfileName
    )

    try {
        $path = Join-Path `
            $Script:ProfilesDir `
            "$ProfileName.json"

        if (-not (Test-Path $path)) {
            throw "Profiilia ei loytynyt: $path"
        }

        return Get-Content $path -Raw |
            ConvertFrom-Json
    }
    catch {
        Write-Host `
            "Profiilin lukeminen epaonnistui: $($_.Exception.Message)" `
            -ForegroundColor Red

        Write-Log `
            "Profiilin lukeminen epaonnistui: $($_.Exception.Message)" `
            "ERROR"

        return $null
    }
}


function Expand-AppPath {
    param (
        [string]$Path
    )

    return [Environment]::ExpandEnvironmentVariables($Path)
}


# ============================================
# CHROME
# ============================================

function Get-ChromePath {

    $paths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}


# ============================================
# OHJELMAN KAYNNISTYS
# ============================================

function Start-ProfileApp {
    param (
        $App
    )

    try {
        if ($App.ProcessName) {

            $running = Get-Process `
                -Name $App.ProcessName `
                -ErrorAction SilentlyContinue

            if ($running) {
                Write-Host `
                    "$($App.Name) on jo kaynnissa." `
                    -ForegroundColor Yellow

                Write-Log "$($App.Name) oli jo kaynnissa"

                return
            }
        }

        $path = Expand-AppPath $App.Path

        if (-not (Test-Path $path)) {

            Write-Host `
                "$($App.Name) ei loytynyt: $path" `
                -ForegroundColor Yellow

            Write-Log `
                "$($App.Name) ei loytynyt: $path" `
                "WARNING"

            return
        }

        if ($App.Arguments) {

            Start-Process `
                -FilePath $path `
                -ArgumentList $App.Arguments `
                -ErrorAction Stop
        }
        else {

            Start-Process `
                -FilePath $path `
                -ErrorAction Stop
        }

        Write-Host `
            "$($App.Name) kaynnistetty." `
            -ForegroundColor Green

        Write-Log "$($App.Name) kaynnistetty"
    }
    catch {

        Write-Host `
            "$($App.Name) kaynnistys epaonnistui." `
            -ForegroundColor Red

        Write-Log `
            "$($App.Name) kaynnistys epaonnistui: $($_.Exception.Message)" `
            "ERROR"
    }
}


# ============================================
# VERKKOSIVUN AVAAMINEN
# ============================================

function Start-ProfileWebsite {
    param (
        $Website
    )

    try {
        $chromePath = Get-ChromePath

        if (-not $chromePath) {
            throw "Google Chromea ei loytynyt."
        }

        # Tukee seka uusia Name/Url-objekteja
        # etta vanhoja pelkkia URL-merkkijonoja.
        if ($Website -is [string]) {
            $name = $Website
            $url = $Website
        }
        else {
            $name = $Website.Name
            $url = $Website.Url
        }

        Start-Process `
            -FilePath $chromePath `
            -ArgumentList $url `
            -ErrorAction Stop

        Write-Host `
            "$name avattu Chromessa." `
            -ForegroundColor Green

        Write-Log `
            "$name avattu Chromessa: $url"
    }
    catch {

        Write-Host `
            "Verkkosivun avaaminen epaonnistui: $($_.Exception.Message)" `
            -ForegroundColor Red

        Write-Log `
            "Verkkosivun avaaminen epaonnistui: $($_.Exception.Message)" `
            "ERROR"
    }
}


# ============================================
# KANSION AVAAMINEN
# ============================================

function Start-ProfileFolder {
    param (
        [string]$Folder
    )

    try {
        $expandedFolder = Expand-AppPath $Folder

        if (-not (Test-Path $expandedFolder)) {
            throw "Kansiota ei loytynyt: $expandedFolder"
        }

        Start-Process `
            explorer.exe `
            -ArgumentList $expandedFolder

        Write-Host `
            "Kansio avattu: $expandedFolder" `
            -ForegroundColor Green

        Write-Log `
            "Kansio avattu: $expandedFolder"
    }
    catch {

        Write-Host `
            $_.Exception.Message `
            -ForegroundColor Yellow

        Write-Log `
            $_.Exception.Message `
            "WARNING"
    }
}


# ============================================
# KOKO PROFIILIN KAYNNISTYS
# ============================================

function Start-Profile {
    param (
        [string]$ProfileName
    )

    $profile = Get-ProfileConfig $ProfileName

    if ($null -eq $profile) {
        return
    }

    Write-Log "Profiili $($profile.Name) kaynnistetaan"

    foreach ($app in $profile.Apps) {
        Start-ProfileApp $app
    }

    foreach ($website in $profile.Websites) {
        Start-ProfileWebsite $website
    }

    foreach ($folder in $profile.Folders) {
        Start-ProfileFolder $folder
    }

    Write-Host ""
    Write-Host "Kaikki kaynnistetty!" -ForegroundColor Green

    Write-Log "Profiili $($profile.Name) kaynnistetty"
}


# ============================================
# PROFIILIN ALAVALIKKO
# ============================================

function Show-ProfileMenu {
    param (
        [string]$ProfileName
    )

    $profile = Get-ProfileConfig $ProfileName

    if ($null -eq $profile) {
        return
    }

    while ($true) {

        Clear-Host

        Write-Host "========================================="
        Write-Host "          $($profile.Name.ToUpper())"
        Write-Host "========================================="
        Write-Host ""

        $items = @()

        # Lisataan ohjelmat valikkoon
        foreach ($app in $profile.Apps) {

            $items += [PSCustomObject]@{
                Type = "App"
                Name = $app.Name
                Data = $app
            }
        }

        # Lisataan verkkosivut valikkoon
        foreach ($website in $profile.Websites) {

            if ($website -is [string]) {
                $name = $website
            }
            else {
                $name = $website.Name
            }

            $items += [PSCustomObject]@{
                Type = "Website"
                Name = $name
                Data = $website
            }
        }

        # Lisataan kansiot valikkoon
        foreach ($folder in $profile.Folders) {

            $items += [PSCustomObject]@{
                Type = "Folder"
                Name = "Avaa kansio: $folder"
                Data = $folder
            }
        }

        $index = 1

        foreach ($item in $items) {
            Write-Host "$index. $($item.Name)"
            $index++
        }

        $allChoice = $index
        Write-Host "$allChoice. Kaynnista kaikki"

        $index++

        $backChoice = $index
        Write-Host "$backChoice. Takaisin"

        Write-Host ""

        $choice = Read-Host "Valitse toiminto"

        if ($choice -notmatch '^\d+$') {
            Write-Host "Anna numero." -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }

        $number = [int]$choice

        if ($number -ge 1 -and $number -le $items.Count) {

            $selected = $items[$number - 1]

            switch ($selected.Type) {

                "App" {
                    Start-ProfileApp $selected.Data
                }

                "Website" {
                    Start-ProfileWebsite $selected.Data
                }

                "Folder" {
                    Start-ProfileFolder $selected.Data
                }
            }

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        elseif ($number -eq $allChoice) {

            Start-Profile $ProfileName

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        elseif ($number -eq $backChoice) {

            break
        }

        else {

            Write-Host `
                "Virheellinen valinta." `
                -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }
}


# ============================================
# OHJELMIEN TILAN TARKISTUS
# ============================================

function Show-ProgramStatus {

    Clear-Host

    Write-Host "OHJELMIEN TILA" -ForegroundColor Cyan
    Write-Host "-----------------------------------------"
    Write-Host ""

    try {

        $files = Get-ChildItem `
            "$Script:ProfilesDir\*.json" `
            -ErrorAction Stop

        $apps = @()

        foreach ($file in $files) {

            $profile = Get-Content `
                $file.FullName `
                -Raw |
                ConvertFrom-Json

            foreach ($app in $profile.Apps) {

                if ($app.ProcessName) {

                    $apps += [PSCustomObject]@{
                        Name = $app.Name
                        ProcessName = $app.ProcessName
                    }
                }
            }
        }

        $apps = $apps |
            Sort-Object ProcessName -Unique

        foreach ($app in $apps) {

            $running = Get-Process `
                -Name $app.ProcessName `
                -ErrorAction SilentlyContinue

            if ($running) {

                Write-Host `
                    "$($app.Name) : KAYNNISSA" `
                    -ForegroundColor Green
            }
            else {

                Write-Host `
                    "$($app.Name) : EI KAYNNISSA" `
                    -ForegroundColor DarkGray
            }
        }

        Write-Log "Ohjelmien tila tarkistettu"
    }
    catch {

        Write-Host `
            "Tilatarkistus epaonnistui." `
            -ForegroundColor Red

        Write-Log `
            "Tilatarkistus epaonnistui: $($_.Exception.Message)" `
            "ERROR"
    }
}


# ============================================
# LOKIN NAYTTO
# ============================================

function Show-Log {

    Clear-Host

    Write-Host "LOKI" -ForegroundColor Cyan
    Write-Host "-----------------------------------------"
    Write-Host ""

    if (Test-Path $Script:LogFile) {

        Get-Content `
            $Script:LogFile `
            -Tail 30
    }
    else {

        Write-Host "Lokia ei ole viela luotu."
    }
}
# ============================================
# WINDOWS SETUP MANAGER - YHTEISET FUNKTIOT
# ============================================

# Projektin juurikansio
$Script:ProjectRoot = $PSScriptRoot


# ============================================
# LUETAAN YLEINEN CONFIG.JSON
# ============================================

try {
    $configPath = Join-Path $Script:ProjectRoot "config.json"

    if (-not (Test-Path $configPath)) {
        throw "config.json tiedostoa ei loytynyt."
    }

    $globalConfig = Get-Content $configPath -Raw -ErrorAction Stop |
        ConvertFrom-Json
}
catch {
    Write-Host "Virhe config.json tiedoston lukemisessa:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}


# Profiilien kansio config.json tiedostosta
$Script:ProfilesDir = Join-Path `
    $Script:ProjectRoot `
    $globalConfig.profiles_folder


# Lokitiedosto config.json tiedostosta
$Script:LogFile = Join-Path `
    $Script:ProjectRoot `
    $globalConfig.log_file


# Lokikansio
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
            Add-Content `
                -Path $Script:LogFile `
                -ErrorAction Stop
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
            throw "Profiilitiedostoa ei loytynyt: $path"
        }

        $content = Get-Content `
            $path `
            -Raw `
            -ErrorAction Stop

        return $content | ConvertFrom-Json
    }
    catch {
        Write-Host `
            "Profiilin lukeminen epaonnistui: $($_.Exception.Message)" `
            -ForegroundColor Red

        Write-Log `
            "Profiilin $ProfileName lukeminen epaonnistui: $($_.Exception.Message)" `
            "ERROR"

        return $null
    }
}


# ============================================
# YMPARISTOMUUTTUJIEN LAAJENNUS
# ============================================

function Expand-AppPath {
    param (
        [string]$Path
    )

    return [Environment]::ExpandEnvironmentVariables($Path)
}


# ============================================
# YHDEN OHJELMAN KAYNNISTYS
# ============================================

function Start-ProfileApp {
    param (
        $App
    )

    try {

        # Tarkistetaan onko ohjelma jo kaynnissa
        if ($App.ProcessName) {

            $running = Get-Process `
                -Name $App.ProcessName `
                -ErrorAction SilentlyContinue

            if ($running) {

                Write-Host `
                    "$($App.Name) on jo kaynnissa." `
                    -ForegroundColor Yellow

                Write-Log `
                    "$($App.Name) oli jo kaynnissa"

                return
            }
        }


        # Laajennetaan esim. %LOCALAPPDATA%
        $path = Expand-AppPath $App.Path


        # Tarkistetaan loytyyko ohjelma
        if (-not (Test-Path $path)) {

            Write-Host `
                "$($App.Name) ei loytynyt: $path" `
                -ForegroundColor Yellow

            Write-Log `
                "$($App.Name) ei loytynyt polusta $path" `
                "WARNING"

            return
        }


        # Kaynnistetaan ohjelma
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

        Write-Log `
            "$($App.Name) kaynnistetty"
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
# GOOGLE CHROME -POLUN ETSINTA
# ============================================

function Get-ChromePath {

    $chromePaths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )


    foreach ($path in $chromePaths) {

        if (Test-Path $path) {
            return $path
        }
    }


    return $null
}


# ============================================
# PROFIILIN KAYNNISTYS
# ============================================

function Start-Profile {
    param (
        [string]$ProfileName
    )

    try {

        $profile = Get-ProfileConfig $ProfileName


        if ($null -eq $profile) {
            return
        }


        Write-Host ""

        Write-Host `
            "Kaynnistetaan profiili: $($profile.Name)" `
            -ForegroundColor Cyan


        Write-Log `
            "Profiili $($profile.Name) kaynnistetaan"


        # ====================================
        # OHJELMAT
        # ====================================

        foreach ($app in $profile.Apps) {

            Start-ProfileApp $app
        }


        # ====================================
        # VERKKOSIVUT GOOGLE CHROMESSA
        # ====================================

        $chromePath = Get-ChromePath


        foreach ($website in $profile.Websites) {

            try {

                if ($chromePath) {

                    Start-Process `
                        -FilePath $chromePath `
                        -ArgumentList $website `
                        -ErrorAction Stop


                    Write-Host `
                        "Avattu Chromessa: $website"


                    Write-Log `
                        "Verkkosivu avattu Chromessa: $website"
                }
                else {

                    Write-Host `
                        "Google Chromea ei loytynyt." `
                        -ForegroundColor Red


                    Write-Log `
                        "Google Chromea ei loytynyt" `
                        "ERROR"
                }
            }
            catch {

                Write-Host `
                    "Verkkosivun avaaminen epaonnistui." `
                    -ForegroundColor Red


                Write-Log `
                    "Verkkosivun avaaminen epaonnistui: $website - $($_.Exception.Message)" `
                    "ERROR"
            }
        }


        # ====================================
        # KANSIOT
        # ====================================

        foreach ($folder in $profile.Folders) {

            try {

                $expandedFolder = Expand-AppPath $folder


                if (Test-Path $expandedFolder) {

                    Start-Process `
                        explorer.exe `
                        -ArgumentList $expandedFolder `
                        -ErrorAction Stop


                    Write-Host `
                        "Kansio avattu: $expandedFolder"


                    Write-Log `
                        "Kansio avattu: $expandedFolder"
                }
                else {

                    Write-Host `
                        "Kansiota ei loytynyt: $expandedFolder" `
                        -ForegroundColor Yellow


                    Write-Log `
                        "Kansiota ei loytynyt: $expandedFolder" `
                        "WARNING"
                }
            }
            catch {

                Write-Host `
                    "Kansion avaaminen epaonnistui." `
                    -ForegroundColor Red


                Write-Log `
                    "Kansion avaaminen epaonnistui: $folder - $($_.Exception.Message)" `
                    "ERROR"
            }
        }


        Write-Host ""

        Write-Host `
            "Profiili kaynnistetty!" `
            -ForegroundColor Green


        Write-Log `
            "Profiili $($profile.Name) kaynnistetty"
    }
    catch {

        Write-Host `
            "Profiilin kaynnistyksessa tapahtui virhe." `
            -ForegroundColor Red


        Write-Log `
            "Profiilin kaynnistyksessa tapahtui virhe: $($_.Exception.Message)" `
            "ERROR"
    }
}


# ============================================
# PROFIILIN OHJELMIEN SULKEMINEN
# ============================================

function Stop-Profile {
    param (
        [string]$ProfileName
    )

    try {

        $profile = Get-ProfileConfig $ProfileName


        if ($null -eq $profile) {
            return
        }


        Write-Host ""

        Write-Host `
            "Suljetaan profiilin ohjelmia..." `
            -ForegroundColor Cyan


        foreach ($processName in $profile.StopProcesses) {

            try {

                $process = Get-Process `
                    -Name $processName `
                    -ErrorAction SilentlyContinue


                if ($process) {

                    $process |
                        Stop-Process `
                            -Force `
                            -ErrorAction Stop


                    Write-Host `
                        "$processName suljettu." `
                        -ForegroundColor Green


                    Write-Log `
                        "Prosessi $processName suljettu"
                }
                else {

                    Write-Host `
                        "$processName ei ollut kaynnissa."
                }
            }
            catch {

                Write-Host `
                    "$processName sulkeminen epaonnistui." `
                    -ForegroundColor Red


                Write-Log `
                    "$processName sulkeminen epaonnistui: $($_.Exception.Message)" `
                    "ERROR"
            }
        }
    }
    catch {

        Write-Log `
            "Profiilin sulkeminen epaonnistui: $($_.Exception.Message)" `
            "ERROR"
    }
}


# ============================================
# OHJELMIEN TILAN TARKISTUS
# ============================================

function Show-ProgramStatus {

    Write-Host ""

    Write-Host `
        "OHJELMIEN TILA" `
        -ForegroundColor Cyan

    Write-Host "-----------------------------"


    try {

        $files = Get-ChildItem `
            "$Script:ProfilesDir\*.json" `
            -ErrorAction Stop


        $processNames = @()


        foreach ($file in $files) {

            $profile = Get-Content `
                $file.FullName `
                -Raw |
                ConvertFrom-Json


            foreach ($app in $profile.Apps) {

                if ($app.ProcessName) {

                    $processNames += $app.ProcessName
                }
            }
        }


        $processNames = $processNames |
            Sort-Object -Unique


        foreach ($processName in $processNames) {

            $running = Get-Process `
                -Name $processName `
                -ErrorAction SilentlyContinue


            if ($running) {

                Write-Host `
                    "$processName : KAYNNISSA" `
                    -ForegroundColor Green
            }
            else {

                Write-Host `
                    "$processName : EI KAYNNISSA" `
                    -ForegroundColor DarkGray
            }
        }


        Write-Log `
            "Ohjelmien tila tarkistettu"
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
# LOKIN NAYTTAMINEN
# ============================================

function Show-Log {

    Write-Host ""

    Write-Host `
        "LOKI" `
        -ForegroundColor Cyan

    Write-Host "-----------------------------"


    if (Test-Path $Script:LogFile) {

        Get-Content `
            $Script:LogFile `
            -Tail 20
    }
    else {

        Write-Host `
            "Lokia ei ole viela luotu."
    }
}
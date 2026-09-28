# Projektin juurikansio
$Script:ProjectRoot = $PSScriptRoot

$Script:ConfigDir = Join-Path $Script:ProjectRoot "config"
$Script:LogDir = Join-Path $Script:ProjectRoot "logs"
$Script:LogFile = Join-Path $Script:LogDir "launcher.log"


function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    if (-not (Test-Path $Script:LogDir)) {
        New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
    }

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$time [$Level] $Message" |
        Add-Content -Path $Script:LogFile
}


function Get-ProfileConfig {
    param (
        [string]$ProfileName
    )

    try {
        $path = Join-Path $Script:ConfigDir "$ProfileName.json"

        if (-not (Test-Path $path)) {
            throw "Profiilitiedostoa ei loytynyt: $path"
        }

        $content = Get-Content $path -Raw -ErrorAction Stop

        return $content | ConvertFrom-Json
    }
    catch {
        Write-Host "Profiilin lukeminen epaonnistui: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Profiilin $ProfileName lukeminen epaonnistui: $($_.Exception.Message)" "ERROR"

        return $null
    }
}


function Expand-AppPath {
    param (
        [string]$Path
    )

    return [Environment]::ExpandEnvironmentVariables($Path)
}


function Start-ProfileApp {
    param (
        $App
    )

    try {
        # Tarkistetaan onko prosessi jo kaynnissa
        if ($App.ProcessName) {
            $running = Get-Process -Name $App.ProcessName -ErrorAction SilentlyContinue

            if ($running) {
                Write-Host "$($App.Name) on jo kaynnissa." -ForegroundColor Yellow
                Write-Log "$($App.Name) oli jo kaynnissa"

                return
            }
        }

        $path = Expand-AppPath $App.Path

        if (-not (Test-Path $path)) {
            Write-Host "$($App.Name) ei loytynyt: $path" -ForegroundColor Yellow
            Write-Log "$($App.Name) ei loytynyt polusta $path" "WARNING"

            return
        }

        if ($App.Arguments) {
            Start-Process -FilePath $path -ArgumentList $App.Arguments
        }
        else {
            Start-Process -FilePath $path
        }

        Write-Host "$($App.Name) kaynnistetty." -ForegroundColor Green
        Write-Log "$($App.Name) kaynnistetty"
    }
    catch {
        Write-Host "$($App.Name) kaynnistys epaonnistui." -ForegroundColor Red
        Write-Log "$($App.Name) kaynnistys epaonnistui: $($_.Exception.Message)" "ERROR"
    }
}


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
        Write-Host "Kaynnistetaan profiili: $($profile.Name)" -ForegroundColor Cyan

        Write-Log "Profiili $($profile.Name) kaynnistetaan"

        # Ohjelmat
        foreach ($app in $profile.Apps) {
            Start-ProfileApp $app
        }

        # Verkkosivut
        foreach ($website in $profile.Websites) {
            try {
                Start-Process $website

                Write-Host "Avattu: $website"
                Write-Log "Verkkosivu avattu: $website"
            }
            catch {
                Write-Log "Verkkosivun avaaminen epaonnistui: $website" "ERROR"
            }
        }

        # Kansiot
        foreach ($folder in $profile.Folders) {
            try {
                $expandedFolder = Expand-AppPath $folder

                if (Test-Path $expandedFolder) {
                    Start-Process explorer.exe -ArgumentList $expandedFolder

                    Write-Host "Kansio avattu: $expandedFolder"
                    Write-Log "Kansio avattu: $expandedFolder"
                }
                else {
                    Write-Host "Kansiota ei loytynyt: $expandedFolder" -ForegroundColor Yellow
                    Write-Log "Kansiota ei loytynyt: $expandedFolder" "WARNING"
                }
            }
            catch {
                Write-Log "Kansion avaaminen epaonnistui: $folder" "ERROR"
            }
        }

        Write-Host ""
        Write-Host "Profiili kaynnistetty!" -ForegroundColor Green
    }
    catch {
        Write-Host "Profiilin kaynnistyksessa tapahtui virhe." -ForegroundColor Red
        Write-Log "Profiilin kaynnistyksessa tapahtui virhe: $($_.Exception.Message)" "ERROR"
    }
}


function Stop-Profile {
    param (
        [string]$ProfileName
    )

    $profile = Get-ProfileConfig $ProfileName

    if ($null -eq $profile) {
        return
    }

    Write-Host ""
    Write-Host "Suljetaan profiilin ohjelmia..." -ForegroundColor Cyan

    foreach ($processName in $profile.StopProcesses) {

        try {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

            if ($process) {
                $process | Stop-Process -Force

                Write-Host "$processName suljettu." -ForegroundColor Green
                Write-Log "Prosessi $processName suljettu"
            }
            else {
                Write-Host "$processName ei ollut kaynnissa."
            }
        }
        catch {
            Write-Host "$processName sulkeminen epaonnistui." -ForegroundColor Red
            Write-Log "$processName sulkeminen epaonnistui: $($_.Exception.Message)" "ERROR"
        }
    }
}


function Show-ProgramStatus {

    Write-Host ""
    Write-Host "OHJELMIEN TILA" -ForegroundColor Cyan
    Write-Host "-----------------------------"

    try {
        $files = Get-ChildItem "$Script:ConfigDir\*.json"

        $processNames = @()

        foreach ($file in $files) {

            $profile = Get-Content $file.FullName -Raw | ConvertFrom-Json

            foreach ($app in $profile.Apps) {
                if ($app.ProcessName) {
                    $processNames += $app.ProcessName
                }
            }
        }

        $processNames = $processNames | Sort-Object -Unique

        foreach ($processName in $processNames) {

            $running = Get-Process -Name $processName -ErrorAction SilentlyContinue

            if ($running) {
                Write-Host "$processName : KAYNNISSA" -ForegroundColor Green
            }
            else {
                Write-Host "$processName : EI KAYNNISSA" -ForegroundColor DarkGray
            }
        }

        Write-Log "Ohjelmien tila tarkistettu"
    }
    catch {
        Write-Host "Tilatarkistus epaonnistui." -ForegroundColor Red
        Write-Log "Tilatarkistus epaonnistui: $($_.Exception.Message)" "ERROR"
    }
}


function Show-Log {

    Write-Host ""
    Write-Host "LOKI" -ForegroundColor Cyan
    Write-Host "-----------------------------"

    if (Test-Path $Script:LogFile) {
        Get-Content $Script:LogFile -Tail 20
    }
    else {
        Write-Host "Lokia ei ole viela luotu."
    }
}
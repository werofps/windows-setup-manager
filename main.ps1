$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\functions.ps1"


function Show-Menu {

    Clear-Host

    Write-Host "========================================="
    Write-Host "        WINDOWS SETUP MANAGER"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "1. Gaming"
    Write-Host "2. Koulu"
    Write-Host "3. Videoeditointi"
    Write-Host "4. Tarkista ohjelmien tila"
    Write-Host "5. Sulje Gaming-ohjelmat"
    Write-Host "6. Nayta loki"
    Write-Host "7. Lopeta"
    Write-Host ""
}


Write-Log "Windows Setup Manager kaynnistetty"


while ($true) {

    Show-Menu

    $choice = Read-Host "Valitse toiminto (1-7)"

    switch ($choice) {

        "1" {
            Start-Profile "gaming"

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "2" {
            Start-Profile "school"

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "3" {
            Start-Profile "editing"

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "4" {
            Show-ProgramStatus

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "5" {
            Stop-Profile "gaming"

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "6" {
            Show-Log

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        "7" {
            Write-Log "Windows Setup Manager lopetettu"

            Write-Host ""
            Write-Host "Ohjelma lopetetaan."

            break
        }

        default {
            Write-Host ""
            Write-Host "Virheellinen valinta." -ForegroundColor Red

            Write-Log "Virheellinen valinta: $choice" "WARNING"

            Start-Sleep -Seconds 1
        }
    }
}
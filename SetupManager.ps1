$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\functions.ps1"

Write-Log "Windows Setup Manager kaynnistetty"


while ($true) {

    Clear-Host

    Write-Host "========================================="
    Write-Host "        WINDOWS SETUP MANAGER"
    Write-Host "========================================="
    Write-Host ""

    try {

        $profiles = Get-ChildItem `
            "$Script:ProfilesDir\*.json" `
            -ErrorAction Stop

        $index = 1

        foreach ($profileFile in $profiles) {

            $profile = Get-Content `
                $profileFile.FullName `
                -Raw |
                ConvertFrom-Json

            Write-Host "$index. $($profile.Name)"

            $index++
        }


        $statusChoice = $index

        Write-Host "$statusChoice. Tarkista ohjelmien tila"

        $index++


        $logChoice = $index

        Write-Host "$logChoice. Nayta loki"

        $index++


        $exitChoice = $index

        Write-Host "$exitChoice. Lopeta"

        Write-Host ""


        $choice = Read-Host "Valitse toiminto"


        if ($choice -notmatch '^\d+$') {

            Write-Host `
                "Anna numero." `
                -ForegroundColor Red

            Start-Sleep -Seconds 1

            continue
        }


        $number = [int]$choice


        # ====================================
        # PROFIILIN VALINTA
        # ====================================

        if ($number -ge 1 -and $number -le $profiles.Count) {

            $selectedFile = $profiles[$number - 1]

            $profileName = `
                [System.IO.Path]::GetFileNameWithoutExtension(
                    $selectedFile.Name
                )

            Show-ProfileMenu $profileName
        }


        # ====================================
        # OHJELMIEN TILA
        # ====================================

        elseif ($number -eq $statusChoice) {

            Show-ProgramStatus

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }


        # ====================================
        # LOKI
        # ====================================

        elseif ($number -eq $logChoice) {

            Show-Log

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }


        # ====================================
        # LOPETA
        # ====================================

        elseif ($number -eq $exitChoice) {

            Write-Log "Windows Setup Manager lopetettu"

            Write-Host ""
            Write-Host "Ohjelma lopetetaan."

            break
        }


        else {

            Write-Host `
                "Virheellinen valinta." `
                -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }
    catch {

        Write-Host `
            "Virhe: $($_.Exception.Message)" `
            -ForegroundColor Red

        Write-Log `
            "Paaohjelman virhe: $($_.Exception.Message)" `
            "ERROR"

        Write-Host ""
        Read-Host "Paina Enter jatkaaksesi"
    }
}
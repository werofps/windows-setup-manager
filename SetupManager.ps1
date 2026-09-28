$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\functions.ps1"

Write-Log "Windows Setup Manager kaynnistetty"

while ($true) {

    Clear-Host

    Write-Host "========================================="
    Write-Host "        WINDOWS SETUP MANAGER"
    Write-Host "========================================="
    Write-Host ""

    $profiles = Get-ChildItem "$Script:ProfilesDir\*.json"

    $index = 1

    foreach ($profileFile in $profiles) {

        $profile = Get-Content $profileFile.FullName -Raw | ConvertFrom-Json

        Write-Host "$index. $($profile.Name)"

        $index++
    }

    Write-Host "$index. Tarkista ohjelmien tila"
    $statusChoice = $index

    $index++

    Write-Host "$index. Nayta loki"
    $logChoice = $index

    $index++

    Write-Host "$index. Lopeta"
    $exitChoice = $index

    Write-Host ""

    $choice = Read-Host "Valitse toiminto"

    if ($choice -match '^\d+$') {

        $number = [int]$choice

        if ($number -ge 1 -and $number -le $profiles.Count) {

            $selectedFile = $profiles[$number - 1]

            $profileName = [System.IO.Path]::GetFileNameWithoutExtension(
                $selectedFile.Name
            )

            Start-Profile $profileName

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        elseif ($number -eq $statusChoice) {

            Show-ProgramStatus

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        elseif ($number -eq $logChoice) {

            Show-Log

            Write-Host ""
            Read-Host "Paina Enter jatkaaksesi"
        }

        elseif ($number -eq $exitChoice) {

            Write-Log "Windows Setup Manager lopetettu"

            break
        }

        else {
            Write-Host "Virheellinen valinta." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

    else {
        Write-Host "Anna numero." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}
# Corrige l'erreur Gradle "Could not read workspace metadata ... metadata.bin"
# Fermez Android Studio avant d'executer ce script.

Write-Host "Arret des daemons Gradle..."
Set-Location "$PSScriptRoot\android"
.\gradlew.bat --stop 2>$null

Write-Host "Nettoyage du cache Gradle global corrompu..."
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches\8.11.1" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$PSScriptRoot\android\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$PSScriptRoot\.gradle-home" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\.gradle-home" | Out-Null

Write-Host "Correction du SDK Flutter..."
$localProps = "$PSScriptRoot\android\local.properties"
(Get-Content $localProps) -replace 'flutter\.sdk=.*', 'flutter.sdk=C:\\Users\\Home\\fvm\\versions\\3.41.0' | Set-Content $localProps

Write-Host "OK. Lancez maintenant:"
Write-Host "  Git Bash  -> ./run_app.sh"
Write-Host "  PowerShell -> `$env:GRADLE_USER_HOME='$(Resolve-Path $PSScriptRoot)\.gradle-home'; fvm flutter run"

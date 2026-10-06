# Mini-ABS: lokal ishga tushirish
#   powershell -ExecutionPolicy Bypass -File run-local.ps1
# 1) WAR yig'iladi  2) Tomcat'ga joylanadi  3) Tomcat ishga tushadi -> http://localhost:8090/miniabs
# (8080 portni bu kompyuterda Jenkins egallagan, shuning uchun Tomcat 8090 da)
param(
  [string]$Tomcat = "$env:USERPROFILE\dev\tomcat"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $env:JAVA_HOME) {
  $env:JAVA_HOME = (Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory | Select-Object -First 1).FullName
}

Write-Host '== WAR yig''ilmoqda...'
Push-Location "$root\web"
mvn -q -B package
if ($LASTEXITCODE -ne 0) { Pop-Location; throw 'Maven build xato bilan tugadi' }
Pop-Location

Write-Host '== Tomcat to''xtatilmoqda (ishlayotgan bo''lsa)...'
& "$Tomcat\bin\shutdown.bat" 2>$null | Out-Null
for ($i = 0; $i -lt 15; $i++) {
  Start-Sleep -Seconds 1
  $l = Get-NetTCPConnection -LocalPort 8005 -State Listen -ErrorAction SilentlyContinue
  if (-not $l) { break }
}
if ($l) {
  # shutdown.bat ulgurmasa, aynan shu Tomcat jarayonini to'xtatamiz
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($l.OwningProcess)"
  if ($p.CommandLine -like "*$Tomcat*") { Stop-Process -Id $l.OwningProcess -Force }
}

Copy-Item "$root\web\target\miniabs.war" "$Tomcat\webapps\miniabs.war" -Force

Write-Host '== Tomcat ishga tushirilmoqda...'
Start-Process -FilePath "$Tomcat\bin\catalina.bat" -ArgumentList 'start' -WorkingDirectory "$Tomcat\bin" -WindowStyle Hidden
Write-Host 'Tayyor (15-20 soniyadan keyin): http://localhost:8090/miniabs  (login: b.abdusalomov / Operator2026)'

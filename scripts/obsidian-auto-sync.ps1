param(
  [string]$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$Remote = "origin",
  [string]$Branch = "main",
  [string]$ObsidianExe = "",
  [string]$MessagePrefix = "Auto sync notes",
  [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingFile {
  param([string[]]$Candidates)

  foreach ($candidate in $Candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }

    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  return $null
}

function Find-Git {
  $fromPath = Get-Command git -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
  return Resolve-ExistingFile @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$programFilesX86\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
    "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe"
  )
}

function Find-Obsidian {
  if (-not [string]::IsNullOrWhiteSpace($ObsidianExe)) {
    if (Test-Path -LiteralPath $ObsidianExe -PathType Leaf) {
      return (Resolve-Path -LiteralPath $ObsidianExe).Path
    }

    throw "Obsidian executable was not found at: $ObsidianExe"
  }

  $fromPath = Get-Command Obsidian -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
  $candidate = Resolve-ExistingFile @(
    "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
    "$env:ProgramFiles\Obsidian\Obsidian.exe",
    "$programFilesX86\Obsidian\Obsidian.exe"
  )

  if (-not $candidate) {
    throw "Obsidian.exe was not found. Pass -ObsidianExe 'C:\path\to\Obsidian.exe'."
  }

  return $candidate
}

function Invoke-Git {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

  & $script:GitExe @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function Get-GitOutput {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

  $output = & $script:GitExe @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE`n$output"
  }

  return ($output | Out-String).Trim()
}

function Sync-Notes {
  param([string]$Phase)

  Push-Location -LiteralPath $VaultPath
  try {
    Invoke-Git rev-parse --is-inside-work-tree | Out-Null
    Invoke-Git config core.quotepath false

    $status = Get-GitOutput status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($status)) {
      Write-Host "[$Phase] Local changes found. Creating a commit..."
      Invoke-Git add -A

      $staged = Get-GitOutput diff --cached --name-only
      if (-not [string]::IsNullOrWhiteSpace($staged)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Invoke-Git commit -m "${MessagePrefix}: $timestamp ($Phase)"
      }
    }
    else {
      Write-Host "[$Phase] No local changes to commit."
    }

    Write-Host "[$Phase] Pulling latest remote changes..."
    Invoke-Git pull --rebase --autostash $Remote $Branch

    Write-Host "[$Phase] Pushing to $Remote/$Branch..."
    Invoke-Git push $Remote "HEAD:$Branch"

    Write-Host "[$Phase] Sync complete."
  }
  finally {
    Pop-Location
  }
}

if (-not (Test-Path -LiteralPath $VaultPath -PathType Container)) {
  throw "Vault path does not exist: $VaultPath"
}

$script:GitExe = Find-Git
if (-not $script:GitExe) {
  throw "git.exe was not found. Install Git for Windows or add git to PATH."
}

Sync-Notes "open"

if ($NoLaunch) {
  exit 0
}

$obsidian = Find-Obsidian
Write-Host "Launching Obsidian for vault: $VaultPath"
Start-Process -FilePath $obsidian -ArgumentList @($VaultPath) | Out-Null

Write-Host "Waiting for Obsidian to close..."
Start-Sleep -Seconds 3
while (Get-Process -Name Obsidian -ErrorAction SilentlyContinue) {
  Start-Sleep -Seconds 5
}

Sync-Notes "close"

[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [switch]$Recurse,
    [switch]$FailOnWarning
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SkippedDirectoryNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($name in @(
        ".git",
        ".gradle",
        ".gradle-user-home",
        "node_modules",
        "bin",
        "obj",
        "build",
        "dist",
        "coverage",
        ".next",
        ".nuxt",
        ".turbo",
        ".cache",
        ".parcel-cache"
    )) {
    [void]$SkippedDirectoryNames.Add($name)
}

function Get-RootFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Resolve-Path -LiteralPath $Path).Path
}

function Test-TargetFile {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $knownNames = @("README.md", "CHANGELOG.md", "AGENTS.md", "CLAUDE.md", ".editorconfig")
    $knownExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".cmd", ".bat", ".yml", ".yaml")

    if ($knownNames -contains $File.Name) {
        return $true
    }

    if ($knownExtensions -contains $File.Extension.ToLowerInvariant()) {
        return $true
    }

    return $false
}

function Test-SkippedDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$Directory
    )

    if ($Directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        return $true
    }

    return $SkippedDirectoryNames.Contains($Directory.Name)
}

function Get-TargetFilesFromTree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    $files = [System.Collections.Generic.Dictionary[string, System.IO.FileInfo]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $pending = [System.Collections.Generic.Stack[System.IO.DirectoryInfo]]::new()
    $pending.Push((Get-Item -LiteralPath $BasePath))

    while ($pending.Count -gt 0) {
        $currentDirectory = $pending.Pop()

        foreach ($file in @(Get-ChildItem -LiteralPath $currentDirectory.FullName -File -Force -ErrorAction SilentlyContinue | Where-Object { Test-TargetFile -File $_ })) {
            $files[$file.FullName] = $file
        }

        foreach ($childDirectory in @(Get-ChildItem -LiteralPath $currentDirectory.FullName -Directory -Force -ErrorAction SilentlyContinue)) {
            if (Test-SkippedDirectory -Directory $childDirectory) {
                continue
            }

            $pending.Push($childDirectory)
        }
    }

    return @($files.Values | Sort-Object FullName)
}

function Get-TargetFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [switch]$RecurseAll
    )

    $files = [System.Collections.Generic.Dictionary[string, System.IO.FileInfo]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($RecurseAll) {
        return @(Get-TargetFilesFromTree -BasePath $BasePath)
    }

    $topLevelNames = @("README.md", "CHANGELOG.md", "AGENTS.md", "CLAUDE.md", ".editorconfig")
    foreach ($name in $topLevelNames) {
        $path = Join-Path $BasePath $name
        if (Test-Path -LiteralPath $path) {
            $file = Get-Item -LiteralPath $path
            $files[$file.FullName] = $file
        }
    }

    $recursiveDirectories = @(".github", "docs", "scripts")
    foreach ($directoryName in $recursiveDirectories) {
        $directoryPath = Join-Path $BasePath $directoryName
        if (-not (Test-Path -LiteralPath $directoryPath)) {
            continue
        }

        foreach ($file in (Get-TargetFilesFromTree -BasePath $directoryPath)) {
            $files[$file.FullName] = $file
        }
    }

    foreach ($file in (Get-ChildItem -LiteralPath $BasePath -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @(".ps1", ".psm1", ".psd1", ".cmd", ".bat") })) {
        $files[$file.FullName] = $file
    }

    return @($files.Values | Sort-Object FullName)
}

function Get-DetectedEncoding {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    if ($Bytes.Length -eq 0) {
        return "utf8"
    }

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return "utf8-bom"
    }

    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return "utf16le"
    }

    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return "utf16be"
    }

    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
        [void]$utf8.GetString($Bytes)
        return "utf8"
    }
    catch {
        return "non-utf8"
    }
}

function Get-RecommendedPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    if ($File.Extension.ToLowerInvariant() -in @(".md", ".ps1", ".psm1", ".psd1")) {
        return "prefer-bom"
    }

    return "utf8"
}

$rootPath = Get-RootFullPath -Path $Root
if ($Recurse) {
    $targets = Get-TargetFiles -BasePath $rootPath -RecurseAll
}
else {
    $targets = Get-TargetFiles -BasePath $rootPath
}

if ($targets.Count -eq 0) {
    throw "チェック対象のテキストファイルが見つかりませんでした: $rootPath"
}

$results = New-Object System.Collections.Generic.List[object]
foreach ($file in $targets) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $encoding = Get-DetectedEncoding -Bytes $bytes
    $policy = Get-RecommendedPolicy -File $file
    $status = "OK"
    $note = ""

    switch ($encoding) {
        "utf8-bom" {
            $note = "UTF-8 with BOM"
        }
        "utf8" {
            if ($policy -eq "prefer-bom") {
                $status = "WARN"
                $note = "UTF-8 without BOM"
            }
            else {
                $note = "UTF-8"
            }
        }
        "utf16le" {
            $status = "FAIL"
            $note = "UTF-16 LE"
        }
        "utf16be" {
            $status = "FAIL"
            $note = "UTF-16 BE"
        }
        default {
            $status = "FAIL"
            $note = "non UTF-8"
        }
    }

    $results.Add([pscustomobject]@{
            Status   = $status
            Encoding = $encoding
            Path     = $file.FullName.Substring($rootPath.Length).TrimStart('\', '/')
            Note     = $note
        })
}

$results |
    Sort-Object Status, Path |
    Format-Table -AutoSize

$failureCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warningCount = @($results | Where-Object { $_.Status -eq "WARN" }).Count

if ($failureCount -gt 0) {
    throw "文字コードチェックで FAIL が $failureCount 件見つかりました。"
}

if ($FailOnWarning -and $warningCount -gt 0) {
    throw "文字コードチェックで WARN が $warningCount 件見つかりました。"
}

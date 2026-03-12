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

$BinaryExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($extension in @(
         ".7z",
         ".avi",
         ".bmp",
         ".class",
         ".dll",
         ".dylib",
         ".eot",
         ".exe",
         ".gif",
         ".gz",
         ".ico",
         ".jar",
         ".jpeg",
         ".jpg",
         ".mp3",
         ".mp4",
         ".mov",
         ".otf",
         ".pdf",
         ".pdb",
         ".png",
         ".rar",
         ".so",
         ".tar",
         ".tgz",
         ".ttf",
         ".wav",
         ".webm",
         ".webp",
         ".woff",
         ".woff2",
         ".zip"
    )) {
    [void]$BinaryExtensions.Add($extension)
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

    return -not $BinaryExtensions.Contains($File.Extension.ToLowerInvariant())
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

function Get-TargetFilesFromGit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    if (-not (Test-Path -LiteralPath (Join-Path $BasePath ".git"))) {
        return @()
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return @()
    }

    $files = [System.Collections.Generic.Dictionary[string, System.IO.FileInfo]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($relativePath in @(git -C $BasePath ls-files)) {
        if (-not $relativePath) {
            continue
        }

        $fullPath = Join-Path $BasePath $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        $file = Get-Item -LiteralPath $fullPath
        if (-not (Test-TargetFile -File $file)) {
            continue
        }

        $files[$file.FullName] = $file
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
        $trackedFiles = @(Get-TargetFilesFromGit -BasePath $BasePath)
        if ($trackedFiles.Count -gt 0) {
            return $trackedFiles
        }

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

function Convert-EditorConfigCharset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Charset
    )

    switch ($Charset.Trim().ToLowerInvariant()) {
        "utf-8" { return "utf8" }
        "utf-8-bom" { return "utf8-bom" }
        "utf-16le" { return "utf16le" }
        "utf-16be" { return "utf16be" }
        default { return $null }
    }
}

function Expand-EditorConfigPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $match = [System.Text.RegularExpressions.Regex]::Match($Pattern, "\{[^{}]+\}")
    if (-not $match.Success) {
        return @($Pattern)
    }

    $prefix = $Pattern.Substring(0, $match.Index)
    $suffix = $Pattern.Substring($match.Index + $match.Length)
    $options = $match.Value.TrimStart([char[]]@("{")).TrimEnd([char[]]@("}")) -split ","
    $expanded = New-Object System.Collections.Generic.List[string]

    foreach ($option in $options) {
        foreach ($candidate in (Expand-EditorConfigPattern -Pattern ($prefix + $option + $suffix))) {
            $expanded.Add($candidate)
        }
    }

    return $expanded.ToArray()
}

function Convert-EditorConfigPatternToRegex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $normalizedPattern = $Pattern.Replace("\", "/")
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append("^")

    for ($index = 0; $index -lt $normalizedPattern.Length; $index++) {
        $character = $normalizedPattern[$index]

        if ($character -eq "*") {
            $isDoubleStar = ($index + 1 -lt $normalizedPattern.Length) -and ($normalizedPattern[$index + 1] -eq "*")
            if ($isDoubleStar) {
                [void]$builder.Append(".*")
                $index += 1
            }
            else {
                [void]$builder.Append("[^/]*")
            }

            continue
        }

        if ($character -eq "?") {
            [void]$builder.Append("[^/]")
            continue
        }

        [void]$builder.Append([System.Text.RegularExpressions.Regex]::Escape([string]$character))
    }

    [void]$builder.Append("$")
    return $builder.ToString()
}

function Test-EditorConfigPatternMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalizedRelativePath = $RelativePath.Replace("\", "/")
    $target = if ($Pattern.Contains("/")) {
        $normalizedRelativePath
    }
    else {
        [System.IO.Path]::GetFileName($normalizedRelativePath)
    }

    foreach ($candidatePattern in (Expand-EditorConfigPattern -Pattern $Pattern)) {
        $regexPattern = Convert-EditorConfigPatternToRegex -Pattern $candidatePattern
        if ($target -match $regexPattern) {
            return $true
        }
    }

    return $false
}

function Get-EditorConfigCharsetRules {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EditorConfigPath
    )

    if (-not (Test-Path -LiteralPath $EditorConfigPath)) {
        return @()
    }

    $rules = New-Object System.Collections.Generic.List[object]
    $currentPattern = $null

    foreach ($line in Get-Content -LiteralPath $EditorConfigPath) {
        $trimmed = $line.Trim()

        if (-not $trimmed -or $trimmed.StartsWith("#") -or $trimmed.StartsWith(";")) {
            continue
        }

        if ($trimmed -match "^\[(.+)\]$") {
            $currentPattern = $matches[1].Trim()
            continue
        }

        if (-not $currentPattern) {
            continue
        }

        $parts = $trimmed -split "\s*=\s*", 2
        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim().ToLowerInvariant()
        if ($key -ne "charset") {
            continue
        }

        $normalizedCharset = Convert-EditorConfigCharset -Charset $parts[1]
        if ($null -eq $normalizedCharset) {
            continue
        }

        $rules.Add([pscustomobject]@{
                Pattern  = $currentPattern
                Encoding = $normalizedCharset
            })
    }

    return $rules.ToArray()
}

function Get-RecommendedPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [object[]]$CharsetRules
    )

    $relativePath = $File.FullName.Substring($RootPath.Length).TrimStart('\', '/')
    $matchedEncoding = $null

    foreach ($rule in $CharsetRules) {
        if (Test-EditorConfigPatternMatch -Pattern $rule.Pattern -RelativePath $relativePath) {
            $matchedEncoding = $rule.Encoding
        }
    }

    if ($null -eq $matchedEncoding) {
        return "utf8"
    }

    return $matchedEncoding
}

$rootPath = Get-RootFullPath -Path $Root
$charsetRules = Get-EditorConfigCharsetRules -EditorConfigPath (Join-Path $rootPath ".editorconfig")
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
    $policy = Get-RecommendedPolicy -File $file -RootPath $rootPath -CharsetRules $charsetRules
    $status = "OK"
    $note = switch ($encoding) {
        "utf8-bom" { "UTF-8 with BOM" }
        "utf8" { "UTF-8" }
        "utf16le" { "UTF-16 LE" }
        "utf16be" { "UTF-16 BE" }
        default { "non UTF-8" }
    }

    if ($policy -eq "utf8-bom") {
        if ($encoding -eq "utf8") {
            $status = "WARN"
            $note = "UTF-8 without BOM"
        }
        elseif ($encoding -ne "utf8-bom") {
            $status = "FAIL"
        }
    }
    elseif ($policy -eq "utf8") {
        if ($encoding -eq "utf8-bom") {
            $status = "WARN"
            $note = "UTF-8 with BOM (unexpected)"
        }
        elseif ($encoding -ne "utf8") {
            $status = "FAIL"
        }
    }
    elseif ($encoding -ne $policy) {
        $status = "FAIL"
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

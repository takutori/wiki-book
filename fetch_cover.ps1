# fetch_cover.ps1 - fetch book cover from Google Books API and update .md file
# Usage: .\fetch_cover.ps1 -MdFile "work/AI-Agent/book.md" -Query "book title author"

param(
    [Parameter(Mandatory)][string]$MdFile,
    [Parameter(Mandatory)][string]$Query
)

$root = $PSScriptRoot

# Japanese strings from Unicode code points
$lblCover = -join [char[]]@(0x8868, 0x7D19)   # 表紙

# 1. Search Google Books API
$encoded  = [Uri]::EscapeUriString($Query)
$searchUrl = "https://www.googleapis.com/books/v1/volumes?q=$encoded&maxResults=5"

try {
    $res = Invoke-RestMethod -Uri $searchUrl
} catch {
    Write-Error "Google Books API error: $_"
    exit 1
}

$item = $res.items | Where-Object { $_.volumeInfo.imageLinks.thumbnail } | Select-Object -First 1

if (-not $item) {
    Write-Error "Cover not found. Try a different query."
    exit 1
}

$info = $item.volumeInfo
Write-Host "Found: $($info.title) / $($info.authors -join ', ')"

# 2. Download cover image
$coverUrl    = $info.imageLinks.thumbnail -replace "^http:", "https:"
$mdFullPath  = Join-Path $root $MdFile
$mdDir       = Split-Path $mdFullPath -Parent
$imagesDir   = Join-Path $mdDir "images"
$baseName    = [System.IO.Path]::GetFileNameWithoutExtension($mdFullPath)
$destPath    = Join-Path $imagesDir "$baseName.jpg"

New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null
Invoke-WebRequest -Uri $coverUrl -OutFile $destPath
Write-Host "Saved: $destPath"

# 3. Update ![cover-label](...) in .md file using line-by-line processing
$raw   = [System.IO.File]::ReadAllText($mdFullPath, [System.Text.Encoding]::UTF8)
$lines = $raw -split "`r?`n"

$updated = $lines | ForEach-Object {
    $line = $_
    if ($line.Contains($lblCover) -and $line.Contains("(") -and $line.Contains(")")) {
        $open  = $line.IndexOf("(")
        $close = $line.IndexOf(")", $open)
        if ($close -gt $open) {
            $line = $line.Substring(0, $open + 1) + "images/$baseName.jpg" + $line.Substring($close)
        }
    }
    $line
}

[System.IO.File]::WriteAllText($mdFullPath, ($updated -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Updated: $MdFile"

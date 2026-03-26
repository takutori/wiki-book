# fetch_cover.ps1
# 使い方: .\fetch_cover.ps1 -MdFile "work/DomainKnowledge/ザ・ゴール.md" -Query "ザ・ゴール ゴールドラット"
#
# Google Books API で書影を検索し、.md ファイルの画像パスを自動更新する

param(
    [Parameter(Mandatory)][string]$MdFile,   # .md ファイルの相対パス
    [Parameter(Mandatory)][string]$Query     # 検索キーワード（日本語・英語どちらでも可）
)

$root = $PSScriptRoot

# 1. Google Books API で検索
$encoded = [Uri]::EscapeUriString($Query)
$searchUrl = "https://www.googleapis.com/books/v1/volumes?q=$encoded&maxResults=5"

try {
    $res = Invoke-RestMethod -Uri $searchUrl
} catch {
    Write-Error "Google Books API への接続に失敗しました: $_"
    exit 1
}

# imageLinks.thumbnail を持つ最初の結果を使用
$item = $res.items | Where-Object { $_.volumeInfo.imageLinks.thumbnail } | Select-Object -First 1

if (-not $item) {
    Write-Error "書影が見つかりませんでした。別のキーワードで試してください。"
    exit 1
}

$info = $item.volumeInfo
Write-Host "Found: $($info.title) / $($info.authors -join ', ')"

# 2. 画像をダウンロード（zoom=1 → thumbnail サイズ）
$coverUrl = $info.imageLinks.thumbnail -replace "^http:", "https:"
$mdFullPath = Join-Path $root $MdFile
$mdDir = Split-Path $mdFullPath -Parent
$imagesDir = Join-Path $mdDir "images"
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($mdFullPath)
$destPath = Join-Path $imagesDir "$baseName.jpg"

New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null
Invoke-WebRequest -Uri $coverUrl -OutFile $destPath
Write-Host "Saved: $destPath"

# 3. .md の ![表紙](...) を更新
$content = [System.IO.File]::ReadAllText($mdFullPath, [System.Text.Encoding]::UTF8)
$updated = $content -replace "!\[表紙\]\([^)]*\)", "![表紙](images/$baseName.jpg)"
[System.IO.File]::WriteAllText($mdFullPath, $updated, [System.Text.Encoding]::UTF8)
Write-Host "Updated: $MdFile"

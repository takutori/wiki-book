# generate_books.ps1
# work/ と private/ の .md ファイルを走査して docs/books.json を生成する

$repoOwner = "takutori"
$repoName  = "wiki-book"
$branch    = "main"
$rawBase   = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"
$blobBase  = "https://github.com/$repoOwner/$repoName/blob/$branch"
$root      = (Get-Location).Path.TrimEnd('\').Replace('\', '/')

$books = [System.Collections.Generic.List[object]]::new()

foreach ($section in @("work", "private")) {
    if (-not (Test-Path $section)) { continue }

    $mdFiles = Get-ChildItem -Path $section -Recurse -Filter "*.md" |
               Where-Object { $_.Name -ne "template.md" }

    foreach ($file in $mdFiles) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # タイトル（# 見出し）
        $title = ""
        if ($content -match "(?m)^# (.+)$") { $title = $Matches[1].Trim() }
        if ([string]::IsNullOrEmpty($title) -or $title -eq "[本のタイトル]") { continue }

        # リポジトリルートからの相対パス（スラッシュ区切り）
        $fileRelPath = $file.FullName.Replace('\', '/').Replace("$root/", "")
        $dirRelPath  = $file.DirectoryName.Replace('\', '/').Replace("$root/", "")

        # 著者
        $author = ""
        if ($content -match "\*\*著者\*\*：(.+)") { $author = $Matches[1].Trim() }

        # カバー画像（プレースホルダー "images/.jpg" は除外）
        $coverUrl = ""
        if ($content -match "!\[表紙\]\(([^)]+)\)") {
            $coverPath = $Matches[1].Trim()
            if ($coverPath -notmatch "^images/\.[a-z]+$") {
                $coverUrl = "$rawBase/$dirRelPath/$coverPath"
            }
        }

        # カテゴリ / ジャンル
        $category = ""
        if ($content -match "\*\*カテゴリ\*\*：(.+)")  { $category = $Matches[1].Trim() }
        elseif ($content -match "\*\*ジャンル\*\*：(.+)") { $category = $Matches[1].Trim() }

        # 評価（private のみ）
        $rating = ""
        if ($content -match "\*\*評価\*\*：(.+)") { $rating = $Matches[1].Trim() }

        $books.Add([pscustomobject]@{
            title    = $title
            author   = $author
            section  = $section
            category = $category
            cover    = $coverUrl
            url      = "$blobBase/$fileRelPath"
            rating   = $rating
        })
    }
}

if (-not (Test-Path "docs")) { New-Item -ItemType Directory -Path "docs" | Out-Null }

$json = if ($books.Count -eq 0) { "[]" } else { $books | ConvertTo-Json -Depth 3 }
[System.IO.File]::WriteAllText("$root/docs/books.json", $json, [System.Text.Encoding]::UTF8)

Write-Host "Generated docs/books.json ($($books.Count) books)"

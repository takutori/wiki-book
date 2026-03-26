# generate_books.ps1
# work/ と private/ の .md ファイルを走査して docs/books.json を生成する

$repoOwner = "takutori"
$repoName  = "wiki-book"
$branch    = "main"
$rawBase   = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"
$blobBase  = "https://github.com/$repoOwner/$repoName/blob/$branch"
$root      = (Get-Location).Path.TrimEnd('\').Replace('\', '/')

# Japanese strings built from Unicode code points to avoid PS1 source encoding issues
$fwColon     = [char]0xFF1A
$lblCover    = -join [char[]]@(0x8868, 0x7D19)                  # 表紙
$lblAuthor   = -join [char[]]@(0x8457, 0x8005)                  # 著者
$lblCategory = -join [char[]]@(0x30AB,0x30C6,0x30B4,0x30EA)    # カテゴリ
$lblGenre    = -join [char[]]@(0x30B8,0x30E3,0x30F3,0x30EB)    # ジャンル
$lblRating   = -join [char[]]@(0x8A55, 0x4FA1)                  # 評価
$placeholder = '[' + (-join [char[]]@(0x672C,0x306E,0x30BF,0x30A4,0x30C8,0x30EB)) + ']'  # [本のタイトル]

$books = [System.Collections.Generic.List[object]]::new()

foreach ($section in @("work", "private")) {
    if (-not (Test-Path $section)) { continue }

    $mdFiles = Get-ChildItem -Path $section -Recurse -Filter "*.md" |
               Where-Object { $_.Name -ne "template.md" }

    foreach ($file in $mdFiles) {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        # タイトル
        $title = ""
        if ($content -match "(?m)^# (.+)$") { $title = $Matches[1].Trim() }
        if ([string]::IsNullOrEmpty($title) -or $title -eq $placeholder) { continue }

        $fileRelPath = $file.FullName.Replace('\', '/').Replace("$root/", "")
        $dirRelPath  = $file.DirectoryName.Replace('\', '/').Replace("$root/", "")

        # 著者
        $author = ""
        if ($content -match "\*\*$lblAuthor\*\*$fwColon(.+)") { $author = $Matches[1].Trim() }

        # カバー画像
        $coverUrl = ""
        if ($content -match "!\[$lblCover\]\(([^)]+)\)") {
            $coverPath = $Matches[1].Trim()
            if ($coverPath -notmatch "^images/\.[a-z]+$") {
                $coverUrl = "$rawBase/$dirRelPath/$coverPath"
            }
        }

        # カテゴリ / ジャンル
        $category = ""
        if ($content -match "\*\*$lblCategory\*\*$fwColon(.+)")  { $category = $Matches[1].Trim() }
        elseif ($content -match "\*\*$lblGenre\*\*$fwColon(.+)") { $category = $Matches[1].Trim() }

        # 評価
        $rating = ""
        if ($content -match "\*\*$lblRating\*\*$fwColon(.+)") { $rating = $Matches[1].Trim() }

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

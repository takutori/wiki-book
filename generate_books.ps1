# generate_books.ps1 - scans work/ and private/ .md files to generate docs/books.json

$repoOwner = "takutori"
$repoName  = "wiki-book"
$branch    = "main"
$rawBase   = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"
$blobBase  = "https://github.com/$repoOwner/$repoName/blob/$branch"
$root      = (Get-Location).Path.TrimEnd('\').Replace('\', '/')

# Japanese strings from Unicode code points (avoids PS1 source encoding issues)
$fwColon     = [char]0xFF1A
$lblCover    = -join [char[]]@(0x8868, 0x7D19)
$lblAuthor   = -join [char[]]@(0x8457, 0x8005)
$lblCategory = -join [char[]]@(0x30AB, 0x30C6, 0x30B4, 0x30EA)
$lblGenre    = -join [char[]]@(0x30B8, 0x30E3, 0x30F3, 0x30EB)
$lblRating   = -join [char[]]@(0x8A55, 0x4FA1)
$placeholder = '[' + (-join [char[]]@(0x672C,0x306E,0x30BF,0x30A4,0x30C8,0x30EB)) + ']'

# Extract value after full-width colon from lines containing the given label
function Get-MdField([string[]]$lines, [string]$label, [char]$colon) {
    foreach ($line in $lines) {
        if ($line.Contains($label) -and $line.Contains($colon)) {
            $idx = $line.IndexOf($colon)
            if ($idx -ge 0 -and ($idx + 1) -lt $line.Length) {
                return $line.Substring($idx + 1).Trim()
            }
        }
    }
    return [string]::Empty
}

$books = [System.Collections.Generic.List[object]]::new()

foreach ($section in @("work", "private")) {
    if (-not (Test-Path $section)) { continue }

    $mdFiles = Get-ChildItem -Path $section -Recurse -Filter "*.md" |
               Where-Object { $_.Name -ne "template.md" }

    foreach ($file in $mdFiles) {
        $raw   = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $lines = $raw -split "`r?`n"

        # Title from first "# " heading
        $title = [string]::Empty
        foreach ($line in $lines) {
            if ($line.StartsWith("# ")) { $title = $line.Substring(2).Trim(); break }
        }
        if ([string]::IsNullOrEmpty($title) -or $title -eq $placeholder) { continue }

        $fileRelPath = $file.FullName.Replace('\', '/').Replace("$root/", "")
        $dirRelPath  = $file.DirectoryName.Replace('\', '/').Replace("$root/", "")

        $author   = Get-MdField $lines $lblAuthor $fwColon
        $category = Get-MdField $lines $lblCategory $fwColon
        if ([string]::IsNullOrEmpty($category)) { $category = Get-MdField $lines $lblGenre $fwColon }
        $rating   = Get-MdField $lines $lblRating $fwColon

        # Cover image from "![cover-label](images/xxx.jpg)" line
        $coverUrl = [string]::Empty
        foreach ($line in $lines) {
            if ($line.Contains($lblCover) -and $line.Contains("(") -and $line.Contains(")")) {
                $start = $line.IndexOf("(") + 1
                $end   = $line.IndexOf(")", $start)
                if ($end -gt $start) {
                    $coverPath = $line.Substring($start, $end - $start).Trim()
                    if ($coverPath -notmatch "^images/\.[a-z]+$") {
                        $coverUrl = "$rawBase/$dirRelPath/$coverPath"
                    }
                }
                break
            }
        }

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

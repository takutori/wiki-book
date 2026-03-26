# empty string vs null test
$a = ""
Write-Host "empty eq null: $($a -eq $null)"
Write-Host "empty length: $($a.Length)"

# Full simulation of generate_books logic
$fwColon   = [char]0xFF1A
$lblAuthor = -join [char[]]@(0x8457, 0x8005)
$lblCover  = -join [char[]]@(0x8868, 0x7D19)

$f = Get-ChildItem -Path "work\DomainKnowledge" -Filter "*.md" | Where-Object { $_.Name -ne "template.md" } | Select-Object -First 1
$content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

# title match (same as generate_books.ps1)
$title = ""
if ($content -match "(?m)^# (.+)$") { $title = $Matches[1].Trim() }
Write-Host "title: $title"

# cover match (same as generate_books.ps1) - this runs BEFORE author in current code
if ($content -match "!\[$lblCover\]\(([^)]+)\)") {
    $coverPath = $Matches[1].Trim()
    Write-Host "cover: $coverPath"
}

# author match
$author = ""
$matchResult = $content -match "\*\*$lblAuthor\*\*$fwColon(.+)"
Write-Host "author match: $matchResult"
if ($matchResult) { $author = $Matches[1].Trim() }
Write-Host "author: '$author'"
Write-Host "author null: $($author -eq $null)"

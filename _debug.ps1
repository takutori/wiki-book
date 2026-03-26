$f = Get-ChildItem -Path "work\DomainKnowledge" -Filter "*.md" | Where-Object { $_.Name -ne "template.md" } | Select-Object -First 1
$content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

$fwColon   = [char]0xFF1A
$lblAuthor = -join [char[]]@(0x8457, 0x8005)

$pattern = "\*\*$lblAuthor\*\*$fwColon(.+)"
Write-Host "Pattern length: $($pattern.Length)"
Write-Host "Match: $($content -match $pattern)"
if ($content -match $pattern) {
    Write-Host "Capture: $($Matches[1])"
}

# 単純な部分一致テスト
Write-Host "Contains lblAuthor: $($content.Contains($lblAuthor))"
Write-Host "Contains fwColon: $($content.Contains($fwColon))"

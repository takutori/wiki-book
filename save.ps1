# books.json を最新の状態に更新してから push する
. "$PSScriptRoot/generate_books.ps1"

git add .
git commit -m "auto save: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push

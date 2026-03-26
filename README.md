# wiki-book

読んだ本のノートを蓄積するリポジトリ。

## 本棚

https://takutori.github.io/wiki-book/

## フォルダ構成

| フォルダ | 内容 |
|---|---|
| `work/` | 仕事で必要な知識を得るために読んだ本 |
| `private/` | 趣味で読んだ本（小説など） |

`work/`・`private/` 配下のフォルダは本のカテゴリを表す。各カテゴリフォルダ内に本1冊につき1つの `.md` ファイルを作成する。

テンプレートはそれぞれ以下に用意している。

- `work/template.md`
- `private/template.md`

## 保存・Push

```powershell
./save.ps1
```

実行するとコミットメッセージの入力が求められ、`git add → commit → push` まで自動で行う。

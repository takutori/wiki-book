# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

読んだ本のノートを蓄積するリポジトリ。`work/`（仕事関連）と `private/`（趣味）の2種類に分かれており、それぞれ配下のフォルダが本のカテゴリを表す。カテゴリフォルダ内に本1冊につき1つの `.md` ファイルを作成する。

## テンプレート

新しい本のノートを作成する際は必ずテンプレートに従うこと。

- `work/template.md` — 主張・根拠・知見メモ・理解を後回しにした内容の構成
- `private/template.md` — あらすじ・感想・印象に残った点・こんな人に勧めたい、の構成

## 本を追加するときの手順

ユーザーから本の情報を受け取ったら、以下を順番に実行すること。

1. **`.md` ファイルを作成**
   対象カテゴリフォルダにテンプレートをもとに作成する。

2. **表紙画像を取得**
   `fetch_cover.ps1` を実行して Google Books API から表紙を取得・保存し、`.md` の画像パスを更新する。
   ```powershell
   ./fetch_cover.ps1 -MdFile "work/カテゴリ/書名.md" -Query "検索キーワード"
   ```
   - 日本語・英語どちらのキーワードでも可
   - 検索結果が意図した本と異なる場合はキーワードを調整する

3. **push して Pages に反映**
   `save.ps1` を実行する。内部で `generate_books.ps1` が走り `docs/books.json` が更新されてから push される。
   ```powershell
   ./save.ps1
   ```

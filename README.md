# Jacques Lacan Psychoanalysis Notes

这是一个拉康派精神分析 Obsidian 知识库，并通过 Quartz 发布为可浏览的网页知识图谱。

## Web publishing

GitHub Actions 会在推送到 `main` 后自动构建 Quartz 站点，并发布到 GitHub Pages。Quartz 的 Graph、Backlinks、Explorer、Search 和 Obsidian-flavored Markdown 插件已启用。

站点地址：

https://unsolitude.github.io/Jacques-Lacan-psychoanalysis-note/

## Local preview

```powershell
npm ci
npx quartz plugin install
$preview = Join-Path $env:TEMP "quartz-lacan-content"
New-Item -ItemType Directory -Force -Path $preview
Copy-Item -Recurse -Force "拉康派精神分析知识图谱","拉康理论逻辑","相关图片" $preview
Copy-Item -Force index.md (Join-Path $preview "index.md")
npx quartz build --serve -d $preview
```

## Obsidian auto sync

Use `start-obsidian-sync.cmd` to open this vault when you want automatic GitHub sync. It runs one sync before Obsidian opens and another after Obsidian closes. Ignored files in `.gitignore` are not committed.

To run one sync without opening Obsidian:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\obsidian-auto-sync.ps1 -NoLaunch
```

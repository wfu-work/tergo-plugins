#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
site_dir=${1:-"$root/site"}
base_url=${TERGO_PLUGIN_BASE_URL:-https://wfu-work.github.io/tergo-plugins/packages}

python3 - "$site_dir" <<'PY'
from pathlib import Path
import shutil
import sys

site = Path(sys.argv[1])
if site.exists():
    shutil.rmtree(site)
site.mkdir(parents=True)
PY

TERGO_PLUGIN_BASE_URL="$base_url" "$script_dir/update-catalog.sh" "$root/dist"
mkdir -p "$site_dir/catalog" "$site_dir/packages"
cp "$root/catalog/index.json" "$site_dir/catalog/index.json"
cp "$root/dist"/*.tergo-plugin "$site_dir/packages/"
touch "$site_dir/.nojekyll"

python3 - "$site_dir" <<'PY'
from html import escape
import json
from pathlib import Path
import sys

site = Path(sys.argv[1])
catalog = json.loads((site / "catalog/index.json").read_text(encoding="utf-8"))
cards = []
for plugin in catalog.get("plugins", []):
    name = escape(str(plugin.get("name") or plugin.get("id") or "未命名插件"))
    plugin_id = escape(str(plugin.get("id") or ""))
    version = escape(str(plugin.get("version") or ""))
    description = escape(str(plugin.get("description") or "暂无描述"))
    category = escape(str(plugin.get("category") or "utility"))
    package_url = escape(str(plugin.get("packageUrl") or ""), quote=True)
    package_link = f'<a href="{package_url}">下载插件包</a>' if package_url else ""
    cards.append(
        f'''<article class="card">
  <div class="card-heading"><h2>{name}</h2><span>v{version}</span></div>
  <p class="id">{plugin_id} · {category}</p>
  <p>{description}</p>
  <div class="card-footer">{package_link}</div>
</article>'''
    )

updated_at = escape(str(catalog.get("updatedAt") or ""))
cards_html = "\n".join(cards) or '<p class="empty">当前没有可用插件。</p>'
page = f'''<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Tergo 在线插件目录</title>
  <style>
    :root {{ color-scheme: light; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #202124; background: #f6f8fa; }}
    body {{ margin: 0; }}
    main {{ max-width: 960px; margin: 0 auto; padding: 64px 24px 72px; }}
    header {{ margin-bottom: 32px; }}
    h1 {{ margin: 0 0 10px; font-size: clamp(28px, 5vw, 42px); letter-spacing: -0.03em; }}
    .lead {{ margin: 0; max-width: 680px; color: #5f6368; line-height: 1.7; }}
    .actions {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 22px; }}
    .actions a, .card-footer a {{ color: #0969da; text-decoration: none; font-weight: 600; }}
    .actions a {{ padding: 9px 14px; border: 1px solid #d0d7de; border-radius: 9px; background: #fff; }}
    .actions a:hover, .card-footer a:hover {{ text-decoration: underline; }}
    .meta {{ margin-top: 26px; color: #6e7781; font-size: 13px; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }}
    .card {{ display: flex; flex-direction: column; min-height: 174px; padding: 20px; border: 1px solid #d8dee4; border-radius: 14px; background: #fff; box-shadow: 0 2px 8px #1f23280a; }}
    .card-heading {{ display: flex; align-items: baseline; justify-content: space-between; gap: 12px; }}
    h2 {{ margin: 0; font-size: 18px; }}
    .card-heading span {{ flex: none; color: #6e7781; font-size: 12px; }}
    .id {{ margin: 7px 0 0; color: #6e7781; font: 12px ui-monospace, SFMono-Regular, Menlo, monospace; }}
    .card p:not(.id) {{ color: #4b5563; font-size: 14px; line-height: 1.65; }}
    .card-footer {{ margin-top: auto; padding-top: 14px; font-size: 13px; }}
    .empty {{ color: #6e7781; }}
    footer {{ margin-top: 42px; color: #6e7781; font-size: 12px; }}
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Tergo 在线插件目录</h1>
      <p class="lead">为 Tergo 终端提供经过校验的开发工作流插件。Tergo 客户端使用下面的 JSON 目录发现插件，并在安装前校验包的 SHA-256。</p>
      <div class="actions">
        <a href="catalog/index.json">查看目录 JSON</a>
        <a href="https://github.com/wfu-work/tergo-plugins">查看 GitHub 仓库</a>
      </div>
      <p class="meta">共 {len(cards)} 个插件 · 目录更新时间：{updated_at}</p>
    </header>
    <section class="grid" aria-label="插件列表">
      {cards_html}
    </section>
    <footer>Tergo Plugins · 由 GitHub Pages 发布</footer>
  </main>
</body>
</html>
'''
(site / "index.html").write_text(page, encoding="utf-8")
PY
printf 'built plugin site at %s\n' "$site_dir"

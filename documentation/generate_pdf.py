#!/usr/bin/env python3
"""
Convert XPLOORIA_V1_DOCUMENTATION.md to a styled HTML file,
then use macOS wkhtmltopdf / WeasyPrint / cupsfilter fallback to make a PDF.
"""

import os
import subprocess
import sys

MD_FILE = os.path.join(os.path.dirname(__file__), "XPLOORIA_V1_DOCUMENTATION.md")
HTML_FILE = os.path.join(os.path.dirname(__file__), "XPLOORIA_V1_DOCUMENTATION.html")
PDF_FILE = os.path.join(os.path.dirname(__file__), "XPLOORIA_V1_DOCUMENTATION.pdf")

# ── 1. Convert markdown → HTML ────────────────────────────────────────────────
try:
    import markdown
    from markdown.extensions.tables import TableExtension
    from markdown.extensions.toc import TocExtension
    from markdown.extensions.fenced_code import FencedCodeExtension
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "markdown", "-q"])
    import markdown
    from markdown.extensions.tables import TableExtension
    from markdown.extensions.toc import TocExtension
    from markdown.extensions.fenced_code import FencedCodeExtension

with open(MD_FILE, "r", encoding="utf-8") as f:
    md_text = f.read()

md = markdown.Markdown(extensions=[
    TableExtension(),
    TocExtension(toc_depth=3),
    FencedCodeExtension(),
    "nl2br",
    "sane_lists",
])
body_html = md.convert(md_text)

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Xplooria V1 — Product Documentation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

  :root {{
    --primary: #00E5A0;
    --secondary: #6C63FF;
    --accent: #FFB300;
    --bg: #0A0E1A;
    --surface: #121827;
    --elevated: #1C2333;
    --border: #2A3347;
    --text: #F0F4FF;
    --text2: #8892A4;
  }}

  * {{ box-sizing: border-box; margin: 0; padding: 0; }}

  body {{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: var(--bg);
    color: var(--text);
    font-size: 14px;
    line-height: 1.7;
    padding: 0;
  }}

  .cover {{
    background: linear-gradient(135deg, var(--bg) 0%, #0d1424 50%, #0a1520 100%);
    padding: 80px 60px 60px;
    border-bottom: 2px solid var(--primary);
    text-align: center;
    page-break-after: always;
  }}

  .cover-badge {{
    display: inline-block;
    background: var(--primary);
    color: #000;
    font-weight: 800;
    font-size: 11px;
    letter-spacing: 2px;
    text-transform: uppercase;
    padding: 6px 18px;
    border-radius: 20px;
    margin-bottom: 32px;
  }}

  .cover h1 {{
    font-size: 48px;
    font-weight: 900;
    letter-spacing: -1px;
    line-height: 1.1;
    margin-bottom: 8px;
    color: #fff;
  }}

  .cover h1 span {{ color: var(--primary); }}

  .cover-sub {{
    font-size: 18px;
    color: var(--text2);
    margin-bottom: 40px;
    font-weight: 500;
  }}

  .cover-meta {{
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    max-width: 700px;
    margin: 0 auto;
  }}

  .cover-meta-item {{
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 16px;
  }}

  .cover-meta-item .label {{
    font-size: 10px;
    font-weight: 700;
    color: var(--primary);
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 4px;
  }}

  .cover-meta-item .value {{
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
  }}

  .wrapper {{
    max-width: 900px;
    margin: 0 auto;
    padding: 48px 48px 80px;
  }}

  h1, h2, h3, h4 {{
    color: #fff;
    line-height: 1.3;
    font-weight: 700;
  }}

  h1 {{
    font-size: 32px;
    margin: 48px 0 16px;
    padding-bottom: 12px;
    border-bottom: 2px solid var(--primary);
    color: var(--primary);
  }}

  h2 {{
    font-size: 22px;
    margin: 36px 0 12px;
    color: #e8ecff;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--border);
  }}

  h3 {{
    font-size: 17px;
    margin: 28px 0 10px;
    color: var(--primary);
  }}

  h4 {{
    font-size: 14px;
    margin: 20px 0 8px;
    color: var(--text2);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }}

  p {{
    margin: 0 0 12px;
    color: var(--text);
  }}

  a {{ color: var(--primary); text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}

  ul, ol {{
    padding-left: 24px;
    margin-bottom: 12px;
  }}

  li {{
    margin-bottom: 4px;
    color: var(--text);
  }}

  strong {{ color: #fff; font-weight: 700; }}
  em {{ color: var(--primary); font-style: italic; }}

  blockquote {{
    border-left: 4px solid var(--primary);
    background: var(--surface);
    padding: 16px 20px;
    border-radius: 0 8px 8px 0;
    margin: 20px 0;
    color: var(--text2);
    font-size: 15px;
  }}

  blockquote p {{ color: var(--text2); margin: 0; }}

  code {{
    background: var(--elevated);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 2px 6px;
    font-family: 'SF Mono', 'Fira Code', 'Menlo', monospace;
    font-size: 12px;
    color: var(--primary);
  }}

  pre {{
    background: var(--elevated);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 20px;
    overflow-x: auto;
    margin: 16px 0;
  }}

  pre code {{
    background: none;
    border: none;
    padding: 0;
    color: #a8b4cc;
    font-size: 12px;
    line-height: 1.6;
  }}

  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
    font-size: 13px;
    border-radius: 10px;
    overflow: hidden;
  }}

  thead th {{
    background: var(--elevated);
    color: var(--primary);
    font-weight: 700;
    text-align: left;
    padding: 12px 14px;
    border-bottom: 2px solid var(--border);
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }}

  tbody tr {{
    border-bottom: 1px solid var(--border);
  }}

  tbody tr:nth-child(even) {{
    background: rgba(255,255,255,0.02);
  }}

  tbody td {{
    padding: 10px 14px;
    color: var(--text);
    vertical-align: top;
  }}

  hr {{
    border: none;
    border-top: 1px solid var(--border);
    margin: 32px 0;
  }}

  .section-break {{
    page-break-before: always;
  }}

  @media print {{
    body {{ background: #fff; color: #111; }}
    .cover {{ background: #fff; color: #111; border-bottom: 3px solid #00C991; }}
    .cover h1 {{ color: #111; }}
    .cover h1 span {{ color: #00C991; }}
    .wrapper {{ padding: 24px; }}
    h1 {{ color: #00C991; border-bottom-color: #00C991; }}
    h2 {{ color: #222; }}
    h3 {{ color: #00C991; }}
    pre, code, blockquote {{ background: #f5f5f5; color: #333; }}
    pre code {{ color: #333; }}
    table {{ border: 1px solid #ddd; }}
    thead th {{ background: #f0f0f0; color: #00A070; }}
    tbody td {{ color: #222; }}
  }}
</style>
</head>
<body>

<!-- ── Cover Page ─────────────────────────── -->
<div class="cover">
  <div class="cover-badge">Version 1 · April 2026</div>
  <h1><span>XPLOORIA</span></h1>
  <div class="cover-sub">Gamified Tourism Discovery & Community Platform<br/>Northeast India · iOS & Android</div>

  <div class="cover-meta">
    <div class="cover-meta-item">
      <div class="label">Platform</div>
      <div class="value">Flutter (iOS + Android)</div>
    </div>
    <div class="cover-meta-item">
      <div class="label">Backend</div>
      <div class="value">Firebase (spotmizoram)</div>
    </div>
    <div class="cover-meta-item">
      <div class="label">Company</div>
      <div class="value">HillsTech</div>
    </div>
    <div class="cover-meta-item">
      <div class="label">Features</div>
      <div class="value">61+ Screens · 50+ Routes</div>
    </div>
    <div class="cover-meta-item">
      <div class="label">State Management</div>
      <div class="value">Riverpod 3</div>
    </div>
    <div class="cover-meta-item">
      <div class="label">Version</div>
      <div class="value">1.0 Release</div>
    </div>
  </div>
</div>

<!-- ── Main Content ────────────────────────── -->
<div class="wrapper">
{body_html}
</div>

</body>
</html>
"""

with open(HTML_FILE, "w", encoding="utf-8") as f:
    f.write(html)

print(f"✅ HTML generated: {HTML_FILE}")

# ── 2. Convert HTML → PDF ─────────────────────────────────────────────────────
pdf_generated = False

# Try wkhtmltopdf
if not pdf_generated:
    try:
        result = subprocess.run(
            ["wkhtmltopdf",
             "--page-size", "A4",
             "--margin-top", "15mm",
             "--margin-bottom", "15mm",
             "--margin-left", "15mm",
             "--margin-right", "15mm",
             "--enable-local-file-access",
             "--print-media-type",
             "--quiet",
             HTML_FILE, PDF_FILE],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode == 0:
            pdf_generated = True
            print(f"✅ PDF generated via wkhtmltopdf: {PDF_FILE}")
    except Exception as e:
        print(f"wkhtmltopdf not available: {e}")

# Try WeasyPrint
if not pdf_generated:
    try:
        import weasyprint
        weasyprint.HTML(filename=HTML_FILE).write_pdf(PDF_FILE)
        pdf_generated = True
        print(f"✅ PDF generated via WeasyPrint: {PDF_FILE}")
    except ImportError:
        print("WeasyPrint not installed, trying to install...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "weasyprint", "-q"],
                                  timeout=120)
            import weasyprint
            weasyprint.HTML(filename=HTML_FILE).write_pdf(PDF_FILE)
            pdf_generated = True
            print(f"✅ PDF generated via WeasyPrint: {PDF_FILE}")
        except Exception as e:
            print(f"WeasyPrint failed: {e}")
    except Exception as e:
        print(f"WeasyPrint error: {e}")

# Try cupsfilter (macOS built-in)
if not pdf_generated:
    try:
        result = subprocess.run(
            ["cupsfilter", "-e", HTML_FILE, "-o", PDF_FILE],
            capture_output=True, text=True, timeout=60
        )
        if result.returncode == 0:
            pdf_generated = True
            print(f"✅ PDF generated via cupsfilter: {PDF_FILE}")
    except Exception as e:
        print(f"cupsfilter failed: {e}")

# Fallback: open the HTML in Safari and let macOS handle print-to-PDF
if not pdf_generated:
    print("\\n⚠️  Automatic PDF generation was not possible.")
    print("To create the PDF manually on macOS:")
    print(f"  1. Open: {HTML_FILE}")
    print(f"  2. Press Cmd+P → Save as PDF → {PDF_FILE}")
    os.system(f'open "{HTML_FILE}"')

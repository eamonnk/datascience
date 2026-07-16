#!/usr/bin/env python3
"""
Convert one or more plain .R scripts into Quarto (.qmd) documents that will
render nicely as pages on the portfolio site, complete with the YAML front
matter the Projects listing page needs (title, description, date, categories).

Usage:
    python scripts/convert_r_to_qmd.py path/to/script1.R path/to/script2.R
    python scripts/convert_r_to_qmd.py r-raw/*.R          # convert a whole folder

Output:
    Writes a .qmd file next to each input, into r-projects/, named after the
    original script (my-analysis.R -> r-projects/my-analysis.qmd).

Notes:
    - This is a simple wrapper: your whole script becomes ONE code chunk. If
      you'd rather split it into narrative sections (## Data, ## Model, ##
      Results) with separate chunks and markdown commentary between them,
      do that by hand afterwards -- it reads much better for a portfolio.
    - Comments in your R script starting with "# ---" or "#### " are treated
      as section headers and lifted out as markdown headings automatically.
"""
import sys
import re
from pathlib import Path
from datetime import date

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "r-projects"

HEADER_TEMPLATE = """---
title: "{title}"
description: "TODO: one-sentence summary of the problem and what you found."
date: "{today}"
categories: [R]
format:
  html:
    code-fold: true
---

"""


def split_into_sections(r_code: str):
    """
    Very simple heuristic splitter: treats comment lines that look like
    section headers (e.g. "# --- Data cleaning ---" or "#### Modelling")
    as markdown headings, and groups the R code between them into chunks.
    Falls back to a single chunk if no such headers are found.
    """
    header_pattern = re.compile(r"^#{2,}\s*-*\s*(.+?)\s*-*\s*$")
    lines = r_code.splitlines()
    sections = []
    current_title = None
    current_lines = []

    for line in lines:
        m = header_pattern.match(line.strip())
        if m and len(m.group(1)) > 2:
            if current_lines and any(l.strip() for l in current_lines):
                sections.append((current_title, current_lines))
            current_title = m.group(1).strip("# -")
            current_lines = []
        else:
            current_lines.append(line)

    if current_lines and any(l.strip() for l in current_lines):
        sections.append((current_title, current_lines))

    if not sections:
        sections = [(None, lines)]

    return sections


def convert_file(r_path: Path):
    r_code = r_path.read_text(encoding="utf-8")
    title = r_path.stem.replace("_", " ").replace("-", " ").title()
    today = date.today().isoformat()

    body_parts = [HEADER_TEMPLATE.format(title=title, today=today)]

    sections = split_into_sections(r_code)
    for i, (section_title, code_lines) in enumerate(sections):
        code = "\n".join(code_lines).strip("\n")
        if not code.strip():
            continue
        if section_title:
            body_parts.append(f"## {section_title}\n\n")
        body_parts.append(f"```{{r}}\n#| label: chunk-{i+1}\n{code}\n```\n\n")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUT_DIR / (r_path.stem + ".qmd")
    out_path.write_text("".join(body_parts), encoding="utf-8")
    print(f"Wrote {out_path}")
    print("  -> Open it and fill in the TODO description, adjust categories,")
    print("     and add markdown commentary between chunks if you'd like.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    for arg in sys.argv[1:]:
        p = Path(arg)
        if not p.exists():
            print(f"Skipping {p}: not found")
            continue
        if p.suffix.lower() != ".r":
            print(f"Skipping {p}: not a .R file")
            continue
        convert_file(p)


if __name__ == "__main__":
    main()

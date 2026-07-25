#!/usr/bin/env python3
"""
Convert one or more Jupyter notebooks (.ipynb) into Quarto (.qmd) documents.

Usage:

    python scripts/convert_ipynb_to_qmd.py notebooks/*.ipynb

Output:

    py-projects/<notebook-name>.qmd
"""

from pathlib import Path
from datetime import date
import json
import sys

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "py-projects"

HEADER_TEMPLATE = """---
title: "{title}"
description: "TODO: one-sentence summary."
date: "{today}"
categories: [Python]
format:
  html:
    code-fold: true
    toc: true
jupyter: python3
---

"""


def clean_title(filename):
    return (
        filename.replace("_", " ")
        .replace("-", " ")
        .replace("&", "and")
        .title()
    )


def convert_notebook(ipynb_path: Path):

    with open(ipynb_path, encoding="utf-8") as f:
        notebook = json.load(f)

    title = clean_title(ipynb_path.stem)
    today = date.today().isoformat()

    parts = [
        HEADER_TEMPLATE.format(
            title=title,
            today=today
        )
    ]

    for cell in notebook["cells"]:

        source = "".join(cell.get("source", []))

        if cell["cell_type"] == "markdown":

            parts.append(source)
            parts.append("\n\n")

        elif cell["cell_type"] == "code":

            parts.append(
                "```{python}\n"
                "#| echo: true\n"
                "#| warning: false\n"
                "#| message: false\n"
            )

            parts.append(source.rstrip())
            parts.append("\n```\n\n")

    OUTPUT_DIR.mkdir(exist_ok=True)

    out_file = OUTPUT_DIR / (ipynb_path.stem + ".qmd")

    out_file.write_text(
        "".join(parts),
        encoding="utf-8"
    )

    print(f"Wrote {out_file}")


def main():

    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    for arg in sys.argv[1:]:

        p = Path(arg)

        if not p.exists():
            print(f"Skipping {p}: not found")
            continue

        # If a directory is supplied, convert every notebook in it
        if p.is_dir():
            notebooks = sorted(p.rglob("*.ipynb"))

            if not notebooks:
                print(f"No notebooks found in {p}")
                continue

            for nb in notebooks:
                convert_notebook(nb)

        # If a single notebook is supplied
        elif p.suffix.lower() == ".ipynb":
            convert_notebook(p)

        else:
            print(f"Skipping {p}: not an .ipynb file or directory")

if __name__ == "__main__":
    main()
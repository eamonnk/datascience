# MSc Portfolio Site (Quarto + GitHub Pages)

A ready-to-go [Quarto](https://quarto.org) website that renders your `.ipynb`
notebooks and R analyses directly into a browsable portfolio, auto-published
via GitHub Actions every time you push. **You do not need Quarto, R, or
Jupyter installed locally** — GitHub's servers do the rendering.

## What's in here

```
_quarto.yml              site config (nav, theme, title — edit the placeholders)
index.qmd                homepage
projects.qmd             auto-generated listing of everything in notebooks/ + r-projects/
about.qmd                your background/CV page
styles.css                small visual tweaks
notebooks/                <- put your .ipynb files here
r-projects/               <- put your R work here, as .qmd (see below)
scripts/convert_r_to_qmd.py   helper to turn a plain .R script into a .qmd page
files/                    optional: CV PDF or other downloads
.github/workflows/publish.yml   the automation that builds + deploys the site
```

## Step-by-step: live today

### 1. Create the GitHub repo
- Go to github.com → New repository → give it a name (e.g. `msc-portfolio`) →
  **Public** (Pages on a free account needs the repo to be public, unless you
  have GitHub Pro/Team/Enterprise) → Create repository (don't add a README,
  you already have one here).

### 2. Add these files to the repo
Easiest via command line, from inside this folder:
```bash
git init
git add .
git commit -m "Initial portfolio site"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
git push -u origin main
```
(Or: drag-and-drop everything into the repo via the GitHub web UI — "Add
file" → "Upload files" — if you'd rather not use git directly. Make sure
hidden folders like `.github/` come along; the web upload UI does preserve
folder structure when you drag a whole folder in.)

### 3. Drop in your real files
- Copy your `.ipynb` notebooks into `notebooks/`.
- For R: either
  - run `python3 scripts/convert_r_to_qmd.py path/to/your-script.R` locally
    (needs only Python, no R/Quarto required) — it writes a matching `.qmd`
    into `r-projects/`, or
  - hand-convert following the pattern in `r-projects/example-analysis.qmd`.
- **Delete the two example files** (`notebooks/example-notebook.ipynb`,
  `r-projects/example-analysis.qmd`) once you have real content in, or leave
  them if you want placeholder content for now.
- Each notebook/qmd needs a small metadata header for the listing page to
  show a proper title/description/date/category — see the examples for the
  exact format (a raw cell at the top of `.ipynb` files, YAML front matter at
  the top of `.qmd` files).

### 4. Edit the placeholders
In `_quarto.yml`, `index.qmd`, and `about.qmd`, replace:
- `Your Name` / `Your Name — MSc Portfolio`
- `YOUR-GH-USERNAME`, `YOUR-REPO-NAME`, `YOUR-LINKEDIN`
- the About page education/experience placeholders

### 5. Commit and push
```bash
git add .
git commit -m "Add real projects"
git push
```
This triggers the GitHub Action (see Actions tab in your repo — you can watch
it run). It installs Quarto, Python/Jupyter, and R, renders every page, and
pushes the built site to a `gh-pages` branch. Takes ~2–4 minutes.

### 6. Turn on GitHub Pages
- Repo → **Settings → Pages**
- Source: **Deploy from a branch**
- Branch: **gh-pages** / **/(root)** → Save
  (the `gh-pages` branch only appears after step 5's Action has run once —
  refresh the dropdown if you don't see it yet)
- Repo → **Settings → Actions → General → Workflow permissions** → make sure
  **"Read and write permissions"** is selected (needed so the Action can push
  to `gh-pages`) → Save, then re-run the Action from the Actions tab if it
  failed on the first try because of this.

Your site will be live at:
```
https://YOUR-USERNAME.github.io/YOUR-REPO-NAME/
```

## Ongoing use
Every time you `git push` a new notebook or `.qmd` to `main`, the site
rebuilds and redeploys automatically — no manual steps needed.

## Troubleshooting
- **Action fails on R packages**: some R packages take a while to compile on
  first run (~5–10 min) — this is normal for `tidyverse`. Subsequent runs are
  cached and much faster.
- **Notebook fails to execute in Actions but runs fine for you locally**:
  usually a missing package or a missing data file. Add the package to the
  `pip install` line in `.github/workflows/publish.yml`, and make sure any
  data files the notebook reads are committed to the repo with a relative
  path (not an absolute path like `/Users/you/...`).
- **Don't want notebooks re-executed on every build** (e.g. they're slow, or
  you already have the outputs saved): add this to the top of that notebook's
  raw YAML cell:
  ```yaml
  execute:
    enabled: false
  ```
  Quarto will then just format the existing saved outputs rather than re-run
  the code.
- **Want to preview locally before pushing** (optional, not required): install
  [Quarto](https://quarto.org/docs/get-started/) and run `quarto preview`
  from this folder.

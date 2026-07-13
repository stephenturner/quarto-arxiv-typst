# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Quarto extension that renders documents to arXiv-preprint-style PDF (the layout the NeurIPS style files established) through Typst, with no LaTeX involved. There is no application code and no test suite. The deliverable is the `_extensions/arxiv/` directory; `template.qmd` is both the starter document that `quarto use template` copies and the only test fixture.

Deployment is pushing this repo to GitHub as `<user>/quarto-arxiv-typst`; `quarto add` installs `_extensions/` only, while `quarto use template` also copies the root starter files (`template.qmd`, `references.bib`, `loss-curve.svg`). Those three root files must stay in sync with what the extension supports. Releases are a `version` bump in `_extension.yml` plus a git tag.

The Typst template is adapted from [daskol/typst-templates](https://github.com/daskol/typst-templates) (MIT), merged into one self-contained file with the entry point renamed to `arxiv`.

The format id is `arxiv-typst`, derived by Quarto as `<extension-dir>-<base-format>` from the `_extensions/arxiv` directory. It cannot be changed to `typst-arxiv` or anything else starting with a base format name: that breaks Quarto's format resolution (the template partials are silently dropped and renders fail with `unknown variable: appendix`). Tested on 2026-07-13; keep the directory name prefix free of `typst`.

## Prose in this repo

Never hard-wrap markdown or qmd source. `README.md`, `CLAUDE.md`, and `template.qmd` keep each paragraph, list item, and caption on one line, however long. If an edit leaves a paragraph split across lines, rejoin it.

## Commands

Rendering the fixture is the test. A full render takes about two seconds, so run both modes after any template change:

```bash
quarto render template.qmd --to arxiv-typst
quarto render template.qmd --to arxiv-typst -M anonymous:true --output submission.pdf
```

A render with `--output somefile.pdf` deletes the previously rendered `template.pdf`; re-run the plain render afterwards to restore it. Verify changes visually by rasterizing pages (`pdftoppm -png -r 150 template.pdf page`) and reading the images, not just by checking that the render exits cleanly.

To debug template changes, keep the generated Typst and read it:

```bash
quarto render template.qmd --to arxiv-typst -M keep-typ:true   # writes template.typ
```

Renders are expected to be completely warning-free. The body font (TeX Gyre Termes) is bundled in `_extensions/arxiv/fonts/` and wired up via `font-paths` in `_extension.yml`, so "unknown font family" warnings never come from the template. If font or `invalid font weight` warnings appear, the source is document code, typically gt emitting its web font stack or its default stub weight `initial`; fix those in the chunk with `gt::tab_options(table.font.names = ..., stub.font.weight = "normal")`, not in the template.

## Architecture

Quarto assembles a single `.typ` file from three sources at render time, in this order:

1. `_extensions/arxiv/typst-template.typ` becomes the preamble. It defines the `arxiv()` show-rule function plus the helpers the document can call (`toprule`/`midrule`/`botrule`, `#paragraph[...]`, `#url("...")`, `#show: appendix`).
2. `_extensions/arxiv/typst-show.typ` becomes the `#show: doc => arxiv(...)` call. This is a **Pandoc template**, not Typst source: the `$if(...)$` / `$for(...)$` syntax is Pandoc's, and it is what maps Quarto's metadata into `arxiv()` arguments. Author and affiliation plumbing lives here, iterating Quarto's normalized `by-author` and `by-affiliation` lists. Standard Quarto typst options (`papersize`, `margin`, `section-numbering`, `toc`/`toc-title`/`toc-depth`) pass through here into `arxiv()` parameters, whose signature holds the defaults; an option quarto documents for the typst format only works in this format if it is plumbed through. It also installs the `show label("refs")` rule that relocates the bibliography (see below).
3. The document body, followed by `_extensions/arxiv/biblio.typ`, our override of Quarto's stock bibliography partial.

`_extension.yml` wires 1 and 2 in as `template-partials` of the built-in `typst` format, ships `natbib.csl` as a `format-resource`, and registers `fonts/` (TeX Gyre Termes) through `font-paths`, which Quarto resolves relative to the extension directory.

Understanding a bug usually means knowing which of these three layers produced the offending line, so reach for `keep-typ` early.

### Mode and notice handling

There is no accepted/camera-ready logic; it was removed deliberately, so do not reintroduce it. `notice` is a plain parameter, default `[Preprint. Under review.]`, rendered centered in the first-page footer (later pages get the page number instead). Users set `notice` in the metadata to whatever their venue wants.

`anonymous: true` swaps the whole author tuple for "Anonymous Author(s)" before anything author-derived is rendered, which is why ORCID badges, author-note footnotes, and emails all vanish in that mode without any extra guards. It also turns line numbers on; `lineno` overrides that default in either direction.

`hide-emails: true` removes only the email row under the affiliations. The correspondence footnote always renders "Name \<email\>" for corresponding authors, on the theory that institutional usernames (sdt5z@virginia.edu) identify nobody without the name attached; the supported way to keep an address off the page entirely is omitting `email:` from that author's YAML entry.

### Quarto-specific workarounds in the template

These exist because Quarto's Typst output differs from hand-written Typst. Do not simplify them away.

- **Duplicate affiliations.** When an author references an affiliation by `id` alone, Quarto emits that id twice, once with data and once empty. `normalize-affls` folds the pairs and keeps the entry that has data.
- **Emails are content, not strings.** A bare `@` inside a Typst string literal breaks, so `typst-show.typ` passes emails as `[content]` and `content-to-string` recovers the address to build the `mailto:` link.
- **Float kinds.** Quarto wraps floats in its own kinds (`"quarto-float-fig"`, `"quarto-float-tbl"`), so every figure show-rule is written twice, once for the native Typst kind and once for the Quarto kind. Dropping the Quarto variants silently loses the caption styling on everything authored in Markdown.
- **Bibliography style.** The template calls `set std.bibliography(style: "natbib.csl")`. Quarto emits its own `#set bibliography(...)` later in the file, which is why a user's `bibliographystyle` metadata wins.
- **Author-note footnotes.** The equal-contribution (*) and correspondence (†) notes are real Typst footnotes created invisibly: `box(width: 0pt, hide(footnote(...)))` with a symbol `numbering` function, followed by `counter(footnote).update(0)` so document footnotes still start at 1. The visible superscript marks next to author names are drawn separately in `format-author-name`, with affiliation indices sorted numerically so a multi-affiliation author never shows "3 2".
- **Bibliography placement.** An empty `::: {#refs}` div in the document becomes `#block[] <refs>` in the Typst output. `typst-show.typ` installs `show label("refs")` to render `std.bibliography(...)` at that anchor (this is how references land before the appendix), and our `biblio.typ` wraps the stock end-of-document emission in `context if query(label("refs")).len() == 0 { ... }` so exactly one bibliography ever exists. Typst hard-errors on two bibliographies, so any change here must keep the two sides mutually exclusive. The anchor rule lives in `typst-show.typ` rather than `biblio.typ` because show rules only affect content after them, and `biblio.typ` is concatenated after the body.

### natbib.csl exists twice

`_extensions/arxiv/natbib.csl` is the source of truth. The copy at the repository root is the render-time artifact that Quarto's `format-resources` drops next to the document, and it is overwritten on every render. Edit the one under `_extensions/`.

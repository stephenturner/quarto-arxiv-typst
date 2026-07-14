// arXiv preprint-style Typst template for Quarto.
//
// Adapted from https://github.com/daskol/typst-templates (MIT license),
// merged into a single self-contained file with the entry point renamed
// to `arxiv` and metadata plumbing adjusted for Quarto.

// ---------------------------------------------------------------------------
// Font configuration
// ---------------------------------------------------------------------------

#let font-defaults = (
  tiny: 7pt,
  scriptsize: 7pt,
  footnotesize: 9pt,
  small: 9pt,
  normalsize: 10pt,
  large: 14pt,
  Large: 16pt,
  LARGE: 20pt,
  huge: 23pt,
  Huge: 28pt,
)

// Times (Type-1) in the original style. TeX Gyre Termes is its free
// OpenType descendant and ships with this extension (see fonts/ and the
// font-paths entry in _extension.yml), so it is always available and the
// output is identical across machines. Override with `mainfont`.
#let font-family = ("TeX Gyre Termes",)

#let font-config-default() = (
  family: (serif: font-family),
  size: (
    Large: font-defaults.Large,
    footnote: font-defaults.footnotesize,
    large: font-defaults.large,
    small: font-defaults.small,
    normal: font-defaults.normalsize,
    script: font-defaults.scriptsize,
    title: 17pt,
    subtitle: 13pt,
    section: 12pt,
    abstract-title: 12pt,
    notice: 9pt,
    line-number: 7pt,
  ),
)

#let font-config-merge(font-config) = {
  let fc = font-config-default()
  if "family" in font-config {
    fc.family = fc.family + font-config.family
  }
  if "size" in font-config {
    fc.size = fc.size + font-config.size
  }
  return fc
}

// ---------------------------------------------------------------------------
// Figures
// ---------------------------------------------------------------------------

#let make_figure_caption(fc, it) = {
  set align(center)
  block(context {
    set align(left)
    set text(size: fc.size.normal)
    it.supplement
    if it.numbering != none {
      [ ]
      it.counter.display(it.numbering)
    }
    it.separator
    [ ]
    it.body
  })
}

#let make_figure(caption_above: false, fc, it) = {
  let body = block(width: 100%, {
    set align(center)
    set text(size: fc.size.normal)
    if caption_above {
      v(1em, weak: true)
      it.caption
    }
    v(1em, weak: true)
    it.body
    v(8pt, weak: true)
    if not caption_above {
      it.caption
      v(1em, weak: true)
    }
  })

  if it.placement == none {
    return body
  } else {
    return place(it.placement, body, float: true, clearance: 2.3em)
  }
}

// ---------------------------------------------------------------------------
// Authors and affiliations
// ---------------------------------------------------------------------------

#let anonymous-author = (
  name: "Anonymous Author(s)",
  email: "anon.email@example.org",
  affl: ("anonymous-affl",),
)

#let anonymous-affl = (
  department: none,
  institution: "Affiliation",
  location: "Address",
)

#let format-author-names(authors) = {
  authors.map(author => author.name)
}

// Affiliations may arrive as a dictionary or as an array of (key, value)
// pairs. Quarto can emit the same affiliation id twice (once with data,
// once empty) when an author references it by id alone; fold pairs into a
// dictionary keeping the entry that actually has data.
#let normalize-affls(affls) = {
  if type(affls) == dictionary {
    return affls
  }
  let acc = (:)
  for (key, val) in affls {
    if key not in acc or val.len() > 0 {
      acc.insert(key, val)
    }
  }
  return acc
}

// Recover a plain string from simple content (text runs and escapes), so
// emails passed as content can still become mailto links.
#let content-to-string(c) = {
  if type(c) == str {
    c
  } else if c.has("text") {
    c.text
  } else if c.has("children") {
    c.children.map(content-to-string).join("")
  } else if c.has("child") {
    content-to-string(c.child)
  } else if c.func() == space {
    " "
  } else {
    ""
  }
}

// Emails arrive from Quarto as content (strings would choke on the escaped
// `@` inside a Typst string literal).
#let format-email(email) = {
  if email == none {
    return none
  }
  let addr = content-to-string(email)
  if addr == "" {
    email
  } else {
    link("mailto:" + addr, raw(addr))
  }
}

// Small linked ORCID iD badge (green disc, white "iD").
#let orcid-icon(orcid) = {
  link("https://orcid.org/" + orcid, box(height: 0.85em, baseline: 12%,
    circle(radius: 0.425em, fill: rgb("#A6CE39"),
      align(center + horizon,
        text(fill: white, weight: "bold", size: 0.55em, [iD])))))
}

#let is-corresponding(author) = {
  "corresponding" in author and author.corresponding
}

#let is-equal-contributor(author) = {
  "equal-contributor" in author and author.at("equal-contributor")
}

#let format-author-name(author, affl2idx, affilated: false) = {
  let affl = author.at("affl")
  if type(affl) == str {
    affl = (affl,)
  }
  let result = strong(author.name)
  if "orcid" in author {
    result += h(0.075em) + orcid-icon(author.orcid)
  }
  let marks = ()
  if affilated {
    marks = affl.map(it => affl2idx.at(it)).sorted().map(str)
  }
  if is-equal-contributor(author) {
    marks.push("*")
  }
  if is-corresponding(author) {
    marks.push("\u{2020}")
  }
  if marks.len() > 0 {
    result += super(typographic: false, marks.join(" "))
  }
  return box(result)
}

#let format-affiliation(affl) = {
  assert(affl.len() > 0, message: "Affiliation must be non-empty.")

  let affiliation = ""
  if type(affl) == array {
    affiliation = affl.join(", ")
  } else if type(affl) == dictionary {
    let terms = ()
    if "department" in affl and affl.department != none {
      terms.push(affl.department)
    }
    if "institution" in affl and affl.institution != none {
      terms.push(affl.institution)
    }
    if "location" in affl and affl.location != none {
      terms.push(affl.location)
    }
    if "country" in affl and affl.country != none {
      terms.push(affl.country)
    }
    affiliation = terms.filter(it => it.len() > 0).join(", ")
  } else {
    assert(false, message: "Unexpected execution branch.")
  }

  return affiliation
}

#let make-single-author(author, affls, affl2idx, hide-emails: false) = {
  let affl = author.at("affl")
  if type(affl) == str {
    affl = (affl,)
  }

  let name = format-author-name(author, affl2idx)
  let affiliation = affl
    .map(it => format-affiliation(affls.at(it)))
    .map(it => box(it))
    .join(" ")

  let lines = (name, affiliation)
  if not hide-emails and "email" in author and author.email != none {
    lines.push(box(format-email(author.email)))
  }

  let body = lines.filter(it => it != none).join([\ ])
  return align(center, body)
}

#let make-two-authors(authors, affls, affl2idx, hide-emails: false) = {
  let row = authors
    .map(it => make-single-author(it, affls, affl2idx, hide-emails: hide-emails))
    .map(it => box(it))
  return align(center, grid(columns: (1fr, 1fr), gutter: 2em, ..row))
}

#let make-many-authors(authors, affls, affl2idx, hide-emails: false) = {
  let format-affl(affls, key, index) = {
    let affl = affls.at(key)
    let affiliation = format-affiliation(affl)
    let entry = super(typographic: false, [#index]) + affiliation
    return box(entry)
  }

  let names = authors
    .map(it => format-author-name(it, affl2idx, affilated: true))

  let affiliations = affl2idx
    .pairs()
    .map(it => format-affl(affls, ..it))

  let emails = if hide-emails {
    ()
  } else {
    authors
      .filter(it => "email" in it and it.email != none)
      .map(it => box(format-email(it.email)))
  }

  let paragraphs = (names, affiliations, emails)
    .filter(it => it.len() > 0)
    .map(it => it.join(h(1em, weak: true)))
    .join([#parbreak() ])

  return align(center, {
    pad(left: 1em, right: 1em, paragraphs)
  })
}

#let make-authors(authors, affls, hide-emails: false) = {
  let ordered-affls = authors.map(it => it.affl).flatten().dedup()
  let affl2idx = ordered-affls.enumerate(start: 1).fold((:), (acc, it) => {
    let (ix, affl) = it
    acc.insert(affl, ix)
    return acc
  })

  if authors.len() == 0 {
    return none
  } else if authors.len() == 1 {
    return make-single-author(authors.at(0), affls, affl2idx, hide-emails: hide-emails)
  } else if authors.len() == 2 {
    return make-two-authors(authors, affls, affl2idx, hide-emails: hide-emails)
  } else {
    return make-many-authors(authors, affls, affl2idx, hide-emails: hide-emails)
  }
}

// ---------------------------------------------------------------------------
// Helpers usable from raw typst blocks in the document
// ---------------------------------------------------------------------------

// Booktabs-style rules for tables.
#let botrule = table.hline(stroke: (thickness: 0.08em))
#let midrule = table.hline(stroke: (thickness: 0.05em))
#let toprule = botrule

// Run-in paragraph heading.
#let paragraph(body) = {
  parbreak()
  [*#body*]
  h(1em, weak: true)
}

// External link in monospace font.
#let url(uri) = {
  return link(uri, raw(uri))
}

// Switch the rest of the document into appendix mode:
//   #show: appendix
//   = First Appendix Section   // rendered as "A  First Appendix Section"
// Add #pagebreak(weak: true) before the show rule to start the appendix
// on a fresh page; the numbering switch itself does not force one.
#let appendix(body) = {
  set heading(numbering: "A.1")
  counter(heading).update(0)
  body
}

// ---------------------------------------------------------------------------
// Main template
// ---------------------------------------------------------------------------

/**
 * arxiv
 *
 * Args:
 *   subtitle: Optional second line, italic, under the title and inside the
 *   rules.
 *   date: Optional date line, centered under the authors.
 *   anonymous: Replaces authors with "Anonymous Author(s)" and turns on
 *   line numbers (submission mode).
 *   notice: Text of the first-page footer notice. None leaves the first-page
 *   footer empty.
 *   lineno: Overrides the line-numbering default (on when anonymous).
 *   table-stripes: Shades alternating table body rows light gray; the
 *   header row stays unshaded.
 *   paper, margin, sectionnumbering, toc, toc-title, toc-depth: Standard
 *   Quarto typst options (papersize, margin, section-numbering, toc,
 *   toc-title, toc-depth), passed through from document metadata.
 *   font-config: Font family and size overrides.
 */
#let arxiv(
  title: [],
  subtitle: none,
  authors: ((), (:)),
  keywords: (),
  date: none,
  abstract: none,
  anonymous: false,
  notice: none,
  lineno: none,
  hide-emails: false,
  table-stripes: false,
  paper: "us-letter",
  margin: (x: 1in, y: 1in),
  sectionnumbering: "1.1",
  toc: false,
  toc-title: none,
  toc-depth: none,
  font-config: (:),
  body,
) = {
  let fc = font-config-merge(font-config)

  // Anonymize for submission.
  if anonymous {
    authors = ((anonymous-author,), (anonymous-affl: anonymous-affl))
  }
  let (authors, affls) = authors
  let affls = normalize-affls(affls)

  set document(
    title: title,
    author: format-author-names(authors),
    keywords: keywords,
    // Quarto hands `date` over as a string, which set document rejects.
    date: if type(date) == datetime { date } else { auto },
  )

  set page(
    paper: paper,
    margin: margin,
    footer-descent: 25pt - fc.size.normal,
    footer: context {
      let i = counter(page).at(here()).first()
      if i == 1 {
        // No notice means no first-page footer at all.
        if notice != none {
          return align(center, text(size: fc.size.notice, [#notice]))
        }
      } else {
        return align(center, text(size: fc.size.normal, [#i]))
      }
    },
  )

  set par(justify: true, leading: 0.55em)
  set text(font: fc.family.serif, size: fc.size.normal)

  // Quotations, similar to LaTeX's `quoting` package.
  show quote: set align(left)
  show quote: set pad(x: 4em)
  show quote: set block(spacing: 1em)

  // Code snippet spacing as in the original LaTeX.
  show raw.where(block: true): set block(spacing: 14pt)

  // Bullet lists.
  show list: set block(spacing: 15pt)
  set list(indent: 30pt, spacing: 8.5pt)

  // Footnotes.
  set footnote.entry(
    separator: line(length: 2in, stroke: 0.5pt),
    clearance: 6.65pt,
    indent: 12pt)

  // Headings.
  set heading(numbering: sectionnumbering)
  show heading: it => {
    let number = if it.numbering != none {
      counter(heading).display(it.numbering)
    }

    set align(left)
    let gap = h(1em, weak: true)
    if it.level == 1 {
      text(size: fc.size.section, weight: "bold", {
        let ex = 7.95pt
        v(2.7 * ex, weak: true)
        [#number #gap *#it.body*]
        v(2 * ex, weak: true)
      })
    } else if it.level == 2 {
      text(size: fc.size.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.70 * ex, weak: true)
        [#number #gap *#it.body*]
        v(2.03 * ex, weak: true)
      })
    } else {
      text(size: fc.size.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.6 * ex, weak: true)
        [#number #gap *#it.body*]
        v(1.8 * ex, weak: true)
      })
    }
  }

  // Figures and tables. Quarto emits floats with its own kinds
  // ("quarto-float-fig", "quarto-float-tbl"), so style those alongside the
  // native Typst kinds for documents that mix in raw Typst figures.
  set figure.caption(separator: [:])
  show figure: set block(breakable: false)
  show figure.caption.where(kind: table): it => make_figure_caption(fc, it)
  show figure.caption.where(kind: image): it => make_figure_caption(fc, it)
  show figure.caption.where(kind: "quarto-float-fig"): it => make_figure_caption(fc, it)
  show figure.caption.where(kind: "quarto-float-tbl"): it => make_figure_caption(fc, it)
  show figure.where(kind: image): it => make_figure(fc, it)
  show figure.where(kind: table): it => make_figure(fc, it, caption_above: true)
  show figure.where(kind: "quarto-float-fig"): it => make_figure(fc, it)
  show figure.where(kind: "quarto-float-tbl"): it => make_figure(fc, it, caption_above: true)

  // Booktabs-style tables: no vertical rules or cell borders, a heavy rule
  // above the header and below the last row, and a light rule under the
  // header. Every cell claims a heavy bottom stroke, but on interior edges
  // the cell below wins with its explicit top stroke, so the heavy rule
  // survives only on the table's bottom edge, where no cell overrides it.
  set table(
    stroke: (x, y) => (
      top: if y == 0 { 0.08em + black } else if y == 1 { 0.05em + black } else { 0pt },
      bottom: 0.08em + black,
    ),
    inset: (x: 8pt, y: 4pt),
  )
  show table.cell.where(y: 0): strong
  set table(fill: (_, y) => if y > 0 and calc.even(y) { luma(245) }) if table-stripes

  // Math equation numbering and referencing.
  set math.equation(numbering: "(1)")
  show ref: it => {
    let eq = math.equation
    let el = it.element
    if el != none and el.func() == eq {
      let numb = numbering("1", ..counter(eq).at(el.location()))
      let color = rgb(0%, 8%, 45%)
      let content = link(el.location(), text(fill: color, numb))
      [(#content)]
    } else {
      return it
    }
  }

  // References list styling (applies to the bibliography Quarto appends at
  // the end of the document). natbib.csl ships with the format and is
  // copied next to the document at render time; setting `bibliographystyle`
  // in the document metadata overrides this because Quarto emits its own
  // `#set bibliography(style: ...)` later.
  show std.bibliography: set text(size: fc.size.small)
  set std.bibliography(title: [References], style: "natbib.csl")

  // Title.
  block(width: 100%, {
    let top-rule-width = 4pt
    let bot-rule-width = 1pt

    v(0.1in + top-rule-width / 2)
    line(length: 100%, stroke: top-rule-width + black)
    align(center, text(size: fc.size.title, weight: "bold", [#title]))
    if subtitle != none {
      v(-0.15in)
      align(center, text(size: fc.size.subtitle, style: "italic", [#subtitle]))
      v(0.05in)
    }
    v(-bot-rule-width)
    line(length: 100%, stroke: bot-rule-width + black)
  })

  v(0.25in)

  // Authors.
  block(width: 100%, {
    set text(size: fc.size.normal)
    set par(leading: 4.5pt)
    set block(spacing: 1.0em)
    make-authors(authors, affls, hide-emails: hide-emails)

    // Equal-contribution (*) and correspondence (†) notes become symbol
    // footnotes at the bottom of the first page, above the notice, like
    // LaTeX \thanks. The in-text marks are hidden (the superscripts next
    // to the author names serve that role), and the footnote counter is
    // reset afterwards so regular document footnotes still start at 1.
    // Nothing renders when no author carries either flag.
    let equals = authors.filter(is-equal-contributor)
    let correspondents = authors.filter(is-corresponding)
    let marks = ()
    let notes = ()
    if equals.len() > 0 {
      marks.push("*")
      notes.push([These authors contributed equally.])
    }
    if correspondents.len() > 0 {
      marks.push("\u{2020}")
      notes.push({
        [Correspondence to ]
        correspondents
          .map(a => {
            // Always name plus email: bare addresses like sdt5z@virginia.edu
            // don't identify anyone on their own. Shown even when
            // hide-emails is set; leave `email` out of the author entry to
            // keep an address off the page entirely.
            let entry = [#a.name]
            if "email" in a and a.email != none {
              entry += [ \<]
              entry += format-email(a.email)
              entry += [\>]
            }
            entry
          })
          .join(", ")
        [.]
      })
    }
    if notes.len() > 0 {
      {
        set footnote(numbering: n => marks.at(n - 1))
        for note in notes {
          box(width: 0pt, hide(footnote(note)))
        }
      }
      counter(footnote).update(0)
    }
    v(0.3in - 0.1in)
  })

  // Date, centered under the authors. Both branches pull up: the author
  // block's trailing space is sized for the classic layout, and whatever
  // follows it (the date, or the abstract when there is no date) should sit
  // the same distance below the emails.
  if date != none {
    block(width: 100%, {
      set text(size: fc.size.normal)
      v(-0.15in)
      align(center, [#date])
    })
  } else {
    v(-0.25in)
  }

  v(6.5pt)

  // Line numbering: on for anonymous submissions, off otherwise, unless
  // overridden explicitly.
  let use-lineno = if lineno != none {
    lineno
  } else {
    anonymous
  }
  let show-lineno(body) = {
    if use-lineno {
      set par.line(
        numbering: n => text(size: fc.size.line-number)[#n],
        number-clearance: 11pt)
      body
    } else {
      body
    }
  }

  // Abstract.
  if abstract != none {
    block(width: 100%, {
      set text(size: fc.size.normal)
      set par(leading: 0.43em)

      align(center, text(size: fc.size.abstract-title)[*Abstract*])
      v(0.215em)
      show: show-lineno
      pad(left: 0.5in, right: 0.5in, abstract)
      v(0.43em)
    })

    v(0.43em / 2)
  }

  // Table of contents (off by default; papers rarely carry one).
  if toc {
    v(1em)
    outline(
      title: if toc-title == none { auto } else { toc-title },
      depth: toc-depth,
    )
  }

  // Main body.
  {
    show: show-lineno

    set text(size: fc.size.normal)
    set par(leading: 0.43em)
    set block(spacing: 1.0em)
    body
  }
}

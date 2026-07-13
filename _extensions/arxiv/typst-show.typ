#show: doc => arxiv(
$if(title)$
  title: [$title$],
$endif$
  authors: (
    (
$for(by-author)$
$if(it.name.literal)$
      (
        name: "$it.name.literal$",
$if(it.email)$
        email: [$it.email$],
$endif$
$if(it.orcid)$
        orcid: "$it.orcid$",
$endif$
$if(it.attributes.corresponding)$
        corresponding: true,
$endif$
$if(it.attributes.equal-contributor)$
        "equal-contributor": true,
$endif$
        affl: ($for(it.affiliations)$"$if(it.id)$$it.id$$else$$it.name$$endif$", $endfor$),
      ),
$endif$
$endfor$
    ),
    (
$for(by-affiliation)$
      ("$if(it.id)$$it.id$$else$$it.name$$endif$", (
$if(it.department)$
        department: "$it.department$",
$endif$
$if(it.name)$
        institution: "$it.name$",
$endif$
$if(it.city)$
        location: "$it.city$",
$endif$
$if(it.country)$
        country: "$it.country$",
$endif$
      )),
$endfor$
    ),
  ),
$if(keywords)$
  keywords: ($for(keywords)$"$it$", $endfor$),
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(anonymous)$
  anonymous: true,
$endif$
$if(lineno)$
  lineno: true,
$endif$
$if(hide-emails)$
  hide-emails: true,
$endif$
$if(table-stripes)$
  table-stripes: true,
$endif$
$if(notice)$
  notice: [$notice$],
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-title)$
  toc-title: [$toc-title$],
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
$if(mainfont)$
  font-config: (family: (serif: ("$mainfont$",))),
$endif$
  doc,
)
$if(citations)$
$if(bibliography)$
$if(csl)$
#set bibliography(style: "$csl$")
$elseif(bibliographystyle)$
#set bibliography(style: "$bibliographystyle$")
$endif$
$if(suppress-bibliography)$
#show bibliography: none
$endif$
$-- An empty `::: {#refs}` div in the document becomes a `<refs>`-labeled
$-- block; render the bibliography there (e.g. before an appendix) instead
$-- of at the end. biblio.typ skips its end-of-document emission when this
$-- anchor exists.
#show label("refs"): it => {
  it
  std.bibliography(($for(bibliography)$"$bibliography$"$sep$,$endfor$))
}
$endif$
$endif$

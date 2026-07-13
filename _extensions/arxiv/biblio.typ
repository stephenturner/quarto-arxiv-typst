$if(citations)$
$if(csl)$

#set bibliography(style: "$csl$")
$elseif(bibliographystyle)$

#set bibliography(style: "$bibliographystyle$")
$endif$
$if(bibliography)$
$if(suppress-bibliography)$
#show bibliography: none
$endif$

$-- Emit the bibliography at the end of the document only when there is no
$-- `::: {#refs}` div; typst-show.typ renders it at that anchor instead.
#context if query(label("refs")).len() == 0 {
  std.bibliography(($for(bibliography)$"$bibliography$"$sep$,$endfor$))
}
$endif$
$endif$

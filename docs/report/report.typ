#include "title.typ"

#set heading(numbering: "1.")
#set page(  
  numbering: (x, ..) => [#x],
  number-align: center + bottom,
)

#pagebreak()

#outline(title: "Table des matières", depth: 3, indent: 15pt)

#pagebreak()
#include "chapters/introduction.typ"
#pagebreak()
#include "chapters/start_guide.typ"
#pagebreak()
#include "chapters/implementation.typ"
#pagebreak()
#include "chapters/verification.typ"
#pagebreak()
#include "chapters/conclusion.typ"

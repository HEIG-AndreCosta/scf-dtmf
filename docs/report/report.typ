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
#include "chapters/getting_started.typ"
#pagebreak()
#include "chapters/contraintes.typ"
#pagebreak()
#include "chapters/design.typ"
#pagebreak()
#include "chapters/algorithme.typ"
#pagebreak()
#include "chapters/dma.typ"
#pagebreak()
#include "chapters/memoire.typ"
#pagebreak()
#include "chapters/IP_correlation.typ"
#pagebreak()
#include "chapters/user.typ"
#pagebreak()
#include "chapters/driver.typ"
#pagebreak()
#include "chapters/conclusion.typ"

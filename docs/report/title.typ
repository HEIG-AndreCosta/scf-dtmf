#columns(2, [
    #image("media/logo_heig-vd-2020.svg", width: 40%)
    #colbreak()
    #par(justify: false)[
        #align(right, [
            Département des Technologies de l'information et de la communication (TIC)
        ])
    ] 
    #v(1%)
    #par(justify:false)[
        #align(right, [
            Informatique et systèmes de communication
        ])
    ]
    #v(1%)
    #par(justify:false)[
        #align(right, [
            System-On-Chip FPGA
        ])
    ]
  ])
  
#v(20%)

#align(center, [#text(size: 14pt, [*SCF*])])
#v(4%)
#align(center, [#text(size: 20pt, [*Laboratoire 9*])])
#v(1%)
#align(center, [#text(size: 16pt, [*DTMF*])])

#v(8%)

#align(left, [#block(width: 70%, [
    #table(
      stroke: none,
      columns: (25%, 75%),
      [*Etudiants*], [André Costa, Patrick Maillard],
      [*Professeurs*], [Alberto Dassatti & Yann Thoma],
      [*Assistant*], [Anthony I. Jaccard],
      [*Année*], [2025]
    )
  ])])

#align(bottom + right, [
    Yverdon-les-Bains, #datetime.today().display("[day].[month].[year]")
  ])

#table(
  columns: (auto, auto, auto),
  align: center,
  stroke: 0.5pt,
  fill: (x, y) => if y == 0 { rgb("#E8F4FD") } else if x == 0 { rgb("#F0F8FF") },
  
  [*Offset*], [*READ*], [*WRITE*],
  
  // Configuration et contrôle
  [0x00], [ID Constant (0xCAFE1234)], [Non assigné],
  [0x04], [Test Register], [Test Register],
  [0x08], [Non assigné], [Start Calculation],
  [0x0C], [IRQ Status Register], [Clear IRQ Status],
  
  // Résultats de corrélation
  [0x10], [Dot Product [31:0]], [Non assigné],
  [0x14], [Dot Product [63:32]], [Non assigné],
  
  // Échantillons de fenêtre (Window samples)
  [0x100], [Non assigné], [Window samples 0,1],
  [0x104], [Non assigné], [Window samples 2,3],
  [0x108], [Non assigné], [Window samples 4,5],
  [0x10C], [Non assigné], [Window samples 6,7],
  [⋮], [⋮], [⋮],
  [0x17C], [Non assigné], [Window samples 62,63],
  
  // Échantillons de référence (Reference samples)
  [0x184], [Non assigné], [Reference samples 0,1],
  [0x188], [Non assigné], [Reference samples 2,3],
  [0x18C], [Non assigné], [Reference samples 4,5],
  [0x190], [Non assigné], [Reference samples 6,7],
  [⋮],[⋮], [⋮],
  [0x284], [Non accessible], [Reference samples 62,63],
)

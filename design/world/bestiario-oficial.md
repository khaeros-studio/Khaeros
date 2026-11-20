# Bestiário Oficial de Khaeros — Criaturas da Beira e Ambientes Ativos

> **Canon Level:** Misto — `Established` (10 entidades e 4 círculos já registrados em `codex_historia.gd`, `maldicoes.md` e `chefes.md`) / `Provisional` (2 criaturas inéditas `brasa_errante` e `coro_fraturado`, 4 Fichas de Ambiente Ativo, materiais de espólio e kits expandidos de Patamar, aguardando validação final de `narrative-director` e `game-designer`)
> **Visible To Player:** `Yes` (entradas resumidas no Grimório da Academia em `codex_historia.gd`) / `Discoverable` (padrões críticos, neutralização de ambiente e ganchos de espólio) / `Hidden` (ecos não resolvidos sobre a origem do Colapso, da sexta voz do Santuário e do destino das expedições antigas)
> **Source:** `src/gameplay/hub/codex_historia.gd`, `design/gdd/game-concept.md`, `design/art/art-bible.md`, `design/gdd/maldicoes.md`, `design/gdd/chefes.md`
> **Cross-References:**
> - Grimório in-game: [codex_historia.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/gameplay/hub/codex_historia.gd)
> - Conceito e Pilares: [game-concept.md](file:///c:/Users/lucas/meu-jogo-estudio/design/gdd/game-concept.md)
> - Direção Visual e Silhuetas: [art-bible.md](file:///c:/Users/lucas/meu-jogo-estudio/design/art/art-bible.md)
> - Maldições Aliadas (Pactos): [maldicoes.md](file:///c:/Users/lucas/meu-jogo-estudio/design/gdd/maldicoes.md)
> - Máquina de Estados de Chefes: [chefes.md](file:///c:/Users/lucas/meu-jogo-estudio/design/gdd/chefes.md)
> **Contradictions Check:** Confirmada consistência com o cânone vigente. Ver seção final *Verificação de Consistência e Harmonizações Ecológicas* para a reconciliação explícita de `anomalia_menor` (origem no Veio com desgarradas no Limiar), `fenda_errante` (origem no Santuário com deriva para o Veio conforme `eco_veio_02`), a forma hostil vs. pactuada das Maldições de Pactos e o respeito integral ao Lore Freeze (sem cosmologia paralela).

---

## Taxonomia da Ordem e Gramática Tática

A Escola da Ordem de Khaeros mede o horror em **Graus** para que o medo tenha nome; em combate, porém, sobrevive quem lê **Patamar**, **Papel** e **Silhueta** antes do primeiro golpe cair.

- **Regra Visual de Combate (Art Bible):** Traço preto pesado de tinta (`#0D0E14`), legibilidade garantida em silhueta sólida reduzida a `48 px` e dois acentos exclusivos: **Magenta de Fluxo** (perigo, instabilidade, ponto emissor e telégrafo) e **Dourado Ritual** (elite, consagração e lei de chefe). Amarras e fios cor de **Osso** pertencem exclusivamente às Maldições vinculadas da Doutrina de Pactos e nunca aparecem em inimigos selvagens.
- **Princípio Anti-Saco de HP (Pilar P3):** Toda criatura existe para impor uma **decisão tática imediata** — quebrar preparo com golpe pesado (`"Quebrou!"`), cortar linha de fogo, girar pilares, podar horda antes do escalonamento ou explorar o terreno contra o próprio inimigo.
- **Escala Dupla:**
  - *Patamar 1 (Grau 3):* Pressão fundamental; pune erro básico de espaçamento ou prioridade.
  - *Patamar 2 (Grau 2 / Grau 1 menor):* Inimigos de quebra de ritmo; punem imobilidade, spam de ataque e linhas retas.
  - *Patamar 3 (Grau 1):* Peças de controle de campo e resistência; exigem flanqueio, interrupção cirúrgica ou quebra de vínculo.
  - *Patamar 4 (Grau Especial):* Regentes de círculo; arenas fixas, armadura contra cambaleio, transição de Fase 2 aos `50%` de Vida e teste definitivo de domínio da Doutrina.

### Matriz Geral dos Quatro Círculos

| Região (`id`) | Criatura (`id`) | Grau | Patamar | Papel Tático | Decisão Tática Central | Ambiente Ativo |
|---|---|---|---|---|---|---|
| **1. O Limiar da Beira** (`limiar`) | Eco Perdido (`eco_perdido`) | Grau 3 | 1 | Horda | Podar o enxame antes do escalonamento de velocidade | *As Lajes Suspensas da Beira* |
| **1. O Limiar da Beira** (`limiar`) | Vulto Mudo (`vulto_mudo`) | Grau 2 | 2 | Oportunista | Guardar esquiva e ler o bote ao punir outros alvos | *As Lajes Suspensas da Beira* |
| **1. O Limiar da Beira** (`limiar`) | Soberano do Limiar (`soberano_do_limiar`) | Grau Especial | 4 | Solo/Chefe | Gerir 4 padrões, pilares, puxão + lacaios e decisão de Pacto | *As Lajes Suspensas da Beira* |
| **2. Veio Instável** (`veio_instavel`) | Anomalia Menor (`anomalia_menor`) | Grau 3 | 1 | Controlador | Cortar linha de tiro ou encurralar antes do recuo | *As Fissuras de Obsidiana do Veio* |
| **2. Veio Instável** (`veio_instavel`) | Espreitador da Fenda (`espreitador_da_fenda`) | Grau 2 | 2 | Oportunista | Manter movimento lateral para anular a emboscada pelas costas | *As Fissuras de Obsidiana do Veio* |
| **2. Veio Instável** (`veio_instavel`) | Guardião do Rito (`guardiao_do_rito`) | Grau Especial | 4 | Solo/Chefe | Rotacionar os 3 pilares sem acampar sob o hexagrama | *As Fissuras de Obsidiana do Veio* |
| **3. Fosso das Cinzas** (`fosso_das_cinzas`) | Brasa Errante (`brasa_errante`) | Grau 2 | 2 | Controlador | Controlar onde cai a escória e abatê-la fora das poças | *A Fornalha Morta do Fosso* |
| **3. Fosso das Cinzas** (`fosso_das_cinzas`) | Baluarte de Cinza (`baluarte_de_cinza`) | Grau 1 | 3 | Bruto | Contornar a frente blindada e punir a recuperação sísmica | *A Fornalha Morta do Fosso* |
| **3. Fosso das Cinzas** (`fosso_das_cinzas`) | Colosso de Cinza (`colosso_de_cinza`) | Grau Especial | 4 | Solo/Chefe | Evacuar arcos de `260 px` e punir a grade torácica aberta | *A Fornalha Morta do Fosso* |
| **4. Santuário Partido** (`santuario_partido`) | Fenda Errante (`fenda_errante`) | Grau 1 | 2 | Controlador | Ler intervalos angulares e quebrar/desviar a geometria | *O Observatório Despedaçado* |
| **4. Santuário Partido** (`santuario_partido`) | Coro Fraturado (`coro_fraturado`) | Grau 1 | 3 | Líder | Furar a linha para interromper o cântico e desarmar vínculos | *O Observatório Despedaçado* |
| **4. Santuário Partido** (`santuario_partido`) | Arconte da Fenda (`arconte_da_fenda`) | Grau Especial | 4 | Solo/Chefe | Ler os 6 cristais, girar os 4 pilares e cronometrar o Selo `[Q]` | *O Observatório Despedaçado* |

---

## Região 1 — O Limiar da Beira (`limiar`)

*O primeiro frio além do pórtico da Academia: lajes cinza-azuladas suspensas na névoa, onde a pedra esqueceu o que sustentava e o espaço cobra memória em troca de passo. Aqui o Iniciado aprende que hesitar custa chão — e que cada telégrafo no piso é uma sentença com data marcada.*

---

### 1. Eco Perdido, o Vazio que Ainda Marcha — Patamar 1 | Horda | O Limiar da Beira

> **ID Canônico:** `eco_perdido` · **Escala da Ordem:** Grau 3 · **Família Visual:** Eco (humano subtraído)

- **Ecologia do Colapso:** Vestígio de antigos viajantes e aprendizes esvaziados pela Ruptura do Limiar, o Eco perdeu rosto, nome e sombra, sobrevivendo ao drenar o calor residual de juramentos e o compasso cardíaco de quem invade as lajes frias. Antes de emergir da névoa, denuncia-se pelo arrastar seco de pano úmido sobre pedra e por pegadas rasas de tinta preta que se evaporam antes de qualquer calcanhar tocar o piso.
- **Silhueta e Leitura Visual:** Figura vertical e curva em tinta preta sólida, definida por um capuz fundo vazio e um braço direito alongado em lâmina de névoa rígida; a metade inferior desfaz-se em fiapos verticais sem pés nem sombra projetada. Durante a antecipação, o braço-lâmina afasta-se amplamente do tronco abrindo espaço negativo limpo e acendendo um fio magenta estreito na aresta de corte.
- **Comportamento e IA de Combate:**
  - *Abertura:* Materializa-se em bandos de 2 a 4 espécimes por bordas opostas, avançando em convergência direta para encurtar o centro da câmara já no primeiro segundo.
  - *Loop Principal:* Marcha em cadência humana arrastada até alcançar distância curta e prepara um corte em arco frontal telegrafado; prefere cercar pelos ângulos deixados abertos por outros Ecos.
  - *Gatilho de Pressão (Estado Crítico):* Quando um Eco adjacente morre ou sua própria Vida cai abaixo de 50%, absorve os fiapos soltos de tinta e acelera o passo, cortando a pausa entre aproximação e novo preparo.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Inércia de Enxame*:** Ganha bônus cumulativo de velocidade de movimento para cada outro Eco Perdido vivo na câmara (até 3 acúmulos), obrigando o jogador a podar a horda em vez de apenas correr em círculos.
  - **Ataque Assinatura — *Ceifa do Esquecimento*:** Projeta um setor frontal curto em magenta (`0,45 s` de preparo) e varre o espaço com o braço de tinta; vulnerável a interrupção por golpe pesado (`"Quebrou!"`) durante o recuo do braço ou a esquiva atravessando o arco para punição imediata pelas costas.
  - **Habilidade de Pressão/Reação — *Último Arrasto*:** Ao cair abaixo de 50% de Vida ou presenciar a queda de um Eco vizinho, executa um passo rasante adiante que fecha o espaço morto e reinicia seu ciclo de corte sem recuo defensivo.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Tinta de Memória Fria** — resíduo escuro recolhido dos fiapos dissipados, base alquímica para tinturas de foco e estabilizadores de Fluxo.
  - *Gancho Narrativo / Item Raro:* **Fivela Sem Inscrição** — fecho metálico de manto da 1ª Turma gasto até perder o nome; Mestre Halvar reconhece a têmpera do pino, mas recusa-se a revelar quem o vestia na madrugada da Ruptura.

---

### 2. Vulto Mudo, o Cão Sem Lamento — Patamar 2 | Oportunista | O Limiar da Beira

> **ID Canônico:** `vulto_mudo` · **Escala da Ordem:** Grau 2 · **Família Visual:** Resíduo de Anomalia (pactuável por Pactos como Maldição Comum)

- **Ecologia do Colapso:** Resíduo veloz de Anomalia que teve até o grito de dor extirpado pela Ruptura, o Vulto Mudo não guarda lamento humano e alimenta-se do sangue quente e da quebra de postura de presas distraídas em combate. Sua proximidade apaga subitamente o eco das botas do Iniciado sobre as lajes, enquanto sulcos paralelos de garras invisíveis riscam a névoa baixa rente às quinas da câmara.
- **Silhueta e Leitura Visual:** Quadrúpede baixo e esguio de contorno duro em tinta densa, com dorso arqueado em cunha horizontal e cabeça estreita sem olhos rasgada por duas fendas magenta; cristais curtos e nus brotam ao longo da espinha (na forma aliada de Pactos, esses cristais são selados por amarras cor de osso e nunca expõem magenta em repouso). Na preparação do bote, comprime o torso rente ao solo recuando os ombros para evidenciar a direção do disparo.
- **Comportamento e IA de Combate:**
  - *Abertura:* Evita o choque frontal nos primeiros dois segundos, correndo pelas laterais da câmara até o jogador engajar outro alvo ou gastar sua primeira carga de esquiva.
  - *Loop Principal:* Orbita a média distância nos pontos cegos e dispara investidas súbitas sempre que lê o jogador em recuperação de golpe pesado ou preso num canto.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, abandona a corrida circular e passa a recuar em rastro de tinta logo após atacar, deixando um laço de sombra no solo para prender quem persegue sem ler a saída.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Faro da Guarda Aberta*:** Causa dano adicional contra alvos atingidos durante animação de ataque ou sem cargas de esquiva disponíveis, punindo ofensiva gananciosa no meio da horda.
  - **Ataque Assinatura — *Bote de Penumbra*:** Trava um corredor retangular estreito de preparo rápido (`0,40 s`) e rasga a distância em alta velocidade com as garras frontais; esquivar perpendicularmente ao eixo do corredor expõe o Vulto numa derrapagem longa no ponto final do bote.
  - **Habilidade de Pressão/Reação — *Paredes de Sombra*:** Ao cruzar 50% de Vida (ou sofrer disparo à distância em alcance médio), salta para trás deixando um anel sombrio curto (`0,45 s` de aviso) que enraíza quem avança em linha reta — a mesma essência de contenção que oferece como Efeito de Saída se aceitar um Pacto.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Tendão de Tinta Silenciosa** — fibra elástica extraída das patas dianteiras, empregada em óleos de cadência de esquiva e fios de sintonização.
  - *Gancho Narrativo / Item Raro:* **Colar de Amarra Rompida** — tira gasta de tecido cor de osso marcada pela insígnia geminada de Pactos; indício silencioso de que um Iniciado anterior tentou vincular este espécime e falhou no Limiar.

---

### 3. Soberano do Limiar, o Rei Sem Povo do Pórtico — Patamar 4 | Solo/Chefe | O Limiar da Beira

> **ID Canônico:** `soberano_do_limiar` · **Escala da Ordem:** Grau Especial · **Família Visual:** Maldição Primordial (pactuável no estado `Subjugado` por Pactos)

- **Ecologia do Colapso:** Guardião anterior às muralhas de âmbar da Academia que recusou o recuo durante a Ruptura e acolheu no peito o ouro partido da própria fenda, o Soberano alimenta-se da convicção de juramentos novos para manter de pé sua coroa quebrada. Antes de descer sobre o altar final de quatro pilares, o ar gela com cheiro de ferro e ozônio enquanto elos invisíveis retinem contra a pedra e um anel de selos dourados rachados queima a poeira sob o piso.
- **Silhueta e Leitura Visual:** Silhueta vertical régia (`~1,5×` o Iniciado) de ombros largos e capa esfarrapada em tinta densa, encimada por uma coroa flutuante de cristais partidos e meias-correntes pendentes; no centro do tórax abre-se uma fissura dourada cortada por veias magenta de perigo. Cada um de seus quatro ataques abre amplamente os braços ou ergue a coroa no espaço negativo, tornando o padrão identificável antes mesmo de o telégrafo no chão completar o preenchimento.
- **Comportamento e IA de Combate:**
  - *Abertura:* Nasce sozinho no eixo norte da câmara fixa de quatro pilares e aguarda meio segundo em guarda solene antes de fechar distância para o primeiro corte *Garra do Véu Rasgado*.
  - *Loop Principal:* Executa um ciclo determinístico de quatro padrões — corte em setor (*Garra do Véu Rasgado*), avanço retangular que estanca contra pilares (*Irrupção do Limiar*), anel radial com 12 projéteis (*Pulso de Soberania*) e círculo de puxão com invocação controlada de até 2 Ecos Perdidos (*Convergência da Fenda*, teto de 3 vivos).
  - *Gatilho de Pressão (Estado Crítico):* Ao cair para `≤ 50%` de Vida (`350 HP`), ativa `0,50 s` de transição invulnerável com onda repulsora sem dano que racha a barra no HUD e entra em **Fúria**: velocidade de marcha `+15%` e recuperações reduzidas em `40%`, mantendo os tempos de preparo idênticos para preservar a justiça da leitura.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Coroa da Inquebrantável*:** Armadura absoluta contra cambaleio, imobilização e `"Quebrou!"`, somada a fortíssima resistência a empurrão (`fator 0,12`); vence quem domina os quatro telégrafos, usa os pilares para barrar avanços e decide quando limpar lacaios.
  - **Ataque Assinatura — *Irrupção & Pulso de Soberania*:** Encadeia a investida retangular *Irrupção do Limiar* (`0,60 s` de preparo; atrai-lo contra um dos quatro pilares interrompe o trajeto e abre janela limpa) com *Pulso de Soberania* (`0,60 s`), que detona `210 px` ao redor e dispara 12 projéteis radiais cujos vãos se abrem a média distância para esquiva limpa e punição.
  - **Habilidade de Pressão/Reação — *Convergência da Fenda*:** Desenha um círculo central (`225 px`) envolto por anel tracejado externo de atração (`420 px`, `0,70 s` de aviso); no disparo, puxa combatentes sem invulnerabilidade para o impacto e invoca até dois Ecos Perdidos nos flancos — na Fúria, o ritmo comprimido exige gerenciar esquiva no puxão e limpeza rápida dos lacaios.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Elo de Ouro Partido** — metal ressonante colhido das correntes desfeitas, catalisador de reforja para armas e selos de Domínio de alto grau.
  - *Gancho Narrativo / Item Raro:* **Selo do Juramento Subjugado** — ao zerar a Vida, Doutrinas ortodoxas o exorcizam por Fragmentos de Eco da Beira; quem jurou **Pactos** encontra o Soberano ajoelhado em estado `Subjugado`, podendo abrir mão dos Fragmentos para dobrá-lo ao vínculo como Maldição Primordial.

---

### Ficha de Ambiente Ativo — Região 1: *As Lajes Suspensas da Beira*

- **Efeito Passivo do Terreno:** **Tributo da Hesitação** — A pedra suspensa cobra movimento constante em troca de apoio; permanecer mais de `3 s` sobre o mesmo quadrante faz subir uma geada fria de tinta que reduz gradualmente a velocidade de caminhada até o jogador se deslocar ou esquivar, desestimulando defesa estática.
- **Perigos Dinâmicos:**
  1. **Laje que Esquece:** Periodicamente, placas periféricas da câmara racham com brilho azul-cinza e estalo oco por `1,2 s` antes de afundarem na névoa por `4 s`; encurta rotas preguiçosas de kiting e devolve quem cai à borda mais próxima com dano de queda e perda de ritmo.
  2. **Sopro de Névoa Cega:** Acionado em intervalos fixos ou quando um inimigo é abatido próximo ao precipício, uma rajada fria rasante varre uma faixa lateral (avisada por fiapos horizontais), empurrando levemente corpos em direção às bordas sem nunca encobrir os telégrafos de combate no chão.
- **Neutralização / Uso a Favor:** **Arremesso de Borda** — Golpes pesados, empurrões de escudo e ondas de repulsão podem lançar Ecos Perdidos e Vultos Mudos sobre lajes prestes a afundar ou contra o *Sopro de Névoa Cega*, derrubando-os no vazio para abates imediatos ou atordoamento prolongado contra a quina da arena.

---

## Região 2 — Veio Instável (`veio_instavel`)

*A Beira mostrando os dentes: galerias esverdeadas cor de petróleo iluminadas de baixo para cima por veios de Fluxo cru que sangram pelas paredes. O chão vibra em dois tempos, as sombras sobem ao contrário e quem fica imóvel por um segundo assina a própria lápide.*

---

### 4. Anomalia Menor, o Olho do Fluxo Cru — Patamar 1 | Controlador | Veio Instável *(desgarradas alcançam o Limiar)*

> **ID Canônico:** `anomalia_menor` · **Escala da Ordem:** Grau 3 · **Família Visual:** Anomalia (forma imitada com excesso)

- **Ecologia do Colapso:** Condensada onde o excesso de Fluxo cru coagula sobre as paredes do Veio Instável (com exemplares desgarrados vazando ocasionalmente até o Limiar), esta criatura imita patas anfíbias em excesso enquanto suga energia bruta das fissuras do piso. Sua presença é denunciada por um zumbido elétrico em dois tempos e pelo cheiro acre de ozônio queimado saindo de crostas cristalinas magenta nos cantos da câmara.
- **Silhueta e Leitura Visual:** Massa baixa, larga e assimétrica de contorno duro, coroada por um leque irregular de cristais facetados retos e um único núcleo emissor circular bem aberto no centro frontal. Durante o preparo, os cristais laterais se inclinam para frente enquanto o núcleo magenta se contrai num ponto intenso, marcando sem ambiguidade o instante do tiro.
- **Comportamento e IA de Combate:**
  - *Abertura:* Recua nos primeiros passos para os flancos ou atrás de pilares de obsidiana, buscando linha limpa de tiro cruzando o centro da câmara.
  - *Loop Principal:* Mantém distância defensiva — afastando-se sempre que o Iniciado se aproxima — e dispara feixes retos telegrafados que cortam corredores de fuga enquanto aliados móveis pressionam o jogador.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida ou quando encurralada contra a parede sem rota de recuo, entra em sobrecarga e dispara dois feixes curtos em cadência alternada, tornando o núcleo frágil e instável.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Fuga Fototrópica*:** Sempre que um inimigo hostil fecha distância curta, desliza rapidamente para trás em direção ao veio de parede mais próximo, punindo quem a deixa viva nos cantos da sala.
  - **Ataque Assinatura — *Agulha de Fluxo*:** Projeta um corredor retilíneo magenta fixo (`0,55 s` de leitura) antes de disparar um projétil rápido; esquivar lateralmente através do eixo do feixe garante avanço seguro em diagonal, e um golpe pesado durante a contração do núcleo quebra o preparo (`"Quebrou!"`).
  - **Habilidade de Pressão/Reação — *Estilhaço de Sobrecarga*:** Abaixo de 50% de Vida (ou ao morrer se abatida durante o preparo), detona uma descarga curta de cristais ao redor do corpo após `0,40 s` de aviso circular, exigindo cancelar a recuperação do golpe final com esquiva.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Prisma de Fluxo Cru** — fragmento facetado de alta condutividade, reagente base para tônicos de recarga de Selo e gravuras arcanas.
  - *Gancho Narrativo / Item Raro:* **Lente de Observação Fraturada** — vidro calibrado da Universidade fundido ao cristal da criatura, prova de que instrumentos de medição de Mestra Maren foram absorvidos vivos pelo Veio.

---

### 5. Espreitador da Fenda, a Costura que Morde — Patamar 2 | Oportunista | Veio Instável

> **ID Canônico:** `espreitador_da_fenda` · **Escala da Ordem:** Grau 2 · **Família Visual:** Predador de Fenda (pactuável por Pactos como Maldição Refinada)

- **Ecologia do Colapso:** Predador refinado que aprendeu a rasgar e dobrar a costura do ar no Veio Instável, o Espreitador alimenta-se da atenção dividida de exorcistas cercados e da energia desperdiçada por guardas rompidas. Antes de surgir pelas costas, o ar cheira a vidro partido e um estalo seco duplo ecoa sempre atrás dos ombros do alvo, enquanto uma linha violeta de dobra paira a um palmo do chão.
- **Silhueta e Leitura Visual:** Silhueta agachada em crescente assimétrico de perfil afiado, com antebraços em lâminas-talas curvas e cauda fragmentada em fumaça violeta-magenta; olhos estreitos inclinados e gumes energizados acendem no preparo (quando pactuado, suas lâminas exibem talas e amarras cor de osso). No instante pré-dobra, o corpo inteiro enverga para trás deixando o contorno aberto em arco de mola.
- **Comportamento e IA de Combate:**
  - *Abertura:* Surge fora do cone frontal do jogador a distância média, observando a trajetória por um instante antes de abrir a primeira dobra espacial.
  - *Loop Principal:* Inicia o preparo à distância média, dissolve-se em fumaça violeta e reaparece exatamente atrás do ponto onde o alvo estava para desferir um corte rápido, recuando em seguida para novo flanco.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida ou quando o último aliado da sala morre, deixa um corte radial (*Rastro Cortante*) no ponto de partida toda vez que dobra o espaço, punindo perseguições lineares.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Dobra de Retaguarda*:** Ataques que acertam pelas costas causam dano amplificado e aplicam **Abalo**, forçando rotação constante de guarda e punindo quem luta focado num único ponto.
  - **Ataque Assinatura — *Salto da Costura*:** Acende uma linha de dobra entre si e a retaguarda do jogador (`0,50 s` de telégrafo claro), teleporta-se e desfere o arco *Bote Estilhaçado*; manter movimento lateral contínuo após o início do telégrafo faz o golpe cair no vazio e abre janela plena de contra-ataque.
  - **Habilidade de Pressão/Reação — *Rastro Cortante*:** Ao cair abaixo de 50% de Vida ou ser atingido corpo a corpo durante o reposicionamento, detona um anel cortante rápido (`120 px`) no ponto que abandona, aplicando **Abalo** em quem avançou sem aguardar o recuo.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Fibrila de Espaço Rasgado** — filamento translúcido que vibra fora de fase, usado em forja de adagas, runas de esquiva e vínculos refinados.
  - *Gancho Narrativo / Item Raro:* **Insígnia da 3ª Turma Partida ao Meio** — medalha de batedor cortada num plano tão perfeito que suas duas metades ainda se atraem em silêncio, eco direto do relato deixado no Veio.

---

### 6. Guardião do Rito, a Lei do Hexagrama Perpétuo — Patamar 4 | Solo/Chefe | Veio Instável

> **ID Canônico:** `guardiao_do_rito` · **Escala da Ordem:** Grau Especial · **Família Visual:** Entidade Cerimonial (vertical, simétrica e dourada)

- **Ecologia do Colapso:** Entidade cerimonial nascida quando os primeiros arcanistas tentaram acorrentar o Veio Instável num contrato perpétuo cujas três assinaturas arcanas devoraram seus autores, o Guardião não conhece ódio e alimenta-se da própria simetria do Fluxo canalizado na câmara para executar uma sentença que ninguém mais sabe cancelar. Ao cruzar o limiar de sua arena, os veios magenta das paredes apagam-se de súbito num silêncio metálico, dando lugar ao cheiro de cera quente e incenso queimado enquanto um hexagrama dourado incendeia a pedra sob luz zenital dura.
- **Silhueta e Leitura Visual:** Construção vertical rigidamente simétrica feita de placas cerimoniais retangulares, ombreiras triangulares e um cetro-lança de três pontas sobre manto escuro de tinta; três selos dourados orbitam em triângulo atrás da cabeça sem rosto, enquanto os ataques de perigo rasgam o ar em feixes magenta nítidos emoldurados a ouro. Ao preparar cada disparo, o cetro ergue-se na vertical perfeita e os três selos alinham-se no plano da mira.
- **Comportamento e IA de Combate:**
  - *Abertura:* Manifesta-se no vértice central do hexagrama cercado pelos três pilares da câmara e traça de imediato um leque triplo de corredores telegrafados para testar a leitura de cobertura do Iniciado.
  - *Loop Principal:* Mantém distância cirúrgica deslizando entre os vértices do hexagrama, alternando leques triplos de projéteis velozes com triângulos explosivos inscritos no piso que expulsam o jogador de trás de um mesmo pilar.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, funde as três assinaturas no **Decreto de Fechamento**: liga os pilares com feixes periódicos de varredura geométrica e dobra a cadência dos leques triplos, reduzindo o intervalo seguro antes de sua recarga central.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Cláusula da Simetria*:** Imune a cambaleio e `"Quebrou!"`; mantém redução de dano enquanto os três selos orbitais estão sincronizados — obrigar um feixe seu a estilhaçar-se contra os pilares da câmara ou puni-lo na recarga do cetro desalinha temporariamente um selo e abre dano integral.
  - **Ataque Assinatura — *Sentença em Leque Triplo*:** Desenha três corredores velozes divergentes (`0,55 s` de telégrafo limpo) e dispara lanças de Fluxo capazes de pulverizar quem permanece em campo aberto; usar os três pilares como abrigo ou atravessar o leque com esquiva diagonal garante aproximação segura na recarga do cetro.
  - **Habilidade de Pressão/Reação — *Hexagrama Incompleto*:** Periodicamente (e em ritmo acelerado abaixo de 50% de Vida), inscreve três selos triangulares explosivos ao redor do pilar mais próximo do jogador (`0,75 s` de aviso), forçando abandono imediato da cobertura e recompensando quem cruza a zona de risco para pressionar o Guardião durante a conjuração.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Assinatura de Bronze Ritual** — placa geométrica gravada em metal puro, usada na reforja de Selos e amplificação de duração de Domínio.
  - *Gancho Narrativo / Item Raro:* **Contrato Sem Cláusula de Saída** — lâmina de chumbo com três nomes da fundação da Academia raspados à força; prova física de que o Veio foi selado às pressas para esconder um erro institucional.

---

### Ficha de Ambiente Ativo — Região 2: *As Fissuras de Obsidiana do Veio*

- **Efeito Passivo do Terreno:** **Pulso em Dois Tempos** — O Fluxo cru sob a pedra pulsa num compasso audível e visível nas bordas da câmara; a cada batida forte do veio, projéteis arcanos e descargas de Fluxo ganham aceleração breve, premiando leitura rítmica e punindo deslocamento distraído.
- **Perigos Dinâmicos:**
  1. **Sangria de Veio:** A cada compasso completo (ou quando impactos pesados racham a margem), uma fissura diagonal de obsidiana brilha em magenta por `0,9 s` e ejeta um jato estreito de Fluxo cru atravessando a câmara, fatiando o terreno em dois setores isolados.
  2. **Eco de Sobrecarga:** Canalizar o Selo ou habilidades de alto custo de Fluxo diretamente sobre uma fissura aberta sem respeitar o intervalo do pulso provoca um rebote radial de estilhaços após `0,6 s`, cobrando preço visível pelo excesso de poder (Pilar P2).
- **Neutralização / Uso a Favor:** **Condução de Fissura** — Empurrar ou atrair Espreitadores e Anomalias sobre uma fissura no instante em que ela telegrafa a *Sangria de Veio* faz o jato de Fluxo cru ferir e aplicar **Abalo** também nos inimigos, quebrando sua postura e acelerando o abate sem gastar recursos próprios.

---

## Região 3 — Fosso das Cinzas (`fosso_das_cinzas`)

*A antiga fundição silenciada da Ordem, onde uma erupção de Grau Especial consumiu bigornas, escudos e mestres num único suspiro de brasa. Escória vitrificada, grelhas quentes e poeira cinza-carvão dominam a arena — mas o aço temperado aqui ensina que peso sem ritmo é só pedra esperando rachar.*

---

### 7. Brasa Errante, o Sopro da Fundição Morta — Patamar 2 | Controlador | Fosso das Cinzas

> **ID Canônico:** `brasa_errante` *(nova criatura)* · **Escala da Ordem:** Grau 2 · **Família Visual:** Núcleo de Escória / Anomalia Térmica

- **Ecologia do Colapso:** Nascida dos cadinhos estilhaçados quando a grande fornalha do Fosso implodiu em Fluxo corrompido, a Brasa Errante é um núcleo flutuante de escória viva que se alimenta do calor de lâminas temperadas e do oxigênio da respiração de invasores. Antes de surgir entre as vigas, anuncia-se por um chiado contínuo de ferro mergulhado em óleo frio, cheiro sufocante de enxofre adocicado e gotas de escória vitrificada que estalam sobre as lajes.
- **Silhueta e Leitura Visual:** Esfera irregular flutuante em tinta carvão envolta por três cascas curvas de escória separadas por espaço negativo, revelando um coração incandescente em brasa-magenta; sem pernas nem rosto, é legível de imediato pela rotação das placas. Na antecipação de ataque, as três cascas abrem-se radialmente como um cadinho virando, expondo integralmente o núcleo luminoso.
- **Comportamento e IA de Combate:**
  - *Abertura:* Flutua por cima de escombros baixos e despeja nos primeiros dois segundos uma poça de escória entre o jogador e os brutos da sala para fatiar o campo de batalha.
  - *Loop Principal:* Mantém distância segura recuando sobre terreno quente e lança arcos lentos de escória derretida que negam zonas de movimentação com **Queimadura**, tentando empurrar o Iniciado contra o alcance dos Baluartes.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida ou quando fica sem aliados corpo a corpo na câmara, sela parcialmente as cascas e passa a avançar em ignição instável, pressionando o jogador a abatê-la à distância ou esquivar do estouro terminal.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Esteira de Escória*:** Golpes com empurrão arremessam a Brasa Errante com facilidade — permitindo ao jogador jogá-la para longe das áreas seguras antes de desferir o golpe letal ou empurrá-la contra válvulas frias da forja.
  - **Ataque Assinatura — *Vazamento de Cadinho*:** Marca um círculo de impacto no chão (`0,75 s` de aviso) onde despeja uma massa pesada de escória que fere no impacto e deixa poça de **Queimadura** por `4 s`; o arco lento abre janela clara para sair do círculo e punir o núcleo exposto enquanto as cascas permanecem abertas no resfriamento.
  - **Habilidade de Pressão/Reação — *Têmpera Reversa*:** Abaixo de 50% de Vida, sofrer dano corpo a corpo sem morrer aciona um pulso térmico curto (`0,45 s` de preparo) que reacende todas as poças de escória próximas por mais `2 s`, forçando execução decisiva ou reposicionamento prévio.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Carvão de Fluxo Vitrificado** — brasa petrificada que arde sem fumaça, usada em alquimia de Queimadura e reforja de lâminas térmicas.
  - *Gancho Narrativo / Item Raro:* **Cinzel Derretido da Forja Baixa** — ferramenta retorcida ainda presa a um molde inacabado com a espiral da Doutrina da Transmutação gravada no cabo, provando que Mestra Oreth trabalhou na fundição antes da queda.

---

### 8. Baluarte de Cinza, o Portão que Recusou Cair — Patamar 3 | Bruto | Fosso das Cinzas

> **ID Canônico:** `baluarte_de_cinza` · **Escala da Ordem:** Grau 1 · **Família Visual:** Guardião Pétreo (pactuável por Pactos como Maldição Rara)

- **Ecologia do Colapso:** Massa pétrea nascida do encontro entre escória vitrificada e o último voto dos defensores da Cidadela Baixa que se recusaram a abandonar os portões da fundição, o Baluarte alimenta-se da energia cinética dos impactos recebidos contra sua couraça. Sua aproximação faz pedregulhos vibrarem no chão em batidas lentas e graves, acompanhadas por cheiro de basalto queimado e dois sulcos profundos de punhos arrastados na cinza.
- **Silhueta e Leitura Visual:** Trapézio largo e pesado apoiado sobre antebraços pétreos colossais que formam um escudo frontal natural, com cabeça afundada nos ombros e fissuras internas incandescentes em brasa-magenta (na forma pactuada, correias largas cor de osso ancoram suas placas). Ao preparar golpes sísmicos, ergue ambos os punhos acima da silhueta criando um arco vazio nítido antes do desabamento.
- **Comportamento e IA de Combate:**
  - *Abertura:* Planta-se imediatamente no eixo central entre o jogador e os controladores da câmara, marchando em ritmo implacável sem recuar diante de golpes leves.
  - *Loop Principal:* Sustenta pressão frontal bloqueando passagens estreitas e descarrega tremores circulares de amplo alcance que punem quem tenta vencê-lo apenas em troca franca de frente.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, trinca as placas torácicas e entra em **Marcha de Ruína**: perde parte da mitigação frontal, mas cada esmagamento dispara uma segunda onda sísmica retardada que exige esquiva em dois tempos.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Carapaça Ancorada*:** Mitiga dano de golpes frontais leves e resiste a empurrão comum; força o jogador a rotacionar pelas costas, aplicar **Abalo** ou desferir golpes pesados/especiais para rachar sua postura e expor a escória viva sob a rocha.
  - **Ataque Assinatura — *Quebra-Limiar Sísmico*:** Preparo pesado e largo (`0,70 s`) telegrafado por círculo amplo no piso antes de cravar os punhos no solo; sair do raio ou atravessar a onda com esquiva no impacto garante janela generosa enquanto o Baluarte arranca os braços da pedra rachada.
  - **Habilidade de Pressão/Reação — *Cratera de Cinza*:** Ao cruzar 50% de Vida (ou após absorver 3 ataques frontais seguidos sem quebra), bate o antebraço no piso liberando um anel concêntrico duplo que empurra e aplica **Abalo** em quem insistiu em atacar sua frente blindada.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Placa de Basalto Jurado** — laje densa temperada em cinza antiga, componente essencial para reforjas defensivas e fortalecimento de escudos.
  - *Gancho Narrativo / Item Raro:* **Voto de Ferro Calcinado** — chapa de juramento da Doutrina do Guardião com a inscrição *"A muralha não escolhe quem protege"*; ao vê-la no Campus, Mestre Berrin encerra a conversa em silêncio.

---

### 9. Colosso de Cinza, o Coração da Fornalha Morta — Patamar 4 | Solo/Chefe | Fosso das Cinzas

> **ID Canônico:** `colosso_de_cinza` · **Escala da Ordem:** Grau Especial · **Família Visual:** Titã de Fundição (monolítico e incandescente)

- **Ecologia do Colapso:** Titã formado quando o núcleo da grande forja engoliu martelos, bigornas e a cinza jurada de mestres ferreiros num único corpo monumental, o Colosso alimenta-se de metal derretido e do calor arrancado de cada impacto sísmico contra as lajes do Fosso. Sua descida é precedida por uma chuva muda de fuligem acesa caindo do teto partido, ar seco que distorce a visão e o rugido grave de um fole gigante instantes antes de despencar como meteoro de magma.
- **Silhueta e Leitura Visual:** Gigante monolítico (`~2,2×` o Iniciado) moldado em pedra carbonizada e vigas de ferro fundido, com punhos-bigorna maciços e uma grade de fornalha cravada no peito onde pulsa luz magenta-dourada. Durante cada preparo, seus braços se erguem bem acima da linha dos ombros ou recuam em grande amplitude, abrindo o centro do torso e anunciando de longe a direção do arco colossal.
- **Comportamento e IA de Combate:**
  - *Abertura:* Despenca do teto no centro da câmara como meteoro telegrafado por anel crescente no chão, expulsando ondas de cinza e forçando evacuação imediata do eixo de entrada.
  - *Loop Principal:* Executa ataques demorados mas devastadores — varreduras incandescentes de `260 px` e esmagamentos de bigorna que abrem veios ardentes no chão — sempre seguidos por janelas longas de resfriamento em que os punhos ficam presos à pedra e a grade peitoral escancara.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, rompe os ferrolhos da grade em **Fornalha Aberta**: recebe dano ampliado no núcleo exposto, mas cada esmagamento gera ondas ígneas em dois estágios (anel interno e externo) e alterna saltos meteóricos que redesenham as zonas seguras da arena.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Bigorna Viva*:** Armadura absoluta contra cambaleio, imobilização e quase imóvel contra empurrão; sua crosta externa mitiga golpes apressados fora de janela, mas a grade peitoral aberta na recuperação recebe dano crítico, premiando disciplina sobre pressa.
  - **Ataque Assinatura — *Martelo de Escória & Onda Ígnea*:** Preparo longo (`0,85 s`) com arco gigantesco de `260 px` marcado em fulgor nítido, seguido de onda ígnea rasteira; sair por completo da zona incandescente ou cruzar a borda na esquiva recompensa com `1,8 s` de punição direta sobre o núcleo peitoral exposto.
  - **Habilidade de Pressão/Reação — *Queda de Meteoro*:** Ao atingir 50% de Vida e em ciclos da Fase 2, salta para fora do quadro marcando um círculo que acompanha o jogador por `0,9 s` antes de travar por `0,5 s` e desabar, abrindo linhas de magma temporárias que forçam rotação limpa até esfriarem.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Núcleo de Cinza Primordial** — brasa condensada de calor perpétuo, catalisador mestre para reforja final de armas e frascos alquímicos superiores.
  - *Gancho Narrativo / Item Raro:* **Martelo Rachado do Mestre Ferreiro** — relíquia cuja cabeça partida guarda a marca de um selo de contenção inacabado, revelando que a fundição tentou trancar algo que já subia do quarto círculo.

---

### Ficha de Ambiente Ativo — Região 3: *A Fornalha Morta do Fosso*

- **Efeito Passivo do Terreno:** **Sobreaquecimento da Escória** — Grelhas metálicas incrustadas no piso retêm calor vivo da fundição; permanecer sobre elas por mais de `2,5 s` contínuos acumula calor até aplicar **Queimadura**, canalizando o combate para as passarelas frias de basalto.
- **Perigos Dinâmicos:**
  1. **Abertura de Fole:** Periodicamente, dutos laterais sopram uma rajada de brasa sobre as grelhas centrais (anunciada por `1,0 s` de chiado e clarão nos respiradouros), causando dano térmico e reacendendo poças de escória próximas.
  2. **Queda de Escória do Cadinho:** Sempre que um golpe sísmico pesado (de Baluarte, Colosso ou habilidade pesada de impacto) sacode a câmara, gotas incandescentes soltam-se dos cadinhos suspensos e caem em 2 a 3 círculos marcados (`0,8 s` de aviso), espalhando novos focos temporários de **Queimadura**.
- **Neutralização / Uso a Favor:** **Válvulas de Têmpera** — Atingir os contrapesos de corrente nas bordas da sala libera uma descarga de ar frio rasante que apaga poças de escória ativas e resfria instantaneamente inimigos superaquecidos (Brasas Errantes e o Colosso), aplicando **Abalo** e ampliando a janela de vulnerabilidade de seus núcleos rachados.

---

## Região 4 — Santuário Partido (`santuario_partido`)

*A antiga Câmara dos Cinco Domínios rasgada ao meio por uma fenda vertical no altar principal. Lajes flutuantes de cristal azul-gelo preservam ecos de Expansões de Domínio desfeitas; aqui o combate deixa de ser apenas sobrevivência e torna-se julgamento de filosofia.*

---

### 10. Fenda Errante, o Rasgo sem Carne — Patamar 2 | Controlador | Santuário Partido *(correntes arrastam exemplares ao Veio Instável)*

> **ID Canônico:** `fenda_errante` · **Escala da Ordem:** Grau 1 · **Família Visual:** Ruptura Viva (geométrica e sem corpo orgânico)

- **Ecologia do Colapso:** Nascida diretamente da cicatriz vertical que partiu a cúpula de cristal do Santuário (com espécimes à deriva frequentemente arrastados pelas correntes de Fluxo até o Veio Instável), a Fenda Errante não possui carne nem osso e alimenta-se da pressão residual de Expansões de Domínio rompidas. Anuncia-se por um estalo agudo de vidro se partindo em câmera lenta, cheiro metálico de ar rarefeito e um ponto de sucção que torce a poeira em espiral antes de se rasgar.
- **Silhueta e Leitura Visual:** Rasgo vertical negro em cunha flutuante cercado por seis estilhaços angulosos orbitais em simetria radial, com uma linha central magenta-elétrica cortando o vazio. Durante a preparação, os seis estilhaços retraem-se em direção ao núcleo formando uma estrela fechada e apontando exatamente os seis vetores de disparo.
- **Comportamento e IA de Combate:**
  - *Abertura:* Desliza suavemente até o cruzamento central da câmara ou entre pilares, convertendo o espaço aberto num tabuleiro de ângulos restritos.
  - *Loop Principal:* Flutua em órbita curta acumulando pressão e dispara anéis simultâneos de seis projéteis em todas as direções, obrigando o jogador a ler intervalos em movimento enquanto lida com outras ameaças.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, inverte o giro dos seis estilhaços e passa a disparar um segundo anel defasado em `30°` logo após o primeiro, fechando os vãos seguros de quem ficou estático.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Corpo Sem Lastro*:** Flutua imune a perigos rasteiros do piso; em contrapartida, golpes pesados a empurram facilmente e giram o alinhamento de seus seis estilhaços, permitindo ao jogador redirecionar a geometria da rajada durante o preparo.
  - **Ataque Assinatura — *Coroa de Seis Estilhaços*:** Contrai os seis fragmentos com seis linhas radiais telegrafadas (`0,60 s`) e dispara um anel simultâneo de projéteis em `60°`; posicionar-se nos corredores vazios ou cruzar o anel usando a invulnerabilidade da esquiva abre janela limpa para abatê-la na recarga.
  - **Habilidade de Pressão/Reação — *Colapso Defasado*:** Abaixo de 50% de Vida, dispara após `0,55 s` um segundo anel girado em `30°` no eixo oposto, obrigando reposicionamento contínuo ou interrupção agressiva antes que o segundo ciclo arme.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Estilhaço de Cúpula Partida** — cristal de refração pura usado em alquimia de precisão e amplificação de alcance de técnicas.
  - *Gancho Narrativo / Item Raro:* **Diapasão de Cristal Azul-Gelo** — fragmento arquitetônico do Santuário original que ainda ressoa em nota limpa perto de Monólitos de Lore, lembrando a harmonia anterior à ruptura.

---

### 11. Coro Fraturado, o Eco das Cinco Vozes — Patamar 3 | Líder | Santuário Partido

> **ID Canônico:** `coro_fraturado` *(nova criatura)* · **Escala da Ordem:** Grau 1 · **Família Visual:** Eco Cerimonial Composto (halo partido)

- **Ecologia do Colapso:** Formado pelos restos fundidos de cinco oficiantes do Santuário que tentaram sustentar um Selo conjunto no segundo em que a cúpula ruiu, o Coro Fraturado alimenta-se da cadência de combate e da ressonância de Fluxo das maldições ao seu redor. Antes de entrar em cena, um acorde dissonante de cinco vozes fora de tempo vibra nos ossos do maxilar do Iniciado, acompanhado por cheiro frio de incenso velho e cinco anéis concêntricos finos riscados no pó das lajes.
- **Silhueta e Leitura Visual:** Figura alta e levitante envolta em túnica clerical rasgada em tinta preta sem rosto central, coroada por um halo quebrado de cinco placas-máscara em arco; feixes finos de dourado rachado por magenta conectam seu halo aos aliados fortalecidos, revelando instantaneamente sua rede de comando. Ao preparar o cântico, as cinco placas expandem-se em coroa aberta ao redor do vácuo da cabeça.
- **Comportamento e IA de Combate:**
  - *Abertura:* Recua para a retaguarda da câmara logo no primeiro segundo e ancora vínculos de ressonância em até dois aliados próximos, estabelecendo prioridade imediata de alvo.
  - *Loop Principal:* Mantém distância protegida atrás de Fendas Errantes ou lacaios, alternando cânticos de sincronia (que aceleram recuperações aliadas e erguem barreiras breves) com repulsões concêntricas se o jogador romper a linha.
  - *Gatilho de Pressão (Estado Crítico):* Quando perde todos os aliados vinculados ou cai abaixo de 50% de Vida, desfaz o coro em **Solo Dissonante**, substituindo suporte por pulsos rítmicos de área em três anéis consecutivos que pressionam todo o espaço da câmara.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Regência da Dissonância*:** Vincula até 2 aliados visivelmente na câmara, acelerando seus ciclos de ataque e renovando escudo leve; obriga o jogador a furar a formação para silenciar o Líder em vez de travar uma guerra de atrito contra aliados protegidos.
  - **Ataque Assinatura — *Cântico da Ruptura*:** Carrega um anel concêntrico de expansão (`0,65 s` de preparo claro e vulnerável a golpe pesado `"Quebrou!"`); se concluído, empurra quem está perto e sincroniza um disparo imediato dos aliados vinculados — interrompê-lo atordoa o Coro e desfaz instantaneamente todos os escudos da sala.
  - **Habilidade de Pressão/Reação — *Requiém Fraturado*:** Abaixo de 50% de Vida ou isolado sem aliados, estilhaça o halo em três anéis concêntricos sequenciais (`interno → médio → externo`), exigindo esquiva rítmica para dentro dos anéis já detonados a fim de fechar distância e finalizar o abate.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Corda Vocal de Cristal Dissonante** — filamento ressonante colhido do halo quebrado, usado em elixires de carga acelerada de Selo e amplificadores de Domínio.
  - *Gancho Narrativo / Item Raro:* **Partitura Rasgada dos Cinco Selos** — placa de marfim que registra o coro cerimonial das cinco filosofias, mas traz no rodapé uma sexta voz raspada às pressas com cinzel — indício de uma omissão deliberada na fundação do Santuário.

---

### 12. Arconte da Fenda, a Cicatriz da Ambição — Patamar 4 | Solo/Chefe | Santuário Partido

> **ID Canônico:** `arconte_da_fenda` · **Escala da Ordem:** Grau Especial · **Família Visual:** Regente de Fenda (levitante, seis cristais orbitais)

- **Ecologia do Colapso:** Não é um invasor estrangeiro, mas a cicatriz viva da maior ambição da Ordem quando tentou forçar uma única Expansão de Domínio capaz de dobrar a Beira inteira, alimentando-se da dissonância entre as filosofias partidas no altar. Antes de descer sobre a câmara final de quatro pilares, a gravidade parece falhar por meio segundo, o ar congela com gosto metálico de ozônio e uma fenda vertical de luz negra abre-se no centro da arena cercada por seis estilhaços em órbita muda.
- **Silhueta e Leitura Visual:** Entidade régia levitante de proporções alongadas e contorno rasgado em tinta profunda, sem pés tocando as lajes, cortada no centro do torso por uma fenda vertical brilhante em magenta-dourado e emoldurada por seis cristais facetados em hexágono perfeito. Antes mesmo de o chão iluminar, os seis cristais reorganizam-se em formações distintas (leque horizontal, círculo de invocação ou cruz de corte), funcionando como telégrafo vivo na própria silhueta.
- **Comportamento e IA de Combate:**
  - *Abertura:* Paira acima da fenda central cercado pelos quatro pilares do Santuário, abre cinco cristais em leque frontal e dispara uma primeira rajada veloz para medir o domínio de cobertura e esquiva do Iniciado.
  - *Loop Principal:* Alterna deslocamentos curtos em dobra entre quadrantes dos pilares, rajadas em leque de cinco projéteis rápidos e invocações controladas de Ecos Perdidos nos flancos para impedir que o jogador fique escondido atrás da mesma coluna.
  - *Gatilho de Pressão (Estado Crítico):* Abaixo de 50% de Vida, ativa **Reescrita do Santuário**: a fenda vertical do altar alarga-se, os seis cristais passam a disparar leques duplos cruzados (cinco projéteis seguidos de fechamento angular) e cada invocação é acompanhada por um rasgo linear atravessando a arena, testando o domínio pleno do Selo `[Q]` e da Expansão de Domínio.
- **Kit de Habilidades:**
  - **Passiva de Identidade — *Sexteto Orbital*:** Armadura absoluta contra cambaleio, imobilização e `"Quebrou!"`; seus seis cristais orbitais anunciam geometricamente cada padrão meio segundo antes do disparo, recompensando jogadores que leem silhueta e piso simultaneamente.
  - **Ataque Assinatura — *Leque dos Cinco Juízos*:** Alinha cinco cristais à frente (`0,55 s` de preparo em corredores nítidos) e dispara cinco projéteis velozes em leque amplo; girar pelos quatro pilares do Santuário ou atravessar o eixo central na esquiva abre a principal janela de punição para encaixar combos e o Selo `[Q]` antes da próxima dobra.
  - **Habilidade de Pressão/Reação — *Decreto da Fenda Vertical*:** Ao atingir 50% de Vida e nos picos da Fase 2, traça uma linha longa de ruptura espacial no eixo da câmara (`0,70 s` de aviso) enquanto invoca Ecos Perdidos nos flancos opostos, forçando limpeza limpa na rotação ou contra-abertura da Expansão de Domínio do Iniciado.
- **Recompensa e Espólio (Loot):**
  - *Material:* **Coração de Fenda Selado** — singularidade estável colhida do eixo do Arconte, catalisador supremo de reforja e alquimia de Domínio.
  - *Gancho Narrativo / Item Raro:* **Lascas da Cúpula de Cristal Azul-Gelo** — seis estilhaços que, reunidos sob a luz quente do Campus, não refletem o rosto do Iniciado, mas a silhueta distante de uma cratera além do quarto círculo.

---

### Ficha de Ambiente Ativo — Região 4: *O Observatório Despedaçado*

- **Efeito Passivo do Terreno:** **Ressonância de Domínio Desfeito** — As lajes flutuantes de cristal azul-gelo preservam o eco de Expansões anteriores; sempre que o jogador ou um chefe ativa uma técnica de grande custo de Fluxo, o piso ressoa por `3 s` ampliando levemente o ganho de Fluxo por acertos limpos, premiando agressividade precisa.
- **Perigos Dinâmicos:**
  1. **Cicatrização da Fenda Vertical:** Periodicamente, fendas finas rasgam as juntas entre as lajes flutuantes (`0,85 s` de linha magenta nítida) antes de se fecharem com estalo gravitacional que fere e puxa quem permanece sobre a emenda, exigindo transições constantes entre lajes.
  2. **Refração de Cristal Caído:** Projéteis inimigos (de Fendas Errantes ou do Arconte) que acertam as arestas de cristal quebrado nas bordas externas dividem-se em dois estilhaços lentos em `45°`, punindo quem recua encostado às paredes em vez de girar pelos pilares centrais.
- **Neutralização / Uso a Favor:** **Sintonizar os Pilares de Cristal** — Os quatro pilares íntegros do Santuário absorvem descargas inimigas sem refração e acumulam carga azul-dourada visível; acertar um pilar carregado com golpe pesado dispara uma onda purificadora que apaga projéteis próximos, atordoa brevemente inimigos menores e quebra escudos de líderes como o Coro Fraturado.

---

## Verificação de Consistência e Notas Interdisciplinares

### Consistência de Cânone (`Contradictions Check`)
1. **Distribuição Regional das 12 Criaturas (3 por Círculo):**
   - `anomalia_menor` tem seu ninho primário no **Veio Instável** (`veio_instavel`), onde o Fluxo cru brota em excesso; a ecologia preserva explicitamente que exemplares desgarrados vazam para o **Limiar da Beira**, mantendo consistência com `game-concept.md` e os encontros iniciais.
   - `fenda_errante` tem sua origem primária no **Santuário Partido** (`santuario_partido`), nascendo da cúpula partida; a ecologia preserva que correntes de pressão arrastam exemplares até o **Veio Instável**, mantendo consistência total com o relato do batedor em `eco_veio_02` (`codex_historia.gd`).
2. **Dualidade Hostil vs. Pactuada (`maldicoes.md` & `chefes.md`):**
   - `vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza` e `soberano_do_limiar` preservam integralmente suas silhuetas, nomes de habilidades (*Paredes de Sombra*, *Rastro Cortante*, *Quebra-Limiar*, *Cratera de Cinza*, *Garra do Véu Rasgado*, *Irrupção do Limiar*, *Pulso de Soberania*, *Convergência da Fenda*) e a regra visual do Art Bible §3.3 (selvagens exibem magenta nu; pactuadas usam amarras/fios cor de osso e nunca expõem magenta em repouso).
3. **Lore Freeze (Pilar P5):**
   - Nenhum texto inventa cosmologia paralela para a causa do Colapso, a Mentira ou os 7 Invioláveis; todos os ganchos de espólio operam como fragmentos investigativos abertos.

### Sinalizações para Coordenação (Pós-Aprovação)
- **`game-designer`:** Validar em GDDs futuros (`ia-inimigos`, `camaras-e-ondas`, `chefes` pós-MVP e economia/crafting) os parâmetros numéricos exatos de `brasa_errante`, `coro_fraturado`, os kits expandidos de Patamar 2–4 fora do MVP, os 4 Ambientes Ativos e a tabela de conversão dos 12 materiais de espólio.
- **`level-designer`:** Incorporar a geometria de interação dos 4 Ambientes Ativos (lajes periféricas no Limiar, fissuras diagonais no Veio, grelhas/válvulas no Fosso, pilares sintonizáveis/bordas refrativas no Santuário) respeitando a regra de chão limpo para telégrafos.
- **`art-director`:** Validar os sprites 2D de `brasa_errante` (cascas de escória orbitais) e `coro_fraturado` (halo partido de cinco placas) no teste da miniatura em `48 px` e garantir que a paleta de brasa-magenta do Fosso jamais compita com os telégrafos SDF.
- **`narrative-director`:** Aprovar promoção de `Provisional` para `Established` das 2 novas criaturas (`brasa_errante`, `coro_fraturado`) e dos 12 ganchos narrativos de espólio (especialmente a pista da sexta voz na *Partitura Rasgada dos Cinco Selos* e o cinzel da Transmutação no Fosso).

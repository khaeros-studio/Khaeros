# Art Bible: Khaeros

> **Status**: Approved — as 9 seções aprovadas uma a uma pelo CD em 2026-11-05
> **Owned By**: art-director
> **Last Updated**: 2026-11-05
> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED 2026-11-05 — lean mode

`/art-bible` writes these nine sections in this order and replaces each
section's `[To be designed]` line as that section is approved. A section still
holding its placeholder is incomplete; a later run fills only those.

## 1. Visual Identity Statement

*Aprovada pelo CD em 2026-11-05.*

### Regra visual central

> **Da sombra, só sai o que fere ou o que se escolhe.**

A Beira é um lugar escuro, desenhado à mão com tinta preta pesada. Tudo o que é
ambiente (chão, paredes, primeiro plano, névoa) fica em valores frios e
contidos. A saturação, o brilho e o contraste máximo ficam reservados a duas
coisas: o que pode ferir o jogador (telégrafos, ataques, inimigos em ação, Fluxo
cru) e o que o jogador pode escolher (cartas de bênção, portas, interativos,
preços). Se um elemento não é perigo nem escolha, ele recua.

**Por que esta regra.** Num roguelike de ação com câmera 3/4 e personagem a
~1/12 da altura da tela, a pergunta que mais se repete é "para onde o olho vai
agora?". A regra responde a essa pergunta e carrega as referências sem copiar
nenhuma:
- de Hollow Knight vem a paleta contida, com cor só onde significa algo;
- de Hades II vem a legibilidade do combate como prioridade;
- de Jujutsu Kaisen vêm as manchas de preto, que fazem da sombra uma presença
  ativa e não só ausência de luz.

Ela também serve ao P5: o que não fere nem se escolhe fica na sombra, e o mundo
mostra só fragmentos de si.

### Princípios de apoio

**1. O fundo cede ao telégrafo.** *(Serve ao P3 — Reflexo que se lê)*

Todo ataque inimigo é telegrafado no chão, e o jogador só pode ser culpado por
morrer se conseguir ler esse aviso. Por isso a legibilidade do combate vence a
atmosfera, sempre. O chão sob a área de combate é um plano achatado de valor
médio-escuro e baixa saturação, com textura só nas bordas. As silhuetas de
inimigos e do jogador precisam funcionar em preenchimento preto sólido, e o
traço preto grosso garante esse recorte contra qualquer fundo.

*Teste de design:* quando um elemento de ambiente (veio de Fluxo, névoa,
detalhe pintado) competir com um telégrafo ou uma silhueta, o ambiente perde
valor, saturação ou contraste naquele ponto, nunca o contrário. Se um revisor
não consegue apontar a área de dano num print em menos de meio segundo, o fundo
está errado.

**2. Cor é significado, e o preço tem cor.** *(Serve ao P2 — A Beira cobra)*

A paleta é de escuros frios com dois acentos, cada um com significado fixo:
- **magenta de Fluxo**: instabilidade, perigo e custo (veios, Anomalias, o
  preço de uma bênção);
- **dourado**: elite, ritual e consagração (chefes e elites, o Campus, o ganho
  de uma bênção).

O preço aparece na própria imagem, em magenta ao lado do ganho em dourado, e o
jogador lê o custo de qualquer vantagem sem texto. Nenhuma cor de acento é
usada como decoração.

*Teste de design:* quando um elemento pedir destaque, pergunte o que ele
significa. Se é perigo ou custo, usa magenta. Se é poder, elite ou rito, usa
dourado. Se não é nada disso, fica dessaturado nos escuros frios, por mais
bonito que fique com cor.

**3. Filosofia vira forma antes de virar cor.** *(Serve ao P1 — Toda bênção é uma filosofia)*

Como magenta e dourado já têm significado fixo, a cor não pode distinguir
Tradições nem Doutrinas. Cada uma das 6 é reconhecida pela linguagem de forma da
sua silhueta, do seu gesto e dos seus ícones: Lâmina com ângulos agudos,
Guardião com massas largas e estáveis, Véu com contornos que se dissolvem, e
assim por diante (detalhado na Seção 3). Uma carta de bênção deve parecer o que
a Tradição acredita e ser identificável num relance, mesmo em tons de cinza.

*Teste de design:* quando duas Tradições, cartas ou Mestres parecerem
parecidos, diferencie primeiro pela silhueta e pela forma dominante, depois pelo
ornamento do traço (hachura, espessura, ritmo). Nunca só pelo matiz. Um desenho
que só se distingue trocando a cor está errado.

### Notas de aplicação

- **Estilo de execução:** ilustração de quadrinho com traço preto de espessura
  consistente, hachuras e manchas de preto, cel-shading de 2 a 3 tons. A
  pixel-art isométrica está **descartada** como estilo. Teste: se o elemento não
  foi desenhado com o peso de tinta do resto, ele não pertence à Beira.
- **P4 (Ritual, não pressão)** fica fora dos princípios de propósito. É servido
  pelo contraste entre lugares: o Campus tem sombra mais quente e dourado
  doméstico, e a Beira tem o frio e o magenta. A paleta que muda de lugar já
  comunica "voltar para casa".
- **Magenta dos veios × telégrafos:** resolvido na Seção 4.5 (o telégrafo é dono
  do topo da escada de valor e se distingue por forma e movimento). A regra de
  desempate continua valendo: se o P3 ficar ambíguo, o P3 vence.

## 2. Mood & Atmosphere

*Aprovada pelo CD em 2026-11-05.*

Khaeros alterna entre dois polos: **casa** (Campus, quente, P4) e **cobrança**
(Beira, fria, P2). Cada estado se define por quatro controles: temperatura,
contraste, direção da luz e densidade de névoa. Uma regra vale para todos os
estados de combate: **a névoa nunca cobre o chão de combate** (P3). Ela vive no
primeiro plano, nas bordas da câmara e na faixa superior da tela, que faz o
papel do céu.

Escala de energia: 1 (repouso) a 5 (pico).

### 2.1 Campus da Academia — "voltar para casa"
- **Emoção-alvo:** alívio e pertencimento, com uma ponta de inquietação institucional.
- **Luz:** quente (âmbar de lamparina), contraste médio-baixo, lateral baixa vinda de janelas e lamparinas, sombras longas e macias.
- **Descritores:** acolhedor, gasto, habitado, poeira dourada, falível.
- **Energia:** 1–2.
- **O que carrega o clima:** feixes de poeira dourada nas janelas e lamparinas acesas. É a única luz doméstica do jogo. As manchas de preto existem, mas recuadas nos cantos.

*Por quê:* P4. É o único estado em que a luz quente domina, e a volta precisa
ser sentida antes de qualquer texto. As sombras são marrom-violáceas e alguns
corredores escapam da luz: a Academia não é inocente (P5).

### 2.2 Limiar da Beira — "o primeiro frio"
- **Emoção-alvo:** apreensão contida, melancolia, curiosidade cautelosa.
- **Luz:** fria, cinza-azulada, difusa e sem fonte definida (um céu encoberto que não se vê). Contraste baixo nos planos distantes e médio no chão.
- **Descritores:** nevoento, silencioso, erodido, suspenso, desbotado.
- **Energia:** 2 fora de combate, 3 em combate.
- **O que carrega o clima:** névoa de profundidade densa no topo da tela, engolindo as ruínas a meia distância. Fendas de magenta pequenas e raras, como se a Beira ainda se contivesse.

*Por quê:* é a região que ensina a ler. Com o ambiente em baixo contraste, os
telégrafos não competem com nada, e o jogador aprende a gramática visual sem
ruído.

### 2.3 Veio Instável — "a Beira mostrando os dentes"
- **Emoção-alvo:** tensão, hostilidade, a sensação de um lugar que machuca.
- **Luz:** ar frio esverdeado (petróleo). A luz vem **de baixo para cima**, dos veios magenta nas paredes. Contraste alto, pretos mais fundos e mais manchas de preto.
- **Descritores:** rachado, pulsante, cortante, abafado, febril.
- **Energia:** 3–4.
- **O que carrega o clima:** veios de Fluxo cru correndo por paredes e bordas, pulsando devagar. A luz de baixo inverte a leitura natural (as sombras sobem), e algo parece errado. Névoa baixa e pesada, rente às bordas.

*Por quê:* P2. O magenta está em toda parte porque o custo está em toda parte.
O chão de combate continua limpo (P3, ver Seção 4).

**Câmara limpa (transição dentro das regiões).** Quando cai a última onda, a
névoa recua um pouco, o grading clareia levemente e as portas acendem em
dourado. É um respiro de 1–2 s que marca "agora é escolha". A energia cai um
nível.

### 2.4 Santuário Esquecido — "alguém cuidou disto"
- **Emoção-alvo:** respiro, ternura melancólica, mistério (quem manteve isto de pé?).
- **Luz:** **uma única** fonte quente, pequena e baixa (um braseiro), no centro. O resto é pedra cinza-quente. Contraste médio, concentrado na poça de luz.
- **Descritores:** abrigado, quieto, gasto, cuidadoso, íntimo.
- **Energia:** 1.
- **O que carrega o clima:** um arco de pedra baixo que abraça a luz, sinais de manutenção (pedras recolocadas, pano dobrado; ver Seção 6) e a névoa da região parando na soleira, sem entrar.

*Por quê:* é o eco do Campus dentro da Beira (P4), da mesma família quente,
porém menor e mais frágil. O Campus tem muitas fontes de luz; o Santuário tem
uma. É um abrigo, não uma casa. O cuidado é visível, e quem cuidou não aparece
(P5).

### 2.5 Altar de Provação e elites — "a aposta"
- **Emoção-alvo:** ousadia, adrenalina de um risco escolhido, solenidade.
- **Luz:** a câmara mantém o matiz da região, mas a luz-chave vira **zenital** (de cima), dura e branco-dourada. Contraste alto, sombras curtas sob cada figura, como um holofote ritual.
- **Descritores:** solene, exposto, cerimonial, ameaçador, consagrado.
- **Energia:** 4.
- **O que carrega o clima:** a aura dourada pulsante e a coroa de espinhos das elites. Na porta, uma moldura dourada atravessada por rachaduras magenta: o ganho e o preço aparecem juntos antes de entrar.

*Por quê:* P2. Um risco escolhido vira rito, e a luz de cima transforma a
câmara num palco de prova. A diferença para o Veio é a direção: lá a luz sobe
do chão (caos), aqui desce do alto (rito).

### 2.6 Tela de bênção — "a voz do Mestre"
- **Emoção-alvo:** pausa reverente, deliberação, tentação.
- **Luz:** o mundo congela e cai para quase monocromático (saturação de 15–25%, valor reduzido em cerca de 40%), sobrando só tinta e névoa. As cartas são a única coisa iluminada: base osso/papel, dourado no ganho, magenta no preço. Luz frontal, sem direção física, porque é ressonância e não um lugar.
- **Descritores:** suspenso, íntimo, reverente, nítido, tentador.
- **Energia:** 2, com tensão de escolha.
- **O que carrega o clima:** o "congelamento em tinta". Partículas de Fluxo param no ar e o mundo vira gravura. A forma da Doutrina (Seção 3) domina cada carta, e a insígnia do Mestre aparece em silhueta.

*Por quê:* P1. Isolar as cartas tira qualquer outra pergunta da frente. Com o
fundo monocromático, o dourado e o magenta das cartas leem como significado
puro (P2).

### 2.7 Chefes — "o que ganhou forma"
Cada chefe encarna um dos dois acentos e é o ápice de cor da sua região.

**Anomalia Maior (fim do Limiar)**
- **Emoção-alvo:** assombro e repulsa (o grotesco de Jujutsu Kaisen).
- **Luz:** a névoa fria se abre em círculo e o **vórtice magenta do próprio chefe** vira a luz principal. A luz vem do inimigo. Contraste alto.
- **Descritores:** colossal, faminto, viscoso, hipnótico.
- **Energia:** 5.
- **O que carrega o clima:** o vórtice e os cristais. A arena é a câmara mais escura e mais limpa do Limiar, para que ele seja a única coisa clara.

**Guardião do Rito (fim do Veio)**
- **Emoção-alvo:** gravidade, o confronto com uma lei.
- **Luz:** os veios se **apagam** ao redor da arena, o petróleo recua e uma luz zenital dourada e dura cai sobre o Guardião. Contraste máximo, composição simétrica.
- **Descritores:** solene, implacável, metálico, cerimonial.
- **Energia:** 5.
- **O que carrega o clima:** reflexos dourados na armadura e uma arena simétrica.

*Diferença para o Altar:* no Altar o dourado aparece só nas elites, sobre o
matiz da região. No Guardião o dourado domina a cena e a região se cala. Mesmo
nos chefes valem as regras de telégrafo da Seção 4.

### 2.8 Morte — "a tinta engole"
- **Emoção-alvo:** perda seca, sem humilhação. A aceitação de "de novo".
- **Luz:** hitstop longo **antes** de escurecer, para o jogador ver o que o atingiu. Depois a cor drena em cerca de 0,5 s até sobrar só tinta e osso. Manchas de preto avançam das bordas para o centro, e o Iniciado é a última luz a sumir.
- **Descritores:** súbito, silencioso, gráfico, final, breve.
- **Energia:** de 5 a 0, em queda abrupta.
- **O que carrega o clima:** a vinheta de tinta fechando sobre o personagem como o último quadro de uma página.

*Por quê:* P3, porque a causa da morte fica legível no quadro congelado. P4,
porque a morte é curta e corta direto para o calor do Campus.

### 2.9 Vitória sobre chefe e retorno — "o fôlego depois"
- **Emoção-alvo:** catarse, alívio, orgulho e saudade de casa.
- **Luz:** o golpe final vira um *impact frame* em osso com manchas pretas. Depois o acento do chefe se dissipa (o magenta se desfaz em partículas ou o dourado se apaga) e a arena esquenta alguns graus. O retorno ao Campus é uma transição de frio para quente.
- **Descritores:** explosivo, depois sereno, luminoso, aberto.
- **Energia:** de 5 a 2.
- **O que carrega o clima:** a névoa se ergue e revela um pedaço de fundo nunca visto, um fragmento do mundo (P5).

### 2.10 Matriz de distinção

| Estado | Temperatura | Contraste | Direção da luz | Névoa | Energia |
|---|---|---|---|---|---|
| Campus | quente (âmbar) | médio-baixo | lateral baixa, várias fontes | quase nenhuma (poeira) | 1–2 |
| Limiar | fria azulada | baixo | difusa, sem fonte | densa (topo e bordas) | 2–3 |
| Veio | fria esverdeada + magenta | alto | de baixo (veios) | baixa e pesada nas bordas | 3–4 |
| Santuário | quente pálida | médio, concentrado | do centro, uma fonte | barrada na soleira | 1 |
| Altar/elite | região + dourado | alto | zenital dura | da região | 4 |
| Bênção | neutra (mundo) + cartas | máximo (carta × mundo) | frontal, não física | congelada | 2 |
| Anomalia Maior | fria + magenta do chefe | alto | vem do chefe | aberta em círculo | 5 |
| Guardião do Rito | dourada | máximo | zenital, simétrica | recuada | 5 |
| Morte | sem cor | gráfico (tinta/osso) | nenhuma; a tinta fecha | — | 5 → 0 |
| Vitória/retorno | esquentando | alto → médio | abre-se | se ergue | 5 → 2 |

## 3. Shape Language

*Aprovada pelo CD em 2026-11-05.*

### 3.1 Filosofia de silhueta *(P3, P1)*

- **Teste da miniatura.** Todo personagem, preenchido de preto sólido e reduzido
  a **48 px de altura** (cerca de metade do tamanho em jogo a 1080p, onde 1/12 da
  tela dá ~90 px), tem que ser identificável pelo arquétipo e pela direção para
  onde aponta. Se precisa de cor para ser reconhecido, a forma falhou.
- **Um traço distintivo por arquétipo**, no terço superior ou na extremidade
  voltada ao perigo: o capuz do Eco, o leque de cristais da Anomalia, a coroa da
  elite, a arma do jogador.
- **A silhueta revela o comportamento.** O jogador deve prever o ataque pela
  forma, antes do telégrafo:

| Comportamento | Forma | Exemplo |
|---|---|---|
| corpo a corpo | vertical, arma ou braços destacados do corpo | Eco Perdido, Eco do Veio |
| à distância | baixa e larga, com um **ponto emissor** visível (boca, olho, núcleo) | Anomalia Menor, Anomalia do Veio |
| investida | **cunha horizontal** apontando a direção do avanço | Fenda Errante |
| investida pesada | bloco facetado com uma frente plana | Estilhaço Vivo |

- **Espaço negativo na antecipação:** em toda pose de preparação, a arma ou o
  membro que vai atacar se afasta do corpo. É isso que torna a antecipação
  legível.

### 3.2 Ecos e Anomalias: duas famílias opostas *(P5, P3)*

| | **Eco** | **Anomalia** |
|---|---|---|
| Ideia | humano **subtraído** (o erro é a falta) | forma **imitada com excesso** (o erro é a sobra) |
| Contorno | humano (capuz, ombros, braços); a metade inferior se desfaz em fiapos de tinta, sem pés | fechado e duro; imita bicho (sapo, aranha, vespa, lodo) |
| Traço | quebrado e tracejado na base, como tinta escorrendo | contínuo, com cristais **facetados retos** brotando do corpo orgânico |
| Erro anatômico | partes que faltam: rosto vazio, mãos incompletas | partes a mais: articulações, olhos, simetria quebrada |
| Movimento | humano, arrastado, lembra alguém | animal com espasmos, ritmo errado |
| Cor | interior claro de névoa, sem acento | magenta nos cristais e no ponto emissor |

O Eco do Veio é o Eco Perdido inclinado para a frente, com fiapos mais longos
que leem como velocidade. O Estilhaço Vivo é uma Anomalia mineral: mais cristal
que corpo.

*Por quê:* duas famílias aprendidas uma vez ajudam a leitura imediata (P3) e
contam o mundo sem texto (P5). Os Ecos herdam a melancolia de Hollow Knight; as
Anomalias, o grotesco de Jujutsu Kaisen.

**Elites:** a coroa de espinhos acrescenta pontas verticais no topo e quebra a
silhueta para cima. A elite é reconhecível mesmo em preto, sem depender da aura.

**Chefes:**
- **Anomalia Maior:** massa baixa, larguíssima e arredondada (o sapo), com
  cristais irradiando. Domina o horizontal.
- **Guardião do Rito:** vertical, simétrico, feito de retângulos e triângulos em
  pé (armadura, lança, escudo). Domina o vertical.

Os dois chefes são opostos em forma, assim como são opostos em cor.

### 3.3 Forma dominante das 6 Doutrinas *(P1)*

Regra: cada Doutrina é **uma forma geométrica primária**, repetida na arma, no
ícone, no gesto, no topo da carta e na insígnia do Mestre. O teste é em tons de
cinza: as seis têm que se distinguir sem cor.

| Doutrina (Mestre) | Forma dominante | Arma (silhueta) | Ícone | Gesto / pose | Traço e hachura |
|---|---|---|---|---|---|
| **Lâmina** (Halvar) | linha diagonal, triângulo estreito: foco num ponto | espada reta e longa, guarda mínima; a silhueta é uma linha | um único traço diagonal atravessando um círculo | inclinado para a frente, peso no pé dianteiro, arco de corte curto e rápido | linhas longas e contínuas de velocidade; hachura paralela numa só direção |
| **Guardião** (Berrin) | trapézio de base larga, quadrado: massa estável | escudo-bastião retangular grande + golpe curto e pesado | escudo trapezoidal sobre uma linha de chão | plantado, base larga, escudo à frente, movimentos curtos | o traço mais grosso, cantos firmes; hachura cruzada densa |
| **Véu** (Endra) | crescente, contorno aberto que não fecha | adagas curvas pequenas, em crescente | círculo com metade engolida por mancha de preto | agachado, de perfil, assimétrico, ataca pelo lado | traço interrompido, contornos com falhas; manchas de preto cobrindo metade |
| **Ressonância** (Maren) | círculos concêntricos, onda chegando à borda | foco ou cajado com anel ou orbe suspenso | anéis concêntricos com o externo **quase tocando** a moldura (perto do limite) | braço estendido, emanação radial, equilíbrio tenso | traço duplo vibrando; linhas concêntricas |
| **Transmutação** (Oreth) | espiral, ciclo: uma forma que vira outra | cálice (triângulo invertido sobre haste) | gota dentro de uma espiral | verter e arremessar em arco, movimento circular | curvas que mudam de espessura; manchas que escorrem |
| **Pactos** (Sorcha) | par ligado: duas massas unidas por uma linha | **besta**, a única arma de silhueta horizontal em T | duas formas unidas por um fio | recuado, mira estável, corpo voltado para o aliado na linha de frente | duas espessuras de traço convivendo (a sua e a da criatura) |

**Criatura do pacto (Pactos).** É um resíduo de Anomalia vinculado, então usa a
gramática de Anomalia: massa baixa, de quatro patas, com cristais. Ser aliada
**cria um risco de P3**: ela pode ser lida como inimiga. A forma resolve isso de
três jeitos:
- um **fio de vínculo** em traço osso ligando-a ao jogador, sempre visível;
- os cristais **envoltos em amarras** cor de osso, "selados", o que dá uma
  silhueta com faixas que nenhuma Anomalia inimiga tem;
- a insígnia de Pactos (as duas formas unidas) marcada no corpo.

Quanto magenta ela mantém é decidido na Seção 4.

**As cartas herdam a forma no topo da moldura:** Lâmina em ponta, Guardião em
topo reto e largo, Véu com recorte assimétrico e rasgado, Ressonância em arco,
Transmutação em voluta, Pactos em topo geminado.

### 3.4 Geometria de ambiente *(P3, P5)*

- **Bordas pintadas e orgânicas**, sem grade aparente. As paredes formam curvas
  côncavas que abraçam a arena e concentram o peso visual nas bordas.
- **O chão de combate não tem formas internas fortes.** Círculos, cones e linhas
  retas longas pintados no chão são **vocabulário exclusivo do telégrafo** e não
  podem aparecer como decoração. Rachaduras e texturas do chão são ramificadas e
  irregulares.
- **Primeiro plano em silhueta chapada de tinta**, sem traço interno, ocupando no
  máximo cerca de 15% da tela e nunca sobre a área jogável. Ele emoldura e não
  esconde.
- **Vocabulário de forma por lugar:**

| Lugar | Formas | Leitura |
|---|---|---|
| Campus | arcos, retângulos, verticais estáveis | ordem humana, instituição |
| Limiar | horizontais arredondadas e erodidas, ruínas suaves | algo que já foi e está sumindo |
| Veio | diagonais, rachaduras, cristais facetados | instabilidade cortante |
| Santuário | arco baixo e simétrico, forma de abraço | abrigo mantido de propósito |
| Altar | anel, com verticais em espinho ao redor | rito e prova (ecoa a coroa das elites) |

### 3.5 Formas-herói e formas de apoio *(P3, regra central)*

| Camada | O que entra | Contorno | Peso do traço (1080p) |
|---|---|---|---|
| **Telégrafo** | áreas de ataque inimigo | fechado, geométrico e limpo | **~4 px** (o mais grosso do jogo) |
| **Herói** | jogador, inimigos, criatura do pacto, interativos, portas | fechado, convexo e simples | ~3 px (referência = 1,0) |
| **Apoio** | paredes, objetos de cena, detalhe de chão | aberto, quebrado, hachurado | ~1,5 px (0,5) |
| **Moldura** | primeiro plano | sem traço: mancha chapada de tinta | — |

*Por quê:* o olho vai primeiro aos contornos fechados e grossos. Com a
hierarquia de traço espelhando a hierarquia de importância, a regra central da
Seção 1 vale também na linha, e não só na cor.

### 3.6 Gramática da UI *(P1, P2; detalhe na Seção 7)*

- **Molduras retangulares com cantos chanfrados a 45°**, desenhadas no mesmo
  traço de tinta do mundo. A UI parece desenhada, não um vetor limpo.
- **Cartas verticais**, com o topo na forma da Doutrina (3.3).
- **Ganho e preço por forma:**
  - **ganho** = formas que se abrem ou irradiam (raios, estrela de quatro pontas);
  - **preço** = formas partidas (losango rachado, gota partida).
- **Raridade por ornamento**, nunca só por cor: Comum com moldura simples, Rara
  com moldura dupla, Épica com moldura recortada e ornamentada.
- **Ícones do HUD com formas distintas:** Vida em barra segmentada, Fluxo em gota
  ou veio, cargas de esquiva em chevrons, Fragmentos em estilhaço.
- **Ícones de porta** inscritos num arco, legíveis a 32 px.

## 4. Color System

*Aprovada pelo CD em 2026-11-05. Decisões: telégrafo por valor e forma (opção a);
Veio Instável em petróleo; criatura do pacto com magenta selado.*

### 4.1 Paleta primária

| # | Nome | HEX aprox. | Papel | Nunca usar para |
|---|---|---|---|---|
| 1 | **Tinta** | `#0D0E14` | traço, manchas de preto, silhueta, primeiro plano | — |
| 2 | **Ardósia da Beira** | `#2B3240` (chão: `#343C4A`) | chão de combate, paredes, plano de jogo | destaque de qualquer coisa |
| 3 | **Névoa** | `#6F8494` (base do Limiar; variantes em 4.4) | atmosfera, planos distantes, interior dos Ecos | chão de combate |
| 4 | **Osso** | `#E6DFCF` (no mundo, até `#CFC6B4`) | luz de leitura: jogador, texto, cartas, impact frames, fio de vínculo | áreas grandes de ambiente |
| 5 | **Magenta de Fluxo** | `#E0259C` | instabilidade, perigo, custo: Anomalias, veios, preço, HUD de Fluxo | decoração |
| 6 | **Dourado de Rito** | `#E3B23C` | elite, rito, consagração, ganho, portas abertas, foco da UI | decoração; nada da Beira comum |
| 7 | **Âmbar do Campus** | `#9A6A3E` | cor regional da casa: sombras e luz do Campus e do Santuário | acento; nunca na Beira fora do Santuário |

O âmbar é cor de **lugar**, não de significado. Ele é mais escuro e menos
saturado que o dourado para que os dois não se confundam. O dourado diz "isto é
consagrado"; o âmbar diz "isto é casa".

### 4.2 Escada de valor (o eixo que garante o P3)

Luminosidade aproximada em L* (CIELAB, de 0 a 100). É o canal mais robusto para
leitura rápida e para daltonismo.

| Faixa | L* | Quem ocupa |
|---|---|---|
| Tinta | 0–10 | traço, manchas, primeiro plano |
| Fundo profundo | 10–25 | paredes, sombras |
| Chão de combate | 22–38 | plano de jogo |
| Névoa e planos distantes | 35–55 | bordas, topo da tela |
| Teto do magenta ambiente | ≤ 45 | veios e fendas |
| Personagens (interior) | 40–80 | inimigos, jogador (o osso do jogador fica ≤ 82 no mundo) |
| Escolhas | 70–90 | cartas, portas, interativos (fora de combate) |
| **Telégrafo (núcleo)** | **≥ 88** | **só telégrafo e impact frame** |

**Regra:** o núcleo do telégrafo fica pelo menos **40 pontos de L* acima** do
chão por baixo dele. A escada acima garante cerca de 50.

### 4.3 Vocabulário semântico

| Significado | Cor | Forma de apoio obrigatória |
|---|---|---|
| Ataque inimigo iminente | família magenta no topo da escada (4.5) | borda de tinta grossa + preenchimento que cresce |
| Instabilidade ambiente | magenta abaixo do teto | ramificado e orgânico, nunca geométrico |
| Anomalia (corpo) | magenta nos cristais e no ponto emissor, L* ≤ 70 | gramática de excesso (3.2) |
| Eco | névoa clara, sem acento | gramática de falta (3.2) |
| Elite | aura dourada pulsante | coroa de espinhos |
| Ganho (bênção, recompensa) | dourado | formas que irradiam |
| Preço (custo da bênção) | magenta | formas partidas |
| Escolha disponível (porta, interativo) | moldura dourada | arco da porta + ícone |
| Porta do Altar de Provação | dourado com rachaduras magenta | coroa de espinhos no ícone |
| Ação do jogador (golpe, Selo) | osso + manchas de tinta | contorno **tracejado** e fino, sem a borda grossa nem o preenchimento crescente do telégrafo |
| Aliado (criatura do pacto) | tinta e osso, **magenta selado** (só uma brasa interna) | fio de vínculo + amarras |

**Regra sobre as habilidades do jogador:** o Selo gasta Fluxo, mas **a área do
Selo não é magenta**. Ela é osso, com partículas magenta dentro, em contorno
tracejado. Assim o jogador nunca confunde a própria área com um aviso inimigo.

### 4.4 Matiz e temperatura por região (Valheim traduzido para 2D pintado)

O que vem de Valheim é a **ideia**, não a técnica: um matiz por região, a névoa
que carrega esse matiz, a luz volumétrica que dá o tom e o céu como a voz da
região. A tradução para a Beira:

1. **Névoa em faixas de cel-shading.** Duas ou três bandas chapadas, não
   gradiente suave, mais densas no topo da tela (o fundo, em 3/4) e nas bordas.
   Nunca sobre o chão de combate.
2. **O teto de névoa faz o papel do céu.** A faixa superior da tela é onde a
   região diz o seu tom.
3. **Feixes de luz pintados.** Uma camada aditiva de baixa opacidade (≤ 20%), em
   diagonais, sempre fora do chão de combate.
4. **Grading regional aplicado só às camadas de ambiente.** Personagens recebem
   no máximo 15% do tingimento, como luz de recorte. **Telégrafos e UI recebem
   0%.** (A implementação fica com o technical-artist.)
5. **Profundidade dentro da região.** Cada câmara mais funda escurece um pouco.
   O jogador sente progresso sem que o matiz mude.

O que evitar para não copiar Valheim: névoa volumétrica realista, gradientes
suaves de 3D e texturas low-poly. Aqui a névoa é tinta chapada em faixas.

| Lugar | Matiz dominante (névoa/ar) | Luz-chave | Sombra | Contraste | Acentos permitidos |
|---|---|---|---|---|---|
| **Campus** | âmbar `#8A6A4E` | lamparina `#F2C98A`, lateral baixa | marrom-violáceo `#2B1F26` | médio-baixo | dourado doméstico abundante; magenta quase ausente |
| **Limiar** | cinza-azulado `#6F8494` | difusa `#B8C4CE`, sem direção | `#18202A` | baixo | magenta raro e pequeno |
| **Veio** | petróleo `#2C4F50` | luz de baixo vinda dos veios, só nas paredes; ar `#5E8A86` | `#0A1517` | alto | magenta abundante nas paredes e bordas, sempre abaixo do teto |
| **Santuário** | pedra neutra-quente `#5C554D` | braseiro `#E2B874`, central | `#1D1917` | médio, concentrado | dourado doméstico em uma única fonte |
| **Altar** | herda a região | zenital dura `#F3E4B5` | herda | alto | dourado nas elites + magenta da região |
| **Tela de bênção** | o mundo a 15–25% de saturação, valor reduzido em ~40% | frontal (cartas) | tinta | máximo | dourado e magenta só nas cartas |

*Por que petróleo no Veio:* é o complementar do magenta. Os veios leem como algo
estranho que fere o lugar, e a névoa fica longe do matiz do telégrafo. O Limiar
azulado-claro e o Veio esverdeado-escuro se separam em matiz e em valor.

### 4.5 Telégrafos: canal próprio de valor e forma

O Veio Instável é cheio de magenta, e magenta significa perigo. Para o aviso de
ataque nunca se perder nos veios, o telégrafo continua na família magenta, mas é
**dono exclusivo do topo da escada de valor** e se distingue também por forma e
movimento.

- **Cores:** núcleo `#FFD3EE` (L* ≈ 88), anel interno magenta pleno `#FF3DAE`,
  contorno de tinta `#0D0E14` com ~4 px a 1080p (1,33× o traço de herói).
- **Movimento:** durante a antecipação, o preenchimento cresce da borda para o
  centro (ou do centro para fora, por tipo de ataque). No disparo, um flash de
  osso por 2 frames. **O telégrafo nunca pulsa; ele cresce.**
- **Magenta ambiente:** teto de L* ≤ 45 e saturação ≤ 60% (HSV). Nunca tem
  contorno grosso e nunca forma geometria fechada (círculo, cone, linha reta). Os
  veios são sempre ramificados.
- **Ritmo dos veios:** pulsação lenta (ciclo ≥ 2 s, amplitude ≤ 10% de valor),
  um ritmo que nunca coincide com o crescimento do telégrafo.
- **Zona de silêncio:** veios a menos de ~1 altura de personagem da borda do
  chão de combate escurecem um passo na escada. Dentro do chão, só como
  rachaduras escuras e sem brilho.
- **Corpos magenta:** Anomalias e a Anomalia Maior ficam com L* ≤ 70. O núcleo do
  vórtice pode brilhar mais, mas o telégrafo é desenhado acima de tudo, com
  contorno de tinta separando os dois.

*Alternativa rejeitada (registro):* telégrafo vermelho-brasa exclusivo
(`#FF5A26`). Separava por matiz, mas criava um terceiro acento, convergia com o
dourado das elites em protanopia e deuteranopia e ainda precisaria da borda
grossa e do canal de valor.

### 4.6 Paleta de UI e onde ela diverge do mundo

A UI usa as mesmas sete cores da paleta, com quatro divergências deliberadas:

1. **Nunca recebe grading regional nem névoa.** O HUD tem a mesma cor no Campus
   e no Veio, e é isso que o torna confiável.
2. **Pode usar osso chapado em áreas grandes** (cartas, painéis de texto). O
   mundo nunca faz isso. O osso é o "papel" da UI.
3. **Painéis em tinta a 85–90% de opacidade sem texto e ≥ 92% com texto**
   (emenda de 2026-11-05, Seção 7.3), com o traço chanfrado da Seção 3.6.
4. **O dourado também marca foco e seleção** (cursor, carta em destaque).
   Escolha é consagração, então o significado se mantém.

Mais duas regras:
- **Texto magenta só em números de preço.** Corpo de texto é **osso sobre tinta
  em painéis e tinta sobre osso em cartas e fichas** (emenda de 2026-11-05; os
  dois dão ~14:1).
- **A Vida é osso, não vermelha** — barra segmentada clara, para não acrescentar
  matiz nem competir com o magenta do Fluxo ao lado. Validado com o ux-designer;
  regras de Vida baixa e a opção "Vida colorida" estão na Seção 7.8.

### 4.7 Segurança para daltonismo

**Teste obrigatório:** todo print de aprovação passa por simulação de
deuteranopia, protanopia e tritanopia e por conversão para tons de cinza. O que
deixar de ser legível em qualquer um desses filtros volta para revisão.

| Par ou elemento em risco | Risco | Apoio obrigatório |
|---|---|---|
| Telégrafo × fundo | qualquer tipo, se depender de matiz | **valor** (escada 4.2) + borda de tinta + preenchimento crescente + **deixa sonora** (a definir pelo audio-director) |
| Magenta (preço) × dourado (ganho) | **tritanopia:** os dois tendem a rosa claro | ícone partido × ícone que irradia (3.6); posição fixa na carta |
| Aura dourada da elite | qualquer tipo, em cena carregada | coroa de espinhos (forma) + pulsação |
| Fluxo × Vida no HUD | baixo, mas soma de riscos | forma (gota × segmentos) e posição fixa |
| Raridade da carta | qualquer tipo, se for só cor | ornamento da moldura |
| Doutrinas | — | resolvido por definição: forma primeiro (P1) |
| Criatura do pacto × Anomalias inimigas | qualquer tipo | fio de vínculo + amarras (forma, não cor) |
| Veios × névoa petróleo (deuteranopia) | os veios podem se fundir à névoa | aceitável: é ambiente; o que importa é o telégrafo continuar no topo da escada |

## 5. Character Design Direction

*Aprovada pelo CD em 2026-11-05. Decisões: cabelo prateado fixo; animação por
rig 2D + quadros-chave desenhados; mangas de Oreth mudam de cor só no retrato,
em tons neutros.*

### 5.1 Contrato de leitura personagem × ambiente *(P3, regra central)*

Personagem e ambiente se separam por **densidade de textura inversa**. Onde o
ambiente é liso, o personagem lê pelo contorno e pelo valor. Onde o ambiente é
carregado, o personagem lê por ser chapado. O olho separa "superfície agitada"
de "forma lisa e fechada" antes de separar matizes. Por isso essa regra
funciona em tons de cinza e com daltonismo, e não disputa espaço com o magenta e
o dourado.

| Superfície (Seção 6.3) | Densidade de textura | Valor (L*) | O personagem lê por |
|---|---|---|---|
| Chão de combate | **baixa**: até 2 tons, sem hachura no miolo | 22–38 | contorno de tinta de 3 px + interior com tom médio pelo menos ~10 L* acima do chão |
| Paredes e bordas | **alta**: hachura de 1,5 px, rachaduras, lascas | 10–25 | interior chapado (baixa frequência) contra textura alta, e valor acima |
| Névoa e topo da tela | baixa, em faixas | 35–55 | contorno de tinta (escuro sobre claro) |

**Regras do personagem que decorrem disso:**
- O interior é **chapado**: cel de 2–3 tons e **no máximo uma zona de hachura**
  (o lado da sombra), com espaçamento pelo menos 2× o da hachura de parede.
  Personagem com hachura por todo o corpo vira parede.
- **Teste de fundo** (soma-se ao teste da miniatura de 3.1): a silhueta a 90 px,
  em cinza, tem que ler sobre o trecho mais texturizado da parede e sobre o
  chão. Se sumir em um dos dois, o problema é do personagem.

### 5.2 O Iniciado: arquétipo visual

**Arquétipo:** o aprendiz que desce sozinho. É esguio, vertical e tem o peso um
pouco à frente. Duas coisas são constantes e formam a identidade do jogador:
1. **Cabelo prateado** (fixo — decisão do CD), a massa mais clara do personagem
   (osso, L* ≤ 82 no mundo). Fica no terço superior e é o "farol" do jogador em
   cena cheia.
2. **Casaco escuro longo**, até a panturrilha, com interior em L* 40–50 (acima
   do chão) e acentos **em osso**. A barra do casaco dá ao jogador um contorno
   inferior em sino que nenhum inimigo tem: Ecos não têm pés, Anomalias são
   baixas.

*Por quê:* o padrão de valor do jogador é **escuro com topo claro**. É o inverso
do Eco, que é claro com a base desfeita. O jogador se distingue da família mais
parecida com ele (humana) já pela distribuição de luz, antes da forma.

**Acentos do casaco:** osso. Nunca dourado, nunca magenta (4.1). Se a arte do
Nano Banana tiver acentos dourados ou coloridos, eles mudam de cor na
regeneração. O acento carrega a **forma da Doutrina jurada** num motivo de
barra e gola: diagonais para Lâmina, faixa larga para Guardião, crescentes para
Véu, e assim por diante (3.3). Isso aparece no retrato. No jogo, o que sobra é
só um ritmo na barra do casaco.

**Proporção:** ~6 cabeças no sprite de jogo e ~7 no retrato. A cabeça um pouco
maior no sprite segura o cabelo como massa legível a 90 px (~15 px de cabeça).
No retrato, a anatomia mais realista sustenta a referência a Jujutsu Kaisen.

### 5.3 Customização sem quebrar a silhueta

Princípio: **a customização vive no retrato; a silhueta de jogo é fixa.** A
90 px, rosto e tom de pele quase não aparecem (5.9), então dá para oferecer
variedade real sem custo de leitura.

| Elemento | Customizável? | Limite |
|---|---|---|
| Nome | sim (decisão do CD, conceito §2) | — |
| Rosto (formato, olhos, nariz, boca) | sim, presets de rosto (as variações de retrato existentes viram a base) | só no retrato |
| Tom de pele | sim, 6–8 tons | no jogo vira um plano pequeno no rosto e nas mãos; não muda o contorno |
| Penteado | sim, 3–4 cortes | todos dentro de um **envelope**: massa clara no topo da cabeça, sem cobrir o contorno do rosto, volume máximo fixo |
| Cor do cabelo | **não — prateado fixo** | é a âncora de identidade |
| Compleição | opcional, 2 tipos | largura de ombro ±5%, mesma altura, mesma barra de casaco |
| Casaco (comprimento, cor, recorte) | **não** | é a identidade do jogador |

*Por quê:* o casaco e a massa clara do cabelo são o "traço distintivo" do
jogador. Mexer neles é o mesmo que mexer na coroa da elite. O resto pode variar
à vontade.

### 5.4 A arma da Doutrina troca a leitura da silhueta

A arma é o traço distintivo do jogador (3.1). O casaco e o cabelo dizem "sou
eu"; a arma e a postura de idle dizem "como eu luto agora".

| Doutrina | Arma | O que muda na silhueta | Postura de idle |
|---|---|---|---|
| Lâmina | espada reta longa (~0,6 da altura) | ganha uma **diagonal** que sai do corpo | inclinado para a frente, lâmina baixa em diagonal |
| Guardião | escudo-bastião | fica **mais largo que alto** (é a única) | plantado, base larga, escudo à frente |
| Véu | adagas em crescente | **encolhe**: silhueta compacta e agachada | de perfil, assimétrico, adagas junto ao corpo |
| Ressonância | foco ou cajado com orbe | fica **mais alto**: o orbe passa da cabeça | braço estendido, equilíbrio tenso |
| Transmutação | cálice | **ampliado de propósito** (~20% da altura), levado à frente como lanterna | meio giro, cálice inclinado como quem vai verter |
| Pactos | besta | **T horizontal** na altura do peito | recuado, mira estável, com a criatura à frente |

O cálice é a arma mais fraca em silhueta. Um cálice realista some a 90 px, e por
isso o exagero de escala é obrigatório.

### 5.5 Distinguir num relance

Cada família tem um canal dominante e um de reforço. Nenhuma depende só de cor.

| Família | Forma | Padrão de valor | Acento | Contato com o chão | Movimento |
|---|---|---|---|---|---|
| **Jogador** | vertical, casaco em sino, arma destacada | escuro com topo claro | nenhum; osso no cabelo e nos acentos | mancha de contato em tinta | nítido, responsivo |
| **Criatura do pacto** | baixa, quatro patas, cristais **com amarras** | tinta e osso | **brasa magenta selada** (só interna) | mancha de contato | segue o jogador com atraso; nunca dá espasmo |
| **Ecos** | humano subtraído: capuz, sem pés | claro (névoa) com a base em fiapos | nenhum | **sem sombra de contato** | arrastado, humano |
| **Anomalias** | forma imitada com excesso, ponto emissor | médio-escuro | magenta nos cristais e no emissor (L* ≤ 70) | mancha de contato | espasmos, ritmo errado |
| **Elites** | a base + **coroa de espinhos** + armadura | a base | aura dourada pulsante | a base | a base, ~10% mais lento e pesado |
| **Chefes** | escala (5.6), domínio de um eixo | eles são a luz da arena | magenta (Anomalia Maior) ou dourado (Guardião) | grande e definida | lento, com antecipações longas |
| **NPCs do Campus** | humanos inteiros, de pé, forma da Doutrina no traje | rim âmbar do Campus | nenhum na figura; marcador dourado de interação | mancha de contato | parados, idle sutil |

- **Ecos não projetam sombra de contato.** É a gramática da subtração (3.2)
  aplicada à luz, e separa Eco de humano mesmo quando os dois estão parados.
- **Mestres nunca aparecem na Beira** (cânone, conceito §7). Uma figura humana
  inteira na Beira nunca é um NPC.
- **Mancha de contato:** mancha de tinta de borda irregular e sem contorno. Nunca
  um anel ou uma elipse limpa, porque círculo no chão é vocabulário exclusivo do
  telégrafo (3.4).

**Feedback de dano por família** (os dois abaixo da faixa reservada L* ≥ 88):
- **Jogador atingido:** 2 quadros de **inversão** — silhueta em tinta chapada e
  contorno em osso — junto com o hitstop. Gesto de quadrinho, inconfundível.
- **Inimigo atingido:** 1 quadro de flash em osso (L* ~80).

### 5.6 Escala relativa *(proposta de arte; hitbox fica com o game-designer)*

| Figura | Altura em relação ao jogador | Nota |
|---|---|---|
| Iniciado | 1,0 (~90 px) | referência |
| Eco Perdido / Eco do Veio | 1,0–1,1 | o Eco do Veio é inclinado para a frente |
| Anomalia Menor / do Veio | 0,6 de altura, 1,2 de largura | baixa e larga |
| Fenda Errante | 0,7, em cunha | horizontal |
| Estilhaço Vivo | 1,4 | bloco facetado |
| Criatura do pacto | 0,6–0,7 | menor que o jogador, para não disputar protagonismo |
| Elite | base × 1,15 + coroa | |
| Anomalia Maior | ~3,5 de altura, ~6 de largura | domina o horizontal |
| Guardião do Rito | ~3 | domina o vertical; **rosto sempre coberto** (título e função, sem biografia) |

**Traço dos chefes:** 3,5 px. Os 4 px continuam exclusivos do telégrafo, para
que nada no jogo tenha traço mais grosso que o aviso de ataque.

### 5.7 Mestres: direção de design e retratos

Cada Mestre carrega a **forma da sua Doutrina** (3.3) na silhueta do traje e do
corpo. Em tons de cinza, os seis bustos têm que se distinguir. Os traços
canônicos dos romances são obrigatórios; para Halvar e Maren não há descrição
canônica de aparência, então o que vai abaixo para eles é **[PROPOSTA]**.

| Mestre | Base | Forma no corpo e no traje | Traço de assinatura |
|---|---|---|---|
| **Halvar** (Lâmina) | [PROPOSTA] | alto e estreito; gola e lapelas cortadas em diagonal; o corpo é uma linha | olhar fixo num ponto; o único que encara direto o espectador |
| **Berrin** (Guardião) | [CÂNONE] silencioso, ombros largos | trapézio de base larga; ombros que passam da moldura do busto | **boca quase sempre fechada**: a expressão vem das sobrancelhas e do olhar |
| **Endra** (Véu) | [CÂNONE] magra, idade indefinida, olhos cinzentos | crescente; cabelo ou capuz assimétrico cobrindo metade do rosto em mancha de preto | **olhos cinzentos** em osso-acinzentado, sem acento; idade indefinida por pele lisa com olhar cansado, nunca rugas que fixem uma idade |
| **Maren** (Ressonância) | [PROPOSTA] | círculos: gola redonda, ornamento em anéis concêntricos, postura equilibrada no limite | um anel ou pingente que quase toca a borda da moldura (ecoa o ícone) |
| **Oreth** (Transmutação) | [CÂNONE] mangas bordadas que mudam de cor sob a luz | espiral; mangas largas com bordado em voluta | as mangas: **só no retrato**, o bordado alterna entre âmbar, petróleo, névoa e osso — **nunca magenta nem dourado** — e o desenho em voluta também muda de forma (decisão do CD) |
| **Sorcha** (Pactos) | [CÂNONE] cicatriz de um vínculo forçado e rompido | o par ligado, **mas incompleto**: manto ou estola de duas partes com o cordão entre elas cortado | a **cicatriz** como uma linha de fio rompido, em osso pálido na pele, na gramática do fio de vínculo (3.3) |

**Oreth e a Lore Freeze:** ela é Mestra-Conselheira, e a regra 3 da Lore Freeze
(conceito §9) proíbe nomear Mestres-Conselheiros em texto de jogo. Do lado da
arte, o retrato de Oreth **não carrega insígnia de Conselho**: ela se apresenta
como Mestra da Transmutação. O tratamento no texto fica com o narrative-director
e o CD.

**Direção dos retratos de diálogo:**
- **Enquadramento:** busto, do alto da cabeça até o meio do peito, em vista 3/4
  voltada para o centro da tela. A linha dos olhos fica a ~1/3 do topo e é igual
  em todos os Mestres, para a troca de quem fala não "pular".
- **Estilo (Jujutsu Kaisen + quadrinho):** contorno externo grosso e traço
  interno fino; manchas de preto no cabelo e na sombra do rosto; hachura dura no
  lado escuro; cel de 2–3 tons; olhos de desenho anguloso; luz lateral âmbar do
  Campus (2.1).
- **Expressões por Mestre:** 4 base (neutro, aprovação, severidade, inquietação)
  + 1 de assinatura (ex.: Berrin com o olhar desviado, Endra com meio sorriso
  encoberto).
- **Quanto exagero:** **contido no retrato.** O rosto fica composto quase
  sempre, e a emoção mora nos olhos e nas sobrancelhas. Só a expressão de
  assinatura pode ser um "estalo" forte. Os Mestres são autoridades de uma
  instituição falível (P5); rosto de desenho animado tiraria o peso da tela de
  bênção.
- **Retrato do Iniciado:** os presets da 5.3 × 3 expressões (neutro,
  determinação, cansaço).

### 5.8 Pose e animação

**Exagero: pose alta, deformação baixa.** As poses de jogo vão ao extremo:
linha de ação forte, antecipação com espaço negativo (3.1), golpe esticado. Os
volumes não viram borracha, e a espessura do traço não varia com o movimento. A
90 px uma pose sutil desaparece; e o traço uniforme é a identidade do estilo.

**Assimetria de antecipação (regra de P3):**
- **Jogador:** antecipação **curta** (1–2 quadros). O botão responde na hora.
- **Inimigo:** antecipação **longa e legível** (3–5 quadros + pausa na pose de
  preparo), sincronizada com o crescimento do telégrafo.

**Método de produção (decisão do CD): rig 2D + quadros-chave desenhados.** O
corpo é dividido em partes pintadas montadas no esqueleto 2D do Godot, **só com
rotação e translação, sem escala** (o traço não deforma). Rastros de golpe
(*smears*), impactos, especiais e a morte são desenhados à mão por cima, como
quadros-chave. Isso corta a maior parte do volume quadro a quadro e funciona com
arte gerada por IA, que não mantém consistência entre quadros. **Risco a
vigiar:** cara de "boneco recortado" se as poses-chave forem tímidas — por isso
a regra de pose alta acima é obrigatória. A viabilidade técnica fica registrada
na Seção 8.

**Animações mínimas do Iniciado** (reprodução-base de 12 qps, com pausas nas
poses-chave; a coluna "quadros" vale para os quadros-chave desenhados):

| Animação | Quadros-chave | Por arma ou compartilhada | Nota de arte |
|---|---|---|---|
| Idle | 6 (loop) | **por arma** | respiração e balanço da barra do casaco; postura da 5.4 |
| Corrida | 8 (loop) | compartilhada, com a arma em pose de carregar | o casaco abre atrás e reforça a direção |
| Ataque em combo | 3 golpes × 4–6 = 14–18 | **por arma** | cada golpe com 1 quadro de *smear* em tinta; **todo quadro de recuperação precisa parecer aceitável se for cortado** (cancelamento, §55.2 do baseline) |
| Especial | 8–12 | **por arma** | o mais teatral: 1 pausa de pose estilo painel de quadrinho |
| Esquiva | 5–6 | compartilhada | esticada + 2–3 imagens residuais em **osso tracejado** (gramática das ações do jogador, 4.3), nunca em fiapos de tinta (que são do Eco) |
| Selo | 6–8 | compartilhada | um gesto de mão que "desenha" o selo; a área é osso tracejado |
| Dano | 2–3 | compartilhada | junto com a inversão da 5.5 |
| Morte | 10–14 | compartilhada | segue a 2.8; o Iniciado é a última luz a sumir |

**Direções:** câmera 3/4 com 8 direções; 5 desenhadas (frente, frente-3/4,
lado, costas-3/4, costas) e 3 espelhadas. O espelho troca a arma de mão; aceito,
desde que os acentos do casaco sejam simétricos.

**Outras famílias** (4 animações por inimigo: movimento, antecipação, ataque,
morte):
- **Ecos** morrem se desfazendo em fiapos: a subtração se completa.
- **Anomalias** morrem rachando: os cristais estilhaçam e o magenta se dissipa
  em partículas.
- **Criatura do pacto:** idle, corrida, Chamado do Pacto (avançar, segurar,
  atrair) e dano. O que ela faz ao "cair" depende do GDD de combate.

### 5.9 Detalhe na distância de câmera (~90 px a 1080p)

Princípio: **desenha-se para 90 px, não para o arquivo-fonte.** O que não
sobrevive a 90 px não entra no sprite; entra no retrato.

| Sobrevive (obrigatório) | Cortado (vai para o retrato ou some) |
|---|---|
| contorno fechado de 3 px | traços do rosto (no máximo uma faixa escura de olhos, ou nada) |
| massa clara do cabelo | dedos (a mão vira uma forma de luva) |
| silhueta da arma da Doutrina | bordados, botões, fivelas, correias finas |
| barra e abertura do casaco | hachura interna além de uma zona |
| uma divisão de valor (lado claro e lado escuro) | variação de tom de pele além de um plano |
| postura da Doutrina | o motivo dos acentos do casaco (fica só um ritmo) |

**Limites:** nenhum detalhe interno **menor que ~5 px** no tamanho final, e
nenhuma forma tonal interna menor que ~8 px. Abaixo disso o detalhe vira ruído e
compete com a textura da parede, violando a 5.1.

## 6. Environment Design Language

*Aprovada pelo CD em 2026-11-05.*

### 6.1 Estilo arquitetônico

**Campus (Universidade da Ressonância).** Instituição de pedra e madeira que
funciona como cidade: arcadas, claustros, salões de pé-direito alto, escadas
largas e lamparinas. Vocabulário de 3.4: arcos, retângulos e verticais estáveis.
A ordem humana é visível. **A falibilidade aparece como uso, não como evento:**
remendos de pedra em outro tom, andaimes esquecidos, portas trancadas, um
corredor com as lamparinas apagadas (2.1), acréscimos que não combinam com o
prédio original. Nada disso se explica. P4 pede casa; P5 pede que a casa não
seja inocente.

Cada Doutrina tem um espaço com a sua forma (3.3):

| Local | Status | Direção |
|---|---|---|
| **Pátio da Lâmina** | canônico | aberto e longo, com uma linha de visão reta de ponta a ponta; pilares projetam sombras diagonais; suportes de lâminas de treino; piso gasto em trilhas, **sem marcações geométricas claras** (círculo e linha pintados são do telégrafo, mesmo no Campus) |
| **Salão das Lamparinas Baixas** (Véu) | canônico | teto baixo, lamparinas penduradas na altura do joelho, poças de luz baixas; a maior parte do salão em mancha de preto; arcos e cortinas em crescente |
| Espaço do Guardião | [PROPOSTA] | salão de paredes grossas e contrafortes em trapézio; pesado e baixo |
| Espaço da Ressonância | [PROPOSTA] | câmara redonda ou abobadada, com anéis concêntricos no teto (nunca no chão) |
| Espaço da Transmutação | [PROPOSTA] | oficina com escada em espiral, recipientes, bancadas manchadas |
| Espaço dos Pactos | [PROPOSTA] | pares de pilares ligados por pontes ou cordas; **sem jaulas** (cativeiro choca com a cicatriz de Sorcha e com a ética do vínculo) |

Vale tanto para o Campus andável quanto para o menu com fundo pintado (pendência
3 do conceito).

**A Beira (ruínas da Era da Ruína Imediata).** Regra-mãe: **a arquitetura da
Beira mostra material e erosão, nunca função nem época.** Escadas que terminam
no ar, meios-arcos, colunas cortadas, blocos sem ornamento, nenhuma ordem
arquitetônica consistente o bastante para "datar" ou atribuir a alguém. **Nunca
cita a arquitetura do Campus**: isso criaria uma ligação histórica que o cânone
não tem.

As duas regiões herdam as duas famílias de inimigo (3.2):
- **Limiar: a Beira subtrai.** Ruína erodida, horizontais arredondadas, cantos
  comidos, massas que somem na névoa a meia distância. A gramática do Eco: o que
  falta é o erro.
- **Veio: a Beira excede.** Rocha rachada em diagonais, **cristais facetados
  brotando das paredes e das ruínas**, veios de Fluxo ramificados em magenta
  (abaixo do teto de 4.5). A gramática da Anomalia: o que sobra é o erro. O
  jogador aprende que "cristal = Fluxo em excesso" pelo cenário e pelo inimigo
  ao mesmo tempo.

**Santuário Esquecido.** Arco baixo e simétrico em forma de abraço, feito de
**pedras reaproveitadas e recolocadas** — o cuidado de alguém sobre a ruína. Uma
fonte de luz: o braseiro (2.4).

**Altar de Provação.** O anel é **arquitetônico**: um círculo de pedras
verticais em espinho **ao redor** da arena, fora do chão de combate, nunca um
círculo pintado no chão. Luz zenital dourada (2.5).

**Arenas de chefe.**
- **Anomalia Maior:** a câmara mais escura e mais limpa do Limiar, bordas
  recuadas.
- **Guardião do Rito:** simétrica, verticais em pé, veios apagados (2.7).

### 6.2 Filosofia de textura: pintado à mão com traço, sem PBR

Tudo é **ilustração pintada com traço de tinta**: cel de 2–3 tons por material,
hachura no lugar de textura de ruído, manchas de preto no lugar de oclusão
ambiente. Sem PBR, sem fotografia, sem gradiente suave, sem brilho especular
realista. **Normal maps 2D ficam fora como regra**; exceções são avaliadas pelo
technical-artist.

**Por quê:**
1. **P3 depende de controle exato de valor.** A escada de 4.2 só funciona se o
   L* de cada superfície for o L* pintado. Iluminação física mexe nos valores de
   forma imprevisível.
2. **A mesma tinta em tudo.** Personagem e cenário com o mesmo peso de linha são
   um mundo só (teste da Seção 1).
3. **Referências.** Hollow Knight e Jujutsu Kaisen são tinta e mancha; Valheim
   entra só como ideia de cor regional (4.4).
4. **Produção.** Os assets de IA precisam de uma **passada de unificação**
   (repintar o traço na espessura da 3.5, reduzir a cel para 2–3 tons). PBR
   exigiria mapas que essa fonte não fornece com coerência.

| Material | Linguagem |
|---|---|
| Pedra | hachura cruzada só na sombra, bordas lascadas em traço quebrado |
| Madeira (Campus) | veio em traço longo, base âmbar |
| Metal (Guardião, Campus) | reflexo como **forma dura** recortada, 1 por superfície, nunca degradê |
| Cristal (Veio) | facetas planas em 2 tons + 1 aresta clara |
| Tecido | dobras em mancha de preto, sem hachura |
| Fluxo (veios) | ramificado, sem contorno grosso, pulsação lenta (4.5) |

### 6.3 Câmara em camadas (2D 3/4 no Godot)

De trás para a frente. A implementação (CanvasLayers, y-sort, shaders) fica com
o technical-artist (Seção 8); aqui está o que cada camada pode conter.

| # | Camada | Conteúdo | Traço | L* | Densidade de textura | Grading regional |
|---|---|---|---|---|---|---|
| 1 | **Fundo / teto de névoa** | a "voz" da região em 2–3 faixas chapadas (4.4) | nenhum | 35–55 | baixa | 100% |
| 2 | **Névoa distante** | ruína a meia distância engolida pela névoa | 1,5 px, falhado | 35–50 | baixa | 100% |
| 3 | **Parede e borda traseira** | arquitetura, veios, cristais; curvas côncavas que abraçam a arena | 1,5 px (apoio) | 10–25 | **alta** | 100% |
| 4 | **Chão de combate** | plano achatado; textura só nas bordas; rachaduras escuras e ramificadas | — | 22–38 | **baixa** (até 2 tons; variação ≤ ~6 L* no miolo) | 100% |
| 5 | **Objetos** (y-sort junto com a 6) | objetos de borda, obstáculos | 1,5 px decorativo; **3 px se bloqueia movimento** | 10–35 | média | 100% |
| 6 | **Personagens** (y-sort) | jogador, criatura, inimigos, NPCs; ações do jogador em osso tracejado | 3 px (chefes 3,5) | 40–82 | baixa (5.1) | ≤ 15% |
| 7 | **Telégrafo** | áreas de ataque inimigo | 4 px | núcleo ≥ 88 | — | **0%** |
| 8 | **Primeiro plano** | mancha chapada de tinta, ≤ 15% da tela, nunca sobre a área jogável (3.4) + névoa de borda | nenhum | 0–10 | nenhuma | 100% |
| 9 | **UI** | HUD, cartas | traço chanfrado (3.6) | — | — | **0%** |

**Regras de cruzamento entre camadas:**
- **Telégrafo sobre corpo:** onde o telégrafo passa por cima de um personagem, o
  *preenchimento* cai para ~50% sobre o corpo e o *contorno* fica a 100%.
- **Oclusão:** objeto que cubra personagem ou telégrafo vai a ~40% de opacidade
  na área coberta. Telégrafo nunca fica escondido. O mais simples é evitar
  objetos altos fora da faixa de borda.
- **Halo de clareza:** em volta de toda porta e todo interativo, num raio de ~1
  altura de personagem, a textura cai para a densidade do chão. A escolha
  (dourado) não disputa com hachura.

### 6.4 Densidade de objetos por tipo de área

| Tipo de área | Miolo do chão | Faixa de borda | Foco | Observação |
|---|---|---|---|---|
| **Câmara de combate** | 0 decorativos; 0–2 obstáculos que bloqueiam | **densa**: ~70–80% de todos os objetos | no máximo 1 fragmento narrativo (6.5), sempre na borda | a densidade de borda é o que faz o personagem ler como "liso" (5.1) |
| **Santuário** | moderada, **agrupada** em volta do braseiro | média | o braseiro + 2–4 sinais de cuidado | caminho até as portas livre; a névoa para na soleira |
| **Altar de Provação** | 0 | média: o anel de verticais | as elites | o dourado fica nas elites e na luz, não nos objetos |
| **Chefe** | 0 | **baixa**: ~metade da câmara comum | o chefe | o chefe é a coisa mais carregada da tela; a arena cede |
| **Campus** | **alta** (livros, bancos, lamparinas, ferramentas) | alta | 1 por Mestre ou estação + portas | sem telégrafo a densidade pode subir, mas o halo de clareza em volta de interativos e NPCs é obrigatório |

A densidade cai à medida que a leitura de combate pesa mais: o Campus é o mais
denso porque é o único sem perigo; o chefe é o mais vazio porque é o maior
perigo. A curva de densidade acompanha a curva de energia da Seção 2.

### 6.5 Narrativa ambiental sem texto (dentro da Lore Freeze)

**Princípio: o lugar mostra marcas de uso, nunca a história de alguém.** Um
objeto sugere; um conjunto nunca resolve.

**Pode:**
- marcas de **uso e de cuidado**: desgaste, remendo, poeira varrida para os
  cantos, lenha empilhada;
- **ausências**: uma escada sem destino, um nicho vazio, uma porta sem saída;
- **repetição com variação** entre câmaras: o mesmo tipo de fragmento volta
  diferente, e o jogador monta um padrão que nunca fecha.

**Não pode:**
- **Texto legível** de qualquer tipo. Inscrições só como marcas gastas, **nunca
  um alfabeto consistente** (seria inventar escrita e cultura).
- **Rostos** em estátuas, relevos ou pinturas, na Beira e no Campus. Um rosto
  vira "quem era?" e abre caminho para identificar Mestres-Conselheiros ou
  fundadores. Na Beira, estátuas aparecem sem cabeça ou com o rosto erodido.
- **Heráldica, brasões ou emblemas de lugar** (evita insinuar Cidades-Bastião).
- **Depressão, cratera ou "centro"** em fundos e horizontes, inclusive no fundo
  revelado na vitória (2.9): ele mostra mais ruína e mais névoa, nunca uma
  geografia que aponte para a Cratera.
- **Imagens do Colapso:** nada de destruição radial apontando para um ponto de
  origem, nada de antes e depois, nada de cena congelada de catástrofe.
- **As 6 formas de Doutrina nas ruínas da Beira.** Elas só aparecem no que o
  Iniciado e o Campus trazem; uma Doutrina numa ruína da Era da Ruína Imediata
  seria história inventada.
- **Pertences de expedições ou Iniciados mortos** sem decisão do
  narrative-director.

**No Santuário:** o cuidado está no **lugar**, não em posses. Pedras recolocadas
com argamassa mais clara, um pano dobrado sobre uma pedra, chão varrido com a
poeira nas laterais, uma fenda tapada. Cada instância usa 1–2 sinais diferentes.
Nada pessoal: sem cama, sem retrato, sem objeto que conte quem é. Quem cuida
nunca aparece (P5).

**No Campus:** a falibilidade aparece pelo físico (6.1), sem galeria de
retratos institucionais.

O narrative-director e o level-designer revisam os fragmentos antes da produção.
O art bible define o vocabulário; o conteúdo de cada fragmento não é decisão de
arte.

## 7. UI/HUD Visual Direction

*Aprovada pelo CD em 2026-11-05. Autoria: art-director (arte) + ux-designer
(legibilidade). Decisões: vinheta de Vida baixa na versão UX; painéis com texto
≥ 92%; na tela de bênção navegar já e confirmar depois; Vida em osso com opção
colorida; fontes Alegreya SC + Alegreya Sans; Mestre com insígnia + retrato
lateral.*

A UI de Khaeros é **tinta sobre papel de osso**: painéis de tinta com moldura
chanfrada a 45° (3.6), cartas de osso, e dourado e magenta só onde significam
algo (4.3). Ela obedece à regra central: a UI é sempre **escolha** ou **estado
do jogador**, e por isso pode brilhar. O que não é nenhum dos dois não entra.

### 7.1 Diegético, espacial e de tela *(P3, P4)*

| Camada | O que entra | Por quê |
|---|---|---|
| **Tela** | Vida, Fluxo, cargas de esquiva, Fragmentos, barra de chefe, tela de bênção, pausa, menus | P3: o estado do jogador fica sempre no mesmo lugar e na mesma cor (sem grading, 4.6). |
| **Espacial** (no mundo, sem pertencer a ele) | ícones de porta no arco, números de dano, prompts de interação, vida de inimigo | a informação pertence a um ponto do mapa, onde o olho já está |
| **Diegético** | telégrafos (4.5), portas que acendem (2.3), aura das elites; no Campus: bancada da Oficina de Reforja, armeiro das 6 armas, livro de matrícula do Iniciado | P4: no Campus, escolher é um gesto num lugar; o jogador anda até a bancada e só então o painel de tela abre |

**Regra:** o diegético entra pelo mundo e vira tela no momento da decisão (ex.:
interagir com o livro de matrícula abre a ficha de osso para digitar o nome).
Nunca o contrário.

### 7.2 Tipografia *(P1, P4)*

**Personalidade:** acadêmica e escrita à mão, sem ser medieval de feira — a
letra de uma universidade antiga que estuda algo perigoso. O peso de tinta do
mundo aparece no **peso** da letra, nunca em letras "sujas".

**Par escolhido:** **Alegreya SC** (títulos, versaletes) + **Alegreya Sans**
(corpo e números). Google Fonts, SIL OFL, latim estendido.
- **Fonte de acessibilidade:** Atkinson Hyperlegible Next como opção de troca do
  corpo.
- **Logotipo e títulos de tela ≥ 48 px:** letreiramento desenhado à mão com
  textura de tinta (não é fonte).
- **Cobertura obrigatória:** Latin-1 + Latin Extended-A. Teste de glifos: "Ação,
  Coração, Órbita, Ênfase, Último, à vez, pôr, Mãe, Iniciação" e o nome digitado
  na criação do Iniciado.
- **Algarismos** de HUD e de dano alinhados e tabulares (lnum/tnum).
- **Renderização:** fontes de UI em MSDF (Seção 8).

**Hierarquia a 1080p (escala de UI 100%):**

| Nível | Uso | Fonte | Tamanho | Peso |
|---|---|---|---|---|
| Display | logotipo, "Morte", título de resumo | letreiramento | 72–96 | — |
| H1 | título de tela (Oficina de Reforja, Pausa) | Alegreya SC | 48–56 | Bold |
| H2 | nome da Tradição na carta, nome do chefe | Alegreya SC | 32–36 | Bold |
| H3 | nome do Mestre, rótulos de seção | Alegreya SC | 24–26 | Regular/Bold |
| Corpo | descrição da carta, menus | Alegreya Sans | **24** | Medium sobre osso, Regular sobre tinta |
| Secundário | raridade, dicas de botão, metadados | Alegreya Sans | 20 | Regular |
| Números de HUD | Vida, Fluxo, Fragmentos | Alegreya Sans | 24–28 | Bold, contorno de tinta 2 px |
| Números de efeito na carta | "+25%" | Alegreya Sans | 28 | Bold |

- **Piso absoluto: 18 px**, só para o não essencial (versão, créditos). Fonte de
  título nunca abaixo de 24 px. Haste mínima de 2 px no tamanho de corpo; nenhum
  peso abaixo de 400.
- **Os layouts aguentam +40% de texto** (o português já é ~25% mais longo). Na
  carta: até 2 linhas de efeito, ~90 caracteres.
- **Sem traço irregular nos glifos.** A tremida de tinta vive na moldura. Texto
  no mundo leva contorno de tinta de 2 px; texto em painel não. Sombra, quando
  houver, é deslocamento duro de 2 px, nunca desfoque.

### 7.3 Contraste (medido sobre a paleta 4.1)

| Combinação | Contraste aprox. | Regra |
|---|---|---|
| Tinta sobre Osso / Osso sobre Tinta | ~14:1 | base de todo texto |
| Dourado sobre Tinta | ~9,7:1 | liberado |
| Magenta `#E0259C` sobre Tinta | ~4,5:1 | só número ≥ 24 px Bold (texto grande) |
| Magenta sobre Osso | ~3,2:1 | **nunca texto** |
| **Dourado sobre Osso** | **~1,5:1** | **nunca texto, traço fino ou anel de foco** |

- Texto: **≥ 4,5:1 sempre**; na descrição da carta, mirar ≥ 7:1.
- Elementos que não são texto (ícones, segmentos, chevrons, foco): ≥ 3:1 contra o
  vizinho.
- **Painéis de tinta com texto: ≥ 92% de opacidade** (100% no alto contraste).
  Painéis sem texto podem ficar a 85–90%.
- Se o número de preço medir abaixo do mínimo, a saída é uma variante clara só
  para texto (~`#F25BB8`, ~6,4:1) — entra na paleta 4.1 só com aprovação.
- **Números e texto desenhados no mundo** usam o osso de mundo `#CFC6B4`
  (L* ≈ 80), nunca o osso de UI (L* ≈ 89, que fica na faixa do telégrafo).
- Toda tela passa pelo teste da 4.7 (deuteranopia, protanopia, tritanopia,
  cinza).

### 7.4 Iconografia *(P1, P3)*

- **Traço:** o mesmo pincel de tinta do mundo, contorno externo **fechado** e
  grosso (o ícone é forma-herói, 3.5). Máximo de **tinta + osso + 1 acento**.
- **Tamanhos:** mestre a 64 px e versões **redesenhadas** (não só reduzidas) a
  48 e 32:

| Tamanho | Uso | Traço externo | Detalhe permitido |
|---|---|---|---|
| 96 | glifo da Doutrina na carta | ~4 px | forma primária + hachura da Doutrina |
| 64 | carta, Oficina, resumo de morte | ~4 px | forma primária + hachura da Doutrina (3.3) |
| 48 | insígnia do Mestre, escolha de arma, gota de Fluxo | ~3 px | forma primária + 1 detalhe |
| 32 | HUD, ganho e preço na carta, prompts | ~2–2,5 px | só a forma primária |

- Ícone de porta desenhado a **40 px** na tela; o teste de 32 px é o pior caso.
- **Teste da miniatura (3.1):** o ícone de 32 px preenchido de preto continua
  identificável.
- **Um vocabulário só:** o ícone da porta é o mesmo da recompensa e do HUD
  (estilhaço = Fragmentos, topo da Doutrina = bênção, coroa de espinhos = Altar,
  arco baixo = Santuário, forma própria a definir = cura).
- **Proibido em UI de mundo:** círculo fechado, cone ou linha reta longa no chão
  (vocabulário do telégrafo, 3.4). Mira e indicadores de alcance são **osso
  tracejado**, em ponta ou chevron. Mira de 24 px com contorno de tinta.

### 7.5 Anatomia da carta de bênção *(P1, P2)*

Carta vertical de ~320 × 500 px a 1080p; três cartas com 48 px de intervalo
ocupam ~1060 px. De cima para baixo:

1. **Coroa da Doutrina (0–14%).** A silhueta do topo da moldura tem a forma da
   Doutrina (3.3). Insígnia do Mestre a 48 px, em tinta. **O topo é exclusivo da
   Doutrina:** nenhum ornamento de raridade toca nele.
2. **Nome da Tradição (14–24%).** H2, versaletes, tinta sobre osso. Nome
   canônico de `traditions.ts`.
3. **Vinheta (24–52%).** Glifo da Tradição a 96 px ou pequena ilustração em tinta
   com a hachura da Doutrina. Sem cor.
4. **Ganho (52–76%).** Ícone que irradia a 32 px, em dourado **com contorno de
   tinta ≥ 2 px**; texto do efeito em tinta, número em tinta Bold 28 px. Melhoria
   de algo já pego mostra "atual → novo". **O dourado fica no ícone, nunca no
   texto.**
5. **Selo do preço (76–92%).** Placa de tinta chanfrada embutida no osso; forma
   partida em magenta; número do preço em magenta Bold ≥ 24 px. **Posição fixa em
   todas as cartas** (reforço para tritanopia). Sem preço, a placa vira vazio de
   osso e a altura não muda.
6. **Rodapé de raridade (92–100%).** "Comum", "Rara" ou "Épica" escrito, ≥ 20 px
   em versalete. O **ornamento** corre só pelas laterais, cantos e rodapé:
   simples, dupla (linhas com ≥ 4 px de intervalo) ou recortada com respingo.

**Fundo:** osso chapado, grão de no máximo 5% só nas margens (nunca atrás do
texto), contorno externo de tinta de 3 px, margem interna ≥ 16 px sem ornamento.
Molduras em 9-slice com traço ≥ 2 px na menor escala.

**Teste das 18 combinações:** as 6 Doutrinas × 3 raridades, em cinza e a 50% do
tamanho; 5 avaliadores acertam Doutrina **e** raridade em ≥ 90%.

**A tela em volta:** o mundo congelado em gravura (2.6); **insígnia do Mestre em
silhueta atrás das cartas e retrato em tinta de meio-corpo à esquerda**, com o
nome em H3 e uma linha de fala em corpo itálico (com legenda, 7.9); "↻ Trocar
ofertas" abaixo das cartas, num botão chanfrado com o número de cargas. Sem
cargas, o botão fica desabilitado por **forma** (ícone riscado e "0").

**Outras telas, mesma gramática:**
- **Escolha de arma:** o mesmo componente de carta (mesma navegação, mesmo
  foco), com o topo da Doutrina.
- **Oficina de Reforja:** cartas de melhoria com topo reto neutro, para não serem
  lidas como Doutrina; grade com ordem de foco fixa; comprado × caro demais
  distinguidos por forma e texto.
- **Ficha de matrícula:** osso, campo do nome sublinhado a pincel, cursor em
  dourado *sobre o sublinhado de tinta*; máximo de 16 caracteres; teclado na tela
  para gamepad ou botão "nome aleatório", com um nome padrão preenchido.
- **Pausa:** painel de tinta ≥ 92% com as bênçãos ativas em miniatura (topo +
  ícone, 64 px) e texto completo.
- **Resumo de morte:** página de tinta com texto em osso; **causa da morte** com
  ícone do inimigo e nome do ataque (P3); bênçãos da run em miniatura; sem
  dourado de celebração.

### 7.6 Navegação e foco *(P3)*

**Um único modelo de foco:** passar o mouse move o mesmo foco que o teclado e o
gamepad; clique confirma.

| Ação | Teclado | Gamepad |
|---|---|---|
| Mover o foco | A/D, ←/→ | D-pad, analógico esquerdo |
| Seleção direta | 1 / 2 / 3 (move o foco, não confirma) | — |
| Confirmar | Enter / Espaço / E | A (Sul) |
| Trocar ofertas | R | Y (Norte) |
| Pausa | Esc | Start |

**Trava contra escolha acidental (decisão do CD: navegar já, confirmar depois):**
- ao abrir a tela de bênção, o **buffer de entrada é esvaziado**;
- o foco se move desde o 1º quadro;
- a **confirmação só vale 500 ms depois de a última carta assentar**, e só se o
  botão foi apertado depois de a tela abrir (botão já segurado não conta);
- depois de trocar ofertas, mesma trava de 300 ms.

**Regras:** foco inicial na carta do meio, sem dar a volta entre a 3ª e a 1ª;
**sem cronômetro** (P4); Esc/Start abre a pausa por cima da tela de bênção, nunca
pula a escolha.

**Foco visível (≥ 2 sinais além da cor):**
- anel dourado de ≥ 4 px **fora da carta**, com uma linha de tinta entre o anel e
  a carta (dourado sobre osso não tem contraste);
- a carta em foco cresce para **106%** e sobe ~12 px; as outras caem para ~70% de
  valor;
- com redução de movimento, o crescimento continua (é informação), em corte seco;
- teste: num print em cinza, 5 de 5 avaliadores apontam a carta em foco em < 1 s.

**Portas:** ícone dentro do arco; a ~1,5 altura de personagem aparece acima do
arco um rótulo em texto ("Bênção: Lâmina", "Altar de Provação") de ≥ 20 px em
painel de tinta, com o glifo do botão de interagir, que troca para o último
dispositivo usado. Com duas portas ao alcance, só a mais próxima fica em
destaque. *(Entrar por botão ou por encostar fica para o GDD de câmaras; a
recomendação de UX é botão.)*

### 7.7 Sensação de animação *(P4, P2, P3)*

**Princípio: posição suave, tinta em degraus.** O que se move (cartas, painéis)
usa interpolação suave sem elástico, a 60 qps. O que é tinta (traços,
rachaduras, manchas) anima "em dois", ~12 qps. Nada de UI pulsa em loop no
combate: pulsar é a linguagem das auras e dos veios, e o telégrafo cresce (4.5).

- **Entrada das cartas:** o mundo congela em ~0,25 s; o contorno de cada carta se
  traça em 2–3 quadros e o osso preenche; as cartas descem ~20 px e assentam com
  60–80 ms de defasagem. **Total ≤ 0,45 s**, três cartas legíveis até 500 ms. Sem
  efeito máquina de escrever. Troca de ofertas: ≤ 0,3 s.
- **Foco:** ver 7.6. Depois que assenta, fica parada. Os raios do ícone de ganho
  se abrem um passo.
- **Confirmação (ganho, depois preço):** os raios do ganho se abrem e um traço
  dourado voa para o HUD; em seguida, uma **rachadura magenta atravessa o selo do
  preço** em 2 quadros, com 80 ms de pausa. As cartas recusadas se desfazem em
  mancha de tinta. Total ≤ 0,6 s, com opção de pular. O preço é sempre o último
  tempo: a Beira cobra por último (P2).
- **Números de dano:**
  - osso de mundo `#CFC6B4` com contorno de tinta de 2 px; **nunca magenta,
    nunca L* ≥ 88, nunca com fundo circular ou em cone**;
  - golpe normal 28 px; **crítico 36 px em dourado** com contorno de tinta (poder
    do jogador);
  - nascem acima da cabeça do alvo, aparecem em 130% e assentam em 100% em 2
    quadros, sobem 24 px e somem em ≤ 0,6 s;
  - golpes no mesmo alvo dentro de 300 ms viram um número que soma;
  - no máximo 6 números na tela; o mais antigo some primeiro;
  - "Quebrou!" é letreiramento de onomatopeia de quadrinho (~44 px) — é onde o
    Jujutsu Kaisen aparece na UI;
  - **dano recebido pelo jogador não gera número**: vira segmento de Vida
    quebrando.
- **HUD:** o segmento de Vida perdido racha em 3 quadros e cai como lasca (um
  resto fica visível 400 ms); a cura volta como pincelada. A gota de Fluxo enche
  como líquido. O chevron de esquiva usado fica só em contorno e recarrega de
  baixo para cima. O contador de Fragmentos gira com brilho de estilhaço e
  escurece depois de 2 s.
- **Fotossensibilidade:** limitador global de **no máximo 3 flashes por
  segundo** somando todas as fontes (impact frames, flash de disparo do
  telégrafo); impact frame no máximo 1 a cada 1 s. Vale sempre.

### 7.8 HUD mínimo e posição *(P3)*

Margem segura de 48 px em 1920 × 1080. Nenhum elemento do HUD entra no retângulo
central de 60% × 70% da tela.

| Elemento | Posição | Tamanho | Visual |
|---|---|---|---|
| **Vida** | canto inferior esquerdo | barra de 18 px de altura, segmentos com 3 px de intervalo | **osso segmentado**, contorno de tinta |
| **Fluxo** | à esquerda da Vida | gota de 48 px | magenta (a única cor do grupo); **entalhe marcando o custo do Selo** |
| **Esquiva** | logo abaixo da Vida | chevrons de 32 px | osso; cheio = preenchido, vazio = só contorno |
| **Fragmentos** | canto superior direito | ícone 32 px + número 24 px | osso com brilho frio, escurece em repouso |
| **Barra de chefe** | topo, centro, ~960 px | 14 px + nome em H2 | osso segmentado em fases; moldura cristalina (Anomalia Maior) ou simétrica (Guardião) |
| **Prompt de interação** | no mundo, acima do objeto | glifo 32 px + verbo 20 px | moldura chanfrada de tinta |

- O grupo inferior esquerdo (~420 × 110 px) tem **placa própria de tinta ≥ 92%**
  e não depende da moldura da câmara.
- Sem lista de bênçãos em combate (fica na pausa).
- Vida de inimigo comum: fio de osso sob os pés, aparece após o primeiro golpe e
  some em 2 s.

**Barra de Vida (decisão do CD: osso + opção colorida):**
- cada segmento vale uma quantidade **fixa** de Vida (proposta: 10); com o Vigor
  do Juramento a barra cresce em comprimento até 25% da largura da tela, e dali
  os segmentos estreitam; segmento parcial = preenchimento parcial;
- número opcional "34/80" ao lado (padrão: ligado);
- **opção de acessibilidade "Vida colorida"**: troca o osso por um vermelho-tinta.
  É a única exceção à regra de dois acentos e só existe nesse modo;
- quem tem a bênção **O Fundo do Poço** ganha uma marca fixa em 50% na barra.

**Vida baixa (decisão do CD: versão UX).** Limiar proposto: **25% da Vida
máxima** (o número final é do game-designer). Abaixo dele:
- a **moldura da barra muda de forma** (fica partida, com borda mais grossa) e
  os segmentos restantes ganham mancha de tinta;
- uma **vinheta de tinta estática ou respirando devagar** (ciclo ≥ 2 s, fora do
  ritmo dos veios), **no máximo 8% de cada borda, opacidade ≤ 40%**, que **nunca
  avança para o centro** — só a morte fecha a tela (2.8);
- teste: um telégrafo e um inimigo na borda, sob a vinheta máxima, mantêm ≥ 40
  pontos de L* do chão e o contorno visível; se não passar, a vinheta vai para
  baixo da camada de telégrafos e personagens;
- uma **deixa sonora** própria (audio-director).

### 7.9 Opções de acessibilidade visual do MVP

| # | Opção | Valores | Padrão |
|---|---|---|---|
| 1 | Escala de UI | 85 / 100 / 125 / 150% | 100% em ≥ 1080p; 125% abaixo |
| 2 | Legendas (voz dos Mestres, fala do Campus) | liga/desliga; 24/32/40 px; fundo 0–100% | **ligado**, 32 px, fundo 75%; falante identificado pelo nome, nunca pela cor |
| 3 | Tremor de câmera | 0–100%, passos de 10 | 100% |
| 4 | Reduzir flashes | liga/desliga (o limitador de 3/s vale sempre) | desligado |
| 5 | Redução de movimento | liga/desliga (transições viram fade ≤ 300 ms; vinheta estática; **o hitstop continua**) | desligado |
| 6 | Vinheta de Vida baixa | 0–100% | 100% |
| 7 | Números de dano | ligado / reduzido (só crítico e total) / desligado | ligado |
| 8 | Número de Vida no HUD | liga/desliga | ligado |
| 9 | Vida colorida | liga/desliga | desligado |
| 10 | Alto contraste da UI | liga/desliga: painéis 100%, molduras em linha sólida de 3 px, raridade por contagem de linhas + palavra, texto osso puro sobre tinta pura; as formas continuam | desligado |
| 11 | Tamanho da mira | 1× / 1,5× / 2× | 1× |
| 12 | Fonte de leitura | Alegreya Sans / Atkinson Hyperlegible Next | Alegreya Sans |

Também obrigatório: remapeamento completo de teclado e gamepad; todos os menus
usáveis sem mouse; layout cabendo a 150% em 1280×720.

**Fora do MVP, de propósito:** filtros de daltonismo. O sistema já é
independente de cor por construção (forma primeiro, escada de valor, teste da
4.7). Opção futura: "intensidade do telégrafo" (contorno de 4 para 6 px), se o
playtest mostrar erro de leitura no Veio.

### 7.10 Painéis e molduras (nota de produção)

- Cantos chanfrados a 45° prontos para **9-slice**: cantos fixos e bordas que
  repetem sem costura.
- Painel: tinta ≥ 92% com texto; textura de hachura só na faixa da moldura; o
  leito do texto é chapado.
- A dessaturação de congelamento e os wipes de tinta são passes de tela (Seção 8).

**Donos fora da arte:** deixas sonoras de Vida baixa e de telégrafo
(audio-director); teclado na tela e escala em 720p (ui-programmer); ordem das
camadas entre vinheta e telégrafo (technical-artist); entrar por botão e limiar
de Vida baixa (game-designer).

## 8. Asset Standards

*Aprovada pelo CD em 2026-11-05. Autoria: art-director (arte) +
technical-artist (limites do Godot 4.7). Decisões: teto oficial **4K, arte em
2×**; densidade dos fundos decidida por **A/B no protótipo**; **min-spec de GPU
com 4 GB** em qualquer resolução.*

> **Verificação de engine.** Itens marcados *(NÃO VERIFICADO 4.7)* vêm do
> conhecimento do Godot 4.3/4.4 e não constam em `docs/engine-reference/godot/`.
> Confirmar no protótipo antes de tratá-los como regra.

**Medida de referência.** "px 1×" é o tamanho na tela a 1920×1080. A arte de
personagem, UI e ícones é exportada em **2×** (resolução nativa de 4K). As
espessuras da Seção 3.5 são proporções da tela: o traço de herói de 3 px vira
4 px a 1440p e 6 px a 4K.

### 8.1 Formatos de arquivo

| Etapa | Formato | Regra |
|---|---|---|
| **Bruto** (saída do Nano Banana) | JPG ou PNG, como veio | **Intocado para sempre**; prova de origem. Se o Gemini oferecer PNG, prefira PNG. |
| **Master de trabalho** | `.kra` (Krita) ou `.psd`, em camadas | retoque, correção de traço e de paleta; parte do bruto já recortado |
| **Exportado** (vai para o jogo) | **PNG-32 RGBA, 8 bits/canal, sRGB, alfa reto** (não pré-multiplicado), sem metadados | único formato importado pelo Godot |
| **Prompt** | `.prompt.md` ao lado do bruto | prompt completo, data, modelo e layout da folha — sem isso não se regera igual |

**Nunca JPG no jogo:** não tem alfa; a compressão gera halo justamente nas bordas
duras de preto contra cor (o nosso estilo); desloca as áreas chapadas do
cel-shading (quebra a checagem de paleta, 8.5); e soma perda com a recompressão
do Godot. O JPG só existe como entrada e morre no recorte.

**Exportação:** dimensões **múltiplas de 4** (de 128 no que for BC7); margem
transparente ≥ 4 px (em 2×) em volta da figura; tela do quadro de **tamanho fixo
por categoria** (8.3) com o pivô no centro do apoio dos pés. Se o empacotador
aparar o vazio, o deslocamento vai para `AtlasTexture.margin`.

### 8.2 Convenção de nomes

- Tudo em minúsculas, snake_case, só ASCII (sem acento, ç, espaço ou hífen):
  `eco_perdido`, `lamina`, `guardiao_rito`.
- Nomes de personagem, região e Doutrina seguem o **cânone** (conceito). Nada de
  nome do protótipo ("sacerdotisa", "ato_ii").
- Tokens de ação em inglês (são os nomes de animação no código).
- Todo arquivo exportado termina com a densidade: `_2x` (ou `_1x`).
- Versão (`_v01`) **só nos arquivos-fonte**; o nome exportado é estável.

| Prefixo | Conteúdo |
|---|---|
| `chr_` | Iniciado, Mestres, NPCs do Campus, criatura do pacto |
| `enm_` | inimigos comuns; a elite é variante (`_elite`) |
| `bos_` | chefes |
| `wpn_` | armas avulsas (peça de rig, ícone de arsenal) |
| `env_` | chão, paredes, bordas, primeiro plano (`_fg`), névoa; a região logo depois do prefixo |
| `prp_` | objetos de cena e interativos, inclusive portas |
| `por_` | retratos de diálogo e insígnias de Mestre |
| `crd_` | cartas de bênção: molduras por Doutrina e raridade, arte interna |
| `ui_` | painéis, molduras, barras, botões, cursor |
| `ico_` | ícones (levam o tamanho de exibição: `_32`, `_48`, `_96`) |
| `vfx_` | efeitos rasterizados (respingos, partículas, impact frames) |
| `key_` | arte de apresentação (cartaz de chefe, tela de título) |
| `tlg_` | reservado — **o telégrafo não é rasterizado** (8.6) |

**Padrões:**
- Estático: `[cat]_[nome]_[variante]_[dens].png` → `prp_braseiro_aceso_2x.png`,
  `env_veio_parede_curva_03_2x.png`, `ico_porta_fragmentos_32_2x.png`.
- Pose ou quadro: `[cat]_[nome]_[variante]_[acao]_[direcao]_[nn]_[dens].png` →
  `chr_iniciado_lamina_windup_frente_01_2x.png`.
- Peça de rig (5.8): `[cat]_[nome]_[variante]_part_[peca]_[direcao]_[dens].png`
  → `chr_iniciado_part_antebraco_d_frente_2x.png`.
- Folha montada: `[cat]_[nome]_[variante]_[direcao]_sheet_[dens].png` + o
  `.tres` de SpriteFrames de mesmo nome.
- Fonte: `…_raw_v03.jpg`, `…_raw_v03.prompt.md`, `…_work_v03.kra`.

**Vocabulário fixo de ação:** `idle`, `run`, `windup`, `attack`, `recover`,
`dash`, `cast`, `hurt`, `death`, `spawn`. Ação nova entra nesta lista antes de
ser usada.

**Direções:** as 5 desenhadas da Seção 5.8 — `frente`, `frente34`, `lado`,
`costas34`, `costas` — com a figura em 3/4 voltada para a direita; o lado
esquerdo sai por **espelhamento** no motor (a arma troca de mão, aceito).

### 8.3 Resolução e tamanho de quadro por categoria

**Regra de densidade:** personagens, UI, ícones, cartas e VFX são autorados e
exportados em **2×** e exibidos em 1× a 1080p com filtro linear com mipmap (é
ilustração, **nunca** nearest); a 4K a exibição é 1:1.

**Fundos pintados (chão, paredes): decididos por A/B no protótipo** (decisão do
CD). Candidatos: **2× BC7 + mipmap** (~64 MiB por câmara, nítido a 4K, artefato
leve) contra **1× Lossless** (~47 MiB, sem artefato, macio a 4K). O A/B é
capturado a 1080p e a 4K, com o chão ao lado de um telégrafo. Primeiro plano e
névoa ficam em 1× ou viram máscara no motor (8.6).

| Categoria | Corpo na tela (px 1×) | Quadro (px 1×) | Arquivo (2×) | Traço externo no arquivo |
|---|---|---|---|---|
| **Iniciado** | ~90 de altura | 160×160 | 320×320 | 6 px (herói) |
| **Inimigo comum** (Eco ~85–95; Anomalia Menor ~55 alt. × 90 larg.; Fenda ~60 × 110) | conforme ao lado | 160×160 | 320×320 | 6 px |
| **Estilhaço Vivo** | ~100–110 | 192×192 | 384×384 | 6 px |
| **Elite** | corpo-base ×1,15 + coroa | 192×192 | 384×384 | 6 px (a coroa não engrossa o traço) |
| **Criatura do pacto** | ~55 | 128×128 | 256×256 | 6 px (o fio de vínculo é do motor) |
| **Mestre / NPC do Campus** | ~95 | 160×192 | 320×384 | 6 px |
| **Anomalia Maior** | ~220 alt. × 420 larg. | 512×384 | 1024×768 | 7 px (3,5 px 1×) |
| **Guardião do Rito** | ~270 com a lança | 384×448 | 768×896 | 7 px |
| **Retrato de diálogo** | busto | 512×640 | 1024×1280 | 6 px |
| **Insígnia / mini-retrato** | — | 128×128 | 256×256 | 4–6 px |
| **Carta de bênção** (moldura sem texto) | — | 320×480 | 640×960 | 6 px |
| **Arte interna da carta** | — | 280×200 | 560×400 | 4–6 px |
| **Glifo de Tradição** | — | 96×96 | 192×192 | 4 px |
| **Ícones de HUD e de porta** | — | 32, 40 e 48 | 64, 80 e 96 | ≥ 2 px 1×; cada tamanho **ajustado à mão** |
| **Porta** | ~140 | 192×256 | 384×512 | 6 px |
| **Objeto de cena** | 32–256 | sob medida, múltiplo de 4 | 2× | 3 px (apoio) |
| **Módulo de parede ou borda** | — | 512×256 / 256×512 | conforme A/B | 3 px (apoio) |
| **Base do chão** | — | 512×512 ou chunk de 2048×2048 | conforme A/B | 1,5 px 1× nas bordas |
| **VFX** (por quadro) | — | 64×64 a 256×256 | 2× | segue a camada do efeito |

- **O traço é absoluto, não proporcional ao tamanho.** Nada no mundo passa de
  **3,5 px 1×** (7 px em 2×); acima disso só o telégrafo (4 px 1×).
- **Ícones pequenos não saem de redução automática:** o de 32 px é redesenhado
  para o traço continuar ≥ 2 px na tela.
- **Arte neutra de luz:** nenhum personagem, inimigo ou objeto chega com o
  grading regional pintado; o tom da região é aplicado no motor (8.6). Um mesmo
  Eco serve no Limiar e no Veio.
- **Origem mínima para o 2× ser real:** na folha do Nano Banana, o corpo da pose
  tem **≥ 270 px** (1,5× o alvo de 180 px em 2×). Abaixo disso é ampliação
  disfarçada: regerar em 2816×1536 ou com menos poses por folha.

### 8.4 Espessura de traço consistente com a IA

O Nano Banana não respeita espessura em pixels. A regra é **medir depois da
reescala**.

1. **Uma reescala só, direto do bruto e sempre para baixo:**
   `s = altura_alvo_2x ÷ altura_corpo_na_fonte`, uma escala por personagem
   (tirada da pose de referência). `s` ≤ 1,0, de preferência 0,35–0,8. Se
   `s > 1`, a imagem é recusada e regerada. **Nunca ampliar.** Reamostragem por
   média de área; sem nitidez artificial depois (cria halo claro em volta do
   preto).
2. **Medir o traço resultante:** ~10 pontos do contorno externo (fora mãos e
   arma), mediana.

| Camada | Alvo 2× | Faixa aceita 2× | Equivale em 1× |
|---|---|---|---|
| Herói | 6 | 5–7 | 2,5–3,5 |
| Apoio | 3 | 2–4 | 1–2 |

   Linhas internas e hachuras: 0,5–0,75 da espessura do contorno externo.
3. **Calibrar o prompt pela conta inversa:** traço necessário na fonte =
   `alvo_2x ÷ s`. Ex.: Iniciado numa folha 1408×768 em 2×4, corpo ~300 px →
   `s = 0,6` → traço de ~10 px na fonte; em 2816×1536, ~20 px.
4. **Correção:** desvio de até ±1,5 px em 2× é corrigido automaticamente
   (dilatar ou erodir a máscara de tinta, L* < 15). Desvio maior: retoque no
   master ou regeração (afinar demais apaga rosto e mãos).
5. **Uniformidade:** variação ≤ 1 px em 2× entre as poses de uma animação, senão
   o traço "pisca".

### 8.5 Paleta: checagem contra os HEX da Seção 4

**Não quantizar a imagem inteira para 7 cores** (o cel e o antisserrilhado
precisam de mais).

1. **Rampas oficiais:** cada cor da 4.1 ganha uma rampa de 3 tons (sombra, base,
   luz), ΔL* ~12–18, ajustada à escada da 4.2. Ficam em
   `assets/art/source/palette/` (`.gpl` + `.json`); os HEX exatos saem no
   `/asset-spec`.
2. **Ajuste suave:** só pixels internos e opacos de áreas chapadas são puxados
   para o tom de rampa mais próximo; bordas e hachuras ficam. Quase-pretos
   (L* < 12) viram **Tinta `#0D0E14`**.
3. **Checagem** (a ferramenta mede e relata; quem aprova é uma pessoa):
   - **acentos:** pixel com saturação HSV > 60% precisa estar a ΔE2000 ≤ 8 do
     magenta ou do dourado (ou de suas rampas); outro matiz saturado é sinalizado;
   - **tetos de valor:** personagens e objetos ≤ L* 82; corpos de Anomalia ≤ 70;
     magenta de ambiente ≤ 45 e saturação ≤ 60%;
   - **faixa reservada:** **nenhum asset de mundo com L* ≥ 88** (é do telégrafo e
     do impact frame);
   - exceção da UI: retratos e UI usam osso chapado até `#E6DFCF` (4.6);
   - o âmbar `#9A6A3E` só em asset de Campus ou Santuário;
   - **restrição do chroma key:** em personagens, `G − max(R,B) ≤ 62`, ou o
     recorte come a cor (petróleo e magenta passam).

### 8.6 Limites do Godot 4.7

**Importação 2D.** No Godot 4 o filtro não é opção de importação: fica no
CanvasItem (`texture_filter`) ou no projeto *(NÃO VERIFICADO 4.7)*.

| Perfil | Aplica-se a | Compressão | Mipmaps | Fix alpha border | Premult | Filtro |
|---|---|---|---|---|---|---|
| **P1 Herói** | personagens, inimigos, VFX em flipbook, UI, cartas, criatura | **Lossless** | ON | ON | OFF | Linear Mipmap |
| **P2 Fundo** | chunks de chão e parede | conforme A/B: Lossless ou **VRAM Compressed alta qualidade (BC7)** | ON | ON | OFF | Linear Mipmap |
| **P3 Máscara** | névoa, primeiro plano, feixes | Lossless, tons de cinza | OFF | ON | OFF | Linear |
| **P4 LUT** | grading regional | Lossless, 1024×32 | OFF | OFF | OFF | Linear, sem repeat |

- **Nunca BC1/BC3 em nada com traço** (blocos 4×4 sujam a linha preta). BC7 só
  em fundos, depois do A/B.
- **Premultiplied OFF:** alfa reto e blend Mix, para não quebrar o batching.
- Projeto: `snap_2d_transforms_to_pixel` e `snap_2d_vertices_to_pixel` OFF;
  `use_hdr_2d` OFF (a mistura fica em sRGB e bate com o Krita e a escada de L*).
- **Glow e HDR:** sem glow do WorldEnvironment (no 4.6 o glow passou para antes
  do tonemapping) e HDR output desligado (novo no 4.7). O brilho é pintado na
  arte, para preservar a escada de L*.

**Atlas e animação.**
- Cada animação num `SpriteFrames`; cada quadro um `AtlasTexture` apontando para
  **uma** página de atlas. **Proibido PNG por quadro** em animação (anula o
  batching).
- Um atlas por "elenco carregado junto": herói; inimigos e elites da região;
  chefe; VFX; UI.
- Página de atlas até **4096×2048**, padding de 4 px, quadros alinhados a 4 px.
- O rig 2D (5.8) usa peças em atlas: herói com no máximo **6 partes visíveis por
  quadro** no orçamento de draw calls.
- **O y-sort é o grande quebrador de lote:** no pior caso, conte 1 draw call por
  sprite. Sombras de contato ficam fora do y-sort, numa camada de chão com
  textura única.
- A ferramenta de recorte precisa **emitir `.tres` de SpriteFrames** (hoje emite
  JSON do PixiJS).

**Tamanhos e memória.**
- Nenhuma textura passa de **4096 px** em qualquer lado; fundos maiores viram
  **chunks de 2048×2048**.
- **Teto de memória de textura residente: 512 MiB, alerta em 448 MiB.** Com o
  min-spec de 4 GB (decisão do CD) há folga; o teto só sobe depois de medido no
  protótipo.

| Grupo | Residência | Teto |
|---|---|---|
| Jogador (peças de rig + quadros-chave, todas as armas), 2× Lossless + mip | run | 96 MiB |
| Criatura do pacto | run | 24 MiB |
| Elenco da região (comuns e elites) | região | 128 MiB |
| Chefe (o elenco da região é descarregado) | arena | 64 MiB |
| VFX | run e região | 48 MiB |
| UI, HUD, ícones e fontes | run | 64 MiB |
| Ilustrações das 3 cartas oferecidas | sob demanda | 16 MiB |
| Câmara atual (chunks + máscaras) | câmara | 64 MiB |
| Próxima câmara (pré-carga na transição de porta) | transitório | 64 MiB |

**Orçamento de draw calls (teto 500, pior caso sem lote):**

| Grupo | Teto |
|---|---|
| Ambiente (chunks, paredes, névoa, feixes, veios, primeiro plano) | 40 |
| Sombras + telégrafos (até 24 simultâneos) | 30 |
| Entidades em y-sort (herói ≤ 6 partes, inimigos ≤ 40 × 3, props ≤ 60) | 200 |
| VFX (≤ 24 emissores + ≤ 40 flipbooks) | 64 |
| Passes de tela cheia (morte, impact frame, bênção) | 6 |
| UI/HUD | 80 |
| **Reserva** | **≥ 80** |

A contagem de draw calls 2D precisa ser validada com captura no PIX (D3D12 é o
padrão no Windows desde o 4.6) ou RenderDoc: o monitor do Godot pode contar só
3D *(NÃO VERIFICADO 4.7)*.

**Grading regional, névoa e luz (implementação da 4.4 e da 6.3).**
- **Recomendado: ShaderMaterial compartilhado com `global uniform`** (LUT da
  região, força, escurecimento por profundidade): 0 draw calls extras e nenhuma
  cópia de tela, funciona dentro do y-sort. Três materiais: `amb_graded` (100%),
  `char_tint` (≤ 15%) e o padrão (telégrafos e UI, 0%).
- **Passes de tela** (BackBufferCopy / screen texture) só para efeitos globais
  transitórios: morte, impact frame, mundo dessaturado na tela de bênção.
- **Light2D:** no máximo 2 PointLight2D com textura, sem sombras, só em chefes.
  Sem normal maps.
- **Névoa e primeiro plano:** máscara de baixa resolução (ex. 512×256) com
  limiar no shader e borda nítida por `fwidth`; cor do global uniform da região;
  primeiro plano num Parallax2D com scroll 1,1–1,2.
- **Telégrafo:** shader SDF sobre um quad, contorno de 4 px que escala sozinho a
  4K. **Não usar `draw_arc` / `draw_line` / Line2D** (no 4.7 perderam a borda
  suavizada). O progresso vem do **tempo do gameplay**, não de `TIME`, para o
  telégrafo congelar no hitstop.
- **Fio de vínculo:** Line2D com textura de traço de borda suave, ou shader (pelo
  mesmo motivo).
- **Ordem no mundo**, numa CanvasLayer: chão (z −10) → sombras (−6) → telégrafos
  (−5) → y-sort de entidades e props (0) → névoa frontal, feixes e primeiro plano
  (10). Por cima: pós (50) e UI (100).
- **Overdraw:** ≤ 3,5 telas equivalentes em média no combate, ≤ 5 no pico de
  chefe.

**Partículas e VFX.** O estilo de quadrinho pede **flipbook** (impactos, cortes,
estrelas desenhados, no atlas de VFX); partículas só complementam (poeira,
fagulhas, vórtice).
- ≤ 24 emissores ativos; ≤ 1.500 partículas GPU e ≤ 300 CPU na tela; fagulha de
  golpe ≤ 24, ambiente ≤ 150, vórtice do chefe ≤ 600 por emissor; ≤ 40
  flipbooks simultâneos; overdraw de VFX ≤ 0,5 tela.
- GPUParticles2D: ativar o **Shader Baker** (4.5) na exportação para evitar
  travada no primeiro uso.
- VFX de ataque inimigo recebe 0% de grading. Se o hitstop tiver de congelar o
  VFX, o gameplay zera `speed_scale` dos emissores (testar se respeitam
  `Engine.time_scale`).

**Escala de resolução** (chaves explícitas no `project.godot`, porque o 4.7 mudou
os padrões para projetos novos):
- `display/window/size/viewport_width=1920`, `viewport_height=1080`;
- `display/window/stretch/mode="canvas_items"` (renderiza na resolução nativa;
  o traço fica nítido com a arte em 2×);
- `display/window/stretch/aspect="keep_height"` (**preserva o personagem a 1/12
  da altura**; ultrawide mostra mais largura);
- `display/window/stretch/scale_mode="fractional"`.
- **Ultrawide:** cada câmara tem **≥ 370 px lógicos de sangria por lado** (330
  visíveis em 43:18 + 40 do chute de câmera) e **≥ 40 px em cima e embaixo**;
  acima de 43:18 (W = 2580), pillarbox; abaixo de 16:9, letterbox. *(Revisto em
  2026-11-05 pelo GDD Cena 3/4 e câmera: era ≥ 300 px e 21:9, o que cortava os
  ultrawides reais 2560×1080 e 3440×1440.)*
- **Zoom de câmera** (soco no hitstop, intro de chefe): ≤ 1,15.

### 8.7 Checklist de aceite de uma imagem do Nano Banana

Três resultados: **Aceita**, **Aceita com retoque** (até ~15 min no master) ou
**Regerar**.

**Fundo e recorte**
1. Fundo `#00FF00` chapado e uniforme: sem gradiente, vinheta, papel ou moldura.
2. **Sem sombra projetada nem elipse de chão no verde**, sem luz verde rebatida
   na figura. A sombra é do motor.
3. Nenhum verde saturado *na figura* (o recorte come). Os cristais do Estilhaço
   Vivo, verde-água no protótipo, viram cristal neutro com veio magenta.
4. **Fumaça e brilho não são gerados sobre verde.** Os fiapos do Eco são **tinta
   sólida** em traço tracejado. Brilho, aura e faísca são gerados sobre preto
   `#000000` (mistura aditiva) ou feitos no motor.
5. Depois do recorte: sem halo verde a 400% de zoom, sobre fundo escuro e claro.
   O anel externo da figura é traço de Tinta.

**Folha e composição**
6. Número de poses bate com o layout; nenhuma figura toca a borda da célula
   (margem ≥ 5%) e nada fica cortado, nem a ponta da arma.
7. Mesma escala e mesma linha de chão em todas as poses (altura varia ≤ 5%, salvo
   agachar ou saltar de propósito).
8. Mesmo ângulo 3/4 em todas as folhas do personagem; direção conforme a 8.2.
9. Corpo da pose ≥ 270 px na fonte (8.3).

**Estilo e traço**
10. Ilustração de quadrinho com contorno preto fechado, cel de 2–3 tons, manchas
    de preto. **Recusar** pixel-art, gradiente suave, render 3D, brilho plástico
    ou textura fotográfica.
11. Traço dentro da faixa depois da reescala (8.4), com `s ≤ 1`.
12. Luz neutra, sem tom de região pintado.

**Leitura e cânone**
13. **Teste dos 48 px** (3.1).
14. Forma confere com a família (3.2) e com a Doutrina (3.3).
15. Bate com a ficha do personagem: proporção, roupa, dedos, mão da arma; acentos
    do casaco do Iniciado em osso (5.2).
16. Passa na checagem de paleta e valor (8.5).

**Limpeza**
17. **Nada de texto embutido** (letra, número, rótulo, assinatura, marca
    d'água). Todo texto é feito no Godot, por causa da localização.
18. **O `.prompt.md` não cita** jogo, anime, mangá, estúdio, personagem ou
    artista, nem "no estilo de…", e nenhuma imagem de terceiro foi usada como
    entrada (Seção 9.7). Conferido contra a lista de nomes proibidos **antes** de
    abrir a imagem. *(Acrescentado em 2026-11-05 com a Seção 9.)*

**Prova final:** o asset aceito vai num print do jogo sobre o chão do Limiar e
do Veio, que passa pelos filtros de daltonismo e cinza da 4.7. O print aprovado
fica em `production/qa/evidence/`.

### 8.8 Onde ficam os arquivos e fluxo do bruto ao jogo

```
assets/art/
  source/                 ← com .gdignore: o Godot NÃO importa esta pasta
    raw/[cat]/            brutos do Nano Banana + .prompt.md (intocados)
    work/[cat]/           masters .kra/.psd (versionados _vNN)
    palette/              khaeros_paleta.gpl, rampas .json
    reference/            moodboard e dioramas do protótipo (só referência)
    manifest.json         mapeamento bruto → poses (entrada da ferramenta)
  export/                 ← o único lugar importado pelo Godot
    chr/ enm/ bos/ wpn/ env/[regiao]/ prp/ por/ crd/ ui/ ico/ vfx/ key/
```

**Fluxo:** bruto + prompt → recorte (ferramenta) → **relatório de medidas**
(traço, `s`, paleta, L* máximo, resíduo de verde; a ferramenta observa e não dá
veredito) → revisão humana com o checklist da 8.7 → retoque no master →
exportação → print no jogo e aprovação.

**Ferramenta de recorte** (`Khaeros/eco-das-brasas/tools/`, a trazer para
`tools/asset-pipeline/`) — correções exigidas antes de usar no Godot:
- forçar o RGB dos pixels semitransparentes da borda para a Tinta `#0D0E14`
  (hoje sobra franja esverdeada: o despill é limitado a 18 níveis);
- aparar o vazio e gravar o deslocamento; teto de página de 4096 com divisão em
  várias páginas; padding de 4 px;
- emitir `.tres` de SpriteFrames em vez de JSON do PixiJS;
- separar os atlas por região (hoje `enemies.png` junta 190 quadros).

**Git:** brutos JPG e `.kra` pesam; Git LFS fica com o devops-engineer.

### 8.9 Conflitos arte × técnica e o que foi decidido

| # | Preferência de arte | Limite técnico | Decisão |
|---|---|---|---|
| 1 | tudo em 2× | 2× custa 4× a memória (+33% de mip) | 2× em personagens, UI, ícones, cartas e VFX (teto 4K, decisão do CD); fundos por A/B no protótipo |
| 2 | sem compressão no traço | Lossless = 4 B/px na VRAM | Lossless em tudo com traço; BC7 só em fundos, se vencer o A/B |
| 3 | câmaras pintadas únicas | 40 câmaras únicas ≈ 2,5 GB | **kit pintado por região** (chunks de chão, peças de borda orgânicas com alfa, decalques), sem grade aparente |
| 4 | muitos quadros | memória e atlas | **rig 2D + quadros-chave** (5.8); herói ≤ 400 quadros/peças a 2× |
| 5 | telégrafo, névoa e primeiro plano desenhados | traço exato a qualquer resolução e preenchimento que cresce | feitos no motor (shader / máscara), **nunca gerados pela IA** |
| 6 | props tingidos pela região | tingimento assado impede reaproveitar | props usam o material `amb_graded` |
| 7 | luz de recorte nos personagens | sem normal maps | tingimento uniforme de ≤ 15%; rim falso por amostras de alfa só se o art-director exigir |
| 8 | zoom dramático | a 4K qualquer zoom > 1 borra | zoom ≤ 1,15 |

**Em aberto (a medir no protótipo):** contagem real de draw calls 2D; se `TIME`,
partículas e névoa respeitam o hitstop (e se a névoa deve congelar); o A/B dos
fundos.

## 9. Reference Direction

*Aprovada pelo CD em 2026-11-05. Referências do CD: Hades II, Jujutsu Kaisen,
Hollow Knight, Valheim. Gustave Doré incluído por proposta do art-director,
aprovado pelo CD. Mark of the Deep incluído a pedido do usuário em 2026-11-13
(9.5b).*

**Princípio: cada referência entra por uma porta só.** Cada obra empresta uma
técnica ou regra específica, já escrita numa seção deste documento — nenhuma
empresta "a estética". Se duas referências parecem dar a mesma coisa, só a dona
listada na 9.6 vale. Quando duas puxam para lados opostos (a saturação de Hades
contra a contenção de Hollow Knight), quem decide é a regra central da Seção 1,
não a referência.

### 9.1 Hades II: o palco e o encontro

**Pegar:**
- **A câmara como palco:** miolo do chão calmo, borda carregada, densidade de
  detalhe caindo à medida que o perigo cresce (3.4, 6.3, 6.4).
- **A escolha como encontro com uma voz:** a bênção chega com quem a oferece —
  retrato, nome, uma linha de fala — e o mundo para em volta (2.6, 7.5).
- **O enquadramento 3/4 com o personagem a ~1/12 da altura da tela** (3.1, 5.9).

**Divergir:**
- **Cor por patrono: proibido.** Lá a cor identifica o deus; aqui a Doutrina se
  reconhece pela forma (P1, 3.3), e magenta e dourado têm significado fixo (4.3).
  É a divergência mais importante.
- **Raridade por cor: proibido.** Aqui vem do ornamento (3.6, 7.5).
- **Layout da oferta:** nada de lista horizontal com ícone em moldura redonda;
  são três cartas verticais de osso, topo na forma da Doutrina, moldura chanfrada.
- **Retrato:** busto ou meio-corpo de tinta, expressão contida (5.7); nunca uma
  figura grande, pintada e colorida dominando a tela.
- **Iconografia de panteão:** nada de meandro grego, louro, colunas clássicas,
  cerâmica de figuras (protege também a regra de não datar a Beira, 6.1).
- **Telégrafo:** nada de decalque vermelho; é magenta no topo da escada de valor
  e cresce em vez de pulsar (4.5).

**Teste anti-cópia:** se dá para descobrir de qual Mestre é uma carta só pela
cor, virou Hades. Refazer pela forma.

### 9.2 Jujutsu Kaisen: tinta que bate e corpo que sobra

**Pegar:**
- **A mancha de preto como presença ativa:** sombra como preenchimento de tinta
  sólida com borda desenhada (Seção 1, 5.7, 6.2).
- **O quadro de impacto:** quadro único em osso e tinta que congela o golpe
  decisivo (2.9); dele descendem a inversão de dano do jogador (5.5), o *smear*
  (5.8) e a onomatopeia "Quebrou!" (7.7).
- **O grotesco da sobra:** articulações a mais, olhos a mais, simetria quebrada,
  ritmo errado — a gramática da Anomalia (3.2).
- **O retrato de mangá de ação:** contorno externo grosso, traço interno fino,
  olhos angulosos, hachura dura no lado escuro (5.7).

**Divergir:**
- **Nada de elenco.** O Iniciado (cabelo prateado, casaco escuro) fica perto de
  um personagem famoso da obra: **nunca** usa venda nos olhos, óculos escuros
  redondos, gola alta abotoada de uniforme escolar nem cabelo espetado para cima.
  O cabelo segue o envelope da 5.3 e o casaco abre em sino (5.2).
- **Nada de escola japonesa:** sem uniforme estilo gakuran, torii, papel de selo
  com escrita, iconografia xintoísta ou budista. A Academia é pedra e madeira
  (6.1).
- **Gestos de selo:** o Selo "desenha" a forma no ar (5.8); nunca sinais de mão
  com dedos entrelaçados em mudras reconhecíveis.
- **Sem "expansão de domínio":** nenhum chefe troca o cenário por um espaço
  interno simbólico (2.7).
- **Sem relâmpago preto com vermelho** como efeito de golpe; vermelho não existe
  na paleta (4.1).
- **O grotesco é animal e mineral, nunca carne humana.** Anomalias **não têm
  boca, dentes nem rosto humanos** e não são corpos remendados; imitam bicho e
  criam cristal facetado (3.2). O lado humano é dos Ecos, e aparece por falta.
- **Sem retícula de mangá:** o tom vem de hachura (6.2) ou de cel chapado.

**Teste anti-cópia:** mostre o Iniciado, um Mestre ou uma Anomalia a quem conhece
a obra. Se a primeira reação for o nome de um personagem ou de uma técnica,
refazer.

### 9.3 Hollow Knight: contenção e ausência

**Pegar:**
- **A silhueta em preenchimento chapado com um traço distintivo por arquétipo**
  (3.1).
- **A quantidade de cor:** mundo quase monocromático, acento raro, pequeno e
  sempre com significado (Seção 1, princípio 2). Daqui vem só *quanto* acento; a
  temperatura de cada região é do Valheim (9.4).
- **A melancolia por ausência:** ruínas que não se explicam, criaturas que
  lembram alguém sem dizer quem (3.2, 6.5).
- **O primeiro plano escuro que emoldura** sem esconder (3.4, camada 8 da 6.3).

**Divergir:**
- **Rosto do Eco:** vazio de sombra sob o capuz; nunca máscara clara com dois
  olhos pretos, nem chifres ou pontas saindo da cabeça.
- **Nada de insetos antropomórficos.** A vespa e a aranha da 3.2 são Anomalias —
  bichos imitados e cheios de cristal —, não cidadãos de um reino.
- **O traço:** contorno preto fechado de 3 px no herói e 4 px no telégrafo
  (3.5); nunca linha fina, contorno ausente ou cenário sem traço.
- **O primeiro plano** é mancha de tinta chapada e nítida, sem desfoque.
- **O HUD:** a Vida nunca é contada em máscaras ou rostos; o Fluxo é uma gota, não
  um orbe com rosto (7.8).
- **A câmera:** a vista lateral de plataforma não serve de referência; Khaeros é
  3/4 de cima.

**Teste anti-cópia:** num print em cinza, se o contorno preto grosso some, o
print vira Hollow Knight. O traço de tinta é o que separa os dois.

### 9.4 Valheim: o lugar tem temperatura

**Pegar** (tradução completa na 4.4):
- **Um matiz dominante por região,** levado pela névoa e pelo ar, não pelos
  objetos (4.4, 2.10).
- **O céu como voz da região:** em 3/4, a faixa superior da tela, o teto de névoa
  (4.4 item 2, camada 1 da 6.3).
- **A profundidade que escurece** sem trocar de matiz (4.4 item 5).
- **A luz que dá o tom,** em feixes pintados ≤ 20% de opacidade, fora do chão de
  combate (4.4 item 3).

**Divergir:**
- **A técnica inteira:** nada de névoa volumétrica, gradiente suave de 3D,
  low-poly, textura pixelada ou neblina física. A névoa tem 2–3 faixas chapadas.
- **Nada nórdico:** sem runas, casa comprida, nó celta, árvore cósmica, machado
  de barba (cumpre também a 6.5: nenhum alfabeto consistente, nenhuma cultura
  datável).
- **As cores dos biomas:** nenhum matiz regional é tirado da obra; os HEX são os
  da 4.4, escolhidos pela semântica do magenta. Névoa arroxeada nunca encosta no
  magenta.
- **Ciclo de dia e noite e clima que muda:** fora. O tom de uma câmara é fixo,
  porque a escada de valor (4.2) precisa ser previsível.

**Teste anti-cópia:** dá para contar as faixas de névoa? Se a névoa é um degradê
que não se conta, virou Valheim.

### 9.5 Gustave Doré: a hachura como valor

**Lacuna que fecha:** nenhuma das outras referências cobre a **hachura** como
linguagem, e o documento depende dela: hachura por Doutrina (3.3), hachura
cruzada só na sombra (6.2), o "congelamento em gravura" da tela de bênção (2.6) e
o mundo que vira gravura na morte (2.8). Doré morreu em 1883; a obra está em
domínio público.

**Pegar:**
- **Densidade de hachura como escala de valor:** mais linhas = mais escuro;
  hachura cruzada só na sombra (6.2).
- **A distância como linha mais fina e mais espaçada:** planos distantes perdem
  hachura antes de perder forma (camada 2 da 6.3).
- **A gravura como estado:** na tela de bênção e na morte, o mundo some até
  sobrar só linha (2.6, 2.8).

**Divergir:**
- **Hachura densa em tudo:** quebra o contrato da 5.1. Hachura nunca entra no
  miolo do chão de combate (camada 4 da 6.3), e o personagem tem no máximo uma
  zona hachurada.
- **Iconografia bíblica e dantesca** (anjos, demônios alados, multidões de
  condenados) — esbarra também no veto a imagens do Colapso (6.5).
- **Papel sépia e anatomia acadêmica realista** no sprite. O papel é o osso da UI
  (4.6), e o sprite tem ~6 cabeças (5.2).

**Teste anti-cópia:** se aparece hachura no miolo do chão de combate ou no corpo
inteiro de um personagem, é Doré demais. Recuar para a 5.1.

### 9.5b Mark of the Deep: o lugar que gera o inimigo

*Incluído a pedido do usuário em 2026-11-13. A leitura vem de reviews (pesquisa
rápida), não de prancha: antes de usar, montar a prancha em
`assets/art/source/reference/` (9.7 item 1) e confirmar cada item contra
screenshots.*

O jogo é de um estúdio de São Paulo: ação e aventura isométrica numa ilha
amaldiçoada e abandonada. As reviews descrevem personagens 3D sobre cenários 2D
pintados, áreas muito distintas entre si, luz sombria e inimigos que "pertencem"
ao ambiente.

**Pegar:**
- **O inimigo feito do material do lugar:** a criatura carrega a matéria da área
  onde nasce. No Khaeros isso reforça a 3.2: o Eco do Limiar é névoa e tinta, a
  Anomalia do Veio é mais cristal, e o Estilhaço Vivo é mineral. A pergunta de
  design passa a ser "do que este lugar é feito, e o que nasceria disso?" (3.2,
  6.5).
- **A área reconhecível pela forma do cenário:** cada região tem um conjunto
  próprio de silhuetas de ruína e de objeto, que se lê antes da cor (3.4, 6.1).
  A cor e a temperatura continuam sendo do Valheim (9.4); daqui vem só o
  vocabulário de *forma* por região.
- **A distância de câmera 3/4 com personagem pequeno numa arena desenhada,**
  como prova de que o formato funciona num estúdio brasileiro de porte indie.
  Isso é referência de viabilidade, não de imagem.

**Divergir:**
- **Personagem 3D sobre fundo 2D:** fora. Tudo no Khaeros é 2D pintado com traço
  de tinta (6.2, 8.3), e o sprite não ganha volume renderizado nem shader de
  cel 3D.
- **Saturação e brilho no ambiente:** fora. Se a região ficar "colorida e
  brilhante", quebra a regra central (Seção 1). O que não fere nem se escolhe
  recua.
- **Iconografia pirata e caribenha** (navio, âncora, caveira com ossos, tricórnio,
  mar tropical): fora. A Beira não tem cultura datável (6.1, 6.5).
- **Mais uma camada "parecida com Hades":** a própria crítica nota que o visual
  desse gênero começa a parecer repetido. O palco 3/4 continua sendo do Hades II
  (9.1), e Mark of the Deep não acrescenta nada a ele.

**Teste anti-cópia:** um inimigo do Khaeros posto numa área de Mark of the Deep
deveria parecer fora do lugar, porque é feito da matéria da Beira. Se ele parece
"de lá", refazer.

### 9.6 Matriz de posse

| Elemento | Dono único | Onde está |
|---|---|---|
| Miolo calmo e borda carregada; densidade que cai com o perigo | Hades II | 3.4, 6.3, 6.4 |
| Escolha como encontro com uma voz | Hades II | 2.6, 7.5 |
| Escala 3/4 a ~1/12 da tela | Hades II | 3.1, 5.9 |
| Mancha de preto ativa | Jujutsu Kaisen | 1, 5.7, 6.2 |
| Quadro de impacto, inversão de dano, onomatopeia | Jujutsu Kaisen | 2.9, 5.5, 7.7 |
| Grotesco da sobra (Anomalias) | Jujutsu Kaisen | 3.2 |
| Retrato de mangá de ação | Jujutsu Kaisen | 5.7 |
| Silhueta chapada com um traço distintivo | Hollow Knight | 3.1 |
| *Quantidade* de acento | Hollow Knight | 1, 4.3 |
| Melancolia por ausência | Hollow Knight | 3.2, 6.5 |
| Primeiro plano que emoldura | Hollow Knight | 3.4, 6.3 |
| *Temperatura* por região, céu como voz, profundidade que escurece | Valheim | 4.4, 2.10 |
| Hachura como valor e distância; gravura como estado | Doré | 3.3, 6.2, 2.6, 2.8 |
| Inimigo feito do material do lugar; vocabulário de *forma* do cenário por região | Mark of the Deep | 3.2, 3.4, 6.1, 6.5 |
| Telégrafo, escada de valor, semântica do magenta e do dourado, molduras chanfradas, tipografia | **nenhuma referência**: próprios de Khaeros | 4.2, 4.5, 3.6, 7.2 |

A última linha importa: o que define a identidade e a leitura de combate não vem
de nenhuma obra. É o que nunca deve ser "corrigido" olhando uma referência.

### 9.7 Regras de uso de referência na produção

1. **Onde a referência mora:** prints, frames e moodboards ficam só em
   `assets/art/source/reference/` (com `.gdignore`, 8.8), nunca em `raw/`,
   `work/` ou `export/`. Cada prancha leva no nome a obra e o elemento (ex.:
   `ref_hades2_miolo-borda_01.png`, `ref_jjk_mancha-preto_03.png`), e a pasta tem
   um `.md` curto com a origem de cada imagem.
2. **Prompts do Nano Banana nunca citam** o nome de um jogo, anime, mangá,
   estúdio, personagem ou artista, nem "no estilo de...". O prompt descreve a
   técnica:
   - em vez de "estilo Jujutsu Kaisen": *"ilustração de quadrinho de ação,
     contorno externo preto grosso e uniforme, traço interno fino, manchas de
     preto sólidas nas sombras, hachura dura no lado escuro, cel de 2 a 3 tons"*;
   - em vez de "estilo Hollow Knight": *"silhueta simples e fechada, legível em
     preto sólido, paleta quase monocromática fria"*;
   - em vez de "névoa do Valheim": *"névoa em 2 a 3 faixas chapadas de cor, sem
     degradê"*.
   Doré também se descreve pela técnica, para os prompts terem um vocabulário só.
   A revisão confere o `.prompt.md` contra uma lista de nomes proibidos (item 18
   do checklist da 8.7).
3. **Nenhuma imagem de terceiro entra como entrada de imagem** (image-to-image,
   referência visual ou edição) no Nano Banana. Só arte própria de Khaeros:
   masters, fichas de personagem, pranchas aprovadas. Proibido decalcar ou pintar
   por cima de uma referência, mesmo como rascunho.
4. **A revisão usa os testes do art bible, nunca "parece com X".** A referência
   só confere se o elemento listado foi pego e se a divergência foi respeitada.
   "Ficou mais parecido com Hades" nunca é motivo para aprovar.
5. **Teste de origem nos assets-chave** (retratos dos Mestres, Iniciado, chefes,
   key art): mostre o asset sem contexto a alguém que conhece as seis
   referências. Se a pessoa disser de qual obra ele veio, volta para iteração,
   mesmo que passe no checklist da 8.7.
6. **Comparar o jogo em público** ("inspirado em...") é decisão do producer e do
   CD, não da arte.

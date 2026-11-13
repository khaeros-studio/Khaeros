# Prompt — chr_iniciado_ressonancia_ficha_raw_v02

- **Modelo:** Gemini ("Argon", Criar imagem, 16:9), na conversa da ficha v03 · **Data:** 2026-11-11 · **Folha:** R0, 4×1
- **Por que v02:** a v01 pedia o emblema de anéis nas costas. Pela decisão de 2026-11-11 o emblema é peça do rig, então as costas saem lisas. O formato é o compacto que funcionou nas folhas da Lâmina.

## Prompt (colar inteiro)

Gere uma IMAGEM nova de FICHA DE ARMA (não é folha de animação). Como referência do personagem, use SOMENTE a PRIMEIRA imagem desta conversa; IGNORE todas as imagens geradas depois dela. Troque SÓ a arma e a ponta dos painéis do casaco, como descrito abaixo. REGRA ABSOLUTA: nenhuma palavra, letra, número, símbolo ou emblema desenhado em lugar nenhum — as COSTAS do casaco e o mantelete são LISOS, só tecido cinza-azulado com a borda cor de osso; nenhum brilho, aura, faísca, fumaça, rastro ou linha de movimento; nenhuma linha divisória, borda, quadro, seta ou rótulo; fundo verde #00FF00 chapado e contínuo, sem sombra no chão. LAYOUT: imagem larga 16:9 com QUATRO elementos lado a lado, separados, sem se tocar: [1] o personagem em 3/4 de FRENTE, voltado para a direita, de corpo inteiro; [2] o personagem em 3/4 de COSTAS, voltado para a direita e para longe de quem olha, de corpo inteiro, cabeça de costas sem mostrar o rosto; [3] a arma ISOLADA, vertical e inteira; [4] detalhe grande do topo da arma. As figuras 1 e 2 na MESMA escala, cada uma ocupando no máximo 80% da altura da imagem, com o chão na mesma linha. ESTILO: igual à primeira imagem — quadrinho de ação adulto em nanquim, contorno externo preto muito grosso e uniforme, face de sombra em PRETO CHAPADO de borda dura, luz em 2 tons por material; sem degradê, sem 3D. PERSONAGEM: exatamente o da primeira imagem (cabelo prateado anguloso, gola alta, mantelete com borda de osso, casaco cinza-azulado com fecho de presilhas de osso, luvas pretas, antebraços enfaixados em osso, cinto com estojo cilíndrico atrás, botas com caneleiras de osso); acentos só em cor de osso. ÚNICA MUDANÇA NO CASACO: os 4 painéis abaixo da cintura terminam em ARCO ARREDONDADO com uma linha dupla cor de osso acompanhando a curva (no lugar das pontas em diagonal). ARMA — FOCO RESSONANTE: um cajado fino e reto, um pouco mais alto que o personagem; haste cinza-aço escura com detalhes em osso; no topo, um orbe redondo e liso cor de osso, suspenso dentro de dois anéis concêntricos finos de metal; o orbe fica acima da cabeça do personagem. Nada de brilho: o orbe é uma forma chapada com contorno preto. Ele NÃO carrega espada. SÓ DOIS BRAÇOS. POSE das figuras 1 e 2: de pé, firme, o foco na mão DIREITA, apoiado verticalmente ao lado do corpo, mão esquerda solta e um pouco aberta.

## Registro de geração

- 2026-11-11: gerada pelo navegador do app. Original em JPEG 2752×1536, capturado pelo laço que copia o `.tmp` do download.
- Resultado: vieram 4 elementos (frente, costas, foco isolado e detalhe do topo). As costas e o mantelete saíram **lisos**. O foco lê bem: haste cinza-aço com anéis de osso, orbe cor de osso dentro de dois anéis concêntricos e topo acima da cabeça. Sem brilho, sem espada, o mesmo personagem.
- Problemas:
  - **As pontas dos painéis continuam em diagonal**, com a linha dupla de osso mas sem o arco arredondado. É o motivo que separa as Doutrinas na silhueta.
  - A figura 1 está quase de frente, não em 3/4.
  - O orbe e os anéis ficam colados num plano só, como um alvo, sem o vão de "suspenso". Isso lê bem como o ícone de anéis da §3.3.
  - O verde aparece entre os anéis, o que exige recorte por cor dentro do topo.
- **Parecer do art-director (subagente, 2026-11-11): REGERAR, uma tentativa só.** Ele achou dois erros que eu não tinha visto e que reprovam o checklist:
  - **Mão errada na figura 1**: de frente, o cajado está à direita de quem olha, ou seja, na mão ESQUERDA do personagem.
  - **O orbe não passa da cabeça**: o anel externo termina no topo do cabelo e o orbe fica na altura dos olhos (§5.4). Corrige o que eu tinha anotado acima.
  - Os painéis em diagonal pesam pela propagação para R1 e R2. O ângulo de frente e o topo em plano único não pesam a 90 px; no sprite, o topo vira orbe + um anel.
  - Se a v03 trouxer a barra em diagonal de novo: aprovar com retoque manual dos arcos e usar a ficha retocada como referência.
- A v03 falhou nas três correções (ver o prompt dela). Decisão do usuário (2026-11-11): retocar a v02.
- **Retoque por código (2026-11-11)** → `chr_iniciado_ressonancia_ficha_raw_v02r.png` (PNG 2752×1536, sem recompressão JPEG). Feito com System.Drawing num script C# no scratchpad, sem editar pixels à mão.
  - Separação dos 4 elementos por componentes conexos fora do verde.
  - **Haste alongada em 305 px** nas figuras 1 e 2 e no cajado isolado: o topo (orbe e anéis) sobe e o vão é preenchido repetindo uma linha cinza da haste. Agora o orbe e os anéis ficam inteiros acima do cabelo, com folga de verde.
  - **Figura 1 espelhada**: o foco passa para a mão direita do personagem, à esquerda de quem olha. Efeito colateral: a luz do rosto e do corpo vem da esquerda nessa figura, e o cinto e as bolsas trocam de lado.
  - Recomposição: figuras 1–3 em escala 0,805 com o chão comum em y=1496; o detalhe do topo em 0,85.
  - **Aprovada pelo usuário em 2026-11-11 como a referência R0 da Ressonância.**
  - **Ainda falta: a barra em arcos** (festonê), que precisa de pintura à mão. Até lá a ficha mantém as pontas diagonais.

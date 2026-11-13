# Prompt — chr_iniciado_lamina_selo_frente34_raw_v01

- **Modelo:** Nano Banana (Gemini 3.1 Pro), na conversa da ficha v03 · **Data:** 2026-11-11 · **Folha:** L6, 4×2, 16:9
- **Conteúdo:** Selo ×8 (`cast` variante `selo`, 01–08), frente34. É um gesto de mão que "escreve no chão" 180 px à frente (GDD Selo e Fluxo, Overview). A espada fica na mão direita. Sem VFX na folha: o círculo é um sprite separado.
- **Enviado por:** usuário (remoto)

## Prompt (colar inteiro)

Gere uma IMAGEM nova. Como referência do personagem, use SOMENTE a PRIMEIRA imagem desta conversa (a ficha de design com frente, perfil e costas); IGNORE todas as folhas de poses geradas depois dela. REGRA ABSOLUTA: nenhuma palavra, letra, número ou símbolo escrito; nenhum círculo, runa, brilho, luz, aura, faísca, fumaça, poeira ou linha de movimento — o gesto é só do corpo, sem efeito mágico desenhado; nenhuma linha divisória, borda ou quadro; fundo verde #00FF00 chapado e contínuo, sem sombra no chão. LAYOUT: imagem larga 16:9 com EXATAMENTE 8 poses do MESMO personagem em grade invisível de 4 colunas e 2 linhas (4 em cima, 4 embaixo), lidas da esquerda para a direita, todas em vista 3/4 de frente voltadas para a direita, mesma escala, pés na mesma linha em cada fileira; cada figura ocupa no máximo metade da altura da sua célula, com margem livre em volta; a espada inteira dentro da própria célula. ESTILO: igual à ficha — quadrinho de ação adulto em nanquim, contorno externo preto muito grosso e uniforme (cerca de 1/25 da altura do corpo), a face de sombra de cada figura em PRETO CHAPADO de borda dura com a luz vindo da direita, luz em 2 tons por material, hachura diagonal só na transição; sem degradê, sem 3D. PERSONAGEM E ESPADA: exatamente os da ficha (cabelo prateado anguloso, gola alta, mantelete LISO com borda de osso e sem emblema, casaco cinza-azulado em 4 painéis com pontas em diagonal, presilhas de osso, luvas pretas, antebraços enfaixados em osso, botas com caneleiras de osso; espada longa reta com fio cor de osso); acentos só em cor de osso, nunca dourado ou magenta. AÇÃO — SELO: o personagem marca o chão à sua frente com um gesto ritual da mão ESQUERDA, como quem escreve uma ordem no chão; a espada fica baixa na mão direita o tempo todo. LINHA DE CIMA: [1] guarda: de pé, espada baixa em diagonal, olhar no chão à frente; [2] chamada: mão esquerda sobe até a altura do rosto com dois dedos estendidos juntos, cotovelo alto, olhar concentrado; [3] traço: a mão esquerda corta o ar num traço diagonal firme para baixo, tronco acompanha, casaco balança; [4] apontar: braço esquerdo esticado para baixo e para a frente, dois dedos apontando um ponto no chão adiante, joelho da frente dobrando. LINHA DE BAIXO: [5] marcar: agachado sobre um joelho, a palma esquerda aberta voltada para o chão adiante, dedos abertos, tronco inclinado à frente, painéis do casaco espalhados no chão; [6] sustentar: mesma posição, braço tenso, cabeça baixa, olhar fixo no ponto marcado; [7] erguer: levantando-se, mão esquerda recolhendo em punho junto ao peito; [8] volta à guarda: de pé, firme, espada baixa em diagonal, mão esquerda solta ao lado do corpo.

## Registro de geração

- 2026-11-11: gerada pelo usuário.
- Resultado: vieram 8 poses, sem efeito mágico nem texto. A chamada com dois dedos (2), o apontar (4), a palma no chão (5–6), o punho no peito (7) e a guarda (8) leem bem.
- Problemas que **reprovam** a folha:
  - As poses 1 e 2 estão **cortadas na cintura**, não são corpo inteiro.
  - A escala varia muito entre as figuras.
  - Na pose 3 aparece **uma segunda espada** na mão esquerda.
- Decisão: regerar como v02.
- **v02**, gerada com a correção curta: **reprovada e não salva**.
  - O Gemini misturou a folha com a ficha: vieram 6 figuras sobrepostas e um close da cabeça, em resolução de prévia.
  - A correção curta não funciona nesta conversa. A próxima tentativa é a v03, com o prompt completo e as correções embutidas.
- **v03**, gerada com o prompt completo (texto enviado ao usuário em 2026-11-11, que começa com "folha de animação, não é ficha"). Salva como `chr_iniciado_lamina_selo_frente34_raw_v03.jpg`.
  - Resultado: 8 figuras de corpo inteiro, na mesma escala, com uma espada só na mão direita e o gesto feito pela mão esquerda. As 8 poses estão na ordem pedida e o fundo veio limpo.
  - Retoques:
    - A pose 3 tem um traço curvo fino cor de osso, um rastro que é VFX e precisa ser apagado no recorte.
    - A imagem chegou em 1024×572 (prévia); em 2026-11-11 foi trocada pelo original de 2752×1536, baixado pelo navegador do app.
    - **Pose 5 com 3 braços** (apontado pelo usuário): a mão da espada, um braço esquerdo apontando e um terceiro braço com a mão no chão. Decisão do usuário (2026-11-11): a pose 5 é descartada e a pose 6 é usada nos quadros 5 e 6. **L6 v03 aprovada.**

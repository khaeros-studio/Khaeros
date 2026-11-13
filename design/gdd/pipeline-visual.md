# Pipeline visual

> **Status**: Approved (2026-11-10, `/review-all-gdds` 3ª passada, mantido Approved por decisão do usuário: S-B1, a troca na metade do wipe segue a ordem do estado Transição do Combate R1; S-B2, a Bênção só abre com o hitstop em 0; C-B2, os campos de duração do `CombatTuning` citados na R7 e na R12) — (`/design-review` 2026-11-10, lean, por subagentes: NEEDS REVISION — 7 bloqueantes nas regras e 9 nos critérios, revisados; re-review: NEEDS REVISION leve — 3 nas regras e 3 nos critérios, revisados na mesma data; os dois revisores confirmaram a aprovação com as correções; aprovado pelo usuário)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-10
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P3 *Reflexo que se lê* (regra central do Art Bible: "Da sombra, só sai o que fere ou o que se escolhe")

> **Nota (2026-11-11, Run e regiões):** a R3 deixa de dizer que a Run informa p: quem informa p são as Câmaras; a Run só dá `p_max` e a sequência.

> **Nota (2026-11-11, Tela de bênção e carta):** pendente: `modo_bencao` sai em `tela_fechada` (não no `escolher`).

> **Nota (2026-11-11, Feedback de combate):** pendente: com impact frame negado pelo limitador sai só o flash chapado (zoom, manchas, hitstop e número ficam); `uso` de VFX pode vir de uma contagem injetável.

> **Nota (2026-11-11, revisão cruzada):** pendente: o impact frame é P1 no Feedback (R7/R9 já citam o solicitante e a vítima P4–P2, resolvido em 2026-11-12); "3 flashes/s sempre" × passe obrigatório em fade (F6); Dependencies desatualizadas (Combate, Telégrafos, Feedback, Run e Câmaras existem).

## Summary

**Pipeline visual** é a camada de render que faz valer a regra central do Art
Bible, "da sombra, só sai o que fere ou o que se escolhe". Ele define três
famílias de material por papel, com grading regional por LUT de 100%, 15% ou 0%, o
escurecimento por profundidade em luz linear e a névoa fora do chão. Também
define a peça de desenho do telégrafo em SDF, com o contorno por cima dos
corpos, e o traço do jogador. Por fim, cuida do impact frame por modo global,
dos dois relógios dos shaders e dos orçamentos de render. Para o jogador, o
efeito é ler o perigo num relance (P3).

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Cena 3/4 e câmera, Conteúdo orientado a dados; Combate núcleo, Movimento e esquiva, Run e regiões, Câmaras e ondas (por contrato)`

## Overview

**Pipeline visual** é a camada de render que faz a regra central do Art Bible
valer em todo quadro: **da sombra, só sai o que fere ou o que se escolhe**. Ele
não decide o que aparece na tela (isso é dos sistemas de jogo) nem onde (camadas
e y-sort são da Cena 3/4). Ele decide **como** cada coisa é desenhada:

- **famílias de material por papel:** cenário com 100% do grading regional,
  personagens com até 15%, telégrafos, ataques inimigos e UI com 0%;
- **atmosfera:** grading por LUT de cada região, escurecimento por profundidade
  da câmara, névoa em faixas chapadas e feixes de luz, todos fora do chão de
  combate;
- **a peça de desenho do telégrafo** em SDF (forma, crescimento, contorno de
  4 px que acompanha a resolução, quebra). O GDD de Telégrafos a usa para cada
  ataque;
- **traço do jogador e leitura do corpo:** o tracejado fino das ações, o
  contorno de invulnerabilidade na silhueta inteira, as imagens residuais, a
  inversão de silhueta e o flash de acerto;
- **momentos de tela:** impact frame (por um modo global nos materiais), morte,
  transição de tinta entre câmaras e a Bênção dessaturada;
- **os dois relógios** que o Combate pediu: um vivo, que congela no hitstop, e um
  de apresentação, que corre no hitstop e para na pausa. Os dois são entregues
  aos shaders por variáveis próprias, nunca pelo `TIME` do motor;
- **orçamentos e configuração:** draw calls (teto 500), overdraw, partículas,
  memória, importação de texturas e as chaves de projeto que o Art Bible §8.6
  exige.

Para o jogador, o efeito é a promessa do P3: **o olho acha o perigo num
relance**. O telégrafo é a coisa mais clara da tela e nunca some atrás de um
corpo. A ação do jogador nunca se confunde com um aviso inimigo. O mundo recua
para a sombra, e a região muda de tom sem mudar a leitura.

> **→ vira ADR:** estrutura de nós e materiais (CanvasLayers, CanvasGroup,
> `global uniform`), o caminho do grading (LUT global ou plano B) e o
> orquestrador dos relógios. A referência do motor não cobre o renderer 2D do
> 4.7; os experimentos E1–E7 (Open Questions) vêm antes do ADR.

## Detailed Design

### Core Rules

> `technical-artist` consultado para escopo e viabilidade (modo Lean);
> `art-director`, `godot-shader-specialist` e `gameplay-programmer` não
> consultados nesta seção. Revisar manualmente antes de produção. Toda API citada
> existe no Godot 4.7.2 instalado (sonda no ClassDB, 2026-11-10), mas o
> comportamento está **NÃO VERIFICADO** até os experimentos E1–E7 (Open
> Questions). A referência do motor não cobre o renderer 2D.

**R1. Três famílias de material por papel** (revisão 1; decisão do usuário,
2026-11-10). Todo CanvasItem do mundo usa um shader de uma destas três
famílias. A **família** decide o grading; o **shader** decide o desenho.

| Família | Grading regional | Quem usa |
|---|---|---|
| `amb_graded` | 100% | chão, paredes, veios, fundo, névoa, feixes, primeiro plano, props do y-sort e sombras de contato |
| `char_tint` | `forca_grading_personagem` (15%) | jogador, inimigos, aliados (o corpo) e a aura de elite (acento do corpo, §4.3) |
| `sem_grading` | 0% | telégrafos, VFX de ataque inimigo, VFX e traços de ação do jogador (inclui as imagens residuais), fio de vínculo, números e letreiros no mundo, UI |

- **Include e marca de família.** Cada shader do jogo inclui o `.gdshaderinc`
  da sua família (caminho e nome no ADR). O include traz o que a família faz
  (F1, F2, F5 e o `modo_impacto` da R7) e declara a **marca de família**, que o
  validador lê. O mecanismo da marca (constante do include, metadado do recurso
  ou nome do arquivo) é do ADR.
- **Variante** é outro `ShaderMaterial` do mesmo shader, com outros valores de
  uniform. Um `render_mode` diferente (por exemplo `blend_add`) é decidido na
  compilação: é **outro shader** da mesma família, não variante.
- **Shaders do jogo** (lista fechada: um shader novo entra aqui antes de entrar
  no jogo), com o comportamento por valor de `modo_impacto` (R7) e na Bênção
  (F5):

| Shader | Família | Desenha | `recusa` | `chefe` | `reduzido` | Bênção |
|---|---|---|---|---|---|---|
| `amb_sprite` | `amb_graded` | chão, paredes, veios (pulsação, R4), props, sombras de contato, fundo | tinta chapada `#0D0E14` | osso chapado `#E6DFCF` | um passo abaixo na escada, dessaturado (R11) | F5 |
| `amb_mascara` | `amb_graded` | névoa e primeiro plano (máscara P3 com limiar e `fwidth`, R4) | tinta chapada | osso chapado | como `amb_sprite` | F5 |
| `amb_aditivo` | `amb_graded`, `blend_add` | feixes | some (0) | some (0) | como `amb_sprite` | F5 |
| `char_sprite` | `char_tint` | peças do rig e sprites de corpo; estado por entidade (R6) | inimigos e aliados em tinta chapada com contorno osso `#E6DFCF` por peça (R7) | tinta chapada, sem contorno | F1 e dessaturação de um passo (R11) | F5 |
| `char_grupo` | `char_tint` (repassa a saída das peças) | CanvasGroup do jogador: contorno de invulnerabilidade e inversão (R6) | jogador em osso pleno `#E6DFCF`; contorno e inversão suspensos | jogador em tinta chapada | contorno e inversão seguem | não muda |
| `tel_sdf` | `sem_grading` | preenchimento (quad, z −5) e contorno (malha de borda, z 5) do telégrafo (F4) | preenchimento some; contorno em osso `#E6DFCF` | preenchimento some; contorno fica em tinta | não muda | não há telégrafo vivo (Edge Cases) |
| `traco_sdf` | `sem_grading` | tracejado de ação (F7), anéis de área e explosão, glifo do projétil, imagens residuais, fio de vínculo | some | some | não muda | não há (Edge Cases) |
| `vfx_sprite` | `sem_grading` | flipbooks, partículas, números, letreiros, VFX de ataque inimigo | VFX de ataque inimigo em osso chapado `#E6DFCF`; o resto some | VFX de ataque inimigo em tinta chapada; o resto some, menos as manchas de tinta do abate (VFX) | não muda | números e letreiros somem ao abrir (Edge Cases) |
| `ui` | `sem_grading` | HUD, cartas, menus | não muda | não muda | não muda | não muda (as cartas são UI) |

- Os passes de tela (wipe e morte; R7) ficam em `pós` (z 50), não são
  CanvasItem do mundo e não têm família. Shaders dos passes, fora das famílias e fora da lista fechada acima: `pass_wipe` (wipe de tinta e fade) e `pass_morte` (tinta das bordas). Cada um tem material próprio no nó de `pós`; `progresso_wipe` (e o progresso da morte) é **uniform do material do passe**, não global.
- A tabela de camadas da Cena (R4) diz em que camada cada coisa fica; esta
  regra diz a família. Um CanvasItem de mundo cujo shader não traz marca de
  família é erro de autoria: em debug, o validador do Pipeline lista os nós sem
  família (aviso no registro de depuração, sem parar o jogo).
- Trocar a família de um nó fora desta tabela é proibido (Art Bible §8.6,
  §8.9 nº 6–7).

**R2. Grading regional.**

- Cada região tem uma LUT 32³ (textura 1024×32, perfil P4 do Art Bible §8.6:
  sem compressão com perda, sem mipmaps, sem repetição; teste da LUT identidade, F1). A cor final é
  `mix(cor, lut(cor), força)`, com a força do material (R1). "Até 15%" nos
  personagens quer dizer exatamente essa mistura (F1).
- A LUT ativa é um `global uniform sampler2D lut_regiao`, trocado na entrada de
  região, sob a transição de tinta (R7). **Plano B**, se o E2 mostrar que a LUT
  global não funciona em canvas_item ou no Shader Baker: um `uniform sampler2D`
  comum nos shaders das três famílias, trocado por script na troca de
  região. O resto da regra não muda.
- A névoa, os feixes e a cor de fundo também vêm da região (uniforms globais de
  cor; Cena, Visual/Audio para a cor de fundo).
- **Bênção:** com `modo_bencao` ligado, `amb_graded` e `char_tint` vão para
  `saturacao_bencao` (20%) e `valor_bencao` (60%) (F5: luma em linear, mistura e valor no sRGB codificado; Art Bible §4.4: 15–25% e
  −40%). `sem_grading` não muda; as cartas são UI. A Bênção só abre com a
  câmara limpa, sem telégrafo vivo, e números e letreiros no mundo somem no
  quadro em que ela abre (Edge Cases). A câmara limpa só é avaliada com o
  hitstop em 0 (Combate núcleo R10), então a Bênção nunca abre sobre um
  congelamento pendente; ela também espera o *impact frame* ativo terminar
  (Estados).

**R3. Escurecimento por profundidade** (decisão do usuário, 2026-11-10). Cada
câmara mais funda da região escurece chão, paredes, veios, props e sombras de contato: a luminância, em linear, de `amb_graded` é
multiplicado por `max(piso_profundidade, 1 − passo_profundidade × p)` (F2), com
p = o `p` das Câmaras (só câmaras de combate, 0–4 no Limiar; o santuário usa o `p` da última câmara de combate), informado pelas Câmaras; a CPU calcula o multiplicador e o envia no global `fator_profundidade`. Fundo, névoa, feixes e primeiro plano não escurecem (`recebe_profundidade` falso; decisão do usuário, 2026-11-10). Não muda o matiz, nem `char_tint`, nem
`sem_grading`. O tom mais escuro do chão, depois da LUT, continua dentro da faixa L* 22–38 em toda profundidade
(F2, VV3, AC). Escurecer em linear é decisão do usuário (2026-11-10): no sRGB codificado o chão cairia a L* 21,1.

**R4. Névoa, feixes, veios e primeiro plano** (Art Bible §4.4, §4.5, §6.3).

- **Névoa:** 2 ou 3 faixas chapadas, sem escurecimento por profundidade (R3), desenhadas por máscara de baixa resolução
  (512×256) com limiar e borda por `fwidth`, mais densas no topo da tela e nas
  bordas. A máscara vive **em espaço da câmara** (px de mundo): cobre o
  retângulo da câmara mais a sangria (Cena R6) e anda com o mundo, nunca presa à
  tela; assim o lookahead, o chute e o zoom de 1,15 não a levam para o chão. A
  névoa frontal, na camada do primeiro plano, segue a deriva da Cena F7. A máscara é zero sobre o retângulo jogável: **a névoa nunca cobre o
  chão de combate**, e por isso nunca cobre um telégrafo.
- **Feixes:** camada aditiva de opacidade ≤ `opacidade_max_feixes` (20%), em
  diagonais, fora do chão de combate.
- **Veios (magenta ambiente):** L* ≤ 45 depois da LUT, **no pico da pulsação** (VV15), saturação ≤ 60%, nunca geometria
  fechada; pulsação com ciclo ≥ 2 s e amplitude ≤ 10% de valor, no relógio de
  apresentação, sem fase comum com nenhum telégrafo. A zona de silêncio perto da
  borda do chão é regra de autoria do Art Bible §4.5.
- **Primeiro plano:** ≤ 15% da tela. O parallax é do `CameraTuning` (Cena R4,
  R11); este GDD propõe 1,15 (resposta à Cena OQ6) e não guarda o valor. O fundo
  e a névoa distante seguem com parallax 1,0 (Cena).

**R5. Primitiva de telégrafo** (contrato para o GDD de Telégrafos; Art Bible
§4.5, §6.3). O Pipeline desenha; o GDD de Telégrafos decide forma, tamanho,
tempo e qual ataque usa cada um.

- **Formas:** `circulo` (raio), `setor` (raio e meio-ângulo; o arco e o cone),
  `retangulo` orientado, ancorado no meio do lado do atacante (comprimento e largura; a linha e a investida) e `anel`
  (raio interno e externo). As dimensões são em px de mundo e têm de ser as do
  teste de acerto do golpe (Combate R13; P3).
- **Entrada por telégrafo:** forma, posição, rotação, dimensões, progresso
  `p` ∈ [0, 1] (calculado pelo GDD de Telégrafos no relógio vivo), modo de
  crescimento (`borda_ao_centro`, `centro_a_borda` ou `ao_longo_do_eixo`) e
  estado.
- **Estados:** `crescendo` (o preenchimento cresce com `p`; **nunca pulsa**);
  `disparo` (flash de osso por `passos(duracao_flash_telegrafo_s)` (2) passos vivos e some; se o limitador negar, núcleo e anel ficam como estão, sem osso, e somem, F6);
  `quebrado` (uma rachadura de tinta atravessa o preenchimento em 2 passos vivos e
  some, sem flash; Combate V9); `cancelado` (o dono morreu ou saiu: some em 2
  passos vivos, sem flash, com opacidade 1 → 0,5 → 0).
- **Cores fixas** (sem grading, sem névoa): núcleo `#FFD3EE` (L* ≈ 88), anel
  interno `#FF3DAE` (faixa de `largura_anel_px` junto ao contorno; base do núcleo a `opacidade_base_telegrafo` em p = 0; a confirmar pelo art-director), contorno `#0D0E14` com `contorno_telegrafo_px` (4 px a
  1080p, em unidades de canvas, por dentro da borda de acerto) que escala com a resolução (F3, F4). O núcleo fica ≥ 40 L* acima do chão
  (Art Bible §4.2).
- **Duas passadas** (decisão do usuário, 2026-11-10): o **preenchimento** (núcleo
  e anel) fica em sombras e telégrafos (z −5, abaixo do y-sort), e o corpo dos
  personagens o cobre; o **contorno** fica numa camada própria acima do y-sort
  (`contorno de telégrafo`, z 5, entre o y-sort e a frente), a 100%, desenhado
  numa **malha de borda** (a faixa do contorno mais a margem de suavização), não
  num quad cheio (F4, F10). Nota para o ADR: `MeshInstance2D` com `ArrayMesh` (mais controle que `Polygon2D`), vértices em coordenadas locais do telégrafo e `varying` de `VERTEX` para o fragmento recalcular a SDF; um `ShaderMaterial` por telégrafo (sem `instance uniform`, E7). Assim o
  telégrafo nunca some atrás de um corpo (Art Bible §6.3) sem máscara. Pede a
  assinatura do art-director e uma linha nova no §6.3 e no §8.6 ("o corpo cobre
  o preenchimento").
- **Acessibilidade futura:** o contorno aceita `contorno_telegrafo_alto_px`
  (6 px) para a opção de intensidade do telégrafo (Art Bible §7.9, rodapé).

**R6. Traço do jogador e leitura do corpo.**

- **Tracejado de ação do jogador** (Combate V2–V5, V13; Movimento V3): família
  `sem_grading` (shader `traco_sdf`) com contorno tracejado de `largura_tracejado_px` (1,75 px a
  1080p), traço de `traco_tracejado_px` (8) e intervalo de
  `intervalo_tracejado_px` (6), escalados com a resolução (F3). Valor ≤ L* 82.
  Serve para o raio de fora do *smear*, o anel da área e da explosão, o glifo do
  projétil e as imagens residuais da esquiva. Cor: osso de mundo `#CFC6B4`
  (L* 80,15).
- **Anéis de área e explosão** (Combate V3, V13): na camada `telégrafo`
  (z −5), como pede o Combate, num nó irmão **anterior** ao dos preenchimentos
  de telégrafo; assim ficam abaixo de qualquer telégrafo ativo. Contam no grupo
  VFX do R9, não no de sombras e telégrafos.
- **Contorno de invulnerabilidade** (Combate V10, V11; decisão do usuário,
  2026-11-10): o rig do jogador fica num CanvasGroup (shader `char_grupo`, R1), e
  o shader desenha a **silhueta inteira** tracejada em osso de mundo `#CFC6B4`
  (L* 80,15), **por fora** da borda do alfa (fase angular estática, F7; larguras
  × `escala_traco`), sem costuras, pelo tempo exato da invulnerabilidade
  pós-dano e da recusa (durações do Combate). Não pisca e não muda a
  luminosidade. Só o jogador tem o efeito.
- **CanvasGroup do jogador:** `fit_margin` ≥ (max(`largura_tracejado_px`,
  `contorno_silhueta_px`) + 1) × `escala_traco`, para o contorno por fora caber
  no buffer (a unidade do `fit_margin` é NÃO VERIFICADO, E5). A origem do grupo
  fica no pé do jogador, que é a chave do y-sort (Cena R5).
- **Inversão de silhueta** (Art Bible §5.5, Combate V10; revisão 1): no shader
  `char_grupo`, sobre a saída do CanvasGroup inteiro. Todo pixel com alfa > 0
  vira **tinta chapada** `#0D0E14`, e a borda do alfa ganha, por fora, um
  contorno sólido em osso de mundo `#CFC6B4` de `contorno_silhueta_px` (3). Não
  há limiar por peça: o traço interno e as manchas escuras não viram osso, e as
  sobreposições das peças não aparecem. Dura os passos de hitstop do golpe
  recebido mais o extra do Combate (V10: 4 passos vivos; o número é do Combate,
  que o envia no evento; decisão do usuário, 2026-11-10; emenda ao "2 quadros"
  do §5.5). Enquanto a inversão está ativa, o contorno sólido dela substitui o tracejado de invulnerabilidade; o tracejado volta no passo seguinte ao fim da inversão.
- **Flash de acerto em inimigo** (Combate V6): `char_sprite` mistura osso de
  mundo `#CFC6B4` (L* ~80) pela duração da V6 do Combate (5 passos vivos; o
  número é do Combate, enviado no evento), segurado no hitstop.
- **Estado por entidade** (decisão do usuário, 2026-11-10): cada entidade do
  y-sort tem o **próprio** `ShaderMaterial` (instância do shader da família,
  duplicada no spawn), com os uniforms `papel` (jogador, inimigo, aliado),
  `flash` e, nos props `oclusor`, `alfa_oclusao`. O orçamento do R9 já é contado
  sem lote (1 draw call por sprite no y-sort, §8.6), então o material único não
  custa draw call. O custo de CPU e de troca de estado com 9 a 40 entidades é
  NÃO VERIFICADO (E7). `instance uniform` em canvas_item não é usado: o suporte
  no 4.7 é NÃO VERIFICADO (E7).
- **Imagens residuais** (Movimento V3): até 3 silhuetas do jogador, cada uma no
  y do pé onde foi deixada, tracejadas em osso de mundo (`traco_sdf`), sem
  mancha de contato. Duas opções para o E5 e o ADR:
  - **(a) snapshot:** no passo em que a imagem nasce, a saída do CanvasGroup é
    copiada para uma textura própria (uma cópia por imagem; 1 draw call por
    imagem; memória ~3 × W × H × 4 B do buffer do grupo, < 1 MiB no total a 4K
    para um grupo de ~128 × 160 unidades);
  - **(b) rig duplicado:** 3 CanvasGroups com a pose congelada (até 3 × 6
    peças = 18 draw calls, mais 3 buffers de grupo).
  O R9 conta 3 draw calls (opção a); a opção b pede +15 no grupo de entidades.
- **Fio de vínculo** (aliado; Art Bible §4.1, §4.3, §8.6), regra mínima:
  família `sem_grading`, osso de mundo `#CFC6B4`, traço contínuo com borda
  suavizada (nunca `draw_line` nem Line2D sem textura, que no 4.7 perderam a
  suavização). Forma, largura e animação são do GDD do aliado; Line2D com
  textura × quad com SDF de segmento é o E6. Se o E6 escolher Line2D com textura, o fio usa `vfx_sprite` (não `traco_sdf`) e a tabela da R1 muda.
- **Oclusão** (decisão do usuário, 2026-11-10): um prop do y-sort marcado como
  `oclusor` que cobre o jogador (o retângulo de oclusão autorado `R_oc` contém o pé ou o centro
  do corpo do jogador, e o prop está à frente no y-sort) fica com opacidade
  `opacidade_oclusao` (40%), com transição de `duracao_transicao_oclusao_s`
  (0,1 s = 6 passos de 1/60 s de `t_apres`) no relógio de apresentação, com histerese de `margem_histerese_oclusao_px` (8) na saída (F9). Chefe que cobre o jogador é do GDD de Chefes.

**R7. Momentos de tela.**

- **Impact frame** (Combate V11, V12; decisão do usuário, 2026-11-10): um
  `global uniform int modo_impacto` muda todos os shaders ao mesmo tempo, sem
  passe de tela (comportamento por shader na tabela da R1). Valores (revisão 1):
  - `0`: nenhum;
  - `recusa` (Combate V11): mundo (`amb_graded`) em tinta chapada (L* ≤ 10);
    jogador em osso pleno `#E6DFCF` (L* ≥ 88, a exceção do §4.2); inimigos e
    aliados em tinta chapada com contorno osso; telégrafo só com o contorno, em
    osso; UI não muda;
  - `chefe` (Art Bible §2.9, Combate V12): impact frame **em osso** com manchas
    de tinta: mundo em osso chapado `#E6DFCF`, personagens em tinta chapada,
    telégrafo só com o contorno, em tinta; as manchas são do VFX; UI não muda;
  - `reduzido` (R11): o mundo dessaturado um passo na escada, sem tela em osso
    nem em tinta.
- **Contorno dos inimigos no `recusa`** (decisão do usuário, 2026-11-10): por
  peça, no `char_sprite`, amostrando o alfa vizinho. Cada quadro do atlas de
  inimigo tem **margem transparente ≥ `contorno_silhueta_px`** (3 unidades; na
  textura, × a densidade da arte: 6 texels com arte em 2×, acima do padding de
  4 px do §8.6; OQ12). As costuras internas entre peças são aceitas.
- **Solicitante e dono:** o **solicitante** do impact frame é o **Feedback de
  combate** (Combate → Feedback → Pipeline; remetente único); o **Combate é o
  dono do evento** (quando e por quanto tempo). Chefe vence recusa continua
  valendo (preempção abaixo).
- **Duração:** quem decide quando e por quanto tempo é o dono do evento (Combate;
  o Feedback repassa o pedido). A
  duração vem sempre em **passos de apresentação** (1/60 s de `t_apres`), no
  campo `impact_passos` do evento: passos(`hitstop_recusa_s`) na recusa e
  passos(`impact_chefe_s`) no chefe (Combate núcleo R15, R17).
- **Limite:** no máximo 1 impact frame por segundo. O do chefe tem
  **preempção** (decisão do usuário, 2026-11-10): se uma recusa ocupou a janela
  de 1 s, o do chefe a substitui (se a recusa ainda está na tela, é cortada).
  No mesmo passo, vence o chefe (Combate AC1). O limite de 3 flashes por
  segundo vale sempre (§7.7), inclusive para o chefe (F6).
- **Limitador de flashes:** no máximo 3 flashes de tela por segundo (Art Bible
  §7.7), numa janela de 1 s em tempo real monotônico (F6). Contam o impact frame (inclusive o reduzido), os passes de tela e os disparos de telégrafo cuja área somada no passo passa de `limiar_area_flash` (11% da tela; decisão do usuário, 2026-11-10); o pedido negado é descartado, e o evento de jogo segue, **exceto o passe de tela obrigatório** (transição de câmara, morte): ele conta no `N_flash` e nunca é negado; se a janela já estiver cheia, sai como fade de `duracao_fade_s` (shader `pass_wipe`) em vez do wipe de tinta. O flash de acerto num sprite
  de inimigo não conta (Combate AC1).
- **Transição de câmara** (Cena R10): passe de tela de tinta que cobre em
  `duracao_wipe_s` / 2, troca a câmara (e a LUT, se a região mudar) e descobre na
  outra metade (0,4 s no total). A troca acontece no estado de jogo
  **Transição** do orquestrador (Combate núcleo R1): no primeiro quadro com
  `progresso_wipe` ≥ 0,5, na ordem da R1, vêm "câmara nova" (hitstop
  zerado), o teleporte, a câmara nova, os VFX apagados, o corte da câmera (Cena
  R10) e, por último, a LUT e o zero dos relógios (F8). O passe tem **progresso próprio**: o uniform
  `progresso_wipe` do material de `pass_wipe` (0 → 1; não é global), avançado pelo orquestrador com o `dt` de
  apresentação (limitado por `dt_max_apres`, F8). Ele não lê `t_apres`, então o
  zero dos relógios no meio da transição não o afeta.
- **Morte** (Art Bible §2.8): passe de tela de tinta que avança das bordas; a
  duração e o conteúdo são da Run e do VFX. O passe usa progresso próprio, como
  o wipe.
- **Bênção:** R2.
- **Teto:** no máximo `teto_drawcalls_passes` (6) draw calls de passes de tela.

**R8. Os dois relógios** (Combate V1; resposta à OQ4 do Combate).

- **`t_vivo`** (global uniform, segundos): avança 1/60 a cada passo vivo e para
  no hitstop, na pausa, na Bênção e fora de Jogo (inclui a Morte e a transição).
- **`t_apres`** (global uniform, segundos): avança com o tempo real do quadro (sem `Engine.time_scale`, limitado a `dt_max_apres` = 0,1 s por quadro) e
  para só na pausa, na Bênção e nos menus. **Corre no hitstop**, na transição
  e na Morte.
- Os dois voltam a 0 no meio da transição de câmara, com a tela coberta (F8). Quem escreve os dois é o orquestrador do passo (Combate R1), uma vez por
  quadro. **Nenhum shader do mundo usa `TIME`** (regra para o control manifest). A UI
  (shader `ui`) pode usar `TIME`: ela precisa animar com `t_apres` parado na
  Bênção e nos menus, e não congela no hitstop. Os passes de tela usam o próprio
  progresso (R7).
- **Emissores e animações:** os do relógio vivo ficam com `speed_scale` 0
  enquanto o mundo está congelado (hitstop, pausa, Bênção); os do relógio de
  apresentação, só na pausa e na Bênção. Animações do relógio vivo (rig,
  `AnimatedSprite2D`) são avançadas pelo passo ou congeladas com `speed_scale`
  0. O comportamento de `speed_scale` 0 nos emissores é **NÃO VERIFICADO** (E3).
- Qual efeito usa qual relógio é do dono do efeito (Combate V1, Movimento V3).

**R9. Orçamentos** (Art Bible §8.6, com o rebalanceamento do telégrafo; decisão
do usuário, 2026-11-10).

| Grupo | Draw calls |
|---|---|
| Ambiente (chão, paredes, veios, fundo, névoa, feixes, primeiro plano) | 40 |
| Sombras e telégrafos (sombras em até 6 draw calls com lote + até 24 telégrafos × 2 passadas: preenchimento em quad, contorno em malha de borda) | 54 |
| Entidades no y-sort (inclui até 3 imagens residuais: 3 draw calls na opção a da R6; a opção b pede +15) | 200 |
| VFX (inclui os anéis de área e explosão em z −5 e as manchas da recusa) | 64 |
| Passes de tela | 6 |
| UI | 80 |
| Reserva | ≥ 56 |
| **Teto** | **500** |

- Overdraw (área dos quads e malhas, transparente incluído; F10) ≤ 3,5 telas em média e ≤ 5 no pico de chefe. Fatias: VFX ≤ 0,5 tela; sombras e telégrafos ≤ 0,4 na média e ≤ 0,8 no pico (24 telégrafos). A fatia de telégrafos é **contrato do GDD de Telégrafos** (o 0,8 só vale com 24 círculos de r ≈ 120; setores e retângulos grandes estouram). O buffer do CanvasGroup do jogador e os passes `pós` em tela cheia (até +1 tela na transição) ficam **fora da soma da F10**: medir à parte na captura.
- **O 24 de telégrafos é o orçamento do Pipeline** (24 × 2 passadas = 48 draw
  calls, `teto_telegrafos`): o Pipeline é o dono; o GDD de Telégrafos só o lê.
- **Corte no teto de VFX:** antes do "sai o mais antigo do relógio de
  apresentação", vale a escolha de vítima de **P4 a P2** do Feedback R4 (P0 e P1
  nunca saem); só então o mais antigo. Flash, telégrafo e inversão nunca saem.
- Partículas: ≤ 24 emissores; ≤ 1.500 GPU e ≤ 300 CPU; fagulha ≤ 24, ambiente
  ≤ 150, vórtice ≤ 600 por emissor; ≤ 40 flipbooks simultâneos.
- Luz: no máximo 2 PointLight2D, sem sombras, só em chefes; sem normal maps. A
  luz só atinge `amb_graded` e `char_tint`: os `sem_grading` ficam com um
  `light_mask` sem o bit da luz (`range_item_cull_mask` da luz; nomes NÃO
  VERIFICADO no 4.7). O ganho sobre o chão fica ≤ L* 38 no ponto mais claro,
  medido na captura da arena do chefe.
- Memória residente de textura: 512 MiB, alerta em 448 (grupos do Art Bible
  §8.6). Os tetos somam 504 MiB no pior caso de residência, acima do alerta (VV13).
- **Fonte de verdade da contagem:** captura no PIX (D3D12) ou no RenderDoc
  (Vulkan, `--rendering-driver vulkan`), até o E1 mostrar que o monitor de draw
  calls conta o 2D.
- **Acima do teto:** vale o "Corte no teto de VFX" acima (vítima de P4 a P2
  do Feedback R4; P0 e P1 nunca saem; só então o mais antigo do relógio de
  apresentação, política da V15 do Combate). Nunca se corta flash, telégrafo
  ou inversão.

**R10. Configuração de projeto e importação.** O `project.godot` tem de
declarar (hoje não declara):

- filtro padrão de textura de canvas Linear Mipmap
  (`rendering/textures/canvas_textures/default_texture_filter`; chave NÃO
  VERIFICADO no 4.7);
- `rendering/2d/snap/snap_2d_transforms_to_pixel` e
  `rendering/2d/snap/snap_2d_vertices_to_pixel` desligados (caminhos NÃO
  VERIFICADO no 4.7);
- `rendering/viewport/hdr_2d` desligado e a saída HDR do 4.7 desligada
  (`request_hdr_output`; a chave exata do projeto é NÃO VERIFICADO: a referência
  só diz que a função existe); nenhum `WorldEnvironment` com glow (o 2D não usa);
- os `shader_globals` da R2, R3, R7 e R8 (`lut_regiao`, cores da região,
  `fator_profundidade`, `modo_impacto` (0, recusa, chefe, reduzido; R7), `modo_bencao`, `saturacao_bencao`, `valor_bencao` (F5; do `VisualTuning`, escritos na carga), `t_vivo`, `t_apres`,
  `escala_traco` = s_tela × zoom, só para o CanvasGroup e os passes com FRAGCOORD; os traços vivem em unidades de canvas, decisão do usuário, 2026-11-10);
- Shader Baker ligado no preset de exportação (que ainda não existe; fica para o pipeline de build; a chave do preset é NÃO VERIFICADO).

O stretch e o viewport são da Cena (R1). Os perfis de importação P1–P4, o
formato dos arquivos e os nomes são norma do Art Bible §8.1–8.6: o Pipeline cita,
não redefine.

**R11. Acessibilidade (lado de render).**

- **Reduzir flashes** (§7.9 nº 4): o impact frame vira o mundo dessaturado um
  passo na escada (`modo_impacto` = `reduzido`), sem tela em osso nem em tinta;
  o flash de inimigo cai para L* ~65 (valor do Combate, AC1). Isto é a **opção** Reduzir flashes: vale também com `modo_impacto` = 0 e não é parte do valor `reduzido`.
- **Redução de movimento** (§7.9 nº 5): a transição de câmara vira fade de
  `duracao_fade_s` (≤ 0,3 s); a vinheta fica estática. Hitstop e animações de
  jogo continuam.
- **Alto contraste** (§7.9 nº 10) é da UI; o telégrafo já fica no topo da escada.
- **Daltonismo:** nada depende de matiz (a escada de L* e a forma carregam a
  leitura). Filtros de daltonismo ficam fora do MVP (§7.9).
- Toda captura de aprovação passa pelos 3 simuladores e por tons de cinza
  (§4.7); a ferramenta de captura é parte do Pipeline (modo de debug).

**R12. `VisualTuning`** (dado; Conteúdo R1, um `*Tuning` por sistema). Os
números das R2–R11 ficam neste recurso (F1–F3 e faixas no Formulas). Os
orçamentos da R9 são norma do Art Bible e ficam na mesma tabela, como
referência para as ferramentas de medição.

- **Durações** ficam em segundos (`_s`) e viram passos pela F7 do Conteúdo,
  `passos(t_s) = max(1, round(t_s × 60))`, uma vez, na carga.
- **Durações dos efeitos que o Combate dispara** são do Combate (decisão do
  usuário, 2026-11-10), nos campos `flash_acerto_s`, `extra_inversao_s`,
  `impact_chefe_s`, `hitstop_recusa_s` e `invuln_atingido_s` do `CombatTuning`
  (Combate núcleo R15). O Pipeline as recebe prontas no evento (`flash_passos`,
  `inversao_passos`, `invuln_passos`, `impact_passos`; Combate R17) e só as
  implementa.
- **O parallax do primeiro plano** é do `CameraTuning` (Cena R11).

**R13. Injeção.** O Pipeline recebe por injeção: o `VisualTuning`, a região atual
(LUT e cores), a profundidade da câmara, o estado do orquestrador (Jogo,
hitstop, pausa, Bênção, menu, transição), as opções de acessibilidade, a posição
e o retângulo do jogador (oclusão), a lista de telégrafos ativos e as durações
dos efeitos do Combate (no evento). Os testes
montam tudo em memória; o que só se vê na tela vai para captura [V].

### States and Transitions

**Modo de tela** (um por vez; a ordem de prioridade é Transição > Morte >
Bênção > Impacto > Normal; um pedido de impacto durante a Bênção é descartado; um impacto **ativo** é cortado quando a Transição ou a Morte entram, e a Bênção **espera** o impacto terminar para abrir):

| Modo | Entra quando | Sai para |
|---|---|---|
| Normal | começo da câmara; fim de qualquer outro | Impacto, Bênção, Transição, Morte |
| Impacto | o Feedback pede, por evento do Combate (abate de chefe, recusa), e o limitador deixa | o anterior, ao fim da duração pedida |
| Bênção | a tela de bênção abre | Normal, ao fechar |
| Transição | troca de câmara | Normal, ao descobrir |
| Morte | `jogador_morreu` | fim da run (Run e regiões) |

**Relógios por estado do jogo:**

| Estado | `t_vivo` | `t_apres` |
|---|---|---|
| Jogo (passo vivo) | corre | corre |
| Hitstop | parado | corre |
| Pausa | parado | parado |
| Bênção | parado | parado |
| Menus | parado | parado |
| Transição de câmara | parado | corre |
| Morte | parado | corre (a confirmar com a Run, OQ11) |

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Cena 3/4 e câmera | família por camada; camada do contorno de telégrafo (z 5); proposta de parallax do primeiro plano (1,15, OQ6; o valor fica no `CameraTuning`) | tabela de camadas e z (R4), y-sort (R5), câmera, troca de câmara (R10) | Cena (camadas), este GDD (materiais) |
| Combate núcleo | relógios, `modo_impacto`, flash de acerto, inversão, contorno de invulnerabilidade, limitador | pedidos de impact frame (modo e duração em passos de apresentação), durações do flash de acerto e da inversão, eventos | Combate (quando), este GDD (como) |
| Movimento e esquiva | material das imagens residuais (tracejado) | posição e direção da esquiva | Movimento (quando), este GDD (como) |
| Telégrafos | primitiva (formas, estados, duas passadas) | forma, dimensões, `p`, estado de cada telégrafo | este GDD (primitiva), Telégrafos (uso); **provisório** |
| Feedback de combate (VFX) | materiais, tracejado, relógios, orçamento de VFX | os efeitos de cada evento | VFX; **provisório** |
| Run e regiões | — | região atual (LUT, cores), profundidade da câmara | Run; **provisório** |
| Câmaras e ondas | — | props marcados como `oclusor` | Câmaras; **provisório** |
| Acessibilidade e opções | — | Reduzir flashes, Redução de movimento, intensidade do telégrafo | Acessibilidade; **provisório** |
| Conteúdo orientado a dados | — | `VisualTuning`, LUTs e máscaras como recursos | Conteúdo |
| HUD / Menus | material `sem_grading` (UI sem grading e sem névoa) | — | UI |

## Formulas

> Proposta do `systems-designer` (modo Lean). Decisões do usuário, 2026-11-10:
> escurecimento em linear com VV3 (Q1); névoa e fundo sem profundidade (Q2);
> traço em unidades de canvas (Q3); flash de telégrafo só acima do limiar de
> área (Q4); propostas A2–A20 adotadas. Contas de L* feitas à mão (sRGB IEC
> 61966-2-1, D65, CIE 1976), ±0,2 L*: conferir por script antes do aceite. Todo
> comportamento de shader é **NÃO VERIFICADO** até os experimentos E1–E7.

**Convenções**

- `srgb2lin(c)` = c/12,92 se c ≤ 0,04045; senão ((c + 0,055)/1,055)^2,4.
  `lin2srgb(y)` = 12,92·y se y ≤ 0,0031308; senão 1,055·y^(1/2,4) − 0,055.
- `Y(c) = 0,2126·R_lin + 0,7152·G_lin + 0,0722·B_lin` (Rec.709, D65).
  `L*(Y) = 116·Y^(1/3) − 16` se Y > 0,008856; senão 903,3·Y.
- Com `use_hdr_2d` desligado, `COLOR` e a mistura ficam em **sRGB codificado**
  (Art Bible §8.6). "Codificado" é esse espaço; "linear" é depois de `srgb2lin`.
- `cov(x, aa) = clamp(0,5 − x/aa, 0, 1)`: cobertura suavizada da região
  {x < 0}, com `aa = length(vec2(dFdx(x), dFdy(x)))` (unidades de canvas por
  pixel físico, ≈ 1/(s_tela × z_camera)).
- **Unidade de traço:** larguras e dimensões em **unidades de canvas = px de
  mundo antes do zoom da câmera** (com zoom 1, 1 unidade = 1 px lógico de
  1080p). O zoom da câmera e o stretch `canvas_items` as levam ao pixel físico
  (F3); por isso o traço engrossa com o zoom.
- **`passos(t_s)`** = F7 do Conteúdo: `max(1, round(t_s × 60))`.
- **Passo de apresentação** = 1/60 s de `t_apres`. **Passo vivo** = um passo do
  orquestrador (1/60 s de `t_vivo`).
- **Ordem das operações.**
  - `amb_graded`: F1 (f = 1) → F2 (só onde `recebe_profundidade` = verdadeiro)
    → F5 (se `modo_bencao`) → `modo_impacto` (R7).
  - `char_tint`: F1 (f = 0,15) → F5 → `modo_impacto`.
  - `sem_grading`: nada disso.
- **`recebe_profundidade`** é um uniform de material (não global). Há dois
  recursos `ShaderMaterial` com o mesmo shader `amb_graded`: um com verdadeiro
  (chão, paredes, veios, props do y-sort, sombras de contato) e um com falso (fundo, névoa, feixes,
  primeiro plano). Isto é variante permitida pela R1 (mesmos uniforms).

### F1. Grading por LUT

The lut_grading formula is defined as:

`c_out.rgb = mix(c.rgb, lut(c.rgb), f)` ; `c_out.a = c.a`

Amostragem de `lut()` numa textura 1024×32 (32 fatias de 32×32 lado a lado:
vermelho em x dentro da fatia, verde em y com v = 0 no topo, azul escolhe a
fatia):

`b = c.b × 31` ; `s0 = floor(b)` ; `s1 = min(s0 + 1, 31)` ; `t = b − s0`
`u(s) = (32·s + 31·c.r + 0,5) / 1024` ; `v = (31·c.g + 0,5) / 32`
`lut(c) = mix(tex(u(s0), v), tex(u(s1), v), t)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| c | vec4 | 0–1 por canal | calculated | cor do texel, sRGB codificado, alfa reto |
| f | float | {1; 0–0,15; 0} | data file | 1 em `amb_graded`; `forca_grading_personagem` (0,15) em `char_tint`; 0 em `sem_grading` (o shader nem amostra) |
| s0, s1 | int | 0–31 | calculated | fatias de azul vizinhas |
| t | float | 0–1 | calculated | interpolação manual entre as fatias |
| u, v | float | u ∈ [0,5/1024; 1023,5/1024]; v ∈ [0,5/32; 31,5/32] | calculated | UV com meio texel |
| c_out | vec4 | 0–1 | calculated | cor graduada |

**Output Range:** 0–1 por canal, porque é combinação convexa de duas cores em
[0, 1].

- O meio texel deixa u dentro de [32s + 0,5; 32s + 31,5]/1024, e o filtro
  bilinear nunca lê a fatia vizinha.
- A LUT precisa de filtro Linear, **sem mipmaps** (o mip misturaria fatias),
  **sem repeat** e sem compressão com perda (perfil P4; VV4). R e G são
  interpolados pelo hardware; B, pelo `mix`.
- **Teste da LUT identidade:** com a LUT identidade, `|lut(c) − c| ≤ 1/255` em
  todo canal. O teste pega a convenção de eixos errada (verde invertido, fatia
  trocada) da ferramenta que gera a LUT.
- O alfa fica intacto, o que bate com o premultiplied OFF.

**Example:** personagem com c = (0,60; 0,50; 0,40) → b = 12,4, s0 = 12,
s1 = 13, t = 0,4; u0 = (384 + 18,6 + 0,5)/1024 = 0,39365;
u1 = (416 + 18,6 + 0,5)/1024 = 0,42490; v = (15,5 + 0,5)/32 = 0,5. Se a LUT do
Limiar devolve (0,55; 0,50; 0,60): com f = 0,15, c_out = (0,5925; 0,50; 0,43).
Com f = 1 (cenário), c_out = (0,55; 0,50; 0,60).

### F2. Escurecimento por profundidade

The depth_darkening formula is defined as:

`k = max(piso_profundidade, 1 − passo_profundidade × p)` (na CPU, uma vez por
câmara; enviado em `fator_profundidade`)
`c' = lin2srgb(k × srgb2lin(c_LUT))` se `recebe_profundidade`; senão `c' = c_LUT`
Efeito em L* (acima do joelho): `L*' = (L* + 16) × k^(1/3) − 16`
Piso mínimo para o chão: `k_min = ((22 + 16) / (L*_chao_min + 16))³`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | int | ≥ 0 | injected | o `p` das Câmaras (só câmaras de combate; o santuário usa o `p` da última câmara de combate), 0 na primeira |
| passo_profundidade | float | 0–0,05 | data file | `VisualTuning` (0,03) |
| piso_profundidade | float | k_min–1 | data file | `VisualTuning` (0,85) |
| k | float | piso–1 | calculated | multiplicador de luminância em linear; com 0,03/0,85 chega ao piso em p = 5 |
| fator_profundidade | float | piso–1 | calculated | global uniform = k |
| c_LUT | vec3 | 0–1 | calculated | saída do F1 com f = 1 |
| recebe_profundidade | bool | — | constant (por material) | verdadeiro: chão, paredes, veios, props, sombras de contato; falso: fundo, névoa, feixes, primeiro plano |
| L*_chao_min | float | 22–38 | calculated | L* do tom **mais escuro** do chão **depois** da LUT da região, em p = 0 |
| k_min | float | 0–1 | calculated | menor piso que mantém esse tom ≥ 22 |

**Output Range:** k ∈ [piso, 1]; c' ∈ [0, c_LUT]. Valores com k = 0,85
(p ≥ 5), aplicados em linear:

| Cor | L* em p = 0 | L* em k = 0,85 | Recebe? |
|---|---|---|---|
| Chão `#343C4A` | 25,1 | **23,0** (dentro de 22–38) | sim |
| Ardósia/parede `#2B3240` | 20,7 | 18,8 | sim |
| Sombra de parede, L* 10 | 10,0 | 8,6 (vira tinta) | sim |
| Névoa e fundo, L* 35–55 | 35–55 | 35–55 | **não** (Q2) |
| Núcleo do telégrafo `#FFD3EE` | 88,9 | 88,9 | não (`sem_grading`) |
| Núcleo − chão (regra: ≥ 40) | 63,8 | 66,0 | — |

Chão `#343C4A` por câmara (passo 0,03):

| p | 0 | 1 | 2 | 3 | 4 | ≥ 5 |
|---|---|---|---|---|---|---|
| k | 1 | 0,97 | 0,94 | 0,91 | 0,88 | 0,85 |
| L* | 25,1 | 24,7 | 24,3 | 23,9 | 23,4 | 23,0 |

- **A restrição que manda é o piso da faixa do chão, não a regra dos 40 L*.**
  O telégrafo não escurece, então a diferença núcleo − chão só cresce.
- **O tom mais escuro do chão, já com LUT, precisa de L* ≥ 24,12 em p = 0**
  (`k_min` ≤ 0,85). O `#343C4A` (25,1) passa com 1 L* de folga. Um segundo tom
  do chão mais escuro que 24,12 (o §6.3 permite ~6 L* de variação no miolo) não
  passa: VV3 bloqueia a LUT ou pede o tom clareado (art-director).
- **Registro:** aplicado ao sRGB codificado (V do HSV), o mesmo 0,85 levaria o
  chão a 21,1 (fora da faixa a partir de p = 4). Rejeitado (Q1).
- **Otimização permitida, se o custo aparecer no E2:** `c' = c_LUT × k^(1/2,4)`
  no codificado. Fica ~0,4 L* mais claro no chão (23,4), do lado seguro da
  faixa. Conferir os desvios em 10–40 L* no E2 antes de adotar.

**Example:** p = 2 → k = 0,94 → k^(1/3) = 0,9796 → chão
(25,1 + 16) × 0,9796 − 16 = **24,3**; parede (20,7 + 16) × 0,9796 − 16 = 19,9.
VV3 com um tom escuro do chão de L* 23,5 depois da LUT: `k_min` =
(38/39,5)³ = 0,890 > 0,85 → erro.

### F3. Escala do traço

The stroke_scale formula is defined as:

`s_tela = min(W_janela / 1920, H_janela / 1080)` ;
`px_fisico = w_canvas × s_tela × z_camera`
Toda largura de traço vive em **unidades de canvas** (px de mundo antes do zoom;
`w_canvas = px_1080` com zoom 1), e o zoom e o stretch `canvas_items` fazem a
conta. Só os shaders que trabalham em pixel físico
(contorno de invulnerabilidade no CanvasGroup; passes de tela que usam
`FRAGCOORD`) multiplicam por `escala_traco = s_tela × z_camera` (global uniform,
escrito pelo orquestrador a cada quadro).

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| W_janela, H_janela | int | > 0 | injected | tamanho da janela em pixels físicos |
| s_tela | float | > 0 (0,667 em 720p; 2,0 em 4K) | calculated | `keep_height`: janela mais larga → s = H/1080; mais estreita → letterbox, s = W/1920. O pillarbox acima de 43:18 não muda s |
| z_camera | float | 1–1,15 | injected | zoom da câmera (soco no hitstop, intro de chefe) |
| w_canvas | float | ver Faixas | data file | `contorno_telegrafo_px` 4; `contorno_telegrafo_alto_px` 6; `largura_anel_px` 6; `largura_tracejado_px` 1,75; `traco_tracejado_px` 8; `intervalo_tracejado_px` 6; `contorno_silhueta_px` 3 |
| escala_traco | float | > 0 | calculated | s_tela × z_camera |
| px_fisico | float | > 0 | calculated | largura na tela |

**Output Range:** sem clamp. O traço acompanha o zoom (4 → 4,6 px em 1080p com
zoom 1,15) e mantém a razão 1,33 com o traço de 3 px do herói, que está pintado
na arte. A suavização da borda sempre usa `aa` (1 pixel físico).

| Janela | s_tela | contorno 4 | tracejado 1,75 | traço 8 / intervalo 6 |
|---|---|---|---|---|
| 1280×720 e 1280×800 (Deck, letterbox de 40 px) | 0,667 | 2,67 | **1,17** | 5,33 / 4 |
| 1920×1080 e 2560×1080 | 1 | 4 | 1,75 | 8 / 6 |
| 1920×1200 (letterbox de 60 px) | 1 | 4 | 1,75 | 8 / 6 |
| 2560×1440 e 3440×1440 | 1,333 | 5,33 | 2,33 | 10,67 / 8 |
| 3840×2160 | 2 | 8 | 3,5 | 16 / 12 |

Abaixo de s_tela ≈ 0,857, o tracejado fica com menos de 1,5 px físico e
esmaece pela cobertura parcial (pode esmaecer; sem aviso no padrão, porque o VV7 só dispara com `largura_tracejado_px` × 0,667 < 1,0). O `TEXTURE_PIXEL_SIZE` do
CanvasGroup em pixel físico é **NÃO VERIFICADO**.

**Example:** 1440p, contorno 4 → 5,33 px físicos; com zoom 1,15, 6,13. No
shader do telégrafo, aa = 1/(1,333 × 1,15) = 0,652 unidade de canvas. Contorno
de invulnerabilidade no CanvasGroup com tracejado de 1,75: 1,75 × 1,533 =
2,68 px físicos.

### F4. Preenchimento e contorno do telégrafo por SDF

The telegraph_sdf formula is defined as:

`q = R(−θ) · (pos − origem)` (unidades de canvas)

SDFs, com d < 0 dentro:

- **círculo:** `d = |q| − r`
- **anel:** `d = | |q| − r_m | − t_a`, com `r_m = (r_int + r_ext)/2` e
  `t_a = (r_ext − r_int)/2`
- **retângulo orientado, ancorado no atacante** (a origem fica no meio do lado
  do atacante; eixo +x local para a frente): `q_c = q − (L/2, 0)` ;
  `v = |q_c| − (L/2, W/2)` ; `d = |max(v, 0)| + min(max(v.x, v.y), 0)`
- **setor** (ápice na origem, eixo +x local, meio-ângulo α, raio R): girar q
  para o eixo +y, então `q.x = |q.x|` ; `cα = (sin α, cos α)` ; `l = |q| − R` ;
  `m = |q − cα·clamp(q·cα, 0, R)|` ; `d = max(l, m·sign(cα.y·q.x − cα.x·q.y))`

Zonas pela profundidade dentro da borda, `h = −d − w`:

| Zona | Condição | Camada | Cor | Opacidade |
|---|---|---|---|---|
| contorno | −w ≤ d ≤ 0 (**por dentro** da borda de acerto) | z 5, malha de borda | `#0D0E14` | `α_c = cov(d, aa) − cov(d + w, aa)` |
| anel interno | 0 ≤ h ≤ a | z −5 | `#FF3DAE` | 1 desde p = 0 *(a confirmar pelo art-director)* |
| núcleo, base | h > a, fora da frente | z −5 | `#FFD3EE` | `opacidade_base_telegrafo` (0,25) *(a confirmar pelo art-director)* |
| núcleo, crescido | h > a, dentro da frente (g ≤ 0) | z −5 | `#FFD3EE` | 1 |

Opacidade do núcleo: `α_n = cov(a − h, aa) × mix(opacidade_base, 1, cov(g, aa))`

Opacidade do anel: `α_a = cov(d + w, aa) − cov(d + w + a, aa)` (a faixa
0 ≤ h ≤ a; como `cov(a − h) = cov(d + w + a)`, anel e núcleo se completam sem
fresta). Na passada do preenchimento, o alfa é `α_f = α_a + α_n` e a cor é
`(α_a·C_anel + α_n·C_núcleo) / max(α_f, 1e−5)`, com `C_anel` = `#FF3DAE` e
`C_núcleo` = `#FFD3EE`.

Frente de crescimento, na área do núcleo (`h' = h − a`, `D'' = D − w − a`):

- `borda_ao_centro`: `g = h' − p·D''`
- `centro_a_borda`: `g = p · d_n(q_c/p)`, a área do núcleo escalada por p em
  torno da âncora, com `q_c` relativo a ela (círculo: centro, `q_c = q`;
  retângulo: centro geométrico, `q_c = q − (L/2, 0)`; setor: o ápice
  **do núcleo recuado**, a (w + a)/sin α do ápice da forma ao longo do eixo, `q_c = q − ((w + a)/sin α, 0)`; escalar em torno do ápice da forma atrasaria o início do crescimento até p ≈ 0,07). No anel, `g = (1 − p)·D'' − h'`.
- **p = 0:** o shader trata p = 0 antes de tudo, nos três modos e no anel:
  `cov(g) = 0`, só a base. Isso evita a divisão por p e a linha de meia
  cobertura que `g = 0` deixaria na linha média do anel (h' = D'') e na borda
  do anel em `borda_ao_centro` (h' = 0).
- **p ≥ 1** (espelho do p = 0; o shader trata p ≥ 1 antes de tudo, nos três modos e no anel): `cov(g) = 1` no núcleo inteiro, sem avaliar `g`. Sem isso, `g = 0` no eixo medial do núcleo (o centro do círculo, o eixo do retângulo e do setor, a linha média do anel) deixaria uma linha de meia cobertura (`α_n` = 0,625). Em `centro_a_borda` a mesma meia cobertura apareceria na fronteira anel/núcleo (α_a 0,5 + α_n 0,31 = 0,81). Com `cov(g) = 1`, `α_n = cov(a − h)` é o complemento exato de `α_a`, e `α_a + α_n = 1` sem fresta.
- `ao_longo_do_eixo` (só retângulo): `g = (q.x − w − a) − p·(L − 2w − 2a)`, a
  partir do lado do atacante. No setor é sinônimo de `centro_a_borda` (radial
  a partir do ápice).

Raio interno máximo D: círculo r; anel t_a; retângulo min(L, W)/2; setor
R·sin α/(1 + sin α) se α ≤ 90°, senão R/2. D é calculado na CPU e passado como
uniform.

Estados (R5):

- **`disparo`:** anel e núcleo em osso `#E6DFCF` por
  `passos(duracao_flash_telegrafo_s)` (2) passos vivos, depois some. Se o F6
  negar o flash, anel e núcleo ficam como estão (`#FF3DAE` e `#FFD3EE`; o
  núcleo já está a 100% em p = 1) pelos mesmos passos e somem.
- **`quebrado`:** rachadura em 2 passos vivos e some.
- **`cancelado`:** opacidade das duas passadas 1 → 0,5 → 0 em 2 passos vivos.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| origem, θ | vec2, float | — | injected | posição (centro; ápice; meio do lado do atacante) e rotação (Telégrafos) |
| r, r_int, r_ext, L, W, R | float | > 0 (VV8, VV9) | injected | dimensões em unidades de canvas, iguais às do teste de acerto (Combate R13), com a mesma âncora |
| α | float | (0, π) | injected | meio-ângulo do setor |
| p | float | 0–1 (fora disso: clamp + aviso VV10) | injected | progresso no relógio vivo (Telégrafos) |
| w | float | 3,5–8 | data file | `contorno_telegrafo_px` (4) ou `contorno_telegrafo_alto_px` (6) |
| a | float | 0–12 | data file | `largura_anel_px` (6) *(a confirmar pelo art-director)* |
| opacidade_base_telegrafo | float | 0–0,4 | data file | 0,25 *(a confirmar pelo art-director)* |
| D, D'' | float | D'' > 0 | calculated | raio interno máximo; profundidade útil do núcleo |
| aa | float | ≈ 1/(s_tela × z) | calculated | suavização de 1 px físico |
| α_c, α_n | float | 0–1 | calculated | coberturas das duas passadas |

**Output Range:** coberturas em [0, 1].

- A borda externa da tinta coincide com a borda de acerto.
- A frente é medida na área do núcleo, não na forma inteira, então o
  preenchimento completa em p = 1 nos três modos (o p ≥ 1 é tratado à parte, sem a linha de meia cobertura do eixo medial). Sem a medida na área do núcleo, o
  círculo r = 100 "fecharia" em p ≈ 0,90.
- Base em p = 0 sobre o chão `#343C4A` (mistura no codificado): L* ≈ 42. Ela
  mostra a área inteira desde o primeiro passo e fica ~47 L* abaixo do núcleo
  crescido (88,9), o que mantém a leitura do crescimento.
- O quad do preenchimento cobre a caixa da forma mais 2 unidades de margem de
  suavização (pior caso: 720p, aa = 1,5). O contorno é uma **malha de borda**:
  no círculo, o anel de r − w − 2 a r + 2; no anel, no setor e no retângulo, a
  faixa equivalente ao longo das bordas (malha gerada na CPU; ADR). No círculo
  r = 120 ela cobre π(122² − 114²) = 5.931,3 unidades², contra 59.536 do quad
  cheio (−90%).
- Degenerações: VV8–VV10.

**Example:** círculo r = 120, w = 4, a = 6, 1440p (aa = 0,75).

- Em |q| = 118, d = −2: α_c = 1 − cov(2) = 1 − 0 = 1.
- Em |q| = 113: h = 3 → anel.
- `borda_ao_centro` com p = 0,5: D'' = 110; a frente fica em h' = 55 → núcleo
  crescido em 55 ≤ |q| < 110, base em |q| < 55.
- `centro_a_borda` com p = 0,5: crescido em |q| ≤ 55.
- Setor R = 200, α = 45°: D = 200 × 0,7071/1,7071 = 82,8.
- Retângulo 400×80, `ao_longo_do_eixo`, p = 0,25: o núcleo cresce de q.x > 10 a
  q.x = 10 + 0,25 × 380 = 105 (95 unidades a partir do atacante).

### F5. Bênção

The blessing_desaturation formula is defined as:

`g = lin2srgb(Y(c))` ;
`c' = mix(vec3(g), c, saturacao_bencao) × valor_bencao` (o `mix` e o `×` no
codificado)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| c | vec3 | 0–1 | calculated | cor depois do F1/F2 (codificado) |
| Y(c) | float | 0–1 | calculated | luminância Rec.709 **em linear** |
| g | float | 0–1 | calculated | cinza codificado com a mesma luminância de c |
| saturacao_bencao | float | 0,15–0,25 | data file | `VisualTuning` (0,20; Art Bible §4.4) |
| valor_bencao | float | 0,55–0,70 | data file | `VisualTuning` (0,60; "−40% de valor", o V do HSV como o artista lê no Krita) |
| c' | vec3 | 0–valor_bencao | calculated | cor da Bênção |

**Output Range:** 0 a `valor_bencao` por canal.

- A luma em linear preserva a escada de L* no cinza, coerente com a checagem em
  tons de cinza do §4.7. A luma Rec.709 no codificado escureceria cores
  saturadas: o magenta `#E0259C` (L* 51,3) viraria cinza de L* 36,3; em linear,
  fica em 51,3.
- O `× v` fica no codificado porque é assim que o "−40%" do Art Bible é lido.
  Em linear, o mesmo 0,6 tiraria só ~6 L* do chão.
- A Bênção é tela estática; as duas conversões não pesam.

**Example:** chão `#343C4A`: Y = 0,04457 → g = 0,2336. mix com 0,2 →
(0,2277; 0,2340; 0,2449); × 0,6 → (0,1366; 0,1404; 0,1470) ≈ `#232425`,
**L* 14,1** (era 25,1). Fora de combate, sem regra de faixa.

### F6. Limitador de flashes

The flash_limiter formula is defined as:

`aceito(e, t) = N_flash(t − 1 s, t] < limite_flashes_s ∧ (e ∉ {impacto_recusa, impacto_chefe} ∨ N_imp(e)(t − 1 s, t] < limite_impacto_s)`
`N_imp(impacto_recusa)` conta todos os impactos aceitos; `N_imp(impacto_chefe)`
conta só os do chefe (preempção: a recusa não bloqueia o chefe)
Disparo de telégrafo só vira pedido se, no mesmo passo vivo,
`Σ A_disparo × z_camera² ≥ limiar_area_flash × 1920 × 1080`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| t | int (µs) | ≥ 0 | injected | relógio **real monotônico** (não `t_apres`), injetado para teste |
| N_flash, N_imp | int | 0–4 (o passe obrigatório pode levar o N_flash a 4; F6, R7) | calculated | flashes **aceitos** (ou passes obrigatórios contabilizados) com início na janela semiaberta (t − 1 s, t] |
| limite_flashes_s | int | 3 (teto fixo) | constant | Art Bible §7.7; acessibilidade, não é botão de balanceamento |
| limite_impacto_s | int | 1 (teto fixo) | constant | idem |
| e | enum | impacto_recusa, impacto_chefe, passe_tela, disparos_telegrafo | injected | fonte do pedido; com Reduzir flashes, os dois impactos saem em `reduzido` e contam igual |
| A_disparo | float | ≥ 0 | calculated | área da forma inteira (πr² no círculo) de cada telégrafo que entra em `disparo` neste passo vivo, em unidades de canvas² |
| limiar_area_flash | float | ≤ 0,11 | constant | fração da tela 1920×1080 (critério de área do WCAG 2.3.1): 228.096 unidades² |

**Output Range:** booleano. Regras:

- conta o início de cada flash: um flash de vários quadros conta 1, e todos os
  disparos acima do limiar no mesmo passo contam juntos como 1;
- pedido negado é **descartado, não enfileirado** (a fila juntaria flashes
  depois e atrasaria a resposta);
- o evento de jogo segue igual: hitstop, dano e a morte do chefe acontecem; só
  o efeito de tela some;
- telégrafo negado entra em disparo sem o osso (F4). O telégrafo nunca é
  cortado (V15);
- **passe de tela obrigatório** (transição de câmara, morte; decisão do usuário, 2026-11-10): nunca é negado. Conta no `N_flash` (pode levar a janela ao limite para os pedidos seguintes). Se, ao pedir, a janela já tem `limite_flashes_s` flashes, o passe sai como fade de `duracao_fade_s` em vez do wipe de tinta, e a câmara troca com a tela coberta pelo fade;
- no mesmo passo, a ordem é chefe > recusa > passes > telégrafos (Combate AC1);
- **preempção do chefe** (decisão do usuário, 2026-11-10): uma recusa aceita na
  janela não bloqueia o impacto do chefe. Se a recusa ainda está na tela, ela é
  cortada e o chefe começa (é um início novo e conta no `N_flash`). O limite de
  3 flashes/s vale sempre: se ele negar, o chefe fica sem impact frame;
- o impact frame reduzido (R11) é uma mudança de ~10 L* na tela inteira e
  **continua contando**;
- o flash de acerto em sprite de inimigo não conta (Combate AC1);
- por que só a área: osso `#E6DFCF` (L* 89,0) e núcleo (88,9) têm o mesmo L*.
  No disparo, o salto de luminância vem do anel (L* 59,6 → 89), que é estreito.

**Example:**

- Aceitos em 0,10 s (impacto de recusa), 0,40 s e 0,70 s. Pedido em 0,95 s: a janela
  (−0,05; 0,95] tem 3 → negado.
- Recusa em 1,05 s: há impacto em (0,05; 1,05] → negada.
- Recusa em 1,10 s: (0,10; 1,10] tem 2 flashes e nenhum impacto → aceita.
- Preempção: recusa aceita em 2,00 s, e nenhum outro flash depois de 1,30 s;
  chefe em 2,30 s. A janela (1,30; 2,30] tem 1 impacto, de recusa:
  `N_imp(chefe)` = 0 e `N_flash` = 1 → aceito, e a recusa, se ainda está na
  tela, é cortada. Um segundo chefe em 2,60 s seria negado (`N_imp(chefe)` = 1).
- Disparo de um círculo r = 120: 45.239 unidades² (2,18% da tela) → não é
  pedido. Seis disparos iguais no mesmo passo: 271.434 (13,1%) → um pedido.

### F7. Fase do tracejado

The dash_phase formula is defined as:

`P = traco_tracejado_px + intervalo_tracejado_px` ;
`n = max(1, round(perimetro / P))` ; `P' = perimetro / n` ; `r_t = traco_tracejado_px / P`
`φ = fract(s / P')` ; `δ = |fract(φ − r_t/2 + 0,5) − 0,5|` (distância de fase ao
meio do traço, periódica)
`on = cov(δ − r_t/2, aa_φ)`: as **duas** bordas do traço ficam suavizadas, sem
salto em φ = 0
`aa_φ = aa × |∇s| / P'`, com a derivada **analítica** de s: `|∇s|` = r/|q| no
círculo e no anel, 1 no retângulo, R_ref/|q_corpo| na silhueta. **Não usar
`fwidth(s)`**: s salta de perímetro para 0 na costura (θ = ±π; o canto inicial
do retângulo), e o `fwidth` explode ali, o que deixa uma coluna de pixels a ~50%

s por tipo de contorno:

- círculo e anel: `s = r·(atan2(q.y, q.x) + π)`;
- retângulo: comprimento de arco a partir de um canto;
- silhueta (CanvasGroup, pixel físico): `s = R_ref·(atan2 em torno do centro do
  corpo + π)`, com `R_ref` = metade da altura do corpo, e as larguras ×
  `escala_traco`.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| traco_tracejado_px | float | 4–16 | data file | 8 |
| intervalo_tracejado_px | float | 3–12, e ≥ 2 × largura | data file | 6 |
| perimetro | float | > 0 | calculated | 2πr; 2(L + W); 2π·R_ref na silhueta |
| n | int | ≥ 1 | calculated | número inteiro de traços, para não haver costura em θ = ±π |
| P' | float | ≈ P | calculated | período ajustado |
| s, φ | float | s ≥ 0; φ ∈ [0, 1) | calculated | posição ao longo do contorno; fase |
| r_t, δ | float | r_t ≈ 0,571; δ ∈ [0; 0,5] | calculated | razão traço/período; distância de fase ao meio do traço |

**Output Range:** `on` ∈ [0, 1].

- A razão traço/período fica fixa (8/14 = 0,571); só o período estica ou
  encolhe até ±P/2 por volta.
- Na silhueta, a fase é **angular e estática**: não anda e não pisca (R6). O
  comprimento do traço varia com a distância ao centro, porque um contorno
  arbitrário não tem comprimento de arco no shader.
- Perímetro < 3P (círculo de r < 6,7 unidades): aviso VV7.

**Example:** anel do Selo, r = 150: perímetro 942,5; n = round(67,3) = 67;
P' = 14,07 (traço 8,04, intervalo 6,03). Silhueta de 90 unidades de altura:
R_ref = 45, n = round(282,7/14) = 20.

### F8. Relógios

The presentation_clocks formula is defined as:

`t_vivo = n_vivos / 60` (n_vivos é int64 na CPU; a divisão é em double) ;
`t_apres += min(dt_real, dt_max_apres)` só nos estados em que corre (tabela de
relógios)
Zero: `n_vivos ← 0`, `t_apres ← 0` no quadro em que a transição de câmara chega
à metade (tela toda em tinta)
Erro ao enviar como float32: `ULP(T) = 2^(floor(log2 T) − 23)` ; erro de
arredondamento ≤ ULP/2

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| n_vivos | int | ≥ 0 | calculated | passos vivos desde o último zero (orquestrador, Combate R1) |
| dt_real | float | ≥ 0 | injected | delta real do quadro, **não escalado** por `Engine.time_scale` |
| dt_max_apres | float | 0,05–0,25 | data file | 0,1 s: um engasgo não pula o wipe de 0,4 s inteiro |
| T | float | 0–∞ | calculated | valor do relógio |
| ULP | float | — | calculated | resolução do float32 em T |

**Output Range:**

- ULP em 1800 s = 2^−13 s (erro ≤ 0,061 ms); em 3600 s = 2^−12 s (erro
  ≤ 0,122 ms). A ULP passa de 1 ms a partir de **16.384 s (4,55 h)** numa câmara só, e o erro (ULP/2) a partir de 32.768 s.
- Na CPU, o acumulador é `float` do GDScript (double): não há erro acumulado.
- Com o zero por câmara, T fica limitado à duração de uma câmara, mesmo com o
  jogador ausente. O `p` dos telégrafos vem por uniform próprio e não depende
  do zero.
- **Não usar `fmod`:** quebra a fase de efeitos cujo período não divide o
  módulo.
- Aviso de debug VV16 se T > 4096 s.
- Na metade da transição não há telégrafo nem VFX vivo, e a tela está coberta:
  o salto de fase não é visível.
- O wipe e o passe de morte não leem os relógios: usam `progresso_wipe` (R7),
  avançado por `min(dt_real, dt_max_apres)`.

**Example:** n_vivos = 216.001 → t_vivo = 3600,016667; em float32,
3600,016602 (erro de 0,065 ms). Engasgo de 0,5 s no meio do wipe: `t_apres`
avança 0,1 s, e o wipe segue de onde estava.

### F9. Oclusão

The occlusion_fade formula is defined as:

`dentro(R, P) = x_min ≤ P.x < x_max ∧ y_min ≤ P.y < y_max`
`entra = (dentro(R_oc, P_pe) ∨ dentro(R_oc, P_corpo)) ∧ y_prop > y_jogador`
`sai = ¬(dentro(R_oc ⊕ m, P_pe) ∨ dentro(R_oc ⊕ m, P_corpo)) ∨ y_prop ≤ y_jogador`
(`R_oc ⊕ m` = retângulo expandido em m por lado)
`cobre ← cobre ? ¬sai : entra` ; `α_alvo = cobre ? opacidade_oclusao : 1`
Por passo de apresentação: `α ← move_toward(α, α_alvo, (1 − opacidade_oclusao) / n_oc)`, com `n_oc = passos(duracao_transicao_oclusao_s)`
(contínuo: `Δα = (1 − opacidade_oclusao) × dt_apres × 60 / n_oc`)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| R_oc | rect | área > 0 | data file | retângulo de oclusão **autorado** no prop marcado `oclusor` (Câmaras); não é o retângulo da textura |
| P_pe, P_corpo | vec2 | — | injected | pé e centro do corpo do jogador (R13) |
| y_prop, y_jogador | float | — | calculated | chaves do y-sort |
| m | float | 0–16 | data file | `margem_histerese_oclusao_px` (8) |
| opacidade_oclusao | float | 0,3–0,6 | data file | 0,4 |
| duracao_transicao_oclusao_s | float | 0,017–0,2 | data file | 0,1 s (n_oc = 6 passos de apresentação) |
| cobre | bool | — | calculated | estado com histerese |
| α | float | opacidade_oclusao–1 | calculated | opacidade do prop |

**Output Range:** α ∈ [opacidade_oclusao; 1], com velocidade constante (0,1
por passo com os padrões).

- A reversão no meio continua do α atual, sem salto.
- A histerese impede a tremulação quando o jogador anda na borda de R_oc.
- Prop de várias partes precisa de CanvasGroup ou de um sprite só; senão as
  sobreposições internas aparecem.
- O preenchimento do telégrafo pode ficar sob um prop não oclusor; o contorno
  (z 5) nunca fica.

**Example:** R_oc x 800–960, y 300–520; pé (870, 500), corpo (870, 455);
y_prop 520 > 500 → cobre. α: 1 → 0,9 → … → 0,4 em 6 passos (0,1 s). O pé vai a
x = 964: ainda dentro de R_oc ⊕ 8 → continua coberto. Em x = 970, sai; com
α = 0,7, volta a 1 em 3 passos.

### F10. Orçamento

The budget_check formula is defined as:

`Σ grupos = 40 + 54 + 200 + 64 + 6 + 80 = 444` ; `reserva = 500 − 444 = 56`
Sombras e telégrafos: `6 (sombras, em até 6 draw calls com lote) + 24 × 2 (duas passadas: quad do preenchimento + malha de borda do contorno) = 54`
Medição por diferença: `D_g = D_total − D_total(cena sem o grupo g)`, cada um
contado numa captura (PIX/RenderDoc) do quadro de pior caso
Overdraw: `OD = Σ_i A_i / (W × H)` (A_i = área de tela do quad ou da malha i, **com o
transparente**); fatias: VFX ≤ 0,5; sombras e telégrafos ≤ 0,4 na média e ≤ 0,8
no pico
Memória: `bytes = W × H × bpp × (4/3 se mipmaps)` (Lossless = RGBA8, 4 B/px na
VRAM; BC7 = 1 B/px)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| grupos | int | ver R9 | data file | tetos de draw calls (R9) |
| D_total | int | ≥ 0 | calculated | chamadas `Draw*` nos passes de canvas do quadro capturado |
| A_i | float | ≥ 0 | calculated | área do quad na tela, inteira (o fragmento transparente também é sombreado) |
| OD | float | ≥ 0 | calculated | telas equivalentes (≤ 3,5 na média do combate; ≤ 5 no pico de chefe; VFX ≤ 0,5; sombras e telégrafos ≤ 0,4 / 0,8) |
| bytes | int | — | calculated | memória residente da textura |

**Output Range:**

- A soma é verificável sem captura (VV12).
- A captura vale para a cena de estresse com todos os grupos no máximo: 24
  telégrafos, 40 inimigos × 3 (o teto do §8.6; o MVP tem até 9 por onda, Combate V15), 60 props, 24 emissores, 40 flipbooks, 3 imagens
  residuais. O lote só pode reduzir a contagem; o orçamento é sem lote, exceto
  nas sombras, cujo teto de 6 pressupõe lote numa textura única.
- Os tetos de memória do §8.6 somam **504 MiB** no pior caso de residência (o
  chefe troca o elenco: max(128, 64)). Ficam acima do alerta de 448 e a 8 MiB
  do teto (VV13).

**Example:** página de atlas 4096×2048 Lossless com mipmaps:
4096 × 2048 × 4 × 4/3 = 42,7 MiB. LUT: 1024 × 32 × 4 = 128 KiB. Overdraw de uma
câmara (revisão 1): fundo e névoa distante, recortados à faixa acima do chão,
0,4 + parede 0,3 + chão 0,8 + sombras e telégrafos 0,4 + 3 faixas de névoa 0,3
+ feixes 0,2 + y-sort 0,5 + VFX 0,3 + primeiro plano 0,1 + UI 0,2 = 3,5 (no teto
da média). Telégrafos: 8 círculos r = 120, cada um com quad de 59.536 e malha de
5.931,3 unidades², somam 523.738,6 = 0,25 tela; 24 somam 0,76 (pico ≤ 0,8). Com o
contorno em quad cheio, os 24 dariam 1,38.

### Faixas seguras do `VisualTuning`

| Campo | Padrão | Faixa segura | O que quebra fora |
|---|---|---|---|
| `forca_grading_personagem` | 0,15 | 0–0,15 | acima de 0,15: o corpo afunda no matiz da região (Art Bible §4.4 é teto) |
| `saturacao_bencao` | 0,20 | 0,15–0,25 | acima: o mundo disputa com as cartas; abaixo: some a voz da região |
| `valor_bencao` | 0,60 | 0,55–0,70 | abaixo: o chão vai a L* < 12,6 e a câmara some; acima: as cartas perdem contraste |
| `passo_profundidade` | 0,03 | 0–0,05 | acima: chega ao piso na câmara 3; as diferenças entre câmaras ficam bruscas |
| `piso_profundidade` | 0,85 | k_min (F2)–1 | abaixo de k_min: o tom mais escuro do chão sai de L* 22 (VV3) |
| `opacidade_max_feixes` | 0,20 | 0–0,20 | acima: o feixe aditivo clareia a névoa até a faixa do chão |
| `ciclo_veio_s` | 2,0 | ≥ 2,0 | abaixo: lê como pulsação de telégrafo |
| `amplitude_veio` | 0,10 | 0–0,10 | acima: a base do veio tem de cair abaixo de ~41 L* para o pico ficar ≤ 45 (a VV15 mede o pico; base 45 com 10% dá 49,3) |
| `duracao_flash_telegrafo_s` | 0,033 (2 passos) | 0,033–0,05 (2–3 passos) | 1 passo (16,7 ms) não é percebido; ≥ 4 atrasa a leitura do disparo |
| `contorno_telegrafo_px` | 4 | 3,5–6 | ≤ 3: igual ao traço do herói; > 6: come a área útil (VV9) |
| `contorno_telegrafo_alto_px` | 6 | ≥ contorno, ≤ 8 | — |
| `largura_anel_px` *(a confirmar pelo art-director)* | 6 | 0–12 | acima: o anel domina e o núcleo crescido some em telégrafos pequenos |
| `opacidade_base_telegrafo` *(a confirmar pelo art-director)* | 0,25 | 0–0,4 | 0: a área só aparece pelo contorno em p = 0; acima de 0,4: a base (L* > 52,3 sobre o chão padrão) apaga o crescimento |
| `largura_tracejado_px` | 1,75 | 1,5–2,5 | ≥ 3: confunde com contorno; < 1,5: esmaece em 720p |
| `traco_tracejado_px` | 8 | 4–16 | — |
| `intervalo_tracejado_px` | 6 | 3–12 e ≥ 2 × largura | intervalo pequeno: lê como linha cheia (borda de telégrafo) |
| `contorno_silhueta_px` | 3 | 2–3,5 | ≥ 4 (o contorno do telégrafo): confunde com a borda de ameaça; < 2: some em 720p |
| `opacidade_oclusao` | 0,40 | 0,30–0,60 | abaixo: o prop some; acima: esconde o jogador |
| `duracao_transicao_oclusao_s` | 0,1 (6 passos) | 0,017–0,2 (1–12 passos) | 0: divisão por zero no F9 (VV11) |
| `margem_histerese_oclusao_px` | 8 | 0–16 | 0: tremula na borda; acima: o prop fica transparente longe do jogador |
| `duracao_wipe_s` | 0,4 | 0,2–0,6 | acima: atrasa o combate; abaixo: vira corte seco |
| `duracao_fade_s` | 0,3 | 0,1–0,3 | acima de 0,3: viola a R11 |
| `dt_max_apres` | 0,1 | 0,05–0,25 | abaixo: efeitos de apresentação ficam lentos em 20–30 qps; acima: engasgo pula o wipe |
| `teto_drawcalls_passes` | 6 | 2–6 | — |

Fora desta tabela: o parallax do primeiro plano (`CameraTuning`, Cena R11) e as
durações dos efeitos que o Combate dispara (flash de acerto, extra da inversão;
Combate V6, V10), que o Pipeline recebe no evento (R12).

Constantes de acessibilidade, que não são botão de balanceamento:
`limite_flashes_s` = 3; `limite_impacto_s` = 1; `limiar_area_flash` = 0,11
(só pode baixar).

### Validação do `VisualTuning`

Mesmo regime do Movimento: os **erros** vão para a tela de erros do catálogo e
a run não começa; os **avisos** ficam só no registro de validação, e a run
começa.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| VV1 | erro | `forca_grading_personagem` ∉ [0; 0,15] | teto do Art Bible §4.4 |
| VV2 | erro | `piso_profundidade` ∉ (0, 1] ou `passo_profundidade` < 0 | k fora de (0, 1] |
| VV3 | erro, cruzada com Run e regiões | para cada LUT de região: L* em linear de `piso_profundidade × Y(lut(t))` < 22, para o tom t mais escuro do chão; **aviso** se < 22,5 (o chão padrão dá 22,96) | R3: o chão em 22–38 em toda profundidade. A CPU lê a LUT, aplica o F2 e calcula o L*. **Aviso** também se o tom mais claro do chão, em p = 0, passar de L* 38 (teto da faixa 22–38) |
| VV4 | erro | LUT ≠ 1024×32, com mipmaps, com repeat ou com compressão com perda; (o teste da LUT identidade, > 1/255, é critério de aceite com uma LUT sintética, não validação das LUTs de região) | quebra o meio texel, a mistura de fatias ou a convenção de eixos (F1) |
| VV5 | erro | `contorno_telegrafo_px` ≤ 3 (traço do herói) ou `contorno_telegrafo_alto_px` < `contorno_telegrafo_px`; ou `contorno_silhueta_px` ≥ `contorno_telegrafo_px` | perde a hierarquia de traço |
| VV6 | erro | `largura_tracejado_px` ≥ 3 | a ação do jogador lê como borda de ameaça |
| VV7 | aviso | `largura_tracejado_px` × 0,667 < 1,0; `intervalo_tracejado_px` < 2 × largura; ou perímetro < 3P | esmaece em 720p e no Deck, vira linha cheia ou fica com um traço só |
| VV8 | erro (em execução: aviso e o telégrafo não é desenhado) | r, L, W, R ≤ 0; `r_int` ≥ `r_ext`; α ∉ (0, π); `ao_longo_do_eixo` em círculo ou anel | SDF degenerada |
| VV9 | erro se D'' ≤ 0 (D ≤ w + a, o que inclui D ≤ w; a F4 exige D'' > 0); aviso se 0 < D'' < 8 (com w = 4 e a = 6: D < 18) | — | o contorno ou o anel engolem o núcleo; o crescimento não se lê |
| VV10 | aviso (em execução) | p ∉ [0, 1] → clamp; anel com `r_int` = 0 → use `circulo` | entrada fora do contrato |
| VV11 | erro | `duracao_transicao_oclusao_s` ≤ 0, `opacidade_oclusao` ∉ (0, 1) ou `R_oc` com área 0; **aviso** com `opacidade_oclusao` fora de [0,3; 0,6] | divisão por zero e leitura |
| VV12 | erro | Σ grupos > 500; **aviso** se reserva < 50 | R9 |
| VV13 | aviso | Σ tetos de memória no pior caso > 448 MiB (hoje 504) | alerta do §8.6 |
| VV14 | erro | `duracao_fade_s` > 0,3, `duracao_wipe_s` ≤ 0 ou `dt_max_apres` < 1/60 | R11 e R7; um dt_max abaixo de um quadro a 60 qps atrasaria a apresentação sempre |
| VV15 | erro | `ciclo_veio_s` < 2, `amplitude_veio` > 0,10, `opacidade_max_feixes` > 0,20 ou `limiar_area_flash` > 0,11; **aviso**, cruzada com regiões, se o L* do veio **depois da LUT, no pico da pulsação** (valor × (1 + `amplitude_veio`), no codificado) > 45 | Art Bible §4.4, §4.5 e §7.7 |
| VV16 | aviso de debug (em execução) | `t_vivo` ou `t_apres` > 4096 s | ULP de 0,49 ms; sinal de que o zero por câmara não rodou |
| VV17 | aviso | campo do `VisualTuning` com valor fora da faixa segura (tabela acima), quando nenhuma outra VV disparou para aquele campo nesta validação | Art Bible §4.4, §6.3 e §8.6 |

**Precedência:** VV8 suspende VV9 e VV10 do mesmo telégrafo (SDF degenerada
não é medida). O erro de uma VV suspende o aviso da mesma VV para o mesmo
campo.

## Edge Cases

> `technical-artist` e `systems-designer` não consultados nesta seção: modo Lean.
> Os limites que eles levantaram em Detailed Design e Formulas estão incorporados.

**Grading e profundidade**

- **Se a LUT da região faltar ou falhar na carga:** a validação do catálogo
  recusa (VV4) e a run não começa. Não há LUT padrão escondida no código.
- **Se a LUT global não compilar em canvas_item ou no Shader Baker** (E2): entra
  o plano B da R2 (uniform comum, trocado por script). Os critérios de aceite
  valem para os dois caminhos.
- **Se a região mudar no meio de uma câmara** (não acontece no MVP): a LUT só
  troca sob a transição de tinta (R7); sem transição, a LUT antiga fica até a
  próxima.
- **Se a profundidade passar de 5:** o multiplicador fica no piso (0,85; F2). Na
  primeira câmara (p = 0), nada escurece.
- **Se um prop ou personagem estiver com um shader sem marca de família:**
  aparece sem grading, e o validador de debug o lista (R1). Na build de release, nada avisa:
  o critério de aceite pega na captura.

**Telégrafo**

- **Se dois telégrafos se sobrepuserem:** os dois preenchimentos aparecem (o
  mais recente por cima) e os dois contornos ficam visíveis em z 5. A soma dos
  núcleos não passa do L* do núcleo (mesma cor).
- **Se um telégrafo ficar sob um prop alto que não é `oclusor`:** o
  preenchimento pode ficar coberto, mas o contorno (z 5, acima do y-sort) nunca
  fica (F9).
- **Se o telégrafo encostar na borda da câmara:** é desenhado inteiro (o quad
  cobre a forma mais a margem de suavização); a névoa nunca cobre o chão, então
  não o cobre (R4).
- **Se o progresso `p` chegar fora de [0, 1]:** é preso ao intervalo e vai um
  aviso de debug (VV10).
- **Se forem pedidos mais de 24 telégrafos ao mesmo tempo:** acima do teto da
  R9, o Pipeline desenha todos assim mesmo (telégrafo nunca é cortado, Combate
  V15) e o orçamento estoura; o aviso de debug aponta o dono (GDD de IA ou de
  Telégrafos), que tem de respeitar o teto.
- **Se o limitador negar o flash de disparo:** núcleo e anel ficam como estão
  pelos passos do flash, sem osso, e somem (F6). O ataque sai igual.
- **Se o telégrafo for quebrado e o dono morrer no mesmo passo:** vale
  `quebrado` (a ameaça sumiu por ação do jogador); `cancelado` é só para quando o
  dono some sem o "Quebrou!". O `cancelado` some em 1 → 0,5 → 0.

**Traço e corpo**

- **Se o jogador for atingido durante a invulnerabilidade da esquiva:** não há
  dano, então não há inversão nem contorno pós-dano; continuam as imagens
  residuais (Movimento V3).
- **Se a recusa de morte acontecer:** no sprite do jogador o impact frame da
  recusa (Combate V11, 18 passos de apresentação) vence a inversão do golpe
  recebido enquanto durar o `modo_impacto`; depois voltam os 4 passos vivos que restam da
  inversão (Combate V10, Feedback R12) e, no passo seguinte ao fim dela, o
  contorno tracejado pelo tempo da invulnerabilidade da recusa, nessa ordem.
- **Se o jogador estiver coberto por dois oclusores:** os dois ficam a 40%.
- **Se o jogador passar rápido por um oclusor** (esquiva): a transição de 6
  passos de apresentação pode não completar; ela volta do valor em que estava,
  sem salto (F9).
- **Se o zoom da câmera subir (impacto):** os traços em unidades de canvas
  engrossam junto (F3; decisão do usuário); o contorno do CanvasGroup usa
  `escala_traco`, que já inclui o zoom.
- **Se um quadro de inimigo não tiver a margem transparente ≥
  `contorno_silhueta_px`:** o contorno do impact frame `recusa` é cortado na
  borda do quadro. A ferramenta de recorte avisa (Art Bible §8.6; OQ12).

**Momentos de tela e relógios**

- **Se um impact frame for pedido durante a transição de câmara ou a Bênção:**
  vale a prioridade dos modos (Transição > Morte > Bênção > Impacto > Normal); o
  impact frame é descartado, e o evento de jogo segue. Um impacto já ativo é cortado quando a Transição ou a Morte entram; a Bênção espera o impacto terminar para abrir.
- **Se o chefe morrer e a recusa acontecer no mesmo segundo:** vence o chefe.
  No mesmo passo, a recusa fica sem impact frame. Se a recusa veio antes na
  janela de 1 s, o impact frame do chefe a substitui (preempção; se ela ainda
  está na tela, é cortada), desde que o limite de 3 flashes/s deixe. Se a
  recusa vier depois do chefe na janela, fica sem impact frame (R7, F6).
- **Se o jogo pausar no meio de um impact frame:** `t_apres` para, e o impact
  frame retoma de onde estava ao despausar.
- **Se a Bênção abrir com números ou letreiros vivos no mundo:** eles somem no
  quadro em que ela abre, sem fade. Congelados pelo `t_apres` parado, ficariam
  sobre o mundo dessaturado, e o §4.4 reserva dourado e magenta às cartas. A
  Bênção só abre com a câmara limpa, sem telégrafo vivo (Run e regiões).
- **Se os relógios zerarem no meio do wipe:** o wipe segue pelo
  `progresso_wipe` (R7), que não lê os relógios.
- **Se a janela perder o foco** (Input pausa): igual à pausa.
- **Se um quadro demorar muito** (engasgo de carga): `t_apres` avança no máximo
  `dt_max_apres` (0,1 s) naquele quadro, e a transição de tinta não é pulada
  (F8).
- **Se uma run passar de 4 horas:** os relógios voltam a 0 a cada transição de
  câmara (F8); o aviso de debug VV16 aparece se algum passar de 4096 s.

**Configuração e plataforma**

- **Se a janela for menor que 1920×1080** (720p, Steam Deck): os traços ficam
  mais finos (F3); o tracejado de 1,75 px vira 1,17 px físicos no Deck e pode
  esmaecer; sem aviso no padrão (o VV7 não dispara com 1,75).
- **Se o monitor for HDR:** a saída HDR fica desligada (R10); a imagem é a mesma
  do SDR.
- **Se o driver não for D3D12** (Vulkan para captura): o resultado tem de ser
  igual; diferença visível é defeito (E2).
- **Se uma opção de acessibilidade mudar no meio da run:** vale a partir do
  quadro seguinte; nada é recalculado para trás.

**Conflitos com outros GDDs e o Art Bible:**

- **Art Bible §5.5** ("inversão de 2 quadros") × Combate V10: vale o Combate
  (hitstop + 4 passos; decisão do usuário), com a inversão da silhueta inteira
  no CanvasGroup (R6). Emenda pendente no Art Bible.
- **Art Bible §6.3 e §8.6** (telégrafo acima × abaixo dos personagens; orçamento
  de 30 para sombras e telégrafos, reserva ≥ 80): vale a R5 e a R9 (duas
  passadas, 54 e reserva ≥ 56; decisões do usuário). Emendas pendentes, com a
  assinatura do art-director.
- **Art Bible §8.6** (impact frame como passe de tela): vale a R7 (modo global
  nos materiais; decisão do usuário).
- **Art Bible §8.6** (memória: os tetos somam 504 MiB, acima do alerta de 448):
  aviso VV13; o art-director decide se reduz algum grupo.
- **Art Bible §2.9 e Combate V12** (impact frame do chefe "em osso"; duração em
  "12 quadros de render") × R7: o aspecto segue o §2.9 (`modo_impacto` =
  `chefe`); a duração vale em passos de apresentação (R7). Emenda feita no Combate em
  2026-11-10 (`impact_chefe_s`, R15; OQ9 fechada).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Cena 3/4 e câmera | Forte | camadas e z (R4), y-sort (R5), viewport e stretch (R1), câmera e zoom (R7, R8), troca de câmara (R10), parallax do primeiro plano (`CameraTuning`, R11) | não há onde desenhar |
| Conteúdo orientado a dados | Forte | `VisualTuning`, LUTs e máscaras como recursos, tela de erros para VV1–VV17 | números no código, o que a regra do projeto proíbe |
| Combate núcleo | Suave, **por contrato** | pedidos de impact frame, estados do jogador (atingido, invulnerável, recusa), estado do orquestrador (hitstop) para os relógios, durações do flash de acerto, da inversão e do impact frame | os efeitos de corpo e de tela não disparam; o resto funciona |
| Movimento e esquiva | Suave | posição e direção da esquiva (imagens residuais) | sem imagens residuais |
| Run e regiões | Suave, **por contrato** | região atual (LUT, cores) e profundidade da câmara | nenhuma câmara começa: não há LUT padrão (Edge Cases); os testes usam dublê |
| Câmaras e ondas | Suave, **por contrato** | props marcados como `oclusor` | sem oclusão |
| Acessibilidade e opções | Suave, **por contrato** | Reduzir flashes, Redução de movimento, intensidade do telégrafo | valores padrão (tudo ligado no normal) |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Telégrafos | Forte | a primitiva de telégrafo (formas, estados, duas passadas, cores, contorno) |
| Feedback de combate (VFX) | Forte | materiais, tracejado, relógios, limitador, orçamento de VFX |
| Combate núcleo | Suave | relógios, `modo_impacto`, inversão, contorno de invulnerabilidade, flash de acerto (Combate OQ4 respondida pela R6 e pela R8) |
| Movimento e esquiva | Suave | material das imagens residuais |
| HUD / Tela de bênção / Menus | Suave | material sem grading e sem névoa; dessaturação da Bênção |
| Chefes (fatia vertical) | Suave | impact frame do abate, luz (≤ 2 PointLight2D), oclusão por chefe (a decidir no GDD de Chefes) |
| Acessibilidade e opções | Suave | o lado de render das opções (R11) |

**Bidirecionalidade:**

- A Cena cita o Pipeline (OQ1, OQ2, OQ6, R10): a OQ1 (camada do telégrafo) fica
  respondida pela R5 (duas passadas; contorno em z 5) e a OQ6 pela R4
  (primeiro plano 1,15, valor no `CameraTuning`; fundo e névoa distante 1,0). A OQ2 (oclusão por chefe)
  segue com o GDD de Chefes. A camada nova `contorno de telégrafo` (z 5) precisa
  entrar na tabela da R4 da Cena.
- O Combate cita os relógios e a OQ4 (tracejado no rig, `speed_scale` dos
  emissores): respondidos pela R6 e pela R8, com o comportamento NÃO VERIFICADO
  até o E3 e o E5. O Combate **não lista** "Pipeline visual" em Dependencies
  (OQ9).
- O Conteúdo não lista o `VisualTuning` na tabela de `*Tuning` da R1, nem o
  Pipeline em Interactions e Dependencies (OQ10).
- O Movimento (V3) usa o material de imagem residual da R6.
- Telégrafos, VFX, Run, Câmaras e Acessibilidade ainda não existem; cada um, ao
  ser escrito, deve listar "Pipeline visual" em Dependencies e honrar os
  contratos acima.
- **Índice:** a linha 6 lista só "Cena 3/4 e câmera"; faltam Conteúdo (forte) e
  Combate, Movimento, Run e Câmaras (suaves, por contrato).

## Visual/Audio Requirements

O próprio sistema é o requisito visual: as regras R1–R11 e o Art Bible (§1,
§4, §6.3, §7.7, §7.9, §8.6) são a especificação. Este GDD não cria arte nova.
Ele define como a arte autorada pelo Art Bible é desenhada.

- **Provas visuais** que acompanham cada mudança no Pipeline: capturas da
  cena de referência (uma câmara do Limiar com jogador, 3 inimigos, 2
  telégrafos crescendo e um prop oclusor) em 1080p, 1440p e 4K, e nos 3
  simuladores de daltonismo e em cinza (Art Bible §4.7). As capturas ficam em
  `production/qa/evidence/`.
- **Áudio:** nenhum. O Pipeline não emite som.

> 📌 **Asset Spec** — este GDD define materiais e a primitiva do telégrafo, não
> assets. As LUTs das regiões e as máscaras de névoa entram no `/asset-spec` da
> região (Run e regiões).

## Game Feel

- **Legibilidade antes de tudo:** em qualquer quadro de combate, o núcleo do
  telégrafo é a coisa mais clara do mundo (L* ≈ 89 contra o chão de 23–25), e o
  contorno nunca fica coberto. A ação do jogador nunca usa a gramática do aviso.
- **O congelamento se sente pelo que continua:** no hitstop, o mundo para
  (relógio vivo), mas a câmera, a estrela de impacto e o número se mexem
  (relógio de apresentação). Por isso o golpe parece pesado e não travado
  (Combate V1).
- **Profundidade sem perder leitura:** cada câmara escurece um pouco (−3%), e o
  jogador sente que desce sem o chão sair da faixa de leitura.
- **Desempenho:** o orçamento existe para manter os 60 quadros por segundo do
  `technical-preferences` (16,6 ms por quadro) no pior caso do MVP (9 inimigos
  por onda, Combate V15, e 24 telégrafos). A cena de estresse da F10 usa o teto
  do §8.6 (40 inimigos × 3) como folga.

## UI Requirements

- **Sem tela para o jogador.** As opções de acessibilidade (Reduzir flashes,
  Redução de movimento, intensidade do telégrafo) são do GDD de Acessibilidade e
  opções.
- **Ferramentas de debug** (só em builds de desenvolvimento):
  - o validador de família da R1, que lista os nós sem marca de família;
  - o modo de captura com os 3 simuladores de daltonismo e cinza (R11);
  - uma sobreposição com os contadores de orçamento (draw calls do monitor,
    emissores, flipbooks), sempre ressalvando que a fonte de verdade é a
    captura (R9).

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/art/art-bible.md` | §1, §2.8, §2.9, §4.1–4.7, §5.5, §5.8, §6.2–6.3, §7.7–7.9, §8.1–8.9 | regra central, paleta e escada de L*, grading regional, telégrafo, inversão, camadas, flashes, acessibilidade, orçamentos, importação |
| `design/gdd/cena-3-4-e-camera.md` | R1, R4, R5, R7, R8, R10, OQ1, OQ2, OQ6 | viewport e stretch, camadas e z, y-sort, câmera e zoom, troca de câmara; perguntas que o Pipeline responde |
| `design/gdd/combate-nucleo.md` | V1, V2–V6, V9–V15, AC1, OQ4 | dois relógios, traços das ações, flash, inversão, contorno de invulnerabilidade, impact frame, orçamento de VFX, limitador |
| `design/gdd/movimento-e-esquiva.md` | V3 | imagens residuais em tracejado |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, F7 | `VisualTuning` como `*Tuning`, faixas, conversão de tempo |
| `design/gdd/game-concept.md` | §3 (P3), §11 | legibilidade; direção de arte e câmera |
| `docs/engine-reference/godot/modules/rendering.md`, `breaking-changes.md`, `deprecated-apis.md` | 4.4–4.7 | linhas sem suavização no 4.7, stretch, HDR output, Shader Baker, `y_sort_enabled`; lacuna: o renderer 2D não está coberto |

## Acceptance Criteria

> Proposta do `qa-lead` (modo Lean), revista na revisão 1 (2026-11-10) contra as
> regras da v2. Todas as contas foram refeitas por script (sRGB IEC 61966-2-1,
> D65, Rec.709, CIE 1976). Os oráculos de L\* com ±0,05 usam a `lut_passagem`
> (lut(c) = c exato, em float). Pela `lut_identidade` RGBA8, a quantização de
> x/31 em 8 bits soma até 0,2 L\* perto do chão (o chão dá 25,23 em vez de
> 25,13), mais que a tolerância.
>
> Evidência: **[L]** `tests/unit/visual/`; **[I]** `tests/integration/visual/`;
> **[V]** Visual/Feel: screenshot retido em `production/qa/evidence/` com a
> assinatura nomeada no critério (art-director para cor e leitura;
> technical-artist para medida); **[P]** desempenho, com captura retida e
> limiar; **[M]** manual, com testador, build e resultado registrados. O
> Pipeline não tem tela própria: nenhum critério é [UI].
>
> **Oráculo em CPU (espelho).** F1, F4, F5, F7, o `modo_impacto` por shader (R1,
> R7) e a inversão (R6) só existem em shader. Os [L] testam um espelho em
> GDScript das mesmas fórmulas (`VisualMath`, nome a confirmar no ADR), puro e
> sem SceneTree. O espelho do F1 lê a `Image` RGBA8 e reproduz o bilinear do
> hardware em R e G e o `mix` manual em B; por isso a saída de LUT tem ±1/255.
> Um [L] do espelho **não** prova o shader: cada fórmula de shader tem um [I] ou
> [V] que compara a leitura de volta com o espelho (F1: AC-PV-10; ordem:
> AC-PV-17; F4: AC-PV-19; F7: AC-PV-29; impacto: AC-PV-39, 40 e 70; inversão:
> AC-PV-68). O `commands.test` roda headless, com o renderer dummy, que não
> desenha. Todo critério que lê pixels roda com GPU (`godot --path .
> --rendering-driver d3d12` ou `vulkan`), fora do CI, e retém a captura.
>
> **BLOQUEADO até o experimento En** (OQ1): o critério depende de um
> comportamento do 4.7 marcado NÃO VERIFICADO. **E1** o monitor conta os draw
> calls do 2D, e o lote no y-sort (R9); **E2** LUT e globais em canvas_item e no
> Shader Baker, hints de sampler e paridade D3D12 × Vulkan (R2, R7, Edge);
> **E3** relógios: `TIME` na pausa, `speed_scale` 0 nos emissores, avanço
> manual de animação (R8); **E4** SDF do telégrafo: largura do contorno, malha
> de borda e custo (F3, F4); **E5** contorno e inversão no CanvasGroup,
> `fit_margin`, `TEXTURE_PIXEL_SIZE` e imagens residuais (R6); **E6** fio de
> vínculo (R6); **E7** material único por entidade e `instance uniform` (R6).
> Todo critério que lê pixels ([V], [P], [M] e os [I] com leitura de volta) e
> desenha um shader de `amb_graded` ou `char_tint` depende do E2 (ou roda no
> plano B e diz qual); todo que desenha `tel_sdf` depende do E4. O cabeçalho de
> cada critério e a lista da Nota de cobertura seguem esta regra.
>
> **VV13 da FPV.** A FPV sempre dá {VV13 aviso} (os tetos de memória do §8.6
> somam 504 MiB, acima do alerta de 448). Esse aviso fica fora de todo conjunto
> exato dos critérios; só a AC-PV-47 o testa, mudando os tetos de memória.
>
> Tolerâncias: L\* ±0,05 (oráculos com 2 casas, do script); cor codificada
> ±0,0005 por canal no espelho; saída de LUT RGBA8 ±1/255 por canal; SDF ±0,001
> unidade de canvas; coberturas e opacidades ±0,001; áreas ±0,1 unidade²;
> `t_apres` e `progresso_wipe` ±1e-9; o float32 do F8 é exato bit a bit.
> Passos, contagens, conjuntos de erros e avisos e a ordem dos eventos são
> exatos. Medida em captura: largura ±0,5 px físico; cor ±2/255 por canal. Uma
> borda exata só é testada com números representáveis em binário; senão, um
> ponto de cada lado a ±0,001. Passos são indexados a partir de 0 (o passo em
> que o estado entra).
>
> Cada critério é independente: o teste copia a fixture e o roteiro citados.
> Nada de seed nem de tempo real: relógio monotônico, `dt_real`,
> `Engine.time_scale` e estado do orquestrador são dublês injetados (R13).
> Telégrafos, VFX, Run, Câmaras, Acessibilidade e os eventos do Combate são
> **provisórios**: os critérios que dependem deles usam dublês que honram este
> GDD e serão rodados de novo com os sistemas reais.
>
> **Fixture padrão do Pipeline (FPV):**
>
> - `VisualTuning` padrão (todos os padrões da tabela de Faixas seguras), com
>   `limite_flashes_s` 3, `limite_impacto_s` 1, `limiar_area_flash` 0,11.
> - **LUTs** (`Image` RGBA8 1024×32, sem mipmaps, sem repeat, sem compressão),
>   geradas por funções de fábrica em `tests/unit/visual/fixtures/`:
>   - `lut_identidade`: texel da fatia s, coluna x, linha y (y = 0 no topo) =
>     (x/31; y/31; s/31);
>   - `lut_permutada`: texel = (s/31; x/31; y/31), o que dá
>     lut(c) = (c.b; c.r; c.g);
>   - `lut_permutada_invertida`: a `lut_permutada` com as linhas trocadas
>     (y = 0 embaixo), o erro de convenção da ferramenta;
>   - `lut_constante`: todo texel = (0,55; 0,50; 0,60);
>   - `lut_degrau`: fatias 0–12 pretas, fatias 13–31 brancas;
>   - `lut_passagem`: dublê sem textura, lut(c) = c exato em float (F2, F5 e
>     VV3).
> - **Cores** (L\* do script): chão `#343C4A` 25,13 (Y 0,04456); parede
>   `#2B3240` 20,69; núcleo `#FFD3EE` 88,93; anel `#FF3DAE` 59,57; contorno
>   `#0D0E14` 4,07; osso `#E6DFCF` 88,97; osso de mundo `#CFC6B4` 80,15;
>   magenta `#E0259C` 51,35.
> - **Região dublê** (Run e regiões; VV3 e VV15): tom mais escuro e tom mais
>   claro do chão = `#343C4A`; veio cinza de base L\* 41,00 (pico 44,95 com
>   `amplitude_veio` 0,10, sem aviso).
> - **Telégrafos** (origem (0; 0), θ = 0, w = 4, a = 6, `opacidade_base` 0,25):
>   **C120** círculo r = 120; **C100** círculo r = 100; **A60** anel
>   r_int 60, r_ext 120 (r_m 90, t_a 30, D 30, D'' 20); **R400** retângulo
>   400 × 80 ancorado no atacante (D 40, D'' 30); **S200** setor R = 200,
>   α = 45° (D 82,843, D'' 72,843). aa = 1/(s_tela × z): 0,75 em 1440p com
>   z = 1.
> - **Orquestrador dublê:** roteiro de estados por quadro (Jogo, hitstop,
>   pausa, Bênção, menu, transição, Morte), `dt_real` por quadro,
>   `Engine.time_scale` e um espião dos globais e uniforms escritos (nome,
>   valor, quadro).
> - **Combate dublê:** eventos com as durações do Combate (R12): flash de
>   acerto 5 passos vivos (V6); extra da inversão 4 passos vivos (V10);
>   invulnerabilidade pós-dano 40 passos vivos; impact frame `recusa` e `chefe`
>   de 12 passos de apresentação.
> - **Relógio monotônico dublê** em µs, para o F6.
> - **Jogador dublê** para a oclusão: pé e centro do corpo injetados; a chave
>   de y-sort do jogador é o y do pé (Cena R5).
> - **Cena de captura** `tests/integration/visual/cena_captura.tscn`: a câmara
>   1920 × 1080 com chão `#343C4A`, paredes, veios, 3 faixas de névoa, feixes, 3
>   props (1 `oclusor`), o jogador, 2 Ecos e os telégrafos C120, R400 e S200;
>   p = 0; LUT do Limiar, salvo quando o critério pede a `lut_identidade`.
> - **Cena de estresse** `tests/performance/visual/estresse_f10.tscn`: o pior
>   caso da F10 (24 telégrafos, 40 inimigos com 3 peças cada, 60 props, 24
>   emissores no teto de partículas, 40 flipbooks, 3 imagens residuais), com
>   câmara de chefe para o pico.

**A. Dados, injeção e validação**

- **AC-PV-01 [L] R12/R13 — sem valor escondido.** Criar o Pipeline (o objeto
  de lógica, sem SceneTree) sem `VisualTuning` falha na construção com erro
  nomeado; nenhum global é escrito e nenhum valor padrão de código é usado.
  Trocar `passo_profundidade` para 0,04 no dado muda o `fator_profundidade` em
  p = 2 de 0,94 para 0,92 (nenhum número no código).
- **AC-PV-02 [L] R13 — determinismo.** Duas instâncias novas, com a FPV e o
  roteiro versionado `tests/unit/visual/fixtures/roteiro_relogios.json` (3600
  quadros com todos os estados, engasgos de 0,5 s, duas transições, pedidos de
  impact frame `recusa` e `chefe`, disparos de telégrafo e oclusão), escrevem a
  mesma sequência de globais (`t_vivo`, `t_apres`, `fator_profundidade`,
  `modo_impacto`, `modo_bencao`, `escala_traco`), de `progresso_wipe` e de
  opacidades de oclusão, bit a bit.
- **AC-PV-03 [L] Faixas/VV — validação do `VisualTuning`.** Cada linha muda um
  só campo da FPV (LUT `lut_passagem` e a região dublê da FPV) e
  confere o **conjunto exato** de regras disparadas, com a precedência da
  Validação (AC-PV-59) e o VV17 **por valor** (dispara quando o valor sai da
  faixa segura e nenhuma outra VV disparou para aquele campo). Erro impede a
  run; aviso só registra. A FPV sozinha dá {VV13 aviso}, que fica fora das
  colunas abaixo.

  | Campo | Sem regra | Conjunto exato |
  |---|---|---|
  | `forca_grading_personagem` | 0 e 0,15 | −0,01 → {VV1}; 0,151 → {VV1} |
  | `piso_profundidade` | 0,83 e 1 | 0 → {VV2, VV3 erro}; 1,01 → {VV2}; 0,78 → {VV3 erro} (chão a L\* 21,86); 0,80 → {VV3 aviso} (22,18) |
  | `passo_profundidade` | 0 e 0,05 | −0,01 → {VV2}; 0,051 → {VV17} |
  | `contorno_telegrafo_px` | 3,5 e 6 | 3 → {VV5}; 3,01 → {VV17}; 6,01 → {VV5} (o alto, 6, fica menor) |
  | `contorno_telegrafo_alto_px` | 4 e 8 | 3,99 → {VV5}; 8,01 → {VV17} |
  | `contorno_silhueta_px` | 2 e 3,5 | 4 → {VV5}; 3,51 → {VV17}; 1,99 → {VV17} |
  | `largura_tracejado_px` | 1,5 e 2,5 | 3 → {VV6}; 2,99 → {VV17}; 1,49 → {VV7} |
  | `intervalo_tracejado_px` | 3,5 e 12 | 3,49 → {VV7}; 12,01 → {VV17} |
  | `traco_tracejado_px` | 4 e 16 | 3,99 → {VV17}; 16,01 → {VV17} |
  | `largura_anel_px` | 0 e 12 | −0,01 → {VV17}; 12,01 → {VV17} |
  | `opacidade_base_telegrafo` | 0 e 0,4 | 0,401 → {VV17} |
  | `duracao_flash_telegrafo_s` | 0,033 e 0,05 | 0,0329 → {VV17} (2 passos); 0,051 → {VV17} (3 passos); 0,016 → {VV17} (1 passo) |
  | `opacidade_oclusao` | 0,3 e 0,6 | 0 → {VV11 erro}; 1 → {VV11 erro}; 0,29 → {VV11 aviso}; 0,61 → {VV11 aviso} |
  | `duracao_transicao_oclusao_s` | 0,017 e 0,2 | 0 → {VV11 erro}; 0,016 → {VV17}; 0,201 → {VV17} |
  | `margem_histerese_oclusao_px` | 0 e 16 | −0,01 → {VV17}; 16,01 → {VV17} |
  | `duracao_fade_s` | 0,1 e 0,3 | 0,301 → {VV14}; 0,099 → {VV17} |
  | `duracao_wipe_s` | 0,2 e 0,6 | 0 → {VV14}; 0,19 → {VV17}; 0,61 → {VV17} |
  | `dt_max_apres` | 0,05 e 0,25 | 0,0166 → {VV14}; 0,0167 → {VV17}; 0,251 → {VV17} |
  | `ciclo_veio_s` | 2,0 | 1,99 → {VV15} |
  | `amplitude_veio` | 0 e 0,10 | 0,101 → {VV15} |
  | `opacidade_max_feixes` | 0 e 0,20 | 0,201 → {VV15} |
  | `limiar_area_flash` | 0,05 e 0,11 | 0,111 → {VV15} |
  | `saturacao_bencao` | 0,15 e 0,25 | 0,149 → {VV17}; 0,251 → {VV17} |
  | `valor_bencao` | 0,55 e 0,70 | 0,549 → {VV17}; 0,701 → {VV17} |
  | `teto_drawcalls_passes` | 2 e 6 | 1 → {VV17}; 7 → {VV17} |

  - VV15 aviso, cruzada com regiões (`lut_passagem`, veio cinza, pico =
    valor × 1,10 no codificado): base L\* 41,00 → {} (pico 44,95); base
    41,50 → {VV15 aviso} (pico 45,49). O limiar fica em base 41,05.
  - O parallax do primeiro plano (`CameraTuning`) e as durações do flash de
    acerto e do extra da inversão (Combate, no evento) não são campos do
    `VisualTuning` (R12) e não têm linha.
- **AC-PV-04 [L] VV8–VV10 — telégrafo degenerado** (provisório: o catálogo de
  Telégrafos é dublê). Na validação do catálogo, cada linha dá o conjunto
  exato, com a precedência da Validação (VV8 suspende VV9 e VV10 do mesmo
  telégrafo; o erro do VV9 suspende o aviso do VV9). Em execução, o mesmo
  telégrafo dá aviso de debug e não é desenhado (VV8) ou é desenhado com clamp
  (VV10). O VV7 (perímetro < 3P) é do tracejado (F7), não do contorno do
  telégrafo, que é contínuo: nenhuma linha abaixo o dispara.

  | Entrada | Conjunto exato |
  |---|---|
  | C120 | {} |
  | círculo r = 0; r = −1 | {VV8} (o VV9 suspenso) |
  | anel r_int = r_ext = 60 | {VV8} |
  | setor α = 0 | {VV8} |
  | setor R = 200, α = π | {VV8} (o VV9 suspenso; o VV10 não tem cláusula de setor) |
  | círculo com `ao_longo_do_eixo` | {VV8} |
  | círculo r = 4 (D = w; D'' = −6) | {VV9 erro} (o aviso suspenso) |
  | círculo r = 4,01 e r = 10 (D'' = −5,99 e 0) | {VV9 erro} (D'' ≤ 0) |
  | círculo r = 10,5 e r = 17,99 (D'' = 0,5 e 7,99) | {VV9 aviso} (0 < D'' < 8) |
  | círculo r = 18 (D'' = 8) | {} |
  | p = −0,1 e p = 1,1 em execução | {VV10}, desenhado com p = 0 e p = 1 |
  | anel r_int 0, r_ext 120 | {VV10} |
- **AC-PV-59 [L] Validação — precedência.** O validador aplica a precedência
  da Validação, e o conjunto de saída não depende da ordem dos campos nem dos
  telégrafos:
  - um telégrafo com VV8 nunca lista VV9 nem VV10 (círculo r = 0; setor
    α = π);
  - o erro de uma VV suspende o aviso da mesma VV para o mesmo campo ou
    telégrafo (`opacidade_oclusao` 0 → {VV11 erro}; círculo r = 4 e r = 10 → {VV9
    erro}; região dublê com o tom escuro do chão em L\* 23,50 e o claro em
    38,10 → {VV3 erro});
  - a suspensão não passa de um telégrafo ou campo para outro: um catálogo com
    um círculo r = 0 e um círculo r = 12 (D'' = 2) dá {VV8 no primeiro, VV9
    aviso no segundo}; `opacidade_oclusao` 0 junto com
    `duracao_transicao_oclusao_s` 0,016 dá {VV11 erro, VV17};
  - o VV17 é por valor: `contorno_telegrafo_px` 3,01 → {VV17}; 3 → {VV5}, sem
    VV17;
  - o mesmo `VisualTuning` e o mesmo catálogo, validados com os campos e os
    telégrafos em ordem inversa, dão o mesmo conjunto.
- **AC-PV-05 [I] R1 — validador de família** (debug). Árvore montada em teste
  com 8 CanvasItems de mundo: um com `amb_sprite`, um com `amb_aditivo`, um com
  `char_sprite`, um com `tel_sdf`, um com `vfx_sprite`, um com a variante de
  `amb_sprite` com `recebe_profundidade` falso, um sem material e um com um
  `ShaderMaterial` de um shader que não inclui o `.gdshaderinc` de nenhuma
  família (sem marca). O validador lista **exatamente** os dois últimos, por
  caminho de nó, no registro de depuração; o jogo não para e nenhum material é
  trocado. Os passes de tela em `pós` (z 50) não são listados. No mesmo
  arquivo, um teste confere que a lista fechada da R1 tem exatamente os 9
  shaders (`amb_sprite`, `amb_mascara`, `amb_aditivo`, `char_sprite`,
  `char_grupo`, `tel_sdf`, `traco_sdf`, `vfx_sprite`, `ui`) e que cada um
  declara a marca da família da tabela. Os shaders dos passes, `pass_wipe` e
  `pass_morte`, ficam fora da lista e das famílias (R1): não têm marca e o
  validador não os lista. Na build de release o validador não
  roda (nenhuma linha no registro). O mecanismo da marca vem do ADR.
- **AC-PV-06 [I] R10 — configuração do projeto.** Um script lê o
  `project.godot` com `ConfigFile` e confere, nos caminhos de chave da R10
  (todos NÃO VERIFICADO hoje; confirmados antes por uma sonda no ClassDB do
  4.7.2, registrada no ADR): filtro padrão de textura de canvas = Linear
  Mipmap; `snap_2d_transforms_to_pixel` e `snap_2d_vertices_to_pixel` falsos;
  `hdr_2d` falso; saída HDR (`request_hdr_output`) desligada; os
  `shader_globals` `lut_regiao` (sampler2D; ou ausente no plano B, AC-PV-12),
  as cores da região, `fator_profundidade`, `modo_impacto` (int; os valores 0,
  `recusa`, `chefe` e `reduzido` são constantes do include), `modo_bencao`,
  `saturacao_bencao`, `valor_bencao`, `t_vivo`, `t_apres` e `escala_traco`,
  cada um com o tipo declarado; `progresso_wipe` **não** é global (é uniform
  do material de `pass_wipe`, R7). Hoje
  falha (o `project.godot` não declara nada disso). "Sem glow" não é chave do
  `project.godot`: é conferido na AC-PV-53. O Shader Baker é do preset de
  exportação: essa linha fica **BLOQUEADA até existir `export_presets.cfg`**,
  com a chave do preset NÃO VERIFICADO.

**B. Grading, profundidade e Bênção**

- **AC-PV-07 [L] F1 — LUT identidade.** Com `lut_identidade`, para todo c na
  grade de 18 valores por canal {0; 1/17; …; 1} (5832 cores) e para as 6 cores
  com um canal em 1/255 ou 254/255 e os outros dois em 0,5: |lut(c) − c| ≤
  1/255 em todo canal. O alfa sai igual ao de entrada (0; 0,5; 1).
- **AC-PV-08 [L] F1 — convenção dos eixos.** Com `lut_permutada`, para c =
  (0,2; 0,5; 0,9), (1; 0; 0), (0; 1; 0) e (0; 0; 1): lut(c) = (c.b; c.r; c.g)
  ±1/255. A `lut_permutada_invertida` falha este teste em (0; 1; 0), com erro
  ≥ 0,99 no canal B.
- **AC-PV-09 [L] F1 — amostragem e exemplo.** Com c = (0,60; 0,50; 0,40):
  b = 12,4, s0 = 12, s1 = 13, t = 0,4 (±1e-6); u0 = 0,393652, u1 = 0,424902,
  v = 0,5 (±1e-6). Com `lut_constante`: f = 0,15 → c_out = (0,5925; 0,50;
  0,43); f = 1 → (0,55; 0,50; 0,60); f = 0 → c (±1/255).
  - Bordas: c.b = 1 → s0 = s1 = 31, t = 0; c.r = 0 → u = (32·s + 0,5)/1024;
    c.r = 1 → u = (32·s + 31,5)/1024 (dentro da fatia s).
  - `lut_degrau`: c = (0,5; 0,5; 0,4) → lut = (0,4; 0,4; 0,4) ±1/255;
    c = (1; 0,5; 12/31) → lut = (0; 0; 0) ±1/255 (não lê a fatia 13).
- **AC-PV-10 [I] F1/E2 — o shader bate com o espelho. BLOQUEADO até o E2.**
  Com GPU, um quad de 256 × 256 com as 5832 cores da grade da AC-PV-07,
  desenhado com `amb_sprite` e cada LUT de textura da FPV, lido de volta: cada
  pixel bate com o espelho com ±1/255. O mesmo quad com `char_sprite` bate com
  f = 0,15; com `vfx_sprite` e `ui` (família `sem_grading`), sai com a cor de
  entrada. Roda nos dois caminhos da R2 (global e plano B).
- **AC-PV-11 [L] VV4 — perfil da LUT.** Conjunto exato por linha: LUT
  1024 × 32 RGBA8 sem mipmaps, sem repeat → {}; 1024 × 64 → {VV4}; com
  mipmaps → {VV4}; com repeat → {VV4}; comprimida com perda (VRAM) → {VV4};
  LUT da região ausente → {VV4}, e a run não começa. A
  `lut_permutada_invertida` (1024 × 32 RGBA8, perfil certo) → {}: a convenção
  dos eixos não é validação de região (VV4); quem a pega é a AC-PV-08.
- **AC-PV-12 [I] R2/E2 — troca de LUT só sob a tinta. BLOQUEADO até o E2.**
  Com o orquestrador dublê, a região muda na entrada da câmara seguinte:
  `lut_regiao` (ou o uniform do plano B nos shaders das três famílias) muda no **mesmo
  quadro** em que a transição chega à metade (tela coberta) e em nenhum outro.
  Uma troca de região pedida sem transição não muda a LUT até a próxima
  transição. O critério roda nos dois caminhos (global e plano B) e dá o mesmo
  espião.
- **AC-PV-13 [L] F2 — multiplicador por profundidade.** Com a FPV,
  `fator_profundidade` por p:

  | p | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 50 |
  |---|---|---|---|---|---|---|---|---|
  | k | 1 | 0,97 | 0,94 | 0,91 | 0,88 | 0,85 | 0,85 | 0,85 |

  (±1e-9). É calculado uma vez por câmara: dentro da câmara, o espião registra
  uma única escrita.
- **AC-PV-14 [L] F2 — L\* do chão e da parede, em linear.** Com
  `lut_passagem` e c' = lin2srgb(k × srgb2lin(c)) (±0,05 L\*):

  | p | 0 | 1 | 2 | 3 | 4 | ≥ 5 |
  |---|---|---|---|---|---|---|
  | Chão `#343C4A` | 25,13 | 24,71 | 24,29 | 23,85 | 23,41 | 22,96 |
  | Parede `#2B3240` | 20,69 | 20,32 | 19,94 | 19,56 | 19,16 | 18,76 |

  - A sombra de parede de L\* 10,00 vai a 8,63 em k = 0,85.
  - Veios e sombras de contato (`recebe_profundidade` verdadeiro) escurecem
    como o chão; com `recebe_profundidade` falso (névoa L\* 35 e 55, fundo,
    feixes, primeiro plano), a cor sai igual em todo p.
  - Em `char_tint` e `sem_grading`, a cor sai igual em todo p; o núcleo fica
    em 88,93, e núcleo − chão vai de 63,81 (p = 0) a 65,98 (p ≥ 5).
  - O matiz não muda: em k = 0,85, a razão entre os canais lineares do chão é
    a de entrada (±1e-6).
  - Registro da alternativa rejeitada (não é o comportamento): no codificado,
    o mesmo k levaria o chão a 21,89 em p = 4 e a 21,08 em p ≥ 5; a otimização
    `c_LUT × k^(1/2,4)` dá 23,37 em p ≥ 5. Este critério falha se o espelho
    implementar qualquer um dos dois.
  - Pela `lut_identidade` RGBA8, o mesmo cálculo dá o chão em 25,23 (p = 0) e
    23,06 (p ≥ 5): confere com ±0,25 L\* (o erro é da quantização da LUT, não
    do F2).
- **AC-PV-15 [L] VV3 — piso do chão por LUT** (provisório: Run e regiões
  dublê). Com `lut_passagem`, `piso_profundidade` 0,85, e o tom mais escuro do
  chão t = cinza em float, `t = lin2srgb(((L + 16)/116)³)` para o L\* da
  linha:

  | L\* de t | L\* em k = 0,85 | Conjunto exato |
  |---|---|---|
  | 23,50 | 21,42 | {VV3 erro} (k_min = 0,8903) |
  | 24,00 | 21,89 | {VV3 erro} |
  | 24,20 | 22,08 | {VV3 aviso} |
  | 24,50 | 22,36 | {VV3 aviso} |
  | 24,80 | 22,65 | {} |
  | 25,13 (`#343C4A`) | 22,96 | {} |

  Limiares: erro abaixo de L\* 24,115 (k_min = 0,85), aviso abaixo de 24,643;
  toda linha fica a ≥ 0,08 L\* deles. Uma LUT sintética que escurece o chão
  `#343C4A` para L\* 23,5 depois da LUT dá {VV3 erro} (a regra lê Y(lut(t)),
  não t).
  - Teto da faixa (aviso do VV3, em p = 0): com o tom mais claro do chão t' =
    cinza em float, pelo mesmo `lin2srgb`, L\* 37,90 → {}; 38,10 → {VV3
    aviso}; `#343C4A` (25,13) → {}. Tom escuro em 23,50 e claro em 38,10 na
    mesma LUT → {VV3 erro} (o erro suspende o aviso da mesma VV, AC-PV-59).
- **AC-PV-16 [L] F5 — Bênção.** Com `lut_passagem`, p = 0, `saturacao_bencao` 0,20 e
  `valor_bencao` 0,60:
  - chão `#343C4A`: Y = 0,04456; g = 0,2336; mistura (0,2277; 0,2340; 0,2449);
    c' = (0,1366; 0,1404; 0,1470) (±0,0005), L\* 14,06;
  - magenta `#E0259C`: o cinza g tem L\* 51,35, igual ao da cor (a luma Rec.709
    no codificado daria 36,29; o critério falha se der esse valor);
  - cinza puro (0,5; 0,5; 0,5) → (0,3; 0,3; 0,3);
  - com `valor_bencao` 0,55, o chão vai a L\* 12,61; com 0,70, a 16,91;
  - uma peça `#343C4A` em `char_sprite` dá o mesmo c' do chão (o F1 com
    f = 0,15 e `lut_passagem` não muda a cor);
  - `char_grupo`, `tel_sdf`, `traco_sdf`, `vfx_sprite` e `ui` não mudam com
    `modo_bencao` (tabela da R1).
- **AC-PV-71 [L] R2/Edge — números e letreiros somem na Bênção.** Com o
  orquestrador dublê e um VFX dublê com 3 números e 1 letreiro vivos no mundo
  (`vfx_sprite`): no quadro em que a Bênção abre, os 4 deixam de ser desenhados
  (alfa 0 ou invisíveis), sem fade (nenhum quadro com alfa entre 0 e 1); um
  flipbook de VFX que não é número nem letreiro segue desenhado; as cartas (UI)
  não mudam. Ao fechar a Bênção, os 4 não voltam.
- **AC-PV-17 [I] R2/R3 — ordem das operações no shader. BLOQUEADO até o E2.**
  Com GPU, quads de chão `#343C4A` com `lut_identidade`, p = 5, e `modo_bencao`
  ligado: `amb_sprite` (`recebe_profundidade` verdadeiro) faz F1 → F2 → F5 e
  bate com o espelho (±2/255); a variante com falso pula o F2; `char_sprite`
  pula o F2; `vfx_sprite` sai igual à entrada. Com `modo_impacto` ligado por
  cima, vale a AC-PV-69 (o impacto é a última operação).

**C. Escala do traço**

- **AC-PV-18 [L] F3 — tabela de s_tela.** Para cada janela, s_tela e as
  larguras em pixel físico com z = 1 (±0,001):

  | Janela | s_tela | contorno 4 | tracejado 1,75 | traço 8 / intervalo 6 |
  |---|---|---|---|---|
  | 1280 × 720 | 0,6667 | 2,667 | 1,167 | 5,333 / 4 |
  | 1280 × 800 | 0,6667 | 2,667 | 1,167 | 5,333 / 4 |
  | 1920 × 1080 e 2560 × 1080 | 1 | 4 | 1,75 | 8 / 6 |
  | 1920 × 1200 | 1 | 4 | 1,75 | 8 / 6 |
  | 2560 × 1440 e 3440 × 1440 | 1,3333 | 5,333 | 2,333 | 10,667 / 8 |
  | 3840 × 2160 | 2 | 8 | 3,5 | 16 / 12 |

  - 1440p com z = 1,15: contorno 6,133 px; aa = 0,6522 unidade; tracejado do
    CanvasGroup 2,683 px.
  - `escala_traco` escrito pelo orquestrador = s_tela × z, a cada quadro em
    que s_tela ou z mudam (espião).
- **AC-PV-66 [L] VV5/F3 — `contorno_silhueta_px`.** Conjunto exato, mudando
  os dois campos juntos: silhueta 3 e contorno 4 → {}; silhueta 3,5 e contorno
  3,5 → {VV5} (silhueta ≥ contorno); silhueta 3,49 e contorno 3,5 → {};
  silhueta 4 e contorno 6 → {VV17} (silhueta fora de 2–3,5; VV5 não dispara,
  4 < 6). Largura em pixel físico (× `escala_traco`): 3 px em 1080p, 4,6 px em
  1440p com z = 1,15, 6 px em 4K. `fit_margin` do CanvasGroup =
  (max(1,75; 3) + 1) × `escala_traco` = 4; 6,133; 8 (a unidade é do E5).
- **AC-PV-19 [V] F3/F4/E4 — contorno medido na captura. BLOQUEADO até o E2 e o E4.**
  Cena de captura com C120 em `crescendo`, p = 0,5, capturada em 1920 × 1080,
  2560 × 1440 e 3840 × 2160 (z = 1) e em 1440p com z = 1,15. A largura do
  contorno, medida como a faixa com α_c ≥ 0,5 ao longo de 8 raios, é 4, 5,33, 8
  e 6,13 px físicos (±0,5); a borda externa da tinta coincide com a borda de
  acerto do círculo (±0,5 px); em 1440p com z = 1, a leitura de volta de α_c,
  α_a e α_n nos raios da AC-PV-60 bate com o espelho (±2/255); a captura do
  RenderDoc mostra o contorno numa malha de borda (r − w − 2 a r + 2), não num
  quad cheio. As 4 capturas ficam retidas; assina o technical-artist.

**D. Telégrafo**

- **AC-PV-20 [L] F4 — SDF de cada forma.** d (±0,001) nos pontos q (θ = 0):
  - **C120:** (0; 0) → −120; (118; 0) → −2; (120; 0) → 0; (130; 0) → 10.
  - **A60:** |q| = 90 → −30; |q| = 60 → 0; |q| = 120 → 0; |q| = 50 → 10;
    (0; 0) → 60.
  - **R400:** (200; 0) → −40; (0; 0) → 0 (lado do atacante); (−10; 0) → 10;
    (200; 50) → 10; (410; 50) → 14,142. Com θ = 90°, o ponto de mundo
    (0; 200) → −40.
  - **S200:** (100; 0) → −70,711; (250; 0) → 50; (0; 100) → 70,711;
    (0; 0) → 0; (150; 150) → 12,132.
- **AC-PV-21 [L] F4 — raio interno e zonas.** D: C120 120; A60 30; R400 40;
  S200 82,843; setor R = 200 com α = 120° → 100. Para C120 em 1440p
  (aa = 0,75), `borda_ao_centro`:
  - α_c: 1 em |q| = 118; 0,5 em |q| = 120 e em 116; 0 em 113;
  - zona: anel em |q| = 113 (h = 3); núcleo em |q| = 109 (h' = 1);
  - α_n em |q| = 100: 0,250 com p = 0 e 1,000 com p = 1.
- **AC-PV-60 [L] F4 — anel e composição da cor.** C120, 1440p (aa = 0,75),
  `borda_ao_centro`; α_a = cov(d + w, aa) − cov(d + w + a, aa); cor da passada
  do preenchimento = (α_a·`#FF3DAE` + α_n·`#FFD3EE`) / max(α_f, 1e−5), em 0–255
  (±0,5):

  | \|q\| | p | α_a | α_n | α_f | cor |
  |---|---|---|---|---|---|
  | 116 | 0 e 1 | 0,500 | 0,000 | 0,500 | (255; 61; 174) |
  | 113 | 0 e 1 | 1,000 | 0,000 | 1,000 | (255; 61; 174) |
  | 110 | 0 | 0,500 | 0,125 | 0,625 | (255; 91,0; 186,8) |
  | 110 | 1 | 0,500 | 0,500 | 1,000 | (255; 136; 206) |
  | 109 | 0 | 0,000 | 0,250 | 0,250 | (255; 211; 238) |
  | 109 | 1 | 0,000 | 1,000 | 1,000 | (255; 211; 238) |

  - Sem fresta: com p = 1, numa grade de 0,25 unidade entre |q| = 104 e 115,5,
    α_a + α_n = 1 (±0,001).
  - Em |q| = 118 (fora do preenchimento), α_f = 0, e a cor não é NaN.
  - Base sobre o chão (p = 0, mistura no codificado): L\* 42,45 com
    `opacidade_base_telegrafo` 0,25; 52,30 com 0,4.
- **AC-PV-61 [L] F4/F10 — malha de borda do contorno.** A malha gerada na CPU,
  numa grade de 0,5 unidade:
  - C120: cobre todo ponto com 114 ≤ |q| ≤ 122 (r − w − 2 a r + 2) e nenhum
    com |q| < 113 ou > 123; área dentro de ±2% de π(122² − 114²) = 5.931,3
    unidades², contra 59.536 do quad cheio (−90,0%);
  - A60, R400 e S200: cobre todo ponto com −w − 2 ≤ d ≤ 2 (−6 ≤ d ≤ 2) e
    nenhum com d < −7 ou d > 3, inclusive nos cantos do retângulo e no ápice e
    nos cantos do setor;
  - com w = 6 (intensidade do telégrafo, AC-PV-75), a faixa vai a −8 ≤ d ≤ 2.
- **AC-PV-22 [L] F4 — crescimento em p = 0, 0,5 e 1.** Cada linha confere em
  que pontos da área do núcleo (h' > 0) g ≤ 0 (crescido), com
  d_n = d + w + a (a SDF da área do núcleo) e `q_c` relativo à âncora:

  | Forma e modo | p = 0 | p = 0,5 | p = 1 |
  |---|---|---|---|
  | C120 `borda_ao_centro` | nenhum | 55 ≤ \|q\| < 110 | todos |
  | C120 `centro_a_borda` | nenhum | \|q\| ≤ 55 | todos |
  | A60 `centro_a_borda` | nenhum (sem linha em \|q\| = 90) | 80 ≤ \|q\| ≤ 100 | todos |
  | R400 `ao_longo_do_eixo` | nenhum | 10 < q.x ≤ 200 | todos |
  | R400 `centro_a_borda` | nenhum | 105 ≤ q.x ≤ 295 e \|q.y\| ≤ 15 | todos |
  | S200 `centro_a_borda` e `ao_longo_do_eixo` | nenhum | a área do núcleo escalada por 0,5 em torno do ápice do núcleo recuado, (14,142; 0): (20; 0) e (102; 0) crescidos, (102,2; 0) e (150; 0) base | todos |

  - Em p = 0, nos três modos e no anel, o espelho trata p = 0 antes de tudo:
    cov(g) = 0 e α_n = `opacidade_base` × cov(a − h) em toda a área (0,25 no
    miolo; 0,125 em h' = 0), sem divisão por zero e sem a linha de meia
    cobertura em |q| = 90 no A60 nem em |q| = 110 no C120.
  - R400 `ao_longo_do_eixo` com p = 0,25: crescido em 10 < q.x ≤ 105 e base em
    q.x > 105.
  - S200 `ao_longo_do_eixo` dá o mesmo g de `centro_a_borda` (sinônimo, F4)
    em todo ponto de uma grade de 1 unidade, com p = 0,25, 0,5 e 0,75.
  - Em p = 1, a coluna "todos" vem do atalho p ≥ 1 (cov(g) = 1, AC-PV-82).
- **AC-PV-23 [L] F4 — completa exatamente em p = 1.** Para C100, C120, A60,
  R400 e S200, em cada modo válido, numa grade de 1 unidade sobre a área do
  núcleo (h' > 0): em p = 1, cov(g) = 1 em todo ponto (o p ≥ 1 é tratado
  antes, sem avaliar g; F4), e o g calculado sem o atalho também é ≤ 0. Em p = 0,99, g > 0 nestes
  pontos (±0,001):

  | Forma e modo | Ponto | g |
  |---|---|---|
  | C100 `borda_ao_centro` | (0; 0) | 0,900 |
  | C100 `centro_a_borda` | (89,5; 0) | 0,400 |
  | A60 `borda_ao_centro` | (90; 0) | 0,200 |
  | A60 `centro_a_borda` | (70,1; 0) | 0,100 |
  | R400 `borda_ao_centro` | (200; 0) | 0,300 |
  | R400 `centro_a_borda` | (389,5; 0) | 1,400 |
  | R400 `ao_longo_do_eixo` | (387; 0) | 0,800 |
  | S200 `borda_ao_centro` | (117; 0) | 0,617 |
  | S200 `centro_a_borda` (ápice do núcleo em (14,142; 0)) | (189,5; 0) | 1,259 |
  | S200 `ao_longo_do_eixo` (= `centro_a_borda`) | (189,5; 0) | 1,259 |

  Regressão do defeito citado no GDD: C100 `borda_ao_centro` em p = 0,9 ainda
  tem g = 9 no centro (não fechou).
- **AC-PV-82 [L] F4 — p ≥ 1 sem linha nem fresta.** Em 1440p (aa = 0,75),
  com p = 1 e com p = 1,1 (clamp, VV10), o espelho trata p ≥ 1 antes de tudo
  (cov(g) = 1, sem avaliar g):
  - A60 `borda_ao_centro`: α_n = 1,000 em |q| = 90 (a linha média; sem o
    atalho daria 0,625) e em |q| = 85 e 95;
  - R400 `borda_ao_centro`: α_n = 1,000 em (200; 0) e em todo o eixo q.y = 0,
    de q.x = 40 a 360 (grade de 1 unidade);
  - C120 `borda_ao_centro`: α_n = 1,000 em (0; 0);
  - sem fresta na fronteira anel/núcleo: C120 `centro_a_borda` em |q| = 110
    dá α_a = 0,500, α_n = 0,500 e α_a + α_n = 1,000 (sem o atalho, 0,8125);
    R400 `ao_longo_do_eixo` em (390; 0) dá α_a + α_n = 1,000; numa grade de
    0,25 unidade entre |q| = 100 e 115,5 (C120) e entre q.x = 380 e 389,5
    (R400, q.y = 0), α_a + α_n = 1 (±0,001);
  - em p = 0,99 o atalho não age: os g da AC-PV-23 continuam valendo.
- **AC-PV-24 [L] R5/F4 — estados** (provisório: Telégrafos dublê, passos
  vivos; `duracao_flash_telegrafo_s` 0,033 → `passos` = 2):
  - `disparo` aceito pelo limitador, ou sem pedido (área abaixo do limiar,
    F6): anel e núcleo em osso `#E6DFCF` nos passos 0 e 1; no passo 2, nada é
    desenhado; o contorno não muda de cor;
  - `disparo` negado: anel `#FF3DAE` e núcleo `#FFD3EE` como estavam (o núcleo
    a 100% em p = 1), sem osso, nos passos 0 e 1; no passo 2, nada;
  - com `duracao_flash_telegrafo_s` 0,05 → 3 passos (0, 1 e 2), nada no 3;
  - `quebrado`: rachadura nos passos 0 e 1, sem osso; no passo 2, nada;
  - `cancelado`: opacidade das duas passadas 1 no passo 0, 0,5 no passo 1 e
    nada no passo 2, sem osso;
  - `quebrado` e dono morto no mesmo passo → vale `quebrado`;
  - em `crescendo`, com `p` constante por 60 passos, cor e opacidade de cada
    zona não mudam (nunca pulsa);
  - em hitstop, os passos não contam: um `disparo` que entra no passo vivo N,
    seguido de um hitstop de 6 quadros, fica em osso no passo N, nos 6 quadros
    congelados e no passo vivo N + 1; no N + 2, nada.
- **AC-PV-25 [I] R5/R6 — duas passadas e camadas.** Na cena de captura, cada
  telégrafo gera exatamente 2 CanvasItems com `tel_sdf`: o preenchimento
  (quad) com z −5, abaixo do y-sort, e o contorno (malha de borda) com z 5, na
  camada `contorno de telégrafo`. O contorno não recebe névoa, grading nem
  `fator_profundidade` (os globais mudam, o contorno não); essa conferência
  lê pixels de `tel_sdf` e fica **BLOQUEADA até o E4**, e a da árvore e dos z
  roda já. Um anel de área do
  jogador (`traco_sdf`) fica em z −5 num nó irmão **anterior** ao de todos os
  preenchimentos de telégrafo (índice menor na árvore). Depende da camada
  `contorno de telégrafo` entrar na tabela da R4 da Cena (OQ5).
- **AC-PV-26 [V] R5/Art Bible §6.3 — corpo por cima, contorno visível.
  BLOQUEADO até o E2 e o E4.** Cena de captura, C120 em `crescendo` (p = 0,5) com um
  Eco parado sobre o centro e o jogador sobre a borda; R400 sob um prop alto
  que não é `oclusor`. Captura em 1080p:
  - o corpo do Eco e o do jogador cobrem o preenchimento;
  - o contorno aparece por cima dos dois corpos e do prop, contínuo nos 360°
    (nenhum trecho do contorno escondido);
  - a medida de cor no contorno sobre o corpo dá `#0D0E14` (±2/255).
  Assinam o art-director (leitura e a emenda do §6.3) e o lead.
- **AC-PV-27 [V] Edge — sobreposição e borda da câmara. BLOQUEADO até o
  E2 e o E4.** Captura com dois
  C120 sobrepostos e um R400 encostado na borda da câmara: os dois contornos
  aparecem inteiros; na sobreposição, o núcleo não fica mais claro que
  `#FFD3EE` (medida ±2/255); o R400 aparece inteiro até a borda, sem corte de
  quad. Assina o art-director.
- **AC-PV-75 [L] R5/R11 — intensidade do telégrafo.** Com a opção de
  intensidade ligada (Acessibilidade dublê), w = `contorno_telegrafo_alto_px`
  6. No C120 em 1440p (aa = 0,75): α_c = 0,5 em |q| = 120 e em 114, e 1 em
  117; D'' = 108; em `borda_ao_centro` com p = 0,5, a frente fica em h' = 54
  (|q| = 54); a malha de borda vai de |q| = 112 a 122. Desligada a opção,
  volta a w = 4 no quadro seguinte.

**E. Traço do jogador e leitura do corpo**

- **AC-PV-28 [L] F7 — tracejado.** P = 14, r_t = 8/14 = 0,5714:
  - anel r = 150: perímetro 942,478; n = 67; P' = 14,067; traço 8,038;
    intervalo 6,029 (±0,001);
  - silhueta de 90 unidades: R_ref 45; n = 20;
  - círculo r = 1: perímetro 6,283, round(0,449) = 0 → n = 1 (o `max` vale);
    com r = 2, n = 1 já sai do `round` (0,898);
  - aviso VV7 por perímetro < 3P: r = 6,68 → {VV7}; r = 6,69 → {}.
- **AC-PV-62 [L] F7 — δ periódico e derivada analítica.** Anel r = 150 em
  1440p (aa = 0,75), no raio |q| = 150: aa_φ = aa × (r/|q|) / P' = 0,05332.
  - `on` = 1 no meio do traço (s = 4,019), 0 no meio do intervalo
    (s = 11,053) e 0,5 nas duas bordas do traço (s = 0 e s = 8,038) (±0,001);
  - sem costura: on(s = 0) e on(s = perímetro − 1e-6) dão 0,5 (a borda de
    início do traço), com diferença ≤ 0,001; on(perímetro − ε) = on(P' − ε)
    para ε = 0,001;
  - sem coluna: aa_φ em θ = π − 1e-4 e em θ = −π + 1e-4 é igual ao de θ = 0
    (±1e-9); o espelho calcula |∇s| analiticamente e não tira diferença finita
    de s através de θ = ±π;
  - |∇s| cai com |q|: em |q| = 75, aa_φ = 0,10663;
  - retângulo R400 tracejado: |∇s| = 1, aa_φ = aa / P'; no canto inicial,
    on(s = 0) e on(s = 960 − 1e-6) dão 0,5 (±0,001).
- **AC-PV-29 [V] R6/F7 — tracejado de ação e imagens residuais. BLOQUEADO
  até o E2 e o E4** (as capturas têm chão, corpos e telégrafos). Captura em
  1080p e em 720p de: o *smear* do Corte, o anel da Onda, o glifo do Pulso e as
  3 imagens residuais da esquiva (`traco_sdf`). O traço mede 1,75 px (±0,5) em
  1080p e 1,17 px (±0,5) em 720p; a cor mede `#CFC6B4` (±2/255; L\* 80,15 ≤ 82);
  nenhuma linha cheia (os intervalos se veem). Em 1440p, o anel da Onda r = 150
  lido de volta tem 67 traços ao longo de |q| = 150 e nenhuma coluna de meia
  cobertura em θ = ±π (o espelho da AC-PV-62, ±2/255). Nas mesmas capturas,
  nenhum traço do jogador se confunde com um contorno de telégrafo (tracejado ×
  contínuo; osso de mundo × tinta). Assina o art-director.
- **AC-PV-83 [I] R6 — imagens residuais no y do pé** (provisório: Movimento
  dublê). Uma esquiva dublê deixa 3 imagens residuais com o pé do jogador em
  y = 400, 430 e 460: cada imagem é um nó do y-sort com chave igual ao y do pé
  em que foi deixada (400, 430 e 460), não ao y atual do jogador, e um prop
  com pé em y = 415 fica entre a 1ª e a 2ª na ordem de desenho; nenhuma imagem
  tem nó de mancha de contato; nunca há mais de 3; o shader é `traco_sdf`.
- **AC-PV-30 [V] R6/E5 — contorno de invulnerabilidade na silhueta.
  BLOQUEADO até o E2 e o E5.** O jogador atingido (invulnerabilidade de 40 passos
  vivos do Combate dublê: passos 0–39) é capturado nos passos 0, 20 e 39 em
  1080p e em 1440p com z = 1,15:
  - o contorno tracejado em osso de mundo `#CFC6B4` (±2/255) envolve a
    silhueta inteira do rig **por fora** da borda do alfa, sem costura entre as
    peças e sem corte no limite do buffer do CanvasGroup (`fit_margin` 4 px em
    1080p e 6,13 px em 1440p com zoom; AC-PV-66);
  - a fase é igual nas três capturas (não anda, não pisca);
  - a largura mede 1,75 px em 1080p e 2,68 px em 1440p com zoom (±0,5);
  - no passo 40 o contorno não aparece; nenhum inimigo recebe o efeito.
  Assinam o art-director e o technical-artist.
- **AC-PV-78 [V] R6 — fio de vínculo. BLOQUEADO até o E2 e o E6.** Captura de um
  aliado dublê com o fio de vínculo em 1080p e em 720p: shader de família
  `sem_grading` (`traco_sdf`; `vfx_sprite` se o E6 escolher Line2D com
  textura, R6), cor `#CFC6B4` (±2/255), traço contínuo com borda suavizada
  (nenhum degrau de serrilhado ao longo de 100 px de fio a 30°). Um script
  confere que o fio não usa `draw_line` nem `Line2D` sem textura. Assina o
  art-director.
- **AC-PV-31 [L] R6 — tempos do corpo** (provisório: Combate dublê; as
  durações chegam no evento, nenhuma vem do `VisualTuning`).
  - Inversão: golpe recebido com hitstop de 6 quadros e extra 4 no evento → a
    inversão dura os 6 quadros congelados + 4 passos vivos e termina no fim do
    4º vivo; com extra 0, termina com o hitstop; com extra 8, dura 6 + 8.
  - Flash de acerto: com 5 no evento, 5 passos vivos, segurado no hitstop (um
    hitstop de 3 quadros no meio estende a duração em 3 quadros); com 3 no
    evento, 3 passos.
  - Contorno de invulnerabilidade: ligado do primeiro ao último passo da
    invulnerabilidade do evento, exato (40 → passos 0–39).
  - Esquiva atingida durante a invulnerabilidade da esquiva: nenhuma inversão,
    nenhum contorno pós-dano.
  - Recusa: a ordem dos efeitos é inversão → impact frame `recusa` → contorno
    pela invulnerabilidade da recusa; durante o impact frame `recusa`,
    contorno e inversão ficam suspensos no `char_grupo` (tabela da R1).
- **AC-PV-80 [L] R6 — a inversão substitui o tracejado** (provisório: Combate
  dublê; os passos vivos da invulnerabilidade contam do primeiro passo vivo
  depois do hitstop). Golpe recebido com hitstop de 6 quadros, extra 4 e
  invulnerabilidade de 40 passos vivos (0–39):
  - nos 6 quadros congelados e nos passos vivos 0–3, o `char_grupo` desenha só
    o contorno sólido da inversão (nenhum pixel do tracejado; no espelho da
    AC-PV-67, a saída com os dois ligados é igual à da inversão só);
  - o tracejado aparece no passo vivo 4, o seguinte ao fim da inversão, e
    segue até o 39; no 40, nada;
  - com extra 0, o tracejado aparece no passo vivo 0.
- **AC-PV-74 [I] R6 — material único por entidade. BLOQUEADO até o E7.** Com
  9 e com 40 inimigos e 3 props `oclusor` instanciados: cada entidade do y-sort
  tem o próprio `ShaderMaterial` (nenhum recurso repetido entre entidades;
  duplicado no spawn), com os uniforms `papel`, `flash` e, nos oclusores,
  `alfa_oclusao`; ligar o `flash` de um Eco não muda nenhum outro material;
  nenhum shader usa `instance uniform`. O custo de CPU e de troca de estado
  medido no E7 entra na AC-PV-48.
- **AC-PV-32 [V] R6/R11 — flash de acerto visto. BLOQUEADO até o E2.**
  Captura de um Eco (`char_sprite`) no passo 0 do flash: mede L\* ~80 (75–85;
  mistura com `#CFC6B4`). Com a opção Reduzir flashes ligada e `modo_impacto` = 0 (a opção não
  depende do valor `reduzido`, R11), mede L\* ~65 (60–70).
  Assina o art-director.
- **AC-PV-67 [L] R6 — inversão no CanvasGroup (espelho).** Sobre uma `Image`
  sintética de 64 × 64 da saída do grupo (função de fábrica: uma peça clara
  `#E6DFCF`, uma peça escura com traço interno `#0D0E14`, uma sobreposição das
  duas, alfa 1 no miolo e 0,5 na borda), com `escala_traco` 1:
  - todo pixel com alfa > 0 (o traço interno escuro, a peça clara e a
    sobreposição) sai `#0D0E14`, com o alfa de entrada;
  - pixels com alfa 0 a até 3 px da borda do alfa (`contorno_silhueta_px` ×
    `escala_traco`) saem `#CFC6B4`; a 4 px ou mais, alfa 0;
  - nenhum pixel sai em osso por limiar de L\* por peça;
  - com `escala_traco` 1,533 (1440p, z = 1,15), o contorno vai a 4,6 px.
- **AC-PV-68 [V] R6/E5 — inversão vista. BLOQUEADO até o E2 e o E5.** Captura do
  jogador no passo 0 da inversão, em 1080p e em 1440p com z = 1,15: a silhueta
  inteira em tinta `#0D0E14` (±2/255), sem as sobreposições das peças à vista;
  contorno sólido `#CFC6B4` por fora da borda, com 3 px em 1080p e 4,6 px em
  1440p com zoom (±0,5), sem corte no limite do buffer; a leitura de volta bate
  com o espelho da AC-PV-67 (±2/255). Assinam o art-director e o
  technical-artist.

**F. Oclusão**

- **AC-PV-33 [L] F9 — exemplo do GDD.** `duracao_transicao_oclusao_s` 0,1 →
  n_oc = 6. R_oc x 800–960, y 300–520; pé (870; 500), corpo (870; 455);
  y_prop 520:
  - cobre; α por passo de apresentação: 1 → 0,9 → 0,8 → 0,7 → 0,6 → 0,5 → 0,4
    (6 passos; ±1e-9);
  - pé e corpo a x = 964: continua coberto (dentro de R_oc ⊕ 8, que vai até
    968 exclusivo);
  - x = 968: sai (borda superior exclusiva);
  - reversão: com α = 0,7, sair leva α a 1 em 3 passos;
  - em hitstop, α continua andando (relógio de apresentação); em pausa, para.
- **AC-PV-34 [L] F9 — regras.** Cada caso parte do exemplo:
  - y_prop 500 (= y do pé): não cobre, mesmo com pé e corpo dentro;
  - só o corpo dentro de R_oc: pé (975; 500), corpo (870; 455), y_prop 520 →
    cobre;
  - entrar exige R_oc sem margem: pé e corpo em x = 964, vindo de fora, não
    cobrem;
  - dois oclusores cobrindo: os dois vão a 0,4;
  - passagem rápida: entra e sai depois de 2 passos → α 0,8 e volta a 1 em 2
    passos, sem salto;
  - `opacidade_oclusao` 0,3 e `duracao_transicao_oclusao_s` 0,017
    (n_oc = 1) → α 1 → 0,3 num passo; com `opacidade_oclusao` 0,3 e 0,2 s (n_oc = 12), α cai
    0,05833 (0,7/12) por passo.

**G. Momentos de tela e limitador**

- **AC-PV-35 [L] Estados — prioridade dos modos** (Transição > Morte > Bênção
  > Impacto > Normal). Com o orquestrador dublê: pedido de impacto durante a
  Transição → descartado, o modo segue Transição e o evento de jogo segue;
  durante a Bênção → descartado; durante a Morte → descartado. O fim do
  Impacto volta ao modo anterior. A Transição volta a Normal ao descobrir. O impacto ativo cortado pela
  Transição ou pela Morte e a Bênção que espera estão na AC-PV-81.
- **AC-PV-81 [L] Estados — impacto ativo cortado; a Bênção espera.** Com o
  orquestrador dublê, `dt_real` 1/60 e um impact frame `recusa` de 12 passos
  de apresentação (dublê; o valor de fábrica da recusa é 18) aceito no quadro 0, cada item em separado:
  - Transição no quadro 5: no mesmo quadro, `modo_impacto` vai a `0` e o modo
    de tela a Transição; o impacto não volta depois que a Transição descobre;
  - `jogador_morreu` no quadro 5: o mesmo, com o modo Morte;
  - Bênção pedida no quadro 5: o modo segue Impacto até o quadro 11, e a
    Bênção abre no quadro 12 (`modo_bencao` ligado no 12, não antes);
  - o impacto cortado segue contando no `N_flash` e no `N_imp` até sair da
    janela (conta o início, F6).
- **AC-PV-36 [L] F6 — sequência do exemplo.** Relógio em µs, limitador vazio;
  "disparo" é um pedido de disparos de telégrafo acima do limiar (o passe de
  tela obrigatório nunca é negado, AC-PV-79):
  - recusa em 100.000 → aceita; disparo em 400.000 → aceito; disparo em
    700.000 → aceito;
  - disparo em 950.000 → negado (3 na janela);
  - recusa em 1.050.000 → negada (3 flashes e o impacto em 100.000 na janela);
  - recusa em 1.100.000 → aceita (100.000 saiu da janela semiaberta; 2 flashes
    e nenhum impacto);
  - disparo em 1.150.000 → negado (400.000, 700.000 e 1.100.000 na janela);
  - disparo em 1.399.999 → negado; disparo em 1.400.000 → aceito (400.000 sai
    da janela (0,4; 1,4]).
  Os negados não entram na contagem e não são enfileirados (nenhum efeito
  depois). Com Reduzir flashes, os mesmos pedidos saem em `reduzido` e dão o
  mesmo resultado.
- **AC-PV-37 [L] F6 — área do disparo.** Disparos de C120 no mesmo passo vivo
  (área por telégrafo = πr² = 45.238,9, a forma inteira, F6), limiar 228.096:

  | Disparos | z = 1 | z = 1,15 |
  |---|---|---|
  | 3 | 135.716,8 → sem pedido | 179.485,5 → sem pedido |
  | 4 | 180.955,7 → sem pedido | 239.314,0 → 1 pedido |
  | 5 | 226.194,7 → sem pedido | 299.142,5 → 1 pedido |
  | 6 | 271.433,6 → 1 pedido | 358.970,9 → 1 pedido |

  Borda: um retângulo 576 × 396 (área 228.096) em z = 1 → 1 pedido (≥).
  Seis disparos em passos vivos diferentes → nenhum pedido.
- **AC-PV-38 [L] F6 — ordem no mesmo passo.** Limitador com 1 vaga (2 flashes
  na janela, nenhum impacto): chefe, recusa, passe de transição e disparo
  pedidos no mesmo passo → chefe aceito; recusa e disparo negados; o passe,
  obrigatório, sai como fade (a janela ficou cheia com o chefe) e conta
  (`N_flash` = 4). Com 2 vagas (1 flash na janela, nenhum impacto): chefe
  aceito; recusa negada (o chefe conta no `N_imp(recusa)`); passe aceito como
  wipe de tinta; disparo negado. O flash de acerto num Eco, pedido 10 vezes no
  mesmo segundo, não muda a contagem. O telégrafo negado entra em `disparo`
  sem osso (AC-PV-24).
- **AC-PV-63 [L] F6 — preempção do chefe.** Relógio em µs, impact frames de
  12 passos de apresentação (0,2 s); **cada item parte do limitador vazio**
  (são roteiros separados):
  - recusa em 2.000.000 → aceita; chefe em 2.300.000 → aceito
    (`N_imp(chefe)` = 0, `N_flash` = 1); um segundo chefe em 2.600.000 →
    negado (`N_imp(chefe)` = 1);
  - corte: recusa aceita em 2.000.000 e chefe em 2.100.000 (passo 6 da
    recusa): no quadro do chefe, `modo_impacto` passa de `recusa` a `chefe` sem
    quadro de `0` no meio, e a recusa não volta depois do fim do chefe;
  - recusa depois do chefe: chefe aceito em 3.000.000, recusa em 3.500.000 →
    negada (`N_imp(recusa)` conta o chefe);
  - a recusa cortada continua contando no `N_flash` até sair da janela.
- **AC-PV-64 [L] F6 — o teto de 3 flashes/s vale para o chefe.** Recusa aceita
  em 2.000.000 e disparos (acima do limiar) aceitos em 2.050.000 e 2.100.000; chefe em 2.300.000 →
  **negado** (`N_flash` = 3 na janela (1,3; 2,3] s): o chefe fica sem impact
  frame, a recusa segue até o fim, e o evento de jogo (morte do chefe,
  hitstop) acontece igual. O mesmo pedido de chefe em 3.000.001 (a janela tem
  2 flashes: 2.050.000 e 2.100.000) → aceito. Com Reduzir flashes, o mesmo
  roteiro dá o mesmo resultado (o `reduzido` conta).
- **AC-PV-79 [L] F6/R7 — passe de tela obrigatório nunca é negado.** Relógio
  em µs, limitador vazio, cada item em separado:
  - disparos aceitos em 100.000, 200.000 e 300.000 (janela cheia); transição
    de câmara pedida em 500.000 → **não é negada**: sai como fade de
    `duracao_fade_s` (0,3 s, shader `pass_wipe`) em vez do wipe de tinta, a
    câmara troca com a tela coberta pelo fade, e o passe conta (`N_flash` = 4
    na janela (−0,5; 0,5]); um disparo em 600.000 é negado;
  - com 2 flashes na janela (disparos em 200.000 e 300.000), a transição em
    500.000 sai como wipe de tinta de `duracao_wipe_s` e conta (`N_flash` = 3);
  - `jogador_morreu` com a janela cheia: o passe de morte sai (nunca negado),
    como fade, e conta;
  - com Reduzir flashes, o mesmo resultado.
- **AC-PV-39 [V] R7 — impact frame `recusa`. BLOQUEADO até o E2 e o E4.** Cena de
  captura com `modo_impacto` = `recusa`, com o jogador, 2 Ecos, C120, um anel
  de área do jogador, um VFX de ataque inimigo e o HUD:
  - cenário (`amb_sprite`, `amb_mascara`) em tinta chapada, L\* ≤ 10 (medida em
    5 pontos do chão, das paredes e da névoa); feixes (`amb_aditivo`) somem;
  - jogador (`char_grupo`) em osso pleno `#E6DFCF` (±2/255), L\* ≥ 88, sem
    contorno de invulnerabilidade nem inversão;
  - Ecos em tinta chapada com contorno osso `#E6DFCF` por peça, inteiro (o
    quadro do atlas tem margem ≥ 3 unidades; OQ12);
  - C120: só o contorno, em osso; nenhum preenchimento;
  - anel de área (`traco_sdf`) some; VFX de ataque inimigo em osso chapado;
  - HUD igual à captura sem impacto (diferença ≤ 2/255).
  Uma captura PIX ou RenderDoc do mesmo quadro tem o mesmo número de draw calls
  do quadro sem impacto (nenhum passe de tela; F10). Assinam o art-director e o
  lead de QA.
- **AC-PV-40 [V] R11 — impact frame `reduzido`. BLOQUEADO até o E2 e o E4.** Mesma
  cena com Reduzir flashes (os pedidos `recusa` e `chefe` saem em `reduzido`):
  o mundo fica dessaturado e um passo abaixo na escada (variação de 8–12 L\* no
  chão), sem tela em osso nem em tinta; personagens com F1 e dessaturação de um
  passo; contorno e inversão do jogador seguem; telégrafos, traços, VFX e HUD
  não mudam (≤ 2/255). Assina o art-director.
- **AC-PV-69 [L] R1/R7 — `modo_impacto` por shader (espelho).** Para cada um
  dos 9 shaders e cada valor (`0`, `recusa`, `chefe`, `reduzido`), o espelho do
  include devolve o que a tabela da R1 diz, com mundo `#343C4A`, peça de
  personagem `#808080` e o C120:
  - `recusa`: `amb_sprite` e `amb_mascara` → `#0D0E14`; `amb_aditivo` → alfa
    0; `char_sprite` de inimigo e de aliado → `#0D0E14` com contorno
    `#E6DFCF`; `char_grupo` → `#E6DFCF`; `tel_sdf` → preenchimento alfa 0 e
    contorno `#E6DFCF`; `traco_sdf` → alfa 0; `vfx_sprite` → `#E6DFCF` no VFX
    de ataque inimigo e alfa 0 no resto; `ui` igual;
  - `chefe`: `amb_sprite` e `amb_mascara` → `#E6DFCF`; `amb_aditivo` → alfa 0;
    `char_sprite` → `#0D0E14` sem contorno; `char_grupo` → `#0D0E14`;
    `tel_sdf` → preenchimento alfa 0 e contorno `#0D0E14`; `traco_sdf` → alfa
    0; `vfx_sprite` → `#0D0E14` no VFX de ataque inimigo, manchas do abate
    iguais e alfa 0 no resto; `ui` igual;
  - `reduzido`: os três `amb_*` → L\* e saturação menores; `char_sprite` → F1
    e L\* e saturação menores; `char_grupo`, `tel_sdf`, `traco_sdf`,
    `vfx_sprite` e `ui` iguais;
  - `0`: tudo igual à saída sem impacto.
  O tamanho do "passo na escada" do `reduzido` não tem número no GDD; até ter,
  este critério confere só a direção.
- **AC-PV-70 [V] R7 — impact frame `chefe`. BLOQUEADO até o E2 e o E4.** A cena de
  captura com `modo_impacto` = `chefe` (Art Bible §2.9): mundo em osso chapado
  `#E6DFCF` (±2/255, em 5 pontos do chão, das paredes e da névoa); feixes
  somem; jogador e Ecos em tinta chapada `#0D0E14`, sem contorno; C120 só com o
  contorno, em tinta; VFX de ataque inimigo em tinta; manchas de tinta do abate
  (VFX dublê) visíveis; HUD igual (≤ 2/255). Mesmo número de draw calls do
  quadro sem impacto (captura). Assinam o art-director (OQ13) e o lead de QA.
- **AC-PV-41 [L] R7 — transição de câmara e fade** (`progresso_wipe`, uniform
  do material de `pass_wipe`, com o dt de apresentação). `duracao_wipe_s` 0,4 e `dt_real` 1/60: `progresso_wipe`
  sobe 1/24 por quadro; a tela fica coberta no 12º quadro (progresso 0,5,
  ±1e-9), a câmara (e a LUT) troca nesse quadro, e o wipe descobre no 24º
  (progresso ≥ 1 − 1e-9). Com um engasgo de 0,5 s, o progresso avança só 0,25
  (0,1 s, `dt_max_apres`). Com Redução de movimento, vira fade de 0,3 s, e a
  vinheta fica estática. Hitstop durante a transição não para o wipe.
- **AC-PV-65 [L] R7/F8 — o zero dos relógios não afeta o wipe.** No 12º quadro
  da transição, `n_vivos` e `t_apres` vão a 0 (AC-PV-43), e `progresso_wipe`
  segue 0,5 → 0,5417 → … → 1 nos 12 quadros seguintes, sem salto (±1e-9).
  Com `t_apres` forçado a 0 em qualquer quadro do roteiro, a sequência de
  `progresso_wipe` é a mesma, bit a bit. O passe de morte avança o próprio
  progresso do mesmo jeito.
- **AC-PV-76 [L] Edge — opção de acessibilidade muda no meio da run.** Reduzir
  flashes ligado no quadro N, com um impact frame `recusa` em curso: o espião
  mostra `recusa` até N e `reduzido` a partir de N + 1; nada é reescrito para
  trás.
- **AC-PV-77 [L] Edge — pausa no meio do impact frame.** Impact frame `recusa`
  de 12 passos de apresentação, pausa depois do 5º (passos 0–4) por 120
  quadros: `modo_impacto` fica `recusa`, a contagem fica em 5 e, ao despausar,
  o impacto dura mais 7 passos (5–11) e sai.
- **AC-PV-42 [P] R7 — teto dos passes de tela.** Captura PIX ou RenderDoc do
  quadro com transição, vinheta e morte juntas: ≤ 6 draw calls de passes de
  tela (`pass_wipe` e `pass_morte`; medição por diferença, F10). **BLOQUEADO
  até o E2** (a cena desenha o mundo) e, para o monitor, até o E1; depois do
  E2, vale pela captura.

**H. Relógios**

- **AC-PV-43 [L] F8 — relógios por estado.** Com o orquestrador dublê,
  `dt_real` 1/60 por quadro e 10 quadros por estado:

  | Estado | Δ`t_vivo` | Δ`t_apres` |
  |---|---|---|
  | Jogo (passo vivo) | 10/60 | 10/60 |
  | Hitstop | 0 | 10/60 |
  | Pausa | 0 | 0 |
  | Bênção | 0 | 0 |
  | Menus | 0 | 0 |
  | Transição de câmara | 0 | 10/60 |
  | Morte | 0 | 10/60 (a confirmar com a Run, OQ11) |

  - `Engine.time_scale` 0,5 não muda Δ`t_apres` (usa o `dt_real` sem escala).
  - `dt_real` 0,5 num quadro de Jogo → Δ`t_apres` = 0,1.
  - Cada relógio é escrito uma vez por quadro (espião); `t_vivo` = n_vivos/60
    em double, sem acumular soma de floats.
  - Na metade da transição, n_vivos = 0 e `t_apres` = 0 no mesmo quadro.
  - Janela sem foco = pausa.
- **AC-PV-44 [L] F8 — float32 e VV16.** n_vivos 216.001 → t_vivo
  3600,016667 em double e 3600,016602 em float32 (bit a bit; erro 0,065 ms).
  ULP: 1800 s → 2^−13; 3600 s → 2^−12; 4096 s → 2^−11 (0,488 ms). VV16:
  n_vivos 245.760 (4096 s) → nenhum aviso; 245.761 → aviso de debug; o mesmo
  para `t_apres` 4096,0167.
- **AC-PV-45 [I] R8 — nenhum `TIME` no mundo.** Um script varre os
  `.gdshader` e `.gdshaderinc` do projeto: nenhuma ocorrência do identificador
  `TIME` fora de comentário, exceto no shader `ui` (a R8 deixa a UI usar
  `TIME`). Um shader do mundo com `TIME` faz o teste falhar com o caminho e a
  linha; o `ui` com `TIME` passa.
- **AC-PV-46 [I] R8/E3 — emissores e animações congelam. BLOQUEADO até o
  E3.** Com GPU, um emissor do relógio vivo e um do de apresentação, e um
  `AnimatedSprite2D` vivo, por 30 quadros em cada estado: no hitstop, o vivo
  fica com `speed_scale` 0 e as partículas não andam (posição igual quadro a
  quadro na leitura de volta), e o de apresentação anda; na pausa e na Bênção,
  os dois param; ao voltar, retomam do mesmo estado (sem salto, sem
  reemissão).

**I. Orçamento**

- **AC-PV-47 [L] F10/VV12/VV13 — somas.** Grupos da R9: Σ = 444, reserva 56 →
  {}. UI 137 (Σ 501) → {VV12 erro}; UI 87 (Σ 451, reserva 49) → {VV12
  aviso}; UI 86 (reserva 50) → {}. Sombras e telégrafos = 6 + 24 × 2 = 54.
  Memória: página 4096 × 2048 RGBA8 com mipmaps = 42,667 MiB; LUT 1024 × 32 ×
  4 = 128 KiB; tetos do §8.6 no pior caso = 504 MiB → {VV13}; com 448 → {}.
  Overdraw (tolerância 1e-9 nas somas):
  - exemplo da câmara: 0,4 + 0,3 + 0,8 + 0,4 + 0,3 + 0,2 + 0,5 + 0,3 + 0,1 +
    0,2 = 3,5 → dentro (≤ 3,5);
  - telégrafo C120: quad 59.536 + malha de borda 5.931,3 = 65.467,3 unidades²;
    8 deles = (59.536 + 5.931,3) × 8 = 523.738,6 = 0,2526 tela (o valor da F10) (≤ 0,4, fatia da média); 24 = 0,7577 tela
    (≤ 0,8, fatia do pico); com o contorno em quad cheio, 24 dariam 1,3781,
    acima da fatia do pico;
  - fatia de VFX ≤ 0,5 tela.
- **AC-PV-48 [P] R9/F10 — cena de estresse. BLOQUEADO até o E2 e o E4** (a cena
  desenha `amb_graded` e `char_tint`; a malha de borda e o `tel_sdf` têm de
  existir; o teto do y-sort depende da opção a ou b do E5). Cena de estresse em 1920 × 1080, quadro
  de pior caso capturado no PIX (D3D12) e no RenderDoc (Vulkan):
  - draw calls no total ≤ 500, e cada grupo ≤ o teto da R9 (ambiente 40;
    sombras e telégrafos 54; y-sort 200, com as 3 imagens residuais em 3 draw
    calls na opção a da R6, ou + 15 na opção b, conforme o E5; VFX 64; passes
    6; UI 80), medidos por diferença;
  - overdraw (área dos quads e malhas, com o transparente) ≤ 3,5 telas na média
    de 600 quadros de combate e ≤ 5 no pico de chefe; fatias: VFX ≤ 0,5;
    sombras e telégrafos ≤ 0,4 na média e ≤ 0,8 no pico (os 24 C120 da cena;
    a fatia é contrato do GDD de Telégrafos, R9); o buffer do CanvasGroup do
    jogador e os passes `pós` em tela cheia ficam fora da soma e são medidos
    à parte, na planilha;
  - ≤ 24 emissores; ≤ 1.500 partículas GPU e ≤ 300 CPU; por emissor, fagulha
    ≤ 24, ambiente ≤ 150 e vórtice ≤ 600; ≤ 40 flipbooks; ≤ 2 PointLight2D,
    sem sombras; nenhum normal map;
  - memória de textura residente ≤ 512 MiB (alerta em 448 registrado);
  - tempo de quadro p99 ≤ 16,6 ms nos 600 quadros (`technical-preferences`).
  Captura e planilha ficam em `production/qa/evidence/`. O monitor do motor só
  substitui a captura depois do E1 (**BLOQUEADO até o E1** para essa troca). O
  custo do material único por entidade (AC-PV-74) entra aqui depois do E7.
- **AC-PV-49 [I] R9/Edge — acima do teto.** Com 30 telégrafos pedidos, todos
  os 30 são desenhados (nenhum cortado; consomem a reserva do orçamento: 54 + 12 = 66, com reserva ≥ 56) e sai um aviso de debug com o dono
  (Telégrafos ou IA). Com o orçamento de VFX estourado, sai primeiro a vítima
  escolhida pelo Feedback R4 (P4 a P2) e, na falta dela, o efeito
  mais antigo do relógio de apresentação (corte P4→P2 confirmado, Feedback R4); flash, telégrafo, telégrafo partido, inversão, passes obrigatórios e os P1
  (recusa e chefe) nunca saem.
- **AC-PV-72 [I] R9 — `light_mask` dos `sem_grading`.** Na cena de captura com
  2 PointLight2D de chefe, um script percorre a árvore: todo CanvasItem com
  shader de `sem_grading` (`tel_sdf`, `traco_sdf`, `vfx_sprite`, `ui`) tem um
  `light_mask` sem nenhum bit do `range_item_cull_mask` das luzes, e todo
  CanvasItem de `amb_graded` e `char_tint` tem o bit; nenhuma luz tem sombra
  ligada. Os nomes das propriedades vêm da sonda no ClassDB do 4.7.2 (NÃO
  VERIFICADO hoje).
- **AC-PV-73 [V] R9 — a luz não toca o aviso. BLOQUEADO até o E2 e o E4.** Captura da
  arena do chefe com as 2 luzes ligadas e desligadas: núcleo, anel e contorno
  do telégrafo, traços do jogador e HUD iguais nas duas (≤ 2/255); o chão, no
  ponto mais claro sob a luz, mede L\* ≤ 38. Assina o technical-artist.

**J. Atmosfera, cor e plataforma**

- **AC-PV-50 [V] R4 — névoa nunca sobre o chão. BLOQUEADO até o E2 e o E4.** Cena de
  captura com as 3 faixas de névoa e os feixes, em 1080p, 1440p e 3840 × 2160,
  com z = 1,15 e com o lookahead e o chute da câmera no máximo (Cena): a
  máscara é zero (diferença ≤ 2/255 para a captura sem névoa) em todo o
  retângulo jogável, e por isso sobre os 3 telégrafos. A névoa fica mais densa
  no topo e nas bordas; os feixes, em diagonal, fora do chão. Por script: a
  máscara 512 × 256, em espaço da câmara, é zero em todo texel que cai no
  retângulo jogável, e a posição de mundo de cada texel não muda com o
  deslocamento da câmera (a máscara anda com o mundo). Assina o art-director.
- **AC-PV-51 [V] R11/§4.7 — daltonismo e cinza. BLOQUEADO até o E2 e o
  E4.** A cena de captura com `lut_identidade` e p = 0, em 4 estados
  (`crescendo` com p = 0,5; `disparo` aceito; impact frame `recusa`; impact
  frame `chefe`), passa pela ferramenta de captura do Pipeline em 4 filtros
  (protanopia, deuteranopia, tritanopia e tons de cinza): 4 × 4 = 16 imagens,
  com L\* medido na imagem filtrada (±1):
  - `crescendo` e `disparo`: o núcleo crescido, ou o osso do disparo, fica
    ≥ 40 L\* acima do chão (esperado 63,81 e 63,85); o anel fica ≥ 15 L\*
    acima do chão (34,45) e o contorno ≥ 15 L\* abaixo dele (21,06);
  - impact frames (sem preenchimento, R1): o contorno do telégrafo fica a
    ≥ 40 L\* do mundo (`recusa`: osso 88,97 sobre tinta, L\* ≤ 10; `chefe`:
    tinta 4,07 sobre osso 88,97, 84,90);
  - em toda imagem, a ação do jogador (tracejado) se distingue do telégrafo
    pela forma (julgamento do art-director).
  As 16 imagens e as 4 originais ficam retidas; assinam o art-director e o
  lead de QA.
- **AC-PV-52 [V] R4 — veios e primeiro plano. BLOQUEADO até o E2.** Captura
  de cada região com LUT, no pico da pulsação do veio: o veio mede L\* ≤ 45
  depois da LUT; nenhum veio forma geometria fechada; saturação ≤ 60% (HSV,
  medida); o primeiro plano cobre ≤ 15% da tela (contagem de pixels). Com o
  relógio de apresentação, a pulsação do veio tem período ≥ 2 s e amplitude
  ≤ 10% de valor (medida em 240 quadros). O parallax do primeiro plano é do
  `CameraTuning` e é conferido na Cena. Assina o art-director.
- **AC-PV-53 [V] Edge/E2 — paridade D3D12 × Vulkan e HDR. BLOQUEADO até o
  E2 e o E4.** A cena de captura em D3D12 e em `--rendering-driver vulkan`: diferença
  por pixel ≤ 2/255. Num monitor HDR, a captura é igual à de SDR (≤ 2/255) e o
  glow não aparece. Assina o technical-artist.
- **AC-PV-54 [V] R2 — Bênção vista. BLOQUEADO até o E2.** Cena de captura
  **sem telégrafos e sem Ecos** (a Bênção só abre com a câmara limpa, R2), com
  `lut_identidade` e p = 0, tela de bênção aberta: o chão mede L\* 14,1 (±1); a
  carta (UI) fica igual à captura sem Bênção (≤ 2/255); nenhum número nem
  letreiro do mundo na tela (AC-PV-71). Assina o art-director.

**K. Manual**

- **AC-PV-55 [M] P3 — o perigo num relance. BLOQUEADO até o E2 e o E4.** 5 testadores, cada um com 10
  capturas da cena de captura com 1 a 3 telégrafos em posições sorteadas de
  antemão (lista versionada, sem seed em execução), exibidas por 0,5 s: cada um
  aponta onde está cada telégrafo. Passa com ≥ 90% de acertos no total. Com a
  ação do jogador na tela, nenhuma ação é apontada como telégrafo em mais de 1
  das 50 respostas.
- **AC-PV-56 [M] R5 — crescimento se lê. BLOQUEADO até o E2 e o E4.** Jogando 10 minutos na câmara de
  teste com C120, R400 e S200 nos três modos, o testador diz, para cada um, se
  o preenchimento cresceu até a borda antes do disparo e se em algum momento
  pulsou. Passa com "cresceu" em todos e "pulsou" em nenhum.
- **AC-PV-57 [M] R6/R8 — leitura do hitstop. BLOQUEADO até o E2 e o E3.**
  Durante um abate de chefe (36
  passos de hitstop), o testador confirma que os efeitos do mundo param e que a
  vinheta e a transição continuam. Registro com vídeo de 60 qps retido.
- **AC-PV-58 [M] Edge — Steam Deck (1280 × 800). BLOQUEADO até o E2 e o E4.** O tracejado de 1,17 px se
  vê em todas as ações (sim/não por ação) e o letterbox de 40 px aparece em
  cima e embaixo. Se o tracejado esmaecer, registrar a ação (o VV7 não dispara no
  padrão: 1,75 × 0,667 = 1,17 ≥ 1,0; não bloqueia).

### Nota de cobertura

| Item | Critérios |
|---|---|
| R1 | AC-PV-05, 10, 17, 25, 69 |
| R2 | AC-PV-07 a 12, 16, 17, 54, 71 |
| R3 | AC-PV-13, 14, 15, 17 |
| R4 | AC-PV-50, 52 |
| R5 | AC-PV-19 a 27, 55, 56, 60, 61, 75, 82 |
| R6 | AC-PV-28 a 34, 62, 66, 67, 68, 74, 78, 80, 83 |
| R7 | AC-PV-35 a 42, 63, 64, 65, 69, 70, 76, 77, 79, 81 |
| R8 | AC-PV-43 a 46, 57, 65 |
| R9 | AC-PV-42, 47, 48, 49, 72, 73 |
| R10 | AC-PV-06 |
| R11 | AC-PV-32, 40, 41, 51, 58, 75, 76 |
| R12 | AC-PV-01, 03, 31 |
| R13 | AC-PV-01, 02 |
| F1 | AC-PV-07 a 10 |
| F2 | AC-PV-13, 14, 15 |
| F3 | AC-PV-18, 19, 66 |
| F4 | AC-PV-19 a 24, 60, 61, 75, 82 |
| F5 | AC-PV-16, 54 |
| F6 | AC-PV-36, 37, 38, 63, 64, 79 |
| F7 | AC-PV-28, 29, 62 |
| F8 | AC-PV-43, 44, 65 |
| F9 | AC-PV-33, 34 |
| F10 | AC-PV-47, 48, 61 |
| VV1, VV2, VV6, VV11, VV14, VV15, VV17 | AC-PV-03 |
| VV3 | AC-PV-03, 15, 59 |
| VV4 | AC-PV-11 |
| VV5 | AC-PV-03, 66 |
| VV7 | AC-PV-03, 28 |
| VV8, VV9, VV10 | AC-PV-04, 59, 82 |
| VV12, VV13 | AC-PV-47 |
| VV16 | AC-PV-44 |
| Precedência da Validação | AC-PV-59 |
| Estados (modos de tela) | AC-PV-35, 81 |
| Edge Cases | AC-PV-04, 12, 24, 27, 31, 34, 35, 41, 49, 53, 54, 58, 63, 64, 65, 71, 76, 77, 79, 81 |

Contagem: 83 critérios — 48 [L], 12 [I], 17 [V], 2 [P], 4 [M]. Os números
AC-PV-59 a 78 são da revisão 1, e os AC-PV-79 a 83, da revisão 2; ficam junto
do tema, fora da ordem numérica; nenhum número antigo mudou.

Bloqueados por experimento (regra do preâmbulo: todo [V], [P] e [M] desenha o
mundo, então todos dependem do E2): E1 (AC-PV-42 e 48, só a troca da captura
pelo monitor); E2 (AC-PV-10, 12, 17, 19, 26, 27, 29, 30, 32, 39, 40, 42, 48,
50, 51, 52, 53, 54, 55, 56, 57, 58, 68, 70, 73, 78); E3 (AC-PV-46, 57); E4
(AC-PV-19, 25 só a leitura de pixels, 26, 27, 29, 39, 40, 48, 50, 51, 53, 55,
56, 58, 70, 73); E5 (AC-PV-30, 68; 48 só o teto do y-sort); E6 (AC-PV-78); E7
(AC-PV-74); export preset (parte da AC-PV-06). O `traco_sdf` (AC-PV-29) não
tem experimento próprio na OQ1 (OQ14).

**Pendências para o dono das regras** (as da OQ14; os critérios acima seguem o
texto atual):

1. O "passo na escada" do `reduzido` (R7, R11) não tem número; a AC-PV-69
   confere só a direção, e a AC-PV-40 usa os 8–12 L\* do texto antigo.
2. A R7 não diz se a pausa e a Bênção param o `progresso_wipe` (o dt de
   apresentação na pausa).
3. Redução de movimento ligada durante um wipe em curso: o Edge Case diz "a
   partir do quadro seguinte", mas não diz se o wipe em curso vira fade.
4. A cor do contorno no `disparo` não está escrita no F4; a AC-PV-24 supõe que
   não muda.
5. O tracejado `traco_sdf` (AC-PV-29) não tem experimento próprio na OQ1.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Experimentos no motor instalado, antes do ADR: E1 draw calls 2D (monitor × PIX/RenderDoc; lote no y-sort); E2 LUT global em canvas_item e no Shader Baker (conferir que o sampler da LUT não usa `source_color`), hints de sampler (`filter_linear`, `repeat_disable`) aceitos em `global uniform sampler2D` (se recusados, o filtro vem do padrão do projeto, Linear Mipmap, que sem mips cai para Linear) e paridade D3D12 × Vulkan; E3 relógios (`TIME` na pausa; `speed_scale` 0 nos emissores; avanço manual de animação); E4 SDF do telégrafo (largura do contorno a 1080p/1440p/4K, malha de borda e custo de GPU); E5 contorno de silhueta e inversão no CanvasGroup (custo, costuras, unidade do `fit_margin`, `TEXTURE_PIXEL_SIZE`) e imagens residuais (snapshot × rig duplicado, R6); E6 fio de vínculo (Line2D com textura × quad com SDF de segmento); E7 material único por entidade (custo de CPU e de troca de estado com 9 a 40 entidades) e `instance uniform` em canvas_item (NÃO VERIFICADO) | technical-artist + godot-shader-specialist | antes de `/create-architecture` |
| 2 | ADR: estrutura de nós e materiais, caminho do grading (LUT global ou plano B), orquestrador dos relógios | technical-director + godot-specialist | depois do E1–E3 |
| 3 | A confirmar pelo art-director: o telégrafo em duas passadas ("o corpo cobre o preenchimento"), o anel de 6 px, a base do núcleo a 25% em p = 0, o retângulo ancorado no lado do atacante | art-director | antes de produzir os telégrafos |
| 4 | Emendas no Art Bible: §5.5 (inversão = hitstop + 4 passos), §6.3 e §8.6 (telégrafo em duas passadas; sombras e telégrafos 54, reserva ≥ 56), §8.6 (impact frame por modo global), §8.6 (memória: os tetos somam 504 MiB, acima do alerta de 448) | art-director | próxima revisão do Art Bible |
| 5 | Cena: acrescentar a camada `contorno de telégrafo` (z 5) na tabela da R4 e fechar a OQ1 e a OQ6 | dono da Cena | próxima edição da Cena |
| 6 | Oclusão de personagem coberto por chefe (Cena OQ2) | dono do GDD de Chefes | fatia vertical |
| 7 | Índice: linha 6 com Conteúdo (forte) e Combate, Movimento, Run e Câmaras (suaves, por contrato) | usuário / producer | próxima edição do índice |
| 8 | O limiar de área do flash do telégrafo (11% da tela, critério WCAG) precisa de confirmação de quem cuida da acessibilidade | accessibility-specialist | GDD de Acessibilidade e opções |
| 9 | ~~Combate: (a)–(d)~~ **Resolvida em 2026-11-10** (cross-review, C-B2): V12 em passos de apresentação, campos no `CombatTuning` e nos eventos, preempção do chefe na Acessibilidade e na AC-78; o Pipeline em Dependencies do Combate. Texto original: (a) a V12 passar a duração do impact frame do chefe de "12 quadros de render" para passos de apresentação; (b) listar "Pipeline visual" em Dependencies; (c) confirmar que as durações do flash de acerto (V6) e do extra da inversão (V10) são campos dele, que o Pipeline recebe no evento; (d) o AC1 ("chefe > recusa; o perdedor fica sem impact frame") e o AC-79 passam a refletir a preempção do chefe sobre a recusa (R7, F6) | dono do Combate núcleo | próxima edição do Combate |
| 10 | Conteúdo: listar o `VisualTuning` na tabela de `*Tuning` da R1, e o Pipeline em Interactions e Dependencies | dono do Conteúdo | próxima edição do Conteúdo |
| 11 | Relógios na Morte (`t_vivo` parado, `t_apres` correndo) e Bênção só com a câmara limpa | dono da Run e regiões | GDD de Run e regiões |
| 12 | Margem transparente ≥ `contorno_silhueta_px` nos quadros de inimigo (6 texels com arte em 2×) × padding de 4 px do §8.6; aviso na ferramenta de recorte | art-director + technical-artist | antes de produzir os atlas de inimigo |
| 13 | Aspecto dos `sem_grading` e do jogador no impact frame (VFX de ataque inimigo em osso na `recusa` e em tinta no `chefe`; jogador em tinta no `chefe`), escolhido nesta revisão para manter o P3 | art-director | antes de produzir os VFX do combate |
| 14 | Pendências pequenas apontadas pelo qa-lead (2026-11-10): número do "passo na escada" do `modo_impacto` = `reduzido`; se a pausa e a Bênção param o `progresso_wipe`; se Redução de movimento ligada no meio de um wipe o converte em fade; cor do contorno no `disparo`; experimento para o tracejado `traco_sdf` (AC-PV-29) | technical-artist + accessibility-specialist | antes da story de VFX de tela |

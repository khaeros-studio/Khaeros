# Mestres Ofertantes

> **Status**: Designed
> **Author**: game-designer (Vertical Slice)
> **Created**: 2026-11-18
> **Last Updated**: 2026-11-18
> **Sistema**: #20 · Category: `Narrative` · Priority: `Vertical Slice`
> **Implements Pillar**: P1 *Toda bênção é uma filosofia*; P5 *O mundo não se explica de uma vez*; P4 *Ritual, não pressão*

## Summary

**Mestres Ofertantes** dá rosto, voz e vínculo aos três mentores canônicos de Khaeros — **Halvar** (Mestre da Lâmina / Forja), **Maren** (Mestra do Selo / Ressonância) e **Oreth** (Mestre do Véu / Pactos) — tanto na **Tela de Bênção** durante a run (retrato e fala contextual curta ao abrir a oferta) quanto no **Altar dos Mestres** no **Campus** (diálogos de afinidade e lore fragmentada entre descidas). O sistema é puramente narrativo e apresentacional: **não** altera probabilidades de sorteio nem substitui as regras de `Bênçãos (Tradições)`.

> **Quick reference** — Layer: `Narrative` · Priority: `Vertical Slice` · Key deps: `Bênçãos (Tradições), Diálogo e lore, Tela de bênção e componente de carta, Campus (hub), Save e perfil`

## Overview

No MVP, as bênçãos eram ofertas anônimas: três cartas sobre a silhueta da Doutrina, sem retrato nem voz (`bencaos-tradicoes.md`, `tela-de-bencao-e-carta.md` R5). Na Vertical Slice, **Mestres Ofertantes** cumpre o pilar **P1 (*Toda bênção é uma filosofia*)** e **P5 (*O mundo não se explica de uma vez*)**: cada oferta ganha a presença de um dos Mestres, e cada retorno ao Campus abre novas falas curtas que revelam o mundo aos poucos, por camadas de afinidade.

- **Os 3 Mestres canônicos:**
  - **Halvar** — Mestre da Lâmina / Forja (disciplina física, aço, corte limpo e responsabilidade do impacto).
  - **Maren** — Mestra do Selo / Ressonância (medida, distância, vibração do Fluxo e cálculo frio sob risco).
  - **Oreth** — Mestre do Véu / Pactos (custo oculto, sombra, vínculo e o preço que a Beira cobra em silêncio).
- **Na Tela de Bênção:** Quando `oferta_aberta` dispara, o sistema seleciona um Mestre ofertante para apresentar a oferta (retrato + 1 fala curta localizada, ≤ 120 caracteres), sem bloquear a leitura das cartas nem alterar o pool de 18 Tradições.
- **No Campus (Altar dos Mestres):** O jogador pode conversar com Halvar, Maren ou Oreth entre runs. A afinidade cresce por interações/escolhas ligadas ao Mestre, destravando falas contextuais (pós-vitória, pós-morte, primeira vez com uma arma, marcos de afinidade) sem nunca entregar exposição pesada de lore.

**Fantasia do jogador (MDA — Narrative, Fellowship, Discovery):** Sentir que não está descendo sozinho para a Beira: há três figuras com visões opostas sobre como sobreviver e o que vale o preço, que reagem ao que o jogador faz e revelam quem são uma frase por vez (Relatedness + P5).

## Detailed Design

### Core Rules

**R1. Os 3 Mestres canônicos (`MasterDef`).**
Cada Mestre é definido em dados (`MasterDef`, `Conteúdo orientado a dados`) com os campos mínimos: `id`, `chave_nome`, `chave_titulo`, `doutrina_associada`, `retrato_id`, `cor_selo`, `tom_voz` e lista de blocos de falas (`FalaMestreDef`).

| ID (`id`) | Nome | Título Canônico | Doutrina Associada | Tom e Filosofia |
|---|---|---|---|---|
| `halvar` | **Halvar** | Mestre da Lâmina / Forja | `lamina` | Direto, austero, pragmático. Valoriza postura, peso do golpe e enfrentar de frente. |
| `maren` | **Maren** | Mestra do Selo / Ressonância | `ressonancia` | Precisa, analítica, contida. Trata a Beira como equação de ritmo, alcance e controle. |
| `oreth` | **Oreth** | Mestre do Véu / Pactos | `pactos` | Lacônico, enigmático, observador. Fala do que sobra quando o ferro falha e do preço do vínculo. |

**R2. Seleção do Mestre na Tela de Bênção.**
- A escolha do Mestre ofertante na Tela de Bênção **não** altera o sorteio das 3 cartas (`Bênçãos (Tradições)` R4 continua dono exclusivo do pool e da raridade).
- Regra de seleção determinística (usando o mesmo contexto/seed da oferta, sem consumir reais dos fluxos `bencaos` ou `raridade`):
  1. Se a oferta contém ao menos uma Tradição associada à Doutrina de um dos 3 Mestres (`halvar`, `maren`, `oreth`), prioriza o Mestre correspondente à **primeira carta** da oferta que pertença a um deles.
  2. Caso nenhuma das 3 cartas tenha associação direta com um dos 3 Mestres, usa o Mestre da **arma equipada** se for um dos 3 (`lamina → halvar`, `ressonancia → maren`, `pactos → oreth`), ou alterna deterministicamente por `(indice_camara % 3)` entre `halvar`, `maren`, `oreth`.
- A Tela de Bênção recebe um payload `MestreOfertaView` (`id_mestre`, `nome`, `titulo`, `retrato_id`, `chave_fala`) junto com a exibição da oferta.

**R3. Falas contextuais na Tela de Bênção.**
- Ao abrir a Tela de Bênção, exibe **uma única fala curta** (máximo 2 linhas / ~120 caracteres) compatível com o contexto atual:
  - Prioridade 1: Fala de contexto específico não vista recentemente (ex.: `pos_chefe` ou `vida_baixa` `< 35%` ou `arma_associada`).
  - Prioridade 2: Fala neutra do catálogo do Mestre, escolhida sem repetir a última fala exibida do mesmo Mestre na sessão.
- A fala aparece imediatamente com o retrato e **nunca** exige clique extra para liberar a escolha das cartas (respeita a trava de 500 ms da `Tela de bênção` sem adicionar atrito).

**R4. Altar dos Mestres no Campus.**
- Ao interagir com `zona_mestres` no Campus (`campus-hub.md` R2), o jogador escolhe com qual dos 3 Mestres conversar (Halvar, Maren ou Oreth).
- Cada Mestre exibe:
  - Retrato, nome, título e indicador discreto de **Afinidade** (nível `0..5`).
  - Uma fala contextual baseada no **último evento de run** (`ultima_run_vitoria`, `ultima_run_morte`, `primeira_visita`, `arma_trocada`, ou fala de marco de afinidade).
- Falar com um Mestre no Campus após uma run concluída marca que o diálogo pós-run daquele Mestre foi lido (evita repetir a mesma reação ao abrir o altar duas vezes seguidas sem nova run).

**R5. Vínculo de Afinidade e Lore Progressiva (P5).**
- Cada Mestre possui um contador inteiro `afinidade_pontos` e um `nivel_afinidade` (`0` a `5`) persistidos por perfil (`Save e perfil`).
- **Fontes de afinidade (ganhos discretos, sem grind obrigatório):**
  - `+1` ponto ao conversar com o Mestre no Campus após uma run (máximo 1 vez por Mestre por run concluída).
  - `+1` ponto ao escolher na Tela de Bênção uma carta ofertada por aquele Mestre (ou ao completar uma run usando a Doutrina associada ao Mestre, `+2` pontos na vitória).
- **Limiares de nível de afinidade:**

| Nível | Pontos Acumulados | Desbloqueio Narrativo |
|---|---|---|
| `0` | `0–2` | Tratamento formal; falas introdutórias sobre o Limiar e a Doutrina |
| `1` | `3–6` | Reconhecimento do Iniciado; 1ª camada de história da Forja / Selo / Véu |
| `2` | `7–12` | Comentários sobre os outros Mestres e divergências filosóficas |
| `3` | `13–20` | Memórias da Beira antes da ruptura (lore fragmentada, P5) |
| `4` | `21–30` | Confiança plena; reflexões pessoais sobre o custo do juramento |
| `5` | `31+` | Vínculo consolidado; epígrafes raras na Tela de Bênção e no Campus |

- **Sem bônus mecânico escondido:** Na Vertical Slice, a afinidade desbloqueia exclusivamente diálogo e lore (P5), nunca poder de combate obrigatório, evitando transformar conversa em obrigação de otimização (P4).

**R6. Persistência (`PortaDeSecao` `[mestres]`).**
- Implementa `PortaDeSecao` (`ler(dados)` / `escrever()`, apenas `int`, `String`, `bool`, `Dictionary`, sem `float`):
  - Guarda por `id_mestre`: `afinidade_pontos: int`, `nivel_afinidade: int`, `falas_vistas: Array[String]` (ids de falas únicas/marcos já exibidos) e `conversou_pos_ultima_run: bool`.

### States and Transitions

| Estado | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| **Em Oferta (Run)** | `oferta_aberta` na Tela de Bênção | Seleciona `MestreOfertaView` e fala curta contextual; registra escolha se aplicável | **Inativo** (`bencao_escolhida`) |
| **No Altar (Campus)** | Interação em `zona_mestres` | Lista Halvar, Maren, Oreth; exibe retrato, nível de afinidade e fala contextual; marca `conversou_pos_ultima_run` | **Inativo** (fechar painel) |

### Interactions with Other Systems

| Sistema | Recebe de Mestres Ofertantes | Fornece a Mestres Ofertantes | Dono da interface |
|---|---|---|---|
| **Bênçãos (Tradições) (#19)** | — (sorteio permanece independente) | `oferta_aberta(cartas, trocas)`, `bencao_tomada` | Bênçãos (Tradições) |
| **Tela de bênção (#29)** | `MestreOfertaView` (retrato, nome, título, fala) | Exibição na lateral/fundo da tela de oferta | Tela de bênção |
| **Campus (hub) (#25)** | Dados do painel do Altar dos Mestres | Abertura via `zona_mestres`, encerramento | Campus (hub) |
| **Diálogo e lore (#26)** | Solicitação de texto localizado e seleção de fala | Chaves de texto, sistema de tags/condições de diálogo | Diálogo e lore |
| **Run e regiões (#18)** | — | `run_encerrada` (vitória/morte/abandono) para liberar conversa pós-run | Run e regiões |
| **Save e perfil (#27)** | `escrever()`, `ler(dados)` (`PortaDeSecao` `[mestres]`) | Carga e persistência em ponto seguro | Save e perfil |

## Edge Cases

- **Nenhuma fala contextual elegível no catálogo:** Fallback garantido para a lista de falas neutras do Mestre; nunca exibe chave de tradução crua ou texto vazio.
- **Todas as falas únicas de um nível já foram vistas:** O Mestre entra em rotação determinística/não-repetitiva das falas gerais do seu nível atual ou anteriores.
- **Save com `id_mestre` desconhecido:** Preservado como órfão pelo `Save` (ou ignorado na UI), sem quebrar a listagem dos 3 Mestres canônicos.
- **Afinidade acima do limite de nível 5 (`afinidade_pontos > 31`):** `nivel_afinidade` permanece travado em `5` (teto), sem erro nem overflow.
- **Troca de ofertas (`trocar()`) na Tela de Bênção:** O Mestre ofertante da tela atual permanece o mesmo durante aquela câmara (não pisca retrato nem troca fala no meio da troca de cartas).
- **Jogador nunca visita o Altar dos Mestres:** O loop de run e a Tela de Bênção funcionam normalmente; a afinidade ainda pode subir passivamente via escolhas de bênçãos, sem bloquear progressão.

## Dependencies

### Depends On (Upstream)
- **Bênçãos (Tradições) (#19)** — eventos `oferta_aberta` e `bencao_tomada`.
- **Diálogo e lore (#26)** — estrutura de dados de falas e localização (`Localização #34`).
- **Conteúdo orientado a dados (#1)** — `MasterDef`.
- **Save e perfil (#27)** — `PortaDeSecao` `[mestres]`.

### Depended On By (Downstream)
- **Tela de bênção e componente de carta (#29)** — integra retrato e fala do Mestre (substituindo o estado "sem Mestre" do MVP).
- **Campus (hub) (#25)** — zona `zona_mestres`.

## UI Requirements

- **Na Tela de Bênção:** Retrato do Mestre ancorado na borda/fundo sem sobrepor nenhuma das cartas; balão/faixa de fala discreta com fonte legível (respeitando `escala_ui` e acessibilidade); cor de acento alinhada à Doutrina do Mestre.
- **No Altar dos Mestres (Campus):** Seletor com os 3 Mestres (Halvar, Maren, Oreth), mostrando retrato, título, marcador discreto de afinidade (`0–5` runas/selos) e botão para conversar/ler próxima fala.
- **Indicador de novidade:** Um ponto/glifo discreto sobre `zona_mestres` no Campus quando há fala nova pós-run ou novo marco de afinidade disponível.

## Acceptance Criteria

- **AC-MO-01 [L] R1 — Catálogo dos 3 Mestres:** GIVEN o catálogo padrão da Vertical Slice, WHEN o sistema é carregado, THEN existem exatamente os 3 Mestres canônicos (`halvar`, `maren`, `oreth`) com suas Doutrinas (`lamina`, `ressonancia`, `pactos`) e retratos válidos.
- **AC-MO-02 [L] R2 — Independência do sorteio:** GIVEN qualquer estado de afinidade ou última conversa com Mestres, WHEN `Bênçãos` sorteia uma oferta, THEN o conjunto de 3 cartas e suas raridades são idênticos ao sorteio sem Mestres (zero influência no RNG de `bencaos`/`raridade`).
- **AC-MO-03 [L] R2 — Seleção do Mestre na oferta:** GIVEN uma oferta cuja primeira carta associável pertence à Doutrina `ressonancia`, WHEN o Mestre ofertante é resolvido, THEN `MestreOfertaView.id_mestre == "maren"`.
- **AC-MO-04 [L] R2 — Fallback determinístico de seleção:** GIVEN uma oferta sem cartas associadas exclusivamente a um dos 3 Mestres, WHEN o Mestre é resolvido, THEN usa o Mestre da arma equipada (se `lamina`/`ressonancia`/`pactos`) ou `(indice_camara % 3)` de forma determinística.
- **AC-MO-05 [I] R3 — Exibição na Tela de Bênção sem bloqueio:** GIVEN `oferta_aberta` emitida durante a run, WHEN a Tela de Bênção abre, THEN o retrato e uma fala curta não vazia do Mestre são exibidos imediatamente, e a escolha das cartas funciona após a trava padrão de 500 ms sem exigir fechar diálogo.
- **AC-MO-06 [L] Edge Case — Estabilidade na troca de oferta:** GIVEN uma Tela de Bênção aberta com `halvar`, WHEN o jogador aciona `trocar()`, THEN as cartas atualizam mas o Mestre exibido e sua fala permanecem estáveis na mesma oferta.
- **AC-MO-07 [I] R4 — Interação no Altar dos Mestres:** GIVEN `zona_focada == zona_mestres` no Campus, WHEN o jogador interage e seleciona `oreth`, THEN exibe retrato, título, nível de afinidade atual e uma fala contextual coerente com o último desfecho de run.
- **AC-MO-08 [L] R4/R5 — Ganho único de afinidade por conversa pós-run:** GIVEN uma run recém-encerrada, WHEN o jogador conversa com `halvar` duas vezes seguidas no Campus sem iniciar nova run, THEN `halvar.afinidade_pontos` sobe `+1` apenas na primeira conversa (`conversou_pos_ultima_run == true`).
- **AC-MO-09 [I] R5 — Reset de flag pós-run:** GIVEN `conversou_pos_ultima_run == true` para `maren`, WHEN uma nova run termina (`run_encerrada`), THEN `conversou_pos_ultima_run` volta a `false` permitindo nova fala e novo ponto de afinidade.
- **AC-MO-10 [L] R5 — Progressão de níveis de afinidade:** GIVEN `afinidade_pontos` atingindo `3`, `7`, `13`, `21` e `31`, WHEN o nível é recalculado, THEN `nivel_afinidade` avança respectivamente para `1`, `2`, `3`, `4` e `5` (com teto em `5`).
- **AC-MO-11 [L] R3 — Não repetição imediata e fallback:** GIVEN um Mestre com 3 falas neutras disponíveis, WHEN abre duas ofertas seguidas no mesmo nível, THEN não repete a mesma fala em sequência; se todas as falas de marco já foram vistas, recorre sempre a uma fala válida sem texto vazio.
- **AC-MO-12 [L] R6 — Persistência via `Save`:** GIVEN `halvar` com `afinidade_pontos == 8`, `nivel_afinidade == 2` e `falas_vistas == ["halvar_marco_1"]`, WHEN `escrever()` e depois `ler(dados)` são executados, THEN todo o estado de afinidade e falas vistas é restaurado exatamente sem `float`.

# Relatório Consolidado de Revisão UX — Khaeros MVP (`/ux-review all`)

> **Date**: 2026-11-18
> **Reviewer**: ux-designer (agente — `/ux-review all`)
> **Scope**: 100% da documentação de UX e Acessibilidade do MVP (`design/ux/*.md` + `design/accessibility-requirements.md`)
> **Platform Target**: PC (Windows), 1920 × 1080 de referência (1280 × 720 mínimo, ultrawide até 2580 × 1080) — teclado+mouse e gamepad
> **Accessibility Tier Committed**: **Standard** (com 3 itens elevados de Comprehensive/Exemplary e 2 desvios documentados em `design/accessibility-requirements.md`)
> **Overall Verdict**: **APPROVED** (0 bloqueantes, 0 dimensões não avaliadas)

---

## 1. Tabela Resumo (`/ux-review all`)

| Arquivo | Checklist | Status do Doc | Veredito | Bloqueantes | Notas Principais |
|---|---|---|---|---|---|
| `design/accessibility-requirements.md` | Tier & Padrão | `Approved` | **APPROVED** | 0 | Tier **Standard** formalizado; 12 opções do Art Bible §7.9 + zona morta, `hitstop_mult` e telégrafo 6 px cobertos; plano AR-01..15 completo. |
| `design/ux/interaction-patterns.md` | Phase 3C (Pattern Library) | `Approved` | **APPROVED** | 0 | Catálogo P1–P12 completo; foco único (ADR-0012 §3), `GrupoDeCartas` (`bencao`/`arma`/`maldicao`), travas 500/300 ms e padrões de modal/aviso alinhados. |
| `design/ux/hud.md` | Phase 3B (HUD Design) | `Approved` | **APPROVED** | 0 | Respeita margem segura de 48 px e retângulo central 60%×70% livre a 100%; cobre Vida, Fluxo, Esquiva, Fragmentos, Barra de Chefe, Bloco do Pacto, fios e prompt. |
| `design/ux/tela-de-bencao.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Anatomia 6 zonas (Art Bible §7.5), 8 estados de `GrupoDeCartas`, foco inicial no meio, `preco_revelado` antes de rachar a Vida, `trocar` vence `aceitar` com cargas. |
| `design/ux/tela-escolha-de-arma-e-pacto.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Pendência #6 de QA resolvida: foco inicial no modo `arma` abre em `ultima_arma` com fallback na 1ª carta (`lamina`, índice 0); modo `maldicao` em 2 passos (Campo → Reserva). |
| `design/ux/tela-consentimento-do-pacto.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Variantes `encontro` (V10/V11/V13) e `chefe` (V18 Pactuar/Exorcizar) no estado `BENCAO`; gravação no ponto seguro no mesmo passo. |
| `design/ux/pausa-e-opcoes.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Pausa sobre `JOGO` e `BENCAO` (Abandonar desabilitado por forma+motivo em `BENCAO`); 5 abas de Opções, remapeamento P12 e reset de perfil com confirmação dupla P4. |
| `design/ux/tela-fim-de-run.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Cobre os 12 campos de `ResumoDaRun` (R7-P) + saldo e painel de vínculo (V17); variantes `vitoria`, `morte`, `abandono`; trava de 500 ms na abertura. |
| `design/ux/tela-erros-do-catalogo.md` | Phase 3A (UX Spec) | `Approved` | **APPROVED** | 0 | Especificação criada e aprovada: paleta Tinta/Osso/Magenta, diagnósticos `V1–V11` + códigos dos donos, `Copiar relatório`, `Recarregar` (debug), `Sair` e operação digital `"Sem catálogo"` (Input R12). |

---

## 2. Conformidade com o Art Bible §7 (Direção Visual de UI/HUD)

| Seção da Art Bible | Requisito Visual e de Interação | Status nas Specs UX | Evidência / Onde é Atendido |
|---|---|---|---|
| **§7.1 Diegético, espacial e de tela** | Estado do jogador e decisões na camada de tela (sem grading regional); fios de Vida, números de dano e prompt de interação espaciais projetados na camada UI; telégrafos e portas no mundo. | **CONFORME** | `hud.md` §B–D; `adr-0012-ui-e-hud.md` Decisão 1 (`compositor.mundo_para_vista(X)`). |
| **§7.2 Tipografia** | Par Alegreya SC (H1 48–56 px, H2 32–36 px, H3 24–26 px) + Alegreya Sans (Corpo 24 px, Secundário 20 px, piso absoluto 18 px para metadados / 16 px em escala 85%); algarismos tabulares; folga para +40% de expansão de texto. | **CONFORME** | `accessibility-requirements.md` (Visual); seção §13 (Localização) de todas as 6 UX Specs de tela. |
| **§7.3 Contraste e Paleta (§4.1, §4.6)** | Tinta `#0D0E14` sobre Osso `#E6DFCF` / `#CFC6B4` (~14:1); painéis com texto ≥ 92% de opacidade (100% no alto contraste); Dourado só em ícones de ganho e anel de foco (com linha de tinta separadora); Magenta `#E0259C` reservado a preço e alerta de erro (≥ 24 px Bold sobre Tinta, nunca texto sobre Osso). | **CONFORME** | `tela-de-bencao.md` §5; `tela-erros-do-catalogo.md` §5; `hud.md` §D; `accessibility-requirements.md` AR-03. |
| **§7.4 Iconografia** | Contorno fechado grosso; tamanhos 96 / 64 / 48 / 32 px; vocabulário único entre porta, recompensa e HUD; proibido círculo/cone fechado de mundo fora de telégrafos (mira em osso tracejado). | **CONFORME** | `hud.md` §D; `tela-de-bencao.md` §5; `accessibility-requirements.md` (Tamanho da mira). |
| **§7.5 Anatomia da carta e telas** | Carta 320 × 500 px, 6 faixas fixas (Coroa 0–14%, Nome 14–24%, Vinheta 24–52%, Ganho 52–76%, Selo do preço/aviso 76–92%, Raridade 92–100%); botão desabilitado por forma (ícone riscado + "0"/motivo). | **CONFORME** | `tela-de-bencao.md` §5; `tela-escolha-de-arma-e-pacto.md` §5 (`aviso_texto` na faixa 76–92% sem magenta); `interaction-patterns.md` P2 e P11. |
| **§7.6 Navegação e foco único** | Um único modelo de foco para mouse, teclado e gamepad; teclas 1–3 só movem o foco sem confirmar; trava de 500 ms após assentar e 300 ms após troca/pausa; foco com ≥ 2 sinais além da cor (anel ≥ 4 px + escala 106% e subida 12 px). | **CONFORME** | `interaction-patterns.md` P1 e P2; todas as specs de tela (§7 e §11–12). |
| **§7.7 Sensação de animação e flashes** | Movimento suave a 60 qps (`t_ui`/`t_real`), tinta em degraus (~12 qps); nada de UI pulsa em loop no combate; preço racha por último (`preco_revelado`); limitador global de ≤ 3 flashes/s sempre ativo. | **CONFORME** | `interaction-patterns.md` (Animation Standards); `tela-de-bencao.md` §9–10; `accessibility-requirements.md` AR-05. |
| **§7.8 HUD mínimo e Vida baixa** | Margem segura 48 px; retângulo central 60%×70% livre a 100%; Vida em osso segmentado (opção Vida colorida); vinheta de Vida baixa ≤ 8% da borda e ≤ 40% opacidade + moldura partida. | **CONFORME** | `hud.md` §C–E, §K–L. |

---

## 3. Auditoria das 12 Opções de Acessibilidade (Art Bible §7.9 + Extensões MVP)

Todas as 12 opções obrigatórias do Art Bible §7.9, além das extensões motoras e visuais definidas nos GDDs e ADRs, estão mapeadas com dono, chave de persistência (`user://opcoes.cfg` / `user://input_binds.cfg`, ADR-0013 §8) e tela de configuração (`pausa-e-opcoes.md`):

| # | Opção (Art Bible §7.9) | Valores e Padrão | Chave (`opcoes.cfg`) | Onde é Especificada e Validada | Status |
|---|---|---|---|---|---|
| 1 | **Escala de UI** | 85 / 100 / 125 / 150% (padrão 100% em ≥1080p, 125% abaixo) | `[ui] escala` | `hud.md` §K, `tela-de-bencao.md` F1, `pausa-e-opcoes.md` §5 (AR-01) | **COMPLIANT** |
| 2 | **Legendas** | Lig/desl; 24/32/40 px; fundo 0–100% (padrão lig, 32 px, 75%, nome do falante) | `[acessibilidade] legendas_*` | Especificada em `accessibility-requirements.md` para a fatia vertical (MVP não tem fala/VO) | **COMPLIANT (N/A no MVP)** |
| 3 | **Tremor de câmera** | 0–100% em passos de 10% (padrão 100%) | `[acessibilidade] tremor_camera` | `pausa-e-opcoes.md` §5, `accessibility-requirements.md` (AR-07) | **COMPLIANT** |
| 4 | **Reduzir flashes** | Lig/desl (padrão desl; limitador de 3 flashes/s vale sempre) | `[acessibilidade] reduzir_flashes` | `tela-de-bencao.md` §10, `pausa-e-opcoes.md` §5 (AR-05) | **COMPLIANT** |
| 5 | **Redução de movimento** | Lig/desl (padrão desl; fades ≤ 300 ms, vinheta estática, foco 106% em corte seco, hitstop mantido) | `[acessibilidade] reduzir_movimento` | Todas as specs §10, `interaction-patterns.md` (AR-06) | **COMPLIANT** |
| 6 | **Vinheta de Vida baixa** | 0–100% (padrão 100%; moldura partida garante leitura a 0%) | `[ui] vinheta` | `hud.md` §E, §K, `pausa-e-opcoes.md` §5 | **COMPLIANT** |
| 7 | **Números de dano** | Ligado / Reduzido (só crítico e total) / Desligado (padrão ligado) | `[acessibilidade] numeros_dano` | `pausa-e-opcoes.md` §5, `accessibility-requirements.md` | **COMPLIANT** |
| 8 | **Número de Vida no HUD** | Lig/desl (padrão ligado: `"34/80"`) | `[ui] numero_vida` | `hud.md` §D, §K, `pausa-e-opcoes.md` §5 | **COMPLIANT** |
| 9 | **Vida colorida** | Lig/desl (padrão desligado; troca osso por vermelho-tinta como reforço) | `[ui] vida_colorida` | `hud.md` §K, `pausa-e-opcoes.md` §5 | **COMPLIANT** |
| 10 | **Alto contraste da UI** | Lig/desl (painéis 100%, molduras sólidas 3 px, raridade por linhas + palavra, osso puro sobre tinta pura) | `[ui] alto_contraste` | Todas as specs §11–12, `pausa-e-opcoes.md` §5 (AR-03) | **COMPLIANT** |
| 11 | **Tamanho da mira** | 1× / 1,5× / 2× (padrão 1×) | `[ui] tamanho_mira` | `accessibility-requirements.md`, `pausa-e-opcoes.md` §5 | **COMPLIANT** |
| 12 | **Fonte de leitura** | Alegreya Sans / Atkinson Hyperlegible Next | `[ui] fonte_leitura` | Todas as specs §11–12, `pausa-e-opcoes.md` §5 (AR-14) | **COMPLIANT** |
| +1 | **Remapeamento completo + Zona morta** | Até 3 binds/ação em teclado e gamepad separados + zona morta 0,05–0,40 | `user://input_binds.cfg` | `pausa-e-opcoes.md` §5–6, `interaction-patterns.md` P12 (AR-08, AR-09) | **COMPLIANT** |
| +2 | **Intensidade do telégrafo e Hitstop** | Contorno do telégrafo 4 → 6 px (`telegrafo_alto`); `hitstop_mult` ∈ {1,0; 0,5; 0,25} | `[acessibilidade] telegrafo_alto`, `hitstop_mult` | `pausa-e-opcoes.md` §5, `accessibility-requirements.md` | **COMPLIANT** |

---

## 4. Alinhamento com os 26 GDDs do MVP

Revisão cruzada entre os 26 GDDs aprovados do MVP (`design/gdd/systems-index.md`) e os artefatos de `design/ux/`:

1. **Conteúdo orientado a dados (`conteudo-orientado-a-dados.md`)**: UI Requirements 100% cobertos por `design/ux/tela-erros-do-catalogo.md` (contagem no topo, lista rolável com erros antes de avisos na ordem do manifesto, regras `V1–V11` e prefixos dos donos, `Copiar relatório`, `Recarregar` em debug, `Sair`, log em `user://content_errors.log` e fallback PT-BR embutido).
2. **Modificadores e atributos (`modificadores-e-atributos.md`)**: sistema interno; números escalados e custos negativos refletidos em `DadosDaCarta` (`tela-de-bencao.md`) e `LeituraDoHud` (`hud.md`).
3. **RNG com seed (`rng-com-seed.md`)**: formato F9 (`XXXX-XXXX · vX.Y.Z · cXXXX`) exibido e copiável em `pausa-e-opcoes.md` e `tela-fim-de-run.md`; campo de edição de seed em debug coberto pelo contexto `Texto` (`interaction-patterns.md` P1).
4. **Input e controle (`input-e-controle.md`)**: foco único (R9), contextos Jogo/Bênção/Transição/Menu/Pausa/Texto/Remapeando (R10), perda de foco da janela com barreira de retorno (R11), modo digital `"Sem catálogo"` (R12, em `tela-erros-do-catalogo.md`), ação `troca` (R1a) e `rotulo_acao(acao, dispositivo)` integrados em todas as specs.
5. **Cena 3/4 e câmera (`cena-3-4-e-camera.md`)**: opção de tremor de câmera (0–100%) e conversão `mundo_para_vista` dos elementos espaciais do HUD (`hud.md`).
6. **Pipeline visual (`pipeline-visual.md`)**: congelamento em gravura no estado `BENCAO`, vinheta na camada Pós, limitador de 3 flashes/s, opção `reduzir_flashes` e `telegrafo_alto` (6 px) refletidos em `hud.md`, `tela-de-bencao.md`, `pausa-e-opcoes.md` e `accessibility-requirements.md`.
7. **Movimento e esquiva (`movimento-e-esquiva.md`)**: chevrons de esquiva (cheio × contorno, contorno 3 px no alto contraste) e tremor de 80 ms em `esquiva_sem_carga` (`hud.md`).
8. **Combate núcleo (`combate-nucleo.md`)**: barra de Vida segmentada, escudo, recusas de morte, espera de `hitstop_ativo() == false` para rachar a Vida por dano, passe de morte bloqueando `ui_*` até abrir `tela-fim-de-run.md`.
9. **Armas das Doutrinas (`armas-das-doutrinas.md`)**: modo `arma` de `GrupoDeCartas` com as 3 armas do MVP (`lamina`, `ressonancia`, `pactos`), foco inicial em `ultima_arma` com fallback em `lamina` (resolvendo a pendência #6 de QA) e `aviso_texto` na Besta sem Maldição (`tela-escolha-de-arma-e-pacto.md`).
10. **Selo e Fluxo (`selo-e-fluxo.md`)**: gota de Fluxo com entalhe do custo, estado de recarga com forma própria e pisca 1× em `selo_sem_fluxo` (`hud.md`).
11. **Efeitos de status (`efeitos-de-status.md`)**: leitura por forma no mundo e marcadores `{status.<id>.<campo>}` resolvidos no texto da carta (`tela-de-bencao.md`, `accessibility-requirements.md`).
12. **Maldições (`maldicoes.md`)**: Bloco do Pacto (332 × 88 px, 12 px acima do grupo do jogador) com slot em campo, reserva, anel de Exaustão, marca de Saltando e Selo da Troca (`hud.md`).
13. **Telégrafos (`telegrafos.md`)**: canal exclusivo L* ≥ 88, contorno 4/6 px e par visual para todo aviso sonoro (`accessibility-requirements.md`).
14. **IA de inimigos e elites (`ia-de-inimigos-e-elites.md`)**: fio de Vida sob os pés (2 s após dano, 1,5× para elite) e distinção de elite por coroa + raio (`hud.md`).
15. **Chefes (`chefes.md`)**: barra de chefe no topo centro (~960 px, entalhe de fase em 50%, sem fio sob os pés) em `hud.md`; escolha `Pactuar` / `Exorcizar` no chefe `Subjugado` em `tela-consentimento-do-pacto.md`.
16. **Câmaras e ondas (`camaras-e-ondas.md`)**: transição com fade do HUD (`TRANSICAO`) e leitura espacial de portas e santuário (`hud.md`).
17. **Portas e recompensas (`portas-e-recompensas.md`)**: prompt espacial `Interagir` com glifo dinâmico e rótulo da recompensa acima do arco (`hud.md`, `interaction-patterns.md` P8).
18. **Run e regiões (`run-e-regioes.md`)**: fluxo completo de início (`tela-escolha-de-arma-e-pacto.md`), pausa e abandono (`pausa-e-opcoes.md`) e encerramento com os 12 campos de `ResumoDaRun` (`tela-fim-de-run.md`).
19. **Bênçãos (Tradições) (`bencaos-tradicoes.md`)**: oferta de 1–3 cartas, sem pular, troca vencendo confirmação no mesmo passo com cargas, `bencao_escolhida` retida até `tela_fechada` (`tela-de-bencao.md`, `interaction-patterns.md` P2/P3).
20. **Economia de Fragmentos (`economia-de-fragmentos.md`)**: contador no canto superior direito com soma `"+N"` na janela de 1,5 s (`hud.md`) e discriminativo de coletados/bônus/total/saldo em `tela-fim-de-run.md`.
21. **Save e perfil (`save-e-perfil.md`)**: avisos `PERFIL_CORROMPIDO`, `PERFIL_VERSAO_FUTURA`, `PERFIL_SAIR_SEM_SALVAR` (P5, fora de `JOGO`), `PERSIST_FALHA_GRAVAR` (P6) e reset de perfil com confirmação dupla (P4) e backup `.reset.bak` (`pausa-e-opcoes.md`, `interaction-patterns.md`).
22. **HUD (`hud.md` GDD)**: 100% espelhado em `design/ux/hud.md`.
23. **Tela de bênção e componente de carta (`tela-de-bencao-e-carta.md`)**: 100% espelhado em `design/ux/tela-de-bencao.md`, `design/ux/tela-escolha-de-arma-e-pacto.md` e `design/ux/interaction-patterns.md` (P2).
24. **Feedback de combate (VFX) (`feedback-de-combate.md`)**: números de dano (ligado/reduzido/desligado), `reduzir_flashes`, `reduzir_movimento` e `hitstop_mult` integrados em `pausa-e-opcoes.md` e `accessibility-requirements.md`.
25. **Telemetria local (`telemetria-local.md`)**: opções `[telemetria]` e paridade com `ResumoDaRun` e impressão do catálogo refletidas em `pausa-e-opcoes.md` e `tela-fim-de-run.md`.
26. **Vínculo e pactos (`vinculo-e-pactos.md`)**: cartão "O Primeiro Vínculo" (V3), Escolha do Pacto em 2 passos com `ultima_dupla` (V16/V16b em `tela-escolha-de-arma-e-pacto.md`), consentimento de encontro e chefe (V9/V10/V11/V13/V18 em `tela-consentimento-do-pacto.md`) e painel de vínculo no fim da run (V17 em `tela-fim-de-run.md`).

---

## 5. Revisão Individual por Documento

### 5.1 `design/ux/tela-erros-do-catalogo.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes (Propósito, Contexto/Posição/Entrada/Saída, Layout e hierarquia visual com paleta `#0D0E14`/`#CFC6B4`/`#E6DFCF`/`#E0259C`, Estados, Interação em modo `"Sem catálogo"`, Dados/Eventos, Transições, Acessibilidade, Localização/Fallback, 7 Critérios de Aceite, Open Questions).
- **GDD Alignment**: **ALIGNED** — cobre integralmente `conteudo-orientado-a-dados.md` (UI Requirements, R7, R9, R12, AC-07, AC-08, AC-51) e `input-e-controle.md` (R12 "Sem catálogo", AC-38).
- **Accessibility**: **COMPLIANT** — operável 100% por entradas digitais em teclado e gamepad (D-pad e botões), sem depender de `InputTuning`; erros e avisos diferenciados por texto `[ERRO]`/`[AVISO]` e ícone `✖`/`▲`.
- **Pattern Library**: **CONSISTENT** — usa P1 (Foco único), P6 (Confirmação discreta) e P8 (Prompt de botão).
- **Verdict**: **APPROVED**

### 5.2 `design/ux/tela-escolha-de-arma-e-pacto.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes.
- **GDD & QA Alignment**: **ALIGNED** — regra de foco inicial do modo `arma` explícita e alinhada à pendência #6 de `production/qa/pendencias-para-design-2026-11-16.md` e a `armas-das-doutrinas.md` R4: abre na carta de `ultima_arma` do perfil, com fallback obrigatório na 1ª carta (`lamina`, índice 0). Modo `maldicao` cobre V16/V16b e `aviso_texto` da Besta cobre R15-P.
- **Accessibility**: **COMPLIANT** — raridade e Doutrina por forma e palavra; slots Campo/Reserva por posição e texto.
- **Pattern Library**: **CONSISTENT** — usa P1, P2 (modos `arma` e `maldicao`), P10 e P11.
- **Verdict**: **APPROVED**

### 5.3 `design/ux/hud.md` (HUD Design — Checklist 3B)
- **Completeness**: 10/10 seções presentes (Filosofia, Arquitetura da Informação, Zonas, Elementos, Estados por Contexto, Hierarquia e Orçamento, Notificações, Plataforma, Acessibilidade, Ajustes e 8 Critérios de Aceite).
- **GDD Alignment**: **ALIGNED** — cobre `hud.md` (R1–R19), `chefes.md` (R10 barra de chefe), `maldicoes.md` (Bloco do Pacto) e `vinculo-e-pactos.md` (prompt Interagir).
- **Accessibility**: **COMPLIANT** — leitura por forma e valor (testável em cinza); redução de movimento troca sacudida por pulso de contorno e torna a vinheta estática.
- **Pattern Library**: **N/A** (documento tipo HUD Design, Phase 3B).
- **Verdict**: **APPROVED**

### 5.4 `design/ux/tela-de-bencao.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes.
- **GDD Alignment**: **ALIGNED** — cobre `tela-de-bencao-e-carta.md` (R1–R16, F1–F5, AC-TB-01..35) e `bencaos-tradicoes.md`.
- **Accessibility**: **COMPLIANT** — travas de 500/300 ms, teclas 1–3 apenas movem foco, alto contraste, redução de movimento e `reduzir_flashes`.
- **Pattern Library**: **CONSISTENT** — usa P1, P2 (modo `bencao`), P3, P9 e P11.
- **Verdict**: **APPROVED**

### 5.5 `design/ux/tela-consentimento-do-pacto.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes.
- **GDD Alignment**: **ALIGNED** — cobre `vinculo-e-pactos.md` (V9, V10, V11, V13, V15, V18) e `chefes.md` (R9, R9b).
- **Accessibility**: **COMPLIANT** — mundo congelado sem limite de tempo (P9), travas de confirmação, preço e ganho explícitos no rótulo do botão antes de confirmar.
- **Pattern Library**: **CONSISTENT** — usa P1, P9 e P10.
- **Verdict**: **APPROVED**

### 5.6 `design/ux/pausa-e-opcoes.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes.
- **GDD Alignment**: **ALIGNED** — cobre `run-e-regioes.md` (R6), `rng-com-seed.md` (F9), `input-e-controle.md` (R8, R10, R11) e `save-e-perfil.md` (R8, R11, UI Requirements).
- **Accessibility**: **COMPLIANT** — expõe todas as opções visuais, auditivas e motoras; confirmações destrutivas com foco inicial em Cancelar.
- **Pattern Library**: **CONSISTENT** — usa P1, P4, P5, P6, P7, P10, P11 e P12.
- **Verdict**: **APPROVED**

### 5.7 `design/ux/tela-fim-de-run.md` (UX Spec — Checklist 3A)
- **Completeness**: 15/15 seções presentes.
- **GDD Alignment**: **ALIGNED** — cobre `run-e-regioes.md` (R4–R8-P, os 12 campos do resumo), `vinculo-e-pactos.md` (V17 painel de vínculo) e `economia-de-fragmentos.md`.
- **Accessibility**: **COMPLIANT** — trava de 500 ms contra ataque segurado; distinção de vitória/morte/abandono pelo título textual; agrupamento cognitivo em 3 painéis de ≤ 5 itens.
- **Pattern Library**: **CONSISTENT** — usa P1, P6 e P8.
- **Verdict**: **APPROVED**

### 5.8 `design/ux/interaction-patterns.md` (Pattern Library — Checklist 3C)
- **Completeness**: Catálogo P1–P12 atualizado e sincronizado com todas as 7 specs de tela/HUD, incluindo a regra de foco inicial por modo em P2 (`bencao`, `arma`, `maldicao`), padrões de animação (`t_ui`/`t_real`) e padrões de som (`FilaDeSonsDeInterface`).
- **Verdict**: **APPROVED**

---

## 6. Conclusão e Veredito Final

- **Verdict**: **APPROVED**
- **Blocking issues**: **0**
- **Advisory issues**: **0**
- **Dimensions not assessed**: **0**

Toda a documentação de UX (`design/ux/*.md`) e de Acessibilidade (`design/accessibility-requirements.md`) do MVP está com status `Approved`, 100% consistente com a Art Bible §7, os ADRs 0001–0018 e os 26 GDDs do MVP, pronta para validação final e produção.

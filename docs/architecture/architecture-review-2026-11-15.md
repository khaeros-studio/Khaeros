# Architecture Review Report

Date: 2026-11-15
Mode: full
Workflow: standard
Engine: Godot 4.7.2 (pin 4.7)
GDDs Reviewed: 22 (sistemas do MVP; game-concept, systems-index, co-op-ganchos e os 4 cross-reviews não geram requisitos)
ADRs Reviewed: 14 (ADR-0001 a ADR-0014, todos Proposed)

Reviewed-Content-Hash: docs/architecture/adr-0001-orquestrador-do-passo.md bd0d0e9850294d72d9c8bdf051ed7d764521bfdc
Reviewed-Content-Hash: docs/architecture/adr-0002-canal-de-eventos.md 3b75e3cdc86e5f4d37a625de8d27430ca38f36c7
Reviewed-Content-Hash: docs/architecture/adr-0003-entidades-e-portadores.md ebcbf5916b956d524215dd8ea77741b4f4b284cb
Reviewed-Content-Hash: docs/architecture/adr-0004-catalogo-de-dados.md a0bf703b727e04d46ebbf5e4a8553a18eb137ef4
Reviewed-Content-Hash: docs/architecture/adr-0005-rng-deterministico.md 104cf352067703d902d1a24422a11a88c448003c
Reviewed-Content-Hash: docs/architecture/adr-0006-input-por-passo.md e24c31c5ba2580d713ca49d2a47077874f56950b
Reviewed-Content-Hash: docs/architecture/adr-0007-cena-viewport-e-camera.md 76006c9afba464bc67d74e622e8080b948bb27fd
Reviewed-Content-Hash: docs/architecture/adr-0008-movimento-e-colisao-propria.md 0e4ebbad92b55af399eafe66901dfa8e29da0077
Reviewed-Content-Hash: docs/architecture/adr-0009-atributos-e-modificadores.md 75a6af6cfa2ac44ac820d837269be6bcac08d492
Reviewed-Content-Hash: docs/architecture/adr-0010-resolucao-do-combate-no-passo.md d7007d5a7236fc00543d421d2e9643c4c4f05ced
Reviewed-Content-Hash: docs/architecture/adr-0011-pipeline-visual.md 3cc309bae086d2cda331466b9a6061c52ecac6d4
Reviewed-Content-Hash: docs/architecture/adr-0012-ui-e-hud.md 7f229756e578b6879cc9578adffab52138fcfb17
Reviewed-Content-Hash: docs/architecture/adr-0013-persistencia-do-mvp.md 0a3f44c6b938ff914223737ba152ea8e891fe770
Reviewed-Content-Hash: docs/architecture/adr-0014-telegrafos-geometria-e-teto.md 84e40eb8620682f705a0f461039e9ff4bd5a49e9
Reviewed-Content-Hash: design/gdd/armas-das-doutrinas.md e826f67cf4732dc18e3da67ce8022ac0eead6221
Reviewed-Content-Hash: design/gdd/bencaos-tradicoes.md 1b26182cc98e95ae6d8bf9fee97479473beebca7
Reviewed-Content-Hash: design/gdd/camaras-e-ondas.md f93786c0ea8fd8e7c62fccf84bd6dd789af82049
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md 6da8ab36d8cba469c85ab4e5e1df0a66d74bce87
Reviewed-Content-Hash: design/gdd/co-op-ganchos.md 5137ef14919eae61e0ed1cfd10439e7ad3df1874
Reviewed-Content-Hash: design/gdd/combate-nucleo.md db2f728062b005f44f6ed27bd4b3b3373f109c88
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 2e0e2d20ccf67e2a3a82a8f2d57dc714349844d6
Reviewed-Content-Hash: design/gdd/economia-de-fragmentos.md a5ce1a6d92b51e97855758d93c741db08e7d43c2
Reviewed-Content-Hash: design/gdd/efeitos-de-status.md 775878c77d4f226f9c13df9f5aca8db0e4e64b85
Reviewed-Content-Hash: design/gdd/feedback-de-combate.md c36c3f644a6cfdf17af007ededfdbd19d97f0638
Reviewed-Content-Hash: design/gdd/game-concept.md e58a8c46b597befb0f316b1abe68d4a245662397
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06.md 03a2b0f5830d1e46b0871abbb214bdc5a73185cb
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06b.md 99e8ac82721c627d39bba1ca0412034fc3cecb41
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-10.md 5a409f47f80b2ae57db7f9b3865ca9d7f3c47cf4
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-11.md 283a9974c9456cde415ee605b81d5f3112f5bb08
Reviewed-Content-Hash: design/gdd/hud.md a924d2bd817e746f7daeafe60d16df43ef07eb93
Reviewed-Content-Hash: design/gdd/ia-de-inimigos-e-elites.md daf83bb55784a03f32ef1605708bf76aa9847808
Reviewed-Content-Hash: design/gdd/input-e-controle.md c60b5642d3dfaefdc524bced8ac43e033ef8f87f
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md faa79d650b6bccc62b435d72945ef1a8e7a3e443
Reviewed-Content-Hash: design/gdd/movimento-e-esquiva.md 3d487d670c2df426e6b19b3f486432ba5b7e1c91
Reviewed-Content-Hash: design/gdd/pipeline-visual.md 5e4d20cf62d0285112db9357624aa7370b39102c
Reviewed-Content-Hash: design/gdd/portas-e-recompensas.md efe241b965803db38873d2e725eb7cec8718e612
Reviewed-Content-Hash: design/gdd/rng-com-seed.md e2c2dfce7af9f43639d330976ad51b806360a45c
Reviewed-Content-Hash: design/gdd/run-e-regioes.md 129c4860e80a090b38d90197cbea7c9939576f4c
Reviewed-Content-Hash: design/gdd/selo-e-fluxo.md 4266bc402bf5dc9edd648c3717c28d4e2950901b
Reviewed-Content-Hash: design/gdd/systems-index.md bd91159fd257e0a9e05954a6191dbc7102940a28
Reviewed-Content-Hash: design/gdd/tela-de-bencao-e-carta.md 3e34e9f992f3a97d0e8a6159811db2fb9a5d009e
Reviewed-Content-Hash: design/gdd/telegrafos.md 2062253eba164fdfc02f58325aecb74a06245c72
Reviewed-Content-Hash: design/gdd/telemetria-local.md 31b7fe6dd4debe27a6b165fd23b691d5b27bf4d1
Reviewed-Content-Hash: docs/architecture/tr-registry.yaml e75e5e2b46d3c423e37df4776e3ff6a696dd68b5
Reviewed-Content-Hash: docs/architecture/architecture.md 2aeb73d0176d48a39bd8c6432440481cf310f3a4
Reviewed-Content-Hash: docs/engine-reference/godot/VERSION.md f60fe6094466e6e09b054ac033e48a6ec59f6aca
Reviewed-Content-Hash: docs/engine-reference/godot/breaking-changes.md 4bc55e16796664ff88c7582c9f08e3530f7c94d4
Reviewed-Content-Hash: docs/engine-reference/godot/current-best-practices.md a45cd2c39a8ec53eaa3e924f39f93594e62085fd
Reviewed-Content-Hash: docs/engine-reference/godot/deprecated-apis.md 6a1353983e1db0d7bc0cc41a568b039495b5413c
Reviewed-Content-Hash: docs/engine-reference/godot/modules/animation.md ee51f50a46f8c63b771f62fe438947d4d84c59e3
Reviewed-Content-Hash: docs/engine-reference/godot/modules/audio.md c72af247505908a04f84a1dd3e765939efe700bd
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: docs/engine-reference/godot/modules/navigation.md 7ae18ffbd2c3230cb19d610373225bfba187a472
Reviewed-Content-Hash: docs/engine-reference/godot/modules/networking.md 6606880462a2241014f77feb9610c5611e659ec6
Reviewed-Content-Hash: docs/engine-reference/godot/modules/physics.md 3b6ac8947f3f3e8c9ac9e6e0ff6cac06fdb8d805
Reviewed-Content-Hash: docs/engine-reference/godot/modules/rendering.md 2a303185bb57eed31dd1151a036784820747b211
Reviewed-Content-Hash: docs/engine-reference/godot/modules/ui.md 30ad166ab8c4e92c15aa37ed3464483b92b7845b
Reviewed-Content-Hash: project.yaml 1865992db01b355d66f3917d4540b7fd667b7696
Reviewed-Content-Hash: .claude/docs/technical-preferences.md c4546c18d41094bece5de506127595c63feddd83
review-receipts: not stamped, no such file: docs/consistency-failures.md
Reviewed-Content-Hash: .claude/skills/architecture-review/SKILL.md 1a9d28aadbcbd26b5fc6b8ed1c64d73ae82b7b73
Reviewed-Content-Hash: .claude/skills/architecture-review/references/1-load.md 9a65759ebdbb2cb1f9744775bfed18cb25e76347
Reviewed-Content-Hash: .claude/skills/architecture-review/references/2-extract-requirements.md d08ea0b0e9ab9760b0d8bfe0cd9115f0bc40f8e2
Reviewed-Content-Hash: .claude/skills/architecture-review/references/3-traceability.md bb7b6b65c5e5e5b8869fa692413aa831615dede7
Reviewed-Content-Hash: .claude/skills/architecture-review/references/4-conflicts.md 0d30f8173b23248a32523a365b606dd1ce9642ab
Reviewed-Content-Hash: .claude/skills/architecture-review/references/5-engine.md 318ecbc1361d430badaf5dd8ce4cfc6ab0dff0ca
Reviewed-Content-Hash: .claude/skills/architecture-review/references/6-document-coverage.md dcce78482ec2ce60048989b6f9d1f797dd0a9a0e
Reviewed-Content-Hash: .claude/skills/architecture-review/references/7-report.md a007fd66bdac87812dc272e4b14cd231174e979d
Reviewed-Content-Hash: .claude/skills/architecture-review/references/8-write.md bf6d8946fc7b9e19eda7f65503a5c8f593a0d2b1
Reviewed-Content-Hash: .claude/skills/architecture-review/references/9-handoff.md fd5f681f4c3517c6a2e388c6d78075d82dded22e

> Revisão independente: a sessão que escreveu os ADRs só orquestrou. Rastreio feito por 4 subagentes (grupos de GDDs) e Fases 4–6 por um subagente `technical-director`, todos sem editar o repo. Freshness check: RECEIPT NONE (primeiro relatório com recibo).

---

### Traceability Summary
Total requirements: 270
✅ Covered (Accepted): 0
🟡 Covered (Proposed): 219
⚠️ Partial: 45
❌ Gaps: 6

Nenhum ADR está Accepted, então nenhum requisito conta como ✅. O caminho é `/architecture-decision accept ADR-NNNN`, começando pelo 0001. A matriz completa está em [requirements-traceability.md](requirements-traceability.md) e os IDs passam a ser permanentes em [tr-registry.yaml](tr-registry.yaml).

### Coverage Gaps (no ADR exists)

| TR-ID | GDD | Requisito | Origem | Domínio | ADR(s) | Status |
|---|---|---|---|---|---|---|
| TR-feedback-008 | feedback-de-combate | Ganchos de áudio: um som por gancho por passo; limite de vozes por gancho e total, por prioridade | R9, F4 | Áudio | — | ❌ |
| TR-armas-008 | armas | Chave derivada `<chave_nome>_DESC` e nomes canônicos validados, sem campo novo | R4, R8, AC-AR-33/34 | Dados/localização | — | ❌ |
| TR-selo-004 | selo | "Investida ativa" lida pelo Combate no item 5 antes do disparo, guardada e entregue ao Selo | R2.2, AC-SF-10 | Comunicação entre sistemas | — | ❌ |
| TR-telegrafos-014 | telegrafos | Áudio: tom que sobe com p e estalo no disparo, no máximo 3 telégrafos soando | Visual/Audio | Áudio | — | ❌ |
| TR-run-007 | run-e-regioes | Resumo de 10 campos montado uma vez e imutável, lido pela tela final e pela Telemetria | R7, AC-RN-18 | estrutura de dados | — | ❌ |
| TR-economia-001 | economia-de-fragmentos | `ContaFragmentos` injetada (sem singleton), com `saldo` que atravessa as runs e `coletados_run` | R1, AC-EF-01/15 | composição / ciclo de vida | — | ❌ |

Sugestões:
- **TR-run-007, TR-economia-001** (e ~12 parciais de Run, Câmaras, Portas, Bênçãos e Economia): `/architecture-decision "Ciclo da run e composição"` — Feature, risco BAIXO.
- **TR-feedback-008, TR-telegrafos-014**: `/architecture-decision "Áudio: ganchos e vozes"` — Apresentação, risco MÉDIO (API de áudio não verificada).
- **TR-selo-004**: emenda no ADR-0010 (guardar "investida ativa" do item 5 e entregar ao Selo) — Core, risco BAIXO.
- **TR-armas-008**: emenda no ADR-0004 (chave `_DESC` derivada e validação de nomes canônicos) — Foundation, risco BAIXO.

### Partial Coverage

| TR-ID | GDD | Requisito | Origem | Domínio | ADR(s) | Status |
|---|---|---|---|---|---|---|
| TR-conteudo-014 | conteudo-orientado-a-dados | Script de importação F1–F6 em `tools/content-import/` + teste de paridade com o cânone | Formulas (Importação), F1–F6 | Pipeline de dados | ADR-0004 | ⚠️ |
| TR-conteudo-015 | conteudo-orientado-a-dados | Orçamento de carga: mediana ≤ 250 ms e validação ≤ 30 ms (advisory) | AC-38 | Desempenho | ADR-0004 | ⚠️ |
| TR-rng-012 | rng-com-seed | Texto da seed (F9) na pausa, morte, vitória e debug; copiar para a área de transferência; campo de seed no debug | R8, F9, UI Requirements | UI/plataforma | ADR-0005 | ⚠️ |
| TR-pipeline-009 | pipeline-visual | Memória de textura 512 MiB com alerta em 448; os tetos somam 504 MiB (VV13) | R9 | Desempenho/memória | ADR-0011 | ⚠️ |
| TR-feedback-007 | feedback-de-combate | Números de dano: faixas por alvo, agregação de 300 ms, teto de 6 e regra de saída | R6, F1, F2, F5 | Estrutura de dados/render | ADR-0002 | ⚠️ |
| TR-feedback-012 | feedback-de-combate | Opções de acessibilidade aplicadas pelos donos; nenhuma resposta as contorna | R7 | Acessibilidade/persistência | ADR-0007, ADR-0011, ADR-0013 | ⚠️ |
| TR-combate-nucleo-017 | combate-nucleo | Orçamento de CPU: itens 3, 5, 7, 8 e 9 com p99 ≤ 0,3 ms/passo | AC-81 | Desempenho | ADR-0010 | ⚠️ |
| TR-combate-nucleo-018 | combate-nucleo | Latência do golpe ≤ 2 passos + 1 quadro (sinal de fim de desenho do quadro) | AC-92 | Desempenho/plataforma | ADR-0010, ADR-0006 | ⚠️ |
| TR-armas-001 | armas | `WeaponDef` com exatamente 7 campos e `AttackDef` como sub-recurso; propriedade desconhecida é erro | R1, AC-AR-01, AC-AR-30 | Estrutura de dados | ADR-0004 | ⚠️ |
| TR-armas-003 | armas | Injeção da arma no começo da run: portador com `vida_max`/`velocidade` base, Combate com os dois `AttackDef` | R9, AC-AR-06, AC-AR-36 | Comunicação entre sistemas | ADR-0009, ADR-0010 | ⚠️ |
| TR-armas-004 | armas | Tela de escolha antes da run com o componente de carta, navegável por teclado, mouse e gamepad | R4, AC-AR-08/09/11/12 | UI/entrada | ADR-0012, ADR-0006 | ⚠️ |
| TR-armas-005 | armas | Estados Escolhendo → Equipada → Encerrada; arma fixa durante a run | States, AC-AR-10 | Tempo/estados de jogo | ADR-0001 | ⚠️ |
| TR-selo-012 | selo | Eventos `selo`, `selo_sem_fluxo` e `selo_fim` emitidos pelo Selo | R2, R3 | Comunicação entre sistemas | ADR-0002 | ⚠️ |
| TR-status-008 | efeitos-de-status | Troca de câmara limpa todos os status (nada passa para a câmara nova) | R7, AC-ST-16 | Ciclo de vida | ADR-0001, ADR-0003 | ⚠️ |
| TR-status-009 | efeitos-de-status | Número agregado por inimigo: período em passos vivos, resto acumulado, animação no relógio de apresentação, toggle do Combate | R8, F5, AC-ST-19/20 | Apresentação / tempo | ADR-0002, ADR-0011 | ⚠️ |
| TR-status-012 | efeitos-de-status | Consulta `estado(inimigo)` para HUD/VFX; sinais pequenos e fixos, no máximo 3, um só com > 9 inimigos marcados | R6, Visual/Audio, AC-ST-23 | Apresentação | ADR-0011, ADR-0003 | ⚠️ |
| TR-telegrafos-013 | telegrafos | Duas passadas (preenchimento z −5, contorno z 5), crescimento sem pulsar, contorno de 6 px na opção de acessibilidade | Visual/Audio, R8, AC-TG-22/23 | Render / acessibilidade | ADR-0011, ADR-0007 | ⚠️ |
| TR-ia-003 | ia-de-inimigos-e-elites | Máquina de fases (surgindo, aproximação, preparo, execução, recuperação) com timers em passos vivos | R3–R7, States, AC-IA-01..10 | Estado | ADR-0003, ADR-0014 | ⚠️ |
| TR-ia-006 | ia-de-inimigos-e-elites | Movimento dos inimigos: obstáculos e parede por passo e separação par a par ao fim do item 7 | R9, AC-IA-13/14 | Colisão | ADR-0008 | ⚠️ |
| TR-ia-009 | ia-de-inimigos-e-elites | `ranged` só inicia o preparo dentro do retângulo visível da câmera (+ margem) | R11, AC-IA-19/28 | Comunicação (câmera → regra) | ADR-0007 | ⚠️ |
| TR-movimento-006 | movimento-e-esquiva | Esquiva pelo buffer do Input; toque sem carga durante congelamento emite `esquiva_sem_carga` no 1º passo vivo | R5, Input R6 | Entrada | ADR-0006, ADR-0008 | ⚠️ |
| TR-movimento-014 | movimento-e-esquiva | Orçamento de CPU do Movimento ≤ 0,2 ms/passo (provisório) | AC [P] | Desempenho | ADR-0001 | ⚠️ |
| TR-camaras-001 | camaras-e-ondas | Câmaras são o dono único de p e `p_max`; a chave do RNG é o índice da câmara (santuário incluído), não p | R3, AC-CO-01 | interface entre sistemas | ADR-0005 | ⚠️ |
| TR-camaras-009 | camaras-e-ondas | Portas: estado, posição, alcance de 111 px, interação pede a Transição; ignorada em hitstop e Transição | R13, AC-CO-18/19 | input / estado de jogo | ADR-0001, ADR-0006 | ⚠️ |
| TR-portas-004 | portas-e-recompensas | Última câmara jogável: sem recompensa e sem porta; contrato `fim_da_run` com a Run | R2 passo 1b, R6, AC-PR-24 | interface entre sistemas | ADR-0002 | ⚠️ |
| TR-portas-005 | portas-e-recompensas | `porta_escolhida(i)` das Câmaras vira a recompensa da próxima câmara e é entregue à Run; tudo injetado, sem SceneTree | R9, R11, AC-PR-16/20 | interface / composição | ADR-0002 | ⚠️ |
| TR-portas-006 | portas-e-recompensas | Fragmentos creditados na `ContaFragmentos` injetada; cura lê `vida_max` do portador | R4, R5, AC-PR-04/05 | interface entre sistemas | ADR-0009 | ⚠️ |
| TR-portas-008 | portas-e-recompensas | Evento de porta escolhida com `tipo` e `opcoes` (para Telemetria e HUD) | Dependencies; Telemetria R4, OQ 7 | comunicação | ADR-0002 | ⚠️ |
| TR-run-001 | run-e-regioes | Máquina de estados da run (Sem run → Escolha de arma → Ativa → Encerrada) coordenada com os estados do orquestrador | R1, AC-RN-01/17 | estado de jogo | ADR-0001, ADR-0005 | ⚠️ |
| TR-run-004 | run-e-regioes | Vitória: `camara_limpa` → `fim_da_run` → crédito → `run_encerrada`; tela final sem Transição | R4, AC-RN-09/10/11 | comunicação / estado de jogo | ADR-0002 | ⚠️ |
| TR-run-008 | run-e-regioes | `nova_run`: reset total dos sistemas da run, descarte da seed e dos fluxos; o saldo da Economia fica fora do reset | R8, AC-RN-19/20 | ciclo de vida | ADR-0005, ADR-0003, ADR-0009 | ⚠️ |
| TR-bencaos-002 | bencaos-tradicoes | Registro de tomadas (sem repetir), `restantes()` e `tomadas()`, zerado na Nova run | R2, R8, R9, AC-BN-15/16 | ciclo de vida | ADR-0009 | ⚠️ |
| TR-bencaos-005 | bencaos-tradicoes | Troca e escolha no mesmo passo: a troca vence; não dá para pular | R5, R6, AC-BN-10 | input / UI | ADR-0012 | ⚠️ |
| TR-bencaos-006 | bencaos-tradicoes | Contrato síncrono `pedir_oferta(região, índice)`, `sem_bencao`, `oferta_ja_aberta`, `restantes()` | R3, AC-BN-02/17 | interface entre sistemas | ADR-0002 | ⚠️ |
| TR-bencaos-007 | bencaos-tradicoes | Eventos `oferta_aberta`, `oferta_trocada`, `bencao_tomada` para a Tela, o HUD, o Áudio e a Telemetria | R5, OQ 9 | comunicação | ADR-0002, ADR-0012 | ⚠️ |
| TR-bencaos-009 | bencaos-tradicoes | Texto da carta com o número da raridade, arredondado como no Modificadores, em chave de tradução | R10, AC-BN-18 | dados / localização | ADR-0009, ADR-0012 | ⚠️ |
| TR-economia-004 | economia-de-fragmentos | Ordem com a Run (lê `coletados_run` antes da vitória; usa o `efetivo`); nada creditado se a morte cai no mesmo passo | R4, AC-EF-21/22/28 | interface / tempo do passo | ADR-0002 | ⚠️ |
| TR-economia-006 | economia-de-fragmentos | `nova_run()` zera `coletados_run` e mantém o saldo | R6, AC-EF-15/16 | ciclo de vida | ADR-0005 | ⚠️ |
| TR-economia-007 | economia-de-fragmentos | Run e Portas aceitam a Economia ausente (dublê ou nula) sem quebrar | Dependencies | composição | — | ⚠️ |
| TR-hud-012 | hud | Opções de acessibilidade do HUD (escala, número de Vida, Vida colorida, alto contraste, vinheta) aplicadas e guardadas | R13, AC-HD-25 | persistência / UI | ADR-0012, ADR-0013 | ⚠️ |
| TR-tela-bencao-002 | tela-de-bencao-e-carta | `CartaView` montada pela Bênçãos a partir do `BoonDef` (glifo, `icone_ganho`, chave do preço com `{valor}`) | R2, AC-TB-21 | dados / interface | ADR-0004, ADR-0012 | ⚠️ |
| TR-tela-bencao-006 | tela-de-bencao-e-carta | Troca e confirmar no mesmo quadro: só `trocar()`; troca sem carga desabilitada | R8, AC-TB-13–15 | input | ADR-0012 | ⚠️ |
| TR-tela-bencao-010 | tela-de-bencao-e-carta | Acessibilidade: alto contraste, redução de movimento, "Reduzir flashes" pelo limitador | R14, AC-TB-22/33 | UI / renderização | ADR-0011, ADR-0012 | ⚠️ |
| TR-telemetria-001 | telemetria-local | Um `.jsonl` por sessão em `user://`, descarga a cada linha, campos comuns, última linha pode ficar truncada | R2, R3, R10, AC-TL-01–03/22/23 | persistência | ADR-0013 | ⚠️ |
| TR-telemetria-003 | telemetria-local | Esquema dos 10 eventos do MVP e campos que outros sistemas ainda não emitem (causa da morte, porta escolhida, "câmara entrou", passo vivo) | R4, R5, OQ 7 | comunicação | ADR-0002 | ⚠️ |

Temas recorrentes: catálogo de eventos incompleto no ADR-0002 (Selo, Bênçãos, Portas, campos da Telemetria); contrato de `status.tick` e limpeza de status sem dono; orçamentos de CPU sem método de medição; opções de acessibilidade sem lugar de persistência.

### Cross-ADR Conflicts, ordem, engine e cobertura do documento

Escopo: ADR-0001..0014 (todos Proposed). Grafo gerado por `.claude/scripts/adr-dep-graph.sh`.

### Fase 4 — Conflitos

Nenhum conflito bloqueante (🔴). Posse de dados, hitstop (Combate), lista de inimigos (IA), `GeometriaDeAcerto` (0010) e ordem do item 7 estão coerentes após a revisão cruzada.

🟡 Menores:
1. **ADR-0010 interno**: o campo Verification Required (1) ainda pede teste de `round()/roundi()` no meio exato; a Decision (linha 70) e o ADR-0009 §2 proíbem `round()`. Corrigir para "teste de `arredondar_meio_longe_do_zero` (ADR-0009)".
2. **Arestas faltando no Depends On** (o grafo fica limpo por omissão):
   - 0008 → 0009 (Corte consome `valor`/`multiplicador_de_dano`; o 0009 diz "ADR-0008 já consome").
   - 0012 → 0009 (`fontes_de`) e 0012 → 0011 (shader `ui`, `sem_grading`, vinheta).
   - 0011 → 0014 (pool por `VistaDeTelegrafo.slot`). Hoje 0011 e 0014 se declaram mutuamente "Enables": ciclo implícito. Direção sugerida: 0011 depende de 0014; tirar 0011 do "Knowledge Risk/depende" do 0014 (só Enables).
   Nenhuma das arestas cria ciclo.
3. **Status sem ADR**: contrato de `status.tick` (item 7) sem dono formal.
4. **Orçamento de CPU**: não há orçamento total do passo; 0003–0008 não têm Performance Implications. Telemetria pode gastar até 3 ms síncronos no passo da morte (0013), não somado a Combate 0,3 + Movimento 0,2 ms.

### Ordem de dependência

Sem ciclos declarados. NO_DEPS_SECTION: 0003, 0004, 0005 (template curto; posicionados como sem dependências por omissão, mas o architecture.md diz 0003→0001/0002, 0004→0001–0003, 0005→0001/0004 — lacuna estrutural).

ORDER: 0001, 0003*, 0004*, 0005*, 0002, 0006, 0007, 0009, 0013, 0008, 0011, 0012, 0010, 0014.
Com as arestas do item 2: …0009, 0013, 0008, 0010, 0014, 0011, 0012.
Todas as dependências estão em Proposed: nenhuma implementável com segurança até 0001/0002 serem aceitos.

### Fase 5 — Engine (checagem feita pelo revisor, sem especialista)

- Versão: todos citam 4.7 / pin 4.7.2. Sem referência obsoleta.
- Engine Compatibility: 11/14. Faltam 0003, 0004, 0005 (têm só seção de verificação/experimento).
- APIs depreciadas: nenhuma. `device == 0` e `DisplayServer.AccessibilityLiveMode` aparecem só como o que evitar (0006, 0012 usam a forma correta).
- Pós-corte: `@abstract`, override tipado, foco duplo, `offset_transform_*`, `store_*`→bool, D3D12, Shader Baker confirmados na referência; sem suposições contraditórias entre ADRs (0001 e 0011 concordam que `global_shader_parameter_set` é NOT SOURCEABLE).
- NOT SOURCEABLE pendente: 0001 (6 itens), 0002 (3), 0010 AC-92, 0011 E1–E7, 0012 E1–E6, 0013 E-P1–E-P6, 0014 (4), 0009 float64.

GDD Revision Flags: nenhum — nenhuma suposição de GDD contradiz comportamento verificado. Condicional: Pipeline visual (LUT global sampler) e Combate AC-92 dependem de E2/AC-92; se o experimento falhar, revisar.

### Fase 6 — Cobertura do architecture.md

- Todos os sistemas MVP do systems-index têm módulo. Não-MVP ausentes por escopo.
- Arquitetura órfã: Orquestrador (intencional, sem GDD); Persistência (ADR-0013) não aparece como módulo em Module Ownership.
- Desatualizado: linha do Orquestrador cita `SceneTree.paused: NEEDS VERIFICATION` (padrão proibido no registro); "ADR-0001 ... não foi revisado" na rastreabilidade; Status sem ADR não listado em Required ADRs.


### GDD Revision Flags
Nenhum agora. Condicionais: Pipeline (se E2 falhar) e Combate (se AC-92 não tiver fonte).

---

### Verdict: CONCERNS

Toda a cobertura repousa em ADRs Proposed (teto CONCERNS); 6 gaps e 45 parciais, nenhum na Foundation ou no Core que bloqueie (TR-armas-008 é emenda de dado, TR-selo-004 é emenda pontual). Nenhum conflito 🔴.

### Required ADRs
1. Emendas pequenas: ADR-0010 (TR-selo-004, `round()` em Verification Required, dono de `status.tick`), ADR-0004 (TR-armas-008), ADR-0002 (catálogo de eventos), arestas de dependência (0008→0009, 0012→0009, 0012→0011, 0011→0014) e Engine Compatibility nos ADRs 0003–0005.
2. ADR-0015 — Ciclo da run e composição.
3. ADR-0016 — Áudio: ganchos e vozes.
4. Aceite dos ADRs na ordem de dependência, começando pelo ADR-0001.

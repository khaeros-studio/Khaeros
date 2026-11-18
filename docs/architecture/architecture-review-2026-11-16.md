# Architecture Review Report

Date: 2026-11-17 (atualizado após aceite dos 18 ADRs e fechamento dos experimentos EX-0001..0016; original 2026-11-16)
Mode: full
Workflow: standard
Engine: Godot 4.7.2 (pin 4.7)
GDDs Reviewed: 26 (sistemas do MVP, inclusive maldicoes, chefes, vinculo-e-pactos e save-e-perfil)
ADRs Reviewed: 18 (ADR-0001 a ADR-0018, todos Accepted em 2026-11-16 e verificados com EX-0001..0016 em 2026-11-17)

Reviewed-Content-Hash: docs/architecture/adr-0001-orquestrador-do-passo.md 3b533db36083942768383b01988de9e577d1d320
Reviewed-Content-Hash: docs/architecture/adr-0002-canal-de-eventos.md 6734fc2ff33f4f1a4edcab028cd5614a50e466e8
Reviewed-Content-Hash: docs/architecture/adr-0003-entidades-e-portadores.md 470cf29f32b1cf795e8bf330ed9665a3506832f0
Reviewed-Content-Hash: docs/architecture/adr-0004-catalogo-de-dados.md 61dcdc11f6f22be001c2eebdd25aa65dd4516221
Reviewed-Content-Hash: docs/architecture/adr-0005-rng-deterministico.md afabc7f1a3bd987242f535435526b8180ef317e1
Reviewed-Content-Hash: docs/architecture/adr-0006-input-por-passo.md e84f81ea01121b2c64c249218e9e89dbf3e07e59
Reviewed-Content-Hash: docs/architecture/adr-0007-cena-viewport-e-camera.md 76006c9afba464bc67d74e622e8080b948bb27fd
Reviewed-Content-Hash: docs/architecture/adr-0008-movimento-e-colisao-propria.md 79cdb29cec4daea61f4a11e47271f5e01044cc26
Reviewed-Content-Hash: docs/architecture/adr-0009-atributos-e-modificadores.md 17f86fd5c28e2dde070844e63cf5a33210c93fba
Reviewed-Content-Hash: docs/architecture/adr-0010-resolucao-do-combate-no-passo.md c3e8e1f05e86bfc5be6439e8a4a9f1fd9c743348
Reviewed-Content-Hash: docs/architecture/adr-0011-pipeline-visual.md ceee09c85e42774f3f641f954f8fb29b359eb933
Reviewed-Content-Hash: docs/architecture/adr-0012-ui-e-hud.md e624efb5f0ab3247819895dd8beb5c3facf89e87
Reviewed-Content-Hash: docs/architecture/adr-0013-persistencia-do-mvp.md 86659f001da164587e1e8b3dc696f4c7a88e08a8
Reviewed-Content-Hash: docs/architecture/adr-0014-telegrafos-geometria-e-teto.md 8da40d4bc420a853dd0a4a86e0d9af5b0e7a34fe
Reviewed-Content-Hash: docs/architecture/adr-0015-ciclo-da-run-e-composicao.md 812e45d333c4c1b6984acb4ed761df81cb3fa8b5
Reviewed-Content-Hash: docs/architecture/adr-0016-audio-ganchos-e-vozes.md 97a5130d07ceaf8b4879f34f21d630f34b7a871d
Reviewed-Content-Hash: docs/architecture/adr-0017-aliados-e-invocacoes.md 5e81eb36fda34a83a39adb5351c314929cbdca94
Reviewed-Content-Hash: docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md 9daf2f83e8034aadc25a6c753b29efcde9af155d
Reviewed-Content-Hash: docs/architecture/architecture.md 3a6b3c244635f06c3b011b37fe17ffb023b961a3
Reviewed-Content-Hash: design/gdd/armas-das-doutrinas.md 9c266479a89d63c09a6004e2b85d013200110b93
Reviewed-Content-Hash: design/gdd/bencaos-tradicoes.md d738546ec4695e371b9cd8c632f95d6d1b45320c
Reviewed-Content-Hash: design/gdd/camaras-e-ondas.md 25976a4e0156395f91e86071b8ab48e9dfd7a742
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md 6da8ab36d8cba469c85ab4e5e1df0a66d74bce87
Reviewed-Content-Hash: design/gdd/chefes.md d1067e2cb645305970ad4138e2af66ed77c56776
Reviewed-Content-Hash: design/gdd/co-op-ganchos.md 5137ef14919eae61e0ed1cfd10439e7ad3df1874
Reviewed-Content-Hash: design/gdd/combate-nucleo.md a68c7f9be46f510d60093cd5909add7dbf6a15d1
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 5f88819624a4cf826f4c4bf94b24f805bcac643f
Reviewed-Content-Hash: design/gdd/economia-de-fragmentos.md 7580ba7cd0b18dfb039d6d2a8416ee283598e5f6
Reviewed-Content-Hash: design/gdd/efeitos-de-status.md cd1b09b860e63a2bff46cb4b5abe4082f7b31362
Reviewed-Content-Hash: design/gdd/feedback-de-combate.md 656f0b03316895103e51bd9fbd2c61a8247789b9
Reviewed-Content-Hash: design/gdd/game-concept.md 8e2a146414f594eda02b24eec9405926491d6495
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06.md 03a2b0f5830d1e46b0871abbb214bdc5a73185cb
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06b.md 99e8ac82721c627d39bba1ca0412034fc3cecb41
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-10.md 5a409f47f80b2ae57db7f9b3865ca9d7f3c47cf4
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-11.md 283a9974c9456cde415ee605b81d5f3112f5bb08
Reviewed-Content-Hash: design/gdd/hud.md cfedf57ff403b3b49c4a3f493d0cba5b0b1e1bde
Reviewed-Content-Hash: design/gdd/ia-de-inimigos-e-elites.md a50f6366ab26f8ee86ddd4d175e328593027447c
Reviewed-Content-Hash: design/gdd/input-e-controle.md 417bbae59e7a6a79ad05b5e6d77aff70ab82d586
Reviewed-Content-Hash: design/gdd/maldicoes.md 128201c59d3ee1dc5d32d928dd61227478f50776
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md 0a2e475bf83ef6539231c2e5c42898e0ea9aa4a5
Reviewed-Content-Hash: design/gdd/movimento-e-esquiva.md 3d487d670c2df426e6b19b3f486432ba5b7e1c91
Reviewed-Content-Hash: design/gdd/pactos-decisoes-a-confirmar.md af3866b7f84de8a498fe331b92c8e5fa12db4529
Reviewed-Content-Hash: design/gdd/pipeline-visual.md 72aa5605ab3b30b640706cce0dc00db71b3f81bd
Reviewed-Content-Hash: design/gdd/portas-e-recompensas.md 7f7e092419d01ec634b756333aede522d21957a2
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7e303091e57c041df88895dbe3c33d7626cad25b
Reviewed-Content-Hash: design/gdd/run-e-regioes.md b3c35071b91ebe5338b495079b804062efab5b07
Reviewed-Content-Hash: design/gdd/save-e-perfil.md bfd07b8307b0d3627e13b5b0ab9bf809b06dc2eb
Reviewed-Content-Hash: design/gdd/selo-e-fluxo.md 74c1d822b7afe49a1e96baa49ccf5bc91a35e644
Reviewed-Content-Hash: design/gdd/systems-index.md 8bd311e6b137b7a12582404083324313949ac4a4
Reviewed-Content-Hash: design/gdd/tela-de-bencao-e-carta.md ff8d24d33460c175a28be54045b41347d0888865
Reviewed-Content-Hash: design/gdd/telegrafos.md 3902362b39e1bc2ef1a673e9b9b9a1e66c2d3f68
Reviewed-Content-Hash: design/gdd/telemetria-local.md 766f93ca34ede098dab019d8d2c81e89a413897a
Reviewed-Content-Hash: design/gdd/vinculo-e-pactos.md 8a1b08d729bc4fcb0a5d641567a61ae86d90646f

## Resumo

Revisão feita depois da Doutrina de Pactos (GDDs do commit 6698079). Escrita e correção dos ADRs por agentes de arquitetura; extração de requisitos e as duas revisões (consistência e cobertura) por agentes independentes, que não escreveram os ADRs.

- **ADRs:** 18, todos **Accepted** (aprovação do usuário em 2026-11-16 e propagação dos experimentos `EX-0001..0016` em 2026-11-17). Novos: 0015 Ciclo da run e composição, 0016 Áudio: ganchos e vozes, 0017 Aliados e invocações, 0018 IA de inimigos e chefe. Emendas datadas de 2026-11-16/17 em 0001–0018. Os ADRs 0003–0005 ganharam as seções obrigatórias (Decision, Consequences, GDD Requirements Addressed, Engine Compatibility, ADR Dependencies).
- **Requisitos:** 400 em `tr-registry.yaml` (270 de 2026-11-15 + 130 novos: 18 maldicoes, 18 chefes com o TR-ia-019, 18 vinculo, 18 save, 57 das emendas Pactos em 20 GDDs e 1 de orçamento do item 6.1). Nenhum ID renumerado; TR-run-007 revisado (resumo de 12 campos).
- **Cobertura:** ✅ 400 · 🟡 0 · ⚠️ 0 · ❌ 0 (18/18 ADRs Accepted e PC de referência fixado no ADR-0004).

## Traceability Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered (Accepted) | 400 | 100% |
| 🟡 Covered (Proposed) | 0 | 0% |
| ⚠️ Partial | 0 | 0% |
| ❌ Gap | 0 | 0% |
| **Total** | **400** | **100%** |

Desde 2026-11-15: os 6 gaps e os 45 parciais foram integralmente resolvidos e promovidos a ✅ Covered (Accepted) após o aceite dos 18 ADRs e a fixação do PC de referência (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, RTX 3050 Laptop, Windows 11 Home 10.0.26300`) com carga medida em `160,8 ms` (editor) / `86,2 ms` (`.pck`) `< 250 ms` para o `TR-conteudo-015` (ADR-0004).

**Itens de engine agora VERIFICADOS (`EX-0001..0016` e `EX-0011 E1–E7`, 2026-11-16/17):** TR-rng-012 (`DisplayServer.clipboard_set`), TR-combate-nucleo-018 (`RenderingServer.frame_post_draw`, `33,33 ms ≤ 50 ms`), TR-pipeline-* (`EX-0001-3` e `EX-0011 E1–E7` em `prototypes/pipeline-verificacao/`).

Matriz completa: [requirements-traceability.md](requirements-traceability.md).

## Fase 4 — Conflitos entre ADRs

A revisão independente achou **5 🔴 e 14 🟡**. Todos os 🔴 foram corrigidos e reconferidos; os 🟡 estão corrigidos ou aceitos como estão.

| # | Achado | Correção |
|---|---|---|
| C1 🔴 | Ciclos não declarados: 0010↔0017, 0014→0010→0017, 0012↔0015 | Dependência num sentido só (quem define a interface é dependência de quem usa): 0017 depende de 0010; 0015 depende de 0012; portas injetadas declaradas (`exaurir`, `ConsultaDeAlvoMaldicao`, portas de UI) |
| C2 🔴 | Item 7 divergente entre 0001 e 0010 | Ordem canônica em 0001, 0010, 0014 e 0018: `telegrafos.varrer` → `ia.inicio_do_item_7` → por inimigo vivo `avancar(1)` → `status.tick` → `telegrafos.avancar` → impacto → IA → `ia.fim_do_item_7` |
| C3 🔴 | Campo `tipo` de `EvMaldicaoTrocada` colidia com `tipo()` | Renomeado para `modo` |
| C4 🔴 | 0015 e 0018 dependiam de ordem de registro, proibida pelo 0002 | Chamadas diretas: `vinculo.consolidar_run` antes de `EvRunEncerrada`; `chefe_vencido` direto do Combate para a IA |
| C5 🔴 | `maldicao_exausta` com dois emissores | Só o Combate emite (combate-nucleo R17, maldicoes R20) |
| 🟡 1–14 | Assinaturas, bloco `ModuloDeIA`, tabela de estados do 0001, dono do Vínculo, catálogo de eventos, persistência, orçamento, Enables | Corrigidos. Aceitos como estão: `vinculo_fim_run` fundido em `EvVinculoGanho` (`vinculo_atualizado`) no canal, com linha própria só na Telemetria; co-dependência 0017↔0018 declarada fora do "Depends On" para não criar ciclo no grafo (aceitar os dois juntos) |

Também alinhados nesta rodada, antes da revisão: ordem interna do item 6.1 (dona: ADR-0017, maldicoes R23); assinaturas de `ferir_maldicao`/`ferir_acuada`/`disparar_projetil`/`subjugar` (donas: ADR-0010); acuada fora da lista de inimigos (ADR-0003); ordem de entrega Telemetria → HUD → Feedback → Telas → Áudio; lacaios do chefe sem `elites`/`spawn`, mas com `ia` como qualquer `melee` (IA R21, AC-IA-46; só o chefe não consome RNG); orçamento total do passo vivo ≤ 1,0 ms p99 (tabela no ADR-0001).

## Ordem de dependência

`adr-dep-graph.sh`: sem ciclos e sem bloqueio. Ordem de aceite:
0001, 0002, 0003, 0004, 0005, 0006, 0009, 0007, 0013, 0008, 0010, 0014, 0011, 0017 + 0018 (juntos), 0012, 0015, 0016.

## Fase 5 — Engine

- 18/18 com Engine Compatibility, todos no pin 4.7.2. Nenhuma API depreciada.
- APIs pós-corte conferidas na referência sem contradição: `@abstract`, override tipado, `duplicate_deep`, `offset_transform_*`, `store_string` → bool, Shader Baker, foco duplo.
- `DEEP_DUPLICATE_ALL` (0004) e todos os experimentos `EX-0001..0016` + `EX-0011 E1–E7` verificados e propagados aos ADRs `0001–0018` (`production/qa/evidence/experimentos/`).
- Engine Specialist: **PASS** (`godot-specialist`, 2026-11-17 — `EX-0001..0016` e `EX-0011 E1–E7` verificados).

## Fase 6 — Cobertura do architecture.md

Atualizado para a v1.13: 26 GDDs do MVP, 18 ADRs Accepted, Module Ownership com Maldições, Vínculo, Chefes, Save e Áudio, ADR Audit com 0001–0018 verificados, `Open Questions` do MVP todas fechadas/resolvidas, nenhuma menção de `SceneTree.paused` como dependência (o ADR-0001 usa estado próprio).

## GDD Revision Flags

Nenhum bloqueante. Para a aba de Design avaliar:
- Telégrafos OQ11: um telégrafo mirado na Maldição tem o mesmo desenho e não fere o jogador (risco já registrado em `pactos-decisoes-a-confirmar.md`).
- Conteúdo OQ 9: o ADR-0004 decidiu `BossPatternDef` embutido em `EnemyDef.padroes` (array tipado, sem id nem manifesto). O GDD pode fechar a OQ.
- Input OQ 13: o ADR-0006 decidiu que, sem bind livre, a ação `troca` nasce sem tecla e avisa `INPUT_ACAO_NOVA` uma vez.

## Verdict: PASS

Todos os 18 ADRs (`ADR-0001` a `ADR-0018`) estão `Accepted`, `400/400` requisitos técnicos (`100%`) estão `✅ Covered (Accepted)` sem gaps (`0 ❌`), sem parciais (`0 ⚠️`), sem conflitos (`0 🔴`) e sem ciclos no grafo de dependências (`adr-dep-graph.sh`), e os experimentos de engine `EX-0001..0016` + `EX-0011 E1–E7` foram verificados e propagados.

## Decisões tomadas pelos agentes (para o usuário revisar)

Cada ADR lista as suas na seção "Decisões tomadas pelo agente (a revisar)". As principais:
- **0015:** nova run recria o escopo inteiro (sem `reset()` por módulo); a escolha do chefe vale no 1º passo vivo depois que a tela fecha; gravar ao sair do jogo é síncrono (a única gravação fora do ponto seguro); "Abandonar run" só na pausa aberta a partir de Jogo.
- **0016:** Áudio é o 5º consumidor; 16 vozes, com pools próprios para os 3 tons de telégrafo e as 4 vozes de Interface; o hitstop não pausa o som; som não posicional.
- **0017:** a Vida da Maldição fica no módulo e o Combate a escreve por `descontar_vida`; reposicionar durante o salto cancela o salto; `TecnicaDef` também serve ao efeito do Chamado.
- **0018:** orçamento da IA ≤ 0,15 ms p99; o chefe recusa `puxar`; o retângulo visível vem do último estado base da câmera.
- **0004:** `BossPatternDef` embutido no `EnemyDef`. **0006:** `troca` sem bind se a tecla padrão estiver ocupada. **0012/0013:** nomes `PortaDoPacto`, `LeituraDoPerfil`, `ModoDoPerfil`, `marcar_pendente()`/`gravar_se_pendente()`.

## Required ADRs

Nenhum ADR novo é necessário para o MVP (18/18 escritos, revisados e `Accepted`). Todas as pendências de arquitetura foram encerradas em 2026-11-17:
1. ✅ PC de referência fixado no ADR-0004 (`TR-conteudo-015` e orçamentos de CPU).
2. ✅ Experimentos `EX-0001..0016` e `EX-0011 E1–E7` rodados e propagados aos ADRs e ao `control-manifest.md`.
3. ✅ 18/18 ADRs aceitos na ordem de dependência.
4. ✅ `design/accessibility-requirements.md` e `design/ux/interaction-patterns.md` criados.

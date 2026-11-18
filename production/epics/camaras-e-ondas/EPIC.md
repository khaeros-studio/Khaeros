# Epic: Câmaras e ondas

> **Layer**: Feature
> **GDD**: design/gdd/camaras-e-ondas.md
> **Architecture Module**: Câmaras e ondas (layout, ondas, p, portas físicas)
> **Status**: Complete
> **Stories**: 10 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [WaveRules, RoomTuning e RegionDef (WV1–WV11)](story-001-tuning-e-validacao-wv.md) | Logic | Complete | ADR-0004 |
| 002 | [Profundidade p, p_max e chave do RNG](story-002-profundidade-e-sequencia.md) | Logic | Complete | ADR-0015, ADR-0005 |
| 003 | [Layout de pedras, retângulo e obstáculos](story-003-layout-de-pedras.md) | Logic | Complete | ADR-0005, ADR-0008, ADR-0014 |
| 004 | [Composição das ondas](story-004-composicao-das-ondas.md) | Logic | Complete | ADR-0005, ADR-0018 |
| 005 | [Spawn — 14 candidatos, filtros, ordem](story-005-spawn-e-candidatos.md) | Logic | Complete | ADR-0005, ADR-0018 |
| 006 | [Montagem na Transição](story-006-montagem-na-transicao.md) | Integration | Complete | ADR-0001, ADR-0015, ADR-0017, ADR-0008 |
| 007 | [Próxima onda, em combate e câmara limpa](story-007-ciclo-de-combate-e-limpar.md) | Logic | Complete | ADR-0001, ADR-0010, ADR-0002, ADR-0003 |
| 008 | [Santuário e portas físicas](story-008-santuario-e-portas.md) | Logic | Complete | ADR-0015, ADR-0006, ADR-0001 |
| 009 | [Câmara do chefe](story-009-camara-do-chefe.md) | Logic | Complete | ADR-0015, ADR-0018, ADR-0005, ADR-0010, ADR-0003, ADR-0001 |
| 010 | [Evidência visual da arena e portas](story-010-evidencia-visual-arena-e-portas.md) | Visual/Feel | Complete | ADR-0014, ADR-0008 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Layout, ondas, profundidade `p` (dono de `p_max`), portas físicas, "em combate", `camara_limpa(p,tipo)`, retângulo de vista e obstáculos. Risco: montar layout + 3 ondas + 1ª onda num quadro da Transição (custo a medir).

## Dependências entre épicos

- ia-de-inimigos-e-elites
- rng
- orquestrador-do-passo

## Estado atual do código

As três ondas fixas da fatia (`data/integration/gameplay.json`, `game_session.gd`) são **substituídas** pela composição por RNG.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |
| [ADR-0018: IA de inimigos e chefe](../../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) | Fases dos inimigos, lista estável, padrões do chefe, fases e Fúria | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **15 / 15** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-camaras-001 | Câmaras são dono único de p e p_max; chave do RNG é o índice da câmara (santuário incluído), não p | ADR-0005 ✅, ADR-0015 ✅ |
| TR-camaras-002 | Câmara montada no quadro da metade do wipe, depois do teleporte; 1ª onda no mesmo quadro | ADR-0001 ✅, ADR-0008 ✅ |
| TR-camaras-003 | Retângulo jogável = câmara inteira; obstáculos circulares entregues a Movimento, Selo, Telégrafos e IA | ADR-0008 ✅, ADR-0014 ✅ |
| TR-camaras-004 | Layout pelo fluxo layout com consumo fixo (10 candidatos por pedra, 91 reais) | ADR-0005 ✅ |
| TR-camaras-005 | Ondas compostas na montagem pelo fluxo ondas | ADR-0005 ✅ |
| TR-camaras-006 | Spawn sorteia sempre 14 candidatos (28 reais); só a escolha final depende do jogador | ADR-0005 ✅ |
| TR-camaras-007 | Próxima onda e câmara limpa avaliadas no item 10, só com hitstop 0 | ADR-0001 ✅ |
| TR-camaras-008 | Consulta em combate; ao limpar remove projéteis e emite camara_limpa uma vez no mesmo passo | ADR-0002 ✅, ADR-0010 ✅ |
| TR-camaras-009 | Portas com estado, posição e alcance de 111 px; interação pede a Transição e é ignorada em hitstop e Transição | ADR-0001 ✅, ADR-0006 ✅, ADR-0015 ✅ |
| TR-camaras-010 | Valores de tuning (WaveRules, RoomTuning) vêm do catálogo validado (WV1-WV9) | ADR-0004 ✅ |
| TR-camaras-011 | Montagem pede reposicionar_maldicao(pos) e encontro_na_camara(indice); acuada nasce sem RNG e pos_acuada fica guardada | ADR-0015 ✅, ADR-0017 ✅, ADR-0005 ✅ |
| TR-camaras-012 | Campo ordem por inimigo passado à IA; filtro por spawn_dist_acuada_px sem mudar o consumo dos 14 candidatos | ADR-0005 ✅, ADR-0018 ✅ |
| TR-camaras-013 | Fase Subjugado com em combate falso e R9 suspensa; só limpar_camara_chefe emite camara_limpa(4, chefe), uma vez | ADR-0001 ✅, ADR-0010 ✅, ADR-0015 ✅ |
| TR-camaras-014 | Câmara do chefe sem sorteio nem fluxos; lacaios entram na lista pelo módulo de Chefes com teto de 9 inimigos | ADR-0018 ✅, ADR-0005 ✅, ADR-0003 ✅ |
| TR-camaras-015 | Câmara limpa conta só a lista de inimigos; Maldições e acuada ficam fora | ADR-0003 ✅, ADR-0010 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/camaras-e-ondas.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

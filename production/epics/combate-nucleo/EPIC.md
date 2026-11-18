# Epic: Combate núcleo

> **Layer**: Core
> **GDD**: design/gdd/combate-nucleo.md
> **Architecture Module**: Combate núcleo (golpes, projéteis, empurrão, mortes, Vida, eventos)
> **Status**: Complete
> **Stories**: 10 / 10 Complete (2026-11-18) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Golpes, projéteis, empurrão, varredura de mortes, Vida do jogador, contador de hitstop e eventos V1–V15; facções (ALIADO), `ferir_maldicao`, `ferir_acuada`, `subjugar`. Define as interfaces que IA e Telégrafos implementam.

## Dependências entre épicos

- movimento-e-esquiva
- modificadores
- orquestrador-do-passo
- experimentos-de-engine (EX-0010-1 só para a story AC-92)

## Estado atual do código

`src/gameplay/game_session.gd` (379 linhas) **substituir/decompor**: ataque, estocada, corte na esquiva e `_hurt_enemy`/`_hurt_player` são a referência de sensação e números, mas misturam combate, IA, ondas e bênçãos num objeto e devolvem `Array[String]`. Extrair para Combate (ADR-0010), com eventos tipados; os valores vão para `CombatTuning`.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |
| [ADR-0018: IA de inimigos e chefe](../../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) | Fases dos inimigos, lista estável, padrões do chefe, fases e Fúria | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **24 / 24** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-combate-nucleo-001 | Ordem fixa dos 10 itens do passo vivo, só no estado Jogo | ADR-0001 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-002 | Hitstop como contador de passos (vale o maior), congela do passo seguinte; nunca Engine.time_scale | ADR-0001 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-003 | Lista de inimigos em ordem estável, estado vivo fora do SceneTree, lógica testável sem cena | ADR-0003 ✅ |
| TR-combate-nucleo-004 | Descontos do item 3 antes do Movimento; disparo do item 5 com Especial primeiro, combo por slot, um golpe por passo | ADR-0010 ✅ |
| TR-combate-nucleo-005 | Geometria de acerto única (arco, círculo, leque) reusada pelos telégrafos (forma = teste, P3) | ADR-0010 ✅, ADR-0014 ✅ |
| TR-combate-nucleo-006 | Projéteis em lista própria com ordem fixa de teste por passo e disparar_projetil para a IA | ADR-0010 ✅ |
| TR-combate-nucleo-007 | ferir_inimigo com dano float, contador de acertos e caminho silencioso para Status e Selo | ADR-0010 ✅, ADR-0009 ✅ |
| TR-combate-nucleo-008 | ferir_jogador com dano inteiro e um arredondamento; recursos do jogador no Combate; em combate consultado das Câmaras | ADR-0010 ✅, ADR-0009 ✅ |
| TR-combate-nucleo-009 | Eventos tipados com campos fixos e durações prontas para HUD, Feedback, Áudio, Selo, Status, Câmaras, Run e Telemetria | ADR-0002 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-010 | Varredura de mortes com retrato por passe (até 4); morto não age; morte do jogador para os passos seguintes | ADR-0010 ✅, ADR-0003 ✅ |
| TR-combate-nucleo-011 | Transição com seis ações em ordem no quadro de progresso_wipe >= 0,5 | ADR-0001 ✅, ADR-0011 ✅ |
| TR-combate-nucleo-012 | Empurrão e impacto na parede com colisão própria contra paredes e obstáculos | ADR-0008 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-013 | Câmara limpa só é avaliada com hitstop em 0 (contrato com Câmaras e Run) | ADR-0001 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-014 | Pedidos síncronos do Movimento (cancelar, garantir_invulneravel, aplicar_corte, esquiva_iniciada); Corte pesado sem hitstop | ADR-0010 ✅, ADR-0008 ✅ |
| TR-combate-nucleo-015 | Todas as dependências do Combate por injeção (portadores, amostra, consultas, geometria, tuning, AttackDef) | ADR-0001 ✅, ADR-0003 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-016 | Valores de tuning vêm do CombatTuning validado no catálogo (CV1-CV21) | ADR-0004 ✅ |
| TR-combate-nucleo-017 | Orçamento de CPU dos itens 3, 5, 7, 8 e 9 com p99 <= 0,3 ms por passo | ADR-0010 ✅ |
| TR-combate-nucleo-018 | Latência do golpe <= 2 passos + 1 quadro, medida até o fim de desenho do quadro | ADR-0010 ✅, ADR-0006 ✅ |
| TR-combate-nucleo-019 | Item 6.1 Maldições depois do Selo (6) e antes dos inimigos (7) | ADR-0001 ✅, ADR-0017 ✅, ADR-0010 ✅ |
| TR-combate-nucleo-020 | Maldição na facção do jogador fora das listas de alvos, sem fogo amigo; aplicar_golpe_maldicao síncrono com abate creditado ao dono | ADR-0010 ✅, ADR-0003 ✅ |
| TR-combate-nucleo-021 | ferir_maldicao (F12) com Exaustão síncrona via exaurir; golpe e projétil inimigo testam só o alvo guardado | ADR-0010 ✅, ADR-0014 ✅, ADR-0017 ✅ |
| TR-combate-nucleo-022 | ferir_acuada (F13) sem hitstop nem número; falhar_encontro síncrono nos itens 7 e 8, antes da varredura | ADR-0010 ✅, ADR-0001 ✅, ADR-0014 ✅ |
| TR-combate-nucleo-023 | Chefe subjugavel fica Subjugado na lista com pedido subjugar à IA e projéteis removidos; lacaios invocado_pelo_chefe saem sem abate | ADR-0010 ✅, ADR-0018 ✅ |
| TR-combate-nucleo-024 | Eventos maldicao_atingida, maldicao_exausta, chamado, chamado_indisponivel, chefe_vencido e campos autor_player_id, limpo_pelo_chefe, origem maldicao | ADR-0002 ✅, ADR-0010 ✅, ADR-0017 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | CombatTuning validado e esqueleto injetável do Combate | Logic | Complete | ADR-0010, ADR-0004 |
| 002 | Ordem do passo vivo, hitstop e transição | Logic | Complete | ADR-0010, ADR-0001 |
| 003 | Disparo do golpe, combo por slot, guarda e recuperação | Logic | Complete | ADR-0010 |
| 004 | GeometriaDeAcerto e projéteis | Logic | Complete | ADR-0010, ADR-0014 |
| 005 | Investida e pedidos síncronos do Movimento | Integration | Complete | ADR-0010, ADR-0008 |
| 006 | ferir_inimigo, empurrão e impacto na parede | Logic | Complete | ADR-0010 |
| 007 | ferir_jogador e varredura de mortes | Logic | Complete | ADR-0010 |
| 008 | Eventos tipados e contratos | Integration | Complete | ADR-0002, ADR-0010 |
| 009 | Pactos — Maldição aliada, acuada e chefe Subjugado | Logic | Complete | ADR-0010, ADR-0017, ADR-0018 |
| 010 | Leitura visual, desempenho e latência do golpe | Visual/Feel | Complete | ADR-0010, ADR-0011 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/combate-nucleo.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

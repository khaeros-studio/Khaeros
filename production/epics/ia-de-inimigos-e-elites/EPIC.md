# Epic: IA de inimigos e elites

> **Layer**: Feature
> **GDD**: design/gdd/ia-de-inimigos-e-elites.md
> **Architecture Module**: IA e elites (fases, lista estável de inimigos, sortear_elite)
> **Status**: Complete
> **Stories**: 10 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Lista estável, item 7 e consultas](story-001-lista-estavel-e-consultas.md) | Logic | Complete | ADR-0018, ADR-0003 |
| 002 | [Fases, surgimento e melee](story-002-fases-surgimento-e-melee.md) | Logic | Complete | ADR-0018, ADR-0014, ADR-0005 |
| 003 | [Ranged, charger e vista](story-003-ranged-charger-e-vista.md) | Logic | Complete | ADR-0018, ADR-0007 |
| 004 | [Andar, conter e separação](story-004-andar-conter-e-separacao.md) | Logic | Complete | ADR-0018, ADR-0008 |
| 005 | [Elites, armadura e quebra](story-005-elites-armadura-e-quebra.md) | Logic | Complete | ADR-0018, ADR-0005, ADR-0009 |
| 006 | [Alvo efetivo e atração](story-006-alvo-e-atracao.md) | Logic | Complete | ADR-0018, ADR-0017 |
| 007 | [Imobilizar, puxar e conter](story-007-imobilizar-puxar-e-conter.md) | Logic | Complete | ADR-0018, ADR-0017 |
| 008 | [Acuada por paridade](story-008-acuada-por-paridade.md) | Logic | Complete | ADR-0018, ADR-0017 |
| 009 | [Chefe ativo e lacaios](story-009-chefe-ativo-e-lacaios.md) | Logic | Complete | ADR-0018, ADR-0010 |
| 010 | [IATuning e IV1–IV9](story-010-tuning-e-validacao.md) | Integration | Complete | ADR-0004, ADR-0018 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Fases dos inimigos, **lista de inimigos com ordem estável** (dona), `sortear_elite`, consulta de alvos; movimento direto sem pathfinding.

## Dependências entre épicos

- combate-nucleo
- telegrafos
- movimento-e-esquiva
- rng

## Estado atual do código

A IA dos dois inimigos em `game_session.gd` é **referência**; substituir por ADR-0018 (fases tipadas, RNG do fluxo `ia`).

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |
| [ADR-0018: IA de inimigos e chefe](../../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) | Fases dos inimigos, lista estável, padrões do chefe, fases e Fúria | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **19 / 19** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ia-001 | IA no item 7, em ordem estável, nunca em hitstop nem fora de Jogo | ADR-0001 ✅, ADR-0018 ✅ |
| TR-ia-002 | Lista de inimigos com identidade estável; morto não age; remoção na varredura | ADR-0003 ✅, ADR-0010 ✅, ADR-0018 ✅ |
| TR-ia-003 | Máquina de fases com timers em passos vivos | ADR-0003 ✅, ADR-0014 ✅, ADR-0018 ✅ |
| TR-ia-004 | Fluxos de RNG ia (variável) e elites (consumo fixo de 1 real por inimigo) | ADR-0005 ✅, ADR-0018 ✅ |
| TR-ia-005 | Preparo acoplado a iniciar_telegrafo; golpe no mesmo passo do disparo | ADR-0014 ✅, ADR-0018 ✅ |
| TR-ia-006 | Inimigos presos a obstáculos e parede e separados par a par ao fim do item 7 | ADR-0008 ✅, ADR-0018 ✅ |
| TR-ia-007 | Elite, chefe e profundidade como fontes no portador | ADR-0009 ✅, ADR-0018 ✅ |
| TR-ia-008 | sortear_elite chamado pelas Câmaras, no máximo 1 elite por onda | ADR-0005 ✅, ADR-0018 ✅ |
| TR-ia-009 | ranged só inicia o preparo dentro do retângulo visível da câmera | ADR-0007 ✅, ADR-0018 ✅ |
| TR-ia-010 | Quebra por pedir_recuperacao; armadura de elite e chefe | ADR-0010 ✅, ADR-0014 ✅, ADR-0018 ✅ |
| TR-ia-011 | Consulta de alvos atingíveis em ordem estável, com raio, para Input e Movimento | ADR-0006 ✅, ADR-0008 ✅, ADR-0018 ✅ |
| TR-ia-012 | Lê no_selo do item 6 e aplica lentidão e cambaleio ao andar, não ao avanço | ADR-0001 ✅, ADR-0010 ✅, ADR-0018 ✅ |
| TR-ia-013 | Dependências injetadas; testes sem SceneTree | ADR-0003 ✅, ADR-0018 ✅ |
| TR-ia-014 | Valores de tuning vêm do catálogo validado (IATuning, EnemyDef, EliteRules, IV1-IV9) | ADR-0004 ✅, ADR-0018 ✅ |
| TR-ia-015 | Alvo por inimigo exposto por consulta; atrair sem renovação com respiro e imobilizar só em comuns | ADR-0018 ✅, ADR-0017 ✅, ADR-0010 ✅ |
| TR-ia-016 | Consulta atingiveis só leitura em ordem estável de spawn, sem Maldição nem acuada | ADR-0018 ✅, ADR-0003 ✅ |
| TR-ia-017 | Chefe ativo com fases TransicaoFase e Subjugado; subjugar para IA e colisão ofensiva; lacaios sem RNG | ADR-0018 ✅, ADR-0010 ✅ |
| TR-ia-018 | Alvo padrão acuada por paridade de ordem, suspenso enquanto atraído | ADR-0018 ✅, ADR-0017 ✅ |
| TR-ia-019 | Pedido puxar da IA para a técnica Convergência (TecnicaDef.puxar): aceita comuns e elites, o chefe recusa | ADR-0018 ✅, ADR-0017 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/ia-de-inimigos-e-elites.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

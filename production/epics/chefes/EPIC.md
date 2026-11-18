# Epic: Chefes

> **Layer**: Feature
> **GDD**: design/gdd/chefes.md
> **Architecture Module**: Chefes (BossPatternDef, fases e Fúria, Pactuar/Exorcizar)
> **Status**: Complete
> **Stories**: 10 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean) — ver `## Stories`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Dados do chefe e validação CH1–CH8](story-001-dados-do-chefe-e-validacao.md) | Integration | Complete | ADR-0004, ADR-0014 |
| 002 | [Máquina de fases do chefe](story-002-maquina-de-fases-do-chefe.md) | Logic | Complete | ADR-0018, ADR-0005 |
| 003 | [Padrões 0 e 1 e alvo travado](story-003-padroes-0-e-1-e-alvo-travado.md) | Logic | Complete | ADR-0014, ADR-0018, ADR-0010 |
| 004 | [Padrão 2: pulso e radiais](story-004-padrao-2-pulso-e-radiais.md) | Logic | Complete | ADR-0010, ADR-0018, ADR-0014 |
| 005 | [Padrão 3: convergência e lacaios](story-005-padrao-3-convergencia-e-lacaios.md) | Logic | Complete | ADR-0018, ADR-0008, ADR-0010, ADR-0014, ADR-0003 |
| 006 | [Defesas e TransicaoFase](story-006-defesas-e-transicao-de-fase.md) | Logic | Complete | ADR-0018, ADR-0010, ADR-0009 |
| 007 | [Barra de chefe no HUD](story-007-barra-de-chefe-no-hud.md) | UI | Complete | ADR-0012 |
| 008 | [Queda do chefe e limpeza](story-008-queda-do-chefe-e-limpeza.md) | Integration | Complete | ADR-0010, ADR-0018, ADR-0015, ADR-0011 |
| 009 | [Subjugado e escolha](story-009-subjugado-e-escolha.md) | Integration | Complete | ADR-0015, ADR-0002, ADR-0010, ADR-0018 |
| 010 | [Apresentação do chefe](story-010-apresentacao-do-chefe.md) | Visual/Feel | Complete | ADR-0011, ADR-0016, ADR-0014 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Padrões do chefe (`BossPatternDef`), fases e Fúria, alvo travado, Pactuar/Exorcizar (`EvChefeSubjugado`, `EvChefeExorcizado`).

## Dependências entre épicos

- ia-de-inimigos-e-elites
- telegrafos
- vinculo-e-pactos

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |
| [ADR-0018: IA de inimigos e chefe](../../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) | Fases dos inimigos, lista estável, padrões do chefe, fases e Fúria | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **17 / 17** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-chefes-001 | Chefe como EnemyDef com comportamento chefe, lista de BossPatternDef e ChefesTuning validados por CH1-CH8; tuning vem do catálogo validado | ADR-0004 ✅ |
| TR-chefes-002 | Máquina de estados do chefe (Surgindo a Morto/Subjugado) em ciclo de 4 padrões com timers por passo vivo | ADR-0018 ✅ |
| TR-chefes-003 | Luta do chefe determinística sem consumir RNG (arena fixa, esperas fixas, lacaios sem fluxos elites/spawn) | ADR-0005 ✅, ADR-0018 ✅ |
| TR-chefes-004 | Alvo do chefe travado no início do Preparo; cada golpe testa só esse alvo; golpe em curso não fere ninguém se o alvo sair | ADR-0014 ✅, ADR-0010 ✅, ADR-0018 ✅ |
| TR-chefes-005 | Telégrafos SETOR, RETANGULO, ANEL e CIRCULO no MVP, retângulo pelo raio do alvo travado, cancelamento na TransicaoFase e no abate | ADR-0014 ✅ |
| TR-chefes-006 | Contorno secundário tracejado por raio_secundario_px, só desenho | ADR-0014 ✅, ADR-0011 ✅, ADR-0004 ✅ |
| TR-chefes-007 | disparar_projetil(alvo = id): projétil de alvo único atravessa quem não é o alvo e some por pilar, parede ou tempo | ADR-0010 ✅, ADR-0018 ✅ |
| TR-chefes-008 | Deslocamento forçado sem dano (puxão e pulso repulsor) em jogador e Maldição com colisão, ignorado por invulneráveis | ADR-0008 ✅, ADR-0010 ✅ |
| TR-chefes-009 | Invocação controlada de lacaios com teto e marca invocado_pelo_chefe, removidos na queda do chefe sem abate nem ao_abater | ADR-0018 ✅, ADR-0010 ✅ |
| TR-chefes-010 | TransicaoFase com gatilho único, inimigo invulnerável (dano x 0, ticks continuam) e Fúria alterando velocidade e recargas | ADR-0018 ✅, ADR-0010 ✅, ADR-0009 ✅ |
| TR-chefes-011 | Armadura total, imunidade a imobilização, fonte chefe (empurrão x 0,12) e Abalo funcionando | ADR-0010 ✅, ADR-0009 ✅ |
| TR-chefes-012 | Desfecho pela marca subjugavel do spawn: chefe fica na lista inerte com Vida 0, hitstop de chefe 36 mais impact frame, chefe_vencido, abate e cura só no Exorcizar | ADR-0010 ✅, ADR-0011 ✅, ADR-0015 ✅ |
| TR-chefes-013 | Escolha síncrona resolver_subjugado, creditar, limpar_camara_chefe; Câmaras como emissora única de camara_limpa; chefe_subjugado em s+37; escolha repetida ignorada | ADR-0015 ✅, ADR-0002 ✅, ADR-0010 ✅ |
| TR-chefes-014 | Morte do jogador no mesmo passo tem precedência sobre vitória e subjugação | ADR-0010 ✅, ADR-0015 ✅ |
| TR-chefes-015 | Barra de chefe no HUD lê Vida, vida_max, fase e subjugado, atualiza no mesmo passo, sem fio de Vida sob o chefe | ADR-0012 ✅ |
| TR-chefes-016 | Impact frame de chefe com preempção, luz de chefe, leitura da Fase 2 e ganchos de áudio chefe_* | ADR-0011 ✅, ADR-0016 ✅ |
| TR-chefes-017 | Chefe mais lacaios dentro do teto de inimigos (9) e do teto de telégrafos (24) | ADR-0014 ✅, ADR-0003 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/chefes.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

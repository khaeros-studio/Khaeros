# Epic: Maldições (Doutrina de Pactos)

> **Layer**: Feature
> **GDD**: design/gdd/maldicoes.md
> **Architecture Module**: Maldições (ModuloDeMaldicoes, item 6.1)
> **Status**: Complete
> **Stories**: 10 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Catálogo CurseDef/TecnicaDef/MaldicoesTuning e validação ML1–ML8 | Logic | Complete | ADR-0004, ADR-0017 |
| 002 | ModuloDeMaldicoes, MaldicaoRef e a dupla da expedição | Logic | Complete | ADR-0017, ADR-0003 |
| 003 | IA de aliado — fio, alvo e passivas condicionais | Logic | Complete | ADR-0017, ADR-0009 |
| 004 | Ataque básico pela R20 e habilidade Primordial | Integration | Complete | ADR-0010, ADR-0017 |
| 005 | Dano recebido, alvo travado, Exaustão e saída de campo | Integration | Complete | ADR-0017, ADR-0010 |
| 006 | Contadores, regeneração, espelho e dupla que cresce | Logic | Complete | ADR-0017, ADR-0009 |
| 007 | Troca e Técnica Combinada | Logic | Complete | ADR-0017, ADR-0006 |
| 008 | Chamado do Pacto e atração limitada | Integration | Complete | ADR-0017, ADR-0010 |
| 009 | Câmara, `estado_pacto`, eventos e orçamento do 6.1 | Integration | Complete | ADR-0017, ADR-0002 |
| 010 | Fio, marca do Virote e ganchos `sfx_maldicao_*` | Visual/Feel | Complete | ADR-0011, ADR-0016 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

`ModuloDeMaldicoes` no item 6.1 do passo, `MaldicaoRef` da dupla, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado e eventos de Maldição.

## Dependências entre épicos

- combate-nucleo
- movimento-e-esquiva
- modificadores
- input
- ia-de-inimigos-e-elites

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |
| [ADR-0018: IA de inimigos e chefe](../../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) | Fases dos inimigos, lista estável, padrões do chefe, fases e Fúria | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **19 / 19** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-maldicoes-019 | Orçamento de CPU do item 6.1 (Maldições) com p99 <= 0,1 ms por passo | ADR-0017 ✅ |
| TR-maldicoes-001 | Maldição é entidade da facção do jogador ligada a player_id e portador, fora das listas de inimigos e atingíveis (sem fogo amigo, não conta na câmara limpa, não bloqueia o jogador) | ADR-0017 ✅, ADR-0003 ✅, ADR-0010 ✅ |
| TR-maldicoes-002 | Dupla campo/reserva por jogador (MaldicaoRef) com estados Seguindo a Saltando/Pronta/Exausta; a dupla pode crescer no meio da run com portador novo | ADR-0017 ✅, ADR-0003 ✅, ADR-0009 ✅ |
| TR-maldicoes-003 | Ordem fixa dos 8 sub-passos no item 6.1 só em passo vivo; troca automática dentro de exaurir (itens 7 e 8); quem entra só age no 6.1 seguinte | ADR-0017 ✅, ADR-0001 ✅, ADR-0010 ✅ |
| TR-maldicoes-004 | IA de aliado: alvo por prioridade (marca do Virote, mais perto do jogador no fio, seguir), desempate pelo menor id, fio com histerese | ADR-0017 ✅ |
| TR-maldicoes-005 | Golpe da Maldição pelo impacto do Combate com de_arma falso (sem Fluxo, golpe_* ou hitstop); abate creditado ao dono via autor_player_id | ADR-0010 ✅, ADR-0017 ✅ |
| TR-maldicoes-006 | Alvo por inimigo (jogador ou Maldição atraída); telégrafo e projétil testam só o alvo travado | ADR-0018 ✅, ADR-0010 ✅, ADR-0014 ✅, ADR-0017 ✅ |
| TR-maldicoes-007 | Atração limitada via atrair(id, passos, passos_respiro) sem renovação e com respiro; saída de campo avisada à IA no mesmo passo; fator_andar_atraido lido a cada passo | ADR-0017 ✅, ADR-0018 ✅ |
| TR-maldicoes-008 | ferir_maldicao com F3 do Modificadores, sem invulnerabilidade nem hitstop; Exaustão com troca automática; maldicao_atingivel imune durante o salto | ADR-0010 ✅, ADR-0017 ✅, ADR-0009 ✅ |
| TR-maldicoes-009 | Contadores por passo vivo (Exaustão, regeneração com acumulador fracionário, recarga da troca) congelados em hitstop, pausa e transição | ADR-0017 ✅, ADR-0001 ✅ |
| TR-maldicoes-010 | Ação Troca no input por passo (buffer de 10 passos congelado no hitstop); recusa emite troca_indisponivel(motivo) | ADR-0017 ✅, ADR-0006 ✅ |
| TR-maldicoes-011 | Técnica combinada por dados: Saída e depois Entrada no mesmo passo, abates da Saída antes, Entrada lê o estado deixado (imobilizado, atraído, Abalo) | ADR-0017 ✅, ADR-0004 ✅ |
| TR-maldicoes-012 | Chamado do Pacto via pode_chamar/pedir_chamado (item 5, executa no 6.1): salto de N passos que para em obstáculo, pouso que imobiliza comum e atrai, M_chamado, recusa pelo Combate | ADR-0017 ✅, ADR-0010 ✅ |
| TR-maldicoes-013 | reposicionar_maldicao(pos) na troca de câmara limpa marca, atração e imobilização e preserva Vida, estados e recargas | ADR-0017 ✅, ADR-0015 ✅ |
| TR-maldicoes-014 | Leitura estado_pacto(player_id) sem efeito colateral e igual na pausa | ADR-0012 ✅, ADR-0017 ✅ |
| TR-maldicoes-015 | Eventos da R20 um por fato, nunca em passo congelado, com emissor único | ADR-0002 ✅, ADR-0017 ✅ |
| TR-maldicoes-016 | Passivas condicionais por código (fonte especie:<id>:<passiva>) e espelho de dano_todo_pct e velocidade_pct do jogador nos portadores da dupla | ADR-0009 ✅, ADR-0017 ✅ |
| TR-maldicoes-017 | Catálogo CurseDef, TecnicaDef e MaldicoesTuning validado por ML1-ML8; valores de tuning vêm do catálogo validado | ADR-0004 ✅, ADR-0017 ✅ |
| TR-maldicoes-018 | Fio de vínculo sempre visível, sem telégrafo de chão, marca do Virote e ganchos sfx_maldicao_* com no máximo 1 por passo | ADR-0011 ✅, ADR-0016 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/maldicoes.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

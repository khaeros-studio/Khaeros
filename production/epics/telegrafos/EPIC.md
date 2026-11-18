# Epic: Telégrafos

> **Layer**: Feature
> **GDD**: design/gdd/telegrafos.md
> **Architecture Module**: Telégrafos (lista, teto 24, geometria de acerto)
> **Status**: Complete
> **Stories**: 10 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Pool fixo, teto 24 e ciclo de vida](story-001-pool-teto-e-ciclo.md) | Logic | Complete | ADR-0014, ADR-0003 |
| 002 | [derivar() das formas](story-002-derivar-formas.md) | Logic | Complete | ADR-0014 |
| 003 | [FormaDeTelegrafo e testes de acerto](story-003-forma-e-testes-de-acerto.md) | Logic | Complete | ADR-0014, ADR-0010 |
| 004 | [Disparo no mesmo passo](story-004-disparo.md) | Logic | Complete | ADR-0014 |
| 005 | [Alvo travado e falha no vazio](story-005-alvo-travado.md) | Logic | Complete | ADR-0014 |
| 006 | [Quebrar, cancelar e troca de câmara](story-006-quebrar-e-cancelar.md) | Logic | Complete | ADR-0014, ADR-0001 |
| 007 | [Formas do chefe](story-007-formas-do-chefe.md) | Logic | Complete | ADR-0014 |
| 008 | [publicar() ao Pipeline](story-008-publicar-vistas.md) | Logic | Complete | ADR-0014, ADR-0011 |
| 009 | [TelegraphTuning e TV1–TV6](story-009-tuning-e-validacao.md) | Integration | Complete | ADR-0014, ADR-0004 |
| 010 | [Captura visual e áudio](story-010-captura-visual-e-audio.md) | Visual/Feel | Complete | ADR-0011, ADR-0007, ADR-0016 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Lista de telégrafos com teto de 24 e slots reutilizáveis, geometria de acerto, estado por quadro, alvo travado para o chefe.

## Dependências entre épicos

- combate-nucleo
- cena-e-camera

## Estado atual do código

`world_view.gd::_telegraph` desenha telégrafos à mão: só referência visual; a lógica vive aqui, o desenho no Pipeline.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **17 / 17** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-telegrafos-001 | Telégrafo como entidade em pool pré-alocado, ligado ao dono | ADR-0003 ✅, ADR-0014 ✅ |
| TR-telegrafos-002 | Um telégrafo por inimigo; teto 24 com recusa e nova tentativa | ADR-0014 ✅ |
| TR-telegrafos-003 | Mira travada na criação; progresso linear só em passo vivo; acompanha o dono | ADR-0014 ✅, ADR-0001 ✅ |
| TR-telegrafos-004 | Disparo resolvido no mesmo passo pela IA | ADR-0014 ✅, ADR-0010 ✅ |
| TR-telegrafos-005 | Formas e dimensões derivadas do EnemyDef, fonte única | ADR-0014 ✅ |
| TR-telegrafos-006 | A forma desenhada é o teste de acerto | ADR-0014 ✅, ADR-0010 ✅ |
| TR-telegrafos-007 | Comprimento da faixa limitado por parede ou obstáculo na mira | ADR-0014 ✅, ADR-0008 ✅ |
| TR-telegrafos-008 | Quebrar, cancelar e liberar tudo na hora na troca de câmara | ADR-0014 ✅, ADR-0001 ✅ |
| TR-telegrafos-009 | Entrega do estado de cada telégrafo ao Pipeline a cada quadro | ADR-0014 ✅, ADR-0011 ✅ |
| TR-telegrafos-010 | Validação TV1-TV6 pelo mesmo derivar() usado em jogo | ADR-0014 ✅, ADR-0004 ✅ |
| TR-telegrafos-011 | Valores de tuning vêm do catálogo validado (TelegraphTuning) | ADR-0004 ✅ |
| TR-telegrafos-012 | Dependências injetadas; testes sem SceneTree | ADR-0014 ✅, ADR-0003 ✅ |
| TR-telegrafos-013 | Duas passadas em z -5 e z 5, crescimento sem pulsar, contorno de 6 px na opção de acessibilidade | ADR-0011 ✅, ADR-0007 ✅ |
| TR-telegrafos-014 | Áudio com no máximo 3 telégrafos soando ao mesmo tempo | ADR-0016 ✅ |
| TR-telegrafos-015 | Telégrafo guarda alvo travado e raio, testa só ele e falha no vazio se o alvo sair | ADR-0014 ✅ |
| TR-telegrafos-016 | Dimensões pelo raio do alvo travado (F7); Maldição nunca cria telégrafo e o teto de 24 não muda | ADR-0014 ✅ |
| TR-telegrafos-017 | cancelar_telegrafo na TransicaoFase e na queda do chefe | ADR-0014 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/telegrafos.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

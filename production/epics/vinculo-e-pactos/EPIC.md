# Epic: Vínculo e pactos

> **Layer**: Feature
> **GDD**: design/gdd/vinculo-e-pactos.md
> **Architecture Module**: Vínculo e pactos
> **Status**: Complete
> **Stories**: 10 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | VinculoTuning, memórias e validação VP1–VP9 | Logic | Complete | ADR-0004 |
| 002 | PerfilVinculo e a seção `[vinculo]` | Logic | Complete | ADR-0013, ADR-0015 |
| 003 | Primeiro pacto, escolha da dupla e seed | Integration | Complete | ADR-0015, ADR-0005 |
| 004 | Sorteio do encontro no fluxo `pactos` | Logic | Complete | ADR-0005, ADR-0015 |
| 005 | A acuada — alvo por paridade, ferir_acuada e fuga | Integration | Complete | ADR-0010, ADR-0017 |
| 006 | Consentimento, Portas 2b e dupla que cresce | Integration | Complete | ADR-0015, ADR-0017 |
| 007 | Pontos, níveis, consolidação e bônus de nível | Logic | Complete | ADR-0015, ADR-0013, ADR-0009 |
| 008 | Chefe subjugado — Pactuar ou Exorcizar | Integration | Complete | ADR-0015, ADR-0002 |
| 009 | Eventos do Vínculo para a Telemetria | Logic | Complete | ADR-0002, ADR-0013 |
| 010 | Telas do pacto (UI) e playtest AC-VP-26 | UI | Complete | ADR-0012 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Pontos e nível por espécie, encontro de pacto e acuada, consentimento, conteúdo da seção `[vinculo]`; eventos `EvVinculoGanho`, `EvPactoFormado`, `EvEncontroFalhou`.

## Dependências entre épicos

- maldicoes
- rng
- persistencia
- combate-nucleo

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **18 / 18** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-vinculo-001 | PerfilVinculo injetado, escrito só pelo Vínculo, atravessa runs e sessões (escopo perfil) | ADR-0015 ✅, ADR-0001 ✅, ADR-0013 ✅ |
| TR-vinculo-002 | Sorteio do encontro ao criar a run no fluxo RNG novo pactos, consumo fixo de 4 reais mesmo com garantia | ADR-0005 ✅, ADR-0015 ✅ |
| TR-vinculo-003 | Tela Escolha do Pacto antes da seed; seed nasce em dupla_confirmada; estado inicial inclui dupla e perfil | ADR-0015 ✅, ADR-0005 ✅, ADR-0012 ✅ |
| TR-vinculo-004 | Encontro em câmara de combate normal, índices 1-2, no máximo 1 por run; consultas encontro_na_camara e encontro_aguardando sem RNG | ADR-0015 ✅ |
| TR-vinculo-005 | Entidade acuada neutra, imóvel, sem fogo amigo, fora da câmara limpa, congela em hitstop, pausa e Transição | ADR-0010 ✅, ADR-0017 ✅ |
| TR-vinculo-006 | Alvo por paridade da ordem de nascimento, atração com prioridade, golpe só testa o seu alvo, troca de alvo no mesmo passo na fuga | ADR-0010 ✅, ADR-0017 ✅ |
| TR-vinculo-007 | ferir_acuada com dano inteiro, sem hitstop, aplica M do atacante; falhar_encontro síncrono antes da varredura | ADR-0010 ✅ |
| TR-vinculo-008 | Telas de consentimento e do chefe no estado Bênção, mundo parado, pacto grava no fim do mesmo passo | ADR-0001 ✅, ADR-0012 ✅, ADR-0013 ✅, ADR-0015 ✅ |
| TR-vinculo-009 | Recompensa sai primeiro; Portas esperam pacto_resolvido antes de abrir (passo 2b) | ADR-0015 ✅, ADR-0002 ✅ |
| TR-vinculo-010 | Dupla cresce de 1 para 2 no meio da run, nova Maldição na reserva em Pronta | ADR-0017 ✅ |
| TR-vinculo-011 | Escolha Pactuar/Exorcizar no chefe subjugado com eventos chefe_escolhido e pacto_registrado | ADR-0015 ✅, ADR-0002 ✅, ADR-0012 ✅ |
| TR-vinculo-012 | pontos_run só em memória com tetos; consolida em run_encerrada antes da tela final, emite vinculo_atualizado, depois grava | ADR-0015 ✅, ADR-0013 ✅ |
| TR-vinculo-013 | Sair no meio da run consolida como abandono com regra de derrota; encontro Aguardando vira pendente | ADR-0013 ✅, ADR-0015 ✅ |
| TR-vinculo-014 | Bônus de nível aplicados só no começo da run pela fonte de modificador vinculo (vida_max, mult_recuperacao, bonus_dano_basico no básico) | ADR-0009 ✅, ADR-0017 ✅ |
| TR-vinculo-015 | Conteúdo de [vinculo] via escrever/ler/campos_de_ids, sem float nem StringName, espécies na ordem do manifesto, nível como cache de F3 | ADR-0013 ✅ |
| TR-vinculo-016 | ler() corrige só a entrada afetada, aviso VP-S1 uma vez por chave, nunca trava | ADR-0013 ✅ |
| TR-vinculo-017 | Valores de tuning vêm de VinculoTuning validado (VP1-VP9) e CurseDef.memorias do catálogo | ADR-0004 ✅ |
| TR-vinculo-018 | Telemetria com estado_inicial ampliado e eventos encontro_pacto, pacto e vinculo_fim_run | ADR-0013 ✅, ADR-0002 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/vinculo-e-pactos.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

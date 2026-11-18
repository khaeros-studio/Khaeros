# Epic: Modificadores e atributos

> **Layer**: Core
> **GDD**: design/gdd/modificadores-e-atributos.md
> **Architecture Module**: Modificadores (portador: atributos, modificadores, gatilhos)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories modificadores`
> **Engine Risk**: MEDIUM
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Portador com atributos, modificadores e gatilhos; `valor()`, `multiplicador_de_dano()`, `gatilhos()`, `aplicar/remover/avancar`; cache reconstruído e arredondamento determinístico próprio; portador da Maldição, espelho e `furia` (emenda Pactos).

## Dependências entre épicos

- orquestrador-do-passo
- conteudo
- experimentos-de-engine (EX-0009-1)

## Estado atual do código

Nenhum: a fatia aplica bênçãos de forma explícita, sem sistema de modificadores. Construir do zero; as bênçãos de `game_session.gd` viram casos de teste.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **16 / 16** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-modificadores-001 | Portador por combatente; atributos derivados separados dos recursos | ADR-0009 ✅, ADR-0003 ✅ |
| TR-modificadores-002 | Lista fechada de atributos com piso e teto; estrutura do modificador | ADR-0009 ✅ |
| TR-modificadores-003 | Estado de portador independente por instância; definição do catálogo intacta | ADR-0003 ✅, ADR-0009 ✅ |
| TR-modificadores-004 | Condicionais avaliados no uso, com contexto passado por quem consulta | ADR-0009 ✅ |
| TR-modificadores-005 | Tabela fechada das 21 chaves de tipo de efeito, entregue ao validador | ADR-0009 ✅, ADR-0004 ✅ |
| TR-modificadores-006 | Remover uma fonte remove todos os seus modificadores e gatilhos | ADR-0009 ✅ |
| TR-modificadores-007 | Recálculo imediato, sem esperar quadro | ADR-0009 ✅ |
| TR-modificadores-008 | Ordem canônica, float até o fim e arredondamento determinístico | ADR-0009 ✅ |
| TR-modificadores-009 | Atributo x recurso com notificação de valor antigo e novo | ADR-0009 ✅ |
| TR-modificadores-010 | Elite e profundidade aplicadas como fontes no spawn | ADR-0009 ✅ |
| TR-modificadores-011 | Semântica dos gatilhos com executor único | ADR-0009 ✅ |
| TR-modificadores-012 | Paridade de tabela com o cânone | ADR-0009 ✅ |
| TR-modificadores-013 | Valores de tuning vêm do catálogo validado; valor já escalado, params não escalam | ADR-0004 ✅, ADR-0009 ✅ |
| TR-modificadores-014 | Um portador por Maldição da dupla (base, vinculo, especie, espelhos), persistente na Exaustão e na reserva, criável no passo de um pacto | ADR-0009 ✅, ADR-0003 ✅, ADR-0017 ✅ |
| TR-modificadores-015 | Espelho por tipos_propagados_maldicao e fator_propagacao_maldicao, entra e sai com a fonte do jogador em todos os portadores | ADR-0009 ✅, ADR-0017 ✅ |
| TR-modificadores-016 | Origens vinculo, especie e espelho e lista restrita de atributos do portador da Maldição | ADR-0009 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/modificadores-e-atributos.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)

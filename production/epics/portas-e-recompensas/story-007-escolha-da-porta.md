# Story 007: Escolha da porta, recompensa pendente e EvPortaEscolhida

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (R8, R9, R9-P, R11; F3, F3-P)
**Requirement**: `TR-portas-005`, `TR-portas-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4 passo 4, §9); ADR-0002: Canal de eventos
**ADR Decision Summary**: as Câmaras emitem `porta_escolhida(k)` (só em passo vivo); as Portas guardam o tipo como `recompensa_pendente` da câmara `i + 1`, emitem `EvPortaEscolhida(tipo, opcoes)` e chamam `run.avancar()`; tudo injetado, sem SceneTree; colaboradores ausentes são Nulos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: payload de evento só com dados e ids (ADR-0002); `EvPortaEscolhida` é subclasse tipada de `EventoDoPasso` com `tipo()` de `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: toda criação de módulo passa por `FabricaDaRun`; dependências no `_init` (ADR-0015)
- Required: payload sem `Node` nem referência viva (ADR-0002)
- Forbidden: autoload, `get_node` absoluto em lógica

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-16 / AC-PR-36** `porta_escolhida(i)` guarda o tipo como recompensa da próxima câmara; as portas `santuario`, `chefe` e `ultima` não carregam recompensa; a porta `chefe` mostra o símbolo do chefe e nenhuma quantidade (dado da vista).
- [x] **AC-PR-12 / AC-PR-15** A ordem sorteada vale da esquerda para a direita (x = 735, 1185 com 2 portas; 510, 960, 1410 com 3); cada porta expõe tipo e quantidade, com os Fragmentos da **próxima** câmara de combate (depois do santuário, p 3: +3).
- [x] **AC-PR-35** (substitui AC-PR-17 no Limiar de 7) Escolhendo sempre bênção quando há, média em 100 000 runs 4,58 (± 0,05); determinística com `u0` ≥ 0,3 e `u1` < 0,5 nas 4 escolhas: 5 bênçãos; nunca escolhendo: 1.
- [x] **AC-PR-20** O sistema roda com `RewardTable`, Câmaras, Run, Bênçãos e Economia dublês, sem SceneTree.

---

## Implementation Notes

*Derived from ADR-0015 §4 passo 4 / §9:*

- `Portas.ao_porta_escolhida(k)`: valida estado `PORTAS_ABERTAS` e `k` no intervalo; guarda `recompensa_pendente`; emite `EvPortaEscolhida(tipo, opcoes)` (para HUD e Telemetria); chama `run.avancar()`. Escolha repetida ou fora de estado é ignorada.
- `VistaDePorta` pré-alocada (tipo, quantidade, x) publicada para a Apresentação.
- Teste de integração monta as Portas com dublês Nulos e simula as 7 câmaras do Limiar.

---

## Out of Scope

- Story 008: desenho e ícones.
- Épico `camaras-e-ondas`: interação e emissão de `porta_escolhida`.

---

## Files

- `src/gameplay/portas/portas.gd`
- `src/gameplay/portas/vista_de_porta.gd`
- `src/gameplay/portas/eventos_de_portas.gd` (`EvPortaEscolhida`)
- `tests/integration/portas/portas_escolha_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/portas/portas_escolha_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`; `production/epics/run-e-regioes/story-003-sequencia-da-regiao.md` (`run.avancar()`)
- Unlocks: `production/epics/portas-e-recompensas/story-008-portas-no-mundo.md`; `production/epics/run-e-regioes/story-006-vitoria.md`

**Código da fatia**: nenhum equivalente; construção do zero.

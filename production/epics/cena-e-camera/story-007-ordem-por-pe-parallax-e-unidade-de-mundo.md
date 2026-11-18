# Story 007: Ordem por pé, parallax manual (F7) e unidade de mundo

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-002`, `TR-cena-003`, `TR-cena-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: Âncoras ordenadas por `(pé_interpolado.y, ordem_criacao_visual)` com registro central de criação injetado e ordinal monotônico; parallax é deslocamento manual `offset = (1−p)*(C_final−centro_camara)`; toda distância de runtime já está em pixels de mundo e o fator 1,5 pertence só à importação.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: `y_sort_enabled=false` nas âncoras irmãs com o mesmo z; o compositor só muda a ordem de irmãos quando a ordem calculada muda (verificar visualmente e medir o custo com o teto real de entidades na story 008). Não combinar com `Parallax2D` nem follow automático de `CanvasLayer`.

**Control Manifest Rules (this layer)**:
- Required: pixels de mundo sem segunda conversão 1,5; ordem por `(pé_interpolado.y, ordem_criacao_visual)` com registro central injetado (ADR-0007)
- Forbidden: ordenar pela elevação aparente; atribuir `z_index` fora do módulo de camadas (ADR-0007)
- Guardrail: ordenação total e estável por 100 quadros

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-07** (teste do script de importação, Conteúdo F4) com `UNIT_TO_PX` = 1,5 e fixture do cânone (arena 1280×720, raio 18) → valores gravados 1920×1080 e 27, e 0 → 0; com a constante trocada para 2, o raio gravado é 36; em jogo, o sistema que lê o raio 27 do `.tres` usa 27 sem multiplicar de novo
- [ ] **AC-08** (Integration) Projétil desenhado 60 px acima → colide pela posição de chão; só sobreposição de sprite → não colide (dublê da interface de entidade; a colisão real é de movimento-e-esquiva e combate-nucleo)
- [ ] **AC-11** Pé em y 500 contra 520 → o de 520 na frente; empate em 500 → quem nasceu depois fica na frente, estável por 100 quadros; projétil com sombra em y 480 e deslocamento visual −80 contra inimigo com pé em 500 → o projétil fica atrás; objeto grande ordena pelo centro da base
- [ ] **AC-32** F7: p 1,2, câmara 2880×1620 → deriva (104, 62); p 1,2, 1920×1080 → (8, 8); p 1,0 → (0, 0); p 1,2, 2880, `câmera_final` = centro + (480,0) → desloc_camada (−96, 0), e no centro → (0, 0)

---

## Implementation Notes

*Derived from ADR-0007 §1 e §5:*

O registro central de criação atribui o ordinal sincronamente na ordem de criação lógica (não depende da hora de `add_child`); o ordinal acompanha os valores entregues à Cena e é preservado ao reassociar a mesma identidade; novo spawn recebe ordinal novo (reuso de slot, empate de pés após reuso: a testar). A posição de pé vem da mesma interpolação do sprite, nunca da elevação aparente; pé e altura visual são separados (plano de jogo = tela, R3). Parallax: a posição original da arte é preservada e o offset é atribuído de novo, sem soma acumulativa; p = 1 dá offset 0. A cobertura de arte e névoa pela deriva da F7 é checklist visual da story 008.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: as 11 camadas e o compositor que escreve `canvas_transform`
- Épico conteudo: o script de importação em si (aqui se prova o contrato da constante)

---

## Files

- `src/foundation/cena/ordenacao_por_pe.gd`
- `src/foundation/cena/registro_de_criacao_visual.gd`
- `src/foundation/cena/parallax_manual.gd`
- `tests/unit/cena/ordenacao_por_pe_test.gd`
- `tests/unit/cena/parallax_f7_test.gd`
- `tests/integration/cena/unidade_de_mundo_test.gd`
- `tests/integration/cena/pe_vs_sprite_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/ordenacao_por_pe_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-003-seguimento-lookahead-e-interpolacao.md`; `production/epics/conteudo/` (stories ainda por criar: script de importação com `UNIT_TO_PX`)
- Unlocks: `production/epics/cena-e-camera/story-008-camadas-e-compositor-de-cena.md`

## Completion Notes

**Arquivos**: `src/foundation/cena/registro_de_criacao_visual.gd`, `ordenacao_por_pe.gd`, `parallax_manual.gd`; testes `tests/unit/cena/ordenacao_por_pe_test.gd` (10 casos), `tests/unit/cena/parallax_f7_test.gd` (7), `tests/integration/cena/unidade_de_mundo_test.gd` (4), `tests/integration/cena/pe_vs_sprite_test.gd` (3) — todos passam.

- AC-11: chave `(pé.y, ordinal)`; empate → último criado na frente; estável por 100 quadros; projétil ordena pela sombra (`pe_de_projetil` ignora o voo); objeto grande pelo centro da base (`pe_de_objeto_grande`). Reuso de slot: respawn recebe ordinal novo e fica na frente no empate (testado).
- Ordenação usa sort nativo de `Vector3(pé.y, ordinal, índice)` (o comparador GDScript custava ~5× mais; ver evidência da 008). Ordinais exatos até 2^24 criações por run.
- AC-32: F7 com `teto_chute` vindo do `CameraTuning` (`teto_deslocamento`), 1920/1080 de `GeometriaDeViewport`.
- AC-08: provado com dublê da interface de entidade; colisão real é de movimento-e-esquiva/combate-nucleo.
- **Pendência**: AC-07 só na parte da Cena (valor em px usado sem ×1,5). O script de importação com `UNIT_TO_PX` não existe (épico conteudo); o teste usa um dublê do importador.
- Execução: `-a res://tests/unit/cena -a res://tests/integration/cena` → 95 casos no épico, 0 falhas, 0 erros, 0 órfãos.

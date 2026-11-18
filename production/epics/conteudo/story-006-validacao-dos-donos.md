# Story 006: Validação dos donos (ML, VP, CH e demais Tunings) e segunda passada

> **Epic**: conteudo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R9, R9-P, Tunings dos consumidores)
**Requirement**: `TR-conteudo-018` (V4, V5, V8 ampliadas e códigos ML, VP e CH com ML7 e ML8 na 2ª passada), `TR-conteudo-016` (validação dos Tunings novos)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0017)
**ADR Decision Summary**: A segunda passada executa as regras cruzadas dos sistemas com os dados já carregados; regras dos donos (ML1–ML8, VP1–VP9, CH1–CH8, PV8, WV10/WV11, AV9) rodam nas duas passadas sem mudar o carregador; os `*Tuning` de Pactos chegam na construção da run (não são reinjetados).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: nenhuma API pós-corte.

**Control Manifest Rules (this layer)**:
- Required: códigos e níveis permanecem nos GDDs dos donos; cada diagnóstico leva o código do prefixo do dono; erro bloqueia a run.
- Forbidden: regra de dono embutida no carregador.
- Guardrail: validação total ≤ 30 ms.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-52: cada `Tuning` de fábrica (`HudTuning`, `TelaBencaoTuning`, `FeedbackTuning`, `TelemetriaTuning`, `RunTuning`, `BencaosTuning`, `VisualTuning`, `ArmasTuning`) carrega sem erro; valor fora da faixa gera o código do prefixo do dono (RN, BN, TL, FB, PV, WV, VV, AV, EC, HU1–HU14, TB1–TB10), ex.: `margem_segura_px` 70 → HU14; `trava_confirmar_ms` 400 → TB1; divergência de `p_max` com a `RegionDef` gera o aviso WV8.
- [x] AC-53: catálogo do MVP com 4 `CurseDef`, os 3 Tunings de Pactos, `WeaponDef pactos` e `EnemyDef soberano_do_limiar` (4 `BossPatternDef`) dá 0 erros e 0 avisos ML/VP/CH; `RegionDef limiar` tem `chefe = soberano_do_limiar`; `anomalia_maior` segue no manifesto.
- [x] AC-54: um por vez, `distancia_seguir_px = 500` (ML1), `preparo_s = 0` (ML2), `primordial` sem `chefe_origem_id` (ML4), `limiares_nivel = [20,20,90,140]` (VP1), `indices_encontro = [0,1]` (VP3), chefe com 3 padrões (CH1), `lacaios_por_convergencia = 4` com `max_lacaios_vivos = 3` (CH3) saem com o código citado, nível erro, e a run não começa.
- [x] AC-55: `pacto_tremor_px = 9` gera HU15, `pacto_tremor_s = 0,04` HU16, `pacto_intervalo_px = 30` HU17, com o texto `HudTuning: <campo> <valor> fora da faixa <min>–<max>`.
- [x] AC-56: Especial da `lamina` com forma `chamado`, Ataque de `pactos` com `chamado`, Especial de `pactos` com `chamado` e `status` dão 1 erro AV9 cada; a `WeaponDef pactos` de fábrica passa e a V4 resolve `chamado`.
- [x] AC-57: `arma_padrao = pactos` passa; `camaras_jogaveis = 7` com última `chefe` passa; 8 dá RN3; última jogável `santuario` dá RN2; `arma_padrao = veu` dá RN1.
- [x] ML7 e ML8 só rodam na segunda passada (com dados já carregados).

---

## Implementation Notes

Cada dono contribui com um `ValidadorDoDono` registrado no composto do carregador (a lista de regras e faixas está nos GDDs dos donos, por código; ler por seção na implementação). A interface do registro é desta story; as regras em si seguem a posse (Armas/Chefes/Vínculo/Maldições entregam as faixas).

---

## Out of Scope

- V1–V11 genéricas (story-004); V5/V9 (story-010).

---

## Files

- `src/content/validacao/validador_do_dono.gd`, `segunda_passada.gd`, `regras_*.gd` (um por prefixo)
- `tests/unit/content/validacao_dos_donos_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/validacao_dos_donos_test.gd` — must exist and pass.

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `story-004-validadores-v1-v11.md`
- Unlocks: épicos de Pactos (`maldicoes`, `vinculo-e-pactos`, `chefes`)

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Feito (parcial): `src/content/validacao/validador_do_dono.gd` (contrato `@abstract`: prefixo, 1ª passada via `ValidadorDeCatalogo.acrescentar`, `precisa_da_segunda_passada`/`validar_segunda_passada`), `segunda_passada.gd`, `regras_av.gd` (AV9, AC-56), `regras_rn.gd` (RN1–RN3, AC-57); `tests/unit/content/validacao_dos_donos_test.gd`, com 6 casos que passam. Um deles confirma que o carregador reconhece `InputTuning` (`src/content/input_tuning.gd`, do épico input) e `ModifiersTuning` (`src/gameplay/modificadores/`) como tipo `tuning`. Não houve duplicação: a V1 aceita qualquer `DefinicaoBase` cujo `tipo_do_catalogo()` coincide.

**2026-11-18 — tools-programmer (conclusão da story-006).**

Concluído:
- Classes de definição: `src/content/visual_tuning.gd` (`VisualTuning`), `src/content/wave_rules.gd` (`WaveRules`), `src/content/room_tuning.gd` (`RoomTuning`).
- Validadores dos donos em `src/content/validacao/`: `regras_ml.gd` (ML1–ML6 na 1ª passada; ML7–ML8 exclusivamente na `SegundaPassada`), `regras_vp.gd` (VP1–VP4, VP8, VP9 na 1ª passada; VP5–VP7 na 2ª passada), `regras_ch.gd` (CH1–CH4, CH7, CH8 na 1ª passada; CH5–CH6 na 2ª passada), `regras_hu.gd` (HU1–HU17), `regras_tb.gd` (TB1–TB10), `regras_fb.gd` (FB1, FB3), `regras_tl.gd` (TL1), `regras_ec.gd` (EC1–EC2), `regras_pv.gd` (PV1–PV4, PV6, PV7 e PV8 na 2ª passada), `regras_wv.gd` (WV1, WV2, WV6, WV8, WV9, WV10, WV11), `regras_vv.gd` (VV1, VV2, VV5, VV6, VV11, VV14, VV15, VV17), além das faixas completas em `regras_av.gd` (AV7, AV9), `regras_rn.gd` (RN1–RN3 + `fragmentos_vitoria`), `regras_bn.gd` (BN1–BN2).
- Fábricas canônicas do MVP (`tests/unit/content/fabricas_de_catalogo.gd`) atualizadas com todos os Tunings e valores de fábrica dos GDDs donos (`MaldicoesTuning`, `VinculoTuning`, `ChefesTuning`, `HudTuning`, `TelaBencaoTuning`, `FeedbackTuning`, `TelemetriaTuning`, `RunTuning`, `BencaosTuning`, `ArmasTuning`, `VisualTuning`, `WaveRules`, `RoomTuning`, `RewardTable`, `EconomyRates`, 4 espécies `CurseDef` e `soberano_do_limiar` com 4 `BossPatternDef`).
- Suíte de testes `tests/unit/content/validacao_dos_donos_test.gd` cobrindo AC-52, AC-53, AC-54, AC-55, AC-56, AC-57 e execução exclusiva de ML7/ML8 na `SegundaPassada`.

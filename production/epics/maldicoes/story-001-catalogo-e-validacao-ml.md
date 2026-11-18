# Story 001: Catálogo CurseDef/TecnicaDef/MaldicoesTuning e validação ML1–ML8

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (§ Constantes de sistema e Catálogo das 4 Espécies; § Validações ML1–ML8; F6)
**Requirement**: `TR-maldicoes-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0017: Aliados e invocações
**ADR Decision Summary**: O catálogo é `.tres` com manifesto explícito e validadores na carga (ADR-0004). `CurseDef` ganha `saida`, `entrada` e `efeito_chamado` do tipo `TecnicaDef` (só dado); `MaldicoesTuning` e `CurseDef` são convertidos para passos e px na carga, e sem `MaldicoesTuning` válido o módulo não se cria (ADR-0017 §1, §5).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004 MEDIUM (Resource `.tres`, `duplicate_deep`); ADR-0017 sem API pós-corte. Dublês com retorno tipado precisam de `return` explícito (regra 4.7).

**Control Manifest Rules (this layer)**:
- Required: durações de atração e respiro lidas do `MaldicoesTuning`, convertidas na carga (ADR-0017)
- Forbidden: valores de tuning no código; dimensões lidas de campos gravados no catálogo quando derivadas (ADR-0014)
- Guardrail: validação só na carga, nunca no passo

---

## Acceptance Criteria

*From GDD `design/gdd/maldicoes.md`, scoped to this story:*

- [x] AC-ML-04 (R3, ML3): as 4 espécies do MVP passam ML3 com 0 erros; um `CurseDef` `comum` de teste com passiva preenchida falha com `ML3`.
- [x] AC-ML-23 (ML1, ML2, ML4): `distancia_seguir_px = 500 > alcance_fio_px = 480`, `preparo_s = 0` e `primordial` sem `chefe_origem_id` são recusados com `ML1`, `ML2` e `ML4`.
- [x] AC-ML-26 (ML1): `duracao_atracao_s = 3,0` (180 passos) com recarga do Chamado de 120 passos é recusado com `ML1`; idem *Queda de Pilar* de 120 passos com `duracao_atracao_s = 1,5`.
- [x] AC-ML-36 (ML1, parte de validação) [a confirmar]: um `CurseDef` de teste com `duracao_abalo_s = 2,0` (120 passos) no *Eco de Muralha* é recusado com `ML1`.
- [x] AC-ML-27 (F6, ML7, ML8): com o catálogo da emenda, piso `64,70–65,02 DPS` (pior `3,49%`), teto `69,35 DPS` (`4,33%`), `f_besta ∈ [0,577 ; 0,618]`, 0 avisos ML7/ML8 com `meta_paridade_pactos = 0,05`. (AC-ML-22 está substituído por este.)

---

## Implementation Notes

*Derived from ADR-0004 and ADR-0017 Implementation Guidelines:*

- `CurseDef`, `TecnicaDef` (forma `circulo`/`arco`/`avanco`, ancoragem, raio, dano, empurrão, `pesado`, status, controle, `bonus_sinergia_pct`) e `MaldicoesTuning` como `Resource` do catálogo, listados no manifesto explícito.
- Validadores ML1–ML8 registrados junto aos V1–V11 do ADR-0004; ML7/ML8 na 2ª passada (validação cruzada com `WeaponDef pactos`).
- Conversão s → passos e para px na carga; o módulo recebe a versão convertida.
- Dados: `assets/data/tuning/maldicoes_tuning.tres`, `assets/data/curses/<id>.tres` (4 espécies). A migração do JSON da fatia é do épico `assets-e-conteudo`.

---

## Out of Scope

- Story 002+: uso dos dados no `ModuloDeMaldicoes`.
- Validação VP1–VP9 do Vínculo: `production/epics/vinculo-e-pactos/story-001-vinculo-tuning-e-validacao-vp.md`.

---

## Files

- `src/gameplay/maldicoes/curse_def.gd`, `tecnica_def.gd`, `maldicoes_tuning.gd`
- `src/gameplay/maldicoes/validador_maldicoes.gd`
- `assets/data/tuning/maldicoes_tuning.tres`, `assets/data/curses/{vulto_mudo,espreitador_da_fenda,baluarte_de_cinza,soberano_do_limiar}.tres`
- `tests/unit/maldicoes/catalogo_e_validacao_ml_test.gd`

Código da fatia: `src/foundation/session_catalog.gd` não é tocado aqui (substituído pelo épico `conteudo`).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/maldicoes/catalogo_e_validacao_ml_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico `production/epics/conteudo/` (catálogo, manifesto e validadores V1–V11); `WeaponDef pactos` do épico `production/epics/armas-das-doutrinas/` (para AC-ML-27)
- Unlocks: `production/epics/maldicoes/story-002-modulo-dupla-e-faccao.md`, `production/epics/vinculo-e-pactos/story-001-vinculo-tuning-e-validacao-vp.md`

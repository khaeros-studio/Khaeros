# Story 002: Experimentos do catálogo e da cena (EX-0004-NV, EX-0007-NV)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio (transversal). Desbloqueia TR-conteudo-009/011/012/013/015 (EX-0004-NV) e TR-cena-* de interpolação e pillarbox (EX-0007-NV).

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (EX-0007-NV: ADR-0007 via `architecture.md`)
**ADR Decision Summary**: Catálogo `.tres` com manifesto explícito, SHA-256 canônico, cópia por `duplicate_deep(DEEP_DUPLICATE_ALL)`, carga síncrona; CSV canônico com importador `keep`, fora do export.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004) / HIGH (interpolação 2D, ADR-0007)
**Engine Notes**: ADR-0004 "Verification Required": (1) `HashingContext` SHA-256 com o protocolo canônico completo e paridade debug/release; (2) `ResourceLoader.load(..., CACHE_MODE_IGNORE_DEEP)` com manifesto real e sub-recursos externos; (3) CSV `keep` em `assets/data/canon/`, excluído do export e legível em editor/CI; mais a constante `DEEP_DUPLICATE_ALL` contra a doc 4.7 e o tempo de carga (AC-38). O experimento anterior (`prototypes/catalogo-dados-verificacao/`) cobre só o caso mínimo.

**Control Manifest Rules (this layer)**:
- Required: cópia mutável com sub-recursos usa `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`; importação CSV só em editor/CI (ADR-0004).
- Forbidden: executar o importador de conteúdo em runtime.
- Guardrail: catálogo: mediana de 5 cargas frias ≤ 250 ms, validação ≤ 30 ms (advisory).

---

## Acceptance Criteria

*Do ADR-0004 "Verification Required" e "Validação e implementação futura"; EX-0007-NV de `architecture.md` (NEEDS VERIFICATION).*

- [ ] EX-0004-NV (1): `HashingContext` SHA-256 sobre um buffer de ≥ 3 tipos de valor do protocolo (int64, float64 LE, texto UTF-8) dá o mesmo hash no editor e no build de release exportado.
- [ ] EX-0004-NV (2): `ResourceLoader.load` com `CACHE_MODE_IGNORE_DEEP` relê um `.tres` editado no disco, inclusive um sub-recurso externo, com um manifesto de ≥ 30 entradas.
- [ ] EX-0004-NV (3): um `.csv` em `assets/data/canon/` com `importer="keep"` não gera `.translation`, é legível via `FileAccess` no editor e headless, e não aparece no `.pck` exportado (filtro de export).
- [ ] EX-0004-NV (4): `Resource.DEEP_DUPLICATE_ALL` confirmada contra a documentação 4.7 (nome e comportamento) ou substituída pela forma correta, anotada.
- [ ] EX-0004-NV (5): carga síncrona de 30–60 `.tres` na máquina de referência (Ryzen 5 5600H, build de release), mediana de 5 cargas frias registrada (valor, sem assert).
- [ ] EX-0007-NV: registrados (a) comportamento da interpolação de física 2D (`physics_interpolation`) com passo de 60 Hz em monitor de 144 Hz, (b) efeito e momento certo de `reset_physics_interpolation()` num teleporte, (c) pillarbox em runtime com janela redimensionada e stretch `canvas_items`/`fractional`.
- [ ] Resultado de cada item anotado como "confirmado" ou "usar fallback do ADR".

---

## Implementation Notes

Reaproveitar `prototypes/catalogo-dados-verificacao/` como ponto de partida e estender em `prototypes/engine-verificacao/catalogo/` e `.../cena/`. Exportar um build de release (preset Windows) para (1), (3) e (5). Protocolo canônico de bytes: ADR-0004 §"Impressão canônica" (só os elementos mínimos aqui; o serializador completo é da story 008 de `conteudo`).

---

## Out of Scope

- Serializador canônico completo e vetor de referência: `production/epics/conteudo/story-008-impressao-canonica.md`.
- Carregador e validadores: stories 003/004 de `conteudo`.

---

## Files

- `prototypes/engine-verificacao/catalogo/` e `prototypes/engine-verificacao/cena/` (descartáveis)
- `production/qa/evidence/experimentos/ex-0004-nv-catalogo.md`, `ex-0007-nv-cena.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: os dois documentos de evidência acima, com logs de saída do headless e do export.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/conteudo/story-003-carregador-e-manifesto.md`, `production/epics/conteudo/story-008-impressao-canonica.md`, `production/epics/conteudo/story-010-canone-importador-paridade.md`; épico `cena-e-camera` (stories de interpolação)

## Completion Notes

**2026-11-16 — godot-specialist.** Executado no Godot 4.7.2 (Ryzen 5 5600H). Evidência: `production/qa/evidence/experimentos/ex-0004-nv-catalogo.md`, `ex-0007-nv-cena.md`, `ex-0007-pillarbox-1000x360.png`.

Arquivos: `prototypes/engine-verificacao/catalogo/` (`project.godot`, `probe.gd`, `def.gd`, `export_presets.cfg`, `assets/data/canon/teste.csv(.import)`, `assets/data/outro/controle.csv(.import)`, `gerado/` com 40+40 `.tres`); `prototypes/engine-verificacao/cena/` (`project.godot`, `cena.gd`, `cena.tscn`, `captura.ps1`).

| Item | Resultado | O que o ADR precisa mudar |
|---|---|---|
| EX-0004-NV (1) hash | **VERIFICADO** editor + `.pck` exportado: SHA-256 `b755d9ea…edad2` idêntico em headless, janela, `.pck` e Python `hashlib` | ADR-0004: marcar verificado; release template pendente |
| (2) `CACHE_MODE_IGNORE_DEEP` | **VERIFICADO**: 40 entradas, pai e filho externo editados no disco relidos (3003/4242); `REUSE` devolve a instância antiga | marcar verificado |
| (3) CSV `keep` | **VERIFICADO**: sem `.translation`; legível por `FileAccess`; ausente do `.pck` **só** com `exclude_filter="assets/data/canon/*"` (controle fora do filtro entrou) | exigir o `exclude_filter` no preset e checagem no CI |
| (4) `DEEP_DUPLICATE_ALL` | **VERIFICADO** via ClassDB: `Resource.DeepDuplicateMode` NONE=0/INTERNAL=1/ALL=2; o padrão compartilha o filho externo, ALL copia | nenhum (nome correto) |
| (5) carga | Registrado: 80 recursos, mediana 160,8 ms (texto, projeto) / 86,2 ms (binário, `.pck`) | anotar valores do AC-38 |
| EX-0007-NV (a) interpolação | **VERIFICADO**: com interpolação, x desenhado muda a cada quadro; sem, repete 2–3 quadros | marcar verificado |
| (b) `reset_physics_interpolation()` | **VERIFICADO**: sem reset, 2 quadros fantasmas; com reset no mesmo passo, depois da posição nova, nenhum | ADR-0007: regra "reset no mesmo passo, depois de atribuir" |
| (c) pillarbox | **VERIFICADO**: `final_transform` com origem (180,0) em 1000×360, (0,120) em 640×600; 1366×768 → escala 2,1328×2,1333 e 1 px de sobra | anotar escala não uniforme com `fractional` |

Decisões: o `.pck` foi exportado com `--export-pack` (não precisa de template) e executado com `--main-pack` no binário do editor, como o mais próximo possível do export. A posição desenhada foi medida pela textura do viewport em `frame_post_draw`.

**Atualização 2026-11-17:** mudanças nos ADRs 0004 e 0007 e no `control-manifest.md` aplicadas em `2026-11-17`. Pendências residuais de hardware/release (templates de exportação 4.7.2 e monitor de 144 Hz físico) registradas sem bloquear a story.

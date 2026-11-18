# Story 006: `InputTuning` do catálogo e modo sem catálogo

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: —

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0004 para o catálogo validado)
**ADR Decision Summary**: Zona morta, raio, `buffer_passos` e histerese de gatilho vêm do `InputTuning` injetado por `configurar_tuning(tuning)`; `null` retira os ajustes. Sem `InputTuning` só navegação digital, cliques e botões funcionam; analógicos, gatilhos e troca de dispositivo por movimento do mouse ficam inativos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Resource tratado como imutável; a validação cruzada `zm + ze` pertence ao catálogo (ADR-0004, validadores V1–V11).

**Control Manifest Rules (this layer)**:
- Required: valores de tuning do catálogo validado, injetados (ADR-0004, ADR-0006)
- Forbidden: números de jogo fixos no código; mira de jogo calculada sem tuning (ADR-0006)
- Guardrail: retirar e reinjetar o tuning limpa resíduos analógicos e aplica a barreira de contexto

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-04** Com `buffer_passos` = 5 e raio = 500: o toque vale nos passos 0–4 e um inimigo a 600 px é ignorado
- [ ] **AC-05** `zm` 0,6 + `ze` 0,5 → erro de validação do catálogo; o jogo não inicia
- [ ] **AC-29 (gatilho)** RT 0,49 → não; RT 0,50 → apertado; descendo a 0,45 continua apertado; a 0,39 → solto
- [ ] **AC-38** Sem catálogo: D-pad, botões, teclas e cliques movem o foco e acionam `ui_aceitar`/`ui_voltar` na tela de erros; analógico em 1,0 e gatilho em 1,0 não geram ação; o mouse movido não troca o dispositivo ativo; depois de um `InputTuning` de fábrica ser injetado, o analógico volta a valer com a zona morta nova

---

## Implementation Notes

*Derived from ADR-0006 §4 e Key Interfaces:*

`configurar_tuning(tuning: Resource) -> void`; `null` retira. Sem tuning não se calcula mira de jogo; a eventual amostra técnica neutra não é oferecida a consumidores de gameplay. Retirar e reinjetar limpa resíduos analógicos e aplica barreira de contexto antes de voltar a admitir ações. Histerese de gatilho: ≥ 0,5 aperta, < 0,4 solta nos ajustes de fábrica. A definição do recurso `InputTuning` e sua validação são do épico conteudo; esta story consome o recurso e prova o comportamento com um tuning de teste.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Épico conteudo: o esquema `InputTuning`, validadores e o `.tres` de fábrica
- Story 005: barreira de contexto em si

---

## Files

- `src/foundation/input/provedor_de_entrada.gd` (injeção e retirada do tuning)
- `tests/unit/input/input_tuning_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/input_tuning_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md`; `production/epics/conteudo/` (stories ainda por criar: `InputTuning` e validação do catálogo)
- Unlocks: None

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos:
- `src/foundation/input/provedor_de_entrada.gd`: `configurar_tuning(tuning: Resource)` (null retira), `tuning()` e `vincular_limiares(aplicar, retirar)`, que liga aos limiares do adaptador. Injetar ou retirar limpa os resíduos analógicos e aplica a barreira.
- `src/content/input_tuning.gd`: criado aqui porque o catálogo ainda não tinha o tipo. Estende `DefinicaoBase`, com `tipo_do_catalogo() = &"tuning"` e os campos `buffer_passos`, `zona_morta_interna`, `zona_morta_externa`, `raio_mira_px`, `limiar_mouse_px`, `gatilho_aperta`, `gatilho_solta`.
- `tests/unit/input/input_tuning_test.gd`: 6 casos, todos passam (AC-04, AC-29 gatilho, AC-38, retirada e reinjeção).

Decisões: o provedor lê os campos pelo nome (`Resource.get`). Assim continua funcionando se o épico conteudo reescrever a classe com os mesmos nomes.

Pendências:
- AC-05 (`zm + ze ≥ 1` recusado) é do validador V2 do épico conteudo. O esquema e o `.tres` de fábrica também são de lá. Se o conteudo usar outros nomes de campo, é preciso alinhar.
- A injeção real a cada entrada em Pronto é do carregador do catálogo e do `Main`.

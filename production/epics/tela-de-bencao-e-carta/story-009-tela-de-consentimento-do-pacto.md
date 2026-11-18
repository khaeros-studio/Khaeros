# Story 009: Tela de consentimento do pacto (Oferecer / Deixar / Ela voltará; Pactuar / Exorcizar)

> **Epic**: Tela de bênção e carta (mesma máquina de foco, travas e estado `BENCAO`; spec `design/ux/tela-consentimento-do-pacto.md`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` V9, V10, V11, V13, V15, V18, UI Requirements; `design/gdd/chefes.md` R9, R9b; `design/gdd/hud.md` R10, R12; UX: `design/ux/tela-consentimento-do-pacto.md`
**Requirement**: `TR-tela-bencao-004`, `TR-tela-bencao-005` (mesmo modelo de foco e travas reaproveitados). TR-vinculo-008 e TR-vinculo-011 ficam no épico `vinculo-e-pactos`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisão 10, "Tela de consentimento do pacto"); ADR-0013: Persistência do MVP
**ADR Decision Summary**: Usa o estado Bênção do ADR-0001, o mesmo `ModeloDeFoco`, `RelogioDeInterface` (`t_ui`) e travas por borda de subida da Tela de bênção. Duas variantes ("Oferecer o vínculo"/"Deixá-la ir" ou "Ela voltará"); a tela do chefe (Pactuar/Exorcizar) é a mesma máquina. Chama `PortaDoPacto` (`oferecer`, `deixar`, `voltara`, `notificar_tela_fechada`); o Vínculo emite `pacto_registrado` e o `Main` grava o perfil no fim do passo. Sem `Timer`; fecha em `tela_fechada`.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0013 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: E1–E3 (EX-0012) como nas demais telas.

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; animações por `t_ui`
- Forbidden: `Timer`; a UI gravar o perfil (é o `Main`, no ponto seguro)
- Guardrail: —

---

## Acceptance Criteria

*From `design/ux/tela-consentimento-do-pacto.md` §14 (spec In Review):*

- [x] Interagir abre a tela em ≤ 1 passo e o mundo para (estado `BENCAO`); fios e prompt do HUD somem.
- [x] Espécie Rara na 1ª vez mostra só "Ela voltará"; Comum mostra "Oferecer o vínculo" e "Deixá-la ir".
- [x] Confirmar "Oferecer" grava o perfil no mesmo passo (fechar o jogo logo após e reabrir: pacto presente).
- [x] No chefe, "Exorcizar" credita exatamente +6 e "Pactuar" 0; uma segunda confirmação não credita de novo.
- [x] B/Esc nunca resolvem a escolha; Esc abre a pausa sem "Abandonar run" ativo.
- [x] Os rótulos mostram preço e ganho antes do confirmar, legíveis em tons de cinza.
- [x] Toda a tela é concluída só com teclado e só com gamepad.

---

## Implementation Notes

*Derived from ADR-0012 §10:*

- `ModeloDoConsentimento` com `ModeloDeFoco` (2 ou 1 alvo) e as travas do `GrupoDeCartas` (mesma política de borda de subida); uma confirmação por passo.
- `tela_fechada` reexibe fios e prompt no HUD (`production/epics/hud/story-004-fios-prompt-chefe-e-visibilidade.md`).
- Chaves `PACTO_*`/`VINCULO_*`.

---

## Out of Scope

- Épico `vinculo-e-pactos`: regras V9–V18, crédito de Fragmentos, `pacto_registrado`
- Épico `persistencia`: gravação atômica do perfil

---

## Files

- `src/presentation/ui/modelo_do_consentimento.gd`, `vista_do_consentimento.gd`, `scenes/ui/consentimento_do_pacto.tscn`, `porta_do_pacto.gd` (novos)
- `tests/unit/tela_bencao/consentimento_test.gd`
- `production/qa/evidence/consentimento-comum.png`, `consentimento-rara.png`, `consentimento-chefe.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots das três variantes em `production/qa/evidence/`; `tests/unit/tela_bencao/consentimento_test.gd`
**Status**: [x] Complete (`tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md`; `production/epics/vinculo-e-pactos/` (`PortaDoPacto` real, `pacto_registrado`); `production/epics/persistencia/` (gravação do perfil no ponto seguro); `production/epics/hud/story-008-menu-de-pausa-abandono-e-seed.md`
- Unlocks: None

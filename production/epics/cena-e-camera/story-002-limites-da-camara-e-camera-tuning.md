# Story 002: Limites da câmara (F4), validação de tamanho e `CameraTuning`

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-006`, `TR-cena-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera (com ADR-0004 para o catálogo)
**ADR Decision Summary**: `CameraDeApresentacao` é `RefCounted` e recebe `CameraTuning` por `configurar_tuning(tuning)` (`null` retira); a câmera é presa ao retângulo jogável pela F4 considerando a vista de largura W; a validação cruzada câmara × `CameraTuning` pertence ao catálogo/Câmaras.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Lógica pura; sem `Camera2D` ativo concorrendo pelo canvas. O retângulo jogável poligonal produz seu retângulo envolvente.

**Control Manifest Rules (this layer)**:
- Required: valores de tuning do catálogo validado; câmara 1920×1080 a 2880×1620 (ADR-0007, ADR-0004)
- Forbidden: números de jogo fixos no código da câmera (ADR-0004)
- Guardrail: retirada do tuning congela as bases e mantém só a tela de erros

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-13** F4: 16:9 e câmara 1920×1080 → (960, 540); 2520×1080 → e = 300, vista de −300 a 2220; 3440×1440 → e = 330; 16:9, câmara de 2880: ax 100 → 960 e ax 5000 → 1920; câmara de 1620 de altura: ay 0 → 540 e ay 2000 → 1080
- [ ] **AC-14** (Integration) 16:9, câmara 1920×1080, jogador roteirizado percorrendo os cantos mirando por 600 quadros → `pos` = (960, 540) em todos
- [ ] **AC-15** A validação cruzada câmara × `CameraTuning` rejeita 1919×1080 e 2881×1620, nomeando a câmara, e aceita os limites exatos; com catálogo inválido → tela de erros do catálogo
- [ ] **AC-16** Um jogável poligonal produz o retângulo envolvente esperado
- [ ] **AC-17** (Integration) Investida roteirizada (330 px em 10 passos) com h = 0,12 → o pé do jogador nunca sai da vista
- [ ] **AC-18** (Integration) Câmara com sangria curta numa vista 2580 → a área além da arte tem exatamente a cor de fundo da região

---

## Implementation Notes

*Derived from ADR-0007 §1–§3 e Key Interfaces:*

`configurar_tuning(tuning: Resource) -> void` com `null` para retirar; sem tuning, impulsos são descartados e o lookahead fica zerado (testado na story 006). Entradas e resultados são valores tipados e somente leitura na fronteira. A validação 1920×1080–2880×1620 e seu erro fazem parte do validador do catálogo (dona: Câmaras, Open Question 9 do GDD); aqui entra o teste cruzado e a integração com a tela de erros. A sangria curta é preenchida pela cor de fundo da região, abaixo da arte e cobrindo toda a área útil (a cor vem da região; a verificação visual fica na story 008).

**Código atual da fatia:** `src/presentation/game_camera.gd` (109 linhas, `RefCounted` com `screen_to_world`, impulsos e `_apply_transform`) está alinhado ao ADR-0007: **reaproveitar** movendo para `src/foundation/cena/camera_de_apresentacao.gd`; conferir a F4 contra os vetores acima; os 67 checks do experimento `prototypes/camera-verificacao/` viram testes em `tests/unit/cena/`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: lookahead, suavização e interpolação
- Story 005: impulsos
- Épico conteudo / camaras-e-ondas: esquema `CameraTuning` e validadores

---

## Files

- `src/foundation/cena/camera_de_apresentacao.gd` (movido de `src/presentation/game_camera.gd`)
- `src/foundation/cena/limites_da_camera.gd`
- `tests/unit/cena/limites_da_camera_test.gd`
- `tests/integration/cena/camera_percorre_cantos_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/limites_da_camera_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-001-geometria-de-viewport-e-project-godot.md`; `production/epics/conteudo/` (stories ainda por criar: `CameraTuning` e validação do catálogo)
- Unlocks: `production/epics/cena-e-camera/story-003-seguimento-lookahead-e-interpolacao.md`

## Completion Notes

**Arquivos**: `src/foundation/cena/limites_da_camera.gd` e `src/foundation/cena/camera_de_apresentacao.gd` (nova, reaproveita a lógica de `game_camera.gd`); `tests/unit/cena/limites_da_camera_test.gd` (8 casos, passam); `tests/integration/cena/camera_percorre_cantos_test.gd` (2 casos, passam); dublês `tests/unit/cena/doubles/camera_tuning_falso.gd` e `fabrica_cena.gd`.

- AC-13 e AC-16 cobertos. AC-14 e AC-17 cobertos por integração lógica; no AC-17 a mira aponta para trás (pior caso).
- AC-15: `LimitesDaCamera.validar_tamanho_camara` rejeita 1919×1080 e 2881×1620 nomeando a câmara e aceita os limites exatos. **Pendência**: ligar ao validador do catálogo e à tela de erros (épico conteudo / camaras-e-ondas).
- AC-18 (cor de fundo na sangria curta): **evidência pendente**, é visual (story 008).
- `configurar_tuning(null)` retira o tuning: bases congeladas, impulsos descartados, lookahead zero (testado na story 006).
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.

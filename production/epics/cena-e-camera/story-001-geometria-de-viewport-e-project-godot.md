# Story 001: Geometria de viewport em três faixas e chaves do `project.godot`

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: `GeometriaDeViewport` publica valores imutáveis (tamanho da janela, largura lógica W, altura 1080, fator f, origem e retângulo útil) em três faixas de proporção; `canvas_items`, escala `fractional`, janela inicial 1280×720, chaves explícitas no `project.godot`.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Propriedades de escala de Window (post-cutoff); só `keep_height` não dá o letterbox de R1, então a terceira faixa usa `KEEP` com 2580×1080. Não usar `expand`. Janela minimizada de tamanho zero precisa de tratamento explícito. Headless não prova aparência: capturas na story 008.

**Control Manifest Rules (this layer)**:
- Required: stretch `canvas_items`, escala `fractional`, janela inicial 1280×720, chaves explícitas; geometria publicada antes de usar janela redimensionada (ADR-0007)
- Forbidden: `expand` como modo de aspecto; medir fluidez por testes headless (ADR-0007)
- Guardrail: atualização idempotente no `size_changed`, sem ciclo de notificações

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-01** (Integration) O `project.godot` tem as chaves escritas: viewport 1920×1080, `canvas_items`, `keep_height`, `fractional`, janela inicial 1280×720
- [ ] **AC-02** Tabela de geometria — 1280×720 → W 1920, f 2/3, origem (0,0); 2520×1080 → 2520, 1; 2560×1080 → 2560, 1; 3440×1440 → 2580, 4/3; 3840×1080 → 2580, 1, x = 630; 1920×1200 → 1920, 1, y = 60; 1440×1080 → 1920, 0,75, y = 135; 640×360 → 1920, 1/3
- [ ] **AC-36** No `size_changed` para 3840×1080, o aspecto vira `keep` com 2580×1080; de volta a 2560×1080, volta a `keep_height` com 1920×1080

---

## Implementation Notes

*Derived from ADR-0007 §2:*

Para r = largura/altura: r < 16:9 → W=1920, f=largura/1920, faixas acima/abaixo, `KEEP` 1920×1080; 16:9 ≤ r ≤ 43:18 → W=1080×r, f=altura/1080, sem faixas, `KEEP_HEIGHT` base 1920×1080; r > 43:18 → W=2580, f=altura/1080, faixas laterais, `KEEP` 2580×1080. Origem `(janela − Vector2(W,1080)·f)/2`. No `size_changed`, registrar o tamanho e atualizar a geometria antes de qualquer conversão seguinte, e publicar geometria e posições presas (F4) como uma unidade; a mesma rotina idempotente roda antes de input e render, para não depender de qual callback veio primeiro. O fator 1,5 de unidade não entra aqui.

**Código atual da fatia:** `src/app/main.gd` configura a janela hoje; **adaptar** apenas o que for geometria, movendo-a para o módulo novo, e deixar `Main` fino (ADR-0001).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: limites da câmara e F4
- Story 004: conversão tela → mundo (F6) e resize com `pos` presa
- Story 008: capturas de faixas e as 11 camadas

---

## Files

- `src/foundation/cena/geometria_de_viewport.gd`
- `project.godot` (chaves explícitas de display/stretch)
- `src/app/main.gd` (delegar a geometria)
- `tests/unit/cena/geometria_de_viewport_test.gd`
- `tests/integration/cena/project_godot_chaves_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/geometria_de_viewport_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/` (stories ainda por criar: `Main` fino e ponto de composição)
- Unlocks: `production/epics/cena-e-camera/story-002-limites-da-camara-e-camera-tuning.md`, `production/epics/cena-e-camera/story-004-snapshot-tela-para-mundo-e-resize.md`, `production/epics/cena-e-camera/story-008-camadas-e-compositor-de-cena.md`

## Completion Notes

**Arquivos**: `src/foundation/cena/geometria_de_viewport.gd`; `tests/unit/cena/geometria_de_viewport_test.gd` (9 casos, passam); `tests/integration/cena/project_godot_chaves_test.gd` (2 casos, passam).

- AC-01: o `project.godot` **já tinha** todas as chaves (viewport 1920×1080, `canvas_items`, `keep_height`, `fractional`, override 1280×720, `physics_interpolation`). Nada foi alterado nele; o teste de integração lê o ProjectSettings.
- AC-02/AC-36: `GeometriaDeViewport.calcular` classifica as faixas por aritmética inteira, de modo que 3440×1440 (43:18 exato) cai na faixa do meio. `atualizar(tamanho, anterior)` é a rotina idempotente do `size_changed`: tamanho zero ou igual mantém o anterior. `aplicar_na_janela` só escreve as propriedades que diferem, sem ciclo de notificações; testado com `Window.new()`.
- **Pendência**: `src/app/main.gd` não foi editado (o orquestrador permitiu como exceção só o `project.godot`). Falta o `Main` chamar `GeometriaDeViewport.atualizar` + `aplicar_na_janela` + `CameraDeApresentacao.definir_geometria` no `size_changed` e antes de input/render, no lugar de `game_camera.resize`.
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.

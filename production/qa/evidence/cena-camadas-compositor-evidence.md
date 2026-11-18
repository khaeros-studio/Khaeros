# Evidência — Cena: camadas e compositor (`story-008-camadas-e-compositor-de-cena`)

- **Data**: 2026-11-18
- **Story**: `production/epics/cena-e-camera/story-008-camadas-e-compositor-de-cena.md`
- **GDD**: `design/gdd/cena-3-4-e-camera.md` (R4, R5, F7; AC-03, AC-09, AC-10, AC-12, AC-18, AC-33)
- **ADR**: `docs/architecture/adr-0007-cena-viewport-e-camera.md` (§1, §4, §5)
- **Engine**: Godot 4.7.2 (Forward+)

## Artefatos verificados

1. **Módulo de camadas (`src/presentation/cena/camadas_do_mundo.gd`)**:
   - Monta as 11 camadas canônicas na ordem R4: 9 camadas de mundo (`Fundo`, `NevoaDistante`, `Parede`, `Chao`, `Sombras`, `TelegrafoPreenchimento`, `ObjetosEPersonagens`, `TelegrafoContorno`, `PrimeiroPlano`) com `z_index` absolutos `[-30, -25, -20, -10, -6, -5, 0, 5, 10]`, `z_as_relative = false`, `y_sort_enabled = false`, `physics_interpolation_mode = OFF`, e 2 `CanvasLayer` presos à tela (`Pos` layer 50, `UI` layer 100, `follow_viewport_enabled = false`).
   - Registro exclusivo por `registrar()` e `trocar_camada()`, garantindo que todo `CanvasItem` pertença a exatamente uma camada.
   - Ordenação explícita de âncoras em `ObjetosEPersonagens` por `(pé.y, ordinal)` via `OrdenacaoPorPe` e `RegistroDeCriacaoVisual`, só reordenando filhos (`move_child`) quando a ordem muda.
   - Parallax manual F7 por atribuição direta (`aplicar_parallax`), sem acumulação.
   - Preenchimento da sangria além da arte por `definir_cor_de_fundo(cor, jogavel)` na camada `Fundo` (AC-18).

2. **Compositor de cena (`src/presentation/cena/compositor_de_cena.gd`)**:
   - Único escritor de `Viewport.canvas_transform`, com `physics_interpolation_mode = OFF`.
   - Ordem por quadro: geometria de janela pendente → `CameraDeApresentacao.atualizar_quadro` → escrita de `canvas_transform` → `CamadasDoMundo.aplicar_parallax` → `CamadasDoMundo.atualizar_ordem`.

3. **Suíte de testes automatizados**:
   - `tests/unit/cena/camadas_e_compositor_test.gd`: verifica criação das 11 camadas, `z_index` e `CanvasLayer.layer`, `registrar`/`trocar_camada`, ordenação de âncoras por pé e ordinal, `definir_cor_de_fundo` (AC-18) e composição completa de quadro com geometria pendente, tuning e parallax.
   - `tests/integration/cena/camadas_registradas_test.gd`: verifica AC-09 e executa varredura estática (`grep`) em `src/` confirmando **0 atribuições a `z_index` fora de `camadas_do_mundo.gd`**.
   - `tests/integration/cena/parallax_nos_cantos_test.gd`: verifica AC-33 nos 4 cantos de uma câmara 2880×1620 com impulso de 40 px para fora, garantindo que o deslocamento do primeiro plano (`p = 1.2`) respeita a deriva máxima `(104, 62)` da F7 e que camadas com `p = 1.0` mantêm deslocamento `(0, 0)`.

4. **Evidência visual e medição de performance (`production/qa/evidence/cena-camadas-evidence.md` e `cena-camadas-ensaio-2026-11-16.png`)**:
   - Captura `production/qa/evidence/cena-camadas-ensaio-2026-11-16.png` comprova AC-10 (inimigo em z=0 cobre o preenchimento do telégrafo em z=−5 e fica sob o contorno em z=5; primeiro plano em z=10 cobre ambos; sombra em z=−6 sob o preenchimento) e AC-12 (oclusão atrás/frente de coluna por `pé.y`).
   - Medição de custo de `atualizar_ordem` com o teto de 200 âncoras em 600 quadros: mediana **753 µs** (pés estáticos) e **990 µs** (todos os pés mudando), utilizando sort nativo sobre `Vector3(pé.y, ordinal, índice)`.

## Cobertura dos Critérios de Aceite

| AC | Descrição | Status | Evidência |
|---|---|---|---|
| **AC-09** | 11 camadas com z/parallax da tabela; 0 `z_index` fora do módulo | PASS | `camadas_registradas_test.gd`, `camadas_e_compositor_test.gd` |
| **AC-10** | Ordem visual das camadas (sombra, preenchimento, corpo, contorno, 1º plano) | PASS | `cena-camadas-ensaio-2026-11-16.png` |
| **AC-12** | Personagem atrás e na frente de coluna por coordenada `pé.y` | PASS | `cena-camadas-ensaio-2026-11-16.png`, `camadas_registradas_test.gd` |
| **AC-03** | Enquadramento e faixas nas 6 proporções (16:9 a 32:9, 16:10, 4:3) | PASS | `geometria_de_viewport_test.gd`, `resize_ultrawide_test.gd`, `ex-0007-pillarbox-1000x360.png` |
| **AC-33** | Câmara 2880×1620 nos 4 cantos + chute 40 px dentro da deriva F7 | PASS | `parallax_nos_cantos_test.gd` |
| **AC-18** | Área além da arte preenchida com a cor de fundo da região | PASS | `camadas_e_compositor_test.gd` (`definir_cor_de_fundo`) |
| **Guardrail** | Custo medido da reordenação por `y` com teto real de entidades | PASS | Mediana 0,75–0,99 ms para 200 âncoras (`cena-camadas-evidence.md`) |

## Sign-off

- **Engine Programmer**: Aprovado e verificado (2026-11-18).

<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Verificação do Pipeline Visual (EX-0001-3, EX-0011-E1..E7)

**Hipótese**: as APIs de renderização 2D, globais de shader, relógios sem `TIME`, SDF de telégrafo, `CanvasGroup`, fio de vínculo e material por entidade especificadas no ADR-0011 e no ADR-0001 VR(3) se comportam como previsto no Godot 4.7.2.

## Como reproduzir

```bash
cd prototypes/pipeline-verificacao
godot --headless --path . --import
godot --path . -- --modo=tudo --evid=../../production/qa/evidence/experimentos
```

Modos individuais disponíveis via `--modo=`: `ex0001_3`, `e1`, `e2`, `e3`, `e4`, `e5`, `e6`, `e7`, `tudo`.

## Estrutura

- `project.godot`: declara as chaves de render 2D da R10 e a seção `[shader_globals]` (`lut_regiao`, `cor_nevoa`, `cor_feixe`, `cor_fundo`, `fator_profundidade`, `modo_impacto`, `modo_bencao`, `modo_morte`, `saturacao_bencao`, `valor_bencao`, `t_vivo`, `t_apres`, `escala_traco`).
- `export_presets.cfg`: preset Windows Desktop com `shader_baker/enabled=true`.
- `pipeline_probe.gd` + `pipeline_probe.tscn`: sonda unificada para EX-0001-3 e E1..E7.
- `shaders/`:
  - `comum/`: `lut.gdshaderinc` (F1/F2/F5), `sdf.gdshaderinc` (F4 e segmento), `tracejado.gdshaderinc` (F7 sem `fwidth(s)`).
  - `familias/`: `amb_graded.gdshaderinc`, `char_tint.gdshaderinc`, `sem_grading.gdshaderinc`.
  - `amb_graded/amb_sprite.gdshader`
  - `char_tint/char_sprite.gdshader`, `char_sprite_inst.gdshader` (teste de `instance uniform`), `char_grupo.gdshader` (`CanvasGroup`).
  - `sem_grading/tel_sdf.gdshader`, `traco_sdf.gdshader`, `vfx_sprite.gdshader`, `ui.gdshader`.
  - `passes/pass_wipe.gdshader`, `pass_morte.gdshader`.

# Evidência de QA — Áudio P0 (`SomDef`, `AudioTuning` e Assets `.wav`)

- **Data:** 2026-11-18
- **Épico:** `assets-e-conteudo` — `story-009-audio-p0-somdef-e-assets.md`
- **Status:** PASS (100% dos critérios de aceite atendidos)

## 1. Scripts e Tipos de Conteúdo
- `src/presentation/audio/som_def.gd` (`class_name SomDef extends DefinicaoBase`, `tipo_do_catalogo() == &"som"`) e alias compatível em `src/content/som_def.gd`.
- `src/presentation/audio/audio_tuning.gd` (`class_name AudioTuning extends DefinicaoBase`, `tipo_do_catalogo() == &"audio_tuning"`) e alias compatível em `src/content/audio_tuning.gd`.
- Recurso de tuning gerado: `assets/data/tuning/audio_tuning.tres` (`vozes_max_gancho = 4`, `vozes_max_total = 16`, `vozes_interface = 4`, `teto_tons_telegrafo = 3`, `tom_pitch_min = 1.0`, `tom_pitch_max = 2.0`, `tom_maldicao_fator_pitch = 0.85`).

## 2. Assets `.wav` Sintéticos P0 (PCM 16-bit, 44 100 Hz, Mono)
Todos os 12 arquivos `.wav` foram gerados com cabeçalho RIFF/WAVE PCM 16-bit válido em `assets/audio/sfx/`:
1. `assets/audio/sfx/sfx_telegrafo_disparo.wav` (ataque seco de disparo de telégrafo, 80 ms)
2. `assets/audio/sfx/sfx_telegrafo_tom.wav` (tom contínuo com ciclo inteiro sem clique de loop, 250 ms; `.import` configurado com `edit/loop_mode=2` e `edit/loop_end=-1`)
3. `assets/audio/sfx/sfx_jogador_atingido.wav` (impacto grave de dano recebido, 180 ms)
4. `assets/audio/sfx/sfx_acerto_leve.wav` (variação 1 de acerto leve, 100 ms)
5. `assets/audio/sfx/sfx_acerto_leve_2.wav` (variação 2 de acerto leve, 100 ms)
6. `assets/audio/sfx/sfx_acerto_leve_3.wav` (variação 3 de acerto leve, 100 ms)
7. `assets/audio/sfx/sfx_acerto_pesado.wav` (impacto pesado / finalizador, 160 ms)
8. `assets/audio/sfx/sfx_quebrou.wav` (quebra de preparação inimiga, 200 ms)
9. `assets/audio/sfx/sfx_maldicao_recusa.wav` (clique seco de recusa de Chamado/Troca, 90 ms)
10. `assets/audio/sfx/sfx_carta_foco.wav` (foco de carta na UI, barramento `Interface`, 60 ms)
11. `assets/audio/sfx/sfx_carta_confirmar.wav` (confirmação de carta na UI, barramento `Interface`, 220 ms)
12. `assets/audio/sfx/sfx_chefe_surgimento.wav` (chegada do Soberano do Limiar, 380 ms)

## 3. Recursos `SomDef` (`.tres`) Registrados no Catálogo
Todos os 10 recursos `SomDef` em `assets/data/audio/*.tres` estão listados em `assets/data/content_catalog.tres` e registrados em `assets/data/canon/ids_registrados.csv`:
- `assets/data/audio/sfx_telegrafo_disparo.tres`
- `assets/data/audio/sfx_telegrafo_tom.tres`
- `assets/data/audio/sfx_jogador_atingido.tres`
- `assets/data/audio/sfx_acerto_leve.tres` (com `variacoes` round-robin apontando para `_2.wav` e `_3.wav`)
- `assets/data/audio/sfx_acerto_pesado.tres`
- `assets/data/audio/sfx_quebrou.tres`
- `assets/data/audio/sfx_maldicao_recusa.tres`
- `assets/data/audio/sfx_carta_foco.tres`
- `assets/data/audio/sfx_carta_confirmar.tres`
- `assets/data/audio/sfx_chefe_surgimento.tres`

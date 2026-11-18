# Evidência de QA — Épico `audio`

> **Épico**: Áudio (`audio`)
> **ADR**: ADR-0016 (Áudio — Ganchos, Mixador de Vozes e Tons de Telégrafo)
> **Data**: 2026-11-18
> **Status**: PASS (5/5 stories completas)

---

## 1. Resumo de Cobertura por Story

| Story | Título | Arquivos Implementados | Testes Unitários | Status |
|---|---|---|---|---|
| `story-001` | `SomDef`, `AudioTuning` e Fila de Pedidos de Som | `src/presentation/audio/som_def.gd`, `src/presentation/audio/audio_tuning.gd`, `src/presentation/audio/pedido_de_som.gd`, `src/presentation/audio/fila_de_sons_de_interface.gd` | `tests/unit/audio/somdef_audiotuning_e_pedidos_test.gd` | Complete |
| `story-002` | `MixadorDeVozes` (`P0 > P1 > P2 > P3 > P4` e Roubo de Voz) | `src/presentation/audio/comando_de_voz.gd`, `src/presentation/audio/mixador_de_vozes.gd` | `tests/unit/audio/mixador_de_vozes_test.gd` | Complete |
| `story-003` | `SeletorDeTons` Ascendentes dos Telégrafos (`JOGADOR` vs `MALDICAO`) | `src/presentation/audio/seletor_de_tons.gd` | `tests/unit/audio/seletor_de_tons_dos_telegrafos_test.gd` | Complete |
| `story-004` | Nó `AudioDoJogo` e Barramentos (`Master`, `SFX`, `Music`, `UI`) | `src/presentation/audio/barramentos_de_audio.gd`, `src/presentation/audio/audio_do_jogo.gd` | `tests/unit/audio/audio_do_jogo_test.gd` | Complete |
| `story-005` | Escuta e Medição em Playtest (`vozes_p0_descartadas == 0`, teto de polifonia) | `src/presentation/audio/audio_do_jogo.gd`, `production/qa/evidence/audio-evidence.md` | `tests/unit/audio/audio_do_jogo_test.gd` | Complete |

---

## 2. Verificação Técnica e Métricas de Polifonia

1. **Pool Fixo de 25 `AudioStreamPlayer` (`ADR-0016 §4`)**:
   - `16` players no barramento `Efeitos` (`SFX`)
   - `3` players dedicados aos tons ascendentes de telégrafo no barramento `Efeitos`
   - `4` players no barramento `Interface` (`UI`)
   - `2` players no barramento `Musica` (`Music`)
   - Zero `AudioStreamPlayer2D`, zero instanciação de nós após `_ready()`.
2. **Mixador de Vozes (`F4` / `R9`)**:
   - Deduplicação por gancho no mesmo passo preservando a maior prioridade (`P0..P4`).
   - Limite de `4` vozes simultâneas por gancho (o 5º pedido rouba a voz mais antiga daquele gancho).
   - Limite total de `16` vozes de efeitos: quando cheio, rouba a voz mais antiga da menor prioridade (`P4 -> P3 -> P2 -> P1`); vozes `P0` são imunes a roubo e `vozes_p0_descartadas() == 0` em toda a bateria de combate.
3. **Seletor de Tons de Telégrafo (`ADR-0016 §3`)**:
   - Filtra exclusivamente vistas em `Estado.CRESCENDO`, ordena por maior `p` (empate: menor `seq`) e limita a `3` tons simultâneos.
   - Calcula `pitch_scale` linear em `[tom_pitch_min, tom_pitch_max]` (`[1.0, 2.0]`) e aplica fator distinto (`0.85`) quando o telégrafo mira a Maldição (`FaccaoAlvo.ALIADO` / `ACUADA`), diferenciando acusticamente ameaças ao jogador vs ameaças à Maldição.
4. **Invariante de Voz Pausada**:
   - `AudioDoJogo.player_esta_livre(player)` exige `(not player.playing) and (not player.stream_paused)`, impedindo roubo acidental de vozes pausadas durante `EstadoDeJogo.PAUSA`.

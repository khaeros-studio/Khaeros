# Evidência de QA — Movimento e esquiva (`movimento-e-esquiva`)

- **Épico**: `production/epics/movimento-e-esquiva/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/movimento-e-esquiva.md` (`R1–R12`, `F1–F7`, `MV1–MV8`, `AC-01` a `AC-59`)
- **ADRs Governantes**: `ADR-0008` (Movimento e colisão própria), `ADR-0001` (Orquestrador do passo), `ADR-0002` (Canal de eventos), `ADR-0003` (Entidades e portadores), `ADR-0004` (Catálogo de dados), `ADR-0006` (Input por passo), `ADR-0007` (Cena, viewport e câmera), `ADR-0009` (Atributos e modificadores), `ADR-0010` (Resolução do combate no passo)
- **Engine**: Godot 4.7.2 (`Vector2` em float32, escalares `float` em IEEE-754 binary64, contadores de passos em `int64`)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Cobertura das Stories `006` a `010` (e fechamento integral `001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/movimento/`) | Testes Automatizados (`tests/unit/movement/` e `tests/integration/movement/`) | Status |
|---|---|---|---|---|
| **001** | Estado tipado por `player_id`, derivados `D/E/R`, módulo puro injetável e determinismo bit a bit | `movimento.gd`, `estado_do_movimento.gd`, `parametros_do_movimento.gd`, `combate_para_movimento.gd`, `fonte_de_comandos.gd` | `estado_do_jogador_e_modulo_puro_test.gd` | Complete |
| **002** | Andar (`F1`), parada imediata sem inércia, ordem interna `R3`, `passo()` vs `passo_congelado()` | `movimento.gd` | `andar_e_ordem_do_passo_test.gd`, `ordem_e_bloqueio_test.gd` | Complete |
| **003** | Largada da esquiva (`R5`, `R6`, `F2`, `F4`), buffer de 10 passos, pedidos síncronos ao Combate (`cancelar`, `garantir_invulneravel(D+E)`, `esquiva_iniciada`) e `esquiva_sem_carga` | `esquiva.gd`, `movimento.gd`, `ev_esquiva.gd`, `ev_esquiva_sem_carga.gd` | `esquiva_e_contrato_com_o_combate_test.gd` | Complete |
| **004** | Cargas de esquiva (`R7`, `F3`), recarga sequencial sem zerar progresso no gasto, sincronia de `cargas_esquiva` no item 0 | `cargas_de_esquiva.gd`, `movimento.gd` | `cargas_e_recarga_test.gd` | Complete |
| **005** | Colisão própria discreta (`R10`, `F7`): passada ordenada de círculos, borda estrita `<`, normal `(0, -1)` em centro coincidente, clamp ao retângulo encolhido | `colisao.gd`, `geometria_de_movimento.gd`, `obstaculo_circular.gd` | `colisao_propria_test.gd` | Complete |
| **006** | `teleportar(pos)` (`R1`), `deslocar(v)` (`R9`), investida externa, cancelamento pela esquiva e reset de interpolação (`AC-32`, `AC-58`, `AC-27`, `AC-28`, `AC-44a`) | `movimento.gd`, `ev_teleporte_do_jogador.gd`, `reset_de_interpolacao_do_jogador.gd` | `teleporte_e_deslocamento_forcado_test.gd`, `reset_de_interpolacao_no_teleporte_test.gd` | Complete |
| **007** | Corte da esquiva (`R8`, `F5`, `F6`): consulta ordenada de atingíveis, alcance inclusivo por distância², teto opcional `alvos_max_corte`, dano via `Portador` sem `apos_esquiva` nem `enesimo_acerto`, `aplicar_corte` sem hitstop (`AC-18` a `AC-26`, `AC-41`, `AC-51`) | `movimento.gd`, `alvos_do_corte.gd`, `alvo_do_corte.gd` | `corte_da_esquiva_test.gd` | Complete |
| **008** | Consultas por valor e eventos `EvEsquiva`/`EvEsquivaSemCarga` para HUD, Pipeline e Áudio; sem invulnerabilidade guardada no Movimento; proteção real com `Combate` (`AC-55`, `AC-42`, `AC-43`, `AC-56`) | `movimento.gd`, `ev_esquiva.gd`, `ev_esquiva_sem_carga.gd` | `contrato_de_saida_test.gd`, `estados_do_input_e_invulnerabilidade_test.gd`, `tests/unit/combat/investida_e_movimento_test.gd` (`AC-56`/`AC-59`) | Complete |
| **009** | Evidência visual e de feel: teleporte sem rastro (`AC-44b`), esquiva legível em câmara 1920×1080 com imagens residuais (`AC-46`), áudio provisório 20/20 (`AC-47`) | `movimento.gd`, `reset_de_interpolacao_do_jogador.gd` | Evidências visuais retidas em `production/qa/evidence/combate-camara-04-esquiva-invuln-run.png` e `combate-camara-04-esquiva-invuln-bot-reativo-s3.png` | Complete |
| **010** | `MovementTuning` validado (`MV1–MV8`, faixas `R11`, limites exatos `AC-35..39`, `AC-53`, `AC-54`, precisão `AC-59`) e orçamento de CPU `p99 <= 0,2 ms` (`AC-48`) | `movement_tuning.gd`, `parametros_do_movimento.gd` | `movement_tuning_test.gd` | Complete |

---

## 2. Verificação de Regras e Validações (`MV1–MV8` e `R11`)

Em `src/gameplay/movimento/movement_tuning.gd` (`MovementTuning extends DefinicaoBase`) e `tests/unit/movement/movement_tuning_test.gd`:

- **Faixas `R11` (`AC-53`)**: `cargas_base` (`1–3`), `duracao_esquiva_s` (`0,05–0,5`), `velocidade_esquiva_pxs` (`300–3000`), `invuln_extra_s` (`0–0,25`, aceita `0`), `recarga_s` (`0,1–3,0`), `fator_recuperacao` (`0–1`), `raio_jogador_px` (`10–50`, `MV4`). Arredondamento `0,125 s -> 8 passos` via `Unidades.duracao_para_passos`.
- **`MV1` (`AC-35`, `AC-54`)**: erro se `d_passo >= r_obs_min + raio_jogador_px` (`50 >= 40` e limite exato `22,5 >= 22,5`); aviso se margem `(r_obs_min + raio_jogador_px) / d_passo < 2,0` (`1,725 < 2`; `2,0` exato passa sem aviso).
- **`MV2` (`AC-36`, `AC-54`)**: erro se `R <= D + E` (`12 <= 12`); aviso se `(D + E) / R > 0,5` (`12/21` e `12/13` geram aviso; `12/24 = 0,5` exato não gera aviso).
- **`MV3` (`AC-11`)**: `inv_esquiva = D + E` calculado como soma de inteiros quantizados separadamente (`9 + 3 = 12`, nunca `13`).
- **`MV4` e `MV5` (`AC-37`)**: `raio_jogador_px` fora de `[10, 50]` gera erro `MV4`; `alvos_max_corte` explícito `<= 0` gera erro `MV5`, enquanto vazio (`null`) ou `>= 1` são aceitos.
- **`MV6` (`AC-38`, `AC-54`)**: aviso se `d_passo > 2 * (raio_jogador_px + r_inimigo_min + alcance_extra_px)` (`40 = 40` sem aviso; `2401 px/s` gera aviso).
- **`MV7` (`AC-38`, `AC-54`)**: aviso se `dist_total` fora de `[2 * raio_jogador_px, 600]` (`54 px` e `600 px` exatos sem aviso; `15 px` e `675 px` geram aviso).
- **`MV8` (`AC-54`)**: aviso se `D > input_buffer_steps` (`D = 10` sem aviso; `D = 11` gera aviso).
- **`AC-59`**: precisão verificada para contadores `int64` e escalares `float` IEEE-754 binary64 (`2.0**52 + 1.0 != 2.0**52` e `2.0**53 + 1.0 == 2.0**53`).

---

## 3. Evidência Visual, Áudio e Desempenho (`Story 009` e `Story 010`)

- **AC-44b (Sem rastro no teleporte)**: `teleportar(pos)` iguala `anterior = atual = pos`, incrementa `contador_teleportes()` e emite `EvTeleporteDoJogador`; `ResetDeInterpolacaoDoJogador` chama `reset_physics_interpolation()` no mesmo quadro, eliminando qualquer quadro intermediário entre a posição antiga e a nova.
- **AC-46 (Esquiva em câmara 1920×1080, janela 1280×720)**: capturas retidas em `production/qa/evidence/combate-camara-04-esquiva-invuln-run.png` e `production/qa/evidence/combate-camara-04-esquiva-invuln-bot-reativo-s3.png` mostram o deslocamento de `202,5 px` de mundo (`135 px` de tela em 720p) com imagens residuais em osso tracejado durante os `12` passos de invulnerabilidade.
- **AC-47 (Áudio provisório nas 20 esquivas)**: 20/20 disparos de `EvEsquiva` acionam o som seco de esquiva no passo vivo de largada; toques com `0` cargas emitem apenas `EvEsquivaSemCarga` sem disparo nem VFX/som de esquiva.
- **AC-48 (Desempenho, orçamento `p99 <= 0,2 ms`)**: benchmark de 10.000 passos em `tests/unit/movement/movement_tuning_test.gd` com 9 inimigos na lista, Corte ativo sem teto, esquiva a cada 42 passos e 6 obstáculos circulares comprova `p99 <= 200 µs` (`0,2 ms`).

**Sign-off técnico (Gameplay Programmer #1 / Lead)**: Aprovado (`2026-11-18`).

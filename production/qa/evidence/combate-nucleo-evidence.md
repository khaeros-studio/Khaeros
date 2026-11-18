# Evidência de QA — Combate núcleo (`combate-nucleo`)

- **Épico**: `production/epics/combate-nucleo/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/combate-nucleo.md` (`R1–R25`, `F1–F13`, `CV1–CV22`, `V1–V15`, `AC-01` a `AC-119`)
- **ADRs Governantes**: `ADR-0010` (Resolução do combate no passo), `ADR-0001` (Orquestrador do passo), `ADR-0002` (Canal de eventos), `ADR-0003` (Entidades e portadores), `ADR-0004` (Catálogo de dados), `ADR-0006` (Input por passo), `ADR-0008` (Movimento e colisão própria), `ADR-0009` (Atributos e modificadores), `ADR-0011` (Pipeline visual), `ADR-0014` (Telégrafos), `ADR-0017` (Aliados e invocações), `ADR-0018` (IA de inimigos e chefe)
- **Engine**: Godot 4.7.2 (`RefCounted` puro em GDScript, sem `Area2D`, `ShapeCast2D`, `Timer`, `Engine.time_scale` ou `round()`/`roundi()`)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Resumo de Implementação e Testes por Story (`001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/combate/`) | Suíte de Testes (`tests/unit/combat/`) | Status |
|---|---|---|---|---|
| **001** | `CombatTuning` validado (`faixas R15` + `CV1–CV22`), `ParametrosDoCombate`, `AtaqueConvertido`, `DependenciasDoCombate` e esqueleto injetável sem valor padrão escondido (`AC-01` a `AC-04`, `AC-60` a `AC-65`) | `combate.gd`, `parametros_do_combate.gd`, `ataque_convertido.gd`, `dependencias_do_combate.gd`, `validador_combat_tuning.gd` | `combat_tuning_test.gd` | Complete |
| **002** | Ordem do passo vivo (`itens 3, 5, 7, 8, 9`), contador de hitstop (`vale o maior`, congela a partir do passo seguinte), `camara_nova()` e contrato de `pode_avaliar_camara_limpa()` (`AC-05` a `AC-11`, `AC-95`, `AC-96`) | `combate.gd` | `hitstop_test.gd` | Complete |
| **003** | Disparo do golpe (`Especial` antes do `Ataque`), combo independente por slot, avaliação congelada de `M` no disparo (`DanoCongelado`), fechamento de `apos_esquiva`, guarda e recuperação (`F2`) (`AC-12` a `AC-19`, `AC-21`, `AC-22`, `AC-112`) | `combate.gd`, `estado_de_golpe.gd`, `recursos_do_jogador.gd` | `disparo_do_golpe_test.gd` | Complete |
| **004** | `GeometriaDeAcerto` (`arco`, `circulo`, leque de `projetil`), passo de apoio (`deslocar` após o teste) e ciclo de projéteis do jogador e de inimigos em lista ordenada (`AC-20`, `AC-23` a `AC-32`, `AC-93`) | `combate.gd`, `projetil_registro.gd`, `formulas_de_combate.gd`, `src/gameplay/telegrafos/geometria_de_acerto.gd` | `geometria_de_acerto_test.gd`, `projeteis_test.gd` | Complete |
| **005** | Investida (`avanco`, `F6`, `1º alvo` pesado e seguintes leves) e contratos síncronos com o Movimento (`cancelar`, `garantir_invulneravel`, `aplicar_corte` sem hitstop, `esquiva_iniciada`) (`AC-33` a `AC-36`, `AC-58`, `AC-59`, `AC-84` a `AC-86`, `AC-94`) | `combate.gd`, `movimento_para_combate.gd` | `investida_e_movimento_test.gd` | Complete |
| **006** | `ferir_inimigo` (`R8`, `F1`, `F3`), `enesimo_acerto`, armadura de elite/chefe, cambaleio, `"Quebrou!"`, percurso do empurrão (`× 0,78`, zero em `< 4,5 px/s`, `F7`), impacto na parede (`F8`) e caminho silencioso `ferir_inimigo_de_status` (`AC-37` a `AC-47`, `AC-89`, `AC-90`) | `combate.gd`, `formulas_de_combate.gd`, `contratos_do_combate.gd` | `ferir_inimigo_e_empurrao_test.gd` | Complete |
| **007** | `ferir_jogador` (`R13`, `F10`, 1 único arredondamento via `FormulasDeModificadores.dano_recebido`), escudo, invulnerabilidade pós-dano (`40` passos), refletir antes da morte, recusa de morte (`hitstop 18`) e varredura em até `4` passes com retrato por passe (`AC-48` a `AC-57`, `AC-87`, `AC-88`) | `combate.gd`, `recursos_do_jogador.gd` | `ferir_jogador_e_varredura_test.gd` | Complete |
| **008** | Emissão de eventos tipados (`EventosDoCombate`: `EvGolpe`, `EvArea`, `EvDisparo`, `EvInvestida`, `EvAcerto`, `EvAcertoDeArma`, `EvParede`, `EvQuebrou`, `EvJogadorAtingido`, `EvRecusouMorte`, `EvJogadorMorreu`, `EvInimigoMorreu`, `EvExplosao`), durações visuais prontas, `peso_visual`, DPS de referência (`F11`), seleção de 1 impulso de câmera por passo (`V14`) e deduplicação de som no passo (`A1`) (`AC-66` a `AC-72`, `AC-80b`, `AC-91`, `AC-97`) | `eventos_do_combate.gd`, `formulas_de_combate.gd`, `combate.gd` | `eventos_e_contratos_test.gd` | Complete |
| **009** | Emenda Pactos: sem fogo amigo (`Faccao`), `aplicar_golpe_maldicao` no item `6.1` sem hitstop e com `autor_player_id` do dono, Pouso do Chamado com `M` do Especial e sem recuperação, `ferir_maldicao` (`F12`) com `exaurir` síncrono, `ferir_acuada` (`F13`) com `falhar_encontro` síncrono antes da varredura, projétil inimigo testando só o alvo travado (`R22`), lacaios `invocado_pelo_chefe` sem abate e chefe `subjugavel` (`subjugar` + `resolver_subjugado`: abate e `cura_ao_abater` só no `exorcizar`) (`AC-98` a `AC-119`) | `combate.gd`, `maldicoes_para_combate.gd`, `contratos_do_combate.gd`, `eventos_do_combate.gd` | `pactos_combate_test.gd` | Complete |
| **010** | Leitura visual, orçamento de desempenho (`<= 0,8 ms` em debug / `<= 0,3 ms` meta release, `AC-81`) e latência de 1 passo (`<= 50 ms` via `RenderingServer.frame_post_draw`, `EX-0010-1`, `AC-92`, `AC-82`) | `combate.gd`, `eventos_do_combate.gd` | `orcamento_e_latencia_test.gd`, `production/qa/evidence/experimentos/ex-0010-latencia.md` | Complete |

---

## 2. Evidência Visual, Desempenho e Latência (`Story 010`)

- **Capturas Visuais Retidas (`AC-73` a `AC-79`)**:
  - `production/qa/evidence/combate-camara-05-hitstop-finalizador-run.png` e `combate-camara-05-hitstop-finalizador-bot-reativo-s3.png`: hitstop do finalizador, flash em osso e leitura de impacto.
  - `production/qa/evidence/combate-camara-02-telegrafo-melee-bot-reativo-s3.png` e `combate-camara-03-telegrafo-faixa-bot-reativo-s3.png`: distinção entre telégrafo inimigo e golpe do jogador (`P3`).
  - `production/qa/evidence/integracao-jogavel/combate-real.png`: sessão integrada renderizada em 1280×720.
- **Desempenho (`AC-81`, `TR-combate-nucleo-017`)**:
  - Cenário de estresse: `1.000` passos vivos medidos (após `60` passos de aquecimento) com `9` inimigos (`6` Ecos, `2` Elites e `1` Chefe), `6` projéteis simultâneos em voo (`3` do jogador e `3` de inimigos) e golpes atingindo os `9` alvos com empurrão e colisão.
  - Medição (`Time.get_ticks_usec()` somando os itens `3, 5, 7, 8 e 9`): dentro do orçamento de `<= 0,8 ms` (`800 µs`) em execução de teste e abaixo do guardrail de `0,3 ms` (`300 µs`) por passo.
- **Latência do Golpe (`AC-92`, `TR-combate-nucleo-018` e `AC-82`)**:
  - No nível lógico (`tests/unit/combat/orcamento_e_latencia_test.gd`), `100%` dos toques elegíveis disparam o golpe no **mesmo passo físico** (`latência de 1 passo`, `0` golpes engolidos).
  - No nível de quadro de engine (`production/qa/evidence/experimentos/ex-0010-latencia.md`, `EX-0010-1`), `RenderingServer.frame_post_draw` dispara exatamente `1` vez por quadro (`936/936` quadros), com pior caso medido de **`33,33 ms <= 50,0 ms`** a 60 Hz com vsync ligado (`22,13 ms` a 144 fps sem vsync).

**Sign-off técnico (Gameplay Programmer #1 / Lead)**: Aprovado (`2026-11-18`).

# Evidência de QA — Run e regiões (`run-e-regioes`)

**Épico**: `production/epics/run-e-regioes/EPIC.md`
**GDD**: `design/gdd/run-e-regioes.md` (R1–R11, R1-P–R11-P, F1–F3, RN1–RN6, AC-RN-01..38)
**ADRs**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0009, ADR-0012, ADR-0013, ADR-0015
**Data**: 2026-11-18

---

## 1. Artefatos Implementados em `src/gameplay/run/`

| Arquivo | Classe (`class_name`) | Stories / Regras cobertas |
|---|---|---|
| `src/gameplay/run/validacao_run.gd` | `ValidacaoRun` | Story 002: validação RN1–RN6 sobre `RunTuning` e `RegionDef` (`arma_padrao` válida incluindo `pactos`, última jogável `combate` ou `chefe`, `camaras_jogaveis` em `1..7`). |
| `src/gameplay/run/resumo_da_run.gd` | `ResumoDaRun` | Story 008: resumo imutável de 12 campos (`motivo`, `seed_texto`, `arma`, `camaras_limpas`, `bencaos_tomadas`, `fragmentos_coletados`, `bonus_vitoria`, `total`, `abates`, `duracao_s`, `desfecho_chefe`, `dupla`), sem setters e com arrays `make_read_only()`. |
| `src/gameplay/run/eventos_da_run.gd` | `EventosDaRun` | Stories 004/006: `EvRunIniciada`, `EvFimDaRun`, `EvRunEncerrada`. |
| `src/gameplay/run/preferencias_de_arma_em_memoria.gd` | `PreferenciasDeArmaEmMemoria` | Story 004/009: implementação de `PreferenciasDeArma` (lembrança da última arma confirmada). |
| `src/gameplay/run/run.gd` | `Run` | Stories 001, 003, 004, 006, 007: máquina de estados da run (`SEM_RUN / PREPARANDO -> ESCOLHA_DE_ARMA / ESCOLHA_INICIAL -> ESCOLHA_DA_DUPLA -> ATIVA / EM_CAMARA -> ENCERRADA (VITORIA / DERROTA / ABANDONADA)`), sequência das 7 câmaras do Limiar, criação da seed após `dupla_confirmada`, condição de vitória no chefe (+15 Fragmentos de vitória: total 25 ao Pactuar ou 31 ao Exorcizar/Abater), prioridade da morte sobre a limpeza e bloqueio de abandono em `BENCAO` e `Subjugado`. |
| `src/gameplay/run/escopo_da_run.gd` | `EscopoDaRun` | Story 005: contêiner de escopo de run descartado em `nova_run()` (`desligar()`), garantindo que nada vaze entre runs sem usar `reset()`. |
| `src/gameplay/run/fabrica_da_run.gd` | `FabricaDaRun` | Story 005: fábrica que instancia `Portador`, `FonteDeFluxos`, `RegistroDeBencaos`, `Bencaos`, `Portas` e `Camaras` a cada nova run. |
| `src/gameplay/run/sessao_de_jogo.gd` | `SessaoDeJogo` | Stories 004, 005, 010: fachada dos 4 escopos (`Perfil > Sessão > Run > Câmara`), coordenação com `Save.gravar_se_pendente` (bloqueando escrita em `JOGO`) e `sair_do_jogo()` (consolidando run ativa como abandono conforme R10/V20b). |

---

## 2. Suíte de Testes Unitários (`tests/unit/run/`)

| Arquivo de Teste | Casos Verificados | Status |
|---|---|---|
| `tests/unit/run/run_estados_test.gd` | AC-RN-01 (transições válidas e recusas), AC-RN-17 (fim repetido ignorado), AC-RN-29 (pulos da dupla com 0, 1 e 2 pactuadas e retorno por Esc sem seed). | PASS |
| `tests/unit/run/run_validacao_test.gd` | AC-RN-24 e AC-RN-38 (RN1–RN6 com `arma_padrao = pactos`, `camaras_jogaveis = 8` -> RN3, última `santuario` -> RN2, última `chefe` -> válido). | PASS |
| `tests/unit/run/run_sequencia_test.gd` | AC-RN-06, AC-RN-07, AC-RN-21 (`p_max` lido das Câmaras), AC-RN-22 (múltiplas regiões), AC-RN-30 (índice 5 -> `chefe`, índice 6 -> `fim_da_run`, montar 7 -> RN3). | PASS |
| `tests/unit/run/run_inicio_test.gd` | AC-RN-02/27 (ordem de início com Lâmina e com Pactos), AC-RN-03 (última arma lembrada e `arma_padrao`), AC-RN-04 (`0x3F9A07C2`, `--seed=1B2C3D4E` e fallback para `--seed=XYZ`), AC-RN-05/28 (3 cartas e Vidas 100, 80, 90). | PASS |
| `tests/unit/run/run_nova_run_test.gd` | AC-RN-19 (reset por recriação de `EscopoDaRun` mantendo saldo), AC-RN-20 (seed nova), AC-RN-26 (sem SceneTree e `WeakRef` antigo liberado), AC-RN-36 (pacto com *Soberano* preservado no perfil). | PASS |
| `tests/unit/run/run_vitoria_test.gd` | AC-RN-08 (santuário não encerra), AC-RN-10/31 (índice 5 comum dá +3 Fragmentos e abre porta `chefe`), AC-RN-32 (vitória por abate: coletados 11 + bônus 15 = 26, `abatido`, 7 câmaras limpas), AC-RN-33 (Pactuar = 25, Exorcizar = 31). | PASS |
| `tests/unit/run/run_morte_abandono_test.gd` | AC-RN-11/12/13/16/35 (morte vence limpeza no chefe, recusa de morte mantém ativa), AC-RN-14/15/34 (abandono bloqueado em Bênção e em `Subjugado`). | PASS |
| `tests/unit/run/run_resumo_test.gd` | AC-RN-18, AC-RN-23 (exemplos F2: 22, 7, 4; 3600 passos = 60 s), AC-RN-37 (12 campos imutáveis e arrays read-only). | PASS |
| `tests/unit/run/run_perfil_e_saida_test.gd` | Story 010 / ADR-0015 §7: gravação recusada em `JOGO` (`ERR_BUSY`), gravada em ponto seguro, e `sair_do_jogo()` com run ativa consolida pontos como abandono e grava sincronamente. | PASS |

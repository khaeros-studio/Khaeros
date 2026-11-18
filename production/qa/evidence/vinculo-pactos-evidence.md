# Evidência de QA — Vínculo e pactos (`vinculo-e-pactos`)

**Épico**: `production/epics/vinculo-e-pactos/EPIC.md`
**GDD**: `design/gdd/vinculo-e-pactos.md` (V1–V47, F1–F5, VP1–VP9, AC-VP-01..26)
**ADRs**: ADR-0001, ADR-0002, ADR-0004, ADR-0005, ADR-0009, ADR-0010, ADR-0012, ADR-0013, ADR-0015, ADR-0017, ADR-0018
**Data**: 2026-11-18

---

## 1. Artefatos Implementados em `src/gameplay/vinculo/`

| Arquivo | Classe (`class_name`) | Stories / Regras cobertas |
|---|---|---|
| `src/gameplay/vinculo/validador_vinculo.gd` | `ValidadorVinculo` | Story 001: validação VP1–VP9 (1ª e 2ª passadas) e cálculo de memórias reveladas `F5` por raridade e nível. |
| `src/gameplay/vinculo/perfil_vinculo.gd` | `PerfilVinculo` | Story 002: implementa `PortaDeSecao` para a seção `[vinculo]` do `RepositorioDePerfil` (`escrever()`, `ler()`, `campos_de_ids() -> ["ultima_dupla", "encontro_pendente"]`), validação `V33` com aviso `VP-S1` uma vez por chave e recálculo de `nivel` por `F3`. |
| `src/gameplay/vinculo/porta_do_vinculo_na_run.gd` | `PortaDoVinculoNaRun` | Story 002/003: contrato do ADR-0015 §5 entre Run/Portas/Câmaras e o Vínculo. |
| `src/gameplay/vinculo/vinculo_nulo.gd` | `VinculoNulo` | Story 002: dublê nulo com `return` explícito (Godot 4.7). |
| `src/gameplay/vinculo/sorteio_do_encontro.gd` | `SorteioDoEncontro` | Story 004: sorteio determinístico `F1` no fluxo `pactos` (`9`), consumindo sempre 4 reais (`u0..u3`), com garantias `G1` (1º encontro no índice 1 com `espreitador_da_fenda`), `G2` (`encontro_pendente`) e `G3` (`pity_runs = 2`). |
| `src/gameplay/vinculo/acuada.gd` | `MaldicaoAcuada` | Story 005: posicionamento nos 5 `pontos_acuada` fora das pedras sem RNG (`V7`), Vida `F2` (`round(vida_max * 1,2)` → 114 no Espreitador), sem fogo amigo, alvo padrão por paridade de `ordem` (`V8`), prioridade de atração da Maldição e fuga em 12 passos ao zerar a Vida (`V12`). |
| `src/gameplay/vinculo/encontro_de_pacto.gd` | `EncontroDePacto` | Story 004/005: máquina de estados do encontro na run (`SEM_ENCONTRO -> PLANEJADO -> ACUADA -> AGUARDANDO / FUGIU -> RESOLVIDO / ABANDONADO / NAO_ALCANCADO`). |
| `src/gameplay/vinculo/consentimento.gd` | `ConsentimentoPacto` | Story 006: opções da tela de consentimento (`oferecer`/`deixar_ir`, `reafirmar`/`deixar_ir`, ou `ela_voltara` quando espécie Rara/Épica exige `>= 2` encontros bem-sucedidos — `V13`). |
| `src/gameplay/vinculo/pontos_de_vinculo.gd` | `PontosDeVinculo` | Story 007: `F3` (acumulador da run com tetos de abates e técnicas, limiares `[20, 50, 90, 140]`, níveis `1..5`) e `F4` (bônus de nível no início da run: `+5%` Vida no nv 2, Exaustão `× 0,90` no nv 3, `+5%` dano básico no nv 4, fonte `vinculo:<id>`). |
| `src/gameplay/vinculo/escolha_do_chefe.gd` | `EscolhaDoChefe` | Story 008: decisão `Pactuar` vs `Exorcizar` no chefe Subjugado (`V18`), incluindo "o fardo repartido" (`V18.5`) quando o *Soberano do Limiar* já está no nível 5 (+10 pontos para cada espécie da dupla ou para a de menor nível fora da dupla). |
| `src/gameplay/vinculo/eventos_vinculo.gd` | `EventosVinculo` | Story 009: `EvPactoRegistrado`, `EvPactoFormado`, `EvDuplaConfirmada`, `EvEncontroFalhou`, `EvEncontroPacto`, `EvPactoResolvido`, `EvChefeEscolhido`, `EvVinculoGanho`, `EvVinculoAtualizado`. |
| `src/gameplay/vinculo/vinculo.gd` | `Vinculo` | Stories 003–010: fachada completa do módulo de Vínculo e pactos. |

---

## 2. Suíte de Testes Unitários (`tests/unit/vinculo/`)

| Arquivo de Teste | Casos Verificados | Status |
|---|---|---|
| `tests/unit/vinculo/vinculo_tuning_e_validacao_vp_test.gd` | AC-VP-21 (VP5, VP6, VP7 no catálogo MVP e gatilhos com `0,06` e `0,08`), VP1–VP4, VP8, VP9 e F5 (memórias). | PASS |
| `tests/unit/vinculo/perfil_vinculo_e_secao_test.gd` | AC-VP-02 (run de Lâmina não altera `escrever()`), AC-VP-24 (recálculo de nível 7 -> 3, desduplicação de `ultima_dupla`, avisos `VP-S1`), AC-VP-25 (`campos_de_ids()`). | PASS |
| `tests/unit/vinculo/primeiro_pacto_e_dupla_test.gd` | AC-VP-01 (concessão automática do *Vulto Mudo* na 1ª escolha da Besta sem abrir tela de dupla), V16/V16b (escolha com `>= 2` pactuadas). | PASS |
| `tests/unit/vinculo/sorteio_do_encontro_test.gd` | AC-VP-03 (G1 no índice 1 com *Espreitador* e 4 reais), AC-VP-04 (consumo fixo de 4 reais com e sem pendente), AC-VP-05 (exemplo numérico F1 e reafirmação), AC-VP-06 (G3 `pity_runs = 2`). | PASS |
| `tests/unit/vinculo/acuada_alvo_e_fuga_test.gd` | AC-VP-07 (nascimento em `(960, 540)` com Vida 114), AC-VP-08 (sem fogo amigo), AC-VP-09 (paridade da `ordem`), AC-VP-10 (atração por 180 passos), AC-VP-11 (fuga em 12 passos e `encontro_pendente`). | PASS |
| `tests/unit/vinculo/consentimento_portas_e_dupla_test.gd` | AC-VP-12 (Portas 2b esperam consentimento), AC-VP-13 ("Oferecer o vínculo"), AC-VP-14 (*Baluarte de Cinza* exige 2 encontros: `"ela_voltara"` no 1º, `"oferecer"` no 2º), AC-VP-15 (entrada na reserva com Vida `80/95`). | PASS |
| `tests/unit/vinculo/pontos_niveis_e_consolidacao_test.gd` | AC-VP-16 (`12 + 12 + 6 + 8 = 38`), AC-VP-17 (`19 + 31 = 50 -> nível 3`), AC-VP-18 (morte conserva pontos), AC-VP-19 (saída em `Aguardando` consolida pontos e marca pendente), AC-VP-20 (*Baluarte* nv 5: Vida 142, Exaustão 540, básico `13,23`). | PASS |
| `tests/unit/vinculo/chefe_pactuar_ou_exorcizar_test.gd` | AC-VP-22 (Pactuar *Soberano* inédito), AC-VP-23 (V18.5 fardo repartido no nível 5 transfere +10 para *Vulto* e +10 para *Baluarte*). | PASS |
| `tests/unit/vinculo/eventos_para_telemetria_test.gd` | AC-TL-34, AC-TL-36, AC-TL-37, AC-TL-38, AC-TL-39 (emissão ordenada de `pacto`, `encontro_pacto` e `vinculo_fim_run`). | PASS |

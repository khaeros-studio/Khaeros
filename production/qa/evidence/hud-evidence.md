# Evidência de QA — Épico `hud`

> **Épico**: HUD, Menu de Pausa, Tela de Opções e Fim de Run (`hud`)
> **ADR**: ADR-0012 (UI e HUD — Modelos Reativos, Vistas `Control` e Foco Único)
> **GDD / UX**: `design/gdd/hud.md`, `design/ux/hud.md`, `design/ux/pausa-e-opcoes.md`, `design/ux/tela-fim-de-run.md`
> **Data**: 2026-11-18
> **Status**: PASS (10/10 stories completas)

---

## 1. Resumo de Cobertura por Story

| Story | Título | Arquivos Implementados | Testes Unitários | Status |
|---|---|---|---|---|
| `story-001` | `ModeloDoHud`, `LeituraDoHud` e `RelogioDeInterface` | `src/presentation/hud/leitura_do_hud.gd`, `src/presentation/hud/relogio_de_interface.gd`, `src/presentation/hud/formato_numerico.gd`, `src/presentation/hud/modelo_do_hud.gd` | `tests/unit/hud/modelo_e_vida_hud_test.gd` | Complete |
| `story-002` | Barra de Vida Segmentada, Racha de Dano e Vida Baixa | `src/presentation/hud/modelo_da_vida.gd` | `tests/unit/hud/modelo_e_vida_hud_test.gd` | Complete |
| `story-003` | Gota de Fluxo (40%), Chevrons de Esquiva, Fragmentos e Glifos | `src/presentation/hud/modelo_recursos_e_mundo.gd` | `tests/unit/hud/fluxo_esquiva_fragmentos_fios_chefe_test.gd` | Complete |
| `story-004` | Pool de 9 Fios de Inimigos, Prompt de Porta (`≤ 111 px`) e Barra de Chefe (50%) | `src/presentation/hud/modelo_recursos_e_mundo.gd` | `tests/unit/hud/fluxo_esquiva_fragmentos_fios_chefe_test.gd` | Complete |
| `story-005` | Bloco do Pacto (`72×72` Ativa em Osso, `56×56` Reserva, Anel de Exaustão e Chamado) | `src/presentation/hud/modelo_do_bloco_do_pacto.gd` | `tests/unit/hud/bloco_do_pacto_e_vista_test.gd` | Complete |
| `story-006` | `VistaDoHud` (`Control` Ancorada, Margem Segura `48 px` Fixa e Escala `80%..150%`) | `src/presentation/hud/vista_do_hud.gd` | `tests/unit/hud/bloco_do_pacto_e_vista_test.gd` | Complete |
| `story-007` | 12 Opções de Acessibilidade do HUD e Persistência | `src/presentation/hud/opcoes_do_hud.gd` | `tests/unit/hud/bloco_do_pacto_e_vista_test.gd` | Complete |
| `story-008` | `MenuDePausa` (Continuar, Opções, Copiar Seed e Abandonar Run com Confirmação) | `src/presentation/hud/menu_de_pausa.gd` | `tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd` | Complete |
| `story-009` | `TelaDeOpcoes` (Áudio, Vídeo, Acessibilidade, Remapeamento com Troca e Reset de Perfil) | `src/presentation/hud/tela_de_opcoes.gd` | `tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd` | Complete |
| `story-010` | `TelaFimDeRun` (Vitória/Derrota/Abandono, 12 Estatísticas, Painel de Vínculo e Trava `500 ms`) | `src/presentation/hud/tela_fim_de_run.gd` | `tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd` | Complete |

---

## 2. Verificação dos Critérios de Aceitação (`AC-HU-01` a `AC-HU-40`)

1. **Barra de Vida, Racha e Vida Baixa (`F1`, `F2`, `F3`)**:
   - Segmentos de `10` unidades (`ceil(vida_max / 10)`), largura base `260 px` escalando `+2 px` por ponto acima de 100 até o teto de `480 px` a 100%.
   - Racha de dano recente congela enquanto `hitstop_ativo() == true` ou enquanto aguarda `preco_revelado` na Tela de Bênção.
   - Histerese inteira de vida baixa (`25%` entra, `30%` sai), borda limitada a `8%` da altura e opacidade máxima `40%`.
2. **Bloco do Pacto (`R15–R19`)**:
   - Exibido exclusivamente quando `doutrina == &"pactos"` com pelo menos 1 Maldição equipada.
   - Silhueta ativa `72×72` em osso (`#F2EDE4`) **sem magenta**, barra de vida `132 px` segmentada de 10 em 10, silhueta da reserva `56×56` com anel de regeneração (`1 - restante/total`), recarga de troca e estado do Chamado (`Pronto`, `Em recarga`, `Bloqueado`).
3. **Zero Strings Literais Visíveis**:
   - Todos os rótulos visíveis em `src/presentation/hud/` utilizam chaves de tradução (`HUD_*`, `PAUSA_*`, `OPCOES_*`, `RUN_*`, `PERFIL_*`, `INPUT_*`) e `FormatoNumerico` com espaço fixo (`1 234`).

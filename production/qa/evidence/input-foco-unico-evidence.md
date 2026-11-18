# Evidência — Input: foco único, telas sem mouse e campo de texto (`story-009-foco-unico-e-telas-sem-mouse`)

- **Data**: 2026-11-18
- **Story**: `production/epics/input/story-009-foco-unico-e-telas-sem-mouse.md`
- **GDD**: `design/gdd/input-e-controle.md` (R9, R10; AC-33, AC-34, AC-36)
- **ADRs**: `docs/architecture/adr-0006-input-por-passo.md` (§5), `docs/architecture/adr-0012-ui-e-hud.md` (§3)
- **Engine**: Godot 4.7.2

## Artefatos implementados e verificados

1. **Controlador e auxiliar de foco único (`src/foundation/input/roteador_de_foco.gd`, `class_name RoteadorDeFoco`)**:
   - Garante **um único modelo de foco autoritativo** para teclado, gamepad e mouse, com foco inicial obrigatório em toda tela (`configurar_tela`).
   - Espelha o foco nos nós `Control` opcionais chamando `grab_focus()` e configurando `mouse_filter = Control.MOUSE_FILTER_IGNORE` para neutralizar o foco duplo do Godot 4.6 e evitar dupla confirmação pela via nativa.
   - Em hover (`aplicar_hover`), move o foco e chama `grab_focus()` **apenas quando o mouse se moveu** (`mouse_moveu == true`) e **fora do contexto `texto`**. O `ui_navegar` seguinte parte do controle focado pelo hover.
   - Na Tela de bênção: atalhos `1`/`2`/`3` (`ui_carta_1..3`) apenas movem o foco sem confirmar; `Enter`, `Espaço`, `E` e `A` (gamepad) confirmam no máximo uma vez por passo, respeitando as travas de abertura (500 ms) e de troca (300 ms); `R` (`ui_trocar_ofertas`) solicita troca e rearma a trava.
   - No campo de texto de debug (`contexto = texto`, AC-36):
     - Entra em edição por bind de teclado de `ui_aceitar` ou por clique no campo; **recusa `A` do gamepad**.
     - Durante a edição, `WASD`, `1–3`, `R`, `E` e `Espaço` viram texto e o foco não se move.
     - Mesmo com `ui_aceitar`/`ui_voltar` remapeados para `F1`/`F2`, em edição **apenas `KEY_ENTER`/`KEY_KP_ENTER` e `KEY_ESCAPE` físicos** confirmam ou cancelam.
     - `Esc` cancela a edição sem alterar o valor confirmado e sem abrir a Pausa.
     - Valor recusado pelo parse (`XYZ` + `Enter`) mantém o contexto `texto`, preserva o texto digitado e expõe a mensagem do RNG (`TextoDaSeed.interpretar`).
     - Hover sobre controle vizinho mantém a edição; clique num controle vizinho cancela a edição sem acionar o vizinho.

2. **Suíte de testes unitários (`tests/unit/input/foco_unico_test.gd`)**:
   - `test_foco_inicial_e_navegacao_alcanca_todos_os_controles_E_hover_move_foco_unico`: percorre as 8 telas do inventário R9 (`menu_principal`, `pausa`, `bênção`, `morte`, `vitória`, `opções`, `erros_catalogo`, `debug`), verificando foco inicial, `grab_focus()`, `MOUSE_FILTER_IGNORE`, alcance total por `ui_navegar` e continuidade de `ui_navegar` a partir do controle focado por hover.
   - `test_tela_de_bencao_atalhos_1_2_3_so_focam_aceitar_confirma_r_troca_e_travas`: verifica `1/2/3`, confirmação por `Enter`/`Espaço`/`E`/`A`, troca por `R` e travas de 500/300 ms.
   - `test_campo_de_texto_debug_fluxo_completo_ac36`: verifica todos os subitens do AC-36 ponta a ponta com `RoteadorDeContexto` e `TextoDaSeed.interpretar`.

3. **Evidências visuais retidas**:
   - `production/qa/evidence/experimentos/ex-0012-e2-selecao.png` e `ex-0012-e2-final.png` (edição de `LineEdit` e bloqueio de navegação nativa em contexto Texto).
   - `production/qa/evidence/integracao-jogavel/menu.png`, `pausa.png`, `bencao.png`, `morte.png`, `resultado-real.png` (telas operadas sem mouse com foco visível).

## Cobertura dos Critérios de Aceite

| AC | Descrição | Status | Evidência |
|---|---|---|---|
| **AC-33** | Foco inicial, `ui_navegar` alcança todos os controles, hover move foco único (`grab_focus()`), Bênção 1/2/3/aceitar/R/travas | PASS | `tests/unit/input/foco_unico_test.gd` |
| **AC-34** | Telas operadas sem mouse com foco visível | PASS | `ex-0012-e2-*.png`, `integracao-jogavel/*.png` |
| **AC-36** | Campo de seed do debug em contexto Texto (teclado entra, gamepad A não entra, Enter/Esc fixos, erro mantém edição, clique fora cancela sem acionar) | PASS | `tests/unit/input/foco_unico_test.gd` |

## Sign-off

- **Engine Programmer**: Aprovado e verificado (2026-11-18).

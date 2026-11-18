# Story 005: Contextos, barreira de troca, perda de foco e desconexão

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-008`, `TR-input-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0001 para o estado de jogo e ADR-0012 para a UI)
**ADR Decision Summary**: A troca de contexto incrementa a época, invalida a capacidade, esvazia buffer, bordas e escolha, e bloqueia as entradas físicas seguradas até a soltura; perda de foco em Jogo pede Pausa; Input solicita mudanças, não altera o estado do jogo sozinho.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Notificações de foco da janela e conexão de gamepad chegam ao adaptador; a reconciliação com o estado físico real ao recuperar o foco exige teste com hardware. Desconexão durante Transição está pendente de alinhamento de design: não inferir pausa automática.

**Control Manifest Rules (this layer)**:
- Required: perda de foco e desconexão do gamepad ativo viram `pedir_estado(PAUSA)` em JOGO (ADR-0001); roteador de contexto com retorno explícito (ADR-0006)
- Forbidden: `SceneTree.paused`; módulos trocando o estado diretamente (ADR-0001)
- Guardrail: sem acumular comandos durante Transição ou passe de morte

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-22** Ataque segurado, Jogo → Bênção → buffer vazio e nenhuma carta aceita enquanto segura; soltar e apertar `ui_aceitar` → aceita (trava de 500/300 ms zerada no teste); Bênção → Jogo com o botão segurado → ataque falso até soltar; toque no mesmo passo da troca ignorado; Jogo → Transição com Ataque no buffer → buffer vazio; Ataque, Especial, esquiva e `pausar` durante a Transição → nenhuma ação
- [ ] **AC-23** Perda de foco em Jogo → Pausa, segurados falsos, buffer vazio; em Menu ou Bênção → não pausa; na Transição → a Pausa abre no primeiro passo de Jogo depois do wipe; **[M]** Alt+Tab real, uma vez por release
- [ ] **AC-24** Com monitor de dispositivos injetado: gamepad ativo desconecta → Pausa + `INPUT_CONTROLE_DESCONECTADO`, reconectar continua em Pausa; teclado ativo → não pausa; gamepad não ativo desconecta → nada; durante Bênção ou Menu → só a mensagem; **[M]** cabo ou Bluetooth de verdade
- [ ] **AC-35** Jogo: Esc → Pausa, Esc de novo → Jogo (idem Start); Bênção: Esc → Pausa por cima, fechar a Pausa volta à Bênção com as mesmas 3 cartas, B não muda nada; Opções abertas da Pausa: Esc ou B → volta à Pausa, Start não muda nada
- [ ] **AC-40** Com `jogador_morreu` e o passe de morte em andamento, Esc e `ui_aceitar` não fazem nada (nenhum `ui_*` é entregue); quando a tela final abre, vale o contexto Menu

---

## Implementation Notes

*Derived from ADR-0006 §3 (tabela de contextos) e ADR-0001:*

Contextos: Jogo, Pausa, Bênção, Menu, Texto, Transição/passe de morte, Sem foco, Remapeando — cada um com sua saída permitida (tabela do ADR). Estado global e contexto de input são diferentes: opções e Texto podem estar sobre uma Pausa; fechar a Pausa sobre Bênção restaura a mesma oferta. O orquestrador processa pedidos de pausa/foco e troca de contexto antes de despachar regras vivas; havendo troca, não distribui a amostra antiga nem amostra uma segunda vez no passo. Durante o wipe memoriza o pedido de pausa e entra em Pausa no primeiro passo que voltaria a Jogo. Recuperar foco ou reconectar não fecha a pausa. Após recuperar foco, eco de teclado não rearma comandos.

**Código atual da fatia:** os contextos de `game_input.gd` e a leitura de foco de `src/app/main.gd` são **reaproveitar parcialmente** como base; reescrever a barreira (época, bloqueio por entrada física) e o roteador.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: foco único e telas operadas sem mouse
- Épico orquestrador-do-passo: o estado de jogo e `pedir_estado`
- Épico tela-de-bencao-e-carta: as travas de 500/300 ms

---

## Files

- `src/foundation/input/roteador_de_contexto.gd`
- `src/foundation/input/barreira_de_troca.gd`
- `src/foundation/input/monitor_de_dispositivos.gd`
- `tests/unit/input/contextos_e_barreira_test.gd`
- `tests/integration/input/foco_e_desconexao_test.gd`
- `production/qa/evidence/input-altab-desconexao-manual.md` (registro dos testes [M])

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/input/foco_e_desconexao_test.gd` — must exist and pass; mais o registro manual de Alt+Tab e desconexão

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md`, `production/epics/input/story-004-buffer-de-comandos-e-troca.md`; `production/epics/orquestrador-do-passo/` (stories ainda por criar: estados de jogo e pedido de estado)
- Unlocks: `production/epics/input/story-009-foco-unico-e-telas-sem-mouse.md`

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos: `src/foundation/input/roteador_de_contexto.gd` (novo), `src/foundation/input/monitor_de_dispositivos.gd` (novo), `src/foundation/input/barreira_de_troca.gd` (sessão anterior), `tests/unit/input/contextos_e_barreira_test.gd` (10 casos), `tests/integration/input/foco_e_desconexao_test.gd` (7 casos), `production/qa/evidence/input-altab-desconexao-manual.md` (registro [M], pendente). Suítes de input inteiras: 120 casos, 0 falhas.

Decisões:
- `RoteadorDeContexto`: pilha base + sobreposições com retorno explícito (`definir_base`, `abrir`, `fechar`), "Sem foco" como sobreposição separada, `processar_amostra` trata `pausar` (Jogo/Bênção → Pausa; Pausa → volta) e `ui_voltar` em Menu sobreposto. Estado do jogo só por `pedir_estado(pedido) -> bool` injetado (`PEDIDO_PAUSA`/`PEDIDO_RETOMAR`); a pilha só muda se aceito. Cada mudança do contexto efetivo chama `ao_trocar` (= `ProvedorDeEntrada.trocar_contexto`), que aplica a barreira na hora.
- Perda de foco em Jogo pede Pausa; na Transição memoriza e a Pausa entra em `definir_base(JOGO)`; recuperar foco não fecha a Pausa.
- `MonitorDeDispositivos`: só o gamepad ativo (dispositivo ativo = gamepad e id igual) gera o aviso; Pausa só em Jogo. Desconexão na Transição: só o aviso (pendência de design do ADR-0006). O aviso segue "uma vez por sessão" (R8).
- Nota de comportamento da barreira (story 004): uma troca feita depois da amostra do passo N descarta as bordas da amostra N+1; os testes usam um passo vazio após a troca.

Pendências:
- Ligar em `src/app/main.gd` (fora do escopo): foco da janela → `perder_foco`/`recuperar_foco` (+ `AdaptadorDeEntradaGodot.soltar_tudo`), `Input.joy_connection_changed` → `ao_mudar_conexao`, e o orquestrador consultar `roteador.contexto()` antes de amostrar e não distribuir a amostra quando `processar_amostra` devolver `true`. Os nomes reais dos pedidos de estado dependem do épico orquestrador-do-passo.
- Testes [M] de Alt+Tab e desconexão real: pendentes (registro criado).

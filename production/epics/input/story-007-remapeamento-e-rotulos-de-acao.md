# Story 007: Remapeamento transacional e `rotulo_acao`

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-006` (regras de remapeamento; a persistência é da story 008)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo
**ADR Decision Summary**: Remapeamento é transação sobre cópia do mapa: resolve a troca de binds conflitantes, valida todos os contextos afetados, garante primários e só então substitui o mapa ativo; `pausar` nunca entra em troca e Esc/Start são fixos; `rotulo_acao(acao, dispositivo)` devolve `{texto, glifo}` do bind atual e do layout ativo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Rótulo AZERTY exige a tecla lógica do layout ativo; verificação manual em hardware. Tempos de captura recebem delta real da fronteira, independente de `t_vivo`/`t_apres`, porque a tela pode estar pausada.

**Control Manifest Rules (this layer)**:
- Required: remapeamento é transação sobre cópia, validada por inteiro antes de publicar (ADR-0006)
- Forbidden: serializar objetos `InputEvent`; mapa parcial publicado (ADR-0006)
- Guardrail: máximo de três binds por dispositivo; alterar o mapa aplica a barreira de contexto

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-25** Atribuir o secundário de `ataque` ao `especial` → os dois trocam e sai `INPUT_CONFLITO_TROCA`; troca que deixaria ação sem primário → recusada; mesma entrada em contextos diferentes → não troca
- [ ] **AC-26** Remover Esc de `pausar`, ou atribuir Esc/Start a outra ação de Jogo, Pausa ou Bênção → recusado (`INPUT_RECUSA_PAUSA`); acrescentar F10 em `pausar` → aceito
- [ ] **AC-27** "Remover" só tira um secundário; o primário de uma ação de jogo nunca fica vazio; um 4º bind à Esquiva no teclado → recusado, os 3 ficam
- [ ] **AC-28** Evento com posição física W e tecla lógica Z → `mover` para cima; **[UI]+[M]** rótulo AZERTY na tela de remapeamento
- [ ] **AC-29 (recusas)** Windows/Meta, Print Screen e roda do mouse → recusados
- [ ] **AC-30** Remapeando `selo` no gamepad: B curto → atribuído; Start segurado por 1 s → cancela; 5 s sem entrada → cancela; nos cancelamentos os binds ficam inalterados
- [ ] **AC-39** `rotulo_acao`: padrão, remapeado, AZERTY, troca de dispositivo ativo no passo N refletida em N+1, e ação ou dispositivo inexistente → rótulo vazio e um aviso, sem falha (valores do GDD, 2026-11-13)
- [ ] **AC-47** `rotulo_acao("troca", teclado)` = "R" e `("troca", gamepad)` = glifo de LT; com a Troca remapeada para G, a consulta seguinte devolve "G"

---

## Implementation Notes

*Derived from ADR-0006 §6:*

Cada ação usa lista ordenada de até três descritores simples (`tecla_fisica`, `mouse`, `botao_gamepad`, `gatilho`). Vetores de gamepad não são remapeados. Conflito ambíguo com vários donos que uma troca válida não resolve é recusado sem mudança parcial. Captura dura até 5 s; candidatos Esc/Start só são confirmados na soltura curta e ficam sujeitos às recusas de reserva. "Restaurar padrão" atua só no dispositivo escolhido; `trocar_analogicos` é opção do mapa. A tela de remapeamento (UI) pertence ao épico hud; aqui entram o modelo e suas regras.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: arquivo `input_binds.cfg`, `.bak` e migração
- Épico hud: a tela de remapeamento

---

## Files

- `src/foundation/input/mapa_de_binds.gd`
- `src/foundation/input/transacao_de_remapeamento.gd`
- `src/foundation/input/rotulos_de_acao.gd`
- `tests/unit/input/remapeamento_test.gd`
- `tests/unit/input/rotulo_acao_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/remapeamento_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/input/story-001-acoes-mapa-padrao-e-adaptador-de-eventos.md`
- Unlocks: `production/epics/input/story-008-persistencia-de-binds-e-migracao.md`

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos: `mapa_de_binds.gd` e `rotulos_de_acao.gd` (sessão anterior), `src/foundation/input/transacao_de_remapeamento.gd` (novo), `tests/unit/input/remapeamento_test.gd` (17 casos, passam), `tests/unit/input/rotulo_acao_test.gd` (5 casos, passam).

Decisões:
- `TransacaoDeRemapeamento` com funções estáticas `atribuir`, `acrescentar`, `remover` e `validar` sobre cópia; devolvem `Resultado {aceito, mapa, aviso}`. Recusa devolve o mapa original intacto. Validação final do mapa inteiro: primário em toda chave do padrão, ≤ 3, família/entradas proibidas, Esc/Start só em `pausar` dentro de Jogo/Pausa/Bênção e `BindsPadrao.varrer_conflitos` vazio.
- Avisos: troca → `INPUT_CONFLITO_TROCA`; Esc/Start e qualquer troca que envolva `pausar` → `INPUT_RECUSA_PAUSA`; demais recusas (4º bind, sem primário, conflito com vários donos, Meta/PrintScreen/roda, vetor de gamepad) → `INPUT_RECUSA_TECLA` (o GDD não nomeia a mensagem de "troca sem primário"; decisão registrada aqui).
- `TransacaoDeRemapeamento.Captura`: restrita à família, captura no aperto; Esc/Start viram candidatos, capturados só na soltura curta; segurar `CANCELAR_S` (1 s) ou `PRAZO_S` (5 s) sem entrada cancela. Tempo por `avancar(delta_real)`. As durações são constantes de regra (R8), sobrescrevíveis no construtor.
- AC-28 coberto pelo adaptador (`physical_keycode`), com teste W físico/Z lógico → `mover` para cima.

Pendências: rótulo AZERTY na tela [UI]+[M] (épico hud) e verificação de `DisplayServer.keyboard_get_label_from_physical` (fora da engine-reference).

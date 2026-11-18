# Story 001: Ações, mapa padrão de binds e adaptador de eventos

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo
**ADR Decision Summary**: `AdaptadorDeEntradaGodot`, nó fino na fronteira da engine, converte eventos em descritores de valores e mantém estado por entrada física e bordas novas; o mapa de binds próprio é a autoridade e o `InputMap` não guarda buffer nem decide contexto.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Eventos identificados por classe, sem assumir `device == 0` para teclado e mouse (4.7); `Input.use_accumulated_input` desativado no ponto de composição, com custo medido em mouse de alta frequência. A entrega da localização esquerda/direita de modificadores pelo Windows requer verificação.

**Control Manifest Rules (this layer)**:
- Required: `Input`/`InputEvent` só na fronteira de input; mapa de binds próprio é a autoridade (ADR-0006)
- Forbidden: avançar gameplay por callbacks de teclado, sinais da UI ou eventos de gamepad; `_unhandled_input` por nó para ações (ADR-0006)
- Guardrail: sem fila ilimitada de eventos; cada evento reduz-se a estado limitado

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-01** Mapa padrão e build de release injetado → o conjunto de ações é exatamente o da R1 (com `troca`), sem nenhuma `debug_*`; nenhuma ação passa de 3 binds por dispositivo; a Esquiva tem Espaço, Shift e L e `ui_aceitar` tem Enter, Espaço e E
- [ ] **AC-41** `troca`: teclado R (primário) e Tab, gamepad LT; uma varredura do contexto Jogo não acha R, Tab ou LT em outra ação; R continua em `ui_trocar_ofertas` na Bênção sem conflito
- [ ] **AC-35 (varredura)** Uma varredura do mapa padrão não acha nenhuma entrada em duas ações do mesmo contexto
- [ ] **AC-21** Aperto e soltura entre dois passos → apertado = verdadeiro e segurado = falso; aperto, soltura e aperto no mesmo intervalo → 1 toque; o caso [I] repete com `Input.parse_input_event`
- [ ] **AC-28 (física)** Evento com posição física W e tecla lógica Z → `mover` para cima
- [ ] Repetições de teclado (`echo`) não geram bordas; soltar um bind não solta a ação se outro bind dela continua pressionado; Shift esquerdo e direito contam como um bind lógico mas mantêm estado físico separado (ADR-0006 §1)

---

## Implementation Notes

*Derived from ADR-0006 §1 e Implementation Guidelines:*

Lista fechada de ações como `StringName`, nenhuma tecla no código de jogo. A identidade física tem classe, código, localização esquerda/direita quando disponível e, para gamepad, o id do dispositivo; teclas usam posição física. O adaptador guarda estado por entrada física, conjunto de bordas novas, cursor válido em coordenadas de janela e soma dos módulos dos movimentos de mouse desde a última amostra; cada borda preserva origem, ordem de chegada e, no clique, a posição de janela no instante do aperto. Defaults ficam em dados embarcados independentes do catálogo (a tela de erros precisa deles). Não há `_physics_process` no adaptador, nem `Autoload`.

**Código atual da fatia — `src/foundation/game_input.gd` (317 linhas): reaproveitar parcialmente.** Aproveitar a leitura de `InputEvent`, eixos/radial e conexão de joystick; substituir o acesso por `Dictionary` e qualquer leitura direta de `Input` fora do adaptador. Mover o que for fronteira para `src/foundation/input/` e retirar o arquivo antigo só quando a story 002 estiver fechada (`src/app/main.gd` continua a usá-lo até lá).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: amostra por passo, movimento e dispositivo ativo
- Story 004: buffer e `ComandosDoPasso`
- Story 007: remapeamento e rótulos

---

## Files

- `src/foundation/input/acoes.gd`
- `src/foundation/input/binds_padrao.gd` (dados embarcados)
- `src/foundation/input/adaptador_de_entrada_godot.gd`
- `src/foundation/input/descritor_de_entrada.gd`
- `tests/unit/input/mapa_padrao_test.gd`
- `tests/integration/input/adaptador_parse_input_event_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/mapa_padrao_test.gd` — must exist and pass
- Integration: `tests/integration/input/adaptador_parse_input_event_test.gd`

**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/` (stories ainda por criar: ponto de composição e passo de física)
- Unlocks: `production/epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md`, `production/epics/input/story-007-remapeamento-e-rotulos-de-acao.md`

## Completion Notes

**Concluída em 2026-11-16 (gameplay-programmer, execução orquestrada sem commit).**

Arquivos criados:
- `src/foundation/input/acoes.gd`: lista fechada R1 + `troca`, contextos, conjunto do buffer, chaves direcionais internas (`mover.cima`, `ui_navegar.esquerda`).
- `src/foundation/input/binds_padrao.gd`: mapa padrão embarcado (teclas por posição física), `varrer_conflitos()`.
- `src/foundation/input/descritor_de_entrada.gd`: identidade física (tipo, código, lado, id do gamepad) e chave lógica (tipo + código).
- `src/foundation/input/adaptador_de_entrada_godot.gd`: nó fino, `_input` → descritores; estado limitado (segurados, uma borda por entrada física com ordem/origem/posição do clique, Σ|Δmouse| via `screen_relative`, cursor em px de janela, eixos por gamepad, histerese de gatilho). `drenar()` → `Lote`.
- `tests/unit/input/mapa_padrao_test.gd`: 12 casos, todos passam.
- `tests/integration/input/adaptador_parse_input_event_test.gd`: 5 casos `[I]` com `Input.parse_input_event`, todos passam.

Decisões:
- `Borda` e `Lote` são classes internas do adaptador, para não criar arquivos fora da lista da story.
- O eco é descartado no adaptador. "Segundo bind não rearma" e "soltar um bind não solta a ação" são resolvidos no provedor, porque dependem do contexto.
- Vetores de gamepad (analógicos de `mover`, `mirar` e da navegação) ficam fora do mapa, porque não são remapeáveis (ADR-0006 §6).
- Ainda não há ações `debug_*`. O teste de AC-01 confirma que nenhuma existe no conjunto de release.

Pendências:
- `Input.use_accumulated_input = false` precisa ficar no ponto de composição (`src/app/main.gd`), fora do escopo desta story. Por enquanto só o teste `[I]` o desliga.
- A conversão evento → px de janela usa o padrão herdado da fatia. A Cena (cena-e-camera, story 004) deve injetar `conversor_para_janela`.
- Não está provado que o Windows entrega o lado (esquerdo/direito) do Shift. Precisa de teste manual com hardware.
- `src/foundation/game_input.gd` (legado) continua no lugar, porque `src/app/main.gd` ainda o usa. Deve sair na integração do orquestrador.

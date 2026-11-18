# Story 004: Buffer de comandos, `ComandosDoPasso` e ação `troca`

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-007`, `TR-input-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (complemento do ADR-0008 para os metadados de época; ADR-0017 para a Troca)
**ADR Decision Summary**: O buffer é um conjunto de quatro ações com contador único: um toque novo une os comandos e repõe o prazo de todos; sem toque, um passo vivo desconta 1; hitstop conserva o prazo mas aceita toques; `ComandosDoPasso` é uma capacidade separada ligada ao passo e à época.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Lógica pura, sem API de engine; tempo é contagem de passos (nunca `Time`/`Timer`).

**Control Manifest Rules (this layer)**:
- Required: buffer com contador único; entradas `{acao, passo_do_toque, epoca, durante_congelamento}`; consumidor só aceita a época corrente; consumo de uma ação nunca apaga as outras (ADR-0006, ADR-0008)
- Forbidden: ler `Time`, `OS` ou `Engine.time_scale` na lógica (ADR-0001)
- Guardrail: `quer`/`consumir` não alocam por chamada

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-15** Toque no passo 0, sem outro toque, sem hitstop → `quer(ataque)` verdadeiro nos passos 0–9 e falso no 10
- [ ] **AC-16** Hitstop nos passos 0–35: toque no passo 0 ou no 20 → T = 10 no passo 35, disponível de 36 a 44, vazio no 45
- [ ] **AC-17** Ataque no passo 0 e Especial no passo 8 → os dois valem até o passo 17 e somem no 18 (prazo compartilhado)
- [ ] **AC-18** Buffer {selo, ataque, especial, esquiva}, consumidores Movimento → Combate → Selo: o Movimento consome a esquiva, o Combate consome o especial e deixa o ataque para o passo seguinte, o Selo roda por último; consumir um nunca remove os outros
- [ ] **AC-19** Ataque segurado com buffer vazio → `quer` verdadeiro e o buffer não muda; Esquiva ou Selo segurados por 30 passos, com buffer vazio após o prazo → `quer` falso a partir do passo 10; `interagir` e `pausar` nunca entram no buffer; Esquiva sem carga fica até o prazo acabar
- [ ] **AC-20** Ataque segurado por 30 passos → segurado em todos e "apertado" só no primeiro
- [ ] **AC-42** `troca` tocada no passo 0 → `quer(troca)` verdadeiro nos passos 0–9 e falso no 10; segurar por 30 passos com buffer vazio → falso a partir do 10
- [ ] **AC-43** Hitstop nos passos 0–5 e `troca` tocada no passo 0 → T fica em 10 até o passo 5, `quer(troca)` verdadeiro de 6 a 14 e falso no 15
- [ ] **AC-44** Buffer {esquiva, ataque, troca}, consumidores Movimento → Combate → Selo → Maldições: cada dono consome a sua ação no mesmo passo, sem remover as outras nem mudar o prazo
- [ ] Capacidade retida após o fim do passo ou troca de contexto torna `quer`/`consumir` inválidos sem alterar o buffer do passo seguinte

---

## Implementation Notes

*Derived from ADR-0006 §2 e Key Interfaces:*

O buffer guarda quatro ações mais `troca` conforme a emenda de Pactos (contador único; o consumidor da `troca` é Maldições). `ComandosDoPasso.quer(acao)`: Ataque e Especial aceitam segurado ou buffer, Esquiva e Selo só buffer. `consumir(acao)` remove só o comando executado, devolve true se removeu e não altera o prazo; o consumidor chama depois de executar com sucesso. A prioridade é ordem de tentativa pelos donos, não um despachante. O metadado `durante_congelamento` serve ao `esquiva_sem_carga` do ADR-0008 (um evento por toque no 1º passo vivo seguinte, descartado na troca de contexto); os critérios de integração desse complemento ficam com o épico movimento-e-esquiva.

**Código atual da fatia:** o buffer de `game_input.gd` (se houver) é **substituir** pelo contador único; não reaproveitar prazos por botão.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: barreira de contexto e entrada durante Transição
- Épico movimento-e-esquiva: reação `esquiva_sem_carga`
- Épico maldicoes: o consumidor da `troca`

---

## Files

- `src/foundation/input/buffer_de_comandos.gd`
- `src/foundation/input/comandos_do_passo.gd`
- `tests/unit/input/buffer_de_comandos_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/buffer_de_comandos_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md`
- Unlocks: `production/epics/input/story-005-contextos-barreira-foco-e-desconexao.md`

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos: `src/foundation/input/buffer_de_comandos.gd` e `comandos_do_passo.gd`, mais a integração em `provedor_de_entrada.gd`: `comandos_do_passo()` e `encerrar_passo()`, e invalidação em `amostrar`/`trocar_contexto`. Teste: `tests/unit/input/buffer_de_comandos_test.gd`, 15 casos, todos passam. AC-20 é coberto em `amostra_e_movimento_test.gd`.

Decisões:
- Cada entrada é `{acao, passo_do_toque, epoca, durante_congelamento}` (classe interna `Entrada`). `contem`/`remover` exigem a época corrente.
- `quer`/`consumir` não alocam: só consultam dicionários.
- `troca` só entra no buffer, sem "segurar repete".
- Fora de Jogo, o buffer é esvaziado a cada amostra.
- Complemento do ADR-0008: um contador de toques de esquiva durante hitstop (`drenar_esquivas_congeladas()`), zerado em `esvaziar()`. A integração fica com o épico movimento-e-esquiva.

Pendências:
- Os consumidores reais (Movimento, Combate, Selo, Maldições) não existem ainda. AC-18 e AC-44 foram provados com consumidores simulados pela ordem de chamada.

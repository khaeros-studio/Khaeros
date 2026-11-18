# Economia de Fragmentos

> **Status**: Approved
> **Author**: usuário + Claude (design-system, modo Lean; emenda Pactos aprovada pelo usuário em 2026-11-16)
> **Last Updated**: 2026-11-18 (correção de `efetivo = 1` em F1 e AC-EF-08); 2026-11-15 (emenda Pactos)
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P2 *A Beira cobra*; P4

> **Emenda Pactos (2026-11-15).** A fonte `chefe` deixa de ser reservada: entra no MVP
> com o *Soberano do Limiar* (`chefes.md` R9, F6). Abate ou Exorcizar: +6. Pactuar: 0
> do chefe. Vitória: +15 (sem mudança). O texto antigo fica; o novo leva a marca
> "(emenda Pactos, 2026-11-15)". Conferência das taxas: F3-P. Conflito resolvido: Chefes F6 foi emendado e usa o índice 5
> recompensado (Run R3-P), com 10/25/31.

## Summary

**Economia de Fragmentos** é a conta do **Fragmento de Eco da Beira**: soma o que a
run paga (porta e vitória), guarda o saldo entre as runs e o mostra ao jogador. No MVP
**só conta e mostra**; o gasto (Oficina de Reforja) é da fatia vertical, mas a
interface `gastar` já existe aqui.

**(emenda Pactos, 2026-11-15)** No MVP a run paga em três fontes: porta, **chefe**
(+6 no abate ou Exorcizar; 0 ao Pactuar) e vitória.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Run e regiões, Portas e recompensas, Conteúdo orientado a dados` · **(emenda Pactos, 2026-11-15)** + `Chefes (por contrato)`

## Overview

> `economy-designer` não consultado nesta seção: modo Lean.

**Economia de Fragmentos** é dona de **um número**: o saldo. Ela não decide quando uma
porta é aberta (Portas e recompensas), quando a run acaba (Run e regiões) nem em que
se gasta (Oficina, fatia vertical). Decide **quanto cada fonte paga** (as taxas, em
dados), **quando o saldo muda** e **quem pode mexer nele**.

- **Fontes no MVP:** a porta de Fragmentos (`2 + floor(p/3)`, fórmula das Portas) e a
  vitória (`fragmentos_vitoria` 15, da Run). Chefe (6) e Provação (3) são fontes
  **reservadas**, com taxa já em dados. **Não há Fragmento por abate** (cânone: com +1
  por elite a renda subia ~55% sem decisão do jogador).
- **Saldo:** inteiro ≥ 0, **fora do reset da Nova run** (Run R8), mantido na vitória,
  na morte e no abandono. **Só em memória** no MVP: zera ao fechar o jogo; a
  persistência entre sessões fica para o Save e perfil (a Economia expõe
  `exportar/importar`).
- **Gasto:** `gastar(custo)` atômico (recusa se faltar saldo, nunca negativo), testado
  com dublê; nenhuma tela de gasto no MVP.
- **Mostrar:** o saldo e cada mudança vão como evento para o HUD, a tela final e a
  Telemetria.

A **fantasia** é a de que a Beira cobra, mas deixa algo: nenhuma run termina de mãos
vazias. No MVP não há sumidouro: ela só acumula (é um contador); o ciclo fecha (fonte e gasto) na fatia vertical, com a Oficina. A economia é pequena de propósito: poucas fontes, todas ligadas a uma escolha
do jogador (porta ou chegar ao fim), sem moer inimigos.

As regras seguem o cânone (`engine.ts:497–500`, `:510–525`, `TRIAL_FRAGMENTS`,
baseline §56–57), com as decisões do usuário de 2026-11-11: saldo só em memória,
fontes porta e vitória, `gastar` pronto sem loja.

> **→ vira ADR:** não. O saldo é um objeto injetado, como o resto do projeto.

## Detailed Design

### Core Rules

**R1. A conta.** Um objeto `ContaFragmentos`, injetado (sem singleton), com dois
inteiros: `saldo` (≥ 0, começa em 0, atravessa as runs) e `coletados_run` (o que a run
atual creditou; zera na Nova run). `saldo` tem teto `saldo_max` (padrão 999 999); um
crédito que passaria do teto é cortado no teto e emite o aviso `saldo_no_teto`.

**R2. Quem calcula cada taxa (dono único por número).** A Economia **não** guarda as
taxas das fontes que já têm dono; ela só **credita** o que recebe:

| Origem | Quantidade | Dono da taxa | MVP |
|---|---|---|---|
| `porta` | `2 + floor(p/3)` (Portas F1; também quando a bênção vira Fragmentos, Portas R3) | `RewardTable` (Portas) | sim |
| `vitoria` | `fragmentos_vitoria` (15) | `RunTuning` (Run) | sim |
| `chefe` | `RegionDef.fragmentos_chefe` (6) | `RegionDef` | reservada |
| `provacao` | `fragmentos_provacao` (3) | `EconomyRates` (Economia) | reservada |

`EconomyRates` fica só com `fragmentos_provacao` e `saldo_max`. Isto **corrige** a
"resolução por contrato" do índice (a Economia dona de todas as taxas): a Run e as
Portas já são donas das suas e duplicar o número criaria dois donos.

**R2-P (emenda Pactos, 2026-11-15).** A linha `chefe` passa a valer no MVP:

| Origem | Quantidade | Dono da taxa | Quem chama | MVP |
|---|---|---|---|---|
| `chefe` | `RegionDef.fragmentos_chefe` (6; cânone `bossFragments`, Run R4) | `RegionDef` | **Chefes** (R9, F6) | **sim** |

- Lâmina e Ressonância: Chefes chama `creditar(chefe, 6)` quando o chefe fica `Morto`.
- Pactos, **Exorcizar**: Chefes chama `creditar(chefe, 6)`.
- Pactos, **Pactuar**: Chefes **não chama** `creditar`. O "0 Fragmentos" de Chefes F6
  é a ausência da chamada: `creditar(chefe, 0)` seria recusado com `EC1` (R3).
  Contrato pedido a Chefes: deixar isso explícito na F6.
- A Economia continua sem guardar a taxa do chefe.

**R3. Creditar.** `creditar(origem, quantidade) → efetivo`: `quantidade` do tipo `int` (um `float`, mesmo `2.0`, é recusado) e ≥ 1 e `origem`
na tabela da R2, senão **recusa** (erro `EC1`, saldo intacto, sem evento). Sucesso:
soma ao `saldo` e a `coletados_run` e emite `saldo_mudou(saldo, delta, origem)`. Não
há Fragmento por abate nem por elite (cânone, baseline §56).

**R4. Quando a Run e as Portas creditam.** A porta credita ao limpar a câmara da porta
escolhida (Portas R4/R8). A Run, ao vencer, lê `coletados_run()` **antes** de creditar
a vitória e depois faz `bonus = creditar(vitoria, fragmentos_vitoria)` (o `efetivo`
devolvido, F1); o resumo guarda `coletados`, `bonus` e `total = coletados + bonus`
(Run R7/F2). `coletados_run()` significa sempre "tudo que a run creditou", vitória
incluída. **Morte vence a limpeza:** se `jogador_morreu` e `camara_limpa` caem no mesmo
passo, as Portas **não** creditam (Run R5; Portas R2 recebe a mesma nota).

**R4-P (emenda Pactos, 2026-11-15).** Ordem na câmara do chefe: crédito do chefe (se
houver) → `camara_limpa(4, chefe)` → `fim_da_run` → a Run lê `coletados_run()` (já com
os 6 do chefe) → `creditar(vitoria, 15)` → `run_encerrada`. O crédito do chefe sai no
1º passo vivo após o hitstop de chefe (36 passos; Chefes R9) ou na escolha Exorcizar.
**Morte vence:** jogador morto no passo do abate do chefe → sem crédito do chefe
(Chefes, Edge Cases; Run R5-P). O resumo não separa o chefe: ele está em `coletados`;
o desfecho vem em `desfecho_chefe` (Run R7-P).

**R5. Gastar.** `gastar(custo, motivo)`: `custo` inteiro ≥ 1. Se `saldo < custo`:
recusa com `saldo_insuficiente`, saldo intacto. Senão subtrai e emite
`saldo_mudou(saldo, −custo, motivo)`. É atômico (tudo ou nada). **Não mexe em
`coletados_run`**. No MVP ninguém chama (não há Oficina); existe e é testado com dublê.

**R6. Nova run.** `nova_run()` zera `coletados_run` e **não** toca `saldo` (Run R8).
Morte e abandono também não tocam o saldo (Run R5/R6).

**R7. Persistência (OQ 5 da Run).** No MVP o saldo é **só em memória**: zera ao
fechar o jogo. `exportar() → int` devolve o saldo; `importar(int)` o restaura (valor
inválido, negativo ou não `int`: **mantém o saldo atual** e emite `EC2`; acima do teto: corta). O Save
e perfil (fatia vertical) liga os dois sem mudar este GDD.

**R8. Consulta e eventos.** `saldo()` e `coletados_run()` são consultas puras. Eventos:
`saldo_mudou(saldo, delta, origem)` e `saldo_no_teto`. O HUD, a tela final e a
Telemetria só leem e escutam; nenhum escreve (só Run, Portas e, depois, a Oficina).

**R9. Injeção.** Recebe `EconomyRates` e começa vazia (ou importada). Os testes montam
a conta em memória, sem cena, e usam dublês para os créditos das Portas e da Run.

### States and Transitions

Sem máquina de estados: a conta responde a qualquer chamada, em qualquer estado do
jogo (a Run decide quando chamar). A única transição é `nova_run()` (R6).

### Interactions with Other Systems

| Sistema | Recebe da Economia | Fornece à Economia | Dono da interface |
|---|---|---|---|
| Portas e recompensas | `saldo_mudou` (opcional, HUD) | `creditar(porta, n)` (Portas F1) | Economia |
| Run e regiões | `coletados_run()`, o `efetivo` de `creditar` | `creditar(vitoria, n)`; `nova_run()` | Economia |
| Conteúdo orientado a dados | — | `EconomyRates` | Conteúdo |
| HUD, tela final, Telemetria | `saldo()`, `coletados_run()`, `saldo_mudou` | — | Economia |
| Oficina de Reforja (fatia vertical) | `gastar(custo, motivo)` | — | Economia |
| Save e perfil (fatia vertical) | `exportar()`/`importar(int)` | — | Economia |
| **(emenda Pactos, 2026-11-15)** Chefes | `saldo_mudou` (opcional) | `creditar(chefe, 6)` no abate ou Exorcizar; nada ao Pactuar | Economia |

## Formulas

**F1. Crédito.** `efetivo = min(q, saldo_max − saldo)`; `saldo' = saldo + efetivo`;
`coletados_run' = coletados_run + efetivo`. Se `efetivo < q`, emite `saldo_no_teto`.
`q` é inteiro ≥ 1 (R3). Ex.: saldo 999 998, `q` 3 → efetivo 1, saldo 999 999.

**F2. Gasto.** `saldo' = saldo − custo` se `saldo ≥ custo`, senão nada muda. Ex.:
saldo 11, custo 15 → recusa; saldo 26, custo 15 → saldo 11.

**F3. Renda de uma run no Limiar (MVP).** As portas de Fragmentos pagam nas câmaras
1, 2 e 4 (a 0 dá bênção, o santuário dá cura; **o índice 5 não dá recompensa**, decisão
do usuário de 2026-11-12: só a vitória), com `p` 1, 2, 3 e a fórmula das Portas
(F1: `2 + floor(p/3)`) = **2, 2, 3** (soma 7).

| Caso (índices da sequência) | Fragmentos coletados |
|---|---|
| Mínimo, vitória (nenhuma porta de Fragmentos) | 0 + 15 = **15** |
| Máximo, vitória (as 3 portas de Fragmentos) | 7 + 15 = **22** |
| Mínimo, morte | **0** |
| Máximo, morte no índice 5 antes de limpar | 2 + 2 + 3 = **7** |

Faixa por run: 0–22. Para a Oficina (350 no total, baseline §57.2): 350/22 ≈ **16** runs
com renda máxima ou 24 com a mínima. Renda esperada de quem sempre pega Fragmentos quando
aparece: P(aparece numa escolha) = 0,8133 (Portas F2), então ≈ 7 × 0,81 + 15 ≈ 21 por
vitória, ~17 runs para os 350. A faixa mínima de 15 só vale se o pool de bênçãos não
esgotar (bênção sem pool vira Fragmentos, Portas R3: só soma). A calibração fina fica
para o balance-check da Oficina (OQ 2).

**F3-P. Renda de uma run no Limiar com chefe (emenda Pactos, 2026-11-15).**
`renda = portas + frag_chefe + vitoria`. `frag_chefe ∈ {0, 6}` (Chefes F6); `vitoria ∈
{0, 15}`.

**Conferência das taxas:**
- `chefe` 6 = `RegionDef.fragmentos_chefe` (R2) = cânone `bossFragments` (Run R4) =
  Chefes F6. **Bate.**
- `vitoria` 15 = `RunTuning.fragmentos_vitoria` (Run knobs) = Chefes F6. **Bate.**
- ~~**Portas: conflito [a confirmar].** A F3 acima diz que o índice 5 não dá recompensa
  (máx. 7), e Chefes F6 repete "até 7 de portas". A emenda da Run (R3-P) faz do
  índice 5 uma câmara comum, com Fragmentos `2 + floor(4/3) = 3` (máx. 10). A F3
  antiga fica até o usuário decidir.~~
- **Portas: resolvido.** Chefes F6 foi emendado: índice 5 recompensado (Run R3-P),
  máx. 10 de portas, totais 10/25/31. **Bate** com a coluna "Índice 5 recompensado"
  abaixo; a outra coluna fica como registro.

| Caso | Índice 5 recompensado (Run R3-P) | Índice 5 sem recompensa (F3 / Chefes F6) |
|---|---|---|
| Máx., vence por abate ou Exorcizar | 10 + 6 + 15 = **31** | 7 + 6 + 15 = **28** |
| Máx., Pactos pactua | 10 + 0 + 15 = **25** | 7 + 0 + 15 = **22** |
| Mín., vence por abate ou Exorcizar | 0 + 6 + 15 = **21** | **21** |
| Mín., Pactos pactua | **15** | **15** |
| Máx., morre no chefe | **10** | **7** |
| Mín., morte | **0** | **0** |

**Renda esperada** de quem sempre pega Fragmentos (P = 0,8133 por escolha, Portas F2) e
vence por abate: ≈ 10 × 0,81 + 21 ≈ **29** (ou 7 × 0,81 + 21 ≈ 27). Para os 350 da
Oficina: ≈ 12 a 13 vitórias (antes ≈ 17). Ao Pactuar: ≈ 23 (ou 21) por vitória.

**Leitura (P2, *A Beira cobra*):** Pactuar custa 6, ≈ 20–25% de uma vitória. Pactos
nunca ganha mais que Lâmina e Ressonância: no máximo empata (Exorcizar). Não há laço de
renda infinito: o chefe paga 1 vez por run e não há Fragmento por abate. A renda maior
só aproxima a Oficina; a calibração é a OQ 2.

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `saldo_max` | 999 999 | 9 999–2 147 483 647 | gate | teto do saldo; só evita estouro de inteiro (a renda é ≤ 22 por run) |
| `fragmentos_provacao` | 3 | 0–10 | curva | cânone `TRIAL_FRAGMENTS`; reservada (Provação fora do MVP) |

As taxas de porta, vitória e chefe **não** são knobs daqui (R2): ficam na
`RewardTable`, no `RunTuning` e na `RegionDef`.

**(emenda Pactos, 2026-11-15)** O racional de `saldo_max` passa a "renda ≤ 31 por
run" (F3-P); o padrão não muda. Faixa segura sugerida para `RegionDef.fragmentos_chefe`
(dono: Conteúdo/Chefes): **0–10 [a confirmar]**. Acima de 10, Pactuar passa a custar
mais que metade da vitória (15) e empurra o jogador a Exorcizar sempre; em 0, Pactuar
deixa de ter preço (P2).

## Edge Cases

- **Crédito de 0, negativo ou não inteiro:** recusa com `EC1`, saldo e `coletados_run`
  intactos, sem evento.
- **Origem desconhecida:** recusa com `EC1`; `chefe` e `provacao` são aceitas
  (reservadas, ninguém as chama no MVP).
- **Crédito que passa do teto:** corta no teto, `saldo_no_teto`; `coletados_run` soma
  só o efetivo.
- **Crédito com efetivo 0 (saldo já no teto):** sem evento `saldo_mudou`; só
  `saldo_no_teto`.
- **`gastar` com custo 0, negativo ou não inteiro:** recusa com `EC1`, sem evento.
- **`gastar` com saldo insuficiente:** `saldo_insuficiente`, nada muda (sem gasto
  parcial).
- **`gastar` em sequência rápida (dois gastos no mesmo passo):** cada um valida contra
  o saldo já descontado; o segundo pode ser recusado.
- **Morte e `camara_limpa` no mesmo passo:** morte vence, as Portas não creditam (R4).
- **Morte, abandono ou fim da run:** o saldo não muda (só os créditos já feitos); o
  resumo lê `coletados_run()` antes da vitória e o `efetivo` dela (R4).
- **Nova run sem ter jogado:** `coletados_run` já é 0; o saldo fica.
- **Fechar o jogo no meio da run:** o saldo em memória se perde (R7); aceito no MVP
  (OQ 1).
- **`importar` com valor inválido:** mantém o saldo atual e emite `EC2`, sem travar; acima do teto: corta.
- **Dois créditos no mesmo passo (porta e vitória):** aplicados na ordem de chamada,
  cada um com seu evento (a ordem de chamada é da Run, AC-RN-09).
- **`creditar` durante Transição ou pausa:** aceito; a Economia não tem estado (a Run
  e as Portas só chamam em momentos válidos).

**(emenda Pactos, 2026-11-15)**
- **"Origem desconhecida" acima:** `chefe` deixa de ser reservada; agora Chefes a chama.
- **Pactuar:** nenhuma chamada; se vier `creditar(chefe, 0)`, recusa `EC1`, sem evento
  (R2-P).
- **Dois créditos de chefe na mesma run** (ex.: abate e Exorcizar duplicados por erro):
  a Economia aceita os dois (não tem estado); garantir 1 crédito é de Chefes (F6).
  O teste de integração AC-EF-33 pega a duplicação.
- **Morte no passo do abate do chefe:** sem crédito do chefe (R4-P).
- **Fechar o jogo em `Subjugado`:** nenhum crédito do chefe; o saldo se perde de
  qualquer modo (R7).
- **Vínculo já no máximo e o jogador Pactua:** 0 Fragmentos sem ganho; Pactuar fica
  dominado por Exorcizar. Não é falha da Economia; registrado para Vínculo e pactos
  (OQ 7).

## Dependencies

| Sistema | Direção | Natureza | Interface |
|---|---|---|---|
| Portas e recompensas | entra | por contrato | `creditar(porta, n)` com `n` da Portas F1; sem bênção vira `porta` (Portas R3) |
| Run e regiões | entra e sai | por contrato | `creditar(vitoria, n)` (devolve o efetivo), `nova_run()`; lê `coletados_run()` antes da vitória para o resumo (Run R7) |
| Conteúdo orientado a dados | entra | rígida | `EconomyRates` (`fragmentos_provacao`, `saldo_max`); nota de edição pendente |
| HUD | sai | leitura | `saldo()`, `saldo_mudou` |
| Tela final | sai | leitura | `coletados_run()` via resumo da Run |
| Telemetria local | sai | leitura | `saldo_mudou(saldo, delta, origem)` |
| Oficina de Reforja (fatia vertical) | sai | por contrato | `gastar(custo, motivo)` |
| Save e perfil (fatia vertical) | sai | por contrato | `exportar()` / `importar(int)` |
| Chefes (fatia vertical) | entra | reservada | `creditar(chefe, n)` com `RegionDef.fragmentos_chefe` |
| **(emenda Pactos, 2026-11-15)** Chefes (**MVP**) | entra | por contrato | `creditar(chefe, 6)` no abate ou Exorcizar; nada ao Pactuar (Chefes R9, F6). Bidirecional: Chefes, Depended On By |

Nenhum sistema depende da Economia para **rodar** a run: sem ela, os créditos viram
chamadas perdidas e o jogo continua (a Run e as Portas aceitam a interface ausente).

## Visual/Audio Requirements

- **Ganho:** o número do saldo no HUD sobe com um pulso curto e um som de moeda leve; o
  ganho de porta aparece também como "+N" junto da câmara (HUD).
- **Recusa de gasto:** (fatia vertical) tremor curto do saldo e som seco; fora do MVP.
- **Teto:** sem efeito próprio (valor inalcançável na prática).

Visual e som são do HUD, do Áudio e da Pipeline visual; esta seção só declara os
eventos que os disparam (`saldo_mudou`). Sem cor própria definida: o art-director
escolhe (OQ 3).

## Game Feel

- **Latência:** o saldo no HUD atualiza no mesmo passo do evento (≤ 1 passo, 16,7 ms).
- **Legibilidade:** o "+N" fica visível por ~1,5 s; vários ganhos seguidos somam num
  só "+N" (HUD decide a janela).
- **Sem moer:** não há Fragmento por abate, então o combate não ganha "plink" de moeda;
  o ganho só aparece ao limpar a câmara (porta) e na tela final (vitória).

## UI Requirements

- Saldo sempre visível no HUD fora de combate pesado; na tela final: "coletados" e
  "bônus de vitória" separados e o saldo novo (HUD OQ e GDD do HUD).
- Rótulo "Fragmentos de Eco" (nome definitivo é do narrative-director/localização).
- Sem tela de gasto no MVP.

## Cross-References

- Run e regiões R5–R8, F2, OQ 5 (saldo fora do reset; persistência).
- Portas e recompensas R3, R4, F1, `RewardTable`.
- Conteúdo orientado a dados `EconomyRates`, `RunTuning`, `RegionDef`.
- Baseline §56 (sem Fragmento por abate), §57.2 (Oficina, 350); `engine.ts:497–525`.
- Índice: linha 21; a circularidade "Run e regiões ↔ Economia" passa a dono único por taxa (R2); **pendente** a edição do índice, do Conteúdo e da Run (OQ 5).

## Acceptance Criteria

Tipos: [L] lógica (unitário), [I] integração, [V] visual (screenshot).

- **AC-EF-01 [L] R1 — início.** Conta nova: `saldo()` = 0 e `coletados_run()` = 0.
- **AC-EF-02 [L] R3/F1 — crédito simples.** `creditar(porta, 2)`: saldo 2, `coletados_run` 2, um `saldo_mudou(2, +2, porta)`.
- **AC-EF-03 [L] R3 — acumula.** `creditar(porta,2)`, `creditar(porta,3)`, `creditar(vitoria,15)`: saldo 20, `coletados_run` 20, três eventos na ordem.
- **AC-EF-04 [L] R3 — quantidade inválida.** `creditar(porta, 0)`, `-1`, `2.5`, `2.0` (float) e `NaN`: recusa `EC1`, saldo e `coletados_run` intactos, sem evento.
- **AC-EF-05 [L] R3 — origem inválida.** `creditar("abate", 1)`: recusa `EC1`, nada muda.
- **AC-EF-06 [L] R3 — sem abate.** O evento de morte de inimigo do Combate (dublê) não altera o saldo; nenhuma origem `abate`/`elite` existe.
- **AC-EF-07 [L] R2 — reservadas aceitas.** `creditar(chefe, 6)` e `creditar(provacao, 3)` funcionam como qualquer origem válida.
- **AC-EF-08 [L] F1/R1 — teto.** Saldo 999 998, `creditar(porta, 3)`: saldo 999 999, `coletados_run` soma 1, `saldo_no_teto` emitido, `saldo_mudou` com delta +1.
- **AC-EF-09 [L] R1 — teto cheio.** Saldo 999 999, `creditar(porta, 2)`: nenhum `saldo_mudou`; `saldo_no_teto` emitido; saldo igual.
- **AC-EF-10 [L] R5/F2 — gastar com saldo.** Saldo 26, `gastar(15, "teste")`: saldo 11, `saldo_mudou(11, −15, "teste")`, `coletados_run` intacto.
- **AC-EF-11 [L] R5 — gasto exato.** Saldo 15, `gastar(15)`: saldo 0.
- **AC-EF-12 [L] R5 — insuficiente.** Saldo 11, `gastar(15)`: `saldo_insuficiente`, saldo 11, sem evento.
- **AC-EF-13 [L] R5 — custo inválido.** `gastar(0)`, `-3`, `1.5`: recusa `EC1`, saldo intacto.
- **AC-EF-14 [L] R5 — dois gastos seguidos.** Saldo 20, `gastar(15)` e `gastar(15)`: o 1º passa (saldo 5), o 2º é recusado.
- **AC-EF-15 [L] R6 — Nova run.** Saldo 11, `coletados_run` 11; `nova_run()`: saldo 11, `coletados_run` 0.
- **AC-EF-16 [L] R6 — morte e abandono.** `jogador_morreu` e abandono (dublês da Run) não mudam o saldo.
- **AC-EF-17 [L] R7 — exportar.** Saldo 26: `exportar()` = 26.
- **AC-EF-18 [L] R7 — importar válido.** `importar(40)` numa conta nova: saldo 40, `coletados_run` 0.
- **AC-EF-19 [L] R7 — importar inválido.** Saldo 26: `importar(-5)`, `1.5`, `"x"` mantêm 26 e emitem `EC2`; `importar(2 000 000)` com teto 999 999: saldo 999 999.
- **AC-EF-20 [L] R7 — sem persistência.** Conta recriada (simula fechar o jogo): saldo 0.
- **AC-EF-21 [L] R3/R4 — `efetivo`.** `creditar(porta,2)` devolve 2; saldo 999 998: `creditar(vitoria,15)` devolve 1 e `coletados_run()` soma 1.
- **AC-EF-22 [I] R4 — Run, vitória (a última câmara não dá recompensa).** Saldo 11; portas pagam 2 (índice 1) e 3 (índice 4, p 3); a Run lê coletados 5, `bonus` 15: saldo 11 + 5 + 15 = 31, resumo coletados 5, bônus 15, total 20. Limpar o índice 5 não credita nada além da vitória. Referência: Run AC-RN-09/25.
- **AC-EF-23 [I] R4 — Run, morte.** Saldo 11, porta de 2 paga no índice 1, morte no índice 2: saldo 13, resumo total 2, sem bônus.
- **AC-EF-24 [I] R3 — Portas.** Porta de Fragmentos com `p` 3 credita 3; a bênção sem pool (Portas R3) credita como `porta` com `p` da câmara.
- **AC-EF-25 [I] F3 — extremos do Limiar.** 3 portas de Fragmentos (índices 1, 2, 4) + vitória: coletado 7 + 15 = 22; nenhuma + vitória: 15; nenhuma + morte: 0; as 3 portas e morte no índice 5 antes de limpar: 7.
- **AC-EF-26 [I] R8 — leitura.** HUD e Telemetria (dublês) recebem `saldo_mudou` em ordem, sem poder alterar a conta (a interface de leitura não expõe `creditar` nem `gastar`).
- **AC-EF-27 [V] UI — HUD.** Screenshot do saldo e do "+N" após uma porta de Fragmentos (`production/qa/evidence/`), junto do HUD.

- **AC-EF-28 [I] R4 — morte e limpeza no mesmo passo.** `jogador_morreu` e `camara_limpa` (porta de Fragmentos) no mesmo passo: as Portas não creditam; saldo e `coletados_run` intactos.
- **AC-EF-29 [L] R8 — teto avisa.** O `saldo_no_teto` do AC-EF-08 e do AC-EF-09 chega ao ouvinte (dublê de HUD).
- **AC-EF-30 [L] R2/R9 — sem taxas de porta.** A conta monta em memória só com `EconomyRates` (`fragmentos_provacao`, `saldo_max`), sem cena; `fragmentos_base` não existe nela e `creditar(chefe, 6)` funciona sem dado de taxa.

**(emenda Pactos, 2026-11-15)** Com o chefe no MVP, AC-EF-22 e AC-EF-25 valem só com
`camaras_jogaveis = 6`; AC-EF-31 a 34 cobrem o Limiar com chefe.

- **AC-EF-31 [I] R2-P/R4-P — abate.** GIVEN saldo 11 (coletados 5), WHEN o dublê de
  Chefes abate com Lâmina, THEN `saldo_mudou(17, +6, chefe)` sai antes de
  `camara_limpa`; a Run lê coletados 11 e credita 15; saldo 32; resumo total 26.
- **AC-EF-32 [I] R2-P — Pactuar.** GIVEN Pactos com o chefe `Subjugado` e saldo 11,
  WHEN a escolha é `pactuar`, THEN nenhum `saldo_mudou` com origem `chefe`; após a
  vitória, saldo 26.
- **AC-EF-33 [I] R2-P — Exorcizar, 1 crédito.** GIVEN Pactos e saldo 11, WHEN a
  escolha é `exorcizar`, THEN exatamente 1 `saldo_mudou(17, +6, chefe)`; após a
  vitória, saldo 32.
- **AC-EF-34 [I] R4-P — morte no abate.** `jogador_morreu` no passo em que o chefe
  zera a Vida: nenhum crédito `chefe` nem `vitoria`; saldo intacto.
- **AC-EF-35 [I] F3-P — extremos (depende da OQ 8).** Com o índice 5 recompensado: 4
  portas de Fragmentos + abate + vitória = 31; + Pactuar = 25. Sem: 28 e 22.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Persistência entre sessões (hoje só em memória, perde ao fechar o jogo) | Save e perfil | fatia vertical |
| 2 | Calibração do custo da Oficina contra a renda de 15–22 por run (350 no total) | Oficina de Reforja + balance-check | fatia vertical |
| 3 | Cor, som e rótulo definitivos de "Fragmentos de Eco" | art-director, audio-director, localização | HUD |
| 4 | Fragmentos do chefe (6) e da Provação (3): origem e momento do crédito | Chefes / Câmaras | fatia vertical |
| 6 | **(emenda Pactos, 2026-11-15)** OQ 4 resolvida para o chefe (Chefes R9, F6); a Provação segue aberta. Com pactos e vínculo salvos entre sessões (save mínimo do MVP), o saldo deve entrar no mesmo save? Hoje R7 e ADR-0013 dizem que não **[a confirmar]** | usuário; Save mínimo | GDD de Save mínimo |
| 7 | **(emenda Pactos)** ~~Pactuar com vínculo no máximo fica dominado por Exorcizar (0 vs. 6 sem ganho)~~ **Fechada:** Vínculo V18.5 ("o fardo repartido"): com o *Soberano* no nível 5, os 10 pontos de Pactuar vão inteiros para cada espécie da dupla (ou para a pactuada de menor nível fora dela). Pactuar segue com ganho | Vínculo e pactos | ~~GDD de Vínculo e pactos~~ resolvida |
| 8 | **(emenda Pactos)** ~~Índice 5 recompensado (Run R3-P, máx. 10 de portas) ou não (F3, Chefes F6, máx. 7)~~ **Fechada:** Chefes F6 emendado com índice 5 recompensado (10/25/31) | usuário; Portas; Chefes | ~~antes de aprovar a emenda~~ resolvida |
| 5 | **Edições pendentes por dono único:** Conteúdo (linha 96 `EconomyRates` só com Provação e `saldo_max`; linhas 390 e 787; campo `RegionDef.fragmentos_chefe`; `EC1`/`EC2` como códigos V*), Run (linha 155; R4/F2 com `efetivo` e `bonus`), Portas (R2: morte vence a limpeza), índice (linha 21) | Conteúdo, Run, Portas | `/review-all-gdds` |

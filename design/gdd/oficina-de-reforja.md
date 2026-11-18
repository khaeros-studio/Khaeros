# Oficina de Reforja

> **Status**: Designed
> **Author**: game-designer (Vertical Slice)
> **Created**: 2026-11-18
> **Last Updated**: 2026-11-18
> **Sistema**: #22 · Category: `Progression` · Priority: `Vertical Slice`
> **Implements Pillar**: P2 *A Beira cobra*; P4 *Ritual, não pressão*

## Summary

A **Oficina de Reforja** é o sistema de metaprogresso permanente entre runs onde o jogador gasta **Fragmentos de Eco da Beira** acumulados na `Economia de Fragmentos` para comprar melhorias permanentes no perfil (`Save`). Na Vertical Slice, oferece 5 melhorias iniciais (**Têmpera Vital**, **Passada Firme**, **Fio Afiado**, **Reserva de Esquiva** e **Canalização do Selo**) que injetam modificadores com fonte `meta:reforja_*` no sistema de `Modificadores e atributos` no início de cada run, com suporte a **reembolso/reset gratuito** integral a qualquer momento no Campus.

> **Quick reference** — Layer: `Progression` · Priority: `Vertical Slice` · Key deps: `Economia de Fragmentos, Modificadores e atributos, Save e perfil, Conteúdo orientado a dados, Campus (hub)`

## Overview

No MVP, os Fragmentos de Eco da Beira apenas acumulavam em memória (`economia-de-fragmentos.md`). Na Vertical Slice, a **Oficina de Reforja** fecha o ciclo econômico (faucet → sink) e dá sentido ao retorno ao Campus: cada descida — mesmo uma derrota após limpar algumas câmaras — aproxima o Iniciado de uma melhoria tangível.

- **5 melhorias permanentes iniciais:** cobrem sobrevivência, mobilidade, dano geral, esquiva e dano de Selo, sem criar escolhas falsas (todas têm impacto direto e legível no loop de combate).
- **Custo progressivo em Fragmentos:** cada nível comprado aumenta o custo do próximo nível de forma previsível, totalizando **380 Fragmentos** para maximizar todas as 5 melhorias (~16 a 24 runs no Limiar, alinhado à projeção de `economia-de-fragmentos.md` F3).
- **Reset gratuito (reembolso integral):** seguindo **P4 (*Ritual, não pressão*)**, o jogador pode zerar todas as melhorias da Oficina no Campus e receber **100% dos Fragmentos gastos** de volta, permitindo experimentar builds diferentes sem punição nem grind extra.
- **Integração limpa:**
  - **Economia de Fragmentos:** debita via `gastar(custo, motivo)` e devolve no reset.
  - **Modificadores e atributos:** no início de cada run, aplica cada melhoria com nível > 0 usando fonte `meta:reforja_<id>`.
  - **Save e perfil:** implementa `PortaDeSecao` (`ler(dados)` / `escrever()`) persistindo na seção `[oficina]` de `user://perfil.cfg`.

**Fantasia do jogador (MDA — Progression, Autonomy, Competence):** Sentir que o tempo na Beira forja o próprio Iniciado: cada retorno à Oficina traz uma escolha real de investimento ("mais fôlego para errar menos, ou mais dano para quebrar o chefe mais rápido?"), com liberdade total para reforjar a estratégia a custo zero.

## Detailed Design

### Core Rules

**R1. Catálogo das 5 melhorias iniciais.**
Cada melhoria é um recurso orientado a dados (`ReforgeUpgradeDef`, `Conteúdo orientado a dados`) com `id`, `chave_nome`, `chave_descricao`, `nivel_max`, `custo_base`, `custo_passo`, `tipo_efeito` e `valor_por_nivel`:

| ID (`id`) | Nome em UI | Atributo / Tipo (`Modificadores`) | Ganho por nível | Nível Máx. | Máx. Total |
|---|---|---|---|---|---|
| `tempera_vital` | Têmpera Vital | `vida_max_plano` (`vida_max`, plano) | `+10` Vida Máx | `5` | `+50` Vida Máx |
| `passada_firme` | Passada Firme | `velocidade_pct` (`velocidade`, percentual) | `+0.05` (`+5%`) | `4` | `+20%` Velocidade |
| `fio_afiado` | Fio Afiado | `dano_todo_pct` (`dano_todo`, percentual) | `+0.06` (`+6%`) | `5` | `+30%` Dano Geral |
| `reserva_esquiva` | Reserva de Esquiva | `cargas_esquiva` (`cargas_esquiva`, plano) | `+1` Carga de Esquiva | `1` | `+1` Carga Máx. |
| `canalizacao_selo` | Canalização do Selo | `dano_selo_pct` (`dano_selo`, percentual) | `+0.10` (`+10%`) | `4` | `+40%` Dano de Selo |

**R2. Compra de nível.**
- A compra só é permitida **fora de run ativa** (no Campus / estado de Menus).
- Pré-condições para `comprar(id_melhoria)`:
  1. `id_melhoria` existe no catálogo.
  2. `nivel_atual < nivel_max`.
  3. `economia.saldo() >= custo_proximo_nivel(id_melhoria)`.
- Se alguma pré-condição falhar, a compra é recusada sem alterar níveis nem saldo, retornando motivo explícito (`id_invalido`, `nivel_maximo`, `saldo_insuficiente` ou `em_run`).
- Em sucesso:
  1. Chama `economia.gastar(custo, "reforja:" + id_melhoria)`.
  2. Incrementa `niveis[id_melhoria] += 1` e soma `custo` em `total_gasto`.
  3. Emite `melhoria_comprada(id_melhoria, novo_nivel, custo)`.
  4. Marca o `Save` como pendente (gravação no ponto seguro, `save-e-perfil.md` R5.1).

**R3. Reembolso / Reset gratuito.**
- O jogador pode acionar `resetar()` na Oficina (fora de run) sem qualquer taxa ou perda de Fragmentos.
- Se `total_gasto == 0` (nenhuma melhoria comprada), `resetar()` é no-op (não emite erro nem altera saldo).
- Se `total_gasto > 0`:
  1. Calcula `reembolso = total_gasto` (soma exata dos custos pagos ou reconstruída pela fórmula F2 caso venha de migração).
  2. Devolve o valor integral à `Economia de Fragmentos` (contrato: `creditar("reembolso_oficina", reembolso)` ou método dedicado `estornar_oficina(reembolso)` respeitando `saldo_max`).
  3. Zera `niveis` (todos `0`) e `total_gasto = 0`.
  4. Emite `oficina_resetada(reembolso)`.
  5. Marca o `Save` como pendente.

**R4. Integração com `Modificadores e atributos` (`meta:reforja_*`).**
- A Oficina não altera atributos diretamente fora da run; ao iniciar uma run (`aplicar_em_portador(portador)`), para cada melhoria com `nivel > 0`:
  - Cria/aplica um modificador no portador do jogador com:
    - `fonte`: `"meta:reforja_" + id_melhoria` (ex.: `meta:reforja_tempera_vital`, `meta:reforja_fio_afiado`).
    - `atributo` e `operacao`: conforme tabela da R1.
    - `valor`: `nivel * valor_por_nivel`.
    - `duracao`: permanente na run (sobrevive entre câmaras; limpo ao fim da run pelo Modificadores R6 e reaplicado na próxima run).
- **Propagação para Maldições (Pactos):** Como `fio_afiado` (`dano_todo_pct`) e `passada_firme` (`velocidade_pct`) são modificadores no portador do jogador, eles seguem automaticamente a regra de propagação `tipos_propagados_maldicao` de `modificadores-e-atributos.md` R14.
- **Teto de `cargas_esquiva` e `vida_max`:** Respeitam os pisos e tetos definidos em `ModifiersTuning` / `MovementTuning`.

**R5. Persistência via `Save e perfil` (`PortaDeSecao`).**
- A Oficina implementa a interface `PortaDeSecao` (`save-e-perfil.md` R2, R3 e R15) para a seção `[oficina]`:
  - `escrever() -> Dictionary`: retorna exclusivamente tipos permitidos (`int`, `String`, `Dictionary` de `int`, sem `float`):
    ```
    {
      "versao": 1,
      "niveis": {
        "tempera_vital": 0..5,
        "passada_firme": 0..4,
        "fio_afiado": 0..5,
        "reserva_esquiva": 0..1,
        "canalizacao_selo": 0..4
      }
    }
    ```
  - `ler(dados: Dictionary) -> void`: lê `niveis`, valida faixas (`clamp(nivel, 0, nivel_max)`), ignora/preserva ids desconhecidos conforme política de órfãos do `Save`, e recalcula `total_gasto` deterministicamente pela Fórmula F2.
  - `campos_de_ids() -> Array`: retorna `[]` (ids ficam nas chaves de `niveis`).

### States and Transitions

| Estado | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| **Em Repouso (Campus)** | Fora de run | Permite `comprar(id)` e `resetar()`; atualiza `Save` pendente | **Aplicada em Run** (ao iniciar run) |
| **Aplicada em Run** | Início da run (`Zona Portal`) | Modificadores `meta:reforja_*` ativos no portador; compras e reset bloqueados | **Em Repouso (Campus)** (`run_encerrada`) |

### Interactions with Other Systems

| Sistema | Recebe da Oficina | Fornece à Oficina | Dono da interface |
|---|---|---|---|
| **Economia de Fragmentos (#21)** | `gastar(custo, "reforja:" + id)`, pedido de estorno no reset | `saldo()`, `saldo_mudou` | Economia de Fragmentos |
| **Modificadores e atributos (#2)** | Modificadores `meta:reforja_*` no início da run | Aplicação e recálculo de atributos | Modificadores e atributos |
| **Save e perfil (#27)** | `escrever()`, `ler(dados)`, `campos_de_ids()` (`PortaDeSecao` `[oficina]`) | Carga na inicialização e gravação em ponto seguro | Save e perfil |
| **Campus (hub) (#25)** | Dados de exibição (níveis, custos, bônus atual/próximo) | Abertura do painel, comandos de compra e reset | Campus / UI |
| **Conteúdo orientado a dados (#1)** | — | `ReforgeUpgradeDef` e `OficinaTuning` | Conteúdo |

## Formulas

**F1. Custo do próximo nível (`nivel_atual` de `0` até `nivel_max - 1`).**
$$\text{custo}(\text{id}, n) = \text{custo\_base}(\text{id}) + \text{custo\_passo}(\text{id}) \times n$$

Onde $n = \text{nivel\_atual} \in [0, \text{nivel\_max} - 1]$:

| Melhoria | `custo_base` | `custo_passo` | Custos por nível (Nv 1 → Máx) | Total da melhoria |
|---|---|---|---|---|
| **Têmpera Vital** (5) | `10` | `5` | `10, 15, 20, 25, 30` | **100** |
| **Passada Firme** (4) | `10` | `5` | `10, 15, 20, 25` | **70** |
| **Fio Afiado** (5) | `10` | `5` | `10, 15, 20, 25, 30` | **100** |
| **Reserva de Esquiva** (1) | `40` | `0` | `40` | **40** |
| **Canalização do Selo** (4) | `10` | `5` | `10, 15, 20, 25` | **70** |
| **Total Geral** | — | — | 19 níveis totais | **380 Fragmentos** |

**F2. Total gasto e valor de reembolso integral.**
Para uma melhoria no nível $L \in [0, \text{nivel\_max}]$:
$$\text{gasto}(\text{id}, L) = \sum_{n=0}^{L-1} (\text{custo\_base} + \text{custo\_passo} \times n) = L \cdot \text{custo\_base} + \text{custo\_passo} \cdot \frac{L(L - 1)}{2}$$

Exemplo: Têmpera Vital no nível 3 → $3 \times 10 + 5 \times \frac{3 \times 2}{2} = 30 + 15 = 45$ Fragmentos reembolsados.
$$\text{reembolso\_total} = \sum_{\text{id}} \text{gasto}(\text{id}, L_{\text{id}})$$

**F3. Efeito acumulado aplicado em run.**
$$\text{efeito}(\text{id}, L) = L \times \text{valor\_por\_nivel}(\text{id})$$
Exemplo: `fio_afiado` nível 5 → $5 \times 0,06 = +0,30$ (`+30%` em `dano_todo`).

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `custo_base` (melhorias graduais) | `10` | `5–25` | Curve | Permite comprar o 1º nível já após 1–2 runs iniciais (0–31 Fragmentos por run). |
| `custo_passo` (melhorias graduais) | `5` | `2–15` | Curve | Cria progressão suave sem parede abrupta; total de 380 fecha ~16–24 runs no Limiar. |
| `custo_reserva_esquiva` | `40` | `25–80` | Gate | Melhoria de nível único de alto impacto tático; exige 2–3 runs bem-sucedidas para desbloquear. |
| `permitir_reset_gratuito` | `true` | `true/false` | Gate | Mantém o reset 100% gratuito na Vertical Slice (P4); `false` reservado caso modo desafio futuro exija trava. |

## Edge Cases

- **Compra durante uma run ativa:** Bloqueada (`em_run`); a Oficina só opera no Campus/Menus.
- **Saldo exatamente igual ao custo:** Permitido; saldo final fica `0`.
- **Nível no arquivo de Save acima de `nivel_max` (edição manual ou nerf de catálogo):** `ler(dados)` faz `clamp` para `nivel_max` e recalcula `total_gasto` pela F2 para o nível válido.
- **Nível negativo ou tipo inválido no Save:** `ler(dados)` corrige entrada inválida para `0`.
- **Reset com `saldo + reembolso > saldo_max` (999 999):** Segue o teto de `Economia de Fragmentos` F1; em fluxo normal de jogo o teto nunca é atingido pela Oficina.
- **Reset quando `total_gasto == 0`:** Botão de reset fica desabilitado na UI e chamada em lógica é no-op.
- **Melhoria `cargas_esquiva` combinada com bênção de esquiva na run:** Os modificadores somam normalmente em `Modificadores e atributos`; a Oficina não impõe teto próprio além do sistema de destino.

## Dependencies

### Depends On (Upstream)
- **Economia de Fragmentos (#21)** — saldo, `gastar(custo, motivo)` e contrato de estorno/crédito de reembolso (`reembolso_oficina`). *(Nota de contrato: adicionar `reembolso_oficina` na tabela R2 de `economia-de-fragmentos.md` ou método `estornar` sem contar em `coletados_run`.)*
- **Modificadores e atributos (#2)** — aplicação das fontes `meta:reforja_*` no portador do jogador.
- **Save e perfil (#27)** — persistência da seção `[oficina]` via `PortaDeSecao` e persistência do saldo em `[economia]`.
- **Conteúdo orientado a dados (#1)** — definição de `ReforgeUpgradeDef`.

### Depended On By (Downstream)
- **Campus (hub) (#25)** — zona `zona_oficina` que abre o painel da Oficina.
- **Run e regiões (#18)** — garante aplicação de `aplicar_em_portador` ao iniciar a run.
- **Telemetria local (#35)** — pode escutar `melhoria_comprada` e `oficina_resetada` para análise de progressão.

## UI Requirements

- **Cartões/linhas das 5 melhorias:** Exibir nome, ícone, nível atual (`nv. X / Y`), barra ou marcadores de nível, efeito atual → próximo efeito (ex.: `+20 → +30 Vida Máx`), e custo do próximo nível em Fragmentos (ou `"MÁX"` quando completo).
- **Destaque de acessibilidade de compra:** Botão de compra claramente habilitado quando `saldo >= custo` e desabilitado com contraste legível quando `saldo < custo`.
- **Botão de Reset / Reembolso:** Exibe o total de Fragmentos que será devolvido (`"Reembolsar tudo (+X Fragmentos)"`), pede confirmação simples se `total_gasto > 0`, e fica desabilitado se `total_gasto == 0`.
- **Navegação unificada:** Foco por mouse, teclado e gamepad seguindo o padrão de `Tela de bênção e componente de carta`.

## Acceptance Criteria

- **AC-OR-01 [L] R1 — Catálogo inicial:** GIVEN o catálogo padrão da Vertical Slice, WHEN a Oficina é inicializada sem save, THEN existem exatamente as 5 melhorias (`tempera_vital`, `passada_firme`, `fio_afiado`, `reserva_esquiva`, `canalizacao_selo`), todas no nível `0`.
- **AC-OR-02 [L] F1 — Cálculo de custo progressivo:** GIVEN `tempera_vital` no nível `0, 1, 2, 3, 4`, WHEN consultado `custo_proximo_nivel`, THEN retorna `10, 15, 20, 25, 30` respectivamente (e `40` para `reserva_esquiva` nível `0`).
- **AC-OR-03 [I] R2 — Compra válida:** GIVEN saldo `20` e `tempera_vital` nível `0`, WHEN `comprar("tempera_vital")` é chamado, THEN o nível passa a `1`, o saldo passa a `10`, e `melhoria_comprada("tempera_vital", 1, 10)` é emitido.
- **AC-OR-04 [I] R2 — Compra com saldo insuficiente:** GIVEN saldo `9` e `tempera_vital` nível `0` (custo `10`), WHEN `comprar("tempera_vital")` é chamado, THEN a compra é recusada com `saldo_insuficiente`, o nível permanece `0` e o saldo permanece `9`.
- **AC-OR-05 [L] R2 — Compra no nível máximo:** GIVEN `reserva_esquiva` no nível `1` (`nivel_max = 1`) e saldo `100`, WHEN `comprar("reserva_esquiva")` é chamado, THEN a compra é recusada com `nivel_maximo` e o saldo permanece `100`.
- **AC-OR-06 [L] R2 — Compra bloqueada em run:** GIVEN estado `Aplicada em Run`, WHEN `comprar("fio_afiado")` é chamado, THEN a compra é recusada com `em_run`.
- **AC-OR-07 [I] R3/F2 — Reset gratuito e reembolso integral:** GIVEN `tempera_vital` nível `3` (45 gastos) e `reserva_esquiva` nível `1` (40 gastos) com saldo `15`, WHEN `resetar()` é chamado no Campus, THEN todas as melhorias voltam a `0`, o saldo passa a `100` (`15 + 85`), e `oficina_resetada(85)` é emitido.
- **AC-OR-08 [L] R3 — Reset com nada comprado:** GIVEN todas as melhorias no nível `0`, WHEN `resetar()` é chamado, THEN o saldo não muda e nenhum evento de reset é emitido.
- **AC-OR-09 [I] R4 — Aplicação de Têmpera Vital e Fio Afiado:** GIVEN `tempera_vital` nível `5` (`+50`) e `fio_afiado` nível `2` (`+12%`), WHEN `aplicar_em_portador(jogador)` roda no início da run com Lâmina (`vida_max` 100), THEN o portador recebe fontes `meta:reforja_tempera_vital` e `meta:reforja_fio_afiado`, resultando em `vida_max == 150` e `+12%` em `dano_todo`.
- **AC-OR-10 [I] R4 — Aplicação de Passada Firme e Canalização do Selo:** GIVEN `passada_firme` nível `4` (`+20%`) e `canalizacao_selo` nível `4` (`+40%`), WHEN `aplicar_em_portador(jogador)` roda, THEN `velocidade` recebe `+20%` via `meta:reforja_passada_firme` e `dano_selo` recebe `+40%` via `meta:reforja_canalizacao_selo`.
- **AC-OR-11 [I] R4 — Aplicação de Reserva de Esquiva:** GIVEN `reserva_esquiva` nível `1`, WHEN `aplicar_em_portador(jogador)` roda, THEN `cargas_esquiva` do jogador aumenta em `+1` via `meta:reforja_reserva_esquiva`.
- **AC-OR-12 [I] R4 — Persistência entre câmaras e reset pós-run:** GIVEN melhorias aplicadas no início da run, WHEN o jogador avança de câmara, THEN os modificadores `meta:reforja_*` permanecem ativos; WHEN a run termina e o Modificadores limpa a run, a próxima run reaplica os níveis atuais da Oficina.
- **AC-OR-13 [L] R5 — Serialização `PortaDeSecao`:** GIVEN `tempera_vital` nível `2` e `fio_afiado` nível `1`, WHEN `escrever()` é chamado, THEN retorna um `Dictionary` contendo apenas `int`, `String` e `Dictionary` de `int` (sem `float`), e `ler(dados)` restaura exatamente os mesmos níveis e `total_gasto == 35` (`10 + 15` de Têmpera Vital + `10` de Fio Afiado).
- **AC-OR-14 [L] R5 — Sanitização de save corrompido/acima do máximo:** GIVEN um dicionário de `ler(dados)` com `tempera_vital: 99` e `passada_firme: -3`, WHEN `ler(dados)` é executado, THEN `tempera_vital` é limitado a `5` e `passada_firme` é corrigido para `0`.
- **AC-OR-15 [L] F1 — Soma total de maximização:** GIVEN o catálogo completo da Vertical Slice, WHEN somados os custos de todos os 19 níveis das 5 melhorias, THEN o custo total para maximizar a Oficina é exatamente `380` Fragmentos.

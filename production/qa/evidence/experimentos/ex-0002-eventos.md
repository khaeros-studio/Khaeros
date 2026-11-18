# EX-0002-1..3 — canal de eventos (evidência)

- **Data**: 2026-11-16 · **Engine**: Godot 4.7.2.stable.official.ed1daf0bf (build padrão) · **Máquina**: AMD Ryzen 5 5600H (`OS.get_processor_name()`), Windows 11 10.0.26300
- **Protótipo**: `prototypes/engine-verificacao/eventos-e-aritmetica/` — `eventos/evento_do_passo.gd` (`@abstract class_name EventoDoPasso extends RefCounted`, `@abstract func tipo() -> StringName`), 3 subclasses (`EventoDano`, `EventoMorte`, `EventoEsquiva`), `probe.gd` (headless), `latencia.gd`/`.tscn` (janela).
- **Build**: binário do editor (`OS.is_debug_build()` = true), no projeto e no `.pck` exportado por `--export-pack` executado com `--main-pack`. Template de release não instalado: sem número de release.

## EX-0002-1 — custo de um `RefCounted` por evento

Por passo: cria N `EventoDano`, preenche 2 campos e faz `append` num `Array[EventoDoPasso]` novo. São 10 000 passos seguidos, medidos com `Time.get_ticks_usec`.

| N/passo | Projeto: média / p50 / p99 (µs) | `.pck`: média / p50 / p99 (µs) | vs 0,3 ms (p99) |
|---|---|---|---|
| 20 | 78,8 / 78 / **198** | 72,3 / 75 / **166** | dentro |
| 50 | 161,3 / 126 / **330** | 194,3 / 196 / **482** | **estoura** |
| 100 | 439,3 / 417 / **1 408** | 300,3 / 234 / **590** | **estoura** |

Máximos isolados de 3–18 ms aparecem em todos os casos, provavelmente por agendamento do SO. O ruído entre execuções é de ±50 %.

**Resultado: PARCIAL.** Com cerca de 20 eventos por passo, a alocação gasta até ~0,2 ms no p99, ou seja, 2/3 do orçamento de 0,3 ms do Combate, antes de qualquer regra. Com 50 ou mais, a alocação sozinha passa do orçamento, e isso no binário debug. O ADR não tem fallback escrito; a mitigação dele é "reutilizar instâncias por tipo", que a nota do especialista rejeita. Precisa de decisão: medir no template de release e/ou limitar os eventos por passo. Ver abaixo.

## EX-0002-2 — `Array[EventoDoPasso]` com subclasses `@abstract`

Saída (igual no projeto e no `.pck`): `append=9 do_tipo(dano)=3 soma_valor=9 filter+assign(morte)=3 as_errado_null=true is_typed=true`.

- `append` de 3 subclasses num `Array[EventoDoPasso]`: ok. Filtro por `tipo()` em `Array[EventoDano]` com `as`: ok. `as` para o tipo errado devolve `null`, sem erro.
- `tipo()` sobrescrito com `return` explícito: compila (regra 4.7 atendida).
- **`filter()` NÃO devolve `Array` sem tipo no 4.7.2.** Sobre um `Array[EventoDoPasso]`, `filter()` devolveu um array tipado (`is_typed()` = true), e `var t: Array[EventoDoPasso] = lista.filter(...)` **passou** sem erro em runtime.
- `@abstract`: `Script.is_abstract()` = true, mas `load("res://eventos/evento_do_passo.gd").new()` **instanciou sem erro**, e `can_instantiate()` = true. Pela documentação, o bloqueio vale para `EventoDoPasso.new()` escrito no código (análise estática). Por `Script.new()` dinâmico ele não vale.

**Resultado: VERIFICADO, com 1 afirmação do ADR REFUTADA.** A frase da linha 120 do ADR-0002 ("um `filter()` pode devolver `Array` sem tipo e a atribuição falha em tempo de execução") não se confirma no 4.7.2. `append` continua valendo como estilo, mas não é obrigatório.

## EX-0002-3 — ordem de sinais e `CONNECT_DEFERRED`

Cinco ouvintes `CONNECT_DEFERRED` foram conectados na ordem Audio, HUD, Telemetria, Telas, Feedback, de propósito diferente da ordem fixa do ADR. Também há um ouvinte síncrono. Log:

```
emit(q0) Sincrono(q0) depois_do_emit(q0) Audio(def,q0) HUD(def,q0) Telemetria(def,q0) Telas(def,q0) Feedback(def,q0)
```

- O ouvinte síncrono roda dentro do `emit`. Os deferidos rodam **depois** que a função que emitiu retorna (fila de mensagens), ainda no mesmo quadro.
- A ordem dos deferidos é a **ordem de conexão**, não uma ordem declarada. Mudar quem conecta primeiro muda a ordem de entrega.

**Resultado: CONFIRMADO.** A ordem fixa Telemetria → HUD → Feedback → Telas → Áudio só fica garantida com a lista explícita do ADR-0002. Sinais com `CONNECT_DEFERRED` não garantem essa ordem e ainda deslocam a entrega para fora do passo.

## O que o ADR-0002 precisa mudar (aplicar pelo lead-programmer)

1. VR(1): registrar a medição acima e a conclusão: com cerca de 20 eventos por passo, a alocação cabe; com 50 ou mais, estoura 0,3 ms no p99 do binário debug. Decidir entre (a) medir no template de release antes de mexer, (b) teto de eventos por passo no Combate, ou (c) rever o orçamento. Não há fallback escrito no ADR.
2. Linha 120: trocar "um `filter()` pode devolver `Array` sem tipo e a atribuição falha" por "no 4.7.2, `filter()` de um array tipado devolve array tipado (verificado); `append` fica como convenção".
3. Anotar que `@abstract` não impede `Script.new()` dinâmico. Proibir a instanciação por reflexão, ou testar que a base nunca é instanciada.
4. VR(3): confirmado, com a ordem fixa por lista mantida.

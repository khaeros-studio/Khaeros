# UX Spec: Escolha de arma e Escolha do Pacto

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `EscolhaDeArma` (modo `arma`) + `EscolhaDoPacto` (modo `maldicao`)
> **Platform Target**: PC — teclado+mouse, gamepad
> **Related GDDs**: `armas-das-doutrinas.md` R4, R8 · `vinculo-e-pactos.md` V3, V16, V16b, UI Requirements · `tela-de-bencao-e-carta.md` R3, R6, R7, R11, R14, R15-P, R15b-P
> **Related ADRs**: ADR-0012 §3, §10, §11 · ADR-0015 (`Run.Fase`) · ADR-0001 (`MENU`)
> **Related UX**: `tela-de-bencao.md` (mesmo `GrupoDeCartas`), `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`

## 1. Propósito

O jogador quer **escolher com o que vai lutar** antes da run, comparando três armas lado a lado em segundos; com a Besta, quer **decidir quem luta primeiro** entre as Maldições que já pactuou. O jogo precisa da arma (e da dupla) antes de criar a seed (V16b).

## 2–4. Contexto, posição, entrada e saída

Chega calmo, vindo do menu principal ou de "Nova run". Estado `MENU` do ADR-0001 o tempo todo.

```
Menu principal / Fim de run ("Nova run")
  └── Escolha de arma (Run ESCOLHA_DE_ARMA)
        └── [Cartão O Primeiro Vínculo, V3 — só 1ª Besta]
              └── Escolha do Pacto (Run ESCOLHA_DA_DUPLA — só ≥ 2 pactuadas)
```

| Entrada | Origem | Dados |
|---|---|---|
| "Jogar" / "Nova run" | Menu / Fim de run | `ultima_arma` (`preferencias.cfg`), perfil via `LeituraDoPerfil` |
| Esc na Escolha do Pacto | Escolha do Pacto | volta à arma, sem seed (ADR-0015) |

| Saída | Destino | Efeito |
|---|---|---|
| Confirmar Lâmina/Ressonância | Run `ATIVA` (`TRANSICAO`) | grava `ultima_arma`; seed criada |
| Confirmar Besta, 0–1 pactuada | V3 (se 0) → `ATIVA`; com 1, aviso curto na carga | `dupla_confirmada(id, "")` |
| Confirmar Besta, ≥ 2 pactuadas | Escolha do Pacto | — |
| Confirmar dupla | `ATIVA` | `ultima_dupla`, gatilho de Save "Dupla escolhida"; seed criada |
| Esc na Escolha de arma | Menu principal | nada gravado |

## 5. Layout

```
╔════════════════════ ESCOLHA DE ARMA ═════════════════════╗
║  {Lâmina}        ●{Ressonância}        {Besta do Vínculo} ║  3 cartas 320×500, fileira 1 056 px (Tela R3)
║  Vida·Velocidade  Vida·Velocidade       Vida·Velocidade   ║
║  Ataque/Especial  Ataque/Especial       Ataque/Especial   ║
║                                         [⚠ aviso_texto]   ║  posição do selo do preço (R15-P)
║        [Esc Voltar]                    [Enter Confirmar]  ║
╚═══════════════════════════════════════════════════════════╝
╔════════════════════ ESCOLHA DO PACTO ════════════════════╗
║  Slots:  [ CAMPO: Vulto Mudo ]   [ RESERVA: ●vazio ]       ║  passo atual destacado
║  {esp.1}   {esp.2 ✓Campo}   {esp.3}   {Soberano}          ║  n ≤ 4 (largura de 4, R3)
║  nome · raridade (palavra+ornamento) · nível · barra de    ║
║  vínculo · kit 3–5 linhas · memórias                       ║
║        [Esc Voltar]                    [Enter Confirmar]  ║
╚═══════════════════════════════════════════════════════════╝
```

**Foco inicial — arma (resolução da pendência #6 de `pendencias-para-design-2026-11-16.md`):** ao abrir no modo `arma`, o foco inicial vai para a carta correspondente à **última arma usada no perfil** (`ultima_arma` lida do perfil/`preferencias.cfg`: índice 0 `lamina`, 1 `ressonancia` ou 2 `pactos`, conforme `armas-das-doutrinas.md` R4); quando não há `ultima_arma` gravada ou o id não existe na fileira, o **fallback obrigatório é a 1ª carta (`lamina`, índice 0)** — vencendo a regra genérica de "carta do meio" (`floor((n-1)/2)`) do modo `bencao` (Tela R6). **Pacto:** com `ultima_dupla` válida, as duas já vêm nos slots e o foco vai a "Confirmar"; senão foco na 1ª espécie, passo "Campo".

Hierarquia: (1) nome e Doutrina pela silhueta do topo; (2) Vida e velocidade; (3) Ataque/Especial com uma linha (`_DESC`); (4) aviso da Besta. No Pacto: (1) slots Campo/Reserva; (2) nome e raridade; (3) nível e vínculo; (4) kit e memórias.

## 6. Estados

| Estado | Gatilho | Mudança |
|---|---|---|
| Entrando → Travada → Livre | abrir | entrada ≤ 0,45 s; trava 500 ms (Tela R7) |
| Besta sem Maldição | perfil sem pacto | `aviso_texto` "o Chamado não responde" (tinta, ícone de alerta, sem magenta); ainda escolhível (V3 garante 1) |
| Pacto: passo Campo / passo Reserva | 1ª / 2ª confirmação | slot ativo com anel; carta escolhida ganha selo "Campo" e fica desabilitada por forma e texto |
| Pacto: 2 pactuadas | V16 tabela | as duas já nos slots; só "Inverter ordem" e "Confirmar" |
| Erro de gravação de `preferencias.cfg` | falha I/O | segue a run; aviso discreto `OPCOES_FALHA_GRAVAR` 1× |
| Perfil corrompido | Save | aviso `PERFIL_CORROMPIDO` antes desta tela (fila do `Main`); V3 roda de novo |

## 7. Interação (mesmo modelo de foco da Tela, R6)

| Ação | Teclado | Gamepad | Mouse |
|---|---|---|---|
| Mover foco | A/D, ←/→; ↓/↑ para botões | D-pad, analógico | mover sobre a carta |
| Seleção direta | 1–3 (move o foco) | — | — |
| Confirmar | Enter/Espaço/E | A (Sul) | clique na carta em foco (1º clique fora de foco só foca) |
| Voltar / desfazer | Esc (Pacto: 1º Esc limpa a Reserva, 2º o Campo, 3º volta à arma) | B (Leste), mesma cascata | botão Voltar |
| Inverter ordem (Pacto, 2 pactuadas) | R | Y (Norte) | botão |

Sem trocar ofertas, sem preço. Não dá a volta nas bordas.

## 8–9. Dados e eventos

Lê: `DadosDaCarta` modo `arma` (montado pelo Armas: nome, Doutrina, Vida, rótulo de velocidade, Ataque/Especial, `aviso_texto`); modo `maldicao` via `LeituraDoPerfil` (nome, raridade, nível, pontos até o próximo, kit, memórias, `ultima_dupla`). Nunca lê arquivo. Escreve só por porta: `PortaDaEscolhaDeArma.escolher(i)`; `PortaDaEscolhaDeDupla.confirmar(campo, reserva)` → `dupla_confirmada` (persistente: Save).

## 10. Transições

Entrada Tela R10 (≤ 0,45 s); escolha da 1ª Maldição: carta encolhe para o slot Campo em 0,25 s; saída: fade 0,25 s para a carga. Redução de movimento: fade ≤ 300 ms e cortes secos (foco continua crescendo 106%, em corte).

## 11–12. Entrada e acessibilidade

Teclado, gamepad e mouse completos; foco preso na tela; Esc nunca sai do jogo. Desconexão do gamepad: foco mantido, glifos trocam para teclado no passo seguinte. Raridade e Doutrina por ornamento e palavra (Tela R14); "Campo"/"Reserva" por texto e posição, não cor. Alto contraste e fonte de leitura valem. Carga cognitiva: 3 cartas × 4 dados = dentro de 7±2 por carta; o Pacto divide em dois passos.

## 13. Localização

Kit em 3–5 linhas com `autowrap`; nomes longos ("Ressonância", "Besta do Vínculo") com redução até o piso de leitura. Botões de slot ≤ 12 caracteres (+40%: ALTA prioridade).

## 14. Critérios de aceite

- [ ] A tela fica interativa (fim da trava) em ≤ 950 ms após "Jogar" (0,45 s + 500 ms).
- [ ] Com `ultima_arma = ressonancia`, o foco inicial abre na carta da Ressonância (índice 1); com `ultima_arma = pactos`, na Besta do Vínculo (índice 2); sem `ultima_arma` no perfil (ou inválida), o fallback abre na 1ª carta (`lamina`, índice 0).
- [ ] Confirmar a Besta com 3 pactuadas abre a Escolha do Pacto; com 1, vai direto à carga com aviso curto e `dupla_confirmada(id, "")`.
- [ ] No Pacto, a mesma espécie não pode ocupar os dois slots; Esc desfaz Reserva, depois Campo, depois volta à arma sem seed criada.
- [ ] Com `ultima_dupla` válida, os dois slots chegam preenchidos e um Confirmar inicia a run.
- [ ] Toda a tela é concluída só com gamepad e só com teclado; o foco tem anel + escala, visível em tons de cinza.
- [ ] Besta sem Maldição mostra o aviso na faixa 76–92% da carta, sem magenta.

## 15. Open Questions

| Questão | Dono | Resolução |
|---|---|---|
| Modo `maldicao` aceito pelo Vínculo (R15b-P [a confirmar]) | game-designer | assumido nesta spec |
| Texto final do aviso da Besta | writer | provisório |

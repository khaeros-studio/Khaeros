# UX Spec: Tela de bênção

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `TelaDeBencao` (`GrupoDeCartas` modo `bencao` + `CartaView`)
> **Platform Target**: PC — teclado+mouse, gamepad
> **Related GDDs**: `tela-de-bencao-e-carta.md` (R1–R16, F1–F5, Edge Cases, AC-TB-*) · `bencaos-tradicoes.md` R3, R5, R11 · `hud.md` R3, R12
> **Related ADRs**: ADR-0012 §5, §6, §11 · ADR-0001 (`BENCAO`)
> **Related UX**: `hud.md`, `pausa-e-opcoes.md`, `tela-consentimento-do-pacto.md` (mesmo estado), `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`

## 1. Propósito

Depois de limpar a câmara, o jogador quer **ler as ofertas e pegar a que muda a run, sabendo o preço**. A tela não tem pressa (P4) e o preço é sempre o último tempo (P2). O jogo precisa de exatamente um `escolher(i)` ou `trocar()`.

## 2–4. Contexto, entrada e saída

Chega aliviado, ainda com adrenalina; dedo no botão de ataque (risco de escolha acidental, Tela R7). Enviado pelo jogo, não voluntário.

| Entrada | Origem | Dados |
|---|---|---|
| `oferta_aberta(cartas, trocas)` | Bênçãos, câmara limpa (`JOGO` → `BENCAO`) | `CartaView[]` (n 1–3), `trocas` |
| Continuar da pausa | `PAUSA` → `BENCAO` | mesma oferta; trava 300 ms |

| Saída | Destino | Efeito |
|---|---|---|
| Confirmar carta | `tela_fechada` → `JOGO` (portas abrem) ou fim de run em vitória | bênção aplicada no quadro do aperto (irreversível) |
| Esc / Start | Pausa por cima (sem "Abandonar run") | nada; oferta preservada |

Não há saída sem escolher (R12). Modal; não dispensável.

## 5. Layout

```
╔════════════════ (mundo congelado em gravura, insígnia da Doutrina ao fundo) ═══════════════╗
║   ┌Coroa Doutrina┐   ┌──────────────┐●  ┌──────────────┐                                    ║
║   │ Nome         │   │ Nome  (106%) │   │ Nome         │   3 cartas 320×500, 48 px (R3, R4) ║
║   │ {vinheta}    │   │ {vinheta}    │   │ {vinheta}    │                                    ║
║   │ ganho +N     │   │ ganho +N     │   │ ganho +N     │                                    ║
║   │ [selo preço] │   │ [ vazio ]    │   │ [ vazio ]    │   preço sempre na mesma altura     ║
║   │ COMUM        │   │ RARA         │   │ ÉPICA        │                                    ║
║   └──────────────┘   └──────────────┘   └──────────────┘                                    ║
║                       [↻ Trocar ofertas · 0]  (riscado se 0)                                ║
║ grupo do HUD visível (R12)                                               Fragmentos visíveis║
╚═════════════════════════════════════════════════════════════════════════════════════════════╝
```

Foco inicial: carta do meio (`floor((n−1)/2)`). Hierarquia: ganho → preço → raridade → nome/Doutrina.

## 6. Estados

Os 8 da máquina do GDD (Fechada, Entrando, Travada, Livre, Trocando, Confirmando, Saindo, Pausada). Extras de UX:

| Estado | Gatilho | Mudança |
|---|---|---|
| Troca desabilitada | `trocas = 0` | botão riscado + "0"; R/Y e Confirmar nele só tremem 80 ms |
| n = 1 ou 2 | pool pequeno | cartas centralizadas; teclas acima de n não fazem nada |
| Sem preço | `preco_texto` nulo | placa vira vazio de osso; `preco_revelado` no fim do ganho |
| Aperto dentro da trava | < 500 ms do assentar / < 300 ms de troca ou pausa | descartado, sem feedback de confirmação (o foco ainda move) |
| Perda de foco da janela | SO | só limpa entradas (ADR-0012 §4) |

## 7. Interação

Tabela completa em Tela R6 (A/D ←/→, 1–3, Enter/Espaço/E, R/Y, ↓/↑ ao botão, Esc/Start). Regras-chave: clique só confirma a carta já em foco; mouse parado não rouba foco; troca vence confirmar no mesmo passo **com cargas**; sem cargas o confirmar vale (ADR-0012 §11). Pular a animação só depois de `preco_revelado`.

## 8–9. Dados e eventos

Lê só `DadosDaCarta` (ADR-0012 §11) e `trocas`. Chama `PortaDaBencao.escolher(i)` (persistente na run), `trocar()`, `notificar_tela_fechada()`; emite `preco_revelado` (HUD libera o rachar da Vida) e `tela_fechada` (HUD reexibe fios e prompt; Input volta a Jogo).

## 10. Transições

Entrada ≤ 0,45 s, legível em 500 ms (R10); troca ≤ 0,3 s; confirmação ≤ 0,6 s (ganho → traço dourado ao HUD → rachadura magenta do preço → recusadas viram mancha). Redução de movimento: fade ≤ 300 ms; foco cresce em corte seco. Reduzir flashes: traço e rachadura sem flash.

## 11–12. Entrada e acessibilidade

Teclado, gamepad, mouse completos; foco preso; Esc abre pausa (nunca pula). Hit target = carta inteira (320 × 500). Clique direito: nada. Desconexão de gamepad: oferta mantida, nenhuma escolha implícita. Raridade por ornamento + palavra; Doutrina pela silhueta; preço por forma partida + posição fixa, não só magenta; foco com 2 sinais além da cor (R11). Alto contraste e fonte de leitura (R14). Carga: 3 cartas × (ganho, preço, raridade) = 9 itens; mitigado pela anatomia fixa (o olho sabe onde está cada coisa).

## 13. Localização

`texto` do ganho em 52–76% com `autowrap` e redução até o piso; `preco_texto` por `tr(chave).format({valor})`. Nome da Tradição em uma linha de H2: ALTA prioridade para +40%.

## 14. Critérios de aceite

- [ ] As três cartas estão legíveis em ≤ 500 ms após `oferta_aberta`.
- [ ] Segurar Ataque durante a abertura e soltar não escolhe nada; Enter a 400 ms do assentar é descartado, a 600 ms confirma.
- [ ] Com `trocas = 0`, R/Y fazem o botão tremer e nada mais; Confirmar + R no mesmo passo escolhe a carta em foco.
- [ ] Em "O Preço com Nome", a animação de rachar a Vida do HUD só começa no quadro de `preco_revelado`; o número já mostra o valor novo antes.
- [ ] Esc abre a pausa com "Abandonar run" desabilitado por forma e texto; Continuar devolve a mesma oferta com o mesmo foco.
- [ ] Em tons de cinza, Comum/Rara/Épica e "tem preço"/"sem preço" continuam distinguíveis.
- [ ] Mouse parado sobre a carta 0 ao abrir: o foco fica na carta do meio; o primeiro clique na carta 0 só a foca.

## 15. Open Questions

Nenhuma nova; pendências do GDD (OQ da Tela) seguem lá.

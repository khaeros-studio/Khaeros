# Tela de bênção e componente de carta

> **Status**: Approved (2026-11-11; revisão única por subagente: 9 bloqueantes e 13 recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P1 *Toda bênção é uma filosofia*; P2 *A Beira cobra*; P3; P4

## Summary

A **Tela de bênção** é onde a oferta da Bênçãos vira escolha: de **1 a 5 cartas** na ordem do
sorteio, o botão de troca e a confirmação. O **componente de carta** é a unidade visual
(Doutrina, nome, vinheta, ganho, preço, raridade, foco) e vale para qualquer tela que
ofereça escolhas (Escolha de arma e Oficina o consomem nos GDDs delas). Só **lê** a oferta
e **devolve** a escolha ou a troca.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Bênçãos (Tradições), Input e controle, Pipeline visual, Modificadores e atributos`

## Overview

> `ux-designer` não consultado nesta seção: modo Lean.

A tela existe para o momento em que o jogador **aceita uma filosofia e o preço dela**:
o mundo congela, as cartas assentam e o jogador navega, compara e confirma, sem
cronômetro e sem poder escolher por engano. Ela **não** sorteia (Bênçãos), **não** aplica
o efeito (Modificadores) e **não** decide o que vem depois da escolha (Portas).

- **Entrada:** `oferta_aberta(cartas, trocas)` da Bênçãos. O mundo para (Pipeline R2;
  Input no contexto Bênção). As cartas descem e assentam em ≤ 0,45 s.
- **Componente de carta** (Art Bible §7.5): coroa da Doutrina, nome, vinheta, ganho (com "atual → novo" reservado), selo do preço (só o custo real da bênção, hoje O
  Preço com Nome), rodapé de raridade. Ordem das cartas = ordem do sorteio.
- **Navegação:** um modelo de foco só (mouse, teclado e gamepad); foco inicial na carta do
  meio; **confirmar só vale 500 ms depois de a última carta assentar** e só com botão
  apertado depois de a tela abrir; trava de 300 ms depois de trocar.
- **Troca:** "↻ Trocar ofertas" com o número de cargas (base 0 no MVP: botão
  desabilitado por forma, ícone riscado e "0").
- **Saída:** `escolher(carta)` ou `trocar()` para a Bênçãos; a tela se desfaz em ≤ 0,6 s
  (ganho, depois preço) e o jogo segue.
- **Do MVP:** sem Mestre (retrato e fala são da fatia vertical); insígnia da Doutrina em
  silhueta ao fundo.

A **fantasia** é a de olhar três (ou cinco) leituras do mundo lado a lado e sentir o
peso de escolher uma: a Beira cobra por último, no selo que racha depois do ganho.

As regras seguem a Art Bible §7.5 a §7.7 e o contrato da Bênçãos (R3, R5, R6, R10, UI
Requirements), com as decisões do usuário de 2026-11-11: componente genérico com a tela
de bênção sem Mestre, de 1 a 5 cartas com escala proporcional, só o custo real da bênção
no selo do preço.

> **→ vira ADR:** não. A tela é uma cena que escuta `oferta_aberta` e chama `escolher` e
> `trocar`; não guarda estado de jogo.

## Detailed Design

### Core Rules

**R1. Só lê e devolve.** A tela recebe a oferta da Bênçãos, desenha, e devolve **uma** de
duas ações: `escolher(índice)` ou `trocar()`. Não sorteia, não aplica efeito, não abre
portas, não guarda estado de jogo. O relógio da tela é o **tempo de interface** (o mundo
está parado, Bênçãos R11), não os passos da simulação.

**R2. Dados da carta (`CartaView`).** **Quem monta** é a Bênçãos, a partir do `BoonDef`
(Conteúdo) e da raridade sorteada; a Tela só desenha. Campos: `id`, `nome`, `doutrina` (token
do Conteúdo), `raridade` (`comum`, `rara`, `epica`), `glifo` (vinheta da Tradição, 96 px),
`icone_ganho`, `texto` (já com o número da raridade, Bênçãos R10), `melhoria` (opcional:
"atual → novo"; **reservado**, Tradições não evoluem, Bênçãos R2) e `preco_texto`. O
`preco_texto` **deriva dos `efeitos[]` marcados como custo** (valor negativo com
`escala_com_raridade` falso, Modificadores) e vem de uma **chave de texto com marcador
`{valor}`** (nunca número literal, Conteúdo V10); é nulo se a bênção não tem custo (no MVP só
**O Preço com Nome**, nome do cânone). Nota de edição pendente no Conteúdo (`BoonDef` ganha
`glifo`, `icone_ganho` e a chave do preço) e na Bênçãos (entrega `CartaView`).

**R3. Layout.** Cartas de 320 × 500 px a 100% (Art Bible §7.5), 48 px de intervalo, em
**uma fileira centralizada**, da esquerda para a direita **na ordem do sorteio** (carta 0 à
esquerda). Largura da fileira = `n × 320 + (n − 1) × 48`: 1 carta 320; 2: 688; 3: 1 056
(a Art Bible diz ~1 060); 4: 1 424; 5: 1 792 px. **4 e 5 cartas são reservadas:** Bênçãos R3/R4 fixam `min(3, pool)` e 3 reais por oferta, então no MVP `n` ≤ 3; as larguras de 4 e 5 ficam como reserva para quando a Bênçãos mudar. **Escala das cartas** `s = min(escala_ui,
1824 / largura_da_fileira)` (1824 = 1920 − 2 × 48 de margem): a 100% todas de 1 a 5
cabem em `s` = 1; com UI 125%/150% três cartas crescem (1,25/1,5), quatro e cinco ficam em
no máximo 1,28 e 1,018. Com UI 85%, `s` = 0,85 (escolha do jogador). O botão de troca
fica abaixo das cartas, centralizado.

**R4. Anatomia da carta** (Art Bible §7.5, de cima para baixo, em % da altura):
1. **Coroa da Doutrina** (0–14%): silhueta do topo com a forma da Doutrina e a insígnia a
   48 px em tinta; **o topo é exclusivo da Doutrina** (nenhum ornamento de raridade).
2. **Nome da Tradição** (14–24%): H2, versaletes, tinta sobre osso.
3. **Vinheta** (24–52%): glifo da Tradição a 96 px, em tinta, sem cor.
4. **Ganho** (52–76%): ícone de 32 px em dourado **com contorno de tinta ≥ 2 px**, texto do
   efeito em tinta, número em tinta Bold 28 px; o dourado fica **só no ícone**.
5. **Selo do preço** (76–92%): placa de tinta chanfrada com forma partida em magenta e o
   `preco_texto` em magenta Bold ≥ 24 px; **posição fixa em todas as cartas**; sem custo,
   a placa vira vazio de osso e a altura não muda.
6. **Rodapé de raridade** (92–100%): "Comum", "Rara" ou "Épica" por extenso, ≥ 20 px em
   versalete; o ornamento corre pelas laterais, cantos e rodapé: **simples**, **dupla**
   (linhas com ≥ 4 px de intervalo) ou **recortada com respingo**.
Fundo de osso chapado (grão ≤ 5% só nas margens), contorno de tinta de 3 px, margem
interna ≥ 16 px sem ornamento.

**R5. A tela em volta.** O mundo congelado em gravura (Art Bible §2.6; Pipeline). No MVP,
**sem Mestre**: no fundo, a **insígnia em silhueta da Doutrina da arma da run**; sem
retrato nem fala. O HUD segue as regras do HUD R12 (grupo inferior e Fragmentos visíveis).
Sem lista de bênçãos já tomadas (fica na pausa).

**R6. Foco e navegação.** Um modelo de foco só (mouse, teclado, gamepad), com as teclas
da Art Bible §7.6:

| Ação | Teclado | Gamepad | Mouse |
|---|---|---|---|
| Mover o foco | A/D, ←/→ | D-pad, analógico esquerdo | passar o mouse |
| Seleção direta | 1 a 3 (`ui_carta_1..3` do Input, Art Bible §7.6; move o foco, não confirma) | — | — |
| Confirmar | Enter / Espaço / E | A (Sul) | clique |
| Trocar ofertas | R | Y (Norte) | clique no botão |
| Pausa | Esc | Start | — |
| Foco para o botão e de volta | ↓ / ↑ | D-pad ↓ / ↑ | passar o mouse |

O foco inicial é a **carta do meio** (índice `floor((n − 1) / 2)`: n 1 → 0, 2 → 0, 3 → 1, 4
→ 1, 5 → 2); **não dá a volta** entre a última e a primeira. Confirmar com o foco no botão
de troca troca. Os botões são os do Input, remapeáveis (Input). **Mouse:** passar o ponteiro move o foco quando o ponteiro **se move** sobre uma carta; o clique **só confirma a carta que já está em foco**: um clique sobre uma carta fora de foco (por exemplo com o mouse parado desde a abertura) apenas move o foco para ela, e o segundo clique confirma.

**R7. Trava contra escolha acidental.** Ao abrir a tela o **buffer de entrada é
esvaziado**; o foco se move desde o 1º quadro. **Confirmar e trocar** só valem `trava_confirmar_ms`
(500 ms) **depois de a última carta assentar**, e só se o botão foi apertado (borda de
subida) **depois** de a tela abrir: botão já segurado não conta. Depois de **trocar**, a
mesma trava de `trava_troca_ms` (300 ms) vale para confirmar e trocar. Ao voltar da
**pausa**, o buffer é esvaziado e vale a trava de 300 ms. Apertos dentro da trava são
**descartados**, não guardados.

**R8. Troca.** Com `trocas ≥ 1` o botão fica ativo ("↻ Trocar ofertas" com o número de
cargas); trocar chama `trocar()`, a Bênçãos gasta 1 e devolve `oferta_trocada(cartas, trocas)` (mesmo payload de `oferta_aberta`; nota de edição na Bênçãos) com as novas
cartas (animação ≤ 0,3 s, `trava_troca_ms`); o foco volta à carta inicial. Com
`trocas = 0` (base do MVP) o botão fica **desabilitado por forma** (ícone riscado e "0") e
apertar R/Y só faz o botão tremer 80 ms. Troca e confirmar no mesmo quadro, **com cargas**: **a troca vence**
(Bênçãos R5). **Sem cargas, a troca não existe**: R/Y são ignorados e um confirmar no mesmo quadro **vale**. O foco chega ao botão desabilitado; Confirmar nele não faz nada (só o tremor).

**R9. Confirmação.** `escolher(i)` é enviado à Bênçãos **no quadro do aperto** (a tela não
espera a animação; a Bênçãos aplica o efeito e emite `bencao_tomada`). Depois, em ≤
`anim_confirmar_s` (0,6 s): os raios do **ganho** se abrem e um traço dourado voa para o
**grupo inferior do HUD** (Vida); em seguida uma **rachadura magenta** atravessa o selo do
preço em 2 quadros, com 80 ms de pausa (**só se a carta tem preço**); as cartas recusadas se
desfazem em mancha de tinta. O preço é sempre o último tempo (P2): a Tela emite
**`preco_revelado`** no momento da rachadura (ou no fim do ganho, se não há preço) e o **HUD
segura a animação da Vida causada pela bênção até esse sinal** (o número de Vida já é o
novo, só a animação espera; nota de edição pendente no HUD). **Pular:** apertar confirmar de
novo só pula **depois** de `preco_revelado`. Ao terminar, a tela emite **`tela_fechada`**
(Tela → Bênçãos): a Bênçãos **segura `bencao_escolhida`** até recebê-lo, e é só então que as
Portas abrem as portas, a Run pode encerrar com vitória, o Pipeline sai de `modo_bencao` e o
Input volta ao contexto Jogo (nota de edição pendente na Bênçãos R5/R11).

**R10. Entrada e saída.** A entrada: o mundo congela em ~0,25 s (**em paralelo** com a descida das cartas, dentro do total); o contorno de cada carta se
traça em 2–3 quadros, o osso preenche, as cartas descem ~20 px e assentam com 60–80 ms de
defasagem entre elas; **total ≤ 0,45 s**, três cartas legíveis até 500 ms; sem efeito
máquina de escrever. Interpolação suave sem elástico a 60 qps; a tinta anima "em dois"
(~12 qps).

**R11. Foco visível** (≥ 2 sinais além da cor): anel dourado de ≥ 4 px **fora da carta**,
com uma linha de tinta entre o anel e a carta; a carta em foco **cresce para 106%** e sobe
~12 px; as outras caem para ~70% de valor. Depois que assenta, a carta fica parada.

**R12. Sem cronômetro, sem pular.** Não há tempo limite (P4) e a oferta **não pode ser
pulada** (Bênçãos R5). Esc/Start abre a pausa **por cima** da tela de bênção e nunca pula a
escolha.

**R13. Casos de n.** Com `n` = 1 ou 2 (pool pequeno, Bênçãos R3) as cartas ficam
centralizadas com o mesmo tamanho; a seleção direta cobre só 1 a `n` (e no máximo 3). As teclas 1 a 3 acima de `n`
não fazem nada; com 4 ou 5 cartas (reservado) a 4ª e a 5ª só pelo foco (A/D). `n` = 0 não abre tela (Bênçãos emite `sem_bencao`).

**R14. Acessibilidade.** A raridade é lida por **ornamento e palavra**, nunca só por cor; a
Doutrina, pela silhueta do topo. Alto contraste (Art Bible §7.9 nº 10): painéis 100%,
molduras de 3 px, raridade por contagem de linhas e palavra, texto osso puro sobre tinta pura.
Redução de movimento: a entrada vira *fade* ≤ 300 ms; o crescimento do foco **continua**
(é informação), em corte seco. "Reduzir flashes": o traço dourado e a rachadura saem sem
flash. Fonte de leitura (opção 12) e escala de UI valem; em 1280 × 720 tudo escala com a
tela e as fileiras de 1 a 5 cartas cabem pela mesma conta (R3), sem quebrar em duas. Remapeamento completo.
Todos os menus usáveis sem mouse.

**R15. Componente reutilizável.** `CartaView` + `GrupoDeCartas` (foco, trava, entrada)
servem a qualquer tela de escolha; o **modo** define o topo: **bênção** e **arma** (topo da
Doutrina) e **melhoria** (topo reto neutro, Oficina; grade com ordem de foco fixa, comprado
× caro demais por forma e texto). **No MVP só o modo bênção é implementado**; arma e
melhoria ficam como interface para a Run (tela de início) e a Oficina.

**R16. Injeção.** Recebe as cartas por interface (`CartaView[]`, trocas) e chama
`escolher`/`trocar` por um objeto injetado; o relógio é injetável. Os testes montam tudo em
memória, sem Bênçãos real.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Fechada | início, ou depois de Saindo | Entrando (`oferta_aberta`) |
| Entrando (≤ 0,45 s) | `oferta_aberta` | Travada |
| Travada (até 500 ms depois de assentar; 300 ms depois de trocar ou da pausa) | assentou, trocou ou voltou da pausa | Livre |
| Livre | trava acabou | Trocando (`trocar`), Confirmando (`escolher`) |
| Trocando (≤ 0,3 s) | troca aceita | Travada (cartas novas) |
| Confirmando (≤ 0,6 s) | `escolher(i)` | Saindo |
| Saindo | animação acabou (emite `tela_fechada`) | Fechada |
| Pausada (por cima, de Entrando a Saindo) | Esc / Start | o estado de antes, com a trava de F3; foco e mouse são ignorados enquanto Trocando, Confirmando e Saindo |

Pausa pode abrir em qualquer estado menos Fechada; ao voltar vale a trava de 300 ms (R7).

### Interactions with Other Systems

| Sistema | Fornece à tela | Recebe da tela | Dono da interface |
|---|---|---|---|
| Bênçãos (Tradições) | `oferta_aberta(cartas, trocas)`, `oferta_trocada(cartas, trocas)`, `CartaView[]` montadas | `escolher(i)`, `trocar()`, `preco_revelado`, `tela_fechada` | Bênçãos |
| Input e controle | botões remapeáveis, contexto Bênção, esvaziar buffer | — | Input |
| Pipeline visual | mundo congelado em gravura, fontes, camada de UI | — | Pipeline |
| HUD | — | `preco_revelado` (libera a animação de Vida); o traço dourado voa ao grupo inferior; HUD R12 | HUD |
| Conteúdo orientado a dados | `BoonDef` (nome, Doutrina, ícone), `TelaBencaoTuning` | — | Conteúdo |
| Run e regiões | Doutrina da arma (insígnia de fundo) | — | Run |
| Áudio, Telemetria | — | `oferta_aberta`, `oferta_trocada`, `bencao_tomada`, `bencao_escolhida` (da Bênçãos) | apresentação |
| Modificadores e atributos | nunca fala direto: a Bênçãos intermedia | — | — |

## Formulas

**F1. Fileira e escala.** `largura(n) = n × 320 + (n − 1) × 48` px a 100%; `s = min(escala_ui,
1824 / largura(n))`; largura final = `largura(n) × s`; altura da carta = `500 × s`. Ex.: n 3, UI
100% → 1 056 px, s = 1; n 3, UI 150% → s = 1,5, 1 584 px; n 5, UI 100% → 1 792 px, s = 1; n 5,
UI 150% → s = min(1,5; 1,018) = 1,018, 1 824 px, altura 509 px; n 3, UI 85% → s = 0,85, 898 px.
Altura total no pior caso (UI 150%, n 3): 750 + 24 + botão 64 = 838 px ≤ 984 (1080 − 2 × 48).

**F2. Foco inicial.** `i0 = floor((n − 1) / 2)` (n 1 → 0; 2 → 0; 3 → 1; 4 → 1; 5 → 2).

**F3. Trava de confirmação.** `t_assentou` = o **fim real da entrada** (`t_abrir + entrada_s`, ou o fim do fade com redução de movimento). Confirmar vale em `t ≥ t_assentou + trava_confirmar_ms` **e** se o botão subiu
(borda de subida) em `t_aperto > t_abrir`. Ex.: abre em 0 s, entrada 0,45 s → confirmar vale
a partir de 0,95 s. **Depois de trocar:** `t_novas = t_troca + anim_troca_s` (as novas cartas
assentam) e confirmar ou trocar valem a partir de `t_novas + trava_troca_ms`: troca em
2,0 s → vale a partir de 2,6 s. **Depois da pausa:** vale a partir de `max(fim da trava em curso, t_volta + trava_troca_ms)`; com a pausa aberta durante Entrando ou Trocando, a trava de 500 ms (ou 300 ms) depois de assentar continua valendo se terminar depois. Ex.: pausa em 0,2 s, volta em 5,0 s: o fim da entrada (0,45 + 0,5 = 0,95 s) já passou, então vale a partir de 5,3 s; pausa em 0,2 s e volta em 0,5 s: vale a partir de 0,95 s.

**F4. Tempo de uma escolha, melhor caso.** Entrada 0,45 s + trava 0,5 s = **0,95 s** até o primeiro
confirmar válido (≈ 1 s de leitura forçada); confirmação 0,6 s. Sem troca nem pausa, do
`oferta_aberta` ao mundo de volta: ≥ 1,55 s.

**F5. Foco.** Carta em foco: escala `s × foco_escala` (1,06) e sobe `foco_sobe_px × s` (12 px);
as outras: valor × `valor_nao_focada` (0,7). Anel dourado de 4 px × s, com a linha de tinta de
2 px entre o anel e a carta. Ex. (s = 1): a carta de 320 × 500 vira 339,2 × 530 e sobe 12 px.

## Tuning Knobs

`TelaBencaoTuning` (tipo no Conteúdo, dono: Tela de bênção; edição aplicada):

| Knob | Padrão | Faixa | Categoria | Efeito |
|---|---|---|---|---|
| `trava_confirmar_ms` | 500 | 500–800 | gate | espera depois de a última carta assentar; abaixo de 500 exige emenda da Art Bible (decisão do CD) |
| `trava_troca_ms` | 300 | 200–500 | gate | trava depois de trocar ou voltar da pausa |
| `entrada_s` | 0,45 | 0,3–0,45 | feel | duração da entrada (Art Bible ≤ 0,45) |
| `anim_troca_s` | 0,3 | 0,15–0,4 | feel | duração da troca |
| `anim_confirmar_s` | 0,6 | 0,3–0,6 | feel | duração da confirmação (Art Bible ≤ 0,6) |
| `foco_escala` | 1,06 | 1,03–1,10 | feel | crescimento da carta em foco |
| `foco_sobe_px` | 12 | 6–16 | feel | quanto a carta em foco sobe |
| `valor_nao_focada` | 0,7 | 0,6–0,8 | feel | valor das cartas sem foco |
| `intervalo_cartas_px` | 48 | 32–64 | feel | intervalo entre cartas |
| `tremor_botao_ms` | 80 | 0–200 | feel | tremor do botão de troca desabilitado |

**Códigos de validação (decisão 2026-11-13; prefixo TB, hospedado na R9 do Conteúdo).** Um erro por campo de `TelaBencaoTuning` fora da faixa da tabela acima, na ordem da tabela: TB1 `trava_confirmar_ms`, TB2 `trava_troca_ms`, TB3 `entrada_s`, TB4 `anim_troca_s`, TB5 `anim_confirmar_s`, TB6 `foco_escala`, TB7 `foco_sobe_px`, TB8 `valor_nao_focada`, TB9 `intervalo_cartas_px`, TB10 `tremor_botao_ms`. Texto: `TelaBencaoTuning: <campo> <valor> fora da faixa <min>–<max>`.

Constantes fixas pela Art Bible (mudar exige emenda dela): carta 320 × 500, margem de 48 px,
contorno de 3 px, anel de 4 px, porcentagens das zonas da carta.

## Edge Cases

- **Oferta com 1 ou 2 cartas (pool pequeno):** centralizadas, mesmo tamanho (R13); foco
  inicial F2; teclas acima de `n` não fazem nada.
- **`oferta_trocada` com `n` diferente do anterior:** impossível dentro da mesma oferta
  (o pool só cresce com a troca, Bênçãos R6); se acontecer, a fileira recalcula (F1) e o foco
  volta a F2.
- **Cartas repetidas depois da troca:** permitido (Bênçãos R6); a tela não compara.
- **Botão apertado desde antes da abertura:** não conta (R7); precisa soltar e apertar de novo.
- **Dois confirmar no mesmo quadro:** vale o do foco atual; o segundo é descartado.
- **Confirmar e trocar no mesmo quadro:** a troca vence (Bênçãos R5).
- **Mouse parado sobre uma carta ao abrir:** o foco vai à carta inicial (F2), não à do mouse,
  até o mouse **se mover** (e o clique segue a regra da R6).
- **Clique durante a trava:** descartado (R7), sem sacudir nada.
- **Pausa durante a entrada, a confirmação ou a troca:** a animação **pausa** e retoma; ao
  voltar vale a trava de 300 ms (F3). A pausa durante Confirmando não desfaz a escolha (já
  foi enviada, R9).
- **Esc na trava:** abre a pausa normalmente. **Perder o foco da janela** na Bênção **não** pausa (Input), a tela fica como está.
- **Mouse parado sobre uma carta ao abrir e clique sem mover:** só move o foco para a carta clicada; o segundo clique confirma (R6).
- **Troca com `trocas` = 0:** o botão só treme (R8); R/Y e clique não chamam `trocar()`.
- **Troca com `trocas` ≥ 1 e foco no botão:** Confirmar troca; o foco volta à carta F2 depois.
- **Dispositivo muda no meio (mouse ↔ gamepad):** os glifos trocam no quadro seguinte; o foco
  fica onde está.
- **Resolução diferente de 1920 × 1080:** tudo escala com a tela (F1 vale proporcionalmente).
- **`preco_texto` muito longo:** quebra em até 2 linhas na placa (altura fixa); acima disso, o
  texto reduz até 24 px e, se ainda não couber, corta com reticências e o texto completo vai
  para a descrição (provisório, OQ 4).
- **`texto` do ganho muito longo:** zona do ganho com altura fixa (24% da carta); reduz até o
  piso de legibilidade e, depois, corta com reticências (validação do Conteúdo, OQ 5).
- **Redução de movimento ligada:** a entrada vira fade ≤ 300 ms e a confirmação, corte
  seco, mas as **travas e o foco** (106%) continuam iguais.
- **Alto contraste e Fonte de leitura alternativa juntos:** valem os dois (R14).
- **Vitória logo depois da escolha (Run R4):** a Run só encerra depois de `tela_fechada` (a Bênçãos segura `bencao_escolhida`, R9); sem portas.
- **`oferta_aberta` com a tela ainda Saindo da oferta anterior:** impossível (a Bênçãos recusa
  com `oferta_ja_aberta` até a escolha, R3); a nova entrada só começa em Fechada.

## Dependencies

| Sistema | Direção | Natureza | Interface |
|---|---|---|---|
| Bênçãos (Tradições) | entra e sai | por contrato | `oferta_aberta(cartas, trocas)`, `oferta_trocada`; devolve `escolher(i)`, `trocar()` |
| Input e controle | entra | rígida | botões remapeáveis, contexto Bênção, esvaziar o buffer, borda de subida do botão |
| Pipeline visual | entra | rígida | mundo congelado em gravura, camada de UI, fontes, orçamento de draw calls |
| Conteúdo orientado a dados | entra | rígida | `BoonDef` (nome, Doutrina, ícone, glifo, `icone_ganho`, chave de texto do preço com `{valor}`), `TelaBencaoTuning` (10 campos; já registrado no Conteúdo R1) |
| Portas e recompensas | — | independente | a Tela não fala com as Portas; fala com a Bênçãos (as Portas esperam o fim da escolha pela Bênçãos/Run) |
| Run e regiões | entra | leitura | Doutrina da arma (insígnia de fundo); estado de jogo |
| HUD | sai e paralelo | leitura | o HUD segue visível em parte (HUD R12), recebe o traço dourado e os sinais `preco_revelado` e `tela_fechada` |
| Áudio / Telemetria | sai | leitura | eventos da Bênçãos; a tela emite `preco_revelado` e `tela_fechada` |
| Escolha de arma (tela de início, Run OQ 4) | sai | reservada | `CartaView` modo arma |
| Oficina de Reforja (fatia vertical) | sai | reservada | `CartaView` modo melhoria, grade |

Nenhum sistema depende da tela para **rodar**: a Bênçãos funciona com um dublê que escolhe.

## Visual/Audio Requirements

- **Carta:** osso chapado, tinta, dourado só no ícone do ganho, magenta só no selo do preço;
  ornamento de raridade só nas laterais, cantos e rodapé (Art Bible §7.5); topo exclusivo da
  Doutrina.
- **Entrada:** contorno traçado em 2–3 quadros, osso preenche, as cartas descem ~20 px e
  assentam com 60–80 ms de defasagem; som seco de papel/osso, um por carta (audio-director).
- **Foco:** anel dourado de 4 px com linha de tinta; sem pulsar em loop.
- **Confirmação:** raios do ganho, traço dourado para o HUD, rachadura magenta no preço por
  último, cartas recusadas em mancha de tinta; sons: ganho, depois a rachadura (P2).
- **Troca:** as cartas se desfazem e as novas assentam em ≤ 0,3 s.
- **Botão de troca desabilitado:** ícone riscado e "0"; tremor de 80 ms ao apertar.
- **Fundo:** mundo congelado em gravura e insígnia da Doutrina da arma em silhueta.

## Game Feel

- **Navegar já, confirmar depois:** o foco responde desde o 1º quadro; a confirmação só depois
  de 500 ms (F3). O jogador pode ler e comparar sem medo.
- **Sem cronômetro** (P4) e sem pular a escolha.
- **Preço por último:** o selo racha só depois do ganho (P2).
- **Latência:** o foco e o `escolher` respondem no mesmo quadro do aperto (≤ 16,7 ms).
- **Fotossensibilidade:** nada pisca; o traço dourado e a rachadura respeitam o limitador de
  3 flashes/s e a opção "Reduzir flashes".

## UI Requirements

- Esta tela **é** a UI: sem HUD próprio além do que o HUD já mostra.
- Cartas de 1 a 5 com a escala da F1; botão "↻ Trocar ofertas" abaixo, com cargas.
- Spec de UX (`design/ux/tela-de-bencao.md`) feita com `/ux-design` antes das epics; o
  componente `CartaView` ganha uma biblioteca de padrões (`design/ux/interaction-patterns.md`).
- Teste das **18 combinações** da Art Bible §7.5 (6 Doutrinas × 3 raridades, em cinza e a 50%):
  5 avaliadores acertam Doutrina e raridade em ≥ 90% (QA visual, fora dos ACs automáticos).

> **📌 UX Flag — Tela de bênção e carta:** na Pré-Produção, rodar `/ux-design` para esta tela
> e para o componente de carta antes das epics.

## Cross-References

- Art Bible §2.6, §7.5, §7.6, §7.7, §7.9; Bênçãos R3, R5, R6, R10, R11 e UI Requirements;
  Input (contexto Bênção); HUD R12; Pipeline R2.
- Índice: linha 29.

## Acceptance Criteria

Tipos: [L] lógica (unitário, relógio e Bênçãos falsos), [I] integração, [V] visual (screenshot
em `production/qa/evidence/`).

- **AC-TB-01 [L] F1 — fileira.** `largura(n)` = 320, 688, 1 056, 1 424, 1 792 para n = 1..5.
- **AC-TB-02 [L] F1 — escala.** UI 100%: s = 1 para n 1..3 (e, reservado, 4 e 5); UI 150%: n 3 → 1,5; (reservado) n 5 → 1,018 (1 824 px); UI 85%, n 3 → 0,85.
- **AC-TB-03 [L] R3 — ordem.** As cartas aparecem na ordem recebida (carta 0 à esquerda), sem reordenar por raridade ou Doutrina.
- **AC-TB-04 [L] F2 — foco inicial.** n 1..5 → foco em 0, 0, 1, 1, 2.
- **AC-TB-05 [L] R6 — navegação.** A/D e ←/→ movem o foco uma carta; na primeira, ← não dá a volta; na última, → não dá a volta; ↓ vai ao botão de troca e ↑ volta.
- **AC-TB-06 [L] R6 — seleção direta.** Tecla 2 move o foco à carta 2 sem confirmar; tecla 3 com n = 2 não faz nada; não existe tecla 4 nem 5.
- **AC-TB-07 [L] R6 — mouse.** Passar o mouse sobre a carta k move o foco para k; clique confirma só a carta já em foco e só fora da trava; clique numa carta fora de foco só move o foco (segundo clique confirma); mouse parado ao abrir não rouba o foco de F2.
- **AC-TB-08 [L] F3 — trava de abertura.** Aberta em 0 s com entrada 0,45 s: confirmar em 0,9 s é descartado; em 0,95 s vale.
- **AC-TB-09 [L] R7 — botão segurado.** Confirmar já pressionado quando a tela abre e mantido até 2 s: descartado; soltar e apertar de novo em 2,1 s: vale.
- **AC-TB-10 [L] R7 — buffer.** Um confirmar enfileirado antes de a tela abrir é esvaziado e não escolhe nada.
- **AC-TB-11 [L] F3 — trava da troca.** Troca em 2,0 s (anim 0,3): confirmar em 2,5 s é descartado; em 2,6 s vale; trocar de novo em 2,5 s também é descartado.
- **AC-TB-12 [L] R7/F3 — pausa.** Pausa em 1,2 s e volta em 3,0 s: confirmar em 3,2 s é descartado; em 3,3 s vale; pausa em 0,2 s e volta em 0,5 s: vale só a partir de 0,95 s.
- **AC-TB-13 [L] R8 — troca com cargas.** Com trocas 1, trocar chama `trocar()` uma vez, atualiza as cartas e o número de cargas para 0, e devolve o foco a F2.
- **AC-TB-14 [L] R8 — troca sem cargas.** Com trocas 0: o botão fica desabilitado (ícone riscado, "0"), R, Y e clique não chamam `trocar()`, o botão treme 80 ms; o foco chega ao botão e Confirmar nele só treme.
- **AC-TB-15 [L] R8 — troca e confirmar juntos.** Com cargas, no mesmo quadro: só `trocar()` é chamado; sem cargas (R pressionado junto): `escolher` vale.
- **AC-TB-16 [L] R9 — confirmar.** `escolher(i)` é chamado uma vez no quadro do aperto; um segundo confirmar no mesmo quadro ou na animação não chama de novo.
- **AC-TB-17 [L] R9 — animação.** Com preço: o selo racha depois do ganho e `preco_revelado` sai nesse momento; sem preço: não há rachadura e `preco_revelado` sai no fim do ganho; a animação dura ≤ 0,6 s; apertar confirmar antes de `preco_revelado` é ignorado, depois dele pula.
- **AC-TB-18 [L] R12 — sem cronômetro.** Com a tela aberta por 10 min (relógio falso), nada é escolhido sozinho e não há botão de pular.
- **AC-TB-19 [L] R12 — pausa por cima.** Esc abre a pausa sem escolher; fechar a pausa devolve a tela no mesmo estado.
- **AC-TB-20 [L] R13 — n pequeno.** n = 1: uma carta centralizada, foco 0, confirmar vale após a trava; n = 2 centralizadas.
- **AC-TB-21 [L] R2/R4 — dados da carta.** Com `preco_texto` nulo a placa de preço fica vazia e a altura da carta é a mesma; com o preço de O Preço com Nome a placa mostra o texto (da chave de localização com `{valor}`) em posição fixa.
- **AC-TB-22 [L] R14 — acessibilidade.** Alto contraste liga painéis 100% e raridade por linhas e palavra; redução de movimento vira fade ≤ 300 ms e o foco continua a 106% em corte seco; "Reduzir flashes" tira o flash.
- **AC-TB-23 [L] R15 — modos.** `CartaView` com modo bênção e modo arma usa topo da Doutrina; modo melhoria usa topo reto neutro (teste de interface).
- **AC-TB-24 [L] R16 — injeção.** A tela roda com Bênçãos e relógio falsos, sem cena de jogo.
- **AC-TB-25 [I] R9 — Bênçãos real.** Oferta de 3 cartas: escolher a 2 emite `bencao_tomada` uma vez no quadro do aperto; `bencao_escolhida` só depois de `tela_fechada`, e as portas abrem depois disso; `sem_bencao` não abre a tela.
- **AC-TB-26 [V] R4 — carta.** Screenshot de uma carta de cada raridade a 100%: zonas nas porcentagens da Art Bible, dourado só no ícone, topo sem ornamento de raridade.
- **AC-TB-27 [V] R11 — foco.** Screenshot em cinza com 3 cartas: a carta em foco (106%, anel) é apontada em < 1 s por 5 de 5 avaliadores.
- **AC-TB-28 [V] F1 — fileira (5 cartas, reservado).** Screenshot com 5 cartas a 100% e a 150% de UI: todas dentro da margem de 48 px, contando a carta em foco a 106%.

- **AC-TB-29 [L] R9 — HUD segura a Vida.** Com a bênção O Preço com Nome (Vida −10): o número de Vida do HUD muda no quadro de `escolher`, a animação de rachar só começa em `preco_revelado`.
- **AC-TB-30 [L] R10 — entrada.** Da `oferta_aberta` até as cartas assentadas, ≤ 0,45 s; três cartas legíveis em 0,5 s.
- **AC-TB-31 [L] R7 — dois confirmar.** Dois confirmar no mesmo quadro: `escolher` uma vez.
- **AC-TB-32 [L] Game Feel — latência.** O foco e o `escolher` respondem no quadro do aperto (≤ 16,7 ms, relógio falso).
- **AC-TB-33 [L] R14 — acessibilidade (partes).** Alto contraste: painéis 100% e raridade por linhas e palavra; redução de movimento: fade ≤ 300 ms e foco a 106% em corte seco; "Reduzir flashes": sem flash (três testes separados).
- **AC-TB-34 [L] Edge — pausa e foco de janela.** Esc na trava abre a pausa; perder o foco da janela não pausa nem escolhe.
- **AC-TB-35 [L] Validação — faixa do `TelaBencaoTuning`.** `trava_confirmar_ms` 400 gera o erro TB1; `entrada_s` 0,5 gera TB3; `anim_confirmar_s` 0,7 gera TB5; `foco_escala` 1,2 gera TB6; o dado de fábrica não gera nenhum TB; cada um dos 10 campos fora da faixa gera só o código do seu campo (TB1 a TB10).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Retrato e fala do Mestre na tela de bênção | Bênçãos / narrative-director | fatia vertical |
| 2 | Modo arma (tela de início) e modo melhoria (Oficina) do componente | Run OQ 4 / Oficina | fatia vertical |
| 3 | Teste das 18 combinações da Art Bible (Doutrina × raridade, em cinza) | art-director + QA | `/ux-design` |
| 4 | `preco_texto` longo: quebra, redução e corte (provisório) | art-director | `/ux-design` |
| 5 | ~~Conteúdo: `TelaBencaoTuning` (10 campos)~~ **Resolvida (2026-11-13):** o tipo e os códigos TB1–TB10 estão no Conteúdo R1/R9; falta só a validação do tamanho dos textos do ganho | Conteúdo | próxima edição |
| 6 | Sons de entrada, foco, confirmação e rachadura do preço | audio-director | Áudio |
| 7 | **Edições pendentes:** Bênçãos (monta `CartaView`; `oferta_trocada(cartas, trocas)`; segura `bencao_escolhida` até `tela_fechada`; R11/Edge: a pausa **abre** em Bênção, Input é a fonte), Conteúdo (`BoonDef` com `glifo`, `icone_ganho`, chave do preço; `TelaBencaoTuning`), HUD (recebe `preco_revelado` e o traço dourado), Input (as teclas 4 e 5 não existem; o glifo e o rótulo do botão vêm de `rotulo_acao(acao, dispositivo)` do Input, assinatura fechada em 2026-11-13), Pipeline (`modo_bencao` sai em `tela_fechada`) | Bênçãos, Conteúdo, HUD, Input, Pipeline | `/review-all-gdds` |

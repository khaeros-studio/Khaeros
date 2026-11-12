# HUD

> **Status**: Approved (2026-11-11; revisão única por subagente: 7 bloqueantes e recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê*; P4

## Summary

O **HUD** é a camada de interface que mostra ao jogador, durante a câmara, só o que
ele precisa decidir: **Vida, Fluxo, cargas de Esquiva e Fragmentos**, mais o prompt de
interação e o fio de Vida do inimigo. É mínimo de propósito (Art Bible §7.8). Só **lê**
dados e eventos dos outros sistemas; nunca decide nada.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Combate núcleo, Selo e Fluxo, Movimento e esquiva, Economia de Fragmentos, Chefes (reservado)`

> **Atualização (2026-11-12):** `preco_revelado` e `tela_fechada` viraram regra (R3, R12, AC-HD-35 e 36); ancoragem, camada da vinheta, `limiar_vida` e `rotulo_acao` registrados (R2, R3, R4, R10).

> **Nota (2026-11-11, Feedback de combate):** OQ 6 encerrada: o fio de Vida do inimigo e o prompt de interação ficam no HUD; números de dano e "Quebrou!" são do Feedback.

## Overview

> `ux-designer` não consultado nesta seção: modo Lean.

O **HUD** responde a três perguntas sem tirar o olho da arena: *quanto aguento*, *o
que posso fazer agora* (Fluxo, esquiva) e *o que ganhei*. Ele **não** mostra números
de dano nem o "Quebrou!" (Feedback de combate), telégrafos (Telégrafos), bênçãos
(pausa, Art Bible §7.8) nem o progresso da run (decisão do usuário).

- **Grupo do jogador (inferior esquerdo):** Vida (barra de osso segmentada, 25% = Vida
  baixa), Fluxo (gota magenta com entalhe do custo do Selo), Esquiva (chevrons abaixo
  da Vida), numa placa própria de tinta.
- **Fragmentos (superior direito):** ícone e número, escurece em repouso.
- **No mundo:** fio de Vida do inimigo comum (aparece após o primeiro golpe, some em 2
  s) e prompt de interação acima do objeto.
- **Reservado:** barra de chefe (topo, centro) só especificada, para a fatia vertical.
- **Estados:** vinheta e moldura partida de **Vida baixa**; opções de acessibilidade
  (escala de UI, número de Vida, Vida colorida, alto contraste, vinheta).

A **fantasia** é a de olhar a Beira, não o painel: o HUD é pequeno, fica nas bordas,
nunca entra (os elementos de tela, a 100%) no retângulo central de 60% × 70% e cada elemento lê só pela forma e pelo
valor, não pela cor.

As regras seguem a Art Bible §7.8–7.9 e os "UI Requirements" de Combate, Movimento,
Selo e Economia, com as decisões do usuário de 2026-11-11: escopo de §7.8 com chefe
reservado, sem progresso de run, Vida baixa em 25%.

> **→ vira ADR:** não. O HUD é uma cena que só escuta eventos e lê consultas; sem
> estado de jogo próprio.

## Detailed Design

### Core Rules

**R1. Só lê.** O HUD consulta e escuta; não chama nenhuma regra de jogo, não guarda
estado de jogo e não escreve em sistema algum. Cada elemento tem uma **fonte** (tabela
R2) e atualiza no mesmo passo em que o dado muda (≤ 1 passo).

**R2. Elementos e fontes** (posições da Art Bible §7.8, 1920 × 1080, margem segura de
48 px). **Ancoragem (regra provisória, 2026-11-12):** os elementos de tela ancoram nas
**bordas do viewport** (margem de 48 px), e o retângulo central de 60% × 70% refere-se ao
**quadro de 1920 × 1080 centralizado** (Cena R1; ultrawide até 2580 de largura); ver AC-HD-34.
A regra "nada no retângulo central de 60% × 70%" vale **só para os elementos de tela a 100% de escala** (Vida, Fluxo, Esquiva, Fragmentos, chefe); o prompt e o fio de Vida, que ficam **no mundo**, são isentos; a 125% e 150% o grupo inferior pode invadir o retângulo (exceção aceita, R13 e OQ 3):

| Elemento | Posição | Fonte (dono) | MVP |
|---|---|---|---|
| Vida | inferior esquerdo | Vida atual e máxima, escudo, recusas; `jogador_atingido`, `recusou_morte` (Combate) | sim |
| Fluxo | à esquerda da Vida | Fluxo 0–`fluxo_max`, custo, estados, `selo_sem_fluxo` (Selo) | sim |
| Esquiva | abaixo da Vida | cargas, máximo, fração da recarga; `esquiva`, `esquiva_sem_carga` (Movimento) | sim |
| Fragmentos | superior direito | `saldo()`, `saldo_mudou` (Economia) | sim |
| Fio de Vida do inimigo | no mundo, sob os pés | Vida atual e máxima do inimigo, primeiro golpe (Combate) | sim |
| Prompt de interação | no mundo, acima da porta | porta interagível (Câmaras R13), glifo do botão (Input) | sim |
| Barra de chefe | topo, centro, ~960 px | Vida e fases do chefe (Chefes) | reservado |

O grupo inferior esquerdo (~420 × 110 px) tem **placa de tinta ≥ 92%** própria. Não há
lista de bênçãos, progresso de câmara, minimapa nem telégrafos no HUD.

**R3. Vida.** Barra de osso segmentada: cada segmento vale `vida_por_segmento` (10);
18 px de altura, 3 px de intervalo; segmento parcial = preenchimento parcial. A barra
cresce em comprimento com a `vida_max` até 25% da largura da tela; dali, os segmentos
estreitam. Número "34/80" ao lado (padrão ligado, opção 8). Com a bênção **O Fundo do Poço**, uma marca na posição do `limiar_vida` lido do **dado da bênção** (não 50% fixo; sem dado, 50%). Perdeu Vida: **todo segmento que perde preenchimento** racha (Vida perdida 25 a partir de 34/80: a Vida fica 9; racham o 4º (parcial), o 3º e o 2º inteiros e parte do 1º) e cai
em 0,25 s; **escudo absorveu tudo: não racha** (Combate V10). Cura: preenche da
esquerda para a direita em 0,25 s. **Vida perdida por bênção (preço):** o número e o
preenchimento mudam no quadro de `escolher`; a animação de rachar espera o `preco_revelado`
da Tela de bênção (R9 da Tela); o traço dourado da confirmação voa para o grupo inferior (Vida).

**R4. Vida baixa.** `vida_atual ≤ vida_baixa_pct × vida_max` (25%, arredondando o
limiar para cima em inteiro) liga: moldura **partida** com borda mais grossa e manchas
de tinta nos segmentos; **vinheta** nas bordas (≤ 8% de cada borda, opacidade ≤ 40%,
nunca avança para o centro, ciclo ≥ 2 s) e a deixa sonora (Áudio). Histerese: desliga
só ao passar de `vida_baixa_pct + 5` pontos (30%), para a vinheta não piscar. A opção
6 (0–100%) escala a vinheta; "redução de movimento" (opção 5) a deixa estática.
**Camada:** a vinheta fica na **camada de pós da Cena** (z 50), acima do mundo e abaixo da UI,
sem criar uma 12ª camada. O plano de contingência dos Visual/Audio Requirements ("abaixo de
telégrafos e personagens") exige confirmar com a Cena que essa posição existe (OQ 9).
**Nota:** "Vida baixa" (HUD, `vida_baixa_pct`) é distinta de `limiar_vida` (Modificadores,
lido pela marca de O Fundo do Poço, R3): os dois não compartilham valor nem regra.

**R5. Escudo e recusas.** *Provisório (art-director, OQ 2):* o escudo aparece como uma
**faixa fina de tinta clara** sobre a barra, de largura proporcional (valor ÷ `vida_max`, limitada ao resto da barra), 
que some ao zerar; as **recusas de morte restantes** (Combate) aparecem como pontos de
osso (máx. 3) junto ao número de Vida, só quando ≥ 1. No MVP a base é 0, então nada
aparece sem bênção ou melhoria.

**R6. Fluxo.** Gota magenta de 48 px que enche de baixo para cima conforme
Fluxo ÷ `fluxo_max`; **entalhe** na altura do custo (40 de 100). Estados: **Pronto**
(Fluxo ≥ custo: gota cheia até o entalhe com brilho leve), **Sem Fluxo** (< custo:
sem brilho), **Em recarga** (`recarga_s` do Selo: ícone escurecido; tem precedência sobre os outros dois). `selo_sem_fluxo`: pisca o
entalhe **uma vez** por toque novo (Selo). Ícone do Selo ao lado com o glifo do botão
(`selo`, remapeável, Input). Sem número de Fluxo (a Art Bible §7.9 não tem essa opção; o "número de Fluxo" do Selo vira pedido de adição, OQ 8).

**R7. Esquiva.** Um chevron de 32 px por carga máxima: **cheio** = preenchido, **vazio**
= só contorno; o chevron em recarga preenche pela fração 0–1 do Movimento.
`esquiva_sem_carga`: o conjunto estremece 80 ms (provisório, Movimento V5). A
invulnerabilidade **não** aparece no HUD (Movimento).

**R8. Fragmentos.** Ícone de 32 px e número de 24 px, **escurecidos em repouso**;
`saldo_mudou` com delta > 0 acende o conjunto por 1,5 s e mostra "+N" ao lado (ganhos
dentro de 1,5 s somam num só "+N"). Delta < 0 (Oficina, fatia vertical): "−N" no
mesmo lugar. Número com separador de milhar a partir de 1 000.

**R9. Fio de Vida do inimigo comum.** Fio de osso sob os pés: aparece **após o primeiro
dano** (qualquer origem: lê-se a queda da Vida do inimigo, não o `acerto`, porque o Selo e os status não emitem `acerto`), mostra Vida atual ÷ máxima, some **2 s** depois do último
dano (reinicia a cada dano). Elites: o mesmo fio, 1,5× mais largo. Morreu: some
no mesmo passo. Não aparece em inimigo sem dano. Limite de fios visíveis: 9 (o teto
de inimigos).

**R10. Prompt de interação.** Aparece acima da **porta** quando ela está interagível: o
alcance é o de Câmaras R13 (`interagir_folga_px`; o HUD não tem raio próprio, e duas
portas ao alcance são impossíveis com o espaçamento de 450 px). Glifo de 32 px do botão
de `interagir` (o HUD consulta `rotulo_acao(acao, dispositivo)` do Input, conforme o dispositivo ativo; mesma consulta para o glifo do Selo) e verbo de 20 px ("Interagir", o
aviso de Câmaras R13), moldura chanfrada de tinta. Se um segundo objeto interagível
passar a existir (fatia vertical), o desempate é de Câmaras. A pedra do santuário **não**
é interagível (cura automática, Câmaras R12). Some ao sair do alcance, ao abrir a Bênção
(`oferta_aberta`) ou na Transição.

**R11. Barra de chefe (reservada).** Topo, centro, ~960 px × 14 px, nome em H2, osso
segmentado em fases; moldura cristalina (Anomalia Maior) ou simétrica (Guardião). Só
especificada: entra com o GDD de Chefes.

**R12. Visibilidade por estado de jogo** (o conjunto Jogo, Pausa, Bênção, Menu, Morte e Transição é o do **orquestrador** do Combate R1, e a Run acrescenta Escolha de arma e Encerrada; a Bênção entra por `oferta_aberta` e **termina em `tela_fechada`** (da Tela de bênção): esse sinal é o gatilho que **reexibe fios e prompt**). Jogo: tudo visível. Pausa: tudo visível,
esmaecido a 60% sob a pausa. Bênção: grupo inferior e Fragmentos visíveis, fios e
prompt escondidos. Transição: HUD some em 0,25 s e volta em 0,25 s (fade; com redução
de movimento, ≤ 300 ms). Tela de início e tela final: sem HUD de combate; a tela final
usa o resumo da Run (R7 da Run) e o saldo, **no GDD da própria tela**.

**R13. Escala e acessibilidade.** Todas as medidas valem em 1920 × 1080 a 100%; a
**escala de UI** (85/100/125/150%) multiplica os tamanhos, mantendo a margem de 48 px;
a 150% o grupo inferior cabe em 1280 × 720. Opções do HUD (Art Bible §7.9): 1, 5, 6, 8,
9 (Vida colorida: o osso vira vermelho-tinta), 10 (alto contraste: placas 100%,
molduras de 3 px, texto osso puro), 12 (fonte). Cada elemento lê por **forma e valor**,
nunca só por cor (Vida: segmentos; Fluxo: nível e entalhe; Esquiva: preenchido ou
contorno).

**R14. Injeção e dados.** Ao ser criado (inclusive recriado na Transição) o HUD lê o estado atual por consultas (`saldo()`, Vida, Fluxo, cargas, `tomadas()` da Bênçãos para a marca do Fundo do Poço), nunca só por eventos. O HUD recebe as **fontes por interface de leitura** (R2) e o
`HudTuning` (Tuning Knobs); os testes montam fontes falsas e verificam a cena sem jogo.

### States and Transitions

Sem máquina de estados própria. Cada elemento tem estados locais que seguem a fonte:
Vida **normal ↔ baixa** (R4, com histerese); Fluxo **pronto / sem Fluxo / em recarga**
(R6); fio do inimigo **oculto → visível → oculto** (R9); prompt **oculto ↔ visível**
(R10). O HUD inteiro **segue o estado de jogo** (R12).

### Interactions with Other Systems

| Sistema | Fornece ao HUD | Recebe do HUD | Dono da interface |
|---|---|---|---|
| Combate núcleo | Vida, escudo, recusas, `jogador_atingido`, `recusou_morte`, Vida do inimigo | — | Combate |
| Selo e Fluxo | Fluxo, custo, estados, `selo_sem_fluxo` | — | Selo |
| Movimento e esquiva | cargas, máximo, fração, `esquiva`, `esquiva_sem_carga` | — | Movimento |
| Economia de Fragmentos | `saldo()`, `saldo_mudou` | — | Economia |
| Câmaras e ondas / Portas | porta interagível e alcance (Câmaras R13) | — | Câmaras |
| Input e controle | glifo do botão por dispositivo via `rotulo_acao(acao, dispositivo)`, contexto de menu | — | Input |
| Run e regiões | estado de jogo (Jogo, Pausa, Transição, Encerrada) | — | Run |
| Bênçãos | `oferta_aberta` (esconde fios e prompt); `limiar_vida` do dado de O Fundo do Poço | — | Bênçãos |
| Tela de bênção e carta | `preco_revelado`, `tela_fechada`; o HUD recebe | — | Tela de bênção |
| Cena 3/4 e câmera | camada de pós (z 50) da vinheta; quadro de 1920 × 1080 e viewport (R2) | — | Cena |
| Pipeline visual | camada de UI, fonte, orçamento de draw calls | — | Pipeline |
| Feedback de combate (VFX) | — | divisão de elementos (R2) | Feedback |
| Chefes (reservado) | Vida e fases do chefe | — | Chefes |

## Formulas

**F1. Segmentos da Vida.** `n_seg = ceil(vida_max / vida_por_segmento)`; a capacidade do
segmento `i` (0 = esquerda) = `min(vida_por_segmento, vida_max − vida_por_segmento × i)`
(o **último** pode ter capacidade menor, e então sua **largura** é proporcional à
capacidade); preenchimento = `clamp((vida − vida_por_segmento × i) / capacidade, 0, 1)`.
Assim, Vida cheia = todos os segmentos cheios. Ex.: Vida 34/80: 8 segmentos, 3 cheios, o
4º em 0,4. `vida_max` 85, Vida 85: 9 segmentos, o 9º com capacidade 5 (metade da
largura) e cheio. `vida_max` 100: 10 segmentos; o piso 20: 2.

**F2. Largura da barra de Vida.** `largura = min(n_seg × segmento_px + 3 × (n_seg − 1), teto)`
com `teto = barra_max_frac × 1920`; o teto vale **antes** da escala: 480 px a
100%, e a escala multiplica o resultado final (a 150%, até 720 px, o que invade o
retângulo central: exceção da R2). Acima do teto, `segmento_px' = (teto − 3 × (n_seg − 1)) / n_seg`.
Ex. (`segmento_px` 32): Vida 100 → 10 × 32 + 27 = **347 px**; Vida 150 (Vigor máximo) →
15 × 32 + 42 = 522 > 480 → `segmento_px'` = (480 − 42) / 15 = 29,2 px. A placa do
grupo (~420 × 110 px, Art Bible §7.8) **cresce** com a barra no caso de Vigor alto.

**F3. Vida baixa com histerese** (em inteiros, `pct_i` = pct × 100 como inteiro: 25 e 30; evita o ponto flutuante de 0,25 + 0,05). Liga se `vida × 100 ≤ pct_i × vida_max` arredondado para cima; desliga se `vida × 100 > (pct_i + histerese_i) × vida_max`, ambos como `ceil` no limiar de Vida. Equivale a: liga se `vida ≤ ceil(vida_baixa_pct × vida_max)`; desliga se `vida > ceil((vida_baixa_pct + vida_baixa_histerese) × vida_max)`. Ex.
`vida_max` 100: liga em ≤ 25, desliga em > 30; `vida_max` 20: liga ≤ 5, desliga > 6.
Vida 0 é morte (Combate): o HUD não calcula.

**F4. Fluxo.** `altura_gota = Fluxo / fluxo_max × 48 px`; entalhe na fração
`custo / fluxo_max` = 40/100 = 0,40 (19,2 px do fundo). Pronto ⇔ `recarga = 0` **e** `Fluxo ≥ custo_fluxo` (Selo); **Em recarga** tem precedência sobre Pronto e Sem Fluxo (ícone escurecido).

**F5. Esquiva.** Chevron `k` (0 = esquerda) cheio se `k < cargas`; o chevron `k = cargas`
(se `cargas < máximo`) preenche pela fração da recarga (0–1); os demais, contorno.

**F6. "+N" de Fragmentos.** `N = soma dos delta > 0` recebidos com menos de
`janela_ganho_s` entre um e outro; o "+N" fica visível `janela_ganho_s` depois do **último**
ganho (a janela reinicia a cada ganho); `N` mostrado limitado a 99 999. Ex.: +2 e, 1 s
depois, +3 → "+5" por mais 1,5 s.

**F7. Fio de Vida do inimigo.** `largura = largura_fio (48 px) × (fio_elite_escala se elite) × Vida / Vida_max`;
visível por `fio_visivel_s` (2 s = 120 passos) após o **último** dano. Ex.: Vida 12/40:
fio a 30%.

## Tuning Knobs

`HudTuning` (tipo novo no Conteúdo, dono: HUD; nota de edição pendente). `margem_segura_px` (48) e `barra_max_frac` (0,25) seguem a Art Bible §7.8: mexer neles exige emenda dela. Constantes fixas (não são knobs): 0,25 s de racha e cura, 60% da pausa, 3 pontos de recusa, 99 999 do "+N".

| Knob | Padrão | Faixa | Categoria | Efeito |
|---|---|---|---|---|
| `vida_por_segmento` | 10 | 5–20 | curva | quanto vale um segmento da barra |
| `segmento_px` | 32 | 24–40 | feel | largura de um segmento a 100% de UI |
| `barra_max_frac` | 0,25 | 0,20–0,30 | gate | teto da barra (fração da largura da tela) |
| `vida_baixa_pct` | 0,25 | 0,15–0,35 | curva | limiar de Vida baixa |
| `vida_baixa_histerese` | 0,05 | 0,02–0,10 | feel | folga para desligar a Vida baixa |
| `vinheta_max_borda` | 0,08 | 0–0,08 | gate | espessura máxima da vinheta (Art Bible: ≤ 8%) |
| `vinheta_opacidade_max` | 0,40 | 0–0,40 | gate | opacidade máxima (Art Bible: ≤ 40%) |
| `janela_ganho_s` | 1,5 | 0,5–3 | feel | tempo e janela do "+N" |
| `fio_visivel_s` | 2 | 1–4 | feel | quanto o fio fica após o último dano |
| `largura_fio` | 48 px | 32–72 | feel | largura do fio do inimigo comum |
| `fio_elite_escala` | 1,5 | 1–2 | feel | largura do fio de elite |
| `esquiva_tremor_ms` | 80 | 0–200 | feel | tremor em `esquiva_sem_carga` |
| `fade_estado_s` | 0,25 | 0,1–0,3 | feel | fade do HUD em Transição |
| `margem_segura_px` | 48 | 32–64 | gate | margem segura |

## Edge Cases

- **Vida cheia ou 0 segmentos de diferença:** cura com Vida cheia não anima.
- **`vida_max` muda no meio da câmara (Vigor, bênção):** a barra reajusta no mesmo
  passo (F1/F2); a Vida atual segue a F4 do Modificadores; a Vida baixa é reavaliada
  com a F3.
- **Vida cruza o limiar e volta (cura e dano em seguida):** a histerese impede o
  pisca; a vinheta só desliga acima do limiar de desligar.
- **Escudo absorve tudo:** nenhum segmento racha (R3), mas a faixa do escudo diminui.
- **`recusou_morte`:** a barra salta à **Vida nova** que o evento traz (Combate) de uma vez, sem preenchimento animado; a Vida baixa (moldura e vinheta) liga se ≤ limiar.
- **Vida 1 com `vida_max` 20:** moldura partida e vinheta ligadas, sem passar de 8% e
  40%.
- **Fluxo exatamente no custo:** Pronto (≥).
- **Fluxo cheio e cortado por novo máximo:** a gota reescala (F4) no mesmo passo.
- **Esquiva com máximo 1 ou 2 cargas:** 1 ou 2 chevrons; bênção que aumenta o máximo
  adiciona chevron sem animação de recarga.
- **Dois ganhos de Fragmentos no mesmo passo (porta e vitória):** somam num "+N".
- **Saldo no teto (999 999):** o número não muda; sem "+N" (Economia: sem `saldo_mudou`).
- **Saldo ≥ 1 000 000:** impossível (teto); se importado maior, a Economia corta.
- **Dois inimigos mortos no mesmo passo com fio visível:** os fios somem no mesmo passo.
- **Mais de 9 fios:** impossível (teto de 9 inimigos); se acontecer, os 9 mais próximos
  do jogador.
- **Elite com Vida baixa:** o fio segue F7; nada de mudança de forma.
- **Prompt com a Bênção aberta ou na Transição:** escondido (R12).
- **Troca de dispositivo (teclado ↔ gamepad):** o glifo do prompt e do Selo troca no
  passo seguinte (Input).
- **Escala de UI 150% a 1280 × 720:** o grupo inferior cabe (R13); se `vida_max` alto
  estreitar demais, os segmentos têm piso de 12 px e a barra quebra em duas linhas
  (provisório, OQ 3).
- **Alto contraste e Vida colorida juntos:** valem os dois (placas 100% e osso
  vermelho-tinta).
- **Pausa no meio do "+N":** o relógio do HUD também pausa (não consome a janela).
- **Run encerrada (morte):** o HUD some na tela final; a vinheta fecha só com a morte
  (Art Bible §2.8), não antes.

## Dependencies

| Sistema | Direção | Natureza | Interface |
|---|---|---|---|
| Combate núcleo | entra | leitura | Vida, escudo, recusas, `jogador_atingido`, `recusou_morte`, Vida do inimigo (Combate UI) |
| Selo e Fluxo | entra | leitura | Fluxo, custo, estados, `selo_sem_fluxo` |
| Movimento e esquiva | entra | leitura | cargas, máximo, fração da recarga, `esquiva`, `esquiva_sem_carga` |
| Economia de Fragmentos | entra | leitura | `saldo()`, `saldo_mudou(saldo, delta, origem)` |
| Câmaras e ondas / Portas e recompensas | entra | leitura | porta interagível e alcance (Câmaras R13); nota de edição pendente: remover "número da câmara" dos UI Requirements de Câmaras |
| Input e controle | entra | leitura | `rotulo_acao(acao, dispositivo)` (glifo por dispositivo); remapeamento |
| Run e regiões | entra | leitura | estado de jogo (Jogo, Pausa, Transição, Encerrada) |
| Bênçãos (Tradições) | entra | leitura | `oferta_aberta`, `bencao_tomada` (O Fundo do Poço: marca no `limiar_vida` do dado; 50% sem dado) |
| Cena 3/4 e câmera | entra | leitura | camada de pós (z 50) da vinheta (OQ 9); viewport e quadro de 1920 × 1080 (R2) |
| Modificadores e atributos | entra | leitura | `vida_max`, máximo de cargas |
| Pipeline visual | entra | rígida | camada de UI, fontes, paleta, orçamento de draw calls |
| Conteúdo orientado a dados | entra | rígida | `HudTuning` (14 campos; já registrado no Conteúdo R1) |
| Chefes (reservado) | entra | reservada | Vida e fases do chefe (R11) |
| Feedback de combate (VFX) | sai | divisão | o HUD não mostra números de dano nem "Quebrou!" |
| Tela de bênção e carta | entra | leitura | `preco_revelado`, `tela_fechada`; o HUD recebe (não compartilham elementos; o HUD esconde fios e prompt na oferta e os reexibe em `tela_fechada`) |

Nenhum sistema depende do HUD para **rodar**; sem ele o jogo funciona, só sem
interface.

## Visual/Audio Requirements

- **Osso e tinta** (Art Bible §7.8): Vida em osso segmentado com contorno de tinta; Fluxo
  em magenta (a única cor do grupo); Fragmentos em osso com brilho frio.
- **Segmento perdido:** racha e cai (0,25 s); cura preenche da esquerda para a direita.
- **Vida baixa:** moldura partida, manchas de tinta, vinheta ≤ 8% / ≤ 40%, deixa sonora
  própria (audio-director); teste de legibilidade: com a vinheta máxima, um telégrafo e um
  inimigo na borda mantêm ≥ 40 pontos de L* do chão; se falhar, a vinheta vai para baixo
  da camada de telégrafos e personagens. Posição padrão: camada de pós da Cena (z 50), acima do
  mundo e abaixo da UI; o plano de contingência exige confirmar com a Cena (OQ 9), sem criar 12ª camada.
- **Fluxo Pronto:** brilho leve na gota; **`selo_sem_fluxo`:** pisca o entalhe uma vez.
- **Fragmentos:** acende por 1,5 s ao ganhar, com som de moeda leve.
- **Sons:** `jogador_atingido` e `recusou_morte` são do Áudio/Feedback; o HUD só dispara
  a animação.

## Game Feel

- **Latência:** todo elemento atualiza em ≤ 1 passo (16,7 ms) do evento da fonte.
- **Legibilidade periférica:** Vida, Fluxo e Esquiva legíveis a 100% e a 85% de escala
  sem olhar direto (forma e valor, nunca só cor).
- **Sem ruído:** nada pisca mais de 3 vezes por segundo (limitador da Art Bible §7.9 nº 4);
  a Vida baixa respira com ciclo ≥ 2 s; "Redução de movimento" (opção 5) deixa a vinheta estática; "Reduzir flashes" (opção 4) só alimenta o limitador.
- **Peso do dano:** o **número** e o preenchimento da Vida mudam no passo do evento (≤ 1 passo); só a **animação** de rachar começa após o hitstop do Combate. O relógio do HUD roda em tempo real (não em passos vivos) e **pausa** com a pausa.

## UI Requirements

- **Grupo inferior esquerdo** (Vida, Fluxo, Esquiva) com placa de tinta ≥ 92%.
- **Opções do HUD** (menu de opções, outro GDD de UX): escala de UI, número de Vida,
  Vida colorida, alto contraste, vinheta, fonte.
- Todas as medidas a 1920 × 1080 / 100%; a 150% o grupo cabe em 1280 × 720 (R13).
- A spec de UX (`design/ux/hud.md`) é feita com `/ux-design` antes das epics (UX Flag
  dos GDDs de Movimento e Selo): este GDD é a base de regras.

> **📌 UX Flag — HUD:** na Pré-Produção, rodar `/ux-design` para o HUD antes das epics.

## Cross-References

- Art Bible §7.1, §7.4, §7.8, §7.9; Combate "UI Requirements" e V10/V11; Movimento "UI
  Requirements" e V5; Selo "UI Requirements"; Economia R8, F1; Câmaras R12 e R13; Run R7/R12.
- Índice: linha 28.

## Acceptance Criteria

Tipos: [L] lógica (unitário, fontes falsas), [I] integração, [V] visual (screenshot em
`production/qa/evidence/`).

- **AC-HD-01 [L] F1 — segmentos.** Vida 34/80 com 10 por segmento: 8 segmentos, 3 cheios, o 4º a 0,4; `vida_max` 100: 10; `vida_max` 20: 2; `vida_max` 85 com Vida 85: 9 segmentos, o 9º com capacidade 5 (metade da largura) e cheio.
- **AC-HD-02 [L] F2 — largura.** Vida 100 → 347 px; Vida 150 → 480 px com `segmento_px'` 29,2; nunca passa de `barra_max_frac × 1920` antes da escala; a 150% de escala, Vida 100 → 520,5 px.
- **AC-HD-03 [L] R3 — rachar.** `jogador_atingido` com Vida perdida 10 racha o segmento correspondente; com escudo absorvendo tudo (Vida perdida 0) nenhum racha; Vida perdida 25 a partir de 34/80 (Vida fica 9): racham o 4º (parcial), o 3º e o 2º inteiros e parte do 1º; a latência do número de Vida é ≤ 1 passo.
- **AC-HD-04 [L] R3 — Fundo do Poço.** Com a bênção, uma marca na posição do `limiar_vida` do dado dela (com `limiar_vida` 0,40: a 40% da barra; sem dado: 50%); sem a bênção, nenhuma.
- **AC-HD-05 [L] F3 — liga.** `vida_max` 100: Vida 25 liga a Vida baixa; Vida 26 não.
- **AC-HD-06 [L] F3 — histerese.** Subindo de 25 para 30 continua ligada; em 31 desliga; descendo de 31 para 26 continua desligada.
- **AC-HD-07 [L] F3 — Vida pequena.** `vida_max` 20: liga ≤ 5, desliga > 6.
- **AC-HD-08 [L] R4 — vinheta.** A vinheta nunca passa de `vinheta_max_borda` (8%) por borda nem de `vinheta_opacidade_max` (40%), mesmo com a opção 6 em 100%.
- **AC-HD-09 [L] R5 — escudo e recusas.** Sem escudo e sem recusas nada é desenhado; com recusas 2, dois pontos; com 5, no máximo 3; escudo 20 sobre Vida 90/100: faixa de 10 (limitada ao resto), some ao zerar.
- **AC-HD-10 [L] F4/R6 — Fluxo.** Fluxo 39: Sem Fluxo; 40: Pronto; entalhe a 0,40 de `fluxo_max`; gota a 24 px com Fluxo 50; Fluxo 100 com recarga > 0: Em recarga (ícone escurecido), não Pronto.
- **AC-HD-11 [L] R6 — `selo_sem_fluxo`.** Um evento por toque novo (Selo AC-SF-08): o pisca acontece uma vez por evento; segurar o botão não gera evento novo, então um pisca só.
- **AC-HD-12 [L] F5/R7 — Esquiva.** 2 cargas de 3, recarga a 0,5: chevrons 1 e 2 cheios, o 3º a 50%; `esquiva_sem_carga` estremece 80 ms.
- **AC-HD-13 [L] F6/R8 — "+N".** +2 e, 1 s depois, +3: mostra "+5" por 1,5 s após o último; um ganho depois de 1,5 s abre "+N" novo.
- **AC-HD-14 [L] R8 — Fragmentos.** Saldo 1 234 mostra "1 234"; delta < 0 mostra "−N"; saldo sem `saldo_mudou` não pisca.
- **AC-HD-15 [L] F7/R9 — fio.** Vida 12/40: fio a 30%; invisível antes do primeiro dano; some 120 passos após o último; reinicia a cada dano; elite 1,5× mais largo.
- **AC-HD-16 [L] R9 — morte.** Inimigo morto: fio some no mesmo passo.
- **AC-HD-17 [L] R10 — prompt.** O limiar de 111 px é a **distância entre centros** = `porta_raio_px` 69 + raio do jogador 27 + `interagir_folga_px` 15 (Câmaras R13): a 111 px do centro da porta o prompt "Interagir" aparece; a 112 px não; some ao abrir a Bênção e na Transição; sem prompt na pedra do santuário.
- **AC-HD-18 [L] R10 — glifo.** Trocar de teclado para gamepad troca o glifo do prompt e do Selo no passo seguinte.
- **AC-HD-19 [L] R12 — estados.** Em Bênção: grupo inferior e Fragmentos visíveis, fios e prompt ocultos; em Pausa: esmaecido a 60%; em Transição: fade de 0,25 s (≤ 300 ms com redução de movimento).
- **AC-HD-20 [L] R11 — chefe reservado.** Sem Chefes, a barra de chefe não existe na cena; nenhum erro por fonte ausente.
- **AC-HD-21 [L] R1 — só lê.** A interface de leitura passada ao HUD não expõe nenhum método de escrita; o HUD roda com fontes falsas, sem cena de jogo (R14).
- **AC-HD-22 [L] F3 — `vida_max` muda.** `vida_max` 100, Vida 25 (Vida baixa ligada) → 150: Vida 75 (Modificadores F4), 15 segmentos, e a Vida baixa desliga (75 > ceil(0,30 × 150) = 45).
- **AC-HD-23 [L] Edge — `recusou_morte`.** A barra salta à Vida nova sem preencher em animação; a moldura partida liga se ≤ limiar.
- **AC-HD-24 [L] Edge — pausa.** "+5" com 1,0 s restante: pausar 10 s e retomar mantém 1,0 s restante.
- **AC-HD-25 [L] R13 — opções.** Opção 9 troca o osso por vermelho-tinta; opção 10 liga placas a 100%; opção 8 desliga o número de Vida; opção 5 deixa a vinheta estática; opção 6 a 50% reduz a opacidade da vinheta pela metade; opções 9 e 10 juntas valem as duas.
- **AC-HD-26 [V] R2 — layout.** Screenshot a 1920 × 1080 a 100%: nenhum elemento **de tela** dentro do retângulo central de 60% × 70% (prompt e fio de mundo isentos); margem de 48 px; placa do grupo ≥ 92%.
- **AC-HD-27 [V] R13 — 150%.** Screenshot a 1280 × 720 com escala 150%: o grupo inferior cabe na tela (invadir o retângulo central é a exceção aceita, R2).
- **AC-HD-28 [V] R4 — Vida baixa.** Screenshot com Vida baixa, um telégrafo e um inimigo na borda: L* ≥ 40 do chão e vinheta ≤ 8%; repetido com a opção 9 (Vida colorida): a mancha de tinta mantém o contraste.

- **AC-HD-29 [L] R9 — limite e elite.** 9 inimigos com fio: 9 fios; um 10º (fora do teto) mostra só os 9 mais próximos; elite com Vida 5/100 mostra o fio a 5%, 1,5× mais largo, sem mudar de forma.
- **AC-HD-30 [L] R9 — dano sem `acerto`.** Dano do Selo e de status (sem `acerto`) faz o fio aparecer.
- **AC-HD-31 [L] R14 — estado inicial.** Recriar o HUD na Transição com a bênção O Fundo do Poço, saldo 26, Vida 40/100 e Fluxo 40: a marca de 50%, o saldo, a Vida e o Fluxo aparecem sem receber evento.
- **AC-HD-32 [L] R7 — máximo de cargas muda.** Máximo 2 → 3 por bênção: aparece o 3º chevron, vazio, sem animação de recarga.
- **AC-HD-33 [L] R12 — início, final e Encerrada.** Nas telas de início e final e no estado Encerrada, nenhum elemento de combate é desenhado.
- **AC-HD-34 [V] R2 — ancoragem em ultrawide (provisório).** Screenshot a 2560 × 1080 a 100%: Vida, Fluxo, Esquiva e Fragmentos ancorados nas bordas do viewport (margem de 48 px), e nenhum elemento de tela dentro do retângulo central de 60% × 70% do quadro de 1920 × 1080 centralizado.
- **AC-HD-35 [L] R3 — `preco_revelado`.** Bênção com preço em Vida: o número e o preenchimento da Vida mudam no quadro de `escolher`; nenhum segmento racha antes de `preco_revelado`; ao receber `preco_revelado` a animação de rachar começa (0,25 s); o traço dourado da confirmação voa para o grupo inferior (Vida).
- **AC-HD-36 [L] R12 — `tela_fechada`.** Com a Bênção aberta, fios e prompt ficam ocultos; em `tela_fechada` fios (com a janela de `fio_visivel_s` ainda válida) e o prompt (se a porta continua interagível) voltam a aparecer no mesmo passo; sem `tela_fechada`, não voltam.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Barra de chefe: layout final, fases e nome | Chefes / art-director | fatia vertical |
| 2 | Visual do escudo e das recusas de morte (propostos aqui) | art-director | `/ux-design` do HUD |
| 3 | Grupo inferior de ~420 px × barra de até 480 px: placa que cresce e quebra em duas linhas a 150% / Vigor alto | art-director + UX | `/ux-design` do HUD |
| 4 | Deixa sonora da Vida baixa e som do ganho de Fragmentos | audio-director | Áudio |
| 5 | Conteúdo: `HudTuning` (14 campos) e validação | Conteúdo | próxima edição |
| 6 | Fio de Vida do inimigo e prompt: ficam no HUD ou no Feedback de combate? (propostos aqui) | Feedback de combate | GDD de Feedback |
| 7 | Tela final e tela de início (resumo da Run) | UX / Run OQ 4 | `/ux-design` |
| 9 | A vinheta de Vida baixa fica na camada de pós da Cena (z 50); o plano de contingência "abaixo de telégrafos e personagens" é possível sem criar 12ª camada? | Cena 3/4 | `/review-all-gdds` |
| 10 | Ancoragem em ultrawide (R2, regra provisória): confirmar bordas do viewport e quadro central de 1920 × 1080 (AC-HD-34) | Cena / art-director | `/ux-design` do HUD |
| 8 | Contratos: Câmaras (tirar "número da câmara"), Selo (tirar "número de Fluxo" ou pedir opção à Art Bible), Combate (fio e prompt são do HUD), Art Bible §7.8 (exceção do retângulo central a 125%/150%) | Câmaras, Selo, Combate, art-director | `/review-all-gdds` |

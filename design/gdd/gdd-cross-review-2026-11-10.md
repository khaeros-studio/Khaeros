# Cross-GDD Review Report (3ª passada)

**Data:** 2026-11-10 · **Foco:** full (consistência, design holístico, cenários)
**Executado:** nesta aba de Design, por três subagentes em paralelo (fase 2
`game-designer`, fase 3 `game-designer`, fase 4 `qa-lead`). Os subagentes leram
os GDDs por seção (o conteúdo é grande demais para ser colado no prompt; desvio
declarado do Phase 1 do skill).
**GDDs reviewed:** 9 of 9 present — Conteúdo orientado a dados, Modificadores e
atributos, RNG com seed, Input e controle, Cena 3/4 e câmera, Movimento e
esquiva, Combate núcleo, Pipeline visual, Armas das Doutrinas (todos Approved).
**Not read:** nenhum GDD ficou sem leitura, mas a fase 2 não conferiu tudo (ver
"Cobertura").
**Base anterior:** `gdd-cross-review-2026-11-06b.md` (CONCERNS).

---

## Consistency Issues

### Blocking

🔴 **C-B1. A camada `contorno de telégrafo` (z 5) não existe na Cena.**
Pipeline R5 (`pipeline-visual.md:180–186`, OQ5) desenha o contorno do telégrafo
numa camada própria em z 5. A Cena R4 (`cena-3-4-e-camera.md:95–113`) diz que
toda coisa visível pertence a exatamente uma camada da tabela, que não tem z 5;
o AC-09 (l. 720–722) exige "exatamente uma das 10 camadas" e o AC-10 (l. 723–724)
ainda trata o telégrafo abaixo do personagem como provisório; l. 14/37 dizem "10
camadas". Índice l. 27/156: "9 camadas". **Correção:** linha nova na R4 da Cena
(`contorno de telégrafo | — | 5 | 1,0`), "10" → "11" e AC-09/AC-10/aviso das
l. 134–138 reescritos, OQ1 fechada; índice "11 camadas de render (9 de arte)".

🔴 **C-B2. As durações dos efeitos visuais do Combate não têm campo de dado nem
de evento.** O Pipeline R12/R13 (`pipeline-visual.md:392–401`) e R6 (l. 222,
226) recebe do Combate, no evento, as durações do flash de acerto (5 passos),
do extra da inversão (+4), da invulnerabilidade e do impact frame. O Combate só
as tem em prosa (V6 l. 1169–1170; V10 l. 1228; V11 l. 1244; V12 l. 1263–1264);
o `CombatTuning` (R15, l. 362–394) e os eventos (R17, l. 428–440) não as têm.
**Decisão do usuário (2026-11-10):** o Combate é o dono (campos `_s` no
`CombatTuning` e durações nos eventos).

### Warnings

- ⚠️ **C-W1.** O Combate não lista o Pipeline visual (Dependencies l. 1021–1060;
  índice linha 8), que o lista dos dois lados (`pipeline-visual.md:1184, 1196`).
- ⚠️ **C-W2.** O Conteúdo R1 (l. 94) não nomeia `MovementTuning`, `VisualTuning`
  nem `ArmasTuning`; Interactions (l. 371–378) e downstream (l. 768–790) sem o
  Pipeline e com Armas incompleto; nota de bidirecionalidade velha (l. 795–799).
- ⚠️ **C-W3.** Impact frame: a V12 do Combate fala em "12 quadros de render" e o
  Pipeline R7 em passos de apresentação; o AC1 e o AC-79 do Combate dizem que a
  recusa perde para o chefe, e o Pipeline R7/F6 tem preempção (decisão do
  usuário).
- ⚠️ **C-W4.** Profundidade p: o Pipeline R3 conta da primeira câmara (dono Run),
  Armas R7/F3 da primeira câmara de combate (dono Câmaras), o Modificadores R10
  põe a fórmula na IA/Câmaras. Opções: (a) um único p (câmaras de combate) com
  um dono; (b) dois contadores com nomes distintos.
- ⚠️ **C-W5.** Cena e Combate se põem um ao outro como downstream
  (`cena-3-4-e-camera.md:603`; `combate-nucleo.md:1057`); nota velha da Cena
  l. 607–612.
- ⚠️ **C-W6.** O Movimento não lista Armas nem Pipeline como upstream (l.
  660–668); nota velha (l. 696–698).
- ⚠️ **C-W7.** Movimento R2 (l. 97–98) diz que roda antes do Combate; o Combate
  R1 (l. 80–81) põe o "início do passo" do Combate antes do Movimento.
- ⚠️ **C-W8.** Um contador só de invulnerabilidade (dano, recusa, esquiva,
  investida), mas o contorno do Pipeline R6 (l. 205–211) é só para a pós-dano e
  a recusa: o Combate precisa expor a origem, ou fixar que o contorno segue o
  total.
- ⚠️ **C-W9.** Alcance do Pulso: 825 px no Conteúdo F6 (l. 530) × 844,5 px
  testados no Combate F5 (OQ7 do Combate).
- ⚠️ **C-W10.** Índice atrás: l. 27/156 (camadas); linha 6 sem Acessibilidade;
  linha 7 sem Combate, Câmaras e IA; linha 8 sem Pipeline; linha 33 sem Pipeline.

### Info

- ℹ️ **C-I1.** Notas de bidirecionalidade e OQs velhas em Pipeline (l. 1219, OQ7),
  Armas (l. 690–692), Combate (l. 1071, OQ6), Input (l. 550–554), Modificadores
  (l. 575–580), Cena (l. 607–612) e Conteúdo (l. 795–799).
- ℹ️ **C-I2.** "OQ9" ambíguo no Pipeline (l. 279, 1211): escrever "Pipeline OQ9".
- ℹ️ **C-I3.** Parallax: o dono é o `CameraTuning`; a nota ² da Cena R4 e a faixa
  da F7 ainda esperam o Pipeline (fundo 1,0, primeiro plano 1,15).
- ℹ️ **C-I4.** Registro confere nos valores lidos; faltam F1–F6 e constantes de
  Armas e as do `VisualTuning`.
- ℹ️ **C-I5.** Pulso 270 → 540 sem resto velho (270 só como dado de teste FP-R).
- ℹ️ **C-I6.** Hitstop coerente entre Cena R7, Combate R10 e Input R6.
- ℹ️ **C-I7.** Recusa coerente (Modificadores R13 × Combate R13.7); o Combate
  atribui `passos(invuln_s)` em vez de `max` (inócuo hoje).
- ℹ️ **C-I8.** OQs do Combate fora de ordem (11 antes de 10).

---

## Game Design Issues

### Blocking

Nenhum nos GDDs aprovados. O **D-W16** é bloqueante para o GDD de Portas e
recompensas.

### Warnings

- ⚠️ **D-W11. Ressonância: fantasia "perto do limite" × mecânica que paga para
  ficar longe.** Pulso de 825 px, 540 de empurrão a cada 14 passos (~174 px/s de
  repulsão), cambaleio ~50% do tempo; a Onda (28% do dano) é o único golpe de
  perto. "Só Pulso" dá 51,4 contra 67,0 combinado: atirar de longe custa ~23% de
  DPS e quase nenhum risco. Opções: (a) recompensar a proximidade (Onda escalada
  pela distância, ou queda do Pulso além de ~400 px); (b) `vida_s` do Pulso ~0,5 s
  (~495 px); (c) reescrever a fantasia como "controle de distância" (CD); (d)
  Telemetria grava a distância média por arma. Recomendado: (b) + (a) leve, no
  playtest. Depende da IA (sem GDD).
- ⚠️ **D-W12. Lâmina com duas fugas invulneráveis e mais Vida.** Invulnerabilidade
  sustentada 45,7% (esquiva 12/42 + Investida 12/70) × 28,6% na Ressonância; 7 ×
  5 golpes da Fenda elite. A paridade (Armas R6) mede só o ataque. A
  invulnerabilidade da Investida não tem sinal visual. Opções: meta de defesa
  como segundo AV; sinal tracejado na Investida; reduzir a invulnerabilidade da
  Investida. Bênçãos devem pôr teto nas cargas de esquiva somadas.
- ⚠️ **D-W13. "Quebrou!" automático com o Ataque segurado.** Na Lâmina, n × R = 48
  e Q = 24 caem na janela de trava dos três inimigos comuns; no MVP não trava só
  porque eles morrem antes. Bênçãos de velocidade de ataque ou regiões mais
  fundas abrem a trava. Recomendado: ampliar o CV18 já (Armas OQ6) e um knob
  `quebrou_imune_s`.
- ⚠️ **D-W14. A invulnerabilidade de 40 passos ao ser atingido achata a multidão e
  a curva.** Teto global de ~1 golpe a cada 0,67 s; o dano do inimigo não sobe
  com a profundidade. Tomar um golpe compra 3,3× uma esquiva de invulnerabilidade.
  Recomendado: o GDD de Câmaras e ondas declara alvo de dano recebido e de
  duração por câmara; testar `invuln_atingido_s` 0,4–0,5 s no playtest.
- ⚠️ **D-W15. Bênção de Ataque ≈ 3× a de Especial** (escolha falsa na Lâmina; real
  na Ressonância só em grupo). Dono: GDD de Bênçãos (efeitos qualitativos no
  Especial, ou magnitude por slot).
- ⚠️ **D-W16. P2 "A Beira cobra" não morde no MVP.** Fragmentos só contam e
  mostram; a porta de Fragmentos é dominada por bênção ou cura; com o D-N2 podem
  sair duas portas mortas. Recomendado: tirar a porta de Fragmentos do sorteio no
  MVP; o GDD de Portas define a cura parcial com números.
- ⚠️ **D-W17. Atenção em multidão.** Osso pinta quase tudo (núcleo do telégrafo,
  números, marca do Quebrou, flash, estrelas, tracejado); 4 decisões ativas no
  MVP, no limite. Donos: VFX, HUD, Telégrafos (números/marcas abaixo de L* 70 em
  multidão; nada do relógio de apresentação cobre um contorno de telégrafo; AC de
  captura de estresse).

### Info

- ℹ️ **D-I8.** O Pulso (825 px) alcança mais que meia altura da vista (540): IA e
  Telégrafos garantem aviso visível de ataques vindos de fora da tela.
- ℹ️ **D-I9.** A paridade é de um alvo; as câmaras são de grupo. Telemetria grava
  dano recebido por câmara e distância média.
- ℹ️ **D-I10.** Cortes exatos de golpes até morrer (80/16, 80/10, 100/10): a Oficina
  e o Muro de Pedras vão cruzá-los.
- ℹ️ **D-I11.** O telégrafo perde o flash no pico (limitador cheio); Telégrafos
  garante a leitura sem flash.
- ℹ️ **D-I12.** Congelamento real da Lâmina no combinado é 25% (abaixo do CV2 33%).
- ℹ️ **D-I13.** Fantasia coerente, exceto D-W11 e D-W13.
- ℹ️ **D-I14.** D-W6 mitigado, não fechado (Corte da esquiva sem teto de M).

### NOT ASSESSED (dentro da fase 3)

- **3a progressão** e **3d economia:** sem GDD de Economia, Oficina, Desbloqueio,
  Portas, Selo e Fluxo. Requisitos para eles: D-W1, D-W2, D-W5, D-W8, D-N5,
  D-W16; armas horizontais sem grind; P4 sem FOMO.
- **3e alvos de dificuldade:** nenhum GDD define TTK por câmara, duração de
  câmara ou dano recebido; a IA não existe (D-W11 e D-W12 não provados).

---

## Cross-System Scenario Issues

Scenarios walked: 6 — S1 combo da Lâmina num Eco em preparação · S2 esquiva no
passo do projétil · S3 recusa × Pulso que limpa a câmara · S4 abate de chefe com
cadeia e transição · S5 troca de câmara com investida e esquiva · S6 pausa no
meio do hitstop.

### Blockers

🔴 **S-B1. A transição de câmara não tem estado de jogo nem ordem.** Combate
l. 272–274 (troca em passo vivo, zera o hitstop, V1 apaga VFX); Movimento R1
(teleporte cancela a esquiva); Cena R10 l. 228 (a câmera corta ao entrar);
Pipeline R7/F8 (o wipe troca câmara e LUT e zera os relógios na metade; `t_vivo`
parado na Transição); Input R10 sem contexto "Transição". **Decisão do usuário
(2026-11-10):** estado de jogo "Transição" no orquestrador (mundo em
`passo_congelado()`, Input sem ações, buffer esvazia); teleporte, "câmara nova",
hitstop zerado, VFX apagados, corte da câmera, LUT e zero dos relógios no quadro
da metade do wipe; investida e recuperação zeram na câmara nova (fecha o S-W2).

🔴 **S-B2. A câmara limpa sai com hitstop pendente.** O último abate pede ≥ 4
passos no item 9 e a câmara limpa é avaliada no item 10; a Bênção não roda o
Combate. **Decisão do usuário (2026-11-10):** "câmara limpa" só é publicada, e a
Bênção só abre, com hitstop = 0 (Combate R10/R14, contrato para Câmaras e Run;
Pipeline liga a espera da Bênção ao fim do hitstop).

### Warnings

- ⚠️ **S-W1.** S1: o toque de Ataque guardado no hitstop do Corte sempre expira
  antes da recarga (disponível de s+7 a s+15; recarga zera em s+22). Opções:
  aceitar e documentar ("segurar repete"), ou o prazo de Ataque/Especial só
  desconta com a recarga do slot em 0.
- ⚠️ **S-W2.** S5: investida e recuperação passavam para a câmara nova — resolvido
  pela decisão do S-B1.
- ⚠️ **S-W3.** S3: a recusa negada pelo limitador deixa 18 passos congelados sem o
  impact frame. Opção: sinal de reserva fora do limitador (inversão segurada pelos
  18 passos).
- ⚠️ **S-W4.** S4: as mortes que sobram da cadeia saem depois do hitstop do chefe,
  com um segundo congelamento. Opção: passe extra para as mortes causadas pelo
  chefe, ou sem hitstop próprio.
- ⚠️ **S-W5.** S6: o Combate não diz que o contador de hitstop para na pausa.
  Correção: "fora de Jogo o orquestrador não executa a R1; o hitstop não
  desconta".
- ⚠️ **S-W6.** S1: o telégrafo de um inimigo morto durante a preparação não tem
  regra (V9 só parte no Quebrou). Correção: na V12, "morto em preparação: o
  telégrafo se parte como na V9.1, sem letreiro"; contrato de Telégrafos.

### Info

- ℹ️ **S-I1.** Estrela pesada (V6) e leve (V12) se sobrepõem no golpe que mata.
- ℹ️ **S-I2.** O Corte da esquiva não tem `peso_visual` claro; V14 sem linha para
  Corte e reflexo.
- ℹ️ **S-I3.** As imagens residuais duram D + E fixos, mas o texto diz que somem
  quando a invulnerabilidade acaba.
- ℹ️ **S-I4.** Ordem dos efeitos da recusa (inversão × impact frame no mesmo
  passo): a inversão pode nunca aparecer.
- ℹ️ **S-I5.** Base do reflexo: Combate usa `vida_perdida` (dano − absorvido); o
  Modificadores diz "o que o jogador de fato perdeu".
- ℹ️ **S-I6.** A recusa atribui a invulnerabilidade em vez de `max` (= C-I7).
- ℹ️ **S-I7.** Impact frame do chefe em quadros (= C-W3).
- ℹ️ **S-I8.** Pausa e engasgo desencontram câmera (impulsos zerados), impact
  frame e hitstop.

Resultado por cenário: S1 problema · S2 ok · S3 problema · S4 problema · S5
problema · S6 problema.

---

## GDDs Flagged for Revision

| GDD | Razão | Tipo | Prioridade |
|---|---|---|---|
| cena-3-4-e-camera.md | C-B1, S-B1; C-W5, C-I1, C-I3, S-I8 | Consistência | Blocking |
| combate-nucleo.md | C-B2, S-B1, S-B2; C-W1, C-W3, C-W5, C-W8, S-W3–S-W6, C-I7, C-I8 | Consistência | Blocking |
| pipeline-visual.md | S-B1, S-B2; C-W4, C-W8, C-I1, C-I2 | Consistência | Blocking |
| input-e-controle.md | S-B1 (contexto Transição); C-W7, S-W1, C-I1 | Consistência | Blocking |
| conteudo-orientado-a-dados.md | C-W2, C-W9, C-I1 | Consistência | Warning |
| movimento-e-esquiva.md | C-W6, C-W7, S-I3 | Consistência | Warning |
| armas-das-doutrinas.md | C-W4, D-W11, D-W12, C-I1 | Consistência / Design | Warning |
| modificadores-e-atributos.md | C-W4, S-I5, C-I1 | Consistência | Warning |
| systems-index.md | C-B1, C-W1, C-W10 | Consistência | Warning |
| design/registry/entities.yaml | C-I4 | Consistência | Info |

Decisão do usuário (2026-11-10): **corrigir agora e manter os GDDs Approved**, com
nota no cabeçalho de cada um, conferido por subagente; o índice não é marcado
como Needs Revision.

---

## Cobertura

- Fase 2 não conferiu: o texto da R6 do Input (C-W7); unidades das F3/F4/F10 do
  Pipeline contra a F6 da Cena; F7 do Combate × F7 do Conteúdo; relógios da F8 do
  Pipeline × relógio da Cena R12; Cross-References linha a linha; Interactions do
  Combate (l. 483–500) e do Pipeline (l. 429–443); Circular Dependencies do
  índice; faixas do `ArmasTuning` × CV do Combate; o GDD de RNG (só pelo 06b);
  registro além da l. ~545.
- Fase 3 não leu o registro nem os Overviews de Conteúdo, RNG e Input.

## Status dos itens do 06b

- **Fechados:** D-N1 (vale o maior); C-W1–C-W4, S-W4, C-I2 (aplicados em
  2026-11-06); S-W2 quase fechado.
- **Abertos:** C-I1, C-I5, C-I7 (não conferidos); C-I3 (Chefes); C-I8 (Pactos,
  Alpha); D-N2–D-N5, D-W1–D-W5, D-W7–D-W10, D-I6 (sistemas sem GDD); D-W6
  parcial.

---

## Verdict: FAIL

Quatro bloqueantes de contrato entre documentos (C-B1, C-B2, S-B1, S-B2), nenhum
de redesenho. Os avisos de design (D-W11–D-W17) são requisitos para os GDDs que
ainda vêm (IA, Câmaras e ondas, Portas, Bênçãos, VFX, Telégrafos, Selo e Fluxo).

### Required actions before re-running

1. Cena: camada `contorno de telégrafo` (z 5), "11 camadas", AC-09/AC-10, OQ1;
   corte da câmera na metade do wipe (R10).
2. Combate: campos `_s` das durações visuais no `CombatTuning` e nos eventos da
   R17; estado "Transição" no orquestrador (R1) e "câmara nova" no meio do wipe
   zerando hitstop, investida e recuperação; câmara limpa só com hitstop = 0;
   o hitstop não desconta fora de Jogo.
3. Pipeline: a Bênção espera o fim do hitstop; a troca de câmara, LUT e relógios
   no quadro da metade do wipe coincidem com o estado "Transição" do Combate.
4. Input: contexto "Transição" (sem ações de jogo, buffer esvazia).
5. Índice: "11 camadas de render (9 de arte)".

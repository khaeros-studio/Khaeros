# Khaeros — Conceito do Jogo e Pilares

> **Status:** v1.0 — **APROVADO pelo Creative Director em 2026-11-05.** Pendências 3–7 da §13 seguem abertas.
> **Data:** 2026-11-05 · **Engine:** Godot 4.7 / GDScript (ver `project.yaml`)
> **Fonte da verdade do universo:** `C:\Users\lucas\Desktop\Khaeros` (repo Khaeros).
> Este documento **traduz** o cânone para o jogo novo; nunca reescreve o cânone.
> Onde os dois discordarem, o repo Khaeros vence até o CD decidir o contrário.

## Legenda de status (usada em todo o documento)

| Marca | Significado |
|---|---|
| **[CÂNONE]** | Existe no repo Khaeros, com fonte citada. Não se altera aqui. |
| **[ADAPTAÇÃO]** | Cânone traduzido para ação/Godot; a ideia é canônica, a forma é nova. |
| **[PROPOSTA]** | Invenção nova, para o CD aprovar. Nada marcado assim é cânone ainda. |
| **[DESCARTADO]** | Invenção do protótipo "Eco das Brasas" — não usar (o CD disse que fez a ideia se perder). |

---

## 1. Pitch

**Um roguelike de ação sala-a-sala, em câmera 3/4, em que um Iniciado da
Universidade desce à Beira — a zona instável onde o Colapso ainda respira — e
volta mais forte, ou não volta, a cada tentativa, carregando as Tradições dos
seus Mestres como bênçãos.**

Referência de jogabilidade: **Hades II** (estrutura, câmera, combate, interface).
Nada de Hades é copiado — nem arte, nem personagens, nem nomes, nem textos.
Tudo o que aparece na tela é de Khaeros.

**Referência secundária: Mark of the Deep** (Mad Mimic, 2025; aventura de
exploração com combate de ritmo "soulslike"; pesquisa rápida em resenhas, 2026-11-13).
É referência de *sensação de combate e ritmo*, não de estrutura: o jogo é
metroidvania, e Khaeros segue sala a sala. Nada dele é copiado (arte, nomes,
mundo, textos, sistemas). O que ele empresta, sem mudar os pilares P1 a P5 nem o
escopo do MVP:

| Empréstimo | Onde já vive em Khaeros |
|---|---|
| Golpe com compromisso e leitura de janela: o jogador paga por errar o tempo, em vez de apertar botão sem custo | P3 (todo ataque é telegrafado; a esquiva sempre responde) e Combate núcleo (combo da Lâmina, o terceiro golpe pesado) |
| Peso do impacto: hitstop e resposta no corpo que acerta e no que é atingido | Combate núcleo (hitstop de 3 e 6 passos) e Feedback de combate |
| Armas novas que mudam o ritmo, não só os números | Armas das Doutrinas (uma por Doutrina) |

**O que evitar** (críticas recorrentes às resenhas do jogo): combate lento por
inimigo básico exigir golpes demais, e prioridade de animação alta demais, que
faz o jogador levar golpe no meio de uma ação já iniciada. Khaeros mantém o
ritmo de Hades II, com resposta rápida ao comando do jogador. O protótipo do combate
(`prototypes/combate-camara-concept/`) é onde se confere isso, jogando.

Fontes: resenhas e páginas de imprensa do jogo; não houve acesso à
documentação oficial de combate, então o resumo acima descreve a recepção
crítica e não o sistema interno.

## 2. Fantasia do jogador

Ser um aprendiz que **escolheu uma filosofia** (Doutrina) e a prova no lugar mais
perigoso do mundo. Cada bênção não é "mais dano": é uma **escola de pensamento
sobre a Maldição** que o jogador aceita carregar ([CÂNONE] — Doutrinas/Tradições
são "escolas de pensamento sobre a Maldição/Colapso", `baseline.md` §1). A Beira
cobra um preço por cada passo ([CÂNONE] Inviolável II, "A Beira Contada").

O jogador **escolhe o nome do seu Iniciado** ([PROPOSTA] — decisão do CD,
2026-11-05). O papel continua o canônico: "o Iniciado" que jura uma Doutrina no
Rito de Iniciação (`baseline.md` §54.6, Ficha do Iniciado §57.5).

## 3. Pilares de design

Os pilares abaixo derivam dos **7 Pilares congelados** de Khaeros
(`baseline.md` §2) e da revisão do pivô para ação (§54.2). Cada um diz de onde
vem.

| # | Pilar | O que significa na prática | Origem |
|---|---|---|---|
| P1 | **Toda bênção é uma filosofia** | A escolha de Tradição define o build e a identidade da run. Cartas dizem *o que a Tradição acredita*, não só o número. | Pilar 5 "Pertencimento por Filosofia" + §54.4 (18 Tradições → 18 bênçãos) |
| P2 | **A Beira cobra** | Toda vantagem tem preço visível: portas de risco (Altar de Provação), Vida que não volta inteira, troca de oferta limitada. Nada é de graça. | Pilar 4 "Escassez Real" + Inviolável I (Preço Equivalente) e II (Beira Contada) |
| P3 | **Reflexo que se lê** | Todo ataque inimigo é telegrafado no chão; a esquiva com invulnerabilidade sempre responde. Morrer tem que parecer culpa do jogador, nunca do jogo. | Pilar 2 rebalanceado (§54.2) + game feel (§55: hitstop, buffer, cancelamento) |
| P4 | **Ritual, não pressão** | Run curta, volta ao Campus, conversa, melhora, desce de novo. Sem FOMO, sem diária obrigatória. | Pilar 6 "Retenção por Ritual" |
| P5 | **O mundo não se explica de uma vez** | Lore chega em fragmento, nunca em biografia. Mistérios congelados continuam mistérios. | Lore Freeze v1.0 + Doc Nº 018 §3 ("fragmento, nunca biografia") |

**Anti-pilares (o que este jogo NÃO é):**
- Não é online, nem MMO, nem tem monetização. É single-player, PC.
- Não cria cosmologia nova (o Colapso, a Mentira e os 7 Invioláveis seguem sem conteúdo novo).
- Não é uma recriação de Hades: a estrutura de gênero é a referência, a identidade é Khaeros.

**Pilares de Khaeros que NÃO se aplicam a este jogo** ([PROPOSTA] — confirmar):
- Pilar 1 "A Interface É o Mundo" — já substituído no modo de ação (§54.2).
- Pilar 7 "Mobile-First" — este jogo é PC (Windows), teclado/mouse + gamepad parcial.
- Zero-Trust/servidor/replay determinístico (§54.3) — premissas técnicas do
  modo web; o jogo Godot é offline. O **determinismo** pode voltar se houver
  ranking online no futuro.

## 4. Loop principal

```
Campus (hub) ─► Rito/escolha de arma ─► Run na Beira ─► morte ou vitória ─► Campus
   ▲                                       │
   └── Oficina de Reforja (Fragmentos) ◄───┘
```

**Run** ([ADAPTAÇÃO] de `arenaContent.ts` `ARENA_REGIONS`):
1. **Limiar da Beira** — 7 câmaras (combate ×3, Santuário, combate ×2, chefe **Anomalia Maior**).
2. **Veio Instável** — 7 câmaras (combate ×2, Santuário, combate ×3, chefe **Guardião do Rito**).

**Câmara:** porta fecha → ondas de inimigos → câmara limpa → recompensa
aparece → portas abrem mostrando a **próxima recompensa** → jogador escolhe.

**Recompensas de porta** ([CÂNONE] tipos já existentes no modo de ação):
bênção de Tradição, Fragmentos de Eco, cura, **Altar de Provação** (porta
opcional de risco: elites em toda onda, +3 Fragmentos, bênção Rara+, §56.4),
Santuário Esquecido (descanso).

**Entre runs:** Fragmentos de Eco compram melhorias permanentes na **Oficina de
Reforja** ([CÂNONE] §57.2 — Vigor do Juramento, Ímpeto da Doutrina, Fluxo
Profundo, Fôlego da Beira, Juramento Renovado, Recusa dos Que Ficam).

## 5. Estrutura de Hades II → equivalente em Khaeros

| Elemento do gênero (ref. Hades II) | Em Khaeros | Status |
|---|---|---|
| Ataque | Ataque da arma da Doutrina (Corte, Pulso, Estocada…) | [CÂNONE] `ARENA_WEAPONS` |
| Especial | Especial da arma (Investida, Onda, Leque de Lâminas…) | [CÂNONE] |
| Esquiva com invulnerabilidade | **Esquiva** (cargas, cancela recuperação) | [CÂNONE] §54.4, §55.2 |
| Feitiço de área | **Selo** — gasta **Fluxo**, área que desacelera e fere | [CÂNONE] §54.4 |
| Bênçãos de deuses em cartas | **Tradições** oferecidas pelos **Mestres** da Doutrina, em cartas, com o jogo congelado | Tradições [CÂNONE]; Mestres como ofertantes [PROPOSTA] — ver §7 |
| Raridade de bênção | Comum / Rara / Épica (×1 / ×1,5 / ×2) | [CÂNONE] `ARENA_RARITY_NAMES` |
| Trocar oferta | "↻ Trocar ofertas", cargas pela Oficina | [CÂNONE] §57.3 |
| Moeda de meta-progressão | **Fragmento de Eco da Beira** | [CÂNONE] |
| Melhorias permanentes (cartas no hub) | **Oficina de Reforja** | [CÂNONE] §57.2 |
| "Desafio à morte" | **Recusa dos Que Ficam** / bênção Os Que Ficam | [CÂNONE] |
| Inimigos elite | Elites (armadura, aura dourada) a partir da profundidade 3 | [CÂNONE] §56.3 |
| Hub com NPCs e conversas | **Campus da Academia** (Universidade da Ressonância) | Local [CÂNONE]; Campus andável [PROPOSTA] (estava em aberto, §54.8) |
| Várias armas trocadas entre runs | 6 armas, uma por Doutrina; a Doutrina jurada é a inicial | [ADAPTAÇÃO] — decisão do CD 2026-11-05, ver §6 |
| Hitstop, buffer de entrada, quebra de guarda | Hitstop, buffer de 10 ticks, "Quebrou!", impacto na parede | [CÂNONE] §55.2 |

## 6. Armas — uma por Doutrina, coerente com a filosofia

**Decisão do CD (2026-11-05):** o jogador pode trocar de arma entre runs, mas
cada arma é **desenhada para a filosofia da sua Doutrina**. A arma inicial é a
da Doutrina jurada no Rito de Iniciação; as outras se liberam com Fragmentos.
Exemplo dado pelo CD: quem faz pacto com criaturas não luta de espada, escudo e
armadura pesada — luta **de longe** enquanto a criatura do pacto luta por ele.

| Doutrina | Filosofia ([CÂNONE] Doc Nº 002/019) | Arma | Ataque / Especial | Status |
|---|---|---|---|---|
| **Lâmina** | foco, timing, ímpeto | Lâmina do Juramento (espada) | Corte em combo / Investida | [CÂNONE] `ARENA_WEAPONS.BLADE` |
| **Guardião** | imutabilidade, sacrifício defensivo | Escudo-Bastião (escudo + golpe pesado, armadura) | Golpe de Escudo / Muralha (reduz dano) | [CÂNONE] |
| **Véu** | ocultação, ação indireta | Adagas do Véu | Estocadas rápidas com Sangramento / Leque de Lâminas | [CÂNONE] |
| **Ressonância** | risco calculado perto do limite | Foco Ressonante (cajado/foco) | Pulso à distância / Onda de Ressonância | [CÂNONE] |
| **Transmutação** | adaptação, nada se desperdiça | Cálice da Transmutação | Gota Corrosiva (Queimadura) / Transmutar à distância | [CÂNONE] |
| **Pactos** | vínculo, o fardo nunca é carregado sozinho | **Besta do Vínculo** (arma de longo alcance) + **criatura do pacto** que luta corpo a corpo | Virote à distância / **Chamado do Pacto** (a criatura avança, segura e atrai inimigos) | **[ADAPTAÇÃO — aprovada 2026-11-05]** — substitui o "Laço dos Pactos" (chicote) do modo web |

**Por que Pactos muda:** o "Laço dos Pactos" atual é um chicote corpo a corpo
que cura. A nova versão segue a decisão do CD **e** o cânone dos romances: Serel,
dos Pactos, tem vínculo com a **Sombra Muda**, uma Anomalia resgatada que age com
ela (Vol. I/II). A criatura do pacto do jogador é **da mesma natureza** — um
resíduo de Anomalia vinculado — sem ser a Sombra Muda (que é de Serel). A
Combat Bible já previa "Invocação com entidade própria" como proposta
(`GDD_CombatBible_CoreLoop_Tradicoes.md` §1.3, Fase 2B: vínculo com estado, sem
IA de aggro completa) — este jogo é onde ela nasce.

**Aspectos (variantes de arma):** fora do MVP. Se entrarem, cada Doutrina terá
3 aspectos, um por Tradição ([PROPOSTA] — combina com 6 × 3 = 18).

## 7. Mestres e bênçãos

**Decisão do CD (2026-11-05):** as bênçãos são oferecidas pelos **Mestres** de
cada Doutrina, ao estilo das bênçãos divinas do gênero. O CD abriu exceção de
Lore Freeze para criar os Mestres que faltam e registrar no repo Khaeros
(`docs/NARRATIVE_Mestres_Bencaos_Modo_Acao.md`).

**Como funciona dentro do mundo ([CÂNONE — aprovado 2026-11-05]):** o Mestre não está na Beira. Antes
da descida, cada Mestre "sintoniza" o Iniciado (o mesmo ato de ensinar uma
Tradição no Campus); dentro da Beira, quando uma câmara é limpa, o Fluxo
liberado faz essa sintonia **ressoar**, e a voz do Mestre chega por um instante
oferecendo três leituras da sua Doutrina. Escolher é aceitar a Tradição — e o
preço dela.

| Doutrina | Mestre que oferece | Status |
|---|---|---|
| Lâmina | **Mestre Halvar** | [CÂNONE — aprovado 2026-11-05] — nome novo, Mestre vivo do Campus (Tamsen é a fundadora histórica e **nunca aparece em cena**) |
| Guardião | **Mestre Berrin** | [CÂNONE] — Romance Vol. I (expedição à Zona) |
| Véu | **Mestra Endra** | [CÂNONE] — Romance Vol. I (Cap. 44) |
| Ressonância | **Mestra Maren** | [CÂNONE — aprovado 2026-11-05] — nome novo, Mestra viva (Corah é a fundadora histórica) |
| Transmutação | **Mestra-Conselheira Oreth** | [CÂNONE — aprovado 2026-11-05] — dá nome à "Mestra-Conselheira da Transmutação" que já existe sem nome no Vol. I |
| Pactos | **Mestre Sorcha** | [CÂNONE] — Romance Vol. I/II; continua valendo "Pactos sem fundador nomeado" (Sorcha é professora viva, não fundadora) |

**As 18 bênçãos** são as 18 Tradições com os **nomes canônicos de
`traditions.ts`** (nunca reescritos) e os efeitos de ação já definidos em
`arenaContent.ts` `BOON_EFFECTS` ([CÂNONE] — números são placeholders, regra 4).
Exemplos: O Traço Único (+25% dano do Ataque), O Corte Fantasma (a esquiva
corta), O Fundo do Poço (abaixo de 50% de Vida, +40% de dano), Os Que Ficam
(recusa a morte uma vez), A Matéria Residual (inimigos explodem ao morrer).

**Fora do MVP ([PROPOSTA]):** bênçãos de duas Doutrinas combinadas (equivalente
às "duo" do gênero) — exigem desenho próprio e combat-lab.

## 8. Mundo do jogo

| Elemento | Descrição | Status |
|---|---|---|
| **Campus da Academia / Universidade da Ressonância** | Hub entre runs; centro político e social, "cidade-estado"; instituição falível | [CÂNONE] Compilado §6–7 |
| **A Beira** | Zona instável onde a fronteira entre o Portador e sua própria beira afina; cobra algo pequeno a cada passo | [CÂNONE] Inviolável II, GDD Expedições |
| **Limiar da Beira** (*A Beira Contada*) | Região 1, mais calma | [CÂNONE] `BEIRA_LIMIAR` |
| **Veio Instável** (*As Profundezas*) | Região 2, mais hostil, veios de Fluxo cru | [CÂNONE] `BEIRA_VEIO_INSTAVEL` |
| **Santuário Esquecido** | Câmara de descanso — "um abrigo de pedra que alguém manteve de pé por tempo demais pra ter sido acaso" | [CÂNONE] |
| **Fragmento de Eco da Beira** | Moeda que sai da run | [CÂNONE] |
| **Altar de Provação** | Porta opcional de risco/recompensa | [CÂNONE] §56.4 |
| **Câmaras** | As salas fechadas da run | [CÂNONE] — "câmara" é o termo do modo de ação |
| "Câmaras de Ancoragem" | **Não existe no cânone.** O termo veio do protótipo Eco das Brasas (`mainMenu.ts`). | [DESCARTADO] — usar só "câmara" |
| Beira Profunda (3ª região), Cidade da Cratera | Congelados de propósito, aguardando o CD | **Fora do jogo** até decisão |

**Inimigos** ([CÂNONE] `ARENA_ENEMIES`, derivados dos encontros canônicos):

| Região | Inimigo | Comportamento |
|---|---|---|
| Limiar | Eco Perdido | corpo a corpo |
| Limiar | Anomalia Menor | à distância |
| Limiar | Fenda Errante | investida |
| Veio | Eco do Veio | corpo a corpo, mais rápido |
| Veio | Anomalia do Veio | à distância |
| Veio | Estilhaço Vivo | investida pesada |

**Chefes** ([CÂNONE]): **Anomalia Maior** ("a instabilidade aqui ganhou forma e
fome — maior, mais lenta, mais perigosa de ignorar") e **Guardião do Rito**
(título/função, sem biografia — Compilado §8).

## 9. Regras de Lore Freeze aplicadas a este jogo

Herdadas de `KHAEROS_COMPILADO_MESTRE_001-017.md` §10, com a exceção aberta pelo
CD em 2026-11-05:

1. **Não criar países, Doutrinas nem cosmologia.** O Colapso, a Mentira e os 7
   Invioláveis não ganham conteúdo novo aqui.
2. **Mestres novos só os 3 da §7**, com registro no repo Khaeros. Nenhum
   fundador novo de Tradição. Pactos continua sem fundador nomeado.
3. **Fragmento, nunca biografia.** Texto de jogo (cartas, Santuário, fragmentos
   de lore) não nomeia Mestres-Conselheiros, Cidades-Bastião, a Cratera nem
   resolve mistério dos romances — mesma regra do teste `beiraExpedition.test.ts`.
4. **Personagens dos romances** (Serel, Vahn, Ren, Yenna, Naeve, Isarn) **não
   têm arco no jogo** sem decisão do CD; podem, no máximo, ser mencionados.
5. **Toda invenção nasce [PROPOSTA]** e só vira cânone com sign-off do CD,
   registrado no repo Khaeros.

## 10. O que foi descartado do protótipo "Eco das Brasas"

[DESCARTADO], por decisão do CD (a ideia se perdeu):
- o título "Eco das Brasas";
- as Doutrinas inventadas "Brasas" e "Tempestade";
- os Mestres Ardhe, Sael, Korvan, Imre e Vaelis;
- os biomas Campus Abandonado, Bosque de Vidro e Santuário Submerso;
- o termo "Câmaras de Ancoragem" e "Beira Malfeita";
- os chefes Guardião de Coral, Sacerdotisa de Vidro, Batráquio Colossal e Coração
  do Colapso **como personagens/nomes** (a arte pode ser reaproveitada — §12).

**Mantido do protótipo** (técnica, não lore): câmera 3/4 com chão achatado,
chão pintado contínuo com bordas orgânicas e a pipeline de recorte do verde em
`eco-das-brasas/tools/`.

## 11. Direção de arte e câmera (referência de gênero, não cópia)

- **Câmera 3/4** com o chão achatado; personagem **pequeno na tela** (~1/12 da
  altura), arena inteira visível ou quase.
- **Câmaras fechadas** com bordas **pintadas e orgânicas** (sem grade de tiles
  aparente) e **primeiro plano em silhueta** escura emoldurando a tela.
- **Telégrafos no chão** (círculos, cones, linhas) para todo ataque inimigo.
- **Estilo de quadrinho**: traço preto grosso, cel-shading de 2–3 tons, acentos
  de cor saturada. Paleta de Khaeros: escuros frios + **magenta de Fluxo** +
  dourado de elite/ritual (o protótipo já chegou nisso).
- **Interface**: cartas de bênção com o jogo congelado, portas com o ícone da
  recompensa, HUD mínimo (Vida, Fluxo, cargas de esquiva, Fragmentos).
- Detalhamento vem no **Art Bible** (`/art-bible`), não aqui.

## 12. Arte pronta (Nano Banana) — avaliação

Fonte: `Khaeros/eco-das-brasas/art-in/` + `manifest.json`. Fundo verde #00FF00.
Achado geral: há **dois estilos misturados** — ilustração de quadrinho com
contorno (inimigos, chefes, retratos) e **pixel-art isométrica** (dioramas,
algumas poses). O Art Bible precisa escolher **um**; a recomendação é a
ilustração de quadrinho, que é a que se aproxima do alvo.

| Arte | Serve? | Uso proposto |
|---|---|---|
| **Iniciado** — ficha (frente/lado/costas) + 8 poses de frente + 8 de costas | ✅ Serve | Protagonista. A espada combina com Lâmina; outras Doutrinas precisam da arma trocada. Regerar as poses no estilo final se o Art Bible escolher quadrinho. |
| **Retratos do Iniciado** (várias versões, inclusive um rosto masculino de pele mais escura) | ✅ Serve | Retrato de diálogo; as variações podem virar opções de aparência na criação do personagem ([PROPOSTA]). |
| **Armas**: espada, cajado, adagas | ✅ 3 de 6 | Lâmina, Ressonância (foco), Véu. **Faltam:** escudo + arma pesada (Guardião), cálice (Transmutação), **besta** (Pactos) e a **criatura do pacto**. |
| **Espectro** encapuzado | ✅ | **Eco Perdido** (e variante recolorida = Eco do Veio). |
| **Lodo** com olhos | ✅ | **Anomalia Menor** (à distância). |
| **Golem de cristal** (verde-água) / golem de coral (rosa) | ✅ | **Estilhaço Vivo** (investida pesada). |
| **Aranha de cristal**, **vespa de cristal** | ⚠️ Proposta | **Anomalia do Veio** / **Fenda Errante**, lidas como "a instabilidade que ganhou forma" imitando bichos. Precisa do aval do CD. |
| **Carapaça** (caranguejo vermelho), **inseto** (besouro laranja), **anfíbio** (sapo) | ⚠️ Reserva | Sem lugar canônico hoje; guardar para variantes ou descartar. |
| **Soldado** (armadura escura, lança e escudo) | ⚠️ Proposta | Base visual para o **Guardião do Rito** (regerar em escala de chefe). |
| **Batráquio Colossal** (sapo gigante com cristais e vórtice magenta) + arte de apresentação | ✅ Visual / ❌ Nome | **Anomalia Maior** — combina com o texto canônico "ganhou forma e fome — maior, mais lenta". Regerar a arte de apresentação com o nome certo (a atual diz "Chefe do Ato II"). |
| **Sacerdotisa de Vidro** | ❌ | Personagem do protótipo; não tem papel canônico. Alternativa ao Soldado para o Guardião do Rito só se o CD quiser. |
| **Coração do Colapso** (3 ovos/núcleos) | ❌ | Toca a cosmologia congelada do Colapso. Descartar. |
| **Dioramas isométricos** (floresta, ruínas, portal magenta) | ⚠️ Referência | Bom clima, mas pixel-art isométrica não é o chão 3/4 pintado. Usar como referência de clima, não como asset. |
| **Ícones e molduras de UI** (grades de itens, molduras de carta, painéis) | ⚠️ Parcial | As molduras servem de referência; os rótulos são do protótipo. Regerar com os nomes canônicos. |

Os prompts antigos (`eco-das-brasas/docs/PROMPTS_NANO_BANANA.md`) servem como
base técnica (fundo verde, bloco de estilo), mas precisam trocar todo nome do
protótipo pelos canônicos. Isso será feito em `/asset-spec`, depois do Art Bible.

## 13. Decisões pendentes (do CD)

| # | Pendência | Recomendação |
|---|---|---|
| 1 | ~~Aprovar os 3 Mestres novos~~ | ✅ Aprovado 2026-11-05 |
| 2 | ~~Besta do Vínculo + criatura do pacto~~ | ✅ Aprovado 2026-11-05; detalhar no GDD de combate |
| 3 | Campus andável (como o hub do gênero) ou menu | Andável, pequeno, no 2º marco (o MVP pode ser menu) |
| 4 | Uso de aranha/vespa de cristal como Anomalias | Aprovar a leitura "instabilidade imita forma" |
| 5 | Guardião do Rito: base Soldado ou Sacerdotisa | Soldado (armadura = rito, guarda) |
| 6 | Estilo único: ilustração de quadrinho ou pixel-art | Ilustração de quadrinho com traço preto |
| 7 | Rito de Iniciação jogável dentro do jogo (escolha da Doutrina inicial + nome) | Sim, como tutorial curto |

## 14. Fontes consultadas (somente leitura)

- `Khaeros/docs/baseline.md` §1–3, §54–57
- `Khaeros/CLAUDE.md` (estado atual, regras de governança)
- `Khaeros/packages/combat-rules/src/arenaContent.ts`, `traditions.ts`
- `Khaeros/docs/KHAEROS_COMPILADO_MESTRE_001-017.md` §2–12 (cosmologia, Lore Freeze)
- `Khaeros/docs/GDD_Expedicoes_Beira.md` §1, §3–4
- `Khaeros/docs/GDD_Biblia_Integracao_Gameplay_Lore.md` §1–4
- `Khaeros/docs/GDD_CombatBible_CoreLoop_Tradicoes.md` (índice, §1.3)
- `Khaeros/docs/NARRATIVE_Mestres_Nomeados_Piloto.md` §0, `..._Expansao_Lamina_Ressonancia.md` §3
- `Khaeros/docs/ROMANCE_VOL_2.md` §2–3, `ROMANCE_VOL_3.md` (índice), `content/ebook/` (Mestres citados)
- `Khaeros/eco-das-brasas/art-in/manifest.json` + as 43 imagens

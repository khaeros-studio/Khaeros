# Cross-GDD Review Report (2ª passada)

Date: 2026-11-06 (segunda revisão do dia; a primeira, FAIL, está em `gdd-cross-review-2026-11-06.md`)
GDDs Reviewed: 5 of 5 present
Not read: none
Focus: full
Systems Covered: Conteúdo orientado a dados (1), Modificadores e atributos (2), RNG com seed (3), Input e controle (4), Cena 3/4 e câmera (5)
Pilares: P1 Toda bênção é uma filosofia · P2 A Beira cobra · P3 Reflexo que se lê · P4 Ritual, não pressão · P5 O mundo não se explica de uma vez. Anti-pilares: não é online/MMO/monetizado; não cria cosmologia nova; não é recriação de Hades.
Registro: `design/registry/entities.yaml` (3 fórmulas do Conteúdo e RNG, 3 de Modificadores, 5 constantes), usado como base. Nenhum GDD diverge dos valores registrados (`tick_rate` 60, `unit_to_px` 1,5, `input_buffer_steps` 10, `damage_reduction_cap` 0,6, `player_min_max_hp` 20).

Status no índice durante a revisão:
- Conteúdo, RNG e Input: **Approved**;
- Modificadores e Cena 3/4: **In Review**. Os dois voltaram para In Review quando receberam os warnings da 1ª passada. Esta revisão conferiu essas mudanças, mas não substitui o `/design-review` de cada um.

> **Execução:**
> - As fases 2 e 3 rodaram como subagentes `game-designer` em paralelo. Eles leram os GDDs por seção, porque os 5 juntos têm ~240 KB e não cabem no prompt.
> - A conferência dos achados da 1ª passada e a fase 4 foram feitas na sessão principal. Ela leu por inteiro as Core Rules, Interactions, Edge Cases, Dependencies, Cross-References e ACs do Conteúdo, e os trechos correspondentes do Input, da Cena e do Modificadores. O RNG, que não muda desde 2026-11-05, foi lido só por busca.
> - **Cobertura da fase 2:** parou no limite de passos e entregou o que tinha. Não leu o RNG (a sessão principal cobriu por busca), nem a maioria dos ACs do Input e da Cena, nem o corpo das F1–F8 do Conteúdo.
> - **Cobertura da fase 3:** não leu Summary nem Game Feel do Conteúdo, do RNG e do Input. Nenhum dos 5 GDDs tem Player Fantasy, que é advisory no `standard`.
> - TTK, alvo de vitória e duração de câmara: **NOT ASSESSED — NO DATA**, como na 1ª passada.

---

## Conferência da 1ª passada

| Item | Estado | Evidência |
|---|---|---|
| 🔴 C-B1 tokens de sala e recompensa | ✅ resolvido | Conteúdo R2 l. 136–137 (`combate`/`santuario`/`chefe`; `bencao`/`fragmentos`/`cura`/`provacao`); donos na R8 l. 231–232; `chefe` reservado l. 243; V4 l. 258; AC-12, AC-39, AC-48 |
| 🔴 S-B1 tela de erros sem `InputTuning` | ✅ resolvido | Conteúdo Edge Cases l. 727–731, UI l. 826–829, AC-51; Input R12 "Sem catálogo" l. 279–286, AC-38 |
| C-W1 tokens de forma | ✅ | Modificadores R12 l. 253–256, l. 272–273 |
| C-W2 `ModifiersTuning` | ✅ | Conteúdo R1 l. 94, Interactions l. 371, Dependencies l. 759; Modificadores l. 100–108; OQ6 fechada |
| C-W3 params divergentes | ✅ | Conteúdo V11 l. 265 e AC-50; Modificadores Edge Cases l. 502–506 e AC-26 |
| C-W4 cambaleio do chefe | ✅ | Conteúdo l. 673–680 (Combate e IA; Chefes confirma) |
| C-W5 arma de Pactos | ✅ | Modificadores R12 l. 264–270; AC-29 com o Corte da Lâmina do Juramento (nome canônico, `arenaContent.ts:29–32`) |
| C-W6 Cena ↔ Input | ✅ | Cena Interactions l. 251 e Dependencies l. 572; índice nas linhas 4 e 5 e na Foundation Layer |
| C-W7 hitstop × `time_scale` | ✅ | Cena R7 l. 182–188, Edge Cases l. 547–549, AC-28 l. 775–777; requisito para o Combate |
| C-W8 dono dos valores de hitstop | ✅ | Cena F5 l. 412–422, Game Feel l. 622–623 |
| C-W9 `unit_to_px` | ✅ | Cena R2 l. 83–86, F1 l. 277–295, AC-07 l. 695–701; Conteúdo l. 375 |
| C-W10 raio inclusivo | ✅ declarado | Input R5 l. 130–131, F4 l. 411, AC l. 657 |
| C-I1 a C-I4 | ✅ | — |
| C-I5 Depends On da Cena no índice | ⏳ aberto | `systems-index.md` l. 69 ainda não cita Câmaras e ondas nem Acessibilidade |
| C-I6 `referenced_by` do registro | ⏳ aberto | `entities.yaml` não mudou desde 2026-11-05 (ver I-6 abaixo) |
| C-I7 Next Steps do índice | ⏳ aberto, mais defasado | ver C-W4 abaixo |
| S-W1 fim da run no MVP | ⏳ mantido | dono: Run e regiões (Not Started) |
| S-W2 abates em cadeia no hitstop | ◐ parcial | o `time_scale` saiu; falta definir a ordem e o empilhamento (ver D-N1) |
| S-W3 recarga e sistemas fora da run | ✅ para Pronto | Conteúdo l. 721–726, AC-47; o caso que termina em Falhou é novo (S-W4) |
| D-W1 a D-W10 | ⏳ mantidos | os donos (Bênçãos, Combate, Chefes, Selo e Fluxo, Economia, HUD) ainda não existem; nenhuma mudança de hoje mexeu nas causas |
| D-I6 seed do dia × P4 | ⏳ mantido | `rng-com-seed.md:18`, OQ6 l. 803 |

---

## Consistency Issues

### Blocking

Nenhum.

### Warnings

⚠️ **C-W1. O AC-39 do Conteúdo não pode passar como está escrito** (2f)
- `conteudo-orientado-a-dados.md:1045–1046` exige a sequência `combate, …, santuario, …, chefe`.
- As l. 1048–1050 exigem que "nenhum `.tres` contém … `combat` …". Como `combate` contém `combat`, a busca por substring sempre falha.
- O mesmo vale para `BLADE` (pode aparecer como texto em `trad_blade_*`, que é id canônico mantido) e impede incluir `arc`, porque `arco` contém `arc`.
- A lista proibida também é parcial: faltam `ranged`, `boss` (como token), `circle`, `projectile`, `burn` e `weak`.
- O subagente da fase 2 classificou isto como Blocking. Esta revisão rebaixou para Warning: o erro é de redação de um teste, nenhum outro sistema depende dele e a regra (tokens em PT) está clara. A 4ª re-review do Conteúdo já tinha registrado o mesmo ponto como recomendação.
- **Mudar no Conteúdo (AC-39):**
  - trocar "nenhum `.tres` contém X" por "nenhum valor de id ou token nos `.tres` é igual a X", comparando o token inteiro;
  - a lista proibida passa a ser toda a coluna `id_canon` do mapa R2, exceto os ids que o mapa mantém iguais (inimigos, melhorias).

⚠️ **C-W2. A melhoria `recusa` precisa de params, e a importação não os grava** (2b/2f)
- Fatos:
  - o Modificadores exige `vida_ao_voltar` 0,4 e `invuln_s` 2,0 em todo `recusas_morte` (`modificadores-e-atributos.md:163`);
  - os params têm de ser iguais entre fontes (`:502–506`, V11 do Conteúdo `:265`), e o AC-26 soma Os Que Ficam com a Recusa dos Que Ficam;
  - no cânone, a melhoria só tem `deathDefiance` 1, e os 40% e 120 ticks são constantes de código (`arenaContent.ts:209`, `engine.ts:627–628`).
- **Falha:** a tabela de constantes escondidas do Conteúdo (`:657–668`) só cobre as Tradições. Quando a Oficina entrar (fatia vertical), a `UpgradeDef recusa` sai sem params e dá erro V1 ou V11 no conteúdo real (AC-20).
- **Mudar no Conteúdo:**
  - uma linha para a melhoria `recusa` na tabela (`vida_ao_voltar` 0,4, `invuln_s` 2,0);
  - ou uma regra geral: um tipo de gatilho com params recebe os mesmos params em toda fonte importada.

⚠️ **C-W3. Dependentes que faltam no Modificadores e no índice** (2a)
- O Modificadores R10 cria as fontes `chefe` e `profundidade`, e a fórmula da segunda é "do GDD de IA / Câmaras" (`modificadores-e-atributos.md:231–236`). A Interactions cita "IA / Câmaras e ondas" (`:324`).
- A tabela de dependentes (`:558–570`) não tem Câmaras e ondas nem Chefes.
- No índice, o Depends On de Câmaras e ondas (`systems-index.md:80`, e o mapa na Feature Layer) e o de Chefes (`:79`) não citam Modificadores.
- **Mudar:**
  - Modificadores: as duas linhas em "É dependência de";
  - índice: Modificadores no Depends On das duas linhas, ou a fórmula da profundidade passa explicitamente para a IA.

⚠️ **C-W4. O Next Steps do índice ficou para trás** (2c; continuação do C-I7)
- `systems-index.md:303` ainda diz que o Conteúdo e o Input estão "In Review".
- Não registra:
  - as 4ªs re-reviews (APPROVED) dos dois;
  - a 1ª passada do `/review-all-gdds` (FAIL);
  - os warnings aplicados em Cena e Modificadores, que voltaram para In Review.
- **Mudar no índice:** atualizar a linha. Esta revisão já faz isso (Phase 6).

### Info

- ℹ️ **C-I1.** O AC-51 do Conteúdo (`:1026`) testa só "D-pad e botões do gamepad". O AC-38 do Input (`:636–637`) inclui teclas e cliques. Os dois não se contradizem, mas o AC-51 poderia citar os dois caminhos. "A lista rola" também não diz se a roda do mouse vale: ela não está na lista digital do Input R12 (`:283`).
- ℹ️ **C-I2.** A Cena (`:642`) diz que o `CombatTuning` está "na tabela de `*Tuning`" da R1 do Conteúdo, mas a `:94` só diz "hitstop", sem nomear o Tuning. O nome aparece nas l. 373, 650 e 761. Nomear o `CombatTuning` na R1.
- ℹ️ **C-I3.** O `fator_empurrao` tem dois donos de valor:
  - o da elite (0,4) fica nas `EliteRules`, dono IA;
  - o do chefe (0,12) fica no `ModifiersTuning`.
  Não é contradição, mas a escolha deve ser registrada no GDD de Chefes, ou o 0,12 deve ir para um dado da IA/Chefes.
- ℹ️ **C-I4.** Cross-References incompletas:
  - Modificadores (`:603`) cita só Conteúdo "R1, V4, constantes escondidas". Também usa a R2 (tokens de forma), a F7 (passos) e a V11.
  - Input (`:598`) cita só "R1, V2". A regra "Sem catálogo" usa também Edge Cases › Recarga em debug, UI Requirements e AC-51.
- ℹ️ **C-I5.** A regra `zm + ze < 1` nunca dispara com valores dentro das faixas:
  - as faixas são `zm` 0–0,5 e `ze` 0–0,2 (`input-e-controle.md:356–357`), então a soma máxima é 0,7;
  - o AC-05 do Input usa `ze` 0,5 (fora da faixa), então o erro sai pela faixa e o teste não prova a regra entre campos;
  - o mesmo vale para o caso "`zm + ze ≥ 1`" do AC-51 do Conteúdo.
  - **Decidir no Input:** tirar a regra, por ser redundante, ou alargar as faixas e reescrever o AC-05 com valores dentro delas.
- ℹ️ **C-I6.** No registro, além do C-I6 da 1ª passada (`referenced_by` de `duration_to_steps`, `tick_rate`, `damage_reduction_cap`), faltam valores que hoje cruzam GDDs: `fator_empurrao_chefe` 0,12 (Modificadores, citado pelo Conteúdo), a queda 0,78/passo e o raio de 1350 px. Rodar `/consistency-check`.
- ℹ️ **C-I7.** A OQ2 do RNG (`rng-com-seed.md:799`) ainda testa "hitstop e `time_scale` diferentes". O hitstop agora é contador de passos (Cena R7), mas o teste continua útil para `time_scale` de debug. Reescrever o texto.
- ℹ️ **C-I8.** "Nenhuma arma de fábrica do MVP cura por acerto" (`modificadores-e-atributos.md:269`) só vale para o MVP. No cânone, as armas de Pactos curam por acerto (`arenaContent.ts:72–73`). A regra já cobre esse caso, mas o GDD de Armas precisa saber quando os Pactos entrarem (Alpha).

---

## Game Design Issues

Nenhum bloqueante. D-W1 a D-W10 da 1ª passada seguem abertos e encaminhados aos GDDs donos. Os números vêm do cânone e são placeholders.

### Warnings

⚠️ **D-N1. Hitstops em sequência não têm regra de empilhamento** (3b, 3f/P3)
- Evidência:
  - o hitstop agora é um contador de passos do Combate, e os sistemas vivos pulam esses passos (`cena-3-4-e-camera.md:182–188`);
  - o prazo do buffer não desconta durante o hitstop (`input-e-controle.md:161–166`, F3);
  - uma cadeia de explosões processa até 4 passes por passo, e o resto fica para o passo seguinte (`modificadores-e-atributos.md:281–287`);
  - nenhum GDD diz se hitstops seguidos somam, renovam ou ficam no maior.
- **Efeito:** numa câmara tardia (~27 abates, Matéria Residual), hitstops somados de abate podem congelar o mundo por segundos. Um toque de esquiva guardado sai muito depois do que o jogador espera, contra P3.
- **Para o GDD de Combate núcleo:**
  - hitstop não cumulativo (`max(restante, novo)`);
  - um teto de passos por janela no `CombatTuning`;
  - dizer se a varredura de mortes é um sistema vivo (se roda durante o hitstop).
  - Junta com S-W2.

⚠️ **D-N2. As portas sorteiam com reposição, e duas portas iguais não são escolha** (3c, 3f/P2)
- Evidência:
  - o cânone sorteia de `[boon×3, fragments×2, heal]` mais `trial`, com reposição; só a Provação repetida vira bênção (`engine.ts:403–411`);
  - o Conteúdo transforma isso em pesos por tipo (`conteudo-orientado-a-dados.md:91`, `:151–152`).
- **Conta:** com 2 portas, os dois tipos saem iguais em ≈ 29% das vezes depois da profundidade mínima da Provação, e ≈ 39% antes dela.
- **Efeito:** duas portas `fragmentos` ou duas `cura` não oferecem troca, contra P2. Duas `bencao` ainda podem ser escolha real, se cada porta tiver um Mestre (D-W7).
- **Para Portas e recompensas:**
  - decidir se os tipos saem sem repetição, ou se a repetição só vale quando as portas diferem;
  - a `RewardTable` também precisa dos campos "chance de 3 portas" (0,3, `engine.ts:403`) e "Provação repetida vira" (`:410`), que não estão na lista de campos do Conteúdo R1 (`:91`).

⚠️ **D-N3. A V11 fixa os params por tipo de efeito em todo o catálogo** (3c, 3g/P1)
- Evidência:
  - a V11 exige params iguais entre todos os `EffectDef` do mesmo tipo (`conteudo-orientado-a-dados.md:265`);
  - os condicionais têm params fixos: `limiar_vida` 0,5, `a_cada` 4, `janela_s` 1,5 (`modificadores-e-atributos.md:154–156`).
- **Efeito:** duas Tradições não podem usar a mesma mecânica com limiares diferentes (por exemplo, abaixo de 30% contra abaixo de 50%) sem um tipo novo na lista fechada R5. Isso estreita P1 e pesa sobre D-W10. Também torna global qualquer ajuste feito por param.
- **Para Bênçãos e o CD:**
  - declarar que a identidade de uma Tradição vem de tipo + valor + combinação;
  - uma variante nova exige um tipo novo na R5 (Modificadores e V4).
  - É uma restrição de mecânica e não pede lore.

### Info

- ℹ️ **D-N4.** A recusa devolve o jogador com 40% da Vida (`modificadores-e-atributos.md:163`), abaixo do limiar 0,5 do Fundo do Poço (`:154`). Com até 3 recusas (D-W2), a build de Vida baixa ganha uma rede que alimenta o próprio bônus. O GDD de Bênçãos deve dizer se a sinergia é desejada.
- ℹ️ **D-N5.** Os Fragmentos por porta são uma curva escondida no cânone (`2 + floor(depth/3)`, `engine.ts:498`). A `RewardTable` só diz "Fragmentos por porta" (`:91`), e as outras fontes estão na `EconomyRates` (`:92`). Portas deve declarar `base` e `por_profundidade`. A Economia deve somar as duas tabelas (D-W8).
- ℹ️ **D-N6.** O hitstop sem `time_scale`, os impulsos de câmera em tempo real e o buffer que não perde toque no hitstop de chefe reforçam P3. A tela de erros só com entradas digitais não toca nenhum pilar. Nenhuma mudança de hoje toca P4, P5 ou os anti-pilares.

---

## Cross-System Scenario Issues

Cenários percorridos: 5
1. O catálogo falha ao iniciar e mostra a tela de erros.
2. Recarga em debug: Pronto → Pronto e Pronto → Falhou.
3. A câmara é limpa, a porta é escolhida e a próxima câmara começa.
4. Um abate em cadeia (Matéria Residual + Primeiro Vínculo) acontece durante o hitstop.
5. Os Que Ficam + Recusa dos Que Ficam numa mesma run (fatia vertical).

### Blockers

Nenhum. O S-B1 da 1ª passada (cenário 1) está resolvido: Conteúdo e Input dizem a mesma coisa (só entradas digitais, nenhum número no código), e o AC-51 e o AC-38 testam isso.

### Warnings

⚠️ **S-W4. Uma recarga que termina em Falhou não tira o Tuning já injetado** (cenário 2; Conteúdo, Input, Cena)
- **Sequência:** Pronto (o Input e a câmera recebem os Tunings) → recarga em debug → Falhou.
- **O que os GDDs dizem:**
  - o Conteúdo diz que, em Falhou, "inclusive numa recarga", os sistemas fora da run ficam **sem** Tuning (`conteudo-orientado-a-dados.md:727–731`), e que o Input recebe "nada" (`:374`);
  - o Input R12 diz o mesmo (`input-e-controle.md:279–282`);
  - a re-injeção só acontece a cada **entrada em Pronto** (`:724–726`), e nenhum GDD define um passo de retirada.
- **Falha:** se o carregador só deixa de injetar, o Input continua com o `InputTuning` antigo e com analógicos ativos, o que contradiz o modo só digital e o AC-51 ("nenhum sistema fora da run recebeu Tuning").
- Só acontece em debug.
- **Mudar:**
  - Conteúdo (Edge Cases › Recarga): o carregador retira o Tuning (injeta vazio) dos sistemas fora da run ao sair de Pronto; trocar o "nada" da l. 374 por "retirada";
  - AC-51: acrescentar o caso "recarga que falha depois de um Pronto";
  - Input R12: dizer que a retirada leva ao modo só digital.
- As duas re-reviews de hoje (Conteúdo e Input) já tinham registrado este ponto como recomendação.

⚠️ **S-W1 (mantido). Fim da run no MVP com o `limiar` terminando em sala `chefe`** (cenário 3; Run, Portas, RNG)
- Continua sem dono escrito.
- No cânone, a porta antes da sala `boss` é forçada a `boon`, e a antes do Santuário, a `heal` (`engine.ts:400–401`).
- Nenhum GDD diz se o fluxo `portas` é consumido nessas portas forçadas (RNG R4/R7).
- Re-checar quando Run e regiões e Portas e recompensas forem escritos.

⚠️ **S-W2 (parcial). Abates em cadeia durante o hitstop** (cenário 4; Modificadores, Input, Cena; Combate ausente)
- O risco do `time_scale` saiu.
- Ainda falta:
  - dizer se o "passo seguinte" da R13 (Modificadores) é um passo vivo, ou se a varredura roda durante o hitstop;
  - a regra de empilhamento dos hitstops de abate (D-N1).
- Para o GDD de Combate núcleo.

### Info

- ℹ️ **S-I1.** Cenário 5: com V11, os params iguais (0,4 e 2,0) batem com o cânone, que usa as mesmas constantes para as duas fontes. O cenário só falha pela C-W2 (params ausentes na `UpgradeDef`). A sinergia com o Fundo do Poço é a D-N4.
- ℹ️ **S-I2.** Cenário 1: um gatilho analógico remapeado para uma ação `ui_*` fica morto em Falhou. A roda do mouse não está na lista digital (C-I1). Nenhum dos dois impede usar a tela.

---

## GDDs Flagged for Revision

| GDD | Razão | Tipo | Prioridade |
|---|---|---|---|
| conteudo-orientado-a-dados.md | C-W1 (AC-39), C-W2 (params da `recusa`), S-W4 (retirada do Tuning); C-I1, C-I2 | Consistência / Cenário | Warning |
| input-e-controle.md | S-W4 (retirada no R12); C-I1, C-I4, C-I5 | Cenário / Consistência | Warning |
| modificadores-e-atributos.md | C-W3 (dependentes); C-I4 | Consistência | Warning |
| systems-index.md | C-W3 (Depends On de Câmaras e Chefes), C-W4 (Next Steps); C-I5 da 1ª passada | Consistência | Warning |
| rng-com-seed.md | C-I7 (OQ2); D-I6 | Consistência / Design Theory | Info |
| design/registry/entities.yaml | C-I6 | Consistência | Info |

A Cena 3/4 não tem item novo.

Requisitos para GDDs ainda não escritos (somam-se aos da 1ª passada):
- **Combate núcleo:** D-N1 (empilhamento e teto do hitstop), S-W2 (varredura de mortes × hitstop).
- **Portas e recompensas:** D-N2 (repetição de tipo, chance de 3 portas, Provação repetida), D-N5 (curva de Fragmentos por porta), S-W1 (consumo do fluxo nas portas forçadas).
- **Bênçãos:** D-N3 (params fixos por tipo), D-N4 (recusa × Vida baixa).
- **Chefes:** C-I3 (onde fica o 0,12).
- **Oficina de Reforja:** C-W2.
- **Armas das Doutrinas (Alpha):** C-I8.

---

## Verdict: CONCERNS

- **Bloqueantes:** 0. Os dois da 1ª passada (C-B1 e S-B1) estão resolvidos.
- **Warnings:**
  - 4 de consistência (C-W1 a C-W4);
  - 3 de cenário (S-W4 novo; S-W1 e S-W2 mantidos);
  - 3 novos de teoria de design (D-N1 a D-N3), mais D-W1 a D-W10 mantidos.
- Os warnings de GDD escrito são edições curtas no Conteúdo, no Input, no Modificadores e no índice. Os outros são requisitos para GDDs ainda não escritos.
- **Ressalva de processo:** Modificadores e Cena 3/4 estão In Review no índice. Antes do `/gate-check` ou do `/create-architecture`, os dois precisam de um `/design-review` que os aprove de novo, ou de uma decisão sua de aceitar as mudanças de hoje sem nova review.

---

## Aplicado depois da revisão (2026-11-06, mesma sessão, aprovação do usuário)

- **C-W1:** o AC-39 do Conteúdo compara o token inteiro, contra toda a coluna `id_canon` do mapa R2 que o mapa troca.
- **C-W2:** a importação grava `vida_ao_voltar` 0,4 e `invuln_s` 2,0 na `UpgradeDef recusa` (Conteúdo, Edge Cases › Constantes escondidas).
- **C-W3:** o Modificadores passa a ter Câmaras e ondas e Chefes como dependentes. O índice passa a ter Modificadores no Depends On das duas linhas, na tabela e na Feature Layer.
- **C-W4:** o Next Steps do índice foi atualizado.
- **S-W4:** o carregador retira o Tuning dos sistemas fora da run ao sair de Pronto. Mudaram:
  - no Conteúdo: Edge Cases › Recarga, as linhas do Input e da Cena em Interactions, e o AC-51;
  - no Input: a R12.
- **Infos:** C-I2 (o `CombatTuning` é nomeado na R1 do Conteúdo) e C-I4 (Cross-References do Modificadores e do Input).
- **Status:** Conteúdo e Input seguem Approved, por decisão do usuário. Modificadores e Cena 3/4 seguem In Review.
- **Ainda abertos:**
  - C-I1, C-I3 e C-I5 a C-I8;
  - S-W1 e S-W2;
  - D-N1 a D-N5, D-W1 a D-W10 e D-I6;
  - o C-I5 e o C-I6 da 1ª passada.

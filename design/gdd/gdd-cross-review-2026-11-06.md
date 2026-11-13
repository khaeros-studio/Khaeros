# Cross-GDD Review Report

Date: 2026-11-06
GDDs Reviewed: 5 of 5 present
Not read: none
Focus: full
Systems Covered: Conteúdo orientado a dados (1), Modificadores e atributos (2), RNG com seed (3), Input e controle (4), Cena 3/4 e câmera (5)
Pilares: P1 Toda bênção é uma filosofia · P2 A Beira cobra · P3 Reflexo que se lê · P4 Ritual, não pressão · P5 O mundo não se explica de uma vez. Anti-pilares: não é online/MMO/monetizado; demais em `game-concept.md`.
Registro: `design/registry/entities.yaml` com 8 fórmulas e 6 constantes (Fundação), usado como base.

Status no índice durante a revisão: Conteúdo **Needs Revision**, Input **In Review** (mudou durante esta revisão, por outra sessão), Modificadores, RNG e Cena **Approved**.

> Execução: as fases 2 e 3 rodaram como subagentes `game-designer` em paralelo, lendo os GDDs por seção (5 GDDs, ~230 KB, grandes demais para colar no prompt). As duas pararam no limite de passos e entregaram o que tinham. A cobertura parcial está declarada abaixo. Os achados principais foram conferidos por releitura na sessão principal.
> - Fase 2: não leu as Formulas F4–F9 do RNG nem parte do Edge Cases do Conteúdo. Nenhum dos 5 GDDs tem seção Tuning Knobs (advisory no `standard`).
> - Fase 3: dois pontos do cânone ficaram sem confirmar (se Selos sobrepostos somam dano e a base de `cargas_esquiva`).

---

## Consistency Issues

### Blocking (resolver antes da arquitetura)

🔴 **C-B1. Tokens de sala e de recompensa fora do mapa de ids** (Conteúdo; 2c)
- `conteudo-orientado-a-dados.md` R2 (l. 126–135): o mapa cobre doutrina, região, chefe, inimigo, tipo de efeito, comportamento, forma e status. Não tem linha para tipo de sala nem para recompensa.
- Cânone: `RoomKind = "combat" | "sanctuary" | "boss"` (`types.ts:172`) e `RewardKind = "boon" | "fragments" | "heal" | "trial"` (`:177`; pool de portas em `engine.ts:400–410`).
- Quem já depende deles: `RegionDef` "sequência de câmaras" (l. 89), `RewardTable` "pesos das portas… cura do Santuário" (l. 91), RNG Edge Cases ("o Santuário não tem ondas", `rng-com-seed.md:499`).
- A R8 não dá dono a essas listas e a V4 não as confere. Pela AC-39, um token sem linha faz a importação falhar, então a importação do `limiar` (MVP) falha.
- **Mudar no Conteúdo:**
  - linhas no mapa com tokens em PT;
  - donos na R8 (Câmaras e ondas / Run para sala; Portas e recompensas para recompensa);
  - listas na V4;
  - `combat` e `boon` na lista proibida da AC-39.
- É o mesmo bloqueante da 3ª re-review do Conteúdo (2026-11-06).

### Warnings

⚠️ **C-W1. Modificadores usa os tokens canônicos de forma** (2c)
- `modificadores-e-atributos.md:255–257` usa `arc`, `circle` e `lunge`.
- Conteúdo R2 (l. 134) define `arco`, `circulo` e `avanco`, e diz que o dado guarda só tokens Godot.
- **Mudar em Modificadores R12.**

⚠️ **C-W2. `ModifiersTuning` não está no Conteúdo** (2c/2d)
- `modificadores-e-atributos.md:100` pede a inclusão na R1 do Conteúdo (OQ6, l. 781).
- `conteudo-orientado-a-dados.md` l. 94, 361 e 732 não o citam.
- As constantes escondidas (l. 629–630, piso 20 e teto 60%) vão para um "`*Tuning` do sistema dono" sem nome.
- **Mudar no Conteúdo:** R1, Interactions e Dependencies.

⚠️ **C-W3. A checagem de params divergentes pedida por Modificadores não existe** (2c/2f)
- `modificadores-e-atributos.md:500–504` e a AC-26 (l. 710–711) exigem erro de validação para params divergentes entre fontes do mesmo gatilho.
- Nenhuma das V1–V10 do Conteúdo (l. 244–255) cobre uma regra entre definições. A AC-26 de Modificadores não passa.
- **Mudar no Conteúdo:** criar a V11 e uma AC para ela.

⚠️ **C-W4. O cambaleio do chefe é atribuído ao GDD errado** (2c)
- `conteudo-orientado-a-dados.md:659–661` diz que o comportamento `chefe` decide o `fator_empurrao` 0,12 "e o fim do cambaleio (GDD de Modificadores)".
- `modificadores-e-atributos.md:232–235` só traz o `fator_empurrao`. Não cambalear é "regra de IA e de Combate". Cânone: `engine.ts:587`.
- **Mudar no Conteúdo:** atribuir a Combate núcleo / IA / Chefes.

⚠️ **C-W5. Modificadores cita a arma de Pactos do modo web** (2c)
- `modificadores-e-atributos.md:269` e a AC-29 (l. 730) usam "Laço dos Pactos" e "Círculo de Pacto (`healOnHit` 2)".
- O Conteúdo R11 (l. 307–309) e a OQ4 (l. 1036) dizem que nada de Pactos é importado e que a arma é a Besta do Vínculo.
- **Mudar em Modificadores:** regra genérica ("arma com cura por acerto") e AC com arma de fábrica.

⚠️ **C-W6. Cena ↔ Input não é recíproco, e o índice também está errado** (2a)
- Lado do Input: `input-e-controle.md:534` e `:543–547` dão ao Input, como fornecedor da Cena, `fonte_mira`, `intensidade_mira` e o cursor.
- Lado da Cena: `cena-3-4-e-camera.md:545–551` não lista o Input como upstream, embora a F2 da Cena (l. 293–294) use "a F2 do Input".
- No índice: `systems-index.md:69` (Cena) não cita o Input, e `:155` chama de "suave" a dependência Input→Cena que a tabela (l. 68) e `input:514` chamam de "forte".
- **Mudar:** Dependencies da Cena e o índice.

⚠️ **C-W7. Hitstop por `Engine.time_scale` × sistemas que contam passos** (2b)
- A Cena admite hitstop por `time_scale` (`cena-3-4-e-camera.md:178–180`, `:529–530`, AC-28 `:746–748`).
- O Input exige amostragem e buffer rodando durante o hitstop, sem descontar o prazo (`input-e-controle.md:159–164`, F3, AC-16).
- Modificadores conta durações em passos vivos (`modificadores-e-atributos.md:195`).
- Com `time_scale = 0`, não há passo de física. O dono do hitstop é o Combate núcleo (Not Started); o RNG já marca o risco (OQ2, `rng-com-seed.md:799`).
- **Mudar:**
  - Cena: tirar ou condicionar a hipótese de `time_scale`;
  - requisito para o GDD de Combate: o hitstop é um contador de passos, a física continua rodando e os sistemas vivos pulam o passo.

⚠️ **C-W8. Quem é dono dos valores de hitstop** (2d)
- A Cena F5 (`cena-3-4-e-camera.md:400–404`) e o Game Feel (l. 598–599) tabelam 3, 6 e 36 passos.
- O Conteúdo (l. 94, 363, 773–775) põe o hitstop no `CombatTuning`, com dono Combate.
- Cânone (`engine.ts:63–67`): LIGHT 3, HEAVY 6, KILL 4, HURT 6, BOSS_KILL 36. O 36 é só da morte do chefe.
- **Mudar na Cena:** marcar os valores como referência ao `CombatTuning`, sem posse.

⚠️ **C-W9. `unit_to_px`: conversão na importação ou dado em jogo?** (2d/2e)
- O Conteúdo diz conversão única, na importação: l. 196–197, l. 396–400 e F4.
- A Cena F1 (`cena-3-4-e-camera.md:279`) trata o valor como dado de arquivo. A AC-07 (l. 669–671) troca o dado para 2 e espera raio 36, ou seja, conversão em jogo. Aplicada sobre valores já em px, isso converte duas vezes.
- A Interactions do Conteúdo (l. 365) põe "dono da interface: Cena", e o registro dá `source: conteudo`.
- **Mudar:**
  - Cena: a F1 = a F4 do Conteúdo, só na importação, e a AC-07 vira teste do script de importação;
  - Conteúdo: dono na l. 365.

⚠️ **C-W10. Raio da mira automática inclusivo no Input, exclusivo no cânone** (2e)
- Input: `input-e-controle.md:130`, F4 (l. 400) e AC-10 (l. 639), "a até 1350 px (inclusivo)".
- Cânone: `packages/preview/src/arena/input.ts:181`, `d < 900`, estrito.
- O desvio não está entre os declarados.
- **Mudar no Input:** declarar o desvio ou usar `<`.

### Info

- ℹ️ **C-I1.** `modificadores-e-atributos.md:175` ainda fala dos "provisórios do mapa do Conteúdo (`dash_damage` etc.)". O mapa já usa os nomes finais. Apagar a frase.
- ℹ️ **C-I2.** A Cena (l. 572–574, OQ8 l. 808) diz que o Conteúdo não lista o `CameraTuning`. Já lista (l. 94, 365). Fechar a OQ8.
- ℹ️ **C-I3.** `cena-3-4-e-camera.md:243` diz que a Cena fornece "posição da câmera para o limiar do mouse". A F5 do Input não usa isso. Tirar.
- ℹ️ **C-I4.** A R12 do Input (`input-e-controle.md:266–272`) não lista `ze`. A F2 e a validação `zm + ze < 1` dependem dele. Acrescentar `ze` (0,05).
- ℹ️ **C-I5.** `systems-index.md:69` não cita Câmaras e ondas nem Acessibilidade, que a Cena lista como Suave por contrato (`cena:550–551`).
- ℹ️ **C-I6.** O `referenced_by` do registro está incompleto:
  - `duration_to_steps` não cita Modificadores;
  - `tick_rate` não cita Input, Cena nem Modificadores;
  - `damage_reduction_cap` não cita o Conteúdo.
  - Também faltam no registro valores usados por mais de um GDD: a queda 0,78/passo, o `fator_empurrao_chefe` 0,12 e o raio de 1350 px.
- ℹ️ **C-I7.** O Next Steps do índice (`systems-index.md:~298`) não registra a 3ª re-review do Conteúdo. O status do Input mudou durante esta revisão (Needs Revision → In Review).

---

## Game Design Issues

Nenhum bloqueante: nenhuma estratégia dominante está provada. Os números abaixo vêm do cânone importado (placeholders, regra 4), porque Bênçãos, Selo e Fluxo, Combate, Chefes e Economia ainda não têm GDD. Alvos de dificuldade e de TTK: **NOT ASSESSED — NO DATA**, porque nenhum GDD nem o registro define taxa de vitória, TTK ou duração de câmara.

### Warnings

⚠️ **D-W1. A cura ao abater cresce com a profundidade e anula "Vida que não volta inteira"** (3c/3d/3f)
- Evidência:
  - `cura_ao_abater` cura por morte, sem teto além de `vida_max` (`modificadores-e-atributos.md:168`, `:286–287`), inclusive na cadeia de explosões.
  - Primeiro Vínculo: 2 de Vida, 4 na Épica (`arenaContent.ts:157`).
  - Cerca de 27 abates por câmara na profundidade 12, o que dá ~54 de cura na Comum e ~108 na Épica, mais que a Vida máxima base.
- Choca com P2 (`game-concept.md:52`).
- **Para o GDD de Bênçãos:** teto de cura por câmara, ou cura decrescente por abate.

⚠️ **D-W2. Três recusas de morte com a meta cheia** (3c/3f)
- Evidência:
  - recusas de fontes diferentes somam (`modificadores-e-atributos.md:500–503`), até 3 (Os Que Ficam + Recusa dos Que Ficam ×2, `arenaContent.ts:159`, `:209`);
  - Vida efetiva ≈ 4,6× a base;
  - `baseline.md:5109–5112`: com a meta cheia, a perícia 0 sobe de 5–20% para 40–95% de vitória.
- **Para Oficina / Bênçãos:** um alvo de vitória com a meta cheia e o knob `teto_recusas_morte`.

⚠️ **D-W3. Multiplicadores condicionais dominam as bênçãos de percentual no fim da run** (3c)
- Evidência:
  - F2 de Modificadores: `(1 + P) × Π`;
  - Linha Contada e Penumbra escalam o fator inteiro com a raridade;
  - `teto_multiplicador_dano` está vazio (`modificadores-e-atributos.md:107`, `:388–390`, máximo teórico ≈ 14).
- Com M = 2,5, o Traço Único Comum rende +10% e a Linha Contada Comum ≈ +15% sobre tudo.
- **Decidir antes da fatia vertical:** escala da raridade sobre `(valor − 1)`, ou um teto derivado de um TTK-alvo.

⚠️ **D-W4. O chefe tem Vida fixa contra um M sem teto** (3e)
- Evidência:
  - +5% por profundidade não vale para chefe (`modificadores-e-atributos.md:236–237`; `engine.ts:322`);
  - Anomalia Maior: 700.
- Com M ≈ 12, o chefe cai em menos de 1 s de DPS teórico.
- **Para o GDD de Chefes:** um TTK-alvo que dirija o teto ou uma regra de chefe.

⚠️ **D-W5. O Fluxo ganho por alvo realimenta o Selo no corpo a corpo de área** (3c/3d)
- Evidência: +3 de Fluxo por alvo atingido (`engine.ts:40`, `:575`).
- Lâmina com o Corte em 5 alvos: ≈ 56 Fluxo/s, um Selo a cada ≈ 0,7 s. Ressonância: ≈ 16,5/s.
- Com Forma Fixa, o resultado é Abalo quase permanente.
- **Para Selo e Fluxo (MVP):** teto de Fluxo por golpe, ou ganho por golpe em vez de por alvo.

⚠️ **D-W6. O Corte Fantasma usa M inteiro durante a invulnerabilidade** (3c/3f)
- Evidência: dano 10 × M(Ataque) por inimigo atravessado (`modificadores-e-atributos.md:166`, `:94–96`).
- Com cargas extras (Fio Invisível, Fôlego), "esquivar através" vira o ataque mais seguro do jogo, em tensão com P3.
- **Para Movimento / Bênçãos:** usar só `P_slot` + `P_todo`, ou pôr teto de alvos.

⚠️ **D-W7. A oferta "três leituras da Doutrina do Mestre" degenera** (3c/3g)
- Evidência:
  - `game-concept.md:150–153`: o Mestre oferece três leituras da sua Doutrina;
  - cada Doutrina tem exatamente 3 Tradições (`arenaContent.ts:132–163`), então a 3ª oferta do mesmo Mestre tem 1 opção;
  - o cânone sorteia 3 das 18 (`engine.ts:419–432`).
- **Para Bênçãos / Mestres ofertantes:** escolher o modelo. É decisão de mecânica para o CD, sem lore nova.

⚠️ **D-W8. A meta acaba em ~8 runs e o Fragmento fica sem sumidouro** (3a/3d)
- Evidência:
  - fontes: portas 2–6, Provação +3, chefes 6/10, vitória 15;
  - ~42 por run na perícia 1 (`baseline.md:4990`);
  - único sumidouro definido: a Oficina, 350 no total (`arenaContent.ts:201–210`);
  - o custo do desbloqueio de armas está indefinido.
- **Para Economia / Desbloqueio de armas:**
  - o custo das armas;
  - se a morte guarda 100% dos Fragmentos;
  - um alvo de horas até a meta cheia;
  - um sumidouro compatível com P4.

⚠️ **D-W9. O orçamento de atenção no combate passa de 4** (3b)
- Decisões ativas ao mesmo tempo:
  1. posicionar e esquivar lendo telégrafos;
  2. mirar;
  3. Ataque × Especial;
  4. Selo e Fluxo;
  5. manter as condições da build (4º acerto, janela de 1,5 s pós-esquiva, Vida < 50%).
- Atenuantes já desenhados: segurar repete o golpe; mira automática no gamepad.
- **Para HUD / Feedback:** condicionais como estado passivo e legível (pip do 4º acerto, brilho pós-esquiva).

⚠️ **D-W10. P1/P2 contra o conteúdo do cânone** (3f/3g)
- Evidência:
  - das 18 Tradições, 7 são atributo puro;
  - só Preço com Nome tem preço mecânico (`arenaContent.ts:132–163`);
  - o conceito diz "cada bênção não é 'mais dano'" e "toda vantagem tem preço" (`game-concept.md:33–35`, `:51–52`).
- **Para o GDD de Bênçãos:** dizer como P2 se cumpre (custo de oportunidade, ou preço mecânico com aval do CD).

### Info

- ℹ️ **D-I1.** No MVP, a run é o único loop. A competição run × meta começa na fatia vertical (porta de bênção × porta de Fragmentos), o que serve a P2. No Alpha, a Oficina e as armas disputam a mesma moeda.
- ℹ️ **D-I2.** O inimigo cresce ~20× em Vida por câmara (profundidade 1 → 12) e o jogador ~3–4× em M, mais o tempo de câmara. Na Provação tardia, o ×1,35 bate no teto de 9 inimigos por onda. Câmaras e ondas deve declarar alvos de duração e de dano recebido.
- ℹ️ **D-I3.** Lâmina × Ressonância parecem assimétricas e viáveis (só cânone; dependem de Armas e Combate).
- ℹ️ **D-I4.** Os tetos de redução (0,6) e de Vida (20) estão inertes no conteúdo atual. Guarda × Abalo × redução chegam a −73%, fora do `min()`. Combate decide se a guarda e o Abalo contam no teto.
- ℹ️ **D-I5.** Fardo Repartido e Matéria Residual parecem saudáveis.
- ℹ️ **D-I6.** Cada GDD serve a um pilar, e nenhum viola anti-pilar. Risco: o "seed do dia" (`rng-com-seed.md:18`) esbarra em P4 se virar diária com recompensa. Registrar que é local e sem sequência.
- ℹ️ **D-I7.** A fantasia é coerente entre os 5 GDDs (legibilidade, controle que não engole comando, justiça reproduzível, preço visível).

---

## Cross-System Scenario Issues

Cenários percorridos: 5
1. O catálogo falha ao iniciar e mostra a tela de erros.
2. A câmara é limpa, a porta é escolhida e a próxima câmara começa.
3. Um abate em cadeia (Matéria Residual + Primeiro Vínculo) acontece durante o hitstop.
4. Recarga do catálogo em debug entre runs.
5. Mira automática no gamepad enquanto uma onda nasce.

### Blockers

🔴 **S-B1. O catálogo falha ao iniciar: a tela de erros fica sem `InputTuning`** (Conteúdo, Input)
- **Gatilho:** a carga do catálogo termina em Falhou. O estado Falhou do Conteúdo descarta o catálogo.
- **O que os GDDs pedem:**
  - o Conteúdo (UI Requirements) exige que a tela de erros seja "totalmente usável por teclado e gamepad";
  - o Input (R10) põe essa tela no contexto Menu;
  - o Input lê a zona morta e os limiares do gatilho do `InputTuning`, que fica no catálogo (R12).
- **Falha:** nenhum dos GDDs diz que valores o Input usa sem catálogo. A única exceção prevista no Conteúdo é o texto PT-BR embutido.
- **Pior caso:** o próprio erro pode ser o `zm + ze ≥ 1` do `InputTuning` (Input AC-05), e então a tela que mostra o erro depende do dado inválido.
- **Resolver (Conteúdo + Input):** valores de fábrica do `InputTuning` embutidos no código, só para a tela de erros, como segunda exceção explícita à regra "nenhum número literal"; ou a tela aceita só teclas e botões digitais, sem analógico.

### Warnings

⚠️ **S-W1. Fim da run no MVP com o `limiar` terminando em sala `boss`** (Conteúdo, Run, Portas, RNG)
- Evidência:
  - a `RegionDef limiar` grava `rooms` com `boss` na posição 6;
  - o Conteúdo diz que "no MVP a Run não leva à câmara do chefe";
  - no cânone, a porta antes da sala `boss` é forçada a `["boon"]` (`engine.ts:401`).
- **Falha:** nenhum GDD escrito diz o que acontece depois da câmara 5 no MVP (vitória? as portas aparecem?), nem se o fluxo `portas` é consumido nesse ponto (R7 do RNG, reprodução).
- Dono: Run e regiões (Not Started). Re-checar quando ele for escrito.

⚠️ **S-W2. Abates em cadeia durante o hitstop** (Modificadores, Input, Cena; Combate ausente)
- Evidência:
  - Modificadores R13 processa até 4 passes de explosão por passo e deixa o resto para o "passo seguinte";
  - o hitstop de abate (KILL 4) é do Combate;
  - se o hitstop usar `time_scale` (Cena C-W7), o "passo seguinte" só acontece depois do congelamento, enquanto o Input e as durações de Modificadores assumem que o passo continua rodando e só não conta.
- Hoje o resultado depende da implementação do hitstop. Resolver junto com C-W7, no GDD de Combate.

⚠️ **S-W3. Recarga em debug e os sistemas vivos fora da run** (Conteúdo, Input, Cena, RNG)
- O que funciona: a recarga recalcula a impressão (R12), e o texto da seed (RNG R8, `c____`) mostra a nova. Isso é coerente.
- **Falha:**
  - o Conteúdo garante que "nenhum sistema guarda o catálogo entre runs", mas o Input (menus) e a câmera vivem fora da run e recebem `InputTuning` e `CameraTuning`;
  - nenhum GDD diz se eles recebem a nova injeção depois da recarga.
- Efeito: ajustar a zona morta pela recarga em debug pode não ter efeito até reiniciar o jogo.
- **Resolver:** no Conteúdo, Edge Cases › Recarga, dizer quem re-injeta os Tunings dos sistemas fora da run.

### Info

- ℹ️ **S-I1.** Mira automática durante o spawn: o Input R5 exclui inimigos "surgindo", e o RNG sorteia os candidatos de spawn com consumo fixo (R4b). É coerente. O raio inclusivo × exclusivo é a C-W10.

---

## GDDs Flagged for Revision

| GDD | Razão | Tipo | Prioridade |
|---|---|---|---|
| conteudo-orientado-a-dados.md | C-B1 tokens de sala/recompensa; S-B1 Input sem catálogo; C-W2, C-W3, C-W4, C-W9 (l. 365); S-W3 | Consistência / Cenário | Blocking |
| input-e-controle.md | S-B1 (a parte do Input); C-W10; C-I4 | Cenário / Consistência | Blocking |
| cena-3-4-e-camera.md | C-W6, C-W7, C-W8, C-W9; C-I2, C-I3 | Consistência | Warning |
| modificadores-e-atributos.md | C-W1, C-W5; C-I1 | Consistência | Warning |
| systems-index.md | C-W6 (Depends On da Cena; l. 155); C-I5, C-I7 | Consistência | Warning |
| rng-com-seed.md | D-I6 (seed do dia × P4) | Design Theory | Info |

Requisitos para GDDs ainda não escritos (não são revisão, mas devem entrar quando forem escritos):
- **Combate núcleo:** hitstop como contador de passos (C-W7, S-W2); guarda × Abalo × teto (D-I4).
- **Bênçãos:** D-W1, D-W3, D-W7, D-W10.
- **Chefes:** TTK-alvo (D-W4).
- **Selo e Fluxo:** D-W5.
- **Movimento e esquiva:** D-W6.
- **Economia / Desbloqueio de armas:** D-W8.
- **HUD:** D-W9.
- **Run e regiões:** S-W1.
- **Câmaras e ondas:** D-I2.

---

## Verdict: FAIL

Bloqueantes: 2.
- **C-B1:** os tokens de sala e de recompensa ficaram fora do mapa de ids.
- **S-B1:** a tela de erros do catálogo depende do `InputTuning`, que vem do catálogo que falhou.

Há também 13 warnings de consistência e de cenário e 10 de teoria de design.

### Ações exigidas antes de rodar de novo
1. **Conteúdo:** linhas de tipo de sala e de recompensa no mapa R2 (tokens em PT), donos na R8, listas na V4, e a AC-39 com os tokens novos.
2. **Conteúdo + Input:** definir o que o Input usa quando o catálogo falha (valores de fábrica embutidos como exceção explícita, ou tela de erros só digital). Pôr a regra nos dois GDDs, com uma AC.
3. Recomendado na mesma passada: C-W2, C-W3, C-W4 e C-W9 no Conteúdo; C-W6 a C-W9 na Cena; C-W1 e C-W5 em Modificadores; C-W10 no Input.

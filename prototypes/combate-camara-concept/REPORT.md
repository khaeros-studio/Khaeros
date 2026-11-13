<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: o combate de uma camara (Lamina, telegrafo, esquiva) e legivel e justo em Godot a 60 passos/s? -->
<!-- Date: 2026-11-12 -->

# Concept Prototype Report: Combate de uma câmara (Khaeros)

> **Date**: 2026-11-12
> **Prototype Path**: Engine (Godot 4.7.2, GDScript)
> **Concept File**: design/gdd/game-concept.md
> **Review mode**: lean (CD-PLAYTEST pulada, modo Lean)

---

## Hypothesis

Se o jogador anda, ataca com a Lâmina e esquiva lendo o telégrafo no chão, o combate vai parecer justo e com peso (P3), evidenciado por: (1) todo golpe sofrido teve telégrafo visível por pelo menos 24 passos; (2) a janela de esquiva cobre o disparo no ritmo previsto pelos GDDs; (3) o Eco Perdido cai no 3º Corte (14, 14, 25,2) e o combo congela 12 passos.

## Riskiest Assumption Tested

Que a leitura do telégrafo e a esquiva funcionam a 60 passos/s no Godot sem o jogo "engolir" o comando. **Provou-se.** A parte mecânica passou nos cenários e a sensação foi confirmada pelo playtest do usuário em 2026-11-13.

---

## Approach

Uma câmara 1920×1080 com 2 pilares e 3 ondas (3, 5 e 5 inimigos: Eco Perdido e Anomalia Menor, 2 Ecos elite, +20% de Vida por profundidade 4). Lâmina com Corte (combo, hitstop, empurrão, quebra de preparo) e Investida; esquiva com cargas e invulnerabilidade; tela de bênção de 3 cartas de teste (Ataque +25%, +1 carga, Corte da esquiva). Todos os valores em `data/tuning.json`. Simulação própria em passos fixos de 60/s (`step()`), desenhada com `_draw`.

**Path chosen:** Engine. **Reason:** o feel é a hipótese; navegador mentiria sobre o tempo.

**Shortcuts taken (intencionais):** círculos próprios em vez de `CharacterBody2D`; sem câmera, sem ordenação 3/4, sem arte (formas de placeholder), sem áudio, sem Selo/Fluxo (decisão do usuário: só se o núcleo passar), sem RNG com seed (usa o `RandomNumberGenerator`), sem morte/menus, bênçãos de teste (`[PLACEHOLDER]`, não canônicas).

---

## Result

Fonte: `production/qa/evidence/combate-camara-testes.txt`, `...-batch-*.txt`, `...-bot-*.json` e as 6 screenshots `combate-camara-0N-*-bot-reativo-s3.png` (rodadas de verdade, com janela, GPU NVIDIA RTX 3050, Vulkan, Forward+).

**Confirmado por cenário determinístico (T1–T5):**
- Janela de invulnerabilidade da esquiva contra o disparo do Eco: esquiva com 1 a 12 passos faltando livra; com 13 acerta. São 12 passos (0,2 s) de um preparo de 26: exatamente o contrato do Movimento F4 (`D + E = 12`, protege do passo do toque ao `s+11`).
- Esquivar para fora do setor travado livra em qualquer momento do preparo (26 de 26), porque a mira trava no início (Telégrafos R2). Ou seja, ler o telégrafo e sair da forma já basta; a invulnerabilidade é a rede de segurança.
- Combo no Eco parado: 14, 14, 25,2, morto no passo 39 (3 + 3 + 6 = 12 passos congelados), igual ao exemplo do Combate F1 e F9.
- Dois toques de esquiva seguidos com +1 carga; Corte da esquiva tirou 10 de dano; esquiva de 9 passos × 22,5 px = 202,5 px.
- A idade mínima do telégrafo em qualquer golpe sofrido nos lotes foi 26 passos (Eco) e 36 (Anomalia), sempre ≥ 24 (R9). Por construção, todo golpe passa por telégrafo visível.

**Observado nas screenshots:** os setores e faixas leem bem no chão, com contorno cheio desde o passo 0 e preenchimento linear; faixa da Anomalia cruza a tela inteira e fica larga demais em relação ao corpo (81 px); o arco do golpe pesado (dourado) e a esquiva com anel de invulnerabilidade são distinguíveis. Cartas de bênção legíveis.

**Lotes de bot (30 câmaras de 3 ondas, 13 abates cada; perfil → Vida perdida média, golpes recebidos médios):**

| Perfil | Vida perdida | Golpes/câmara | Passos p/ limpar |
|---|---|---|---|
| reativo (reação 15, falha 10%) | 1,3 (1%) | 0,13 | 1009 (16,8 s) |
| lento (reação 20, falha 25%) | 2,1 (2%) | 0,20 | 1000 |
| nunca esquiva | 3,2 (3%) | 0,33 | 907 |

Bênçãos no bot reativo: Ataque +25% limpa em 888 passos (−12%); +1 carga e Corte da esquiva não mudam o resultado do bot (ele não os explora).

**Problema real que o bot revelou:** a câmara é **trivial para um jogador agressivo**. O Eco morre em 3 golpes (~0,6 s) antes de completar o ciclo de ataque: nos 13 abates de um lote, só 1 a 2 disparos de melee e 5 de faixa acontecem. Mesmo o bot que nunca esquiva perde 3% da Vida; a meta do IA R12 é 25% (faixa 10–50%). Esquivar reduz os golpes recebidos em ~60% (0,33 → 0,13), mas em termos absolutos o efeito é pequeno.

## Metrics

| Metric | Value |
|--------|-------|
| Path used | Engine |
| Iterations to playable | 3 (câmara de 1 onda → 3 ondas → 3 ondas + elites + profundidade) |
| Prototype duration | ~uma sessão |
| Playtesters | 1 interno (o usuário, 2026-11-13) / 0 externos; mais bot e cenários |
| Feel assessment | "o combate está bom e com peso"; melhor momento: o combo de 3 golpes congelando a tela (hitstop 3, 3, 6) |
| Hypothesis verdict | **CONFIRMED** (usuário, playtest de 2026-11-13; sinais 1 a 3 confirmados por teste automático) |

---

## Playtest Debrief (usuário, 2026-11-13)

Um playtester interno (o próprio autor, não é primeira impressão ingênua), jogando com teclado e mouse.

1. **Hipótese:** CONFIRMED.
2. **Melhor momento:** "o combo de 3 golpes congelando a tela".
3. **Pior momento:** não identificou nenhum.
4. **Surpresa:** nada inesperado.
5. **Veredito:** "PROCEED, o combate está bom e com peso".

O usuário não relatou a câmara fácil demais, a sobreposição do Eco nem a faixa larga da Anomalia que o bot e as screenshots apontaram. Esses pontos seguem como achados para o Design, não confirmados nem negados pelo playtest.

---

## Recommendation: PROCEED

O playtest humano confirmou a hipótese: o combate com a Lâmina, o telégrafo e a esquiva parece bom e com peso em Godot, com os números dos GDDs. A mecânica bate com os GDDs nos cenários T1 a T5. O marco M2 ("Combate prova") tem o veredito PROCEED. Ressalvas: foi um único playtester interno, sem tester externo; e os achados de balanço abaixo (câmara fácil para jogo agressivo) ficam para o Design e o `/balance-check`. Revisão do Creative Director: CD-PLAYTEST pulada, modo Lean.

## If Proceeding

- **Valores que funcionaram (mecanicamente):** todos os do `tuning.json`; D 9, E 3, R 42, cargas 1 (+1 por bênção), hitstop 3/3/6, janela de combo 34, recuperação 8.
- **Assumptions confirmed:** a janela de esquiva de 12 passos tem folga contra a reação de 15 passos (preparo 26); o contrato de invulnerabilidade do Movimento F4 vale; combo e hitstop batem com o Combate F1/F9.
- **Assumptions disproved / a tratar:** ver "Achados para o Design" abaixo.
- **Emergent:** inimigos sem colisão com o jogador se empilham em cima dele.

**Next steps** (os GDDs já existem, então o caminho é o da Fase 4 do plano): `/test-setup` (4.1), `/create-architecture` e `/architecture-decision` (4.2, incluindo o ADR do corpo do jogador), depois épicos e histórias (4.3). O código de produção é escrito do zero; este protótipo não é migrado.

## If Pivoting / If Killing

Não aplicável: veredito PROCEED.

---

## Achados para o Design (não alterei GDDs)

1. **Câmara fácil demais para jogo agressivo (IA R12, Combate F11, Armas F3):** DPS da Lâmina (~88/s) contra Eco de 30 de Vida mata antes do ciclo `espera_inicial` (20–69 passos) + `preparo` (26). Só 1–2 disparos de melee em 13 abates. A meta 25% de Vida por câmara não aparece com este bot. Vale conferir o `/balance-check` e o orçamento de ondas (Câmaras), e se o jogador mediano é menos agressivo.
2. **Sem colisão corpo a corpo jogador–inimigo (IA R9 só separa inimigos):** o Eco anda até sobrepor o jogador (distância ~1 px) e, com a mira travada no começo do preparo, o setor pode apontar para o lado errado e errar mesmo com o jogador parado (T3: 3 disparos, 1 acerto). Definir o que acontece quando o inimigo encosta (empurra o jogador ou para a 78 px).
3. **Faixa da Anomalia ocupa a tela inteira (Telégrafos F3, 81 × 1728 px):** legível, mas dois tiros cruzados cobrem metade da câmara; conferir leitura com mais de 2 atiradores.
4. **ADR pendente (Movimento Overview):** o protótipo usou círculos próprios, sem `CharacterBody2D`. Não foi comparado. `docs/engine-reference/godot/modules/physics.md` continua sem cobrir o 2D no 4.7: **NOT SOURCEABLE** para a decisão.
5. **Não testados (fora do escopo):** câmera e lookahead, ordenação 3/4, Selo/Fluxo, Portas, gamepad, mira automática, Telemetria.
6. **Cross-review (CONCERNS parcial):** nenhuma divergência de número entre Movimento, Combate, Telégrafos e IA apareceu nos cenários T1–T5. Os ACs e Edge Cases não checados em cruzado seguem não checados.

## Lessons Learned

- **O que quebrou:** a primeira câmara (4 inimigos, 1 onda) era trivial; foi preciso 3 ondas e elites para o telégrafo ser exercitado, e ainda assim o bot agressivo o evita.
- **O que surpreendeu:** esquivar para fora da forma travada libera 100% do preparo, e a invulnerabilidade só aparece quando o jogador não tem para onde ir (parede).
- **O que testar diferente:** uma sessão humana filmada; um bot "cauteloso" (só ataca em recuperação); e uma câmara de profundidade 0 e outra de profundidade 6.

---

> *Prototype code location: `prototypes/combate-camara-concept/`*
> *This code is throwaway. Never refactor into production.*

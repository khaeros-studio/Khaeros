# Systems Index: Khaeros

> **Status**: Approved (enumeração, dependências e prioridades aprovadas pelo CD em 2026-11-05)
> **Created**: 2026-11-05
> **Last Updated**: 2026-11-11 (Telemetria local Approved (22/22 MVP); antes, Feedback de combate Approved; antes, Tela de bênção e carta Approved; antes, HUD Approved; antes, Economia de Fragmentos Approved; antes, Bênçãos (Tradições) Approved; antes, Run e regiões Approved; antes, Portas e recompensas Approved; antes, Câmaras e ondas Approved; antes, IA de inimigos e elites Approved; antes, Telégrafos Approved; antes, Efeitos de status Approved; antes, 2026-11-10: Selo e Fluxo Approved; antes, Armas das Doutrinas Approved; antes, Pipeline visual Approved. Antes, 2026-11-09: Combate núcleo Approved; ciclos Movimento ↔ Combate e Combate ↔ IA em Circular Dependencies. Antes, 2026-11-08: Movimento e esquiva Approved: `/design-review` NEEDS REVISION → revisado → re-review APPROVED. Antes, 2026-11-06: 2ª passada do `/review-all-gdds`: CONCERNS, 0 bloqueantes; Next Steps atualizado. Antes: warnings da 1ª passada aplicados em Cena 3/4 e Modificadores, os dois voltam a In Review; C-W6 na Foundation Layer)
> **Source Concept**: design/gdd/game-concept.md (v1.0)
> **Art Bible**: design/art/art-bible.md (aprovado)
> **Revisões de diretor**: TD-SYSTEM-BOUNDARY, PR-SCOPE e CD-SYSTEMS puladas — modo lean (`modes.rigor: standard`)

---

## Overview

Khaeros é um roguelike de ação sala-a-sala em câmera 3/4 (referência de gênero:
Hades II), no universo canônico do repo Khaeros. O loop que o MVP precisa provar
é o canônico do modo de ação: **câmara → bênção → porta** (baseline §54.2), com
**Restart Rate ≥ 40%** como métrica-chave. Os sistemas se organizam em torno de
cinco pilares: P1 *Toda bênção é uma filosofia*, P2 *A Beira cobra*, P3 *Reflexo
que se lê*, P4 *Ritual, não pressão*, P5 *O mundo não se explica de uma vez*.

**Fundação e núcleo.** Todo valor de jogo vive em **dados** (Resources `.tres`),
nunca no código. Um sistema de **modificadores** é o encanamento comum por onde
bênçãos, melhorias da Oficina e efeitos de status alteram atributos; sem ele cada
bênção vira código especial. O **RNG com seed** torna cada run reproduzível
(bugs, playtests, um futuro "seed do dia"), sem trazer de volta o servidor do
modo web. **Input**, **cena 3/4** e **pipeline visual** dão a base que o Art
Bible exige: 11 camadas de render (9 de arte), y-sort, grading regional por shader, telégrafo em SDF.

**Combate (P3).** **Movimento e esquiva** (invulnerabilidade, cargas,
cancelamento) e o **combate núcleo** (hitbox, dano, Vida, hitstop, empurrão,
cambaleio, "Quebrou!", impacto na parede — tudo herdado do baseline §55) são o
coração do jogo e o maior gargalo. Sobre eles ficam as **armas das 6
Doutrinas** (MVP: Lâmina e Ressonância), o **Selo** com seu recurso **Fluxo**, os
**status**, os **telégrafos** no chão e a **IA** de Ecos e Anomalias, com elites.

**A run (P2).** **Câmaras e ondas** fecham a porta e soltam inimigos;
**portas e recompensas** mostram o que vem a seguir (bênção, Fragmentos, cura,
Altar de Provação, Santuário Esquecido); a **run** encadeia Limiar da Beira →
Veio Instável. As **bênçãos** são as 18 Tradições canônicas (P1), oferecidas
pelos **Mestres** de cada Doutrina. A **economia de Fragmentos de Eco** liga a
run à meta.

**Meta e Campus (P4).** **Oficina de Reforja** (as 6 melhorias canônicas),
**desbloqueio de armas**, **Rito de Iniciação** (nome, aparência, Doutrina
jurada) e o **Campus** como hub dão o ritual de voltar, melhorar e descer de
novo. **Diálogo e lore** entregam falas curtas e fragmentos dentro da Lore
Freeze (P5).

**Apresentação e polimento.** HUD, componente de carta (bênção, arma, Oficina),
menus, feedback de combate (VFX), áudio, acessibilidade (as 12 opções do Art
Bible §7.9), localização e **telemetria local** (Restart Rate, mortes,
escolhas).

**Fora do escopo:** ranking online, servidor e Zero-Trust; Benfeitores e
monetização; bênçãos duplas; aspectos de arma; Beira Profunda e Cidade da Cratera
(congeladas no cânone). A ferramenta de recorte de arte é ferramental, não
sistema de jogo (Art Bible §8.8).

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Conteúdo orientado a dados (inferred) | Core | MVP | Approved | [conteudo-orientado-a-dados.md](conteudo-orientado-a-dados.md) | — |
| 2 | Modificadores e atributos (inferred) | Core | MVP | Approved | [modificadores-e-atributos.md](modificadores-e-atributos.md) | Conteúdo orientado a dados |
| 3 | RNG com seed (inferred) | Core | MVP | Approved | [rng-com-seed.md](rng-com-seed.md) | Conteúdo orientado a dados (suave) |
| 4 | Input e controle (inferred) | Core | MVP | Approved | [input-e-controle.md](input-e-controle.md) | Conteúdo orientado a dados (suave), Cena 3/4 e câmera (forte, mira do mouse) |
| 5 | Cena 3/4 e câmera | Core | MVP | Approved | [cena-3-4-e-camera.md](cena-3-4-e-camera.md) | Conteúdo orientado a dados (suave), Input e controle (suave, lookahead; ciclo por contrato) |
| 6 | Pipeline visual | Core | MVP | Approved | [pipeline-visual.md](pipeline-visual.md) | Cena 3/4 e câmera, Conteúdo orientado a dados, Combate núcleo (suave, por contrato), Movimento e esquiva (suave), Run e regiões (suave, por contrato), Câmaras e ondas (suave, por contrato) |
| 7 | Movimento e esquiva | Gameplay | MVP | Approved | [movimento-e-esquiva.md](movimento-e-esquiva.md) | Input e controle, Cena 3/4 e câmera, Modificadores e atributos, Conteúdo orientado a dados |
| 8 | Combate núcleo | Gameplay | MVP | Approved | [combate-nucleo.md](combate-nucleo.md) | Movimento e esquiva, Modificadores e atributos, Conteúdo orientado a dados, Input e controle, IA de inimigos e elites (por contrato), Câmaras e ondas (suave, por contrato) |
| 9 | Armas das Doutrinas | Gameplay | MVP | Approved | [armas-das-doutrinas.md](armas-das-doutrinas.md) | Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados, Input e controle, Tela de bênção e componente de carta (suave, por contrato) |
| 10 | Selo e Fluxo | Gameplay | MVP | Approved | [selo-e-fluxo.md](selo-e-fluxo.md) | Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados, Input e controle, Movimento e esquiva (suave), Armas das Doutrinas (suave), IA de inimigos e elites (por contrato), Câmaras e ondas (suave, por contrato), Run e regiões (suave, por contrato) |
| 11 | Efeitos de status (inferred) | Gameplay | MVP | Approved | [efeitos-de-status.md](efeitos-de-status.md) | Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados, Selo e Fluxo (suave), Armas das Doutrinas (suave), IA de inimigos e elites (por contrato), Câmaras e ondas (suave, por contrato) |
| 12 | Criatura do pacto | Gameplay | Alpha | Not Started | — | Armas das Doutrinas, IA de inimigos e elites |
| 13 | Telégrafos | Gameplay | MVP | Approved | [telegrafos.md](telegrafos.md) | Pipeline visual, Combate núcleo, Conteúdo orientado a dados, IA de inimigos e elites (por contrato), Câmaras e ondas (suave, por contrato) |
| 14 | IA de inimigos e elites | Gameplay | MVP | Approved | [ia-de-inimigos-e-elites.md](ia-de-inimigos-e-elites.md) | Combate núcleo, Telégrafos, RNG com seed, Conteúdo orientado a dados, Modificadores e atributos, Selo e Fluxo (suave), Efeitos de status (suave), Câmaras e ondas (por contrato), Movimento e esquiva (suave) |
| 15 | Chefes | Gameplay | Vertical Slice | Not Started | — | IA de inimigos e elites, Telégrafos, Modificadores e atributos |
| 16 | Câmaras e ondas | Gameplay | MVP | Approved | [camaras-e-ondas.md](camaras-e-ondas.md) | IA de inimigos e elites, RNG com seed, Conteúdo orientado a dados, Cena 3/4 e câmera, Modificadores e atributos, Combate núcleo (por contrato), Portas e recompensas (por contrato), Run e regiões (por contrato) |
| 17 | Portas e recompensas | Gameplay | MVP | Approved | [portas-e-recompensas.md](portas-e-recompensas.md) | Câmaras e ondas, RNG com seed, Conteúdo orientado a dados, Run e regiões (por contrato), Bênçãos (Tradições) (por contrato), Economia de Fragmentos (suave, por contrato) |
| 18 | Run e regiões | Gameplay | MVP | Approved | [run-e-regioes.md](run-e-regioes.md) | Câmaras e ondas, Portas e recompensas, Chefes (a partir da fatia vertical, reservado), Conteúdo orientado a dados, RNG com seed, Combate núcleo (suave), Bênçãos (Tradições) (por contrato), Economia de Fragmentos (por contrato) |
| 19 | Bênçãos (Tradições) | Gameplay | MVP | Approved | [bencaos-tradicoes.md](bencaos-tradicoes.md) | Modificadores e atributos, RNG com seed, Armas das Doutrinas (suave), Conteúdo orientado a dados, Portas e recompensas, Run e regiões (suave) |
| 20 | Mestres ofertantes | Narrative | Vertical Slice | Not Started | — | Bênçãos (Tradições), Diálogo e lore |
| 21 | Economia de Fragmentos | Economy | MVP | Approved | [economia-de-fragmentos.md](economia-de-fragmentos.md) | Run e regiões (por contrato), Portas e recompensas (por contrato), Conteúdo orientado a dados |
| 22 | Oficina de Reforja | Progression | Vertical Slice | Not Started | — | Economia de Fragmentos, Modificadores e atributos, Save e perfil, Conteúdo orientado a dados |
| 23 | Desbloqueio de armas | Progression | Alpha | Not Started | — | Economia de Fragmentos, Armas das Doutrinas, Save e perfil |
| 24 | Rito de Iniciação e criação do Iniciado | Progression | Vertical Slice | Not Started | — | Armas das Doutrinas, Save e perfil, Diálogo e lore |
| 25 | Campus (hub) | Meta | Vertical Slice | Not Started | — | Oficina de Reforja, Desbloqueio de armas, Rito de Iniciação e criação do Iniciado, Mestres ofertantes |
| 26 | Diálogo e lore (inferred) | Narrative | Vertical Slice | Not Started | — | Conteúdo orientado a dados, Localização |
| 27 | Save e perfil (inferred) | Persistence | Vertical Slice | Not Started | — | Conteúdo orientado a dados |
| 28 | HUD | UI | MVP | Approved | [hud.md](hud.md) | Combate núcleo, Selo e Fluxo, Movimento e esquiva, Economia de Fragmentos, Chefes (barra de chefe, fatia vertical) |
| 29 | Tela de bênção e componente de carta | UI | MVP | Approved | [tela-de-bencao-e-carta.md](tela-de-bencao-e-carta.md) | Bênçãos (Tradições), Mestres ofertantes (retrato, fatia vertical), Input e controle |
| 30 | Menus (inferred) | UI | Vertical Slice | Not Started | — | Save e perfil, Input e controle |
| 31 | Feedback de combate (VFX) | UI | MVP | Approved | [feedback-de-combate.md](feedback-de-combate.md) | Combate núcleo, Pipeline visual, Telégrafos, Cena 3/4 e câmera |
| 32 | Áudio (inferred) | Audio | Vertical Slice | Not Started | — | Combate núcleo, Telégrafos, Run e regiões |
| 33 | Acessibilidade e opções | Meta | Vertical Slice | Not Started | — | HUD, Tela de bênção e componente de carta, Menus, Feedback de combate (VFX), Input e controle |
| 34 | Localização (inferred) | Meta | Vertical Slice | Not Started | — | — |
| 35 | Telemetria local | Meta | MVP | Approved | [telemetria-local.md](telemetria-local.md) | Run e regiões, Bênçãos (Tradições), RNG com seed |

**Escopo de conteúdo por nível** (o sistema é um só; o conteúdo cresce):
- **Armas das Doutrinas:** MVP = Lâmina e Ressonância (decisão do CD); fatia
  vertical = + Guardião e Véu; Alpha = + Transmutação e Pactos (com a Criatura do
  pacto).
- **Run e regiões:** MVP = Limiar da Beira sem chefe; fatia vertical = Limiar
  completo com a Anomalia Maior; Alpha = + Veio Instável e Guardião do Rito.
- **Economia de Fragmentos:** MVP = só contar e mostrar; fatia vertical = gastar
  na Oficina.

---

## Categories

| Category | Description | Neste jogo |
|----------|-------------|------------|
| **Core** | Fundação de que tudo depende | dados, modificadores, RNG, input, cena 3/4, pipeline visual |
| **Gameplay** | O que torna o jogo divertido | movimento, combate, armas, Selo, status, telégrafos, IA, chefes, câmaras, portas, run, bênçãos, criatura do pacto |
| **Progression** | Crescimento entre runs | Oficina de Reforja, desbloqueio de armas, Rito de Iniciação |
| **Economy** | Criação e gasto de recurso | Fragmentos de Eco da Beira |
| **Persistence** | Continuidade | save e perfil |
| **UI** | Informação na tela | HUD, cartas, menus, feedback de combate |
| **Audio** | Som e música | áudio |
| **Narrative** | Entrega de história | Mestres ofertantes, diálogo e lore |
| **Meta** | Fora do loop principal | Campus, acessibilidade, localização, telemetria |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Necessário para o loop câmara → bênção → porta funcionar. Sem isso não dá para testar "é divertido?" | M2 — combate prova (protótipo) | Design FIRST |
| **Vertical Slice** | Uma região completa e polida: Campus → Limiar → Anomalia Maior → Campus | M3 — fatia vertical | Design SECOND |
| **Alpha** | Todo o escopo mecânico canônico: 6 armas, 2 regiões, 2 chefes | Alpha | Design THIRD |
| **Full Vision** | Polimento, casos de borda, conteúdo extra e decisões de CD congeladas | Beta / Release | Design as needed |

**Por que cada nível** (do diálogo com o CD em 2026-11-05):
- **MVP (22):** sem esses o loop de 30 segundos não existe — lutar e ler o
  telégrafo (P3), escolher a bênção (P1) e a porta (P2). A telemetria entra cedo
  porque o Restart Rate é o que dá veredito ao MVP.
- **Fatia vertical (11):** a experiência completa de uma região — o ritual de
  voltar ao Campus, melhorar e descer de novo (P4), a voz dos Mestres (P1) e o
  primeiro chefe.
- **Alpha (2 + conteúdo):** o resto do jogo canônico — a segunda região e todas
  as Doutrinas, incluindo Pactos com a criatura.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Conteúdo orientado a dados — todo valor de jogo vive em dados (padrão de código do estúdio)
2. RNG com seed — todo sorteio passa por ele, para a run ser reproduzível (suave: ordem do manifesto e impressão do catálogo do Conteúdo)
3. Input e controle — teclado/mouse e gamepad jogáveis, remapeamento completo nos dois, buffer de 10 passos (suave: Conteúdo; forte: Cena 3/4, conversão tela → mundo da mira do mouse)
4. Cena 3/4 e câmera — viewport 1920×1080, plano de jogo = tela, y-sort em 11 camadas de render (9 de arte), câmera com limites (suave: Conteúdo; suave por contrato: Input, lookahead)
5. Localização — textos fora do código desde o início (PT-BR primeiro)

### Core Layer (depends on foundation)

1. Modificadores e atributos — depends on: Conteúdo orientado a dados
2. Pipeline visual — depends on: Cena 3/4 e câmera
3. Movimento e esquiva — depends on: Input e controle, Cena 3/4 e câmera, Modificadores e atributos, Conteúdo orientado a dados
4. Combate núcleo — depends on: Movimento e esquiva, Modificadores e atributos, Conteúdo orientado a dados, Input e controle
5. Save e perfil — depends on: Conteúdo orientado a dados

### Feature Layer (depends on core)

1. Armas das Doutrinas — depends on: Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados
2. Selo e Fluxo — depends on: Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados, Input e controle
3. Efeitos de status — depends on: Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados
4. Telégrafos — depends on: Pipeline visual, Combate núcleo
5. IA de inimigos e elites — depends on: Combate núcleo, Telégrafos, RNG com seed, Conteúdo orientado a dados, Modificadores e atributos
6. Criatura do pacto — depends on: Armas das Doutrinas, IA de inimigos e elites
7. Chefes — depends on: IA de inimigos e elites, Telégrafos, Modificadores e atributos (fonte `chefe`)
8. Câmaras e ondas — depends on: IA de inimigos e elites, RNG com seed, Conteúdo orientado a dados, Cena 3/4 e câmera, Modificadores e atributos (fonte `profundidade`)
9. Portas e recompensas — depends on: Câmaras e ondas, RNG com seed, Conteúdo orientado a dados
10. Run e regiões — depends on: Câmaras e ondas, Portas e recompensas, Chefes, Conteúdo orientado a dados, RNG com seed
11. Bênçãos (Tradições) — depends on: Modificadores e atributos, RNG com seed, Armas das Doutrinas, Conteúdo orientado a dados
12. Diálogo e lore — depends on: Conteúdo orientado a dados, Localização
13. Mestres ofertantes — depends on: Bênçãos (Tradições), Diálogo e lore
14. Economia de Fragmentos — depends on: Run e regiões, Portas e recompensas, Conteúdo orientado a dados
15. Oficina de Reforja — depends on: Economia de Fragmentos, Modificadores e atributos, Save e perfil, Conteúdo orientado a dados
16. Desbloqueio de armas — depends on: Economia de Fragmentos, Armas das Doutrinas, Save e perfil
17. Rito de Iniciação e criação do Iniciado — depends on: Armas das Doutrinas, Save e perfil, Diálogo e lore
18. Campus (hub) — depends on: Oficina de Reforja, Desbloqueio de armas, Rito de Iniciação, Mestres ofertantes

### Presentation Layer (depends on features)

1. HUD — depends on: Combate núcleo, Selo e Fluxo, Movimento e esquiva, Economia de Fragmentos, Chefes
2. Tela de bênção e componente de carta — depends on: Bênçãos (Tradições), Mestres ofertantes, Input e controle
3. Menus — depends on: Save e perfil, Input e controle
4. Feedback de combate (VFX) — depends on: Combate núcleo, Pipeline visual, Telégrafos, Cena 3/4 e câmera
5. Áudio — depends on: Combate núcleo, Telégrafos, Run e regiões

### Polish Layer (depends on everything)

1. Acessibilidade e opções — depends on: HUD, Tela de bênção e componente de carta, Menus, Feedback de combate (VFX), Input e controle
2. Telemetria local — depends on: Run e regiões, Bênçãos (Tradições), RNG com seed

**Gargalos (muitos dependentes — alto risco):** Modificadores e atributos;
Combate núcleo (o mais carregado); Conteúdo orientado a dados; IA de inimigos e
elites; Câmaras e ondas.

**Folhas (podem ser desenhadas por último):** Acessibilidade, Telemetria,
Campus, Menus.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Conteúdo orientado a dados | MVP | Foundation | systems-designer, godot-specialist | S |
| 2 | RNG com seed | MVP | Foundation | systems-designer | S |
| 3 | Input e controle | MVP | Foundation | game-designer, ux-designer | S |
| 4 | Cena 3/4 e câmera | MVP | Foundation | game-designer, technical-artist | M |
| 5 | Modificadores e atributos | MVP | Core | systems-designer | M |
| 6 | Movimento e esquiva | MVP | Core | game-designer | M |
| 7 | Combate núcleo | MVP | Core | game-designer, systems-designer | L |
| 8 | Pipeline visual | MVP | Core | technical-artist, godot-shader-specialist | M |
| 9 | Armas das Doutrinas (Lâmina, Ressonância) | MVP | Feature | game-designer, systems-designer | M |
| 10 | Selo e Fluxo | MVP | Feature | game-designer | S |
| 11 | Efeitos de status | MVP | Feature | systems-designer | S |
| 12 | Telégrafos | MVP | Feature | game-designer, technical-artist | M |
| 13 | IA de inimigos e elites | MVP | Feature | ai-programmer, game-designer | L |
| 14 | Câmaras e ondas | MVP | Feature | level-designer, systems-designer | M |
| 15 | Portas e recompensas | MVP | Feature | game-designer, economy-designer | M |
| 16 | Bênçãos (Tradições) | MVP | Feature | game-designer, systems-designer | L |
| 17 | Run e regiões (Limiar) | MVP | Feature | game-designer, level-designer | M |
| 18 | Economia de Fragmentos | MVP | Feature | economy-designer | S |
| 19 | HUD | MVP | Presentation | ux-designer, art-director | M |
| 20 | Tela de bênção e componente de carta | MVP | Presentation | ux-designer, art-director | M |
| 21 | Feedback de combate (VFX) | MVP | Presentation | technical-artist, art-director | M |
| 22 | Telemetria local | MVP | Polish | analytics-engineer | S |
| 23 | Chefes (Anomalia Maior) | Vertical Slice | Feature | game-designer, ai-programmer | L |
| 24 | Localização | Vertical Slice | Foundation | localization-lead | S |
| 25 | Diálogo e lore | Vertical Slice | Feature | narrative-director, writer | M |
| 26 | Mestres ofertantes | Vertical Slice | Feature | narrative-director, game-designer | M |
| 27 | Save e perfil | Vertical Slice | Core | systems-designer | M |
| 28 | Oficina de Reforja | Vertical Slice | Feature | economy-designer, systems-designer | M |
| 29 | Rito de Iniciação e criação do Iniciado | Vertical Slice | Feature | game-designer, narrative-director, ux-designer | M |
| 30 | Campus (hub) | Vertical Slice | Feature | level-designer, game-designer | L |
| 31 | Menus | Vertical Slice | Presentation | ux-designer | M |
| 32 | Áudio | Vertical Slice | Presentation | audio-director, sound-designer | M |
| 33 | Acessibilidade e opções | Vertical Slice | Polish | accessibility-specialist, ux-designer | M |
| 34 | Criatura do pacto | Alpha | Feature | game-designer, ai-programmer | L |
| 35 | Desbloqueio de armas | Alpha | Feature | economy-designer | S |

S = 1 sessão, M = 2–3 sessões, L = 4+ sessões. Sistemas independentes da mesma
camada podem ser desenhados em paralelo.

---

## Circular Dependencies

- **Run e regiões ↔ Economia de Fragmentos.** A run gera Fragmentos e a economia
  define quanto cada fonte paga. **Resolução por contrato:** a Economia é dona
  das taxas (em dados); a Run só emite eventos (`camara_limpa`, `chefe_derrotado`,
  `vitoria`, `provacao_vencida`). Nenhum dos dois chama o outro diretamente.
- **Input e controle ↔ IA de inimigos e elites.** A IA depende do Combate, que
  depende do Movimento, que depende do Input; o Input usa a consulta de alvos da
  IA para a mira automática do gamepad. **Resolução por contrato:** o Input só
  define a interface da consulta; a IA a implementa e ela é injetada. Nenhum dos
  dois chama o outro diretamente.
- **Input e controle ↔ Cena 3/4 e câmera.** O Input usa a conversão tela → mundo
  da Cena para a mira do mouse (Cena R9/F6). A Cena usa a fonte da mira, a
  intensidade e a consulta de cursor do Input para o lookahead (Input R2/R5, Cena
  F2). **Resolução por contrato:** os dois lados só expõem interfaces de leitura,
  injetadas. Nenhum chama a lógica do outro (decisão do usuário, 2026-11-06).
- **Movimento e esquiva ↔ Combate núcleo.** O Combate depende da posição e da
  consulta "em esquiva"; o Movimento depende da recuperação, da investida e da
  invulnerabilidade do Combate. **Resolução por contrato:** o Movimento define a
  interface (consultas e pedidos, Movimento OQ2); o Combate a implementa (Combate
  R18), injetada. Nenhum chama a lógica interna do outro (2026-11-09).
- **Combate núcleo ↔ IA de inimigos e elites.** A IA depende do dano, do
  cambaleio e do "Quebrou!"; o Combate precisa do estado da IA e da lista de
  inimigos. **Resolução por contrato:** o Combate define a interface (estado,
  pedido de "Quebrou!", `ferir_jogador`, `disparar_projetil`); a IA a implementa
  e chama, por injeção (Combate Dependencies, 2026-11-09).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Combate núcleo | Design / Technical | A sensação do baseline §55 (hitstop, buffer, cancelamento) foi provada em TypeScript, não em Godot; se o combate não for bom, nada mais importa | Protótipo de uma câmara logo após o GDD (`/prototype combate-camara`), com veredito PROCEED/PIVOT/KILL |
| Modificadores e atributos | Technical / Scope | Gargalo: bênçãos, Oficina e status escrevem nele; um modelo errado obriga a reescrever os três | Desenhar antes de qualquer bênção; ADR crítico na arquitetura; testes unitários das fórmulas |
| Pipeline visual | Technical | Vários pontos do Godot 4.7 estão marcados NÃO VERIFICADO no Art Bible §8.6 (contagem de draw calls 2D, `TIME` no hitstop, global uniforms com sampler) | Medir no protótipo: captura no PIX/RenderDoc, A/B dos fundos |
| Bênçãos (Tradições) | Design | Os 18 efeitos de `arenaContent.ts` são placeholders calibrados por piloto automático, não por pessoas | Playtest humano + telemetria de escolha; `/balance-check` antes da fatia vertical |
| Criatura do pacto | Design / Technical | Aliado com IA própria precisa ser legível como aliado (Art Bible §3.3, §5.5) e não roubar o protagonismo | Protótipo isolado antes do Alpha; regras de leitura do Art Bible como critério de aceite |
| Animação por rig 2D com arte de IA (afeta Armas, IA, Chefes) | Technical / Scope | Risco de cara de "boneco recortado"; folhas de IA não mantêm consistência entre poses | Testar o rig com o Iniciado (Lâmina) no protótipo de combate; regra de pose alta (Art Bible §5.8) |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 35 |
| Design docs started | 22 |
| Design docs reviewed | 22 |
| Design docs approved | 22 |
| MVP systems designed | 22/22 |
| Vertical Slice systems designed | 0/11 |

---

## Next Steps

- [x] Review and approve this systems enumeration (CD, 2026-11-05)
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`, na ordem acima) — 17/22: Bênçãos (Tradições) (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 5 bloqueantes (F7 do RNG, índice no manifesto, chave do pedido, pool menor que 3, arredondamento) — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Run e regiões (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 5 bloqueantes (sequência jogável, `RunTuning`, saldo de Fragmentos fora do reset, ciclo de estados, ordem da vitória) — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Portas e recompensas (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 3 bloqueantes — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Câmaras e ondas (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 3 bloqueantes — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); IA de inimigos e elites (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 2 bloqueantes — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Telégrafos (`/design-system` 2026-11-11; revisão única por subagente: NEEDS REVISION, 5 bloqueantes de contrato — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Efeitos de status (`/design-system` 2026-11-10; revisão única por subagente: NEEDS REVISION, 4 bloqueantes de texto — corrigidos sem re-review; **Approved** pelo usuário em 2026-11-11; sem entrada no review log); Selo e Fluxo (`/design-system` 2026-11-10; revisão única por subagente: NEEDS REVISION, 5 bloqueantes de contrato — corrigidos sem re-review; **Approved** pelo usuário; sem entrada no review log); Armas das Doutrinas (`/design-system` 2026-11-10; `/design-review` por subagente: NEEDS REVISION, 6 bloqueantes — revisados; re-review por script: 4 nos critérios — revisados; **Approved** pelo usuário); Pipeline visual (`/design-system` 2026-11-10; `/design-review` por subagentes: NEEDS REVISION, 7 bloqueantes nas regras e 9 nos critérios — revisados; re-review NEEDS REVISION leve — revisado; **Approved** pelo usuário; sem entrada no review log); Combate núcleo (`/design-system` 2026-11-09; `/design-review` por subagentes: NEEDS REVISION, 3 bloqueantes nas regras e 8 nos critérios — revisados; re-review: regras APPROVED, critérios com 2 correções aplicadas; **Approved** pelo usuário; sem entrada no review log); Movimento e esquiva (`/design-review` 2026-11-08, nesta aba por subagentes: NEEDS REVISION, 6 bloqueantes — revisados; re-review 2026-11-08: **APPROVED**, 0 bloqueantes, 4 recomendadas aplicadas, incluindo o pedido `deslocar(v)` do Combate; sem entrada no review log); Conteúdo orientado a dados (`/design-review` 2026-11-05: NEEDS REVISION, 3 bloqueantes — revisados; re-review 2026-11-05: NEEDS REVISION, 1 bloqueante, a impressão do catálogo — revisado com a R12; re-review 2026-11-06: NEEDS REVISION, 2 bloqueantes — unidade do empurrão e chefe do Limiar no MVP — revisados em 2026-11-06; 2ª e 3ª re-reviews independentes 2026-11-06: NEEDS REVISION — revisadas; 4ª re-review 2026-11-06: **APPROVED**, 0 bloqueantes, 6 recomendadas; ver `reviews/conteudo-orientado-a-dados-review-log.md`); RNG com seed (`/design-review` 2026-11-05: NEEDS REVISION, 2 bloqueantes no contrato R7 — revisados; re-review 2026-11-05: **APPROVED**, 0 bloqueantes, 5 recomendadas); Input e controle (`/design-review` 2026-11-05: NEEDS REVISION, 3 bloqueantes — revisados em 2026-11-06; 2ª e 3ª re-reviews 2026-11-06: NEEDS REVISION — revisadas; 4ª re-review 2026-11-06: **APPROVED**, 0 bloqueantes; ver `reviews/input-e-controle-review-log.md`); Cena 3/4 e câmera (`/design-review` 2026-11-05: NEEDS REVISION, 2 bloqueantes — contrato de camadas/parallax e câmera a 60 Hz × render — revisados (F7, P interpolado); re-review 2026-11-05: **APPROVED**, 0 bloqueantes, 4 recomendadas; warnings da 1ª passada do `/review-all-gdds` aplicados em 2026-11-06 → In Review; re-review 2026-11-08: **APPROVED**, 0 bloqueantes, 4 recomendadas — 3 aplicadas na mesma sessão (justificativa do hitstop na R7, relógio injetado, caso sem `CameraTuning`); a C-I5 do índice segue aberta; ver `reviews/cena-3-4-e-camera-review-log.md`); Modificadores e atributos (`/design-review` 2026-11-06: NEEDS REVISION, 5 bloqueantes — revisados; re-review 2026-11-06: NEEDS REVISION, 1 bloqueante — momento de M na investida (R12) — revisado em 2026-11-06; re-review 2026-11-06: **APPROVED**, 0 bloqueantes, 2 recomendadas — aplicadas na mesma sessão; warnings da 1ª passada do `/review-all-gdds` aplicados em 2026-11-06 → In Review; re-review 2026-11-08: **APPROVED**, 0 bloqueantes, 3 opcionais não aplicados, sem entrada no log; ver `reviews/modificadores-e-atributos-review-log.md`)
- [ ] `/review-all-gdds` dos 5 GDDs MVP: 1ª passada 2026-11-06 **FAIL** (C-B1, S-B1; `gdd-cross-review-2026-11-06.md`) — resolvidos; 2ª passada 2026-11-06 **CONCERNS**, 0 bloqueantes (`gdd-cross-review-2026-11-06b.md`). Warnings curtos aplicados na mesma data: Conteúdo (AC-39, params da `recusa`, retirada do Tuning ao sair de Pronto, AC-51), Input (R12), Modificadores (dependentes Câmaras e ondas e Chefes) e este índice (Depends On de Câmaras e ondas e de Chefes); Conteúdo e Input seguem Approved (decisão do usuário). Os `/design-review` de Cena 3/4 e de Modificadores deram APPROVED em 2026-11-08. Pendentes: infos e requisitos para GDDs não escritos no relatório
- [ ] 📌 UX: `/ux-design` da tela de erros do catálogo (Conteúdo orientado a dados, UI Requirements) na pré-produção, antes dos épicos
- [ ] Prototipar o combate logo após o GDD de Combate núcleo (`/prototype combate-camara`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check technical-setup` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production

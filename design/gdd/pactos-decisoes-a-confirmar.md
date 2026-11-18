# Pactos no MVP — decisões a confirmar (2026-11-16)

> **Aprovado pelo usuário em 2026-11-16** ("Aprovar todas"): as 21 decisões
> abaixo valem como estão. Todo marcador provisório dos GDDs do lote que apontava
> para um item desta lista foi confirmado por esta aprovação e consolidado nos
> respectivos GDDs em **2026-11-18** (`Status: Approved` em todos os 26 GDDs do MVP).

Lote feito por agentes a pedido do usuário ("termine todos os GDD usando os
agentes"). Cada item abaixo foi decidido por um agente, aprovado pelo usuário em
2026-11-16 e consolidado sem tags provisórias nos GDDs citados em 2026-11-18.

## Estado do lote

- **Novos (Approved):** [vinculo-e-pactos.md](vinculo-e-pactos.md), [save-e-perfil.md](save-e-perfil.md).
- **Emendados (Approved, emenda Pactos):** maldicoes, chefes, armas-das-doutrinas,
  run-e-regioes, economia-de-fragmentos, camaras-e-ondas, portas-e-recompensas,
  combate-nucleo, modificadores-e-atributos, ia-de-inimigos-e-elites, telegrafos,
  input-e-controle, hud, feedback-de-combate, conteudo-orientado-a-dados,
  rng-com-seed, telemetria-local, efeitos-de-status, selo-e-fluxo, pipeline-visual,
  bencaos-tradicoes, tela-de-bencao-e-carta. Mais uma nota de versão no game-concept.
- **Sem mudança:** cena-3-4-e-camera, movimento-e-esquiva.
- **Revisão cruzada (2 revisores independentes, 2026-11-16):** 22 contradições
  achadas, 5 bloqueantes; todas corrigidas. Não houve segunda passada depois das
  correções.

## Combate e Maldições

| # | Decisão | Onde |
|---|---|---|
| 1 | Atração do Chamado 1,5 s, respiro 0,5 s, sem renovação (antes 3,0 s, ficava permanente) | Maldições R17/F4b, IA R17 |
| 2 | Ataque básico −10% (18,00–18,36 DPS); Saída dano 5, Entrada 6–7, técnica máx. 14; meta de paridade ±5% (piso 64,70, teto 69,35 DPS, 4,33%) | Maldições F3/F6, Armas F7, Vínculo F4 |
| 3 | Abalo do *Eco de Muralha* 1,5 s (alternativa 1,0 s), vale contra chefe | Maldições, Status OQ8 |
| 4 | Dupla Espreitador + Baluarte mantém Abalo o tempo todo com trocas: aceito, vigiar no playtest | Maldições |
| 5 | Maldições agem no item 6.1 do passo; Exaustão síncrona (troca automática no mesmo passo) | Combate R1/R23 |
| 6 | Bênçãos propagam `dano_todo_pct` e `velocidade_pct` ao portador da Maldição (fator 1,0); nenhum gatilho propaga | Modificadores R14/F6 |
| 7 | Pouso do Chamado usa o M do Especial do jogador, sem empurrão e sem recuperação | Combate R3.1, Armas |
| 8 | Bind da Troca: R/Tab no teclado e LT no gamepad (Q e LB são do Selo) | Input |
| 9 | `bonus_dano_basico` do vínculo limitado a 0–0,07 | Vínculo |

## Chefe

| # | Decisão | Onde |
|---|---|---|
| 10 | Todo golpe do chefe testa só o alvo travado, inclusive os 12 projéteis; puxão e pulso movem jogador e Maldição | Chefes R3, IA R16, Telégrafos R5a |
| 11 | Em Pactos, abate e `cura_ao_abater` do chefe só no Exorcizar | Chefes R9, Combate R14 |
| 12 | Índice 5 vira câmara comum com recompensa → portas rendem 10, totais 25 (Pactuar) / 31 (Exorcizar) | Run R3-P, Portas, Economia, Chefes F6 |
| 13 | Anomalia Maior: volta na fatia vertical ou sai (no MVP o chefe é o Soberano do Limiar) | game-concept §4/§13 |

## Vínculo, run e save

| # | Decisão | Onde |
|---|---|---|
| 14 | Na 1ª escolha da Besta o jogo concede o *Vulto Mudo* (nunca há 0 pactos) | Vínculo V3, Run R2-P |
| 15 | Encontro só em runs de Pactos; índices 1–2; o 1º é garantido no índice 1 com o *Espreitador*; quem falha ganha encontro garantido na próxima run; Raras pedem 2 encontros vencidos | Vínculo |
| 16 | Anomalias de ordem par miram a acuada; nenhum inimigo nasce a ≤ 240 px dela | IA R22, Câmaras |
| 17 | Pactuar o Soberano já pactuado dá +10 pontos de vínculo (no máximo, vão para a dupla) | Vínculo |
| 18 | Pacto feito numa run perdida continua valendo; sair no meio da run = abandono | Vínculo, Save R10 |
| 19 | A tela de consentimento do pacto usa o estado Bênção | Vínculo V9, Save R5.1 |
| 20 | Um perfil só, sem tela de exportar/importar no MVP | Save R1/R12 |
| 21 | O saldo de Fragmentos continua fora do save (hoje só os pactos persistem) — estranho para o jogador | Economia R7, Save |

## Riscos registrados (não bloqueiam)

- Um telégrafo mirado na Maldição tem o mesmo desenho e não fere o jogador: tensão com P3 (Telégrafos OQ11).
- Besta sem Maldição fica 67% fora da paridade; mitigado pelo item 14.
- Besta com 5 inimigos no Selo: f_selo 42,0% (teto 45%).
- Tradições de slot (Traço Único) sobem só a Besta (~60% do dano) (Bênçãos R14-P).

## Fora dos GDDs (arquitetura, aba de Arquitetura)

ADR novo "Aliados e invocações"; emendas no ADR-0013 (`user://perfil.cfg` no
MVP, seção `[vinculo]` opaca, desconhecidos preservados, gravação fora de Jogo,
saída como abandono), ADR-0010 (item 6.1, `ferir_maldicao`, `ferir_acuada`, alvo
no projétil, `subjugar`), ADR-0012 (chaves de perfil e HUD do Pacto) e ADR-0014
(alvo travado, faixa pelo raio do alvo, contorno secundário).

## Cânone

Proposta da linha "Maldições" em [../narrative/proposta-canone-maldicoes.md](../narrative/proposta-canone-maldicoes.md),
para o usuário gravar no repo Khaeros.

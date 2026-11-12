# Cross-GDD Review Report

> **Date**: 2026-11-11 · **Focus**: full (consistência + holismo + cenários)
> **GDDs reviewed**: 22 de 22 presentes (MVP completo), **lidos por seção, nenhum por inteiro**
> **Verdict**: **FAIL** na rodada de 2026-11-11 (3 bloqueantes) → **CONCERNS (parcial)** no fechamento de 2026-11-12, sem bloqueante conhecido (ver "Fechamento")
> **Parte NOT ASSESSED**: ver "Não lido" (a cobertura é parcial em todas as 4 passadas da Fase 2 e na Fase 3)

**Método e desvio declarado.** Os 22 GDDs somam ~1 MB e não cabem colados nos prompts; cada
subagente leu por seção. A Fase 2 rodou em 4 agentes (um inicial que voltou parcial, e as
Partes A, B e C), a Fase 3 em 1 (parcial) e a Fase 4 foi feita pelo coordenador a partir dos
relatórios. Nenhum agente leu os 22 GDDs por inteiro; o que não foi lido está listado e conta como
NOT ASSESSED, não como "limpo".

Pilares reais (`game-concept.md` §3): **cinco**: P1 *Toda bênção é uma filosofia*, P2 *A Beira
cobra*, P3 *Reflexo que se lê*, P4 *Ritual, não pressão*, P5 *O mundo não se explica de uma vez*.
Anti-pilares: sem online/MMO nem monetização; sem cosmologia nova; sem recriar Hades.

---

## Consistency Issues

### Blocking (3)

🔴 **B1. Pausa em Bênção.** `run-e-regioes.md` R6, Edge Cases e AC-RN-15 e `bencaos-tradicoes.md`
Edge Cases diziam que a pausa não abre em Bênção. `input-e-controle.md` (R10, estados) e
`tela-de-bencao-e-carta.md` (R12, AC-TB-19) dizem que abre por cima. "Abandonar run" mora na
pausa, então a regra de quando se abandona ficava sem dono.

🔴 **B2. Bênção × respostas em curso.** `feedback-de-combate.md` (Edge "Pausa, Bênção", AC-FB-26) dizia
que as respostas retomam; `pipeline-visual.md` (R2, AC-PV-71) diz que números e letreiros somem ao abrir
a Bênção e não voltam. Os dois ACs não passam juntos.

🔴 **B3. Nome do campo do acerto marcado.** `combate-nucleo.md` (R8.2, R17, AC-91) usava `quarto acerto`;
`modificadores-e-atributos.md` e `feedback-de-combate.md` usam `enesimo_acerto`, e o campo não estava na
tabela R17. "Quarto" é falso quando `a_cada` ≠ 4.

### Warnings

⚠️ **Quem envia** o impulso de câmera e o pedido de impact frame: Combate V14 ("o Combate manda"), Cena R8
("Combate e VFX enviam"), Pipeline R7 ("o Combate pede") e Feedback R1/R12 ("o Feedback envia") divergem; a regra
do maior preset tem dois donos.

⚠️ **Política de corte no teto de VFX:** Pipeline R9 e Combate V15 cortam o mais antigo do relógio de apresentação;
Feedback R4 corta por prioridade P4→P2 e inclui o relógio vivo. O impact frame é P0 na R4 e P1 na R3.

⚠️ **Relógio por resposta:** no Feedback R3, morte de inimigo comum, flash da parede, contorno de invulnerabilidade
da recusa, marca do `quebrou` e anel da `area` estão como "apresentação"; Combate V1/V9/V10/V12 os dão como
relógio vivo.

⚠️ **Duração da inversão:** Feedback R12 diz 6 passos; Combate R17/AC-97 dizem 10 (hitstop + 4); no passo da recusa
não está dito se vale 6 ou 18.

⚠️ **Preset de câmera do acerto de projétil:** Feedback R3 emite impulso; Combate V14/AC-72 manda nenhum no Pulso leve.

⚠️ **Cena F5:** não tem "zoom principal" (Combate V14), usa `dir` unitário (V14 usa vetor nulo), soma impulsos
(a regra de um por passo e a `escala` estão só como nota pendente) e usa outro tempo (`ticks_usec`) que o Pipeline `t_apres`.

⚠️ **Ganchos de áudio do acerto marcado:** Combate AC-80b espera 1 leve + 1 pesado; Feedback R3 mapeia `sfx_acerto_critico`;
não diz se substitui ou soma.

⚠️ **"Estado de jogo" sem dono:** HUD R12 diz "estados da Run: Jogo, Pausa, Transição, Encerrada"; a Run tem Sem run,
Escolha de arma, Ativa e Encerrada; o conjunto Jogo/Pausa/Bênção/Menu/Morte/Transição é do orquestrador (Combate R1).
O Input tem contexto Transição sem estado na tabela e a morte vira "Menu".

⚠️ **HUD sem gatilho de volta** depois da Bênção (só escuta `oferta_aberta`; falta `tela_fechada`/`bencao_escolhida`).

⚠️ **Transição de entrada da 1ª câmara** (Run R2 passo 5): a Transição do Combate parte de uma porta; não há porta na
1ª câmara. O "câmara entrou" da Telemetria também depende disso.

⚠️ **"Morte vence a limpeza"** tem três versões (Câmaras: não dá limpa; Run: a Run ignora; Economia: Portas não creditam);
Portas não tem a regra nem AC.

⚠️ **Ordem `run_encerrada` × `creditar(vitoria)`:** Run R4.3 lista `run_encerrada`, soma, abre tela; Economia e
Telemetria exigem o resumo já com o bônus.

⚠️ **Fluxo no início da run:** Run R8/AC-RN-19 dizem 0; Selo R1/AC-SF-06 dizem 100.

⚠️ **`bencao_escolhida`:** a Tela segura até `tela_fechada`; Bênçãos R5/AC-BN-09 emitem em seguida; Tela Dependencies
diz que não emite eventos próprios, mas R9 emite `preco_revelado` e `tela_fechada`; Portas ainda "abre a tela" no R2.2.

⚠️ **Chave de RNG:** RNG F2 diz "número da câmara na run"; Câmaras R3, Portas R7 e Bênçãos R3 dizem "índice na região".
`pedir_oferta` pode receber i ou i+1. **AC-PR-10** e o texto da Portas F3 usam chaves 0,1,2,4,5 e "duas forçadas",
mas as escolhas livres do MVP ocorrem em 0, 1, 3 e 4.

⚠️ **Donos:** `p_max` (Run R9 × Câmaras R3); +5% de Vida por profundidade e elite 2,4/1,25/1,2/0,4 (nenhum GDD assume;
fora do registro); `teto_telegrafos` 24 (Telégrafos × Pipeline R9); base de trocas (`trocas_oferta` no Modificadores ×
`trocas_iniciais` na Bênçãos); `teto_numeros`/`janela_soma_s` (Feedback × Combate V7).

⚠️ **`teto_telegrafos` 24 inalcançável** (máx. 9 inimigos, 1 telégrafo cada); a faixa 12–24 e o TV5 estão justificados com
um raciocínio que não vale.

⚠️ **`tamanho_oferta` 1–5** (Bênçãos BN1, UI) contradiz o consumo fixo de 3 reais (Bênçãos R3/R4).

⚠️ **Dependencies** de uma ponta só: Armas não lista IA, Câmaras nem Run; IA não lista Armas; Movimento ↔ Status; Movimento ↔
Armas; Modificadores sem Status e Armas; Pipeline, Combate, Cena e Input ainda dizem que GDDs existentes "não existem".

⚠️ **Teto de M e status:** `teto_multiplicador_dano` vazio (M máx. ≈ 14,08, DPS ≈ 936 vs Vida do chefe 700); o ST5 testa cada
status sozinho (juntos ≈ 79% do DPS da arma); o M do Selo chega a ≈ 4,2 e o SV12/meta de `f_selo` só vale com M = 1.

⚠️ **Nomes:** "O Preço do Nome" (Bênçãos, Tela) × "O Preço com Nome" (cânone, Modificadores, Armas); notas apontam linhas do
Conteúdo que não existem (linhas 96, 390, 787); `santuario_cura` (nome real) × `cura_santuario` (nas notas); `valid`
V10 do Conteúdo cobre Provação > 0? (nenhuma regra PV detecta).

⚠️ **Exemplo da Run** F2/AC-RN-23 ("coletou 11 e venceu → 26") fora da faixa da Economia (máx. 10 coletados).

⚠️ **Validação:** a faixa de `limiar_nivel2` do Feedback não tem validação (`FB3` só cobre os retornos).

### Info
`jogador_morreu` e `acerto_de_arma` sem linha na tabela R17; `saldo_mudou` com 3º campo `origem`/`motivo`;
recarga do Selo no HUD vs Selo R7 não conferida; registro `entities.yaml` sem teto de 6 números, 300 ms, 64/24/1500/500,
`limite_impacto_s`, `santuario_cura`, `fragmentos_*`, `p_max`, elite e +5% de Vida; `referenced_by` dos hitstops sem Cena F5
e Feedback; 3 flashes/s "sempre" × passe obrigatório em fade; "~280 runs" × 265 na Telemetria; Combate/Selo vs IA em
hitstop do abate de elite (pesado × 4).

### Correções do cross-review de 2026-11-10 que persistem
C-B1 (11 camadas), S-B1 (estado Transição e hitstop) e S-B2 (`camara_limpa` com hitstop 0) conferidos; C-B2 não verificado.

---

## Game Design Issues (Fase 3: 0 bloqueantes)

⚠️ **A1. Lâmina × Ressonância (D-W11, D-W12):** o Pulso a longa distância quase não cobra nada; a Telemetria não grava distância
por arma; a esquiva da Lâmina (invulnerabilidade 45,7%) sem meta de defesa.
⚠️ **A2. Porta de Fragmentos dominada no MVP (D-W16):** sem sumidouro, não dá poder na run (aparece em 81% das escolhas).
⚠️ **A3. Recompensa da última câmara (índice 5) é morta:** a vitória vem logo depois; as 4,58 bênçãos esperadas contam uma que
não age (máx. útil 4).
⚠️ **A4. Bênçãos não trata D-W15 (Ataque ≈ 3× Especial), D-W12 (teto de cargas de esquiva) nem o teto do M do Selo (≈ 4,2).**
⚠️ **A5. Fluxo não é escasso:** a espera entre câmaras o enche (R1 "passa de câmara em câmara" sem consequência).
⚠️ **A6. Dificuldade ancorada só em parte:** alvo 0,25 da Vida por câmara é proposta; sem alvo de duração por câmara; sem
medição; `invuln_atingido_s` 0,6667 a testar (0,4–0,5).
⚠️ **A7. P1/P2 e Doutrina:** pool puro de 18 desvincula a fantasia da Doutrina; só 1 de 18 cartas com preço mecânico; o P2 do
MVP vive de custo de oportunidade.
⚠️ **A8. Atenção no limite (4 decisões):** leitura do chão no pico p4 (Fenda, Anomalia, elite).
ℹ️ I1 loop único e sem sumidouro (aceitável como escopo do MVP); I2 trocas sem fonte; I3 elite é risco sem retorno; I4 sem
violação de anti-pilar; I5 run curta sem clímax e "Restart Rate" sem leitura definida.

Itens D-W11…D-W17 do cross-review anterior: D-W11 aberto; D-W12 aberto; D-W13 não conferido; D-W14 parcial; D-W15 aberto;
D-W16 decidido e mantido; D-W17 parcial.

Pilares: o HUD cita "P3 *Leitura primeiro*" (o nome real é *Reflexo que se lê*); os GDDs desta rodada citam P1–P4 e nunca P5.

---

## Cross-System Scenario Issues

Scenarios walked: 5 (vitória na câmara 5; morte e limpeza no mesmo passo; recusa de morte com `jogador_atingido`; abrir a Bênção no
meio do combate; entrada da 1ª câmara).

#### Blockers
🔴 **Abrir a Bênção no meio do combate** — Pipeline, Feedback, HUD, Input, Run. Passo 3: números e letreiros somem (Pipeline) ou
retomam (Feedback). É o B2; a pausa em Bênção é o B1.

#### Warnings
⚠️ **Vitória na câmara 5** — Câmaras, Portas, Bênçãos, Tela, Run, Economia, Telemetria: `bencao_escolhida` só depois de
`tela_fechada`; a ordem `run_encerrada` × crédito dos 15 está ambígua; a recompensa final é morta (A3).
⚠️ **Morte e limpeza no mesmo passo** — Combate, Câmaras, Run, Portas, Economia: três regras; Portas sem regra nem AC.
⚠️ **Recusa de morte com golpe no mesmo passo** — Combate, Feedback, Pipeline: o impact frame vence a inversão (R12), mas a
duração (6 × 10 × 22) e o relógio (vivo × hitstop de 18) divergem.
⚠️ **Entrada da 1ª câmara** — Run, Combate, Selo, Telemetria: sem porta e sem Transição definida; Fluxo 0 × 100.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|---|---|---|---|
| run-e-regioes.md | pausa em Bênção; ordem `run_encerrada` × crédito; Fluxo inicial; Transição da 1ª câmara; `p_max`; exemplo F2 | Consistency | Blocking (B1, resolvido) / Warning |
| bencaos-tradicoes.md | pausa em Bênção (resolvido); `tela_fechada`; `tamanho_oferta`; D-W15 e tetos | Consistency / Design | Blocking (resolvido) / Warning |
| feedback-de-combate.md | Bênção × respostas (resolvido); remetente; relógios; política de corte; inversão | Consistency | Blocking (B2, resolvido) / Warning |
| pipeline-visual.md | remetente do impact frame; corte; dependências desatualizadas | Consistency | Warning |
| combate-nucleo.md | campo do acerto marcado (resolvido); V14; `jogador_morreu` na R17; áudio do acerto marcado | Consistency | Blocking (B3, resolvido) / Warning |
| cena-3-4-e-camera.md | F5 (zoom principal, `dir`, `escala`, um por passo, tempo) | Consistency | Warning |
| input-e-controle.md | contexto Transição e morte | Consistency | Warning |
| hud.md | estados de jogo; gatilho de volta após a Bênção; pilar P3 | Consistency | Warning |
| portas-e-recompensas.md | AC-PR-10 e F3; morte vence a limpeza; roteamento da oferta | Consistency | Warning |
| camaras-e-ondas.md | OQs resolvidas; `p_max`; "morte vence" | Consistency | Warning |
| rng-com-seed.md | F2 "profundidade"; nova_run | Consistency | Warning |
| conteudo-orientado-a-dados.md | tipos pendentes; linhas citadas; V* | Consistency | Warning |
| armas-das-doutrinas.md, ia-de-inimigos-e-elites.md, movimento-e-esquiva.md, modificadores-e-atributos.md, efeitos-de-status.md, selo-e-fluxo.md | dependências unilaterais; donos; teto de M; ST5; SV12 | Consistency / Design | Warning |
| tela-de-bencao-e-carta.md, telemetria-local.md, economia-de-fragmentos.md | nome da bênção; Dependencies; eventos; exemplo | Consistency | Warning |

---

## Resolução dos bloqueantes (decisão do usuário, 2026-11-11)

- **B1:** Input é a fonte; a pausa **abre** em Bênção, com "Abandonar run" **desabilitado**. Editados: Run R6, Edge Cases e
  AC-RN-15; Bênçãos Edge Cases.
- **B2:** na Bênção, números e letreiros **somem e não voltam** (Pipeline R2/AC-PV-71); o AC-FB-26 e o Edge do Feedback
  distinguem Pausa de Bênção.
- **B3:** o nome canônico é `enesimo_acerto`. Editados: Combate R8.2 (passos 2, 4 e 5) e R17 (tabela de campos); o texto
  "quarto acerto" do Combate designa o caso `a_cada` = 4. As ACs do Combate (AC-37, AC-91) mantêm o texto "quarto acerto".

Conferência: só por busca de texto nas linhas editadas; **não houve nova revisão completa** (regra de economia).

---

## Verdict: FAIL

NOT ASSESSED (fica abaixo de FAIL no ranking): HUD (quase inteiro), ACs e Edge Cases de Armas, Movimento, Combate, Pipeline, Cena
e Input, RNG F1–F6/F8–F9, Conteúdo R2–R12/F1–F8, Edge Cases de vários GDDs e o `entities.yaml` (só por busca). Uma segunda passada,
por seção, nesses trechos é o que falta para um veredito completo.

### Required actions before re-running
1. Conferir B1–B3 nos GDDs editados (feito por busca; falta a leitura do contexto).
2. Decidir os 9 pontos de design da Fase 3 (A1–A8, I1/I5) e resolver os avisos de dono: remetente do impulso e do impact frame;
   política de corte e prioridade do impact frame; relógio por resposta; duração da inversão; "estado de jogo"; `p_max`;
   +5% de Vida por profundidade; elite; Fluxo inicial; ordem da vitória; chave de RNG (i × i+1) e AC-PR-10; teto do M.
3. Registrar em `design/registry/entities.yaml` os valores novos (Telégrafos, IA, Câmaras, Portas, Run, Bênçãos, Economia, HUD,
   Tela, Feedback, Telemetria).


---

## Fechamento (2026-11-12): segunda passada e correções

**Método.** Sem uma segunda `/review-all-gdds` completa (regra de economia): 4 subagentes de leitura nos trechos não lidos (HUD/Cena/Input; Armas/Movimento; Combate regras e fórmulas; Pipeline/RNG/Conteúdo), 3 de edição com as decisões do usuário, e conferência dos pontos corrigidos por leitura das seções alteradas.

### Segunda passada: achados
- **Bloqueantes (4, todos de registro ausente ou exemplo errado; resolvidos):** `HudTuning`, `VisualTuning` e `ArmasTuning` não existiam no Conteúdo (agora na R1, Interactions e Dependencies); AC-HD-03 (conta da Vida) e AC-HD-17 (111 px = distância entre centros 69 + 27 + 15) corrigidos.
- **Avisos (~25):** nível "aviso" ausente no Conteúdo R9 (OQ 8 aberta); `nova_run` no RNG (aplicado); "profundidade" com três sentidos (RNG F2 corrigido; Pipeline R3 ainda sem dizer se o santuário conta); HUD ↔ Tela (`preco_revelado`, `tela_fechada`, agora regras e ACs no HUD); vinheta de Vida baixa em z 50 (HUD OQ 9, a confirmar com a Cena); ancoragem em ultrawide (HUD OQ 10, AC-HD-34); buffer de contador único do Input prende toques (aceito do cânone, a decidir); Input não dizia o que sai da Bênção (agora `tela_fechada`); Cena sem estado de Bênção (agora zera os impulsos); glifo por ação (`rotulo_acao`, Input OQ); hitstop do Movimento citava a soma antiga (corrigido); dois sentidos de `M` no Movimento (cargas renomeadas `cargas_max`); frase dos dois Pulsos em rajada (Armas, corrigida); toque do Selo na recarga e buffer de 10 passos (Selo, corrigido); Abalo do Selo 28 passos (Status); `CombatTuning` sem campos enumerados no Conteúdo; Dependencies desatualizadas.

### Decisões do usuário (2026-11-12), aplicadas
| # | Decisão | Onde aplicada |
|---|---|---|
| 1 | Remetente único: Combate → Feedback → destino | Combate V14/AC-72, Cena R8/F5/estados, Pipeline R7/R9 |
| 2 | Dono do `p_max`: Câmaras | Câmaras R3, Run R9/F1, Armas (alias), registro |
| 3 | Dono do +5% de Vida e da elite: IA | IA F2/R10, Modificadores R10, Armas R7, Status, registro |
| 4 | `teto_telegrafos` 24 = orçamento do Pipeline R9; faixa e TV5 reescritos | Pipeline R9, Telégrafos R2/Knobs/TV5/AC-TG-03 |
| 5 | `teto_multiplicador_dano` = 4,0 provisório | Modificadores F2/Knobs/AC-04b, Selo F5/SV12, Status ST5, registro |
| 6 | Última câmara sem recompensa; porta forçada `ultima` depois do índice 4 | Portas R1/R2/R6/F1/F3/ACs, Run R4/F2/ACs, Câmaras R11/R13/AC-CO-18, Economia F3, Telemetria F3, Bênçãos F3/F4, RNG chaves |
| 7 | Fluxo: aceitar o Selo permanente | Selo OQ4 (pergunta de playtest) |
| 8 | Pausa em Bênção abre, Abandonar desabilitado (já da 1ª parte) | Run R6/Edge/AC-RN-15, Bênçãos |

Efeito da decisão 6: escolhas livres do Limiar caem de 4 para 3 (depois dos índices 0, 1 e 3); E[bênçãos] = 1 + 3 × 0,895 ≈ **3,69** (era 4,58); máximo de bênçãos tomadas **4** (pool termina em 14); Fragmentos por porta 2, 2, 3 = 7, máximo por run **22** (era 25); Telemetria **21** linhas por run, ~285 runs por arquivo.

### Reconferência dos 3 bloqueantes originais (por leitura das seções)
- **B1, pausa em Bênção:** Run R6, Edge e AC-RN-15; Bênçãos Edge; Input (estados e R10) e Tela: **consistentes** (abre; Abandonar desabilitado; Bênção sai em `tela_fechada`).
- **B2, Bênção × respostas:** Feedback Edge e AC-FB-26; Pipeline R2 e AC-PV-71: **consistentes** (números e letreiros somem e não voltam; o resto retoma; Pausa retoma tudo).
- **B3, campo do acerto marcado:** Combate R8.2 (passos 2, 4, 5) e R17 (`acerto`, `acerto_de_arma`, `jogador_morreu`): **consistentes** com `enesimo_acerto`; Modificadores e Feedback já usavam esse nome.
- Registro: `registry.sh validate`: 0 problemas (146 entradas depois das constantes novas `damage_multiplier_cap`, `door_free_choices_limiar`, `final_chamber_reward`, `blessing_max_taken_limiar`).

### Pendências conhecidas (nenhuma é bloqueante)
- **Selo F5:** com M do Selo = 4 e M da arma menor, `f_selo` da Lâmina com 1 alvo daria ≈ 31,9% (meta 0,05–0,20): cenário misto não calculado; decidir se a meta muda ou se o M do Selo tem teto próprio (D-W/Selo OQ5).
- **Status ST5:** nota de cabeçalho "~79%" ainda no texto antigo e AC-ST-22 não revisado; o valor de X (50%) do caso somado a confirmar.
- **Movimento:** restam `M` de cargas por renomear (Edge "Cargas" ~l. 604–607, AC-13, AC-49, Dependencies do HUD).
- **Combate:** AC-74/76/77/79 ainda dizem "BLOQUEADO até o GDD de Telégrafos"; F8 já tem 540 (o 270 é só dado de teste); campos `_s` do `CombatTuning` sem enumeração no Conteúdo; hitstop da investida em vários alvos (Selo F supõe passos distintos); `AC-98..100` a conferir.
- **Cena:** F3 ainda diz "tempo real" (os impulsos agora usam `t_apres`).
- **Dependencies** de Telégrafos, Câmaras, HUD e Feedback listando o Combate; IA, Armas, Movimento↔Status; parágrafos "ainda não existem" em vários GDDs.
- **Conteúdo:** catálogo de tokens de porta (`santuario`, `chefe`, `ultima`); nível "aviso" no R9 (OQ 8); força "Forte" já alinhada.
- **Registro:** `source` das 4 constantes novas conferir (Portas, Bênçãos, Modificadores); não há constante do máximo de 22 Fragmentos; `entities.yaml` ainda sem teto de 6 números, 300 ms, 64/24/1500/500.
- **Textos "nota de edição pendente"** que já foram aplicados (HUD Tuning Knobs, Tela Tuning Knobs, HUD OQ 5, Bênçãos cabeçalho).
- **Design da Fase 3 ainda em aberto (para playtest ou decisão):** A1 Ressonância à distância (D-W11) e Lâmina (D-W12); A4 teto de cargas de esquiva e magnitude por slot (D-W15, Ataque ≈ 3× Especial); A6 alvo de duração por câmara e o 0,25 de dano; A7 pool puro × Doutrina e preço mecânico em 1 de 18 cartas; A8 atenção no pico p4 (elite, Fenda, Anomalia); I1 Fragmentos sem sumidouro; I5 leitura do Restart Rate. A2 (porta de Fragmentos) decidida em Portas OQ1; A3 e A5 decididas acima.

### Veredito final do fechamento: CONCERNS (parcial)
- **Nenhum bloqueante conhecido permanece**: os 3 originais e os 4 da segunda passada estão resolvidos e foram reconferidos por leitura das seções alteradas.
- **Não é uma revisão completa**: continuam **NOT ASSESSED** os corpos dos ACs de Armas, Movimento, Combate, Pipeline, Cena, Input, RNG e Conteúdo, os Edge Cases de vários GDDs, a leitura integral do `entities.yaml` e as Dependencies de Telégrafos, Câmaras, HUD e Feedback. As edições da segunda rodada foram conferidas por busca e leitura pontual, **sem nova revisão independente** (regra de economia).
- **Critério "sem FAIL":** atingido no que foi lido e corrigido (nenhum bloqueante conhecido); **não** equivale a um PASS nem a uma revisão completa limpa.

### Aceite do usuário (2026-11-12)
A revisão cruzada foi **aceita como CONCERNS parcial** (ACs e Edge Cases não avaliados, aceito pelo usuário em 2026-11-12); a terceira leitura por seção não será feita. O critério de conclusão do MVP (22/22 GDDs aprovados, revisão cruzada sem FAIL) está **atendido**.

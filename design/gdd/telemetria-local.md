# Telemetria local

> **Status**: Approved (2026-11-11; revisão única por subagente: 8 bloqueantes e recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P2 *A Beira cobra* (dado para calibrar o preço); P4

## Summary

A **Telemetria local** grava, **só na máquina do jogador**, um registro enxuto de cada run
(início, câmaras, ofertas e escolhas de bênção, causa de morte, fim) em um arquivo `.jsonl`
por sessão. Serve ao `/balance-check` e ao playtest: mostra se o dano por câmara, a duração
e as escolhas batem com o que os GDDs previram. Nada sai da máquina sozinho.

> **Quick reference** — Layer: `Meta` · Priority: `MVP` · Key deps: `Run e regiões, Bênçãos (Tradições), RNG com seed`

## Overview

> `analytics-engineer` não consultado nesta seção: modo Lean.

A Telemetria local **só escuta**: não influencia o jogo, não calcula nada de design e não
é lida pelo jogo. Cada sistema continua dono do seu dado; a Telemetria escreve o que eles
emitem.

- **O que grava (MVP):** início de run (seed, versão, impressão do catálogo, arma, estado
  inicial: RNG/Run); uma linha por câmara (duração, dano recebido, abates: Câmaras, IA OQ 10);
  uma por oferta de bênção e uma por escolha, com raridade e trocas (Bênçãos); a causa da morte
  (Combate); fim de run com o resumo (Run R7) e o caminho (RNG). **Sem granularidade por
  golpe ou esquiva** (decisão do usuário).
- **Onde e como:** um arquivo `.jsonl` por sessão em `user://telemetria/`, uma linha JSON por
  evento, anexando e gravando a cada evento (`FileAccess.store_line` devolve `bool` desde a 4.4:
  a falha é lida e registrada, nunca ignorada).
- **Privacidade:** **ligada por padrão, só local, com opção de desligar** (decisão do
  usuário). Sem rede, sem identificador de pessoa ou de máquina, sem nome nem caminho do
  usuário. O playtester envia o arquivo se quiser; as opções têm "abrir pasta" e "apagar dados".
- **Fora do MVP:** envio automático, painel, eventos por golpe, perfil do jogador.

A **fantasia** não é do jogador: é do designer, que quer saber o que a Beira realmente
cobrou. O jogador só deve sentir que **ela não existe**: nenhum travamento, nenhum aviso,
nenhuma dependência.

As regras seguem o contrato dos GDDs vizinhos (RNG Interactions, Run R7/OQ 7, Bênçãos eventos,
Câmaras e IA OQ 10), com as decisões do usuário de 2026-11-11: arquivo `.jsonl` por sessão, ligada
por padrão e só local com opção de desligar, eventos sem granularidade por golpe.

> **→ vira ADR:** não. A Telemetria é um ouvinte de eventos que escreve num arquivo; sem estado
> de jogo.

## Detailed Design

### Core Rules

**R1. Só escuta.** A Telemetria recebe eventos dos outros sistemas por interface e os escreve.
Não calcula regra de design, não altera estado de jogo e **o jogo nunca lê o arquivo**. Qualquer
falha dela (disco, permissão, tamanho) é **absorvida** (R8): o jogo segue como se ela não
existisse.

**R2. Sessão e arquivo.** Uma **sessão** é uma execução do jogo. Ao iniciar (com a Telemetria
ligada), ela cria `user://telemetria/sessao-AAAAMMDD-HHMMSS.jsonl` (data e hora **UTC** da
abertura) e grava a 1ª linha, `sessao_iniciada`. **Uma linha JSON por evento**, em UTF-8,
terminada em quebra de linha, **descarregada ao disco a cada linha** (a API de descarga e a de
anexar são conferidas na implementação, OQ 5; `store_line` devolve `bool`, e a falha é lida,
R8). Ao sair do jogo grava `sessao_encerrada` e fecha.

**R3. Campos comuns** (toda linha): `t` (tipo do evento), `n` (número da linha, de 0, na sessão),
`ms` (milissegundos desde o início da sessão, relógio monotônico), `run` (índice da run na
sessão, de 1; 0 fora de run) e, só na linha 0, `schema` (versão do esquema, 1).

**R4. Eventos do MVP** (nenhum é por golpe ou esquiva; cada linha é pequena, < 2 KB):

| `t` | Quando | Campos (além dos comuns) | Fonte |
|---|---|---|---|
| `sessao_iniciada` | abertura | `schema`, `versao` (do jogo), `impressao` (curta, 4 hex), `os` (família: windows, linux, macos), `data_utc` | RNG, Conteúdo R12 |
| `run_iniciada` | ao criar a seed | `seed` (texto), `impressao` (completa, 64 hex), `regiao`, `estado_inicial` = `arma`, `doutrina` e `oficina` (nível de cada melhoria; vazio no MVP), como o RNG R7 | RNG, Run |
| `camara` | ao **limpar** (o santuário fecha no `camara_limpa`) ou ao encerrar a run dentro dela | `indice`, `p`, `tipo` (`combate`, `santuario`), `ms_inicio` (o `ms` em que a câmara abriu), `duracao_s`, `vida_max`, `dano_recebido`, `abates`, `vida_fim`, `resultado` (`limpa`, `morte`, `abandono`) | Run (câmara entrou), Câmaras, Combate |
| `oferta` | `oferta_aberta` | `indice_camara` (o índice atual, vindo da Run), `cartas` (lista de `id` + `raridade`), `trocas` | Bênçãos, Run |
| `oferta_trocada` | `oferta_trocada` | `cartas`, `trocas` (restantes) | Bênçãos |
| `bencao` | `bencao_tomada` | `id`, `raridade`, `trocas_restantes` (as `trocas` da última `oferta` ou `oferta_trocada`) | Bênçãos |
| `porta` | porta escolhida | `indice_camara`, `tipo` escolhido, `opcoes` (tipos oferecidos) | Portas (evento novo, OQ 7), Run (caminho) |
| `morte` | `jogador_morreu` | `indice`, `causa` (`tipo_inimigo`, `ataque`; **`null` se o Combate não os fornecer**, sem `TL3`), `vida_max` | Combate (campos pedidos, OQ 7) |
| `run_encerrada` | `run_encerrada` | o **resumo da Run R7** (10 campos: motivo, seed, arma, câmaras limpas, bênçãos tomadas, Fragmentos coletados, bônus de vitória, total, abates, duração), `caminho` (porta, bênção e troca em ordem), `fragmentos_por_origem` (soma dos `delta` positivos de `saldo_mudou` por `origem` na run) | Run, RNG, Economia |
| `sessao_encerrada` | saída do jogo pelo menu, telemetria desligada ou limite | `motivo` (`saida`, `desligada`, `limite`) | — |

**R5. Contadores da câmara.** A Run avisa **"câmara entrou"** (a Câmaras só emite `camara_limpa`) e emite o **passo vivo em Jogo** (a Run F3 já o conta: sem pausa, Bênção nem Transição). Ao entrar numa câmara a Telemetria zera `dano_recebido`, `abates` e
a `duracao`. `dano_recebido` soma a **Vida perdida** de cada `jogador_atingido` (sem descontar cura nem recuperação da recusa de morte) (o que o escudo
absorveu **não** conta, Combate R17); `abates` conta `inimigo_morreu` na câmara; a duração são os
**passos vivos em estado Jogo** (como a Run F3: sem pausa, Bênção nem Transição, **incluindo
hitstop**) ÷ 60. O santuário grava `dano_recebido` 0 e `abates` 0.

**R6. Opções.** `telemetria_ligada` (padrão **ligado**) vive na configuração do usuário (não é
Save). Desligada: **nenhum arquivo** é aberto nem escrito. **Desligar** no meio da sessão fecha o
arquivo com `sessao_encerrada` (`desligada`) e vai a Desligada. **Ligar** no meio vai ao estado
**Armada**: o arquivo novo abre na próxima `run_iniciada`, começa com `sessao_iniciada` (`n` volta a
0, `schema` de novo, `run` **continua** a contagem da sessão). **Parada por falha**: religar não
ajuda, só volta na próxima sessão; **Parada por limite**: ligar abre arquivo novo (Armada). As
opções ganham **"Abrir pasta de telemetria"** e **"Apagar dados"** (apaga só `sessao-*.jsonl`
da pasta, depois de uma confirmação; um arquivo que não puder ser apagado, por exemplo aberto por
outra instância, é ignorado com `TL1` e não para a gravação). Na **primeira execução** o jogo
mostra um **aviso único** de que a telemetria é local e pode ser desligada (spec no GDD de
Opções, OQ 5).

**R7. Privacidade.** Só dados de design. **Nunca** gravar: nome do usuário ou da máquina,
caminho absoluto, IP, identificador de pessoa ou de dispositivo, texto livre, hora local com
fuso. A data é UTC. **Sem rede**: nada sai da máquina sozinho; o playtester envia o arquivo se
quiser. A `seed` é o texto do RNG (em debug só hex, RNG R8; não é dado pessoal), `impressao` e `versao` também não identificam pessoa. A `impressao` da `sessao_iniciada` vale só para o **início** da sessão; a da `run_iniciada` é a da run.

**R8. Falhas e avisos.** Se abrir, gravar ou descarregar falhar (disco cheio, sem permissão, caminho
inválido), a Telemetria registra **um** `TL1` no log do motor, **para de gravar na sessão** e
fica no estado Parada por falha; **sem nova tentativa em laço, sem aviso ao jogador no MVP e
sem atrasar o jogo**. Cada gravação é de linha curta e síncrona, e o custo medido é parte da
validação (F4, OQ 3; avisos TL1 a TL3).

**R9. Tamanho e retenção.** A Telemetria só grava uma linha se `tamanho + linha + reserva (512 B)
≤ max_bytes_sessao`; a **reserva** garante espaço para `sessao_encerrada` (`limite`). Ao não caber
mais, escreve esse `sessao_encerrada` e para (Parada por limite): o arquivo **nunca passa do
limite**. Ao iniciar a sessão, mantém só as últimas `max_sessoes` (20) e apaga as mais
antigas (só os `sessao-*.jsonl`, ordenados pelo texto da data no nome; falha ao apagar: `TL1`, ignorada).

**Avisos** (log, nunca erro de jogo): **`TL1`** erro de arquivo (abrir, gravar, descarregar,
apagar); **`TL2`** custo de gravação acima do orçamento (F4); **`TL3`** campo ausente ou
desconhecido num evento, uma vez por tipo.

**R10. Fechamento brusco.** Como cada linha é descarregada ao ser escrita, no máximo a **última
linha** pode ficar truncada; o leitor **ignora linha que não é JSON válido**. Sessão sem
`sessao_encerrada` = encerrada de forma abrupta.

**R11. Uso.** O `/balance-check`, o playtest e as ferramentas em `tools/` leem o `.jsonl`
(sozinhos; o `schema` é versionado). Ex.: dano por câmara ÷ `vida_max` contra o alvo 0,25 da IA
(IA R12, OQ 10); duração por câmara contra Câmaras AC-CO-27 (câmara 0: 10–25 s; câmara 4: 25–60 s, proposta) e o dano contra Câmaras OQ 10; escolhas e raridades contra Bênçãos F;
tempo do clique em "Jogar" à 1ª câmara (Run OQ 9, ≤ 3 s) com o `ms` de `run_iniciada` (o "Jogar" cria a run) e o `ms_inicio` da 1ª `camara`. As ferramentas de análise ficam **fora** deste GDD.

**R12. Nova run e abandono.** Cada run abre com `run_iniciada` e fecha com `run_encerrada`
(vitória, morte ou abandono); a Nova run incrementa `run`. Abandonar encerra a câmara em
curso com `resultado` `abandono`.

**R13. Injeção.** Recebe os eventos por interface (incluindo "câmara entrou" e o passo vivo em Jogo, da Run), o relógio monotônico e o **escritor de
arquivo** (testes usam um escritor em memória e um que falha) e `TelemetriaTuning`. Os testes
montam tudo sem disco.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Desligada | `telemetria_ligada` falso | Armada (ligar) |
| Armada | ligar no meio da sessão, ou depois de Parada por limite | Aberta (próxima `run_iniciada`), Desligada |
| Aberta | sessão iniciada com a opção ligada, ou a `run_iniciada` seguinte à Armada | Desligada (desligar), Parada por falha (R8), Parada por limite (R9), Encerrada (sair) |
| Parada por falha | erro de arquivo | Encerrada (sair); religar não ajuda, só volta na próxima sessão |
| Parada por limite | o arquivo não comporta mais linhas (R9) | Armada (ligar), Encerrada (sair) |
| Encerrada | saída do jogo | — |

### Interactions with Other Systems

| Sistema | Fornece à Telemetria | Recebe da Telemetria | Dono da interface |
|---|---|---|---|
| Run e regiões | início e fim de run, resumo (R7), caminho, abandono | nada | Run |
| Bênçãos (Tradições) | `oferta_aberta`, `oferta_trocada`, `bencao_tomada` | nada | Bênçãos |
| RNG com seed | seed, versão, impressão, estado inicial | nada | RNG |
| Câmaras e ondas | câmara nova, `camara_limpa`, tipo, `p` | nada | Câmaras |
| Combate núcleo | `jogador_atingido`, `inimigo_morreu`, `jogador_morreu` (causa) | nada | Combate |
| Portas e recompensas | porta escolhida e opções | nada | Portas |
| Economia de Fragmentos | `saldo_mudou` (origem) para `fragmentos_por_origem` | nada | Economia |
| Conteúdo orientado a dados | `TelemetriaTuning`, impressão do catálogo | nada | Conteúdo |
| Opções / menus | `telemetria_ligada`, "Abrir pasta", "Apagar dados" | estado atual | Opções (reservado) |
| `/balance-check`, playtest, `tools/` | — | leem o arquivo | fora do jogo |

## Formulas

**F1. Duração da câmara.** `duracao_s = passos_vivos_em_Jogo / 60`, gravada com
`casas_decimais_duracao` (2) casas. Os passos incluem os de hitstop e excluem pausa, Bênção e
Transição (R5). Ex.: 1 044 passos → 17,40 s.

**F2. Dano relativo da câmara** (calculado pelas **ferramentas**, não pelo jogo):
`dano_rel = dano_recebido / vida_max` (ambos gravados na linha `camara`). O alvo da IA é 0,25
por câmara (IA R12). Ex.: 20 de dano com `vida_max` 80 → 0,25; 28 com 80 → 0,35 (acima do alvo).

**F3. Tamanho de uma run no Limiar (caso máximo).** No Limiar (6 câmaras, índices 0–5, santuário
no 3) há **5 portas** (3 livres, depois dos índices 0, 1 e 3, e 2 forçadas, depois do 2 e do 4) e, no máximo, **4 ofertas** (nos índices 0, 1, 2 e 4: a recompensa
da câmara pode ser bênção, Fragmentos ou cura, Portas R9; o santuário não oferece bênção e o índice 5 não dá recompensa).
Linhas de uma run vencedora no teto: 1 `run_iniciada` + 6 `camara` + 4 `oferta` + 4 `bencao` + 5
`porta` + 1 `run_encerrada` = **21** (+ 1 `oferta_trocada` por troca, base 0; + 1 `morte` numa
derrota; + `sessao_iniciada` e `sessao_encerrada` por sessão). Com ~300 B por linha, 600 B em
`run_iniciada` e ~1 KB em `run_encerrada`: `19 × 300 + 600 + 1 000` = **7 300 B**, ou
`2 097 152 / 7 300` ≈ **287 runs** em `max_bytes_sessao` (2 MiB). Folga grande, por isso o limite só protege.

**F4. Custo de gravação.** Cada linha custa ≤ `orcamento_linha_ms` (1 ms, para linhas ≤ 2 KB) e o
total de um passo ≤ `orcamento_passo_ms` (3 ms). O pior passo real é a **morte**: `camara`
(`morte`) + `morte` + `run_encerrada` (~1 KB) = 3 linhas ≤ 3 ms de 16,7. A `camara` e a `oferta`
(passos seguidos) e a `porta` (escolha do jogador, depois) não caem no mesmo passo. Passar dos
orçamentos não derruba nada: só conta o aviso `TL2` (R8).

**F5. Retenção.** Ao iniciar a sessão: `apagar = max(0, existentes − (max_sessoes − 1))`, as mais
antigas primeiro (pelo nome, que ordena por data UTC). Ex.: 20 existentes e `max_sessoes` 20 →
apaga 1; 12 existentes → apaga 0.

## Tuning Knobs

`TelemetriaTuning` (tipo novo no Conteúdo, dono: Telemetria local; nota de edição pendente):

| Knob | Padrão | Faixa | Categoria | Efeito |
|---|---|---|---|---|
| `max_bytes_sessao` | 2 097 152 | 262 144–16 777 216 | gate | tamanho máximo do arquivo de uma sessão |
| `max_sessoes` | 20 | 5–100 | gate | quantos arquivos a pasta guarda |
| `orcamento_linha_ms` | 1,0 | 0,2–5,0 | feel | custo de gravação por linha acima do qual conta `TL2` |
| `orcamento_passo_ms` | 3,0 | 1,0–8,0 | feel | custo de gravação por passo acima do qual conta `TL2` |
| `casas_decimais_duracao` | 2 | 1–3 | feel | casas de `duracao_s` |

`telemetria_ligada` **não** é knob de design: é preferência do usuário (padrão ligada, R6).

## Edge Cases

- **Sem permissão ou disco cheio ao abrir a pasta:** `TL1` no log, estado Parada por falha, o
  jogo segue sem arquivo (R8).
- **Pasta `user://telemetria/` não existe:** é criada na abertura; se não puder, `TL1`.
- **Falha no meio da sessão:** para de gravar; a linha em curso pode ficar truncada (R10).
- **Dois jogos ao mesmo tempo (duas instâncias):** nomes com a hora UTC até o segundo podem
  colidir; no conflito, o nome ganha o sufixo `-2`, `-3`.
- **Relógio do sistema errado:** o nome do arquivo e `data_utc` ficam errados, mas `ms` é monotônico
  e `n` ordena as linhas; sem outro efeito.
- **Arquivo chega a 2 MB:** escreve `sessao_encerrada` (`limite`) e para; a run em curso fica sem o
  resto do registro (F3: só acontece em ~285 runs).
- **Run abandonada na câmara:** `camara` com `resultado` `abandono` e `run_encerrada` com motivo
  `abandono` (R12).
- **Morte na mesma câmara de uma bênção em curso:** a `oferta` já gravada permanece; a `bencao`
  só existe se `bencao_tomada` ocorreu; a `camara` fecha com `morte`.
- **Recusa de morte (Combate V11):** não é morte; nenhuma linha `morte`; o `dano_recebido` soma o `vida_perdida` do `jogador_atingido` que a causou, **sem descontar** a recuperação.
- **Morte e `camara_limpa` no mesmo passo:** vale a morte (Run R5): uma só `camara` com `resultado` `morte`.
- **Apagar dados ou retenção com arquivo aberto por outra instância:** a falha ao apagar é ignorada com `TL1` e a gravação segue.
- **Santuário:** grava `camara` com `tipo` `santuario`, dano 0, abates 0 e `duracao_s` (da entrada até o `camara_limpa`, que no santuário é imediato, Câmaras).
- **Desligar com a run em curso:** fecha o arquivo (`desligada`); a run termina sem registro; ligar
  de novo só vale na próxima run (R6).
- **Sair do jogo pelo menu no meio da run:** grava `camara` em curso como `abandono` e `sessao_encerrada` (`saida`), **sem** `run_encerrada`. **Matar o processo:** nenhuma das duas; o leitor trata como abrupta (R10).
- **Evento recebido de um sistema depois de a Telemetria parar:** descartado sem erro.
- **Evento com campo desconhecido ou ausente:** a linha sai com o campo `null` e `TL3` conta uma
  vez por tipo; nunca falha.
- **Nova run no mesmo passo do fim da anterior:** `run_encerrada` primeiro, `run_iniciada` depois,
  com `run` incrementado.
- **Apagar dados com a sessão aberta:** o arquivo da sessão em curso **não** é apagado; fecha e
  apaga na próxima sessão.
- **Pasta com arquivos que não são `sessao-*.jsonl`:** nunca apagados (R6, R9).
- **Pausa ou Bênção aberta:** `ms` continua a correr (monotônico), a duração da câmara **não**
  (F1).

## Dependencies

| Sistema | Direção | Natureza | Interface |
|---|---|---|---|
| Run e regiões | entra | por contrato | início e fim de run, resumo (R7), caminho, abandono |
| Bênçãos (Tradições) | entra | por contrato | `oferta_aberta`, `oferta_trocada`, `bencao_tomada` |
| RNG com seed | entra | por contrato | seed, versão, impressão, estado inicial, caminho |
| Câmaras e ondas | entra | leitura | câmara nova, câmara limpa e tipo (`camara_limpa`), `p` |
| Run e Combate (duração e dano) | entra | leitura | a duração vem dos sinais da Run (passo vivo em Jogo, R5); o dano recebido vem do Combate (`jogador_atingido`) |
| Combate núcleo | entra | leitura | `jogador_atingido`, `inimigo_morreu`, `jogador_morreu` (causa) |
| Portas e recompensas | entra | leitura | porta escolhida e opções |
| Economia de Fragmentos | entra | leitura | `saldo_mudou(saldo, delta, origem)` |
| Conteúdo orientado a dados | entra | rígida | `TelemetriaTuning`, impressão do catálogo (nota de edição pendente) |
| Opções / menus (reservado) | entra e sai | por contrato | `telemetria_ligada`, "Abrir pasta", "Apagar dados" |
| `/balance-check`, playtest, `tools/` | sai | leitura do arquivo | `.jsonl`, `schema` versionado |

Nenhum sistema depende da Telemetria para **rodar**: sem ela o jogo é idêntico.

## Visual/Audio Requirements

- Sem visual nem áudio no jogo: a Telemetria é invisível ao jogador.
- Só as opções do menu (R6): "Telemetria local" (liga/desliga), "Abrir pasta de telemetria" e
  "Apagar dados" com uma confirmação.

## Game Feel

- **Zero impacto percebido:** gravação síncrona de linha curta (≤ 1 ms por linha, ≤ 3 ms por
  passo, F4); nenhum travamento, aviso nem tela.
- Nenhuma mudança em hitstop, latência de entrada ou ritmo de nenhum sistema.

## UI Requirements

- Três itens no menu de opções (R6), dentro do GDD de Acessibilidade e opções (reservado):
  liga/desliga (padrão ligado, com texto "só neste computador, nada é enviado"), "Abrir pasta"
  e "Apagar dados" (confirmação).
- Nenhuma tela própria. Sem aviso quando a Telemetria para por falha (R8).

## Cross-References

- RNG Interactions (linhas de Telemetria local) e Edge Cases; Run R7, F3, OQ 7 e OQ 9; Bênçãos
  R5 (eventos); IA R12 e OQ 10 (`alvo_dano_camera`); Câmaras OQ 10 e AC-CO-27; Combate R17
  (Vida perdida), `jogador_morreu` (causa); Economia R8.
- Índice: linha 35.

## Acceptance Criteria

Tipos: [L] lógica (unitário, escritor de arquivo e relógio falsos), [I] integração.

- **AC-TL-01 [L] R2 — abertura.** Com a opção ligada, a sessão cria `sessao-AAAAMMDD-HHMMSS.jsonl` (UTC) e a linha 0 é `sessao_iniciada` com `schema` 1, `versao`, `impressao` (4 hex), `os` e `data_utc`.
- **AC-TL-02 [L] R3 — campos comuns.** Toda linha tem `t`, `n` (0, 1, 2… sem buracos), `ms` (não decrescente) e `run`; `schema` só na linha 0.
- **AC-TL-03 [L] R2 — descarga.** O escritor falso recebe uma chamada de descarga depois de cada linha.
- **AC-TL-04 [L] R4 — `run_iniciada`.** Ao criar a seed grava `seed` (texto), `impressao` (64 hex), `regiao` e `estado_inicial` (`arma`, `doutrina`, `oficina` vazia no MVP); `run` = 1 na 1ª run da sessão.
- **AC-TL-05 [L] R4/R5 — câmara.** Uma câmara com `jogador_atingido` (Vida perdida 8 e 12; um golpe de 6 todo absorvido pelo escudo) e 3 `inimigo_morreu`: `dano_recebido` 20, `abates` 3, `resultado` `limpa`.
- **AC-TL-06 [L] F1/R5 — duração.** 1 044 passos vivos em Jogo (incluindo 30 de hitstop) com 600 passos de pausa e 120 de Bênção: `duracao_s` 17,40.
- **AC-TL-07 [L] R5 — santuário.** Câmara do santuário: `tipo` `santuario`, `dano_recebido` 0, `abates` 0.
- **AC-TL-08 [L] R4 — oferta e escolha.** `oferta_aberta` com 3 cartas grava `oferta` (3 `id` + `raridade`, `trocas`); `oferta_trocada` grava `oferta_trocada`; `bencao_tomada` grava `bencao` com `trocas_restantes`.
- **AC-TL-09 [L] R4 — porta.** Uma porta escolhida grava `porta` com o `tipo` escolhido e as `opcoes` oferecidas.
- **AC-TL-10 [L] R4 — morte.** `jogador_morreu` grava `morte` com `causa` (`tipo_inimigo`, `ataque`) quando o Combate os fornece e `causa: null` (sem `TL3`) quando não; uma `recusou_morte` **não** grava `morte` e o `dano_recebido` soma o `vida_perdida` do golpe sem descontar a recuperação.
- **AC-TL-11 [L] R4/R12 — fim de run.** `run_encerrada` grava o resumo de 10 campos da Run R7, o `caminho` em ordem e `fragmentos_por_origem`; vitória, morte e abandono geram uma linha cada.
- **AC-TL-12 [L] R12 — abandono.** Abandonar na câmara 2: `camara` com `resultado` `abandono`, depois `run_encerrada` com motivo `abandono`.
- **AC-TL-13 [L] R12 — nova run.** `run_encerrada` vem antes de `run_iniciada`; `run` passa de 1 para 2.
- **AC-TL-14 [L] R1/R13 — só escuta.** A Telemetria não chama nenhum método de escrita de qualquer sistema; roda com eventos e escritor falsos, sem disco.
- **AC-TL-15 [L] R6 — desligada.** Com `telemetria_ligada` falso, nenhum arquivo é criado nem aberto durante a sessão inteira.
- **AC-TL-16 [L] R6 — desligar e ligar.** Desligar com a run em curso: `sessao_encerrada` (`desligada`) e o arquivo fecha (Desligada); ligar vai a Armada; a próxima `run_iniciada` abre arquivo novo com `sessao_iniciada` (`n` = 0, `schema` 1) e `run` continuando a contagem; após Parada por falha, ligar não abre arquivo.
- **AC-TL-17 [L] R7 — privacidade.** Nenhuma linha de uma sessão de teste contém o nome do usuário, um caminho absoluto, IP, nome da máquina ou hora local com fuso; `data_utc` termina em `Z`; `seed` (só hex em debug) e `impressao` contêm só os caracteres esperados.
- **AC-TL-18 [L] R8 — falha ao abrir.** Escritor que falha ao abrir: um erro (`TL1`), estado Parada por falha, o jogo continua e nenhum evento posterior lança erro.
- **AC-TL-19 [L] R8 — falha no meio.** Escritor que falha na 10ª linha: para de gravar, nenhuma nova tentativa, sem aviso ao jogador, sem exceção.
- **AC-TL-20 [L] R9/F3 — limite.** Com `max_bytes_sessao` pequeno (4 KB): a última linha de dados cabe com a reserva de 512 B, `sessao_encerrada` (`limite`) é a última e o arquivo final é **≤ 4 096 B**; nenhuma linha depois.
- **AC-TL-21 [L] R9/F5 — retenção.** Com 20 arquivos e `max_sessoes` 20 ao iniciar: apaga 1 (o mais antigo); com 12: nenhum; um arquivo `outro.txt` na pasta nunca é apagado.
- **AC-TL-22 [L] R10 — truncamento.** Um arquivo cuja última linha está cortada: o leitor de teste ignora só essa linha e lê as demais; sem `sessao_encerrada` = sessão abrupta.
- **AC-TL-23 [L] R2 — nome repetido.** Duas sessões abertas no mesmo segundo ganham `-2` no nome da segunda.
- **AC-TL-24 [L] Edge — campo ausente.** Evento com campo faltando: a linha sai com `null` e `TL3` conta uma vez por tipo; sem falha.
- **AC-TL-25 [L] F4 — orçamento.** Um escritor que demora 4 ms por linha conta `TL2` e a gravação continua (não derruba nada).
- **AC-TL-26 [L] R6 — Apagar dados.** "Apagar dados" apaga só `sessao-*.jsonl`, depois da confirmação, e não apaga o arquivo da sessão em curso.
- **AC-TL-27 [L] F2/R11 — leitura.** A fixture de uma sessão (3 runs) lida pelo leitor de teste calcula `dano_rel` por câmara (ex.: 20/80 = 0,25) sem o jogo.
- **AC-TL-28 [I] R4 — run completa.** Uma run de 6 câmaras no Limiar com Run, Câmaras, Bênçãos, Portas e Combate reais e a fixture "todas as portas livres dão bênção: ofertas nos índices 0, 1, 2 e 4": 21 linhas de run na ordem esperada (F3) e `run_encerrada` com os 10 campos do resumo da Run por nome.
- **AC-TL-29 [L] R5 — morte e limpeza.** `jogador_morreu` e `camara_limpa` no mesmo passo: uma só `camara` com `resultado` `morte`.
- **AC-TL-30 [L] R1 — o jogo nunca lê.** Nenhum símbolo de leitura do arquivo é chamado fora do leitor de teste (varredura do módulo).
- **AC-TL-31 [L] Edge — pasta inexistente e evento após parada.** Sem a pasta, ela é criada; se não puder, `TL1`; evento depois de Parada por falha é descartado sem erro.
- **AC-TL-32 [L] R6/R9 — apagar com arquivo aberto.** Um arquivo que não pode ser apagado é ignorado com `TL1` e a gravação segue.
- **AC-TL-33 [L] R4 — `ms_inicio`.** A 1ª `camara` traz `ms_inicio`, e `ms_inicio − ms(run_iniciada)` é o tempo do "Jogar" à 1ª câmara (Run OQ 9).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Envio do arquivo pelo playtester (manual hoje); painel e envio automático | analytics-engineer / usuário | fatia vertical |
| 2 | Eventos por golpe e esquiva, com amostragem | analytics-engineer | só se o balance-check pedir |
| 3 | Medir o custo real de gravação de linha na plataforma (F4) e confirmar `flush` e anexar | ADR de implementação / lead-programmer | implementação |
| 4 | Ferramenta de análise em `tools/` (resumo de runs, dano por câmara, escolhas) | tools-programmer | primeiro playtest |
| 5 | Menu de opções (ligar, abrir pasta, apagar), aviso único da 1ª execução e base legal (LGPD/GDPR) para o envio manual do arquivo | UX / localização / usuário | GDD de Acessibilidade e opções |
| 6 | Conteúdo: `TelemetriaTuning` (5 campos) e avisos `TL1`–`TL3` como códigos V* | Conteúdo | próxima edição |
| 7 | **Edições pendentes:** Combate (`atacante_tipo` e `ataque_id` no `jogador_atingido` e a causa no `jogador_morreu`), Portas (evento de porta escolhida com `tipo` e `opcoes`), Run (sinais "câmara entrou" e passo vivo; `run_iniciada`/`run_encerrada` com resumo e caminho; Run OQ 7 resolvida), Bênçãos (eventos), Câmaras (OQ 10), IA (OQ 10), RNG (Interactions) | donos de cada GDD | `/review-all-gdds` |

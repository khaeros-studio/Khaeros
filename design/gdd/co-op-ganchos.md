# Co-op online: ganchos nos 22 GDDs aprovados do MVP

> **Status**: Levantamento (somente leitura; nenhum GDD foi editado)
> **Data**: 2026-11-13
> **Origem**: decisão do usuário (co-op online de 1 a 4 jogadores, depois do MVP
> solo; dificuldade escala com o número de jogadores; cada jogador escolhe uma
> das 6 Doutrinas). Ver `game-concept.md` seção 13b e `systems-index.md` sistema 36.

## Como ler

Cada linha é um **pressuposto de um só jogador** que o GDD aprovado faz hoje, e o
**gancho** que o Co-op online precisará. Isto é uma lista, não uma decisão: nada
aqui muda o MVP. A gravidade é: **baixa** = só dado ou escala; **média** = muda uma
regra; **alta** = muda a arquitetura.

**Limites da leitura.** Dois subagentes leram os GDDs por seção (Grep nos
cabeçalhos e Read por faixa), nunca inteiros. Não foram lidos a fundo: os ACs de
quase todos os GDDs; Pipeline visual (161 KB, só trechos das R1, R2, R5 a R8);
Efeitos de status (só R1 a R3, R6 e Tuning); os Edge Cases de Bênçãos, Economia,
HUD, Tela e Telemetria; os ACs de Modificadores, Conteúdo e Feedback. Onde o texto
diz "provável", é inferência do leitor e não está no GDD.

## Cinco temas que atravessam os GDDs

1. **O jogador é um singleton.** Posição, Vida, Fluxo, cargas de esquiva, portador
   de Modificadores e Selos assumem um dono único. Precisa virar entidade com id
   de jogador. *(arquitetura)*
2. **Hitstop, pausa e Bênção são globais.** O contador de hitstop é único (Combate
   R10), e a pausa e a Bênção param o relógio e todos os contadores. Online, o
   mundo não pode parar para todos. *(arquitetura e regra)*
3. **Morte do jogador = fim da run.** `jogador_morreu` encerra a run e leva o
   Input ao Passe de morte. Falta morte individual, espectador e revive.
   *(regra; é a decisão central do co-op)*
4. **Alvo da IA e dos telégrafos no singular.** A IA anda "em direção ao jogador" e
   o telégrafo trava a mira nele. Falta política de alvo e escala por jogadores.
   *(regra e dado)*
5. **RNG sem eixo de jogador.** Uma seed e chaves (finalidade, região, índice da
   câmara). Falta decidir quais fluxos são do grupo e quais por jogador, e quem
   sorteia online (host ou todos os clientes com a mesma seed). *(regra e ADR)*

Observação favorável: Input, câmera e Pipeline já são amostrados e calculados por
quadro local, o que facilita o modelo "uma câmera e um Input por cliente".

## Fundação

### rng-com-seed.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R2, R3 | Uma seed por run; fluxos por (finalidade, região, profundidade), sem eixo de jogador | Decidir fluxos do grupo (`ondas`, `layout`, `portas`, `elites`) e por jogador (`bencaos`, `raridade`); eixo extra de índice de jogador | Alta |
| R7 (contrato de reprodução) | Lista uma arma, uma Doutrina e uma sequência única de escolhas | Estado inicial por jogador; caminho inclui quem escolheu porta e bênção; acrescentar nº de jogadores | Alta |
| R7 (`ia`) e Interactions | `ia` já é "não garantido"; um só simulador consome todos os fluxos | Definir quem sorteia (host) e se o cliente reproduz ou só recebe; decisão de rede/ADR | Alta |
| R4b, R7 (`spawn`, K=14) | O ponto de spawn depende da posição "do jogador" | Regra determinística com N posições; o consumo de RNG continua fixo | Média |
| R9 | A fonte de fluxos é injetada uma vez por consumidor | Aceitar o id do jogador se houver fluxos por jogador | Média |
| R8 | O texto da seed descreve uma run única | Mostrar/negociar a seed no lobby; incluir nº de jogadores | Baixa |

### conteudo-orientado-a-dados.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 (`WeaponDef`) | 2 armas no MVP; as outras 4 Doutrinas ficam como dado sem arma | Seis `WeaponDef` válidas e validação de equilíbrio (AV*) para as 6 Doutrinas | Média |
| R1 (`BoonDef`, Edge) | Bênção de Doutrina sem arma no MVP continua válida | Garantir bênçãos jogáveis para as 6 Doutrinas; validar cobertura | Média |
| R1 (`WaveRules`, `RunTuning`) | Um conjunto de parâmetros, sem escala por jogadores | Tipo novo (por exemplo `CoopTuning`: multiplicador por N, 1 a 4) com faixa validada | Baixa |
| V1 a V10 | Nenhuma validação cruza Doutrinas | Checar 6 Doutrinas distintas e composição livre de até 4 jogadores | Baixa |
| R12, R5/R10 | Catálogo único, só leitura | Em rede, cliente e host precisam do mesmo catálogo: exigir impressão (SHA-256) igual no lobby | Baixa |

### input-e-controle.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| Overview, R13 | Um provedor de amostras, um conjunto de ações | Provedor por jogador; online, cada cliente amostra só o seu | Alta |
| R10 e estados (Jogo, Pausa, Bênção, Transição, Passe de morte, Menu) | Máquina de estados global; "o jogo pausa sozinho" | Pausa online não congela o mundo (vira menu); estado por jogador (Passe de morte, Bênção) | Alta |
| Passe de morte | Entrada ignorada, depois Menu | Separar morte individual (espectador) de fim da run | Alta |
| R3 | Dispositivo ativo único para o jogo todo | Por jogador local; online é o do cliente | Média |
| R5 / F4 (mira) | Mira vem da câmera única; mira automática a partir de um jogador | Mira e tela→mundo por jogador | Média |
| Overview ("vira ADR") | Onde amostrar (nó, Autoload, injeção) está em aberto | Decidir já com o jogador como parâmetro | Média |
| R12, R13 | Binds de usuário único; testes injetam uma sequência | Binds por perfil; injetar N sequências | Baixa |

### cena-3-4-e-camera.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R7 e R10 (hitstop por contador) | Contador do Combate é global; `t_apres` não congela no hitstop | Definir hitstop global ou local | Alta |
| Overview, R7 | Câmera segue "o jogador" com lookahead | Câmera local por cliente; definir o comportamento no morto (seguir aliado) | Média |
| R7 `P` | Posição de render interpolada do jogador | Interpolar aliados remotos (snapshot/netcode) | Média |
| R7 (câmara do tamanho da tela), F4 | Câmera parada no centro | Nada para câmera local; câmera compartilhada exigiria enquadrar N e zoom | Média (se compartilhada) |
| R8 (impulsos) | Remetente único, sem destinatário | Impulso só para o jogador envolvido (ou todos, por regra) | Média |
| R9, estados | Tela→mundo por uma câmera; intro de chefe comandada | Consulta por câmera de jogador; intro comum a todos? | Baixa |

### pipeline-visual.md (leitura parcial; ACs não lidos)
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R8 (dois relógios) | `t_vivo` congela no hitstop; `t_apres` para na pausa e na Bênção; relógios globais | Online, pausa e Bênção não param o relógio global; relógio de apresentação por cliente | Alta |
| R1 (`char_grupo`) | Um CanvasGroup do jogador; paleta "jogador em osso pleno" | Um CanvasGroup e `papel` por jogador; marca para distinguir 4 jogadores | Média |
| R5, R6 | Traço e imagens residuais "do jogador" | Distinguir local de aliados; orçamento de VFX conta 4 | Média |
| R7 | Impact frame (1 por segundo), `modo_impacto`, `modo_bencao` são uniforms globais; passe de tela entre câmaras | Impact frame e flashes por cliente; sincronizar a troca de câmara | Média |
| F10 (orçamento) | Calibrado com 1 jogador e 9 inimigos; 24 telégrafos | Reorçar para N jogadores e mais inimigos | Média |
| R9 / F9 | Oclusão testa "o" jogador | A partir do jogador local ou de qualquer um | Baixa |

### modificadores-e-atributos.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1, Estados | "O portador do jogador" nasce e morre com a run | N portadores, um por jogador (a estrutura já é por portador) | Baixa |
| R2 | `trocas_oferta`, `recusas_morte`, `vida_max` são do jogador | Atributos por jogador | Baixa |
| F3, `refletir_dano` | Só jogador contra inimigos | Se houver fogo amigo, definir alvo aliado (provável: sem fogo amigo) | Média |
| Interactions (fontes) | Escala de dificuldade não existe | Fonte `dificuldade_coop`, como `elite` e `profundidade`, escalando Vida e dano dos inimigos por N sem editar Câmaras | Baixa |

## Gameplay

### movimento-e-esquiva.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 | "Só o Movimento escreve a posição": um estado único (posição, cargas, recarga, invulnerabilidade) | Instanciar o Movimento por jogador, com id de dono | Alta |
| R2 (passo vivo) | O orquestrador lê um estado de Input e um hitstop; chama `passo()` ou `passo_congelado()` | Decidir por jogador qual estado de Input vale e se o hitstop congela todos | Alta |
| Edge ("fim da run no meio da esquiva") | Run termina → Input sai de Jogo → Movimento para | Distinguir morte de um jogador de fim da run; morto em espectador ou revive | Alta |
| R1 `teleportar` | Teleporta "o" jogador e cancela a esquiva | Por jogador, com posições de spawn distintas | Média |
| R2 e Dependencies (ordem Movimento → Combate → Selo) | Ordem roda uma vez | Ordem estável por id entre jogadores | Média |
| Dependencies (IA, Cena, Combate) | Posição "do jogador" no singular; consultas sem argumento | Lista de posições; jogador como parâmetro | Média |
| Dependencies (MV4) | Vão mínimo ≥ diâmetro de um corpo | Espaço para 4 corpos; colisão entre jogadores existe ou não | Baixa |

### combate-nucleo.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 (ordem do passo, itens 3 a 6) | Bloco único de jogador; roda só no estado Jogo | Iterar jogadores em ordem estável | Alta |
| R10 (hitstop) | Contador único, `max(contador, n)`; congela todo o mundo | Hitstop global, por jogador ou por cliente | Alta |
| R13 `ferir_jogador` | Alvo único (Vida, escudo, `recusas_morte`) | Passar o jogador alvo; Vida, escudo e recusas por jogador | Alta |
| R13.7 `jogador_morreu` | A Run encerra e o Input sai de Jogo; Câmaras ignoram "limpa" depois | Morte individual; fim da run só quando todos morrerem | Alta |
| R1 (estados fora de Jogo) | Pausa e Bênção não descontam contador algum | Redefinir pausa e Bênção (individual ou compartilhada) | Alta |
| R1 (Transição, `cancelar`) | O Combate zera hitstop, investida e recuperação | Reset por jogador; sincronizar a troca de câmara | Média |
| R13.1, F10, F11 | "Em combate" e DPS de referência assumem 1 alvo | "Câmara limpa" considera todos os vivos; re-baselinar com N | Baixa |

### armas-das-doutrinas.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| Overview, R4 | Tela de escolha com 2 armas antes de cada run | 6 Doutrinas; escolha no lobby, por jogador, com unicidade (um Iniciado por Doutrina; ver pergunta aberta 1) | Média |
| Estados, Edge ("se o jogador morrer") | Arma "Encerrada" na morte, que encerra a run | Encerrar no fim da run, não na morte individual; arma do morto | Média |
| F2 | `Vida_chefe` 700 fixa; paridade entre armas ≤ 0,15 | Escalar a Vida do chefe por jogadores e reaferir a paridade com 6 armas | Média |
| Dependencies | Modificadores monta o portador do jogador | Um portador por jogador | Média |
| R4 (persistência), F3, F4 | `ultima_arma` em `preferencias.cfg`; contas para 1 jogador | Escolha vem do lobby; refazer as contas por nº de jogadores | Baixa |

### selo-e-fluxo.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 | `fluxo` é um float único | Fluxo por jogador | Alta |
| R2 | Posição e mira de um jogador | Passar o jogador dono do Selo | Média |
| R3 | A lista de Selos não tem dono; M(Selo) é de um só jogador | Cada Selo guarda o dono; decidir se Selos de jogadores diferentes empilham | Média |
| R5 | Abate pelo Selo dá `cura_ao_abater` e `explosao_ao_abater` | Atribuir o abate ao dono do Selo | Média |
| R4, R6, HUD | Marca `no_selo` única; Selos apagados na troca; HUD de um Fluxo | Dono no Abalo; Selo do morto: apaga ou continua; Fluxo dos aliados no HUD | Baixa |

### efeitos-de-status.md (leitura parcial)
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1, R3 | Cada inimigo guarda `acumulos` e `restante` sem origem; as 4 fontes são de um jogador | Guardar a fonte (jogador) para atribuição de abate e de dano | Média |
| R2 / F1 | Reaplicar soma acúmulos até o teto C (10 e 6) por inimigo | Decidir se acúmulos de jogadores diferentes somam; o teto satura mais rápido com 4 | Média |
| R6 | Abalo único (−30%), de 4 s, não acumula | Pode ficar permanente com 4 jogadores aplicando | Baixa |
| F5 | Número agregado de dano de status a cada 0,5 s | Agregar por jogador ou por fonte | Baixa |
| R1 | "O jogador não tem status no MVP" | Não bloqueia o co-op; registrar se algum inimigo aplicar status aos jogadores | Baixa |

### telegrafos.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R2 | Mira travada "do inimigo ao jogador" | Receber da IA o jogador-alvo | Alta |
| R4, R6 | Testa a forma contra "o centro do jogador"; `ferir_jogador` uma vez; contato do avanço "uma vez por avanço" | Testar contra cada jogador; "uma vez por avanço" por jogador | Média |
| R2 `teto_telegrafos` = 24 | 9 inimigos do MVP não atingem o teto | Reaferir o teto e a legibilidade com mais inimigos e 4 jogadores | Média |
| R4 / `cancelado` | Cancela se "o dono morreu ou saiu" | Incluir "alvo travado morreu ou saiu" | Baixa |
| F2, F3, F5, F6 | `raio_jogador_u` constante; legibilidade calibrada para 1 pessoa | Raios iguais ou por Doutrina; revalidar com a tela cheia | Baixa |

### ia-de-inimigos-e-elites.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R4 (aproximação) | Anda sempre em direção ao jogador; ranged e chefe medem distância a ele | Política de alvo por inimigo (mais próximo, aggro ou fluxo `ia`) | Alta |
| R1 / Dependencies | A IA lê "a posição e o raio do jogador"; a consulta de alvos do Input só lista inimigos | Contrato com a lista de jogadores e troca de alvo | Alta |
| Edge (AC-IA-21), Combate R14 | Se o jogador morre, os inimigos param a partir do passo seguinte | Param só quando todos morrerem; senão retargetam | Alta |
| R11 | Ranged ataca só no retângulo visível da câmera | Definir qual vista vale (união ou câmera de cada alvo) | Média |
| R12 / `alvo_dano_camera` (0,25) | Meta de dano para "um jogador mediano"; dano dos inimigos fixo | Escalar Vida, orçamento e nº de inimigos por N mantendo a meta | Média |
| R10, R3, R7 (fluxos `elites` e `ia`) | Fluxos únicos; AC-IA-17 exige `elites` independente do jogador | Seed compartilhada ou autoridade do host | Média |
| F5 / IV7 | Teto de 1,5 golpes/s por invulnerabilidade | Vale por jogador; o dano total à equipe cresce | Baixa |

### camaras-e-ondas.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R9, R10, R11 | Câmara limpa sem inimigos vivos; `jogador_morreu` impede a limpeza (AC-CO-16) | Definir morto, espectador e revive; "morte vence a limpeza" vira "todos mortos vencem" | Alta |
| R13 (portas) | Um jogador interage com a porta (alcance 111 px) e pede a Transição | Quem decide a porta (qualquer um, votação ou líder); todos na saída antes da Transição | Alta |
| R6, F1, F2 | Orçamento = 3 + 0,9·p + 2·região; teto de 9 inimigos; pico de 6 | Termo por nº de jogadores e possível teto maior; refazer a tabela de pico e a duração (F5) | Média |
| R7, F3 | Spawn "a mais de 390 px do jogador" | Distância a todos os vivos (ou ao mais próximo); os 14 candidatos já servem | Média |
| R4, R11 (Transição) | Entrada em (960; 930); o orquestrador teleporta "o jogador" no meio do wipe | N posições de entrada; Transição síncrona | Baixa a média |
| R12, Tuning, AC-CO-27 | Santuário cura 40% da Vida do jogador; durações para o "jogador médio" | Cura por jogador; metas por nº de jogadores | Baixa |

### portas-e-recompensas.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1, R3, R2 passo 2 | Uma recompensa por porta; a bênção pede 3 cartas e `bencao_escolhida` chega depois de `tela_fechada` | Bênção por jogador ou do grupo; muda o fluxo de abrir as portas | Alta |
| R2 passo 0 | "Morte vence a limpeza": nada é creditado | Regra com N jogadores | Alta |
| R9 | `porta_escolhida(i)` vem de uma única interação | Votação, líder ou primeiro | Alta |
| R4 | Fragmentos por porta (2 + floor(p/3)) creditam a conta da run | Por jogador ou do grupo; escalar com N | Média |
| R6, R7 | A chave do fluxo `portas` é (portas, região, índice da câmara) e consome 4 reais | Manter se for do grupo; mostrar votos | Média |
| R5, Run R4/R6 | Cura 30% da Vida do jogador; última câmara assume uma passagem | Cura de cada jogador; a passagem é de todos | Baixa |

### run-e-regioes.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 | Máquina de estados única com uma arma e uma seed | Lobby e sincronização do início; "Escolha de arma" vira escolha de Doutrina por jogador | Alta |
| R5 | `jogador_morreu` encerra a run (motivo `morte`) | Fim da run quando todos morrem; revive e espectador; quem fecha a tela final | Alta |
| R6 | "Abandonar run" na pausa, desabilitado em Bênção | Abandono por jogador (sair da sala) contra fim da run para todos; pausa não pausa o mundo | Alta |
| R2, R4, R7, R8 | Estado inicial, vitória (+15), resumo de 10 campos e reset da run são de um jogador | Estado, crédito, resumo e reset por jogador e do grupo | Média |
| Tuning, R9 | `camaras_jogaveis` (6) e `p_max` (4) fixos | Nenhum, salvo escala por N | Baixa |

### bencaos-tradicoes.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R3, R4 | Chave dos fluxos (região, índice da câmara) sem jogador; 6 reais por oferta e por troca | Chave com id de jogador (ofertas distintas) ou ofertas iguais para todos; consumo fixo continua | Alta |
| R3 | Uma oferta aberta por vez (`oferta_ja_aberta`) | Estado de oferta por jogador; ofertas simultâneas | Alta |
| R9, R11 | Lista de tomadas zera na Nova run; "com a oferta aberta o mundo para" | Lista por jogador; mundo parado é inviável online | Alta |
| R1, R2, F4 | Pool = 18 menos as tomadas; uma bênção nunca se repete; no máximo 4 no Limiar | Pool por jogador ou compartilhado; com 4 jogadores o compartilhado esgota mais rápido | Média |
| R4 (`livres`) | Sorteio na ordem do manifesto, sem filtro por Doutrina | Oferta filtrada ou ponderada pela Doutrina do jogador | Média |
| R5, R6 | Escolha de 1 carta, sem pular; `trocas_oferta` do jogador | Escolha e trocas por jogador; sem pular trava os demais? | Média |

### economia-de-fragmentos.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1 | `ContaFragmentos` única: `saldo` e `coletados_run` | Conta por jogador (perfil); `coletados_run` do grupo ou por jogador | Média |
| R2, R4 | `creditar(origem, quantidade)` não diz a quem | Destinatário (jogador ou grupo) e regra de divisão | Média |
| R5, R7 | `gastar` e persistência de uma conta | Cada jogador gasta e persiste na própria; dono do saldo (anti-cheat) | Média |
| R4 (Edge) | "Morte vence a limpeza" não credita | Regra com N jogadores | Média |
| F3, R8 | Renda de 0 a 22 por run; meta 350; HUD lê `saldo()` | Rever com N; ler saldo local e dos aliados | Baixa |

## Apresentação e Meta

### hud.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R12 | Visibilidade por estado de jogo único (Bênção esconde fios e prompt) | Estados por jogador; `tela_fechada` reexibe só para quem escolheu | Alta |
| R2 | Vida, Fluxo e Esquiva de um jogador no canto inferior esquerdo | Painel de aliados (até 3 mini-barras), posição na Art Bible | Média |
| R1, R14 | Interfaces únicas (`saldo()`, Vida, Fluxo, cargas, `tomadas()`) | Fontes por jogador local e remoto (somente leitura) | Média |
| R3 a R7, R9, R10 | Vinheta de Vida baixa; fio de vida (limite 9); prompt da porta | Vinheta só local; prompt por jogador próximo; rever o teto de 9 fios | Baixa |
| Tela final | Resumo da Run e saldo únicos | Resumo por jogador | Baixa |

### tela-de-bencao-e-carta.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R1, R12 | Tela modal: mundo parado, relógio de interface, sem tempo limite e sem pular | Escolha simultânea sem pausa, pausa só local (vulnerável?) ou bênção entre câmaras | Alta |
| R7, R9 | `escolher(i)` e `tela_fechada` fecham o fluxo de um jogador; sem cronômetro (P4) | `tela_fechada` por jogador; Portas e Run esperam todos; sem cronômetro conflita com bloquear os aliados | Alta |
| R12 (pausa) | Esc abre a pausa por cima | Online não há pausa: menu local sem parar o mundo | Média |
| R5, R6, R15, R16 | Insígnia de uma Doutrina; um dispositivo; `GrupoDeCartas` por interface | Insígnia da Doutrina local; o componente é reutilizável sem mudança | Baixa |

### feedback-de-combate.md (leitura parcial; fórmulas e Tuning não lidos)
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R12 (hitstop, impact frame, câmera) | Um impulso de câmera e um impact frame (AC-FB-16, AC-FB-17) | Definir se o hitstop é local ao atingido ou global | Alta |
| R10 | `jogador_atingido` inverte o sprite; `jogador_morreu` anima "o Iniciado" e pede o passe da tela | Id de jogador no evento; feedback mais discreto para aliado | Média |
| L82–83 | VFX de disparo e projétil "do jogador" em fila única | Orçamento de VFX com 4 jogadores, com teto e prioridade | Média |
| L144, L376 | Dano recebido sem número (lido na Vida do HUD) | Aliados também sem número; talvez barra do aliado | Baixa |

### telemetria-local.md
| Onde | Pressuposto de 1 jogador | Gancho | Grav. |
|---|---|---|---|
| R2 a R5 | Uma sessão = um arquivo; campos sem id de jogador; contadores por câmara de um jogador | Campo `jogador` (índice) e `n_jogadores`; contadores por jogador | Média |
| R4 (`run_iniciada`, `oferta`, `bencao`, `porta`, `morte`, `run_encerrada`) | `estado_inicial` e resumo únicos; oferta única; porta e morte sem papel | Listas por jogador; `jogador` e papel nas ofertas, portas e mortes | Média |
| R7 | Sem identificador de pessoa nem IP | Não gravar ids de outras contas; usar índice de assento (0 a 3) | Baixa |
| R11 | Metas (dano por câmara ÷ `vida_max`, duração) para 1 jogador | Metas por `n_jogadores` | Baixa |

## O que este levantamento não faz

- Não propõe a resposta para nenhuma pergunta aberta (`game-concept.md` seção 13b).
- Não edita nenhum GDD aprovado. Quando o GDD do Co-op online for escrito, cada
  linha acima vira uma nota de cabeçalho no GDD afetado, como nas notas
  "pendente" já usadas no MVP.
- Não cobre netcode (modelo, latência, desconexão): hoje não é um sistema do índice.

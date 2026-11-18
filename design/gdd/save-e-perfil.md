# Save e perfil (MVP mínimo)

> **Status**: Approved
> **Author**: systems-designer (lote Pactos, brief `production/session-state/brief-pactos-gdds.md`; aprovado pelo usuário em 2026-11-16)
> **Last Updated**: 2026-11-18 (consolidação de decisões aprovadas pelo usuário em 2026-11-16); 2026-11-16; 2026-11-15
> **Last Verified**: 2026-11-15 contra ADR-0013 (Decision §1–§6 e Decisões do usuário 1–3), `maldicoes.md` (Summary, R2, Dependencies), `telemetria-local.md` (R2, R6, R8), `input-e-controle.md` (R8, Edge Cases › Remapeamento, Dependencies), `conteudo-orientado-a-dados.md` (R2, V9), `chefes.md` (R9) e `docs/engine-reference/godot/`
> **Sistema**: #27 (entrega 22f) · Category: `Persistence` · Layer: `Foundation/Core` · Priority: `MVP` (mínimo)
> **Implements Pillar**: P1 (escolha com identidade: os pactos do jogador são dele e atravessam runs)

## Summary

**Save e perfil** guarda entre sessões o que o jogador construiu com as
Maldições: quais espécies estão pactuadas e o vínculo com cada uma. No MVP há
**um perfil só** e **um arquivo**, `user://perfil.cfg`, gravado de forma atômica
pelo adaptador do ADR-0013. O Save é dono do **formato**, de **quando grava**, da
**versão e migração**, do tratamento de **arquivo ausente, corrompido ou de
versão futura** e do **reset**. O **conteúdo** é do GDD de Vínculo e pactos: o
Save o trata como uma seção opaca, lida e escrita por `ler()`/`escrever()`.
Oficina, desbloqueios, Rito e Campus são da fatia vertical; aqui ficam só os
pontos de extensão.

> **Quick reference** — Layer: `Foundation/Core` · Priority: `MVP` · Key deps: `Vínculo e pactos (conteúdo), Conteúdo orientado a dados (ids), Run e regiões (fim da run), ADR-0013 (armazém e gravação atômica)`

## Overview

O cânone diz que o vínculo é consentido e não comandado. Um pacto perdido por
causa de um arquivo seria uma quebra de promessa. Por isso o Save do MVP faz
pouco, mas faz com segurança: grava no momento do pacto, grava no fim de cada
run e grava ao sair. Nunca grava no meio de um passo de jogo. Nunca apaga um
arquivo que não conseguiu ler: guarda uma cópia e avisa.

O Save **não** guarda a run. Fechar o jogo no meio de uma expedição perde a
expedição, como hoje (ADR-0013 §6; Economia R7). O saldo de Fragmentos continua
só em memória no MVP (AC-EF-20). Binds, última arma e opções continuam nos seus
arquivos próprios (ADR-0013 §2). O Save do MVP é só o arquivo do perfil.

**Fantasia do jogador:** "minhas Maldições me esperam". Ao abrir o jogo, as
espécies pactuadas e o vínculo estão lá, sem tela de carregar e sem escolha de
slot. O Save é invisível quando funciona e honesto quando falha.

**Sem este sistema,** a decisão do usuário "tudo atravessa runs" não existe: cada
sessão recomeçaria sem pactos e a Doutrina de Pactos perderia a sua progressão.

## Detailed Design

### Core Rules

**R1. Perfil único no MVP.** Existe só o **perfil 0**. Não há tela de slots nem
escolha de perfil. Os caminhos saem de `CaminhosDePersistencia.de(0)`
(ADR-0013 §2), o que deixa a porta aberta para slots ou para um segundo jogador
local (`user://perfis/<n>/`, ADR-0013 "Nota de preparação para co-op") sem
mudar este GDD. Perfil único em vez de 3 slots: slots exigem
tela de escolha (Menus é Vertical Slice) e não servem a nenhum teste do MVP.

**R2. Arquivo e formato.** O perfil mora em **`user://perfil.cfg`**, no formato
`ConfigFile` (texto INI), lido e gravado por um `RepositorioDePerfil` com a
mesma forma dos repositórios do ADR-0013 §3 (`carregar()` nunca falha;
`salvar() -> Error`). O ADR-0013 §6 já reservava esse nome para a fatia
vertical; este GDD antecipa o arquivo para o MVP com uma única seção de
conteúdo (contrato pedido ao ADR-0013, ver Dependencies). Estrutura:

| Seção | Chave | Tipo | Dono | Conteúdo |
|---|---|---|---|---|
| `[meta]` | `schema_version` | `int` | Save | Versão do formato do arquivo inteiro. MVP = **1** |
| `[meta]` | `gravado_por` | `String` | Save | Versão do build que gravou (diagnóstico; nunca lida como regra) |
| `[vinculo]` | chaves de primeiro nível do dicionário de `escrever()` | ver R3 | **Vínculo e pactos** | Seção opaca "dados do Vínculo" |
| `[oficina]`, `[desbloqueios]`, `[rito]`, `[campus]`, `[economia]`, `[run]` | — | — | sistemas da fatia vertical | **Reservadas**: o MVP não as escreve (R12) |

Nada de caminho absoluto, nome de usuário, hora local ou identificador de
máquina entra no arquivo (mesma regra da Telemetria R7).

**R3. Seção opaca do Vínculo (contrato `ler()`/`escrever()`).** O Save não
conhece os campos do Vínculo. A interface é:

- `escrever() -> Dictionary`: o Vínculo devolve o estado a persistir. Valores
  permitidos: `bool`, `int`, `String`, e `Array`/`Dictionary` feitos só desses
  tipos (sem `float`, sem `Object`, sem `Resource`, sem `StringName`). O
  `float` fica fora para o arquivo ser idêntico byte a byte entre gravações
  iguais.
- `ler(dados: Dictionary) -> void`: o Save entrega o que leu (já migrado, R6, e
  já filtrado de ids desconhecidos, R9). Se não há arquivo, entrega `{}` e o
  Vínculo aplica os seus padrões. **Validar faixas** (ex.: `nivel` acima do
  máximo, pontos negativos) é do Vínculo, dentro de `ler()`.
- **Única exigência estrutural do Save:** o estado por espécie vem num
  dicionário de primeiro nível chamado `especies`, com **chave = id da espécie**
  (`CurseDef`, Conteúdo R2). O Save precisa disso para tratar ids desconhecidos
  (R9). Qualquer outra referência a id de espécie fora de `especies` deve ser um
  `Array` de ids declarado ao Save em `campos_de_ids()` (no MVP:
  `["ultima_dupla", "encontro_pendente"]`, `vinculo-e-pactos.md` V31).
- **Conteúdo do Vínculo** (lista final e faixas em `vinculo-e-pactos.md` V30; o
  Save só lê a forma): `versao: int`, `primeiro_pacto_concedido: bool`,
  `primeiro_encontro_visto: bool`, `runs_pactos_iniciadas: int`,
  `runs_pactos_sem_encontro: int`, `encontro_pendente: [id]` (0–1 id),
  `ultima_dupla: [id, id]` (`""` = vaga vazia) e `especies: { <id>: {pactuada:
  bool, vinculo_pontos: int, nivel: int, encontros_vistos: int,
  encontros_bem_sucedidos: int} }`. Todos os tipos estão na lista permitida
  acima (sem `float`, sem `StringName`).

**R4. Carga.** O Save carrega o perfil **uma vez por sessão**, na inicialização,
**depois** que o catálogo chega a Pronto (Conteúdo) e antes da tela de escolha
de arma e Maldições. Sequência pura: ler texto pelo armazém → recuperação de
sobras da gravação atômica (ADR-0013 §4) → interpretar → checar versão (R6) →
validar tipos de `[meta]` e da forma de `[vinculo]` (R8) → migrar → filtrar ids
(R9) → `vinculo.ler(dados)`. Qualquer erro cai num dos casos de R8 e o jogo
segue. Carregar nunca trava nem derruba o jogo.

**R5. Quando grava.** O Save grava **só** nestes pontos:

| Gatilho | Origem | Observação |
|---|---|---|
| **Pacto registrado** | evento do Vínculo `pacto_registrado(especie_id)` (nome fixado em `vinculo-e-pactos.md` V32: primeiro pacto V3, "Oferecer" V10, "Pactuar" V18); inclui `pactuar` no chefe (Chefes R9) | Grava no primeiro ponto seguro (R5.1) |
| **Fim da run** | `run_encerrada` (~~vitória ou derrota~~ vitória, derrota ou abandono; emenda Pactos, 2026-11-15; Run e regiões, AC-RN-10) | Grava depois que o Vínculo consolidou a run |
| **Sair do jogo** | "Sair" no menu ou pedido de fechar a janela | Grava antes de encerrar o processo (R10) |
| **Reset de perfil** | Opções (R11) | Fora de run |
| **Dupla escolhida** | confirmação da dupla antes da expedição (Maldições R2) | Atualiza `ultima_dupla`; está num estado Menus |

- **R5.1 Ponto seguro.** Nenhuma gravação ocorre **dentro** de um passo em
  estado Jogo (ADR-0013 §4 e Guidelines). O gatilho só marca o perfil como
  **pendente**. O `Main` executa a gravação pendente no fim de um passo cujo
  estado é Pausa, Bênção, Menus, Morte ou Transição (ADR-0001), nunca no meio da
  lista de eventos do passo (ADR-0002). Se o pacto acontecer em estado Jogo, a
  gravação espera o próximo estado fora de Jogo (no pior caso, a Transição para
  a próxima câmara). **Contrato pedido ao Vínculo:** a escolha de consentimento
  do pacto acontece num estado fora de Jogo (tela de escolha), para o pacto
  gravar no mesmo instante.
  - **(emenda Pactos, 2026-11-15)** Confirmado: **Bênção** está na lista de
    estados onde se grava. O Vínculo V9 põe a tela de consentimento (e a do
    chefe, V18) no estado Bênção do ADR-0001, então o pacto
    grava no fim do mesmo passo.
- **R5.2 Só grava se mudou.** O Save monta o texto (`[meta]` + `escrever()`) e
  compara com o último texto gravado com sucesso. Igual: não grava e conta como
  sucesso. Isso deixa barato chamar o Save nos gatilhos sem checar antes.
- **R5.3 Uma gravação por ponto seguro.** Vários gatilhos antes do ponto seguro
  viram **uma** gravação, com o estado mais recente.

**R6. Versão e migração.** `schema_version` ausente → tratado como **1**
(ADR-0013 §3). Versão **menor** que a atual → `migrar(v_de, dados) -> dados`,
função pura em cadeia (1→2→3…), testada com fixtures; o arquivo migrado só é
regravado no próximo gatilho de R5 (a carga não grava). As migrações de
**conteúdo** da seção `[vinculo]` são funções puras escritas pelo dono do
conteúdo (Vínculo) e registradas na cadeia do Save; o Save decide a ordem e
quando rodam. Versão **maior** que a suportada → R8 caso "versão futura".

**R7. Gravação atômica.** Toda gravação usa `gravar_atomico(caminho, texto)` do
`ArmazemDeArquivos` (ADR-0013 §4: temporário, releitura, substituição e
recuperação pura na carga). O Save não toca `FileAccess`, `DirAccess` nem
`ConfigFile.save/load` (ADR-0013 Guidelines). `gravar_atomico` falhou → o
arquivo anterior continua o vigente, o estado novo continua valendo **em
memória**, e o aviso `PERSIST_FALHA_GRAVAR` aparece **uma vez por sessão**
(ADR-0013, Decisão do usuário 1). O próximo gatilho tenta de novo. Sem laço de
nova tentativa.

**R8. Arquivo ausente, corrompido ou de versão futura.** Mesmas regras do
ADR-0013 §3, com o modo de sessão que cada caso deixa:

| Caso | O que o jogo faz | Modo da sessão | Aviso |
|---|---|---|---|
| **Ausente** (primeira execução) | `ler({})`, Vínculo nos padrões (sem pactos) | Normal: grava no próximo gatilho | Nenhum |
| **Corrompido** (texto não interpreta; `[meta]` com tipo errado; `[vinculo]` sem `especies` como `Dictionary` ou com valor de tipo proibido por R3) | Cópia byte a byte para `perfil.cfg.bak` (ou `.bak2`, `.bak3`…; nunca apaga backup) e `ler({})` | Normal **só se a cópia deu certo**; se a cópia falhou, **Sem gravação** | `PERFIL_CORROMPIDO`, uma vez |
| **Versão futura** (`schema_version` > suportada) | `ler({})`; arquivo preservado | **Sem gravação**: nenhum gatilho grava nesta sessão | `PERFIL_VERSAO_FUTURA`, uma vez |

- **Arquivo inteiro inválido, sem valor parcial** (ADR-0013 §3). A forma fina de
  cada espécie (`nivel` é `int`?) **não** invalida o arquivo: é validada pelo
  Vínculo em `ler()`, que descarta ou corrige só aquela entrada. O Save valida
  apenas o que é dele: `[meta]`, a existência de `especies` e os tipos
  permitidos.
- **Modo Sem gravação.** O jogo roda com o estado em memória (pactos feitos
  nesta sessão funcionam até fechar), mas o arquivo nunca é tocado. Protege o
  progresso de quem abriu um build antigo (versão futura) ou cujo arquivo ruim
  não pôde ser copiado.

**R9. Ids desconhecidos.** Ids de espécie nunca são renomeados (Conteúdo R2),
mas um build pode não ter uma espécie que o arquivo tem (espécie removida, build
de teste com catálogo menor, ou arquivo vindo de build mais novo da mesma
versão de schema). Regra:

- Entrada de `especies` cujo id **não** existe no catálogo de `CurseDef` →
  **órfã**: não vai para `ler()`, fica guardada à parte e é **regravada igual**
  em toda gravação. Quando um build com a espécie abrir o arquivo, ela volta.
- Id que existe mas está `obsoleto` (Conteúdo R2, V9) → é conhecido; vai para
  `ler()`. O Vínculo decide se a mostra.
- Id desconhecido num campo de `campos_de_ids()` (`ultima_dupla` ou
  `encontro_pendente`) → é trocado por `""` antes de `ler()`; o Vínculo trata
  `""` como vaga vazia (em `encontro_pendente`, como "sem pendente",
  `vinculo-e-pactos.md` V33).
- Chave de primeiro nível desconhecida em `[vinculo]` e **seção desconhecida**
  (inclusive as reservadas de R2) → preservadas como texto e regravadas iguais.
  Isso estende o "chave desconhecida é ignorada" do ADR-0013 §3: ignorada na
  leitura, **mantida** na escrita.

**R10. Fechar o jogo no meio da run.** A run **não** é salva no MVP.

- **Pacto**: nunca se perde por fechar o jogo, porque grava no ponto seguro do
  próprio pacto (R5). Só uma queda do processo **entre** o pacto em estado Jogo
  e o próximo ponto seguro o perde (ver R5.1, contrato pedido ao Vínculo).
- **Vínculo ganho na run** (pontos, encontros): o Save grava o que `escrever()`
  devolver. Decisão deste GDD: **ao sair normalmente no meio da run** (menu Sair
  ou fechar a janela), o Save pede `escrever()` e grava; **o Vínculo deve
  consolidar a run como abandono, com a mesma regra de uma derrota** (contrato
  pedido ao Vínculo). **Em queda do processo** (crash, matar o processo, falta
  de luz) vale o último arquivo gravado: o vínculo ganho desde o último gatilho
  se perde. Alternativa rejeitada: perder sempre o vínculo da
  run ao fechar; ela pune quem precisa sair e não protege nada, porque o
  vínculo não tem custo a evitar.
- **Falha ao gravar na saída:** em vez de fechar em silêncio, o jogo mostra
  `PERFIL_SAIR_SEM_SALVAR` com "Tentar de novo" e "Sair sem salvar". Uma nova
  tentativa por clique, sem laço. O mecanismo de interceptar o
  pedido de fechar a janela é do ADR (NOT SOURCEABLE na referência local).

**R11. Reset de perfil.** Em Opções, fora de run (só no menu principal),
"Apagar progresso de pactos" pede **duas confirmações** (`PERFIL_RESET_CONFIRMAR`).
Confirmado: copia `perfil.cfg` byte a byte para `perfil.cfg.reset.bak` (ou
`.reset.bak2`…; nunca apaga backup), chama `vinculo.ler({})` e grava um perfil
novo (órfãs e seções desconhecidas **também** são descartadas no reset). Se a
cópia falhar, o reset é cancelado e o arquivo fica intacto. O reset **não** toca
`opcoes.cfg`, `preferencias.cfg`, `input_binds.cfg` nem a telemetria
(ADR-0013 §2). No modo Sem gravação (R8), o reset fica indisponível.

**R12. Exportar e importar.** Segue o padrão do ADR-0013 §6: cada dono expõe a
sua porta e o Save a chama. No MVP, a porta do Vínculo é `escrever()`
(exportar) e `ler()` (importar). O `RepositorioDePerfil` expõe
`exportar_texto() -> String` e `importar_texto(texto) -> Error` (o mesmo
caminho de validação da carga, R4–R9), usados por testes e pela fatia vertical.
**Não há tela de exportar/importar no MVP**: o jogador que quiser
levar o perfil copia `perfil.cfg` com o jogo fechado, e a carga o valida. O MVP
**não** chama `ContaFragmentos.exportar/importar` nem o estado do RNG
(Economia R7, AC-EF-20; ADR-0013 §6).

**R13. Build de playtest.** O build de playtest **lê e grava** o perfil
normalmente, porque testar a progressão de pactos entre sessões é parte do que o
playtest mede. Isso é diferente da última arma, que o playtest
não lê (AC-AR-39). A composição pode injetar um `PerfilNulo` (não lê, não grava)
em testes e em debug, sem `if` dentro do Save.

**R14. Injeção e testes.** O Save é lógica pura sobre `ArmazemDeArquivos`,
`RelatorDeAvisos`, o catálogo de ids e a porta do Vínculo, todos injetados pelo
`Main` (ADR-0001, sem Autoload). Testes unitários usam `ArmazemEmMemoria`
(ADR-0013 §1). Só thread principal.

**R15. Pontos de extensão (fatia vertical, não desenhados aqui).** Cada sistema
futuro entra como **mais uma seção opaca** com o mesmo contrato `ler()/escrever()`
e a sua cadeia de migração, registrada no Save: Oficina de Reforja (#22,
`[oficina]`), Desbloqueio de armas (#23, `[desbloqueios]`), Rito de Iniciação
(#24, `[rito]`), Campus (`[campus]`), saldo da Economia (`[economia]`, que exige
revisar Economia R7) e save de run (`[run]`, com seed e fluxos mascarados com
`& 0xFFFFFFFF` na leitura, RNG e ADR-0013 §6). A migração única de
`preferencias.cfg` para o perfil (Armas R4, ADR-0013 §6) também é da fatia
vertical. Slots de perfil (R1) entram por `CaminhosDePersistencia.de(n)`.

### States and Transitions

| Estado do Save | Entra quando | Grava? | Sai quando |
|---|---|---|---|
| **Não carregado** | início da sessão | não | catálogo Pronto → carga (R4) |
| **Normal** | carga ok, arquivo ausente, ou corrompido com `.bak` feito | sim, nos gatilhos de R5 | fim da sessão |
| **Pendente** (sub-estado de Normal) | um gatilho de R5 | no próximo ponto seguro (R5.1) | gravou (volta a Normal) ou falhou (Normal com aviso, R7) |
| **Sem gravação** | versão futura, ou `.bak` falhou, ou catálogo Falhou | nunca | fim da sessão |

Se o catálogo ficar em Falhou (Conteúdo), o Save **não carrega e não grava**
(Sem gravação): sem catálogo não há como separar ids conhecidos de órfãos, e
gravar transformaria todo o perfil em órfão ou em vazio.

### Interactions with Other Systems

| Sistema | Entra no Save | Sai do Save | Dono do contrato |
|---|---|---|---|
| Vínculo e pactos | `escrever()`, `campos_de_ids()`, migrações de conteúdo, evento de pacto registrado | `ler(dados)` na carga e no reset | Vínculo (conteúdo) / Save (formato) |
| Conteúdo orientado a dados | ids de `CurseDef`, estado do catálogo (Pronto/Falhou) | — | Conteúdo |
| Run e regiões | `run_encerrada`, estado de jogo (ADR-0001) | — | Run |
| Chefes | `pactuar` passa pelo Vínculo (Chefes R9) | — | Vínculo |
| UI / Opções (ADR-0012) | ação de reset, sair do jogo | avisos `PERFIL_*`, `PERSIST_FALHA_GRAVAR`, modo Sem gravação | ADR-0012 |
| Armazém (ADR-0013) | resultado de leitura e de `gravar_atomico`/`copiar_bytes` | texto a gravar | ADR-0013 |
| Input, Armas, Telemetria | — | nada: arquivos próprios, fora do perfil | cada um |

## Formulas

Este sistema não define regra numérica de balanceamento (taxa, curva, custo ou
limiar que um passe de balanço ajustaria). Os únicos números são de formato:
`schema_version = 1` (R2, R6) e o sufixo crescente dos backups (`.bak`, `.bak2`,
…; R8, R11), herdados do ADR-0013 §3. Por isso não há seção de fórmulas nem
`Tuning Knobs`; as quantidades do vínculo (pontos, níveis) são fórmulas do GDD
de Vínculo e pactos.

## Edge Cases

- **Primeira execução, sem `perfil.cfg`:** `ler({})`, sem pactos, sem aviso. O
  arquivo nasce no primeiro gatilho de R5 (normalmente a escolha da dupla ou o
  fim da primeira run).
- **Queda no meio da gravação atômica:** a recuperação do ADR-0013 §4 decide na
  próxima carga: destino válido → usa e apaga sobras; destino ausente e `.old`
  presente → restaura `.old`; `.tmp` sozinho nunca é promovido. O jogador perde
  no máximo o que estava sendo gravado.
- **Arquivo vazio (0 bytes) ou só espaços:** **corrompido** (R8), com `.bak`.
  Um perfil válido sempre tem `[meta]`, porque o Save sempre o escreve.
  (Diferente de um arquivo com conteúdo e sem `schema_version`, que vale 1, R6.)
- **`[meta]` presente e `[vinculo]` ausente:** válido; `ler({})`. Pode ser um
  perfil gravado antes de qualquer dado do Vínculo.
- **`schema_version` com tipo errado (ex.: `"1"` texto):** corrompido (R8).
- **`schema_version = 0` ou negativo:** corrompido (R8); não existe versão menor
  que 1.
- **Duas instâncias do jogo abertas ao mesmo tempo:** a última a gravar vence.
  Resíduo aceito, como na Telemetria (ADR-0013 §5). Sem trava de arquivo no MVP.
- **Espécie removida do catálogo com pacto feito:** a entrada vira órfã (R9),
  some do jogo e volta se a espécie voltar. `ultima_dupla` com esse id recebe
  `""` naquela vaga.
- **As duas vagas de `ultima_dupla` desconhecidas:** `["", ""]`; a tela de dupla
  abre sem pré-seleção (regra da tela é do Vínculo/Maldições R2).
- ~~**Pacto no chefe e morte no mesmo passo:** a morte do jogador vence (Maldições
  Edge Cases, Combate R16) e não há `pactuar`; nada a gravar além do fim da run.~~
  **(emenda Pactos, 2026-11-15) Morte antes do Subjugado:** se o jogador morre
  antes de o chefe entrar em `Subjugado`, não há escolha nem `pactuar`; nada a
  gravar além do fim da run. Em `Subjugado` não há dano (Chefes R9), então a morte
  não pode cruzar com a escolha.
- **Pacto feito e o jogador sai pelo menu na tela seguinte:** o pacto já gravou
  no ponto seguro (R5.1); a saída grava de novo só se algo mudou (R5.2).
- **Falha ao gravar no pacto, sucesso no fim da run:** o pacto continua em
  memória (R7) e entra no arquivo na gravação do fim da run. Um aviso só na
  sessão.
- **Disco cheio ou sem permissão em toda gravação:** um `PERSIST_FALHA_GRAVAR`
  na sessão; na saída, `PERFIL_SAIR_SEM_SALVAR` (R10). O jogo nunca trava.
- **Versão futura e o jogador faz um pacto:** o pacto vale até fechar o jogo e
  não é gravado (Sem gravação). O aviso `PERFIL_VERSAO_FUTURA` já disse isso no
  início da sessão.
- **Jogador apaga `perfil.cfg` com o jogo aberto:** a próxima gravação recria o
  arquivo com o estado em memória. Nada é relido no meio da sessão.
- **Jogador cola um `perfil.cfg` de outra máquina com o jogo aberto:** ignorado
  até a próxima sessão; se o jogo gravar antes de fechar, sobrescreve. O jeito
  suportado é copiar com o jogo fechado (R12).
- **`.bak` já existe até `.bak9` e mais:** o sufixo continua crescendo (`.bak10`);
  nunca apaga (ADR-0013 §3). Arquivos de backup não são lidos pelo jogo.
- **Valor `float` vindo de um arquivo editado à mão em `[vinculo]`:** tipo
  proibido (R3) → corrompido, com `.bak`.
- **Catálogo em Falhou:** Sem gravação; nenhuma leitura de perfil, nenhum aviso
  de perfil (o erro do catálogo já tem a sua tela, Conteúdo).

## Dependencies

### Depends On (Upstream)

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| **ADR-0013 Persistência** (arquitetura) | Forte | `ArmazemDeArquivos`, `gravar_atomico`, `copiar_bytes`, recuperação na carga, regras de `.bak`, `PERSIST_FALHA_GRAVAR` | Não há gravação segura |
| **Conteúdo orientado a dados** | Forte | ids de `CurseDef` estáveis (R2), registro de ids (V9), estado Pronto/Falhou | Sem catálogo, Sem gravação (States) |
| **Vínculo e pactos** | Forte, por contrato | conteúdo da seção `[vinculo]`, `escrever()`, `campos_de_ids()`, migrações de conteúdo, evento de pacto | Nada a salvar no MVP |
| **Run e regiões** | Suave | `run_encerrada` (gatilho R5) e o estado de jogo (ADR-0001) para o ponto seguro | Grava só no pacto e na saída |
| **Input e controle** | Suave | dono de `user://input_binds.cfg` (perfil 0, ADR-0013 §2); o Save não lê, não grava e não reseta esse arquivo (R11) | Nada muda no perfil |

### Depended On By (Downstream)

| Sistema | Tipo | O que leva daqui |
|---|---|---|
| **Vínculo e pactos** | Forte | Persistência do seu estado entre sessões; quando grava; tratamento de ids desconhecidos |
| **Conteúdo orientado a dados** | Suave | O Save exige ids de `CurseDef` nunca renomeados e o estado `obsoleto` em vez de apagar (Conteúdo R2, V9); o catálogo é consultado, não alterado |
| **Maldições** | Suave (via Vínculo) | Espécies pactuadas e `ultima_dupla` para a escolha da dupla (Maldições R2) |
| **Menus / Opções (ADR-0012)** | Suave | Reset de perfil, avisos `PERFIL_*`, saída com falha |
| **Input e controle** | Suave | Resposta à pendência do Input (`input-e-controle.md:551`): **os binds ficam em `user://input_binds.cfg` próprio**, perfil 0, fora de `perfil.cfg` (ADR-0013 §2); não há migração no MVP |
| **Armas das Doutrinas** | Suave | `preferencias.cfg` continua fora do perfil no MVP; migração para o perfil é fatia vertical (R15) |
| **Telemetria local** | nenhuma | Telemetria R6 diz "não é Save": confirmado; o perfil não guarda nada da telemetria |
| **Oficina (#22), Desbloqueio (#23), Rito (#24), Menus (#30)** | Forte (fatia vertical) | Pontos de extensão de R15 |
| **Economia de Fragmentos, RNG com seed** | Suave (fatia vertical) | Seções reservadas `[economia]` e `[run]`; MVP não as usa |

### Contratos pedidos

- **A `vinculo-e-pactos.md`:** (1) expor `escrever()/ler()/campos_de_ids()` com
  os tipos de R3 e o estado por espécie em `especies` com chave = id; (2) validar
  faixas em `ler()`; (3) a escolha de consentimento do pacto ocorre fora do
  estado Jogo (R5.1); (4) consolidar a run como abandono (regra de derrota) quando
  o jogador sai no meio da run (R10); (5) fornecer as migrações de conteúdo
  quando seus campos mudarem (R6); (6) nomear o evento de pacto registrado
  (atendido: `pacto_registrado(especie_id)`, V32; (1) atendido na V30–V31).
- **A ADR-0013:** acrescentar `user://perfil.cfg` (dono do formato: Save; perfil
  0) à tabela §2 já no MVP, e ajustar a frase do §6 que o reserva só para a fatia
  vertical; registrar a preservação de seções/chaves desconhecidas na escrita
  (R9) como regra deste repositório.
- **A ADR-0012:** itens de UI de R11 e os avisos da UI Requirements.
- **A `input-e-controle.md`:** atualizar a linha de Dependencies "Binds em
  `user://` próprio até o GDD de Save existir" para "binds em `input_binds.cfg`,
  decisão do Save".

## UI Requirements

Textos por chave, no tom do jogo, sem jargão técnico. Avisos aparecem uma vez por
sessão, no menu principal ou na próxima tela fora de Jogo, nunca por cima do
combate.

| Chave | Quando | Conteúdo mínimo | Ação |
|---|---|---|---|
| `PERFIL_CORROMPIDO` | R8 corrompido | O progresso de pactos não pôde ser lido. Uma cópia foi guardada. Você começa sem pactos. | OK |
| `PERFIL_VERSAO_FUTURA` | R8 versão futura | Este progresso é de uma versão mais nova do jogo. Nada será salvo nesta sessão para não perdê-lo. | OK |
| `PERSIST_FALHA_GRAVAR` | R7 (chave do ADR-0013) | Não foi possível salvar. O progresso vale até fechar o jogo. | OK (discreto) |
| `PERFIL_SAIR_SEM_SALVAR` | R10, falha na saída | Não foi possível salvar o progresso. | "Tentar de novo" / "Sair sem salvar" |
| `PERFIL_RESET_CONFIRMAR` | R11 | 1ª: "Apagar todos os pactos e vínculos?" 2ª: "Isso não pode ser desfeito no jogo." | "Cancelar" (padrão) / "Apagar" |

- Em Sem gravação, o item de reset aparece desabilitado com o motivo.
- Sem ícone de "salvando": a gravação é rápida e ocorre fora de Jogo.
- Navegável por teclado e gamepad com `ui_voltar` = Cancelar (Input R8).

## Cross-References

- [../../docs/architecture/adr-0013-persistencia-do-mvp.md](../../docs/architecture/adr-0013-persistencia-do-mvp.md) (§1 armazém, §2 arquivos, §3 repositórios, §4 gravação atômica, §6 sem save de run, Decisões 1–3)
- [../../docs/architecture/adr-0001-orquestrador-do-passo.md](../../docs/architecture/adr-0001-orquestrador-do-passo.md) (estados de jogo, composição no `Main`)
- [../../docs/architecture/adr-0002-canal-de-eventos.md](../../docs/architecture/adr-0002-canal-de-eventos.md) (lista de eventos esvaziada no fim do passo)
- `vinculo-e-pactos.md` (#38 / 22d, conteúdo da seção `[vinculo]`)
- [maldicoes.md](maldicoes.md) (R2 dupla, catálogo de `CurseDef`)
- [chefes.md](chefes.md) (R9 `Subjugado` → `pactuar`)
- [conteudo-orientado-a-dados.md](conteudo-orientado-a-dados.md) (R2 ids, V9)
- [run-e-regioes.md](run-e-regioes.md) (`run_encerrada`, AC-RN-10)
- [input-e-controle.md](input-e-controle.md) (R8, Edge Cases › Remapeamento, Dependencies)
- [telemetria-local.md](telemetria-local.md) (R6 "não é Save", R7 privacidade)
- [armas-das-doutrinas.md](armas-das-doutrinas.md) (R4, AC-AR-39)
- [economia-de-fragmentos.md](economia-de-fragmentos.md) (R7, AC-EF-20)
- `docs/engine-reference/godot/breaking-changes.md` (`FileAccess.store_*` → `bool`, 4.4)

**Engine (NOT SOURCEABLE na referência local):** `ConfigFile.parse`/`encode_to_text`,
`DirAccess.rename` sobre destino existente no Windows, e o mecanismo de
interceptar o pedido de fechar a janela não estão em `docs/engine-reference/godot/`.
Os dois primeiros têm experimento no ADR-0013 (E-P3, E-P2); o terceiro precisa
de verificação pelo ADR que tratar a saída do jogo.

## Acceptance Criteria

`[L]` = unitário com `ArmazemEmMemoria`, Vínculo dublê e catálogo em memória.
`[I]` = integração com o armazém real numa raiz temporária (ADR-0013 Validation).

- **AC-SP-01 [L] R8 ausente.** **GIVEN** armazém vazio **WHEN** o Save carrega
  **THEN** o Vínculo recebe `ler({})` uma vez, zero gravações, zero avisos, estado Normal.
- **AC-SP-02 [L] R2/R3 ida e volta.** **GIVEN** um Vínculo dublê cujo
  `escrever()` devolve `{especies: {vulto_mudo: {pactuada: true, vinculo_pontos: 7, nivel: 1, encontros_vistos: 2}}, ultima_dupla: ["vulto_mudo", ""]}`
  **WHEN** o Save grava e uma nova instância carrega o mesmo armazém **THEN**
  `ler()` recebe um dicionário igual e o arquivo tem `[meta] schema_version=1`.
- **AC-SP-03 [L] R5.2.** **GIVEN** um perfil gravado **WHEN** um gatilho ocorre
  sem mudança em `escrever()` **THEN** o armazém registra zero `gravar_atomico`.
- **AC-SP-04 [L] R5.1.** **GIVEN** estado Jogo e um `pacto_registrado` no passo
  `n` **WHEN** os passos `n`..`n+5` rodam em Jogo e o passo `n+6` em Transição
  **THEN** há zero gravações até o fim do passo `n+5` e exatamente uma no fim do
  passo `n+6`, nunca durante o processamento de um passo.
- **AC-SP-05 [L] R5.3.** **GIVEN** três gatilhos (pacto, dupla, pacto) antes de um
  ponto seguro **WHEN** o ponto seguro chega **THEN** uma gravação, com o estado
  do último gatilho.
- **AC-SP-06 [L] R5.** **GIVEN** um perfil que mudou na run **WHEN**
  `run_encerrada(derrota)` e depois `run_encerrada(vitória)` em outra run **THEN**
  cada uma produz uma gravação no ponto seguro seguinte.
- **AC-SP-07 [L] R7 falha.** **GIVEN** `programar_falha(&"gravar_atomico", 1)`
  **WHEN** dois gatilhos gravam em pontos seguros diferentes **THEN** o 1º
  devolve erro e emite `PERSIST_FALHA_GRAVAR` uma vez, o estado em memória não
  muda, e o 2º grava com sucesso sem novo aviso.
- **AC-SP-08 [L] R8 corrompido.** **GIVEN** `perfil.cfg` com o texto `%%lixo`
  **WHEN** o Save carrega **THEN** `perfil.cfg.bak` tem bytes idênticos ao
  original, `ler({})`, um `PERFIL_CORROMPIDO`, e o próximo gatilho substitui
  `perfil.cfg`.
- **AC-SP-09 [L] R8 backup já existe.** **GIVEN** `perfil.cfg.bak` já presente e
  `perfil.cfg` corrompido **WHEN** carrega **THEN** a cópia vai para
  `perfil.cfg.bak2` e `perfil.cfg.bak` fica intacto.
- **AC-SP-10 [L] R8 cópia falha.** **GIVEN** arquivo corrompido e falha
  programada em `copiar_bytes` **WHEN** carrega e depois ocorre um gatilho **THEN**
  estado Sem gravação e zero `gravar_atomico`; `perfil.cfg` com os bytes originais.
- **AC-SP-11 [L] R8 versão futura.** **GIVEN** `schema_version=2` com Save que
  suporta 1 **WHEN** carrega, ocorre um pacto e o jogador sai **THEN** `ler({})`,
  um `PERFIL_VERSAO_FUTURA`, zero gravações e o arquivo byte a byte igual.
- **AC-SP-12 [L] R6 migração.** **GIVEN** um fixture sem `schema_version` e uma
  cadeia de teste `migrar(1→2)` **WHEN** um Save de versão 2 carrega **THEN** o
  fixture é tratado como 1, `ler()` recebe o dado migrado e a carga não grava.
- **AC-SP-13 [L] R9 órfã.** **GIVEN** arquivo com `especies` de `vulto_mudo` e
  `especie_teste_x`, catálogo só com `vulto_mudo` **WHEN** carrega e grava
  **THEN** `ler()` não contém `especie_teste_x` e o arquivo regravado ainda tem
  a entrada de `especie_teste_x` com os mesmos valores.
- **AC-SP-14 [L] R9 `ultima_dupla`.** **GIVEN** `ultima_dupla = ["especie_teste_x", "vulto_mudo"]`
  com `especie_teste_x` fora do catálogo **WHEN** carrega **THEN** `ler()` recebe
  `ultima_dupla = ["", "vulto_mudo"]`.
- **AC-SP-15 [L] R9 seção desconhecida.** **GIVEN** arquivo com `[oficina] nivel=3`
  **WHEN** carrega e grava **THEN** a seção `[oficina]` volta igual no arquivo.
- **AC-SP-16 [L] R3 tipo proibido.** **GIVEN** `[vinculo]` com um `float` em
  `especies` **WHEN** carrega **THEN** caso corrompido de R8 (`.bak` + aviso).
- **AC-SP-17 [L] R8 forma fina.** **GIVEN** `especies.vulto_mudo.nivel = "dois"`
  (texto) e o resto válido **WHEN** carrega **THEN** o arquivo **não** é tratado
  como corrompido (zero `.bak`) e `ler()` recebe a entrada para o Vínculo validar.
- **AC-SP-18 [L] R11 reset.** **GIVEN** perfil com pactos e uma órfã, menu principal
  **WHEN** o jogador confirma as duas telas **THEN** `perfil.cfg.reset.bak` igual
  ao anterior, `ler({})`, um perfil novo gravado sem órfã, e `opcoes.cfg`,
  `preferencias.cfg` e `input_binds.cfg` sem nenhuma operação no registro do armazém.
- **AC-SP-19 [L] R11 cancelado.** **GIVEN** falha programada em `copiar_bytes`
  **WHEN** reset confirmado **THEN** reset cancelado, zero `gravar_atomico`,
  `ler()` não é chamado.
- **AC-SP-20 [L] R10 saída.** **GIVEN** uma run ativa com `escrever()` diferente
  do último gravado **WHEN** o jogador escolhe Sair **THEN** uma gravação antes do
  fim; com falha programada, aparece `PERFIL_SAIR_SEM_SALVAR` e "Tentar de novo"
  faz exatamente mais uma tentativa.
- **AC-SP-21 [L] States catálogo.** **GIVEN** catálogo em Falhou **WHEN** a sessão
  inicia e um gatilho ocorre **THEN** zero leituras e zero gravações de `perfil.cfg`.
- **AC-SP-22 [L] R12.** **GIVEN** `exportar_texto()` de um perfil A **WHEN**
  `importar_texto()` em outro Save **THEN** `ler()` recebe o mesmo dicionário; um
  texto corrompido devolve erro diferente de `OK` e não altera o estado.
- **AC-SP-23 [L] R2 privacidade e determinismo.** **GIVEN** o mesmo `escrever()`
  gravado duas vezes **THEN** os textos são idênticos byte a byte e não contêm
  `user://` globalizado, letra de unidade, nem nome do usuário do sistema.
- **AC-SP-24 [I] R7 e recuperação.** Em raiz temporária: **GIVEN** um
  `perfil.cfg` válido e uma queda simulada em cada passo da sequência atômica
  (E-P2) **WHEN** o Save carrega **THEN** usa o arquivo antigo ou o novo, nunca um
  truncado, e `.tmp` sozinho não é promovido.
- **AC-SP-25 [I] fluxo real.** Em raiz temporária: **GIVEN** um perfil ausente
  **WHEN** uma sessão faz um pacto (dublê), fecha, e uma segunda sessão carrega
  **THEN** a espécie aparece como pactuada na segunda sessão.

## Open Questions

1. **OQ1 — Slots (R1):** o MVP fica com perfil único? Slots dependem de Menus
   (#30, Vertical Slice).
2. ~~**OQ2 — Vínculo ao sair no meio da run (R10):** o abandono consolida com a
   regra de derrota? A regra fina de ganho é do Vínculo; o Save só grava.~~
   **Fechada (emenda Pactos, 2026-11-15):** sim. Vínculo V20b consolida a saída
   como abandono, com a regra de derrota (sem `pts_vitoria`); encontro em
   `Aguardando` vira `Abandonado`. Em queda do processo vale o último arquivo.
3. ~~**OQ3 — Pacto em estado Jogo (R5.1):** o Vínculo aceita pôr o consentimento
   numa tela fora de Jogo? Se não, o pacto espera a próxima Transição, com uma
   janela pequena de perda em crash.~~ **Fechada (emenda Pactos, 2026-11-15):**
   sim. Vínculo V9 põe a tela de consentimento fora de Jogo, no estado Bênção
   (ADR-0001); o pacto grava no mesmo instante (R5.1).
4. **OQ4 — Playtest (R13):** o build de playtest lê o perfil (progressão entre
   sessões) ou começa sempre limpo, como a última arma (AC-AR-39)?
5. **OQ5 — Exportar/importar pela UI (R12):** fica para a fatia vertical?
6. **OQ6 — Preservar desconhecidos na escrita (R9):** o ADR-0013 §3 diz só
   "ignorada". Preservar só no perfil ou em todos os repositórios?
7. **OQ7 — Interceptar o fechar da janela (R10):** API NOT SOURCEABLE na
   referência local; precisa de verificação no ADR de UI/saída antes da story.
8. **OQ8 — Duas instâncias:** aceitar "última grava vence" no MVP ou criar uma
   trava simples de arquivo?

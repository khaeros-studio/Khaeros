# ADR-0015: Ciclo da run e composição

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

> **Quem pode mover para `Accepted`: o usuário, ou o `technical-director` com a
> confirmação explícita do usuário. Nenhum outro agente, e nenhuma skill sozinha.**

## Date

2026-11-16

## Last Verified

2026-11-16 (contra `design/gdd/run-e-regioes.md` R1–R11-P, `portas-e-recompensas.md` R2-P/R6-P/R9-P/R11-P/R12-P, `economia-de-fragmentos.md` R1/R4-P/R6/R7, `bencaos-tradicoes.md` R2/R3/R8/R9, `vinculo-e-pactos.md` V4–V12/V18/V20/V20b/V30–V34, `chefes.md` R9/R9b, `save-e-perfil.md` R5/R5.1/R10/R11/R13 e `pactos-decisoes-a-confirmar.md`; código em `src/gameplay/game_session.gd` e `src/app/main.gd`).

## Decision Makers

`technical-director` (agente, lote "fechamento da arquitetura — Pactos", pedido do usuário em 2026-11-16). Aguarda revisão do usuário.

## Summary

Hoje a run é um `GameSession` monolítico com estado em `String` e o `Main` guarda catálogo, seleção e captura; não há dono para a composição, para o ciclo de vida dos objetos da run, para a conta de Fragmentos, para o resumo final nem para quando o perfil grava. Este ADR decide: `Main` fino como única raiz de composição, uma `SessaoDeJogo` injetada com quatro escopos de vida (perfil > sessão > run > câmara) onde **Nova run recria o escopo da run em vez de zerar campo a campo**, a máquina de estados da `Run` coordenada com o `EstadoDeJogo` do ADR-0001 só por `pedir_estado`, a sequência câmara → porta → recompensa → bênção → (encontro de pacto) → chefe, um `ResumoDaRun` imutável, a `ContaFragmentos` de escopo de sessão (fora do save) e contratos que aceitam dublês nulos.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (instalado 4.7.2) |
| **Domain** | Core |
| **Layer** | Feature |
| **Knowledge Risk** | LOW — quase tudo é GDScript puro (`RefCounted`); o único contato com a engine é o `Main` (`Node`) e o pedido de fechar a janela |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` (regra 4.7 de override com retorno tipado; `@abstract` desde 4.5) |
| **Post-Cutoff APIs Used** | Nenhuma obrigatória. Regra 4.7: os dublês (`ContaFragmentosNula` etc.) sobrescrevem métodos com retorno não-`void` e **devem** ter `return` explícito |
| **Verification Required** | (1) `get_tree().set_auto_accept_quit(false)` + `NOTIFICATION_WM_CLOSE_REQUEST` no `Main` em 4.7.2/Windows: a gravação de saída roda antes de `get_tree().quit()`; (2) nenhuma classe deste ADR é autoload (checar `project.godot`) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (estados e pedidos de estado), ADR-0002 (canal de eventos e catálogo), ADR-0003 (ids de entidade), ADR-0005 (seed e fluxos), ADR-0009 (`Portador` recriado na run), ADR-0010 (morte, `subjugar`, `ferir_acuada`), ADR-0012 (tela final, tela de escolha, estado Bênção para consentimento), ADR-0013 (`RepositorioDePerfil`, `perfil.cfg`, gravação fora de Jogo), ADR-0017 (`ModuloDeMaldicoes`, escrito em paralelo) |
| **Enables** | Épicos de Run e regiões, Portas e recompensas, Economia de Fragmentos, Vínculo e pactos (parte de ciclo), Chefes (desfecho), Telemetria (resumo) |
| **Blocks** | Toda história que cria/descarta a run, credita Fragmentos, monta o resumo ou grava o perfil |
| **Ordering Note** | Pode ser aceito depois do ADR-0001/0002/0013. O ADR-0017 só precisa existir para o escopo de run nomear o `ModuloDeMaldicoes`; o resto independe dele |

## Context

### Problem Statement

A revisão de 2026-11-15 deixou dois gaps sem ADR (TR-run-007, TR-economia-001) e ~15 parciais em Run, Câmaras, Portas, Bênçãos e Economia, todos com a mesma raiz: ninguém decide **quem cria o quê, quando morre e quem conversa com quem** ao longo da run. A Doutrina de Pactos (commit 6698079, decisões 12, 14, 15, 18, 19, 21) acrescenta a escolha da dupla, o encontro de pacto, o chefe com `Subjugado` e o perfil persistente, o que torna a pergunta urgente: sem dono, o reset da Nova run e o ponto de gravação viram regras espalhadas.

### Current State

- `src/gameplay/game_session.gd` (`RefCounted`): estado em `String` (`"menu"`, `"jogo"`), `data: Dictionary`, jogador/inimigos/projéteis como `Dictionary`, `kills`, `seed_value`, RNG próprio (`_rng_state`, `_imul`), `blessing_counts`, `start()` que zera campo a campo. Tudo de run, câmara e sessão no mesmo objeto.
- `src/app/main.gd` (`Node`): instancia catálogo, sessão, input, câmera, mundo e HUD como campos; guarda seleção de menu, contexto, captura e erro de dados. É raiz de composição de fato, mas sem regras.
- Não existe `ContaFragmentos`, resumo, perfil nem gravação.

### Constraints

- Nenhum singleton/autoload (coding standards: injeção de dependência).
- Lógica testável sem `SceneTree` (ADR-0001: orquestrador `RefCounted`).
- Nenhuma gravação dentro de um passo em `JOGO` (Save R5.1, ADR-0013).
- Determinismo: o consumo dos fluxos do RNG não pode depender de haver encontro, dublê ou perfil (Vínculo V6: fluxo `pactos` próprio, 4 reais fixos).
- MVP com uma região e um jogador, mas `player_id` já existe nos eventos (co-op pós-MVP).

### Requirements

- Estados da run R1-P e coordenação com o `EstadoDeJogo`.
- Reset total da Nova run (R8, R8-P) sem lista manual de campos a zerar.
- Saldo de Fragmentos atravessa runs e fica fora do save (decisão 21).
- Resumo montado uma vez e imutável (R7, R7-P).
- Sequência do Limiar com 7 câmaras, índice 5 comum, chefe no 6 (decisão 12).
- Encontro de pacto nos índices 1–2 só em Pactos (decisão 15) e portas que esperam `pacto_resolvido`.
- Gravação do perfil só fora de `JOGO`; sair no meio da run = abandono (decisão 18).
- Run e Portas funcionam com a Economia ausente (TR-economia-007).

## Decision

### 1. Raiz de composição: `Main` fino + `SessaoDeJogo`

- `Main` (`Node`, cena raiz) é o **único** lugar que: lê argumentos de linha de comando, cria os adaptadores de disco (`ArmazemDeArquivos`, ADR-0013), instancia nós de Apresentação e liga `_physics_process`/`_process` ao `OrquestradorDoPasso` (ADR-0001). Ele chama `ComposicaoDaSessao.montar(dependencias)` uma vez em `_ready()` e guarda a `SessaoDeJogo` devolvida.
- `ComposicaoDaSessao` (`RefCounted`, sem estado) é a **fábrica**: sabe montar o grafo inteiro a partir de um `DependenciasDaSessao` (catálogo carregado, armazém, provedor de entropia, relator de erros, flags de build). Testes montam a mesma composição com armazém em memória e `PerfilNulo` (Save R13).
- `SessaoDeJogo` (`RefCounted`) é a **dona dos escopos** e a fachada que o `Main` e a UI usam: `iniciar_escolha()`, `confirmar_arma(id)`, `confirmar_dupla(campo, reserva)`, `abandonar()`, `nova_run()`, `sair_do_jogo()`, `gravar_se_pendente(estado)`. Ela não contém regra de jogo; delega à `Run`.
- **Proibido**: autoload, `Engine.get_singleton` para estado de jogo, `get_node("/root/...")` em lógica, e qualquer módulo de gameplay criando outro módulo de gameplay. Só `ComposicaoDaSessao` e `FabricaDaRun` chamam `.new()` em módulos.

### 2. Escopos de vida

| Escopo | Dono | Vive | Contém | Zerado/recriado quando |
|---|---|---|---|---|
| **Perfil** (persistido) | `SessaoDeJogo` | processo; conteúdo no `user://perfil.cfg` | `PerfilVinculo` (conteúdo V30), `RepositorioDePerfil`, `GravadorDePerfil`, `PreferenciasDeArma` (última arma), opções/binds (ADR-0013) | só por Reset de perfil (Save R11: `vinculo.ler({})`), nunca pela run |
| **Sessão** (memória) | `SessaoDeJogo` | processo, nada em disco | `ContaFragmentos` (`saldo`), catálogo carregado, `OrquestradorDoPasso`, canal de eventos (ADR-0002), escritor de Telemetria (um `.jsonl` por sessão) | nunca; `saldo` zera ao fechar o jogo (Economia R7, decisão 21) |
| **Run** | `SessaoDeJogo.escopo_run` (`EscopoDaRun`) | de `confirmar_arma`/`confirmar_dupla` até `nova_run`/`sair_do_jogo` | `Run`, RNG da run (seed + fluxos, ADR-0005), `Portador` do jogador (ADR-0009), arma fixa, estado de Combate, Selo, Movimento, `RegistroDeBencaos`, `ModuloDeMaldicoes` (ADR-0017), `EncontroDaRun` + `pontos_run` (Vínculo), `Portas`, `Camaras`, `Chefes`, contadores de abates, `passos_em_jogo` inicial | **recriado inteiro** em `nova_run()`: o `EscopoDaRun` antigo é solto (referência descartada) e um novo é montado pela `FabricaDaRun` |
| **Câmara** | `Camaras` | de uma troca de câmara à seguinte | inimigos, projéteis, telégrafos, status, acuada, obstáculos, VFX de mundo, `t_vivo`/`t_apres` | nas seis ações da troca de câmara (ADR-0001, Combate R1, Transição) — `Camaras.trocar(i)` descarta o `ConteudoDaCamara` e monta outro |

Regras:
- **Recriar, não zerar.** Nenhum módulo de escopo de run tem método `reset()`. A "lista do que a Nova run zera" (R8, R8-P, Bênçãos R9, Economia R6, Maldições R14) é satisfeita por construção: tudo que está no `EscopoDaRun` morre com ele. A única operação explícita é `conta.nova_run()` (zera `coletados_run`), porque a conta é de sessão.
- Um objeto de escopo menor pode guardar referência a um de escopo maior (a `Run` conhece a `ContaFragmentos`), **nunca** o contrário. Quem é de sessão e precisa ouvir a run assina eventos no canal, que é de sessão, e não guarda referência ao `EscopoDaRun`.
- O canal de eventos é de sessão; o `EscopoDaRun` remove as suas assinaturas ao ser descartado (`EscopoDaRun.desligar()`, chamado pela `SessaoDeJogo` antes de soltá-lo).

### 3. Máquina de estados da run e coordenação com o orquestrador

`Run.Fase`: `SEM_RUN`, `ESCOLHA_DE_ARMA`, `ESCOLHA_DA_DUPLA`, `ATIVA`, `ENCERRADA` (+ `motivo`: `VITORIA`, `MORTE`, `ABANDONO`). A `Run` nunca escreve o `EstadoDeJogo`; ela chama `orquestrador.pedir_estado()` (ADR-0001 §6).

| Fase da Run | `EstadoDeJogo` possível | Quem pede a troca |
|---|---|---|
| `SEM_RUN`, `ESCOLHA_DE_ARMA`, `ESCOLHA_DA_DUPLA` | `MENU` | `SessaoDeJogo` (fora do passo) |
| `ATIVA` | `TRANSICAO` (entrada), `JOGO`, `PAUSA`, `BENCAO`, `MORTE` | ADR-0001 §6 (Câmaras, Portas, Bênçãos, Combate, Input) + **Vínculo** pede `BENCAO`/`JOGO` para a tela de consentimento e Pactuar/Exorcizar (decisão 19) |
| `ENCERRADA(VITORIA)` | `MENU` (tela final, sem Transição) | `Run`, no mesmo passo de `run_encerrada` |
| `ENCERRADA(MORTE)` | `MORTE` → `MENU` | Combate pede `MORTE`; a UI pede `MENU` quando o estado Morte termina (R5: a Run não soma atraso) |
| `ENCERRADA(ABANDONO)` | `PAUSA` → `MENU` | `SessaoDeJogo.abandonar()` (fora do passo) |

- `ESCOLHA_DE_ARMA → ESCOLHA_DA_DUPLA` só com Doutrina `pactos` **e** `vinculo.pedir_dupla()` pedir tela (≥ 2 pactuadas). Com 0 ou 1 pactuada o Vínculo responde `dupla_confirmada` na hora (V3: 0 → Vulto Mudo) e a Run segue direto. Esc na dupla volta a `ESCOLHA_DE_ARMA` sem seed.
- **Entrega da arma na composição (TR-armas-003, Armas R9, AC-AR-06).** A `FabricaDaRun` recebe o `WeaponDef` confirmado (vindo de `PortaDaEscolhaDeArma.escolher(i)` do ADR-0012) e, ao montar o `EscopoDaRun`, (1) cria o `Portador` do jogador com `vida_max` e `velocidade` **base** da arma como valores de base dos atributos (ADR-0009; nenhum modificador ainda) e (2) entrega ao Combate os dois `AttackDef` (`ataque`, `especial`) por construtor. Nenhum módulo lê o catálogo para descobrir a arma depois disso; a arma é fixa no escopo de run. Testes montam `WeaponDef` em memória.
- `→ ATIVA` (R2/R2-P, em ordem): cria seed → `FabricaDaRun` monta o `EscopoDaRun` (inclui a entrega da arma acima) → Vínculo planeja o encontro no fluxo `pactos` (só Pactos, V6/V21) → `Run` guarda `passos_em_jogo()` inicial → `Camaras.trocar(0)` com `primeira_recompensa` → `pedir_estado(TRANSICAO)`.
- **Abandono permitido** = `fase == ATIVA` **e** `estado ∈ {PAUSA vindo de JOGO}` **e** não `chefe_subjugado_pendente`. Em `BENCAO` (inclui consentimento e Pactuar/Exorcizar) e de `chefe_subjugado` até a vitória fica desabilitado (R6, R4-P passo 4). A UI pergunta `run.abandono_permitido()`.
- **Morte vence a limpeza por ordem do passo.** `jogador_morreu` sai no item 9 e a Run vai a `ENCERRADA(MORTE)` ao processá-lo; `camara_limpa` do item 10 do mesmo passo encontra a Run fora de `ATIVA` e é ignorada pela Run **e** pelas Portas (que consultam `run.ativa()` antes do passo 0 da R2). Sem flag extra.

### 4. Sequência do Limiar e contrato Câmara → Porta → Recompensa → Bênção → Chefe

`Run` guarda `regiao` e o índice `i` e é a fonte única da sequência: `proxima(i) -> TipoDeCamara` devolve o tipo de `i + 1` se `i + 1 < camaras_jogaveis`, senão `FIM_DA_RUN`. Limiar: `camaras_jogaveis = 7`, índices 0–6 = combate ×3, santuário (3), combate ×2, **chefe (6)**. **O índice 5 é câmara de combate comum** (decisão 12): recebe a recompensa da porta livre depois do 4 e abre a porta forçada `chefe`. Montar índice `≥ camaras_jogaveis` é o erro RN3.

As Câmaras são donas de `p`/`p_max` e derivam `p` do índice; a chave dos fluxos de estrutura é sempre `(regiao, i)` vinda da Run (TR-camaras-001). Fluxo por câmara:

1. **Entrada** (seis ações da Transição): `Camaras.trocar(i, recompensa_pendente)` monta layout → `vinculo.ao_montar_camara(i, montador)` (nasce a acuada se o encontro está `Planejado` em `i`; não consome RNG) → 1ª onda.
2. **Combate** em `JOGO`. Item 10: `camara_limpa(p, tipo)` (Câmaras são a única emissora; Chefes R9b.4).
3. **Portas R2-P** ao processar `camara_limpa`: (0) Run fora de `ATIVA` → nada; (1) santuário → passo 3; (1b) `run.proxima(i) == FIM_DA_RUN` (índice 6) → nenhuma recompensa, nenhuma porta, a Run trata a vitória; (2) concede a recompensa: Fragmentos → `conta.creditar(PORTA, n)`; cura → lê `vida_max` do `Portador`; bênção → `bencaos.pedir_oferta(regiao, i)`, Portas pedem `BENCAO` e esperam `tela_fechada`; (2b) `vinculo.encontro_aguardando()` → estado **Aguardando pacto** até `pacto_resolvido`; (3) abre `n` portas (R6-P: livres depois de 0, 1, 3, 4; `santuario` depois de 2; `chefe` depois de 5).
4. **Porta escolhida**: Câmaras emitem `porta_escolhida(k)` (interação só em passo vivo, logo ignorada em hitstop e Transição; TR-camaras-009) → Portas guardam o tipo como `recompensa_pendente` da câmara `i + 1`, emitem `EvPortaEscolhida(tipo, opcoes)` e entregam à Run → `run.avancar()` (`i += 1`) → Câmaras pedem `TRANSICAO`.
5. **Chefe (índice 6)**: fora de Pactos, Chefes R9 caminho `Morto` → `creditar(CHEFE, 6)` em `s + 37` → `camara_limpa(4, chefe)`. Em Pactos: Combate marca `Subjugado` em `s` (`subjugar`, ADR-0010), Chefes emitem `EvChefeSubjugado` em `s + 37` → Run liga `chefe_subjugado_pendente` → Interagir no chefe → Vínculo pede `BENCAO` e abre Pactuar/Exorcizar → escolha → Vínculo emite `chefe_escolhido(id, escolha)` (e `EvPactoFormado` com `origem = chefe` só no Pactuar) → Vínculo pede `JOGO` → **no 1º passo vivo seguinte**, Chefes executam R9b.3 (`resolver_subjugado` no Combate, que emite `EvChefeExorcizado` só no Exorcizar → crédito só no Exorcizar → `limpar_camara_chefe()`) e as Câmaras emitem `camara_limpa(4, chefe)` no item 10 desse passo.
6. **Vitória** (R4-P, Economia R4-P), na Run, ao processar `camara_limpa` com `i == camaras_jogaveis − 1`: lê `conta.coletados_run()` (já com os 6 do chefe) → `bonus = conta.creditar(VITORIA, fragmentos_vitoria)` (`efetivo`) → monta `ResumoDaRun` → `ENCERRADA(VITORIA)` → emite `EvRunEncerrada(motivo, resumo)` → pede `MENU`.

### 5. Encontro de pacto: contrato com Vínculo (lado da run)

A Run e as Portas só conhecem esta porta do Vínculo (o resto — sorteio F1, acuada, pontos, consentimento — é do Vínculo):

```gdscript
class_name PortaDoVinculoNaRun extends RefCounted
## Fachada de escopo de run do Vínculo e pactos. VinculoNulo implementa tudo como "sem Pactos".
func pedir_dupla(doutrina: StringName) -> void: pass            # responde com o evento dupla_confirmada(campo, reserva)
func planejar_encontro(doutrina: StringName, fluxo_pactos: FluxoAleatorio) -> void: pass  # sempre 4 reais em Pactos; nada fora
func ao_montar_camara(indice: int, montador: MontadorDeCamara) -> void: pass
func encontro_aguardando() -> bool: return false
func consolidar_run(motivo: StringName, venceu: bool) -> void: pass   # V20 / V20b
```

- Encontro só em Pactos, nos índices `indices_encontro = [1, 2]` (`VinculoTuning`), no máximo um por run; o 1º garantido no índice 1 com o Espreitador (decisão 15). A Run não sabe se há encontro.
- Falha da acuada (Vida ≤ 0): o Combate avisa o Vínculo antes do item 9 (contrato compartilhado; `EvEncontroFalhou`), a câmara segue normal e `encontro_aguardando()` passa a `false`.
- Consentimento: tela no **estado `BENCAO`** (decisão 19); a escolha chega como evento de UI fora do passo. "Oferecer"/Pactuar emitem `pacto_registrado(especie_id)`, que marca o perfil pendente; como o estado é `BENCAO`, a gravação ocorre no fim desse mesmo passo (§7). Depois sai `pacto_resolvido` e as Portas seguem ao passo 3.
- A dupla entra no `EscopoDaRun` pela `FabricaDaRun` (`ModuloDeMaldicoes`, ADR-0017); a Run guarda só os ids para o resumo.

### 6. `ContaFragmentos` (escopo de sessão, fora do save)

```gdscript
class_name LeituraDaConta extends RefCounted   # o que HUD, Telemetria e tela final recebem
func saldo() -> int: return 0
func coletados_run() -> int: return 0

class_name ContaFragmentos extends LeituraDaConta
func _init(rates: EconomyRates, eventos: CanalDeEventos) -> void
func creditar(origem: StringName, quantidade: int) -> int   # devolve o efetivo (teto saldo_max); emite saldo_mudou / saldo_no_teto
func gastar(quantidade: int) -> bool                        # existe e é testado; ninguém chama no MVP
func nova_run() -> void                                     # zera coletados_run; não toca saldo
func exportar() -> int                                      # não chamado no MVP (Save R12)
func importar(valor: Variant) -> void

class_name ContaFragmentosNula extends ContaFragmentos      # dublê: creditar devolve 0, nada emitido
```

- Criada uma vez pela `ComposicaoDaSessao`; injetada em `Portas`, `Chefes` e `Run` (escrita) e como `LeituraDaConta` em HUD/Telemetria (sem `creditar`/`gastar`; AC-EF-26).
- **Nunca** vai para `perfil.cfg` (decisão 21). Morte e abandono não tocam o saldo.

### 7. Quando o perfil grava

- `GravadorDePerfil` (perfil) assina `pacto_registrado`, `dupla_confirmada` (quando houve tela), `EvRunEncerrada` (emitido depois de a Run chamar `vinculo.consolidar_run` direto) e o reset de perfil; cada gatilho só faz `pendente = true` (Save R5, R5.3).
- `Main`, **depois** que `orquestrador.passo_fisico()` retorna (logo, depois do final comum e fora da lista de eventos), chama `sessao.gravar_se_pendente(orquestrador.estado())`, que grava se `pendente` e o estado ∉ {`JOGO`, `INICIANDO`}. `RepositorioDePerfil` compara o texto e não regrava se igual (R5.2).
- **Ordem no fim da run**: a Run chama `vinculo.consolidar_run()` **direto** (cadeia de controle, sem depender de ordem de registro, ADR-0002) → emite `EvRunEncerrada` → Gravador marca pendente → grava no fim desse passo, cujo estado já é `MORTE`/`MENU`.
- **Sair do jogo** (`NOTIFICATION_WM_CLOSE_REQUEST` com `set_auto_accept_quit(false)`, ou "Sair" no menu): `sessao.sair_do_jogo()` → se `fase == ATIVA`, `run.encerrar_por_saida()` = abandono completo (resumo, `EvRunEncerrada`, consolidação V20b, encontro `Aguardando` → `Abandonado`) → gravação **síncrona e imediata** (a única fora do ponto seguro, porque o processo vai acabar; o passo não está rodando) → fecha a Telemetria → `get_tree().quit()`. Falha ao gravar: a UI mostra o aviso do Save R10 em vez de fechar em silêncio.
- Queda do processo: vale o último arquivo (Save R10). A run nunca é salva no MVP.

### 8. `ResumoDaRun` imutável

Montado **uma vez** pela Run em `_encerrar(motivo)` e passado por referência em `EvRunEncerrada`; tela final, Telemetria e Vínculo só leem.

```gdscript
class_name ResumoDaRun extends RefCounted
## Imutável: todos os campos são fixados em _init e só têm getter. Arrays são cópias somente leitura.
func _init(motivo: StringName, seed_texto: String, arma: StringName, camaras_limpas: int,
		bencaos_tomadas: Array[StringName], fragmentos_coletados: int, bonus_vitoria: int,
		abates: int, duracao_passos: int, desfecho_chefe: StringName, dupla: Array[StringName]) -> void
func motivo() -> StringName                   # vitoria | morte | abandono
func seed_texto() -> String                   # RNG F9
func arma() -> StringName
func camaras_limpas() -> int                  # santuário e chefe contam; vitória = 7
func bencaos_tomadas() -> Array[StringName]   # devolve cópia (make_read_only)
func fragmentos_coletados() -> int
func bonus_vitoria() -> int                   # efetivo de creditar(VITORIA); 0 sem vitória
func total() -> int                           # coletados + bonus (F2), derivado e fixo
func abates() -> int
func duracao_s() -> float                     # F3 a partir de duracao_passos / 60
func desfecho_chefe() -> StringName           # abatido | exorcizado | pactuado | nenhum (R7-P)
func dupla() -> Array[StringName]             # [campo, reserva]; vazio fora de Pactos (R7-P)
```

São os **10 campos da R7** + os **2 da R7-P** (`desfecho_chefe`, `dupla`) = 12; `total` conta entre os 10 porque é campo do resumo, mas é calculado no `_init`. Não há setter, e os arrays recebidos são duplicados e marcados `make_read_only()`.

### 9. Contratos tolerantes a dublê (TR-economia-007)

Todo colaborador opcional da Run e das Portas tem uma variante **Nula** com o comportamento "ausente" e `return` explícito: `ContaFragmentosNula`, `VinculoNulo` (sem encontro, `pedir_dupla` responde dupla vazia), `ChefesNulo`, `BencaosNula` (`pedir_oferta` responde `sem_bencao`), `GravadorNulo`/`PerfilNulo` (Save R13). Regra: construtores **nunca** aceitam `null` silencioso — a `ComposicaoDaSessao` injeta a Nula; se um teste passar `null`, o `_init` troca pela Nula e avisa o relator uma vez. Nenhum `if x != null` dentro da regra.

### Architecture Diagram

```
Main (Node) ─ _ready: ComposicaoDaSessao.montar(deps) ─► SessaoDeJogo (RefCounted)
  │ _physics_process → orquestrador.passo_fisico() → sessao.gravar_se_pendente(estado)
  │ WM_CLOSE_REQUEST → sessao.sair_do_jogo()
  ▼
SessaoDeJogo
  ├─ PERFIL:  PerfilVinculo · RepositorioDePerfil · GravadorDePerfil · PreferenciasDeArma
  ├─ SESSÃO:  ContaFragmentos · Catálogo · OrquestradorDoPasso · CanalDeEventos · Telemetria
  └─ escopo_run: EscopoDaRun  (FabricaDaRun; recriado em nova_run)
        Run(fase, i, sequência) · RNG(seed, fluxos) · Portador · Combate · Selo · Movimento
        RegistroDeBencaos · ModuloDeMaldicoes · EncontroDaRun · Portas · Chefes
        └─ Camaras ─ ConteudoDaCamara (recriado na troca de câmara)

Câmara i:  TRANSICAO(trocar i; acuada?) → JOGO … item 10 camara_limpa
  → Portas: recompensa (BENCAO? tela_fechada) → Aguardando pacto? (BENCAO consentimento; pacto_resolvido)
  → portas → porta_escolhida → run.avancar → TRANSICAO → i+1
Câmara 6:  … Subjugado → BENCAO Pactuar/Exorcizar → JOGO → R9b → camara_limpa(4, chefe)
  → Run: coletados → creditar(VITORIA) → ResumoDaRun → EvRunEncerrada → MENU (tela final)
```

### Key Interfaces

```gdscript
class_name Run extends RefCounted
enum Fase { SEM_RUN, ESCOLHA_DE_ARMA, ESCOLHA_DA_DUPLA, ATIVA, ENCERRADA }
func fase() -> Fase
func ativa() -> bool
func doutrina() -> StringName                  # pedido por Chefes R12
func regiao() -> StringName
func indice() -> int
func proxima(i: int) -> StringName             # tipo de câmara ou &"fim_da_run"
func avancar() -> void                         # chamado pelas Portas após porta_escolhida
func abandono_permitido() -> bool
func encerrar_por_saida() -> void
func resumo() -> ResumoDaRun                   # null antes de ENCERRADA

class_name Bencaos extends RefCounted          # contrato síncrono (TR-bencaos-006)
func pedir_oferta(regiao: StringName, indice: int) -> StringName  # &"aberta" | &"sem_bencao" | &"oferta_ja_aberta"
func restantes() -> int
func tomadas() -> Array[StringName]
```

### Implementation Guidelines

- Must: toda criação de módulo passa por `ComposicaoDaSessao` (sessão/perfil) ou `FabricaDaRun` (run); módulos recebem dependências no `_init`.
- Must never: autoload, `get_node` absoluto em lógica, `SceneTree.paused`, `reset()` em módulo de escopo de run.
- Must: `nova_run()` = `escopo_run.desligar()` → soltar → `conta.nova_run()` → `Run.fase = ESCOLHA_DE_ARMA` → `pedir_estado(MENU)`. A seed nova só nasce em `→ ATIVA`.
- Must: a Run só troca o `EstadoDeJogo` por `pedir_estado`; nunca grava disco; nunca guarda números das Maldições.
- Must: gravação do perfil só em `gravar_se_pendente` (estado ≠ `JOGO`) ou em `sair_do_jogo()`.
- Must: `ResumoDaRun` sem setters; arrays com `make_read_only()`.
- Must: dublês Nulos com `return` explícito em todo override não-`void` (regra 4.7).
- Must: Portas consultam `run.ativa()` antes de conceder (morte vence a limpeza).

## Alternatives Considered

### Alternativa 1: Autoloads (`RunManager`, `Economia`) globais
- **Description**: singletons acessíveis de qualquer script.
- **Pros**: menos fiação; padrão comum em Godot.
- **Cons**: viola o padrão de injeção; testes exigem a árvore; o reset vira manual; dublês exigem trocar o autoload.
- **Estimated Effort**: menor no início, maior em testes.
- **Rejection Reason**: contraria coding standards, Economia R1 ("sem singleton") e AC-EF-01/15.

### Alternativa 2: Objetos de run longevos com `reset()`
- **Description**: criar tudo uma vez e chamar `reset()` em cada módulo na Nova run.
- **Pros**: sem realocação; referências estáveis.
- **Cons**: cada campo novo exige lembrar do `reset()`; vazamento de estado entre runs é exatamente o bug que o R8/R8-P tenta prevenir; o `game_session.gd` atual já mostra o padrão (`start()` zerando campo a campo).
- **Estimated Effort**: parecido.
- **Rejection Reason**: frágil; a recriação garante o reset por construção, e o custo de alocação de uma run é desprezível.

### Alternativa 3: Saldo de Fragmentos no perfil
- **Description**: gravar `saldo` em `perfil.cfg`.
- **Pros**: menos estranho para o jogador (risco registrado na decisão 21).
- **Cons**: contradiz a decisão 21 aprovada; abre migração de dado econômico antes da Oficina.
- **Rejection Reason**: decisão de design fechada. A porta `exportar/importar` já existe, então ligar depois é uma linha na composição.

## Consequences

### Positive
- Reset da Nova run correto por construção; testes de run montam um `EscopoDaRun` em memória.
- Um só lugar decide a gravação; o pacto nunca grava dentro de `JOGO`.
- Resumo único e imutável alimenta tela final, Telemetria e Vínculo sem divergência.
- Run e Portas testáveis com dublês nulos (Economia, Vínculo, Chefes, Bênçãos).

### Negative
- Mais classes pequenas (`SessaoDeJogo`, `ComposicaoDaSessao`, `FabricaDaRun`, `EscopoDaRun`, Nulas).
- A fiação de eventos tem ordem de assinatura relevante (Vínculo antes do Gravador), que fica implícita na composição; mitigado por teste de integração.
- A escolha Pactuar/Exorcizar só vira `camara_limpa` no 1º passo vivo depois de fechar a tela (1 passo de atraso, invisível).

### Neutral
- `GameSession` atual vira código de migração e desaparece.
- O `Main` continua dono da Apresentação; este ADR só tira dele as regras.

## Risks
- **Ordem de assinatura no canal** (Vínculo consolidar antes do Gravador marcar): teste de integração `run_encerrada → perfil gravado contém pontos_run`.
- **Gravação na saída em Windows**: verificar o pedido de fechar a janela em 4.7.2 (Verification Required 1); fallback = vale o último arquivo (Save R10).
- **Referências penduradas ao `EscopoDaRun` antigo** (ex.: Apresentação guardando o `Portador`): a Apresentação lê só pelo `LeituraDoHud` (ADR-0012), que a `SessaoDeJogo` religa em `nova_run`; teste que dispara `nova_run` e confere que nenhum evento antigo chega.
- **Atrito com ADR-0001**: a tabela de origens de pedido de estado não lista o Vínculo; emenda pedida (abaixo).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| run-e-regioes.md | TR-run-001 — R1/R1-P: estados da run coordenados com o orquestrador | §3: `Run.Fase` + tabela fase × `EstadoDeJogo`, só por `pedir_estado` |
| run-e-regioes.md | TR-run-004 — R4/R4-P: `camara_limpa` → `fim_da_run` → crédito → `run_encerrada`, tela final sem Transição | §4.6, ordem fixa na Run; pede `MENU` |
| run-e-regioes.md | TR-run-007 — R7/R7-P: resumo montado uma vez e imutável | §8: `ResumoDaRun` (10 + 2 campos) |
| run-e-regioes.md | TR-run-008 — R8/R8-P: reset total, seed e fluxos descartados, saldo fora | §2: `EscopoDaRun` recriado; RNG é de run; conta é de sessão |
| run-e-regioes.md | R3-P (decisão 12): índice 5 comum, chefe no 6, `camaras_jogaveis = 7` | §4: `proxima(i)` e sequência |
| camaras-e-ondas.md | TR-camaras-001 — chave do RNG é o índice, não `p` | §4: Run é fonte de `(regiao, i)`; Câmaras derivam `p` |
| camaras-e-ondas.md | TR-camaras-009 — porta ignorada em hitstop e Transição | §4.4: interação só em passo vivo; bloqueada em Aguardando pacto |
| portas-e-recompensas.md | TR-portas-004 — última câmara sem recompensa/porta; `fim_da_run` | §4.3 (1b) com R2-P: última = chefe |
| portas-e-recompensas.md | TR-portas-005 — `porta_escolhida` vira recompensa da próxima; tudo injetado | §4.4; Portas no `EscopoDaRun`, sem `SceneTree` |
| portas-e-recompensas.md | TR-portas-006 — Fragmentos na conta injetada; cura lê `vida_max` | §4.3 (2), §6 |
| portas-e-recompensas.md | TR-portas-008 — evento de porta escolhida com `tipo` e `opcoes` | §4.4: `EvPortaEscolhida` (catálogo no ADR-0002) |
| bencaos-tradicoes.md | TR-bencaos-002 — registro de tomadas zerado na Nova run | `RegistroDeBencaos` no escopo de run |
| armas-das-doutrinas.md | TR-armas-003 — R9: portador com `vida_max` e velocidade base, Combate com os dois `AttackDef` | §3: `FabricaDaRun` entrega a arma ao montar o `EscopoDaRun` |
| bencaos-tradicoes.md | TR-bencaos-006 — `pedir_oferta`, `sem_bencao`, `oferta_ja_aberta`, `restantes()` síncronos | Key Interfaces (`Bencaos`) |
| economia-de-fragmentos.md | TR-economia-001 — `ContaFragmentos` injetada, `saldo` atravessa runs | §6, escopo de sessão |
| economia-de-fragmentos.md | TR-economia-004 — lê `coletados_run` antes da vitória; usa `efetivo`; nada creditado com morte no mesmo passo | §4.6 e §3 (morte vence por ordem) |
| economia-de-fragmentos.md | TR-economia-006 — `nova_run()` zera `coletados_run`, mantém saldo | §6, Implementation Guidelines |
| economia-de-fragmentos.md | TR-economia-007 — Run e Portas aceitam Economia ausente | §9: `ContaFragmentosNula` |
| economia-de-fragmentos.md | R7 + decisão 21: saldo fora do save | §6, §7 |
| armas.md | TR-armas-005 — Escolhendo → Equipada → Encerrada; arma fixa | Escolha = `ESCOLHA_DE_ARMA`; arma injetada no `EscopoDaRun` e imutável; Encerrada = escopo descartado |
| vinculo-e-pactos.md | **TR-vinculo-002, TR-vinculo-004, TR-vinculo-009, TR-portas-009, TR-rng-013** — encontro sorteado ao criar a run (fluxo `pactos`, só Pactos, índices 1–2), acuada montada na câmara, portas esperam `pacto_resolvido` | §3 (→ ATIVA), §4.1, §4.3 (2b), §5 |
| vinculo-e-pactos.md | **TR-vinculo-008, TR-vinculo-011, TR-save-006, TR-save-007** — consentimento e Pactuar/Exorcizar no estado `BENCAO`; pacto grava no ponto seguro do mesmo passo (V9, decisão 19) | §5, §7 |
| vinculo-e-pactos.md / save-e-perfil.md | **TR-vinculo-012, TR-vinculo-013, TR-save-006, TR-save-007, TR-save-013** — consolidação em `run_encerrada` e na saída como abandono; gravação só fora de `JOGO` (V20, V20b, Save R5/R5.1/R10, decisão 18) | §7 |
| chefes.md | **TR-chefes-012, TR-chefes-013, TR-camaras-013, TR-run-013, TR-run-015** — `Subjugado` → escolha → R9b → `camara_limpa(4, chefe)` → vitória; abandono desabilitado em `Subjugado` | §3 (abandono), §4.5 |

## Performance Implications
- **CPU**: nenhum custo por passo; criação do `EscopoDaRun` é O(módulos) uma vez por run (< 1 ms esperado). `gravar_se_pendente` é um `bool` por passo.
- **Memória**: um `EscopoDaRun` vivo por vez; o antigo é liberado pela contagem de referências (`RefCounted`) — exige não haver ciclos (ver Validation).
- **Load Time**: nenhum; o catálogo já é carregado uma vez (ADR-0004).
- **Network**: n/a.

## Migration Plan
1. Criar `src/app/composicao_da_sessao.gd`, `src/gameplay/sessao_de_jogo.gd`, `src/gameplay/run/` (`run.gd`, `escopo_da_run.gd`, `fabrica_da_run.gd`, `resumo_da_run.gd`) e `src/gameplay/economia/conta_fragmentos.gd` (+ Nula), com testes em `tests/unit/run/` e `tests/unit/economia/`.
2. `main.gd`: trocar `var session = Session.new()` e `var catalog = Catalog.new()` por `ComposicaoDaSessao.montar(...)`; manter seleção de menu, captura e nós de Apresentação; mover a decisão de estado (`context`, `pending_pause`) para pedidos ao orquestrador.
3. `game_session.gd`: fatiar por escopo — `state: String` → `Run.Fase` + `EstadoDeJogo`; `seed_value`/`_rng_state`/`_imul` → RNG do ADR-0005; `blessing_counts` → `RegistroDeBencaos`; `kills`/`live_steps` → contadores da Run e `passos_em_jogo()`; `enemies`/`projectiles`/`effects` → `ConteudoDaCamara`; `start()` → `FabricaDaRun.montar()`. Cada fatia vira uma história; o arquivo some quando vazio.
4. Os testes atuais da fatia jogável continuam passando a cada fatia (paridade antes de remover).

**Rollback plan**: a `SessaoDeJogo` pode embrulhar o `GameSession` antigo como um único "módulo de run" até a migração acabar; voltar atrás é apontar a composição para ele.

## Validation Criteria
- Teste: `nova_run()` depois de uma run com bênçãos, abates, Maldições e encontro → novo `EscopoDaRun` sem nenhum estado antigo; `saldo` igual; `coletados_run == 0`; o `EscopoDaRun` antigo é liberado (`WeakRef` nulo).
- Teste: `jogador_morreu` e `camara_limpa` no mesmo passo → nenhum crédito, resumo com `motivo = morte`.
- Teste: vitória com chefe abatido/exorcizado/pactuado → ordem de eventos `saldo_mudou(chefe)?` → `camara_limpa` → `saldo_mudou(vitoria)` → `EvRunEncerrada`; `total` = 26/31/25 conforme F2-P.
- Teste: `ResumoDaRun` não tem setter; mutar o array devolvido não altera o resumo.
- Teste: Run e Portas montadas com `ContaFragmentosNula`, `VinculoNulo`, `ChefesNulo`, `BencaosNula` completam as 7 câmaras.
- Teste: `pacto_registrado` em `BENCAO` → arquivo gravado no fim do mesmo passo; nenhum gravação com estado `JOGO` (armazém em memória registra o estado de cada escrita).
- Teste: `sair_do_jogo()` com run de Pactos ativa → `EvRunEncerrada(abandono)`, consolidação V20b e gravação, nessa ordem.
- Grep no CI: `project.godot` sem `[autoload]` de gameplay.

## Decisões tomadas pelo agente (a revisar)
1. **Recriar o escopo da run** em vez de `reset()` por módulo.
2. **Resumo com 12 campos** (10 da R7 + `desfecho_chefe` e `dupla` da R7-P); o pedido citava 10 — o texto do TR-run-007 no registro deve ser atualizado para 12.
3. **Vínculo pede `BENCAO`/`JOGO`** para as telas de consentimento e Pactuar/Exorcizar — exige emenda na tabela de origens do ADR-0001 §6.
4. **Escolha do chefe aplicada no 1º passo vivo** após fechar a tela (Chefes R9b.3 roda no item 10 desse passo), não dentro do estado `BENCAO`.
5. **Gravação na saída é síncrona** e é a única fora do ponto seguro.
6. **Abandono permitido só em `PAUSA` vinda de `JOGO`** (nunca de `BENCAO`, nunca com `Subjugado` pendente).
7. **Construtor que recebe `null` troca pela Nula e avisa uma vez**, em vez de falhar.
8. TR-IDs da tabela GDD Requirements: ids oficiais do `tr-registry.yaml` (TR-vinculo-*, TR-chefes-*, TR-save-*, TR-portas-009, TR-rng-013, TR-camaras-013, TR-run-013 e 015); sem numeração provisória.

## Related
- ADR-0001 (pedido de emenda: Vínculo como origem de `BENCAO`/`JOGO`), ADR-0002 (catálogo: `EvRunEncerrada`, `EvPortaEscolhida`, `EvChefeSubjugado`, `EvChefeExorcizado`, `EvPactoFormado`, `EvEncontroFalhou`), ADR-0005, ADR-0009, ADR-0010, ADR-0012, ADR-0013, ADR-0017.
- GDDs: `design/gdd/run-e-regioes.md`, `camaras-e-ondas.md`, `portas-e-recompensas.md`, `economia-de-fragmentos.md`, `bencaos-tradicoes.md`, `vinculo-e-pactos.md`, `chefes.md`, `save-e-perfil.md`, `pactos-decisoes-a-confirmar.md`.
- Código a migrar: `src/app/main.gd`, `src/gameplay/game_session.gd`.

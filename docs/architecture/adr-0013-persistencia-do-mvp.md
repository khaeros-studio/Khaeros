# ADR-0013 — Persistência do MVP

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-15)

## Date

2026-11-15

## Last Verified

2026-11-17 (experimentos EX-0013 E-P1..P7 marcados como Verificados: sequência `.old` em `gravar_atomico` mantida, `p99 ≤ 1 ms/linha` com nota de picos isolados do SO para `TL2`, exigência de `schema_version` após `parse == OK`, concatenação de `"Z"` em `get_datetime_string_from_system(true)`, `OS.shell_open` e `NOTIFICATION_WM_CLOSE_REQUEST`). Antes: 2026-11-16 (emenda Pactos e pendências: `perfil.cfg` no MVP, contra `save-e-perfil.md` inteiro por seções, `vinculo-e-pactos.md` V30–V33 e `pactos-decisoes-a-confirmar.md` itens 18, 20, 21). 2026-11-15 — GDDs de Telemetria local (R1–R13, F3–F5, AC-TL-01..33), Input e controle (R8, AC-31/32), Armas das Doutrinas (R4 tela de escolha, AC-AR-39), Economia de Fragmentos (R7, AC-EF-20) e RNG com seed (Edge "save no meio da run", fronteira de máscara); ADR-0002 e ADR-0006 §6; `docs/engine-reference/godot/`.

## Decision Makers

Proposta da aba de Arquitetura (engine-programmer), autorizada a escrever em paralelo com os ADRs 0009–0014. Aceite pelo usuário pendente. Nenhuma regra de GDD é alterada; o que tocaria regra ou experiência está em "Decisões pendentes do usuário".

## Summary

Toda leitura e gravação em disco do MVP passa por um único adaptador injetado, `ArmazemDeArquivos`, cuja implementação real é a única a tocar `FileAccess`/`DirAccess`. Acima dele há lógica pura: três repositórios `ConfigFile` versionados (`opcoes.cfg`, `preferencias.cfg`, `input_binds.cfg`), com gravação atômica por temporário e substituição, e a Telemetria, que escreve um `.jsonl` por sessão por um `EscritorDeLinhas` mantido aberto. Não há save de run no MVP; Economia e RNG expõem `exportar`/`importar` sem arquivo. Os testes unitários usam um armazém em memória, sem I/O.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin local 4.7.2 |
| **Domain** | Core / I/O de arquivo |
| **Layer** | Foundation (adaptador e repositórios); a Telemetria continua na Apresentação |
| **Knowledge Risk** | MEDIUM: as APIs usadas são anteriores ao corte, mas a referência local só cobre o retorno `bool` de `store_*` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (linha `FileAccess.store_*` → `bool`, 4.4), `current-best-practices.md` (`@abstract`, retorno tipado em override 4.7) |
| **Post-Cutoff APIs Used** | `FileAccess.store_line`/`store_string` devolvem `bool` (4.4, **confirmado**); `@abstract` (4.5, **confirmado**); override com retorno tipado exige `return` explícito (4.7, **confirmado**) |
| **Verification Required** | Todos os itens **E-P1..E-P7 Verificados (EX-0013, 2026-11-16)** no Godot 4.7.2 (ver "Verificação de engine (2026-11-16)"): (E-P1) `store_line` + `flush` com `p99 ≤ 1 ms/linha` (`90 µs` para 300 B, `211 µs` para 2 KB; picos isolados do SO de 7–15 ms disparam `TL2` como ruído benigno), `flush` sobrevive a `OS.kill` (1000/1000 linhas), erro reportado em `bool` + `get_error()` / `get_open_error()`; (E-P2) `DirAccess.rename` no Windows apaga o destino antes de mover — sequência `.old` em `gravar_atomico` mantida como obrigatória e recuperação k=1..4 verificada; (E-P3) `ConfigFile.parse`/`encode_to_text` preservam int64, `StringName` e arrays, mas lixo binário retorna `OK` vazio — obrigatório exigir `schema_version` após `parse == OK` e descartar objeto inteiro em erro; (E-P4) `JSON.stringify` ordena chaves e preserva UTF-8/int64; (E-P5) `Time.get_datetime_string_from_system(true)` exige concatenar `"Z"`, `get_ticks_usec` monotônico (1 µs); (E-P6) `OS.shell_open(ProjectSettings.globalize_path(...))` confirmado com espaços no caminho; (E-P7) `auto_accept_quit = false` + `NOTIFICATION_WM_CLOSE_REQUEST` interceptam o fechamento da janela e permitem gravar / mostrar `PERFIL_SAIR_SEM_SALVAR` |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): composição no `Main`, sem Autoload, passo fixo; [ADR-0002](adr-0002-canal-de-eventos.md): Telemetria como `ConsumidorDeEventos`, primeira na entrega; [ADR-0004](adr-0004-catalogo-de-dados.md): `TelemetriaTuning` e impressão do catálogo; [ADR-0005](adr-0005-rng-deterministico.md): seed e máscara de 32 bits; [ADR-0006](adr-0006-input-por-passo.md) §6: formato dos binds e transação de remapeamento |
| **Enables** | ADR-0012 (itens de opções: telemetria, abrir pasta, apagar dados, falha de gravação; avisos `PERFIL_*` e reset do perfil); ADR-0015 (quando gravar o perfil, composição de `RepositorioDePerfil`); ADR-0017 (`ultima_dupla`); stories de Telemetria, de remapeamento e da tela de escolha de arma |
| **Blocks** | E-P1..E-P7 verificados no editor em 2026-11-16 (`EX-0013`); repetir no `.exe` de release quando os templates 4.7.2 forem instalados |
| **Ordering Note** | Pode ser implementado e testado com o armazém em memória antes dos ADRs 0009–0012; a validação de gravação real exige o experimento no Windows |

## Context

O MVP grava pouco, mas grava de quatro donos diferentes: a última arma (Armas R4, `user://preferencias.cfg` seção `[armas]`), os binds (Input R8, AC-31/32, com `.bak` byte a byte de arquivo corrompido), a opção e o arquivo de telemetria (Telemetria R2, R6, R8–R10) e, só como contrato, o saldo (Economia R7: em memória, `exportar`/`importar`) e o estado do RNG (só se houver save no meio da run, fatia vertical). As regras comuns são: nenhum módulo de regra toca disco, nenhum teste unitário faz I/O (Coding Standards; Telemetria R13; Armas "Preferências dublê"), falha de disco nunca derruba o jogo, e o build de playtest não lê nem grava `preferencias.cfg` (AC-AR-39). Duas incertezas de engine ficaram explicitamente para este ADR: descarga/anexação do `FileAccess` (Telemetria OQ 3, architecture.md Open Questions) e atomicidade da substituição no Windows (ADR-0006 §6). A fatia jogável em `src/` não grava nada em `user://`.

## Decision

### 1. Um adaptador de arquivo, lógica pura acima dele

`ArmazemDeArquivos` (`@abstract`, `RefCounted`) é a única fronteira com o disco. `ArmazemUserGodot` implementa-o sobre `FileAccess`/`DirAccess` com uma **raiz injetada** (`user://` em produção, `user://_testes/<caso>/` nos testes de integração); `ArmazemEmMemoria` é o dublê, com mapa de caminho → bytes, registro de leituras/gravações e falhas programáveis por operação e por ordem de chamada. Todo resto (repositórios, Telemetria, retenção, nomes de arquivo, contagem de bytes) é GDScript puro que recebe e devolve `String`/`PackedByteArray`. Nada é Autoload; o `Main` compõe e injeta (ADR-0001). Tudo roda na thread principal; nenhuma classe deste ADR é thread-safe, e isso fica documentado nelas.

### 2. Arquivos do MVP

| Arquivo | Dono do conteúdo | Escopo | Conteúdo |
|---|---|---|---|
| `user://opcoes.cfg` | Opções (ADR-0012 expõe a tela) | máquina | `[meta] schema_version`; `[telemetria] ligada` (padrão `true`), `aviso_visto`; `[ui] escala` (`float` ∈ {0,85; 1,0; 1,25; 1,5}, padrão 1,0; valor fora da lista = chave inválida, ADR-0012 §8); `[audio]` (emenda 2026-11-16, ADR-0016: `master`, `musica`, `efeitos`, `interface`, volumes lineares de 0 a 1 como `float` com padrão do ADR-0016; 0 deixa o barramento mudo; valor fora da faixa = chave inválida); seções futuras de acessibilidade. Lido e gravado por `RepositorioDeOpcoes` (mesma forma do `RepositorioDePreferencias`), injetado na UI pelo `Main` |
| `user://preferencias.cfg` | Armas | perfil 0 | `[meta] schema_version`; `[armas] ultima_arma` (caminho e chave do GDD de Armas) |
| `user://input_binds.cfg` | Input | perfil 0 | o formato do ADR-0006 §6, sem mudança |
| `user://perfil.cfg` (emenda 2026-11-16) | **Formato, versão e gravação: Save e perfil. Conteúdo de `[vinculo]`: Vínculo** | perfil 0, perfil único | `[meta] schema_version` (1), `gravado_por`; `[vinculo]` opaca (§7). Seções reservadas `[oficina]`, `[desbloqueios]`, `[rito]`, `[campus]`, `[economia]`, `[run]`: o MVP não as escreve |
| `user://telemetria/sessao-AAAAMMDD-HHMMSS[-N].jsonl` | Telemetria | máquina, só host | JSON Lines, Telemetria R2–R4 |

`telemetria_ligada` fica **fora** de `preferencias.cfg` de propósito: o build de playtest não pode ler esse arquivo (AC-AR-39, "zero leituras"), mas precisa saber se a telemetria foi desligada. Separar opções de máquina e escolhas lembradas também impede que um `preferencias.cfg` corrompido religue a telemetria de quem a desligou. Os caminhos saem de `CaminhosDePersistencia.de(perfil: int)`; o perfil 0 resolve para os caminhos acima, iguais aos dos GDDs.

### 3. Repositórios `ConfigFile` versionados

Cada repositório lê o texto pelo armazém e o interpreta em memória (`ConfigFile.parse(texto)`, sem `load()` de caminho), e grava com `encode_to_text()` mais `gravar_atomico` (`EX-0013 E-P3` confirmou que `encode_to_text()`/`parse()` preservam int64 > 2³¹, `StringName` e arrays aninhados). Como `ConfigFile.parse` devolve `OK` com 0 seções para lixo binário e deixa estado parcial após `ERR_PARSE_ERROR` (`E-P3`), **todo repositório exige a presença explícita de `[meta] schema_version` e da seção esperada após `parse == OK`**, e descarta o objeto `ConfigFile` inteiro em qualquer erro. Regras de carga, iguais às do ADR-0006 para os arquivos `.cfg`: arquivo ausente → padrões, sem aviso; versão maior que a suportada → padrões **em memória**, arquivo preservado e **nunca regravado** nessa sessão; texto que não interpreta, sem `schema_version` válido ou chave conhecida com tipo inválido → arquivo inteiro inválido, nenhum valor parcial, cópia byte a byte para `.bak` (ou `.bak2`, `.bak3` se já existir; nunca apaga backup), aviso uma vez por sessão (Input `INPUT_BINDS_CORROMPIDOS`; Armas o seu aviso de debug), e o próximo salvamento substitui; se a cópia falhar, não sobrescreve. Chave desconhecida é ignorada; chave ausente recebe o padrão. A migração de versão é função pura `migrar(v_de, dados) -> dados`, testada com fixtures.

### 4. Gravação atômica

`gravar_atomico(caminho, texto)` faz: (1) grava `caminho.tmp` inteiro, verifica o `bool` de `store_string`, fecha; (2) relê `caminho.tmp` e compara com o texto (para os `.cfg`, também reinterpreta); (3) substitui o destino usando **obrigatoriamente a sequência com `.old`**: `destino → destino.old`, `tmp → destino`, apagar `destino.old` (`EX-0013 E-P2` demonstrou que `DirAccess.rename(tmp, destino)` no Windows sobrescreve o destino, mas apaga o destino antes de mover a origem — se a origem estiver presa, o destino é perdido; por isso o `rename` único não é usado). A **recuperação na carga** é pura e cobre a queda em qualquer ponto (verificada nos 4 pontos `k=1..4` em `E-P2`): destino existe e é válido → usa e apaga sobras; destino ausente e `.old` presente → restaura `.old`; `.tmp` sozinho nunca é promovido (pode estar incompleto). Falha em qualquer passo devolve um `Error` diferente de `OK`, o arquivo anterior continua o vigente, o valor novo continua valendo **em memória** na sessão e o chamador decide o aviso (ver Decisões pendentes, item 1). Quem grava: Armas ao confirmar a arma; Input ao concluir a transação de remapeamento (ADR-0006: a transação valida a cópia do mapa, só depois o repositório grava; se a gravação falhar o mapa ativo já trocado continua em memória); Opções ao mudar um item. Nenhuma gravação de `.cfg` ocorre dentro de um passo em estado Jogo.

### 5. Telemetria: escritor de linhas aberto durante a sessão

A Telemetria é um `ConsumidorDeEventos` (ADR-0002) puro com a máquina de 6 estados do GDD; recebe `EscritorDeLinhas`, `ArmazemDeArquivos` (pasta, listagem, retenção, apagar), `RelogioDeSessao` (ms monotônico via `Time.get_ticks_msec()`, µs via `Time.get_ticks_usec()` para o orçamento F4, e data UTC via `Time.get_datetime_string_from_system(true) + "Z"` — `EX-0013 E-P5` confirmou que a função da engine não traz o sufixo `"Z"`), `RelatorDeAvisos` (TL1–TL3) e `TelemetriaTuning`. **Não há anexação a arquivo existente**: cada sessão (ou cada reabertura vinda de Armada) cria um arquivo novo, e o escritor fica aberto e escreve em sequência; isso elimina a dúvida sobre o modo de anexar. Antes de criar: garante a pasta, aplica a retenção F5 só sobre nomes que casam `sessao-\d{8}-\d{6}(-\d+)?\.jsonl`, e escolhe o nome livre (`-2`, `-3` se existir; a corrida entre duas instâncias no mesmo segundo é aceita como residual). Cada evento vira uma linha (`JSON.stringify` de um `Dictionary` montado pela Telemetria; `E-P4` confirmou que `JSON.stringify` ordena chaves alfabeticamente e preserva UTF-8/int64), o tamanho em bytes é contado em memória (`to_utf8_buffer().size() + 1`), a regra R9 é aplicada **antes** de escrever, depois `escrever_linha` (o `bool` de `store_line`) e `descarregar` (`flush`, seguido de `get_error()`, confirmado em `E-P1`; falha na abertura é lida em `FileAccess.get_open_error()`). Qualquer `false` ou erro: um `TL1`, estado Parada por falha, escritor fechado, sem nova tentativa. O custo de cada linha e o total do passo são medidos com o relógio injetado (`p99 ≤ 1 ms/linha` confirmado em `E-P1`: `90 µs` para 300 B e `211 µs` para 2 KB; picos isolados de escalonamento/disco do SO de 7–15 ms podem ultrapassar `3 ms/passo` e disparam apenas o aviso benigno `TL2`, sem constituir falha). "Apagar dados" e retenção nunca tocam o arquivo aberto; "Abrir pasta" chama `abrir_pasta_no_sistema()` do armazém real (`OS.shell_open` sobre `ProjectSettings.globalize_path`, verificado em `E-P6`) e o caminho absoluto **nunca** é escrito em linha (R7). `duracao_s` é arredondada pela Telemetria antes de entrar no dicionário (F1, `casas_decimais_duracao`).

### 6. Sem save de run; `exportar`/`importar` sem arquivo

O MVP não persiste saldo, run nem RNG. `ContaFragmentos.exportar() -> int` e `importar(v) -> bool` existem e são testados (Economia R7), mas a composição do MVP **não os liga a arquivo** (AC-EF-20: conta recriada = saldo 0). O RNG não exporta estado no MVP. **Emenda 2026-11-16:** o `user://perfil.cfg` deixou de ser só da fatia vertical e existe no MVP (§7), mas **só com a seção `[vinculo]`**: o saldo de Fragmentos continua fora do save (Economia R7, decisão 21 de Pactos: "estranho para o jogador", aceito) e o RNG não grava estado. As portas `exportar_texto()`/`importar_texto()` do perfil existem e são testadas (save-e-perfil R12), **sem tela de exportar/importar no MVP** (um perfil só, decisão 20). Para a fatia vertical fica reservado: as seções dos demais donos chamando `exportar`/`importar`; a seed e os estados dos fluxos gravados como inteiros e **mascarados com `& 0xFFFFFFFF` na leitura** (RNG, fronteira de máscara); e a migração única de `preferencias.cfg` (Armas R4).

### 7. Perfil do MVP (`user://perfil.cfg`; emenda 2026-11-16)

Dono do **formato, do momento de gravar, da versão e do reset**: o Save (`save-e-perfil.md`). Dono do **conteúdo** de `[vinculo]`: o Vínculo. O `RepositorioDePerfil` tem a mesma forma dos demais (`carregar()` nunca falha; `salvar() -> Error`), lê pelo armazém e grava por `gravar_atomico` (§4).

- **Seção opaca.** O repositório não conhece os campos do Vínculo: chama `escrever() -> Dictionary` e `ler(dados)` de uma `PortaDeSecao` (`@abstract`, `ler`, `escrever`, `campos_de_ids`, `migrar_conteudo`). Valores permitidos: `bool`, `int`, `String`, `Array`/`Dictionary` desses; **sem `float`, `StringName`, `Object` nem `Resource`**, para o texto ser idêntico byte a byte entre gravações iguais. Única exigência estrutural: o estado por espécie vem no dicionário `especies`, com chave igual ao id de `CurseDef`.
- **Validar o conteúdo** (faixas, `nivel`, pontos) e o aviso VP-S1 são do **dono da seção** (Vínculo), dentro de `ler()`. O repositório valida só `[meta]`, a existência e o tipo de `especies` e os tipos permitidos.
- **Carga** uma vez por sessão, depois de o catálogo (ADR-0004) estar Pronto: ler → recuperação de sobras (§4) → interpretar → versão → validar → migrar → filtrar ids → `ler()`. **Catálogo em Falhou → modo Sem gravação** (AC-SP-21): o jogo roda sem pactos e o arquivo nunca é tocado.
- **Chaves e seções desconhecidas são preservadas** na escrita (estende "ignorada" do §3): ignoradas na leitura, mantidas como texto e regravadas iguais. Entradas de `especies` com id fora do catálogo ficam órfãs, voltam ao arquivo e reaparecem quando um build com a espécie as lê. Id desconhecido em `campos_de_ids()` (`ultima_dupla`, `encontro_pendente`) vira `""` antes de `ler()`.
- **Só grava se o texto mudou** (R5.2): o repositório compara o texto novo com o último gravado com sucesso; igual conta como sucesso sem tocar o disco.
- **Gravação só fora de Jogo** (R5.1, R5.3): os gatilhos (`pacto_registrado`, `run_encerrada`, `dupla_confirmada` (quando houve tela, igual ao ADR-0015), sair, reset) só marcam o perfil como **pendente**; o `Main` grava no fim de um passo em Pausa, Bênção (inclui a tela de consentimento do pacto), Menus, Morte ou Transição, nunca no meio da lista de eventos. Vários gatilhos viram **uma** gravação com o estado mais recente (coalescência). A regra "nenhuma gravação de `.cfg` em Jogo" do §4 vale para o perfil.
- **Sair no meio da run = abandono.** A run não é salva. Ao sair pelo menu ou pelo fechamento da janela (`get_tree().set_auto_accept_quit(false)` + `NOTIFICATION_WM_CLOSE_REQUEST` no `Main`, **Verificado em EX-0013 E-P7**), o Save pede `escrever()` e grava; o Vínculo consolida a run como derrota/abandono. **Pacto feito em run perdida continua valendo** (decisão 18): grava no ponto seguro da própria tela. Queda do processo vale o último arquivo gravado. A falha na saída mostra `PERFIL_SAIR_SEM_SALVAR` ("Tentar de novo" / "Sair sem salvar"), uma tentativa por clique.
- **Corrompido:** arquivo ilegível ou `[meta]`/`especies` com tipo errado → cópia byte a byte para `perfil.cfg.bak` (ou `.bak2`, `.bak3`; nunca apaga backup), `ler({})` e aviso `PERFIL_CORROMPIDO` uma vez. Cópia falhou → modo **Sem gravação**. **Versão futura** (`schema_version` > suportada) → `ler({})`, arquivo preservado, **Sem gravação** e `PERFIL_VERSAO_FUTURA`. Arquivo ausente → padrões, sem aviso.
- **Reset** (só no menu principal, fora de run, duas confirmações): copia para `perfil.cfg.reset.bak` (ou `.reset.bak2`…), chama `ler({})` e grava perfil novo (órfãs e seções desconhecidas também caem). Cópia falhou → reset cancelado. Indisponível em Sem gravação. Não toca `opcoes.cfg`, `preferencias.cfg`, `input_binds.cfg` nem a telemetria.
- **Exportar/importar:** só as portas de texto (`exportar_texto()`, `importar_texto(texto) -> Error`, mesma validação da carga), para teste e fatia vertical; **sem tela no MVP**. Fragmentos e RNG não entram.
- **`PerfilNulo`** (dublê: não lê, não grava) é injetável em testes e debug. O **build de playtest lê e grava o perfil** normalmente (diferente de `preferencias.cfg`, AC-AR-39).

### 8. Opções de acessibilidade: dono e seção (TR-feedback-012, TR-tela-bencao-010; 2026-11-16)

Todas ficam em `user://opcoes.cfg` (por máquina), lidas e gravadas só pelo `RepositorioDeOpcoes`; cada dono recebe o valor por injeção e nunca lê arquivo. O Feedback **não aplica** nenhuma opção (Feedback R7): pede aos donos, e nenhuma resposta as contorna. Nomes de chave provisórios até o GDD de Acessibilidade e opções.

| Opção (Art Bible §7.9) | Dono que aplica | Seção / chave |
|---|---|---|
| nº 3 Tremor de câmera 0–100% | Cena (ADR-0007, F5) | `[acessibilidade] tremor_camera` |
| nº 4 Reduzir flashes | Pipeline (ADR-0011, limitador F6); Tela de bênção (ADR-0012) | `[acessibilidade] reduzir_flashes` |
| nº 5 Redução de movimento | Cena (zoom); Pipeline/pool de números (ADR-0011, fade); UI (ADR-0012, fade ≤ 300 ms, corte seco do foco) | `[acessibilidade] reduzir_movimento` |
| nº 7 Números de dano (ligado/reduzido/desligado) | Pool de números (ADR-0011 §8) | `[acessibilidade] numeros_dano` |
| nº 10 Alto contraste | UI (ADR-0012: HUD e Tela de bênção) | `[ui] alto_contraste` |
| Intensidade do telégrafo (contorno 6 px) | Pipeline (ADR-0011 §8, `tel_sdf`) | `[acessibilidade] telegrafo_alto` |
| Encurtar o hitstop | Orquestrador (ADR-0001), multiplicador separado | `[acessibilidade] hitstop_mult` (GDD de Acessibilidade, OQ 3) |
| Escala, número de Vida, Vida colorida, vinheta | HUD (ADR-0012); vinheta desenhada pelo Pipeline | `[ui] escala`, `numero_vida`, `vida_colorida`, `vinheta` |
| Volumes | Áudio (ADR-0016) | `[audio]` |

### Key Interfaces

```gdscript
# armazem_de_arquivos.gd — única fronteira com o disco; não é thread-safe (só thread principal).
# Ex.: var a := ArmazemEmMemoria.new(); a.programar_falha(&"gravar_atomico", 1)
@abstract
class_name ArmazemDeArquivos extends RefCounted
@abstract func ler_texto(caminho: String) -> LeituraDeArquivo     # .ok, .existe, .texto, .bytes
@abstract func gravar_atomico(caminho: String, texto: String) -> Error
@abstract func copiar_bytes(origem: String, destino: String) -> Error   # .bak byte a byte
@abstract func existe(caminho: String) -> bool
@abstract func listar_arquivos(pasta: String) -> PackedStringArray     # só nomes, ordem indefinida
@abstract func apagar(caminho: String) -> Error
@abstract func garantir_pasta(pasta: String) -> Error
@abstract func criar_escritor_de_linhas(caminho: String) -> EscritorDeLinhas  # null se não abrir

@abstract
class_name EscritorDeLinhas extends RefCounted
@abstract func escrever_linha(texto: String) -> bool   # FileAccess.store_line (bool desde 4.4)
@abstract func descarregar() -> bool                   # flush + checagem de erro (E-P1)
@abstract func fechar() -> void

# Repositório versionado (um por arquivo .cfg); lógica pura sobre o armazém.
# Ex.: var r := RepositorioDePreferencias.new(armazem, CaminhosDePersistencia.de(0), avisos)
#      var p := r.carregar(); p.ultima_arma = &"lamina"; var err := r.salvar(p)
class_name RepositorioDePreferencias extends RefCounted
func carregar() -> PreferenciasDoPerfil   # nunca falha: padrões em qualquer erro
func salvar(p: PreferenciasDoPerfil) -> Error   # ERR_UNAVAILABLE se versão futura (não regrava)
# Mesma forma (revisão cruzada 2026-11-15): RepositorioDeOpcoes (opcoes.cfg: telemetria_ligada, aviso_visto,
# escala_ui → ADR-0012) e RepositorioDeBinds (input_binds.cfg: só lê/grava texto; formato, validação e
# transação ficam no Input, ADR-0006 §6).

# Perfil (emenda 2026-11-16). Ex.: var r := RepositorioDePerfil.new(armazem, CaminhosDePersistencia.de(0), avisos, catalogo, vinculo)
class_name RepositorioDePerfil extends RefCounted
func carregar() -> ModoDoPerfil                    # nunca falha; NORMAL ou SEM_GRAVACAO
func marcar_pendente() -> void                     # gatilho; nunca grava
func gravar_se_pendente() -> Error                 # só o Main, em passo fora de Jogo; OK sem tocar o disco se o texto não mudou
func exportar_texto() -> String
func importar_texto(texto: String) -> Error        # mesma validação da carga

@abstract
class_name PortaDeSecao extends RefCounted         # implementada pelo Vínculo; o repositório não conhece os campos
@abstract func escrever() -> Dictionary
@abstract func ler(dados: Dictionary) -> void
@abstract func campos_de_ids() -> PackedStringArray

# Porta que Armas recebe; no build de playtest a composição injeta PreferenciasDeArmaNulas
# (não lê, não grava), o que satisfaz AC-AR-39 sem flag dentro do módulo de Armas.
@abstract
class_name PreferenciasDeArma extends RefCounted
@abstract func ultima_arma() -> StringName       # &"" se não há
@abstract func lembrar_arma(id: StringName) -> void
```

### Implementation Guidelines

- MUST passar todo acesso a disco por `ArmazemDeArquivos`; `FileAccess`/`DirAccess`/`ConfigFile.load/save` só em `ArmazemUserGodot`.
- MUST verificar todo `bool`/`Error` devolvido e transformar falha em estado explícito (Parada por falha, valor só em memória), nunca em exceção nem laço de nova tentativa.
- MUST gravar `.cfg` só por `gravar_atomico` e preservar arquivo inválido em `.bak` antes de substituí-lo.
- MUST contar bytes da telemetria em memória e aplicar R9 antes de escrever.
- MUST testar unidades com `ArmazemEmMemoria` e relógio falso; testes `[I]` usam o armazém real numa raiz temporária e limpam ao fim.
- MUST NEVER ler o `.jsonl` no jogo (AC-TL-30), escrever caminho absoluto, nome de usuário ou hora local nele, ou criar telemetria num cliente co-op.
- MUST NEVER usar Autoload, `ProjectSettings` ou `OS` fora do armazém real e do `Main`.
- MUST NEVER gravar `.cfg` durante um passo em estado Jogo.

## Alternatives Considered

| Alternativa | Benefício | Motivo de rejeição |
|---|---|---|
| Cada dono chama `FileAccess`/`ConfigFile.save` direto | Menos classes | Espalha I/O em módulos de regra, impede teste sem disco e duplica a lógica de `.bak` e atomicidade |
| Um único `config.cfg` para tudo | Um arquivo | Viola AC-AR-39 (playtest leria o arquivo para saber da telemetria) e um arquivo corrompido apagaria binds e opções juntos |
| `ConfigFile.save(caminho)` direto | Uma chamada | Não é atômico: queda no meio deixa arquivo truncado; perde a releitura de verificação |
| Telemetria reabrindo o arquivo em modo de anexar a cada linha | Sem handle aberto | Custa abrir/fechar por linha e depende do modo de anexar, que a referência não cobre |
| Telemetria em fila e thread de gravação | Tira o custo do passo | O GDD decide gravação síncrona e descarga por linha (R2, F4); thread exigiria sincronização para 3 linhas no pior passo |
| Persistir o saldo já no MVP | Progresso entre sessões | Contradiz Economia R7 e AC-EF-20 |

## Consequences

Positivas: toda regra de persistência e de telemetria é testável em memória, incluindo falhas no N-ésimo acesso; o formato dos binds do ADR-0006 é mantido; o build de playtest fica correto por composição, não por `if` espalhado; a fatia vertical recebe o Save e perfil já com a porta pronta. Negativas: mais uma camada de indireção e três arquivos de configuração em vez de um; a atomicidade real depende de E-P2 e, no pior caso, da sequência de três renomeações com recuperação na carga; a Telemetria mantém um handle aberto durante a sessão.

## Risks

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| `flush()` só esvazia o buffer do processo, sem `fsync` | Média | Baixo | R10 já tolera perder a última linha; E-P1 mede matando o processo |
| `flush()` custa mais que 1 ms por linha no Windows | Baixa | Médio | Medido em E-P1; acima disso só `TL2` (F4); pendência de design se for sistemático |
| `rename` não é atômico no Windows (verificado 2026-11-16: substitui o destino, mas apaga-o antes de mover) | Alta | Médio | Sequência com `.old` e recuperação pura na carga (mantidas) |
| Antivírus ou indexador segura o `.tmp` por instantes | Baixa | Baixo | Falha vira `Error`, valor fica em memória, próxima gravação tenta de novo |
| `ConfigFile.parse`/`encode_to_text` divergem do esperado | Baixa | Baixo | Serializador INI próprio atrás da mesma interface |

## GDD Requirements Addressed

| GDD | Requisito | Como |
|---|---|---|
| telemetria-local.md | R1, R13; AC-TL-14, 30 | Consumidor só leitura; escritor, armazém e relógio injetados; jogo nunca lê |
| telemetria-local.md | R2, R3, R10; AC-TL-01..03, 22, 23 | Arquivo novo por sessão, handle aberto, `store_line` + descarga por linha, sufixo `-N` |
| telemetria-local.md | R6, R7; AC-TL-15..17, 26 | `opcoes.cfg [telemetria]`, estados Armada/Desligada, apagar só `sessao-*.jsonl`, sem caminho absoluto |
| telemetria-local.md | R8, F4; AC-TL-18, 19, 25, 31 | `bool`/erro checado, um `TL1`, Parada por falha; custo medido por relógio injetado (`TL2`) |
| telemetria-local.md | R9, F3, F5; AC-TL-20, 21, 32 | Bytes contados em memória antes de escrever; retenção por regex do nome; falha ao apagar ignorada |
| input-e-controle.md | R8 (persistência); AC-31, 32 | `input_binds.cfg` do ADR-0006, versionado, atômico, `.bak` byte a byte |
| armas-das-doutrinas.md | R4 (última arma, build de playtest); AC-AR-39 | `preferencias.cfg [armas] ultima_arma`, gravado ao confirmar; porta nula no playtest |
| save-e-perfil.md | R1–R4, R6, R7 (perfil único, `perfil.cfg`, seção opaca, carga, versão, gravação atômica) (TR-save-001, TR-save-002, TR-save-003, TR-save-004, TR-save-009, TR-save-010) | §7 e §2: `RepositorioDePerfil`, `PortaDeSecao`, `gravar_atomico` |
| save-e-perfil.md | R5, R5.1–R5.3 (gatilhos, ponto seguro, só se mudou, coalescência) (TR-save-006, TR-save-007, TR-save-008) | `marcar_pendente()` + `gravar_se_pendente()` no fim de passo fora de Jogo |
| save-e-perfil.md | R8, R9, AC-SP-21 (ausente, corrompido, versão futura, ids desconhecidos, catálogo em Falhou) (TR-save-005, TR-save-011, TR-save-012) | `.bak`/`.bakN`, Sem gravação, preservação de chaves e órfãs |
| save-e-perfil.md | R10, R11, R12, R13 (sair = abandono, reset, portas de texto, `PerfilNulo`) (TR-save-013, TR-save-014, TR-save-015, TR-save-016, TR-save-017) | §7; saída depende de E-P7 |
| vinculo-e-pactos.md | V30–V33, V45; pactos-decisoes 18, 20, 21 | Vínculo é dono do conteúdo e valida faixas (VP-S1); pacto em run perdida persiste; sem Fragmentos no save (TR-vinculo-001, TR-vinculo-012, TR-vinculo-015, TR-vinculo-016, TR-vinculo-018) |
| economia-de-fragmentos.md | R7; AC-EF-20 | `exportar`/`importar` sem arquivo no MVP |
| rng-com-seed.md | Edge "save no meio da run", máscara na fronteira | Sem persistência no MVP; formato futuro mascarado na leitura |
| feedback-de-combate.md / tela-de-bencao-e-carta.md | Feedback R7, Tela R14 (TR-feedback-012, TR-tela-bencao-010) | §8: tabela opção → dono → seção de `opcoes.cfg`; donos recebem o valor injetado |

## Performance Implications

Fora do passo: carga dos três `.cfg` na inicialização (alguns KB, uma vez) e gravação só por ação do jogador em menu. No passo: só a Telemetria, até 3 linhas no passo da morte (F4: ≤ 1 ms por linha, ≤ 3 ms por passo, orçamento do GDD a confirmar em E-P1). Memória: um handle aberto e um `Dictionary` temporário por linha; nenhum evento por golpe, então a alocação por linha não está em caminho quente. A contagem de bytes evita consultar o tamanho do arquivo a cada linha.

## Migration Plan

A fatia em `src/` não tem persistência, então não há dado a migrar. Passos: (1) executar E-P1..E-P6 em `prototypes/persistencia-verificacao/` (descartável); (2) criar `src/foundation/persistencia/` com o armazém (abstrato, real, em memória), `CaminhosDePersistencia`, os três repositórios e as portas; testes em `tests/unit/persistencia/` e `tests/integration/persistencia/`; (3) Telemetria em `src/presentation/telemetria/` como consumidor, ligada no `Main` antes do HUD; (4) Armas e Input recebem as portas quando seus módulos de produção substituírem `game_session.gd`/`game_input.gd`; (5) ADR-0012 liga a tela de opções às operações deste ADR.

## Validation Criteria

Experimentos no Godot 4.7.2, Windows 11, build exportado e editor: **E-P1** `store_line` + `flush` em 10 000 linhas de 300 B e 2 KB: média e p99 por linha; matar o processo no meio e conferir que só a última linha pode estar truncada; forçar falha (arquivo somente leitura, pasta removida) e registrar onde o erro aparece (`bool`, `get_error()`). **E-P2** `DirAccess.rename` sobre destino existente, com destino aberto por outro processo, e queda simulada em cada passo da sequência com `.old`. **E-P3** ida e volta `ConfigFile.parse`/`encode_to_text` com `int` acima de 2³¹, `StringName`, `Array` e lixo binário. **E-P4** saída de `JSON.stringify` para `int`, `float` arredondado, `null` e texto com acentos (UTF-8 válido). **E-P5** `Time` em UTC terminando em `Z` e relógio monotônico em ms/µs. **E-P6** `OS.shell_open` da pasta globalizada. **E-P7** (emenda 2026-11-16) interceptar o pedido de fechar a janela no Windows (build exportado): gravar o perfil antes de sair, mostrar `PERFIL_SAIR_SEM_SALVAR` e permitir "Tentar de novo"; conferir o caminho de "Sair" do menu e o de fechar a janela. Emenda 2026-11-16: o E-P1 também mede o **pior passo com 5 linhas** (F4-P, schema 2) contra os 3 ms. Depois: todos os AC-TL `[L]` com armazém em memória; AC-31/32 do Input e AC-TL-28 como `[I]` com armazém real em raiz temporária; AC-AR-39 com a porta nula; AC-EF-20.

## Emenda Pactos e pendências (2026-11-16)

- **Mudança no corpo:** §2 ganha `perfil.cfg`; §6 deixa de reservá-lo só para a fatia vertical; novo §7. O MVP continua sem save de run, sem Fragmentos e sem estado de RNG no disco.
- **Decisão registrada (TR-economia-009):** o saldo de Fragmentos **fica fora do save no MVP** (OQ 6 da Economia, decidida pelo usuário, `pactos-decisoes-a-confirmar.md` item 21; "estranho para o jogador", aceito). `ContaFragmentos.exportar/importar` seguem sem arquivo (AC-EF-20).
- **`[audio]` em `opcoes.cfg`** (volumes Master, Música, Efeitos, Interface), pelo `RepositorioDeOpcoes`, conforme o ADR-0016.
- **Telemetria schema 2** (TR-telemetria-011, TR-telemetria-012; `telemetria-local.md` R4-P): o `schema` da linha 0 passa a 2; novos `encontro_pacto`, `pacto`, `vinculo_fim_run`; `run_iniciada` com `dupla` e `pactos`; resumo de `run_encerrada` com 12 campos. O pior passo passa a ter **5 linhas** (F4-P) contra o orçamento de 3 ms por passo: entra como critério de validação (E-P1 mede 5 linhas no mesmo passo; acima do orçamento só gera `TL2`, e o ajuste de orçamento é do design).
- **Escopo:** um perfil só (`CaminhosDePersistencia.de(0)`); sem tela de exportar/importar (as portas de texto ficam, sem tela). Nada é retirado do ADR que o previa: `exportar`/`importar` de Economia e RNG seguem sem arquivo.
- **Decisões minhas, para revisão:** (1) `ModoDoPerfil` com dois valores (`NORMAL`, `SEM_GRAVACAO`); (2) nome e assinatura de `PortaDeSecao`, `marcar_pendente()` e `gravar_se_pendente()`; (3) o catálogo em Falhou entra como causa de Sem gravação, conforme AC-SP-21; (4) o Save compara o texto a gravar em memória, sem reler o arquivo.
- **Pendências:** E-P7 (fechar janela); TR-save-001 a 018 já constam do `tr-registry.yaml` (ids oficiais citados na tabela acima); migrações de conteúdo do Vínculo registradas na cadeia do Save; ADR-0015 define o ponto de chamada de `gravar_se_pendente()`.

## Nota de preparação para co-op

`CaminhosDePersistencia.de(perfil)` já recebe o perfil: no co-op online cada jogador roda na própria máquina com o perfil 0, e um eventual segundo jogador local usaria `user://perfis/<n>/` para binds e preferências, sem mudar os repositórios. `opcoes.cfg` é por máquina. A Telemetria só é composta no papel solo ou host (o cliente apresenta e não grava); eventos de jogador ganham `player_id` e o `schema` sobe para 2 quando isso entrar. Nenhum código de rede aqui.

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Aviso de falha ao salvar binds/preferências/opções.** O ADR-0006 deixou a mensagem da UI em aberto. Opções: (a) aviso discreto uma vez por sessão com chave nova (ex.: `PERSIST_FALHA_GRAVAR`) e o valor valendo só nesta sessão; (b) silêncio com log. **Recomendação: (a)**, porque fingir que salvou contraria o ADR-0006 e o jogador refaria o remapeamento sem saber.
2. **Arquivo de versão futura e confirmação de arma.** Com `preferencias.cfg` de versão maior (jogador voltou a um build antigo), este ADR não regrava, e a última arma só vale na sessão. Opções: (a) não regravar; (b) regravar, perdendo campos novos. **Recomendação: (a)**, como no ADR-0006.
3. **Onde mora `telemetria_ligada`.** Os GDDs dizem só "configuração do usuário". Este ADR põe em `opcoes.cfg` para não conflitar com AC-AR-39. Confirmar, ou aceitar que o build de playtest leia `preferencias.cfg` (o que exigiria editar AC-AR-39). **Recomendação: confirmar `opcoes.cfg`.**

## Verificação de engine (2026-11-16)

Fonte: Completion Notes em `production/epics/experimentos-de-engine/` e `production/qa/evidence/experimentos/ex-0013-p1-p7.md`. Editor 4.7.2 standard, Windows 11.

- **E-P1 — custo de gravar e `flush`: PARCIAL.** p99 por linha 90–211 µs (OK), mas o pior trecho de 5 linhas seguidas levou 7–15 ms, acima do teto de 3 ms; os picos são do SO, não do GDScript. **Mitigação (decidida):** no passo de morte, o módulo só enfileira as linhas num buffer em memória; o `ArmazemUserGodot` grava e chama `flush` fora do passo (depois do `_physics_process`, no mesmo quadro). O passo fica dentro do teto; o risco residual é perder as linhas se o processo cair naquele quadro, aceito. O teto de 3 ms segue medido, como advisory, só sobre o trecho dentro do passo.
- **VERIFICADO:** depois do `flush`, as linhas estão no arquivo (releitura confere).
- **E-P2 — `DirAccess.rename` no Windows:** substitui um destino existente, mas **não é atômico** (apaga o destino antes de mover). A sequência com `.old` e a recuperação pura na carga ficam obrigatórias.
- **E-P3 — `ConfigFile.parse`:** aceita lixo binário e devolve `OK` com um arquivo vazio. **Exigência:** depois do parse, o repositório confere `schema_version` e a seção esperada; se faltarem, trata como corrompido e vai para o `.bak`. `OK` do parse, sozinho, não prova arquivo válido.
- **VERIFICADO:** `JSON.stringify` atende ao formato da telemetria.
- **E-P5 — `Time`:** a data/hora UTC vem sem o sufixo `Z`; o formatador concatena `"Z"` explicitamente.
- **VERIFICADO:** `OS.shell_open` com `ProjectSettings.globalize_path` abre a pasta do usuário.
- **E-P7 — pedido de fechar janela:** VERIFICADO no editor (fechamento automático desligado, `NOTIFICATION_WM_CLOSE_REQUEST` recebido, gravação antes de sair). **Não rodado no export.**
- **Pendência:** os templates de export 4.7.2 não estão instalados; repetir E-P1, E-P2 e E-P7 no `.exe` exportado.

## Related

[ADR-0002](adr-0002-canal-de-eventos.md), [ADR-0006](adr-0006-input-por-passo.md) §6, ADR-0012 (UI e HUD, tela de opções), [telemetria-local.md](../../design/gdd/telemetria-local.md), [input-e-controle.md](../../design/gdd/input-e-controle.md), [armas-das-doutrinas.md](../../design/gdd/armas-das-doutrinas.md), [economia-de-fragmentos.md](../../design/gdd/economia-de-fragmentos.md), [rng-com-seed.md](../../design/gdd/rng-com-seed.md), architecture.md "Data Flow §3" e "Open Questions".

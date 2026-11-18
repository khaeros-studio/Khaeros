# UX Spec: Tela de erros do catálogo

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Screen / Flow Name**: `TelaErrosDoCatalogo`
> **Platform Target**: PC — teclado+mouse, gamepad (modo digital "Sem catálogo")
> **Related GDDs**: `conteudo-orientado-a-dados.md` R7, R9, R12, Edge Cases (Recarga em debug), UI Requirements, AC-07, AC-08, AC-51 · `input-e-controle.md` R9, R10, R12 ("Sem catálogo"), AC-33, AC-34, AC-38 · `save-e-perfil.md` States (Sem gravação com catálogo em Falhou)
> **Related ADRs**: ADR-0004 §Carga e publicação, §Validação e diagnóstico, §Recarga entre runs · ADR-0006 §5 · ADR-0012 §3, §9, §11 (CB: `DisplayServer.clipboard_set`) · ADR-0001 (`MENU`)
> **Related UX**: `design/ux/interaction-patterns.md` (P1 Foco único, P6 Confirmação discreta, P8 Prompt de botão), `design/accessibility-requirements.md`, `design/art/art-bible.md` §4.1, §4.6, §7.2, §7.3, §7.6

## 1. Propósito

Quando a validação do catálogo (`content_catalog.tres` e definições `.tres`) encontra ao menos **1 erro** na inicialização ou numa recarga em debug, nenhuma run pode começar (Conteúdo R9). A `TelaErrosDoCatalogo` existe para **mostrar de forma imediata, legível e copiável todos os diagnósticos coletados**, permitindo que o desenvolvedor (em debug, com botão de recarga rápida) ou o jogador/testador (em release, copiando o relatório ou saindo) entenda exatamente o que falhou, mesmo quando o próprio `InputTuning` ou a tabela de tradução falharam.

## 2–4. Contexto, posição, entrada e saída

Abre no lugar do menu principal sempre que o carregador termina em `Falhou` (Conteúdo R9). Se houver apenas avisos (`0 erros`), esta tela **não** abre (avisos vão para o log e console). Permanece no contexto `Menu` (Input R10) e no modo **"Sem catálogo"** (Input R12), sem nenhum `*Tuning` injetado nos sistemas persistentes e com o Save em modo `Sem gravação` (ADR-0004, ADR-0013).

```
Inicialização / Recarga em debug (fora de run)
  └── Carregando → Validando (1ª e 2ª passadas)
        ├── 0 erros (avisos ≥ 0) ──► Menu principal (Pronto)
        └── ≥ 1 erro (Falhou) ─────► Tela de erros do catálogo (Sem catálogo / Menu)
                                       ├── [Copiar relatório] (fica na tela + confirmação discreta)
                                       ├── [Recarregar] (só em debug → Carregando → Pronto ou Falhou)
                                       └── [Sair] (encerra a aplicação)
```

| Entrada | Origem | Dados recebidos |
|---|---|---|
| Inicialização com `≥ 1 erro` | Carregador (`Falhou`) | Lista de diagnósticos ordenada (erros depois avisos; ordem do manifesto), contagens (`n_erros`, `n_avisos`), caminho `user://content_errors.log`, flag `is_debug_build` |
| Recarga em debug com `≥ 1 erro` | `Recarregar` (de `Pronto` fora de run ou da própria tela) | Novo lote de diagnósticos (`CACHE_MODE_IGNORE_DEEP`), `InputTuning` revogado (injeção vazia) |

| Saída | Destino | Efeito |
|---|---|---|
| `Recarregar` (só debug) com `0 erros` | Menu principal (`Pronto`) | Reinjeta `InputTuning`, `CameraTuning`, `HudTuning`, `TelaBencaoTuning`, `FeedbackTuning`, `VisualTuning`; recalcula impressão SHA-256 (R12) |
| `Recarregar` (só debug) com `≥ 1 erro` | `TelaErrosDoCatalogo` (`Falhou`) | Atualiza a lista e a contagem; foco volta ao topo |
| `Sair` | Sistema operacional | Fecha o jogo (`SceneTree.quit()`); nenhum dado de perfil é gravado |

Não existe saída para iniciar run, nem `ui_voltar` (Esc/B) que feche esta tela, pois não há nível acima quando o catálogo falha.

## 5. Layout e hierarquia visual

Tela de diagnóstico sem arte própria (Conteúdo UI Requirements), construída exclusivamente com a paleta e tipografia da Art Bible (§4.1, §4.6, §7.2, §7.3):

- **Fundo e painéis**: fundo em **Tinta `#0D0E14`** (opacidade 100%, já que é tela inteira sem mundo por trás); quadro da lista em painel de Tinta com moldura chanfrada de **Osso de mundo `#CFC6B4`** (3 px).
- **Tipografia e cores**:
  - Título (H1, Alegreya SC Bold 48 px) e cabeçalho de contagem em **Osso de UI `#E6DFCF`** sobre Tinta (~14:1).
  - Rótulo de gravidade **`[ERRO]`** e contagem de erros com acento em **Magenta `#E0259C`** Bold (≥ 24 px sobre Tinta, contraste ~4,5:1, Art Bible §7.3; acompanhado sempre do prefixo textual `[ERRO]` e ícone partido `✖`, nunca só cor).
  - Rótulo de gravidade **`[AVISO]`** em **Osso `#CFC6B4`** com ícone `▲` (diferenciação por forma e palavra, independente de cor).
  - Corpo de cada diagnóstico (Alegreya Sans Regular/Medium 22–24 px, algarismos tabulares) em **Osso `#E6DFCF`** para `id`, regra e mensagem, e **Osso `#CFC6B4`** para o caminho do arquivo e valores encontrado/esperado.

```
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║  FALHA NA VALIDAÇÃO DO CATÁLOGO                                                          ║
║  ✖ 3 erros · ▲ 1 aviso — Nenhuma run pode começar. Relatório salvo em user://content_errors.log ║
║ ┌──────────────────────────────────────────────────────────────────────────────────────┐ ║
║ │ [✖ ERRO]  [V1]  EnemyDef (eco_perdido) · assets/data/enemy/eco_perdido.tres          │▲║
║ │           Campo: dano · Encontrado: <ausente> · Esperado: float > 0                  │█║
║ │──────────────────────────────────────────────────────────────────────────────────────│░║
║ │ [✖ ERRO]  [V2]  AttackDef (lamina.ataque) · assets/data/weapon/lamina.tres           │░║
║ │           Campo: recarga_s · Encontrado: 0.0 · Esperado: > 0.0                       │░║
║ │──────────────────────────────────────────────────────────────────────────────────────│░║
║ │ [✖ ERRO]  [TB1] TelaBencaoTuning (tela_bencao_tuning) · .../tela_bencao_tuning.tres  │░║
║ │           Campo: trava_confirmar_ms · Encontrado: 400 · Esperado: 500–800            │░║
║ │──────────────────────────────────────────────────────────────────────────────────────│░║
║ │ [▲ AVISO] [WV8] ArmasTuning (armas_tuning) · assets/data/tuning/armas_tuning.tres    │▼║
║ │           Campo: p_max · Encontrado: 5 · Esperado: 4 (igual a RegionDef.p_max)       │ ║
║ └──────────────────────────────────────────────────────────────────────────────────────┘ ║
║   [W/S · ↑/↓ · D-pad: Rolar lista]                        (Relatório copiado! — 3 s)     ║
║   ●[Copiar relatório (C)]        [Recarregar catálogo (R) — Debug]        [Sair]         ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
```

**Hierarquia de leitura:**
1. **Título e resumo no topo**: deixa claro por que o jogo parou (`X erros, Y avisos`) e onde o arquivo `.log` foi gravado.
2. **Lista rolável de diagnósticos**: ocupa a faixa central (70% da altura), exibindo **todos** os erros primeiro e os avisos depois, na ordem estável do manifesto (Conteúdo R9, ADR-0004). Cada item mostra:
   - **Gravidade**: `[✖ ERRO]` (Magenta `#E0259C` Bold ≥ 24 px + ícone) ou `[▲ AVISO]` (Osso `#CFC6B4` + ícone);
   - **Regra**: código entre colchetes (`V1`–`V11` ou prefixos dos sistemas donos: `RN`, `EC`, `AV`, `MV`, `ST`, `BN`, `TL`, `FB`, `PV`, `WV`, `VV`, `HU`, `TB`, `ML`, `VP`, `CH`);
   - **Identidade e arquivo**: `<Tipo> (<id>)` e caminho `.tres` (ou `assets/data/content_catalog.tres` quando o manifesto falha);
   - **Mensagem detalhada**: `campo`, `valor encontrado` e `valor esperado` (ou regra entre campos violada).
3. **Barra de ações inferior**: botões largos (mín. 280 × 64 px), com **foco inicial em `Copiar relatório`**. Em builds de release, o botão `Recarregar catálogo` não existe (oculto da árvore e do `ModeloDeFoco`), restando `Copiar relatório` e `Sair`.

## 6. Estados

| Estado | Gatilho | Mudança visual e comportamental |
|---|---|---|
| Aberta (padrão) | Carga ou recarga termina em `Falhou` | Lista populada no topo (scroll = 0); foco inicial no botão `Copiar relatório`; `user://content_errors.log` já gravado |
| Manifesto ausente | `content_catalog.tres` não encontrado (AC-02) | Lista exibe 1 único item `[✖ ERRO]`: `manifesto não encontrado: assets/data/content_catalog.tres` |
| Foco na lista rolável | `↑` a partir dos botões ou clique/hover na lista | Anel de foco (4 px dourado com linha de tinta, ou 3 px osso sólido) envolve o quadro da lista; `↑/↓` (W/S, D-pad) rolam 1 item por toque; `PageUp/PageDown` rolam 1 página |
| Relatório copiado | Acionar `Copiar relatório` ou atalho `C` | Copia texto completo para o clipboard (`DisplayServer.clipboard_set`); exibe confirmação discreta P6 (`CATALOGO_RELATORIO_COPIADO` / fallback PT-BR) por 3 s em `t_real` |
| Recarregando (só debug) | Acionar `Recarregar catálogo` ou atalho `R` | Desabilita botões por 1 passo enquanto o carregador roda síncrono com `CACHE_MODE_IGNORE_DEEP`; se `0 erros`, transita para o Menu principal; se `≥ 1 erro`, atualiza a lista e exibe confirmação discreta `"Recarregado: X erros"` |
| Fallback sem tradução | Falha na própria tabela de tradução (V6 ou CSV ausente) | Usa strings PT-BR mínimas embutidas na classe da vista (única exceção permitida à R7 do Conteúdo) |

## 7. Interação e operação em modo "Sem catálogo" (Input R12)

Como o catálogo falhou, o `InputTuning` **não existe** (ou foi retirado ao sair de `Pronto`). O sistema de Input opera estritamente no modo **"Sem catálogo"** (Input R12, AC-51) e a UI segue o **foco único** (Art Bible §7.6, P1 de `interaction-patterns.md`):

- **Apenas entradas digitais**: teclas do teclado, cliques de botão do mouse, D-pad e botões digitais do gamepad (A/Sul, B/Leste, X/Oeste, Y/Norte).
- **Analógicos e gatilhos ignorados**: os eixos analógicos (esquerdo e direito) e gatilhos analógicos (LT/RT) dependem de `zm`, `ze` e limiares de histerese do `InputTuning` e por isso **não movem o foco nem acionam nada** (AC-51).
- **Sem troca de dispositivo por movimento do mouse**: como `L_mouse` também pertence ao `InputTuning`, mover o mouse não altera o dispositivo ativo para fins de glifo (apenas clique de mouse ou tecla/botão digital trocam); porém, o hover com movimento sobre os slots de layout dos botões continua movendo o `ModeloDeFoco` único (política de Menu, ADR-0012 §3).

| Ação | Teclado (digital) | Gamepad (digital — D-pad e botões) | Mouse |
|---|---|---|---|
| Mover foco entre botões (`Copiar`, `Recarregar`, `Sair`) | `A` / `D`, `←` / `→` | D-pad `←` / `→` (analógico ignorado) | Mover sobre o botão; clique confirma |
| Rolar a lista de diagnósticos | `W` / `S`, `↑` / `↓`, `PageUp` / `PageDown` | D-pad `↑` / `↓` (em qualquer foco da tela, rola a lista diretamente) | Roda do mouse na lista ou clique na barra de rolagem |
| Alternar foco Lista ↔ Botões | `↑` / `↓` quando na borda, ou `Tab` (se remapeado) | — (D-pad `↑`/`↓` rola a lista sem precisar tirar o foco dos botões; D-pad `←`/`→` navega nos botões) | Clique |
| Confirmar botão em foco | `Enter` / `Espaço` / `E` | `A` (Sul) | Clique esquerdo no botão |
| Atalho Copiar relatório | `C` | `X` (Oeste) | Clique em `Copiar relatório` |
| Atalho Recarregar (só debug) | `R` | `Y` (Norte) | Clique em `Recarregar catálogo` |
| Voltar (`Esc` / `B`) | Sem efeito (não fecha a tela) | Sem efeito | — |

> **Design de rolagem sem atrito no gamepad (AC-51):** Como na barra inferior os botões estão dispostos em linha horizontal (`←`/`→`) e a lista é o único elemento vertical da tela, `↑`/`↓` no D-pad (e `W`/`S` ou `↑`/`↓` no teclado) rolam a lista de diagnósticos diretamente mesmo quando o foco está em `Copiar relatório` ou `Sair`. Além disso, a própria lista também é um alvo focável acima dos botões para inspeção item a item. Assim o teste automatizado e o jogador conseguem rolar a lista e acionar `Copiar relatório` e `Sair` usando exclusivamente D-pad e botões do gamepad.

## 8–9. Dados, eventos e formato do relatório

- **Leitura**: recebe um `RelatorioDeValidacao` (RefCounted, imutável) contendo `erros: Array[DiagnosticoDeConteudo]`, `avisos: Array[DiagnosticoDeConteudo]`, `impressao_parcial: String` (se disponível) e `caminho_log: String` (`user://content_errors.log`).
- **Portas injetadas**:
  - `PortaDaAreaDeTransferencia.copiar(texto)` → chama `DisplayServer.clipboard_set(texto)` (ADR-0012 CB);
  - `PortaDoCarregador.recarregar()` (só em debug, fora de run, ADR-0004);
  - `PortaDaAplicacao.sair()`.
- **Formato do texto copiado e do `.log`**: texto puro UTF-8, uma linha de cabeçalho (`KHAEROS CONTENT ERRORS — X erros, Y avisos`) seguida de uma linha por diagnóstico no formato `[{NIVEL}] [{REGRA}] {tipo}:{id} ({arquivo}) — {campo}: encontrado={encontrado}, esperado={esperado} — {mensagem}`.

## 10. Transições

Abre em corte seco (0 ms), pois ocorre na inicialização antes de qualquer cena de jogo ou imediatamente após falha de recarga em debug. Não depende de `TelaBencaoTuning` nem de `VisualTuning`. A confirmação discreta de cópia usa `RelogioDeInterface.t_real()` (3 s).

## 11–12. Entrada e acessibilidade

- **Checklist de acessibilidade**:
  - **Só teclado**: completo (`A`/`D` ou `←`/`→` para botões, `W`/`S` ou `↑`/`↓` para rolar, `Enter`/`Espaço`/`E` para confirmar, `C` para copiar, `R` para recarregar em debug).
  - **Só gamepad**: completo via D-pad e botões digitais, sem depender de analógicos nem de `InputTuning` (AC-51).
  - **Tamanho mínimo de texto**: título 48 px, resumo 24 px, linhas de diagnóstico 22 px (acima do piso de 22 px de corpo e 16 px absoluto de `design/accessibility-requirements.md`).
  - **Independência de cor**: erros e avisos diferenciados por prefixo textual (`[ERRO]` vs `[AVISO]`), ícone (`✖` vs `▲`) e ordem (erros agrupados antes dos avisos), além da cor (Magenta `#E0259C` vs Osso `#CFC6B4`).
  - **Sem flashes**: tela 100% estática.
  - **Escala e resolução**: layout ancorado com margem segura de 48 px; em 1280 × 720 a lista encolhe em altura e mantém `autowrap` nas mensagens longas sem cortar texto.

## 13. Localização e exceção de fallback (Conteúdo R7)

As chaves da tela (`CATALOGO_ERRO_TITULO`, `CATALOGO_ERRO_RESUMO`, `CATALOGO_BTN_COPIAR`, `CATALOGO_BTN_RECARREGAR`, `CATALOGO_BTN_SAIR`, `CATALOGO_RELATORIO_COPIADO`) usam `tr()` quando a tabela PT-BR foi carregada. Caso a tabela de tradução não tenha carregado ou uma chave da própria tela falhe (ex.: erro V6 global), a vista aplica o dicionário estático de fallback em PT-BR embutido no script — a **única exceção autorizada no projeto** à proibição de literais de UI (Conteúdo UI Requirements, linha 1111).

## 14. Critérios de aceite

- [ ] Com 2 erros (`V1`, `V2`) e 1 aviso (`WV8`), a tela abre no lugar do menu principal mostrando `"2 erros · 1 aviso"`, os 2 erros listados antes do aviso na ordem do manifesto, cada um com gravidade, código da regra, id/arquivo, campo e valores (AC-07).
- [ ] Com 0 erros e ≥ 1 aviso, esta tela **não** abre e o jogo segue para o menu principal.
- [ ] Com o catálogo em `Falhou` (inclusive quando o erro é `zm + ze ≥ 1` no `InputTuning`), nenhum sistema recebe `*Tuning`; a lista rola e os botões `Copiar relatório` e `Sair` funcionam exclusivamente por D-pad e botões digitais do gamepad, enquanto o analógico é ignorado (AC-51, Input AC-38).
- [ ] Acionar `Copiar relatório` (por botão ou atalho `C`/`X`) copia o relatório completo para a área de transferência (`DisplayServer.clipboard_get()` contém todos os códigos e arquivos listados) e mostra confirmação discreta por 3 s.
- [ ] Em build de debug, o botão `Recarregar catálogo` aparece e dispara a recarga com `CACHE_MODE_IGNORE_DEEP`; se o `.tres` foi corrigido no disco, a tela fecha e o jogo entra em `Pronto` reinjetando os Tunings (AC-47); em build de release, o botão `Recarregar catálogo` não existe (AC-08).
- [ ] Se a tabela de tradução falhar na carga, todos os rótulos da tela continuam legíveis pelo fallback PT-BR embutido, sem exibir chaves cruas.
- [ ] Em filtro de tons de cinza e nos 3 simuladores de daltonismo, itens `[✖ ERRO]` e `[▲ AVISO]` e o anel de foco nos botões permanecem distinguíveis por forma e texto.

## 15. Open Questions

Nenhuma. Todos os requisitos de `conteudo-orientado-a-dados.md` (UI Requirements, R9, R12) e `input-e-controle.md` (R12 "Sem catálogo") estão fechados nesta especificação.

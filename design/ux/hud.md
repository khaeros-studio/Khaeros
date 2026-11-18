# HUD Design: HUD de combate

> **Status**: Approved · **Author**: ux-designer (agente) · **Last Updated**: 2026-11-18
> **Fonte de verdade das regras**: `design/gdd/hud.md` (R1–R19, F1–F8, Tuning, AC-HD-*); arquitetura em `docs/architecture/adr-0012-ui-e-hud.md` (decisões 1, 2, 8, 10)
> **Padrões e acessibilidade**: `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md` (escritos em paralelo; esta spec só os referencia)
> **Plataforma**: PC, 1920 × 1080 de referência, 1280 × 720 mínimo, ultrawide até 2580 de largura; teclado+mouse e gamepad

Esta spec traduz o GDD em decisões de UX. Não repete medidas: cita a regra.

## A. Filosofia

**Mínimo, nas bordas, lido pela forma.** O jogador olha a Beira, não o painel (GDD Overview). Só o que decide o próximo segundo fica na tela; o resto vai para a pausa, o resumo ou o mundo. Nenhum elemento de tela a 100% entra no retângulo central de 60% × 70% (R2).

## B. Arquitetura da informação

| Informação | Categoria | Onde mora |
|---|---|---|
| Vida, escudo, recusas | Must Show | grupo inferior esquerdo (R3, R5) |
| Fluxo e estado do Selo | Must Show | grupo inferior esquerdo (R6) |
| Cargas de Esquiva | Must Show | grupo inferior esquerdo (R7) |
| Bloco do Pacto (dupla, Vida, Exaustão, Troca) | Must Show **só com Pactos** | acima do grupo (R15–R19) |
| Barra de chefe | Contextual (câmara do chefe, chefe vivo) | topo centro (R11; ativa no MVP por `chefes.md` R10) |
| Fragmentos | Contextual (acende no ganho, escurece em repouso) | superior direito (R8) |
| Fio de Vida do inimigo | Contextual (após dano, 2 s) | no mundo (R9) |
| Prompt Interagir | Contextual (porta, acuada `Aguardando`, chefe `Subjugado`) | no mundo (R10; `vinculo-e-pactos.md` V9, V18) |
| Bênçãos tomadas, seed, progresso | On Demand | pausa (`pausa-e-opcoes.md`) |
| Invulnerabilidade, telégrafos, números de dano | Hidden do HUD | mundo / Feedback / Telégrafos |

Conflito com a filosofia: com Pactos o Must Show sobe de 3 para 4 blocos. Aceito porque o Bloco fica na mesma coluna de leitura do Selo e nunca no centro (R15).

## C. Zonas

```
┌──────────────────────────────────────────────────────────────┐
│ 48px              [ Nome do chefe (H2) ]            [◆ 1 234]│  topo: chefe (centro), Fragmentos (dir.)
│                   [▓▓▓▓▓▓▓▓▓▓|▓▓▓▓▓▓▓▓▓]                     │
│        ┌ - - - - retângulo central 60% × 70% - - - - ┐       │
│        |  (só mundo: fios, prompt, telégrafos)        |      │
│        └ - - - - - - - - - - - - - - - - - - - - - - ┘       │
│ ┌Bloco do Pacto 332×88┐  ← só com Pactos, 12 px acima       │
│ └─────────────────────┘                                      │
│ ┌Grupo ~420×110: gota Fluxo · barra Vida 34/80 · chevrons┐   │
└──────────────────────────────────────────────────────────────┘
```

## D. Elementos (resumo; detalhe no GDD)

| Elemento | Forma | Atualiza | Animação |
|---|---|---|---|
| Vida | osso segmentado + número | consulta a cada entrega (ADR-0012 §2) | racha 0,25 s; espera `preco_revelado` e fim do hitstop |
| Fluxo | gota com entalhe | idem | pisca o entalhe 1× em `selo_sem_fluxo` |
| Esquiva | chevrons cheio/contorno | idem | tremor 80 ms em `esquiva_sem_carga` |
| Fragmentos | ícone + número | idem | acende 1,5 s, "+N" somado |
| Bloco do Pacto | 2 slots, barras, Selo da Troca | `estado_pacto()` | sacudida 4 px / 0,15 s; pulso de contorno com redução de movimento |
| Barra de chefe | osso com entalhe 50% | `chefe()` | entalhe racha na troca de fase |
| Fio / prompt | fio de osso / glifo + verbo | idem | aparece e some no passo |

## E. Estados por contexto (ADR-0001 `EstadoDeJogo`)

| Estado | O que muda |
|---|---|
| `JOGO` (exploração/limpeza) | tudo visível; prompt quando houver interagível |
| `JOGO` (combate) | idem; fios aparecem com dano; Vida baixa liga vinheta |
| `BENCAO` (Tela de bênção ou consentimento/Pactuar) | grupo, Bloco e Fragmentos visíveis; fios, prompt e barra de chefe escondidos até `tela_fechada` (R12) |
| `PAUSA` | tudo esmaecido a 60% sob o menu |
| `TRANSICAO` | fade 0,25 s ida e volta (≤ 300 ms com redução de movimento) |
| `MENU`, `MORTE` | sem HUD de combate; tela final é `tela-fim-de-run.md` |
| Diálogo/cutscene | não existe no MVP; se surgir, segue a linha `BENCAO` |
| Vida baixa | moldura partida + vinheta + som (R4, histerese 30%) |
| Sem Pactos / sem reserva | Bloco não existe / encolhe a 228 × 88 (R15, R17) |

## F–G. Hierarquia e orçamento

MUST KEEP: Vida, Fluxo, Esquiva (sem eles não se joga). SHOULD KEEP: Bloco do Pacto, barra de chefe (decisão tática; som de recusa cobre a Troca se escondido). CAN HIDE: Fragmentos (som de coleta), fios (feedback de golpe). Orçamento: ≤ 6 elementos de tela simultâneos (grupo, Bloco, chefe, Fragmentos, + prompt e até 9 fios no mundo); elementos de tela ≤ 12% da área a 100% (grupo + Bloco + chefe ≈ 4,6 + 1,4 + 1,2 = ~7%). Nada é derrubado no MVP; se a escala de 150% invadir o centro, aceita-se (R2).

## H. Notificações

| Tipo | Origem | Posição | Duração | Fila |
|---|---|---|---|---|
| "+N" Fragmentos | Economia | ao lado do número | 1,5 s | soma na janela; nunca empilha |
| Recusa (sem Fluxo, sem carga, Troca indisponível) | Selo, Movimento, Maldições | no próprio elemento | 80–150 ms | reinicia sem somar; nunca enfileira |
| `SEED_COPIADA`, `OPCOES_FALHA_GRAVAR` | UI | fora de `JOGO` apenas | 2 s | fila de avisos do `Main` |
| Avisos `PERFIL_*` | Save | nunca sobre o combate (ADR-0012 §10) | até dispensar | fila do `Main`, 1×/sessão |

## I. Plataforma

Só PC. Margem 48 px nas bordas do viewport; o centro se mede no quadro 1920 × 1080 centralizado (R2). Glifos trocam com o dispositivo no passo seguinte (R10, R19).

## J. Acessibilidade

Sem elemento interativo (sem ordem de foco). Forma e valor, nunca só cor (R13, R17). Redução de movimento: vinheta estática, sacudidas viram pulso de contorno, preenchimentos viram corte. Alto contraste: placas 100%, molduras 3 px. Texto mínimo 20 px a 100%. Leitor de tela: fora do MVP (AccessKit futuro, ADR-0012 §3) — ver `design/accessibility-requirements.md`.

## K. Ajustes do jogador (`opcoes.cfg [ui]`, ADR-0013 §8)

`escala` 85/100/125/150 (100) · `numero_vida` lig/desl (lig) · `vida_colorida` (desl) · `alto_contraste` (desl) · `vinheta` 0–100% (100) · `[acessibilidade] reduzir_movimento` (desl).

## L. Critérios de aceite

- [ ] A 1920 × 1080 e 100%, nenhum elemento de tela tem pixel no retângulo x 384–1536, y 162–918; todos ficam a ≥ 48 px das bordas, também em 1280 × 720 e 2580 × 1080.
- [ ] Em `JOGO` com Pactos e dupla cheia: grupo, Bloco (332 × 88, 12 px acima do grupo) e Fragmentos visíveis; sem Pactos o nó do Bloco não existe.
- [ ] Ao abrir a Tela de bênção ou de consentimento, fios e prompt somem no mesmo passo e voltam no passo de `tela_fechada`.
- [ ] Na câmara do chefe, a barra aparece com o chefe vivo e some em `Morto`/`Subjugado`; o chefe não tem fio sob os pés.
- [ ] Com tons de cinza (filtro de dessaturação), Vida baixa, Fluxo pronto/sem Fluxo, Esquiva cheia/vazia, Reserva Pronta/Exausta e Troca disponível/indisponível continuam distinguíveis.
- [ ] Com redução de movimento, `troca_indisponivel` não desloca o Selo da Troca (só pulso de contorno) e a vinheta não pulsa.
- [ ] Três coletas em 1 s mostram um só "+N" com a soma; nenhum aviso `PERFIL_*` aparece em `JOGO`.
- [ ] A 150% em 1280 × 720, grupo e Bloco cabem inteiros na tela.

## Open Questions

| Questão | Dono | Resolução |
|---|---|---|
| Tier de acessibilidade final | accessibility-specialist | definir em `design/accessibility-requirements.md` |
| Posição da camada da vinheta (GDD OQ 9) | Cena / Pipeline | ADR-0012 §1 delega ao Pipeline |

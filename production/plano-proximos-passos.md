# Plano dos Próximos Passos — Khaeros (Godot)

> Criado em 2026-11-05. Rigor do estúdio: **standard** (`project.yaml` → `modes.rigor`).
> Conceito: `design/gdd/game-concept.md` (rascunho v0.1, aguardando aprovação).

## Fase 0 — Ambiente (você, fora do Claude)

| # | Passo | Por quê |
|---|---|---|
| 0.1 | ✅ **Feito em 2026-11-05.** Godot 4.7.2 padrão em `C:\Users\lucas\Godot\4.7.2\`, comando `godot` no PATH do usuário; `godot --headless --path . --import` sai com 0. | `project.godot` verificado. Smoke e run só funcionam depois de existir a cena principal. |
| 0.2 | ✅ **Feito** — Python 3.13.14 no PATH (`python` e `python3`, Git Bash e PowerShell). Os scripts do estúdio não usam PyYAML. | Os hooks leem `project.yaml` com Python. |
| 0.3 | ✅ **Feito em 2026-11-05** — `godot --version` = 4.7.2.stable.official; `project-coherence.sh`: 6 conferidos, 0 not checked, 1 differs esperado (gdUnit4 ausente até o passo 4.1 `/test-setup`). | Confirma as duas instalações. |

## Fase 1 — Fechar o conceito (Concept)

| # | Passo | Skill | Saída |
|---|---|---|---|
| 1.1 | Revisar e aprovar `game-concept.md` e as 7 pendências da §13 | — (conversa) | conceito v1.0 aprovado |
| 1.2 | Dar o sign-off dos Mestres novos em `Khaeros/docs/NARRATIVE_Mestres_Bencaos_Modo_Acao.md` §6 | — | cânone atualizado no repo Khaeros |
| 1.3 | Validar o conceito | `/design-review design/gdd/game-concept.md` | relatório de lacunas |

## Fase 2 — Identidade visual (antes de mapear sistemas)

| # | Passo | Skill | Saída |
|---|---|---|---|
| 2.1 | ✅ **Feito 2026-11-05** — Art Bible completo (9 seções, aprovado pelo CD) | `/art-bible` | `design/art/art-bible.md` |
| 2.2 | Especificar os assets que faltam e reescrever os prompts do Nano Banana com nomes canônicos (armas de Guardião, Transmutação e Pactos; criatura do pacto; Anomalia Maior; Guardião do Rito; chão das câmaras) | `/asset-spec` | specs + prompts |
| 2.3 | Trazer a pipeline de recorte de verde de `eco-das-brasas/tools/` para `tools/asset-pipeline/` (adaptada para exportar PNG para o Godot) | `/dev-story` ou `tools-programmer` | pipeline no estúdio |

## Fase 3 — Sistemas e GDDs (Pre-production)

| # | Passo | Skill | Saída |
|---|---|---|---|
| 3.1 | Decompor o conceito em sistemas e ordem de design | `/map-systems` | `design/gdd/systems-index.md` |
| 3.2 | GDDs na ordem Foundation → Core: **movimento e esquiva**, **combate (armas, Selo, hitstop)**, **inimigos e telégrafos**, **câmaras e portas**, **bênçãos (Tradições e Mestres)**, **run e regiões**, **meta-progressão (Oficina de Reforja)**, **Campus** | `/design-system <sistema>` | um GDD por sistema |
| 3.3 | Revisão cruzada dos GDDs | `/review-all-gdds` | consistência |
| 3.4 | Protótipo do núcleo: **uma câmara**, Iniciado com a Lâmina, 2 inimigos, esquiva, uma tela de bênção | `/prototype combate-camara` | PROCEED / PIVOT / KILL |

> O protótipo 3.4 pode vir **antes** dos GDDs de bênçãos e de Campus. O risco
> maior é o combate ser bom em Godot; prove isso primeiro.

## Fase 4 — Arquitetura e produção

| # | Passo | Skill |
|---|---|---|
| 4.1 | Instalar gdUnit4 e o CI de testes | `/test-setup` |
| 4.2 | Arquitetura e ADRs críticos (dados de conteúdo em `.tres`, máquina de estados da run, determinismo sim/não) | `/create-architecture`, `/architecture-decision` |
| 4.3 | Épicos, histórias e primeira sprint | `/create-epics`, `/create-stories`, `/sprint-plan new` |
| 4.4 | Vertical slice: Limiar da Beira completo (7 câmaras + Anomalia Maior) | `/vertical-slice` |

## Marcos

| Marco | Pronto quando |
|---|---|
| **M0 — Ambiente** ✅ 2026-11-05 | Godot e Python instalados, coerência sem `[NOT CHECKED]` |
| **M1 — Conceito aprovado** | `game-concept.md` v1.0 + sign-off dos Mestres |
| **M2 — Combate prova** | protótipo de uma câmara com veredito PROCEED |
| **M3 — Fatia vertical** | Limiar da Beira jogável do Campus ao chefe |

## Regras que valem em todas as fases

- O repo Khaeros é a fonte da verdade do universo. Mudança de cânone é
  registrada lá (`docs/baseline.md` + documento específico).
- Toda invenção nasce `[PROPOSTA]`.
- Nenhum commit sem você pedir (nem aqui nem no repo Khaeros).

# Epics Index

Last Updated: 2026-11-16
Engine: Godot 4.7 (4.7.2 instalado)
Review: PR-EPIC skipped — lean
Control manifest: ausente na geração (outro agente o gerava em paralelo) — stories devem embutir a versão quando existir

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [Experimentos de engine](experimentos-de-engine/EPIC.md) | Foundation | — | docs/architecture/architecture.md | 9 stories | Ready |
| [Orquestrador do passo e canal de eventos](orquestrador-do-passo/EPIC.md) | Foundation | — | docs/architecture/adr-0001-orquestrador-do-passo.md | 8 stories | Ready |
| [Conteúdo orientado a dados](conteudo/EPIC.md) | Foundation | conteudo | design/gdd/conteudo-orientado-a-dados.md | 10 stories | Ready |
| [RNG com seed](rng/EPIC.md) | Foundation | rng | design/gdd/rng-com-seed.md | 7 stories | Ready |
| [Input e controle](input/EPIC.md) | Foundation | input | design/gdd/input-e-controle.md | 9 stories | Ready |
| [Cena 3/4 e câmera](cena-e-camera/EPIC.md) | Foundation | cena | design/gdd/cena-3-4-e-camera.md | 8 stories | Ready |
| [Save e perfil (persistência)](persistencia/EPIC.md) | Foundation | save | design/gdd/save-e-perfil.md | 10 | Ready |
| [Modificadores e atributos](modificadores/EPIC.md) | Core | modificadores | design/gdd/modificadores-e-atributos.md | 8 | Ready |
| [Movimento e esquiva](movimento-e-esquiva/EPIC.md) | Core | movimento-e-esquiva | design/gdd/movimento-e-esquiva.md | 10 | Ready |
| [Combate núcleo](combate-nucleo/EPIC.md) | Core | combate-nucleo | design/gdd/combate-nucleo.md | 10 stories | Ready |
| [Armas das Doutrinas](armas-das-doutrinas/EPIC.md) | Feature | armas-das-doutrinas | design/gdd/armas-das-doutrinas.md | 8 stories | Ready |
| [Selo e Fluxo](selo-e-fluxo/EPIC.md) | Feature | selo-e-fluxo | design/gdd/selo-e-fluxo.md | 5 stories | Ready |
| [Efeitos de status](efeitos-de-status/EPIC.md) | Feature | efeitos-de-status | design/gdd/efeitos-de-status.md | 7 stories | Ready |
| [Telégrafos](telegrafos/EPIC.md) | Feature | telegrafos | design/gdd/telegrafos.md | 10 stories | Ready |
| [IA de inimigos e elites](ia-de-inimigos-e-elites/EPIC.md) | Feature | ia-de-inimigos-e-elites | design/gdd/ia-de-inimigos-e-elites.md | 10 stories | Ready |
| [Economia de Fragmentos](economia-de-fragmentos/EPIC.md) | Feature | economia | design/gdd/economia-de-fragmentos.md | 7 stories | Ready |
| [Bênçãos e Tradições](bencaos-tradicoes/EPIC.md) | Feature | bencaos | design/gdd/bencaos-tradicoes.md | 10 stories | Ready |
| [Câmaras e ondas](camaras-e-ondas/EPIC.md) | Feature | camaras | design/gdd/camaras-e-ondas.md | 10 stories | Ready |
| [Portas e recompensas](portas-e-recompensas/EPIC.md) | Feature | portas | design/gdd/portas-e-recompensas.md | 8 stories | Ready |
| [Run e regiões (ciclo da run)](run-e-regioes/EPIC.md) | Feature | run | design/gdd/run-e-regioes.md | 10 stories | Ready |
| [Maldições (Doutrina de Pactos)](maldicoes/EPIC.md) | Feature | maldicoes | design/gdd/maldicoes.md | 10 stories | Ready |
| [Vínculo e pactos](vinculo-e-pactos/EPIC.md) | Feature | vinculo | design/gdd/vinculo-e-pactos.md | 10 stories | Ready |
| [Chefes](chefes/EPIC.md) | Feature | chefes | design/gdd/chefes.md | 10 stories | Ready |
| [Pipeline visual](pipeline-visual/EPIC.md) | Presentation | pipeline | design/gdd/pipeline-visual.md | 10 stories | Ready |
| [HUD](hud/EPIC.md) | Presentation | hud | design/gdd/hud.md | 10 stories | Ready |
| [Tela de bênção e carta](tela-de-bencao-e-carta/EPIC.md) | Presentation | tela-bencao | design/gdd/tela-de-bencao-e-carta.md | 9 stories | Ready |
| [Feedback de combate](feedback-de-combate/EPIC.md) | Presentation | feedback | design/gdd/feedback-de-combate.md | 8 stories | Ready |
| [Áudio: ganchos e vozes](audio/EPIC.md) | Presentation | — | docs/architecture/adr-0016-audio-ganchos-e-vozes.md | 5 stories | Ready |
| [Telemetria local](telemetria-local/EPIC.md) | Presentation | telemetria | design/gdd/telemetria-local.md | 10 stories | Ready |
| [Assets e conteúdo](assets-e-conteudo/EPIC.md) | Foundation | — | design/gdd/conteudo-orientado-a-dados.md | 9 stories | Ready |

## Ordem de execução por camada

Regra: só se chama para baixo (architecture.md). Dentro da camada, a ordem respeita as dependências entre épicos; itens na mesma linha podem correr em paralelo.

**0. Transversal (começa já e corre em paralelo)**
- `experimentos-de-engine` — EX-0001/0002 primeiro (bloqueiam o orquestrador), depois EX-0004-NV, EX-0007-NV, EX-0013, EX-0009-1; EX-0011 E1–E3 antes das stories do Pipeline; EX-0012, EX-0016, EX-0010-1 antes das stories que os citam.
- `assets-e-conteudo` — entrega 1 (catálogo `.tres` + migração do JSON) logo após o `conteudo`; arte e áudio acompanham Apresentação.

**1. Foundation** (ordem de inicialização da arquitetura §4)
1. `orquestrador-do-passo` ∥ `conteudo`
2. `rng` ∥ `input`
3. `cena-e-camera` ∥ `persistencia`

**2. Core** (ordem do passo: Modificadores → Movimento → Combate)
4. `modificadores`
5. `movimento-e-esquiva`
6. `combate-nucleo`

**3. Feature**
7. `armas-das-doutrinas` ∥ `selo-e-fluxo` ∥ `telegrafos` ∥ `economia-de-fragmentos` ∥ `bencaos-tradicoes`
8. `ia-de-inimigos-e-elites`
9. `efeitos-de-status` ∥ `camaras-e-ondas` ∥ `maldicoes`
10. `portas-e-recompensas` ∥ `vinculo-e-pactos`
11. `run-e-regioes` ∥ `chefes`

**4. Presentation** (pode começar junto da Feature para o que só depende de Core/Foundation)
12. `pipeline-visual` (após `telegrafos` e EX-0011 E1–E3)
13. `feedback-de-combate` ∥ `hud` ∥ `tela-de-bencao-e-carta`
14. `audio` ∥ `telemetria-local`

Caminho crítico: experimentos EX-0001/0002 → orquestrador → modificadores → movimento → combate → IA → câmaras → portas → run. A fatia de 2026-11-14 continua jogável durante a troca: cada épico substitui sua parte por trás do `Main`.

## Cobertura de TR (400 / 400)

Conferida por script contra `docs/architecture/tr-registry.yaml` (2026-11-16): cada TR-ID ativo está em exatamente um épico; todos têm ADR Accepted (0 untraced).

| Épico | Sistema (TR) | TR-IDs | Faixa |
|-------|--------------|--------|-------|
| conteudo | conteudo | 19 | TR-conteudo-001 … TR-conteudo-019 |
| rng | rng | 15 | TR-rng-001 … TR-rng-015 |
| input | input | 15 | TR-input-001 … TR-input-015 |
| cena-e-camera | cena | 13 | TR-cena-001 … TR-cena-013 |
| persistencia | save | 18 | TR-save-001 … TR-save-018 |
| modificadores | modificadores | 16 | TR-modificadores-001 … TR-modificadores-016 |
| movimento-e-esquiva | movimento-e-esquiva | 14 | TR-movimento-001 … TR-movimento-014 |
| combate-nucleo | combate-nucleo | 24 | TR-combate-nucleo-001 … TR-combate-nucleo-024 |
| armas-das-doutrinas | armas-das-doutrinas | 14 | TR-armas-001 … TR-armas-014 |
| selo-e-fluxo | selo-e-fluxo | 15 | TR-selo-001 … TR-selo-015 |
| efeitos-de-status | efeitos-de-status | 13 | TR-status-001 … TR-status-013 |
| telegrafos | telegrafos | 17 | TR-telegrafos-001 … TR-telegrafos-017 |
| ia-de-inimigos-e-elites | ia-de-inimigos-e-elites | 19 | TR-ia-001 … TR-ia-019 |
| economia-de-fragmentos | economia | 9 | TR-economia-001 … TR-economia-009 |
| bencaos-tradicoes | bencaos | 11 | TR-bencaos-001 … TR-bencaos-011 |
| camaras-e-ondas | camaras | 15 | TR-camaras-001 … TR-camaras-015 |
| portas-e-recompensas | portas | 10 | TR-portas-001 … TR-portas-010 |
| run-e-regioes | run | 16 | TR-run-001 … TR-run-016 |
| maldicoes | maldicoes | 19 | TR-maldicoes-019 … TR-maldicoes-018 |
| vinculo-e-pactos | vinculo | 18 | TR-vinculo-001 … TR-vinculo-018 |
| chefes | chefes | 17 | TR-chefes-001 … TR-chefes-017 |
| pipeline-visual | pipeline | 16 | TR-pipeline-001 … TR-pipeline-016 |
| hud | hud | 14 | TR-hud-001 … TR-hud-014 |
| tela-de-bencao-e-carta | tela-bencao | 15 | TR-tela-bencao-001 … TR-tela-bencao-015 |
| feedback-de-combate | feedback | 16 | TR-feedback-001 … TR-feedback-016 |
| telemetria-local | telemetria | 12 | TR-telemetria-001 … TR-telemetria-012 |
| experimentos-de-engine | — | 0 | transversal (sem TR próprio) |
| orquestrador-do-passo | — | 0 | transversal (sem TR próprio) |
| audio | — | 0 | transversal (sem TR próprio) |
| assets-e-conteudo | — | 0 | transversal (sem TR próprio) |
| **Total** | | **400** | |

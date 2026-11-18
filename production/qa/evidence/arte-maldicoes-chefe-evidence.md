# Evidência de Arte e Sign-Off — Maldições Aliadas, Chefe Soberano do Limiar e Iniciado de Pactos (`story-007`)

> **Story:** [`production/epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md`](../../epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md)
> **Data:** 2026-11-18
> **Responsáveis:** `art-director` (Direção Visual e Sign-Off) · `technical-artist` (Chroma-Key, Despill, Empacotamento Runtime e Validação)
> **Status:** APROVADO (PASS)

---

## 1. Atlas de Atores Empacotados em `assets/art/runtime/`

Todos os 6 novos atores foram processados a partir das folhas aprovadas em `assets/art/source/raw/` via [`tools/art/pack_all_mvp_art.ps1`](../../../tools/art/pack_all_mvp_art.ps1) e [`tools/art/pack_all_mvp_art.py`](../../../tools/art/pack_all_mvp_art.py), com remoção de chroma-key `#00FF00` (flood-fill externo + chaveamento de vãos internos + despill de borda verde) e padronizados em células `400×400` (pivô `[200, 320]`):

| Ator (`actor_id`) | Atlas PNG (`3200×2400`) | Manifesto e SpriteFrames | Quadros | Animações | Tamanho Lógico / Escala | Observações de Recorte |
|---|---|---|---|---|---|---|
| `vulto_mudo` | [`vulto_mudo_atlas_v01.png`](../../../assets/art/runtime/vulto_mudo/vulto_mudo_atlas_v01.png) | `atlas_manifest_v01.json` · `vulto_mudo_frames_v01.tres` | `44` | `16` | `92.0 px` (`0.4100`) | 6 poses da fileira 1 (`spawn(4)+idle(2)`) + 6 poses das fileiras 2–3 (`run(6)`) em `VM1-F`; zero magenta/dourado |
| `espreitador_da_fenda` | [`espreitador_da_fenda_atlas_v01.png`](../../../assets/art/runtime/espreitador_da_fenda/espreitador_da_fenda_atlas_v01.png) | `atlas_manifest_v01.json` · `espreitador_da_fenda_frames_v01.tres` | `44` | `16` | `98.0 px` (`0.4200`) | Silhueta em crescente e lâminas de osso `#CFC6B4`/`#E6DFCF`; zero magenta |
| `baluarte_de_cinza` | [`baluarte_de_cinza_atlas_v01.png`](../../../assets/art/runtime/baluarte_de_cinza/baluarte_de_cinza_atlas_v01.png) | `atlas_manifest_v01.json` · `baluarte_de_cinza_frames_v01.tres` | `44` | `16` | `118.0 px` (`0.4600`) | Trapézio maciço com cintas de osso `#CFC6B4`; zero magenta |
| `soberano_do_limiar` | [`soberano_do_limiar_atlas_v01.png`](../../../assets/art/runtime/soberano_do_limiar/soberano_do_limiar_atlas_v01.png) | `atlas_manifest_v01.json` · `soberano_do_limiar_frames_v01.tres` | `44` | `16` | `115.0 px` (`0.4500`) | Forma aliada com coroa selada por anéis de osso e frestas preservadas; zero magenta |
| `chefe_soberano_limiar` | [`chefe_soberano_limiar_atlas_v01.png`](../../../assets/art/runtime/chefe_soberano_limiar/chefe_soberano_limiar_atlas_v01.png) | `atlas_manifest_v01.json` · `chefe_soberano_limiar_frames_v01.tres` | `48` | `26` (`13` `frente34` + `13` `costas34`) | `168.0 px` (`0.5800`) | Retoques aplicados: limpeza de pontos magenta na face (`B1-F` poses 1–2) e recorte integral por célula na pose 12 de `B2-F`/`B2-C` mantendo todos os estilhaços |
| `iniciado_pactos` | [`iniciado_pactos_atlas_v01.png`](../../../assets/art/runtime/iniciado_pactos/iniciado_pactos_atlas_v01.png) | `atlas_manifest_v01.json` · `iniciado_pactos_frames_v01.tres` | `44` | `8` (`idle`, `virote`, `chamado`, `troca` × 2 vistas) | `94.0 px` (`0.4087`) | Frestas internas do arco da Besta do Vínculo limpas por chaveamento |

Além dos atores, as 8 peças de `W0` (`wep_pecas_doutrinas_raw_v01.jpg`) foram empacotadas em `assets/art/runtime/pecas_doutrinas/`:
- `emblema_lamina.png`, `emblema_ressonancia.png`, `emblema_pactos.png`, `virote_vinculo.png`, `pulso_ressonante.png`, `projetil_anomalia.png`, `marca_virote.png`, `indicador_atracao.png`.

---

## 2. Silhuetas de HUD e Retratos da Escolha do Pacto (`assets/art/ui/maldicoes/`)

Extraídos de `U4` (`ui_maldicoes_silhuetas_retratos_raw_v01.jpg`) com verificação automática de paleta garantindo **ZERO pixels magenta (`#E0259C`)** (regra ML-V1):

- **Silhuetas `72×72` (Slot Primário a 100%) e `56×56` (Slot Secundário a 100%):**
  - `silhueta_vulto_mudo_72.png` (`72×72`), `silhueta_vulto_mudo_56.png` (`56×56`)
  - `silhueta_espreitador_da_fenda_72.png` (`72×72`), `silhueta_espreitador_da_fenda_56.png` (`56×56`)
  - `silhueta_baluarte_de_cinza_72.png` (`72×72`), `silhueta_baluarte_de_cinza_56.png` (`56×56`)
  - `silhueta_soberano_do_limiar_72.png` (`72×72`), `silhueta_soberano_do_limiar_56.png` (`56×56`)
  - `silhueta_generica_72.png` (`72×72`), `silhueta_generica_56.png` (`56×56`)
- **Retratos de Busto para a Carta de Escolha do Pacto:**
  - `retrato_vulto_mudo.png` (`295×367`)
  - `retrato_espreitador_da_fenda.png` (`313×367`)
  - `retrato_baluarte_de_cinza.png` (`296×367`)
  - `retrato_soberano_do_limiar.png` (`296×367`)

---

## 3. Sign-Off da Direção de Arte e Técnica

- **Art Director (`art-director`):** Aprovado. As 4 espécies aliadas e seus ícones/retratos respeitam integralmente a restrição de paleta de Pactos (tinta `#0D0E14`, ardósia `#2B3240`/`#5C6678` e selos de osso `#CFC6B4`/`#E6DFCF`, sem nenhum pixel magenta), enquanto o Chefe Soberano do Limiar contrasta imediatamente pela coroa e fenda peitoral abertas em Magenta `#E0259C`.
- **Technical Artist (`technical-artist`):** Aprovado. Todos os 11 atores passam na validação estrutural e matemática (`ALL_RUNTIME_ATLASES_OK actors=11`).

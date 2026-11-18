# Evidência de Arte e Sign-Off — LUT do Limiar, Cartas, Glifos, HUD e Cenário (`story-008`)

> **Story:** [`production/epics/assets-e-conteudo/story-008-lut-por-regiao-e-arte-de-ui.md`](../../epics/assets-e-conteudo/story-008-lut-por-regiao-e-arte-de-ui.md)
> **Data:** 2026-11-18
> **Responsáveis:** `art-director` (Direção Visual e Sign-Off) · `technical-artist` (Geração de LUT 3D, Recorte de UI/Cenário e Configuração de Import)
> **Status:** APROVADO (PASS)

---

## 1. Textura LUT 3D `32³` do Limiar (`assets/art/lut/`)

- **Arquivo:** [`assets/art/lut/limiar.png`](../../../assets/art/lut/limiar.png) (`1024×32 px`, PNG 24-bit lossless, desenrolada em 32 fatias horizontais de `32×32`).
- **Curva de Grading:** Aplica resfriamento sutil de ardósia (`#141821`) nos meios-tons e sombras neutras de cenário, com máscara de proteção cromática que preserva 100% da integridade dos tons semânticos de **Magenta (`#E0259C`)**, **Ouro Ritual (`#E3B23C`)** e **Osso (`#E6DFCF` / `#CFC6B4`)**.
- **Configuração de Importação (Perfil P4 — ADR-0011 §6):** [`assets/art/lut/limiar.png.import`](../../../assets/art/lut/limiar.png.import) configurado com:
  - `compress/mode=0` (Lossless)
  - `mipmaps/generate=false`
  - `roughness/mode=0`
  - `detect_3d/compress_to=0` e sem `source_color`.

---

## 2. Arte de Cartas de Bênção (`assets/art/ui/cartas/` — Folha `U1`)

Recortada com flood-fill exclusivamente a partir da borda externa, preservando o fundo interno em tinta `#0D0E14`:
- `moldura_comum.png` (`320×500 px`)
- `moldura_rara.png` (`320×500 px`)
- `moldura_epica.png` (`320×500 px`)
- `verso_carta.png` (`320×500 px`)
- `selo_preco.png` (`274×89 px` — tarja *"A Beira Cobra"* com talho em magenta `#E0259C`)
- `coroa_lamina.png` (`302×155 px`)
- `coroa_ressonancia.png` (`249×169 px`)
- `coroa_pactos.png` (`256×169 px`)

---

## 3. Glifos de Tradições, Slots e Status (`assets/art/ui/glifos/` — Folha `U2`)

12 medalhões recortados das 2 fileiras de `U2` (em disco de tinta `#0D0E14` com alto contraste para leitura em `32×32 px`):
- **Tradições:** `traco_unico.png`, `corte_fantasma.png`, `fundo_do_poco.png`, `linha_contada.png`, `materia_residual.png`, `os_que_ficam.png`.
- **Slots de Ganho:** `slot_ataque.png` (osso `#E6DFCF`), `slot_especial.png` (ouro `#E3B23C`), `slot_selo.png` (magenta `#E0259C`).
- **Efeitos de Status:** `status_sangramento.png`, `status_queimadura.png`, `status_abalo.png`.

---

## 4. Componentes do HUD (`assets/art/ui/hud/` — Folha `U3`)

8 conjuntos recortados com remoção tanto do verde externo quanto dos vãos verdes internos das peças vazadas:
- `placa_fundo.png`, `segmentos_vida.png`, `moldura_vida_baixa.png`, `recusa_escudo.png`, `gota_fluxo.png` (entalhe de 40%), `chevrons_esquiva.png`, `icone_fragmento.png`, `barra_chefe.png` (entalhe central de 50% de Fúria).

---

## 5. Kit de Cenário Pintado do Limiar (`assets/art/environment/limiar/` — Folhas `C1`, `C2`, `C3`)

22 peças modulares em ardósia fria (`L* 18–38`) sem geometria proibida de telégrafos no piso:
- **Lajes e Bordas (`C1` — 8 peças):** `chao_laje_01..04.png`, `borda_parede_01..04.png`.
- **Obstáculos, Pilar do Chefe e Santuário (`C2` — 6 peças):** `obstaculo_rocha_01..03.png`, `obstaculo_coluna_04.png`, `pilar_chefe.png`, `altar_santuario.png`.
- **Portas, Totens de Recompensa e Primeiro Plano (`C3` — 8 peças):** `porta_fechada.png`, `porta_aberta.png` (vão central `#0D0E14` preservado), `porta_chefe.png`, `pedestal_pacto.png`, `totem_bencao.png`, `totem_fragmentos.png`, `totem_cura.png`, `foreground_silhueta.png`.

---

## 6. Sign-Off da Direção de Arte e Técnica

- **Art Director (`art-director`):** Aprovado contra a [Art Bible](../../../design/art/art-bible.md) (§3.4, §4.2, §7.5, §7.8) e GDDs de HUD e Tela de Bênção.
- **Technical Artist (`technical-artist`):** Aprovado contra o ADR-0011 (orçamento de UI ≤ 80 draw calls, LUT P4 lossless sem mipmaps).

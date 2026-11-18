# Evidência de Arte e Sign-Off — Lote 02: Inimigos do Limiar e Peças de Elite (`story-006`)

> **Story:** [`production/epics/assets-e-conteudo/story-006-arte-lote-02-inimigos-do-limiar.md`](../../epics/assets-e-conteudo/story-006-arte-lote-02-inimigos-do-limiar.md)
> **Data:** 2026-11-18
> **Responsáveis:** `art-director` (Direção Visual e Sign-Off) · `technical-artist` (Empacotamento Runtime e Validação)
> **Status:** APROVADO (PASS)

---

## 1. Escopo Validado

| Ator / Pacote | Diretório Runtime | Quadros (`400×400`) | Animações | Escala / Tamanho Lógico | Status |
|---|---|---|---|---|---|
| **Eco Perdido** (`eco_perdido`) | `assets/art/runtime/eco_perdido/` | `44` (`3200×2400`) | `16` (`8` `frente34` + `8` `costas34`) | `96.0 px` (`scale: 0.4174`) | Validado |
| **Anomalia Menor** (`anomalia_menor`) | `assets/art/runtime/anomalia_menor/` | `44` (4 folhas) | `16` (`8` `frente34` + `8` `costas34`) | `90.0 px` | Validado |
| **Fenda Errante** (`fenda_errante`) | `assets/art/runtime/fenda_errante/` | `44` (`3200×2400`) | `16` (`8` `frente34` + `8` `costas34`) | `110.0 px` (`scale: 0.4400`) | Validado |
| **Peças de Elite (`X0`)** (`elite_pecas`) | `assets/art/runtime/elite_pecas/` | `6` (`1200×800`) | `6` (`3` coroas + `3` placas) | `scale: 0.135–0.250` | Validado |

---

## 2. Verificação Técnica (`validate_runtime_atlases.gd` & ADR-0011)

- **Canvas e Pivô:** Todas as células seguem o padrão canônico de `400×400 px` com pivô de contato no chão em `[200, 320]` e margem mínima superior a `6 texels` em todas as bordas.
- **Saída do Validador:**
  - `VALIDATED_ATLAS actor=anomalia_menor frames=44 animations=16`
  - `VALIDATED_ATLAS actor=eco_perdido frames=44 animations=16`
  - `VALIDATED_ATLAS actor=fenda_errante frames=44 animations=16`
  - `VALIDATED_ATLAS actor=elite_pecas frames=6 animations=6`
- **Evidências Visuais e Capturas Retidas:**
  - [`production/qa/evidence/integracao-jogavel/combate-real.png`](integracao-jogavel/combate-real.png)
  - [`production/qa/evidence/integracao-jogavel/jogo.png`](integracao-jogavel/jogo.png)

---

## 3. Sign-Off da Direção de Arte e Técnica

- **Art Director (`art-director`):** Aprovado contra a [Art Bible](../../../design/art/art-bible.md) (§2 Gramática de Formas, §3 Paleta Semântica de Perigo em Magenta `#E0259C` e Ouro Ritual `#E3B23C` para Coroas de Elite, §5.5 ausência de sombra de contato nos Ecos).
- **Technical Artist (`technical-artist`):** Aprovado contra o orçamento de memória e draw calls do ADR-0011.

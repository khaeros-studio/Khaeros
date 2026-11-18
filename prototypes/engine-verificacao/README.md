<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Verificação de engine (EX-*) — protótipos descartáveis

**Hipótese**: os itens NOT SOURCEABLE / NEEDS VERIFICATION dos ADRs (0001, 0002, 0004, 0007, 0009, 0010, 0013) se comportam no Godot 4.7.2 como os ADRs supõem.

**Status**: concluído em 2026-11-16 no binário do editor; a rodada no build exportado (`.exe`) fica pendente porque os templates de exportação 4.7.2 não estão instalados. O `.pck` foi exportado com `--export-pack` e executado com `--main-pack`.

| Pasta | Experimentos | Como rodar | Evidência |
|---|---|---|---|
| `passo-e-quadro/` | EX-0001-1, -2, -6 | `godot --path passo-e-quadro -- --modo=ordem\|atraso\|arrasto` (+ `mover_janela.ps1`) | `production/qa/evidence/experimentos/ex-0001-passo-e-quadro.md` |
| `catalogo/` | EX-0004-NV | `godot --headless --path catalogo --script probe.gd -- --modo=gerar\|tudo\|carga\|hash` | `.../ex-0004-nv-catalogo.md` |
| `cena/` | EX-0007-NV | `godot --path cena [-- --sem-interp]` (+ `captura.ps1`) | `.../ex-0007-nv-cena.md` |
| `eventos-e-aritmetica/` | EX-0002-1..3, EX-0009-1, EX-0010-1 | `godot --headless --path eventos-e-aritmetica --script probe.gd`; `probe_extra.gd`; `godot --path eventos-e-aritmetica [-- --vsync]` | `.../ex-0002-eventos.md`, `ex-0009-float64.md`, `ex-0010-latencia.md` |
| `persistencia/` | EX-0013-P1..P7 | `godot --headless --path persistencia --script probe.gd -- --modo=tudo\|kill_p1\|contar\|kill_p2 --k=N\|inspecionar\|limpar`; `godot --path persistencia -- --shell` e fechar a janela | `.../ex-0013-p1-p7.md` |

Rode `godot --headless --path <pasta> --import` antes da primeira execução.

## Achados principais

- Os padrões de física são 60 ticks e 8 passos máximos por quadro. Os passos de física rodam antes do `_process` do quadro. O loop modal de mover a janela não gera `delta` grande; o maior `delta` é o do 1º quadro (0,14 s).
- O hash SHA-256 canônico é idêntico no editor, no `.pck` e no Python. `CACHE_MODE_IGNORE_DEEP` e `DEEP_DUPLICATE_ALL` funcionam. O CSV `keep` só fica fora do `.pck` se houver `exclude_filter`.
- A interpolação 2D funciona. `reset_physics_interpolation()` tem de vir no mesmo passo do teleporte; sem ela aparecem 2 quadros fantasmas.
- Com 50 ou mais eventos `RefCounted` por passo, o p99 passa de 0,3 ms (debug). `filter()` de array tipado devolve array tipado, o que refuta o que o ADR-0002 diz.
- `float` é binary64. O literal `9007199254740993.0` vira 2^53+2 no tokenizer.
- `frame_post_draw` dispara 1 vez por quadro; o toque→golpe mais lento levou 33,3 ms com vsync a 60 Hz.
- `DirAccess.rename` no Windows apaga o destino antes de mover, então não é atômico. Por isso a sequência `.old` é necessária. `ConfigFile.parse` aceita lixo binário como vazio.

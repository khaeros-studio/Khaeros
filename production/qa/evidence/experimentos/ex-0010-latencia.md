# EX-0010-1 — `RenderingServer.frame_post_draw` e latência toque→golpe (evidência)

- **Data**: 2026-11-16 · **Engine**: Godot 4.7.2.stable.official.ed1daf0bf, binário do editor, janela real, `gl_compatibility` · **Máquina**: Ryzen 5 5600H, monitor interno 60 Hz (`screen_get_refresh_rate()` = 60), Windows 11
- **Protótipo**: `prototypes/engine-verificacao/eventos-e-aritmetica/latencia.gd` + `latencia.tscn` (cena principal do projeto)

## Método

1. Ação `golpe` registrada em runtime (tecla J física).
2. Em `_process`, em quadros variados (intervalo de 7–11 quadros), um `InputEventKey` sintético é injetado com `Input.parse_input_event` e o instante `t_toque` é gravado com `Time.get_ticks_usec()`.
3. Em `_physics_process`, `Input.is_action_just_pressed(&"golpe")` aplica o "golpe": troca a cor de um `ColorRect` (mudança visual) e conta os passos desde o toque.
4. No primeiro `RenderingServer.frame_post_draw` depois do golpe, a latência é `agora − t_toque`. A tecla é solta logo depois.
5. Cada `_process` também conta quantos `frame_post_draw` houve desde o anterior.

Reproduzir: `godot --path prototypes/engine-verificacao/eventos-e-aritmetica` (vsync off, `max_fps` 144) e `... -- --vsync`.

## Resultados (40 amostras cada)

| Modo | Média | Mediana | p95 | Máx | Mín | Passos até o golpe | `frame_post_draw` por quadro |
|---|---|---|---|---|---|---|---|
| vsync off, 144 fps | 14,49 ms | 15,15 ms | 22,07 ms | 22,13 ms | 8,00 ms | 1 em 40/40 | `{1: 485}` |
| vsync on, 60 Hz | 33,12 ms | 33,14 ms | 33,28 ms | **33,33 ms** | 32,65 ms | 1 em 40/40 | `{1: 451}` |

- `frame_post_draw` disparou **exatamente uma vez por quadro** (936 quadros, nenhum com 0 ou 2).
- O golpe acontece sempre no 1º passo de física depois da injeção.
- Pior caso com vsync: 33,3 ms, abaixo do limite de 50 ms (2 passos + 1 quadro).

**Resultado: VERIFICADO.** `frame_post_draw` serve de marco de fim de quadro e a latência medida cabe no AC-92.

Ressalvas:
- `frame_post_draw` marca o fim do envio do desenho pela CPU, não o scan-out do monitor. A latência até o fóton é maior (fila do driver + varredura) e não foi medida.
- A injeção sintética entra pela fila de input do Godot. O tempo do hardware/SO até o evento chegar não está incluído.
- Monitor de 144 Hz real e template de release: pendentes.

## O que o ADR-0010 precisa mudar

1. Marcar `RenderingServer.frame_post_draw` como VERIFICADO (1 por quadro, depois do desenho) e descrever o método acima para o teste de produção do AC-92.
2. Deixar explícito no AC-92 que a medida vai do "evento na fila do Godot" ao "fim do envio do quadro", excluindo o tempo do periférico e o scan-out.

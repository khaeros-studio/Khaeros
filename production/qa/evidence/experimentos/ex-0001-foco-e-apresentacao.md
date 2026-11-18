# EX-0001-4, EX-0001-5, EX-0012-E3 — foco, pausa própria e apresentação (evidência, story-003)

- **Data**: 2026-11-16
- **Engine**: Godot 4.7.2.stable.official.ed1daf0bf, janela real (`gl_compatibility`), Windows 11 Home 10.0.26300.
- **Protótipo**: `prototypes/engine-verificacao/foco-e-apresentacao/` (`foco.gd`; `driver.ps1` gera perda/ganho de foco e o clique por `ShowWindow`, `keybd_event` e `mouse_event` — **input injetado no SO**, não mouse/teclado físicos).
- **Gamepad**: nenhum conectado (`Input.get_connected_joypads()` = `[]`).

## Como reproduzir

```bash
cd prototypes/engine-verificacao/foco-e-apresentacao
godot --headless --path . --import
powershell -NoProfile -ExecutionPolicy Bypass -File driver.ps1 &   # em paralelo
godot --path .
```

## EX-0001-4 — o que anima com a flag própria (sem `SceneTree.paused`)

Fases de 0,7 s; todos os nós filhos de um `Node2D` "_box". Partículas medidas por pixels alterados num quadrado 120×120 da captura.

| Fase | Tween dx | AnimationPlayer Δpos | AnimatedSprite2D trocas | Audio Δpos | GPU px | CPU px |
|---|---|---|---|---|---|---|
| 0 normal | 70,05 | 0,700 | 14 | avança (loop de 1 s) | 14 | 6 |
| 1 só a flag `pausado_proprio` | 13,70 | 1,300* | 14 | 0,702 | 15 | 6 |
| 2 parada explícita | **0** | **0** | **0** | **0** | **0** | **0** |
| 3 retomado | 39,78 | 0,705 | 14 | avança | 15 | 6 |
| 4 `_box.process_mode = DISABLED` | **0** | **0** | **0** | 0,012 (resíduo) | **0** | **0** |
| 5 retomado | 70,51 | 0,705 | 14 | avança | 15 | 6 |

\* posição cruzou o fim do loop; o que importa é ≠ 0.

- **Com só a flag, todos os seis tipos seguem animando** (esperado: a flag é nossa).
- Parada explícita que funcionou: `Tween.pause()`/`play()`; `AnimationPlayer.speed_scale = 0`; `GPUParticles2D.speed_scale = 0`; `CPUParticles2D.speed_scale = 0`; `AnimatedSprite2D.speed_scale = 0`; `AudioStreamPlayer.stream_paused = true`. Retomada volta ao normal.
- `process_mode = PROCESS_MODE_DISABLED` no pai **também** congela os seis (inclusive GPU particles e o áudio, que fica pausado e retoma do ponto). É um meio único e mais simples, sem `SceneTree.paused`.

**EX-0001-4: VERIFICADO** (os dois meios funcionam).

## EX-0001-5 — notificações de foco

Ordem medida (t em ms desde o início), repetida em minimizar/restaurar e em Alt+Tab ida/volta:

- Perda: `NOTIFICATION_APPLICATION_FOCUS_OUT` (2017) → ~10–30 ms → `NOTIFICATION_WM_WINDOW_FOCUS_OUT` (1005) → `Window.focus_exited`.
- Ganho: `NOTIFICATION_APPLICATION_FOCUS_IN` (2016) → ~20–30 ms → `NOTIFICATION_WM_WINDOW_FOCUS_IN` (1004) → `Window.focus_entered`. No restaurar após minimizar, `WM_WINDOW_FOCUS_IN` chegou **duas vezes** (9170 e 9208 ms).
- As quatro chegam ao **nó raiz da cena** (`Node2D`, via `_notification`). Durante `APPLICATION_FOCUS_IN`, `get_window().has_focus()` ainda é false.
- `application/run/pause_on_focus_loss`: **não existe** no 4.7.2 (`ProjectSettings.has_setting` = false; ausente do `--doctool`). Nada a gravar. Ajuste correlato existente: `input_devices/joypads/ignore_joypad_on_unfocused_application` (padrão false).

**EX-0001-5 (foco): VERIFICADO.** Usar `NOTIFICATION_APPLICATION_FOCUS_OUT` para `pedir_estado(PAUSA)` (é o primeiro e único por troca; `WM_WINDOW_FOCUS_IN` pode repetir), idempotente.

## EX-0001-5 — desconexão do gamepad

**NÃO RODADO — sem hardware** (nenhum gamepad). API confirmada no `--doctool`: `Input.joy_connection_changed(device: int, connected: bool)`; o protótipo já registra o sinal. Pendente: conectar/desconectar um gamepad ativo e um segundo, rodando `godot --path .` neste protótipo.

## EX-0012-E3 — clique que devolve o foco

| Cenário | Resultado |
|---|---|
| Alt+Tab (teclado injetado) | foco volta sem nenhum `InputEventMouseButton` (só as notificações) |
| Clique em janela sem foco (janela posta por cima com `SWP_NOACTIVATE`, `mouse_event` injetado) | `APPLICATION_FOCUS_IN` t=14068 → `WM_WINDOW_FOCUS_IN` 14089 → `focus_entered` 14096 → **`InputEventMouseButton pressed=true` 14114** → `pressed=false` 14126 |

O clique de ativação **chega** como `InputEventMouseButton`, **depois** de `APPLICATION_FOCUS_IN` (~46 ms). **E3: VERIFICADO com input injetado** → a **barreira de retorno do ADR-0012 é necessária** (descartar o clique que acompanha o ganho de foco). Confirmação com mouse físico e gamepad físico: pendente (execução manual do usuário).

## O que os ADRs precisam mudar

- **ADR-0001**: (4) a Apresentação para por `process_mode = PROCESS_MODE_DISABLED` no nó-raiz da apresentação ou pelos meios por tipo listados; ambos medidos. (5) Gatilho de pausa = `NOTIFICATION_APPLICATION_FOCUS_OUT` no `Main`; remover `pause_on_focus_loss` (não existe). `WM_WINDOW_FOCUS_IN` pode chegar repetido: tratar ganho de foco como idempotente. Gamepad: pendente de hardware.
- **ADR-0012**: E3 confirmado → manter a barreira de retorno: abrir em `APPLICATION_FOCUS_IN` e descartar o par press/release de mouse seguinte (chegou ~46 ms depois).

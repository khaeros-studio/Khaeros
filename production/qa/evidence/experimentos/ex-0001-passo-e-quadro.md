# EX-0001-1, -2, -6 — passo e quadro (evidência)

- **Data**: 2026-11-16
- **Engine**: Godot 4.7.2.stable.official.ed1daf0bf (build padrão, não .NET), binário do editor rodando o projeto (`godot --path .`), janela real (renderer `gl_compatibility`, vsync desligado, `max_fps` 0). `OS.is_debug_build()` = true.
- **Máquina**: AMD Ryzen 5 5600H, Radeon integrada + RTX 3050 Laptop, Windows 11 Home 10.0.26300.
- **Protótipo**: `prototypes/engine-verificacao/passo-e-quadro/` (`passo_e_quadro.gd`, modos `ordem`, `atraso`, `arrasto`; `mover_janela.ps1` para o EX-0001-6). O `project.godot` do protótipo não declara os valores de física, de propósito.
- **Build exportado**: NÃO executado. A pasta `%APPDATA%\Godot\export_templates\` está vazia (nenhum template 4.7.2 instalado) e o repositório não tem `export_presets.cfg`. Toda a coluna "export" fica pendente.

## Como reproduzir

```bash
cd prototypes/engine-verificacao/passo-e-quadro
godot --headless --path . --import
godot --path . -- --modo=ordem
godot --path . -- --modo=atraso
godot --path . -- --modo=arrasto &   # e, em paralelo:
powershell -NoProfile -ExecutionPolicy Bypass -File mover_janela.ps1
```

## EX-0001-1 — padrões e quadro atrasado

Valores lidos com o `project.godot` sem declaração (log `EX|PS ...` e `EX|Engine ...`):

| Ajuste | Valor padrão no 4.7.2 |
|---|---|
| `physics/common/physics_ticks_per_second` | **60** |
| `physics/common/max_physics_steps_per_frame` | **8** |
| `physics/common/physics_jitter_fix` | 0.5 |
| `physics/common/physics_interpolation` | false |

Quadro atrasado com `OS.delay_msec` dentro de `_process`, 5 repetições cada; medido no quadro seguinte:

| Atraso | `_physics_process` no quadro seguinte | `delta` de `_process` no quadro seguinte |
|---|---|---|
| 50 ms | 3, 3, 2, 2, 3 | 0.0522, 0.0432, 0.0438, 0.0439, 0.0395 |
| 100 ms | 5, 6, 5, 6, 5 | 0.0898, 0.1018, 0.0878, 0.1023, 0.0891 |
| 250 ms | **8, 8, 8, 8, 8** (teto) | 0.1441, 0.1493, 0.1270, 0.1273, 0.1358 |

Observações:
- Com 250 ms o número de passos para no teto `max_physics_steps_per_frame` = 8 (≈ 133 ms de jogo); o resto do atraso não vira passo naquele quadro. O `delta` de `_process` não é o tempo de parede: é sincronizado pelo `physics_jitter_fix` com os passos rodados (0,04 s para 50 ms; 0,13–0,15 s para 250 ms).
- Com o `physics_jitter_fix` 0.5, um atraso de 40 ms isolado (modo `ordem`) gerou só 1 passo no quadro seguinte: a engine espalha a dívida. O orquestrador não pode presumir "passos = atraso / 16,7 ms".
- O **primeiro quadro** da execução teve `delta` 0.13–0.14 s com 7–8 passos (três execuções), acima do `dt_max_apres` 0,1 s.

**Resultado EX-0001-1: CONFIRMADO (editor).** Valores a gravar no `project.godot` principal: `physics_ticks_per_second=60` e `max_physics_steps_per_frame=8` (os padrões medidos, declarados explicitamente). Export: pendente.

## EX-0001-2 — ordem `_physics_process` × `_process`

100 quadros (frames de processo 19–118) registrando `P<frame>` em `_physics_process` e `R<frame>(n=passos)` em `_process`, com `Engine.get_process_frames()`. Histograma de passos por quadro: `{0: 71, 1: 28, 3: 1}` (0, 1 e 2+ cobertos; 2+ também no modo `atraso`, até 8). Trecho:

```
P20 P20 P20 R20(n=3) R21(n=0) R22(n=0) ... P26 R26(n=1) R27(n=0) ...
```

Violações (algum `P<f>` depois de `R<f>` do mesmo quadro): **0**. Todos os passos de física do quadro rodam antes do `_process` daquele quadro; quadros com 0 passos chamam só `_process`.

**Resultado EX-0001-2: CONFIRMADO (editor).** Export: pendente (mesmo binário de main loop; risco baixo, mas não medido).

## EX-0001-6 — primeiro quadro depois de mover a janela

Execução de 14 s; aos ~3 s o `mover_janela.ps1` posta `WM_SYSCOMMAND/SC_MOVE` na janela (o mesmo loop modal de mover do Windows que o arrasto com mouse usa, aqui no modo teclado), move 20 vezes com seta direita a cada 100 ms e encerra com Enter (~3,5 s dentro do loop modal).

| Execução | Quadros em 14 s | Maior `delta` | Quadros com `delta` > 0,05 s ou > 2 passos |
|---|---|---|---|
| Sem mover | 16 097 / 16 040 | 0.1333 / 0.1426 | só o 1º quadro |
| Com loop modal de mover | 11 908 | 0.1316 | só o 1º quadro |

A queda de ~4 000 quadros mostra que o loop modal estava ativo, mas o Godot 4.7.2 continuou iterando durante ele: nenhum quadro depois do inicial passou de 0,05 s nem de 2 passos. Não houve o "quadro gigante" pós-arrasto que o ADR temia.

**Resultado EX-0001-6: CONFIRMADO, com ressalva.** `dt_max_apres` 0,1 s cobre o mover (nenhum delta pós-mover > 0,05 s). Ressalvas: (a) o arrasto com mouse físico não foi feito (ambiente sem operador); o `SC_MOVE` usa o mesmo loop modal, mas um arrasto manual de 5 s fica como verificação manual recomendada; (b) o maior `delta` real é o do **primeiro quadro** (0,13–0,14 s), que o clamp de 0,1 s corta. Isso precisa constar no ADR.

## O que o ADR-0001 precisa mudar (aplicar pelo lead-programmer)

1. VR(1): fixar `physics_ticks_per_second=60` e `max_physics_steps_per_frame=8` no `project.godot` (padrões medidos). Registrar que o `delta` de `_process` é suavizado pelo `physics_jitter_fix` (0.5 padrão) e que um quadro lento não produz `atraso/16,7` passos; com 250 ms o teto 8 descarta tempo.
2. VR(2): ordem confirmada — passos de física do quadro antes do `_process`; 0 passos é comum (71 % dos quadros sem vsync a ~1 100 fps).
3. VR(6): o loop modal de mover a janela não gera `delta` grande; o maior `delta` vem do 1º quadro (≈ 0,14 s) — o clamp `dt_max_apres` 0,1 s deve valer desde o 1º quadro.
4. Linha "export" dos três itens: pendente até instalar os templates 4.7.2 e criar o preset Windows.

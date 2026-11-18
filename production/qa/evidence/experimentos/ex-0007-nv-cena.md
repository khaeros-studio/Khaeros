# EX-0007-NV — interpolação 2D, teleporte e pillarbox (evidência)

- **Data**: 2026-11-16 · **Engine**: Godot 4.7.2.stable.official.ed1daf0bf, binário do editor, janela real, `gl_compatibility` · **Máquina**: Ryzen 5 5600H, Windows 11
- **Protótipo**: `prototypes/engine-verificacao/cena/` (`cena.gd`, `cena.tscn`, `captura.ps1`). `project.godot`: 640×360, stretch `canvas_items` / aspect `keep` / scale `fractional`, `physics_ticks_per_second=60`, `physics_interpolation=true`, vsync off, `Engine.max_fps=144`.
- **Método**: um `Sprite2D` 16×16 branco anda 3 px por passo em `_physics_process`. A cada quadro, em `RenderingServer.frame_post_draw`, o script lê a textura do viewport e acha a coluna do primeiro pixel branco na linha 180: é a posição **desenhada**, não a do nó. Log no formato `passo:x_desenhado`.
- **Ressalva de hardware**: `DisplayServer.screen_get_refresh_rate()` = **60 Hz** nesta máquina (a tela do notebook não é 144 Hz). O caso "monitor de 144 Hz" foi emulado com `max_fps=144` e vsync off (144 quadros/s desenhados com passo de 60 Hz). Em monitor 144 Hz real com vsync: pendente.

Reproduzir: `godot --path prototypes/engine-verificacao/cena` (interpolação ligada) e `... -- --sem-interp` (sprite com `physics_interpolation_mode = OFF`).

## (a) Interpolação com passo 60 Hz e quadro a 144/s

| Modo | Amostra (passo:x) | Leitura |
|---|---|---|
| Interpolação ligada | `17:69 17:71 18:72 18:73 19:74 19:76 19:77 20:78 20:79 21:81 ...` | x muda **a cada quadro** (1–2 px), sem repetição: movimento contínuo |
| Sprite com interpolação OFF | `16:68 16:68 17:71 17:71 18:74 18:74 19:77 19:77 19:77 ...` | x repete 2–3 quadros e salta 3 px: degrau (judder) |

**VERIFICADO**: `physics/common/physics_interpolation=true` interpola `Sprite2D` 2D no 4.7.2; `Node.physics_interpolation_mode` desliga por nó. O desenho fica ~1 passo atrás do estado (esperado da interpolação).

## (b) Teleporte e `reset_physics_interpolation()`

Teleporte de x≈617 para x=20 dentro de `_physics_process`:

| Caso | Quadros desenhados em torno do teleporte |
|---|---|
| Sem reset | `199:617 |TELEPORTE| 200:426 200:177 201:20 ...` — **2 quadros fantasmas** (426 e 177) varrendo a tela |
| Com `reset_physics_interpolation()` logo depois de atribuir a posição, no mesmo `_physics_process` | `259:196 |TELEPORTE| 260:20 260:20 260:20 261:21 ...` — sem fantasma |
| Interpolação OFF (controle) | `199:617 |TELEPORTE| 200:20 ...` |

**VERIFICADO**: o momento certo é no mesmo passo, **depois** de escrever a posição nova. Sem o reset, o teleporte aparece como risco atravessando a tela por 1 passo.

## (c) Pillarbox em runtime (`canvas_items` + `keep` + `fractional`)

| Janela (`window_set_size`) | `get_final_transform()` | Textura do viewport | Leitura |
|---|---|---|---|
| 1000×360 | escala 1,0; origem (180, 0) | 640×360 | barras laterais de 180 px (pillarbox) |
| 640×600 | escala 1,0; origem (0, 120) | 640×360 | barras em cima/embaixo (letterbox) |
| 1366×768 | escala 2,1328 × 2,1333; origem (1, 0) | 1365×768 | escala fracionária; 1 px de sobra arredondada |

Captura de tela da janela de 1000×360: `production/qa/evidence/experimentos/ex-0007-pillarbox-1000x360.png`. A cor de fundo do protótipo é preta, então as barras não se distinguem da área de jogo na imagem; a prova numérica é a origem (180, 0) da `final_transform`.

**VERIFICADO**: o pillarbox se reajusta em runtime, 10 quadros depois do `window_set_size`, sem código próprio. Em 1366×768 a escala fracionária não é idêntica nos dois eixos (2,1328 × 2,1333) e sobra 1 px.

## O que precisa mudar (ADR-0007 / architecture.md)

1. Marcar interpolação 2D e `reset_physics_interpolation()` como verificados. Regra: todo teleporte (spawn, reposicionamento de câmera, troca de sala) chama `reset_physics_interpolation()` no mesmo passo, depois da posição nova.
2. Pillarbox: confirmado com `canvas_items`/`keep`/`fractional`; anotar a escala não uniforme e a sobra de 1 px em 1366×768 (pixel art pode pedir `integer` ou tratamento próprio — decisão do ADR-0007).
3. Pendente: monitor de 144 Hz real com vsync.

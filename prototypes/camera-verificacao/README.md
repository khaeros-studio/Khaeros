# Experimento de cena, viewport e câmera

Experimento descartável para ADR-0007. `.gdignore` isola a pasta do projeto
principal. Nenhum código ou configuração de produção é alterado.

## Executar

Na raiz do repositório, em PowerShell:

```powershell
$cameraProbeLog = Join-Path $env:TEMP 'khaeros-camera-probe.log'
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --log-file $cameraProbeLog --path 'prototypes/camera-verificacao' --script main.gd
```

Resultado em 2026-11-14: Godot `4.7.2.stable.official.ed1daf0bf`,
`RESULT checks=67 failures=0`, saída 0.

## Evidência obtida

- Oito tamanhos do AC-02: cálculo de largura lógica, escala e origem das
  faixas, confrontado também com `Window.get_visible_rect()` e
  `get_final_transform()` reais. O experimento escreve as propriedades nativas
  e lê as transformações; não usa screenshots.
- A política tem três faixas: abaixo de 16:9, `KEEP` e 1920×1080; entre 16:9
  e 43:18 inclusive, `KEEP_HEIGHT` e 1920×1080; acima de 43:18, `KEEP` e
  2580×1080. Em 3840×1080 a engine produz origem (630,0); em 1440×1080,
  origem (0,135), escala 0,75 e vista lógica 1920×1080.
- F6 com clamping do cursor às bordas, conversão via inversa de `Transform2D`
  e vetor bruto do AC-37 a partir da posição física atual. A inversa da
  transformação final com zoom/chute altera a mira, confirmando a necessidade
  de uma conversão base separada.
- F2: lookahead de mouse, intensidade analógica, redução de movimento e mira
  automática; limite e monotonicidade em 360 direções e distâncias 0–2000.
- F3/F4: meia-vida, duas fatias de tempo equivalentes, relógio parado, ausência
  de overshoot, limites e centralização nas câmaras pequena/grande.
- F5: pesado (6,-2), decaimento do zoom, redução de movimento, tremor zero
  preservando zoom, combinação de intro/impacto, teto do deslocamento e
  limiar de descarte do leve. Ruído fixo injetado, sem RNG.
- F7: deriva (104,62), (8,8) e deslocamento ancorado (-96,0).
- Interpolação manual (2,5;0), colapso dos dois extremos num teleporte;
  propriedade de interpolação de física ligada, câmera com modo `OFF`,
  chamada `reset_physics_interpolation()` e fração da engine dentro de [0,1].
- Propriedades de camadas e ordem de irmãos aceitas pela engine. Com
  `canvas_transform` de translação (-100,-50), `CanvasLayer` seguindo o viewport
  em escala 1,2 apresenta **base escalada 1,2 e translação ainda (-100,-50)**.
  Portanto essa propriedade sozinha não implementa o deslocamento de F7.
  `follow_viewport_enabled=false` conserva a transformação da camada de tela
  em identidade. Um `Node2D` com deslocamento manual (-96,0), z=10 e
  interpolação desligada aceita a configuração proposta para primeiro plano.
- As propriedades explícitas de scroll de `Parallax2D` existem e são
  configuráveis; seu modo de interpolação padrão é `OFF`. Isso é comparação
  de alternativa, não adoção desse nó no projeto.
- Fixture de transação de corte: conserva câmera antiga antes de metade do
  wipe, corta/zera impulsos e baseline do relógio juntos no quadro central,
  executa uma vez. É uma simulação local, não o orquestrador de produção.

## Limites

Não há validação visual, screenshots, backend gráfico real, custo de desenho,
ordem visual do y-sort ou de CanvasLayers, sangria/oclusão, interpolação de
sprites a 144 Hz, colisão, suavidade percebida, entrada de mouse real, DPI ou
fullscreen. A ordenação de irmãos só confere índices, não pixels desenhados.
As transformações de janela são verificadas headless; o callback
`size_changed` e sua integração com a câmera não são exercitados.

As funções são fixtures matemáticas independentes, não uma câmera completa.
Não cobrem integração Input/Cena, origem de `InputEvent.position` sob stretch,
conversão entre coordenadas lógicas e de janela, relógio real do orquestrador,
filtros dos estados Pausa/Bênção/Morte, retirada de tuning, fila de 16 impulsos,
escala variável por impulso, dois acumuladores `pos`/`pos_seguir`, nem a
sequência real de troca de câmara. O teste de corte não prova esses sistemas.

Expectativas: `design/gdd/cena-3-4-e-camera.md`, R1/R7/R9/R10, F2–F7,
recorte de AC-02/05/06/13/19/21–25/26/30/32/34/36–38. As APIs foram
confrontadas com a referência local e executadas na engine instalada.

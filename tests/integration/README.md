# Testes da integração jogável

Os runners `run_catalog.gd`, `run_gameplay.gd`, `run_input_camera.gd`, `run_app.gd` e `run_ui_flow.gd` exercitam os módulos reais em processos isolados do Godot. `tests/unit/smoke/playable_integration_test.gd` chama esses runners pela suíte gdUnit4 existente, inclusive no CI. Exige saída 0, marcador `failures=0` e ausência de `SCRIPT ERROR`; saída 0 isolada não prova que um script compilou.

Execução individual, a partir da raiz:

```powershell
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/integration/run_gameplay.gd --quit-after 600
```

Suíte usada pelo projeto:

```powershell
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

`capture_playthrough.gd` é uma ferramenta visual separada: abre a cena real, fornece amostras de comandos de um jogador automático e captura combate/resultado. Não altera Vida nem elimina inimigos por fora das regras durante essa partida. **Executar sem `--headless`**:

```powershell
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --windowed --resolution 1280x720 --script tests/integration/capture_playthrough.gd
```

As imagens ficam em `production/qa/evidence/integracao-jogavel/`. A cena principal também aceita `-- --qa-capture=menu`, `jogo`, `pausa`, `bencao`, `morte` ou `vitoria` somente em build de debug. Essas capturas diretas verificam layout, não são prova de alcançar naturalmente o estado. O resultado da partida visual está separado em `resultado-real.png`.

Os testes de gamepad usam eventos sintéticos; não substituem teste com controle físico. A partida automatizada não aprova balanceamento, sensação ou todos os critérios dos 22 GDDs.

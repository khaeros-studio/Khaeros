# EX-0016-A — API de áudio (evidência, story-009)

- **Data**: 2026-11-16
- **Engine**: Godot 4.7.2.stable.official.ed1daf0bf (build padrão), janela real, driver **WASAPI**, `mix_rate` **48000** (o dispositivo, não 44100).
- **Protótipo**: `prototypes/engine-verificacao/audio/` (`gerar.gd` gera `default_bus_layout.tres` e os WAV; `audio_probe.gd` mede com `AudioEffectCapture` no barramento `Efeitos`).
- **Build exportado**: `.pck` por `--export-pack "Windows Desktop"` rodado com o binário do editor (`--main-pack`). Templates 4.7.2 seguem não instalados (mesma ressalva do EX-0004): não cobre o binário de release.
- **Audição humana**: NÃO feita (agente sem ouvidos). O loop foi medido objetivamente (saltos amostra a amostra na captura). Uma escuta de 10 s do `tom_loop.wav` fica recomendada.

## Como reproduzir

```bash
cd prototypes/engine-verificacao/audio
godot --headless --path . --script res://gerar.gd   # idempotente
godot --headless --path . --import
godot --path . -- --modo=tudo
godot --headless --path . --export-pack "Windows Desktop" <tmp>/ex0016.pck && godot --main-pack <tmp>/ex0016.pck -- --modo=bus
```

## Resultados

| # | Item | Medido | Resultado |
|---|---|---|---|
| 1 | `AudioServer.get_bus_index` | `Master`=0, `Musica`=1, `Efeitos`=2, `Interface`=3; `"Inexistente"`=**-1**; `""`=-1. Layout carregado de `res://default_bus_layout.tres` sem declarar nada no `project.godot` (o padrão de `audio/buses/default_bus_layout` é esse caminho) | **VERIFICADO** |
| 2 | `pitch_scale` em tempo real (mesma voz tocando, 441 Hz) | 0,25→113,0 Hz (esp. 110,3); 0,5→221,2 (220,5); 1→439,9/442,3 (441); 2→882,2 (882); 4→1762,0 (1764). Muda sem reiniciar a voz. `pitch_scale = 0.0` → `ERROR: Condition "p_pitch_scale <= 0.0"` e o valor fica 1.0; 8.0 e 20.0 aceitos | **VERIFICADO**. Faixa utilizável: (0, ∞) na API; para tom de telégrafo, 0,25–4 medido com erro < 3 %. Nunca passar 0 |
| 3 | `stream_paused` | Stream de 3 s sem loop: posição 0,758 → 0,769 durante 0,6 s de pausa (resíduo de mixagem), `playing` = **false** durante a pausa; 0,5 s depois de retomar: **1,271** (reinício daria ~0,5). RMS na pausa 0,027 (cauda do buffer já mixado) | **VERIFICADO**, com nota: `playing` lê false enquanto pausado — o pool não pode tratar `playing == false` como "voz livre" se ela estiver `stream_paused` |
| 4 | `volume_db` / `linear_to_db()` | `linear_to_db(1.0)`=0.0; `(0.5)`=**-6.0206**; `(0.25)`=-12.041; `(0.0)`=**-inf** (sem erro). `volume_db = -inf` aceito, RMS medido 0,00000. RMS 1,0 → 0,35353; 0,5 → 0,17682 (razão **0,5002**). `volume_db` lido de volta = valor escrito. Existe também `volume_linear` (lido 0,5012 para -6 dB) | **VERIFICADO** |
| 5 | `default_bus_layout.tres` no build exportado | `.pck`: `bus count=4`, mesmos nomes e `send` → `Master`, `get_bus_index("Inexistente")`=-1 | **VERIFICADO** (pck; release template NÃO RODADO) |
| 6 | Loop por flag de import (WAV) | `.import` com `edit/loop_mode=2` (Forward) e `edit/loop_end=-1` (padrão) → `loop_mode=1` (LOOP_FORWARD), `loop_end=44099`, tocando após 2,1 s de um WAV de 1 s, max salto 0,058 vs 0,029 de seno puro, 2 saltos (1 por emenda, ~2× a inclinação normal: um ponto de amostra perdido; inaudível em princípio). **Armadilha**: `edit/loop_end=44100` (= nº de amostras) ou `loop_end = n` em `AudioStreamWAV` montado em memória → salto **0,39–0,66** por emenda (estalo; o mixador lê além do fim). Controle com emenda ruim (441,25 Hz): 0,37. Sem flag (`loop_mode=0`): para em 1 s | **VERIFICADO** para WAV com `edit/loop_mode=2` e `loop_end` padrão. OGG **NÃO RODADO** (sem codificador Vorbis na máquina) |
| 7 | `AudioStreamPolyphonic` | não usado (ADR) | n/a |

Achado lateral: um `--script` headless também carrega o `default_bus_layout.tres`; a ferramenta que o gera precisa ser idempotente (a 1ª versão duplicou os barramentos).

## O que o ADR-0016 precisa mudar (aplicar pelo dono do ADR)

1. Tabela "Confirmação de API": `get_bus_index` -1, `pitch_scale`, `stream_paused`, `volume_db`, `linear_to_db()`, `default_bus_layout.tres` e loop WAV por import passam a **Confirmada (EX-0016-A, 2026-11-16)**.
2. `pitch_scale` exige > 0: o `AudioTuning` deve validar a faixa do tom (sugestão 0,25–4) e nunca enviar 0.
3. Pool de vozes: voz com `stream_paused = true` reporta `playing == false`; o critério de "voz livre" precisa considerar `stream_paused`.
4. Loop do tom contínuo: WAV com `edit/loop_mode=2` e `loop_end` padrão (-1); **proibir** `loop_end` igual ao nº de amostras. Período do tom com nº inteiro de ciclos no arquivo.
5. `mix_rate` real é o do dispositivo (48 kHz aqui); nada no ADR deve presumir 44,1 kHz.
6. Pendências: OGG loop (se o ADR quiser OGG) e o binário de release (templates).

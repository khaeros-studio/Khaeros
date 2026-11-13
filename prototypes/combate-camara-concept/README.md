<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: o combate de uma camara (Lamina, telegrafo, esquiva) e legivel e justo em Godot a 60 passos/s? -->
<!-- Date: 2026-11-12 -->

# combate-camara-concept

**Status:** concluído. Veredito **PROCEED** (playtest do usuário em 2026-11-13). Código descartável: não migrar para produção.

## Hipótese

Se o jogador anda, ataca com a Lâmina e esquiva lendo o telégrafo no chão, o combate vai parecer justo e com peso (P3, "Reflexo que se lê").
Sinais: (1) todo golpe sofrido teve telégrafo visível por pelo menos 24 passos; (2) a janela de esquiva cobre o disparo no ritmo previsto; (3) o Eco Perdido cai no 3º Corte e o combo congela 12 passos.

## Como rodar (Godot 4.7.2, na raiz do repositório)

Jogar (humano):

```bash
godot --path . --windowed --resolution 1280x720 res://prototypes/combate-camara-concept/main.tscn
```

Controles: WASD andar, mouse mirar, clique esquerdo Corte (segure), clique direito Investida, Espaço esquiva, R reinicia a câmara, F12 salva screenshot em `production/qa/evidence/`. Ao limpar as 3 ondas aparece a tela de bênção (teclas 1, 2, 3 ou clique).

Bot com janela (gera screenshots): acrescente `-- --bot --profile=reativo --seed=3 --tag=nome`.
Lote sem janela: `-- --batch=30 --profile=reativo` (perfis: `reativo`, `perfeito`, `lento`, `nunca_esquiva`; `--bencao=0|1|2` aplica uma bênção).
Cenários determinísticos: `-- --teste`.

Todos os números moram em `data/tuning.json` (fonte: GDDs de Movimento, Combate, Telégrafos, IA e Armas).

## Achados

Ver `REPORT.md` e as evidências em `production/qa/evidence/combate-camara-*`.

# Experimento de movimento e colisão própria

Experimento descartável para ADR-0008. A pasta tem `.gdignore` e roda como
projeto separado. Nenhum arquivo de produção é alterado.

## Executar

Na raiz do repositório, em PowerShell:

```powershell
$movementProbeLog = Join-Path $env:TEMP 'khaeros-movement-probe.log'
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --log-file $movementProbeLog --path 'prototypes/movimento-verificacao' --script main.gd
```

Resultado em 2026-11-14: Godot `4.7.2.stable.official.ed1daf0bf`,
`RESULT checks=51 failures=0`, saída 0.

## Evidência

- Quantização de D/E/R separadamente, zero permitido e mínimo de um passo para
  duração positiva. O caso 0,158 + 0,058 produz 9+3=12; quantizar a soma daria13.
- Nove vetores de caminhada de AC-04 e 60 passos acumulados de AC-03, usando
  `Vector2` da engine e tolerâncias do GDD.
- Colisão própria por círculos, em uma passada na ordem dos dados, seguida de
  clamp ao retângulo encolhido: tangência exata não empurra, penetração0,001
  empurra, centros coincidentes usam normal para cima. Obstáculos A/B dão571
  ou609 conforme sua ordem (AC-29). Layout estreito inválido pode deixar
  sobreposição depois de uma passada.
- Esquiva axial de AC-30: começa em900, vai a922,5 e depois permanece em931
  por oito passos. Pedido de apoio10,5px de AC-58 também resolve colisão.
- F5 compara distância ao quadrado inclusivamente, sem epsilon, na borda60.
  F6 verifica apenas os exemplos aritméticos18,5/14,5; não usa Modificadores.
- Fixture temporal independente: nove deslocamentos da esquiva, consulta
  `em_esquiva` falsa já no último, ordem cancelar → garantir invulnerável →
  esquiva iniciada, sem inércia, cargas voltando em42/84/126, gasto sem zerar
  recarga, esquiva encadeada em0/9 e redução do máximo zerando progresso quando
  as cargas ficam cheias (retorno em72).
- Passo congelado altera somente o histórico anterior=atual. Teleporte cancela
  esquiva e conserva cargas, progresso e proteção do dublê. O dublê de Combate
  protege passos0–11 para pedido12, sem simular dano real.

## Limite encontrado em F7

`d_passo < raio_combinado` não transforma a resolução por ponto final em uma
colisão contínua do trajeto. Com raio combinado69, início relativo ao centro
(-10;68,5) e fim(10;68,5), ambos os pontos estão fora do disco
(distância≈69,226), o passo mede20<69, mas o segmento passa dentro dele
(distância mínima68,5). A resolução de R10 deixa o ponto final inalterado.

O teste registra esse comportamento como **limite observado**, não como
aprovação de uma garantia contínua. O caso axial de AC-30 passa. Para partida
fora do disco, o limite de passo impede atravessar o semiplano radial oposto
em um único deslocamento, mas não detecta toda interseção tangencial. Além
disso, uma posição inicialmente dentro, como centro−(5;0), pode sair pelo lado
oposto mesmo com passo22,5<69. Spawn/teleporte válido e limites da alegação
precisam ficar explícitos na revisão do design. Não foi alterado nenhum GDD.

## Limitações

É uma coleção de fixtures, não o Movimento de produção. O modelo temporal usa
um buffer simplificado só de esquiva e não verifica o contador compartilhado
com Ataque/Especial/Selo. Não cobre Input real, toques durante hitstop,
`esquiva_sem_carga`, consumo autorizado por época, prioridades de investida,
Modificadores reais, Corte por identidade/teto/ordem, aplicação de dano/status,
contratos de eventos, catálogo e validações completas MV1–MV8, aviso de
teleporte na cena ou ressincronização da interpolação visual. Não há
`CharacterBody2D`, física da engine, rendering, teste de sensação, desempenho
ou paridade direta com TypeScript. F6 e F7 são recortes aritméticos/geométricos;
não representam aprovação de todos os seus contratos.

Expectativas: `design/gdd/movimento-e-esquiva.md`, R1–R10, F1–F7 e recorte de
AC-01/03/04/06/07/11/13–17/29/30/32/52/58. `passos(t)` segue F7 de
`conteudo-orientado-a-dados.md`. As APIs básicas foram confrontadas com a
referência local e executadas na engine instalada.

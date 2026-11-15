# Experimento de input por passo

Experimento descartável para o ADR-0006. Não é a implementação de produção.
A pasta tem `.gdignore` para ficar fora do projeto principal; execute-a como
projeto separado.

## Execução

Na raiz do repositório, em PowerShell:

```powershell
$inputProbeLog = Join-Path $env:TEMP 'khaeros-input-probe.log'
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --log-file $inputProbeLog --path 'prototypes/input-verificacao' --script main.gd
```

Resultado em 2026-11-14: Godot `4.7.2.stable.official.ed1daf0bf`,
`RESULT checks=38 failures=0`, código de saída 0.

## O que foi verificado

- `Input.parse_input_event` entrega eventos sintéticos a um `Node._input`
  conectado à árvore. O coletor usa a posição física da tecla, independentemente
  do código lógico. O mapa de três teclas é uma fixture, não o mapa completo R1.
- Aperto e soltura entre duas amostras preservam o toque; aperto, soltura e novo
  aperto geram uma única borda. Amostrar novamente sem eventos não repete a borda.
  O eco do teclado não a renova.
- Dois binds físicos da mesma ação conservam o estado segurado até ambos serem
  soltos. A segunda tecla não cria uma nova borda enquanto a ação já está ativa.
- Com `Input.use_accumulated_input = false`, dois movimentos opostos do mouse
  chegam separadamente. F5 soma seus módulos: (3,4) e (-3,-4) produzem 10 px,
  mesmo com deslocamento líquido zero. O valor anterior da opção é restaurado
  ao fim. Este teste usa eventos sintéticos; não mede agrupamento pelo SO.
- A troca de contexto descarta toques pendentes, inclusive um toque já solto no
  intervalo da troca. Bloqueia cada tecla que continua segurada até a soltura;
  confirmar um menu não se transforma em esquiva. Durante Transição não há
  ações, e teclas seguradas ao sair continuam bloqueadas.
- Modelo puro de F3: prazo de dez passos (0–9), congelamento por 36 passos de
  hitstop com toque em 0 ou 20, expiração no passo 45 e renovação compartilhada
  por Ataque em 0/Especial em 8 até 17, expirando ambos em 18.
- Consumir uma ação preserva as demais e o prazo. Ataque/Especial segurados
  repetem; Esquiva/Selo não. Interagir/Pausar não entram no buffer. Injetar prazo
  cinco produz disponibilidade em 0–4 e expiração em 5.

## Limites

Não verifica a integração ao orquestrador, a invalidação de amostra já entregue
antes de uma troca no mesmo passo, consumo autorizado por sistema, troca de
contexto apagando o buffer integrado, foco real da janela, gamepad físico ou
gatilhos, menus/Texto/Remapeando, remapeamento/persistência, mira/zona morta,
latência, atalhos do SO, nem captura em build exportada. O modelo do buffer e o
coletor são fixtures independentes. A ordem de execução dos consumidores e suas
recargas pertencem à integração futura.

Os vetores e expectativas vêm de `design/gdd/input-e-controle.md`, F3/F5 e
AC-04, AC-15–22. As APIs foram confrontadas com a referência local de input e
executadas na versão instalada; nenhum resultado depende de uma leitura de
documentação de uma versão diferente.

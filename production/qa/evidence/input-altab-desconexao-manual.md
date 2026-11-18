# Input: registro manual de Alt+Tab e desconexão (story input-005, AC-23 [M] e AC-24 [M])

**Status: pendente — precisa de execução com janela e hardware real.** Nada foi executado manualmente ainda.

| Caso | Procedimento | Esperado | Resultado | Data / build |
|---|---|---|---|---|
| AC-23 [M] Alt+Tab em Jogo | Segurar W + Ataque, Alt+Tab, voltar | Pausa aberta; ao voltar segue em Pausa; W/Ataque não rearmam até soltar | pendente | — |
| AC-23 [M] Alt+Tab no wipe | Alt+Tab durante a Transição, voltar | Pausa abre no 1º passo de Jogo após o wipe | pendente | — |
| AC-24 [M] cabo USB | Jogar com gamepad, puxar o cabo | Pausa + `INPUT_CONTROLE_DESCONECTADO`; reconectar não fecha a Pausa | pendente | — |
| AC-24 [M] Bluetooth | Desligar o gamepad BT em Jogo e na Bênção | Jogo: Pausa + aviso; Bênção: só o aviso | pendente | — |

Pré-requisito: `src/app/main.gd` ligar o foco da janela a `RoteadorDeContexto.perder_foco/recuperar_foco` e
`Input.joy_connection_changed` a `MonitorDeDispositivos.ao_mudar_conexao` (fora do escopo da story 005).

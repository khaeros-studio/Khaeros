# Fechamento da primeira integração

2026-11-14 · Godot 4.7.2 · cena principal configurada · sem commit.

| Runner | Verificações | Resultado |
|---|---:|---|
| `run_catalog.gd` | 38 | Passou |
| `run_gameplay.gd` | 35 | Passou |
| `run_input_camera.gd` | 32 | Passou |
| `run_app.gd` | 9 | Passou |
| `run_ui_flow.gd` | 23 | Passou |
| **Total interno dos runners** | **137** | **Zero falhas** |

A suíte gdUnit4 executou três casos (o wrapper dos cinco runners e os dois testes de fumaça existentes): zero erros, falhas, ignorados ou órfãos; saída 0. Resultado preservado em `gdunit.log`. As duas mensagens iniciais de porta de depuração inválida são esperadas pelo comando do projeto com porta 0; o runner segue e conclui os testes. O caso de catálogo com JSON `1e999` produz aviso esperado e rejeição.

O jogador automático da sessão completou três ondas/13 abates com seed123, Vida100 e1001 passos vivos. O roteiro visual separado, com a seed da cena principal e evolução por quadros reais, também venceu as três ondas/13 abates, com Vida76. São execuções distintas; nenhuma altera Vida ou elimina inimigos por fora das regras durante essas partidas.

Capturas de menu, combate real, bênçãos, pausa, derrota e vitória real foram inspecionadas. O teste de fluxo de UI usa eventos reais da engine com callbacks avançados explicitamente; hardware físico e sensação não são certificados.

`stamp.txt` contém SHA-256 dos arquivos de implementação/dados/cena/testes desta entrega. Alterações posteriores exigem repetir os testes afetados e atualizar evidência. Os recursos ainda ausentes estão descritos em `docs/COMO-JOGAR.md`.

# Integração jogável — evidência de 2026-11-14

Godot 4.7.2, Windows, janela 1280×720, Forward+ / Vulkan, NVIDIA GeForce RTX 3050 Laptop GPU. Cena real `scenes/main.tscn` configurada como principal. Implementação autorizada pelo pedido do usuário “faça a integração do jogo”; ADRs continuam como propostas, sem aceite formal automático.

## Execução observada

**Run result: PASS — primeira fatia integrada.** O roteiro visual em `tests/integration/capture_playthrough.gd` executou a sessão real até vitória: três ondas, 13 abates, Vida final 76/100. Ele fornece amostras de controle e escolhe bênçãos, sem alterar a Vida ou remover inimigos artificialmente. Log: `playthrough-render.log`, sem erros de execução.

As imagens foram abertas e conferidas: textos legíveis sem recorte, cartas inteiras, foco de seleção visível, personagem e efeitos de combate presentes, HUD atualizando Vida/inimigos/onda. Arte é provisória. Não é aprovação artística ou de sensação.

| Imagem | O que comprova |
|---|---|
| [menu.png](menu.png) | Cena inicial e instruções |
| [combate-real.png](combate-real.png) | Ataque e dano durante a partida renderizada |
| [bencao.png](bencao.png) | Três cartas e foco de seleção; estado preparado pela ferramenta de captura |
| [pausa.png](pausa.png) | Ações de pausa e opção de movimento |
| [morte.png](morte.png) | Layout de derrota e reinício; estado preparado pela captura |
| [resultado-real.png](resultado-real.png) | Vitória alcançada pela partida visual completa |

Os primeiros testes gráficos restritos registraram indisponibilidade de cache de shader. A execução visual completa e as capturas seguintes rodaram com acesso normal ao cache, sem esse erro; não houve mudança de renderer para ocultá-lo.

## Escopo de validação

Os runners reais verificam carga de dados, simulação, dispositivos sintéticos, câmera, composição e fluxo de telas. A suíte gdUnit4 inclui esses runners no processo de testes do projeto. A contagem final e os hashes dos arquivos estão no registro de fechamento desta pasta.

Ainda não validados como produto: áudio, arte/animações finais, controle físico, sensação de esquiva, gravação em 144 Hz, orçamento p99 com todos os sistemas e recursos ainda não integrados listados em `docs/COMO-JOGAR.md`.

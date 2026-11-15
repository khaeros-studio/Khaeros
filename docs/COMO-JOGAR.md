# Khaeros — primeira integração jogável

Abra `project.godot` no Godot 4.7.2 e pressione **F5**. A cena inicial já está configurada em `scenes/main.tscn`. Escolha **Entrar na Beira**.

Esta versão tem uma travessia de três ondas com a **Lâmina do Juramento**. Derrote os inimigos, escolha uma bênção entre as ondas e alcance a tela de vitória. Se morrer, é possível começar novamente.

| Ação | Teclado e mouse | Controle, disposição Xbox |
|---|---|---|
| Mover | WASD ou setas | Analógico esquerdo |
| Mirar | Mouse | Analógico direito; mira automática quando solto |
| Atacar | Clique esquerdo ou J | X |
| Investida | Clique direito ou K | Y |
| Esquivar | Espaço, Shift ou L | A ou gatilho direito |
| Pausar / continuar | Esc | Start |
| Navegar nas telas | Setas, WASD ou mouse | Direcional ou analógico esquerdo |
| Confirmar | Enter, Espaço, E ou clique | A |
| Selecionar bênção | 1, 2 ou 3; confirmar depois | Navegar e confirmar |

Segurar Ataque ou Investida repete quando a recarga permitir. Esquiva exige novo toque e uma carga disponível. A pausa também abre ao perder o foco da janela. A opção **Redução de movimento**, no início e na pausa, desliga o lookahead e o zoom de impacto.

## O que já está conectado

- Cena principal, carregamento e validação do conjunto de dados da integração.
- Entrada por teclado/mouse/gamepad, buffer compartilhado e bloqueio de comandos entre telas.
- Caminhada, esquiva, recarga, proteção, obstáculos e limites da câmara.
- Combo de três ataques, Investida e Corte da esquiva como bênção.
- Eco Perdido e Anomalia Menor, elites, preparação de ataques, projéteis e dano.
- Três ondas, três opções de bênção, transição, pausa, derrota, vitória e reinício.
- Câmera com duas bases, mira sem tremor, escala para telas estreitas/ultrawide e interface em português.

## Limites desta versão

É a primeira fatia integrada, não o MVP completo. Os desenhos são silhuetas provisórias feitas para testar leitura e controles; as folhas de arte existentes continuam preservadas para o pipeline final. Ainda faltam animações e áudio finais, Ressonância, Selo/Fluxo, status completos, geração de regiões/portas, economia e salvamento de progresso. Os comandos ainda não têm remapeamento ou persistência.

O catálogo atual é um JSON validado, e o sorteio próprio cobre espera da IA. Ele não implementa o catálogo completo de Resources, o hash canônico nem os oito fluxos do ADR-0005. Os atributos/bênçãos desta fatia são explícitos, sem substituir o futuro sistema geral de modificadores. A colisão preserva a regra discreta dos GDDs e o limite tangencial registrado no ADR-0008.

## Organização

| Caminho | Responsabilidade |
|---|---|
| `scenes/main.tscn` | Cena inicial |
| `src/app/main.gd` | Composição, passos, telas e conexão dos módulos |
| `src/foundation/session_catalog.gd` | Validação dos dados desta integração |
| `src/foundation/game_input.gd` | Dispositivos, ações e buffer |
| `src/gameplay/game_session.gd` | Combate, inimigos, ondas e estados da sessão |
| `src/gameplay/movement.gd` | Colisões, recarga e histórico de posição |
| `src/presentation/game_camera.gd` | Câmera e conversão da mira |
| `src/presentation/world_view.gd` | Cenário, personagens e efeitos provisórios |
| `src/presentation/game_hud.gd` | Menus, HUD e bênçãos |
| `data/integration/gameplay.json` | Valores e ondas da versão jogável |
| `tests/integration/` | Testes executáveis e roteiro visual |

O código foi escrito em módulos novos. O protótipo anterior e seus resultados continuam disponíveis em `prototypes/combate-camara-concept/`.

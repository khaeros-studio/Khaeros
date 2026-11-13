# Prompt — enm_eco_perdido_ataquemorte_frente34_raw_v01

- **Modelo:** Gemini ("Argon", Criar imagem, 16:9), na conversa do Eco `/app/155c612cfa4c23ec` (primeira imagem = ficha E0) · **Data:** 2026-11-13 · **Folha:** E2 frente34, 5×2
- **Conteúdo:**
  - linha 1: `windup` 01–03 e `attack` 01–02;
  - linha 2: `recover` 01–02, `hurt` 01 e `death` 01–02.

  As poses vêm da spec do lote 2, §4.

## Prompt (colar inteiro)

Gere uma IMAGEM nova de FOLHA DE ANIMAÇÃO (não é ficha de personagem: sem close da cabeça, sem detalhe do braço, sem vistas de perfil/costas, sem figuras sobrepostas). Como referência da criatura, use SOMENTE a PRIMEIRA imagem desta conversa; IGNORE todas as imagens geradas depois dela. REGRA ABSOLUTA: nenhuma palavra, letra, número ou símbolo; nenhum arco de golpe, rastro, brilho, aura, faísca, fumaça, névoa, fiapo solto, poeira ou linha de movimento; nenhuma linha divisória, borda ou quadro; fundo verde #00FF00 chapado e contínuo, sem sombra no chão. CÂMERA: TODAS as figuras em vista 3/4 de FRENTE, voltadas para a direita, vistas um pouco de cima. LAYOUT: imagem larga 16:9 com EXATAMENTE 10 figuras da MESMA criatura, separadas por bastante verde, sem se tocar, em 2 fileiras: EXATAMENTE 5 em cima e EXATAMENTE 5 embaixo, lidas da esquerda para a direita; TODAS inteiras, nenhuma cortada; TODAS na MESMA escala; cada figura ocupa no máximo 45% da altura da imagem; as pontas dos braços ficam dentro do espaço da própria figura, sem encostar na vizinha nem na borda. ESTILO: igual à primeira imagem — quadrinho de ação adulto em nanquim, contorno externo preto muito grosso e uniforme, face de sombra em PRETO CHAPADO de borda dura, luz em 2 tons; sem degradê, sem 3D. CRIATURA: exatamente o Eco Perdido da primeira imagem: vulto alto e magro que flutua; capuz com a ponta caída em gancho pingando tinta; rosto oval liso e claro, sem nenhum traço, dentro da cavidade preta; manto cinza-azulado com mangas curtas rasgadas; BURACO redondo vazado no peito mostrando o fundo verde; braços magros que terminam numa ÚNICA PONTA afiada, sem mãos; barra rasgada em dentes com forro preto; SEM pernas. SÓ DOIS BRAÇOS. LINHA DE CIMA — ATAQUE, uma varrida com o braço direito: [1] para, o tronco gira para trás, o braço direito é puxado para trás e para fora, longe do corpo; [2] o braço direito mais alto e mais para trás, o esquerdo esticado à frente como contrapeso; [3] preparo máximo: torção total, braço de ataque bem afastado, ponta para trás; [4] varrida: o braço direito atravessa a frente do corpo num arco largo, esticado, só o braço, sem rastro; [5] continuação: o braço já do outro lado, tronco girado, capuz acompanhando. LINHA DE BAIXO: [6] recuperação: curvado para a frente, braços caídos; [7] recuperação: se endireitando, braços voltando; [8] dano: tronco e capuz jogados para trás, braços abertos; [9] morte: dobra-se ao meio, capuz caindo para a frente, braços soltos; [10] morte: desabado num monte baixo de manto vazio no chão, com o capuz caído por cima, braços largados.

## Registro de geração

- 2026-11-13: gerada pelo navegador do app. Original em JPEG 2752×1536.
- Resultado: **10 figuras** (5+5), sem arco de golpe nem efeito.
  - A recuperação (6–7) e o dano (8) leem bem.
  - A morte é a parte mais forte: na 9 ele dobra ao meio, e na 10 vira um monte de manto vazio com o capuz caído por cima.
  - O buraco do peito aparece vazado em quase todas as poses.
- Problemas:
  - **O ataque é fraco:**
    - a pose 1 parece um idle, sem puxar o braço para trás;
    - na 2 e na 3 os braços cruzam a frente do corpo em vez de fazer a torção;
    - a varrida (4–5) lê como um braço esticado apontando, sem o arco.

    A 90 px e em 2 quadros isso pesa menos; o rig pode reforçar com rotação do antebraço.
  - Na pose 8 o braço esquerdo termina numa mão aberta; o antebraço é peça do rig.
  - A ponta do braço da pose 2 chega perto do braço baixo da pose 3, e a ponta da pose 10 fica a poucos pixels da borda direita.

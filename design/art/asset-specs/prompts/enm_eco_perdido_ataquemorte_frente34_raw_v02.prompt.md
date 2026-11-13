# Prompt — enm_eco_perdido_ataquemorte_frente34_raw_v02

- **Modelo:** Gemini ("Argon", Criar imagem, 16:9), na conversa do Eco `/app/155c612cfa4c23ec` (primeira imagem = ficha E0) · **Data:** 2026-11-13 · **Folha:** E2 frente34, 5×2
- **Por que v02:** na v01 o ataque saiu fraco: a pose 1 parecia um idle, os braços cruzavam o corpo e a varrida lia como um braço apontando. Aqui o preparo e o corte vêm descritos com direção (esquerda/direita da imagem) e peso do corpo. A linha de baixo é a mesma; se ela vier pior, valem as poses 6–10 da v01.

## Prompt (colar inteiro)

Gere uma IMAGEM nova de FOLHA DE ANIMAÇÃO (não é ficha de personagem: sem close da cabeça, sem detalhe do braço, sem vistas de perfil/costas, sem figuras sobrepostas). Como referência da criatura, use SOMENTE a PRIMEIRA imagem desta conversa; IGNORE todas as imagens geradas depois dela. REGRA ABSOLUTA: nenhuma palavra, letra, número ou símbolo; nenhum arco de golpe, rastro, brilho, aura, faísca, fumaça, névoa, fiapo solto, poeira ou linha de movimento; nenhuma linha divisória, borda ou quadro; fundo verde #00FF00 chapado e contínuo, sem sombra no chão. CÂMERA: TODAS as figuras em vista 3/4 de FRENTE, voltadas para a DIREITA da imagem, vistas um pouco de cima. LAYOUT: imagem larga 16:9 com EXATAMENTE 10 figuras da MESMA criatura, separadas por bastante verde, sem se tocar, em 2 fileiras: EXATAMENTE 5 em cima e EXATAMENTE 5 embaixo, lidas da esquerda para a direita; TODAS inteiras, nenhuma cortada; TODAS na MESMA escala; cada figura ocupa no máximo 45% da altura da imagem; as pontas dos braços ficam dentro do espaço da própria figura, sem encostar na vizinha nem na borda. ESTILO: igual à primeira imagem — quadrinho de ação adulto em nanquim, contorno externo preto muito grosso e uniforme, face de sombra em PRETO CHAPADO de borda dura, luz em 2 tons; sem degradê, sem 3D. CRIATURA: exatamente o Eco Perdido da primeira imagem: vulto alto e magro que flutua; capuz com a ponta caída em gancho pingando tinta; rosto oval liso e claro, sem nenhum traço, dentro da cavidade preta; manto cinza-azulado com mangas curtas rasgadas; BURACO redondo vazado no peito mostrando o fundo verde; braços magros que terminam numa ÚNICA PONTA afiada, sem mãos; barra rasgada em dentes com forro preto; SEM pernas. SÓ DOIS BRAÇOS. LINHA DE CIMA — ATAQUE: um corte horizontal violento com o braço direito, que vem de trás e varre para a DIREITA, como uma foice; poses EXAGERADAS, com linha de ação forte: [1] RECUO: o corpo todo se inclina para TRÁS, para a ESQUERDA da imagem, o capuz recua, o braço direito vai para trás do corpo com a ponta apontando para a ESQUERDA da imagem, o braço esquerdo ainda solto; [2] TORÇÃO: os ombros giram para a esquerda, o braço direito sobe ATRÁS da cabeça, dobrado, ponta para cima e para trás, o braço esquerdo esticado para a DIREITA como mira; [3] PREPARO MÁXIMO, a pose mais tensa: o corpo encolhido e enrolado como uma mola, inclinado para trás, o braço direito ESTICADO para trás e para cima, longe do corpo, pronto para cortar; [4] CORTE: o corpo se lança para a DIREITA, inclinado para a frente, e o braço direito, totalmente esticado na horizontal, varre para a frente e aponta para a DIREITA na altura do ombro, o braço esquerdo jogado para trás; [5] CONTINUAÇÃO: o golpe passou: o braço direito cruzou para o outro lado do corpo, o tronco ficou torcido de costas para a direita, a barra do manto rodando. LINHA DE BAIXO: [6] recuperação: curvado para a frente, braços caídos; [7] recuperação: se endireitando, braços voltando; [8] dano: tronco e capuz jogados para trás, braços abertos; [9] morte: dobra-se ao meio, capuz caindo para a frente, braços soltos; [10] morte: desabado num monte baixo de manto vazio no chão, com o capuz caído por cima, braços largados.

## Registro de geração

- 2026-11-13: gerada pelo navegador do app. Original em JPEG 2752×1536.
- Resultado: **o ataque melhorou bastante em relação à v01.**
  - O recuo (1) inclina para trás.
  - Na torção (2) o braço sobe atrás da cabeça e o outro mira à direita.
  - O preparo máximo (3) estica o braço para trás e para cima, longe do corpo.
  - O corte (4) é horizontal para a direita.
  - Na continuação (5) o tronco gira de costas e o braço dá a volta no corpo como uma foice.
  - A linha de baixo é quase igual à da v01; a morte (9–10) continua forte.
- Problemas:
  - **As pontas viraram punho ou mão:** punho na pose 3, mão fechada com ponta na 4, dedos na 8. O antebraço é peça do rig.
  - **Pose 5:** o braço em foice que contorna a cintura é estranho como anatomia, mas lê bem como golpe no tamanho final.
  - Ao lado da pose 5 há um pontinho solto no verde; sai no recorte.
  - A ponta do braço da pose 4 fica a poucos pixels do ombro da pose 5.
- **Teste de modelo (2026-11-13), a pedido do usuário.** O mesmo prompt foi gerado de novo (`_v03.jpg`, Nano Banana 2.1; "Ver detalhes da resposta" confirma o modelo) e depois refeito com "Refazer com o Pro" (`_v03pro.jpg`, Nano Banana Pro).
  - **A v03 (2.1)** é equivalente à v02. A pose 3 virou um gesto de "dab" com punho, e a morte (10) não mostra o capuz.
  - **A Pro foi pior:**
    - **pôs olhos (fendas) em todos os rostos**, o que quebra o rosto liso e cai na divergência da Art Bible §9.3 (máscara clara com olhos);
    - o ataque virou "mão na cabeça" (2) e "dab" (3);
    - a morte (10) saiu sentada, sem desabar, com o buraco preenchido de preto.
  - **Aprovada pelo usuário em 2026-11-13: v02, no Nano Banana 2.1.**
  - **Conclusão: fica a v02.** O Nano Banana 2.1 (padrão com o Argon) segue melhor o prompt nesta conversa. O Pro fica só como teste pontual, e só para o Iniciado.

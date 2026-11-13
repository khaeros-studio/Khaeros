# Prompt — chr_iniciado_lamina_idledash_costas34_raw_v02

- **Modelo:** Gemini (modelo "Argon", Criar imagem, 16:9), na conversa da ficha v03 · **Data:** 2026-11-11 · **Folha:** L1 costas34, 6×2
- **Por que v02:** o texto da v01 (gen1.py) é longo. Esta versão usa o formato compacto que funcionou na L6 v03 e na L7 ("folha de animação, não é ficha"), com o emblema descrito para não sair como "Ø" (retoque pedido pelo art-director, §8 da spec).

## Prompt (colar inteiro)

Gere uma IMAGEM nova de FOLHA DE ANIMAÇÃO (não é ficha de personagem: sem close de rosto, sem vistas de frente/perfil, sem figuras sobrepostas). Como referência do personagem, use SOMENTE a PRIMEIRA imagem desta conversa; IGNORE todas as imagens geradas depois dela. REGRA ABSOLUTA: nenhuma palavra, letra, número ou símbolo escrito além do emblema descrito abaixo; nenhum brilho, aura, fumaça, poeira, rastro ou linha de movimento; nenhuma linha divisória, borda ou quadro; fundo verde #00FF00 chapado e contínuo, sem sombra no chão. CÂMERA: TODAS as figuras em vista 3/4 de COSTAS, voltadas para a direita e para longe de quem olha, vistas um pouco de cima; vemos o cabelo, a nuca e as costas do casaco; o rosto NÃO aparece. LAYOUT: imagem larga 16:9 com EXATAMENTE 12 figuras do MESMO personagem, separadas, sem se tocar, em 2 fileiras de 6 (SEIS em cima e SEIS embaixo), lidas da esquerda para a direita; TODAS de CORPO INTEIRO, nenhuma cortada; TODAS na MESMA escala; os pés de cada fileira na mesma linha; cada figura ocupa no máximo metade da altura da imagem. ESTILO: igual à primeira imagem — quadrinho de ação adulto em nanquim, contorno externo preto muito grosso e uniforme, face de sombra em PRETO CHAPADO de borda dura, luz em 2 tons por material; sem degradê, sem 3D. PERSONAGEM: exatamente o da primeira imagem (cabelo prateado anguloso, gola alta, mantelete LISO com borda de osso, casaco cinza-azulado em 4 painéis com pontas em diagonal, luvas pretas, antebraços enfaixados em osso, cinto com estojo cilíndrico atrás, botas com caneleiras de osso); acentos só em cor de osso. EMBLEMA NAS COSTAS: entre as omoplatas, abaixo do mantelete, um emblema grande cor de osso — um anel circular aberto cortado por UMA faixa diagonal larga, como uma pincelada grossa, que vai do canto de baixo à esquerda ao canto de cima à direita e SAI para fora do anel nas duas pontas; é um sinal desenhado, NUNCA a letra Ø. ESPADA: UMA ÚNICA espada longa reta na mão DIREITA, baixa em diagonal; SÓ DOIS BRAÇOS. LINHA DE CIMA — IDLE, ciclo de respiração com o corpo inclinado à frente e peso no pé da frente: [1] base; [2] inspira, ombros sobem, barra do casaco balança para trás; [3] topo da respiração; [4] expira; [5] base com a barra balançando para a frente; [6] volta à base. LINHA DE BAIXO — ESQUIVA para a direita: [7] agacha rápido; [8] impulso, corpo esticado na diagonal; [9] pico do salto, corpo esticado quase na horizontal, casaco aberto atrás; [10] ainda no ar; [11] aterrissando, joelhos dobrados; [12] de pé, recuperado.

## Registro de geração

- 2026-11-11: gerada pelo navegador do app (modelo "Argon", 16:9). Original em JPEG 2752×1536.
- Resultado: **12 figuras**, todas em vista 3/4 de costas, de corpo inteiro e na mesma escala. O fundo veio limpo. A esquiva lê bem: agacha, impulso, voo horizontal, aterrissagem e recuperação.
- Problemas:
  - O **emblema saiu como "Ø" de novo**, e no mantelete em vez de abaixo dele, mesmo com a descrição detalhada. Esta é a terceira vez.
  - Na esquiva, a **espada some** no impulso (pose 8) e vira só um cabo no voo (pose 9).
  - O idle está ereto, sem inclinar à frente.
  - A pose 7 mostra o perfil do rosto.
- Proposta ao usuário: tirar o emblema das folhas (costas lisas) e aplicar o emblema como peça separada do rig, pintada uma vez à mão.

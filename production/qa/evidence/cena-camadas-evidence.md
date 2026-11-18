# Evidência — Cena: camadas e compositor (story cena-e-camera/008)

Data: 2026-11-16 · Godot 4.7.2 (binário do editor, debug) · RTX 3050 Laptop, Vulkan Forward+

## Capturas retidas

- `cena-camadas-ensaio-2026-11-16.png` — janela 1280×720 (16:9), câmera real + `CompositorDeCena` + `CamadasDoMundo`,
  um item por camada de mundo. Gerada por script de ensaio executado COM janela (`godot --path . -s <script>`),
  salvando `root.get_texture().get_image()` após `frame_post_draw`.
  - AC-10: o inimigo (cinza) em pé sobre o telégrafo cobre o preenchimento magenta (z −5); o contorno (z 5) fica
    por cima do inimigo; o primeiro plano (z 10, retângulo preto) cobre preenchimento e contorno. Sombra (z −6)
    aparece sob o preenchimento.
  - AC-12 (parcial): na coluna, o personagem "atrás" (pé y 600 < 630) fica totalmente oculto pela coluna e o
    personagem "na frente" (dourado, pé y 660) aparece sobre ela. Falta a dupla de screenshots com o MESMO
    personagem atrás e na frente, com arte real.

## Custo da reordenação por y (guardrail ADR-0007 §5)

200 âncoras (teto de draw calls de entidades do control-manifest), 600 quadros, `CamadasDoMundo.atualizar_ordem`
(definir chaves + sort nativo de `Vector3(pé.y, ordinal, índice)` + `move_child` só quando a ordem muda):

| Cenário | mediana | p95 | máx |
|---|---|---|---|
| pés estáticos | 753 µs | 1584 µs | 9276 µs |
| todos os pés mudam | 990 µs | 1856 µs | 4205 µs |

Primeira versão (comparador GDScript em `sort_custom`) medida antes: mediana 4570/4965 µs — trocada pelo sort
nativo (ganho ~5×). Medido em headless com o binário do editor (debug); um template release deve ser mais rápido,
não presumido. O conteúdo real tem bem menos de 200 âncoras (máx. 9 inimigos/onda + projéteis). Decisão sobre o
orçamento: performance-analyst.

## Pendente (precisa de execução com janela dedicada e/ou da integração)

- AC-03: capturas nas 6 proporções (16:9, 2560×1080, 3440×1440, 32:9, 16:10, 4:3) — não feitas.
- AC-18: captura da cor de fundo da região na sangria — o código existe (`definir_cor_de_fundo`), captura não feita.
- AC-12 com arte real; checklist de cobertura de arte/névoa pela deriva da F7.
- Sign-off do lead: **pendente**.

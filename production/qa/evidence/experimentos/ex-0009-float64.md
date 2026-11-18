# EX-0009-1 — `float` do GDScript é IEEE-754 de 64 bits (evidência)

- **Data**: 2026-11-16 · **Engine**: Godot 4.7.2.stable.official.ed1daf0bf, build padrão (não `precision=double`) · **Máquina**: Ryzen 5 5600H, Windows 11
- **Protótipo**: `prototypes/engine-verificacao/eventos-e-aritmetica/probe.gd` (`_float64`) e `probe_extra.gd`
- **Execuções**: headless no projeto e `.pck` exportado (`--export-pack` + `--main-pack`). Os resultados foram idênticos byte a byte. Template de release não instalado.

| Verificação | Resultado (projeto = `.pck`) |
|---|---|
| `0.1 + 0.2` bits | `0x3fd3333333333334` (valor de dupla precisão exato), `== 0.3` → false, `String.num(s, 17)` = `0.30000000000000004` |
| `2^52 + 1.0 != 2^52` | true: há 53 bits de mantissa. Em 32 bits, isso falharia a partir de 2^24 |
| `2^53 + 1.0 == 2^53` (soma em runtime) | **true**, o que é o comportamento correto de dupla precisão (2^53+1 não é representável) |
| `float(int 2^53+1)` e `"9007199254740993".to_float()` | `0x4340000000000000` (= 2^53, arredondamento correto, empate para o par) |
| **literal** `9007199254740993.0` no código | `0x4340000000000001` (= 2^53+2): **o tokenizer do GDScript não arredondou o empate para o par** |
| `int` | 64 bits: `2^62 + 1` exato, `max_int` 9223372036854775807 |

**Resultado: VERIFICADO**, `float` é IEEE-754 binary64 e dá o mesmo resultado no projeto e no `.pck`.

**Correção para a story/ADR:** o AC "`float` preserva 2^53+1 distinto de 2^53" está **errado como prova**. Nenhum binary64 representa 2^53+1, então a soma colapsa em 2^53, como deve. A prova correta de 64 bits é: `2^52 + 1 != 2^52` e os bits de `0.1 + 0.2` = `0x3FD3333333333334`.

**Achado colateral (determinismo):** literais `float` no código-fonte com mais de 17 dígitos significativos, ou em empate exato, podem ser convertidos de forma diferente de `String.to_float()` e de `float(int)`. Valores de gameplay vêm de dados (`.tres`/CSV), não de literais, mas fixtures de teste do ADR-0009 (AC-03/AC-05) não devem usar literais em casos de empate.

## O que o ADR-0009 precisa mudar

1. VR(1): marcar verificado (binary64 no build padrão; projeto e `.pck`). Template de release pendente.
2. Trocar o critério "2^53+1 distinto de 2^53" pela prova correta acima.
3. Acrescentar a nota sobre literais em empate no tokenizer (preferir `to_float()`/dados nos fixtures de borda).

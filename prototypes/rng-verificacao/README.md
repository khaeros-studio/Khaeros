# Verificação do RNG

Experimento isolado para o ADR-0005. Executado em 2026-11-14 no Godot 4.7.2.stable.official.ed1daf0bf. As 33 verificações passaram, com zero falhas e saída 0.

## Execução

Na raiz do repositório, em PowerShell.

```powershell
$rngProbeLog = Join-Path $env:TEMP 'khaeros-rng-probe.log'
& 'C:/Users/lucas/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --log-file $rngProbeLog --path 'prototypes/rng-verificacao' --script main.gd
```

## Evidência

- F1 reproduz cinco estados e saídas da seed zero e cinco saídas de 3F9A07C2.
- F2 reproduz os vetores fmix32, cinco profundidades da finalidade portas e a derivação da seed zero. A máscara na fronteira normaliza seeds negativas e acima de uint32.
- F4 reproduz limiares adjacentes e o intervalo máximo 2²¹.
- F6 reproduz os exemplos do GDD e testa somas inteiras 2³¹−1 e 2³¹, pesos zero, limiar exato de metade e rejeição de soma superior ao limite.

O produto máximo `u × W`, com W = 2³¹, é 9.223.372.034.707.292.160 e cabe em int64. Já a comparação direta com `C × 2³²`, quando C = 2³¹, estoura o inteiro com sinal. A comparação equivalente `((u × W) >> 32) < C` mantém a exatidão e permite a soma 2³¹ prevista no GDD. Como C é inteiro, truncar a parte fracionária do lado esquerdo conserva o resultado de menor estrito.

Este experimento cobre as fórmulas numéricas F1, F2, F4 e o ramo inteiro de F6. Os handles de fluxos, seu ciclo de vida, F3/F5/F7/F8/F9, pesos reais e o lint de produção terão testes próprios na implementação. Os vetores esperados vêm do GDD aprovado. A implementação de produção deverá também conferir a paridade diretamente contra o cânone TypeScript.

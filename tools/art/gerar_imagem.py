"""Gera imagens de arte do Khaeros com o Gemini (modelo de imagem "Nano Banana").

A chave nunca fica no código nem no chat. O script procura, nesta ordem:
  1. a variável de ambiente GEMINI_API_KEY;
  2. o arquivo tools/art/.gemini-key (uma linha só com a chave; está no .gitignore).

Uso (na raiz do projeto):
  python tools/art/gerar_imagem.py --prompt "Iniciado de corpo inteiro, frente" --nome iniciado_frente
  python tools/art/gerar_imagem.py --prompt-arquivo prompts/eco.txt --ref ref1.png --ref ref2.png --nome eco_perdido
  python tools/art/gerar_imagem.py --testar   (só confere a chave e a conexão, sem gerar imagem)

O bloco de estilo de tools/art/estilo-khaeros.txt (derivado do Art Bible) entra antes
de todo prompt; use --sem-estilo para desligar. As imagens vão para assets/art/geradas/,
com um .txt ao lado guardando o prompt exato e o modelo usados.

Sem dependências: só a biblioteca padrão do Python.
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
PASTA_SAIDA = RAIZ / "assets" / "art" / "geradas"
ARQ_ESTILO = Path(__file__).with_name("estilo-khaeros.txt")
ARQS_CHAVE = [Path(__file__).with_name(".gemini-key"), Path(__file__).with_name("gemini-key.txt")]
ARQ_CHAVE = ARQS_CHAVE[0]
MODELO_PADRAO = "gemini-2.5-flash-image"
API = "https://generativelanguage.googleapis.com/v1beta/models"


def ler_chave() -> str:
    """Devolve a chave da API ou encerra com uma mensagem que diz como configurá-la."""
    chave = os.environ.get("GEMINI_API_KEY", "").strip()
    for arq in ARQS_CHAVE:
        if not chave and arq.exists():
            chave = arq.read_text(encoding="utf-8-sig").strip()
    if not chave:
        sys.exit(
            "Chave do Gemini não encontrada.\n"
            "Crie a chave em https://aistudio.google.com/apikey e salve-a de um destes jeitos:\n"
            f"  - num arquivo de uma linha: {ARQ_CHAVE}\n"
            "  - ou na variável de ambiente GEMINI_API_KEY (reabra o terminal depois)."
        )
    return chave


def parte_imagem(caminho: Path) -> dict:
    """Converte uma imagem de referência em parte inline da requisição."""
    tipo = mimetypes.guess_type(caminho.name)[0] or "image/png"
    dados = base64.b64encode(caminho.read_bytes()).decode("ascii")
    return {"inline_data": {"mime_type": tipo, "data": dados}}


def chamar(modelo: str, chave: str, corpo: dict, timeout: int = 180) -> dict:
    """Faz a chamada generateContent e devolve o JSON da resposta."""
    req = urllib.request.Request(
        f"{API}/{modelo}:generateContent",
        data=json.dumps(corpo).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": chave},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as erro:
        detalhe = erro.read().decode("utf-8", "replace")[:800]
        sys.exit(f"O Gemini recusou o pedido (HTTP {erro.code}).\n{detalhe}")
    except urllib.error.URLError as erro:
        sys.exit(f"Sem conexão com o Gemini: {erro.reason}")


def testar(chave: str) -> None:
    """Lista os modelos disponíveis para a chave, sem gastar geração de imagem."""
    req = urllib.request.Request(f"{API}?pageSize=200", headers={"x-goog-api-key": chave})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            modelos = [m["name"].split("/")[-1] for m in json.loads(resp.read())["models"]]
    except urllib.error.HTTPError as erro:
        sys.exit(f"A chave não funcionou (HTTP {erro.code}).")
    imagem = [m for m in modelos if "image" in m]
    print(f"Chave OK. {len(modelos)} modelos visíveis.")
    print("Modelos de imagem:", ", ".join(imagem) if imagem else "nenhum com 'image' no nome")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--prompt", help="texto do pedido")
    p.add_argument("--prompt-arquivo", type=Path, help="arquivo .txt com o pedido")
    p.add_argument("--ref", type=Path, action="append", default=[], help="imagem de referência (pode repetir)")
    p.add_argument("--nome", default="imagem", help="nome-base do arquivo de saída")
    p.add_argument("--modelo", default=MODELO_PADRAO, help=f"modelo de imagem (padrão: {MODELO_PADRAO})")
    p.add_argument("--sem-estilo", action="store_true", help="não prefixar o bloco de estilo do Art Bible")
    p.add_argument("--testar", action="store_true", help="só confere a chave e lista os modelos de imagem")
    a = p.parse_args()

    chave = ler_chave()
    if a.testar:
        testar(chave)
        return

    pedido = a.prompt or (a.prompt_arquivo.read_text(encoding="utf-8") if a.prompt_arquivo else "")
    if not pedido.strip():
        sys.exit("Faltou o pedido: use --prompt ou --prompt-arquivo.")
    estilo = "" if a.sem_estilo or not ARQ_ESTILO.exists() else ARQ_ESTILO.read_text(encoding="utf-8").strip()
    texto = f"{estilo}\n\nSUBJECT:\n{pedido.strip()}" if estilo else pedido.strip()

    for r in a.ref:
        if not r.exists():
            sys.exit(f"Referência não encontrada: {r}")
    partes = [{"text": texto}] + [parte_imagem(r) for r in a.ref]
    corpo = {"contents": [{"parts": partes}], "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]}}

    resposta = chamar(a.modelo, chave, corpo)
    PASTA_SAIDA.mkdir(parents=True, exist_ok=True)
    carimbo = datetime.now().strftime("%Y%m%d-%H%M%S")
    salvas, falas = [], []
    for cand in resposta.get("candidates", []):
        for parte in cand.get("content", {}).get("parts", []):
            dado = parte.get("inlineData") or parte.get("inline_data")
            if dado:
                ext = mimetypes.guess_extension(dado.get("mimeType") or dado.get("mime_type") or "image/png") or ".png"
                destino = PASTA_SAIDA / f"{a.nome}_{carimbo}_{len(salvas) + 1}{ext}"
                destino.write_bytes(base64.b64decode(dado["data"]))
                salvas.append(destino)
            elif parte.get("text"):
                falas.append(parte["text"])

    if not salvas:
        motivo = resposta.get("promptFeedback") or resposta.get("candidates", [{}])[0].get("finishReason")
        sys.exit(f"Nenhuma imagem voltou. Motivo informado: {motivo}\n{' '.join(falas)[:500]}")

    registro = PASTA_SAIDA / f"{a.nome}_{carimbo}.txt"
    registro.write_text(
        f"modelo: {a.modelo}\nreferências: {[str(r) for r in a.ref]}\n\n{texto}\n\n--- resposta em texto ---\n{''.join(falas)}\n",
        encoding="utf-8",
    )
    for s in salvas:
        print(s)


if __name__ == "__main__":
    main()

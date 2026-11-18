#!/usr/bin/env python3
"""
Khaeros MVP Art Packager (`tools/art/pack_all_mvp_art.py`)
===========================================================
Executa o pipeline completo de empacotamento técnico de Arte do MVP a partir das
folhas aprovadas em `assets/art/source/raw/`:

1. Remoção de fundo verde (#00FF00 chroma-key):
   - Flood-fill 4-conectado a partir das bordas externas (preserva miolos escuros #0D0E14
     em molduras de UI, portas, arcos, emblemas).
   - Chaveamento de vãos internos verdes (#00FF00 dominante) quando aplicável.
   - Despill suave de borda verde em pixels de transição/anti-aliasing.
2. Geração de Atlas de Atores em `assets/art/runtime/<actor_id>/` (células 400x400,
   pivô em [200, 320], `atlas_manifest_v01.json` e `<actor_id>_frames_v01.tres`):
   - `vulto_mudo` (44 frames, 16 animações)
   - `espreitador_da_fenda` (44 frames, 16 animações)
   - `baluarte_de_cinza` (44 frames, 16 animações)
   - `soberano_do_limiar` (44 frames, 16 animações)
   - `chefe_soberano_limiar` (48 frames, 26 animações) + retoques Art Director
   - `iniciado_pactos` (44 frames, 8 animações)
3. Silhuetas e Retratos de Maldição (`story-007`) em `assets/art/ui/maldicoes/`:
   - 5 silhuetas em 72x72 e 56x56 PNG transparente (zero pixels magenta #E0259C).
   - 4 retratos de busto em PNG transparente.
4. Assets de UI, Cartas, Glifos, HUD, Cenário, Peças e LUT (`story-008`):
   - `assets/art/lut/limiar.png` (1024x32 3D LUT 32^3 lossless) + `limiar.png.import`
   - `assets/art/ui/cartas/` (8 elementos de U1, molduras 320x500)
   - `assets/art/ui/glifos/` (12 ícones de U2)
   - `assets/art/ui/hud/` (8 conjuntos de U3)
   - `assets/art/environment/limiar/` (22 peças de C1, C2 e C3)
   - `assets/art/runtime/pecas_doutrinas/` (8 peças de W0)
"""

from __future__ import annotations

import json
import math
from collections import deque
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "assets" / "art" / "source" / "raw"
RUNTIME_DIR = ROOT / "assets" / "art" / "runtime"
UI_DIR = ROOT / "assets" / "art" / "ui"
ENV_DIR = ROOT / "assets" / "art" / "environment" / "limiar"
LUT_DIR = ROOT / "assets" / "art" / "lut"


def is_green_mask(rgb: np.ndarray, mode: str = "standard") -> np.ndarray:
    """Detecta pixels de chroma-key verde #00FF00."""
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    if mode == "strict":
        return (g > 155) & ((g - np.maximum(r, b)) > 65)
    return (g > 110) & ((g - np.maximum(r, b)) > 40)


def flood_fill_external(mask: np.ndarray) -> np.ndarray:
    """Flood-fill 4-conectado a partir das 4 bordas da imagem/recorte."""
    h, w = mask.shape
    ext = np.zeros((h, w), dtype=bool)
    q: deque[Tuple[int, int]] = deque()

    for x in range(w):
        if mask[0, x] and not ext[0, x]:
            ext[0, x] = True
            q.append((0, x))
        if mask[h - 1, x] and not ext[h - 1, x]:
            ext[h - 1, x] = True
            q.append((h - 1, x))
    for y in range(h):
        if mask[y, 0] and not ext[y, 0]:
            ext[y, 0] = True
            q.append((y, 0))
        if mask[y, w - 1] and not ext[y, w - 1]:
            ext[y, w - 1] = True
            q.append((y, w - 1))

    while q:
        cy, cx = q.popleft()
        if cy > 0 and mask[cy - 1, cx] and not ext[cy - 1, cx]:
            ext[cy - 1, cx] = True
            q.append((cy - 1, cx))
        if cy + 1 < h and mask[cy + 1, cx] and not ext[cy + 1, cx]:
            ext[cy + 1, cx] = True
            q.append((cy + 1, cx))
        if cx > 0 and mask[cy, cx - 1] and not ext[cy, cx - 1]:
            ext[cy, cx - 1] = True
            q.append((cy, cx - 1))
        if cx + 1 < w and mask[cy, cx + 1] and not ext[cy, cx + 1]:
            ext[cy, cx + 1] = True
            q.append((cy, cx + 1))

    return ext


def remove_green_chroma(img: Image.Image, external_only: bool = False) -> Image.Image:
    """
    Remove fundo verde #00FF00 por flood-fill externo + chaveamento de vãos internos
    verdes + despill de borda verde.
    """
    rgba = np.array(img.convert("RGBA"), dtype=np.uint8)
    rgb = rgba[:, :, :3]

    green_std = is_green_mask(rgb, "standard")
    bg_mask = flood_fill_external(green_std)
    if not external_only:
        green_inner = is_green_mask(rgb, "strict")
        bg_mask = bg_mask | green_inner

    rgba[bg_mask, 3] = 0
    rgba[bg_mask, :3] = 0

    # Despill de borda verde em pixels não-transparentes com contaminação de #00FF00
    fg = ~bg_mask
    r = rgba[:, :, 0].astype(np.int16)
    g = rgba[:, :, 1].astype(np.int16)
    b = rgba[:, :, 2].astype(np.int16)
    max_rb = np.maximum(r, b)
    spill = fg & ((g - max_rb) > 18)
    if np.any(spill):
        excess = g[spill] - max_rb[spill]
        # Pixels muito verdes na transição ganham alpha proporcional e g neutralizado
        alpha_scale = np.clip(1.0 - (excess - 18) / 90.0, 0.0, 1.0)
        rgba[spill, 3] = (rgba[spill, 3].astype(np.float32) * alpha_scale).astype(np.uint8)
        rgba[spill, 1] = max_rb[spill].astype(np.uint8)
        dead = spill & (rgba[:, :, 3] < 24)
        rgba[dead] = 0

    return Image.fromarray(rgba, mode="RGBA")


def clean_magenta_in_region(img: Image.Image, box: Tuple[int, int, int, int]) -> Image.Image:
    """
    Retoque Art Director (B1-F poses 1 e 2): remove pontos magenta na face,
    convertendo-os para tinta #0D0E14.
    """
    rgba = np.array(img, dtype=np.uint8)
    x0, y0, x1, y1 = box
    sub = rgba[y0:y1, x0:x1]
    r = sub[:, :, 0].astype(np.int16)
    g = sub[:, :, 1].astype(np.int16)
    b = sub[:, :, 2].astype(np.int16)
    a = sub[:, :, 3]
    mag = (a > 0) & (r > 120) & (b > 80) & ((r - g) > 45)
    sub[mag, 0] = 13
    sub[mag, 1] = 14
    sub[mag, 2] = 20
    rgba[y0:y1, x0:x1] = sub
    return Image.fromarray(rgba, mode="RGBA")


def purge_any_magenta(img: Image.Image) -> Tuple[Image.Image, int]:
    """Garante ZERO pixels magenta (#E0259C) em silhuetas e retratos de maldição."""
    rgba = np.array(img, dtype=np.uint8)
    r = rgba[:, :, 0].astype(np.int16)
    g = rgba[:, :, 1].astype(np.int16)
    b = rgba[:, :, 2].astype(np.int16)
    a = rgba[:, :, 3]
    mag = (a > 0) & (r > 130) & (b > 90) & ((r - g) > 45) & ((b - g) > 25)
    count = int(np.sum(mag))
    if count > 0:
        lum = ((r[mag] + g[mag] + b[mag]) // 3).astype(np.uint8)
        rgba[mag, 0] = lum
        rgba[mag, 1] = lum
        rgba[mag, 2] = lum
    return Image.fromarray(rgba, mode="RGBA"), count


def find_1d_cuts(occupied: np.ndarray, count: int, search_radius: int = 85) -> List[int]:
    """Encontra cortes ótimos em vãos transparentes próximos à divisão nominal."""
    length = len(occupied)
    cuts = [0]
    for i in range(1, count):
        nominal = int(round(i * length / count))
        best = nominal
        found = False
        for d in range(search_radius + 1):
            for cand in (nominal - d, nominal + d):
                if 0 < cand < length and not occupied[cand]:
                    best = cand
                    found = True
                    break
            if found:
                break
        if found:
            left = best
            right = best
            while left > 0 and not occupied[left - 1]:
                left -= 1
            while right + 1 < length and not occupied[right + 1]:
                right += 1
            best = (left + right) // 2
        cuts.append(best)
    cuts.append(length)
    return cuts


def extract_grid_cells(
    rgba_img: Image.Image,
    cols_per_row: List[int],
    use_uniform_grid_cells: List[Tuple[int, int]] | None = None,
) -> List[Image.Image]:
    """
    Divide uma folha RGBA nas fileiras/colunas especificadas e retorna o recorte
    (bounding box de pixels visíveis) de cada pose.
    """
    arr = np.array(rgba_img, dtype=np.uint8)
    alpha = arr[:, :, 3] > 10
    h, w = alpha.shape
    rows = len(cols_per_row)

    row_occ = np.any(alpha, axis=1)
    row_cuts = find_1d_cuts(row_occ, rows, search_radius=65)

    crops: List[Image.Image] = []
    uniform_set = set(use_uniform_grid_cells or [])

    for r in range(rows):
        y0, y1 = row_cuts[r], row_cuts[r + 1]
        cols = cols_per_row[r]
        col_occ = np.any(alpha[y0:y1, :], axis=0)
        col_cuts = find_1d_cuts(col_occ, cols, search_radius=75)

        for c in range(cols):
            if (r, c) in uniform_set:
                cx0 = int(round(c * w / cols))
                cx1 = int(round((c + 1) * w / cols))
                cy0 = int(round(r * h / rows))
                cy1 = int(round((r + 1) * h / rows))
                cx0 = min(cx0, col_cuts[c])
                cx1 = max(cx1, col_cuts[c + 1])
                cy0 = min(cy0, y0)
                cy1 = max(cy1, y1)
            else:
                cx0, cx1 = col_cuts[c], col_cuts[c + 1]
                cy0, cy1 = y0, y1

            cell_alpha = alpha[cy0:cy1, cx0:cx1]
            ys, xs = np.nonzero(cell_alpha)
            if len(xs) == 0:
                crops.append(Image.new("RGBA", (16, 16), (0, 0, 0, 0)))
                continue
            bx0, bx1 = int(xs.min()), int(xs.max()) + 1
            by0, by1 = int(ys.min()), int(ys.max()) + 1
            crop = rgba_img.crop((cx0 + bx0, cy0 + by0, cx0 + bx1, cy0 + by1))
            crops.append(crop)

    return crops


def place_in_400x400_cell(crop: Image.Image, target_max_w: int = 340, target_max_h: int = 290) -> Image.Image:
    """
    Posiciona um recorte de pose numa célula 400x400 ancorada pelo centro-base
    no pivô [200, 320]. Se exceder a área segura, aplica redução proporcional.
    """
    cw, ch = crop.size
    if cw > target_max_w or ch > target_max_h:
        scale = min(target_max_w / float(cw), target_max_h / float(ch))
        nw = max(1, int(round(cw * scale)))
        nh = max(1, int(round(ch * scale)))
        crop = crop.resize((nw, nh), Image.Resampling.LANCZOS)
        cw, ch = nw, nh

    cell = Image.new("RGBA", (400, 400), (0, 0, 0, 0))
    px = max(0, min(400 - cw, 200 - cw // 2))
    py = max(0, min(400 - ch, 320 - ch))
    cell.paste(crop, (px, py), crop)
    return cell


def build_actor_atlas(
    actor_id: str,
    frames: List[Image.Image],
    animations: List[Tuple[str, int, bool, List[float]]],
    logical_size: float,
    scale_val: float,
) -> Dict[str, int]:
    """
    Empacota `frames` (lista de células 400x400) em `<actor_id>_atlas_v01.png`
    (grade de 8 colunas), gera `atlas_manifest_v01.json` e `<actor_id>_frames_v01.tres`.
    """
    out_dir = RUNTIME_DIR / actor_id
    out_dir.mkdir(parents=True, exist_ok=True)

    total_frames = len(frames)
    cols = 8
    rows = math.ceil(total_frames / cols)
    atlas_img = Image.new("RGBA", (cols * 400, rows * 400), (0, 0, 0, 0))

    for idx, cell in enumerate(frames):
        gx = (idx % cols) * 400
        gy = (idx // cols) * 400
        atlas_img.paste(cell, (gx, gy))

    atlas_path = out_dir / f"{actor_id}_atlas_v01.png"
    atlas_img.save(atlas_path, format="PNG")

    # Manifest JSON
    manifest_anims: Dict[str, dict] = {}
    for anim_name, count, looped, _durations in animations:
        manifest_anims[anim_name] = {
            "scale": round(scale_val, 4),
            "frames": count,
            "loop": looped,
            "fps": 12,
        }

    manifest = {
        "status": "runtime_ready",
        "canvas": [400, 400],
        "pivot": [200, 320],
        "logical_size": logical_size,
        "animations": manifest_anims,
    }
    manifest_path = out_dir / "atlas_manifest_v01.json"
    manifest_path.write_text(json.dumps(manifest, indent="\t") + "\n", encoding="utf-8")

    # SpriteFrames .tres
    load_steps = 2 + total_frames
    res_atlas_path = f"res://assets/art/runtime/{actor_id}/{actor_id}_atlas_v01.png"
    lines: List[str] = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{res_atlas_path}" id="1"]',
        "",
    ]

    for idx in range(total_frames):
        gx = (idx % cols) * 400
        gy = (idx // cols) * 400
        lines.extend(
            [
                f'[sub_resource type="AtlasTexture" id="frame_{idx:02d}"]',
                'atlas = ExtResource("1")',
                f"region = Rect2({gx}, {gy}, 400, 400)",
                "filter_clip = true",
                "",
            ]
        )

    anim_entries: List[str] = []
    cursor = 0
    for anim_name, count, looped, durations in animations:
        f_list: List[str] = []
        for i in range(count):
            dur = durations[i] if i < len(durations) else 1.0
            f_list.append(f'{{"duration": {dur:.1f}, "texture": SubResource("frame_{cursor:02d}")}}')
            cursor += 1
        loop_str = "true" if looped else "false"
        anim_entries.append(
            f'{{"frames": [{", ".join(f_list)}], "loop": {loop_str}, "name": &"{anim_name}", "speed": 12.0}}'
        )

    assert cursor == total_frames, f"{actor_id}: animation frames sum {cursor} != {total_frames}"

    lines.append("[resource]")
    lines.append("animations = [" + ",\n".join(anim_entries) + "]")
    tres_path = out_dir / f"{actor_id}_frames_v01.tres"
    tres_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    return {"frames": total_frames, "animations": len(animations), "width": cols * 400, "height": rows * 400}


def load_and_key_raw(filename: str, external_only: bool = False) -> Image.Image:
    path = RAW_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"Arquivo raw não encontrado: {path}")
    img = Image.open(path)
    return remove_green_chroma(img, external_only=external_only)


def pack_all_actors() -> Dict[str, Dict[str, int]]:
    results: Dict[str, Dict[str, int]] = {}

    std_16_anims: List[Tuple[str, int, bool, List[float]]] = [
        ("spawn_frente34", 4, False, [1.0, 1.0, 1.0, 1.0]),
        ("idle_frente34", 2, True, [1.0, 1.0]),
        ("run_frente34", 6, True, [1.0] * 6),
        ("spawn_costas34", 4, False, [1.0, 1.0, 1.0, 1.0]),
        ("idle_costas34", 2, True, [1.0, 1.0]),
        ("run_costas34", 6, True, [1.0] * 6),
        ("windup_frente34", 3, False, [1.5, 1.5, 3.0]),
        ("attack_frente34", 2, False, [1.0, 1.0]),
        ("recover_frente34", 2, False, [5.0, 5.0]),
        ("hurt_frente34", 1, False, [1.0]),
        ("death_frente34", 2, False, [1.0, 1.0]),
        ("windup_costas34", 3, False, [1.5, 1.5, 3.0]),
        ("attack_costas34", 2, False, [1.0, 1.0]),
        ("recover_costas34", 2, False, [5.0, 5.0]),
        ("hurt_costas34", 1, False, [1.0]),
        ("death_costas34", 2, False, [1.0, 1.0]),
    ]

    # 1. vulto_mudo (VM1-F tem 14 poses em 3 fileiras: 6 + 4 + 4 -> pega 6 da fileira 1 e 6 das fileiras 2-3)
    vm1_f = load_and_key_raw("mal_vulto_mudo_spawnrun_frente34_raw_v01.jpg")
    vm1_f_cells = extract_grid_cells(vm1_f, [6, 4, 4])
    vm1_f_12 = vm1_f_cells[:6] + vm1_f_cells[6:12]

    vm1_c = extract_grid_cells(load_and_key_raw("mal_vulto_mudo_spawnrun_costas34_raw_v01.jpg"), [6, 6])
    vm2_f = extract_grid_cells(load_and_key_raw("mal_vulto_mudo_ataquemorte_frente34_raw_v01.jpg"), [5, 5])
    vm2_c = extract_grid_cells(load_and_key_raw("mal_vulto_mudo_ataquemorte_costas34_raw_v01.jpg"), [5, 5])
    vm_frames = [place_in_400x400_cell(c) for c in (vm1_f_12 + vm1_c + vm2_f + vm2_c)]
    results["vulto_mudo"] = build_actor_atlas("vulto_mudo", vm_frames, std_16_anims, 92.0, 0.4100)

    # 2. espreitador_da_fenda
    ef1_f = extract_grid_cells(load_and_key_raw("mal_espreitador_fenda_spawnrun_frente34_raw_v01.jpg"), [6, 6])
    ef1_c = extract_grid_cells(load_and_key_raw("mal_espreitador_fenda_spawnrun_costas34_raw_v01.jpg"), [6, 6])
    ef2_f = extract_grid_cells(load_and_key_raw("mal_espreitador_fenda_ataquemorte_frente34_raw_v01.jpg"), [5, 5])
    ef2_c = extract_grid_cells(load_and_key_raw("mal_espreitador_fenda_ataquemorte_costas34_raw_v01.jpg"), [5, 5])
    ef_frames = [place_in_400x400_cell(c) for c in (ef1_f + ef1_c + ef2_f + ef2_c)]
    results["espreitador_da_fenda"] = build_actor_atlas("espreitador_da_fenda", ef_frames, std_16_anims, 98.0, 0.4200)

    # 3. baluarte_de_cinza
    bc1_f = extract_grid_cells(load_and_key_raw("mal_baluarte_cinza_spawnrun_frente34_raw_v01.jpg"), [6, 6])
    bc1_c = extract_grid_cells(load_and_key_raw("mal_baluarte_cinza_spawnrun_costas34_raw_v01.jpg"), [6, 6])
    bc2_f = extract_grid_cells(load_and_key_raw("mal_baluarte_cinza_ataquemorte_frente34_raw_v01.jpg"), [5, 5])
    bc2_c = extract_grid_cells(load_and_key_raw("mal_baluarte_cinza_ataquemorte_costas34_raw_v01.jpg"), [5, 5])
    bc_frames = [place_in_400x400_cell(c) for c in (bc1_f + bc1_c + bc2_f + bc2_c)]
    results["baluarte_de_cinza"] = build_actor_atlas("baluarte_de_cinza", bc_frames, std_16_anims, 118.0, 0.4600)

    # 4. soberano_do_limiar (forma aliada)
    sa1_f = extract_grid_cells(load_and_key_raw("mal_soberano_aliado_spawnrun_frente34_raw_v01.jpg", external_only=True), [6, 6])
    sa1_c = extract_grid_cells(load_and_key_raw("mal_soberano_aliado_spawnrun_costas34_raw_v01.jpg", external_only=True), [6, 6])
    sa2_f = extract_grid_cells(load_and_key_raw("mal_soberano_aliado_ataquemorte_frente34_raw_v01.jpg", external_only=True), [5, 5])
    sa2_c = extract_grid_cells(load_and_key_raw("mal_soberano_aliado_ataquemorte_costas34_raw_v01.jpg", external_only=True), [5, 5])
    sa_frames = [place_in_400x400_cell(c) for c in (sa1_f + sa1_c + sa2_f + sa2_c)]
    results["soberano_do_limiar"] = build_actor_atlas("soberano_do_limiar", sa_frames, std_16_anims, 115.0, 0.4500)

    # 5. chefe_soberano_limiar (48 frames, 26 animações) + retoques Art Director
    b1_f_img = load_and_key_raw("bos_soberano_limiar_movgarra_frente34_raw_v01.jpg")
    # Retoque Art Director em B1-F poses 1 e 2: limpar pontos magenta na face (abaixo da coroa)
    b1_f_img = clean_magenta_in_region(b1_f_img, (80, 225, 200, 265))   # Pose 1 face
    b1_f_img = clean_magenta_in_region(b1_f_img, (300, 130, 390, 175))  # Pose 2 face
    b1_f = extract_grid_cells(b1_f_img, [6, 6])
    b1_c = extract_grid_cells(load_and_key_raw("bos_soberano_limiar_movgarra_costas34_raw_v01.jpg"), [6, 6])

    # Retoque Art Director em B2-F/B2-C pose 12 (row 1, col 5): recortar pela célula da grade 6x2 para manter todos os estilhaços juntos
    b2_f = extract_grid_cells(
        load_and_key_raw("bos_soberano_limiar_ataquesfuria_frente34_raw_v01.jpg"),
        [6, 6],
        use_uniform_grid_cells=[(1, 5)],
    )
    b2_c = extract_grid_cells(
        load_and_key_raw("bos_soberano_limiar_ataquesfuria_costas34_raw_v01.jpg"),
        [6, 6],
        use_uniform_grid_cells=[(1, 5)],
    )

    boss_anims: List[Tuple[str, int, bool, List[float]]] = [
        ("spawn_frente34", 4, False, [1.0, 1.0, 1.0, 1.0]),
        ("idle_frente34", 2, True, [1.0, 1.0]),
        ("run_frente34", 3, True, [1.0, 1.0, 1.0]),
        ("windup_frente34", 1, False, [2.5]),
        ("attack_frente34", 1, False, [1.5]),
        ("recover_frente34", 1, False, [4.0]),
        ("spawn_costas34", 4, False, [1.0, 1.0, 1.0, 1.0]),
        ("idle_costas34", 2, True, [1.0, 1.0]),
        ("run_costas34", 3, True, [1.0, 1.0, 1.0]),
        ("windup_costas34", 1, False, [2.5]),
        ("attack_costas34", 1, False, [1.5]),
        ("recover_costas34", 1, False, [4.0]),
        ("irrupcao_frente34", 2, False, [2.0, 1.5]),
        ("pulso_frente34", 2, False, [2.0, 2.0]),
        ("convergencia_frente34", 2, False, [2.0, 2.0]),
        ("furia_frente34", 2, False, [2.0, 2.5]),
        ("hurt_frente34", 1, False, [1.0]),
        ("subjugado_frente34", 2, True, [2.0, 2.0]),
        ("death_frente34", 1, False, [4.0]),
        ("irrupcao_costas34", 2, False, [2.0, 1.5]),
        ("pulso_costas34", 2, False, [2.0, 2.0]),
        ("convergencia_costas34", 2, False, [2.0, 2.0]),
        ("furia_costas34", 2, False, [2.0, 2.5]),
        ("hurt_costas34", 1, False, [1.0]),
        ("subjugado_costas34", 2, True, [2.0, 2.0]),
        ("death_costas34", 1, False, [4.0]),
    ]
    boss_frames = [place_in_400x400_cell(c, 360, 300) for c in (b1_f + b1_c + b2_f + b2_c)]
    results["chefe_soberano_limiar"] = build_actor_atlas(
        "chefe_soberano_limiar", boss_frames, boss_anims, 168.0, 0.5800
    )

    # 6. iniciado_pactos (44 frames, 8 animações)
    p1_f = extract_grid_cells(load_and_key_raw("chr_iniciado_pactos_idlevirote_frente34_raw_v01.jpg"), [6, 6])
    p1_c = extract_grid_cells(load_and_key_raw("chr_iniciado_pactos_idlevirote_costas34_raw_v01.jpg"), [6, 6])
    p2_f = extract_grid_cells(load_and_key_raw("chr_iniciado_pactos_chamado_frente34_raw_v01.jpg"), [5, 5])
    p2_c = extract_grid_cells(load_and_key_raw("chr_iniciado_pactos_chamado_costas34_raw_v01.jpg"), [5, 5])
    pactos_anims: List[Tuple[str, int, bool, List[float]]] = [
        ("idle_frente34", 6, True, [1.0] * 6),
        ("virote_frente34", 6, False, [1.0] * 6),
        ("idle_costas34", 6, True, [1.0] * 6),
        ("virote_costas34", 6, False, [1.0] * 6),
        ("chamado_frente34", 6, False, [1.0] * 6),
        ("troca_frente34", 4, False, [1.0] * 4),
        ("chamado_costas34", 6, False, [1.0] * 6),
        ("troca_costas34", 4, False, [1.0] * 4),
    ]
    pactos_frames = [place_in_400x400_cell(c) for c in (p1_f + p1_c + p2_f + p2_c)]
    results["iniciado_pactos"] = build_actor_atlas(
        "iniciado_pactos", pactos_frames, pactos_anims, 94.0, 0.4087
    )

    return results


def pack_maldicoes_ui() -> List[str]:
    """Recorta U4 (`ui_maldicoes_silhuetas_retratos_raw_v01.jpg`) para `assets/art/ui/maldicoes/`."""
    out_dir = UI_DIR / "maldicoes"
    out_dir.mkdir(parents=True, exist_ok=True)

    u4 = load_and_key_raw("ui_maldicoes_silhuetas_retratos_raw_v01.jpg", external_only=True)
    cells = extract_grid_cells(u4, [5, 4])

    silhuetas_names = [
        "silhueta_vulto_mudo",
        "silhueta_espreitador_da_fenda",
        "silhueta_baluarte_de_cinza",
        "silhueta_soberano_do_limiar",
        "silhueta_generica",
    ]
    retratos_names = [
        "retrato_vulto_mudo.png",
        "retrato_espreitador_da_fenda.png",
        "retrato_baluarte_de_cinza.png",
        "retrato_soberano_do_limiar.png",
    ]

    generated: List[str] = []
    for i, base_name in enumerate(silhuetas_names):
        clean_cell, _ = purge_any_magenta(cells[i])
        for sz in (72, 56):
            resized = clean_cell.resize((sz, sz), Image.Resampling.LANCZOS)
            resized, _ = purge_any_magenta(resized)
            out_path = out_dir / f"{base_name}_{sz}.png"
            resized.save(out_path, format="PNG")
            generated.append(str(out_path.relative_to(ROOT)))

    for i, r_name in enumerate(retratos_names):
        clean_cell, _ = purge_any_magenta(cells[5 + i])
        out_path = out_dir / r_name
        clean_cell.save(out_path, format="PNG")
        generated.append(str(out_path.relative_to(ROOT)))

    return generated


def generate_limiar_lut() -> List[str]:
    """
    Gera `assets/art/lut/limiar.png` (1024x32 3D LUT 32^3 desenrolada horizontalmente)
    com grading frio de Limiar nas sombras ardósia (#141821) preservando na íntegra
    os tons de Magenta (#E0259C), Ouro (#E3B23C) e Osso (#E6DFCF), mais `limiar.png.import`.
    """
    LUT_DIR.mkdir(parents=True, exist_ok=True)
    lut = np.zeros((32, 1024, 3), dtype=np.uint8)

    # Cores protegidas (normalizadas 0..1)
    protected = [
        np.array([0xE0, 0x25, 0x9C], dtype=np.float32) / 255.0,  # Magenta #E0259C
        np.array([0xE3, 0xB2, 0x3C], dtype=np.float32) / 255.0,  # Ouro #E3B23C
        np.array([0xE6, 0xDF, 0xCF], dtype=np.float32) / 255.0,  # Osso claro #E6DFCF
        np.array([0xCF, 0xC6, 0xB4], dtype=np.float32) / 255.0,  # Osso #CFC6B4
    ]
    slate_tint = np.array([-0.015, 0.0, 0.032], dtype=np.float32)

    for b_idx in range(32):
        b_val = b_idx / 31.0
        for g_idx in range(32):
            g_val = g_idx / 31.0
            for r_idx in range(32):
                r_val = r_idx / 31.0
                c = np.array([r_val, g_val, b_val], dtype=np.float32)

                # Distância mínima para as cores protegidas
                min_dist = min(float(np.linalg.norm(c - p)) for p in protected)
                # Peso de proteção: 1.0 perto das cores de acento/osso, 0.0 longe
                protection = np.clip(1.0 - min_dist / 0.35, 0.0, 1.0)

                # Peso de sombra/meio-tom neutro para grading frio de ardósia (#141821)
                lum = 0.2126 * r_val + 0.7152 * g_val + 0.0722 * b_val
                sat = float(np.max(c) - np.min(c))
                shadow_weight = (1.0 - lum) * lum * 4.0 * (1.0 - np.clip(sat * 2.5, 0.0, 1.0))
                effect = shadow_weight * (1.0 - protection)

                out_c = np.clip(c + slate_tint * effect, 0.0, 1.0)
                x = b_idx * 32 + r_idx
                lut[g_idx, x] = np.round(out_c * 255.0).astype(np.uint8)

    lut_path = LUT_DIR / "limiar.png"
    Image.fromarray(lut, mode="RGB").save(lut_path, format="PNG")

    import_text = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://ckhaeroslutlimiar"
path="res://.godot/imported/limiar.png-00000000000000000000000000000000.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="res://assets/art/lut/limiar.png"
dest_files=["res://.godot/imported/limiar.png-00000000000000000000000000000000.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""
    import_path = LUT_DIR / "limiar.png.import"
    import_path.write_text(import_text, encoding="utf-8")

    return [str(lut_path.relative_to(ROOT)), str(import_path.relative_to(ROOT))]


def pack_ui_and_environment() -> List[str]:
    generated: List[str] = []

    # U1: Cartas (`assets/art/ui/cartas/`) - flood-fill externo para preservar interior #0D0E14
    # Layout visual de U1:
    # Colunas 0, 1, 2 têm Molduras no topo e Coroas na base;
    # Coluna 3 tem Selo de Preço no topo e Verso da Carta na base.
    cartas_dir = UI_DIR / "cartas"
    cartas_dir.mkdir(parents=True, exist_ok=True)
    u1 = load_and_key_raw("ui_cartas_molduras_coroas_raw_v01.jpg", external_only=True)
    u1_arr = np.array(u1, dtype=np.uint8)
    u1_alpha = u1_arr[:, :, 3] > 10
    col_cuts = find_1d_cuts(np.any(u1_alpha, axis=0), 4, search_radius=75)

    col_top_bottom: List[Tuple[Image.Image, Image.Image]] = []
    for c in range(4):
        cx0, cx1 = col_cuts[c], col_cuts[c + 1]
        sub_alpha = u1_alpha[:, cx0:cx1]
        r_cuts = find_1d_cuts(np.any(sub_alpha, axis=1), 2, search_radius=120)
        pair: List[Image.Image] = []
        for r in range(2):
            ry0, ry1 = r_cuts[r], r_cuts[r + 1]
            cell_a = sub_alpha[ry0:ry1, :]
            ys, xs = np.nonzero(cell_a)
            bx0, bx1 = int(xs.min()), int(xs.max()) + 1
            by0, by1 = int(ys.min()), int(ys.max()) + 1
            pair.append(u1.crop((cx0 + bx0, ry0 + by0, cx0 + bx1, ry0 + by1)))
        col_top_bottom.append((pair[0], pair[1]))

    u1_items = [
        ("moldura_comum.png", col_top_bottom[0][0].resize((320, 500), Image.Resampling.LANCZOS)),
        ("moldura_rara.png", col_top_bottom[1][0].resize((320, 500), Image.Resampling.LANCZOS)),
        ("moldura_epica.png", col_top_bottom[2][0].resize((320, 500), Image.Resampling.LANCZOS)),
        ("selo_preco.png", col_top_bottom[3][0]),
        ("coroa_lamina.png", col_top_bottom[0][1]),
        ("coroa_ressonancia.png", col_top_bottom[1][1]),
        ("coroa_pactos.png", col_top_bottom[2][1]),
        ("verso_carta.png", col_top_bottom[3][1].resize((320, 500), Image.Resampling.LANCZOS)),
    ]
    for fname, im in u1_items:
        p = cartas_dir / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    # U2: Glifos (`assets/art/ui/glifos/`) - 12 ícones em 2 fileiras de 6 (y=0..502)
    glifos_dir = UI_DIR / "glifos"
    glifos_dir.mkdir(parents=True, exist_ok=True)
    u2_full = load_and_key_raw("ui_glifos_tradicoes_status_raw_v01.jpg", external_only=True)
    u2_cropped = u2_full.crop((0, 0, u2_full.width, 505))
    u2_cells = extract_grid_cells(u2_cropped, [6, 6])
    u2_names = [
        "traco_unico.png",
        "corte_fantasma.png",
        "fundo_do_poco.png",
        "linha_contada.png",
        "materia_residual.png",
        "os_que_ficam.png",
        "slot_ataque.png",
        "slot_especial.png",
        "slot_selo.png",
        "status_sangramento.png",
        "status_queimadura.png",
        "status_abalo.png",
    ]
    for fname, im in zip(u2_names, u2_cells):
        p = glifos_dir / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    # U3: HUD (`assets/art/ui/hud/`) - 8 conjuntos em 2 fileiras de 4, removendo verde externo e interno
    hud_dir = UI_DIR / "hud"
    hud_dir.mkdir(parents=True, exist_ok=True)
    u3 = load_and_key_raw("ui_hud_elementos_raw_v01.jpg", external_only=False)
    u3_cells = extract_grid_cells(u3, [4, 4])
    u3_names = [
        "placa_fundo.png",
        "segmentos_vida.png",
        "moldura_vida_baixa.png",
        "recusa_escudo.png",
        "gota_fluxo.png",
        "chevrons_esquiva.png",
        "icone_fragmento.png",
        "barra_chefe.png",
    ]
    for fname, im in zip(u3_names, u3_cells):
        p = hud_dir / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    # C1, C2, C3: Cenário do Limiar (`assets/art/environment/limiar/`)
    ENV_DIR.mkdir(parents=True, exist_ok=True)
    c1 = extract_grid_cells(load_and_key_raw("env_limiar_chao_bordas_raw_v01.jpg", external_only=True), [4, 4])
    c1_names = [
        "chao_laje_01.png",
        "chao_laje_02.png",
        "chao_laje_03.png",
        "chao_laje_04.png",
        "borda_parede_01.png",
        "borda_parede_02.png",
        "borda_parede_03.png",
        "borda_parede_04.png",
    ]
    for fname, im in zip(c1_names, c1):
        p = ENV_DIR / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    c2 = extract_grid_cells(load_and_key_raw("env_limiar_pilares_santuario_raw_v01.jpg", external_only=True), [3, 3])
    c2_names = [
        "obstaculo_rocha_01.png",
        "obstaculo_rocha_02.png",
        "obstaculo_rocha_03.png",
        "obstaculo_coluna_04.png",
        "pilar_chefe.png",
        "altar_santuario.png",
    ]
    for fname, im in zip(c2_names, c2):
        p = ENV_DIR / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    c3 = extract_grid_cells(load_and_key_raw("env_limiar_portas_foreground_raw_v01.jpg", external_only=True), [4, 4])
    c3_names = [
        "porta_fechada.png",
        "porta_aberta.png",
        "porta_chefe.png",
        "pedestal_pacto.png",
        "totem_bencao.png",
        "totem_fragmentos.png",
        "totem_cura.png",
        "foreground_silhueta.png",
    ]
    for fname, im in zip(c3_names, c3):
        p = ENV_DIR / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    # W0: Peças de Doutrinas e Projéteis (`assets/art/runtime/pecas_doutrinas/`)
    w0_dir = RUNTIME_DIR / "pecas_doutrinas"
    w0_dir.mkdir(parents=True, exist_ok=True)
    w0 = extract_grid_cells(load_and_key_raw("wep_pecas_doutrinas_raw_v01.jpg", external_only=False), [4, 4])
    w0_names = [
        "emblema_lamina.png",
        "emblema_ressonancia.png",
        "emblema_pactos.png",
        "virote_vinculo.png",
        "pulso_ressonante.png",
        "projetil_anomalia.png",
        "marca_virote.png",
        "indicador_atracao.png",
    ]
    for fname, im in zip(w0_names, w0):
        p = w0_dir / fname
        im.save(p, format="PNG")
        generated.append(str(p.relative_to(ROOT)))

    return generated


def validate_all_runtime_atlases() -> None:
    """
    Valida matematicamente todos os atores em `assets/art/runtime/` (existentes + novos):
    verifica que `.json`, `.tres` e `.png` batem em contagem de animações e frames, e
    que todas as regiões `400x400` estão estritamente dentro dos limites do atlas.
    """
    import re

    expected_actors = {
        "anomalia_menor": {"frames": 44, "animations": 16},
        "eco_perdido": {"frames": 44, "animations": 16},
        "fenda_errante": {"frames": 44, "animations": 16},
        "iniciado_lamina": {"frames": 108, "animations": 18},
        "elite_pecas": {"frames": 6, "animations": 6},
        "vulto_mudo": {"frames": 44, "animations": 16},
        "espreitador_da_fenda": {"frames": 44, "animations": 16},
        "baluarte_de_cinza": {"frames": 44, "animations": 16},
        "soberano_do_limiar": {"frames": 44, "animations": 16},
        "chefe_soberano_limiar": {"frames": 48, "animations": 26},
        "iniciado_pactos": {"frames": 44, "animations": 8},
    }

    rect_re = re.compile(r"region\s*=\s*Rect2\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)")
    anim_re = re.compile(r'"name":\s*&"([^"]+)"')
    sub_re = re.compile(r'SubResource\("frame_\d+"\)')

    for actor_id, spec in expected_actors.items():
        actor_dir = RUNTIME_DIR / actor_id
        tres_path = actor_dir / f"{actor_id}_frames_v01.tres"
        json_path = actor_dir / "atlas_manifest_v01.json"
        assert tres_path.exists(), f"Missing {tres_path}"
        assert json_path.exists(), f"Missing {json_path}"

        manifest = json.loads(json_path.read_text(encoding="utf-8"))
        assert "animations" in manifest, f"Invalid manifest {json_path}"
        assert len(manifest["animations"]) == spec["animations"], (
            f"{actor_id}: manifest animations {len(manifest['animations'])} != {spec['animations']}"
        )

        tres_text = tres_path.read_text(encoding="utf-8")
        anim_names = anim_re.findall(tres_text)
        assert len(anim_names) == spec["animations"], (
            f"{actor_id}: tres animations {len(anim_names)} != {spec['animations']}"
        )
        for aname in anim_names:
            assert aname in manifest["animations"], f"{actor_id}: missing {aname} in manifest"

        frame_refs = sub_re.findall(tres_text)
        assert len(frame_refs) == spec["frames"], (
            f"{actor_id}: tres frame refs {len(frame_refs)} != {spec['frames']}"
        )

        atlas_png = actor_dir / f"{actor_id}_atlas_v01.png"
        if atlas_png.exists():
            with Image.open(atlas_png) as im:
                aw, ah = im.size
            regions = rect_re.findall(tres_text)
            assert len(regions) == spec["frames"], f"{actor_id}: region count {len(regions)} != {spec['frames']}"
            for rx, ry, rw, rh in regions:
                x, y, w, h = int(rx), int(ry), int(rw), int(rh)
                assert (w, h) == (400, 400), f"{actor_id}: invalid frame size {w}x{h}"
                assert 0 <= x and 0 <= y and x + w <= aw and y + h <= ah, (
                    f"{actor_id}: region ({x},{y},{w},{h}) out of bounds ({aw}x{ah})"
                )

        print(f"VALIDATED_ATLAS actor={actor_id} frames={spec['frames']} animations={spec['animations']}")


def main() -> None:
    print("=== [1/5] Empacotando Atlas de Atores (runtime) ===")
    actor_stats = pack_all_actors()
    for aid, st in actor_stats.items():
        print(f"  -> {aid}: {st['frames']} frames, {st['animations']} anims ({st['width']}x{st['height']})")

    print("=== [2/5] Empacotando Silhuetas e Retratos de Maldição (story-007) ===")
    mal_files = pack_maldicoes_ui()
    print(f"  -> {len(mal_files)} arquivos gerados em assets/art/ui/maldicoes/")

    print("=== [3/5] Gerando LUT 3D 32^3 do Limiar (story-008) ===")
    lut_files = generate_limiar_lut()
    print(f"  -> {', '.join(lut_files)}")

    print("=== [4/5] Empacotando UI (Cartas, Glifos, HUD), Cenário e Peças (story-008) ===")
    ui_env_files = pack_ui_and_environment()
    print(f"  -> {len(ui_env_files)} arquivos gerados")

    print("=== [5/5] Validando todos os Atlas de Runtime ===")
    validate_all_runtime_atlases()
    print("ALL_MVP_ART_PACKAGED_AND_VALIDATED_OK")


if __name__ == "__main__":
    main()

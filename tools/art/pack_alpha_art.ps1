Add-Type -AssemblyName System.Drawing

$csCode = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class AlphaArtPacker {
    private static bool IsPureGreenBg(byte r, byte g, byte b) {
        int maxRB = Math.Max(r, b);
        // Preserva ciano (#7DD3FC tem B alto) e dourado (#E3B23C tem R alto)
        return g > 125 && (g - maxRB) > 38 && b < 150 && r < 165;
    }

    private static bool IsInnerGreenIsland(byte r, byte g, byte b) {
        int maxRB = Math.Max(r, b);
        return g > 155 && (g - maxRB) > 55 && b < 130 && r < 140;
    }

    public static void CropKeyAndSave(Bitmap src, int x0, int y0, int w, int h, string outPath, int targetW, int targetH) {
        using (Bitmap crop = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(crop)) {
                g.DrawImage(src, new Rectangle(0, 0, w, h), new Rectangle(x0, y0, w, h), GraphicsUnit.Pixel);
            }

            BitmapData bd = crop.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int bytes = Math.Abs(bd.Stride) * h;
            byte[] buf = new byte[bytes];
            Marshal.Copy(bd.Scan0, buf, 0, bytes);
            int stride = bd.Stride;

            // 1. Flood-fill externo a partir das 4 bordas
            bool[] visited = new bool[w * h];
            Queue<int> q = new Queue<int>();
            Action<int, int> tryEnqueue = (px, py) => {
                if (px < 0 || py < 0 || px >= w || py >= h) return;
                int idx = py * w + px;
                if (visited[idx]) return;
                int off = py * stride + px * 4;
                if (IsPureGreenBg(buf[off + 2], buf[off + 1], buf[off])) {
                    visited[idx] = true;
                    q.Enqueue(idx);
                }
            };

            for (int x = 0; x < w; x++) { tryEnqueue(x, 0); tryEnqueue(x, h - 1); }
            for (int y = 0; y < h; y++) { tryEnqueue(0, y); tryEnqueue(w - 1, y); }

            while (q.Count > 0) {
                int cur = q.Dequeue();
                int cx = cur % w;
                int cy = cur / w;
                int off = cy * stride + cx * 4;
                buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
                tryEnqueue(cx - 1, cy);
                tryEnqueue(cx + 1, cy);
                tryEnqueue(cx, cy - 1);
                tryEnqueue(cx, cy + 1);
            }

            // 2. Remover ilhas internas puramente verdes (ex.: vãos de anéis/grades) preservando ciano/dourado
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int off = y * stride + x * 4;
                    if (buf[off + 3] == 0) continue;
                    byte b = buf[off], g = buf[off + 1], r = buf[off + 2];
                    if (IsInnerGreenIsland(r, g, b)) {
                        buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
                    }
                }
            }

            // 3. Despill suave nas bordas adjacentes a transparência
            for (int y = 1; y < h - 1; y++) {
                for (int x = 1; x < w - 1; x++) {
                    int off = y * stride + x * 4;
                    if (buf[off + 3] == 0) continue;
                    bool adjTransparent =
                        buf[(y - 1) * stride + x * 4 + 3] == 0 ||
                        buf[(y + 1) * stride + x * 4 + 3] == 0 ||
                        buf[y * stride + (x - 1) * 4 + 3] == 0 ||
                        buf[y * stride + (x + 1) * 4 + 3] == 0;
                    if (adjTransparent) {
                        int b = buf[off], g = buf[off + 1], r = buf[off + 2];
                        int maxRB = Math.Max(r, b);
                        if (g > maxRB + 12 && b < 170) {
                            buf[off + 1] = (byte)Math.Min(g, maxRB + 8);
                        }
                    }
                }
            }

            Marshal.Copy(buf, 0, bd.Scan0, bytes);
            crop.UnlockBits(bd);

            string dir = Path.GetDirectoryName(outPath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);

            if (targetW > 0 && targetH > 0) {
                using (Bitmap res = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb)) {
                    using (Graphics g2 = Graphics.FromImage(res)) {
                        g2.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g2.DrawImage(crop, 0, 0, targetW, targetH);
                    }
                    res.Save(outPath, ImageFormat.Png);
                }
            } else {
                crop.Save(outPath, ImageFormat.Png);
            }
        }
    }

    public static void PackActor4x2(string rawPath, string outAtlasPath, string tmpDir) {
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            int cw = src.Width / 4;
            int ch = src.Height / 2;
            using (Bitmap atlas = new Bitmap(1600, 800, PixelFormat.Format32bppArgb)) {
                using (Graphics ga = Graphics.FromImage(atlas)) {
                    for (int row = 0; row < 2; row++) {
                        for (int col = 0; col < 4; col++) {
                            string tmp = Path.Combine(tmpDir, string.Format("cell_{0}_{1}.png", row, col));
                            int w = (col == 3) ? (src.Width - col * cw) : cw;
                            int h = (row == 1) ? (src.Height - row * ch) : ch;
                            CropKeyAndSave(src, col * cw, row * ch, w, h, tmp, 400, 400);
                            using (Bitmap cell = (Bitmap)Image.FromFile(tmp)) {
                                ga.DrawImage(cell, col * 400, row * 400, 400, 400);
                            }
                        }
                    }
                }
                string dir = Path.GetDirectoryName(outAtlasPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                atlas.Save(outAtlasPath, ImageFormat.Png);
            }
        }
    }

    public static void PackEnv3x2(string rawPath, string outDir) {
        string[] names = new string[] {
            "chao_01.png", "chao_02.png", "portal.png",
            "obstaculo_01.png", "obstaculo_02.png", "obstaculo_03.png"
        };
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            int cw = src.Width / 3;
            int ch = src.Height / 2;
            for (int row = 0; row < 2; row++) {
                for (int col = 0; col < 3; col++) {
                    int w = (col == 2) ? (src.Width - col * cw) : cw;
                    int h = (row == 1) ? (src.Height - row * ch) : ch;
                    string outPath = Path.Combine(outDir, names[row * 3 + col]);
                    CropKeyAndSave(src, col * cw, row * ch, w, h, outPath, 384, 384);
                }
            }
        }
    }
}
'@

Add-Type -TypeDefinition $csCode -ReferencedAssemblies System.Drawing

$rawDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\source\raw"
$runtimeDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\runtime"
$envDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\environment"
$tmpDir = "C:\Users\lucas\.gemini\antigravity\brain\1b61e639-b8de-4588-a7ab-e3767cadb68b\scratch\alpha_pack_tmp"
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }

$actors = @(
    @{ id = "iniciado_guardiao"; raw = "chr_iniciado_guardiao_raw_v01.jpg"; scale = "0.42" },
    @{ id = "iniciado_veu"; raw = "chr_iniciado_veu_raw_v01.jpg"; scale = "0.42" },
    @{ id = "chefe_guardiao_rito"; raw = "bos_guardiao_rito_raw_v01.jpg"; scale = "0.62" },
    @{ id = "chefe_colosso_cinza"; raw = "bos_colosso_cinza_raw_v01.jpg"; scale = "0.66" },
    @{ id = "chefe_arconte_fenda"; raw = "bos_arconte_fenda_raw_v01.jpg"; scale = "0.64" }
)

foreach ($a in $actors) {
    $id = $a.id
    $aDir = Join-Path $runtimeDir $id
    $atlasPath = Join-Path $aDir "${id}_atlas_v01.png"
    [AlphaArtPacker]::PackActor4x2((Join-Path $rawDir $a.raw), $atlasPath, $tmpDir)

    $manifest = @"
{
  "actor": "$id",
  "cell_size": 400,
  "columns": 4,
  "rows": 2,
  "animations": {
    "idle_frente34": {"scale": $($a.scale)},
    "run_frente34": {"scale": $($a.scale)},
    "attack1_frente34": {"scale": $($a.scale)},
    "attack_frente34": {"scale": $($a.scale)},
    "windup_frente34": {"scale": $($a.scale)},
    "hurt_frente34": {"scale": $($a.scale)},
    "idle_costas34": {"scale": $($a.scale)},
    "run_costas34": {"scale": $($a.scale)},
    "attack1_costas34": {"scale": $($a.scale)},
    "attack_costas34": {"scale": $($a.scale)},
    "windup_costas34": {"scale": $($a.scale)},
    "death_frente34": {"scale": $($a.scale)},
    "death_costas34": {"scale": $($a.scale)}
  }
}
"@
    Set-Content -Path (Join-Path $aDir "atlas_manifest_v01.json") -Value $manifest -Encoding UTF8

    $tres = @"
[gd_resource type="SpriteFrames" load_steps=10 format=3]

[ext_resource type="Texture2D" path="res://assets/art/runtime/$id/${id}_atlas_v01.png" id="1_atlas"]

[sub_resource type="AtlasTexture" id="Atlas_0_0"]
atlas = ExtResource("1_atlas")
region = Rect2(0, 0, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_1_0"]
atlas = ExtResource("1_atlas")
region = Rect2(400, 0, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_2_0"]
atlas = ExtResource("1_atlas")
region = Rect2(800, 0, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_3_0"]
atlas = ExtResource("1_atlas")
region = Rect2(1200, 0, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_0_1"]
atlas = ExtResource("1_atlas")
region = Rect2(0, 400, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_1_1"]
atlas = ExtResource("1_atlas")
region = Rect2(400, 400, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_2_1"]
atlas = ExtResource("1_atlas")
region = Rect2(800, 400, 400, 400)

[sub_resource type="AtlasTexture" id="Atlas_3_1"]
atlas = ExtResource("1_atlas")
region = Rect2(1200, 400, 400, 400)

[resource]
animations = [{
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": true,
"name": &"idle_frente34",
"speed": 6.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_0")}, {"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": true,
"name": &"run_frente34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}],
"loop": false,
"name": &"attack1_frente34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}],
"loop": false,
"name": &"attack_frente34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}],
"loop": false,
"name": &"windup_frente34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_0")}],
"loop": false,
"name": &"hurt_frente34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": true,
"name": &"idle_costas34",
"speed": 6.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": true,
"name": &"run_costas34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}],
"loop": false,
"name": &"attack1_costas34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}],
"loop": false,
"name": &"attack_costas34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}],
"loop": false,
"name": &"windup_costas34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_1")}],
"loop": false,
"name": &"death_frente34",
"speed": 6.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_1")}],
"loop": false,
"name": &"death_costas34",
"speed": 6.0
}]
"@
    Set-Content -Path (Join-Path $aDir "${id}_frames_v01.tres") -Value $tres -Encoding UTF8
}

[AlphaArtPacker]::PackEnv3x2((Join-Path $rawDir "env_veio_instavel_raw_v01.jpg"), (Join-Path $envDir "veio_instavel"))
[AlphaArtPacker]::PackEnv3x2((Join-Path $rawDir "env_fosso_cinzas_raw_v01.jpg"), (Join-Path $envDir "fosso_das_cinzas"))
[AlphaArtPacker]::PackEnv3x2((Join-Path $rawDir "env_santuario_partido_raw_v01.jpg"), (Join-Path $envDir "santuario_partido"))

"ALL_8_ALPHA_ARTS_PACKED_OK"

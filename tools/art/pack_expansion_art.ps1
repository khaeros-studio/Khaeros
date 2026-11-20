Add-Type -AssemblyName System.Drawing

$csCode = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class ExpansionArtPacker {
    private static bool IsExternalGreenBg(byte r, byte g, byte b) {
        int maxRB = Math.Max(r, b);
        return g > 105 && (g - maxRB) > 38;
    }

    private static bool IsStrictPureGreenIsland(byte r, byte g, byte b) {
        return g > 130 && (g - r) > 45 && (g - b) > 50 && r < 120 && b < 115;
    }

    private static int[] FindGridCuts(Bitmap src, int count, bool vertical) {
        int mainLen = vertical ? src.Width : src.Height;
        int crossLen = vertical ? src.Height : src.Width;
        int[] cuts = new int[count + 1];
        cuts[0] = 0;
        cuts[count] = mainLen;
        BitmapData bd = src.LockBits(new Rectangle(0, 0, src.Width, src.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * src.Height;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);
        int stride = bd.Stride;
        src.UnlockBits(bd);

        for (int k = 1; k < count; k++) {
            int nominal = (mainLen * k) / count;
            int minPos = Math.Max(10, nominal - 140);
            int maxPos = Math.Min(mainLen - 10, nominal + 140);
            int bestPos = nominal;
            int bestScore = int.MaxValue;
            for (int p = minPos; p <= maxPos; p++) {
                int nonGreen = 0;
                for (int q = 0; q < crossLen; q += 2) {
                    int x = vertical ? p : q;
                    int y = vertical ? q : p;
                    int off = y * stride + x * 4;
                    if (!IsExternalGreenBg(buf[off + 2], buf[off + 1], buf[off])) nonGreen++;
                }
                if (nonGreen < bestScore || (nonGreen == bestScore && Math.Abs(p - nominal) < Math.Abs(bestPos - nominal))) {
                    bestScore = nonGreen;
                    bestPos = p;
                }
            }
            cuts[k] = bestPos;
        }
        return cuts;
    }

    public static Bitmap ExtractCleanCell(Bitmap src, int x0, int y0, int w, int h, bool removeInnerGreen, out int[] bodyFootAndCenter) {
        Bitmap cell = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(cell)) {
            g.DrawImage(src, new Rectangle(0, 0, w, h), new Rectangle(x0, y0, w, h), GraphicsUnit.Pixel);
        }

        BitmapData bd = cell.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);
        int stride = bd.Stride;

        bool[] bg = new bool[w * h];
        Queue<int> q = new Queue<int>();
        Action<int, int> tryEnqueue = (px, py) => {
            if (px < 0 || py < 0 || px >= w || py >= h) return;
            int idx = py * w + px;
            if (bg[idx]) return;
            int off = py * stride + px * 4;
            if (IsExternalGreenBg(buf[off + 2], buf[off + 1], buf[off])) {
                bg[idx] = true;
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

        if (removeInnerGreen) {
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int idx = y * w + x;
                    if (bg[idx]) continue;
                    int off = y * stride + x * 4;
                    if (IsStrictPureGreenIsland(buf[off + 2], buf[off + 1], buf[off])) {
                        bg[idx] = true;
                        buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
                    }
                }
            }
        }

        // Despill restrito EXCLUSIVAMENTE a franja dist <= 2 px de bg[]
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int idx = y * w + x;
                if (bg[idx]) continue;
                bool inFringe = false;
                for (int dy = -2; dy <= 2 && !inFringe; dy++) {
                    for (int dx = -2; dx <= 2; dx++) {
                        int nx = x + dx, ny = y + dy;
                        if (nx >= 0 && ny >= 0 && nx < w && ny < h && bg[ny * w + nx]) {
                            inFringe = true;
                            break;
                        }
                    }
                }
                if (!inFringe) continue;

                int off = y * stride + x * 4;
                byte b = buf[off], gr = buf[off + 1], r = buf[off + 2], a = buf[off + 3];
                int maxRB = Math.Max(r, b);
                int excess = gr - maxRB;
                if (excess > 18) {
                    if (r > 75 && b > 55) {
                        // Borda de brilho magenta/neon: preserva matiz magenta
                        buf[off + 1] = (byte)Math.Min((int)gr, Math.Min((int)r, (int)b));
                        int newA = (int)Math.Round(a * (1.0 - (excess - 18.0) / 95.0));
                        if (newA < 20) {
                            buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
                        } else {
                            buf[off + 3] = (byte)Math.Max(0, Math.Min(255, newA));
                        }
                    } else if (excess > 24) {
                        buf[off] = 20; buf[off + 1] = 14; buf[off + 2] = 13;
                        int newA = (int)Math.Round(a * (1.0 - (excess - 18.0) / 95.0));
                        if (newA < 24) {
                            buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
                        } else {
                            buf[off + 3] = (byte)Math.Max(0, Math.Min(255, newA));
                        }
                    }
                }
            }
        }

        // Encontrar maior componente conexo para ancora de pivo (excluindo particulas/vortex solto)
        bool[] visComp = new bool[w * h];
        int bestCount = 0;
        int bestMinX = 0, bestMaxX = w - 1, bestMinY = 0, bestMaxY = h - 1;
        int allMinX = w, allMaxX = -1, allMinY = h, allMaxY = -1;
        Queue<int> cq = new Queue<int>();

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int idx = y * w + x;
                byte alpha = buf[y * stride + x * 4 + 3];
                if (alpha <= 20) continue;
                if (x < allMinX) allMinX = x;
                if (x > allMaxX) allMaxX = x;
                if (y < allMinY) allMinY = y;
                if (y > allMaxY) allMaxY = y;
                if (visComp[idx]) continue;

                visComp[idx] = true;
                cq.Enqueue(idx);
                int cnt = 0;
                int cMinX = x, cMaxX = x, cMinY = y, cMaxY = y;
                while (cq.Count > 0) {
                    int p = cq.Dequeue();
                    int px = p % w, py = p / w;
                    cnt++;
                    if (px < cMinX) cMinX = px;
                    if (px > cMaxX) cMaxX = px;
                    if (py < cMinY) cMinY = py;
                    if (py > cMaxY) cMaxY = py;
                    int[] dxs = { -1, 1, 0, 0 };
                    int[] dys = { 0, 0, -1, 1 };
                    for (int k = 0; k < 4; k++) {
                        int nx = px + dxs[k], ny = py + dys[k];
                        if (nx >= 0 && ny >= 0 && nx < w && ny < h) {
                            int nidx = ny * w + nx;
                            if (!visComp[nidx] && buf[ny * stride + nx * 4 + 3] > 20) {
                                visComp[nidx] = true;
                                cq.Enqueue(nidx);
                            }
                        }
                    }
                }
                if (cnt > bestCount) {
                    bestCount = cnt;
                    bestMinX = cMinX; bestMaxX = cMaxX;
                    bestMinY = cMinY; bestMaxY = cMaxY;
                }
            }
        }

        Marshal.Copy(buf, 0, bd.Scan0, bytes);
        cell.UnlockBits(bd);

        bodyFootAndCenter = new int[] {
            bestMinX, bestMaxX, bestMinY, bestMaxY,
            allMinX, allMaxX, allMinY, allMaxY
        };
        return cell;
    }

    public static void PackGetoActor4x2(string rawPath, string outAtlasPath) {
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            int[] colCuts = FindGridCuts(src, 4, true);
            int[] rowCuts = FindGridCuts(src, 2, false);
            Bitmap[] cells = new Bitmap[8];
            int[][] bounds = new int[8][];
            for (int r = 0; r < 2; r++) {
                for (int c = 0; c < 4; c++) {
                    int idx = r * 4 + c;
                    int x0 = colCuts[c];
                    int y0 = rowCuts[r];
                    int w = colCuts[c + 1] - x0;
                    int h = rowCuts[r + 1] - y0;
                    int[] b;
                    cells[idx] = ExtractCleanCell(src, x0, y0, w, h, true, out b);
                    bounds[idx] = b;
                }
            }

            // Escala global unica baseada nas poses neutras (0, 1, 4, 5) visando ~245px de altura
            int[] neutralIds = { 0, 1, 4, 5 };
            double sumBodyH = 0;
            foreach (int nid in neutralIds) {
                sumBodyH += Math.Max(1, bounds[nid][3] - bounds[nid][2] + 1);
            }
            double avgBodyH = sumBodyH / neutralIds.Length;
            double scale = Math.Min(1.0, 245.0 / Math.Max(1.0, avgBodyH));

            // Garante que nenhuma celula (incluindo o vortex em 2 e 6) exceda 384px de altura/largura no quadro 400x400
            for (int i = 0; i < 8; i++) {
                int allW = Math.Max(1, bounds[i][5] - bounds[i][4] + 1);
                int allH = Math.Max(1, bounds[i][7] - bounds[i][6] + 1);
                double maxFit = Math.Min(380.0 / allW, 380.0 / allH);
                if (maxFit < scale) scale = maxFit;
            }

            using (Bitmap atlas = new Bitmap(1600, 800, PixelFormat.Format32bppArgb)) {
                using (Graphics ga = Graphics.FromImage(atlas)) {
                    ga.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    ga.SmoothingMode = SmoothingMode.HighQuality;
                    for (int r = 0; r < 2; r++) {
                        for (int c = 0; c < 4; c++) {
                            int idx = r * 4 + c;
                            int[] b = bounds[idx];
                            int allMinX = b[4], allMaxX = b[5], allMinY = b[6], allMaxY = b[7];
                            if (allMaxX < allMinX || allMaxY < allMinY) continue;
                            int cropW = allMaxX - allMinX + 1;
                            int cropH = allMaxY - allMinY + 1;
                            int bodyCx = (b[0] + b[1]) / 2;
                            int bodyFootY = b[3];

                            double destW = cropW * scale;
                            double destH = cropH * scale;
                            double bodyCxScaled = (bodyCx - allMinX) * scale;
                            double bodyFootScaled = (bodyFootY - allMinY) * scale;

                            // Ancora no pivo (200, 320) dentro da celula 400x400, com clamp para nunca vazar fora da celula
                            double dx = c * 400 + 200.0 - bodyCxScaled;
                            double dy = r * 400 + 320.0 - bodyFootScaled;
                            dx = Math.Max(c * 400 + 4.0, Math.Min(c * 400 + 396.0 - destW, dx));
                            dy = Math.Max(r * 400 + 4.0, Math.Min(r * 400 + 396.0 - destH, dy));

                            ga.DrawImage(
                                cells[idx],
                                new RectangleF((float)dx, (float)dy, (float)destW, (float)destH),
                                new RectangleF(allMinX, allMinY, cropW, cropH),
                                GraphicsUnit.Pixel
                            );
                            cells[idx].Dispose();
                        }
                    }
                }
                string dir = Path.GetDirectoryName(outAtlasPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                atlas.Save(outAtlasPath, ImageFormat.Png);
            }
        }
    }

    public static void PackProps3x2(string rawPath, string outDir) {
        string[] names = new string[] {
            "monolito_lore.png", "fonte_cura.png", "bau_reliquia.png",
            "estatua_guardiao.png", "altar_pacto.png", "coluna_correntes.png"
        };
        if (!Directory.Exists(outDir)) Directory.CreateDirectory(outDir);

        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            int[] colCuts = FindGridCuts(src, 3, true);
            int[] rowCuts = FindGridCuts(src, 2, false);
            Bitmap[] cells = new Bitmap[6];
            int[][] bounds = new int[6][];
            int maxDim = 1;
            for (int r = 0; r < 2; r++) {
                for (int c = 0; c < 3; c++) {
                    int idx = r * 3 + c;
                    int x0 = colCuts[c];
                    int y0 = rowCuts[r];
                    int w = colCuts[c + 1] - x0;
                    int h = rowCuts[r + 1] - y0;
                    int[] b;
                    // Apenas celula 5 (coluna_correntes) habilita remocao interna de ilhas verdes
                    bool inner = (idx == 5);
                    cells[idx] = ExtractCleanCell(src, x0, y0, w, h, inner, out b);
                    bounds[idx] = b;
                    int aw = Math.Max(1, b[5] - b[4] + 1);
                    int ah = Math.Max(1, b[7] - b[6] + 1);
                    if (aw > maxDim) maxDim = aw;
                    if (ah > maxDim) maxDim = ah;
                }
            }

            double sharedScale = Math.Min(1.0, 240.0 / maxDim);
            for (int i = 0; i < 6; i++) {
                int minX = bounds[i][4], maxX = bounds[i][5], minY = bounds[i][6], maxY = bounds[i][7];
                int aw = Math.Max(1, maxX - minX + 1);
                int ah = Math.Max(1, maxY - minY + 1);
                int dw = (int)Math.Round(aw * sharedScale);
                int dh = (int)Math.Round(ah * sharedScale);
                // Margem minima de 4px e dimensoes multiplas de 4
                int outW = ((dw + 8 + 3) / 4) * 4;
                int outH = ((dh + 8 + 3) / 4) * 4;
                using (Bitmap outBmp = new Bitmap(outW, outH, PixelFormat.Format32bppArgb)) {
                    using (Graphics go = Graphics.FromImage(outBmp)) {
                        go.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        go.SmoothingMode = SmoothingMode.HighQuality;
                        float ox = (outW - dw) * 0.5f;
                        float oy = (float)(outH - dh - 4);
                        go.DrawImage(cells[i], new RectangleF(ox, oy, dw, dh), new RectangleF(minX, minY, aw, ah), GraphicsUnit.Pixel);
                    }
                    outBmp.Save(Path.Combine(outDir, names[i]), ImageFormat.Png);
                }
                cells[i].Dispose();
            }
        }
    }

    public static void SaveStoryPng(string rawPath, string outPath) {
        string dir = Path.GetDirectoryName(outPath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            if (src.Width > 1920 || src.Height > 1080) {
                using (Bitmap resized = new Bitmap(1920, 1080, PixelFormat.Format32bppArgb)) {
                    using (Graphics g = Graphics.FromImage(resized)) {
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.DrawImage(src, 0, 0, 1920, 1080);
                    }
                    resized.Save(outPath, ImageFormat.Png);
                }
            } else {
                // Multiplo de 4 sem ampliar
                int w = (src.Width / 4) * 4;
                int h = (src.Height / 4) * 4;
                using (Bitmap cropped = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
                    using (Graphics g = Graphics.FromImage(cropped)) {
                        g.DrawImage(src, new Rectangle(0, 0, w, h), new Rectangle(0, 0, w, h), GraphicsUnit.Pixel);
                    }
                    cropped.Save(outPath, ImageFormat.Png);
                }
            }
        }
    }
}
'@

Add-Type -TypeDefinition $csCode -ReferencedAssemblies System.Drawing

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$rawDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\source\raw"
$pactosDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\runtime\iniciado_pactos"
$propsDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\environment\props"
$histDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\ui\historia"

$atlasPath = Join-Path $pactosDir "iniciado_pactos_atlas_v01.png"
[ExpansionArtPacker]::PackGetoActor4x2((Join-Path $rawDir "chr_iniciado_pactos_geto_raw_v01.jpg"), $atlasPath)

$manifestJson = @"
{
  "actor": "iniciado_pactos",
  "status": "runtime_ready",
  "canvas": [400, 400],
  "pivot": [200, 320],
  "cell_size": 400,
  "columns": 4,
  "rows": 2,
  "animations": {
    "idle_frente34": {"scale": 0.43},
    "run_frente34": {"scale": 0.43},
    "attack1_frente34": {"scale": 0.43},
    "attack_frente34": {"scale": 0.43},
    "virote_frente34": {"scale": 0.43},
    "chamado_frente34": {"scale": 0.43},
    "troca_frente34": {"scale": 0.43},
    "hurt_frente34": {"scale": 0.43},
    "idle_costas34": {"scale": 0.43},
    "run_costas34": {"scale": 0.43},
    "attack1_costas34": {"scale": 0.43},
    "attack_costas34": {"scale": 0.43},
    "virote_costas34": {"scale": 0.43},
    "chamado_costas34": {"scale": 0.43},
    "troca_costas34": {"scale": 0.43},
    "death_frente34": {"scale": 0.43},
    "death_costas34": {"scale": 0.43}
  }
}
"@
[System.IO.File]::WriteAllText((Join-Path $pactosDir "atlas_manifest_v01.json"), $manifestJson, $utf8NoBom)

$tresContent = @'
[gd_resource type="SpriteFrames" load_steps=10 format=3]

[ext_resource type="Texture2D" path="res://assets/art/runtime/iniciado_pactos/iniciado_pactos_atlas_v01.png" id="1_atlas"]

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
"speed": 5.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_0")}, {"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": true,
"name": &"run_frente34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}, {"duration": 1.0, "texture": SubResource("Atlas_3_0")}],
"loop": false,
"name": &"attack1_frente34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}, {"duration": 1.0, "texture": SubResource("Atlas_3_0")}],
"loop": false,
"name": &"attack_frente34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}, {"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": false,
"name": &"virote_frente34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_0")}, {"duration": 1.0, "texture": SubResource("Atlas_3_0")}],
"loop": false,
"name": &"chamado_frente34",
"speed": 9.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": false,
"name": &"troca_frente34",
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
"speed": 5.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": true,
"name": &"run_costas34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": false,
"name": &"attack1_costas34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": false,
"name": &"attack_costas34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": false,
"name": &"virote_costas34",
"speed": 10.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_2_1")}, {"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": false,
"name": &"chamado_costas34",
"speed": 9.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": false,
"name": &"troca_costas34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_1")}],
"loop": false,
"name": &"death_frente34",
"speed": 8.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_1")}],
"loop": false,
"name": &"death_costas34",
"speed": 8.0
}]
'@
[System.IO.File]::WriteAllText((Join-Path $pactosDir "iniciado_pactos_frames_v01.tres"), $tresContent, $utf8NoBom)

[ExpansionArtPacker]::PackProps3x2((Join-Path $rawDir "props_masmorra_raw_v01.jpg"), $propsDir)
[ExpansionArtPacker]::SaveStoryPng((Join-Path $rawDir "historia_prologo_01.jpg"), (Join-Path $histDir "prologo_01.png"))
[ExpansionArtPacker]::SaveStoryPng((Join-Path $rawDir "historia_prologo_02.jpg"), (Join-Path $histDir "prologo_02.png"))

Write-Output "PACK_EXPANSION_ART_OK"

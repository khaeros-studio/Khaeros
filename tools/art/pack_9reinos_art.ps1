Add-Type -AssemblyName System.Drawing

$csCode = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class NineRealmsArtPacker {
    private static bool MatchExt(string mode, byte r, byte g, byte b) {
        int maxRB = Math.Max(r, b);
        int diff = g - maxRB;
        if (mode == "BotanicalStrict") {
            return g >= 205 && r <= 65 && b <= 65 && diff >= 145;
        }
        if (mode == "CyanSafe") {
            return g >= 180 && r <= 65 && b <= 75 && diff >= 115;
        }
        return g >= 135 && r <= 95 && b <= 95 && diff >= 55;
    }

    private static bool MatchInnerSeed(string mode, byte r, byte g, byte b) {
        int maxRB = Math.Max(r, b);
        int diff = g - maxRB;
        if (mode == "BotanicalStrict") {
            return g >= 220 && r <= 45 && b <= 45 && diff >= 175;
        }
        if (mode == "CyanSafe") {
            return g >= 200 && r <= 50 && b <= 55 && diff >= 145;
        }
        return g >= 165 && r <= 125 && b <= 110 && diff >= 70;
    }

    private static void CleanChromaSheet(byte[] buf, int stride, int w, int h, string mode, bool stripGrid, out int[] colCuts, out int[] rowCuts) {
        bool[] bg = new bool[w * h];
        Queue<int> q = new Queue<int>();

        Action<int, int> enqExt = (px, py) => {
            if (px < 0 || py < 0 || px >= w || py >= h) return;
            int idx = py * w + px;
            if (bg[idx]) return;
            int off = py * stride + px * 4;
            if (MatchExt(mode, buf[off + 2], buf[off + 1], buf[off])) {
                bg[idx] = true;
                q.Enqueue(idx);
            }
        };

        for (int x = 0; x < w; x++) { enqExt(x, 0); enqExt(x, h - 1); }
        for (int y = 0; y < h; y++) { enqExt(0, y); enqExt(w - 1, y); }

        while (q.Count > 0) {
            int cur = q.Dequeue();
            int cx = cur % w, cy = cur / w;
            enqExt(cx - 1, cy); enqExt(cx + 1, cy);
            enqExt(cx, cy - 1); enqExt(cx, cy + 1);
        }

        // Ilhas internas fechadas (sempre por semente estrita + propagacao segura)
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int idx = y * w + x;
                if (bg[idx]) continue;
                int off = y * stride + x * 4;
                if (MatchInnerSeed(mode, buf[off + 2], buf[off + 1], buf[off])) {
                    bg[idx] = true;
                    q.Enqueue(idx);
                    while (q.Count > 0) {
                        int cur = q.Dequeue();
                        int cx = cur % w, cy = cur / w;
                        enqExt(cx - 1, cy); enqExt(cx + 1, cy);
                        enqExt(cx, cy - 1); enqExt(cx, cy + 1);
                    }
                }
            }
        }

        if (stripGrid) {
            int margin = Math.Max(8, (int)Math.Round(w / 160.0));
            for (int x = 0; x < 4; x++) {
                for (int y = 0; y < h; y++) { bg[y * w + x] = true; bg[y * w + (w - 1 - x)] = true; }
            }
            for (int y = 0; y < 4; y++) {
                for (int x = 0; x < w; x++) { bg[y * w + x] = true; bg[(h - 1 - y) * w + x] = true; }
            }
            for (int k = 1; k <= 3; k++) {
                int nom = (w * k) / 4;
                int bestX = nom; int bestDark = -1;
                for (int px = Math.Max(8, nom - 50); px <= Math.Min(w - 8, nom + 50); px++) {
                    int darkCnt = 0;
                    for (int py = 0; py < h; py++) {
                        int off = py * stride + px * 4;
                        if (buf[off + 2] < 120 && buf[off + 1] < 120 && buf[off] < 120) darkCnt++;
                    }
                    if (darkCnt > bestDark) { bestDark = darkCnt; bestX = px; }
                }
                if (bestDark > h * 0.55) {
                    for (int px = Math.Max(0, bestX - margin); px <= Math.Min(w - 1, bestX + margin); px++) {
                        for (int py = 0; py < h; py++) bg[py * w + px] = true;
                    }
                }
            }
            {
                int nomY = h / 2;
                int bestY = nomY; int bestDark = -1;
                for (int py = Math.Max(8, nomY - 50); py <= Math.Min(h - 8, nomY + 50); py++) {
                    int darkCnt = 0;
                    for (int px = 0; px < w; px++) {
                        int off = py * stride + px * 4;
                        if (buf[off + 2] < 120 && buf[off + 1] < 120 && buf[off] < 120) darkCnt++;
                    }
                    if (darkCnt > bestDark) { bestDark = darkCnt; bestY = py; }
                }
                if (bestDark > w * 0.55) {
                    for (int py = Math.Max(0, bestY - margin); py <= Math.Min(h - 1, bestY + margin); py++) {
                        for (int px = 0; px < w; px++) bg[py * w + px] = true;
                    }
                }
            }
        }

        for (int i = 0; i < w * h; i++) {
            if (bg[i]) {
                int cx = i % w, cy = i / w;
                int off = cy * stride + cx * 4;
                buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0;
            }
        }

        // Despill restrito EXCLUSIVAMENTE a franja dist <= 2px de bg[]
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int idx = y * w + x;
                if (bg[idx]) continue;
                bool nearBg = false;
                for (int dy = -2; dy <= 2 && !nearBg; dy++) {
                    for (int dx = -2; dx <= 2; dx++) {
                        int nx = x + dx, ny = y + dy;
                        if (nx >= 0 && ny >= 0 && nx < w && ny < h && bg[ny * w + nx]) { nearBg = true; break; }
                    }
                }
                if (!nearBg) continue;

                int off = y * stride + x * 4;
                byte b = buf[off], g = buf[off + 1], r = buf[off + 2], a = buf[off + 3];
                int maxRB = Math.Max(r, b);
                int excess = g - maxRB;

                if (mode == "BotanicalStrict") {
                    if (r < 55 && b < 55 && excess > 18) {
                        double sc = Math.Max(0.0, Math.Min(1.0, 1.0 - (excess - 18.0) / 115.0));
                        int newA = (int)Math.Round(a * sc);
                        if (newA < 24) { buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0; }
                        else { buf[off] = 20; buf[off + 1] = 14; buf[off + 2] = 13; buf[off + 3] = (byte)newA; }
                    } else if (r >= 55 && r > b + 18 && excess > 55) {
                        buf[off + 1] = (byte)Math.Min((int)g, (int)(r * 1.45) + 25);
                        double sc = Math.Max(0.0, Math.Min(1.0, 1.0 - (excess - 55.0) / 110.0));
                        int newA = (int)Math.Round(a * sc);
                        if (newA < 18) { buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0; }
                        else buf[off + 3] = (byte)newA;
                    }
                } else if (mode == "CyanSafe") {
                    if (b > r + 20 && b >= 70) {
                        if (g > b) buf[off + 1] = b;
                        if (excess > 25) {
                            double sc = Math.Max(0.0, Math.Min(1.0, 1.0 - (excess - 25.0) / 120.0));
                            int newA = (int)Math.Round(a * sc);
                            if (newA < 20) { buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0; }
                            else buf[off + 3] = (byte)newA;
                        }
                    } else if (excess > 20) {
                        double sc = Math.Max(0.0, Math.Min(1.0, 1.0 - (excess - 20.0) / 110.0));
                        int newA = (int)Math.Round(a * sc);
                        if (newA < 24) { buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0; }
                        else { buf[off] = 20; buf[off + 1] = 14; buf[off + 2] = 13; buf[off + 3] = (byte)newA; }
                    }
                } else {
                    if (r > 120 && r >= g * 0.75) {
                        if (g > r) buf[off + 1] = r;
                    } else if (excess > 20) {
                        double sc = Math.Max(0.0, Math.Min(1.0, 1.0 - (excess - 20.0) / 110.0));
                        int newA = (int)Math.Round(a * sc);
                        if (newA < 24) { buf[off] = 0; buf[off + 1] = 0; buf[off + 2] = 0; buf[off + 3] = 0; }
                        else { buf[off] = 20; buf[off + 1] = 14; buf[off + 2] = 13; buf[off + 3] = (byte)newA; }
                    }
                }
            }
        }

        // Cortes por projecao minima apos limpeza
        colCuts = new int[5]; colCuts[0] = 0; colCuts[4] = w;
        int searchX = Math.Max(85, (int)(w * 0.08));
        for (int k = 1; k <= 3; k++) {
            int nom = (w * k) / 4;
            int best = nom; int bestCnt = int.MaxValue;
            for (int px = Math.Max(8, nom - searchX); px <= Math.Min(w - 8, nom + searchX); px++) {
                int cnt = 0;
                for (int py = 0; py < h; py += 2) if (buf[py * stride + px * 4 + 3] > 20) cnt++;
                if (cnt < bestCnt || (cnt == bestCnt && Math.Abs(px - nom) < Math.Abs(best - nom))) { bestCnt = cnt; best = px; }
            }
            colCuts[k] = best;
        }
        rowCuts = new int[3]; rowCuts[0] = 0; rowCuts[2] = h;
        int searchY = Math.Max(95, (int)(h * 0.12));
        {
            int nom = h / 2;
            int best = nom; int bestCnt = int.MaxValue;
            for (int py = Math.Max(8, nom - searchY); py <= Math.Min(h - 8, nom + searchY); py++) {
                int cnt = 0;
                for (int px = 0; px < w; px += 2) if (buf[py * stride + px * 4 + 3] > 20) cnt++;
                if (cnt < bestCnt || (cnt == bestCnt && Math.Abs(py - nom) < Math.Abs(best - nom))) { bestCnt = cnt; best = py; }
            }
            rowCuts[1] = best;
        }
    }

    private static void ComputeCellBounds(byte[] buf, int stride, int x0, int y0, int x1, int y1, out int[] allB, out int[] mainB) {
        int cw = x1 - x0, ch = y1 - y0;
        int aminX = x1, amaxX = x0 - 1, aminY = y1, amaxY = y0 - 1;
        bool[] vis = new bool[cw * ch];
        int bestCnt = 0;
        int mminX = x0, mmaxX = x1 - 1, mminY = y0, mmaxY = y1 - 1;
        Queue<int> cq = new Queue<int>();

        for (int py = y0; py < y1; py++) {
            for (int px = x0; px < x1; px++) {
                if (buf[py * stride + px * 4 + 3] <= 20) continue;
                if (px < aminX) aminX = px; if (px > amaxX) amaxX = px;
                if (py < aminY) aminY = py; if (py > amaxY) amaxY = py;
                int li = (py - y0) * cw + (px - x0);
                if (vis[li]) continue;
                vis[li] = true; cq.Enqueue(li);
                int cnt = 0; int cminX = px, cmaxX = px, cminY = py, cmaxY = py;
                while (cq.Count > 0) {
                    int p = cq.Dequeue();
                    int lx = p % cw, ly = p / cw;
                    int gx = x0 + lx, gy = y0 + ly;
                    cnt++;
                    if (gx < cminX) cminX = gx; if (gx > cmaxX) cmaxX = gx;
                    if (gy < cminY) cminY = gy; if (gy > cmaxY) cmaxY = gy;
                    int[] dxs = { -1, 1, 0, 0 }; int[] dys = { 0, 0, -1, 1 };
                    for (int k = 0; k < 4; k++) {
                        int nlx = lx + dxs[k], nly = ly + dys[k];
                        if (nlx >= 0 && nly >= 0 && nlx < cw && nly < ch) {
                            int nli = nly * cw + nlx;
                            if (!vis[nli] && buf[(y0 + nly) * stride + (x0 + nlx) * 4 + 3] > 20) {
                                vis[nli] = true; cq.Enqueue(nli);
                            }
                        }
                    }
                }
                if (cnt > bestCnt) { bestCnt = cnt; mminX = cminX; mmaxX = cmaxX; mminY = cminY; mmaxY = cmaxY; }
            }
        }
        allB = new int[] { aminX, amaxX, aminY, amaxY };
        mainB = new int[] { mminX, mmaxX, mminY, mmaxY };
    }

    public static void PackBoss2x2(string rawPath, string outAtlasPath, string mode) {
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            using (Bitmap work = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb)) {
                using (Graphics gw = Graphics.FromImage(work)) { gw.DrawImage(src, 0, 0, src.Width, src.Height); }
                int w = work.Width, h = work.Height;
                BitmapData bd = work.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int bytes = Math.Abs(bd.Stride) * h;
                byte[] buf = new byte[bytes];
                Marshal.Copy(bd.Scan0, buf, 0, bytes);
                int stride = bd.Stride;

                int[] unusedC; int[] unusedR;
                CleanChromaSheet(buf, stride, w, h, mode, false, out unusedC, out unusedR);

                int midX = w / 2, bestXCnt = int.MaxValue;
                int searchX = Math.Max(95, (int)(w * 0.12));
                for (int px = Math.Max(8, w / 2 - searchX); px <= Math.Min(w - 8, w / 2 + searchX); px++) {
                    int cnt = 0;
                    for (int py = 0; py < h; py += 2) if (buf[py * stride + px * 4 + 3] > 20) cnt++;
                    if (cnt < bestXCnt || (cnt == bestXCnt && Math.Abs(px - w / 2) < Math.Abs(midX - w / 2))) { bestXCnt = cnt; midX = px; }
                }
                int midY = h / 2, bestYCnt = int.MaxValue;
                int searchY = Math.Max(95, (int)(h * 0.12));
                for (int py = Math.Max(8, h / 2 - searchY); py <= Math.Min(h - 8, h / 2 + searchY); py++) {
                    int cnt = 0;
                    for (int px = 0; px < w; px += 2) if (buf[py * stride + px * 4 + 3] > 20) cnt++;
                    if (cnt < bestYCnt || (cnt == bestYCnt && Math.Abs(py - h / 2) < Math.Abs(midY - h / 2))) { bestYCnt = cnt; midY = py; }
                }

                int[] xs = { 0, midX, w };
                int[] ys = { 0, midY, h };
                int[][] allBounds = new int[4][];
                int[][] mainBounds = new int[4][];
                for (int r = 0; r < 2; r++) {
                    for (int c = 0; c < 2; c++) {
                        int idx = r * 2 + c;
                        ComputeCellBounds(buf, stride, xs[c], ys[r], xs[c + 1], ys[r + 1], out allBounds[idx], out mainBounds[idx]);
                    }
                }

                Marshal.Copy(buf, 0, bd.Scan0, bytes);
                work.UnlockBits(bd);

                double maxBody = 1.0;
                for (int i = 0; i < 4; i++) {
                    int bw = mainBounds[i][1] - mainBounds[i][0] + 1;
                    int bh = mainBounds[i][3] - mainBounds[i][2] + 1;
                    if (bw > maxBody) maxBody = bw;
                    if (bh > maxBody) maxBody = bh;
                }
                double scale = 336.0 / maxBody;
                for (int i = 0; i < 4; i++) {
                    if (allBounds[i][1] < allBounds[i][0]) continue;
                    int aw = allBounds[i][1] - allBounds[i][0] + 1;
                    int ah = allBounds[i][3] - allBounds[i][2] + 1;
                    double fit = Math.Min(388.0 / aw, 388.0 / ah);
                    if (fit < scale) scale = fit;
                }

                using (Bitmap atlas = new Bitmap(1600, 800, PixelFormat.Format32bppArgb)) {
                    using (Graphics ga = Graphics.FromImage(atlas)) {
                        ga.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        ga.SmoothingMode = SmoothingMode.HighQuality;
                        for (int r = 0; r < 2; r++) {
                            for (int c = 0; c < 4; c++) {
                                int[] ab = allBounds[c];
                                int[] mb = mainBounds[c];
                                if (ab[1] < ab[0] || ab[3] < ab[2]) continue;
                                int cropW = ab[1] - ab[0] + 1;
                                int cropH = ab[3] - ab[2] + 1;
                                double destW = cropW * scale;
                                double destH = cropH * scale;
                                double bodyCx = ((mb[0] + mb[1]) * 0.5 - ab[0]) * scale;
                                double bodyFoot = (mb[3] - ab[2]) * scale;
                                double dx = c * 400 + 200.0 - bodyCx;
                                double dy = r * 400 + 335.0 - bodyFoot;
                                dx = Math.Max(c * 400 + 4.0, Math.Min(c * 400 + 396.0 - destW, dx));
                                dy = Math.Max(r * 400 + 4.0, Math.Min(r * 400 + 396.0 - destH, dy));
                                ga.DrawImage(work, new RectangleF((float)dx, (float)dy, (float)destW, (float)destH), new RectangleF(ab[0], ab[2], cropW, cropH), GraphicsUnit.Pixel);
                            }
                        }
                    }
                    string dir = Path.GetDirectoryName(outAtlasPath);
                    if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                    atlas.Save(outAtlasPath, ImageFormat.Png);
                }
            }
        }
    }

    public static void PackBoss4x2(string rawPath, string outAtlasPath, string mode, bool stripGrid, bool fadeJetBottom, bool fadeBorderRays) {
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            using (Bitmap work = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb)) {
                using (Graphics gw = Graphics.FromImage(work)) { gw.DrawImage(src, 0, 0, src.Width, src.Height); }
                int w = work.Width, h = work.Height;
                BitmapData bd = work.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int bytes = Math.Abs(bd.Stride) * h;
                byte[] buf = new byte[bytes];
                Marshal.Copy(bd.Scan0, buf, 0, bytes);
                int stride = bd.Stride;

                int[] colCuts; int[] rowCuts;
                CleanChromaSheet(buf, stride, w, h, mode, stripGrid, out colCuts, out rowCuts);

                if (fadeJetBottom) {
                    int xA = colCuts[2], xB = colCuts[3], yB = rowCuts[1];
                    for (int dy = 0; dy < 7 && (yB - 1 - dy) >= 0; dy++) {
                        double f = dy / 7.0;
                        int py = yB - 1 - dy;
                        for (int px = xA; px < xB; px++) {
                            int off = py * stride + px * 4;
                            buf[off + 3] = (byte)Math.Round(buf[off + 3] * f);
                        }
                    }
                }
                if (fadeBorderRays) {
                    int xA = colCuts[3], xB = colCuts[4], yA = rowCuts[0], yB = rowCuts[1];
                    for (int px = xA; px < xB; px++) {
                        for (int py = yA; py < yB; py++) {
                            int dTop = py - yA, dBot = (yB - 1) - py, dRight = (xB - 1) - px;
                            int dMin = Math.Min(dTop, Math.Min(dBot, dRight));
                            if (dMin < 8) {
                                int off = py * stride + px * 4;
                                buf[off + 3] = (byte)Math.Round(buf[off + 3] * (dMin / 8.0));
                            }
                        }
                    }
                }

                // Bbox total e maior componente conexo por celula
                int[][] allBounds = new int[8][];
                int[][] mainBounds = new int[8][];
                for (int r = 0; r < 2; r++) {
                    for (int c = 0; c < 4; c++) {
                        int idx = r * 4 + c;
                        ComputeCellBounds(buf, stride, colCuts[c], rowCuts[r], colCuts[c + 1], rowCuts[r + 1], out allBounds[idx], out mainBounds[idx]);
                    }
                }

                Marshal.Copy(buf, 0, bd.Scan0, bytes);
                work.UnlockBits(bd);

                // Escala uniforme da folha pelos corpos principais (poses 0,1,2,4,5) garantindo caber ate 388x388
                int[] basePoses = { 0, 1, 2, 4, 5 };
                double maxBody = 1.0;
                foreach (int bp in basePoses) {
                    int bw = mainBounds[bp][1] - mainBounds[bp][0] + 1;
                    int bh = mainBounds[bp][3] - mainBounds[bp][2] + 1;
                    if (bw > maxBody) maxBody = bw;
                    if (bh > maxBody) maxBody = bh;
                }
                double scale = 336.0 / maxBody;
                for (int i = 0; i < 8; i++) {
                    if (allBounds[i][1] < allBounds[i][0]) continue;
                    int aw = allBounds[i][1] - allBounds[i][0] + 1;
                    int ah = allBounds[i][3] - allBounds[i][2] + 1;
                    double fit = Math.Min(388.0 / aw, 388.0 / ah);
                    if (fit < scale) scale = fit;
                }

                using (Bitmap atlas = new Bitmap(1600, 800, PixelFormat.Format32bppArgb)) {
                    using (Graphics ga = Graphics.FromImage(atlas)) {
                        ga.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        ga.SmoothingMode = SmoothingMode.HighQuality;
                        for (int r = 0; r < 2; r++) {
                            for (int c = 0; c < 4; c++) {
                                int idx = r * 4 + c;
                                int[] ab = allBounds[idx];
                                int[] mb = mainBounds[idx];
                                if (ab[1] < ab[0] || ab[3] < ab[2]) continue;
                                int cropW = ab[1] - ab[0] + 1;
                                int cropH = ab[3] - ab[2] + 1;
                                double destW = cropW * scale;
                                double destH = cropH * scale;
                                double bodyCx = ((mb[0] + mb[1]) * 0.5 - ab[0]) * scale;
                                double bodyFoot = (mb[3] - ab[2]) * scale;
                                double dx = c * 400 + 200.0 - bodyCx;
                                double dy = r * 400 + 335.0 - bodyFoot;
                                dx = Math.Max(c * 400 + 4.0, Math.Min(c * 400 + 396.0 - destW, dx));
                                dy = Math.Max(r * 400 + 4.0, Math.Min(r * 400 + 396.0 - destH, dy));
                                ga.DrawImage(work, new RectangleF((float)dx, (float)dy, (float)destW, (float)destH), new RectangleF(ab[0], ab[2], cropW, cropH), GraphicsUnit.Pixel);
                            }
                        }
                    }
                    string dir = Path.GetDirectoryName(outAtlasPath);
                    if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                    atlas.Save(outAtlasPath, ImageFormat.Png);
                }
            }
        }
    }

    public static void SaveLosslessPng(string rawPath, string outPath, bool toneDownCenter) {
        string dir = Path.GetDirectoryName(outPath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
        using (Bitmap src = (Bitmap)Image.FromFile(rawPath)) {
            int outW = src.Width > 1920 ? 1920 : (src.Width / 4) * 4;
            int outH = src.Height > 1080 ? 1080 : (src.Height / 4) * 4;
            using (Bitmap bmp = new Bitmap(outW, outH, PixelFormat.Format32bppArgb)) {
                using (Graphics g = Graphics.FromImage(bmp)) {
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.DrawImage(src, 0, 0, outW, outH);
                }
                if (toneDownCenter) {
                    BitmapData bd = bmp.LockBits(new Rectangle(0, 0, outW, outH), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                    int bytes = Math.Abs(bd.Stride) * outH;
                    byte[] buf = new byte[bytes];
                    Marshal.Copy(bd.Scan0, buf, 0, bytes);
                    int stride = bd.Stride;
                    double cx = outW * 0.5, cy = outH * 0.5;
                    for (int y = 0; y < outH; y++) {
                        for (int x = 0; x < outW; x++) {
                            double nx = (x - cx) / (outW * 0.38);
                            double ny = (y - cy) / (outH * 0.38);
                            double d2 = nx * nx + ny * ny;
                            if (d2 < 1.0) {
                                double weight = 1.0 - d2;
                                double lumMult = 1.0 - 0.24 * weight;
                                double satDes = 0.24 * weight;
                                int off = y * stride + x * 4;
                                double b = buf[off], gr = buf[off + 1], r = buf[off + 2];
                                double avg = (r + gr + b) / 3.0;
                                r = (r * (1.0 - satDes) + avg * satDes) * lumMult;
                                gr = (gr * (1.0 - satDes) + avg * satDes) * lumMult;
                                b = (b * (1.0 - satDes) + avg * satDes) * lumMult;
                                buf[off] = (byte)Math.Max(0, Math.Min(255, Math.Round(b)));
                                buf[off + 1] = (byte)Math.Max(0, Math.Min(255, Math.Round(gr)));
                                buf[off + 2] = (byte)Math.Max(0, Math.Min(255, Math.Round(r)));
                            }
                        }
                    }
                    Marshal.Copy(buf, 0, bd.Scan0, bytes);
                    bmp.UnlockBits(bd);
                }
                bmp.Save(outPath, ImageFormat.Png);
            }
        }
    }
}
'@

Add-Type -TypeDefinition $csCode -ReferencedAssemblies System.Drawing

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$rawDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\source\raw"
$runtimeDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\runtime"
$envDir = "c:\Users\lucas\meu-jogo-estudio\assets\art\environment"

[NineRealmsArtPacker]::SaveLosslessPng((Join-Path $rawDir "mapa_arvore_9_reinos_v01.jpg"), "c:\Users\lucas\meu-jogo-estudio\assets\art\ui\mapa\arvore_9_reinos.png", $false)

$arenas = @(
    @{ id = "colina_raizes_profundas"; raw = "arena_colina_raizes_v01.jpg"; toneDown = $true },
    @{ id = "costa_abissal"; raw = "arena_costa_abissal_v01.jpg"; toneDown = $false },
    @{ id = "escarpas_copa_quebrada"; raw = "arena_escarpas_copa_v01.jpg"; toneDown = $false },
    @{ id = "fendas_cinzentas"; raw = "arena_fendas_cinzentas_v01.jpg"; toneDown = $false },
    @{ id = "terras_baldias_subterraneas"; raw = "arena_terras_baldias_v01.jpg"; toneDown = $false }
)
foreach ($ar in $arenas) {
    $rawP = Join-Path $rawDir $ar.raw
    if (Test-Path $rawP) {
        [NineRealmsArtPacker]::SaveLosslessPng($rawP, (Join-Path (Join-Path $envDir $ar.id) "arena_bg.png"), $ar.toneDown)
    }
}

$bosses = @(
    @{ id = "chefe_devorador_espinhos"; raw = "bos_devorador_espinhos_raw_v01.jpg"; mode = "BotanicalStrict"; grid = $false; jet = $false; rays = $false; is2x2 = $false; scale = "0.72" },
    @{ id = "chefe_leviata_mare"; raw = "bos_leviata_mare_raw_v01.jpg"; mode = "CyanSafe"; grid = $false; jet = $true; rays = $false; is2x2 = $false; scale = "0.82" },
    @{ id = "chefe_vigia_coroa"; raw = "bos_vigia_coroa_raw_v01.jpg"; mode = "StandardWithInner"; grid = $false; jet = $false; rays = $false; is2x2 = $true; scale = "0.88" },
    @{ id = "chefe_tirano_grilhoes"; raw = "bos_tirano_grilhoes_raw_v01.jpg"; mode = "StandardWithInner"; grid = $true; jet = $false; rays = $false; is2x2 = $false; scale = "0.84" },
    @{ id = "chefe_pesadelo_abismo"; raw = "bos_pesadelo_abismo_raw_v01.jpg"; mode = "StandardWithInner"; grid = $false; jet = $false; rays = $true; is2x2 = $false; scale = "0.92" }
)

foreach ($b in $bosses) {
    $rawP = Join-Path $rawDir $b.raw
    if (!(Test-Path $rawP)) { continue }
    $id = $b.id
    $bDir = Join-Path $runtimeDir $id
    $atlasPath = Join-Path $bDir "${id}_atlas_v01.png"
    if ($b.is2x2) {
        [NineRealmsArtPacker]::PackBoss2x2($rawP, $atlasPath, $b.mode)
    } else {
        [NineRealmsArtPacker]::PackBoss4x2($rawP, $atlasPath, $b.mode, $b.grid, $b.jet, $b.rays)
    }

    $manifest = @"
{
  "actor": "$id",
  "status": "runtime_ready",
  "canvas": [400, 400],
  "pivot": [200, 320],
  "cell_size": 400,
  "columns": 4,
  "rows": 2,
  "animations": {
    "idle_frente34": {"scale": $($b.scale)},
    "run_frente34": {"scale": $($b.scale)},
    "windup_frente34": {"scale": $($b.scale)},
    "attack1_frente34": {"scale": $($b.scale)},
    "attack_frente34": {"scale": $($b.scale)},
    "recover_frente34": {"scale": $($b.scale)},
    "hurt_frente34": {"scale": $($b.scale)},
    "idle_costas34": {"scale": $($b.scale)},
    "run_costas34": {"scale": $($b.scale)},
    "windup_costas34": {"scale": $($b.scale)},
    "attack1_costas34": {"scale": $($b.scale)},
    "attack_costas34": {"scale": $($b.scale)},
    "recover_costas34": {"scale": $($b.scale)},
    "death_frente34": {"scale": $($b.scale)},
    "death_costas34": {"scale": $($b.scale)}
  }
}
"@
    [System.IO.File]::WriteAllText((Join-Path $bDir "atlas_manifest_v01.json"), $manifest, $utf8NoBom)

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
"speed": 5.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_0")}],
"loop": true,
"name": &"run_frente34",
"speed": 6.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_0")}],
"loop": false,
"name": &"windup_frente34",
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
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_0")}],
"loop": false,
"name": &"recover_frente34",
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
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_0_1")}],
"loop": true,
"name": &"run_costas34",
"speed": 6.0
}, {
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_1_1")}],
"loop": false,
"name": &"windup_costas34",
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
"frames": [{"duration": 1.0, "texture": SubResource("Atlas_3_1")}],
"loop": false,
"name": &"recover_costas34",
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
"@
    [System.IO.File]::WriteAllText((Join-Path $bDir "${id}_frames_v01.tres"), $tres, $utf8NoBom)
}

Write-Output "PACK_9REINOS_ART_OK"

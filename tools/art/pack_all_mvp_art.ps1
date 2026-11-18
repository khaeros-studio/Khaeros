$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$csharpCode = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class KhaerosArtPacker
{
    public static Bitmap RemoveGreenChroma(string path, bool externalOnly)
    {
        using (Bitmap src = new Bitmap(path))
        {
            int w = src.Width;
            int h = src.Height;
            Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(dst))
            {
                g.DrawImage(src, 0, 0, w, h);
            }

            BitmapData bd = dst.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int bytes = Math.Abs(bd.Stride) * h;
            byte[] buf = new byte[bytes];
            Marshal.Copy(bd.Scan0, buf, 0, bytes);

            bool[] greenStd = new bool[w * h];
            bool[] greenStrict = new bool[w * h];

            for (int y = 0; y < h; y++)
            {
                int rowOffset = y * bd.Stride;
                for (int x = 0; x < w; x++)
                {
                    int idx = rowOffset + x * 4;
                    int b = buf[idx];
                    int g = buf[idx + 1];
                    int r = buf[idx + 2];
                    int maxRB = r > b ? r : b;
                    int diff = g - maxRB;

                    int flatIdx = y * w + x;
                    if (g > 110 && diff > 40)
                        greenStd[flatIdx] = true;
                    if (g > 155 && diff > 65)
                        greenStrict[flatIdx] = true;
                }
            }

            bool[] bg = new bool[w * h];
            Queue<int> q = new Queue<int>(w * 4);

            for (int x = 0; x < w; x++)
            {
                int top = x;
                int bot = (h - 1) * w + x;
                if (greenStd[top] && !bg[top]) { bg[top] = true; q.Enqueue(top); }
                if (greenStd[bot] && !bg[bot]) { bg[bot] = true; q.Enqueue(bot); }
            }
            for (int y = 0; y < h; y++)
            {
                int left = y * w;
                int right = y * w + (w - 1);
                if (greenStd[left] && !bg[left]) { bg[left] = true; q.Enqueue(left); }
                if (greenStd[right] && !bg[right]) { bg[right] = true; q.Enqueue(right); }
            }

            while (q.Count > 0)
            {
                int cur = q.Dequeue();
                int cy = cur / w;
                int cx = cur % w;

                if (cy > 0)
                {
                    int n = cur - w;
                    if (greenStd[n] && !bg[n]) { bg[n] = true; q.Enqueue(n); }
                }
                if (cy + 1 < h)
                {
                    int n = cur + w;
                    if (greenStd[n] && !bg[n]) { bg[n] = true; q.Enqueue(n); }
                }
                if (cx > 0)
                {
                    int n = cur - 1;
                    if (greenStd[n] && !bg[n]) { bg[n] = true; q.Enqueue(n); }
                }
                if (cx + 1 < w)
                {
                    int n = cur + 1;
                    if (greenStd[n] && !bg[n]) { bg[n] = true; q.Enqueue(n); }
                }
            }

            for (int y = 0; y < h; y++)
            {
                int rowOffset = y * bd.Stride;
                for (int x = 0; x < w; x++)
                {
                    int flatIdx = y * w + x;
                    int idx = rowOffset + x * 4;
                    bool isBg = bg[flatIdx] || (!externalOnly && greenStrict[flatIdx]);

                    if (isBg)
                    {
                        buf[idx] = 0;
                        buf[idx + 1] = 0;
                        buf[idx + 2] = 0;
                        buf[idx + 3] = 0;
                    }
                    else
                    {
                        int b = buf[idx];
                        int g = buf[idx + 1];
                        int r = buf[idx + 2];
                        int a = buf[idx + 3];
                        int maxRB = r > b ? r : b;
                        int excess = g - maxRB;
                        if (excess > 18)
                        {
                            double scale = 1.0 - (excess - 18.0) / 90.0;
                            if (scale < 0.0) scale = 0.0;
                            if (scale > 1.0) scale = 1.0;
                            int newA = (int)Math.Round(a * scale);
                            if (newA < 24)
                            {
                                buf[idx] = 0;
                                buf[idx + 1] = 0;
                                buf[idx + 2] = 0;
                                buf[idx + 3] = 0;
                            }
                            else
                            {
                                buf[idx + 1] = (byte)maxRB;
                                buf[idx + 3] = (byte)newA;
                            }
                        }
                    }
                }
            }

            Marshal.Copy(buf, 0, bd.Scan0, bytes);
            dst.UnlockBits(bd);
            return dst;
        }
    }

    public static void CleanMagentaInRegion(Bitmap bmp, int x0, int y0, int x1, int y1)
    {
        int w = bmp.Width;
        int h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);

        for (int y = Math.Max(0, y0); y < Math.Min(h, y1); y++)
        {
            int rowOffset = y * bd.Stride;
            for (int x = Math.Max(0, x0); x < Math.Min(w, x1); x++)
            {
                int idx = rowOffset + x * 4;
                int b = buf[idx];
                int g = buf[idx + 1];
                int r = buf[idx + 2];
                int a = buf[idx + 3];
                if (a > 0 && r > 120 && b > 80 && (r - g) > 45)
                {
                    buf[idx] = 20;     // B (#0D0E14)
                    buf[idx + 1] = 14; // G
                    buf[idx + 2] = 13; // R
                }
            }
        }

        Marshal.Copy(buf, 0, bd.Scan0, bytes);
        bmp.UnlockBits(bd);
    }

    public static int PurgeAnyMagenta(Bitmap bmp)
    {
        int w = bmp.Width;
        int h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);

        int count = 0;
        for (int y = 0; y < h; y++)
        {
            int rowOffset = y * bd.Stride;
            for (int x = 0; x < w; x++)
            {
                int idx = rowOffset + x * 4;
                int b = buf[idx];
                int g = buf[idx + 1];
                int r = buf[idx + 2];
                int a = buf[idx + 3];
                if (a > 0 && r > 130 && b > 90 && (r - g) > 45 && (b - g) > 25)
                {
                    byte lum = (byte)((r + g + b) / 3);
                    buf[idx] = lum;
                    buf[idx + 1] = lum;
                    buf[idx + 2] = lum;
                    count++;
                }
            }
        }

        Marshal.Copy(buf, 0, bd.Scan0, bytes);
        bmp.UnlockBits(bd);
        return count;
    }

    public static int[] FindMinProjectionCuts(int[] counts, int count, int searchRadius)
    {
        int len = counts.Length;
        int[] cuts = new int[count + 1];
        cuts[0] = 0;
        cuts[count] = len;

        for (int i = 1; i < count; i++)
        {
            int nominal = (int)Math.Round(i * (double)len / count);
            int best = nominal;
            int minVal = int.MaxValue;

            for (int d = 0; d <= searchRadius; d++)
            {
                int c1 = nominal - d;
                int c2 = nominal + d;
                if (c1 > 4 && c1 < len - 4)
                {
                    // Smooth 3-pixel window sum to find true valley
                    int v1 = counts[c1 - 1] + counts[c1] + counts[c1 + 1];
                    if (v1 < minVal)
                    {
                        minVal = v1;
                        best = c1;
                        if (v1 == 0) break;
                    }
                }
                if (c2 > 4 && c2 < len - 4)
                {
                    int v2 = counts[c2 - 1] + counts[c2] + counts[c2 + 1];
                    if (v2 < minVal)
                    {
                        minVal = v2;
                        best = c2;
                        if (v2 == 0) break;
                    }
                }
            }

            if (minVal == 0)
            {
                int left = best;
                int right = best;
                while (left > 0 && counts[left - 1] == 0) left--;
                while (right + 1 < len && counts[right + 1] == 0) right++;
                best = (left + right) / 2;
            }
            cuts[i] = best;
        }
        return cuts;
    }

    public static List<Bitmap> ExtractGridCells(Bitmap bmp, int[] colsPerRow, int uniformRow, int uniformCol)
    {
        int w = bmp.Width;
        int h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);
        bmp.UnlockBits(bd);

        int[] rowCounts = new int[h];
        for (int y = 0; y < h; y++)
        {
            int rowOffset = y * bd.Stride;
            int cnt = 0;
            for (int x = 0; x < w; x++)
            {
                if (buf[rowOffset + x * 4 + 3] > 10) cnt++;
            }
            rowCounts[y] = cnt;
        }

        int rows = colsPerRow.Length;
        int[] rowCuts = FindMinProjectionCuts(rowCounts, rows, 95);
        List<Bitmap> result = new List<Bitmap>();

        for (int r = 0; r < rows; r++)
        {
            int y0 = rowCuts[r];
            int y1 = rowCuts[r + 1];
            int cols = colsPerRow[r];

            int[] colCounts = new int[w];
            for (int x = 0; x < w; x++)
            {
                int cnt = 0;
                for (int y = y0; y < y1; y++)
                {
                    if (buf[y * bd.Stride + x * 4 + 3] > 10) cnt++;
                }
                colCounts[x] = cnt;
            }

            int[] colCuts = FindMinProjectionCuts(colCounts, cols, 85);

            for (int c = 0; c < cols; c++)
            {
                int cx0 = colCuts[c];
                int cx1 = colCuts[c + 1];
                int cy0 = y0;
                int cy1 = y1;

                if (r == uniformRow && c == uniformCol)
                {
                    int ux0 = (int)Math.Round(c * (double)w / cols);
                    int ux1 = (int)Math.Round((c + 1) * (double)w / cols);
                    cx0 = Math.Min(cx0, ux0);
                    cx1 = Math.Max(cx1, ux1);
                }

                int minX = cx1, maxX = cx0 - 1;
                int minY = cy1, maxY = cy0 - 1;

                for (int y = cy0; y < cy1; y++)
                {
                    int rowOffset = y * bd.Stride;
                    for (int x = cx0; x < cx1; x++)
                    {
                        if (buf[rowOffset + x * 4 + 3] > 10)
                        {
                            if (x < minX) minX = x;
                            if (x > maxX) maxX = x;
                            if (y < minY) minY = y;
                            if (y > maxY) maxY = y;
                        }
                    }
                }

                if (maxX < minX || maxY < minY)
                {
                    result.Add(new Bitmap(16, 16, PixelFormat.Format32bppArgb));
                }
                else
                {
                    Rectangle cropRect = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
                    Bitmap cellBmp = bmp.Clone(cropRect, PixelFormat.Format32bppArgb);
                    if (!(r == uniformRow && c == uniformCol))
                    {
                        RemoveEdgeOrphanFragments(cellBmp);
                    }
                    result.Add(cellBmp);
                }
            }
        }

        return result;
    }

    public static void RemoveEdgeOrphanFragments(Bitmap cellBmp)
    {
        int w = cellBmp.Width;
        int h = cellBmp.Height;
        if (w < 16 || h < 16) return;

        BitmapData bd = cellBmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);

        int[] labels = new int[w * h];
        List<int> compSizes = new List<int>();
        List<bool> touchesBorder = new List<bool>();
        compSizes.Add(0);
        touchesBorder.Add(false);

        int currentLabel = 0;
        int maxCompLabel = 0;
        int maxCompSize = 0;
        Queue<int> q = new Queue<int>();

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                int idx = y * w + x;
                if (labels[idx] == 0 && buf[y * bd.Stride + x * 4 + 3] > 10)
                {
                    currentLabel++;
                    int size = 0;
                    bool border = false;
                    labels[idx] = currentLabel;
                    q.Enqueue(idx);

                    while (q.Count > 0)
                    {
                        int cur = q.Dequeue();
                        size++;
                        int cy = cur / w;
                        int cx = cur % w;
                        if (cx == 0 || cx == w - 1 || cy == 0 || cy == h - 1)
                            border = true;

                        for (int dy = -2; dy <= 2; dy++)
                        {
                            int ny = cy + dy;
                            if (ny < 0 || ny >= h) continue;
                            for (int dx = -2; dx <= 2; dx++)
                            {
                                int nx = cx + dx;
                                if (nx < 0 || nx >= w) continue;
                                int nIdx = ny * w + nx;
                                if (labels[nIdx] == 0 && buf[ny * bd.Stride + nx * 4 + 3] > 10)
                                {
                                    labels[nIdx] = currentLabel;
                                    q.Enqueue(nIdx);
                                }
                            }
                        }
                    }

                    compSizes.Add(size);
                    touchesBorder.Add(border);
                    if (size > maxCompSize)
                    {
                        maxCompSize = size;
                        maxCompLabel = currentLabel;
                    }
                }
            }
        }

        if (currentLabel > 1)
        {
            for (int y = 0; y < h; y++)
            {
                int rowOffset = y * bd.Stride;
                for (int x = 0; x < w; x++)
                {
                    int lbl = labels[y * w + x];
                    if (lbl > 0 && lbl != maxCompLabel)
                    {
                        // Remove disconnected small fragments touching the cut border (neighbor bleed)
                        if (touchesBorder[lbl] && compSizes[lbl] < maxCompSize * 0.18)
                        {
                            int p = rowOffset + x * 4;
                            buf[p] = 0;
                            buf[p + 1] = 0;
                            buf[p + 2] = 0;
                            buf[p + 3] = 0;
                        }
                    }
                }
            }
            Marshal.Copy(buf, 0, bd.Scan0, bytes);
        }

        cellBmp.UnlockBits(bd);
    }

    public static List<Bitmap> ExtractU1Columns(Bitmap bmp)
    {
        int w = bmp.Width;
        int h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(bd.Stride) * h;
        byte[] buf = new byte[bytes];
        Marshal.Copy(bd.Scan0, buf, 0, bytes);
        bmp.UnlockBits(bd);

        int[] colCounts = new int[w];
        for (int x = 0; x < w; x++)
        {
            int cnt = 0;
            for (int y = 0; y < h; y++)
            {
                if (buf[y * bd.Stride + x * 4 + 3] > 10) cnt++;
            }
            colCounts[x] = cnt;
        }

        int[] colCuts = FindMinProjectionCuts(colCounts, 4, 75);
        List<Bitmap> result = new List<Bitmap>(); // 8 items: for each col, top and bottom

        for (int c = 0; c < 4; c++)
        {
            int cx0 = colCuts[c];
            int cx1 = colCuts[c + 1];
            int[] rowCounts = new int[h];
            for (int y = 0; y < h; y++)
            {
                int rowOffset = y * bd.Stride;
                int cnt = 0;
                for (int x = cx0; x < cx1; x++)
                {
                    if (buf[rowOffset + x * 4 + 3] > 10) cnt++;
                }
                rowCounts[y] = cnt;
            }
            int[] rowCuts = FindMinProjectionCuts(rowCounts, 2, 120);
            for (int r = 0; r < 2; r++)
            {
                int ry0 = rowCuts[r];
                int ry1 = rowCuts[r + 1];
                int minX = cx1, maxX = cx0 - 1;
                int minY = ry1, maxY = ry0 - 1;
                for (int y = ry0; y < ry1; y++)
                {
                    int rowOffset = y * bd.Stride;
                    for (int x = cx0; x < cx1; x++)
                    {
                        if (buf[rowOffset + x * 4 + 3] > 10)
                        {
                            if (x < minX) minX = x;
                            if (x > maxX) maxX = x;
                            if (y < minY) minY = y;
                            if (y > maxY) maxY = y;
                        }
                    }
                }
                Rectangle cropRect = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
                result.Add(bmp.Clone(cropRect, PixelFormat.Format32bppArgb));
            }
        }
        return result;
    }

    public static Bitmap ResizeHighQuality(Bitmap src, int targetW, int targetH)
    {
        Bitmap dst = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.DrawImage(src, new Rectangle(0, 0, targetW, targetH));
        }
        return dst;
    }

    public static Bitmap PlaceIn400x400(Bitmap crop, int maxW, int maxH)
    {
        int cw = crop.Width;
        int ch = crop.Height;
        Bitmap toDraw = crop;
        bool disposeToDraw = false;

        if (cw > maxW || ch > maxH)
        {
            double scale = Math.Min(maxW / (double)cw, maxH / (double)ch);
            int nw = Math.Max(1, (int)Math.Round(cw * scale));
            int nh = Math.Max(1, (int)Math.Round(ch * scale));
            toDraw = ResizeHighQuality(crop, nw, nh);
            disposeToDraw = true;
            cw = nw;
            ch = nh;
        }

        Bitmap cell = new Bitmap(400, 400, PixelFormat.Format32bppArgb);
        int px = Math.Max(0, Math.Min(400 - cw, 200 - cw / 2));
        int py = Math.Max(0, Math.Min(400 - ch, 320 - ch));

        using (Graphics g = Graphics.FromImage(cell))
        {
            g.DrawImage(toDraw, new Rectangle(px, py, cw, ch));
        }

        if (disposeToDraw)
            toDraw.Dispose();

        return cell;
    }

    public static void GenerateLimiarLut(string outPath)
    {
        Bitmap lut = new Bitmap(1024, 32, PixelFormat.Format24bppRgb);
        BitmapData bd = lut.LockBits(new Rectangle(0, 0, 1024, 32), ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
        int bytes = Math.Abs(bd.Stride) * 32;
        byte[] buf = new byte[bytes];

        double[][] protColors = new double[][]
        {
            new double[] { 0xE0 / 255.0, 0x25 / 255.0, 0x9C / 255.0 }, // Magenta #E0259C
            new double[] { 0xE3 / 255.0, 0xB2 / 255.0, 0x3C / 255.0 }, // Ouro #E3B23C
            new double[] { 0xE6 / 255.0, 0xDF / 255.0, 0xCF / 255.0 }, // Osso claro #E6DFCF
            new double[] { 0xCF / 255.0, 0xC6 / 255.0, 0xB4 / 255.0 }  // Osso #CFC6B4
        };

        for (int bIdx = 0; bIdx < 32; bIdx++)
        {
            double bVal = bIdx / 31.0;
            for (int gIdx = 0; gIdx < 32; gIdx++)
            {
                double gVal = gIdx / 31.0;
                int rowOffset = gIdx * bd.Stride;
                for (int rIdx = 0; rIdx < 32; rIdx++)
                {
                    double rVal = rIdx / 31.0;

                    double minDist = 10.0;
                    for (int p = 0; p < protColors.Length; p++)
                    {
                        double dr = rVal - protColors[p][0];
                        double dg = gVal - protColors[p][1];
                        double db = bVal - protColors[p][2];
                        double dist = Math.Sqrt(dr * dr + dg * dg + db * db);
                        if (dist < minDist) minDist = dist;
                    }

                    double protection = Math.Max(0.0, Math.Min(1.0, 1.0 - minDist / 0.35));
                    double lum = 0.2126 * rVal + 0.7152 * gVal + 0.0722 * bVal;
                    double maxC = Math.Max(rVal, Math.Max(gVal, bVal));
                    double minC = Math.Min(rVal, Math.Min(gVal, bVal));
                    double sat = maxC - minC;

                    double shadowWeight = (1.0 - lum) * lum * 4.0 * (1.0 - Math.Min(1.0, sat * 2.5));
                    double effect = shadowWeight * (1.0 - protection);

                    double outR = Math.Max(0.0, Math.Min(1.0, rVal - 0.015 * effect));
                    double outG = Math.Max(0.0, Math.Min(1.0, gVal));
                    double outB = Math.Max(0.0, Math.Min(1.0, bVal + 0.032 * effect));

                    int x = bIdx * 32 + rIdx;
                    int idx = rowOffset + x * 3;
                    buf[idx] = (byte)Math.Round(outB * 255.0);
                    buf[idx + 1] = (byte)Math.Round(outG * 255.0);
                    buf[idx + 2] = (byte)Math.Round(outR * 255.0);
                }
            }
        }

        Marshal.Copy(buf, 0, bd.Scan0, bytes);
        lut.UnlockBits(bd);
        lut.Save(outPath, ImageFormat.Png);
        lut.Dispose();
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies System.Drawing

$ROOT = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$RAW_DIR = Join-Path $ROOT "assets\art\source\raw"
$RUNTIME_DIR = Join-Path $ROOT "assets\art\runtime"
$UI_DIR = Join-Path $ROOT "assets\art\ui"
$ENV_DIR = Join-Path $ROOT "assets\art\environment\limiar"
$LUT_DIR = Join-Path $ROOT "assets\art\lut"

function Build-ActorAtlas {
    param(
        [string]$ActorId,
        [System.Collections.Generic.List[System.Drawing.Bitmap]]$Frames,
        [array]$Animations,
        [double]$LogicalSize,
        [double]$ScaleVal
    )

    $outDir = Join-Path $RUNTIME_DIR $ActorId
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $totalFrames = $Frames.Count
    $cols = 8
    $rows = [int][Math]::Ceiling($totalFrames / 8.0)
    $atlasW = $cols * 400
    $atlasH = $rows * 400

    $atlasBmp = New-Object System.Drawing.Bitmap($atlasW, $atlasH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($atlasBmp)
    for ($i = 0; $i -lt $totalFrames; $i++) {
        $gx = ($i % $cols) * 400
        $gy = [int][Math]::Floor($i / $cols) * 400
        $g.DrawImage($Frames[$i], (New-Object System.Drawing.Rectangle($gx, $gy, 400, 400)))
        $Frames[$i].Dispose()
    }
    $g.Dispose()

    $atlasPath = Join-Path $outDir "${ActorId}_atlas_v01.png"
    $atlasBmp.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $atlasBmp.Dispose()

    $scaleStr = $ScaleVal.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
    $logStr = $LogicalSize.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)

    # Manifest JSON
    $animJsonLines = @()
    foreach ($anim in $Animations) {
        $aName = $anim[0]
        $aCount = $anim[1]
        $aLoop = if ($anim[2]) { "true" } else { "false" }
        $animJsonLines += "`t`t`"$aName`": { `"scale`": $scaleStr, `"frames`": $aCount, `"loop`": $aLoop, `"fps`": 12 }"
    }

    $manifestText = @"
{
	"status": "runtime_ready",
	"canvas": [400, 400],
	"pivot": [200, 320],
	"logical_size": $logStr,
	"animations": {
$($animJsonLines -join ",`n")
	}
}
"@
    $manifestPath = Join-Path $outDir "atlas_manifest_v01.json"
    [System.IO.File]::WriteAllText($manifestPath, $manifestText + "`n", (New-Object System.Text.UTF8Encoding($false)))

    # SpriteFrames .tres
    $loadSteps = 2 + $totalFrames
    $resAtlasPath = "res://assets/art/runtime/$ActorId/${ActorId}_atlas_v01.png"
    $tresLines = New-Object System.Collections.Generic.List[string]
    $tresLines.Add("[gd_resource type=`"SpriteFrames`" load_steps=$loadSteps format=3]")
    $tresLines.Add("")
    $tresLines.Add("[ext_resource type=`"Texture2D`" path=`"$resAtlasPath`" id=`"1`"]")
    $tresLines.Add("")

    for ($i = 0; $i -lt $totalFrames; $i++) {
        $gx = ($i % $cols) * 400
        $gy = [int][Math]::Floor($i / $cols) * 400
        $fid = "frame_{0:D2}" -f $i
        $tresLines.Add("[sub_resource type=`"AtlasTexture`" id=`"$fid`"]")
        $tresLines.Add("atlas = ExtResource(`"1`")")
        $tresLines.Add("region = Rect2($gx, $gy, 400, 400)")
        $tresLines.Add("filter_clip = true")
        $tresLines.Add("")
    }

    $animEntries = @()
    $cursor = 0
    foreach ($anim in $Animations) {
        $aName = $anim[0]
        $aCount = $anim[1]
        $aLoop = if ($anim[2]) { "true" } else { "false" }
        $durs = $anim[3]
        $fList = @()
        for ($k = 0; $k -lt $aCount; $k++) {
            $durVal = if ($k -lt $durs.Count) { $durs[$k] } else { 1.0 }
            $durStr = ([double]$durVal).ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)
            $fid = "frame_{0:D2}" -f $cursor
            $fList += "{`"duration`": $durStr, `"texture`": SubResource(`"$fid`")}"
            $cursor++
        }
        $animEntries += "{`"frames`": [$($fList -join ', ')], `"loop`": $aLoop, `"name`": &`"$aName`", `"speed`": 12.0}"
    }

    if ($cursor -ne $totalFrames) {
        throw "$ActorId frame cursor $cursor != $totalFrames"
    }

    $tresLines.Add("[resource]")
    $tresLines.Add("animations = [" + ($animEntries -join ",`n") + "]")
    $tresPath = Join-Path $outDir "${ActorId}_frames_v01.tres"
    [System.IO.File]::WriteAllText($tresPath, ($tresLines -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))

    Write-Output "PACKED_ACTOR actor=$ActorId frames=$totalFrames animations=$($Animations.Count) size=${atlasW}x${atlasH}"
}

function Get-PlacedCells {
    param(
        [string]$RawFile,
        [int[]]$ColsPerRow,
        [bool]$ExternalOnly = $false,
        [int]$UniformRow = -1,
        [int]$UniformCol = -1,
        [int]$MaxW = 340,
        [int]$MaxH = 290,
        [scriptblock]$PreProcess = $null
    )
    $path = Join-Path $RAW_DIR $RawFile
    $bmp = [KhaerosArtPacker]::RemoveGreenChroma($path, $ExternalOnly)
    if ($null -ne $PreProcess) {
        & $PreProcess $bmp
    }
    $crops = [KhaerosArtPacker]::ExtractGridCells($bmp, $ColsPerRow, $UniformRow, $UniformCol)
    $bmp.Dispose()

    $cells = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
    foreach ($c in $crops) {
        $cells.Add([KhaerosArtPacker]::PlaceIn400x400($c, $MaxW, $MaxH))
        $c.Dispose()
    }
    return ,$cells
}

Write-Output "=== [1/5] Empacotando 6 Novos Atores em assets/art/runtime/ ==="

$std16Anims = @(
    @("spawn_frente34", 4, $false, @(1.0, 1.0, 1.0, 1.0)),
    @("idle_frente34", 2, $true, @(1.0, 1.0)),
    @("run_frente34", 6, $true, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("spawn_costas34", 4, $false, @(1.0, 1.0, 1.0, 1.0)),
    @("idle_costas34", 2, $true, @(1.0, 1.0)),
    @("run_costas34", 6, $true, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("windup_frente34", 3, $false, @(1.5, 1.5, 3.0)),
    @("attack_frente34", 2, $false, @(1.0, 1.0)),
    @("recover_frente34", 2, $false, @(5.0, 5.0)),
    @("hurt_frente34", 1, $false, @(1.0)),
    @("death_frente34", 2, $false, @(1.0, 1.0)),
    @("windup_costas34", 3, $false, @(1.5, 1.5, 3.0)),
    @("attack_costas34", 2, $false, @(1.0, 1.0)),
    @("recover_costas34", 2, $false, @(5.0, 5.0)),
    @("hurt_costas34", 1, $false, @(1.0)),
    @("death_costas34", 2, $false, @(1.0, 1.0))
)

# 1. vulto_mudo (VM1-F tem 14 poses em 3 fileiras: 6 + 4 + 4 -> pega 6 da fileira 1 e 6 das fileiras 2-3)
$vm1FAll = Get-PlacedCells "mal_vulto_mudo_spawnrun_frente34_raw_v01.jpg" @(6, 4, 4)
$vmFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
for ($i = 0; $i -lt 12; $i++) { $vmFrames.Add($vm1FAll[$i]) }
for ($i = 12; $i -lt $vm1FAll.Count; $i++) { $vm1FAll[$i].Dispose() }
foreach ($c in (Get-PlacedCells "mal_vulto_mudo_spawnrun_costas34_raw_v01.jpg" @(6, 6))) { $vmFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_vulto_mudo_ataquemorte_frente34_raw_v01.jpg" @(5, 5))) { $vmFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_vulto_mudo_ataquemorte_costas34_raw_v01.jpg" @(5, 5))) { $vmFrames.Add($c) }
Build-ActorAtlas "vulto_mudo" $vmFrames $std16Anims 92.0 0.4100

# 2. espreitador_da_fenda
$efFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
foreach ($c in (Get-PlacedCells "mal_espreitador_fenda_spawnrun_frente34_raw_v01.jpg" @(6, 6))) { $efFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_espreitador_fenda_spawnrun_costas34_raw_v01.jpg" @(6, 6))) { $efFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_espreitador_fenda_ataquemorte_frente34_raw_v01.jpg" @(5, 5))) { $efFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_espreitador_fenda_ataquemorte_costas34_raw_v01.jpg" @(5, 5))) { $efFrames.Add($c) }
Build-ActorAtlas "espreitador_da_fenda" $efFrames $std16Anims 98.0 0.4200

# 3. baluarte_de_cinza
$bcFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
foreach ($c in (Get-PlacedCells "mal_baluarte_cinza_spawnrun_frente34_raw_v01.jpg" @(6, 6))) { $bcFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_baluarte_cinza_spawnrun_costas34_raw_v01.jpg" @(6, 6))) { $bcFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_baluarte_cinza_ataquemorte_frente34_raw_v01.jpg" @(5, 5))) { $bcFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_baluarte_cinza_ataquemorte_costas34_raw_v01.jpg" @(5, 5))) { $bcFrames.Add($c) }
Build-ActorAtlas "baluarte_de_cinza" $bcFrames $std16Anims 118.0 0.4600

# 4. soberano_do_limiar (forma aliada)
$saFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
foreach ($c in (Get-PlacedCells "mal_soberano_aliado_spawnrun_frente34_raw_v01.jpg" @(6, 6) -ExternalOnly $true)) { $saFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_soberano_aliado_spawnrun_costas34_raw_v01.jpg" @(6, 6) -ExternalOnly $true)) { $saFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_soberano_aliado_ataquemorte_frente34_raw_v01.jpg" @(5, 5) -ExternalOnly $true)) { $saFrames.Add($c) }
foreach ($c in (Get-PlacedCells "mal_soberano_aliado_ataquemorte_costas34_raw_v01.jpg" @(5, 5) -ExternalOnly $true)) { $saFrames.Add($c) }
Build-ActorAtlas "soberano_do_limiar" $saFrames $std16Anims 115.0 0.4500

# 5. chefe_soberano_limiar (48 frames, 26 animações + retoques Art Director)
$bossFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
$b1FCells = Get-PlacedCells "bos_soberano_limiar_movgarra_frente34_raw_v01.jpg" @(6, 6) -MaxW 360 -MaxH 300 -PreProcess {
    param($b)
    [KhaerosArtPacker]::CleanMagentaInRegion($b, 80, 225, 200, 265)
    [KhaerosArtPacker]::CleanMagentaInRegion($b, 300, 130, 390, 175)
}
foreach ($c in $b1FCells) { $bossFrames.Add($c) }
foreach ($c in (Get-PlacedCells "bos_soberano_limiar_movgarra_costas34_raw_v01.jpg" @(6, 6) -MaxW 360 -MaxH 300)) { $bossFrames.Add($c) }
foreach ($c in (Get-PlacedCells "bos_soberano_limiar_ataquesfuria_frente34_raw_v01.jpg" @(6, 6) -UniformRow 1 -UniformCol 5 -MaxW 360 -MaxH 300)) { $bossFrames.Add($c) }
foreach ($c in (Get-PlacedCells "bos_soberano_limiar_ataquesfuria_costas34_raw_v01.jpg" @(6, 6) -UniformRow 1 -UniformCol 5 -MaxW 360 -MaxH 300)) { $bossFrames.Add($c) }

$bossAnims = @(
    @("spawn_frente34", 4, $false, @(1.0, 1.0, 1.0, 1.0)),
    @("idle_frente34", 2, $true, @(1.0, 1.0)),
    @("run_frente34", 3, $true, @(1.0, 1.0, 1.0)),
    @("windup_frente34", 1, $false, @(2.5)),
    @("attack_frente34", 1, $false, @(1.5)),
    @("recover_frente34", 1, $false, @(4.0)),
    @("spawn_costas34", 4, $false, @(1.0, 1.0, 1.0, 1.0)),
    @("idle_costas34", 2, $true, @(1.0, 1.0)),
    @("run_costas34", 3, $true, @(1.0, 1.0, 1.0)),
    @("windup_costas34", 1, $false, @(2.5)),
    @("attack_costas34", 1, $false, @(1.5)),
    @("recover_costas34", 1, $false, @(4.0)),
    @("irrupcao_frente34", 2, $false, @(2.0, 1.5)),
    @("pulso_frente34", 2, $false, @(2.0, 2.0)),
    @("convergencia_frente34", 2, $false, @(2.0, 2.0)),
    @("furia_frente34", 2, $false, @(2.0, 2.5)),
    @("hurt_frente34", 1, $false, @(1.0)),
    @("subjugado_frente34", 2, $true, @(2.0, 2.0)),
    @("death_frente34", 1, $false, @(4.0)),
    @("irrupcao_costas34", 2, $false, @(2.0, 1.5)),
    @("pulso_costas34", 2, $false, @(2.0, 2.0)),
    @("convergencia_costas34", 2, $false, @(2.0, 2.0)),
    @("furia_costas34", 2, $false, @(2.0, 2.5)),
    @("hurt_costas34", 1, $false, @(1.0)),
    @("subjugado_costas34", 2, $true, @(2.0, 2.0)),
    @("death_costas34", 1, $false, @(4.0))
)
Build-ActorAtlas "chefe_soberano_limiar" $bossFrames $bossAnims 168.0 0.5800

# 6. iniciado_pactos (44 frames, 8 animações)
$pactosFrames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
foreach ($c in (Get-PlacedCells "chr_iniciado_pactos_idlevirote_frente34_raw_v01.jpg" @(6, 6))) { $pactosFrames.Add($c) }
foreach ($c in (Get-PlacedCells "chr_iniciado_pactos_idlevirote_costas34_raw_v01.jpg" @(6, 6))) { $pactosFrames.Add($c) }
foreach ($c in (Get-PlacedCells "chr_iniciado_pactos_chamado_frente34_raw_v01.jpg" @(5, 5))) { $pactosFrames.Add($c) }
foreach ($c in (Get-PlacedCells "chr_iniciado_pactos_chamado_costas34_raw_v01.jpg" @(5, 5))) { $pactosFrames.Add($c) }

$pactosAnims = @(
    @("idle_frente34", 6, $true, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("virote_frente34", 6, $false, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("idle_costas34", 6, $true, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("virote_costas34", 6, $false, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("chamado_frente34", 6, $false, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("troca_frente34", 4, $false, @(1.0, 1.0, 1.0, 1.0)),
    @("chamado_costas34", 6, $false, @(1.0, 1.0, 1.0, 1.0, 1.0, 1.0)),
    @("troca_costas34", 4, $false, @(1.0, 1.0, 1.0, 1.0))
)
Build-ActorAtlas "iniciado_pactos" $pactosFrames $pactosAnims 94.0 0.4087

Write-Output "=== [2/5] Empacotando Silhuetas e Retratos de Maldicao (story-007) ==="
$malDir = Join-Path $UI_DIR "maldicoes"
New-Item -ItemType Directory -Force -Path $malDir | Out-Null

$u4Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "ui_maldicoes_silhuetas_retratos_raw_v01.jpg"), $true)
$u4Cells = [KhaerosArtPacker]::ExtractGridCells($u4Bmp, @(5, 4), -1, -1)
$u4Bmp.Dispose()

$silNames = @(
    "silhueta_vulto_mudo",
    "silhueta_espreitador_da_fenda",
    "silhueta_baluarte_de_cinza",
    "silhueta_soberano_do_limiar",
    "silhueta_generica"
)
for ($i = 0; $i -lt 5; $i++) {
    $cell = $u4Cells[$i]
    [void][KhaerosArtPacker]::PurgeAnyMagenta($cell)
    foreach ($sz in @(72, 56)) {
        $resized = [KhaerosArtPacker]::ResizeHighQuality($cell, $sz, $sz)
        $magCount = [KhaerosArtPacker]::PurgeAnyMagenta($resized)
        $outPath = Join-Path $malDir "$($silNames[$i])_${sz}.png"
        $resized.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resized.Dispose()
        Write-Output "SAVED_SILHUETA file=$($silNames[$i])_${sz}.png size=${sz}x${sz} magenta_pixels=0"
    }
    $cell.Dispose()
}

$retNames = @(
    "retrato_vulto_mudo.png",
    "retrato_espreitador_da_fenda.png",
    "retrato_baluarte_de_cinza.png",
    "retrato_soberano_do_limiar.png"
)
for ($i = 0; $i -lt 4; $i++) {
    $cell = $u4Cells[5 + $i]
    [void][KhaerosArtPacker]::PurgeAnyMagenta($cell)
    $outPath = Join-Path $malDir $retNames[$i]
    $cell.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "SAVED_RETRATO file=$($retNames[$i]) size=$($cell.Width)x$($cell.Height) magenta_pixels=0"
    $cell.Dispose()
}

Write-Output "=== [3/5] Gerando LUT 3D 32^3 do Limiar (story-008) ==="
New-Item -ItemType Directory -Force -Path $LUT_DIR | Out-Null
$lutPngPath = Join-Path $LUT_DIR "limiar.png"
[KhaerosArtPacker]::GenerateLimiarLut($lutPngPath)

$lutImportText = @"
[remap]

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
"@
$lutImportPath = Join-Path $LUT_DIR "limiar.png.import"
[System.IO.File]::WriteAllText($lutImportPath, $lutImportText, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "SAVED_LUT file=assets/art/lut/limiar.png size=1024x32 import=limiar.png.import"

Write-Output "=== [4/5] Empacotando Cartas (U1), Glifos (U2), HUD (U3), Cenario (C1-C3) e Pecas (W0) ==="

# U1: Cartas
$cartasDir = Join-Path $UI_DIR "cartas"
New-Item -ItemType Directory -Force -Path $cartasDir | Out-Null
$u1Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "ui_cartas_molduras_coroas_raw_v01.jpg"), $true)
$u1Pairs = [KhaerosArtPacker]::ExtractU1Columns($u1Bmp)
$u1Bmp.Dispose()

# u1Pairs indices: [0]=col0_top, [1]=col0_bot, [2]=col1_top, [3]=col1_bot, [4]=col2_top, [5]=col2_bot, [6]=col3_top, [7]=col3_bot
$mComum = [KhaerosArtPacker]::ResizeHighQuality($u1Pairs[0], 320, 500)
$mRara = [KhaerosArtPacker]::ResizeHighQuality($u1Pairs[2], 320, 500)
$mEpica = [KhaerosArtPacker]::ResizeHighQuality($u1Pairs[4], 320, 500)
$vCarta = [KhaerosArtPacker]::ResizeHighQuality($u1Pairs[7], 320, 500)

$mComum.Save((Join-Path $cartasDir "moldura_comum.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$mRara.Save((Join-Path $cartasDir "moldura_rara.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$mEpica.Save((Join-Path $cartasDir "moldura_epica.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$u1Pairs[6].Save((Join-Path $cartasDir "selo_preco.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$u1Pairs[1].Save((Join-Path $cartasDir "coroa_lamina.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$u1Pairs[3].Save((Join-Path $cartasDir "coroa_ressonancia.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$u1Pairs[5].Save((Join-Path $cartasDir "coroa_pactos.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$vCarta.Save((Join-Path $cartasDir "verso_carta.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$mComum.Dispose(); $mRara.Dispose(); $mEpica.Dispose(); $vCarta.Dispose()
foreach ($b in $u1Pairs) { $b.Dispose() }
Write-Output "SAVED_U1_CARTAS count=8 dir=assets/art/ui/cartas/"

# U2: Glifos (2 fileiras superiores y=0..505)
$glifosDir = Join-Path $UI_DIR "glifos"
New-Item -ItemType Directory -Force -Path $glifosDir | Out-Null
$u2Full = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "ui_glifos_tradicoes_status_raw_v01.jpg"), $true)
$u2Crop = $u2Full.Clone((New-Object System.Drawing.Rectangle(0, 0, $u2Full.Width, 505)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$u2Full.Dispose()
$u2Cells = [KhaerosArtPacker]::ExtractGridCells($u2Crop, @(6, 6), -1, -1)
$u2Crop.Dispose()

$u2Names = @(
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
    "status_abalo.png"
)
for ($i = 0; $i -lt 12; $i++) {
    $u2Cells[$i].Save((Join-Path $glifosDir $u2Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $u2Cells[$i].Dispose()
}
Write-Output "SAVED_U2_GLIFOS count=12 dir=assets/art/ui/glifos/"

# U3: HUD (remove verde externo e interno das peças vazadas)
$hudDir = Join-Path $UI_DIR "hud"
New-Item -ItemType Directory -Force -Path $hudDir | Out-Null
$u3Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "ui_hud_elementos_raw_v01.jpg"), $false)
$u3Cells = [KhaerosArtPacker]::ExtractGridCells($u3Bmp, @(4, 4), -1, -1)
$u3Bmp.Dispose()

$u3Names = @(
    "placa_fundo.png",
    "segmentos_vida.png",
    "moldura_vida_baixa.png",
    "recusa_escudo.png",
    "gota_fluxo.png",
    "chevrons_esquiva.png",
    "icone_fragmento.png",
    "barra_chefe.png"
)
for ($i = 0; $i -lt 8; $i++) {
    $u3Cells[$i].Save((Join-Path $hudDir $u3Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $u3Cells[$i].Dispose()
}
Write-Output "SAVED_U3_HUD count=8 dir=assets/art/ui/hud/"

# C1, C2, C3: Cenário do Limiar
New-Item -ItemType Directory -Force -Path $ENV_DIR | Out-Null

$c1Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "env_limiar_chao_bordas_raw_v01.jpg"), $true)
$c1Cells = [KhaerosArtPacker]::ExtractGridCells($c1Bmp, @(4, 4), -1, -1)
$c1Bmp.Dispose()
$c1Names = @(
    "chao_laje_01.png", "chao_laje_02.png", "chao_laje_03.png", "chao_laje_04.png",
    "borda_parede_01.png", "borda_parede_02.png", "borda_parede_03.png", "borda_parede_04.png"
)
for ($i = 0; $i -lt 8; $i++) {
    $c1Cells[$i].Save((Join-Path $ENV_DIR $c1Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $c1Cells[$i].Dispose()
}

$c2Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "env_limiar_pilares_santuario_raw_v01.jpg"), $true)
$c2Cells = [KhaerosArtPacker]::ExtractGridCells($c2Bmp, @(3, 3), -1, -1)
$c2Bmp.Dispose()
$c2Names = @(
    "obstaculo_rocha_01.png", "obstaculo_rocha_02.png", "obstaculo_rocha_03.png",
    "obstaculo_coluna_04.png", "pilar_chefe.png", "altar_santuario.png"
)
for ($i = 0; $i -lt 6; $i++) {
    $c2Cells[$i].Save((Join-Path $ENV_DIR $c2Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $c2Cells[$i].Dispose()
}

$c3Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "env_limiar_portas_foreground_raw_v01.jpg"), $true)
$c3Cells = [KhaerosArtPacker]::ExtractGridCells($c3Bmp, @(4, 4), -1, -1)
$c3Bmp.Dispose()
$c3Names = @(
    "porta_fechada.png", "porta_aberta.png", "porta_chefe.png", "pedestal_pacto.png",
    "totem_bencao.png", "totem_fragmentos.png", "totem_cura.png", "foreground_silhueta.png"
)
for ($i = 0; $i -lt 8; $i++) {
    $c3Cells[$i].Save((Join-Path $ENV_DIR $c3Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $c3Cells[$i].Dispose()
}
Write-Output "SAVED_C1_C2_C3_ENV count=22 dir=assets/art/environment/limiar/"

# W0: Peças de Doutrinas e Projéteis
$w0Dir = Join-Path $RUNTIME_DIR "pecas_doutrinas"
New-Item -ItemType Directory -Force -Path $w0Dir | Out-Null
$w0Bmp = [KhaerosArtPacker]::RemoveGreenChroma((Join-Path $RAW_DIR "wep_pecas_doutrinas_raw_v01.jpg"), $false)
$w0Cells = [KhaerosArtPacker]::ExtractGridCells($w0Bmp, @(4, 4), -1, -1)
$w0Bmp.Dispose()
$w0Names = @(
    "emblema_lamina.png", "emblema_ressonancia.png", "emblema_pactos.png", "virote_vinculo.png",
    "pulso_ressonante.png", "projetil_anomalia.png", "marca_virote.png", "indicador_atracao.png"
)
for ($i = 0; $i -lt 8; $i++) {
    $w0Cells[$i].Save((Join-Path $w0Dir $w0Names[$i]), [System.Drawing.Imaging.ImageFormat]::Png)
    $w0Cells[$i].Dispose()
}
Write-Output "SAVED_W0_PECAS count=8 dir=assets/art/runtime/pecas_doutrinas/"

Write-Output "=== [5/5] Validando Todos os 11 Atores de Runtime ==="
$expectedActors = [ordered]@{
    "anomalia_menor"        = @{ frames = 44; animations = 16 }
    "eco_perdido"           = @{ frames = 44; animations = 16 }
    "fenda_errante"         = @{ frames = 44; animations = 16 }
    "iniciado_lamina"       = @{ frames = 108; animations = 18 }
    "elite_pecas"           = @{ frames = 6; animations = 6 }
    "vulto_mudo"            = @{ frames = 44; animations = 16 }
    "espreitador_da_fenda"  = @{ frames = 44; animations = 16 }
    "baluarte_de_cinza"     = @{ frames = 44; animations = 16 }
    "soberano_do_limiar"    = @{ frames = 44; animations = 16 }
    "chefe_soberano_limiar" = @{ frames = 48; animations = 26 }
    "iniciado_pactos"       = @{ frames = 44; animations = 8 }
}

foreach ($actorId in $expectedActors.Keys) {
    $spec = $expectedActors[$actorId]
    $actorDir = Join-Path $RUNTIME_DIR $actorId
    $tresPath = Join-Path $actorDir "${actorId}_frames_v01.tres"
    $jsonPath = Join-Path $actorDir "atlas_manifest_v01.json"

    if (-not (Test-Path $tresPath)) { throw "Missing $tresPath" }
    if (-not (Test-Path $jsonPath)) { throw "Missing $jsonPath" }

    $manifest = Get-Content $jsonPath -Raw | ConvertFrom-Json
    $manifestAnimNames = @($manifest.animations.PSObject.Properties.Name)
    if ($manifestAnimNames.Count -ne $spec.animations) {
        throw "$actorId manifest animations count $($manifestAnimNames.Count) != $($spec.animations)"
    }

    $tresText = Get-Content $tresPath -Raw
    $animMatches = [regex]::Matches($tresText, '"name":\s*&"([^"]+)"')
    if ($animMatches.Count -ne $spec.animations) {
        throw "$actorId tres animations count $($animMatches.Count) != $($spec.animations)"
    }
    foreach ($m in $animMatches) {
        $aname = $m.Groups[1].Value
        if ($manifestAnimNames -notcontains $aname) {
            throw "$actorId missing animation $aname in manifest"
        }
    }

    $subMatches = [regex]::Matches($tresText, 'SubResource\("frame_\d+"\)')
    if ($subMatches.Count -ne $spec.frames) {
        throw "$actorId frame refs $($subMatches.Count) != $($spec.frames)"
    }

    $atlasPng = Join-Path $actorDir "${actorId}_atlas_v01.png"
    if (Test-Path $atlasPng) {
        $img = [System.Drawing.Image]::FromFile($atlasPng)
        $aw = $img.Width
        $ah = $img.Height
        $img.Dispose()

        $rectMatches = [regex]::Matches($tresText, 'region\s*=\s*Rect2\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
        if ($rectMatches.Count -ne $spec.frames) {
            throw "$actorId region count $($rectMatches.Count) != $($spec.frames)"
        }
        foreach ($rm in $rectMatches) {
            $rx = [int]$rm.Groups[1].Value
            $ry = [int]$rm.Groups[2].Value
            $rw = [int]$rm.Groups[3].Value
            $rh = [int]$rm.Groups[4].Value
            if ($rw -ne 400 -or $rh -ne 400) {
                throw "$actorId invalid region size ${rw}x${rh}"
            }
            if ($rx -lt 0 -or $ry -lt 0 -or ($rx + $rw) -gt $aw -or ($ry + $rh) -gt $ah) {
                throw "$actorId region ($rx,$ry,$rw,$rh) out of bounds (${aw}x${ah})"
            }
        }
    }

    Write-Output "VALIDATED_ATLAS actor=$actorId frames=$($spec.frames) animations=$($spec.animations)"
}

Write-Output "ALL_RUNTIME_ATLASES_OK actors=$($expectedActors.Count)"

param([string]$saida)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public struct R { public int L, T, Ri, B; }
public static class W { [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); }
"@
$p = $null
for ($i=0; $i -lt 120 -and -not $p; $i++) { Start-Sleep -Milliseconds 250; $p = Get-Process | Where-Object { $_.MainWindowTitle -like "EX-0007*" } | Select-Object -First 1 }
if (-not $p) { "PS|janela nao encontrada"; exit 1 }
$r = New-Object R
for ($i=0; $i -lt 200; $i++) { Start-Sleep -Milliseconds 100; [void][W]::GetWindowRect($p.MainWindowHandle, [ref]$r); if (($r.Ri - $r.L) -gt 900 -and ($r.B - $r.T) -lt 500) { break } }
[void][W]::SetForegroundWindow($p.MainWindowHandle); Start-Sleep -Milliseconds 1500
[void][W]::GetWindowRect($p.MainWindowHandle, [ref]$r)
$bmp = New-Object System.Drawing.Bitmap ($r.Ri - $r.L), ($r.B - $r.T)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
$bmp.Save($saida); "PS|captura $($bmp.Width)x$($bmp.Height) -> $saida"

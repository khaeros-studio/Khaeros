param([string]$titulo = "EX-0001 passo e quadro")
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class W {
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c, string t);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
}
"@
$h = [IntPtr]::Zero
for ($i=0; $i -lt 40 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 250; $p = Get-Process | Where-Object { $_.MainWindowTitle -like "EX-0001*" } | Select-Object -First 1; if ($p) { $h = $p.MainWindowHandle; $t = $p.MainWindowTitle } }
if ($h -eq [IntPtr]::Zero) { Write-Output "PS|janela nao encontrada"; exit 1 }
Write-Output "PS|janela: $t"; Start-Sleep -Seconds 3
Write-Output ("PS|t={0:HH:mm:ss.fff} SC_MOVE (loop modal de mover)" -f (Get-Date))
[void][W]::PostMessage($h, 0x0112, [IntPtr]0xF010, [IntPtr]0)
Start-Sleep -Milliseconds 300
for ($k=0; $k -lt 20; $k++) { [void][W]::PostMessage($h, 0x0100, [IntPtr]0x27, [IntPtr]0); Start-Sleep -Milliseconds 100 }
Start-Sleep -Seconds 1
[void][W]::PostMessage($h, 0x0100, [IntPtr]0x0D, [IntPtr]0)
Write-Output ("PS|t={0:HH:mm:ss.fff} ENTER (fim do mover, ~3,3 s de loop modal)" -f (Get-Date))

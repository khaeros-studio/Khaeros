# PROTOTYPE - NOT FOR PRODUCTION. Perda/ganho de foco e clique de ativação com input injetado (SendInput).
Add-Type @"
using System; using System.Runtime.InteropServices;
public struct RECT { public int L, T, R, B; }
public static class W {
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e);
 [DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr e);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
}
"@
function T($m) { Write-Output ("PS|{0:HH:mm:ss.fff} {1}" -f (Get-Date), $m) }
$h = [IntPtr]::Zero
for ($i=0; $i -lt 60 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 250; $p = Get-Process | Where-Object { $_.MainWindowTitle -like "EX-0001 foco*" } | Select-Object -First 1; if ($p) { $h = $p.MainWindowHandle } }
if ($h -eq [IntPtr]::Zero) { T "janela nao encontrada"; exit 1 }
Start-Sleep -Seconds 8
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
T "MINIMIZAR"; [void][W]::ShowWindow($h, 6); Start-Sleep -Seconds 1
T "RESTAURAR"; [void][W]::ShowWindow($h, 9); Start-Sleep -Seconds 1
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
T "ALT+TAB (sair)"; [W]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,2,[UIntPtr]::Zero); [W]::keybd_event(0x12,0,2,[UIntPtr]::Zero); Start-Sleep -Seconds 1
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
T "ALT+TAB (voltar)"; [W]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,2,[UIntPtr]::Zero); [W]::keybd_event(0x12,0,2,[UIntPtr]::Zero); Start-Sleep -Seconds 1
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
T "ALT+TAB (sair p/ clique)"; [W]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x09,0,2,[UIntPtr]::Zero); [W]::keybd_event(0x12,0,2,[UIntPtr]::Zero); Start-Sleep -Seconds 1
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
# Janela por cima (TOPMOST) SEM ativar (SWP_NOACTIVATE), para o clique cair nela sem foco.
[void][W]::SetWindowPos($h, [IntPtr](-1), 0, 0, 0, 0, 0x13); Start-Sleep -Milliseconds 300
T ("topmost sem ativar; foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))
$r = New-Object RECT; [void][W]::GetWindowRect($h, [ref]$r)
[void][W]::SetCursorPos([int](($r.L+$r.R)/2), [int](($r.T+$r.B)/2)); Start-Sleep -Milliseconds 200
T "CLIQUE na janela sem foco"; [W]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 60; [W]::mouse_event(4,0,0,0,[UIntPtr]::Zero); Start-Sleep -Seconds 1
T ("foreground_e_godot=" + ([W]::GetForegroundWindow() -eq $h))

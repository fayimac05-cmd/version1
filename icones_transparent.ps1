# Icones ScolarHub avec logo seul (fond transparent). A lancer depuis C:\ishaallah\version1
Add-Type -AssemblyName System.Drawing
$src = (Resolve-Path 'assets\images\logo_scolarhub.png').Path
$logo = [System.Drawing.Image]::FromFile($src)
$bm = New-Object System.Drawing.Bitmap $logo
$a = $bm.GetPixel(2, 2).A
"Logo source : $($logo.Width) x $($logo.Height) | opacite du coin haut-gauche : $a (0 = transparent)"
if ($a -gt 10) { "ATTENTION : le logo a un fond plein, il ne sera pas transparent. Il faut un fichier PNG sans fond." }
$bm.Dispose()

function Make($size, $pad, $out, $white) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  if ($white) { $g.Clear([System.Drawing.Color]::White) } else { $g.Clear([System.Drawing.Color]::Transparent) }
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.SmoothingMode = 'HighQuality'
  $g.PixelOffsetMode = 'HighQuality'
  $inner = [int]($size * (1 - 2 * $pad))
  $off = [int](($size - $inner) / 2)
  $g.DrawImage($logo, $off, $off, $inner, $inner)
  $g.Dispose()
  $full = Join-Path (Get-Location).Path $out
  New-Item -ItemType Directory -Force -Path (Split-Path $full) | Out-Null
  $bmp.Save($full, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  "{0}  ({1} px, {2} octets)" -f $out, $size, (Get-Item $full).Length
}

$res = 'android\app\src\main\res'
# Icones classiques (Android < 8), logo seul
Make 48 0.02 "$res\mipmap-mdpi\ic_launcher.png" $false
Make 72 0.02 "$res\mipmap-hdpi\ic_launcher.png" $false
Make 96 0.02 "$res\mipmap-xhdpi\ic_launcher.png" $false
Make 144 0.02 "$res\mipmap-xxhdpi\ic_launcher.png" $false
Make 192 0.02 "$res\mipmap-xxxhdpi\ic_launcher.png" $false
# Icone adaptative (Android 8+) : premier plan 108 dp, logo dans la zone sure
Make 108 0.17 "$res\mipmap-mdpi\ic_launcher_foreground.png" $false
Make 162 0.17 "$res\mipmap-hdpi\ic_launcher_foreground.png" $false
Make 216 0.17 "$res\mipmap-xhdpi\ic_launcher_foreground.png" $false
Make 324 0.17 "$res\mipmap-xxhdpi\ic_launcher_foreground.png" $false
Make 432 0.17 "$res\mipmap-xxxhdpi\ic_launcher_foreground.png" $false

$dir = Join-Path (Get-Location).Path "$res\mipmap-anydpi-v26"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$xml = '<?xml version="1.0" encoding="utf-8"?>' + "`r`n" +
'<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">' + "`r`n" +
'    <background android:drawable="@android:color/transparent"/>' + "`r`n" +
'    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>' + "`r`n" +
'</adaptive-icon>' + "`r`n"
[System.IO.File]::WriteAllText("$dir\ic_launcher.xml", $xml, (New-Object System.Text.UTF8Encoding $false))
"$res\mipmap-anydpi-v26\ic_launcher.xml cree"

# Web : logo seul, sauf les icones maskable (fond plein obligatoire)
Make 192 0.03 'web\icons\Icon-192.png' $false
Make 512 0.03 'web\icons\Icon-512.png' $false
Make 192 0.10 'web\icons\Icon-maskable-192.png' $true
Make 512 0.10 'web\icons\Icon-maskable-512.png' $true
Make 32 0.0 'web\favicon.png' $false
$logo.Dispose()
"Termine."

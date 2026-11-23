# Redimensionne le logo ScolarHub (fond blanc) pour Android et le web.
# A lancer depuis C:\ishaallah\version1
Add-Type -AssemblyName System.Drawing
$src = (Resolve-Path 'assets\images\logo_scolarhub.png').Path
$logo = [System.Drawing.Image]::FromFile($src)
"Logo source : $($logo.Width) x $($logo.Height)"

function Make($size, $pad, $out) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.SmoothingMode = 'HighQuality'
  $g.PixelOffsetMode = 'HighQuality'
  $inner = [int]($size * (1 - 2 * $pad))
  $off = [int](($size - $inner) / 2)
  $g.DrawImage($logo, $off, $off, $inner, $inner)
  $g.Dispose()
  $full = Join-Path (Get-Location).Path $out
  $bmp.Save($full, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  "{0}  ({1} px, {2} octets)" -f $out, $size, (Get-Item $full).Length
}

# Android : icone classique
$res = 'android\app\src\main\res'
Make 48  0.05 "$res\mipmap-mdpi\ic_launcher.png"
Make 72  0.05 "$res\mipmap-hdpi\ic_launcher.png"
Make 96  0.05 "$res\mipmap-xhdpi\ic_launcher.png"
Make 144 0.05 "$res\mipmap-xxhdpi\ic_launcher.png"
Make 192 0.05 "$res\mipmap-xxxhdpi\ic_launcher.png"

# Web : icones normales et "maskable" (marge de securite 10 %)
Make 192 0.05 'web\icons\Icon-192.png'
Make 512 0.05 'web\icons\Icon-512.png'
Make 192 0.10 'web\icons\Icon-maskable-192.png'
Make 512 0.10 'web\icons\Icon-maskable-512.png'
Make 32  0.02 'web\favicon.png'

$logo.Dispose()
"Termine."

# Icone Android ScolarHub : fond blanc + logo agrandi. A lancer depuis C:\ishaallah\version1
# (le web n'est pas touche : ses icones restent comme elles sont)
Add-Type -AssemblyName System.Drawing
$src = (Resolve-Path 'assets\images\logo_scolarhub.png').Path
$logo = [System.Drawing.Image]::FromFile($src)
"Logo source : $($logo.Width) x $($logo.Height)"

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
# Icones classiques (Android < 8) : fond blanc, logo grand
Make 48 0.06 "$res\mipmap-mdpi\ic_launcher.png" $true
Make 72 0.06 "$res\mipmap-hdpi\ic_launcher.png" $true
Make 96 0.06 "$res\mipmap-xhdpi\ic_launcher.png" $true
Make 144 0.06 "$res\mipmap-xxhdpi\ic_launcher.png" $true
Make 192 0.06 "$res\mipmap-xxxhdpi\ic_launcher.png" $true
# Icone adaptative (Android 8+) : premier plan transparent, logo plus grand (72 % au lieu de 66 %)
Make 108 0.14 "$res\mipmap-mdpi\ic_launcher_foreground.png" $false
Make 162 0.14 "$res\mipmap-hdpi\ic_launcher_foreground.png" $false
Make 216 0.14 "$res\mipmap-xhdpi\ic_launcher_foreground.png" $false
Make 324 0.14 "$res\mipmap-xxhdpi\ic_launcher_foreground.png" $false
Make 432 0.14 "$res\mipmap-xxxhdpi\ic_launcher_foreground.png" $false

$dir = Join-Path (Get-Location).Path "$res\mipmap-anydpi-v26"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$xml = '<?xml version="1.0" encoding="utf-8"?>' + "`r`n" +
'<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">' + "`r`n" +
'    <background android:drawable="@android:color/white"/>' + "`r`n" +
'    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>' + "`r`n" +
'</adaptive-icon>' + "`r`n"
[System.IO.File]::WriteAllText("$dir\ic_launcher.xml", $xml, (New-Object System.Text.UTF8Encoding $false))
"$res\mipmap-anydpi-v26\ic_launcher.xml cree (fond blanc)"
$logo.Dispose()
"Termine."

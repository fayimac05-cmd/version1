# icones_fond.ps1 — pose les icônes web sur un fond plein (au lieu de transparent)
# À lancer depuis la racine du projet :  powershell -ExecutionPolicy Bypass -File .\icones_fond.ps1
Add-Type -AssemblyName System.Drawing

$fond    = [Drawing.Color]::FromArgb(255, 248, 250, 254)   # #F8FAFE = background_color du manifeste
$dossier = Join-Path $PSScriptRoot 'web'
$sauv    = Join-Path $PSScriptRoot 'icones_originaux'       # copie des originaux (hors de web\)
New-Item -ItemType Directory -Force $sauv | Out-Null

$fichiers = @(
  'icons\Icon-192.png',
  'icons\Icon-512.png',
  'icons\Icon-maskable-192.png',
  'icons\Icon-maskable-512.png',
  'favicon.png'
)

foreach ($f in $fichiers) {
  $cible  = Join-Path $dossier $f
  $copie  = Join-Path $sauv (Split-Path $f -Leaf)
  if (-not (Test-Path $copie)) { Copy-Item $cible $copie }   # on ne sauvegarde qu'une fois

  # On repart toujours de l'original : le script peut être relancé sans danger.
  $src = [Drawing.Image]::FromFile($copie)
  $bmp = New-Object Drawing.Bitmap $src.Width, $src.Height, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.Clear($fond)
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($src, 0, 0, $src.Width, $src.Height)
  $g.Dispose(); $src.Dispose()

  $bmp.Save($cible, [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host "OK  $f"
}
Write-Host "Terminé. Originaux sauvegardés dans $sauv"

param([string]$Src = "$PSScriptRoot/../elite2-assets/base.png",
      [string]$Out = "$PSScriptRoot/../build/base-grid.png")
Add-Type -AssemblyName System.Drawing
$src = $Src
$out = $Out

$img = [System.Drawing.Image]::FromFile($src)
$canvas = New-Object System.Drawing.Bitmap $img.Width, $img.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 30, 30, 60))
$g.DrawImage($img, 0, 0)

$gridPen   = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 255, 0, 255)), 1
$majorPen  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 255, 200, 0)), 1
$font      = New-Object System.Drawing.Font 'Consolas', 9, ([System.Drawing.FontStyle]::Bold)
$brush     = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Magenta)

for ($x = 50; $x -lt $img.Width; $x += 50) {
    if ($x % 100 -eq 0) { $g.DrawLine($majorPen, $x, 0, $x, $img.Height) }
    else                { $g.DrawLine($gridPen,  $x, 0, $x, $img.Height) }
    $g.DrawString("$x", $font, $brush, ($x + 1), 1)
}
for ($y = 50; $y -lt $img.Height; $y += 50) {
    if ($y % 100 -eq 0) { $g.DrawLine($majorPen, 0, $y, $img.Width, $y) }
    else                { $g.DrawLine($gridPen,  0, $y, $img.Width, $y) }
    $g.DrawString("$y", $font, $brush, 1, ($y + 1))
}

$canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $canvas.Dispose(); $img.Dispose()
Write-Host "Wrote: $out"

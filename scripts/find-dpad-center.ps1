Add-Type -AssemblyName System.Drawing

# Load the original (black) base.png so we can find the d-pad cutout — it's a
# slightly-different-shaded interior circle in the lower-middle, distinct from
# the analog-stick cutouts (which are larger).
$src = "$PSScriptRoot/../source/elite2-assets/base.png"
$bmp = [System.Drawing.Bitmap]::FromFile($src)
$w = $bmp.Width; $h = $bmp.Height
Write-Host "base.png: $w x $h"

$rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
$data = $bmp.LockBits($rect,
    [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$bmp.UnlockBits($data)
$bmp.Dispose()

# Sample a horizontal strip at known d-pad latitudes; print luminance band.
# We expect the d-pad cutout to show as a darker/lighter circle vs body.
function PixelL([int]$x, [int]$y) {
    $i = $y * $stride + $x * 4
    $b = $bytes[$i]; $g = $bytes[$i+1]; $r = $bytes[$i+2]; $a = $bytes[$i+3]
    if ($a -lt 10) { return -1 }  # transparent
    return [int](($r + $g + $b) / 3)
}

# Walk every row in the lower-left-middle quadrant (where the d-pad lives),
# find connected pixel regions whose luminance differs noticeably from
# the controller body. Track the centroid of each candidate circular region.
$visited = New-Object 'bool[,]' $w, $h
$regions = @()

# Body luminance baseline: sample center area
$bodyL = PixelL 400 200
Write-Host "Body luminance sample at (400,200): $bodyL"

for ($y = 240; $y -lt 460; $y++) {
    for ($x = 100; $x -lt 500; $x++) {
        if ($visited[$x,$y]) { continue }
        $l = PixelL $x $y
        if ($l -lt 0) { continue }
        # Look for darker-than-body cutouts (Xbox stick/dpad cutouts are darker than body)
        if ([Math]::Abs($l - $bodyL) -lt 12) { continue }

        # Flood fill
        $stack = New-Object System.Collections.Stack
        $stack.Push(@($x, $y))
        $minX = $x; $maxX = $x; $minY = $y; $maxY = $y
        $count = 0
        while ($stack.Count -gt 0) {
            $p = $stack.Pop()
            $px = $p[0]; $py = $p[1]
            if ($px -lt 0 -or $py -lt 0 -or $px -ge $w -or $py -ge $h) { continue }
            if ($visited[$px,$py]) { continue }
            $pl = PixelL $px $py
            if ($pl -lt 0) { continue }
            if ([Math]::Abs($pl - $bodyL) -lt 12) { continue }
            $visited[$px,$py] = $true
            $count++
            if ($px -lt $minX) { $minX = $px }
            if ($px -gt $maxX) { $maxX = $px }
            if ($py -lt $minY) { $minY = $py }
            if ($py -gt $maxY) { $maxY = $py }
            $stack.Push(@($px+1,$py)); $stack.Push(@($px-1,$py))
            $stack.Push(@($px,$py+1)); $stack.Push(@($px,$py-1))
        }
        if ($count -gt 200) {
            $cx = [int](($minX + $maxX) / 2)
            $cy = [int](($minY + $maxY) / 2)
            $rw = $maxX - $minX
            $rh = $maxY - $minY
            $regions += [pscustomobject]@{
                CenterX = $cx; CenterY = $cy
                Width = $rw; Height = $rh
                Pixels = $count
                BBox = "($minX,$minY)-($maxX,$maxY)"
            }
        }
    }
}

Write-Host "`nRegions (darker than body) in dpad-search area:"
$regions | Sort-Object Pixels -Descending | Format-Table -AutoSize

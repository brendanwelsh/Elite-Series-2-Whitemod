param(
    [string]$Source = "$PSScriptRoot/../source/elite2-assets",
    [string]$Dest   = "$PSScriptRoot/../elite2-assets"
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest | Out-Null }

# Files to invert (black -> white; preserves alpha and internal contrast)
$invertList = @(
    'A.png','B.png','X.png','Y.png',
    'Start.png','Select.png',
    'Bumper Left.png','Bumper Right.png','Bumpers.png',
    'Trigger Left.png','Trigger Right.png','Triggers Left.png','triggers.png'
)

# Files to copy untouched (already correct on the white Core)
$copyList = @(
    'Stick Left.png','Stick Right.png',
    'dpad.png',
    'F-botleft.png','F-botright.png','F-mid.png','F-midbot.png',
    'F-midleft.png','F-midright.png','F-midtop.png',
    'F-topleft.png','F-topright.png'
)

function Save-Png {
    param([System.Drawing.Bitmap]$Bmp, [string]$Path)
    $Bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Invert-File {
    param([string]$In, [string]$Out)
    $bmp = [System.Drawing.Bitmap]::FromFile($In)
    $w = $bmp.Width; $h = $bmp.Height
    $rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
    $data = $bmp.LockBits($rect,
        [System.Drawing.Imaging.ImageLockMode]::ReadWrite,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    for ($y = 0; $y -lt $h; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $w; $x++) {
            $i = $row + $x * 4
            # BGRA order
            $bytes[$i]     = 255 - $bytes[$i]
            $bytes[$i + 1] = 255 - $bytes[$i + 1]
            $bytes[$i + 2] = 255 - $bytes[$i + 2]
            # alpha unchanged
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
    $bmp.UnlockBits($data)
    Save-Png $bmp $Out
    $bmp.Dispose()
}

# Polygon defining the WHITE BODY region of base.png (812x569).
# Pixels INSIDE this polygon get inverted (black -> white).
# Pixels OUTSIDE keep their original color (so the black diamond grips remain).
# Coordinates derived from the white Core silhouette; tune if needed.
$bodyPoly = @(
    @(150,   0),  @(660,   0),
    @(700,  80),
    @(720, 175),
    @(680, 275),
    @(615, 370),
    @(545, 460),
    @(480, 540),
    @(330, 540),
    @(270, 460),
    @(200, 370),
    @(133, 275),
    @( 95, 175),
    @(115,  80)
)

function Build-BodyMask {
    param([int]$W, [int]$H, [int[][]]$Poly)
    $mask = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($mask)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Black)
    $pts = New-Object 'System.Drawing.PointF[]' $Poly.Length
    for ($i = 0; $i -lt $Poly.Length; $i++) {
        $pts[$i] = New-Object System.Drawing.PointF $Poly[$i][0], $Poly[$i][1]
    }
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
    $g.Dispose()
    return $mask
}

function Invert-Masked {
    param([string]$In, [string]$Out, [int[][]]$Poly)
    $bmp = [System.Drawing.Bitmap]::FromFile($In)
    $w = $bmp.Width; $h = $bmp.Height
    $mask = Build-BodyMask -W $w -H $h -Poly $Poly

    $rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
    $bd = $bmp.LockBits($rect,
        [System.Drawing.Imaging.ImageLockMode]::ReadWrite,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $md = $mask.LockBits($rect,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    $stride = $bd.Stride
    $bytes  = New-Object byte[] ($stride * $h)
    $mbytes = New-Object byte[] ($md.Stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $bytes, 0, $bytes.Length)
    [System.Runtime.InteropServices.Marshal]::Copy($md.Scan0, $mbytes, 0, $mbytes.Length)

    for ($y = 0; $y -lt $h; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $w; $x++) {
            $i = $row + $x * 4
            # mask: white = body (invert), black = grip (keep)
            $m = $mbytes[$i]
            if ($m -gt 127) {
                $bytes[$i]     = 255 - $bytes[$i]
                $bytes[$i + 1] = 255 - $bytes[$i + 1]
                $bytes[$i + 2] = 255 - $bytes[$i + 2]
            }
        }
    }

    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $bd.Scan0, $bytes.Length)
    $bmp.UnlockBits($bd)
    $mask.UnlockBits($md)

    Save-Png $bmp $Out
    $bmp.Dispose()
    $mask.Dispose()
}

Write-Host "Recoloring assets..."

foreach ($f in $invertList) {
    $in = Join-Path $Source $f
    if (-not (Test-Path -LiteralPath $in)) { Write-Warning "Missing: $f"; continue }
    $out = Join-Path $Dest $f
    Write-Host "  invert  $f"
    Invert-File -In $in -Out $out
}

foreach ($f in $copyList) {
    $in = Join-Path $Source $f
    if (-not (Test-Path -LiteralPath $in)) { Write-Warning "Missing: $f"; continue }
    $out = Join-Path $Dest $f
    Write-Host "  copy    $f"
    Copy-Item -LiteralPath $in -Destination $out -Force
}

Write-Host "  mask    base.png"
Invert-Masked -In (Join-Path $Source 'base.png') -Out (Join-Path $Dest 'base.png') -Poly $bodyPoly
Write-Host "  mask    base-disconnect.png"
Invert-Masked -In (Join-Path $Source 'base-disconnect.png') -Out (Join-Path $Dest 'base-disconnect.png') -Poly $bodyPoly

Write-Host "Done. Output: $Dest"

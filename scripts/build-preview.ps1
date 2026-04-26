param(
    [string]$AssetDir = "$PSScriptRoot/../elite2-assets",
    [string]$Out = "$PSScriptRoot/../preview.png"
)

Add-Type -AssemblyName System.Drawing

# Replicate the CSS layout: 812x569 base, with overlays positioned per elite2.css
$canvas = New-Object System.Drawing.Bitmap 812, 569, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Transparent)

function Draw-Asset {
    param([string]$Name, [int]$X, [int]$Y, [int]$W = 0, [int]$H = 0)
    $path = Join-Path $AssetDir $Name
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "Missing: $Name"; return }
    $img = [System.Drawing.Image]::FromFile($path)
    if ($W -le 0) { $W = $img.Width }
    if ($H -le 0) { $H = $img.Height }
    $g.DrawImage($img, $X, $Y, $W, $H)
    $img.Dispose()
}

# Base (anchors the canvas)
Draw-Asset 'base.png' 0 0

# Triggers — .triggers div: left=129, top=-80, w=558 h=65; .trigger w=86 h=95
# trigger.left floats left at (129, -80). Negative Y goes off-canvas in CSS,
# but for the preview we clip to canvas, so place at top.
Draw-Asset 'Trigger Left.png'  129 0 86 95
Draw-Asset 'Trigger Right.png' (129 + 558 - 86) 0 86 95

# Bumpers — .bumpers: left=120, w=571 h=71; .bumper w=177 h=71
# (top isn't set in source CSS; effectively 0 inside the parent)
Draw-Asset 'Bumper Left.png'  120 0 177 71
Draw-Asset 'Bumper Right.png' (120 + 571 - 177) 0 177 71

# Sticks — .sticks: top=110, left=147, w=422 h=220; stick 94x92
# left stick: top=0, left=0; right stick: bottom-right of container
Draw-Asset 'Stick Left.png'  147 110 94 92
Draw-Asset 'Stick Right.png' (147 + 422 - 101) (110 + 220 - 96) 94 92

# ABXY — .abxy: top=75, left=532, w=172 h=168; button 59x59
# A: top 110, left 57   -> (532+57, 75+110)
# B: top 57,  right 0   -> (532 + 172 - 59, 75+57)
# X: top 55, left 0     -> (532, 75+55)
# Y: top 0,  left 58    -> (532+58, 75)
Draw-Asset 'A.png' (532+57) (75+110) 59 59
Draw-Asset 'B.png' (532 + 172 - 59) (75+57) 59 59
Draw-Asset 'X.png' 532 (75+55) 59 59
Draw-Asset 'Y.png' (532+58) 75 59 59

# Arrows (start/back) — .arrows: top=138, left=327, w=157 h=39
# back: 38x36, float left;  start: 36x36, float right
Draw-Asset 'Start.png' 327 138 38 36
Draw-Asset 'Select.png' (327 + 157 - 36) 138 36 36

# D-pad — .dpad: top=279, left=205, w=140 h=132. dpad.png is 136x135 centered.
Draw-Asset 'dpad.png' (205 + (140 - 136) / 2) (279 + (132 - 135) / 2) 136 135

$g.Dispose()
$canvas.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Host "Preview written: $Out"

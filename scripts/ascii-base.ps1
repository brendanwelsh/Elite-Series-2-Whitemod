Add-Type -AssemblyName System.Drawing
$src = "$PSScriptRoot/../source/elite2-assets/base.png"
$bmp = [System.Drawing.Bitmap]::FromFile($src)
$w = $bmp.Width; $h = $bmp.Height

# Down-sample by 8x to make a readable ASCII grid: 812/8=101, 569/8=71
$step = 8
$cols = [Math]::Floor($w / $step)
$rows = [Math]::Floor($h / $step)

$rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
$d = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $d.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $bytes, 0, $bytes.Length)
$bmp.UnlockBits($d)
$bmp.Dispose()

# Header: column index every 10 cells
$header = '    '
for ($c = 0; $c -lt $cols; $c++) {
    if ($c % 10 -eq 0) { $header += ($c.ToString().PadLeft(2).Substring(0,1)) }
    elseif ($c % 10 -eq 5) { $header += '.' }
    else { $header += ' ' }
}
Write-Output $header
Write-Output ('    ' + ('-' * $cols))

for ($r = 0; $r -lt $rows; $r++) {
    $y = $r * $step
    $line = ($r.ToString().PadLeft(2)) + ': '
    for ($c = 0; $c -lt $cols; $c++) {
        $x = $c * $step
        $i = $y * $stride + $x * 4
        $a = $bytes[$i+3]
        if ($a -lt 30) { $line += ' '; continue }
        $b = $bytes[$i]; $g = $bytes[$i+1]; $rr = $bytes[$i+2]
        $L = ($rr + $g + $b) / 3
        # Map luminance: low=#, mid=*, high=. (relative to base black ~10-30)
        if ($L -lt 5)        { $line += '#' }
        elseif ($L -lt 20)   { $line += '*' }
        elseif ($L -lt 50)   { $line += '+' }
        elseif ($L -lt 100)  { $line += '-' }
        else                 { $line += '.' }
    }
    Write-Output $line
}
Write-Output ""
Write-Output "Each column = $step px, each row = $step px"
Write-Output "So column N starts at x = N * $step, row N starts at y = N * $step"

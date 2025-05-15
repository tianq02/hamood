param (
    [Parameter(Position=0)][ValidateRange(1,100)][int64]$p = 6,
    [Parameter(Position=1)][ValidateRange(0,1)][int64]$Style = 1
)
Write-Host "PowerMod table for $p"
Write-Host "------------------------"
if ($Style -eq 0) {
    for ($i=1; $i -lt $p; $i++) {
        for ($j=1; $j -lt $p; $j++) {
            $ans = PowerMod $j $i $p
            Write-Host -NoNewline "$j^$i%$p=$ans`t"
        }
        Write-Host ""
    }
}
else {
    Write-Host -NoNewline -ForegroundColor Red "p\b`t"
    for ($i=1; $i -lt $p; $i++) {
        Write-Host -NoNewline -ForegroundColor Red "$i`t"
    }
    Write-Host ""
    for ($i=1; $i -lt $p; $i++) {
        Write-Host -NoNewline -ForegroundColor Red "$i`t"
        for ($j=1; $j -lt $p; $j++) {
            $ans = PowerMod $j $i $p
            Write-Host -NoNewline "$ans`t"
        }
        Write-Host ""
    }
}


function PowerMod {
    param (
        [Parameter(Position=0, Mandatory=$true)][ValidateRange([int64]::MinValue, [int64]::MaxValue)][int64]$Base,
        [Parameter(Position=1, Mandatory=$true)][ValidateRange(0, [int64]::MaxValue)][int64]$Power,
        [Parameter(Position=2, Mandatory=$true)][ValidateRange(1, [int64]::MaxValue)][int64]$Mod
    )
    [int64]$ans = 1
    for ([int64]$i=1; $i -le $Power; $i++) {
        $ans = $ans * $Base % $Mod
    }
    return $ans
}
param (
    # 定义参数 p，表示模数，范围为 1 到 100, 后续演示使用模p乘法群
    # 推荐尝试7(素数),8(合数),13(嵌套子群),23(安全素数)
    [Parameter(Position=0)][ValidateRange(1,100)][int64]$p = 7
)
Write-Host "PowerMod table for $p"
Write-Host "------------------------"
Write-Host -NoNewline -ForegroundColor Red "b\p`t"
for ($i=[int64]1; $i -lt $p; $i++) {
    Write-Host -NoNewline -ForegroundColor Red "$i`t"
}
Write-Host "ord"

# 初始化哈希表用于存储各元素的阶(ord)
# ord 是指一个元素在模p乘法群中的阶，即最小的正整数 k，使得 a^k ≡ 1 (mod p) 
$ordGroups = @{}

for ($i=[int64]1; $i -lt $p; $i++) {
    Write-Host -NoNewline -ForegroundColor Red "$i`t"
    $ans = [int64]$i
    $ord = $null
    for ($j=[int64]1; $j -lt $p; $j++) {
        if ($ans -eq 1 -and $null -eq $ord) {
            $ord = [int64]$j
            # 如果 ans 等于 1，表示当前元素的阶已经找到
            # 这些元素是生成元
            Write-Host -NoNewline -ForegroundColor Green "1($i)*`t"
        }                 
        elseif ($ans -eq 1) {
            # 这些元素在也在群中，但不是生成元
            Write-Host -NoNewline -ForegroundColor Green "1($i)`t"
        } else {
            Write-Host -NoNewline "$ans`t"
        }
        $ans = [int64]($ans * $i % $p)
    }
    if ($null -ne $ord) {
        Write-Host "$ord"
        # 将元素(行号i)与其阶(ord)存入哈希表
        if (-not $ordGroups.ContainsKey([int64]$ord)) {
            $ordGroups[[int64]$ord] = @()
        }
        $ordGroups[[int64]$ord] += [int64]$i
    } else {
        Write-Host "N/A"
    }
}

# 输出各子群的元素
Write-Host "`nSubgroups:"   
foreach ($key in $ordGroups.Keys) {
    Write-Host "ord = $key, Count = $($ordGroups[$key].Count), Member = {$($ordGroups[$key] -join ', ')}"
}

if ($ordGroups.ContainsKey([int64]($p-1))) {
    Write-Host "Hooray! $p is a prime number!"
}
else {
    Write-Host "Oops! $p is not a prime number!"
}

# 如何阅读程序输出
# 1. 第一行是模数 p
# 2. 第一列是底数 base (即元素的值，行号)，
# 3. 后续各列是该元素的幂次结果 (base^power mod p)
# 4. 最后一列是元素的阶 ord（最小正整数 k 使得 base^k ≡ 1 mod p）
# 5. 若 ord = p-1，该元素是模p乘法群的生成元（原根），此时p是素数
# 6. 若 ord < p-1，该元素生成一个阶为 ord 的子群
# 7. 若 ord = N/A，该元素不属于模p乘法群（与p不互质），此时p是合数
#
# 小技巧
# 1. 同一行的元素构成以该行号为生成元的子群
# 2. 同一列的各1属于同一子群，带*号的元素是该子群的生成元，不带*号的元素属于嵌套子群
# 3. 一列里除单位元所有的1都带*号，则该子群是个素数阶子群。DH的参数选取自阶最大的素数阶子群
#    例如，p=23，有2阶和11阶的素数阶子群，从11阶子群中选取一个元素作为DH的参数（安全素数，防御Pohlig-Hellman攻击）

param (
    # 定义参数 modP, 表示模数, 范围为 2 到 100, 后续演示使用模p乘法群
    # 推荐尝试7(素数),8(合数),13(嵌套子群),23(安全素数),97(极端不安全)
    [Parameter(Position=0)][ValidateRange(2,100)][int64]$modP = 7,
    [Parameter(Position=1)][ValidateRange(2,200)][int64]$maxPow = 0
)
if ($maxPow -eq 0) {
    # 如果没有指定最大幂次, 则默认使用模数 modP -1 作为最大幂次
    # modP为素数时，这样刚好能看到最后一列全是1，说明所有元素都属于模p乘法群
    $maxPow = $modP - 1
}

Write-Host "PowerMod table for $modP"
Write-Host "------------------------"
Write-Host -NoNewline -ForegroundColor Red "b\modP`t"
for ($i=[int64]1; $i -le $maxPow; $i++) {
    Write-Host -NoNewline -ForegroundColor Red "$i`t"
}
Write-Host "ord"

# 初始化哈希表用于存储各元素的阶(ord)
# ord 是指一个元素在模p乘法群中的阶, 即最小的正整数 k, 使得 a^k ≡ 1 (mod modP) 
$ordGroups = @{} # 群的阶-群中元素的值, 哈希表，群中的元素的阶未必等于群的阶
$ordElements = @{} # 元素的阶-元素的值, 哈希表

for ($i=[int64]1; $i -lt $modP; $i++) {
    Write-Host -NoNewline -ForegroundColor Red "$i`t"
    $ans = [int64]$i # 从一次幂开始
    $ord = $null # 元素的阶

    # 计算i的各次幂
    for ($j=[int64]1; $j -le $maxPow; $j++) {
        if ($ans -eq 1) {
            if ($null -eq $ord) {
                # 如果 ans 等于 1, 表示当前元素的阶已经找到
                # 元素的阶为j, 是j阶子群的生成元
                Write-Host -NoNewline -ForegroundColor Green "1($i)*`t"
                $ord = $j
                # 元素i的阶为j, 将{j:i}存入哈希表
                if (-not $ordElements.ContainsKey([int64]$ord)) {
                    $ordElements[[int64]$ord] = @()
                }
                $ordElements[[int64]$ord] += [int64]$i
            } else {
                # 这些元素在也在j阶的子群中, 但不是生成元, 元素的阶是j的因数，此处是嵌套子群
                Write-Host -NoNewline -ForegroundColor Green "1($i)`t"
            }
            # FIXME: 简单收集属于j阶群的元素是不可靠的，直接在乘幂的部分收集更合适，下面的代码应该弃用
            # 不过，由于子群分析部分根本不考虑模为合数的情况，利用同阶子群的唯一性，现在这种实现也不会出现问题
            # 元素i的j次幂为1，说明j阶子群包含元素i, 将{j:i}存入哈希表
            if (-not $ordGroups.ContainsKey([int64]$j)) {
                $ordGroups[[int64]$j] = @()
            }
            $ordGroups[[int64]$j] += [int64]$i
        } else {
            Write-Host -NoNewline "$ans`t"
        }
        # 计算 ans = (ans * i) % modP
        $ans = ($ans * [int64]$i) % $modP
    }
    if ($null -ne $ord) {
        Write-Host "$ord"
    } else {
        Write-Host "N/A"
    }
}

# 存在p-1阶的子群, 说明p的欧拉函数值φ(modP) = p-1, p是素数
if ($ordElements.ContainsKey([int64]($modP-1))) {
    # 对于安全素数p, p-1 = 2q, q是素数, 
    # 此时模p乘法群的阶p-1只有两个因数2和q
    # 子群数量为4, 分别是1阶、2阶、q阶和2q阶
    # 此处以子群数量为4来判断是否是安全素数
    if ($ordElements.Count -eq 4) {
        Write-Host "`nHooray! $modP is a prime number! A safe prime!"
    } else {
        Write-Host "`nHooray! $modP is a prime number!"
    }
}
else {
    Write-Host "`nOops! $modP is not a prime number! Subgroup analysis is not available.`n"
    # 对于一个合数p, 模p乘法群的阶比p-1小得多
    # 我们需要过滤掉那些不属于群的元素(与p不互质)
    # 此外, 具有相同阶的成员不一定属于同一个子群
    # 说到底该群可能根本不是循环群, 子群分析也就没意义了
    return
}

# 基于生成元遍历，输出各子群的元素
Write-Host "`nSubgroups:"
$found = $false
foreach ($key in ($ordElements.Keys | Sort-Object -Descending)) {
    # 将生成元标记为带*号的元素
    $members = $ordGroups[$key] | ForEach-Object {
        if ($ordElements[$key] -contains $_) {
            "*$_"
        } else {
            " $_"
        }
    }
    Write-Host "ord = $key, gen = $($ordElements[$key].Count), Member = {$($members -join ', ') }"
    if ($ordGroups[$key].Count -eq $ordElements[$key].Count + 1) {
        if ($found) {
            Write-Host "  * Prime order subgroup.`n"
        } else {
            Write-Host "  * Largest prime order subgroup. Pick DH parameter here.`n"
            $found = $true
        }
    } elseif ($key -ne 1) {
        Write-Host "  * Composite order subgroup.`n"
    } else {
        Write-Host "  * Trivial subgroup.`n"
    }
}

# 如何阅读程序输出
# 1. 第一行是模数 modP
# 2. 第一列是底数 base (即元素的值, 行号), 
# 3. 后续各列是该元素的幂次结果 (base^power mod modP)
# 4. 最后一列是元素的阶 ord（最小正整数 k 使得 base^k ≡ 1 mod p）
# 5. 若 ord = p-1, 该元素是模p乘法群的生成元（原根）, 此时p是素数
# 6. 若 ord < p-1, 该元素生成一个阶为 ord 的子群
# 7. 若 ord = N/A, 该元素不属于模p乘法群（与p不互质）, 此时p是合数
#
# 小技巧
# 1. 同一行的元素构成以该行号为生成元的子群
# 2. 同一列的各1属于同一子群, 带*号的元素是该子群的生成元, 不带*号的元素属于嵌套子群
# 3. 一列里除单位元所有的1都带*号, 则该子群是个素数阶子群。DH的参数选取自阶最大的素数阶子群
#    例如, modP=23, 有2阶和11阶的素数阶子群, 从11阶子群中选取一个元素作为DH的参数（安全素数, 防御Pohlig-Hellman攻击）

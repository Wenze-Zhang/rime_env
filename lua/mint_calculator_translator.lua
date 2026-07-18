-- author: https://github.com/ChaosAlphard
-- notes see rime-shuangpin-fuzhuma pull 41

-- modified: Mintimate
-- based on wanxiang super_calculator changes 1 mint default style 2 renamed some functions

-- original features
-- single random number trig power exponential logarithm evaluation
-- nth root mean variance factorial degree radian conversion

-- added features
-- solve linear equations linear systems quadratic cubic quartic equations
-- solve linear and quadratic function expressions and circle equations
-- ceiling floor and modulo functions
-- general term from any two sequence items and partial sums arithmetic or geometric
-- triangle area from three sides and regular polygon area from n and a
-- relation of two lines with distance or intersection point to point and point to line distance
-- perpendicular bisector of a segment and point rotation around a point
-- combinations permutations gcd lcm
-- reflection of a point across a line and of a line across a line or point
-- power sums of consecutive naturals squares cubes fourth powers also for odd and even numbers
-- pythagorean triples batch random numbers prime factorization prime finding
-- 24 points calculator a small game
-- common unit conversion and number base conversion

-- function key list
-- cb = cubes sum of naturals from 1
-- fp = fourth powers sum of naturals from 1
-- sq = squares sum of naturals from 1
-- tx = general term from two items ai ak with indexes i k
-- avg = mean
-- cos = cosine
-- deg = radians to degrees
-- dds = quadratic expression from vertex form
-- dxf = linear expression from point and slope
-- ecb = cubes sum of first n even numbers
-- efp = fourth powers sum of first n even numbers
-- esq = squares sum of first n even numbers
-- exp = returns e^x
-- gbs = lcm of several numbers
-- ggs = pythagorean triples
-- gys = gcd of several numbers
-- hls = determinant
-- ldf = linear expression from two points
-- ld1 = distance between two points
-- ld2 = perpendicular bisector of segment between two points
-- ld3 = coordinates of P rotated around Q by angle a in degrees
-- log = logarithm base x
-- mod = modulo
-- ocb = cubes sum of first n odd numbers
-- ofp = fourth powers sum of first n odd numbers
-- osq = squares sum of first n odd numbers
-- pls = permutations
-- rad = degrees to radians
-- sin = sine
-- sjs = random number
-- tan = tangent
-- tfp = 24 points calculator
-- var = variance
-- ybs = quadratic expression from general form
-- zhs = combinations
-- zys = prime factorization
-- zzs = find primes
-- acos = arccosine
-- asin = arcsine
-- atan = arctangent
-- cesd = circle equation from three points on it
-- cexl = circle equation from center and two points on it
-- cexr = circle equation from center and radius
-- cosh = hyperbolic cosine
-- dbsl = partial sum of geometric sequence from a1 and q
-- dcsl = partial sum of arithmetic sequence from a1 and d
-- dwhs = unit conversion area mass length volume as number oldunit newunit
-- eyyc = solve system ax+by=e cx+dy=f
-- fact = factorial
-- lzx1 = relation of lines A1x+B1y+C1=0 and A2x+B2y+C2=0
-- lzx2 = reflections of two lines across each other
-- loge = natural logarithm
-- logt = logarithm base 10
-- jzzh = base conversion bases 2 to 36 as number frombase tobase
-- psjs = batch random numbers
-- sinh = hyperbolic sine
-- sjxx = triangle centers from three vertexes
-- sjx1 = triangle area from sides a b c
-- sjx2 = triangle area from three vertexes
-- sqrt = square root or imaginary root of x
-- tanh = hyperbolic tangent
-- tcr1 = relation of two circles in standard form
-- tcr2 = relation of two circles in general form
-- yyec = solve quadratic equation
-- yyyc = solve linear equation
-- xsqz = ceiling
-- xxqz = floor
-- zdbx = regular polygon area from n and a
-- atan2 = ccw angle in radians of point x y from x axis
-- dyzx1 = distance and reflection of a point across line Ax+By+C=0
-- dyzx2 = reflection of line l across point P
-- ldexp = returns x*2^y
-- nroot = nth root of x
-- sjxy1 = inradius and circumradius from three sides
-- sjxy2 = inradius and circumradius from three vertexes
-- yysc1 = solve cubic equation
-- yysc2 = solve quartic equation


local T = {}

function T.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    local _calc_pat = config:get_string("recognizer/patterns/expression") or nil
    T.prefix = _calc_pat and _calc_pat:match("%^.?([a-zA-Z/=]+).*") or "V"
    T.tips = config:get_string("calculator/tips") or "计算器"
end

local function startsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

-- function table
local calc_methods = {
    -- e, exp(1) = e^1 = e
    e = math.exp(1),
    -- π
    pi = math.pi,
    b = 10 ^ 2,
    q = 10 ^ 3,
    k = 10 ^ 3,
    w = 10 ^ 4,
    tw = 10 ^ 5,
    m = 10 ^ 6,
    tm = 10 ^ 7,
    y = 10 ^ 8,
    g = 10 ^ 9
}

local methods_desc = {
    ["e"] = "自然常数, 欧拉数",
    ["pi"] = "圆周率 π",
    ["b"] = "百",
    ["q"] = "千",
    ["k"] = "千",
    ["w"] = "万",
    ["tw"] = "十万",
    ["m"] = "百万",
    ["tm"] = "千万",
    ["y"] = "亿",
    ["g"] = "十亿"
}

-- perform the calculation
local function replaceToFactorial(str)
    return str:gsub("([0-9]+)!", "fact(%1)")
end

-- keep significant digits returns number
local function fn(n)
    -- convert number to string for processing
    local s = tostring(n)
    -- find decimal point position
    local i = string.find(s, "%.")
    if i == nil then
        -- no decimal point return as is
        return n
    end
    -- strip trailing zeros after decimal point
    local j = string.len(s)
    while j > i and string.sub(s, j, j) == "0" do
        j = j - 1
    end
    -- remove decimal point when nothing follows
    if j == i then
        -- return integer part
        return tonumber(string.sub(s, 1, i - 1))
    else
        -- otherwise return processed number
        return tonumber(string.sub(s, 1, j))
    end
end

-- keep significant digits returns string
local function fs(n)
    -- convert number to string for processing
    local s = tostring(n)
    -- find decimal point position
    local i = string.find(s, "%.")
    if i == nil then
        -- no decimal point return as is
        return n
    end
    -- strip trailing zeros after decimal point
    local j = string.len(s)
    while j > i and string.sub(s, j, j) == "0" do
        j = j - 1
    end
    -- remove decimal point when nothing follows
    if j == i then
        -- return integer part
        return string.sub(s, 1, i - 1)
    else
        -- otherwise return processed number
        return string.sub(s, 1, j)
    end
end

-- ceiling function
local function ceil(x)
    return math.ceil(x)
end
calc_methods["xsqz"] = ceil
methods_desc["xsqz"] = "向上取整"

-- floor function
local function floor(x)
    return math.floor(x)
end
calc_methods["xxqz"] = floor
methods_desc["xxqz"] = "向下取整"

-- round to n decimal places
local function round(m, n)
    local factor = 10 ^ n
    return floor(m * factor + 0.5) / factor
end

-- gcd of two numbers
local function gcd(a, b)
    while b ~= 0 do
        local temp = b
        b = a % b
        a = temp
    end
    return a
end

-- gcd of several numbers
local function gcd_multiple(...)
    local nums, result
    nums = { ... }
    result = nums[1]
    for i = 2, #nums do
        result = gcd(result, nums[i])
    end
    return fn(result)
end
calc_methods["gys"] = gcd_multiple
methods_desc["gys"] = "计算多个数的最大公因数"

-- lcm of two numbers
local function lcm(a, b)
    return a * b / gcd(a, b)
end

-- lcm of several numbers
local function lcm_multiple(...)
    local nums, result
    nums = { ... }
    result = nums[1]
    for i = 2, #nums do
        result = lcm(result, nums[i])
    end
    return fn(result)
end
calc_methods["gbs"] = lcm_multiple
methods_desc["gbs"] = "计算多个数的最小公倍数"

-- random m n gives m to n only m gives 1 to m none gives 0 to 1
local function random(...)
    return math.random(...)
end
-- register in function table
calc_methods["sjs"] = random
methods_desc["sjs"] = "随机数"
-- register in function table
calc_methods["random"] = random
methods_desc["random"] = "随机数"

-- nth root
local function nth_root(x, n)
    if n % 2 == 0 and x < 0 then
        return nil -- no real solution for negative with even n
    elseif x < 0 then
        return -((-x) ^ (1 / n))
    else
        return x ^ (1 / n)
    end
end
calc_methods["nroot"] = nth_root
methods_desc["nroot"] = "计算 x 开 N 次方"

-- sine
local function sin(x)
    return math.sin(x)
end
calc_methods["sin"] = sin
methods_desc["sin"] = "正弦"

-- hyperbolic sine
local function sinh(x)
    return (math.exp(x) - math.exp(-x)) / 2
end
calc_methods["sinh"] = sinh
methods_desc["sinh"] = "双曲正弦"

-- arcsine
local function asin(x)
    return math.asin(x)
end
calc_methods["asin"] = asin
methods_desc["asin"] = "反正弦"

-- cosine
local function cos(x)
    return math.cos(x)
end
calc_methods["cos"] = cos
methods_desc["cos"] = "余弦"

-- hyperbolic cosine
local function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end
calc_methods["cosh"] = cosh
methods_desc["cosh"] = "双曲余弦"

-- arccosine
local function acos(x)
    return math.acos(x)
end
calc_methods["acos"] = acos
methods_desc["acos"] = "反余弦"

-- tangent
local function tan(x)
    return math.tan(x)
end
calc_methods["tan"] = tan
methods_desc["tan"] = "正切"

-- hyperbolic tangent
local function tanh(x)
    local e = math.exp(2 * x)
    return (e - 1) / (e + 1)
end
calc_methods["tanh"] = tanh
methods_desc["tanh"] = "双曲正切"

-- arctangent
local function atan(x)
    return math.atan(x)
end
calc_methods["atan"] = atan
methods_desc["atan"] = "反正切"

-- ccw angle in radians of point x y from the x axis
-- range from -pi to pi negative means downward positive upward
-- better defined than math.atan of y over x handles x equals 0
local function atan2(y, x)
    if x == 0 and y == 0 then
        return 0 / 0 -- return NaN
    elseif x == 0 and y ~= 0 then
        if y > 0 then
            return math.pi / 2
        else
            return -math.pi / 2
        end
    else
        return math.atan(y / x) + (x < 0 and math.pi or 0)
    end
end
calc_methods["atan2"] = atan2
methods_desc["atan2"] = "返回以弧度为单位的点(x,y)相对于x轴的逆时针角度"

-- radians to degrees
local function deg(x)
    return math.deg(x)
end
calc_methods["deg"] = deg
methods_desc["deg"] = "弧度转换为角度"

-- degrees to radians
local function rad(x)
    return math.rad(x)
end
calc_methods["rad"] = rad
methods_desc["rad"] = "角度转换为弧度"

-- returns x*2^y
local function ldexp(x, y)
    return x * 2 ^ y
end
calc_methods["ldexp"] = ldexp
methods_desc["ldexp"] = "返回 x*2^y"

-- returns e^x
local function exp(x)
    -- validate arguments
    if type(x) ~= "number" then
        return "参数必须是数字"
    end
    return math.exp(x)
end
calc_methods["exp"] = exp
methods_desc["exp"] = "返回 e^x"

-- square root when x>=0 imaginary root when x<0
local function sqrt(x)
    -- validate arguments
    if type(x) ~= "number" then
        return "参数必须是数字"
    end
    local s
    if x < 0 and x ~= -1 then
        s = fn(math.sqrt(-x))
        return "±" .. s .. "i"
    elseif x == -1 then
        return "±i"
    elseif x == 0 then
        return 0
    else
        s = fn(math.sqrt(x))
        return "±" .. s
    end
end
calc_methods["sqrt"] = sqrt
methods_desc["sqrt"] = "计算x平方根或虚根"

-- logarithm base x log 10 100 equals 2
local function log(x, y)
    -- must be positive
    if x <= 0 or y <= 0 then
        return nil
    end
    return math.log(y) / math.log(x)
end
calc_methods["log"] = log
methods_desc["log"] = "x作为底数的对数"

-- natural logarithm
local function loge(x)
    -- must be positive
    if x <= 0 then
        return nil
    end
    return math.log(x)
end
calc_methods["loge"] = loge
methods_desc["loge"] = "e作为底数的对数"

-- logarithm base 10
local function logt(x)
    -- must be positive
    if x <= 0 then
        return nil
    end
    return math.log(x) / math.log(10)
end
calc_methods["logt"] = logt
methods_desc["logt"] = "10作为底数的对数"

-- mean
local function avg(...)
    local data, n, sum
    data = { ... }
    n = #data
    sum = 0
    -- sample count must not be 0
    if n == 0 then
        return nil
    end
    -- compute sum
    for _, value in ipairs(data) do
        sum = sum + value
    end
    return fn(sum / n)
end
calc_methods["avg"] = avg
methods_desc["avg"] = "平均值"

-- variance
local function variance(...)
    local data, n, sum, mean, sum_squared_diff
    data = { ... }
    n = #data
    sum = 0
    sum_squared_diff = 0
    -- sample count must not be 0
    if n == 0 then
        return nil
    end
    -- compute mean
    for _, value in ipairs(data) do
        sum = sum + value
    end
    mean = sum / n
    -- compute variance
    for _, value in ipairs(data) do
        sum_squared_diff = sum_squared_diff + (value - mean) ^ 2
    end
    return fn(sum_squared_diff / n)
end
calc_methods["var"] = variance
methods_desc["var"] = "方差"

-- factorial
local function factorial(x)
    -- must not be negative
    if x < 0 then
        return nil
    elseif x == 0 or x == 1 then
        return 1
    end
    local result = 1
    for i = 1, x do
        result = result * i
    end
    return fn(result)
end
calc_methods["fact"] = factorial
methods_desc["fact"] = "阶乘"

-- determinant
local function hls(...)
    local args, n1, sqrt_n, matrix, index, side_length
    args = { ... }
    n1 = #args
    sqrt_n = math.sqrt(n1)
    -- when count is a perfect square arrange elements into a matrix
    if sqrt_n == math.floor(sqrt_n) then
        matrix = {}
        index = 1
        side_length = math.floor(sqrt_n)
        for i = 1, side_length do
            matrix[i] = {}
            for j = 1, side_length do
                matrix[i][j] = args[index]
                index = index + 1
            end
        end
    else
        return "给出的元素不能组成一个方阵。"
    end
    -- recursive determinant function
    local function determinant(matrix)
        local n, det, sign, row, sub_matrix
        n = #matrix
        det = 0
        -- base case two by two determinant
        if n == 2 then
            return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
        end
        -- recursive expansion
        for j = 1, n do
            sub_matrix = {}
            for i = 2, n do
                row = {}
                for k = 1, n do
                    if k ~= j then
                        table.insert(row, matrix[i][k])
                    end
                end
                table.insert(sub_matrix, row)
            end
            sign = (-1) ^ (1 + j)
            det = det + sign * matrix[1][j] * determinant(sub_matrix)
        end
        return fn(det)
    end
    return determinant(matrix)
end
calc_methods["hls"] = hls
methods_desc["hls"] = "计算行列式"

-- modulo function
local function remainder(x, y)
    -- use math.fmod for remainder
    local result = math.fmod(x, y)
    -- adjust negative results to positive
    if result < 0 then
        result = result + y
    end
    return fn(result)
end
calc_methods["mod"] = remainder
methods_desc["mod"] = "求余函数"

-- squares sum of naturals from 1
local function sum_of_squares(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute squares sum
    local result = n * (n + 1) * (2 * n + 1) / 6
    return fn(result)
end
calc_methods["sq"] = sum_of_squares
methods_desc["sq"] = "连续自然数平方和(从1开始)"

-- cubes sum of naturals from 1
local function sum_of_cubes(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute cubes sum
    local result = (n * (n + 1)) ^ 2 / 4
    return fn(result)
end
calc_methods["cb"] = sum_of_cubes
methods_desc["cb"] = "连续自然数立方和(从1开始)"

-- fourth powers sum of naturals from 1
local function sum_of_fourth_powers(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute fourth powers sum
    local result = n * (n + 1) * (2 * n + 1) * (3 * n ^ 2 + 3 * n - 1) / 30
    return fn(result)
end
calc_methods["fp"] = sum_of_fourth_powers
methods_desc["fp"] = "连续自然数4次方之和(从1开始)"

-- squares sum of first n odd numbers
local function sum_of_odd_squares(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute squares sum
    local result = n * (4 * n ^ 2 - 1) / 3
    return fn(result)
end
calc_methods["osq"] = sum_of_odd_squares
methods_desc["osq"] = "前n个奇数的平方和"

-- squares sum of first n even numbers
local function sum_of_even_squares(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute squares sum
    local result = 2 * n * (n + 1) * (2 * n + 1) / 3
    return fn(result)
end
calc_methods["esq"] = sum_of_even_squares
methods_desc["esq"] = "前n个偶数的平方和"

-- cubes sum of first n odd numbers
local function sum_of_odd_cubes(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute cubes sum
    local result = n ^ 2 * (2 * n ^ 2 - 1)
    return fn(result)
end
calc_methods["ocb"] = sum_of_odd_cubes
methods_desc["ocb"] = "前n个奇数的立方和"

-- cubes sum of first n even numbers
local function sum_of_even_cubes(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute cubes sum
    local result = 2 * (n * (n + 1)) ^ 2
    return fn(result)
end
calc_methods["ecb"] = sum_of_even_cubes
methods_desc["ecb"] = "前n个偶数的立方和"

-- fourth powers sum of first n odd numbers
local function sum_of_odd_fourth_powers(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute fourth powers sum
    local result = (48 * n ^ 5 - 40 * n ^ 3 + 7 * n) / 15
    return fn(result)
end
calc_methods["ofp"] = sum_of_odd_fourth_powers
methods_desc["ofp"] = "前n个奇数的4次方之和"

-- fourth powers sum of first n even numbers
local function sum_of_even_fourth_powers(n)
    -- validate arguments
    if type(n) ~= "number" or n < 1 or n ~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- compute fourth powers sum
    local result = 8 * n * (n + 1) * (2 * n + 1) * (3 * n ^ 2 + 3 * n - 1) / 15
    return fn(result)
end
calc_methods["efp"] = sum_of_even_fourth_powers
methods_desc["efp"] = "前n个偶数的4次方之和"

-- pretty print circle standard equation
local function CircleStandardEquation(h, k, r_squared)
    local standardEquation
    if h == 0 then
        if k > 0 then
            standardEquation = "x²+(y-" .. k .. ")²=" .. r_squared
        elseif k == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            standardEquation = "x²+(y+" .. -k .. ")²=" .. r_squared
        end
    elseif k == 0 then
        if h > 0 then
            standardEquation = "(x-" .. h .. ")²+y²=" .. r_squared
        elseif h == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+y²=" .. r_squared
        end
    else
        if h > 0 and k > 0 then
            standardEquation = "(x-" .. h .. ")²+(y-" .. k .. ")²=" .. r_squared
        elseif h > 0 and k < 0 then
            standardEquation = "(x-" .. h .. ")²+(y+" .. -k .. ")²=" .. r_squared
        elseif h < 0 and k > 0 then
            standardEquation = "(x+" .. -h .. ")²+(y-" .. k .. ")²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+(y+" .. -k .. ")²=" .. r_squared
        end
    end
    return standardEquation
end

-- pretty print circle general equation
local function CircleGeneralEquation(D, E, F)
    local generalEquation = "x²+y²"
    -- handle D term
    if D ~= 0 then
        if D == -1 then
            generalEquation = generalEquation .. "-x"
        elseif D == 1 then
            generalEquation = generalEquation .. "+x"
        elseif D > 0 then
            generalEquation = generalEquation .. "+" .. D .. "x"
        else
            generalEquation = generalEquation .. "-" .. -D .. "x"
        end
    end
    -- handle E term
    if E ~= 0 then
        if E == -1 then
            generalEquation = generalEquation .. "-y"
        elseif E == 1 then
            generalEquation = generalEquation .. "+y"
        elseif E > 0 then
            generalEquation = generalEquation .. "+" .. E .. "y"
        else
            generalEquation = generalEquation .. "-" .. -E .. "y"
        end
    end
    -- handle F term
    if F ~= 0 then
        if F > 0 then
            generalEquation = generalEquation .. "+" .. F .. "=0"
        else
            generalEquation = generalEquation .. "-" .. -F .. "=0"
        end
    end
    return generalEquation
end

-- pretty print line slope intercept equation
local function LineEquation(x1, y1, k)
    local equation, b
    -- special cases
    if k == nil then
        return "x=" .. x1
    else
        equation = "y="
    end
    if k == 0 then
        equation = equation .. y1
        return equation
    end
    -- compute intercept b
    b = fn(y1 - k * x1)
    -- pretty print k
    if k == -1 then
        equation = equation .. "-x"
    elseif k == 1 then
        equation = equation .. "x"
    else
        if k > 0 then
            equation = equation .. k .. "x"
        else
            equation = equation .. "-" .. -k .. "x"
        end
    end
    -- pretty print b
    if b ~= 0 then
        if b > 0 then
            equation = equation .. "+" .. b
        else
            equation = equation .. "-" .. -b
        end
    end
    return equation
end

-- pretty print line general equation
local function LineGeneralEquation(A, B, C)
    -- validate arguments
    if A == 0 and B == 0 then
        return "错误：直线方程系数A和B不能同时为0"
    end
    -- gcd to simplify coefficients
    local s, result
    s = gcd_multiple(math.abs(A), math.abs(B), math.abs(C))
    if A < 0 then
        A = -A
        B = -B
        C = -C
    end
    A = fn(A / s)
    B = fn(B / s)
    C = fn(C / s)
    if A ~= 0 and B == 0 and C == 0 then
        result = "x=0"
    end
    if A ~= 0 and B == 0 and C ~= 0 then
        result = "x=" .. fn(-C / A)
    end
    if A == 0 and B ~= 0 and C == 0 then
        result = "y=0"
    end
    if A == 0 and B ~= 0 and C ~= 0 then
        result = "y=" .. fn(-C / B)
    end
    if A ~= 0 and B ~= 0 then
        if A == 1 then
            result = "x"
        else
            result = A .. "x"
        end
        if B == 1 then
            result = result .. "+y"
        elseif B == -1 then
            result = result .. "-y"
        elseif B > 0 then
            result = result .. "+" .. B .. "y"
        else
            result = result .. "-" .. -B .. "y"
        end
        if C ~= 0 then
            if C > 0 then
                result = result .. "+" .. C .. "=0"
            else
                result = result .. "-" .. -C .. "=0"
            end
        else
            result = result .. "=0"
        end
    end
    return result
end

-- pretty print quadratic expression
local function QuadraticEquation(a, b, c)
    local result = "y="
    -- format a
    if a ~= 0 then
        if a == 1 then
            result = result .. "x²"
        elseif a == -1 then
            result = result .. "-x²"
        else
            result = result .. a .. "x²"
        end
    end
    -- format b
    if b ~= 0 then
        if b == 1 then
            result = result .. "+x"
        elseif b == -1 then
            result = result .. "-x"
        elseif b > 0 then
            result = result .. "+" .. b .. "x"
        else
            result = result .. "-" .. -b .. "x"
        end
    end
    -- format c
    if c ~= 0 then
        if c > 0 then
            result = result .. "+" .. c
        else
            result = result .. "-" .. -c
        end
    end
    return result
end

-- regular polygon area from n and a
local function calculateRegularPolygonArea(n, a)
    -- validate arguments
    if type(n) ~= "number" or type(a) ~= "number" or n ~= floor(n) or n < 1 or a <= 0 then
        return "错误：边数n必须为正整数，边长a必须为正数"
    end
    -- compute polygon area
    local s = (n * a ^ 2) / (4 * math.tan(math.pi / n))
    return fn(s)
end
calc_methods["zdbx"] = calculateRegularPolygonArea
methods_desc["zdbx"] = "已知边数n与边长a计算正多边形面积"

-- partial sum of geometric sequence from a1 and q
local function geometricSeriesSum(a1, q, n)
    -- validate arguments
    if type(a1) ~= "number" or type(q) ~= "number" or type(n) ~= "number" or n ~= floor(n) or n < 1 then
        return "错误：a₁、q、n必须为数字且n是正整数"
    end
    -- compute partial sum
    if a1 == 0 then
        return 0
    elseif q == 0 and a1 ~= 0 then
        return a1
    elseif q == 1 then
        return a1 * n
    else
        local s = a1 * (1 - q ^ n) / (1 - q)
        return fn(s)
    end
end
calc_methods["dbsl"] = geometricSeriesSum
methods_desc["dbsl"] = "已知等比数列的首项a₁，公比q，求指定的前n项和"

-- partial sum of arithmetic sequence from a1 and d
local function ArithmeticSeriesSum(a1, d, n)
    -- validate arguments
    if type(a1) ~= "number" or type(d) ~= "number" or type(n) ~= "number" or n ~= floor(n) or n < 1 then
        return "错误：a₁、d、n必须为数字且n是正整数"
    end
    -- compute partial sum
    if a1 == 0 and d == 0 then
        return 0
    elseif a1 ~= 0 and d == 0 then
        return a1 * n
    else
        local s = n * a1 + n * (n - 1) * d / 2
        return fn(s)
    end
end
calc_methods["dcsl"] = ArithmeticSeriesSum
methods_desc["dcsl"] = "已知等差数列的首项a₁，公差d，求指定的前n项和"

-- general term from any two items ai ak
-- their indexes are i and k
-- b=0 arithmetic b=1 geometric
local function findSequenceFormula(i, ai, k, ak, b)
    -- validate arguments
    if type(i) ~= "number" or i ~= floor(i) or i < 1 or type(k) ~= "number" or k ~= floor(k) or k < 1 then
        return "错误：i 和 k 必须是正整数"
    end
    if ai == ak and i == k then
        return "错误：aᵢ、aₖ 和对应的项数不能同时相等"
    elseif ai ~= ak and i == k then
        return "错误：同一项数对应不同的项值"
    end
    -- general term of arithmetic sequence
    local function arithmeticSequence(i, ai, k, ak)
        local d, a1, s
        d = fn((ak - ai) / (k - i))
        a1 = ai - (i - 1) * d
        s = fn(a1 - d)
        if d == 0 then
            return "aₙ=" .. a1
        elseif d == 1 then
            if s == 0 then
                return "aₙ=n"
            elseif s > 0 then
                return "aₙ=n+" .. s
            else
                return "aₙ=n-" .. -s
            end
        elseif d == -1 then
            if s == 0 then
                return "aₙ=-n"
            elseif s > 0 then
                return "aₙ=-n+" .. s
            else
                return "aₙ=-n-" .. -s
            end
        else
            if s == 0 then
                return "aₙ=" .. d .. "n"
            elseif s > 0 then
                return "aₙ=" .. d .. "n+" .. s
            else
                return "aₙ=" .. d .. "n-" .. -s
            end
        end
    end
    -- general term of geometric sequence
    local function geometricSequence(i, ai, k, ak)
        if ai == 0 or ak == 0 then
            return "错误：等比数列中不能有0项"
        end
        local s, q, n, a1
        s = fn(ak / ai)
        n = fn(k - i)
        if s < 0 and n % 2 == 0 then
            return "无法求解通项公式"
        end
        q = fn(nth_root(s, n))
        a1 = fn(ai / (q ^ (i - 1)))
        if a1 == q then
            if q == 1 then
                return "aₙ=" .. q
            elseif q > 0 then
                return "aₙ=" .. q .. "ⁿ"
            elseif q < 0 then
                return "aₙ=(" .. q .. ")ⁿ"
            end
        elseif a1 == -q then
            if q == 1 then
                return "aₙ=-" .. q
            elseif q == -1 then
                return "aₙ=(" .. q .. ")ⁿ⁻¹"
            elseif q > 0 then
                return "aₙ=-" .. q .. "ⁿ"
            else
                return "aₙ=-(" .. q .. ")ⁿ"
            end
        else
            if q > 0 then
                if a1 == 1 then
                    return "aₙ=" .. q .. "ⁿ⁻¹"
                elseif a1 == -1 then
                    return "aₙ=-" .. q .. "ⁿ⁻¹"
                else
                    return "aₙ=" .. a1 .. "×" .. q .. "ⁿ⁻¹"
                end
            else
                if a1 == 1 then
                    return "aₙ=(" .. q .. ")ⁿ⁻¹"
                elseif a1 == -1 then
                    return "aₙ=-(" .. q .. ")ⁿ⁻¹"
                else
                    return "aₙ=" .. a1 .. "×(" .. q .. ")ⁿ⁻¹"
                end
            end
        end
    end
    -- return general term based on b
    if b == 0 then
        return arithmeticSequence(i, ai, k, ak)
    elseif b == 1 then
        return geometricSequence(i, ai, k, ak)
    else
        return "错误：参数b必须是0或1"
    end
end
calc_methods["tx"] = findSequenceFormula
methods_desc["tx"] = "已知数列的任意两项aᵢ、aₖ及对应的项数i、k，求其通项公式"

-- circle equations from center h k and radius r
local function CircleEquationsxr(h, k, r)
    -- radius must be positive
    if r <= 0 then
        return "错误：半径必须大于0"
    end
    -- circle standard equation
    local r_squared, se, ge, D, E, F
    r_squared = fn(r ^ 2)
    se = CircleStandardEquation(h, k, r_squared)
    -- circle general equation
    D = fn(-2 * h)
    E = fn(-2 * k)
    F = fn(h ^ 2 + k ^ 2 - r ^ 2)
    ge = CircleGeneralEquation(D, E, F)
    -- return both equations
    return "标准方程: " .. se .. "\n一般方程: " .. ge
end
calc_methods["cexr"] = CircleEquationsxr
methods_desc["cexr"] = "已知圆心坐标和半径求圆的方程"

-- circle equations from center h k and two points on it
local function CircleEquationsxl(h, k, x1, y1, x2, y2)
    -- check for coinciding points
    if (x1 == x2 and y1 == y2) or (x1 == h and y1 == k) or (x2 == h and y2 == k) then
        return "错误：三个坐标中不能有任意两个点坐标完全相同"
    end
    local distance1, distance2, r, r_squared, se, ge, D, E, F
    -- distances to center must be equal
    distance1 = math.sqrt((x1 - h) ^ 2 + (y1 - k) ^ 2)
    distance2 = math.sqrt((x2 - h) ^ 2 + (y2 - k) ^ 2)
    if distance1 ~= distance2 then
        return "错误：给定的圆心坐标和两个点无法构成圆"
    end
    -- circle standard equation
    r = distance1
    r_squared = fn(r ^ 2)
    se = CircleStandardEquation(h, k, r_squared)
    -- circle general equation
    D = fn(-2 * h)
    E = fn(-2 * k)
    F = fn(h ^ 2 + k ^ 2 - r_squared)
    ge = CircleGeneralEquation(D, E, F)
    -- return both equations
    return "标准方程: " .. se .. "\n一般方程: " .. ge
end
calc_methods["cexl"] = CircleEquationsxl
methods_desc["cexl"] = "已知圆心和圆上不同两点的坐标求圆方程"

-- circle equation through three non collinear points
local function CircleEquationssd(x1, y1, x2, y2, x3, y3)
    local determinant, A, B, detA, detAD, detAE, detAF, D, E, F, ge, se, r_squared, h, k
    -- check collinearity
    determinant = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法构成圆"
    end
    -- build coefficient matrix A and constant matrix B
    A = {
        { x1, y1, 1 },
        { x2, y2, 1 },
        { x3, y3, 1 }
    }
    B = {
        (-x1 ^ 2 - y1 ^ 2),
        (-x2 ^ 2 - y2 ^ 2),
        (-x3 ^ 2 - y3 ^ 2)
    }
    -- determinant of A
    detA = hls(A[1][1], A[1][2], A[1][3], A[2][1], A[2][2], A[2][3], A[3][1], A[3][2], A[3][3])
    -- determinants for D E F
    detAD = hls(B[1], A[1][2], A[1][3], B[2], A[2][2], A[2][3], B[3], A[3][2], A[3][3])
    detAE = hls(A[1][1], B[1], A[1][3], A[2][1], B[2], A[2][3], A[3][1], B[3], A[3][3])
    detAF = hls(A[1][1], A[1][2], B[1], A[2][1], A[2][2], B[2], A[3][1], A[3][2], B[3])
    -- coefficients D E F
    D = fn(detAD / detA)
    E = fn(detAE / detA)
    F = fn(detAF / detA)
    -- circle general equation
    ge = CircleGeneralEquation(D, E, F)
    -- circle standard equation
    h = fn(-D / 2)
    k = fn(-E / 2)
    r_squared = fn(h ^ 2 + k ^ 2 - F)
    se = CircleStandardEquation(h, k, r_squared)
    -- return both equations
    return "标准方程: " .. se .. "\n一般方程: " .. ge
end
calc_methods["cesd"] = CircleEquationssd
methods_desc["cesd"] = "已知圆上不同三点的坐标，求圆方程"

-- solve linear equation ax+b=0
local function solveLinearEquation(a, b)
    -- a must not be 0 otherwise not linear
    if a == 0 then
        if b == 0 then
            return "方程有无数解"
        else
            return "方程无解"
        end
    else
        -- compute x
        local x = fn(-b / a)
        return "x=" .. x
    end
end
calc_methods["yyyc"] = solveLinearEquation
methods_desc["yyyc"] = "求解一元一次方程"

-- solve system ax+by=e cx+dy=f
local function solveLinearSystem(a, b, c, d, e, f)
    local D, x, y
    -- determinant D
    D = a * d - b * c
    -- check solvability
    if D == 0 then
        if (a * f - c * e) == 0 and (b * e - d * f) == 0 then
            return "方程组有无穷多解"
        else
            return "方程组无解"
        end
    end
    -- compute x and y
    x = fn((d * e - b * f) / D)
    y = fn((a * f - c * e) / D)
    -- return solution string
    return "x=" .. x .. "\ny=" .. y
end
calc_methods["eyyc"] = solveLinearSystem
methods_desc["eyyc"] = "求解二元一次方程组ax+by=e，cx+dy=f"

-- linear expression from point and slope
-- input slope k and point x1 y1
local function pointSlopeForm(k, x1, y1)
    local le = LineEquation(x1, y1, k)
    return "直线方程: " .. le
end
calc_methods["dxf"] = pointSlopeForm
methods_desc["dxf"] = "点斜法求解一次函数解析式"

-- linear expression from two points
-- input two points x1 y1 and x2 y2
local function twoPointsForm(x1, y1, x2, y2)
    -- points must differ
    if x1 == x2 and y1 == y2 then
        return "错误：两点坐标完全相同，无法确定直线方程"
    end
    local k, le
    -- compute slope k
    if x1 == x2 then
        k = nil
    else
        k = (y2 - y1) / (x2 - x1)
        k = fn(k)
    end
    le = LineEquation(x1, y1, k)
    return "直线方程: " .. le
end
calc_methods["ldf"] = twoPointsForm
methods_desc["ldf"] = "两点法求解一次函数解析式"

-- solve quadratic ax^2+bx+c=0
local function solveQuadraticEquation(a, b, c)
    -- validate arguments
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：二次项系数不能为0"
    end
    local Delta, x1, x2, P, Q
    Delta = b ^ 2 - 4 * a * c
    P = fn(-b / (2 * a))
    if Delta == 0 then
        x1 = P
        return "x₁=x₂=" .. x1
    elseif Delta > 0 then
        Q = fn(math.sqrt(Delta) / (2 * a))
        x1 = P + Q
        x2 = P - Q
    else
        Q = fn(math.sqrt(-Delta) / (2 * a))
        if P == 0 then
            if Q == 1 then
                x1 = "i"
                x2 = "-i"
            elseif Q == -1 then
                x1 = "-i"
                x2 = "i"
            else
                x1 = Q .. "i"
                x2 = -Q .. "i"
            end
        else
            if Q == 1 then
                x1 = P .. "+i"
                x2 = P .. "-i"
            elseif Q == -1 then
                x1 = P .. "-i"
                x2 = P .. "+i"
            elseif Q > 0 then
                x1 = P .. "+" .. Q .. "i"
                x2 = P .. "-" .. Q .. "i"
            else
                x1 = P .. "-" .. -Q .. "i"
                x2 = P .. "+" .. -Q .. "i"
            end
        end
    end
    return "x₁=" .. x1 .. "\nx₂=" .. x2
end
calc_methods["yyec"] = solveQuadraticEquation
methods_desc["yyec"] = "求解一元二次方程"

-- solve cubic ax^3+bx^2+cx+d=0
local function solveCubicEquation(a, b, c, d)
    -- validate arguments
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：系数a不能为零"
    end
    -- repeated root discriminants
    local A, B, C, Delta
    A = b ^ 2 - 3 * a * c
    B = b * c - 9 * a * d
    C = c ^ 2 - 3 * b * d
    -- total discriminant
    Delta = B ^ 2 - 4 * A * C
    -- shengjin formula
    -- case 1 A=B=0 one triple real root
    if A == 0 and B == 0 then
        local x = fn(-b / (3 * a))
        return "x₁=x₂=x₃=" .. x
        -- case 2 Delta>0 one real root and conjugate complex pair
    elseif Delta > 0 then
        local Y1, Y2, y1, y2, x1, x2, x3, P, Q
        Y1 = A * b + 3 * a * (-B + math.sqrt(Delta)) / 2
        Y2 = A * b + 3 * a * (-B - math.sqrt(Delta)) / 2
        y1 = nth_root(Y1, 3)
        y2 = nth_root(Y2, 3)
        x1 = fn((-b - y1 - y2) / (3 * a))
        P = fn((-b + 0.5 * (y1 + y2)) / (3 * a))
        Q = fn((0.5 * math.sqrt(3) * (y1 - y2)) / (3 * a))
        if P == 0 then
            if Q == 1 then
                x2 = "i"
                x3 = "-i"
            elseif Q == -1 then
                x2 = "-i"
                x3 = "i"
            else
                x2 = Q .. "i"
                x3 = -Q .. "i"
            end
        elseif P ~= 0 and Q == 1 then
            x2 = P .. "+i"
            x3 = P .. "-i"
        elseif P ~= 0 and Q == -1 then
            x2 = P .. "-i"
            x3 = P .. "+i"
        elseif P ~= 0 and Q > 0 then
            x2 = P .. "+" .. Q .. "i"
            x3 = P .. "-" .. Q .. "i"
        elseif P ~= 0 and Q < 0 then
            x2 = P .. "-" .. -Q .. "i"
            x3 = P .. "+" .. -Q .. "i"
        end
        return "x₁=" .. x1 .. "\nx₂=" .. x2 .. "\nx₃=" .. x3
        -- case 3 Delta=0 three real roots with one double root
    elseif Delta == 0 and A ~= 0 then
        local K, x1, x2
        K = B / A
        x1 = fn(-b / a + K)
        x2 = fn(-0.5 * K)
        return "x₁=" .. x1 .. "\nx₂=x₃=" .. x2
    elseif Delta < 0 and A > 0 then
        -- case 4 Delta<0 three distinct real roots
        local T, M, S, R, x1, x2, x3
        T = (2 * A * b - 3 * a * B) / (2 * math.sqrt(A ^ 3))
        M = acos(T)
        S = cos(M / 3)
        R = sin(M / 3)
        x1 = fn((-b - 2 * math.sqrt(A) * S) / (3 * a))
        x2 = fn((-b + math.sqrt(A) * (S + math.sqrt(3) * R)) / (3 * a))
        x3 = fn((-b + math.sqrt(A) * (S - math.sqrt(3) * R)) / (3 * a))
        return "x₁=" .. x1 .. "\nx₂=" .. x2 .. "\nx₃=" .. x3
    end
end
calc_methods["yysc1"] = solveCubicEquation
methods_desc["yysc1"] = "求解一元三次方程"

-- solve quartic ax^4+bx^3+cx^2+dx+e=0
local function solveQuarticEquation(a, b, c, d, e)
    -- validate arguments
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" or type(e) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：系数a不能为零"
    end
    -- repeated root discriminants
    local D, E, F, A, B, C, Delta
    D = 3 * b ^ 2 - 8 * a * c
    E = -b ^ 3 + 4 * a * b * c - 8 * a ^ 2 * d
    F = 3 * b ^ 4 + 16 * a ^ 2 * c ^ 2 - 16 * a * b ^ 2 * c + 16 * a ^ 2 * b * d - 64 * a ^ 3 * e
    A = D ^ 2 - 3 * F
    B = D * F - 9 * E ^ 2
    C = F ^ 2 - 3 * D * E ^ 2
    -- total discriminant
    Delta = B ^ 2 - 4 * A * C
    -- sign helper
    local function sgn(x)
        if x == 0 then
            return 0
        else
            return fn(math.abs(x) / x)
        end
    end
    -- tianheng formula
    -- case 1 D=E=F=0 one quadruple real root
    if D == 0 and E == 0 and F == 0 then
        local x
        x = fn(-b / (4 * a))
        return "x₁=x₂=x₃=x₄=" .. x
    end
    -- case 2 DEF nonzero A=B=C=0 four real roots with one triple root
    if (D * E * F ~= 0) and (A == 0 and B == 0 and C == 0) then
        local x1, x2
        x1 = fn((-b * D + 9 * E) / (4 * a * D))
        x2 = fn((-b * D - 3 * E) / (4 * a * D))
        return "x₁=" .. x1 .. "\nx₂=x₃=x₄=" .. x2
    end
    -- case 3 E=F=0 D nonzero two double roots real if D>0 complex if D<0
    if E == 0 and F == 0 and D ~= 0 then
        local x1, x2, P, Q
        if D > 0 then
            x1 = fn((-b + math.sqrt(D)) / (4 * a))
            x2 = fn((-b - math.sqrt(D)) / (4 * a))
        else
            P = fn(-b / (4 * a))
            Q = fn(math.sqrt(-D) / (4 * a))
            if P == 0 then
                if Q == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q .. "i"
                    x2 = -Q .. "i"
                end
            else
                if Q == 1 then
                    x1 = P .. "+i"
                    x2 = P .. "-i"
                elseif Q == -1 then
                    x1 = P .. "-i"
                    x2 = P .. "+i"
                elseif Q > 0 then
                    x1 = P .. "+" .. Q .. "i"
                    x2 = P .. "-" .. Q .. "i"
                else
                    x1 = P .. "-" .. -Q .. "i"
                    x2 = P .. "+" .. -Q .. "i"
                end
            end
        end
        return "x₁=x₂=" .. x1 .. "\nx₃=x₄=" .. x2
    end
    -- case 4 ABC nonzero Delta=0 one double real root
    -- others real if AB>0 conjugate complex if AB<0
    if (A * B * C ~= 0) and (Delta == 0) then
        local P, Q, R, x1, x2, x3
        P = -b / (4 * a)
        Q = 2 * A * E / (4 * a * B)
        x1 = fn(P - Q)
        if A * B > 0 then
            R = math.sqrt(2 * B / A) / (4 * a)
            x2 = fn(P + Q + R)
            x3 = fn(P + Q - R)
        else
            R = fn(math.sqrt(-2 * B / A) / (4 * a))
            if (P + Q) == 0 then
                if R == 1 then
                    x2 = "i"
                    x3 = "-i"
                elseif R == -1 then
                    x2 = "-i"
                    x3 = "i"
                else
                    x2 = R .. "i"
                    x3 = -R .. "i"
                end
            else
                if R == 1 then
                    x2 = fn(P + Q) .. "+i"
                    x3 = fn(P + Q) .. "-i"
                elseif R == -1 then
                    x2 = fn(P + Q) .. "-i"
                    x3 = fn(P + Q) .. "+i"
                elseif R > 0 then
                    x2 = fn(P + Q) .. "+" .. R .. "i"
                    x3 = fn(P + Q) .. "-" .. R .. "i"
                else
                    x2 = fn(P + Q) .. "-" .. -R .. "i"
                    x3 = fn(P + Q) .. "+" .. -R .. "i"
                end
            end
        end
        return "x₁=x₂=" .. x1 .. "\nx₃=" .. x2 .. "\nx₄=" .. x3
    end
    -- case 5 Delta>0 two distinct real roots and conjugate pair
    if Delta > 0 then
        local z, z1, z2, z3, x1, x2, x3, x4, P, Q, R1, R2
        z1 = A * D + 3 * ((-B + math.sqrt(Delta)) / 2)
        z2 = A * D + 3 * ((-B - math.sqrt(Delta)) / 2)
        z3 = nth_root(z1, 3) + nth_root(z2, 3)
        z = D ^ 2 - D * z3 + z3 ^ 2 - 3 * A
        P = -b / (4 * a)
        Q = sgn(E) * math.sqrt((D + z3) / 3) / (4 * a)
        R1 = math.sqrt((2 * D - z3 + 2 * math.sqrt(z)) / 3) / (4 * a)
        R2 = fn(math.sqrt((-2 * D + z3 + 2 * math.sqrt(z)) / 3) / (4 * a))
        x1 = fn(P + Q + R1)
        x2 = fn(P + Q - R1)
        if (P - Q) == 0 then
            if R2 == 1 then
                x3 = "i"
                x4 = "-i"
            elseif R2 == -1 then
                x3 = "-i"
                x4 = "i"
            else
                x3 = R2 .. "i"
                x4 = -R2 .. "i"
            end
        else
            if R2 == 1 then
                x3 = fn(P - Q) .. "+i"
                x4 = fn(P - Q) .. "-i"
            elseif R2 == -1 then
                x3 = fn(P - Q) .. "-i"
                x4 = fn(P - Q) .. "+i"
            elseif R2 > 0 then
                x3 = fn(P - Q) .. "+" .. R2 .. "i"
                x4 = fn(P - Q) .. "-" .. R2 .. "i"
            else
                x3 = fn(P - Q) .. "-" .. -R2 .. "i"
                x4 = fn(P - Q) .. "+" .. -R2 .. "i"
            end
        end
        return "x₁=" .. x1 .. "\nx₂=" .. x2 .. "\nx₃=" .. x3 .. "\nx₄=" .. x4
    end
    -- case 6 Delta<0 four real roots if D F positive otherwise two conjugate pairs
    if Delta < 0 then
        local T, M, N, O, y1, y2, y3, x1, x2, x3, x4, P, Q1, Q2, Q3
        T = (3 * B - 2 * A * D) / (2 * A * math.sqrt(A))
        M = acos(T)
        N = cos(M / 3)
        O = sin(M / 3)
        y1 = (D - 2 * math.sqrt(A) * N) / 3
        y2 = (D + math.sqrt(A) * (N + math.sqrt(3) * O)) / 3
        y3 = (D + math.sqrt(A) * (N - math.sqrt(3) * O)) / 3
        -- case 6.1 E=0 D>0 F>0 four real roots
        if E == 0 and D > 0 and F > 0 then
            x1 = fn((-b + math.sqrt(D + 2 * math.sqrt(F))) / (4 * a))
            x2 = fn((-b - math.sqrt(D + 2 * math.sqrt(F))) / (4 * a))
            x3 = fn((-b + math.sqrt(D - 2 * math.sqrt(F))) / (4 * a))
            x4 = fn((-b - math.sqrt(D - 2 * math.sqrt(F))) / (4 * a))
            -- case 6.2 E=0 D<0 F>0 two conjugate pairs
        elseif E == 0 and D < 0 and F > 0 then
            P = fn(-b / (4 * a))
            Q1 = fn(math.sqrt(-D + 2 * math.sqrt(F)) / (4 * a))
            Q2 = fn(math.sqrt(-D - 2 * math.sqrt(F)) / (4 * a))
            if P == 0 then
                if Q1 == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q1 == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q1 .. "i"
                    x2 = -Q1 .. "i"
                end
                if Q2 == 1 then
                    x3 = "i"
                    x4 = "-i"
                elseif Q2 == -1 then
                    x3 = "-i"
                    x4 = "i"
                else
                    x3 = Q2 .. "i"
                    x4 = -Q2 .. "i"
                end
            else
                if Q1 == 1 then
                    x1 = P .. "+i"
                    x2 = P .. "-i"
                elseif Q1 == -1 then
                    x1 = P .. "-i"
                    x2 = P .. "+i"
                elseif Q1 > 0 then
                    x1 = P .. "+" .. Q1 .. "i"
                    x2 = P .. "-" .. Q1 .. "i"
                else
                    x1 = P .. "-" .. -Q1 .. "i"
                    x2 = P .. "+" .. -Q1 .. "i"
                end
                if Q2 == 1 then
                    x3 = P .. "+i"
                    x4 = P .. "-i"
                elseif Q2 == -1 then
                    x3 = P .. "-i"
                    x4 = P .. "+i"
                elseif Q2 > 0 then
                    x3 = P .. "+" .. Q2 .. "i"
                    x4 = P .. "-" .. Q2 .. "i"
                else
                    x3 = P .. "-" .. -Q2 .. "i"
                    x4 = P .. "+" .. -Q2 .. "i"
                end
            end
            -- case 6.3 E=0 F<0 two conjugate pairs
        elseif E == 0 and F < 0 then
            P = -b / (4 * a)
            Q1 = math.sqrt(2 * D + 2 * math.sqrt(A - F)) / (8 * a)
            Q2 = fn(math.sqrt(-2 * D + 2 * math.sqrt(A - F)) / (8 * a))
            if (P + Q1) == 0 then
                if Q2 == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q2 == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q2 .. "i"
                    x2 = -Q2 .. "i"
                end
            else
                if Q2 == 1 then
                    x1 = fn(P + Q1) .. "+i"
                    x2 = fn(P + Q1) .. "-i"
                elseif Q2 == -1 then
                    x1 = fn(P + Q1) .. "-i"
                    x2 = fn(P + Q1) .. "+i"
                elseif Q2 > 0 then
                    x1 = fn(P + Q1) .. "+" .. Q2 .. "i"
                    x2 = fn(P + Q1) .. "-" .. Q2 .. "i"
                else
                    x1 = fn(P + Q1) .. "-" .. -Q2 .. "i"
                    x2 = fn(P + Q1) .. "+" .. -Q2 .. "i"
                end
            end
            if (P - Q1) == 0 then
                if Q2 == 1 then
                    x3 = "i"
                    x4 = "-i"
                elseif Q2 == -1 then
                    x3 = "-i"
                    x4 = "i"
                else
                    x3 = Q2 .. "i"
                    x4 = -Q2 .. "i"
                end
            else
                if Q2 == 1 then
                    x3 = fn(P - Q1) .. "+i"
                    x4 = fn(P - Q1) .. "-i"
                elseif Q2 == -1 then
                    x3 = fn(P - Q1) .. "-i"
                    x4 = fn(P - Q1) .. "+i"
                elseif Q2 > 0 then
                    x3 = fn(P - Q1) .. "+" .. Q2 .. "i"
                    x4 = fn(P - Q1) .. "-" .. Q2 .. "i"
                else
                    x3 = fn(P - Q1) .. "-" .. -Q2 .. "i"
                    x4 = fn(P - Q1) .. "+" .. -Q2 .. "i"
                end
            end
            -- case 6.4 E nonzero four real roots if D F positive else two conjugate pairs
        elseif E ~= 0 then
            if D > 0 and F > 0 then
                P = -b / (4 * a)
                Q1 = sgn(E) * math.sqrt(y1) / (4 * a)
                Q2 = (math.sqrt(y2) + math.sqrt(y3)) / (4 * a)
                Q3 = (math.sqrt(y2) - math.sqrt(y3)) / (4 * a)
                x1 = fn(P + Q1 + Q2)
                x2 = fn(P + Q1 - Q2)
                x3 = fn(P - Q1 + Q3)
                x4 = fn(P - Q1 - Q3)
            else
                P = -b / (4 * a)
                Q1 = math.sqrt(y2) / (4 * a)
                Q2 = sgn(E) * math.sqrt(-y1) / (4 * a)
                Q3 = math.sqrt(-y3) / (4 * a)
                if (P - Q1) == 0 then
                    if (Q2 + Q3) == 1 then
                        x1 = "i"
                        x2 = "-i"
                    elseif (Q2 + Q3) == -1 then
                        x1 = "-i"
                        x2 = "i"
                    else
                        x1 = fn(Q2 + Q3) .. "i"
                        x2 = -fn(Q2 + Q3) .. "i"
                    end
                else
                    if fn(Q2 + Q3) == 1 then
                        x1 = fn(P - Q1) .. "+i"
                        x2 = fn(P - Q1) .. "-i"
                    elseif fn(Q2 + Q3) == -1 then
                        x1 = fn(P - Q1) .. "-i"
                        x2 = fn(P - Q1) .. "+i"
                    elseif fn(Q2 + Q3) > 0 then
                        x1 = fn(P - Q1) .. "+" .. fn(Q2 + Q3) .. "i"
                        x2 = fn(P - Q1) .. "-" .. fn(Q2 + Q3) .. "i"
                    else
                        x1 = fn(P - Q1) .. "-" .. -fn(Q2 + Q3) .. "i"
                        x2 = fn(P - Q1) .. "+" .. -fn(Q2 + Q3) .. "i"
                    end
                end
                if (P + Q1) == 0 then
                    if fn(Q2 - Q3) == 1 then
                        x3 = "i"
                        x4 = "-i"
                    elseif fn(Q2 - Q3) == -1 then
                        x3 = "-i"
                        x4 = "i"
                    else
                        x3 = fn(Q2 - Q3) .. "i"
                        x4 = -fn(Q2 - Q3) .. "i"
                    end
                else
                    if fn(Q2 - Q3) == 1 then
                        x3 = fn(P + Q1) .. "+i"
                        x4 = fn(P + Q1) .. "-i"
                    elseif fn(Q2 - Q3) == -1 then
                        x3 = fn(P + Q1) .. "-i"
                        x4 = fn(P + Q1) .. "+i"
                    elseif fn(Q2 - Q3) > 0 then
                        x3 = fn(P + Q1) .. "+" .. fn(Q2 - Q3) .. "i"
                        x4 = fn(P + Q1) .. "-" .. fn(Q2 - Q3) .. "i"
                    else
                        x3 = fn(P + Q1) .. "-" .. -fn(Q2 - Q3) .. "i"
                        x4 = fn(P + Q1) .. "+" .. -fn(Q2 - Q3) .. "i"
                    end
                end
            end
        end
        return "x₁=" .. x1 .. "\nx₂=" .. x2 .. "\nx₃=" .. x3 .. "\nx₄=" .. x4
    end
end
calc_methods["yysc2"] = solveQuarticEquation
methods_desc["yysc2"] = "求解一元四次方程"

-- quadratic from vertex form y=a(x-h)^2+k
-- x1 y1 is the vertex x2 y2 any other point on the graph
local function getQuadraticEquationdd(x1, y1, x2, y2)
    -- points must differ
    if x1 == x2 or y1 == y2 then
        return "错误：两个点的横坐标不能相同"
    end
    local a, b, c, qe
    a = fn((y2 - y1) / (x2 - x1) ^ 2)
    b = fn(-2 * a * x1)
    c = fn(y1 + a * x1 ^ 2)
    qe = QuadraticEquation(a, b, c)
    return "二次函数解析式为：" .. qe
end
calc_methods["dds"] = getQuadraticEquationdd
methods_desc["dds"] = "顶点式求解二次函数解析式"

-- quadratic from general form
local function getQuadraticEquationy(x1, y1, x2, y2, x3, y3)
    local A, B, detA, detAx, detAy, detAz, a, b, c, qe, determinant
    -- points must not be collinear
    determinant = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法求解二次函数解析式"
    end
    -- build coefficient and constant matrixes
    A = {
        { x1 ^ 2, x1, 1 },
        { x2 ^ 2, x2, 1 },
        { x3 ^ 2, x3, 1 }
    }
    B = {
        (y1),
        (y2),
        (y3)
    }
    -- determinant of A
    detA = hls(A[1][1], A[1][2], A[1][3], A[2][1], A[2][2], A[2][3], A[3][1], A[3][2], A[3][3])
    -- determinants detAx detAy detAz
    detAx = hls(B[1], A[1][2], A[1][3], B[2], A[2][2], A[2][3], B[3], A[3][2], A[3][3])
    detAy = hls(A[1][1], B[1], A[1][3], A[2][1], B[2], A[2][3], A[3][1], B[3], A[3][3])
    detAz = hls(A[1][1], A[1][2], B[1], A[2][1], A[2][2], B[2], A[3][1], A[3][2], B[3])
    -- coefficients a b c
    a = fn(detAx / detA)
    b = fn(detAy / detA)
    c = fn(detAz / detA)
    qe = QuadraticEquation(a, b, c)
    return "二次函数解析式为：" .. qe
end
calc_methods["ybs"] = getQuadraticEquationy
methods_desc["ybs"] = "一般式求解二次函数解析式"

-- triangle area from sides a b c
local function calculateTriangleArea(a, b, c)
    -- sides must form a triangle
    if a + b <= c or a + c <= b or b + c <= a then
        return "错误：不能构成三角形"
    end
    local p, s
    -- half perimeter
    p = (a + b + c) / 2
    -- heron formula
    s = math.sqrt(p * (p - a) * (p - b) * (p - c))
    return fn(s)
end
calc_methods["sjx1"] = calculateTriangleArea
methods_desc["sjx1"] = "已知三角形的三边长a、b、c，求三角形面积"

-- triangle area from three vertexes
local function calculateTriangleArea2(x1, y1, x2, y2, x3, y3)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local determinant, s
    determinant = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    -- must form a triangle
    if determinant == 0 then
        return "错误：三个点重合或共线，不能构成三角形"
    end
    -- compute area
    s = fn(math.abs(determinant / 2))
    return s
end
calc_methods["sjx2"] = calculateTriangleArea2
methods_desc["sjx2"] = "已知三角形的三个顶点坐标(x₁,y₁)，(x₂,y₂)，(x₃,y₃)，求三角形面积"

-- distance and reflection of point across line Ax+By+C=0
local function dyzx1(x1, y1, A, B, C)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(A) ~= "number" or type(B) ~= "number" or type(C) ~= "number" then
        return "错误：参数必须是数字"
    end
    if A == 0 and B == 0 then
        return "错误：直线方程的系数不能同时为零"
    end
    local S, D, s, x, y
    -- check point on line
    S = A * x1 + B * y1 + C
    if S == 0 then
        return "点在直线上，距离为0，无法求解对称点坐标"
    end
    -- distance to line
    D = fn(math.abs(S) / math.sqrt(A ^ 2 + B ^ 2))
    -- reflection coordinates
    s = S / (A ^ 2 + B ^ 2)
    x = fn(x1 - 2 * A * s)
    y = fn(y1 - 2 * B * s)
    return "点到直线距离为" .. D .. "\n点关于直线的对称点坐标为(" .. x .. "," .. y .. ")"
end
calc_methods["dyzx1"] = dyzx1
methods_desc["dyzx1"] = "已知一点坐标(x₁, y₁)和直线方程Ax+By+C=0，求点到直线的距离及对称点坐标"

-- distance between two points
local function ld1(x1, y1, x2, y2)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" then
        return "错误：参数必须是数字"
    end
    -- points must differ
    if x1 == x2 and y1 == y2 then
        return "两点重合，距离为0"
    end
    -- compute distance
    local D = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    return fn(D)
end
calc_methods["ld1"] = ld1
methods_desc["ld1"] = "已知两点坐标，求两点间的距离"

-- perpendicular bisector of segment
local function ld2(x1, y1, x2, y2)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" then
        return "错误：参数必须是数字"
    end
    if x1 == x2 and y1 == y2 then
        return "错误：两点重合，无法求解垂直平分线方程"
    end
    local x3, y3, k, kl, se
    -- midpoint of the segment
    x3 = fn((x1 + x2) / 2)
    y3 = fn((y1 + y2) / 2)
    if x1 == x2 then
        k = nil
        kl = 0
    else
        k = (y2 - y1) / (x2 - x1)
        if k == 0 then
            kl = nil
        else
            kl = -1 / k
            kl = fn(kl)
        end
    end
    se = LineEquation(x3, y3, kl)
    return "垂直平分线方程为：" .. se
end
calc_methods["ld2"] = ld2
methods_desc["ld2"] = "已知两点坐标，求两点间线段的垂直平分线方程"

-- rotate P around Q by angle a in degrees
-- positive ccw negative cw
local function ld3(x1, y1, x2, y2, a)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(a) ~= "number" then
        return "错误：参数必须是数字"
    end
    -- angle in radians
    local a1, x, y
    a1 = rad(a)
    -- rotated coordinates
    x = fn(x2 + (x1 - x2) * cos(a1) - (y1 - y2) * sin(a1))
    y = fn(y2 + (x1 - x2) * sin(a1) + (y1 - y2) * cos(a1))
    return "点P(" .. x1 .. "," .. y1 .. ")绕点Q(" .. x2 .. "," .. y2 .. ")旋转" .. a .. "°后的P'坐标为(" .. x .. "," .. y .. ")"
end
calc_methods["ld3"] = ld3
methods_desc["ld3"] = "已知两点P(x₁, y₁)和Q(x₂, y₂)，求点P绕点Q旋转角度a(角度制)后的P'坐标"

-- relation of two lines
local function lines_relationship(A1, B1, C1, A2, B2, C2)
    -- validate arguments
    if (A1 == 0 and B1 == 0) or (A2 == 0 and B2 == 0) then
        return "错误：直线方程的系数不能同时为零"
    end
    local px, ch, D, x, y, k
    -- parallel or coincident test
    px = (A1 * B2 == A2 * B1) and (A1 * C2 ~= A2 * C1)
    ch = (A1 * B2 == A2 * B1) and (C1 * B2 == C2 * B1) and (C1 * A2 == C2 * A1)
    -- lines coincide
    if ch then
        return "两直线重合，距离为0"
        -- parallel compute distance
    elseif px then
        if B1 ~= B2 then
            k = math.max(B1, B2) / math.min(B1, B2)
            if B1 < B2 then
                A1 = A1 * k
                B1 = B1 * k
                C1 = C1 * k
            else
                C2 = C2 * k
            end
        end
        D = fn(math.abs(C2 - C1) / math.sqrt(A1 ^ 2 + B1 ^ 2))
        return "两直线平行，距离为" .. D
        -- intersecting compute intersection
    else
        x = fn((B1 * C2 - B2 * C1) / (A1 * B2 - A2 * B1))
        y = fn((C1 * A2 - C2 * A1) / (A1 * B2 - A2 * B1))
        return "两直线相交，交点坐标为(" .. x .. "," .. y .. ")"
    end
end
calc_methods["lzx1"] = lines_relationship
methods_desc["lzx1"] = "已知两直线方程A₁x+B₁y+C₁=0和A₂x+B₂y+C₂=0，判断它们的位置关系"

-- inradius and circumradius from sides
local function triangle_circles(a, b, c)
    -- validate arguments
    if a <= 0 or b <= 0 or c <= 0 then
        return "错误：边长必须为正数"
    end
    -- must form a triangle
    if a + b <= c or a + c <= b or b + c <= a then
        return "错误：给定的边长不能构成三角形"
    end
    local s, A, r, R
    -- half perimeter
    s = (a + b + c) / 2
    -- area
    A = math.sqrt(s * (s - a) * (s - b) * (s - c))
    -- inradius
    r = fn(A / s)
    -- circumradius
    R = fn((a * b * c) / (4 * A))
    return "内切圆半径为" .. r .. "\n外接圆半径为" .. R
end
calc_methods["sjxy1"] = triangle_circles
methods_desc["sjxy1"] = "已知三角形三边长，求内切圆半径和外接圆半径"

-- inradius and circumradius from vertexes
local function triangle_circles_by_points(x1, y1, x2, y2, x3, y3)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local a, b, c
    -- points must not be collinear
    if x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2) == 0 then
        return "错误：三个点共线或重合，无法构成三角形"
    end
    -- side lengths
    a = ld1(x1, y1, x2, y2)
    b = ld1(x2, y2, x3, y3)
    c = ld1(x1, y1, x3, y3)
    -- reuse side based function
    return triangle_circles(a, b, c)
end
calc_methods["sjxy2"] = triangle_circles_by_points
methods_desc["sjxy2"] = "已知三角形三个顶点坐标，求内切圆半径和外接圆半径"

-- triangle centers from vertexes
local function triangle_centers(x1, y1, x2, y2, x3, y3)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local determinant, a, b, c, xg, yg, xn, yn, xw, yw, xc, yc, d1, s1, s2
    -- points must not be collinear
    determinant = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法构成三角形"
    end
    -- side lengths
    a = ld1(x2, y2, x3, y3)
    b = ld1(x1, y1, x3, y3)
    c = ld1(x1, y1, x2, y2)
    -- centroid
    xg = fn((x1 + x2 + x3) / 3)
    yg = fn((y1 + y2 + y3) / 3)
    -- incenter
    xn = fn((a * x1 + b * x2 + c * x3) / (a + b + c))
    yn = fn((a * y1 + b * y2 + c * y3) / (a + b + c))
    -- circumcenter
    d1 = 2 * determinant
    xw = fn(((x1 ^ 2 + y1 ^ 2) * (y2 - y3) + (x2 ^ 2 + y2 ^ 2) * (y3 - y1) + (x3 ^ 2 + y3 ^ 2) * (y1 - y2)) / d1)
    yw = fn(((x1 ^ 2 + y1 ^ 2) * (x3 - x2) + (x2 ^ 2 + y2 ^ 2) * (x1 - x3) + (x3 ^ 2 + y3 ^ 2) * (x2 - x1)) / d1)
    -- orthocenter
    s1 = x1 * (x2 * (y1 - y2) + x3 * (y3 - y1)) + (y2 - y3) * (x2 * x3 + (y1 - y2) * (y1 - y3))
    s2 = x1 ^ 2 * (x2 - x3) + x1 * (x3 ^ 2 - x2 ^ 2 + y1 * y2 - y1 * y3) + x2 ^ 2 * x3 -
        x2 * (x3 ^ 2 + y1 * y2 - y2 * y3) +
        x3 * y3 * (y1 - y2)
    xc = fn(s1 / -determinant)
    yc = fn(s2 / determinant)
    return "重心(" .. xg .. "," .. yg .. ")\n内心(" .. xn .. "," .. yn .. ")\n外心(" .. xw ..
        "," .. yw .. ")\n垂心(" .. xc .. "," .. yc .. ")"
end
calc_methods["sjxx"] = triangle_centers
methods_desc["sjxx"] = "已知三角形三个顶点坐标，求其“心”的坐标"

-- permutations
local function permutation(n, r)
    -- validate arguments
    if type(n) ~= "number" or type(r) ~= "number" then
        return "错误：参数必须为数字"
    end
    if n < 0 or r < 0 or n ~= floor(n) or r ~= floor(r) then
        return "错误：参数必须为非负整数"
    end
    if r > n then
        return "错误：第二个参数不能大于第一个参数"
    end
    -- compute permutations
    local result = factorial(n) / factorial(n - r)
    return fn(result)
end
calc_methods["pls"] = permutation
methods_desc["pls"] = "计算排列数"

-- combinations
local function combination(n, r)
    -- validate arguments
    if type(n) ~= "number" or type(r) ~= "number" then
        return "错误：参数必须为数字"
    end
    if n < 0 or r < 0 or n ~= floor(n) or r ~= floor(r) then
        return "错误：参数必须为非负整数"
    end
    if r > n then
        return "错误：第二个参数不能大于第一个参数"
    end
    -- compute combinations
    local result = factorial(n) / (factorial(r) * factorial(n - r))
    return fn(result)
end
calc_methods["zhs"] = combination
methods_desc["zhs"] = "计算组合数"

-- reflections of two lines across each other
local function symmetry_line(A1, B1, C1, A2, B2, C2)
    -- validate arguments
    if type(A1) ~= "number" or type(B1) ~= "number" or type(C1) ~= "number" or type(A2) ~= "number" or type(B2) ~= "number" or type(C2) ~= "number" then
        return "错误：参数必须是数字"
    end
    if (A1 == 0 and B1 == 0) or (A2 == 0 and B2 == 0) then
        return "错误：直线方程的系数不能同时为零"
    end
    -- coefficients of reflected lines
    local a1, a2, b, A3, B3, C3, A4, B4, C4, ge1, ge2
    a1 = A2 ^ 2 + B2 ^ 2
    b = 2 * (A1 * A2 + B1 * B2)
    A3 = a1 * A1 - b * A2
    B3 = a1 * B1 - b * B2
    C3 = a1 * C1 - b * C2
    a2 = A1 ^ 2 + B1 ^ 2
    A4 = a2 * A2 - b * A1
    B4 = a2 * B2 - b * B1
    C4 = a2 * C2 - b * C1
    ge1 = LineGeneralEquation(A3, B3, C3)
    ge2 = LineGeneralEquation(A4, B4, C4)
    return "直线l₁关于l₂的对称直线l₃的方程为：" .. ge1 .. "\n直线l₂关于l₁的对称直线l₄的方程为：" .. ge2
end
calc_methods["lzx2"] = symmetry_line
methods_desc["lzx2"] = "已知直线l₁:A₁x+B₁y+C₁=0和l₂:A₂x+B₂y+C₂=0，求两条直线以彼此为轴的对称直线方程"

-- reflection of line l across point P
local function dyzx2(x1, y1, A, B, C)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(A) ~= "number" or type(B) ~= "number" or type(C) ~= "number" then
        return "错误：参数必须是数字"
    end
    if A == 0 and B == 0 then
        return "直线方程的系数不能同时为零"
    end
    local A1, B1, C1, ge
    -- coefficients of reflected line
    A1 = A
    B1 = B
    C1 = -(2 * A * x1 + 2 * B * y1 + C)
    ge = LineGeneralEquation(A1, B1, C1)
    return "直线l关于点P的对称直线l'的方程为：" .. ge
end
calc_methods["dyzx2"] = dyzx2
methods_desc["dyzx2"] = "已知一点P(x₁,y₁)和直线l:Ax+By+C=0，求直线l关于点P的对称直线l'的方程"

-- relation of two circles in standard form
local function tcr1(x1, y1, r1, x2, y2, r2)
    -- validate arguments
    if type(x1) ~= "number" or type(y1) ~= "number" or type(r1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(r2) ~= "number" then
        return "错误：参数必须是数字"
    end
    if r1 <= 0 or r2 <= 0 then
        return "错误：半径必须为正数"
    end
    -- special case coinciding circles
    if x1 == x2 and y1 == y2 and r1 == r2 then
        return "两圆重合"
    end
    local d, a, h, m, n, xj1, xj2, yj1, yj2, dj, e
    -- center distance
    d = fn(math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2))
    -- determine relation
    -- circles separate
    if d > (r1 + r2) then
        return "两圆外离，圆心距为" .. d .. "，无交点"
    elseif d < math.abs(r1 - r2) then
        return "两圆内含，圆心距为" .. d .. "，无交点"
    end
    -- intersecting or tangent compute parameters
    a = (r1 ^ 2 - r2 ^ 2 + d ^ 2) / (2 * d)
    h = math.sqrt(r1 ^ 2 - a ^ 2)
    m = (x2 - x1) / d
    n = (y2 - y1) / d
    -- intersection coordinates
    xj1 = fn(x1 + a * m + h * n)
    yj1 = fn(y1 + a * n - h * m)
    xj2 = fn(x1 + a * m - h * n)
    yj2 = fn(y1 + a * n + h * m)
    e = 1e-8
    -- precision guard against float errors
    if math.abs(xj1) < e then
        xj1 = 0
    end
    if math.abs(yj1) < e then
        yj1 = 0
    end
    if math.abs(xj2) < e then
        xj2 = 0
    end
    if math.abs(yj2) < e then
        yj2 = 0
    end
    -- chord length
    dj = fn(math.sqrt((xj2 - xj1) ^ 2 + (yj2 - yj1) ^ 2))
    -- tangent or intersecting with points center distance and chord
    if d == (r1 + r2) then
        return "两圆外切，圆心距为" .. d .. "\n交点坐标为(" .. xj1 .. "," .. yj1 .. ")"
    elseif d == math.abs(r1 - r2) then
        return "两圆内切，圆心距为" .. d .. "\n交点坐标为(" .. xj1 .. "," .. yj1 .. ")"
    elseif math.abs(r1 - r2) < d and d < (r1 + r2) then
        return "两圆相交，圆心距为" .. d .. "\n交点坐标为(" .. xj1 .. "," .. yj1 .. ")和(" .. xj2 .. "," .. yj2 .. ")\n相交弦弦长为" .. dj
    end
end
calc_methods["tcr1"] = tcr1
methods_desc["tcr1"] = "已知两圆标准方程(x-x₁)²+(y-y₁)²=r₁²和(x-x₂)²+(y-y₂)²=r₂²，判断它们的位置关系"

-- relation of two circles in general form
local function tcr2(D1, E1, F1, D2, E2, F2)
    -- validate arguments
    if type(D1) ~= "number" or type(E1) ~= "number" or type(F1) ~= "number" or type(D2) ~= "number" or type(E2) ~= "number" or type(F2) ~= "number" then
        return "错误：参数必须是数字"
    end
    local x1, y1, x2, y2, r1, r2
    -- centers radii and center distance
    x1 = -D1 / 2
    y1 = -E1 / 2
    x2 = -D2 / 2
    y2 = -E2 / 2
    r1 = math.sqrt(x1 ^ 2 + y1 ^ 2 - F1)
    r2 = math.sqrt(x2 ^ 2 + y2 ^ 2 - F2)
    -- delegate for output
    return tcr1(x1, y1, r1, x2, y2, r2)
end
calc_methods["tcr2"] = tcr2
methods_desc["tcr2"] = "已知两圆一般方程x²+y²+D₁x+E₁y+F₁=0和x²+y²+D₂x+E₂y+F₂=0，判断它们的位置关系"

-- pythagorean triples
local function ggs(...)
    local args = { ... }
    local n = #args
    if n == 0 then
        return "请输入至少一个数"
    elseif n > 2 then
        return "最多只能输入2个数"
    end
    local function generateTriplets(a_param)
        local results = {}
        -- solutions as a leg
        if a_param % 2 == 1 then
            local c = (a_param ^ 2 - 1) / 2
            local d = (a_param ^ 2 + 1) / 2
            local triplet = { a_param, c, d }
            table.sort(triplet)
            table.insert(results, triplet)
        else
            local c = (a_param ^ 2) / 4 - 1
            local d = (a_param ^ 2) / 4 + 1
            local triplet = { a_param, c, d }
            table.sort(triplet)
            table.insert(results, triplet)
        end
        return results
    end
    local function findHypotenuseTriplets(m)
        local results = {}
        local m_squared = m * m
        local max_a = math.floor(m / math.sqrt(2))
        for a = 1, max_a do
            local b_squared = m_squared - a * a
            if b_squared < 0 then break end
            local b = math.sqrt(b_squared)
            if b == math.floor(b) and b > a then
                local triplet = { a, b, m }
                table.sort(triplet)
                table.insert(results, triplet)
            end
        end
        return results
    end
    local function ggs1(a)
        if type(a) ~= "number" or a < 1 or a ~= math.floor(a) then
            return "参数必须是正整数"
        end
        if a % 2 == 1 and a < 3 then
            return "输入1个参数时,奇数须大于等于3"
        elseif a % 2 == 0 and a < 4 then
            return "输入1个参数时,偶数须大于等于4"
        end
        local results = {}
        -- leg solutions
        local legTriplets = generateTriplets(a)
        for _, t in ipairs(legTriplets) do
            table.insert(results, t)
        end
        -- hypotenuse solutions
        local hypoTrplets = findHypotenuseTriplets(a)
        for _, t in ipairs(hypoTrplets) do
            table.insert(results, t)
        end
        -- deduplicate
        local seen = {}
        local unique = {}
        for _, t in ipairs(results) do
            local key = table.concat(t, ',')
            if not seen[key] then
                seen[key] = true
                table.insert(unique, t)
            end
        end
        if #unique == 0 then
            return "无解"
        else
            local parts = {}
            for _, t in ipairs(unique) do
                table.insert(parts, string.format("(%d,%d,%d)", t[1], t[2], t[3]))
            end
            return "勾股数为: " .. table.concat(parts, " 和 ")
        end
    end
    local function ggs2(a, b)
        if type(a) ~= "number" or a < 1 or a ~= math.floor(a) or
            type(b) ~= "number" or b < 1 or b ~= math.floor(b) then
            return "参数必须是正整数"
        end
        if a == b then
            return "两个参数不能相等"
        end
        local results = {}
        -- two numbers as legs find hypotenuse
        local sum_sq = a ^ 2 + b ^ 2
        local c = math.sqrt(sum_sq)
        if c == math.floor(c) then
            local triplet = { a, b, c }
            table.sort(triplet)
            table.insert(results, triplet)
        end
        -- small as leg large as hypotenuse find other leg
        local sq = math.abs(a ^ 2 - b ^ 2)
        local d = math.sqrt(sq)
        if d == math.floor(d) then
            local triplet = { a, b, d }
            table.sort(triplet)
            table.insert(results, triplet)
        end
        -- as generators find triples
        local part1 = math.abs(a ^ 2 - b ^ 2)
        local part2 = 2 * a * b
        local hypo = a ^ 2 + b ^ 2
        local triplet = { part1, part2, hypo }
        table.sort(triplet)
        table.insert(results, triplet)
        -- dedup logic
        local seen = {}
        local unique = {}
        for _, t in ipairs(results) do
            local key = table.concat(t, ",")
            if not seen[key] then
                seen[key] = true
                table.insert(unique, t)
            end
        end
        if #unique == 0 then
            return "无解"
        else
            local parts = {}
            for _, t in ipairs(unique) do
                table.insert(parts, string.format("(%d,%d,%d)", t[1], t[2], t[3]))
            end
            return "勾股数为: " .. table.concat(parts, " 和 ")
        end
    end
    return (n == 1) and ggs1(args[1]) or ggs2(args[1], args[2])
end
calc_methods["ggs"] = ggs
methods_desc["ggs"] = "求解勾股数"

-- batch random number generator
-- mode 1 three args digits count unique 0 true 1 false
-- mode 2 four args min max count unique
local function generateRandomNumbers(...)
    local args = { ... }
    local min, max, count, unique
    -- validate arg count
    if #args ~= 3 and #args ~= 4 then
        return "参数数量必须为3或4"
    end
    -- parse arg mode
    if #args == 3 then
        local digits, count_arg, unique_arg = args[1], args[2], args[3]
        -- validate types and ranges
        if type(digits) ~= "number" or type(count_arg) ~= "number" or type(unique_arg) ~= "number" then
            return "位数、数量和唯一性参数必须为数字"
        elseif digits < 1 or digits ~= math.floor(digits) then
            return "位数必须为正整数"
        elseif digits > 18 then
            return "位数不能超过18位"
        end
        min = 10 ^ (digits - 1)
        max = 10 ^ digits - 1
        if digits == 1 then min = 1 end -- special case one digit
        count = count_arg
        unique = unique_arg
    else
        min, max, count, unique = args[1], args[2], args[3], args[4]
        -- validate values
        if type(min) ~= "number" or type(max) ~= "number" or type(count) ~= "number" then
            return "最小值、最大值和数量必须为数字"
        elseif min ~= math.floor(min) or max ~= math.floor(max) then
            return "最小值、最大值必须为整数"
        end
    end
    -- common validation
    if min > max then
        min, max = max, min -- swap when out of order
    end
    if count < 1 or count ~= math.floor(count) then
        return "数量必须为正整数"
    elseif unique ~= 0 and unique ~= 1 then
        return "控制唯一性的参数必须为0或1"
    elseif unique == 0 and count > (max - min + 1) then
        return "唯一性要求下，数量不能超过范围大小"
    end
    -- table for random numbers
    local result = {}
    -- generate randoms
    if unique == 0 then
        local used = {} -- track generated randoms
        for i = 1, count do
            local num
            repeat
                num = math.random(min, max)
            until not used[num]
            used[num] = true
            result[i] = num
        end
    else
        -- non unique fill directly
        for i = 1, count do
            result[i] = math.random(min, max)
        end
    end
    -- format output
    local formatted = {}
    for i = 1, #result do
        if i > 1 and (i - 1) % 10 == 0 then
            table.insert(formatted, "\n")
        end
        table.insert(formatted, tostring(result[i]))
        if i < #result and i % 10 ~= 0 then
            table.insert(formatted, ",")
        end
    end
    return table.concat(formatted)
end
calc_methods["psjs"] = generateRandomNumbers
methods_desc["psjs"] = "批量随机数"

-- prime factorization with pretty output
local function prime_factorization(n)
    -- validate and limit digits
    if type(n) ~= "number" or n <= 0 or math.floor(n) ~= n then
        return "参数必须是正整数"
    end
    local digits = #tostring(n)
    if digits > 18 then
        return "数字超限! 最大支持18位数字的质因数分解。"
    end
    -- special cases
    if n == 1 then return "1" end
    local factors = {}
    -- factor out twos
    while n % 2 == 0 do
        factors[2] = (factors[2] or 0) + 1
        n = n // 2
    end
    -- odd factors
    local divisor = 3
    local max_divisor = math.floor(math.sqrt(n))
    while divisor <= max_divisor and n > 1 do
        while n % divisor == 0 do
            factors[divisor] = (factors[divisor] or 0) + 1
            n = n // divisor
            max_divisor = math.floor(math.sqrt(n))
        end
        divisor = divisor + 2
    end
    -- remaining n greater than 1 is prime
    if n > 1 then
        factors[n] = (factors[n] or 0) + 1
    end
    -- superscript table digits 0-9
    local superscript_digits = {
        ["0"] = "⁰",
        ["1"] = "¹",
        ["2"] = "²",
        ["3"] = "³",
        ["4"] = "⁴",
        ["5"] = "⁵",
        ["6"] = "⁶",
        ["7"] = "⁷",
        ["8"] = "⁸",
        ["9"] = "⁹"
    }
    -- convert number to superscript any length
    local function to_superscript(num)
        local s = tostring(num)
        local result = ""
        for i = 1, #s do
            local c = s:sub(i, i)
            result = result .. (superscript_digits[c] or c)
        end
        return result
    end
    -- build output string
    local output = {}
    for factor, count in pairs(factors) do
        local str = tostring(factor)
        if count > 1 then
            str = str .. to_superscript(count)
        end
        table.insert(output, str)
    end
    -- sort factors ascending
    table.sort(output, function(a, b)
        local fa = tonumber(a:match("^%d+"))
        local fb = tonumber(b:match("^%d+"))
        return fa < fb
    end)
    return table.concat(output, "×")
end
calc_methods["zys"] = prime_factorization
methods_desc["zys"] = "质因数分解"

-- find primes euler sieve
local function sieve_of_eratosthenes(n)
    if type(n) ~= "number" or n <= 1 or math.floor(n) ~= n then
        return "参数必须是大于1的正整数"
    end
    if n > 26338 then
        return "数字超限!"
    end
    local is_prime = {}
    local primes = {}
    -- init array all prime by default
    for i = 2, n do
        is_prime[i] = true
    end
    -- euler sieve core
    for i = 2, n do
        if is_prime[i] then
            table.insert(primes, i)
        end
        -- mark composites via found primes
        for j = 1, #primes do
            local p = primes[j]
            local composite = i * p
            if composite > n then break end
            is_prime[composite] = false
            -- key optimization mark each composite once by smallest factor
            if i % p == 0 then break end
        end
    end
    -- format output
    local output = {}
    for i = 1, #primes do
        table.insert(output, tostring(primes[i]))
        if (i % 10 == 0) or (i == #primes) then
            table.insert(output, "\n")
        else
            table.insert(output, ",")
        end
    end
    -- drop trailing newline
    if #output > 0 and output[#output] == "\n" then
        output[#output] = nil
    end
    return table.concat(output)
end
calc_methods["zzs"] = sieve_of_eratosthenes
methods_desc["zzs"] = "找质数"

-- 24 points calculator with dedup
local function solve24(...)
    -- check table contains value
    local function table_contains(tab, val)
        for _, value in ipairs(tab) do
            if value == val then
                return true
            end
        end
        return false
    end
    -- random number helper
    local function generate_numbers()
        math.randomseed(os.time())
        local numbers = {}
        local magic_numbers = {} -- new magic number array
        for i = 1, 4 do
            numbers[i] = math.random(1, 13)
            -- magic for 1 is fixed 1
            if numbers[i] == 1 then
                magic_numbers[i] = 1
            else
                local newrd = math.random(1, 40)
                -- keep magics unique
                while table_contains(magic_numbers, newrd) do
                    newrd = math.random(1, 40)
                end
                magic_numbers[i] = newrd
            end
        end
        -- repeated numbers share magic
        for i = 1, 4 do
            for j = i + 1, 4 do
                if numbers[i] == numbers[j] then
                    magic_numbers[j] = magic_numbers[i]
                end
            end
        end
        return numbers, magic_numbers
    end
    -- solution record for dedup
    local hash_solutions = {}
    local solutions = {}
    -- float closeness check
    local function is_close(a, b)
        return math.abs(a - b) < 1e-9
    end
    -- basic operations
    local function compute(a, b, op)
        if op == '+' then
            return a + b
        elseif op == '-' then
            return a - b
        elseif op == '*' then
            return a * b
        elseif op == '/' then
            if b == 0 then return nil end
            return a / b
        end
    end
    -- compute magics
    local function compute_magic(a, b, op, magic_a, magic_b)
        if op == '+' then
            return magic_a + magic_b
        elseif op == '-' then
            return magic_a - magic_b
        elseif op == '*' then
            return magic_a * magic_b
        elseif op == '/' then
            if magic_b == 0 then return 999999999 end -- avoid divide by zero
            return magic_a / magic_b
        end
    end
    -- permutation helper
    local function permute(t)
        local result = {}
        local function permute_helper(current, remaining)
            if #remaining == 0 then
                table.insert(result, { table.unpack(current) })
            else
                for i = 1, #remaining do
                    local new_current = { table.unpack(current) }
                    table.insert(new_current, remaining[i])
                    local new_remaining = {}
                    for j = 1, #remaining do
                        if j ~= i then
                            table.insert(new_remaining, remaining[j])
                        end
                    end
                    permute_helper(new_current, new_remaining)
                end
            end
        end
        permute_helper({}, t)
        return result
    end
    -- add solution with dedup
    local function add_solution(expr, value, magic_value)
        if is_close(value, 24) then
            -- check magic exists
            local is_duplicate = false
            local replace_index = -1
            for i, hash in ipairs(hash_solutions) do
                if math.abs(magic_value - hash) / (math.abs(magic_value) + 1e-9) < 1e-3 then
                    is_duplicate = true
                    replace_index = i
                    break
                end
            end
            if not is_duplicate then
                -- new solution add to list
                table.insert(solutions, expr)
                table.insert(hash_solutions, magic_value)
            else
                -- maybe replace with better solution
                local need_replace = false
                local existing_expr = solutions[replace_index]
                -- compare bracket count
                local current_brackets = expr:gsub("[^%(%)]", ""):len()
                local existing_brackets = existing_expr:gsub("[^%(%)]", ""):len()
                if current_brackets < existing_brackets then
                    need_replace = true
                    -- same brackets compare minus count
                elseif current_brackets == existing_brackets then
                    local current_minus = expr:gsub("[^-]", ""):len()
                    local existing_minus = existing_expr:gsub("[^-]", ""):len()
                    if current_minus < existing_minus then
                        need_replace = true
                        -- same minus compare divide count
                    elseif current_minus == existing_minus then
                        local current_div = expr:gsub("[^/÷]", ""):len()
                        local existing_div = existing_expr:gsub("[^/÷]", ""):len()
                        if current_div < existing_div then
                            need_replace = true
                            -- same divide compare lexicographically
                        elseif current_div == existing_div and expr < existing_expr then
                            need_replace = true
                        end
                    end
                end
                if need_replace then
                    solutions[replace_index] = expr
                    hash_solutions[replace_index] = magic_value
                end
            end
        end
    end
    -- core 24 points solver
    local function solve_24_with_magic(numbers, magic_numbers)
        local operators = { '+', '-', '*', '/' }
        local perms = permute(numbers)
        local magic_perms = permute(magic_numbers) -- magic permutations
        -- iterate all permutations
        for i, nums in ipairs(perms) do
            local magics = magic_perms[i]
            if magics then
                for _, op1 in ipairs(operators) do
                    for _, op2 in ipairs(operators) do
                        for _, op3 in ipairs(operators) do
                            -- case 1 ((a op1 b) op2 c) op3 d
                            local v1 = compute(nums[1], nums[2], op1)
                            local m1 = compute_magic(nums[1], nums[2], op1, magics[1], magics[2])
                            if v1 and m1 then
                                local v2 = compute(v1, nums[3], op2)
                                local m2 = compute_magic(v1, nums[3], op2, m1, magics[3])
                                if v2 and m2 then
                                    local v3 = compute(v2, nums[4], op3)
                                    local m3 = compute_magic(v2, nums[4], op3, m2, magics[4])
                                    if v3 and m3 then
                                        local expr = string.format("((%d%s%d)%s%d)%s%d", nums[1], op1, nums[2], op2,
                                            nums[3], op3, nums[4])
                                        add_solution(expr, v3, m3)
                                    end
                                end
                            end
                            -- case 2 (a op1 (b op2 c)) op3 d
                            local v1 = compute(nums[2], nums[3], op2)
                            local m1 = compute_magic(nums[2], nums[3], op2, magics[2], magics[3])
                            if v1 and m1 then
                                local v2 = compute(nums[1], v1, op1)
                                local m2 = compute_magic(nums[1], v1, op1, magics[1], m1)
                                if v2 and m2 then
                                    local v3 = compute(v2, nums[4], op3)
                                    local m3 = compute_magic(v2, nums[4], op3, m2, magics[4])
                                    if v3 and m3 then
                                        local expr = string.format("(%d%s(%d%s%d))%s%d", nums[1], op1, nums[2], op2,
                                            nums[3], op3, nums[4])
                                        add_solution(expr, v3, m3)
                                    end
                                end
                            end
                            -- case 3 a op1 ((b op2 c) op3 d)
                            local v1 = compute(nums[2], nums[3], op2)
                            local m1 = compute_magic(nums[2], nums[3], op2, magics[2], magics[3])
                            if v1 and m1 then
                                local v2 = compute(v1, nums[4], op3)
                                local m2 = compute_magic(v1, nums[4], op3, m1, magics[4])
                                if v2 and m2 then
                                    local v3 = compute(nums[1], v2, op1)
                                    local m3 = compute_magic(nums[1], v2, op1, magics[1], m2)
                                    if v3 and m3 then
                                        local expr = string.format("%d%s((%d%s%d)%s%d)", nums[1], op1, nums[2], op2,
                                            nums[3], op3, nums[4])
                                        add_solution(expr, v3, m3)
                                    end
                                end
                            end
                            -- case 4 a op1 (b op2 (c op3 d))
                            local v1 = compute(nums[3], nums[4], op3)
                            local m1 = compute_magic(nums[3], nums[4], op3, magics[3], magics[4])
                            if v1 and m1 then
                                local v2 = compute(nums[2], v1, op2)
                                local m2 = compute_magic(nums[2], v1, op2, magics[2], m1)
                                if v2 and m2 then
                                    local v3 = compute(nums[1], v2, op1)
                                    local m3 = compute_magic(nums[1], v2, op1, magics[1], m2)
                                    if v3 and m3 then
                                        local expr = string.format("%d%s(%d%s(%d%s%d))", nums[1], op1, nums[2], op2,
                                            nums[3], op3, nums[4])
                                        add_solution(expr, v3, m3)
                                    end
                                end
                            end
                            -- case 5 (a op1 b) op2 (c op3 d)
                            local v1 = compute(nums[1], nums[2], op1)
                            local m1 = compute_magic(nums[1], nums[2], op1, magics[1], magics[2])
                            local v2 = compute(nums[3], nums[4], op3)
                            local m2 = compute_magic(nums[3], nums[4], op3, magics[3], magics[4])
                            if v1 and m1 and v2 and m2 then
                                local v3 = compute(v1, v2, op2)
                                local m3 = compute_magic(v1, v2, op2, m1, m2)
                                if v3 and m3 then
                                    local expr = string.format("(%d%s%d)%s(%d%s%d)", nums[1], op1, nums[2], op2, nums[3],
                                        op3, nums[4])
                                    add_solution(expr, v3, m3)
                                end
                            end
                        end
                    end
                end
            end
        end
        return solutions
    end
    -- handle arguments
    local arg = { ... }
    if #arg == 0 then
        -- no args generate randoms
        local numbers, magic_numbers = generate_numbers()
        return "生成的随机数: " .. table.concat(numbers, ", ")
    elseif #arg == 4 then
        -- four args must be integers 1 to 13
        for i, num in ipairs(arg) do
            if type(num) ~= "number" or num < 1 or num > 13 or num ~= math.floor(num) then
                return "错误：请输入4个1到13之间的整数。"
            end
        end
        -- magics for given numbers
        local magic_numbers = {}
        for i, num in ipairs(arg) do
            if num == 1 then
                magic_numbers[i] = 1
            else
                local newrd = math.random(1, 40)
                while table_contains(magic_numbers, newrd) do
                    newrd = math.random(1, 40)
                end
                magic_numbers[i] = newrd
            end
        end
        -- handle repeated numbers
        for i = 1, 4 do
            for j = i + 1, 4 do
                if arg[i] == arg[j] then
                    magic_numbers[j] = magic_numbers[i]
                end
            end
        end
        -- solve 24 points
        local solutions = solve_24_with_magic(arg, magic_numbers)
        if #solutions == 0 then
            return "没有找到解决方案。"
        else
            return "共找到" .. #solutions .. "种解决方案:\n" .. table.concat(solutions, "\n")
        end
    else
        return "错误：请输入4个数字或者不输入参数以生成随机数。"
    end
end
calc_methods["tfp"] = solve24
methods_desc["tfp"] = "24点计算器"

-- unit conversion
-- units are string args quote them single or double not mixed
-- otherwise wrong arg type gives no result
local function dwhs(value, from_unit, to_unit)
    -- conversion factor table
    local conversion_factors = {
        -- length relative to meter
        ai = 1e-10,          -- angstrom
        nm = 1e-9,           -- nanometer
        wm = 1e-6,           -- micrometer
        mm = 1e-3,           -- millimeter
        cm = 0.01,           -- centimeter
        dm = 0.1,            -- decimeter
        m = 1,               -- meter
        km = 1e3,            -- kilometer
        li = 500,            -- li
        yc = 0.0254,         -- inch
        ft = 0.3048,         -- foot
        mile = 1609.344,     -- mile
        nmi = 1852,          -- nautical mile
        zhang = 10 / 3,      -- zhang
        chi = 1 / 3,         -- chi
        cun = 1 / 30,        -- cun
        fen = 1 / 300,       -- fen
        -- area relative to square meter
        mm2 = 1e-6,          -- square millimeter
        cm2 = 1e-4,          -- square centimeter
        dm2 = 1e-2,          -- square decimeter
        m2 = 1,              -- square meter
        km2 = 1e6,           -- square kilometer
        pfyl = 2589988.1103, -- square mile
        hm2 = 1e4,           -- hectare
        sq = 2e5 / 3,        -- shi qing
        acre = 4046.8648,    -- acre
        sm = 2000 / 3,       -- shi mu
        gm = 100,            -- are
        -- volume relative to cubic meter
        wl = 1e-9,           -- microliter
        mm3 = 1e-9,          -- cubic millimeter
        ml = 1e-6,           -- milliliter
        cm3 = 1e-6,          -- cubic centimeter
        cl = 1e-5,           -- centiliter
        dl = 1e-4,           -- deciliter
        l = 1e-3,            -- liter
        dm3 = 1e-3,          -- cubic decimeter
        hl = 0.1,            -- hectoliter
        m3 = 1,              -- cubic meter
        ygl = 4.5461e-3,     -- imperial gallon
        mgl = 3.78541e-3,    -- us gallon
        km3 = 1e9,           -- cubic kilometer
        -- mass relative to gram
        wg = 1e-6,           -- microgram
        mg = 1e-3,           -- milligram
        g = 1,               -- gram
        kg = 1e3,            -- kilogram
        t = 1e6,             -- tonne
        lb = 453.59237,      -- pound
        oz = 28.349523125,   -- ounce
        ct = 0.2,            -- carat
        gd = 1e5,            -- quintal
        sd = 5e4,            -- shi dan
        jin = 500,           -- jin
        liang = 50,          -- liang
        qian = 5,            -- qian
        dr = 1.771845195,    -- dram
        gr = 0.06479891,     -- grain
    }
    -- validate value
    if type(value) ~= "number" or value <= 0 then
        return "错误: 第一个参数必须是有效的正数"
    end
    -- validate units
    if not conversion_factors[from_unit] then
        return "错误: 未知的原单位 '" .. tostring(from_unit) .. "'"
    end
    if not conversion_factors[to_unit] then
        return "错误: 未知的目标单位 '" .. tostring(to_unit) .. "'"
    end
    -- number to superscript chars
    local function to_superscript(num)
        local superscripts = { "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹" }
        local minus = "⁻"
        local str = tostring(num)
        local result = ""
        -- handle minus sign
        if str:sub(1, 1) == "-" then
            result = minus
            str = str:sub(2)
        end
        -- strip leading zeros unless single 0
        str = str:gsub("^0+(%d)", "%1")
        if str == "" then str = "0" end
        -- convert digits
        for digit in str:gmatch("%d") do
            result = result .. superscripts[tonumber(digit) + 1]
        end
        return result
    end
    -- format scientific notation with superscript
    local function format_scientific(num)
        local formatted = string.format("%.6e", num)
        local mantissa, exponent = string.match(formatted, "^(.-)e([%+%-]%d+)$")
        mantissa = mantissa:gsub("%.?0+$", ""):gsub("%.$", "")
        -- drop plus before exponent
        exponent = exponent:gsub("^%+", "")
        return mantissa .. "×10" .. to_superscript(exponent)
    end
    -- decide scientific notation
    local function should_use_scientific(num)
        local abs_num = math.abs(num)
        -- use scientific for >=1e5 or <=1e-3
        if abs_num >= 1e5 or (abs_num <= 1e-3 and abs_num > 0) then
            return true
        end
        -- check integer digit count
        local int_part = math.floor(abs_num)
        if int_part == 0 then
            -- check leading zeros of fraction
            local decimal_str = string.format("%.10f", abs_num - int_part)
            local leading_zeros = 0
            for i = 3, #decimal_str do
                if decimal_str:sub(i, i) == "0" then
                    leading_zeros = leading_zeros + 1
                else
                    break
                end
            end
            return leading_zeros >= 3
        else
            return (math.log10(int_part) + 1) > 4
        end
    end
    -- format number output
    local function format_number(num)
        if should_use_scientific(num) then
            return format_scientific(num)
        else
            return string.format("%.6f", num):gsub("%.?0+$", ""):gsub("%.$", "")
        end
    end
    -- perform conversion
    local result = value * (conversion_factors[from_unit] / conversion_factors[to_unit])
    -- format output
    local formatted_result = format_number(result)
    -- show result
    return formatted_result
end
calc_methods["dwhs"] = dwhs
methods_desc["dwhs"] = "单位换算，支持面积、质量、长度、体积，(数字, '原单位', '目标单位')"

-- number base conversion
-- quote non decimal numbers containing letters single or double not mixed
-- otherwise no result
local function convertBase(...)
    local args = { ... }
    local number, fromBase, toBase
    -- handle arg count
    if #args == 3 then
        number, fromBase, toBase = args[1], args[2], args[3]
    elseif #args == 2 then
        number, toBase = args[1], args[2]
        fromBase = 10 -- default source base 10
    else
        return "参数数量必须为2或3"
    end
    -- validate bases
    if type(fromBase) ~= "number" or type(toBase) ~= "number" then
        return "进制必须是数字类型"
    end
    if fromBase < 2 or fromBase > 36 or toBase < 2 or toBase > 36 then
        return "进制范围必须在2到36之间"
    end
    local number = tostring(number)
    -- validate number format
    local sign = 1
    local integerPart, fractionalPart
    -- handle sign
    if string.sub(number, 1, 1) == '-' then
        sign = -1
        number = string.sub(number, 2)
    elseif string.sub(number, 1, 1) == '+' then
        number = string.sub(number, 2)
    end
    -- split integer and fraction
    local dotPos = string.find(number, '%.')
    if dotPos then
        integerPart = string.sub(number, 1, dotPos - 1)
        fractionalPart = string.sub(number, dotPos + 1)
    else
        integerPart = number
        fractionalPart = ""
    end
    -- digit charset
    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    -- helper char to value
    local function charToValue(c)
        return string.find(digits, string.upper(c), 1, true) - 1
    end
    -- helper value to char
    local function valueToChar(v)
        return string.sub(digits, v + 1, v + 1)
    end
    -- integer part source base to decimal
    local decimalInteger = 0
    for i = 1, #integerPart do
        local c = string.sub(integerPart, i, i)
        local v = charToValue(c)
        if v == -1 or v >= fromBase then
            return "数字中包含无效字符或超出原进制范围"
        end
        decimalInteger = decimalInteger * fromBase + v
    end
    -- fraction part source base to decimal
    local decimalFraction = 0
    local multiplier = 1 / fromBase
    for i = 1, #fractionalPart do
        local c = string.sub(fractionalPart, i, i)
        local v = charToValue(c)
        if v == -1 or v >= fromBase then
            return "数字中包含无效字符或超出原进制范围"
        end
        decimalFraction = decimalFraction + v * multiplier
        multiplier = multiplier / fromBase
    end
    -- integer part decimal to target base
    local targetInteger = {}
    local n = math.abs(decimalInteger)
    if n == 0 then
        targetInteger[1] = '0'
    else
        local i = 0
        while n > 0 do
            i = i + 1
            targetInteger[i] = valueToChar(n % toBase)
            n = math.floor(n / toBase)
        end
        -- reverse array
        for j = 1, math.floor(i / 2) do
            targetInteger[j], targetInteger[i - j + 1] = targetInteger[i - j + 1], targetInteger[j]
        end
    end
    -- fraction part decimal to target base 10 digits precision
    local targetFraction = {}
    local f = decimalFraction
    local maxFractionDigits = 10
    if f > 0 then
        targetFraction[1] = '.'
        local i = 1
        while f > 0 and i <= maxFractionDigits do
            f = f * toBase
            local intPart = math.floor(f)
            targetFraction[i + 1] = valueToChar(intPart)
            f = f - intPart
            i = i + 1
        end
    end
    -- combine result
    local result = {}
    if sign == -1 then
        result[#result + 1] = '-'
    end
    for i = 1, #targetInteger do
        result[#result + 1] = targetInteger[i]
    end
    for i = 1, #targetFraction do
        result[#result + 1] = targetFraction[i]
    end
    return table.concat(result)
end
calc_methods["jzzh"] = convertBase
methods_desc["jzzh"] = "数字进制转换，支持2~36进制，(数字, 原进制, 目标进制)"

-- simple calculator
function T.func(input, seg, env)
    local composition = env.engine.context.composition
    if composition:empty() then return end
    local segment = composition:back()

    if startsWith(input, T.prefix) or (seg:has_tag("calculator")) then
        segment.prompt = "〔" .. T.tips .. "〕"
        segment.tags = segment.tags + Set({ "calculator" })
        -- extract expression
        local express = input:gsub(T.prefix, ""):gsub("^/vs", "")
        -- expression shorter than 2 stop early
        if (string.len(express) < 2) and (not calc_methods[express]) then return end
        if (string.len(express) == 2) and (express:match("^%d[^%!]$")) then return end
        local code = replaceToFactorial(express)

        local loaded_func, load_error = load("return " .. code, "calculate", "t", calc_methods)
        if loaded_func and (type(methods_desc[code]) == "string") then
            yield(Candidate(input, seg.start, seg._end, express .. ":" .. methods_desc[code], ""))
        elseif loaded_func then
            local success, result = pcall(loaded_func)
            if success then
                yield(Candidate(input, seg.start, seg._end, tostring(result), ""))
                yield(Candidate(input, seg.start, seg._end, express .. "=" .. tostring(result), ""))
            else
                -- handle runtime errors
                yield(Candidate(input, seg.start, seg._end, express, "执行错误"))
            end
        else
            -- handle load errors
            yield(Candidate(input, seg.start, seg._end, express, "解析失败"))
        end
    end
end

return T
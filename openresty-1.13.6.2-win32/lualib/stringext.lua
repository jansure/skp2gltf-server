--- 函数：拆分出单个字符
local function stringToChars(str)
    if type(str) ~= "string" then
        return str
    end
    -- 主要用了Unicode(UTF-8)编码的原理分隔字符串
    -- 简单来说就是每个字符的第一位定义了该字符占据了多少字节
    -- UTF-8的编码：它是一种变长的编码方式
    -- 对于单字节的符号，字节的第一位设为0，后面7位为这个符号的unicode码。因此对于英语字母，UTF-8编码和ASCII码是相同的。
    -- 对于n字节的符号（n>1），第一个字节的前n位都设为1，第n+1位设为0，后面字节的前两位一律设为10。
    -- 剩下的没有提及的二进制位，全部为这个符号的unicode码。
    local list = {}
    local len = string.len(str)
    local i = 1
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i + shift - 1)
        i = i + shift
        table.insert(list, char)
    end
    return list, len
end

--- 函数：判断字符(UTF-8编码)是否为中文、韩文、日文
local function isCJKCode(char)
    if type(char) ~= "string" then
        return false
    end
    local len = string.len(char)
    local chInt = 0
    for i = 1, len do
        local n = string.byte(char, i)
        chInt = chInt * 256 + n
    end
    return (chInt >= 14858880 and chInt <= 14860191)
            or (chInt >= 14860208 and chInt <= 14910399)
            or (chInt >= 14910592 and chInt <= 14911167)
            or (chInt >= 14911360 and chInt <= 14989247)
            or (chInt >= 14989440 and chInt <= 15318719)
            or (chInt >= 15380608 and chInt <= 15572655)
            or (chInt >= 15705216 and chInt <= 15707071)
            or (chInt >= 15710384 and chInt <= 15710607)
end

local _M = {
    _VERSION = '0.01',
    stringToChars = stringToChars,
    isCJKCode = isCJKCode,
}

return _M
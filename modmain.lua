local _G = GLOBAL
local jsonUtil = require "json"

-- ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
-- 如果你想自定义服务器地址，请修改这里的HOST，建议使用https
HOST = 'http://127.0.0.1:5562'
-- 🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟
-- ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

--[[
如果你只是本地部署，无需在意下面两条
科雷对访问公网做了限制，现在的http请求仅能访问本地回环地址(localhost, 127.0.0.1)
如果想要访问公网服务地址，可在创意工坊搜索: QueryServer Fix
]]

-- 下面是源代码
-- 想看懂但是看不懂，或者有其他问题，或者没有问题只是想叨叨嗑
-- 都请随时联系我 ling abc1514671906@163.com
-- 两端代码均开源在 https://github.com/LingLambda 欢迎pr和issue
-- ❤️社区你我共创❤️

-- 相关配置
IS_PREFIX = GetModConfigData("isPrefix")
IS_SOURCE = GetModConfigData("isSource")
INTERVAL = GetModConfigData("interval")

-- 打印日志
local function log(log)
    if GetModConfigData("isLog") then
        print("[dst to qq]: " .. log)
    end
end

-- qq群消息示例 对象数组
local exampleMsg = {
    {
        -- 0 消息 1 命令
        type = 0,
        -- 主要数据
        data = {
            -- 来源id，群组号
            source = {
                id = 1100,
                name = "神秘小群"
            },
            -- 发送者信息
            sender = {
                -- qq号码
                id = 114588800,
                -- qq用户名
                name = "凌落",
                -- 群昵称 (可选)
                nick = "落落"
            },
            -- 消息是命令类型时会存在head，代表命令的种类，如 save
            head = "",
            -- 消息正文
            content = "大家好啊，我是电棍"
        }
    }
}


-- 发送游戏内消息
local function sendDstMsg(sender, msg, source)
    local sourceName = ""
    if IS_SOURCE then
        sourceName = source.name
    end

    local senderName = "未知玩家"
    if sender.nick then
        senderName = sender.nick
    elseif sender.name then
        senderName = sender.name
    elseif sender.id then
        senderName = sender.id
    end

    _G.TheNet:Announce("💬" .. sourceName .. senderName .. ": " .. msg)
end

-- 运行命令
local function runCommand(name, value)
    if name == "rollback" then
        _G.ExecuteConsoleCommand("c_rollback(" .. value .. ")")
    elseif name == 'reset' then
        _G.ExecuteConsoleCommand("c_regenerateworld()")
    elseif name == 'save' then
        _G.ExecuteConsoleCommand("c_save()")
    elseif name == 'ban' then
        _G.ExecuteConsoleCommand("TheNet:Kick(" .. value .. ") ")
        _G.ExecuteConsoleCommand("TheNet:Ban(" .. value .. ") ")
    else
        log("[执行命令]未知命令: " .. name)
    end
end

-- 获取群组消息回调函数
local function onGetGroupMsgResult(result, isSuccessful, resultCode)
    if resultCode ~= 200 or not result then
        log("[获取群组消息回调]获取消息失败:" .. jsonUtil.encode(result))
        return
    end

    log("[获取群组消息回调]获取消息成功:" .. result)
    local resData = jsonUtil.decode(result)

    if type(resData) ~= "table" then
        log("[获取群组消息回调]解包数据类型错误，期望为 table 实际为" .. type(resData))
        return
    end

    for _, msg in ipairs(resData) do
        local msgType = msg.type
        local data = msg.data
        if msgType == 0 then
            log('收到消息:' .. msg)
            sendDstMsg(data.sender, data.content, data.source)
        elseif msgType == 1 then
            log('收到命令:' .. msg)
            runCommand(data.head, data.contennt)
        end
    end
end


-- 发送群组消息结果回调函数
local function onSendGroupMsgResult(result, isSuccessful, resultCode)
    if resultCode == 200 then
        log("[发送消息到群组]成功")
    else
        log("[发送消息到群组]失败: " .. jsonUtil.encode(result))
    end
end

-- 发送群组消息
local function sendGroupMsg(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    -- 不广播私聊
    if whisper then
        return
    end

    log("收到玩家消息" .. guid .. userid .. name .. prefab .. message)

    local kid = userid
    if kid == nil then
        if _G.ThePlayer ~= nil then
            kid = _G.ThePlayer.userid
        else
            kid = "未知kleiId"
        end
    end

    -- 饥荒消息对象
    local msg = {
        -- 玩家名称
        userName = name,
        -- 角色名称 如 Wendy
        survivorsName = prefab,
        -- 科雷id
        kleiId = kid,
        -- 消息正文
        message = message,
    }

    local body = jsonUtil.encode(msg)
    log('[发送到群聊]:' .. body)
    _G.TheSim:QueryServer(HOST .. '/send_msg', onSendGroupMsgResult, "POST", body)
end

-- 初始化群消息获取轮询任务
AddSimPostInit(
    function(_)
        -- 判断是否服务端
        if not _G.TheNet or not _G.TheNet:GetIsServer() then
            return
        end

        _G.TheWorld:DoPeriodicTask(INTERVAL, function(inst)
            -- 判断是否主世界
            if not inst.ismastershard then
                return
            end

            log('[轮询请求消息]...')
            _G.TheSim:QueryServer(HOST .. '/get_msg', onGetGroupMsgResult, "GET", nil)
        end)
    end)


-- 重写饥荒公屏聊天函数
AddPrefabPostInit("world",
    function(inst)
        local OldNetworking_Say = _G.Networking_Say
        _G.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
            -- 调用原本逻辑
            OldNetworking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)

            -- 判断是否地面服务端
            if not _G.TheNet or not _G.TheNet:GetIsServer() or not inst.ismastershard then
                return
            end

            -- 判断消息前缀
            if IS_PREFIX then
                if string.lower(string.sub(message, 1, 1)) == ":" or string.lower(string.sub(message, 1, 1)) == "：" then
                    message = string.sub(message, 2)
                else
                    return
                end
            end

            sendGroupMsg(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
        end
    end)

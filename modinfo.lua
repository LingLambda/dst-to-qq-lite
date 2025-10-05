name = "DST TO QQ LITE"
description = [[
在QQ群中可以与游戏中互通聊天，反之亦然，搭建使用非常简单，教程见mod主页
可在配置项启用特定消息转发,转发科雷id,开启日志
默认端口为http post 5562
]]
author = " ling , xsluck "
version = "0.0.1"
forumthread = ""
api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

icon_atlas = 'icon.xml'
icon = "icon.tex"

configuration_options =
{
    {
        name = "isPrefix",
        label = "消息前缀",
        hover = "启用时，饥荒聊天中，只有首字符为:的消息才会传到QQ",
        options =
        {
            { description = "禁用", data = false },
            { description = "启用", data = true },
        },
        default = false,
    },
    {
        name = "isSource",
        label = "显示消息来源",
        hover = "启用时，转发到饥荒的消息会显示群名",
        options =
        {
            { description = "禁用", data = false },
            { description = "启用", data = true },
        },
        default = false,
    },
    {
        name = "isLog",
        label = "日志",
        hover = "打印日志便于调试",
        options =
        {
            { description = "禁用", data = false },
            { description = "启用", data = true },
        },
        default = true,
    },
    {
        name = "interval",
        label = "轮询时间间隔",
        hover = "从服务器轮询的时间间隔，越短刷新消息越快，但会造成额外性能损耗，推荐不修改",
        options =
        {
            { description = "1秒", data = 1 },
            { description = "2秒", data = 2 },
            { description = "3秒", data = 3 },
            { description = "4秒", data = 4 },
            { description = "5秒", data = 5 },
            { description = "7秒", data = 7 },
            { description = "10秒", data = 10 },
            { description = "20秒", data = 20 },
            { description = "30秒", data = 30 },
        },
        default = 4,
    }
}

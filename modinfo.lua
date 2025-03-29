name = "双倍掉落"
description = "采集/挖矿/砍树 的物资有几率双倍掉落，默认几率为10%，可自定义。"
author = "Va6gn（郁郁）"
version = "1.0.0"

-- 兼容性
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- 客户端/服务器兼容性
client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

-- 图标
-- icon_atlas = "modicon.xml"
-- icon = "modicon.tex"

-- 配置选项
configuration_options = {
    {
        name = "enable_double_drop",
        label = "启用双倍掉落",
        options = {
            {description = "开启", data = true},
            {description = "关闭", data = false}
        },
        default = true,
    },
    {
        name = "double_drop_chance",
        label = "双倍掉落几率",
        options = {
            {description = "1%", data = 0.01},
            {description = "5%", data = 0.05},
            {description = "10%", data = 0.1},
            {description = "15%", data = 0.15},
            {description = "20%", data = 0.2},
            {description = "25%", data = 0.25},
            {description = "30%", data = 0.3},
            {description = "50%", data = 0.5},
            {description = "100%", data = 1.0}
        },
        default = 0.1,  -- 默认10%几率
    }
} 
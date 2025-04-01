-- 在文件开头添加 DebugLog 函数定义
local function DebugLog(level, ...)
    if level <= 2 then  -- 可以根据需要调整日志级别
        print("[双倍掉落]", ...)
    end
end

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 获取是否启用采集双倍掉落配置
local success_double_drop, ENABLE_DOUBLE_DROP = _G.pcall(function() 
    return GetModConfigData("enable_double_drop") 
end)

-- 配置错误处理
if not success_double_drop then
    ENABLE_DOUBLE_DROP = true
end

-- 获取双倍掉落几率配置
local success_double_drop_chance, DOUBLE_DROP_CHANCE = _G.pcall(function() 
    return GetModConfigData("double_drop_chance") 
end)

-- 配置错误处理
if not success_double_drop_chance then
    DOUBLE_DROP_CHANCE = 0.1  -- 默认10%几率
end


-- 添加采集双倍掉落功能
local function AddDoubleDropHarvest()
    if not ENABLE_DOUBLE_DROP then return end
    
    -- 修改采集行为
    local old_harvest = ACTIONS.HARVEST.fn
    ACTIONS.HARVEST.fn = function(act)
        local result = old_harvest(act)
        
        if result and act.target and act.doer and math.random() < DOUBLE_DROP_CHANCE then
            -- 获取采集物品的预制体
            local loot = nil
            if act.target.components.crop and act.target.components.crop.product then
                loot = act.target.components.crop.product
            elseif act.target.components.harvestable and act.target.components.harvestable.product then
                loot = act.target.components.harvestable.product
            elseif act.target.components.stewer and act.target.components.stewer.product then
                loot = act.target.components.stewer.product
            end
            
            -- 如果找到了预制体，生成额外的物品
            if loot then
                local item = SpawnPrefab(loot)
                if item then
                    local x, y, z = act.doer.Transform:GetWorldPosition()
                    item.Transform:SetPosition(x, y, z)
                    
                    -- 通知玩家
                    if GetModConfigData("show_double_drop_message") then
                        if act.doer.components.talker then
                            act.doer.components.talker:Say("幸运！获得了双倍收获！")
                        end
                    end
                    
                    DebugLog(2, "玩家", act.doer.name, "获得双倍采集物:", loot)
                end
            end
        end
        
        return result
    end
    
    -- 修改采摘行为
    local old_pick = ACTIONS.PICK.fn
    ACTIONS.PICK.fn = function(act)
        local result = old_pick(act)
        
        if result and act.target and act.doer and math.random() < DOUBLE_DROP_CHANCE then
            -- 获取采摘物品的预制体
            local loot = nil
            if act.target.components.pickable and act.target.components.pickable.product then
                loot = act.target.components.pickable.product
            end
            
            -- 如果找到了预制体，生成额外的物品
            if loot then
                local item = SpawnPrefab(loot)
                if item then
                    local x, y, z = act.doer.Transform:GetWorldPosition()
                    item.Transform:SetPosition(x, y, z)
                    
                    -- 通知玩家
                    if GetModConfigData("show_double_drop_message") then
                        if act.doer.components.talker then
                            act.doer.components.talker:Say("幸运！获得了双倍收获！")
                        end
                    end
                    
                    DebugLog(2, "玩家", act.doer.name, "获得双倍采摘物:", loot)
                end
            end
        end
        
        return result
    end
    
    -- 修改挖掘行为
    local old_dig = ACTIONS.DIG.fn
    ACTIONS.DIG.fn = function(act)
        local target = act.target
        local doer = act.doer
        
        -- 记录挖掘前的位置
        local x, y, z = 0, 0, 0
        if target then
            x, y, z = target.Transform:GetWorldPosition()
        end
        
        local result = old_dig(act)
        
        if result and doer and math.random() < DOUBLE_DROP_CHANCE then
            -- 对于挖掘，我们需要查找周围新生成的物品
            local ents = TheSim:FindEntities(x, y, z, 2, nil, {"INLIMBO"})
            local spawned_items = {}
            
            for _, ent in pairs(ents) do
                if ent.prefab and ent:IsValid() and ent.components.inventoryitem and 
                   not ent.components.inventoryitem:IsHeld() then
                    table.insert(spawned_items, ent.prefab)
                end
            end
            
            -- 复制找到的物品
            for _, item_prefab in ipairs(spawned_items) do
                local item = SpawnPrefab(item_prefab)
                if item then
                    local px, py, pz = doer.Transform:GetWorldPosition()
                    item.Transform:SetPosition(px, py, pz)
                end
            end
            
            if #spawned_items > 0 and doer.components.talker then
                -- 修改挖掘行为的消息显示
                if GetModConfigData("show_double_drop_message") then
                    doer.components.talker:Say("幸运！获得了双倍收获！")
                end
                DebugLog(2, "玩家", doer.name, "获得双倍挖掘物")
            end
        end
        
        return result
    end
    
    -- 修改砍伐行为
    local old_chop = ACTIONS.CHOP.fn
    ACTIONS.CHOP.fn = function(act)
        local target = act.target
        local doer = act.doer
        
        -- 记录砍伐前的位置和预制体名称
        local x, y, z = 0, 0, 0
        local target_prefab = ""
        if target then
            x, y, z = target.Transform:GetWorldPosition()
            target_prefab = target.prefab
        end
        
        -- 执行原始砍伐动作
        local result = old_chop(act)
        
        -- 如果砍伐成功且随机数小于双倍掉落几率
        if result and doer and math.random() < DOUBLE_DROP_CHANCE then
            -- 延迟一帧检查掉落物
            doer:DoTaskInTime(0.1, function()
                -- 对于砍伐，查找周围新生成的物品
                local ents = TheSim:FindEntities(x, y, z, 3, nil, {"INLIMBO"})
                local spawned_items = {}
                
                for _, ent in pairs(ents) do
                    if ent.prefab and ent:IsValid() and ent.components.inventoryitem and 
                       not ent.components.inventoryitem:IsHeld() then
                        table.insert(spawned_items, ent.prefab)
                    end
                end
                
                -- 复制找到的物品
                for _, item_prefab in ipairs(spawned_items) do
                    local item = SpawnPrefab(item_prefab)
                    if item then
                        local px, py, pz = doer.Transform:GetWorldPosition()
                        item.Transform:SetPosition(px, py, pz)
                    end
                end
                
                if #spawned_items > 0 and doer.components.talker then
                    -- 修改砍伐行为的消息显示
                    if GetModConfigData("show_double_drop_message") then
                        doer.components.talker:Say("幸运！获得了双倍收获！")
                    end
                    DebugLog(2, "玩家", doer.name, "获得双倍砍伐物", target_prefab)
                end
            end)
        end
        
        return result
    end
    
    -- 修改采矿行为
    local old_mine = ACTIONS.MINE.fn
    ACTIONS.MINE.fn = function(act)
        local target = act.target
        local doer = act.doer
        
        -- 记录采矿前的位置和预制体名称
        local x, y, z = 0, 0, 0
        local target_prefab = ""
        if target then
            x, y, z = target.Transform:GetWorldPosition()
            target_prefab = target.prefab
        end
        
        -- 执行原始采矿动作
        local result = old_mine(act)
        
        -- 如果采矿成功且随机数小于双倍掉落几率
        if result and doer and math.random() < DOUBLE_DROP_CHANCE then
            -- 延迟一帧检查掉落物
            doer:DoTaskInTime(0.1, function()
                -- 对于采矿，查找周围新生成的物品
                local ents = TheSim:FindEntities(x, y, z, 3, nil, {"INLIMBO"})
                local spawned_items = {}
                
                for _, ent in pairs(ents) do
                    if ent.prefab and ent:IsValid() and ent.components.inventoryitem and 
                       not ent.components.inventoryitem:IsHeld() then
                        table.insert(spawned_items, ent.prefab)
                    end
                end
                
                -- 复制找到的物品
                for _, item_prefab in ipairs(spawned_items) do
                    local item = SpawnPrefab(item_prefab)
                    if item then
                        local px, py, pz = doer.Transform:GetWorldPosition()
                        item.Transform:SetPosition(px, py, pz)
                    end
                end
                
                if #spawned_items > 0 and doer.components.talker then
                    -- 修改采矿行为的消息显示
                    if GetModConfigData("show_double_drop_message") then
                        doer.components.talker:Say("幸运！获得了双倍收获！")
                    end
                    DebugLog(2, "玩家", doer.name, "获得双倍采矿物", target_prefab)
                end
            end)
        end
        
        return result
    end
    
    DebugLog(1, "双倍掉落功能已启用，几率:", DOUBLE_DROP_CHANCE * 100, "%")
end

-- 在mod初始化时调用双倍掉落功能
AddDoubleDropHarvest()
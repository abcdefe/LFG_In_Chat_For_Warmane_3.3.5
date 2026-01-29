-- 插件初始化
local addonName = "_LFG_In_Chat"
local frame = CreateFrame("Frame", "LFGCFrame", UIParent)

-- 默认配置
local defaultConfig = {
    enabled = false,
    filterWords = {},
    highlightEnabled = true  -- 新增: 高亮开关
}

-- 插件加载
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- 当前区域标识
local isInDalaran = false

-- 玩家阵营语言
local playerLanguage = nil

-- 达拉然区域名称(中英文)
local dalaranZones = {
    ["达拉然"] = true,
    ["Dalaran"] = true,
}

-- 检查是否在达拉然
local function CheckDalaranZone()
    local zone = GetRealZoneText()
    isInDalaran = dalaranZones[zone] or false
    return isInDalaran
end

-- 获取玩家阵营语言
local function UpdatePlayerLanguage()
    playerLanguage = GetDefaultLanguage("player")
end

-- 检查消息是否包含关注词,并返回匹配的关注词
local function GetMatchedFilterWords(msg)
    
    
    local lowerMsg = string.lower(msg)
    local matchedWords = {}
    
    for _, word in pairs(LFG_DB_ROLE.filterWords) do
        if word and word ~= "" then
            local lowerWord = string.lower(word)
            if string.find(lowerMsg, lowerWord, 1, true) then
                table.insert(matchedWords, word)
            end
        end
    end
    
    return #matchedWords > 0 and matchedWords or nil
end

-- 检查关注词列表是否为空
local function IsFilterWordsEmpty(msg)
    if not LFG_DB_ROLE or not LFG_DB_ROLE.filterWords then
        return true
    end
    local words = LFG_DB_ROLE.filterWords
    return #words == 0
end

-- 高亮消息中的关注词
local function HighlightFilterWords(msg, matchedWords)
    if not matchedWords or #matchedWords == 0 then
        return msg
    end
    
    local highlightedMsg = msg
    
    -- 对每个匹配的关注词进行高亮处理
    for _, word in ipairs(matchedWords) do
        -- 使用不区分大小写的替换
        local pattern = word:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- 转义特殊字符
        
        -- 查找所有匹配位置并替换
        local function replaceIgnoreCase(text)
            local result = ""
            local lastPos = 1
            local lowerText = string.lower(text)
            local lowerWord = string.lower(word)
            
            while true do
                local startPos, endPos = string.find(lowerText, lowerWord, lastPos, true)
                if not startPos then
                    result = result .. string.sub(text, lastPos)
                    break
                end
                
                -- 添加匹配前的文本
                result = result .. string.sub(text, lastPos, startPos - 1)
                -- 添加高亮的匹配文本
                local matchedText = string.sub(text, startPos, endPos)
                result = result .. "|cff00ff00" .. matchedText .. "|r"
                
                lastPos = endPos + 1
            end
            
            return result
        end
        
        highlightedMsg = replaceIgnoreCase(highlightedMsg)
    end
    
    return highlightedMsg
end

-- 聊天关注函数 - 综合频道(global)
local function ChatFilterChannel(self, event, msg, author, language, ...)
    -- 检查功能是否启用
    if not LFG_DB_ROLE or not LFG_DB_ROLE.enabled then
        return false, msg, author, language, ...
    end
    
    -- 检查是否在达拉然
    if not isInDalaran then
        return false, msg, author, language, ...
    end
    
    -- 检查关注词列表是否为空
    if IsFilterWordsEmpty() then
        return false, msg, author, language, ...
    end

    -- 检查是否包含关注词
    local matchedWords = GetMatchedFilterWords(msg)
    if matchedWords then
        -- 如果启用了高亮功能,修改消息并显示
        if LFG_DB_ROLE.highlightEnabled then
            local highlightedMsg = HighlightFilterWords(msg, matchedWords)
            return false, highlightedMsg, author, language, ...
        else
            -- 否则直接关注
            return false, msg, author, language, ...
        end
    end

    return true
end

-- 聊天关注函数 - 大喊频道
local function ChatFilterYell(self, event, msg, author, language, ...)
    -- 检查功能是否启用
    if not LFG_DB_ROLE or not LFG_DB_ROLE.enabled then
        return false, msg, author, language, ...
    end
    
    -- 检查是否在达拉然
    if not isInDalaran then
        return false, msg, author, language, ...
    end
    
    -- 大喊频道需要判断阵营
    -- 如果语言与玩家不同,说明是对立阵营,关注掉
    if language and playerLanguage and language ~= playerLanguage then
        return true
    end

    -- 检查关注词列表是否为空
    if IsFilterWordsEmpty() then
        return false, msg, author, language, ...
    end
    
    -- 检查是否包含关注词
    local matchedWords = GetMatchedFilterWords(msg)
    if matchedWords then
        -- 如果启用了高亮功能,修改消息并显示
        if LFG_DB_ROLE.highlightEnabled then
            local highlightedMsg = HighlightFilterWords(msg, matchedWords)
            return false, highlightedMsg, author, language, ...
        else
            -- 否则直接关注
            return false, msg, author, language, ...
        end
    end
    
    return true
end

-- 注册聊天频道关注
local function RegisterChatFilters()
    -- global频道使用通用关注
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilterChannel)
    -- 大喊频道使用阵营关注
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilterYell)
end

-- 初始化UI
local function InitializeUI()
    local configFrame = ChatFilterConfigFrame
    if not configFrame then return end
    
    -- 设置背景颜色
    configFrame:SetBackdropColor(0, 0, 0, 1)
    
    -- 设置可拖动
    configFrame:RegisterForDrag("LeftButton")
    
    -- 获取UI元素
    local enableCheckbox = ChatFilterConfigFrameEnableCheckbox
    local highlightCheckbox = ChatFilterConfigFrameHighlightCheckbox
    local inputBox = ChatFilterConfigFrameInputBox
    local addButton = ChatFilterConfigFrameAddButton
    local closeButton = ChatFilterConfigFrameCloseButton
    local scrollFrame = ChatFilterConfigFrameScrollFrame
    local scrollChild = ChatFilterConfigFrameScrollFrameScrollChild
    local zoneText = ChatFilterConfigFrameZoneFrameZoneText
    local factionText = ChatFilterConfigFrameFactionFrameFactionText
    local infoText = ChatFilterConfigFrameInfoFrameInfoText
    
    -- 设置说明文本
    infoText:SetText("关注规则:\n1. Global频道: 关注组队招募和关注词\n2. 大喊频道: 关注对立阵营、组队招募和关注词\n3. 关注词高亮: 高亮显示包含关注词的消息")
    
    -- 启用复选框事件
    enableCheckbox:SetScript("OnClick", function(self)
        LFG_DB_ROLE.enabled = self:GetChecked()
        if LFG_DB_ROLE.enabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 功能已启用")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 功能已禁用")
        end
    end)
    
    -- 高亮复选框事件
    if highlightCheckbox then
        highlightCheckbox:SetScript("OnClick", function(self)
            LFG_DB_ROLE.highlightEnabled = self:GetChecked()
            if LFG_DB_ROLE.highlightEnabled then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 关注词高亮已启用")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 关注词高亮已禁用(将直接关注)")
            end
        end)
    end
    
    -- 添加按钮事件
    addButton:SetScript("OnClick", function()
        local word = inputBox:GetText()
        if word and word ~= "" then
            table.insert(LFG_DB_ROLE.filterWords, word)
            inputBox:SetText("")
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 已添加关注词: " .. word)
            -- 刷新列表
            UpdateFilterWordList()
        end
    end)
    
    -- 回车键添加
    inputBox:SetScript("OnEnterPressed", function(self)
        addButton:Click()
    end)
    
    -- 关闭按钮事件
    closeButton:SetScript("OnClick", function()
        configFrame:Hide()
    end)
    
    -- 框架显示事件
    configFrame:SetScript("OnShow", function()
        enableCheckbox:SetChecked(LFG_DB_ROLE.enabled)
        if highlightCheckbox then
            highlightCheckbox:SetChecked(LFG_DB_ROLE.highlightEnabled)
        end
        
        -- 更新区域显示
        local zone = GetRealZoneText()
        local status = isInDalaran and "|cff00ff00(关注生效)|r" or "|cffff0000(关注不生效)|r"
        zoneText:SetText(zone .. " " .. status)
        
        -- 更新阵营语言显示
        if playerLanguage then
            local factionName = playerLanguage == "Common" and "联盟" or "部落"
            factionText:SetText(playerLanguage .. " (" .. factionName .. ")")
        else
            factionText:SetText("未知")
        end
        
        -- 刷新关注词列表
        UpdateFilterWordList()
    end)
end

-- 更新关注词列表
local listButtons = {}
function UpdateFilterWordList()
    local scrollChild = ChatFilterConfigFrameScrollFrameScrollChild
    if not scrollChild then return end
    
    -- 隐藏所有现有按钮
    for _, btn in ipairs(listButtons) do
        btn:Hide()
    end
    
    if not LFG_DB_ROLE.filterWords then
        return
    end
    
    local yOffset = 0
    for i, word in ipairs(LFG_DB_ROLE.filterWords) do
        if not listButtons[i] then
            -- 创建新的条目框架
            local btn = CreateFrame("Frame", "ChatFilterListItem"..i, scrollChild)
            btn:SetWidth(360)
            btn:SetHeight(30)
            
            -- 背景
            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.bg:SetTexture(0.2, 0.2, 0.2, 0.5)
            
            -- 文本(红色显示)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 10, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetTextColor(1, 0, 0) -- 红色
            
            -- 删除按钮
            btn.deleteBtn = CreateFrame("Button", "ChatFilterDeleteBtn"..i, btn, "UIPanelButtonTemplate")
            btn.deleteBtn:SetPoint("RIGHT", -5, 0)
            btn.deleteBtn:SetWidth(60)
            btn.deleteBtn:SetHeight(24)
            btn.deleteBtn:SetText("删除")
            
            listButtons[i] = btn
        end
        
        local btn = listButtons[i]
        btn:SetPoint("TOPLEFT", 0, -yOffset)
        btn.text:SetText(word)
        btn:Show()
        
        -- 删除按钮点击事件
        btn.deleteBtn:SetScript("OnClick", function()
            table.remove(LFG_DB_ROLE.filterWords, i)
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[聊天关注]|r 已删除关注词: " .. word)
            UpdateFilterWordList()
        end)
        
        yOffset = yOffset + 32
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

-- 事件处理
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- 初始化数据库
        if not LFG_DB_ROLE then
            LFG_DB_ROLE = {}
            LFG_DB_ROLE.enabled = defaultConfig.enabled
            LFG_DB_ROLE.filterWords = {}
            LFG_DB_ROLE.highlightEnabled = defaultConfig.highlightEnabled
        end
        
        -- 兼容旧版本数据
        if LFG_DB_ROLE.highlightEnabled == nil then
            LFG_DB_ROLE.highlightEnabled = true
        end
        
        -- 获取玩家阵营语言
        UpdatePlayerLanguage()
        
        -- 注册聊天关注器
        RegisterChatFilters()
        
        -- 初始化UI
        InitializeUI()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[聊天关注]|r 插件已加载! 输入 /lfgc 打开设置")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckDalaranZone()
        UpdatePlayerLanguage()
        
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        CheckDalaranZone()
    end
end)

-- 斜杠命令
SLASH__LFGINCHAT1 = "/lfgc"
SlashCmdList["_LFGINCHAT"] = function(msg)
    if ChatFilterConfigFrame then
        if ChatFilterConfigFrame:IsShown() then
            ChatFilterConfigFrame:Hide()
        else
            ChatFilterConfigFrame:Show()
        end
    end
end

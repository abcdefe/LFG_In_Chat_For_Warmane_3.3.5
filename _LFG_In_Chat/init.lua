local _, core = ...;

local config, filter = core.Config, core.Filter;

-- 配置界面相关
local Panel = { instance = nil };

function Panel:Init()
    print('===========init=================')
    local instance = CreateFrame('Frame', 'LFG_OptionFrame', UIParent, 'UIPanelScrollFrameTemplate');

    if nil == instance then
        print('eeeeeeeeeeeeeeeeeeeeeeee');
    end

    
    print('===========done=================')

    instance:SetSize(300, 300);
    instance:SetPoint('CENTER', UIParent, 'CENTER');
    
    Panel.instance = instance;
end

function Panel:ToShow()
    print('==========Show==================')
    if nil == Panel.instance then
        Panel:Init();
    end

    print('=========init done==================')

    self.instance:Show();
end

function Panel:Hide()

end

function Panel:Toggle()

end

-- 命令行
local function slashAnalize(str)
    -- 开
    if str == 'on' then
        LFGInChatDB['yell_switch'] = true;
        LFGInChatDB['channel_switch'] = true;
        filter:InitYell();
        filter:InitChannel();
        print('======LFG_In_Chat On======')
        return;
    -- 关
    elseif str == 'off' then
        LFGInChatDB['yell_switch'] = false;
        LFGInChatDB['channel_switch'] = false;
        filter:DestroyYell();
        filter:DestroyChannel();
        print('======LFG_In_Chat Off======')
        return;
    -- 列出过滤词
    elseif str == 'list' then
        local keywordArr, keywordHash = filter:GetKeyword();

        if #keywordArr == 0 then
            print('list keywords is empty');
        else 
            print('list keywords: ' .. table.concat(keywordArr, ', '))
        end
        return;
    -- 添加过滤词
    elseif string.sub(str, 1, 4) == 'add ' then
        local keywordArr, keywordHash = filter:AddKeyword(string.format('%q', string.sub(str, 5)));

        print('list keywords: ' .. table.concat(keywordArr, ', '))
        return;
    -- 删除过滤词
    elseif string.sub(str, 1, 3) == 'rm ' then
        local keywordArr, keywordHash = filter:RemoveKeyword(string.format('%q', string.sub(str, 4)));

        if #keywordArr == 0 then
            print('list keywords is empty');
        else 
            print('list keywords: ' .. table.concat(keywordArr, ', '))
        end
        return;
    elseif str == 'clear' then
        filter:ClearKeyword();

        local keywordArr, keywordHash = filter:GetKeyword();

        if #keywordArr == 0 then
            print('list keywords is empty');
        else 
            print('list keywords: ' .. table.concat(keywordArr, ', '))
        end
        return;
    else
        print('LFGC help:')
        local status_channel = 'off'
        if LFGInChatDB['channel_switch'] then status_channel = 'on' end
        
        print('----------------------------------------------------')
        print('current status is: ' .. status_channel);
        print('type /lfgc on -- for open')
        print('type /lfgc off -- for close')
        print('type /lfgc list -- for keywords list')
        print('type /lfgc add {keywords}-- for filter options add')
        print('type /lfgc rm {keywords}-- for filter options remove')
        print('type /lfgc clear -- for all options clear')
        print('----------------------------------------------------')
    end

    -- Panel:ToShow();
end

SLASH__LFGINCHAT1 = '/lfgc';
SlashCmdList._LFGINCHAT = slashAnalize;

-- 初始化存储信息
local function initVarStore()
    if nil == LFGInChatDB then LFGInChatDB = {} end
    if nil == LFGInChatDB_Role then LFGInChatDB_Role = {} end
end

-- 初始化用户信息
local function initUtilInfo()
    -- 大喊开关
    LFGInChatDB['yell_switch'] = LFGInChatDB['yell_switch'] or false;
    -- 大喊内容过滤开关 暂时未启用
    LFGInChatDB['yell_switch_content'] = LFGInChatDB['yell_switch_content'] or false;

    -- 关键词表
    LFGInChatDB['filter_options'] = LFGInChatDB['filter_options'] or {};

    -- 频道开关
    LFGInChatDB['channel_switch'] = LFGInChatDB['channel_switch'] or false;
end


-- onload event
function ADDON_LOADED() 
    initVarStore();

    initUtilInfo();

    filter:InitYell();
    filter:InitChannel();

    -- local status_yell = 'off'
    -- local status_channel = 'off'
    -- if LFGInChatDB['yell_switch'] then status_yell = 'on' end
    -- if LFGInChatDB['channel_switch'] then status_channel = 'on' end
    
    print(config.WELCOME_TEXT);
end

LFG_IN_CHAT = CreateFrame("Frame")
-- 通过事件进行人物重载，避免联盟部落互相登录导致的信息差
LFG_IN_CHAT:RegisterEvent("ADDON_LOADED");

LFG_IN_CHAT:RegisterEvent("PLAYER_ENTERING_WORLD");

LFG_IN_CHAT:SetScript("OnEvent", function(self, event, name, ...) onEvent(self, event, name, ...) end);

function onEvent(self, event, name, ...)
    if event == "ADDON_LOADED" and name == config.WIDGET_NAME then
        if self.LFGC_LOADED then return end
        ADDON_LOADED();
        self.LFGC_LOADED = true;
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 玩家种族语言
        LFGInChatDB_Role['Language'] = GetDefaultLanguage('player');
    end
end

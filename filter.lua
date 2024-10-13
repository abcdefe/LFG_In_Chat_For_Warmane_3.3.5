local _, core = ...;

core.Filter = {};

local filter, config = core.Filter, core.Config;

local pplLang;

local function initSpamYell(self, event, msg, author, language, ...)
    local pvpStatus = GetZonePVPInfo();

    -- 非当前阵营语言 才进行过滤
    if language ~= pplLang then
        return true;
    else
        return false, msg, author, language, ...;
    end
end

local function initSpamChannel(self,event,msg, author, language, channelName, ...)
    -- 没打开开关
    if LFGInChatDB['channel_switch'] == false then
        return false, msg, author, language, channelName, ...;
    end

    local channelNameUpper = channelName:upper();
    local msgUpper = msg:upper();
    local newMsgCap = '';
    local keywordArr = filter:GetKeyword();

    -- 没有过滤词
    if #keywordArr == 0 then
        return false, msg, author, language, channelName, ...;
    end

    -- 频道不匹配
    if channelNameUpper:find(config.FILTER_CHANNEL_NAME) == nil then
        return false, msg, author, language, channelName, ...;
    end

    -- 过滤指定频道内容
    for i, v in ipairs(keywordArr) do
        local keywordUpper = v:upper();
        if (msgUpper:find(keywordUpper)) then
            newMsgCap = '=' .. keywordUpper .. '=';
            break;
        end
    end

    local newMsg = '';

    if newMsgCap == '' then
        newMsg = msg
        return true;
    else 
        newMsg = (newMsgCap .. ': ' .. msg);
        return false, newMsg, author, language, channelName, ...;
    end

end


-- 初始化喊话
function filter:InitYell()
    if self.YellBind then 
        -- print('inityell loaded')
        return;
    end

    pplLang = LFGInChatDB_Role['Language'];

    self.YellBind = true;

    -- 过滤对立阵营喊话
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", initSpamYell);

end

-- 销毁喊话
function filter:DestroyYell()
    -- if LFGInChatDB['yell_switch'] then return end
    
    -- if self.YellBind then 
    --     -- 过滤对立阵营喊话
    --     ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", initSpamYell);
    --     self.YellBind = false;
    -- end
end

-- 初始化频道
function filter:InitChannel()
    -- if false == LFGInChatDB['channel_switch'] then return end

    if self.ChannelBind then 
        -- print('initchannel loaded'); 
        return;
    end

    -- if #config.FILTER_OPTIONS == 0 then 
    --     print('Empty FILTER_OPTIONS');
    --     print('Use /lfgc add {keyword} to Add Filter Keywords, BLANK use as sperator.')
    --     return;
    -- end

    self.ChannelBind = true;
    
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", initSpamChannel);
end


-- 销毁频道
function filter:DestroyChannel()
    -- if LFGInChatDB['channel_switch'] then return end

    -- if self.ChannelBind then
    --     ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", initSpamChannel);
    --     self.ChannelBind = false;
    -- end
end

--[[ 过滤词相关 ]]
-- 返回过滤词
function filter:GetKeyword()
    local raw = LFGInChatDB['filter_options'];

    local hash = {};

    for i, v in ipairs(raw) do
        -- print('i: ' .. i .. ',v: ' .. v);
        hash[v] = 1;
    end

    return raw, hash;
end

-- 增加过滤词
function filter:AddKeyword(str)
    local len = #LFGInChatDB['filter_options'];

    if len > 10 then
        print('Add Failed. Keyword list has too much');
        return;
    end

    local _, keywordHash = self:GetKeyword();

    for word in string.gmatch(str, "%w+") do 
        if keywordHash[word] == 1 then 
            break;
        end

        keywordHash[word] = 1;
        
        table.insert(LFGInChatDB['filter_options'], word);
    end

    return self:GetKeyword();
end

-- 删除过滤词
function filter:RemoveKeyword(str)
    local len = #LFGInChatDB['filter_options'];

    if len == 0 then
        print('Remove Failed. Keyword list is NONE');
        return;
    end

    local _, keywordHash = self:GetKeyword();
    for word in string.gmatch(str, "%w+") do 
        if keywordHash[word] == 1 then
            keywordHash[word] = 0;
        end
    end

    local keywordTable = {};
    for key, v in pairs(keywordHash) do
        if v == 1 then
            table.insert(keywordTable, key);
        end
    end

    LFGInChatDB['filter_options'] = keywordTable;

    return filter:GetKeyword();
end

-- 清空过滤词
function filter:ClearKeyword()
    LFGInChatDB['filter_options'] = {};
    return filter:GetKeyword();
end

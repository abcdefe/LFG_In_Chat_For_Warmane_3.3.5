local _, core = ...;

core.Config = {};

local config = core.Config;

-- 插件名称
config.WIDGET_NAME = '_LFG_In_Chat';

-- 生效开关
-- config.EFFECT = false;

-- debug开关
-- local debug = false;

-- 组队频道
config.FILTER_CHANNEL_NAME = 'GLOBAL';
-- config.FILTER_CHANNEL_NAME = debug and 'TESTUI' or 'GLOBAL';

-- 默认过滤词
-- config.FILTER_OPTIONS = { 
--     'VOA', 
--     'ICC', 
--     'TOC', 
--     -- 'TOGC', 
--     -- 'RS',
-- };

-- pvp安全区 e.g: 达拉然
config.FILTER_PVP_STATUS = 'SANCTUARY';

-- 插件加载后欢迎语
config.WELCOME_TEXT = 'LFG In Chat Loaded'



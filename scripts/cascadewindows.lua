CASCADEWINDOWS_IGNORE_CT_OPEN = "CASCADEWINDOWS_IGNORE_CT_OPEN";
CASCADEWINDOWS_IGNORE_PS_OPEN = "CASCADEWINDOWS_IGNORE_PS_OPEN";
CASCADEWINDOWS_IGNORE_TOOLS_OPEN = "CASCADEWINDOWS_IGNORE_TOOLS_OPEN";
CASCADEWINDOWS_IGNORE_LIBRARY_OPEN = "CASCADEWINDOWS_IGNORE_LIBRARY_OPEN";
CASCADEWINDOWS_IGNORE_TIMER_OPEN = "CASCADEWINDOWS_IGNORE_TIMER_OPEN";
CASCADEWINDOWS_IGNORE_IMAGES_OPEN = "CASCADEWINDOWS_IGNORE_IMAGES_OPEN";
IS_FGC = false;
OFF = "off";
ON = "on";
local onWindowOpened_Original;
local openWindowList = {};

function onInit()
	local option_header = "option_header_cascadewindows";
	local option_val_off = "option_val_off";
	local option_val_on = "option_val_on";
	local option_entry_cycler = "option_entry_cycler";

	IS_FGC = checkFGC();
    if IS_FGC then
        onWindowOpened_Original = Interface.onWindowOpened;
        Interface.onWindowOpened = onWindowOpened;
        -- I couldn't get FGC sidebar icon to look 100% matching, so let's use the text button at the bottom instead.
        DesktopManager.registerDockShortcut2("closewindows", "closewindows", "sidebar_tooltip_closeall", "closewindows", "closewindows", true, false);
        if MenuManager ~= nil and MenuManager.addMenuItem ~= nil then
            MenuManager.addMenuItem("closewindows", "closewindows", "library_recordtype_label_closewindows", Interface.getString("library_recordtype_label_closewindows"), false);
        end
    else
        Interface.addKeyedEventHandler("onWindowOpened", "", onWindowOpened);
    end

    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_CT_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_CT_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_PS_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_PS_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_TOOLS_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_TOOLS_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_LIBRARY_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_LIBRARY_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_TIMER_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_TIMER_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_IMAGES_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_IMAGES_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    Comm.registerSlashHandler("ccw", cascadeWindows);
end

function onTabletopInit()
    if not IS_FGC then
        local tButton = {
            sIcon = "sidebar_icon_cascade",
            tooltipres = "library_recordtype_label_cascadewindows",
            class = "cascadewindows",
        };

        DesktopManager.registerSidebarToolButton(tButton);
        if MenuManager ~= nil and MenuManager.menusWindow then
            MenuManager.menusWindow.createMenuSelections();
        end
    end
end

function checkFGC()
	local nMajor, nMinor, nPatch = Interface.getVersion()
	if nMajor <= 2 then return true end
	if nMajor == 3 and nMinor <= 2 then return true end
	return nMajor == 3 and nMinor == 3 and nPatch <= 15;
end

function cascadeWindow(t, i, startX, startY, offsetX, offsetY, positionIndex)
    if t ~= nil
        and t[i] ~= nil
        and type(t[i]) == "windowinstance"
        and t[i].setPosition ~= nil then
        local sWindowClass = t[i].getClass();
        -- Check if the window should be ignored
        if shouldIgnoreWindow(t[i]) then
            return positionIndex -- Skip this window but keep the position index unchanged
        end
        -- Set the window's position
        t[i].setPosition(startX + positionIndex * offsetX, startY + positionIndex * offsetY)
        positionIndex = positionIndex + 1 -- Increment the position index for the next window
    end

    return positionIndex
end

function cascadeWindows()
    -- Retrieve the list of open windows
    local openWindowList = Interface.getWindows()
    --Debug.chat("Open windows:", openWindowList)
    local startX, startY = 50, 50
    local offsetX, offsetY = 30, 30
    local positionIndex = 0
    -- Iterate through each window in the list
    for i, window in ipairs(openWindowList) do
        --Debug.chat("Processing window:", window.getClass())
        -- Delegate the positioning logic to cascadeWindow
        positionIndex = cascadeWindow(openWindowList, i, startX, startY, offsetX, offsetY, positionIndex)
    end
end

local ignoreOptions = {
    [CASCADEWINDOWS_IGNORE_CT_OPEN] = { "combattracker_host", "combattracker_client" },
    [CASCADEWINDOWS_IGNORE_PS_OPEN] = { "partysheet_host", "partysheet_client" },
    [CASCADEWINDOWS_IGNORE_TOOLS_OPEN] = { "calendar", "diceselect", "modifiers", "effectlist", "sound_context", "options" },
    [CASCADEWINDOWS_IGNORE_LIBRARY_OPEN] = { "library", "tokenbag", "books_list", "masterindex" },
    [CASCADEWINDOWS_IGNORE_TIMER_OPEN] = { "timerwindow" },
    [CASCADEWINDOWS_IGNORE_IMAGES_OPEN] = { "imagewindow" },
    ["TOP_LEVEL_WINDOWS"] = {
        "desktopdecalfill",
        "desktopdecal",
        "shortcutsanchor",
        "shortcuts",
        "shortcutbar",
        "imagebackpanel",
        "imagemaxpanel",
        "chat",
        "modifierstack",
        "desktop_setdc",
        "dicetower",
        "imagefullpanel",
        "dicepanel",
        "characterlist",
        "tabletop_partylist",
        "tabletop_combatlist"
    }
};

function shouldIgnoreWindow(window)
    local sWindowClass = window.getClass();

    -- Always ignore top-level windows
    for _, className in ipairs(ignoreOptions["TOP_LEVEL_WINDOWS"]) do
        if sWindowClass == className then
            --Debug.chat("Ignoring top-level window:", sWindowClass);
            return true;
        end
    end

    -- Check user-configurable ignore options
    for optionKey, classList in pairs(ignoreOptions) do
        if optionKey ~= "TOP_LEVEL_WINDOWS" and OptionsManager.isOption(optionKey, ON) then
            for _, className in ipairs(classList) do
                if sWindowClass == className then
                    --Debug.chat("Ignoring window due to option:", optionKey, "Class:", sWindowClass);
                    return true;
                end
            end
        end
    end

    return false;
end

function onWindowOpened(window)
    if window == nil then return end

    if IS_FGC and onWindowOpened_Original ~= nil then
        onWindowOpened_Original(window);
    end

    local sWindowClass = window.getClass();
    if type(window) == "windowinstance" and not shouldIgnoreWindow(window) then
        -- Add the window to the openWindowList if it is not ignored
        table.insert(openWindowList, window);
        --Debug.chat("Window added to openWindowList:", sWindowClass);
    else
        -- Log why the window was excluded
        --Debug.chat("Window excluded (ignored):", sWindowClass);
    end
end

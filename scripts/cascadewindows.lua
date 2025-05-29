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
    Comm.registerSlashHandler("ccw", cascadeSlashHandler);
    Comm.registerSlashHandler("cascadewindows", cascadeSlashHandler);

end

function onTabletopInit()
    if not IS_FGC then
        local tButton = {
            sIcon = "cascade_icon_sidebar",
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
        -- Bring the window to the front
        if t[i].bringToFront ~= nil then
            t[i]:bringToFront()
        end
        positionIndex = positionIndex + 1 -- Increment the position index for the next window
    end

    return positionIndex
end

local windowClassPriority = {
    -- Priority 1: Top-level windows (not sorted, keep original order)
    desktop = 1,
    desktoptop = 1,
    desktopbottom = 1,
    desktopdecalfill = 1,
    desktopdecal = 1,
    shortcutsanchor = 1,
    shortcuts = 1,
    shortcutbar = 1,
    imagebackpanel = 1,
    imagemaxpanel = 1,
    modifierstack = 1,
    desktop_setdc = 1,
    imagefullpanel = 1,
    characterlist = 1,
    -- Priority 2: Combat tracker
    combattracker_host = 2,
    combattracker_client = 2,
    -- Priority 3: Party sheet
    partysheet_host = 3,
    partysheet_client = 3,
    -- Priority 4: Tools
    calendar = 4,
    diceselect = 4,
    modifiers = 4,
    effectlist = 4,
    sound_context = 4,
    options = 4,
    timerwindow = 4,
    -- Priority 5: Library
    library = 5,
    tokenbag = 5,
    books_list = 5,
    story_book_list = 5,
    masterindex = 5,
    -- Priority 6: Pages
    reference_manual = 6,
    charsheet = 6,
    -- Priority: Common Window Instances
    -- Campaign
    imagewindow = 8,
    asset_preview = 8,
    battle = 9,
    item = 10,
    npc = 11,
    treasureparcel = 12,
    table = 13,
    vehicle = 14,
    -- World
    location = 15,
    quest = 16,
    referencemanualpage = 17,
    note = 18,
    -- Dune2D20
    archetype = 30,
    faction = 31,
    talent = 32,
    house = 33,
}

local function getWindowPriority(windowClass)
    return windowClassPriority[windowClass] or 99
end

function cascadeWindows(windowClass)
    if windowClass == "" then windowClass = nil end
    
    local sortedList = getSortedWindowList(windowClass)

    -- Debug: print sorted window class names
    local sortedNames = {}
    for i, w in ipairs(sortedList) do
        table.insert(sortedNames, w:getClass())
    end
    Debug.console("Sorted window classes:", table.concat(sortedNames, ", "))

    local startX, startY = 50, 50
    local offsetX, offsetY = 30, 30
    local positionIndex = 0
    for i, window in ipairs(sortedList) do
        positionIndex = cascadeWindow(sortedList, i, startX, startY, offsetX, offsetY, positionIndex)
    end
end

-- Returns a sorted list of windows, filtered by windowClass if provided
function getSortedWindowList(windowClass)
    local openWindowList = Interface.getWindows()
    local filteredList = {}

    for _, w in ipairs(openWindowList) do
        if (not windowClass or (w.getClass and w:getClass() == windowClass))
            and not shouldIgnoreWindow(w) then
            table.insert(filteredList, w)
        end
    end

    -- Sort by priority, then by class name (except for priority 1, which keeps original order)
    table.sort(filteredList, function(a, b)
        local pa, pb = getWindowPriority(a:getClass()), getWindowPriority(b:getClass())
        if pa ~= pb then
            return pa < pb
        end
        if pa == 1 then
            return false -- keep original order for top-level windows
        end
        return a:getClass() < b:getClass()
    end)

    return filteredList
end

-- Map ignore options to priority numbers instead of explicit class lists
local ignoreOptions = {
    [CASCADEWINDOWS_IGNORE_CT_OPEN] = 2,      -- Combat tracker
    [CASCADEWINDOWS_IGNORE_PS_OPEN] = 3,      -- Party sheet
    [CASCADEWINDOWS_IGNORE_TOOLS_OPEN] = 4,   -- Tools
    [CASCADEWINDOWS_IGNORE_LIBRARY_OPEN] = 5, -- Library
    [CASCADEWINDOWS_IGNORE_TIMER_OPEN] = 6,   -- Timer
    [CASCADEWINDOWS_IGNORE_IMAGES_OPEN] = 7,  -- Images
};

function shouldIgnoreWindow(window)
    -- Ignore subwindows (only act on top-level windows)
    if window.getParent and window:getParent() ~= nil then
        Debug.console("Ignoring subwindow:", window.getClass());
        return true;
    end

    local sWindowClass = window.getClass();
    local priority = getWindowPriority(sWindowClass)

    -- Ignore top-level windows based on priority
    if priority == 1 then
        Debug.console("Ignoring top-level window:", sWindowClass);
        return true;
    end
    -- Ignore locked windows
    if window.getLockState and window:getLockState() == true then
        Debug.console("Ignoring locked window:", sWindowClass);
        return true;
    end
    --ignore minimized windows
    if window.isMinimized and window:isMinimized() == true then
        Debug.console("Ignoring minimized window:", sWindowClass);
        return true;
    end
    -- Check user-configurable ignore options by priority
    for optionKey, ignorePriority in pairs(ignoreOptions) do
        if OptionsManager.isOption(optionKey, ON) and priority == ignorePriority then
            Debug.console("Ignoring window due to option:", optionKey, "Class:", sWindowClass, "Priority:", priority);
            return true;
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
        table.insert(openWindowList, window);
        Debug.console("Window added to openWindowList:", sWindowClass);
    else
        Debug.console("Window excluded (ignored):", sWindowClass);
        return
    end
end

function cascadeSimilarWindows(windowClass)
    if not windowClass or type(windowClass) ~= "string" then
        Debug.console("Cascade: Could not determine windowclass.")
        return
    end
    cascadeWindows(windowClass)
end

function cascadeSlashHandler()
    cascadeWindows(nil)
    return true
end
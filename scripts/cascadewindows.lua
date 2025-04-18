CASCADEWINDOWS_IGNORE_CT_OPEN = "CASCADEWINDOWS_IGNORE_CT_OPEN";
CASCADEWINDOWS_IGNORE_IMAGES_OPEN = "CASCADEWINDOWS_IGNORE_IMAGES_OPEN";
CASCADEWINDOWS_IGNORE_PS_OPEN = "CASCADEWINDOWS_IGNORE_PS_OPEN";
CASCADEWINDOWS_IGNORE_TIMER_OPEN = "CASCADEWINDOWS_IGNORE_TIMER_OPEN";
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
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_IMAGES_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_IMAGES_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_PS_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_PS_OPEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = option_val_off, baseval = OFF, default = OFF });
    OptionsManager.registerOption2(CASCADEWINDOWS_IGNORE_TIMER_OPEN, true, option_header, "option_label_CASCADEWINDOWS_IGNORE_TIMER_OPEN", option_entry_cycler,
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

function arrayIterate(t, fnProcess)
    local n = #t

    for i = 1, n do
        if t[i] ~= nil then
            -- Call the provided function for each item
            fnProcess(t, i)
        end
    end

    return t
end

function checkFGC()
	local nMajor, nMinor, nPatch = Interface.getVersion()
	if nMajor <= 2 then return true end
	if nMajor == 3 and nMinor <= 2 then return true end
	return nMajor == 3 and nMinor == 3 and nPatch <= 15;
end

-- List of panel window classes to exclude
local panelWindowClasses = {
    "library",
    "story_book_list",
    "tokenbag",
    "setup",
    "desktopdecalfill",
    "desktopdecal",
    "shortcutsanchor",
    "shortcuts",
    "imagebackpanel",
    "imagemaxpanel",
    "chat",
    "modifierstack",
    "dicetower",
    "imagefullpanel",
    "dicepanel",
    "characterlist"
};

-- Function to check if a window is a panel
function isPanelWindow(sWindowClass)
    for _, className in ipairs(panelWindowClasses) do
        if sWindowClass == className then
            return true;
        end
    end
    return false;
end

function cascadeWindow(t, i, startX, startY, offsetX, offsetY, positionIndex)
    if t ~= nil
        and t[i] ~= nil
        and type(t[i]) == "windowinstance"
        and t[i].setPosition ~= nil then
        local sWindowClass = t[i].getClass();

        -- Check if the window should be ignored
        if isPanelWindow(sWindowClass)
            or ignoreCtOpen(t, i)
            or ignoreImagesOpen(t, i)
            or ignorePsOpen(t, i)
            or ignoreTimerOpen(t, i) then
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

    -- Debug: Print the list of open windows
    Debug.chat("Open windows:", openWindowList)

    local startX, startY = 50, 50
    local offsetX, offsetY = 30, 30
    local positionIndex = 0

    -- Iterate through each window in the list
    for i, window in ipairs(openWindowList) do
        -- Debug: Print the window class
        Debug.chat("Processing window:", window.getClass())

        -- Delegate the positioning logic to cascadeWindow
        positionIndex = cascadeWindow(openWindowList, i, startX, startY, offsetX, offsetY, positionIndex)
    end
end

function ignoreCtOpen(t, i)
    local ignoreCtOpen = OptionsManager.isOption(CASCADEWINDOWS_IGNORE_CT_OPEN, ON);
    return ignoreCtOpen and (t[i].getClass() == "combattracker_host" or t[i].getClass() == "combattracker_client");
end

function ignoreImagesOpen(t, i)
    local ignoreImagesOpen = OptionsManager.isOption(CASCADEWINDOWS_IGNORE_IMAGES_OPEN, ON);
    return ignoreImagesOpen and t[i].getClass() == "imagewindow";
end

function ignorePsOpen(t, i)
    local ignorePsOpen = OptionsManager.isOption(CASCADEWINDOWS_IGNORE_PS_OPEN, ON);
    return ignorePsOpen and (t[i].getClass() == "partysheet_host" or t[i].getClass() == "partysheet_client");
end

function ignoreTimerOpen(t, i)
    local ignoreTimerOpen = OptionsManager.isOption(CASCADEWINDOWS_IGNORE_TIMER_OPEN, ON);
    return ignoreTimerOpen and t[i].getClass() == "timerwindow";
end

function onWindowOpened(window)
    if window == nil then return end

    if IS_FGC and onWindowOpened_Original ~= nil then
        onWindowOpened_Original(window);
    end

    local sWindowClass = window.getClass();
    if type(window) == "windowinstance"
        and not isPanelWindow(sWindowClass) then
        table.insert(openWindowList, window);
        Debug.chat("Window added to openWindowList:", sWindowClass);
    else
        Debug.chat("Window excluded (panel or foundational):", sWindowClass);
    end
end

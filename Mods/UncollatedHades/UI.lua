-- Copy of ZUI for brevity....
-- TODO: publish ZUI framework and add as dependency
function CloseScreenByName ( name )
	local screen = ScreenAnchors[name]
	DisableShopGamepadCursor()
	CloseScreen( GetAllIds( screen.Components ) )
	PlaySound({ Name = "/SFX/Menu Sounds/GeneralWhooshMENU" })
	UnfreezePlayerUnit()
	ToggleControl({ Names = { "AdvancedTooltip" }, Enabled = true })
	ShowCombatUI(name)
	screen.KeepOpen = false
	OnScreenClosed({ Flag = screen.Name })
end
UncollatedHades.BaseComponents = {

    Text = {
        Title = {
            Font = "SpectralSCLightTitling",
            FontSize = "36",
            Color = Color.White,
            Justification = "Center",
            OffsetY = -450,
            ShadowBlur = 0, ShadowColor = { 0, 0, 0, 1 }, ShadowOffset = { 0,  2 },
        },
        Subtitle = {
            Font = "AlegreyaSansSCLight",
            FontSize = "30",
            Color = Color.White,
            Justification = "Center",
            OffsetY = -375,
            ShadowBlur = 0, ShadowColor = { 0, 0, 0, 1 }, ShadowOffset = { 0,  2 },
        },
        Paragraph = {
            FontSize = 24,
            Color = {159, 159, 159, 255},
            Font = "AlegreyaSansSCRegular",
            Justification = "Left",
            Width = ScreenWidth * 0.8,
            VerticalJustification = "Top",
            OffsetX = -ScreenWidth * 0.4,
            OffsetY = -300,
            ShadowBlur = 0, ShadowColor = { 0, 0, 0, 1 }, ShadowOffset = { 0,  2 },
        },
        Note = {
            FontSize = 16,
            Color = {159, 159, 159, 255},
            Font = "AlegreyaSansSCRegular",
            Justification = "Left",
            ShadowBlur = 0, ShadowColor = { 0, 0, 0, 1 }, ShadowOffset = { 0,  2 },
        },
            
    },
    Button = {
        -- Name is the animation attached to the button
        Close = {
            Name = "ButtonClose",
            Scale = 0.7,
            OffsetY = 480,
            ComponentArgs = {
                ControlHotkey = "Cancel",
            }
        },
        MenuLeft = {
            Name = "ButtonCodexDown",
            OffsetX = -1 * ScreenWidth / 2 + 50,
            ComponentArgs = {
                OnPressedFunctionName = "ScreenPageLeft",
            },
            Angle = -90
        },
        MenuRight = {
            Name = "ButtonCodexDown",
            OffsetX = ScreenWidth / 2 - 50,
            ComponentArgs = {
                OnPressedFunctionName = "ScreenPageRight",
            },
            Angle = 90
        },
        Basic = {
            Name = "BoonSlot1",
            Scale = 0.5,
        },
        Icon = {
            Name = "BaseInteractableButton",
        }
    },
    ProgressBar = {
        Standard = {
            Name = "rectangle01",
            Proportion = 0,
            BackgroundColor = {96, 96, 96, 255},
            ForegroundColor = Color.White,
            ScaleY = 1.0,
            ScaleX = 1.0,
            X = ScreenCenterX - 240,
            Y = ScreenCenterY,
        }
    },
    Background = {
        Name = "rectangle01",
        X = ScreenCenterX,
        Y = ScreenCenterY,
        Scale = 10,
        Color = Color.Black,
        Alpha = 0.85,
        FadeInDuration = 0.5,
    },
    Dropdown = {
        Standard = {
            Scale = {X = .25, Y = .5},
            Padding = {X = 0, Y = 2},
            GeneralFontSize = 16,
            Font = "AlegrayaSansSCRegular",
        }
    },

}

function GetScreenIdsToDestroy(screen) 
    local idsToKeep = screen.PermanentComponents or {}
    -- DebugPrint { Text = ModUtil.ToString.Deep(idsToKeep)}
    local allIds = GetAllIds(screen.Components)
    local idsToDestroy = {}
    for _, id in ipairs(allIds) do
        if not Contains(idsToKeep, id) then
            table.insert(idsToDestroy, id)
        end
    end
    
    return idsToDestroy
end

function GoToPageFromSource(screen, button)
    if button.PageIndex == nil then
        DebugPrint { Text = "You need to set PageIndex on the button, you doofus."}
    end
    RenderScreenPage(screen, button, button.PageIndex)
end

-- Handles non-linear paging
function RenderScreenPage(screen, button, index)
    -- Get Non-permanent components and DESTROY them
    Destroy({Ids = GetScreenIdsToDestroy(screen, button)})

    -- then render it
    UncollatedHades.RenderComponents(screen, screen.Pages[index], { Source = button })

end

function ScreenPageRight(screen, button)
    if screen.PageIndex == screen.PageCount then
        return
    end
    -- increment page
    screen.PageIndex = screen.PageIndex + 1
    RenderScreenPage(screen, button, screen.PageIndex)

end

function ScreenPageLeft(screen, button)
    if screen.PageIndex == 1 then
        return
    end
    screen.PageIndex = screen.PageIndex - 1
    RenderScreenPage(screen, button, screen.PageIndex)
end

-- Create Menu
function UncollatedHades.CreateMenu(name, args)
    -- Screen / Hades Framework Setup
    -- DebugPrint { Text = ModUtil.ToString.Deep(args)}
    args = args or {}
    local screen = { Components = {} }
    ScreenAnchors[name] = screen
	screen.Name = name

    local components = screen.Components

    if IsScreenOpen( screen.Name ) then
		return
	end
    OnScreenOpened({ Flag = screen.Name, PersistCombatUI = false })
    HideCombatUI(name)
    FreezePlayerUnit()
    EnableShopGamepadCursor()

    -- Initialize Background + Sounds
	PlaySound({ Name = args.OpenSound or "/SFX/Menu Sounds/DialoguePanelIn" })
    local background = args.Background or UncollatedHades.BaseComponents.Background
    -- Generalize rendering components on the screen.
    UncollatedHades.RenderBackground(screen, background)
    UncollatedHades.RenderComponents(screen, args.Components)
    if args.Pages ~= nil then
        screen.Pages = args.Pages
        screen.PageIndex = args.InitialPageIndex or 1
        screen.PageCount = TableLength(args.Pages)
        -- Page Left button
        if (args.PaginationStyle or "Linear") == "Linear" then
            UncollatedHades.RenderButton(screen, {
                Type = "Button",
                SubType = "MenuLeft",
                Args = { FieldName = "MenuLeft" }
            })
            -- Page Right button
            UncollatedHades.RenderButton(screen, {
                Type = "Button", 
                SubType = "MenuRight",
                Args = { FieldName = "MenuRight" }
            })
        end
        -- assigns the "core" components to a placeholder ID set to not delete later
        screen.PermanentComponents = GetAllIds(screen.Components)

        -- Render first Page
        UncollatedHades.RenderComponents(screen, args.Pages[screen.PageIndex])
    end


	HandleScreenInput( screen )
    return screen
end

function UncollatedHades.RenderComponents(screen, componentsToRender, args)    
    -- Handle rendering overrides
    if type(componentsToRender) == "string" then
        if type(_G[componentsToRender]) == "function" then
            return _G[componentsToRender](screen, args.Source) -- TODO: do secondary args make sense here?
        end
    elseif type(componentsToRender) == "function" then
        return componentsToRender(screen, args.Source)
    end

    -- default framework rendering
    for _, component in pairs(componentsToRender) do
        UncollatedHades.RenderComponent(screen, component)
    end
end

function UncollatedHades.RenderComponent(screen, component)
    if component.Type == "Text" then
        UncollatedHades.RenderText(screen, component)
    elseif component.Type == "Button" then
        UncollatedHades.RenderButton(screen, component)
    elseif component.Type == "Dropdown" then
        UncollatedHades.RenderDropdown(screen, component)
    elseif component.Type == "ProgressBar" then
        UncollatedHades.RenderProgressBar(screen, component)
    elseif component.Type == "List" then
        UncollatedHades.RenderList(screen, component)
    end
end

function UncollatedHades.RenderDropdown(screen, component)
    local dropdownDefinition = ModUtil.Table.Merge(
        DeepCopyTable(UncollatedHades.BaseComponents.Dropdown[component.SubType]),
        DeepCopyTable(component.Args)
    )
    dropdownDefinition.Name = dropdownDefinition.FieldName
    
    ErumiUILib.Dropdown.CreateDropdown(screen, dropdownDefinition)
end

function UncollatedHades.RenderButton(screen, component)
    -- Get Subtype Defaults abnd Merge
    local defaults = DeepCopyTable(UncollatedHades.BaseComponents.Button[component.SubType])
    local buttonDefinition = ModUtil.Table.Merge(defaults, component.Args or {})

    local components = screen.Components
    local buttonName = buttonDefinition.FieldName or buttonDefinition.Name
    local buttonComponentName = buttonDefinition.Name or "BaseInteractableButton"
    components[buttonName] = CreateScreenComponent({ Name = buttonComponentName, Scale = buttonDefinition.Scale or 1.0 })
    DebugPrint { Text = ModUtil.ToString.Deep(buttonDefinition)}

    if buttonDefinition.Animation ~= nil then
        SetAnimation({ DestinationId = components[buttonName].Id, Name = buttonDefinition.Animation })
    end


	Attach({
        Id = components[buttonName].Id,
        DestinationId = components.Background.Id,
        OffsetX = buttonDefinition.OffsetX,
        OffsetY = buttonDefinition.OffsetY,
    })
    if buttonDefinition.ComponentArgs then
        ModUtil.Table.Merge(components[buttonName], buttonDefinition.ComponentArgs)
    end
    if buttonDefinition.Angle ~= nil then
        SetAngle({ Id = components[buttonName].Id, Angle = buttonDefinition.Angle})
    end
    -- HardCoded, not sure how to get around this
    if buttonDefinition.OnPressedFunctionName == nil and component.SubType == "Close" then
        local name = screen.Name
        components[buttonName].OnPressedFunctionName = "Close" .. name .. "Screen"
        if _G["Close" .. name .. "Screen"] == nil then
    
            _G["Close" .. name .. "Screen"] = function()
                CloseScreenByName ( name )
                if buttonDefinition.CloseScreenFunction then
                    buttonDefinition.CloseScreenFunction(buttonDefinition.CloseScreenFunctionArgs)
                elseif buttonDefinition.CloseScreenFunctionName ~= nil then
                    _G[buttonDefinition.CloseScreenFunctionName](buttonDefinition.CloseScreenFunctionArgs)
                end
            end
        end
    end

    -- LABELLED BUTTONS
    if buttonDefinition.Label then
        if type(buttonDefinition.Label) == "table" then
            buttonDefinition.Label.Parent = buttonName
            UncollatedHades.RenderText(screen, buttonDefinition.Label)
        else
            DebugPrint { Text = "Button.Label definition not properly defined!"}
        end
    end

    return components[buttonName]
end

-- Create Text Box
function UncollatedHades.RenderText(screen, component)
    -- Get Subtype Defaults abnd Merge
    local textDefinition = ModUtil.Table.Merge(
        DeepCopyTable(UncollatedHades.BaseComponents.Text[component.SubType]),
        DeepCopyTable(component.Args)
    )
    -- Create Text
    textDefinition.Name = "BlankObstacle"
    local parentName = component.Parent or "Background"
    textDefinition.DestinationId = screen.Components[parentName].Id
    
    screen.Components[textDefinition.FieldName] = CreateScreenComponent(textDefinition)

    -- -- DebugPrint { Text = ModUtil.ToString.Deep(textDefinition)}
    -- -- DebugPrint { Text = parentName .. ": " .. ModUtil.ToString.Deep(screen.Components[parentName])}
    local finalTextDefinition = ModUtil.Table.Merge(textDefinition, {
        Id = screen.Components[textDefinition.FieldName].Id,
    })
    return CreateTextBox(finalTextDefinition)

end

function UncollatedHades.UpdateText(screen, component)
    -- Get Subtype Defaults abnd Merge
    local textDefinition = ModUtil.Table.Merge(
        DeepCopyTable(UncollatedHades.BaseComponents.Text[component.SubType]),
        DeepCopyTable(component.Args)
    )
    local components = screen.Components
    ModifyTextBox({
        Id = components[textDefinition.FieldName].Id, Text = textDefinition.Text
    })

end

function UncollatedHades.RenderBackground(screen, component)
    screen.Components.Background = CreateScreenComponent({ Name = component.Name, X = component.X, Y = component.Y })
    if component.Scale ~= nil then
        SetScale({ Id = screen.Components.Background.Id, Fraction = component.Scale })
    end
    if component.Color ~= nil then
        SetColor({ Id = screen.Components.Background.Id, Color = component.Color })
    end
    if component.Alpha ~= nil then
        if component.FadeInDuration ~= nil then
            SetAlpha({ Id = screen.Components.Background.Id, Fraction = 0 })
            SetAlpha({ Id = screen.Components.Background.Id, Fraction = component.Alpha, Duration = component.FadeInDuration })
        else
            SetAlpha({ Id = screen.Components.Background.Id, Fraction = component.Alpha })
        end
    end
    return screen.Components.Background
end


-- MENUS

ModUtil.Path.Wrap("UseShrineObject", function (baseFunc, ...)
    if UncollatedHades.Initialized == true or not UncollatedHades.config.Enabled then
        return baseFunc(...)
    end

    local selectionBehaviorDropdownItems = {
        Default = {
            Text = "Run Selection Behavior",
            event = function() end
        }
    }
    for name, behavior in pairs(UncollatedHades.SelectionBehaviors) do
        table.insert(selectionBehaviorDropdownItems, {
            Text = name,
            event = function ()
                UncollatedHades.config.SelectionBehavior = name
            end
        })
    end

    local deathBehaviorDropdownOptions = {
        Default = {
            Text = "On Death Behavior",
            event = function() end
        }
    }
    for name, behavior in pairs(UncollatedHades.DeathBehaviors) do
        table.insert(selectionBehaviorDropdownItems, {
            Text = name,
            event = function ()
                UncollatedHades.config.DeathBehavior = name
            end
        })
    end
    UncollatedHades.CreateMenu("UncollatedHades", {
        Components = {
            {
                Type = "Button",
                SubType = "Close",
                Args = {
                    FieldName = "GoButton",
                    Name = "BoonSlot1",
                    Scale = 0.35,
                    OffsetY = 480,
                    Label = {
                        Type = "Text",
                        SubType = "Paragraph",
                        Args = {
                            Text = "Go",
                            FieldName = "GoButtonLabel",
                            OffsetY = 480,
                            OffsetX = 0,
                            Justification = "Center",
                            VerticalJustification = "Center",
                        }
                    },
                }
            },
            {
                Type = "Text",
                SubType = "Title",
                Args = {
                    FieldName = "UncollatedHadesTitle",
                    Text = "Anti-Collation Mod Setup",
                }
            },
            {
                Type = "Text",
                SubType = "Subtitle",
                Args = {
                    FieldName = "UncollatedHadesSubtitle",
                    Text = "Select your desired mod behavior below, then click \"Go!\" below.",
                }
            },
            
            {
                Type = "Text",
                SubType = "Subtitle",
                Args = {
                    FieldName = "RunNumberSubtitle",
                    Font = "AlegreyaSansSCRegular",
                    Text = "Number of Runs to uncollate:",
                    FontSize = 18,
                    OffsetX = - ScreenWidth / 3,
                    OffsetY = - ScreenHeight / 6 - 50,
                }
            },
            {
                Type = "Dropdown",
                SubType = "Standard",
                Args = {
                    FieldName = "RunNumberDropdown",
                    Group = "RunNumberDropdownGroup",
                    -- X, Y, Items, Name
                    X = ScreenWidth / 6,
                    Y = ScreenHeight / 3,
                    Scale = {X = .30, Y = .35},
                    Padding = {X = 0, Y = 2},
                    GeneralFontSize = 12,
                    Items = {
                        Default = {
                            Text = "Number of Runs",
                            event = function() end
                        },
                        { Text = "2", event = function () UncollatedHades.config.NumRuns = 2 end },
                        { Text = "3", event = function () UncollatedHades.config.NumRuns = 3 end },
                        { Text = "4", event = function () UncollatedHades.config.NumRuns = 4 end },
                        { Text = "5", event = function () UncollatedHades.config.NumRuns = 5 end },
                        { Text = "6", event = function () UncollatedHades.config.NumRuns = 6 end },
                        { Text = "7", event = function () UncollatedHades.config.NumRuns = 7 end },
                        { Text = "8", event = function () UncollatedHades.config.NumRuns = 8 end },
                        { Text = "9", event = function () UncollatedHades.config.NumRuns = 9 end },
                        { Text = "10", event = function () UncollatedHades.config.NumRuns = 10 end },
                        { Text = "11", event = function () UncollatedHades.config.NumRuns = 11 end },
                        { Text = "12", event = function () UncollatedHades.config.NumRuns = 12 end },
                        { Text = "24", event = function () UncollatedHades.config.NumRuns = 24 end },
                    }
                }
            },
            {
                Type = "Text",
                SubType = "Subtitle",
                Args = {
                    FieldName = "RunSelectionSubtitle",
                    Font = "AlegreyaSansSCRegular",
                    Text = "Run selection behavior:",
                    FontSize = 18,
                    OffsetX = - ScreenWidth / 6,
                    OffsetY = - ScreenHeight / 6 - 50,
                }
            },
            {
                Type = "Dropdown",
                SubType = "Standard",
                Args = {
                    FieldName = "RunSelection",
                    Group = "RunSelectionGroup",
                    -- X, Y, Items, Name
                    X = 2 * ScreenWidth / 6,
                    Y = ScreenHeight / 3,
                    Scale = {X = .30, Y = .35},
                    Padding = {X = 0, Y = 2},
                    GeneralFontSize = 12,
                    Items = selectionBehaviorDropdownItems,
                }
            },
            {
                Type = "Text",
                SubType = "Subtitle",
                Args = {
                    FieldName = "DeathBehaviorSubtitle",
                    Font = "AlegreyaSansSCRegular",
                    Text = "On death behavior:",
                    FontSize = 18,
                    OffsetX = ScreenWidth / 6,
                    OffsetY = - ScreenHeight / 6 - 50,
                }
            },
            {
                Type = "Dropdown",
                SubType = "Standard",
                Args = {
                    FieldName = "DeathBehaviorDropdown",
                    Group = "DeathBehaviorDropdownGroup",
                    -- X, Y, Items, Name
                    X = 3 * ScreenWidth / 6,
                    Y = ScreenHeight / 3,
                    Scale = {X = .30, Y = .35},
                    Padding = {X = 0, Y = 2},
                    GeneralFontSize = 12,
                    Items = deathBehaviorDropdownOptions,
                }
            }
        }
    })
    baseFunc(...)

end, UncollatedHades)

-- ShowChamberNumber mod for brevity
ModUtil.Path.Wrap("StartRoom", function ( baseFunc, currentRun, currentRoom )
    if UncollatedHades.config.Enabled then
        ShowDepthCounter()
    end

    baseFunc(currentRun, currentRoom)
end, ShowChamberNumber)
ModUtil.Path.Wrap("ShowCombatUI", function ( baseFunc, flag )
    if UncollatedHades.config.Enabled then
        ShowDepthCounter()
    end

    baseFunc(flag)
end, ShowChamberNumber)

ModUtil.Path.Wrap("HideDepthCounter", function ( baseFunc )
    if UncollatedHades.config.Enabled then
        return
    end

    baseFunc()
end, ShowChamberNumber)

ModUtil.Path.Wrap("ShowDepthCounter", function ( baseFunc )
    baseFunc()
    if UncollatedHades.config.Enabled then
	    ModifyTextBox({
            Id = ScreenAnchors.RunDepthId,
            Text = "Chamber " .. tostring(CurrentRun.RunDepthCache) .. ", Run " .. tostring(UncollatedHades.CurrentRunIndex)
        })
    end

end, ShowChamberNumber)

-- All edits are exact and atomic: unknown panel versions retain native UI.
local patch = {}
local edits = {
    {'local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"',
     'local uiSlider = mjrequire "structuresPlusMaintain/quantity"'},
    {'local maxCraftCount = 50', 'local maxCraftCount = 1000000'},
    {'local craftCountToUse = currentCraftCount',
     'uiSlider:finishEditing(sliderView, true)\n        local craftCountToUse = currentCraftCount == maxCraftCount and 1 or currentCraftCount'},
    {'function inspectCraftPanel:popUI()',
     'function inspectCraftPanel:popUI()\n    if uiSlider:finishEditing(sliderView, false) then return true end'},
    {'uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_craftX", {countText = mj:tostring(countToUseOnCraftButton)})',
     'uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_craftX", {countText = mj:tostring(currentCraftCount == maxCraftCount and "1 batch" or countToUseOnCraftButton)})'},
    {'uiComplexTextView:update(sliderCountComplexView, complexViewUpdateData)',
     'if currentCraftCount == maxCraftCount then complexViewUpdateData = {{text = "Continuous"}} end\n    uiComplexTextView:update(sliderCountComplexView, complexViewUpdateData)'},
}
function patch.apply(source)
    if type(source) ~= "string" then return nil end
    for _, edit in ipairs(edits) do
        local a,b = source:find(edit[1], 1, true)
        if not a or source:find(edit[1], b+1, true) then return nil end
        source = source:sub(1,a-1)..edit[2]..source:sub(b+1)
    end
    return source
end
return patch

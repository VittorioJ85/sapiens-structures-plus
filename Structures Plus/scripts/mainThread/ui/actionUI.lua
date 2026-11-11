local mod={loadOrder=70}
function mod:onload(ui)
    local init=ui.init
    function ui:init(...)
        local result=init(self,...)
        for _,wheel in pairs(self.wheels or {}) do
            for _,segment in pairs(wheel.segments or {}) do
                local mouseUp=segment.mouseUp
                if mouseUp then
                    segment.mouseUp=function(button,...)
                        local info=segment.userData or {}
                        -- Native quick-swipe dispatches on release without a
                        -- matching mouse-down. Shutters require a deliberate
                        -- click; controller actions bypass this mouse handler.
                        if button==0 and mjrequire("common/spShutters").desired(info.planTypeIndex)~=nil
                            and not info.mouseDown then return end
                        return mouseUp(button,...)
                    end
                end
            end
        end
        return result
    end
end
return mod

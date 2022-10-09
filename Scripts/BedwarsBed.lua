BedwarsBed = class()

local colors = {
	"#eeeeee", "#f5f071", "#cbf66f", "#68ff88", "#7eeded", "#4c6fe3", "#ae79f0", "#ee7bf0", "#f06767", "#eeaf5c",
	"#7f7f7f", "#e2db13", "#a0ea00", "#19e753", "#2ce6e6", "#0a3ee2", "#7514ed", "#cf11d2", "#d02525", "#df7f00",
	"#4a4a4a", "#817c00", "#577d07", "#0e8031", "#118787", "#0f2e91", "#500aa6", "#720a74", "#7c0000", "#673b00",
	"#222222", "#323000", "#375000", "#064023", "#0a4444", "#0a1d5a", "#35086c", "#520653", "#560202", "#472800"
}

if not g_beds then
    g_beds = {}
end

function BedwarsBed:server_onCreate()
    self.saved = self.storage:load()

    if not self.saved then
        for i=1, #colors+1 do
            local newColor = sm.color.new(string.sub(colors[i], 1) .. "ff")
            local exists = false
            for _, shape in pairs(g_beds) do
                if shape.color == newColor then
                    exists = true
                end
            end

            if not exists then
                self.shape:setColor(newColor)
                break
            end

            if i == #colors then
                self.network:sendToClients("cl_alert", "You can only have one Bed per color")
                self.shape:destroyPart(0)
                return
            end
        end
    end
    self.saved = true
    self.storage:save(self.saved)

    self.color = self.shape.color
    self.key = #g_beds+1
    g_beds[self.key] = self.shape
    self.network:sendToClients("cl_create")
end

function BedwarsBed:server_onDestroy()
    if self.key then
        g_beds[self.key] = nil
    end

    g_respawnManager:sv_destroyBed( self.shape )
end

function BedwarsBed:sv_set_color(color, player)
    local sm_color = sm.color.new(string.sub(color, 1) .. "ff")
    for _, shape in pairs(g_beds) do
        if shape.color == sm_color then
            self.network:sendToClient(player, "cl_alert", "You can only have one Bed per color")
            return
        end
    end
    self.shape:setColor(sm_color)
end

function BedwarsBed.sv_activateBed( self, character )
	g_respawnManager:sv_registerBed( self.shape, character )
end

function BedwarsBed.client_onAction( self, controllerAction, state )
	local consumeAction = true
	if state == true then
		if controllerAction == sm.interactable.actions.use or controllerAction == sm.interactable.actions.jump then
			self:cl_seat()
		else
			consumeAction = false
		end
	else
		consumeAction = false
	end
	return consumeAction
end

function BedwarsBed.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_activateBed", character )
		self:cl_seat()
		sm.gui.displayAlertText( "Lorem Ipsum" )
	end
end

function BedwarsBed:client_onTinker(character, state)
    if not state then return end
	if not self.gui then
		self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PaintGun.layout")
		for i=0, 40 do
			self.gui:setButtonCallback("ColorButton" .. tostring(i), "cl_onColorButton")
		end
	end
	self.gui:open()
end


function BedwarsBed:client_canInteract()
    local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
    sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_USE}" )
    local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
    sm.gui.setInteractionText( "", keyBindingText, "Color" )
    return true
end

function BedwarsBed:cl_onColorButton(name)
	local index = tonumber(string.sub(name, 12))
	local color = colors[index+1]
	self.gui:close()
	self.network:sendToServer("sv_set_color", color)
end

function BedwarsBed.cl_seat( self )
	if sm.localPlayer.getPlayer() and sm.localPlayer.getPlayer():getCharacter() then
		self.interactable:setSeatCharacter( sm.localPlayer.getPlayer():getCharacter() )
	end
end

function BedwarsBed:cl_alert(msg)
    sm.gui.displayAlertText(msg)
end

function BedwarsBed:cl_create()
    self.client_glowEffect = sm.effect.createEffect( "PlayerStart - Glow", self.interactable )
	self.client_glowEffect:start()
end
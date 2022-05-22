Rule = {}
local Rule_mt = Class(Rule, ScoreBoardElement)
---@class Rule : ScoreBoardElement
function Rule.new(name, default, title, valuesData, custom_mt)
	local self = ScoreBoardElement.new(name, title, custom_mt or Rule_mt)
	self.currentIx = default or 1
	self.title = title
	self.values = {}
	self.texts = {}
	if valuesData then
		for i, data in pairs(valuesData) do 
			if data.name then
				Rule[data.name] = data.value
			end
			table.insert(self.values, data.value)
			table.insert(self.texts, data.text)
		end
	end
	return self
end

function Rule.createFromXml(data)
	return Rule.new(data.name, data.default, data.title, data.values)
end

function Rule:getText()
	if next(self.texts) ~= nil and self.texts[self.currentIx] then 
		return self.texts[self.currentIx]
	end
	return tostring(self:getValue())
end

function Rule:getValue()
	return self.values[self.currentIx]
end

function Rule:onTextInput(value)
		
end

function Rule:isTextInputAllowed()
	return false
end

function Rule:onClick()
	self.currentIx = self.currentIx + 1 
	if self.currentIx > #self.values then 
		self.currentIx = 1
	end
	ChangeElementEvent.sendEvent(self, ChangeElementEvent.RULE)
end

function Rule:setSavedValue(value)
	if value ~= nil then
		self.currentIx = value
	end
end

function Rule:getValueToSave()
	return self.currentIx
end


function Rule:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self:getParent().id)
	streamWriteUInt8(streamId, self.id)
end

function Rule.readStream(streamId, connection)
	local categoryId = streamReadUInt8(streamId)
	local id = streamReadUInt8(streamId)
	g_ruleManager:getList():getElement(categoryId, id):onClick()
end

local function updateVehicleLeaseRule(screen, storeItem, vehicle, saleItem)
	screen.leaseButton:setVisible(screen.leaseButton:getIsVisible() and g_ruleManager:getGeneralRuleValue("leaseVehicle") ~= Rule.LEASE_VEHICLE_DEACTIVATED)
	screen.buttonsPanel:invalidateLayout()
end
ShopConfigScreen.updateButtons = Utils.appendedFunction(ShopConfigScreen.updateButtons, updateVehicleLeaseRule)

local function updateVehicleLeaseMissionRule(screen, superFunc, state, canLease)
	if g_ruleManager:getGeneralRuleValue("leaseVehicle") ~= Rule.LEASE_VEHICLE_ALLOWED then
		superFunc(screen, state, false)
		return
	end
	superFunc(screen, state, canLease)
end
InGameMenuContractsFrame.setButtonsForState = Utils.overwrittenFunction(InGameMenuContractsFrame.setButtonsForState, updateVehicleLeaseMissionRule)

local function updateMissionRules(mission, superFunc, ...)
	if not g_ruleManager:isMissionAllowed(mission) then 
		return false
	end
	return superFunc(mission, ...)
end
AbstractMission.init = Utils.overwrittenFunction(AbstractMission.init, updateMissionRules)

local function updateMissionRules2(manager, ...)
	for _, mission in ipairs(manager.missions) do
		if not g_ruleManager:isMissionAllowed(mission) then
			mission:delete()
		end
	end
end
MissionManager.updateMissions = Utils.appendedFunction(MissionManager.updateMissions, updateMissionRules2)

function Rule.getCanStartHelper(currentMission, superFunc, permission, ...)
	if permission == "hireAssistant" and g_ruleManager:getGeneralRuleValue("maxHelpers") <= #currentMission.aiSystem.activeJobVehicles  then 
		return false
	end
	
	return superFunc(currentMission, permission, ...)
end

--g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId())

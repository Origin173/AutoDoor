-- Client timed actions for installing / removing the auto door motor.
-- Mirrors the vanilla ISGrabItemAction / ISActivateGenerator patterns:
-- crouch "Loot" animation, progress ring on the held item, and the standard
-- timed-action progress bar at the bottom of the screen. The actual install /
-- removal runs server-side when the action completes.
require "TimedActions/ISBaseTimedAction"

ISAutoDoorAction = ISBaseTimedAction:derive("ISAutoDoorAction")

function ISAutoDoorAction:isValid()
    local chr = self.character
    if not chr or chr:isDead() then return false end

    if self.mode == "install" then
        local door = self.door
        if not door or door:isDestroyed() then return false end
        if door:isLockedByKey() then return false end
        if AutoDoor.isAutoDoor(door) then return false end
        if not AutoDoor.getRemote(chr) then return false end
        if not AutoDoor.getMotor(chr) then return false end
        if not AutoDoor.getBattery(chr) then return false end
        local csq, dsq = chr:getCurrentSquare(), door:getSquare()
        if not csq or not dsq or csq:isBlockedTo(dsq) then return false end
    elseif self.mode == "uninstall" then
        local door = self.door
        if not door or door:isDestroyed() then return false end
        if not AutoDoor.isAutoDoor(door) then return false end
        local csq, dsq = chr:getCurrentSquare(), door:getSquare()
        if not csq or not dsq or csq:isBlockedTo(dsq) then return false end
    elseif self.mode == "pickup" then
        local worldItem = self.motorWorldItem
        if not worldItem then return false end
        local sq = worldItem:getSquare()
        if not sq then return false end
        if not sq:getWorldObjects():contains(worldItem) then return false end
        if AutoDoor.getMotorFromWorldObject(worldItem) == nil then return false end
        local csq = chr:getCurrentSquare()
        if not csq or csq:isBlockedTo(sq) then return false end
    end
    return true
end

function ISAutoDoorAction:waitToStart()
    self:faceTarget()
    return self.character:shouldBeTurning()
end

function ISAutoDoorAction:update()
    self:faceTarget()
    if self.jobItem then
        self.jobItem:setJobDelta(self:getJobDelta())
    end
end

function ISAutoDoorAction:faceTarget()
    local target = self.mode == "pickup" and self.motorWorldItem or self.door
    if target and target.getSquare then
        self.character:faceThisObject(target)
    end
end

function ISAutoDoorAction:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
    if self.jobItem then
        self.jobItem:setJobType(self.jobText)
        self.jobItem:setJobDelta(0.0)
    end
end

function ISAutoDoorAction:stop()
    if self.jobItem then
        self.jobItem:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISAutoDoorAction:complete()
    local chr = self.character
    if self.mode == "install" then
        local remote = AutoDoor.getRemote(chr)
        if not remote then return false end
        AutoDoor.ensureRemoteId(chr, remote)
        sendClientCommand(chr, "AutoDoor", "Install",
            { x = self.door:getX(), y = self.door:getY(), z = self.door:getZ() })
    elseif self.mode == "uninstall" then
        sendClientCommand(chr, "AutoDoor", "Uninstall",
            { x = self.door:getX(), y = self.door:getY(), z = self.door:getZ() })
    elseif self.mode == "pickup" then
        local sq = self.motorWorldItem:getSquare()
        if not sq then return false end
        sendClientCommand(chr, "AutoDoor", "UninstallMotor",
            { x = sq:getX(), y = sq:getY(), z = sq:getZ() })
    end
    return true
end

function ISAutoDoorAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    if self.mode == "install" or self.mode == "uninstall" then return 90 end
    return 60
end

function ISAutoDoorAction:new(character, door, motorWorldItem, mode)
    local o = ISBaseTimedAction.new(self, character)
    o.door = door
    o.motorWorldItem = motorWorldItem
    o.mode = mode
    if mode == "install" then
        o.jobItem = AutoDoor.getMotor(character)
        o.jobText = AutoDoor.text("IGUI_AutoDoor_Installing", "Installing Auto Door Motor")
    elseif mode == "uninstall" then
        local motorItem = AutoDoor.getMotorItem(door)
        if motorItem and motorItem.getItem then
            o.jobItem = motorItem:getItem()
        end
        o.jobText = AutoDoor.text("IGUI_AutoDoor_Removing", "Removing Auto Door Opener")
    elseif mode == "pickup" then
        if motorWorldItem and motorWorldItem.getItem then
            o.jobItem = motorWorldItem:getItem()
        end
        o.jobText = AutoDoor.text("IGUI_AutoDoor_PickingUp", "Picking Up Motor")
    end
    o.maxTime = o:getDuration()
    return o
end

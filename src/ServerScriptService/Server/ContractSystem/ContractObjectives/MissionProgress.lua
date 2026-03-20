local MissionProgress = {}
MissionProgress.__index = MissionProgress

local function normalizeToken(value)
    if type(value) ~= "string" then
        return nil
    end
    return value:lower():gsub("[%s_%-]+", "")
end

function MissionProgress.new()
    local self = setmetatable({}, MissionProgress)
    return self
end

function MissionProgress:CreateProgress(objectives)
    local progress = {}
    for index, objective in ipairs(objectives or {}) do
        local target = math.max(1, tonumber(objective.target) or 1)
        progress[index] = {
            id = string.format("obj_%d", index),
            objectiveType = objective.objectiveType,
            description = objective.description,
            target = target,
            current = 0,
            completed = false,
            toolType = objective.toolType,
        }
    end
    return progress
end

function MissionProgress:_markObjective(objective, amount)
    if objective.completed then
        return false
    end
    objective.current = math.min(objective.target, objective.current + (amount or 1))
    if objective.current >= objective.target then
        objective.completed = true
        return true
    end
    return false
end

function MissionProgress:ApplySignal(session, signalType, payload)
    local completed = {}
    local objectives = session.objectives or {}
    local runtime = session.runtime or {}
    runtime.evidenceSet = runtime.evidenceSet or {}
    local detectedEvidenceKey = nil
    local detectedEvidenceWasNew = false

    if signalType == "hunt_started" then
        runtime.huntStarted = true
    elseif signalType == "hunt_ended" and runtime.huntStarted then
        runtime.huntCompleted = true
    end

    if signalType == "evidence_detected" and type(payload.evidenceType) == "string" then
        detectedEvidenceKey = payload.evidenceType:gsub("%s+", "")
        detectedEvidenceWasNew = runtime.evidenceSet[detectedEvidenceKey] ~= true
        runtime.evidenceSet[detectedEvidenceKey] = true
    end

    for _, objective in ipairs(objectives) do
        local shouldComplete = false

        if (objective.objectiveType == "IdentifyGhostType" or objective.objectiveType == "IdentifyGhost") and signalType == "ghost_identified" then
            if payload.identified == true then
                shouldComplete = self:_markObjective(objective, 1)
            end
        elseif objective.objectiveType == "CollectEvidence" and signalType == "evidence_detected" then
            if detectedEvidenceKey and detectedEvidenceWasNew then
                shouldComplete = self:_markObjective(objective, 1)
            end
        elseif objective.objectiveType == "SurviveHunt" and signalType == "hunt_ended" then
            shouldComplete = runtime.huntCompleted == true and self:_markObjective(objective, 1)
        elseif objective.objectiveType == "FindGhostRoom" then
            if signalType == "ghost_room_found" then
                shouldComplete = self:_markObjective(objective, 1)
            elseif signalType == "evidence_detected" then
                local nearGhostRoom = payload.nearGhostRoom == true or payload.toolNearGhostRoom == true
                local roomMatch = payload.roomId and session.ghostRoomId and payload.roomId == session.ghostRoomId
                if nearGhostRoom or roomMatch then
                    shouldComplete = self:_markObjective(objective, 1)
                end
            end
        elseif objective.objectiveType == "UseSpecificTool" and signalType == "tool_used" then
            local expected = normalizeToken(objective.toolType)
            local provided = normalizeToken(payload.toolType)
            if expected and provided and expected == provided then
                shouldComplete = self:_markObjective(objective, 1)
            end
        elseif objective.objectiveType == "CompleteMatch" and signalType == "match_ended" then
            shouldComplete = self:_markObjective(objective, 1)
        end

        if shouldComplete and objective.completed then
            table.insert(completed, objective)
        end
    end

    session.runtime = runtime
    return completed
end

function MissionProgress:AreAllCompleted(objectives)
    for _, objective in ipairs(objectives or {}) do
        if objective.completed ~= true then
            return false
        end
    end
    return true
end

return MissionProgress

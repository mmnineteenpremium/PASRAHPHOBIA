local SystemDiagnostics = {}

local diagnostics = {
    systemsLoaded = {},
    systemsFailed = {},
    initTimes = {},
    bootOrder = {}
}

function SystemDiagnostics.RegisterSystem(name)
    table.insert(diagnostics.bootOrder, name)
end

function SystemDiagnostics.MarkLoaded(name, initTime)
    diagnostics.systemsLoaded[name] = true
    diagnostics.initTimes[name] = initTime
end

function SystemDiagnostics.MarkFailed(name, err)
    diagnostics.systemsFailed[name] = err
end

function SystemDiagnostics.PrintReport()

    print(" ")
    print("===== PASRAHPHOBIA SYSTEM BOOT DIAGNOSTICS =====")

    print(" ")
    print("SYSTEM LOAD ORDER")
    for i, name in ipairs(diagnostics.bootOrder) do
        print(i, name)
    end

    print(" ")
    print("SYSTEM INIT TIMES")
    for name, time in pairs(diagnostics.initTimes) do
        print(name .. " : " .. tostring(time) .. " ms")
    end

    print(" ")
    print("FAILED SYSTEMS")
    for name, err in pairs(diagnostics.systemsFailed) do
        print(name .. " -> " .. tostring(err))
    end

    local loadedCount = 0
    for _ in pairs(diagnostics.systemsLoaded) do
        loadedCount += 1
    end

    local failedCount = 0
    for _ in pairs(diagnostics.systemsFailed) do
        failedCount += 1
    end

    print(" ")
    print("TOTAL SYSTEMS")
    print("Loaded:", loadedCount)
    print("Failed:", failedCount)

    print("===== END DIAGNOSTICS =====")
end

return SystemDiagnostics

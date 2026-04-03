local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_PURCHASE_CURRENCY = "MM"

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path or {}) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveCatalogModule()
    local pathOptions = {
        { "shared", "DataTypes", "ShopCatalog", "ModuleScript" },
        { "Shared", "DataTypes", "ShopCatalog", "ModuleScript" },
        { "shared", "DataTypes", "ShopCatalog" },
        { "Shared", "DataTypes", "ShopCatalog" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
    end

    return nil
end

local function toUserId(player)
    if type(player) == "number" then
        return player
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

local function nowClock()
    return os.clock()
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
        RoyalPassSystem = Services.Get(self._deps, "RoyalPassSystem"),
    }
end

function Service:Init()
    self._state:Set("shopCatalog", self:LoadShopCatalog())
    self._state:Set("activeTransactions", {})
    self._state:Set("purchaseHistory", {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:LoadShopCatalog()
    local moduleScript = resolveCatalogModule()
    local loadedCatalog = safeRequire(moduleScript)
    if type(loadedCatalog) ~= "table" then
        return {}
    end

    local normalized = {}
    for _, item in pairs(loadedCatalog) do
        if type(item) == "table" and type(item.id) == "string" and item.id ~= "" then
            normalized[item.id] = {
                id = item.id,
                name = item.name or item.id,
                price = tonumber(item.price) or 0,
                currency = item.currency or DEFAULT_PURCHASE_CURRENCY,
                category = item.category or "Unknown",
                slot = item.slot,
                rarity = item.rarity,
                rarityLabel = item.rarityLabel or item.rarity,
                tags = type(item.tags) == "table" and item.tags or nil,
                marketplaceType = item.marketplaceType,
                marketplaceId = tonumber(item.marketplaceId) or nil,
                entitlementKey = item.entitlementKey,
                royalPassPremium = item.royalPassPremium == true,
                grantItem = item.grantItem ~= false,
                grantCurrency = item.grantCurrency,
                grantCurrencyAmount = tonumber(item.grantCurrencyAmount) or nil,
            }
        end
    end
    return normalized
end

function Service:GetCatalog()
    return self._state:Get("shopCatalog") or {}
end

function Service:_getCatalogItem(itemId)
    local catalog = self._state:Get("shopCatalog") or {}
    return catalog[itemId]
end

function Service:_normalizePurchaseCurrency(currency)
    if type(currency) ~= "string" or currency == "" then
        return DEFAULT_PURCHASE_CURRENCY
    end
    if currency == "RBX" then
        return "Robux"
    end
    return currency
end

function Service:IsMarketplacePurchase(item)
    if type(item) ~= "table" then
        return false
    end
    return self:_normalizePurchaseCurrency(item.currency) == "Robux"
end

function Service:_getEconomyService()
    local economy = self._dependencies.EconomySystem
    if type(economy) == "table" and type(economy.Service) == "table" then
        return economy.Service
    end
    return economy
end

function Service:_getInventoryService()
    local inventory = self._dependencies.InventorySystem
    if type(inventory) == "table" and type(inventory.Service) == "table" then
        return inventory.Service
    end
    return inventory
end

function Service:_getPersistenceService()
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) == "table" and type(persistence.Service) == "table" then
        return persistence.Service
    end
    return persistence
end

function Service:_getRoyalPassService()
    local royalPass = self._dependencies.RoyalPassSystem
    if type(royalPass) == "table" and type(royalPass.Service) == "table" then
        return royalPass.Service
    end
    return royalPass
end

function Service:_persistInventorySnapshot(player, userId)
    local persistence = self:_getPersistenceService()
    if type(persistence) ~= "table" or type(persistence.SaveInventory) ~= "function" then
        return
    end

    local snapshot = nil
    local inventory = self:_getInventoryService()
    if type(inventory) == "table" and type(inventory.GetSnapshotForPersistence) == "function" then
        local ok, result = pcall(function()
            return inventory:GetSnapshotForPersistence(player)
        end)
        if ok and type(result) == "table" then
            snapshot = result
        end
    end

    pcall(function()
        persistence:SaveInventory(userId, snapshot)
    end)
end

function Service:_refundCurrency(player, userId, amount, itemId, reason)
    local economy = self:_getEconomyService()
    if type(economy) ~= "table" or type(economy.AddCurrency) ~= "function" then
        return
    end

    local refunded = false
    pcall(function()
        local ok = economy:AddCurrency(player, "MM", amount, "ShopPurchaseRefund")
        refunded = ok ~= false
    end)

    if refunded then
        self:_publish("PurchaseRefunded", {
            player = player,
            userId = userId,
            itemId = itemId,
            amount = amount,
            reason = reason or "grant_failed",
        })
    end
end

function Service:_alreadyOwned(player, itemId, category)
    local inventory = self:_getInventoryService()
    if type(inventory) ~= "table" then
        return false
    end

    if type(inventory.HasItem) == "function" then
        local ok, result = pcall(function()
            return inventory:HasItem(player, itemId)
        end)
        if ok then
            return result == true
        end
    end

    if category == "Cosmetic" and type(inventory.OwnsCosmetic) == "function" then
        local ok, result = pcall(function()
            return inventory:OwnsCosmetic(player, itemId)
        end)
        if ok then
            return result == true
        end
    end

    return false
end

function Service:ValidatePurchase(player, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if type(itemId) ~= "string" or itemId == "" then
        return false, "invalid_item_id"
    end

    local item = self:_getCatalogItem(itemId)
    if type(item) ~= "table" then
        return false, "item_not_found"
    end
    if type(item.price) ~= "number" or item.price <= 0 then
        return false, "invalid_price"
    end

    local purchaseCurrency = self:_normalizePurchaseCurrency(item.currency)
    if purchaseCurrency ~= "MM" and purchaseCurrency ~= "PP" and purchaseCurrency ~= "Robux" then
        return false, "unsupported_currency"
    end
    if purchaseCurrency == "Robux" then
        local marketplaceType = item.marketplaceType
        if marketplaceType ~= "GamePass" and marketplaceType ~= "DeveloperProduct" then
            return false, "marketplace_type_missing"
        end
        if type(item.marketplaceId) ~= "number" or item.marketplaceId <= 0 then
            return false, "marketplace_id_missing"
        end
    end

    local activeTransactions = self._state:Get("activeTransactions") or {}
    if activeTransactions[userId] ~= nil then
        return false, "transaction_in_progress"
    end

    if self:_alreadyOwned(player, itemId, item.category) then
        return false, "already_owned"
    end

    local economy = self:_getEconomyService()
    if type(economy) ~= "table" then
        return false, "economy_unavailable"
    end

    if purchaseCurrency == "Robux" then
        return true, nil, item, userId
    end

    local balance = nil
    if type(economy.GetBalance) == "function" then
        local ok, result = pcall(function()
            return economy:GetBalance(player)
        end)
        if ok then
            if type(result) == "table" then
                balance = tonumber(result.MM or result.currency or result.balance)
            else
                balance = tonumber(result)
            end
        end
    end

    if type(balance) == "number" and balance < item.price then
        return false, "insufficient_currency"
    end

    return true, nil, item, userId
end

function Service:ResolvePurchaseIntent(player, itemId)
    local ok, err, item, userId = self:ValidatePurchase(player, itemId)
    if not ok then
        return false, err
    end

    local purchaseCurrency = self:_normalizePurchaseCurrency(item.currency)
    if purchaseCurrency == "Robux" then
        return true, nil, {
            flow = "Marketplace",
            userId = userId,
            itemId = itemId,
            item = item,
            purchaseCurrency = purchaseCurrency,
            marketplaceType = item.marketplaceType,
            marketplaceId = item.marketplaceId,
        }
    end

    return true, nil, {
        flow = "SoftCurrency",
        userId = userId,
        itemId = itemId,
        item = item,
        purchaseCurrency = purchaseCurrency,
    }
end

function Service:GrantItem(player, itemId, itemData)
    local inventory = self:_getInventoryService()
    if type(inventory) ~= "table" then
        return false, "inventory_unavailable"
    end

    if type(inventory.GrantItem) == "function" then
        local ok, result = pcall(function()
            return inventory:GrantItem(player, itemId, itemData)
        end)
        if ok and result ~= false then
            return true
        end
    end

    if itemData and itemData.category == "Cosmetic" and type(inventory.AddCosmeticOwnership) == "function" then
        local ok = pcall(function()
            inventory:AddCosmeticOwnership(player, itemId)
        end)
        if ok then
            return true
        end
    end

    if type(inventory.StoreItem) == "function" then
        local ok = pcall(function()
            inventory:StoreItem(player, itemId)
        end)
        if ok then
            return true
        end
    end

    return false, "grant_item_failed"
end

function Service:ProcessPurchase(player, itemId)
    local ok, err, item, userId = self:ValidatePurchase(player, itemId)
    if not ok then
        self:_publish("PurchaseFailed", {
            player = player,
            userId = userId,
            itemId = itemId,
            reason = err,
        })
        return false, err
    end

    local purchaseCurrency = self:_normalizePurchaseCurrency(item.currency)
    if purchaseCurrency == "Robux" then
        return false, "marketplace_prompt_required"
    end

    local activeTransactions = self._state:Get("activeTransactions") or {}
    activeTransactions[userId] = {
        itemId = itemId,
        startedAt = nowClock(),
    }
    self._state:Set("activeTransactions", activeTransactions)

    local economy = self:_getEconomyService()
    local spent = false
    local spendErr = "spend_failed"

    if type(economy.SpendCurrency) == "function" then
        local spendOk, resultA, resultB = pcall(function()
            return economy:SpendCurrency(player, purchaseCurrency, item.price, "ShopPurchase")
        end)
        if spendOk then
            if resultA == false then
                spent = false
                spendErr = resultB or "insufficient_currency"
            else
                spent = true
            end
        end
    end

    if not spent then
        activeTransactions[userId] = nil
        self._state:Set("activeTransactions", activeTransactions)
        self:_publish("PurchaseFailed", {
            player = player,
            userId = userId,
            itemId = itemId,
            reason = spendErr,
        })
        return false, spendErr
    end

    local granted, grantErr = self:GrantItem(player, itemId, item)
    if not granted then
        self:_refundCurrency(player, userId, item.price, itemId, grantErr)
        activeTransactions[userId] = nil
        self._state:Set("activeTransactions", activeTransactions)
        self:_publish("PurchaseFailed", {
            player = player,
            userId = userId,
            itemId = itemId,
            reason = grantErr,
        })
        return false, grantErr
    end

    self:_persistInventorySnapshot(player, userId)

    local history = self._state:Get("purchaseHistory") or {}
    history[userId] = history[userId] or {}
    table.insert(history[userId], {
        itemId = itemId,
        price = item.price,
        category = item.category,
        purchasedAt = os.time(),
    })
    self._state:Set("purchaseHistory", history)

    activeTransactions[userId] = nil
    self._state:Set("activeTransactions", activeTransactions)

        self:_publish("ItemPurchased", {
            player = player,
            userId = userId,
            itemId = itemId,
            price = item.price,
            category = item.category,
            currency = purchaseCurrency,
            source = "SoftCurrency",
        })
    return true
end

function Service:_grantEntitlements(player, item)
    local grantedAny = false
    local economy = self:_getEconomyService()
    if type(item.entitlementKey) == "string" and item.entitlementKey ~= "" then
        if type(economy) == "table" and type(economy.SetPassOwnership) == "function" then
            local ok = pcall(function()
                economy:SetPassOwnership(player, {
                    [item.entitlementKey] = true,
                })
            end)
            grantedAny = ok or grantedAny
        end
    end

    if item.royalPassPremium == true then
        local royalPass = self:_getRoyalPassService()
        if type(royalPass) == "table" and type(royalPass.SetPremiumOwnership) == "function" then
            local ok = pcall(function()
                royalPass:SetPremiumOwnership(player, true)
            end)
            grantedAny = ok or grantedAny
        end
    end

    return grantedAny
end

function Service:GrantMarketplacePurchase(player, itemId, context)
    local item = self:_getCatalogItem(itemId)
    if type(item) ~= "table" then
        return false, "item_not_found"
    end
    if not self:IsMarketplacePurchase(item) then
        return false, "not_marketplace_item"
    end

    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local grantedEntitlements = self:_grantEntitlements(player, item)
    local grantedInventory = true
    if item.grantItem ~= false and not self:_alreadyOwned(player, itemId, item.category) then
        grantedInventory, _ = self:GrantItem(player, itemId, item)
    end

    local grantedCurrency = false
    if type(item.grantCurrency) == "string" and type(item.grantCurrencyAmount) == "number" and item.grantCurrencyAmount > 0 then
        local economy = self:_getEconomyService()
        if type(economy) == "table" and type(economy.AddCurrency) == "function" then
            local ok = pcall(function()
                economy:AddCurrency(player, item.grantCurrency, item.grantCurrencyAmount, "MarketplacePurchase")
            end)
            grantedCurrency = ok or grantedCurrency
        end
    end

    if item.grantItem ~= false and grantedInventory == false and grantedEntitlements ~= true and grantedCurrency ~= true then
        return false, "grant_item_failed"
    end

    self:_persistInventorySnapshot(player, userId)

    local history = self._state:Get("purchaseHistory") or {}
    history[userId] = history[userId] or {}
    table.insert(history[userId], {
        itemId = itemId,
        price = item.price,
        currency = self:_normalizePurchaseCurrency(item.currency),
        category = item.category,
        purchasedAt = os.time(),
        source = type(context) == "table" and context.source or "Marketplace",
        receiptId = type(context) == "table" and context.receiptId or nil,
        marketplaceType = item.marketplaceType,
        marketplaceId = item.marketplaceId,
    })
    self._state:Set("purchaseHistory", history)

    self:_publish("ItemPurchased", {
        player = player,
        userId = userId,
        itemId = itemId,
        price = item.price,
        category = item.category,
        currency = self:_normalizePurchaseCurrency(item.currency),
        source = type(context) == "table" and context.source or "Marketplace",
        marketplaceType = item.marketplaceType,
        marketplaceId = item.marketplaceId,
    })
    return true
end

return Service

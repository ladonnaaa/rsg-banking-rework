local RSGCore = exports['rsg-core']:GetCoreObject()
local SendDiscordWebhook = require('server.discord_webhook')
local AntiSpam = {}

lib.locale()

local function LogTransaction(citizenid, type, amount, description)
    MySQL.insert('INSERT INTO bank_transactions (citizenid, type, amount, description) VALUES (?, ?, ?, ?)', {
        citizenid, type, tonumber(amount), description
    })
end

local function ProcessLoansAndExekuce(citizenid)
    local isBlacklisted = false
    local totalDebt = 0.0
    local loans = MySQL.query.await('SELECT * FROM bank_loans WHERE citizenid = ? AND status != "paid"', {citizenid})
    
    if loans and #loans > 0 then
        for _, loan in ipairs(loans) do
            local isPastDue = MySQL.scalar.await('SELECT IF(due_date < NOW(), 1, 0) FROM bank_loans WHERE id = ?', {loan.id})
            local loanAmount = tonumber(loan.amount) or 0.0

            if isPastDue == 1 and loan.status == 'active' then
                local newAmount = loanAmount * Config.LoanPenaltyMultiplier
                MySQL.update.await('UPDATE bank_loans SET amount = ?, status = "defaulted" WHERE id = ?', {newAmount, loan.id})
                totalDebt = totalDebt + newAmount
                isBlacklisted = true
            elseif loan.status == 'defaulted' then
                totalDebt = totalDebt + loanAmount
                isBlacklisted = true
            else
                totalDebt = totalDebt + loanAmount
            end
        end
    end
    
    return isBlacklisted, totalDebt
end

RegisterNetEvent('rsg-banking:server:opensafedeposit', function(town)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local stashName = 'safedeposit_' .. Player.PlayerData.citizenid .. '_' .. town
    exports['rsg-inventory']:OpenInventory(src, stashName, {
        label = locale('safe_deposit'),
        maxweight = Config.StorageMaxWeight,
        slots = Config.StorageMaxSlots
    })
end)

RSGCore.Functions.CreateCallback('rsg-banking:getBankingInformation', function(source, cb, moneytype)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    
    local cid = Player.PlayerData.citizenid
    local isBlacklisted, totalDebt = ProcessLoansAndExekuce(cid)
    local logs = MySQL.query.await('SELECT * FROM bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 15', {cid})

    if not Player.PlayerData.metadata['savings'] then Player.Functions.SetMetaData('savings', 0) end

    cb({
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        bank = tonumber(Player.PlayerData.money[moneytype]) or 0,
        cash = tonumber(Player.Functions.GetMoney('cash')) or 0,
        savings = tonumber(Player.PlayerData.metadata['savings']) or 0,
        loan = totalDebt,
        blacklisted = isBlacklisted,
        logs = logs
    })
end)

local function RefreshClientUI(src, Player, moneytype)
    local cid = Player.PlayerData.citizenid
    local isBlacklisted, totalDebt = ProcessLoansAndExekuce(cid)
    local logs = MySQL.query.await('SELECT * FROM bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 15', {cid})

    TriggerClientEvent('rsg-banking:client:UpdateUI', src, {
        bank = tonumber(Player.Functions.GetMoney(moneytype)) or 0,
        cash = tonumber(Player.Functions.GetMoney('cash')) or 0,
        savings = tonumber(Player.PlayerData.metadata['savings']) or 0,
        loan = totalDebt,
        logs = logs
    })
end

RegisterNetEvent('rsg-banking:server:transact', function(type, amount, moneytype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local cid = Player.PlayerData.citizenid
    local currentTime = os.time()

    if AntiSpam[src] and (currentTime - AntiSpam[src]) < Config.AntiSpamCooldown then
        TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Zpomalte, úředník nestíhá zpracovávat.", "red")
        return
    end
    AntiSpam[src] = currentTime

    amount = lib.math.round(tonumber(amount) or 0, 2)
    
    if amount <= 0 then
        TriggerClientEvent('rsg-banking:client:UIMessage', src, "CHYBA", "Neplatná hodnota na směnce.", "red")
        return
    end

    local currentCash = tonumber(Player.Functions.GetMoney('cash')) or 0
    local currentBank = tonumber(Player.Functions.GetMoney(moneytype)) or 0
    local currentSavings = tonumber(Player.PlayerData.metadata['savings']) or 0
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname

    local isBlacklisted, totalDebt = ProcessLoansAndExekuce(cid)
    totalDebt = tonumber(totalDebt) or 0.0

    if type == 'withdraw' then
        if isBlacklisted then
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Byl uvalen zákaz výběrů kvůli nesplacené půjčce!", "red")
            return
        end

        local charge = 0
        local hasVip = false
        for _, job in pairs(Config.VIPJobs) do
            if Player.PlayerData.job.name == job then hasVip = true break end
        end
        if not hasVip then charge = amount * (Config.WithdrawChargeRate / 100) end
        
        local totalRemove = amount + charge

        if currentBank >= totalRemove then
            Player.Functions.RemoveMoney(moneytype, totalRemove, 'bank-withdraw')
            Player.Functions.AddMoney('cash', amount, 'bank-withdraw')
            LogTransaction(cid, 'withdraw', amount, "Výběr hotovosti")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Hotovost úspěšně vybrána z účtu.", "green")
            SendDiscordWebhook(playerName, moneytype, amount, "Withdrawal")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nedostatek financí na bankovním účtu.", "red")
        end

    elseif type == 'deposit' then
        if currentCash >= amount then
            Player.Functions.RemoveMoney('cash', amount, 'bank-deposit')
            Player.Functions.AddMoney(moneytype, amount, 'bank-deposit')
            LogTransaction(cid, 'deposit', amount, "Vklad hotovosti")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Hotovost úspěšně vložena na účet.", "green")
            SendDiscordWebhook(playerName, moneytype, amount, "Deposit")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nemáte u sebe tolik hotovosti.", "red")
        end

    elseif type == 'savings_deposit' then
        if currentBank >= amount then
            Player.Functions.RemoveMoney(moneytype, amount, 'savings-deposit')
            Player.Functions.SetMetaData('savings', currentSavings + amount)
            LogTransaction(cid, 'savings', amount, "Převod na spořicí účet")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Prostředky přesunuty na spořicí účet.", "green")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nedostatek financí pro převod.", "red")
        end

    elseif type == 'loan' then
        if isBlacklisted then
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nelze sjednat půjčku, máte záznam o exekuci!", "red")
            return
        end

        local activeLoansCount = MySQL.scalar.await('SELECT COUNT(*) FROM bank_loans WHERE citizenid = ? AND status != "paid"', {cid}) or 0
        if activeLoansCount >= Config.MaxActiveLoans then
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Dosáhli jste maximálního počtu aktivních půjček.", "red")
            return
        end

        if (totalDebt + amount) > Config.MaxLoanAmount then
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Požadavek převyšuje maximální povolený dluh ($"..Config.MaxLoanAmount..").", "red")
            return
        end

        MySQL.insert.await('INSERT INTO bank_loans (citizenid, amount, due_date, status) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY), "active")', {
            cid, amount, Config.LoanDaysToPay
        })
        
        Player.Functions.AddMoney(moneytype, amount, 'bank-loan')
        LogTransaction(cid, 'loan', amount, "Bankovní půjčka")
        RefreshClientUI(src, Player, moneytype)
        TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Půjčka poskytnuta. Splatnost: "..Config.LoanDaysToPay.." dny.", "green")
        SendDiscordWebhook(playerName, moneytype, amount, "Loan Issued")

    elseif type == 'loan_payback' then
        if currentBank < amount then
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nedostatek financí na účtu pro splátku.", "red")
            return
        end

        local loan = MySQL.query.await('SELECT * FROM bank_loans WHERE citizenid = ? AND status != "paid" ORDER BY due_date ASC LIMIT 1', {cid})
        if loan and loan[1] then
            local loanAmount = tonumber(loan[1].amount) or 0
            local payback = amount
            if amount > loanAmount then payback = loanAmount end
            
            Player.Functions.RemoveMoney(moneytype, payback, 'loan-payback')
            
            local remaining = loanAmount - payback
            if remaining <= 0.01 then
                MySQL.update.await('UPDATE bank_loans SET amount = 0, status = "paid" WHERE id = ?', {loan[1].id})
            else
                MySQL.update.await('UPDATE bank_loans SET amount = ? WHERE id = ?', {remaining, loan[1].id})
            end

            LogTransaction(cid, 'loan_payback', payback, "Splátka půjčky")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Splátka úspěšně stržena z účtu.", "green")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nemáte žádné evidované dluhy.", "red")
        end

    elseif type == 'sell_gold' then
        local goldItem = Player.Functions.GetItemByName('gold_bar')
        if goldItem and goldItem.amount >= amount then
            local reward = amount * Config.GoldBarPrice
            Player.Functions.RemoveItem('gold_bar', amount)
            Player.Functions.AddMoney(moneytype, reward, 'gold-sold')
            LogTransaction(cid, 'sell_gold', reward, "Odprodej zlata")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Zlato úspěšně vykoupeno.", "green")
            SendDiscordWebhook(playerName, moneytype, reward, "Gold Sold")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nemáte dostatečný počet zlatých cihel.", "red")
        end
        
    elseif type == 'create_moneyclip' then
        if currentBank >= amount then
            Player.Functions.RemoveMoney(moneytype, amount, 'bank-money_clip')
            Player.Functions.AddItem('money_clip', 1, false, { money = amount })
            LogTransaction(cid, 'money_clip', amount, "Vystavení šeku (Moneyclip)")
            RefreshClientUI(src, Player, moneytype)
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "SCHVÁLENO", "Bankovní šek byl úspěšně vystaven.", "green")
        else
            TriggerClientEvent('rsg-banking:client:UIMessage', src, "ZAMÍTNUTO", "Nedostatek financí na účtu.", "red")
        end
    end
end)
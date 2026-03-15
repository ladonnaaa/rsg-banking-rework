local function SendDiscordWebhook(playerName, targetName, amount, transactionType)
    if not Config.Discord.Enabled or Config.Discord.WebhookURL == "" then return end
    
    local color = Config.Discord.Color
    local emoji = "💰"
    local title = "Transaction Alert"
    
    if transactionType == "Withdrawal" and Config.Discord.TrackWithdrawals then
        color = 15158332 emoji = "💸" title = "Bank Withdrawal"
    elseif transactionType == "Deposit" and Config.Discord.TrackDeposits then
        color = 3066993 emoji = "💵" title = "Bank Deposit"
    elseif transactionType == "Player to Player Transfer" and Config.Discord.TrackTransfers then
        color = 3447003 emoji = "🤝" title = "Player Transfer"
    elseif transactionType == "Loan Issued" and Config.Discord.TrackLoans then
        color = 16753920 emoji = "📜" title = "Bank Loan Issued"
    elseif transactionType == "Gold Sold" and Config.Discord.TrackGold then
        color = 16766720 emoji = "🪙" title = "Gold Sold to Bank"
    else
        return
    end
    
    if amount >= Config.Discord.RoleMentionThreshold then
        emoji = "🚨 " .. emoji
        title = "**" .. title .. " - HIGH VALUE**"
    end
    
    local formattedAmount = tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    
    local fields = {
        { ["name"] = "💵 Amount", ["value"] = "**$" .. formattedAmount .. "**", ["inline"] = true },
        { ["name"] = "📊 Type", ["value"] = transactionType, ["inline"] = true }
    }
    
    if transactionType == "Player to Player Transfer" then
        table.insert(fields, { ["name"] = "👤 Sender", ["value"] = "`" .. playerName .. "`", ["inline"] = true })
        table.insert(fields, { ["name"] = "👤 Receiver",["value"] = "`" .. targetName .. "`", ["inline"] = true })
    else
        table.insert(fields, { ["name"] = "👤 Player", ["value"] = "`" .. playerName .. "`", ["inline"] = false })
        table.insert(fields, { ["name"] = "🏦 Account",["value"] = "`" .. targetName .. "`", ["inline"] = false })
    end
    
    local embed = {{
        ["title"] = emoji .. " " .. title,
        ["color"] = color,
        ["fields"] = fields,
        ["footer"] = { ["text"] = "RSG Banking | " .. os.date("%Y-%m-%d %H:%M:%S") }
    }}

    local content = ""
    if Config.Discord.RoleID ~= "" and amount >= Config.Discord.RoleMentionThreshold then
        content = "⚠️ <@&" .. Config.Discord.RoleID .. "> Large transaction detected!"
    end

    PerformHttpRequest(Config.Discord.WebhookURL, function(err, text, headers) end, 'POST', json.encode({
        username = "Bank System",
        embeds = embed,
        content = content
    }), { ['Content-Type'] = 'application/json' })
end

return SendDiscordWebhook
Config = {}

Config.Keybind    = 'J'
Config.OpenTime   = 8 
Config.CloseTime  = 18 
Config.AlwaysOpen = false 
Config.UseTarget  = true
Config.DistanceSpawn = 25.0 
Config.FadeIn = true

Config.StorageMaxWeight = 500000
Config.StorageMaxSlots = 15

Config.WithdrawChargeRate = 2 
Config.VIPJobs = { 'police', 'mayor', 'judge' }

Config.MaxLoanAmount = 100.0
Config.MaxActiveLoans = 3
Config.LoanDaysToPay = 3
Config.LoanPenaltyMultiplier = 1.5

Config.AntiSpamCooldown = 2

Config.GoldBarPrice = 25.0

Config.BankLocations = {
    {
        name = 'Valentine Bank',
        bankid = 'valbank',
        moneytype = 'valbank',
        coords = vector3(-308.4189, 775.8842, 118.7017),
        npcmodel = 'S_M_M_BankClerk_01',
        npccoords = vector4(-308.14, 773.98, 118.7, 4.75),
        hasGuard = true,
        guardmodel = 'S_M_M_PinLaw_01',
        guardcoords = vector4(-306.2, 771.5, 118.7, 45.0),
        showblip = true,
        blipsprite = 'blip_proc_bank',
        blipscale = 0.2
    },
    {
        name = 'Rhodes Bank',
        bankid = 'rhobank',
        moneytype = 'rhobank',
        coords = vector3(1292.307, -1301.539, 77.04012),
        npcmodel = 'S_M_M_BankClerk_01',
        npccoords = vector4(1291.22, -1303.28, 77.04, 316.53),
        hasGuard = true,
        guardmodel = 'S_M_M_PinLaw_01',
        guardcoords = vector4(1293.5, -1300.0, 77.04, 120.0),
        showblip = true,
        blipsprite = 'blip_proc_bank',
        blipscale = 0.2
    },
    {
        name = 'Saint Denis Bank',
        bankid = 'bank',
        moneytype = 'bank',
        coords = vector3(2644.579, -1292.313, 52.24956),
        npcmodel = 'S_M_M_BankClerk_01',
        npccoords = vector4(2644.75, -1294.15, 52.25, 17.11),
        hasGuard = true,
        guardmodel = 'S_M_M_SDCop_01',
        guardcoords = vector4(2641.5, -1291.8, 52.25, 200.0),
        showblip = true,
        blipsprite = 'blip_proc_bank', 
        blipscale = 0.2
    },
    {
        name = 'Blackwater Bank',
        bankid = 'blkbank',
        moneytype = 'blkbank',
        coords = vector3(-813.1633, -1277.486, 43.63771),
        npcmodel = 'S_M_M_BankClerk_01',
        npccoords = vector4(-813.2, -1275.38, 43.64, 173.1),
        hasGuard = true,
        guardmodel = 'S_M_M_PinLaw_01',
        guardcoords = vector4(-815.0, -1274.0, 43.64, 250.0),
        showblip = true,
        blipsprite = 'blip_proc_bank', 
        blipscale = 0.2
    },
    {
        name = 'Armadillo Bank',
        bankid = 'armbank',
        moneytype = 'armbank',
        coords = vector3(-3666.25, -2626.57, -13.59),
        npcmodel = 'S_M_M_BankClerk_01',
        npccoords = vector4(-3666.28, -2628.69, -13.59, 359.78),
        hasGuard = false,
        showblip = true,
        blipsprite = 'blip_proc_bank', 
        blipscale = 0.2
    }
}

Config.BankDoors = {
    { door = 2642457609, state = 0 },
    { door = 3886827663, state = 0 },
    { door = 1340831050, state = 1 },
    { door = 2343746133, state = 1 },
    { door = 334467483,  state = 1 },
    { door = 3718620420, state = 1 },
    { door = 576950805,  state = 1 },
    { door = 3317756151, state = 0 },
    { door = 3088209306, state = 0 },
    { door = 2058564250, state = 1 },
    { door = 3142122679, state = 1 },
    { door = 1634148892, state = 1 },
    { door = 3483244267, state = 1 },
    { door = 2158285782, state = 0 },
    { door = 1733501235, state = 0 },
    { door = 2089945615, state = 0 },
    { door = 2817024187, state = 0 },
    { door = 1830999060, state = 1 },
    { door = 965922748,  state = 1 },
    { door = 1634115439, state = 1 },
    { door = 1751238140, state = 1 },
    { door = 531022111,  state = 0 },
    { door = 2117902999, state = 1 },
    { door = 2817192481, state = 1 },
    { door = 1462330364, state = 1 },
    { door = 3101287960, state = 0 },
    { door = 3550475905, state = 1 },
    { door = 1329318347, state = 1 },
    { door = 1366165179, state = 1 }
}

Config.Discord = {
    WebhookURL = "", 
    RoleID = "",
    Enabled = false,
    TransactionThreshold = 0,
    RoleMentionThreshold = 1000,
    Color = 16711680,
    TrackWithdrawals = true,
    TrackDeposits = true,
    TrackTransfers = true,
    TrackMoneyClips = true,
    TrackLoans = true,
    TrackGold = true
}
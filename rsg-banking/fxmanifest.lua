fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-banking - ladonna rework'
version '4.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua', 
    'config.lua'
}

server_scripts {
    'server/discord_webhook.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua',
    'client/npcs.lua'
}

ui_page 'ui/index.html'

files {
    'locales/*.json',
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/sounds/*'
}

dependencies {
    'rsg-core',
    'rsg-target',
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-marketplace-community'
description 'Premium open-source QBCore marketplace with a transparent glassmorphism NUI.'
author 'Lens931'
version '2.0.0'

shared_scripts {
    'shared/config.lua',
    'locales/*.lua',
    'shared/locale.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'client/nui/index.html'

files {
    'client/nui/index.html',
    'client/nui/style.css',
    'client/nui/app.js',
    'client/nui/locales.js'
}



dependencies {
    'qb-core',
    'oxmysql'
}

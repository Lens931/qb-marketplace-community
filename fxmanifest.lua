fx_version 'cerulean'
game 'gta5'

name 'qb-marketplace-community'
author 'Lens931 Community'
description 'Clean open-source QBCore marketplace system with NUI, SQL persistence, player listings, purchase flow and seller earnings.'
version '1.0.0'
license 'MIT'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'qb-core',
    'oxmysql'
}

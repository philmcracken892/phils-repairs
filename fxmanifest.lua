game 'rdr3'
fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'


description 'stashes'
version '1.0.0'

shared_scripts { 
	'@ox_lib/init.lua',
	'config.lua'
}

server_scripts {
	'server.lua',
    '@oxmysql/lib/MySQL.lua'
    
}

client_scripts {
	'client.lua',
}

dependencies {
    'ox_lib',
    'rsg-core'
    
}
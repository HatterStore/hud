fx_version 'cerulean'
game 'gta5'

-- Shared scripts (loaded before clients)
shared_scripts {
    '@ox_lib/init.lua',        -- external dependency
    'config/config.lua'        -- your main config
}

-- Client scripts (load after shared scripts)
client_scripts {
    'client/lib.lua',          -- if this exists, keep it first
    'client/**/*.lua',         -- all client scripts in client folder and subfolders
    'client/modules/*.lua'     -- any modules if you have a modules folder inside client
}

-- Server scripts
server_scripts {
    'server/**/*.lua'
}

-- UI page
ui_page 'web/index.html'

-- Files for UI
files {
    'web/**',
    'data/**',                 -- postal data, default settings, etc.
    'stream/**',               -- any streamed content
    'framework/**',            -- framework helpers
    'locales/**',               -- translations
}

-- Lua 5.4 support
lua54 'yes'
use_fxv2_oal 'yes'


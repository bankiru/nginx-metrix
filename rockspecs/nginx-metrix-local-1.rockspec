package = 'nginx-metrix'
version = 'local-1'
source = {
  url = "file://.",
}
description = {
  summary = 'Extended Nginx status and metrics.',
  detailed = [[nothing written]],
  homepage = 'https://github.com/bankiru/nginx-metrix/',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}
dependencies = {
  'lua >= 5.1',
  'lua-cjson >= 2.1',
  'fun-alloyed >= 0.1.3',
  'lust >= 0.1',
}

build = {
  type = "builtin",
  modules = {
    ['nginx-metrix.main'] = 'nginx-metrix/main.lua',
  },
  copy_directories = {
    "nginx-conf"
  }
}

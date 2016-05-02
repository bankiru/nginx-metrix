package = 'nginx-metrix'
version = 'scm-1'
source = {
  url = "https://github.com/bankiru/nginx-metrix.git",
  branch = "master"
}
description = {
  summary = 'Extended Nginx status and metrics.',
  detailed = [[nothing written]],
  homepage = 'https://github.com/bankiru/nginx-metrix/',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}
dependencies = {
  'lua ~> 5.1',
  'lua-cjson >= 2.1',
  'fun-alloyed >= 0.1.3',
  'inspect >= 3.1.0',
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

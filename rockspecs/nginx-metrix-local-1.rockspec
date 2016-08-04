package = 'nginx-metrix'

version = 'local-1'

source = {
  url = "file://src/",
  dir = "nginx-metrix",
}

description = {
  summary = 'Extended Nginx status and metrics.',
  detailed = [[Extended Nginx status and metrics.]],
  homepage = 'https://github.com/bankiru/nginx-metrix/',
  license = 'MIT <http://opensource.org/licenses/MIT>',
  maintainer = 'Boris Gorbylev <ekho@ekho.name>',
}

dependencies = {
  'lua ~> 5.1',
  'lpeg',
  'dkjson',
  'fun-alloyed',
  'inspect',
}

build = {
  type = "builtin",
  modules = {
    ['nginx-metrix'] = 'src/nginx-metrix.lua',
    ['nginx-metrix.aggregator'] = 'src/nginx-metrix/aggregator.lua',
    ['nginx-metrix.collectors'] = 'src/nginx-metrix/collectors.lua',
    ['nginx-metrix.logger'] = 'src/nginx-metrix/logger.lua',
    ['nginx-metrix.scheduler'] = 'src/nginx-metrix/scheduler.lua',
    ['nginx-metrix.serializer'] = 'src/nginx-metrix/serializer.lua',
    ['nginx-metrix.storage'] = 'src/nginx-metrix/storage.lua',
    ['nginx-metrix.validator'] = 'src/nginx-metrix/validator.lua',
    ['nginx-metrix.vhosts'] = 'src/nginx-metrix/vhosts.lua',
  },
}

stds.fun = require 'fun'
stds.is = require 'nginx-metrix.lib.is'

std = 'max+luajit+fun+ngx_lua'

files['tests'] = { std = "+busted" }

new_read_globals = {
  '__TEST__',
  'is',
  'copy',
}

stds.fun = require 'fun'

std = 'max+luajit+fun+ngx_lua'

files['spec'] = { std = "+busted" }

new_read_globals = {
  '__TEST__',
  'copy',
  'print_inspected',
}

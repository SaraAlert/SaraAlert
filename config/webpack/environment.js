const { environment } = require('@rails/webpacker')
const webpack = require('webpack')
const datatables = require('./loaders/datatables');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery/src/jquery',
  jQuery: 'jquery/src/jquery',
  jquery: 'jquery',
  'window.jQuery': 'jquery',
  Popper: ['popper.js', 'default']
}))

environment.loaders.prepend('datatables', datatables)

module.exports = environment

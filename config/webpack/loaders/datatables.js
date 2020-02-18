module.exports = {
  test: /datatables\.net.*/,
  use: [{
    loader: 'imports-loader?define=>false'
  }]
}

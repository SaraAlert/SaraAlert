const path = require('path');
const webpack = require('webpack');

const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';

// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
// Removes exported JavaScript files from CSS-only entries
// in this example, entry.custom will create a corresponding empty custom.js file
const FixStyleOnlyEntriesPlugin = require('webpack-fix-style-only-entries');

module.exports = {
  mode,
  optimization: {
    moduleIds: 'hashed',
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx|)$/,
        exclude: /node_modules/,
        use: ['babel-loader'],
      },
      {
        test: /\.s[ac]ss$/i,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
      },
    ],
  },
  resolve: {
    extensions: ['.js', '.jsx', '.scss', '.css'],
  },
  entry: {
    // application: ['./app/javascript/packs/application.js', './app/javascript/packs/stylesheets/application.scss'],
    application: ['./app/javascript/packs/application.js'],
  },
  output: {
    filename: '[name].js',
    sourceMapFilename: '[name].js.map',
    path: path.resolve(__dirname, '..', '..', 'app/assets/builds'),
  },
  plugins: [
    new FixStyleOnlyEntriesPlugin(),
    new MiniCssExtractPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1,
    }),
    new webpack.ProvidePlugin({
      $: 'jquery/src/jquery',
      jQuery: 'jquery/src/jquery',
      jquery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default'],
    }),
  ],
};

require('es6-shim');
require('core-js');

require("@rails/ujs").start()
require("@rails/activestorage").start()
require("channels")

var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);

import 'bootstrap'
import './stylesheets/application.scss'
import "@fortawesome/fontawesome-free/js/all";

// Browser Compatibility
require('es6-shim');
require('core-js');

// https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
if (!Element.prototype.matches) {
  Element.prototype.matches = Element.prototype.msMatchesSelector ||
                              Element.prototype.webkitMatchesSelector;
}
if (!Element.prototype.closest) {
  Element.prototype.closest = function(s) {
    var el = this;
    do {
      if (el.matches(s)) return el;
      el = el.parentElement || el.parentNode;
    } while (el !== null && el.nodeType === 1);
    return null;
  };
}

// Rails
require("@rails/ujs").start()
require("@rails/activestorage").start()
require("channels")

// React
var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);

// Styling
import 'bootstrap'
import './stylesheets/application.scss'
import "@fortawesome/fontawesome-free/js/all";

// DataTables
require("datatables.net-bs4")(window, $);
require("datatables.net-buttons-bs4")(window, $);
require("datatables.net-bs4/css/dataTables.bootstrap4.css");
require("datatables.net-buttons-bs4/css/buttons.bootstrap4.min.css");

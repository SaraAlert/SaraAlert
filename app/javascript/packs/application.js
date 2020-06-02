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

// Sentry
import * as Sentry from '@sentry/browser';
if (!!window.SENTRY_URL) {
  Sentry.init({
    dsn: window.SENTRY_URL,
    release: window.SARA_VERSION
  });
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
require("datatables.net-bs4/css/dataTables.bootstrap4.css");

// XSS sanitization
require("xss");

// DateTime helpers
window.moment = require("moment-timezone");
moment.suppressDeprecationWarnings = true;
import LocalTime from "local-time";
LocalTime.start();

// Authy Form Helpers
require("authy-form-helpers/src/form.authy.min.js")
require("authy-form-helpers/src/form.authy.min.css")

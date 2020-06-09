// Browser Compatibility
require('es6-shim');
require('core-js');

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

// React
var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);

// Styling
import './stylesheets/application.scss'
import "@fortawesome/fontawesome-free/js/all";

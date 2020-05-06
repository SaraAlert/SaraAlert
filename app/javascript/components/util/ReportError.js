import React from 'react';
import ReactDOM from 'react-dom';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import * as Sentry from '@sentry/browser';

// Error Reporting can happen in several ways
// User can pass in:
//   -  Direct response from Axios Catch Block
//   -  Error string (eg "could not send email")
//   -  Formatted Error Object following Schema below
//   -  Any other object (which will just be JSON stringified)

// User can also pass in optional flag whether they want to report to Sentry

// error: {
// (required) message: 'Example: There was an error...'
// (optional) httpStatus: 502
// (optional) origin: 'MonitorAnalytics'
// (optional) rawError: 'Failed to load resource: the server responded with a status of 500 (Internal Server Error)'
// }

const isDirectAxiosResponse = error => {
  error = JSON.parse(JSON.stringify(error));
  const axiosFields = ['config', 'message', 'name', 'stack'];
  return axiosFields.every(axiosField => Object.prototype.hasOwnProperty.call(error, axiosField));
};

export default function reportError(error, reportToSentry = true) {
  let errorMsgToDisplay = null; // What to show in the UI Toast
  let httpStatus = null;
  let errorExplanationString = null;

  if (error === undefined) {
    console.error('ERROR: Must provide Error to Report');
    return;
  }
  // We want the ability to just pass in direct responses from Axios so we handle that situation here
  // Axios objects are sometimes casted wierdly to string (hence all the JSON.parse/stringifys)
  if (isDirectAxiosResponse(error)) {
    if (error.response) {
      httpStatus = error.response.status;
    }
    error = JSON.parse(JSON.stringify(error));
    errorMsgToDisplay = error.message;
  } else {
    // User has passed in a string
    if (typeof error === 'string') {
      errorMsgToDisplay = error;
    } else {
      // If we've been handed a pre-formatted object
      if (Object.prototype.hasOwnProperty.call(error, 'httpStatus')) {
        errorMsgToDisplay = `Error ${error.httpStatus}: `;
        httpStatus = error.httpStatus;
      }
      if (Object.prototype.hasOwnProperty.call(error, 'message')) {
        errorMsgToDisplay += `${error.message}`;
      }
    }
  }
  if (reportToSentry) {
    Sentry.captureException(new Error(JSON.stringify(error)));
  }

  if (httpStatus !== null) {
    if (httpStatus >= 400 && httpStatus < 500) {
      if (httpStatus === 400) {
        errorExplanationString = 'Request contains incorrect syntax.';
      } else if (httpStatus === 401) {
        errorExplanationString = 'The Requested Resource Requires Authentication.';
      } else if (httpStatus === 403) {
        errorExplanationString = 'The Request could not be completed due to permission errors.';
      } else if (httpStatus === 404) {
        errorExplanationString = 'The Requested URL could not be found.';
      } else {
        errorExplanationString = 'The request for the resource contains bad syntax or cannot be filled for some other reason.';
      }
    } else if (httpStatus >= 500 && httpStatus < 600) {
      errorExplanationString = 'There was an error communicating with the Sara Alert System Server.';
    } else {
      errorExplanationString = 'There was an error.';
    }
  }

  ReactDOM.render(<ToastContainer closeOnClick pauseOnVisibilityChange draggable pauseOnHover />, document.getElementById('toast-mount-point'));
  console.error(error);
  toast.error(
    <div>
      <div>{errorExplanationString}</div>
      <div>Error: {errorMsgToDisplay || JSON.stringify(error)}</div>
    </div>,
    {
      autoClose: 8000,
      newestOnTop: true,
      pauseOnVisibilityChange: false,
      position: toast.POSITION.TOP_CENTER,
      hideProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      draggable: true,
    }
  );
}

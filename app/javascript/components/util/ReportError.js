import React from 'react';
import ReactDOM from 'react-dom';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import * as Sentry from '@sentry/browser';

export default function reportError(error, reportToSentry = true) {
  let httpStatus = null;
  let errorExplanationString = 'There was an problem with your request. ';

  if (error === undefined) {
    return;
  }

  if (error?.response) {
    httpStatus = error.response.status;
  } else if (error?.httpStatus) {
    httpStatus = error.httpStatus;
  }

  if (reportToSentry) {
    Sentry.captureException(error);
    if (error.hasOwnProperty('toJSON')) {
      Sentry.captureMessage(error.toJSON());
    }
  }

  if (httpStatus) {
    httpStatus = Number(httpStatus);
    switch (httpStatus) {
      case 400:
        errorExplanationString += 'Server reported malformed request.';
        break;
      case 401:
        errorExplanationString += 'Invalid authentication provided.';
        break;
      case 403:
        errorExplanationString += 'Invalid permission.';
        break;
      case 404:
        errorExplanationString += 'Failed to communicate with the Sara Alert Server.';
        break;
      case 500:
        errorExplanationString += 'An error occurred on the Sara Alert Server.';
        break;
      default:
        errorExplanationString += 'An unspecified error occurred.';
        break;
    }
  }

  ReactDOM.render(<ToastContainer closeOnClick pauseOnVisibilityChange draggable pauseOnHover />, document.getElementById('toast-mount-point'));

  console.error(error);

  toast.error(<div>{errorExplanationString}</div>, {
    autoClose: 8000,
    newestOnTop: true,
    pauseOnVisibilityChange: false,
    position: toast.POSITION.TOP_CENTER,
    hideProgressBar: false,
    closeOnClick: true,
    pauseOnHover: true,
    draggable: true,
  });
}

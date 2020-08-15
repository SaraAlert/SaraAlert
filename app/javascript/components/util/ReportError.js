import React from 'react';
import ReactDOM from 'react-dom';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import * as Sentry from '@sentry/browser';

export default function reportError(error, reportToSentry = true) {
  let httpStatus = null;
  let errorExplanationString = 'There was a problem with your request. ';

  if (error === undefined) {
    return;
  }

  if (typeof error === 'string' || error instanceof String) {
    errorExplanationString = error;
  }

  if (error?.response) {
    httpStatus = error.response.status;
  } else if (error?.httpStatus) {
    httpStatus = error.httpStatus;
  }

  if (reportToSentry) {
    Sentry.captureException(error);
  }

  if (httpStatus) {
    httpStatus = Number(httpStatus);
    switch (httpStatus) {
      case 400:
        errorExplanationString += 'Server reported malformed request (Error 400).';
        break;
      case 401:
        errorExplanationString += 'Invalid authentication provided (Error 401).';
        break;
      case 403:
        errorExplanationString += 'Invalid permission (Error 403).';
        break;
      case 404:
        errorExplanationString += 'Failed to communicate with the Sara Alert Server (Error 404).';
        break;
      case 500:
        errorExplanationString += 'An error occurred on the Sara Alert Server (Error 500).';
        break;
      case 504:
        errorExplanationString += 'The server timed out (Error 504).';
        break;
      default:
        errorExplanationString += 'An unspecified error occurred.';
        break;
    }
  }

  ReactDOM.render(
    <ToastContainer enableMultiContainer containerId={'errors'} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />,
    document.getElementById('toast-mount-point')
  );

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
    containerId: 'errors',
  });
}

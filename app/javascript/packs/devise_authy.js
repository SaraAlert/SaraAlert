$(document).ready(() => {
  $('a#authy-request-sms-link').unbind('ajax:success');
  $('a#authy-request-sms-link').bind('ajax:success', (evt, data, status, xhr) => {
    alert(data.message);
  });

  $('a#authy-request-phone-call-link').unbind('ajax:success');
  $('a#authy-request-phone-call-link').bind('ajax:success', (evt, data, status, xhr) => {
    alert(data.message);
  });
});

import libphonenumber from 'google-libphonenumber';
const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

/**
  * Formats values in the phone column to be human readable
  * @param {Object} data - Data about the cell this filter is called on.
*/
function formatPhoneNumber (data) {
  // Some components will call this with an object containing a value field containing a phone number
  // Others will pass in a phone value directly
  const phone = (Object.prototype.hasOwnProperty.call(data, 'value')) ? data.value : data
  if (phone === null) return ''

  const match = phone
    .replace('+1', '')
    .replace(/\D/g, '')
    .match(/^(\d{3})(\d{3})(\d{4})$/);
  return match ? +match[1] + '-' + match[2] + '-' + match[3] : '';
};

function phoneSchemaValidator (data) {
  return this.test({
    name: 'phone',
    exclusive: true,
    message: 'Please enter a valid Phone Number',
    test: value => {
      try {
        if (!value) {
          return true; // Blank numbers are allowed
        }
        // Make sure we'll be able to convert to E164 format at submission time
        return !!phoneUtil.format(phoneUtil.parse(value, 'US'), PNF.E164) && /(0|[2-9])\d{9}/.test(value.replace('+1', '').replace(/\D/g, ''));
      } catch (e) {
        return false;
      }
    },
  });
}

export {
  formatPhoneNumber,
  phoneSchemaValidator
}

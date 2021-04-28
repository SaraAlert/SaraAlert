// The styling of the React-Select component cannot be done
// with raw CSS. Custom objects can be defined here and included
// in each component as necessary
const cursorPointerStyle = {
  option: base => ({ ...base, cursor: 'pointer' }),
};

const vaccineModalSelectStyling = {
  menu: base => ({ ...base, zIndex: 9999 }),
  option: base => ({ ...base, minHeight: 30, cursor: 'pointer' })
};

export {
  cursorPointerStyle,
  vaccineModalSelectStyling
}

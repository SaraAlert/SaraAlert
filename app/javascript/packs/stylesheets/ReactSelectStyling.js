// The styling of the React-Select component cannot be done
// with raw CSS. Custom objects can be defined here and included
// in each component as necessary
const cursorPointerStyle = {
  option: base => ({ ...base, cursor: 'pointer' }),
};

const cursorPointerStyleLg = {
  option: base => ({ ...base, cursor: 'pointer' }),
  control: base => ({ ...base, fontSize: '1.25rem', fontWeight: 400, fontFamily: 'Arial', color: '#495057', paddingLeft: '0.25rem' }),
};

const vaccineModalSelectStyling = {
  menu: base => ({ ...base, zIndex: 9999 }),
  option: base => ({ ...base, minHeight: 30, cursor: 'pointer' })
};

const preferredContactTimeSelectStyling = {
  option: base => ({ ...base, cursor: 'pointer', ':nth-child(4)': { borderBottom: '1px solid #ced4da' } }),
  control: base => ({ ...base, fontSize: '1.25rem', fontWeight: 400, fontFamily: 'Arial', color: '#495057', paddingLeft: '0.25rem' }),
};

const customPreferredContactTimeSelectStyling = {
  option: base => ({ ...base, cursor: 'pointer', padding: '0.25rem 1.5rem' }),
};

const bootstrapSelectTheme = (theme, size) => {
  return {
    ...theme,
    borderRadius: 0,
    spacing: size === 'lg' ? {
      ...theme.spacing,
      controlHeight: '3rem',
    } : theme.spacing,
  };
};

export {
  cursorPointerStyle,
  cursorPointerStyleLg,
  vaccineModalSelectStyling,
  preferredContactTimeSelectStyling,
  customPreferredContactTimeSelectStyling,
  bootstrapSelectTheme,
};

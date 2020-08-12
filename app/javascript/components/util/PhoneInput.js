import React from 'react';
import PropTypes from 'prop-types';
import MaskedInput from 'react-text-mask';

class PhoneInput extends React.Component {
  render() {
    return (
      <MaskedInput
        id={this.props.id}
        value={this.props.value?.replace('+1', '')}
        mask={[/\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/]}
        className={`form-control form-control-lg${this.props.isInvalid ? ' is-invalid' : ''}`}
        placeholder="___-___-____"
        onChange={this.props.onChange}
      />
    );
  }
}

PhoneInput.propTypes = {
  id: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  isInvalid: PropTypes.bool,
};

export default PhoneInput;

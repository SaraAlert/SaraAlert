import React from 'react';
import { Breadcrumb } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class BreadcrumbPath extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Breadcrumb className="breadcrumb-square mx-2">
          {this.props.crumbs.map((crumb, index) => (
            <Breadcrumb.Item key={'crumb-' + index} href={crumb.href} active={crumb.href === null ? true : false}>
              <span className="lead">{crumb.value}</span>
            </Breadcrumb.Item>
          ))}
          <li className="ml-auto">
            {this.props.current_user &&
              this.props.current_user.jurisdiction_path &&
              `Your jurisdiction: ${this.props.current_user.jurisdiction_path.join(', ')}`}
          </li>
        </Breadcrumb>
      </React.Fragment>
    );
  }
}

BreadcrumbPath.propTypes = {
  current_user: PropTypes.object,
  crumbs: PropTypes.array,
};

export default BreadcrumbPath;

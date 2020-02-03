import React from "react";
import { Breadcrumb } from 'react-bootstrap';

class BreadcrumbPath extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <Breadcrumb className="breadcrumb-square mx-2">
          {this.props.crumbs.map((crumb, index) => (
            <Breadcrumb.Item key={"crumb-" + index} href={crumb.href} active={crumb.href === null ? true : false}><span className="lead">{crumb.value}</span></Breadcrumb.Item>
          ))}
        </Breadcrumb>
      </React.Fragment>
    );
  }
}

export default BreadcrumbPath

import React from 'react';
import { PropTypes } from 'prop-types';

class Breadcrumb extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <div className="mx-2 mt-4 mb-3">
          <nav aria-label="breadcrumb">
            <ol className="breadcrumb">
              {this.props.crumbs?.map((crumb, index) => {
                var text = crumb['value'];
                return (
                  <li key={'bc' + index} className={'breadcrumb-item lead ' + (crumb['href'] && 'active')}>
                    {crumb['href'] && <a href={`${window.BASE_PATH}${crumb['href']}`}>{text}</a>}
                    {!crumb['href'] && text}
                  </li>
                );
              })}
              <li className="lead ml-auto">Your Jurisdiction: {this.props.jurisdiction}</li>
            </ol>
          </nav>
        </div>
      </React.Fragment>
    );
  }
}

Breadcrumb.propTypes = {
  crumbs: PropTypes.array,
  jurisdiction: PropTypes.string,
};

export default Breadcrumb;

import React from 'react';
import { PropTypes } from 'prop-types';

class Breadcrumb extends React.Component {
  constructor(props) {
    super(props);
    this.renderWorkflowName = this.renderWorkflowName.bind(this);
  }

  goBack(index) {
    // check for if the browser is safari and bump up the index due to a safari off by one history.go bug
    // remove once this bug is fixed in safari
    var isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    if (isSafari) index++;

    window.history.go(0 - index);
  }

  renderWorkflowName(name) {
    if (this.props.enroller && name?.includes('Dashboard')) {
      return 'Return To Dashboard';
    }
    if (this.props.isolation) {
      return name.replace('Exposure', 'Isolation');
    }
    if (window?.WORKFLOW === 'exposure') {
      return name;
    }
    if (window?.location?.pathname?.endsWith('/public_health')) {
      return name;
    }
    if (window?.WORKFLOW === 'isolation') {
      return name.replace('Exposure', 'Isolation');
    }
    if (window?.location?.href?.includes('isolation')) {
      return name.replace('Exposure', 'Isolation');
    }
    if (document?.referrer?.includes('exposure')) {
      return name;
    }
    if (document?.referrer?.includes('isolation')) {
      return name.replace('Exposure', 'Isolation');
    }
    return name;
  }

  render() {
    return (
      <React.Fragment>
        <div className="mx-2">
          <nav aria-label="breadcrumb">
            <ol className="breadcrumb">
              {this.props.crumbs?.map((crumb, index) => {
                return (
                  <li key={'bc' + index} className={'breadcrumb-item lead lead-bc ' + (crumb['href'] && 'active')}>
                    {crumb['href'] && (
                      <a
                        href="#"
                        onClick={() => {
                          if (this.renderWorkflowName(crumb['value']).includes('Isolation')) {
                            // Public Health "Return to Isolation Dashboard"
                            location.assign((window.BASE_PATH ? window.BASE_PATH : '') + '/public_health/isolation');
                          } else if (this.renderWorkflowName(crumb['value']).includes('Exposure')) {
                            // Public Health "Return to Exposure Dashboard"
                            location.assign((window.BASE_PATH ? window.BASE_PATH : '') + '/public_health');
                          } else if (this.renderWorkflowName(crumb['value']).includes('Dashboard')) {
                            // Enroller "Return to Dashboard"
                            location.assign((window.BASE_PATH ? window.BASE_PATH : '') + '/patients');
                          } else {
                            this.goBack(this.props.crumbs.length - (index + 1));
                          }
                        }}>
                        {this.renderWorkflowName(crumb['value'])}
                      </a>
                    )}
                    {!crumb['href'] && crumb['value']}
                  </li>
                );
              })}
              <li className="lead lead-bc ml-auto">Your Jurisdiction: {this.props.jurisdiction}</li>
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
  isolation: PropTypes.bool,
  enroller: PropTypes.bool,
};

export default Breadcrumb;

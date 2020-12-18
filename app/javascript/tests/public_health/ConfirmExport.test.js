import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import ConfirmExport from '../../components/public_health/ConfirmExport.js'

const onCancelMock = jest.fn();
const onStartExportMock = jest.fn();

function getWrapper(show) {
  return shallow(<ConfirmExport show={show} title={'here is a title'} onCancel={onCancelMock} onStartExport={onStartExportMock} />);
}

function getInstance() {
  return shallow(<ConfirmExport show={true} title={'here is a title'} onCancel={onCancelMock} onStartExport={onStartExportMock} />).instance();
}

describe('ConfirmExport', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('here is a title');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toEqual('After clicking Start Export, Sara Alert will gather all of the monitoree data that comprises your request and generate an export file. Sara Alert will then send your user account an email with a one-time download link. This process may take several minutes to complete, based on the amount of data present.');
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toEqual('NOTE: The system will store one of each type of export file. If you initiate another export of this file type, any old files will be overwritten and download links that have not been accessed will be invalid. Only one of each export type is allowed per user per hour.');
    expect(wrapper.find(Modal.Body).find('b').text()).toEqual('Start Export');
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Start Export');
  });

  it('Hides modal if props.show is false', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeFalsy();
  });

  it('Clicking the cancel button calls the onCancel method', () => {
    const wrapper = getWrapper(true);
    expect(onCancelMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(0).simulate('click');
    expect(onCancelMock).toHaveBeenCalled();
  });
  
  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(true);
    expect(onStartExportMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(onStartExportMock).toHaveBeenCalled();
  });

  it('Clicking the submit button hides/shows spinner and updates state', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Button).at(1).find('.spinner-border').exists()).toBeFalsy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Button).at(1).find('.spinner-border').exists()).toBeTruthy();
  });
});

import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import ConfirmExport from '../../components/public_health/ConfirmExport.js'

const workflow = 'exposure'
const onCancelMock = jest.fn();
const onStartExportMock = jest.fn();

function getWrapper(show, type, workflow) {
  return shallow(<ConfirmExport show={show} exportType={type} workflow={workflow} onCancel={onCancelMock} onStartExport={onStartExportMock} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('ConfirmExport', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(true, 'Line list CSV', workflow);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toEqual('After clicking Start Export, Sara Alert will gather all of the monitoree data that comprises your request and generate an export file. Sara Alert will then send your user account an email with a one-time download link. This process may take several minutes to complete, based on the amount of data present.');
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toEqual('NOTE: The system will store one of each type of export file. If you initiate another export of this file type, any old files will be overwritten and download links that have not been accessed will be invalid. Only one of each export type is allowed per user per hour.');
    expect(wrapper.find(Modal.Body).find('b').text()).toEqual('Start Export');
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Start Export');
  });

  it('Properly renders modal title (exportType = Line list CSV)', () => {
    const wrapper = getWrapper(true, 'Line list CSV', workflow);
    expect(wrapper.find(Modal.Title).text()).toEqual(`Line list CSV (${workflow})`);
  });

  it('Properly renders modal title for (exportType = Sara Alert Format)', () => {
    const wrapper = getWrapper(true, 'Sara Alert Format', workflow);
    expect(wrapper.find(Modal.Title).text()).toEqual(`Sara Alert Format (${workflow})`);
  });

  it('Properly renders modal title (exportType = Excel Export For Purge-Eligible Monitorees)', () => {
    const wrapper = getWrapper(true, 'Excel Export For Purge-Eligible Monitorees');
    expect(wrapper.find(Modal.Title).text()).toEqual('Excel Export For Purge-Eligible Monitorees');
  });

  it('Properly renders csv modal title (exportType = Excel Export For All Monitorees)', () => {
    const wrapper = getWrapper(true, 'Excel Export For All Monitorees');
    expect(wrapper.find(Modal.Title).text()).toEqual('Excel Export For All Monitorees');
  });

  it('Hides modal if props.show is false', () => {
    const wrapper = getWrapper(false, 'Line list CSV', workflow);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeFalsy();
  });

  it('Clicking the cancel button calls the onCancel method', () => {
    const wrapper = getWrapper(true, 'Line list CSV', workflow);
    expect(onCancelMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(0).simulate('click');
    expect(onCancelMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls the submit method with correct arguments (exportType = Line list CSV)', () => {
    const wrapper = getWrapper(true, 'Line list CSV', workflow);
    expect(onStartExportMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(onStartExportMock).lastCalledWith(`/export/csv_linelist/${workflow}`);
  });

  it('Clicking the submit button calls the submit method with correct arguments (exportType = Sara Alert Format)', () => {
    const wrapper = getWrapper(true, 'Sara Alert Format', workflow);
    expect(onStartExportMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(onStartExportMock).lastCalledWith(`/export/sara_alert_format/${workflow}`);
  });

  it('Clicking the submit button calls the submit method with correct arguments (exportType = Excel Export For Purge-Eligible Monitorees)', () => {
    const wrapper = getWrapper(true, 'Excel Export For Purge-Eligible Monitorees');
    expect(onStartExportMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(onStartExportMock).lastCalledWith('/export/full_history_patients/purgeable');
  });

  it('Clicking the submit button calls the submit method with correct arguments (exportType = Excel Export For All Monitorees)', () => {
    const wrapper = getWrapper(true, 'Excel Export For All Monitorees');
    expect(onStartExportMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(onStartExportMock).lastCalledWith('/export/full_history_patients/all');
  });

  it('Clicking the submit button hides/shows spinner and updates state', () => {
    const wrapper = getWrapper(true, 'Line list CSV', workflow);
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Button).at(1).find('.spinner-border').exists()).toBeFalsy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Button).at(1).find('.spinner-border').exists()).toBeTruthy();
  });
});

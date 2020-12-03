import React from 'react'
import { mount } from 'enzyme';
import { mockDownload1 } from '../mocks/mockDownload';
import Download from '../../components/downloads/Downloads.js';

describe('Download', () => {
  describe('Properly renders all main components', () => {
    it('When there is no download error', () => {
      const requiredStrings = [
        'Download Export'
      ]
      const wrapper = mount(<Download error={false} download={mockDownload1} export_url={'https://saraalert.org'} />);
      requiredStrings.forEach(requiredString => {
        expect(wrapper.text().includes(requiredString)).toBeTruthy();
      })
    })

    it('When there is a download error', () => {
      const requiredStrings = [
        'The download link is either invalid'
      ]
      const wrapper = mount(<Download error={true} download={null} export_url={null} />)
      requiredStrings.forEach(requiredString => {
        expect(wrapper.text().includes(requiredString)).toBeTruthy();
      })
    })
  })
});

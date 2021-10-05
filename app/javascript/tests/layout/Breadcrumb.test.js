import React from 'react';
import { shallow } from 'enzyme';
import Breadcrumb from '../../components/layout/Breadcrumb';
import { mockBreadcrumbs1 } from '../mocks/mockBreadcrumbs';
import { mockJurisdiction1 } from '../mocks/mockJurisdiction';

describe('Breadcrumb', () => {
  it('Properly renders breadcrumb text and links and jurisdiction', () => {
    const wrapper = shallow(<Breadcrumb crumbs={mockBreadcrumbs1} jurisdiction={mockJurisdiction1.path} />);
    mockBreadcrumbs1.forEach((crumb, index) => {
      if (crumb.href === null) {
        expect(wrapper.find('li').at(index).text()).toEqual(crumb.value);
        expect(wrapper.find('li').at(index).find('a').exists()).toBe(false);
      } else {
        expect(wrapper.find('li').at(index).find('a').text()).toEqual(crumb.value);
        expect(wrapper.find('li').at(index).find('a').prop('href')).toEqual(`${window.BASE_PATH}${crumb.href}`);
      }
    });

    expect(wrapper.find('li').last().text()).toEqual(`Your Jurisdiction: ${mockJurisdiction1.path}`);
  });
});

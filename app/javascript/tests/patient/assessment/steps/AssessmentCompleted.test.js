import React from 'react';
import { shallow } from 'enzyme';
import { Card, Form } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import AssessmentCompleted from '../../../../components/patient/assessment/steps/AssessmentCompleted';
import { mockTranslations } from '../../../mocks/mockTranslations';

const contact = {
  email: 'email@example.com',
  phone: '1111111111',
  webpage: 'somewebpage.com',
};

function getWrapper(language, contactInfo) {
  return shallow(<AssessmentCompleted lang={language} translations={mockTranslations} contact_info={contactInfo} />);
}

describe('AssessmentCompleted', () => {
  it('Properly renders all main components in English', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Spanish', () => {
    const language = 'spa';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Spanish (Puerto Rican)', () => {
    const language = 'spa-pr';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in French', () => {
    const language = 'fra';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Somali', () => {
    const language = 'som';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Korean', () => {
    const language = 'kor';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Vietnamese', () => {
    const language = 'vie';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders all main components in Russian', () => {
    const language = 'rus';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  // it('Properly renders all main components in Arabic', () => {
  //   const language = 'ara';
  //   const wrapper = getWrapper(language, contact);
  //   expect(wrapper.find(Card.Header).exists()).toBe(true);
  //   expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
  //   expect(wrapper.find(Card.Body).exists()).toBe(true);
  //   expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
  //   expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
  //   expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
  //   expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  // });

  it('Properly renders all main components in Chinese', () => {
    const language = 'zho';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['title']);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(0).text()).toEqual(mockTranslations[`${language}`]['html']['weblink']['thank_you']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction1']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction2']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['weblink']['instruction3']);
  });

  it('Properly renders email contact information', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, { email: 'email@example.com' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['shared']['email']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-envelope')).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' email@example.com');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('mailto:email@example.com');
  });

  it('Properly renders phone contact information', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, { phone: '1111111111' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['shared']['phone']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-phone')).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' 1111111111');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('tel:1111111111');
  });

  it('Properly renders webpage contact information', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, { webpage: 'somewebpage.com' });
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).toContain(mockTranslations[`${language}`]['html']['shared']['webpage']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').hasClass('fa-desktop')).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').text()).toEqual(' somewebpage.com');
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').prop('href')).toEqual('somewebpage.com');
  });

  it('Hides contact information when none is provided', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, {});
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).not.toContain(mockTranslations[`${language}`]['html']['shared']['email']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).not.toContain(mockTranslations[`${language}`]['html']['shared']['phone']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).text()).not.toContain(mockTranslations[`${language}`]['html']['shared']['webpage']);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('i').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(Form.Label).at(1).find('a').exists()).toBe(false);
  });

  it('Properly renders success checkmark', () => {
    const language = 'eng';
    const wrapper = getWrapper(language, contact);
    expect(wrapper.find(Card.Body).find(FontAwesomeIcon).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(FontAwesomeIcon).prop('icon').iconName).toEqual('check-circle');
    expect(wrapper.find(Card.Body).find(FontAwesomeIcon).prop('color')).toEqual('#28a745');
    expect(wrapper.find(Card.Body).find(FontAwesomeIcon).prop('size')).toEqual('6x');
  });
});

/**
 * @param {String} workflow - the value of the navigation quary param
 * @param {Boolean} firstParam - whether the nav param is the first query param in the URL
 */
function navQueryParam(workflow, firstParam) {
  return workflow ? `${firstParam ? '?' : '&'}nav=${workflow}` : '';
}

/**
 * @param {String} id - the ID of the patient to link to
 * @param {String} workflow  - the workflow for the nav query param
 */
function patientHref(id, workflow) {
  return `${window.BASE_PATH}/patients/${id}${navQueryParam(workflow, true)}`;
}

export { navQueryParam, patientHref };

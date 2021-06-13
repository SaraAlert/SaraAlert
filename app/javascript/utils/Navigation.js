/**
 * @param {String} workflow - the value of the navigation quary param
 * @param {Boolean} firstParam - whether the nav param is the first query param in the URL
 */
function navQueryParam(workflow, firstParam) {
  return workflow ? `${firstParam ? '?' : '&'}nav=${workflow}` : "";
}

export { navQueryParam };

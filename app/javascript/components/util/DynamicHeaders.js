// To promote reusable and accessibile containers, this function will return

function generateDynamicHeaders(priority) {
  if (isNaN(priority) || priority === null || priority === undefined || priority < 1 || priority > 6) {
    return null;
  }
  let headerMappings = [
    { label: 'one', value: 1 },
    { label: 'two', value: 2 },
    { label: 'three', value: 3 },
    { label: 'four', value: 4 },
    { label: 'five', value: 5 },
    { label: 'six', value: 6 },
  ];

  let headerArray = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
  let availableHeaders = headerArray.slice(priority - 1);
  let headersObject = {};
  headerMappings.forEach((hm, index) => (headersObject[`${hm.label}`] = availableHeaders[Number(index)] || null));
  return headersObject;
}

export default generateDynamicHeaders;

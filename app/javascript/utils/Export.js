/**
 * Called when Exporting to a CSV for a notes field
 * Removes all the values that would cause an issue when opening in excel
 */
function removeFormulaStart(value) {
  if (value === null || value === undefined) {
    return '';
  }
  while (value.charAt(0) === '=' || value.charAt(0) === '+' || value.charAt(0) === '-' || value.charAt(0) === '"') {
    value = value.substring(1);
  }
  while (value.charAt(value.length - 1) === '"') {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

export { removeFormulaStart };

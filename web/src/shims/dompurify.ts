const DOMPurify = {
  sanitize: (val: any) => val,
  isValidAttribute: () => true,
  addHook: () => {},
};

export default DOMPurify;
export const sanitize = DOMPurify.sanitize;
export const isValidAttribute = DOMPurify.isValidAttribute;
export const addHook = DOMPurify.addHook;

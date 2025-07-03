// import * as ed from "https://cdn.jsdelivr.net/npm/@noble/ed25519@2.0.0/+esm";

// window.signWithPrivateKey = async function (base64Key, orderJson) {
//   const keyBytes = Uint8Array.from(atob(base64Key), (c) => c.charCodeAt(0));
//   const orderBytes = new TextEncoder().encode(orderJson);
//   const signature = await ed.sign(orderBytes, keyBytes);
//   const signatureBase64 = btoa(String.fromCharCode(...signature));
//   return signatureBase64;
// };

window.signWithPrivateKey = async function (base64Key, orderJson) {
  // Simulate key and message processing
  const key = atob(base64Key);
  const message = orderJson;

  // Dummy 'signature': base64 of key + message combined
  const fakeSignature = btoa(key + "::" + message);

  return fakeSignature;
};
window.verifySignature = async function (base64Key, orderJson, signature) {
  // Simulate verification logic
  const key = atob(base64Key);
  const message = orderJson;
  const expectedSignature = btoa(key + "::" + message);

  return expectedSignature === signature;
};

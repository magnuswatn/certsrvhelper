"use strict";

function text(el, string) {
    if ('textContent' in el) {
        el.textContent = string;
    } else {
        el.innerText = string;
    }
}
function decode(der, dest) {
    dest.innerHTML = '';
    try {
        const asn1 = ASN1.decode(der);
        dest.appendChild(asn1.toDOM());
    } catch (e) {
	const errorText = 'ASN1 parsing failed: ' + e;
        text(dest, errorText);
    }
}
function decodeCSR() {
    const area = document.getElementById('locTaRequest');
    const tree = document.getElementById('tree');
    try {
        const der = Base64.unarmor(area.value);
        decode(der, tree);
    } catch (e) {
        text(tree, e);
    }
}

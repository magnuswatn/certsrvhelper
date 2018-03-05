certsrvhelper
======

This is a little extension to the Microsoft Active Directory Certificate Services web page (certsrv), that adds an option to print the ASN1 content of the certificate request you're about to submit.

![bilde](https://raw.githubusercontent.com/magnuswatn/certsrvhelper/master/picture.png)

This saves you a trip to the command line, just to check that the CSR is correct.

It also lets you show the newly issued certificate in the browser, without downloading it first.

![bilde2](https://raw.githubusercontent.com/magnuswatn/certsrvhelper/master/picture2.png)

Saves you a download!

## installation

Clone the repo to the server running certsrv, and run the install.ps1 script as Administrator. Probably take a full backup beforehand.

## uninstallation

Just uninstall the "Certificate Authority Web Enrollment" Role Service, and delete the certsrvhelper folder from C:\Windows\System32\certsrv\en-US. And then install the Role Service again. That should fix everything.

## disclaimer

It's quite hackish and it modifies files that only Microsoft should touch. I wouldn't use it if I were you.

## asn1js

It's the great [asn1js](https://lapo.it/asn1js/) library that is used for the parsing. It has the following licence:

ASN.1 JavaScript decoder Copyright (c) 2008-2014 Lapo Luchini <lapo@lapo.it>

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

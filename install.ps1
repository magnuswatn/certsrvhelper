<#
Installer script for the certsvhelper

This will backup the certsrv folder to %USERPROFILE%\Documents\certsrvhelper-backup, copy the needed assets to certsrv and modify the certrqxt.asp and certrsis.asp files as needed

It is extremely fragile and hackish.

Magnus Watn <magnus@watn.no>
#>

function compareFileToHash($file, $knownHashes) {
    $actualHash = (Get-Filehash $file -Algorithm SHA256).hash

    $knownHashes | Foreach-Object {
        if ($actualHash -eq $_) {
            return $true
        }
    }
    return $false
   }

function modFile($file, $modifications) {
    (Get-Content $file) | Foreach-Object {
        $line = $_
        $line
        $modifications.GetEnumerator() | Foreach-Object {
            if ($line -match $_.Name)
            {
                "<!-- Start modified by certsrvhelper (https://github.com/magnuswatn/certsrvhelper) -->"
                $_.Value
                "<!-- End modified by certsrvhelper (https://github.com/magnuswatn/certsrvhelper) -->"
            }
        }
    } | Set-Content $file
}

function insertIntoFileBeforeAppearance($file, $indicator, $content, $number) {
    $count = 1
    (Get-Content $file) | Foreach-Object {
        $line = $_
        if ($line -match $indicator) {
            if ($count -eq $number) {
                "<!-- Start modified by certsrvhelper (https://github.com/magnuswatn/certsrvhelper) -->"
                $content
                "<!-- End modified by certsrvhelper (https://github.com/magnuswatn/certsrvhelper) -->"
            } else {
                $count += 1
            }
        }
        $line
    } | Set-Content $file
}

function fixPermissionOnFile($file) {
    takeown /F $file
    if (!($?)) {
        "Failed to take owernship of $($file). Running as admin?"
        exit 1
    }

    icacls $file /grant "$($env:USERNAME):F"
    if (!($?)) {
        "Failed give self permissions to $($file). Running as admin?"
        exit 1
    }
}

$cerstvLocation = "$($env:SystemRoot)\System32\certsrv\en-US"
$backupLocation = "$($env:USERPROFILE)\Documents\certsrvhelper-backup"


if (!(Test-Path $cerstvLocation)) {
    "Could not locate the certsrv folder. Exiting."
    exit 1
}

$certrqxt = "$($cerstvLocation)\certrqxt.asp"
$certrsis = "$($cerstvLocation)\certrsis.asp"

# The two known versions of these files are from Windows 2008R2 and 2012R2. The differences between them are small and insignificant
$knownCertrqxtHashes = @(
    "02AF5E488AB2DFF34D78C06B35177541C3A3220E9B967CDC053AC8A6E88965DA"
    "2FCB2E7795E2253A267C8E6AF0E0E8ACB7B39302D54192B804869083BD0F03A9"
)

$knownCertrsisHashes = @(
    "A877334944C9BD41428E7387A5031B6E77B34BCCD1CE48691284F1C8C37781A2"
    "1EDF7E29D14D4E5628160765FD7D643D76D1196EAD52D7CB53C6246BE47AB537"
)

if (!(compareFileToHash $certrqxt $knownCertrqxtHashes) -or !(compareFileToHash $certrsis $knownCertrsisHashes)) {
    "Your version of certsrv is different than expected. Not safe to continue. Exiting."
    exit 1
}

# Backup the certsrv folder, as we are going to tamper with it
Copy-Item $cerstvLocation $backupLocation -Recurse

# Copy the needed assets
Copy-Item ./certsrvhelper $cerstvLocation -Recurse

# The files are normally owned by Trusted Installer, we need to take owernship to be able to edit them
fixPermissionOnFile $certrqxt
fixPermissionOnFile $certrsis

# These are the modifications we are going to do; insert the value after the line that mathes the name
$certrqxtModifications = @{
    "</Title>" = "`t<link rel=`"stylesheet`" href=`"certsrvhelper/certsrvhelper.css`" type=`"text/css`">"
    "<Input Type=Submit ID=btnSubmit Value=`"Submit &gt;`" <%If `"IE`"=sBrowser Then%> Style=`"width:.75in`"<%End If%>>" = "<Input Type=Button ID=btnParse Value=`"Show ASN1 &gt;`" onclick=`"decodeCSR();`" <%If `"IE`"=sBrowser Then%> Style=`"width:.75in`"<%End If%>>"
    "<TR><TD ColSpan=3 Height=20></TD></TR>" = "</table></td><td><div style=`"position: relative; padding-bottom: 1em;`"><div id=`"tree`"></div></div></td>"
    "</P>" = "<table><td style=`"vertical-align:top`">"
    "<!-- End of standard text. Scripts follow  -->" = "<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/base64.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/oids.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/int10.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/asn1.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/dom.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/certsrvhelper.js`"></script>"
}

modFile $certrqxt $certrqxtModifications

# My Mind Is A Bad Neighborhood

$certrsisModifications = @{
    "<%ElseIf `"UnknownClient`"<>sBrowser Then%>" = "<Script Language=`"JavaScript`">`r`n`tfunction handleShowCert() {`r`n`t`tvar req = new XMLHttpRequest();`r`n`t`treq.addEventListener(`"load`", function(){`r`n`t`t`tdocument.getElementById('locPEM').innerText=this.responseText;`r`n`t`t});`r`n`t`treq.open(`"GET`", `"/certsrv/certnew.cer?ReqID=<%=ICertRequest.GetRequestId()%>&Enc=b64`");`r`n`t`treq.send();`r`n`t}`r`n</Script>"
    "<P ID=locInfo> The certificate you requested was issued to you.</P>" = "<table><td style=`"vertical-align:top`">"
    "<LocID ID=locDownloadCertChain3>Download certificate chain</LocID></A>" = "`t`t<BR>`r`n`t`t`t<A Href=`"#`" OnClick=`"handleShowCert();return false;`">`r`n`t`t`t<LocID ID=locDownloadCertChain3>Show the PEM encoded certificate</LocID></A>"
}

modFile $certrsis $certrsisModifications

# Couldn't find a unique indicator for where to insert this... Inserting it before the second (last) green line
insertIntoFileBeforeAppearance $certrsis "<!-- Green HR -->" "</td><td><div style=`"position: relative; padding-bottom: 1em; font: 10pt Courier New, sans-serif; padding: 2px 20px;`" id=`"locPEM`"></div></td></table>" 2

"Done."

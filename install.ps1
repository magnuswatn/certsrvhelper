<#
Installer script for the certsvhelper

This will backup the certsrv folder to %USERPROFILE%\Documents\certsrvhelper-backup, copy the needed assets to certsrv and modify the certrqxt.asp file as needed

It is extremely fragile and hackish.

Magnus Watn <magnus@watn.no>
#>

$cerstvLocation = "$($env:SystemRoot)\System32\certsrv\en-US"
$backupLocation = "$($env:USERPROFILE)\Documents\certsrvhelper-backup"


if (!(Test-Path $cerstvLocation)) {
    "Could not locate the certsrv folder. Exiting."
    exit 1
}

$certrqxt = "$($cerstvLocation)\certrqxt.asp"

# The two known versions of this file is from Windows 2008R2 and 2012. The differences between them are small and insignificant
$knownCertrqxtHashes = @(
    "02AF5E488AB2DFF34D78C06B35177541C3A3220E9B967CDC053AC8A6E88965DA"
    "2FCB2E7795E2253A267C8E6AF0E0E8ACB7B39302D54192B804869083BD0F03A9"
)
$actualCertrqxtHash = (Get-Filehash $certrqxt -Algorithm SHA256).hash

$hashMatch = $false
$knownCertrqxtHashes | Foreach-Object {
    if ($actualCertrqxtHash -eq $_) {
        $hashMatch = $true
    }
}

if (!($hashMatch)) {
    "Your version of the certrqxt.asp file is different than expected. Not safe to continue. Exiting."
    exit 1
}

# Backup the certsrv folder, as we are going to tamper with it
Copy-Item $cerstvLocation $backupLocation -Recurse

# Copy the needed assets
Copy-Item ./certsrvhelper $cerstvLocation -Recurse

# The file is normally owned by Trusted Installer, we need to take owernship to be able to edit it
takeown /F $certrqxt
if (!($?)) {
    "Failed to take owernship of the certrqxt.asp file. Running as admin?"
    exit 1
}

icacls $certrqxt /grant "$($env:USERNAME):F"
if (!($?)) {
    "Failed give self permissions to the certrqxt.asp file. Running as admin?"
    exit 1
}

# These are the modifications we are going to do; insert the value after the line that mathes the name
$modifications = @{
    "</Title>" = "`t<link rel=`"stylesheet`" href=`"certsrvhelper/certsrvhelper.css`" type=`"text/css`">"
    "<Input Type=Submit ID=btnSubmit Value=`"Submit &gt;`" <%If `"IE`"=sBrowser Then%> Style=`"width:.75in`"<%End If%>>" = "<Input Type=Button ID=btnParse Value=`"Show ASN1 &gt;`" onclick=`"decodeCSR();`" <%If `"IE`"=sBrowser Then%> Style=`"width:.75in`"<%End If%>>"
    "<TR><TD ColSpan=3 Height=20></TD></TR>" = "</table></td><td><div style=`"position: relative; padding-bottom: 1em;`"><div id=`"tree`"></div></div></td>"
    "</P>" = "<table><td>"
    "<!-- End of standard text. Scripts follow  -->" = "<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/base64.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/oids.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/int10.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/asn1.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/asn1js/dom.js`"></script>`r`n<script type=`"text/javascript`" src=`"certsrvhelper/certsrvhelper.js`"></script>"
}

(Get-Content $certrqxt) |
Foreach-Object {
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
} | Set-Content $certrqxt

"Done."

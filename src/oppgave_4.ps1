param ($UrlKortstokk)

# Dra inn kortstokken via en weblient.
$web_client = new-object system.net.webclient
try {
    $kortstokk = $web_client.DownloadString($UrlKortstokk) | ConvertFrom-Json
    $fikkKortstokk = $true
}
# Hvis hostnamet ikke eksisterer e.l, sett fikkkortstokk til false og print melding.
catch [System.Management.Automation.MethodInvocationException] {
    "Nodename nor servname provided, or not known"
    $fikkKortstokk = $false
}
# Funksjon for å loope gjennom json-data. Tar en kortstokk som parameter, og returnerer en streng.
function kortstokkTilStreng {
    [OutputType([string])]
    param (
        [object[]]
        $kortstokk
    )
    $streng = ""
    foreach ($kort in $kortstokk) {
        # Value-feltet i json-dataene skal ikke ha [0], da dette vil gi "1" i stedet for "10" på tierne.
        $streng = $streng + "$($kort.suit[0])" + $($kort.value) + ","
    }

    # Ved siste kjøring, lagre hele strengen fra foreach, minus siste karakter som var kommaet.
    try {
        $streng = $streng.Substring(0,$streng.Length-1)
    }
    catch [System.Management.Automation.MethodInvocationException] {
        "String is empty."
    }

    return $streng
}

# Hvis det gikk bra å hente inn kortstokken, kjør funksjonen.
if ($fikkKortstokk) {
    Write-Output "Kortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"
}
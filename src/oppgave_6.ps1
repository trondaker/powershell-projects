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
#Ny funksjon som bare summerer verdiene til korta, slik at outputen blir helt riktig. Unngår Poengsum for hver kjøring.
function summerVerdier {
    [OutputType([int])]
    param (
        [object[]]
        $kortstokk
    )
    # Hashtable med kortverdiene. Burde ikke verdiene stige helt til A = 14?
    $kortverdier = @{
        "1" = 1
        "2" = 2
        "3" = 3
        "4" = 4
        "5" = 5
        "6" = 6
        "7" = 7
        "8" = 8
        "9" = 9
        "10" = 10
        "J" = 10
        "Q" = 10
        "K" = 10
        "A" = 11
    }

    foreach ($kort in $kortstokk) {
        # Slå opp i hastable for å få verdien til kortet, typecast til Int og legg sammen med foregående verdier.
        $i = $i + [int]$kortverdier[$kort.value]
    }

    # Returnerer både strengen med kortnavn og verdiene summert.
    return $i
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
        $streng = $streng + "$($kort.suit[0])" + $($kort.value) + ","
    }

    # Ved siste kjøring, lagre hele strengen fra foreach, minus siste karakter som var kommaet.
    try {
        $streng = $streng.Substring(0,$streng.Length-1)
    }
    catch [System.Management.Automation.MethodInvocationException] {
        "String is empty."
    }
    # Returnerer både strengen med kortnavn og verdiene summert.
    return $streng, $i
}

# Hvis det gikk bra å hente inn kortstokken, kjørt funksjonen.
if ($fikkKortstokk) {
    Write-Output "Kortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"
    Write-Output "Poengsum:$(summerVerdier -kortstokk $kortstokk)"
}

# Tildeler meg selv 2 kort først.
$meg = $kortstokk[0..1]
# Fjerner de to første verdiene. -1 kan være 
$kortstokk = $kortstokk[2..$kortstokk.Count]
# Magnus får to kort.
$magnus = $kortstokk[0..1]
# Fjerner Magnus sine kort.
$kortstokk = $kortstokk[2..$kortstokk.Count]
# Skriver ut hvilke kort vi har og poengsum.
Write-Output "meg: $(kortstokkTilStreng -kortstokk $meg)"
Write-Output "magnus: $(kortstokkTilStreng -kortstokk $magnus)"
# Printer ut kortstokken til slutt for å verifisere at korta er borte.
Write-Output "Kortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"

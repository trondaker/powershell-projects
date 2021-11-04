
# Dra inn kortstokken via en weblient.
web_client = new-object system.net.webclient
$kortstokk = $web_client.DownloadString("http://nav-deckofcards.herokuapp.com/shuffle") | ConvertFrom-Json

# Funksjon for å loope gjennom json-data. Tar en kortstokk som parameter, og returnerer en streng.
function kortstokkTilStreng {
    [OutputType([string])]
    param (
        [object[]]
        $kortstokk
    )
    $streng = ""
    foreach ($kort in $kortstokk) {
        $streng = $streng + "$($kort.suit[0])" + $($kort.value[0]) + ","
        # Printer ut en teller pluss suit/number bare for å holde track på om dette blir riktig.
        $i++
        $a = "Kort nummer: "
        "$a$i $($kort.suit[0])$($kort.value[0]) `r`n"
    }

    # Ved siste kjøring, lagre hele strengen fra foreach, minus siste karakter som var kommaet.
    $streng = $streng.Substring(0,$streng.Length-1)

    return $streng
}

# Kaller funksjonen og sender inn kortstokken.
Write-Output "Kortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"
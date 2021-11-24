# Min URL: https://trond-blackjack.azurewebsites.net/api/Blackjack-aker?code=mdBZQS0RbJB3CNXHkOFaKLVCj5D2uCWskCRFMoaGdjgG2rOfksHeeQ==

<# Fra kjøring av function:
2021-11-08T09:26:34.036 [Information] OUTPUT: Kortstokk: H8,HQ,HJ,H10,D10,C7,SK,C6,HK,HA,D7,D2,H7,H3,C3,S10,C4,S3,CJ,S8,D8,H2,S7,CK,C9,SJ,H6,D6,D5,DA,H9,S6,D4,SA,C5,DQ,S2,SQ,C2,C8,S4,D9,DJ,H5,D3,H4,CQ,CA,C10,S9,DK,S5
2021-11-08T09:26:34.052 [Information] OUTPUT: Poengsum:380
2021-11-08T09:26:34.680 [Information] OUTPUT: meg: H8,HQ
2021-11-08T09:26:34.681 [Information] OUTPUT: magnus: HJ,H10
2021-11-08T09:26:34.682 [Information] OUTPUT: Kortstokk: D10,C7,SK,C6,HK,HA,D7,D2,H7,H3,C3,S10,C4,S3,CJ,S8,D8,H2,S7,CK,C9,SJ,H6,D6,D5,DA,H9,S6,D4,SA,C5,DQ,S2,SQ,C2,C8,S4,D9,DJ,H5,D3,H4,CQ,CA,C10,S9,DK,S5
2021-11-08T09:26:34.686 [Information] OUTPUT: 18
2021-11-08T09:26:34.690 [Information] OUTPUT: Ingen fikk blackjack, men Magnus kom nærmere 21 enn meg, han vant!
2021-11-08T09:26:34.719 [Information] Executed 'Functions.Blackjack-aker' (Succeeded, Id=8078f41f-378d-4b61-bab9-9f4da8ff16e7, Duration=21335ms)
#>

# I stedet for å bruke Write-Ouput concater jeg $streng, og sender denne til slutt
# som respons i http-responsen.

## The $TriggerMetadata parameter contains information about the triggered function. The sys property includes data like the date and time it is triggered, the HTTP method used to trigger it, and a unique GUID for the function's execution.
param($Request, $TriggerMetadata)

# Convert the incoming HTTP request body from JSON to a PowerShell object. The incoming HTTP request carries information about the request in the body. This information is accessible inside the function using the $Request parameter.
$requestBodyObject = $Request.Body | ConvertFrom-Json

#param ($UrlKortstokk)

# Dra inn kortstokken via en weblient.
$web_client = new-object system.net.webclient
try {
    $kortstokk = $web_client.DownloadString("http://nav-deckofcards.herokuapp.com/shuffle") | ConvertFrom-Json
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
    $streng = $streng + "Kortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"
    $streng = $streng + "`nPoengsum:$(summerVerdier -kortstokk $kortstokk)"
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
$streng = $streng +  "`nmeg: $(kortstokkTilStreng -kortstokk $meg)"
$streng = $streng +  "`nmagnus: $(kortstokkTilStreng -kortstokk $magnus)"
# Printer ut kortstokken til slutt for å verifisere at korta er borte.
$streng = $streng +  "`nKortstokk: $(kortstokkTilStreng -kortstokk $kortstokk)"
# Gjenbruker summerVerdier-funksjonen for å regne ut verdiene på våre hender.
$min_hand = $(summerVerdier -kortstokk $meg)
$min_hand
$magnus_hand = $(summerVerdier -kortstokk $magnus)
# Hvis verdiene returnert for meg eller Magnus er 21, skriv ut at Blackjack.

# While-løkke som trekker nye kort helt til min verdi er større enn 17.
While ($min_hand -lt 17) {
    $streng = $streng +  "`nJeg trekker kort, fortsatt under 17."
    # Trekker nytt kort og fjerner kortet fra $kortstokk.
    $meg = $meg + $kortstokk[0]
    $kortstokk = $kortstokk[1..$kortstokk.Count]
    # Summerer verdiene og kjører ny vurdering.
    $min_hand = $(summerVerdier -kortstokk $meg)
} 

While ($magnus_hand -lt 17) {
    $streng = $streng +  "`nMagnus trekker kort, fortsatt under 17."
    # Trekker nytt kort og fjerner kortet fra $kortstokk.
    $magnus = $magnus + $kortstokk[0]
    $kortstokk = $kortstokk[1..$kortstokk.Count]
    # Summerer verdiene og kjører ny vurdering.
    $magnus_hand = $(summerVerdier -kortstokk $magnus)
} 

# $min_hand er nå over 17, sjekker hvor vi er og avslutter.
if (($min_hand -gt 21) -and ($magnus_hand -gt 21)) {
    $streng = $streng +  "`nBegge over 21, begge busted."
} 
if (($min_hand -eq 21) -and ($magnus_hand -eq 21)) {
    $streng = $streng +  "`n`nBegge har blackjack!"
} 
if ($min_hand -eq 21) {
    $streng = $streng +  "`nJeg har blackjack, vinner denne runden!"
}
if ($magnus_hand -eq 21) {
    $streng = $streng +  "`nMagnus har blackjack, vinner denne runden!"
}
if ( ($magnus_hand -lt 21) -and ($magnus_hand -gt $min_hand) ) {
    $streng = $streng +  "`nIngen fikk blackjack, men Magnus kom nærmere 21 enn meg, han vant!"
}
if ( ($min_hand -lt 21) -and ($min_hand -gt $magnus_hand) ) {
    $streng = $streng +  "`nIngen fikk blackjack, men jeg kom nærmere 21 enn Magnus, jeg vant!"
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $streng
})



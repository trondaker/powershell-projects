# Min URL: https://blackjack-function-ta.azurewebsites.net/api/blackjack-function?code=QbYIXPXX4GQUapZYz/1wv3zjMVMl6tMYDNKIBxxMrQ5fUou3qeyQ6w==

<# Fra kjøring av function:
Kortstokk: D6,H6,D9,D8,S8,CK,SK,H5,C7,HK,S4,S5,C9,C10,D10,CQ,SQ,HA,S3,C5,H8,D3,DJ,D4,HQ,DQ,SA,H10,HJ,H2,C6,S2,D7,C4,C8,H9,H3,D2,H7,H4,D5,CJ,DA,C3,S7,S10,S6,DK,S9,C2,SJ,CA 
Poengsum:380
meg: D6,H6 
magnus: D9,D8 
Kortstokk: S8,CK,SK,H5,C7,HK,S4,S5,C9,C10,D10,CQ,SQ,HA,S3,C5,H8,D3,DJ,D4,HQ,DQ,SA,H10,HJ,H2,C6,S2,D7,C4,C8,H9,H3,D2,H7,H4,D5,CJ,DA,C3,S7,S10,S6,DK,S9,C2,SJ,CA 
Jeg trekker kort, fortsatt under 17.
Ingen fikk blackjack, men jeg kom nærmere 21 enn Magnus, jeg vant!
2021-11-29T12:12:50.901 [Information] Executed 'Functions.blackjack-function' (Succeeded, Id=f9cd44f5-e72a-4120-b69c-a1e4e6cafb28, Duration=600ms)
#>

## The $TriggerMetadata parameter contains information about the triggered function. The sys property includes data like the date and time it is triggered, the HTTP method used to trigger it, and a unique GUID for the function's execution.
param($Request, $TriggerMetadata)

# Convert the incoming HTTP request body from JSON to a PowerShell object. The incoming HTTP request carries information about the request in the body. This information is accessible inside the function using the $Request parameter.
#$requestBodyObject = $Request.Body | ConvertFrom-Json

# Dra inn kortstokken via en weblient. Try/catch funka ikke når oppgave_11.ps1 kjøres via Azure Functions (?)
$web_client = New-Object Net.WebClient
$kortstokk = $web_client.DownloadString("http://nav-deckofcards.herokuapp.com/shuffle") | ConvertFrom-Json
$fikkKortstokk = $true

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
}


Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body = $streng
})



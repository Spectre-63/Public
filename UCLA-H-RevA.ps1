# UCLA-H.ps1

function Get-PrimeFactors {
    param([int]$number)
    $factors = @()
    $divisor = 2
    while ($number -gt 1) {
        if ($number % $divisor -eq 0) {
            $factors += $divisor
            $number /= $divisor
        } else {
            $divisor++
        }
    }
    return $factors
}

$API = 'https://datausa.io/api/data?drilldowns=State&measures=Population'
$DataSource = Invoke-RestMethod -URI $API -Method GET | select-object -expand data | Select-Object State, Year, Population | Sort-Object State, Year

$filteredData = $DataSource | Where-Object { $_.Year -lt 2021 }
$groupedData = $filteredData | Group-Object State

$outputData = @()

foreach ($group in $groupedData) {
    $stateData = New-Object PSObject -Property @{
        'State Name' = $group.Name
    }

    for ($i = 0; $i -lt $group.Group.Count; $i++) {
        $currentYear = $group.Group[$i].Year
        $nextYear = $group.Group[$i + 1].Year
        $populationPercentIncrease = (($group.Group[$i].Population - $group.Group[$i-1].Population) / $group.Group[$i].Population) * 100
        $valueWithPercent = "{0} ({1:N2}%)" -f $group.Group[$i].Population, $populationPercentIncrease
        $stateData | Add-Member -MemberType NoteProperty -Name $currentYear -Value $valueWithPercent
    }

    $lastYear = $group.Group[-1].Year
    $lastYearPopulation = $group.Group[-1].Population
    $primeFactors = Get-PrimeFactors -number $lastYearPopulation

    $factorsWithResult = $primeFactors | ForEach-Object { "{0};{1:N2}" -f $_, ($lastYearPopulation / $_) }
    $stateData | Add-Member -MemberType NoteProperty -Name "$lastYear Factors" -Value ($factorsWithResult -join ',')

    $outputData += $stateData
}

$outputData | Export-Csv UCLA-H_Report.csv


function Mega_First_5_Random_Num ()
{
    #$n = get-random -Minimum 1 -Maximum 70
    #return $n

    $picks = @()

    for ($p = 1;$p -le 5; $p++)
    {
        $n = get-random -Minimum 1 -Maximum 70 
        while ($picks.contains($n))
        {
            $n = get-random -Minimum 1 -Maximum 70
        }
        $picks += $n

        
    }
    return $picks
}


function PowerBall_First_5_Random_Num ()

    {
        #$n = get-random -Minimum 1 -Maximum 69
        #return $n

        $picks = @()

    for ($p = 1;$p -le 5; $p++)
    {
        $n = get-random -Minimum 1 -Maximum 69
        while ($picks.contains($n))
        {
            $n = get-random -Minimum 1 -Maximum 69
        }
        $picks += $n
    }
    return $picks
}

function Mega_Ball_Random_Num ()
    {
        $n = get-random -Minimum 1 -Maximum 25
        return $n
    
    }

function PowerBall_Random_Number ()
    {
        $n = get-random -Minimum 1 -Maximum 26
        return $n
    }

function Illinois_Lotto_Random_Numbers ()
    {
        #$n = get-random -Minimum 1 -Maximum 52
    #return $n

    $picks = @()

    for ($p = 1;$p -le 5; $p++)
    {
        $n = get-random -Minimum 1 -Maximum 52
        while ($picks.contains($n))
        {
            $n = get-random -Minimum 1 -Maximum 52

        }
        $picks += $n



    }
}




# Show Menu

# Clear Screen
Clear-Host

write-host "Pick which Game you want to play:"
write-host "1. Mega Millions"
write-host "2. PowerBall"
write-host "3. Illinois Lotto"

$game = read-host ">"

if ($game -match "1")
    {
        
        # Mega Millions Numbers
        $NUM_of_Tickets =Read-host "How many tickets do you want"

        "";""

        write-host "Mega Million Numbers"
        write-host "---------------------"
        


        for ($i = 1;$i -le $NUM_of_Tickets; $i++)
            {
               #write-host $(Mega_First_5_Random_Num) $(Mega_First_5_Random_Num) $(Mega_First_5_Random_Num) $(Mega_First_5_Random_Num) $(Mega_First_5_Random_Num) $(Mega_Ball_Random_Num)
               write-host $(Mega_First_5_Random_Num) -NoNewline; write-host " $(Mega_Ball_Random_Num)" -ForegroundColor Red
            }

    }

if ($game -match "2")
    {
        # PowerBall Numbers
        $NUM_of_Tickets =Read-host "How many tickets do you want"
        "";""
        write-host "PowerBall Numbers"
        write-host "-----------------"

        for ($i = 1;$i -le $NUM_of_Tickets; $i++)
            {
                
                #write-host $(PowerBall_First_5_Random_Num) $(PowerBall_First_5_Random_Num) $(PowerBall_First_5_Random_Num) $(PowerBall_First_5_Random_Num) $(PowerBall_First_5_Random_Num) $(PowerBall_Random_Number)
                write-host $(PowerBall_First_5_Random_Num) -NoNewline ; write-host " $(PowerBall_Random_Number)" -ForegroundColor Red
            }
    }
 
if ($game -match "3")
    {
        # Illinois Lotto
        $NUM_of_Tickets = Read-host "How many tickets do you want"
        "";""
        write-host "Illinois Lotto"
        write-host "--------------"

        for ($i = 1;$i -le $NUM_of_Tickets; $i++)
        {
            write-host $(Illinois_Lotto_Random_Numbers) $(Illinois_Lotto_Random_Numbers) $(Illinois_Lotto_Random_Numbers) $(Illinois_Lotto_Random_Numbers) $(Illinois_Lotto_Random_Numbers) $(Illinois_Lotto_Random_Numbers)
        }
    }














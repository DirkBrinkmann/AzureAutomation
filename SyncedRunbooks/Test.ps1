$strMessage = "{0} Hallo Welt" -f (get-date)
$strMessage | out-file c:\temp\azure.txt
#start-sleep -seconds 10

#Modified 14.07.2016 to show GITHUB

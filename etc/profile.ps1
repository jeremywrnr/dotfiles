# quick navigation keys
Set-Alias l ls
Set-Alias c cls
Set-Alias d Get-Date
Set-Alias hm GoDoc
Set-Alias ct cleartool
Set-Alias ck GoChecker
Set-Alias dp FindDefaultPrinter


# system variable manipulation
Set-Alias suv setUserVars.pl
Set-Alias ssv setSysVars.pl
Set-Alias guv getUserVars.pl
Set-Alias gsyv getSysVars.pl


# program references
Set-Alias sub "C:\Program Files\Sublime Text 3\sublime_text.exe"
Set-Alias ipy "C:\Program Files (x86)\IronPython 2.7\ipy.exe"
Set-Alias chrome "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"


# function definitions
function goDoc
{
        set-location C:\Users\jeremywrnr\Documents
}

function goProfile
{
        set-location C:\Users\warnerje\Documents\WindowsPowershell
}
function FindDefaultPrinter
{
    Get-WMIObject -query "Select * From Win32_Printer Where Default = TRUE"
}


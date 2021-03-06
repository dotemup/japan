# ---------------------------------------
# Start Helper Functions
# ---------------------------------------

function show-header() {
    write-host -ForegroundColor Red "-----------------------------------"
    write-host -ForegroundColor Red "Just Another Powershell ApplicatioN"
    write-host -ForegroundColor Red "-----------------------------------"
}

function show-spacer() {
    write-host ""
}

function show-anykey() {
    show-spacer
    write-host -ForegroundColor green "Press enter to continue..." -nonewline
    read-host
    clear-host
}

function show-connection() {
    if ($hostname) { write-host -ForegroundColor Cyan "Hostname entered: $hostname" }
    if ($username) { write-host -ForegroundColor Yellow "Username entered: $username" }
    if ($creds) { write-host -ForegroundColor red "Credentials Entered: $creds.UserName" }
    show-spacer
}

function show-collecthostname() {
    clear-host
    show-header
    $hostname = (read-host -prompt "Enter Hostname").trim()
    $fqdn = (System.Net.Dns)::GetHostByName($hostname).Hostname
    clear-host
    show-hostmenu
}

function show-collectusername() {
    clear-host
    show-header
    $username = (read-host -prompt "Enter Username").trim()
    clear-host
    show-usermenu
}

function show-collectcreds() {
    $creds = Get-Credential
    show-main
}


# ---------------------------------------
# Start Menu Functions
# ---------------------------------------

function show-main() {
    $MenuItems = (
        '1 - Host Menu',
        '2 - User Menu',
        '3 - Enter Credentials',
        '',
        'x - Exit'
    )

    $ValidChoices = $MenuItems | ForEach-Object {$_[0]}

    $Choice = ''

    while ($Choice -notin $ValidChoices) {

        clear-host
        show-header
        show-connection

        foreach ($item in $MenuItems) {
            write-host " $item"
        }

        show-spacer
        write-host -ForegroundColor Yellow "Please enter a choice from the above items: " -nonewline
        $Choice = (read-host).ToLower()

    }

    switch ($choice) {

        '1' { show-hostmenu }
        '2' { show-usermenu }
        '3' { show-collectcreds }

        'x' { break }

    }

}

function show-hostmenu() {

    $MenuItems = (
        '1 - Ping Computer',
        '2 - Show Connected Users',
        '3 - Get Uptime',
        '4 - Get Windows Version',
        '5 - Show Installed Programs',
        '',
        '6 - Enter PS Session',
        '7 - Launch Remote Assistance',
        '',
        '8 - Lock Workstation',
        '9 - Logoff Active User',
        '0 - Restart Computer',
        '',
        'e - Launch RegEdit',
        's - Launch Services',
        '',
        'n - New PS Session',
        '',
        $(if ($hostname) {'r - Reset Hostname'} else {'r - Enter Hostname'}),
        'x - Back'
    )

    $ValidChoices = $MenuItems | ForEach-Object {$_[0]}

    $Choice = ''

    while ($Choice -notin $ValidChoices) {

        clear-host
        show-header
        show-connection

        foreach ($item in $MenuItems) {
            write-host " $item"
        }

        show-spacer
        write-host -ForegroundColor Yellow "Please enter a choice from the above items: " -nonewline
        $Choice = (read-host).ToLower()

    }

    switch ($choice) {

        '1' { invoke-ping }
        '2' { invoke-qwinsta }
        '3' { invoke-uptime }
        '4' { invoke-getinfo }
        '5' { invoke-programs }

        '6' { invoke-pssession }
        '7' { invoke-msra }

        '8' { invoke-lock }
        '9' { invoke-logoff }
        '0' { invoke-restart }
        
        'e' { invoke-regedit }
        's' { invoke-services }
        
        'n' { invoke-newps }

        'r' { show-collecthostname }
        'x' { show-main }

    }

}

function show-usermenu() {

    $MenuItems = (
        '1 - Show User Details',
        '2 - Get Usergroups',
        '',
        $(if ($username) {'r - Reset User'} else {'r - Enter Username'}),
        'x - Back'
    )

    $ValidChoices = $MenuItems | ForEach-Object {$_[0]}

    $Choice = ''

    while ($Choice -notin $ValidChoices) {

        clear-host
        show-header
        show-connection

        foreach ($item in $MenuItems) {
            write-host " $item"
        }

        show-spacer
        write-host -ForegroundColor Yellow "Please enter a choice from the above items: " -nonewline
        $Choice = (read-host).ToLower()

    }

    switch ($choice) {

        '1' { invoke-showuserdetails }
        '2' { invoke-getusergroups }

        'r' { show-collectusername }
        'x' { show-main}

    }

}

# ---------------------------------------
# Start Invoke Functions
# ---------------------------------------

function invoke-ping() {
    write-host -ForegroundColor Cyan "Used powershell to ping $hostname to show machine status."
    ping -n 2 $hostname
    show-anykey
    show-hostmenu
}

function invoke-qwinsta() {
    write-host -ForegroundColor Cyan "Used powershell to show connected users on $hostname."
    qwinsta /server:hostname
    show-anykey
    show-hostmenu
}

function invoke-programs() {
    write-host -ForegroundColor Magenta "This may take a while..."
    write-host -ForegroundColor Cyan "Used powershell to view installed programs on $hostname"
    invoke-command -ComputerName $hostname -scriptblock { Get-WmiObject -Class Win32_Product } | select-object -Property Name, Version | Sort-Object Name | Out-GridView
    show-anykey
    show-hostmenu
}

function invoke-services() {
    write-host -ForegroundColor Cyan "Used powershell to open services for $hostname"
    services.msc /computer=$hostname
    show-anykey
    show-hostmenu
}

function invoke-regedit() {
    write-host -ForegroundColor Cyan "Used powershell to open regedit for $hostname"
    regedit
    show-anykey
    show-hostmenu
}

function invoke-pssession() {
    write-host -ForegroundColor Cyan "Used powershell to set up remote commandline session for $hostname"
    enter-pssession $hostname
    # show-anykey
    # find a better way to do this in a new window w/o exit
}

function invoke-msra() {
    write-host -ForegroundColor Cyan "Used powershell to offer remote desktop assistance using 'msra /offerra' for $hostname"
    msra /offerra $hostname
    show-anykey
    show-hostmenu
}

function invoke-newps() {
    start-process powershell -Credential $creds
}

function invoke-getinfo() {
    $productname = invoke-command -ComputerName $hostname -ScriptBlock { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName }

    $version = invoke-command -ComputerName $hostname -ScriptBlock {
        Try {
            (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
        } Catch {
            "N/A"
        }
    }

    $currentbuild = invoke-command -ComputerName $hostname -ScriptBlock { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild }

    write-host $productname, $version, $currentbuild

    show-anykey
    show-hostmenu
}

function invoke-uptime() {
    write-host -ForegroundColor Cyan "Used powershell to get uptime of machine $hostname"
    invoke-command -ComputerName $hostname -ScriptBlock { (get-date) - (gcim win32_operatingsystem).lastbootuptime }
    show-anykey
    show-hostmenu
}

function invoke-lock() {
    write-host -ForegroundColor Cyan "Used powershell to remotely lock workstation $hostname"
    invoke-command -ComputerName $hostname -ScriptBlock { Start-Process rundll32.exe user32.dll,LockWorkStation }
    show-anykey
    show-hostmenu
}

function invoke-logoff() {
    write-host -ForegroundColor Cyan "Used powershell to disconnect active user of machine $hostname"
    invoke-command -ComputerName $hostname -ScriptBlock { Start-Process shutdown -l }
    show-anykey
    show-hostmenu
}

function invoke-restart() {
    write-host -ForegroundColor Cyan "Used powershell to restart machine $hostname with the 'Restart-Computer' command"
    invoke-command -ComputerName $hostname -ScriptBlock { Restart-Computer -Force }
    show-anykey
    show-hostmenu
    # find a better way to do this with a break timer after x seconds if winrm is broken
}

function invoke-getusergroups() {

    if ($username) {
        Get-ADPrincipalGroupMembership -Identity $username | Select-Object Name, GroupScope, GroupCategory, objectGUID | Sort-Object Name 
    } else {
        write-host -ForegroundColor Magenta "You set a username first"
    }

    show-anykey
    show-usermenu
}

function invoke-showuserdetails() {

    if ($username) {
        net user /domain $username
    } else {
        write-host -ForegroundColor Magenta "You set a username first"
    }

    show-anykey
    show-usermenu
}

# ---------------------------------------
# Start Program
# ---------------------------------------

Show-Main

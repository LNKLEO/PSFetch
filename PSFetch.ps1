<#PSScriptInfo
.VERSION 2.2.0
.GUID 1c26142a-da43-4125-9d70-97555cbb1752
.DESCRIPTION PSFetch is a command-line system information utility for Windows written in PowerShell.
.AUTHOR LNKLEO
.PROJECTURI https://github.com/LNKLEO/PSFetch
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>
<#
.SYNOPSIS
    PSFetch - Neofetch for Windows in PowerShell 5+
.DESCRIPTION
    PSFetch is a command-line system information utility for Windows written in PowerShell.
.PARAMETER image
    Display a pixelated image instead of the usual logo. Imagemagick required.
.PARAMETER genconf
    Download a configuration template. Internet connection required.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER help
    Display this help message.
.INPUTS
    System.String
.OUTPUTS
    System.String[]
.NOTES
    Run PSFetch without arguments to view core functionality.
#>
[CmdletBinding()]
param(
    [string][alias('i')]$image,
    [switch][alias('g')]$genconf,
    [switch][alias('n')]$noimage,
    [switch][alias('h')]$help
)

$e = [char]0x1B

$colorBar = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}' +
    '{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}' +
    '{0}[0m') -f $e, '   '

$is_pscore = if ($PSVersionTable.PSEdition.ToString() -eq 'Core') {
    $true
}
else {
    $false
}

$configdir = $env:XDG_CONFIG_HOME, "${env:USERPROFILE}\.config" | Select-Object -First 1
$config = "${configdir}/PSFetch/config.ps1"

$defaultconfig = 'https://github.com/evilprince2009/PSFetch/blob/main/lib/config.ps1'

# ensure configuration directory exists
if (-not (Test-Path -Path $config)) {
    [void](New-Item -Path $config -Force)
}

# ===== DISPLAY HELP =====
if ($help) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        get-help ($MyInvocation.MyCommand.Definition) -full | less
    }
    else {
        get-help ($MyInvocation.MyCommand.Definition) -full
    }
    exit 0
}

# ===== GENERATE CONFIGURATION =====
if ($genconf.IsPresent) {
    if ((Get-Item -Path $config).Length -gt 0) {
        Write-Output 'ERROR: configuration file already exists!' -f red
        exit 1
    }
    "INFO: downloading default config to '$config'."
    Invoke-WebRequest -Uri $defaultconfig -OutFile $config -UseBasicParsing
    'INFO: successfully completed download.'
    exit 0
}

# ===== VARIABLES =====
$disabled = 'disabled'
$strings = @{
    dashes     = ''
    img        = ''
    title      = ''
    os         = ''
    hostname   = ''
    username   = ''
    computer   = ''
    terminal   = ''
    cpu        = ''
    gpu        = ''
    memory     = ''
    disk_c     = ''
    pwsh       = ''
    pkgs       = ''
    kernel     = ''
}

# ===== CONFIGURATION =====
[Flags()]
enum Configuration {
    None = 0
    Show_Title = 1
    Show_Dashes = 2
    Show_OS = 4
    Show_Computer = 8
    Show_Terminal = 32
    Show_CPU = 64
    Show_GPU = 128
    Show_Memory = 256
    Show_Disk = 512
    Show_Pwsh = 1024
    Show_Pkgs = 2048
}
[Configuration]$configuration = if ((Get-Item -Path $config).Length -gt 0) {
    . $config
}
else {
    0xFFF
}

# ===== OS =====
$strings.os = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption.ToString().TrimStart('Microsoft ')

# ===== LOGO =====
$img = @(
    "                                                                       ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    " ${e}[31m################${e}[0m   ${e}[32m################${e}[0m ",
    "                                                                       ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    " ${e}[34m################${e}[0m   ${e}[33m################${e}[0m ",
    "                                                                       "
)

# ===== HOSTNAME =====
$strings.hostname = $Env:COMPUTERNAME

# ===== USERNAME =====
$strings.username = [Environment]::UserName


# ===== TITLE =====
$strings.title = if ($configuration.HasFlag([Configuration]::Show_Title)) {
    "${e}[1;36m{0}${e}[0m@${e}[1;36m{1}${e}[0m" -f $strings['username', 'hostname']
}
else {
    $disabled
}


# ===== DASHES =====
$strings.dashes = if ($configuration.HasFlag([Configuration]::Show_Dashes)) {
    -join $(for ($i = 0; $i -lt ('{0}@{1}' -f $strings['username', 'hostname']).Length; $i++) { '-' })
}
else {
    $disabled
}


# ===== COMPUTER =====
$strings.computer = if ($configuration.HasFlag([Configuration]::Show_Computer)) {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem
    '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
}
else {
    $disabled
}

# ===== TERMINAL =====
# this section works by getting
# the parent processes of the
# current powershell instance.
$strings.terminal = if ($configuration.HasFlag([Configuration]::Show_Terminal) -and $is_pscore) {
    $parent = (Get-Process -Id $PID).Parent
    for () {
        if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
            $parent = (Get-Process -Id $parent.ID).Parent
            continue
        }
        break
    }
    try {
        switch ($parent.ProcessName) {
            'explorer' { 'Windows Console' }
            default { $PSItem }
        }
    }
    catch {
        $parent.ProcessName
    }
}
else {
    $disabled
}

# ===== CPU/GPU =====
$strings.cpu = if ($configuration.HasFlag([Configuration]::Show_CPU)) {
    (Get-CimInstance -ClassName Win32_Processor).Name
}
else {
    $disabled
}

$strings.gpu = if ($configuration.HasFlag([Configuration]::Show_GPU)) {
    ("{0} [{1}]" -f (Get-CimInstance -ClassName Win32_VideoController).Name, (Get-CimInstance -ClassName Win32_VideoController).DriverVersion)
}
else {
    $disabled
}

# ===== MEMORY =====
$strings.memory = if ($configuration.HasFlag([Configuration]::Show_Memory)) {
    $m = Get-CimInstance -ClassName Win32_OperatingSystem
    $total = [math]::Floor($m.TotalVisibleMemorySize / 1kb)
    $totalv = [math]::Floor(($m.TotalVirtualMemorySize - $m.TotalVisibleMemorySize) / 1kb)
    $used = [math]::Floor((($m.TotalVisibleMemorySize - $m.FreePhysicalMemory) / 1kb))
    $usedv = [math]::Floor((($m.TotalVirtualMemorySize - $m.TotalVisibleMemorySize - $m.FreeVirtualMemory + $m.FreePhysicalMemory) / 1kb))
    ("{0} MiB / {1} MiB [{2} MiB / {3} MiB]" -f $used, $total, $usedv, $totalv)
}
else {
    $disabled
}

# ===== DISK USAGE C =====
$strings.disk_c = if ($configuration.HasFlag([Configuration]::Show_Disk)) {
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID="C:"'
    $total = [math]::Floor(($disk.Size / 1mb))
    $used = [math]::Floor((($disk.Size - $disk.FreeSpace) / 1mb))
    $usage = [math]::Round(($used / $total * 100), 2)
    ("{0} MiB / {1} MiB ({2}%)" -f $used, $total, $usage)
}
else {
    $disabled
}

# ===== POWERSHELL VERSION =====
$strings.pwsh = if ($configuration.HasFlag([Configuration]::Show_Pwsh)) {
    "PowerShell $($PSVersionTable.PSVersion)"
}
else {
    $disabled
}

# ===== Kernel Version =====
$strings.kernel = [Environment]::OSVersion.Version.ToString()

# ===== PACKAGES =====
function Get-PackageManager {
    $_pms = ''

    if ((Get-Command -Name scoop -ErrorAction Ignore).Name -eq 'scoop.exe') {
        $_pms += 'scoop '
    }
    if ((Get-Command -Name winget -ErrorAction Ignore).Name -eq 'winget.exe') {
        $_pms += 'winget '
    }
    
    if ((Get-Command -Name choco -ErrorAction Ignore).Name -eq 'choco.exe') {
        $_pms += 'choco '
    } 

    if ($_pms.Length -eq 0) {
        return '(none)'
    }
    else {
        return $_pms.Replace(' ', ', ').TrimEnd(', ')
    }
}

$strings.pkgs = Get-PackageManager

# Reset terminal sequences and display a newline
Write-Output "${e}[0m"

# Add system info into an array
$info = [collections.generic.list[string[]]]::new()
$info.Add(@("", $strings.title))
$info.Add(@("", $strings.dashes))
$info.Add(@("OS", $strings.os))
$info.Add(@("Kernel Version", $strings.kernel))
$info.Add(@("Host", $strings.computer))
$info.Add(@("Packages", $strings.pkgs))
$info.Add(@("Shell", $strings.pwsh))
$info.Add(@("Terminal", $strings.terminal))
$info.Add(@("CPU", $strings.cpu))
$info.Add(@("GPU", $strings.gpu))
$info.Add(@("Memory", $strings.memory))
$info.Add(@("Disk (C:)", $strings.disk_c))
$info.Add(@("", ""))
$info.Add(@("", $colorBar))

# Write system information in a loop
$counter = 0
$logoctr = 0
while ($counter -lt $info.Count) {
    $logo_line = $img[$logoctr]
    $item_title = "$e[1;36m$($info[$counter][0])$e[0m"
    $item_content = if (($info[$counter][0]) -eq '') {
        $($info[$counter][1])
    }
    else {
        ": $($info[$counter][1])"
    }

    if ($item_content -notlike '*disabled') {
        " ${logo_line}$e[40G${item_title}${item_content}"
    }

    $counter++
    if ($item_content -notlike '*disabled') {
        $logoctr++
    }
}

# Print the rest of the logo
if ($logoctr -lt $img.Count) {
    while ($logoctr -le $img.Count) {
        " $($img[$logoctr])"
        $logoctr++
    }
}

# Print a newline
write-output ''

# Compatible with both Windows PowerShell & PowerShell Core
# Author: Ibne Nahian (@evilprince2009)
#
#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|

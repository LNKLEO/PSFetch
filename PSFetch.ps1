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
$ee = "$e[0m"
$es = "$ee$e[5;37m"
$er = "$ee$e[1;31m"
$eg = "$ee$e[1;32m"
$eb = "$ee$e[1;34m"
$ey = "$ee$e[1;33m"
$et = "$ee$e[1;36m"
$eh = "$ee$e[1;37;46m"

$colorBar = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}' +
    '{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}' +
    '{0}[0m') -f $e, '   '

$units = ('','KiB', 'MiB', 'GiB', 'TiB')

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
    dashes       = ''
    img          = ''
    title        = ''
    os           = ''
    hostname     = ''
    username     = ''
    computer     = ''
    uptime       = ''
    terminal     = ''
    cpu          = ''
    gpu          = ''
    memory       = ''
    volumesum    = ''
    volumes      = @()
    pwsh         = ''
    pkgs         = ''
    kernel       = ''
    refresh_rate = ''
}

# ===== CONFIGURATION =====
[Flags()]
enum Configuration {
    None          = 0
    Show_Title    = 1
    Show_Dashes   = 2
    Show_OS       = 4
    Show_Computer = 8
    Show_Uptime = 16
    Show_Terminal = 32
    Show_CPU      = 64
    Show_GPU      = 128
    Show_Memory   = 256
    Show_Volumes  = 512
    Show_Pwsh     = 1024
    Show_Pkgs     = 2048
}
[Configuration]$configuration = if ((Get-Item -Path $config).Length -gt 0) {
    . $config
}
else {
    0xFEF
}

# ===== OS =====
$strings.os = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption.ToString().TrimStart('Microsoft ')

# ===== LOGO =====
$img = @(
    " $es·$es················$es··$es················$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$er################$es··$eg################$es·$ee ",
    " $es·$es················$es··$es················$es·$ee ",
    " $es·$es················$es··$es················$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$eb################$es··$ey################$es·$ee ",
    " $es·$es················$es··$es················$es·$ee "
)

# ===== HOSTNAME =====
$strings.hostname = $Env:COMPUTERNAME

# ===== USERNAME =====
$strings.username = [Environment]::UserName


# ===== TITLE =====
$strings.title = if ($configuration.HasFlag([Configuration]::Show_Title)) {
    "${e}[1;37m{0}${e}[0m@${e}[1;36m{1}${e}[0m" -f $strings['username', 'hostname']
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
} else {
    $disabled
}

# ===== UPTIME =====
$strings.uptime = if ($configuration.HasFlag([Configuration]::Show_Uptime)) {
    $(switch ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime) {
        ({ $PSItem.Days -eq 1 }) { '1 day' }
        ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
        ({ $PSItem.Hours -eq 1 }) { '1 hour' }
        ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
        ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
        ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
    }) -join ' '
} else {
    $disabled
}

# ======= Refresh Rate =======

function Get-RefreshRate {
    return "$((Get-CimInstance -ClassName Win32_VideoController | Select-Object -Property CurrentRefreshRate).CurrentRefreshRate)Hz"
}

$strings.refresh_rate = Get-RefreshRate

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
    $total = [double]($m.TotalVisibleMemorySize) * 1024
    $htotal = $total
    $totalv = [double]($m.TotalVirtualMemorySize - $m.TotalVisibleMemorySize) * 1024
    $htotalv = $totalv
    $unit = 0
    while ($htotal-gt 999) {
        $htotal /= 1024
        $htotalv /= 1024
        ++ $unit
    }
    $htotal = $htotal.ToString("N3").Substring(0,5)
    $htotalv = $htotalv.ToString("N3").Substring(0,5)
    $unit = $units[$unit]
    ("{0}[+{1}] {2} ({3}[+{4}])" -f $htotal, $htotalv, $unit, $total.ToString("N0"), $totalv.ToString("N0"))
}
else {
    $disabled
}

# ===== Volumes =====
$strings.volumes = if ($configuration.HasFlag([Configuration]::Show_Volumes)) {
    $capsum=0
    Get-CimInstance -ClassName Win32_Volume | Foreach-Object {
        $cap = $_.Capacity
        $hcap = [double]$cap
        $capsum += $hcap
        $unit = 0
        while ($hcap -gt 999) {
            $hcap /= 1024
            ++ $unit
        }
        $hcap = $hcap.ToString("N3").Substring(0,5)
        $unit = $units[$unit]
        $mount = $_.Name.Trim("\")
        if ($mount.StartsWith("?")) {
            $mount = "\\?\"
        }
        $label = $_.Label
        @(,@(("> {0} [$eh{1}$et]" -f $label, $mount), ("{0} {1} ({2})" -f $hcap, $unit, $cap.ToString("N0"))))
    }
    $hcap = $capsum
    $unit = 0
    while ($hcap -gt 999) {
        $hcap /= 1024
        ++ $unit
    }
    $hcap = $hcap.ToString("N3").Substring(0,5)
    $unit = $units[$unit]
    $strings.volumesum = "{0} {1} ({2})" -f $hcap, $unit, $capsum.ToString("N0")
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
foreach($card in $strings.gpu) {
    if ($card.ToUpper() -Match "NVIDIA") {
        $info.Add(@("GPU (Dedicated)", $card))
    } else {
        $info.Add(@("GPU (Integrated)", $card))
    }
}
$info.Add(@("Refresh Rate", $strings.refresh_rate))
$info.Add(@("Memory", $strings.memory))
$info.Add(@("Volumes", $strings.volumesum))
foreach ($Volume in $strings.volumes) {
    $info.Add($Volume)
}
$info.Add(@("", ""))
$info.Add(@("", $colorBar))

# Write system information in a loop
$counter = 0
$logoctr = 0
while ($counter -lt $info.Count) {
    $logo_line = $img[$logoctr]
    $item_title = "$et$($info[$counter][0])$ee"
    $item_content = if (($info[$counter][0]) -eq '') {
        $($info[$counter][1])
    }
    else {
        ": $($info[$counter][1])"
    }

    if ($item_content -notlike '*disabled') {
        " ${logo_line}$e[42G${item_title}${item_content}"
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

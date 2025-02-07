# @name         Generate HTTPS URL with /html/ root removed
# @command      powershell.exe -ExecutionPolicy Bypass -STA -NoProfile ^
#                   -File "%EXTENSION_PATH%" -webRoot "%WebRoot%" -rootPath "%RootPath%" ^
#                   -hostName "%HostName%" -serverName "!@" -path "!/" %Https% %Pause% ^
#                   %Clipboard% %Open% !&
# @description  Generates HTTPS URL of the selected file with the /html/ root removed
# @flag         RemoteFiles
# @flag         ShowResultsInMsgBox
# @version      5
# @homepage     https://winscp.net/eng/docs/extension_generate_http_url
# @require      WinSCP 5.12
# @option       - -site group "URL"
# @option         - -site label "These options are site-specific."
# @option         WebRoot -site textbox "&Web root path:"
# @option         Https -site checkbox "Use HTTP&S" "" "-https"
# @option         RootPath -site textbox "&URL root path (optional):"
# @option         HostName -site textbox "&Web server hostname override (optional):"
# @option       - group "Options"
# @option         Pause checkbox "Display URL" "-pause" "-pause"
# @option         Clipboard checkbox "Copy URL to clipboard" "-clipboard" "-clipboard"
# @option         Open checkbox "Open URL in web browser" "" "-open"
# @optionspage  https://winscp.net/eng/docs/extension_generate_http_url#options

param (
    [Parameter(Mandatory = $True)]
    $webRoot,
    $rootPath,
    $hostName,
    $serverName,
    [Parameter(Mandatory = $True)]
    $path,
    [Switch]
    $https,
    [Switch]
    $pause,
    [Switch]
    $clipboard,
    [Switch]
    $open,
    [Parameter(Mandatory = $True, ValueFromRemainingArguments = $True, Position = 0)]
    $paths
)

try
{
    if (!$webRoot -or ($webRoot.SubString($webRoot.Length - 1, 1) -ne "/"))
    {
        $webRoot += "/"
    }

    $result = $Null
    foreach ($filePath in $paths)
    {
        $filePath = "$path$filePath"

        if (($filePath.Length -lt $webRoot.length) -or
            ($filePath.SubString(0, $webRoot.Length) -ne $webRoot))
        {
            throw "**The path $filePath is not under web root $webRoot.**"
        }

        # Ensure rootPath is formatted correctly
        if ($rootPath)
        {
            if ($rootPath.SubString($rootPath.Length - 1) -ne "/")
            {
                $rootPath += "/"
            }
        }
        else
        {
            $rootPath = "/"
        }

        # Extracting only the part of the path after '/html/'
        $urlPath = $filePath -replace ".*?/html/", ""

        # Encode URL components
        $urlPath = ($urlPath -split "/" | %{ [System.Uri]::EscapeDataString($_) }) -join "/"
     
        # Always use HTTPS
        $protocol = "https://"

        if (!$hostName)
        {
            $hostName = $serverName
        }
        
        # Construct the final URL
        $url = "$protocol$hostName/$urlPath"
        $result += $url
        if ($paths.Count -gt 1)
        {
            $result += "`r`n"
        }

        if ($open)
        {
            Start-Process $url
        }
    }

    if ($pause)
    {
        Write-Host -NoNewline $result
    }

    if ($clipboard)
    {
        Add-Type -Assembly PresentationCore
        [Windows.Clipboard]::SetText($result) 
    }

    $result = 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    $result = 1
}

exit $result

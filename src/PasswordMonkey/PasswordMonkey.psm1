$Script:Passwords = @{};
$Script:PasswordTimeout = 5

function ClearPasswordFromClipboard{
    param (
        [pscredential]$PasswordCredential
    )
    
    $Script = @"
    {
        Add-Type -AssemblyName 'System.Windows.Forms'
        Start-Sleep -Seconds $Script:PasswordTimeout

        if((Get-Clipboard) -eq '$($PasswordCredential.GetNetworkCredential().Password)'){
            [System.Windows.Forms.Clipboard]::Clear()         
        }        
    }.Invoke()
"@    
    
    Start-Process -FilePath powershell -ArgumentList $Script -WindowStyle 'Hidden'
}

<#
    .SYNOPSIS
        Stores a new password in your cache  
    
    .DESCRIPTION
        Stores a new password in your cache. Passwords are stored as PSCredentials. Name need not be 
        (and often won't be) the same as the UserName of the Credential

    .PARAMETER Name
        Specifies the name used to store the password in the cache.
        
    .EXAMPLE
        Pops up the credential window for secure input add stores the result
        
        Add-Password -Name 'mono'

    .EXAMPLE
        Stores a copy of the supplied credential
            
        $Credential = Get-Credential;
        Add-Password -Name 'mono' -Credential $Credential          
#>
function Add-Password {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credential
    )

    if($Script:Passwords.ContainsKey($Name)){
        throw "Password '$Name' already exists. To update an existing password please use Set-Password"
    }
    
    if(!$Credential) {
        $Credential = Get-Credential -Message "Enter credentials for $Name" -UserName $Name
    } 
    
    if(!$Credential) {
        Write-Verbose "Add-Password cancelled for $Name"
    } else {
        Write-Verbose "Saving password $Name ($($Credential.UserName))"
        $Script:Passwords.Add($Name, $Credential);
        Write-Verbose "Saving password $Name, ($($Credential.UserName)) - done."        
    }
}

<#
    .SYNOPSIS
        Creates or updates a password in your cache  
    
    .DESCRIPTION
        Creates or updates a password in your cache. Passwords are stored as PSCredentials. Name need not be 
        the same as the UserName of the Credential

    .PARAMETER Name
        Specifies the name used to store the password in the cache.
        
    .EXAMPLE
        #pops up the credential window for secure input add stores the result
        
        Set-Password -Name 'mono'

    .EXAMPLE
        Stores a copy of the supplied credential
            
        $Credential = Get-Credential;
        Set-Password -Name 'mono' -Credential $Credential          

    .EXAMPLE
        Updates a copy of the supplied credential
        
        # create the password    
        $Credential = Get-Credential;
        Set-Password -Name 'mono' -Credential $Credential
        
        # do stuff ...
        
        # update the password
        $AnotherCredential = Get-Credential;              
        Set-Password -Name 'mono' -Credential $Credential
#>
function Set-Password {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credential
    )

    if(!$Credential){
        $Credential = Get-Credential -Message "Enter credentials for $Name" -UserName $Name
    }
    
    if(!$Credential){
        Write-Verbose "Set-Password cancelled for $Name"
    } else {
        if($Script:Passwords.ContainsKey($Name)){
            Remove-Password -Name $Name;
        }
        Add-Password -Name $Name -Credential $Credential ;
    }
}

function Get-Password {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='default', Position=0)]
        $Name,
        [Parameter(ParameterSetName='list' )]
        [switch]
        $ListAvailable,
        [Parameter(ParameterSetName='default')]
        [switch]
        $OutputToConsole,
        [Parameter(ParameterSetName='default')]
        [switch]
        $Force,
        [Parameter(ParameterSetName='default', Mandatory=$false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Char # one based 
    )

    switch ($PsCmdlet.ParameterSetName) 
    { 
        'default'  {
             Write-verbose "Getting password $Name"
             
             $Password = $Passwords[$Name].GetNetworkCredential().Password

             if($Char -ge 1){
                 if($Char -gt $Password.Length){
                    throw "`$Char should be less than $($Password.Length)"
                 } else {
                    $Password = $password[$Char - 1]                      
                 }
             }
             
             if($OutputToConsole){
                Write-Warning "Be careful out there!";
                Write-Output "$Password";
             } else {
                Write-verbose "Password copied to clipboard"
                $Password | Set-Clipboard ;
                ClearPasswordFromClipboard -PasswordCredential $Passwords[$Name]
             }
             
            Write-verbose "Getting password $Name - done."
            break;
        } 
        'list'  { 
            Write-Verbose "Listing passwords"
            
            $Script:Passwords.Keys |  ForEach-Object {[PsCustomObject]@{Name=$_}}
            
            Write-Verbose "Listing passwords - done."
            break;
        } 
    } 
    
}

function Remove-Password {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Name
    )

    Write-Verbose "Removing password $Name"
    
    $Script:Passwords.Remove($Name);
    
    Write-Verbose "Removing password $Name - done."
}

function Clear-Passwords {
    [CmdLetBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [switch] $Force
    )

    Write-Verbose "Clearing passwords"
    
    if($Force.IsPresent -or $PSCmdlet.ShouldProcess("ALL")){
        $Script:Passwords = @{};
    }
    
    Write-Verbose "Clearing passwords - done."
    
}

<#
    .EXAMPLE 
        
        Add-Password -Name 'mono' 
        Set-PasswordEnvironmentVariable -Name 
        
        # use the environment variable        
        Invoke-SqlCmd -Password $Env:mono @OtherParams
    
    .EXAMPLE 
        
        Add-Password -Name 'mono' 
        Set-PasswordEnvironmentVariable -Name 'mono' -EnvironmentVariableName 'DatabasePassword'
        
        # use the environment variable
        Invoke-SqlCmd -Password $Env:DatabasePassword @OtherParams                
#>
function Set-PasswordEnvironmentVariable {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter(Mandatory=$false)]
        $EnvironmentVariableName = $Name
    )

    Write-Verbose "Setting environment variable $EnvironmentVariableName from $Name"

    $Password = $Passwords[$Name].GetNetworkCredential().Password

    if(!(Test-Path "Env:\$EnvironmentVariableName")){
        New-Item -Path "Env:\$EnvironmentVariableName" -Value $Password | out-null
    } else {
        Set-Item -Path "Env:\$EnvironmentVariableName" -Value $Password
    }
}

<#
    .SYNOPSIS
        Returns a *new* credential for the specifed password
    
    .DESCRIPTION
        Returns a *new* credential for the specifed password. Note: this will use the cached user name which may not be the same as the password name.
    
    .EXAMPLE
        Get-PasswordCredential -Name 'mono' 

    .EXAMPLE
        Cache creds for your azure subscription, and use them to login.
        
        Add-Password -Name 'azure'
        # enter user name and password in the credentials input box
        Login-AzureRmAccount -Credential (Get-PasswordCredential -Name 'azure')

#>
function Get-PasswordCredential {
    [CmdLetBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param (
        [Parameter(Mandatory=$true)]
        $Name
    )

    $Credential =  $Passwords[$Name]
    $NewCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Credential.UserName, $Credential.Password;
    $NewCredential;                
}

<#
    .SYNOPSIS
        Returns a basic auth header for the specifed user name and password.
    
    .EXAMPLE
         Get-BasicAuthHeader -Name 'mono' 

    .EXAMPLE
        Set a password and then use it a basic auth header with Invoke-RestMethod  
        
        # assume $OtherParams and $Headers have already been set
        Add-Password -Name 'mono'
        # enter user name and password in the credentials input     box
        $Headers += Get-BasicAuthHeader -Name 'mono'
        
        Invoke-RestMethod -Headers $Headers @OtherParams
#>
function Get-PasswordBasicAuthHeader {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,
        [Parameter(Mandatory=$False, ParameterSetName="default")]
        [string] $UserName = $Name,
        [Parameter(Mandatory=$true,ParameterSetName="use-credential-name")]
        [switch] $UseCredentialName
    )
    
    $Credential = $Script:Passwords[$Name];
    
    if(!$Credential){
        throw "Password not found";
    }
    
    if($UseCredentialNameForUserName.IsPresent){
        $UserName = $Credential.UserName;
    }
    
    $Password = $Credential.GetNetworkCredential().Password;
    $Pair = "$($UserName):$($Password)";
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair);
    $Base64 = [System.Convert]::ToBase64String($Bytes);
    $BasicAuthValue = "Basic $Base64";
    $Headers = @{ Authorization = $BasicAuthValue};
    $Headers;
}


function Set-PasswordMonkeyAliases{
    [CmdLetBinding()]
    param (
    )

    if($null -eq ((get-alias) | Where-Object {$_.Name -eq 'gpwd'})){
        New-Alias -Name 'gpwd' -Value 'PasswordMonkey\Get-Password' -Description 'Gets a password' -Scope 'Global'
    } else {
        Write-Warning "Cannot set alias gpwd as it already exists"
    }

    if($null -eq ((get-alias) | Where-Object {$_.Name -eq 'spwd'}) ){
        New-Alias -Name 'spwd' -Value 'PasswordMonkey\Set-Password' -Description 'Sets a password' -Scope 'Global'
    } else {
        Write-Warning "Cannot set alias spwd as it already exists"
    }
}

Write-Verbose "Importing argument completers..." 

Get-ChildItem -Path $PsScriptRoot\ArgumentCompleters -File -filter *.ArgumentCompleters.ps1 | ForEach-Object {
    Write-Verbose " importing $($_.FullName)";
    . $_.FullName;
} 

Write-verbose "Importing argument completers - done."
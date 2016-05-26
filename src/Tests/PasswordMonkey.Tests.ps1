$Script:ModulePath =  "$PSScriptRoot\..\PasswordMonkey\PasswordMonkey.psm1"


function Get-TestCredential{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param (
        [string] $Username,
        [string] $Password        
    )
        
    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,($Password| ConvertTo-SecureString -AsPlainText -force);
}

Describe "New-Password" {
    It 'Does not allow duplicates by name' {
         $UserName = 'asy8h';
         $Password = '52y74g8oyb';
         $PasswordName = 'singe';
         $Credential = Get-TestCredential -Username $UserName -Password $Password; 

         New-Password -Name $PasswordName -Credential $Credential;
         {New-Password -Name $PasswordName -Credential $Credential}  | Should Throw;     
    }
    
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
}

Describe "Get-Password" {
     It 'returns null when no passwords have been added' {
         Get-Password | Should BeNullOrEmpty;         
     }

    It 'sets clipboard correctly when individual password requested' {
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 

        New-Password -Name $PasswordName -Credential $Credential;
        (Get-Password | Where Name -eq $PasswordName)  | Should Not BeNullOrEmpty;
        ((Get-Password | Where Name -eq $PasswordName) | Measure-Object).Count   | Should Be 1;
        Get-Password -Name $PasswordName;
        Get-Clipboard  | Should be $Password;
     }
     
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
}


Describe "Set-Password" {
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey
    }
    
    It 'creates password when password not present' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
          
        # pre-conditions
        (Get-Password | Where Name -eq $PasswordName)  | Should BeNullOrEmpty;
        
        # act
        Set-Password -Name $PasswordName -Credential $Credential;
        
        # assert
        (Get-Password | Where Name -eq $PasswordName)  | Should Not BeNullOrEmpty;
        ((Get-Password | Where Name -eq $PasswordName) | Measure-Object).Count   | Should Be 1;
        Get-Password -Name $PasswordName;
        Get-Clipboard  | Should be $Password;         
    }

    It 'updates password when password already present' {
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $Password2 = '467ybrgupi98uh';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential;
        
        # act
        $Credential =  Get-TestCredential -Username $UserName -Password $Password2;
        Set-Password -Name $PasswordName -Credential $Credential;
        
        # assert
        (Get-Password | Where Name -eq $PasswordName)  | Should Not BeNullOrEmpty;
        Get-Password -Name $PasswordName;
        Get-Clipboard  | Should be $Password2;     
    }
}


Describe "Remove-Password" {
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
    
    It 'does not throw if password to remove is not present' {
        # arrange
        $PasswordName = 'mono';
          
        # pre-conditions
        (Get-Password | Where Name -eq $PasswordName)  | Should BeNullOrEmpty;
        
        # act/assert
        {Remove-Password -Name $PasswordName} | Should Not Throw;
    }

    It 'removes password when password is present' {
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $Password2 = '467ybrgupi98uh';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential;      
        
        # act
        Remove-Password -Name $PasswordName;
        
        # assert
        Get-Password | Where Name -eq $PasswordName | Should BeNullOrEmpty;
    }
}

Describe "Clear-Passwords" {
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
    
    It 'does not fail when no passwords present' {
         {Clear-Passwords -Force} | Should Not Throw;        
    }

    It 'clears passwords when 1 password is present ' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential; 

        # act
        Clear-Passwords -Force;
        
        # assert
        Get-Password | Should BeNullOrEmpty; 
    }
    
    It 'clears passwords when more than 1 password is present ' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential; 
        
        $UserName2 = '34657392y65p';
        $Password2 = 'dfnvgp7et7lhdfu;ig4-9';
        $PasswordName2 = 'singe';
        $Credential2 =  Get-TestCredential -Username $UserName2 -Password $Password2; 
        New-Password -Name $PasswordName2 -Credential $Credential2; 

        # act
        Clear-Passwords -Force;
        
        # assert
        Get-Password | Should BeNullOrEmpty;
    }
}

Describe 'Set-PasswordEnvironmentVariable' {
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
    
    It 'Creates (and sets) an environment variable for the specifed password' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential; 
        
        # act
        Set-PasswordEnvironmentVariable -Name $PasswordName;
        
        # assert
        (Get-Item -Path "Env:\$PasswordName").Value | Should Be $Password; 
    }
        
    It 'Updates an existing environment variable to the specifed password' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PreexistingPassword = '763854yefgbaleir';
        $PasswordName = 'mono';
        Set-Item -Path "Env:\$PasswordName" -Value $PreexistingPassword;
        
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential; 
        
        # act
        Set-PasswordEnvironmentVariable -Name $PasswordName;
        
        # assert
        (Get-Item -Path "Env:\$PasswordName").Value | Should Be $Password; 
    }
    
    It 'Creates (and sets) an environment variable for the specifed password with an alternate name' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $EnvironmentVariableName = 'singe';
        $Credential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $Credential; 
        
        # act
        Set-PasswordEnvironmentVariable -Name $PasswordName -EnvironmentVariableName $EnvironmentVariableName;
        
        # assert
        (Get-Item -Path "Env:\$EnvironmentVariableName").Value | Should Be $Password; 
    }
}    


Describe 'Get-PasswordCredential' {
    BeforeEach {
       Import-Module $Script:ModulePath;
    }

    AfterEach {
        Remove-Module PasswordMonkey;
    }
    
    It 'returns a valid credential when sepcified password exists.' {
        # arrange
        $UserName = 'asy8h';
        $Password = '52y74g8oyb';
        $PasswordName = 'mono';
        $ExpectedCredential =  Get-TestCredential -Username $UserName -Password $Password; 
        New-Password -Name $PasswordName -Credential $ExpectedCredential; 
        
        # act
        $ActualCredential = Get-PasswordCredential -Name $PasswordName;

        # assert        
        $ActualCredential | Should Not BeNullOrEmpty;
        $ActualCredential.UserName | Should Be $ExpectedCredential.UserName;
        $ActualCredential.GetNetworkCredential().Password | Should Be $ExpectedCredential.GetNetworkCredential().Password ;
    }
}
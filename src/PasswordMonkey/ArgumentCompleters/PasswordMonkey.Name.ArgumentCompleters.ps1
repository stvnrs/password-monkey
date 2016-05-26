$ScriptBlock = {
        <#
        .SYNOPSIS
        Auto-complete the -Name parameter value for PasswordMonkey cmdlets.
		
		
        .NOTES
		Created by Steven Rose @stvnrs (github) @off_by_one (twitter) 
		
		This is based on a template by Trevor Sullivan <trevor@trevorsullivan.net>
        
        #>
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

		$ObjectList = PasswordMonkey\Get-Password ;

        $ItemList = $ObjectList | Where-Object { $PSItem.Name -match $wordToComplete } | ForEach-Object {
            $CompletionText = $PSItem.Name;
            $ToolTip = $PSItem.Name;
            $ListItemText = $PSItem.Name;
            $CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue;

            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @($CompletionText, $ListItemText, $CompletionResultType, $ToolTip);
        }

        return $ItemList
    }

$ArgumentCompleter = @{
        CommandName = @(
			'Get-Password'                    
			'Get-PasswordBasicAuthHeader'             
			'Get-PasswordCredential'          
			'Remove-Password'                 
			'Set-Password'                   
			'Set-PasswordEnvironmentVariable' 
		);

        ParameterName = 'Name';
        ScriptBlock = $ScriptBlock;
}

Microsoft.PowerShell.Core\Register-ArgumentCompleter @ArgumentCompleter;


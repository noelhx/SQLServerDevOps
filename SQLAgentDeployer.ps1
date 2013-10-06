param(
	[string]$serverName = "localhost\SQL2012",
	[string]$ConfigDir = ".",
	[boolean]$SkipFileCheck = $false,
	# [boolean]$SkipFileCheck = $true,
	[boolean]$CheckOnly = $false)
Write-Host "ServerName: $($serverName)"
Write-Host "ConfigDir: $($ConfigDir)"

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.SMO.Agent') | out-null

Import-Module pscx

function Process-JobStep(
	[System.Xml.XmlElement]$config,
	[Microsoft.SqlServer.Management.SMO.Agent.Job]$job)
{
	Write-Host "Processing job step $($config.id)"
	Write-Debug "JobStepConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	Write-Host -nonewline "Checking to see if job step already exists ... "
	$jobStep = $job.JobSteps | Where-Object {$_.ID -eq $config.id}
	if (!$jobStep)
	{   
		Write-Host "it does not exist"
		$jobStep = New-Object Microsoft.SqlServer.Management.SMO.Agent.JobStep($job, $config.name)
		$jobStep.ID = $config.id
		$isNewJobStep = $true
	}
	else {
		Write-Host "it exists"
		$isNewJobStep = $false
	}

	Write-Debug "Name: $($config.name)"
	if ($jobStep.Name -ne $config.name) {
		Write-Debug "Renaming job step"
		$jobStep.Rename($config.name)
	}

	Write-Debug "SubSystem: $($config.subSystem)"
	if ($config.subSystem -eq "ActiveScripting") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::ActiveScripting
	}
	elseif ($config.subSystem -eq "AnalysisCommand") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::AnalysisCommand
	}
	elseif ($config.subSystem -eq "AnalysisQuery") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::AnalysisQuery
	}
	elseif ($config.subSystem -eq "CmdExec") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::CmdExec
	}
	elseif ($config.subSystem -eq "Distribution") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::Distribution
	}
	elseif ($config.subSystem -eq "LogReader") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::LogReader
	}
	elseif ($config.subSystem -eq "Merge") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::Merge
	}
	elseif ($config.subSystem -eq "PowerShell") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::PowerShell
	}
	elseif ($config.subSystem -eq "QueueReader") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::QueueReader
	}
	elseif ($config.subSystem -eq "Snapshot") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::Snapshot
	}
	elseif ($config.subSystem -eq "SSIS") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::Ssis
	}
	elseif ($config.subSystem -eq "TransactSql") {
		$jobStep.SubSystem = [Microsoft.SqlServer.Management.SMO.Agent.AgentSubSystem]::TransactSql
	}
	else {
		throw "SubSystem is set to unhandled value ($($config.subSystem))"
	}

	Write-Debug "OnSuccessAction: $($config.onSuccessAction)"
	if ($config.onSuccessAction -eq "GoToNextStep") {
		$jobStep.OnSuccessAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::GoToNextStep
	}
	elseif ($config.onSuccessAction -eq "GoToStep") {
		$jobStep.OnSuccessAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::GoToStep
	}
	elseif ($config.onSuccessAction -eq "QuitWithFailure") {
		$jobStep.OnSuccessAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::QuitWithFailure
	}
	elseif ($config.onSuccessAction -eq "QuitWithSuccess") {
		$jobStep.OnSuccessAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::QuitWithSuccess
	}
	elseif ($isNewJobStep -and (!$config.onSuccessAction -or $config.onSuccessAction -eq "")) {
		Write-Debug "Defaulting OnSuccessAction to GoToNextStep"
		$jobStep.OnSuccessAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::GoToNextStep
	}
	elseif (!$config.onSuccessAction -or $config.onSuccessAction -eq "") {
		Write-Debug "Leaving OnSuccessAction as is"
	}
	else {
		throw "OnSuccessAction is set to unhandled value ($($config.onSuccessAction))"
	}

	Write-Debug "OnSuccessStep: $($config.onSuccessStep)"
	$jobStep.OnSuccessStep = $config.onSuccessStep

	Write-Debug "OnFailAction: $($config.onFailAction)"
	if ($config.onFailAction -eq "GoToNextStep") {
		$jobStep.OnFailAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::GoToNextStep
	}
	elseif ($config.onFailAction -eq "GoToStep") {
		$jobStep.OnFailAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::GoToStep
	}
	elseif ($config.onFailAction -eq "QuitWithFailure") {
		$jobStep.OnFailAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::QuitWithFailure
	}
	elseif ($config.onFailAction -eq "QuitWithSuccess") {
		$jobStep.OnFailAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::QuitWithSuccess
	}
	elseif ($isNewJobStep -and (!$config.onFailAction -or $config.onFailAction -eq "")) {
		Write-Debug "Defaulting OnFailAction to QuitWithFailure"
		$jobStep.OnFailAction = [Microsoft.SqlServer.Management.SMO.Agent.StepCompletionAction]::QuitWithFailure
	}
	elseif (!$config.onFailAction -or $config.onFailAction -eq "") {
		Write-Debug "Leaving OnFailAction as is"
	}
	else {
		throw "OnFailAction is set to unhandled value ($($config.onFailAction))"
	}

	Write-Debug "OnFailStep: $($config.onFailStep)"
	$jobStep.OnFailStep = $config.onFailStep

	Write-Debug "Command: $($config.InnerXML)"
	$jobStep.Command = $config.InnerXML

	Write-Debug "RetryAttempts: $($config.retryAttempts)"
	if ($config.retryAttempts) { $jobStep.RetryAttempts = $config.retryAttempts }

	Write-Debug "RetryInterval: $($config.retryInterval)"
	if ($config.retryInterval) { $jobStep.RetryInterval = $config.retryInterval }

	Write-Debug "ProxyName: $($config.proxyName)"
	if ($config.proxyName) {
		if ($config.proxyName -ne "") {
			$proxy = $job.Parent.ProxyAccounts | Where-Object { $_.Name -eq $config.proxyName }
			if ($proxy) {
				$jobStep.ProxyName = $config.proxyName
			}
			else {
				Write-Debug "Unable to find proxy ($($config.proxyName))"
				throw "Unable to find proxy ($($config.proxyName))"
			}
		}
		else {
			$jobStep.ProxyName = $config.proxyName
		}
	}

	Write-Debug "DatabaseName: $($config.databaseName)"
	if ($config.databaseName) {
		if ($config.databaseName -ne "") {
			$proxy = $job.Parent.Parent.Databases | Where-Object { $_.Name -eq $config.databaseName }
			if ($proxy) {
				$jobStep.DatabaseName = $config.databaseName
			}
			else {
				Write-Debug "Unable to find DB ($($config.databaseName))"
				throw "Unable to find DB ($($config.databaseName))"
			}
		}
		else {
			$jobStep.DatabaseName = $config.databaseName
		}
	}

	Write-Debug "DatabaseUserName: $($config.databaseUserName)"
	if ($config.databaseUserName) {
		if ($config.databaseUserName -ne "") {
			$proxy = $job.Parent.Parent.Logins | Where-Object { $_.Name -eq $config.databaseUserName }
			if ($proxy) {
				$jobStep.DatabaseUserName = $config.databaseUserName
			}
			else {
				Write-Debug "Unable to find DatabaseUserName ($($config.databaseUserName))"
				throw "Unable to find DatabaseUserName ($($config.databaseUserName))"
			}
		}
		else {
			$jobStep.DatabaseUserName = $config.databaseUserName
		}
	}

	Write-Debug "CommandExecutionSuccessCode: $($config.commandExecutionSuccessCode)"
	if ($config.commandExecutionSuccessCode) {
		$jobStep.CommandExecutionSuccessCode = $config.commandExecutionSuccessCode
	}    

	# OSRunPriority
	# OutputFileName

	if ($isNewJobStep) {
		Write-Debug "Creating job step"
		$jobStep.Create()
	}
	else {
		Write-Debug "Altering job step"
		$jobStep.Alter()
	}
}

function Process-Job(
	[System.Xml.XmlElement]$config,
	[Microsoft.SqlServer.Management.Smo.Server]$server)
{
	Write-Host "Processing job [$($config.name)]"
	Write-Debug "JobConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	Write-Debug "Starting transaction"
	try {
		$server.ConnectionContext.BeginTransaction()

		Write-Host -nonewline "Checking to see if job already exists ... "
		$job = $server.JobServer.Jobs | Where-Object { $_.name -eq $config.name }
		if (!$job) {
			# If it does not already exist
			Write-Host "it does not"
			$job = New-Object Microsoft.SqlServer.Management.SMO.Agent.Job($server.JobServer, $config.name)
			$isNewJob = $true
		}
		else {
			Write-Host "it does"
			$isNewJob = $false
		}

		# OperatorToEmail
		# OperatorToNetSend
		# OperatorToPage

		Write-Debug "Description: $($config.description)"
		$job.Description = $config.description

		Write-Debug "IsEnabled: $($config.isEnabled)"
		if ($config.isEnabled) {
			if ($config.isEnabled -eq "true") {
				$job.IsEnabled = $true
			}
			elseif ($config.isEnabled -eq "false") {
				$job.IsEnabled = $false
			}
			elseif ($config.isEnabled -eq "") {
				Write-Debug "Leaving IsEnabled as is because it is an empty string"
			}
			else {
				Write-Debug "Throwing exception because IsEnabled is set to unhandled value ($($config.isEnabled))"
				throw "IsEnabled is set to unhandled value ($($config.isEnabled))"
			}
		}
		else {
			Write-Debug "Leaving IsEnabled as is because there is no attribute"
		}

		Write-Debug "EmailLevel: $($config.emailLevel)"
		if ($config.emailLevel) {
			if ($config.emailLevel -eq "Always") {
				$job.EmailLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Always
			}
			elseif ($config.emailLevel -eq "Never") {
				$job.EmailLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Never
			}
			elseif ($config.emailLevel -eq "OnFailure") {
				$job.EmailLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnFailure
			}
			elseif ($config.emailLevel -eq "OnSuccess") {
				$job.EmailLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnSuccess
			}
			elseif ($config.emailLevel -eq "") {
				Write-Debug "Leaving EmailLevel as is because it is an empty string"
			}
			else {
				Write-Debug "Throwing exception because EmailLevel is set to unhandled value ($($config.emailLevel))"
				throw "EmailLevel is set to unhandled value ($($config.emailLevel))"
			}
		}
		else {
			Write-Debug "Leaving EmailLevel as is because there is no attribute"
		}

		Write-Debug "EventLogLevel: $($config.eventLogLevel)"
		if ($config.eventLogLevel) {
			if ($config.eventLogLevel -eq "Always") {
				$job.EventLogLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Always
			}
			elseif ($config.eventLogLevel -eq "Never") {
				$job.EventLogLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Never
			}
			elseif ($config.eventLogLevel -eq "OnFailure") {
				$job.EventLogLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnFailure
			}
			elseif ($config.eventLogLevel -eq "OnSuccess") {
				$job.EventLogLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnSuccess
			}
			elseif ($config.eventLogLevel -eq "") {
				Write-Debug "Leaving EventLogLevel as is because it is an empty string"
			}
			else {
				Write-Debug "Throwing exception because EventLogLevel is set to unhandled value ($($config.eventLogLevel))"
				throw "EventLogLevel is set to unhandled value ($($config.eventLogLevel))"
			}
		}
		else {
			Write-Debug "Leaving EventLogLevel as is because there is no attribute"
		}

		Write-Debug "NetSendLevel: $($config.netSendLevel)"
		if ($config.netSendLevel) {
			if ($config.netSendLevel -eq "Always") {
				$job.NetSendLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Always
			}
			elseif ($config.netSendLevel -eq "Never") {
				$job.NetSendLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Never
			}
			elseif ($config.netSendLevel -eq "OnFailure") {
				$job.NetSendLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnFailure
			}
			elseif ($config.netSendLevel -eq "OnSuccess") {
				$job.NetSendLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnSuccess
			}
			elseif ($config.netSendLevel -eq "") {
				Write-Debug "Leaving NetSendLevel as is because it is an empty string"
			}
			else {
				Write-Debug "Throwing exception because NetSendLevel is set to unhandled value ($($config.netSendLevel))"
				throw "NetSendLevel is set to unhandled value ($($config.netSendLevel))"
			}
		}
		else {
			Write-Debug "Leaving NetSendLevel as is because there is no attribute"
		}

		Write-Debug "PageLevel: $($config.pageLevel)"
		if ($config.pageLevel) {
			if ($config.pageLevel -eq "Always") {
				$job.PageLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Always
			}
			elseif ($config.pageLevel -eq "Never") {
				$job.PageLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::Never
			}
			elseif ($config.pageLevel -eq "OnFailure") {
				$job.PageLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnFailure
			}
			elseif ($config.pageLevel -eq "OnSuccess") {
				$job.PageLevel = [Microsoft.SqlServer.Management.SMO.Agent.CompletionAction]::OnSuccess
			}
			elseif ($config.pageLevel -eq "") {
				Write-Debug "Leaving PageLevel as is because it is an empty string"
			}
			else {
				Write-Debug "Throwing exception because PageLevel is set to unhandled value ($($config.pageLevel))"
				throw "PageLevel is set to unhandled value ($($config.pageLevel))"
			}
		}
		else {
			Write-Debug "Leaving PageLevel as is because there is no attribute"
		}

		Write-Debug "OwnerLoginName: $($config.ownerLoginName)"
		if ($config.ownerLoginName) {
			$login = $server.Logins | Where-Object { $_.Name -eq $config.ownerLoginName }
			if ($login) {
				$job.OwnerLoginName = $config.ownerLoginName
			}
			else {
				Write-Debug "Unable to find owner login for job ($($config.ownerLoginName))"
				throw "Unable to find owner login for job ($($config.ownerLoginName))"
			}
		}

		if ($isNewJob) {
			Write-Host "Creating job"
			$job.Create() }
		 else {
			Write-Host "Altering job"
			$job.Alter()
		}

		Write-Debug "Adding/updating steps"
		$config.steps.ChildNodes | ForEach-Object {Process-JobStep $_ $job}
		Write-Debug "Updating job"
		$job.Alter()

		Write-Debug "Getting job steps to remove"
		$jobStepsToRemove = $job.JobSteps | Where-Object { $config.steps.ChildNodes.ID -notcontains $_.ID }
		Write-Debug "Dropping job steps"
		$jobStepsToRemove | ForEach-Object { $_.Drop() }        
		Write-Debug "Updating job"
		$job.Alter()

		<#
			We do this after the steps to make sure the start step is there
		#>
		$StartStep = $job.JobSteps | Where-Object { $_.ID -eq $config.startStepID }
		if ($StartStep) {
			Write-Debug "Setting start job step to $($config.startStepID)"
			$job.StartStepID = $config.startStepID
		}
		else {
			Write-Debug "Unable to find job start step ($($config.startStepID))"
			throw "Unable to find job start step ($($config.startStepID))"
		}

		Write-Debug "Committing transaction"
		$server.ConnectionContext.CommitTransaction()
	}
	catch [System.Exception] {
		Write-Host "ERROR: Rolling back transaction"
		$server.ConnectionContext.RollBackTransaction()
		$e = $_
		while ($e.InnerException -and !$e.Message) { $e = $e.InnerException }
		Write-Host $e.Message
	}
}

function Process-ProxyAccount(
	[System.Xml.XmlElement]$config,
	[Microsoft.SqlServer.Management.Smo.Server]$server)
{
	Write-Host "Processing proxy account [$($config.name)]"
	Write-Debug "ProxyAccountConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	Write-Debug "Starting transaction"
	try {
		$server.ConnectionContext.BeginTransaction()

		Write-Debug "credentialName: $($config.credentialName)"
		$credential = $server.Parent.Credentials | Where-Object { $_.Name -eq $config.credentialName }
		if (!$credential) {
			throw "Could not find credential [$($config.credentialName)]"
		}

		Write-Host -nonewline "Checking to see if proxy account already exists ... "
		$proxyAccount = $server.JobServer.ProxyAccounts | Where-Object { $_.name -eq $config.name }
		if (!$proxyAccount) {
			Write-Host "it does not, creating"

			Write-Debug "isEnabled: $($config.isEnabled)"
			if ($config.isEnabled -eq "true" -or $config.isEnabled -eq "") {
				Write-Debug "Setting enabled to true"
				$enabled = $true
			}
			elseif ($config.isEnabled -eq "false") {
				Write-Debug "Setting enabled to false"
				$enabled = $false
			}
			else {
				Write-Debug "isEnabled set to unhandled value ($($config.isEnabled))"
				throw "isEnabled set to unhandled value ($($config.isEnabled))"
			}

			$proxyAccount = New-Object Microsoft.SqlServer.Management.SMO.Agent.ProxyAccount(
				$server.JobServer,
				$config.name,
				$config.credentialName,
				$enabled,
				$config.description)
		}
		else {
			Write-Host "it does, updating"
			$proxyAccount.CredentialName = $config.credentialName
			if ($config.isEnabled -eq "true") {
				$proxyAccount.IsEnabled = $true
			}
			elseif ($config.isEnabled -eq "false") {
				$proxyAccount.IsEnabled = $false
			}
			elseif ($config.isEnabled -eq "") {
				Write-Debug "Leaving IsEnabled as is"
			}
			else {
				Write-Debug "isEnabled set to unhandled value ($($config.isEnabled))"
				throw "isEnabled set to unhandled value ($($config.isEnabled))"                
			}

			$proxyAccount.Description = $config.Description
		}
	}
	catch [System.Exception] {
		Write-Host "ERROR: Rolling back transaction"
		$server.ConnectionContext.RollBackTransaction()
		$e = $_
		while ($e.InnerException -and !$e.Message) { $e = $e.InnerException }
		Write-Host $e.Message
	}
}

<#
function Process-JobSchedule(
	[System.Xml.XmlElement]$config,
	[Microsoft.SqlServer.Management.SMO.Agent.Job]$job)
{
	Write-Host "Processing job schedule [$($config.name)]"
	Write-Debug "JobScheduleConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	Write-Host -nonewline "Checking to see if job schedule already exists ... "
	$jobSchedule = $job.jobSchedules | Where-Object { $_.Name -eq $config.name }
	if ($jobSchedule) {
		Write-Host "it does, updating"
	}
	else {
		Write-Host 'it does not, creating'
		$jobSchedule = New-Object Microsoft.SqlServer.Management.SMO.Agent.Job($job, $config.name)  
	}

	Write-Debug "isEnabled: $($config.isEnabled)"
	if ($config.isEnabled -eq "true") {
		$jobSchedule.IsEnabled = $true
	}
	elseif ($config.isEnabled -eq "false") {
		$jobSchedule.IsEnabled = $false
	}
	elseif ($config.isEnabled -eq "") {
		Write-Debug "Leaving IsEnabled as is"
	}
	else {
		Write-Debug "Unhandled isEnabled value ($($config.isEnabled))"
		throw "Unhandled isEnabled value ($($config.isEnabled))"
	}

	Write-Debug "frequencyTypes: $($config.frequencyTypes)"
	Write-Debug "frequencyInterval: $($config.frequencyInterval)"
	Write-Debug "frequencyTypes: $($config.frequencyTypes)"
	Write-Debug "frequencyTypes: $($config.frequencyTypes)"
	if ($config.frequencyTypes -eq "AutoStart") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::AutoStart
	}
	elseif ($config.frequencyTypes -eq "Daily") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Daily
		if ($config.frequencyInterval) {
			$jobSchedule.FrequencyInterval = $config.frequencyInterval
		}
		else {
			Write-Debug "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
			throw "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
		}
	}
	elseif ($config.frequencyTypes -eq "Monthly") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Monthly
		if ($config.frequencyInterval -and $config.frequencyInterval -ge 1 -and $config.frequencyInterval -le 31) {
			$jobSchedule.FrequencyInterval = $config.frequencyInterval
		}
		if ($config.frequencyInterval) {
			Write-Debug "No frequencyInterval ($($config.frequencyInterval)) out of bounds when frequencyTypes value ($($config.frequencyTypes))"
			throw "No frequencyInterval ($($config.frequencyInterval)) out of bounds when frequencyTypes value ($($config.frequencyTypes))"
		}
		else {
			Write-Debug "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
			Write-Debug "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
		}
	}
	elseif ($config.frequencyTypes -eq "MonthlyRelative") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::MonthlyRelative
	}
	elseif ($config.frequencyTypes -eq "OneTime") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OneTime
	}
	elseif ($config.frequencyTypes -eq "OnIdle") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OnIdle
	}
	elseif ($config.frequencyTypes -eq "Unknown") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Unknown
	}
	elseif ($config.frequencyTypes -eq "Weekly") {
		$jobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Weekly
		if ($config.frequencyInterval -ge 1) {
			$jobSchedule.FrequencyInterval = $config.frequencyInterval
		}
		else {
			Write-Debug "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
			Write-Debug "No frequencyInterval when frequencyTypes value ($($config.frequencyTypes))"
		}
	}
	else {
		Write-Debug "Unhandled frequencyTypes value ($($config.frequencyTypes))"
		throw "Unhandled frequencyTypes value ($($config.frequencyTypes))"
	}

	Write-Debug "frequencyInterval: $($config.frequencyInterval)"
	if ([[Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Unknown,
			[Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OneTime,
			[Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::AutoStart,
			[Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OnIdle
			] -contains $jobSchedule.FrequencyTypes) {
		Write-Debug "Skipping frequencyInterval, is not applicable for this frequencyTypes"
	}
	else {

		$jobSchedule.FrequencyInterval = $config.frequencyInterval
	}

		ActiveEndDate
		ActiveEndTimeOfDay
		ActiveStartDate
		ActiveStartTimeOfDay
		FrequencyRecurrenceFactor
		FrequencyRelativeIntervals
		FrequencySubDayInterval
		FrequencySubDayTypes

	}
	catch [System.Exception] {
		Write-Host "ERROR: Rolling back transaction"
		$server.ConnectionContext.RollBackTransaction()
		$e = $_
		while ($e.InnerException -and !$e.Message) { $e = $e.InnerException }
		Write-Host $e.Message
	}
}
#>

function Process-JobCategory(
	[System.Xml.XmlElement]$config,
	[Microsoft.SqlServer.Management.Smo.Server]$server)
{
	Write-Host "Processing proxy account [$($config.name)]"
	Write-Debug "jobCategoryConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	Write-Debug "Starting transaction"
	try {
		$server.ConnectionContext.BeginTransaction()

		Write-Debug "credentialName: $($config.credentialName)"
		$credential = $server.Parent.Credentials | Where-Object { $_.Name -eq $config.credentialName }
		if (!$credential) {
			throw "Could not find credential [$($config.credentialName)]"
		}

		Write-Host -nonewline "Checking to see if job already exists ... "
		$jobCategory = $server.JobServer.jobCategorys | Where-Object { $_.name -eq $config.name }
		if (!$jobCategory) {
			Write-Host "it does not, creating"

			Write-Debug "isEnabled: $($config.isEnabled)"
			if ($config.isEnabled -eq "true" -or $config.isEnabled -eq "") {
				Write-Debug "Setting enabled to true"
				$enabled = $true
			}
			elseif ($config.isEnabled -eq "false") {
				Write-Debug "Setting enabled to false"
				$enabled = $false
			}
			else {
				Write-Debug "isEnabled set to unhandled value ($($config.isEnabled))"
				throw "isEnabled set to unhandled value ($($config.isEnabled))"
			}

			$jobCategory = New-Object Microsoft.SqlServer.Management.SMO.Agent.jobCategory(
				$server.JobServer,
				$config.name,
				$config.credentialName,
				$enabled,
				$config.description)
		}
		else {
			Write-Host "it does, updating"
			$jobCategory.CredentialName = $config.credentialName
			if ($config.isEnabled -eq "true") {
				$jobCategory.IsEnabled = $true
			}
			elseif ($config.isEnabled -eq "false") {
				$jobCategory.IsEnabled = $false
			}
			elseif ($config.isEnabled -eq "") {
				Write-Debug "Leaving IsEnabled as is"
			}
			else {
				Write-Debug "isEnabled set to unhandled value ($($config.isEnabled))"
				throw "isEnabled set to unhandled value ($($config.isEnabled))"                
			}

			$jobCategory.Description = $config.Description
		}
	}
	catch [System.Exception] {
		Write-Host "ERROR: Rolling back transaction"
		$server.ConnectionContext.RollBackTransaction()
		$e = $_
		while ($e.InnerException -and !$e.Message) { $e = $e.InnerException }
		Write-Host $e.Message
	}
}

function Process-File(
	[string]$filename,
	[Microsoft.SqlServer.Management.Smo.Server]$server)
{
	Write-Host "Processing file $($filename)"   
	[xml]$config = Get-Content $filename
	Write-Debug "JobConfig:`n----------START----------`n$($config.OuterXml)`n-----------END-----------"

	If ($config.job -ne $null) {
		Process-Job $config.job $server
	}
	else
	{
		Write-Host "Unable to determine config object type"
	}
}

function Check-File(
	[string]$filename,
	[string]$fileType)
{
	Write-Host -nonewline "Checking $($fileType) file $($filename) ... "

	$SchemaPath = Split-Path $script:MyInvocation.MyCommand.Path
	$SchemaFile = Join-Path -path $SchemaPath -childpath "SQLAgentDeployer$($fileType).xsd"
	Write-Debug "XSD File: $($SchemaFile)"

	if (Test-Xml -Path $filename -SchemaPath $SchemaFile) {
		Write-Host "no errors found"
		return $true
	} else {
		Write-Host "error(s) found"
		Test-Xml -Path $filename -SchemaPath $SchemaFile -Verbose
		return $false
	}
}

function Deploy-SQLAgent()
{
	Write-Host "Starting"
	Write-Host "Running as process $($PID)"
	Write-Host "Current time is $(Get-Date)"
	Write-Host "Config directory is $($ConfigDir)"

	if (!$SkipFileCheck) {
		Write-Host "Checking files"
		$FileCheckResults = Get-ChildItem -Path $ConfigDir -Filter Job*.xml | ForEach-Object { Check-File $_ "Job" }
	}
	else {
		Write-Host "Skipping file check"
		$FileCheckResults = $null
	}

	if (!($FileCheckResults | Where-Object { $_ -eq $false })) {
		Write-Host "All files passed checks"
		$server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName)

		Get-ChildItem -Filter Job*.xml | ForEach-Object { Process-File $_ $server }
	}
	else {
		Write-Host "Error(s) found in file(s)"
		return -1
	}
}

$DebugPreference = "SilentlyContinue"
# $DebugPreference = "Continue"
Deploy-SQLAgent

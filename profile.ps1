Import-Module posh-git
Clear-Host
$env:POSH_GIT_ENABLED = $true
Set-PoshPrompt -Theme ~/.mytheme.omp.json

$gitImage = 'patch to image'
$npmImage = 'path to image'

#Utility funtions

function cls {
    Clear-Host
}

# git functions

function status {
    git status
}

function fetch {
    git fetch -p
}

function update {
    fetch
    pull
    Show-Notification "Git Update" "Fetch, prune, and pull run for project" $gitImage
}

function pull {
    git pull
}

function push {
    git push
}

function branches {
    git branch -l
}

function remoteBranches {
    git branch -r
}

function pushUpstream {
    $currentBranch
    git branch -l | foreach {
        if ($_ -match "^\* (.*)") {
            $currentBranch += $matches[1]
        }
    }
    git push --set-upstream origin $currentBranch
}

function nb {
    param([parameter(Mandatory=$true)][string]$name, [parameter(Mandatory=$false)][bool]$setOrigin=$true)

    $branchName = $name
    git checkout -b $branchName
    if ($setOrigin) {
        pushUpstream
    }
}

function rename($newBranchName) {
    $currentBranch = ''
    git branch -l | foreach {
		if($_ -match "^\* (.*)"){
			$currentBranch += $matches[1]
		}
	}
    git branch -m $newBranchName
    git push origin :$currentBranch $newBranchName
    pushUpstream
}

function delete {
[CmdletBinding()]
param()
	DynamicParam{
		$ParameterName = "branch"

		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		$AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

		$ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
		$ParameterAttribute.Mandatory = $false
		$ParameterAttribute.Position = 0

		$AttributeCollection.Add($ParameterAttribute)

		$finalSet = @()
		git branch -l | foreach {
			if($_ -match "^\* (.*)"){
				$currentBranch += $matches[1]
			}else{
				$finalSet += $_.Trim()
			}
		}

		$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($finalSet)

		$AttributeCollection.Add($ValidateSetAttribute)

		$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
		$RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
		return $RuntimeParameterDictionary
	}

	begin{
		$branch = $PsBoundParameters[$ParameterName]
	}
	process{
		if($branch)
		{
			git branch -D $branch
		}
		if(!$branch)
		{
			git checkout master
			git branch -D $currentBranch
		}
	}
}

function deleteAll {
[CmdletBinding()]
param()
	DynamicParam{
		$ParameterName = "branch"

		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		$AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

		$ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
		$ParameterAttribute.Mandatory = $false
		$ParameterAttribute.Position = 0

		$AttributeCollection.Add($ParameterAttribute)

		$finalSet = @()
		git branch -l | foreach {
			if($_ -match "^\* (.*)"){
				$currentBranch += $matches[1]
			}else{
				$finalSet += $_.Trim()
			}
		}

		$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($finalSet)

		$AttributeCollection.Add($ValidateSetAttribute)

		$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
		$RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
		return $RuntimeParameterDictionary
	}

	begin{
		$branch = $PsBoundParameters[$ParameterName]
	}
	process{
		if($branch)
		{
			git branch -D $branch
			git push origin --delete $branch
		}
		if(!$branch) 
		{
			git checkout master
			git branch -D $currentBranch
			git push origin --delete $currentBranch
		}
	}
}

function co{
[CmdletBinding()]
param()
    DynamicParam{
        $ParameterName = "branch"

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0

        $AttributeCollection.Add($ParameterAttribute)

        $finalSet = @()
        git branch -l | foreach {
            if($_ -match "^\* (.*)"){
                $currentBranch += $matches[1]
            }else{
                $finalSet += $_.Trim()
            }
        }

        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($finalSet)

        $AttributeCollection.Add($ValidateSetAttribute)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin{
        $branch = $PsBoundParameters[$ParameterName]
    }

    process{
        git checkout $branch
    }
}

function postpushcleanup{
	Param(
		[Parameter(Mandatory=$true, Position=0)]
		[string] $version,

		[Parameter(Mandatory=$true, Position=1)]
		[bool] $deleteBranch,

		[Parameter(Mandatory=$false, Position=2)]
		[bool] $updateDevelop=$false
	)

	$currentBranch = git rev-parse --abbrev-ref HEAD
	co master
	update
	merge $currentBranch
	tag $version
	deploytotestenvironments
	
	if($deleteBranch) {
		"* deleteBranch flag set...deleting $currentBranch *"
		deleteAll $currentBranch
	}

	if($updateDevelop) {
		"* updateDevelop flag set...merging changes from master to develop *"
		co develop
		merge master
	}
	"* Post Push Cleanup of $currentBranch Complete *"
    Show-Notification "Git" "Post-Push Cleanup of $currentBranch done!" $gitImage
}

# CC65 build and link nes

function buildnes(){
    $inSourceFolder = $false
    $currentLocation = Get-Location
    $buildContents = $true
    if (Test-Path "./src"){
        $inSourceFolder = $true;
    } else {
        Set-Location "../"
        if (Test-Path "./src"){
            $inSourceFolder = $true;
        } else {
            Write-Host "[ERROR]" -ForegroundColor "Red" -NoNewline
            Write-Output " 'src' folder could be found for project."
        }
    }

    if($inSourceFolder){
        Set-Location "./src"
        if(Test-Path "./main.asm"){
            Write-Host "[INFO]" -ForegroundColor "Blue" -NoNewline
            Write-Output " Running ca65 compiler command with nes type."
            ca65 "main.asm" -o "main.o" -t nes
            Write-Host "[INFO]" -ForegroundColor "Blue" -NoNewline
            Write-Output " Running ld65 linker command with nes type."
            ld65 "main.o" -o "main.nes" -t nes
            Remove-Item "./main.o"
            $nesFile = (Get-Item "main.nes").FullName
            Set-Location "../"
            Write-Host "[INFO]" -ForegroundColor "Blue" -NoNewline
            Write-Output " Checking for 'build' folder in project."
            if(-not(Test-Path "./build")){
                Write-Output "[INFO] Creating 'build' folder for project."
                New-Item -Path . -Name "build" -ItemType "directory"
                $buildContents = $false
            }
            Set-Location "./build"
            if ($buildContents){
                Write-Host "[INFO]" -ForegroundColor "Blue" -NoNewline
                Write-Output " Checking 'build' folder contents."
            }
            if(Test-Path "./main.nes"){
                Remove-Item "./*" -Recurse -Force
                Write-Host "[INFO]" -ForegroundColor "Blue" -NoNewline
                Write-Output " Removing previous build folder contents."
            }
            Move-Item -Path $nesFile -Destination .
            Write-Host "[SUCCESS]" -ForegroundColor "Green" -NoNewline
            Write-Output " Project built successfully."
        } else {
            Write-Host "[ERROR]" -ForegroundColor "Red" -NoNewline
            Write-Output " 'main.asm' could not be found for project."
        }
        Set-Location $currentLocation
    }
}

function newnes([string]$projectname){
    New-Item -Path . -Name "${projectname}" -ItemType "directory"
    Set-Location "./${projectname}"
    git init
    New-Item -Path . -Name ".gitignore" -ItemType "file"
    New-Item -Path . -Name "src" -ItemType "directory"
    Set-Location "./src"
    New-Item -Path . -Name "main.asm" -ItemType "file"
    Set-Location "../"
}

# npm commands

function serve() {
    param([parameter(Mandatory=$false)][string]$f, [parameter(Mandatory=$false)][string]$p, [parameter(Mandatory=$false)][bool]$r=$false)
	if (Test-Path "./pubspec.yaml"){
		$folder = "web"
		$port = "8080"
		$release = ""

		if($f)
		{
			$folder = $f
		}
		if($p)
		{
			$port = $p
		}
		if($r)
		{
			$release = "--release"
		}

		$busy = Get-NetTCPConnection | Where-Object LocalPort -eq $port | Select-Object LocalPort,OwningProcess
		while($busy) {
			[int]$port += 1;
			$busy = Get-NetTCPConnection | Where-Object LocalPort -eq $port | Select-Object LocalPort,OwningProcess
		}
		webdev serve $release $folder":"$port --auto=refresh
	} else {
		if (Test-Path "./package.json"){
			$package = Get-Content -Raw "./package.json" | ConvertFrom-Json
			foreach ( $script in $package.scripts ) {
				if ( $script -match ".*dev.*" ) {    
                    npm run dev              
				}

				if ( $script -match ".*serve.*" ) {
					npm run serve
				}
			}
		}
	}
}

#File links

function gitconfig {code "location to git config"}
function hosts {code "C:\Windows\System32\drivers\etc\hosts"}

# Toast
function Show-Notification {
    param(
    [String] $Title,
    [String] $Message,
    [String] $image
    )
    
    $ToastImageAndText02 = [Windows.UI.Notifications.ToastTemplateType, Windows.UI.Notifications, ContentType = WindowsRuntime]::ToastImageAndText02
    $TemplateContent = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::GetTemplateContent($ToastImageAndText02)
    $TemplateContent.SelectSingleNode('//image[@id="1"]').SetAttribute('src', $image)
    $TemplateContent.SelectSingleNode('//text[@id="1"]').InnerText = $Title
    $TemplateContent.SelectSingleNode('//text[@id="2"]').InnerText = $Message
    $AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($TemplateContent)
}

#Clean Up
Clear-Host
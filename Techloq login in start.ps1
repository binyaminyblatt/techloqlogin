Function New-Shortcut {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,  ValueFromPipelineByPropertyName=$True,Position=0)] 
    [Alias("File","Shortcut")] 
    [string]$Path,

    [Parameter(Mandatory=$True,  ValueFromPipelineByPropertyName=$True,Position=1)] 
    [Alias("Target")] 
    [string]$TargetPath,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=2)] 
    [Alias("Args","Argument")] 
    [string]$Arguments,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=3)]  
    [Alias("Desc")]
    [string]$Description,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=4)]  
    [string]$HotKey,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=5)]  
    [Alias("WorkingDirectory","WorkingDir")]
    [string]$WorkDir,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=6)]  
    [int]$WindowStyle,

    [Parameter(ValueFromPipelineByPropertyName=$True,Position=7)]  
    [string]$Icon,

    [Parameter(ValueFromPipelineByPropertyName=$True)]  
    [switch]$admin
)


Process {

  If (!($Path -match "^.*(\.lnk)$")) {
    $Path = "$Path`.lnk"
  }
  [System.IO.FileInfo]$Path = $Path
  Try {
    If (!(Test-Path $Path.DirectoryName)) {
      md $Path.DirectoryName -ErrorAction Stop | Out-Null
    }
  } Catch {
    Write-Verbose "Unable to create $($Path.DirectoryName), shortcut cannot be created"
    Return $false
    Break
  }


  # Define Shortcut Properties
  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut($Path.FullName)
  $Shortcut.TargetPath = $TargetPath
  $Shortcut.Arguments = $Arguments
  $Shortcut.Description = $Description
  $Shortcut.HotKey = $HotKey
  $Shortcut.WorkingDirectory = $WorkDir
  $Shortcut.WindowStyle = $WindowStyle
  If ($Icon){
    $Shortcut.IconLocation = $Icon
  }

  Try {
    # Create Shortcut
    $Shortcut.Save()
    # Set Shortcut to Run Elevated
    If ($admin) {     
      $TempFileName = [IO.Path]::GetRandomFileName()
      $TempFile = [IO.FileInfo][IO.Path]::Combine($Path.Directory, $TempFileName)
      $Writer = New-Object System.IO.FileStream $TempFile, ([System.IO.FileMode]::Create)
      $Reader = $Path.OpenRead()
      While ($Reader.Position -lt $Reader.Length) {
        $Byte = $Reader.ReadByte()
        If ($Reader.Position -eq 22) {$Byte = 34}
        $Writer.WriteByte($Byte)
      }
      $Reader.Close()
      $Writer.Close()
      $Path.Delete()
      Rename-Item -Path $TempFile -NewName $Path.Name | Out-Null
    }
    Return $True
  } Catch {
    Write-Verbose "Unable to create $($Path.FullName)"
    Write-Verbose $Error[0].Exception.Message
    Return $False
  }

}
}
# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}
New-Shortcut -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Teckloq Login"  -TargetPath "https://block.techloq.com" -Icon "https://raw.githubusercontent.com/binyaminyblatt/techloqlogin/master/Binyamin%20Blatt.ico"

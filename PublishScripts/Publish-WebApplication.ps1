#Requires -Version 3.0

<#
.SYNOPSIS
Erstellt Windows Azure-Websites, virtuelle Computer, SQL-Datenbanken und Speicherkonten für ein Visual Studio-Webprojekt und stellt diese bereit.

.DESCRIPTION
Das Publish-WebApplication.ps1-Skript erstellt die Windows Azure-Ressourcen, die Sie in einem Visual Studio-Webprojekt angeben, und stellt diese (optional) für Sie bereit. Es kann zum Erstellen von Windows Azure-Websites, virtuellen Computern, SQL-Datenbanken und Speicherkonten verwendet werden.

To manage the entire application lifecycle of your web application in this script, implement the placeholder functions New-WebDeployPackage and Test-WebApplication.

Falls Sie den WebDeployPackage-Parameter mit einem gültigen Webbereitstellungspaket (ZIP-Datei) angeben, stellt Publish-WebApplication.ps1 zudem Ihre Webseiten oder virtuellen Computer bereit, die erstellt werden.

Dieses Skript erfordert Windows PowerShell 3.0 oder höher und Windows Azure PowerShell Version 0.7.4 oder höher. Informationen zum Installieren von Windows Azure PowerShell und seinem Azure-Modul finden Sie unter http://go.microsoft.com/fwlink/?LinkID=350552. Geben Sie Folgendes ein, um die Version des Azure-Moduls zu finden: (Get-Module -Name Azure -ListAvailable).version Geben Sie Folgendes ein, um die Version von Windows PowerShell zu finden: $PSVersionTable.PSVersion

Führen Sie vor diesem Skript das Add-AzureAccount-Cmdlet aus, um die Anmeldeinformationen Ihres Windows Azure-Kontos in Windows PowerShell anzugeben. Falls Sie SQL-Datenbanken erstellen, müssen Sie zudem über einen vorhandenen Windows Azure SQL-Datenbankserver verfügen. Verwenden Sie zum Erstellen einer SQL-Datenbank das New-AzureSqlDatabaseServer-Cmdlet im Azure-Modul.

Also, if you have never run a script, use the Set-ExecutionPolicy cmdlet to an execution policy that allows you to run scripts. To run this cmdlet, start Windows PowerShell with the 'Run as administrator' option.

Dieses Publish-WebApplication.ps1-Skript verwendet die JSON-Konfigurationsdatei, die Visual Studio beim Erstellen Ihres Webprojekts generiert. Die JSON-Datei befindet sich im PublishScripts-Ordner Ihrer Visual Studio-Lösung.

Sie können das databases-Objekt in Ihrer JSON-Konfigurationsdatei löschen oder bearbeiten. Das website- oder cloudservice-Objekt sowie dessen Attribute dürfen nicht gelöscht werden. Sie können allerdings das gesamte databases-Objekt oder die Attribute löschen, die für eine Datenbank stehen. Wenn Sie eine SQL-Datenbank nur erstellen, aber nicht bereitstellen möchten, löschen Sie das connectionStringName-Attribut oder dessen Wert.

Es verwendet zudem Funktionen im Windows PowerShell-Skriptmodul "AzureWebAppPublishModule.psm1", um die Ressourcen in Ihrem Windows Azure-Abonnement zu erstellen. Eine Kopie dieses Skriptmoduls finden Sie im PublishScripts-Ordner Ihrer Visual Studio-Lösung.

Sie können das Publish-WebApplication.ps1-Skript in der vorliegenden Form verwenden oder an Ihre Anforderungen anpassen. Sie können auch die Funktionen im AzureWebAppPublishModule.psm1-Modul unabhängig vom Skript verwenden und bearbeiten. So können Sie beispielsweise die Invoke-AzureWebRequest-Funktion verwenden, um eine beliebige REST-API im Windows Azure-Webdienst aufzurufen.

Sobald Sie über ein Skript verfügen, das die benötigten Windows Azure-Ressourcen erstellt, können Sie es wiederholt verwenden, um Umgebungen und Ressourcen in Windows Azure zu erstellen.

Updates zu diesem Skript finden Sie unter "http://go.microsoft.com/fwlink/?LinkId=391217".
Unterstützung zum Erstellen Ihres Webanwendungsprojekts erhalten Sie in der MSBuild-Dokumentation unter "http://go.microsoft.com/fwlink/?LinkId=391339". 
Unterstützung zum Ausführen von Komponententests für Ihr Webanwendungsprojekt finden Sie in der VSTest.Console-Dokumentation unter "http://go.microsoft.com/fwlink/?LinkId=391340". 

Die Lizenzbedingungen für Web Deploy finden Sie unter "http://go.microsoft.com/fwlink/?LinkID=389744". 

.PARAMETER Configuration
Dient zum Angeben des Pfads und des Dateinamens der von Visual Studio generierten JSON-Konfigurationsdatei. Dieser Parameter muss angegeben werden. Diese Datei befindet sich im PublishScripts-Ordner Ihrer Visual Studio-Lösung. Der Benutzer kann die JSON-Konfigurationsdateien durch Bearbeiten der Attributwerte und Löschen optionaler SQL-Datenbankobjekte anpassen. Für die ordnungsgemäße Ausführung des Skripts können SQL-Datenbankobjekte auf der Website und in Konfigurationsdateien für virtuelle Computer gelöscht werden. Website- und Cloud-Dienst-Objekte und -Attribute können nicht gelöscht werden. Falls der Benutzer bei der Veröffentlichung keine SQL-Datenbank erstellen oder in die Verbindungszeichenfolge übernehmen möchte, muss er sicherstellen, dass das connectionStringName-Attribut im SQL-Datenbankobjekt leer ist, oder das gesamte SQL-Datenbankobjekt löschen.

HINWEIS: Dieses Skript unterstützt nur Windows-VHD-Dateien (Dateien für virtuelle Festplatten) für virtuelle Computer. Zur Verwendung einer Linux-VHD muss das Skript so geändert werden, dass ein Cmdlet mit einem Linux-Parameter (wie New-AzureQuickVM oder New-WAPackVM) aufgerufen wird.

.PARAMETER SubscriptionName
Gibt den Namen eines Abonnements in Ihrem Windows Azure-Konto an. Dieser Parameter ist optional. Der Standard ist das aktuelle Abonnement (Get-AzureSubscription -Current). Falls Sie ein Abonnement angeben, das nicht das aktuelle ist, ändert das Skript das angegebene Abonnement zu "aktuell", stellt aber den aktuellen Abonnementstatus wieder her, bevor das Skript fertig gestellt ist. Falls im Skript Fehler auftreten, bevor es abgeschlossen ist, wird das angegebene Abonnement möglicherweise dennoch als "aktuell" festgelegt.

.PARAMETER WebDeployPackage
Gibt den Pfad und den Dateinamen eines Webbereitstellungspakets (ZIP-Datei) an, das Visual Studio generiert. Dieser Parameter ist optional.

Falls Sie ein gültiges Webbereitstellungspaket angeben, verwendet dieses Skript MsDeploy.exe und das Webbereitstellungspaket zum Bereitstellen der Website.

Informationen zum Erstellen eines Webbereitstellungspakets (ZIP-Datei) finden Sie in "Gewusst wie: Erstellen eines Webbereitstellungspakets in Visual Studio" unter http://go.microsoft.com/fwlink/?LinkId=391353.

Informationen über MSDeploy.exe finden Sie in der Web Deploy-Befehlszeilenreferenz unter http://go.microsoft.com/fwlink/?LinkId=391354 

.PARAMETER AllowUntrusted
Ermöglicht die Herstellung nicht vertrauenswürdiger SSL-Verbindungen mit dem Web Deploy-Endpunkt des virtuellen Computers. Dieser Parameter wird beim Aufrufen von "MSDeploy.exe" verwendet und ist optional. Der Standardwert ist "False". Dieser Parameter ist nur relevant, wenn Sie den WebDeployPackage-Parameter mit einem gültigen ZIP-Dateiwert angeben. Informationen zu "MSDeploy.exe" finden Sie in der Web Deploy-Befehlszeilenreferenz unter "http://go.microsoft.com/fwlink/?LinkId=391354". 

.PARAMETER VMPassword
Dient zum Angeben eines Benutzernamens und eines Kennworts für den Administrator des virtuellen Windows Azure-Computers, den das Skript erstellt. Dieser Parameter akzeptiert eine Hash-Tabelle mit Namens- und Kennwortschlüsseln wie etwa:
@{Name = "admin"; Password = "pa$$word"}

Dieser Parameter ist optional. Falls Sie ihn auslassen, sind der Benutzername und das Kennwort für den virtuellen Computer die Standardwerte in der JSON-Konfigurationsdatei.

Dieser Parameter ist nur gültig, wenn die JSON-Konfigurationsdatei für einen Cloud-Dienst vorgesehen ist, der virtuelle Computer enthält.

.PARAMETER DatabaseServerPassword
Sets the password for a Windows Azure SQL database server. This parameter takes an array of hash tables with Name (SQL database server name) and Password keys. Enter one hash table for each database server that your SQL databases use.

Dieser Parameter ist optional. Der Standardwert ist das SQL-Datenbankserverkennwort aus der von Visual Studio generierten JSON-Konfigurationsdatei.

Dieser Wert ist wirksam, wenn die JSON-Konfigurationsdatei databases- und serverName-Attribute enthält und der Name-Schlüssel in der Hash-Tabelle dem serverName-Wert entspricht.

.INPUTS
Keine. Sie können keine Parameterwerte an dieses Skript weiterreichen.

.OUTPUTS
Keine. Dieses Skript gibt keine Objekte zurück. Den Skriptstatus erhalten Sie mithilfe des Verbose-Parameters.

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 -Configuration C:\Documents\Azure\WebProject-WAWS-dev.json

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADWebApp-VM-prod.json `
-Subscription Contoso '
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
-AllowUntrusted `
-DatabaseServerPassword @{Name='dbServerName';Password='adminPassword'} `
-Verbose

.EXAMPLE
PS C:\> $admin = @{name="admin";password="Test123"}
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADVM-VM-test.json `
-SubscriptionName Contoso `
-WebDeployPackage C:\Documents\Azure\ADVM.zip `
-VMPaassword = @{name = "vmAdmin"; password = "pa$$word"} `
-DatabaseServerPassword = @{Name='server1';Password='adminPassword1'}, @{Name='server2';Password='adminPassword2'} `
-Verbose

.LINK
New-AzureVM

.LINK
New-AzureStorageAccount

.LINK
New-AzureWebsite

.LINK
Add-AzureEndpoint
#>
[CmdletBinding(DefaultParameterSetName = 'None', HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=391696')]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $Configuration,

    [Parameter(Mandatory = $false)]
    [String]
    $SubscriptionName,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $WebDeployPackage,

    [Parameter(Mandatory = $false)]
    [Switch]
    $AllowUntrusted,

    [Parameter(Mandatory = $false, ParameterSetName = 'VM')]
    [ValidateScript( { $_.Contains('Name') -and $_.Contains('Password') } )]
    [Hashtable]
    $VMPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'WebSite')]
    [ValidateScript({ !($_ | Where-Object { !$_.Contains('Name') -or !$_.Contains('Password')}) })]
    [Hashtable[]]
    $DatabaseServerPassword,

    [Parameter(Mandatory = $false)]
    [Switch]
    $SendHostMessagesToOutput = $false
)


function New-WebDeployPackage
{
    #Schreiben Sie eine Funktion zum Erstellen und Verpacken Ihrer Webanwendung.

    #Verwenden Sie "MsBuild.exe", um Ihre Webanwendung zu erstellen. Hilfe dazu finden Sie in der MSBuild-Befehlszeilenreferenz unter "http://go.microsoft.com/fwlink/?LinkId=391339".
}

function Test-WebApplication
{
    #Bearbeiten Sie diese Funktion, um einen Komponententest für Ihre Webanwendung auszuführen.

    #Schreiben Sie eine Funktion zum Ausführen von Komponententests für Ihre Webanwendung (unter Verwendung von "VSTest.Console.exe"). Hilfe dazu finden Sie in der VSTest.Console-Befehlszeilenreferenz unter "http://go.microsoft.com/fwlink/?LinkId=391340".
}

function New-AzureWebApplicationEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword
    )
   
    $VMInfo = $null

    # Falls die JSON-Datei über ein webSite-Element verfügt
    if ($Config.IsAzureWebSite)
    {
        Add-AzureWebsite -Name $Config.name -Location $Config.location | Out-String | Write-HostWithTime
        # Erstellen Sie die SQL-Datenbanken. Die Verbindungszeichenfolge wird für die Bereitstellung verwendet.
    }
    else
    {
        $VMInfo = New-AzureVMEnvironment `
            -CloudServiceConfiguration $Config.cloudService `
            -VMPassword $VMPassword
    } 

    $connectionString = New-Object -TypeName Hashtable
    
    if ($Config.Contains('databases'))
    {
        @($Config.databases) |
            Where-Object {$_.connectionStringName -ne ''} |
            Add-AzureSQLDatabases -DatabaseServerPassword $DatabaseServerPassword -CreateDatabase:$Config.IsAzureWebSite |
            ForEach-Object { $connectionString.Add($_.Name, $_.ConnectionString) }           
    }
    
    return @{ConnectionString = $connectionString; VMInfo = $VMInfo}   
}

function Publish-AzureWebApplication
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMInfo           
    )

    if ($Config.IsAzureWebSite)
    {
        if ($ConnectionString -and $ConnectionString.Count -gt 0)
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage `
                -ConnectionString $ConnectionString
        }
        else
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage
        }
    }
    else
    {
        $waitingTime = $VMWebDeployWaitTime

        $result = $null
        $attempts = 0
        $allAttempts = 60
        do 
        {
            $result = Publish-WebPackageToVM `
                -VMDnsName $VMInfo.VMUrl `
                -IisWebApplicationName $Config.webDeployParameters.IisWebApplicationName `
                -WebDeployPackage $WebDeployPackage `
                -UserName $VMInfo.UserName `
                -UserPassword $VMInfo.Password `
                -AllowUntrusted:$AllowUntrusted `
                -ConnectionString $ConnectionString
             
            if ($result)
            {
                Write-VerboseWithTime ($scriptName + ' Die Veröffentlichung für den virtuellen Computer war erfolgreich.')
            }
            elseif ($VMInfo.IsNewCreatedVM -and !$Config.cloudService.virtualMachine.enableWebDeployExtension)
            {
                Write-VerboseWithTime ($scriptName + ' "enableWebDeployExtension" muss auf $true festgelegt werden.')
            }
            elseif (!$VMInfo.IsNewCreatedVM)
            {
                Write-VerboseWithTime ($scriptName + ' Der vorhandene virtuelle Computer unterstützt Web Deploy nicht.')
            }
            else
            {
                Write-VerboseWithTime ($scriptName + " Fehler beim Veröffentlichen des virtuellen Computers. Versuch $($attempts + 1) von $allAttempts.")
                Write-VerboseWithTime ($scriptName + " Die Veröffentlichung für den virtuellen Computer beginnt in $waitingTime Sekunden.")
                
                Start-Sleep -Seconds $waitingTime
            }
             
             $attempts++
        
             #Führen Sie die Veröffentlichung erneut aus, aber nur für den neu erstellten virtuellen Computer mit installiertem Web Deploy. 
        } While( !$result -and $VMInfo.IsNewCreatedVM -and $attempts -lt $allAttempts -and $Config.cloudService.virtualMachine.enableWebDeployExtension)
        
        if (!$result)
        {                    
            Write-Warning 'Publishing to the virtual machine failed. This can be caused by an untrusted or invalid certificate.  You can specify �AllowUntrusted to accept untrusted or invalid certificates.'
            throw ($scriptName + ' Fehler beim Veröffentlichen für den virtuellen Computer.')
        }
    }
}


# Hauptroutine des Skripts
Set-StrictMode -Version 3

# Aktuelle Version des AzureWebAppPublishModule.psm1-Moduls importieren
Remove-Module AzureWebAppPublishModule -ErrorAction SilentlyContinue
$scriptDirectory = Split-Path -Parent $PSCmdlet.MyInvocation.MyCommand.Definition
Import-Module ($scriptDirectory + '\AzureWebAppPublishModule.psm1') -Scope Local -Verbose:$false

New-Variable -Name VMWebDeployWaitTime -Value 30 -Option Constant -Scope Script 
New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
New-Variable -Name SendHostMessagesToOutput -Value $SendHostMessagesToOutput -Scope Global -Force

try
{
    $originalErrorActionPreference = $Global:ErrorActionPreference
    $originalVerbosePreference = $Global:VerbosePreference
    
    if ($PSBoundParameters['Verbose'])
    {
        $Global:VerbosePreference = 'Continue'
    }
    
    $scriptName = $MyInvocation.MyCommand.Name + ':'
    
    Write-VerboseWithTime ($scriptName + ' Start')
    
    $Global:ErrorActionPreference = 'Stop'
    Write-VerboseWithTime ('{0} $ErrorActionPreference ist auf "{1}" festgelegt.' -f $scriptName, $ErrorActionPreference)
    
    Write-Debug ('{0}: $PSCmdlet.ParameterSetName = {1}' -f $scriptName, $PSCmdlet.ParameterSetName)

    # Speichern Sie das aktuelle Abonnement. Es wird später im Skript auf den aktuellen Status zurückgesetzt.
    Backup-Subscription -UserSpecifiedSubscription $SubscriptionName
    
    # Prüfen Sie, ob Sie Azure-Modul Version 0.7.4 oder höher besitzen.
    if (-not (Test-AzureModule))
    {
         throw 'Ihre Version von Windows Azure PowerShell ist veraltet. Die neueste Version finden Sie unter "http://go.microsoft.com/fwlink/?LinkID=320552".'
    }
    
    if ($SubscriptionName)
    {

        # Falls Sie einen Abonnementnamen angegeben haben, prüfen Sie, ob das Abonnement in Ihrem Konto vorhanden ist.
        if (!(Get-AzureSubscription -SubscriptionName $SubscriptionName))
        {
            throw ("{0}: Der Abonnementname $SubscriptionName wurde nicht gefunden." -f $scriptName)

        }

        # Legen Sie für das angegebene Abonnement aktuell fest.
        Select-AzureSubscription -SubscriptionName $SubscriptionName | Out-Null

        Write-VerboseWithTime ('{0}: Das Abonnement ist auf "{1}" festgelegt.' -f $scriptName, $SubscriptionName)
    }

    $Config = Read-ConfigFile $Configuration -HasWebDeployPackage:([Bool]$WebDeployPackage)

    #Webanwendung erstellen und verpacken
    #New-WebDeployPackage

    #Komponententest für die Webanwendung ausführen
    #Test-WebApplication

    #Azure-Umgebung gemäß Beschreibung in der JSON-Konfigurationsdatei erstellen
    $newEnvironmentResult = New-AzureWebApplicationEnvironment -Config $Config -DatabaseServerPassword $DatabaseServerPassword -VMPassword $VMPassword

    #Webanwendungspaket bereitstellen, wenn $WebDeployPackage vom Benutzer angegeben wird 
    if($WebDeployPackage)
    {
        Publish-AzureWebApplication `
            -Config $Config `
            -ConnectionString $newEnvironmentResult.ConnectionString `
            -WebDeployPackage $WebDeployPackage `
            -VMInfo $newEnvironmentResult.VMInfo
    }
}
finally
{
    $Global:ErrorActionPreference = $originalErrorActionPreference
    $Global:VerbosePreference = $originalVerbosePreference

    # Das ursprüngliche aktuelle Abonnement auf den aktuellen Status zurücksetzen
    Restore-Subscription

    Write-Output $Global:AzureWebAppPublishOutput    
    $Global:AzureWebAppPublishOutput = @()
}

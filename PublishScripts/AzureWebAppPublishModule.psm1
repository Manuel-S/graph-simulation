#  "AzureWebAppPublishModule.psm1" ist ein Windows PowerShell-Skriptmodul. Das Modul exportiert Windows PowerShell-Funktionen, die die Lebenszyklusverwaltung für Webanwendungen automatisieren. Sie können die Funktionen in der vorliegenden Form verwenden oder für Ihre Anwendung und Veröffentlichungsumgebung anpassen.





Set-StrictMode -Version 3

# Eine Variable zum Speichern des ursprünglichen Abonnements.
$Script:originalCurrentSubscription = $null

# Eine Variable zum Speichern des ursprünglichen Speicherkontos.
$Script:originalCurrentStorageAccount = $null

# Eine Variable zum Speichern des Speicherkontos des vom Benutzer angegebenen Abonnements.
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# Eine Variable zum Speichern des Abonnementnamens.
$Script:userSpecifiedSubscription = $null

# Web Deploy-Portnummer
New-Variable -Name WebDeployPort -Value 8172 -Option Constant

<#
.SYNOPSIS
Stellt einer Nachricht das Datum und die Uhrzeit voran.

.DESCRIPTION
Stellt einer Nachricht das Datum und die Uhrzeit voran. Diese Funktion ist für Nachrichten vorgesehen, die an die Streams Error und Verbose geschrieben werden.

.PARAMETER  Message
Dient zum Angeben der Nachrichten ohne Datum.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "Hinzufügen der Datei $filename zum Verzeichnis"
2/5/2014 1:03:08 PM - Hinzufügen der Datei $filename zum Verzeichnis

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
Schreibt eine Fehlermeldung mit der aktuellen Zeit als Präfix.

.DESCRIPTION
Schreibt eine Fehlermeldung mit der aktuellen Zeit als Präfix. Diese Funktion ruft die Format-DevTestMessageWithTime-Funktion auf, um vor dem Schreiben einer Nachricht an den Error-Stream die Zeit voranzustellen.

.PARAMETER  Message
Dient zum Angeben der Nachricht im Fehlermeldungsaufruf. Die Nachrichtenzeichenfolge kann an die Funktion weitergeleitet werden.

.INPUTS
System.String

.OUTPUTS
Keine. Die Funktion schreibt in den Error-Stream.

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
Schreibt eine ausführliche Nachricht mit der aktuellen Zeit als Präfix.

.DESCRIPTION
Schreibt eine ausführliche Nachricht mit der aktuellen Zeit als Präfix. Durch den Aufruf von Write-Verbose wird die Nachricht nur angezeigt, wenn das Skript mit dem Verbose-Parameter ausgeführt wird oder wenn die VerbosePreference-Einstellung auf Continue festgelegt ist.

.PARAMETER  Message
Dient zum Angeben der Nachricht im ausführlichen Meldungsaufruf. Die Nachrichtenzeichenfolge kann an die Funktion weitergeleitet werden.

.INPUTS
System.String

.OUTPUTS
Keine. Die Funktion schreibt in den Verbose-Stream.

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
Schreibt eine Host-Nachricht mit der aktuellen Zeit als Präfix.

.DESCRIPTION
Diese Funktion schreibt eine Nachricht an das Hostprogramm (Write-Host) mit der aktuellen Zeit als Präfix. Die Auswirkungen des Schreibens an das Hostprogramm variieren. Die meisten Programme, die Windows PowerShell hosten, schreiben solche Nachrichten an die Standardausgabe.

.PARAMETER  Message
Dient zum Angeben der Basisnachricht ohne Datum. Die Nachrichtenzeichenfolge kann an die Funktion weitergeleitet werden.

.INPUTS
System.String

.OUTPUTS
Keine. Die Funktion schreibt die Nachricht an das Hostprogramm.

.EXAMPLE
PS C:> Write-HostWithTime -Message "Der Vorgang war erfolgreich."
1/27/2014 11:02:37 AM - Der Vorgang war erfolgreich.

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
Gibt $true zurück, wenn eine Eigenschaft oder Methode Mitglied des Objekts ist. Andernfalls wird $false zurückgegeben.

.DESCRIPTION
Gibt $true zurück, wenn die Eigenschaft oder Methode ein Mitglied des Objekts ist. Für statische Methoden der Klasse und für Ansichten wie PSBase und PSObject gibt die Funktion $false zurück.

.PARAMETER  Object
Dient zum Angeben des Objekts im Test. Geben Sie eine Variable an, die ein Objekt oder einen Ausdruck enthält, von dem ein Objekt zurückgegeben wird. Sie können keine Typen (wie etwa [DateTime] angeben oder Objekte an diese Funktion weiterleiten.

.PARAMETER  Member
Dient zum Angeben des Namens der Eigenschaft oder Methode im Test. Wenn Sie eine Methode angeben, lassen Sie die Klammern nach dem Methodenamen weg.

.INPUTS
Keine. Diese Funktion akzeptiert keine Eingaben aus der Pipeline.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Gibt $true zurück, wenn das Azure-Modul mindestens die Version 0.7.4 besitzt. Andernfalls wird $false zurückgegeben.

.DESCRIPTION
Test-AzureModuleVersion gibt $true zurück, wenn das Azure-Modul mindestens die Version 0.7.4 besitzt. Wenn das Modul nicht installiert ist oder eine niedrigere Versionsnummer besitzt, wird $false zurückgegeben. Diese Funktion hat keine Parameter.

.INPUTS
Keine

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
Gibt $true zurück, wenn mindestens Version 0.7.4 des Azure-Moduls installiert ist.

.DESCRIPTION
Test-AzureModule gibt $true zurück, wenn die installierte Version des Azure-Moduls 0.7.4 oder höher ist. Gibt $false zurück, wenn das Modul nicht installiert oder eine frühere Version installiert ist. Diese Funktion besitzt keine Parameter.

.INPUTS
Keine

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
Speichert das aktuelle Windows Azure-Abonnement in der $Script:originalSubscription-Variablen im Skriptbereich.

.DESCRIPTION
Die Backup-Subscription-Funktion speichert das aktuelle Windows Azure-Abonnement (Get-AzureSubscription -Current) und das zugehörige Speicherkonto sowie das von diesem Skript geänderte Abonnement ($UserSpecifiedSubscription) und das zugehörige Speicherkonto im Skriptbereich. Das Speichern der Werte bietet Ihnen die Möglichkeit, das ursprüngliche aktuelle Abonnement und Speicherkonto mithilfe einer Funktion wie Restore-Subscription mit dem aktuellen Status wiederherzustellen, falls sich der aktuelle Status geändert hat.

.PARAMETER UserSpecifiedSubscription
Dient zum Angeben des Namens des Abonnements, in dem die neuen Ressourcen erstellt und veröffentlicht werden. Die Funktion speichert die Namen des Abonnements und der zugehörigen Speicherkonten in einem Skriptbereich. Dieser Parameter muss angegeben werden.

.INPUTS
Keine

.OUTPUTS
Keine

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Windows Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: Start'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: Ursprüngliches Abonnement: ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: Ende'
}


<#
.SYNOPSIS
Stellt für das Windows Azure-Abonnement, das in der $Script:originalSubscription-Variablen im Skriptbereich gespeichert ist, den aktuellen Status wieder her.

.DESCRIPTION
Die Restore-Subscription-Funktion macht das in der $Script:originalSubscription-Variable gespeicherte Abonnement (erneut) zum aktuellen Abonnement. Falls das ursprüngliche Abonnement über ein Speicherkonto verfügt, macht die Funktion dieses Speicherkonto für das aktuelle Abonnement zum aktuellen Speicherkonto. Die Funktion stellt das Abonnement nur wieder her, wenn in der Umgebung eine $SubscriptionName-Variable vorhanden ist, die nicht NULL ist. Andernfalls wird sie beendet. Wenn die $SubscriptionName-Variable nicht NULL ist, $Script:originalSubscription jedoch $null ist, verwendet Restore-Subscription das Select-AzureSubscription-Cmdlet, um die Einstellungen "Aktuell" und "Standard" für Abonnements in Windows Azure PowerShell zu löschen. Diese Funktion besitzt keine Parameter, akzeptiert keine Eingaben und gibt nichts zurück (leer). Sie können -Verbose verwenden, um Nachrichten an den Verbose-Stream zu schreiben.

.INPUTS
Keine

.OUTPUTS
Keine

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: Start'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: Ende'
}

<#
.SYNOPSIS
Sucht ein Windows Azure-Speicherkonto mit der Bezeichnung "devtest*" im aktuellen Abonnement.

.DESCRIPTION
Die Get-AzureVMStorage-Funktion gibt den Namen des ersten Speicherkontos mit dem Namensmuster "devtest*" (ohne Berücksichtigung der Groß- und Kleinschreibung) am angegebenen Speicherort oder in der angegebenen Affinitätsgruppe zurück. Falls das "devtest*"-Speicherkonto dem Speicherort oder der Affinitätsgruppe nicht entspricht, wird es von der Funktion ignoriert. Sie müssen einen Speicherort oder eine Affinitätsgruppe angeben.

.PARAMETER  Location
Dient zum Angeben des Speicherorts für das Speicherkonto. Gültige Werte sind Windows Azure-Speicherorte wie "USA West". Sie können einen Speicherort oder eine Affinitätsgruppe eingeben, aber nicht beides.

.PARAMETER  AffinityGroup
Dient zum Angeben der Affinitätsgruppe des Speicherkontos. Sie können einen Speicherort oder eine Affinitätsgruppe eingeben, aber nicht beides.

.INPUTS
Keine. An diese Funktion können keine Eingaben weitergeleitet werden.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-AzureVMStorage -Location "East US"
devtest3-fabricam

.EXAMPLE
PS C:\> Get-AzureVMStorage -AffinityGroup Finance
PS C:\>

.EXAMPLE\
PS C:\> Get-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Get-AzureVMStorage: Start
VERBOSE: Get-AzureVMStorage: End

.LINK
Get-AzureStorageAccount
#>
function Get-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Get-AzureVMStorage: Start'

    $storages = @(Get-AzureStorageAccount -ErrorAction SilentlyContinue)
    $storageName = $null

    foreach ($storage in $storages)
    {
        # Rufen Sie das erste Speicherkonto ab, dessen Name mit "devtest" beginnt.
        if ($storage.Label -like 'devtest*')
        {
            if ($storage.AffinityGroup -eq $AffinityGroup -or $storage.Location -eq $Location)
            {
                $storageName = $storage.Label

                    Write-HostWithTime ('Get-AzureVMStorage: devtest-Speicherkonto gefunden ' + $storageName)
                    $storage | Out-String | Write-VerboseWithTime
                break
            }
        }
    }

    Write-VerboseWithTime 'Get-AzureVMStorage: Ende'
    return $storageName
}


<#
.SYNOPSIS
Erstellt ein neues Windows Azure-Speicherkonto mit einem eindeutigen Namen, der mit "devtest" beginnt.

.DESCRIPTION
Die Add-AzureVMStorage-Funktion erstellt ein neues Windows Azure-Speicherkonto im aktuellen Abonnement. Der Name des Kontos beginnt mit "devtest", gefolgt von einer eindeutigen alphanumerischen Zeichenfolge. Die Funktion gibt den Namen des neuen Speicherkontos zurück. Geben Sie entweder einen Speicherort oder eine Affinitätsgruppe für das neue Speicherkonto an.

.PARAMETER  Location
Dient zum Angeben des Speicherorts für das Speicherkonto. Gültige Werte sind Windows Azure-Speicherorte wie "USA West". Sie können einen Speicherort oder eine Affinitätsgruppe eingeben, aber nicht beides.

.PARAMETER  AffinityGroup
Dient zum Angeben der Affinitätsgruppe des Speicherkontos. Sie können einen Speicherort oder eine Affinitätsgruppe eingeben, aber nicht beides.

.INPUTS
Keine. An diese Funktion können keine Eingaben weitergeleitet werden.

.OUTPUTS
System.String. Die Zeichenfolge ist der Name des neuen Speicherkontos.

.EXAMPLE
PS C:\> Add-AzureVMStorage -Location "East Asia"
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Add-AzureVMStorage: Start
VERBOSE: Add-AzureVMStorage: Created new storage acccount devtestd6b45e23a6dd4bdab"
VERBOSE: Add-AzureVMStorage: End
devtestd6b45e23a6dd4bdab

.LINK
New-AzureStorageAccount
#>
function Add-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Add-AzureVMStorage: Start'

    # Erstellen Sie einen eindeutigen Namen, indem Sie einen Teil einer GUID an "devtest" anhängen.
    $name = 'devtest'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0,24 - $name.Length)
    $name = $name + $suffix

    # Neues Windows Azure-Speicherkonto mit Speicherort/Affinitätsgruppe erstellen
    if ($PSCmdlet.ParameterSetName -eq 'Location')
    {
        New-AzureStorageAccount -StorageAccountName $name -Location $Location | Out-Null
    }
    else
    {
        New-AzureStorageAccount -StorageAccountName $name -AffinityGroup $AffinityGroup | Out-Null
    }

    Write-HostWithTime ("Add-AzureVMStorage: Neues Speicherkonto $name erstellt")
    Write-VerboseWithTime 'Add-AzureVMStorage: Ende'
    return $name
}


<#
.SYNOPSIS
Überprüft die Konfigurationsdatei und gibt eine Hash-Tabelle mit Konfigurationsdateiwerten zurück.

.DESCRIPTION
Die Read-ConfigFile-Funktion prüft die JSON-Konfigurationsdatei und gibt eine Hash-Tabelle mit ausgewählten Werten zurück.
-- Der Vorgang beginnt mit der Konvertierung der JSON-Datei in ein PSCustomObject.
-- Sie stellt sicher, dass die environmentSettings-Eigenschaft entweder eine Website- oder eine Cloud-Dienst-Eigenschaft enthält, aber nicht beides.
-- Erstellt einen von zwei Hash-Tabellentypen (einen für eine Website, einen für einen Cloud-Dienst) und gibt ihn zurück. Die Hash-Tabelle für eine Website verfügt über folgende Schlüssel:
-- IsAzureWebSite: $True. Die Config-Datei ist für eine Website vorgesehen. 
-- Name: Name der Website
-- Location: Speicherort der Website
-- Databases: SQL-Datenbanken der Website
Die Hash-Tabelle des Cloud-Diensts verfügt über folgende Schlüssel:
-- IsAzureWebSite: $False. Die Config-Datei ist nicht für eine Website vorgesehen.
-- webdeployparameters : Optional. Ist möglicherweise $null oder leer.
-- Databases: SQL-Datenbanken

.PARAMETER  ConfigurationFile
Dient zum Angeben von Pfad und Name der JSON-Konfigurationsdatei für Ihr Webprojekt. Visual Studio generiert die JSON-Datei automatisch, wenn Sie ein Webprojekt erstellen, und speichert sie im PublishScripts-Ordner Ihrer Lösung.

.PARAMETER HasWebDeployPackage
Indicates that there is a web deploy package ZIP file for the web application. To specify a value of $true, use -HasWebDeployPackage or HasWebDeployPackage:$true. To specify a value of false, use HasWebDeployPackage:$false.This parameter is required.

.INPUTS
Keine. An diese Funktion können keine Eingaben weitergeleitet werden.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
cloudService                   @{name=asdfhl; affinityGroup=stephwe1ag1cus; location=; virtualNetwork=; subnet=; availabilitySet=; virtualMachine=}                                                      
IsWAWS                         False                                                                                                                                                                     
webDeployParameters            @{iisWebApplicationName=Default Web Site} 
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [Switch]
        $HasWebDeployPackage	    
    )

    Write-VerboseWithTime 'Read-ConfigFile: Start'

    # Inhalte der JSON-Datei (-raw: Zeilenumbrüche ignorieren) abrufen und in PSCustomObject konvertieren
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: Fehler bei ConvertFrom-Json: ' + $error[0])
    }

    # Bestimmen, ob das environmentSettings-Objekt über webSite- oder cloudService-Eigenschaften verfügt (ungeachtet des Eigenschaftswerts)
    $hasWebsiteProperty =  Test-Member -Object $config.environmentSettings -Member 'webSite'
    $hasCloudServiceProperty = Test-Member -Object $config.environmentSettings -Member 'cloudService'

    if (!$hasWebsiteProperty -and !$hasCloudServiceProperty)
    {
        throw 'Read-ConfigFile: Falsch formatierte Konfigurationsdatei. Enthält weder webSite noch cloudService.'
    }
    elseif ($hasWebsiteProperty -and $hasCloudServiceProperty)
    {
        throw 'Read-ConfigFile: Falsch formatierte Konfigurationsdatei. Enthält sowohl webSite als auch cloudService.'
    }

    # Hash-Tabelle aus den Werten im PSCustomObject erstellen
    $returnObject = New-Object -TypeName Hashtable
    $returnObject.Add('IsAzureWebSite', $hasWebsiteProperty)

    if ($hasWebsiteProperty)
    {
        $returnObject.Add('name', $config.environmentSettings.webSite.name)
        $returnObject.Add('location', $config.environmentSettings.webSite.location)
    }
    else
    {
        $returnObject.Add('cloudService', $config.environmentSettings.cloudService)
        if ($HasWebDeployPackage)
        {
            $returnObject.Add('webDeployParameters', $config.environmentSettings.webdeployParameters)
        }
    }

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: Ende'

    return $returnObject
}

<#
.SYNOPSIS
Fügt einem virtuellen Computer neue Eingabeendpunkte hinzu und gibt den virtuellen Computer mit dem neuen Endpunkt zurück.

.DESCRIPTION
Die Add-AzureVMEndpoints-Funktion fügt einem virtuellen Computer neue Eingabeendpunkte hinzu und gibt den virtuellen Computer mit den neuen Endpunkten zurück. Diese Funktion ruft das Add-AzureEndpoint-Cmdlet (Azure-Modul) auf.

.PARAMETER  VM
Dient zum Angeben des virtuellen Computerobjekts. Geben Sie ein VM-Objekt an, wie etwa den Typ, den das New-AzureVM- oder das Get-AzureVM-Cmdlet zurückgibt. Sie können Objekte von Get-AzureVM an Add-AzureVMEndpoints weiterleiten.

.PARAMETER  Endpoints
Dient zum Angeben eines Arrays von Endpunkten, die dem virtuellen Computer hinzugefügt werden sollen. In der Regel stammen diese Endpunkte aus der JSON-Konfigurationsdatei, die Visual Studio für Webprojekte generiert. Verwenden Sie die Read-ConfigFile-Funktion in diesem Modul, um die Datei in eine Hash-Tabelle zu konvertieren. Die Endpunkte sind eine Eigenschaft des cloudservice-Schlüssels der Hash-Tabelle ($<hashtable>.cloudservice.virtualmachine.endpoints). Beispiel:
PS C:\> $config.cloudservice.virtualmachine.endpoints
name      protocol publicport privateport
----      -------- ---------- -----------
http      tcp      80         80
https     tcp      443        443
WebDeploy tcp      8172       8172

.INPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.OUTPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.EXAMPLE
Get-AzureVM

.EXAMPLE

.LINK
Get-AzureVM

.LINK
Add-AzureEndpoint
#>
function Add-AzureVMEndpoints
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM]
        $VM,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Endpoints
    )

    Write-VerboseWithTime 'Add-AzureVMEndpoints: Start'

    # Jeden Endpunkt aus der JSON-Datei dem VM hinzufügen
    $Endpoints | ForEach-Object `
    {
        $_ | Out-String | Write-VerboseWithTime
        Add-AzureEndpoint -VM $VM -Name $_.name -Protocol $_.protocol -LocalPort $_.privateport -PublicPort $_.publicport | Out-Null
    }

    Write-VerboseWithTime 'Add-AzureVMEndpoints: Ende'
    return $VM
}

<#
.SYNOPSIS
Erstellt alle Elemente eines neuen virtuellen Computers in einem Windows Azure-Abonnement.

.DESCRIPTION
Diese Funktion erstellt einen virtuellen Windows Azure-Computer (VM) und gibt die URL des bereitgestellten VM zurück. Die Funktion richtet die erforderlichen Komponenten ein und ruft dann das New-AzureVM-Cmdlet (Azure-Modul) auf, um einen neuen VM zu erstellen. 
- Sie ruft das New-AzureVMConfig-Cmdlet (Azure-Modul) auf, um ein Konfigurationsobjekt für den virtuellen Computer abzurufen. 
- Falls Sie den Parameter "Subnet" angeben, um den VM einem Azure-Subnetz hinzuzufügen, wird "Set-AzureSubnet" aufgerufen, um die Subnetzliste für den VM festzulegen. 
- Sie ruft "Add-AzureProvisioningConfig" (Azure-Modul) auf, um Elemente zur Konfiguration des virtuellen Computers hinzuzufügen. Sie erstellt eine eigenständige Windows-Bereitstellungskonfiguration (-Windows) mit Administratorkonto und Kennwort.
- Sie ruft die Add-AzureVMEndpoints-Funktion in diesem Modul auf, um die durch den Endpoints-Parameter angegebenen Endpunkte hinzuzufügen. Diese Funktion verwendet ein VM-Objekt und gibt ein VM-Objekt mit den hinzugefügten Endpunkten zurück. 
- Sie ruft das Add-AzureVM-Cmdlet auf, um einen neuen virtuellen Windows Azure-Computer zu erstellen, und gibt den neuen virtuellen Computer zurück. Die Werte der Funktionsparameter werden in der Regel aus der JSON-Konfigurationsdatei übernommen, die Visual Studio für in Windows Azure integrierte Webprojekte generiert. Die Read-ConfigFile-Funktion in diesem Modul konvertiert die JSON-Datei in eine Hash-Tabelle, speichert den cloudservice-Schlüssel der Hash-Tabelle in einer Variablen (als PSCustomObject) und verwendet die Eigenschaften des benutzerdefinierten Objekts als Parameterwerte.

.PARAMETER  UserName
Dient zum Angeben eines Administratorbenutzernamens. Dieser wird als Wert des AdminUserName-Parameters von Add-AzureProvisioningConfig übermittelt. Dieser Parameter muss angegeben werden.

.PARAMETER  UserPassword
Dient zum Angeben eines Kennworts für das Administratorbenutzerkonto. Das Kennwort wird als Wert des Password-Parameters von Add-AzureProvisioningConfig übermittelt. Dieser Parameter muss angegeben werden.

.PARAMETER  VMName
Dient zum Angeben eines Namens für den neuen virtuellen Computer. Der Name des virtuellen Computers muss innerhalb des Cloud-Diensts eindeutig sein. Dieser Parameter muss angegeben werden.

.PARAMETER  VMSize
Dient zum Angeben der VM-Größe. Gültige Werte sind "Sehr klein", "Klein", "Mittel", "Groß", "Sehr groß", "A5", "A6" und "A7". Dieser Wert wird als Wert des InstanceSize-Parameters von "New-AzureVMConfig" übermittelt. Dieser Parameter muss angegeben werden. 

.PARAMETER  ServiceName
Dient zum Angeben eines vorhandenen Windows Azure-Diensts oder eines Namens für einen neuen Windows Azure-Dienst. Dieser Wert wird an den ServiceName-Parameter des New-AzureVM-Cmdlets übermittelt, das den neuen virtuellen Computer einem vorhandenen Windows Azure-Dienst hinzufügt oder, falls Speicherort oder Affinitätsgruppe angegeben ist, einen neuen virtuellen Computer und Dienst im aktuellen Abonnement erstellt. Dieser Parameter muss angegeben werden. 

.PARAMETER  ImageName
Dient zum Angeben des Namens des virtuellen Computerimage, das für den Betriebssystemdatenträger verwendet werden soll. Dieser Parameter wird als Wert des ImageName-Parameters des New-AzureVMConfig-Cmdlets übermittelt und muss angegeben werden. 

.PARAMETER  Endpoints
Dient zum Angeben eines Arrays von Endpunkten, die dem virtuellen Computer hinzugefügt werden sollen. Dieser Wert wird an die Add-AzureVMEndpoints-Funktion übermittelt, die dieses Modul exportiert. Dieser Parameter ist optional. In der Regel stammen diese Endpunkte aus der JSON-Konfigurationsdatei, die Visual Studio für Webprojekte generiert. Verwenden Sie die Read-ConfigFile-Funktion in diesem Modul, um die Datei in eine Hash-Tabelle zu konvertieren. Die Endpunkte sind eine Eigenschaft des cloudService-Schlüssels der Hash-Tabelle ($<hashtable>.cloudservice.virtualmachine.endpoints). 

.PARAMETER  AvailabilitySetName
Dient zum Angeben des Namens eines Verfügbarkeitssatzes für den neuen virtuellen Computer. Wenn Sie mehrere virtuelle Computer in einem Verfügbarkeitssatz platzieren, versucht Windows Azure, separate Hosts für die virtuellen Computer zu verwenden, um die Dienstkontinuität im Falle eines Ausfalls zu verbessern. Dieser Parameter ist optional. 

.PARAMETER  VNetName
Dient zum Angeben des Namens des virtuellen Netzwerks, in dem der neue virtuelle Computer bereitgestellt wird. Dieser Wert wird an den VNetName-Parameter des Add-AzureVM-Cmdlets übermittelt. Dieser Parameter ist optional. 

.PARAMETER  Location
Dient zum Angeben eines Speicherorts für den neuen virtuellen Computer. Gültige Werte sind Windows Azure-Speicherorte wie "USA West". Standardmäßig wird der Speicherort des Abonnements verwendet. Dieser Parameter ist optional. 

.PARAMETER  AffinityGroup
Dient zum Angeben einer Affinitätsgruppe für den neuen virtuellen Computer. Eine Affinitätsgruppe ist eine Gruppe verknüpfter Ressourcen. Bei Angabe einer Affinitätsgruppe versucht Windows Azure, die Ressourcen in der Gruppe zusammenzuhalten, um die Effizienz zu verbessern. 

.PARAMETER EnableWebDeployExtension
Bereitet den VM für die Bereitstellung vor. Dieser Parameter ist optional. Ohne Angabe dieses Parameters wird der VM zwar erstellt, aber nicht bereitgestellt. Der Wert dieses Parameters ist in der JSON-Konfigurationsdatei enthalten, die Visual Studio für Cloud-Dienste generiert.

.PARAMETER  Subnet
Dient zum Angeben des Subnetzes der neuen VM-Konfiguration. Dieser Wert wird an das Set-AzureSubnet-Cmdlet (Azure-Modul) übermittelt, das einen virtuellen Computer und ein Array von Subnetznamen verwendet und einen virtuellen Computer mit den Subnetzen in der Konfiguration zurückgibt.

.INPUTS
Keine. Diese Funktion akzeptiert keine Eingaben aus der Pipeline.

.OUTPUTS
System.Url

.EXAMPLE
 Mit diesem Befehl wird die Add-AzureVM-Funktion aufgerufen. Viele der Parameterwerte stammen aus einem $CloudServiceConfiguration-Objekt. Dieses PSCustomObject besteht aus cloudservice-Schlüssel und Werten der Hash-Tabelle, die die Read-ConfigFile-Funktion zurückgibt. Die Quelle ist die JSON-Konfigurationsdatei, die Visual Studio für Webprojekte generiert.

PS C:\> $config = Read-Configfile <name>.json
PS C:\> $CloudServiceConfiguration = config.cloudservice

PS C:\> Add-AzureVM `
-UserName $userName `
-UserPassword  $userPassword `
-ImageName $CloudServiceConfiguration.virtualmachine.vhdImage `
-VMName $CloudServiceConfiguration.virtualmachine.name `
-VMSize $CloudServiceConfiguration.virtualmachine.size`
-Endpoints $CloudServiceConfiguration.virtualmachine.endpoints `
-ServiceName $serviceName `
-Location $CloudServiceConfiguration.location `
-AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
-VNetName $CloudServiceConfiguration.virtualNetwork `
-Subnet $CloudServiceConfiguration.subnet `
-AffinityGroup $CloudServiceConfiguration.affinityGroup `
-EnableWebDeployExtension

http://contoso.cloudapp.net

.EXAMPLE
PS C:\> $endpoints = [PSCustomObject]@{name="http";protocol="tcp";publicport=80;privateport=80}, `
                        [PSCustomObject]@{name="https";protocol="tcp";publicport=443;privateport=443},`
                        [PSCustomObject]@{name="WebDeploy";protocol="tcp";publicport=8172;privateport=8172}
PS C:\> Add-AzureVM `
-UserName admin01 `
-UserPassword "pa$$word" `
-ImageName bd507d3a70934695bc2128e3e5a255ba__RightImage-Windows-2012-x64-v13.4.12.2 `
-VMName DevTestVM123 `
-VMSize Small `
-Endpoints $endpoints `
-ServiceName DevTestVM1234 `
-Location "West US"

.LINK
New-AzureVMConfig

.LINK
Set-AzureSubnet

.LINK
Add-AzureProvisioningConfig

.LINK
Get-AzureDeployment
#>
function Add-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMSize,

        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $ImageName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Object[]]
        $Endpoints,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AvailabilitySetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $VNetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Location,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AffinityGroup,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Subnet,

        [Parameter(Mandatory = $false)]
        [Switch]
        $EnableWebDeployExtension
    )

    Write-VerboseWithTime 'Add-AzureVM: Start'

    # Erstellen Sie ein neues Windows Azure VM-Konfigurationsobjekt.
    if ($AvailabilitySetName)
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName -AvailabilitySetName $AvailabilitySetName
    }
    else
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName
    }

    if (!$vm)
    {
        throw 'Add-AzureVM: Fehler beim Erstellen der Azure VM-Konfiguration.'
    }

    if ($Subnet)
    {
        # Legen Sie die Subnetzliste für die Konfiguration eines virtuellen Computers fest.
        $subnetResult = Set-AzureSubnet -VM $vm -SubnetNames $Subnet

        if (!$subnetResult)
        {
            throw ('Add-AzureVM: Fehler beim Festlegen des Subnetzes. ' + $Subnet)
        }
    }

    # Konfigurationsdaten zur VM-Konfiguration hinzufügen
    $VMWithConfig = Add-AzureProvisioningConfig -VM $vm -Windows -Password $UserPassword -AdminUserName $UserName

    if (!$VMWithConfig)
    {
        throw ('Add-AzureVM: Fehler beim Erstellen der Bereitstellungskonfiguration.')
    }

    # Eingabeendpunkte zum VM hinzufügen
    if ($Endpoints -and $Endpoints.Count -gt 0)
    {
        $VMWithConfig = Add-AzureVMEndpoints -Endpoints $Endpoints -VM $VMWithConfig
    }

    if (!$VMWithConfig)
    {
        throw ('Add-AzureVM: Fehler beim Erstellen der Endpunkte.')
    }

    if ($EnableWebDeployExtension)
    {
        Write-VerboseWithTime 'Add-AzureVM: webdeploy-Erweiterung hinzufügen'

        Write-VerboseWithTime 'Die Lizenz für Web Deploy finden Sie unter "http://go.microsoft.com/fwlink/?LinkID=389744". '

        $VMWithConfig = Set-AzureVMExtension `
            -VM $VMWithConfig `
            -ExtensionName WebDeployForVSDevTest `
            -Publisher 'Microsoft.VisualStudio.WindowsAzure.DevTest' `
            -Version '1.*' 

        if (!$VMWithConfig)
        {
            throw ('Add-AzureVM: Fehler beim Hinzufügen der webdeploy-Erweiterung.')
        }
    }

    # Hash-Tabelle mit Parametern zur Verteilung erstellen
    $param = New-Object -TypeName Hashtable
    if ($VNetName)
    {
        $param.Add('VNetName', $VNetName)
    }

    if ($Location)
    {
        $param.Add('Location', $Location)
    }

    if ($AffinityGroup)
    {
        $param.Add('AffinityGroup', $AffinityGroup)
    }

    $param.Add('ServiceName', $ServiceName)
    $param.Add('VMs', $VMWithConfig)
    $param.Add('WaitForBoot', $true)

    $param | Out-String | Write-VerboseWithTime

    New-AzureVM @param | Out-Null

    Write-HostWithTime ('Add-AzureVM: Der virtuelle Computer wurde erstellt. ' + $VMName)

    $url = [System.Uri](Get-AzureDeployment -ServiceName $ServiceName).Url

    if (!$url)
    {
        throw 'Add-AzureVM: Die VM-URL wurde nicht gefunden.'
    }

    Write-HostWithTime ('Add-AzureVM: Veröffentlichungs-URL: https://' + $url.Host + ':' + $WebDeployPort + '/msdeploy.axd')

    Write-VerboseWithTime 'Add-AzureVM: Ende'

    return $url.AbsoluteUri
}


<#
.SYNOPSIS
Ruft den angegebenen virtuellen Windows Azure-Computer ab.

.DESCRIPTION
Die Find-AzureVM-Funktion ruft einen virtuellen Windows Azure-Computer (VM) auf der Grundlage des Dienstnamens und des Namens des virtuellen Computers ab. Diese Funktion ruft das Test-AzureName-Cmdlet (Azure-Modul) auf, um zu prüfen, ob der Dienstname in Windows Azure vorhanden ist. Ist dies der Fall, ruft die Funktion das Get-AzureVM-Cmdlet auf, um den virtuellen Computer abzurufen. Diese Funktion gibt eine Hash-Tabelle mit vm- und foundService-Schlüsseln zurück.
-- FoundService: $True, falls der Dienst von "Test-AzureName" gefunden wurde. Andernfalls $False.
-- VM: Enthält das VM-Objekt, wenn "FoundService = true" ist und Get-AzureVM das VM-Objekt zurückgibt.

.PARAMETER  ServiceName
Der Name eines vorhandenen Windows Azure-Diensts. Dieser Parameter muss angegeben werden.

.PARAMETER  VMName
Der Name eines virtuellen Computers im Dienst. Dieser Parameter muss angegeben werden.

.INPUTS
Keine. An diese Funktion können keine Eingaben weitergeleitet werden.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Find-AzureVM -Service Contoso -Name ContosoVM2

Name                           Value
----                           -----
foundService                   True

DeploymentName        : Contoso
Name                  : ContosoVM2
Label                 :
VM                    : Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM
InstanceStatus        : ReadyRole
IpAddress             : 100.71.114.118
InstanceStateDetails  :
PowerState            : Started
InstanceErrorCode     :
InstanceFaultDomain   : 0
InstanceName          : ContosoVM2
InstanceUpgradeDomain : 0
InstanceSize          : Small
AvailabilitySetName   :
DNSName               : http://contoso.cloudapp.net/
ServiceName           : Contoso
OperationDescription  : Get-AzureVM
OperationId           : 3c38e933-9464-6876-aaaa-734990a882d6
OperationStatus       : Succeeded

.LINK
Get-AzureVM
#>
function Find-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    )

    Write-VerboseWithTime 'Find-AzureVM: Start'
    $foundService = $false
    $vm = $null

    if (Test-AzureName -Service -Name $ServiceName)
    {
        $foundService = $true
        $vm = Get-AzureVM -ServiceName $ServiceName -Name $VMName
        if ($vm)
        {
            Write-HostWithTime ('Find-AzureVM: Es wurde ein vorhandener virtueller Computer gefunden. ' + $vm.Name )
            $vm | Out-String | Write-VerboseWithTime
        }
    }

    Write-VerboseWithTime 'Find-AzureVM: Ende'
    return @{ VM = $vm; FoundService = $foundService }
}


<#
.SYNOPSIS
Sucht oder erstellt einen virtuellen Computer im Abonnement, der den Werten in der JSON-Konfigurationsdatei entspricht.

.DESCRIPTION
Die New-AzureVMEnvironment-Funktion sucht oder erstellt einen virtuellen Computer im Abonnement, der den Werten in der JSON-Konfigurationsdatei entspricht. die Visual Studio für Webprojekte generiert. Sie verwendet ein PSCustomObject, das der cloudservice-Schlüssel der Hash-Tabelle ist, die Read-ConfigFile zurück gibt. Diese Daten stammen aus der von Visual Studio generierten JSON-Konfigurationsdatei. Die Funktion sucht nach einem virtuellen Computer im Abonnement mit einem Dienstnamen und einem virtuellen Computernamen, der den Werten im benutzerdefinierten CloudServiceConfiguration-Objekt entspricht. Wird kein entsprechender virtueller Computer gefunden, ruft sie die Add-AzureVM-Funktion in diesem Modul auf und verwendet die Werte im CloudServiceConfiguration-Objekt, um einen virtuellen Computer zu erstellen. Die Umgebung des virtuellen Computers enthält ein Speicherkonto, das einen mit "devtest" beginnenden Namen besitzt. Sollte kein Speicherkonto mit diesem Namensmuster im Abonnement gefunden werden, wird eines erstellt. Die Funktion gibt eine Hash-Tabelle mit VM-URL, Benutzername, Kennwortschlüsseln und Zeichenfolgenwerten zurück.

.PARAMETER  CloudServiceConfiguration
Verwendet ein PSCustomObject, das die cloudservice-Eigenschaft der Hash-Tabelle enthält, die die Read-ConfigFile-Funktion zurückgibt. Alle Werte stammen aus der JSON-Konfigurationsdatei, die Visual Studio für Webprojekte generiert. Sie finden diese Datei im PublishScripts-Ordner in Ihrer Lösung. Dieser Parameter muss angegeben werden.
$config = Read-ConfigFile -ConfigurationFile <file>.json $cloudServiceConfiguration = $config.cloudService

.PARAMETER  VMPassword
Akzeptiert eine Hash-Tabelle mit Namens- und Kennwortschlüssel. Beispiel: @{Name = "admin"; Password = "pa$$word"}. Dieser Parameter ist optional. Ohne Angabe dieses Parameters werden standardmäßig der Benutzername und das Kennwort für den virtuellen Computer aus der JSON-Konfigurationsdatei verwendet.

.INPUTS
PSCustomObject  System.Collections.Hashtable

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
$config = Read-ConfigFile -ConfigurationFile $<file>.json
$cloudSvcConfig = $config.cloudService
$namehash = @{name = "admin"; password = "pa$$word"}

New-AzureVMEnvironment `
    -CloudServiceConfiguration $cloudSvcConfig `
    -VMPassword $namehash

Name                           Value
----                           -----
UserName                       admin
VMUrl                          contoso.cloudnet.net
Password                       pa$$word

.LINK
Add-AzureVM

.LINK
New-AzureStorageAccount
#>
function New-AzureVMEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $CloudServiceConfiguration,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword
    )

    Write-VerboseWithTime ('New-AzureVMEnvironment: Start')

    if ($CloudServiceConfiguration.location -and $CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: Falsch formatierte Konfigurationsdatei. Enthält sowohl location als auch affinityGroup.'
    }

    if (!$CloudServiceConfiguration.location -and !$CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: Falsch formatierte Konfigurationsdatei. Enthält weder location noch affinityGroup.'
    }

    # Falls das CloudServiceConfiguration-Objekt über die Eigenschaft "name" (für den Dienstnamen) verfügt und die Eigenschaft "name" einen Wert besitzt, verwenden Sie diesen. Verwenden Sie andernfalls den (stets angegebenen) Namen des virtuellen Computers im CloudServiceConfiguration-Objekt.
    if ((Test-Member $CloudServiceConfiguration 'name') -and $CloudServiceConfiguration.name)
    {
        $serviceName = $CloudServiceConfiguration.name
    }
    else
    {
        $serviceName = $CloudServiceConfiguration.virtualMachine.name
    }

    if (!$VMPassword)
    {
        $userName = $CloudServiceConfiguration.virtualMachine.user
        $userPassword = $CloudServiceConfiguration.virtualMachine.password
    }
    else
    {
        $userName = $VMPassword.Name
        $userPassword = $VMPassword.Password
    }

    # VM-Name aus der JSON-Datei abrufen
    $findAzureVMResult = Find-AzureVM -ServiceName $serviceName -VMName $CloudServiceConfiguration.virtualMachine.name

    # Falls wir keinen VM mit diesem Namen in diesem Cloud-Dienst finden, erstellen Sie einen.
    if (!$findAzureVMResult.VM)
    {
        $storageAccountName = $null
        $imageInfo = Get-AzureVMImage -ImageName $CloudServiceConfiguration.virtualmachine.vhdimage 
        if ($imageInfo -and $imageInfo.Category -eq 'User')
        {
            $storageAccountName = ($imageInfo.MediaLink.Host -split '\.')[0]
        }

        if (!$storageAccountName)
        {
            if ($CloudServiceConfiguration.location)
            {
                $storageAccountName = Get-AzureVMStorage -Location $CloudServiceConfiguration.location
            }
            else
            {
                $storageAccountName = Get-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
            }
        }

        #If there's no devtest* storage account, create one.
        if (!$storageAccountName)
        {
            if ($CloudServiceConfiguration.location)
            {
                $storageAccountName = Add-AzureVMStorage -Location $CloudServiceConfiguration.location
            }
            else
            {
                $storageAccountName = Add-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
            }
        }

        $currentSubscription = Get-AzureSubscription -Current

        if (!$currentSubscription)
        {
            throw 'New-AzureVMEnvironment: Fehler beim Abrufen des aktuellen Azure-Abonnements.'
        }

        # Speicherkonto "devtest*" als aktuell festlegen
        Set-AzureSubscription `
            -SubscriptionName $currentSubscription.SubscriptionName `
            -CurrentStorageAccountName $storageAccountName

        Write-VerboseWithTime ('New-AzureVMEnvironment: Speicherkonto ist festgelegt auf ' + $storageAccountName)

        $location = ''            
        if (!$findAzureVMResult.FoundService)
        {
            $location = $CloudServiceConfiguration.location
        }

        $endpoints = $null
        if (Test-Member -Object $CloudServiceConfiguration.virtualmachine -Member 'Endpoints')
        {
            $endpoints = $CloudServiceConfiguration.virtualmachine.endpoints
        }

        # VM mit den Werten aus der JSON-Datei und Parameterwerten erstellen
        $VMUrl = Add-AzureVM `
            -UserName $userName `
            -UserPassword $userPassword `
            -ImageName $CloudServiceConfiguration.virtualMachine.vhdImage `
            -VMName $CloudServiceConfiguration.virtualMachine.name `
            -VMSize $CloudServiceConfiguration.virtualMachine.size`
            -Endpoints $endpoints `
            -ServiceName $serviceName `
            -Location $location `
            -AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
            -VNetName $CloudServiceConfiguration.virtualNetwork `
            -Subnet $CloudServiceConfiguration.subnet `
            -AffinityGroup $CloudServiceConfiguration.affinityGroup `
            -EnableWebDeployExtension:$CloudServiceConfiguration.virtualMachine.enableWebDeployExtension

        Write-VerboseWithTime ('New-AzureVMEnvironment: Ende')

        return @{ 
            VMUrl = $VMUrl; 
            UserName = $userName; 
            Password = $userPassword; 
            IsNewCreatedVM = $true; }
    }
    else
    {
        Write-VerboseWithTime ('New-AzureVMEnvironment: Ein vorhandener virtueller Computer wurde gefunden. ' + $findAzureVMResult.VM.Name)
    }

    Write-VerboseWithTime ('New-AzureVMEnvironment: Ende')

    return @{ 
        VMUrl = $findAzureVMResult.VM.DNSName; 
        UserName = $userName; 
        Password = $userPassword; 
        IsNewCreatedVM = $false; }
}


<#
.SYNOPSIS
Gibt einen Befehl zum Ausführen des MsDeploy.exe-Tools zurück.

.DESCRIPTION
Die Get-MSDeployCmd-Funktion erstellt einen gültigen Befehl zum Ausführen des Web Deploy-Tools "MSDeploy.exe" und gibt ihn zurück. Sie sucht den korrekten Pfad zum Tool auf dem lokalen Computer in einem Registrierungsschlüssel. Diese Funktion hat keine Parameter.

.INPUTS
Keine

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-MSDeployCmd
C:\Program Files\IIS\Microsoft Web Deploy V3\MsDeploy.exe

.LINK
Get-MSDeployCmd

.LINK
Web Deploy Tool
http://technet.microsoft.com/en-us/library/dd568996(v=ws.10).aspx
#>
function Get-MSDeployCmd
{
    Write-VerboseWithTime 'Get-MSDeployCmd: Start'
    $regKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy'

    if (!(Test-Path $regKey))
    {
        throw ('Get-MSDeployCmd: Nicht gefunden. ' + $regKey)
    }

    $versions = @(Get-ChildItem $regKey -ErrorAction SilentlyContinue)
    $lastestVersion =  $versions | Sort-Object -Property Name -Descending | Select-Object -First 1

    if ($lastestVersion)
    {
        $installPathKeys = 'InstallPath','InstallPath_x86'

        foreach ($installPathKey in $installPathKeys)
        {		    	
            $installPath = $lastestVersion.GetValue($installPathKey)

            if ($installPath)
            {
                $installPath = Join-Path $installPath -ChildPath 'MsDeploy.exe'

                if (Test-Path $installPath -PathType Leaf)
                {
                    $msdeployPath = $installPath
                    break
                }
            }
        }
    }

    Write-VerboseWithTime 'Get-MSDeployCmd: Ende'
    return $msdeployPath
}


<#
.SYNOPSIS
Erstellt eine Windows Azure-Website.

.DESCRIPTION
Erstellt eine Windows Azure-Website mit dem spezifischen Namen und Speicherort. Diese Funktion ruft das New-AzureWebsite-Cmdlet im Azure-Modul auf. Falls das Abonnement noch keine Website mit dem angegebenen Namen besitzt, erstellt diese Funktion die Website und gibt ein Websiteobjekt zurück. Andernfalls wird $null zurückgegeben.

.PARAMETER  Name
Dient zum Angeben eines Namens für die neue Website. Der Name muss in Windows Azure eindeutig sein. Dieser Parameter muss angegeben werden.

.PARAMETER  Location
Dient zum Angeben des Speicherorts der Website. Gültige Werte sind Windows Azure-Speicherorte wie "USA West". Dieser Parameter muss angegeben werden.

.INPUTS
KEINE.

.OUTPUTS
Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.Site

.EXAMPLE
Add-AzureWebsite -Name TestSite -Location "West US"

Name       : contoso
State      : Running
Host Names : contoso.azurewebsites.net

.LINK
New-AzureWebsite
#>
function Add-AzureWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )

    Write-VerboseWithTime 'Add-AzureWebsite: Start'
    $website = Get-AzureWebsite -Name $Name -ErrorAction SilentlyContinue

    if ($website)
    {
        Write-HostWithTime ('Add-AzureWebsite: Eine vorhandene Website ' +
        $website.Name + ' wurde gefunden')
    }
    else
    {
        if (Test-AzureName -Website -Name $Name)
        {
            Write-ErrorWithTime ('Die Website "{0}" ist bereits vorhanden.' -f $Name)
        }
        else
        {
            $website = New-AzureWebsite -Name $Name -Location $Location
        }
    }

    $website | Out-String | Write-VerboseWithTime
    Write-VerboseWithTime 'Add-AzureWebsite: Ende'

    return $website
}

<#
.SYNOPSIS
Gibt $True zurück, wenn die URL absolut ist und das Schema "https" lautet.

.DESCRIPTION
Die Test-HttpsUrl-Funktion konvertiert die eingegebene URL in ein System.Uri-Objekt. Gibt $True zurück, wenn die URL absolut (nicht relativ) ist und das Schema "https" lautet. Wenn eine der Bedingungen nicht erfüllt ist oder die eingegebene Zeichenfolge nicht in eine URL konvertiert werden kann, wird $false zurückgegeben.

.PARAMETER Url
Dient zum Angeben der zu testenden URL. Geben Sie eine URL-Zeichenfolge ein.

.INPUTS
KEINE.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # Falls "$uri" nicht in ein System.Uri-Objekt konvertiert werden kann, wird von Test-HttpsUrl "$false" zurückgegeben.
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Stellt ein Webpaket in Windows Azure bereit.

.DESCRIPTION
Die Publish-WebPackage-Funktion verwendet "MsDeploy.exe" und ein Webbereitstellungspaket (ZIP-Datei), um Ressourcen für eine Windows Azure-Website bereitzustellen. Diese Funktion generiert keine Ausgabe. Im Falle eines Fehlers beim Aufrufen von "MSDeploy.exe" tritt ein Ausnahmefehler auf. Eine ausführlichere Ausgabe erhalten Sie mithilfe des allgemeinen Verbose-Parameters.

.PARAMETER  WebDeployPackage
Dient zum Angeben des Pfads und Dateinamens eines von Visual Studio generierten Webbereitstellungspakets (ZIP-Datei). Dieser Parameter muss angegeben werden. Informationen zum Erstellen eines Webbereitstellungspakets (ZIP-Datei) finden Sie in "Gewusst wie: Erstellen eines Webbereitstellungspakets in Visual Studio" auf "http://go.microsoft.com/fwlink/?LinkId=391353".

.PARAMETER PublishUrl
Dient zum Angeben der URL, unter der die Ressourcen bereitgestellt werden. Die URL muss das HTTPS-Protokoll verwenden und den Port enthalten. Dieser Parameter muss angegeben werden.

.PARAMETER SiteName
Dient zum Angeben eines Namens für die Website. Dieser Parameter muss angegeben werden.

.PARAMETER Username
Dient zum Angeben des Benutzernamens des Websiteadministrators. Dieser Parameter muss angegeben werden.

.PARAMETER Password
Dient zum Angeben eines Kennworts für den Websiteadministrator. Geben Sie ein Kennwort im Nur-Text-Format ein. Sichere Zeichenfolgen sind nicht zulässig. Dieser Parameter muss angegeben werden.

.PARAMETER AllowUntrusted
Lässt nicht vertrauenswürdige SSL-Verbindungen mit der Website zu. Dieser Parameter wird beim Aufrufen von "MSDeploy.exe" verwendet und muss angegeben werden.

.PARAMETER ConnectionString
Dient zum Angeben einer Verbindungszeichenfolge für eine SQL-Datenbank. Dieser Parameter akzeptiert eine Hash-Tabelle mit Name- und ConnectionString-Schlüssel. Der Name-Wert ist der Name der Datenbank. Der ConnectionString-Wert ist der connectionStringName-Wert aus der JSON-Konfigurationsdatei.

.INPUTS
Keine. Diese Funktion akzeptiert keine Eingaben aus der Pipeline.

.OUTPUTS
Keine

.EXAMPLE
Publish-WebPackage -WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
    -PublishUrl $publishUrl "https://contoso.cloudnet.net:8172/msdeploy.axd" `
    -SiteName 'Contoso-Testwebsite' `
    -UserName $UserName admin01 `
    -Password $UserPassword pa$$word `
    -AllowUntrusted:$False `
    -ConnectionString @{Name='TestDB';ConnectionString='DefaultConnection'}

.LINK
Publish-WebPackageToVM

.LINK
Web Deploy Command Line Reference (MSDeploy.exe)
http://go.microsoft.com/fwlink/?LinkId=391354
#>
function Publish-WebPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-HttpsUrl $_ })]
        [String]
        $PublishUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password,

        [Parameter(Mandatory = $false)]
        [Switch]
        $AllowUntrusted = $false,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )

    Write-VerboseWithTime 'Publish-WebPackage: Start'

    $msdeployCmd = Get-MSDeployCmd

    if (!$msdeployCmd)
    {
        throw 'Publish-WebPackage: "MsDeploy.exe" wurde nicht gefunden.'
    }

    $WebDeployPackage = (Get-Item $WebDeployPackage).FullName

    $msdeployCmd =  '"' + $msdeployCmd + '"'
    $msdeployCmd += ' -verb:sync'
    $msdeployCmd += ' -Source:Package="{0}"'
    $msdeployCmd += ' -dest:auto,computername="{1}?site={2}",userName={3},password={4},authType=Basic'
    if ($AllowUntrusted)
    {
        $msdeployCmd += ' -allowUntrusted'
    }
    $msdeployCmd += ' -setParam:name="IIS Web Application Name",value="{2}"'

    foreach ($DBConnection in $ConnectionString.GetEnumerator())
    {
        $msdeployCmd += (' -setParam:name="{0}",value="{1}"' -f $DBConnection.Key, $DBConnection.Value)
    }

    $msdeployCmd = $msdeployCmd -f $WebDeployPackage, $PublishUrl, $SiteName, $UserName, $Password

    Write-VerboseWithTime ('Publish-WebPackage: MsDeploy: ' + $msdeployCmd)

    $msdeployExecution = Start-Process cmd.exe -ArgumentList ('/C "' + $msdeployCmd + '" ') -WindowStyle Normal -Wait -PassThru

    if ($msdeployExecution.ExitCode -ne 0)
    {
         Write-VerboseWithTime ('"Msdeploy.exe" wurde mit einem Fehler beendet. Exitcode:' + $msdeployExecution.ExitCode)
    }

    Write-VerboseWithTime 'Publish-WebPackage: Ende'
    return ($msdeployExecution.ExitCode -eq 0)
}


<#
.SYNOPSIS
Stellt einen virtuellen Computer in Windows Azure bereit.

.DESCRIPTION
Die Publish-WebPackageToVM-Funktion ist eine Hilfsfunktion, die die Parameterwerte prüft und dann die Publish-WebPackage-Funktion aufruft.

.PARAMETER  VMDnsName
Dient zum Angeben des DNS-Namens des virtuellen Windows Azure-Computers. Dieser Parameter muss angegeben werden.

.PARAMETER IisWebApplicationName
Dient zum Angeben des Namens einer IIS-Webanwendung für den virtuellen Computer. Dieser Parameter muss angegeben werden. Hierbei handelt es sich um den Namen Ihrer Visual Studio Web App. Den Namen finden Sie im webDeployparameters-Attribut der von Visual Studio generierten JSON-Konfigurationsdatei.

.PARAMETER WebDeployPackage
Dient zum Angeben des Pfads und Dateinamens eines von Visual Studio generierten Webbereitstellungspakets (ZIP-Datei). Dieser Parameter muss angegeben werden. Informationen zum Erstellen eines Webbereitstellungspakets (ZIP-Datei) finden Sie in "Gewusst wie: Erstellen eines Webbereitstellungspakets in Visual Studio" auf "http://go.microsoft.com/fwlink/?LinkId=391353".

.PARAMETER Username
Dient zum Angeben des Benutzernamens des Administrators für den virtuellen Computer. Dieser Parameter muss angegeben werden.

.PARAMETER Password
Dient zum Angeben eines Kennworts für den Administrator des virtuellen Computers. Geben Sie ein Kennwort im Nur-Text-Format ein. Sichere Zeichenfolgen sind nicht zulässig. Dieser Parameter muss angegeben werden.

.PARAMETER AllowUntrusted
Lässt nicht vertrauenswürdige SSL-Verbindungen mit der Website zu. Dieser Parameter wird beim Aufrufen von "MSDeploy.exe" verwendet und muss angegeben werden.

.PARAMETER ConnectionString
Dient zum Angeben einer Verbindungszeichenfolge für eine SQL-Datenbank. Dieser Parameter akzeptiert eine Hash-Tabelle mit Name- und ConnectionString-Schlüssel. Der Name-Wert ist der Name der Datenbank. Der ConnectionString-Wert ist der connectionStringName-Wert aus der JSON-Konfigurationsdatei.

.INPUTS
Keine. Diese Funktion akzeptiert keine Eingaben aus der Pipeline.

.OUTPUTS
Keine.

.EXAMPLE
Publish-WebPackageToVM -VMDnsName contoso.cloudapp.net `
-IisWebApplicationName myTestWebApp `
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip
-Username admin01 `
-Password pa$$word `
-AllowUntrusted:$False `
-ConnectionString @{Name='TestDB';ConnectionString='DefaultConnection'}

.LINK
Publish-WebPackage
#>
function Publish-WebPackageToVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMDnsName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IisWebApplicationName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $true)]
        [Bool]
        $AllowUntrusted,
        
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )
    Write-VerboseWithTime 'Publish-WebPackageToVM: Start'

    $VMDnsUrl = $VMDnsName -as [System.Uri]

    if (!$VMDnsUrl)
    {
        throw ('Publish-WebPackageToVM: Ungültige URL ' + $VMDnsUrl)
    }

    $publishUrl = 'https://{0}:{1}/msdeploy.axd' -f $VMDnsUrl.Host, $WebDeployPort

    $result = Publish-WebPackage `
        -WebDeployPackage $WebDeployPackage `
        -PublishUrl $publishUrl `
        -SiteName $IisWebApplicationName `
        -UserName $UserName `
        -Password $UserPassword `
        -AllowUntrusted:$AllowUntrusted `
        -ConnectionString $ConnectionString

    Write-VerboseWithTime 'Publish-WebPackageToVM: Ende'
    return $result
}


<#
.SYNOPSIS
Erstellt eine Zeichenfolge, mit der Sie eine Verbindung mit einer Windows Azure SQL-Datenbank herstellen können.

.DESCRIPTION
Die Get-AzureSQLDatabaseConnectionString-Funktion erstellt eine Verbindungszeichenfolge für die Verbindungsherstellung mit einer Windows Azure SQL-Datenbank.

.PARAMETER  DatabaseServerName
Dient zum Angeben eines vorhandenen Datenbankservers im Windows Azure-Abonnement. Alle Windows Azure SQL-Datenbanken müssen einem SQL-Datenbankserver zugeordnet werden. Verwenden Sie zum Abrufen des Servernamens das Get-AzureSqlDatabaseServer-Cmdlet (Azure-Modul). Dieser Parameter muss angegeben werden.

.PARAMETER  DatabaseName
Dient zum Angeben des Namens für die SQL-Datenbank. Hierbei kann es sich um eine vorhandene SQL-Datenbank oder um den Namen für eine neue SQL-Datenbank handeln. Dieser Parameter muss angegeben werden.

.PARAMETER  Username
Dient zum Angeben des Namens des SQL-Datenbankadministrators. Der Benutzername lautet $Username@DatabaseServerName. Dieser Parameter muss angegeben werden.

.PARAMETER  Password
Dient zum Angeben eines Kennworts für den SQL-Datenbankadministrator. Geben Sie ein Kennwort im Nur-Text-Format ein. Sichere Zeichenfolgen sind nicht zulässig. Dieser Parameter muss angegeben werden.

.INPUTS
Keine.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'pa$$word'

Server=tcp:bebad12345.database.windows.net,1433;Database=testdb;User ID=admin@bebad12345;Password=pa$$word;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Erstellt Windows Azure SQL-Datenbanken auf der Grundlage der Werte in der von Visual Studio generierten JSON-Konfigurationsdatei.

.DESCRIPTION
Die Add-AzureSQLDatabases-Funktion verwendet Informationen aus dem Datenbankbereich der JSON-Datei. Diese Funktion, Add-AzureSQLDatabases (Plural), ruft die Funktion Add-AzureSQLDatabase (Singular) für jede SQL-Datenbank in der JSON-Datei auf. Add-AzureSQLDatabase (Singular) ruft das New-AzureSqlDatabase-Cmdlet (Azure-Modul) auf, das die SQL-Datenbanken erstellt. Diese Funktion gibt kein Datenbankobjekt, sondern eine Hash-Tabelle mit Werten zurück, die zum Erstellen der Datenbanken verwendet wurden.

.PARAMETER DatabaseConfig
 Akzeptiert ein Array aus PSCustomObjects aus der JSON-Datei, die die Read-ConfigFile-Funktion zurückgibt, wenn die JSON-Datei eine Websiteeigenschaft besitzt. Enthält die environmentSettings.databases-Eigenschaften. Die Liste kann an diese Funktion weitergeleitet werden.
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where connectionStringName
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
Dient zum Angeben des Kennworts für den Administrator des SQL-Datenbankservers. Geben Sie eine Hash-Tabelle mit Namens- und Kennwortschlüssel an. Der Namenswert ist der Name des Datenbankservers. Der Kennwortwert ist das Administratorkennwort. Beispiel: @Name = "TestDB1"; Password = "pa$$word" Dieser Parameter ist optional. Wenn Sie den Parameter nicht angeben oder der SQL-Datenbankservername nicht dem Wert der serverName-Eigenschaft des $DatabaseConfig-Objekts entspricht, verwendet die Funktion die Password-Eigenschaft des $DatabaseConfig-Objekts für die SQL-Datenbank in der Verbindungszeichenfolge.

.PARAMETER CreateDatabase
Stellt sicher, dass Sie eine Datenbank erstellen möchten. Dieser Parameter ist optional.

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where $connectionStringName
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=pa$$word;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $true
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: Start'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: Erstellen ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # Erstellt eine neue SQL-Datenbank mit den DatabaseConfig-Werten (sofern noch keine vorhanden ist).
            # Die Befehlsausgabe ist unterdrückt.
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: Ende'
    }
}


<#
.SYNOPSIS
Erstellt eine neue Windows Azure SQL-Datenbank.

.DESCRIPTION
Die Add-AzureSQLDatabase-Funktion erstellt eine Windows Azure SQL-Datenbank auf der Grundlage der Daten in der von Visual Studio generierten JSON-Konfigurationsdatei und gibt die neue Datenbank zurück. Falls das Abonnement bereits über eine SQL-Datenbank mit dem angegebenen Datenbanknamen im angegebenen SQL-Datenbankserver verfügt, gibt die Funktion die vorhandene Datenbank zurück. Diese Funktion ruft das New-AzureSqlDatabase-Cmdlet (Azure-Modul) auf, das die SQL-Datenbank erstellt.

.PARAMETER DatabaseConfig
Akzeptiert ein PSCustomObject aus der JSON-Konfigurationsdatei, die die Read-ConfigFile-Funktion zurückgibt, wenn die JSON-Datei eine Websiteeigenschaft besitzt. Enthält die environmentSettings.databases-Eigenschaften. Das Objekt kann nicht an diese Funktion weitergeleitet werden. Visual Studio generiert eine JSON-Konfigurationsdatei für alle Webprojekte und speichert sie im PublishScripts-Ordner Ihrer Lösung.

.INPUTS
Keine. Diese Funktion akzeptiert keine Eingaben aus der Pipeline.

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: Start'

    # Fehler, wenn der Parameterwert keine serverName-Eigenschaft besitzt oder die serverName-Eigenschaft keinen Wert enthält.
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: Im DatabaseConfig-Wert fehlt der (erforderliche) Datenbankservername.'
    }

    # Fehler, wenn der Parameterwert nicht über die databasename-Eigenschaft verfügt oder die databasename-Eigenschaft keinen Wert besitzt.
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: Im DatabaseConfig-Wert fehlt der (erforderliche) Datenbankname.'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: Vorhandene Datenbank wird verwendet. ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # Falls das $DatabaseConfig-Objekt eine Sortiereigenschaft besitzt und nicht NULL oder leer ist
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # Falls das $DatabaseConfig-Objekt eine Bearbeitungseigenschaft besitzt und nicht NULL oder leer ist
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # Hash-Tabelle in Verbose-Stream schreiben
        $param | Out-String | Write-VerboseWithTime
        # "New-AzureSqlDatabase" mit Verteilung aufrufen (Ausgabe unterdrücken)
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: Ende'
    return $db
}

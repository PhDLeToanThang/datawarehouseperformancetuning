#  InkandHandwritingServices not have in windows 2016
#Add-WindowsFeature Web-Server,Web-Mgmt-Tools,Web-Mgmt-Console,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Static-Content,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,NET-Framework-Features,NET-Framework-45-Features,NET-Framework-Core,NET-Framework-45-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-HTTP-Activation45,Windows-Identity-Foundation,Server-Media-Foundation
#Windows Server 2016 requires Office Online Server April 2017 or later.
#https://www.microsoft.com/en-us/download/details.aspx?id=48145
#https://docs.microsoft.com/en-us/officeonlineserver/deploy-office-online-server
#https://github.com/PhDLeToanThang/datawarehouseperformancetuning/blob/master/officeonlineserver_w2k12_with_PBIrs.ps1

#Windows Server 2019 requires Office Online Server July 2021 patch or later.
#Windows Server 2022 requires Office Online Server Nov 2021 patch or later.

Import-Module -Name OfficeWebApps
Import-Module "C:\Program Files\Microsoft Office\AdminModule\OfficeWebApps\officewebapps.psd1"
# get Frield name on Certificate:
#Get-ChildItem cert:\localmachine\My\ | FL FriendlyName,Subject,NotBefore,NotAfter
#New-OfficeWebAppsHost -Domain pbi.cloud.edu.vn
#New-OfficeWebAppsMachine –MachineToJoin “pbi.cloud.edu.vn”

#New-OfficeWebAppsFarm -InternalUrl “https://<Internal URL FQDN>” -ExternalUrl “https://<External URL FQDN>”-CertificateName “<Certificate’s Friendly Name>” -EditingEnabled -AllowHTTP –Verbose
New-OfficeWebAppsFarm -InternalURL "https://pbi.cloud.edu.vn" -ExternalUrl "https://pbi.cloud.edu.vn" -CertificateName "pbi.cloud.edu.vn" -AllowHttp -EditingEnabled –Verbose
#New-OfficeWebAppsFarm -InternalURL "http://pbi.cloud.edu.vn" -AllowHttp -EditingEnabled –Verbose
# P/S: Private key pfx for import Certificate personal > People > frield name: pbi.cloud.edu.vn
# https://www.alitajran.com/exprt-lets-encrypt-certificate-in-windows-server/ 
#  "[Manual] owa.cloud.edu.vn 2021/12/10 16:50:53"
#Remove-OfficeWebAppsMachine 
#
#PS C:\Windows\system32> New-OfficeWebAppsFarm -InternalURL "https://owa.cloud.edu.vn" -ExternalUrl "https://owa.cloud.edu.vn" -CertificateName "" -AllowHttp -EditingEnabled –Verbose
#VERBOSE: Performing the operation "CreateNewFarm" on target "OfficeWebAppsFarm".
#FarmOU                            : 
#InternalURL                       : https://owa.cloud.edu.vn/
#ExternalURL                       : https://owa.cloud.edu.vn/
#AllowHTTP                         : True
#SSLOffloaded                      : False
#CertificateName                   : 
#EditingEnabled                    : True
#LogLocation                       : C:\ProgramData\Microsoft\OfficeWebApps\Data\Logs\ULS
#LogRetentionInDays                : 7
#LogVerbosity                      : 
#Proxy                             : 
#CacheLocation                     : C:\ProgramData\Microsoft\OfficeWebApps\Working\d
#MaxMemoryCacheSizeInMB            : 75
#DocumentInfoCacheSize             : 5000
#CacheSizeInGB                     : 15
#ClipartEnabled                    : False
#TranslationEnabled                : False
#MaxTranslationCharacterCount      : 125000
#TranslationServiceAppId           : 
#TranslationServiceAddress         : 
#RenderingLocalCacheLocation       : C:\ProgramData\Microsoft\OfficeWebApps\Working\waccache
#RecycleActiveProcessCount         : 5
#AllowCEIP                         : False
#ExcelRequestDurationMax           : 300
#ExcelSessionTimeout               : 450
#ExcelWorkbookSizeMax              : 10
#ExcelPrivateBytesMax              : -1
#ExcelConnectionLifetime           : 1800
#ExcelExternalDataCacheLifetime    : 300
#ExcelAllowExternalData            : True
#ExcelWarnOnDataRefresh            : True
#OpenFromUrlEnabled                : False
#OpenFromUncEnabled                : True
#OpenFromUrlThrottlingEnabled      : True
#PicturePasteDisabled              : True
#RemovePersonalInformationFromLogs : False
#AllowHttpSecureStoreConnections   : False
#IgnoreDeserializationFilter       : False
#Machines                          : {OWA}
#
New-OfficeWebAppsHost -Domain "cloud.edu.vn" –Verbose

#Set-OfficeWebAppsFarm –CertificateName "pbi.cloud.edu.vn"
#Set-OfficeWebAppsFarm : Office Online cannot use the specified certificate because it does not have a private key.  
#At line:1 char:1

Set-OfficeWebAppsFarm -ExcelWorkbookSizeMax 100
Set-OfficeWebAppsFarm -ExcelUseEffectiveUserName:$true
Set-OfficeWebAppsFarm -ExcelAllowExternalData:$true
Set-OfficeWebAppsFarm -ExcelWarnOnDataRefresh:$false
Set-OfficeWebAppsFarm -EditingEnabled:$true
Set-OfficeWebAppsFarm -OpenFromUrlEnabled:$true
Set-OfficeWebAppsFarm -ClipartEnabled:$true
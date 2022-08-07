# OOS install on Windows 2016
#Install .NET Framework 4.5.2
#Install Visual C++ Redistributable Packages for Visual Studio 2013
#Install Visual C++ Redistributable for Visual Studio 2015
#Microsoft.IdentityModel.Extention.dll
#Add-WindowsFeature Web-Server,Web-Mgmt-Tools,Web-Mgmt-Console,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Static-Content,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,InkandHandwritingServices,NET-Framework-Features,NET-Framework-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-HTTP-Activation45,Windows-Identity-Foundation,Server-Media-Foundation

#https://www.catapultsystems.com/blogs/troubleshooting-office-online-server-and-office-web-apps-server/

Import-Module -Name OfficeWebApps

Import-Module "C:\Program Files\Microsoft Office Web Apps\AdminModule\OfficeWebApps\OfficeWebApps.psd1"

Get-ChildItem cert:\localmachine\My\ | FL FriendlyName,Subject,NotBefore,NotAfter

#New-OfficeWebAppsFarm -InternalUrl “https://<Internal URL FQDN>” -ExternalUrl “https://<External URL FQDN>”-CertificateName “<Certificate’s Friendly Name>” -EditingEnabled -AllowHTTP –Verbose

New-OfficeWebAppsFarm -InternalURL "https://owa.cloud.edu.vn" -ExternalUrl "https://owa.cloud.edu.vn" -CertificateName "" -AllowHttp -EditingEnabled –Verbose
#New-OfficeWebAppsFarm -InternalURL "https://owa.cloud.edu.vn" -AllowHttp -EditingEnabled –Verbose
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

Set-OfficeWebAppsFarm -ExcelWorkbookSizeMax 100
Set-OfficeWebAppsFarm -ExcelUseEffectiveUserName:$true
Set-OfficeWebAppsFarm -ExcelAllowExternalData:$true
Set-OfficeWebAppsFarm -ExcelWarnOnDataRefresh:$false
Set-OfficeWebAppsFarm -EditingEnabled:$true
Set-OfficeWebAppsFarm -OpenFromUrlEnabled:$true
Set-OfficeWebAppsFarm -ClipartEnabled:$true

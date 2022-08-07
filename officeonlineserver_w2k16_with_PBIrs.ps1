#---------------Step 1. Install prerequisite software for Office Online Server - OOS install on Windows 2016 
#Install .NET Framework 4.5.2 (https://go.microsoft.com/fwlink/p/?LinkId=510096)
#Install Visual C++ Redistributable Packages for Visual Studio 2013 (https://www.microsoft.com/download/details.aspx?id=40784)
#Install Visual C++ Redistributable for Visual Studio 2015 (https://go.microsoft.com/fwlink/p/?LinkId=620071)
#Microsoft.IdentityModel.Extention.dll (https://go.microsoft.com/fwlink/p/?LinkId=620072)
#InkandHandwritingServices
Add-WindowsFeature Web-Server,Web-Mgmt-Tools,Web-Mgmt-Console,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Static-Content,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,NET-Framework-Features,NET-Framework-45-Features,NET-Framework-Core,NET-Framework-45-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-HTTP-Activation45,Windows-Identity-Foundation,Server-Media-Foundation

#----------------- Step 2 Install Office Online Server -------------------------
#If you plan to use any Excel Online features that utilize external data access (such as Power Pivot), note that Office Online Server must #reside in the same Active Directory forest as its users as well as any external data sources that you plan to access using Windows-based #authentication.
#   Download Office Online Server from the Volume Licensing Service Center (VLSC). 
#   (https://go.microsoft.com/fwlink/p/?LinkId=256561)
#The download is located under those Office products on #the VLSC portal. For development purposes, you can download OOS from MSDN #subscriber downloads.
#    Run Setup.exe.
#    On the Read the Microsoft Software License Terms page, select I accept the terms of this agreement and select Continue.
#    On the Choose a file location page, select the folder where you want the Office Online Server files to be installed (for example, #C:\Program Files\Microsoft Office Web Apps*) and select Install Now. If the folder you specified doesn’t exist, Setup creates it for you.
#    We recommend that you install Office Online Server on the system drive.
#    When Setup finishes installing Office Online Server, select Close.

#------------------ Step 3 Install Language for OOS Server (option) -------------------
# Install language packs for Office Web Apps Server (optional)
#Office Online Server Language Packs let users view web-based Office files in multiple languages.
#To install the language packs, follow these steps.
#    Download the Office Online Server Language Packs from the Microsoft Download Center.
#  Run wacserverlanguagepack.exe.
#   In the Office Online Server Language Pack Wizard, on the Read the Microsoft Software License Terms page, select I accept the terms of #this agreement and select Continue.
#    When Setup finishes installing Office Online Server, select Close.
#-------------------Step 4. Deploy Office Online Server -------------------------------
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

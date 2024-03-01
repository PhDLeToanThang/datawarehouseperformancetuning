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
# Deploy a multi-server, load-balanced Office Online Server farm that uses HTTPS:
# New-OfficeWebAppsFarm -InternalUrl "https://oos.io" -ExternalUrl "https://oos.io" -SSLOffloaded -EditingEnabled

# Standalone not LBN:
New-OfficeWebAppsFarm -InternalURL "https://oos.io" -ExternalUrl "https://oos.io" -CertificateName "" -AllowHttp -EditingEnabled –Verbose
#New-OfficeWebAppsFarm -InternalURL "https://oos.io" -AllowHttp -EditingEnabled –Verbose
#  "[Manual] oos.io 2021/12/10 16:50:53"
#Remove-OfficeWebAppsMachine 
#
#PS C:\Windows\system32> New-OfficeWebAppsFarm -InternalURL "https://oos.io" -ExternalUrl "https://oos.io" -CertificateName "" -AllowHttp -EditingEnabled –Verbose
#VERBOSE: Performing the operation "CreateNewFarm" on target "OfficeWebAppsFarm".
#FarmOU                            : 
#InternalURL                       : https://oos.io/
#ExternalURL                       : https://oos.io/
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

#Verify that the Office Online Server farm was created successfully
#After the farm is created, details about the farm are displayed in the Windows PowerShell prompt. To verify that Office Online Server is installed and configured correctly, use a web browser to access the Office Online Server discovery URL, as shown in the following example. **_The discovery URL is the InternalUrl parameter you specified when you configured your Office Online Server farm, followed by /hosting/discovery, for example_**:
#<InternalUrl>/hosting/discovery
#If Office Online Server works as expected, you should see a Web Application Open Platform Interface Protocol (WOPI)-discovery XML file in your web browser. The first few lines of that file should resemble the following example:
#XML

#<?xml version="1.0" encoding="utf-8" ?> 
#<wopi-discovery>
#<net-zone name="internal-http">
#<app name="Excel" favIconUrl="<InternalUrl>/x/_layouts/images/FavIcon_Excel.ico" checkLicense="true">
#<action name="view" ext="ods" default="true" urlsrc="<InternalUrl>/x/_layouts/xlviewerinternal.aspx?<ui=UI_LLCC&><rs=DC_LLCC&>" /> 
#<action name="view" ext="xls" default="true" urlsrc="<InternalUrl>/x/_layouts/xlviewerinternal.aspx?<ui=UI_LLCC&><rs=DC_LLCC&>" /> 
#<action name="view" ext="xlsb" default="true" urlsrc="<InternalUrl>/x/_layouts/xlviewerinternal.aspx?<ui=UI_LLCC&><rs=DC_LLCC&>" /> 
#<action name="view" ext="xlsm" default="true" urlsrc="<InternalUrl>/x/_layouts/xlviewerinternal.aspx?<ui=UI_LLCC&><rs=DC_LLCC&>" /> 

**Configure Excel workbook maximum size**
#The maximum file size for all files in Power BI Report Server is 100 MB. To stay in sync with that, you need to manually set this in OOS.
#PowerShell:
#Set-OfficeWebAppsFarm -ExcelWorkbookSizeMax 100
#Using EffectiveUserName with Analysis Services
#To allow for live connections to Analysis Services, for connections within an Excel workbook that make use of EffectiveUserName. For OOS to make use of EffectiveUserName, you will need to add the machine account of the OOS server as an administrator for the Analysis Services instance. Management Studio for SQL Server 2016 or later is needed to do this.
#Only embedded Analysis Services connections are currently supported within an Excel workbook. The user's account will need to have permission to connect to Analysis Services as the ability to proxy the user is not available.
#Run the following PowerShell commands on the OOS Server.
#PowerShell
#Set-OfficeWebAppsFarm -ExcelUseEffectiveUserName:$true
#Set-OfficeWebAppsFarm -ExcelAllowExternalData:$true
#Set-OfficeWebAppsFarm -ExcelWarnOnDataRefresh:$false
#Configure a Power Pivot instance for data models
#Installing an Analysis Services Power Pivot mode instance lets you work with Excel workbooks that are using Power Pivot. Make sure that the instance name is POWERPIVOT. Add the machine account of the OOS server as an administrator, for the Analysis Services Power Pivot mode instance. Management Studio for SQL Server 2016 or later is needed to do this.
#For OOS to use the Power Pivot mode instance, run the following command.
#PowerShell
#New-OfficeWebAppsExcelBIServer -ServerId <server_name>\POWERPIVOT
#If you did not already allow external data, from the Analysis Services step above, run the following command.
#PowerShell
#Set-OfficeWebAppsFarm -ExcelAllowExternalData:$true
#Firewall considerations
#To avoid firewall issues, you may need to open the ports 2382 and 2383. You can also add the msmdsrv.exe, for the Power Pivot instance, as an application firewall wall policy.
#Configure Power BI Report Server to use the OOS Server
#On the General page of Site settings, enter the OOS discovery url. The OOS discovery url is the InternalUrl, used when deploying the OOS server, followed by /hosting/discovery. For example, https://servername/hosting/discovery, for HTTP. And, https://server.contoso.com/hosting/discovery for HTTPS.
#To get to Site settings, select the gear icon in the upper right and select Site settings.
#Only a user with the System Administrator role will see the Office Online Server discovery url setting.
#Site settings for Power BI Report Server.
#After you enter the discovery url, and select Apply, selecting an Excel workbook, within the web portal, should display the workbook within the web portal.
#Considerations and limitations
#    You will have read only capability with workbooks.
#    Scheduled refresh isn't supported for Excel workbooks in Power BI Report Server.

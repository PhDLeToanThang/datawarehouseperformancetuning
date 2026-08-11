# Phần 1. Mô hình SSO - Web Login và Redirect MFA/Đăng ký OTP qua Qrcode Mobile:

>>>hãy phân tích phương pháp chi tiết từng bước cấu hình Keycloak latest verison với cấu hình chạy trên ubuntu 24.04 lts server có thể cấu hình tối ưu với AD1 local để làm sso, otp qua Qrcode mobile và là kiểu SSO với việc direct URL web access tới Power BI Report Server (là máy chủ windows 2019DC licensed, đã join domain 1 lần với AD1, nhưng chỉ có Form Web base FB cần chuyển sang dạng tích hợp web access từ Keycloak)?

---

Để triển khai hệ thống SSO toàn diện kết hợp OTP QR Code bằng Keycloak phiên bản mới nhất (26.x) trên máy chủ Ubuntu 24.04 LTS Server, đồng thời đồng bộ hóa tối ưu dữ liệu từ máy chủ Active Directory (AD1) local và chuyển đổi Form-based (FB) của Power BI Report Server (PBIRS) sang kiến trúc định danh tập trung, bạn thực hiện theo phương pháp chi tiết từng bước dưới đây. [1, 2] 

------------------------------

## Mô hình kiến trúc giải pháp
Do Power BI Report Server (on-premises) chạy trên Windows Server không hỗ trợ trực tiếp các giao thức mã nguồn mở hiện đại như OpenID Connect (OIDC) hay OAuth2 ở tầng ứng dụng gốc, giải pháp tối ưu hàng đầu cho hạ tầng này là sử dụng cơ chế Reverse Proxy Federation (như Nginx tích hợp module lua-resty-openidc hoặc Apache với mod_auth_openidc) đứng trước PBIRS. [3, 4] 

* **Luồng xử lý:** Người dùng truy cập URL Web ➔ Reverse Proxy chặn lại và chuyển hướng sang Keycloak bắt buộc đăng nhập (User/Pass từ AD1 + Quét mã QR OTP) ➔ Xác thực thành công, Keycloak trả về Token ➔ Reverse Proxy chuyển dịch token này thành định danh đóng gói vào HTTP Custom Headers chuyển tiếp cho Custom Authentication Extension của Power BI Report Server xử lý gán phiên làm việc. [5] 

------------------------------
## Bước 1: Khởi tạo môi trường Ubuntu 24.04 LTS & Cài đặt Keycloak 26.x
Keycloak 26.x yêu cầu tối thiểu Java 21 và khuyến cáo vận hành cơ sở dữ liệu production bên ngoài như PostgreSQL để đảm bảo tính toàn vẹn dữ liệu thay vì cơ sở dữ liệu nhúng H2. [2] 

## 1.1 Cập nhật hệ thống và cài đặt OpenJDK 21
```
sudo apt update && sudo apt upgrade -y
sudo apt install openjdk-21-jdk wget unzip -y
```
## 1.2 Tạo người dung hệ thống biệt lập và tải Keycloak

### Tạo user chạy dịch vụ không có quyền shell đăng nhập nhằm tăng tính bảo mật
```
sudo useradd -r -m -d /opt/keycloak -s /bin/false keycloak
```
### Tải bản phân phối Keycloak mới nhất (Ví dụ bản ổn định 26.x)
```
cd /tmp
wget https://github.com
sudo unzip keycloak-26.7.0.zip -d /opt/
sudo mv /opt/keycloak-26.7.0/* /opt/keycloak/
sudo chown -R keycloak: /opt/keycloak
```
## 1.3 Cấu hình Production Mode với PostgreSQL (/opt/keycloak/conf/keycloak.conf)
Chỉnh sửa file cấu hình để tối ưu hóa hiệu năng, kết nối database và ép buộc chứng chỉ bảo mật mã hóa toàn vẹn:

### Database cấu hình
```
db=postgres
db-username=keycloak_user
db-password=YourSecurePassword
db-url=jdbc:postgresql://localhost:5432/keycloak_db
```
### Cấu hình Network & bảo mật HTTPS bắt buộc cho OTP/SSO
```
http-enabled=true
http-relative-path=/
proxy-headers=xforwarded # Ép nhận header từ Reverse Proxy phía trước
```
### Điền đường dẫn chứng chỉ SSL/TLS công khai hoặc nội bộ được Windows/Ubuntu tin cậy
```
https-certificate-file=/etc/letsencrypt/live/sso.yourdomain.local/fullchain.pem
https-certificate-key-file=/etc/letsencrypt/live/sso.yourdomain.local/privkey.pem
```
### Tối ưu hóa tính năng nâng cao cho môi trường Production
```
features=token-exchange,declarative-user-profile
```
## 1.4 Khởi tạo tiến trình chạy ngầm Systemd
Tạo file /etc/systemd/system/keycloak.service:

```
[Unit]
Description=Keycloak Identity Provider
After=network.target postgresql.service

[Service]
Type=simple
User=keycloak
Group=keycloak
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start
Restart=always
RestartSec=5
Environment=LANG=en_US.UTF-8

[Install]
WantedBy=multi-user.target
```
Chạy lệnh tối ưu hóa cấu hình sinh mã byte-code tĩnh và kích hoạt dịch vụ:
```
sudo -u keycloak /opt/keycloak/bin/kc.sh build
sudo systemctl daemon-reload
sudo systemctl enable --now keycloak
```
------------------------------
## Bước 2: Liên kết và cấu hình tối ưu User Federation với Active Directory (AD1)## 2.1 Cài đặt kết nối kết nối LDAP/AD trong Keycloak Admin Console

   1. Truy cập trang quản trị Keycloak ➔ Chọn Realm làm việc chính (ví dụ: Company-SSO) ➔ Chọn mục User Federation ➔ Add provider ➔ ldap.
   2. Console Display Name: AD1-Local.
   3. Vendor: Chọn Active Directory.
   4. Connection URL: Điền ldaps://ad1.yourdomain.local:636 (Khuyến cáo dùng cổng mã hóa 636 bảo vệ an toàn thông tin mật khẩu truyền tải thay vì cổng 389).

## 2.2 Đồng bộ hóa cấu hình tối ưu cho Active Directory

* User DN: CN=Users,DC=yourdomain,DC=local (Trỏ đúng OU chứa tài khoản nhân sự).
* Bind DN và Bind Credential: Tài khoản có quyền read hệ thống AD (Ví dụ: CN=KeycloakBind,OU=ServiceAccounts,DC=yourdomain,DC=local).
* User Object Classes: user, person.
* Username LDAP Attribute: sAMAccountName (Đảm bảo người dùng nhập đúng định danh Windows cũ để đồng bộ).
* UUID LDAP Attribute: objectGUID (Đảm bảo thuộc tính định danh duy nhất không đổi).
* Read Only: Chọn True (Đảm bảo Keycloak chỉ đọc thông tin, không làm thay đổi trực tiếp cấu trúc cây AD1 khi không được phép).

## 2.3 Thiết lập cơ chế lập lịch đồng bộ (Sync Settings)
Để tối ưu hóa tài nguyên phần cứng, tránh nghẽn truy vấn tới AD1:

* Periodic Full Sync: Bật True ➔ Tần suất khuyến cáo: 86400 giây (Đồng bộ toàn bộ tài khoản 1 lần/ngày vào ban đêm).
* Periodic Changed Users Sync: Bật True ➔ Tần suất khuyến cáo: 300 giây (Cứ 5 phút quét AD một lần để cập nhật các user mới khởi tạo hoặc mới đổi mật khẩu).

------------------------------
## Bước 3: Cấu hình bắt buộc thực hiện OTP qua QR Code trên Thiết bị di động## 3.1 Cấu hình chính sách mã OTP (OTP Policy)
Trong menu quản trị Realm: Vào mục Authentication ➔ Chọn tab Policies ➔ OTP Policy:

* OTP Type: Chọn TOTP (Time-Based One-Time Password).
* OTP Algorithm: Chọn SHA-1 hoặc tăng cường bảo mật cao với SHA-256.
* Digits: 6 ký tự số.
* Look Ahead Window: Chọn 1 (Cho phép lệch thời gian tối đa 30 giây của thiết bị di động so với máy chủ).
* OTP Period: 30 giây hiệu lực mã.

## 3.2 Áp dụng luồng xác thực (Authentication Flow)

   1. Trong mục Authentication ➔ Chọn Tab Flows ➔ Bấm vào luồng Browser.
   2. Tại khối xử lý sau khi kiểm tra Username/Password thành công, chuyển đổi trạng thái của bước OTP Form / Browser - Conditional OTP từ Optional/Alternative sang Required (Bắt buộc).
   3. Luồng trải nghiệm: Người dùng đăng nhập thành công lần đầu bằng tài khoản AD1 ➔ Hệ thống tự động đẩy ra trang hiển thị Mã QR Code bắt buộc kèm hướng dẫn ➔ Người dùng lấy ứng dụng (Google Authenticator, Microsoft Authenticator) trên mobile quét mã ➔ Nhập mã xác nhận để liên kết thiết bị vĩnh viễn cho các lần đăng nhập tiếp theo.

------------------------------
## Bước 4: Thiết lập Reverse Proxy trung gian xử lý tích hợp Web Access cho Power BI Report Server
Do Power BI Report Server hiện tại chạy dạng Form Web base (FB) cũ, ta sử dụng một máy chủ Nginx trung gian cài đặt module OpenID Connect để nhận diện token từ Keycloak, sau đó phân tách định danh chuyển tiếp cho Windows IIS / PBIRS. [4] 
## 4.1 Tạo Client đại diện trên Keycloak

   1. Vào Clients ➔ Create Client.
   2. Client ID: powerbi-gateway.
   3. Client Protocol: openid-connect.
   4. Capability Config: Bật Standard Flow Enabled.
   5. Access Type: Chọn Confidential (Để sinh mã khóa mật bảo vệ Client Secret).
   6. Valid Redirect URIs: https://yourdomain.local (Địa chỉ URL của Nginx proxy xử lý định tuyến). [6] 

## 4.2 Cấu hình Nginx chặn dịch với Module OIDC
Cài đặt Nginx cấu hình nhận diện JWT Token phát ra từ Keycloak, cấu hình tệp tin ảo hóa:

```
server {
    listen 443 ssl;
    server_name powerbi.yourdomain.local;

    ssl_certificate /etc/nginx/ssl/powerbi.crt;
    ssl_certificate_key /etc/nginx/ssl/powerbi.key;

    # Cấu hình OpenID Connect kết nối Keycloak
    set $oidc_provider "https://yourdomain.local";
    set $oidc_client_id "powerbi-gateway";
    set $oidc_client_secret "Mã_Secret_Sinh_Từ_Keycloak";

    location / {
        # Sử dụng module luaresty hay mod_auth để chặn kiểm tra session token
        # Nếu chưa đăng nhập, tự động chuyển hướng về Keycloak
        access_by_lua_block {
            local res, err = require("resty.openidc").authenticate(opts)
            # Truyền thông tin người dùng được giải mã từ Keycloak vào Custom Header bảo mật
            ngx.req.set_header("X-MS-Authenticated-User", res.user.preferred_username)
        }

        # Chuyển tiếp luồng sạch về máy chủ Windows Server 2019 chạy Power BI
        proxy_pass http://192.168.1.100:80; # IP nội bộ máy chủ Windows PBIRS
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
------------------------------
## Bước 5: Cấu hình Custom Authentication Extension tại Máy chủ Windows Server 2019 (PBIRS)
Bởi vì PBIRS không thể đọc trực tiếp header HTTP từ Nginx nếu không được cấu hình chế độ Custom Security, bạn cần biên dịch thư viện mở rộng để tiếp nhận thông tin từ Header bảo mật X-MS-Authenticated-User. [5] 
## 5.1 Cài đặt Custom Authentication Extension

   1. Tải bộ thư viện hoặc phát triển mã nguồn mở Custom Security Extension mẫu dành cho SQL Server Reporting Services / Power BI Report Server bằng .NET C# (Microsoft cung cấp mẫu Reporting Services Custom Security Sample).
   2. Trong hàm xử lý định danh chính GetUserInfo, tiến hành thay đổi logic kiểm tra thay vì đọc Form đăng nhập cũ, chuyển sang đọc giá trị trực tiếp từ HTTP Request Headers:
   
   // Đọc định danh sAMAccountName được truyền an toàn từ Nginx proxy sau khi qua màng Keycloak OTPstring authenticatedUser = HttpContext.Current.Request.Headers["X-MS-Authenticated-User"];
   
   3. Tiến hành Build dự án lấy file thư viện liên kết động CustomSecurityExtension.dll rồi sao chép trực tiếp vào thư mục cài đặt gốc của PBIRS trên máy chủ Windows 2019:
   * C:\Program Files\Microsoft Power BI Report Server\PBIRS\ReportServer\bin
      * C:\Program Files\Microsoft Power BI Report Server\PBIRS\Portal
   
## 5.2 Khai báo thay đổi phương thức xác thực trên tệp cấu hình Windows
Mở tệp tin RSReportServer.config trên Windows Server 2019:

   1. Tìm đến thẻ <Authentication> và đổi kiểu xác thực sang dạng Custom:
```
   <Authentication>
       <AuthenticationTypes>
           <Custom/>
       </AuthenticationTypes>
       <EnableAuthPersistence>true</EnableAuthPersistence>
   </Authentication>
```
   2. Đăng ký phần mở rộng bảo mật trong danh mục thẻ <Security> và <Authentication> bằng cách trỏ chính xác định danh Class định nghĩa từ file .dll đã nhúng.
   3. Khởi động lại dịch vụ Power BI Report Server Service bằng công cụ Report Server Configuration Manager để áp dụng thay đổi toàn diện cấu hình hệ thống. [7] 

------------------------------
## Kiểm tra vận hành (Validation)

* Truy cập https://yourdomain.local.
* Hệ thống tự động nhảy sang màn hình Login của Keycloak phiên bản mới.
* Nhập tài khoản AD1 ➔ Yêu cầu quét mã QR và điền 6 số OTP trên điện thoại.
* Đăng nhập thành công ➔ Keycloak redirect về Nginx Proxy kèm Token gán vào Custom Header bảo mật ➔ Power BI Report Server tiếp nhận và đăng nhập trực tiếp đúng danh tính người dùng mà không hiển thị lại màn hình Form nhập cũ.
  
```
[1] [https://www.keycloak.org](https://www.keycloak.org/2026/07/keycloak-2670-released)
[2] [https://github.com](https://github.com/PhDLeToanThang/automation/issues/28)
[3] [https://community.fabric.microsoft.com](https://community.fabric.microsoft.com/t5/Report-Server/Integrate-SSO-SAML-or-OIDC-authentication-in-PowerBI-on-premise/m-p/3312786)
[4] [https://community.fabric.microsoft.com](https://community.fabric.microsoft.com/t5/Report-Server/Integrate-Power-BI-Report-Server-with-Keycloak/m-p/3195491)
[5] [https://learn.microsoft.com](https://learn.microsoft.com/en-us/answers/questions/5581016/custom-sso-form-based-authentication-for-powerbi-o)
[6] [https://help.boldbi.com](https://help.boldbi.com/security-configuration/single-sign-on/openid-support/keycloak/)
[7] [https://community.fabric.microsoft.com](https://community.fabric.microsoft.com/t5/Report-Server/Integrate-SSO-SAML-or-OIDC-authentication-in-PowerBI-on-premise/m-p/4391297)
```
---

# Phần 2. Phân tích ngữ cảnh điều chỉnh thiết kế:

>>>Bản thân Keycloak 26.x tôi cũng quen dùng nginx web reserse proxy, và let's encrypt làm SSL/TLS cho HTTPS của keycloak login. như vậy tôi có 2 câu hỏi thắc mắc sau:
1. Keycloak có bắt buộc phải là lớp public login ra cổng 443 ở internet public nếu muốn cho phép người dùng ở internet truy cập vào power BI report serve ? và tất nhiên cả power bi report server cũng cần có URL public cho người dùng internet truy cập ? Nếu keycloak cần NAT ra public port 443,80 (tôi dùng 1 VM haproxy 2.9 và iptables để cho phép public). thì cấu hình Keycloak có thay đổi gì về bước cài, cấu hình keycloak trên ubuntu 24.04 LTS server - là 1 VM Vmware) ?
2. NGINX reverse Proxy có bắt buộc là 1 VM chạy riêng ? hay chạy trên cùng Keycloak 26.x ? hoặc chạy trên haproxy 2.9 ? Hãy phân tích tính hợp lý để tiết kiệm tài nguyên, tập trung thống nhất và an toàn hệ thống. Nếu cài riêng hãy cho chi tiết cấu hình tối ưu và các bước cấu hình chi tiết ?

---

>>>Hoan nghênh cách tiếp cận thực tế của bạn khi kết hợp HAProxy 2.9, Nginx và Keycloak 26.x. Đây là mô hình chuẩn doanh nghiệp, vừa tối ưu hiệu năng vừa đảm bảo an toàn.
Dưới đây là phân tích chuyên sâu giải đáp chi tiết 2 thắc mắc của bạn để cấu hình hệ thống vừa tiết kiệm tài nguyên, vừa bảo mật tối đa.
------------------------------
## Câu hỏi 1: Luồng Public Internet, NAT Ports và Cấu hình Keycloak trên VM Ubuntu 24.04

## 1.1 Khả năng Public và URL tương tác

* **Keycloak BẮT BUỘC phải public ra Internet (Port 443 HTTPS):** Khi người dùng ngoài Internet truy cập Power BI, trình duyệt của họ sẽ bị redirect (chuyển hướng ở tầng Client-side) sang URL của Keycloak để đăng nhập tài khoản và quét mã OTP. Nếu Keycloak nằm hoàn toàn trong mạng nội bộ (LAN/VPN), trình duyệt của người dùng ngoài Internet sẽ báo lỗi không tìm thấy máy chủ (ERR_CONNECTION_TIMED_OUT).
* **Power BI Report Server (PBIRS) CẦN có URL Public:** Người dùng cần một domain công khai (ví dụ: https://company.com) để truy cập xem báo cáo. Tuy nhiên, bản thân máy chủ Windows PBIRS không bao giờ được NAT trực tiếp ra ngoài Internet. Mọi truy cập công khai phải đi qua lớp bảo vệ của Reverse Proxy (HAProxy/Nginx).

## 1.2 Thay đổi cấu hình Keycloak trên VM Ubuntu khi chạy qua HAProxy (Public)
Vì Keycloak chạy trên một VM Ubuntu nội bộ phía sau HAProxy, cấu hình có hai điểm thay đổi cực kỳ quan trọng so với việc chạy độc lập:

   1. **Ủy quyền SSL/TLS (SSL Termination):** Hãy để HAProxy (hoặc Nginx) giữ chứng chỉ Let's Encrypt và giải mã HTTPS ở ngoài cùng. Bản thân Keycloak trên Ubuntu chỉ cần chạy HTTP thuần túy (hoặc HTTPS nội bộ bằng Self-signed Certificate) để tiết kiệm CPU giải mã và đơn giản hóa việc quản lý gia hạn chứng chỉ Let's Encrypt tập trung.
   2. **Cấu hình lại file /opt/keycloak/conf/keycloak.conf:** Bạn cần chỉnh sửa để Keycloak hiểu nó đang đứng sau một Proxy ngược và biết được URL public chính xác của nó (tránh lỗi quay vòng Redirect hoặc lỗi Cookie SameSite).

Chỉnh sửa file cấu hình Keycloak như sau:

# Đổi từ production HTTPS sang nhận diện proxy ngược
http-enabled=true
http-port=8080             # Keycloak lắng nghe port này trong mạng LAN
proxy-headers=xforwarded   # Đọc các header X-Forwarded-For, X-Forwarded-Proto từ HAProxy

# Định nghĩa URL Công khai hiển thị ngoài Internet (Cực kỳ quan trọng)
hostname=://company.com   # Domain public đã trỏ về IP Public của HAProxy

Sau khi sửa, bạn chỉ cần chạy lại lệnh:

sudo -u keycloak /opt/keycloak/bin/kc.sh build
sudo systemctl restart keycloak

------------------------------
## Câu hỏi 2: Vị trí đặt NGINX Reverse Proxy & Phương án kiến trúc tối ưu

## 2.1 Phân tích tính hợp lý và vị trí đặt Nginx
Để đáp ứng các tiêu chí Tiết kiệm tài nguyên, Tập trung thống nhất và An toàn hệ thống, chúng ta phân tích 3 phương án bạn đưa ra:

* **Phương án A:** Chạy chung Nginx trên HAProxy 2.9 (Không khuyến nghị): HAProxy đảm nhận vai trò Load Balancer tầng 4/7 rất tốt. Việc nhồi nhét thêm Nginx kèm module Lua (lua-resty-openidc) để xử lý logic SSO/OIDC lên cùng một VM biên (Edge) làm tăng nguy cơ sập toàn bộ hạ tầng mạng (Single Point of Failure) nếu mã Lua bị lỗi xung đột tài nguyên.
* **Phương án B:** Tạo 1 VM Nginx riêng biệt (Tốn tài nguyên): Cách này an toàn nhất về mặt cô lập lỗi nhưng gây lãng phí tài nguyên VM (CPU, RAM, Storage, IP quản trị) cho các doanh nghiệp quy mô vừa và nhỏ.
* **Phương án C:** Cài chung Nginx lên cùng VM Ubuntu chạy Keycloak 26.x (Tối ưu nhất - Khuyên dùng 👍):
* Tiết kiệm: Sử dụng chung một hệ điều hành Ubuntu 24.04, tận dụng RAM trống của VM Keycloak (Keycloak tốn chủ yếu là RAM cho Java Heap, Nginx và module OIDC tốn cực kỳ ít tài nguyên).
   * **An toàn:** Luồng trao đổi Token (Backchannel) giữa Nginx và Keycloak diễn ra qua giao tiếp localhost (127.0.0.1). Token bí mật (Client Secret) không bao giờ truyền qua mạng LAN, loại bỏ hoàn toàn nguy cơ bị nghe lén (Sniffing).
   * **Thống nhất:** Toàn bộ cụm Logic liên quan đến Xác thực (Auth Stack) được gom vào 1 VM duy nhất giúp dễ đóng gói, sao lưu (Snapshot) và khôi phục khi có sự cố.

------------------------------
## Kiến trúc tổng thể dòng chảy dữ liệu (Luồng Traffic)
```
[ Internet User ] 
       │ (HTTPS:443)
       ▼
 [ HAProxy 2.9 (Cổng Biên) ] ── (Giải mã SSL Let's Encrypt tập trung)
       │
       ├─► Nếu trỏ domain ://company.com   ──► (HTTP:8080) ──► [ Keycloak Service ]
       │
       └─► Nếu trỏ domain ://company.com ──► (HTTP:80) ───► [ Nginx OIDC Proxy ]
                                                                     │ (Nằm chung VM Keycloak,
                                                                     │  xử lý gán Custom Header)
                                                                     ▼
                                                             [ Windows Server 2019 (PBIRS) ]
```
------------------------------
## Hướng dẫn cấu hình chi tiết Phương án Tối ưu (Nginx chung VM với Keycloak)
## 1. Cấu hình tại HAProxy 2.9 (Máy chủ Biên)
HAProxy đóng vai trò nhận request ngoài Internet, giải mã SSL Let's Encrypt, chèn các header định danh nguồn (X-Forwarded-*) rồi điều hướng về cho VM Ubuntu (192.168.1.50).
Thêm vào file cấu hình /etc/haproxy/haproxy.cfg:

```
frontend https_in
    bind *:443 ssl crt /etc/letsencrypt/live/combined_certs.pem
    mode http
    option forwardfor
    http-request set-header X-Forwarded-Proto https

    # Phân loại domain truy cập
    acl is_keycloak hdr(host) -i ://company.com
    acl is_powerbi  hdr(host) -i ://company.com

    use_backend keycloak_backend if is_keycloak
    use_backend powerbi_backend if is_powerbi

backend keycloak_backend
    mode http
    server keycloak_server 192.168.1.50:8080 check

backend powerbi_backend
    mode http
    # Gửi sang port 80 của Nginx nằm trên cùng VM với Keycloak
    server nginx_proxy_server 192.168.1.50:80 check
```

## 2. Cấu hình Nginx tích hợp OpenID Connect trên VM Ubuntu Keycloak
Do Nginx cần xử lý tính năng OpenID Connect với Keycloak qua mã Lua, cách cài đặt sạch sẽ và ổn định nhất trên Ubuntu 24.04 là sử dụng OpenResty (Nginx đóng gói sẵn các module Lua hiệu năng cao).
Bước 2.1: Cài đặt OpenResty và các thư viện OIDC

# Thêm repository của OpenResty:

```
sudo apt install -y gettext-base lsb-release pubkeyheading
wget -qO - https://openresty.org | sudo apt-key add -
sudo add-apt-repository -y "deb http://openresty.org $(lsb_release -sc) main"
sudo apt update
sudo apt install -y openresty luarocks
# Cài đặt thư viện xử lý JWT và OpenID Connect từ Lurarocks
sudo luarocks install lua-resty-openidc
```
## Bước 2.2: Cấu hình OpenResty (Nginx) làm cổng trung gian cho Power BI
Mở file cấu hình /etc/openresty/nginx.conf (hoặc tạo file site mới trong sites-enabled) và thiết lập như sau để chặn truy cập, ép xác thực qua Keycloak nội bộ trước khi đẩy về Windows Server:

```
events {
    worker_connections 1024;
}

http {
    # Cấu hình vùng lưu trữ Session mã hóa cho người dùng ngoài Internet
    lua_shared_dict discovery 1m;
    lua_shared_dict jwks 1m;

    # Cấu hình DNS Server nội bộ hoặc Google để Lua phân giải Domain Keycloak
    resolver 8.8.8.8 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    server {
        listen 80; # Lắng nghe HTTP từ HAProxy chuyển xuống
        server_name ://company.com;

        # Bảo mật: Chỉ chấp nhận các request đi qua HAProxy
        # set_real_ip_from 192.168.1.20; # Điền IP của VM HAProxy nếu muốn filter chặt chẽ
        
        location / {
            access_by_lua_block {
                local opts = {
                    -- Gọi trực tiếp Keycloak qua localhost để đảm bảo tốc độ và bảo mật bí mật (Secret)
                    discovery = "http://127.0.0",
                    client_id = "powerbi-gateway",
                    client_secret = "Mã_Client_Secret_Sao_Chép_Từ_Keycloak",
                    
                    -- URL chuyển hướng mà Client trình duyệt sẽ gọi lại sau khi login thành công ở Keycloak
                    redirect_uri = "https://://company.com/redirect_uri",
                    
                    ssl_verify = "no", -- Vì gọi nội bộ localhost qua http nên không cần check SSL
                    scope = "openid profile",
                    logout_path = "/logout",
                    redirect_uri_x_forwarded_proto = "https" -- Ép Lua hiểu luồng ngoài là HTTPS
                }

                -- Thực hiện hành động chặn để kiểm tra Xác thực
                local res, err = require("resty.openidc").authenticate(opts)
                
                if err then
                    ngx.status = 500
                    ngx.say("Lỗi hệ thống xác thực tập trung: ", err)
                    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                end

                -- ĐỌC ĐỊNH DANH: Lấy Username từ AD1 đã được Keycloak chứng thực thành công
                -- Thường thuộc tính này trong Token là 'preferred_username' hoặc 'sAMAccountName'
                local username = res.user.preferred_username
                
                -- GÁN HEADER BẢO MẬT: Chuyển tiếp định danh xuống cho Windows Server 2019 xử lý
                ngx.req.set_header("X-MS-Authenticated-User", username)
            }

            # Đẩy luồng dữ liệu sạch đã được xác thực về máy chủ Windows chứa Power BI PBIRS
            proxy_pass http://192.168.1.100:80; # IP máy chủ Windows Server 2019
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            
            # Tối ưu hóa Buffer cho Power BI Report Server (Tránh lỗi tải báo cáo lớn bị ngắt quãng)
            proxy_buffer_size          128k;
            proxy_buffers              4 256k;
            proxy_busy_buffers_size    256k;
        }
    }
}
```
Kích hoạt và khởi động dịch vụ Nginx (OpenResty):

```
sudo systemctl enable openresty
sudo systemctl restart openresty
```

------------------------------
## Tóm tắt các việc cần triển khai tiếp theo
Hạ tầng của bạn hiện tại đã phân lớp rất rõ ràng và chuẩn bảo mật Defense-in-Depth (Bảo vệ nhiều lớp). HAProxy chịu tải SSL ở biên ➔ Nginx/OpenResty xử lý logic OIDC nội bộ bảo mật ➔ Keycloak kết nối AD1 lấy tài khoản và ép OTP.

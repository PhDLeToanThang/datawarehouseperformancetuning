# Tạo REST API và Trang Web trực tiếp từ SQL Server

## Phần 1. SQL Server 2025

**Người soạn:** PhD. Lê Toàn Thắng.

**Ngày viết:** 11/12/2025.

---

#### **Giới thiệu**

Trong thế giới ngày nay, dữ liệu là vua. Các công ty thu thập và lưu trữ một lượng dữ liệu khổng lồ trong các cơ sở dữ liệu của họ. Một trong những thách thức lớn nhất là làm thế nào để cung cấp (expose) dữ liệu đó cho các ứng dụng và người dùng khác nhau theo một cách an toàn và hiệu quả. API REST (Representational State Transfer) đã trở thành cách tiếp cận tiêu chuẩn để xây dựng các dịch vụ web cho phép các ứng dụng khác nhau giao tiếp với nhau.

![image](https://github.com/PhDLeToanThang/datawarehouseperformancetuning/tree/master/Rest_APIs_from_SQL/Google_AI_Studio_2025-12-11T03_30_26.807Z.png)

Nhưng nếu bạn có thể tạo REST API và thậm chí cả các trang web trực tiếp từ bên trong SQL Server mà không cần một lớp ứng dụng trung gian (middle-tier application) thì sao? Trong bài viết này, chúng ta sẽ khám phá một tính năng mạnh mẽ của SQL Server cho phép bạn làm chính điều đó.

#### **API REST là gì?**

API REST là một kiểu kiến trúc phần mềm để xây dựng các dịch vụ web. Một dịch vụ web RESTful sử dụng các phương thức HTTP (GET, POST, PUT, DELETE) để thực hiện các thao tác trên các tài nguyên (resources). Các tài nguyên này được xác định bằng các URI (Uniform Resource Identifiers). API REST thường trả về dữ liệu ở định dạng JSON, vốn rất nhẹ và dễ dàng phân tích cú pháp (parse) bởi hầu hết các ngôn ngữ lập trình.

Dưới đây là một ví dụ về một yêu cầu GET đến một API REST để lấy thông tin về một sản phẩm cụ thể:

```
GET https://api.example.com/products/123
```

Phản hồi có thể là một đối tượng JSON như sau:

```json
{
  "id": 123,
  "name": "Laptop Pro",
  "price": 1299.99,
  "inStock": true
}
```

#### **Trang Web là gì?**

Một trang web là một tài liệu được viết bằng HTML (HyperText Markup Language) và có thể được truy cập thông qua một trình duyệt web trên internet. Các trang web có thể chứa văn bản, hình ảnh, video và các yếu tố đa phương tiện khác. Chúng thường được sử dụng để hiển thị thông tin cho người dùng cuối.

#### **Tại sao nên tạo REST API hoặc Trang Web từ bên trong SQL Server?**

Bạn có thể tự hỏi tại sao lại muốn tạo API hoặc trang web trực tiếp từ SQL Server thay vì sử dụng một lớp ứng dụng trung gian truyền thống. Dưới đây là một vài lý do:

1.  **Đơn giản hóa việc phát triển:** Đối với các tác vụ đơn giản, bạn có thể tránh được sự phức tạp của việc xây dựng và duy trì một ứng dụng riêng biệt.
2.  **Giảm độ trễ (Latency):** Bằng cách loại bỏ lớp ứng dụng trung gian, bạn có thể giảm độ trễ mạng giữa máy chủ ứng dụng và máy chủ cơ sở dữ liệu, đặc biệt khi chúng ở các vị trí khác nhau.
3.  **Tận dụng logic hiện có:** Bạn có thể sử dụng lại các stored procedure và các logic nghiệp vụ đã có trong SQL Server của mình.
4.  **Giảm thiểu bề mặt tấn công:** Với ít thành phần hơn để quản lý, bạn có thể giảm thiểu tổng thể bề mặt tấn công tiềm năng.

#### **Tính năng của SQL Server để tạo REST API và Trang Web**

SQL Server (cụ thể là **Azure SQL Edge** và **SQL Server 2022**) cung cấp một tính năng cho phép bạn tạo các HTTP endpoint trực tiếp trong cơ sở dữ liệu. Tính năng này cho phép bạn ánh xạ một URL đến một stored procedure cụ thể. Stored procedure này sau đó có thể trả về dữ liệu ở định dạng JSON (cho API) hoặc HTML (cho trang web).

Tính năng này được tạo ra bằng cách sử dụng câu lệnh `CREATE ENDPOINT` cùng với các stored procedure liên quan.

> **Lưu ý quan trọng:** Tính năng này chủ yếu có sẵn trong Azure SQL Edge và SQL Server 2022. Nó không có sẵn trong các phiên bản SQL Server cũ hơn như 2017 hoặc 2019.

#### **Tạo REST API bằng T-SQL**

Hãy xem một ví dụ về cách tạo một REST API đơn giản trả về danh sách khách hàng dưới dạng JSON.

**Bước 1: Tạo một stored procedure để trả về JSON**

Đầu tiên, chúng ta cần một stored procedure sẽ truy vấn dữ liệu và trả về nó dưới dạng một chuỗi JSON.

```sql
CREATE PROCEDURE dbo.GetCustomersAsJson
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sử dụng FOR JSON AUTO để định dạng kết quả truy vấn thành JSON
    SELECT 
        CustomerID,
        CompanyName,
        ContactName,
        City,
        Country
    FROM 
        dbo.Customers
    FOR JSON AUTO;
END
GO
```

**Bước 2: Tạo HTTP Endpoint**

Bây giờ, chúng ta sẽ tạo một HTTP endpoint ánh xạ một URL đến stored procedure vừa tạo.

```sql
-- Xóa endpoint nếu nó đã tồn tại
IF EXISTS (SELECT * FROM sys.endpoints WHERE name = N'CustomerAPIEndpoint')
    DROP ENDPOINT [CustomerAPIEndpoint];
GO

-- Tạo endpoint mới
CREATE ENDPOINT [CustomerAPIEndpoint]
STATE = STARTED -- Bắt đầu endpoint ngay lập tức
AS HTTP(
    PATH = '/sql/customers', -- Đường dẫn cho API
    AUTHENTICATION = (INTEGRATED), -- Sử dụng xác thực Windows
    PORTS = (CLEAR), -- Lắng nghe trên cổng HTTP rõ ràng (mặc định là 80)
    SITE = '*' -- Lắng nghe trên tất cả các địa chỉ IP của máy chủ
)
FOR SOAP
(
    WEBMETHOD 'GetCustomers'
        (NAME = 'AdventureWorks2019.dbo.GetCustomersAsJson'), -- Ánh xạ đến stored procedure
    BATCHES = DISABLED, -- Vô hiệu hóa các yêu cầu hàng loạt (ad-hoc queries)
    WSDL = DEFAULT -- Tạo WSDL mặc định
);
GO
```

**Giải thích:**

*   `CREATE ENDPOINT [CustomerAPIEndpoint]`: Tạo một endpoint mới tên là `CustomerAPIEndpoint`.
*   `STATE = STARTED`: Endpoint sẽ hoạt động ngay sau khi được tạo.
*   `AS HTTP(...)`: Cấu hình các cài đặt HTTP.
*   `PATH = '/sql/customers'`: Đây là đường dẫn sẽ được sử dụng trong URL.
*   `AUTHENTICATION = (INTEGRATED)`: Yêu cầu xác thực Windows.
*   `FOR SOAP(...)`: Mặc dù chúng ta đang xây dựng một API REST, tính năng này trong SQL Server được xây dựng dựa trên nền tảng của các endpoint SOAP. Chúng ta sẽ sử dụng nó để gọi stored procedure của mình.
*   `WEBMETHOD 'GetCustomers'`: Định nghĩa một phương thức web có tên `GetCustomers`.
*   `NAME = 'AdventureWorks2019.dbo.GetCustomersAsJson'`: Ánh xạ phương thức web `GetCustomers` đến stored procedure `GetCustomersAsJson` trong database `AdventureWorks2019`.

#### **Kiểm tra REST API**

Bây giờ bạn có thể kiểm tra API bằng cách sử dụng một công cụ như `curl` hoặc trình duyệt web.

Mở một trình duyệt và điều hướng đến URL sau (thay thế `your_server_name` bằng tên máy chủ của bạn):

```
http://your_server_name/sql/customers?op=GetCustomers
```

*   `your_server_name`: Tên hoặc địa chỉ IP của máy chủ SQL của bạn.
*   `/sql/customers`: Đường dẫn mà chúng ta đã định nghĩa trong endpoint.
*   `?op=GetCustomers`: Tham số này chỉ định rằng chúng ta muốn gọi phương thức web `GetCustomers`.

Bạn sẽ thấy một phản hồi XML chứa chuỗi JSON bên trong, vì endpoint này về mặt kỹ thuật vẫn là một endpoint SOAP. Tuy nhiên, bạn có thể dễ dàng trích xuất phần JSON từ phản hồi này. Trong các ứng dụng thực tế, bạn sẽ cần một lớp trung gian nhỏ để xử lý phản hồi SOAP và chỉ trả về phần JSON cho client, hoặc bạn có thể cấu hình client của mình để xử lý nó.

**Phản hồi mẫu:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCustomersResponse xmlns="http://tempuri.org/">
      <GetCustomersResult>
        [{"CustomerID":"ALFKI","CompanyName":"Alfreds Futterkiste","ContactName":"Maria Anders","City":"Berlin","Country":"Germany"}, ...]
      </GetCustomersResult>
    </GetCustomersResponse>
  </soap:Body>
</soap:Envelope>
```

#### **Tạo Trang Web bằng T-SQL**

Quá trình tạo một trang web rất giống. Sự khác biệt chính là stored procedure sẽ trả về HTML thay vì JSON.

**Bước 1: Tạo một stored procedure để trả về HTML**

```sql
CREATE PROCEDURE dbo.GetCustomersAsHtml
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX) = N'';
    
    -- Xây dựng chuỗi HTML
    SET @html = N'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Danh sách Khách hàng</title>
        <style>
            table { font-family: sans-serif; border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h1>Danh sách Khách hàng</h1>
        <table>
            <tr>
                <th>ID</th>
                <th>Tên công ty</th>
                <th>Tên liên hệ</th>
                <th>Thành phố</th>
                <th>Quốc gia</th>
            </tr>';

    -- Thêm các dòng dữ liệu vào bảng
    SELECT 
        @html = @html + 
        N'<tr>
            <td>' + CustomerID + N'</td>
            <td>' + CompanyName + N'</td>
            <td>' + ContactName + N'</td>
            <td>' + City + N'</td>
            <td>' + Country + N'</td>
         </tr>'
    FROM dbo.Customers;

    SET @html = @html + N'
        </table>
    </body>
    </html>';

    -- Trả về chuỗi HTML
    SELECT @html AS HtmlContent;
END
GO
```

**Bước 2: Tạo HTTP Endpoint cho Trang Web**

Tương tự như trước, chúng ta tạo một endpoint mới.

```sql
IF EXISTS (SELECT * FROM sys.endpoints WHERE name = N'CustomerWebPageEndpoint')
    DROP ENDPOINT [CustomerWebPageEndpoint];
GO

CREATE ENDPOINT [CustomerWebPageEndpoint]
STATE = STARTED
AS HTTP(
    PATH = '/web/customers',
    AUTHENTICATION = (INTEGRATED),
    PORTS = (CLEAR),
    SITE = '*'
)
FOR SOAP
(
    WEBMETHOD 'GetCustomersPage'
        (NAME = 'AdventureWorks2019.dbo.GetCustomersAsHtml'),
    BATCHES = DISABLED,
    WSDL = DEFAULT
);
GO
```

#### **Kiểm tra Trang Web**

Mở trình duyệt và truy cập URL sau:

```
http://your_server_name/web/customers?op=GetCustomersPage
```

Lần này, bạn sẽ thấy một trang HTML được định dạng đẹp mắt hiển thị danh sách khách hàng trong một bảng. Lưu ý rằng, giống như API, phản hồi sẽ được bọc trong một vỏ bọc SOAP, nhưng trình duyệt hiện đại thường đủ thông minh để hiển thị nội dung HTML bên trong.

#### **Các cân nhắc về Bảo mật**

Khi tạo các endpoint trực tiếp trong SQL Server, bạn cần cực kỳ cẩn thận về bảo mật:

*   **Nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege):** Tài khoản đăng nhập (login) được sử dụng để thực thi stored procedure chỉ nên có các quyền cần thiết tối thiểu. Không cấp quyền `sysadmin` hoặc `db_owner` nếu không cần thiết.
*   **SQL Injection:** Hãy luôn sử dụng các tham số hóa (parameterized queries) trong các stored procedure của bạn để ngăn chặn các tấn công SQL Injection.
*   **HTTPS:** Trong môi trường sản xuất, hãy luôn sử dụng HTTPS (SSL/TLS) để mã hóa dữ liệu truyền giữa client và server. Điều này đòi hỏi phải cấu hình một chứng chỉ SSL trên endpoint.
*   **Tường lửa (Firewall):** Sử dụng tường lửa để giới hạn truy cập vào các cổng mà các endpoint của bạn đang lắng nghe.

#### **Hạn chế**

Đây là một tính năng mạnh mẽ, nhưng nó có một số hạn chế:

*   **Không phải là một framework REST đầy đủ:** Tính năng này không phải là một framework REST hoàn chỉnh. Nó không hỗ trợ các tính năng nâng cao như định tuyến (routing) phức tạp, quản lý phiên (session management), hoặc các tiêu đề HTTP tùy chỉnh một cách dễ dàng.
*   **Phức tạp trong việc gỡ lỗi (Debugging):** Gỡ lỗi các vấn đề có thể khó khăn hơn so với một lớp ứng dụng truyền thống.
*   **Kiểm soát phiên bản (Versioning):** Quản lý các phiên bản khác nhau của API có thể phức tạp.
*   **Vẫn dựa trên nền tảng SOAP:** Như đã thấy, các phản hồi được bọc trong SOAP, điều này có thể không lý tưởng cho các client thuần REST.

#### **Kết luận**

Khả năng tạo REST API và trang web trực tiếp từ SQL Server là một công cụ hữu ích cho các kịch bản cụ thể, nơi bạn cần nhanh chóng cung cấp dữ liệu mà không muốn xây dựng một ứng dụng đầy đủ. Nó đặc biệt hữu ích cho các công việc nội bộ, các nguyên mẫu (prototypes) hoặc khi bạn muốn tận dụng tối đa các stored procedure hiện có.

Tuy nhiên, đối với các ứng dụng phức tạp, quy mô lớn hoặc các API công khai, một lớp ứng dụng trung gian được xây dựng bằng các công nghệ như ASP.NET Core, Node.js hoặc Python vẫn là lựa chọn được khuyến nghị vì tính linh hoạt, bảo mật và khả năng bảo trì vượt trội. Hiểu rõ cả hai cách tiếp cận sẽ giúp bạn chọn đúng công cụ cho đúng công việc.

---

## Phần 2. Các cách dựng phần Rest API từ các máy chủ Microsoft SQL phiên bản 2017,2019,2022: 
***(Lịch sử truy cập API REST và các trang web từ SQL Server 2017,2019,2022)***

Đây là một câu hỏi rất thực tế. Để xây dựng API REST cho Microsoft SQL Server (phiên bản 2017, 2019, 2022) và quản lý lịch sử truy cập, có nhiều cách tiếp cận khác nhau, từ tiêu chuẩn, an toàn cho đến các cách trực tiếp hơn nhưng có thể không phù hợp cho môi trường production.

Đầu tiên, cần làm rõ một điểm quan trọng: **SQL Server không có một tính năng dựng sẵn (built-in) "one-click" để tạo REST API** một cách đơn giản như một số hệ cơ sở dữ liệu khác (ví dụ: PostgREST cho PostgreSQL). Thay vào đó, chúng ta cần sử dụng một lớp ứng dụng trung gian (middle-tier application) hoặc các kỹ thuật nâng cao hơn.

Dưới đây là các phương án phổ biến và được khuyến nghị, từ tốt nhất đến ít phổ biến hơn.

---

### Phương án 1: Xây dựng một Ứng dụng Middle-Tier (Khuyến nghị mạnh mẽ)

Đây là cách tiếp cận tiêu chuẩn, linh hoạt và an toàn nhất. Bạn sẽ tạo một ứng dụng web riêng biệt (API Layer) hoạt động như một "cầu nối" giữa thế giới bên ngoài (web, mobile app) và cơ sở dữ liệu SQL Server của bạn.

#### Cách hoạt động:
1.  **Client** (trang web, ứng dụng di động) gửi một yêu cầu HTTP (GET, POST, PUT, DELETE) đến một **API Endpoint** (ví dụ: `https://api.yourcompany.com/products`).
2.  **Ứng dụng Middle-Tier** của bạn (chạy trên một web server) nhận yêu cầu này.
3.  Nó thực hiện các logic nghiệp vụ (kiểm tra xác thực, phân quyền, validate dữ liệu).
4.  Kết nối an toàn đến **SQL Server**, thực thi một truy vấn hoặc stored procedure.
5.  Nhận dữ liệu từ SQL Server, định dạng nó thành **JSON**.
6.  Gửi phản hồi JSON ngược lại cho client.

#### Các công nghệ phổ biến để xây dựng Middle-Tier:
*   **ASP.NET Core (C#):** Đây là lựa chọn "tự nhiên" nhất trong hệ sinh thái Microsoft. Nó hiệu năng cao, bảo mật tốt và tích hợp hoàn hảo với SQL Server (thông qua Entity Framework Core hoặc ADO.NET).
*   **Node.js (với Express/Fastify):** Rất phổ biến, nhẹ và nhanh. Sử dụng các thư viện như `mssql`, `sequelize` để kết nối đến SQL Server.
*   **Python (với Flask/Django):** Lựa chọn tuyệt vời, đặc biệt nếu bạn đã quen với Python và các thư viện phân tích dữ liệu. Kết nối qua `pyodbc` hoặc `SQLAlchemy`.
*   **Java (với Spring Boot):** Rất mạnh mẽ và bền bỉ, thường được dùng trong các doanh nghiệp lớn.

#### Xử lý "Lịch sử truy cập API" với phương án này:
Đây là nơi phương án này thể hiện sự vượt trội.
1.  **Tạo một bảng trong SQL Server** để lưu log, ví dụ: `ApiAccessLogs`.
    ```sql
    CREATE TABLE dbo.ApiAccessLogs (
        LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
        RequestTime DATETIME2 DEFAULT GETUTCDATE(),
        Endpoint NVARCHAR(255),
        HttpMethod NVARCHAR(10),
        UserIdentifier NVARCHAR(255), -- UserID hoặc API Key
        ClientIP NVARCHAR(45),
        RequestParams NVARCHAR(MAX), -- JSON string
        ResponseStatusCode INT,
        ExecutionTimeMs INT
    );
    ```
2.  Trong ứng dụng Middle-Tier của bạn, tại mỗi API endpoint, bạn sẽ thêm một **middleware** hoặc một đoạn code để ghi lại thông tin yêu cầu vào bảng `ApiAccessLogs` *trước khi* gửi phản hồi cho client.
3.  Để xem lịch sử truy cập, bạn chỉ cần tạo một API endpoint khác (ví dụ: `/api/admin/logs`) được bảo vệ, chỉ dành cho admin. Endpoint này sẽ truy vấn dữ liệu từ bảng `ApiAccessLogs` và trả về.

**Ưu điểm:**
*   **Bảo mật:** Tách biệt hoàn toàn cơ sở dữ liệu khỏi Internet. Client không bao giờ kết nối trực tiếp đến SQL Server.
*   **Linh hoạt:** Dễ dàng triển khai logic nghiệp vụ phức tạp, xác thực, phân quyền, giới hạn tốc độ (rate limiting).
*   **Khả năng mở rộng:** Bạn có thể mở rộng (scale) lớp API độc lập với cơ sở dữ liệu.
*   **Kiểm soát hoàn toàn:** Bạn kiểm soát 100% logic, bao gồm cả việc ghi log truy cập.

---

### Phương án 2: Sử dụng tính năng Native của SQL Server 2022 (Hạn chế cho 2017/2019)

Bắt đầu từ **SQL Server 2022**, Microsoft đã giới thiệu một tính năng cho phép tạo REST API endpoints trực tiếp trong database. Tính năng này trước đây chỉ có trên Azure SQL.

> **Lưu ý quan trọng:** **Tính năng này KHÔNG có sẵn trên SQL Server 2017 và 2019.** Vì vậy, nếu bạn đang dùng các phiên bản này, phương án này không thể áp dụng.

#### Cách hoạt động (trên SQL Server 2022):
Bạn sử dụng cú pháp T-SQL `CREATE ENDPOINT` để định nghĩa các route và ánh xạ chúng đến các stored procedure.

```sql
-- Ví dụ trên SQL Server 2022
CREATE ENDPOINT [ProductsAPI]
STATE = STARTED
AS HTTP(
    PATH = '/api/products',
    AUTHENTICATION = (INTEGRATED),
    PORTS = (CLEAR),
    SITE = '*'
)
FOR TSQL
(
    -- Cấu hình các route
);
```
Sau đó, bạn tạo các stored procedure sẽ xử lý logic và trả về JSON. SQL Server sẽ tự động xử lý việc ánh xạ yêu cầu HTTP đến stored procedure tương ứng.

#### Xử lý "Lịch sử truy cập" với phương án này:
Đây là một điểm yếu. Tính năng này không có một hệ thống logging truy cập API tích hợp sẵn và dễ dàng truy vấn như phương án 1. Bạn sẽ phải:
*   Tự xây dựng logic logging bên trong mỗi stored procedure. Điều này làm cho stored procedure trở nên cồng kềnh và vi phạm nguyên tắc trách nhiệm duy nhất (Single Responsibility Principle).
*   Hoặc sử dụng các tính năng audit chung của SQL Server như SQL Server Audit hoặc Extended Events, việc này phức tạp hơn và không tập trung vào ngữ cảnh của API.

**Ưu điểm:**
*   Đơn giản cho các kịch bản CRUD cơ bản, không cần lớp ứng dụng trung gian.

**Nhược điểm:**
*   **Không khả dụng cho 2017/2019.**
*   Ít linh hoạt hơn rất nhiều so với middle-tier.
*   Khó triển khai logic nghiệp vụ phức tạp, xác thực, phân quyền.
*   **Rất khó để quản lý lịch sử truy cập một cách hiệu quả.**

---

### Phương án 3: Sử dụng các công cụ tạo API tự động (Low-Code/No-Code)

Có một số công cụ của bên thứ ba có thể kết nối đến cơ sở dữ liệu của bạn và tự động sinh ra các REST API endpoint dựa trên cấu trúc bảng (CRUD operations - Create, Read, Update, Delete).

#### Ví dụ các công cụ:
*   DreamFactory
*   Directus
*   Retool
*   Supabase (chủ yếu cho PostgreSQL nhưng có thể kết nối các DB khác)

#### Cách hoạt động:
1.  Bạn cung cấp chuỗi kết nối đến SQL Server của bạn cho công cụ này.
2.  Công cụ sẽ "quét" schema (các bảng, cột, quan hệ).
3.  Nó tự động tạo ra các API endpoint như `/users`, `/products`, `/orders`...
4.  Bạn có thể tùy chỉnh các endpoint, thêm quyền truy cập, và đôi khi là cả logic tùy chỉnh.

#### Xử lý "Lịch sử truy cập":
Hầu hết các công cụ này đều có tính năng logging và audit request được tích hợp sẵn. Bạn có thể bật tính năng này và xem lịch sử truy cập trên giao diện quản trị của chúng, hoặc chúng có thể ghi log vào một bảng trong chính cơ sở dữ liệu của bạn.

**Ưu điểm:**
*   **Rất nhanh:** Có thể tạo API trong vài phút.
*   **Dễ dàng:** Không cần nhiều code.

**Nhược điểm:**
*   **Ít linh hoạt:** Khó triển khai các logic nghiệp vụ phức tạp.
*   **Chi phí:** Các công cụ này thường là trả phí.
*   **Bảo mật:** Cần cấu hình cẩn thận để không vô tình tiết lộ quá nhiều dữ liệu.

---

### Bảng so sánh và Khuyến nghị cuối cùng

| Tiêu chí | Phương án 1: Middle-Tier App | Phương án 2: Native SQL 2022 | Phương án 3: Low-Code Tool |
| :--- | :--- | :--- | :--- |
| **Khuyến nghị** | **Rất cao** | Trung bình (chỉ cho 2022) | Trung bình |
| **Bảo mật** | Rất cao | Trung bình | Trung bình (phụ thuộc cấu hình) |
| **Linh hoạt** | Rất cao | Thấp | Thấp |
| **Hiệu năng** | Rất cao (có thể scale) | Trung bình | Trung bình |
| **Tốc độ phát triển** | Trung bình | Nhanh (cho CRUD đơn giản) | Rất nhanh |
| **Chi phí** | Thấp (mã nguồn mở) | Thấp (có trong license) | Trung bình - Cao (phần mềm) |
| **Logging truy cập** | **Rất dễ dàng và tùy biến** | Rất khó | Dễ dàng (tích hợp sẵn) |
| **Phù hợp nhất cho** | **Hầu hết các dự án, đặc biệt là môi trường production.** | Các API CRUD đơn giản trên SQL 2022. | Internal tools, prototype, CRUD đơn giản. |

### Kết luận

Để xây dựng API REST cho **SQL Server 2017, 2019, 2022** và quản lý lịch sử truy cập một cách chuyên nghiệp, an toàn và bền vững, bạn **nên chọn Phương án 1: Xây dựng một Ứng dụng Middle-Tier**.

Đây là giải pháp duy nhất đáp ứng đầy đủ các yêu cầu của bạn trên cả ba phiên bản SQL Server và mang lại sự kiểm soát, bảo mật và khả năng mở rộng tốt nhất. Việc ghi log lịch sử truy cập cũng trở nên cực kỳ đơn giản và tùy biến khi bạn tự kiểm soát được lớp ứng dụng.

Nếu bạn chỉ dùng **SQL Server 2022** và nhu cầu của bạn rất đơn giản (chỉ đọc/ghi dữ liệu cơ bản), bạn có thể cân nhắc Phương án 2, nhưng hãy chuẩn bị cho những hạn chế về linh hoạt và việc logging.

Nếu bạn cần một giải pháp nhanh cho công việc nội bộ, Phương án 3 là một lựa chọn khả thi.


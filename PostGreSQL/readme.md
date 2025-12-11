# Các Kiến trúc Tính Sẵn sàng Cao cho PostgreSQL

**Nguồn gốc:** https://www.cybertec-postgresql.com/en/postgresql-high-availability-architectures/
**Tiêu đề dịch:** Các Kiến trúc Tính Sẵn sàng Cao cho PostgreSQL - PostgreSQL High Availability Architectures

---

### **Giới thiệu**

Trong thế giới kỹ thuật số ngày nay, việc cơ sở dữ liệu phải luôn sẵn sàng và hoạt động là yếu tố sống còn đối với hầu hết các doanh nghiệp. Chỉ vài phút gián đoạn cũng có thể dẫn đến thiệt hại tài chính đáng kể và mất uy tín với khách hàng. **Tính sẵn sàng cao (High Availability - HA)** là một khái niệm được thiết kế để đảm bảo rằng hệ thống của bạn vẫn hoạt động ngay cả khi có thành phần gặp sự cố. Đối với PostgreSQL, việc triển khai một giải pháp HA đúng đắn là cực kỳ quan trọng.

Bài viết này sẽ đi sâu vào các kiến trúc Tính sẵn sàng cao khác nhau có sẵn cho PostgreSQL, phân tích ưu và nhược điểm của từng loại để giúp bạn lựa chọn giải pháp phù hợp nhất với nhu cầu của mình.

### **Tính Sẵn sàng Cao là gì?**

Tính Sẵn sàng cao (HA) là khả năng của một hệ thống tiếp tục hoạt động mà không bị gián đoạn trong một khoảng thời gian dài. Mục tiêu chính là loại bỏ các **điểm lỗi đơn lẻ (single points of failure)** - các thành phần mà nếu chúng bị hỏng sẽ gây ra sự cố cho toàn bộ hệ thống.

Để đo lường mức độ sẵn sàng cao, người ta thường sử dụng các "con số 9" (the nines):

*   **99%** ("hai chín"): ~3.65 ngày ngừng hoạt động mỗi năm.
*   **99.9%** ("ba chín"): ~8.76 giờ ngừng hoạt động mỗi năm.
*   **99.99%** ("bốn chín"): ~52.6 phút ngừng hoạt động mỗi năm.
*   **99.999%** ("năm chín"): ~5.26 phút ngừng hoạt động mỗi năm.

Việc lựa chọn kiến trúc HA sẽ phụ thuộc trực tiếp vào mục tiêu mức độ sẵn sàng cao mà bạn muốn đạt đến, được thể hiện qua hai chỉ số quan trọng:

*   **RPO (Recovery Point Objective - Mục tiêu Điểm Khôi phục):** Lượng dữ liệu tối đa bạn có thể chấp nhận mất khi xảy ra sự cố. RPO = 0 có nghĩa là không mất dữ liệu nào.
*   **RTO (Recovery Time Objective - Mục tiêu Thời gian Khôi phục):** Thời gian tối đa mà hệ thống có thể bị ngừng hoạt động sau khi xảy ra sự cố.

### **Các Kiến trúc Tính Sẵn sàng Cao cho PostgreSQL**

Không có một giải pháp HA nào phù hợp cho tất cả mọi người. Việc lựa chọn phụ thuộc vào ngân sách, độ phức tạp có thể chấp nhận, và các yêu cầu về RPO/RTO. Dưới đây là các kiến trúc phổ biến nhất.

#### **1. Sao chép Luồng (Streaming Replication)**

Đây là kiến trúc HA phổ biến và được khuyến nghị nhất cho PostgreSQL.

*   **Cách hoạt động:** Một máy chủ **chính (primary)** xử lý tất cả các thao tác ghi (write). Các thay đổi này được gửi đến một hoặc nhiều máy chủ **bản sao (replica/standby)** ở gần như thời gian thực. Các máy chủ bản sao áp dụng các thay đổi này, tạo ra một bản sao gần như giống hệt của cơ sở dữ liệu chính.
*   **Chuyển đổi dự phòng (Failover):** Khi máy chủ chính gặp sự cố, một trong các máy chủ bản sao sẽ được **thúc đẩy (promoted)** lên thành máy chủ chính mới. Ứng dụng sẽ được cấu hình để kết nối đến máy chủ chính mới này.
*   **Sao chép Đồng bộ vs. Không đồng bộ:**
    *   **Không đồng bộ (Asynchronous):** Mặc định và phổ biến nhất. Máy chủ chính xác nhận giao dịch mà không cần chờ máy chủ bản sao xác nhận đã nhận và áp dụng. Điều này mang lại hiệu suất cao nhất nhưng có nguy cơ mất dữ liệu (RPO > 0) nếu máy chủ chính đột ngột hỏng.
    *   **Đồng bộ (Synchronous):** Máy chủ chính chỉ xác nhận giao dịch sau khi ít nhất một máy chủ bản sao đã xác nhận việc ghi dữ liệu vào đĩa. Điều này đảm bảo RPO = 0 (không mất dữ liệu) nhưng làm tăng độ trễ của giao dịch.

**Ưu điểm:**
*   Độ trễ thấp, gần như thời gian thực.
*   Cấu hình tương đối đơn giản.
*   Hỗ trợ sẵn có trong PostgreSQL.

**Nhược điểm:**
*   Trong chế độ không đồng bộ, có nguy cơ mất dữ liệu.
*   Quá trình chuyển đổi dự phòng thường cần được tự động hóa bằng các công cụ bên ngoài.

#### **2. Sử dụng Công cụ Quản lý Chuyển đổi dự phòng (Failover Management Tools)**

Sao chép luồng chỉ cung cấp cơ chế sao chép dữ liệu. Nó không tự động hóa việc phát hiện lỗi và chuyển đổi dự phòng. Đây là lúc các công cụ quản lý phát huy tác dụng. Các công cụ này giám sát cụm máy chủ và tự động thực hiện chuyển đổi dự phòng khi cần thiết.

*   **Các công cụ phổ biến:**
    *   **Patroni:** Một công cụ mạnh mẽ, sử dụng một kho lưu trữ phân tán (như etcd, Consul, ZooKeeper) để quản lý trạng thái của cụm và đảm bảo chỉ có một máy chủ chính tại một thời điểm (tránh hiện tượng "split-brain").
    *   **repmgr:** Một bộ công cụ nguồn mở để quản lý sao chép và chuyển đổi dự phòng cho PostgreSQL. Nó cung cấp các lệnh tiện lợi để thiết lập, giám sát và thúc đẩy máy chủ bản sao.

**Ưu điểm:**
*   Tự động hóa hoàn toàn quá trình chuyển đổi dự phòng, giảm RTO.
*   Ngăn chặn hiện tượng "split-brain", đảm bảo tính toàn vẹn dữ liệu.
*   Cung cấp các tính năng giám sát và quản lý cụm.

**Nhược điểm:**
*   Thêm một thành phần khác vào hệ thống, làm tăng độ phức tạp.
*   Đòi hỏi kiến thức để cài đặt và vận hành đúng cách.

#### **3. Kiến trúc Đĩa Chia sẻ (Shared-Disk Architecture)**

Trong kiến trúc này, tất cả các nút (máy chủ) trong cụm chia sẻ cùng một thiết bị lưu trữ chung (ví dụ: một SAN - Storage Area Network). Tại một thời điểm, chỉ có một nút có quyền truy cập đọc/ghi vào cơ sở dữ liệu. Các nút khác ở chế độ chờ.

*   **Cách hoạt động:** Khi nút hoạt động gặp sự cố, một cơ chế khác (ví dụ: một trình quản lý cụm như Pacemaker) sẽ cấp quyền truy cập đĩa cho một nút dự phòng. Nút này sau đó khởi động PostgreSQL và trở thành máy chủ chính mới.

**Ưu điểm:**
*   Không có độ trễ sao chép dữ liệu vì tất cả các nút đều truy cập cùng một dữ liệu. RPO = 0.
*   Việc chuyển đổi dự phòng có thể rất nhanh.

**Nhược điểm:**
*   Hệ thống lưu trữ chia sẻ trở thành một điểm lỗi đơn lẻ và rất tốn kém.
*   Cấu hình phức tạp hơn nhiều so với sao chép luồng.
*   Ít phổ biến hơn và đòi hỏi chuyên môn cao về cả cơ sở dữ liệu và lưu trữ.

#### **4. Sao chép Logic (Logical Replication)**

Đây là một cơ chế sao chép khác, hoạt động ở cấp độ cao hơn so với sao chép luồng (streaming replication).

*   **Cách hoạt động:** Thay vì gửi các bản ghi WAL (Write-Ahead Log), nó gửi các thay đổi dữ liệu ở cấp độ bảng (ví dụ: các lệnh `INSERT`, `UPDATE`, `DELETE`). Nó cho phép bạn sao chép chỉ một số bảng nhất định và thậm chí có thể viết lại dữ liệu trên máy chủ bản sao.

**Ưu điểm:**
*   Linh hoạt: Có thể sao chép giữa các phiên bản PostgreSQL khác nhau (với một số giới hạn).
*   Có thể chọn lọc dữ liệu hoặc bảng cần sao chép.
*   Hữu ích cho các kịch bản tích hợp dữ liệu hoặc tạo các báo cáo chuyên biệt.

**Nhược điểm:**
*   Có thể có độ trễ cao hơn so với sao chép luồng.
*   Cấu hình phức tạp hơn.
*   Không phải là một giải pháp HA hoàn chỉnh cho toàn bộ cơ sở dữ liệu, thường được sử dụng kết hợp với các phương pháp khác.

### **Lựa chọn Kiến trúc Phù hợp**

Việc lựa chọn phụ thuộc vào các yếu tố sau:

*   **Ngân sách:** Các giải pháp dựa trên sao chép luồng và các công cụ nguồn mở (Patroni, repmgr) là tiết kiệm chi phí nhất. Kiến trúc đĩa chia sẻ rất tốn kém.
*   **Yêu cầu RPO/RTO:** Nếu bạn không thể chấp nhận mất bất kỳ dữ liệu nào (RPO = 0), bạn cần sao chép đồng bộ hoặc kiến trúc đĩa chia sẻ. Nếu bạn cần thời gian khôi phục nhanh (RTO thấp), bạn phải có một công cụ quản lý chuyển đổi dự phòng tự động.
*   **Độ phức tạp và Năng lực vận hành:** Nếu đội ngũ của bạn có chuyên môn về PostgreSQL và các công cụ liên quan, một giải pháp tự xây dựng với Patroni/repmgr rất mạnh mẽ. Nếu không, bạn có thể cân nhắc các giải pháp thương mại hoặc các dịch vụ quản lý cơ sở dữ liệu (Database-as-a-Service).
*   **Mục đích sử dụng:** Đối với hầu hết các ứng dụng OLTP (Online Transaction Processing), kết hợp giữa **Sao chép Luồng + Công cụ Quản lý (Patroni/repmgr)** là tiêu chuẩn vàng. Đối với các nhu cầu tích hợp dữ liệu hoặc báo cáo, **Sao chép Logic** là một sự bổ sung tuyệt vời.

### **Kết luận**

PostgreSQL cung cấp một nền tảng vững chắc để xây dựng các giải pháp Tính sẵn sàng cao mạnh mẽ. **Kiến trúc phổ biến và cân bằng nhất là sử dụng Sao chép Luồng không đồng bộ kết hợp với một công cụ quản lý chuyển đổi dự phòng như Patroni.** Giải pháp này cung cấp sự cân bằng tốt giữa hiệu suất, độ tin cậy, chi phí và độ phức tạp.

Không có một câu trả lời duy nhất cho tất cả. Hãy đánh giá cẩn thận các yêu cầu kinh doanh, kỹ thuật và ngân sách của bạn để đưa ra lựa chọn kiến trúc HA phù hợp nhất, đảm bảo rằng cơ sở dữ liệu PostgreSQL của bạn luôn sẵn sàng phục vụ khi bạn cần.
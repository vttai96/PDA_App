# API Contract (PDA Ingredient Scanning)

## Base URL
- Read from `.env`
- Example:
  - `API_BASE_URL=http://<host>:<port>`

## Common Response Envelope

### Success
```json
{
  "Message": "Success",
  "Data": {}
}
```

### Fail
```json
{
  "Message": "Fail",
  "Error": "Error detail"
}
```

---

## 1) POST `/getTankInfo`
### Chức năng
Giải mã thông tin định danh của bồn chứa từ số hiệu bồn được quét.

### Request
```json
{
  "TankNumber": "T05T01"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "ProductionOrder": "PO-20260314-001",
    "BatchNumber": "BATCH-T05T01-01",
    "RecipeName": "IND_SOLVENT_A",
    "RecipeVersion": "2.3",
    "ProductCode": "PRD-ACETONE-A",
    "ProductName": "Industrial Solvent A",
    "Shift": "A",
    "PlannedStart": "2026-03-15T06:00:00Z"
  }
}
```

---

## 2) POST `/getRecipeDetails`
### Chức năng
Lấy danh sách nguyên liệu theo `ProductionOrder` (Lệnh sản xuất) và `BatchNumber` (Số lô).

### Request
```json
{
  "ProductionOrder": "PO-20260314-001",
  "BatchNumber": "BATCH-T05T01-01"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "ingredients": [
      {
        "IngredientCode": "ING-001",
        "IngredientName": "Acetone",
        "Quantity": 50.0,
        "UnitOfMeasurement": "Kgs"
      },
      {
        "IngredientCode": "ING-002",
        "IngredientName": "Ethanol",
        "Quantity": 12.0,
        "UnitOfMeasurement": "Kgs"
      }
    ]
  }
}
```

---

## 3) POST `/ingredient-scan/complete`
### Chức năng
Được gọi khi một nguyên liệu đạt đến mục tiêu trong khoảng mức sai số cho phép (`target ± 0.1kg`).
Server sẽ lưu lại tất cả các bản ghi quét của nguyên liệu đó cho bồn chứa này.

### Request
```json
{
  "TankNumber": "T05T01",
  "ProductionOrder": "PO-20260314-001",
  "BatchNumber": "BATCH-T05T01-01",
  "IngredientCode": "ING-001",
  "IngredientName": "Acetone",
  "TargetQty": 50.0,
  "ActualQty": 49.95,
  "Scans": [
    {
      "ItemCode": "ING-001",
      "Weight": 20.0,
      "Lot": "LOT-20260315-01",
      "WeightBatch": "CAN001",
      "LabelId": "LBL0001",
      "ScannedAt": "2026-03-15T08:31:15.123Z"
    },
    {
      "ItemCode": "ING-001",
      "Weight": 29.95,
      "Lot": "LOT-20260315-01",
      "WeightBatch": "CAN002",
      "LabelId": "LBL0002",
      "ScannedAt": "2026-03-15T08:34:11.010Z"
    }
  ]
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "IngredientCode": "ING-001",
    "SavedScanCount": 2,
    "AcceptedQty": 49.95
  }
}
```

---

## 4) POST `/tank-transfer/complete`
### Chức năng
Được gọi khi người dùng xác nhận hoàn thành quá trình chuyển bồn sau khi tất cả nguyên liệu đã hoàn tất.

### Request
```json
{
  "TankNumber": "T05T01",
  "ProductionOrder": "PO-20260314-001",
  "BatchNumber": "BATCH-T05T01-01",
  "Status": "Completed",
  "CompletedAt": "2026-03-15T09:05:00.000Z"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "TankNumber": "T05T01",
    "Status": "Completed"
  }
}
```

### Fail Response (example)
```json
{
  "Message": "Fail",
  "Error": "Endpoint /tank-transfer/complete not found"
}
```

---

## 5) (Future) POST `/label/check`
### Chức năng
API tùy chọn trong tương lai để xác thực xem một `LabelId` đã từng được quét trước đó hay chưa (xuyên bồn chứa, xuyên ca làm việc, v.v.).
App hiện tại vẫn đang tự chặn trùng lặp mã tem thông qua bộ nhớ cục bộ.

### Suggested Request
```json
{
  "LabelId": "LBL0002",
  "TankNumber": "T05T01",
  "ProductionOrder": "PO-20260314-001",
  "BatchNumber": "BATCH-T05T01-01"
}
```

### Suggested Success Response
```json
{
  "Message": "Success",
  "Data": {
    "AlreadyUsed": false,
    "LastUsedAt": null
  }
}
```

---

## 6) POST `/users/list`
### Function
Lấy danh sách user cho màn hình login.

### Request
```json
{
  "Shift": "Ca1"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "Users": [
      {
        "UserId": "U1001",
        "UserCode": "EMP1001",
        "UserName": "Nguyen Van A",
        "RoleName": "Van hanh",
        "EmployeeId": "1001",
        "RoleLevel": 100,
        "IsActive": true
      },
      {
        "UserId": "U1002",
        "UserCode": "EMP1002",
        "UserName": "Tran Thi B",
        "RoleName": "Giam sat",
        "EmployeeId": "1002",
        "RoleLevel": 9500,
        "IsActive": true
      }
    ]
  }
}
```

### Fail Response (example)
```json
{
  "Message": "Fail",
  "Error": "No active user for current shift"
}
```

---

## 7) POST `/auth/login`
### Function
Đăng nhập user bằng PIN trên màn hình login.

### Request
```json
{
  "UserId": "U1001",
  "Pin": "1234",
  "Shift": "Ca1",
  "DeviceTime": "2026-03-18T08:30:00.000Z"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "Token": "jwt-or-session-token",
    "User": {
      "UserId": "U1001",
      "UserName": "Nguyen Van A",
      "RoleName": "Van hanh",
      "RoleLevel": 100
    }
  }
}
```

### Fail Response (example)
```json
{
  "Message": "Fail",
  "Error": "Invalid pin"
}
```

### Permission note
- `RoleLevel > 9000`: user được thay đổi `API_BASE_URL` trong trang Settings.
- `RoleLevel <= 9000`: user vẫn vào trang Settings được, nhưng ẩn khu vực cài đặt `API_BASE_URL`.

---

## 8) POST `/history/search`
### Function
Lấy danh sách lịch sử dữ liệu cho trang lịch sử. Hỗ trợ tra cứu toàn bộ hoặc tìm theo mã Tank / mã tem nguyên liệu.

### Request
```json
{
  "QueryType": "ALL",
  "QueryValue": "",
  "DateFrom": "",
  "DateTo": "",
  "Limit": 100
}
```

### QueryType values
- `ALL`: lấy danh sách lịch sử gần nhất.
- `TANK`: tìm theo `TankNumber` (app phân tích từ mã quét `AIT10 <TankNumber>`).
- `LABEL`: tìm theo `LabelId` (app phân tích từ mã quét `AIT01 <itemCode> <weight> <Lot> <weightBatch> <labelId>`).

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "Records": [
      {
        "RecordId": "HIS-20260318-001",
        "Title": "BATCH-T05T01-01",
        "TankNumber": "T05T01",
        "ProductionOrder": "PO-20260314-001",
        "BatchNumber": "BATCH-T05T01-01",
        "OperatorName": "Nguyen Van A",
        "Status": "Completed",
        "CompletedAt": "2026-03-18T09:05:00Z",
        "HasWarning": false
      },
      {
        "RecordId": "HIS-20260318-002",
        "Title": "BATCH-T05T01-02",
        "TankNumber": "T05T01",
        "ProductionOrder": "PO-20260314-002",
        "BatchNumber": "BATCH-T05T01-02",
        "OperatorName": "Tran Thi B",
        "Status": "Warning",
        "CompletedAt": "2026-03-18T11:20:00Z",
        "HasWarning": true
      }
    ]
  }
}
```

### Fail Response (example)
```json
{
  "Message": "Fail",
  "Error": "History data source unavailable"
}
```

---

## 9) POST `/ingredient-scan/progress`
### Function
Lấy tiến độ đã scan trước đó theo `TankNumber + ProductionOrder + BatchNumber` để app khôi phục trạng thái khi quét lại tank.

### Request
```json
{
  "TankNumber": "T05T01",
  "ProductionOrder": "PO-20260314-001",
  "BatchNumber": "BATCH-T05T01-01"
}
```

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "TankNumber": "T05T01",
    "ProductionOrder": "PO-20260314-001",
    "BatchNumber": "BATCH-T05T01-01",
    "Ingredients": [
      {
        "IngredientCode": "ING-001",
        "TargetQty": 50.0,
        "ActualQty": 32.5,
        "IsCompleted": false,
        "LastScannedAt": "2026-03-24T09:10:00Z",
        "Scans": [
          {
            "ItemCode": "ING-001",
            "Weight": 20.0,
            "Lot": "LOT-20260324-01",
            "WeightBatch": "CAN001",
            "LabelId": "LBL0001",
            "ScannedAt": "2026-03-24T08:31:15Z"
          },
          {
            "ItemCode": "ING-001",
            "Weight": 12.5,
            "Lot": "LOT-20260324-01",
            "WeightBatch": "CAN002",
            "LabelId": "LBL0002",
            "ScannedAt": "2026-03-24T09:10:00Z"
          }
        ]
      },
      {
        "IngredientCode": "ING-002",
        "TargetQty": 12.0,
        "ActualQty": 12.0,
        "IsCompleted": true,
        "LastScannedAt": "2026-03-24T09:20:00Z",
        "Scans": [
          {
            "ItemCode": "ING-002",
            "Weight": 12.0,
            "Lot": "LOT-20260324-02",
            "WeightBatch": "CAN003",
            "LabelId": "LBL0003",
            "ScannedAt": "2026-03-24T09:20:00Z"
          }
        ]
      }
    ]
  }
}
```

### Fail Response (example)
```json
{
  "Message": "Fail",
  "Error": "Progress data not found"
}
```

### Notes
- Nếu không có dữ liệu đã scan, backend trả `Message=Success` và `Ingredients: []`.
- App sẽ ghép `ActualQty` vào danh sách công thức từ `/getRecipeDetails`.
- App sẽ tự động đánh dấu item đã hoàn thành nếu `IsCompleted=true` hoặc `ActualQty` nằm trong khoảng `target ± 0.1`.

---

## Quy tắc Mã vạch (Đã xử lý trên app)

### Định dạng mã vạch bồn chứa
- `AIT10 <TankNumber>`

### Định dạng mã vạch nguyên liệu
- `AIT01 <itemCode> <weight> <Lot> <weightBatch> <labelId>`

### Luồng kiểm tra nguyên liệu
1. `itemCode` phải tồn tại trong danh sách nguyên liệu.
2. App tự động focus vào nguyên liệu khớp với `itemCode`.
3. `labelId` không được trùng lặp trong cùng một phiên quét bồn.
4. Nếu số lượng quét tích lũy của nguyên liệu:
   - `< target - 0.1`: tiếp tục quét.
   - `trong khoảng target ± 0.1`: đánh dấu hoàn thành nguyên liệu và gọi `/ingredient-scan/complete`.
   - `> target + 0.1`: hiển thị lỗi và xóa tất cả dữ liệu quét tạm thời của nguyên liệu đó.

### Luồng hoàn tất bồn chứa
- Sau khi tất cả nguyên liệu hoàn thành, app mở màn hình hoàn tất chờ duyệt.
- Khi người dùng bấm nút Xác nhận, app gọi `/tank-transfer/complete`.

### Luồng quét lại bồn chứa (Re-scan)
- App luôn lấy công thức mới nhất từ `/getRecipeDetails`.
- Ngay sau đó, app gọi `/ingredient-scan/progress`.
- Nếu có tiến độ cũ, app tự động khôi phục số lượng đã quét + mã tem đã quét và chỉ để lại các nguyên liệu còn thiếu ở trạng thái chờ.

---

## 10) GET `/app/version` (hoặc POST)
### Chức năng
Lấy thông tin phiên bản mới nhất của ứng dụng để tự động cập nhật (Auto-Update). Ứng dụng sẽ gọi API này ở màn hình Login mỗi lần khởi động.

### Request
*(Không có request body cụ thể nếu dùng GET, có thể truyền kèm header x-header để xác thực).*

### Success Response
```json
{
  "Message": "Success",
  "Data": {
    "latestVersion": "1.0.2",
    "versionCode": 3,
    "isForceUpdate": false,
    "releaseNotes": "- Cập nhật tính năng Auto Update\n- Sửa lỗi UI lúc quét mã",
    "downloadUrl": "/static/apk/my_pda_v1.0.2.apk"
  }
}
```

### Giải thích các trường dữ liệu
- `latestVersion`: Tên phiên bản mới nhất hiển thị cho người dùng (VD: `"1.0.2"`). App còn hỗ trợ fallback so sánh từng phần của String nếu `versionCode` bằng nhau nhưng `latestVersion` lại lớn hơn chuỗi string cũ.
- `versionCode`: Mã phiên bản kỹ thuật, dùng số nguyên. App cần cập nhật nếu `versionCode` API trả về lớn hơn `buildNumber` máy khách đang chạy (bắt nguồn từ `version: 1.0.0+1` ở file pubspec, thì `versionCode = 1`).
- `isForceUpdate`: Trả `true` nếu bắt buộc nâng cấp để dùng tiếp, `false` cho phép người dùng bấm "Bỏ qua".
- `releaseNotes`: Ghi chú nội dung bản cập nhật.
- `downloadUrl`: Tên/Đường dẫn tải file APK. App sẽ tự ghép nối URL nếu nó là đường dẫn tương đối (bắt đầu bằng `/`) kết hợp với `API_BASE_URL` hiện tại.

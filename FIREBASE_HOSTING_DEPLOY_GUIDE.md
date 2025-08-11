## Hướng dẫn deploy Firebase Hosting cho dự án này

### 1) Tổng quan cấu hình hiện tại
- `firebase.json` đã cấu hình Hosting với:
  - `public: build/web` (deploy bản build Flutter Web)
  - `rewrites: [{ "source": "**", "destination": "/index.html" }]` (SPA route)
- Dự án không sử dụng SDK Firebase (FlutterFire/Web SDK); chỉ cần build ra file tĩnh là deploy được.

### 2) Yêu cầu trước khi deploy
- Đã cài Node.js và npm.
- Firebase CLI (cài global hoặc dùng tạm qua npx):
  - Cài global: `npm install -g firebase-tools`
  - Kiểm tra: `firebase --version`
  - Hoặc dùng tạm: `npx firebase-tools --version`
- Đăng nhập Firebase: `firebase login`

Lưu ý Windows PowerShell: chạy các lệnh như bên dưới trực tiếp (không cần | cat).

### 3) Build Flutter Web
```powershell
flutter build web
```
Sau khi build, thư mục xuất ra: `build/web` (khớp với cấu hình `public` trong `firebase.json`).

### 4) Chọn project Firebase để deploy
Bạn có 2 cách:

- Cách A: Thiết lập project mặc định (.firebaserc)
  ```powershell
  firebase use --add
  # Chọn <projectId> của bạn, nhập alias (ví dụ: default)
  ```
  Sau đó có thể deploy không cần `--project` mỗi lần.

- Cách B: Deploy kèm `--project <projectId>` (không cần .firebaserc)
  - Lấy `<projectId>` trong Firebase Console (Project settings).

### 5) Deploy lên Hosting
- Dùng CLI global:
  ```powershell
  firebase deploy --only hosting --project <projectId>
  ```
- Hoặc dùng npx (không cài global):
  ```powershell
  npx firebase-tools deploy --only hosting --project <projectId>
  ```

Nếu đã cấu hình `.firebaserc` (Cách A), có thể đơn giản:
```powershell
firebase deploy --only hosting
```

### 6) Kiểm tra kết quả
Sau khi deploy, CLI sẽ in ra URL (ví dụ `https://<projectId>.web.app`). Mở URL để xác minh.

### 7) Preview channel (tùy chọn)
Tạo bản preview (không ảnh hưởng production):
```powershell
firebase hosting:channel:deploy preview-<ten-kenh> --project <projectId>
```
CLI sẽ trả về một URL tạm thời để kiểm thử.

### 8) Cải thiện hiệu năng (tùy chọn)
Bạn có thể thêm cache headers cho asset đã hash để tải nhanh hơn (sửa `firebase.json`):
```json
{
  "hosting": {
    "public": "build/web",
    "headers": [
      {
        "source": "/index.html",
        "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
      },
      {
        "source": "**/*.{js,css,png,jpg,jpeg,svg,webp,woff2}",
        "headers": [{ "key": "Cache-Control", "value": "public,max-age=31536000,immutable" }]
      }
    ],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

### 9) Lỗi thường gặp
- "firebase: not recognized": Chưa cài global hoặc chưa thêm PATH. Dùng `npx firebase-tools ...` hoặc cài `npm i -g firebase-tools`.
- Deploy sai thư mục: Hãy đảm bảo chạy `flutter build web` và `public` trỏ đúng `build/web`.
- Không có project default: Thêm `--project <projectId>` hoặc `firebase use --add`.

### 10) Gợi ý CI (tùy chọn)
Trong CI (GitHub Actions, v.v.):
1) Thiết lập `FIREBASE_TOKEN` bằng `firebase login:ci`.
2) Bước CI:
   - `flutter build web`
   - `npx firebase-tools deploy --only hosting --project <projectId> --token $FIREBASE_TOKEN`

---
Tài liệu này áp dụng trực tiếp cho dự án hiện tại vì đã có `firebase.json` và kiến trúc SPA. Bạn chỉ cần build và deploy như hướng dẫn.

### Phụ lục: Thiết lập lần đầu (chi tiết)

Phần này dành cho trường hợp bạn chưa từng cấu hình Firebase Hosting cho project hoặc cần biết đầy đủ các bước thiết lập ban đầu.

1) Tạo Firebase Project và bật Hosting
- Vào Firebase Console → Chọn/tạo Project mới.
- Vào mục Hosting → Bấm Get started để khởi tạo Hosting cho project.

2) Kết nối Firebase CLI với project
- Đăng nhập: `firebase login`
- Liên kết project mặc định trong repo (tạo `.firebaserc`):
  ```powershell
  firebase use --add
  # Chọn <projectId> trong danh sách → nhập alias (ví dụ: default)
  ```

3) Khởi tạo file cấu hình (nếu repo CHƯA có `firebase.json`)
- Với repo này đã có sẵn `firebase.json`, bạn có thể bỏ qua bước này.
- Nếu bắt đầu từ đầu: chạy `firebase init hosting` và chọn:
  - Use an existing project → chọn `<projectId>`
  - Public directory: `build/web`
  - Configure as a single-page app: Yes (để tự tạo rewrite về `/index.html`)
  - Ấn No với automatic builds nếu bạn chưa dùng GitHub Actions.

4) Build và chạy thử local
- Build: `flutter build web`
- Xem thử local bằng Hosting Emulator:
  ```powershell
  firebase emulators:start --only hosting
  ```
  Mặc định sẽ mở ở `http://localhost:5000`. Kiểm tra route SPA hoạt động bình thường.

5) Deploy dưới sub-path (nếu có)
- Nếu site của bạn KHÔNG ở root domain (ví dụ deploy tại `https://example.com/app/`), cần set base href khi build Flutter Web:
  ```powershell
  flutter build web --base-href /app/
  ```
- Khi deploy ở root (ví dụ `https://<projectId>.web.app/` hoặc domain custom gắn ở gốc), KHÔNG cần `--base-href`.

6) Nhiều môi trường (dev/staging/prod)
- Thêm nhiều alias:
  ```powershell
  firebase use --add
  # Tạo alias: dev, stg, prod
  ```
- Với nhiều Hosting site (multi-site), gán target để deploy đúng site:
  ```powershell
  firebase target:apply hosting stg <siteId-staging>
  firebase target:apply hosting prod <siteId-prod>
  # Deploy theo target
  firebase deploy --only hosting:stg
  ```

7) Gắn custom domain
- Vào Hosting → Add custom domain → nhập domain → xác thực DNS theo hướng dẫn.
- Sau khi DNS verified, Hosting sẽ cấp SSL tự động. Deploy như bình thường, site sẽ sẵn sàng trên domain custom.

8) Biến môi trường cho API (tùy chọn)
- Nếu backend thay đổi theo môi trường, bạn có thể truyền biến ở build-time:
  ```powershell
  flutter build web --dart-define=API_BASE_URL=https://api.example.com
  ```
- Trong code Dart, đọc bằng `String.fromEnvironment('API_BASE_URL')` (cần tự triển khai). Với repo hiện tại, hãy kiểm tra `lib/services/api_service.dart` để đồng bộ cách lấy base URL.

9) CI/CD nhanh với GitHub Actions (tham khảo)
- Sử dụng token từ `firebase login:ci` (lưu vào secret `FIREBASE_TOKEN`).
- Job cơ bản:
  ```yaml
  name: Deploy Web
  on:
    push:
      branches: [ main ]
  jobs:
    deploy:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: subosito/flutter-action@v2
          with:
            channel: stable
        - run: flutter pub get
        - run: flutter build web
        - run: npx firebase-tools deploy --only hosting --project <projectId> --token ${{ secrets.FIREBASE_TOKEN }}
  ```

10) Rollback nhanh (khi cần)
- Liệt kê các phiên bản đã deploy:
  ```powershell
  firebase hosting:versions:list --site <siteId>
  ```
- Rollback về một version cụ thể:
  ```powershell
  firebase hosting:clone --from_version <versionId> --to_channel live --site <siteId>
  ```

Ghi chú:
- Firebase Hosting tự động nén Brotli/Gzip khi có thể, bạn không cần cấu hình thủ công.
- Hãy giữ `rewrites` về `/index.html` để đảm bảo SPA routing hoạt động trên mọi URL.
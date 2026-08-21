# Admin TODO Progress

- [x] Shop item image preview in Admin Shop Manager list
- [x] Premium cloud avatar ownership and direct unlock flow
- [x] Admin loading/empty/error UI polish for Firebase/offline/permission issues
- [x] Admin audit logs for user/shop/avatar changes
- [x] Admin validation for required image, duplicate names, categories, and non-negative prices

Notes:
- Audit logs are written to `admin_audit_logs` with actor uid/email when Firebase Auth is available.
- Premium cloud avatars use inventory ids like `cloud_avatar_<avatar_doc_id>`.

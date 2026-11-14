// ========================================================
// ملف الاستدعاءات والتصدير الموحد (Barrel File) - منظومة الكابتن
// ========================================================

// 1. مكتبات Dart و Flutter الأساسية
export 'dart:async';
export 'dart:io';
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:flutter_localizations/flutter_localizations.dart';

// 2. مكتبات الحزم الخارجية (Packages)
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_database/firebase_database.dart';
export 'package:permission_handler/permission_handler.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:flutter_contacts/flutter_contacts.dart';

// 3. ملفات البيانات والإدارة الأساسية
export 'app_data.dart';
export 'app_dropdowns.dart';
export 'app_storage_manager.dart';

// 4. ملفات الخدمات (Services)
export 'services/server_config.dart';
export 'services/licensing_service.dart';
export 'services/local_storage_service.dart';
export 'services/file_backup_service.dart';
export 'services/security_manager.dart';
export 'services/cloud_sync_service.dart';
export 'services/auth_service.dart';
export 'services/notification_service.dart';
export 'services/smart_text_parser.dart';
export 'services/ai_assistant_service.dart';

// 5. ملفات الشاشات (Screens)
export 'screens/00_login_screen.dart';
export 'screens/01_clients_screen.dart';
export 'screens/02_brokers_screen.dart';
export 'screens/03_customer_requests_screen.dart';
export 'screens/04_for_sale_screen.dart';
export 'screens/05_for_rent_screen.dart';
export 'screens/06_inspections_screen.dart';
export 'screens/07_completed_operations_screen.dart';
export 'screens/08_accounts_screen.dart';
export 'screens/09_general_report_screen.dart';
export 'screens/10_archive_screen.dart';
export 'screens/about_screen.dart';
export 'screens/home_screen.dart';
export 'screens/trash_bin_screen.dart';
export 'screens/ai_chat_screen.dart';

// 6. ملفات الويدجت المشتركة (Widgets)
export 'widgets/register_company_dialog.dart';
export 'widgets/forgot_password_dialog.dart';
export 'widgets/property_filter_bar.dart';
export 'widgets/custom_screen_appbar.dart';
export 'widgets/home_notifications_dialog.dart';
export 'widgets/home_employees_dialog.dart';
export 'widgets/home_remote_support_dialog.dart';
export 'widgets/home_settings_dialog.dart';
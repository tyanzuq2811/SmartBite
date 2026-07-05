import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('vi'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'navHome': 'Home',
      'navScanner': 'Scanner',
      'navRecipes': 'Recipes',
      'navSettings': 'Settings',

      // Common
      'appName': 'SmartBite',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'update': 'Update',
      'delete': 'Delete',
      'info': 'Info',

      // Login & Register
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'noAccount': 'Don\'t have an account? Register',
      'haveAccount': 'Already have an account? Login',
      'loginSuccess': 'Login successful!',
      'registerSuccess': 'Registration successful!',
      'enterEmail': 'Please enter email',
      'enterPassword': 'Please enter password',
      'invalidEmail': 'Invalid email format',
      'passwordTooShort': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',
      'welcomeBack': 'Welcome Back!',
      'loginSubtitle': 'Login to track your nutrition and recipe goals',
      'createAccount': 'Create Account',
      'registerSubtitle': 'Join SmartBite to personalize your healthy life',

      // Home Screen
      'caloriesToday': 'Calories Today',
      'calGoal': 'Goal',
      'calEaten': 'Eaten',
      'calRemaining': 'Remaining',
      'addMeal': 'Add Meal',
      'syncData': 'Sync Data',
      'synced': 'Synced',
      'syncing': 'Syncing...',
      'history': 'Meal History',
      'waterIntake': 'Water Intake',
      'waterGoal': 'Goal: 2000 ml',
      'waterUnit': 'ml',
      'addWater': 'Add 250ml',
      'resetWater': 'Reset',
      'noHistory': 'No meals logged today yet. Start adding!',
      'mealDetails': 'Meal Details',
      'calories': 'Calories',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',

      // Plan / Recipe Screen
      'planTitle': 'AI Meal Planner',
      'generateMenu': 'GENERATE AI MENU',
      'generatingMenu': 'AI is analyzing your body metrics...',
      'generationTimeNote': 'Please wait, this may take up to 2 minutes',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'swapDish': 'Swap Dish',
      'shoppingList': 'Shopping List',
      'ingredient': 'Ingredient',
      'quantity': 'Quantity',
      'emptyMenu': 'No plan generated yet. Let Gemini AI plan your day!',
      'recipeDetails': 'Recipe Details',
      'instructions': 'Instructions',
      'ingredients': 'Ingredients',
      'servingSize': 'Serving size',
      'preparing': 'Preparing...',

      // Scanner Screen
      'scannerTitle': 'AI Food Scanner',
      'scanSubtitle': 'Scan raw ingredients or cooked dishes to analyze nutrition',
      'takePhoto': 'TAKE PHOTO',
      'chooseGallery': 'CHOOSE FROM GALLERY',
      'analyzingPhoto': 'Gemini AI is analyzing your food photo...',
      'scanResult': 'Analysis Result',
      'recipeResult': 'Suggested Recipe',
      'viewRecipe': 'View Full Recipe',
      'confidenceScore': 'Confidence Score',
      'unidentifiedFood': 'Food could not be recognized. Try another angle.',

      // Settings Screen
      'settingsTitle': 'Settings',
      'personalInfo': 'Personal Information',
      'weight': 'Weight',
      'height': 'Height',
      'age': 'Age',
      'gender': 'Gender',
      'activityLevel': 'Activity Level',
      'dietaryPreference': 'Dietary Preference',
      'saveChanges': 'Save Changes',
      'darkMode': 'Dark Mode',
      'displayLanguage': 'Display Language',
      'notifications': 'Notifications',
      'privacy': 'Privacy & Security',
      'helpCenter': 'Help Center',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to log out?',
      'profileUpdated': 'Profile updated successfully!',

      // Notification Settings
      'notiSettings': 'Notification Settings',
      'mealReminders': 'MEAL REMINDERS',
      'breakfastRemi': 'Breakfast Reminder',
      'breakfastRemiSub': 'Notify me to prepare breakfast at 7:00 AM',
      'lunchRemi': 'Lunch Reminder',
      'lunchRemiSub': 'Notify me to prepare lunch at 11:30 AM',
      'dinnerRemi': 'Dinner Reminder',
      'dinnerRemiSub': 'Notify me to prepare dinner at 6:30 PM',
      'healthAi': 'HEALTH & AI',
      'waterRemi': 'Water Reminder',
      'waterRemiSub': 'Remind me to drink water every 2 hours to stay hydrated',
      'aiChef': 'AI Chef Recommendations',
      'aiChefSub': 'Recommend new recipes based on my preferences',
      'notiTip': 'Tip: Enabling AI Notifications helps you receive personalized menus exactly at your mealtimes.',
      'notiUpdated': 'Notification settings updated',

      // Privacy Settings
      'privacyTitle': 'Privacy & Security',
      'changePassword': 'CHANGE PASSWORD',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'updatePassword': 'Update Password',
      'passwordUpdated': 'Password updated successfully!',
      'currentPasswordReq': 'Please enter current password',
      'newPasswordReq': 'Please enter new password',
      'dataPermissions': 'DATA PERMISSIONS',
      'shareHealth': 'Share Health Data',
      'shareHealthSub': 'Allow sharing anonymous nutrition data to improve AI model',
      'cloudBackup': 'Cloud Backup Sync',
      'cloudBackupSub': 'Automatically backup menu and nutritional indexes to cloud',
      'dangerZone': 'DANGER ZONE',
      'deleteAccount': 'Permanently Delete Account',
      'deleteAccountSub': 'All health and profile data will be permanently wiped out',
      'deleteConfirmTitle': 'Delete Account?',
      'deleteConfirmContent': 'This action will permanently delete your account. All menus, calorie history, and profile data will be lost and CANNOT be recovered. Are you sure?',
      'deleteConfirmBtn': 'Confirm Delete',
      'accountDeleted': 'Your account has been successfully deleted.',

      // Help Center
      'helpTitle': 'Help Center',
      'helpBannerTitle': 'How can we help you?',
      'helpBannerSub': 'Find quick answers or send direct feedback to the SmartBite team.',
      'faqs': 'FREQUENTLY ASKED QUESTIONS (FAQ)',
      'feedbackTitle': 'SEND FEEDBACK OR REPORT A BUG',
      'feedbackTip': 'Your feedback helps SmartBite AI grow better:',
      'feedbackHint': 'Enter your feedback, suggestions, or bug reports here...',
      'sendFeedback': 'Send Feedback',
      'feedbackSent': 'Feedback sent! Thank you.',
      'faqQ1': 'How does SmartBite AI work?',
      'faqA1': 'SmartBite AI personalizes menus based on Gemini AI. It analyzes your body statistics (weight, height, activity level, allergy, target) to propose a 3-meal plan (breakfast, lunch, dinner) and generate a shopping list.',
      'faqQ2': 'How to generate an AI menu?',
      'faqA2': 'Simply switch to the "Recipes" (Plan) tab on the navigation bar, select the day, and click "GENERATE AI MENU". AI will calculate formulas and create recipes in seconds.',
      'faqQ3': 'How to swap a dish if I do not like it?',
      'faqA3': 'Once the menu is generated, each dish has a "Swap" icon. Clicking it triggers AI to replace it with another dish having similar calories but different ingredients.',
      'faqQ4': 'How does the Food Camera Scan work?',
      'faqA4': 'In the "Scanner" tab, you can take a picture of food or fridge ingredients. AI will identify components and generate a detailed recipe matching your diet.',
      'faqQ5': 'How do I change my target calories?',
      'faqA5': 'You can edit body stats by clicking the edit icon on Home page, or via Profile menu in Settings. AI will recalculate recommended daily calories.'
    },
    'vi': {
      // Navigation
      'navHome': 'Trang chủ',
      'navScanner': 'Máy quét',
      'navRecipes': 'Công thức',
      'navSettings': 'Cài đặt',

      // Common
      'appName': 'SmartBite',
      'error': 'Lỗi',
      'success': 'Thành công',
      'loading': 'Đang tải...',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'update': 'Cập nhật',
      'delete': 'Xóa',
      'info': 'Thông tin',

      // Login & Register
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'email': 'Email',
      'password': 'Mật khẩu',
      'confirmPassword': 'Xác nhận mật khẩu',
      'fullName': 'Họ và tên',
      'noAccount': 'Chưa có tài khoản? Đăng ký',
      'haveAccount': 'Đã có tài khoản? Đăng nhập',
      'loginSuccess': 'Đăng nhập thành công!',
      'registerSuccess': 'Đăng ký thành công!',
      'enterEmail': 'Vui lòng nhập email',
      'enterPassword': 'Vui lòng nhập mật khẩu',
      'invalidEmail': 'Email không đúng định dạng',
      'passwordTooShort': 'Mật khẩu phải tối thiểu 6 ký tự',
      'passwordsDoNotMatch': 'Mật khẩu xác nhận không trùng khớp',
      'welcomeBack': 'Chào mừng quay lại!',
      'loginSubtitle': 'Đăng nhập để theo dõi mục tiêu dinh dưỡng và thực đơn',
      'createAccount': 'Tạo tài khoản',
      'registerSubtitle': 'Tham gia SmartBite để cá nhân hóa cuộc sống lành mạnh',

      // Home Screen
      'caloriesToday': 'Calo hôm nay',
      'calGoal': 'Mục tiêu',
      'calEaten': 'Đã ăn',
      'calRemaining': 'Còn lại',
      'addMeal': 'Thêm bữa ăn',
      'syncData': 'Đồng bộ dữ liệu',
      'synced': 'Đã đồng bộ',
      'syncing': 'Đang đồng bộ...',
      'history': 'Lịch sử ăn uống',
      'waterIntake': 'Lượng nước uống',
      'waterGoal': 'Mục tiêu: 2000 ml',
      'waterUnit': 'ml',
      'addWater': 'Thêm 250ml',
      'resetWater': 'Đặt lại',
      'noHistory': 'Chưa ghi nhận bữa ăn nào hôm nay. Hãy thêm ngay!',
      'mealDetails': 'Chi tiết bữa ăn',
      'calories': 'Calo',
      'protein': 'Đạm (Protein)',
      'carbs': 'Tinh bột (Carbs)',
      'fat': 'Béo (Fat)',

      // Plan / Recipe Screen
      'planTitle': 'Lập kế hoạch dinh dưỡng AI',
      'generateMenu': 'TẠO THỰC ĐƠN AI',
      'generatingMenu': 'AI đang phân tích các chỉ số cơ thể của bạn...',
      'generationTimeNote': 'Vui lòng đợi, quá trình này có thể mất tới 2 phút',
      'breakfast': 'Bữa sáng',
      'lunch': 'Bữa trưa',
      'dinner': 'Bữa tối',
      'swapDish': 'Đổi món',
      'shoppingList': 'Danh sách đi chợ',
      'ingredient': 'Nguyên liệu',
      'quantity': 'Số lượng',
      'emptyMenu': 'Chưa có thực đơn nào được tạo. Hãy để Gemini AI lên kế hoạch!',
      'recipeDetails': 'Chi tiết công thức',
      'instructions': 'Hướng dẫn chế biến',
      'ingredients': 'Thành phần nguyên liệu',
      'servingSize': 'Khẩu phần ăn',
      'preparing': 'Đang chuẩn bị...',

      // Scanner Screen
      'scannerTitle': 'Máy quét thực phẩm AI',
      'scanSubtitle': 'Quét nguyên liệu tươi hoặc món ăn đã nấu để phân tích dinh dưỡng',
      'takePhoto': 'CHỤP ẢNH MỚI',
      'chooseGallery': 'CHỌN TỪ THƯ VIỆN',
      'analyzingPhoto': 'Gemini AI đang phân tích ảnh thức ăn của bạn...',
      'scanResult': 'Kết quả phân tích',
      'recipeResult': 'Món ăn gợi ý',
      'viewRecipe': 'Xem chi tiết công thức',
      'confidenceScore': 'Độ tin cậy',
      'unidentifiedFood': 'Không thể nhận diện món ăn. Hãy thử lại với góc chụp khác.',

      // Settings Screen
      'settingsTitle': 'Cài đặt',
      'personalInfo': 'Thông tin cá nhân',
      'weight': 'Cân nặng',
      'height': 'Chiều cao',
      'age': 'Tuổi',
      'gender': 'Giới tính',
      'activityLevel': 'Mức độ vận động',
      'dietaryPreference': 'Chế độ ăn kiêng',
      'saveChanges': 'Lưu thay đổi',
      'darkMode': 'Giao diện tối (Dark Mode)',
      'displayLanguage': 'Ngôn ngữ hiển thị',
      'notifications': 'Thông báo',
      'privacy': 'Quyền riêng tư & Bảo mật',
      'helpCenter': 'Trung tâm trợ giúp',
      'logout': 'Đăng xuất',
      'logoutConfirm': 'Bạn có chắc chắn muốn đăng xuất không?',
      'profileUpdated': 'Cập nhật hồ sơ thành công!',

      // Notification Settings
      'notiSettings': 'Cài đặt thông báo',
      'mealReminders': 'NHẮC NHỞ ĂN UỐNG',
      'breakfastRemi': 'Nhắc nhở bữa sáng',
      'breakfastRemiSub': 'Nhận thông báo chuẩn bị bữa sáng lúc 7:00 AM',
      'lunchRemi': 'Nhắc nhở bữa trưa',
      'lunchRemiSub': 'Nhận thông báo chuẩn bị bữa trưa lúc 11:30 AM',
      'dinnerRemi': 'Nhắc nhở bữa tối',
      'dinnerRemiSub': 'Nhận thông báo chuẩn bị bữa tối lúc 6:30 PM',
      'healthAi': 'SỨC KHỎE & AI',
      'waterRemi': 'Nhắc nhở uống nước',
      'waterRemiSub': 'Nhắc uống nước đều đặn mỗi 2 tiếng để giữ nước',
      'aiChef': 'Gợi ý từ đầu bếp AI',
      'aiChefSub': 'Khuyến nghị công thức món ăn mới dựa trên sở thích',
      'notiTip': 'Mẹo: Bật thông báo AI sẽ giúp bạn nhận được thực đơn cá nhân hóa chính xác vào đúng khung giờ ăn của mình.',
      'notiUpdated': 'Đã cập nhật cài đặt thông báo',

      // Privacy Settings
      'privacyTitle': 'Quyền riêng tư & Bảo mật',
      'changePassword': 'ĐỔI MẬT KHẨU',
      'currentPassword': 'Mật khẩu hiện tại',
      'newPassword': 'Mật khẩu mới',
      'confirmNewPassword': 'Xác nhận mật khẩu mới',
      'updatePassword': 'Cập nhật mật khẩu',
      'passwordUpdated': 'Đổi mật khẩu thành công!',
      'currentPasswordReq': 'Vui lòng nhập mật khẩu hiện tại',
      'newPasswordReq': 'Vui lòng nhập mật khẩu mới',
      'dataPermissions': 'QUYỀN HẠN DỮ LIỆU',
      'shareHealth': 'Chia sẻ dữ liệu sức khỏe',
      'shareHealthSub': 'Cho phép chia sẻ dữ liệu dinh dưỡng ẩn danh để cải thiện AI',
      'cloudBackup': 'Đồng bộ hóa dữ liệu đám mây',
      'cloudBackupSub': 'Tự động sao lưu thực đơn và chỉ số dinh dưỡng lên cloud',
      'dangerZone': 'VÙNG NGUY HIỂM',
      'deleteAccount': 'Xóa tài khoản vĩnh viễn',
      'deleteAccountSub': 'Mọi dữ liệu sức khỏe và chỉ số cá nhân sẽ bị xóa vĩnh viễn',
      'deleteConfirmTitle': 'Xóa tài khoản?',
      'deleteConfirmContent': 'Hành động này sẽ xóa vĩnh viễn tài khoản của bạn. Tất cả dữ liệu thực đơn, calo đã lưu và lịch sử sẽ bị mất hoàn toàn và KHÔNG thể phục hồi. Bạn chắc chắn chứ?',
      'deleteConfirmBtn': 'Xác nhận xóa',
      'accountDeleted': 'Tài khoản của bạn đã được xóa thành công.',

      // Help Center
      'helpTitle': 'Trung tâm trợ giúp',
      'helpBannerTitle': 'Chúng tôi có thể giúp gì cho bạn?',
      'helpBannerSub': 'Tìm câu trả lời nhanh chóng hoặc gửi phản hồi trực tiếp cho đội ngũ phát triển SmartBite.',
      'faqs': 'CÂU HỎI THƯỜNG GẶP (FAQ)',
      'feedbackTitle': 'GỬI PHẢN HỒI HOẶC BÁO LỖI',
      'feedbackTip': 'Ý kiến của bạn sẽ giúp SmartBite AI ngày một tốt hơn:',
      'feedbackHint': 'Nhập nội dung phản hồi, ý kiến đóng góp hoặc báo lỗi tại đây...',
      'sendFeedback': 'Gửi ý kiến',
      'feedbackSent': 'Ý kiến phản hồi đã được gửi đi! Cảm ơn bạn.',
      'faqQ1': 'SmartBite AI hoạt động như thế nào?',
      'faqA1': 'SmartBite AI là ứng dụng cá nhân hóa thực đơn dựa trên trí tuệ nhân tạo (Gemini AI). Ứng dụng phân tích dữ liệu thể trạng của bạn bao gồm: Cân nặng, chiều cao, chế độ ăn kiêng, dị ứng và calo mục tiêu để đề xuất thực đơn 3 bữa sáng - trưa - tối và tạo danh sách đi chợ tương thích.',
      'faqQ2': 'Làm thế nào để tạo thực đơn AI?',
      'faqA2': 'Bạn chỉ cần chuyển sang tab "Lập kế hoạch" (PlanScreen) bên dưới thanh điều hướng, chọn ngày muốn lên kế hoạch và bấm nút "TẠO THỰC ĐƠN AI". AI sẽ tự động lập công thức và tạo thực đơn chỉ trong vài giây.',
      'faqQ3': 'Làm sao để đổi món ăn nếu tôi không thích?',
      'faqA3': 'Khi thực đơn đã được tạo, cạnh mỗi món ăn sẽ có một nút "Đổi món" (icon swap). Khi bạn bấm vào, AI sẽ tính toán và thay thế món ăn đó bằng một món ăn khác có lượng calo tương đương nhưng khẩu vị thay đổi.',
      'faqQ4': 'Công cụ quét món ăn bằng Camera hoạt động thế nào?',
      'faqA4': 'Tại tab "Máy quét", bạn có thể chụp ảnh đĩa thức ăn hoặc các nguyên liệu trong tủ lạnh. AI sẽ nhận diện các thành phần trong ảnh và tự động lập ra công thức nấu ăn chi tiết phù hợp với chế độ ăn kiêng của bạn.',
      'faqQ5': 'Làm cách nào để thay đổi calo mục tiêu?',
      'faqA5': 'Bạn có thể vào tab Trang chủ, nhấn vào phần chỉnh sửa chỉ số cá nhân, hoặc nhấn vào nút sửa profile trong mục Cài đặt để cập nhật thông tin chỉ số cơ thể. AI sẽ tự động điều chỉnh calo khuyên dùng.'
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'vi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String translate(String key) => AppLocalizations.of(this).translate(key);
}

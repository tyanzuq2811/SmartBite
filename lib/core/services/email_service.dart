import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../data/datasources/firebase_datasource.dart';

class EmailService {
  static Future<void> sendEmailNotification({
    required String recipientEmail,
    required String subject,
    required String bodyHtml,
  }) async {
    final smtpEmail = dotenv.env['SMTP_EMAIL'];
    final smtpPassword = dotenv.env['SMTP_PASSWORD'];

    if (smtpEmail == null || smtpPassword == null || smtpEmail.isEmpty || smtpPassword.isEmpty) {
      print('[EmailService] SMTP credentials are not configured in .env!');
      return;
    }

    // Using GMail SMTP server configuration
    final smtpServer = gmail(smtpEmail, smtpPassword);

    final message = Message()
      ..from = Address(smtpEmail, 'SmartBite Support')
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..html = bodyHtml;

    try {
      await send(message, smtpServer);
      print('[EmailService] Gửi email thành công tới: $recipientEmail');
    } catch (e) {
      print('[EmailService] Lỗi khi gửi email: $e');
    }
  }

  static Future<void> sendStreakReminder({
    required String recipientEmail,
    required int currentStreak,
    required String remainingCalText,
  }) async {
    final subject = '🔥 [SmartBite] Nhắc nhở duy trì Streak của bạn hôm nay!';
    final bodyHtml = '''
      <div style="font-family: 'Segoe UI', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05);">
        <div style="background-color: #10B981; padding: 24px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 24px; font-weight: bold; letter-spacing: 0.5px;">SmartBite Remind</h1>
        </div>
        <div style="padding: 32px; background-color: #ffffff; color: #374151; line-height: 1.6;">
          <h2 style="color: #111827; margin-top: 0; font-size: 20px;">Xin chào người dùng SmartBite,</h2>
          <p style="font-size: 15px;">Ngày hôm nay sắp trôi qua rồi! Bạn đang có chuỗi giữ Streak cực kỳ xuất sắc là <strong>$currentStreak ngày</strong>. Đừng để nó biến mất nhé! 🔥</p>
          
          <div style="background-color: #F3F4F6; border-left: 4px solid #10B981; padding: 16px; margin: 24px 0; border-radius: 4px;">
            <p style="margin: 0; font-size: 14px; color: #4B5563;">
              <strong>Trạng thái calo hôm nay:</strong> $remainingCalText
            </p>
          </div>
          
          <p style="font-size: 15px;">Hãy mở ứng dụng SmartBite ngay để ghi nhận các bữa ăn hôm nay và uống đủ nước để hoàn thành mục tiêu ngày của bạn nhé!</p>
          
          <div style="text-align: center; margin-top: 32px;">
            <a href="https://smartbite.page.link/app" style="background-color: #10B981; color: white; padding: 12px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block; box-shadow: 0 4px 6px rgba(16, 185, 129, 0.25);">Mở SmartBite Ngay</a>
          </div>
        </div>
        <div style="background-color: #F9FAFB; padding: 16px; text-align: center; font-size: 12px; color: #9CA3AF; border-top: 1px solid #E5E7EB;">
          <p style="margin: 0;">© 2026 SmartBite App. Mọi quyền được bảo lưu.</p>
          <p style="margin: 4px 0 0 0;">Bạn nhận được email này vì bạn đã bật chế độ nhắc nhở duy trì Streak trên thiết bị.</p>
        </div>
      </div>
    ''';

    await sendEmailNotification(
      recipientEmail: recipientEmail,
      subject: subject,
      bodyHtml: bodyHtml,
    );
  }
}

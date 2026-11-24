import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';

void main() {
  group('loginRedirectUrl', () {
    test('웹은 지금 열려 있는 주소의 origin 으로 돌아온다', () {
      final url = loginRedirectUrl(
        isWeb: true,
        base: Uri.parse('https://hanbakwi-app.vercel.app/#/planner'),
      );
      expect(url, 'https://hanbakwi-app.vercel.app');
    });

    test('로컬 크롬 실행도 포트까지 그대로', () {
      final url = loginRedirectUrl(isWeb: true, base: Uri.parse('http://localhost:5062/'));
      expect(url, 'http://localhost:5062');
    });

    test('앱은 AndroidManifest 와 같은 딥링크로 돌아온다', () {
      final url = loginRedirectUrl(isWeb: false, base: Uri.parse('http://localhost:5062/'));
      expect(url, 'com.goldmagnet.jejuhanbakwi://login-callback');
      expect(url, appLoginCallback);
    });
  });
}

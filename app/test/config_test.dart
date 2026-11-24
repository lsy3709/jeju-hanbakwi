import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/config.dart';

/// 서버 주소 고르기 — 같은 env.json 으로 크롬과 에뮬레이터가 모두 연결되어야 합니다.
void main() {
  group('resolveApiUrl', () {
    test('비어 있으면 웹(크롬)은 localhost', () {
      expect(resolveApiUrl('', isWeb: true), 'http://localhost:8000');
    });
    test('비어 있으면 에뮬레이터는 10.0.2.2', () {
      expect(resolveApiUrl('', isWeb: false), 'http://10.0.2.2:8000');
    });
    test('크롬인데 에뮬레이터 주소(10.0.2.2)가 적혀 있으면 localhost 로 바꾼다', () {
      expect(resolveApiUrl('http://10.0.2.2:8000', isWeb: true), 'http://localhost:8000');
      expect(resolveApiUrl('http://10.0.2.2:8001', isWeb: true), 'http://localhost:8001');
    });
    test('에뮬레이터는 적힌 10.0.2.2 를 그대로 쓴다', () {
      expect(resolveApiUrl('http://10.0.2.2:8000', isWeb: false), 'http://10.0.2.2:8000');
    });
    test('배포 주소나 PC 의 IP 처럼 직접 적은 주소는 그대로 쓴다', () {
      const deployed = 'https://jeju-hanbakwi-api.vercel.app';
      expect(resolveApiUrl(deployed, isWeb: true), deployed);
      expect(resolveApiUrl(deployed, isWeb: false), deployed);
      expect(resolveApiUrl('http://192.168.0.10:8000', isWeb: false), 'http://192.168.0.10:8000');
    });
    test('앞뒤 공백과 끝의 / 는 떼어 낸다', () {
      expect(resolveApiUrl(' http://localhost:8000/ ', isWeb: true), 'http://localhost:8000');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/controllers/planner_controller.dart';

import '../support.dart';

void main() {
  test('입력값이 요청에 실린다. 날짜는 YYYY-MM-DD, 글은 앞뒤 공백 제거', () async {
    final api = PlanApi();
    final c = PlannerController(api: api);
    expect(c.days, 2); // 기본값
    expect(c.companion, isNull);

    c.message = '  바다 보고 싶어요 ';
    c.setDays(3);
    c.setCompanion('연인');
    c.setStartDate(DateTime(2026, 12, 3));
    await c.submit();

    expect(api.planCalls.single, {'message': '바다 보고 싶어요', 'days': 3, 'companions': '연인', 'startDate': '2026-12-03'});
  });

  test('동행·날짜는 null 로 되돌릴 수 있다(선택 사항)', () {
    final c = PlannerController(api: PlanApi());
    c.setCompanion('친구');
    c.setStartDate(DateTime(2026, 12, 3));

    c.setCompanion(null);
    c.setStartDate(null);

    expect(c.companion, isNull);
    expect(c.startDate, isNull);
  });

  test('글이 비어 있으면 요청하지 않는다', () async {
    final api = PlanApi();
    final c = PlannerController(api: api);
    c.message = '   ';

    expect(c.hasMessage, false);
    await c.submit();

    expect(api.planCalls, isEmpty);
    expect(c.result, isNull);
  });

  test('요청 성공: 결과가 채워지고 요청 중이 꺼진다', () async {
    final c = PlannerController(api: PlanApi());
    c.message = '제주';

    final future = c.submit();
    expect(c.loading, true);
    await future;

    expect(c.loading, false);
    expect(c.error, isNull);
    expect(c.result?.answer, '추천이에요');
  });

  test('요청 실패: 오류 문구를 갖고 결과는 없다', () async {
    final api = PlanApi()..failPlan = true;
    final c = PlannerController(api: api);
    c.message = '제주';

    await c.submit();

    expect(c.error, '지금은 이 기능을 쓸 수 없어요.');
    expect(c.loading, false);
    expect(c.result, isNull);
  });

  test('저장 성공: saved 가 켜지고 제목이 서버로 간다', () async {
    final api = PlanApi();
    final c = PlannerController(api: api);
    c.message = '제주';
    await c.submit();
    expect(c.saved, false);

    final error = await c.save('부모님과 제주');

    expect(error, isNull);
    expect(api.saveCalls, ['부모님과 제주']);
    expect(c.saved, true);
    expect(c.saving, false);
  });

  test('저장 실패: 오류 문구를 돌려주고 saved 는 꺼진 채', () async {
    final api = PlanApi()..failSave = true;
    final c = PlannerController(api: api);
    c.message = '제주';
    await c.submit();

    final error = await c.save('제목');

    expect(error, '로그인이 필요해요.');
    expect(c.saved, false);
    expect(c.saving, false);
  });

  test('새로 일정을 짜면 saved 가 다시 꺼진다', () async {
    final c = PlannerController(api: PlanApi());
    c.message = '제주';
    await c.submit();
    await c.save('제목');
    expect(c.saved, true);

    await c.submit();

    expect(c.saved, false);
  });

  test('저장 중에 또 저장해도 요청은 한 번', () async {
    final api = PlanApi();
    final c = PlannerController(api: api);
    c.message = '제주';
    await c.submit();

    await Future.wait([c.save('제목'), c.save('제목')]);

    expect(api.saveCalls.length, 1);
  });
}

// 서비스 이름과 화면 문구를 한곳에 모아 둔 파일입니다. 화면 코드는 글자를 직접 쓰지 않고 Brand.name 처럼 여기서 가져다 씁니다.
// static const 는 객체를 만들지 않고 Brand.name 으로 바로 읽는 바뀌지 않는 값입니다.

/// 서비스 이름과 화면 문구. 수강생이 자기 서비스로 바꿀 때 여기만 고치면 됩니다.
class Brand {
  static const String name = '제주 한 바퀴';
  static const String greeting = '어디로 한 바퀴 돌까요?';
  static const String searchHint = '가고 싶은 곳, 하고 싶은 것을 검색해 보세요';
  static const String aiCardTitle = 'AI에게 일정 맡기기';
  static const String aiCardBody = '누구와, 며칠, 어떤 여행인지만 알려 주세요.\n하루하루 코스를 짜 드려요.';
  static const String loginNeedTitle = '로그인이 필요해요';
  static const String loginNeedBody = '찜하기와 일정 저장은 로그인 후에 쓸 수 있어요.\n"내 여행" 탭에서 구글로 로그인해 주세요.';
  static const String loginNotReady = '로그인 설정이 아직 없어요';
}

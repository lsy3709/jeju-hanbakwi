// 화면이 부를 서버 주소를 고르는 순수 함수입니다.

/** 안드로이드 에뮬레이터 안에서 "내 PC" 를 가리키는 특별한 주소. */
const EMULATOR_HOST = "10.0.2.2";

/**
 * NEXT_PUBLIC_API_URL 값과 지금 화면이 열린 주소(pageHost)로 실제 부를 서버 주소를 고릅니다.
 *
 * - 비어 있으면 http://localhost:8000
 * - 화면이 에뮬레이터의 웹뷰(10.0.2.2)에서 열렸는데 서버가 localhost 로 적혀 있으면 10.0.2.2 로 바꿉니다.
 *   (앱이 3D 지도 화면을 웹뷰로 띄울 때, 에뮬레이터 안의 localhost 는 내 PC 가 아니라 에뮬레이터 자신이기 때문)
 * - 그 밖의 주소(배포 주소 등)는 그대로 씁니다.
 */
export function resolveApiUrl(defined: string | undefined, pageHost: string | null): string {
  const url = (defined || "http://localhost:8000").replace(/\/$/, "");
  if (pageHost === EMULATOR_HOST) return url.replace("//localhost", `//${EMULATOR_HOST}`);
  return url;
}

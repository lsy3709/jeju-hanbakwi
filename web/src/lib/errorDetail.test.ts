// 테스트 파일입니다. 화면 없이 errorDetail.ts 의 detailText 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { detailText } from "./errorDetail";

describe("detailText (서버 오류 본문 → 화면 문구)", () => {
  it('{ "detail": "설명" } 이면 그 글자', () => {
    expect(detailText({ detail: "자기 자신은 정지할 수 없습니다." })).toBe("자기 자신은 정지할 수 없습니다.");
  });
  it("입력값 검증 오류(배열)는 칸 이름을 한국어로 바꿔 모은다", () => {
    const data = {
      detail: [
        { loc: ["body", "title"], msg: "String should have at least 1 character" },
        { loc: ["body", "lat"], msg: "Input should be less than or equal to 34.5" },
      ],
    };
    expect(detailText(data)).toBe(
      "입력값을 확인해 주세요 — 이름: String should have at least 1 character / 위도: Input should be less than or equal to 34.5",
    );
  });
  it("모르는 칸 이름은 그대로 쓴다", () => {
    expect(detailText({ detail: [{ loc: ["query", "size"], msg: "bad" }] })).toBe("입력값을 확인해 주세요 — size: bad");
  });
  it("모양을 알 수 없으면 null", () => {
    expect(detailText(null)).toBeNull();
    expect(detailText({ message: "x" })).toBeNull();
    expect(detailText({ detail: [] })).toBeNull();
  });
});

import { describe, expect, it } from "vitest";
import { resolveApiUrl } from "./apiUrl";

describe("resolveApiUrl (화면이 부를 서버 주소 고르기)", () => {
  it("비어 있으면 localhost:8000", () => {
    expect(resolveApiUrl(undefined, "localhost")).toBe("http://localhost:8000");
    expect(resolveApiUrl("", null)).toBe("http://localhost:8000");
  });
  it("끝의 / 는 뗀다", () => {
    expect(resolveApiUrl("http://localhost:8000/", "localhost")).toBe("http://localhost:8000");
  });
  it("에뮬레이터의 웹뷰(10.0.2.2)로 열렸으면 localhost 서버를 10.0.2.2 로 바꿔 부른다", () => {
    expect(resolveApiUrl("http://localhost:8000", "10.0.2.2")).toBe("http://10.0.2.2:8000");
    expect(resolveApiUrl(undefined, "10.0.2.2")).toBe("http://10.0.2.2:8000");
  });
  it("배포 주소는 어디서 열든 그대로 쓴다", () => {
    const deployed = "https://jeju-hanbakwi-api.vercel.app";
    expect(resolveApiUrl(deployed, "10.0.2.2")).toBe(deployed);
    expect(resolveApiUrl(deployed, "jeju-hanbakwi-web.vercel.app")).toBe(deployed);
  });
});

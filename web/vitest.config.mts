import { defineConfig } from "vitest/config";
import path from "node:path";

// 순수 함수만 테스트하므로 브라우저 환경은 필요 없습니다.
export default defineConfig({
  test: { environment: "node", include: ["src/**/*.test.ts"] },
  resolve: { alias: { "@": path.resolve(import.meta.dirname, "src") } },
});

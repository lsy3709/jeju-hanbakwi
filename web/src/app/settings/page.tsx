// 이 파일이 하는 일: 설정 화면 조립. 지금은 "내 AI 키" 한 묶음입니다.
import type { Metadata } from "next";
import { Settings } from "lucide-react";
import { AiKeySettings } from "@/components/AiKeySettings";

export const metadata: Metadata = { title: "설정" };

export default function SettingsPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <h1 className="flex items-center gap-2 text-2xl font-extrabold">
        <Settings className="text-primary" aria-hidden="true" />
        설정
      </h1>
      <AiKeySettings />
    </div>
  );
}

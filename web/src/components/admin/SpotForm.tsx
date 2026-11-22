"use client";

// 이 파일이 하는 일: 관리자 "여행지 추가·수정" 폼(같은 컴포넌트를 함께 씁니다). 창처럼 화면 위에 떠서, 닫아도 뒤 목록의 스크롤이 그대로입니다.
// 무엇을 서버로 보낼지는 lib/spotForm.ts(순수 함수)와 useAdminSpots 가 정하고, 여기서는 입력만 받습니다.
import { useState, type FormEvent } from "react";
import { X } from "lucide-react";
import { btnOutline, btnPrimary, chip, inputClass } from "@/components/ui";
import { errorMessage } from "@/lib/api";
import { MAX_THEMES, emptySpotForm, spotToForm, toggleTheme, type SpotFormValues } from "@/lib/spotForm";
import type { AdminSpot, Meta } from "@/lib/types";

const fieldLabel = "block space-y-1.5 text-sm";
const labelText = "font-semibold";
const selectClass = "w-full rounded-pill border border-line bg-surface px-4 py-2.5 text-sm";
const textareaClass = "w-full rounded-card border border-line bg-surface px-4 py-2.5 text-sm placeholder:text-muted";

export function SpotForm({
  meta,
  spot,
  onSubmit,
  onClose,
}: {
  meta: Meta;
  /** 수정할 여행지. null 이면 새로 추가 */
  spot: AdminSpot | null;
  /** 저장. 실패하면 오류를 던져 주세요(폼 아래에 서버의 detail 을 보여 줍니다). */
  onSubmit: (values: SpotFormValues) => Promise<void>;
  onClose: () => void;
}) {
  const isNew = spot === null;
  const [values, setValues] = useState<SpotFormValues>(() => (spot ? spotToForm(spot) : emptySpotForm()));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 입력칸 하나를 바꾸는 작은 도우미(칸마다 setValues 를 쓰지 않으려고)
  const set = <K extends keyof SpotFormValues>(key: K, value: SpotFormValues[K]) =>
    setValues((prev) => ({ ...prev, [key]: value }));

  async function handleSubmit(event: FormEvent) {
    event.preventDefault(); // 페이지가 새로고침되지 않게 막기
    setBusy(true);
    setError(null);
    try {
      await onSubmit(values);
      onClose(); // 성공하면 닫습니다. 목록의 그 줄은 useAdminSpots 가 이미 바꿔 두었습니다.
    } catch (e) {
      setError(errorMessage(e)); // 예: 422 "입력값을 확인해 주세요 — 위도: ..." / 400 "고칠 내용이 없습니다."
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/40 p-4">
      <form
        role="dialog"
        aria-modal="true"
        aria-label={isNew ? "여행지 추가" : "여행지 수정"}
        onSubmit={handleSubmit}
        className="mx-auto my-6 w-full max-w-lg space-y-4 rounded-card bg-surface p-6"
      >
        <div className="flex items-start justify-between gap-4">
          <h2 className="text-lg font-bold">{isNew ? "여행지 추가" : `여행지 수정 · ${spot.id}번`}</h2>
          <button type="button" onClick={onClose} aria-label="닫기" className="text-muted hover:text-ink">
            <X size={20} aria-hidden="true" />
          </button>
        </div>

        <label className={fieldLabel}>
          <span className={labelText}>이름 (필수)</span>
          <input required maxLength={60} value={values.title} onChange={(e) => set("title", e.target.value)} className={inputClass} />
        </label>

        <div className="grid grid-cols-2 gap-3">
          <label className={fieldLabel}>
            <span className={labelText}>분류</span>
            <select required value={values.category} onChange={(e) => set("category", e.target.value)} className={selectClass}>
              <option value="">고르세요</option>
              {meta.categories.map((option) => (
                <option key={option}>{option}</option>
              ))}
            </select>
          </label>
          <label className={fieldLabel}>
            <span className={labelText}>지역</span>
            <select required value={values.area} onChange={(e) => set("area", e.target.value)} className={selectClass}>
              <option value="">고르세요</option>
              {meta.areas.map((option) => (
                <option key={option}>{option}</option>
              ))}
            </select>
          </label>
        </div>

        <fieldset className="space-y-1.5 text-sm">
          <legend className={labelText}>
            테마 ({values.theme_tags.length}/{MAX_THEMES})
          </legend>
          <div className="flex flex-wrap gap-2">
            {meta.themes.map((theme) => {
              const selected = values.theme_tags.includes(theme);
              // 5개를 고른 뒤에는 고르지 않은 칩을 누를 수 없게 합니다(서버도 5개까지만 받음).
              const full = !selected && values.theme_tags.length >= MAX_THEMES;
              return (
                <button
                  key={theme}
                  type="button"
                  aria-pressed={selected}
                  disabled={full}
                  onClick={() => set("theme_tags", toggleTheme(values.theme_tags, theme))}
                  className={`${chip(selected)} disabled:cursor-not-allowed disabled:opacity-40`}
                >
                  {theme}
                </button>
              );
            })}
          </div>
        </fieldset>

        <label className={fieldLabel}>
          <span className={labelText}>한 줄 소개</span>
          <input maxLength={120} value={values.one_liner} onChange={(e) => set("one_liner", e.target.value)} className={inputClass} />
        </label>

        <label className={fieldLabel}>
          <span className={labelText}>소개 글</span>
          <textarea rows={4} maxLength={2000} value={values.overview} onChange={(e) => set("overview", e.target.value)} className={textareaClass} />
        </label>

        <label className={fieldLabel}>
          <span className={labelText}>주소</span>
          <input maxLength={120} value={values.address} onChange={(e) => set("address", e.target.value)} className={inputClass} />
        </label>

        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={values.indoor} onChange={(e) => set("indoor", e.target.checked)} className="size-4 accent-primary" />
          <span className={labelText}>실내 장소예요</span>
          <span className="text-muted">(비 오는 날 추천에 쓰여요)</span>
        </label>

        {/* 사진·위치는 추가할 때만 받습니다(서버의 수정 주소가 이 칸을 받지 않음). */}
        {isNew && (
          <div className="space-y-3 rounded-card bg-sand p-4">
            <p className="text-xs text-muted">선택 입력 · 위치는 제주 근처(위도 32.5~34.5, 경도 125.5~127.5)만 받아요.</p>
            <label className={fieldLabel}>
              <span className={labelText}>사진 주소</span>
              <input
                type="url"
                placeholder="https://..."
                value={values.image_url}
                onChange={(e) => set("image_url", e.target.value)}
                className={inputClass}
              />
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label className={fieldLabel}>
                <span className={labelText}>위도</span>
                <input type="number" step="any" placeholder="33.45" value={values.lat} onChange={(e) => set("lat", e.target.value)} className={inputClass} />
              </label>
              <label className={fieldLabel}>
                <span className={labelText}>경도</span>
                <input type="number" step="any" placeholder="126.56" value={values.lng} onChange={(e) => set("lng", e.target.value)} className={inputClass} />
              </label>
            </div>
          </div>
        )}

        {error && (
          <p role="alert" className="rounded-card bg-primary/10 px-4 py-3 text-sm text-primary">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2">
          <button type="button" onClick={onClose} className={btnOutline}>
            취소
          </button>
          <button type="submit" disabled={busy} className={btnPrimary}>
            {busy ? "저장하는 중..." : isNew ? "추가하기" : "저장하기"}
          </button>
        </div>
      </form>
    </div>
  );
}

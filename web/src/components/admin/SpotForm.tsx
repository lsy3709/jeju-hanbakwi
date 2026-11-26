"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 이 파일이 하는 일: 관리자 "여행지 추가·수정" 폼(같은 컴포넌트를 함께 씁니다). 창처럼 화면 위에 떠서, 닫아도 뒤 목록의 스크롤이 그대로입니다.
// 무엇을 서버로 보낼지는 lib/spotForm.ts(순수 함수)와 useAdminSpots 가 정하고, 여기서는 입력만 받습니다.
import { useState, type FormEvent } from "react";
import { ArrowRight, ImageOff, RotateCcw, X } from "lucide-react";
import { btnOutline, btnPrimary, chip, inputClass } from "@/components/ui";
import { errorMessage } from "@/lib/api";
import {
  MAX_PHOTO_URL,
  MAX_THEMES,
  categoryChoices,
  emptySpotForm,
  photoUrlProblem,
  spotToForm,
  toggleTheme,
  type SpotFormValues,
} from "@/lib/spotForm";
import type { AdminSpot, Meta } from "@/lib/types";

// 아래 네 줄은 입력칸마다 반복되는 Tailwind 클래스를 한 번만 적어 둔 것입니다.
const fieldLabel = "block space-y-1.5 text-sm";
const labelText = "font-semibold";
const selectClass = "w-full rounded-pill border border-line bg-surface px-4 py-2.5 text-sm";
const textareaClass = "w-full rounded-card border border-line bg-surface px-4 py-2.5 text-sm placeholder:text-muted";

// 컴포넌트 = 화면 조각을 그려 돌려주는 함수입니다. 중괄호 안의 이름들(props)은 부르는 쪽이 넘겨 주는 값입니다.
// meta 는 고를 수 있는 분류·지역·테마 목록, spot 이 null 이면 추가 폼이고 아니면 수정 폼입니다. 저장은 부른 쪽(onSubmit)이 서버에 보냅니다.
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
  // 같은 폼을 추가와 수정에 함께 쓰기 때문에, 어느 쪽인지에 따라 제목·단추 글자·입력칸이 달라집니다.
  const isNew = spot === null;
  const [values, setValues] = useState<SpotFormValues>(() => (spot ? spotToForm(spot) : emptySpotForm()));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 입력칸 하나를 바꾸는 작은 도우미(칸마다 setValues 를 쓰지 않으려고)
  // 제네릭 <K ...> 는 "칸 이름(key)에 맞는 값 모양만 받겠다"는 안전장치입니다. 나머지 칸은 그대로 두고 한 칸만 바꾼 새 값을 만듭니다.
  const set = <K extends keyof SpotFormValues>(key: K, value: SpotFormValues[K]) =>
    setValues((prev) => ({ ...prev, [key]: value }));

  // 저장을 요청하고(await) 성공하면 폼을 닫습니다. 실패하면 서버가 알려 준 이유를 폼 아래에 보입니다.
  async function handleSubmit(event: FormEvent) {
    event.preventDefault(); // 페이지가 새로고침되지 않게 막기
    const photoProblem = photoUrlProblem(values.image_url);
    if (photoProblem) {
      setError(`사진 주소를 확인해 주세요 — ${photoProblem}`); // 서버에 보내기 전에 먼저 알려 줍니다
      return;
    }
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
              {/* 편의 시설 · 추천 식당 분류도 넣습니다. 지금 분류가 선택지에 없으면 저장이 막혀 사진도 못 바꿉니다. */}
              {categoryChoices(meta, spot?.category ?? "").map((option) => (
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

        {/* 사진은 추가할 때도, 수정할 때도 받습니다. */}
        <PhotoFields
          spot={spot}
          values={values}
          onChange={(photo) => {
            setValues((prev) => ({ ...prev, ...photo }));
            setError(null); // 사진 칸을 고치면 앞서 뜬 오류 문구는 지웁니다(고친 뒤에도 남아 있으면 헷갈립니다)
          }}
        />

        {/* 위치는 추가할 때만 받습니다(서버의 수정 주소가 이 칸을 받지 않음). */}
        {isNew && (
          <div className="space-y-3 rounded-card bg-sand p-4">
            <p className="text-xs text-muted">선택 입력 · 위치는 제주 근처(위도 32.5~34.5, 경도 125.5~127.5)만 받아요.</p>
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

type PhotoValues = Pick<SpotFormValues, "image_url" | "image_credit" | "image_source_url">;

/**
 * 사진 칸. 수정할 때는 "지금 사진 → 바꿀 사진"을 나란히 보여 주고, 주소를 넣으면 바로 미리 봅니다.
 * 사진 주소를 바꾸면 출처 두 칸을 비웁니다 — 옛 사진을 찍은 사람의 이름이 새 사진에 붙지 않게 하려는 것입니다.
 */
function PhotoFields({
  spot,
  values,
  onChange,
}: {
  spot: AdminSpot | null;
  values: PhotoValues;
  onChange: (photo: Partial<PhotoValues>) => void;
}) {
  const original: PhotoValues = {
    image_url: spot?.image_url ?? "",
    image_credit: spot?.image_credit ?? "",
    image_source_url: spot?.image_source_url ?? "",
  };
  const typed = values.image_url.trim();
  const changed = typed !== "" && typed !== original.image_url;
  const problem = photoUrlProblem(values.image_url);
  // 미리 볼 주소: 수정할 때는 "바꾼 경우"에만, 추가할 때는 넣은 주소를 그대로. 규칙에 안 맞는 주소는 미리 보지 않습니다.
  const previewUrl = problem ? "" : spot ? (changed ? typed : "") : typed;

  function setUrl(next: string) {
    const photo: Partial<PhotoValues> = { image_url: next };
    // 처음으로 다른 주소를 넣는 순간, 옛 사진의 출처가 그대로 남아 있으면 비웁니다.
    if (spot && values.image_url.trim() === original.image_url && next.trim() !== original.image_url) {
      if (values.image_credit === original.image_credit) photo.image_credit = "";
      if (values.image_source_url === original.image_source_url) photo.image_source_url = "";
    }
    onChange(photo);
  }

  return (
    <fieldset className="space-y-3 rounded-card bg-sand p-4 text-sm">
      <legend className={labelText}>{spot ? "사진 바꾸기" : "사진 (선택)"}</legend>

      <div className="flex items-center gap-3">
        {spot && <PhotoPreview label="지금 사진" url={original.image_url} />}
        {spot && <ArrowRight size={18} aria-hidden="true" className="shrink-0 text-muted" />}
        <PhotoPreview
          label={spot ? "바꿀 사진" : "미리 보기"}
          url={previewUrl}
          emptyHint={spot ? "새 주소를 넣으면 여기에 보여요" : "주소를 넣으면 여기에 보여요"}
        />
      </div>

      <label className={fieldLabel}>
        <span className={labelText}>사진 주소</span>
        <input
          type="text"
          inputMode="url"
          placeholder="https://..."
          maxLength={MAX_PHOTO_URL}
          value={values.image_url}
          onChange={(e) => setUrl(e.target.value)}
          aria-invalid={problem !== null}
          aria-describedby="photo-url-help"
          className={inputClass}
        />
      </label>
      <p id="photo-url-help" className={`text-xs ${problem ? "text-primary" : "text-muted"}`}>
        {problem ?? "https:// 로 시작하는 그림 주소를 넣어 주세요. 써도 되는 사진(직접 찍은 사진, 공개 라이선스 사진)만 쓰세요."}
      </p>

      <label className={fieldLabel}>
        <span className={labelText}>저작자 · 라이선스</span>
        <input
          maxLength={200}
          placeholder="예: 홍길동 · CC BY 4.0 · Wikimedia Commons"
          value={values.image_credit}
          onChange={(e) => onChange({ image_credit: e.target.value })}
          className={inputClass}
        />
      </label>
      <label className={fieldLabel}>
        <span className={labelText}>사진 원본 주소</span>
        <input
          type="text"
          inputMode="url"
          maxLength={300}
          pattern="https://.+"
          title="https:// 로 시작하는 주소"
          placeholder="https://commons.wikimedia.org/wiki/File:..."
          value={values.image_source_url}
          onChange={(e) => onChange({ image_source_url: e.target.value })}
          className={inputClass}
        />
      </label>

      {spot && changed && (
        <div className="flex flex-wrap items-center justify-between gap-2">
          <p className="text-xs text-muted">
            {values.image_credit.trim()
              ? "저장하면 사진과 출처가 함께 바뀌어요."
              : "출처를 비워 두면 출처 표시 없이 저장돼요. 공개 라이선스 사진은 출처를 꼭 적어 주세요."}
          </p>
          <button type="button" onClick={() => onChange(original)} className="inline-flex items-center gap-1 text-xs font-semibold text-primary">
            <RotateCcw size={14} aria-hidden="true" />
            원래 사진으로
          </button>
        </div>
      )}
    </fieldset>
  );
}

/** 사진 한 장의 미리 보기. 주소가 없거나 불러오지 못하면 그 사실을 글로 알려 줍니다. */
function PhotoPreview({ label, url, emptyHint = "사진이 없어요" }: { label: string; url: string; emptyHint?: string }) {
  // "어떤 주소가 실패했는지"를 기억합니다(주소가 바뀌면 자동으로 다시 시도).
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  const failed = url !== "" && failedUrl === url;
  return (
    <figure className="min-w-0 flex-1 space-y-1">
      <div className="flex aspect-4/3 items-center justify-center overflow-hidden rounded-card border border-line bg-surface">
        {url && !failed ? (
          <img src={url} alt={label} onError={() => setFailedUrl(url)} className="size-full object-cover" />
        ) : (
          <span className="flex flex-col items-center gap-1 px-2 text-center text-xs text-muted">
            <ImageOff size={20} aria-hidden="true" />
            {failed ? "사진을 불러오지 못했어요. 주소를 확인해 주세요." : emptyHint}
          </span>
        )}
      </div>
      <figcaption className="text-center text-xs text-muted">{label}</figcaption>
    </figure>
  );
}

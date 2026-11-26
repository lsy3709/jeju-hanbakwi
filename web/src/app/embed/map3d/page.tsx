"use client";

// 이 파일이 하는 일: 3D 지도만 화면 가득 보여 주는 주소(/embed/map3d). 앱(Flutter)이 웹뷰로 이 주소를 띄웁니다.
// 필터는 탐색 화면과 같은 쿼리(?q=&theme=&area=&category=&indoor=)를 그대로 받습니다. 한 번 만든 3D 화면을 웹과 앱이 함께 씁니다.
import { Suspense, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import { SpotMap3DView } from "@/components/SpotMap3DView";
import { ErrorBox, Loading } from "@/components/States";
import { useSpotSearch } from "@/hooks/useSpotSearch";
import { parseExploreQuery } from "@/lib/exploreFilters";

export default function EmbedMap3DPage() {
  return (
    <Suspense fallback={<Loading />}>
      <EmbedMap3D />
    </Suspense>
  );
}

function EmbedMap3D() {
  const searchParams = useSearchParams();
  const { filters } = useMemo(() => parseExploreQuery(searchParams), [searchParams]);
  const { list, reload } = useSpotSearch(filters);

  // fixed inset-0: 위쪽 메뉴와 아래쪽 탭을 덮고 화면 전체를 씁니다(앱에는 앱의 메뉴가 따로 있으니까요).
  return (
    <div className="fixed inset-0 z-50 bg-sand">
      {list === null ? (
        <Loading />
      ) : list.error && list.items.length === 0 ? (
        <ErrorBox message={list.error} onRetry={reload} />
      ) : (
        <SpotMap3DView spots={list.items} linkToDetail={false} className="h-full w-full" />
      )}
    </div>
  );
}

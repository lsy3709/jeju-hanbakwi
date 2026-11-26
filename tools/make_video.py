"""기능 구현 영상 만들기 — 배포된 웹을 실제 브라우저로 조작하며 녹화하고, 무료 음성 합성(edge-tts)으로 해설을 붙입니다.

쓰는 법 (저장소 맨 위 폴더에서):
    python tools/make_video.py                      # 배포 주소로
    python tools/make_video.py http://localhost:3000

필요한 것: pip install playwright edge-tts pillow, playwright install chromium, ffmpeg(PATH 또는 C:/ffmpeg/bin)
결과: tmp_video/jeju_intro.mp4  (작업 파일은 tmp_video/work/ — git 에 올리지 않습니다)
"""
import asyncio
import io
import json
import shutil
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

import edge_tts
from PIL import Image
from playwright.sync_api import sync_playwright

WEB = (sys.argv[1] if len(sys.argv) > 1 else "https://jeju-hanbakwi-web.vercel.app").rstrip("/")
ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / "tmp_video" / "work"
OUT = ROOT / "tmp_video" / "jeju_intro.mp4"
VOICE = "ko-KR-SunHiNeural"
W, H = 1280, 720
q = urllib.parse.quote


def tool(name):
    found = shutil.which(name)
    return found or f"C:/ffmpeg/bin/{name}.exe"


FFMPEG, FFPROBE = tool("ffmpeg"), tool("ffprobe")

# 장면: (이름, 해설). 화면 조작은 아래 record() 에서 이름으로 고릅니다.
SCENES = [
    ("home", "제주 한 바퀴는 날씨와 취향에 맞는 제주 여행지를 찾고, AI 가 일정을 짜 주는 서비스입니다. 홈에서는 오늘 날씨를 보고 어울리는 곳을 먼저 추천합니다."),
    ("explore", "탐색에서는 검색어와 테마, 지역, 실내외로 여행지를 좁힙니다. 지금은 바다 테마에 실외만 골랐습니다."),
    ("places", "약국, 편의점, 숙소 같은 편의 시설 백이십 곳도 분류를 골라 찾을 수 있습니다."),
    ("map", "같은 결과를 지도에서 핀으로 볼 수 있습니다."),
    ("map3d", "삼 디 지도는 한라산과 오름의 높낮이를 세워서 보여 줍니다. 블렌더로 만든 돌하르방이 한라산 위에 서 있습니다."),
    ("fantasy", "판타지 지도는 제주도 전체를 블렌더 모델 하나로 만든 화면입니다. 핀을 누르면 장소 이름이 나옵니다."),
    ("night", "하늘 단추를 누르면 낮과 밤이 바뀝니다. 밤에는 별이 뜨고 마을에 불이 켜집니다."),
    ("detail", "상세 화면에는 사진과 출처, 소개 글, 위치 지도가 있습니다."),
    ("planner", "AI 플래너에 여행을 말로 설명하면, AI 가 우리 데이터에서 장소를 골라 일자별 일정을 짜 줍니다."),
    ("result", "일정에 나온 장소는 모두 우리 데이터베이스에 있는 곳입니다. 웹과 앱은 같은 서버를 함께 쓰고, 코드는 깃허브에 공개되어 있습니다."),
]

CAPTION_JS = """
(() => {
  const show = () => {
    let text = ''; try { text = sessionStorage.getItem('cap') || ''; } catch (e) { return; }
    let el = document.getElementById('__cap');
    if (!el) {
      el = document.createElement('div');
      el.id = '__cap';
      el.style.cssText = 'position:fixed;left:50%;bottom:22px;transform:translateX(-50%);z-index:2147483647;' +
        'max-width:1100px;padding:10px 20px;border-radius:12px;background:rgba(20,20,20,.82);color:#fff;' +
        'font:500 20px/1.45 "Malgun Gothic",sans-serif;text-align:center;pointer-events:none;word-break:keep-all';
      (document.body || document.documentElement).appendChild(el);
    }
    el.textContent = text;
    el.style.display = text ? 'block' : 'none';
  };
  window.__showCap = show;
  if (document.body) show(); else document.addEventListener('DOMContentLoaded', show);
})();
"""


async def speak():
    """장면마다 해설 음성(mp3)을 만들고 길이(초)를 돌려줍니다."""
    lengths = {}
    for name, text in SCENES:
        path = WORK / f"{name}.mp3"
        await edge_tts.Communicate(text, VOICE, rate="+4%").save(str(path))
        out = subprocess.run([FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                             capture_output=True, text=True, check=True).stdout
        lengths[name] = float(out.strip())
    return lengths


def orange_pin(page, box):
    """캔버스에서 핀 색(감귤 오렌지)에 가까운 점 하나를 찾습니다."""
    im = Image.open(io.BytesIO(page.screenshot())).convert("RGB")
    pts = [(x, y) for y in range(int(box["y"]) + 60, int(min(H, box["y"] + box["height"])) - 90, 3)
           for x in range(int(box["x"]) + 30, int(box["x"] + box["width"]) - 30, 3)
           if (lambda c: c[0] > 215 and 85 < c[1] < 135 and c[2] < 60)(im.getpixel((x, y)))]
    return pts[len(pts) // 2] if pts else None


def record(lengths):
    marks = []  # (이름, 영상 시작부터의 초)
    with sync_playwright() as p:
        browser = p.chromium.launch(args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
        ctx = browser.new_context(viewport={"width": W, "height": H}, record_video_dir=str(WORK), record_video_size={"width": W, "height": H})
        ctx.add_init_script(CAPTION_JS)
        page = ctx.new_page()
        t0 = time.time()

        def caption(text):
            page.evaluate("t => { try { sessionStorage.setItem('cap', t); window.__showCap && window.__showCap(); } catch (e) {} }", text)

        def begin(name):
            """해설을 시작할 때 부릅니다. 자막을 띄우고 시작 시각을 적습니다."""
            caption(dict(SCENES)[name])
            marks.append((name, time.time() - t0))
            return time.time() + lengths[name] + 0.7

        def hold(until):
            page.wait_for_timeout(max(0, int((until - time.time()) * 1000)))

        def scroll(total, steps=24, pause=90):
            for _ in range(steps):
                page.mouse.wheel(0, total / steps)
                page.wait_for_timeout(pause)

        def go(path, settle):
            caption("")
            page.goto(WEB + path)
            page.wait_for_timeout(settle)

        # 1. 홈
        go("/", 4500)
        end = begin("home")
        page.wait_for_timeout(3500); scroll(520); hold(end)

        # 2. 탐색 — 테마 · 실외
        go(f"/explore?theme={q('바다')}&indoor=false", 3500)
        end = begin("explore")
        page.wait_for_timeout(2500); scroll(420); hold(end)

        # 3. 편의 시설
        go(f"/explore?category={q('약국')}", 3500)
        end = begin("places")
        page.wait_for_timeout(2000); scroll(360); hold(end)

        # 4. 지도
        go(f"/explore?category={q('교통')}&view=map", 5000)
        page.locator(".leaflet-container").scroll_into_view_if_needed(); page.wait_for_timeout(800)
        end = begin("map"); hold(end)

        # 5. 3D 지도
        go("/explore?view=3d", 1000)
        page.wait_for_selector("canvas.maplibregl-canvas", timeout=60000)
        page.evaluate("document.querySelector('canvas.maplibregl-canvas').scrollIntoView({block: 'start'}); window.scrollBy(0, -64)")
        page.wait_for_timeout(9000)
        end = begin("map3d")
        box = page.locator("canvas.maplibregl-canvas").bounding_box()
        cx, cy = box["x"] + box["width"] / 2, min(H - 140, box["y"] + box["height"] / 2)
        page.wait_for_timeout(1500)
        page.mouse.move(cx, cy)
        page.keyboard.down("Control")           # 한 손가락 끌기 대신 Ctrl + 휠로 확대
        for _ in range(6):
            page.mouse.wheel(0, -160); page.wait_for_timeout(450)
        page.keyboard.up("Control")
        hold(end)

        # 6. 판타지 지도 — 핀 고르기
        go("/explore?view=fantasy", 1000)
        page.wait_for_selector("canvas", timeout=60000)
        page.evaluate("document.querySelector('canvas').scrollIntoView({block: 'start'}); window.scrollBy(0, -64)")   # 지도가 화면에 가득 오게
        page.wait_for_timeout(9000)
        end = begin("fantasy")
        page.wait_for_timeout(4000)
        pin = orange_pin(page, page.locator("canvas").bounding_box())
        if pin:
            page.mouse.move(*pin, steps=12); page.mouse.click(*pin)
        hold(end)

        # 7. 낮과 밤
        end = begin("night")
        sky = page.get_by_role("button", name="하늘")
        page.wait_for_timeout(1200); sky.click()      # 낮
        page.wait_for_timeout(2600); sky.click()      # 밤
        hold(end + 2.5)

        # 8. 상세
        go("/explore", 3000)
        page.locator("a[href^='/spots/']").first.click(); page.wait_for_timeout(4500)
        end = begin("detail")
        page.wait_for_timeout(2500); scroll(700, steps=30); hold(end)

        # 9. AI 플래너
        go("/planner", 3000)
        end = begin("planner")
        page.locator("textarea").first.click()
        page.keyboard.type("부모님과 많이 걷지 않고 바다가 보이는 곳 위주로", delay=55)
        page.wait_for_timeout(600)
        page.get_by_role("button", name="일정 짜기").click()
        try:
            page.wait_for_selector("text=1일차", timeout=60000)
        except Exception:
            print("! 60초 안에 일정이 나오지 않았습니다")
        hold(end)

        # 10. 결과
        end = begin("result")
        page.wait_for_timeout(1500); scroll(900, steps=40, pause=140); hold(end + 1.0)
        caption("")
        page.wait_for_timeout(600)

        video = page.video
        ctx.close()
        raw = Path(video.path())
        browser.close()
    return raw, marks


def mux(raw, marks):
    cmd = [FFMPEG, "-y", "-v", "error", "-i", str(raw)]
    parts = []
    for i, (name, at) in enumerate(marks, start=1):
        cmd += ["-i", str(WORK / f"{name}.mp3")]
        ms = int(at * 1000)
        parts.append(f"[{i}:a]adelay={ms}|{ms}[a{i}]")
    mix = "".join(f"[a{i}]" for i in range(1, len(marks) + 1))
    graph = ";".join(parts) + f";{mix}amix=inputs={len(marks)}:normalize=0[aout]"
    cmd += ["-filter_complex", graph, "-map", "0:v", "-map", "[aout]",
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "24", "-preset", "medium", "-r", "25",
            "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", str(OUT)]
    subprocess.run(cmd, check=True)


def main():
    if WORK.exists():
        shutil.rmtree(WORK)
    WORK.mkdir(parents=True)
    lengths = asyncio.run(speak())
    print("해설 길이(초):", {k: round(v, 1) for k, v in lengths.items()})
    raw, marks = record(lengths)
    json.dump({"web": WEB, "voice": VOICE, "marks": marks}, open(WORK / "marks.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    mux(raw, marks)
    print("만든 파일:", OUT, f"{OUT.stat().st_size / 1e6:.1f}MB")


if __name__ == "__main__":
    main()

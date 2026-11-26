# 샘플 사진 출처

샘플 관광지 사진은 모두 [위키미디어 공용](https://commons.wikimedia.org)에서 가져왔고, 각 사진의 라이선스(CC BY · CC BY-SA · CC0 · 퍼블릭 도메인)에 따라 저작자와 라이선스를 표시합니다.

- 사진 파일은 `api/static/photos/` 에 있고(가로 960px, 원본을 고치지 않고 크기만 줄인 것), 우리 서버가 `/photos/S001.jpg` 주소로 내줍니다. 수업 중 바깥 사이트 접속이 막혀도 사진이 나오게 하려는 것입니다.
- 화면에서는 상세 화면의 사진 아래에 출처를 보여 줍니다(`image_credit`, `image_source_url`).
- 사진마다 아래 표의 라이선스가 그대로 적용됩니다(저장소의 다른 코드와 별개). CC BY-SA 사진을 고쳐서 다시 배포하면 같은 라이선스를 붙여야 합니다.
- 사진이 있는 곳 55 / 전체 68. 알맞은 공개 사진을 찾지 못한 곳은 대체 그림으로 나옵니다.
- 내 주제로 바꿀 때는 직접 찍은 사진이나 TourAPI 사진(한국관광공사, 공공누리 조건 확인)을 쓰세요.

## 편의 시설의 분류별 대표 사진

편의 시설(숙소 · 게스트하우스 · 병원 · 약국 · 편의점 · 교통)은 곳마다 사진을 구할 수 없어, 분류마다 한 장을 함께 씁니다. 파일은 `api/static/photos/places/` 에 있습니다(가로 960px 이하, 원본을 고치지 않고 크기만 줄인 것). 그 곳의 실제 모습이 아니라 분류를 대표하는 예시 사진입니다. 자세한 것은 [places.md](places.md).

| 파일 | 분류 | 사진의 내용 | 저작자 | 라이선스 | 원본 |
|---|---|---|---|---|---|
| `places/lodging.jpg` | 숙소 | 제주의 호텔 건물 | Abasaa | 퍼블릭 도메인 | [보기](https://commons.wikimedia.org/wiki/File:Ramada_Plaza_Jeju_Hotel.JPG) |
| `places/guesthouse.jpg` | 게스트하우스 | 한옥 게스트하우스 | Korea.net / Korean Culture and Information Service (Jeon Han) | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:KOCIS_Korea_Hanok_GuestHouse_01_(7596121988).jpg) |
| `places/hospital.jpg` | 병원 | 제주의 병원 건물 | thddbwnd | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_National_University_Hospital_2.JPG) |
| `places/pharmacy.jpg` | 약국 | 약국의 진열창 | Andrewssi2 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:YakPharmacy.jpg) |
| `places/store.jpg` | 편의점 | 편의점 입구 | LandAndTree | CC0 | [보기](https://commons.wikimedia.org/wiki/File:GS25_Okcheon_Museong_Branch_20240730.jpg) |
| `places/transit.jpg` | 교통 | 제주 시내의 버스 정류장과 버스 | 제주특별자치도청 대중교통과 | 공공누리 제1유형(출처 표시) | [보기](https://commons.wikimedia.org/wiki/File:Island_Bus_Stop_and_Double-door_Bus_in_Jeju_City_Korea.jpg) |

## 추천 식당의 분류별 대표 사진

추천 식당(한식 · 해산물 · 고기구이 · 국수 · 카페)도 분류마다 한 장을 함께 씁니다. 파일은 `api/static/photos/places/food_*.jpg` 입니다(800×600 으로 가운데를 잘라 줄인 것). 그 식당의 실제 모습이 아니라 분류를 대표하는 예시 사진입니다. 자세한 것은 [restaurants.md](restaurants.md).

| 파일 | 분류 | 사진 | 저작자 | 라이선스 | 원본 |
|---|---|---|---|---|---|
| `places/food_korean.jpg` | 한식 | 한정식 상차림 | egg (Hong, Yun Seon) | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine-Hanjeongsik-03.jpg) |
| `places/food_seafood.jpg` | 해산물 | 회 한 접시 | littlepepper | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Hoe_(raw_fish).jpg) |
| `places/food_bbq.jpg` | 고기구이 | 석쇠 위의 고기 | eommina | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_BBQ.jpg) |
| `places/food_noodle.jpg` | 국수 | 제주 고기국수 | 신동혁 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Gogi-guksu.jpg) |
| `places/food_cafe.jpg` | 카페 | 커피 한 잔 | Julius Schorzman | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:A_small_cup_of_coffee.JPG) |

## 관광지 사진

| 파일 | 관광지 | 저작자 | 라이선스 | 원본 |
|---|---|---|---|---|
| `S001.jpg` | 성산일출봉 | Korea.net / Korean Culture and Information Service | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Seongsan_Ilchulbong_from_the_air.jpg) |
| `S002.jpg` | 한라산 어리목 탐방로 | Basile Morin | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Wooden_staircase_steps_in_the_forest_of_Hallasan_Park_Eorimok_Trail_at_dusk_on_Jeju_Island_in_South_Korea.jpg) |
| `S003.jpg` | 만장굴 | Gary Cycles | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Manjanggul_Lava_tube.jpg) |
| `S004.jpg` | 협재해수욕장 | Lcarrion88 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Hyeopjae_Beach_Scenery.jpg) |
| `S005.jpg` | 우도 | Integral | CC BY-SA 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Red_algal_nodule_beach.JPG) |
| `S006.jpg` | 천지연폭포 | Martin Chen | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korea-Jeju-Cheonjiyeon_Waterfall-01.jpg) |
| `S007.jpg` | 정방폭포 | Abasaa | Public domain | [보기](https://commons.wikimedia.org/wiki/File:Jeongbang_Waterfall_01.JPG) |
| `S008.jpg` | 섭지코지 | song songroov | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Seopjikoji-ro,_Seongsan-eup,_Seogwipo-si,_Jeju-do,_South_Korea_-_panoramio_-_song_songroov_(7).jpg) |
| `S009.jpg` | 오설록 티뮤지엄 | 골뱅이 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:O%27Sulloc_Tea_Museum,_Jeju_(%EC%98%A4%EC%84%A4%EB%A1%9D_%EB%85%B9%EC%B0%A8%EB%B0%95%EB%AC%BC%EA%B4%80,_%EC%A0%9C%EC%A3%BC)_-_panoramio.jpg) |
| `S010.jpg` | 아쿠아플라넷 제주 | Camodr25 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Hanwha_Aquaplanet_Jeju_Island_Entrance.JPG) |
| `S011.jpg` | 제주민속촌 | G41rn8 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_Folk_Village_IMG_2127.jpg) |
| `S012.jpg` | 국립제주박물관 | Republic of Korea from Seoul, Republic of Korea | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_Island_20141129_10_(15926202611).jpg) |
| `S013.jpg` | 넥슨컴퓨터박물관 | Narnars0 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Nexon_Computer_Museum.jpg) |
| `S014.jpg` | 사려니숲길 | 기나ㅏㄴ | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%EC%82%AC%EB%A0%A4%EB%8B%88%EC%88%B2%EA%B8%B8_%EC%99%B8%EB%B6%80_%EB%AA%A8%EC%8A%B5.jpg) |
| `S015.jpg` | 비자림 | Sgroey | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Bijarim_nutmeg_forest_jeju_korea_3.jpg) |
| `S016.jpg` | 새별오름 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Saebyeol_Oreum_03.jpg) |
| `S017.jpg` | 용머리해안 | Sadopaul | CC BY 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Cliff_at_Yongmeori_Beach_(2025-01)_2.jpg) |
| `S018.jpg` | 카멜리아힐 | 골뱅이 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Waterfall,_Camellia_Hill,_Jeju_(%ED%8F%AD%ED%8F%AC,_%EC%A0%9C%EC%A3%BC_%EC%B9%B4%EB%A9%9C%EB%A6%AC%EC%95%84%ED%9E%90)_-_panoramio.jpg) |
| `S019.jpg` | 동문재래시장 | thddbwnd | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_dongmun_market_4.JPG) |
| `S020.jpg` | 서귀포매일올레시장 | Seefooddiet | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Seogwipo_Maeil_Olle_Market_03.jpg) |
| `S021.jpg` | 함덕해수욕장 | Hong Da Hyeon | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Hamdeok_Beach.jpg) |
| `S022.jpg` | 월정리해변 | Sgroey | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_woljeongri_beach_2.jpg) |
| `S023.jpg` | 쇠소깍 | Jocelyndurrey | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%EC%87%A0%EC%86%8C%EA%B9%8D_(5).jpg) |
| `S024.jpg` | 산방산 | Korea.net / Korean Culture and Information Service | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Sanbangsan_(5983281424).jpg) |
| `S027.jpg` | 제주항공우주박물관 | Hunini | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_Aerospace_Museum_20140606-01.JPG) |
| `S028.jpg` | 에코랜드 테마파크 | Christian Bolz | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_Ecoland.jpg) |
| `S030.jpg` | 한림공원 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Hallim_Park_21.jpg) |
| `S031.jpg` | 대포 주상절리대 | Bernard Gagnon | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Daepo_Jusangjeolli_Cliff_02.jpg) |
| `S032.jpg` | 용두암 | Bohao Zhao | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:%EC%A0%9C%EC%A3%BC_%ED%95%B4%EC%95%88_Yongduam_Rock_-_panoramio.jpg) |
| `S033.jpg` | 이호테우해수욕장 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Iho_Tewoo_Beach_05.jpg) |
| `S034.jpg` | 송악산 둘레길 | Lcarrion88 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Songaksan.jpg) |
| `S035.jpg` | 금오름 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Geum_Oreum_07.jpg) |
| `S038.jpg` | 김녕미로공원 | 골뱅이 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Gimnyeong_Maze_Park,_Jeju_(%EC%A0%9C%EC%A3%BC_%EA%B9%80%EB%85%95%EB%AF%B8%EB%A1%9C%EA%B3%B5%EC%9B%90)_-_panoramio.jpg) |
| `S039.jpg` | 제주돌문화공원 | Bernard Gagnon | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_Stone_Park_11.jpg) |
| `S041.jpg` | 천제연폭포 | Abasaa | Public domain | [보기](https://commons.wikimedia.org/wiki/File:Cheonjeyeon_Waterfall_02.JPG) |
| `S042.jpg` | 여미지식물원 | WSTAY.com | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Yeomiji.jpg) |
| `S043.jpg` | 제주4·3평화공원 | GtDX8NNO3Efn2oF6q0s3 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_4.3_Peace_Park_-_Memorial_Hall.jpg) |
| `S046.jpg` | 곽지해수욕장 | Jeong seolah | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Gwakji_Beach_in_Jeju_Island,_2022.jpg) |
| `S047.jpg` | 성읍민속마을 | Trainholic | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Seongeup_Historic_Village.jpg) |
| `S048.jpg` | 표선해수욕장 | Jocelyndurrey This photo was taken with LG G3 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%ED%91%9C%EC%84%A0%ED%95%B4%EB%B9%84%EC%B9%98%ED%95%B4%EB%B3%80_(1).jpg) |
| `S049.jpg` | 외돌개 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Oedolgae_2026_02.jpg) |
| `S050.jpg` | 중문색달해수욕장 | Jisoo-U | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Jungmun_Beach_2.jpg) |
| `S051.jpg` | 제주현대미술관 | PODO Museum (photo provided by internal archive) | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:PODO_Museum_Front_View_2025.jpg) |
| `S052.jpg` | 수월봉 | Sohyeon Bak | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Suwol_Peak_Geo_Park_3.jpg) |
| `S053.jpg` | 마라도 | https://www.flickr.com/photos/87306261@N00/ | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Marado_Buildings.jpg) |
| `S056.jpg` | 삼성혈 | Abasaa | Public domain | [보기](https://commons.wikimedia.org/wiki/File:Samseonghyeol_03.JPG) |
| `S057.jpg` | 제주목 관아 | Thddbwnd | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Gwandeokjeong_Pavilion_2.JPG) |
| `S058.jpg` | 도두봉 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Dodubong_05.jpg) |
| `S060.jpg` | 국수문화거리 | Seefooddiet | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Gogi-guksu_2024.jpg) |
| `S062.jpg` | 모슬포항 방어거리 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Moseulpo_Port_02.jpg) |
| `S063.jpg` | 세화해변 카페거리 | Bohyunlee | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%EC%84%B8%ED%99%94%ED%95%B4%EC%88%98%EC%9A%95%EC%9E%A52.JPG) |
| `S064.jpg` | 제주들불축제 | Grapesurgeon | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Saebyeol_Oreum_01.jpg) |
| `S065.jpg` | 성산일출축제 | Sukkim1996 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Sunrise_with_Seongsan_Ilchulbong.jpg) |
| `S066.jpg` | 서귀포유채꽃축제 | Joycekim77 | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Canola_Flowers_Jeju_Island-_%EC%A0%9C%EC%A3%BC%EB%8F%84_%EC%9C%A0%EC%B1%84%EA%BD%83.jpg) |
| `S067.jpg` | 제주레일바이크 | ProjectManhattan | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Jeju_Rail_Bike.jpg) |

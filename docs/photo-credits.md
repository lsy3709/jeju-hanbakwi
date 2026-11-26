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

## 추천 식당 한 곳마다의 사진 (100장, 2026-11-26 추가)

추천 식당 100곳은 사진이 모두 다릅니다. 분류마다 20장씩 위키미디어 공용의 공개 라이선스 음식 사진을 골라 식당마다 한 장씩 주었습니다. **그 식당을 찍은 사진이 아니라, 같은 종류 음식의 예시 사진입니다.** 파일은 `api/static/photos/places/food/` 에 있고(640×480 으로 가운데를 잘라 줄인 것), 목록은 `api/data/food_photos.json` 입니다. 상표 · 가격표가 크게 보이는 사진과 서로 겹치는 사진은 눈으로 보고 뺐습니다.

| 파일 | 분류 | 저작자 | 라이선스 | 원본 |
|---|---|---|---|---|
| `places/food/korean_01.jpg` | 한식 | Uwe Brodrecht | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:1667_-_Nordkorea_2015_-_von_K%C3%A4song_nach_Pj%C3%B6ngjang_(22967399002).jpg) |
| `places/food/korean_02.jpg` | 한식 | Marufish from Alor Setar, Malaysia | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:2003_1114CZ_(2699639951).jpg) |
| `places/food/korean_03.jpg` | 한식 | sangmins | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Haejangguk_(hangover_soup).jpg) |
| `places/food/korean_04.jpg` | 한식 | Arumdaum | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Gugil_Ttaro_gukbap.jpg) |
| `places/food/korean_05.jpg` | 한식 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:20150508%EC%B5%9C%EA%B4%91%EB%AA%A8DSC09689.JPG) |
| `places/food/korean_06.jpg` | 한식 | Jinho Jung | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Hwangtae-haejang-guk.jpg) |
| `places/food/korean_07.jpg` | 한식 | Dr 방원장 | CC BY 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Gul-gukbap.jpg) |
| `places/food/korean_08.jpg` | 한식 | 최광모 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:20150214-20150219%EC%B5%9C%EA%B4%91%EB%AA%A8C58.JPG) |
| `places/food/korean_09.jpg` | 한식 | egg (Hong, Yun Seon) | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_soup-Bogeo_haejangguk-01.jpg) |
| `places/food/korean_10.jpg` | 한식 | Mar del Este | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_soup_Sundae_gukbap_01.jpg) |
| `places/food/korean_11.jpg` | 한식 | egg (Hong, Yun Seon) | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_soup-Gukbap-01.jpg) |
| `places/food/korean_12.jpg` | 한식 | Suez (sophia) | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Cuisine_of_North_Korea_01.jpg) |
| `places/food/korean_13.jpg` | 한식 | by lwy | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_soup-Gulgukbap-01.jpg) |
| `places/food/korean_14.jpg` | 한식 | Korea.net / Korean Culture and Information Service (Jeon Han | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Gimhaesi_City_41.jpg) |
| `places/food/korean_15.jpg` | 한식 | Jun Seita from Palo Alto, CA, U.S. | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Asiana_Airlines_NRT_to_ICN_Business_Class_Lunch-_Bibimbap_(8300647291).jpg) |
| `places/food/korean_16.jpg` | 한식 | pcamp | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_soup-Sundae_gukbap-01.jpg) |
| `places/food/korean_17.jpg` | 한식 | Korea.net / Korean Culture and Information Service (Jeon Han | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:KORAIL_Gangjin_Gun_05.jpg) |
| `places/food/korean_18.jpg` | 한식 | Jirka Matousek | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bibim-bap_2.jpg) |
| `places/food/korean_19.jpg` | 한식 | No machine-readable author provided. Warszk assumed (based o | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Korea_style_meal.jpg) |
| `places/food/korean_20.jpg` | 한식 | Mar del Este This photo was taken with Samsung Galaxy S4 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine_hanjeongsik_Damyang_South_Korea.jpg) |
| `places/food/seafood_01.jpg` | 해산물 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:2015%EB%85%84_3%EC%9B%94_20%EC%9D%BC_%EB%B4%89%ED%8F%AC%EB%A8%B8%EA%B5%AC%EB%A6%AC%EC%A7%91_%EB%AC%BC%ED%9A%8C_DSC07477.jpg) |
| `places/food/seafood_02.jpg` | 해산물 | 김형찬 | CC BY 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Jaridom-mulhoe.jpg) |
| `places/food/seafood_03.jpg` | 해산물 | 사람냄새 | CC BY 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Jeonbok-mulhoe_2.jpg) |
| `places/food/seafood_04.jpg` | 해산물 | by Tong-Seob Kim at Flickr from Incheon, South Korea | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine-Jeju-Jari_mulhoe-Sliced_raw_damselfish_with_spicy_sauce-01.jpg) |
| `places/food/seafood_05.jpg` | 해산물 | 대경라이프 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Mulhoe_1.jpg) |
| `places/food/seafood_06.jpg` | 해산물 | 대경라이프 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Mulhoe_2.jpg) |
| `places/food/seafood_07.jpg` | 해산물 | 사람냄새 | CC BY 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Mulhoe.jpg) |
| `places/food/seafood_08.jpg` | 해산물 | by LWY at flickr | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean.cuisine-Hoe-01.jpg) |
| `places/food/seafood_09.jpg` | 해산물 | Gaël Chardon | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine-Hoe-03.jpg) |
| `places/food/seafood_10.jpg` | 해산물 | Rhett Sutphin | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine-Hoe-04.jpg) |
| `places/food/seafood_11.jpg` | 해산물 | by karendotcom127 | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean.cuisine-Saengseon_gui-01.jpg) |
| `places/food/seafood_12.jpg` | 해산물 | Brücke-Osteuropa | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Haemultang.jpg) |
| `places/food/seafood_13.jpg` | 해산물 | Jaydub666 | CC BY 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Home_Made_Haemultang.jpg) |
| `places/food/seafood_14.jpg` | 해산물 | by &lt;==Manji==&gt; at Flickr | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_grilled_abalone-Jeonbok_gui-01.jpg) |
| `places/food/seafood_15.jpg` | 해산물 | Daniel Moskowitz | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Godeungeo-gui.jpg) |
| `places/food/seafood_16.jpg` | 해산물 | by david&amp;alina at Flickr | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_cuisine-Godeungeo_gui-01.jpg) |
| `places/food/seafood_17.jpg` | 해산물 | lazy fri13th | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Ganjang-gejang_1.jpg) |
| `places/food/seafood_18.jpg` | 해산물 | Jordi Sanchez | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Jogae-gui.jpg) |
| `places/food/seafood_19.jpg` | 해산물 | bryan... | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Jogae-gui_4.jpg) |
| `places/food/seafood_20.jpg` | 해산물 | Korea.net / Korean Culture and Information Service | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:KOCIS_maeuntang,_spicy_fish_soup_(5035733642).jpg) |
| `places/food/bbq_01.jpg` | 고기구이 | 毒島みるく | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Roasted_beef_ribs_on_rice_lunch_box_of_NewDays.jpg) |
| `places/food/bbq_02.jpg` | 고기구이 | Judgefloro | CC0 | [보기](https://commons.wikimedia.org/wiki/File:6685Baliuag_Bulacan_Landmarks_during_the_2020_coronavirus_pandemic_07.jpg) |
| `places/food/bbq_03.jpg` | 고기구이 | Minseong Kim | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Beef_Bulgogi(BBQ).jpg) |
| `places/food/bbq_04.jpg` | 고기구이 | Debbie Tingzon | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bul-gogi.jpg) |
| `places/food/bbq_05.jpg` | 고기구이 | pelican from Tokyo, Japan | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_(32834714011).jpg) |
| `places/food/bbq_06.jpg` | 고기구이 | pelican from Tokyo, Japan | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_(5019171427).jpg) |
| `places/food/bbq_07.jpg` | 고기구이 | 국립국어원 | CC BY-SA 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_2.jpg) |
| `places/food/bbq_08.jpg` | 고기구이 | anokarina | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_5.jpg) |
| `places/food/bbq_09.jpg` | 고기구이 | anokarina | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_6.jpg) |
| `places/food/bbq_10.jpg` | 고기구이 | stu_spivack | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_8.jpg) |
| `places/food/bbq_11.jpg` | 고기구이 | Graham Hills | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_9.jpg) |
| `places/food/bbq_12.jpg` | 고기구이 | Cinnamontrees | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_cooked.jpg) |
| `places/food/bbq_13.jpg` | 고기구이 | Brücke-Osteuropa | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Bulgogi_in_Seoul.jpg) |
| `places/food/bbq_14.jpg` | 고기구이 | by hellochris | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean.cuisine-Samgyeopsal-01.jpg) |
| `places/food/bbq_15.jpg` | 고기구이 | jinsoo jang | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Samgyeopsal-gui.jpg) |
| `places/food/bbq_16.jpg` | 고기구이 | ProjectManhattan | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Samgyeopsal_2.jpg) |
| `places/food/bbq_17.jpg` | 고기구이 | star5112 (a flickr user) | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean.food-Galbi-01.jpg) |
| `places/food/bbq_18.jpg` | 고기구이 | ayustety (a flickr user) | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean.food-Galbi-03.jpg) |
| `places/food/bbq_19.jpg` | 고기구이 | mino park | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Moksal-gui_2.jpg) |
| `places/food/bbq_20.jpg` | 고기구이 | me | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_barbecue-Samgyeopsal-08.jpg) |
| `places/food/noodle_01.jpg` | 국수 | Seefooddiet | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Gogi-guksu_2024.jpg) |
| `places/food/noodle_02.jpg` | 국수 | chomjong | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Kong-guksu_1.jpg) |
| `places/food/noodle_03.jpg` | 국수 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:20150912%EC%B5%9C%EA%B4%91%EB%AA%A8DSC02772.JPG) |
| `places/food/noodle_04.jpg` | 국수 | 신동혁 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Gogi-guksu.jpg) |
| `places/food/noodle_05.jpg` | 국수 | chomjong | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Kong-guksu_2.jpg) |
| `places/food/noodle_06.jpg` | 국수 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:20151003%EB%A7%89%EA%B5%AD%EC%88%98RX10DSC03107.jpg) |
| `places/food/noodle_07.jpg` | 국수 | Ksait | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Gogiguksu_gulmak.jpg) |
| `places/food/noodle_08.jpg` | 국수 | Uri Tours | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:PIFF_2014_Opening_Ceremony_Dinner_for_Festival_Delegates_(15170795648).jpg) |
| `places/food/noodle_09.jpg` | 국수 | lazy fri13th | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Kong-guksu_3.jpg) |
| `places/food/noodle_10.jpg` | 국수 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:20151003%EC%B5%9C%EA%B4%91%EB%AA%A8RX10DSC03105.JPG) |
| `places/food/noodle_11.jpg` | 국수 | 채지형 | CC BY 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%EC%A0%9C%EC%A3%BC%EB%8F%84_%EA%B3%A0%EA%B8%B0%EA%B5%AD%EC%88%98_12.jpg) |
| `places/food/noodle_12.jpg` | 국수 | KKPCW | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%E4%B8%B8%E6%BA%90%E5%86%B7%E9%BA%BA.jpg) |
| `places/food/noodle_13.jpg` | 국수 | Hyeonyoung Lee 21 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Kong-guksu_made_from_Paju_Jangdan_Beans.jpg) |
| `places/food/noodle_14.jpg` | 국수 | lazy fri13th | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Kong-guksu.jpg) |
| `places/food/noodle_15.jpg` | 국수 | 최광모 | CC0 | [보기](https://commons.wikimedia.org/wiki/File:20151003%EC%B5%9C%EA%B4%91%EB%AA%A8RX10DSC03108.JPG) |
| `places/food/noodle_16.jpg` | 국수 | vedanti | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Kongguksu_(soybean_cold_noodle).jpg) |
| `places/food/noodle_17.jpg` | 국수 | lazy fri13th | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Deul-gireum-mak-guksu_1.jpg) |
| `places/food/noodle_18.jpg` | 국수 | lazy fri13th | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Deul-gireum-mak-guksu.jpg) |
| `places/food/noodle_19.jpg` | 국수 | by Junho Jung at Flickr from South Korea | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Korea-Gangneung-Makguksu-Cold_buckwheat_noodle_dish-01.jpg) |
| `places/food/noodle_20.jpg` | 국수 | pcamp | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Korean_noodles-Makguksu-01.jpg) |
| `places/food/cafe_01.jpg` | 카페 | Mykim0918 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:%22a_cup_of_cpffee_at_munsan_coffee_cafe_2021_from145.jpg%22.jpg) |
| `places/food/cafe_02.jpg` | 카페 | 국립국어원 | CC BY-SA 2.0 kr | [보기](https://commons.wikimedia.org/wiki/File:Bingsu_2.jpg) |
| `places/food/cafe_03.jpg` | 카페 | Kuba Bożanowski from Warsaw, Poland | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:And_another!_(3146040967).jpg) |
| `places/food/cafe_04.jpg` | 카페 | Laliv g | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Bingsu_dessert_Tel_Aviv.jpg) |
| `places/food/cafe_05.jpg` | 카페 | 森正洋デザイン研究所 (Mori Masahiro Design Studio, LLC.) | CC BY 3.0 | [보기](https://commons.wikimedia.org/wiki/File:1958_CoffeeSet_Masahiro-Mori.jpg) |
| `places/food/cafe_06.jpg` | 카페 | Fastily | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Apple_latte_art_2_2024-02-02.jpg) |
| `places/food/cafe_07.jpg` | 카페 | Gerard van de Bruinhorst | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:ASC_Leiden_-_Rwanda_2021_-_056_-_A_decorative_white_tree_of_cream_in_a_cup_of_coffee_-_Kigali.jpg) |
| `places/food/cafe_08.jpg` | 카페 | Peachyeung316 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:A_Cappuccino_at_Amante.jpg) |
| `places/food/cafe_09.jpg` | 카페 | Tmannya | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Bingsu.jpg) |
| `places/food/cafe_10.jpg` | 카페 | Photograph by Mike Peel (www.mikepeel.net). | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:At_Vienna_2025_480.jpg) |
| `places/food/cafe_11.jpg` | 카페 | Peachyeung316 | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:A_cup_of_coffee_in_Mohk.jpg) |
| `places/food/cafe_12.jpg` | 카페 | Infrogmation of New Orleans | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Black_Sesame_Bingsu_Terrytown_LA.JPG) |
| `places/food/cafe_13.jpg` | 카페 | Athena Lam thecupandtheroad | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Athena_Lam_2016_(Unsplash).jpg) |
| `places/food/cafe_14.jpg` | 카페 | Geun young Kim | CC0 | [보기](https://commons.wikimedia.org/wiki/File:Cheese-bingsu.jpg) |
| `places/food/cafe_15.jpg` | 카페 | Shixart1985 | CC BY 2.0 | [보기](https://commons.wikimedia.org/wiki/File:A_person_holds_a_cup_of_cappuccino_featuring_intricate_latte_art,_sitting_at_a_caf%C3%A9_table.jpg) |
| `places/food/cafe_16.jpg` | 카페 | CYAN | CC BY-SA 4.0 | [보기](https://commons.wikimedia.org/wiki/File:Chocolate_bingsu_0a.jpg) |
| `places/food/cafe_17.jpg` | 카페 | Koperczak (talk) 12:35, 8 March 2009 (UTC) | Public domain | [보기](https://commons.wikimedia.org/wiki/File:19th_century_tea-_and_coffee-cups_anaglyph.jpg) |
| `places/food/cafe_18.jpg` | 카페 | Guillaume Blum | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:BC_trip_(9533284911).jpg) |
| `places/food/cafe_19.jpg` | 카페 | bryan... from Taipei, Taiwan | CC BY-SA 2.0 | [보기](https://commons.wikimedia.org/wiki/File:Food_(31881044841).jpg) |
| `places/food/cafe_20.jpg` | 카페 | Pemba.mpimaji | CC BY-SA 3.0 | [보기](https://commons.wikimedia.org/wiki/File:Bem_Vindo_1.jpg) |

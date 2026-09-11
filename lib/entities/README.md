# entities

도메인 모델과 그 최소 표현을 담는 레이어입니다. 관심/검색/상세 3화면이 공유하는 핵심 도메인이 위치합니다.

- `quote/` — 시세 (Quote 모델, Repository, provider)
- (Phase 1에서 추가) `search/`, `stock_meta/`, `daily_quote/`

도메인 전용 계산(등락률, 시가총액 등)은 해당 도메인 폴더 안에 둡니다. `shared`만 참조할 수 있습니다.

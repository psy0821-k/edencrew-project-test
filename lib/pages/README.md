# pages

라우트 단위 화면 조립 레이어입니다. 화면 하나(관심/검색/상세)에 대응합니다.

- `watchlist_page.dart`
- `search_page.dart`
- `stock_detail_page.dart`

Page는 `widgets`/`features`/`entities`/`shared`를 조립만 할 뿐, Repository 등 데이터 접근 구현체를 직접 생성하지 않습니다.

# Issue #31 — 검색 화면 뼈대: 입력창 + 초기 상태 + 결과 목록(하이라이트) + 결과없음 상태

## 시그니처

```dart
// lib/features/search-list/search_result_row.dart
/// 검색 결과 행 하나. 종목명(검색어 일치 구간 하이라이트) + 종목코드 · 시장 표시.
/// 별 아이콘/탭 인터랙션은 이후 이슈(#33, #35)에서 추가.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.query,
  });

  /// 표시할 검색 결과 하나.
  final SearchResult result;

  /// 하이라이트 계산에 쓰이는 정규화된 검색어. (normalizeQuery 결과를 그대로 전달)
  final String query;

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// lib/features/search-list/search_input_field.dart
/// 검색 입력창 + 우측 지우기(X) 버튼.
class SearchInputField extends StatelessWidget {
  const SearchInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;

  /// 텍스트가 바뀔 때마다 호출한다. (원본 문자열 그대로 전달 — 정규화는 상위에서)
  final ValueChanged<String> onChanged;

  /// X 버튼을 탭했을 때 호출한다. (controller.clear()와 상태 초기화는 호출부 책임)
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// lib/pages/search_page.dart (Phase 0 더미 교체)
/// 검색 화면. searchDebouncerNotifierProvider를 구독해
/// 초기/결과/결과없음/에러 상태를 전환한다.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _rawQuery = ''; // 사용자가 입력한 원본 문자열(정규화 전). 결과없음 문구에 그대로 사용.

  @override
  Widget build(BuildContext context) { ... }
}
```

### 상태별 EmptyStateView 사용

- **초기 상태** (`_rawQuery`가 비었거나 `normalizeQuery(_rawQuery).length < 2`):
  `EmptyStateView(iconAsset: 'assets/icons/ico_search.svg', title: '종목을 검색해 보세요', caption: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다')`
- **결과없음 상태** (`AsyncData([])`이고 유효한 검색어인 경우):
  `EmptyStateView(iconAsset: 'assets/icons/ico_search_empty.svg', title: '검색 결과가 없습니다', caption: "'$_rawQuery'와\n일치하는 검색 결과를 찾지 못했습니다.")`
- **에러 상태** (`AsyncError`):
  `EmptyStateView(iconAsset: 'assets/icons/ico_search_empty.svg', title: '검색 결과가 없습니다', caption: '검색 중 문제가 발생했습니다')`

세 상태 모두 이슈 #30에서 만든 `EmptyStateView`를 그대로 재사용하고, 문구/아이콘만 다르게 넘긴다.
`ico_search_empty.svg`는 이번 이슈에서 처음 사용한다(에셋 자체는 이미 `assets/icons/`에 존재).

## 테스트 시나리오

### SearchResultRow

- [정상] 종목명 안에 검색어와 일치하는 구간이 있으면 해당 구간이 `searchHighlight` 스타일로 강조되고 나머지는 일반 텍스트로 표시해야 한다
- [정상] `종목코드 · 시장` 형식의 보조 텍스트를 표시해야 한다
- [경계] query가 빈 문자열이면 하이라이트 없이 종목명 전체를 일반 텍스트로 표시해야 한다
- [경계] 종목명이 매우 길면 별 아이콘 영역과 겹치지 않도록 1줄 + 말줄임표(ellipsis)로 표시해야 한다

### SearchInputField

- [정상] 텍스트를 입력하면 onChanged가 입력된 원본 문자열로 호출되어야 한다
- [정상] X 버튼을 탭하면 onClear가 호출되어야 한다
- [경계] 텍스트가 비어 있어도 X 버튼이 항상 노출되어야 한다 (탭 시 onClear만 호출되면 되므로 비활성화하지 않음)

### SearchPage

- [정상] 처음 진입(검색어 없음)하면 초기 상태(`돋보기 아이콘` + `종목을 검색해 보세요` + 안내 문구)를 보여줘야 한다
- [경계] 1글자만 입력하고 300ms 경과하면 요청이 발생하지 않고 초기 상태를 그대로 유지해야 한다
- [경계] 공백만 연속 입력하고 300ms 경과하면 초기 상태를 그대로 유지해야 한다
- [정상] 2글자 이상 유효한 종목명을 입력하고 300ms 경과 후 결과가 도착하면 결과 목록을 보여주고 각 행에 하이라이트된 종목명과 `종목코드 · 시장`을 표시해야 한다
- [정상] 결과가 없는 검색어를 입력하고 응답이 도착하면 입력한 원본 문자열이 그대로 포함된 `'{검색어}'와 일치하는 검색 결과를 찾지 못했습니다` 문구를 보여줘야 한다
- [예외] 검색 요청이 실패(`AsyncError`)하면 결과없음 상태와 유사한 레이아웃에 `검색 중 문제가 발생했습니다` 문구를 보여줘야 한다
- [정상] 검색 결과가 보이는 상태에서 입력창 우측 X 버튼을 누르면 검색어와 결과가 모두 지워지고 초기 상태로 돌아가야 한다

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| 처음 진입 시 초기 상태 표시 | SearchPage 정상 시나리오(초기 상태) |
| 1글자 입력 시 요청 없이 초기 상태 유지 | SearchPage 경계 시나리오(1글자) |
| 공백만 입력 시 초기 상태 유지 | SearchPage 경계 시나리오(공백) |
| 2글자 이상 검색 시 결과 목록 + 하이라이트 + 코드·시장 표시 | SearchPage 정상 시나리오(결과 표시), SearchResultRow 정상 시나리오 2건 |
| 결과 없음 문구(원본 검색어 포함) | SearchPage 정상 시나리오(결과없음) |
| 검색 실패 시 에러 문구 | SearchPage 예외 시나리오 |
| X 버튼으로 초기화 | SearchPage 정상 시나리오(X 버튼), SearchInputField 정상 시나리오(onClear) |
| 긴 종목명 ellipsis 처리 | SearchResultRow 경계 시나리오(긴 종목명) |

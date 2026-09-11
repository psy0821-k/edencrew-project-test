# features

사용자 액션 단위 레이어입니다. (예: 관심 등록/해제 토글, 정렬 변경, 검색어 입력)

각 feature 폴더 안에 그 액션 전용 위젯 + provider + 헬퍼(comparator 등)를 둡니다.
`entities`와 `shared`만 참조할 수 있습니다.

Familing API 문서
===============

이 문서에서는 Familing의 API에 대해 다룹니다.

통신 방법
=======

클라이언트 -> 서버 (Upstream)
--------------------------

클라이언트와 서버가 기본적으로 통신하는 데에는 HTTP를 사용합니다.

클라이언트에서 서버로 데이터를 보낼 때에는 QueryString(POST)를 사용해 직렬화합니다.
하지만 서버에서 클라이언트에게 데이터를 돌려줄 때에는 JSON을 사용해 직렬화합니다.

요청에는 POST 요청만을 사용합니다. GET 요청은 사용되지 않습니다.

서버 -> 클라이언트 (Downstream)
----------------------------

서버가 클라이언트에게 푸시 알림을 전송하는데는
[Google Cloud Messaging](https://developers.google.com/cloud-messaging)을
사용합니다.

서버에서는 GCM 서버에 HTTP를 사용해 클라이언트에게 알림을 보내달라고 전송하게 됩니다.

서버에서는 클라이언트상에서 표시해야 할 notification 정보를 그대로 전송합니다. 따로
메시지를 해독할 필요는 없습니다. **아직 불확실함**

클라이언트의 구현방법은
[여기](https://developers.google.com/cloud-messaging/android/client)를
참조해 주세요.

클라이언트는 자신의 `token`을 서버로 보내야 푸시 알림이 작동합니다.
자세한 사항은 이 문서의 **WIP** 를 참조해 주세요.

인증
===

bill.im은 API 토큰 기반 인증을 사용합니다. 클라이언트가 인증 방법 중 하나를 사용해 로그인
하게 되면 서버는 해당 유저에게 속하는 API 토큰을 보냅니다.

~~API 토큰이 expire되는 것도 구현해야 하지만 귀찮으므로 생략~~

API 토큰은 클라이언트가 저장하고 있어야 하며 외부에서 접근 가능하면 안됩니다.

서버에서 관리하는 '유저'는 한 인증 방법에 종속됩니다. 즉, Facebook 로그인을 사용하다가
아이디/비밀번호 방식의 로그인으로 바꿀 수 없습니다. ~~귀찮아서요.~~

API 인증
--------

`/api/auth` 외의 거의 대부분의 API는 인증을 필요로 하고 이 인증은 API 토큰으로 이루어집니다.

API 토큰을 `apikey`에 넣어서 POST 요청을 보낼 때 같이 보내면 인증이 자동으로 처리됩니다.

데이터베이스 스키마
================

여기서는 bill.im에 사용되는 데이터베이스 스키마를 다룹니다.

이 데이터베이스 스키마는 내부적으로도 사용되고 외부로 노출된 API에서도 그대로 사용됩니다.

User
----

사용자 하나를 의미합니다.

### id

int, primary key. 사용자의 고유 번호입니다.

### name

String, not null. 사용자의 이름입니다.

### description

String. 한줄 소개.

### background

String. 사용자의 프로필 사진 배경입니다.

### photo

String. 사용자의 프로필 사진입니다.

### group

Group. 사용자가 속하고 있는 그룹입니다.

### enabled

Boolean, not null. 사용자의 활성 상태입니다.

### class

String. 유저의 직군입니다.

### token

String. 사용자의 API 토큰입니다.

### passport

Passport. 사용자의 인증 수단에 관한 정보입니다.

### gcm

String. GCM 키입니다.

### tagged

Article[]. 해당 유저가 태그된 게시글 목록입니다.

Group
-----

사용자들이 속하는 단체 하나를 의미합니다.

### id

int, primary key. 단체의 고유 번호입니다.

### name

String, not null. 단체의 이름입니다.

### inviteCode

String. 단체의 초대 코드입니다.

Article
-------

게시글입니다

- id - int
- group - Group
- type - int (0~3) 게시글, 해보고 싶어요, 허락해 주세요, 어떻게 할까요
- name - String
- photo - String
- description - String
- allowed - int (0~2) 대기, 승낙, 거절 (허락해 주세요)
- solved - boolean 해결 여부 (어떻게 할까요)
- canAdd - boolean 투표 항목 추가 가능 여부 (어떻게 할까요)
- voteEntries - VoteEntry[] 투표 후보 목록 (어떻게 할까요 / 해보고 싶어요)
- voters - User[] 투표한 유저 목록 (어떻게 할까요 / 해보고 싶어요)
- author - User 글쓴이
- tagged - User[] 태그당한 유저 목록
- comments - Comment[] 댓글 목록

VoteEntry
---------

투표 항목 하나를 의미합니다.

- article - Article 게시글
- votes - int 투표 받은 갯수
- voters - User[] 투표 한 사람 목록

Comment
-------

게시글에 달린 댓글 하나를 의미합니다.

### id

int, primary key. 댓글의 고유 번호입니다.

### description

String, not null. 댓글의 내용입니다.

### author

User, not null. 이 게시글을 작성한 사용자입니다.

### article

Article, not null. 이 댓글이 종속된 게시글입니다.


API 레퍼런스
===========

오류 처리
--------

오류가 발생했는지 여부는 'code' 값으로 확인할 수 있습니다.

- 200 - 성공적으로 실행 함
- 400 - 입력받은 데이터가 잘못 됨
- 401 - 로그인 필요
- 403 - 권한 없음
- 422 - 데이터는 정상적이나 처리 불가
- 500 - 내부 서버 오류

로그인
-----

### /api/auth/login

아이디와 비밀번호로 로그인합니다.

#### 입력

- username - 아이디
- password - 비밀번호

#### 출력

User

### /api/auth/register

서버에 가입합니다.

#### 입력

- username - 아이디
- password - 비밀번호
- name - 유저 이름

#### 출력

User

### /api/auth/logout

토큰을 무효화하고 로그아웃 합니다.

#### 입력

- apikey - API 토큰입니다.

#### 출력

HTTP 200

유저
----

### /api/user/self/gcm

Google Cloud Messaging의 토큰을 설정합니다.

#### 입력

- apikey - API 토큰입니다.
- gcm - GCM 토큰입니다.

#### 출력

HTTP 200

### /api/user/self/modify

자신의 유저 정보를 수정합니다.

#### 입력

- apikey - API 토큰입니다.
- description - 유저의 프로필 메시지입니다.
- class - 유저의 직군입니다. 빈 값을 보내면 현재 값을 유지합니다.

### 출력

User

### /api/user/self/info

자신의 유저 정보를 반환합니다.

#### 입력

- apikey - API 토큰입니다.

#### 출력

User

### /api/user/self/delete

계정을 탈퇴하고 로그아웃합니다.

#### 입력

- apikey - API 토큰입니다.

#### 출력

HTTP 200

### /api/user/self/photo

계정의 프로필 사진을 설정합니다.

#### 입력

- apikey - API 토큰입니다.
- photo - [Multipart Image] 이미지.

#### 출력

User

### /api/user/self/background

계정의 뒷 사진을 설정합니다.

#### 입력

- apikey - API 토큰입니다.
- photo - [Multipart Image] 이미지.

#### 출력

User

그룹
-----

### /api/group/self/info

자신이 속해있는 그룹을 출력합니다.

#### 입력

- apikey - API 토큰입니다.

#### 출력

Group

### /api/group/self/create

그룹을 만들고 자신을 거기에 추가합니다.

#### 입력

- apikey - API 토큰입니다.
- name - 그룹의 이름입니다.

#### 출력

Group

### /api/group/self/join

자신을 그룹에 추가합니다.

#### 입력

- apikey - API 토큰입니다.
- code - 그룹의 초대 코드입니다.

#### 출력

Group

### /api/group/info

그룹의 정보를 반환합니다.

#### 입력

- code - 그룹의 초대 코드입니다.

#### 출력

Group

여기 밑부터는 구현 안됐어요 미안

게시글
-----

### /api/article/list

그룹의 전체 게시글 목록을 반환합니다.

목록은 가장 최신의 글이 맨 위에 있게 정렬되어 반환됩니다.

#### 입력

- apikey - API 키입니다.

#### 출력

Article[]

### /api/article/listByUsers

유저 목록 기반의 게시글 목록을 반환합니다.

#### 입력

- apikey - API 키입니다.

#### 출력

```js
[
  {
    // User
    articles: [
      {
        // Article
      }
    ]
  }
]
```

### /api/article/info

게시글의 내용을 반환합니다.

#### 입력

- id - 게시글의 고유번호입니다.

#### 출력

Article

### /api/article/self/create

게시글을 새로 작성합니다.

#### 입력

- apikey - API 토큰입니다.

이것 좀 보면 백엔드 개발자 좀 살려주세요

#### 출력

Article

### /api/article/self/modify

게시글의 내용을 수정합니다.

#### 입력

- apikey - API 토큰입니다.
- id - 수정할 게시글의 고유번호입니다.

살려주세요

#### 출력

Article

### /api/article/self/delete

게시글을 삭제합니다.

#### 입력

- apikey - API 토큰입니다.
- id - 삭제할 게시글의 고유번호입니다.

#### 출력

HTTP 200

### /api/article/self/list

자신과 관련된 게시글을 모두 반환합니다. (author, tagged)

#### 입력

- apikey - API 토큰입니다.
- group - 그룹 ID입니다.

#### 출력

Article[]

댓글
---

댓글은 해당 게시글을 읽을 때 게시글과 함께 댓글의 목록이 반환됩니다.

### /api/comment/create

게시글에 댓글을 작성합니다.

#### 입력

- apikey - API 토큰입니다.
- description - 댓글의 내용입니다.
- secret - 이 댓글이 비밀 댓글인지의 여부입니다. (0이나 1)
- reply - 이 댓글의 대상 유저의 id입니다.
- article - 댓글을 쓸 게시글의 id입니다.

#### 출력

```js
{
  "댓글 정보": "..." // Comment 스키마 참조
}
```

### /api/comment/modify

댓글을 수정합니다.

#### 입력

- apikey - API 토큰입니다.
- id - 댓글의 ID입니다.
- description - 댓글의 내용입니다.

#### 출력

```js
{
  "댓글 정보": "..." // Comment 스키마 참조
}
```

### /api/comment/delete

댓글을 삭제합니다.

#### 입력

- apikey - API 토큰입니다.
- id - 댓글의 ID입니다.

#### 출력

HTTP 200
